-- What a unit frame profile switch (UF:UpdateConfig, which every switch,
-- copy and reset runs) applies (SaftUI-Unitframes/unitframes.lua's
-- UF:ApplyConfig):
--   - the game's friendly plate settings follow the new profile's Friendly
--     plates, out of combat at once and after combat otherwise;
--   - a unit frame's parts are placed afresh, so two parts anchored each way
--     round across two profiles place with no anchor loop.
--
-- The world is nameplate_world.lua's (see its top).
local NP = load_test_file('unitframes/nameplate_world.lua')

local PLAYERS, NPCS = 'nameplateShowFriendlyPlayers', 'nameplateShowFriendlyNpcs'

local function world(client)
	local st, UF = NP.world(client or 'forever')
	st.config.char = {}
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	return st, UF
end

test("a profile switch sets the game's friendly plates to the new profile's", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local config = UF:GetProfileConfig()
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': on')

		-- The switch: the profile's table changes, then UF:UpdateConfig runs.
		config.nameplate.friendly = false
		UF:UpdateConfig()
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', client .. ': off with the new profile')

		config.nameplate.friendly = true
		stub.in_combat = true
		UF:UpdateConfig()
		eq(#stub.blocked, 0, client .. ': nothing tried in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': on again after combat')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ parts placed afresh

-- A single unit frame (the player) with two parts on it, built by the real
-- constructors, and registered as UF:OnEnable leaves one.
local UW = load_test_file('unitframes/uf_world.lua')
local function player_world()
	local st, UF = NP.world('forever')
	st.config.char = {}
	local P = UF:GetProfileConfig()
	local frame = UW.unit_frame('SaftUI_ProfilePlayer', 'player', { 'Health', 'Power' })
	frame.is_group_unit = nil
	UF.units.player = frame
	UF.allUnits.player = frame
	return st, UF, P, frame
end

-- Profile A: the power bar under the health bar. Profile B: the health bar
-- above the power bar (the other way round), the power bar on the frame.
local function profile_a(P)
	P.player.health.position = { point = 'TOP', element = '', rel_point = 'TOP', x_off = 0, y_off = 0 }
	P.player.power.position = { point = 'TOP', element = 'Health', rel_point = 'BOTTOM', x_off = 0, y_off = -2 }
end
local function profile_b(P)
	P.player.power.position = { point = 'BOTTOM', element = '', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
	P.player.health.position = { point = 'BOTTOM', element = 'Power', rel_point = 'TOP', x_off = 0, y_off = 2 }
end

local function anchored_to(region)
	local _, relativeTo = region:GetPoint(1)
	return relativeTo
end

test('a profile switch places a unit frame\'s parts against the new anchors, whichever way they were', function()
	local st, UF, P, frame = player_world()
	profile_a(P)
	UF:UpdateConfig()
	eq(#take_errors(), 0, 'profile A: no error')
	eq(anchored_to(frame.Power), frame.Health, 'A: the power bar under the health bar')
	check(frame.Health:GetNumPoints() == 1 and frame.Power:GetNumPoints() == 1, 'A: both placed')

	for round = 1, 2 do
		profile_b(P)
		UF:UpdateConfig()
		local errors = take_errors()
		eq(#errors, 0, 'switch ' .. round .. ' to B: no error ' .. tostring(errors[1]))
		eq(anchored_to(frame.Health), frame.Power, 'B: the health bar over the power bar')
		eq(anchored_to(frame.Power), frame, 'B: the power bar on the frame')
		check(frame.Health:GetNumPoints() == 1 and frame.Power:GetNumPoints() == 1, 'B: both placed')

		profile_a(P)
		UF:UpdateConfig()
		eq(#take_errors(), 0, 'switch ' .. round .. ' back to A: no error')
		eq(anchored_to(frame.Power), frame.Health, 'A: the power bar under the health bar')
		eq(anchored_to(frame.Health), frame, 'A: the health bar on the frame')
	end
end)

test('a profile switch in combat places no part', function()
	local st, UF, P, frame = player_world()
	profile_a(P)
	UF:UpdateConfig()
	stub.in_combat = true
	profile_b(P)
	UF:UpdateConfig()
	stub.in_combat = false
	eq(anchored_to(frame.Power), frame.Health, 'nothing moved in combat')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ plates

-- A plate whose config unit doesn't change on a switch (an enemy stays an
-- enemy) is placed afresh too: its parts lose their points first, so two parts
-- anchored each way round across two profiles place with no loop. Nothing
-- anchored to a plate is measured (the stubs refuse GetPoint on one).
test("a profile switch places an enemy plate's parts afresh, whichever way they were anchored", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local P = UF:GetProfileConfig().nameplate
		NP.enemy('nameplate1')
		local frame = NP.add('nameplate1')
		local function a()
			P.name.position = { point = 'CENTER', element = 'Health', rel_point = 'CENTER', x_off = 0, y_off = 0 }
			P.health.position = { point = 'CENTER', element = '', rel_point = 'CENTER', x_off = 0, y_off = 0 }
		end
		local function b()
			P.health.position = { point = 'TOP', element = 'Name', rel_point = 'BOTTOM', x_off = 0, y_off = -2 }
			P.name.position = { point = 'CENTER', element = '', rel_point = 'CENTER', x_off = 0, y_off = 0 }
		end
		a()
		UF:UpdateConfig()
		take_errors()
		for round = 1, 2 do
			b()
			UF:UpdateConfig()
			local errors = take_errors()
			eq(#errors, 0, client .. ': to B, round ' .. round .. ': no error ' .. tostring(errors[1]))
			eq(select(2, frame.Health:GetPoint(1)), frame.Name, client .. ': the bar under the name')
			a()
			UF:UpdateConfig()
			errors = take_errors()
			eq(#errors, 0, client .. ': back to A, round ' .. round .. ': no error ' .. tostring(errors[1]))
			eq(select(2, frame.Name:GetPoint(1)), frame.Health, client .. ': the name on the bar')
		end
	end
end)

------------------------------------------------------------------ boss frames and group buttons

-- A boss frame past the first, and a party header's button, are cleared like
-- the single frames. Errors that aren't an anchor loop (the group machinery
-- here is the bare stand-in's) are not what this checks.
local function loops(errors)
	local n = 0
	for _, e in ipairs(errors) do
		if tostring(e):find('dependent on it', 1, true) then n = n + 1 end
	end
	return n
end

test('a profile switch places boss frames and a group header\'s buttons against the new anchors', function()
	local st, UF = NP.world('forever')
	st.config.char = {}
	local P = UF:GetProfileConfig()
	local boss1 = UW.unit_frame('SaftUI_ProfileBoss1', 'boss', { 'Health', 'Power' })
	local boss2 = UW.unit_frame('SaftUI_ProfileBoss2', 'boss', { 'Health', 'Power' })
	boss1.ID, boss2.ID = 1, 2
	UF.units.boss = { boss1, boss2 }
	local header = CreateFrame('Frame', 'SaftUI_ProfileParty', UIParent)
	local button = UW.unit_frame('SaftUI_ProfilePartyButton', 'party', { 'Health', 'Power' }, header)
	button.is_group_unit = true
	UF.groups = { party = header }
	UF.holders = UF.holders or {}

	local function a(unit)
		P[unit].health.position = { point = 'TOP', element = '', rel_point = 'TOP', x_off = 0, y_off = 0 }
		P[unit].power.position = { point = 'TOP', element = 'Health', rel_point = 'BOTTOM', x_off = 0, y_off = -2 }
	end
	local function b(unit)
		P[unit].power.position = { point = 'BOTTOM', element = '', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		P[unit].health.position = { point = 'BOTTOM', element = 'Power', rel_point = 'TOP', x_off = 0, y_off = 2 }
	end
	for _, case in ipairs({ { 'boss', boss2 }, { 'party', button } }) do
		local unit, frame = case[1], case[2]
		P[unit].enable, P[unit].health.enable, P[unit].power.enable = true, true, true
		a(unit)
		UF:UpdateConfig()
		take_errors()
		for round = 1, 2 do
			b(unit)
			UF:UpdateConfig()
			eq(loops(take_errors()), 0, unit .. ': to B, round ' .. round .. ': no anchor loop')
			eq(select(2, frame.Health:GetPoint(1)), frame.Power, unit .. ': the health bar over the power bar')
			a(unit)
			UF:UpdateConfig()
			local errors = take_errors()
			eq(loops(errors), 0, unit .. ': back to A, round ' .. round .. ': no anchor loop ' .. tostring(errors[1]))
			eq(select(2, frame.Power:GetPoint(1)), frame.Health, unit .. ': the power bar under the health bar')
		end
	end
end)
