local st = SaftUI
local UF = st:GetModule('Unitframes')

-- groups.lua's, which loads before this file.
local GROUP_HEADERS = UF.GROUP_HEADERS
local GetGroupSize = UF.GetGroupSize
local UpdateBorder = UF.UpdateBorder

--[[
	A group's test mode fills its holder with preview frames for made-up
	members, so a raid layout can be checked without a raid. The previews are
	SaftUI's own plain frames, built from the same element helpers and the
	same config as the real buttons (size, theme, health and power bars,
	name text, role corner, range alpha), and laid out with the header's own
	sums. No unit is ever faked: no secure frame, unit attribute or Blizzard
	unit function is involved, and the bars are filled straight from the data
	below.

	Not drawn: auras, castbars, portraits, raid target, ready check and
	leader/assist icons, and the level in the name.

	Boss frames have a test mode too, with made-up bosses. They have no
	header: they're five unit frames on the boss holder (unitframes.lua), so
	the container stands in for the holder, and the previews go where
	UF:PlaceUnitFrame puts the boss frames, one for each boss frame the
	layout shows.

	UF.testGroups is a plain field: not saved, off after a /reload. A profile
	switch keeps it on and restyles the previews for the new profile. They hide
	while the group's real header shows, or any real boss frame.
]]

UF.testGroups = {}
UF.previews = {}

local PREVIEW_NAMES = {
	'Aldric', 'Brienna', 'Corvin', 'Dagna', 'Elowen', 'Faelan', 'Garrick', 'Halia', 'Isolde', 'Jorund',
	'Kaelith', 'Lorne', 'Maera', 'Nerith', 'Osric', 'Pella', 'Quillon', 'Rowena', 'Soren', 'Thalia',
	'Ulric', 'Vesna', 'Wystan', 'Xara', 'Yorin', 'Zephra', 'Anwen', 'Bastian', 'Cerys', 'Dorian',
	'Edda', 'Fintan', 'Gwyn', 'Hakon', 'Ilsa', 'Jarek', 'Kestra', 'Leofric', 'Mirelle', 'Nyra',
}

-- Repeats every ten members: two tanks, three healers, five damage. Classes
-- every client has.
local PREVIEW_SPECS = {
	{ class = 'WARRIOR', role = 'TANK', power = 'RAGE' },
	{ class = 'PRIEST', role = 'HEALER', power = 'MANA' },
	{ class = 'MAGE', role = 'DAMAGER', power = 'MANA' },
	{ class = 'ROGUE', role = 'DAMAGER', power = 'ENERGY' },
	{ class = 'HUNTER', role = 'DAMAGER', power = 'FOCUS' },
	{ class = 'PALADIN', role = 'HEALER', power = 'MANA' },
	{ class = 'WARLOCK', role = 'DAMAGER', power = 'MANA' },
	{ class = 'DRUID', role = 'TANK', power = 'RAGE' },
	{ class = 'SHAMAN', role = 'HEALER', power = 'MANA' },
	{ class = 'DRUID', role = 'DAMAGER', power = 'ENERGY' },
}

local PREVIEW_HEALTH = { 0.92, 1, 0.64, 0.35, 0.81, 1, 0.47, 0.73, 1, 0.58 }
local PREVIEW_POWER = { 0.35, 0.9, 0.62, 0.8, 0.5, 0.75, 0.4, 0.2, 1, 0.66 }

-- Members shown out of range, dead or offline. A party (members 1-4, or 1-5
-- with the player) gets one out of range and one dead; offline starts at 9.
local PREVIEW_OUT_OF_RANGE = { [3] = true, [12] = true, [21] = true, [38] = true }
local PREVIEW_DEAD = { [4] = true, [17] = true, [33] = true }
local PREVIEW_OFFLINE = { [9] = true, [26] = true }

local PREVIEW_MAX_HEALTH = 250000
local PREVIEW_MAX_MANA = 60000
local PREVIEW_MAX_POWER = 100 -- rage, energy, focus

local PREVIEW_MEMBERS = {}
for i, name in ipairs(PREVIEW_NAMES) do
	local spec = PREVIEW_SPECS[(i - 1) % #PREVIEW_SPECS + 1]
	-- Shifts the health and power patterns for each further ten members.
	local shift = math.floor((i - 1) / #PREVIEW_SPECS)
	PREVIEW_MEMBERS[i] = {
		name = name,
		player = true,
		reaction = 5, -- friendly
		class = spec.class,
		-- A raid needs two tanks; the later tank slots play damage.
		role = (spec.role == 'TANK' and i > #PREVIEW_SPECS) and 'DAMAGER' or spec.role,
		powerType = spec.power,
		health = PREVIEW_HEALTH[(i * 7 + shift) % #PREVIEW_HEALTH + 1],
		power = PREVIEW_POWER[(i * 3 + shift) % #PREVIEW_POWER + 1],
		outOfRange = PREVIEW_OUT_OF_RANGE[i] or false,
		dead = PREVIEW_DEAD[i] or false,
		offline = PREVIEW_OFFLINE[i] or false,
	}
end

-- Made-up bosses: NPCs, hostile, skull level, at full health and with no
-- role. An NPC's class (what NPC class colors by) is one of these four.
local PREVIEW_BOSSES = {
	{ name = 'Vorgath the Unbound', class = 'WARRIOR' },
	{ name = 'Sister Maelis', class = 'PALADIN' },
	{ name = 'Grimjaw', class = 'WARRIOR' },
	{ name = 'The Hollow Warden', class = 'ROGUE' },
	{ name = 'Ixalith', class = 'MAGE' },
}
for _, boss in ipairs(PREVIEW_BOSSES) do
	boss.player = false
	boss.reaction = 2 -- hostile
	boss.skull = true
	boss.powerType = 'MANA'
	boss.health, boss.power = 1, 1
	boss.outOfRange, boss.dead, boss.offline = false, false, false
end

-- A color object, or nil for anything else (a missing class or power color).
local function AsColor(color)
	if type(color) == 'table' and color.GetRGB then return color end
end

-- Whether an element's class color flags color this member, as oUF checks
-- them: Class for players, NPC class for anyone else (a boss).
local function ColorsByClass(config, member)
	if member.player then return config.colorClass end
	return config.colorClassNPC
end

-- One preview frame, with the same pieces UF.ConstructUnit and the element
-- constructors give a real button (made with the same helpers), minus
-- everything oUF drives: health and power bars with their texts, the name
-- and the role corner.
local function CreatePreviewFrame(container, group, index)
	local label = GROUP_HEADERS[group] and GROUP_HEADERS[group].name or UF.unit_strings[group]
	local frame = CreateFrame('Frame', ('SaftUI_%sPreview%d'):format(label, index), container)
	frame.base_unit = group
	frame.GetConfig = function() return UF:GetProfileConfig()[group] end
	frame.config = frame:GetConfig()

	local textoverlay = CreateFrame('Frame', nil, frame)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(frame)
	frame.TextOverlay = textoverlay

	local health = UF:AddStatusBarElement(frame, 'Health')
	UF:AddText(frame, health)
	local power = UF:AddStatusBarElement(frame, 'Power')
	UF:AddText(frame, power)
	local name = UF:AddTextElement(frame, 'Name')
	-- SetText needs a font; StylePreviewFrame sets the configured one.
	name:SetFontObject(GameFontNormal)
	local role = UF:AddTextureElement(frame, 'GroupRoleIndicator')
	role:SetTexture(st.textures.cornerbr)

	frame.previewElements = { health, power, name, role }
	return frame
end

-- Applies the current profile's look: what UF:UpdateUnitFrame and the
-- elements' UpdateConfig do for a real button.
local function StylePreviewFrame(frame)
	local config = frame:GetConfig()
	frame.config = config
	st:SetSize(frame, config.width, config.height)
	st:SetBackdrop(frame, config.theme, config.background, UF.SizedKind(frame.base_unit, config.width, config.height))
	for _, element in ipairs(frame.previewElements) do
		UF:UpdateElement(element)
	end
	local role = frame.GroupRoleIndicator
	role:SetSize(role.config.size, role.config.size)
end

-- Shows one member the way the real elements would: the health color order
-- of oUF's health element, the texts of SaftUI's health PostUpdate, the
-- power color order of oUF's power element, the name tag's caps, length and
-- colors, the role corner's colors, and the range element's alpha.
local function FillPreviewFrame(frame, member)
	local colors = UF.oUF.colors
	local classColor = AsColor(colors.class[member.class])

	local health = frame.Health
	local healthConfig = health.config
	-- oUF shows an offline member's bar full.
	local healthValue = member.offline and 1 or member.dead and 0 or member.health
	health:SetMinMaxValues(0, 1)
	health:SetValue(healthValue)

	local color
	if healthConfig.colorDisconnected and member.offline then
		color = colors.disconnected
	elseif ColorsByClass(healthConfig, member) then
		color = classColor
	elseif healthConfig.colorReaction then
		color = colors.reaction[member.reaction]
	elseif healthConfig.colorHealth then
		color = colors.health
	end
	color = AsColor(color)
	if healthConfig.colorCustom and healthConfig.customColor then
		health:SetStatusBarColor(UF.UnpackColor(healthConfig.customColor))
	elseif color then
		health:SetStatusBarColor(color:GetRGB())
	end
	if healthConfig.bg.enable then
		local mu = healthConfig.bg.multiplier or 1
		health.bg:SetVertexColor(mu, mu, mu)
	end

	local textConfig = healthConfig.text
	if health.text and textConfig.enable then
		local current = math.floor(PREVIEW_MAX_HEALTH * healthValue + 0.5)
		local deficit = PREVIEW_MAX_HEALTH - current
		local text
		if textConfig.hide_full and deficit == 0 then
			text = ''
		elseif member.dead then
			text = 'Dead'
		elseif textConfig.deficit then
			text = deficit > 0 and ('-' .. st.StringFormat:ShortFormat(deficit)) or ''
		elseif textConfig.percent then
			text = math.floor(healthValue * 100)
		else
			text = current
			-- The percent after it on a skull-level unit, as on a boss.
			if textConfig.boss_percent and member.skull then
				text = ('%s | %.1f'):format(text, healthValue * 100)
			end
		end
		health.text:SetText(text)
	end

	local power = frame.Power
	local powerConfig = power.config
	if powerConfig.enable then
		local powerValue = (member.dead or member.offline) and 0 or member.power
		-- SaftUI's power PostUpdate puts these textures back on every update.
		UF:RedrawBarFill(power)
		power:SetMinMaxValues(0, 1)
		power:SetValue(powerValue)

		color = nil
		if powerConfig.colorDisconnected and member.offline then
			color = colors.disconnected
		elseif powerConfig.colorPower then
			color = AsColor(colors.power[member.powerType]) or colors.power.MANA
		elseif ColorsByClass(powerConfig, member) then
			color = classColor
		elseif powerConfig.colorReaction then
			color = colors.reaction[member.reaction]
		end
		color = AsColor(color)
		if color then
			local r, g, b = color:GetRGB()
			power:SetStatusBarColor(r, g, b)
			UF.SetPowerBackgroundColor(power, r, g, b)
		elseif powerConfig.colorCustom and powerConfig.customColor then
			power:SetStatusBarColor(UF.UnpackColor(powerConfig.customColor))
		end

		if power.text and powerConfig.text.enable then
			local max = member.powerType == 'MANA' and PREVIEW_MAX_MANA or PREVIEW_MAX_POWER
			local current = math.floor(max * powerValue + 0.5)
			if powerConfig.text.hide_full and current == max then
				power.text:SetText('')
			else
				power.text:SetText(powerConfig.text.short and UF.ShortNumber(current)
					or current < 10000 and current or st.StringFormat:ShortFormat(current, 1))
			end
		end
	end

	local name = frame.Name
	local nameConfig = name.config
	if nameConfig.enable then
		local text = member.name
		if nameConfig.allCaps then
			text = strupper(text)
		end
		text = st.StringFormat:UTF8strsub(text, nameConfig.maxLength)
		if ColorsByClass(nameConfig, member) then
			if classColor then
				text = st.StringFormat:ColorString(text, classColor:GetRGB())
			end
		elseif nameConfig.color_hostile and member.reaction < 5 then
			local hostile = st:Color('text', member.reaction < 3 and 'danger' or 'caution')
			text = st.StringFormat:ColorString(text, hostile:GetRGB())
		end
		name:SetText(text)
	end

	-- The role corner's colors and rules from its postUpdate in
	-- elements/indicators.lua, plus the enable check its PostUpdate wrapper
	-- adds: on for party, off for the raids, by default. A boss has no role,
	-- and oUF hides the corner then.
	local role = frame.GroupRoleIndicator
	local roleConfig = role.config
	role:SetTexture(st.textures.cornerbr)
	role:SetTexCoord(0, 1, 0, 1)
	if member.role == 'HEALER' or member.role == 'TANK' then
		role:SetVertexColor(st:Color('roles', member.role):GetRGB())
	else
		role:SetVertexColor(st:Color('roles', 'DAMAGER'):GetRGB())
	end
	role:SetShown((roleConfig.enable and member.role and (roleConfig.showDps or member.role == 'HEALER' or member.role == 'TANK')) and true or false)

	-- oUF's range element shows offline members at full alpha.
	local alpha = frame.config.range_alpha
	frame:SetAlpha((member.outOfRange and not member.offline) and alpha.outside or alpha.inside)
end

-- Places the first count frames inside container the way a header places its
-- buttons.
local function ArrangeLikeHeader(container, frames, count, layout, unitsPerColumn, numColumns)
	for i = 1, count do
		local frame = frames[i]
		frame:ClearAllPoints()
		for _, a in ipairs(UF.GroupAnchor(i, frames, container, layout, unitsPerColumn, numColumns)) do
			frame:SetPoint(a[1], a[2], a[3], a[4], a[5])
		end
	end
end

-- Whether a group's real frames are up: its header, or any boss frame (each
-- shows while its boss exists). nil while they haven't been made.
local function RealFramesShown(group)
	local header = UF.groups and UF.groups[group]
	if header then return header:IsShown() end
	local frames = UF.units and UF.units[group]
	if not frames then return nil end
	for _, frame in ipairs(frames) do
		if frame:IsShown() then return true end
	end
	return false
end

-- How many frames a group's previews stand in for: every member its header
-- can list, or every boss frame (UF:PlaceHolder sizes the holder for them).
local function GetPreviewSize(group, config)
	if GROUP_HEADERS[group] then return GetGroupSize(group, config) end
	return #UF.units[group]
end

-- Shows, restyles and lays out a group's previews from the current profile,
-- or hides them: test mode off, the group disabled, or its real frames
-- showing. The container stands in for the header: same size for the same
-- members, anchored to the holder at the same point. For boss it covers the
-- holder the boss frames are placed in, so the previews land where
-- UF:PlaceUnitFrame puts them. None of this is secure, so it can run in combat
-- (the real frames' OnShow/OnHide).
function UF:UpdateGroupPreview(group)
	local container = self.previews[group]
	local config = self:GetProfileConfig()[group]
	if not (self.testGroups[group] and config.enable and RealFramesShown(group) == false) then
		if container then container:Hide() end
		return
	end

	if not container then
		container = CreateFrame('Frame', nil, UIParent)
		container.frames = {}
		self.previews[group] = container
	end

	local layout = UF.GetUnitGroupLayout(group, config)
	local width, height, unitsPerColumn, numColumns, count = UF.GetGroupLayoutSize(layout, GetPreviewSize(group, config))
	local point = config.position.point
	container:ClearAllPoints()
	container:SetPoint(point, self.holders[group], point)
	container:SetSize(width, height)

	local members = group == 'boss' and PREVIEW_BOSSES or PREVIEW_MEMBERS
	for i = 1, count do
		local frame = container.frames[i] or CreatePreviewFrame(container, group, i)
		container.frames[i] = frame
		StylePreviewFrame(frame)
		FillPreviewFrame(frame, members[i])
		frame:Show()
	end
	for i = count + 1, #container.frames do
		container.frames[i]:Hide()
	end
	ArrangeLikeHeader(container, container.frames, count, layout, unitsPerColumn, numColumns)
	-- A party or raid group's previews sit in the group border, as its members do.
	if GROUP_HEADERS[group] then UpdateBorder(container, config) end

	container:Show()
end

-- The /sui "Test mode" toggle.
function UF:SetGroupTestMode(group, enabled)
	self.testGroups[group] = enabled and true or nil
	self:UpdateGroupPreview(group)
end

-- Boss frames have no header to watch: oUF's unit watch shows each one while
-- its boss exists. So the previews make way for any of them, and come back,
-- from their OnShow and OnHide. HookScript runs after oUF's own handlers.
-- Once, from OnEnable.
function UF:WatchFramesForPreview(group)
	for _, frame in ipairs(self.units[group]) do
		frame:HookScript('OnShow', function() UF:UpdateGroupPreview(group) end)
		frame:HookScript('OnHide', function() UF:UpdateGroupPreview(group) end)
	end
end
