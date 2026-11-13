-- SaftUI-Core/Config/optionstypes.lua and optionskeybinding.lua: the input,
-- color, execute, keybinding and description widgets, with the input's, the
-- color's and the keybinding's art under SaftUI's theme Blizzard.
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua, with a real
-- AceConfigRegistry-3.0). Synthetic AceConfig option tables stand for the
-- options. The mouse and the keyboard are played by firing the frames' scripts
-- (stub.fire_script), and the color picker by stub.pick_color and friends
-- (tests/wow/blizzard.lua). The world and the helpers are
-- options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
local W = st.OptionsWidgets
local bind, opt, range, click, no = H.bind, H.opt, H.range, H.click, H.no
local yes, text_of, check_no_box, check_box, parent = H.yes, H.text_of, H.check_no_box, H.check_box, H.parent
local atlas_piece, art_inside, rebind, theme, insets = H.atlas_piece, H.art_inside, H.rebind, H.theme, H.insets
local INPUT_ART, atlases_of, size_of, shown_textures = H.INPUT_ART, H.atlases_of, H.size_of, H.shown_textures

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

-- A texture's eight corners as text, rounded so float drift doesn't decide a
-- check; corners(l, r, t, b) is what SetTexCoord(l, r, t, b) gives back.
local function coords_of(texture)
	local out = {}
	for i, v in ipairs({ texture:GetTexCoord() }) do out[i] = string.format('%.4f', v) end
	return table.concat(out, ',')
end
local function corners(l, r, t, b)
	local out = {}
	for i, v in ipairs({ l, t, l, b, r, t, r, b }) do out[i] = string.format('%.4f', v) end
	return table.concat(out, ',')
end
local ICON = 'Interface\\Icons\\Spell_Nature_Lightning'

-- A description bound, placed so its parts have a rect, and given its width
-- as the window does (a pooled one keeps its last).
local function placed_description(key, option)
	local w, told, root, row = bind('description', key, option)
	w:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	w:SetWidth(400)
	return w, told, root, row
end

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

test('color: the bar shows the color and opens the picker on it', function()
	local w = color_widget({ hasAlpha = true })
	eq(w:GetWidth(), 170, 'bar width')
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

test('color: the bar is a dropdown\'s size', function()
	local w = color_widget()
	local d = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A' }, get = function() return 'a' end, set = function() end,
	}))
	eq(size_of(w.frame), size_of(d.frame), 'the select\'s width and height')
	eq(size_of(w.frame), '170x24')
	eq(w:GetWidth(), W.WIDTH.select, 'W.WIDTH.color is the select\'s')
	d:Release()
	w:Release()
end)

test('color: the bar reads the color\'s hex code in capitals, channels rounded', function()
	local function text(r, g, b)
		local w = color_widget({ value = { r, g, b, 1 } })
		local out = w.text:GetText()
		w:Release()
		return out
	end
	eq(text(1, 1, 1), '#FFFFFF', 'white')
	eq(text(0, 0, 0), '#000000', 'black')
	eq(text(1, 0.5, 0), '#FF8000', '0.5 rounds to 128 (0x80)')
	eq(text(0.2, 0.4, 0.6), '#336699', 'a color of whole bytes')
	eq(text(0.999, 0.001, 0.7), '#FF00B3', 'rounded, not cut')
	eq(text(0.6666, 0.1, 0.9), '#AA1AE6', 'letters in capitals')
end)

test('color: black text on a light color, white on a dark one', function()
	local function ink(r, g, b)
		local w = color_widget({ value = { r, g, b, 1 } })
		local tr, tg, tb = w.text:GetTextColor()
		w:Release()
		return tr .. ',' .. tg .. ',' .. tb
	end
	eq(ink(1, 1, 1), '0,0,0', 'white fill')
	eq(ink(1, 1, 0), '0,0,0', 'yellow')
	eq(ink(0, 1, 0), '0,0,0', 'green')
	eq(ink(0, 0, 0), '1,1,1', 'black fill')
	eq(ink(1, 0, 0), '1,1,1', 'red')
	eq(ink(0, 0, 1), '1,1,1', 'blue')
	eq(ink(0.5, 0.5, 0.5), '1,1,1', 'mid grey, on the dark side of the cut')
	eq(ink(0.51, 0.51, 0.51), '0,0,0', 'just over it')
end)

test('color: the ink reads on what the bar shows, the fill at its opacity over the black line', function()
	local function ink(hasAlpha, r, g, b, a)
		local w = color_widget({ hasAlpha = hasAlpha, value = { r, g, b, a } })
		local tr, tg, tb = w.text:GetTextColor()
		w:Release()
		return tr .. ',' .. tg .. ',' .. tb
	end
	eq(ink(true, 1, 1, 1, 1), '0,0,0', 'white, solid')
	eq(ink(true, 1, 1, 1, 0.3), '1,1,1', 'white at 30% shows dark grey')
	eq(ink(false, 1, 1, 1, 0.3), '0,0,0', 'no hasAlpha: drawn solid')
	eq(ink(false, 1, 0.5, 0), '0,0,0', 'orange: red counts for more than blue')
end)

test('color: the fill sits over the black line and under the code, which is centred; a disabled bar takes no mouse', function()
	local w = color_widget()
	local fl, fs = w.swatch:GetDrawLayer()
	local ll, ls = w.inner:GetDrawLayer()
	eq(fl .. fs, 'ARTWORK1', 'the fill')
	eq(ll .. ls, 'ARTWORK0', 'the black line, under it')
	eq((w.text:GetDrawLayer()), 'OVERLAY', 'the code, over both')
	local point, rel, relPoint = w.text:GetPoint(1)
	eq(point .. relPoint, 'CENTERCENTER', 'the code in the middle')
	check(rel == w.frame, 'of the bar')
	w:SetDisabled(true)
	eq(w.frame:IsMouseEnabled(), false, 'disabled: no mouse, so the row shows its tooltip')
	w:SetDisabled(false)
	eq(w.frame:IsMouseEnabled(), true, 'enabled: the mouse again')
	w:Release()
end)

test('color: the opacity shows only with hasAlpha and under 100%', function()
	local function text(hasAlpha, a)
		local w = color_widget({ hasAlpha = hasAlpha, value = { 1, 0, 0, a } })
		local out = w.text:GetText()
		w:Release()
		return out
	end
	local dot = ' \194\183 '
	eq(text(true, 0.6), '#FF0000' .. dot .. '60%', 'hasAlpha, 60%')
	eq(text(true, 0.555), '#FF0000' .. dot .. '56%', 'a whole percent, rounded')
	eq(text(true, 1), '#FF0000', 'hasAlpha at 100%')
	eq(text(true, 0.999), '#FF0000', '99.9% rounds to 100%')
	eq(text(true, 0), '#FF0000' .. dot .. '0%', 'fully clear')
	eq(text(false, 0.6), '#FF0000', 'no hasAlpha: the code alone')
end)

test('color: the text and the fill follow the picker, and Cancel puts them back', function()
	local w = color_widget({ hasAlpha = true, value = { 0, 0, 0, 1 } })
	click(w.frame)
	eq(w.text:GetText(), '#000000')
	stub.pick_color(1, 1, 1, 0.8)
	eq(w.text:GetText(), '#FFFFFF \194\183 80%', 'the new code and opacity')
	local tr, tg, tb = w.text:GetTextColor()
	eq(tr .. ',' .. tg .. ',' .. tb, '0,0,0', 'black ink on the white now')
	-- SetColorTexture records the fill in the stub's color_texture (GetVertexColor stays 1,1,1).
	local function fill()
		local c = stub.state(w.swatch).color_texture
		return string.format('%.1f,%.1f,%.1f,%.1f', c[1], c[2], c[3], c[4])
	end
	eq(fill(), '1.0,1.0,1.0,0.8', 'the fill is white at 80%')
	stub.color_picker_cancel()
	eq(fill(), '0.0,0.0,0.0,1.0', 'Cancel: the old fill')
	eq(w.text:GetText(), '#000000', 'Cancel: the old code')
	tr, tg, tb = w.text:GetTextColor()
	eq(tr .. ',' .. tg .. ',' .. tb, '1,1,1', 'white ink again')
	w:Release()
end)

test('color: a click anywhere on the bar opens the picker; a disabled bar does not', function()
	local w = color_widget()
	w:SetDisabled(true)
	click(w.frame)
	check(not ColorPickerFrame:IsShown(), 'disabled: no picker')
	w:SetDisabled(false)
	click(w.frame)
	check(ColorPickerFrame:IsShown(), 'enabled: the picker opens')
	stub.color_picker_cancel()
	w:Release()
end)

test('color: the bar draws under Thick, Thin and Blizzard, and a look change redraws it', function()
	local w = color_widget({ value = { 1, 0.5, 0, 1 } })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	for _, name in ipairs({ 'thick', 'blizzard', 'thin', 'blizzard', 'thick' }) do
		theme(name)
		rebind(w)
		if name == 'blizzard' then check_no_box(w.frame, name) else check_box(w.frame, name) end
		eq(size_of(w.frame), '170x24', name .. ': the same bar')
		eq(w.text:GetText(), '#FF8000', name .. ': the code')
		check(w.text:IsShown(), name .. ': shown')
	end
	w:Release()
	eq(#take_errors(), 0, 'no errors')
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

test('description: an image sits at its left inside its border, the text to its right, and the height covers both', function()
	local w = placed_description('pic', opt('description', 'Words', { image = ICON, imageWidth = 36, imageHeight = 36 }))
	local lineHeight = math.floor(15 * 1.3)
	-- The image's border (SaftUI's theme, Thick here) lies outside it, so the
	-- image sits the border's width in from the row's corner: the row's edge
	-- is the scroll area's, which would cut a border drawn past it.
	local border = SaftUI:ThemeInset('theme', 'theme', 'action')
	eq(border, 2, "Thick's 2px border")
	local box = 36 + 2 * border
	check(w.image:IsShown(), 'the image shows')
	eq(w.image:GetTexture(), ICON, 'its texture')
	eq(w.image:GetWidth() .. 'x' .. w.image:GetHeight(), '36x36', 'imageWidth by imageHeight')
	eq(coords_of(w.image), corners(0, 1, 0, 1), 'the whole texture with no imageCoords')
	eq(w.image:GetLeft(), w.frame:GetLeft() + border, 'at the left of the row, inside its border')
	eq(w.image:GetTop(), w.frame:GetTop() - border, 'and its top')
	eq(w.text:GetLeft(), w.image:GetRight() + border + 8, 'the text 8 right of the border')
	eq(w.text:GetRight(), w.frame:GetRight(), 'to the row\'s right edge')
	eq(w:GetHeight(), box, 'the row is as tall as the image and its border, taller than the text')
	eq(w.text:GetHeight(), lineHeight, 'one line of text')
	eq(w.text:GetTop(), w.frame:GetTop() - math.floor((box - lineHeight) / 2), 'the line is in the middle of the bordered image')

	-- Narrow enough to wrap to three lines, the text is the taller.
	local one = w:GetHeight()
	w:SetWidth(box + 8 + 10 + 1)
	check(w.text:GetHeight() > box, 'many lines')
	eq(w:GetHeight(), w.text:GetHeight(), 'the row covers the text then')
	eq(w.text:GetTop(), w.frame:GetTop(), 'from the top')
	check(w:GetHeight() > one, 'taller than the image alone')
	w:Release()

	-- No text: just the image and its border.
	w = placed_description('bare', opt('description', '', { image = ICON, imageWidth = 36, imageHeight = 36 }))
	eq(w:GetHeight(), box, 'no text: as tall as the image and its border')
	w:Release()

	-- No image: the text from the row's left, and no room kept for a border.
	w = placed_description('words', opt('description', 'Words'))
	eq(w.text:GetLeft(), w.frame:GetLeft(), 'no image: the text at the left')
	eq(w:GetHeight(), lineHeight, 'as tall as the text')
	w:Release()
end)

test('description: imageCoords, a table of 4 or 8 numbers or a function giving one, crop the image', function()
	local w = placed_description('four', opt('description', 'x', { image = ICON, imageCoords = { 0.1, 0.9, 0.2, 0.8 } }))
	eq(coords_of(w.image), corners(0.1, 0.9, 0.2, 0.8), 'left, right, top, bottom')
	w:Release()
	w = placed_description('eight', opt('description', 'x', { image = ICON, imageCoords = { 0, 0, 0, 1, 1, 0, 1, 1 } }))
	eq(coords_of(w.image), corners(0, 1, 0, 1), 'the eight corners')
	w:Release()
	w = placed_description('three', opt('description', 'x', { image = ICON, imageCoords = { 0.1, 0.9, 0.2 } }))
	eq(coords_of(w.image), corners(0, 1, 0, 1), 'any other count: the whole texture, as AceGUI\'s label')
	w:Release()

	-- A function is called with an info table, on each Refresh.
	local trim, calls, seen = 0.1, 0, nil
	w = placed_description('fn', opt('description', 'x', {
		image = ICON,
		imageCoords = function(info)
			calls, seen = calls + 1, info[#info]
			return { trim, 1 - trim, trim, 1 - trim }
		end,
	}))
	eq(coords_of(w.image), corners(0.1, 0.9, 0.1, 0.9), 'what the function gives')
	eq(seen, 'fn', 'called with an info table for the row')
	trim = 0.2
	w:Refresh()
	eq(coords_of(w.image), corners(0.2, 0.8, 0.2, 0.8), 'read again on a Refresh')
	eq(calls, 2, 'once per Refresh')
	w:Release()

	-- A reused widget with no imageCoords shows the whole texture again.
	w = placed_description('plain', opt('description', 'x', { image = ICON }))
	eq(coords_of(w.image), corners(0, 1, 0, 1), 'no imageCoords on the next row: the whole texture')
	w:Release()
end)

test('description: image may be a fileID, or a function giving the texture, width and height; 32 square by default', function()
	local w = placed_description('id', opt('description', 'x', { image = 136048 }))
	eq(w.image:GetTexture(), 136048, 'a fileID')
	eq(w.image:GetWidth() .. 'x' .. w.image:GetHeight(), '32x32', 'no imageWidth or imageHeight: 32 by 32')
	w:Release()
	w = placed_description('fn', opt('description', 'x', {
		image = function() return ICON, 20, 24 end,
		imageWidth = 50, imageHeight = 50,
	}))
	eq(w.image:GetTexture(), ICON, "the function's texture")
	eq(w.image:GetWidth() .. 'x' .. w.image:GetHeight(), '20x24', "its width and height win over imageWidth and imageHeight")
	w:Release()
	w = placed_description('half', opt('description', 'x', { image = function() return ICON end, imageWidth = 40 }))
	eq(w.image:GetWidth() .. 'x' .. w.image:GetHeight(), '40x32', 'or imageWidth and imageHeight fill in')
	w:Release()
end)

test('description: no image, or one that is not a path or fileID, draws none and keeps the text at the left', function()
	local plain = placed_description('plain', opt('description', 'Some words about it.'))
	local plainHeight = plain:GetHeight()
	plain:Release()
	for _, image in ipairs({ false, true, {} }) do
		local w = placed_description('odd', opt('description', 'Some words about it.', { image = image or nil, imageWidth = 36, imageHeight = 36 }))
		check(not w.image:IsShown(), tostring(image) .. ': no image')
		eq(w.text:GetLeft(), w.frame:GetLeft(), tostring(image) .. ': the text at the left')
		eq(w:GetHeight(), plainHeight, tostring(image) .. ': as tall as the text')
		w:Release()
	end
	-- A widget reused after an image row shows none.
	local pic = placed_description('pic', opt('description', 'x', { image = ICON }))
	pic:Release()
	local w = placed_description('after', opt('description', 'Some words about it.'))
	check(w == pic, 'the same widget, reused')
	check(not w.image:IsShown(), 'no image')
	eq(w.text:GetLeft(), w.frame:GetLeft(), 'the text back at the left')
	eq(w:GetHeight(), plainHeight, 'and the height the text alone')
	w:Release()
end)

test("description: justifyH (SaftUI's) sets its text CENTER or RIGHT across the row; anything else, or none, LEFT", function()
	local cases = { { 'CENTER', 'CENTER' }, { 'RIGHT', 'RIGHT' }, { 'LEFT', 'LEFT' }, { 'middle', 'LEFT' }, { false, 'LEFT' } }
	for _, case in ipairs(cases) do
		local w = placed_description('line', opt('description', 'Sourced from elsewhere', { justifyH = case[1] or nil }))
		eq(w.text:GetJustifyH(), case[2], tostring(case[1]) .. ': ' .. case[2])
		eq(w.text:GetLeft() .. '-' .. w.text:GetRight(), w.frame:GetLeft() .. '-' .. w.frame:GetRight(),
			tostring(case[1]) .. ': the text spans the row, so it sits by its justify')
		w:Release()
	end
	-- A pooled one reused after a centred row is LEFT again.
	local centred = placed_description('a', opt('description', 'x', { justifyH = 'CENTER' }))
	centred:Release()
	local w = placed_description('b', opt('description', 'x'))
	check(w == centred, 'the same widget')
	eq(w.text:GetJustifyH(), 'LEFT', 'LEFT again')
	w:Release()
end)

test('description: SetHeight (a fill row, optionsbody.lua) makes it that tall with its text in the middle; a release forgets it', function()
	local w = placed_description('line', opt('description', 'Sourced from elsewhere', { justifyH = 'CENTER', fill = true }))
	local lineHeight = math.floor(15 * 1.3)
	eq(w:GetHeight(), lineHeight, 'one line before it is told a height')
	eq(w.text:GetTop(), w.frame:GetTop(), 'from the top')
	w:SetHeight(200)
	eq(w:GetHeight(), 200, 'as tall as it is told')
	eq(w.text:GetHeight(), lineHeight, 'the text still one line')
	eq(w.text:GetTop(), w.frame:GetTop() - math.floor((200 - lineHeight) / 2), 'in the middle of it')
	w:SetWidth(300)
	eq(w:GetHeight(), 200, 'a new width keeps the height')
	w:Refresh()
	eq(w:GetHeight(), 200, 'and so does reading the row again (the window, mid-drag)')
	eq(w.text:GetTop(), w.frame:GetTop() - math.floor((200 - lineHeight) / 2), 'the text still in the middle')
	w:SetHeight(5)
	eq(w:GetHeight(), lineHeight, 'never shorter than its text')
	eq(w.text:GetTop(), w.frame:GetTop(), 'which starts at the top then')
	w:SetHeight(200)
	w:Release()
	local again = placed_description('next', opt('description', 'Sourced from elsewhere'))
	check(again == w, 'the same widget')
	eq(again:GetHeight(), lineHeight, 'reused: as tall as its text')
	eq(again.text:GetTop(), again.frame:GetTop(), 'from the top')
	again:Release()
end)

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test("an input carries InputBoxTemplate's art", function()
	theme('blizzard')
	local w = bind('input', 'name', opt('input', 'Name', { get = function() return 'x' end, set = function() end }))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local edit = w.frame
	check_no_box(edit, 'Blizzard')
	eq(atlases_of(edit), INPUT_ART, "InputBoxTemplate's left, middle and right")
	art_inside(edit, 'the input')
	eq(size_of(edit), '170x24', 'it keeps its size')
	local left, right = atlas_piece(edit, 'auctionhouse-ui-inputfield-left'), atlas_piece(edit, 'auctionhouse-ui-inputfield-right')
	eq(insets(left, edit):match('^0,0,%d+,0$') ~= nil, true, 'the left end on its left edge, its full height')
	eq(insets(right, edit):match('^%d+,0,0,0$') ~= nil, true, 'the right end on its right edge')
	eq(left:GetWidth(), math.floor(left:GetWidth()), 'an end is whole pixels wide')
	-- A small input: the window sets its width after binding it.
	edit:SetWidth(60)
	art_inside(edit, 'a small input')
	eq(insets(atlas_piece(edit, 'auctionhouse-ui-inputfield-right'), edit):match(',0,0,0$') ~= nil, true, 'the right end follows')
	edit:SetWidth(170)

	theme('thick')
	rebind(w)
	eq(atlases_of(edit), '', 'Thick: no Blizzard art')
	check_box(edit, 'Thick')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test("a color is Blizzard's swatch, stretched to a bar", function()
	theme('blizzard')
	local w = bind('color', 'tint', opt('color', 'Tint', { get = function() return 1, 0.5, 0, 1 end, set = function() end }))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local button = w.frame
	-- Each shown square, as 'insets=r,g,b' (the stub keeps a color texture's color).
	local function squares()
		local out = {}
		for _, region in ipairs(shown_textures(button)) do
			local c = stub.state(region).color_texture
			if c then
				out[#out + 1] = insets(region, button) .. '=' .. string.format('%.1f,%.1f,%.1f', c[1], c[2], c[3])
			end
		end
		table.sort(out)
		return table.concat(out, ' ')
	end
	check_no_box(button, 'Blizzard')
	eq(squares(), '0,0,0,0=1.0,1.0,1.0 1,1,1,1=0.0,0.0,0.0 2,2,2,2=1.0,0.5,0.0',
		'white the whole bar, black a pixel in, the color a pixel in again')
	eq(size_of(button), '170x24', "a dropdown's size")

	theme('thick')
	rebind(w)
	check_box(button, 'Thick')
	eq(squares(), '1,1,1,1=0.0,0.0,0.0 2,2,2,2=1.0,0.5,0.0', 'Thick: the black line and the color, as before')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test("a keybinding is Blizzard's binding button, its select piece shown while it waits for a key", function()
	theme('blizzard')
	local key
	local w = bind('keybinding', 'kb', opt('keybinding', 'Key', {
		get = function() return key end, set = function(_, v) key = v end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local button = w.frame
	-- The shown pieces by file, as 'file=count', and the HIGHLIGHT layer's.
	local function files(layer)
		local count, out = {}, {}
		for _, region in ipairs(shown_textures(button)) do
			local file = region:GetTexture()
			local inLayer = select(1, region:GetDrawLayer()) == 'HIGHLIGHT'
			if type(file) == 'string' and (layer == 'HIGHLIGHT') == inLayer then
				local name = file:match('UI%-Silver%-Button%-(%a+)$') or file
				if layer == 'HIGHLIGHT' then name = name .. ' ' .. region:GetBlendMode() end
				count[name] = (count[name] or 0) + 1
			end
		end
		for name, n in pairs(count) do out[#out + 1] = name .. '=' .. n end
		table.sort(out)
		return table.concat(out, ',')
	end
	check_no_box(button, 'Blizzard')
	eq(files(), 'Up=9', 'nine pieces of UI-Silver-Button-Up')
	eq(files('HIGHLIGHT'), 'Highlight ADD=1', 'the highlight, additive, under the mouse')
	art_inside(button, 'the binding button')
	eq(size_of(button), '170x24', 'it keeps its size')
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq(files(), 'Down=9', 'pressed: -Down')
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	eq(files(), 'Up=9', 'let go: -Up')
	click(button, 'LeftButton')
	check(w.waiting, 'waiting for a key')
	eq(files(), 'Select=1,Up=9', 'the select piece while it waits')
	stub.fire_script(button, 'OnKeyDown', 'K')
	eq(key, 'K', 'the key is set')
	eq(files(), 'Up=9', 'and the select piece goes')

	theme('thick')
	rebind(w)
	eq(files(), '', 'Thick: no Blizzard art')
	check_box(button, 'Thick')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)
