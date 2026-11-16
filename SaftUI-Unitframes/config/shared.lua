local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Settings the unit frames share: "All units". The storage and the rules; this file builds no
	page and applies nothing (a frame changes only through UF:UpdateConfig, which waits for the end
	of combat), and every function here writes tables and nothing else, so each is safe in combat.
	Nothing calls the conversion or the sync at login yet.

	The model. Eleven units are members (UF.SHARE_MEMBERS). A member follows All units for each
	setting it has, until it owns that setting. A shared setting is an entry of UF.SHARED: its key
	(the dotted path below the unit, 'name.font'), the paths it is saved at, its row type and the
	element and kind of unit that make a member have it. A unit frame's own Enable, size, place and
	group layout are never shared (so no entry), nor are Class power, Additional power and the plates.

	Where it is stored, in the unit frame profile (unitframes.profiles.<name>):
	  <profile>.all             All units' values, a unit-shaped table; its defaults are AceDB's
	                            unit wildcard and config/units/all.lua
	  <profile>.<unit>.own      { ['name.font'] = true | false, ... }: dotted keys, cleared to false and
	                            never nil. AceDB fills this table with the element defaults at each login
	                            (enable = true, ...): never iterate it, only read a key an entry names.
	  <profile>.all.version     the marker: UF.SHARED_VERSION once converted. Read and written with
	                            rawget and rawset: a missing key reads as a new table through AceDB's
	                            wildcard.
	  <profile>.backup          { version, when, units }: a copy of the profile's unit tables, made once
	                            before the first conversion (UF:RestoreShared puts it back).
	  <profile>.<unit>.<path>   every member's own stored values stay where they are, and hold what the
	                            member SHOWS: its own value where it owns the setting, else a copy of All
	                            units'. So no reader, oUF element or hot path changes. UF:SharedValue says
	                            what a member shows; UF:SyncShared puts right any drift.

	The steps. UF:ConvertShared(profile) runs once per profile, for each step above the marker
	(UF.SHARED_VERSION says the last; an entry's since says which step converts it):
	  1. All units takes, per setting, the value most members show (UF.SameShared groups the values; a
	     tie goes to All units' default when it is among the tied values, else to the first member);
	  2. each member owns exactly the settings where what it shows differs from that value;
	  3. nothing is written into a member's values. What every member shows is what it showed.
	It computes everything first, then writes (the backup, All units' values, the own flags), and the
	marker last: an error before the marker leaves the profile with no marker and nothing the
	frames read changed. UF:PrepareShared(profile) is the one guarded entry a login or a profile change
	calls: the conversion, then the sync only while the marker says converted.

	A setting added later gets since = n, UF.SHARED_VERSION rises to n, and the conversion runs that
	step for those entries alone, so a unit whose default for the new setting differs owns it from the
	start. Changing a shipped default of a shared setting for some members needs a step as well:
	the sync keeps a follower at All units' value. A test fails an entry no step covers.
]]

------------------------------------------------------------------ members

-- In this order: the mode's tie-break and every list's order.
UF.SHARE_MEMBERS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' }

local IS_MEMBER = {}
for _, unit in ipairs(UF.SHARE_MEMBERS) do IS_MEMBER[unit] = true end

function UF.IsShareMember(unit)
	return IS_MEMBER[unit] == true
end

UF.SHARED_VERSION = 1

------------------------------------------------------------------ the entries

-- { key, part, element, name, type, paths, shows, since }
--   key      the dotted path below the unit of the setting's (first) path; the frame's two are
--            'frame.theme' and 'frame.background', saved at theme and background
--   part     the unit frame part the setting belongs to (UF.PARTS' key), nil for a bar's or the frame's
--   element  the element a member must have (UF.elements, with its ValidUnit), nil for the frame's
--   type     'toggle', 'range', 'select', 'font', 'color', 'colortoggle', 'position' or 'input'
--   paths    where it is saved, below the unit: a list of key lists. One for most; a colortoggle's
--            are its check box then its color; the aura border's are the two hostilities'
--   shows    the kind of unit a member's frames must be able to show (UF.CanShow)
--   since    the step that converts it (default 1)
UF.SHARED, UF.SHARED_BY_KEY, UF.SHARED_BY_PATH = {}, {}, {}
local SHARED, BY_KEY, BY_PATH = UF.SHARED, UF.SHARED_BY_KEY, UF.SHARED_BY_PATH

local function Split(dotted)
	local path = {}
	for part in dotted:gmatch('[^.]+') do path[#path + 1] = part end
	return path
end

local function Add(entry)
	entry.since = entry.since or 1
	entry.paths = entry.paths or { Split(entry.path or entry.key) }
	entry.path = nil
	SHARED[#SHARED + 1] = entry
	BY_KEY[entry.key] = entry
	for _, path in ipairs(entry.paths) do
		BY_PATH[table.concat(path, '.')] = entry
	end
end

-- Each row of a part or bar: { suffix below its config key, name, type, shows, part }.
local function Rows(config, element, part, rows)
	for _, row in ipairs(rows) do
		local key = config .. '.' .. row[1]
		Add({ key = key, part = row.part or part, element = element, name = row[2], type = row[3], shows = row.shows,
			since = row.since })
	end
end

-- A color check box and its color, saved at colorCustom and customColor under base.
local function CustomColor(key, base, element, part, name)
	local toggle, color = Split(base), Split(base)
	toggle[#toggle + 1] = 'colorCustom'
	color[#color + 1] = 'customColor'
	Add({ key = key, part = part, element = element, name = name, type = 'colortoggle', paths = { toggle, color } })
end

local FRAME_ROWS = {
	{ 'frame.theme', 'Theme', 'select', path = 'theme' },
	{ 'frame.background', 'Background', 'select', path = 'background' },
}
for _, row in ipairs(FRAME_ROWS) do
	Add({ key = row[1], name = row[2], type = row[3], path = row.path })
end

-- Health and Power: the bar, its colors, and its text (a part).
local function Bar(config, element, textPart, own)
	local rows = {
		{ 'Smooth', 'Smooth', 'toggle' },
		{ 'alpha', 'Alpha', 'range' },
		{ 'background', 'Background', 'select' },
		{ 'bg.alpha', 'Bar background alpha', 'range' },
		{ 'bg.enable', 'Bar background', 'toggle' },
		{ 'bg.multiplier', 'Bar background brightness', 'range' },
		{ 'colorClass', 'Class color', 'toggle', shows = 'players' },
		{ 'colorClassNPC', 'NPC class color', 'toggle', shows = 'npcs' },
		{ 'colorClassPet', 'Pet class color', 'toggle', shows = 'pets' },
		{ 'colorDisconnected', 'Disconnected color', 'toggle', shows = 'offline' },
		{ 'colorReaction', 'Reaction color', 'toggle' },
		{ 'colorTapping', 'Tapped color', 'toggle', shows = 'mobs' },
		{ 'enable', 'Enable', 'toggle' },
		{ 'framelevel', 'Frame level', 'range' },
		{ 'position', 'Position', 'position' },
		{ 'reverse_fill', 'Reverse fill', 'toggle' },
		{ 'height', 'Height', 'input' },
		{ 'relative_height', 'Relative height', 'toggle' },
		{ 'relative_width', 'Relative width', 'toggle' },
		{ 'width', 'Width', 'input' },
		{ 'theme', 'Theme', 'select' },
		{ 'vertical_fill', 'Vertical fill', 'toggle' },
	}
	Rows(config, element, nil, rows)
	Rows(config, element, nil, own)
	CustomColor(config .. '.customColor', config, element, nil, 'Custom color')
	local text = {
		{ 'enable', 'Show', 'toggle' },
		{ 'hide_full', 'Hide full', 'toggle' },
		{ 'font', 'Font', 'font' },
		{ 'percent', 'Percent', 'toggle' },
		{ 'short', 'Short', 'toggle' },
		{ 'position', 'Text position', 'position' },
	}
	Rows(config .. '.text', element, textPart, text)
	CustomColor(config .. '.text.customColor', config .. '.text', element, textPart, 'Text color')
end

Bar('health', 'Health', 'healthtext', {
	{ 'colorHealth', 'Health color', 'toggle' },
	{ 'colorSmooth', 'Gradient color', 'toggle' },
	{ 'texture', 'Texture', 'select' },
})
Bar('power', 'Power', 'powertext', {
	{ 'colorPower', 'Power type color', 'toggle' },
})
Rows('health.text', 'Health', 'healthtext', {
	{ 'deficit', 'Deficit', 'toggle' },
	{ 'boss_percent', 'Boss percent', 'toggle', shows = 'mobs' },
})

Rows('name', 'Name', 'name', {
	{ 'enable', 'Show', 'toggle' },
	{ 'allCaps', 'All caps', 'toggle' },
	{ 'font', 'Font', 'font' },
	{ 'showLevel', 'Show level', 'toggle' },
	{ 'showSameLevel', 'Show same level', 'toggle' },
	{ 'showMaxLevel', 'Show max level', 'toggle' },
	{ 'show_classification', 'Classification', 'toggle', shows = 'mobs' },
	{ 'colorClass', 'Class color', 'toggle', shows = 'players' },
	{ 'color_hostile', 'Color hostile', 'toggle' },
	{ 'color_friendly', 'Color friendly', 'toggle', shows = 'npcs' },
	{ 'maxLength', 'Max length', 'range' },
	{ 'max_width', 'Max width', 'range' },
	{ 'alpha', 'Alpha', 'range' },
	{ 'position', 'Position', 'position' },
})

Rows('castbar', 'Castbar', nil, {
	{ 'enable', 'Enable', 'toggle' },
	{ 'alpha', 'Alpha', 'range' },
	{ 'background', 'Background', 'select' },
	{ 'framelevel', 'Frame level', 'range' },
	{ 'colors.normal', 'Color', 'color' },
	{ 'colors.nointerrupt', "Can't interrupt color", 'color' },
	{ 'position', 'Position', 'position' },
	{ 'height', 'Height', 'input' },
	{ 'relative_height', 'Relative height', 'toggle' },
	{ 'relative_width', 'Relative width', 'toggle' },
	{ 'width', 'Width', 'input' },
	{ 'theme', 'Theme', 'select' },
	{ 'icon.enable', 'Icon', 'toggle' },
	{ 'icon.background', 'Icon background', 'select' },
	{ 'icon.framelevel', 'Icon frame level', 'range' },
	{ 'icon.position', 'Icon position', 'position' },
	{ 'icon.height', 'Icon height', 'input' },
	{ 'icon.relative_height', 'Icon relative height', 'toggle' },
	{ 'icon.relative_width', 'Icon relative width', 'toggle' },
	{ 'icon.width', 'Icon width', 'input' },
	{ 'icon.theme', 'Icon theme', 'select' },
	{ 'text.enable', 'Spell name', 'toggle' },
	{ 'text.font', 'Spell name font', 'font' },
	{ 'text.position', 'Spell name position', 'position' },
	{ 'time.enable', 'Time', 'toggle' },
	{ 'time.font', 'Time font', 'font' },
	{ 'time.position', 'Time position', 'position' },
})

local function Auras(config, element, own, border)
	Rows(config, element, nil, {
		{ 'enable', 'Enable', 'toggle' },
		{ 'alpha', 'Alpha', 'range' },
		{ 'background', 'Background', 'select' },
		{ 'framelevel', 'Frame level', 'range' },
		{ 'grow_right', 'Grow right', 'toggle' },
		{ 'grow_up', 'Grow up', 'toggle' },
		{ 'initial_anchor', 'Initial anchor', 'select' },
		{ 'max', 'Max', 'range' },
		{ 'per_row', 'Per row', 'range' },
		{ 'onlyShowPlayer', 'Only mine', 'toggle' },
		{ 'position', 'Position', 'position' },
		{ 'relative_size', 'Relative size', 'toggle' },
		{ 'size', 'Size', 'range' },
		{ 'spacing', 'Spacing', 'range' },
		{ 'theme', 'Theme', 'select' },
		{ 'cooldown.enable', 'Cooldown', 'toggle' },
		{ 'cooldown.alpha', 'Cooldown alpha', 'range' },
		{ 'cooldown.reverse', 'Reverse swipe', 'toggle' },
		{ 'cooldown.timer.enable', 'Timer', 'toggle' },
		{ 'cooldown.timer.position', 'Timer position', 'position' },
		{ 'count.font', 'Count font', 'font' },
		{ 'count.position', 'Count position', 'position' },
	})
	Rows(config, element, nil, own)
	-- Either hostility's setting turns the border on, so the row sets both.
	local friend, enemy = Split(config), Split(config)
	friend[#friend + 1], friend[#friend + 2] = 'friend', border.key
	enemy[#enemy + 1], enemy[#enemy + 2] = 'enemy', border.key
	Add({ key = config .. '.border', element = element, name = border.name, type = 'toggle', paths = { friend, enemy } })
end

Auras('buffs', 'Buffs', { { 'purgeable', 'Only buffs I can purge', 'toggle' } },
	{ key = 'colorStealable', name = 'Stealable border' })
Auras('debuffs', 'Debuffs', {}, { key = 'colorTypes', name = 'Dispel type border' })

-- The five icons: Enable, Size, Theme, Background, Alpha and Position, and Show damage dealers on the group role.
for _, indicator in ipairs({
	{ 'raidtargetindicator', 'RaidTargetIndicator', 'raidtarget' },
	{ 'raidroleindicator', 'RaidRoleIndicator', 'raidrole' },
	{ 'grouproleindicator', 'GroupRoleIndicator', 'grouprole' },
	{ 'readycheckindicator', 'ReadyCheckIndicator', 'readycheck' },
	{ 'questindicator', 'QuestIndicator', 'quest' },
}) do
	local config, element, part = indicator[1], indicator[2], indicator[3]
	local rows = {
		{ 'enable', 'Show', 'toggle' },
		{ 'size', 'Size', 'range' },
		{ 'theme', 'Theme', 'select' },
		{ 'background', 'Background', 'select' },
		{ 'alpha', 'Alpha', 'range' },
		{ 'position', 'Position', 'position' },
	}
	if config == 'grouproleindicator' then rows[#rows + 1] = { 'showDps', 'Show damage dealers', 'toggle' } end
	Rows(config, element, part, rows)
end

------------------------------------------------------------------ reading and writing a config

-- The value at path below a config, nil when a table on the way is missing. An index, so AceDB's
-- defaults and wildcards answer as they do for every reader.
local function Get(config, path)
	local node = config
	for i = 1, #path do
		if type(node) ~= 'table' then return nil end
		node = node[path[i]]
	end
	return node
end

local function Set(config, path, value)
	local node = config
	for i = 1, #path - 1 do
		local nextNode = node[path[i]]
		if type(nextNode) ~= 'table' then
			nextNode = {}
			node[path[i]] = nextNode
		end
		node = nextNode
	end
	node[path[#path]] = value
end

local function TableAt(config, path)
	local node = Get(config, path)
	if type(node) ~= 'table' then
		node = {}
		Set(config, path, node)
	end
	return node
end

-- A plain copy of a value, no metatables (a color's methods, AceDB's wildcards), for the backup and
-- for the compare's stand-ins.
local function CopyPlain(value, seen)
	if type(value) ~= 'table' then return value end
	seen = seen or {}
	if seen[value] then return seen[value] end
	local copy = {}
	seen[value] = copy
	for k, v in pairs(value) do copy[k] = CopyPlain(v, seen) end
	return copy
end

------------------------------------------------------------------ the compare and the copy

local function Number(value) return tonumber(value) or 0 end

-- What a position's anchor frame is, with an element dropdown: nothing and false are the unit frame,
-- which 'UIParent' (or UIParent) is not.
local function FrameKey(frame)
	if frame == UIParent or frame == 'UIParent' then return 'UIParent' end
	if not frame then return false end
	if type(frame) == 'table' and frame.GetName then return frame:GetName() or frame end
	return frame
end

-- Two positions by their parts. Offsets are compared as numbers ('5' is 5), never rounded to the
-- pixel: the compare is the same at every UI scale.
local function SamePosition(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	if a.point ~= b.point then return false end
	if (a.rel_point or a.point) ~= (b.rel_point or b.point) then return false end
	if (a.element or nil) ~= (b.element or nil) then return false end
	if not (a.element and b.element) and FrameKey(a.frame) ~= FrameKey(b.frame) then return false end
	return math.abs(Number(a.x_off) - Number(b.x_off)) < 0.0001 and math.abs(Number(a.y_off) - Number(b.y_off)) < 0.0001
end

local function SameValue(rowType, a, b)
	if rowType == 'position' then return SamePosition(a, b) end
	return st.OptionsModel.SameValue(rowType, a, b)
end

-- Whether two unit config tables show the same for the entry, every path compared by the row's type.
-- A colortoggle: the same when both are unticked, whatever the hidden color, or both are ticked with
-- the same color.
function UF.SameShared(entry, a, b)
	local paths = entry.paths
	if entry.type == 'colortoggle' then
		local ta, tb = Get(a, paths[1]), Get(b, paths[1])
		if not ta and not tb then return true end
		if (not ta) ~= (not tb) then return false end
		return SameValue('color', Get(a, paths[2]), Get(b, paths[2]))
	end
	for _, path in ipairs(paths) do
		if not SameValue(entry.type, Get(a, path), Get(b, path)) then return false end
	end
	return true
end

local function RGB(color)
	if color.r ~= nil then return color.r, color.g, color.b end
	return color[1], color[2], color[3]
end

-- A color into the destination's own table, in place, in the shape it has (a color object's or a map's
-- r, g, b; a list's 1 to 3); a new table in the source's shape where it has none.
local function CopyColor(source, config, path)
	if type(source) ~= 'table' then return end
	local r, g, b = RGB(source)
	local dest = Get(config, path)
	if type(dest) ~= 'table' then
		Set(config, path, source.r ~= nil and { r = r, g = g, b = b } or { r, g, b })
	elseif dest.r ~= nil or dest[1] == nil then
		dest.r, dest.g, dest.b = r, g, b
	else
		dest[1], dest[2], dest[3] = r, g, b
	end
end

-- A position part by part, every part: offsets as numbers, an anchor that isn't set as false (so
-- AceDB doesn't fill the default's back in), as the position editor writes it.
local function CopyPosition(source, config, path)
	if type(source) ~= 'table' then return end
	local dest = TableAt(config, path)
	dest.point = source.point
	dest.rel_point = source.rel_point or source.point
	dest.x_off = Number(source.x_off)
	dest.y_off = Number(source.y_off)
	dest.element = source.element or false
	dest.frame = source.frame or false
end

local function CopyTypeface(value) return type(value) == 'table' and st.tablecopy(value, true) or value end

-- Copies the entry's value from one unit config table to another: a position part by part, a color
-- in place, a table value (a typeface) as a copy, a plain value assigned. Never shares a table.
function UF.CopyShared(entry, from, to)
	local paths = entry.paths
	local kind = entry.type
	if kind == 'position' then
		CopyPosition(Get(from, paths[1]), to, paths[1])
	elseif kind == 'color' then
		CopyColor(Get(from, paths[1]), to, paths[1])
	elseif kind == 'colortoggle' then
		Set(to, paths[1], Get(from, paths[1]) and true or false)
		CopyColor(Get(from, paths[2]), to, paths[2])
	elseif kind == 'toggle' then
		for _, path in ipairs(paths) do Set(to, path, Get(from, path) and true or false) end
	elseif kind == 'font' then
		Set(to, paths[1], CopyTypeface(Get(from, paths[1])))
	else
		Set(to, paths[1], Get(from, paths[1]))
	end
end

-- A value the page sets, written into a config: the whole value, or one part of it (part: a position's
-- part name, or 'toggle' or 'color' for a colortoggle's check box and color). A colortoggle's whole
-- value is { toggle = boolean, color = { r, g, b } }. Returns whether the config's value changed.
local function WriteValue(entry, config, value, part)
	local paths, kind = entry.paths, entry.type
	if part then
		if kind == 'colortoggle' then
			if part == 'toggle' then
				local was = Get(config, paths[1]) and true or false
				Set(config, paths[1], value and true or false)
				return was ~= (value and true or false)
			end
			local before = Get(config, paths[2])
			local same = before ~= nil and SameValue('color', before, value)
			CopyColor(value, config, paths[2])
			return not same
		end
		local node = TableAt(config, paths[1])
		if part == 'x_off' or part == 'y_off' then value = Number(value) end
		if (part == 'element' or part == 'frame') and not value then value = false end
		local changed = node[part] ~= value
		node[part] = value
		return changed
	end
	local stand = {}
	if kind == 'colortoggle' then
		value = type(value) == 'table' and value or {}
		Set(stand, paths[1], value.toggle and true or false)
		Set(stand, paths[2], value.color)
	elseif kind == 'toggle' then
		for _, path in ipairs(paths) do Set(stand, path, value and true or false) end
	else
		Set(stand, paths[1], value)
	end
	local same = UF.SameShared(entry, config, stand)
	UF.CopyShared(entry, stand, config)
	return not same
end

-- What a fresh profile's All units holds for the entry: the defaults at its paths, as a unit-shaped
-- table (plain copies; the defaults themselves are never written).
function UF.DefaultShared(entry)
	local config = {}
	local profile = UF:GetProfile() or 'SaftUI'
	for _, path in ipairs(entry.paths) do
		local found, value = st:DefaultAt('unitframes', 'profiles', profile, 'all', unpack(path))
		if found then Set(config, path, CopyPlain(value)) end
	end
	return config
end

------------------------------------------------------------------ who has what, who owns what

-- Whether the unit's page shows the row: a member, the entry's element registered for it and valid for
-- the unit, and a kind of unit its frames can show. 'all' has every entry.
function UF:HasShared(unit, key)
	local entry = BY_KEY[key]
	if not entry then return false end
	if unit == 'all' then return true end
	if not IS_MEMBER[unit] then return false end
	if entry.element then
		local element = UF.elements and UF.elements[entry.element]
		if not element then return false end
		if element.ValidUnit and not element.ValidUnit(unit) then return false end
	end
	if entry.shows and not UF.CanShow(unit, entry.shows) then return false end
	return true
end

local function OwnsKey(config, key)
	local own = rawget(config, 'own')
	return own ~= nil and own[key] == true
end

local function OwnTable(config)
	local own = rawget(config, 'own')
	if not own then
		own = {}
		rawset(config, 'own', own)
	end
	return own
end

-- The unit frame profile's unit table, nil for a unit it doesn't hold (a profile imported from an
-- older export has no table for a unit that wasn't saved).
local function ConfigOf(profile, unit)
	local config = profile[unit]
	if type(config) == 'table' then return config end
end

local function AllOf(profile, create)
	local all = profile.all
	if type(all) == 'table' then return all end
	if create then
		all = {}
		rawset(profile, 'all', all)
		return all
	end
end

local function Marker(profile)
	local all = rawget(profile, 'all')
	local version = type(all) == 'table' and rawget(all, 'version')
	return type(version) == 'number' and version or 0
end

-- Whether the profile (default: the one in use) has been converted: sharing is in force.
function UF:SharedReady(profile)
	profile = profile or self:GetProfileConfig()
	return type(profile) == 'table' and Marker(profile) == UF.SHARED_VERSION
end

function UF:IsOwn(unit, key)
	if not IS_MEMBER[unit] then return false end
	local config = ConfigOf(self:GetProfileConfig(), unit)
	return config ~= nil and OwnsKey(config, key)
end

-- The members, in order, that have the key and hold a config table: { { unit, config }, ... }.
local function Members(self, profile, key)
	local list = {}
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if self:HasShared(unit, key) then
			local config = ConfigOf(profile, unit)
			if config then list[#list + 1] = { unit = unit, config = config } end
		end
	end
	return list
end

-- What the member shows (the first path's value; a position its table): its own where it owns the
-- key or doesn't have it, else All units'.
function UF:SharedValue(unit, key)
	local entry = BY_KEY[key]
	if not entry then return nil end
	local profile = self:GetProfileConfig()
	local source
	if unit == 'all' or (self:HasShared(unit, key) and not self:IsOwn(unit, key)) then
		source = AllOf(profile)
	else
		source = ConfigOf(profile, unit)
	end
	return source and Get(source, entry.paths[1])
end

-- The units of a set, in member order.
local function Ordered(set)
	local list = {}
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if set[unit] then list[#list + 1] = unit end
	end
	return list
end

-- Every follower of the entry (a member that has it and doesn't own it) takes All units' value where
-- its own differs. Marks the units written in changed.
local function Follow(self, profile, entry, changed)
	local all = AllOf(profile)
	if not all then return end
	for _, member in ipairs(Members(self, profile, entry.key)) do
		if not OwnsKey(member.config, entry.key) and not UF.SameShared(entry, member.config, all) then
			UF.CopyShared(entry, all, member.config)
			changed[member.unit] = true
		end
	end
end

------------------------------------------------------------------ writes

-- On 'all': All units' value, and every follower's copy (an owner keeps its own). On a member: the
-- member owns the key, and its value is written. A position is written part by part, every part; a
-- color in place; a typeface as a copy. part: one part of a position, or 'toggle' or 'color' for a
-- colortoggle. Returns the units whose stored values changed, in member order. Applies nothing.
function UF:SetShared(unit, key, value, part)
	local entry = BY_KEY[key]
	if not entry then return {} end
	local profile = self:GetProfileConfig()
	local changed = {}
	if unit == 'all' then
		WriteValue(entry, AllOf(profile, true), value, part)
		Follow(self, profile, entry, changed)
	elseif self:HasShared(unit, key) then
		local config = ConfigOf(profile, unit)
		if config then
			OwnTable(config)[key] = true
			if WriteValue(entry, config, value, part) then changed[unit] = true end
		end
	end
	return Ordered(changed)
end

-- The member owns the key, and nothing else is written: what it shows stays what it shows.
function UF:OwnShared(unit, key)
	if not (BY_KEY[key] and IS_MEMBER[unit] and self:HasShared(unit, key)) then return end
	local config = ConfigOf(self:GetProfileConfig(), unit)
	if config then OwnTable(config)[key] = true end
end

-- The member follows All units again: the flag is false (never nil) and its stored value becomes All
-- units'. Returns the units whose stored value changed.
function UF:FollowAll(unit, key)
	local entry = BY_KEY[key]
	if not (entry and IS_MEMBER[unit] and self:HasShared(unit, key)) then return {} end
	local profile = self:GetProfileConfig()
	local config, all = ConfigOf(profile, unit), AllOf(profile)
	if not (config and all) then return {} end
	OwnTable(config)[key] = false
	local changed = {}
	Follow(self, profile, entry, changed)
	return Ordered(changed)
end

-- From a member: All units takes the member's value, then every member that has the key follows it.
-- From 'all': every member follows. Returns the units whose stored value changed.
function UF:ApplyToAll(unit, key)
	local entry = BY_KEY[key]
	if not entry then return {} end
	local profile = self:GetProfileConfig()
	local all = AllOf(profile, true)
	if unit ~= 'all' then
		if not self:HasShared(unit, key) then return {} end
		local config = ConfigOf(profile, unit)
		if not config then return {} end
		UF.CopyShared(entry, config, all)
	end
	for _, member in ipairs(Members(self, profile, key)) do
		OwnTable(member.config)[key] = false
	end
	local changed = {}
	Follow(self, profile, entry, changed)
	return Ordered(changed)
end

-- targets: a list of units. A target that doesn't have the key is skipped. From a member: each target
-- owns a copy of the member's value, or follows when that value is All units'. From 'all': each target
-- follows. Returns the units whose stored value changed.
function UF:ApplyTo(unit, key, targets)
	local entry = BY_KEY[key]
	if not entry then return {} end
	local profile = self:GetProfileConfig()
	local all = AllOf(profile, true)
	local source
	if unit ~= 'all' then
		if not self:HasShared(unit, key) then return {} end
		source = ConfigOf(profile, unit)
		if not source then return {} end
	end
	local changed = {}
	for _, target in ipairs(targets) do
		if target ~= unit and IS_MEMBER[target] and self:HasShared(target, key) then
			local config = ConfigOf(profile, target)
			if config then
				if not source or UF.SameShared(entry, source, all) then
					OwnTable(config)[key] = false
					if not UF.SameShared(entry, config, all) then
						UF.CopyShared(entry, all, config)
						changed[target] = true
					end
				else
					OwnTable(config)[key] = true
					if not UF.SameShared(entry, config, source) then
						UF.CopyShared(entry, source, config)
						changed[target] = true
					end
				end
			end
		end
	end
	return Ordered(changed)
end

-- The members, in order, that have the key and own it.
function UF:OwnersOf(key)
	local owners = {}
	if not BY_KEY[key] then return owners end
	for _, member in ipairs(Members(self, self:GetProfileConfig(), key)) do
		if OwnsKey(member.config, key) then owners[#owners + 1] = member.unit end
	end
	return owners
end

------------------------------------------------------------------ the once-a-frame update

-- Marks the units to update and shows UF.sharedTicker; its OnUpdate hides it and runs
-- UF:UpdateConfig(unit, element) for each mark, once, in member order. A held slider on All units
-- marks every follower again and again and costs one update of each per frame.
UF.sharedTicker = CreateFrame('Frame')
UF.sharedTicker:Hide()

local pending = {}

function UF:UpdateShared(units, element)
	if not units then return end
	local marked = false
	for _, unit in ipairs(units) do
		if IS_MEMBER[unit] then
			local marks = pending[unit]
			if not marks then
				marks = {}
				pending[unit] = marks
			end
			marks[element or '*'] = true
			marked = true
		end
	end
	if marked then UF.sharedTicker:Show() end
end

UF.sharedTicker:SetScript('OnUpdate', function(self)
	self:Hide()
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		local marks = pending[unit]
		if marks then
			pending[unit] = nil
			if marks['*'] then
				UF:UpdateConfig(unit)
			else
				for element in pairs(marks) do UF:UpdateConfig(unit, element) end
			end
		end
	end
end)

-- All units' values into the followers, for the entries of one element (nil: the frame's own two),
-- as an All units change on that element's rows needs; then the update, once a frame, for the units
-- that changed. Returns them.
function UF:PropagateShared(element)
	local profile = self:GetProfileConfig()
	local changed = {}
	for _, entry in ipairs(SHARED) do
		if entry.element == element then Follow(self, profile, entry, changed) end
	end
	local units = Ordered(changed)
	self:UpdateShared(units, element)
	return units
end

------------------------------------------------------------------ the conversion and the sync

-- Puts every follower's stored value right: All units' value where it differs. Writes nothing on a
-- converted profile that has not drifted. Returns how many values it wrote (and the units).
function UF:SyncShared(profile)
	profile = profile or self:GetProfileConfig()
	local all = type(profile) == 'table' and AllOf(profile)
	if not all then return 0, {} end
	local writes, changed = 0, {}
	for _, entry in ipairs(SHARED) do
		for _, member in ipairs(Members(self, profile, entry.key)) do
			if not OwnsKey(member.config, entry.key) and not UF.SameShared(entry, member.config, all) then
				UF.CopyShared(entry, all, member.config)
				changed[member.unit] = true
				writes = writes + 1
			end
		end
	end
	return writes, Ordered(changed)
end

-- The unit tables of a profile worth keeping a copy of: the keys the defaults name as units.
local function IsUnitKey(key)
	if key == 'all' or key == 'backup' or key == '**' then return false end
	local defaults = st.defaults.unitframes.profiles['**']
	return type(defaults[key]) == 'table'
end

-- A one-time copy of the profile's unit tables, kept before the first conversion. Plain data, as
-- the saved file holds it.
local function MakeBackup(profile)
	local units = {}
	for key, value in pairs(profile) do
		if type(value) == 'table' and IsUnitKey(key) then units[key] = CopyPlain(value) end
	end
	return { version = UF.SHARED_VERSION, when = time(), units = units }
end

-- Whether the profile holds the backup of its unit tables from before the first conversion.
function UF.HasSharedBackup(profile)
	local backup = rawget(profile, 'backup')
	return type(backup) == 'table' and type(backup.units) == 'table'
end

-- Puts the backup back: each unit table in the profile gets the contents it had before the first
-- conversion (in place, so what holds a reference reads them), All units is dropped, and so the
-- marker is: the next conversion starts again. The backup stays. Returns true, or false and why.
-- Applies nothing: the caller updates the unit frames.
function UF:RestoreShared(profile)
	profile = profile or self:GetProfileConfig()
	if type(profile) ~= 'table' or not UF.HasSharedBackup(profile) then
		return false, 'There is no backup of the unit frame settings from before sharing.'
	end
	for key, saved in pairs(rawget(profile, 'backup').units) do
		if type(saved) == 'table' and IsUnitKey(key) then
			local live = profile[key]
			if type(live) ~= 'table' then
				live = {}
				rawset(profile, key, live)
			end
			for k in pairs(live) do live[k] = nil end
			for k, v in pairs(CopyPlain(saved)) do live[k] = v end
		end
	end
	rawset(profile, 'all', nil)
	return true
end

-- What the conversion would do, all of it computed before anything is written: for each entry of the
-- steps above the marker, the value All units takes (nil when it holds it already), and the members
-- that own it.
local function PlanConversion(self, profile, marker)
	local all = AllOf(profile) or {}
	local plan = { writes = {}, owns = {} }
	for _, entry in ipairs(SHARED) do
		if (entry.since or 1) > marker then
			local members = Members(self, profile, entry.key)
			if #members > 0 then
				local groups = {}
				for index, member in ipairs(members) do
					local group
					for _, candidate in ipairs(groups) do
						if UF.SameShared(entry, candidate.config, member.config) then group = candidate break end
					end
					if group then
						group.count = group.count + 1
					else
						groups[#groups + 1] = { config = member.config, count = 1, first = index }
					end
				end
				local best = 0
				for _, group in ipairs(groups) do best = math.max(best, group.count) end
				local tied = {}
				for _, group in ipairs(groups) do
					if group.count == best then tied[#tied + 1] = group end
				end
				local default = UF.DefaultShared(entry)
				local winner
				if #tied == 1 then
					winner = tied[1].config
				else
					for _, group in ipairs(tied) do
						if UF.SameShared(entry, default, group.config) then winner = default break end
					end
					winner = winner or tied[1].config
				end
				if not UF.SameShared(entry, all, winner) then
					plan.writes[#plan.writes + 1] = { entry = entry, from = winner }
				end
				for _, member in ipairs(members) do
					if not UF.SameShared(entry, member.config, winner) then
						plan.owns[#plan.owns + 1] = { config = member.config, key = entry.key }
					end
				end
			end
		end
	end
	return plan
end

-- Once per unit frame profile, for each step above the marker (see the top). Table writes only.
-- Computes everything first, then writes: the one-time backup, All units' values, the own flags,
-- and the marker last. Does nothing on a converted profile.
function UF:ConvertShared(profile)
	profile = profile or self:GetProfileConfig()
	local marker = Marker(profile)
	-- A step no entry could be converted by is a mistake in this file, whatever the profile.
	for _, entry in ipairs(SHARED) do
		if (entry.since or 1) > UF.SHARED_VERSION then
			error(('UF.SHARED entry %s is since %d, but UF.SHARED_VERSION is %d: no conversion step covers it.')
				:format(entry.key, entry.since, UF.SHARED_VERSION), 0)
		end
	end
	if marker >= UF.SHARED_VERSION then return end
	local plan = PlanConversion(self, profile, marker)
	local backup
	if marker == 0 and not UF.HasSharedBackup(profile) then backup = MakeBackup(profile) end
	if backup then rawset(profile, 'backup', backup) end
	local all = AllOf(profile, true)
	for _, write in ipairs(plan.writes) do UF.CopyShared(write.entry, write.from, all) end
	for _, own in ipairs(plan.owns) do OwnTable(own.config)[own.key] = true end
	rawset(all, 'version', UF.SHARED_VERSION)
end

-- Everything a login or a profile change does for sharing, guarded: the conversion, then the sync
-- only while the marker says the profile is converted. A profile the conversion can't read (a malformed
-- saved table) is reported through the error handler, left without the marker, and the frames build
-- from the stored values as they are; the sync never runs over it. Returns whether it ran clean.
function UF:PrepareShared(profile)
	profile = profile or self:GetProfileConfig()
	if type(profile) ~= 'table' then return false end
	local ok = xpcall(function()
		if Marker(profile) < UF.SHARED_VERSION then self:ConvertShared(profile) end
		if Marker(profile) == UF.SHARED_VERSION then self:SyncShared(profile) end
	end, geterrorhandler())
	return ok
end
