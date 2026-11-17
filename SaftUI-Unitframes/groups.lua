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
	itself was placed at that position. Where the header puts its buttons, and
	how big it makes itself, is grouplayout.lua's math.

	Under the Blizzard theme each header sits in Blizzard's raid group border
	(the section after the headers').

	While either raid group is enabled, Blizzard's raid frames are hidden
	(blizzardraid.lua).

	Test mode (grouppreview.lua) fills the holder with SaftUI-owned preview
	frames for made-up members, and the boss holder with made-up bosses.
]]

-- Group key -> its frame names, how many members it can list, and when it
-- shows. Raid unit ids are numbered from 1 with no gaps, so raid11 exists
-- exactly when the raid has 11 or more members.
local GROUP_HEADERS = {
	party = { name = 'Party', size = 5, visibility = '[group:raid] hide; [group:party] show; hide' },
	raid10 = { name = 'Raid10', size = 10, visibility = '[@raid11,exists] hide; [group:raid] show; hide' },
	raid40 = { name = 'Raid40', size = 40, visibility = '[@raid11,exists] show; hide' },
}
-- blizzardraid.lua and grouppreview.lua read it too.
UF.GROUP_HEADERS = GROUP_HEADERS

-- Runs in the restricted environment each time the header makes a unit
-- button (oUF runs it at the end of its own initial config), in combat too.
-- It sizes the button from the header's attributes, which UF:ApplyGroupLayout
-- keeps in step with the profile.
local INITIAL_CONFIG = [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute('initial-width'))
	self:SetHeight(header:GetAttribute('initial-height'))
]]

-- The most members the group's header can list: a party is the player and
-- four others, and lists the player only with showPlayer on.
local function GetGroupSize(group, config)
	if group == 'party' and not config.showPlayer then
		return GROUP_HEADERS[group].size - 1
	end
	return GROUP_HEADERS[group].size
end
-- grouppreview.lua counts a group's previews with it.
UF.GetGroupSize = GetGroupSize

-- The header attributes that come from the group's config.
local function GetLayoutAttributes(group, config)
	local layout = UF.GetGroupLayout(config)
	return {
		['initial-width'] = layout.width,
		['initial-height'] = layout.height,
		point = layout.point,
		xOffset = layout.xOffset,
		yOffset = layout.yOffset,
		unitsPerColumn = layout.unitsPerColumn,
		-- Never more columns than the group needs. Otherwise raid10's 5x8 default lets
		-- the header lay out an 11th member (in combat, at the 10 -> 11 change, before
		-- its state driver hides it) and create a button that wasn't made out of combat.
		maxColumns = math.min(layout.maxColumns, math.ceil(GetGroupSize(group, config) / layout.unitsPerColumn)),
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
		-- Made now, out of combat: in combat it only shows, hides and redraws.
		self:GroupBorder(header)
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

	local _, _, _, _, count = UF.GetGroupLayoutSize(UF.GetGroupLayout(config), GetGroupSize(group, config))
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
	local width, height = UF.GetGroupLayoutSize(UF.GetGroupLayout(config), GetGroupSize(group, config))
	st:PlaceAtPosition(holder, config.position)
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
---- The group border --------------
------------------------------------
--[[
	Under the Blizzard theme a group's members sit in the box, the one border
	Blizzard's look draws everywhere (ThemeArt.LayBox), 4 outside the group
	(KINDS.unitframe's reach, in whole pixels): one around each header's shown
	members (the party; a whole raid, not each raid group), and one around a
	party or raid group's test mode previews. The members draw no border of
	their own under Blizzard (they're drawn as members).

	The header is secure, and lays itself out (shows, places and sizes its
	members, and sizes itself to them) when someone joins or leaves, in
	combat too. So the border is a plain frame of SaftUI's, the header's
	child, anchored to it: it follows the header's size by its anchors, with
	no code of SaftUI's running. It isn't protected (protection spreads from a
	protected frame to its parents and to the frames it's anchored to, not to
	its children or to frames anchored to it), so showing, hiding and drawing
	it is fine in combat too, and nothing protected is called. Nothing is
	written onto the header: the border is kept in a weak table keyed by it
	(.agents/taint.md).

	The box lies over what it borders, so the border is raised one level over
	the highest of the header's children and their children (ThemeArt.LevelAbove,
	depth 2): the members and their bars, which the rim covers the outer pixels of. That only happens out of combat (UF:UpdateGroupBorder): a
	member the header makes in combat sits at the level it was given, and the
	border keeps its last level until the next draw out of combat, a plain
	SetFrameLevel on SaftUI's own frame that nothing in combat depends on.

	A header can show with no member to show: the party's, with showPlayer
	off (its default), for every pending invite (an invite makes a group of
	one at once, so [group:party] holds) and briefly while a group disbands.
	It sizes itself to a sliver then (minWidth by minHeight, at least 0.1:
	configureChildren in SecureGroupHeaders.lua), about 200 by 0.1 for the
	party, where the border would be a strip of the box. So the border's art
	is hidden (its alpha 0) while either side is under two of its pieces,
	and shown again once they fit, from the border's own OnSizeChanged.
	That's code of SaftUI's running in combat, but only on its own border,
	calling nothing protected (alpha isn't).
]]

-- owner (a group header or a preview container) -> its border.
local groupBorders = setmetatable({}, { __mode = 'k' })

-- Shows a border's art while two of its pieces fit on each side, and hides
-- it (alpha 0) on anything smaller: a header with no member to show (above).
-- Only the border's alpha, so in combat too; a secret size leaves it as it is.
local function FitBorder(border, width, height)
	if issecretvalue(width) or issecretvalue(height) then return end
	local pieces = st.ThemeArt.Get(border)
	pieces = pieces and pieces.pieces
	-- This client's corners as laid (Forever's 6, retail's 6 and 7), 12 until
	-- the box is laid.
	local function Size(a, b, side)
		local first, second = pieces and pieces[a], pieces and pieces[b]
		if not (first and second) then return 12 end
		local one, two = first[side](first), second[side](second)
		if issecretvalue(one) or issecretvalue(two) then return 12 end
		return one + two
	end
	local leastWidth = math.max(Size('TopLeftCorner', 'TopRightCorner', 'GetWidth'), Size('BottomLeftCorner', 'BottomRightCorner', 'GetWidth'))
	local leastHeight = math.max(Size('TopLeftCorner', 'BottomLeftCorner', 'GetHeight'), Size('TopRightCorner', 'BottomRightCorner', 'GetHeight'))
	border:SetAlpha((width < leastWidth or height < leastHeight) and 0 or 1)
end

-- Anchors border around owner, the box's reach outside it in whole pixels
-- (drawn again with the group, so a scale change is followed; in combat too:
-- the border is unprotected).
local function AnchorBorder(border, owner)
	local reach = st.ThemeArt.Whole(st.ThemeArt.Reach('unitframe'), owner)
	border:ClearAllPoints()
	border:SetPoint('TOPLEFT', owner, 'TOPLEFT', -reach, reach)
	border:SetPoint('BOTTOMRIGHT', owner, 'BOTTOMRIGHT', reach, -reach)
end

-- The border of owner, a group header or a test mode preview container: made
-- the first time, as owner's child at owner's frame level (left at the level
-- it was made at when owner's level is secret; UF:UpdateGroupBorder raises it
-- out of combat), anchored around owner (AnchorBorder), its art shown only
-- while it fits (FitBorder). It starts hidden; UF:UpdateGroupBorder shows it.
function UF:GroupBorder(owner)
	local border = groupBorders[owner]
	if border then return border end
	border = CreateFrame('Frame', nil, owner)
	local level = owner:GetFrameLevel()
	if not issecretvalue(level) then border:SetFrameLevel(level + 1) end
	AnchorBorder(border, owner)
	border:SetScript('OnSizeChanged', FitBorder)
	border:Hide()
	groupBorders[owner] = border
	return border
end

-- Whether a group's config draws its members in Blizzard's look, so the group
-- border shows: the frame's Theme and Background, or, where the frame's
-- Theme is None (the party's default), its health's.
function UF.GroupBorderShown(config)
	if config.theme == 'none' then
		return st:IsBlizzardLook(config.health.theme, config.health.background)
	end
	return st:IsBlizzardLook(config.theme, config.background)
end

-- Draws and shows owner's border, or clears and hides it, by the group's config.
local function UpdateBorder(owner, config)
	local border = UF:GroupBorder(owner)
	if UF.GroupBorderShown(config) then
		-- Out of combat only: a header's member made in combat keeps the level
		-- it was given, and the border its last one (above).
		AnchorBorder(border, owner)
		if not InCombatLockdown() then
			-- Depth 2: over the members and their bars.
			local level = st.ThemeArt.LevelAbove(owner, border, 2)
			if level then border:SetFrameLevel(level) end
		end
		st.ThemeArt.PaintBox(border)
		FitBorder(border, border:GetSize())
		border:Show()
	else
		st.ThemeArt.Clear(border)
		border:Hide()
	end
end
-- grouppreview.lua draws a preview container's border with it.
UF.UpdateBorder = UpdateBorder

-- The group border of a party or raid group, on its header and on its preview
-- container, each when it exists, from the current profile. Touches only
-- SaftUI's borders, so it runs in and out of combat (UF:ApplyConfig). Boss has
-- no header: its frames are unit frames, in boxes of their own.
function UF:UpdateGroupBorder(group)
	if not GROUP_HEADERS[group] then return end
	local config = self:GetProfileConfig()[group]
	local header = self.groups and self.groups[group]
	if header then UpdateBorder(header, config) end
	local container = self.previews[group]
	if container then UpdateBorder(container, config) end
end

