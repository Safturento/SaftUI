-- The threat tint on enemy nameplates (SaftUI-Unitframes/nameplates/threat.lua,
-- with elements/health.lua's PostUpdateColor and unitframes.lua's
-- UF:OnColorsChanged), and the threat text above the bar's right end:
--   - the state by role (UF.ThreatState): a tank's bad is not holding the mob
--     (good while another group tank holds it), a damage dealer's or healer's
--     is having it, and warning comes just before bad;
--   - the player's role from Blizzard's own check (PlayerUtil, Forever's tank
--     aura first); a group tank by its role, or on Forever its tank aura;
--   - a tank's mob that's loose on a group member who isn't a tank is bad,
--     even off the tank's own threat list; the group is read for who tanks
--     the mob by threat state, stopping at that member;
--   - nothing for a friendly plate, solo with Threat when solo off, a unit not
--     on the mob's threat list (but a tank's loose mob), or a secret threat
--     state; a member whose state is secret is skipped, one whose values
--     alone are secret still counts;
--   - warning and bad replace the bar's colour each time oUF colours it, good
--     gives oUF's colour back;
--   - the events that tint the plates again, a change of the unit's kind, and
--     a plate taken away;
--   - the Colors tab's Threat section, whose change recolours the plates (and
--     only the plates showing a unit);
--   - the threat text: the percent, coloured as the tint and in the normal
--     text colour while good, shown only where the tint would be and the
--     player is on the threat list; its Threat tab.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), whose elements don't update from the
-- unit's data. So a test colours the bar as oUF would and runs the bar's
-- colour callback (Health:PostUpdateColor) by hand, and the stand-in's
-- ForceUpdate only counts (Health.__forceUpdates). The threat, group and role
-- API is tests/wow/game.lua's (stub.threat, stub.secret_threat, stub.group,
-- stub.role, stub.tank_aura) and PlayerUtil blizzard.lua's (stub.spec_role).
local NP = load_test_file('unitframes/nameplate_world.lua')
local S = load_test_file('lib/secrets.lua')

-- A world with the plates spawned: the player a damage dealer in a party with
-- party1, another damage dealer.
local function world(client)
	local st, UF = NP.world(client or 'forever')
	UF:SpawnNameplates()
	stub.role = 'DAMAGER'
	stub.group = { members = { 'party1' } }
	stub.units.party1 = { name = 'Friend', player = true, friend = true, role = 'DAMAGER' }
	return st, UF, UF:GetProfileConfig().nameplate
end

local function enemy(unit) stub.units[unit] = { name = unit, friend = false, attackable = true, reaction = 2 } end
local function friend(unit) stub.units[unit] = { name = unit, friend = true, attackable = false, reaction = 5 } end

-- An enemy's plate, the player's entry (a status, or { status, percent }) on
-- its threat list.
local function add_enemy(unit, entry)
	enemy(unit)
	stub.threat[unit] = { player = entry }
	return NP.add(unit)
end

-- The game's threat list for unit changed.
local function threat_changed(unit) stub.fire_event('UNIT_THREAT_LIST_UPDATE', unit) end

local function rgb(r, g, b) return ('%.2f,%.2f,%.2f'):format(r, g, b) end
local function color(c) return rgb(c.r, c.g, c.b) end
local function bar(frame) return rgb(frame.Health:GetStatusBarColor()) end
local function forced(frame) return frame.Health.__forceUpdates or 0 end

-- SaftUI's hostile red, the colour oUF gives an enemy's bar.
local HOSTILE = { 135 / 255, 81 / 255, 81 / 255 }
local function ouf_colours(frame)
	frame.Health:SetStatusBarColor(unpack(HOSTILE))
	frame.Health:PostUpdateColor(frame.__unit)
end

------------------------------------------------------------------ the state

test('the threat table: every role and status', function()
	local st, UF = world()
	for _, c in ipairs({
		{ true, 3, false, 'good' }, { true, 2, false, 'warning' }, { true, 1, false, 'bad' }, { true, 0, false, 'bad' },
		{ true, 1, true, 'good' }, { true, 0, true, 'good' }, { true, nil, false, nil },
		{ false, 0, false, 'good' }, { false, 1, false, 'warning' }, { false, 2, false, 'bad' }, { false, 3, false, 'bad' }, { false, nil, false, nil },
	}) do eq(UF.ThreatState(c[1], c[2], c[3]), c[4], table.concat({ tostring(c[1]), tostring(c[2]), tostring(c[3]) }, ',')) end
end)

test('a tank: a mob another group tank holds is good', function()
	local st, UF = world()
	stub.role = 'TANK'
	stub.units.party1.role = 'TANK'
	enemy('nameplate1')
	stub.threat.nameplate1 = { player = 0, party1 = 3 }
	local frame = NP.add('nameplate1')
	eq(UF:PlateThreat(frame), 'good', 'party1, a tank, holds it')
	eq(frame.threatState, 'good', 'the plate took it on its add')
	stub.threat.nameplate1.party1 = 1
	eq(UF:PlateThreat(frame), 'bad', 'nobody in the group tanks it')
	stub.threat.nameplate1.party1 = 3
	stub.units.party1.role = 'DAMAGER'
	eq(UF:PlateThreat(frame), 'bad', 'a damage dealer holding it is no co-tank')

	-- A raid's members are raid1..N, the player among them.
	stub.group = { raid = true, members = { 'raid1', 'raid2', 'raid3' } }
	stub.units.raid3 = { name = 'Offtank', player = true, friend = true, role = 'TANK' }
	stub.threat.nameplate1 = { player = 1, raid3 = 2 }
	eq(UF:PlateThreat(frame), 'good', 'a raid tank holds it')
	stub.threat.nameplate1.raid3 = 0
	eq(UF:PlateThreat(frame), 'bad', "and once it doesn't")
end)

test('Forever: a member with the tank aura counts as a group tank; retail reads the role only', function()
	for _, case in ipairs({ { 'forever', 'good' }, { 'retail', 'bad' } }) do
		local client, expected = case[1], case[2]
		local st, UF = world(client)
		stub.role = 'TANK'
		stub.units.party1.role = 'NONE'
		stub.tank_aura.party1 = true
		enemy('nameplate1')
		stub.threat.nameplate1 = { player = 0, party1 = 3 }
		local frame = NP.add('nameplate1')
		eq(UF:PlateThreat(frame), expected, client)
		eq(UF.IsGroupTank('party1'), client == 'forever', client .. ': IsGroupTank')
		eq(UnitHasEffectivelyTankAura ~= nil, client == 'forever', client .. ': the aura function is only on Forever')
		eq(#take_errors(), 0, client .. ": no error (retail has no UnitHasEffectivelyTankAura, and SaftUI doesn't call it there)")
	end

	-- A secret answer is no tank.
	local st, UF = world('forever')
	local restore = S.install()
	stub.units.party1.role = S.secret('ROLE')
	stub.tank_aura.party1 = S.secret('AURA')
	eq(UF.IsGroupTank('party1'), false, 'a secret role and a secret aura')
	stub.units.party1.role = 'TANK'
	eq(UF.IsGroupTank('party1'), true, 'the role alone')
	eq(#take_errors(), 0, 'no error')
	restore()
end)

test('a co-tank whose threat state is secret is skipped; one whose threat values alone are secret still holds the mob', function()
	local st, UF = world()
	stub.role = 'TANK'
	stub.units.party1.role = 'TANK'
	enemy('nameplate1')
	stub.threat.nameplate1 = { player = 0 }
	local frame = NP.add('nameplate1')
	local restore = S.install()
	-- The game makes party1's threat state with the mob secret: its state
	-- comes back secret.
	stub.secret_threat.nameplate1 = { party1 = true }
	stub.threat.nameplate1.party1 = S.secret('STATE')
	eq(UF:PlateThreat(frame), 'bad', 'a secret state: skipped')
	-- Only its threat values are secret (isTanking, the percents: on a boss
	-- the values are kept secret where the state isn't). Its state says it
	-- tanks the mob.
	stub.secret_threat.nameplate1 = nil
	stub.threat.nameplate1.party1 = { status = 3, isTanking = S.secret('VALUES'), percent = S.secret('PERCENT') }
	eq(UF:PlateThreat(frame), 'good', 'its state shows it holds the mob: good')
	stub.threat.nameplate1.party1 = { status = 2, isTanking = S.secret('VALUES') }
	eq(UF:PlateThreat(frame), 'good', 'status 2 is tanking too')
	stub.threat.nameplate1.party1 = { status = 1, isTanking = S.secret('VALUES') }
	eq(UF:PlateThreat(frame), 'bad', 'status 1 is not')
	eq(#take_errors(), 0, 'no error')
	restore()
end)

test("a tank: a mob loose on a group member who isn't a tank is bad, even off the tank's threat list; one nobody tanks shows nothing", function()
	local st, UF, P = world()
	stub.role = 'TANK'
	-- party1, the healer, has the mob; the tank isn't on its threat list.
	stub.units.party1.role = 'HEALER'
	enemy('nameplate1')
	stub.threat.nameplate1 = { party1 = 3 }
	local frame = NP.add('nameplate1')
	eq(UF:PlateThreat(frame), 'bad', 'loose on the healer')
	eq(frame.threatState, 'bad', 'tinted on its add')
	eq(bar(frame), color(st.config.profile.colors.threat.bad), 'in the bad colour')
	eq(frame.Threat:IsShown(), false, "no threat text: the tank isn't on its list")
	stub.threat.nameplate1.party1 = 2
	eq(UF:PlateThreat(frame), 'bad', 'status 2: still loose')
	stub.threat.nameplate1.party1 = 1
	eq(UF:PlateThreat(frame), nil, 'on the healer\'s list but not tanking: nothing')

	-- Nobody in the group tanks it.
	stub.threat.nameplate1 = {}
	eq(UF:PlateThreat(frame), nil, 'nobody has it')
	stub.threat.nameplate1 = { party1 = 0 }
	eq(UF:PlateThreat(frame), nil, 'nobody tanks it')
	-- Another tank has it: no tint for the tank who isn't on its list.
	stub.units.party1.role = 'TANK'
	stub.threat.nameplate1 = { party1 = 3 }
	eq(UF:PlateThreat(frame), nil, 'another tank holds it')
	-- A damage dealer or healer sees nothing for a mob on someone else.
	stub.units.party1.role = 'HEALER'
	stub.role = 'DAMAGER'
	eq(UF:PlateThreat(frame), nil, 'not a tank: nothing')
	-- A secret state of the member's is skipped.
	stub.role = 'TANK'
	local restore = S.install()
	stub.threat.nameplate1 = { party1 = S.secret('STATE') }
	eq(UF:PlateThreat(frame), nil, "the healer's state secret: nothing")
	restore()
	-- On your own there's nobody else.
	stub.group = nil
	P.threat_solo = true
	stub.threat.nameplate1 = {}
	eq(UF:PlateThreat(frame), nil, 'solo with Threat when solo: nothing')
	eq(#take_errors(), 0, 'no error')
end)

test('a raid of 40: the scan reads the threat state of each member until the one tanking the mob, and asks only that one for its role', function()
	local st, UF = world()
	stub.role = 'TANK'
	local members = {}
	for i = 1, 40 do members[i] = 'raid' .. i end
	stub.group = { raid = true, members = members }
	stub.units.raid5 = { name = 'Offtank', player = true, friend = true, role = 'TANK' }
	enemy('nameplate1')
	stub.threat.nameplate1 = { player = 0, raid5 = 3, raid30 = 3 }
	local frame = NP.add('nameplate1')
	local reads, roles, auras = {}, {}, 0
	local realSituation, realRole, realAura = UnitThreatSituation, UnitGroupRolesAssigned, UnitHasEffectivelyTankAura
	UnitThreatSituation = function(unit, mob)
		if unit ~= 'player' then reads[#reads + 1] = unit end
		return realSituation(unit, mob)
	end
	UnitGroupRolesAssigned = function(unit)
		if unit and unit ~= 'player' then roles[#roles + 1] = unit end
		return realRole(unit)
	end
	UnitHasEffectivelyTankAura = function(unit)
		if unit ~= 'player' then auras = auras + 1 end
		return realAura(unit)
	end
	local state = UF:PlateThreat(frame)
	UnitThreatSituation, UnitGroupRolesAssigned, UnitHasEffectivelyTankAura = realSituation, realRole, realAura
	eq(state, 'good', 'raid5, a tank, holds it')
	eq(table.concat(reads, ','), 'raid1,raid2,raid3,raid4,raid5', 'states read up to raid5, then no more')
	eq(table.concat(roles, ','), 'raid5', "only raid5's role read")
	eq(auras, 0, "and no member's aura, raid5's role being enough")
end)

test('no threat entry shows nothing; a secret threat state shows nothing, with no error', function()
	local st, UF = world()
	enemy('nameplate1')
	stub.threat.nameplate1 = {}
	local frame = NP.add('nameplate1')
	eq(UF:PlateThreat(frame), nil, 'the player is not on its threat list')
	ouf_colours(frame)
	UF:UpdatePlateThreat(frame)
	eq(frame.threatState, nil, 'no state')
	eq(bar(frame), rgb(unpack(HOSTILE)), "the bar keeps oUF's colour")

	stub.threat.nameplate1 = { player = 3 }
	stub.secret_threat.nameplate1 = true
	eq(UF:PlateThreat(frame), nil, 'the game says the threat state is secret')

	local restore = S.install()
	stub.secret_threat.nameplate1 = nil
	stub.threat.nameplate1 = { player = S.secret('STATUS') }
	eq(UF:PlateThreat(frame), nil, 'a secret status')
	threat_changed('nameplate1')
	eq(frame.threatState, nil, 'no state')
	ouf_colours(frame)
	eq(bar(frame), rgb(unpack(HOSTILE)), "oUF's colour")
	eq(frame.Threat:IsShown(), false, 'no threat text')
	eq(#take_errors(), 0, 'no error')
	restore()
end)

test('solo: no tint unless Threat when solo is on', function()
	local st, UF, P = world()
	stub.group = nil
	local frame = add_enemy('nameplate1', 3)
	eq(UF:PlateThreat(frame), nil, 'on your own, Threat when solo off')
	eq(frame.threatState, nil, 'not tinted')
	eq(frame.Threat:IsShown(), false, 'no threat text')
	P.threat_solo = true
	eq(UF:PlateThreat(frame), 'bad', 'with Threat when solo on')
	-- The option's set runs UF:UpdateConfig('nameplate').
	UF:UpdateConfig('nameplate')
	eq(frame.threatState, 'bad', 'the plate is tinted by the update')
	eq(frame.Threat:IsShown(), true, 'and shows the text')
end)

test('a friendly plate is never tinted', function()
	local st, UF = world()
	friend('nameplate1')
	stub.threat.nameplate1 = { player = 3 }
	local frame = NP.add('nameplate1')
	eq(UF:PlateThreat(frame), nil, 'a friend')
	eq(frame.threatState, nil, 'no state')
	eq(frame.Threat:IsShown(), false, 'no threat text')
	eq(UF.PLATE_ENEMY_ONLY.Threat, true, "the text is an enemy plate's part")
end)

------------------------------------------------------------------ the tint

test("warning and bad replace the bar's colour every time oUF colours it; good gives oUF's colour back", function()
	local st, UF = world()
	local threat = st.config.profile.colors.threat
	local frame = add_enemy('nameplate1', 3)
	eq(frame.threatState, 'bad', 'bad on its add')
	eq(bar(frame), color(threat.bad), 'tinted at once')
	ouf_colours(frame)
	eq(bar(frame), color(threat.bad), "the threat colour wins when oUF colours the bar")

	-- Over a custom colour too.
	frame.Health.config.colorCustom = true
	ouf_colours(frame)
	eq(bar(frame), color(threat.bad), 'over Custom')
	frame.Health.config.colorCustom = false

	stub.threat.nameplate1.player = 1
	threat_changed('nameplate1')
	eq(frame.threatState, 'warning', 'warning')
	eq(bar(frame), color(threat.warning), 'in the warning colour')
	ouf_colours(frame)
	eq(bar(frame), color(threat.warning), 'kept when oUF colours the bar')

	local before = forced(frame)
	stub.threat.nameplate1.player = 0
	threat_changed('nameplate1')
	eq(frame.threatState, 'good', 'good')
	eq(forced(frame) - before, 1, "Health:ForceUpdate once, for oUF's colour")
	ouf_colours(frame)
	eq(bar(frame), rgb(unpack(HOSTILE)), "oUF's colour stays")

	before = forced(frame)
	stub.threat.nameplate1 = {}
	threat_changed('nameplate1')
	eq(frame.threatState, nil, 'off the list')
	eq(forced(frame) - before, 0, 'no tint to take off: no update')
end)

test("the role comes from Blizzard's effectively-tank check: Forever's tank aura first", function()
	local st, UF = world('forever')
	stub.role = 'DAMAGER'
	stub.tank_aura.player = true
	local frame = add_enemy('nameplate1', 3)
	eq(UF:PlateThreat(frame), 'good', 'Forever: the tank aura makes a damage dealer a tank')
	stub.tank_aura.player = nil
	eq(UF:PlateThreat(frame), 'bad', 'and without it, a damage dealer')

	st, UF = world('retail')
	stub.role = 'NONE'
	stub.spec_role = 'TANK'
	frame = add_enemy('nameplate1', 3)
	eq(UF:PlateThreat(frame), 'good', "retail: no role, a tank's spec")
	stub.role = 'DAMAGER'
	eq(UF:PlateThreat(frame), 'bad', 'an assigned role over the spec')
	eq(#take_errors(), 0, 'no error')
end)

test('threat, group and role events retint the plates', function()
	local st, UF = world()
	local one, two = add_enemy('nameplate1', 3), add_enemy('nameplate2', 3)
	eq(one.threatState, 'bad', 'one bad')
	eq(two.threatState, 'bad', 'two bad')
	stub.threat.nameplate1.player, stub.threat.nameplate2.player = 0, 0
	threat_changed('nameplate1')
	eq(one.threatState, 'good', "the list update's plate")
	eq(two.threatState, 'bad', 'only that plate')
	threat_changed('nameplate2')
	eq(two.threatState, 'good', 'then the other')
	threat_changed('target')
	threat_changed('boss1')
	eq(#take_errors(), 0, 'a unit with no plate of SaftUI is ignored')

	local status = 0
	for _, event in ipairs({ 'UNIT_THREAT_SITUATION_UPDATE', 'GROUP_ROSTER_UPDATE', 'PLAYER_ROLES_ASSIGNED', 'PLAYER_SPECIALIZATION_CHANGED', 'UPDATE_SHAPESHIFT_FORM' }) do
		status = status == 0 and 3 or 0
		stub.threat.nameplate1.player, stub.threat.nameplate2.player = status, status
		local want = status == 3 and 'bad' or 'good'
		stub.fire_event(event, event:find('^UNIT_') and 'player' or nil)
		eq(one.threatState, want, event .. ': nameplate1')
		eq(two.threatState, want, event .. ': nameplate2')
	end

	-- A plate the game took away keeps nothing, and isn't updated again.
	NP.remove('nameplate2')
	eq(two.threatState, nil, 'taken away: no state')
	eq(two.Threat:IsShown(), false, 'and no text')
	stub.threat.nameplate2.player = 3
	stub.fire_event('UNIT_THREAT_SITUATION_UPDATE', 'player')
	eq(two.threatState, nil, 'a plate showing no unit stays untinted')
end)

test("a threat situation change retints every plate for the player's, one plate for a plate's unit, and none for a group member's", function()
	local st, UF = world()
	local one, two = add_enemy('nameplate1', 3), add_enemy('nameplate2', 3)
	stub.threat.nameplate1.player, stub.threat.nameplate2.player = 0, 0
	stub.fire_event('UNIT_THREAT_SITUATION_UPDATE', 'party1')
	eq(one.threatState .. ',' .. two.threatState, 'bad,bad', "a member's: no plate (the mob's own list update follows)")
	stub.fire_event('UNIT_THREAT_SITUATION_UPDATE', 'nameplate2')
	eq(one.threatState .. ',' .. two.threatState, 'bad,good', "a plate's unit: that plate")
	stub.fire_event('UNIT_THREAT_SITUATION_UPDATE', 'player')
	eq(one.threatState .. ',' .. two.threatState, 'good,good', "the player's: every plate")

	-- A unit token that's no plate's isn't looked for among the plates.
	local looked = 0
	local real = UF.PlateForUnit
	UF.PlateForUnit = function(...) looked = looked + 1 return real(...) end
	for _, unit in ipairs({ 'target', 'focus', 'boss1', 'mouseover', 'party1' }) do
		stub.fire_event('UNIT_THREAT_LIST_UPDATE', unit)
		stub.fire_event('UNIT_THREAT_SITUATION_UPDATE', unit)
	end
	eq(looked, 0, 'no plate looked for')
	threat_changed('nameplate1')
	eq(looked, 1, "a plate's unit is")
	UF.PlateForUnit = real
	eq(#take_errors(), 0, 'no error')
end)

test('a unit that turns friendly loses its tint at once, and an enemy again gets it back', function()
	local st, UF = world()
	local frame = add_enemy('nameplate1', 3)
	eq(frame.threatState, 'bad', 'bad')
	local before = forced(frame)
	stub.units.nameplate1.friend, stub.units.nameplate1.attackable = true, false
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	eq(frame.friendly, true, 'a friend now')
	eq(frame.threatState, nil, 'no tint')
	eq(forced(frame) - before, 1, "oUF's colour back")
	eq(frame.Threat:IsShown(), false, 'no threat text')
	stub.units.nameplate1.friend, stub.units.nameplate1.attackable = false, true
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	eq(frame.threatState, 'bad', 'an enemy again: tinted')
	eq(frame.Threat:IsShown(), true, 'with its text')
end)

test('a plate handed from an enemy to a friend keeps no tint', function()
	local st, UF = world()
	local frame = add_enemy('nameplate1', 3)
	eq(frame.threatState, 'bad', 'the enemy: bad')
	NP.remove('nameplate1')
	friend('nameplate2')
	stub.threat.nameplate2 = { player = 3 }
	eq(NP.add('nameplate2', { plate = 1 }), frame, 'the same frame')
	eq(frame.threatState, nil, 'the friend: none')
	eq(frame.Threat:IsShown(), false, 'no text')
	ouf_colours(frame)
	eq(bar(frame), rgb(unpack(HOSTILE)), "oUF's colour")
end)

------------------------------------------------------------------ the Colors tab

test('the Colors tab: Threat with Warning and Bad at their defaults; a change retints every plate', function()
	local st, UF = world()
	eq(color(st.defaults.colors.threat.warning), '1.00,0.60,0.00', 'warning default')
	eq(color(st.defaults.colors.threat.bad), '1.00,0.10,0.10', 'bad default')
	local section = st:GetModule('Colors'):GetConfigTable().args.threat
	eq(section.name, 'Threat', 'the section')
	eq(section.args.warning.name, 'Warning', 'Warning')
	eq(section.args.bad.name, 'Bad', 'Bad')
	eq(rgb(section.args.warning.get()), '1.00,0.60,0.00', "Warning's swatch")
	eq(rgb(section.args.bad.get()), '1.00,0.10,0.10', "Bad's swatch")

	local frame = add_enemy('nameplate1', { status = 3, percent = 100 })
	local hidden = add_enemy('nameplate2', 3)
	NP.remove('nameplate2')
	local before, beforeShown = forced(hidden), forced(frame)
	section.args.bad.set({}, 0.5, 0, 0.5)
	eq(bar(frame), '0.50,0.00,0.50', "the tinted plate's bar")
	eq(rgb(frame.Threat:GetTextColor()), '0.50,0.00,0.50', 'and its threat text')
	eq(forced(frame) - beforeShown, 0, 'retinted as it is: no oUF update, as the picker sets a colour on every move')
	ouf_colours(frame)
	eq(bar(frame), '0.50,0.00,0.50', 'oUF colouring the bar again keeps the new colour')
	eq(forced(hidden) - before, 0, 'a plate showing no unit is left alone')
	section.args.reset.func()
	eq(bar(frame), '1.00,0.10,0.10', 'Reset puts it back')
end)

test('a reputation colour change recolours the plates showing a unit, never one the game took away', function()
	local st, UF = world()
	local shown = add_enemy('nameplate1', 3)
	local hidden = add_enemy('nameplate2', 3)
	NP.remove('nameplate2')
	local beforeShown, beforeHidden = forced(shown), forced(hidden)
	st:ColorsChanged('reaction')
	eq(forced(shown) - beforeShown, 1, "a plate showing its unit: oUF colours its bar again")
	eq(forced(hidden) - beforeHidden, 0, 'a plate that keeps the unit it last showed is left alone')
end)

------------------------------------------------------------------ the threat text

test('the threat text: your percent above the bar, in the tint, and the normal text colour while good', function()
	local st, UF = world()
	local threat, normal = st.config.profile.colors.threat, st.config.profile.colors.text.normal
	local frame = add_enemy('nameplate1', { status = 1, percent = 85 })
	local text = frame.Threat
	eq(text:IsShown(), true, 'shown')
	eq(text:GetText(), '85%', 'the percent')
	eq(rgb(text:GetTextColor()), color(threat.warning), 'warning')

	stub.threat.nameplate1.player = { status = 3, percent = 100 }
	threat_changed('nameplate1')
	eq(text:GetText(), '100%', 'the mob on you')
	eq(rgb(text:GetTextColor()), color(threat.bad), 'bad')

	stub.threat.nameplate1.player = { status = 0, percent = 42.6 }
	threat_changed('nameplate1')
	eq(text:GetText(), '43%', 'a whole percent')
	eq(rgb(text:GetTextColor()), color(normal), 'good: the normal text colour')
	eq(text:IsShown(), true, 'still shown')

	stub.threat.nameplate1 = {}
	threat_changed('nameplate1')
	eq(text:IsShown(), false, 'off the list: hidden')

	-- A tank's too.
	stub.role = 'TANK'
	stub.threat.nameplate1 = { player = { status = 2, percent = 100 } }
	threat_changed('nameplate1')
	eq(text:GetText(), '100%', "a tank's")
	eq(rgb(text:GetTextColor()), color(threat.warning), 'about to lose it: warning')
end)

test('the threat text shows only where the tint would: in a group, or solo with Threat when solo on, never on a secret state', function()
	local st, UF, P = world()
	local frame = add_enemy('nameplate1', { status = 3, percent = 100 })
	eq(frame.Threat:IsShown(), true, 'in a party')
	stub.group = nil
	stub.fire_event('GROUP_ROSTER_UPDATE')
	eq(frame.Threat:IsShown(), false, 'on your own')
	P.threat_solo = true
	UF:UpdateConfig('nameplate')
	eq(frame.Threat:IsShown(), true, 'on your own with Threat when solo on')
	stub.secret_threat.nameplate1 = true
	threat_changed('nameplate1')
	eq(frame.Threat:IsShown(), false, 'a secret state')
	stub.secret_threat.nameplate1 = nil
	threat_changed('nameplate1')
	eq(frame.Threat:IsShown(), true, 'shown again')
	P.threat.enable = false
	UF:UpdateConfig('nameplate', 'Threat')
	eq(frame.Threat:IsShown(), false, 'turned off')
	eq(frame.threatState, 'bad', 'the tint stays: it has no switch of its own')
end)

test('a secret percent is handed to the game to write, with no error', function()
	local st, UF = world()
	local frame = add_enemy('nameplate1', { status = 3, percent = 100 })
	-- The stub's font string takes plain values only (.agents/testing.md,
	-- rule 4), so this one records what it's handed.
	local got
	frame.Threat.SetFormattedText = function(_, format, value) got = { format, value } end
	local restore = S.install()
	local percent = S.secret('PERCENT')
	stub.threat.nameplate1.player = { status = 3, percent = percent }
	threat_changed('nameplate1')
	check(got ~= nil, 'written')
	eq(got and got[1], '%.0f%%', 'as a whole percent')
	eq(got and got[2], percent, 'the secret itself')
	eq(frame.Threat:IsShown(), true, 'shown')
	eq(#take_errors(), 0, 'no error')
	restore()
end)

test("the Threat tab: Enable, Font, Alpha and Position, on the plates only; small, above the bar's right end", function()
	local st, UF, P = world()
	local tab = UF:GetConfigTable().args.nameplate.args.Threat
	check(tab ~= nil, 'the Nameplates page has a Threat tab')
	if not tab then return end
	eq(tab.name, 'Threat', 'its name')
	local keys = {}
	for key in pairs(tab.args) do keys[#keys + 1] = key end
	table.sort(keys)
	eq(table.concat(keys, ','), 'alpha,enable,font,position', 'its options')
	for key, option in pairs(tab.args) do
		check(type(option.desc) == 'string' and option.desc ~= '', key .. ' has a desc')
		check(key == 'position' or option.order < tab.args.position.order, 'Position after ' .. key)
	end
	for _, unit in ipairs({ 'player', 'target', 'party', 'raid40', 'boss' }) do
		eq(UF.elements.Threat.ValidUnit(unit), false, unit .. ' has none')
	end

	eq(P.threat.enable, true, 'on')
	eq(P.threat.font, 'pixel', 'the small font')
	local frame = add_enemy('nameplate1', { status = 3, percent = 100 })
	local point, relativeTo, relativePoint, x, y = frame.Threat:GetPoint(1)
	eq(point, 'BOTTOMRIGHT', 'its bottom right')
	eq(relativeTo, frame.Health, 'on the health bar')
	eq(relativePoint, 'TOPRIGHT', "at the bar's top right")
	eq(x, 0, 'no x offset')
	eq(y, 6, '6 above, level with the debuffs')

	tab.set({ 'Unitframes', 'nameplate', 'Threat', 'enable' }, false)
	eq(P.threat.enable, false, 'Enable saved')
	eq(frame.Threat:IsShown(), false, 'and the text hidden at once')
	tab.set({ 'Unitframes', 'nameplate', 'Threat', 'enable' }, true)
	eq(frame.Threat:IsShown(), true, 'shown again')
	eq(tab.get({ 'Unitframes', 'nameplate', 'Threat', 'font' }), 'pixel', 'Font read')
end)
