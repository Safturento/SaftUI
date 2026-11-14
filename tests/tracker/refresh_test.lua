-- SaftUI's tracker's refresh (SaftUI-Tracker/init.lua, rows.lua): the events
-- that mark it dirty, the throttle, and what a refresh costs. The design makes
-- performance a goal ("a tracker that stutters on quest log updates" is an
-- anti-goal), so these are measured: a burst of events makes one refresh per
-- frame and at most one per 0.1 s, a second refresh makes no frame, and one that
-- changed nothing sets no text.
--
-- Real: SaftUI-Tracker's files over the quest stubs; time and timers are
-- stub.time and stub.run_timers().
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q
local S = load_test_file('lib/secrets.lua')

-- Counts the refreshes TR makes from now on.
local function count_refreshes(TR)
	local counted = { n = 0 }
	local refresh = TR.Refresh
	TR.Refresh = function(self, ...)
		counted.n = counted.n + 1
		return refresh(self, ...)
	end
	return counted
end

local function quiet_log()
	Q.set({ Q.header('Elwynn Forest'), Q.quest(1), Q.quest(2) }, { 1, 2 })
end

RW.both('twenty QUEST_LOG_UPDATEs in one frame make one refresh', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	for _ = 1, 20 do stub.fire_event('QUEST_LOG_UPDATE') end
	eq(counted.n, 0, 'nothing refreshes inside the frame')
	RW.later(0)
	eq(counted.n, 1, 'one refresh on the next frame')
	RW.later(1)
	eq(counted.n, 1, 'and no more')
	eq(#TR.pools.quest.rows, 2, 'it drew the two quests')
end)

RW.both('every event of the list marks it dirty, once per frame, whichever mix', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	for _, event in ipairs(TR.EVENTS) do
		if event ~= 'PLAYER_MONEY' and event ~= 'BAG_UPDATE_COOLDOWN' then
			counted.n = 0
			stub.fire_event(event, 'player')
			stub.fire_event(event, 'player')
			RW.later(1)
			eq(counted.n, 1, event .. ': one refresh')
		end
	end
	counted.n = 0
	stub.fire_event('QUEST_ACCEPTED')
	stub.fire_event('QUEST_REMOVED')
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	eq(counted.n, 1, 'a mix of events: one refresh')
end)

RW.both('UNIT_QUEST_LOG_CHANGED is for the player only; PLAYER_MONEY only while a quest needs money', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	stub.fire_event('UNIT_QUEST_LOG_CHANGED', 'target')
	RW.later(1)
	eq(counted.n, 0, 'another unit: nothing')
	stub.fire_event('UNIT_QUEST_LOG_CHANGED', 'player')
	RW.later(1)
	eq(counted.n, 1, 'the player')

	counted.n = 0
	stub.fire_event('PLAYER_MONEY')
	RW.later(1)
	eq(counted.n, 0, 'no quest needs money: PLAYER_MONEY is not heard')

	stub.money = 100
	Q.set({ Q.header('Elwynn Forest'), Q.quest(1, { money = 5000 }) }, { 1 })
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	counted.n = 0
	stub.fire_event('PLAYER_MONEY')
	RW.later(1)
	eq(counted.n, 1, 'a quest needs more money than the player has: PLAYER_MONEY refreshes')

	stub.money = 9000
	stub.fire_event('PLAYER_MONEY')
	RW.later(1)
	counted.n = 0
	stub.fire_event('PLAYER_MONEY')
	RW.later(1)
	eq(counted.n, 0, 'the money is enough, and the next refresh dropped the event')
end)

RW.both('a burst refreshes at most every 0.1 seconds', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	-- 100 events, one every 10 ms: a second.
	for _ = 1, 100 do
		stub.fire_event('QUEST_LOG_UPDATE')
		RW.later(0.01)
	end
	RW.later(0.2)
	check(counted.n >= 8, 'it did refresh, about every 0.1 s: ' .. counted.n)
	check(counted.n <= 11, 'at most every 0.1 s over a second (11 with the first): ' .. counted.n)
	-- One event after a quiet second refreshes at once, on the next frame.
	counted.n = 0
	RW.later(1)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(0)
	eq(counted.n, 1, 'after a quiet second the first one is not made to wait')
	-- Straight after a refresh it waits out the rest of the gap.
	counted.n = 0
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(0.05)
	eq(counted.n, 0, 'inside the gap: waiting')
	RW.later(0.06)
	eq(counted.n, 1, 'the gap over: refreshed')
end)

-- The controller's ruling (2026-11-14): every event goes through one throttle.
RW.both('a lone event, of any kind, refreshes on the next frame', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	for _, event in ipairs({ 'QUEST_LOG_UPDATE', 'UNIT_QUEST_LOG_CHANGED', 'QUEST_WATCH_UPDATE', 'SUPER_TRACKING_CHANGED', 'QUEST_ACCEPTED' }) do
		counted.n = 0
		stub.fire_event(event, 'player')
		eq(counted.n, 0, event .. ': not inside the frame')
		RW.later(0)
		eq(counted.n, 1, event .. ': on the next frame')
		RW.later(1)
	end
end)

RW.both('events within the gap of the last refresh are coalesced into one at the end of the gap, whatever their kind', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(0)
	eq(counted.n, 1, 'the first')
	RW.later(0.03)
	for _, event in ipairs({ 'QUEST_LOG_UPDATE', 'UNIT_QUEST_LOG_CHANGED', 'QUEST_WATCH_UPDATE', 'SUPER_TRACKING_CHANGED', 'QUEST_REMOVED' }) do
		stub.fire_event(event, 'player')
	end
	RW.later(0.03)
	eq(counted.n, 1, 'inside the gap: waiting')
	RW.later(0.05)
	eq(counted.n, 2, 'the gap over: one refresh for all of them')
	RW.later(1)
	eq(counted.n, 2, 'and no more')
end)

RW.both('a pending refresh is not pushed back by new events, and the last event of a burst is drawn', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(0)
	local started = stub.time
	local refreshed_at = {}
	local refresh = TR.Refresh
	TR.Refresh = function(self, ...)
		refreshed_at[#refreshed_at + 1] = stub.time - started
		return refresh(self, ...)
	end
	for _ = 1, 40 do
		RW.later(0.01)
		stub.fire_event('QUEST_LOG_UPDATE')
	end
	-- 0.4 s of events, one every 10 ms: refreshes at every 0.1 s, none starved.
	check(#refreshed_at >= 3 and #refreshed_at <= 5, 'about every 0.1 s: ' .. #refreshed_at)
	for i = 2, #refreshed_at do
		check(refreshed_at[i] - refreshed_at[i - 1] <= 0.1001 + 1e-9, 'refresh ' .. i .. ' came no later than 0.1 s after the one before')
	end
	-- The last change of a burst is drawn.
	Q.set({ Q.header('Elwynn Forest'), Q.quest(1), Q.quest(2), Q.quest(3, { title = 'Last one' }) }, { 1, 2, 3 })
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(0.2)
	check(RW.quest(TR, 3) ~= nil and RW.text(RW.quest(TR, 3).title):find('Last one', 1, true), 'the last event of the burst is drawn')
end)

RW.both('one kill a frame for 2 seconds, with the events a kill brings, refreshes at most 21 times, and makes no timer per event', function(st, TR)
	quiet_log()
	RW.later(1)
	local counted = count_refreshes(TR)
	local before = #stub.timers
	local max_pending = 0
	for _ = 1, 120 do
		for _, event in ipairs({ 'UNIT_QUEST_LOG_CHANGED', 'QUEST_WATCH_UPDATE', 'QUEST_LOG_UPDATE', 'QUEST_LOG_UPDATE' }) do
			stub.fire_event(event, 'player')
		end
		max_pending = math.max(max_pending, #stub.timers)
		RW.later(1 / 60)
	end
	RW.later(0.2)
	check(counted.n <= 21, 'at most 21 refreshes over 2 seconds: ' .. counted.n)
	check(counted.n >= 15, 'and it did refresh: ' .. counted.n)
	check(max_pending <= before + 2, 'one pending timer at a time, not one per event: ' .. max_pending)
end)

RW.both('a second refresh makes no frame; a refresh with nothing changed sets no text', function(st, TR)
	st.config.profile.tracker.quests.zones = true
	stub.real_zone_text = 'Elwynn Forest'
	Q.set({
		Q.header('Elwynn Forest'),
		Q.quest(1, { objectives = { { text = '3/8 Boars slain', type = 'monster', numFulfilled = 3, numRequired = 8 },
			{ text = 'Done', type = 'monster', finished = true } }, waypoint = 'Take the boat' }),
		Q.quest(2, { objectives = { { text = '', type = 'progressbar' } }, percent = 45 }),
		Q.quest(3, { complete = true, completion = 'Return to Marshal McBride' }),
		Q.quest(4, { objectives = { { text = 'Find it', type = 'monster' } }, time = { total = 300, elapsed = 10 }, timer = 290 }),
		Q.header('Westfall'), Q.quest(5), Q.quest(6, { money = 100000 }),
	}, { 1, 2, 3, 4, 5, 6 }, { focused = 1, popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = 'An offer' } })
	stub.money = 50
	RW.later(1)
	TR:Refresh()
	local counter = RW.counter()
	TR:Refresh()
	eq(counter.frames, 0, 'the second refresh made no frame')
	eq(counter.texts, 0, 'and set no text')
	TR:Refresh()
	eq(counter.frames, 0, 'a third: no frame')
	eq(counter.texts, 0, 'no text')
	counter.stop()
	check(#TR.pools.quest.rows >= 6 and #TR.pools.zone.rows == 2 and #TR.pools.popup.rows == 1, 'rows of every kind were drawn')
end)

RW.both('a change sets only the text that changed', function(st, TR)
	stub.real_zone_text = 'Elwynn Forest'
	Q.set({
		Q.header('Elwynn Forest'),
		Q.quest(1, { objectives = { { text = '3/8 Boars slain', type = 'monster' } } }),
		Q.quest(2, { objectives = { { text = '1/2 Wolves', type = 'monster' } } }),
	}, { 1, 2 })
	TR:Refresh()
	local counter = RW.counter()
	stub.quests.log[2].objectives[1].text = '4/8 Boars slain'
	TR:Refresh()
	eq(counter.texts, 1, 'one objective changed: one text set')
	eq(counter.frames, 0, 'no frame')
	counter.stop()
end)

RW.both('a quest keeps its row across refreshes, and a quest that goes leaves none behind', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1), Q.quest(2), Q.quest(3) }, { 1, 2, 3 })
	TR:Refresh()
	local one, two, three = RW.quest(TR, 1), RW.quest(TR, 2), RW.quest(TR, 3)
	check(one and two and three and one ~= two, 'three rows')
	Q.set({ Q.header('A'), Q.quest(2), Q.quest(3) }, { 2, 3 })
	TR:Refresh()
	eq(RW.quest(TR, 2), two, 'quest 2 has its row still')
	eq(RW.quest(TR, 3), three, 'and quest 3')
	eq(RW.quest(TR, 1), nil, 'quest 1 has none')
	check(not one:IsShown(), 'its row is hidden')
	Q.set({ Q.header('A'), Q.quest(2), Q.quest(3), Q.quest(9) }, { 2, 3, 9 })
	local counter = RW.counter()
	TR:Refresh()
	eq(RW.quest(TR, 9), one, 'a new quest takes the free row')
	eq(counter.frames, 0, 'no frame is made while a free row exists')
	counter.stop()
end)

RW.both('a burst on a full log', function(st, TR, client)
	-- Review Focus 4: 25 watched quests and 10 untracked ones of the current zone,
	-- six objectives each, Show the current zone's: 200 events over two seconds.
	st.config.profile.tracker.quests.show = 'zone'
	stub.real_zone_text = 'Elwynn Forest'
	local log, watched, id = {}, {}, 0
	local function add(header, count, tracked)
		log[#log + 1] = Q.header(header)
		for _ = 1, count do
			id = id + 1
			local objectives = {}
			for o = 1, 6 do objectives[o] = { text = ('%d/10 Thing %d'):format(o, o), type = 'monster', numFulfilled = o, numRequired = 10 } end
			log[#log + 1] = Q.quest(id, { objectives = objectives })
			if tracked then watched[#watched + 1] = id end
		end
	end
	add('Westfall', 10, true)
	add('Duskwood', 5, true)
	add('Elwynn Forest', 10, true)
	-- Ten more of Elwynn Forest's, not tracked: a second header of the same title.
	add('Elwynn Forest', 10, false)
	eq(#watched, 25, '25 watched')
	Q.set(log, watched)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)

	local counted = count_refreshes(TR)
	local counter = RW.counter()
	local frames_after_first
	for step = 1, 200 do
		stub.fire_event('QUEST_LOG_UPDATE')
		RW.later(0.01)
		if step == 20 then frames_after_first = counter.frames end
	end
	RW.later(0.2)
	check(counted.n <= 21, client .. ': at most 21 refreshes over 2 seconds: ' .. counted.n)
	check(counted.n >= 15, client .. ': it did refresh about every 0.1 s: ' .. counted.n)
	eq(#TR.pools.quest.rows, 35, 'all 35 quests have a row')
	counter.reset()
	TR:Refresh()
	eq(counter.texts, 0, 'a refresh with nothing changed sets no text')
	eq(counter.frames, 0, 'and makes no frame')
	counter.stop()
	eq(frames_after_first, 0, 'only the very first refresh made frames: none during the burst')
end)

RW.both('the build refreshes once, on the next frame, and nothing runs before it', function(st, TR)
	local counted = count_refreshes(TR)
	RW.later(1)
	eq(counted.n, 0, 'nothing pending after the build: its refresh ran in RW.world')
	local st2, TR2 = TW.world({ on = true, client = st.forever and 'forever' or 'retail' })
	eq(#stub.timers >= 1, true, 'the build left a refresh pending')
	eq(TR2.model, nil, 'but nothing was read yet')
	stub.run_timers()
	check(TR2.model ~= nil, 'the next frame read the model')
end)

RW.both('with the switch off no event is registered and nothing refreshes', function(st, TR, client)
	local st2, TR2 = TW.world({ on = false, client = client })
	eq(TW.counts.events, 0, 'no event registered')
	eq(TW.counts.timers, 0, 'no timer')
	eq(TR2.eventFrame, nil, 'no event frame')
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 })
	stub.fire_event('QUEST_LOG_UPDATE')
	stub.fire_event('PLAYER_ENTERING_WORLD')
	TR2:MarkDirty('QUEST_LOG_UPDATE')
	eq(#stub.timers, 0, 'nothing is pending')
	stub.run_timers()
	eq(TR2.model, nil, 'nothing was read')
	eq(TR2.pools, nil, 'no row pools')
	eq(TR2:OnColorsChanged('button'), nil, 'a color change does nothing')
end)

RW.both('a refresh in combat draws, makes no secure frame and blocks nothing', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { item = { link = 'item:6948', texture = 134400 } }), Q.quest(2) }, { 1, 2 })
	TW.combat(true)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	check(RW.quest(TR, 1) and RW.quest(TR, 2), 'the rows are drawn in combat')
	eq(#stub.blocked, 0, 'nothing was blocked')
	TR:ToggleZone('A')
	eq(#stub.blocked, 0, 'a collapse in combat blocks nothing')
	TW.combat(false)
	RW.later(1)
	eq(#stub.blocked, 0, 'nor at the end of combat')
	check(TR:IsOn(), 'still on')
end)

RW.both('a secret title is drawn as it is; its text is set again, and nothing errors', function(st, TR)
	-- The stub's SetText takes strings only; the game's takes a secret too.
	local methods = getmetatable(UIParent:CreateFontString(nil, 'OVERLAY')).__index
	local set_text = methods.SetText
	local got
	methods.SetText = function(self, text)
		if issecretvalue(text) then
			got = text
			return
		end
		return set_text(self, text)
	end
	local restore = S.install()
	local secret = S.secret('quest title')
	Q.set({ Q.header('A'), Q.quest(1, { title = secret }), Q.quest(2) }, { 1, 2 })
	TR:Refresh()
	eq(got, secret, 'the secret title went to SetText as it is')
	got = nil
	local row = RW.quest(TR, 1)
	check(row ~= nil, 'its row is drawn')
	TR:Refresh()
	eq(got, secret, 'a secret is set on each refresh: it can not be compared')
	restore()
	methods.SetText = set_text
end)

RW.both('the timer ticks once a second while a timed quest shows, and stops with it', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { time = { total = 300, elapsed = 10 }, timer = 290 }), Q.quest(2) }, { 1, 2 })
	TR:Refresh()
	check(TR.timerTicker ~= nil, 'a ticker runs')
	local row = RW.quest(TR, 1)
	local timer = row.parts[1].fs
	eq(RW.text(timer), 'Time left: 4:50', 'the time left')
	RW.later(1)
	eq(RW.text(timer), 'Time left: 4:49', 'a second on')
	RW.later(30)
	eq(RW.text(timer), 'Time left: 4:19', 'counted from the read')
	RW.later(200)
	eq(RW.text(timer), 'Time left: 0:59', 'under a minute')
	eq(RW.color(timer), RW.rgb(st.config.profile.colors.objectives.failed), 'in Failed')
	Q.set({ Q.header('A'), Q.quest(2) }, { 2 })
	TR:Refresh()
	eq(TR.timerTicker, nil, 'no timed quest shows: the ticker is cancelled')
	eq(RW.counter().frames, 0, 'nothing else made')
end)

RW.both('a timer that reaches 0 asks for a refresh', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { time = { total = 300, elapsed = 298 }, timer = 2 }) }, { 1 })
	TR:Refresh()
	local counted = count_refreshes(TR)
	RW.later(1)
	eq(counted.n, 0, 'a second left')
	RW.later(1)
	RW.later(0)
	eq(counted.n, 1, 'time is up: a refresh reads the quest again')
end)
