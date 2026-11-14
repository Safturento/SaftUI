-- SaftUI-Tracker's model (SaftUI-Tracker/model.lua): the quest log read into a
-- plain table, a quest's title and the lines of its row, on both clients.
--   - the watch list in the game's order; the display rule;
--   - level and elite (Forever's IsEliteQuest, retail's tag), tags, frequency;
--   - objectives (sequenced, Hide finished, finished quests), completion,
--     failure, auto-complete, money, the timer, the item, the focused quest's
--     waypoint, area and distance;
--   - popups, an arena, the counts, the current zone's untracked quests;
--   - an API missing or a value secret making its part absent;
--   - quests the log can't place.
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

local function lines_text(lines)
	local out = {}
	for i, line in ipairs(lines) do out[i] = line.kind .. ':' .. tostring(line.text) .. ':' .. line.state end
	return table.concat(out, ' | ')
end

-- A deep copy of plain data, for comparing two reads.
local function dump(value, seen)
	if type(value) ~= 'table' then return tostring(value) end
	local keys = {}
	for key in pairs(value) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local parts = {}
	for _, key in ipairs(keys) do parts[#parts + 1] = tostring(key) .. '=' .. dump(value[key]) end
	return '{' .. table.concat(parts, ',') .. '}'
end

both("the watch list in the game's order with callings first and overridesSortOrder next", function(st, TR)
	Q.set({
		Q.header('Elwynn Forest'),
		Q.quest(1), Q.quest(2, { overrides = true }), Q.quest(3), Q.quest(4), Q.quest(5, { calling = true }),
	}, { 3, 1, 99, 5, 2, 3 })
	local model = TR.Model.Read('tracked')
	eq(Q.ids(model), '5,2,3,1', 'calling, overrides, then the watch list; quest 4 is not tracked, 99 is not in the log')
	local five = Q.find(model, 5)
	eq(five.watchIndex, 4, 'the watch index is the position on the list (the repeat of 3 counts)')
	eq(five.logIndex, 6, 'the log index')
	eq(five.tracked, true, 'tracked')
	eq(five.calling, true, 'calling')
	eq(Q.find(model, 2).overrides, true, 'overrides')
	eq(Q.find(model, 4), nil, 'an untracked quest is not read')
	check(TR.Model.Compare(Q.find(model, 5), Q.find(model, 2)), 'Compare: a calling before an override')
	check(not TR.Model.Compare(Q.find(model, 2), Q.find(model, 5)), 'and not the other way')
	check(TR.Model.Compare(Q.find(model, 3), Q.find(model, 1)), 'Compare: the watch index')
	eq(Q.ids(TR.Model.Read('tracked')), '5,2,3,1', 'the same input, the same model')
	eq(dump(TR.Model.Read('tracked')), dump(model), 'a second read is the first, field by field')
end)

both('the display rule: tasks, bounties, hidden and disabled quests left out; campaign quests kept', function(st, TR)
	Q.set({
		Q.header('Zone'),
		Q.quest(1), Q.quest(2, { task = true }), Q.quest(3, { bounty = true }), Q.quest(4, { hidden = true }),
		Q.quest(5, { disabled = true }), Q.quest(6, { classification = Enum.QuestClassification.Campaign, campaignID = 7 }),
	}, { 1, 2, 3, 4, 5, 6 })
	eq(Q.ids(TR.Model.Read('tracked')), '1,6', 'only the plain quest and the campaign quest')
	-- Log indexes: the header is 1, quest N is N + 1.
	eq(TR.Model.Shown(C_QuestLog.GetInfo(3)), false, 'Shown: a task quest')
	eq(TR.Model.Shown(C_QuestLog.GetInfo(4)), false, 'Shown: a bounty, which Blizzard never shows either')
	eq(TR.Model.Shown(C_QuestLog.GetInfo(5)), false, 'Shown: hidden')
	eq(TR.Model.Shown(C_QuestLog.GetInfo(6)), false, 'Shown: disabled for the session')
	eq(TR.Model.Shown(C_QuestLog.GetInfo(7)), true, 'Shown: campaign')
	eq(TR.Model.Shown(C_QuestLog.GetInfo(2)), true, 'Shown: a plain quest')
	eq(TR.Model.Shown(nil), false, 'Shown: nothing')
end)

both('level and elite: "[12+] " through IsEliteQuest on Forever, the tag\'s isElite on retail', function(st, TR, client)
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { level = 12, elite = true, tag = { tagName = 'Elite', tagID = 1, isElite = false } }),
		Q.quest(2, { level = 12, elite = false, tag = { tagName = 'Elite', tagID = 1, isElite = true } }),
		Q.quest(3, { level = 20, scaled = 12 }),
		Q.quest(4, { level = 0 }),
	}, { 1, 2, 3, 4 })
	local model = TR.Model.Read('tracked')
	local on = Q.settings(st, { level = true, tags = false })
	local forever = client == 'forever'
	eq(Q.find(model, 1).elite, forever, 'IsEliteQuest says so on Forever only')
	eq(Q.find(model, 2).elite, not forever, "the tag's isElite says so on retail only")
	eq(TR.TitleText(Q.find(model, 1), on), forever and '[12+] Quest 1' or '[12] Quest 1', 'the title of quest 1')
	eq(TR.TitleText(Q.find(model, 2), on), forever and '[12] Quest 2' or '[12+] Quest 2', 'the title of quest 2')
	eq(Q.find(model, 3).level, 12, 'the level the player is shown (difficultyLevel), not the quest\'s own')
	eq(Q.find(model, 4).level, nil, 'a level of 0 is no level')
	eq(TR.TitleText(Q.find(model, 4), on), 'Quest 4', 'and no prefix')
	eq(TR.TitleText(Q.find(model, 1), Q.settings(st, { level = false, tags = false })), 'Quest 1', 'Level off: no prefix')
	eq(type(C_QuestLog.IsEliteQuest), forever and 'function' or 'nil', 'the stub has IsEliteQuest on Forever only')
end)

both('tags and frequency: "(Elite) (Daily)"; a secret title shown as it is, with no prefix or tags', function(st, TR)
	local restore = S.install()
	local secret = S.secret('quest title')
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { tag = { tagName = 'Elite', tagID = 1 }, frequency = Enum.QuestFrequency.Daily }),
		Q.quest(2, { frequency = Enum.QuestFrequency.Weekly }),
		Q.quest(3, { frequency = Enum.QuestFrequency.ResetByScheduler }),
		Q.quest(4, { title = secret, tag = { tagName = 'Dungeon', tagID = 81 }, frequency = Enum.QuestFrequency.Daily }),
		Q.quest(5, { tag = { tagName = S.secret('tag name'), tagID = 2 } }),
	}, { 1, 2, 3, 4, 5 })
	local model = TR.Model.Read('tracked')
	local both_on = Q.settings(st, { level = true, tags = true })
	eq(TR.TitleText(Q.find(model, 1), both_on), '[10] Quest 1 (Elite) (Daily)', 'a tag, then the frequency, in brackets')
	eq(TR.TitleText(Q.find(model, 1), Q.settings(st, { level = false, tags = true })), 'Quest 1 (Elite) (Daily)', 'Level off')
	eq(TR.TitleText(Q.find(model, 1), Q.settings(st, { level = true, tags = false })), '[10] Quest 1', 'Tags off')
	eq(TR.TitleText(Q.find(model, 2), both_on), '[10] Quest 2 (Weekly)', 'Weekly')
	eq(TR.TitleText(Q.find(model, 3), both_on), '[10] Quest 3', 'a frequency that is neither adds nothing')
	local fourth = Q.find(model, 4)
	check(fourth ~= nil, 'a quest with a secret title is in the model')
	eq(fourth.title, secret, 'its title is the secret as it is')
	eq(TR.TitleText(fourth, both_on), secret, 'shown as it is: no prefix, no tags')
	eq(#Q.find(model, 5).tags, 0, 'a secret tag name is no tag')
	eq(TR.TitleText(Q.find(model, 5), both_on), '[10] Quest 5', 'and adds nothing')
	restore()
end)

both('objectives: a sequenced quest cut after its first unfinished one; Hide finished objectives; Objectives of finished quests', function(st, TR)
	local function objectives(...)
		local list = {}
		for i, finished in ipairs({ ... }) do
			list[i] = { text = 'obj ' .. i, type = 'monster', finished = finished, numFulfilled = finished and 1 or 0, numRequired = 1 }
		end
		return list
	end
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { sequenced = true, objectives = objectives(true, false, false) }),
		Q.quest(2, { objectives = objectives(true, false, false) }),
		Q.quest(3, { complete = true, completion = 'Go back', objectives = objectives(true, true) }),
		Q.quest(4, { objectives = {
			{ text = 'Fill the bar', type = 'progressbar', finished = false, numFulfilled = 45, numRequired = 100 },
		}, percent = 45 }),
	}, { 1, 2, 3, 4 })
	local model = TR.Model.Read('tracked')
	local plain = Q.settings(st, { hide_finished = false, finished_objectives = false, bars = true })
	eq(lines_text(TR.QuestLines(Q.find(model, 1), plain)), 'objective:obj 1:completed | objective:obj 2:normal', 'sequenced: up to and with the first unfinished')
	eq(lines_text(TR.QuestLines(Q.find(model, 2), plain)), 'objective:obj 1:completed | objective:obj 2:normal | objective:obj 3:normal', 'not sequenced: all of them')
	local hide = Q.settings(st, { hide_finished = true })
	eq(lines_text(TR.QuestLines(Q.find(model, 1), hide)), 'objective:obj 2:normal', 'Hide finished objectives, sequenced')
	eq(lines_text(TR.QuestLines(Q.find(model, 2), hide)), 'objective:obj 2:normal | objective:obj 3:normal', 'Hide finished objectives')
	eq(lines_text(TR.QuestLines(Q.find(model, 3), plain)), 'completion:Go back:completed', 'a finished quest: its completion text alone')
	eq(lines_text(TR.QuestLines(Q.find(model, 3), Q.settings(st, { finished_objectives = true }))),
		'objective:obj 1:completed | objective:obj 2:completed | completion:Go back:completed', 'Objectives of finished quests on')
	local bar = TR.QuestLines(Q.find(model, 4), plain)
	eq(#bar, 1, 'a progress bar objective is one line')
	eq(bar[1].kind, 'bar', 'the bar, in place of its text')
	eq(bar[1].value, 45, 'at the quest\'s percent')
	eq(bar[1].text, '45%', 'with the percent as its text')
	local text = TR.QuestLines(Q.find(model, 4), Q.settings(st, { bars = false }))
	eq(lines_text(text), 'objective:Fill the bar:normal', 'Progress bars off: its text line')
	eq(Q.find(model, 4).objectives[1].percent, 45, 'the model has the objective\'s percent')
end)

both('complete, failed, auto-complete: the completion text, else QUEST_WATCH_QUEST_READY; "Failed"; complete then click', function(st, TR)
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { complete = true, completion = 'Return to Bob' }),
		Q.quest(2, { complete = true }),
		Q.quest(3, { failed = true, objectives = { { text = 'x', type = 'event', finished = false } } }),
		Q.quest(4, { complete = true, auto = true, completion = 'ignored' }),
		Q.quest(5, { ready = true }),
		Q.quest(6, { failed = true, complete = true }),
	}, { 1, 2, 3, 4, 5, 6 })
	local model = TR.Model.Read('tracked')
	local settings = Q.settings(st)
	eq(Q.find(model, 1).completionText, 'Return to Bob', 'the completion text is read')
	eq(Q.find(model, 2).completionText, nil, 'and nil without one')
	eq(lines_text(TR.QuestLines(Q.find(model, 1), settings)), 'completion:Return to Bob:completed', 'the completion text')
	eq(lines_text(TR.QuestLines(Q.find(model, 2), settings)), 'completion:' .. QUEST_WATCH_QUEST_READY .. ':completed', 'else Ready for turn-in')
	eq(lines_text(TR.QuestLines(Q.find(model, 3), settings)), 'failed:Failed:failed', 'failed: one line')
	eq(lines_text(TR.QuestLines(Q.find(model, 4), settings)),
		'complete:' .. QUEST_WATCH_QUEST_COMPLETE .. ':completed | click:' .. QUEST_WATCH_CLICK_TO_COMPLETE .. ':completed', 'auto-complete: complete, then click')
	eq(Q.find(model, 4).auto, true, 'auto')
	eq(Q.find(model, 5).ready, true, 'ready')
	eq(lines_text(TR.QuestLines(Q.find(model, 5), settings)), 'completion:' .. QUEST_WATCH_QUEST_READY .. ':completed', 'ready to turn in counts as finished')
	eq(lines_text(TR.QuestLines(Q.find(model, 6), settings)), 'completion:' .. QUEST_WATCH_QUEST_READY .. ':completed', 'complete beats failed, as Blizzard\'s')
	check(TR.Model.Finished(Q.find(model, 5)) and not TR.Model.Finished(Q.find(model, 3)), 'Finished')
end)

both('money only while more is needed; the timer from GetQuestTimers on Forever, GetTimeAllowed on retail; TimeText 4:32 and 1:04:32', function(st, TR, client)
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { money = 15000 }),
		Q.quest(2, { timer = 272, time = { total = 600, elapsed = 100 } }),
		Q.quest(3, { time = { total = 600, elapsed = 600 } }),
		Q.quest(4, { timer = 30, time = { total = 600, elapsed = 570 } }),
		Q.quest(5, { complete = true, money = 15000, timer = 100, time = { total = 600, elapsed = 100 } }),
	}, { 1, 2, 3, 4, 5 })
	stub.money = 10000
	stub.time = 1000
	local model = TR.Model.Read('tracked')
	local settings = Q.settings(st, { timers = true })
	eq(Q.find(model, 1).money.have, 10000, 'money: what the player has')
	eq(Q.find(model, 1).money.need, 15000, 'and what the quest needs')
	local money = TR.QuestLines(Q.find(model, 1), settings)
	eq(money[1].kind, 'money', 'a money line')
	eq(money[1].text, GetMoneyString(10000) .. ' / ' .. GetMoneyString(15000), 'have / need')
	stub.money = 20000
	eq(TR.Model.Read('tracked').quests[1].money, nil, 'no money once the player has enough')
	stub.money = 10000

	local forever = client == 'forever'
	eq(Q.find(model, 2).timeLeft, forever and 272 or 500, forever and 'Forever: questTimer is the time left' or 'retail: total minus elapsed')
	eq(Q.find(model, 3).timeLeft, nil, forever and 'Forever: not in GetQuestTimers' or 'retail: nothing left')
	local line = TR.QuestLines(Q.find(model, 2), settings)[1]
	eq(line.kind, 'timer', 'a timer line')
	eq(line.text, 'Time left: ' .. (forever and '4:32' or '8:20'), 'the time left')
	eq(line.state, 'normal', 'in the normal color')
	local later = TR.QuestLines(Q.find(model, 2), settings, 1010)[1]
	eq(later.text, 'Time left: ' .. (forever and '4:22' or '8:10'), 'counted down from the read: 10 seconds on')
	eq(#TR.QuestLines(Q.find(model, 2), Q.settings(st, { timers = false })), 0, 'Timers off')
	local under = TR.QuestLines(Q.find(model, 4), settings)[1]
	eq(under.state, 'failed', 'under a minute: in the failed color')
	eq(#TR.QuestLines(Q.find(model, 4), settings, 1030), 0, 'a timer that has run out is no line')
	eq(#TR.QuestLines(Q.find(model, 5), settings), 1, 'a finished quest: its completion line only, no money and no timer')

	eq(TR.TimeText(272), '4:32', 'TimeText: minutes and seconds')
	eq(TR.TimeText(3872), '1:04:32', 'TimeText: from an hour up')
	eq(TR.TimeText(59.9), '0:59', 'TimeText: whole seconds')
	eq(TR.TimeText(-5), '0:00', 'TimeText: never negative')
	eq(TR.TimeText(nil), '', 'TimeText: nothing')
end)

both("the item and show-when-complete; area, distance (none when the API returns nothing), the focused quest's waypoint", function(st, TR)
	local item = { link = '|cffffffff|Hitem:6948::::::::|h[Hearthstone]|h|r', texture = 134414, charges = 3, showWhenComplete = false,
		cooldown = { start = 5, duration = 30, enable = 1 }, range = 1 }
	Q.set({
		Q.header('Zone'),
		Q.quest(1, { item = item, inArea = true, distance = { sq = 400, onContinent = true }, waypoint = 'Take the boat' }),
		Q.quest(2, { complete = true, item = item, waypoint = 'Not shown' }),
		Q.quest(3, { complete = true, item = { link = 'l', texture = 1, showWhenComplete = true } }),
		Q.quest(4),
	}, { 1, 2, 3, 4 }, { focused = 1 })
	local model = TR.Model.Read('tracked')
	local first = Q.find(model, 1)
	eq(first.item.link, item.link, 'the item\'s link')
	eq(first.item.texture, 134414, 'its texture')
	eq(first.item.charges, 3, 'its charges')
	eq(first.item.cooldown.start, 5, 'its cooldown starts')
	eq(first.item.cooldown.duration, 30, 'and lasts')
	eq(first.item.range, 1, 'its range: 1 in range')
	eq(Q.find(model, 2).item, nil, 'a complete quest whose item does not show when complete: none')
	check(Q.find(model, 3).item ~= nil, 'one that does: kept')
	eq(Q.find(model, 3).item.showWhenComplete, true, 'with the flag')
	eq(Q.find(model, 4).item, nil, 'no item')
	eq(first.inArea, true, 'inside the quest\'s area')
	eq(Q.find(model, 4).inArea, false, 'outside it')
	eq(first.distanceSq, 400, 'the distance squared')
	eq(first.onContinent, true, 'on the continent')
	eq(Q.find(model, 4).distanceSq, nil, 'no distance when the API returns nothing')
	eq(Q.find(model, 4).onContinent, nil, 'and no continent')
	eq(model.focused, 1, 'the focused quest')
	eq(first.waypoint, 'Take the boat', 'its waypoint')
	eq(Q.find(model, 2).waypoint, nil, 'only the focused quest has one')
	eq(lines_text(TR.QuestLines(first, Q.settings(st, { waypoint = true }))), 'waypoint:Waypoint: Take the boat:normal', 'the waypoint line')
	eq(#TR.QuestLines(first, Q.settings(st, { waypoint = false })), 0, 'Waypoint off')
	stub.quests.focused = 0
	eq(TR.Model.Read('tracked').focused, nil, 'none focused')
end)

both('popups, none while SplashFrame shows; no quests in an arena; the counts', function(st, TR)
	Q.set({
		Q.header('Zone'),
		Q.quest(1), Q.quest(2), Q.quest(3, { task = true }),
		Q.header('Other zone'), Q.quest(4),
	}, { 1, 2 }, { popups = { { id = 1, kind = 'COMPLETE' }, { id = 2, kind = 'OFFER' }, { id = 99, kind = 'OFFER' } } })
	local model = TR.Model.Read('tracked')
	eq(#model.popups, 2, 'the popups, but not one for a quest with no title')
	eq(model.popups[1].id, 1, 'the first popup\'s quest')
	eq(model.popups[1].kind, 'COMPLETE', 'its kind')
	eq(model.popups[1].title, 'Quest 1', 'its title')
	eq(model.popups[2].kind, 'OFFER', 'the second')
	eq(model.counts.inLog, 3, 'quests in the log (no headers, no tasks)')
	eq(model.counts.max, 35, 'the most the log holds')
	eq(model.counts.watched, 2, 'tracked')
	eq(model.counts.watchMax, 25, 'the most that can be tracked')
	eq(model.arena, false, 'not an arena')

	SplashFrame = CreateFrame('Frame')
	SplashFrame:Show()
	eq(#TR.Model.Read('tracked').popups, 0, 'no popups while the splash screen shows')
	eq(#TR.Model.Read('tracked').quests, 2, 'the quests still show')
	SplashFrame:Hide()
	eq(#TR.Model.Read('tracked').popups, 2, 'and they are back when it goes')

	stub.instance = { name = 'Ruins of Lordaeron', type = 'arena' }
	local arena = TR.Model.Read('tracked')
	eq(arena.arena, true, 'an arena')
	eq(#arena.quests, 0, 'no quests in an arena')
	eq(#arena.popups, 0, 'no popups')
	eq(arena.counts.watched, 2, 'the counts are still read')
	stub.instance = { name = 'Deadmines', type = 'party' }
	eq(#TR.Model.Read('tracked').quests, 2, 'a dungeon is not an arena')
end)

both("the current zone's quests with Show set to Tracked and the current zone's: untracked ones read, tracked = false", function(st, TR)
	stub.maps = {
		[1415] = { name = 'Eastern Kingdoms', mapType = Enum.UIMapType.Continent, parentMapID = 947 },
		[1429] = { name = 'Elwynn Forest', mapType = Enum.UIMapType.Zone, parentMapID = 1415 },
		[1430] = { name = 'Goldshire', mapType = Enum.UIMapType.Micro, parentMapID = 1429 },
	}
	stub.player_map = 1430
	Q.set({
		Q.header('Elwynn Forest'),
		Q.quest(1), Q.quest(2), Q.quest(3, { hidden = true }), Q.quest(4),
		Q.header('Westfall'),
		Q.quest(5), Q.quest(6),
	}, { 5, 4 })
	local tracked = TR.Model.Read('tracked')
	eq(Q.ids(tracked), '5,4', 'Tracked: only the watch list')
	local zone = TR.Model.Read('zone')
	eq(zone.zoneNames[1], 'Elwynn Forest', 'the zone, climbed out of the micro map')
	eq(Q.ids(zone), '5,4,1,2', "Tracked and the current zone's: the tracked first, then the zone's others in log order, not the hidden one or Westfall's")
	eq(Q.find(zone, 5).tracked, true, 'a tracked quest')
	eq(Q.find(zone, 1).tracked, false, 'an untracked one reads tracked = false')
	eq(Q.find(zone, 1).watchIndex, nil, 'with no watch index')
	eq(Q.find(zone, 1).headerTitle, 'Elwynn Forest', 'and its header')
	eq(Q.find(zone, 1).logIndex, 2, 'and its log index')
	eq(#zone.quests[1].objectives, 0, 'read like any quest')
	check(Q.find(zone, 4).tracked, 'a tracked quest of the zone stays in its place among the tracked')
	stub.real_zone_text = 'Westfall'
	eq(Q.ids(TR.Model.Read('zone')), '5,4,1,2,6', 'GetRealZoneText names Westfall a current zone too')
end)

both('the zone names: the map\'s, GetRealZoneText\'s, GetZoneText\'s, once each', function(st, TR)
	stub.maps = {
		[1429] = { name = 'Elwynn Forest', mapType = Enum.UIMapType.Zone, parentMapID = 1415 },
		[1500] = { name = 'The Stockade', mapType = Enum.UIMapType.Orphan, parentMapID = 1429 },
		[1415] = { name = 'Eastern Kingdoms', mapType = Enum.UIMapType.Continent },
	}
	stub.player_map = 1429
	stub.real_zone_text = 'Elwynn Forest'
	stub.zone_text = 'Goldshire'
	eq(table.concat(TR.Model.ZoneNames(), '|'), 'Elwynn Forest|Goldshire', 'no repeats')
	stub.real_zone_text = 'Stormwind'
	eq(table.concat(TR.Model.ZoneNames(), '|'), 'Elwynn Forest|Stormwind|Goldshire', 'in that order')
	stub.player_map = 1500
	eq(table.concat(TR.Model.ZoneNames(), '|'), 'The Stockade|Stormwind|Goldshire', 'it stops at an Orphan map: the climb does not reach the zone')
	stub.player_map = 1415
	eq(table.concat(TR.Model.ZoneNames(), '|'), 'Stormwind|Goldshire', 'a continent is no zone')
	stub.player_map = nil
	eq(table.concat(TR.Model.ZoneNames(), '|'), 'Stormwind|Goldshire', 'no map (a loading screen)')
	stub.real_zone_text, stub.zone_text = '', ''
	eq(#TR.Model.ZoneNames(), 0, 'no names at all')
	local restore = S.install()
	stub.real_zone_text = S.secret('zone')
	stub.zone_text = 'Goldshire'
	eq(table.concat(TR.Model.ZoneNames(), '|'), 'Goldshire', 'a secret name is left out')
	restore()
end)

both('a missing function makes its part absent; a secret value (level, numbers, distance) counts as missing', function(st, TR)
	local item = { link = 'l', texture = 1, showWhenComplete = true, cooldown = { start = 1, duration = 2, enable = 1 }, range = 0 }
	Q.set({
		Q.header('Zone'),
		Q.quest(1, {
			level = 12, tag = { tagName = 'Elite', tagID = 1, isElite = true }, elite = true, frequency = 1,
			objectives = { { text = 'obj', type = 'monster', finished = false, numFulfilled = 1, numRequired = 2 } },
			money = 500, timer = 100, time = { total = 200, elapsed = 50 }, item = item, inArea = true,
			distance = { sq = 9, onContinent = true }, waypoint = 'w', completion = 'done', complete = true,
		}),
	}, { 1 }, { focused = 1 })
	stub.money = 0
	local full = TR.Model.Read('zone')
	local quest = full.quests[1]
	check(quest.item and quest.level and quest.inArea ~= nil and quest.distanceSq and quest.waypoint, 'with every API, every part is there')

	local function without(label, remove, restore_fn, check_fn)
		remove()
		local ok, model = pcall(TR.Model.Read, 'zone')
		restore_fn()
		check(ok, label .. ': no error (' .. tostring(model) .. ')')
		if ok and check_fn then check_fn(model.quests[1], model) end
	end
	local function drop_member(tbl_name, name, check_fn)
		local tbl = _G[tbl_name]
		local saved = tbl and tbl[name]
		without(tbl_name .. '.' .. name .. ' missing', function() if tbl then tbl[name] = nil end end,
			function() if tbl then tbl[name] = saved end end, check_fn)
	end
	local function drop_global(name, check_fn)
		local saved = _G[name]
		without(name .. ' missing', function() _G[name] = nil end, function() _G[name] = saved end, check_fn)
	end

	drop_member('C_QuestLog', 'GetQuestObjectives', function(q) eq(#q.objectives, 0, 'no objectives') end)
	drop_member('C_QuestLog', 'IsComplete', function(q) eq(q.complete, false, 'not complete') end)
	drop_member('C_QuestLog', 'GetDistanceSqToQuest', function(q) eq(q.distanceSq, nil, 'no distance') end)
	drop_member('C_QuestLog', 'GetNextWaypointText', function(q) eq(q.waypoint, nil, 'no waypoint') end)
	drop_member('C_QuestLog', 'GetRequiredMoney', function(q) eq(q.money, nil, 'no money') end)
	drop_member('C_QuestLog', 'GetQuestTagInfo', function(q) eq(#q.tags, 1, 'only the frequency tag') end)
	drop_member('C_QuestLog', 'GetHeaderIndexForQuest', function(q) eq(q.headerTitle, nil, 'no header') end)
	drop_member('C_QuestLog', 'IsQuestCalling', function(q) eq(q.calling, false, 'not a calling') end)
	drop_member('C_QuestLog', 'GetTimeAllowed', function(q) eq(q.timeLeft, stub.interface == 16001 and 100 or nil, 'timer') end)
	drop_member('C_QuestLog', 'GetQuestTimers', function(q) eq(q.timeLeft, 150, 'Forever without GetQuestTimers reads GetTimeAllowed') end)
	drop_member('C_QuestLog', 'IsEliteQuest', function(q) eq(q.elite, true, "falls back to the tag's isElite") end)
	drop_member('C_QuestLog', 'GetNumQuestLogEntries', function(_, m) eq(m.counts.inLog, nil, 'no log count') end)
	drop_member('C_QuestLog', 'GetMaxNumQuestsCanAccept', function(_, m) eq(m.counts.max, nil, 'no max') end)
	drop_member('C_SuperTrack', 'GetSuperTrackedQuestID', function(q, m) eq(m.focused, nil, 'none focused') eq(q.waypoint, nil, 'so no waypoint') end)
	drop_member('C_Minimap', 'IsInsideQuestBlob', function(q) eq(q.inArea, nil, 'no area') end)
	drop_member('C_PlayerInfo', 'GetContentDifficultyQuestForPlayer', function(q) eq(q.difficultyColor, nil, 'no color') end)
	drop_member('C_Map', 'GetBestMapForUnit', function(_, m) eq(type(m.zoneNames), 'table', 'zone names still') end)
	drop_global('GetQuestLogSpecialItemInfo', function(q) eq(q.item, nil, 'no item') end)
	drop_global('GetQuestLogSpecialItemCooldown', function(q) eq(q.item.cooldown, nil, 'no cooldown') end)
	drop_global('IsQuestLogSpecialItemInRange', function(q) eq(q.item.range, nil, 'no range') end)
	drop_global('GetQuestLogCompletionText', function(q) eq(q.completionText, nil, 'no completion text') end)
	drop_global('IsQuestSequenced', function(q) eq(q.sequenced, false, 'not sequenced') end)
	drop_global('GetMoney', function(q) eq(q.money, nil, 'no money') end)
	drop_global('GetDifficultyColor', function(q) eq(q.difficultyColor, nil, 'no color') end)
	drop_global('GetNumAutoQuestPopUps', function(_, m) eq(#m.popups, 0, 'no popups') end)
	drop_global('GetAutoQuestPopUp', function(_, m) eq(#m.popups, 0, 'no popups') end)
	drop_global('IsInInstance', function(_, m) eq(m.arena, false, 'not an arena') end)
	drop_global('GetRealZoneText', function(_, m) eq(type(m.zoneNames), 'table', 'zone names') end)
	drop_global('Constants', function(_, m) eq(m.counts.watchMax, nil, 'no watch limit') end)
	drop_global('C_QuestLog', function(_, m) eq(#m.quests, 0, 'no quest API, no quests') end)
	drop_global('C_Map', function(_, m) eq(type(m.zoneNames), 'table', 'zone names') end)
	drop_member('Enum', 'QuestFrequency', function(q) eq(#q.tags, 1, 'no enum: only the tag') end)
	drop_global('DAILY', function(q) eq(#q.tags, 1, 'no string: no frequency tag') end)

	-- Secret values, in everything the model reads.
	local restore = S.install()
	local function secret(label) return S.secret(label) end
	Q.set({
		Q.header('Zone'),
		Q.quest(1, {
			level = secret('level'), scaled = secret('scaled'), money = secret('money'), timer = secret('timer'),
			time = { total = secret('total'), elapsed = secret('elapsed') }, distance = { sq = secret('sq'), onContinent = secret('cont') },
			objectives = { { text = secret('text'), type = 'monster', finished = secret('finished'), numFulfilled = secret('n'), numRequired = secret('m') } },
			complete = secret('complete'), failed = secret('failed'), ready = secret('ready'), auto = secret('auto'),
			sequenced = secret('seq'), waypoint = secret('wp'), calling = secret('calling'), overrides = secret('over'),
			elite = secret('elite'), inArea = secret('area'), item = { link = secret('link'), texture = secret('tex'), charges = secret('charges') },
			frequency = secret('freq'), tag = { tagName = secret('tagName'), tagID = 1, isElite = secret('isElite') },
			difficulty = secret('difficulty'), completion = secret('completion'),
		}),
		Q.quest(2, { hidden = secret('hidden'), task = secret('task'), bounty = secret('bounty'), disabled = secret('disabled') }),
	}, { 1, 2 }, { focused = 1 })
	stub.money = 5
	local ok, model = pcall(TR.Model.Read, 'zone')
	check(ok, 'secret values: Read does not error (' .. tostring(model) .. ')')
	if ok then
		local q = model.quests[1]
		eq(#model.quests, 2, 'a secret flag does not hide a quest')
		eq(q.level, nil, 'a secret level is no level')
		eq(q.money, nil, 'a secret money')
		eq(q.timeLeft, nil, 'a secret time')
		eq(q.distanceSq, nil, 'a secret distance')
		eq(q.onContinent, nil, 'and no continent')
		eq(q.objectives[1].text, nil, 'a secret objective text')
		eq(q.objectives[1].numFulfilled, nil, 'a secret number')
		eq(q.objectives[1].finished, false, 'a secret flag is not set')
		eq(q.complete, false, 'a secret complete is not complete')
		eq(q.waypoint, nil, 'a secret waypoint')
		eq(q.difficultyColor, nil, 'a secret difficulty has no color')
		eq(q.item, nil, 'an item with a secret texture is none')
		eq(#q.tags, 0, 'no tags')
		eq(q.elite, false, 'a secret elite is not elite')
		local ok2, lines = pcall(TR.QuestLines, q, Q.settings(st, { timers = true, waypoint = true }), 5)
		check(ok2, 'QuestLines on it: no error (' .. tostring(lines) .. ')')
		local ok3, title = pcall(TR.TitleText, q, Q.settings(st, { level = true, tags = true }))
		check(ok3 and title == 'Quest 1', 'TitleText on it: no level, no tags (' .. tostring(title) .. ')')
	end
	restore()
end)

both("quests the log can't place: no header, a header with no info, a secret header title, no title yet", function(st, TR)
	local restore = S.install()
	local untitled = Q.quest(7)
	untitled.title = nil
	Q.set({
		Q.quest(1), -- above every header: the log can't place it
		Q.header('Zone'),
		Q.quest(2), -- placed
		Q.header(S.secret('header title')),
		Q.quest(3), -- under a header whose title is secret
		Q.quest(4, { title = '' }), -- no title yet
		Q.quest(5), -- its header index points past the log
		Q.quest(6), -- its header index points at a quest, not a header
		untitled, -- no title at all
	}, { 1, 2, 3, 4, 5, 6, 7 })
	local real = C_QuestLog.GetHeaderIndexForQuest
	C_QuestLog.GetHeaderIndexForQuest = function(questID)
		if questID == 5 then return 99 end
		if questID == 6 then return 1 end
		return real(questID)
	end
	local model = TR.Model.Read('tracked')
	C_QuestLog.GetHeaderIndexForQuest = real
	eq(Q.ids(model), '1,2,3,5,6', 'the untitled quests are not in the model')
	eq(Q.find(model, 1).headerTitle, nil, 'no header: nil (Other)')
	eq(Q.find(model, 2).headerTitle, 'Zone', 'a placed quest has its header')
	eq(Q.find(model, 3).headerTitle, nil, 'a secret header title: nil (Other)')
	eq(Q.find(model, 5).headerTitle, nil, 'a header index GetInfo gives nothing for: nil (Other)')
	eq(Q.find(model, 6).headerTitle, nil, 'a header index that is not a header: nil (Other)')
	eq(Q.find(model, 1).campaign, nil, 'and no campaign')
	eq(#take_errors(), 0, 'none of it reports an error')
	restore()
end)

test('nothing at file scope: the model and the groups define functions only', function()
	-- TW.world loads the TOC with st.config absent and counts what the files make.
	for _, client in ipairs({ 'forever', 'retail' }) do
		TW.world({ client = client })
		eq(TW.counts.frames, 0, client .. ': no frame')
		eq(TW.counts.events, 0, client .. ': no event')
		eq(TW.counts.hooks, 0, client .. ': no hook')
		eq(TW.counts.timers, 0, client .. ': no timer')
	end
end)
