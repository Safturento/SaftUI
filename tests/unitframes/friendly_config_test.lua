-- The friendly nameplates' config unit (SaftUI-Unitframes/config/units/
-- friendlynameplate.lua) beside the enemy one, and the plate unit helpers in
-- unitframes.lua:
--   - friendlynameplate's defaults, read through the profile, and the enemy
--     defaults staying today's, for a new profile and an existing one;
--   - UF.IsPlateUnit and UF.PlateConfigKey (which config an enemy's or a
--     friend's plate draws from, with the two "use the other's settings"
--     boxes);
--   - the elements that skip a nameplate by ValidUnit skipping both plate
--     units, and Threat staying on the enemy page only.
--
-- The world is nameplate_world.lua's (see its top).
local NP = load_test_file('unitframes/nameplate_world.lua')

local function world()
	local st, UF = NP.world('forever')
	return st, UF, UF:GetProfileConfig()
end

test('the friendly defaults', function()
	local st, UF, P = world()
	local F = P.friendlynameplate
	eq(F.width, 150, 'width')
	eq(F.height, 16, 'height')
	eq(F.theme, 'none', 'frame Theme None')
	eq(F.use_enemy, false, 'the enemy box is off')
	eq(F.health.enable, false, 'no health bar')
	eq(F.health.text.enable, false, 'no health text')
	eq(F.name.enable, true, 'the name is on')
	eq(F.name.position.point, 'CENTER', 'centred')
	eq(F.name.position.rel_point, 'CENTER', 'on the frame')
	eq(F.name.position.x_off, 0, 'no x offset')
	eq(F.name.position.y_off, 0, 'no y offset')
	eq(F.name.position.element, false, 'anchored to the frame, not to an element')
	eq(F.name.max_width, 150, 'name max width')
	eq(F.name.colorClass, true, 'class coloured')
	eq(F.name.color_friendly, true, 'friendly coloured')
	eq(F.name.color_hostile, true, 'hostile coloured')
	eq(F.name.showLevel, false, 'no level')
	eq(F.name.show_classification, false, 'no classification')
	eq(F.raidtargetindicator.enable, true, 'raid mark on')
	eq(F.raidtargetindicator.size, 16, 'raid mark size')
	eq(F.raidtargetindicator.position.point, 'BOTTOM', 'raid mark bottom')
	eq(F.raidtargetindicator.position.element, 'Name', 'on the name')
	eq(F.raidtargetindicator.position.rel_point, 'TOP', "at the name's top")
	eq(F.raidtargetindicator.position.x_off, 0, 'raid mark x')
	eq(F.raidtargetindicator.position.y_off, 4, '4 above')
	for _, key in ipairs({ 'castbar', 'debuffs', 'buffs', 'questindicator' }) do
		eq(F[key].enable, false, key .. ' off')
	end
	-- The enemy page's other values for when they're turned on.
	local E = P.nameplate
	eq(F.castbar.height, E.castbar.height, 'castbar height as the enemy')
	eq(F.castbar.width, E.castbar.width, 'castbar width as the enemy')
	eq(F.castbar.text.font, E.castbar.text.font, 'castbar text as the enemy')
	eq(F.castbar.icon.width, E.castbar.icon.width, 'castbar icon as the enemy')
	eq(F.debuffs.size, E.debuffs.size, 'debuff size as the enemy')
	eq(F.debuffs.max, E.debuffs.max, 'debuff count as the enemy')
	eq(F.debuffs.onlyShowPlayer, E.debuffs.onlyShowPlayer, 'debuffs as the enemy')
	eq(F.buffs.purgeable, E.buffs.purgeable, 'buffs as the enemy')
	eq(F.questindicator.size, E.questindicator.size, 'quest icon as the enemy')
end)

test('the enemy defaults are today\'s', function()
	local st, UF, P = world()
	local E = P.nameplate
	eq(E.width, 200, 'width')
	eq(E.height, 20, 'height')
	eq(E.enable, true, 'enable')
	eq(E.friendly, true, 'friendly')
	eq(E.threat_solo, false, 'threat_solo')
	eq(E.use_friendly, false, 'the friendly box is off')
	eq(E.health.text.short, true, 'health text short')
	eq(E.name.position.point, 'LEFT', 'name LEFT')
	eq(E.name.position.element, 'Health', 'on Health')
	eq(E.castbar.enable, true, 'castbar on')
	eq(E.debuffs.enable, true, 'debuffs on')
	eq(E.buffs.enable, true, 'buffs on')
end)

test('an existing profile keeps its values', function()
	reset_world()
	load_core_helpers()
	load_saftui('SaftUI-Unitframes/config/default.lua')
	load_saftui('SaftUI-Unitframes/config/units/nameplate.lua')
	load_saftui('SaftUI-Unitframes/config/units/friendlynameplate.lua')
	SaftUI.config.profile = { unitframes = { profiles = { Old = { nameplate = { width = 180, friendly = false } } } } }
	apply_defaults()
	local Old = SaftUI.config.profile.unitframes.profiles.Old
	eq(Old.nameplate.width, 180, 'the changed width is kept')
	eq(Old.nameplate.friendly, false, 'the changed friendly is kept')
	eq(Old.nameplate.height, 20, 'the rest is filled in')
	eq(Old.friendlynameplate.width, 150, 'the friendly unit gets its defaults')
	eq(Old.friendlynameplate.name.colorClass, true, 'and its name defaults')
end)

test('IsPlateUnit', function()
	local st, UF = world()
	eq(UF.PLATE_UNITS.nameplate, true, 'nameplate')
	eq(UF.PLATE_UNITS.friendlynameplate, true, 'friendlynameplate')
	eq(UF.IsPlateUnit('nameplate'), true, 'nameplate')
	eq(UF.IsPlateUnit('friendlynameplate'), true, 'friendlynameplate')
	eq(UF.IsPlateUnit('player'), false, 'player')
	eq(UF.IsPlateUnit('party'), false, 'party')
	eq(UF.IsPlateUnit(nil), false, 'nil')
end)

test('PlateConfigKey', function()
	local st, UF, P = world()
	local function key(friendly) return UF.PlateConfigKey(friendly) end
	eq(key(false), 'nameplate', 'an enemy, no boxes')
	eq(key(true), 'friendlynameplate', 'a friend, no boxes')
	P.nameplate.use_friendly = true
	eq(key(false), 'friendlynameplate', "an enemy, with the Enemy page's box")
	eq(key(true), 'friendlynameplate', 'a friend, with the Enemy page\'s box')
	P.nameplate.use_friendly = false
	P.friendlynameplate.use_enemy = true
	eq(key(false), 'nameplate', "an enemy, with the Friendly page's box")
	eq(key(true), 'nameplate', "a friend, with the Friendly page's box")
	-- Both boxes can't be on (the page prevents it), but it must not loop.
	P.nameplate.use_friendly = true
	eq(key(false), 'friendlynameplate', 'both boxes: an enemy')
	eq(key(true), 'nameplate', 'both boxes: a friend')
end)

test('the plates\' parts', function()
	local st, UF = world()
	for _, name in ipairs({ 'Power', 'GroupRoleIndicator', 'RaidRoleIndicator' }) do
		local valid = assert(UF.elements[name], name).ValidUnit
		eq(valid('nameplate'), false, name .. ': not on the enemy plate')
		eq(valid('friendlynameplate'), false, name .. ': not on the friendly plate')
		eq(valid('player'), true, name .. ': still on the player')
	end
	local threat = UF.elements.Threat.ValidUnit
	eq(threat('nameplate'), true, 'Threat: the enemy page')
	eq(threat('friendlynameplate'), false, 'Threat: not the friendly page')
end)
