-- Each plate draws from its kind's config unit (SaftUI-Unitframes/nameplates/
-- nameplates.lua's UF:ApplyPlateConfig and UF:ApplyPlateKind, unitframes.lua's
-- UF.PlateConfigKey and UF:ApplyConfig, elements/name.lua's tag, and
-- nameplates/threat.lua's Threat element):
--   - a friend's plate from Friendly nameplates (friendlynameplate), an
--     enemy's from Enemy nameplates (nameplate), frame.base_unit naming it,
--     and every part following that config: a friend's name alone by
--     default, an enemy's every part as before;
--   - a plate handed between the kinds, in combat too, and a unit's faction
--     changing, taking the new kind's whole look: its parts, its name's tag
--     and colour, and no threat on a friend;
--   - the two boxes: friends drawn from the enemy config, enemies from the
--     friendly one, with threat still the Enemy page's, and an enemy's only;
--   - a part turned on in the friendly config showing on friends;
--   - the look applied again only when the plate's config unit changes.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), whose tags are bound but never run. So a
-- name's text here is the st:name tag (tags.lua) run with the config unit its
-- bound tag string names, as oUF runs it. The tests check configs, parts and
-- colours, not where a plate's frame sits.
local T = load_test_file('lib/theme_helpers.lua')
local NP = load_test_file('unitframes/nameplate_world.lua')

-- A world with the plates spawned: the player a damage dealer in a party with
-- party1, so an enemy's plate with the player on its threat list is tinted
-- (threat.lua). P is the profile's units.
local function world(client)
	local st, UF = NP.world(client or 'forever')
	UF:SpawnNameplates()
	stub.role = 'DAMAGER'
	stub.group = { members = { 'party1' } }
	stub.units.party1 = { name = 'Friend', player = true, friend = true, role = 'DAMAGER' }
	return st, UF, UF:GetProfileConfig()
end

-- A unit the game shows, named after its token: a hostile one or a friendly
-- NPC, with the player at the top of its threat list either way (bad for a
-- damage dealer: a tint wherever the plate takes one).
local function enemy(unit)
	stub.units[unit] = { name = unit, friend = false, attackable = true, reaction = 2 }
	stub.threat[unit] = { player = 3 }
end
local function friend(unit)
	stub.units[unit] = { name = unit, friend = true, attackable = false, reaction = 5 }
	stub.threat[unit] = { player = 3 }
end

-- The text the plate's name shows: the st:name tag run as oUF runs the tag
-- string bound to the Name (ouf.tags), with the config unit it names.
local function name_text(UF, frame)
	local base = (NP.ouf.tags[frame.Name] or ''):match('^%[st:name%((.-)%)%]$')
	return UF.oUF.Tags.Methods['st:name'](frame.__unit, frame.__unit, base)
end
local function hex(st, color) return '|cff' .. st.StringFormat:ToHex(color:GetRGB()) end

local rgb = T.rgb

local function check_no_threat(frame, label)
	eq(frame.threatState, nil, label .. ': no threat tint')
	eq(frame.Threat:IsShown(), false, label .. ': no threat text')
end

-- A friend's look from the friendly defaults: the name alone, on the frame,
-- in the friendly reaction colour, and the raid mark, which oUF shows for a
-- mark; drawn from friendlynameplate.
local function check_friend(st, UF, frame, label)
	local F = UF:GetProfileConfig().friendlynameplate
	eq(frame.friendly, true, label .. ': a friend')
	eq(frame.base_unit, 'friendlynameplate', label .. ': draws from Friendly nameplates')
	eq(frame.config, F, label .. ": the frame's config")
	eq(frame.Health:IsShown(), false, label .. ': the health bar hidden')
	eq(frame.Health.text:IsShown(), false, label .. ': the health text hidden')
	eq(frame.Name:IsShown(), true, label .. ': the name shown')
	eq(select(2, frame.Name:GetPoint(1)), frame, label .. ': the name on the frame')
	eq(NP.ouf.tags[frame.Name], '[st:name(friendlynameplate)]', label .. ": the name's tag reads Friendly nameplates")
	eq(name_text(UF, frame), hex(st, UF.oUF.colors.reaction[5]) .. frame.__unit .. '|r', label .. ': the name in the friendly reaction colour')
	for _, name in ipairs({ 'Castbar', 'QuestIndicator' }) do
		check(not frame:IsElementEnabled(name), label .. ': ' .. name .. ' disabled in oUF')
		eq(frame[name]:IsShown(), false, label .. ': ' .. name .. ' hidden')
	end
	for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
		eq(frame[name].enabled, false, label .. ': ' .. name .. ' off')
		eq(frame[name]:IsShown(), false, label .. ': ' .. name .. ' hidden')
	end
	eq(UF:ElementWanted(frame.RaidTargetIndicator), true, label .. ': the raid mark wanted')
	eq(frame.RaidTargetIndicator:IsShown(), true, label .. ': the raid mark left to oUF')
	check_no_threat(frame, label)
end

-- An enemy's look, as before friendly plates had a config of their own: every
-- part, the name on the bar in the hostile colour, the threat tint and text
-- (in a group); drawn from nameplate. The castbar, the quest icon and the raid
-- mark are shown by oUF's own updates (a cast, a quest unit, a mark), which
-- the stand-in doesn't run: shown here means SaftUI left them to oUF.
local function check_enemy(st, UF, frame, label)
	eq(frame.friendly, false, label .. ': an enemy')
	eq(frame.base_unit, 'nameplate', label .. ': draws from Enemy nameplates')
	eq(frame.config, UF:GetProfileConfig().nameplate, label .. ": the frame's config")
	eq(frame.Health:IsShown(), true, label .. ': the health bar shown')
	eq(frame.Health.text:IsShown(), true, label .. ': the health text shown')
	eq(frame.Name:IsShown(), true, label .. ': the name shown')
	eq(select(2, frame.Name:GetPoint(1)), frame.Health, label .. ': the name on the bar')
	eq(NP.ouf.tags[frame.Name], '[st:name(nameplate)]', label .. ": the name's tag reads Enemy nameplates")
	st.config.profile.colors.text.danger:SetRGB(0.9, 0.2, 0.2) -- not the default, so a hardcoded red fails
	eq(name_text(UF, frame), hex(st, st.config.profile.colors.text.danger) .. frame.__unit .. '|r', label .. ': the name in the hostile colour')
	for _, name in ipairs({ 'Castbar', 'QuestIndicator' }) do
		eq(frame:IsElementEnabled(name), true, label .. ': ' .. name .. ' enabled in oUF')
		eq(frame[name]:IsShown(), true, label .. ': ' .. name .. ' left to oUF')
	end
	for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
		eq(frame[name].enabled, true, label .. ': ' .. name .. ' on')
		eq(frame[name]:IsShown(), true, label .. ': ' .. name .. ' shown')
	end
	eq(frame.RaidTargetIndicator:IsShown(), true, label .. ': the raid mark left to oUF')
	eq(frame.threatState, 'bad', label .. ': the threat tint')
	eq(rgb(frame.Health:GetStatusBarColor()), rgb(st.config.profile.colors.threat.bad:GetRGB()), label .. ': in the bad colour')
	eq(frame.Threat:IsShown(), true, label .. ': the threat text')
end

-- Counts UF:UpdateUnitFrame's full updates (no element named) of frame, or of
-- every frame for none, while watched; stop() puts the real one back.
local function watch_updates(UF, frame)
	local real = UF.UpdateUnitFrame
	local watch = { full = 0 }
	UF.UpdateUnitFrame = function(self, f, element_name, ...)
		if (frame == nil or f == frame) and not element_name then watch.full = watch.full + 1 end
		return real(self, f, element_name, ...)
	end
	function watch.stop() UF.UpdateUnitFrame = real end
	return watch
end

------------------------------------------------------------------ each kind's config

test('a friendly plate draws from the friendly config', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		friend('nameplate1')
		check_friend(st, UF, NP.add('nameplate1'), client)
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('an enemy plate is unchanged', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		-- Every frame watched: the first add makes it.
		local watch = watch_updates(UF, nil)
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		watch.stop()
		check_enemy(st, UF, frame, client)
		eq(watch.full, 1, client .. ": one full update, its first (UF.InitUnit's): the enemy config needs no other")
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ a plate changing kind

test('a plate handed from an enemy to a friend and back, in combat', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.in_combat = true
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check_enemy(st, UF, frame, client .. ': the enemy')

		NP.remove('nameplate1')
		friend('nameplate2')
		eq(NP.add('nameplate2', { plate = 1 }), frame, client .. ': the same frame for the friend')
		check_friend(st, UF, frame, client .. ': the friend')

		NP.remove('nameplate2')
		enemy('nameplate3')
		eq(NP.add('nameplate3', { plate = 1 }), frame, client .. ': and for the next enemy')
		check_enemy(st, UF, frame, client .. ': the enemy again')
		eq(#take_errors(), 0, client .. ': no error')
		stub.in_combat = false
	end
end)

test('UNIT_FACTION turns a friend hostile: the plate takes the enemy look, and back', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		friend('nameplate1')
		local frame = NP.add('nameplate1')
		check_friend(st, UF, frame, client .. ': a friend')

		local mark = #NP.ouf.calls
		enemy('nameplate1')
		stub.fire_event('UNIT_FACTION', 'nameplate1')
		check_enemy(st, UF, frame, client .. ': turned hostile')
		-- The name is bound to the new config, then oUF's update (which runs the
		-- tags) draws it; the tag's own UNIT_FACTION redraws it again a frame later.
		local seen = {}
		for i = mark + 1, #NP.ouf.calls do
			local call = NP.ouf.calls[i]
			if call[1] == frame and (call[2] == 'Tag' or call[2] == 'Untag' or call[2] == 'UpdateAllElements') then
				seen[#seen + 1] = call[2] .. ' ' .. tostring(call[3])
			end
		end
		eq(seen[1], 'Untag [st:name(friendlynameplate)]', client .. ": the friend's tag dropped")
		eq(seen[2], 'Tag [st:name(nameplate)]', client .. ": then the enemy's bound")
		eq(seen[#seen], 'UpdateAllElements UNIT_FACTION', client .. ": and oUF's update last: " .. table.concat(seen, ', '))

		friend('nameplate1')
		stub.fire_event('UNIT_FACTION', 'nameplate1')
		check_friend(st, UF, frame, client .. ': friendly again')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the boxes

test("the friendly box: friends drawn from the enemy config, with no threat", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		friend('nameplate1')
		local ally = NP.add('nameplate1')
		enemy('nameplate2')
		local foe = NP.add('nameplate2')

		P.friendlynameplate.use_enemy = true
		UF:ApplyConfig('friendlynameplate')
		eq(ally.friendly, true, client .. ': still a friend')
		eq(ally.base_unit, 'nameplate', client .. ': drawn from Enemy nameplates')
		eq(ally.config, P.nameplate, client .. ": the frame's config")
		eq(ally.Health:IsShown(), true, client .. ': the health bar, as on an enemy')
		eq(NP.ouf.tags[ally.Name], '[st:name(nameplate)]', client .. ": the name's tag reads Enemy nameplates")
		eq(name_text(UF, ally), 'nameplate1', client .. ": the enemy config's name colours: none for a friend")
		eq(ally:IsElementEnabled('Castbar'), true, client .. ': the castbar enabled, as the enemy config has it')
		eq(ally.Castbar.ShouldShow(ally.Castbar, 'nameplate1'), true, client .. ": and the friend's cast shows")
		for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
			eq(ally[name].enabled, true, client .. ': ' .. name .. ' on, as the enemy config has them')
			eq(ally[name]:IsShown(), true, client .. ': ' .. name .. ' shown')
		end
		check_no_threat(ally, client .. ': a friend on the enemy config')
		check_enemy(st, UF, foe, client .. ': the enemy, unchanged')

		friend('nameplate3')
		eq(NP.add('nameplate3').base_unit, 'nameplate', client .. ': a friend added while it is on')

		P.friendlynameplate.use_enemy = false
		UF:ApplyConfig('friendlynameplate')
		check_friend(st, UF, ally, client .. ': unchecked')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('the enemy box keeps threat, from the Enemy page', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		local E = P.nameplate
		E.threat.font = 'normal'
		E.threat.position = { point = 'BOTTOM', element = 'Health', rel_point = 'TOP', x_off = 3, y_off = 9 }
		enemy('nameplate1')
		local foe = NP.add('nameplate1')

		E.use_friendly = true
		UF:ApplyConfig('nameplate')
		eq(foe.friendly, false, client .. ': still an enemy')
		eq(foe.base_unit, 'friendlynameplate', client .. ': drawn from Friendly nameplates')
		eq(foe.config, P.friendlynameplate, client .. ": the frame's config")
		eq(foe.Health:IsShown(), false, client .. ": the friendly look: no health bar")
		check(not foe:IsElementEnabled('Castbar'), client .. ': and no castbar')
		eq(foe.threatState, 'bad', client .. ': still tinted, in a group')
		eq(rgb(foe.Health:GetStatusBarColor()), rgb(st.config.profile.colors.threat.bad:GetRGB()), client .. ': in the bad colour')
		eq(foe.Threat:IsShown(), true, client .. ': with the threat text')
		eq(foe.Threat.config, E.threat, client .. ": the threat text's config is the Enemy page's")
		eq(foe.Threat:GetFontObject(), st:GetFont('normal'), client .. ": its font the Enemy page's")
		local point, relativeTo, relativePoint, x, y = foe.Threat:GetPoint(1)
		eq(point, 'BOTTOM', client .. ": its point the Enemy page's")
		eq(relativeTo, foe.Health, client .. ': on the bar')
		eq(relativePoint, 'TOP', client .. ": its relative point the Enemy page's")
		eq(x, 3, client .. ': its x offset')
		eq(y, 9, client .. ': its y offset')

		-- On your own, the Enemy page's Threat when solo decides.
		stub.group = nil
		stub.fire_event('GROUP_ROSTER_UPDATE')
		check_no_threat(foe, client .. ': on your own, Threat when solo off')
		E.threat_solo = true
		UF:UpdateConfig('nameplate')
		eq(foe.threatState, 'bad', client .. ': Threat when solo on: tinted')
		eq(foe.Threat:IsShown(), true, client .. ': with its text')

		enemy('nameplate2')
		local second = NP.add('nameplate2')
		eq(second.base_unit, 'friendlynameplate', client .. ': an enemy added while it is on')
		eq(second.threatState, 'bad', client .. ': tinted')

		-- Threat on a friend stays hidden, whatever the Enemy page says.
		friend('nameplate3')
		check_no_threat(NP.add('nameplate3'), client .. ': a friend')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the friendly config's parts

test('parts turned on in the friendly config show on friends', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		local F = P.friendlynameplate
		friend('nameplate1')
		local ally = NP.add('nameplate1')
		enemy('nameplate2')
		local foe = NP.add('nameplate2')

		F.castbar.enable = true
		UF:UpdateConfig('friendlynameplate', 'Castbar')
		eq(ally:IsElementEnabled('Castbar'), true, client .. ": the friend's castbar enabled in oUF")
		eq(ally.Castbar.ShouldShow(ally.Castbar, 'nameplate1'), true, client .. ": and the friend's cast shows")

		F.buffs.enable = true
		UF:UpdateConfig('friendlynameplate', 'Buffs')
		eq(ally.Buffs.enabled, true, client .. ': its buffs on')
		eq(ally.Buffs:IsShown(), true, client .. ': and shown')

		F.health.enable = true
		UF:UpdateConfig('friendlynameplate', 'Health')
		eq(ally.Health:IsShown(), true, client .. ': its health bar shown')

		friend('nameplate3')
		local other = NP.add('nameplate3')
		eq(other:IsElementEnabled('Castbar'), true, client .. ': a friend added after: its castbar enabled')
		eq(other.Buffs.enabled, true, client .. ': and its buffs on')

		-- The Enemy page's castbar turned off leaves the friends'.
		P.nameplate.castbar.enable = false
		UF:UpdateConfig('nameplate', 'Castbar')
		check(not foe:IsElementEnabled('Castbar'), client .. ": the enemy's castbar disabled")
		eq(ally:IsElementEnabled('Castbar'), true, client .. ": the friend's stays")

		check_no_threat(ally, client .. ': threat is never a friend\'s')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the update

test('a re-applied look only when the key changes', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		NP.remove('nameplate1')

		local watch = watch_updates(UF, frame)
		friend('nameplate2')
		NP.add('nameplate2', { plate = 1 })
		NP.remove('nameplate2')
		friend('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		eq(watch.full, 1, client .. ': two friends after an enemy: the friendly look applied once')
		check_friend(st, UF, frame, client .. ': the second friend')

		NP.remove('nameplate3')
		enemy('nameplate4')
		NP.add('nameplate4', { plate = 1 })
		NP.remove('nameplate4')
		enemy('nameplate5')
		NP.add('nameplate5', { plate = 1 })
		eq(watch.full, 2, client .. ': then two enemies: the enemy look applied once')

		-- With friends on the enemy config, a friend after an enemy keeps it.
		P.friendlynameplate.use_enemy = true
		NP.remove('nameplate5')
		friend('nameplate6')
		NP.add('nameplate6', { plate = 1 })
		eq(frame.base_unit, 'nameplate', client .. ': a friend on the enemy config')
		eq(watch.full, 2, client .. ': and no update for it')
		watch.stop()

		-- A new plate's first add is a friend: the frame is built on the enemy
		-- config (its unit token's), then takes the friendly one; the next
		-- friend on it needs no update.
		P.friendlynameplate.use_enemy = false
		friend('nameplate7')
		local fresh = NP.add('nameplate7')
		eq(fresh.base_unit, 'friendlynameplate', client .. ': a new plate for a friend')
		NP.remove('nameplate7')
		watch = watch_updates(UF, fresh)
		friend('nameplate8')
		NP.add('nameplate8', { plate = 2 })
		eq(watch.full, 0, client .. ': and the next friend on it: none')
		watch.stop()
		eq(#take_errors(), 0, client .. ': no error')
	end
end)
