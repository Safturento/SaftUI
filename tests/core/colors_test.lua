-- Core's color groundwork: the profile defaults a color option or unit frame
-- reads, st:QualityColor, and st:ColorsChanged (SaftUI-Core/Media/colors.lua).
load_test_file('core/config_helpers.lua')
local st = SaftUI

test('the status colors are colors with r, g and b, not lists, so unit frames read them', function()
	for _, key in ipairs({ 'disconnected', 'tapped' }) do
		local c = st.config.profile.colors.status[key]
		eq(c.r, 0.6, key); eq(c.g, 0.6, key); eq(c.b, 0.6, key)
		eq(c[1], nil, key .. ' is not a list')
		check(c.GetRGB, key .. ' has the color methods')
	end
end)

test('Heirloom and WoW Token have colors, and Arcane charges is in range', function()
	for _, q in ipairs({ 7, 8 }) do
		local r, g, b = st.config.profile.colors.item_quality[q]:GetRGB()
		eq(r .. ',' .. g .. ',' .. b, '0,0.8,1', 'quality ' .. q)
	end
	eq(st.config.profile.colors.power.ARCANE_CHARGES.b, 0.94)
end)

test("QualityColor: the profile's color, else Blizzard's, else nil", function()
	check(st:QualityColor(3) == st.config.profile.colors.item_quality[3], "the profile's own object")
	_G.ITEM_QUALITY_COLORS = { [9] = { r = 1, g = 0, b = 0 } }
	eq(st:QualityColor(9).r, 1, "Blizzard's for a quality the profile has no color for")
	eq(st:QualityColor(10), nil, 'no color anywhere')
	eq(st:QualityColor(nil), nil, 'no quality')
end)

test('ColorsChanged calls OnColorsChanged with the group on every module that has one, past one that errors', function()
	local got = {}
	st:NewModule('ColorsTestA').OnColorsChanged = function() error('boom') end
	st:NewModule('ColorsTestB').OnColorsChanged = function(_, group) got[#got + 1] = group end
	st:ColorsChanged('class')
	eq(table.concat(got, ','), 'class')
	eq(#take_errors(), 1, 'the error is reported, not raised')
end)
