-- SaftUI-Core/Config/optionsposition.lua, the Position block (type 'position'):
-- its boxes, dropdown, nudges and dots, and their art under SaftUI's theme
-- Blizzard.
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
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local W = st.OptionsWidgets
local click, type_into, check_no_box, check_box, shown_textures = H.click, H.type_into, H.check_no_box, H.check_box, H.shown_textures
local parent, around, rebind, art_inside, atlas_exact = H.parent, H.around, H.rebind, H.art_inside, H.atlas_exact
local theme, check_line, atlases_of, INPUT_ART, size_of = H.theme, H.check_line, H.atlases_of, H.INPUT_ART, H.size_of
local opt, bind = H.opt, H.bind

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

local function rgb_text(r, g, b) return string.format('%.3f,%.3f,%.3f', r, g, b) end
-- A dot is a glyph (Widgets/states.lua): a white texture whose vertex color is the dot's color.
local function dot_color(button)
	return rgb_text(button.dot:GetVertexColor())
end

local function picked(dots)
	local out = {}
	for i, dot in ipairs(dots) do
		if dot.picked then out[#out + 1] = i end
	end
	return table.concat(out, ',')
end

------------------------------------------------------------------ position

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
	-- Each half's arrow is one Lucide chevron, 12 x 12, on whole pixels: the
	-- both 1 above their half's top, a middle 5 down it.
	local function arrow(button, texture)
		eq(button.arrow:GetTexture(), texture, 'the chevron')
		eq(button.arrow:GetWidth() .. 'x' .. button.arrow:GetHeight(), '12x12', 'drawn 12 by 12')
		local point, rel, relPoint, ax, ay = button.arrow:GetPoint(1)
		return ('%s %s %s,%s'):format(point, relPoint, ax, ay), rel == button
	end
	local upAt, upOn = arrow(w.xUp, st.icons.chevronUp)
	local downAt, downOn = arrow(w.xDown, st.icons.chevronDown)
	eq(upAt, 'TOP TOP 0,1', 'the up chevron 1 above its half\'s top: a whole offset')
	eq(downAt, 'TOP TOP 0,1', 'the down chevron the same, as far from the divider')
	check(upOn and downOn, 'on its own button')
	check(w.xUp.arrows == nil and w.xDown.arrows == nil, 'the three rows are gone')
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
	local br, bg, bb = st.config.profile.theme.accent:GetRGB()
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
	local tr, tg, tb = st:StateColor('edgeHover')
	eq(dot_color(w.this[7]), rgb_text(tr, tg, tb), 'a hovered dot is the lighter tone of the accent')
	eq(w.this[7].dot:GetWidth(), 4, 'still 4 square: it does not grow')
	stub.fire_script(w.this[2], 'OnEnter')
	eq(dot_color(w.this[2]), rgb_text(tr, tg, tb), 'the picked dot under the mouse: the lighter tone too')
	eq(w.this[2].dot:GetWidth(), 8, 'and still 8')
	stub.fire_script(w.this[2], 'OnLeave')
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
	local gr, gg, gb = st.config.profile.colors.text.muted:GetRGB()
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

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test("the position block's boxes, dropdown and nudges take their art, and its dots a 1px line", function()
	theme('thick')
	local store = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 0, frame = 'PlayerFrame', relative_to = '__global' }
	local w = bind_position({
		target = 'select', nameKey = '__global', values = { Health = 'Health', __global = 'Global frame' },
	}, store)
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local thickSize = size_of(w.frame)
	local squares = { this = w.thisSquare, at = w.atSquare }
	local boxes = { name = w.name, x = w.x, y = w.y }
	local nudges = { xUp = w.xUp, xDown = w.xDown, yUp = w.yUp, yDown = w.yDown }
	for name, square in pairs(squares) do check_box(square, 'Thick: the ' .. name .. ' dots') end
	for name, box in pairs(boxes) do check_box(box, 'Thick: ' .. name, nil, true) end
	check_box(w.select, 'Thick: the dropdown')
	for name, nudge in pairs(nudges) do
		eq(atlases_of(nudge), '', 'Thick: ' .. name .. ' has no art')
		check_box(nudge:GetParent(), 'Thick: ' .. name .. "'s box")
	end

	theme('blizzard')
	rebind(w)
	for name, square in pairs(squares) do check_line(square, 'the ' .. name .. ' dots') end
	for name, box in pairs(boxes) do
		check_no_box(box, name)
		eq(atlases_of(box), INPUT_ART, name .. ' is a text box')
		art_inside(box, name)
	end
	check(w.name:IsShown(), 'the name box shows')
	check_no_box(w.select, 'the dropdown')
	eq(atlases_of(w.select), 'common-dropdown-c-button', 'the dropdown is the Settings face')
	local face = atlas_exact(w.select, 'common-dropdown-c-button')
	eq(around(face, w.select), '-4,4,4,-4', 'compact: a 4px glow, clear of the name box under it')
	eq(#w.select.caret, 1, 'one caret texture')
	for _, row in ipairs(w.select.caret) do check(not row:IsShown(), 'no caret') end
	eq(w.select.text:GetJustifyH(), 'CENTER', 'its text centred')
	stub.fire_script(w.select, 'OnEnter')
	eq(face:GetAtlas(), 'common-dropdown-c-button-hover-1', 'under the mouse')
	eq(atlases_of(w.select), 'common-dropdown-c-button-hover-1', 'compact: no hover arrow')
	stub.fire_script(w.select, 'OnLeave')
	eq(face:GetAtlas(), 'common-dropdown-c-button', 'the mouse gone')
	eq(atlases_of(w.xUp), 'minimal-scrollbar-arrow-top', 'up is the top arrow')
	eq(atlases_of(w.xDown), 'minimal-scrollbar-arrow-bottom', 'down the bottom one')
	for name, nudge in pairs(nudges) do
		art_inside(nudge, name)
		check(not nudge.arrow:IsShown(), name .. ': no chevron')
		check_no_box(nudge:GetParent(), name .. "'s box")
	end
	for _, region in ipairs(shown_textures(w.xUp:GetParent())) do
		check(false, 'the pair draws nothing of its own: ' .. tostring(region:GetTexture()))
	end
	stub.fire_script(w.xUp, 'OnEnter')
	eq(atlases_of(w.xUp), 'minimal-scrollbar-arrow-top-over', 'under the mouse')
	stub.fire_script(w.xUp, 'OnMouseDown', 'LeftButton')
	eq(atlases_of(w.xUp), 'minimal-scrollbar-arrow-top-down', 'pressed')
	stub.fire_script(w.xUp, 'OnMouseUp', 'LeftButton')
	eq(atlases_of(w.xUp), 'minimal-scrollbar-arrow-top-over', 'let go')
	stub.fire_script(w.xUp, 'OnLeave')
	eq(atlases_of(w.xUp), 'minimal-scrollbar-arrow-top', 'the mouse gone')
	click(w.yDown)
	eq(store.y_off, -1, 'a nudge still nudges')
	eq(size_of(w.frame), thickSize, 'the block keeps its size')

	theme('thick')
	rebind(w)
	for name, square in pairs(squares) do check_box(square, 'Thick again: the ' .. name .. ' dots') end
	for name, box in pairs(boxes) do
		check_box(box, 'Thick again: ' .. name)
		eq(atlases_of(box), '', 'Thick again: ' .. name .. ' has no art')
	end
	check_box(w.select, 'Thick again: the dropdown')
	eq(atlases_of(w.select), '', 'Thick again: the dropdown has no art')
	for _, row in ipairs(w.select.caret) do
		check(row:IsShown(), 'Thick again: the caret')
		eq(row:GetTexture(), st.icons.chevronDown, "Lucide's chevron-down")
	end
	eq(w.select.text:GetJustifyH(), 'LEFT', 'Thick again: the text from the left')
	for name, nudge in pairs(nudges) do
		eq(atlases_of(nudge), '', 'Thick again: ' .. name .. ' has no art')
		check(nudge.arrow:IsShown(), 'Thick again: ' .. name .. "'s chevron")
		check_box(nudge:GetParent(), 'Thick again: ' .. name .. "'s box")
	end
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)
