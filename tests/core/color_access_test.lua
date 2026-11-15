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

-- The accent: st.config.profile.theme.accent, read through the accessor.

test("Color('accent') is the profile's theme.accent; a key passed is ignored", function()
	check(st:Color('accent') == st.config.profile.theme.accent)
	check(st:Color('accent', 'anything') == st.config.profile.theme.accent)
	st.config:SetProfile('Two'); check(st:Color('accent') == st.config.profile.theme.accent)
	eq(select(4, st:ColorRGBA('accent', nil, 0.25)), 0.25, 'a strength over the accent, which has no alpha')
	local r, g, b = st:ColorRGBA('accent')
	eq(r, 0); eq(g, 0.68); eq(b, 0.94)
end)

test("a theme.accent that is not a color reads as the default", function()
	local keep = st.config.profile.theme.accent
	st.config.profile.theme.accent = 'x'
	check(st:Color('accent') == st.defaults.theme.accent)
	st.config.profile.theme.accent = keep
end)

-- A recording of st:ColorsChanged for fn.
local function Recorded(fn)
	local log, real = {}, st.ColorsChanged
	st.ColorsChanged = function(_, group) log[#log + 1] = group; return real(st, group) end
	fn()
	st.ColorsChanged = real
	return table.concat(log, ',')
end

test('a profile update fires accent after theme', function()
	local log = Recorded(function() st.config:SetProfile('Three') end)
	check(log:find('theme,accent$'), 'theme then accent at the end: ' .. log)
end)

test('a profile update in combat: migrated at once, theme then accent after combat', function() -- Review Focus 2
	local old = { colors = { button = { blue = { r = 0.5 } } } }
	SaftUI_DB.profiles.Combat = old
	local log = Recorded(function()
		stub.in_combat = true
		st.config:SetProfile('Combat')
		eq(st.config.profile.colors.version, #st:GetModule('Colors').MIGRATION_STEPS, 'migrated at once')
		eq(st.config.profile.theme.accent.r, 0.5, 'the destination written now')
		eq(#stub.blocked, 0)
		stub.in_combat = false
	end)
	check(not log:find('theme', 1, true) and not log:find('accent', 1, true), 'neither in combat: ' .. log)
	log = Recorded(function() stub.fire_event('PLAYER_REGEN_ENABLED') end)
	check(log:find('theme,accent$'), 'theme then accent after combat: ' .. log)
	eq(#stub.blocked, 0)
	st.config:SetProfile('Two')
end)

-- What st:Print prints first, with the printed arguments.
local function Printed(fn)
	local keep, out = print, {}
	print = function(...) out[#out + 1] = table.concat({ ... }, ' ') end
	local ok, err = pcall(fn)
	print = keep
	check(ok, tostring(err))
	return out[1]
end

test("st:Print's prefix is the accent at print time", function()
	eq(Printed(function() st:Print('x') end), '[|cff00adf0SaftUI|r]:  x')
	local accent = st.config.profile.theme.accent
	accent.r, accent.g, accent.b = 1, 0, 0
	check(Printed(function() st:Print('x') end):find('^%[|cffff0000SaftUI|r%]'), 'the next print is red')
	check(Printed(function() st:Error('x') end):find('^%[|cffff0000SaftUI|r '), 'st:Error builds the same prefix')
	accent.r, accent.g, accent.b = 0, 0.68, 0.94
end)

test('a print before the defaults exist', function() -- Review Focus 3
	local keep = st.defaults
	st.defaults = nil
	local line = Printed(function() st:Print('x') end)
	check(line:find('|cff00adf0SaftUI|r', 1, true), 'the shipped hex: ' .. tostring(line))
	check(Printed(function() st:Error('x') end):find('|cff00adf0SaftUI|r', 1, true), 'and for Error')
	st.defaults = keep
end)
