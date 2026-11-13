local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's select and multiselect widgets (st.OptionsWidgets,
	optionswidgets.lua). A select opens the select list (optionslist.lua).
]]

local floor, max, ceil = math.floor, math.max, math.ceil

local Box, Edge, HoverEdge, BlizzardLook = W.Box, W.Edge, W.HoverEdge, W.BlizzardLook
local DropdownStates, LookDropdown = W.DropdownStates, W.LookDropdown
local FIELD_HEIGHT, Base, builders, define = Kit.FIELD_HEIGHT, Kit.Base, Kit.builders, Kit.define
local Colors, FIELD_FONT_SIZE, SetFieldFont = Kit.Colors, Kit.FIELD_FONT_SIZE, Kit.SetFieldFont
local NewText, arts, Art, LookLine, PaintFace = Kit.NewText, Kit.arts, Kit.Art, Kit.LookLine, Kit.PaintFace
local CheckBox, PlaceCheckArt, LookCheckBox = Kit.CheckBox, Kit.PlaceCheckArt, Kit.LookCheckBox
local SetCheck = Kit.SetCheck

------------------------------------------------------------------ select

-- A box that shows its choice and opens the list. The caret is four rows of
-- pixels, 7, 5, 3 and 1 wide, each placed by its left edge on a whole pixel
-- around one centre: placed by their centre, the odd widths would start half a
-- pixel off and blur. Returns the rows (hidden under Blizzard, LookDropdown).
local function Caret(parent)
	local carets = {}
	for i, width in ipairs({ 7, 5, 3, 1 }) do
		local t = parent:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Colors().text.grey:GetRGB())
		t:SetSize(width, 1)
		t:SetPoint('TOPLEFT', parent, 'RIGHT', -12 - floor(width / 2), 3 - i)
		carets[i] = t
	end
	return carets
end

-- Whether a select's row is a font list (LibSharedMedia's LSM30_Font):
-- name -> file, each name drawn in the file's face.
local function IsFontList(row)
	return row.option.dialogControl == 'LSM30_Font'
end

-- The entries for a row's values: { {key, label, font} }. A font list is
-- labeled by the name and drawn in the file's face.
local function ListEntries(root, row)
	local fontMode = IsFontList(row)
	local entries = {}
	for i, value in ipairs(OM.Values(root, row)) do
		if fontMode then
			entries[i] = { key = value.key, label = tostring(value.key), font = value.name }
		else
			entries[i] = { key = value.key, label = tostring(value.name) }
		end
	end
	return entries, fontMode
end

--[[
	Under Blizzard a select whose choices fit has Blizzard's steppers
	(DropdownWithSteppersTemplate): back over its left end and next over its
	right, the face between them (button.faceLeft and faceRight, the steppers
	and their gaps), so the select keeps its 170. A click on one picks the
	previous or next choice in the list's order, as a pick from the list does
	(Commit); one with no choice that way (an end, or a disabled select) is
	disabled, so nothing wraps. The choices fit when the longest's label, in
	the face's font, is at most W.StepperRoom() wide; else the face spans the
	whole select and there are none. That's read at each bind, so they come
	and go as the choices change. A font list never has them: measuring its
	names, each in its own face, would load every font file there is, at
	every render. Nor does an action select (Steppable): one with no value to
	step from (get = false or no get, as AceDBOptions' Copy From and Delete),
	whose next would pick its first choice and run the action in one click,
	or one that confirms, which would ask at every step. Under Thick and Thin
	there are none.
]]

-- Where a stepper's icon sits from its top left (WowStyle2IconButtonTemplate).
local STEPPER_ICON_X, STEPPER_ICON_Y = 4, -3

-- The stepped face's room for its text: the select less the steppers and
-- their gaps, less the text's inset at each side.
function W.StepperRoom()
	local look = st.ThemeArt.Control('dropdown')
	local steps = look.stepper
	return W.WIDTH.select - (steps.width + steps.backGap) - (steps.width + steps.nextGap) - 2 * look.textInset
end

-- A stepper's art in its state, as the face's (PaintFace): disabled, held
-- down under the mouse (pressedhover), under the mouse, held down off it,
-- else normal. Its icon is the disabled one while disabled, and sits
-- pressedOffset further while an enabled one is held down. Nothing until its
-- select first wears the steppers (PlaceStepper).
local function PaintStepper(stepper)
	local art = arts[stepper]
	local look = art.look
	if not look then return end
	local steps, enabled = look.stepper, stepper:IsEnabled()
	local state = 'normal'
	if not enabled then
		state = 'disabled'
	elseif art.down and art.over then
		state = 'pressedhover'
	elseif art.over then
		state = 'hover'
	elseif art.down then
		state = 'pressed'
	end
	art.pieces.Background:SetAtlas(steps.background[state])
	local icon = art.pieces.Icon
	if art.direction < 0 then
		icon:SetAtlas(enabled and steps.back or steps.backDisabled)
	else
		icon:SetAtlas(enabled and steps.next or steps.nextDisabled)
	end
	local x, y = STEPPER_ICON_X, STEPPER_ICON_Y
	if enabled and art.down then x, y = x + look.pressedOffset[1], y + look.pressedOffset[2] end
	icon:ClearAllPoints()
	icon:SetPoint('TOPLEFT', stepper, 'TOPLEFT', x, y)
end

-- One of a select's steppers, back (direction -1) or next (1): a button of
-- the select's own, hidden until it wears them, with the button art round it
-- (Background) and its arrow (Icon). Its state follows the mouse. The game
-- sends a disabled button no OnEnter or OnLeave, so a stepper enabled again
-- reads whether the mouse is on it now.
local function Stepper(w, button, direction)
	local stepper = CreateFrame('Button', nil, button)
	stepper:Hide()
	local art = Art(stepper)
	art.direction = direction
	art.pieces.Background = stepper:CreateTexture(nil, 'BACKGROUND')
	art.pieces.Icon = stepper:CreateTexture(nil, 'ARTWORK')
	local function State(field, value)
		return function(self)
			art[field] = value
			PaintStepper(self)
		end
	end
	stepper:SetScript('OnEnter', State('over', true))
	stepper:SetScript('OnLeave', State('over', false))
	stepper:SetScript('OnMouseDown', State('down', true))
	stepper:SetScript('OnMouseUp', State('down', false))
	stepper:SetScript('OnDisable', State('down', false))
	stepper:SetScript('OnEnable', function(self)
		art.over = self:IsMouseOver()
		PaintStepper(self)
	end)
	-- A pooled select hidden mid-press or under the mouse starts afresh.
	stepper:SetScript('OnHide', function()
		art.over, art.down = false, false
	end)
	stepper:SetScript('OnClick', function() w:Step(direction) end)
	return stepper
end

-- A stepper over side ('LEFT' or 'RIGHT') of button, in look (the dropdown's
-- art): as tall as the button, its art outset round it as the face's is.
local function PlaceStepper(stepper, button, side, look)
	local steps, art = look.stepper, Art(stepper)
	art.look = look
	stepper:SetSize(steps.width, button:GetHeight())
	stepper:ClearAllPoints()
	stepper:SetPoint(side, button, side, 0, 0)
	local background = art.pieces.Background
	background:ClearAllPoints()
	background:SetPoint('TOPLEFT', stepper, 'TOPLEFT', -look.outset, look.outset)
	background:SetPoint('BOTTOMRIGHT', stepper, 'BOTTOMRIGHT', look.outset, -look.outset)
	art.pieces.Icon:SetSize(steps.icon, steps.icon)
end

-- While the steppers show: each enabled when there's a choice to step to
-- that way and the select isn't disabled, and painted. entries are the
-- choices when the caller has them (StepTargets).
local function EnableSteppers(w, entries)
	if not w.stepped then return end
	local back, nextKey
	if not w.disabled then back, nextKey = w:StepTargets(entries) end
	w.back:SetEnabled(back ~= nil)
	w.next:SetEnabled(nextKey ~= nil)
	PaintStepper(w.back)
	PaintStepper(w.next)
end

-- Whether a select may have steppers: not a font list, and not an action:
-- it shows a value to step from (a get that isn't false) and sets it with
-- no confirm.
local function Steppable(w)
	return not IsFontList(w.row) and OM.Has(w.root, w.row, 'get') and not OM.Has(w.root, w.row, 'confirm')
end

-- The select's look: under Blizzard the steppers either side of the face
-- when it may have them (Steppable) and its choices fit (StepsFit), the
-- face between them, else the face across it all; then its dropdown's
-- (LookDropdown). Only the face takes the mouse for the list, as only it
-- lights. The choices are read once, for the fit and the steppers' states;
-- not at all for a select that may have none.
local function LookSelect(w, blizzard)
	local button = w.frame
	local look = blizzard and st.ThemeArt.Control('dropdown')
	local entries = blizzard and Steppable(w) and ListEntries(w.root, w.row) or nil
	w.stepped = entries ~= nil and w:StepsFit(entries)
	if w.stepped then
		local steps = look.stepper
		button.faceLeft, button.faceRight = steps.width + steps.backGap, steps.width + steps.nextGap
		PlaceStepper(w.back, button, 'LEFT', look)
		PlaceStepper(w.next, button, 'RIGHT', look)
	else
		button.faceLeft, button.faceRight = 0, 0
	end
	w.back:SetShown(w.stepped)
	w.next:SetShown(w.stepped)
	button:SetHitRectInsets(button.faceLeft, button.faceRight, 0, 0)
	LookDropdown(button, blizzard)
	EnableSteppers(w, entries)
end

builders.select = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.select, FIELD_HEIGHT)
	w.frame = button
	w.text = NewText(button, 'LEFT')
	w.text:SetPoint('LEFT', button, 'LEFT', 8, 0)
	w.text:SetPoint('RIGHT', button, 'RIGHT', -22, 0)
	button.text = w.text
	button.caret = Caret(button)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnClick', function() w:Open() end)
	button:SetScript('OnHide', function()
		if W.ListOwner() == button then W.CloseList() end
	end)
	DropdownStates(button, function() return w.disabled end)
	w.back = Stepper(w, button, -1)
	w.next = Stepper(w, button, 1)
	-- The choices' labels are measured on this (StepsFit), never shown.
	w.measure = NewText(button, 'LEFT')
	w.measure:SetWordWrap(false)
	w.measure:Hide()
end

define('select', {
	-- The look after the row: whether the steppers fit reads its choices.
	-- Until then they're left be (Refresh and OnDisabled skip them), so
	-- the choices are read once for them (LookSelect).
	Bind = function(self, ...)
		self.stepped = false
		Base.Bind(self, ...)
		LookSelect(self, BlizzardLook())
		return self
	end,

	-- Whether every choice's label (entries, else the row's now) fits the
	-- stepped face (W.StepperRoom), measured in the face's font. True with
	-- no choices; never for a font list, whose names aren't measured.
	StepsFit = function(self, entries)
		if IsFontList(self.row) then return false end
		local room, measure = W.StepperRoom(), self.measure
		SetFieldFont(measure)
		for _, entry in ipairs(entries or ListEntries(self.root, self.row)) do
			measure:SetText(entry.label)
			if ceil(measure:GetUnboundedStringWidth()) > room then return false end
		end
		return true
	end,

	-- The keys a step back and a step forward pick, in the list's order
	-- (entries, else the row's now); nil past an end. A value not among the
	-- choices has none back, and the first next.
	StepTargets = function(self, entries)
		if not self.row then return nil, nil end
		local value = self:Value()
		entries = entries or ListEntries(self.root, self.row)
		for i, entry in ipairs(entries) do
			if entry.key == value then
				local back, forward = entries[i - 1], entries[i + 1]
				return back and back.key, forward and forward.key
			end
		end
		return nil, entries[1] and entries[1].key
	end,

	-- Picks the choice a step back (-1) or forward (1), as a pick from the
	-- list does. Nothing past an end, while disabled, or without steppers.
	Step = function(self, direction)
		if self.disabled or not self.stepped then return end
		local back, forward = self:StepTargets()
		local key
		if direction < 0 then key = back else key = forward end
		if key ~= nil then self:Commit(key) end
	end,

	-- Only the chosen key's label is resolved here; the list is built when it opens.
	Refresh = function(self)
		self.value = self:Value()
		local values = OM.Member(self.root, self.row, 'values')
		local fontMode = IsFontList(self.row)
		local label, font = '', nil
		if type(values) == 'table' and self.value ~= nil and values[self.value] ~= nil then
			if fontMode then
				label, font = tostring(self.value), values[self.value]
			else
				label = tostring(values[self.value])
			end
		end
		if fontMode and font then
			SetFieldFont(self.text, font, FIELD_FONT_SIZE, '')
		else
			SetFieldFont(self.text)
		end
		self.text:SetText(label)
		EnableSteppers(self)
	end,

	-- The list is built from the values as they are now: a function can
	-- depend on other settings.
	Open = function(self)
		if self.disabled or not self.row then return end
		local entries, fontMode = ListEntries(self.root, self.row)
		W.OpenList(self.frame, entries, self:Value(), function(key) self:Commit(key) end, fontMode)
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		PaintFace(self.frame)
		EnableSteppers(self)
	end,

	OnRelease = function(self)
		self.stepped = false
		if W.ListOwner() == self.frame then W.CloseList() end
	end,
})

------------------------------------------------------------------ multiselect

local MULTI_ROW = 22
-- Under Blizzard the box is a line at the multiselect's edge, so its rows sit
-- this far in from it on the left and right, as their boxes are above and below.
local MULTI_INSET = 2

builders.multiselect = function(w)
	local frame = st:CreateFrame('Frame', nil, UIParent) -- no box under Thick and Thin
	frame:SetSize(W.WIDTH.multiselect, MULTI_ROW)
	w.frame = frame
	w.rows = {}
end

-- A row's look: its box's (LookCheckBox), and under Blizzard the box's
-- highlight drawn over it, a texture of the box's own in its OVERLAY layer
-- (row.hover), which the row's OnEnter shows and OnLeave hides: the box takes
-- no mouse, so its own HIGHLIGHT layer never shows, and a texture of the
-- row's would lie under the box's art (a frame's regions draw under its
-- children). Under Thick and Thin the row lights the box's edge instead.
-- Under Blizzard the row's box and label sit MULTI_INSET in, clear of the
-- multiselect's line.
local function LookRow(row, blizzard)
	LookCheckBox(row.box, blizzard, MULTI_ROW, 'LEFT')
	row.blizzard = blizzard
	if blizzard and not row.hover then
		row.hover = row.box:CreateTexture(nil, 'OVERLAY', nil, 1)
	end
	if row.hover then
		if blizzard then
			PlaceCheckArt(row.box, row.hover)
			row.hover:SetAtlas(row.box.look.highlight)
			row.hover:SetBlendMode(row.box.look.highlightBlend)
		end
		row.hover:Hide()
	end
	local inset = blizzard and MULTI_INSET or 0
	row.box:SetPoint('LEFT', row, 'LEFT', inset, 0)
	row.label:SetPoint('RIGHT', row, 'RIGHT', -inset, 0)
end

local function MultiRow(w, i)
	local row = w.rows[i]
	if row then return row end
	row = CreateFrame('Button', nil, w.frame)
	row:SetHeight(MULTI_ROW)
	row:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', 0, -(i - 1) * MULTI_ROW)
	row:SetPoint('TOPRIGHT', w.frame, 'TOPRIGHT', 0, -(i - 1) * MULTI_ROW)
	row.box = CheckBox(row, 18)
	row.box:SetPoint('LEFT', row, 'LEFT', 0, 0)
	row.box:EnableMouse(false)
	row.label = NewText(row, 'LEFT')
	row.label:SetPoint('LEFT', row.box, 'RIGHT', 8, 0)
	row.label:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
	LookRow(row, w.blizzard or false)
	row:SetScript('OnEnter', function(self)
		Edge(self.box, true)
		if self.blizzard then self.hover:Show() end
	end)
	row:SetScript('OnLeave', function(self)
		Edge(self.box, false)
		if self.hover then self.hover:Hide() end
	end)
	row:SetScript('OnClick', function(self)
		if w.disabled or self.key == nil then return end
		w:Commit(self.key, not self.checked)
	end)
	w.rows[i] = row
	return row
end

define('multiselect', {
	Bind = function(self, ...)
		self.blizzard = BlizzardLook()
		LookLine(self.frame, self.blizzard)
		for _, row in ipairs(self.rows) do LookRow(row, self.blizzard) end
		return Base.Bind(self, ...)
	end,

	OnDisabled = function(self, disabled)
		for _, row in ipairs(self.rows) do SetCheck(row.box, row.checked, disabled) end
	end,

	Refresh = function(self)
		local values = OM.Values(self.root, self.row)
		for i, value in ipairs(values) do
			local row = MultiRow(self, i)
			row.key = value.key
			row.checked = self:Value(value.key) and true or false
			SetCheck(row.box, row.checked, self.disabled)
			row.label:SetText(tostring(value.name))
			row:Show()
		end
		for i = #values + 1, #self.rows do
			self.rows[i].key = nil
			self.rows[i]:Hide()
		end
		self.frame:SetHeight(max(MULTI_ROW, #values * MULTI_ROW))
	end,
})

------------------------------------------------------------------ for the later widget files

Kit.Caret, Kit.ListEntries = Caret, ListEntries
