-- st:MigrateColors (SaftUI-Core/Media/colors.lua): a profile saved before the
-- colors were named for their roles keeps every customized color, at login and
-- on every profile switch, copy or reset (Config:UpdateConfig), on a real
-- AceDB-3.0 (core/config_helpers.lua).
local st
local T = load_test_file('lib/theme_helpers.lua')

-- A fresh world logged in with saved (SaftUI_DB as the game loads it from the
-- SavedVariables file before login, or nil for a new install).
local function fresh(saved)
	reset_world()
	SaftUI_DB = saved
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	return st
end

-- AceDB's key for this character's profile choice.
local function char_key() return UnitName('player') .. ' - ' .. GetRealmName() end

local function on(profile) return { profileKeys = { [char_key()] = 'Old' }, profiles = { Old = profile } } end
local RGB = T.rgb
local function rgb(c) return T.rgb(c.r, c.g, c.b) end
local function LAST() return #st:GetModule('Colors').MIGRATION_STEPS end
local RED, YELLOW, BLUE = RGB(220/255, 100/255, 100/255), RGB(200/255, 200/255, 100/255), RGB(0, 0.68, 0.94)

-- Keys sorted with tostring, tables recursed: two equal tables give one string.
local function Dump(t)
	if type(t) ~= 'table' then return tostring(t) end
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local out = {}
	for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. '=' .. Dump(t[k]) end
	return '{' .. table.concat(out, ',') .. '}'
end

-- profile.colors, then a path's group and key ('loot.pass'), or profile.theme.accent.
local function Slot(profile, path)
	if path == 'accent' then return profile.theme.accent end
	local group, key = path:match('^([^.]+)%.(.+)$')
	return profile.colors[group][key]
end

test('nothing saved: only the version, every destination at its default, nothing saved for them', function()
	fresh(on({}))
	local colors = st.config.profile.colors
	eq(colors.version, LAST())
	eq(rgb(colors.loot.pass), RED); eq(rgb(colors.roles.TANK), BLUE); eq(rgb(colors.factions.Neutral), YELLOW)
	eq(rgb(st.config.profile.theme.accent), BLUE, 'the accent at its default')
	st.config:SetProfile('Two')
	eq(SaftUI_DB.profiles.Old.theme, nil, 'and nothing of it saved')
	eq(SaftUI_DB.profiles.Old.colors.version, LAST())
	for _, group in ipairs({ 'loot', 'roles', 'factions' }) do eq(SaftUI_DB.profiles.Old.colors[group], nil, group) end
end)

test('one saved channel: the rest from OLD_COLORS, into every destination of the split, methods kept', function()
	fresh(on({ colors = { text = { red = { r = 1 } } } }))
	for _, d in ipairs({ { 'loot', 'pass' }, { 'roles', 'DAMAGER' }, { 'factions', 'Horde' } }) do
		local c = st.config.profile.colors[d[1]][d[2]]
		eq(rgb(c), RGB(1, 100/255, 100/255), d[2]); eq(type(c.GetRGB), 'function', d[2])
	end
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.colors.loot.pass
	eq(saved.r, 1); eq(saved.g, nil, 'AceDB keeps only the channel that differs')
end)

test('retired sources move and go: Text > Purple to Transmog, Buttons > Yellow to Mount, never its alpha', function()
	fresh(on({ colors = { text = { purple = { g = 0 } }, button = { yellow = { b = 0.5, a = 0.3 } } } }))
	local colors = st.config.profile.colors
	eq(rgb(colors.loot.transmog), RGB(197/255, 0, 1)); eq(rgb(colors.loot.mount), RGB(0.6, 0.6, 0.5))
	eq(colors.loot.mount.a, 1, "Mount keeps its own opacity (CreateColor's 1), not Yellow's 0.3")
	eq(rawget(colors.text, 'purple'), nil); eq(rawget(colors.button, 'yellow'), nil)
end)

test('a source equal to its old value to the byte copies nothing (raw data)', function()
	local raw = { colors = { text = { red = { r = 220/255 + 0.001 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.loot, nil); eq(raw.colors.roles, nil); eq(raw.colors.factions, nil); eq(raw.colors.version, LAST())
end)

test('raw data: a group and a destination are made only where a copy lands', function()
	local raw = { colors = { text = { blue = { b = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.roles.TANK), RGB(0, 0.68, 0.5)); eq(rgb(raw.colors.factions.Alliance), RGB(0, 0.68, 0.5))
	eq(raw.colors.loot, nil); eq(raw.colors.roles.HEALER, nil)
end)

test('run twice: no change', function()
	local raw = { colors = { text = { red = { r = 1 }, purple = { g = 0 } } } }
	st:MigrateColors(raw); local once = Dump(raw)
	st:MigrateColors(raw); eq(Dump(raw), once)
	check(pcall(st.MigrateColors, st, nil), 'a nil profile is left alone')
	local empty = {}; st:MigrateColors(empty); eq(next(empty), nil, 'no colors table: nothing written')
end)

test('a switch to, a copy from and a reset of an unmigrated profile', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { text = { red = { r = 1 } } } }
	SaftUI_DB.profiles.Three = { colors = { text = { yellow = { r = 1 } } } }
	st.config:SetProfile('Two'); eq(st.config.profile.colors.loot.pass.r, 1); eq(st.config.profile.colors.version, LAST())
	st.config:SetProfile('Old'); st.config:CopyProfile('Three')
	eq(st.config.profile.colors.factions.Neutral.r, 1); eq(st.config.profile.colors.version, LAST())
	check(st.config.profile.colors.factions.Neutral.GetRGB, 'a copied profile keeps the methods')
	st.config.profile.colors.loot.pass.r = 0.5; st.config:ResetProfile()
	eq(rgb(st.config.profile.colors.loot.pass), RED); eq(st.config.profile.colors.version, LAST())
end)

test('in combat a switch migrates at once', function()
	fresh(on({})); SaftUI_DB.profiles.Two = { colors = { text = { red = { r = 1 } } } }
	stub.in_combat = true; st.config:SetProfile('Two')
	eq(st.config.profile.colors.loot.pass.r, 1); eq(#stub.blocked, 0); stub.in_combat = false
end)

test('saved data the migration does not expect: nothing errors and nothing is lowered', function() -- Review Focus 1
	for _, raw in ipairs({ { colors = 'x' }, { colors = { text = 'x' } }, { colors = { text = { red = 5 } } },
		{ colors = { text = { red = { r = 'x', g = 0 } } } }, { colors = { version = 'x' } }, { colors = { version = 0.5 } }, { colors = { version = -1 } } }) do
		check(pcall(st.MigrateColors, st, raw))
	end
	local raw = { colors = { text = { red = { r = 'x', g = 0 } } } }; st:MigrateColors(raw)
	eq(rgb(raw.colors.loot.pass), RGB(220/255, 0, 100/255), "a channel that isn't a number takes the old default's")
	for _, version in ipairs({ 0.5, -1, 'x' }) do
		raw = { colors = { version = version, text = { red = { r = 1 } } } }; st:MigrateColors(raw)
		eq(raw.colors.loot.pass.r, 1, 'version ' .. tostring(version) .. ' runs step 1'); eq(raw.colors.version, LAST())
	end
	raw = { colors = { version = 99, text = { red = { r = 1 } } } }; st:MigrateColors(raw)
	eq(raw.colors.version, 99); eq(raw.colors.loot, nil)
	fresh(on({ colors = { text = { red = 5 }, version = 'x' } })); eq(#take_errors(), 0)
	eq(st.config.profile.colors.version, LAST())
end)

test('a migration that raises at login is reported and the profile still loads (xpcall, Ruling 6)', function()
	fresh(on({}))
	local steps = st:GetModule('Colors').MIGRATION_STEPS
	steps[#steps + 1] = { copy = { 5 }, retire = 5 }
	take_errors()
	st.Config:InitializeAceConfig() -- login again, with a step that raises
	steps[#steps] = nil
	eq(#take_errors(), 1, 'one error reported, not raised')
	check(type(st.config.profile) == 'table', 'the profile is there, so modules still load')
end)

-- A profile as today's build saves it, every hue customized in part.
local function OLD_SAVED()
	return { colors = {
		text = { red = { r = 1 }, orange = { g = 0.2 }, yellow = { b = 0 }, green = { r = 0.5 }, grey = { r = 0.4 },
			blue = { g = 0.1 }, purple = { r = 0.3 }, cyan = { b = 0.2 }, white = { g = 0.9 } },
		button = { red = { r = 0.9, a = 0.5 }, green = { g = 0.9 }, blue = { r = 0.7, a = 0.2 }, yellow = { b = 0.4 },
			grey = { r = 0.2 }, normal = { a = 0.3 }, hover = { r = 0.6 }, pushed = { a = 0.1 } },
	} }
end
-- path -> RGB of what it holds after every step; each task adds its rows.
local EXPECTED = {
	['loot.need'] = RGB(1, 0.9, 1), ['loot.greed'] = RGB(200/255, 200/255, 0), ['loot.transmog'] = RGB(0.3, 128/255, 1),
	['loot.pass'] = RGB(1, 100/255, 100/255), ['loot.mount'] = RGB(0.6, 0.6, 0.4),
	['roles.TANK'] = RGB(0, 0.1, 0.94), ['roles.HEALER'] = RGB(0.5, 240/255, 60/255), ['roles.DAMAGER'] = RGB(1, 100/255, 100/255),
	['factions.Alliance'] = RGB(0, 0.1, 0.94), ['factions.Horde'] = RGB(1, 100/255, 100/255), ['factions.Neutral'] = RGB(200/255, 200/255, 0),
	['accent'] = RGB(0.7, 0.68, 0.94),
	['text.muted'] = RGB(0.4, 180/255, 180/255), -- Text > Grey's default was 180 when step 3 shipped
}
test('a profile saved before any of this runs every step at once, in order', function()
	fresh(on(OLD_SAVED()))
	for path, want in pairs(EXPECTED) do eq(rgb(Slot(st.config.profile, path)), want, path) end
	eq(st.config.profile.colors.version, LAST())
end)


-- Step 2: the accent takes Buttons > Blue, never Text > Blue.

test('step 2: the accent takes Buttons > Blue, never Text > Blue; Buttons > Green is dropped', function()
	fresh(on({ colors = { text = { blue = { r = 0.9 } }, button = { blue = { g = 0.2, a = 0.3 }, green = { r = 1 } } } }))
	local p = st.config.profile
	eq(rgb(p.theme.accent), T.rgb(0, 0.2, 0.94)); eq(p.theme.accent.a, 1, "its own opacity (the game's CreateColor), never Buttons > Blue's 0.3"); eq(type(p.theme.accent.GetRGB), 'function')
	eq(rgb(p.colors.roles.TANK), T.rgb(0.9, 0.68, 0.94), 'Text > Blue went to Tank and Alliance at step 1')
	eq(rgb(p.colors.factions.Alliance), T.rgb(0.9, 0.68, 0.94))
	eq(rawget(p.colors.text, 'blue'), nil); eq(rawget(p.colors.button, 'blue'), nil); eq(rawget(p.colors.button, 'green'), nil)
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.theme.accent
	eq(saved.g, 0.2); eq(saved.r, nil, 'AceDB keeps only the channel that differs'); eq(saved.a, nil)
end)

test('a profile at version 1 runs step 2 alone', function()
	local raw = { colors = { version = 1, text = { blue = { r = 0.9 } }, button = { blue = { r = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.theme.accent), T.rgb(0.5, 0.68, 0.94)); eq(raw.colors.roles, nil, 'step 1 is not run again'); eq(raw.colors.version, LAST())
	eq(raw.colors.text.blue, nil, 'Text > Blue retired with no destination'); eq(raw.colors.button.blue, nil)
end)

test('step 2: a Text > Blue changed after step 1 goes nowhere (not the accent, not Tank)', function()
	local raw = { colors = { version = 1, roles = { TANK = { r = 0.4 } }, text = { blue = { r = 0.9, g = 0.9 } } } }
	st:MigrateColors(raw)
	eq(raw.theme, nil, 'no accent written'); eq(raw.colors.roles.TANK.r, 0.4, 'Tank keeps what step 1 gave it')
	eq(raw.colors.text.blue, nil)
end)

test('step 2: an uncustomized Buttons > Blue copies nothing, whatever its opacity', function()
	local raw = { colors = { button = { blue = { a = 0.3 } } } }
	st:MigrateColors(raw)
	eq(raw.theme, nil, 'the bytes are the old ones: not customized, the accent keeps its default')
	raw = { colors = { button = { blue = { r = 0, g = 0.68 + 0.0001, b = 0.94 } } } }
	st:MigrateColors(raw); eq(raw.theme, nil, 'equal to the byte')
	raw = { colors = { button = { blue = { b = 0.5 } } } }
	st:MigrateColors(raw); eq(rgb(raw.theme.accent), T.rgb(0, 0.68, 0.5))
end)

test('step 2 on raw data: the accent is written into one that is there, else made with its theme', function()
	local accent = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 }
	local raw = { theme = { name = 'thin', accent = accent }, colors = { version = 1, button = { blue = { r = 0.5 } } } }
	st:MigrateColors(raw)
	check(raw.theme.accent == accent, 'in place'); eq(accent.r, 0.5); eq(accent.g, 0.68); eq(accent.b, 0.94); eq(accent.a, 0.7, 'never an alpha')
	eq(raw.theme.name, 'thin')
	raw = { theme = 'x', colors = { version = 1, button = { blue = { r = 0.5 } } } }
	st:MigrateColors(raw); eq(rgb(raw.theme.accent), T.rgb(0.5, 0.68, 0.94), 'a theme that is not a table is replaced')
	raw = { colors = { version = 1, button = { blue = 5, green = 'x' } } }
	check(pcall(st.MigrateColors, st, raw)); eq(raw.theme, nil); eq(raw.colors.button.blue, nil, 'retired even when it is not a table')
end)

test('step 2: a profile at the last step, or above it, runs nothing', function()
	local raw = { colors = { version = LAST(), button = { blue = { r = 0.5 } } } }
	st:MigrateColors(raw); eq(raw.theme, nil); eq(raw.colors.button.blue.r, 0.5, 'left as it is')
end)

test('step 2: a switch to, a copy from and a reset of an unmigrated profile carry the accent', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { button = { blue = { r = 1 } } } }
	SaftUI_DB.profiles.Three = { colors = { version = 1, button = { blue = { g = 1 } } } }
	st.config:SetProfile('Two'); eq(st.config.profile.theme.accent.r, 1); eq(st.config.profile.colors.version, LAST())
	check(st.config.profile.theme.accent.GetRGB, 'the methods')
	st.config:SetProfile('Old'); st.config:CopyProfile('Three')
	eq(rgb(st.config.profile.theme.accent), T.rgb(0, 1, 0.94), 'a copy from a profile at version 1: step 2 alone')
	st.config.profile.theme.accent.r = 0.5; st.config:ResetProfile()
	eq(rgb(st.config.profile.theme.accent), BLUE)
end)

-- Step 3: Text > Grey becomes Text > Muted; Buttons > Grey is dropped.
--
-- Text > Grey's default became 180 (#b4b4b4, decision 49) after the frozen
-- table was written at 150 and before this step shipped, so OLD_COLORS holds
-- 180 for it: the default in effect when the key retires. Buttons > Grey's
-- default never changed, and it stays 150.
local GREY180 = RGB(180/255, 180/255, 180/255)

test("step 3: Muted's default is 180, and the frozen Text > Grey is that default (Buttons > Grey stays 150)", function()
	fresh(on({}))
	local CO = st:GetModule('Colors')
	eq(rgb(st.config.profile.colors.text.muted), GREY180, "Muted's default")
	eq(rgb(CO.OLD_COLORS['text.grey']), GREY180, "Text > Grey's default at the time it retires")
	eq(rgb(CO.OLD_COLORS['button.grey']), RGB(150/255, 150/255, 150/255), "Buttons > Grey's default never changed")
	eq(rawget(st.defaults.colors.text, 'grey'), nil); eq(rawget(st.defaults.colors.button, 'grey'), nil)
end)

test('step 3: untouched, nothing is written for Muted and nothing is saved', function()
	fresh(on({}))
	eq(rgb(st.config.profile.colors.text.muted), GREY180)
	st.config:SetProfile('Two')
	eq(SaftUI_DB.profiles.Old.colors.text, nil, 'no Text group saved')
	eq(SaftUI_DB.profiles.Old.colors.version, LAST())
	local raw = { colors = {} }
	st:MigrateColors(raw); eq(raw.colors.text, nil, 'no group made'); eq(raw.colors.version, LAST())
end)

test('step 3: a customized grey becomes Muted, methods kept, only the changed channel saved', function()
	fresh(on({ colors = { text = { grey = { r = 0.4, g = 0.5, b = 0.6 } } } }))
	local colors = st.config.profile.colors
	eq(rgb(colors.text.muted), RGB(0.4, 0.5, 0.6)); check(colors.text.muted.GetRGB, 'AceDB methods kept')
	eq(rawget(colors.text, 'grey'), nil, 'Text > Grey is gone')
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.colors.text
	eq(saved.muted.r, 0.4); eq(saved.muted.g, 0.5); eq(saved.muted.b, 0.6); eq(saved.grey, nil)
end)

test('step 3: a partial grey has its missing channels filled from 180', function()
	fresh(on({ colors = { text = { grey = { r = 0.4 } } } }))
	eq(rgb(st.config.profile.colors.text.muted), RGB(0.4, 180/255, 180/255))
	local raw = { colors = { text = { grey = { g = 0.2, a = 0.3 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.text.muted), RGB(180/255, 0.2, 180/255), 'g alone'); eq(raw.colors.text.muted.a, nil, 'never an alpha')
	raw = { colors = { text = { grey = { r = 'x', g = 0.2, b = {} } } } }
	st:MigrateColors(raw); eq(rgb(raw.colors.text.muted), RGB(180/255, 0.2, 180/255), "channels that aren't numbers take 180")
end)

test('step 3: a grey still at the default copies nothing (an opacity alone, or 180 to the byte)', function()
	for _, grey in ipairs({ { a = 0.3 }, { r = 180/255, g = 180/255, b = 180/255 }, { r = 180/255 + 0.001 }, {} }) do
		local raw = { colors = { text = { grey = grey } } }
		st:MigrateColors(raw)
		eq(raw.colors.text.muted, nil, 'no Muted written'); eq(raw.colors.text.grey, nil, 'but the grey is retired')
	end
end)

test('step 3: a grey saved at exactly 150 is a customized color and is kept as Muted', function()
	fresh(on({ colors = { text = { grey = { r = 150/255, g = 150/255, b = 150/255 } } } }))
	eq(rgb(st.config.profile.colors.text.muted), RGB(150/255, 150/255, 150/255), '150 is not the default now')
	-- A grey saved at only r = 150 keeps it and takes 180 for the rest.
	local raw = { colors = { text = { grey = { r = 150/255 } } } }
	st:MigrateColors(raw); eq(rgb(raw.colors.text.muted), RGB(150/255, 180/255, 180/255))
end)

test('step 3: a customized Buttons > Grey is dropped, and never reaches Muted', function()
	fresh(on({ colors = { button = { grey = { r = 0.9, g = 0.1, b = 0.1 } } } }))
	local colors = st.config.profile.colors
	eq(rawget(colors.button, 'grey'), nil); eq(rgb(colors.text.muted), GREY180, 'Muted keeps its default')
	st.config:SetProfile('Two')
	eq(SaftUI_DB.profiles.Old.colors.text, nil, 'and nothing is saved for Muted')
	-- Both customized: Text > Grey wins, Buttons > Grey goes.
	local raw = { colors = { text = { grey = { r = 0.4 } }, button = { grey = { r = 0.9 }, normal = { a = 0.3 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.text.muted.r, 0.4); eq(raw.colors.button.grey, nil); eq(raw.colors.button.normal.a, 0.3, 'the rest of Buttons is left alone')
	raw = { colors = { button = { grey = 5 }, text = { grey = 'x' } } }
	check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button.grey, nil, 'retired even when it is not a table'); eq(raw.colors.text.muted, nil)
end)

test('step 3 by version: 0 runs every step, 1 runs steps 2 and 3, 2 runs step 3 alone, the last step runs nothing', function()
	local function profile(version)
		return { colors = { version = version, text = { red = { r = 1 }, grey = { r = 0.4 } }, button = { blue = { r = 0.5 }, grey = { r = 0.9 } } } }
	end
	local raw = profile(0); st:MigrateColors(raw)
	eq(raw.colors.loot.pass.r, 1, 'step 1'); eq(raw.theme.accent.r, 0.5, 'step 2'); eq(raw.colors.text.muted.r, 0.4, 'step 3'); eq(raw.colors.version, LAST())
	raw = profile(1); st:MigrateColors(raw)
	eq(raw.colors.loot, nil, 'step 1 is not run again'); eq(raw.theme.accent.r, 0.5); eq(raw.colors.text.muted.r, 0.4)
	raw = profile(2); st:MigrateColors(raw)
	eq(raw.colors.loot, nil); eq(raw.theme, nil, 'step 2 is not run again'); eq(raw.colors.text.muted.r, 0.4)
	eq(raw.colors.text.grey, nil); eq(raw.colors.button.grey, nil); eq(raw.colors.version, LAST())
	raw = profile(LAST()); st:MigrateColors(raw)
	eq(raw.colors.text.muted, nil, 'at the last step, nothing runs'); eq(raw.colors.text.grey.r, 0.4, 'and the grey is left as it is')
	eq(raw.colors.version, LAST())
end)

test('step 3 on a real AceDB at version 0, 1 and 2, and run twice', function()
	for version, want in pairs({ [0] = 0.4, [1] = 0.4, [2] = 0.4 }) do
		fresh(on({ colors = { version = version, text = { grey = { r = want } } } }))
		eq(st.config.profile.colors.text.muted.r, want, 'version ' .. version); eq(st.config.profile.colors.version, LAST())
		local once = Dump(st.config.profile.colors)
		st:MigrateColors(st.config.profile); eq(Dump(st.config.profile.colors), once, 'run twice: no change')
	end
	local raw = { colors = { text = { grey = { r = 0.4 } }, button = { grey = { r = 0.9 } } } }
	st:MigrateColors(raw); local once = Dump(raw)
	st:MigrateColors(raw); eq(Dump(raw), once, 'raw data, run twice')
end)

test('step 3: a grey changed after the step ran is Muted now, and a switch to an unmigrated profile carries it', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { text = { grey = { b = 0.1 } }, button = { grey = { r = 0.9 } } } }
	st.config:SetProfile('Two')
	eq(rgb(st.config.profile.colors.text.muted), RGB(180/255, 180/255, 0.1)); eq(st.config.profile.colors.version, LAST())
	st.config:SetProfile('Old'); st.config:CopyProfile('Two')
	eq(rgb(st.config.profile.colors.text.muted), RGB(180/255, 180/255, 0.1), 'a copy carries it')
	st.config.profile.colors.text.muted:SetRGB(0.1, 0.1, 0.1); st.config:ResetProfile()
	eq(rgb(st.config.profile.colors.text.muted), GREY180, 'a reset puts the default back')
end)
