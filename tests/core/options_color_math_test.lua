-- SaftUI-Core/Config/optionscolorpicker.lua's color maths (W.ColorMath): pure
-- functions, tested directly with exact values. HSV and RGB, hex text, whole
-- numbers typed into a box, the "last used" list and where the picker opens.
local H = load_test_file('core/options_widgets_helpers.lua')
local W = SaftUI.OptionsWidgets
local M = W.ColorMath

local function rgb3(r, g, b) return string.format('%.6f,%.6f,%.6f', r, g, b) end

test('HSVToRGB: pure red, green and blue, white, black and grey', function()
	eq(rgb3(M.HSVToRGB(0, 1, 1)), rgb3(1, 0, 0), 'hue 0 is red')
	eq(rgb3(M.HSVToRGB(1 / 3, 1, 1)), rgb3(0, 1, 0), 'a third is green')
	eq(rgb3(M.HSVToRGB(2 / 3, 1, 1)), rgb3(0, 0, 1), 'two thirds is blue')
	eq(rgb3(M.HSVToRGB(1, 1, 1)), rgb3(1, 0, 0), 'hue 1 wraps to red (the bottom of the strip)')
	eq(rgb3(M.HSVToRGB(0.5, 0, 1)), rgb3(1, 1, 1), 'no saturation, full brightness: white')
	eq(rgb3(M.HSVToRGB(0.5, 1, 0)), rgb3(0, 0, 0), 'no brightness: black, whatever the rest')
	eq(rgb3(M.HSVToRGB(0.7, 0, 0.5)), rgb3(0.5, 0.5, 0.5), 'no saturation: grey')
	eq(rgb3(M.HSVToRGB(1 / 6, 1, 1)), rgb3(1, 1, 0), 'a sixth is yellow')
end)

test('RGBToHSV: pure red, grey, black and white; the hue given is kept while grey or black', function()
	local h, s, v = M.RGBToHSV(1, 0, 0)
	eq(rgb3(h, s, v), rgb3(0, 1, 1), 'red')
	h, s, v = M.RGBToHSV(0, 0, 1)
	eq(rgb3(h, s, v), rgb3(2 / 3, 1, 1), 'blue')
	h, s, v = M.RGBToHSV(0.5, 0.5, 0.5, 0.25)
	eq(rgb3(h, s, v), rgb3(0.25, 0, 0.5), 'grey keeps the hue it had')
	h, s, v = M.RGBToHSV(0, 0, 0, 0.8)
	eq(rgb3(h, s, v), rgb3(0.8, 0, 0), 'black keeps it too')
	h, s, v = M.RGBToHSV(1, 1, 1, 0.3)
	eq(rgb3(h, s, v), rgb3(0.3, 0, 1), 'white keeps it')
	h = M.RGBToHSV(0.5, 0.5, 0.5)
	eq(h, 0, 'no hue given: 0')
	h, s, v = M.RGBToHSV(1, 0, 0, 0.9)
	eq(h, 0, 'a color with a hue ignores the one given')
end)

test('HSV and RGB round-trip an arbitrary color to within 1/255', function()
	local r, g, b = 0.2137, 0.8412, 0.4421
	local h, s, v = M.RGBToHSV(r, g, b)
	local r2, g2, b2 = M.HSVToRGB(h, s, v)
	check(math.abs(r - r2) < 1 / 255 and math.abs(g - g2) < 1 / 255 and math.abs(b - b2) < 1 / 255,
		'back to ' .. rgb3(r2, g2, b2))
	-- And every sixth of the wheel.
	for i = 0, 11 do
		local hr, hg, hb = M.HSVToRGB(i / 12, 0.6, 0.9)
		local h2, s2, v2 = M.RGBToHSV(hr, hg, hb)
		local rr, rg, rb = M.HSVToRGB(h2, s2, v2)
		check(near(hr, rr) and near(hg, rg) and near(hb, rb), 'sector ' .. i)
	end
end)

test('ToByte and Clamp: whole 0 to 255, rounded, and held in range', function()
	eq(M.ToByte(0), 0, 'zero')
	eq(M.ToByte(1), 255, 'one')
	eq(M.ToByte(0.5), 128, 'a half rounds up')
	eq(M.ToByte(-3), 0, 'below zero')
	eq(M.ToByte(7), 255, 'above one')
	eq(M.Clamp(5, 0, 3), 3, 'high')
	eq(M.Clamp(-1, 0, 3), 0, 'low')
	eq(M.Clamp(2, 0, 3), 2, 'inside')
end)

test('FormatHex: capitals, six digits, eight with an opacity', function()
	eq(M.FormatHex(143 / 255, 31 / 255, 31 / 255), '#8F1F1F', '#8F1F1F')
	eq(M.FormatHex(1, 1, 1), '#FFFFFF', 'white')
	eq(M.FormatHex(0, 0, 0), '#000000', 'black')
	eq(M.FormatHex(143 / 255, 31 / 255, 31 / 255, 128 / 255), '#8F1F1F80', 'with an opacity: eight digits')
	eq(M.FormatHex(2, -1, 0.5), '#FF0080', 'out of range is held in it')
end)

test('ParseHex: six digits, eight with an opacity, a # or none, spaces; bad text is nil', function()
	local r, g, b, a = M.ParseHex('#8F1F1F')
	eq(r, 143 / 255, 'r')
	eq(g, 31 / 255, 'g')
	eq(b, 31 / 255, 'b')
	eq(a, nil, 'six digits carry no opacity')
	r, g, b, a = M.ParseHex('8f1f1f')
	eq(r, 143 / 255, 'no #, lower case')
	r, g, b, a = M.ParseHex('  #8F1F1F80 ')
	eq(r, 143 / 255, 'eight digits: r')
	eq(a, 128 / 255, 'eight digits: the last pair is the opacity')
	eq(M.ParseHex('#8F1F1'), nil, 'five digits')
	eq(M.ParseHex('#8F1F1F8'), nil, 'seven digits')
	eq(M.ParseHex('#GG0000'), nil, 'not hex')
	eq(M.ParseHex(''), nil, 'empty')
	eq(M.ParseHex('red'), nil, 'a word')
	eq(M.ParseHex(nil), nil, 'nil')
	eq(M.ParseHex('#8F1F1F8080'), nil, 'ten digits')
	-- A round trip through the text.
	local text = M.FormatHex(M.ParseHex('#3A7BD5'))
	eq(text, '#3A7BD5', 'format of parse')
end)

test('ParseNumber: a whole number clamped into range; anything else is nil', function()
	eq(M.ParseNumber('143', 0, 255), 143, 'a number')
	eq(M.ParseNumber(' 143 ', 0, 255), 143, 'spaces')
	eq(M.ParseNumber('300', 0, 255), 255, 'too high: the top')
	eq(M.ParseNumber('-5', 0, 255), 0, 'too low: the bottom')
	eq(M.ParseNumber('12.6', 0, 255), 13, 'rounded to a whole number')
	eq(M.ParseNumber('50%', 0, 100), 50, 'a percent sign')
	eq(M.ParseNumber('50 %', 0, 100), 50, 'a spaced one')
	eq(M.ParseNumber('abc', 0, 255), nil, 'not a number')
	eq(M.ParseNumber('', 0, 255), nil, 'empty')
	eq(M.ParseNumber('nan', 0, 255), nil, 'nan')
	eq(M.ParseNumber('inf', 0, 255), nil, 'inf')
	eq(M.ParseNumber('1e999', 0, 255), nil, 'a number too big to be one')
end)

test('Remember: newest first, no duplicates by code and opacity, twelve at most', function()
	local list = {}
	list = M.Remember(list, 1, 0, 0, 1, 12)
	list = M.Remember(list, 0, 1, 0, 1, 12)
	eq(#list, 2, 'two colors')
	eq(M.FormatHex(list[1].r, list[1].g, list[1].b), '#00FF00', 'the newest is first')
	list = M.Remember(list, 1, 0, 0, 1, 12)
	eq(#list, 2, 'the same color again adds none')
	eq(M.FormatHex(list[1].r, list[1].g, list[1].b), '#FF0000', 'and moves to the front')
	list = M.Remember(list, 1, 0, 0, 0.5, 12)
	eq(#list, 3, 'another opacity is another color')
	eq(list[1].a, 0.5, 'its opacity kept')
	-- The same code to the byte is the same color.
	list = M.Remember(list, 255.4 / 255, 0, 0, 0.5, 12)
	eq(#list, 3, 'within the same byte')
	for i = 1, 20 do list = M.Remember(list, i / 255, 0, 0, 1, 12) end
	eq(#list, 12, 'twelve at most')
	eq(list[1].r, 20 / 255, 'the newest first')
	local original = {}
	local after = M.Remember(original, 1, 1, 1, 1, 12)
	eq(#original, 0, 'the list given is not changed')
	eq(#after, 1, 'a new one is made')
end)

test('Place: right of the field, 8 apart; left of it, or up, when it would leave the screen', function()
	local anchor = { left = 100, right = 300, top = 500, bottom = 476 }
	local x, y = M.Place(anchor, 440, 388, 1920, 1080)
	eq(x, 308, 'its left 8 past the field\'s right')
	eq(y, 500, 'its top at the field\'s top')
	-- Too far right: the field's left side.
	anchor = { left = 1600, right = 1800, top = 500, bottom = 476 }
	x, y = M.Place(anchor, 440, 388, 1920, 1080)
	eq(x, 1600 - 8 - 440, 'flipped to the left')
	-- Too low: shifted up until its bottom is on the screen.
	anchor = { left = 100, right = 300, top = 200, bottom = 176 }
	x, y = M.Place(anchor, 440, 388, 1920, 1080)
	eq(y, 388, 'up, its bottom at the screen\'s')
	-- Too high: down from the screen's top.
	anchor = { left = 100, right = 300, top = 1200, bottom = 1176 }
	x, y = M.Place(anchor, 440, 388, 1920, 1080)
	eq(y, 1080, 'its top at the screen\'s')
	-- Neither side fits: held on the screen.
	x = M.Place({ left = 50, right = 150, top = 500, bottom = 476 }, 1900, 388, 1920, 1080)
	check(x >= 0 and x + 1900 <= 1920, 'within the screen')
	-- With a margin.
	x, y = M.Place({ left = 100, right = 300, top = 200, bottom = 176 }, 440, 388, 1920, 1080,
		{ left = 10, right = 10, top = 10, bottom = 20 })
	eq(y, 388 + 20, 'above the bottom margin')
	-- Whole numbers, whatever the field's.
	x, y = M.Place({ left = 100.4, right = 300.3, top = 500.6, bottom = 476.2 }, 440, 388, 1920, 1080)
	eq(x, math.floor(x), 'x whole')
	eq(y, math.floor(y), 'y whole')
end)
