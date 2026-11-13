-- A plate's click area (its hit-test points) is SaftUI's frame on the plate
-- (SaftUI-Unitframes/nameplates/nameplates.lua, ruling N11):
--   - oUF sets it on every add (ClearAllHitTestPoints, then
--     SetAllHitTestPoints with the frame);
--   - Blizzard's pooled UnitFrame sets its own again outside the add: on its
--     driver's options update (UpdateNamePlateOptions: a window resize, the
--     options loading, a Blizzard nameplate option), and from its callbacks on
--     the friendly NPC plates setting and on showing only friendly players'
--     names. SaftUI runs oUF's two calls again after each, for every plate
--     showing its unit: from a post-hook on the options update, at the end of
--     UF:RefreshPlateWidgets (after SaftUI sets the game's plate settings),
--     and on the next frame after either setting changes (whoever changed it);
--   - in combat the game lets addon code change the click area only on a tick
--     Blizzard's own code changed it (or the plate got its unit), so the
--     options update's hook goes through, and the next frame's waits for the
--     end of combat;
--   - a plate the game took away, or one showing only widgets, is left alone;
--     with Nameplates off or another nameplate addon, nothing is hooked or
--     registered.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), with Blizzard's plate frames locked. The
-- plates' click area, CVarCallbackRegistry, NamePlateDriverFrame's options
-- update and the ticks are tests/wow/game.lua's and blizzard.lua's.
local NP = load_test_file('unitframes/nameplate_world.lua')

local CLIENTS = { 'forever', 'retail' }
local NPCS = 'nameplateShowFriendlyNpcs'
local NAMES = 'nameplateShowOnlyNameForFriendlyPlayerUnits'

local enemy = NP.enemy

-- What a plate's click area covers: the one region every anchor is on, 'none'
-- for no anchors, 'mixed' for anchors on different regions.
local function clicks(plate)
	local points = plate:GetHitTestPoints()
	if #points == 0 then return 'none' end
	local region = points[1].relativeTo
	for _, a in ipairs(points) do
		if a.relativeTo ~= region then return 'mixed' end
	end
	return region
end

-- Blizzard's pooled UnitFrame on a plate, which its own click area is on.
local function blizzard(plate) return rawget(plate, 'UnitFrame') end

-- A world with the plates spawned and three plates: two enemies (SaftUI's
-- frames one and two) and one showing only widgets, on NamePlate1 to 3.
-- st.config.char is AceDB's per-character table, which the shell doesn't
-- have: {} for each world, as for a new character.
local function world(client)
	local st, UF = NP.world(client)
	st.config.char = {}
	UF:SpawnNameplates()
	enemy('nameplate1')
	enemy('nameplate2')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	NP.add('nameplate3', { widgets_only = true })
	return st, UF, one, two
end

------------------------------------------------------------------ the stubs

test("the stubs: oUF's click area on the add, Blizzard's after its options update; addon code changes it in combat only on such a tick", function()
	local st, UF, one = world('forever')
	eq(clicks(NamePlate1), one, "oUF's on the add")
	eq(clicks(NamePlate3), 'none', 'a widget-only plate: none (Blizzard cleared it, oUF set nothing)')

	-- Blizzard's own update, untainted: its area, in combat too.
	UF.RestorePlateHitTests = function() end -- SaftUI's restore left out, to see Blizzard's
	stub.in_combat = true
	NamePlateDriverFrame:UpdateNamePlateOptions()
	eq(clicks(NamePlate1), blizzard(NamePlate1), "Blizzard's area")
	eq(NamePlate1:CanChangeHitTestPoints(), true, 'addon code may change it on the same tick')
	stub.run_timers()
	eq(NamePlate1:CanChangeHitTestPoints(), false, 'not on the next, in combat')
	local ok, err = pcall(NamePlate1.ClearAllHitTestPoints, NamePlate1)
	check(not ok and tostring(err):find('CanChangeHitTestPoints', 1, true), 'a guarded call errors then: ' .. tostring(err))
	eq(clicks(NamePlate1), blizzard(NamePlate1), 'and changes nothing')
	stub.in_combat = false
	eq(NamePlate1:CanChangeHitTestPoints(), true, 'out of combat it may')

	-- A setting change runs CVarCallbackRegistry's callbacks, the plates'
	-- UnitFrames' among them.
	stub.cvars[NAMES] = '0'
	NamePlate1:SetAllHitTestPoints(one)
	stub.set_cvar_secure(NAMES, '1')
	eq(clicks(NamePlate1), blizzard(NamePlate1), "the show-only-names callback: Blizzard's area")
	NamePlate1:SetAllHitTestPoints(one)
	stub.set_cvar_secure(NPCS, '1')
	eq(clicks(NamePlate1), blizzard(NamePlate1), "the friendly NPC callback: Blizzard's area")
	NP.remove('nameplate1')
	NamePlate1:SetAllHitTestPoints(one)
	stub.set_cvar_secure(NPCS, '0')
	eq(clicks(NamePlate1), one, "a plate taken away: its UnitFrame's callbacks are gone")
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ Blizzard's options update

for _, client in ipairs(CLIENTS) do
	test(client .. ": after Blizzard's options update every plate showing its unit clicks as SaftUI's frame again", function()
		local st, UF, one, two = world(client)
		NamePlateDriverFrame:UpdateNamePlateOptions()
		eq(clicks(NamePlate1), one, 'plate 1: its frame')
		eq(clicks(NamePlate2), two, 'plate 2: its frame')
		eq(clicks(NamePlate3), 'none', "a widget-only plate keeps Blizzard's (none)")
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ': in combat (a window resize mid-fight) the click area comes back on the same tick, with no error', function()
		local st, UF, one, two = world(client)
		stub.in_combat = true
		stub.run_timers() -- a later tick than the adds
		NamePlateDriverFrame:UpdateNamePlateOptions()
		eq(clicks(NamePlate1), one, 'plate 1: its frame')
		eq(clicks(NamePlate2), two, 'plate 2: its frame')
		eq(#take_errors(), 0, 'no error: the game allows it on the tick Blizzard changed it')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(clicks(NamePlate1), one, 'still its frame after combat')
	end)
end

------------------------------------------------------------------ the game's plate settings

for _, client in ipairs(CLIENTS) do
	test(client .. ': Friendly plates turned off and on: the click area is SaftUI\'s frame at once after each', function()
		local st, UF, one, two = world(client)
		local P = UF:GetProfileConfig().nameplate
		for _, friendly in ipairs({ false, true, false }) do
			P.friendly = friendly
			UF:ApplyNameplateCVars()
			eq(stub.cvars[NPCS], friendly and '1' or '0', 'the setting changed')
			eq(clicks(NamePlate1), one, ('friendly %s: plate 1, its frame'):format(tostring(friendly)))
			eq(clicks(NamePlate2), two, ('friendly %s: plate 2, its frame'):format(tostring(friendly)))
		end
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ": the friendly NPC setting changed elsewhere (Blizzard's key binding): SaftUI's click area on the next frame", function()
		local st, UF, one, two = world(client)
		stub.set_cvar_secure(NPCS, '1')
		eq(clicks(NamePlate1), blizzard(NamePlate1), "Blizzard's own callback ran after SaftUI's")
		stub.run_timers()
		eq(clicks(NamePlate1), one, 'the next frame: plate 1, its frame')
		eq(clicks(NamePlate2), two, 'plate 2, its frame')
		eq(clicks(NamePlate3), 'none', 'the widget-only plate left alone')

		stub.set_cvar_secure(NPCS, '0')
		stub.set_cvar_secure(NPCS, '1')
		eq(#stub.timers, 1, 'two changes in one frame wait once')
		stub.run_timers()
		eq(clicks(NamePlate1), one, 'its frame again')

		-- Blizzard's option to show only the names of friendly players resets
		-- it too.
		stub.cvars[NAMES] = '0'
		stub.set_cvar_secure(NAMES, '1')
		stub.run_timers()
		eq(clicks(NamePlate1), one, 'after the show-only-names setting too')
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ': the friendly NPC setting changed in combat: the click area waits for the end of combat, with no error', function()
		local st, UF, one = world(client)
		stub.in_combat = true
		stub.set_cvar_secure(NPCS, '1')
		stub.run_timers()
		eq(#take_errors(), 0, 'no error: the game refuses the change on the next frame, and SaftUI asks first')
		eq(clicks(NamePlate1), blizzard(NamePlate1), "Blizzard's until combat ends")
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(clicks(NamePlate1), one, 'its frame once combat ends')
	end)
end

------------------------------------------------------------------ what's left alone

test('a plate the game took away, or never gave SaftUI, is left alone', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, one = world(client)
		NP.add('nameplate4', { forbidden = true })
		NP.remove('nameplate1')
		local touched = 0
		for _, plate in ipairs({ NamePlate1, NamePlate4 }) do
			for _, method in ipairs({ 'ClearAllHitTestPoints', 'SetAllHitTestPoints', 'SetHitTestPoints' }) do
				local real = plate[method]
				rawset(plate, method, function(...) touched = touched + 1 return real(...) end)
			end
		end
		NamePlateDriverFrame:UpdateNamePlateOptions()
		UF:RefreshPlateWidgets()
		stub.set_cvar_secure(NPCS, '1')
		stub.run_timers()
		eq(touched, 0, client .. ': nothing called on the plate taken away, or on the forbidden one')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('Nameplates off, or another nameplate addon: no hook on the options update and no setting callback', function()
	for _, case in ipairs({ 'off', 'Plater' }) do
		local st, UF = NP.world('forever')
		if case == 'off' then
			UF:GetProfileConfig().nameplate.enable = false
		else
			stub.loaded_addons.Plater = true
		end
		local before = rawget(NamePlateDriverFrame, 'UpdateNamePlateOptions')
		UF:SpawnNameplates()
		eq(rawget(NamePlateDriverFrame, 'UpdateNamePlateOptions'), before, case .. ': not hooked')
		stub.set_cvar_secure(NPCS, '1')
		eq(#stub.timers, 0, case .. ': nothing waits on the setting')
	end
end)

test('a client without the options update, the setting registry or the hit-test check does nothing and nothing errors', function()
	local st, UF = NP.world('forever')
	rawset(NamePlateDriverFrame, 'UpdateNamePlateOptions', nil)
	CVarCallbackRegistry = nil
	check(UF:SpawnNameplates(), 'spawned')
	enemy('nameplate1')
	local one = NP.add('nameplate1')
	rawset(NamePlate1, 'CanChangeHitTestPoints', nil)
	UF:RefreshPlateWidgets()
	eq(clicks(NamePlate1), one, 'its frame')
	eq(#take_errors(), 0, 'no error')
end)

-- The game's same-tick exception for Blizzard's own change isn't documented
-- to stay open after SaftUI's first call: the second is asked for again, and a
-- refusal then waits for the end of combat instead of erroring.
test('in combat, a plate that refuses the second call waits for the end of combat, with no error', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, one = world(client)
		local asked = 0
		rawset(NamePlate1, 'CanChangeHitTestPoints', function()
			asked = asked + 1
			return asked == 1 or not InCombatLockdown()
		end)
		local clear = NamePlate1.ClearAllHitTestPoints
		rawset(NamePlate1, 'ClearAllHitTestPoints', function(self)
			local was = stub.in_combat
			stub.in_combat = false
			clear(self)
			stub.in_combat = was
		end)
		stub.run_timers() -- the next frame: the add's tick is over
		stub.in_combat = true
		UF:RestorePlateHitTests()
		eq(#take_errors(), 0, client .. ': no error')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(clicks(NamePlate1), one, client .. ': its frame once combat ends')
		eq(#take_errors(), 0, client .. ': and no error then')
	end
end)
