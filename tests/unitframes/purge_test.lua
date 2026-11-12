-- "Only buffs I can purge" (SaftUI-Unitframes/purge.lua and elements/auras.lua):
--   - the purge table: each class's purge, dispel and steal spells per client,
--     with what each removes (Magic, Enrage, stealable);
--   - the spells the player knows, through C_SpellBook.IsSpellKnown (a pet's in
--     the pet's spellbook), turned into Blizzard's aura container filters: a
--     filter string and candidate filters (UF.PurgeFilter, UF.AuraFilter);
--   - the toggle on every unit's Buffs tab, off by default, not on Debuffs,
--     applied to a built aura group without a reload, and back;
--   - the filters following the spellbook (SPELLS_CHANGED and the other
--     events), and waiting for the end of combat;
--   - a nameplate's debuffs: nameplate-only debuffs in, Only mine by the
--     aura's own flag, so the pet's debuffs stay.
--
-- The world is theme_test.lua's (see its top), made fresh on each client
-- (world): real Core and its defaults, the unit frames' defaults (every
-- unit's), unitframes.lua, groups.lua, config/config.lua, constructors.lua,
-- updaters.lua, purge.lua and the elements; oUF stood in for by its colors
-- table, and a unit frame by a SaftUI button with UF.ConstructUnit's fields
-- and the elements a test names, built by their own constructors
-- (make_unit_frame).
--
-- Stand-in, for what needs oUF: the aura container (frame:CreateAuras). oUF's
-- CreateAuras makes a Blizzard AuraContainer; here a plain frame with the
-- methods auras.lua calls on it. oUF's AddGroup (which gives a group key) and
-- Blizzard's SetAuraGroupFilterString and SetAuraGroupCandidateFilters
-- (CustomAuraContainerSharedMixin) are recorded, each with its filter string
-- and candidate filters; the flow layout setters, SetEnabled,
-- SetAuraGroupLayout and SetAuraGroupMaxFrameCount only take their
-- arguments.
local T = load_test_file('lib/theme_helpers.lua')

local st, UF, P

local UNITS = { 'arena', 'boss', 'focus', 'focustarget', 'party', 'pet', 'pettarget', 'player', 'raid10', 'raid40', 'target', 'targettarget' }
local ELEMENTS = { 'auras', 'power', 'additionalpower', 'health', 'castbar', 'classpower', 'indicators' }

-- A fresh world on one client ('forever' or 'retail').
local function world(client)
	T.client(client)
	st = SaftUI
	load_saftui('SaftUI-Unitframes/config/position.lua')
	load_saftui('SaftUI-Unitframes/config/default.lua')
	for _, unit in ipairs(UNITS) do
		load_saftui('SaftUI-Unitframes/config/units/' .. unit .. '.lua')
	end
	apply_defaults()
	addon_namespace('SaftUI-Unitframes').oUF = {
		colors = {
			class = {}, reaction = {}, power = {},
			disconnected = CreateColor(1, 1, 1), tapped = CreateColor(1, 1, 1), health = CreateColor(0.2, 0.8, 0.2),
			roles = {}, runes = {},
		},
	}
	-- The TOC's order: purge.lua after tags.lua, before the elements.
	for _, file in ipairs({ 'unitframes', 'groups', 'config/config', 'constructors', 'updaters', 'purge' }) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
	for _, file in ipairs(ELEMENTS) do
		load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
	end
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st.StringFormat = LibStub('LibStringFormat-1.0')
	UF = st:GetModule('Unitframes')
	P = UF:GetProfileConfig()
	UF:UpdateColors()
end

-- The player: a class token and the spell IDs known in the player's
-- spellbook and in the pet's.
local function player(class, spells, petSpells)
	stub.class = class
	stub.known_spells, stub.known_pet_spells = {}, {}
	for _, id in ipairs(spells or {}) do stub.known_spells[id] = true end
	for _, id in ipairs(petSpells or {}) do stub.known_pet_spells[id] = true end
end

-- Candidate filters as text, keys sorted, a set's members quoted:
-- 'includeDispelTypes={"Magic"}', 'isStealable=true'; 'nil' for none.
local function candidates(filters)
	if filters == nil then return 'nil' end
	local parts = {}
	for key, value in pairs(filters) do
		if type(value) == 'table' then
			local members = {}
			for member, on in pairs(value) do
				if on then members[#members + 1] = ('%q'):format(member) end
			end
			table.sort(members)
			parts[#parts + 1] = key .. '={' .. table.concat(members, ',') .. '}'
		else
			parts[#parts + 1] = key .. '=' .. tostring(value)
		end
	end
	table.sort(parts)
	return table.concat(parts, ',')
end

-- 'filter string; candidate filters' for an AuraFilter or PurgeFilter result.
local function filters(filter, candidateFilters)
	return tostring(filter) .. '; ' .. candidates(candidateFilters)
end

-- The calls each aura container stand-in recorded, by container: a list of
-- 'Method: filter string; candidate filters'.
local calls = setmetatable({}, { __mode = 'k' })

-- A unit frame for a config unit, with the named elements built by their own
-- constructors (theme_test.lua's, with the container recording its group's
-- filters).
local function make_unit_frame(name, unit, elements)
	local frame = CreateFrame('Button', name, UIParent)
	frame.base_unit = unit
	frame.GetConfig = function() return UF:GetProfileConfig()[unit] end
	frame.config = frame:GetConfig()
	function frame:UpdateAllElements() end
	function frame:CreateAuras()
		local auras = CreateFrame('Frame', nil, self)
		calls[auras] = {}
		function auras:SetEnabled() end
		function auras:SetFlowLayoutAnchorPoint() end
		function auras:SetFlowLayoutMaximumLineSize() end
		function auras:SetFlowLayoutGrowthDirection() end
		function auras:SetAuraGroupLayout() end
		function auras:SetAuraGroupMaxFrameCount() end
		function auras:AddGroup(filter, options)
			table.insert(calls[self], 'AddGroup: ' .. filters(filter, options.candidateFilters))
			return 'Group1'
		end
		function auras:SetAuraGroupFilterString(key, filter)
			eq(key, 'Group1', 'the group set is the one AddGroup made')
			table.insert(calls[self], 'SetAuraGroupFilterString: ' .. tostring(filter))
		end
		function auras:SetAuraGroupCandidateFilters(key, candidateFilters)
			eq(key, 'Group1', 'the group set is the one AddGroup made')
			table.insert(calls[self], 'SetAuraGroupCandidateFilters: ' .. candidates(candidateFilters))
		end
		return auras
	end
	local overlay = CreateFrame('Frame', nil, frame)
	overlay:SetFrameLevel(99)
	overlay:SetAllPoints(frame)
	frame.TextOverlay = overlay
	frame.elements = {}
	for _, element in ipairs(elements) do
		frame.elements[element] = UF.elements[element].Constructor(frame, element)
	end
	return frame
end

-- The calls an aura element's container recorded since the last take, joined
-- with ' | ', and cleared.
local function take_calls(auras)
	local list = calls[auras]
	calls[auras] = {}
	return table.concat(list, ' | ')
end

-- Sets an option on a unit's aura tab, as /sui does: the tab's setter, which
-- saves it and runs UF:UpdateConfig for that unit and element.
local function set_option(unit, auraType, key, value)
	local tab = UF.elements[auraType].GetConfigTable(unit)
	tab.set({ unit, auraType, 'buttons', key }, value)
end

------------------------------------------------------------------ the table

test('the purge table: each spell has an ID and what it removes, by class, on each client', function()
	world('forever')
	for _, client in ipairs({ 'forever', 'live' }) do
		local count = 0
		for class, spells in pairs(UF.PURGE_SPELLS[client]) do
			for _, s in ipairs(spells) do
				count = count + 1
				check(type(s.id) == 'number' and #s.removes > 0, client .. ' ' .. class)
				check(s.pet == nil or s.pet == true, client .. ' ' .. class .. ' ' .. tostring(s.id) .. ': pet is true or nil')
				for _, r in ipairs(s.removes) do
					check(r == 'Magic' or r == 'Enrage' or r == 'stealable', client .. ' ' .. class .. ' ' .. tostring(s.id) .. ' removes ' .. tostring(r))
				end
			end
		end
		check(count > 0, client .. ' has spells')
	end
	-- What step 1 found Forever lacks: Spellsteal, Greater Purge, Consume
	-- Magic, a Soothe that removes an enrage, a Shiv that does.
	for _, class in ipairs({ 'MAGE', 'DRUID', 'ROGUE', 'DEMONHUNTER' }) do
		eq(UF.PURGE_SPELLS.forever[class], nil, 'Forever has no ' .. class .. ' purge spell')
	end
end)

-- Every spell verified against wago.tools at Forever 1.60.1.70888 and retail
-- 12.1.5.70783 (purge.lua's comment): 'CLASS id removes[ pet]', what it
-- removes sorted.
local VERIFIED = {
	forever = {
		'HUNTER 19801 Enrage',
		'PRIEST 527 Magic', 'PRIEST 988 Magic',
		'SHAMAN 370 Magic', 'SHAMAN 8012 Magic',
		'WARLOCK 19505 Magic pet', 'WARLOCK 19731 Magic pet', 'WARLOCK 19734 Magic pet', 'WARLOCK 19736 Magic pet',
		'WARRIOR 23922 Magic', 'WARRIOR 23923 Magic', 'WARRIOR 23924 Magic', 'WARRIOR 23925 Magic',
	},
	live = {
		'DEMONHUNTER 278326 Magic',
		'DRUID 2908 Enrage',
		'HUNTER 19801 Enrage,Magic',
		'MAGE 30449 stealable',
		'PRIEST 528 Magic',
		'ROGUE 5938 Enrage',
		'SHAMAN 370 Magic', 'SHAMAN 378773 Magic',
		'WARLOCK 19505 Magic pet',
	},
}

test('the purge table is exactly the verified spells, each removing what its effects remove', function()
	world('forever')
	for client, expected in pairs(VERIFIED) do
		local actual = {}
		for class, spells in pairs(UF.PURGE_SPELLS[client]) do
			for _, s in ipairs(spells) do
				local removes = {}
				for i, r in ipairs(s.removes) do removes[i] = r end
				table.sort(removes)
				actual[#actual + 1] = ('%s %s %s%s'):format(class, tostring(s.id), table.concat(removes, ','), s.pet and ' pet' or '')
			end
		end
		table.sort(actual)
		local sorted = {}
		for i, line in ipairs(expected) do sorted[i] = line end
		table.sort(sorted)
		eq(table.concat(actual, '; '), table.concat(sorted, '; '), client)
	end
end)

------------------------------------------------------------------ the spells the player knows

for _, client in ipairs({ 'forever', 'retail' }) do
	local forever = client == 'forever'

	test(client .. ': a shaman who knows Purge sees the magic buffs the raid can dispel', function()
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeShaman', 'target', { 'Buffs' })
		player('SHAMAN', { 370 })
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', 'Purge')
		-- The client's other Magic remover alone does as much: Purge's second
		-- rank on Forever, Greater Purge on retail.
		player('SHAMAN', { forever and 8012 or 378773 })
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', forever and 'Purge rank 2' or 'Greater Purge')
		player('PRIEST', { forever and 527 or 528 })
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', 'Dispel Magic')
		-- Another class's spell counts for nothing: the table is read by the
		-- player's class.
		player('WARRIOR', { 370 })
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', "a warrior knowing a shaman's spell")
	end)

	-- An enrage (dispel type 9, Frenzy on Forever) is matched as 'Enrage' and
	-- as '', on both clients: the type had no internal name on either until
	-- retail's 12.1, and an aura with such a type most likely reports '' as its
	-- dispelName (purge.lua).
	test(client .. ": a hunter's Tranquilizing Shot", function()
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeHunter', 'target', { 'Buffs' })
		player('HUNTER', { 19801 })
		if forever then
			eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"","Enrage"}', 'Forever: enrages only')
		else
			eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"","Enrage","Magic"}', 'retail: magic and enrages')
		end
		eq(filters(UF.PurgeFilter({ Enrage = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"","Enrage"}', 'PurgeFilter: enrages by both names')
	end)

	test(client .. ": a protection warrior's Shield Slam takes off a magic buff on Forever only", function()
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeWarrior', 'target', { 'Buffs' })
		for _, id in ipairs({ 23922, 23923, 23924, 23925 }) do
			player('WARRIOR', { id })
			if forever then
				eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', 'Forever: Shield Slam ' .. id)
			else
				eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', "retail's Shield Slam dispels nothing: " .. id)
			end
		end
	end)

	test(client .. ": a warlock with Devour Magic in the pet's spellbook; without the pet, none", function()
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeWarlock', 'target', { 'Buffs' })
		player('WARLOCK', nil, { 19505 })
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', 'the felhunter out')
		player('WARLOCK')
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', 'no pet')
		-- The pet's spell is looked for in the pet's spellbook, not the player's.
		player('WARLOCK', { 19505 })
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', "in the player's spellbook it isn't the pet's")
		if forever then
			-- A felhunter that has only learned Devour Magic's fourth rank.
			player('WARLOCK', nil, { 19736 })
			eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', 'Devour Magic rank 4')
		end
	end)

	test(client .. ': summoning or dismissing the pet updates the filters', function()
		world(client)
		local frame = make_unit_frame('SaftUI_PurgePet', 'target', { 'Buffs' })
		UF.units = { target = frame }
		P.target.buffs.enable = true
		P.target.buffs.purgeable = true
		player('WARLOCK')
		UF:UpdateUnitFrame(frame)
		eq(take_calls(frame.Buffs), 'AddGroup: HELPFUL; includeDispelTypes={}', 'built with no pet: no buffs')
		stub.known_pet_spells[19505] = true
		stub.fire_event('UNIT_PET', 'party1')
		eq(take_calls(frame.Buffs), '', "a party member's pet changes nothing")
		stub.fire_event('UNIT_PET', 'player')
		eq(take_calls(frame.Buffs), 'SetAuraGroupFilterString: HELPFUL|RAID_PLAYER_DISPELLABLE | SetAuraGroupCandidateFilters: includeDispelTypes={"Magic"}', 'the felhunter summoned')
		stub.known_pet_spells = {}
		stub.fire_event('UNIT_PET', 'player')
		eq(take_calls(frame.Buffs), 'SetAuraGroupFilterString: HELPFUL | SetAuraGroupCandidateFilters: includeDispelTypes={}', 'the felhunter dismissed')
	end)
end

test('a mage who knows only Spellsteal sees stealable buffs', function()
	world('retail')
	local frame = make_unit_frame('SaftUI_PurgeMage', 'target', { 'Buffs' })
	player('MAGE', { 30449 })
	eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; isStealable=true', 'Spellsteal')
	eq(filters(UF.PurgeFilter({ stealable = true })), 'HELPFUL; isStealable=true', 'PurgeFilter: stealable only')
	-- Blizzard's candidate filters must all pass, so magic and stealable can't
	-- be either-or in one group. A stealable buff is a magic one, so Magic
	-- covers Spellsteal.
	eq(filters(UF.PurgeFilter({ Magic = true, stealable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"Magic"}', 'PurgeFilter: magic and stealable')

	-- Forever has no Spellsteal: a Forever mage removes nothing.
	world('forever')
	frame = make_unit_frame('SaftUI_PurgeMageForever', 'target', { 'Buffs' })
	player('MAGE', { 30449 })
	eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', 'Forever: no Spellsteal')
end)

test("retail: a druid's Soothe and a rogue's Shiv see enrages, by both names", function()
	world('retail')
	local frame = make_unit_frame('SaftUI_PurgeEnrage', 'target', { 'Buffs' })
	player('DRUID', { 2908 })
	eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"","Enrage"}', 'Soothe')
	player('ROGUE', { 5938 })
	eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL|RAID_PLAYER_DISPELLABLE; includeDispelTypes={"","Enrage"}', 'Shiv')
end)

test('a player who knows no such spell sees no buffs while the toggle is on', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeNone', 'target', { 'Buffs' })
		player('WARRIOR')
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', client .. ': a warrior')
		player('PRIEST')
		eq(filters(UF.AuraFilter(frame, 'Buffs', { purgeable = true })), 'HELPFUL; includeDispelTypes={}', client .. ": a priest who hasn't learned Dispel Magic")
		eq(filters(UF.PurgeFilter({})), 'HELPFUL; includeDispelTypes={}', client .. ': PurgeFilter with nothing known')
		eq(next(UF:KnownRemovals()), nil, client .. ': KnownRemovals is empty')
	end
end)

------------------------------------------------------------------ the option

test("Only buffs I can purge is on every unit's Buffs tab, off by default, and not on Debuffs", function()
	world('forever')
	for _, unit in ipairs(UNITS) do
		local tab = UF.elements.Buffs.GetConfigTable(unit)
		local option = tab.args.buttons.args.purgeable
		if check(option, unit .. ': Buffs has the option') then
			eq(option.type, 'toggle', unit .. ': a toggle')
			eq(option.name, 'Only buffs I can purge', unit .. ': its name')
			eq(option.size, 'small', unit .. ': small')
			eq(option.order, 6.5, unit .. ': after Only mine')
			eq(option.desc, "Shows only buffs you can take off the unit with a spell you know: a purge, a dispel or a steal. If you know none, no buffs show.", unit .. ': its tooltip, with no reload note')
		end
		eq(P[unit].buffs.purgeable, false, unit .. ': off by default')
		eq(tab.get({ unit, 'Buffs', 'buttons', 'purgeable' }), false, unit .. ': the tab reads it off')
		eq(UF.elements.Debuffs.GetConfigTable(unit).args.buttons.args.purgeable, nil, unit .. ': not on Debuffs')
	end
end)

test("off, Buffs keeps today's filter; on, it switches without a reload, and back", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeToggle', 'target', { 'Buffs', 'Debuffs' })
		UF.units = { target = frame }
		P.target.buffs.enable = true
		P.target.debuffs.enable = true
		player('SHAMAN', { 370 })
		UF:UpdateUnitFrame(frame)
		eq(take_calls(frame.Buffs), 'AddGroup: HELPFUL; nil', client .. ": off: today's buffs filter")
		eq(take_calls(frame.Debuffs), 'AddGroup: HARMFUL; nil', client .. ": today's debuffs filter")

		set_option('target', 'Buffs', 'purgeable', true)
		eq(P.target.buffs.purgeable, true, client .. ': saved')
		eq(take_calls(frame.Buffs), 'SetAuraGroupFilterString: HELPFUL|RAID_PLAYER_DISPELLABLE | SetAuraGroupCandidateFilters: includeDispelTypes={"Magic"}', client .. ': on, applied to the built group')
		eq(take_calls(frame.Debuffs), '', client .. ': the debuffs left alone')

		-- An update that changes neither the filter string nor the candidate
		-- filters calls neither setter: each makes the container update every aura.
		set_option('target', 'Buffs', 'spacing', 5)
		UF:UpdateUnitFrame(frame)
		eq(take_calls(frame.Buffs), '', client .. ': nothing changed, nothing set')

		set_option('target', 'Buffs', 'purgeable', false)
		eq(take_calls(frame.Buffs), 'SetAuraGroupFilterString: HELPFUL | SetAuraGroupCandidateFilters: nil', client .. ": off: today's filter again")
	end
end)

test('a unit frame built with the toggle on gets the purge filter from AddGroup', function()
	world('retail')
	local frame = make_unit_frame('SaftUI_PurgeBuilt', 'target', { 'Buffs' })
	UF.units = { target = frame }
	P.target.buffs.enable = true
	P.target.buffs.purgeable = true
	player('MAGE', { 30449 })
	UF:UpdateUnitFrame(frame)
	eq(take_calls(frame.Buffs), 'AddGroup: HELPFUL; isStealable=true', 'built with the filter')
	UF:UpdateUnitFrame(frame)
	eq(take_calls(frame.Buffs), '', 'and nothing set again by the next update')
end)

test('Only mine applies without a reload too', function()
	world('forever')
	local frame = make_unit_frame('SaftUI_PurgeOnlyMine', 'target', { 'Buffs', 'Debuffs' })
	UF.units = { target = frame }
	P.target.buffs.enable = true
	P.target.debuffs.enable = true
	UF:UpdateUnitFrame(frame)
	take_calls(frame.Buffs)
	take_calls(frame.Debuffs)
	set_option('target', 'Debuffs', 'onlyShowPlayer', true)
	eq(take_calls(frame.Debuffs), 'SetAuraGroupFilterString: HARMFUL|PLAYER | SetAuraGroupCandidateFilters: isFromPlayerOrPlayerPet=true', 'on')
	set_option('target', 'Debuffs', 'onlyShowPlayer', false)
	eq(take_calls(frame.Debuffs), 'SetAuraGroupFilterString: HARMFUL | SetAuraGroupCandidateFilters: nil', 'off')
	local option = UF.elements.Debuffs.GetConfigTable('target').args.buttons.args.onlyShowPlayer
	check(not option.desc:find('Reload'), 'Only mine no longer asks for a reload: ' .. option.desc)
end)

------------------------------------------------------------------ the spellbook changing

test('learning a purge spell mid-session updates the filters; in combat it waits', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local frame = make_unit_frame('SaftUI_PurgeLearn', 'target', { 'Buffs', 'Debuffs' })
		UF.units = { target = frame }
		P.target.buffs.enable = true
		P.target.buffs.purgeable = true
		P.target.debuffs.enable = true
		player('SHAMAN')
		UF:UpdateUnitFrame(frame)
		eq(take_calls(frame.Buffs), 'AddGroup: HELPFUL; includeDispelTypes={}', client .. ': no purge yet')
		take_calls(frame.Debuffs)

		stub.known_spells[370] = true
		stub.fire_event('SPELLS_CHANGED')
		eq(take_calls(frame.Buffs), 'SetAuraGroupFilterString: HELPFUL|RAID_PLAYER_DISPELLABLE | SetAuraGroupCandidateFilters: includeDispelTypes={"Magic"}', client .. ': Purge learned')
		eq(take_calls(frame.Debuffs), '', client .. ': the debuffs left alone')

		-- In combat the change waits for the end of combat.
		stub.known_spells = {}
		stub.in_combat = true
		stub.fire_event('PLAYER_TALENT_UPDATE')
		stub.fire_event('TRAIT_CONFIG_UPDATED', 1)
		eq(take_calls(frame.Buffs), '', client .. ': unchanged in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(take_calls(frame.Buffs), 'SetAuraGroupFilterString: HELPFUL | SetAuraGroupCandidateFilters: includeDispelTypes={}', client .. ': applied once combat ends')

		-- A frame with the toggle off isn't touched.
		P.target.buffs.purgeable = false
		UF:UpdateUnitFrame(frame)
		take_calls(frame.Buffs)
		stub.known_spells[370] = true
		stub.fire_event('SPELLS_CHANGED')
		eq(take_calls(frame.Buffs), '', client .. ': toggle off, nothing set')
	end
end)

test('no unit frames yet: a spellbook change does nothing', function()
	world('forever')
	UF.units = nil
	stub.fire_event('SPELLS_CHANGED')
	eq(#take_errors(), 0, 'no error before the unit frames are made')
end)

------------------------------------------------------------------ nameplate debuffs

test("nameplate debuffs: nameplate-only debuffs in, Only mine by the aura's own flag, the pet's in", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local plate = make_unit_frame('SaftUI_PurgePlate', 'target', { 'Debuffs' })
		plate.isNamePlate = true
		local target = make_unit_frame('SaftUI_PurgeTarget', 'target', { 'Debuffs' })
		eq(filters(UF.AuraFilter(plate, 'Debuffs', { onlyShowPlayer = true })), 'HARMFUL|INCLUDE_NAME_PLATE_ONLY; isFromPlayerOrPlayerPet=true', client .. ': a plate, Only mine')
		eq(filters(UF.AuraFilter(plate, 'Debuffs', { onlyShowPlayer = false })), 'HARMFUL|INCLUDE_NAME_PLATE_ONLY; nil', client .. ': a plate, every debuff')
		eq(filters(UF.AuraFilter(target, 'Debuffs', { onlyShowPlayer = true })), 'HARMFUL|PLAYER; isFromPlayerOrPlayerPet=true', client .. ': another unit unchanged')
		eq(filters(UF.AuraFilter(target, 'Debuffs', { onlyShowPlayer = false })), 'HARMFUL; nil', client .. ': another unit, every debuff')
		eq(filters(UF.AuraFilter(target, 'Buffs', { onlyShowPlayer = true })), 'HELPFUL|PLAYER; isFromPlayerOrPlayerPet=true', client .. ': buffs, Only mine')
	end
end)
