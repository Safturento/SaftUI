local st = SaftUI
local OM = st.OptionsModel

--[[
	The widgets SaftUI's options window draws its rows with. Each is a control
	only: the window draws the label and the row around it.

	  local widget = W.Create(parent, row.type)       -- from a pool, one per type
	  widget:Bind(root, row, onChanged)               -- reads the value, shows it
	  widget:SetPoint(...)                            -- widget.frame is the frame
	  widget:GetWidth()                               -- the control's fixed width
	  widget:SetDisabled(true)
	  widget:Release()                                -- back to the pool

	Bind reads the row's value with OM.Get. A change the user makes goes the
	way AceConfigDialog's does: OM.Validate (a failure calls
	onChanged(false, message) and sets nothing), then OM.Confirm (a text asks
	with W.Confirm first), then OM.Set. After that onChanged(ok, err) runs, ok
	false when the set errored. The window re-renders from it. While a slider
	is being dragged, onChanged gets a third argument, true; one more
	onChanged(true) comes when the mouse is let go, so the window doesn't
	rebuild the slider under the user's mouse.

	Types: toggle, range, select, multiselect, input, color, execute,
	keybinding, description. Widths: toggle 18, range 168 (a 116 track, a gap
	of 6 and a 46 value box), select, multiselect, input and keybinding 170,
	color 22. An execute button is as wide as its name needs (80 at least),
	and a description is as wide as the window sets it (400 until it does).
	A multiselect's and a description's height follow what they hold
	(widget.frame:GetHeight()); the others are 18, 22, 24 or 26 high.

	Left out: input's multiline (one line), select's radio style (a dropdown,
	as the spec says), description's image. A description's fontSize is small
	(the default), medium or large.
]]

local W = {}
st.OptionsWidgets = W

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format, tconcat, tinsert, tremove = string.format, table.concat, table.insert, table.remove

W.WIDTH = {
	toggle = 18, range = 168, select = 170, multiselect = 170, input = 170,
	color = 22, execute = 80, keybinding = 170, description = 400,
}
local TRACK_WIDTH, VALUE_WIDTH, GAP = 116, 46, 6
local FIELD_HEIGHT = 24
local LIST_ROW_HEIGHT, LIST_MAX_ROWS = 22, 12
local LIST_STRATA = 'FULLSCREEN_DIALOG'

------------------------------------------------------------------ look

-- The mockup's colors (the thick template's, and the field fill).
local FIELD, EDGE, ALT, BG = st.BOX_COLORS.field, st.BOX_COLORS.edge, st.BOX_COLORS.alt, st.BOX_COLORS.bg

local function Colors()
	return st.config.profile.colors
end

-- The window's font for fields and lists: the profile's normal face, at 15.
local fieldFont
local FIELD_FONT_SIZE = 15
function W.GetFont()
	if not fieldFont then
		fieldFont = _G.SaftUI_OptionsFieldFont or CreateFont('SaftUI_OptionsFieldFont')
		W.UpdateFonts()
	end
	return fieldFont
end

-- Applies the profile's face and outline to the font (a profile change).
function W.UpdateFonts()
	if not fieldFont then return end
	local config = st.config.profile.fonts.normal
	fieldFont:SetFont(st.LSM:Fetch('font', config.font_name), FIELD_FONT_SIZE, config.font_outline)
	fieldFont:SetTextColor(Colors().text.normal:GetRGB())
end

local function NewText(parent, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(W.GetFont())
	fs:SetJustifyH(justify or 'LEFT')
	return fs
end

-- A box: the field fill and a 1px edge border, with the dark line outside it.
local function Box(frame, fill)
	frame:SetBackdrop({
		bgFile = st.BLANK_TEX, edgeFile = st.BLANK_TEX, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(unpack(fill or FIELD))
	frame:SetBackdropBorderColor(unpack(EDGE))
	if not frame.outline then
		local outline = st:CreateFrame('Frame', nil, frame)
		outline:SetPoint('TOPLEFT', frame, 'TOPLEFT', -1, 1)
		outline:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 1, -1)
		outline:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
		outline:SetBackdrop({ edgeFile = st.BLANK_TEX, edgeSize = 1 })
		outline:SetBackdropBorderColor(unpack(ALT))
		frame.outline = outline
	end
	return frame
end

-- The border color (the hover and focus look is blue).
local function Edge(frame, blue)
	if blue then
		frame:SetBackdropBorderColor(Colors().button.blue:GetRGB())
	else
		frame:SetBackdropBorderColor(unpack(EDGE))
	end
end

-- A box that is blue-bordered under the mouse.
local function HoverEdge(frame, isDisabled)
	frame:SetScript('OnEnter', function(self) if not isDisabled() then Edge(self, true) end end)
	frame:SetScript('OnLeave', function(self) Edge(self, false) end)
end

------------------------------------------------------------------ numbers

-- Strips float drift (0.1 * 3 is 0.30000000000000004).
local function Tidy(value)
	return tonumber(format('%.10g', value))
end

-- value on min's grid of step (no grid for a step of 0).
local function Snap(value, minimum, step)
	if step and step > 0 then
		value = floor((value - minimum) / step + 0.5) * step + minimum
	end
	return Tidy(value)
end

-- A number as the value box shows it: 0.065, 12, 33.5.
local function Shown(value, percent)
	if percent then value = value * 100 end
	return tostring(tonumber(format('%.6g', value)))
end

------------------------------------------------------------------ the confirm dialog

local dialog

local function CloseConfirmFrames()
	if dialog then dialog.catcher:Hide() end
end

-- Esc and clicks outside are No. Not for a frame that already closed.
local function Answer(yes)
	if not (dialog and dialog.catcher:IsShown()) then return end
	local onYes, onNo = dialog.onYes, dialog.onNo
	dialog.onYes, dialog.onNo = nil, nil
	CloseConfirmFrames()
	if yes then
		if onYes then onYes() end
	elseif onNo then
		onNo()
	end
end

local function MakeDialogButton(parent, text, yes)
	local button = Box(st:CreateFrame('Button', nil, parent))
	button:SetSize(80, 24)
	button.text = NewText(button, 'CENTER')
	button.text:SetAllPoints()
	button.text:SetText(text)
	HoverEdge(button, function() return false end)
	button:SetScript('OnClick', function() Answer(yes) end)
	return button
end

local function BuildDialog()
	-- A full-screen catcher keeps clicks from reaching the window under the dialog.
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata('FULLSCREEN_DIALOG')
	catcher:SetFrameLevel(100)
	catcher:EnableMouse(true)
	catcher:Hide()

	local frame = Box(st:CreateFrame('Frame', nil, catcher), BG)
	frame:SetFrameLevel(110)
	frame:SetWidth(320)
	frame:EnableMouse(true)
	-- The thick template's second border.
	frame.outline:SetBackdropBorderColor(unpack(ALT))

	local text = NewText(frame, 'CENTER')
	text:SetWordWrap(true)
	text:SetWidth(290)
	text:SetPoint('TOP', frame, 'TOP', 0, -16)

	-- Text measured on one line decides the height, as a wrapped font string
	-- only knows its height once it has been laid out.
	local measure = NewText(frame, 'LEFT')
	measure:SetWordWrap(false)
	measure:Hide()

	local yes = MakeDialogButton(frame, 'Yes', true)
	yes:SetPoint('BOTTOMRIGHT', frame, 'BOTTOM', -6, 14)
	local no = MakeDialogButton(frame, 'No', false)
	no:SetPoint('BOTTOMLEFT', frame, 'BOTTOM', 6, 14)

	catcher:SetScript('OnMouseDown', function() Answer(false) end)
	catcher:SetScript('OnKeyDown', function(self, key)
		local consumed = key == 'ESCAPE' or key == 'ENTER'
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(not consumed) end
		if key == 'ESCAPE' then Answer(false) elseif key == 'ENTER' then Answer(true) end
	end)
	catcher:SetScript('OnShow', function(self) self:EnableKeyboard(true) end)
	catcher:SetScript('OnHide', function(self) self:EnableKeyboard(false) end)

	dialog = { catcher = catcher, frame = frame, text = text, measure = measure, yes = yes, no = no }
end

-- The frame the confirm dialog centers on (the options window sets it).
function W.SetDialogAnchor(frame)
	W.dialogAnchor = frame
end

-- Asks text with Yes and No buttons, centered over the window. onYes runs on
-- Yes; onNo (optional) on No, Esc or a click outside. Enter is Yes. A dialog
-- that is already up is answered No first.
function W.Confirm(text, onYes, onNo)
	if not dialog then BuildDialog() end
	if dialog.catcher:IsShown() then Answer(false) end
	dialog.onYes, dialog.onNo = onYes, onNo
	text = tostring(text)
	dialog.text:SetText(text)
	dialog.measure:SetText(text)
	local lines = max(1, ceil(dialog.measure:GetStringWidth() / 270))
	local lineHeight = floor(FIELD_FONT_SIZE * 1.3)
	dialog.text:SetHeight(lines * lineHeight)
	dialog.frame:SetHeight(16 + lines * lineHeight + 16 + 24 + 14)
	dialog.frame:ClearAllPoints()
	dialog.frame:SetPoint('CENTER', W.dialogAnchor or UIParent, 'CENTER', 0, 0)
	dialog.catcher:Show()
end

-- The open confirm dialog's text, or nil.
function W.ConfirmText()
	if dialog and dialog.catcher:IsShown() then return dialog.text:GetText() end
end

------------------------------------------------------------------ the select list

-- One list shared by every select: a column of up to 12 rows over a scrollable
-- list of entries, closed by a choice, a click outside or Esc.
local list

local function ListFill()
	local entries, offset = list.entries, list.offset
	for i, row in ipairs(list.rows) do
		local entry = entries[offset + i]
		if entry then
			row.entry = entry
			row.text:SetFontObject(W.GetFont())
			if list.fontMode then row.text:SetFont(entry.font, FIELD_FONT_SIZE, '') end
			row.text:SetText(entry.label)
			if entry.key == list.selected then
				row.text:SetTextColor(Colors().text.blue:GetRGB())
			else
				row.text:SetTextColor(Colors().text.normal:GetRGB())
			end
			row:Show()
		else
			row.entry = nil
			row:Hide()
		end
	end
	local total, shown = #entries, min(#entries, LIST_MAX_ROWS)
	if total > shown then
		local track = shown * LIST_ROW_HEIGHT
		list.bar:SetHeight(max(10, track * shown / total))
		list.bar:ClearAllPoints()
		list.bar:SetPoint('TOPRIGHT', list.frame, 'TOPRIGHT', -2, -1 - (track - list.bar:GetHeight()) * offset / (total - shown))
		list.bar:Show()
	else
		list.bar:Hide()
	end
end

function W.CloseList()
	if list then
		list.owner, list.onPick, list.entries = nil, nil, nil
		list.catcher:Hide()
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

	list = { catcher = catcher, frame = frame, bar = bar, rows = {}, offset = 0 }

	for i = 1, LIST_MAX_ROWS do
		local row = CreateFrame('Button', nil, frame)
		row:SetHeight(LIST_ROW_HEIGHT)
		row:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, -1 - (i - 1) * LIST_ROW_HEIGHT)
		row:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, -1 - (i - 1) * LIST_ROW_HEIGHT)
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
			local entry, onPick = self.entry, list.onPick
			W.CloseList()
			if entry and onPick then onPick(entry.key) end
		end)
		list.rows[i] = row
	end

	frame:SetScript('OnMouseWheel', function(_, delta)
		local over = #list.entries - LIST_MAX_ROWS
		if over <= 0 then return end
		list.offset = max(0, min(over, list.offset - delta * 3))
		ListFill()
	end)
	catcher:SetScript('OnMouseDown', W.CloseList)
	catcher:SetScript('OnKeyDown', function(self, key)
		-- Esc closes the list; every other key goes on to the game.
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(key ~= 'ESCAPE') end
		if key == 'ESCAPE' then W.CloseList() end
	end)
	catcher:SetScript('OnShow', function(self) self:EnableKeyboard(true) end)
	catcher:SetScript('OnHide', function(self) self:EnableKeyboard(false) end)
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

	local rows = min(#entries, LIST_MAX_ROWS)
	local height = rows * LIST_ROW_HEIGHT + 2
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
end

-- The list's frames { catcher, frame, rows, ... } (nil until first opened), and the
-- confirm dialog's { catcher, frame, text, yes, no } (nil until first asked).
-- For tests.
function W.GetListFrames() return list end
function W.GetDialogFrames() return dialog end

-- The frame the open list belongs to, or nil.
function W.ListOwner()
	return list and list.catcher:IsShown() and list.owner or nil
end

------------------------------------------------------------------ the base widget

local Base = {}
Base.__index = Base

local pools = {} -- rowType -> { widget }
local builders = {} -- rowType -> function(widget): makes widget.frame

function Base:GetWidth() return self.width end
function Base:GetHeight() return self.frame:GetHeight() end
function Base:SetPoint(...) self.frame:SetPoint(...) end

function Base:IsDisabled() return self.disabled end

function Base:SetDisabled(disabled)
	self.disabled = disabled and true or false
	self.frame:SetAlpha(self.disabled and 0.4 or 1)
	if self.OnDisabled then self:OnDisabled(self.disabled) end
end

-- Reads the row's value and shows it. Each type's Refresh does the showing.
function Base:Bind(root, row, onChanged)
	self.root, self.row, self.onChanged = root, row, onChanged
	self:SetDisabled(row.disabled)
	self:Refresh()
	return self
end

function Base:Value(...)
	return OM.Get(self.root, self.row, ...)
end

-- A change from the user: validate, then confirm, then set, then tell the
-- window. A failed validation puts the shown value back.
function Base:Commit(...)
	local root, row = self.root, self.row
	if not row or self.disabled then return end
	local args, n = { ... }, select('#', ...)
	local function Apply()
		if self.root ~= root or self.row ~= row then return end -- released meanwhile
		local ok = OM.Set(root, row, unpack(args, 1, n))
		self:Refresh()
		if self.onChanged then self.onChanged(ok ~= false, nil, self.dragging) end
	end
	local valid, err = OM.Validate(root, row, ...)
	if not valid then
		self:Refresh()
		if self.onChanged then self.onChanged(false, err) end
		return
	end
	local text = OM.Confirm(root, row, ...)
	if text then
		W.Confirm(text, Apply, function()
			if self.root == root and self.row == row then self:Refresh() end
		end)
	else
		Apply()
	end
end

function Base:Release()
	if self.released then return end
	self.released = true
	if self.OnRelease then self:OnRelease() end
	self.root, self.row, self.onChanged = nil, nil, nil
	self.dragging = nil
	self.frame:Hide()
	self.frame:ClearAllPoints()
	self.frame:SetParent(nil)
	self.frame:SetAlpha(1)
	self.disabled = false
	tinsert(pools[self.type], self)
end

-- The widget for rowType, from the pool when one was released.
function W.Create(parent, rowType)
	local build = builders[rowType]
	if not build then error(format('SaftUI options: no widget for type %q', tostring(rowType)), 2) end
	pools[rowType] = pools[rowType] or {}
	local widget = tremove(pools[rowType])
	if not widget then
		widget = setmetatable({ type = rowType, width = W.WIDTH[rowType] }, Base)
		build(widget)
	end
	widget.released = false
	widget.frame:SetParent(parent)
	widget.frame:SetFrameLevel(parent:GetFrameLevel() + 1)
	widget.frame:Show()
	return widget
end

-- How many widgets of a type sit in the pool.
function W.Pooled(rowType)
	return pools[rowType] and #pools[rowType] or 0
end

------------------------------------------------------------------ a check box (toggle, multiselect)

-- A box of size with a blue square inside when checked: box.mark.
local function CheckBox(parent, size)
	local box = Box(st:CreateFrame('CheckButton', nil, parent))
	box:SetSize(size, size)
	box.mark = box:CreateTexture(nil, 'OVERLAY')
	box.mark:SetPoint('TOPLEFT', box, 'TOPLEFT', 3, -3)
	box.mark:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', -3, 3)
	box.mark:SetColorTexture(Colors().button.blue:GetRGB())
	box.mark:Hide()
	return box
end

local function SetCheck(box, checked)
	checked = checked and true or false
	box:SetChecked(checked)
	box.mark:SetShown(checked)
end

------------------------------------------------------------------ toggle

builders.toggle = function(w)
	local box = CheckBox(UIParent, 18)
	w.frame = box
	HoverEdge(box, function() return w.disabled end)
	box:SetScript('OnClick', function()
		if w.disabled then return end
		w:Commit(not w.value)
	end)
end

-- Each type's methods are copied onto its widgets as they're built. A
-- Refresh that comes after a release (a hidden edit box losing focus) does
-- nothing.
local function define(rowType, methods)
	local build = builders[rowType]
	builders[rowType] = function(w)
		for name, fn in pairs(methods) do w[name] = fn end
		if methods.Refresh then
			local refresh = methods.Refresh
			w.Refresh = function(self, ...)
				if self.row then return refresh(self, ...) end
			end
		end
		build(w)
	end
end

define('toggle', {
	Refresh = function(self)
		self.value = self:Value() and true or false
		SetCheck(self.frame, self.value)
	end,
})

------------------------------------------------------------------ range

builders.range = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(TRACK_WIDTH + GAP + VALUE_WIDTH, FIELD_HEIGHT)
	w.frame = frame

	local slider = CreateFrame('Slider', nil, frame)
	slider:SetOrientation('HORIZONTAL')
	slider:SetSize(TRACK_WIDTH, FIELD_HEIGHT)
	slider:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	slider:EnableMouse(true)
	slider:SetObeyStepOnDrag(true)
	w.slider = slider

	local track = Box(st:CreateFrame('Frame', nil, slider))
	track:SetPoint('LEFT', slider, 'LEFT', 0, 0)
	track:SetSize(TRACK_WIDTH, 6)
	track:SetFrameLevel(max(0, slider:GetFrameLevel() - 1)) -- under the knob
	w.track = track
	local fill = track:CreateTexture(nil, 'ARTWORK')
	fill:SetColorTexture(Colors().button.blue:GetRGB())
	fill:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	fill:SetPoint('BOTTOMLEFT', track, 'BOTTOMLEFT', 1, 1)
	fill:SetWidth(1)
	w.fill = fill

	slider:SetThumbTexture(st.BLANK_TEX)
	local knob = slider:GetThumbTexture()
	knob:SetSize(6, 14)
	knob:SetVertexColor(Colors().text.normal:GetRGB())

	local edit = Box(st:CreateFrame('EditBox', nil, frame))
	edit:SetSize(VALUE_WIDTH, FIELD_HEIGHT)
	edit:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('CENTER')
	edit:SetTextInsets(2, 2, 0, 0)
	edit:SetAutoFocus(false)
	w.edit = edit

	slider:SetScript('OnValueChanged', function(_, value)
		if w.updating or not w.row or w.disabled then return end
		w:Dragged(value)
	end)
	slider:SetScript('OnMouseDown', function() w.dragging = true end)
	slider:SetScript('OnMouseUp', function()
		local changed = w.dirty
		w.dragging, w.dirty = nil, nil
		if changed and w.onChanged then w.onChanged(true) end
	end)

	edit:SetScript('OnEnterPressed', function(self)
		if not w.row then return end
		local text = self:GetText():gsub('%%', ''):gsub('^%s+', ''):gsub('%s+$', '')
		local number = tonumber(text)
		if number then w:Typed(number) else w:Refresh() end
		self:ClearFocus()
	end)
	edit:SetScript('OnEscapePressed', function(self)
		w:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self)
		Edge(self, true)
		self:HighlightText(0, -1)
	end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		w:Refresh()
	end)
end

define('range', {
	-- The slider's ends (softMin and softMax, else min and max, as
	-- AceConfigDialog gives them), and the hard limits typed numbers get cut to.
	Limits = function(self)
		local root, row = self.root, self.row
		local min_, max_ = OM.Member(root, row, 'min'), OM.Member(root, row, 'max')
		local softMin, softMax = OM.Member(root, row, 'softMin'), OM.Member(root, row, 'softMax')
		local step, bigStep = OM.Member(root, row, 'step'), OM.Member(root, row, 'bigStep')
		self.softMin, self.softMax = softMin or min_ or 0, softMax or max_ or 100
		self.hardMin = min_ or (not softMin and 0 or nil)
		self.hardMax = max_ or (not softMax and 100 or nil)
		self.step, self.dragStep = step or 0, bigStep or step or 0
		self.percent = OM.Member(root, row, 'isPercent') and true or false
	end,

	-- The hard limits, as AceConfigDialog's ActivateSlider cuts a value.
	Cut = function(self, value)
		if self.hardMin then value = max(value, self.hardMin) end
		if self.hardMax then value = min(value, self.hardMax) end
		return value
	end,

	-- The slider moved by the user: snapped to bigStep (or step) while
	-- dragging.
	Dragged = function(self, value)
		value = self:Cut(Snap(value, self.softMin, self.dragStep))
		if value == self.value then return end
		if self.dragging then self.dirty = true end
		self:Commit(value)
	end,

	-- A number typed in the box: cut to the slider's ends first, then snapped
	-- to step and cut to min and max.
	Typed = function(self, number)
		if self.percent then number = number / 100 end
		number = max(self.softMin, min(self.softMax, number))
		number = self:Cut(Snap(number, self.hardMin or self.softMin, self.step))
		self:Commit(number)
	end,

	Refresh = function(self)
		self:Limits()
		local value = self:Value()
		self.value = type(value) == 'number' and value or nil
		local shown = self.value or self.softMin
		self.updating = true
		self.slider:SetMinMaxValues(self.softMin, self.softMax)
		if self.dragStep > 0 then self.slider:SetValueStep(self.dragStep) end
		self.slider:SetValue(max(self.softMin, min(self.softMax, shown)))
		self.updating = false
		local span = self.softMax - self.softMin
		local fraction = span > 0 and max(0, min(1, (shown - self.softMin) / span)) or 0
		self.fill:SetWidth(max(1, (TRACK_WIDTH - 2) * fraction))
		self.edit:SetText(self.value and (Shown(self.value, self.percent) .. (self.percent and '%' or '')) or '')
	end,

	OnDisabled = function(self, disabled)
		self.slider:EnableMouse(not disabled)
		self.edit:EnableMouse(not disabled)
		if disabled then self.edit:ClearFocus() end
	end,
})

------------------------------------------------------------------ select

-- A box that shows its choice and opens the list. The caret is four rows of pixels.
local function Caret(parent)
	local carets = {}
	for i, width in ipairs({ 7, 5, 3, 1 }) do
		local t = parent:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Colors().text.grey:GetRGB())
		t:SetSize(width, 1)
		t:SetPoint('TOP', parent, 'RIGHT', -12, 3 - i)
		carets[i] = t
	end
end

builders.select = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.select, FIELD_HEIGHT)
	w.frame = button
	w.text = NewText(button, 'LEFT')
	w.text:SetPoint('LEFT', button, 'LEFT', 8, 0)
	w.text:SetPoint('RIGHT', button, 'RIGHT', -22, 0)
	Caret(button)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnClick', function() w:Open() end)
	button:SetScript('OnHide', function()
		if W.ListOwner() == button then W.CloseList() end
	end)
end

-- The entries for a row's values: { {key, label, font} }. LibSharedMedia's
-- font lists give name -> file, so a font list is labeled by the name and
-- drawn in the file's face.
local function ListEntries(root, row)
	local fontMode = row.option.dialogControl == 'LSM30_Font'
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

define('select', {
	-- Only the chosen key's label is resolved here; the list is built when it opens.
	Refresh = function(self)
		self.value = self:Value()
		local values = OM.Member(self.root, self.row, 'values')
		local fontMode = self.row.option.dialogControl == 'LSM30_Font'
		local label, font = '', nil
		if type(values) == 'table' and self.value ~= nil and values[self.value] ~= nil then
			if fontMode then
				label, font = tostring(self.value), values[self.value]
			else
				label = tostring(values[self.value])
			end
		end
		self.text:SetFontObject(W.GetFont())
		if fontMode and font then self.text:SetFont(font, FIELD_FONT_SIZE, '') end
		self.text:SetText(label)
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
	end,

	OnRelease = function(self)
		if W.ListOwner() == self.frame then W.CloseList() end
	end,
})

------------------------------------------------------------------ multiselect

local MULTI_ROW = 22

builders.multiselect = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(W.WIDTH.multiselect, MULTI_ROW)
	w.frame = frame
	w.rows = {}
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
	row:SetScript('OnEnter', function(self) Edge(self.box, true) end)
	row:SetScript('OnLeave', function(self) Edge(self.box, false) end)
	row:SetScript('OnClick', function(self)
		if w.disabled or self.key == nil then return end
		w:Commit(self.key, not self.checked)
	end)
	w.rows[i] = row
	return row
end

define('multiselect', {
	Refresh = function(self)
		local values = OM.Values(self.root, self.row)
		for i, value in ipairs(values) do
			local row = MultiRow(self, i)
			row.key = value.key
			row.checked = self:Value(value.key) and true or false
			SetCheck(row.box, row.checked)
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

------------------------------------------------------------------ input

builders.input = function(w)
	local edit = Box(st:CreateFrame('EditBox', nil, UIParent))
	edit:SetSize(W.WIDTH.input, FIELD_HEIGHT)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('LEFT')
	edit:SetTextInsets(8, 8, 0, 0)
	edit:SetAutoFocus(false)
	w.frame = edit
	HoverEdge(edit, function() return w.disabled or edit:HasFocus() end)
	edit:SetScript('OnEnterPressed', function(self)
		if not w.row then return end
		local text = self:GetText()
		self:ClearFocus()
		w:Commit(text)
	end)
	edit:SetScript('OnEscapePressed', function(self)
		w:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self) Edge(self, true) end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		w:Refresh()
	end)
end

define('input', {
	Refresh = function(self)
		local value = self:Value()
		self.value = value
		self.frame:SetText(value == nil and '' or tostring(value))
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		if disabled then self.frame:ClearFocus() end
	end,
})

------------------------------------------------------------------ color

-- ColorPickerFrame is Blizzard's: used only through its public API, and
-- nothing is written onto it. The forever branch's picker is the mainline
-- one, where opacity is the alpha (1 is solid).
local function OpenPicker(info)
	-- Forever and retail both have SetupColorPickerAndShow. Without it the swatch
	-- does nothing: the older way means writing fields onto Blizzard's frame.
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow(info)
	end
end

builders.color = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.color, W.WIDTH.color)
	w.frame = button
	-- The black 1px line inside the border, then the color.
	local inner = button:CreateTexture(nil, 'ARTWORK')
	inner:SetColorTexture(0, 0, 0, 1)
	inner:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1)
	inner:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -1, 1)
	w.swatch = button:CreateTexture(nil, 'OVERLAY')
	w.swatch:SetPoint('TOPLEFT', button, 'TOPLEFT', 2, -2)
	w.swatch:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 2)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnClick', function() w:Pick() end)
end

define('color', {
	Refresh = function(self)
		local r, g, b, a = self:Value()
		self.r, self.g, self.b, self.a = r or 0, g or 0, b or 0, a or 1
		self.hasAlpha = OM.Member(self.root, self.row, 'hasAlpha') and true or false
		self.swatch:SetColorTexture(self.r, self.g, self.b, self.hasAlpha and self.a or 1)
	end,

	-- Opens the picker on the current color. Each change it makes is set;
	-- Cancel puts the color it opened with back. The picker calls swatchFunc
	-- once as it opens, with the same color, which isn't a change.
	Pick = function(self)
		if self.disabled or not self.row then return end
		local root, row = self.root, self.row
		local r, g, b, a = self.r, self.g, self.b, self.a
		local hasAlpha = self.hasAlpha
		local function Current()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			local na = hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
			return nr, ng, nb, na
		end
		local opening = true
		local function Changed(nr, ng, nb, na)
			-- The picker calls swatchFunc while it opens (with whatever alpha it
			-- held before), before it is the user's.
			if opening or self.root ~= root or self.row ~= row then return end
			if nr == self.r and ng == self.g and nb == self.b and (not hasAlpha or na == self.a) then return end
			self:Commit(nr, ng, nb, na)
		end
		OpenPicker({
			r = r, g = g, b = b,
			opacity = hasAlpha and a or nil,
			hasOpacity = hasAlpha,
			swatchFunc = function() Changed(Current()) end,
			opacityFunc = function() Changed(Current()) end,
			cancelFunc = function(previous)
				previous = previous or { r = r, g = g, b = b, a = a }
				Changed(previous.r, previous.g, previous.b, hasAlpha and previous.a or 1)
			end,
		})
		opening = false
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
	end,
})

------------------------------------------------------------------ execute

builders.execute = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent), BG)
	button:SetHeight(26)
	w.frame = button
	w.text = NewText(button, 'CENTER')
	w.text:SetPoint('CENTER', button, 'CENTER', 0, 0)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnMouseDown', function() w.text:SetPoint('CENTER', button, 'CENTER', 0, -1) end)
	button:SetScript('OnMouseUp', function() w.text:SetPoint('CENTER', button, 'CENTER', 0, 0) end)
	button:SetScript('OnClick', function() w:Run() end)
end

define('execute', {
	Refresh = function(self)
		self.text:SetText(self.row.name or '')
		self.width = max(W.WIDTH.execute, ceil(self.text:GetStringWidth()) + 28)
		self.frame:SetWidth(self.width)
	end,

	-- Confirm, then call the option's func.
	Run = function(self)
		if self.disabled or not self.row then return end
		local root, row = self.root, self.row
		local function Go()
			if self.root ~= root or self.row ~= row then return end
			local ok = OM.Set(root, row)
			if self.onChanged then self.onChanged(ok ~= false) end
		end
		local text = OM.Confirm(root, row)
		if text then W.Confirm(text, Go) else Go() end
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
	end,
})

------------------------------------------------------------------ keybinding

local IGNORED_KEYS = {
	BUTTON1 = true, BUTTON2 = true, UNKNOWN = true,
	LSHIFT = true, LCTRL = true, LALT = true, RSHIFT = true, RCTRL = true, RALT = true,
}
local MOUSE_BUTTONS = { MiddleButton = 'BUTTON3', Button4 = 'BUTTON4', Button5 = 'BUTTON5' }

builders.keybinding = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.keybinding, FIELD_HEIGHT)
	w.frame = button
	w.text = NewText(button, 'CENTER')
	w.text:SetAllPoints()
	HoverEdge(button, function() return w.disabled or w.waiting end)

	-- A press while waiting is the new key. Esc clears the binding, as it does
	-- in AceGUI's keybinding box.
	local function Press(key)
		if not w.waiting then return end
		if key ~= 'ESCAPE' then
			if IGNORED_KEYS[key] then return end
			if IsShiftKeyDown() then key = 'SHIFT-' .. key end
			if IsControlKeyDown() then key = 'CTRL-' .. key end
			if IsAltKeyDown() then key = 'ALT-' .. key end
		else
			key = ''
		end
		w:StopWaiting()
		w:Commit(key)
	end
	button:SetScript('OnKeyDown', function(self, key)
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(not w.waiting) end
		Press(key)
	end)
	button:SetScript('OnMouseWheel', function(_, delta)
		Press(delta >= 0 and 'MOUSEWHEELUP' or 'MOUSEWHEELDOWN')
	end)
	button:SetScript('OnMouseDown', function(_, mouseButton)
		if mouseButton == 'LeftButton' or mouseButton == 'RightButton' then return end
		Press(MOUSE_BUTTONS[mouseButton] or mouseButton)
	end)
	button:SetScript('OnClick', function(_, mouseButton)
		if w.disabled then return end
		if mouseButton ~= nil and mouseButton ~= 'LeftButton' then return end
		if w.waiting then w:StopWaiting() else w:StartWaiting() end
	end)
	button:SetScript('OnHide', function() w:StopWaiting() end)
end

define('keybinding', {
	Refresh = function(self)
		local key = self:Value()
		self.value = key
		self.text:SetFontObject(W.GetFont())
		if self.waiting then
			self.text:SetText('Press a key')
			self.text:SetTextColor(Colors().text.blue:GetRGB())
		elseif key and key ~= '' then
			self.text:SetText(key)
			self.text:SetTextColor(Colors().text.normal:GetRGB())
		else
			self.text:SetText('Not bound')
			self.text:SetTextColor(Colors().text.grey:GetRGB())
		end
	end,

	StartWaiting = function(self)
		self.waiting = true
		self.frame:EnableKeyboard(true)
		self.frame:EnableMouseWheel(true)
		Edge(self.frame, true)
		self:Refresh()
	end,

	StopWaiting = function(self)
		if not self.waiting then return end
		self.waiting = nil
		self.frame:EnableKeyboard(false)
		self.frame:EnableMouseWheel(false)
		Edge(self.frame, false)
		if self.row then self:Refresh() end
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		if disabled then self:StopWaiting() end
	end,

	OnRelease = function(self)
		self:StopWaiting()
	end,
})

------------------------------------------------------------------ description

builders.description = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(W.WIDTH.description, 18)
	w.frame = frame
	w.text = NewText(frame, 'LEFT')
	w.text:SetWordWrap(true)
	w.text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
	w.text:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
	w.measure = NewText(frame, 'LEFT')
	w.measure:SetWordWrap(false)
	w.measure:Hide()
end

local DESCRIPTION_SIZES = { small = FIELD_FONT_SIZE, medium = FIELD_FONT_SIZE + 2, large = FIELD_FONT_SIZE + 5 }

define('description', {
	GetWidth = function(self) return self.frame:GetWidth() end,

	-- The window sizes a description to its row. The height follows the text.
	SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self:Fit()
	end,

	Fit = function(self)
		local lineHeight = floor((self.size or FIELD_FONT_SIZE) * 1.3)
		local lines = max(1, ceil(self.measure:GetStringWidth() / max(1, self.frame:GetWidth() - 10)))
		self.text:SetHeight(lines * lineHeight)
		self.frame:SetHeight(lines * lineHeight)
	end,

	Refresh = function(self)
		local text = self.row.name
		if type(text) ~= 'string' then text = '' end
		-- fontSize: small (the default), medium or large.
		local size = DESCRIPTION_SIZES[OM.Member(self.root, self.row, 'fontSize')] or FIELD_FONT_SIZE
		self.size = size
		for _, fs in ipairs({ self.text, self.measure }) do
			fs:SetFontObject(W.GetFont())
			if size ~= FIELD_FONT_SIZE then
				local path, _, flags = W.GetFont():GetFont()
				fs:SetFont(path, size, flags)
			end
		end
		self.text:SetText(text)
		self.measure:SetText(text)
		self.text:SetTextColor(Colors().text.normal:GetRGB())
		self:Fit()
	end,
})
