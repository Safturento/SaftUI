-- SaftUI-Core/Config/optionsrange.lua, the range widget: a slider and its value
-- box, the numbers it snaps and shows, the slider's arrow buttons, and its
-- Blizzard art under SaftUI's theme Blizzard.
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
local range, bind, opt, check_no_box, shown_textures = H.range, H.bind, H.opt, H.check_no_box, H.shown_textures
local check_box, parent, rebind, art_inside, theme = H.check_box, H.parent, H.rebind, H.art_inside, H.theme
local INPUT_ART, atlases_of, inside, size_of, anchor = H.INPUT_ART, H.atlases_of, H.inside, H.size_of, H.anchor
local click = H.click

local function type_into(w, text)
	w.edit:SetText(text)
	stub.fire_script(w.edit, 'OnEnterPressed')
end

-- A button's first texture's atlas, and whether it's desaturated.
local function arrow_texture(button)
	for _, region in ipairs({ button:GetRegions() }) do
		if region:GetObjectType() == 'Texture' then return region end
	end
end
local function atlas_of(button) return arrow_texture(button):GetAtlas() end

------------------------------------------------------------------ range

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

-- The caret is Lucide's chevron-down, 16 px square. An even size on a whole-pixel
-- centre keeps its edges on whole pixels, so it doesn't blur.
test("select: the caret is a chevron-down texture on whole pixels", function()
	local w = bind('select', 'pick', opt('select', 'Pick', { values = { a = 'Alpha' }, get = function() return 'a' end, set = function() end }))
	eq(#w.frame.caret, 1, 'one caret texture')
	local caret = w.frame.caret[1]
	eq(caret:GetTexture(), st.icons.chevronDown, "Lucide's chevron-down")
	eq(caret:GetWidth(), 16); eq(caret:GetHeight(), 16)
	local point, relative, relPoint, x, y = caret:GetPoint(1)
	eq(point, 'CENTER'); eq(relative, w.frame); eq(relPoint, 'RIGHT')
	eq(x, math.floor(x), 'at a whole x'); eq(y, math.floor(y), 'and a whole y')
	eq(caret:GetWidth() % 2, 0, 'an even size')
end)

-- Today's caret colour, in every state: the colour of grey text, never changed by
-- the mouse, an open list or the select being disabled.
test("select: the caret stays grey at rest, hovered, open and disabled", function()
	local w = bind('select', 'pick', opt('select', 'Pick', { values = { a = 'Alpha' }, get = function() return 'a' end, set = function() end }))
	local grey = st.config.profile.colors.text.muted
	local caret = w.frame.caret[1]
	local function is_muted(state)
		local r, g, b = caret:GetVertexColor()
		eq(r, grey.r, state .. ': r'); eq(g, grey.g, state .. ': g'); eq(b, grey.b, state .. ': b')
		check(caret:IsShown(), state .. ': shown')
	end
	is_muted('rest')
	stub.fire_script(w.frame, 'OnEnter'); is_muted('hover')
	stub.fire_script(w.frame, 'OnLeave')
	click(w.frame); eq(W.ListOwner(), w.frame, 'the list is open'); is_muted('open')
	W.CloseList()
	w:SetDisabled(true); is_muted('disabled')
	w:SetDisabled(false)
end)

-- Blizzard's look keeps Blizzard's arrow (the face's own): no chevron of SaftUI's,
-- and Thick brings it back.
test("select: the caret is hidden under Blizzard and back under Thick", function()
	theme('thick')
	local w = bind('select', 'pick', opt('select', 'Pick', { values = { a = 'Alpha' }, get = function() return 'a' end, set = function() end }))
	check(w.frame.caret[1]:IsShown(), 'Thick: the chevron')
	theme('blizzard'); rebind(w)
	check(not w.frame.caret[1]:IsShown(), 'Blizzard: hidden')
	theme('thick'); rebind(w)
	check(w.frame.caret[1]:IsShown(), 'Thick again: the chevron')
	eq(w.frame.caret[1]:GetTexture(), st.icons.chevronDown, 'still the chevron')
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

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test('a range is a minimal slider with an input-art value box', function()
	theme('thick')
	local w = bind('range', 'size', opt('range', 'Size', {
		min = 0, max = 10, step = 1, get = function() return 5 end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local knob = w.slider:GetThumbTexture()
	eq(atlases_of(w.slider), '', 'Thick: no Blizzard art')
	eq(knob:GetTexture(), st.BLANK_TEX, 'Thick: the flat knob')
	eq(size_of(knob), '6x14', 'Thick: 6x14')
	local flat = #shown_textures(w.slider)
	check_box(w.edit, 'Thick: the value box')

	theme('blizzard')
	rebind(w)
	eq(atlases_of(w.slider), 'Minimal_SliderBar_Button,Minimal_SliderBar_Left,Minimal_SliderBar_Right,_Minimal_SliderBar_Middle',
		'the track and the thumb, and nothing flat')
	eq(knob:GetAtlas(), 'Minimal_SliderBar_Button', 'the thumb')
	eq(size_of(knob), '20x19', "at the atlas's size")
	check(not w.track:IsShown(), 'the flat track hidden')
	for _, region in ipairs(shown_textures(w.slider)) do
		if region ~= knob then check(inside(region, w.slider), tostring(region:GetAtlas()) .. ' inside the slider') end
	end
	eq(size_of(w.frame), '168x24', 'the range keeps its size')
	eq(size_of(w.slider), '88x24', 'and its slider, narrowed for the arrows')
	check_no_box(w.edit, 'the value box')
	eq(atlases_of(w.edit), INPUT_ART, 'the value box is a text box')
	art_inside(w.edit, 'the value box')
	eq(size_of(w.edit), '46x24', 'it keeps its size')

	theme('thick')
	rebind(w)
	eq(atlases_of(w.slider), '', 'Thick again: no Blizzard art')
	eq(knob:GetTexture(), st.BLANK_TEX, 'Thick again: the flat knob')
	eq(size_of(knob), '6x14', 'Thick again: 6x14')
	eq(#shown_textures(w.slider), flat, 'Thick again: the flat track')
	check_box(w.edit, 'Thick again: the value box')
	eq(atlases_of(w.edit), '', 'Thick again: no art on the value box')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test("under Blizzard a range has the minimal slider's end arrows inside its 116", function()
	theme('thick')
	local w = bind('range', 'size', opt('range', 'Size', {
		min = 0, max = 10, step = 1, get = function() return 5 end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	local names = { [w.frame] = 'frame', [w.slider] = 'slider' }
	check(not w.backArrow:IsShown() and not w.forwardArrow:IsShown(), 'Thick: no arrows')
	eq(w.backArrow:GetParent(), w.frame); eq(w.forwardArrow:GetParent(), w.frame)
	theme('blizzard'); rebind(w)
	check(w.backArrow:IsShown() and w.forwardArrow:IsShown())
	eq(atlas_of(w.backArrow), 'Minimal_SliderBar_Button_Left'); eq(size_of(w.backArrow), '11x19'); eq(anchor(w.backArrow, names), 'TOPLEFT frame TOPLEFT 0,-2')
	eq(anchor(w.slider, names), 'LEFT frame LEFT 15,0'); eq(size_of(w.slider), '88x24')
	eq(atlas_of(w.forwardArrow), 'Minimal_SliderBar_Button_Right'); eq(size_of(w.forwardArrow), '9x18'); eq(anchor(w.forwardArrow, names), 'TOPLEFT frame TOPLEFT 107,-3')
	eq(size_of(w.frame), '168x24'); eq(size_of(w.edit), '46x24')
	theme('thick'); rebind(w)
	check(not w.backArrow:IsShown() and not w.forwardArrow:IsShown(), 'Thick again: no arrows')
	eq(size_of(w.slider), '116x24'); eq(anchor(w.slider, names), 'LEFT frame LEFT 0,0')
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

-- From here the cases type into a box, as options_position_test.lua's do.
local type_into = H.type_into

test("a slider arrow steps by the option's step through the same path as a drag, clamped, disabled at the ends", function()
	theme('blizzard')
	local w, told, sets, get = range({ value = 5, min = 0, max = 10, step = 1 })
	click(w.forwardArrow)
	eq(get(), 6); eq(#sets, 1); eq(told.n, 1, 'the window is told once, as a drag is')
	click(w.backArrow); eq(get(), 5)
	check(w.forwardArrow:IsEnabled() and w.backArrow:IsEnabled())
	check(not arrow_texture(w.backArrow):IsDesaturated(), 'enabled: in colour')
	type_into(w.edit, '10')
	check(not w.forwardArrow:IsEnabled(), 'at the top, forward is disabled'); check(w.backArrow:IsEnabled())
	check(arrow_texture(w.forwardArrow):IsDesaturated(), 'a disabled arrow is desaturated')
	check(not arrow_texture(w.backArrow):IsDesaturated())
	eq(stub.try_click(w.forwardArrow), false, 'a disabled arrow takes no click'); eq(get(), 10, 'no step past the end')
	type_into(w.edit, '0')
	check(not w.backArrow:IsEnabled(), 'at the bottom, back is disabled'); check(w.forwardArrow:IsEnabled())
	check(not arrow_texture(w.forwardArrow):IsDesaturated(), 'enabled again: in colour')
	w:SetDisabled(true)
	check(not w.forwardArrow:IsEnabled() and not w.backArrow:IsEnabled(), 'a disabled range has both off')
	w:SetDisabled(false)
	check(w.forwardArrow:IsEnabled() and not w.backArrow:IsEnabled())
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test('slider arrow edge cases', function()
	theme('blizzard')
	-- A percent: 0.5 and 0.05 make 0.55, shown as 55%.
	local p, _, _, pget = range({ value = 0.5, min = 0, max = 1, step = 0.05, isPercent = true })
	click(p.forwardArrow); eq(pget(), 0.55); eq(p.edit:GetText(), '55%')
	p:Release()
	-- No step and no bigStep: a hundredth of the span.
	local h, _, _, hget = range({ value = 100, softMin = 0, softMax = 200 })
	click(h.forwardArrow); eq(hget(), 102)
	h:Release()
	-- A soft max under the hard one: forward is off past it, back lands on it.
	local s, _, _, sget = range({ value = 50, min = 0, max = 100, softMax = 10, step = 1 })
	check(not s.forwardArrow:IsEnabled(), 'at or past the slider end')
	click(s.backArrow); eq(sget(), 10)
	s:Release()
	-- A bigStep is for the drag; an arrow moves by step.
	local b, _, _, bget = range({ value = 5, min = 0, max = 10, step = 1, bigStep = 5 })
	click(b.forwardArrow); eq(bget(), 6)
	b:Release()
	-- No value: the arrows read from the slider's low end.
	local n = range({ value = nil, min = 0, max = 10, step = 1 })
	check(not n.backArrow:IsEnabled() and n.forwardArrow:IsEnabled())
	n:Release()
	-- A bigStep and no step: an arrow moves by bigStep.
	local g, _, _, gget = range({ value = 10, min = 0, max = 100, bigStep = 10 })
	click(g.forwardArrow); eq(gget(), 20, 'bigStep only: forward by bigStep')
	click(g.backArrow); click(g.backArrow); eq(gget(), 0, 'and back')
	g:Release()
	-- 0.1 ten times from 0: each step on the grid, landing exactly on 1.
	local d, _, _, dget = range({ value = 0, min = 0, max = 1, step = 0.1 })
	for i = 1, 10 do
		click(d.forwardArrow)
		eq(dget(), tonumber(('%.1f'):format(i / 10)), 'step ' .. i .. ': no float drift')
	end
	check(dget() == 1, 'exactly 1')
	check(not d.forwardArrow:IsEnabled(), 'at the top: forward off')
	d:Release()
	-- A validate that fails: the step sets nothing, the window is told why,
	-- and the box still shows the value.
	local value, sets = 5, 0
	local v, told = bind('range', 'amount', opt('range', 'Amount', {
		min = 0, max = 10, step = 1,
		get = function() return value end,
		set = function(_, x) sets = sets + 1; value = x end,
		validate = function() return 'Not that' end,
	}))
	click(v.forwardArrow)
	eq(value, 5, 'a failed validate blocks the step'); eq(sets, 0)
	eq(told.n, 1); eq(told.ok, false); eq(told.err, 'Not that', 'onChanged(false, message)')
	eq(v.edit:GetText(), '5', 'the box still shows 5')
	v:Release()
	eq(#take_errors(), 0, 'no errors')
end)
