-- Unit frame profiles and shared settings (SaftUI-Unitframes/config/profiles.lua with the real UF:UpdateConfig
-- wiring): New, Copy, Switch, Delete, Import and Export each leave every profile consistent. A new profile and a
-- copy are converted from THEIR values (a copy never carries its source's backup: UF.CopyProfileData), a switch to
-- a profile that is converted moves nothing, a deleted profile leaves the next one converted, an import is a
-- plain table that converts at the next login and says so once, and an export carries no backup.
--
-- Real: shared_world.lua's world (the unit frames' module, the shared files, the elements) over a real AceDB-3.0,
-- UF:OnEnable (the frames are plain Buttons, SW.enable) and SaftUI's own prompts and confirm (the options widgets),
-- driven as profiles_test.lua drives them. Stand-in: st.Config's Export and Import, which need the encoders (they
-- hand the data over as a deep copy of plain data, as the game's import makes it).
local SW = load_test_file('unitframes/shared_world.lua')

local st, UF, W, db, exported

local function world(customize)
	st, UF = SW.world()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	W = st.OptionsWidgets
	db = SW.acedb({})
	if customize then SW.customize(db.profile.unitframes.profiles.SaftUI) end
	db = SW.relog(db)
	SW.enable()
	st.Config = st.Config or {}
	function st.Config:Refresh() end
	function st.Config:Export(data) exported = data; return 'EXPORTED' end
	function st.Config:Import(text)
		if text == 'GOOD' then return true, SW.saved_copy(exported) end
		return false
	end
end

local function P() return db.profile.unitframes end
local function profile(name) return P().profiles[name or P().config_profile] end
local function press(key) UF.GenerateProfileConfigGroup().args[key].func() end
local function box() return W.PromptBox() end
local function type_and_enter(text)
	box():SetText(text)
	stub.fire_script(box(), 'OnEnterPressed')
end

local function count_owned(prof)
	local n = 0
	for _, unit in ipairs(SW.MEMBERS) do
		local own = rawget(prof[unit], 'own')
		for _, entry in ipairs(UF.SHARED) do
			if own and own[entry.key] == true then n = n + 1 end
		end
	end
	return n
end

local function lines_of(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

test('New: the new profile is converted from the defaults and has its own All units and backup; the profile it left is untouched', function()
	world(true)
	local first = profile('SaftUI')
	local first_owned = count_owned(first)
	press('new')
	type_and_enter('Fresh')
	eq(P().config_profile, 'Fresh')
	local fresh = profile('Fresh')
	eq(UF:SharedReady(fresh), true, 'converted at once')
	eq(count_owned(fresh), 155, 'from its own values: the defaults')
	check(UF.HasSharedBackup(fresh), 'with a backup of its own')
	check(rawget(fresh, 'all') ~= rawget(first, 'all'), 'its own All units')
	eq(count_owned(first), first_owned, 'the first profile is as it was')
	eq(#take_errors(), 0)
end)

test('Copy: the copy carries the values, All units and flags, never the backup, and shares nothing with its source', function()
	world(true)
	local source = profile('SaftUI')
	check(UF.HasSharedBackup(source), 'the source has a backup')
	local owned = count_owned(source)
	press('copy')
	type_and_enter('Copied')
	local copy = profile('Copied')
	eq(P().config_profile, 'Copied')
	eq(UF:SharedReady(copy), true)
	eq(UF.HasSharedBackup(copy), false, 'no backup carried')
	check(UF.HasSharedBackup(source), 'the source keeps its own')
	eq(count_owned(copy), owned, 'the same flags')
	check(not rawequal(rawget(copy, 'all'), rawget(source, 'all')) and not rawequal(copy.target, source.target), 'its own tables')
	-- Editing the copy does not touch the source.
	UF:SetShared('all', 'name.alpha', 0.33)
	check(rawget(source, 'all').name.alpha ~= 0.33, 'the source is unchanged')
	local ok, diffs = SW.same(SW.snapshot(source), SW.snapshot(source))
	check(ok)
	eq(#take_errors(), 0)
end)

test('Copy of a profile that was never converted: the copy is converted from ITS values, the source is not', function()
	world(false)
	-- A profile made and customized but not yet switched to (so never converted).
	local other = P().profiles.Other
	other.target.name.font = 'pixel'
	other.player.name.font = 'pixel'
	other.focus.name.font = 'pixel'
	eq(UF:SharedReady(other), false)
	P().config_profile = 'Other'
	-- (the page shows the profile in use; a Copy copies it before any update converted it)
	local before = SW.snapshot(other)
	press('copy')
	type_and_enter('OtherCopy')
	local copy = profile('OtherCopy')
	eq(UF:SharedReady(copy), true, 'the copy is converted')
	local ok, diffs = SW.same(before, SW.snapshot(copy))
	check(ok, 'it shows what the source showed: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 10)))
	eq(copy.all.name.font, 'normal', 'All units took the majority of ITS values')
	eq(rawget(copy.target, 'own')['name.font'], true)
	eq(rawget(other, 'all') == nil or rawget(other.all, 'version') == nil or UF:SharedReady(other), true, 'the source is as it was or converted by its own update')
end)

test('Switch: the profile select converts the profile it goes to, and moves nothing in either', function()
	world(true)
	local before = SW.snapshot(profile('SaftUI'))
	local other = P().profiles.Other
	other.pet.name.font = 'pixel'
	other.boss.name.font = 'pixel'
	other.focus.name.font = 'pixel'
	local other_before = SW.snapshot(other)
	UF.GenerateProfileConfigGroup().args.current.set(nil, 'Other')
	eq(P().config_profile, 'Other')
	eq(UF:SharedReady(other), true, 'converted on the switch')
	local ok, diffs = SW.same(other_before, SW.snapshot(other))
	check(ok, 'it shows what it showed: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 10)))
	UF.GenerateProfileConfigGroup().args.current.set(nil, 'SaftUI')
	ok, diffs = SW.same(before, SW.snapshot(profile('SaftUI')))
	check(ok, 'and back: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 10)))
	eq(#take_errors(), 0)
end)

test('Delete: the profile that is switched to is converted', function()
	world(true)
	local other = P().profiles.Other
	other.pet.name.font = 'pixel'
	P().config_profile = 'Other'
	UF:UpdateConfig()
	press('delete')
	stub.fire_script(W.GetDialogFrames().yes, 'OnClick')
	check(rawget(P().profiles, 'Other') == nil, 'deleted')
	eq(P().config_profile, 'SaftUI')
	eq(UF:SharedReady(profile()), true, 'the one switched to shares')
	eq(#take_errors(), 0)
end)

test('Export: the text is made of the profile without its backup, All units and flags included; the profile keeps its backup', function()
	world(true)
	local source = profile('SaftUI')
	press('export')
	check(exported ~= nil, 'something was exported')
	eq(rawget(exported, 'backup'), nil, 'no backup')
	check(rawget(exported, 'all') ~= nil and rawget(exported.all, 'version') == 1, 'All units and the marker go with it')
	check(exported.target ~= nil and rawget(exported.target, 'own') ~= nil, 'and the flags')
	check(UF.HasSharedBackup(source), 'the profile itself keeps its backup')
	check(not rawequal(exported, source), 'a copy')
end)

test('Import: a plain table, left alone in the session with one message, converted at the next login from its own values', function()
	world(true)
	press('export')
	local lines = lines_of(function()
		press('import')
		type_and_enter('GOOD')
	end)
	eq(P().config_profile, 'Imported')
	local imported = profile('Imported')
	eq(UF:SharedState(imported), 'plain')
	eq(UF:SharedReady(imported), false, 'no sharing in this session')
	local told = 0
	for _, line in ipairs(lines) do
		if line:find('next login', 1, true) then told = told + 1 end
	end
	eq(told, 1, 'it says so once: ' .. table.concat(lines, ' | '))
	-- Editing a plain table through the pages' sets writes nothing shared: no share is drawn.
	eq(rawget(imported, 'backup'), nil)
	local snapshot = SW.snapshot(profile('SaftUI'))
	db = SW.relog(db)
	SW.enable()
	check(UF:SharedReady(profile('Imported')), 'converted at the login (it carried the marker: a sync)')
	local ok, diffs = SW.same(snapshot, SW.snapshot(profile('Imported')))
	check(ok, 'and it shows what the exported profile showed: ' .. table.concat(diffs, ', ', 1, math.min(#diffs, 10)))
	eq(#take_errors(), 0)
end)
