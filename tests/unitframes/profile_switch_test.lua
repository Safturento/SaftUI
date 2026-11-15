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
