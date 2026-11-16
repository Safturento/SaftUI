-- The Buttons section's opacity is drawn: every Buttons reader in Core draws its
-- color at its own strength times the color's opacity
-- (st:ColorRGBA('button', key, strength)). At the defaults (100%) every reader
-- draws the alpha it drew before; at 50% half of it. Each case sets the colors
-- to values that are not the defaults, so a reader that hardcodes the shipped
-- color, or a strength, fails.
--
-- Core's readers: a SaftUI button's highlight and pushed fill
-- (Widgets/button.lua), a check box's checked fill and highlight, flat and
-- 'bare' (Widgets/checkbutton.lua), a scroll bar thumb at rest, under the mouse
-- and pressed (Widgets/scrollbar.lua), and st:EnableResizing's corner
-- (skinning.lua). The options window's grip is in options_resize_test.lua.
--
-- Real: Core's helpers (Widgets/button.lua, skinning.lua), the check box and
-- scroll bar widgets, and the real defaults.
local T = load_test_file('lib/theme_helpers.lua')
local text = T.text

local st = T.client('forever')
load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
load_saftui('SaftUI-Core/Widgets/scrollbar.lua')

-- Not the defaults: the shipped Normal is 0.1, 0.1, 0.1, Hover 0.3, 0.5, 0.7
-- and Pushed 0.3, 0.4, 0.5.
local COLOR = {
	normal = { 0.2, 0.7, 0.4 },
	hover = { 0.9, 0.2, 0.6 },
	pushed = { 0.5, 0.8, 0.1 },
	checked = { 0.2, 0.3, 0.9 },
}
-- What a hover highlight draws: Hover at 0.4 times its opacity (st.HOVER_TINT).
local TINT = 0.4

-- Sets Normal, Hover and Pushed to the odd colors, each at opacity a.
local function paint(a)
	for key, rgb in pairs(COLOR) do
		local c = st.config.profile.colors.button[key]
		c:SetRGB(unpack(rgb))
		c.a = a
	end
end

local function want(key, strength)
	local rgb = COLOR[key]
	return text(rgb[1], rgb[2], rgb[3], strength * (st.config.profile.colors.button[key].a or 1))
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

-- The stubs' frames have no SetResizable, which st:EnableResizing calls.
local function resizable()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame.SetResizable = function() end
	return frame
end

-- Every reader, drawn now, against the opacity a (a strength of 1 each).
local function readers(a, label)
	paint(a)

	local button = CreateFrame('Button', nil, UIParent)
	st:SkinButton(button)
	eq(text(button.hover:GetVertexColor()), want('hover', TINT), label .. ': a button highlight, Hover at 0.4')
	eq(text(button.pushed:GetVertexColor()), want('pushed', 1), label .. ': a button pushed fill, Pushed')

	local box = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(box)
	eq(text(box:GetCheckedTexture():GetVertexColor()), want('checked', 1), label .. ': a check box fill, Checked')
	eq(text(box:GetHighlightTexture():GetVertexColor()), want('hover', TINT), label .. ': a check box highlight, Hover at 0.4')
	-- Drawn again as the theme switches, flat each time.
	T.theme('blizzard'); T.theme('thick')
	eq(text(box:GetCheckedTexture():GetVertexColor()), want('checked', 1), label .. ': the fill again after a theme switch')
	eq(text(box:GetHighlightTexture():GetVertexColor()), want('hover', TINT), label .. ': the highlight again after a theme switch')

	local bare = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(bare, 'bare')
	eq(text(bare:GetCheckedTexture():GetVertexColor()), want('checked', 1), label .. ': a bare check box fill, Checked')
	eq(text(bare:GetHighlightTexture():GetVertexColor()), want('hover', TINT), label .. ': a bare check box highlight, Hover at 0.4')

	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = bar:GetThumb()
	local function fill() return text(thumb.backdrop:GetBackdropColor()) end
	eq(fill(), want('normal', 1), label .. ': a scroll bar thumb at rest, Normal')
	stub.fire_script(thumb, 'OnEnter')
	eq(fill(), want('hover', 1), label .. ': under the mouse, Hover')
	stub.fire_script(thumb, 'OnMouseDown')
	eq(fill(), want('pushed', 1), label .. ': pressed, Pushed')
	stub.fire_script(thumb, 'OnMouseUp')
	stub.fire_script(thumb, 'OnLeave')
	eq(fill(), want('normal', 1), label .. ': at rest again')
	T.theme('blizzard'); T.theme('thick')
	eq(fill(), want('normal', 1), label .. ': and after a theme switch')

	local frame = resizable()
	st:EnableResizing(frame)
	eq(text(frame.ResizeButton:GetPushedTexture():GetVertexColor()), want('hover', 1), label .. ': a resize corner pressed, Hover')
	eq(text(frame.ResizeButton:GetHighlightTexture():GetVertexColor()), want('hover', 1), label .. ': a resize corner under the mouse, Hover')
end

test('the defaults draw every Buttons color fully: 100% opacity, so every reader draws its own strength', function()
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'checked', 'danger' }) do
		eq(st.defaults.colors.button[key].a, 1, 'Buttons > ' .. key .. ' defaults at 100%')
		eq(st.config.profile.colors.button[key].a, 1, 'and so does the profile')
	end
	eq(text(st.defaults.colors.button.normal:GetRGB()), '0.10,0.10,0.10')
	eq(text(st.defaults.colors.button.hover:GetRGB()), '0.30,0.50,0.70')
	eq(text(st.defaults.colors.button.pushed:GetRGB()), '0.30,0.40,0.50')
	eq(text(st.defaults.colors.button.danger:GetRGB()), '0.60,0.10,0.10')
	eq(text(st.defaults.colors.button.checked:GetRGB()), '0.30,0.50,0.70', "Checked starts as Hover's default, so a checked box looks as it did")
end)

test('at 100% every reader draws the alpha it drew before: its own strength', function()
	readers(1, '100%')
end)

test('at 50% each draws half its strength', function()
	readers(0.5, '50%')
end)

test('at 0% nothing of a Buttons color is drawn, and no reader raises', function()
	readers(0, '0%')
end)

test('a color with no opacity of its own reads as fully opaque', function()
	paint(1)
	st.config.profile.colors.button.hover.a = nil
	local frame = resizable()
	st:EnableResizing(frame)
	eq(text(frame.ResizeButton:GetPushedTexture():GetVertexColor()), text(COLOR.hover[1], COLOR.hover[2], COLOR.hover[3], 1))
	st.config.profile.colors.button.hover.a = 1
end)

test('st:ColorRGBA allocates nothing per read, ten thousand times', function()
	paint(0.5)
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = bar:GetThumb()
	stub.fire_script(thumb, 'OnEnter')
	collectgarbage(); collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, 10000 do st:ColorRGBA('button', 'hover', 1) end
	local grown = collectgarbage('count') - before
	collectgarbage('restart')
	check(grown < 20, 'st:ColorRGBA makes no table per read (grew ' .. grown .. ' KB)')
end)

test('a pick reaches every reader at once, at its opacity (live colors)', function()
	local C = load_test_file('lib/color_cost.lua')
	paint(1)
	local button = CreateFrame('Button', nil, UIParent)
	st:SkinButton(button)
	local box = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(box)
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local frame = resizable()
	st:EnableResizing(frame)
	-- Outside an edit: only each color's own pass runs, so a follower under the wrong key fails.
	for key, rgb in pairs({ normal = { 0.1, 0.9, 0.2 }, hover = { 0.8, 0.2, 0.7 }, pushed = { 0.6, 0.6, 0.1 }, checked = { 0.3, 0.7, 0.2 } }) do
		local c = st.config.profile.colors.button[key]
		c:SetRGB(unpack(rgb)); c.a = 0.5
		st:ColorChanged('button', key)
	end
	eq(text(button.hover:GetVertexColor()), text(0.8, 0.2, 0.7, 0.5 * TINT), 'a button highlight, Hover at 0.4')
	eq(text(button.pushed:GetVertexColor()), text(0.6, 0.6, 0.1, 0.5), 'a button pushed fill')
	eq(text(box:GetCheckedTexture():GetVertexColor()), text(0.3, 0.7, 0.2, 0.5), 'a check box fill, Checked')
	eq(text(box:GetHighlightTexture():GetVertexColor()), text(0.8, 0.2, 0.7, 0.5 * TINT), 'a check box highlight, Hover at 0.4')
	eq(text(bar:GetThumb().backdrop:GetBackdropColor()), text(0.1, 0.9, 0.2, 0.5), 'a thumb at rest')
	eq(text(frame.ResizeButton:GetPushedTexture():GetVertexColor()), text(0.8, 0.2, 0.7, 0.5), 'a resize corner')
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'checked' }) do
		local c = st.config.profile.colors.button[key]
		c.a = 1
	end
end)
