-- SaftUI-Core/Config/optionssmalldialog.lua: OW:OpenDialog, the small dialog
-- over the window for an option table of its own (UF's Copy from), drawn
-- again by the window's renders, and its scroll under Blizzard.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OW = st.OptionsWindow
local close_all, drawn, frames, click, keys = H.close_all, H.drawn, H.frames, H.click, H.keys
local theme = H.theme

-- A table of the dialog's own: get and set on the group, a range hidden while
-- the toggle is off, and an inline group with a button.
local dialogValues, dialogRuns = { on = true, size = 5 }, 0
local function DialogTable()
	return {
		type = 'group', name = 'The group',
		get = function(info) return dialogValues[info[#info]] end,
		set = function(info, value) dialogValues[info[#info]] = value end,
		args = {
			on = { order = 1, type = 'toggle', name = 'On' },
			size = {
				order = 2, type = 'range', name = 'Size', min = 1, max = 10, step = 1,
				hidden = function() return not dialogValues.on end,
			},
			stuff = {
				order = 3, type = 'group', inline = true, name = 'Stuff',
				args = { go = { type = 'execute', name = 'Go', func = function() dialogRuns = dialogRuns + 1 end } },
			},
		},
	}
end

local function dialogRows()
	local out = {}
	for i, c in ipairs(OW.GetDialogFrames().body.cells) do out[i] = c.row.key end
	return table.concat(out, ',')
end

local function dialogCell(key)
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

------------------------------------------------------------------ OpenDialog

test('OpenDialog draws a table of its own in a small SaftUI dialog above the window', function()
	st.Config:Open('Loot')
	eq(OW:OpenDialog('My dialog', DialogTable()), true, 'it opens')
	local d = OW.GetDialogFrames()
	check(d.frame:IsShown(), 'shown')
	eq(d.title:GetText(), 'My dialog', 'its title')
	eq(dialogRows(), 'on,size,go', "the table's rows, its inline group a section")
	eq(d.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG', "the window's strata")
	check(d.frame:GetFrameLevel() > frames().window:GetFrameLevel() + 10, 'well above the window')
	check(st:GetCloseButton(d.frame) ~= nil, 'the close X')
	eq(drawn(), 'on', "the window's page is drawn as it was")

	-- Its own set re-renders it, not the window.
	local before = OW.GetRenderCount()
	click(dialogCell('on').widget.frame)
	eq(dialogValues.on, false, 'set through the model')
	eq(dialogRows(), 'on,go', 'the hidden range is gone')
	eq(OW.GetRenderCount(), before, "the window didn't render")
	click(dialogCell('go').widget.frame)
	eq(dialogRuns, 1, 'the button runs')
	dialogValues.on = true

	click(st:GetCloseButton(d.frame))
	check(not d.frame:IsShown(), 'the X closes it')
	eq(#d.body.cells, 0, 'and releases its rows')
	check(OW:IsShown(), 'the window stays open')
	close_all()
end)

test("OpenDialog's title can be a function, read on each render", function()
	local picked
	local options = DialogTable()
	options.args.on.set = function(_, value) picked = value end
	OW:OpenDialog(function() return picked == nil and 'Pick one' or 'Picked' end, options)
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Pick one', 'before')
	click(dialogCell('on').widget.frame)
	eq(d.title:GetText(), 'Picked', 'after the set')
	OW:CloseDialog()
end)

test("a drag in the dialog refreshes its other rows in place too; it's drawn again when let go", function()
	local size = 5
	OW:OpenDialog('Drag', {
		type = 'group', name = 'Drag',
		args = {
			size = { order = 1, type = 'range', name = 'Size', min = 1, max = 10, step = 1,
				get = function() return size end, set = function(_, v) size = v end },
			shown = { order = 2, type = 'input', name = 'Size shown',
				get = function() return tostring(size) end, set = function() end },
		},
	})
	local w, sizeRow = dialogCell('size').widget, dialogCell('size').row
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(8)
	eq(size, 8, 'set while dragging')
	eq(dialogCell('shown').widget.frame:GetText(), '8', 'the other row follows')
	-- A render builds the rows anew from the model; mid-drag they're the ones drawn.
	eq(dialogCell('size').row, sizeRow, 'not drawn again mid-drag')
	eq(dialogCell('size').widget, w, 'the slider is the one dragged')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	check(dialogCell('size').row ~= sizeRow, 'drawn again when let go')
	eq(dialogCell('shown').widget.frame:GetText(), '8', 'with the value set')
	OW:CloseDialog()
end)

test('Esc closes the dialog through its own catcher, and leaves the window open', function()
	st.Config:Open('Loot')
	OW:OpenDialog('Esc', DialogTable())
	local keys = OW.GetDialogFrames().keys
	check(keys:IsKeyboardEnabled(), 'its catcher is on while it shows')
	stub.fire_script(keys, 'OnKeyDown', 'A')
	check(OW:IsDialogShown(), 'A: still open')
	eq(keys:GetPropagateKeyboardInput(), true, 'A goes on')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsDialogShown(), 'Esc closes it')
	eq(keys:GetPropagateKeyboardInput(), false, 'Esc is kept, so the window under it stays')
	check(not keys:IsKeyboardEnabled(), 'the catcher is off once closed')
	check(OW:IsShown(), 'the window is still open')
	close_all()
end)

test('the dialog closes with the window and on entering combat, and refuses to open in combat', function()
	st.Config:Open('Loot')
	OW:OpenDialog('With the window', DialogTable())
	st.Config:Close()
	check(not OW:IsDialogShown(), 'closing the window closes it')

	-- Without the window too.
	OW:OpenDialog('Alone', DialogTable())
	check(OW:IsDialogShown(), 'open without the window')
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not OW:IsDialogShown(), 'entering combat closes it')

	stub.in_combat = true
	eq(OW:OpenDialog('Combat', DialogTable()), false, 'refused in combat')
	check(not OW:IsDialogShown(), 'not shown')
	close_all()
end)

test("the window's render draws an open dialog again, so it follows a change made elsewhere; not while its box is typed in or its slider held", function()
	st.Config:Open('Loot')
	local name, size = 'Before', 5
	OW:OpenDialog('Follow', {
		type = 'group', name = 'Follow',
		args = {
			note = { order = 1, type = 'input', name = function() return name end, get = function() return 'text' end, set = function() end },
			size = { order = 2, type = 'range', name = 'Size', min = 1, max = 10, step = 1,
				get = function() return size end, set = function(_, v) size = v end },
		},
	})
	eq(dialogCell('note').label:GetText(), 'Before', 'drawn')
	name = 'After'
	st.Config:Refresh()
	H.tick()
	eq(dialogCell('note').label:GetText(), 'After', "a change to the tree: the window's render drew it again")

	-- One of its boxes typed in: left be, so the typing isn't lost.
	local box = dialogCell('note').widget.frame
	box:SetFocus()
	name = 'Typed'
	OW:Render()
	eq(dialogCell('note').widget.frame, box, 'the box keeps the keyboard')
	eq(dialogCell('note').label:GetText(), 'After', 'not drawn again while typing')
	box:ClearFocus()
	OW:Render()
	eq(dialogCell('note').label:GetText(), 'Typed', 'drawn again once the box lets go')

	-- Its slider held: left be until the mouse is let go.
	local w, row = dialogCell('size').widget, dialogCell('size').row
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(7)
	OW:Render()
	eq(dialogCell('size').row, row, 'not drawn again mid-drag')
	eq(dialogCell('size').widget, w, 'the slider is still the one held')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	check(dialogCell('size').row ~= row, 'drawn again when let go')
	OW:Render()
	check(OW:IsDialogShown(), 'and still open')
	OW:CloseDialog()
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ under the Blizzard theme

test("the dialog's scroll reaches 7 past its content under Blizzard", function()
	-- So a dropdown's 7px glow at the content's right edge isn't clipped.
	theme('blizzard')
	OW:OpenDialog('Glow', DialogTable())
	local d = OW.GetDialogFrames()
	eq(d.scroll:GetWidth(), 527, 'Blizzard: 7 past the 520 content')
	eq(d.content:GetWidth(), 520, 'the content keeps its width')
	OW:CloseDialog()
	theme('thick')
	OW:OpenDialog('Glow', DialogTable())
	eq(d.scroll:GetWidth(), 520, 'Thick: the content, as before')
	-- Drawn again with the other look while open.
	theme('blizzard')
	OW:OpenDialog('Glow', DialogTable())
	eq(d.scroll:GetWidth(), 527, 'Blizzard again')
	OW:CloseDialog()
	theme('thick')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
