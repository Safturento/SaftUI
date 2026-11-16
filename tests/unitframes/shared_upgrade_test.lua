-- The upgrade to shared settings, on a real AceDB-3.0 (tests/unitframes/shared_world.lua's SW.acedb:
-- its logout strips what equals a default, its login fills the defaults back and makes a missing
-- table through its wildcards): after the conversion every member shows exactly what it showed, on an
-- untouched profile and a customized one, through a logout and a second login; the own flags are
-- where a member differs; a unit frame profile of another name converts by itself; a fresh profile
-- writes nothing into All units.
--
-- Nothing is wired yet: a source scan pins that no file but config/shared.lua calls the conversion,
-- the sync or the update, and a case loads the files and logs in on an existing profile and finds
-- nothing added to it (no All units, no flags, no marker, no backup).
local SW = load_test_file('unitframes/shared_world.lua')

local st, UF

local function world()
	st, UF = SW.world()
end

local function profile_of(db, name)
	return db.profile.unitframes.profiles[name or 'SaftUI']
end

local function owned(profile)
	local out = {}
	for _, unit in ipairs(SW.MEMBERS) do
		local keys = {}
		for _, entry in ipairs(UF.SHARED) do
			local own = rawget(profile[unit], 'own')
			if own and own[entry.key] == true then keys[#keys + 1] = entry.key end
		end
		table.sort(keys)
		out[unit] = table.concat(keys, ',')
	end
	return out
end

local function same_owned(a, b, label)
	for _, unit in ipairs(SW.MEMBERS) do eq(a[unit], b[unit], label .. ': ' .. unit .. ' owns the same') end
end

-- The values (not the empty tables AceDB leaves behind) under a saved table, as 'a.b.c', sorted.
local function leaves(t, prefix, out)
	out = out or {}
	for k, v in pairs(t or {}) do
		local path = (prefix and (prefix .. '.') or '') .. tostring(k)
		if type(v) == 'table' then leaves(v, path, out) else out[#out + 1] = path end
	end
	table.sort(out)
	return out
end

local function shows_the_same(before, profile, label)
	local ok, diffs = SW.same(before, SW.snapshot(profile))
	check(ok, label .. ': ' .. table.concat(diffs, ', '))
end

test('an untouched profile: every member shows the same after the upgrade, through a logout and a login', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	local before = SW.snapshot(profile)
	UF:ConvertShared(profile)
	eq(UF:SyncShared(profile), 0, 'the sync has nothing to do')
	shows_the_same(before, profile, 'after the conversion')
	local flags = owned(profile)
	local count = 0
	for _, unit in ipairs(SW.MEMBERS) do
		for _ in flags[unit]:gmatch('[^,]+') do count = count + 1 end
	end
	eq(count, 155, 'the owned settings of a fresh profile')

	db = SW.relog(db)
	profile = profile_of(db)
	eq(rawget(profile.all, 'version'), 1, 'the marker survived the logout')
	same_owned(flags, owned(profile), 'after the login')
	UF:ConvertShared(profile)
	same_owned(flags, owned(profile), 'the conversion does nothing a second time')
	eq(UF:SyncShared(profile), 0, 'the sync writes nothing after a login')
	shows_the_same(before, profile, 'after the login')

	-- And a third time: nothing drifts at each login.
	db = SW.relog(db)
	profile = profile_of(db)
	eq(UF:SyncShared(profile), 0)
	shows_the_same(before, profile, 'after another login')
end)

test('a customized profile: the same, and the owns are exactly where a member differs', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	SW.customize(profile)
	-- A login first, so the snapshot holds what AceDB fills in (a color's alpha, say): the compare is of the upgrade.
	db = SW.relog(db)
	profile = profile_of(db)
	local before = SW.snapshot(profile)
	UF:ConvertShared(profile)
	eq(UF:SyncShared(profile), 0)
	shows_the_same(before, profile, 'after the conversion')
	eq(profile.all.name.font, 'pixel', 'All units takes the font most units show')
	for _, unit in ipairs(SW.MEMBERS) do
		eq(rawget(profile[unit], 'own')['name.font'], unit == 'target' or nil, unit .. ' name font')
	end
	-- Party's level is now what most show; Raid 10 and Raid 40 still own theirs.
	eq(profile.all.name.showLevel, true)
	check(rawget(profile.party, 'own')['name.showLevel'] ~= true, 'party follows the level')
	eq(rawget(profile.raid10, 'own')['name.showLevel'], true)
	eq(rawget(profile.raid40, 'own')['name.showLevel'], true)
	-- A string offset differs from 0: owned, and left as the string it was.
	eq(rawget(profile.boss, 'own')['raidtargetindicator.position'], true)
	eq(profile.boss.raidtargetindicator.position.x_off, '5')
	-- A position with no anchor element: owned, and the table as it was.
	eq(rawget(profile.focus, 'own')['name.position'], true)
	eq(profile.focus.name.position.element, false)
	-- The colors in each shape.
	eq(rawget(profile.focus, 'own')['castbar.colors.normal'], true)
	eq(rawget(profile.target, 'own')['castbar.colors.normal'], true)
	eq(rawget(profile.target, 'own')['buffs.size'], true)
	eq(rawget(profile.player, 'own')['frame.theme'], true)
	eq(rawget(profile.pet, 'own')['power.enable'], true)
	local flags = owned(profile)

	db = SW.relog(db)
	profile = profile_of(db)
	same_owned(flags, owned(profile), 'after the login')
	UF:ConvertShared(profile)
	same_owned(flags, owned(profile), 'the conversion does nothing a second time')
	eq(UF:SyncShared(profile), 0, 'the sync writes nothing after a login')
	shows_the_same(before, profile, 'after the login')
	eq(profile.all.name.font, 'pixel')
	eq(profile.target.name.font.font_name, 'Homespun', 'the typeface survived')
	eq(profile.focus.castbar.colors.normal.r, 1)
	local r, g, b = profile.target.castbar.colors.normal:GetRGB()
	eq(r .. g .. b, '010')
end)

test('a unit frame profile of another name converts by itself', function()
	world()
	local db = SW.acedb({})
	local original = profile_of(db)
	local healer = profile_of(db, 'Healer')
	healer.target.name.font = 'pixel'
	healer.player.name.font = 'pixel'
	healer.focus.name.font = 'pixel'
	local before = SW.snapshot(healer)
	UF:ConvertShared(healer)
	shows_the_same(before, healer, 'Healer')
	eq(rawget(healer.all, 'version'), 1)
	eq(rawget(original.all, 'version'), nil, 'SaftUI is untouched')
	eq(rawget(original.target, 'own'), nil)
	eq(healer.all.name.font, 'normal', 'the majority of eleven')
	eq(rawget(healer.target, 'own')['name.font'], true)
	db = SW.relog(db)
	healer = profile_of(db, 'Healer')
	eq(rawget(healer.all, 'version'), 1)
	eq(UF:SyncShared(healer), 0)
	shows_the_same(before, healer, 'Healer after a login')
	eq(rawget(profile_of(db).all, 'version'), nil, 'SaftUI is still unconverted')
end)

test('a fresh profile writes nothing into All units', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	UF:ConvertShared(profile)
	-- What AceDB keeps of All units at the logout: the marker, and nothing the defaults give.
	stub.fire_event('PLAYER_LOGOUT')
	local saved = rawget(db.sv.profiles.SaftUI.unitframes.profiles.SaftUI, 'all')
	eq(type(saved), 'table', 'All units is saved')
	eq(table.concat(leaves(saved), ','), 'version', 'only the marker')
end)

test('the backup survives a logout and puts the unit tables back', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	SW.customize(profile)
	db = SW.relog(db)
	profile = profile_of(db)
	local before = SW.snapshot(profile)
	UF:PrepareShared(profile)
	eq(rawget(profile, 'backup') ~= nil, true)
	profile.target.name.font = 'normal'
	profile.player.name.font = 'normal'
	db = SW.relog(db)
	profile = profile_of(db)
	eq(UF.HasSharedBackup(profile), true, 'the backup is in the saved data')
	check(UF:RestoreShared(profile))
	eq(UF:SharedReady(profile), false)
	shows_the_same(before, profile, 'after the restore')
	for _, unit in ipairs(SW.MEMBERS) do eq(rawget(profile[unit], 'own'), nil, unit .. ' has no flags') end
	-- The restored profile converts again, to the same.
	UF:PrepareShared(profile)
	shows_the_same(before, profile, 'converted again')
end)

test('nothing is wired: loading the files and logging in on an existing profile adds nothing to it', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	SW.customize(profile)
	db = SW.relog(db)
	profile = profile_of(db)
	-- What a login does to the profile: the unit frames' config is read.
	UF:GetProfileConfig()
	local before = SW.snapshot(profile)
	stub.fire_event('PLAYER_LOGIN')
	stub.fire_event('PLAYER_LOGOUT')
	db = SW.relog(db)
	profile = profile_of(db)
	check(rawget(profile.all, 'version') == nil, 'no marker')
	eq(rawget(profile, 'backup'), nil, 'no backup')
	for _, unit in ipairs(SW.MEMBERS) do
		local own = rawget(profile[unit], 'own')
		local flags = 0
		for key, value in pairs(own or {}) do
			if UF.SHARED_BY_KEY[key] and value ~= nil then flags = flags + 1 end
		end
		eq(flags, 0, unit .. ' has no own flags')
	end
	shows_the_same(before, profile, 'after the login')
	-- And the saved data holds no All units: at a logout AceDB strips what equals a default.
	stub.fire_event('PLAYER_LOGOUT')
	local saved = rawget(db.sv.profiles.SaftUI.unitframes.profiles.SaftUI, 'all')
	eq(table.concat(leaves(saved), ','), '', 'no All units saved')
end)

test('nothing is wired: no unit frame file but config/shared.lua calls the conversion, the sync or the update', function()
	local words = { 'ConvertShared', 'SyncShared', 'PrepareShared', 'RestoreShared', 'UpdateShared', 'PropagateShared',
		'SetShared', 'FollowAll', 'ApplyToAll', 'OwnShared', 'SharedReady' }
	local T = load_test_file('lib/theme_helpers.lua')
	local scanned = 0
	for _, path in ipairs((T.saftui_files())) do
		if path:sub(1, 15) == 'SaftUI-Unitfram' and path ~= 'SaftUI-Unitframes/config/shared.lua' then
			local source = read_saftui_source(path)
			if source then
				scanned = scanned + 1
				for _, word in ipairs(words) do
					check(not source:find(word, 1, true), path .. ' calls ' .. word .. ' before the wiring task')
				end
			end
		end
	end
	check(scanned > 30, 'it scanned ' .. scanned .. ' files')
end)
