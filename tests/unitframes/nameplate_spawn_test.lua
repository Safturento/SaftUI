-- SaftUI's nameplates, spawned (SaftUI-Unitframes/nameplates/nameplates.lua
-- and unitframes.lua):
--   - UF:SpawnNameplates makes oUF's nameplate driver once, after the other
--     units, sets the config's size and sets it again after Blizzard sets its
--     own, waiting for the end of combat;
--   - it stands down, touching nothing of Blizzard's, while Nameplates is off
--     or another nameplate addon draws the plates (UF.NAMEPLATE_ADDONS);
--   - each plate's frame is built on its plate's first add, kept by its
--     plate's number (UF.nameplates), updated once after oUF's init, and kept
--     for the plate's next unit; the plate callbacks ('added', 'removed',
--     'updated');
--   - config changes, profile switches and purge filter refreshes reach the
--     plates, whose points stay oUF's;
--   - a bar's colour flags on a paused plate stay plain fields, so its
--     UNIT_FACTION stays off until oUF resumes it;
--   - nothing is written onto Blizzard's plate frames.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), with Blizzard's plate frames locked.
local NP = load_test_file('unitframes/nameplate_world.lua')

-- The config's size as the driver gets it, so these cases hold whatever
-- UF.PlateDriverSize converts.
local function driver_size(UF, width, height)
	return table.concat({ UF.PlateDriverSize(width, height) }, 'x')
end
local function size_set()
	return stub.nameplate_size and table.concat(stub.nameplate_size, 'x')
end

------------------------------------------------------------------ spawning

test('Nameplates on: one driver, the config size, and a second call spawns nothing', function()
	local st, UF = NP.world('forever')
	local size = driver_size(UF, 200, 20)
	check(UF:SpawnNameplates(), 'spawned')
	check(UF.plateDriver ~= nil, 'the driver kept')
	eq(size_set(), size, "the config's size")
	local driver = UF.plateDriver
	check(not UF:SpawnNameplates(), 'not again')
	eq(UF.plateDriver, driver, 'the same driver')
	eq(#take_errors(), 0, "no error: oUF's second spawn never ran")
end)

test("the stand-in's second SpawnNamePlates reports oUF's error", function()
	local st, UF = NP.world('forever')
	check(NP.ouf:SpawnNamePlates('SaftUI_') ~= nil, 'a driver')
	eq(NP.ouf:SpawnNamePlates('SaftUI_'), nil, 'none the second time')
	local errors = take_errors()
	eq(#errors, 1, 'one error reported')
	check(tostring(errors[1]):find('oUF nameplate driver has already been initialized.', 1, true), tostring(errors[1]))
end)

test("the stand-in's IsElementEnabled and IsElementPaused want an element name, as oUF's argcheck does", function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	for _, method in ipairs({ 'IsElementEnabled', 'IsElementPaused' }) do
		local ok, err = pcall(frame[method], frame, nil)
		eq(ok, false, method .. ': no name errors')
		check(tostring(err):find("Bad argument #2 to '" .. method .. "' (string expected, got nil)", 1, true), tostring(err))
	end
end)

test('OnEnable spawns nameplates after the other units', function()
	local src = read_saftui_source('SaftUI-Unitframes/unitframes.lua')
	local body = src:match('function UF:OnEnable%(%)(.-)\nend')
	local spawn = body:find('SpawnNameplates', 1, true)
	check(spawn, 'OnEnable spawns them')
	for _, call in ipairs({ 'CreateGroupHeaders', 'ApplyConfig', 'UpdateColors', 'RegisterMovers' }) do
		local at = body:find(call, 1, true)
		check(at and spawn and at < spawn, call .. ' first')
	end
end)

test('the nameplate defaults: on, friendly plates on, threat solo off, 200 by 20', function()
	local st, UF = NP.world('forever')
	local P = UF:GetProfileConfig().nameplate
	eq(P.enable, true, 'enable')
	eq(P.friendly, true, 'friendly')
	eq(P.threat_solo, false, 'threat_solo')
	eq(P.width, 200, 'width')
	eq(P.height, 20, 'height')
end)

test('Nameplates off: no driver, no size set', function()
	local st, UF = NP.world('forever')
	UF:GetProfileConfig().nameplate.enable = false
	local before = rawget(NamePlateDriverFrame, 'UpdateNamePlateSize')
	check(not UF:SpawnNameplates(), 'not spawned')
	eq(UF.plateDriver, nil, 'no driver')
	eq(stub.nameplate_size, nil, 'no size')
	eq(rawget(NamePlateDriverFrame, 'UpdateNamePlateSize'), before, 'not hooked')
	eq(NP.add('nameplate1'), nil, 'a plate gets no frame of SaftUI\'s')
	eq(next(UF.nameplates), nil, 'none kept')
end)

test('another nameplate addon loaded: SaftUI stands down and touches nothing', function()
	for _, a in ipairs({
		{ 'Plater', 'Plater' }, { 'EllesmereUINameplates', 'EllesmereUI Nameplates' },
		{ 'Kui_Nameplates', 'KuiNameplates' }, { 'TidyPlates_ThreatPlates', 'Threat Plates' },
		{ 'NeatPlates', 'NeatPlates' }, { 'Platynator', 'Platynator' },
	}) do
		local st, UF = NP.world('forever')
		eq(UF:NameplateAddon(), nil, a[1] .. ': none before it loads')
		stub.loaded_addons[a[1]] = true
		local before = rawget(NamePlateDriverFrame, 'UpdateNamePlateSize')
		check(not UF:SpawnNameplates(), a[1])
		eq(UF:NameplateAddon(), a[2], a[1] .. "'s name")
		eq(UF.plateDriver, nil, a[1] .. ': no driver')
		eq(stub.nameplate_size, nil, a[1] .. ': no size')
		eq(rawget(NamePlateDriverFrame, 'UpdateNamePlateSize'), before, a[1] .. ': not hooked')
		eq(NP.add('nameplate1'), nil, a[1] .. ': no frame of SaftUI\'s on a plate')
	end
end)

test('ElvUI stands SaftUI down while its nameplates are on', function()
	local cases = {
		{ 'nameplates off', function() return { { private = { nameplates = { enable = false } } } } end, nil },
		{ 'nameplates on', function() return { { private = { nameplates = { enable = true } } } } end, 'ElvUI' },
		{ 'its private table not set up', function() return { {} } end, 'ElvUI' },
		{ 'no nameplates table', function() return { { private = {} } } end, 'ElvUI' },
	}
	for _, case in ipairs(cases) do
		local st, UF = NP.world('forever')
		stub.loaded_addons.ElvUI = true
		ElvUI = case[2]()
		eq(UF:NameplateAddon(), case[3], case[1])
		eq(UF:SpawnNameplates(), case[3] == nil, case[1] .. (case[3] and ': stands down' or ': spawns'))
		eq(UF.plateDriver ~= nil, case[3] == nil, case[1] .. ': the driver')
	end
	-- Not loaded, its global left over: SaftUI draws.
	local st, UF = NP.world('forever')
	ElvUI = { { private = { nameplates = { enable = true } } } }
	eq(UF:NameplateAddon(), nil, 'ElvUI not loaded')
end)

------------------------------------------------------------------ the plates' frames

test("a plate's first add builds SaftUI's frame, kept in UF.nameplates by its number, not UF.allUnits", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = NP.world(client)
		UF:SpawnNameplates()
		local frame = NP.add('nameplate1')
		check(frame ~= nil, client .. ': a frame')
		eq(frame:GetName(), 'SaftUI_NamePlate1', client .. ': its name')
		eq(frame:GetParent(), NamePlate1, client .. ": the plate's child")
		eq(frame.ID, 1, client .. ': its plate number')
		eq(frame.base_unit, 'nameplate', client .. ': its config unit')
		eq(frame.config, UF:GetProfileConfig().nameplate, client .. ': its config')
		eq(UF.nameplates[1], frame, client .. ': kept by its number')
		eq(UF.allUnits.nameplate1, nil, client .. ': not among the units')
		eq(next(UF.allUnits), nil, client .. ': nothing there')
		eq(UF:GetMoverFrame('nameplate'), nil, client .. ': no mover')

		local second = NP.add('nameplate2')
		eq(second:GetName(), 'SaftUI_NamePlate2', client .. ': the second plate')
		eq(UF.nameplates[2], second, client .. ': kept by its number')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('a plate has health, name, castbar, buffs, debuffs, quest and raid target icons, the threat text, the subtext, and nothing else', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = NP.world(client)
		UF:SpawnNameplates()
		local frame = NP.add('nameplate1')
		local names = {}
		for name in pairs(frame.elements) do names[#names + 1] = name end
		table.sort(names)
		eq(table.concat(names, ','), 'Buffs,Castbar,Debuffs,Health,Name,QuestIndicator,RaidTargetIndicator,Subtext,Threat', client)
		eq(frame.Power, nil, client .. ': no power bar')
		eq(frame.GroupRoleIndicator, nil, client .. ': no group role')
		eq(frame.RaidRoleIndicator, nil, client .. ': no raid role')
	end
end)

-- Whether the game turns a frame's mouse on when it gets an OnEnter or
-- OnLeave script isn't modelled by the stubs (nor known): a plate's frame
-- simply gets neither, so it can't take the mouse over Blizzard's plate,
-- where a click targets the unit.
test("a plate's frame takes no mouse: no clicks registered, no OnEnter or OnLeave, in or out of combat", function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local frames = { NP.add('nameplate1') }
	stub.in_combat = true
	frames[2] = NP.add('nameplate2')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	for i, frame in ipairs(frames) do
		local what = i == 1 and 'out of combat' or 'made in combat'
		eq(frame:GetScript('OnEnter'), nil, what .. ': no OnEnter')
		eq(frame:GetScript('OnLeave'), nil, what .. ': no OnLeave')
		eq(stub.state(frame).click_buttons, nil, what .. ': no clicks registered')
		eq(frame:IsMouseEnabled(), false, what .. ': the mouse off, as oUF left it')
	end

	-- Other units still get them.
	local target = NP.ouf:Spawn('target', 'SaftUI_Target')
	eq(target:GetScript('OnEnter'), UF.OnEnter, "a unit frame's OnEnter")
	eq(stub.state(target).click_buttons and stub.state(target).click_buttons[1], 'AnyUp', "a unit frame's clicks")
end)

test('Power, Group role and Raid role are for every unit but the plates', function()
	local st, UF = NP.world('forever')
	for _, name in ipairs({ 'Power', 'GroupRoleIndicator', 'RaidRoleIndicator' }) do
		local valid = UF.elements[name].ValidUnit
		check(valid and not valid('nameplate'), name .. ': not on a plate')
		for _, unit in ipairs({ 'player', 'target', 'party', 'raid40', 'boss' }) do
			check(valid and valid(unit), name .. ': ' .. unit)
		end
	end
end)

-- Runs fn with UF:UpdateUnitFrame watched: returns, for each call, the frame,
-- whether oUF had initialized it then, and the element it was for.
local function watch_updates(UF, fn)
	local seen = {}
	local real = UF.UpdateUnitFrame
	UF.UpdateUnitFrame = function(self, frame, element)
		seen[#seen + 1] = { frame = frame, init = NP.ouf.IsInitialized(frame), element = element }
		return real(self, frame, element)
	end
	local ok, err = pcall(fn)
	UF.UpdateUnitFrame = real
	assert(ok, err)
	return seen
end

test('a plate is updated after its init, never from the style function', function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local frame
	local seen = watch_updates(UF, function() frame = NP.add('nameplate1') end)
	eq(#seen, 1, 'one update on the first add')
	eq(seen[1] and seen[1].frame, frame, 'of its frame')
	eq(seen[1] and seen[1].init, true, "after oUF's init")
	eq(seen[1] and seen[1].element, nil, 'a full update')
	eq(frame:IsElementEnabled('Health'), true, 'its elements enabled')

	NP.remove('nameplate1')
	seen = watch_updates(UF, function() NP.add('nameplate2', { plate = 1 }) end)
	eq(#seen, 0, 'no full update when the plate comes back')
end)

test('a plate made in combat is updated at once, and not again after combat', function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	stub.in_combat = true
	local frame
	local seen = watch_updates(UF, function() frame = NP.add('nameplate1') end)
	eq(#seen, 1, 'updated in combat: nothing on a plate is secure')
	stub.in_combat = false
	seen = watch_updates(UF, function() stub.fire_event('PLAYER_REGEN_ENABLED') end)
	eq(#seen, 0, 'nothing waits for the end of combat')
	eq(#stub.blocked, 0, 'nothing blocked')
end)

test('the plate callbacks: added with the unit, removed with it, updated after each update', function()
	local st, UF = NP.world('forever')
	local log = {}
	UF:RegisterPlateCallback('added', function(frame, unit) log[#log + 1] = 'added ' .. frame:GetName() .. ' ' .. unit end)
	UF:RegisterPlateCallback('removed', function(frame, unit) log[#log + 1] = 'removed ' .. frame:GetName() .. ' ' .. unit end)
	UF:RegisterPlateCallback('updated', function(frame, extra) log[#log + 1] = 'updated ' .. frame:GetName() .. ' ' .. tostring(extra) end)
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	eq(table.concat(log, '; '), 'updated SaftUI_NamePlate1 nil; added SaftUI_NamePlate1 nameplate1', 'the first add: its update, then added')
	eq(UF:PlateForUnit('nameplate1'), frame, 'found by its unit')
	eq(UF:PlateForUnit('nameplate2'), nil, 'not another')

	log = {}
	UF:UpdateUnitFrame(frame, 'Health')
	UF:UpdateUnitFrame(frame)
	eq(table.concat(log, '; '), 'updated SaftUI_NamePlate1 nil; updated SaftUI_NamePlate1 nil', 'after an element update and a full one')

	log = {}
	NP.remove('nameplate1')
	eq(table.concat(log, '; '), 'removed SaftUI_NamePlate1 nameplate1', 'removed')
	eq(UF:PlateForUnit('nameplate1'), nil, 'gone from its unit')

	-- An error in one callback is reported and the next still runs.
	UF:RegisterPlateCallback('added', function() error('a broken callback') end)
	UF:RegisterPlateCallback('added', function(_, unit) log[#log + 1] = 'after ' .. unit end)
	log = {}
	NP.add('nameplate2', { plate = 1 })
	eq(#take_errors(), 1, 'the error reported')
	eq(log[#log], 'after nameplate2', 'the next callback ran')
end)

test('a plate showing only widgets, a game object and a forbidden plate get no added callback', function()
	local st, UF = NP.world('forever')
	local added = {}
	UF:RegisterPlateCallback('added', function(frame, unit) added[#added + 1] = unit end)
	UF:SpawnNameplates()
	local widgets = NP.add('nameplate1', { widgets_only = true })
	check(widgets ~= nil, 'a frame is still built on the plate')
	eq(widgets:IsShown(), false, 'hidden')
	local object = NP.add('nameplate2', { game_object = true })
	eq(object:IsShown(), false, 'hidden')
	eq(NP.add('nameplate3', { forbidden = true }), nil, 'nothing on a forbidden plate')
	eq(UF.nameplates[3], nil, 'none kept for it')
	eq(#added, 0, 'no added callback')
	eq(UF:PlateForUnit('nameplate1'), nil, 'not found by its unit')
	eq(UF:PlateForUnit('nameplate2'), nil, 'nor the game object')
	eq(#take_errors(), 0, 'no error')
end)

test('a removed plate runs the removed callbacks and keeps its frame for the next add', function()
	local st, UF = NP.world('forever')
	local got = {}
	UF:RegisterPlateCallback('removed', function(frame, unit) got[#got + 1] = { frame, unit } end)
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	NP.remove('nameplate1')
	eq(#got, 1, 'one removed callback')
	eq(got[1] and got[1][1], frame, 'with the frame')
	eq(got[1] and got[1][2], 'nameplate1', 'and the unit')
	-- oUF's remove clears only the unit attribute, which its handler ignores
	-- when nil, so __unit keeps the unit that left. SaftUI finds a plate by its
	-- unit only while the plate shows it.
	eq(frame.__unit, 'nameplate1', "oUF's __unit, kept")
	eq(UF:PlateForUnit('nameplate1'), nil, 'no plate for the unit that left')

	local again = NP.add('nameplate2', { plate = 1 })
	eq(again, frame, 'the same frame for the next unit on the plate')
	eq(UF.nameplates[1], frame, 'still kept by its number')
	eq(UF:PlateForUnit('nameplate2'), frame, 'found by the new unit')
	eq(frame.__unit, 'nameplate2', 'its new unit')
	local count = 0
	UF:ForEachPlate(function() count = count + 1 end)
	eq(count, 1, 'still one plate frame')
end)

------------------------------------------------------------------ the size

test('the plate size is set again after Blizzard sets its own, and waits for the end of combat', function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local size = driver_size(UF, 200, 20)
	NamePlateDriverFrame:UpdateNamePlateSize()
	eq(size_set(), size, "SaftUI's again")
	stub.in_combat = true
	NamePlateDriverFrame:UpdateNamePlateSize()
	eq(size_set(), '230x45', "Blizzard's until combat ends")
	eq(#stub.blocked, 0, 'SaftUI waited')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(size_set(), size, "SaftUI's once combat ends")
	eq(#take_errors(), 0, 'no error')
end)

test('a size oUF refuses at spawn is reported, and the hook still goes in', function()
	local st, UF = NP.world('forever')
	local P = UF:GetProfileConfig().nameplate
	P.width = 'wide' -- not a number: oUF's SetSize argument check raises
	local before = rawget(NamePlateDriverFrame, 'UpdateNamePlateSize')
	check(UF:SpawnNameplates(), 'spawned')
	eq(#take_errors(), 1, 'the size error reported')
	check(rawget(NamePlateDriverFrame, 'UpdateNamePlateSize') ~= before, 'hooked')
	P.width = 200
	NamePlateDriverFrame:UpdateNamePlateSize()
	eq(size_set(), driver_size(UF, 200, 20), "SaftUI's size after Blizzard's, once the config is right")
end)

test("a size change reaches the plates through the nameplate's config update", function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	local P = UF:GetProfileConfig().nameplate
	P.width, P.height = 180, 16
	UF:UpdateConfig('nameplate')
	eq(size_set(), driver_size(UF, 180, 16), 'the new size')
	-- On screen (a size times its effective scale): the frame keeps UIParent's
	-- scale and its plate WorldFrame's (pixels.lua), so their own units differ.
	local function onScreen(region)
		local width, height = region:GetSize()
		local scale = region:GetEffectiveScale()
		return ('%.4fx%.4f'):format(width * scale, height * scale)
	end
	eq(onScreen(frame), onScreen(NamePlate1), "the frame follows its plate's size")
	eq(table.concat({ NamePlate1:GetSize() }, 'x'), size_set(), 'the plate takes the size set')
	-- An element's update leaves the size alone.
	stub.set_nameplate_size_secure(230, 45)
	UF:UpdateConfig('nameplate', 'Health')
	eq(size_set(), '230x45', 'not set for an element')
	UF:UpdateConfig()
	eq(size_set(), driver_size(UF, 180, 16), 'set by a full update')
end)

------------------------------------------------------------------ config changes

test('config changes reach the plates', function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')

	local visited = {}
	UF:ForEachUnitFrame(function(frame) visited[frame] = (visited[frame] or 0) + 1 end)
	eq(visited[one], 1, 'ForEachUnitFrame visits plate 1')
	eq(visited[two], 1, 'and plate 2')
	visited = {}
	UF:ForEachPlate(function(frame) visited[frame] = (visited[frame] or 0) + 1 end)
	eq(visited[one], 1, 'ForEachPlate visits plate 1')
	eq(visited[two], 1, 'and plate 2')

	-- Health's UpdateConfig, watched.
	local health = UF.elements.Health
	local real = health.UpdateConfig
	local ran = {}
	health.UpdateConfig = function(frame, ...)
		ran[frame] = (ran[frame] or 0) + 1
		return real(frame, ...)
	end
	UF:UpdateConfig('nameplate', 'Health')
	eq(ran[one], 1, "an element's update reaches plate 1")
	eq(ran[two], 1, 'and plate 2')
	ran = {}
	UF:UpdateConfig()
	health.UpdateConfig = real
	eq(ran[one], 1, 'a full update reaches plate 1')
	eq(ran[two], 1, 'and plate 2')

	-- Their points are oUF's: all of the plate.
	for i, frame in ipairs({ one, two }) do
		local plate = _G['NamePlate' .. i]
		eq(frame:GetNumPoints(), 2, 'plate ' .. i .. ': two points')
		for p = 1, frame:GetNumPoints() do
			local point, relativeTo, relativePoint, x, y = frame:GetPoint(p)
			eq(relativeTo, plate, 'plate ' .. i .. ': on its plate')
			eq(point, relativePoint, 'plate ' .. i .. ': ' .. point .. ' to the same point')
			check(x == 0 and y == 0, 'plate ' .. i .. ': no offset')
		end
	end

	-- A profile switch re-points each plate's cached config.
	local P2 = st.config.profile.unitframes.profiles.Other
	st.config.profile.unitframes.config_profile = 'Other'
	UF:RefreshConfigReferences()
	for i, frame in ipairs({ one, two }) do
		eq(frame.config, P2.nameplate, 'plate ' .. i .. ": the new profile's config")
		eq(frame.Health.config, P2.nameplate.health, 'plate ' .. i .. ": its health's too")
	end
	eq(#take_errors(), 0, 'no error')
end)

test('a purge filter refresh reaches a plate', function()
	local st, UF = NP.world('forever')
	local buffs = UF:GetProfileConfig().nameplate.buffs
	buffs.enable = true
	buffs.purgeable = true
	stub.class = 'SHAMAN'
	stub.known_spells = {}
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	local group = frame.Buffs.groups[frame.Buffs.groupKey]
	check(group ~= nil, 'the buffs have their group')
	eq(group and group.filter, 'HELPFUL', 'no purge spell yet')

	stub.known_spells[370] = true -- Purge
	stub.fire_event('SPELLS_CHANGED')
	eq(group and group.filter, 'HELPFUL|RAID_PLAYER_DISPELLABLE', 'Purge learned: the plate follows')
end)

------------------------------------------------------------------ paused plates

test("a paused plate's update leaves UNIT_FACTION off, and oUF's resume turns it on again", function()
	local st, UF = NP.world('forever')
	local health = UF:GetProfileConfig().nameplate.health
	check(health.colorTapping or health.colorReaction, "a plate's health has a faction flag on by default")
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	eq(frame:IsEventRegistered('UNIT_FACTION'), true, 'registered by its first update')

	NP.remove('nameplate1')
	NP.add('nameplate2', { plate = 1, widgets_only = true })
	eq(frame:IsElementPaused('Health'), true, 'its health paused')
	eq(frame:IsEventRegistered('UNIT_FACTION'), false, "dropped by oUF's pause")
	UF:UpdateConfig('nameplate')
	eq(frame:IsEventRegistered('UNIT_FACTION'), false, 'still off after an update')
	eq(frame.Health.colorReaction, health.colorReaction, 'the flag is set')

	NP.remove('nameplate2')
	eq(frame:IsElementPaused('Health'), nil, 'resumed')
	eq(frame:IsEventRegistered('UNIT_FACTION'), true, "registered again by oUF's resume, from the flags")
end)

test('a disabled bar keeps its colour flags as plain fields', function()
	local st, UF = NP.world('forever')
	UF:SpawnNameplates()
	local frame = NP.add('nameplate1')
	frame:DisableElement('Health')
	eq(frame:IsEventRegistered('UNIT_FACTION'), false, "dropped by oUF's Disable")
	UF:UpdateUnitFrame(frame)
	eq(frame:IsEventRegistered('UNIT_FACTION'), false, 'still off after an update')
	eq(frame.Health.colorReaction, UF:GetProfileConfig().nameplate.health.colorReaction, 'the flag is set')
end)

------------------------------------------------------------------ Blizzard's frames

test("nothing is written onto Blizzard's plate frames", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = NP.world(client)
		UF:SpawnNameplates()
		local frame = NP.add('nameplate1')
		NP.add('nameplate2', { widgets_only = true })
		NP.add('nameplate3', { forbidden = true })
		NP.remove('nameplate1')
		NP.add('nameplate4', { plate = 1 })
		stub.nameplate_target = 'nameplate4'
		stub.fire_event('PLAYER_TARGET_CHANGED')
		NamePlateDriverFrame:UpdateNamePlateSize()
		-- Blizzard's options update and a change of the friendly NPC plates
		-- setting, after which SaftUI puts the click areas back.
		NamePlateDriverFrame:UpdateNamePlateOptions()
		stub.set_cvar_secure('nameplateShowFriendlyNpcs', '1')
		stub.run_timers()
		UF:UpdateConfig()
		NP.remove('nameplate2')
		NP.remove('nameplate3')
		eq(#take_errors(), 0, client .. ': no error from the locked frames')
		-- oUF's own writes onto the plate, with rawset.
		eq(rawget(NamePlate1, 'unitFrame'), frame, client .. ": oUF's unitFrame")
	end
end)
