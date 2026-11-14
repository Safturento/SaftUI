local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The select list (st.OptionsWidgets, optionswidgets.lua): one list every
	select opens (W.OpenList, W.CloseList, W.ListOwner), and two lists drawn
	on its frames: the check list (W.OpenCheckList), whose clicks apply at
	once, and the Apply list (W.OpenApplyList), a check list whose picks wait
	for its Apply button (a shared setting's Apply to: Multiple,
	optionsshare.lua).
]]

local floor, max, min = math.floor, math.max, math.min

local Box, BlizzardLook, HoverEdge, LookButton = W.Box, W.BlizzardLook, W.HoverEdge, W.LookButton
local LIST_STRATA, FIELD_HEIGHT = Kit.LIST_STRATA, Kit.FIELD_HEIGHT
local BG, EDGE, Colors, FIELD_FONT_SIZE = Kit.BG, Kit.EDGE, Kit.Colors, Kit.FIELD_FONT_SIZE
local SetFieldFont, NewText, Art, Changes = Kit.SetFieldFont, Kit.NewText, Kit.Art, Kit.Changes
local ShowBox, PaintFace, CheckBox, LookCheckBox = Kit.ShowBox, Kit.PaintFace, Kit.CheckBox, Kit.LookCheckBox
local SetCheck, CatchKeys = Kit.SetCheck, Kit.CatchKeys

local LIST_ROW_HEIGHT, LIST_MAX_ROWS = 22, 12
local LIST_WHEEL_ROWS = 3 -- a turn of the wheel over the list, or over its scroll bar
local DISABLED_ALPHA = 0.4 -- a disabled entry, as a disabled control (optionscontrols.lua)

-- The Apply list's button: 80 wide (W.Confirm's buttons), 6 under the rows.
-- Under Blizzard it also keeps 6 above the menu's bottom inset; under Thick
-- and Thin the list's padding is that room.
local APPLY_WIDTH, APPLY_GAP = 80, 6

-- A check list's rows (and the Apply list's) sit 4 further in than a select's,
-- on all four sides, so the boxes don't touch the border; a select's rows
-- stay against the edge, as its owner's face does. Blizzard's menu art has its
-- own insets (listInsets) and gets none.
local LIST_PAD = 4

------------------------------------------------------------------ the select list

-- One list shared by every select: a column of up to 12 rows over a scrollable
-- list of entries, closed by a choice, a click outside or Esc.
local list

-- Where the rows sit in from the list's edges (left, top, right, bottom)
-- under Thick and Thin: inside Box's edge. Under Blizzard the dropdown's
-- listInsets. list.insets is these, plus the padding the open list asks for.
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
			-- A caption is Text > Grey; the picked entry blue; the rest normal.
			if entry.caption then
				row.text:SetTextColor(Colors().text.grey:GetRGB())
			elseif entry.key == list.selected then
				row.text:SetTextColor(Colors().text.blue:GetRGB())
			else
				row.text:SetTextColor(Colors().text.normal:GetRGB())
			end
			if entry.caption or entry.disabled then row.hover:Hide() end -- a scroll can put one under the mouse
			row:SetAlpha(entry.disabled and DISABLED_ALPHA or 1)
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
		-- On whole pixels: its height and its place are rounded.
		local height = floor(max(10, track * shown / total) + 0.5)
		list.bar:SetHeight(height)
		list.bar:ClearAllPoints()
		list.bar:SetPoint('TOPRIGHT', list.frame, 'TOPRIGHT', -2, -list.insets[2] - floor((track - height) * offset / (total - shown) + 0.5))
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
		list.isChecked, list.onToggle, list.onApply = nil, nil, nil
		if list.apply then list.apply:Hide() end -- only the Apply list shows it
		for _, button in ipairs(list.checkButtons) do button:Hide() end -- and a check list with buttons theirs
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
	list.baseInsets = blizzard and look.listInsets or LIST_INSETS
	for i, row in ipairs(list.rows) do
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

	list = { catcher = catcher, frame = frame, bar = bar, rows = {}, checkButtons = {}, offset = 0, insets = LIST_INSETS, baseInsets = LIST_INSETS }
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
		-- A caption and a disabled entry are not lit, and do nothing when clicked:
		-- the list stays open.
		row:SetScript('OnEnter', function(self)
			local entry = self.entry
			if not (entry and (entry.caption or entry.disabled)) then self.hover:Show() end
		end)
		row:SetScript('OnLeave', function(self) self.hover:Hide() end)
		row:SetScript('OnClick', function(self)
			if self.entry and (self.entry.caption or self.entry.disabled) then return end
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
	CatchKeys(catcher, { ESCAPE = true }, function(key)
		if key == 'ESCAPE' then W.CloseList() end
	end)
end

-- The rows' insets for the list that's open: the look's, and LIST_PAD more
-- when it's a check list under SaftUI's theme.
local function SetListInsets(padded)
	local base, pad = list.baseInsets, padded and not list.blizzard and LIST_PAD or 0
	list.insets = { base[1] + pad, base[2] + pad, base[3] + pad, base[4] + pad }
	for i, row in ipairs(list.rows) do PlaceListRow(row, i) end
end

-- Opens the list under owner, as W.OpenList says. kind is nil for a select's,
-- 'check' for a check list's (padded rows) and 'apply' for the Apply list's
-- (padded, taller by its button's room). buttons, for a check list's, are
-- its { label, onClick }: the list is as tall as the Apply list's and at
-- least as wide as they are in a row (BUTTONS_GAP apart), plus its insets.
local function OpenList(owner, entries, selected, onPick, fontMode, kind, buttons)
	if not list then BuildList() end
	W.CloseList()
	if #entries == 0 then return end
	list.owner, list.entries, list.selected, list.onPick, list.fontMode = owner, entries, selected, onPick, fontMode
	LookList()
	SetListInsets(kind ~= nil)

	local rows = min(#entries, LIST_MAX_ROWS)
	local count = buttons and #buttons or 0
	local extra = (kind == 'apply' or count > 0) and APPLY_GAP + FIELD_HEIGHT + (list.blizzard and APPLY_GAP or 0) or 0
	local height = rows * LIST_ROW_HEIGHT + list.insets[2] + list.insets[4] + extra
	local width = max(floor(owner:GetWidth() + 0.5), W.WIDTH.select) -- a size read back is a hair off: round it
	if count > 0 then
		width = max(width, count * APPLY_WIDTH + (count - 1) * APPLY_GAP + list.insets[1] + list.insets[3])
	end
	list.frame:SetSize(width, height)
	list.width = width -- as asked, not as read back (which can be a hair off)
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

-- Opens the list under owner (a frame; above it when there's no room below).
-- entries: { {key, label, font = path} }, the selected key shows blue, and
-- onPick(key) runs on a choice. An entry with caption = true is a heading
-- (its label in Text > Grey, no hover, a click that does nothing, the list
-- staying open) and one with disabled = true is dim (alpha 0.4), lit by no
-- mouse and not to be picked. fontMode draws each label in its own face
-- (entry.font). An empty list doesn't open.
function W.OpenList(owner, entries, selected, onPick, fontMode)
	OpenList(owner, entries, selected, onPick, fontMode)
end

-- The list's frames { catcher, frame, rows, skin, menu, insets, apply, ... }
-- (nil until first opened; skin and menu, c-bg, from the first Blizzard look;
-- apply, the Apply list's button, from the first Apply list). For tests.
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

-- A button of the list, made the first time: Box, blue-edged under the mouse,
-- 80 wide and FIELD_HEIGHT tall, its text centred (the Apply list's, and a
-- check list's). Hidden, until it's placed.
local function NewListButton()
	local button = Box(st:CreateFrame('Button', nil, list.frame))
	button:SetSize(APPLY_WIDTH, FIELD_HEIGHT)
	button:SetFrameLevel(list.frame:GetFrameLevel() + 1)
	button.text = NewText(button, 'CENTER')
	button.text:SetAllPoints()
	HoverEdge(button, function() return false end)
	button:Hide()
	return button
end

-- Opens the select list's frames under owner as a check list: entries are
-- { {key, label} }, each row a check box marked by isChecked(key). A click on
-- a row calls onToggle(key) and draws the marks again, leaving the list
-- open. A click outside, Esc and W.CloseList close it, and W.ListOwner()
-- reports owner while it's open, so the options window waits to re-render.
-- An empty list doesn't open.
-- buttons, optional, { { label = 'All', onClick = fn }, ... }: drawn as the
-- Apply list's button is (80 x FIELD_HEIGHT, 6 apart, centred, 6 under the
-- rows; the panel button under Blizzard). A click runs its onClick and draws
-- the marks again; the list stays open. The list is as wide as they are in a
-- row, and its insets, at least.
function W.OpenCheckList(owner, entries, isChecked, onToggle, buttons)
	OpenList(owner, entries, nil, nil, nil, 'check', buttons)
	if W.ListOwner() ~= owner then return end
	list.isChecked, list.onToggle = isChecked, onToggle
	ListFill()
	local count = buttons and #buttons or 0
	if count == 0 then return end
	local rows = min(#entries, LIST_MAX_ROWS)
	local total = count * APPLY_WIDTH + (count - 1) * APPLY_GAP
	local left = floor((list.width - total) / 2)
	local top = -(list.insets[2] + rows * LIST_ROW_HEIGHT + APPLY_GAP)
	for i, spec in ipairs(buttons) do
		local button = list.checkButtons[i]
		if not button then
			button = NewListButton()
			list.checkButtons[i] = button
		end
		button.text:SetText(spec.label)
		button:SetScript('OnClick', function()
			spec.onClick()
			if list.onToggle == onToggle and list.catcher:IsShown() then ListFill() end
		end)
		LookButton(button, list.blizzard or false)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', left + (i - 1) * (APPLY_WIDTH + APPLY_GAP), top)
		button:Show()
	end
end

------------------------------------------------------------------ the Apply list

-- The Apply list's button, made the first time: Box, blue-edged under the
-- mouse, its text Apply; a click runs list.onApply.
local function ApplyButton()
	if not list.apply then
		local button = NewListButton()
		button.text:SetText('Apply')
		button:SetScript('OnClick', function()
			if list.onApply then list.onApply() end
		end)
		list.apply = button
	end
	return list.apply
end

-- Opens the select list's frames under owner as a check list with an Apply
-- button under its rows: entries are { {key, label} }, every row unchecked to
-- start. A click on a row toggles its mark and leaves the list open, calling
-- nothing. Apply closes the list and calls onApply(keys) with the checked
-- keys in entries' order, or nothing when none is checked. Esc, a click
-- outside and W.CloseList close it calling nothing; W.ListOwner() reports
-- owner while it's open. An empty list doesn't open. Under Blizzard the
-- button is the panel button (W.LookButton), as the confirm dialog's.
function W.OpenApplyList(owner, entries, onApply)
	OpenList(owner, entries, nil, nil, nil, 'apply')
	if W.ListOwner() ~= owner then return end
	local checked = {}
	list.isChecked = function(key) return checked[key] end
	list.onToggle = function(key) checked[key] = not checked[key] or nil end
	list.onApply = function()
		local keys = {}
		for _, entry in ipairs(entries) do
			if checked[entry.key] then keys[#keys + 1] = entry.key end
		end
		W.CloseList()
		if #keys > 0 then onApply(keys) end
	end
	ListFill()
	local button = ApplyButton()
	LookButton(button, list.blizzard or false)
	local rows = min(#entries, LIST_MAX_ROWS)
	button:ClearAllPoints()
	button:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', floor((list.width - APPLY_WIDTH) / 2),
		-(list.insets[2] + rows * LIST_ROW_HEIGHT + APPLY_GAP))
	button:Show()
end
