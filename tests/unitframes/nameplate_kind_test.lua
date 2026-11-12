-- Each add of a plate (SaftUI-Unitframes/nameplates/nameplates.lua, with
-- updaters.lua's UF:ElementWanted, which the castbar, the indicators and the
-- aura areas read):
--   - an enemy's plate shows every part; a friendly plate
--     (UF.IsFriendlyPlate) carries the bar, the name, the health text and the
--     raid mark, its enemy-only parts (UF.PLATE_ENEMY_ONLY) disabled in oUF,
--     turned off and hidden. Set on every add, again when the unit's faction
--     changes, and when a config change turns a part on or off;
--   - a plate reused for the other kind, after a plate that showed only
--     widgets too (oUF's resume turns its parts on again);
--   - Blizzard's widgets and soft target icon moved onto the plate on every
--     add, widget-only plates too; forbidden plates left alone.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), with Blizzard's plate frames locked.
local NP = load_test_file('unitframes/nameplate_world.lua')
local S = load_test_file('lib/secrets.lua')

-- A world with every part of a plate on, the plates spawned. Task 7 makes the
-- castbar, the aura areas and the quest icon on the plate's defaults, with the
-- castbar and its spell name placed by numbers (every unit's castbar default
-- has its offsets as strings, which the stubbed SetPoint refuses) and no time.
local function world(client)
	local st, UF = NP.world(client or 'forever')
	local P = UF:GetProfileConfig().nameplate
	for _, key in ipairs({ 'castbar', 'buffs', 'debuffs', 'questindicator', 'raidtargetindicator' }) do
		P[key].enable = true
	end
	P.castbar.position = { point = 'TOPRIGHT', element = 'Health', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -6 }
	P.castbar.text.position = { point = 'LEFT', element = 'Castbar', rel_point = 'LEFT', x_off = 4, y_off = 0 }
	P.castbar.time.enable = false
	UF:SpawnNameplates()
	return st, UF, P
end

-- The game's answers for a unit: UnitIsFriend('player', unit) and
-- UnitCanAttack('player', unit).
local function unit_is(unit, friend, attackable)
	stub.units[unit] = { name = unit, friend = friend, attackable = attackable }
end
local function friend(unit) unit_is(unit, true, false) end
local function enemy(unit) unit_is(unit, false, true) end

-- Checks a plate's frame carries an enemy's parts (enemy true) or a friend's.
-- The castbar, the quest icon and the raid mark are shown by oUF's own
-- updates (a cast, a quest unit, a mark), which the stand-in doesn't run; for
-- those, shown here means SaftUI left them to oUF (UF:SetElementEnabled and
-- UF:ApplyPlateKind show them, after oUF's castbar Enable hid the bar), and
-- the oUF update after an add decides. Hidden means SaftUI hid them.
local function check_kind(frame, enemy, label)
	for _, name in ipairs({ 'Castbar', 'QuestIndicator' }) do
		eq(frame:IsElementEnabled(name) == true, enemy, label .. ': ' .. name .. (enemy and ' enabled in oUF' or ' disabled in oUF'))
		eq(frame[name]:IsShown(), enemy, label .. ': ' .. name .. (enemy and ' left to oUF' or ' hidden'))
	end
	for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
		eq(frame[name].enabled, enemy, label .. ': ' .. name .. (enemy and ' on' or ' off'))
		eq(frame[name]:IsShown(), enemy, label .. ': ' .. name .. (enemy and ' shown' or ' hidden'))
	end
	eq(frame.Health:IsShown(), true, label .. ': the bar shown')
	eq(frame.Name:IsShown(), true, label .. ': the name shown')
	eq(frame.Health.text:IsShown(), true, label .. ': the health text shown')
	eq(frame.RaidTargetIndicator:IsShown(), true, label .. ': the raid mark left to oUF')
	eq(frame.friendly, not enemy, label .. ': frame.friendly')
end

------------------------------------------------------------------ kinds

test('an enemy plate shows every part; a friendly plate carries the bar, name, health text and raid mark', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		enemy('nameplate1')
		local foe = NP.add('nameplate1')
		check_kind(foe, true, client .. ': enemy')

		friend('nameplate2')
		local ally = NP.add('nameplate2')
		check_kind(ally, false, client .. ': friend')
		local disabled = {}
		for _, call in ipairs(NP.ouf.calls) do
			if call[1] == ally and call[2] == 'DisableElement' then disabled[call[3]] = true end
		end
		check(disabled.Castbar and disabled.QuestIndicator, client .. ": the castbar and quest icon disabled through oUF's DisableElement")
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('a friendly plate never shows a cast', function()
	local st, UF = world()
	friend('nameplate1')
	local frame = NP.add('nameplate1')
	local castbar = frame.Castbar
	castbar:Show()
	eq(castbar.ShouldShow(castbar, 'nameplate1'), false, "oUF skips the friend's cast")
	eq(castbar:IsShown(), false, 'and the castbar is hidden')

	-- The quest icon too: oUF shows it by its own rules, and its PostUpdate
	-- hides it again.
	local quest = frame.QuestIndicator
	quest:Show()
	quest.PostUpdate(quest)
	eq(quest:IsShown(), false, 'the quest icon hidden after an update')

	enemy('nameplate2')
	local foe = NP.add('nameplate2')
	eq(foe.Castbar.ShouldShow(foe.Castbar, 'nameplate2'), true, "an enemy's cast shows")
	eq(foe.Castbar.ShouldShow(foe.Castbar, 'nameplate1'), false, "and only its own unit's")
	foe.QuestIndicator:Show()
	foe.QuestIndicator.PostUpdate(foe.QuestIndicator)
	eq(foe.QuestIndicator:IsShown(), true, "an enemy's quest icon stays")
end)

test('a plate reused for an enemy shows the enemy parts, placed', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		friend('nameplate1')
		local frame = NP.add('nameplate1')
		check_kind(frame, false, client .. ': first a friend')

		-- The castbar moved in the options while the plate shows a friend: a
		-- part the plate hides is still placed, ready for the next enemy.
		P.castbar.position = { point = 'TOP', element = 'Health', rel_point = 'BOTTOM', x_off = 2, y_off = -8 }
		P.debuffs.position = { point = 'BOTTOMLEFT', element = 'Health', rel_point = 'TOPLEFT', x_off = 0, y_off = 6 }
		UF:UpdateConfig('nameplate')
		check_kind(frame, false, client .. ': still a friend after the update')

		NP.remove('nameplate1')
		enemy('nameplate2')
		local mark = #NP.ouf.calls
		eq(NP.add('nameplate2', { plate = 1 }), frame, client .. ': the same frame for the enemy')
		check_kind(frame, true, client .. ': then an enemy')

		-- oUF's order on a reused plate: the new unit attribute updates every
		-- element once with the old kind's set (the castbar still disabled),
		-- then the added callback sets the kind, then oUF updates again.
		local seen = {}
		for i = mark + 1, #NP.ouf.calls do
			local call = NP.ouf.calls[i]
			if call[1] == frame and (call[2] == 'UpdateAllElements' or call[3] == 'Castbar') then
				seen[#seen + 1] = call[2] .. ' ' .. call[3]
			end
		end
		eq(table.concat(seen, ', '),
			'UpdateAllElements OnAttributeChanged, EnableElement Castbar, UpdateAllElements NAME_PLATE_UNIT_ADDED',
			client .. ": oUF's early update, the kind, then oUF's update")

		for _, part in ipairs({ { 'Castbar', P.castbar.position }, { 'Debuffs', P.debuffs.position } }) do
			local element, position = frame[part[1]], part[2]
			local point, relativeTo, relativePoint, x, y = element:GetPoint(1)
			eq(point, position.point, client .. ': ' .. part[1] .. "'s point")
			eq(relativeTo, frame.Health, client .. ': ' .. part[1] .. ' on the bar')
			eq(relativePoint, position.rel_point, client .. ': ' .. part[1] .. "'s relative point")
			eq(x, position.x_off, client .. ': ' .. part[1] .. "'s x offset")
			eq(y, position.y_off, client .. ': ' .. part[1] .. "'s y offset")
		end
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('an attackable friend counts as an enemy, and a secret answer too', function()
	local st, UF = world()
	friend('nameplate1')
	eq(UF.IsFriendlyPlate('nameplate1'), true, 'a friend')
	enemy('nameplate2')
	eq(UF.IsFriendlyPlate('nameplate2'), false, 'an enemy')
	eq(UF.IsFriendlyPlate('nameplate9'), false, 'a unit that is not there')

	-- A cross-faction player in your party, outside an instance: friendly,
	-- and attackable.
	unit_is('nameplate3', true, true)
	eq(UF.IsFriendlyPlate('nameplate3'), false, 'an attackable friend')
	check_kind(NP.add('nameplate3'), true, 'an attackable friend')

	local restore = S.install()
	unit_is('nameplate4', S.secret('FRIEND'), false)
	eq(UF.IsFriendlyPlate('nameplate4'), false, 'a secret friend answer')
	check_kind(NP.add('nameplate4'), true, 'a secret friend answer')
	unit_is('nameplate5', true, S.secret('ATTACKABLE'))
	eq(UF.IsFriendlyPlate('nameplate5'), false, 'a secret attackable answer')
	check_kind(NP.add('nameplate5'), true, 'a secret attackable answer')
	restore()
	eq(#take_errors(), 0, 'no error')
end)

test('a unit turning hostile gets the enemy parts at once', function()
	local st, UF = world()
	friend('nameplate1')
	local frame = NP.add('nameplate1')
	check_kind(frame, false, 'a friend')

	local updates = frame.__updates
	enemy('nameplate1')
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	check_kind(frame, true, 'hostile')
	check(frame.__updates > updates, "updated, so each part shows its unit's state (a castbar with no cast hides)")

	friend('nameplate1')
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	check_kind(frame, false, 'friendly again')

	-- The player's own faction changing (a PvP flag) can change every plate's.
	enemy('nameplate1')
	stub.fire_event('UNIT_FACTION', 'player')
	check_kind(frame, true, "the player's faction changed")

	-- Another unit's, or a plate's that left: nothing changes.
	friend('nameplate1')
	stub.fire_event('UNIT_FACTION', 'target')
	stub.fire_event('UNIT_FACTION', 'nameplate7')
	check_kind(frame, true, "another unit's faction")
	NP.remove('nameplate1')
	updates = frame.__updates
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	stub.fire_event('UNIT_FACTION', 'player')
	eq(frame.friendly, false, 'a plate that left keeps its kind until its next add')
	eq(frame.__updates, updates, 'and is not updated')
	eq(#take_errors(), 0, 'no error')
end)

test('a part turned on or off in the options follows on a plate that shows its unit', function()
	local st, UF, P = world()
	P.castbar.enable = false
	P.questindicator.enable = false
	enemy('nameplate1')
	local frame = NP.add('nameplate1')
	check(not frame:IsElementEnabled('Castbar'), 'off in the options: the castbar disabled in oUF')
	check(not frame:IsElementEnabled('QuestIndicator'), 'and the quest icon')

	-- Watched: the frame's oUF calls, in order.
	local log = {}
	local enable, update = frame.EnableElement, frame.UpdateAllElements
	frame.EnableElement = function(self, name, ...)
		log[#log + 1] = 'enable ' .. name
		return enable(self, name, ...)
	end
	frame.UpdateAllElements = function(self, event)
		log[#log + 1] = 'update'
		return update(self, event)
	end

	P.castbar.enable = true
	UF:UpdateConfig('nameplate', 'Castbar')
	eq(frame:IsElementEnabled('Castbar'), true, 'turned on: enabled in oUF')
	eq(frame.Castbar:IsShown(), false, "hidden by oUF's Enable: the update after it shows a cast")
	local enabledAt
	for i, entry in ipairs(log) do
		if entry == 'enable Castbar' then enabledAt = i end
	end
	check(enabledAt and log[#log] == 'update' and #log > enabledAt,
		"updated after it's enabled, so it shows its unit's state: " .. table.concat(log, ', '))

	P.questindicator.enable = true
	UF:UpdateConfig('nameplate', 'QuestIndicator')
	eq(frame:IsElementEnabled('QuestIndicator'), true, 'the quest icon turned on')

	P.castbar.enable = false
	UF:UpdateConfig('nameplate', 'Castbar')
	check(not frame:IsElementEnabled('Castbar'), 'turned off: disabled in oUF')
	eq(frame.Castbar:IsShown(), false, 'and hidden')

	-- On a friend's plate, turning it on leaves it off.
	friend('nameplate2')
	local ally = NP.add('nameplate2')
	P.castbar.enable = true
	UF:UpdateConfig('nameplate')
	check(not ally:IsElementEnabled('Castbar'), "a friend's castbar stays disabled")
	eq(ally.Castbar:IsShown(), false, 'and hidden')
	eq(frame:IsElementEnabled('Castbar'), true, "the enemy's on again")
	frame.EnableElement, frame.UpdateAllElements = enable, update

	-- A plate that shows no unit (gone, or showing only widgets) keeps its
	-- parts as they are, its old unit's kind and __unit stale, until its next
	-- add sets them.
	P.castbar.enable = false
	UF:UpdateConfig('nameplate', 'Castbar')
	NP.remove('nameplate1')
	P.castbar.enable = true
	UF:UpdateConfig('nameplate', 'Castbar')
	check(not frame:IsElementEnabled('Castbar'), 'a plate that left: its castbar not enabled for the unit that left')
	NP.add('nameplate3', { plate = 1, widgets_only = true })
	UF:UpdateConfig('nameplate', 'Castbar')
	check(not frame:IsElementEnabled('Castbar'), 'nor while it shows only widgets')
	NP.remove('nameplate3')
	enemy('nameplate4')
	NP.add('nameplate4', { plate = 1 })
	eq(frame:IsElementEnabled('Castbar'), true, 'enabled by the next add')
	eq(#take_errors(), 0, 'no error')
end)

test('a plate that showed only widgets gets its kind back when it is reused', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		-- oUF's resume, when the widget-only unit leaves, turns every aura
		-- area on and shows the bar whatever the config says.
		P.health.enable = false
		friend('nameplate1')
		local frame = NP.add('nameplate1')
		eq(frame.Health:IsShown(), false, client .. ': the bar off in the options')
		NP.remove('nameplate1')

		NP.add('nameplate2', { plate = 1, widgets_only = true })
		eq(frame:IsShown(), false, client .. ': widgets only: the frame hidden')
		UF:UpdateConfig('nameplate')
		eq(frame:IsElementPaused('Health'), true, client .. ': a config update leaves it paused')
		NP.remove('nameplate2')
		eq(frame.Buffs.enabled, true, client .. ": oUF's resume turned the buffs on")
		eq(frame.Health:IsShown(), true, client .. ": and showed the bar")

		friend('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		eq(frame.Health:IsShown(), false, client .. ': a friend: the bar off again')
		for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
			eq(frame[name].enabled, false, client .. ': a friend: ' .. name .. ' off again')
			eq(frame[name]:IsShown(), false, client .. ': a friend: ' .. name .. ' hidden')
		end
		check(not frame:IsElementEnabled('Castbar'), client .. ': a friend: the castbar disabled')

		NP.remove('nameplate3')
		NP.add('nameplate4', { plate = 1, game_object = true })
		NP.remove('nameplate4')
		enemy('nameplate5')
		NP.add('nameplate5', { plate = 1 })
		eq(frame.Health:IsShown(), false, client .. ': an enemy: the bar off again')
		eq(frame:IsElementEnabled('Castbar'), true, client .. ': an enemy: the castbar enabled')
		eq(frame.Castbar:IsShown(), true, client .. ": and left to oUF's update")
		for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
			eq(frame[name].enabled, true, client .. ': an enemy: ' .. name .. ' on')
			eq(frame[name]:IsShown(), true, client .. ': an enemy: ' .. name .. ' shown')
		end

		-- And an enemy's plate that showed only widgets, reused for an enemy.
		NP.remove('nameplate5')
		NP.add('nameplate6', { plate = 1, widgets_only = true })
		NP.remove('nameplate6')
		enemy('nameplate7')
		NP.add('nameplate7', { plate = 1 })
		eq(frame.Health:IsShown(), false, client .. ': enemy after enemy: the bar off')
		eq(frame:IsElementEnabled('Castbar'), true, client .. ': enemy after enemy: the castbar enabled')
		check(not frame:IsElementPaused('Castbar'), client .. ': and running')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('kinds are applied after init: a first add of a friendly plate raises no error', function()
	local st, UF = world()
	friend('nameplate1')
	local frame = NP.add('nameplate1')
	eq(#take_errors(), 0, "no error: oUF's EnableElement and DisableElement ran on an initialized frame")
	check(NP.ouf.IsInitialized(frame), 'initialized')
	check(not frame:IsElementEnabled('Castbar'), 'the castbar disabled')
	eq(frame.friendly, true, 'a friend')
end)

------------------------------------------------------------------ Blizzard's widgets

-- Checks the UnitFrame Blizzard gave plate has its widgets and soft target
-- icon on the plate, by one point: the widgets' top on the plate's bottom, or
-- for a plate that shows only widgets (widgetsOnly) their bottom on it.
local function check_widgets(plate, label, widgetsOnly)
	local unitFrame = rawget(plate, 'UnitFrame')
	local widgets, softTarget = rawget(unitFrame, 'WidgetContainer'), rawget(unitFrame, 'SoftTargetFrame')
	eq(widgets:GetParent(), plate, label .. ': the widgets on the plate')
	eq(widgets:GetNumPoints(), 1, label .. ': by one point')
	local point, relativeTo, relativePoint = widgets:GetPoint(1)
	eq(point, widgetsOnly and 'BOTTOM' or 'TOP', label .. (widgetsOnly and ': their bottom' or ': their top'))
	eq(relativeTo, plate, label .. ': to the plate')
	eq(relativePoint, 'BOTTOM', label .. ': its bottom')
	eq(softTarget:GetParent(), plate, label .. ': the soft target icon on the plate')
end

test('widgets move to the plate on every add, widget-only plates too', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local added = 0
		UF:RegisterPlateCallback('added', function() added = added + 1 end)
		enemy('nameplate1')
		NP.add('nameplate1')
		check_widgets(NamePlate1, client .. ': the first add')
		NP.remove('nameplate1')
		-- Blizzard hands the plate a new UnitFrame from its pool.
		enemy('nameplate2')
		NP.add('nameplate2', { plate = 1 })
		check_widgets(NamePlate1, client .. ': the second add')
		eq(added, 2, client .. ': two added callbacks')

		NP.add('nameplate3', { widgets_only = true })
		check_widgets(NamePlate2, client .. ': a widget-only plate', true)
		NP.add('nameplate4', { game_object = true })
		check_widgets(NamePlate3, client .. ': a game object')
		NP.remove('nameplate3')
		NP.add('nameplate5', { plate = 2, widgets_only = true })
		check_widgets(NamePlate2, client .. ': a widget-only plate again', true)
		NP.remove('nameplate5')
		NP.add('nameplate6', { plate = 2 })
		check_widgets(NamePlate2, client .. ': a widget-only plate reused for an enemy')
		eq(added, 3, client .. ': no added callback for those')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("a plate's widgets are placed again after Blizzard places them again", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		UF:RefreshPlateWidgets()
		enemy('nameplate1')
		NP.add('nameplate1')
		NP.add('nameplate2', { widgets_only = true })
		NP.add('nameplate3')
		NP.remove('nameplate3')

		-- The game's friendly NPC plates setting changed: plate 1 now shows
		-- only widgets, plate 2 its whole unit, and Blizzard anchored each
		-- plate's widgets to its own UnitFrame again.
		stub.set_nameplate_widgets_only('nameplate1', true)
		stub.set_nameplate_widgets_only('nameplate2', false)
		local unitFrame = rawget(NamePlate1, 'UnitFrame')
		eq(select(2, rawget(unitFrame, 'WidgetContainer'):GetPoint(1)), unitFrame, client .. ": Blizzard's anchor")

		UF:RefreshPlateWidgets()
		check_widgets(NamePlate1, client .. ': plate 1, now widgets only', true)
		check_widgets(NamePlate2, client .. ': plate 2, now its whole unit')
		local released = rawget(NamePlate3, 'UnitFrame')
		eq(released, nil, client .. ': a plate that left has no UnitFrame to place')

		-- A UnitFrame made from a template without widgets or a soft target
		-- icon (a spectator's) is left as it is.
		rawset(unitFrame, 'WidgetContainer', nil)
		rawset(unitFrame, 'SoftTargetFrame', nil)
		UF:RefreshPlateWidgets()
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('a forbidden plate is left alone', function()
	local st, UF = world()
	local log = {}
	for _, event in ipairs({ 'added', 'removed', 'updated' }) do
		UF:RegisterPlateCallback(event, function() log[#log + 1] = event end)
	end
	friend('nameplate4')
	eq(NP.add('nameplate4', { forbidden = true }), nil, "no frame of SaftUI's on it")
	local unitFrame = rawget(NamePlate1, 'UnitFrame')
	eq(rawget(unitFrame, 'WidgetContainer'):GetParent(), unitFrame, 'its widgets left on its UnitFrame')
	eq(rawget(unitFrame, 'SoftTargetFrame'):GetParent(), unitFrame, 'its soft target icon too')
	eq(UF.nameplates[1], nil, 'none kept')
	stub.fire_event('UNIT_FACTION', 'nameplate4')
	NP.remove('nameplate4')
	eq(#log, 0, 'no callbacks')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ every other unit

test('every other unit shows its parts by its config alone', function()
	local st, UF = world()
	-- A plate's kind never reaches a frame that isn't a plate's, whatever it
	-- carries.
	local unitframe = { config = { enable = true }, friendly = true }
	for name in pairs(UF.PLATE_ENEMY_ONLY) do
		eq(UF:ElementWanted({ name = name, unitframe = unitframe, config = { enable = true } }), true, name .. ': on')
		eq(UF:ElementWanted({ name = name, unitframe = unitframe, config = { enable = false } }), false, name .. ': off')
	end
	local keys = {}
	for name in pairs(UF.PLATE_ENEMY_ONLY) do keys[#keys + 1] = name end
	table.sort(keys)
	eq(table.concat(keys, ','), 'Buffs,Castbar,Debuffs,QuestIndicator,Threat', 'the enemy-only parts')
end)
