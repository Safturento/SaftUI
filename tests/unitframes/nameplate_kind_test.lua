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
local function check_kind(frame, enemy, label)
	for _, name in ipairs({ 'Castbar', 'QuestIndicator' }) do
		eq(frame:IsElementEnabled(name) == true, enemy, label .. ': ' .. name .. (enemy and ' enabled in oUF' or ' disabled in oUF'))
		eq(frame[name]:IsShown(), enemy, label .. ': ' .. name .. (enemy and ' shown' or ' hidden'))
	end
	for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
		eq(frame[name].enabled, enemy, label .. ': ' .. name .. (enemy and ' on' or ' off'))
		eq(frame[name]:IsShown(), enemy, label .. ': ' .. name .. (enemy and ' shown' or ' hidden'))
	end
	eq(frame.Health:IsShown(), true, label .. ': the bar shown')
	eq(frame.Name:IsShown(), true, label .. ': the name shown')
	eq(frame.Health.text:IsShown(), true, label .. ': the health text shown')
	eq(frame.RaidTargetIndicator:IsShown(), true, label .. ': the raid mark shown')
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
	eq(frame.Castbar:IsShown(), true, 'and shown')
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
		eq(frame.Castbar:IsShown(), true, client .. ': and shown')
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
-- icon on the plate, the widgets hanging from its bottom.
local function check_widgets(plate, label)
	local unitFrame = rawget(plate, 'UnitFrame')
	local widgets, softTarget = rawget(unitFrame, 'WidgetContainer'), rawget(unitFrame, 'SoftTargetFrame')
	eq(widgets:GetParent(), plate, label .. ': the widgets on the plate')
	local point, relativeTo, relativePoint = widgets:GetPoint(1)
	eq(point, 'TOP', label .. ': their top')
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
		check_widgets(NamePlate2, client .. ': a widget-only plate')
		NP.add('nameplate4', { game_object = true })
		check_widgets(NamePlate3, client .. ': a game object')
		NP.remove('nameplate3')
		NP.add('nameplate5', { plate = 2, widgets_only = true })
		check_widgets(NamePlate2, client .. ': a widget-only plate again')
		eq(added, 2, client .. ': no added callback for those')
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

------------------------------------------------------------------ the player's own plate

test("the personal resource display stays Blizzard's", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local log = {}
		UF:RegisterPlateCallback('added', function(_, unit) log[#log + 1] = 'added ' .. unit end)
		UF:RegisterPlateCallback('removed', function(_, unit) log[#log + 1] = 'removed ' .. unit end)

		-- The player's plate first: no frame of SaftUI's is made on it, and its
		-- widgets stay on Blizzard's UnitFrame.
		stub.nameplate_player = 'nameplate1'
		eq(NP.add('nameplate1'), nil, client .. ": no frame of SaftUI's on the player's plate")
		eq(UF.nameplates[1], nil, client .. ': none kept')
		local unitFrame = rawget(NamePlate1, 'UnitFrame')
		eq(rawget(unitFrame, 'WidgetContainer'):GetParent(), unitFrame, client .. ': its widgets left on its UnitFrame')
		eq(rawget(unitFrame, 'SoftTargetFrame'):GetParent(), unitFrame, client .. ': its soft target icon too')
		NP.remove('nameplate1')
		stub.nameplate_player = nil

		-- The plate reused for an enemy gets SaftUI's frame.
		enemy('nameplate2')
		local frame = NP.add('nameplate2', { plate = 1 })
		check(frame ~= nil and frame:IsShown(), client .. ': an enemy on the same plate: SaftUI\'s frame')
		NP.remove('nameplate2')

		-- Then the player's plate again: SaftUI's frame on it paused and hidden.
		stub.nameplate_player = 'nameplate3'
		friend('nameplate3')
		log = {}
		NP.add('nameplate3', { plate = 1 })
		eq(frame:IsShown(), false, client .. ': hidden on the player\'s plate')
		eq(frame:IsElementPaused('Health'), true, client .. ': its parts paused')
		eq(UF:PlateForUnit('nameplate3'), nil, client .. ': not a plate of SaftUI\'s for the unit')
		eq(rawget(rawget(NamePlate1, 'UnitFrame'), 'WidgetContainer'):GetParent(), rawget(NamePlate1, 'UnitFrame'),
			client .. ': its widgets left on its UnitFrame')
		local updates = frame.__updates
		stub.fire_event('UNIT_FACTION', 'nameplate3')
		stub.fire_event('UNIT_FACTION', 'player')
		stub.nameplate_target = 'nameplate3'
		stub.fire_event('PLAYER_TARGET_CHANGED')
		stub.nameplate_target = nil
		eq(frame.__updates, updates, client .. ': its faction or being targeted updates nothing')
		NP.remove('nameplate3')
		stub.nameplate_player = nil
		eq(frame:IsElementPaused('Health'), nil, client .. ': resumed when it leaves')

		-- And reused for a friend: the friend's kind.
		friend('nameplate4')
		NP.add('nameplate4', { plate = 1 })
		check_kind(frame, false, client .. ': a friend after the player')
		eq(table.concat(log, ', '), 'removed nameplate3, added nameplate4', client .. ': no added callback for the player\'s plate')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("the bundled oUF's nameplate driver leaves the player's own plate alone before it blocks Blizzard's UnitFrame", function()
	local src = read_saftui_source('SaftUI-Unitframes/Libraries/oUF/ouf.lua')
	local handler = src:match('local function driverEventHandler%(self, event, unit%)(.-)\n\tend\n')
	check(handler ~= nil, 'the handler found')
	handler = handler or ''
	check(src:find("return nameplate == C_NamePlate.GetNamePlateForUnit('player')", 1, true),
		"the player's plate found by frame, not UnitIsUnit")
	local added = handler:find("event == 'NAME_PLATE_UNIT_ADDED'", 1, true)
	local check_at = added and handler:find('if(isPlayerPlate(nameplate)) then', added, true)
	local unblock = check_at and handler:find('nameplate.UnitFrame:SetRolesets(nil)', check_at, true)
	local pause = check_at and handler:find('nameplate.unitFrame:PauseAllElements()', check_at, true)
	local disable = added and handler:find('oUF:DisableBlizzard(unit)', added, true)
	check(check_at and disable and check_at < disable, "the add checks the player's plate before oUF:DisableBlizzard")
	check(unblock and disable and unblock < disable, 'and unblocks its UnitFrame there')
	check(pause and disable and pause < disable, "and pauses oUF's frame there")
	local target = handler:find("event == 'PLAYER_TARGET_CHANGED'", 1, true)
	local targetCheck = target and handler:find('if(isPlayerPlate(nameplate)) then return end', target, true)
	check(targetCheck and targetCheck < added, 'targeting yourself leaves the plate alone too')
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
	eq(table.concat(keys, ','), 'Buffs,Castbar,Debuffs,QuestIndicator', 'the enemy-only parts')
end)
