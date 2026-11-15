-- What a color pick costs the unit frames and the nameplates
-- (SaftUI-Unitframes/unitframes.lua: UF:OnColorsChanged, UF.ColorReaches,
-- UF:UpdateColors), at the size of a 40 player raid with its plates: only the
-- frames a color reaches update, and only the elements the color's group
-- colors. colors_test.lua's stand-in oUF and counting frames, made into the
-- whole UI:
--   - 'raid1' to 'raid40' in a header: classes cycling the client's, 5 mages
--     (raid1, 9, 17, 25 and 33); raid1 and raid2 tanks, raid3 to raid10
--     healers, raid40 with no role, the rest damage dealers; raid7 offline;
--     half of them mana users, the rest rage users;
--   - 'nameplate1' to 'nameplate40': 30 NPCs at standing 2, 6 at 4 (the last
--     of them shows no unit), 4 enemy player mages. Plates have no Power or
--     role corner, as in game;
--   - 10 single frames (the player a druid on energy with its mana bar and
--     combo points, three bosses at standing 3).
-- The elements are counting stand-ins (oUF's own update is not run): what is
-- measured is which frames and elements a pass reaches, and the pass's own
-- cost, which is the reader's. UnitClass, UnitReaction, UnitPowerType,
-- UnitIsConnected, UnitIsTapDenied, UnitIsPlayer and UnitGroupRolesAssigned
-- are stubbed by unit and make nothing per call.
local C = load_test_file('lib/color_cost.lua')
local S = load_test_file('lib/secrets.lua')
load_core_helpers()
addon_namespace('SaftUI-Unitframes').oUF = {
	colors = {
		class = {}, reaction = {}, power = {},
		disconnected = CreateColor(1, 1, 1), tapped = CreateColor(1, 1, 1),
		roles = {}, runes = {},
	},
}
load_saftui('SaftUI-Unitframes/unitframes.lua')

local st = SaftUI
local UF = st:GetModule('Unitframes')
local profile = st.config.profile.colors
local oUFColors = UF.oUF.colors

local CLASSES = { 'WARRIOR', 'PALADIN', 'HUNTER', 'ROGUE', 'PRIEST', 'SHAMAN', 'WARLOCK', 'DRUID' }

-- Unit data, by unit token.
local classOf, reactionOf, powerOf, playerOf, connectedOf, tappedOf, roleOf = {}, {}, {}, {}, {}, {}, {}
local missing = {}
UnitExists = function(unit) return not missing[unit] end
UnitClass = function(unit) return 'Class', classOf[unit] end
UnitReaction = function(unit) return reactionOf[unit] end
UnitPowerType = function(unit) return 0, powerOf[unit] end
UnitIsPlayer = function(unit) return playerOf[unit] or false end
UnitIsConnected = function(unit)
	local connected = connectedOf[unit]
	if connected == nil then return true end
	return connected
end
UnitIsTapDenied = function(unit) return tappedOf[unit] or false end
UnitGroupRolesAssigned = function(unit) return roleOf[unit] or 'NONE' end

-- A frame whose elements count their ForceUpdate calls and which counts its
-- UpdateTags calls; all its methods are shared, so a call makes nothing.
local ELEMENTS = { 'Health', 'Power', 'AdditionalPower', 'ClassPower', 'GroupRoleIndicator' }
-- Each element and each frame paints a real stub widget as it updates, with
-- the color oUF holds at that moment (what oUF's own update does with the
-- colors), so C.measure counts real calls and a pass skipped in combat, or
-- run before oUF has the new color, shows. 'seen' is the red it read.
local function ForceUpdate(self)
	self.updates = self.updates + 1
	local c = oUFColors.class.MAGE
	self.seen = c.r
	self.tex:SetVertexColor(c.r, c.g, c.b)
end
local function IsElementEnabled(self, name) return self.owner.have[name] == true end
local function UpdateTags(self)
	self.tags = self.tags + 1
	local c = oUFColors.class.MAGE
	self.font:SetTextColor(c.r, c.g, c.b)
end
local function GetConfig() return {} end

local frames = {}
local function make_frame(unit, have, plate)
	local frame = { __unit = unit, tags = 0, have = {}, UpdateTags = UpdateTags, IsElementEnabled = IsElementEnabled,
		GetConfig = GetConfig, isNamePlate = plate or nil, shown = true, threats = 0 }
	frame.owner = frame
	local host = CreateFrame('Frame', nil, UIParent)
	frame.font = host:CreateFontString()
	for _, name in ipairs(have) do
		frame.have[name] = true
		frame[name] = { updates = 0, ForceUpdate = ForceUpdate, tex = host:CreateTexture() }
	end
	frames[#frames + 1] = frame
	return frame
end

local raid, plates, singles, boss = {}, {}, {}, {}
local mages = 0
for i = 1, 40 do
	local unit = 'raid' .. i
	local mage = i % 8 == 1
	classOf[unit] = mage and 'MAGE' or CLASSES[(i % #CLASSES) + 1]
	if mage then mages = mages + 1 end
	playerOf[unit], reactionOf[unit] = true, 5
	powerOf[unit] = i % 2 == 0 and 'MANA' or 'RAGE'
	roleOf[unit] = i <= 2 and 'TANK' or i <= 10 and 'HEALER' or i == 40 and 'NONE' or 'DAMAGER'
	raid[i] = make_frame(unit, { 'Health', 'Power', 'GroupRoleIndicator' })
end
connectedOf.raid7 = false
for i = 1, 40 do
	local unit = 'nameplate' .. i
	if i <= 36 then
		classOf[unit], reactionOf[unit], playerOf[unit] = 'WARRIOR', i <= 30 and 2 or 4, false
	else
		classOf[unit], reactionOf[unit], playerOf[unit] = 'MAGE', 2, true
		mages = mages + 1
	end
	powerOf[unit] = 'MANA'
	plates[i] = make_frame(unit, { 'Health' }, true)
end
plates[36].shown = false
tappedOf.nameplate1 = true
for _, unit in ipairs({ 'player', 'target', 'focus', 'pet', 'targettarget', 'focustarget', 'pettarget' }) do
	classOf[unit], reactionOf[unit], playerOf[unit], powerOf[unit] = 'WARRIOR', 5, unit ~= 'pet', 'MANA'
	singles[unit] = make_frame(unit, { 'Health', 'Power' })
end
classOf.player, powerOf.player = 'DRUID', 'ENERGY'
for _, name in ipairs({ 'AdditionalPower', 'ClassPower' }) do
	singles.player.have[name] = true
	singles.player[name] = { updates = 0, ForceUpdate = ForceUpdate, tex = CreateFrame('Frame', nil, UIParent):CreateTexture() }
end
for i = 1, 3 do
	local unit = 'boss' .. i
	classOf[unit], reactionOf[unit], playerOf[unit], powerOf[unit] = 'WARRIOR', 3, false, 'MANA'
	boss[i] = make_frame(unit, { 'Health', 'Power' })
end

local header = { GetNumChildren = function() return #raid end }
function header.GetChildren() return unpack(raid) end
UF.groups = { raid = header }
UF.nameplates = plates
UF.units = { boss = boss }
for unit, frame in pairs(singles) do UF.units[unit] = frame end
UF.PlateShowsUnit = function(_, frame) return frame.shown end
UF.ElementWanted = function(_, element) return element.config.enable end -- updaters.lua's, as far as a config goes
UF.UpdatePlateThreat = function(_, frame) frame.threats = frame.threats + 1 end
local previews = {}
UF.testGroups = { party = true }
UF.UpdateGroupPreview = function(_, group) previews[group] = (previews[group] or 0) + 1 end

-- oUF's colors, one object per profile color (the profile's own tables are the
-- source), so a pass copies into them as it does in game.
local function seed(group, key)
	local from = profile[group][key]
	local color = CreateColor(from.r, from.g, from.b)
	if group == 'status' then oUFColors[key] = color else oUFColors[group][key] = color end
	return color
end
for _, key in ipairs({ 'MAGE', 'WARRIOR', 'DRUID' }) do seed('class', key) end
for key in pairs({ [2] = true, [4] = true }) do seed('reaction', key) end
for _, key in ipairs({ 'MANA', 'ENERGY', 'COMBO_POINTS' }) do seed('power', key) end

-- Every widget is colored once, as the stub's first color call makes a table.
for _, frame in ipairs(frames) do
	for _, name in ipairs(ELEMENTS) do
		if frame[name] then frame[name]:ForceUpdate() end
	end
	frame:UpdateTags()
end

local function set(group, key, r, g, b)
	local color = profile[group][key]
	color.r, color.g, color.b = r, g, b
end

local function reset()
	for _, frame in ipairs(frames) do
		frame.tags, frame.threats = 0, 0
		for _, name in ipairs(ELEMENTS) do
			if frame[name] then frame[name].updates = 0 end
		end
	end
	for group in pairs(previews) do previews[group] = nil end
	missing = {}
	stub.in_combat = false
	take_errors()
end

-- What a pass updated: { Health = n, Power = n, ..., tags = n } over every
-- frame, and the frames each element update reached, by unit.
local function totals(only)
	local out = { tags = 0, threats = 0, frames = {} }
	for _, name in ipairs(ELEMENTS) do out[name] = 0 end
	for _, frame in ipairs(frames) do
		if not only or only[frame] then
			for _, name in ipairs(ELEMENTS) do
				if frame[name] then
					out[name] = out[name] + frame[name].updates
					if frame[name].updates > 0 then out.frames[frame.__unit] = true end
				end
			end
			out.tags, out.threats = out.tags + frame.tags, out.threats + frame.threats
			if frame.tags > 0 then out.frames[frame.__unit] = true end
		end
	end
	return out
end

local function count_frames(t)
	local n = 0
	for _ in pairs(t.frames) do n = n + 1 end
	return n
end

local function rgb(c) return ('%.2f,%.2f,%.2f'):format(c.r, c.g, c.b) end

test("Class > Mage reaches only the mages' frames: Health and Power once each, and their tags", function()
	reset()
	set('class', 'MAGE', 0.1, 0.2, 0.3)
	local mage_color = oUFColors.class.MAGE
	local m = C.measure(function() st:ColorChanged('class', 'MAGE') end, 1)
	C.print('unit frames, class', m)
	eq(mages, 9, 'the 9 mages (5 raid, 4 plates)')
	for _, frame in ipairs(raid) do
		local mage = classOf[frame.__unit] == 'MAGE'
		eq(frame.Health.updates, mage and 1 or 0, frame.__unit .. ' Health')
		eq(frame.Power.updates, mage and 1 or 0, frame.__unit .. ' Power')
		eq(frame.tags, mage and 1 or 0, frame.__unit .. ' tags')
		eq(frame.GroupRoleIndicator.updates, 0, frame.__unit .. ' role corner')
	end
	-- The plates of the 4 player mages (the 36th shows nothing but is no mage).
	for i = 1, 40 do
		local mage = classOf['nameplate' .. i] == 'MAGE'
		eq(plates[i].Health.updates, mage and 1 or 0, 'nameplate' .. i .. ' Health')
		eq(plates[i].tags, mage and 1 or 0, 'nameplate' .. i .. ' tags')
	end
	local t = totals()
	eq(t.Health, 9, 'Health 9')
	eq(t.Power, 5, "Power 5 (the plates have none)")
	eq(t.tags, 9, 'tags 9')
	eq(t.AdditionalPower + t.ClassPower + t.GroupRoleIndicator, 0, 'no other element')
	check(t.Health + t.Power + t.tags <= 23, '23 calls at most')
	eq(oUFColors.class.MAGE, mage_color, "oUF's color object is the same one")
	eq(rgb(oUFColors.class.MAGE), '0.10,0.20,0.30', "oUF's mage color is the new color")
	check(oUFColors.class.MAGE ~= profile.class.MAGE, "and is not the profile's table")
	eq(rgb(oUFColors.class.WARRIOR), rgb(profile.class.WARRIOR), "another class's color is untouched")
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	eq(#take_errors(), 0, 'no errors')
end)

test("Reputation > Hostile: the 30 plates at standing 2, Health and tags; the enemy players' plates untouched", function()
	reset()
	set('reaction', 2, 0.9, 0.1, 0.1)
	st:ColorChanged('reaction', 2)
	local t = totals()
	eq(t.Health, 30, 'Health of the 30 NPC plates')
	eq(t.tags, 30, 'their tags')
	eq(t.Power, 0, 'no Power (plates have none, the bosses are at standing 3)')
	for i = 1, 40 do
		local hostile = i <= 30
		eq(plates[i].Health.updates, hostile and 1 or 0, 'nameplate' .. i)
	end
	for i = 37, 40 do eq(plates[i].Health.updates, 0, 'enemy player ' .. i .. ' untouched') end
	eq(plates[36].Health.updates, 0, 'a plate at standing 4 untouched')
	eq(rgb(oUFColors.reaction[2]), '0.90,0.10,0.10', "oUF's color")
	eq(#take_errors(), 0)
end)

test('Reputation: a pet is reached by its standing, a player not', function()
	reset()
	st:ColorChanged('reaction', 5)
	eq(singles.pet.Health.updates, 1, 'the pet, an NPC at standing 5')
	eq(singles.target.Health.updates, 0, 'a player (target) wears its class color')
	eq(raid[1].Health.updates, 0, 'a raid player')
end)

test('Power > Mana: Power of mana users, every AdditionalPower; ClassPower only on the player frame, only for its own points', function()
	reset()
	st:ColorChanged('power', 'MANA')
	local expected = 0
	for _, frame in ipairs(frames) do
		if frame.Power and powerOf[frame.__unit] == 'MANA' then expected = expected + 1 end
	end
	local t = totals()
	eq(t.Power, expected, 'Power of every mana user')
	check(singles.player.Power.updates == 0, 'not the druid on energy')
	eq(t.AdditionalPower, 1, 'the player frame has the one AdditionalPower, updated')
	eq(t.ClassPower, 0, 'ClassPower not for Mana')
	eq(t.Health + t.tags + t.GroupRoleIndicator, 0, 'no other element, no tags')
	reset()
	st:ColorChanged('power', 'COMBO_POINTS')
	t = totals()
	eq(t.ClassPower, 1, "the player's ClassPower for its own points")
	eq(t.Power + t.AdditionalPower, 0, 'no Power: nobody has combo points as a power type')
	reset()
	st:ColorChanged('power', 'HOLY_POWER')
	eq(totals().ClassPower, 1, "a class power key reaches the player's ClassPower")
	reset()
	st:ColorChanged('power', 'RAGE')
	t = totals()
	eq(t.ClassPower + t.AdditionalPower, 0, 'Rage touches neither')
	eq(t.Power, 20, 'the 20 raid frames on rage')
	eq(#take_errors(), 0)
end)

test('Status > Disconnected: Health of raid7 alone', function()
	reset()
	set('status', 'disconnected', 0.4, 0.4, 0.4)
	st:ColorChanged('status', 'disconnected')
	local t = totals()
	eq(t.Health, 1, 'one Health')
	eq(raid[7].Health.updates, 1, 'raid7')
	eq(raid[7].Power.updates, 1, "and its Power, which has Disconnected and Tapped flags too")
	eq(t.Power, 1, 'no other Power')
	eq(t.tags, 0, 'no tags')
	eq(rgb(oUFColors.disconnected), '0.40,0.40,0.40', "oUF's color")
	reset()
	st:ColorChanged('status', 'tapped')
	t = totals()
	eq(t.Health, 1, 'Tapped: one Health')
	eq(plates[1].Health.updates, 1, 'the tapped plate')
	reset()
	st:ColorsChanged('status')
	t = totals()
	eq(t.Health, 89, 'the whole Status pass: every Health')
	eq(t.Power, 50, 'and every Power')
end)

test("Text > Danger: UpdateTags on every frame showing a unit, no element update; Text > Normal: the shown plates' threat text", function()
	reset()
	st:ColorChanged('text', 'danger')
	local t = totals()
	eq(t.tags, 89, 'every frame showing a unit but the one plate that shows none')
	check(t.tags <= 90, '90 at most')
	eq(t.Health + t.Power + t.AdditionalPower + t.ClassPower + t.GroupRoleIndicator, 0, 'no element update')
	eq(t.threats, 0, "Danger is not the threat text's color")
	reset()
	st:ColorChanged('text', 'normal')
	t = totals()
	eq(t.tags, 0, 'no tag reads Normal')
	eq(t.threats, 39, "the 39 shown plates' threat text")
	eq(plates[36].threats, 0, 'not the plate showing no unit')
	for _, key in ipairs({ 'strong', 'shared' }) do
		reset()
		st:ColorChanged('text', key)
		eq(totals().tags, 0, 'no tag reads ' .. key)
		eq(previews.party, nil, 'and no preview does')
	end
	reset()
	st:ColorChanged('text', 'caution')
	eq(previews.party, 1, 'Caution is read by the previews')
	reset()
	st:ColorChanged('text', 'success')
	eq(previews.party, nil, 'Success is read by tags but not the previews')
	reset()
	missing.raid3 = true
	st:ColorChanged('text', 'danger')
	eq(raid[3].tags, 0, 'a frame with no unit is left alone')
	eq(raid[4].tags, 1, 'the others still update')
	eq(#take_errors(), 0)
end)

test("Roles > Tank: the 2 tanks' role corners, in the Tank color; Damage reaches the damage dealers and those with none", function()
	reset()
	st:ColorChanged('roles', 'TANK')
	local t = totals()
	eq(t.GroupRoleIndicator, 2, 'the two tanks')
	eq(raid[1].GroupRoleIndicator.updates + raid[2].GroupRoleIndicator.updates, 2, 'raid1 and raid2')
	eq(t.Health + t.Power + t.tags, 0, 'nothing else')
	reset()
	st:ColorChanged('roles', 'HEALER')
	eq(totals().GroupRoleIndicator, 8, 'the 8 healers')
	reset()
	st:ColorChanged('roles', 'DAMAGER')
	t = totals()
	eq(t.GroupRoleIndicator, 30, '29 damage dealers and raid40, with no role')
	eq(raid[40].GroupRoleIndicator.updates, 1, 'a unit with no role')
	eq(raid[1].GroupRoleIndicator.updates, 0, 'not a tank')
end)

test('a secret class, standing or power type counts as a match (Review Focus 2)', function()
	local restore = S.install()
	reset()
	local saved = { classOf.raid3, reactionOf.raid3, powerOf.raid3, playerOf.raid3, roleOf.raid3 }
	classOf.raid3 = S.secret('class')
	st:ColorChanged('class', 'MAGE')
	eq(raid[3].Health.updates, 1, 'raid3 updated on Class > Mage')
	eq(raid[3].Power.updates, 1, 'its Power too')
	eq(raid[3].tags, 1, 'and its tags')
	eq(raid[2].Health.updates, 0, 'a frame with a plain other class is not')
	reset()
	reactionOf.nameplate31 = S.secret('standing')
	st:ColorChanged('reaction', 2)
	eq(plates[31].Health.updates, 1, 'a plate whose standing is secret')
	reset()
	playerOf.nameplate2 = S.secret('player')
	st:ColorChanged('reaction', 2)
	eq(plates[2].Health.updates, 1, 'and one that is secret about being a player')
	reset()
	powerOf.raid4 = S.secret('power')
	st:ColorChanged('power', 'RAGE')
	eq(raid[4].Power.updates, 1, 'a secret power type')
	reset()
	roleOf.raid5 = S.secret('role')
	st:ColorChanged('roles', 'TANK')
	eq(raid[5].GroupRoleIndicator.updates, 1, 'a secret role')
	reset()
	connectedOf.raid6 = S.secret('connected')
	st:ColorChanged('status', 'disconnected')
	eq(raid[6].Health.updates, 1, 'a secret connection')
	eq(#take_errors(), 0, 'nothing compared, no errors')
	classOf.raid3, reactionOf.raid3, powerOf.raid3, playerOf.raid3, roleOf.raid3 = unpack(saved, 1, 5)
	reactionOf.nameplate31, playerOf.nameplate2, powerOf.raid4, roleOf.raid5, connectedOf.raid6 = 4, false, 'RAGE', 'HEALER', nil
	restore()
end)

test("the whole pass (key nil) updates every frame with a unit, for the group's elements only", function()
	reset()
	st:ColorsChanged('class')
	local t = totals()
	eq(t.Health, 89, 'Health of every frame showing a unit')
	eq(t.Power, 50 - 0, 'Power of every frame that has one')
	eq(t.tags, 89, 'every tags')
	eq(t.AdditionalPower + t.ClassPower + t.GroupRoleIndicator, 0, "no element Class does not color")
	reset()
	st:ColorsChanged('roles')
	t = totals()
	eq(t.GroupRoleIndicator, 40, 'every role corner')
	eq(t.Health + t.Power + t.tags, 0, 'nothing else')
	reset()
	st:ColorsChanged('power')
	t = totals()
	eq(t.AdditionalPower, 1, 'AdditionalPower')
	eq(t.ClassPower, 1, 'ClassPower')
	eq(t.Health, 0, 'no Health')
	reset()
	st:ColorsChanged('text')
	t = totals()
	eq(t.threats, 39, "the plates' threat text on a whole Text pass")
	eq(t.tags, 89, 'and every tags')
end)

test('the previews redraw for class, reaction, power, status, roles and text (their offline members); not for threat', function()
	for _, case in ipairs({ { 'class', 'MAGE' }, { 'reaction', 2 }, { 'power', 'MANA' }, { 'status', 'disconnected' },
			{ 'roles', 'TANK' }, { 'text', 'danger' } }) do
		reset()
		st:ColorChanged(case[1], case[2])
		eq(previews.party, 1, case[1] .. ' redraws the party preview once')
	end
	reset()
	st:ColorsChanged('status')
	eq(previews.party, 1, 'the whole Status pass too')
	for _, case in ipairs({ { 'threat', 'warning' } }) do
		reset()
		st:ColorChanged(case[1], case[2])
		eq(previews.party, nil, case[1] .. ' does not')
	end
	eq(#take_errors(), 0)
end)

test('100 Class > Mage passes allocate under 4 KB; in combat the same calls (Review Focus 4)', function()
	reset()
	st:ColorChanged('class', 'MAGE')
	reset()
	local m = C.measure(function() st:ColorChanged('class', 'MAGE') end, 100)
	C.print('100 class passes', m)
	check(m.kb < 4, ('under 4 KB, got %.2f'):format(m.kb))
	eq(m.calls.total, 2300, '23 color calls a pass: 9 Health, 5 Power, 9 tags (real stub widgets)')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	reset()
	stub.in_combat = true
	local combat = C.measure(function() st:ColorChanged('class', 'MAGE') end, 100)
	C.print('100 class passes, in combat', combat)
	check(combat.kb < 4, ('under 4 KB in combat, got %.2f'):format(combat.kb))
	eq(combat.forbidden.total, 0, 'nothing forbidden in combat')
	eq(combat.made, 0, 'nothing made in combat')
	eq(combat.calls.total, m.calls.total, 'the same calls')
	local t = totals()
	eq(t.Health, 900, 'in combat every mage Health was updated, 100 times')
	stub.in_combat = false
	reset()
	local text = C.measure(function() st:ColorChanged('text', 'danger') end, 100)
	check(text.kb < 4, ('Text passes under 4 KB, got %.2f'):format(text.kb))
	check(text.calls.total > 0, 'and they color')
	local roles = C.measure(function() st:ColorChanged('roles', 'TANK') end, 100)
	check(roles.kb < 4, ('Roles passes under 4 KB, got %.2f'):format(roles.kb))
	eq(#take_errors(), 0)
end)

test("oUF has the new color before a frame updates (the whole pass at an edit's end would show the old one)", function()
	reset()
	set('class', 'MAGE', 0.77, 0.66, 0.55)
	st:ColorChanged('class', 'MAGE')
	for _, frame in ipairs({ raid[1], raid[9], plates[37] }) do
		eq(frame.Health.seen, 0.77, frame.__unit .. ' read the new red')
	end
	set('class', 'MAGE', 0.31, 0.66, 0.55)
	st:ColorsChanged('class')
	eq(raid[1].Health.seen, 0.31, 'and on the whole pass')
	eq(raid[2].Health.seen, 0.31, 'every frame')
end)

test('Reputation reaches a player whose bar or name shows its standing, and no other', function()
	reset()
	local target = singles.target
	target.Health.colorReaction, target.Health.colorClass = true, false
	st:ColorChanged('reaction', 5)
	eq(target.Health.updates, 1, 'a player with Class off and Reaction on')
	target.Health.colorReaction = nil
	reset()
	target.config = { name = { color_friendly = true, colorClass = false } }
	st:ColorChanged('reaction', 5)
	eq(target.tags, 1, 'a player whose name has Color friendly on and Class color off')
	eq(target.Health.updates, 1, '(and so is its Health: the frame shows a standing)')
	target.config = nil
	reset()
	target.Health.colorReaction, target.Health.colorClass = true, true
	st:ColorChanged('reaction', 5)
	eq(target.Health.updates, 0, 'a player with Class on is not')
	target.Health.colorReaction, target.Health.colorClass = nil, nil
	reset()
	singles.focus.Power.colorReaction = true
	st:ColorChanged('reaction', 5)
	eq(singles.focus.Power.updates, 1, 'a player whose Power shows its standing')
	singles.focus.Power.colorReaction = nil
	reset()
	singles.focus.Power.colorReaction, singles.focus.Power.colorPower = true, true
	st:ColorChanged('reaction', 5)
	eq(singles.focus.Power.updates, 0, 'a player whose Power has Power type on as well is not')
	singles.focus.Power.colorReaction, singles.focus.Power.colorPower = nil, nil
	eq(#take_errors(), 0)
end)

test('ClassPower follows the frame that has it, in a vehicle too', function()
	reset()
	singles.player.__unit = 'vehicle'
	st:ColorChanged('power', 'COMBO_POINTS')
	eq(singles.player.ClassPower.updates, 1, 'the player frame whose unit is the vehicle')
	singles.player.__unit = 'player'
	eq(#take_errors(), 0)
end)

test('a hidden frame and an element its config turns off are not updated', function()
	reset()
	raid[1].IsVisible = function() return false end
	st:ColorChanged('class', 'MAGE')
	eq(raid[1].Health.updates + raid[1].tags, 0, 'a hidden frame: oUF updates it when it shows')
	eq(raid[9].Health.updates, 1, 'a shown one')
	raid[1].IsVisible = nil
	-- oUF gives a plate no OnShow: a plate showing its unit is updated though
	-- the game has hidden it.
	reset()
	plates[37].IsVisible = function() return false end
	st:ColorChanged('class', 'MAGE')
	eq(plates[37].Health.updates, 1, 'a hidden plate that shows its unit takes the color in the pass')
	plates[37].IsVisible = nil
	reset()
	raid[9].Power.config = { enable = false }
	st:ColorChanged('class', 'MAGE')
	eq(raid[9].Power.updates, 0, 'a bar its config turns off')
	eq(raid[9].Health.updates, 1, 'its Health')
	raid[9].Power.config = nil
end)

test('a profile color with no value leaves the color oUF has', function()
	oUFColors.class.ZZZ = CreateColor(0.5, 0.5, 0.5)
	UF:UpdateColors('class', 'ZZZ')
	eq(rgb(oUFColors.class.ZZZ), '0.50,0.50,0.50')
	oUFColors.class.ZZZ = nil
end)

test('UF.ColorReaches: key nil reaches every frame, a group with no rule too', function()
	eq(UF.ColorReaches(raid[1], 'class', nil), true)
	eq(UF.ColorReaches(raid[1], 'class', 'MAGE'), true)
	eq(UF.ColorReaches(raid[2], 'class', 'MAGE'), false)
	eq(UF.ColorReaches(raid[1], 'text', 'danger'), true)
	eq(UF.ColorReaches({}, 'class', 'MAGE'), true, 'a frame with no unit')
	eq(UF.ColorReaches(raid[7], 'status', 'disconnected'), true)
	eq(UF.ColorReaches(raid[8], 'status', 'disconnected'), false)
end)
