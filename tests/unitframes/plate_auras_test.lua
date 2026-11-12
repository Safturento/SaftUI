-- A plate's aura areas take the config its kind draws from in full, their
-- buttons' size and count too (SaftUI-Unitframes/elements/auras.lua). An aura
-- area's group is built once, on its frame's first update with the area on,
-- and a plate's frame is always first updated from Enemy nameplates (its unit
-- token's config, 'nameplate'). So a config update, a kind change among them,
-- sets the group's count through the container (SetAuraGroupMaxFrameCount,
-- in combat too), and sizes the buttons as it restyles them: at once out of
-- combat, at the end of combat in it, since Blizzard's container restricts
-- its buttons while aura data is secret (.agents/taint.md rule 11). The aura
-- tabs no longer ask for a reload for Size, Relative size and Max.
--
-- The world is nameplate_world.lua's, with the oUF stand-in's containers made
-- as Blizzard's are: a batch of buttons for a group (ouf.batchButtons) and
-- each restricted after PostCreateButton (ouf.restrictButtons). The aura
-- secrecy is tests/wow/game.lua's: C_Secrets.ShouldAurasBeSecret() is
-- InCombatLockdown(). The stand-in doesn't lay buttons out: a layout asked for
-- is recorded (SetAuraGroupLayout).
local NP = load_test_file('unitframes/nameplate_world.lua')

-- A world with the plates spawned, the Friendly page's debuffs on at their
-- own size and count: 30 and 2, where the Enemy page's are 20 and 6.
local function world(client)
	local st, UF = NP.world(client)
	NP.ouf.batchButtons = 3
	NP.ouf.restrictButtons = true
	UF:SpawnNameplates()
	local P = UF:GetProfileConfig()
	P.friendlynameplate.debuffs.enable = true
	P.friendlynameplate.debuffs.size = 30
	P.friendlynameplate.debuffs.max = 2
	return st, UF, P
end

local function enemy(unit) stub.units[unit] = { name = unit, friend = false, attackable = true, reaction = 2 } end
local function friend(unit) stub.units[unit] = { name = unit, friend = true, attackable = false, reaction = 5 } end

-- An aura area's group (its one group).
local function group(auras)
	local _, g = next(auras.groups)
	return g
end

-- Every button the area has, and their sizes as 'W x H, ...'. Read only while
-- aura data isn't secret: the buttons refuse every call while it is.
local function buttons(auras) return { auras:GetChildren() } end
local function sizes(auras)
	local list = {}
	for _, button in ipairs(buttons(auras)) do
		list[#list + 1] = ('%dx%d'):format(button:GetWidth(), button:GetHeight())
	end
	return table.concat(list, ', ')
end
local function all(size, count)
	local list = {}
	for i = 1, count do list[i] = ('%dx%d'):format(size, size) end
	return table.concat(list, ', ')
end

-- A plate whose frame was first updated from the Enemy page: its group built
-- at the enemy's size and count, with the stand-in's batch of 3 buttons.
local function enemy_plate(UF)
	enemy('nameplate1')
	local frame = NP.add('nameplate1')
	eq(group(frame.Debuffs).options.size, 20, "the group was built at the Enemy page's size")
	eq(group(frame.Debuffs).maxFrameCount, 6, "and count")
	NP.remove('nameplate1')
	return frame
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": the Friendly page's debuff size and count apply to a friend's plate first built for an enemy", function()
		local st, UF, P = world(client)
		local frame = enemy_plate(UF)
		friend('nameplate2')
		eq(NP.add('nameplate2', { plate = 1 }), frame, 'the same frame, for a friend')
		local debuffs = frame.Debuffs
		eq(group(debuffs).maxFrameCount, 2, "the Friendly page's count, through the container")
		eq(sizes(debuffs), all(30, 3), "its buttons at the Friendly page's size")
		local later = debuffs:_AddButton()
		eq(('%dx%d'):format(later:GetWidth(), later:GetHeight()), '30x30', 'a button the container makes after: the same')

		-- Relative size follows the frame's own height: the friendly 16.
		P.friendlynameplate.debuffs.relative_size = true
		P.friendlynameplate.debuffs.size = 6
		UF:UpdateConfig('friendlynameplate', 'Debuffs')
		eq(sizes(debuffs), all(22, 4), 'Relative size: 16 + 6, without a reload')
		eq(#take_errors(), 0, client .. ': no error')
	end)

	test(client .. ": the Enemy page's size and count come back when the plate is handed back to an enemy", function()
		local st, UF, P = world(client)
		local frame = enemy_plate(UF)
		friend('nameplate2')
		NP.add('nameplate2', { plate = 1 })
		NP.remove('nameplate2')
		enemy('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		eq(group(frame.Debuffs).maxFrameCount, 6, "the Enemy page's count")
		eq(sizes(frame.Debuffs), all(20, 3), "the Enemy page's size")

		-- And Max set on the Enemy page applies without a reload.
		P.nameplate.debuffs.max = 4
		UF:UpdateConfig('nameplate', 'Debuffs')
		eq(group(frame.Debuffs).maxFrameCount, 4, 'Max, without a reload')
		eq(#take_errors(), 0, client .. ': no error')
	end)

	test(client .. ': in combat the count applies at once and the size waits for the end of combat, with no error', function()
		local st, UF, P = world(client)
		local frame = enemy_plate(UF)
		local debuffs = frame.Debuffs
		local layouts = {}
		local setLayout = debuffs.SetAuraGroupLayout
		debuffs.SetAuraGroupLayout = function(self, key, layout)
			-- Out of combat only: the buttons refuse their getters in it.
			layouts[#layouts + 1] = not InCombatLockdown() and sizes(self) or 'in combat'
			return setLayout(self, key, layout)
		end

		stub.in_combat = true
		friend('nameplate2')
		NP.add('nameplate2', { plate = 1 })
		eq(#take_errors(), 0, 'no error: no button touched while aura data is secret')
		eq(group(debuffs).maxFrameCount, 2, "the Friendly page's count at once")

		-- Combat over, before its event: the buttons kept their size.
		stub.in_combat = false
		eq(sizes(debuffs), all(20, 3), 'the buttons keep their size until combat ends')
		layouts = {}
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(sizes(debuffs), all(30, 3), "then take the Friendly page's")
		eq(layouts[#layouts], all(30, 3), 'and the container lays them out again after they are resized')

		-- Handed back to an enemy in combat: the same, the other way.
		stub.in_combat = true
		NP.remove('nameplate2')
		enemy('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		eq(group(debuffs).maxFrameCount, 6, "an enemy in combat: the Enemy page's count at once")
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(sizes(debuffs), all(20, 3), "and its size once combat ends")
		eq(#take_errors(), 0, 'no error')
		debuffs.SetAuraGroupLayout = setLayout
	end)
end

test('the aura tabs: Size, Relative size and Max apply without a reload; Show and the borders still need one', function()
	local st, UF = world('forever')
	-- Each unit's tab as the element gives it: every unit's frames apply them
	-- the same way.
	for _, unit in ipairs({ 'nameplate', 'friendlynameplate', 'target' }) do
		for _, area in ipairs({ 'Buffs', 'Debuffs' }) do
			local tab = UF.elements[area].GetConfigTable(unit)
			local buttonsArgs = tab.args.buttons.args
			for _, key in ipairs({ 'size', 'relative_size', 'max' }) do
				check(not buttonsArgs[key].desc:find('eload'), ('%s %s %s: no reload asked: %s'):format(unit, area, key, buttonsArgs[key].desc))
			end
			check(buttonsArgs.border.desc:find('/reload') ~= nil, ('%s %s: the border still asks for one'):format(unit, area))
			check(tab.args.cooldown.args.enable.desc:find('/reload') ~= nil, ('%s %s: the cooldown Show still asks for one'):format(unit, area))
		end
	end
end)
