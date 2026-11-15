-- SaftUI-Core/Config/optionsdialog.lua, the options window's confirm dialog
-- (W.Confirm and W.Prompt, one modal at a time over the window), and its
-- buttons under SaftUI's theme Blizzard.
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua, with a real
-- AceConfigRegistry-3.0). Synthetic AceConfig option tables stand for the
-- options. The mouse and the keyboard are played by firing the frames' scripts
-- (stub.fire_script), and SaftUI's color picker through its own boxes
-- and buttons (options_widgets_helpers.lua's pick_color). The world and the helpers are
-- options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
local W = st.OptionsWidgets
local yes, click, no, bind, opt = H.yes, H.click, H.no, H.bind, H.opt
local check_no_box, check_box, panel_of, theme = H.check_no_box, H.check_box, H.panel_of, H.theme
local insets, INPUT_ART, atlases_of, size_of = H.insets, H.INPUT_ART, H.atlases_of, H.size_of

------------------------------------------------------------------ confirm dialog

test('W.Confirm: centered over the window, Esc is No, Enter is Yes', function()
	local window = CreateFrame('Frame', nil, UIParent)
	window:SetSize(400, 300)
	window:SetPoint('CENTER', UIParent, 'CENTER', 100, -50)
	W.SetDialogAnchor(window)
	local answers = {}
	W.Confirm('Sure?', function() answers[#answers + 1] = 'yes' end, function() answers[#answers + 1] = 'no' end)
	local d = W.GetDialogFrames()
	check(d.catcher:IsShown(), 'shown')
	local wx, wy = window:GetCenter()
	local dx, dy = d.frame:GetCenter()
	eq(dx, wx, 'centered across')
	-- An odd height (one line of text) is half a unit up, so its edges stay on whole pixels.
	check(math.abs(dy - wy) <= 0.5, 'and down, within half a unit: ' .. dy .. ' for ' .. wy)
	eq(d.frame:GetTop(), math.floor(d.frame:GetTop()), 'its top on a whole pixel')
	eq(d.frame:GetBottom(), math.floor(d.frame:GetBottom()), 'and its bottom')
	eq(W.ConfirmText(), 'Sure?', 'text')

	stub.fire_script(d.catcher, 'OnKeyDown', 'ESCAPE')
	eq(answers[1], 'no', 'Esc is No')
	check(not d.catcher:IsShown(), 'closed')

	W.Confirm('Sure?', function() answers[#answers + 1] = 'yes' end, function() answers[#answers + 1] = 'no' end)
	stub.fire_script(d.catcher, 'OnKeyDown', 'ENTER')
	eq(answers[2], 'yes', 'Enter is Yes')

	W.Confirm('Sure?', function() answers[#answers + 1] = 'yes' end, function() answers[#answers + 1] = 'no' end)
	stub.fire_script(d.catcher, 'OnMouseDown')
	eq(answers[3], 'no', 'a click outside is No')

	-- A second question answers the first No.
	W.Confirm('First', function() answers[#answers + 1] = 'y1' end, function() answers[#answers + 1] = 'n1' end)
	W.Confirm('Second', function() answers[#answers + 1] = 'y2' end)
	eq(answers[4], 'n1', 'the open question is declined')
	eq(W.ConfirmText(), 'Second', 'the new one is up')
	yes()
	eq(answers[5], 'y2', 'and answers on its own')
	W.SetDialogAnchor(nil)
end)

test('W.Confirm: its two buttons can be named, and with no window up it centers on the screen', function()
	local window = CreateFrame('Frame', nil, UIParent)
	window:SetSize(400, 300)
	window:SetPoint('CENTER', UIParent, 'CENTER', 100, -50)
	window:Hide()
	W.SetDialogAnchor(window)
	local answers = {}
	W.Confirm('Sell?', function() answers[#answers + 1] = 'sell' end, function() answers[#answers + 1] = 'keep' end,
		{ yes = 'Sell them', no = 'Keep them', enter = false })
	local d = W.GetDialogFrames()
	eq(d.yes.text:GetText(), 'Sell them', 'the first button')
	eq(d.no.text:GetText(), 'Keep them', 'the second')
	local ux = UIParent:GetCenter()
	eq(d.frame:GetCenter(), ux, 'centered on the screen, not on the hidden window')
	stub.fire_script(d.catcher, 'OnKeyDown', 'ENTER')
	eq(#answers, 0, 'Enter answers nothing when the caller says so')
	check(d.catcher:IsShown(), 'and the question stays up')
	stub.fire_script(d.catcher, 'OnKeyDown', 'ESCAPE')
	eq(answers[1], 'keep', 'Esc is the second answer')
	W.Confirm('Sell?', function() answers[#answers + 1] = 'sell2' end, nil, { yes = 'Sell them', no = 'Keep them', enter = false })
	yes()
	eq(answers[2], 'sell2', 'a click on the first button answers it')
	W.Confirm('Sell?', function() answers[#answers + 1] = 'default' end)
	stub.fire_script(d.catcher, 'OnKeyDown', 'ENTER')
	eq(answers[3], 'default', 'a Confirm with no opts still answers Yes on Enter')
	W.Confirm('Sell?', function() end)
	eq(d.yes.text:GetText(), 'Yes', 'the default label is back')
	eq(d.no.text:GetText(), 'No', 'and the other')
	no()
	W.SetDialogAnchor(nil)
end)

test('W.Prompt: a box with the initial text, Enter and the button accept it, Esc cancels', function()
	local window = CreateFrame('Frame', nil, UIParent)
	window:SetSize(400, 300)
	window:SetPoint('CENTER', UIParent, 'CENTER', 100, -50)
	W.SetDialogAnchor(window)
	local got = {}
	local function ask(initial, opts)
		opts = opts or {}
		opts.onCancel = function() got[#got + 1] = 'cancel' end
		W.Prompt('Name it', initial, function(text) got[#got + 1] = text end, opts)
	end
	eq(W.PromptBox(), nil, 'no prompt open')
	ask('start')
	local d = W.GetDialogFrames()
	local box = W.PromptBox()
	check(box and box:IsShown(), 'the box shows')
	eq(W.ConfirmText(), 'Name it', 'the text')
	eq(box:GetText(), 'start', 'prefilled')
	check(box:HasFocus(), 'focused')
	local hl = stub.state(box).highlight
	check(hl and hl[1] == 0 and hl[2] == -1, 'all selected')
	local wx, wy = window:GetCenter()
	local dx, dy = d.frame:GetCenter()
	eq(dx, wx, 'centered across')
	-- An odd height (one line of text) is half a unit up, so its edges stay on whole pixels.
	check(math.abs(dy - wy) <= 0.5, 'and down, within half a unit: ' .. dy .. ' for ' .. wy)
	eq(d.frame:GetTop(), math.floor(d.frame:GetTop()), 'its top on a whole pixel')
	eq(d.frame:GetBottom(), math.floor(d.frame:GetBottom()), 'and its bottom')
	check(d.yes:IsShown() and d.no:IsShown(), 'two buttons')
	eq(d.yes.text:GetText(), 'Yes', 'default accept label')
	eq(d.no.text:GetText(), 'No', 'default cancel label')

	box:SetText('typed')
	stub.fire_script(box, 'OnEnterPressed')
	eq(got[1], 'typed', 'Enter accepts the box text')
	check(not d.catcher:IsShown(), 'closed')
	eq(W.PromptBox(), nil, 'no prompt open after')
	check(not box:HasFocus(), 'focus dropped')

	ask('x'); W.PromptBox():SetText('via button'); click(d.yes)
	eq(got[2], 'via button', 'the accept button')

	ask('x'); stub.fire_script(W.PromptBox(), 'OnEscapePressed')
	eq(got[3], 'cancel', 'Esc in the box cancels')
	ask('x'); stub.fire_script(d.catcher, 'OnKeyDown', 'ESCAPE')
	eq(got[4], 'cancel', 'Esc outside cancels')
	ask('x'); click(d.no)
	eq(got[5], 'cancel', 'the cancel button')
	ask('x'); stub.fire_script(d.catcher, 'OnMouseDown')
	eq(got[6], 'cancel', 'a click outside')
	ask('x'); W.CancelConfirm()
	eq(got[7], 'cancel', 'CancelConfirm (the window closing) cancels a prompt')
	eq(#got, 7, 'nothing was accepted by the cancels')

	-- No onCancel is fine.
	W.Prompt('Name it', nil, function(text) got[#got + 1] = 'none:' .. text end)
	eq(W.PromptBox():GetText(), '', 'empty without an initial text')
	stub.fire_script(d.catcher, 'OnKeyDown', 'ESCAPE')
	eq(#got, 7, 'cancelled quietly')
	W.SetDialogAnchor(nil)
end)

test('W.Prompt: labels, one button, maxLetters, and a taller dialog than a confirm', function()
	W.Confirm('One line', function() end)
	local confirm_height = W.GetDialogFrames().frame:GetHeight()
	no()
	W.Prompt('One line', 'x', function() end, { accept = 'Close', cancel = false, maxLetters = 0 })
	local d = W.GetDialogFrames()
	eq(d.yes.text:GetText(), 'Close', 'accept label')
	check(d.yes:IsShown() and not d.no:IsShown(), 'one button')
	eq(W.PromptBox():GetMaxLetters(), 0, 'uncapped')
	eq(d.frame:GetHeight(), confirm_height + 24 + 10, 'the box row is added to the height')
	eq(d.yes:GetCenter(), d.frame:GetCenter(), 'the one button is centered')
	stub.fire_script(d.catcher, 'OnKeyDown', 'ESCAPE')
	W.Prompt('One line', '', function() end, { maxLetters = 12, cancel = 'Never mind' })
	eq(W.PromptBox():GetMaxLetters(), 12, 'capped')
	eq(d.no.text:GetText(), 'Never mind', 'cancel label')
	check(d.no:IsShown(), 'two buttons again')
	stub.fire_script(d.catcher, 'OnKeyDown', 'ESCAPE')
	-- And a Confirm after a prompt is a plain Confirm again.
	W.Confirm('Plain', function() end)
	eq(W.PromptBox(), nil, 'no box for a confirm')
	check(not d.box:IsShown(), 'box hidden')
	eq(d.yes.text:GetText(), 'Yes', 'labels back')
	eq(d.no.text:GetText(), 'No', 'labels back')
	check(d.no:IsShown(), 'two buttons back')
	no()
end)

test('a prompt and a confirm are one modal: opening either answers the open one No', function()
	local got = {}
	W.Confirm('Sure?', function() got[#got + 1] = 'yes' end, function() got[#got + 1] = 'confirm no' end)
	W.Prompt('Name?', '', function() got[#got + 1] = 'accepted' end, { onCancel = function() got[#got + 1] = 'prompt cancel' end })
	eq(got[1], 'confirm no', 'the confirm is answered No')
	check(W.PromptBox() ~= nil, 'the prompt is up')
	W.Confirm('Sure again?', function() got[#got + 1] = 'yes2' end, function() got[#got + 1] = 'confirm2 no' end)
	eq(got[2], 'prompt cancel', 'the prompt is cancelled')
	eq(W.PromptBox(), nil, 'the prompt is gone')
	eq(W.ConfirmText(), 'Sure again?', 'the new question is up')
	W.Prompt('Name?', 'a', function(t) got[#got + 1] = t end)
	eq(got[3], 'confirm2 no', 'declined again')
	stub.fire_script(W.GetDialogFrames().catcher, 'OnKeyDown', 'ENTER')
	eq(got[4], 'a', 'Enter outside the box accepts too')
	eq(#got, 4, 'nothing else ran')
end)

test('descriptions, confirms and prompts count \\n as line breaks', function()
	local one = bind('description', 'one', opt('description', 'some words'))
	local base = one:GetHeight()
	local two = bind('description', 'two', opt('description', '\nsome words'))
	eq(two:GetHeight(), 2 * base, 'a leading newline is a blank first line')
	local three = bind('description', 'three', opt('description', 'a\nb\nc'))
	eq(three:GetHeight(), 3 * base, 'three short lines')
	local gap = bind('description', 'four', opt('description', 'a\n\nb'))
	eq(gap:GetHeight(), 3 * base, 'an empty line counts as one')
	one:Release(); two:Release(); three:Release(); gap:Release()

	local function height(open)
		open()
		local h = W.GetDialogFrames().frame:GetHeight()
		stub.fire_script(W.GetDialogFrames().catcher, 'OnKeyDown', 'ESCAPE')
		return h
	end
	local line = math.floor(15 * 1.3)
	local c1 = height(function() W.Confirm('one', function() end) end)
	eq(height(function() W.Confirm('one\ntwo\nthree', function() end) end), c1 + 2 * line, 'Confirm: three lines')
	local p1 = height(function() W.Prompt('one', '', function() end) end)
	eq(height(function() W.Prompt('\none', '', function() end) end), p1 + line, 'Prompt: a leading newline')
end)

test('W.Confirm: a longer text makes a taller dialog', function()
	W.Confirm('Short', function() end)
	local short = W.GetDialogFrames().frame:GetHeight()
	W.Confirm(string.rep('A long question that needs more than one line. ', 8), function() end)
	check(W.GetDialogFrames().frame:GetHeight() > short, 'taller')
	no()
end)

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test("the confirm dialog's buttons are panel buttons", function()
	theme('blizzard')
	W.Confirm('Sure?', function() end)
	local d = W.GetDialogFrames()
	for name, button in pairs({ yes = d.yes, no = d.no }) do
		eq((panel_of(button)), 'Left=Up,Middle=Up,Right=Up', name .. " is Blizzard's panel button")
		check_no_box(button, name)
		eq(size_of(button), '80x24', name .. ' keeps its size')
	end
	eq(d.frame.backdropInfo, nil, 'the dialog: no box of its own, its skin draws it')
	check(d.skin ~= nil and d.skin:IsShown(), 'the dialog is drawn as the window is')
	eq(st:DrawnTheme(d.skin), 'blizzard', "in SaftUI's theme")
	eq(st:DrawnKind(d.skin), 'panel', 'as a panel')
	eq(insets(d.skin, d.frame), '0,0,0,0', 'over the dialog frame')
	check(d.skin:GetFrameLevel() < d.frame:GetFrameLevel(), 'under it')
	no()
	W.Prompt('Name?', 'x', function() end)
	check_no_box(d.box, "the prompt's box")
	eq(atlases_of(d.box), INPUT_ART, "the prompt's box is a text box")
	no()

	theme('thick')
	W.Prompt('Name?', 'x', function() end)
	for name, button in pairs({ yes = d.yes, no = d.no }) do
		eq((panel_of(button)), '', 'Thick: ' .. name .. ' is no panel button')
		check_box(button, 'Thick: ' .. name)
	end
	-- The dialog is drawn by its skin in every theme (it was a Box under
	-- Thick and Thin, solid), so it is see-through with the window.
	eq(d.frame.backdropInfo, nil, 'Thick: no box of its own')
	check(d.skin:IsShown(), 'Thick: drawn as the window is')
	eq(st:DrawnTheme(d.skin), 'thick', "Thick: in SaftUI's theme")
	check_box(d.box, "Thick: the prompt's box", nil, true) -- focused, so lit
	eq(atlases_of(d.box), '', "Thick: no art on the prompt's box")
	no()
	eq(#take_errors(), 0, 'no errors')
end)
