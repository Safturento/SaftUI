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
	is being dragged, onChanged gets a third argument, true, and a fourth,
	the widget, so the window can refresh the other rows and leave the
	slider be; one more onChanged(true) comes when the mouse is let go, so
	the window doesn't rebuild the slider under the user's mouse.

	Types: toggle, range, select, multiselect, input, color, execute,
	keybinding, description, position. Widths: toggle 18, range 168 (a 116 track, a gap
	of 6 and a 46 value box), select, multiselect, input and keybinding 170,
	color 22. An execute button is as wide as its name needs (80 at least),
	and a description is as wide as the window sets it (400 until it does). A
	position block is as wide as its parts (200, 332 with a name target, 352
	with a select target) and 65 high; its get/set/validate take the part first (point,
	rel_point, x_off, y_off, frame, relative_to), so a change is
	Commit(part, value). The window sets widget.onTip, which the block calls
	as the mouse enters and leaves any of its parts. A multiselect's and a description's height follow what they hold
	(widget.frame:GetHeight()); the others are 18, 22, 24 or 26 high.

	Left out: input's multiline (one line), select's radio style (a dropdown,
	as the spec says). A description's fontSize is small (the default), medium
	or large. Its image is read as AceConfigDialog reads it: image a texture
	path or fileID, or a function giving that with a width and height;
	imageWidth and imageHeight otherwise (32 each by default); imageCoords 4
	or 8 numbers, or a function giving them, else the whole texture. The image
	sits at the description's left with the text to its right, and the height
	covers both. It has a border in SaftUI's theme, as an icon SaftUI skins
	does. Refresh reads them all again (the window refreshes the other
	rows while a slider is dragged, so a preview can follow it).

	Other files add types of their own with W.Define (custom types, at the
	end), each with its own pool. W.CUSTOM marks them, and the body draws a
	bare one's row with no label, across the line. W.OpenCheckList opens
	the select list's frames as a list of check boxes.
]]

local W = {}
st.OptionsWidgets = W

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format, tconcat, tinsert, tremove = string.format, table.concat, table.insert, table.remove

W.WIDTH = {
	toggle = 18, range = 168, select = 170, multiselect = 170, input = 170,
	color = 22, execute = 80, keybinding = 170, description = 400,
	position = 0, -- the block's width follows its parts (widget:GetWidth())
}
local TRACK_WIDTH, VALUE_WIDTH, GAP = 116, 46, 6
local FIELD_HEIGHT = 24
local LIST_ROW_HEIGHT, LIST_MAX_ROWS = 22, 12
-- Above the options window (FULLSCREEN_DIALOG, like edit mode's outlines), so
-- the list and the confirm dialog show over it and catch the clicks around them.
local LIST_STRATA = 'TOOLTIP'

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

-- Gives fs the field font, or path at size with flags (each defaulting to the
-- field font's). Always set outright: in game SetFontObject doesn't undo an
-- earlier SetFont, so a pooled font string would keep a font list's face or a
-- large description's size. A profile change re-renders, which sets it again.
local function SetFieldFont(fs, path, size, flags)
	local font = W.GetFont()
	local fieldPath, fieldSize, fieldFlags = font:GetFont()
	fs:SetFontObject(font)
	fs:SetFont(path or fieldPath, size or fieldSize, flags or fieldFlags)
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

-- For the options window's own boxes and buttons (the search box, Reload UI).
W.Box, W.Edge, W.HoverEdge = Box, Edge, HoverEdge

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

-- Lines a text takes in a box avail wide: each line of the text (split on \n)
-- measured on its own, an empty one counting as a line. measure is a font
-- string that doesn't wrap and isn't shown (text decides a height, as a
-- wrapped font string only knows its own once it has been laid out).
local function CountLines(measure, text, avail)
	local lines, from = 0, 1
	avail = max(1, avail)
	while from do
		local newline = text:find('\n', from, true)
		measure:SetText(text:sub(from, (newline or #text + 1) - 1))
		lines = lines + max(1, ceil(measure:GetStringWidth() / avail))
		from = newline and newline + 1
	end
	return lines
end

local dialog

local function CloseConfirmFrames()
	if dialog then
		dialog.box:ClearFocus()
		dialog.box:Hide()
		dialog.prompt = nil
		dialog.catcher:Hide()
	end
end

-- Esc and clicks outside are No. Not for a frame that already closed. A
-- prompt's Yes hands its box's text on.
local function Answer(yes)
	if not (dialog and dialog.catcher:IsShown()) then return end
	local onYes, onNo = dialog.onYes, dialog.onNo
	local typed = dialog.prompt and dialog.box:GetText() or nil
	dialog.onYes, dialog.onNo = nil, nil
	CloseConfirmFrames()
	if yes then
		if onYes then onYes(typed) end
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
	catcher:SetFrameStrata(LIST_STRATA)
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

	-- A prompt's edit box, below the text (OpenDialog places it).
	local box = Box(st:CreateFrame('EditBox', nil, frame))
	box:SetSize(290, FIELD_HEIGHT)
	box:SetFontObject(W.GetFont())
	box:SetJustifyH('LEFT')
	box:SetTextInsets(8, 8, 0, 0)
	box:SetAutoFocus(false)
	box:SetFrameLevel(frame:GetFrameLevel() + 1)
	box:Hide()
	box:SetScript('OnEnterPressed', function() Answer(true) end)
	box:SetScript('OnEscapePressed', function() Answer(false) end)
	box:SetScript('OnEditFocusGained', function(self) Edge(self, true) end)
	box:SetScript('OnEditFocusLost', function(self) Edge(self, false) end)

	-- Text measured on one line decides the height (CountLines).
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

	dialog = { catcher = catcher, frame = frame, text = text, measure = measure, yes = yes, no = no, box = box }
end

-- The frame the confirm dialog centers on (the options window sets it).
function W.SetDialogAnchor(frame)
	W.dialogAnchor = frame
end

-- One modal at a time, for Confirm and Prompt: the dialog is built once, and
-- opening either answers an open one No first. Sets the text, the buttons and
-- the height, and shows the dialog (a prompt's box is placed and shown here).
local function OpenDialog(text, onYes, onNo, prompt, yesLabel, noLabel)
	if not dialog then BuildDialog() end
	if dialog.catcher:IsShown() then Answer(false) end
	dialog.onYes, dialog.onNo = onYes, onNo
	dialog.prompt = prompt and true or nil
	text = tostring(text)
	dialog.text:SetText(text)
	local lines = CountLines(dialog.measure, text, 270)
	local lineHeight = floor(FIELD_FONT_SIZE * 1.3)
	dialog.text:SetHeight(lines * lineHeight)
	local height = 16 + lines * lineHeight + 16 + 24 + 14
	if prompt then
		height = height + FIELD_HEIGHT + 10
		dialog.box:ClearAllPoints()
		dialog.box:SetPoint('TOP', dialog.frame, 'TOP', 0, -(16 + lines * lineHeight + 10))
		dialog.box:Show()
	else
		dialog.box:Hide()
	end
	dialog.frame:SetHeight(height)
	dialog.yes.text:SetText(yesLabel)
	dialog.yes:ClearAllPoints()
	if noLabel then
		dialog.yes:SetPoint('BOTTOMRIGHT', dialog.frame, 'BOTTOM', -6, 14)
		dialog.no.text:SetText(noLabel)
		dialog.no:Show()
	else
		dialog.yes:SetPoint('BOTTOM', dialog.frame, 'BOTTOM', 0, 14)
		dialog.no:Hide()
	end
	dialog.frame:ClearAllPoints()
	dialog.frame:SetPoint('CENTER', W.dialogAnchor or UIParent, 'CENTER', 0, 0)
	dialog.catcher:Show()
end

-- Asks text with Yes and No buttons, centered over the window. onYes runs on
-- Yes; onNo (optional) on No, Esc or a click outside. Enter is Yes. A dialog
-- that is already up is answered No first.
function W.Confirm(text, onYes, onNo)
	OpenDialog(text, onYes, onNo, false, 'Yes', 'No')
end

-- Asks text with a one-line edit box under it, filled with initial (or empty),
-- focused and all selected. Enter or the accept button calls onAccept(text)
-- and closes; Esc, the cancel button and a click outside call opts.onCancel
-- (optional). opts.accept and opts.cancel label the buttons (Yes and No);
-- opts.cancel == false leaves only the accept button; opts.maxLetters caps
-- the box (0, the default, is no cap). The same dialog as Confirm.
function W.Prompt(text, initial, onAccept, opts)
	opts = opts or {}
	local cancel = opts.cancel
	if cancel == nil then cancel = 'No' end
	OpenDialog(text, onAccept, opts.onCancel, true, opts.accept or 'Yes', cancel or nil)
	dialog.box:SetMaxLetters(opts.maxLetters or 0)
	dialog.box:SetText(initial or '')
	dialog.box:SetFocus()
	dialog.box:HighlightText()
end

-- Answers an open confirm dialog No (the options window closing).
function W.CancelConfirm()
	Answer(false)
end

-- The open confirm or prompt dialog's text, or nil.
function W.ConfirmText()
	if dialog and dialog.catcher:IsShown() then return dialog.text:GetText() end
end

-- The open prompt's edit box, or nil (a confirm has none).
function W.PromptBox()
	if dialog and dialog.catcher:IsShown() and dialog.prompt then return dialog.box end
end

------------------------------------------------------------------ the select list

-- One list shared by every select: a column of up to 12 rows over a scrollable
-- list of entries, closed by a choice, a click outside or Esc.
local list

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
		list.isChecked, list.onToggle = nil, nil
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
-- window. A failed validation puts the shown value back (an input keeps its text).
function Base:Commit(...)
	local root, row = self.root, self.row
	if not row or self.disabled then return end
	local args, n = { ... }, select('#', ...)
	local function Apply()
		if self.root ~= root or self.row ~= row then return end -- released meanwhile
		local ok = OM.Set(root, row, unpack(args, 1, n))
		self:Refresh()
		if self.onChanged then self.onChanged(ok ~= false, nil, self.dragging, self) end
	end
	local valid, err = OM.Validate(root, row, ...)
	if not valid then
		if self.type == 'input' then
			-- AceConfigDialog keeps what was typed beside the error. The box may
			-- have been reset when Enter dropped its focus, so put the text back.
			self.frame:SetText(tostring((...)))
		else
			self:Refresh()
		end
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
	tinsert(self.pool, self)
end

-- The widget for rowType, from the pool when one was released.
function W.Create(parent, rowType)
	local build = builders[rowType]
	if not build then error(format('SaftUI options: no widget for type %q', tostring(rowType)), 2) end
	pools[rowType] = pools[rowType] or {}
	local widget = tremove(pools[rowType])
	if not widget then
		-- Its pool is the one it was built for: a custom type defined again
		-- starts a new one (W.Define).
		widget = setmetatable({ type = rowType, width = W.WIDTH[rowType], pool = pools[rowType] }, Base)
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

	-- The track is the slider's own textures, under the knob by draw layer. A
	-- child frame put under it by frame level drew over it in game once the
	-- widget was reparented (that moves children back above their parent).
	-- A box's look: the dark line outside, the edge, the field inside it.
	local outline = slider:CreateTexture(nil, 'BACKGROUND')
	outline:SetColorTexture(unpack(ALT))
	outline:SetPoint('LEFT', slider, 'LEFT', -1, 0)
	outline:SetSize(TRACK_WIDTH + 2, 8)
	local track = slider:CreateTexture(nil, 'BORDER', nil, 0)
	track:SetColorTexture(unpack(EDGE))
	track:SetPoint('LEFT', slider, 'LEFT', 0, 0)
	track:SetSize(TRACK_WIDTH, 6)
	w.track = track
	local inside = slider:CreateTexture(nil, 'BORDER', nil, 1)
	inside:SetColorTexture(unpack(FIELD))
	inside:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	inside:SetPoint('BOTTOMRIGHT', track, 'BOTTOMRIGHT', -1, 1)
	local fill = slider:CreateTexture(nil, 'ARTWORK')
	fill:SetColorTexture(Colors().button.blue:GetRGB())
	fill:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	fill:SetPoint('BOTTOMLEFT', track, 'BOTTOMLEFT', 1, 1)
	fill:SetWidth(1)
	w.fill = fill

	slider:SetThumbTexture(st.BLANK_TEX)
	local knob = slider:GetThumbTexture()
	knob:SetDrawLayer('OVERLAY')
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
		-- A click on the track moves the slider before OnMouseDown runs, so a
		-- held button already means a drag: the window mustn't re-render (and
		-- take this slider away) until it's let go.
		if IsMouseButtonDown('LeftButton') then w.dragging = true end
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
		-- Always set (AceGUI's SetSliderValues does): a pooled slider keeps its last row's step.
		self.slider:SetValueStep(self.dragStep)
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

-- A box that shows its choice and opens the list. The caret is four rows of
-- pixels, 7, 5, 3 and 1 wide, each placed by its left edge on a whole pixel
-- around one centre: placed by their centre, the odd widths would start half a
-- pixel off and blur.
local function Caret(parent)
	local carets = {}
	for i, width in ipairs({ 7, 5, 3, 1 }) do
		local t = parent:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Colors().text.grey:GetRGB())
		t:SetSize(width, 1)
		t:SetPoint('TOPLEFT', parent, 'RIGHT', -12 - floor(width / 2), 3 - i)
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
		if fontMode and font then
			SetFieldFont(self.text, font, FIELD_FONT_SIZE, '')
		else
			SetFieldFont(self.text)
		end
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

-- ColorPickerFrame is Blizzard's: used only through its public API, and no
-- Lua field is written onto it. The forever branch's picker is the mainline
-- one, where opacity is the alpha (1 is solid). Two C methods move it above the
-- options window, as AceGUI's color picker does (AceGUIWidget-ColorPicker.lua):
-- SetFrameStrata('FULLSCREEN_DIALOG') and SetFrameLevel(swatch level + 10).
-- Its own strata is DIALOG, under the window (FULLSCREEN_DIALOG), where it
-- opens behind it and its GLOBAL_MOUSE_DOWN cancel takes the next click.
local function OpenPicker(info, swatch)
	-- Forever and retail both have SetupColorPickerAndShow. Without it the swatch
	-- does nothing: the older way means writing fields onto Blizzard's frame.
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetFrameStrata('FULLSCREEN_DIALOG')
		ColorPickerFrame:SetFrameLevel(swatch:GetFrameLevel() + 10)
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
		}, self.frame)
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

	-- A press while waiting is the new key. Esc clears the binding.
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
	w.image = frame:CreateTexture(nil, 'ARTWORK')
	w.image:Hide()
	-- The image's border, in SaftUI's theme like an action button's icon (Icon
	-- zoom's preview is one). It shows only with an image (ShowImage), and lies
	-- outside the image, which Fit places the border's width in from the row's
	-- corner: the row's edge is the scroll area's, which cuts what lies past it.
	st:SetBackdrop(w.image, 'theme', 'theme', 'action')
	w.image.backdrop:Hide()
	w.text = NewText(frame, 'LEFT')
	w.text:SetWordWrap(true)
	w.measure = NewText(frame, 'LEFT')
	w.measure:SetWordWrap(false)
	w.measure:Hide()
end

local DESCRIPTION_SIZES = { small = FIELD_FONT_SIZE, medium = FIELD_FONT_SIZE + 2, large = FIELD_FONT_SIZE + 5 }
local IMAGE_SIZE, IMAGE_GAP = 32, 8 -- AceGUI's label image is 32 square without a size

define('description', {
	GetWidth = function(self) return self.frame:GetWidth() end,

	-- The window sizes a description to its row. The height follows the text,
	-- and the image when there is one.
	SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self:Fit()
	end,

	-- The text takes what the image and its border leave of the width. Beside
	-- an image taller than it, it sits in the image's middle, as AceGUI's label
	-- puts it. The border's width is the theme's now: a theme picked on the
	-- Theme tab reaches the row when it is drawn again.
	Fit = function(self)
		local imageWidth, imageHeight = 0, 0
		if self.image:IsShown() then
			local border = st:ThemeInset('theme', 'theme')
			self.image:ClearAllPoints()
			self.image:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', border, -border)
			imageWidth = self.image:GetWidth() + 2 * border
			imageHeight = self.image:GetHeight() + 2 * border
		end
		local textLeft = imageWidth > 0 and imageWidth + IMAGE_GAP or 0
		local lineHeight = floor((self.size or FIELD_FONT_SIZE) * 1.3)
		local lines = CountLines(self.measure, self.fullText or '', self.frame:GetWidth() - textLeft - 10)
		local textHeight = lines * lineHeight
		local textTop = imageHeight > textHeight and floor((imageHeight - textHeight) / 2) or 0
		self.text:ClearAllPoints()
		self.text:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', textLeft, -textTop)
		self.text:SetPoint('TOPRIGHT', self.frame, 'TOPRIGHT', 0, -textTop)
		self.text:SetHeight(textHeight)
		self.frame:SetHeight(max(textHeight, imageHeight))
	end,

	-- AceConfigDialog's description image: image (a path or fileID, or a
	-- function giving one with its width and height), imageWidth and
	-- imageHeight, and imageCoords (4 or 8 numbers in a table, or a function
	-- giving one). Anything but a path or fileID draws no image.
	ShowImage = function(self)
		local root, row = self.root, self.row
		local image, width, height = OM.Member(root, row, 'image')
		if type(image) ~= 'string' and type(image) ~= 'number' then
			self.image:Hide()
			self.image.backdrop:Hide()
			return
		end
		if not width then width = OM.Member(root, row, 'imageWidth') end
		if not height then height = OM.Member(root, row, 'imageHeight') end
		self.image:SetTexture(image)
		self.image:SetSize(type(width) == 'number' and width or IMAGE_SIZE, type(height) == 'number' and height or IMAGE_SIZE)
		-- As AceGUI's label: any other count of numbers shows the whole texture,
		-- which also undoes a pooled widget's last crop.
		local coords = OM.Member(root, row, 'imageCoords')
		if type(coords) == 'table' and (#coords == 4 or #coords == 8) then
			self.image:SetTexCoord(unpack(coords))
		else
			self.image:SetTexCoord(0, 1, 0, 1)
		end
		self.image:Show()
		self.image.backdrop:Show()
	end,

	Refresh = function(self)
		local text = self.row.name
		if type(text) ~= 'string' then text = '' end
		-- fontSize: small (the default), medium or large.
		local size = DESCRIPTION_SIZES[OM.Member(self.root, self.row, 'fontSize')] or FIELD_FONT_SIZE
		self.size = size
		for _, fs in ipairs({ self.text, self.measure }) do
			SetFieldFont(fs, nil, size)
		end
		self.fullText = text
		self.text:SetText(text)
		self.text:SetTextColor(Colors().text.normal:GetRGB())
		self:ShowImage()
		self:Fit()
	end,
})

------------------------------------------------------------------ position

-- The Position block: THIS [dots] TO [target] AT ITS [dots] OFFSET [X over Y],
-- each part a caption over a 48 tall band, 12 apart. One block per option
-- (type 'position'); its get/set/validate take the part first: 'point',
-- 'rel_point', 'x_off', 'y_off', 'frame', 'relative_to'.
local POINTS = { 'TOPLEFT', 'TOP', 'TOPRIGHT', 'LEFT', 'CENTER', 'RIGHT', 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT' }
local POS_GAP, POS_BAND, POS_CAPTION_HEIGHT, POS_CAPTION_GAP = 12, 48, 13, 4
local POS_BAND_TOP = POS_CAPTION_HEIGHT + POS_CAPTION_GAP
local POS_DOT_CELL, POS_DOT_MARGIN = 14, 3
local POS_BOX, POS_NUDGE, POS_AXIS, POS_AXIS_GAP = 22, 14, 12, 8
local POS_NAME_WIDTH, POS_SELECT_WIDTH, POS_NAME_HEIGHT = 120, 140, 24
-- The nudge box overlaps the edit box's right edge by 1: one shared seam.
local POS_OFFSET_WIDTH = POS_AXIS + POS_AXIS_GAP + 46 + POS_NUDGE - 1
local DOT_GREY = { 0.333, 0.333, 0.333 }

-- The dot's look: 4x4 grey, or 8x8 blue when it is the picked one; the text
-- color while the mouse is on it.
local function PaintDot(dot)
	local r, g, b
	if dot.hovered then
		r, g, b = Colors().text.normal:GetRGB()
	elseif dot.picked then
		r, g, b = Colors().button.blue:GetRGB()
	else
		r, g, b = unpack(DOT_GREY)
	end
	local size = dot.picked and 8 or 4
	dot.dot:SetSize(size, size)
	dot.dot:SetColorTexture(r, g, b)
end

-- A 48x48 square of nine dot buttons; onPick(point) on a click.
local function DotSquare(w, parent, onPick)
	local square = Box(st:CreateFrame('Frame', nil, parent))
	square:SetSize(POS_BAND, POS_BAND)
	square.dots = {}
	for i, point in ipairs(POINTS) do
		local button = st:CreateFrame('Button', nil, square)
		button:SetSize(POS_DOT_CELL, POS_DOT_CELL)
		local col, line = (i - 1) % 3, floor((i - 1) / 3)
		button:SetPoint('TOPLEFT', square, 'TOPLEFT', POS_DOT_MARGIN + col * POS_DOT_CELL, -(POS_DOT_MARGIN + line * POS_DOT_CELL))
		button.dot = button:CreateTexture(nil, 'OVERLAY')
		button.dot:SetPoint('CENTER', button, 'CENTER', 0, 0)
		button.point = point
		button:SetScript('OnClick', function()
			if w.disabled then return end
			onPick(point)
		end)
		button:SetScript('OnEnter', function(self)
			if not w.disabled then self.hovered = true; PaintDot(self) end
			w:Tip(true)
		end)
		button:SetScript('OnLeave', function(self)
			self.hovered = false
			PaintDot(self)
			w:Tip(false)
		end)
		PaintDot(button)
		square.dots[i] = button
	end
	return square
end

-- One half of the nudge pair: a 14x11 button (a clickable region of the
-- pair's box) with a three-row arrow, 2/4/6 wide, in whole pixels. Up sits in
-- the box's rows 1-9 (the arrow in rows 4-6, from the button's TOP); down in rows
-- 11-20 (rows 3-5 of its button, from its TOP).
local function NudgeButton(w, parent, up, onClick)
	local button = st:CreateFrame('Button', nil, parent)
	button:SetSize(POS_NUDGE, POS_BOX / 2)
	button.arrows = {}
	for i = 1, 3 do
		local t = button:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Colors().text.grey:GetRGB())
		t:SetSize(up and (2 * i) or (8 - 2 * i), 1)
		t:SetPoint('TOP', button, 'TOP', 0, -((up and 3 or 2) + i))
		button.arrows[i] = t
	end
	button:SetScript('OnClick', function()
		if w.disabled then return end
		onClick()
	end)
	button:SetScript('OnEnter', function(self)
		if not w.disabled then
			for _, t in ipairs(self.arrows) do t:SetColorTexture(Colors().text.normal:GetRGB()) end
		end
		w:Tip(true)
	end)
	button:SetScript('OnLeave', function(self)
		for _, t in ipairs(self.arrows) do t:SetColorTexture(Colors().text.grey:GetRGB()) end
		w:Tip(false)
	end)
	return button
end

-- The nudge pair: one 14x22 box with a 1px divider between up and down, and
-- the two buttons over its halves.
local function NudgePair(w, parent, onUp, onDown)
	local pair = Box(st:CreateFrame('Frame', nil, parent))
	pair:SetSize(POS_NUDGE, POS_BOX)
	local divider = pair:CreateTexture(nil, 'ARTWORK')
	divider:SetColorTexture(unpack(EDGE))
	divider:SetSize(POS_NUDGE - 2, 1)
	divider:SetPoint('TOPLEFT', pair, 'TOPLEFT', 1, -(POS_BOX / 2 - 1))
	local up = NudgeButton(w, pair, true, onUp)
	up:SetPoint('TOPLEFT', pair, 'TOPLEFT', 0, 0)
	local down = NudgeButton(w, pair, false, onDown)
	down:SetPoint('BOTTOMLEFT', pair, 'BOTTOMLEFT', 0, 0)
	return pair, up, down
end

-- An edit box of the block. onEnter(text) runs on Enter, after focus is dropped.
local function PositionEdit(w, parent, justify, onEnter)
	local edit = Box(st:CreateFrame('EditBox', nil, parent))
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH(justify)
	edit:SetTextInsets(justify == 'CENTER' and 2 or 8, justify == 'CENTER' and 2 or 8, 0, 0)
	edit:SetAutoFocus(false)
	edit:SetScript('OnEnter', function(self)
		if not (w.disabled or self:HasFocus()) then Edge(self, true) end
		w:Tip(true)
	end)
	edit:SetScript('OnLeave', function(self)
		if not self:HasFocus() then Edge(self, false) end
		w:Tip(false)
	end)
	edit:SetScript('OnEnterPressed', function(self)
		if not w.row or w.disabled then return end
		local text = self:GetText()
		self:ClearFocus()
		onEnter(text)
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
	return edit
end

builders.position = function(w)
	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetHeight(POS_BAND_TOP + POS_BAND)
	w.frame = frame

	local function PickDot(part) return function(point) w:Commit(part, point) end end
	w.thisSquare = DotSquare(w, frame, PickDot('point'))
	w.atSquare = DotSquare(w, frame, PickDot('rel_point'))
	w.this, w.at = w.thisSquare.dots, w.atSquare.dots

	w.name = PositionEdit(w, frame, 'LEFT', function(text) w:Commit('frame', strtrim(text)) end)

	w.select = Box(st:CreateFrame('Button', nil, frame))
	w.select:SetSize(POS_SELECT_WIDTH, POS_BOX)
	w.select.text = NewText(w.select, 'LEFT')
	w.select.text:SetPoint('LEFT', w.select, 'LEFT', 8, 0)
	w.select.text:SetPoint('RIGHT', w.select, 'RIGHT', -22, 0)
	Caret(w.select)
	w.select:SetScript('OnClick', function() w:Open() end)
	w.select:SetScript('OnEnter', function(self)
		if not w.disabled then Edge(self, true) end
		w:Tip(true)
	end)
	w.select:SetScript('OnLeave', function(self) Edge(self, false); w:Tip(false) end)
	w.select:SetScript('OnHide', function(self)
		if W.ListOwner() == self then W.CloseList() end
	end)

	-- X and Y: label, box, then the nudge pair, overlapping the box's right edge by 1.
	local function Axis(label, part, errName)
		local axis = NewText(frame, 'LEFT')
		axis:SetText(label)
		axis:SetWidth(POS_AXIS)
		local box = PositionEdit(w, frame, 'CENTER', function(text)
			local number = tonumber(strtrim(text))
			if not number then
				w:Refresh()
				if w.onChanged then w.onChanged(false, errName .. ' must be a number') end
				return
			end
			w:Commit(part, number)
		end)
		box:SetSize(46, POS_BOX)
		local pair, up, down = NudgePair(w, frame, function() w:Nudge(part, 1) end, function() w:Nudge(part, -1) end)
		pair:SetPoint('TOPLEFT', box, 'TOPRIGHT', -1, 0)
		return axis, box, up, down
	end
	w.xLabel, w.x, w.xUp, w.xDown = Axis('X', 'x_off', 'X')
	w.yLabel, w.y, w.yUp, w.yDown = Axis('Y', 'y_off', 'Y')

	-- Captions: shown ones are in w.captions, left to right.
	w.captionFor = {}
	for _, key in ipairs({ 'this', 'to', 'at', 'offset' }) do
		local fs = frame:CreateFontString(nil, 'OVERLAY')
		fs:SetFontObject(st.OptionsBody.Font('caption'))
		fs:SetJustifyH('CENTER')
		fs:SetWordWrap(false)
		fs:SetHeight(POS_CAPTION_HEIGHT)
		w.captionFor[key] = fs
	end
	w.captionFor.this:SetText('THIS')
	w.captionFor.to:SetText('TO')
	w.captionFor.at:SetText('AT ITS')
	w.captionFor.offset:SetText('OFFSET')
	w.captions = {}
end

define('position', {
	-- A block's parts are laid out for the row's target; nothing of a previous
	-- bind is left (the dropdown, the name box, the TO caption, the widths).
	Refresh = function(self)
		local root, row = self.root, self.row
		local target = OM.Member(root, row, 'target')
		if target ~= 'name' and target ~= 'select' then target = nil end
		self.target = target

		local point, relPoint = self:Value('point'), self:Value('rel_point')
		for i, dot in ipairs(self.this) do
			dot.hovered, dot.picked = false, POINTS[i] == point
			PaintDot(dot)
		end
		for i, dot in ipairs(self.at) do
			dot.hovered, dot.picked = false, POINTS[i] == relPoint
			PaintDot(dot)
		end
		self.x:SetText(tostring(tonumber(self:Value('x_off')) or 0))
		self.y:SetText(tostring(tonumber(self:Value('y_off')) or 0))

		-- The TO part.
		local showName = target == 'name'
		local toWidth = 0
		if target == 'name' then
			toWidth = POS_NAME_WIDTH
		elseif target == 'select' then
			toWidth = POS_SELECT_WIDTH
			local key = self:Value('relative_to')
			local values = OM.Member(root, row, 'values')
			local label = ''
			if type(values) == 'table' and key ~= nil and values[key] ~= nil then label = tostring(values[key]) end
			SetFieldFont(self.select.text)
			self.select.text:SetText(label)
			showName = key ~= nil and key == OM.Member(root, row, 'nameKey')
		end
		self.select:SetShown(target == 'select')
		if showName then self.name:SetText(tostring(self:Value('frame') or '')) end
		self.name:SetShown(showName)
		self.name:SetSize(target == 'select' and POS_SELECT_WIDTH or POS_NAME_WIDTH,
			target == 'select' and POS_BOX or POS_NAME_HEIGHT)

		-- Left to right, 12 apart.
		local frame, x = self.frame, 0
		local captions = {}
		local function Part(key, width)
			local fs = self.captionFor[key]
			fs:ClearAllPoints()
			fs:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, 0)
			fs:SetWidth(width)
			fs:SetTextColor(Colors().text.grey:GetRGB())
			fs:Show()
			captions[#captions + 1] = fs
			local at = x
			x = x + width + POS_GAP
			return at
		end
		local band = -POS_BAND_TOP
		self.thisSquare:ClearAllPoints()
		self.thisSquare:SetPoint('TOPLEFT', frame, 'TOPLEFT', Part('this', POS_BAND), band)
		if target then
			local at = Part('to', toWidth)
			self.select:ClearAllPoints()
			self.name:ClearAllPoints()
			if target == 'select' then
				self.select:SetPoint('TOPLEFT', frame, 'TOPLEFT', at, band)
				self.name:SetPoint('TOPLEFT', frame, 'TOPLEFT', at, band - POS_BOX - 4)
			else
				self.name:SetPoint('TOPLEFT', frame, 'TOPLEFT', at, band - (POS_BAND - POS_NAME_HEIGHT) / 2)
			end
		else
			self.captionFor.to:Hide()
		end
		self.atSquare:ClearAllPoints()
		self.atSquare:SetPoint('TOPLEFT', frame, 'TOPLEFT', Part('at', POS_BAND), band)
		local offsetAt = Part('offset', POS_OFFSET_WIDTH)
		for i, axis in ipairs({ { self.xLabel, self.x }, { self.yLabel, self.y } }) do
			local y = band - (i - 1) * (POS_BOX + 4)
			axis[1]:ClearAllPoints()
			axis[1]:SetPoint('TOPLEFT', frame, 'TOPLEFT', offsetAt, y - 3)
			axis[2]:ClearAllPoints()
			axis[2]:SetPoint('TOPLEFT', frame, 'TOPLEFT', offsetAt + POS_AXIS + POS_AXIS_GAP, y)
			SetFieldFont(axis[1])
			axis[1]:SetTextColor(Colors().text.normal:GetRGB())
		end
		wipe(self.captions)
		for i, fs in ipairs(captions) do self.captions[i] = fs end
		self.width = x - POS_GAP
		frame:SetWidth(self.width)
	end,

	Nudge = function(self, part, direction)
		if self.disabled or not self.row then return end
		local stored = tonumber(self:Value(part)) or 0
		self:Commit(part, stored + direction * (IsShiftKeyDown() and 10 or 1))
	end,

	-- The window shows the row's desc over the whole block (set by the body).
	Tip = function(self, on)
		if self.onTip then self.onTip(on) end
	end,

	Open = function(self)
		if self.disabled or not self.row or self.target ~= 'select' then return end
		local entries, fontMode = ListEntries(self.root, self.row)
		W.OpenList(self.select, entries, self:Value('relative_to'), function(key) self:Commit('relative_to', key) end, fontMode)
	end,

	OnDisabled = function(self, disabled)
		for _, square in ipairs({ self.thisSquare, self.atSquare }) do
			for _, dot in ipairs(square.dots) do dot:EnableMouse(not disabled) end
		end
		for _, control in ipairs({ self.select, self.xUp, self.xDown, self.yUp, self.yDown }) do
			control:EnableMouse(not disabled)
		end
		for _, edit in ipairs({ self.name, self.x, self.y }) do
			edit:EnableMouse(not disabled)
			if disabled then edit:ClearFocus() end
		end
	end,

	OnRelease = function(self)
		self.onTip = nil
		if W.ListOwner() == self.select then W.CloseList() end
	end,
})

------------------------------------------------------------------ custom types

-- The types other files define (the bags' Categories tab): W.CUSTOM[rowType]
-- is { bare = true | false, titled = true | false } for each. The body draws
-- a bare type's row with no label, the widget across the whole line, and a
-- titled bare type's with its name above the widget (optionsbody.lua).
W.CUSTOM = {}

-- The types above, which W.Define can't replace.
local BUILT_IN = {}
for rowType in pairs(builders) do BUILT_IN[rowType] = true end

-- W.Define(rowType, { width = n, bare = bool, titled = bool, build = function(w) end,
-- methods = { Refresh = ..., OnRelease = ..., ... } }) makes a widget type.
-- titled is for a bare type only: its row shows its name over the widget.
-- build makes w.frame, and whatever else the type keeps, once per widget.
-- The methods are copied onto each widget as define copies a built-in
-- type's, so Bind, Refresh (nothing after a release), Commit, SetDisabled
-- (OnDisabled) and Release (OnRelease) work as for the built-in types.
-- width is W.WIDTH[rowType] and the widget's GetWidth (0 when nil). A custom
-- type may be defined again (its file loaded again): widgets are then built
-- from the new definition, in a new pool, so the old ones never come back.
-- Redefining a built-in type is an error.
function W.Define(rowType, spec)
	if BUILT_IN[rowType] then
		error(format('SaftUI options: %q is a built-in widget type', tostring(rowType)), 2)
	end
	if type(rowType) ~= 'string' or type(spec) ~= 'table' or type(spec.build) ~= 'function' then
		error(format('SaftUI options: W.Define(%q) needs a type name and a build function', tostring(rowType)), 2)
	end
	builders[rowType] = spec.build
	define(rowType, spec.methods or {})
	pools[rowType] = {}
	W.WIDTH[rowType] = spec.width or 0
	W.CUSTOM[rowType] = { bare = spec.bare and true or false, titled = (spec.bare and spec.titled) and true or false }
end

------------------------------------------------------------------ the check list

-- A row of the open list: a check list's has a check box at its left, marked
-- by isChecked(key), and its label after it; a select's has no box and its
-- label 8 in, as BuildList made it. Rows are shared by both, so each fill
-- lays them out for the list that's open.
function LayCheckRow(row, entry)
	local checking = list.isChecked ~= nil
	if checking and not row.box then
		row.box = CheckBox(row, 18)
		row.box:SetPoint('LEFT', row, 'LEFT', 6, 0)
		row.box:EnableMouse(false)
	end
	if row.box then
		row.box:SetShown(checking)
		if checking then SetCheck(row.box, list.isChecked(entry.key)) end
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
