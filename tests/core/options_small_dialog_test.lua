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

test("the window's render leaves an open dialog be while its own dropdown list or a confirm is open", function()
	st.Config:Open('Loot')
	local name, value = 'Before', 'a'
	OW:OpenDialog('Guard', {
		type = 'group', name = 'Guard',
		args = {
			pick = { order = 1, type = 'select', name = function() return name end, values = { a = 'A', b = 'B' },
				get = function() return value end, set = function(_, v) value = v end },
		},
	})
	local W = st.OptionsWidgets
	eq(dialogCell('pick').label:GetText(), 'Before', 'drawn')
	local widget = dialogCell('pick').widget
	click(widget.frame)
	check(W.ListOwner() == widget.frame, "the dialog's dropdown list is open")
	name = 'During list'
	OW:Render()
	eq(dialogCell('pick').label:GetText(), 'Before', 'not drawn again under its open list')
	check(W.ListOwner() == widget.frame, 'the list stays open')
	W.CloseList()
	OW:Render()
	eq(dialogCell('pick').label:GetText(), 'During list', 'drawn again once the list is shut')

	name = 'During confirm'
	W.Confirm('Sure?', function() end)
	check(W.ConfirmText() ~= nil, 'a confirm is open')
	OW:Render()
	eq(dialogCell('pick').label:GetText(), 'During list', 'not drawn again under a confirm')
	W.CancelConfirm()
	OW:Render()
	eq(dialogCell('pick').label:GetText(), 'During confirm', 'drawn again once it is answered')

	-- Closing the dialog takes its list and a confirm with it.
	click(dialogCell('pick').widget.frame)
	check(W.ListOwner() ~= nil, 'its list open')
	OW:CloseDialog()
	eq(W.ListOwner(), nil, 'the list goes with the dialog')
	OW:OpenDialog('Guard', { type = 'group', name = 'Guard', args = {
		go = { order = 1, type = 'execute', name = 'Go', confirm = true, func = function() end },
	} })
	click(dialogCell('go').widget.frame)
	check(W.ConfirmText() ~= nil, 'a confirm from it')
	OW:CloseDialog()
	eq(W.ConfirmText(), nil, 'the confirm goes with the dialog')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the dialog ends its side padding (24) under its last row, Copy from's buttons floating there; a status line makes room for itself; Blizzard keeps its foot", function()
	local values = { t1 = true, t2 = false }
	local function CopyLike()
		return {
			type = 'group', name = 'Copy',
			get = function(info) return values[info[#info]] end,
			set = function(info, v) values[info[#info]] = v end,
			args = {
				settings = { order = 1, type = 'group', inline = true, name = 'Settings', args = {
					t1 = { order = 1, type = 'toggle', name = 'One' }, t2 = { order = 2, type = 'toggle', name = 'Two' },
				} },
				accept = { order = 2, type = 'execute', name = 'Confirm copy', align = 'center', func = function() end },
				cancel = { order = 3, type = 'execute', name = 'Cancel', align = 'center', func = function() end },
			},
		}
	end
	theme('thick')
	OW:OpenDialog('Copy', CopyLike())
	local d = OW.GetDialogFrames()
	local accept = dialogCell('accept')
	eq(accept.y, dialogCell('t1').y + 38 + 24, 'the buttons float 24 under the settings, as far as under them')
	eq(d.content:GetHeight(), accept.y + accept.height, 'the content ends at the buttons: no bottom margin')
	eq(accept.frame:GetBottom() - d.frame:GetBottom(), 24, 'Thick: 24 under the buttons, as at the sides (54 before)')
	eq(d.frame:GetHeight(), 58 + accept.y + accept.height + 24, 'the head, the rows, the side padding')
	check(not d.bar:IsShown(), 'nothing to scroll')
	-- A status line (a validate error) makes room for itself under the rows, and gives it back.
	d.body.onChanged(false, 'That will not do.')
	eq(d.status:GetText(), 'That will not do.', 'the status line')
	eq(accept.frame:GetBottom() - d.frame:GetBottom(), 30, "the foot grows to the status line's 30")
	check(d.status:GetTop() <= accept.frame:GetBottom(), 'the status line under the buttons')
	check(not d.bar:IsShown(), 'still nothing to scroll')
	d.body.onChanged(true)
	eq(d.status:GetText(), '', 'cleared')
	eq(dialogCell('accept').frame:GetBottom() - d.frame:GetBottom(), 24, 'and 24 again')
	OW:CloseDialog()

	-- Blizzard keeps its layout: the body's bottom margin and a foot of 30 under the last row.
	theme('blizzard')
	OW:OpenDialog('Copy', CopyLike())
	accept = dialogCell('accept')
	eq(accept.y, dialogCell('t1').y + 34 + 4, 'Blizzard: the buttons 4 under the settings, as before')
	eq(accept.frame:GetBottom() - d.frame:GetBottom(), 24 + 30, 'Blizzard: 54 under them, as before')
	OW:CloseDialog()
	theme('thick')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ an idle scroll bar

-- The dialog sizes its scroll frame to its rows exactly (SizeDialog), but the
-- game reads a frame's height back from its layout in single precision: a
-- view laid out 560 tall can come back 559.99994, a sliver short of the 560
-- of rows it holds, and the bar showed, as tall as the view, with nothing to
-- scroll. The stubs lay out in double precision and give 560 back, so the
-- view's read-back is set here by hand.
test("OB.ScrollTo counts what there is to scroll in whole units: a view a hair short of its rows shows no bar, under either look", function()
	local OB = st.OptionsBody
	local parent = CreateFrame('Frame', nil, UIParent)
	parent:SetSize(600, 700)
	parent:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	local scroll = CreateFrame('ScrollFrame', nil, parent)
	scroll:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
	scroll:SetSize(520, 560 - 2 ^ -14) -- 560 as the game's layout hands it back
	local content = CreateFrame('Frame', nil, scroll)
	content:SetSize(520, 560)
	scroll:SetScrollChild(content)
	local bar = OB.ScrollBar(parent, function() end, { narrow = true })
	local companion = OB.Companion(bar)
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		eq(OB.ScrollTo(scroll, bar, 30, 560), 0, look .. ': nothing to scroll to')
		check(not bar:IsShown(), look .. ': no bar')
		check(not companion.frame:IsShown(), look .. ": nor Blizzard's")
		-- A whole unit more is something to scroll.
		eq(OB.ScrollTo(scroll, bar, 30, 561), 1, look .. ': a unit to scroll')
		check(bar:IsShown() or companion.frame:IsShown(), look .. ': its bar')
		eq(bar:IsShown(), look == 'thick', look .. ': the look\'s own bar')
	end
	theme('thick')

	-- The dialog sized to its rows, and the window's page that fits: no bar.
	st.Config:Open('Loot')
	OW:OpenDialog('Fits', DialogTable())
	local d = OW.GetDialogFrames()
	eq(d.scroll:GetHeight(), d.height, 'the view is the rows')
	check(not d.bar:IsShown(), "the dialog's: none")
	check(not frames().bar:IsShown(), "the window's: none")
	OW:CloseDialog()
	close_all()
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
