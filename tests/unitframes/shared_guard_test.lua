-- What protects a layout when something goes wrong with shared settings (config/shared.lua), each case
-- failing before its guard was built: a plain imported profile is left unconverted until a login gives it
-- AceDB's defaults; a conversion refuses while an element is not registered; every writer does nothing on
-- an unconverted profile or a newer marker; a restore gives back working values after a real logout; an
-- error at each write step leaves no marker and converges on retry; the files that may call the API are
-- scanned; the branch leaves a profile's saved data byte for byte as the base's; the two cast bar wildcard
-- defaults hold a follower's value across a login; every member's default is pinned; and the cost of a held
-- slider and of the sync.
--
-- Real AceDB-3.0 throughout, its logout stripping defaults and its saved data written out and read back
-- with the functions dropped (SW.relog), as the game does.
local SW = load_test_file('unitframes/shared_world.lua')
local C = load_test_file('lib/color_cost.lua')
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')

local st, UF
local EXPECTED_DIGEST = 37751237

local function world(opts)
	st, UF = SW.world(opts)
end

local function profile_of(db, name) return db.profile.unitframes.profiles[name or 'SaftUI'] end

-- A fresh AceDB database, its unit frame profile changed by fn, logged out and in once so what AceDB fills
-- in (a saved color's alpha, a nil key) has settled, as in a profile the player has used.
local function customized(fn)
	world()
	local db = SW.acedb({})
	if fn then fn(profile_of(db)) end
	return SW.relog(db)
end

-- Every value in a profile as 'path = value', sorted: the empty tables AceDB's wildcards make and the
-- functions are left out. Two listings equal mean nothing in the profile changed.
local function leaves(value, prefix, out)
	out = out or {}
	if type(value) ~= 'table' then
		out[#out + 1] = prefix .. ' = ' .. tostring(value)
	else
		for k, v in pairs(value) do
			if type(v) ~= 'function' then leaves(v, (prefix and (prefix .. '.') or '') .. tostring(k), out) end
		end
	end
	if prefix == nil then table.sort(out) end
	return out
end

local function listing(profile) return table.concat(leaves(profile), '\n') end

local function owned(profile)
	local out = {}
	for _, unit in ipairs(SW.MEMBERS) do
		local keys = {}
		local own = rawget(profile[unit], 'own')
		for _, entry in ipairs(UF.SHARED) do
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

local function shows_the_same(before, profile, label)
	local ok, diffs = SW.same(before, SW.snapshot(profile))
	check(ok, label .. ': ' .. #diffs .. ' differ: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 30)))
end

------------------------------------------------------------------ Important 1: a plain imported profile

-- An export of the profile in use, as the game's import makes it: plain data, every value, no AceDB tables.
local function import(db, make_export, drop)
	local data = SW.saved_copy(profile_of(db))
	data.all = nil
	data.backup = nil
	for _, unit in ipairs(drop or {}) do data[unit] = nil end
	db.profile.unitframes.profiles.Imported = data
	db.profile.unitframes.config_profile = 'Imported'
	return data
end

local function import_case(label, make_export, drop)
	-- The base: the same import with no conversion at all, then a login.
	local db = customized(make_export)
	import(db, make_export, drop)
	db = SW.relog(db)
	local base = SW.snapshot(profile_of(db, 'Imported'))
	-- The branch: what the game does on an import, then a login that gives it AceDB's tables.
	db = customized(make_export)
	local data = import(db, make_export, drop)
	local before = listing(data)
	local ok, why = UF:PrepareShared(data)
	eq(ok, false, label .. ': a plain table is not converted')
	eq(why, 'plain')
	eq(#take_errors(), 0, label .. ': quietly')
	check(listing(data) == before, label .. ': nothing was written into it')
	eq(rawget(data, 'all'), nil, label .. ': no All units made')
	eq(rawget(data, 'backup'), nil, label .. ': no backup')
	local synced, reason = UF:SyncShared(data)
	eq(synced, false, label .. ': nor synced')
	check(reason, label .. ': with a reason')
	local converted = pcall(UF.ConvertShared, UF, data)
	eq(converted, false, label .. ': ConvertShared refuses it')
	check(listing(data) == before, label .. ': and writes nothing')
	-- The login that fills it.
	db = SW.relog(db)
	local profile = profile_of(db, 'Imported')
	eq(UF:PrepareShared(profile), true, label .. ': converted at the login')
	eq(UF:SharedReady(profile), true)
	shows_the_same(base, profile, label .. ': after the login')
	eq(UF:SyncShared(profile), 0, label .. ': and the sync has nothing to do')
end

test('C18a an imported profile with names hidden on ten units shows them hidden after the login', function()
	import_case('import, hidden names', function(p)
		for _, unit in ipairs(SW.MEMBERS) do p[unit].name.enable = false end
		p.player.name.enable = true
	end)
end)

test('C18b an imported profile with no Boss table keeps Boss\'s own defaults', function()
	import_case('import, boss missing', function() end, { 'boss' })
end)

test('C18c an untouched imported profile with every unit present', function()
	import_case('import, untouched', function() end)
end)

test('a profile table with a metatable but no All units is converted, and nothing is made before it is', function()
	-- A table with some metatable is one AceDB (or a test) made; a failed conversion leaves no All units.
	local db = customized()
	local profile = profile_of(db)
	eq(rawget(profile, 'all'), nil, 'AceDB makes no All units table before a conversion')
	local pet = profile.pet
	profile.pet = setmetatable({}, { __index = function() error('boom', 0) end })
	eq(UF:PrepareShared(profile), false)
	take_errors()
	profile.pet = pet
	eq(rawget(profile, 'all'), nil, 'the plan made no All units table')
end)

------------------------------------------------------------------ Important 2: an element is not registered

test('G the conversion refuses while an element is not registered, and nothing is lost when it is', function()
	local db = customized(function(p)
		p.target.castbar.height = 40
		p.player.castbar.colors.normal = { r = 1, g = 0, b = 0 }
		p.focus.castbar.enable = false
		p.boss.castbar.width = 12
	end)
	local profile = profile_of(db)
	local before = SW.snapshot(profile)
	local listed = listing(profile)
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil -- castbar.lua failed to load, or a call before the elements register
	local ok, err = pcall(UF.ConvertShared, UF, profile)
	eq(ok, false)
	check(tostring(err):find('Castbar', 1, true), 'it names the element: ' .. tostring(err))
	eq(UF:PrepareShared(profile), false, 'not converted')
	eq(UF:SharedState(profile), 'missing')
	eq(#take_errors(), 0, 'a part that did not load is said once in chat, not raised on every update')
	check(listing(profile) == listed, 'values, flags, marker and backup untouched')
	eq(rawget(profile, 'all'), nil)
	eq(rawget(profile, 'backup'), nil)
	local synced = UF:SyncShared(profile)
	eq(synced, false)
	UF.elements.Castbar = castbar
	eq(UF:PrepareShared(profile), true, 'converted once the element is back')
	shows_the_same(before, profile, 'after the element registered')
	eq(rawget(profile.target, 'own')['castbar.height'], true, 'the cast bar customizations are owned')
	eq(rawget(profile.player, 'own')['castbar.colors.normal'], true)
	eq(UF:SyncShared(profile), 0, 'and the sync loses none')
	shows_the_same(before, profile, 'after the sync')
end)

test('a converted profile is not written while an element is missing', function()
	local db = customized()
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil
	local listed = listing(profile)
	for _, call in ipairs({
		function() return UF:SyncShared(profile) end,
		function() return UF:SetShared('all', 'name.font', 'header') end,
		function() return UF:PropagateShared('Name') end,
		function() return UF:FollowAll('target', 'name.font') end,
	}) do
		local ok, why = call()
		eq(ok, false)
		check(type(why) == 'string' and why:find('Castbar', 1, true), 'it says why: ' .. tostring(why))
	end
	UF.elements.Castbar = castbar
	check(listing(profile) == listed, 'nothing was written')
end)

------------------------------------------------------------------ Important 3: every writer checks the marker

local function writers(profile)
	return {
		SyncShared = function() return UF:SyncShared(profile) end,
		['SetShared all'] = function() return UF:SetShared('all', 'name.font', 'header') end,
		['SetShared member'] = function() return UF:SetShared('target', 'name.font', 'header') end,
		['SetShared position part'] = function() return UF:SetShared('all', 'name.position', 9, 'x_off') end,
		OwnShared = function() return UF:OwnShared('target', 'name.font') end,
		FollowAll = function() return UF:FollowAll('target', 'name.font') end,
		ApplyToAll = function() return UF:ApplyToAll('party', 'name.showLevel') end,
		['ApplyTo from a member'] = function() return UF:ApplyTo('target', 'name.font', { 'focus', 'boss' }) end,
		['ApplyTo from all'] = function() return UF:ApplyTo('all', 'name.font', { 'focus', 'boss' }) end,
		PropagateShared = function() return UF:PropagateShared('Name') end,
		['PropagateShared frame'] = function() return UF:PropagateShared(nil) end,
	}
end

local function nothing_is_written(label, db, newer)
	local profile = profile_of(db)
	local listed = listing(profile)
	local pending = UF.sharedTicker:IsShown()
	for name, call in pairs(writers(profile)) do
		-- OwnShared writes the one flag that protects a unit's edit, on any converted profile (I2); the
		-- others do nothing.
		if not (newer and name == 'OwnShared') then
			local ok, why = call()
			eq(ok, false, label .. ': ' .. name .. ' does nothing')
			check(type(why) == 'string' and #why > 0, label .. ': ' .. name .. ' says why')
		end
	end
	check(listing(profile) == listed, label .. ': nothing was written by any of them')
	eq(UF.sharedTicker:IsShown(), pending, label .. ': no update was marked')
	if newer then
		-- The conversion itself writes nothing on a newer marker.
		UF:ConvertShared(profile)
		check(listing(profile) == listed, label .. ': ConvertShared writes nothing either')
	end
end

test('on an unconverted profile every writer does nothing', function()
	local db = customized(function(p)
		p.target.name.font = 'pixel'
		p.player.name.font = 'pixel'
		p.party.name.showLevel = true
	end)
	nothing_is_written('unconverted', db)
	eq(UF:SharedReady(profile_of(db)), false)
end)

test('on a newer marker every writer does nothing', function()
	local db = customized(function(p)
		p.target.name.font = 'pixel'
		p.party.name.showLevel = true
	end)
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	rawset(profile.all, 'version', UF.SHARED_VERSION + 1) -- a newer SaftUI converted it
	local listed = listing(profile)
	nothing_is_written('newer marker', db, true)
	eq(rawget(profile.all, 'version'), UF.SHARED_VERSION + 1, 'the marker is left')
	eq(UF:PrepareShared(profile), false)
	eq(UF:SharedState(profile), 'newer')
	check(listing(profile) == listed, 'PrepareShared writes nothing either')
	-- A non-number marker counts as unconverted.
	rawset(profile.all, 'version', 'x')
	eq(UF:SharedReady(profile), false)
end)

test('on a converted profile every writer works', function()
	local db = customized()
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	for name, call in pairs(writers(profile)) do
		local ok, why = call()
		check(ok ~= false, name .. ' ran: ' .. tostring(why))
	end
end)

------------------------------------------------------------------ Important 4: a restore after a real logout

test('a restore after a logout and a login gives back working values with no reload', function()
	local db = customized(SW.customize)
	local profile = profile_of(db)
	local before = SW.snapshot(profile)
	local colorBefore = profile.target.castbar.colors.normal
	local hasMethods = type(colorBefore.GetRGB) == 'function'
	UF:PrepareShared(profile)
	UF:SetShared('all', 'castbar.colors.normal', { r = 0.1, g = 0.2, b = 0.3 })
	UF:SetShared('all', 'name.position', { point = 'TOP', rel_point = 'TOP', x_off = 4, y_off = 4 })
	UF:SetShared('target', 'name.font', 'header')
	db = SW.relog(db) -- the saved data written out and read back: functions dropped
	profile = profile_of(db)
	local live = profile.target.castbar.colors.normal
	local liveMetatable = getmetatable(profile.target.buffs)
	check(liveMetatable ~= nil, 'a unit sub-table has AceDB\'s metatable after a login')
	local methodsBefore = type(live.GetRGB)
	local ok, why = UF:RestoreShared(profile)
	eq(ok, true, tostring(why))
	eq(rawequal(profile.target.castbar.colors.normal, live), true, 'the color table is the live one')
	eq(type(profile.target.castbar.colors.normal.GetRGB), methodsBefore, 'its methods are as the login left them')
	if hasMethods then
		eq(methodsBefore, 'function', 'a login gives a color its methods back')
		local r, g, b = profile.target.castbar.colors.normal:GetRGB()
		eq(r .. g .. b, '010', 'GetRGB gives the restored color')
		local _, _, bluer = UF.UnpackColor(profile.target.castbar.colors.normal)
		eq(bluer, 0)
	end
	eq(rawequal(getmetatable(profile.target.buffs), liveMetatable), true, 'sub-tables keep AceDB\'s metatables')
	check(type(profile.target.buffs.friend) == 'table', 'a wildcard table is still made by a read')
	shows_the_same(before, profile, 'every shared setting is as before the conversion')
	eq(UF:SharedReady(profile), false)
	-- Converting again after the restore (asked for: a login does not) gives the same flags as the first time.
	local first = {}
	eq(UF:PrepareShared(profile), false, 'a login does not convert a restored profile')
	eq(UF:EnableShared(profile), true)
	for _, unit in ipairs(SW.MEMBERS) do first[unit] = owned(profile)[unit] end
	eq(rawget(profile.target, 'own')['name.font'], true)
end)

test('a restore through a second logout and login is the same', function()
	local db = customized(SW.customize)
	local profile = profile_of(db)
	local before = SW.snapshot(profile)
	UF:PrepareShared(profile)
	db = SW.relog(SW.relog(db))
	profile = profile_of(db)
	check(UF.HasSharedBackup(profile), 'the backup survives two logins')
	eq(UF:RestoreShared(profile), true)
	shows_the_same(before, profile, 'after the restore')
	db = SW.relog(db)
	shows_the_same(before, profile_of(db), 'and after another login')
end)

------------------------------------------------------------------ Important 5: the write order and an error at each step

local STEPS = {
	['the backup copy'] = function(restore)
		local real = time
		time = function() error('boom', 0) end
		restore[#restore + 1] = function() time = real end
	end,
	['the backup\'s rawset'] = function(restore)
		local real = rawset
		rawset = function(t, k, v) if k == 'backup' then error('boom', 0) end return real(t, k, v) end
		restore[#restore + 1] = function() rawset = real end
	end,
	['All units\' first value'] = function(restore)
		local real = UF.CopyShared
		UF.CopyShared = function() error('boom', 0) end
		restore[#restore + 1] = function() UF.CopyShared = real end
	end,
	['an own flag midway'] = function(restore)
		local real, count = rawset, 0
		rawset = function(t, k, v)
			if k == 'own' then
				count = count + 1
				if count == 5 then error('boom', 0) end
			end
			return real(t, k, v)
		end
		restore[#restore + 1] = function() rawset = real end
	end,
	['the marker\'s rawset'] = function(restore)
		local real = rawset
		rawset = function(t, k, v) if k == 'version' then error('boom', 0) end return real(t, k, v) end
		restore[#restore + 1] = function() rawset = real end
	end,
}

for name, inject in pairs(STEPS) do
	test('an error at ' .. name .. ' leaves no marker, no member changed, and the retry converges', function()
		local function make()
			return customized(function(p)
				SW.customize(p)
				p.raid10.name.maxLength = 9
				p.boss.health.text.enable = true
			end)
		end
		-- What a clean conversion gives, on the same profile.
		local clean = make()
		local cleanProfile = profile_of(clean)
		UF:PrepareShared(cleanProfile)
		local cleanFlags = owned(cleanProfile)

		local db = make()
		local profile = profile_of(db)
		local before = SW.snapshot(profile)
		local restore = {}
		inject(restore)
		local ok, ran = pcall(UF.PrepareShared, UF, profile)
		for _, fn in ipairs(restore) do fn() end
		eq(ok, true, 'PrepareShared raised nothing')
		eq(ran, false, 'it reported the error')
		eq(#take_errors(), 1)
		eq(rawget(profile.all or {}, 'version'), nil, 'no marker')
		eq(UF:SharedReady(profile), false)
		shows_the_same(before, profile, 'no member changed')
		-- A login with the half-written state: still no marker, nothing for the sync to put right.
		db = SW.relog(db)
		profile = profile_of(db)
		eq(UF:SharedReady(profile), false)
		shows_the_same(before, profile, 'after a login')
		-- The retry.
		eq(UF:PrepareShared(profile), true, 'the retry is clean')
		eq(UF:SharedReady(profile), true)
		same_owned(cleanFlags, owned(profile), 'the flags of a clean conversion')
		eq(UF:SyncShared(profile), 0, 'the sync has nothing to put right')
		shows_the_same(before, profile, 'after the retry')
	end)
end

test('the marker is written last: a conversion stopped at the flags has none', function()
	local db = customized(SW.customize)
	local profile = profile_of(db)
	local real, seen = rawset, {}
	rawset = function(t, k, v)
		seen[#seen + 1] = k
		return real(t, k, v)
	end
	UF:ConvertShared(profile)
	rawset = real
	local last
	for i, k in ipairs(seen) do if k == 'version' then last = i end end
	check(last, 'the marker was written')
	for i, k in ipairs(seen) do
		if k == 'own' or k == 'backup' then check(i < last, k .. ' is written before the marker') end
	end
	eq(seen[#seen], 'version', 'and nothing after it')
end)

------------------------------------------------------------------ Important 5: who may call the API

-- The sharing API and who may call it (N3). Every mention of one of these words, in any file of any
-- addon but config/shared.lua and sharedsetup.lua, must sit in a top-level function listed here for that file: the calls
-- that wire sharing (login, profile changes, the pages) and nothing else. An alias, a call through self
-- or a string key is a mention too. Any other mention fails, naming the file, the function and the word.
local API = { 'ConvertShared', 'SyncShared', 'PrepareShared', 'RestoreShared', 'UpdateShared', 'PropagateShared',
	'CopyShared', 'SameShared', 'HasShared', 'SharedValue', 'SharedReady', 'OwnShared', 'SetShared', 'DefaultShared',
	'CopyProfileData', 'HasSharedBackup', 'sharedTicker',
	'SharedState', 'SharedStateText', 'EnableShared', 'SharedRestored', 'SharedWhole', 'CanMarkOwn' }
-- Names another addon has too (the action bars' own sharing): a mention is a call on UF, Unitframes, or self
-- in a Unitframes file.
local SHORT = { 'ApplyTo', 'ApplyToAll', 'FollowAll', 'OwnersOf', 'IsOwn' }
-- Data the pages read (never written): any function of these files.
local DATA = { 'SHARE_MEMBERS', 'SHARED_BY_KEY', 'SHARED_BY_PATH', 'SHARED_VERSION' }
local DATA_FILES = { ['SaftUI-Unitframes/config/sharedoptions.lua'] = true, ['SaftUI-Unitframes/config/config.lua'] = true }

-- file -> top-level function -> the words it may mention. '<file>' is the file's own level.
local ALLOWED = {
	['SaftUI-Unitframes/unitframes.lua'] = {
		['UF:OnEnable'] = { 'PrepareShared' },
		['UF:UpdateConfig'] = { 'PrepareShared', 'PropagateShared' },
	},
	['SaftUI-Unitframes/config/profiles.lua'] = {
		PromptNewProfile = { 'CopyProfileData' },
		PromptExportProfile = { 'CopyProfileData' },
		ConfirmDeleteProfile = { 'SharedReady', 'SharedState' },
	},
	['SaftUI-Unitframes/config/config.lua'] = {
		['UF:CopySettings'] = { 'CanMarkOwn', 'HasShared', 'SameShared', 'OwnShared' },
		['UF:GetConfigTable'] = { 'SharedReady' },
	},
	['SaftUI-Unitframes/config/sharedoptions.lua'] = {
		Applied = { 'UpdateShared' },
		Targets = { 'HasShared' },
		['UF.SharedWhole'] = { 'SharedWhole' },
		AllValue = { 'SharedReady', 'SharedWhole' },
		['UF.SettingShare'] = { 'SharedWhole', 'ApplyToAll', 'ApplyTo', 'OwnersOf', 'IsOwn', 'FollowAll' },
		['UF.SharesElement'] = { 'HasShared' },
		OwnThenSet = { 'OwnShared', 'IsOwn', 'SameShared' },
		PausedReset = { 'IsOwn', 'CopyShared' },
		CheckFollowers = { 'HasShared', 'IsOwn' },
		Decorate = { 'HasShared' },
		['UF.DecorateShares'] = { 'SharedReady', 'CanMarkOwn' },
		['UF.SharedNoticePage'] = { 'SharedState', 'SharedStateText', 'RequestShare' },
		['UF:RestoreSharedNow'] = { 'RestoreShared' },
		['UF:RestoreSharedCommand'] = { 'HasSharedBackup', 'SharedState', 'SharedStateText' },
		['UF:ShareNow'] = { 'EnableShared' },
		['UF:RequestShare'] = { 'ShareNow' },
		['UF:ShareCommand'] = { 'RequestShare', 'SharedState' },
		WhenText = {},
	},
}

local function masked(path)
	local source = read_saftui_source(path)
	if not source then return nil end
	local _, mask = L.Lex(source)
	return mask, source
end

-- The top-level function a position of the masked source is in: '<file>' outside every function.
local function enclosing(mask, position)
	local events = {}
	for offset, name in mask:gmatch('\n()function%s+([%w_.:]+)%s*%(') do events[#events + 1] = { offset, name } end
	for offset, name in mask:gmatch('\n()local%s+function%s+([%w_]+)%s*%(') do events[#events + 1] = { offset, name } end
	for offset in mask:gmatch('\n()end%f[^%w_]') do events[#events + 1] = { offset, '<file>' } end
	table.sort(events, function(a, b) return a[1] < b[1] end)
	local current = '<file>'
	for _, event in ipairs(events) do
		if event[1] > position then break end
		current = event[2]
	end
	return current
end

-- The two files of the shared settings' storage and rules: shared.lua and sharedsetup.lua (its second half).
local SHARED_FILES = { ['SaftUI-Unitframes/config/shared.lua'] = true, ['SaftUI-Unitframes/config/sharedsetup.lua'] = true }

-- Their masked sources as one.
local function masked_shared()
	local a = masked('SaftUI-Unitframes/config/shared.lua')
	local b = masked('SaftUI-Unitframes/config/sharedsetup.lua')
	return a .. '\n' .. b
end

local function listed(list, word)
	for _, entry in ipairs(list or {}) do
		if entry == word then return true end
	end
	return false
end

test('wiring: only the listed functions of the listed files mention the sharing API', function()
	local scanned, mentions = 0, 0
	for _, path in ipairs((T.saftui_files())) do
		if not SHARED_FILES[path] then
			local mask, source = masked(path)
			if mask then
				scanned = scanned + 1
				local allowed = ALLOWED[path] or {}
				for _, word in ipairs(API) do
					for position in mask:gmatch('()%f[%w_]' .. word .. '%f[^%w_]') do
						local where = enclosing(mask, position)
						mentions = mentions + 1
						check(listed(allowed[where], word), path .. ': ' .. where .. ' mentions ' .. word)
					end
					-- A string key (UF['SyncShared']) or a quoted name is a mention too.
					check(not source:find('[\'"]' .. word .. '[\'"]'), path .. ' names ' .. word .. ' in a string')
				end
				for _, word in ipairs(SHORT) do
					local own = path:find('^SaftUI%-Unitframes/') ~= nil
					for _, receiver in ipairs(own and { 'UF', 'Unitframes', 'self' } or { 'UF', 'Unitframes' }) do
						for position in mask:gmatch('()%f[%w_]' .. receiver .. '%s*[:.]%s*' .. word .. '%f[^%w_]') do
							local where = enclosing(mask, position)
							mentions = mentions + 1
							check(listed(allowed[where], word), path .. ': ' .. where .. ' calls ' .. receiver .. '.' .. word)
						end
					end
					check(not source:find('[\'"]' .. word .. '[\'"]') or not own, path .. ' names ' .. word .. ' in a string')
				end
				for _, word in ipairs(DATA) do
					if not DATA_FILES[path] and path ~= 'SaftUI-Unitframes/unitframes.lua' then
						check(not mask:find('%f[%w_]' .. word .. '%f[^%w_]'), path .. ' mentions ' .. word)
					end
				end
			end
		end
	end
	check(scanned > 150, 'it scanned ' .. scanned .. ' files, every addon\'s')
	check(mentions > 20, 'it found the wiring: ' .. mentions .. ' mentions')
	-- And every listed word is really there: a stale entry hides a new mention.
	for path, functions in pairs(ALLOWED) do
		local mask = masked(path)
		for name, words in pairs(functions) do
			for _, word in ipairs(words) do
				local found = false
				for position in mask:gmatch('()%f[%w_]' .. word .. '%f[^%w_]') do
					if enclosing(mask, position) == name then found = true end
				end
				check(found, path .. ': ' .. name .. ' is listed for ' .. word .. ' and does not mention it')
			end
		end
	end
end)

test('wiring: the scan itself finds a disguised call', function()
	local function mentions(source, word, where)
		local _, mask = L.Lex(source)
		for position in mask:gmatch('()%f[%w_]' .. word .. '%f[^%w_]') do
			if enclosing(mask, position) == where then return true end
		end
		return false
	end
	local source = '\nlocal function A()\n\tlocal sync = UF.SyncShared\nend\nfunction UF:B()\n\tself:FollowAll(1)\nend\nfunction UF.C()\n\tUF[\'SyncShared\'](UF)\nend\n'
	eq(mentions(source, 'SyncShared', 'A'), true, 'an alias')
	eq(mentions(source, 'FollowAll', 'UF:B'), true, 'a call through self')
	eq(source:find('[\'"]SyncShared[\'"]') ~= nil, true, 'a string key')
	eq(mentions(source, 'SyncShared', 'UF:B'), false, 'and the function it is in')
end)

-- Every mention of an API word inside shared.lua and sharedsetup.lua outside its own definition, counted: a new one, an alias
-- (`local sync = UF.SyncShared`, called from the ticker) included, changes a count and fails here.
local SHARED_MENTIONS = { ApplyTo = 0, ApplyToAll = 0, CanMarkOwn = 1, ConvertShared = 1, CopyProfileData = 0, CopyShared = 6,
	DefaultShared = 2, EnableShared = 0, FollowAll = 0, HasShared = 11, HasSharedBackup = 2, IsOwn = 1, OwnShared = 0,
	OwnersOf = 0, PrepareShared = 1, PropagateShared = 0, RestoreShared = 0, SameShared = 9, SetShared = 0, SharedReady = 0,
	SharedRestored = 2, SharedState = 4, SharedStateText = 3, SharedValue = 0, SharedWhole = 0, SyncShared = 2,
	UpdateShared = 1, sharedTicker = 4 }
local function shared_mentions()
	local mask = masked_shared()
	local counts = {}
	for _, word in ipairs(API) do
		local n = 0
		for position in mask:gmatch('()%f[%w_]' .. word .. '%f[^%w_]') do
			if not mask:sub(math.max(1, position - 12), position - 1):find('function%s+[%w_]*[:.]?$') then n = n + 1 end
		end
		counts[word] = n
	end
	for _, word in ipairs(SHORT) do
		local n = 0
		for position in mask:gmatch('()%f[%w_]' .. word .. '%f[^%w_]') do
			if not mask:sub(math.max(1, position - 12), position - 1):find('function%s+[%w_]*[:.]?$') then n = n + 1 end
		end
		counts[word] = n
	end
	return counts
end

test('shared.lua\'s own mentions of the API are pinned by count (an alias or a new call site changes one)', function()
	local counts = shared_mentions()
	for word, n in pairs(counts) do
		eq(n, SHARED_MENTIONS[word], 'shared.lua mentions ' .. word .. ' ' .. n .. ' times')
	end
end)

-- What a static scan can close: the API reached by a name built at run time. It cannot see `getfenv`, `loadstring`,
-- `_G[...]`, a method name read from a data table, or a module handed around by another addon.
test('no string-built access to the API: no UF[...] index, and no other addon reaches the Unitframes module by a name', function()
	for _, path in ipairs((T.saftui_files())) do
		local mask, source = masked(path)
		if mask and not SHARED_FILES[path] then
			if path:find('^SaftUI%-Unitframes/') then
				check(not mask:find('%f[%w_]UF%s*%['), path .. ' indexes UF by a computed name')
				check(not mask:find("%f[%w_]Unitframes'?%)?%s*%["), path .. ' indexes the module by a computed name')
				check(not mask:find('%f[%w_]self%s*%[%s*[^%]]-%.%.'), path .. ' builds a self[...] name')
			else
				check(not source:find('GetModule%(%s*[\'"]Unitframes'), path .. ' reaches the Unitframes module')
				check(not source:find('modules%.Unitframes') and not source:find('modules%s*%['), path .. ' reaches st.modules by name')
				check(not mask:find('GetModule%([^)]-%.%.'), path .. ' builds a module name')
			end
		end
	end
end)

test('config/shared.lua and sharedsetup.lua wire nothing themselves: no hook, event or login call, and its own calls are the ones it needs', function()
	local mask = masked_shared()
	for _, word in ipairs({ 'OnEnable', 'OnInitialize', 'hooksecurefunc', 'SecureHook', 'RegisterEvent', 'RegisterMessage',
		'RegisterCallback', 'C_Timer', 'HookScript' }) do
		check(not mask:find('%f[%w_]' .. word .. '%f[^%w_]'), 'shared.lua uses ' .. word)
	end
	-- Calls of the entry points outside their definitions: the file's own, counted. A new one is wiring.
	local allowed = { ConvertShared = 1, SyncShared = 2, UpdateShared = 1, PrepareShared = 1, RestoreShared = 0, PropagateShared = 0,
		SetShared = 0, OwnShared = 0, FollowAll = 0, ApplyToAll = 0, ApplyTo = 0, EnableShared = 0 }
	for word, count in pairs(allowed) do
		local n = 0
		for _, owner in ipairs({ 'self', 'UF' }) do
			for position in mask:gmatch('()%f[%w_]' .. owner .. '%s*[:.]%s*' .. word .. '%s*%(') do
				if mask:sub(position - 9, position - 1) ~= 'function ' then n = n + 1 end
			end
		end
		eq(n, count, 'shared.lua calls ' .. word .. ' ' .. n .. ' times')
	end
end)

------------------------------------------------------------------ Minor 1: byte for byte inert

-- The whole saved data, keys sorted, empty tables counted, no function: two strings equal mean the same file.
local function serialize(value, out)
	out = out or {}
	if type(value) == 'table' then
		local keys = {}
		for k in pairs(value) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		out[#out + 1] = '{'
		for _, k in ipairs(keys) do
			if type(value[k]) ~= 'function' then
				out[#out + 1] = tostring(k) .. '='
				serialize(value[k], out)
				out[#out + 1] = ','
			end
		end
		out[#out + 1] = '}'
	else
		out[#out + 1] = type(value) .. ':' .. tostring(value)
	end
	return out
end

-- The operations the base also runs: logins, readers' reads, profile switches, copies, a reset, a delete.
local function operations()
	local db = SW.acedb({})
	local function touch(profile)
		for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party',
			'raid10', 'raid40', 'arena', 'nameplate', 'friendlynameplate' }) do
			local config = profile[unit]
			for _, element in ipairs({ 'name', 'health', 'power', 'castbar', 'buffs', 'debuffs', 'raidtargetindicator',
				'raidroleindicator', 'grouproleindicator', 'readycheckindicator', 'questindicator' }) do
				local e = config[element]
				if element == 'buffs' or element == 'debuffs' then local _ = e.friend, e.enemy end
			end
		end
	end
	touch(profile_of(db))
	profile_of(db).target.name.font = 'pixel'
	profile_of(db).party.name.showLevel = true
	db = SW.relog(db)
	touch(profile_of(db))
	stub.fire_event('PLAYER_LOGIN')
	db.profile.unitframes.profiles.Healer.player.name.font = 'pixel'
	db.profile.unitframes.config_profile = 'Healer'
	touch(profile_of(db, 'Healer'))
	db = SW.relog(db)
	db.profile.unitframes.profiles.Copy = SW.saved_copy(profile_of(db))
	db.profile.unitframes.profiles.Healer = nil
	db.profile.unitframes.config_profile = 'SaftUI'
	touch(profile_of(db))
	local data = SW.logout(db)
	return table.concat(serialize(data))
end

test('the branch leaves a profile\'s saved data byte for byte as the base\'s', function()
	world({ bare = true })
	eq(UF.SHARED, nil, 'the base has none of the branch\'s files')
	eq(st.ALL_UNITS_DEFAULTS, nil)
	eq(rawget(st.defaults.unitframes.profiles['**'], 'all'), nil)
	local base = operations()
	world()
	check(UF.SHARED ~= nil)
	eq(rawget(st.defaults.unitframes.profiles['**'], 'all'), nil, 'All units is not in AceDB\'s defaults')
	local branch = operations()
	check(#base > 2000, 'the saved data is real: ' .. #base .. ' characters')
	eq(#branch, #base, 'the same length')
	eq(branch == base, true, 'the same bytes (empty tables included)')
end)

------------------------------------------------------------------ Minor 4: L6 and L9

-- A unit's own defaults at the entry's paths, as a unit-shaped table.
local function member_default(entry, unit)
	local config = {}
	for _, path in ipairs(entry.paths) do
		local found, value = st:DefaultAt('unitframes', 'profiles', 'SaftUI', unit, unpack(path))
		if found then
			local node = config
			for i = 1, #path - 1 do
				node[path[i]] = node[path[i]] or {}
				node = node[path[i]]
			end
			node[path[#path]] = type(value) == 'table' and SW.saved_copy(value) or value
		end
	end
	return config
end

test('L6 a follower that holds All units\' value keeps it across a login, with no sync', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	local set = {}
	for _, entry in ipairs(UF.SHARED) do
		local all = UF.DefaultShared(entry)
		for _, unit in ipairs(SW.MEMBERS) do
			if UF:HasShared(unit, entry.key) and not UF.SameShared(entry, member_default(entry, unit), all) then
				-- This member's own default differs from All units': it follows by holding All units' value.
				UF.CopyShared(entry, all, profile[unit])
				set[#set + 1] = { unit = unit, entry = entry, all = all }
			end
		end
	end
	check(#set > 50, 'a setting differs from All units\' default for many members: ' .. #set)
	db = SW.relog(db) -- no sync
	profile = profile_of(db)
	local lost = {}
	for _, item in ipairs(set) do
		if not UF.SameShared(item.entry, profile[item.unit], item.all) then lost[#lost + 1] = item.unit .. '.' .. item.entry.key end
	end
	eq(#lost, 0, 'AceDB stripped a follower\'s value: ' .. table.concat(lost, ', ', 1, math.min(#lost, 20)))
	eq(UF:SyncShared(profile), 0, 'and the sync has nothing to write at a login')
end)

-- A digest of the default of every shared setting on every member that has it (name, unit, value).
local function defaults_digest()
	local parts, count = {}, 0
	local function text(value)
		if type(value) ~= 'table' then return tostring(value) end
		local keys = {}
		for k in pairs(value) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		local out = {}
		for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. ':' .. text(value[k]) end
		return '{' .. table.concat(out, ',') .. '}'
	end
	for _, entry in ipairs(UF.SHARED) do
		for _, unit in ipairs(SW.MEMBERS) do
			if UF:HasShared(unit, entry.key) then
				count = count + 1
				parts[#parts + 1] = entry.key .. '@' .. unit .. '=' .. text(member_default(entry, unit))
			end
		end
	end
	local joined = table.concat(parts, '\n')
	local sum, size = 0, #joined
	for i = 1, size do sum = (sum * 31 + joined:byte(i)) % 2147483629 end
	return count, size, sum
end

test('L9 every member\'s default for every shared setting is pinned: changing one needs a conversion step', function()
	world()
	local count, size, sum = defaults_digest()
	local why = 'A shared setting\'s default changed for some member. A follower keeps the value it holds, so only fresh profiles '
		.. 'would see the new default: give the setting a conversion step (since = n and UF.SHARED_VERSION = n in '
		.. 'config/shared.lua), or, for a new setting, since = n; then update this digest.'
	eq(count, 1874, 'settings on members. ' .. why)
	eq(sum, EXPECTED_DIGEST, 'the digest (' .. size .. ' characters). ' .. why)
end)

------------------------------------------------------------------ Minor 5 and 6

test('a key set to nil in the session converts against what AceDB will refill: five units\' Name anchor', function()
	world()
	local units = { 'player', 'target', 'focus', 'pet', 'boss', 'party' }
	local function session()
		local db = SW.relog(SW.acedb({}))
		for _, unit in ipairs(units) do rawset(profile_of(db)[unit].name.position, 'element', nil) end
		return db
	end
	-- The base: the same nils, no conversion, a login.
	local baseline = SW.snapshot(profile_of(SW.relog(session())))
	local db = session()
	local profile = profile_of(db)
	eq(UF:PrepareShared(profile), true)
	eq(profile.all.name.position.element, 'Health', 'All units holds the anchor AceDB refills, not a missing one')
	for _, unit in ipairs({ 'player', 'target', 'focus', 'pet', 'boss' }) do
		check(not UF:IsOwn(unit, 'name.position'), unit .. ' follows the Name anchor')
	end
	db = SW.relog(db)
	local after = SW.snapshot(profile_of(db))
	for _, unit in ipairs(units) do
		eq(after[unit]['name.position'].element, baseline[unit]['name.position'].element, unit .. ' shows what it shows with no conversion')
	end
	eq(after.player['name.position'].element, 'Health')
	eq(UF:SyncShared(profile_of(db)), 0)
end)

test('M15 FollowAll clears the flag to false, never nil', function()
	local db = customized()
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	UF:SetShared('target', 'name.font', 'header')
	UF:FollowAll('target', 'name.font')
	eq(rawget(profile.target, 'own')['name.font'], false)
	UF:ApplyToAll('party', 'name.showLevel')
	eq(rawget(profile.raid10, 'own')['name.showLevel'], false)
end)

test('M30 SharedValue of an owner is its own value', function()
	local db = customized()
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	UF:SetShared('target', 'name.font', 'header')
	eq(UF:SharedValue('target', 'name.font'), 'header')
	eq(UF:SharedValue('player', 'name.font'), profile.all.name.font)
	check(UF:SharedValue('all', 'name.font') ~= 'header')
end)

test('M34 a copied position\'s relative point is written, and holds through a login', function()
	local db = customized()
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	UF:SetShared('all', 'name.position', { point = 'TOP', x_off = 0, y_off = 0 }) -- no relative point
	for _, unit in ipairs(SW.MEMBERS) do
		if not UF:IsOwn(unit, 'name.position') then eq(profile[unit].name.position.rel_point, 'TOP', unit) end
	end
	db = SW.relog(db)
	profile = profile_of(db)
	for _, unit in ipairs(SW.MEMBERS) do
		if not UF:IsOwn(unit, 'name.position') then eq(profile[unit].name.position.rel_point, 'TOP', unit .. ' after a login') end
	end
	eq(UF:SyncShared(profile), 0)
end)

test('M40 the sync puts the frame\'s Theme and Background right', function()
	local db = customized()
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	profile.target.theme = 'thin'
	profile.focus.background = 'solid'
	local writes, units = UF:SyncShared(profile)
	eq(writes, 2)
	eq(table.concat(units, ','), 'target,focus')
	eq(profile.target.theme, profile.all.theme)
	eq(profile.focus.background, profile.all.background)
end)

test('M3 the conversion does nothing on a marker at or above its version', function()
	local db = customized(SW.customize)
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	for _, version in ipairs({ UF.SHARED_VERSION, UF.SHARED_VERSION + 1 }) do
		rawset(profile.all, 'version', version)
		local listed = listing(profile)
		UF:ConvertShared(profile)
		check(listing(profile) == listed, 'marker ' .. version)
	end
end)

------------------------------------------------------------------ Minor 7 and the ticker

test('cost: a held slider and a sync make little garbage', function()
	local db = customized(SW.customize)
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	local ignore = { [UF.sharedTicker] = true }
	-- Followers that differ, as a held slider leaves them: one value of All units changes each call.
	local n = 0
	local m = C.measure(function()
		n = n + 1
		profile.all.health.alpha = (n % 10) / 10
		UF:PropagateShared('Health')
	end, 100, ignore)
	local perCall = m.kb / 100
	print(('PropagateShared %.2f KB a call'):format(perCall))
	check(perCall < 4, ('PropagateShared makes %.2f KB a call'):format(perCall))
	local s = C.measure(function() UF:SyncShared(profile) end, 20, ignore)
	print(('SyncShared %.2f KB a call'):format(s.kb / 20))
	check(s.kb / 20 < 32, ('SyncShared makes %.2f KB a call'):format(s.kb / 20))
end)

test('an error in one unit\'s update does not strand the marks after it', function()
	world()
	local db = SW.acedb({})
	UF:PrepareShared(profile_of(db))
	local calls = {}
	function UF:UpdateConfig(unit, element)
		calls[#calls + 1] = unit
		if unit == 'target' then error('boom', 0) end
	end
	UF:UpdateShared({ 'player', 'target', 'party', 'raid40' }, 'Name')
	SW.step(UF)
	eq(table.concat(calls, ','), 'player,target,party,raid40', 'every mark ran')
	eq(#take_errors(), 1, 'the error was reported')
	calls = {}
	SW.step(UF)
	eq(#calls, 0, 'and nothing is left for the next frame')
end)

------------------------------------------------------------------ N1 and N2

test('N1 a restore refuses while an element is not registered, and writes nothing', function()
	local db = customized(SW.customize)
	local profile = profile_of(db)
	UF:PrepareShared(profile)
	local listed = listing(profile)
	local castbar = UF.elements.Castbar
	UF.elements.Castbar = nil
	local ok, why = UF:RestoreShared(profile)
	eq(ok, false)
	check(tostring(why):find('Castbar', 1, true), 'it names the part: ' .. tostring(why))
	check(listing(profile) == listed, 'nothing was written, the marker included')
	eq(rawget(profile, 'restored'), nil, 'and no restore is recorded')
	UF.elements.Castbar = castbar
	eq(UF:RestoreShared(profile), true, 'it restores once the element is back')
end)

test('N2 reading a setting of an unconverted profile makes no All units: it never reaches the saved file', function()
	world()
	local db = SW.acedb({})
	local profile = profile_of(db)
	for _, key in ipairs({ 'name.font', 'health.colorClass', 'castbar.colors.normal', 'buffs.border' }) do
		for _, unit in ipairs({ 'all', 'player', 'party' }) do
			UF:SharedValue(unit, key)
			UF:IsOwn(unit, key)
		end
		UF:OwnersOf(key)
	end
	eq(rawget(profile, 'all'), nil, 'no All units made by a read')
	local saved = SW.logout(db)
	eq(rawget(saved.profiles.SaftUI.unitframes.profiles.SaftUI or {}, 'all'), nil, 'and none in the saved file')
end)
