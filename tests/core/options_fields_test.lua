-- SaftUI-Core/Config/optionstypes.lua and optionskeybinding.lua: the input,
-- color, execute, keybinding and description widgets, with the input's, the
-- color's and the keybinding's art under SaftUI's theme Blizzard.
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua, with a real
-- AceConfigRegistry-3.0). Synthetic AceConfig option tables stand for the
-- options. The mouse and the keyboard are played by firing the frames' scripts
-- (stub.fire_script), and the color picker through its own boxes and buttons
-- (options_widgets_helpers.lua's pick_color and friends). The world and the helpers are
-- options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local W = st.OptionsWidgets
local bind, opt, range, click, no = H.bind, H.opt, H.range, H.click, H.no
local yes, text_of, check_no_box, check_box, parent = H.yes, H.text_of, H.check_no_box, H.check_box, H.parent
local pick_color, picker_cancel, picker_okay = H.pick_color, H.color_picker_cancel, H.color_picker_okay
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
	check(W.ColorPickerShown(), 'the picker opens')
	local F = W.GetColorPickerFrames()
	eq(F.red:GetText(), '51', 'picker r')
	eq(F.green:GetText(), '102', 'picker g')
	eq(F.blue:GetText(), '153', 'picker b')
	eq(F.opacity:GetText(), '80%', 'picker opacity')
	check(F.alpha:IsShown(), 'with an opacity strip')
	picker_cancel()
	w:Release()
end)

test('color: the picker opens above the window (FULLSCREEN_DIALOG), beside the swatch', function()
	local window = CreateFrame('Frame', nil, UIParent)
	window:SetFrameStrata('FULLSCREEN_DIALOG')
	window:SetFrameLevel(20)
	local w = color_widget()
	w.frame:SetParent(window)
	w.frame:SetFrameLevel(window:GetFrameLevel() + 3)
	w.frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	click(w.frame)
	local F = W.GetColorPickerFrames()
	eq(F.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	check(F.frame:GetFrameLevel() > window:GetFrameLevel(), 'above the window')
	check(F.frame:GetFrameLevel() > w.frame:GetFrameLevel(), 'above the swatch')
	check(F.frame:GetLeft() > w.frame:GetRight(), 'beside the swatch, not over it')
	picker_cancel()
	w:Release()
end)

test('color: opening the picker does not set anything', function()
	-- The picker never tells a change as it opens, and Cancel on an untouched
	-- picker puts back the color it has: the same, which is no change either.
	local w, told, sets = color_widget({ hasAlpha = true })
	click(w.frame)
	eq(#sets, 0, 'no set while it opens')
	eq(told.n, 0, 'nobody told')
	picker_cancel()
	eq(#sets, 0, 'cancelling an untouched picker sets nothing either')
	w:Release()
end)

test('color: a pick sets r, g, b and a; Cancel puts the opening color back', function()
	local w, told, sets, get = color_widget({ hasAlpha = true })
	click(w.frame)
	pick_color(230 / 255, 204 / 255, 179 / 255, 0.5)
	-- The color first, then the opacity: two changes.
	eq(#sets, 2, 'one set for each change')
	eq(sets[2][1], 230 / 255, 'r')
	eq(sets[2][2], 204 / 255, 'g')
	eq(sets[2][3], 179 / 255, 'b')
	eq(sets[2][4], 0.5, 'a')
	eq(told.ok, true, 'ok')
	pick_color(26 / 255, 26 / 255, 26 / 255, 0.5)
	eq(#sets, 3, 'a second pick')
	picker_okay()
	eq(#sets, 3, 'Okay repeats nothing: the color is set already')
	eq(get()[1], 26 / 255, 'and it stays')
	w:Release()

	local c, _, csets, cget = color_widget({ hasAlpha = true })
	click(c.frame)
	pick_color(1, 0, 0, 1)
	picker_cancel()
	local r, g, b, a = unpack(cget())
	eq(r, 0.2, 'r restored')
	eq(g, 0.4, 'g restored')
	eq(b, 0.6, 'b restored')
	eq(a, 0.8, 'a restored')
	eq(#csets, 3, 'the hex, the opacity, then the restore')
	c:Release()
end)

test('color: with no alpha the picker has no opacity and a is 1', function()
	local w, _, sets = color_widget({ hasAlpha = false, value = { 0.2, 0.4, 0.6 } })
	click(w.frame)
	check(not W.GetColorPickerFrames().alpha:IsShown(), 'no opacity strip')
	check(not W.GetColorPickerFrames().opacity:IsShown(), 'no opacity box')
	pick_color(128 / 255, 128 / 255, 128 / 255)
	eq(sets[1][4], 1, 'a passed as 1')
	picker_cancel()
	w:Release()
end)

test('color: a field rebound to another row closes the picker, the old row gets its opening color, the new one nothing', function()
	local w, _, sets, get = color_widget({ hasAlpha = true })
	click(w.frame)
	pick_color(1, 0, 0)
	local written = false
	-- The window drew another page: the same widget is bound to another row.
	local other = opt('color', 'Other', { get = function() return 0, 0, 0, 1 end, set = function() written = true end })
	local root, row = H.make('other', other)
	w:Bind(root, row, function() end)
	check(not W.ColorPickerShown(), 'the picker is closed')
	local r, g, b, a = unpack(get())
	eq(r, 0.2, 'the old row: opening r')
	eq(a, 0.8, 'and a')
	check(not written, 'the new row is never written')
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

-- The normal text color, 'r,g,b' to two places, and a font string's.
local function normal_rgb() return string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.normal:GetRGB()) end
local function ink_of(fs) return string.format('%.2f,%.2f,%.2f', fs:GetTextColor()) end

test('color: the code is the normal text color on any color and opacity, never white by the fill', function()
	local function ink(hasAlpha, r, g, b, a)
		local w = color_widget({ hasAlpha = hasAlpha, value = { r, g, b, a } })
		local out = ink_of(w.text)
		w:Release()
		return out
	end
	eq(ink(false, 1, 1, 1, 1), normal_rgb(), 'white fill')
	eq(ink(false, 1, 1, 0, 1), normal_rgb(), 'yellow, a light color')
	eq(ink(false, 0, 0, 0, 1), normal_rgb(), 'black fill, a dark color')
	eq(ink(true, 1, 1, 1, 0.3), normal_rgb(), 'a light color at 30%')
	check(normal_rgb() ~= '1.00,1.00,1.00', 'not white: the normal text color')
end)

-- The color field's parts' insets from the field, 'left,top,right,bottom'.
local function swatch_insets(w)
	return {
		inner = H.insets(w.inner, w.frame),
		fill = H.insets(w.swatch, w.frame),
		line = w.line:IsShown() and H.insets(w.line, w.frame) or 'hidden',
	}
end

-- The code's left, from the field's left, and how it sits.
local function code_place(w)
	local point, rel, relPoint, x = w.text:GetPoint(1)
	check(rel == w.frame, 'the code is placed on the field')
	return point .. ' ' .. relPoint .. ' ' .. x .. ' ' .. w.text:GetJustifyH()
end

test('color: a field, its swatch at the left (40 wide, the inner height, a line after it), then the code', function()
	theme('thick')
	local w = color_widget({ value = { 1, 0, 0, 1 } })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	check_box(w.frame, 'thick')
	eq(size_of(w.frame), '170x24', "a dropdown's size")
	local p = swatch_insets(w)
	-- Inside the 1px edge: the swatch's black line from 1 to 41, the color a
	-- pixel in from it, then the edge's line from 41 to 42.
	eq(p.inner, '1,1,129,1', 'the swatch: 40 wide, the field\'s inner height')
	eq(p.fill, '2,2,130,2', 'the color a pixel in, inside its black line')
	eq(p.line, '41,1,128,1', 'a 1px line after it')
	eq(H.rgba(unpack(stub.state(w.line).color_texture)), H.rgba(unpack(st.BOX_COLORS.edge)), "the line in the field's edge color")
	eq(H.rgba(unpack(stub.state(w.inner).color_texture)), '0.00,0.00,0.00,1.00', 'the swatch\'s black line')
	-- The code: the field's text inset (8) after the line, to 8 from the right.
	eq(code_place(w), 'LEFT LEFT 50 LEFT', 'the code 8 after the line, left-aligned')
	local _, _, _, rx = w.text:GetPoint(2)
	eq(rx, -8, 'and 8 in from the right')
	eq(w.text:GetText(), '#FF0000', 'the code')
	eq(ink_of(w.text), normal_rgb(), 'in the normal text color')
	-- Layers: the black line, the checker, the color, then the code over them.
	local fl, fs = w.swatch:GetDrawLayer()
	local ll, ls = w.inner:GetDrawLayer()
	eq(ll .. ls, 'ARTWORK0', 'the black line at the bottom')
	eq(fl .. fs, 'ARTWORK3', 'the color over the checker')
	eq((w.text:GetDrawLayer()), 'OVERLAY', 'the code over them all')
	w:Release()
end)

-- The checker's squares shown on a color field: { rect = 'x,y,w,h' from the
-- field's top left, light = true for the light grey }.
local function checker_of(w)
	local out = {}
	for _, region in ipairs(H.shown_textures(w.frame)) do
		local c = stub.state(region).color_texture
		if region.checker then
			out[#out + 1] = {
				x = math.floor(region:GetLeft() - w.frame:GetLeft() + 0.5),
				y = math.floor(w.frame:GetTop() - region:GetTop() + 0.5),
				w = math.floor(region:GetWidth() + 0.5), h = math.floor(region:GetHeight() + 0.5),
				grey = c and string.format('%.2f', c[1]),
			}
		end
	end
	return out
end

test('color: a see-through color shows over a checker of two greys in 4px squares; a solid one over none', function()
	theme('thick')
	local w = color_widget({ hasAlpha = true, value = { 1, 0, 0, 0.6 } })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local squares = checker_of(w)
	check(#squares > 0, 'a checker under the see-through color')
	-- The dark grey covers the color's area, the light squares alternate on it.
	local back, light, greys = nil, {}, {}
	for _, s in ipairs(squares) do
		greys[s.grey] = true
		if s.w > 4 then back = s else light[#light + 1] = s end
	end
	check(back ~= nil, 'a dark grey under the squares')
	eq(back and (back.x .. ',' .. back.y .. ',' .. back.w .. ',' .. back.h), '2,2,38,20', "it fills the color's area")
	local count = 0
	for _ in pairs(greys) do count = count + 1 end
	eq(count, 2, 'two greys')
	-- The light squares: every other 4px square from the area's top left, cut
	-- at its right edge (38 is 9 squares and a half).
	local cells = {}
	for _, s in ipairs(light) do
		check(s.w <= 4 and s.h <= 4, 'a square at most 4px')
		cells[#cells + 1] = ((s.x - 2) / 4) .. ':' .. ((s.y - 2) / 4)
		check((((s.x - 2) / 4) + ((s.y - 2) / 4)) % 2 == 0, 'a light square every other place')
	end
	eq(#light, 25, '10 columns of 5 rows, every other one light')
	local tl, tr = w.swatch:GetDrawLayer()
	eq(tl .. tr, 'ARTWORK3', 'the color over the checker')
	eq(string.format('%.1f', stub.state(w.swatch).color_texture[4]), '0.6', 'drawn at its opacity')

	-- Solid at 100%, or with no opacity: no checker.
	w:Release()
	local solid = color_widget({ hasAlpha = true, value = { 1, 0, 0, 1 } })
	solid:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	eq(#checker_of(solid), 0, 'at 100%: no checker')
	solid:Release()
	local opaque = color_widget({ hasAlpha = false, value = { 1, 0, 0, 0.6 } })
	opaque:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	eq(#checker_of(opaque), 0, 'no hasAlpha: no checker')
	opaque:Release()
end)

test('color: the checker and the code round the opacity alike: 99.6% is solid, 99.4% is not', function()
	for _, case in ipairs({ { 0.996, false, '#FF0000' }, { 0.995, false, '#FF0000' }, { 0.994, true, '#FF0000 \194\183 99%' } }) do
		local w = color_widget({ hasAlpha = true, value = { 1, 0, 0, case[1] } })
		w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
		eq(#checker_of(w) > 0, case[2], case[1] .. ': the checker')
		eq(w.text:GetText(), case[3], case[1] .. ': the code')
		w:Release()
	end
end)

test("color: the checker's squares stay inside the swatch's area, under Thick, Thin and Blizzard", function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(name)
		local w = color_widget({ hasAlpha = true, value = { 1, 0, 0, 0.5 } })
		w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
		local area = w.area
		local squares = checker_of(w)
		check(#squares > 0, name .. ': a checker')
		for _, s in ipairs(squares) do
			check(s.x >= area.x and s.y >= area.y and s.x + s.w <= area.x + area.width and s.y + s.h <= area.y + area.height,
				name .. ': ' .. s.x .. ',' .. s.y .. ',' .. s.w .. ',' .. s.h .. ' inside ' .. area.x .. ',' .. area.y .. ',' .. area.width .. ',' .. area.height)
		end
		w:Release()
	end
	theme('thick')
end)

test('color: the checker follows the picker, coming and going with the opacity', function()
	theme('thick')
	local w = color_widget({ hasAlpha = true, value = { 0, 0, 1, 1 } })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	eq(#checker_of(w), 0, 'solid: none')
	click(w.frame)
	pick_color(0, 0, 1, 0.5)
	check(#checker_of(w) > 0, 'see-through: the checker')
	pick_color(0, 0, 1, 1)
	eq(#checker_of(w), 0, 'solid again: gone')
	picker_cancel()
	w:Release()
end)

test('color: under the mouse its body tints, as an input\'s, and its edge stays', function()
	theme('thick')
	local w = color_widget()
	stub.fire_script(w.frame, 'OnEnter', true)
	eq(H.rgba(w.frame:GetBackdropBorderColor()), H.rgba(unpack(st.BOX_COLORS.edge)), 'the edge stays')
	check(st:StateLook(w.frame).layer.shown, 'the Layer tints the body')
	stub.fire_script(w.frame, 'OnLeave', true)
	check(not st:StateLook(w.frame).layer.shown, 'gone again')
	w:Release()
end)

test("color: under Blizzard the field is the Settings dropdown's face, with Blizzard's swatch inside it", function()
	theme('blizzard')
	local w = color_widget({ hasAlpha = true, value = { 0, 1, 0, 0.5 } })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	check_no_box(w.frame, 'blizzard')
	local face = H.atlas_piece(w.frame, 'common-dropdown-c-button')
	check(face ~= nil, 'the dropdown face')
	eq(face and H.insets(face, w.frame), '-7,-7,-7,-7', 'outset 7 round the field, as a select\'s')
	-- The swatch: a white square, a black one a pixel in, the color (and the
	-- checker) a pixel in again, 3 in from the face's edge.
	local white = w.white
	check(white and white:IsShown(), "the swatch's white square")
	eq(H.insets(white, w.frame), '3,3,127,3', 'the swatch 40 wide, 3 in from the face')
	eq(H.rgba(unpack(stub.state(white).color_texture)), '1.00,1.00,1.00,1.00', 'white')
	eq(H.insets(w.inner, w.frame), '4,4,128,4', 'the black square a pixel in')
	eq(H.insets(w.swatch, w.frame), '5,5,129,5', 'the color a pixel in again')
	check(not w.line:IsShown(), 'no line: the white square parts it from the code')
	check(#checker_of(w) > 0, 'see-through: the checker inside it')
	eq(code_place(w), 'LEFT LEFT 51 LEFT', 'the code 8 after the swatch')
	eq(ink_of(w.text), normal_rgb(), 'in the normal text color')
	-- The face follows the mouse and the disabled state, as a select's.
	stub.fire_script(w.frame, 'OnEnter', true)
	eq(face:GetAtlas(), 'common-dropdown-c-button-hover-1', 'under the mouse')
	stub.fire_script(w.frame, 'OnMouseDown', 'LeftButton')
	eq(face:GetAtlas(), 'common-dropdown-c-button-pressedhover-1', 'pressed')
	stub.fire_script(w.frame, 'OnMouseUp', 'LeftButton')
	stub.fire_script(w.frame, 'OnLeave', true)
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'at rest')
	w:SetDisabled(true)
	eq(face:GetAtlas(), 'common-dropdown-c-button-disabled', 'disabled')
	w:SetDisabled(false)
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'enabled again')
	check(H.atlas_piece(w.frame, 'common-dropdown-c-button-hover-arrow') == nil, 'no hover arrow: no list opens')

	-- Back to Thick: Box again, the face and the white square gone.
	theme('thick')
	rebind(w)
	check_box(w.frame, 'thick again', nil, true)
	check(H.atlas_piece(w.frame, 'common-dropdown-c-button') == nil, 'no face')
	check(not w.white:IsShown(), 'no white square')
	eq(H.insets(w.swatch, w.frame), '2,2,130,2', "the color where Thick's swatch has it")
	eq(code_place(w), 'LEFT LEFT 50 LEFT', "the code where Thick's has it")
	w:Release()
end)

test('color: every edge on a whole pixel, under Thick, Thin and Blizzard, see-through and solid, with a size read back a hair off', function()
	local P = load_test_file('lib/pixels.lua')
	local HAIR = 2 ^ -14
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, a in ipairs({ 1, 0.4 }) do
			for _, noise in ipairs({ 0, HAIR, -HAIR }) do
				stub.size_noise = noise
				theme(name)
				local w = color_widget({ hasAlpha = true, value = { 0.3, 0.6, 0.9, a } })
				w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
				local off = P.off(w.frame)
				eq(#off, 0, name .. ' at ' .. a .. ', noise ' .. noise .. ': ' .. P.report(off))
				w:Release()
			end
		end
	end
	stub.size_noise = 0
	theme('thick')
end)

test('color: a disabled field takes no mouse', function()
	local w = color_widget()
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
	pick_color(1, 1, 1, 0.8)
	eq(w.text:GetText(), '#FFFFFF \194\183 80%', 'the new code and opacity')
	eq(ink_of(w.text), normal_rgb(), 'the code in the normal text color')
	-- SetColorTexture records the fill in the stub's color_texture (GetVertexColor stays 1,1,1).
	local function fill()
		local c = stub.state(w.swatch).color_texture
		return string.format('%.1f,%.1f,%.1f,%.1f', c[1], c[2], c[3], c[4])
	end
	eq(fill(), '1.0,1.0,1.0,0.8', 'the fill is white at 80%')
	picker_cancel()
	eq(fill(), '0.0,0.0,0.0,1.0', 'Cancel: the old fill')
	eq(w.text:GetText(), '#000000', 'Cancel: the old code')
	eq(ink_of(w.text), normal_rgb(), 'Cancel: the normal text color still')
	w:Release()
end)

test('color: a click anywhere on the bar opens the picker; a disabled bar does not', function()
	local w = color_widget()
	w:SetDisabled(true)
	click(w.frame)
	check(not W.ColorPickerShown(), 'disabled: no picker')
	w:SetDisabled(false)
	click(w.frame)
	check(W.ColorPickerShown(), 'enabled: the picker opens')
	picker_cancel()
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

------------------------------------------------------------------ color with a toggle

-- A color field with SaftUI's toggle field: a check box at its left that turns
-- the color on (its get and set, and offText, the grey word the field shows
-- while it's off).
local function toggled_color(fields)
	fields = fields or {}
	local value = fields.value or { 0.2, 0.4, 0.6, 1 }
	local on = fields.on ~= false
	local log = { sets = {}, toggles = {} }
	local w, told, root, row = bind('color', 'tint', opt('color', 'Tint', {
		get = function() return unpack(value) end,
		set = function(_, r, g, b, a) log.sets[#log.sets + 1] = { r, g, b, a }; value = { r, g, b, a } end,
		toggle = {
			get = function() return on end,
			set = function(_, v) log.toggles[#log.toggles + 1] = v; on = v end,
			offText = fields.offText or 'Class',
			desc = fields.desc,
		},
	}))
	log.on = function() return on end
	log.set_on = function(v) on = v end
	return w, told, log, root, row
end

local function grey_rgb() return string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.muted:GetRGB()) end

test('color with a toggle: a check box at the left of the field, 18 square on whole pixels, then the swatch and the code', function()
	theme('thick')
	local w = toggled_color()
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	check(w.check and w.check:IsShown(), 'a check box is drawn')
	eq(size_of(w.check), '18x18', "the kit's check box size")
	eq(H.insets(w.check, w.frame), '4,3,148,3', 'inside the field, 4 from its left, centered on its line')
	eq(w.check:GetChecked(), true, 'ticked')
	check(w.check.mark:IsShown(), "with the kit's blue mark")
	check(w.swatch:IsShown() and w.inner:IsShown() and w.line:IsShown(), 'the swatch is shown')
	check(w.swatch:GetLeft() > w.check:GetRight(), 'after the check box')
	eq(w.text:GetText(), '#336699', 'the code')
	eq(ink_of(w.text), normal_rgb(), 'in the normal text color')
	eq(size_of(w.frame), '170x24', 'the field keeps its size')
	w:Release()
end)

test('color with a toggle: off, a grey word the option gives takes the swatch and the code', function()
	local w, _, log = toggled_color({ on = false, offText = 'Class color' })
	check(w.check:IsShown() and not w.check:GetChecked(), 'the box is empty')
	check(not w.check.mark:IsShown(), 'with no mark')
	check(not w.swatch:IsShown() and not w.inner:IsShown() and not w.line:IsShown() and not w.checkerBack:IsShown(),
		'no swatch, line or checker')
	eq(w.text:GetText(), 'Class color', 'the word')
	eq(ink_of(w.text), grey_rgb(), 'in the grey of Text > Muted')
	eq(#log.toggles, 0, 'nothing was set by showing it')
	w:Release()
end)

test('color with a toggle: offText can be a function of the row', function()
	local seen = 'Reaction'
	local w = bind('color', 'tint', opt('color', 'Tint', {
		get = function() return 1, 0, 0, 1 end, set = function() end,
		toggle = { get = function() return false end, set = function() end, offText = function() return seen end },
	}))
	eq(w.text:GetText(), 'Reaction', 'the word is what the function gives')
	w:Release()
end)

test('color with a toggle: the box takes its own click and toggles, opening no picker', function()
	local w, told, log = toggled_color({ on = true })
	click(w.check)
	eq(table.concat({ tostring(log.toggles[1]) }), 'false', 'ticking off sets false')
	check(not W.ColorPickerShown(), 'no picker')
	eq(told.n, 1, 'the window is told')
	eq(told.ok, true, 'it went well')
	check(not w.check:GetChecked() and not w.swatch:IsShown() and w.text:GetText() == 'Class', 'the field shows it off')
	click(w.check)
	eq(log.toggles[2], true, 'ticking on sets true')
	check(w.swatch:IsShown() and w.text:GetText() == '#336699', 'the color is back')
	check(not W.ColorPickerShown(), 'still no picker')
	eq(#log.sets, 0, 'the color itself is never set by the box')
	w:Release()
end)

test('color with a toggle: a click on the field when off ticks it and opens nothing; when on, opens the picker', function()
	local w, told, log = toggled_color({ on = false })
	click(w.frame)
	eq(log.toggles[1], true, 'ticked')
	check(not W.ColorPickerShown(), 'no picker as it ticks')
	eq(told.n, 1, 'the window is told')
	click(w.frame)
	check(W.ColorPickerShown(), 'on: the picker opens')
	eq(#log.toggles, 1, 'and nothing is ticked')
	pick_color(1, 1, 1, 1)
	eq(#log.sets, 1, 'a pick sets the color')
	picker_cancel()
	w:Release()
end)

test('color with a toggle: turning it off closes the picker', function()
	local w = toggled_color({ on = true })
	click(w.frame)
	check(W.ColorPickerShown(), 'open')
	click(w.check)
	check(not W.ColorPickerShown(), 'closed by the box')
	w:Release()
end)

test('color with a toggle: disabled, neither the box nor the field takes the mouse or a click', function()
	local w, _, log = toggled_color({ on = false })
	w:SetDisabled(true)
	eq(w.frame:IsMouseEnabled(), false, 'the field takes no mouse')
	eq(w.check:IsMouseEnabled(), false, 'nor does the box')
	click(w.check)
	click(w.frame)
	eq(#log.toggles, 0, 'nothing ticked')
	w:SetDisabled(false)
	eq(w.check:IsMouseEnabled(), true, 'enabled: the box takes the mouse again')
	w:Release()
end)

test("color with a toggle: the box's tooltip says what unticked means; its own desc wins", function()
	local lines, owner = {}, nil
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) owner = frame end, ClearLines = function() lines = {} end,
		AddLine = function(_, text) lines[#lines + 1] = text end, Show = function() end,
		IsOwned = function(_, frame) return owner == frame end, Hide = function() owner = nil end,
	}
	local ok, err = pcall(function()
		local w = toggled_color({ on = true, offText = 'Class color' })
		stub.fire_script(w.check, 'OnEnter', true)
		eq(owner, w.check, 'owned by the box')
		check((lines[2] or ''):find('Class color', 1, true), 'unticked, the field shows Class color: ' .. tostring(lines[2]))
		stub.fire_script(w.check, 'OnLeave', true)
		eq(owner, nil, 'hidden on leave')
		w:Release()
		w = toggled_color({ on = true, offText = 'Class color', desc = 'Unticked, the bar is class colored.' })
		stub.fire_script(w.check, 'OnEnter', true)
		eq(lines[2], 'Unticked, the bar is class colored.', "the option's own words")
		stub.fire_script(w.check, 'OnLeave', true)
		w:Release()
	end)
	_G.GameTooltip = saved
	if not ok then error(err, 0) end
end)

test('color with a toggle: a field rebound to a row without one has no box and the swatch where it always was', function()
	theme('thick')
	local w = toggled_color()
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local root, row = H.make('plain', opt('color', 'Plain', { get = function() return 1, 0, 0, 1 end, set = function() end }))
	w:Bind(root, row, function() end)
	check(not w.check:IsShown(), 'no box')
	eq(H.insets(w.swatch, w.frame), '2,2,130,2', "the swatch where a plain field has it")
	eq(code_place(w), 'LEFT LEFT 50 LEFT', 'and the code')
	check(w.swatch:IsShown() and w.text:GetText() == '#FF0000', 'the color is shown')
	w:Release()
end)

test('color with a toggle: the box and the field follow the look, under Thick, Thin and Blizzard', function()
	local w = toggled_color({ on = true })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	for _, name in ipairs({ 'thick', 'blizzard', 'thin', 'blizzard', 'thick' }) do
		theme(name)
		rebind(w)
		eq(size_of(w.frame), '170x24', name .. ': the same field')
		check(w.check:IsShown(), name .. ': the box is shown')
		if name == 'blizzard' then
			check(w.check.art and w.check.art.normal:IsShown(), name .. ": Blizzard's check box art")
			check(w.check.art.check:IsShown(), name .. ': ticked, its check')
			check(not w.check.mark:IsShown(), name .. ': no blue mark')
		else
			check(w.check.mark:IsShown(), name .. ': the blue mark')
		end
		check(w.swatch:GetLeft() >= w.check:GetRight(), name .. ': the swatch after the box')
	end
	w:Release()
end)

test('color with a toggle: every edge on a whole pixel, on or off, under Thick, Thin and Blizzard, with a size read back a hair off', function()
	local P = load_test_file('lib/pixels.lua')
	local HAIR = 2 ^ -14
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, on in ipairs({ true, false }) do
			for _, noise in ipairs({ 0, HAIR, -HAIR }) do
				stub.size_noise = noise
				theme(name)
				local w = toggled_color({ on = on })
				w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
				local off = P.off(w.frame)
				eq(#off, 0, name .. (on and ' on' or ' off') .. ', noise ' .. noise .. ': ' .. P.report(off))
				w:Release()
			end
		end
	end
	stub.size_noise = 0
	theme('thick')
end)

test('color with a toggle, Blizzard: the box takes the mouse over all of its art, so a click on the art never reaches the field; Thick and Thin keep the 18 square', function()
	local w = toggled_color({ on = true })
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	for _, name in ipairs({ 'thick', 'thin', 'blizzard', 'thick' }) do
		theme(name)
		rebind(w)
		local l, r, t, b = w.check:GetHitRectInsets()
		if name == 'blizzard' then
			local art = w.check.art.normal
			check(w.check:GetLeft() + l <= art:GetLeft() + 0.01 and w.check:GetRight() - r >= art:GetRight() - 0.01
				and w.check:GetTop() - t >= art:GetTop() - 0.01 and w.check:GetBottom() + b <= art:GetBottom() + 0.01,
				name .. ': the hit rect covers the art (insets ' .. table.concat({ l, r, t, b }, ',') .. ')')
		else
			eq(table.concat({ l, r, t, b }, ','), '0,0,0,0', name .. ': the 18 square')
		end
	end
	w:Release()
end)

test('color with a toggle: the swatch, the code and the word sit where the README says, under each look', function()
	local want = {
		thick = { inner = '31,1,99,1', fill = '32,2,100,2', code = 'LEFT LEFT 80 LEFT', word = 31 },
		blizzard = { code = 'LEFT LEFT 81 LEFT', word = 33 },
	}
	want.thin = want.thick
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(name)
		local w, _, log = toggled_color({ on = true })
		w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
		local expected = want[name]
		if expected.inner then
			eq(H.insets(w.inner, w.frame), expected.inner, name .. ': the swatch line at 31')
			eq(H.insets(w.swatch, w.frame), expected.fill, name .. ': the color at 32')
		else
			eq(H.insets(w.white, w.frame):match('^(%d+),'), '33', name .. ': the white square at 33')
			eq(H.insets(w.swatch, w.frame):match('^(%d+),'), '35', name .. ': the color at 35')
		end
		eq(code_place(w), expected.code, name .. ': the code')
		w:Release()
		w = toggled_color({ on = false })
		w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
		local _, _, _, x = w.text:GetPoint(1)
		eq(x, expected.word, name .. ': the word starts where the swatch did')
		w:Release()
	end
	theme('thick')
end)

test('color with a toggle: a row bound disabled gives the box no mouse; a row bound on a released box again does', function()
	local w = bind('color', 'tint', opt('color', 'Tint', {
		disabled = true, get = function() return 1, 1, 1, 1 end, set = function() end,
		toggle = { get = function() return true end, set = function() end, offText = 'Class' },
	}))
	eq(w.check:IsMouseEnabled(), false, 'bound disabled: no mouse on the box')
	eq(w.frame:IsMouseEnabled(), false, 'nor on the field')
	w:Release()
end)

test("color with a toggle: releasing the field hides the box's tooltip", function()
	local owner
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) owner = frame end, ClearLines = function() end, AddLine = function() end, Show = function() end,
		IsOwned = function(_, frame) return owner == frame end, Hide = function() owner = nil end,
	}
	local ok, err = pcall(function()
		local w = toggled_color()
		stub.fire_script(w.check, 'OnEnter', true)
		eq(owner, w.check, 'shown')
		w:Release()
		eq(owner, nil, 'gone with the field')
	end)
	_G.GameTooltip = saved
	if not ok then error(err, 0) end
end)

test('color with a toggle: Pick opens nothing while it is off, even called directly', function()
	local w = toggled_color({ on = false })
	w:Pick()
	check(not W.ColorPickerShown(), 'no picker')
	w:Release()
end)

test('color with a toggle: a toggle turned off under an open picker (a reset) closes it, and a later pick writes nothing', function()
	local w, _, log = toggled_color({ on = true })
	click(w.frame)
	check(W.ColorPickerShown(), 'open')
	log.set_on(false)
	pick_color(1, 0, 0, 1)
	check(not W.ColorPickerShown(), 'the pick finds the picker stale and closes it')
	eq(#log.sets, 0, 'no color is written where nothing shows it')
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

------------------------------------------------------------------ keybinding

test("keybinding: with Blizzard's binding helpers, META chords bind and its ignored keys are never tried", function()
	-- BindingUtil.lua's, as Blizzard has them (the stubs have none).
	local meta_down, chords = false, 0
	local names = { 'IsMetaKeyDown', 'IsKeyPressIgnoredForBinding', 'CreateKeyChordStringUsingMetaKeyState' }
	local saved = {}
	for _, name in ipairs(names) do saved[name] = _G[name] end
	local META_KEYS = { LALT = 1, RALT = 1, LCTRL = 1, RCTRL = 1, LSHIFT = 1, RSHIFT = 1, LMETA = 1, RMETA = 1,
		ALT = 1, CTRL = 1, SHIFT = 1, META = 1 }
	IsMetaKeyDown = function() return meta_down end
	IsKeyPressIgnoredForBinding = function(key) return META_KEYS[key] ~= nil or key == 'UNKNOWN' or key == 'BUTTON1' or key == 'BUTTON2' end
	CreateKeyChordStringUsingMetaKeyState = function(key)
		chords = chords + 1
		local chord = {}
		if IsAltKeyDown() then chord[#chord + 1] = 'ALT' end
		if IsControlKeyDown() then chord[#chord + 1] = 'CTRL' end
		if IsShiftKeyDown() then chord[#chord + 1] = 'SHIFT' end
		if IsMetaKeyDown() then chord[#chord + 1] = 'META' end
		chord[#chord + 1] = key
		return table.concat(chord, '-')
	end
	local ok, err = pcall(function()
		local sets = {}
		local w = bind('keybinding', 'metakey', opt('keybinding', 'Key', {
			get = function() return 'F5' end, set = function(_, v) sets[#sets + 1] = v end,
		}))
		click(w.frame)
		stub.fire_script(w.frame, 'OnKeyDown', 'LMETA')
		eq(#sets, 0, "a META key alone is Blizzard's ignored key")
		meta_down, stub.shift_down = true, true
		stub.fire_script(w.frame, 'OnKeyDown', 'G')
		meta_down, stub.shift_down = false, false
		eq(sets[1], 'SHIFT-META-G', "a META chord, in Blizzard's order")
		eq(chords, 1, "built by Blizzard's chord function")
		click(w.frame)
		stub.fire_script(w.frame, 'OnKeyDown', 'UNKNOWN')
		eq(#sets, 1, 'UNKNOWN is ignored')
		w:Release()
	end)
	for _, name in ipairs(names) do _G[name] = saved[name] end
	if not ok then error(err, 0) end
end)

test('keybinding: without Blizzard\'s binding helpers, the fallback adds META and ignores the META keys', function()
	local saved = IsMetaKeyDown
	local meta_down = false
	IsMetaKeyDown = function() return meta_down end
	local ok, err = pcall(function()
		local sets = {}
		local w = bind('keybinding', 'metafallback', opt('keybinding', 'Key', {
			get = function() return 'F5' end, set = function(_, v) sets[#sets + 1] = v end,
		}))
		click(w.frame)
		stub.fire_script(w.frame, 'OnKeyDown', 'RMETA')
		eq(#sets, 0, 'a META key alone is ignored')
		meta_down, stub.shift_down, stub.alt_down = true, true, true
		stub.fire_script(w.frame, 'OnKeyDown', 'G')
		meta_down, stub.shift_down, stub.alt_down = false, false, false
		eq(sets[1], 'ALT-SHIFT-META-G', "the same order as Blizzard's chord")
		w:Release()
	end)
	IsMetaKeyDown = saved
	if not ok then error(err, 0) end
end)

test('keybinding: a click waits, the next key (with modifiers) is set, Esc clears', function()
	local value, sets = 'F5', {}
	local w, told = bind('keybinding', 'key', opt('keybinding', 'Key', {
		get = function() return value end, set = function(_, v) sets[#sets + 1] = v; value = v end,
	}))
	eq(w:GetWidth(), 170, 'width')
	eq(text_of(w.text), 'F5', 'shows the key')

	click(w.frame)
	eq(text_of(w.text), 'Press a key', 'waiting')
	do -- "Press a key" is the accent: a non-default one, so a literal blue fails
		local accent = st.config.profile.theme.accent
		accent:SetRGB(0.9, 0.1, 0.2)
		click(w.frame); click(w.frame) -- stop waiting, wait again: drawn again
		eq(string.format('%.2f,%.2f,%.2f', w.text:GetTextColor()), '0.90,0.10,0.20', 'Press a key in the accent')
		accent:SetRGB(0, 0.68, 0.94)
	end
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
	eq(ink_of(w.text), grey_rgb(), 'Not bound is Text > Muted')

	click(w.frame)
	stub.fire_script(w.frame, 'OnMouseDown', 'MiddleButton')
	eq(sets[3], 'BUTTON3', 'the middle button')
	click(w.frame)
	stub.fire_script(w.frame, 'OnMouseDown', 'Button6')
	eq(sets[4], 'BUTTON6', 'a sixth mouse button commits the game\'s name')
	click(w.frame)
	stub.fire_script(w.frame, 'OnMouseDown', 'Button31')
	eq(sets[5], 'BUTTON31', 'the last mouse button')
	click(w.frame)
	stub.fire_script(w.frame, 'OnMouseWheel', 1)
	eq(sets[6], 'MOUSEWHEELUP', 'the wheel')

	click(w.frame)
	click(w.frame)
	check(not w.frame:IsKeyboardEnabled(), 'a second click stops waiting')
	eq(#sets, 6, 'sets nothing')
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

test("a color field: Blizzard's swatch inside the face under Blizzard, the swatch and its line under Thick", function()
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
	eq(squares(), '3,3,127,3=1.0,1.0,1.0 4,4,128,4=0.0,0.0,0.0 5,5,129,5=1.0,0.5,0.0',
		'white 40 wide, 3 in from the face; black a pixel in, the color a pixel in again')
	eq(size_of(button), '170x24', "a dropdown's size")

	theme('thick')
	rebind(w)
	check_box(button, 'Thick')
	eq(squares(), '1,1,129,1=0.0,0.0,0.0 2,2,130,2=1.0,0.5,0.0 41,1,128,1=0.3,0.3,0.3',
		"Thick: the swatch's black line and the color inside the edge, then the edge's line")
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
