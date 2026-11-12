-- Core's pure helpers: st.Plain, st.PlainNumber, st.PlainString and st.Clamp
-- (SaftUI-Core/utilities.lua), st.OutlineFlag (SaftUI-Core/Media/fonts.lua).
load_core_helpers()
local S = load_test_file('lib/secrets.lua')
local st = SaftUI

test('Plain passes a plain value through and drops a secret one', function()
	local restore = S.install()
	local t = {}
	eq(st.Plain(5), 5, 'number')
	eq(st.Plain('a'), 'a', 'string')
	eq(st.Plain(false), false, 'false stays false')
	eq(st.Plain(t), t, 'table')
	eq(st.Plain(nil), nil, 'nil')
	eq(st.Plain(S.secret('s')), nil, 'secret')
	restore()
end)

test('PlainNumber keeps only plain numbers', function()
	eq(st.PlainNumber(0), 0, 'zero')
	eq(st.PlainNumber(-2.5), -2.5, 'negative')
	eq(st.PlainNumber('5'), nil, 'a numeric string')
	eq(st.PlainNumber(true), nil, 'boolean')
	eq(st.PlainNumber({}), nil, 'table')
	eq(st.PlainNumber(nil), nil, 'nil')
	local restore = S.install()
	eq(st.PlainNumber(S.secret('n')), nil, 'secret')
	restore()
end)

test('PlainString keeps only plain strings', function()
	eq(st.PlainString(''), '', 'empty string')
	eq(st.PlainString('x'), 'x', 'string')
	eq(st.PlainString(5), nil, 'number')
	eq(st.PlainString(false), nil, 'boolean')
	eq(st.PlainString(nil), nil, 'nil')
	local restore = S.install()
	eq(st.PlainString(S.secret('s')), nil, 'secret')
	restore()
end)

test('Clamp floors, then holds the value between low and high', function()
	eq(st.Clamp(5, 1, 10), 5, 'inside')
	eq(st.Clamp(5.9, 1, 10), 5, 'floored')
	eq(st.Clamp(1, 1, 10), 1, 'at low')
	eq(st.Clamp(10, 1, 10), 10, 'at high')
	eq(st.Clamp(0, 1, 10), 1, 'below low')
	eq(st.Clamp(11, 1, 10), 10, 'above high')
	eq(st.Clamp(0.5, 1, 10), 1, 'floors to 0, below low')
	eq(st.Clamp(10.9, 1, 10), 10, 'floors to 10')
	eq(st.Clamp(-3, 1, 10), 1, 'negative')
	eq(st.Clamp(nil, 3, 10), 3, 'nil is low')
	eq(st.Clamp(false, 3, 10), 3, 'false is low')
	eq(st.Clamp(5, 8, 2), 2, 'low > high gives high')
	eq(st.Clamp(nil, 8, 2), 2, 'low > high with nil gives high')
end)

test('Clamp errors on a non-number or a secret, as the bar copy did', function()
	check(not pcall(st.Clamp, 'x', 1, 10), 'a string')
	local restore = S.install()
	check(not pcall(st.Clamp, S.secret('c'), 1, 10), 'a secret')
	restore()
end)

test('OutlineFlag gives the font flag for every outline the Fonts module has', function()
	local FN = st:GetModule('Fonts')
	local n = 0
	for key in pairs(FN.outlines) do
		n = n + 1
		eq(st.OutlineFlag(key), key == 'NONE' and '' or key, key)
	end
	check(n >= 6, 'checked every key')
	eq(st.OutlineFlag('NONE'), '', 'NONE is no flags')
end)

test('OutlineFlag: nil is no flags, an unknown key passes through', function()
	eq(st.OutlineFlag(nil), '', 'nil')
	eq(st.OutlineFlag('SOMETHING'), 'SOMETHING', 'unknown key')
end)

test('TooltipLinesText joins each line, left then right, with a space before each', function()
	eq(st.TooltipLinesText({ { leftText = 'Sword', rightText = 'Rare' }, { leftText = '5 Armor' }, {}, { rightText = 'x' } }),
		' Sword Rare 5 Armor x', 'both sides, one side, none')
	eq(st.TooltipLinesText({}), '', 'no lines')
	eq(st.TooltipLinesText({ { leftText = '' } }), ' ', 'an empty text still adds its space')
end)
