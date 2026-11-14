-- SaftUI-Tracker's zone groups (SaftUI-Tracker/groups.lua) over the model
-- (model.lua): a group per quest log header, the current zone first (by the zone
-- map's name, GetRealZoneText or GetZoneText), then campaigns, then the log's
-- header order, Other last under its own key; the three orders and Finished
-- quests first; collapsed groups keeping their header and count; Group by zone
-- off; two headers of one title merging in the first one's place. On both
-- clients.
--
-- Real: SaftUI-Tracker's files and Core's helpers. Stubbed: the game's quest
-- API (tests/wow/quests.lua), which these cases fill with stub.quests.
local TW = load_test_file('tracker/tracker_world.lua')
local Q = load_test_file('tracker/quest_log.lua')
local S = load_test_file('lib/secrets.lua')

local function both(name, fn)
	for _, client in ipairs({ 'forever', 'retail' }) do
		test(name .. ' [' .. client .. ']', function()
			local st, TR = TW.world({ client = client })
			fn(st, TR, client)
			eq(#take_errors(), 0, client .. ': no error reported')
		end)
	end
end

local function keys(groups)
	local out = {}
	for i, group in ipairs(groups) do out[i] = group.key end
	return table.concat(out, '|')
end

local function ids(group)
	local out = {}
	for i, quest in ipairs(group.quests) do out[i] = quest.id end
	return table.concat(out, ',')
end

local function build(st, TR, changes, collapsed, show)
	local model = TR.Model.Read(show or 'tracked')
	return TR.Groups.Build(model.quests, Q.settings(st, changes), model.zoneNames, collapsed), model
end

both('a group per header; the current zone first by the map name, GetRealZoneText or GetZoneText', function(st, TR)
	Q.set({
		Q.header('Durotar'), Q.quest(1),
		Q.header('Elwynn Forest'), Q.quest(2), Q.quest(3),
		Q.header('Westfall'), Q.quest(4),
	}, { 1, 2, 3, 4 })
	local groups = build(st, TR, {})
	eq(keys(groups), 'Durotar|Elwynn Forest|Westfall', 'no zone: the log\'s order')
	eq(groups[2].title, 'Elwynn Forest', 'the title is the header\'s')
	eq(groups[2].count, 2, 'the count')
	eq(ids(groups[2]), '2,3', 'the quests')
	eq(groups[1].current, false, 'not the current zone')

	stub.maps = {
		[1415] = { name = 'Eastern Kingdoms', mapType = Enum.UIMapType.Continent },
		[1429] = { name = 'Elwynn Forest', mapType = Enum.UIMapType.Zone, parentMapID = 1415 },
	}
	stub.player_map = 1429
	groups = build(st, TR, {})
	eq(keys(groups), 'Elwynn Forest|Durotar|Westfall', 'the zone map\'s name first')
	eq(groups[1].current, true, 'current')
	eq(keys((build(st, TR, { current_first = false }))), 'Durotar|Elwynn Forest|Westfall', 'Current zone first off: in place')
	eq(build(st, TR, { current_first = false })[2].current, true, 'still marked current')

	stub.player_map = nil
	stub.real_zone_text = 'Westfall'
	eq(keys(build(st, TR, {})), 'Westfall|Durotar|Elwynn Forest', 'GetRealZoneText')
	stub.real_zone_text = ''
	stub.zone_text = 'Durotar'
	eq(keys(build(st, TR, {})), 'Durotar|Elwynn Forest|Westfall', 'GetZoneText (already first: the others keep their order)')
	stub.zone_text = 'Westfall'
	eq(keys(build(st, TR, {})), 'Westfall|Durotar|Elwynn Forest', 'GetZoneText')

	check(TR.Groups.IsCurrent('Westfall', { 'Elwynn Forest', 'Westfall' }), 'IsCurrent: one of the names')
	check(not TR.Groups.IsCurrent('Westfall', { 'Elwynn Forest' }), 'IsCurrent: not one')
	check(not TR.Groups.IsCurrent('westfall', { 'Westfall' }), 'IsCurrent: the title as the game spells it')
	check(not TR.Groups.IsCurrent(nil, { 'Westfall' }), 'IsCurrent: no title')
	check(not TR.Groups.IsCurrent('Westfall', {}), 'IsCurrent: no names')
	local restore = S.install()
	check(not TR.Groups.IsCurrent(S.secret('title'), { 'Westfall' }), 'IsCurrent: a secret title')
	restore()
end)

both("then campaign groups, then the log's header order; Other last, keyed *other", function(st, TR)
	Q.set({
		Q.quest(99), -- above every header: Other
		Q.header('Durotar'), Q.quest(1),
		Q.header('The Long Road', 5), Q.quest(2),
		Q.header('Elwynn Forest'), Q.quest(3),
		Q.header('Other'), Q.quest(4), -- a real header, titled Other
	}, { 1, 2, 3, 4, 99 })
	stub.zone_text = 'Elwynn Forest'
	local groups = build(st, TR, {})
	eq(keys(groups), 'Elwynn Forest|The Long Road|Durotar|Other|*other', 'current, campaign, the log\'s order, then Other')
	eq(groups[2].campaign, 5, 'the campaign group carries its campaign ID')
	eq(groups[3].campaign, nil, 'a plain one has none')
	eq(groups[4].title, 'Other', 'a real header titled Other keeps its own key')
	eq(groups[5].title, 'Other', 'the Other group\'s title')
	eq(groups[5].key, TR.OTHER_KEY, 'its key')
	eq(TR.OTHER_KEY, '*other', 'is *other')
	eq(groups[5].current, false, 'Other is never current')
	eq(ids(groups[5]), '99', 'with the quest the log can\'t place')
	eq(keys(build(st, TR, { current_first = false })), 'The Long Road|Durotar|Elwynn Forest|Other|*other', 'without Current zone first: campaigns, then the log\'s order')
	stub.zone_text = 'Other'
	eq(build(st, TR, {})[1].key, 'Other', 'a zone named Other makes the real header current, never *other')
	eq(build(st, TR, {})[#build(st, TR, {})].key, '*other', 'Other stays last')
end)

both('the three orders and Finished quests first, keeping the order otherwise; untracked zone quests after the tracked', function(st, TR)
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { level = 20 }), Q.quest(2, { level = 10 }), Q.quest(3, { level = 0 }),
		Q.quest(4, { level = 10, complete = true }), Q.quest(5, { level = 5 }), Q.quest(6, { level = 20, complete = true }),
	}, { 2, 3, 1, 4, 6 })
	stub.zone_text = 'Zone'
	local function order(changes, show)
		return ids(build(st, TR, changes, nil, show or 'zone')[1])
	end
	eq(order({ order = 'game' }), '2,3,1,4,6,5', "the game's order: the watch list, the untracked quest after")
	eq(order({ order = 'log' }), '1,2,3,4,5,6', 'the log\'s order')
	eq(order({ order = 'level' }), '5,2,4,1,6,3', 'level, low first, then the game\'s order; no level last')
	eq(order({ order = 'game', finished_first = true }), '4,6,2,3,1,5', 'finished first, the order kept in each part')
	eq(order({ order = 'log', finished_first = true }), '4,6,1,2,3,5', 'finished first in the log\'s order')
	eq(order({ order = 'level', finished_first = true }), '4,6,5,2,1,3', 'finished first by level')
	eq(order({ order = 'game' }, 'tracked'), '2,3,1,4,6', 'Show: Tracked reads no untracked quest')

	-- Sort on its own.
	local quests = {
		{ id = 'a', logIndex = 1, tracked = false }, { id = 'b', logIndex = 2, watchIndex = 2, tracked = true },
		{ id = 'c', logIndex = 3, watchIndex = 1, tracked = true, overrides = true },
		{ id = 'd', logIndex = 4, tracked = false, ready = true },
	}
	TR.Groups.Sort(quests, 'game', false)
	eq(quests[1].id .. quests[2].id .. quests[3].id .. quests[4].id, 'cbad', 'game: Compare, then the untracked by log index')
	TR.Groups.Sort(quests, 'game', true)
	eq(quests[1].id, 'd', 'a quest ready to turn in counts as finished')
	TR.Groups.Sort(quests, 'bogus', false)
	eq(quests[1].id, 'c', 'an unknown order is the game\'s')
end)

both('collapsed groups from the character\'s table keep their header and count', function(st, TR)
	Q.set({
		Q.quest(4), -- above every header: Other
		Q.header('Westfall'), Q.quest(1), Q.quest(2),
		Q.header('Durotar'), Q.quest(3),
	}, { 1, 2, 3, 4 })
	local collapsed = { Westfall = true, [TR.OTHER_KEY] = true, Durotar = false }
	local groups = build(st, TR, {}, collapsed)
	eq(keys(groups), 'Westfall|Durotar|*other', 'every group is still there')
	eq(groups[1].collapsed, true, 'Westfall is collapsed')
	eq(groups[1].title, 'Westfall', 'with its header')
	eq(groups[1].count, 2, 'and its count')
	eq(ids(groups[1]), '1,2', 'and its quests, which the drawing leaves out')
	eq(groups[2].collapsed, false, 'Durotar is not')
	eq(groups[3].collapsed, true, 'Other collapses by its own key')
	eq(build(st, TR, {}, nil)[1].collapsed, false, 'no table: none collapsed')
	eq(#build(st, TR, {}, {}), 3, 'an empty table too')
	eq(collapsed.Westfall, true, 'the table is only read')
end)

both("Group by zone off: one list in the chosen order; two headers with one title merge in the first one's place", function(st, TR)
	Q.set({
		Q.header('Zone A'), Q.quest(1, { level = 30 }),
		Q.header('Zone B'), Q.quest(2, { level = 20 }),
		Q.header('Zone A'), Q.quest(3, { level = 10 }),
	}, { 3, 1, 2 })
	local grouped = build(st, TR, { zones = true })
	eq(keys(grouped), 'Zone A|Zone B', 'two headers with one title are one group, in the first one\'s place')
	eq(ids(grouped[1]), '3,1', 'with both headers\' quests, in the game\'s order')
	eq(grouped[1].count, 2, 'counted together')

	local flat = build(st, TR, { zones = false, order = 'level' }, { ['*all'] = true, ['Zone A'] = true })
	eq(#flat, 1, 'one group')
	eq(flat[1].key, '*all', 'keyed *all')
	eq(TR.ALL_KEY, '*all', 'TR.ALL_KEY')
	eq(flat[1].title, nil, 'with no title')
	eq(flat[1].collapsed, false, 'never collapsed')
	eq(flat[1].count, 3, 'with every quest')
	eq(ids(flat[1]), '3,2,1', 'in the chosen order')
	eq(ids(build(st, TR, { zones = false, order = 'game' })[1]), '3,1,2', 'the game\'s order')
	eq(ids(build(st, TR, { zones = false, order = 'log' })[1]), '1,2,3', 'the log\'s order')

	Q.set({}, {})
	eq(#build(st, TR, { zones = true }), 0, 'no quests, no groups')
	eq(#build(st, TR, { zones = false }), 0, 'no quests, no list')
end)

both('the groups are a read, not a change: the model\'s quests keep their order', function(st, TR)
	Q.set({ Q.header('Z'), Q.quest(1, { level = 9 }), Q.quest(2, { level = 1 }) }, { 1, 2 })
	local model = TR.Model.Read('tracked')
	local before = Q.ids(model)
	TR.Groups.Build(model.quests, Q.settings(st, { zones = false, order = 'level' }), model.zoneNames, {})
	eq(Q.ids(model), before, 'Build sorts copies')
	TR.Groups.Build(model.quests, Q.settings(st, { zones = true, order = 'level' }), model.zoneNames, {})
	eq(Q.ids(model), before, 'in both modes')
end)
