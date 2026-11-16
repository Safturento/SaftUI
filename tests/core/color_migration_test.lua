-- st:MigrateColors (SaftUI-Core/Media/colors.lua): a profile saved before the
-- colors were named for their roles keeps every customized color, at login and
-- on every profile switch, copy or reset (Config:UpdateConfig), on a real
-- AceDB-3.0 (core/config_helpers.lua).
local st
local T = load_test_file('lib/theme_helpers.lua')

-- A fresh world logged in with saved (SaftUI_DB as the game loads it from the
-- SavedVariables file before login, or nil for a new install). The tests of
-- steps 1 to 6 pin what those steps did to the Buttons colors (step 5's
-- opacities, step 6's seed of Buttons > Checked), which steps 7 and 8 drop
-- (the states are the Accent's, and the four colors' defaults are gone from
-- st.defaults): so by default the world has steps 7 and 8 taken out of the
-- Colors module's list as colors.lua loads, before login's migration runs, and
-- the four old defaults put back as defaults.lua loads, and those tests are as
-- they shipped. fresh(saved, true) keeps every step and the real defaults (the
-- step 7 and 8 tests).
local OLD_DEFAULTS = {
	normal = { 0.1, 0.1, 0.1, 1 }, hover = { 0.3, 0.5, 0.7, 1 },
	pushed = { 0.3, 0.4, 0.5, 1 }, checked = { 0.3, 0.5, 0.7, 1 },
}
local function fresh(saved, all_steps)
	reset_world()
	SaftUI_DB = saved
	local real_load = load_saftui
	load_saftui = function(path, ...)
		local result = real_load(path, ...)
		if path == 'SaftUI-Core/Media/colors.lua' and not all_steps then
			local steps = SaftUI:GetModule('Colors').MIGRATION_STEPS
			check(#steps == 8, 'step 8 is the last step (the older tests run without steps 7 and 8)')
			steps[8] = nil; steps[7] = nil
		elseif path == 'SaftUI-Core/Config/defaults.lua' and not all_steps then
			for key, c in pairs(OLD_DEFAULTS) do SaftUI.defaults.colors.button[key] = CreateColor(c[1], c[2], c[3], c[4]) end
		end
		return result
	end
	local ok, err = pcall(load_test_file, 'core/config_helpers.lua')
	load_saftui = real_load
	if not ok then error(err, 0) end
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
	['text.strong'] = RGB(1, 0.9, 1), ['text.danger'] = RGB(1, 100/255, 100/255), ['text.warning'] = RGB(220/255, 0.2, 100/255),
	['text.caution'] = RGB(200/255, 200/255, 0), ['text.success'] = RGB(0.5, 240/255, 60/255), ['text.shared'] = RGB(120/255, 202/255, 0.2),
	['button.danger'] = RGB(0.9, 0.1, 0.1), ['button.hover'] = RGB(0.6, 0.5, 0.7), -- step 5 keeps a customized Buttons color
}
test('a profile saved before any of this runs every step at once, in order', function()
	fresh(on(OLD_SAVED()))
	for path, want in pairs(EXPECTED) do eq(rgb(Slot(st.config.profile, path)), want, path) end
	for _, key in ipairs({ 'normal', 'hover', 'pushed', 'danger' }) do eq(st.config.profile.colors.button[key].a, 1, 'step 5: Buttons > ' .. key .. ' back at 100%') end
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
	eq(raw.colors.text.muted.r, 0.4); eq(raw.colors.button.grey, nil); eq(raw.colors.button.normal.a, 1, 'the rest of Buttons is left alone, but step 5 puts its opacity back to 100%'); eq(raw.colors.button.normal.r, nil, 'and its color')
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


-- Step 4: the state colors take their roles' names. It runs after step 1 read
-- text.white, yellow, red and green for Loot, Roles and Factions.

local STATE = { 'strong', 'danger', 'warning', 'caution', 'success', 'shared' }
local OLD_STATE = { 'white', 'red', 'orange', 'yellow', 'green', 'cyan' }

test('step 4: each state color takes its hue, and Buttons > Danger takes Buttons > Red, never its alpha', function()
	fresh(on({ colors = { text = { white = { g = 0.9 }, red = { r = 1 }, orange = { g = 0.2 }, yellow = { b = 0 },
		green = { r = 0.5 }, cyan = { b = 0.2 } }, button = { red = { r = 0.9, a = 0.5 } } } }))
	local c = st.config.profile.colors
	eq(rgb(c.text.strong), RGB(1, 0.9, 1)); eq(rgb(c.text.danger), RGB(1, 100/255, 100/255))
	eq(rgb(c.text.warning), RGB(220/255, 0.2, 100/255)); eq(rgb(c.text.caution), RGB(200/255, 200/255, 0))
	eq(rgb(c.text.success), RGB(0.5, 240/255, 60/255)); eq(rgb(c.text.shared), RGB(120/255, 202/255, 0.2))
	eq(rgb(c.button.danger), RGB(0.9, 0.1, 0.1)); eq(c.button.danger.a, st.defaults.colors.button.danger.a, "Buttons > Danger's own opacity (100%), not Red's 0.5")
	for _, key in ipairs(STATE) do check(c.text[key].GetRGB, key .. ': the methods are kept') end
	eq(c.loot.pass.r, 1, 'the same source fed step 1'); eq(c.roles.HEALER.r, 0.5)
	for _, k in ipairs(OLD_STATE) do eq(rawget(c.text, k), nil, k) end
	eq(rawget(c.button, 'red'), nil)
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.colors
	eq(saved.text.danger.r, 1); eq(saved.text.danger.g, nil, 'AceDB keeps only the channel that differs')
	eq(saved.button.danger.r, 0.9); eq(saved.button.danger.a, nil)
end)

test('step 4: step by step across builds (Review Focus 5)', function()
	local raw = { colors = { version = 1, loot = { pass = { r = 0.3 } }, text = { red = { g = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.text.danger), RGB(220/255, 0.5, 100/255))
	eq(raw.colors.loot.pass.r, 0.3); eq(raw.colors.loot.pass.g, nil, 'step 1 is not run again: Pass keeps what step 1 gave it')
	eq(raw.colors.roles, nil, 'and no role is made'); eq(raw.colors.version, LAST())
	raw = { colors = { version = 3, text = { red = { r = 1 }, green = { g = 0.1 } }, loot = {} } }
	st:MigrateColors(raw)
	eq(raw.colors.text.danger.r, 1); eq(rgb(raw.colors.text.success), RGB(60/255, 0.1, 60/255)); eq(raw.theme, nil, 'steps 1 to 3 are not run again')
	eq(raw.colors.loot.pass, nil)
end)

test('step 4: a version-0 profile feeds Pass, Damage and Horde and Danger from the same Text > Red', function()
	local raw = { colors = { text = { red = { r = 1 } } } }
	st:MigrateColors(raw)
	for _, path in ipairs({ 'loot.pass', 'roles.DAMAGER', 'factions.Horde', 'text.danger' }) do
		eq(rgb(Slot(raw, path)), RGB(1, 100/255, 100/255), path)
	end
	eq(raw.colors.text.red, nil)
end)

test('step 4: untouched, nothing is written and nothing is saved', function()
	fresh(on({}))
	for _, key in ipairs(STATE) do eq(rgb(st.config.profile.colors.text[key]), rgb(st.defaults.colors.text[key]), key) end
	eq(rgb(st.config.profile.colors.button.danger), RGB(0.6, 0.1, 0.1))
	st.config:SetProfile('Two')
	eq(SaftUI_DB.profiles.Old.colors.text, nil, 'no Text group saved'); eq(SaftUI_DB.profiles.Old.colors.button, nil)
	local raw = { colors = {} }
	st:MigrateColors(raw); eq(raw.colors.text, nil, 'no group made'); eq(raw.colors.button, nil); eq(raw.colors.version, LAST())
end)

test('step 4: a partial color has its missing channels filled from the frozen old default, never an alpha', function()
	local raw = { colors = { version = 3, text = { white = { g = 0.5, a = 0.2 }, cyan = { r = 'x', b = 0.9 }, orange = { r = 0 } },
		button = { red = { g = 0.4, a = 0.1 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.text.strong), RGB(1, 0.5, 1)); eq(raw.colors.text.strong.a, nil)
	eq(rgb(raw.colors.text.shared), RGB(120/255, 202/255, 0.9), "a channel that isn't a number takes the old default's")
	eq(rgb(raw.colors.text.warning), RGB(0, 150/255, 100/255))
	eq(rgb(raw.colors.button.danger), RGB(0.6, 0.4, 0.1)); eq(raw.colors.button.danger.a, 1, "Red's 0.1 is never copied: step 5 writes 100%")
end)

test('step 4: a color still at its old default (an opacity alone, or to the byte) copies nothing', function()
	for _, grey in ipairs({ { a = 0.3 }, {}, { r = 1 }, { r = 1 - 0.001 } }) do
		local raw = { colors = { version = 3, text = { white = grey } } }
		st:MigrateColors(raw)
		eq(raw.colors.text.strong, nil, 'no Strong written'); eq(raw.colors.text.white, nil, 'but White is retired')
	end
	local raw = { colors = { version = 3, text = { red = { r = 220/255 + 0.001 } }, button = { red = { a = 0.3 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.text.danger, nil); eq(raw.colors.button.danger, nil, "Buttons > Red's opacity alone copies nothing")
end)

test('step 4: a color written into one that is there, else made with its group', function()
	local danger = { r = 0.1, g = 0.1, b = 0.1, a = 0.7 }
	local raw = { colors = { version = 3, text = { danger = danger, red = { r = 0.5 } } } }
	st:MigrateColors(raw)
	check(raw.colors.text.danger == danger, 'in place'); eq(danger.r, 0.5); eq(danger.g, 100/255); eq(danger.a, 0.7, 'never an alpha')
	raw = { colors = { version = 3, text = 'x', button = { red = { r = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.button.danger), RGB(0.5, 0.1, 0.1), 'Buttons > Danger made'); eq(raw.colors.text, 'x', 'a Text that is not a table is left alone')
end)

test('step 4: dead keys are retired even when they are not tables, and nothing raises', function()
	local raw = { colors = { version = 3, text = { white = 5, red = 'x', orange = true, yellow = {}, green = 0, cyan = 'y' }, button = { red = 5 } } }
	check(pcall(st.MigrateColors, st, raw))
	for _, k in ipairs(OLD_STATE) do eq(raw.colors.text[k], nil, k) end
	eq(raw.colors.button.red, nil)
	for _, key in ipairs(STATE) do eq(raw.colors.text[key], nil, key .. ': nothing copied from a value that is no color') end
end)

test('step 4 by version: 0 runs every step, 1 to 3 run from the next one, the last step runs nothing', function()
	local function profile(version)
		return { colors = { version = version, text = { red = { r = 1 }, white = { g = 0.9 }, grey = { r = 0.4 } }, button = { blue = { r = 0.5 }, red = { r = 0.9 } } } }
	end
	local raw = profile(0); st:MigrateColors(raw)
	eq(raw.colors.loot.pass.r, 1, 'step 1'); eq(raw.theme.accent.r, 0.5, 'step 2'); eq(raw.colors.text.muted.r, 0.4, 'step 3')
	eq(raw.colors.text.danger.r, 1, 'step 4'); eq(raw.colors.text.strong.g, 0.9); eq(raw.colors.button.danger.r, 0.9); eq(raw.colors.version, LAST())
	raw = profile(2); st:MigrateColors(raw)
	eq(raw.colors.loot, nil); eq(raw.theme, nil); eq(raw.colors.text.muted.r, 0.4, 'step 3 runs'); eq(raw.colors.text.danger.r, 1, 'step 4 runs')
	raw = profile(3); st:MigrateColors(raw)
	eq(raw.colors.text.muted, nil, 'step 3 is not run again'); eq(raw.colors.text.grey.r, 0.4); eq(raw.colors.text.danger.r, 1, 'step 4 runs'); eq(raw.colors.button.red, nil)
	raw = profile(LAST()); st:MigrateColors(raw)
	eq(raw.colors.text.danger, nil, 'at the last step nothing runs'); eq(raw.colors.text.red.r, 1, 'and the old keys are left as they are'); eq(raw.colors.version, LAST())
	raw = profile(LAST() + 5); st:MigrateColors(raw)
	eq(raw.colors.version, LAST() + 5, 'a version above the last is never lowered'); eq(raw.colors.text.danger, nil)
end)

test('step 4 on a real AceDB at version 0 to 3, and run twice', function()
	for version = 0, 3 do
		fresh(on({ colors = { version = version, text = { red = { r = 0.3 }, cyan = { g = 0.1 } }, button = { red = { b = 0.9 } } } }))
		local c = st.config.profile.colors
		eq(c.text.danger.r, 0.3, 'version ' .. version); eq(rgb(c.text.shared), RGB(120/255, 0.1, 250/255)); eq(c.button.danger.b, 0.9)
		eq(c.version, LAST())
		local once = Dump(c)
		st:MigrateColors(st.config.profile); eq(Dump(st.config.profile.colors), once, 'run twice: no change')
	end
	local raw = { colors = { text = { red = { r = 0.3 }, white = { r = 0.5 } }, button = { red = { r = 0.9 } } } }
	st:MigrateColors(raw); local once = Dump(raw)
	st:MigrateColors(raw); eq(Dump(raw), once, 'raw data, run twice')
end)

test('step 4: a switch to, a copy from and a reset of an unmigrated profile carry the state colors', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { text = { orange = { r = 1 } }, button = { red = { g = 0.9 } } } }
	SaftUI_DB.profiles.Three = { colors = { version = 3, text = { yellow = { b = 0.1 } } } }
	st.config:SetProfile('Two')
	eq(st.config.profile.colors.text.warning.r, 1); eq(st.config.profile.colors.button.danger.g, 0.9); eq(st.config.profile.colors.version, LAST())
	st.config:SetProfile('Old'); st.config:CopyProfile('Three')
	eq(rgb(st.config.profile.colors.text.caution), RGB(200/255, 200/255, 0.1), 'a copy from a profile at version 3: step 4 alone')
	st.config.profile.colors.text.caution:SetRGB(0.1, 0.1, 0.1); st.config:ResetProfile()
	eq(rgb(st.config.profile.colors.text.caution), YELLOW, 'a reset puts the default back')
end)

test('step 4 in combat: a switch migrates at once', function()
	fresh(on({})); SaftUI_DB.profiles.Two = { colors = { text = { red = { r = 1 } } } }
	stub.in_combat = true; st.config:SetProfile('Two')
	eq(st.config.profile.colors.text.danger.r, 1); eq(#stub.blocked, 0); stub.in_combat = false
end)

test('the frozen table holds every retired key, and is unchanged since Task 3', function()
	local old = st:GetModule('Colors').OLD_COLORS
	local want = { 'text.grey', 'text.white', 'text.red', 'text.orange', 'text.yellow', 'text.green', 'text.blue', 'text.purple', 'text.cyan',
		'button.red', 'button.green', 'button.blue', 'button.yellow', 'button.grey' }
	for _, key in ipairs(want) do check(old[key], key) end
	eq(rgb(old['text.cyan']), RGB(120/255, 202/255, 250/255)); eq(rgb(old['button.red']), RGB(0.6, 0.1, 0.1)); eq(old['button.red'].a, 0.8)
end)

------------------------------------------------------------------ step 5: opacity

local BUTTONS = { 'normal', 'hover', 'pushed', 'danger' }

test('step 5: every saved Buttons opacity goes back to 100%, in place, never nil', function()
	fresh(on({ colors = { button = { normal = { a = 0.3 }, hover = { r = 0.6, a = 0.1 }, pushed = { a = 0.5 }, danger = { g = 0.4, a = 0.5 } } } }))
	local b = st.config.profile.colors.button
	for _, k in ipairs(BUTTONS) do eq(b[k].a, 1, k); check(b[k].GetRGB, k .. ': the methods are kept') end
	eq(b.hover.r, 0.6, 'its color kept'); eq(b.danger.g, 0.4, "and Danger its own")
	eq(st.defaults.colors.button.hover.a, 1, 'the default is 100%')
	local raw = { colors = { version = 4, button = { hover = { a = 0.2 } } } }; st:MigrateColors(raw)
	eq(raw.colors.button.hover.a, 1); eq(raw.colors.button.normal, nil, 'no table made'); eq(raw.colors.version, LAST())
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.colors.button
	eq(saved.hover.r, 0.6); eq(saved.hover.a, nil, 'AceDB keeps no opacity that is the default')
	eq(saved.normal, nil, 'and nothing of a color that only had one')
end)

test('step 5 only touches opacity', function()
	fresh(on({}))
	local step = st:GetModule('Colors').MIGRATION_STEPS[5]
	eq(step.copy, nil); eq(step.retire, nil)
	eq(table.concat(step.opacity, ','), 'button.normal,button.hover,button.pushed,button.danger')
end)

test('step 5: a partial table keeps its colors and only its opacity changes; a table with no opacity gets 100%', function()
	local raw = { colors = { version = 4, button = { normal = { r = 0.9 }, hover = { a = 0.1 }, pushed = { r = 0.1, g = 0.2, b = 0.3, a = 0 }, danger = {} } } }
	st:MigrateColors(raw)
	local b = raw.colors.button
	eq(b.normal.r, 0.9); eq(b.normal.a, 1, 'a table with no opacity gets 100% written')
	eq(b.hover.a, 1); eq(b.hover.r, nil)
	eq(rgb(b.pushed), RGB(0.1, 0.2, 0.3)); eq(b.pushed.a, 1, 'even 0%')
	eq(b.danger.a, 1)
	eq(raw.colors.version, LAST())
end)

test('step 5: data it does not expect is left alone, and nothing raises', function()
	for _, bad in ipairs({ 'x', 5, true }) do
		local raw = { colors = { version = 4, button = bad } }
		check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button, bad, 'a Buttons group that is ' .. type(bad))
		eq(raw.colors.version, LAST())
	end
	local raw = { colors = { version = 4, button = { normal = 5, hover = 'x', pushed = true, danger = { a = 'x' } } } }
	check(pcall(st.MigrateColors, st, raw))
	eq(raw.colors.button.normal, 5); eq(raw.colors.button.hover, 'x'); eq(raw.colors.button.pushed, true, 'a color that is no table: left as it is')
	eq(raw.colors.button.danger.a, 1, 'an opacity that is no number is put right')
	raw = { colors = { version = 4 } }
	st:MigrateColors(raw); eq(raw.colors.button, nil, 'no Buttons group made'); eq(raw.colors.version, LAST())
end)

test('step 5: the other Buttons keys and other groups are untouched', function()
	local raw = { colors = { version = 4, button = { hover = { a = 0.2 }, grey = { a = 0.2 } }, text = { normal = { a = 0.4 } }, class = { MAGE = { a = 0.3 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.button.grey.a, 0.2, 'a key that is no Buttons color'); eq(raw.colors.text.normal.a, 0.4); eq(raw.colors.class.MAGE.a, 0.3)
end)

test('step 5 on a real AceDB at version 0 to 4, run twice, and never run again', function()
	for version = 0, 4 do
		fresh(on({ colors = { version = version, button = { hover = { r = 0.2, a = 0.3 }, normal = { a = 0.1 } } } }))
		local c = st.config.profile.colors
		eq(c.button.hover.a, 1, 'version ' .. version); eq(c.button.hover.r, 0.2); eq(c.button.normal.a, 1); eq(c.version, LAST())
		local once = Dump(c)
		st:MigrateColors(st.config.profile); eq(Dump(st.config.profile.colors), once, 'run twice: no change')
	end
	-- Once at the last step, an opacity chosen since stays.
	fresh(on({ colors = { version = LAST(), button = { hover = { a = 0.4 } } } }))
	eq(st.config.profile.colors.button.hover.a, 0.4, 'a profile at the last step keeps the opacity it was given after')
	st:MigrateColors(st.config.profile); eq(st.config.profile.colors.button.hover.a, 0.4, 'and a second run')
	fresh(on({ colors = { version = LAST() + 3, button = { hover = { a = 0.4 } } } }))
	eq(st.config.profile.colors.button.hover.a, 0.4); eq(st.config.profile.colors.version, LAST() + 3, 'a version above the last is never lowered')
end)

test('step 5: an opacity chosen after the migration survives the next login', function()
	fresh(on({ colors = { button = { hover = { a = 0.3 } } } }))
	eq(st.config.profile.colors.button.hover.a, 1)
	st.config.profile.colors.button.hover.a = 0.5 -- as the Colors tab's slider writes it
	st.config:SetProfile('Two'); st.config:SetProfile('Old')
	eq(st.config.profile.colors.button.hover.a, 0.5, 'a switch away and back keeps it')
	st:MigrateColors(st.config.profile)
	eq(st.config.profile.colors.button.hover.a, 0.5, 'a second run')
	local saved = SaftUI_DB
	fresh(saved)
	eq(st.config.profile.colors.button.hover.a, 0.5, 'and so does the next login')
end)

test('step 5: a profile created after the upgrade has every Buttons color at 100% and is migrated at once', function()
	fresh(on({}))
	st.config:SetProfile('Brand new')
	local b = st.config.profile.colors.button
	for _, k in ipairs(BUTTONS) do eq(b[k].a, 1, k) end
	eq(st.config.profile.colors.version, LAST())
	eq(rgb(b.hover), RGB(0.3, 0.5, 0.7), 'at their default colors')
end)

test('step 5: a switch to, a copy from and a reset of an unmigrated profile reset the opacities', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { button = { normal = { a = 0.2 }, pushed = { r = 0.4, a = 0.9 } } } }
	SaftUI_DB.profiles.Three = { colors = { version = 4, button = { hover = { a = 0.2 } } } }
	st.config:SetProfile('Two')
	eq(st.config.profile.colors.button.normal.a, 1); eq(st.config.profile.colors.button.pushed.a, 1); eq(st.config.profile.colors.button.pushed.r, 0.4)
	st.config:SetProfile('Old'); st.config:CopyProfile('Three')
	eq(st.config.profile.colors.button.hover.a, 1, 'a copy from a profile at version 4: step 5 alone')
	st.config.profile.colors.button.hover.a = 0.5; st.config:ResetProfile()
	eq(st.config.profile.colors.button.hover.a, 1, 'a reset puts 100% back')
end)

test('step 5 in combat: a switch migrates at once', function()
	fresh(on({})); SaftUI_DB.profiles.Two = { colors = { button = { hover = { a = 0.2 } } } }
	stub.in_combat = true; st.config:SetProfile('Two')
	eq(st.config.profile.colors.button.hover.a, 1); eq(#stub.blocked, 0); stub.in_combat = false
end)

test('step 5 after step 4: the Danger made from Buttons > Red is at 100% too, and its old 0.5 was never copied', function()
	local raw = { colors = { version = 3, button = { red = { r = 0.9, a = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.button.danger), RGB(0.9, 0.1, 0.1)); eq(raw.colors.button.danger.a, 1)
end)

------------------------------------------------------------------ step 6: Checked is Hover's old color

test('step 6 is the last step: it seeds Buttons > Checked from a customized Hover, and nothing else', function()
	fresh(on({}))
	local Colors = st:GetModule('Colors')
	eq(#Colors.MIGRATION_STEPS, 6)
	local step = Colors.MIGRATION_STEPS[6]
	eq(step.copy, nil); eq(step.retire, nil); eq(step.opacity, nil)
	eq(table.concat(step.seed[1], ','), 'button.hover,button.checked')
	-- (Step 6 retired nothing; step 7 now does, so OLD_COLORS holds the four since: step 7's test.)
end)

test('step 6: a Hover customized in color is copied into Checked, opacity and all; Hover keeps its own', function()
	for _, version in ipairs({ 5, 4, 0 }) do
		local raw = { colors = { version = version, button = { hover = { r = 0.9, g = 0.2, b = 0.6, a = version == 5 and 0.7 or 1 } } } }
		st:MigrateColors(raw)
		local b = raw.colors.button
		eq(rgb(b.checked), RGB(0.9, 0.2, 0.6), 'version ' .. version)
		eq(b.checked.a, version == 5 and 0.7 or 1, 'its opacity too (step 5 reset an older one first)')
		eq(rgb(b.hover), RGB(0.9, 0.2, 0.6), 'Hover is left as it is')
		eq(raw.colors.version, LAST())
	end
end)

test('step 6: one saved channel is enough, the rest comes from the default; a changed opacity alone counts', function()
	local raw = { colors = { version = 5, button = { hover = { r = 0.9 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.button.checked), RGB(0.9, 0.5, 0.7), "the other channels are Hover's default")
	raw = { colors = { version = 5, button = { hover = { a = 0.5 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.button.checked.a, 0.5); eq(rgb(raw.colors.button.checked), RGB(0.3, 0.5, 0.7))
end)

test("step 6: a Hover at its default (to the byte) seeds nothing; an untouched profile has the defaults", function()
	local raw = { colors = { version = 5, button = { hover = { r = 0.3, g = 0.5, b = 0.7, a = 1 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.button.checked, nil, 'no table made')
	raw = { colors = { version = 5 } }
	st:MigrateColors(raw); eq(raw.colors.button, nil, 'no Buttons group made'); eq(raw.colors.version, LAST())
	fresh(on({}))
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.3, 0.5, 0.7), 'the default')
	eq(st.config.profile.colors.button.checked.a, 1)
	st.config:SetProfile('Two')
	eq(SaftUI_DB.profiles.Old.colors.button, nil, 'nothing saved for it')
end)

test('step 6: a saved Checked is never overwritten by the seed', function()
	local raw = { colors = { version = 5, button = { hover = { r = 0.9, g = 0.2, b = 0.6 }, checked = { r = 0.1, g = 0.1, b = 0.1, a = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.button.checked), RGB(0.1, 0.1, 0.1), 'its color stays'); eq(raw.colors.button.checked.a, 0.5, 'and its opacity')
	eq(raw.colors.version, LAST())
end)

test('step 6: data it does not expect is left alone, and nothing raises', function()
	for _, bad in ipairs({ 'x', 5, true }) do
		local raw = { colors = { version = 5, button = bad } }
		check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button, bad)
	end
	for _, bad in ipairs({ 'x', 5, true }) do
		local raw = { colors = { version = 5, button = { hover = bad } } }
		check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button.checked, nil, 'a Hover that is ' .. type(bad))
	end
	local raw = { colors = { version = 5, button = { hover = { r = 'x', g = 0.1 } } } }
	check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button.checked.g, 0.1)
	eq(raw.colors.button.checked.r, 0.3, 'a channel that is no number takes the default')
end)

test('step 6 on a real AceDB: runs once, at login; a later Hover change does not reach Checked; Checked stays saved', function()
	fresh(on({ colors = { version = 5, button = { hover = { r = 0.9, g = 0.2, b = 0.6 } } } }))
	local b = st.config.profile.colors.button
	eq(rgb(b.checked), RGB(0.9, 0.2, 0.6)); eq(st.config.profile.colors.version, LAST())
	b.hover:SetRGB(0.1, 0.1, 0.1)
	st:MigrateColors(st.config.profile)
	eq(rgb(b.checked), RGB(0.9, 0.2, 0.6), 'a second run changes nothing')
	st.config:SetProfile('Two'); st.config:SetProfile('Old')
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.9, 0.2, 0.6), 'a switch away and back')
	local saved = SaftUI_DB
	fresh(saved)
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.9, 0.2, 0.6), 'and the next login')
	eq(rgb(st.config.profile.colors.button.hover), RGB(0.1, 0.1, 0.1))
end)

test('step 6: a switch to, a copy from and a reset of a profile', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { version = 5, button = { hover = { r = 0.9, g = 0.2, b = 0.6 } } } }
	SaftUI_DB.profiles.Three = { colors = { version = 5, button = { hover = { r = 0.1, g = 0.9, b = 0.3 } } } }
	st.config:SetProfile('Two')
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.9, 0.2, 0.6), 'a switch to an unmigrated profile')
	st.config:SetProfile('Old')
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.3, 0.5, 0.7), 'the other profile is left at its default')
	st.config:CopyProfile('Three')
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.1, 0.9, 0.3), 'a copy from an unmigrated profile')
	st.config:ResetProfile()
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.3, 0.5, 0.7), 'a reset: the defaults')
	eq(rgb(st.config.profile.colors.button.hover), RGB(0.3, 0.5, 0.7))
	eq(st.config.profile.colors.version, LAST())
end)

test('step 6 in combat: a switch migrates at once', function()
	fresh(on({})); SaftUI_DB.profiles.Two = { colors = { version = 5, button = { hover = { r = 0.9, g = 0.2, b = 0.6 } } } }
	stub.in_combat = true; st.config:SetProfile('Two')
	eq(rgb(st.config.profile.colors.button.checked), RGB(0.9, 0.2, 0.6)); eq(#stub.blocked, 0); stub.in_combat = false
end)

local FOUR = { 'normal', 'hover', 'pushed', 'checked' }

-- Customized Buttons state colors, with colors of every other group that must come through untouched.
local function customized(version)
	return { colors = { version = version,
		button = {
			normal = { r = 0, g = 1, b = 0 }, hover = { r = 1, g = 0, b = 0, a = 0.5 }, pushed = { r = 0, g = 0, b = 1 },
			checked = { r = 1, g = 1, b = 0 }, danger = { r = 0.9, g = 0.2, b = 0.2 } },
		class = { MAGE = { r = 0.1, g = 0.2, b = 0.3 } },
		reaction = { [4] = { r = 0.5, g = 0.5, b = 0.5 } },
		experience = { rested = { r = 0.9, g = 0.9, b = 0.1 } } },
		theme = { accent = { r = 0.4, g = 0.5, b = 0.6 } } }
end

-- Everything but the four keys, as one string: what the retire must leave alone
-- (Danger by its channels: step 5 puts its opacity back to 100%, as it always did).
local function others(raw)
	local c = raw.colors
	local d = c.button and c.button.danger
	return Dump({ danger = d and { d.r, d.g, d.b }, class = c.class, reaction = c.reaction, experience = c.experience, accent = raw.theme.accent })
end

test('steps 7 and 8 drop the four Buttons state colors and keep Danger (the states are the Accent\'s now)', function()
	fresh(on({}), true)
	local Colors = st:GetModule('Colors')
	eq(#Colors.MIGRATION_STEPS, 8, 'step 8 is the last step')
	for _, n in ipairs({ 7, 8 }) do eq(table.concat(Colors.MIGRATION_STEPS[n].retire, ','), 'button.normal,button.hover,button.pushed,button.checked', 'step ' .. n) end
	local raw = customized(6)
	local want = others(raw)
	st:MigrateColors(raw)
	local button = raw.colors.button
	for _, key in ipairs(FOUR) do eq(button[key], nil, key .. ' dropped') end
	eq(rgb(button.danger), RGB(0.9, 0.2, 0.2), 'Danger kept')
	eq(others(raw), want, 'no other color touched')
	eq(raw.colors.version, 8)
	local once = Dump(raw)
	st:MigrateColors(raw); eq(Dump(raw), once, 'run twice: no change')
	-- a profile before step 6 seeds Checked from Hover, then the retires drop both: neither survives
	local old = { colors = { version = 5, button = { hover = { r = 1, g = 0, b = 0 } } } }
	st:MigrateColors(old)
	eq(old.colors.button.hover, nil); eq(old.colors.button.checked, nil); eq(old.colors.version, 8)
	local frozen = Colors.OLD_COLORS
	eq(rgb(frozen['button.normal']), RGB(0.1, 0.1, 0.1)); eq(rgb(frozen['button.hover']), RGB(0.3, 0.5, 0.7))
	eq(rgb(frozen['button.pushed']), RGB(0.3, 0.4, 0.5)); eq(rgb(frozen['button.checked']), RGB(0.3, 0.5, 0.7))
	for _, key in ipairs(FOUR) do eq(frozen['button.' .. key].a, 1, key .. ' opaque') end
end)

test('step 8: a profile saved at every earlier step loses the four and nothing else, once', function()
	fresh(on({}), true)
	for version = 0, 7 do
		local raw = customized(version)
		local want = others(raw)
		check(pcall(st.MigrateColors, st, raw), 'version ' .. version .. ': no error')
		for _, key in ipairs(FOUR) do eq(raw.colors.button[key], nil, 'version ' .. version .. ': ' .. key .. ' gone') end
		-- (version 0 and 1 run steps 1 and 2 too: the accent takes Buttons > Blue, which this profile has not)
		eq(others(raw), want, 'version ' .. version .. ': every other color as it was')
		eq(raw.colors.version, 8, 'version ' .. version)
		-- it ran once: a state color saved after it (a hand edit) is not dropped by a second run
		raw.colors.button.hover = { r = 0.2, g = 0.2, b = 0.2 }
		st:MigrateColors(raw)
		eq(raw.colors.button.hover.r, 0.2, 'version ' .. version .. ': a second run drops nothing')
	end
end)

test('step 8: no Buttons group, or one that is no table, is left as it is', function()
	fresh(on({}), true)
	for _, bad in ipairs({ 'x', 5, true }) do
		local raw = { colors = { version = 7, button = bad } }
		check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button, bad); eq(raw.colors.version, 8)
	end
	local raw = { colors = { version = 7 } }
	st:MigrateColors(raw); eq(raw.colors.button, nil, 'no Buttons group made'); eq(raw.colors.version, 8)
	raw = { colors = { version = 7, button = { normal = 'x', hover = 4, danger = { r = 1 } } } }
	check(pcall(st.MigrateColors, st, raw)); eq(raw.colors.button.normal, nil); eq(raw.colors.button.hover, nil); eq(raw.colors.button.danger.r, 1)
end)

test('step 8 on a live profile: the saved Buttons colors go at login, the keys are not colors any more', function()
	fresh(on(customized(7)), true)
	local colors = st.config.profile.colors
	eq(colors.version, 8)
	for _, key in ipairs(FOUR) do
		eq(colors.button[key], nil, key .. ' gone from the live profile')
		check(not pcall(st.Color, st, 'button', key), "st:Color('button', '" .. key .. "') errors at the caller")
	end
	eq(st:Color('button', 'danger').r, 0.9, 'Danger kept')
	eq(rgb(st:Color('class', 'MAGE')), RGB(0.1, 0.2, 0.3), 'and the other colors')
	eq(st.config.profile.theme.accent.r, 0.4, 'the Accent')
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.colors.button
	for _, key in ipairs(FOUR) do eq(saved[key], nil, key .. ' not saved') end
	eq(saved.danger.r, 0.9)
	-- the same at version 6 (step 7 ran on a live profile while the defaults stood: it put each back): nothing left
	fresh(on(customized(6)), true)
	for _, key in ipairs(FOUR) do eq(st.config.profile.colors.button[key], nil, 'from version 6: ' .. key) end
end)

test('step 8: a switch to, a copy from and a reset of an unmigrated profile', function()
	fresh(on({}), true)
	SaftUI_DB.profiles.Two = customized(5)
	SaftUI_DB.profiles.Three = customized(7)
	st.config:SetProfile('Two')
	for _, key in ipairs(FOUR) do eq(st.config.profile.colors.button[key], nil, 'a switch: ' .. key) end
	eq(st.config.profile.colors.version, 8); eq(st.config.profile.colors.button.danger.r, 0.9)
	st.config:SetProfile('Old'); st.config:CopyProfile('Three')
	for _, key in ipairs(FOUR) do eq(st.config.profile.colors.button[key], nil, 'a copy: ' .. key) end
	eq(st.config.profile.colors.version, 8); eq(st.config.profile.colors.button.danger.r, 0.9)
	st.config.profile.colors.button.danger:SetRGB(0.1, 0.1, 0.1); st.config:ResetProfile()
	for _, key in ipairs(FOUR) do eq(st.config.profile.colors.button[key], nil, 'a reset: ' .. key) end
	eq(rgb(st.config.profile.colors.button.danger), RGB(0.6, 0.1, 0.1), 'the default Danger')
end)

test('step 8 in combat: a switch migrates at once', function()
	fresh(on({}), true); SaftUI_DB.profiles.Two = customized(7)
	stub.in_combat = true; st.config:SetProfile('Two')
	eq(st.config.profile.colors.button.hover, nil); eq(st.config.profile.colors.version, 8); eq(#stub.blocked, 0); stub.in_combat = false
end)

test('step 8 migrates through a raising step like the others: the profile still loads', function()
	-- a Buttons group of the wrong shape and a hand-edited version never stop the login
	fresh(on({ colors = { version = 'x', button = { hover = 'x', danger = { r = 0.9 } } } }), true)
	eq(st.config.profile.colors.version, 8); eq(st.config.profile.colors.button.hover, nil); eq(st.config.profile.colors.button.danger.r, 0.9)
end)
