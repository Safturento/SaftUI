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

test('a hand-edited channel that is no number reads as the default, and nothing raises', function()
	local c = st.config.profile.colors.button
	local keep = c.hover
	local default = st.defaults.colors.button.hover
	for _, bad in ipairs({ { r = 'x' }, { g = true }, { b = {} }, { a = 'x' } }) do
		local edited = CreateColor(0.9, 0.2, 0.6, 0.5)
		for k, v in pairs(bad) do edited[k] = v end
		c.hover = edited
		local ok, r, g, b, a = pcall(st.ColorRGBA, st, 'button', 'hover', 0.4)
		check(ok, 'ColorRGBA raised on ' .. next(bad))
		if ok then
			eq(type(r) == 'number' and type(g) == 'number' and type(b) == 'number' and type(a) == 'number', true, 'four numbers for ' .. next(bad))
			eq(r, default.r); eq(g, default.g); eq(b, default.b); eq(a, 0.4 * default.a, 'the default, at its strength')
		end
		check(st:Color('button', 'hover') == default, 'st:Color reads the default for ' .. next(bad))
	end
	c.hover = CreateColor(0.9, 0.2, 0.6, 0.5)
	eq(select(4, st:ColorRGBA('button', 'hover', 0.4)), 0.2, 'a good one is read as it is')
	c.hover = keep
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
	SaftUI_DB.profiles.Old = old
	local log = Recorded(function()
		stub.in_combat = true
		st.config:SetProfile('Old')
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

-- Task 4: the Error prefix and DEBUG are Text > Danger, read at each call.

test('the Error prefix is Danger at print time (a listed change from pure red); before the defaults dc6464', function() -- Review Focus 3
	local danger = st.config.profile.colors.text.danger
	check(Printed(function() st:Error('x') end):find('|cffdc6464Error|r]:', 1, true), 'Danger at its default, not the old pure red')
	check(not Printed(function() st:Error('x') end):find('|cffff0000', 1, true), 'no hardcoded red')
	danger.r, danger.g, danger.b = 0, 1, 0
	check(Printed(function() st:Error('x') end):find('|cff00ff00Error|r]:', 1, true), 'the next print follows a changed Danger')
	danger.r, danger.g, danger.b = 220/255, 100/255, 100/255
	st.config:SetProfile('Three')
	local other = st.config.profile.colors.text.danger
	other.r, other.g, other.b = 0, 0, 1
	check(Printed(function() st:Error('x') end):find('|cff0000ffError|r]:', 1, true), "a profile switch reaches the new profile's Danger")
	other.r, other.g, other.b = 220/255, 100/255, 100/255
	local keep = st.defaults
	st.defaults = nil
	local line = Printed(function() st:Error('x') end)
	check(line:find('|cffdc6464Error|r]:', 1, true), 'before the defaults, the shipped hex: ' .. tostring(line))
	st.defaults = keep
	st.config.profile.theme.accent.r = 1
	check(Printed(function() st:Error('x') end):find('^%[|cffffadf0SaftUI|r |cffdc6464Error|r%]'), 'the accent and Danger each in their own place')
	st.config.profile.theme.accent.r = 0
end)

test('DEBUG is Danger, read at each call', function()
	load_string_format()
	local keep = st.DEBUG
	st.DEBUG = true
	local danger = st.config.profile.colors.text.danger
	check(Printed(function() st:Debug('Mod', 'x') end):find('<|cffdc6464DEBUG|r:Mod>', 1, true), 'at the default')
	danger.r, danger.g, danger.b = 0, 1, 0
	check(Printed(function() st:Debug('Mod', 'x') end):find('<|cff00ff00DEBUG|r:Mod>', 1, true), 'a changed Danger')
	danger.r, danger.g, danger.b = 220/255, 100/255, 100/255
	st.DEBUG = keep
end)
