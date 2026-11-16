-- The upgrade to shared settings, on a real AceDB-3.0 (tests/unitframes/shared_world.lua's SW.acedb:
-- its logout strips what equals a default, its login fills the defaults back and makes a missing
-- table through its wildcards): after the conversion every member shows exactly what it showed, on an
-- untouched profile and a customized one, through a logout and a second login; the own flags are
-- where a member differs; a unit frame profile of another name converts by itself; a fresh profile
-- writes nothing into All units.
--
-- Wired (UF:OnEnable, UF:UpdateConfig): the real OnEnable converts and syncs before anything is spawned and a
-- second login writes nothing; a profile it can't convert (an element not registered, a plain import, a newer
-- marker, an error) is left exactly as it was, says why once and has no share on any page; /sui uf restore puts
-- the backup back and no login converts the profile again until it is asked (/sui uf share); a profile switch
-- in combat converts the new profile with table writes only. A source scan (shared_guard_test.lua) lists the
-- only functions that may call the API.
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
	eq(table.concat(leaves(saved), ','), 'debuffs.enable,version', "only All units' own default (Debuffs on) and the marker")
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
	for _, unit in ipairs(SW.MEMBERS) do
		for _, entry in ipairs(UF.SHARED) do
			local own = rawget(profile[unit], 'own')
			check(not (own and own[entry.key]), unit .. ' ' .. entry.key .. ' has no flag')
		end
	end
	-- The restored profile converts again, to the same.
	UF:PrepareShared(profile)
	shows_the_same(before, profile, 'converted again')
end)


------------------------------------------------------------------ wired: the real OnEnable and UpdateConfig

-- Every value in a profile as 'path = value', sorted (empty tables and functions left out): two listings
-- equal mean nothing in the profile changed.
local function listing(profile)
	local out = {}
	local function walk(value, prefix)
		if type(value) ~= 'table' then
			out[#out + 1] = prefix .. ' = ' .. tostring(value)
			return
		end
		for k, v in pairs(value) do
			if type(v) ~= 'function' then walk(v, (prefix and (prefix .. '.') or '') .. tostring(k)) end
		end
	end
	walk(profile)
	table.sort(out)
	return table.concat(out, '\n')
end

-- The lines printed while fn runs.
local function printed_by(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		table.insert(lines, table.concat(parts, ' '))
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

-- The number of owned settings over every member.
local function owned_count(profile)
	local flags, count = owned(profile), 0
	for _, unit in ipairs(SW.MEMBERS) do
		for _ in flags[unit]:gmatch('[^,]+') do count = count + 1 end
	end
	return count
end

-- How many options of the tree have a share.
local function shares_in(tree)
	if not each_option then load_test_file('lib/options_walk.lua') end
	local n = 0
	each_option({ args = { Unitframes = tree } }, function(option)
		if type(option) == 'table' and option.share ~= nil then n = n + 1 end
	end)
	return n
end

local function spawned_ready(record)
	local ready = 0
	for _, spawn in ipairs(record.spawns) do
		if spawn[2] then ready = ready + 1 end
	end
	return ready, #record.spawns
end

-- The saved file's unit frame profile (what the game keeps) as a string, for comparing two logins.
local function file_listing(sv, name)
	return listing(sv.profiles.SaftUI.unitframes.profiles[name or 'SaftUI'])
end

-- A logout and a login on the same saved data, the way the game does them: the saved file as it is after the
-- logout, and a new AceDB over a copy of it.
local function logout_login(db)
	local file = SW.logout(db)
	return file, SW.acedb_from(SW.saved_copy(file))
end

for _, customized in ipairs({ false, true }) do
	test('wired (' .. (customized and 'customized' or 'untouched') .. '): OnEnable converts and syncs before anything is spawned; every unit shows what it showed, through a logout and a login; a second login writes nothing', function()
		world()
		local db = SW.acedb({})
		if customized then SW.customize(profile_of(db)) end
		local file0
		file0, db = logout_login(SW.relog(db)) -- the file as the player has it, and a login over it
		local profile = profile_of(db)
		local units0, snap = SW.saved_units(file0), SW.snapshot(profile)
		eq(UF:SharedReady(profile), false, 'not converted before the login')
		eq(rawget(profile, 'all'), nil, 'no All units yet')

		local record = SW.enable()
		local ready, total = spawned_ready(record)
		check(total > 0, 'frames were spawned')
		eq(ready, total, 'every frame was spawned on a converted profile')
		eq(UF:SharedReady(profile), true)
		shows_the_same(snap, profile, 'after the first login')
		check(UF.HasSharedBackup(profile), 'the backup exists')
		if not customized then eq(owned_count(profile), 155, 'the owned settings of a fresh profile') end
		local when = rawget(profile, 'backup').when
		eq(#take_errors(), 0, 'no error')
		local flags = owned(profile)

		-- A logout: no unit's saved configuration changed (the flags, All units and the backup are what is added).
		local file1
		file1, db = logout_login(db)
		local diffs = SW.effective_diff(units0, SW.saved_units(file1))
		eq(#diffs, 0, 'no unit\'s saved configuration changed: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 20)))
		check(file_listing(file1):find('backup', 1, true), 'the backup is in the saved file')

		-- The second login: nothing is converted and nothing is written.
		profile = profile_of(db)
		record = SW.enable()
		eq(spawned_ready(record), #record.spawns, 'ready at the second login too')
		same_owned(flags, owned(profile), 'the second login')
		eq(rawget(profile, 'backup').when, when, 'the backup is the first one')
		shows_the_same(snap, profile, 'after the second login')
		local file2
		file2, db = logout_login(db)
		check(file_listing(file2) == file_listing(file1), 'the second login wrote nothing: the saved file is the same')

		-- And a switch to another profile and back moves nothing.
		profile = profile_of(db)
		SW.enable()
		db.profile.unitframes.config_profile = 'Other'
		UF:UpdateConfig()
		eq(UF:SharedReady(profile_of(db, 'Other')), true, 'the other profile converted when switched to')
		db.profile.unitframes.config_profile = 'SaftUI'
		UF:UpdateConfig()
		local file3 = SW.logout(db)
		diffs = SW.effective_diff(units0, SW.saved_units(file3))
		eq(#diffs, 0, 'a switch away and back moves nothing: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 20)))
		eq(#take_errors(), 0, 'no error')
	end)
end

-- What each way a profile can't be converted does: nothing is written, the frames are built from the stored
-- values, no page draws a share and All units' entry says why, one plain message says so once (not per
-- frame, not per update).
local function cannot_convert(label, state, prepare)
	test('wired: ' .. label .. ' leaves the profile exactly as it was, says so once, and draws no share', function()
		world()
		local db = SW.acedb({})
		SW.customize(profile_of(db))
		local file0
		file0, db = logout_login(SW.relog(db))
		local units0 = SW.saved_units(file0)
		local profile = profile_of(db)
		local after = prepare(profile, db)
		local record
		local lines = printed_by(function()
			record = SW.enable()
			-- Updates after the login (a profile change, the option edits that update everything).
			for _ = 1, 3 do UF:UpdateConfig() end
		end)
		eq(#take_errors() <= 1, true, 'at most the one error the failing step raised')
		eq(UF:SharedReady(profile), false, 'not in force')
		eq(UF:SharedState(profile), state, 'the state')
		eq(spawned_ready(record), 0, 'the frames were built from the stored values')
		local told = 0
		for _, line in ipairs(lines) do
			if line:find('SaftUI', 1, true) then told = told + 1 end
		end
		eq(told, 1, 'one message, once: ' .. table.concat(lines, ' | '))
		local tree = UF:GetConfigTable()
		eq(shares_in(tree), 0, 'no page has a share on any row')
		check(tree.args.all.args.general.args.notice ~= nil, 'All units says why instead of showing settings')
		check(tree.args.all.args.general.args.parts == nil, 'and has no settings')
		if after then after() end
		local file1 = SW.logout(db)
		local diffs = SW.effective_diff(units0, SW.saved_units(file1))
		eq(#diffs, 0, 'no unit\'s saved configuration changed: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 20)))
		local saved = file1.profiles.SaftUI.unitframes.profiles.SaftUI
		eq(saved.backup, nil, 'no backup was made')
		local all = rawget(saved, 'all')
		eq(all == nil or all.version ~= UF.SHARED_VERSION or state == 'newer', true, 'no marker was written')
		for _, unit in ipairs(SW.MEMBERS) do
			local flags = type(saved[unit]) == 'table' and saved[unit].own
			check(flags == nil or next(flags) == nil, unit .. ' has no own flags')
		end
	end)
end

cannot_convert('an element that did not load', 'missing', function()
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil
	return function() UF.elements.Castbar = castbar end
end)

cannot_convert('a newer marker (a downgrade, then this version)', 'newer', function(profile)
	local all = profile.all
	rawset(all, 'version', UF.SHARED_VERSION + 1)
end)

cannot_convert('an error anywhere in the conversion', 'failed', function(profile)
	-- A member that fails when read, until after the logout.
	local good = profile.pet
	rawset(profile, 'pet', setmetatable({}, { __index = function() error('boom', 0) end }))
	return function() rawset(profile, 'pet', good) end
end)

test('wired: a plain imported profile is left alone in the session and converts at the next login', function()
	world()
	local db = SW.acedb({})
	SW.customize(profile_of(db))
	db = SW.relog(db)
	local record = SW.enable()
	local imported = SW.saved_copy(profile_of(db))
	imported.all, imported.backup = nil, nil
	-- Another profile's data as the game's import makes it: plain tables, only what its export held.
	db.profile.unitframes.profiles.Imported = imported
	local base_listing = listing(imported)
	db.profile.unitframes.config_profile = 'Imported'
	local lines = printed_by(function()
		UF:UpdateConfig()
		UF:UpdateConfig()
		UF:UpdateConfig()
	end)
	eq(UF:SharedState(), 'plain')
	eq(UF:SharedReady(), false)
	check(listing(imported) == base_listing, 'nothing was written into it')
	eq(rawget(imported, 'all'), nil, 'no All units made')
	local told = 0
	for _, line in ipairs(lines) do
		if line:find('SaftUI', 1, true) then told = told + 1 end
	end
	eq(told, 1, 'one message: ' .. table.concat(lines, ' | '))
	check(lines[1] and lines[1]:find('next login', 1, true), 'it says the next login')
	eq(shares_in(UF:GetConfigTable()), 0, 'no share is drawn')
	-- The next login gives it AceDB's tables and converts it from its own values.
	local base = SW.snapshot(profile_of(db, 'Imported'))
	db = SW.relog(db)
	check(rawget(profile_of(db, 'Imported'), 'all') == nil)
	record = SW.enable()
	eq(UF:SharedReady(), true, 'converted at the login')
	local ok2, d2 = SW.same(base, SW.snapshot(profile_of(db, 'Imported')))
	check(ok2, 'it shows what its export held: ' .. table.concat(d2, ', ', 1, math.min(#d2, 20)))
end)

------------------------------------------------------------------ /sui uf restore and /sui uf share

test('/sui uf restore: says what it would do, then puts the profile back as the backup has it, with no reload, and no login converts it again by itself', function()
	world()
	local db = SW.acedb({})
	SW.customize(profile_of(db))
	db = SW.relog(db)
	local profile = profile_of(db)
	local before, snap = SW.effective(profile), SW.snapshot(profile)
	SW.enable()
	-- Edits after the conversion: a unit's place and a plate (kept by a restore), a shared setting (put back).
	UF:SetShared('all', 'name.alpha', 0.5)
	UF:SetShared('player', 'buffs.size', 31)
	profile.player.width = 411
	snap.player.width = 411 -- a unit's own size is not what a restore puts back
	check(UF:SharedReady(profile))
	local reloads = 0
	ReloadUI = function() reloads = reloads + 1 end

	local lines = printed_by(function() UF:RunShareCommand('restore') end)
	eq(#lines, 1, 'one line')
	check(lines[1]:find('restore confirm', 1, true), 'it asks for confirm: ' .. tostring(lines[1]))
	check(lines[1]:find('as they were on', 1, true), 'naming the day of the backup')
	eq(UF:SharedReady(profile), true, 'nothing was done')

	lines = printed_by(function() UF:RunShareCommand('restore confirm') end)
	eq(#lines, 1, 'one line: ' .. table.concat(lines, ' | '))
	check(lines[1]:find('are back', 1, true) and lines[1]:find('sharing is off', 1, true), 'says what it did: ' .. tostring(lines[1]))
	eq(reloads, 0, 'no reload')
	eq(UF:SharedReady(profile), false)
	eq(UF:SharedState(profile), 'restored')
	eq(rawget(profile, 'all'), nil, 'no marker')
	eq(profile.player.width, 411, 'a unit\'s own size is kept')
	shows_the_same(snap, profile, 'every shared setting is as before the conversion')
	for _, unit in ipairs(SW.MEMBERS) do
		for _, entry in ipairs(UF.SHARED) do check(not UF:IsOwn(unit, entry.key), unit .. ' ' .. entry.key .. ' is not owned') end
	end
	eq(shares_in(UF:GetConfigTable()), 0, 'no share is drawn after a restore')

	-- A logout and a login: the profile is NOT converted again by itself.
	db = SW.relog(db)
	profile = profile_of(db)
	local listed = listing(profile)
	lines = printed_by(function() SW.enable() end)
	eq(UF:SharedReady(profile), false, 'the login does not convert a restored profile')
	local after = listing(profile)
	check(after:gsub('[^\n]*restoredTold[^\n]*\n?', '') == listed:gsub('[^\n]*restoredTold[^\n]*\n?', ''), 'and writes nothing but that it said so')
	eq(#lines, 1, 'one message about it: ' .. table.concat(lines, ' | '))
	check(lines[1]:find('/sui uf share', 1, true), 'telling how to turn it on again')
	-- M3: the next login does not say it again; the All units page does.
	db = SW.relog(db)
	profile = profile_of(db)
	lines = printed_by(function() SW.enable() end)
	eq(#lines, 0, 'the second login after the restore says nothing: ' .. table.concat(lines, ' | '))
	check(UF:GetConfigTable().args.all.args.general.args.notice.name:find('/sui uf share', 1, true), 'the page keeps saying it')

	-- M4: /sui uf share says what it will do and needs confirm.
	local was = SW.snapshot(profile)
	lines = printed_by(function() UF:RunShareCommand('share') end)
	eq(UF:SharedReady(profile), false, 'not without confirm')
	check(lines[1]:find('replaces the old backup', 1, true) and lines[1]:find('NOW', 1, true) and lines[1]:find('share confirm', 1, true), tostring(lines[1]))
	local button = UF:GetConfigTable().args.all.args.general.args.turnOn
	check(button.confirm and button.confirm:find('replaces the old backup', 1, true), 'the page button asks with the same words')
	lines = printed_by(function() UF:RunShareCommand('share confirm') end)
	eq(UF:SharedReady(profile), true, 'asked for, it converts')
	shows_the_same(was, profile, 'and nothing on screen changed')
	check(UF.HasSharedBackup(profile), 'with a fresh backup')
	local said = table.concat(lines, ' | ')
	check(said:find('Shared settings are on', 1, true) and said:find('set up for this unit frame profile', 1, true), said)
	db = SW.relog(db)
	profile = profile_of(db)
	SW.enable()
	eq(UF:SharedReady(profile), true, 'and the next login keeps it')
end)

test('/sui uf restore refuses plainly with no backup, with an element missing, and waits for combat', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	SW.enable()
	-- A profile that was never converted by this version (or whose backup went): no backup.
	UF:EnableShared(profile)
	rawset(profile, 'backup', nil)
	local lines = printed_by(function() UF:RunShareCommand('restore confirm') end)
	check(lines[1] and lines[1]:find('no backup', 1, true) or lines[1]:find('nothing to restore', 1, true), tostring(lines[1]))
	eq(UF:SharedReady(profile), true, 'nothing was done')

	world()
	db = SW.acedb({})
	profile = profile_of(db)
	SW.enable()
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil
	lines = printed_by(function() UF:RunShareCommand('restore confirm') end)
	check(lines[1] and lines[1]:find('Castbar', 1, true), 'names the part that did not load: ' .. tostring(lines[1]))
	UF.elements.Castbar = castbar
	eq(rawget(profile, 'all') ~= nil and UF:SharedReady(profile), true, 'and nothing was restored')

	-- In combat: nothing now, a plain line, and it happens when combat ends.
	stub.in_combat = true
	lines = printed_by(function() UF:RunShareCommand('restore confirm') end)
	check(lines[1] and lines[1]:find('combat', 1, true), 'says it waits: ' .. tostring(lines[1]))
	eq(UF:SharedReady(profile), true, 'nothing was written in combat')
	stub.in_combat = false
	lines = printed_by(function() stub.fire_event('PLAYER_REGEN_ENABLED') end)
	eq(UF:SharedReady(profile), false, 'restored when combat ended')
	eq(UF:SharedState(profile), 'restored')
	eq(#take_errors(), 0)
end)

test('wired: a profile switch in combat builds the frames from the stored values and converts at the end of combat (M9)', function()
	local C = load_test_file('lib/color_cost.lua')
	world()
	local db = SW.acedb({})
	SW.customize(profile_of(db))
	db = SW.relog(db)
	local record = SW.enable()
	local other = profile_of(db, 'Other')
	other.player.name.font = 'pixel'
	other.target.name.font = 'pixel'
	local before = SW.snapshot(other)
	db.profile.unitframes.config_profile = 'Other'
	stub.in_combat = true
	local applied = #record.applied
	local m = C.measure(function() UF:UpdateConfig() end, 1, { [UF.sharedTicker] = true })
	eq(m.forbidden.total, 0, 'no forbidden call in combat')
	eq(m.made, 0, 'nothing made')
	eq(UF:SharedReady(other), false, 'no conversion in combat')
	eq(rawget(other, 'all'), nil, 'nothing written into the profile')
	shows_the_same(before, other, 'the frames read the stored values, which are what it shows')
	eq(#record.applied, applied, 'no frame was updated in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(UF:SharedReady(other), true, 'converted at the end of combat')
	shows_the_same(before, other, 'and shows what it showed')
	check(#record.applied > applied, 'the frames were updated when combat ended')
	eq(#take_errors(), 0)
end)
------------------------------------------------------------------ cost

test('cost: a login that converts a large customized profile, and one that only syncs', function()
	local C = load_test_file('lib/color_cost.lua')
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	SW.customize(profile)
	-- Every unit owns something in several parts: a large profile.
	for index, unit in ipairs(SW.MEMBERS) do
		profile[unit].name.maxLength = 10 + index
		profile[unit].health.alpha = 0.5 + index / 40
		profile[unit].buffs.size = 20 + index
		profile[unit].castbar.alpha = 0.4 + index / 30
	end
	db = SW.relog(db)
	profile = profile_of(db)
	local ignore = { [UF.sharedTicker] = true }
	local first = C.measure(function() UF:PrepareShared(profile) end, 1, ignore)
	C.print('the conversion login', first)
	eq(first.forbidden.total, 0, 'no frame touched')
	eq(first.made, 0, 'nothing made')
	check(first.kb < 1600, ('the conversion makes %.0f KB of garbage, once per profile'):format(first.kb))
	local again = C.measure(function() UF:PrepareShared(profile) end, 1, ignore)
	C.print('a login that only syncs', again)
	check(again.kb < 8, ('a sync that has nothing to put right makes %.1f KB'):format(again.kb))
end)

------------------------------------------------------------------ the fix round: edits survive, one error, one line

-- A part's menu row of the page of unit, as the options model reads it: the root and the row.
local function menu_row(unit, part, key)
	local OM = st.OptionsModel
	local item = UF:GetConfigTable().args[unit].args.general.args.parts.args[part]
	local root = OM.MenuRoot(item)
	return root, { option = item.menu.args[key], path = { OM.MENU_KEY, key }, type = item.menu.args[key].type, key = key }
end

local function converted_world()
	world()
	local db = SW.acedb({})
	SW.customize(profile_of(db))
	db = SW.relog(db)
	local record = SW.enable()
	return db, record
end

test('I2: a page edit made while a part of the unit frames did not load is the unit\'s own, and the sync that follows keeps it', function()
	local db = converted_world()
	local profile = profile_of(db)
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil
	eq(UF:SharedState(profile), 'missing')
	local root, row = menu_row('target', 'name', 'maxLength')
	eq(st.OptionsModel.Get(root, row) ~= 77, true)
	check(st.OptionsModel.Set(root, row, 77))
	eq(UF:IsOwn('target', 'name.maxLength'), true, 'the flag is written although syncs are refused')
	UF.elements.Castbar = castbar
	UF:UpdateConfig()
	eq(profile.target.name.maxLength, 77, 'nothing put it back when the part loaded')
	db = SW.relog(db)
	SW.enable()
	eq(profile_of(db).target.name.maxLength, 77, 'nor at the next login')
end)

test('M2: a sync that fails on a converted profile raises one error and says so once; sharing is then paused for the session', function()
	local db = converted_world()
	local profile = profile_of(db)
	local good = profile.pet
	rawset(profile, 'pet', setmetatable({}, { __index = function() error('boom', 0) end }))
	local lines = printed_by(function()
		for _ = 1, 4 do UF:UpdateConfig() end -- a profile change, combat's end, a theme change, a scale change
	end)
	eq(#take_errors(), 1, 'one error over four updates')
	local told = 0
	for _, line in ipairs(lines) do if line:find('SaftUI', 1, true) then told = told + 1 end end
	eq(told, 1, 'one chat line: ' .. table.concat(lines, ' | '))
	eq(UF:SharedState(profile), 'failed')
	eq(UF:SharedReady(profile), false, 'paused')
	rawset(profile, 'pet', good)
	-- Paused: a drift is not put right (nothing is written), and the page draws no share.
	rawset(profile.target.name, 'font', 'header')
	UF:UpdateConfig()
	eq(profile.target.name.font, 'header', 'nothing was written')
	eq(shares_in(UF:GetConfigTable()), 0, 'no share is drawn')
	-- An edit still carries its flag, so the next login's sync keeps it.
	local root, row = menu_row('target', 'name', 'maxLength')
	check(st.OptionsModel.Set(root, row, 61))
	eq(UF:IsOwn('target', 'name.maxLength'), true)
	eq(#take_errors(), 0)
end)

test('M6: a login that finally converts says so in one line', function()
	world()
	local db = SW.acedb({})
	SW.customize(profile_of(db))
	db = SW.relog(db)
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil
	local first = printed_by(function() SW.enable() end)
	eq(#first, 1, 'waiting: ' .. table.concat(first, ' | '))
	UF.elements.Castbar = castbar
	db = SW.relog(db)
	local second = printed_by(function() SW.enable() end)
	eq(#second, 1, 'one line: ' .. table.concat(second, ' | '))
	check(second[1]:find('set up for this unit frame profile', 1, true), second[1])
	db = SW.relog(db)
	eq(#printed_by(function() SW.enable() end), 0, 'and nothing after')
end)

test('M7 and W5: the real UpdateConfig propagates an All units set into the followers and never applies "all" as a unit', function()
	local db, record = converted_world()
	local OM = st.OptionsModel
	local root, row = menu_row('all', 'name', 'max_width')
	local profile = profile_of(db)
	local applied = #record.applied
	check(OM.Set(root, row, 111))
	for _, unit in ipairs(SW.MEMBERS) do
		if UF:HasShared(unit, 'name.max_width') and not UF:IsOwn(unit, 'name.max_width') then
			eq(profile[unit].name.max_width, 111, unit .. ' follows (the real UpdateConfig has the lines)')
		end
	end
	eq(#record.applied, applied, 'ApplyConfig was not asked for "all"')
	SW.step(UF)
	for _, call in ipairs({ unpack(record.applied, applied + 1) }) do
		check(call[1] ~= 'all', 'no update of the unit "all"')
	end
	check(#record.applied > applied, 'the followers were updated on the next frame')
end)

test('W24 and W21: a restore updates the frames, and turning sharing on again replaces the old backup', function()
	local db, record = converted_world()
	local profile = profile_of(db)
	local applied = #record.applied
	UF:RunShareCommand('restore confirm')
	check(#record.applied > applied, 'the frames were updated by the restore')
	profile.target.name.maxLength = 44 -- an edit made while restored
	UF:RunShareCommand('share confirm')
	eq(UF:SharedReady(profile), true)
	UF:SetShared('all', 'name.maxLength', 50)
	UF:SetShared('target', 'name.maxLength', 45)
	eq(UF:RestoreShared(profile), true)
	eq(profile.target.name.maxLength, 44, 'the new backup is of the moment sharing was turned on again')
end)
