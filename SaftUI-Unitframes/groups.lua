local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Party and raid frames.

	Each group is an oUF group header (Blizzard's SecureGroupHeaderTemplate).
	The header makes, places, shows and assigns its unit buttons itself, in
	combat too, so SaftUI never touches the header or its buttons in combat:
	everything here that sizes, places or sets attributes runs out of combat
	(UF:ApplyConfig only gets here out of combat, and moves go through
	st:SafeReposition).

	Each header hangs in a SaftUI holder frame that is sized to the whole group
	(every member it can show) and is the group's edit mode mover. So the
	outline covers the group's spot even when solo, and a drag moves the
	holder, not the header. The header is anchored to the holder at the
	group's position point, so the frames sit where they did when the header
	itself was placed at that position.

	Test mode (bottom of the file) fills the holder with SaftUI-owned preview
	frames for made-up members.
]]

-- Group key -> its frame names, how many members it can list, and when it
-- shows. Raid unit ids are numbered from 1 with no gaps, so raid11 exists
-- exactly when the raid has 11 or more members.
local GROUP_HEADERS = {
	party = { name = 'Party', size = 5, visibility = '[group:raid] hide; [group:party] show; hide' },
	raid10 = { name = 'Raid10', size = 10, visibility = '[@raid11,exists] hide; [group:raid] show; hide' },
	raid40 = { name = 'Raid40', size = 40, visibility = '[@raid11,exists] show; hide' },
}

-- The header's 'point' and 'columnAnchorPoint' values SaftUI offers: one
-- frame or column grows away from the previous one's opposite side.
local GROWTH_POINTS = { TOP = true, BOTTOM = true, LEFT = true, RIGHT = true }

-- Runs in the restricted environment each time the header makes a unit
-- button (oUF runs it at the end of its own initial config), in combat too.
-- It sizes the button from the header's attributes, which UF:ApplyGroupLayout
-- keeps in step with the profile.
local INITIAL_CONFIG = [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute('initial-width'))
	self:SetHeight(header:GetAttribute('initial-height'))
]]

-- A copy of getRelativePointAnchor in Blizzard's SecureGroupHeaders.lua (it's
-- local there): the opposite point, and which way along each axis a point
-- grows.
local function GetRelativePointAnchor(point)
	point = point:upper()
	if point == 'TOP' then
		return 'BOTTOM', 0, -1
	elseif point == 'BOTTOM' then
		return 'TOP', 0, 1
	elseif point == 'LEFT' then
		return 'RIGHT', 1, 0
	elseif point == 'RIGHT' then
		return 'LEFT', -1, 0
	elseif point == 'TOPLEFT' then
		return 'BOTTOMRIGHT', 1, -1
	elseif point == 'TOPRIGHT' then
		return 'BOTTOMLEFT', -1, -1
	elseif point == 'BOTTOMLEFT' then
		return 'TOPRIGHT', 1, 1
	elseif point == 'BOTTOMRIGHT' then
		return 'TOPLEFT', -1, 1
	else
		return 'CENTER', 0, 0
	end
end

-- The group's layout config as header attribute values. config.growthDirection
-- is the header's 'point' and config.initialAnchor its 'columnAnchorPoint'.
-- The header adds xOffset/yOffset as they are, so they're signed here to make
-- spacing a gap whichever way the frames grow (unsigned, frames growing down
-- or left overlapped).
local function GetLayout(config)
	local point = GROWTH_POINTS[config.growthDirection] and config.growthDirection or 'TOP'
	local _, xMult, yMult = GetRelativePointAnchor(point)
	local spacing = tonumber(config.spacing) or 0
	return {
		point = point,
		xOffset = spacing * xMult,
		yOffset = spacing * yMult,
		unitsPerColumn = math.max(1, tonumber(config.unitsPerColumn) or 5),
		maxColumns = math.max(1, tonumber(config.maxColumns) or 1),
		columnSpacing = tonumber(config.columnSpacing) or 0,
		columnAnchorPoint = GROWTH_POINTS[config.initialAnchor] and config.initialAnchor or 'LEFT',
		width = tonumber(config.width) or 0,
		height = tonumber(config.height) or 0,
	}
end

-- The size the header gives itself for count members (the same sums as
-- configureChildren in SecureGroupHeaders.lua), its column length and column
-- count, and how many of the count it shows (maxColumns can cut it short).
local function GetLayoutSize(layout, count)
	count = math.max(1, count)
	local _, xMult, yMult = GetRelativePointAnchor(layout.point)
	local unitsPerColumn, numColumns = layout.unitsPerColumn, 1
	if count > unitsPerColumn then
		numColumns = math.min(math.ceil(count / unitsPerColumn), layout.maxColumns)
	else
		unitsPerColumn = count
	end

	local w, h = layout.width, layout.height
	local width = math.abs(xMult) * (unitsPerColumn - 1) * w + (unitsPerColumn - 1) * (layout.xOffset * xMult) + w
	local height = math.abs(yMult) * (unitsPerColumn - 1) * h + (unitsPerColumn - 1) * (layout.yOffset * yMult) + h
	if numColumns > 1 then
		local _, colX, colY = GetRelativePointAnchor(layout.columnAnchorPoint)
		width = width + (numColumns - 1) * math.abs(colX) * (width + layout.columnSpacing)
		height = height + (numColumns - 1) * math.abs(colY) * (height + layout.columnSpacing)
	end
	return width, height, unitsPerColumn, numColumns, math.min(count, unitsPerColumn * numColumns)
end

-- The most members the group's header can list: a party is the player and
-- four others, and lists the player only with showPlayer on.
local function GetGroupSize(group, config)
	if group == 'party' and not config.showPlayer then
		return GROUP_HEADERS[group].size - 1
	end
	return GROUP_HEADERS[group].size
end

-- The header attributes that come from the group's config.
local function GetLayoutAttributes(group, config)
	local layout = GetLayout(config)
	return {
		['initial-width'] = layout.width,
		['initial-height'] = layout.height,
		point = layout.point,
		xOffset = layout.xOffset,
		yOffset = layout.yOffset,
		unitsPerColumn = layout.unitsPerColumn,
		maxColumns = layout.maxColumns,
		columnSpacing = layout.columnSpacing,
		columnAnchorPoint = layout.columnAnchorPoint,
		showPlayer = (group == 'party' and config.showPlayer) and true or false,
	}
end

-- Spawns the party, raid10 and raid40 headers and their holders. The headers
-- start hidden (the template is hidden) and get their layout, buttons and
-- visibility from the first UF:ApplyConfig. Out of combat only (OnEnable).
function UF:CreateGroupHeaders()
	self.groups = {}
	for group, info in pairs(GROUP_HEADERS) do
		local config = self:GetProfileConfig()[group]

		self.holders[group] = CreateFrame('Frame', 'SaftUI_' .. info.name .. 'Holder', UIParent)

		local attributes = {
			['oUF-initialConfigFunction'] = INITIAL_CONFIG,
			showParty = group == 'party',
			showRaid = group ~= 'party',
			groupFilter = '1,2,3,4,5,6,7,8',
			groupingOrder = '1,2,3,4,5,6,7,8',
			groupBy = 'GROUP',
			-- Read by UF.ConstructUnit, to find the buttons' config.
			base_unit = group,
		}
		for name, value in pairs(GetLayoutAttributes(group, config)) do
			attributes[name] = value
		end

		local header = self.oUF:SpawnHeader('SaftUI_' .. info.name, nil, attributes)
		header.config = config
		-- Test mode previews make way for the real frames, and come back.
		-- HookScript runs after the header's own (secure) handlers.
		header:HookScript('OnShow', function() UF:UpdateGroupPreview(group) end)
		header:HookScript('OnHide', function() UF:UpdateGroupPreview(group) end)
		self.groups[group] = header
	end
end

-- The header makes a unit button the first time it has a member for it, which
-- can be in combat (someone joins), and SaftUI's style function can't do all
-- of its work on a secure button then (RegisterForClicks is protected). So
-- every button the header can need is made now, out of combat: a startingIndex
-- below 1 makes the header lay out that many extra, empty slots, then it goes
-- back to normal. A hidden header lays nothing out, so it's shown for that.
local function CreateHeaderChildren(header, count)
	if count < 1 or header:GetAttribute('child' .. count) then return end
	local shown = header:IsShown()
	header:SetAttribute('startingIndex', 1 - count)
	if not shown then header:Show() end
	header:SetAttribute('startingIndex', 1)
	if not shown then header:Hide() end
end

-- Re-applies the group's config to its header: the layout attributes, the
-- buttons it can need, and when it shows (never, while the group is disabled).
-- UF:ApplyConfig resizes the buttons already made before this, so the
-- header's last layout pass here measures them at their new size. Out of
-- combat only.
function UF:ApplyGroupLayout(group)
	local header = self.groups[group]
	local config = self:GetProfileConfig()[group]

	-- All at once, without a layout pass after each one (the header's own
	-- _ignore switch, as setAttributesWithoutResponse in SecureGroupHeaders.lua uses).
	header:SetAttribute('_ignore', 'attributeChanges')
	for name, value in pairs(GetLayoutAttributes(group, config)) do
		header:SetAttribute(name, value)
	end
	header:SetAttribute('_ignore', nil)

	local _, _, _, _, count = GetLayoutSize(GetLayout(config), GetGroupSize(group, config))
	CreateHeaderChildren(header, count)

	-- A shown header lays itself out again on any attribute change, so this
	-- one makes it measure everything as it is now.
	header:SetAttribute('saftui-layout', (header:GetAttribute('saftui-layout') or 0) + 1)

	local visibility = config.enable and GROUP_HEADERS[group].visibility or 'hide'
	if header.visibility ~= visibility then
		header:SetVisibility('custom ' .. visibility)
	end
end

-- Sizes the group's holder to every member the header can list, laid out as
-- the header lays them out, and places it at the group's position. The holder
-- counts as protected in combat while the header is anchored to it.
function UF:PlaceGroupHolder(group)
	local holder = self.holders[group]
	local config = self:GetProfileConfig()[group]
	local width, height = GetLayoutSize(GetLayout(config), GetGroupSize(group, config))
	holder:ClearAllPoints()
	holder:SetPoint(st:UnpackPoint(config.position))
	st:SetSize(holder, width, height)
end

-- Anchors the header to its holder at the group's position point. The header
-- sizes itself to the members it shows, so they start from that point: a
-- party placed by its top-left corner fills its spot from there.
function UF:AnchorGroupHeader(group)
	local point = self:GetProfileConfig()[group].position.point
	local header = self.groups[group]
	header:ClearAllPoints()
	header:SetPoint(point, self.holders[group], point)
end

-- A group mover's apply, after a drag, a nudge or a profile change: the
-- holder and the header on it follow the group's position. In combat both wait
-- for the end of combat (the header is secure, and so the holder too).
function UF:ApplyGroupPosition(group)
	st:SafeReposition(self.holders[group], 'uf_holder_' .. group, function() self:PlaceGroupHolder(group) end)
	st:SafeReposition(self.groups[group], 'uf_' .. group, function() self:AnchorGroupHeader(group) end)
	self:UpdateGroupPreview(group)
end

------------------------------------
---- Test mode ---------------------
------------------------------------
--[[
	A group's test mode fills its holder with preview frames for made-up
	members, so a raid layout can be checked without a raid. The previews are
	SaftUI's own plain frames, built from the same element helpers and the
	same config as the real buttons (size, template, health and power bars,
	name text, role corner, range alpha), and laid out with the header's own
	sums. No unit is ever faked: no secure frame, unit attribute or Blizzard
	unit function is involved, and the bars are filled straight from the data
	below.

	Not drawn: auras, castbars, portraits, raid target, ready check and
	leader/assist icons, and the level in the name.

	UF.testGroups is a plain field: not saved, off after a /reload. A profile
	switch keeps it on and restyles the previews for the new profile. They hide
	while the group's real header shows.
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

-- A color object, or nil for anything else (a missing class or power color).
local function AsColor(color)
	if type(color) == 'table' and color.GetRGB then return color end
end

-- r, g, b of a color object or a plain { r, g, b } list (customColor can be either).
local function UnpackColor(color)
	if AsColor(color) then return color:GetRGB() end
	return color[1], color[2], color[3]
end

-- One preview frame, with the same pieces UF.ConstructUnit and the element
-- constructors give a real button (made with the same helpers), minus
-- everything oUF drives: health and power bars with their texts, the name
-- and the role corner.
local function CreatePreviewFrame(container, group, index)
	local frame = CreateFrame('Frame', ('SaftUI_%sPreview%d'):format(GROUP_HEADERS[group].name, index), container)
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
	st:SetBackdrop(frame, config.template)
	for _, element in ipairs(frame.previewElements) do
		UF:UpdateElement(element)
	end
	local role = frame.GroupRoleIndicator
	role:SetSize(role.config.size, role.config.size)
end

-- Shows one member the way the real elements would: the health color order
-- of oUF's health element, the deficit text of SaftUI's health PostUpdate,
-- the power color order of oUF's power element, the name tag's caps, length
-- and class color, the role corner's colors, and the range element's alpha.
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
	elseif healthConfig.colorClass then
		color = classColor
	elseif healthConfig.colorReaction then
		color = colors.reaction[5] -- friendly
	elseif healthConfig.colorHealth then
		color = colors.health
	end
	color = AsColor(color)
	if healthConfig.colorCustom and healthConfig.customColor then
		health:SetStatusBarColor(UnpackColor(healthConfig.customColor))
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
		end
		health.text:SetText(text)
	end

	local power = frame.Power
	local powerConfig = power.config
	if powerConfig.enable then
		local powerValue = (member.dead or member.offline) and 0 or member.power
		-- SaftUI's power PostUpdate puts these textures back on every update.
		power:SetStatusBarTexture(st.BLANK_TEX)
		power.bg:SetTexture(st.BLANK_TEX)
		power:SetMinMaxValues(0, 1)
		power:SetValue(powerValue)

		color = nil
		if powerConfig.colorDisconnected and member.offline then
			color = colors.disconnected
		elseif powerConfig.colorPower then
			color = AsColor(colors.power[member.powerType]) or colors.power.MANA
		elseif powerConfig.colorClass then
			color = classColor
		elseif powerConfig.colorReaction then
			color = colors.reaction[5]
		end
		color = AsColor(color)
		if color then
			local r, g, b = color:GetRGB()
			power:SetStatusBarColor(r, g, b)
			UF.SetPowerBackgroundColor(power, r, g, b)
		elseif powerConfig.colorCustom and powerConfig.customColor then
			power:SetStatusBarColor(UnpackColor(powerConfig.customColor))
		end

		if power.text and powerConfig.text.enable then
			local max = member.powerType == 'MANA' and PREVIEW_MAX_MANA or PREVIEW_MAX_POWER
			local current = math.floor(max * powerValue + 0.5)
			if powerConfig.text.hide_full and current == max then
				power.text:SetText('')
			else
				power.text:SetText(current < 10000 and current or st.StringFormat:ShortFormat(current, 1))
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
		if nameConfig.colorClass and classColor then
			text = st.StringFormat:ColorString(text, classColor:GetRGB())
		end
		name:SetText(text)
	end

	-- The role corner's colors and rules from its postUpdate in
	-- elements/indicators.lua. That one doesn't check enable, but a disabled
	-- corner is never anchored (UF:UpdateElement stops first), so enable
	-- decides here: on for party, off for the raids, by default.
	local role = frame.GroupRoleIndicator
	local roleConfig = role.config
	local textColors = st.config.profile.colors.text
	role:SetTexture(st.textures.cornerbr)
	role:SetTexCoord(0, 1, 0, 1)
	if member.role == 'HEALER' then
		role:SetVertexColor(textColors.green:GetRGB())
	elseif member.role == 'TANK' then
		role:SetVertexColor(textColors.blue:GetRGB())
	else
		role:SetVertexColor(textColors.red:GetRGB())
	end
	role:SetShown((roleConfig.enable and (roleConfig.showDps or member.role == 'HEALER' or member.role == 'TANK')) and true or false)

	-- oUF's range element shows offline members at full alpha.
	local alpha = frame.config.range_alpha
	frame:SetAlpha((member.outOfRange and not member.offline) and alpha.outside or alpha.inside)
end

-- Places the first count frames inside container the way configureChildren in
-- SecureGroupHeaders.lua places a header's buttons inside the header.
local function ArrangeLikeHeader(container, frames, count, layout, unitsPerColumn, numColumns)
	local point = layout.point
	local relativePoint, xOffsetMult, yOffsetMult = GetRelativePointAnchor(point)
	local xMultiplier, yMultiplier = math.abs(xOffsetMult), math.abs(yOffsetMult)

	local columnAnchorPoint, columnRelPoint, colxMulti, colyMulti
	if numColumns > 1 then
		columnAnchorPoint = layout.columnAnchorPoint
		columnRelPoint, colxMulti, colyMulti = GetRelativePointAnchor(columnAnchorPoint)
	end

	local columnUnitCount = 0
	for i = 1, count do
		local frame = frames[i]
		columnUnitCount = columnUnitCount + 1
		if columnUnitCount > unitsPerColumn then
			columnUnitCount = 1
		end

		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint(point, container, point, 0, 0)
			if columnAnchorPoint then
				frame:SetPoint(columnAnchorPoint, container, columnAnchorPoint, 0, 0)
			end
		elseif columnUnitCount == 1 then
			frame:SetPoint(columnAnchorPoint, frames[i - unitsPerColumn], columnRelPoint,
				colxMulti * layout.columnSpacing, colyMulti * layout.columnSpacing)
		else
			frame:SetPoint(point, frames[i - 1], relativePoint,
				xMultiplier * layout.xOffset, yMultiplier * layout.yOffset)
		end
	end
end

-- Shows, restyles and lays out a group's previews from the current profile,
-- or hides them: test mode off, the group disabled, or its real header
-- showing. The container stands in for the header: same size for the same
-- members, anchored to the holder at the same point. None of this is secure,
-- so it can run in combat (the header's OnShow/OnHide).
function UF:UpdateGroupPreview(group)
	local container = self.previews[group]
	local header = self.groups and self.groups[group]
	local config = self:GetProfileConfig()[group]
	if not (self.testGroups[group] and header and config.enable and not header:IsShown()) then
		if container then container:Hide() end
		return
	end

	if not container then
		container = CreateFrame('Frame', nil, UIParent)
		container.frames = {}
		self.previews[group] = container
	end

	local layout = GetLayout(config)
	local width, height, unitsPerColumn, numColumns, count = GetLayoutSize(layout, GetGroupSize(group, config))
	local point = config.position.point
	container:ClearAllPoints()
	container:SetPoint(point, self.holders[group], point)
	container:SetSize(width, height)

	for i = 1, count do
		local frame = container.frames[i] or CreatePreviewFrame(container, group, i)
		container.frames[i] = frame
		StylePreviewFrame(frame)
		FillPreviewFrame(frame, PREVIEW_MEMBERS[i])
		frame:Show()
	end
	for i = count + 1, #container.frames do
		container.frames[i]:Hide()
	end
	ArrangeLikeHeader(container, container.frames, count, layout, unitsPerColumn, numColumns)

	container:Show()
end

-- The /sui "Test mode" toggle.
function UF:SetGroupTestMode(group, enabled)
	self.testGroups[group] = enabled and true or nil
	self:UpdateGroupPreview(group)
end
