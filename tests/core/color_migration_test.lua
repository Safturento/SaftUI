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
	st.config:SetProfile('Two')
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
}
test('a profile saved before any of this runs every step at once, in order', function()
	fresh(on(OLD_SAVED()))
	for path, want in pairs(EXPECTED) do eq(rgb(Slot(st.config.profile, path)), want, path) end
	eq(st.config.profile.colors.version, LAST())
end)

-- Text > Grey's default is #b4b4b4 (180), brighter than the #969696 it shipped
-- with. CO.OLD_COLORS keeps the old 150 frozen, but no step reads text.grey
-- (it is not a source), so it only serves a profile that predates a step.
test('Text > Grey: a profile that never changed it gets 180; one that customized it keeps its own', function()
	fresh(on({}))
	eq(rgb(st.config.profile.colors.text.grey), RGB(180/255, 180/255, 180/255), 'the new default')
	fresh(on({ colors = { text = { grey = { r = 0.4, g = 0.5, b = 0.6 } } } }))
	eq(rgb(st.config.profile.colors.text.grey), RGB(0.4, 0.5, 0.6), 'a customized grey is its own')
	fresh(on({ colors = { text = { grey = { r = 150/255, g = 150/255, b = 150/255 } } } }))
	eq(rgb(st.config.profile.colors.text.grey), RGB(150/255, 150/255, 150/255), 'one saved at the old default is a choice and stays')
	eq(rgb(st:GetModule('Colors').OLD_COLORS['text.grey']), RGB(150/255, 150/255, 150/255), 'the frozen table is never edited')
end)
