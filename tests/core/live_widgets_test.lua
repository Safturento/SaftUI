-- Core's widgets follow a color at once (live colors, Task 2): a SaftUI
-- button's highlight and pressed fill, a check box's checked fill and
-- highlight, a scroll bar thumb, a radio group's picked button, an action
-- button's hover, the resize corner, a close button, and the edit mode grid's
-- centre lines. Each case draws the widget, then changes the color as an edit
-- does (C.edit: set the color, one frame) and reads it back; the cost cases
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

local st = T.client('forever')
load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
load_saftui('SaftUI-Core/Widgets/scrollbar.lua')
load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
load_editmode()

local function color(group, key) return st.config.profile.colors[group][key] end

-- Theme > Accent, set as its row does inside an edit.
local function accent(r, g, b)
	C.edit(st, function()
		st.config.profile.theme.accent:SetRGB(r, g, b)
		st:ColorChanged('accent')
		C.step(st)
	end)
end
local function restore_accent()
	local d = st.defaults.theme.accent
	st.config.profile.theme.accent:SetRGB(d.r, d.g, d.b)
end

-- Sets a Buttons color and tells the mechanism, as the Colors row does inside an edit.
local function pick(group, key, r, g, b, a)
	C.edit(st, function()
		local c = color(group, key)
		c:SetRGB(r, g, b)
		if a then c.a = a end
		st:ColorChanged(group, key)
		C.step(st)
	end)
end

local function reset_colors()
	for _, key in ipairs({ 'normal', 'hover', 'pushed' }) do
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

test("a SaftUI button's highlight and pressed fill follow Buttons > Normal and Pushed at their opacity; Hover changes neither", function()
	reset_colors()
	local button = CreateFrame('Button', nil, UIParent)
	st:SkinButton(button)
	pick('button', 'normal', 0.2, 0.4, 0.6, 0.5)
	eq(text(button.hover:GetVertexColor()), text(0.2, 0.4, 0.6, 0.5), 'the highlight follows Normal at 50%')
	pick('button', 'pushed', 0.6, 0.4, 0.2, 0.5)
	eq(text(button.pushed:GetVertexColor()), text(0.6, 0.4, 0.2, 0.5), 'the pressed fill follows Pushed')
	local hover, pushed = text(button.hover:GetVertexColor()), text(button.pushed:GetVertexColor())
	pick('button', 'hover', 0.9, 0.9, 0.1)
	eq(text(button.hover:GetVertexColor()), hover, 'Hover leaves the highlight')
	eq(text(button.pushed:GetVertexColor()), pushed, 'and the pressed fill')
end)

test("a check box's checked fill and highlight follow Hover and Normal; a bare one too; none under Blizzard", function()
	reset_colors()
	local box = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(box)
	local bare = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(bare, 'bare')
	pick('button', 'hover', 0.9, 0.2, 0.6, 0.5)
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(0.9, 0.2, 0.6, 0.5), 'the checked fill follows Hover')
	eq(text(bare:GetCheckedTexture():GetVertexColor()), text(0.9, 0.2, 0.6, 0.5), 'a bare one too')
	pick('button', 'normal', 0.1, 0.8, 0.3, 0.4)
	eq(text(box:GetHighlightTexture():GetVertexColor()), text(0.1, 0.8, 0.3, 0.4), 'the highlight follows Normal')
	eq(text(bare:GetHighlightTexture():GetVertexColor()), text(0.1, 0.8, 0.3, 0.4), 'a bare one too')
	local before = text(box:GetCheckedTexture():GetVertexColor())
	pick('button', 'pushed', 0.3, 0.3, 0.3)
	eq(text(box:GetCheckedTexture():GetVertexColor()), before, 'Pushed is not read')

	T.theme('blizzard')
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(1, 1, 1, 1), 'Blizzard: the art is white')
	pick('button', 'hover', 0.5, 0.5, 0.9)
	pick('button', 'normal', 0.5, 0.5, 0.9)
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(1, 1, 1, 1), 'and a pass does not tint it')
	eq(text(box:GetHighlightTexture():GetVertexColor()), text(1, 1, 1, 1), 'nor its highlight')
	T.theme('thick')
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(0.5, 0.5, 0.9, 1), 'back under Thick it draws the color as it is now')
end)

test('a scroll bar thumb follows the key of its state: Normal at rest, Hover under the mouse, Pushed held', function()
	reset_colors()
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = bar:GetThumb()
	local function fill() return text(thumb.backdrop:GetBackdropColor()) end
	pick('button', 'normal', 0.2, 0.3, 0.4)
	eq(fill(), text(0.2, 0.3, 0.4, 1), 'at rest: Normal')
	stub.fire_script(thumb, 'OnEnter')
	pick('button', 'normal', 0.3, 0.3, 0.4)
	eq(fill(), text(0.3, 0.5, 0.7, 1), 'under the mouse: Normal changes nothing (it shows Hover, the default here)')
	pick('button', 'hover', 0.5, 0.6, 0.7)
	eq(fill(), text(0.5, 0.6, 0.7, 1), 'under the mouse: Hover')
	stub.fire_script(thumb, 'OnMouseDown')
	pick('button', 'pushed', 0.8, 0.1, 0.1, 0.5)
	eq(fill(), text(0.8, 0.1, 0.1, 0.5), 'held: Pushed')
	stub.fire_script(thumb, 'OnMouseUp')
	stub.fire_script(thumb, 'OnLeave')
	eq(fill(), text(0.3, 0.3, 0.4, 1), 'at rest again: Normal as it is now')
	T.theme('blizzard')
	local before = fill()
	pick('button', 'normal', 0.9, 0.9, 0.9)
	eq(fill(), before, 'under Blizzard the thumb is not painted')
end)

test("st:SkinActionButton's hover follows the Accent; under Blizzard's art it is not painted", function()
	reset_colors()
	local button = CreateFrame('CheckButton', nil, UIParent)
	st:SkinActionButton(button)
	accent(0.9, 0.5, 0.1)
	eq(text(button.hover:GetVertexColor()), text(0.9, 0.5, 0.1, 1), 'the hover is the Accent')
	restore_accent()

	T.theme('blizzard')
	st:SkinActionButton(button)
	local before = text(button.hover:GetVertexColor())
	accent(0.1, 0.5, 0.9)
	eq(text(button.hover:GetVertexColor()), before, "Blizzard's art shows: not tinted")
	restore_accent()
end)

test("the resize corner's pushed and highlight textures follow Hover", function()
	reset_colors()
	local frame = resizable()
	st:EnableResizing(frame)
	pick('button', 'hover', 0.9, 0.2, 0.6, 0.5)
	eq(text(frame.ResizeButton:GetPushedTexture():GetVertexColor()), text(0.9, 0.2, 0.6, 0.5), 'pushed')
	eq(text(frame.ResizeButton:GetHighlightTexture():GetVertexColor()), text(0.9, 0.2, 0.6, 0.5), 'highlight')
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

------------------------------------------------------------------ cost

for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
	test(('100 passes over 200 widgets make nothing and allocate under 4 KB (%s)'):format(theme), function()
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
		-- Each widget colored once: a cold stub widget makes its table at its first color call.
		st:ColorChanged('button', 'normal'); st:ColorChanged('button', 'hover'); st:ColorChanged('button', 'pushed')
		st:ColorChanged('accent')
		local flip = 0
		local m = C.measure(function()
			flip = 1 - flip
			color('button', 'normal'):SetRGB(0.2 + flip * 0.1, 0.3, 0.4)
			st:ColorChanged('button', 'normal')
		end, 100)
		eq(m.made, 0, 'nothing made')
		eq(m.forbidden.total, 0, 'nothing forbidden: ' .. (function()
			local out = {}
			for k, v in pairs(m.forbidden.by) do out[#out + 1] = k .. '=' .. v end
			return table.concat(out, ',')
		end)())
		check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
		if theme ~= 'blizzard' then check(m.calls.total >= 100 * 100, 'it does color: ' .. m.calls.total) end
		C.print('core widgets (' .. theme .. ')', m)
		local a = C.measure(function() st:ColorChanged('accent') end, 100)
		eq(a.forbidden.total, 0, 'an Accent pass: nothing forbidden')
		check(a.kb < 4, 'an Accent pass: garbage ' .. a.kb .. ' KB')
		reset_colors()
	end)
end
