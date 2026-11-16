-- Text > Normal in the options kit's controls (the review of color roles Task 4,
-- Minor 1): a bound key, a select's entry, the field font, a hovered position
-- dot and its axis label, the range knob after a look change, a color field's
-- code and a description. Every case runs with Text > Normal at a value that is
-- not its default, so a reader that drew the shipped 0.9, 0.9, 0.8 fails.
--
-- Real: options_widgets_helpers.lua's world.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
local W = st.OptionsWidgets
local bind, opt, click, theme, parent, rebind = H.bind, H.opt, H.click, H.theme, H.parent, H.rebind

local ODD = '0.10,0.60,0.30'
st.config.profile.colors.text.normal:SetRGB(0.1, 0.6, 0.3)
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6)
local function text(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end

test('a bound key is Text > Normal, an unbound one Muted', function()
	local w = bind('keybinding', 'key', opt('keybinding', 'Key', { get = function() return 'F5' end, set = function() end }))
	eq(text(w.text:GetTextColor()), ODD, 'F5')
	w:Release()
end)

test("a color field's code is Text > Normal", function()
	local w = bind('color', 'tint', opt('color', 'Tint', { get = function() return 0.2, 0.4, 0.6, 1 end, set = function() end }))
	eq(text(w.text:GetTextColor()), ODD, '#336699')
	w:Release()
end)

test('a description is Text > Normal', function()
	local w = bind('description', 'about', opt('description', 'Some words about it.'))
	eq(text(w.text:GetTextColor()), ODD, 'the words')
	w:Release()
end)

test("a select's entry is Text > Normal, the picked one too (by contrast over its fade: no longer the accent)", function()
	theme('thick')
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return 'a' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	click(w.frame)
	local list = W.GetListFrames()
	local seen = {}
	for _, row in ipairs(list.rows) do
		local label = row.text:GetText()
		if label then seen[label] = text(row.text:GetTextColor()) end
	end
	eq(seen.B, ODD, 'an entry not picked')
	eq(seen.A, ODD, 'the picked one is Normal over its bar and fade, not the accent')
	W.CloseList()
	w:Release()
end)

test("the field font is Text > Normal (W.UpdateFonts)", function()
	local w = bind('input', 'word', opt('input', 'Word', { get = function() return 'abc' end, set = function() end }))
	st.config.profile.colors.text.normal:SetRGB(0.3, 0.2, 0.9)
	W.UpdateFonts()
	eq(text(W.GetFont():GetTextColor()), '0.30,0.20,0.90', 'the object takes the changed color')
	st.config.profile.colors.text.normal:SetRGB(0.1, 0.6, 0.3)
	W.UpdateFonts()
	w:Release()
end)

test("a range's knob is Text > Normal after the look goes Blizzard and back", function()
	theme('thick')
	local w = bind('range', 'size', opt('range', 'Size', { min = 0, max = 10, step = 1, get = function() return 5 end, set = function() end }))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	theme('blizzard'); rebind(w)
	theme('thick'); rebind(w)
	eq(text(w.slider:GetThumbTexture():GetVertexColor()), ODD, 'the flat knob again')
	w:Release()
end)

test("a position block's axis label is Text > Normal and a hovered dot the lighter tone", function()
	theme('thick')
	local store = { point = 'TOPRIGHT', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -8, frame = 'Minimap' }
	local w = bind('position', 'pos', opt('position', 'Position', {
		get = function(_, part) return store[part] end, set = function(_, part, value) store[part] = value end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	check(w.xLabel and w.yLabel, 'the axis labels')
	eq(text(w.xLabel:GetTextColor()), ODD, 'the X label')
	eq(text(w.yLabel:GetTextColor()), ODD, 'the Y label')
	local button = w.this[1]
	check(button and button.dot, 'a dot')
	if button and button.dot then
		stub.fire_script(button, 'OnEnter', true)
		local r, g, b = button.dot:GetVertexColor()
		local tr, tg, tb = st:StateColor('edgeHover')
		eq(text(r, g, b), text(tr, tg, tb), 'a hovered dot is the lighter tone of the accent (a glyph), not Text')
		stub.fire_script(button, 'OnLeave', true)
	end
	w:Release()
end)
