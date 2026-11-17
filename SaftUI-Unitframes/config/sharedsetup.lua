local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Settings the unit frames share, the second half of config/shared.lua (loaded right after it):
	the one-time backup and its restore, the conversion, and the states and the guarded entries a
	login and the page call (UF:PrepareShared, UF:EnableShared). Like shared.lua it builds no page
	and applies nothing, and every function here writes tables and nothing else. It reads the
	locals of shared.lua that it needs through UF.sharedLocals, which it takes and clears.
]]

local X = UF.sharedLocals
UF.sharedLocals = nil
local AllOf, ConfigOf, CopyPlain, Get, Marker, Members = X.AllOf, X.ConfigOf, X.CopyPlain, X.Get, X.Marker, X.Members
local MissingElement, OwnTable, SharedFailed, SharedTold, Shown = X.MissingElement, X.OwnTable, X.SharedFailed, X.SharedTold, X.Shown
local MEMBER_LIST, SHARED = UF.SHARE_MEMBERS, UF.SHARED

------------------------------------------------------------------ the backup, the conversion and the states

-- The one-time backup, kept before the first conversion: for each member, the values of the settings it
-- has (the shared paths, as plain data, as the saved file holds them) and its own flags for them, as they
-- were; a value equal to the member's default is left out (a restore writes the default). Not the whole
-- profile: a restore puts back only what the conversion and later sharing could change, and a unit's
-- place, size and the plates stay as the player has them.
local function JoinPath(path) return table.concat(path, '.') end

local function DeepEqual(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for k, v in pairs(a) do
		if not DeepEqual(v, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

-- The member's default at a path: found, value (AceDB's, read and never written).
local function DefaultOf(unit, path)
	return st:DefaultAt('unitframes', 'profiles', UF:GetProfile() or 'SaftUI', unit, unpack(path))
end

local function MakeBackup(self, profile)
	local units = {}
	for _, unit in ipairs(MEMBER_LIST) do
		local config = ConfigOf(profile, unit)
		if config then
			local values, own = {}, {}
			local flags = rawget(config, 'own')
			for _, entry in ipairs(SHARED) do
				if self:HasShared(unit, entry.key) then
					for _, path in ipairs(entry.paths) do
						local value = Get(config, path)
						-- A value that is the unit's default is left out: a restore writes the default back.
						local found, default = DefaultOf(unit, path)
						if value ~= nil and not (found and DeepEqual(value, default)) then
							values[JoinPath(path)] = CopyPlain(value)
						end
					end
					if flags and flags[entry.key] ~= nil then own[entry.key] = flags[entry.key] end
				end
			end
			-- No empty tables in the saved file: a unit with nothing to keep has no entry, and a part with
			-- nothing has no key.
			local entry
			if next(values) ~= nil then entry = { values = values } end
			if next(own) ~= nil then entry = entry or {}; entry.own = own end
			if entry then units[unit] = entry end
		end
	end
	return { version = UF.SHARED_VERSION, when = time(), units = next(units) ~= nil and units or nil }
end

-- Whether the profile holds the backup from before the first conversion.
function UF.HasSharedBackup(profile)
	local backup = rawget(profile, 'backup')
	return type(backup) == 'table' and type(backup.version) == 'number'
end

-- A copy of a unit frame profile for a Copy or an export: everything but what belongs to the profile it was
-- made for: the backup, and the marks of a restore (restored, restoredTold), so the copy converts like any
-- other profile. (profiles.lua's Copy and Export use it.)
function UF.CopyProfileData(profile)
	local copy = st.tablecopy(profile, true)
	rawset(copy, 'backup', nil)
	rawset(copy, 'restored', nil)
	rawset(copy, 'restoredTold', nil)
	return copy
end

-- Saved values into the live tables: a table into the live table in place (keeping its metatable, and the
-- function fields a color's methods are, which the saved file doesn't hold), every other value assigned.
local function MergeInPlace(live, saved)
	for key, value in pairs(saved) do
		local current = rawget(live, key)
		if type(value) == 'table' and type(current) == 'table' then
			MergeInPlace(current, value)
		else
			live[key] = CopyPlain(value)
		end
	end
	local gone
	for key, value in pairs(live) do
		if saved[key] == nil and type(value) ~= 'function' then
			gone = gone or {}
			gone[#gone + 1] = key
		end
	end
	if gone then
		for _, key in ipairs(gone) do live[key] = nil end
	end
end

local function WriteBack(config, path, saved)
	local parent = config
	for index = 1, #path - 1 do
		local nextNode = parent[path[index]]
		if type(nextNode) ~= 'table' then
			nextNode = {}
			parent[path[index]] = nextNode
		end
		parent = nextNode
	end
	local last = path[#path]
	local current = rawget(parent, last)
	if saved == nil then
		parent[last] = nil
	elseif type(saved) == 'table' and type(current) == 'table' then
		MergeInPlace(current, saved)
	else
		parent[last] = CopyPlain(saved)
	end
end

-- Puts the backup back: each member's shared settings get the values and own flags they had before the
-- first conversion, written into the live tables in place (so the tables keep AceDB's wildcards, a color its
-- methods, and what holds a reference reads them), and All units is dropped, and so the marker is: the next
-- conversion starts again. Everything else in the profile (a unit's place and size, the plates, Class power)
-- is as the player has it now. The backup stays. Returns true, or false and why. Applies nothing: the
-- caller reloads the interface, or updates the unit frames.
function UF:RestoreShared(profile)
	profile = profile or self:GetProfileConfig()
	if type(profile) ~= 'table' or not UF.HasSharedBackup(profile) then
		return false, 'There is no backup of the unit frame settings from before sharing.'
	end
	-- A member whose element is not registered has no setting for it: its values would be left as sharing
	-- made them while the marker went, and a later restore would revert whatever changed since.
	local missing = MissingElement()
	if missing then
		return false, 'The unit frame part ' .. missing .. ' did not load, so nothing was restored.'
	end
	local units = rawget(profile, 'backup').units or {}
	for _, unit in ipairs(MEMBER_LIST) do
		-- A unit with no entry had nothing to keep: every shared setting at its default, no flags.
		local saved = units[unit] or {}
		local config = type(saved) == 'table' and ConfigOf(profile, unit)
		if config then
			local values, own = saved.values or {}, saved.own or {}
			local flags = rawget(config, 'own')
			for _, entry in ipairs(SHARED) do
				if self:HasShared(unit, entry.key) then
					for _, path in ipairs(entry.paths) do
						local value = values[JoinPath(path)]
						if value == nil then
							local found, default = DefaultOf(unit, path)
							if found then value = default end
						end
						WriteBack(config, path, value)
					end
					if own[entry.key] ~= nil then
						OwnTable(config)[entry.key] = own[entry.key]
					elseif flags then
						flags[entry.key] = nil
					end
				end
			end
		end
	end
	rawset(profile, 'all', nil)
	-- The owner asked to be back where they were: no login converts this profile again by itself.
	-- UF:EnableShared (/sui uf share, or the button on the All units page) is the way back to sharing.
	rawset(profile, 'restored', time())
	rawset(profile, 'restoredTold', nil)
	SharedFailed[profile] = nil
	SharedTold[profile] = 'restored'
	return true
end

-- What the conversion would do, all of it computed before anything is written: for each entry of the
-- steps above the marker, the value All units takes (nil when it holds it already), and the members
-- that own it. A member is compared by what it will show after the next login (Shown).
local function PlanConversion(self, profile, marker)
	-- All units as it reads now: the saved table, or, while there is none (a profile never converted: no
	-- `all` table is made before it is), what AceDB's wildcard would give a table made by a read.
	local all = rawget(profile, 'all') and profile.all
	local plan = { writes = {}, owns = {} }
	for _, entry in ipairs(SHARED) do
		if (entry.since or 1) > marker then
			local members = Members(self, profile, entry.key)
			for _, member in ipairs(members) do member.shown = Shown(entry, member.unit, member.config) end
			if #members > 0 then
				local groups = {}
				for index, member in ipairs(members) do
					local group
					for _, candidate in ipairs(groups) do
						if UF.SameShared(entry, candidate.config, member.shown) then group = candidate break end
					end
					if group then
						group.count = group.count + 1
					else
						groups[#groups + 1] = { config = member.shown, count = 1, first = index }
					end
				end
				local best = 0
				for _, group in ipairs(groups) do best = math.max(best, group.count) end
				local tied = {}
				for _, group in ipairs(groups) do
					if group.count == best then tied[#tied + 1] = group end
				end
				local default = UF.DefaultShared(entry)
				local winner
				if #tied == 1 then
					winner = tied[1].config
				else
					for _, group in ipairs(tied) do
						if UF.SameShared(entry, default, group.config) then winner = default break end
					end
					winner = winner or tied[1].config
				end
				if not UF.SameShared(entry, all or UF.DefaultShared(entry, true), winner) then
					plan.writes[#plan.writes + 1] = { entry = entry, from = winner }
				end
				for _, member in ipairs(members) do
					if not UF.SameShared(entry, member.shown, winner) then
						plan.owns[#plan.owns + 1] = { config = member.config, key = entry.key }
					end
				end
			end
		end
	end
	return plan
end

-- Once per unit frame profile, for each step above the marker (see the top). Table writes only.
-- Computes everything first, then writes: the one-time backup, All units' values, the own flags,
-- and the marker last. Does nothing on a converted profile. Raises, and so writes nothing, for a
-- profile AceDB hasn't made (a plain imported table: it converts at the login that fills it, on the data
-- the frames will read) and while any element an entry names is not registered (the conversion would
-- take a missing element's settings for none and mark its members as following).
function UF:ConvertShared(profile)
	profile = profile or self:GetProfileConfig()
	local marker = Marker(profile)
	-- A step no entry could be converted by is a mistake in this file, whatever the profile.
	for _, entry in ipairs(SHARED) do
		if (entry.since or 1) > UF.SHARED_VERSION then
			error(('UF.SHARED entry %s is since %d, but UF.SHARED_VERSION is %d: no conversion step covers it.')
				:format(entry.key, entry.since, UF.SHARED_VERSION), 0)
		end
	end
	if marker >= UF.SHARED_VERSION then return end
	if getmetatable(profile) == nil then
		error('The unit frame profile has no AceDB defaults yet: it converts at the next login.', 0)
	end
	local missing = MissingElement()
	if missing then
		error('The unit frame element ' .. missing .. ' is not registered: the conversion waits for it.', 0)
	end
	local plan = PlanConversion(self, profile, marker)
	local backup
	if marker == 0 and not UF.HasSharedBackup(profile) then backup = MakeBackup(self, profile) end
	if backup then rawset(profile, 'backup', backup) end
	local all = AllOf(profile, true)
	for _, write in ipairs(plan.writes) do UF.CopyShared(write.entry, write.from, all) end
	for _, own in ipairs(plan.owns) do OwnTable(own.config)[own.key] = true end
	rawset(all, 'version', UF.SHARED_VERSION)
end

-- Why sharing is not in force for the profile, without doing anything: nil while it is, else
--   'none'      there is no profile
--   'plain'     a table with no AceDB defaults (an import made in this session: it shares from the next login; a copy keeps AceDB's tables)
--   'restored'  the owner restored the backup: nothing converts it again until UF:EnableShared
--   'newer'     a newer SaftUI converted it: its flags and values are left alone
--   'missing'   a part of the unit frames did not load (an element an entry names is not registered)
--   'failed'    the setup raised an error this session
--   'pending'   not converted yet (the next UF:PrepareShared does it)
function UF:SharedState(profile)
	profile = profile or self:GetProfileConfig()
	if type(profile) ~= 'table' then return 'none' end
	if getmetatable(profile) == nil then return 'plain' end
	if UF.SharedRestored(profile) and Marker(profile) == 0 then return 'restored' end
	local marker = Marker(profile)
	if marker > UF.SHARED_VERSION then return 'newer' end
	if SharedFailed[profile] then return 'failed' end
	if MissingElement() then return 'missing' end
	if marker == UF.SHARED_VERSION then return 'ready' end
	return 'pending'
end

-- The plain sentence for why sharing is off (a state of UF:SharedState), or nil for 'ready' and 'pending'.
function UF.SharedStateText(state, profile)
	if state == 'plain' then
		return 'This unit frame profile was imported during this session. Its settings start sharing between units at your next login.'
	elseif state == 'restored' then
		return 'Shared settings are off for this unit frame profile, as you restored it. Type /sui uf share to turn them on again.'
	elseif state == 'newer' then
		return 'This unit frame profile was saved by a newer SaftUI, so its shared settings are left as they are.'
	elseif state == 'missing' then
		return 'Shared settings are paused: the unit frame part ' .. tostring(MissingElement()) .. ' did not load, so sharing waits for it. Nothing was changed, and your edits are kept.'
	elseif state == 'failed' then
		local detail = type(SharedFailed[profile]) == 'string' and (' (' .. SharedFailed[profile] .. ')') or ''
		if type(profile) == 'table' and Marker(profile) >= 1 then
			return 'Shared settings are paused for this unit frame profile for this session: a sync failed, so nothing more is written. Your edits are kept.' .. detail
		end
		return 'Shared settings could not be set up for this unit frame profile, so it is left exactly as it was.' .. detail
	end
end

-- Says why sharing is off, once for each profile and reason in this session.
local function Tell(profile, state)
	if SharedTold[profile] == state then return end
	SharedTold[profile] = state
	-- A restored profile says so at the first login after the restore only (the All units page keeps saying it).
	if state == 'restored' then
		if rawget(profile, 'restoredTold') then return end
		rawset(profile, 'restoredTold', true)
	end
	local text = UF.SharedStateText(state, profile)
	if text then st:Print(text) end
end

-- Everything a login or a profile change does for sharing, guarded: the conversion, then the sync
-- only while the marker says the profile is converted. Nothing is written, and the frames build from
-- the stored values exactly as before sharing existed, for a profile that is plain (an import or copy in
-- this session: it converts at the login that gives it AceDB's tables), restored (the owner asked to be
-- back), newer (a newer SaftUI's), or while an element is not registered; each says why once in chat
-- (UF.SharedStateText). A profile the conversion can't read (a malformed saved table) raises an error
-- through the game's handler once, is left without the marker, says so once, and is not tried again
-- this session; the sync never runs over it. Returns true when sharing is in force, else false and the
-- state.
function UF:PrepareShared(profile)
	profile = profile or self:GetProfileConfig()
	if type(profile) ~= 'table' then return false, 'none' end
	local state = self:SharedState(profile)
	if state == 'pending' then
		local ok, err = xpcall(function()
			self:ConvertShared(profile)
			if Marker(profile) == UF.SHARED_VERSION then self:SyncShared(profile) end
		end, function(message)
			geterrorhandler()(message)
			return message
		end)
		if not ok then SharedFailed[profile] = type(err) == 'string' and err or true end
		state = self:SharedState(profile)
		-- Said whenever a profile is converted, so a login that finally can (after a part did not load, or an
		-- error) tells the owner: sharing is on, nothing moved.
		if ok and state == 'ready' then
			st:Print('Shared unit frame settings are set up for this unit frame profile. Nothing changed on screen, and a backup was kept: /sui uf restore goes back.')
		end
	elseif state == 'ready' then
		-- A converted profile: the sync puts right a drift (a hand edit, a default a later SaftUI changed).
		local ok, err = xpcall(function() self:SyncShared(profile) end, function(message)
			geterrorhandler()(message)
			return message
		end)
		if not ok then
			-- Raised once: the profile's sharing is paused for the session (nothing is written, no page has a
			-- share, edits are still marked as the unit's own), and the owner is told once.
			SharedFailed[profile] = type(err) == 'string' and err or true
			state = self:SharedState(profile)
		end
	end
	if state == 'ready' then return true end
	if state ~= 'pending' then Tell(profile, state) end
	return false, state
end

-- Turns sharing on for a profile that is off (/sui uf share, or the All units page's button): clears the
-- restore, forgets a failed setup, makes a fresh backup of the profile as it is now (the old one was of
-- before the restore), then converts like a login. A plain or newer profile is refused, with why.
-- Returns true when sharing is in force, else false and a sentence.
function UF:EnableShared(profile)
	profile = profile or self:GetProfileConfig()
	local state = self:SharedState(profile)
	if state == 'ready' then return true end
	if state == 'none' or state == 'plain' or state == 'newer' or state == 'missing' then
		return false, UF.SharedStateText(state, profile) or 'There is no unit frame profile.'
	end
	if UF.SharedRestored(profile) then
		rawset(profile, 'restored', nil)
		rawset(profile, 'backup', nil)
	end
	rawset(profile, 'restoredTold', nil)
	SharedFailed[profile] = nil
	SharedTold[profile] = nil
	local ok, why = self:PrepareShared(profile)
	if ok then return true end
	return false, UF.SharedStateText(why, profile) or 'Shared settings could not be turned on.'
end
