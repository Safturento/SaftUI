local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's confirm dialog (st.OptionsWidgets,
	optionswidgets.lua): W.Confirm and W.Prompt, one modal at a time over
	the window.
]]

local floor, max, ceil = math.floor, math.max, math.ceil

local Box, Edge, HoverEdge, BlizzardLook = W.Box, W.Edge, W.HoverEdge, W.BlizzardLook
local LookButton = W.LookButton
local FIELD_HEIGHT, LIST_STRATA = Kit.FIELD_HEIGHT, Kit.LIST_STRATA
local FIELD_FONT_SIZE, NewText = Kit.FIELD_FONT_SIZE, Kit.NewText
local LookInput, LookWindow = Kit.LookInput, Kit.LookWindow

------------------------------------------------------------------ the full-screen key catchers

-- The keys of a catcher (the confirm dialog's, the select list's): while it's
-- shown it takes the keys in consumes ({ KEY = true }) and lets every other
-- one go on to the game. act(key) runs on each key. Out of combat only, as
-- SetPropagateKeyboardInput is protected in it.
local function CatchKeys(catcher, consumes, act)
	catcher:SetScript('OnKeyDown', function(self, key)
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(not consumes[key]) end
		act(key)
	end)
	catcher:SetScript('OnShow', function(self) self:EnableKeyboard(true) end)
	catcher:SetScript('OnHide', function(self) self:EnableKeyboard(false) end)
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
local DIALOG_WIDTH = 320

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

	-- Drawn by its skin (LookDialog), which is under it.
	local frame = st:CreateFrame('Frame', nil, catcher)
	frame:SetFrameLevel(110)
	frame:SetWidth(DIALOG_WIDTH)
	frame:EnableMouse(true)

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
	CatchKeys(catcher, { ESCAPE = true, ENTER = true }, function(key)
		if key == 'ESCAPE' then Answer(false) elseif key == 'ENTER' then Answer(true) end
	end)

	dialog = { catcher = catcher, frame = frame, text = text, measure = measure, yes = yes, no = no, box = box }
end

-- The frame the confirm dialog centers on (the options window sets it).
function W.SetDialogAnchor(frame)
	W.dialogAnchor = frame
end

-- The dialog in SaftUI's theme now: drawn as the options window is, with
-- Blizzard's panel buttons and a text box under Blizzard.
local function LookDialog()
	local blizzard = BlizzardLook()
	dialog.skin = LookWindow(dialog.frame, dialog.catcher)
	LookButton(dialog.yes, blizzard)
	LookButton(dialog.no, blizzard)
	LookInput(dialog.box, blizzard, FIELD_HEIGHT)
end

-- One modal at a time, for Confirm and Prompt: the dialog is built once, and
-- opening either answers an open one No first. Sets the text, the buttons and
-- the height, and shows the dialog (a prompt's box is placed and shown here).
local function OpenDialog(text, onYes, onNo, prompt, yesLabel, noLabel)
	if not dialog then BuildDialog() end
	if dialog.catcher:IsShown() then Answer(false) end
	LookDialog()
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
	-- Its height is odd for an odd number of lines: placed by its corner, so
	-- its edges stay on whole units.
	W.PlaceCentred(dialog.frame, W.dialogAnchor or UIParent, DIALOG_WIDTH, height)
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

-- The confirm dialog's frames { catcher, frame, text, yes, no, box, skin }
-- (nil until first asked; skin is what draws it as the window is under
-- Blizzard). For tests.
function W.GetDialogFrames() return dialog end

------------------------------------------------------------------ for the later widget files

Kit.CountLines = CountLines
Kit.CatchKeys = CatchKeys
