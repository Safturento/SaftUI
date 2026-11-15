-- st:Color and st:ColorRGBA (SaftUI-Core/Media/colors.lua): the one way to read
-- a color by its group and key. They read the active profile at call time, fall
-- back to the defaults, and raise on a key with no default.
load_test_file('core/config_helpers.lua')
local st = SaftUI

test("Color: the profile's own object, read at call time; after a switch, the new profile's", function()
	check(st:Color('loot', 'pass') == st.config.profile.colors.loot.pass)
	st.config:SetProfile('Two'); check(st:Color('loot', 'pass') == st.config.profile.colors.loot.pass)
end)

test('before st.config exists, the default', function()
	local keep = st.config; st.config = nil
	check(st:Color('roles', 'TANK') == st.defaults.colors.roles.TANK); st.config = keep
end)

test('a group or key with no default raises its name', function()
	local ok, err = pcall(st.Color, st, 'text', 'purple'); check(not ok and err:find('SaftUI: no color text.purple', 1, true))
	ok, err = pcall(st.Color, st, 'hues', 'x'); check(not ok and err:find('SaftUI: no color hues.x', 1, true))
	st.config.profile.colors.text.purple = CreateColor(1, 0, 0)
	check(not pcall(st.Color, st, 'text', 'purple'), 'a saved table with no default is still an error')
	st.config.profile.colors.text.purple = nil
end)

test('a group that is not a table reads as the default', function() -- Review Focus 1
	local keep = st.config.profile.colors.loot; st.config.profile.colors.loot = 'x'
	check(st:Color('loot', 'pass') == st.defaults.colors.loot.pass); st.config.profile.colors.loot = keep
end)

test('ColorRGBA: strength times opacity, a nil alpha as 1', function()
	eq(select(4, st:ColorRGBA('text', 'normal')), 1)
	eq(select(4, st:ColorRGBA('text', 'normal', 0.25)), 0.25)
	st.config.profile.colors.button.hover.a = 0.5
	eq(select(4, st:ColorRGBA('button', 'hover', 0.4)), 0.2)
end)

test('a nil key raises, except for a default that is itself a color (renown)', function() -- Ruling 5
	check(not pcall(st.Color, st, 'loot'), 'a group is not a color')
	check(not pcall(st.ColorRGBA, st, 'text'), 'nor for ColorRGBA')
	local ok, err = pcall(st.Color, st, 'loot')
	check(not ok and err:find('SaftUI: no color loot.nil', 1, true), tostring(err))
	check(st:Color('renown') == st.config.profile.colors.renown, "renown, a color with no keys")
end)

test('a saved entry that is not a color (no methods) reads as the default', function()
	local keep = st.config.profile.colors.loot.pass
	st.config.profile.colors.loot.pass = { r = 1, g = 0, b = 0 }
	check(st:Color('loot', 'pass') == st.defaults.colors.loot.pass)
	st.config.profile.colors.loot.pass = 5
	check(st:Color('loot', 'pass') == st.defaults.colors.loot.pass)
	st.config.profile.colors.loot.pass = keep
end)

test('ColorRGBA returns the color\'s r, g and b first', function()
	local r, g, b = st:ColorRGBA('loot', 'transmog')
	local c = st.config.profile.colors.loot.transmog
	eq(r, c.r); eq(g, c.g); eq(b, c.b)
end)
