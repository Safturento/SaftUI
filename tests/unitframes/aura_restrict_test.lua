-- Blizzard's aura container restricts each aura button once it's made: while
-- aura data is secret (in combat), addon code can't touch the button or
-- anything on it, SaftUI's backdrop included (.agents/taint.md rule 11). The
-- buttons are styled as they're made (PostCreateButton, before the
-- restriction), so SaftUI styles them again on a config update only while
-- aura data isn't secret, and in combat waits for the end of combat
-- (SaftUI-Unitframes/elements/auras.lua).
--
-- A frame made in combat gets its first config update then (UF.InitUnit): a
-- plate's on its first add, a group member's when they join. In game that
-- update errored on the buttons its container had just made, which stopped
-- the frame's update there, so a plate's threat text was left with no font
-- and every threat event after it errored ("Font not set").
--
-- The world is nameplate_world.lua's, with the oUF stand-in's containers made
-- as Blizzard's are: a batch of buttons for a group (ouf.batchButtons) and
-- each restricted after PostCreateButton (ouf.restrictButtons). The aura
-- secrecy is tests/wow/game.lua's: C_Secrets.ShouldAurasBeSecret() is
-- InCombatLockdown().
local NP = load_test_file('unitframes/nameplate_world.lua')

local CLIENTS = { 'forever', 'retail' }

local function world(client)
	local st, UF = NP.world(client)
	NP.ouf.batchButtons = 2
	NP.ouf.restrictButtons = true
	UF:SpawnNameplates()
	stub.role = 'DAMAGER'
	stub.group = { members = { 'party1' } }
	stub.units.party1 = { name = 'Friend', player = true, friend = true, role = 'DAMAGER' }
	return st, UF
end

local function add_enemy(unit, status)
	stub.units[unit] = { name = unit, friend = false, attackable = true, reaction = 2 }
	stub.threat[unit] = { player = status }
	return NP.add(unit)
end

-- Every button the frame's aura areas have, by its backdrop's draws.
local function buttons(frame)
	local list = {}
	for _, auras in ipairs({ frame.Buffs, frame.Debuffs }) do
		for _, child in ipairs({ auras:GetChildren() }) do list[#list + 1] = child end
	end
	return list
end

for _, client in ipairs(CLIENTS) do
	test(client .. ': a plate first added in combat gets its whole update, with no error', function()
		local st, UF = world(client)
		stub.in_combat = true
		local frame = add_enemy('nameplate1', 0)
		eq(#take_errors(), 0, 'no error from the update')
		check(#buttons(frame) > 0, 'its aura areas have buttons')
		check(frame.Threat:GetFont() ~= nil, 'its threat text has its font')
		stub.fire_event('UNIT_THREAT_LIST_UPDATE', 'nameplate1')
		eq(#take_errors(), 0, 'no error from a threat update')
		check(frame.Threat:IsShown(), 'the threat text shows')
	end)

	test(client .. ': its buttons are styled again once combat ends', function()
		local st, UF = world(client)
		stub.in_combat = true
		local frame = add_enemy('nameplate1', 0)
		local made = buttons(frame)
		local styled = {}
		local setBackdrop = st.SetBackdrop
		st.SetBackdrop = function(self, f, ...)
			styled[f] = true
			return setBackdrop(self, f, ...)
		end
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		st.SetBackdrop = setBackdrop
		eq(#take_errors(), 0, 'no error')
		for i, button in ipairs(made) do
			check(styled[button], 'button ' .. i .. ' styled again')
		end
	end)

	test(client .. ': out of combat a config update styles the buttons at once', function()
		local st, UF = world(client)
		local frame = add_enemy('nameplate1', 0)
		local made = buttons(frame)
		local styled = {}
		local setBackdrop = st.SetBackdrop
		st.SetBackdrop = function(self, f, ...)
			styled[f] = true
			return setBackdrop(self, f, ...)
		end
		UF:UpdateUnitFrame(frame)
		st.SetBackdrop = setBackdrop
		eq(#take_errors(), 0, 'no error')
		for i, button in ipairs(made) do
			check(styled[button], 'button ' .. i .. ' styled')
		end
	end)
end
