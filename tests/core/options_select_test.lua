-- SaftUI-Core/Config/optionsselect.lua, the select and multiselect widgets: the
-- choices a select shows and picks, its Blizzard dropdown face, its steppers,
-- and the multiselect's boxes and rows; and the check list (W.OpenCheckList),
-- whose case reaches the select list frames the select cases above it opened
-- (W.GetListFrames().catcher is nil until a list has opened); and the check
-- art's size (W.CheckArtSize) and the Blizzard theme's box and rows on a toggle,
-- a multiselect and a check list, whose case counts the multiselect rows the
-- pool kept from the multiselect cases above it (the pooled widget that had
-- three rows still has them, hidden).
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
local click, entries_of, bind, text_of, opt = H.click, H.entries_of, H.bind, H.text_of, H.opt
local parent, make, size_of, shown_textures, around = H.parent, H.make, H.size_of, H.shown_textures, H.around
local theme, atlases_of, rebind, check_no_box, check_box = H.theme, H.atlases_of, H.rebind, H.check_no_box, H.check_box
local atlas_exact, anchor, atlas_piece, insets, check_line = H.atlas_exact, H.anchor, H.atlas_piece, H.insets, H.check_line
local inside = H.inside

local function px(a) return string.format('%d', math.floor(a + 0.5)) end

-- A stepper's texture in layer: its Background (BACKGROUND) or its Icon (ARTWORK).
local function stepper_piece(stepper, layer)
	for _, region in ipairs({ stepper:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:GetDrawLayer() == layer then return region end
	end
end
local function background(stepper) return stepper_piece(stepper, 'BACKGROUND') end
local function icon(stepper) return stepper_piece(stepper, 'ARTWORK') end
local function icon_of(stepper) return icon(stepper):GetAtlas() end

-- A select's face, and its hover arrow's left from the button's (shown or not).
local function face_of(w) return atlas_piece(w.frame, 'common-dropdown-c-button') end
local function arrow_left(w)
	for _, region in ipairs({ w.frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:GetAtlas() == 'common-dropdown-c-button-hover-arrow' then
			return tonumber(px(region:GetLeft() - w.frame:GetLeft()))
		end
	end
end

-- The text's left and right, from the select's sides.
local function text_insets(w)
	return px(w.text:GetLeft() - w.frame:GetLeft()) .. ',' .. px(w.frame:GetRight() - w.text:GetRight())
end

local function hit_rect(frame) return table.concat({ frame:GetHitRectInsets() }, ',') end

------------------------------------------------------------------ select

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

------------------------------------------------------------------ the check list

test('W.OpenCheckList: rows show their marks; a click toggles one and the list stays open; Esc and a click outside close it; ListOwner reports it', function()
	local catcher = W.GetListFrames().catcher -- the select list's, opened above
	local owner = W.Box(st:CreateFrame('Button', nil, UIParent))
	owner:SetSize(170, 24)
	owner:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	local checked, toggled = { b = true }, {}
	local entries = { { key = 'a', label = 'Alpha' }, { key = 'b', label = 'Bravo' }, { key = 'c', label = 'Charlie' } }
	local function open()
		W.OpenCheckList(owner, entries, function(key) return checked[key] end, function(key)
			toggled[#toggled + 1] = key
			checked[key] = not checked[key]
		end)
	end
	local list = W.GetListFrames()
	local function marks()
		local out = {}
		for i = 1, #entries do
			local box = list.rows[i].box
			out[i] = not (box and box:IsShown()) and '?' or box.mark:IsShown() and 'x' or '-'
		end
		return table.concat(out)
	end

	open()
	check(list.catcher == catcher, "it reuses the select list's frames")
	check(list.catcher:IsShown(), 'it opens')
	eq(W.ListOwner(), owner, 'ListOwner reports it')
	eq(table.concat(entries_of(list), ','), 'Alpha,Bravo,Charlie', 'a row per entry, by its label')
	eq(marks(), '-x-', 'each row shows its mark')
	eq(list.rows[2].box:GetChecked(), true, 'its box is checked')
	local _, rel, relPoint = list.rows[1].text:GetPoint(1)
	check(rel == list.rows[1].box and relPoint == 'RIGHT', 'the label comes after the box')

	click(list.rows[1])
	eq(table.concat(toggled, ','), 'a', 'a click calls onToggle with its key')
	eq(marks(), 'xx-', 'and the marks are drawn again')
	check(list.catcher:IsShown(), 'the list stays open')
	eq(W.ListOwner(), owner, 'still its owner')
	click(list.rows[2])
	eq(marks(), 'x--', 'another click, another toggle')

	stub.fire_script(list.catcher, 'OnKeyDown', 'ESCAPE')
	check(not list.catcher:IsShown(), 'Esc closes it')
	eq(W.ListOwner(), nil, 'and ListOwner says so')
	eq(stub.try_click(list.rows[1]), false, 'a closed list takes no click')
	eq(#toggled, 2, "a closed list's row toggles nothing")

	open()
	stub.fire_script(list.catcher, 'OnMouseDown')
	check(not list.catcher:IsShown(), 'a click outside closes it')
	eq(W.ListOwner(), nil, 'nor is it reported')

	open()
	W.CloseList()
	check(not list.catcher:IsShown(), 'and so does W.CloseList')

	-- onToggle that closes the list leaves it closed.
	W.OpenCheckList(owner, entries, function() return false end, function() W.CloseList() end)
	click(list.rows[1])
	check(not list.catcher:IsShown(), 'an onToggle that closes it leaves it closed')

	-- A select list opened after it has no boxes, and a choice still closes it.
	local value = 'a'
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return value end, set = function(_, v) value = v end,
	}))
	click(w.frame)
	check(not list.rows[1].box:IsShown(), "a select's rows have no box")
	local point, relTo, _, x = list.rows[1].text:GetPoint(1)
	check(point == 'LEFT' and relTo == list.rows[1] and x == 8, "and their label is at the row's left again")
	eq(text_of(list.rows[1].text), 'A', 'its own entries')
	click(list.rows[2])
	eq(value, 'b', 'a choice sets')
	check(not list.catcher:IsShown(), 'and closes it')
	w:Release()

	W.OpenCheckList(owner, {}, function() return false end, function() end)
	eq(W.ListOwner(), nil, "an empty check list doesn't open")
end)

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test('W.CheckArtSize: the largest whole size up to 30x29, in proportion, within the row', function()
	eq(table.concat({ W.CheckArtSize(34) }, 'x'), '30x29')
	eq(table.concat({ W.CheckArtSize(29) }, 'x'), '30x29')
	eq(table.concat({ W.CheckArtSize(22) }, 'x'), '23x22')
	eq(table.concat({ W.CheckArtSize(18) }, 'x'), '19x18')
end)

test("under Blizzard a toggle's box is drawn 30x29, a multiselect's and a check list's rows 23x22; no box or row changes size", function()
	local checked = true
	local t = bind('toggle', 'on', opt('toggle', 'On', {
		get = function() return checked end, set = function() end,
	}))
	-- a checked, b not.
	local m = bind('multiselect', 'pick', opt('multiselect', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function(_, key) return key == 'a' end, set = function() end,
	}))
	parent:SetSize(800, 600)
	parent:SetPoint('CENTER')
	t:SetPoint('TOPLEFT', parent, 'TOPLEFT', 40, -50)
	m:SetPoint('TOPLEFT', parent, 'TOPLEFT', 40, -150)
	theme('blizzard'); rebind(t); rebind(m)
	-- Checked, unchecked, and each disabled: the art the same size, in the same place.
	for _, state in ipairs({ { true, false }, { false, false }, { false, true }, { true, true } }) do
		checked = state[1]; rebind(t); t:SetDisabled(state[2])
		local name = (checked and 'checked' or 'unchecked') .. (state[2] and ', disabled' or '')
		eq(t.frame:GetChecked(), checked, name)
		check(#shown_textures(t.frame) > 0, name .. ': the toggle is drawn')
		for _, region in ipairs(shown_textures(t.frame)) do
			eq(size_of(region), '30x29', name); eq(around(region, t.frame), '-12,5,0,-6', name .. ': its right on the box, 5 above')
		end
		eq(size_of(t.frame), '18x18', name); eq(t:GetWidth(), 18, name)
		eq(table.concat({ t.frame:GetHitRectInsets() }, ','), '-12,0,-5,-6', name .. ': a click on the art reaches the box')
	end
	checked = true; t:SetDisabled(false); rebind(t)
	for i, row in ipairs(m.rows) do
		local name = i == 1 and 'the checked row' or 'the unchecked row'
		eq(row.box:GetChecked(), i == 1, name)
		check(#shown_textures(row.box) > 0, name .. ' is drawn')
		for _, region in ipairs(shown_textures(row.box)) do
			eq(size_of(region), '23x22', name); eq(around(region, row.box), '0,2,5,-2', name)
		end
		eq(size_of(row.box), '18x18', name); eq(row:GetHeight(), 22, name)
	end
	-- The row's hover, a texture of its box's own the row's OnEnter shows: the box's art's size.
	local row = m.rows[2]
	stub.fire_script(row, 'OnEnter')
	check(row.hover:IsShown(), 'the hover shows under the mouse')
	eq(size_of(row.hover), '23x22', 'the hover the art size'); eq(around(row.hover, row.box), '0,2,5,-2', 'over the art')
	stub.fire_script(row, 'OnLeave')
	check(not row.hover:IsShown(), 'and goes with it')
	-- W.OpenCheckList's rows: the same 23x22 on an 18 box.
	local owner = W.Box(st:CreateFrame('Button', nil, UIParent))
	owner:SetSize(170, 24)
	owner:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	W.OpenCheckList(owner, { { key = 'a', label = 'Alpha' } }, function() return true end, function() end)
	local box = W.GetListFrames().rows[1].box
	check(#shown_textures(box) > 0, 'a check list row is drawn')
	for _, region in ipairs(shown_textures(box)) do
		eq(size_of(region), '23x22'); eq(around(region, box), '0,2,5,-2')
	end
	eq(size_of(box), '18x18')
	W.CloseList()
	theme('thick'); rebind(t); rebind(m)
	eq(atlases_of(t.frame), '', 'Thick: no art')
	eq(table.concat({ t.frame:GetHitRectInsets() }, ','), '0,0,0,0')
	t:Release(); m:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test("a select is the Settings dropdown: its face follows the mouse, a press and its list", function()
	theme('thick')
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return 'a' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local button = w.frame
	eq(button.text, w.text, "the text is the button's")
	-- The text's left and right, from the button's sides.
	local function insets_of_text()
		return px(w.text:GetLeft() - button:GetLeft()) .. ',' .. px(button:GetRight() - w.text:GetRight())
	end
	eq(atlases_of(button), '', 'Thick: no Blizzard art')
	check_box(button, 'Thick')
	local caret = #shown_textures(button)
	check(caret > 0, 'Thick: the caret')
	eq(insets_of_text(), '8,22', 'Thick: the text clear of the caret')
	eq(w.text:GetJustifyH(), 'LEFT', 'Thick: from the left')

	theme('blizzard'); rebind(w)
	check_no_box(button, 'Blizzard'); eq(size_of(button), '170x24', 'it keeps its size')
	eq(atlases_of(button), 'common-dropdown-c-button', 'the face; no caret, no hover arrow yet')
	local face = atlas_exact(button, 'common-dropdown-c-button')
	eq(face:GetDrawLayer(), 'BACKGROUND', 'under the text')
	-- Its choices fit the stepped face (W.StepperRoom), so the face sits between the steppers.
	eq(around(face, button), '24,7,-23,-7', 'a 7px glow round the face, from 31 to 140')
	eq(w.text:GetJustifyH(), 'CENTER', 'the text centred')
	eq(insets_of_text(), '44,43', 'in 13 from the face')
	local x0, y0 = w.text:GetCenter()
	local function text_offset()
		local x, y = w.text:GetCenter()
		return px(x - x0) .. ',' .. px(y - y0)
	end

	stub.fire_script(button, 'OnEnter')
	eq(face:GetAtlas(), 'common-dropdown-c-button-hover-1', 'under the mouse')
	local arrow = atlas_exact(button, 'common-dropdown-c-button-hover-arrow')
	check(arrow ~= nil and arrow:IsShown(), 'the hover arrow shows')
	eq(size_of(arrow), '12x5', 'at its atlas size')
	eq(arrow:GetDrawLayer(), 'OVERLAY')
	eq(around(arrow, button):match(',(-?%d+)$'), '-5', 'hanging under the face')
	eq(around(arrow, button), '79,-24,-79,-5', 'centred under it, its left on a whole pixel')
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq(face:GetAtlas(), 'common-dropdown-c-button-pressedhover-1', 'pressed under the mouse')
	eq(text_offset(), '2,-1', 'the text pressed in')
	stub.fire_script(button, 'OnLeave')
	eq(face:GetAtlas(), 'common-dropdown-c-button-pressed-1', 'held, the mouse gone')
	check(not arrow:IsShown(), 'no arrow off the button')
	eq(text_offset(), '2,-1', 'still pressed in')
	stub.fire_script(button, 'OnEnter')
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	eq(face:GetAtlas(), 'common-dropdown-c-button-hover-1', 'let go')
	eq(text_offset(), '0,0', 'the text back')
	stub.fire_script(button, 'OnLeave')
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'the mouse gone'); check(not arrow:IsShown(), 'and the arrow')
	click(button)
	check(W.ListOwner() == button, 'the list opened')
	eq(face:GetAtlas(), 'common-dropdown-c-button-open', 'open while its list shows')
	W.CloseList()
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'closed again')
	w:SetDisabled(true)
	eq(face:GetAtlas(), 'common-dropdown-c-button-disabled', 'disabled')
	stub.fire_script(button, 'OnEnter')
	check(not arrow:IsShown(), 'disabled: no arrow under the mouse')
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq(face:GetAtlas(), 'common-dropdown-c-button-disabled', 'disabled: not pressed')
	eq(text_offset(), '0,0', 'disabled: the text not pressed in')
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	stub.fire_script(button, 'OnLeave')
	w:SetDisabled(false)
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'enabled again')

	theme('thick'); rebind(w)
	eq(atlases_of(button), '', 'Thick again: no Blizzard art')
	check_box(button, 'Thick again')
	eq(#shown_textures(button), caret, 'Thick again: the caret')
	eq(insets_of_text(), '8,22', 'Thick again: the text where it was')
	eq(w.text:GetJustifyH(), 'LEFT', 'Thick again: from the left')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test('under Blizzard a select whose choices fit has steppers inside its 170, the face between them', function()
	theme('thick')
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B', c = 'C' }, get = function() return 'b' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local button = w.frame
	local names = { [button] = 'frame', [w.back] = 'back', [w.next] = 'next' }
	eq(w.back:GetObjectType() .. ',' .. w.next:GetObjectType(), 'Button,Button')
	check(w.back:GetParent() == button and w.next:GetParent() == button, "the steppers are the select's own")
	check(not w.back:IsShown() and not w.next:IsShown(), 'Thick: no steppers')
	eq(hit_rect(button), '0,0,0,0', 'Thick: the whole box opens the list')

	theme('blizzard'); rebind(w)
	check(w.back:IsShown() and w.next:IsShown(), 'its choices fit: steppers')
	eq(size_of(button), '170x24', 'the select keeps its size'); eq(w:GetWidth(), 170)
	eq(size_of(w.back), '26x24'); eq(anchor(w.back, names), 'LEFT frame LEFT 0,0')
	eq(size_of(w.next), '26x24'); eq(anchor(w.next, names), 'RIGHT frame RIGHT 0,0')
	local face = face_of(w)
	eq(around(face, button), '24,7,-23,-7', 'the face from 31 to 140')
	eq(arrow_left(w), 79, 'the hover arrow under the face, centred')
	eq(text_insets(w), '44,43', 'the text 13 in from the face')
	eq(hit_rect(button), '31,30,0,0', 'only the face opens the list, as only it lights')
	for _, stepper in ipairs({ w.back, w.next }) do
		local name = names[stepper]
		eq(background(stepper):GetAtlas(), 'common-dropdown-c-button', name .. ': the button art')
		eq(around(background(stepper), stepper), '-7,7,7,-7', name .. ': its glow round it')
		eq(size_of(icon(stepper)), '17x17', name .. ': the icon')
		eq(anchor(icon(stepper), names), 'TOPLEFT ' .. name .. ' TOPLEFT 4,-3', name .. ': the icon at 4,-3')
		check(stepper:IsEnabled(), name .. ': at b, both have a choice to step to')
	end
	eq(icon_of(w.back), 'common-dropdown-icon-back')
	eq(icon_of(w.next), 'common-dropdown-icon-next')

	-- Its states follow the mouse, as the face's do.
	stub.fire_script(w.next, 'OnEnter')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-hover-2', 'under the mouse')
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'the face stays unlit')
	stub.fire_script(w.next, 'OnMouseDown', 'LeftButton')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-pressedhover-2', 'pressed under the mouse')
	eq(anchor(icon(w.next), names), 'TOPLEFT next TOPLEFT 6,-4', 'the icon pressed in 2,-1')
	stub.fire_script(w.next, 'OnLeave')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-pressed-2', 'held, the mouse gone')
	stub.fire_script(w.next, 'OnMouseUp', 'LeftButton')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button', 'let go')
	eq(anchor(icon(w.next), names), 'TOPLEFT next TOPLEFT 4,-3', 'the icon back')

	theme('thick'); rebind(w)
	check(not w.back:IsShown() and not w.next:IsShown(), 'Thick again: no steppers')
	eq(hit_rect(button), '0,0,0,0', 'Thick again: the whole box')
	eq(text_insets(w), '8,22', 'Thick again: the text where it was')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test('a select gets steppers only when its longest choice fits the stepped face; otherwise the Settings face at the full 170', function()
	eq(W.StepperRoom(), 83, '170 less the steppers and their gaps (31 and 30), less the text insets (13 each)')
	theme('thick')
	local values = { a = 'A', b = 'B' }
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = function() return values end, get = function() return 'b' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local button = w.frame
	local char = select(2, W.GetFont():GetFont()) / 2 -- the stub's character: half the font's size wide
	local fits = string.rep('m', math.floor(83 / char))
	values = { a = fits, b = 'B' }; theme('blizzard'); rebind(w)
	check(w:StepsFit(), 'fits')
	check(w.back:IsShown() and w.next:IsShown(), 'the longest choice fits: steppers')
	values = { a = fits .. 'm', b = 'B' }; rebind(w)
	check(not w:StepsFit(), "doesn't fit")
	check(not w.back:IsShown() and not w.next:IsShown(), 'one character more: none')
	eq(around(face_of(w), button), '-7,7,7,-7', 'the face at the full 170')
	eq(arrow_left(w), 79, 'the hover arrow centred on it')
	eq(text_insets(w), '13,13', 'the text 13 in from the full face')
	eq(hit_rect(button), '0,0,0,0', 'the whole face opens the list')
	values = { theme = "Use SaftUI's theme", thick = 'Thick', blizzard = 'Blizzard' }; rebind(w)
	check(not w.back:IsShown(), "a Theme select's choices don't fit")
	values = {}; rebind(w)
	check(w:StepsFit(), 'no choices: nothing to cut')
	w:Release()

	-- A font list (LSM30_Font) never has steppers, decided without measuring:
	-- each name would be set in its own face, loading every font file there is.
	local fonts = { ['Alpha'] = [[Interface\AddOns\X\Alpha.ttf]], ['Beta'] = [[Interface\AddOns\X\Beta.ttf]] }
	local reads = 0
	theme('thick')
	local f = bind('select', 'font', opt('select', 'Font', {
		dialogControl = 'LSM30_Font', values = function() reads = reads + 1; return fonts end,
		get = function() return 'Beta' end, set = function() end,
	}))
	f:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	eq(reads, 1, "Thick: the values read once, for the face's label (a pooled select keeps no steppers)")
	local labelReads = reads
	local measured = 0
	f.measure.SetFont = function(fs, ...) measured = measured + 1; return getmetatable(fs).__index.SetFont(fs, ...) end
	f.measure.SetText = function(fs, ...) measured = measured + 1; return getmetatable(fs).__index.SetText(fs, ...) end
	reads = 0
	theme('blizzard'); rebind(f)
	check(not f.back:IsShown() and not f.next:IsShown(), 'short font names: still no steppers')
	eq(around(face_of(f), f.frame), '-7,7,7,-7', 'the face at the full 170')
	eq(measured, 0, 'no name set in its face, nothing measured')
	eq(reads, labelReads, 'the choices not read for the steppers')
	check(not f:StepsFit(), "asked, a font list's choices don't fit")
	eq(measured, 0, 'still nothing measured')
	f.measure.SetFont, f.measure.SetText = nil, nil
	f:Release()
	theme('thick')
	eq(#take_errors(), 0, 'no errors')
end)

test("a select reads its choices once a bind for its steppers, and a released one forgets them", function()
	theme('thick')
	local reads = 0
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = function() reads = reads + 1; return { a = 'A', b = 'B', c = 'C' } end,
		get = function() return 'b' end, set = function() end,
	}))
	reads = 0; rebind(w)
	local labelReads = reads -- Thick: the face's label only
	theme('blizzard'); rebind(w)
	check(w.back:IsShown(), 'steppers')
	reads = 0; rebind(w)
	eq(reads, labelReads + 1, 'bound again with its steppers shown: the label, and the choices once')
	w:SetDisabled(true); w:SetDisabled(false)
	check(w.back:IsEnabled() and w.next:IsEnabled(), 'enabled again at b')
	w:Release()
	check(not w.stepped, 'released: no steppers remembered')
	theme('thick')
	eq(#take_errors(), 0, 'no errors')
end)

test('a stepper picks the next or previous choice through the same path as a pick, and stops at the ends', function()
	theme('blizzard')
	local stored, validated, sets = 'b', 0, 0
	local valid = true
	local w, told = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B', c = 'C' },
		get = function() return stored end,
		validate = function() validated = validated + 1; return valid or 'Not that one' end,
		set = function(_, v) sets = sets + 1; stored = v end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)

	-- A pick from the list, for the path a step takes.
	click(w.frame)
	click(W.GetListFrames().rows[3])
	eq(stored, 'c', 'the list picks c')
	local pick = { validated = validated, sets = sets, told = told.n }
	stored, validated, sets, told.n = 'b', 0, 0, 0
	rebind(w)

	click(w.next)
	eq(stored, 'c', 'next picks the next choice'); eq(sets, 1, 'set once')
	eq(validated, pick.validated, 'validated as a pick is')
	eq(told.n, pick.told, 'the window told as for a pick'); eq(told.ok, true)
	eq(text_of(w.text), 'C', 'and the face shows it')
	check(not w.next:IsEnabled(), 'at the last choice, next is disabled')
	eq(icon_of(w.next), 'common-dropdown-icon-next-disabled')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-disabled')
	check(w.back:IsEnabled(), 'back is not')
	w:Step(1) -- the game sends a disabled button no click; a step past the end does nothing
	eq(stored, 'c', 'no wrap past the end'); eq(sets, 1)
	click(w.back); click(w.back)
	eq(stored, 'a', 'back twice: a')
	check(not w.back:IsEnabled(), 'at the first choice, back is disabled')
	eq(icon_of(w.back), 'common-dropdown-icon-back-disabled')
	eq(background(w.back):GetAtlas(), 'common-dropdown-c-button-disabled')
	check(w.next:IsEnabled(), 'next is enabled again'); eq(icon_of(w.next), 'common-dropdown-icon-next')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button', 'and unlit')
	w:Step(-1)
	eq(stored, 'a', 'no wrap past the start')

	-- A validate that fails: nothing set, the window told why.
	valid, sets, told.n = false, 0, 0
	click(w.next)
	eq(stored, 'a', 'a failed validate sets nothing'); eq(sets, 0)
	eq(told.n, 1); eq(told.ok, false); eq(told.err, 'Not that one', 'onChanged(false, message)')
	eq(text_of(w.text), 'A', 'the face still shows A')
	valid = true
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test('an action select (get = false, or no get) and one that confirms have no steppers', function()
	theme('blizzard')
	local sets = 0
	local function set() sets = sets + 1 end
	local values = { a = 'A', b = 'B' }
	local cases = {
		-- AceDBOptions' Copy From: no value to show, its set copies a profile.
		{ 'get = false', { values = values, get = false, set = set } },
		{ 'no get', { values = values, set = set } },
		{ 'confirm = true', { values = values, get = function() return 'a' end, set = set, confirm = true } },
		{ 'a confirm function', { values = values, get = function() return 'a' end, set = set, confirm = function() return false end } },
		{ 'a confirm method', { values = values, get = function() return 'a' end, set = set, confirm = 'Ask' },
			{ handler = { Ask = function() return false end } } },
	}
	for _, case in ipairs(cases) do
		local name, fields, groupFields = case[1], case[2], case[3]
		local w = bind('select', 'pick', opt('select', 'Pick', fields), groupFields)
		w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
		check(not w.stepped, name .. ': no steppers')
		check(not w.back:IsShown() and not w.next:IsShown(), name .. ': none shown')
		eq(around(face_of(w), w.frame), '-7,7,7,-7', name .. ': the face at the full 170')
		eq(hit_rect(w.frame), '0,0,0,0', name .. ': the whole face opens the list')
		w:Step(1); w:Step(-1)
		eq(sets, 0, name .. ': a step sets nothing')
		eq(W.ConfirmText(), nil, name .. ': nor asks')
		w:Release()
	end

	-- A confirm inherited from the group counts too.
	local w = bind('select', 'pick', opt('select', 'Pick', { values = values, get = function() return 'a' end, set = set }),
		{ confirm = true })
	check(not w.back:IsShown(), 'an inherited confirm: no steppers')
	w:Release()
	-- A get from the group is a value to step from.
	w = bind('select', 'pick', opt('select', 'Pick', { values = values, set = set }), { get = function() return 'a' end })
	check(w.back:IsShown() and w.next:IsShown(), 'an inherited get: steppers')
	w:Release()
	theme('thick')
	eq(#take_errors(), 0, 'no errors')
end)

test('stepper edge cases', function()
	theme('blizzard')
	local stored = 'gone'
	local function store(_, v) stored = v end

	-- A stored value not among the values: back disabled, next picks the first.
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return stored end, set = store,
	}))
	check(w.back:IsShown(), 'steppers')
	check(not w.back:IsEnabled(), 'no choice: back disabled')
	check(w.next:IsEnabled(), 'no choice: next enabled')
	local back, nextKey = w:StepTargets()
	eq(back, nil, 'no choice to step back to'); eq(nextKey, 'a', 'the first is next')
	click(w.next)
	eq(stored, 'a', 'next picks the first')
	w:Release()

	-- One value: both disabled.
	stored = 'only'
	w = bind('select', 'pick', opt('select', 'Pick', {
		values = { only = 'Only' }, get = function() return stored end, set = store,
	}))
	check(not w.back:IsEnabled() and not w.next:IsEnabled(), 'one value: both disabled')
	w:Step(-1); w:Step(1)
	eq(stored, 'only', 'nothing to step to')
	w:Release()

	-- No values: both disabled.
	w = bind('select', 'pick', opt('select', 'Pick', {
		values = {}, get = function() return nil end, set = store,
	}))
	check(w.back:IsShown(), 'no choices: steppers')
	check(not w.back:IsEnabled() and not w.next:IsEnabled(), 'no choices: both disabled')
	w:Release()

	-- Disabled: both disabled; enabled again, as the value says.
	stored = 'b'
	w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B', c = 'C' }, get = function() return stored end, set = store,
	}))
	w:SetDisabled(true)
	check(not w.back:IsEnabled() and not w.next:IsEnabled(), 'a disabled select: both disabled')
	eq(icon_of(w.back), 'common-dropdown-icon-back-disabled'); eq(icon_of(w.next), 'common-dropdown-icon-next-disabled')
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-disabled')
	w:Step(1)
	eq(stored, 'b', 'a disabled select does not step')
	w:SetDisabled(false)
	check(w.back:IsEnabled() and w.next:IsEnabled(), 'enabled again: at b both')
	eq(icon_of(w.next), 'common-dropdown-icon-next')
	stored = 'c'; rebind(w)
	check(w.back:IsEnabled() and not w.next:IsEnabled(), 'at c: back only')
	w:Release()

	-- A disabled row: both disabled from the bind.
	stored = 'b'
	w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B', c = 'C' }, disabled = true, get = function() return stored end, set = store,
	}))
	check(w:IsDisabled(), 'the row is disabled')
	check(not w.back:IsEnabled() and not w.next:IsEnabled(), 'a disabled row: both disabled')
	w:Release()

	-- A values function that changes between clicks: the order read at the click.
	local values = { a = 'A', b = 'B', c = 'C' }
	stored = 'b'
	w = bind('select', 'pick', opt('select', 'Pick', {
		values = function() return values end, get = function() return stored end, set = store,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	values = { b = 'B', z = 'Z' }
	click(w.next)
	eq(stored, 'z', "next is b's next in the order read at the click")
	values = { b = 'B', m = 'M', z = 'Z' }
	click(w.back)
	eq(stored, 'm', 'and back')

	-- A values function whose longest label grows past the room: steppers at
	-- one bind, none at the next, and back when it shrinks.
	local long = string.rep('m', math.floor(W.StepperRoom() / (select(2, W.GetFont():GetFont()) / 2)) + 1)
	values = { a = 'A', m = 'M' }; rebind(w)
	check(w.back:IsShown() and w.next:IsShown(), 'short: steppers')
	values = { a = 'A', m = long }; rebind(w)
	check(not w.back:IsShown() and not w.next:IsShown(), 'grown past the room: none')
	eq(around(face_of(w), w.frame), '-7,7,7,-7', 'the face at the full width')
	values = { a = 'A', m = 'M' }; rebind(w)
	check(w.back:IsShown() and w.next:IsShown(), 'shrunk again: steppers')
	eq(around(face_of(w), w.frame), '24,7,-23,-7', 'the face between them')

	-- A stepper disabled under the mouse hears no OnLeave (the game sends a
	-- disabled button none): enabled again, it's lit only if the mouse is on it.
	stub.cursor_x, stub.cursor_y = 0, 0
	stored = 'a'; rebind(w)
	stub.fire_script(w.next, 'OnEnter')
	click(w.next)
	eq(stored, 'm'); check(not w.next:IsEnabled(), 'next disabled under the mouse')
	stored = 'a'; rebind(w)
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button', 'enabled again with the mouse elsewhere: unlit')
	local x, y = w.next:GetCenter()
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
	stored = 'm'; rebind(w)
	stored = 'a'; rebind(w)
	eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-hover-2', 'enabled again under the mouse: lit')
	stub.cursor_x, stub.cursor_y = 0, 0
	w:Release()
	theme('thick')
	eq(#take_errors(), 0, 'no errors')
end)

test("a multiselect's box is a 1px line, and its rows are Settings boxes", function()
	theme('thick')
	local w = bind('multiselect', 'pick', opt('multiselect', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function(_, key) return key == 'a' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	eq(w.frame.backdropInfo, nil, 'Thick: no box, as before')
	local thickSize = size_of(w.frame)

	theme('blizzard')
	rebind(w)
	check_line(w.frame, 'Blizzard: the box')
	eq(size_of(w.frame), thickSize, 'it keeps its size')
	for i, row in ipairs({ w.rows[1], w.rows[2] }) do
		eq(atlases_of(row.box):match('checkbox%-minimal') ~= nil, true, 'row ' .. i .. ' is a Settings box')
		check(inside(row.box, w.frame), 'row ' .. i .. "'s box inside the box")
		check(row.box:GetLeft() > w.frame:GetLeft(), "row " .. i .. "'s box clear of the line")
	end
	stub.fire_script(w.rows[2], 'OnEnter')
	local hover = atlas_piece(w.rows[2].box, 'checkbox-minimal')
	local shownHover
	for _, region in ipairs(shown_textures(w.rows[2].box)) do
		if select(1, region:GetDrawLayer()) == 'OVERLAY' and region:GetBlendMode() == 'ADD' then shownHover = region end
	end
	check(shownHover ~= nil and shownHover:GetParent() == w.rows[2].box, "the row's hover is a texture of its box")
	stub.fire_script(w.rows[2], 'OnLeave')
	check(not shownHover:IsShown(), 'and goes with the mouse')
	check(hover ~= nil, 'the box art')

	theme('thick')
	rebind(w)
	eq(w.frame.backdropInfo, nil, 'Thick again: no box')
	eq(size_of(w.frame), thickSize, 'its size')
	eq(insets(w.rows[1].box, w.frame):match('^0,') ~= nil, true, "Thick again: the rows' boxes at its left, as before")
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)
