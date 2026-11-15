local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The action bars' shared settings. Every bar follows All bars' value of a
	setting (profile.actionbars.all) until it owns that setting: a flag in the
	bar's own table (profile.actionbars.<bar>.own[key] = true), whose value is
	then the bar's, in the same place it has always been (profile.actionbars.
	<bar>.size, .text.hotkey.size ...). Nothing else reads those places
	directly: AB:GetBarConfig(id) builds the table every reader takes, each
	value the bar's own where it owns the key, else All bars'.

	A key is one setting of the page: buttons, perrow, size, spacing, growth
	(the corner the first button sits in, AB.GROWTH_ORDER), visibility, fade_alpha, '<kind>.show', '.font', '.size', '.outline' and
	'.position' for the texts (hotkey, count, macro, countdown; the cooldown
	numbers have no show). A '<kind>.position' is the text's four position parts
	(point, rel_point, x_off, y_off) at once. A bar doesn't have a key its type
	has no use for (the pet and stance bars' count and macro, AB.barTypes
	texts): HasSetting says, it is never own and its value is the bar's stored
	one. Enable, position, Theme and Background aren't shared.

	Nothing here applies a change: callers run AB:UpdateBar(id) (or AB:UpdateBars,
	bars.lua) after, which defers to the end of combat as it always has. Every
	function here is table writes only, safe in combat.

	AB:ConvertProfile() turns a profile saved before this existed into one that
	looks exactly the same: All bars takes Bar 1's values and each bar owns the
	settings where it shows something else. It runs once per profile, marked by
	profile.actionbars.version (inside actionbars, so a profile copy carries the
	marker and a reset clears it), from AB:OnEnable and AB:UpdateConfig, through
	AB:TryConvertProfile, which reports an error through the game's error handler
	and goes on: the bars then build from the profile as it is.
]]

AB.CONFIG_VERSION = 1
AB.TEXT_KINDS = { 'hotkey', 'count', 'macro', 'countdown' }
AB.POSITION_PARTS = { 'point', 'rel_point', 'x_off', 'y_off' }

local POSITION_PARTS = AB.POSITION_PARTS

-- The corners a bar's first button can sit in, as the page offers them (here, not in options.lua,
-- since the effective config reads them and files load before that one).
AB.GROWTH_VALUES = {
	TOPLEFT = 'Top left', TOPRIGHT = 'Top right',
	BOTTOMLEFT = 'Bottom left', BOTTOMRIGHT = 'Bottom right',
}
AB.GROWTH_ORDER = { 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }

-- Every shared key, in the page's order.
AB.SHARED_KEYS = { 'buttons', 'perrow', 'size', 'spacing', 'growth', 'visibility', 'fade_alpha' }
for _, kind in ipairs(AB.TEXT_KINDS) do
	if kind ~= 'countdown' then
		table.insert(AB.SHARED_KEYS, kind .. '.show')
	end
	for _, field in ipairs({ 'font', 'size', 'outline', 'position' }) do
		table.insert(AB.SHARED_KEYS, kind .. '.' .. field)
	end
end

-- key -> { kind, field } for a text key, { } for a plain one.
local KEY_INFO = {}
for _, key in ipairs(AB.SHARED_KEYS) do
	local kind, field = key:match('^(%a+)%.(%a+)$')
	KEY_INFO[key] = { kind = kind, field = field }
end

-- How many buttons each bar has, for the conversion to compare what a bar shows
-- (a bar's built buttons aren't there yet when a profile is converted).
local NUM_BUTTONS = { pet = 10, stance = 10 }
local DEFAULT_NUM_BUTTONS = AB.NUM_BUTTONS

-- Whether a table of parts or plain values is the same; a position is the list
-- of its four values.
local function Same(a, b)
	if type(a) == 'table' and type(b) == 'table' then
		for i = 1, #POSITION_PARTS do
			if a[i] ~= b[i] then return false end
		end
		return true
	end
	return a == b
end

local function OwnTable(bar)
	bar.own = bar.own or {}
	return bar.own
end

-- The stored table of a bar id, or All bars' for 'all'.
function AB:GetStore(id)
	if id == 'all' then return self.config.all end
	return self.config[id]
end

-- One stored value of src (a bar's or All bars' table). A position key reads
-- the part.
local function Read(src, key, part)
	local info = KEY_INFO[key]
	if info.kind then
		return src.text[info.kind][info.field == 'position' and part or info.field]
	end
	return src[key]
end

local function Write(src, key, value, part)
	local info = KEY_INFO[key]
	if info.kind then
		src.text[info.kind][info.field == 'position' and part or info.field] = value
	else
		src[key] = value
	end
end

-- A key's value out of a resolved config: a position as the list of its parts.
local function ResolvedValue(config, key)
	local info = KEY_INFO[key]
	if not info.kind then return config[key] end
	local text = config.text[info.kind]
	if info.field ~= 'position' then return text[info.field] end
	local parts = {}
	for i, part in ipairs(POSITION_PARTS) do parts[i] = text[part] end
	return parts
end

-- Writes a ResolvedValue into src.
local function WriteResolved(src, key, value)
	if KEY_INFO[key].field == 'position' then
		for i, part in ipairs(POSITION_PARTS) do Write(src, key, value[i], part) end
	else
		Write(src, key, value)
	end
end

-- Whether id (a bar id or 'all') has the setting key at all. Reads the bar
-- types at call time.
function AB:HasSetting(id, key)
	local info = KEY_INFO[key]
	if not info then return false end
	if id == 'all' or not info.kind then return true end
	local barType = self.barTypes[id]
	return not (barType and barType.texts) or barType.texts[info.kind] == true
end

-- Whether bar id owns the setting key. 'all' owns nothing.
function AB:IsOwn(id, key)
	if id == 'all' then return false end
	local bar = self.config[id]
	return bar and bar.own and bar.own[key] == true or false
end

-- Bar id's effective config, built per call and never cached: every value the
-- bar's own where it owns the key, else All bars' (id may be 'all'). A key the
-- bar doesn't have reads the bar's stored value. enable and position are the
-- bar's (nil for 'all'); position is the profile's own table, which edit mode
-- writes.
function AB:GetBarConfig(id)
	local bar = self:GetStore(id)
	local all = self.config.all
	local config = { enable = bar.enable, position = bar.position, text = {} }
	for _, kind in ipairs(self.TEXT_KINDS) do config.text[kind] = {} end
	for _, key in ipairs(self.SHARED_KEYS) do
		local src = (id ~= 'all' and self:HasSetting(id, key) and not self:IsOwn(id, key)) and all or bar
		local info = KEY_INFO[key]
		if info.field == 'position' then
			local text = config.text[info.kind]
			for _, part in ipairs(POSITION_PARTS) do text[part] = Read(src, key, part) end
		elseif info.kind then
			config.text[info.kind][info.field] = Read(src, key)
		else
			config[key] = Read(src, key)
		end
	end
	if not AB.GROWTH_VALUES[config.growth] then config.growth = 'TOPLEFT' end
	return config
end

-- One value of bar id's effective config (part for a position key).
function AB:GetSetting(id, key, part)
	local config = self:GetBarConfig(id)
	local info = KEY_INFO[key]
	if not info then return nil end
	if info.kind then
		return config.text[info.kind][info.field == 'position' and part or info.field]
	end
	return config[key]
end

-- On 'all': All bars' value. On a bar: the bar owns the key and its value is
-- written; the first time a bar owns a position, All bars' four parts are
-- copied in before the part is written. Applies nothing.
function AB:SetSetting(id, key, value, part)
	if not KEY_INFO[key] then return end
	if id == 'all' then
		Write(self.config.all, key, value, part)
		return
	end
	local bar = self.config[id]
	local own = OwnTable(bar)
	if own[key] ~= true then
		if KEY_INFO[key].field == 'position' then
			for _, p in ipairs(POSITION_PARTS) do
				Write(bar, key, Read(self.config.all, key, p), p)
			end
		end
		own[key] = true
	end
	Write(bar, key, value, part)
end

-- The bar follows All bars again. The flag is false, never nil, so a flag that
-- ships true stays cleared. Its stored value stays.
function AB:ResetSetting(id, key)
	if id == 'all' or not KEY_INFO[key] then return end
	OwnTable(self.config[id])[key] = false
end

-- Every bar that has key follows All bars.
local function ClearFlags(self, key)
	for _, id in ipairs(self.BAR_IDS) do
		if self:HasSetting(id, key) then
			OwnTable(self.config[id])[key] = false
		end
	end
end

-- From a bar: All bars takes the bar's effective value (all four parts for a
-- position), then every bar follows it. From 'all': every bar follows it.
function AB:ApplyToAll(id, key)
	if not KEY_INFO[key] then return end
	if id ~= 'all' then
		if not self:HasSetting(id, key) then return end
		WriteResolved(self.config.all, key, ResolvedValue(self:GetBarConfig(id), key))
	end
	ClearFlags(self, key)
end

-- targets: a list of bar ids. A target that doesn't have the key is skipped.
-- From a bar: each target owns a copy of the bar's value, or follows when that
-- value is All bars'. From 'all': each target follows.
function AB:ApplyTo(id, key, targets)
	if not KEY_INFO[key] then return end
	local value
	local fromBar = id ~= 'all'
	if fromBar then
		if not self:HasSetting(id, key) then return end
		value = ResolvedValue(self:GetBarConfig(id), key)
	end
	local all = ResolvedValue(self:GetBarConfig('all'), key)
	for _, target in ipairs(targets) do
		if target ~= id and target ~= 'all' and self.config[target] and self:HasSetting(target, key) then
			local own = OwnTable(self.config[target])
			if not fromBar or Same(value, all) then
				own[key] = false
			else
				WriteResolved(self.config[target], key, value)
				own[key] = true
			end
		end
	end
end

-- The bars, in AB.BAR_IDS order, that have the key and own it.
function AB:OwnersOf(key)
	local owners = {}
	for _, id in ipairs(self.BAR_IDS) do
		if self:HasSetting(id, key) and self:IsOwn(id, key) then
			owners[#owners + 1] = id
		end
	end
	return owners
end

-- What a bar shows for key, for the conversion: Buttons and Buttons per row
-- clamped to the bar's button count, a position as its parts.
local function Shown(src, key, numButtons)
	local info = KEY_INFO[key]
	if info.field == 'position' then
		local parts = {}
		for i, part in ipairs(POSITION_PARTS) do parts[i] = Read(src, key, part) end
		return parts
	end
	local value = Read(src, key)
	if key == 'buttons' or key == 'perrow' then
		return st.Clamp(tonumber(value) or value, 1, numButtons)
	end
	return value
end

-- What the texts' font, size and outline shipped as before Small text became their
-- default font: a copy of Small text's face, size and outline (AceDB saves only
-- what differs from a default, so a profile saved then has a face only where it
-- chose one, and a size or an outline only where it changed them). A record of
-- the past, kept here whatever Small text's defaults become.
AB.OLD_TEXT_FONT = { font = 'Homespun', size = 10, outline = 'MONOCHROMEOUTLINE' }

-- The texts whose font the step below converts: the cooldown numbers have no
-- font of their own to convert.
local FONT_KINDS = { 'hotkey', 'count', 'macro' }

AB.DEFAULT_TEXT_FONT = 'pixel'
AB.FONTS_VERSION = 1

-- A text that reads the shared font by default but has a size or an outline that
-- is not the old copy's drew the old copy's face at that size or outline (the
-- face was never saved: it was the default). Whether a text's font is Small
-- text because it was never set, or because a Font row picked it, can't be told
-- once AceDB has put the defaults back, so this reads a size or an outline kept
-- beside it as the first: a face and a size picked in the old build, then Small
-- text, is the one shape this gets wrong (it draws the old face at that size).
local function KeepsOldFace(font, size, outline)
	local old = AB.OLD_TEXT_FONT
	return font == AB.DEFAULT_TEXT_FONT and (size ~= old.size or outline ~= old.outline)
end

-- One-time step for a profile saved before the texts' default font was Small text
-- (actionbars.fontsVersion, which has no default; it rides in the profile's own
-- table, so a copy carries it and a reset clears it): each text keeps what it
-- drew. It runs before the conversion to All bars below, which compares what
-- each bar shows. Table writes only.
--   - In a profile not yet converted to All bars, each bar's own text tables
--     (the values a bar shows, with no flags yet).
--   - In one converted, All bars' text tables, and then each bar's effective
--     values: a bar that follows All bars' Small text but owns a size or an
--     outline owns the old face too, so it draws what it did. A bar that owns
--     its font (a shared font picked from the Font row) keeps it.
function AB:ConvertFonts()
	local config = self.config
	if not config or config.fontsVersion ~= nil then return end
	local old = AB.OLD_TEXT_FONT

	local function Convert(text)
		if type(text) == 'table' and KeepsOldFace(text.font, text.size, text.outline) then
			text.font = old.font
		end
	end

	if not config.version then
		for _, id in ipairs(self.BAR_IDS) do
			local bar = config[id]
			for _, kind in ipairs(FONT_KINDS) do
				if bar and bar.text and self:HasSetting(id, kind .. '.font') then Convert(bar.text[kind]) end
			end
		end
	else
		for _, kind in ipairs(FONT_KINDS) do
			if config.all and config.all.text then Convert(config.all.text[kind]) end
		end
		for _, id in ipairs(self.BAR_IDS) do
			local bar = config[id]
			for _, kind in ipairs(FONT_KINDS) do
				local key = kind .. '.'
				if bar and bar.text and type(bar.text[kind]) == 'table' and self:HasSetting(id, key .. 'font')
					and not self:IsOwn(id, key .. 'font') then
					local all = config.all and config.all.text and config.all.text[kind] or {}
					if all.font == AB.DEFAULT_TEXT_FONT then
						local text = bar.text[kind]
						local size = self:IsOwn(id, key .. 'size') and text.size or all.size
						local outline = self:IsOwn(id, key .. 'outline') and text.outline or all.outline
						if size ~= old.size or outline ~= old.outline then
							text.font = old.font
							OwnTable(bar)[key .. 'font'] = true
						end
					end
				end
			end
		end
	end
	config.fontsVersion = AB.FONTS_VERSION
end

-- Once per profile (see the top). Table writes only.
function AB:ConvertProfile()
	self:ConvertFonts()
	local config = self.config
	if config.version then return end

	-- All bars takes Bar 1's values, set or default.
	for _, key in ipairs(self.SHARED_KEYS) do
		if KEY_INFO[key].field == 'position' then
			for _, part in ipairs(POSITION_PARTS) do
				Write(config.all, key, Read(config.bar1, key, part), part)
			end
		else
			Write(config.all, key, Read(config.bar1, key))
		end
	end

	-- Each bar owns what it shows differently from All bars.
	for _, id in ipairs(self.BAR_IDS) do
		local bar = config[id]
		local own = OwnTable(bar)
		local n = NUM_BUTTONS[id] or DEFAULT_NUM_BUTTONS
		for _, key in ipairs(self.SHARED_KEYS) do
			if self:HasSetting(id, key) then
				own[key] = not Same(Shown(bar, key, n), Shown(config.all, key, n))
			end
		end
	end

	config.version = self.CONFIG_VERSION
end

-- ConvertProfile that never stops its caller: a profile the conversion can't
-- read (a malformed saved table) is reported through the error handler, left
-- without the marker (so the next profile change tries again), and the bars
-- still build from it. Every caller at login or on a profile change uses this.
function AB:TryConvertProfile()
	return xpcall(function() self:ConvertProfile() end, geterrorhandler())
end
