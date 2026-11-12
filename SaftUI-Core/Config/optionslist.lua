local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The select list (st.OptionsWidgets, optionswidgets.lua): one list every
	select opens (W.OpenList, W.CloseList, W.ListOwner), and the check list
	drawn on its frames (W.OpenCheckList).
]]

local floor, max, min = math.floor, math.max, math.min

local Box, BlizzardLook = W.Box, W.BlizzardLook
local LIST_STRATA = Kit.LIST_STRATA
local BG, EDGE, Colors, FIELD_FONT_SIZE = Kit.BG, Kit.EDGE, Kit.Colors, Kit.FIELD_FONT_SIZE
local SetFieldFont, NewText, Art, Changes = Kit.SetFieldFont, Kit.NewText, Kit.Art, Kit.Changes
local ShowBox, PaintFace, CheckBox, LookCheckBox = Kit.ShowBox, Kit.PaintFace, Kit.CheckBox, Kit.LookCheckBox
local SetCheck = Kit.SetCheck

local LIST_ROW_HEIGHT, LIST_MAX_ROWS = 22, 12
local LIST_WHEEL_ROWS = 3 -- a turn of the wheel over the list, or over its scroll bar

------------------------------------------------------------------ the select list

-- One list shared by every select: a column of up to 12 rows over a scrollable
-- list of entries, closed by a choice, a click outside or Esc.
local list

-- Where the rows sit in from the list's edges (left, top, right, bottom)
-- under Thick and Thin: inside Box's edge. Under Blizzard the dropdown's
-- listInsets.
local LIST_INSETS = { 1, 1, 1, 1 }

-- The check list's (below): a row laid out for the list that's open, and a
-- click on a check list's row.
local LayCheckRow, ToggleCheck

local function ListFill()
	local entries, offset = list.entries, list.offset
	for i, row in ipairs(list.rows) do
		local entry = entries[offset + i]
		if entry then
			row.entry = entry
			if list.fontMode then
				SetFieldFont(row.text, entry.font, FIELD_FONT_SIZE, '')
			else
				SetFieldFont(row.text)
			end
			row.text:SetText(entry.label)
			if entry.key == list.selected then
				row.text:SetTextColor(Colors().text.blue:GetRGB())
			else
				row.text:SetTextColor(Colors().text.normal:GetRGB())
			end
			LayCheckRow(row, entry)
			row:Show()
		else
			row.entry = nil
			row:Hide()
		end
	end
	-- The scroll bar, shown when there's more than the rows show: under
	-- Blizzard Blizzard's narrow one, inside the list on its right beside
	-- the rows' top and bottom (in rows); else the 3px bar.
	local total, shown = #entries, min(#entries, LIST_MAX_ROWS)
	local blizzardBar = list.blizzardBar
	if list.blizzard then
		list.bar:Hide()
		blizzardBar:Set(list.frame, list.frame:GetWidth() - list.insets[3] - blizzardBar.width, list.insets[2],
			shown * LIST_ROW_HEIGHT, shown, total, offset)
	elseif total > shown then
		blizzardBar:Hide()
		local track = shown * LIST_ROW_HEIGHT
		list.bar:SetHeight(max(10, track * shown / total))
		list.bar:ClearAllPoints()
		list.bar:SetPoint('TOPRIGHT', list.frame, 'TOPRIGHT', -2, -list.insets[2] - (track - list.bar:GetHeight()) * offset / (total - shown))
		list.bar:Show()
	else
		blizzardBar:Hide()
		list.bar:Hide()
	end
end

-- The list scrolled to offset (in rows), within its entries: what its
-- Blizzard scroll bar's arrows, track and thumb ask for.
local function ScrollList(offset)
	if not list.entries then return end
	list.offset = max(0, min(#list.entries - LIST_MAX_ROWS, floor(offset + 0.5)))
	ListFill()
end

-- The list's owner's dropdown face is open while the list shows.
function W.CloseList()
	if list then
		local owner = list.owner
		list.owner, list.onPick, list.entries = nil, nil, nil
		list.isChecked, list.onToggle = nil, nil
		list.catcher:Hide()
		if owner then PaintFace(owner) end
	end
end

-- Row i of the list, list.insets in from the list's sides and top.
local function PlaceListRow(row, i)
	local insets = list.insets
	local y = -insets[2] - (i - 1) * LIST_ROW_HEIGHT
	row:ClearAllPoints()
	row:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', insets[1], y)
	row:SetPoint('TOPRIGHT', list.frame, 'TOPRIGHT', -insets[3], y)
end

-- The list in SaftUI's theme now, when it changed. Box, the rows inside its
-- edge (LIST_INSETS), a row under the mouse lit blue at 0.25. Or under
-- Blizzard the Settings menu's (st.ThemeArt.Control('dropdown')): no Box;
-- c-bg, the menu's own border and shadow, on list.skin, a plain frame of
-- SaftUI's just under the list (the theme draws nothing on it, so there's no
-- second border), at listOutsets round the list; the rows listInsets in; a
-- row under the mouse on rowHover. list.blizzard is the look, for a check
-- list's boxes (LayCheckRow); list.insets where the rows sit (OpenList,
-- ListFill).
local function LookList()
	local blizzard = BlizzardLook()
	list.blizzard = blizzard
	if not Changes(Art(list.frame), blizzard) then return end
	ShowBox(list.frame, not blizzard, BG)
	local look = blizzard and st.ThemeArt.Control('dropdown')
	if blizzard and not list.skin then
		list.skin = CreateFrame('Frame', nil, list.catcher)
		list.skin:SetAllPoints(list.frame)
		list.menu = list.skin:CreateTexture(nil, 'BACKGROUND')
	end
	if list.skin then list.skin:SetShown(blizzard) end
	if blizzard then
		local outsets = look.listOutsets
		list.skin:SetFrameLevel(max(0, list.frame:GetFrameLevel() - 1))
		list.menu:SetAtlas(look.list)
		list.menu:ClearAllPoints()
		list.menu:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', outsets[1], outsets[2])
		list.menu:SetPoint('BOTTOMRIGHT', list.frame, 'BOTTOMRIGHT', outsets[3], outsets[4])
	end
	list.insets = blizzard and look.listInsets or LIST_INSETS
	for i, row in ipairs(list.rows) do
		PlaceListRow(row, i)
		if blizzard then
			row.hover:SetAtlas(look.rowHover)
			row.hover:SetAlpha(1)
		else
			row.hover:SetColorTexture(Colors().button.blue:GetRGB())
			row.hover:SetAlpha(0.25)
		end
	end
end

local function BuildList()
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata(LIST_STRATA)
	catcher:SetFrameLevel(50)
	catcher:EnableMouse(true)
	catcher:Hide()

	local frame = Box(st:CreateFrame('Frame', nil, catcher), BG)
	frame:SetFrameLevel(60)
	frame:EnableMouse(true)
	frame:EnableMouseWheel(true)

	local bar = frame:CreateTexture(nil, 'OVERLAY')
	bar:SetColorTexture(unpack(EDGE))
	bar:SetWidth(3)
	bar:Hide()

	list = { catcher = catcher, frame = frame, bar = bar, rows = {}, offset = 0, insets = LIST_INSETS }
	list.blizzardBar = W.BlizzardBar(frame, ScrollList, { narrow = true, step = 1, wheel = LIST_WHEEL_ROWS })

	for i = 1, LIST_MAX_ROWS do
		local row = CreateFrame('Button', nil, frame)
		row:SetHeight(LIST_ROW_HEIGHT)
		PlaceListRow(row, i)
		row:SetFrameLevel(frame:GetFrameLevel() + 1)
		row.hover = row:CreateTexture(nil, 'BACKGROUND')
		row.hover:SetAllPoints()
		row.hover:SetColorTexture(Colors().button.blue:GetRGB())
		row.hover:SetAlpha(0.25)
		row.hover:Hide()
		row.text = NewText(row, 'LEFT')
		row.text:SetPoint('LEFT', row, 'LEFT', 8, 0)
		row.text:SetPoint('RIGHT', row, 'RIGHT', -10, 0)
		row:SetScript('OnEnter', function(self) self.hover:Show() end)
		row:SetScript('OnLeave', function(self) self.hover:Hide() end)
		row:SetScript('OnClick', function(self)
			if list.onToggle then return ToggleCheck(self) end
			local entry, onPick = self.entry, list.onPick
			W.CloseList()
			if entry and onPick then onPick(entry.key) end
		end)
		list.rows[i] = row
	end

	frame:SetScript('OnMouseWheel', function(_, delta)
		local over = #list.entries - LIST_MAX_ROWS
		if over <= 0 then return end
		list.offset = max(0, min(over, list.offset - delta * LIST_WHEEL_ROWS))
		ListFill()
	end)
	catcher:SetScript('OnMouseDown', W.CloseList)
	-- Esc closes the list; every other key goes on to the game.
	W.CatchKeys(catcher, { ESCAPE = true }, function(key)
		if key == 'ESCAPE' then W.CloseList() end
	end)
end

-- Opens the list under owner (a frame; above it when there's no room below).
-- entries: { {key, label, font = path} }, the selected key shows blue, and
-- onPick(key) runs on a choice. fontMode draws each label in its own face
-- (entry.font). An empty list doesn't open.
function W.OpenList(owner, entries, selected, onPick, fontMode)
	if not list then BuildList() end
	W.CloseList()
	if #entries == 0 then return end
	list.owner, list.entries, list.selected, list.onPick, list.fontMode = owner, entries, selected, onPick, fontMode
	LookList()

	local rows = min(#entries, LIST_MAX_ROWS)
	local height = rows * LIST_ROW_HEIGHT + list.insets[2] + list.insets[4]
	list.frame:SetSize(max(owner:GetWidth(), W.WIDTH.select), height)
	list.frame:SetScale(owner:GetEffectiveScale() / UIParent:GetEffectiveScale())
	list.frame:ClearAllPoints()
	local bottom = owner:GetBottom()
	if bottom and bottom - height * list.frame:GetScale() < 0 then
		list.frame:SetPoint('BOTTOMLEFT', owner, 'TOPLEFT', 0, 2)
	else
		list.frame:SetPoint('TOPLEFT', owner, 'BOTTOMLEFT', 0, -2)
	end

	list.offset = 0
	for i, entry in ipairs(entries) do
		if entry.key == selected then
			list.offset = max(0, min(#entries - LIST_MAX_ROWS, i - 1))
			break
		end
	end
	ListFill()
	list.catcher:Show()
	PaintFace(owner)
end

-- The list's frames { catcher, frame, rows, skin, menu, insets, ... } (nil
-- until first opened; skin and menu, c-bg, from the first Blizzard look).
-- For tests.
function W.GetListFrames() return list end

-- The frame the open list belongs to, or nil.
function W.ListOwner()
	return list and list.catcher:IsShown() and list.owner or nil
end

------------------------------------------------------------------ the check list

-- A row of the open list: a check list's has a check box at its left, marked
-- by isChecked(key), and its label after it; a select's has no box and its
-- label 8 in, as BuildList made it. Rows are shared by both, so each fill
-- lays them out for the list that's open. Under Blizzard (list.blizzard,
-- LookList) the box is the Settings panel's check box, as every check box.
function LayCheckRow(row, entry)
	local checking = list.isChecked ~= nil
	if checking and not row.box then
		row.box = CheckBox(row, 18)
		row.box:SetPoint('LEFT', row, 'LEFT', 6, 0)
		row.box:EnableMouse(false)
	end
	if row.box then
		row.box:SetShown(checking)
		if checking then
			LookCheckBox(row.box, list.blizzard or false, LIST_ROW_HEIGHT, 'LEFT')
			SetCheck(row.box, list.isChecked(entry.key))
		end
	end
	if (row.checking or false) ~= checking then
		row.checking = checking
		row.text:ClearAllPoints()
		if checking then
			row.text:SetPoint('LEFT', row.box, 'RIGHT', 8, 0)
		else
			row.text:SetPoint('LEFT', row, 'LEFT', 8, 0)
		end
		row.text:SetPoint('RIGHT', row, 'RIGHT', -10, 0)
	end
end

-- A click on a check list's row: onToggle(key), then the marks again while
-- the list is still this one (onToggle may close it, or open another).
function ToggleCheck(row)
	local entry, onToggle = row.entry, list.onToggle
	if not entry then return end
	onToggle(entry.key)
	if list.onToggle == onToggle and list.catcher:IsShown() then ListFill() end
end

-- Opens the select list's frames under owner as a check list: entries are
-- { {key, label} }, each row a check box marked by isChecked(key). A click on
-- a row calls onToggle(key) and draws the marks again, leaving the list
-- open. A click outside, Esc and W.CloseList close it, and W.ListOwner()
-- reports owner while it's open, so the options window waits to re-render.
-- An empty list doesn't open.
function W.OpenCheckList(owner, entries, isChecked, onToggle)
	W.OpenList(owner, entries, nil, nil)
	if W.ListOwner() ~= owner then return end
	list.isChecked, list.onToggle = isChecked, onToggle
	ListFill()
end
