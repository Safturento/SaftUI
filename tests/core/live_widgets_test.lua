-- Core's widgets follow a color at once (live colors, Task 2): a SaftUI
-- button's states, a check box's mark and edge, a scroll bar thumb, a radio
-- group's picked button, an action button's hover and the resize corner (each
-- the Accent's, through the helpers: Widgets/states.lua), a close button, and
-- the edit mode grid's centre lines. What each state draws is in
-- widget_states_test.lua; here each follows a change of the Accent (and ignores
-- the Buttons colors Normal, Hover, Pushed and Checked, which they no longer read). Each case draws the widget, then changes the color as an edit
-- does outside an edit (set the color, say st:ColorChanged: only that color's
-- pass runs, so a follower under the wrong key fails) and reads it back; the cost cases
-- measure st:ColorChanged outside an edit (tests/lib/color_cost.lua).
-- Edit mode's bar, list and status line are in editmode_colors_test.lua; the
-- /sui grip is in options_resize_test.lua.
--
-- Real: Core's helpers (Widgets/button.lua, skinning.lua, panels.lua, theme),
-- the check box, scroll bar and radio group widgets, the real color mechanism
-- (Media/colors.lua), edit mode's grid and bar.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local text = T.text
local function SL_rgb(t) return text(t.r, t.g, t.b) end

local st
-- A fresh world: Core's helpers, the widgets and edit mode's real files.
local function build()
	st = T.client('forever')
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	load_saftui('SaftUI-Core/Widgets/scrollbar.lua')
	load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
	load_editmode()
end
build()

local function color(group, key) return st.config.profile.colors[group][key] end

-- Theme > Accent, set as its row does, outside an edit (only its pass runs).
local function accent(r, g, b)
	st.config.profile.theme.accent:SetRGB(r, g, b)
	st:ColorChanged('accent')
end
local function restore_accent()
	local d = st.defaults.theme.accent
	st.config.profile.theme.accent:SetRGB(d.r, d.g, d.b)
end

-- Sets a color and tells the mechanism outside an edit: only that color's pass
-- runs, so a follower under the wrong key, or none, is seen (an edit's end
-- would run the group's whole pass over it).
local function pick(group, key, r, g, b, a)
	local c = color(group, key)
	c:SetRGB(r, g, b)
	if a then c.a = a end
	st:ColorChanged(group, key)
end

local function reset_colors()
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'checked' }) do
		local default = st.defaults.colors.button[key]
		color('button', key):SetRGB(default.r, default.g, default.b)
		color('button', key).a = 1
	end
	color('text', 'muted'):SetRGB(st.defaults.colors.text.muted.r, st.defaults.colors.text.muted.g, st.defaults.colors.text.muted.b)
	color('text', 'danger'):SetRGB(st.defaults.colors.text.danger.r, st.defaults.colors.text.danger.g, st.defaults.colors.text.danger.b)
	T.theme('thick')
end

local function scrollBar()
	local bar = CreateFrame('Frame', nil, UIParent)
	local parts = {}
	for _, key in ipairs({ 'thumb', 'track', 'forward', 'back' }) do
		parts[key] = CreateFrame('Button', nil, bar)
		parts[key]:SetSize(8, 20)
		parts[key]:SetPoint('CENTER')
	end
	function bar:GetThumb() return parts.thumb end
	function bar:GetTrack() return parts.track end
	function bar:GetForwardStepper() return parts.forward end
	function bar:GetBackStepper() return parts.back end
	return bar
end

local function resizable()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame.SetResizable = function() end
	return frame
end

------------------------------------------------------------------ one case a reader

-- What a state's color is now (the cache), as the helpers draw it.
local function state(name) return text(st:StateColor(name)) end
local function layer_of(frame) return text(st:StateLook(frame).layer.r, st:StateLook(frame).layer.g, st:StateLook(frame).layer.b, st:StateLook(frame).layer.a) end

test("a SaftUI button's hover and pushed tint follow the Accent; the Buttons colors change neither", function()
	reset_colors()
	local button = CreateFrame('Button', nil, UIParent)
	st:SkinButton(button)
	stub.fire_script(button, 'OnEnter', true)
	accent(0.2, 0.4, 0.6)
	eq(layer_of(button), state('hover'), 'the hover follows the Accent')
	check(st:StateLook(button).layer.b > st:StateLook(button).layer.r, 'and it is the new one: ' .. layer_of(button))
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq(layer_of(button), state('pushed'), 'pushed follows it too')
	local before = layer_of(button)
	pick('button', 'hover', 0.9, 0.9, 0.1)
	pick('button', 'pushed', 0.9, 0.9, 0.1)
	pick('button', 'normal', 0.9, 0.9, 0.1)
	pick('button', 'checked', 0.9, 0.9, 0.1)
	eq(layer_of(button), before, 'Buttons > Hover, Pushed, Normal and Checked are not read')
	restore_accent()
end)

test("a check box's mark and edge follow the Accent; a bare one's checked texture follows nothing; none under Blizzard", function()
	reset_colors()
	local box = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(box)
	local bare = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(bare, 'bare')
	box:SetChecked(true)
	accent(0.9, 0.2, 0.6)
	local look = st:StateLook(box)
	eq(text(look.mark.r, look.mark.g, look.mark.b), text(0.9, 0.2, 0.6), 'the mark is the Accent')
	eq(T.edge(box.backdrop), text(0.9, 0.2, 0.6, 1), 'and the edge')
	-- A bare one is restyled by its caller (the bags' veil and eye): its checked texture follows nothing.
	bare:GetCheckedTexture():SetVertexColor(0, 0, 0, 0.6)
	accent(0.1, 0.8, 0.3)
	eq(text(bare:GetCheckedTexture():GetVertexColor()), text(0, 0, 0, 0.6), "a bare one: its caller's checked color stays")
	st:ColorsChanged('button'); st:ColorsChanged('accent')
	eq(text(bare:GetCheckedTexture():GetVertexColor()), text(0, 0, 0, 0.6), 'through a whole pass too')
	pick('button', 'checked', 0.3, 0.3, 0.3)
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(0.1, 0.8, 0.3, 1), 'Buttons > Checked is not read')

	T.theme('blizzard')
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(1, 1, 1, 1), 'Blizzard: the art is white')
	accent(0.5, 0.5, 0.9)
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(1, 1, 1, 1), 'and a pass does not tint it')
	eq(text(box:GetHighlightTexture():GetVertexColor()), text(1, 1, 1, 1), 'nor its highlight')
	T.theme('thick')
	local back = st:StateLook(box).mark
	eq(text(back.r, back.g, back.b), text(0.5, 0.5, 0.9), 'back under Thick it draws the Accent as it is now')
	restore_accent()
end)

test("a 'button'-style check box (the currency funnel) follows the Accent while checked; none under Blizzard", function()
	reset_colors()
	local box = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(box, 'button')
	box:SetChecked(true)
	accent(0.9, 0.2, 0.6)
	eq(T.edge(box.backdrop), text(0.9, 0.2, 0.6, 1), 'the checked edge: the Accent')
	local fill = st:StateLook(box).fill
	eq(text(fill.r, fill.g, fill.b), text(0.9, 0.2, 0.6), 'and the fade')
	T.theme('blizzard')
	eq(st:StateLook(box).fill.alpha, 0, 'Blizzard: held')
	local edge = T.edge(box.backdrop)
	accent(0.5, 0.5, 0.9)
	eq(T.edge(box.backdrop), edge, 'Blizzard: its border is not painted')
	restore_accent()
end)

test('a scroll bar thumb rests at kit-edge, and follows the Accent under the mouse and held; Buttons > Normal is not read', function()
	reset_colors()
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = bar:GetThumb()
	local function fill() return text(thumb.backdrop:GetBackdropColor()) end
	local rest = text(unpack(st.States.THUMB_REST))
	pick('button', 'normal', 0.2, 0.3, 0.4)
	eq(fill(), rest, 'at rest: kit-edge, whatever Normal is')
	stub.fire_script(thumb, 'OnEnter', true)
	accent(0.5, 0.6, 0.7)
	local over = st:StateLook(thumb).solid
	check(over.r ~= st.States.THUMB_REST[1] and fill() ~= rest, 'under the mouse: lighter, the Accent: ' .. fill())
	eq(text(over.r, over.g, over.b), text(thumb.backdrop:GetBackdropColor()):sub(1, 14), 'and it is the one drawn')
	stub.fire_script(thumb, 'OnMouseDown', 'LeftButton')
	local held = fill()
	check(held ~= text(over.r, over.g, over.b, 1), 'held: the pushed tone ' .. held)
	stub.fire_script(thumb, 'OnMouseUp', 'LeftButton')
	stub.fire_script(thumb, 'OnLeave', true)
	eq(fill(), rest, 'at rest again')
	T.theme('blizzard')
	local before = fill()
	accent(0.9, 0.9, 0.9)
	eq(fill(), before, 'under Blizzard the thumb is not painted')
	restore_accent()
end)

test("st:SkinActionButton's hover and pushed follow the Accent; under Blizzard's art they are not painted", function()
	reset_colors()
	local button = CreateFrame('CheckButton', nil, UIParent)
	st:SkinActionButton(button)
	accent(0.9, 0.5, 0.1)
	local hover = st:StateLook(button).hover_piece
	eq(text(hover.r, hover.g, hover.b, hover.a), state('hover'), 'the hover is the tone of the Accent')
	check(hover.r > hover.b, 'and it is the new Accent: ' .. SL_rgb(hover))
	restore_accent()

	T.theme('blizzard')
	st:SkinActionButton(button)
	local before = text(button.hover:GetVertexColor())
	accent(0.1, 0.5, 0.9)
	eq(text(button.hover:GetVertexColor()), before, "Blizzard's art shows: not tinted")
	restore_accent()
end)

test("the resize corner's states follow the Accent", function()
	reset_colors()
	local frame = resizable()
	st:EnableResizing(frame)
	stub.fire_script(frame.ResizeButton, 'OnEnter', true)
	accent(0.9, 0.2, 0.6)
	local r, g, b = frame.ResizeButton:GetNormalTexture():GetVertexColor()
	check(r > b and r > g, 'under the mouse: the lighter tone of the new Accent: ' .. text(r, g, b))
	local pr, pg, pb = frame.ResizeButton:GetHighlightTexture():GetVertexColor()
	eq(text(pr, pg, pb), text(r, g, b), 'highlight')
	pick('button', 'hover', 0.1, 0.1, 0.9)
	eq(T.rgb(frame.ResizeButton:GetNormalTexture():GetVertexColor()), T.rgb(r, g, b), 'Buttons > Hover is not read')
	restore_accent()
end)

test("a radio group's picked button follows the Accent; the others keep the theme's border", function()
	reset_colors()
	local group = st:CreateRadioGroup('LiveTabs', UIParent, {
		buttonHeight = 30, buttonWidth = 100, buttonSpacing = 6, theme = 'theme', background = 'theme',
		items = { { label = 'One' }, { label = 'Two' } },
	})
	group:SetPoint('CENTER')
	local one, two = group.buttons[1], group.buttons[2]
	local edge = T.edge(two.backdrop)
	local own = T.edge(one.backdrop)
	stub.fire_script(two, 'OnClick', 'LeftButton', false)
	accent(0.9, 0.5, 0.1)
	eq(T.edge(two.backdrop), text(0.9, 0.5, 0.1, 1), 'the picked button')
	eq(T.edge(one.backdrop), own, 'the other keeps its border')
	stub.fire_script(one, 'OnClick', 'LeftButton', false)
	accent(0.1, 0.5, 0.9)
	eq(T.edge(one.backdrop), text(0.1, 0.5, 0.9, 1), 'the pick moved: this one now')
	check(T.edge(two.backdrop) ~= text(0.1, 0.5, 0.9, 1), 'and the first is not painted')
	restore_accent()
	eq(edge ~= nil, true)
end)

test("a close button's cross follows Muted at rest and Danger under the mouse; none under Blizzard", function()
	reset_colors()
	local frame = CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(frame)
	local x = close.icon
	pick('text', 'muted', 0.2, 0.7, 0.3)
	eq(text(x:GetVertexColor()), text(0.2, 0.7, 0.3, 1), 'at rest: Muted')
	pick('text', 'danger', 0.9, 0.1, 0.1)
	eq(text(x:GetVertexColor()), text(0.2, 0.7, 0.3, 1), 'Danger is not read at rest')
	stub.fire_script(close, 'OnEnter', true)
	eq(text(x:GetVertexColor()), text(0.9, 0.1, 0.1, 1), 'under the mouse: Danger')
	eq(T.edge(close), text(0.9, 0.1, 0.1, 1), 'and its edge')
	pick('text', 'danger', 0.5, 0.1, 0.8)
	eq(text(x:GetVertexColor()), text(0.5, 0.1, 0.8, 1), 'Danger followed under the mouse')
	pick('text', 'muted', 0.3, 0.3, 0.3)
	eq(text(x:GetVertexColor()), text(0.5, 0.1, 0.8, 1), 'Muted is not read under the mouse')
	stub.fire_script(close, 'OnLeave', true)
	eq(text(x:GetVertexColor()), text(0.3, 0.3, 0.3, 1), 'at rest: Muted as it is now')

	T.theme('blizzard')
	local before = text(x:GetVertexColor())
	pick('text', 'muted', 0.9, 0.9, 0.9)
	eq(text(x:GetVertexColor()), before, 'Blizzard: its cross is hidden, not painted')
end)

test("the grid's centre lines follow the Accent, nothing redrawn", function()
	reset_colors()
	local EM = st.EditModeFrames
	EM.active = true
	EM:GetSettings().grid = true
	EM:UpdateGrid()
	local lines = {}
	for _, region in ipairs({ EM.gridFrame:GetRegions() }) do
		if region:IsShown() then lines[#lines + 1] = region end
	end
	check(#lines > 2, 'the grid is drawn')
	local function colorOf(line) return text(unpack(stub.state(line).color_texture)) end
	local before = {}
	for i, line in ipairs(lines) do before[i] = colorOf(line) end
	local draws = 0
	local real = EM.UpdateGrid
	EM.UpdateGrid = function(...) draws = draws + 1; return real(...) end
	accent(0.9, 0.5, 0.1)
	EM.UpdateGrid = real
	eq(draws, 0, 'nothing redrawn')
	local changed = 0
	for i, line in ipairs(lines) do
		if colorOf(line) ~= before[i] then
			changed = changed + 1
			eq(colorOf(line), text(0.9, 0.5, 0.1, 0.9), 'a centre line: the Accent at its alpha')
		end
	end
	eq(changed, 2, 'the two centre lines')
	restore_accent()

	EM.active = false
	EM:UpdateGrid()
end)

test("a pass of a color no widget reads paints nothing: Buttons > Danger, Class > Mage", function()
	reset_colors()
	for i = 1, 3 do
		local button = CreateFrame('Button', nil, UIParent); st:SkinButton(button)
		local box = CreateFrame('CheckButton', nil, UIParent); st:SkinCheckButton(box)
		local bar = scrollBar(); st:SkinNewScrollBar(bar)
	end
	local m = C.measure(function()
		st:ColorChanged('button', 'danger')
		st:ColorChanged('class', 'MAGE')
	end, 10)
	eq(m.calls.total, 0, 'no setter called')
	eq(m.forbidden.total, 0)
end)

test('a whole pass paints every reader as the per-key passes do', function()
	reset_colors()
	local button = CreateFrame('Button', nil, UIParent); st:SkinButton(button)
	local frame = CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(frame)
	stub.fire_script(button, 'OnEnter', true)
	st.config.profile.theme.accent:SetRGB(0.3, 0.2, 0.1)
	color('text', 'muted'):SetRGB(0.6, 0.5, 0.4)
	st:ColorsChanged('accent'); st:ColorsChanged('text')
	eq(layer_of(button), state('hover'), 'a button hover tint, the tone of the Accent')
	restore_accent()
	eq(text(close.icon:GetVertexColor()), text(0.6, 0.5, 0.4, 1), 'a close cross')
end)

------------------------------------------------------------------ cost

for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
	test(('100 passes over 200 widgets make nothing and allocate under 4 KB (%s)'):format(theme), function()
		build() -- a fresh world per theme: no widgets piling up from the cases before
		reset_colors()
		T.theme(theme)
		local list = {}
		for i = 1, 50 do
			local button = CreateFrame('Button', nil, UIParent); st:SkinButton(button)
			local box = CreateFrame('CheckButton', nil, UIParent); st:SkinCheckButton(box)
			local bar = scrollBar(); st:SkinNewScrollBar(bar)
			local action = CreateFrame('CheckButton', nil, UIParent); st:SkinActionButton(action)
			list[#list + 1] = { button, box, bar, action }
		end
		-- A few in each state, so a pass has something to color (the rest cost one call).
		for i = 1, 10 do
			stub.fire_script(list[i][1], 'OnEnter', true)
			list[i][2]:SetChecked(true)
			stub.fire_script(list[i][3]:GetThumb(), 'OnEnter', true)
		end
		-- Each widget colored once: a cold stub widget makes its table at its first color call.
		st:ColorChanged('accent')
		local flip = 0
		local m = C.measure(function()
			flip = 1 - flip
			st.config.profile.theme.accent:SetRGB(0.2 + flip * 0.1, 0.5, 0.8)
			st:ColorChanged('accent')
		end, 100)
		restore_accent()
		eq(m.made, 0, 'nothing made')
		eq(m.forbidden.total, 0, 'nothing forbidden: ' .. (function()
			local out = {}
			for k, v in pairs(m.forbidden.by) do out[#out + 1] = k .. '=' .. v end
			return table.concat(out, ',')
		end)())
		check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
		if theme ~= 'blizzard' then check(m.calls.total >= 100 * 30, 'it does color: ' .. m.calls.total) end
		C.print('core widgets (' .. theme .. ', 200 widgets)', m)
		local a = C.measure(function() st:ColorChanged('accent') end, 100)
		eq(a.forbidden.total, 0, 'an Accent pass: nothing forbidden')
		check(a.kb < 4, 'an Accent pass: garbage ' .. a.kb .. ' KB')
		reset_colors()
	end)
end
