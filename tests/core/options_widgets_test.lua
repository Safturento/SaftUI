-- SaftUI-Core/Config/optionswidgets.lua, the widgets SaftUI's options window
-- draws rows with (toggle, range, select, multiselect, input, color, execute,
-- keybinding, description, the confirm dialog), and the close button of
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
	eq(w.frame:GetText(), 'a', 'the box shows the real value again')

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

test('color: without SetupColorPickerAndShow the older fields are used', function()
	-- A Classic-family picker: a frame with the old fields and SetColorRGB, not the new method.
	local old = CreateFrame('Frame', nil, UIParent)
	old:Hide()
	local rgb
	function old:SetColorRGB(r, g, b) rgb = { r, g, b } end
	local real = ColorPickerFrame
	ColorPickerFrame = old
	local w, _, sets = color_widget({ hasAlpha = true })
	click(w.frame)
	ColorPickerFrame = real
	check(old:IsShown(), 'shown')
	eq(rgb[1], 0.2, 'color given')
	eq(old.hasOpacity, true, 'opacity flag')
	eq(old.opacity, 0.8, 'and value')
	eq(type(old.func), 'function', 'func')
	eq(type(old.cancelFunc), 'function', 'cancelFunc')
	eq(old.previousValues.b, 0.6, 'previousValues')
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
	eq(frame.close, close, 'stored as frame.close')
	eq(close:GetWidth(), 24, '24 wide')
	eq(close:GetHeight(), 24, '24 tall')
	eq(st.CLOSE_BUTTON_SIZE[1], 24, 'the constant says so too')
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
	eq(plain:GetWidth(), 24, 'at the new size')
end)

test('CreatePanel builds its header with the new close button', function()
	local panel = st:CreatePanel('Test panel', 200, 100)
	check(panel.close ~= nil, 'the panel has its close button')
	eq(panel.close.icon:GetTexture(), st.textures.close, 'with the X')
	click(panel.close)
	check(not panel:IsShown(), 'and it closes the panel')
end)
