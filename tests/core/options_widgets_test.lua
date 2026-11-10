-- SaftUI-Core/Config/optionswidgets.lua, the widgets SaftUI's options window
-- draws rows with (toggle, range, select, multiselect, input, color, execute,
-- keybinding, description, position, the confirm dialog), and the close button of
-- SaftUI-Core/panels.lua (st:CreateCloseButton, st:CreateHeader).
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua). Synthetic
-- AceConfig option tables stand for the options. The mouse and the keyboard are
-- played by firing the frames' scripts (stub.fire_script), and the color picker
-- by stub.pick_color and friends (tests/wow/blizzard.lua).

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/skinning.lua') -- st:StripTextures, which a header uses on a button that isn't SaftUI's
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionswidgets.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua') -- the position block's caption font
local OM, W = st.OptionsModel, st.OptionsWidgets

------------------------------------------------------------------ helpers

local function opt(otype, name, fields)
	local option = { type = otype, name = name }
	for key, value in pairs(fields or {}) do option[key] = value end
	return option
end

-- The model's row for option key in a one-page tree, and the tree.
local function make(key, option, groupFields)
	local page = { type = 'group', name = 'Page', args = { [key] = option } }
	for k, v in pairs(groupFields or {}) do page[k] = v end
	local root = { page = page }
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
	error('no row ' .. key)
end

local parent = CreateFrame('Frame', nil, UIParent)

-- A bound widget, with what it told the window.
local function bind(rowType, key, option, groupFields)
	local root, row = make(key, option, groupFields)
	local w = W.Create(parent, rowType)
	local told = { n = 0 }
	w:Bind(root, row, function(ok, err, dragging)
		told.n, told.ok, told.err, told.dragging = told.n + 1, ok, err, dragging
	end)
	return w, told, root, row
end

local function click(frame, ...) stub.fire_script(frame, 'OnClick', ...) end

-- The text a font string shows.
local function text_of(fs) return fs:GetText() end

local function yes() click(W.GetDialogFrames().yes) end
local function no() click(W.GetDialogFrames().no) end

------------------------------------------------------------------ toggle

test('toggle: Bind reads through the model, a click writes through it', function()
	local value, sets = true, {}
	local w, told = bind('toggle', 'on', opt('toggle', 'On', {
		get = function(info) return value end,
		set = function(info, v) sets[#sets + 1] = { info[#info], v }; value = v end,
	}))
	eq(w:GetWidth(), 18, 'checkbox width')
	eq(w.frame:GetChecked(), true, 'checked from get')
	check(w.frame.mark:IsShown(), 'the mark shows')

	click(w.frame)
	eq(#sets, 1, 'one set')
	eq(sets[1][1], 'on', 'info is the option path')
	eq(sets[1][2], false, 'the value flipped')
	eq(told.ok, true, 'onChanged(true)')
	eq(told.n, 1, 'told once')
	eq(w.frame:GetChecked(), false, 'now unchecked')
	check(not w.frame.mark:IsShown(), 'the mark is gone')

	click(w.frame)
	eq(value, true, 'and back')
	w:Release()
end)

test('a disabled widget ignores clicks', function()
	local sets = 0
	local w, told = bind('toggle', 'on', opt('toggle', 'On', {
		get = function() return false end,
		set = function() sets = sets + 1 end,
		disabled = true,
	}))
	check(w:IsDisabled(), 'disabled from the row')
	click(w.frame)
	eq(sets, 0, 'nothing set')
	eq(told.n, 0, 'nobody told')
	w:SetDisabled(false)
	click(w.frame)
	eq(sets, 1, 'enabled again')
	w:Release()
end)

------------------------------------------------------------------ validate, confirm, set

test('a change is validated, then confirmed, then set', function()
	local log, value = {}, 'a'
	local w, told = bind('input', 'name', opt('input', 'Name', {
		get = function() return value end,
		validate = function(info, v) log[#log + 1] = 'validate ' .. v; return v ~= 'bad' or 'No bad names' end,
		confirm = function(info, v) log[#log + 1] = 'confirm ' .. v; return v == 'big' and 'Really big?' or false end,
		set = function(info, v) log[#log + 1] = 'set ' .. v; value = v end,
	}))

	-- Invalid: nothing is confirmed or set, and the window is told why.
	w.frame:SetText('bad')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(table.concat(log, ','), 'validate bad', 'validated only')
	eq(told.ok, false, 'told: not ok')
	eq(told.err, 'No bad names', 'with the validate message')
	eq(value, 'a', 'nothing was set')
	eq(w.frame:GetText(), 'bad', 'the box keeps what was typed (AceConfigDialog does)')

	-- No confirm text: validate, then confirm, then set (OM.Set validates once more, as it always does).
	log = {}
	w.frame:SetText('small')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(table.concat(log, ','), 'validate small,confirm small,validate small,set small', 'order')
	eq(told.ok, true, 'ok')

	-- A confirm text asks first; nothing is set until Yes.
	log = {}
	w.frame:SetText('big')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(table.concat(log, ','), 'validate big,confirm big', 'asked, not set')
	log = {}
	eq(W.ConfirmText(), 'Really big?', 'the dialog asks the text')
	no()
	eq(#log, 0, 'No sets nothing')
	eq(value, 'small', 'value unchanged')
	check(not W.GetDialogFrames().catcher:IsShown(), 'dialog closed')

	w.frame:SetText('big')
	stub.fire_script(w.frame, 'OnEnterPressed')
	log = {}
	yes()
	eq(value, 'big', 'Yes sets')
	eq(log[#log], 'set big', 'the set comes after the question')
	eq(told.ok, true, 'told ok after Yes')
	w:Release()
end)

test('an input keeps its typed text and shows the error after a failed validate', function()
	local w, told = bind('input', 'name', opt('input', 'Name', {
		get = function() return 'stored' end,
		validate = function(_, v) return v ~= 'nope' or 'Not that one' end,
		set = function() end,
	}))
	w.frame:SetFocus() -- Enter drops focus first, and the focus loss refreshes the box
	w.frame:SetText('nope')
	stub.fire_script(w.frame, 'OnEnterPressed')
	check(not w.frame:HasFocus(), 'focus dropped')
	eq(w.frame:GetText(), 'nope', 'the typed text survives the focus loss')
	eq(told.ok, false, 'told: not ok')
	eq(told.err, 'Not that one', 'the error shows')
	-- A valid text still commits.
	w.frame:SetText('fine')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(told.ok, true, 'a valid text is set')
	w:Release()
end)

test('a validation pattern on an input fails the same way', function()
	local value, sets = '1', 0
	local w, told = bind('input', 'n', opt('input', 'N', {
		pattern = '^%d+$', usage = 'digits only',
		get = function() return value end,
		set = function(info, v) sets = sets + 1; value = v end,
	}))
	w.frame:SetText('x1')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(sets, 0, 'not set')
	eq(told.ok, false, 'not ok')
	check(told.err:find('digits only', 1, true), 'the usage text is the message')
	w:Release()
end)

------------------------------------------------------------------ range

local function range(fields)
	local value = fields.value
	local sets = {}
	local option = opt('range', 'Amount', {
		min = fields.min, max = fields.max, softMin = fields.softMin, softMax = fields.softMax,
		step = fields.step, bigStep = fields.bigStep, isPercent = fields.isPercent,
		get = function() return value end,
		set = function(info, v) sets[#sets + 1] = v; value = v end,
	})
	local w, told = bind('range', 'amount', option)
	return w, told, sets, function() return value end
end

local function type_into(w, text)
	w.edit:SetText(text)
	stub.fire_script(w.edit, 'OnEnterPressed')
end

test('range: the slider and its value box show the value', function()
	local w = range({ value = 0.25, min = 0, max = 1, step = 0.05 })
	eq(w:GetWidth(), 168, 'a 116 track, a gap of 6 and a 46 box')
	eq(w.slider:GetWidth(), 116, 'track width')
	eq(w.edit:GetWidth(), 46, 'value box width')
	local lo, hi = w.slider:GetMinMaxValues()
	eq(lo, 0, 'slider min')
	eq(hi, 1, 'slider max')
	eq(w.slider:GetValue(), 0.25, 'slider value')
	eq(w.edit:GetText(), '0.25', 'box text')
	w:Release()
end)

test('range: the track is drawn on the slider under its knob, so no frame level can put it over the knob', function()
	local w = range({ value = 0.5, min = 0, max = 1, step = 0.1 })
	-- A frame of its own under the slider went over the knob once reparented.
	check(w.track:IsObjectType('Texture'), 'the track is a texture, not a frame')
	check(w.track:GetParent() == w.slider and w.fill:GetParent() == w.slider, 'the track and fill are the slider\'s')
	eq(w.track:GetDrawLayer(), 'BORDER', 'the track')
	eq(w.fill:GetDrawLayer(), 'ARTWORK', 'the fill over it')
	eq(w.slider:GetThumbTexture():GetDrawLayer(), 'OVERLAY', 'the knob over both')
	eq(w.track:GetWidth(), 116); eq(w.track:GetHeight(), 6)
	w:Release()
end)

test('range: dragging snaps to bigStep, else step', function()
	local w, told, sets, get = range({ value = 0, min = 0, max = 1, step = 0.05, bigStep = 0.1 })
	eq(w.slider:GetValueStep(), 0.1, 'the slider steps by bigStep')
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(0.37)
	eq(sets[#sets], 0.4, 'snapped to the 0.1 grid')
	eq(told.dragging, true, 'the window is told it is mid-drag')
	local n = told.n
	w.slider:SetValue(0.52)
	eq(sets[#sets], 0.5, 'snapped again')
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(told.n, n + 2, 'one more onChanged for the move, one on release')
	eq(told.dragging, nil, 'the release is not mid-drag')
	eq(told.ok, true, 'ok')
	eq(w.edit:GetText(), '0.5', 'the box follows')

	-- With no bigStep the step is it.
	local w2, _, sets2 = range({ value = 0, min = 0, max = 1, step = 0.05 })
	stub.fire_script(w2.slider, 'OnMouseDown')
	w2.slider:SetValue(0.37)
	eq(sets2[#sets2], 0.35, 'snapped to the 0.05 grid')
	stub.fire_script(w2.slider, 'OnMouseUp')
	w:Release()
	w2:Release()
end)

test('range: moving the slider only releases the window after the drag ends', function()
	local w, told = range({ value = 0, min = 0, max = 10, step = 1 })
	stub.fire_script(w.slider, 'OnMouseDown')
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(told.n, 0, 'a click that moved nothing tells nobody')
	w:Release()
end)

test('range: typed numbers snap to step and are cut to the slider ends, then min and max', function()
	-- No soft ends: the box takes min and max.
	local w, told, sets = range({ value = 5, min = 0, max = 100, step = 5 })
	type_into(w, '47')
	eq(sets[#sets], 45, 'snapped to step')
	type_into(w, '250')
	eq(sets[#sets], 100, 'cut to max')
	type_into(w, '-3')
	eq(sets[#sets], 0, 'cut to min')
	type_into(w, 'abc')
	eq(#sets, 3, 'not a number: nothing set')
	eq(w.edit:GetText(), '0', 'and the box shows the value again')
	w:Release()

	-- Soft ends cut a typed number first.
	local s, _, ssets = range({ value = 20, min = 0, max = 1000, softMin = 10, softMax = 50, step = 1 })
	local lo, hi = s.slider:GetMinMaxValues()
	eq(lo, 10, 'the slider runs softMin')
	eq(hi, 50, 'to softMax')
	type_into(s, '200')
	eq(ssets[#ssets], 50, 'cut to softMax')
	type_into(s, '3')
	eq(ssets[#ssets], 10, 'cut to softMin')
	type_into(s, '30')
	eq(ssets[#ssets], 30, 'inside both')
	s:Release()

	-- Only min: the slider has a default max (100), and so does a typed number.
	local d, _, dsets = range({ value = 1, min = 0, step = 1 })
	type_into(d, '500')
	eq(dsets[#dsets], 100, 'AceConfigDialog gives a range with no max one of 100')
	d:Release()
end)

test('range: isPercent shows x% and stores the fraction', function()
	local w, told, sets, get = range({ value = 0.45, min = 0, max = 1, step = 0.01, isPercent = true })
	eq(w.edit:GetText(), '45%', 'shown as a percent')
	type_into(w, '60%')
	eq(sets[#sets], 0.6, 'typed 60% stores 0.6')
	eq(w.edit:GetText(), '60%', 'and shows 60%')
	type_into(w, '25')
	eq(sets[#sets], 0.25, 'the % sign is optional')
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(0.8)
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(get(), 0.8, 'the slider stores the fraction too')
	eq(w.edit:GetText(), '80%', 'shows 80%')
	w:Release()
end)

test('range: a value past the slider ends still shows in the box', function()
	local w = range({ value = 400, min = 0, max = 1000, softMin = 0, softMax = 100 })
	eq(w.slider:GetValue(), 100, 'the slider is at its end')
	eq(w.edit:GetText(), '400', 'the box says what the setting is')
	w:Release()
end)

------------------------------------------------------------------ select

local function entries_of(listFrames)
	local out = {}
	for _, row in ipairs(listFrames.rows) do
		if row:IsShown() then out[#out + 1] = text_of(row.text) end
	end
	return out
end

test('select: the list is values sorted by key (or sorting), the choice sets', function()
	local value, sets = 'b', {}
	local w, told = bind('select', 'pick', opt('select', 'Pick', {
		values = { c = 'Charlie', a = 'Alpha', b = 'Bravo' },
		get = function() return value end,
		set = function(info, v) sets[#sets + 1] = v; value = v end,
	}))
	eq(w:GetWidth(), 170, 'dropdown width')
	eq(text_of(w.text), 'Bravo', 'shows the chosen value')

	click(w.frame)
	local list = W.GetListFrames()
	check(list.catcher:IsShown(), 'the list opens')
	eq(table.concat(entries_of(list), ','), 'Alpha,Bravo,Charlie', 'sorted by key')
	click(list.rows[3])
	eq(sets[1], 'c', 'the choice is set')
	eq(text_of(w.text), 'Charlie', 'and shown')
	check(not list.catcher:IsShown(), 'a choice closes the list')
	eq(told.ok, true, 'ok')
	w:Release()

	local w2 = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'Alpha', b = 'Bravo', c = 'Charlie' }, sorting = { 'c', 'a', 'b' },
		get = function() return 'a' end, set = function() end,
	}))
	click(w2.frame)
	eq(table.concat(entries_of(W.GetListFrames()), ','), 'Charlie,Alpha,Bravo', 'sorting wins')
	W.CloseList()
	w2:Release()
end)

test('select: a values function is read again each time the list opens', function()
	local values = { a = 'One' }
	local calls = 0
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = function() calls = calls + 1; return values end,
		get = function() return 'a' end, set = function() end,
	}))
	click(w.frame)
	eq(table.concat(entries_of(W.GetListFrames()), ','), 'One', 'first open')
	W.CloseList()
	values = { a = 'One', b = 'Two', c = 'Three' }
	click(w.frame)
	eq(table.concat(entries_of(W.GetListFrames()), ','), 'One,Two,Three', 'sees what changed since')
	W.CloseList()
	w:Release()
end)

test('select: the list closes on an outside click, on Esc, and passes other keys on', function()
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return 'a' end, set = function() end,
	}))
	click(w.frame)
	local list = W.GetListFrames()
	check(list.catcher:IsKeyboardEnabled(), 'the list takes the keyboard while open')
	stub.fire_script(list.catcher, 'OnMouseDown')
	check(not list.catcher:IsShown(), 'an outside click closes it')
	check(not list.catcher:IsKeyboardEnabled(), 'and gives the keyboard back')

	click(w.frame)
	stub.fire_script(list.catcher, 'OnKeyDown', 'W')
	check(list.catcher:IsShown(), 'another key leaves it open')
	check(list.catcher:GetPropagateKeyboardInput(), 'and goes on to the game')
	stub.fire_script(list.catcher, 'OnKeyDown', 'ESCAPE')
	check(not list.catcher:IsShown(), 'Esc closes it')
	check(not list.catcher:GetPropagateKeyboardInput(), 'and is not passed on')
	w:Release()
end)

test('select: at most 12 rows show, the rest scroll with the wheel', function()
	local values = {}
	for i = 1, 30 do values[string.format('k%02d', i)] = 'Entry ' .. i end
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = values, get = function() return 'k01' end, set = function() end,
	}))
	click(w.frame)
	local list = W.GetListFrames()
	local shown = entries_of(list)
	eq(#shown, 12, 'twelve rows')
	eq(shown[1], 'Entry 1', 'from the top')
	eq(list.frame:GetHeight(), 12 * 22 + 2, 'twelve rows tall')
	check(list.bar:IsShown(), 'a scroll bar shows')
	stub.fire_script(list.frame, 'OnMouseWheel', -1)
	eq(entries_of(list)[1], 'Entry 4', 'one notch scrolls three rows')
	for _ = 1, 20 do stub.fire_script(list.frame, 'OnMouseWheel', -1) end
	local last = entries_of(list)
	eq(last[#last], 'Entry 30', 'stops at the end')
	for _ = 1, 20 do stub.fire_script(list.frame, 'OnMouseWheel', 1) end
	eq(entries_of(list)[1], 'Entry 1', 'and at the top')
	W.CloseList()
	w:Release()
end)

test('select: the list opens at the chosen entry when it is far down', function()
	local values = {}
	for i = 1, 30 do values[string.format('k%02d', i)] = 'Entry ' .. i end
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = values, get = function() return 'k20' end, set = function() end,
	}))
	click(w.frame)
	local shown = entries_of(W.GetListFrames())
	check(table.concat(shown, ','):find('Entry 20', 1, true), 'the chosen entry is in view')
	W.CloseList()
	w:Release()
end)

test('select: LSM30_Font entries are drawn in their own face', function()
	local w = bind('select', 'font', opt('select', 'Font', {
		dialogControl = 'LSM30_Font',
		values = { ['Alpha Face'] = [[Interface\AddOns\X\Alpha.ttf]], ['Beta Face'] = [[Interface\AddOns\X\Beta.ttf]] },
		get = function() return 'Beta Face' end, set = function() end,
	}))
	eq(text_of(w.text), 'Beta Face', 'the button shows the name')
	eq((w.text:GetFont()), [[Interface\AddOns\X\Beta.ttf]], 'in its face')
	click(w.frame)
	local list = W.GetListFrames()
	eq(table.concat(entries_of(list), ','), 'Alpha Face,Beta Face', 'labeled by name, not path')
	eq((list.rows[1].text:GetFont()), [[Interface\AddOns\X\Alpha.ttf]], 'row 1 in its own face')
	eq((list.rows[2].text:GetFont()), [[Interface\AddOns\X\Beta.ttf]], 'row 2 in its own face')
	W.CloseList()

	-- The same row object drawn for a plain list afterwards uses the field font again.
	local plain = bind('select', 'p', opt('select', 'P', {
		values = { a = 'Plain' }, get = function() return 'a' end, set = function() end,
	}))
	click(plain.frame)
	check(W.GetListFrames().rows[1].text:GetFont() ~= [[Interface\AddOns\X\Alpha.ttf]], 'no stale face')
	W.CloseList()
	w:Release()
	plain:Release()
end)

test('select: a widget reused after a font list shows its value in the field font', function()
	local font = bind('select', 'font', opt('select', 'Font', {
		dialogControl = 'LSM30_Font',
		values = { ['Beta Face'] = [[Interface\AddOns\X\Beta.ttf]] },
		get = function() return 'Beta Face' end, set = function() end,
	}))
	font:Release()
	local plain = bind('select', 'p', opt('select', 'P', {
		values = { a = 'Plain' }, get = function() return 'a' end, set = function() end,
	}))
	check(plain == font, 'the pool hands back the same widget')
	local path, size, flags = W.GetFont():GetFont()
	local p, s, f = plain.text:GetFont()
	eq(p, path, 'the field font face')
	eq(s, size, 'the field font size')
	eq(f, flags, 'the field font outline')
	plain:Release()
end)

test('select: a validation failure keeps the old choice', function()
	local value = 'a'
	local w, told = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return value end,
		validate = function() return 'nope' end, set = function(_, v) value = v end,
	}))
	click(w.frame)
	click(W.GetListFrames().rows[2])
	eq(value, 'a', 'not set')
	eq(told.err, 'nope', 'told why')
	eq(text_of(w.text), 'A', 'still shows A')
	w:Release()
end)

test('select: releasing the widget closes its list', function()
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A' }, get = function() return 'a' end, set = function() end,
	}))
	click(w.frame)
	check(W.GetListFrames().catcher:IsShown(), 'open')
	w:Release()
	check(not W.GetListFrames().catcher:IsShown(), 'closed with it')
end)

------------------------------------------------------------------ multiselect

test('multiselect: get(info, key) and set(info, key, value)', function()
	local state, calls = { a = true, b = false }, {}
	local w, told = bind('multiselect', 'many', opt('multiselect', 'Many', {
		values = { b = 'Beta', a = 'Alpha', c = 'Gamma' },
		get = function(info, key) return state[key] end,
		set = function(info, key, v) calls[#calls + 1] = { key, v }; state[key] = v end,
	}))
	eq(w:GetWidth(), 170, 'width')
	eq(w.frame:GetHeight(), 3 * 22, 'one row per value')
	eq(w.rows[1].box:GetWidth(), 18, 'checkboxes are 18')
	local rows = w.rows
	eq(text_of(rows[1].label), 'Alpha', 'sorted by key')
	eq(rows[1].box:GetChecked(), true, 'a is on')
	eq(rows[2].box:GetChecked(), false, 'b is off')

	click(rows[2])
	eq(#calls, 1, 'one set')
	eq(calls[1][1], 'b', 'the key')
	eq(calls[1][2], true, 'the new state')
	eq(rows[2].box:GetChecked(), true, 'shown on')
	click(rows[1])
	eq(calls[2][1], 'a', 'a')
	eq(calls[2][2], false, 'turned off')
	eq(told.ok, true, 'told ok')
	w:Release()
end)

test('multiselect: a values function that shrinks hides the extra rows on the next bind', function()
	local values = { a = 'A', b = 'B', c = 'C' }
	local root, row = make('m', opt('multiselect', 'M', {
		values = function() return values end, get = function() return false end, set = function() end,
	}))
	local w = W.Create(parent, 'multiselect')
	w:Bind(root, row)
	eq(w.frame:GetHeight(), 66, 'three rows')
	values = { a = 'A' }
	w:Refresh()
	eq(w.frame:GetHeight(), 22, 'one row')
	check(not w.rows[3]:IsShown(), 'the third is hidden')
	w:Release()
end)

------------------------------------------------------------------ input

test('input: Enter sets the text, Esc puts the old text back', function()
	local value, sets = 'old', {}
	local w, told = bind('input', 'text', opt('input', 'Text', {
		get = function() return value end, set = function(_, v) sets[#sets + 1] = v; value = v end,
	}))
	eq(w:GetWidth(), 170, 'text input width')
	eq(w.frame:GetText(), 'old', 'shows the value')
	w.frame:SetText('new')
	stub.fire_script(w.frame, 'OnEscapePressed')
	eq(w.frame:GetText(), 'old', 'Esc reverts')
	eq(#sets, 0, 'sets nothing')
	w.frame:SetText('new')
	stub.fire_script(w.frame, 'OnEnterPressed')
	eq(sets[1], 'new', 'Enter sets')
	eq(told.ok, true, 'ok')
	eq(w.frame:GetText(), 'new', 'shows the set value')
	w:Release()
end)

test('range: a slider reused for a row with no step does not keep the stepped row\'s step', function()
	local a = range({ min = 0, max = 10, step = 2, value = 4 })
	local slider = a.slider
	eq(slider:GetValueStep(), 2, 'the stepped row sets its step')
	a:Release()
	local b = range({ min = 0, max = 1, value = 0.5 })
	check(b.slider == slider, 'the slider was reused')
	eq(b.slider:GetValueStep(), 0, 'no step: not the last row\'s 2 (AceGUI sets step or 0)')
	b:Release()
end)

------------------------------------------------------------------ color

local function color_widget(fields)
	fields = fields or {}
	local value = fields.value or { 0.2, 0.4, 0.6, 0.8 }
	local sets = {}
	local w, told = bind('color', 'tint', opt('color', 'Tint', {
		hasAlpha = fields.hasAlpha,
		get = function() return unpack(value) end,
		set = function(info, r, g, b, a) sets[#sets + 1] = { r, g, b, a }; value = { r, g, b, a } end,
	}))
	return w, told, sets, function() return value end
end

test('color: the swatch shows the color and opens the picker on it', function()
	local w = color_widget({ hasAlpha = true })
	eq(w:GetWidth(), 22, 'swatch width')
	local r, g, b, a = w.swatch:GetVertexColor()
	click(w.frame)
	check(ColorPickerFrame:IsShown(), 'the picker opens')
	local pr, pg, pb = ColorPickerFrame:GetColorRGB()
	eq(pr, 0.2, 'picker r')
	eq(pg, 0.4, 'picker g')
	eq(pb, 0.6, 'picker b')
	eq(ColorPickerFrame:GetColorAlpha(), 0.8, 'picker alpha')
	eq(ColorPickerFrame.hasOpacity, true, 'with an opacity slider')
	stub.color_picker_cancel()
	w:Release()
end)

test('color: the picker opens above the window (FULLSCREEN_DIALOG, over the swatch)', function()
	local window = CreateFrame('Frame', nil, UIParent)
	window:SetFrameStrata('FULLSCREEN_DIALOG')
	window:SetFrameLevel(20)
	local w = color_widget()
	w.frame:SetParent(window)
	w.frame:SetFrameLevel(window:GetFrameLevel() + 3)
	-- Blizzard's picker is DIALOG strata, level 0 (an earlier case may have raised the stub's).
	ColorPickerFrame:SetFrameStrata('DIALOG')
	ColorPickerFrame:SetFrameLevel(1)
	eq(ColorPickerFrame:GetFrameStrata(), 'DIALOG', 'under the window before it opens')
	click(w.frame)
	eq(ColorPickerFrame:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	eq(ColorPickerFrame:GetFrameLevel(), w.frame:GetFrameLevel() + 10, 'level, over the swatch')
	check(ColorPickerFrame:GetFrameLevel() > w.frame:GetFrameLevel(), 'above the swatch')
	stub.color_picker_cancel()
	w:Release()
end)

test('color: opening the picker does not set anything', function()
	-- The picker calls swatchFunc as it opens, with the alpha it still holds
	-- from an earlier use. That is not the user's change.
	stub.set_color_picker_alpha(0.1)
	local w, told, sets = color_widget({ hasAlpha = true })
	click(w.frame)
	eq(#sets, 0, 'no set while it opens')
	eq(told.n, 0, 'nobody told')
	stub.color_picker_cancel()
	eq(#sets, 0, 'cancelling an untouched picker sets nothing either')
	w:Release()
end)

test('color: a pick sets r, g, b and a; Cancel puts the opening color back', function()
	local w, told, sets, get = color_widget({ hasAlpha = true })
	click(w.frame)
	stub.pick_color(0.9, 0.8, 0.7, 0.5)
	eq(#sets, 1, 'one set for one pick')
	eq(sets[1][1], 0.9, 'r')
	eq(sets[1][2], 0.8, 'g')
	eq(sets[1][3], 0.7, 'b')
	eq(sets[1][4], 0.5, 'a')
	eq(told.ok, true, 'ok')
	stub.pick_color(0.1, 0.1, 0.1, 0.5)
	eq(#sets, 2, 'a second pick')
	stub.color_picker_okay()
	eq(#sets, 2, 'Okay repeats the color, which is no change')
	w:Release()

	local c, _, csets, cget = color_widget({ hasAlpha = true })
	click(c.frame)
	stub.pick_color(1, 0, 0, 1)
	stub.color_picker_cancel()
	local r, g, b, a = unpack(cget())
	eq(r, 0.2, 'r restored')
	eq(g, 0.4, 'g restored')
	eq(b, 0.6, 'b restored')
	eq(a, 0.8, 'a restored')
	eq(#csets, 2, 'the pick, then the restore')
	c:Release()
end)

test('color: with no alpha the picker has no opacity and a is 1', function()
	local w, _, sets = color_widget({ hasAlpha = false, value = { 0.2, 0.4, 0.6 } })
	click(w.frame)
	check(not ColorPickerFrame.hasOpacity, 'no opacity slider')
	stub.pick_color(0.5, 0.5, 0.5)
	eq(sets[1][4], 1, 'a passed as 1')
	stub.color_picker_cancel()
	w:Release()
end)

test('color: without SetupColorPickerAndShow the swatch does nothing, and writes nothing onto the picker', function()
	local old = CreateFrame('Frame', nil, UIParent)
	old:Hide()
	local real = ColorPickerFrame
	ColorPickerFrame = old
	local w = color_widget({ hasAlpha = true })
	click(w.frame)
	ColorPickerFrame = real
	check(not old:IsShown(), 'not shown')
	eq(old.func, nil, 'no field written')
	eq(old.hasOpacity, nil, 'none')
	w:Release()
end)

------------------------------------------------------------------ execute

test('execute: runs func; confirm asks first and runs only after Yes', function()
	local ran = 0
	local w, told = bind('execute', 'go', opt('execute', 'Go', { func = function() ran = ran + 1 end }))
	check(w:GetWidth() >= 80, 'at least 80 wide')
	click(w.frame)
	eq(ran, 1, 'runs at once with no confirm')
	eq(told.ok, true, 'told')
	w:Release()

	ran = 0
	local c, ctold = bind('execute', 'wipe', opt('execute', 'Wipe', {
		confirm = true, confirmText = 'Wipe everything?', func = function() ran = ran + 1 end,
	}))
	click(c.frame)
	eq(ran, 0, 'not yet')
	eq(W.ConfirmText(), 'Wipe everything?', 'asks')
	no()
	eq(ran, 0, 'No runs nothing')
	click(c.frame)
	yes()
	eq(ran, 1, 'Yes runs it')
	eq(ctold.ok, true, 'told ok')
	c:Release()
end)

test('execute: an inherited confirm and a method-name func work', function()
	local ran = 0
	local handler = { Run = function(self, info) ran = ran + 1 end }
	local w = bind('execute', 'go', opt('execute', 'Go', { func = 'Run' }), { handler = handler, confirm = true })
	click(w.frame)
	check(W.ConfirmText(), 'the group confirm asks')
	yes()
	eq(ran, 1, 'the handler method ran')
	w:Release()
end)

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
	eq(dy, wy, 'and down')
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
	eq(dy, wy, 'and down')
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

------------------------------------------------------------------ keybinding

test('keybinding: a click waits, the next key (with modifiers) is set, Esc clears', function()
	local value, sets = 'F5', {}
	local w, told = bind('keybinding', 'key', opt('keybinding', 'Key', {
		get = function() return value end, set = function(_, v) sets[#sets + 1] = v; value = v end,
	}))
	eq(w:GetWidth(), 170, 'width')
	eq(text_of(w.text), 'F5', 'shows the key')

	click(w.frame)
	eq(text_of(w.text), 'Press a key', 'waiting')
	check(w.frame:IsKeyboardEnabled(), 'takes the keyboard')
	stub.fire_script(w.frame, 'OnKeyDown', 'LSHIFT')
	eq(#sets, 0, 'a lone modifier is ignored')
	stub.shift_down, stub.ctrl_down = true, true
	stub.fire_script(w.frame, 'OnKeyDown', 'G')
	stub.shift_down, stub.ctrl_down = false, false
	eq(sets[1], 'CTRL-SHIFT-G', 'modifiers in AceGUI order')
	check(not w.frame:IsKeyboardEnabled(), 'keyboard given back')
	eq(text_of(w.text), 'CTRL-SHIFT-G', 'shown')
	eq(told.ok, true, 'told')

	click(w.frame)
	stub.fire_script(w.frame, 'OnKeyDown', 'ESCAPE')
	eq(sets[2], '', 'Esc clears the binding')
	eq(text_of(w.text), 'Not bound', 'shown as unbound')

	click(w.frame)
	stub.fire_script(w.frame, 'OnMouseDown', 'MiddleButton')
	eq(sets[3], 'BUTTON3', 'the middle button')
	click(w.frame)
	stub.fire_script(w.frame, 'OnMouseWheel', 1)
	eq(sets[4], 'MOUSEWHEELUP', 'the wheel')

	click(w.frame)
	click(w.frame)
	check(not w.frame:IsKeyboardEnabled(), 'a second click stops waiting')
	eq(#sets, 4, 'sets nothing')
	w:Release()
end)

------------------------------------------------------------------ description

test('description: fontSize small, medium and large step up from the default', function()
	local sizes = {}
	for _, fs in ipairs({ 'small', 'medium', 'large', false }) do
		local w = bind('description', 'd', opt('description', 'Words', { fontSize = fs or nil }))
		sizes[#sizes + 1] = select(2, w.text:GetFont())
		w:Release()
	end
	check(sizes[2] > sizes[1] and sizes[3] > sizes[2], 'small < medium < large')
	eq(sizes[4], sizes[1], 'no fontSize is small')
end)

test('select: the closed button shows the chosen key\'s label', function()
	local w = bind('select', 'p', opt('select', 'P', {
		values = function() return { a = 'A', b = 'B' } end,
		get = function() return 'b' end, set = function() end,
	}))
	eq(text_of(w.text), 'B', 'label of the chosen key')
	w:Release()
end)

test('description: shows its text, and its height follows the width', function()
	local w = bind('description', 'about', opt('description', 'Some words about it.'))
	eq(w:GetWidth(), 400, 'default width')
	eq(text_of(w.text), 'Some words about it.', 'text')
	local one = w:GetHeight()
	w:SetWidth(60)
	eq(w:GetWidth(), 60, 'the window sets the width')
	check(w:GetHeight() > one, 'a narrower box is taller')
	w:Release()
end)

------------------------------------------------------------------ pooling

test('a released widget is reused for the same type, and only that type', function()
	local a = W.Create(parent, 'toggle')
	local b = W.Create(parent, 'toggle')
	check(a ~= b, 'two live widgets differ')
	a:Release()
	eq(W.Pooled('toggle') >= 1, true, 'in the pool')
	local c = W.Create(parent, 'toggle')
	check(c == a, 'the released one comes back')
	local d = W.Create(parent, 'select')
	check(d ~= a and d ~= b, 'another type is its own')
	b:Release()
	c:Release()
	d:Release()
end)

test('a released widget is hidden, detached and forgets its row', function()
	local sets = 0
	local w = bind('toggle', 'on', opt('toggle', 'On', { get = function() return false end, set = function() sets = sets + 1 end }))
	local frame = w.frame
	w:Release()
	check(not frame:IsShown(), 'hidden')
	eq(frame:GetParent(), nil, 'no parent')
	eq(w.row, nil, 'row dropped')
	click(frame)
	eq(sets, 0, 'a stray click on the released frame sets nothing')
	w:Release() -- twice is harmless
	local count = W.Pooled('toggle')
	w:Release()
	eq(W.Pooled('toggle'), count, 'and does not pool twice')
end)

test('a reused widget shows its new row, not the old one', function()
	local a = bind('toggle', 'on', opt('toggle', 'On', { get = function() return true end, set = function() end }))
	a:Release()
	local root, row = make('off', opt('toggle', 'Off', { get = function() return false end, set = function() end }))
	local b = W.Create(parent, 'toggle')
	b:Bind(root, row)
	check(b == a, 'reused')
	eq(b.frame:GetChecked(), false, 'shows the new value')
	eq(b.frame:GetParent(), parent, 'under its new parent')
	b:Release()
end)

test('every widget type in the brief builds, binds and releases', function()
	local made = {}
	for _, rowType in ipairs({ 'toggle', 'range', 'select', 'multiselect', 'input', 'color', 'execute', 'keybinding', 'description' }) do
		local w = W.Create(parent, rowType)
		check(w.frame ~= nil, rowType .. ' has a frame')
		check(w:GetWidth() > 0, rowType .. ' has a width')
		made[#made + 1] = w
	end
	for _, w in ipairs(made) do w:Release() end
	local ok = pcall(W.Create, parent, 'nonsense')
	check(not ok, 'an unknown type is an error')
end)

------------------------------------------------------------------ the close button

test('CreateCloseButton: the look', function()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(frame)
	eq(st:GetCloseButton(frame), close, 'found with st:GetCloseButton')
	eq(close:GetWidth(), 24, '24 wide')
	eq(close:GetHeight(), 24, '24 tall')
	eq(st.CLOSE_X_BUTTON_SIZE[1], 24, 'the constant says so too')
	eq(st.CLOSE_BUTTON_SIZE[1], 20, 'a Blizzard button keeps its old size constant')
	eq(close.icon:GetTexture(), st.textures.close, 'the close texture')
	check(st.textures.close:find('close.tga', 1, true), 'registered in st.textures')
	local colors = st.config.profile.colors
	local gr, gg, gb = close.icon:GetVertexColor()
	eq(gr, colors.text.grey.r, 'the X is grey')
	eq(gg, colors.text.grey.g, 'grey g')
	eq(gb, colors.text.grey.b, 'grey b')
	local br, bg, bb = close:GetBackdropBorderColor()
	eq(br, 0.3, 'the edge border')
	local fr = close:GetBackdropColor()
	eq(fr, 0.078, 'the field fill')
	check(close.outline ~= nil, 'a dark line outside')
	eq(close.outline:GetBackdropBorderColor(), 0.1, 'in the alt color')
end)

test('CreateCloseButton writes no field onto the frame it is given', function()
	local frame = CreateFrame('Frame', nil, UIParent)
	local before = {}
	for k in pairs(frame) do before[k] = true end
	st:CreateCloseButton(frame)
	for k in pairs(frame) do check(before[k], 'new field on the frame: ' .. tostring(k)) end
end)

test('CreateCloseButton: hover turns red, pressed moves the X down 1px, a click hides the frame', function()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(frame)
	local red = st.config.profile.colors.text.red

	stub.fire_script(close, 'OnEnter')
	local br, bg, bb = close:GetBackdropBorderColor()
	eq(br, red.r, 'border red r')
	eq(bg, red.g, 'border red g')
	eq(bb, red.b, 'border red b')
	local xr, xg = close.icon:GetVertexColor()
	eq(xr, red.r, 'the X is red')
	eq(xg, red.g, 'X g')
	local fr, fg, fb, fa = close:GetBackdropColor()
	eq(fr, 0.5, 'a red fill')
	check(fa > 0 and fa < 1, 'a faint one')

	local _, _, _, _, y0 = close.icon:GetPoint(1)
	stub.fire_script(close, 'OnMouseDown', 'LeftButton')
	local _, _, _, _, y1 = close.icon:GetPoint(1)
	eq(y1, y0 - 1, 'the X moves down 1px')
	stub.fire_script(close, 'OnMouseUp', 'LeftButton')
	local _, _, _, _, y2 = close.icon:GetPoint(1)
	eq(y2, y0, 'and back up')

	stub.fire_script(close, 'OnLeave')
	eq((close:GetBackdropBorderColor()), 0.3, 'the border is back')
	local gr = close.icon:GetVertexColor()
	eq(gr, st.config.profile.colors.text.grey.r, 'the X is grey again')

	check(frame:IsShown(), 'shown before the click')
	click(close, 'LeftButton')
	check(not frame:IsShown(), 'a click hides the frame')
end)

test('CreateHeader: a SaftUI close button keeps its look and sits in the header; a handed-in other button keeps its old one', function()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetSize(300, 200)
	local close = st:CreateCloseButton(frame)
	local header = st:CreateHeader(frame, 'Title')
	eq(frame.close_button, close, 'the header found the frame\'s close button')
	eq(close.backdrop, nil, 'no template backdrop was put over it')
	eq(close:GetWidth(), 24, 'still 24 wide')
	local point, relative = close:GetPoint(1)
	eq(point, 'RIGHT', 'anchored to the header\'s right')
	eq(relative, header, 'to the header')
	eq(close.icon:GetTexture(), st.textures.close, 'the X is still there')

	local other = st:CreateFrame('Frame', nil, UIParent)
	local plain = st:CreateFrame('Button', nil, other)
	st:CreateHeader(other, 'Other', plain)
	check(plain.backdrop ~= nil, 'a button that is not SaftUI\'s is skinned as before')
	eq(plain:GetWidth(), 20, 'at the old size')
	eq(plain:GetHeight(), 10, 'and height')
end)

test('CreatePanel builds its header with the new close button', function()
	local panel = st:CreatePanel('Test panel', 200, 100)
	local close = st:GetCloseButton(panel)
	check(close ~= nil, 'the panel has its close button')
	eq(close.icon:GetTexture(), st.textures.close, 'with the X')
	click(close)
	check(not panel:IsShown(), 'and it closes the panel')
end)

------------------------------------------------------------------ position

-- A position option over a plain table; sets are recorded.
local function position_option(fields, store)
	store = store or { point = 'TOPRIGHT', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -8, frame = 'Minimap' }
	local sets = {}
	local option = opt('position', 'Position', {
		get = function(info, part) return store[part] end,
		set = function(info, part, value) sets[#sets + 1] = part .. '=' .. tostring(value); store[part] = value end,
	})
	for k, v in pairs(fields or {}) do option[k] = v end
	return option, sets, store
end

local function bind_position(fields, store)
	local option, sets, store = position_option(fields, store)
	local w, told = bind('position', 'pos', option)
	return w, told, sets, store
end

local function caption_texts(w)
	local out = {}
	for i, fs in ipairs(w.captions) do out[i] = fs:GetText() end
	return table.concat(out, ',')
end

local function type_into(box, text)
	box:SetText(text)
	stub.fire_script(box, 'OnEnterPressed')
end

local function rgb_text(r, g, b) return string.format('%.3f,%.3f,%.3f', r, g, b) end
local function dot_color(button)
	local c = stub.state(button.dot).color_texture
	return rgb_text(c[1], c[2], c[3])
end

local function picked(dots)
	local out = {}
	for i, dot in ipairs(dots) do
		if dot.picked then out[#out + 1] = i end
	end
	return table.concat(out, ',')
end

test('position: captions read THIS, TO, AT ITS, OFFSET with a name target, and THIS, AT ITS, OFFSET without one', function()
	local w = bind_position({ target = 'name' })
	eq(caption_texts(w), 'THIS,TO,AT ITS,OFFSET', 'with a target')
	w:Release()
	local w2 = bind_position()
	eq(caption_texts(w2), 'THIS,AT ITS,OFFSET', 'without one')
	w2:Release()
end)

test('position: the parts are laid out 12 apart, each caption over its part, on a 48 band', function()
	local w = bind_position({ target = 'name' })
	eq(w:GetWidth(), 48 + 12 + 120 + 12 + 48 + 12 + 79, 'width: dots, name, dots, offset')
	eq(w.frame:GetWidth(), w:GetWidth(), 'the frame is as wide')
	eq(w:GetHeight(), 65, 'a 13 caption, 4, a 48 band')
	local _, _, _, x1 = w.this[1]:GetParent():GetPoint(1)
	local _, _, _, x2 = w.name:GetPoint(1)
	local _, _, _, x3 = w.at[1]:GetParent():GetPoint(1)
	eq(x1, 0, 'THIS starts the block')
	eq(x2, 60, 'TO is 12 after the 48 dots')
	eq(x3, 192, 'AT ITS is 12 after the 120 name box')
	eq(w.this[1]:GetParent():GetWidth(), 48, 'a 48 dot square')
	local _, _, _, dx1 = w.this[1]:GetPoint(1)
	local _, _, _, dx3 = w.this[3]:GetPoint(1)
	eq(dx1, 3, 'the first dot cell starts 3 in (centers at 10/24/38)')
	eq(dx3 + w.this[3]:GetWidth(), 45, 'and the third ends 3 from the far side')
	eq(w.x:GetWidth(), 46, 'a 46 wide X box')
	eq(w.x:GetHeight(), 22, 'which is 22 tall')
	eq(w.xUp:GetWidth(), 14, 'with a 14 wide nudge')
	eq(w.xUp:GetHeight() + w.xDown:GetHeight(), 22, 'pair as tall as the box')
	local pair = w.xUp:GetParent()
	check(w.xDown:GetParent() == pair, 'up and down are halves of one box')
	eq(pair:GetWidth(), 14, 'a 14 wide box')
	eq(pair:GetHeight(), 22, 'as tall as the edit box')
	local _, rel, relPoint, px, py = pair:GetPoint(1)
	check(rel == w.x and relPoint == 'TOPRIGHT', 'on the edit box\'s right edge')
	eq(px, -1, 'overlapping it by 1: one shared seam')
	eq(py, 0)
	local function arrows(button)
		local out = {}
		for i, t in ipairs(button.arrows) do
			local _, _, _, ax, ay = t:GetPoint(1)
			out[i] = ('%d@%d,%d'):format(t:GetWidth(), ax, ay)
			eq(t:GetHeight(), 1)
			eq((14 - t:GetWidth()) % 2, 0, 'arrow ' .. i .. ' is centered on whole pixels')
			eq(ay, math.floor(ay), 'and on a whole row')
		end
		return table.concat(out, ' ')
	end
	eq(arrows(w.xUp), '2@0,-4 4@0,-5 6@0,-6', 'the up arrow: 2/4/6 wide, widest at the base')
	eq(arrows(w.xDown), '6@0,-3 4@0,-4 2@0,-5', 'the down arrow: 6/4/2 wide, widest at the top')
	local divider
	for _, region in ipairs({ pair:GetRegions() }) do
		if region:GetObjectType() == 'Texture' then divider = region end
	end
	check(divider ~= nil, 'one divider')
	eq(divider:GetHeight(), 1, '1px')
	eq(divider:GetWidth(), 12, 'inside the border')
	eq(w.captions[2]:GetWidth(), 120, 'the TO caption spans its part to center on it')
	w:Release()
end)

test('position: the picked dots show the stored points; clicking a dot sets that point', function()
	local w, told, sets, store = bind_position({ target = 'name' })
	eq(#w.this, 9, 'nine dots')
	eq(w.this[1].point, 'TOPLEFT', 'first is TOPLEFT')
	eq(w.this[5].point, 'CENTER', 'fifth is CENTER')
	eq(w.at[9].point, 'BOTTOMRIGHT', 'last is BOTTOMRIGHT')
	eq(picked(w.this), '3', 'THIS: TOPRIGHT is picked')
	eq(picked(w.at), '9', 'AT ITS: BOTTOMRIGHT is picked')
	eq(w.this[3].dot:GetWidth(), 8, 'the picked dot is 8')
	eq(w.this[1].dot:GetWidth(), 4, 'the others are 4')
	local br, bg, bb = st.config.profile.colors.button.blue:GetRGB()
	eq(dot_color(w.this[3]), rgb_text(br, bg, bb), 'the picked dot is the profile blue')
	eq(dot_color(w.this[1]), rgb_text(0.333, 0.333, 0.333), 'the others are #555555')

	click(w.this[2])
	eq(sets[#sets], 'point=TOP', 'clicking a dot sets the point')
	eq(told.ok, true, 'told ok')
	eq(picked(w.this), '2', 'and it is the picked one now')
	click(w.at[5])
	eq(sets[#sets], 'rel_point=CENTER', 'the AT ITS dots set rel_point')
	eq(store.rel_point, 'CENTER', 'stored')

	stub.fire_script(w.this[7], 'OnEnter')
	local tr, tg, tb = st.config.profile.colors.text.normal:GetRGB()
	eq(dot_color(w.this[7]), rgb_text(tr, tg, tb), 'a hovered dot is in the text color')
	stub.fire_script(w.this[7], 'OnLeave')
	eq(dot_color(w.this[7]), rgb_text(0.333, 0.333, 0.333), 'and grey again after')
	w:Release()
end)

test('position: X and Y show the stored offsets, strings included; Enter sets the typed number', function()
	local w, told, sets, store = bind_position(nil, { point = 'TOP', rel_point = 'TOP', x_off = '-6', y_off = nil })
	eq(w.x:GetText(), '-6', 'a string offset shows')
	eq(w.y:GetText(), '0', 'a missing one shows 0')
	type_into(w.y, '12')
	eq(sets[#sets], 'y_off=12', 'Enter sets the number')
	eq(type(store.y_off), 'number', 'as a number')
	eq(w.y:GetText(), '12', 'and shows it')
	type_into(w.x, ' 3.5 ')
	eq(sets[#sets], 'x_off=3.5', 'spaces around the number are fine')
	w:Release()
end)

test('position: text that is not a number reports it, sets nothing and puts the stored value back', function()
	local w, told, sets = bind_position()
	type_into(w.x, 'abc')
	eq(#sets, 0, 'nothing set')
	eq(told.ok, false, 'told: not ok')
	eq(told.err, 'X must be a number', 'with the X message')
	eq(w.x:GetText(), '0', 'the box has the stored value again')
	type_into(w.y, '')
	eq(told.err, 'Y must be a number', 'and the Y message')
	eq(w.y:GetText(), '-8', 'Y is back')
	w:Release()
end)

test('position: Esc and focus loss put a box back to the stored value', function()
	local w, _, sets = bind_position()
	w.x:SetText('99')
	stub.fire_script(w.x, 'OnEscapePressed')
	eq(w.x:GetText(), '0', 'Esc reverts')
	w.y:SetText('77')
	stub.fire_script(w.y, 'OnEditFocusLost')
	eq(w.y:GetText(), '-8', 'losing focus reverts')
	eq(#sets, 0, 'neither sets')
	w:Release()
end)

test('position: nudges move 1, or 10 with Shift, from a string offset too', function()
	local w, _, sets = bind_position(nil, { point = 'TOP', rel_point = 'TOP', x_off = '-6', y_off = -8 })
	click(w.xUp)
	eq(sets[#sets], 'x_off=-5', 'up from a string -6')
	click(w.xDown)
	eq(sets[#sets], 'x_off=-6', 'down')
	stub.shift_down = true
	click(w.yDown)
	stub.shift_down = false
	eq(sets[#sets], 'y_off=-18', 'Shift moves 10')
	eq(w.y:GetText(), '-18', 'the box follows')
	click(w.yUp)
	eq(sets[#sets], 'y_off=-17', 'Y up, 1 without Shift')
	w:Release()
end)

test('position: a name typed and Entered sets frame; a failed validate sets nothing and reports its message', function()
	local w, told, sets = bind_position({
		target = 'name',
		validate = function(info, part, value)
			if part == 'frame' and value == 'Nope' then return "Frame doesn't exist" end
			return true
		end,
	})
	eq(w.name:GetText(), 'Minimap', 'the stored frame shows')
	type_into(w.name, 'Nope')
	eq(#sets, 0, 'nothing set')
	eq(told.ok, false, 'told: not ok')
	eq(told.err, "Frame doesn't exist", 'with the message')
	eq(w.name:GetText(), 'Minimap', 'the stored name is back')
	type_into(w.name, '  UIParent ')
	eq(sets[#sets], 'frame=UIParent', 'a valid trimmed name sets frame')
	eq(told.ok, true, 'told ok')
	w:Release()
end)

test('position: a select target shows the dropdown, and the name box only for nameKey', function()
	local store = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 0, frame = 'PlayerFrame', relative_to = 'Health' }
	local w, told, sets = bind_position({
		target = 'select', nameKey = '__global',
		values = { __unitframe = 'Unit frame', Health = 'Health', __global = 'Global frame' },
	}, store)
	eq(caption_texts(w), 'THIS,TO,AT ITS,OFFSET', 'the TO caption shows')
	eq(w:GetWidth(), 48 + 12 + 140 + 12 + 48 + 12 + 79, 'the TO part is 140 wide')
	check(w.select:IsShown(), 'the dropdown shows')
	eq(w.select.text:GetText(), 'Health', 'with the stored choice')
	check(not w.name:IsShown(), 'no name box for Health')

	click(w.select)
	local list = W.GetListFrames()
	check(list.catcher:IsShown(), 'the list opened')
	local labels = {}
	for i, entry in ipairs(list.entries) do labels[i] = entry.label end
	eq(table.concat(labels, ','), 'Health,Global frame,Unit frame', 'with the values, sorted by key')
	for i, entry in ipairs(list.entries) do
		if entry.key == '__global' then click(list.rows[i]) end
	end
	eq(sets[#sets], 'relative_to=__global', 'picking sets relative_to')
	eq(w.select.text:GetText(), 'Global frame', 'the dropdown follows')
	check(w.name:IsShown(), 'the name box shows for nameKey')
	eq(w.name:GetText(), 'PlayerFrame', 'with the stored frame')
	eq(w.name:GetWidth(), 140, 'a 140 wide name box')
	eq(w.name:GetHeight(), 22, 'on the bottom row')
	local _, _, _, _, y1 = w.select:GetPoint(1)
	local _, _, _, _, y2 = w.name:GetPoint(1)
	eq(y2, y1 - 26, 'the name box is 22 + 4 under the dropdown')

	type_into(w.name, 'UIParent')
	eq(sets[#sets], 'frame=UIParent', 'the name box sets frame')
	w:Release()
end)

test('position: a block reused after a select target has no dropdown, and one reused without a target has no TO part', function()
	local w = bind_position({ target = 'select', nameKey = '__global', values = { __global = 'Global frame' } },
		{ point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 0, relative_to = '__global', frame = 'X' })
	check(w.select:IsShown() and w.name:IsShown(), 'the select shape shows both')
	w:Release()

	local w2 = bind_position({ target = 'name' })
	eq(w2, w, 'the same widget came back from the pool')
	check(not w2.select:IsShown(), 'no dropdown')
	check(w2.name:IsShown(), 'the name box shows')
	eq(w2.name:GetWidth(), 120, 'at 120 again')
	eq(w2.name:GetText(), 'Minimap', 'with this row\'s frame')
	eq(w2:GetWidth(), 331, 'and the block is narrower again')
	w2:Release()

	local w3 = bind_position()
	eq(w3, w, 'the pool again')
	check(not w3.name:IsShown(), 'no name box')
	check(not w3.select:IsShown(), 'no dropdown')
	eq(caption_texts(w3), 'THIS,AT ITS,OFFSET', 'no TO caption')
	check(not w.captionFor.to:IsShown(), 'the TO caption is hidden')
	eq(w3:GetWidth(), 199, 'and 200 wide')
	w3:Release()
end)

test('position: the caption font is the title face at 11, in grey', function()
	local w = bind_position()
	local path, size = w.captions[1]:GetFont()
	local config = st.config.profile.fonts.title
	eq(path, st.LSM:Fetch('font', config.font_name), 'the title face')
	eq(size, 11, 'at 11')
	local r, g, b = w.captions[1]:GetTextColor()
	local gr, gg, gb = st.config.profile.colors.text.grey:GetRGB()
	check(r == gr and g == gg and b == gb, 'grey')
	w:Release()
end)

test('position: the block calls onTip as the mouse enters and leaves its parts', function()
	local w = bind_position({ target = 'name' })
	local log = {}
	w.onTip = function(on) log[#log + 1] = on end
	stub.fire_script(w.this[1], 'OnEnter')
	stub.fire_script(w.this[1], 'OnLeave')
	stub.fire_script(w.x, 'OnEnter')
	eq(#log, 3, 'three calls')
	eq(log[1], true, 'on')
	eq(log[2], false, 'off')
	w:Release()
	eq(w.onTip, nil, 'released: no tip hook left')
end)

test('position: disabled dims the block and ignores clicks and nudges', function()
	local w, told, sets = bind_position({ target = 'name', disabled = true })
	check(w:IsDisabled(), 'disabled from the row')
	eq(w.frame:GetAlpha(), 0.4, 'dimmed')
	click(w.this[1])
	click(w.at[1])
	click(w.xUp)
	click(w.yDown)
	type_into(w.x, '5')
	type_into(w.name, 'Other')
	eq(#sets, 0, 'nothing set')
	eq(told.n, 0, 'nobody told')
	w:SetDisabled(false)
	click(w.xUp)
	eq(sets[#sets], 'x_off=1', 'enabled again')
	w:Release()
end)
