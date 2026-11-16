-- The conversion and the sync on many customized profiles, through real AceDB logouts and logins whose saved
-- data drops functions, as WoW's file does (SW.relog). Each case: every member shows the same after the
-- conversion and after each login, the sync a login runs writes nothing, the flags survive. Ported from the
-- review of the first version (its cases C1 to C17, G, L6, C4c and C6c): the import cases are in
-- shared_guard_test.lua. Whole member tables are compared, not only the shared paths.
local SW = load_test_file('unitframes/shared_world.lua')

local st, UF

local function world()
	st, UF = SW.world()
end

local acedb_from = SW.acedb_from
local sv_copy = SW.saved_copy
local relog = SW.relog

local function profile_of(db, name) return db.profile.unitframes.profiles[name or 'SaftUI'] end

-- Every member path the conversion reads, read once, as readers do (AceDB makes wildcard tables on a read).
local function touch(profile)
	for _, unit in ipairs(SW.MEMBERS) do
		local c = rawget(profile, unit) or profile[unit]
		if type(c) == 'table' then
			for _, entry in ipairs(UF.SHARED) do
				for _, path in ipairs(entry.paths) do
					local node = c
					for _, key in ipairs(path) do
						if type(node) ~= 'table' then break end
						node = node[key]
					end
				end
			end
		end
	end
end

-- A plain deep copy, no functions, no empty tables, no 'own'.
local function plain(v, depth)
	if type(v) ~= 'table' then return v end
	local out, any = {}, false
	for k, x in pairs(v) do
		if type(x) ~= 'function' and not (depth == 0 and k == 'own') then
			local c = plain(x, (depth or 0) + 1)
			if c ~= nil then out[k] = c any = true end
		end
	end
	if not any then return nil end
	return out
end

local MEMBERS_AND_MORE = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party',
	'raid10', 'raid40', 'arena', 'nameplate', 'friendlynameplate', 'oldunit' }

local function snapshot(profile)
	touch(profile)
	local out = {}
	for _, unit in ipairs(MEMBERS_AND_MORE) do
		local c = rawget(profile, unit)
		out[unit] = plain(c, 0)
	end
	return out
end

local function diff(a, b, path, out)
	out = out or {}
	if type(a) ~= 'table' or type(b) ~= 'table' then
		-- An anchor frame that is nil and one that is false are the same (the unit frame): the sync writes false.
		local same_frame = path:sub(-6) == '.frame' and (a == nil or a == false) and (b == nil or b == false)
		if a ~= b and not same_frame then out[#out + 1] = path .. ': ' .. tostring(a) .. ' -> ' .. tostring(b) end
		return out
	end
	for k, v in pairs(a) do diff(v, b[k], path .. '.' .. tostring(k), out) end
	for k, v in pairs(b) do if a[k] == nil then diff(nil, v, path .. '.' .. tostring(k), out) end end
	return out
end

local function same(a, b, label)
	local d = diff(a, b, '')
	table.sort(d)
	check(#d == 0, label .. ': ' .. #d .. ' diffs: ' .. table.concat(d, "; ", 1, math.min(#d, 60)))
	return #d == 0
end

local function owns(profile)
	local out = {}
	for _, unit in ipairs(SW.MEMBERS) do
		local c = rawget(profile, unit)
		local own = c and rawget(c, 'own')
		local keys = {}
		for _, entry in ipairs(UF.SHARED) do
			if own and own[entry.key] == true then keys[#keys + 1] = entry.key end
		end
		out[unit] = table.concat(keys, ',')
	end
	return out
end

-- The full upgrade on db's profile: before, PrepareShared, then logins with the sync each time; every snapshot equals the first.
local function upgrade_holds(db, label, opts)
	opts = opts or {}
	local profile = profile_of(db, opts.name)
	local before = snapshot(profile)
	local ok = UF:PrepareShared(profile)
	eq(ok, true, label .. ': prepared clean')
	for _, e in ipairs(take_errors()) do check(false, label .. ' error: ' .. e) end
	same(before, snapshot(profile), label .. ': after the conversion and sync')
	local writes = UF:SyncShared(profile)
	eq(writes, 0, label .. ': a second sync writes nothing')
	local flags = owns(profile)
	UF:ConvertShared(profile)
	same(flags, owns(profile), label .. ': a second conversion changes no flag')
	for i = 1, 3 do
		db = relog(db)
		profile = profile_of(db, opts.name)
		local w = 0
		-- What Task 6 does at login: PrepareShared before anything is drawn.
		if rawget(profile, 'all') and rawget(profile.all, 'version') == UF.SHARED_VERSION then
			w = UF:SyncShared(profile)
		end
		if opts.expect_login_writes == nil then
			eq(w, 0, label .. ': login ' .. i .. ' sync writes')
		end
		same(before, snapshot(profile), label .. ': after login ' .. i)
		same(flags, owns(profile), label .. ': flags after login ' .. i)
	end
	return db, before, flags
end

local function fresh_db()
	world()
	return acedb_from({ profiles = { SaftUI = { unitframes = { profiles = { SaftUI = {} } } } } })
end

local function customized(fn, settle)
	local db = fresh_db()
	fn(profile_of(db))
	if settle ~= false then db = relog(db) end
	return db
end

test('C1 fresh profile', function()
	upgrade_holds(fresh_db(), 'fresh')
end)

test('C2 every unit different', function()
	local fonts = { 'pixel', 'normal', 'header', 'Homespun', 'pixel2', 'pixel3', 'small', 'big', 'x1', 'x2', 'x3' }
	upgrade_holds(customized(function(p)
		for i, unit in ipairs(SW.MEMBERS) do
			p[unit].name.font = fonts[i]
			p[unit].name.maxLength = 10 + i
			p[unit].health.text.position.x_off = i
			p[unit].power.height = i
			p[unit].buffs.size = 10 + i
			p[unit].theme = (i % 2 == 0) and 'thin' or 'thick'
			if p[unit].castbar then p[unit].castbar.colors.normal = { r = i / 20, g = 0.5, b = 0.5 } end
			p[unit].raidtargetindicator.size = 8 + i
		end
	end), 'every unit different')
end)

test('C3 one unit different', function()
	upgrade_holds(customized(function(p) p.target.name.maxLength = 12 end), 'one unit')
end)

test('C4b the same, saved and logged in first', function()
	upgrade_holds(customized(function(p)
		p.target.castbar.colors.normal = {}
		p.pet.name.position = {}
		p.boss.name.maxLength = 0
		p.party.health.Smooth = false
		p.raid10.buffs.size = 0
		p.target.power.height = ''
		p.focus.name.alpha = 0
	end), 'nil false 0 empty, logged in')
end)

test('C5 colors with and without alpha', function()
	upgrade_holds(customized(function(p)
		p.target.castbar.colors.normal = CreateColor(1, 0, 0, 0.5)
		p.focus.castbar.colors.normal = { r = 1, g = 0, b = 0 }
		p.player.castbar.colors.normal = { 1, 0, 0 }
		p.boss.castbar.colors.normal = { r = 1, g = 0, b = 0, a = 1 }
		p.raid10.health.colorCustom = true
		p.raid10.health.customColor = { 1, 0, 0, 0.3 }
		p.raid40.health.colorCustom = true
		p.raid40.health.customColor = { r = 1, g = 0, b = 0, a = 0.9 }
		p.party.health.customColor = { 0, 1, 0 } -- unticked, a hidden color
	end), 'colors')
end)

test('C6 anchors: missing, false, UIParent, a frame name, another element', function()
	local db = customized(function(p)
		p.target.name.position.element = false
		p.focus.name.position = { point = 'LEFT', rel_point = 'LEFT', frame = 'UIParent', element = false, x_off = 7, y_off = -1 }
		p.boss.name.position = { point = 'LEFT', rel_point = 'LEFT', frame = 'SomeAddonFrame', element = false, x_off = 7, y_off = -1 }
		p.pet.name.position.element = 'Power'
		p.party.castbar.position.element = 'Health'
		p.raid10.castbar.position.frame = 'UIParent'
		p.player.power.position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = -200, element = false }
	end)
	upgrade_holds(db, 'anchors')
end)

test('C7 a setting some units name in their defaults and others take from the wildcard', function()
	upgrade_holds(customized(function(p)
		p.target.castbar.width = 0
		p.target.castbar.relative_width = true
		p.boss.castbar.width = 299
		p.boss.castbar.relative_width = false
	end), 'castbar width')
end)

test('C8 a table value partly customized', function()
	upgrade_holds(customized(function(p)
		p.target.name.position.x_off = 3
		p.focus.castbar.colors.normal.r = 0.1
		p.raid40.health.customColor[1] = 0.2
		p.raid40.health.colorCustom = true
		p.party.buffs.position.y_off = 9
	end), 'partly')
end)

test('C9 a member table missing in session', function()
	local db = customized(function(p) p.target.name.font = 'pixel' end)
	local p = profile_of(db)
	local saved = rawget(p, 'pettarget')
	rawset(p, 'pettarget', nil)
	local before = snapshot(p) -- pettarget now made by the wildcard on a read
	eq(UF:PrepareShared(p), true)
	same(before, snapshot(p), 'missing member, in session')
end)

test('C10 a removed unit and older keys', function()
	upgrade_holds(customized(function(p)
		p.oldunit = { name = { font = 'x' }, health = { height = 3 } }
		p.player.oldkey = 7
		p.target.name.oldkey = 'y'
		p.player.healthtemplate = 'thick'
	end), 'removed unit')
end)

test('C11 the wildcard tables: aura hostilities', function()
	upgrade_holds(customized(function(p)
		p.party.buffs.friend.colorStealable = true
		p.raid10.debuffs.enemy.colorTypes = true
		p.player.debuffs.friend.colorTypes = false
		p.target.buffs.enemy.colorStealable = false
	end), 'hostilities')
end)

test('C12 an older SaftUI: list colors, string offsets, -0', function()
	upgrade_holds(customized(function(p)
		p.target.castbar.colors.normal = { 0.1, 0.2, 0.3 }
		p.focus.power.height = '5'
		p.pet.power.height = 5
		p.boss.raidtargetindicator.position.x_off = '5'
		p.pet.name.position.x_off = -0
		p.party.name.position.y_off = '-1'
	end), 'older shapes')
end)

test('C13 typefaces', function()
	upgrade_holds(customized(function(p)
		p.target.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
		p.player.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
		p.focus.name.font = { font_name = 'Homespun', font_size = 12.00001, font_outline = 'MONOCHROMEOUTLINE' }
		p.boss.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
		p.pet.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
		p.party.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
		p.raid10.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
	end), 'typefaces')
end)

test('C14 colortoggles ticked and unticked', function()
	upgrade_holds(customized(function(p)
		for i, unit in ipairs({ 'player', 'target', 'focus' }) do
			p[unit].health.colorCustom = true
			p[unit].health.customColor = { 0.1 * i, 0.2, 0.3 }
		end
		for i, unit in ipairs({ 'pet', 'boss', 'party', 'raid10', 'raid40', 'targettarget' }) do
			p[unit].health.colorCustom = false
			p[unit].health.customColor = { 0.05 * i, 0.9, 0.1 }
		end
		for _, unit in ipairs(SW.MEMBERS) do
			p[unit].power.text.colorCustom = true
			p[unit].power.text.customColor = { 1, 0.5, 0 }
		end
	end), 'colortoggles')
end)

test('C15 the majority customized everywhere, a tie the default is not in', function()
	upgrade_holds(customized(function(p)
		for _, unit in ipairs(SW.MEMBERS) do
			p[unit].name.enable = false
			p[unit].name.showLevel = false
			p[unit].health.text.enable = true
		end
		for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget' }) do p[unit].name.alpha = 0.5 end
		for _, unit in ipairs({ 'pet', 'pettarget', 'boss', 'party', 'raid10' }) do p[unit].name.alpha = 0.25 end
	end), 'majorities')
end)

test('C16 SW.customize (the implementer\'s set)', function()
	upgrade_holds(customized(SW.customize), 'SW.customize')
end)

test('C17 a unit frame profile of another name, a switch and a copy', function()
	local db = customized(function(p) SW.customize(p) end)
	local ufp = db.profile.unitframes
	ufp.profiles.Healer.player.name.font = 'pixel'
	ufp.profiles.Healer.raid40.buffs.size = 33
	db = relog(db)
	ufp = db.profile.unitframes
	local before = snapshot(ufp.profiles.SaftUI)
	local beforeHealer = snapshot(ufp.profiles.Healer)
	UF:PrepareShared(ufp.profiles.SaftUI)
	ufp.config_profile = 'Healer'
	UF:PrepareShared(UF:GetProfileConfig())
	same(beforeHealer, snapshot(ufp.profiles.Healer), 'Healer converted')
	ufp.config_profile = 'SaftUI'
	eq(UF:SyncShared(UF:GetProfileConfig()), 0, 'switch back: nothing to sync')
	ufp.profiles.Copy = UF.CopyProfileData(ufp.profiles.SaftUI)
	UF:PrepareShared(ufp.profiles.Copy)
	same(before, snapshot(ufp.profiles.Copy), 'copy shows the same')
	eq(UF:SyncShared(ufp.profiles.Copy), 0)
	db = relog(db)
	ufp = db.profile.unitframes
	for _, name in ipairs({ 'SaftUI', 'Copy' }) do
		eq(UF:SyncShared(ufp.profiles[name]), 0, name .. ' sync after login')
		same(before, snapshot(ufp.profiles[name]), name .. ' after login')
	end
	eq(UF:SyncShared(ufp.profiles.Healer), 0)
	same(beforeHealer, snapshot(ufp.profiles.Healer), 'Healer after login')
	-- A copy made by UF.CopyProfileData does not carry the backup of the profile it came from.
	eq(rawget(ufp.profiles.Copy, 'backup'), nil, 'the copy has no backup')
	eq(rawget(ufp.profiles.SaftUI, 'backup') ~= nil, true, 'the source keeps its own')
end)

-- Against the base: the same edits, logins with no conversion; the converted profile must show the same after each login.
local function flow(fn, convert)
	local db = customized(fn, false)
	if convert then eq(UF:PrepareShared(profile_of(db)), true) end
	local snaps, writes = {}, {}
	for i = 1, 2 do
		db = relog(db)
		local p = profile_of(db)
		writes[i] = convert and UF:SyncShared(p) or 0
		snaps[i] = snapshot(p)
	end
	return snaps, writes
end

local function against_base(label, fn)
	local b = flow(fn, false)
	local c, w = flow(fn, true)
	for i = 1, 2 do same(b[i], c[i], label .. ': login ' .. i .. ' (sync wrote ' .. w[i] .. ')') end
end


test('C4c in-session nils against the base', function()
	against_base('in-session nils', function(p)
		rawset(p.player.name, 'font', nil)
		rawset(p.focus.health.text, 'font', nil)
		p.target.castbar.colors.normal = {}
		p.pet.name.position = {}
		p.boss.name.maxLength = 0
		p.player.debuffs.position = { point = 'TOP' }
	end)
end)

test('C6c in-session missing anchor against the base', function()
	against_base('missing anchor', function(p)
		rawset(p.player.name.position, 'element', nil)
		rawset(p.target.name.position, 'element', nil)
		rawset(p.focus.name.position, 'element', nil)
		rawset(p.pet.name.position, 'element', nil)
		rawset(p.boss.name.position, 'element', nil)
		rawset(p.party.name.position, 'element', nil)
	end)
end)

