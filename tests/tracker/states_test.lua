-- SaftUI's tracker in every state together (Task 13): each part has its own
-- tests; these put them side by side, over the looks, placements, handovers and
-- scroll states a player can be in, and check what no single part's test sees:
--   - every state on both clients, over the three looks, the three item
--     placements, Grow, the handover's three states (own, Blizzard's in
--     SaftUI's place, both side by side), collapsed or not, scrolled or not,
--     the tracker on either screen half and size noise up, down and off, sits
--     on whole pixels with nothing blocked and nothing stray on Blizzard's
--     tracker. The states are a pairwise sample: every value of each setting
--     meets every value of every other at least once (the full product is
--     thousands of worlds), and a test checks the sample covers every pair;
--   - combat in and out at each of them: no secure call and no secure frame in
--     combat, the buttons never dimmer than they should be, one pass after;
--   - a theme change, a profile switch and /sui changes at each of them make no
--     new frame;
--   - a profile switch between In the row and Beside the tracker in combat
--     (Task 9's deferred case: decided here, tested here);
--   - the switch off: Blizzard's tracker, the skin and its mover exactly as
--     with SaftUI-Tracker not loaded, through a session's worth of events.
-- Real: SaftUI-Tracker's files, Core's helpers and theme engine, Misc's skin and
-- tracker mover, Blizzard's tracker from the Misc fixture, the quest, section and
-- secure button stubs. The scroll frame is tracker_world.lua's stand-in.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q
local T = load_test_file('lib/theme_helpers.lua')
local P = load_test_file('lib/pixels.lua')

local MISC = { skinning = true, skin = true, otp = true }

------------------------------------------------------------------ the states

local FACTORS = {
	{ key = 'theme', values = { 'thick', 'thin', 'blizzard' } },
	{ key = 'placement', values = { 'row', 'beside', 'off' } },
	{ key = 'grow', values = { 'down', 'up' } },
	{ key = 'handover', values = { 'own', 'blizzard', 'both' } },
	{ key = 'collapsed', values = { false, true } },
	{ key = 'scrolled', values = { false, true } },
	{ key = 'side', values = { 'right', 'left' } },
	{ key = 'noise', values = { 2 ^ -14, -2 ^ -14, 0 } },
}

-- A pairwise sample of the states: a greedy cover of every pair of values of two
-- different factors, each round taking the state (of the whole product) that
-- covers the most pairs not yet covered, the first in product order on a tie, so
-- the sample is the same every run.
local function sample()
	local products = { {} }
	for _, factor in ipairs(FACTORS) do
		local nextProducts = {}
		for _, partial in ipairs(products) do
			for index = 1, #factor.values do
				local copy = { unpack(partial) }
				copy[#copy + 1] = index
				nextProducts[#nextProducts + 1] = copy
			end
		end
		products = nextProducts
	end
	local function pairKey(a, va, b, vb) return a .. ':' .. va .. '/' .. b .. ':' .. vb end
	local uncovered, left = {}, 0
	for a = 1, #FACTORS - 1 do
		for b = a + 1, #FACTORS do
			for va = 1, #FACTORS[a].values do
				for vb = 1, #FACTORS[b].values do
					uncovered[pairKey(a, va, b, vb)] = true
					left = left + 1
				end
			end
		end
	end
	local chosen = {}
	while left > 0 do
		local best, bestGain
		for _, state in ipairs(products) do
			local gain = 0
			for a = 1, #FACTORS - 1 do
				for b = a + 1, #FACTORS do
					if uncovered[pairKey(a, state[a], b, state[b])] then gain = gain + 1 end
				end
			end
			if not bestGain or gain > bestGain then best, bestGain = state, gain end
		end
		for a = 1, #FACTORS - 1 do
			for b = a + 1, #FACTORS do
				local key = pairKey(a, best[a], b, best[b])
				if uncovered[key] then
					uncovered[key] = nil
					left = left - 1
				end
			end
		end
		local state = {}
		for index, factor in ipairs(FACTORS) do state[factor.key] = factor.values[best[index]] end
		chosen[#chosen + 1] = state
	end
	return chosen
end

local STATES = sample()

local function name_of(client, state)
	return ('%s, %s, %s, Grow %s, handover %s, %s, %s, %s side, noise %g'):format(
		client, state.theme, state.placement, state.grow, state.handover,
		state.collapsed and 'collapsed' or 'expanded', state.scrolled and 'scrolled' or 'at the top', state.side, state.noise)
end

test('the states are a pairwise sample: every value meets every other value of another factor at least once', function()
	local seen = {}
	for _, state in ipairs(STATES) do
		for a = 1, #FACTORS - 1 do
			for b = a + 1, #FACTORS do
				seen[FACTORS[a].key .. '=' .. tostring(state[FACTORS[a].key]) .. ' ' .. FACTORS[b].key .. '=' .. tostring(state[FACTORS[b].key])] = true
			end
		end
	end
	local pairs_wanted = 0
	for a = 1, #FACTORS - 1 do
		for b = a + 1, #FACTORS do
			for _, va in ipairs(FACTORS[a].values) do
				for _, vb in ipairs(FACTORS[b].values) do
					pairs_wanted = pairs_wanted + 1
					check(seen[FACTORS[a].key .. '=' .. tostring(va) .. ' ' .. FACTORS[b].key .. '=' .. tostring(vb)], ('%s=%s meets %s=%s'):format(FACTORS[a].key, tostring(va), FACTORS[b].key, tostring(vb)))
				end
			end
		end
	end
	check(pairs_wanted > 100, 'a real number of pairs: ' .. pairs_wanted)
	check(#STATES >= 9 and #STATES <= 40, 'a small sample: ' .. #STATES .. ' states')
end)

------------------------------------------------------------------ the world

local function item_of(id) return { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 } end

local WITH_ITEMS = { [1] = true, [2] = true, [3] = true, [5] = true, [6] = true, [8] = true }

-- Two zones of quests, most with an item, one of each kind of line, a popup.
-- without: quest IDs left out; extra: one more quest with an item (8).
local function log(without, extra)
	local long = 'Gather a great many of the things this long objective asks of you from around the whole zone'
	local entries = {
		Q.header('Elwynn Forest'),
		Q.quest(1, { title = 'One objective', objectives = { { text = '1/2 Wolves', type = 'monster' } } }),
		Q.quest(2, { title = 'Three objectives', objectives = { { text = '1/2 A', type = 'monster' }, { text = '2/3 B', type = 'monster' }, { text = '3/4 C', type = 'monster' } } }),
		Q.quest(3, { title = 'Wrapped objectives with a very long title that wraps on to a second line at this width', objectives = { { text = long, type = 'monster' } }, waypoint = 'Take the boat' }),
		Q.quest(4, { title = 'A bar', objectives = { { text = 'Escort', type = 'progressbar' } }, percent = 37 }),
		Q.header('Westfall'),
		Q.quest(5, { title = 'A timer', objectives = { { text = 'Hurry', type = 'monster' } }, time = { total = 300, elapsed = 10 }, timer = 290 }),
		Q.quest(6, { title = 'An item', objectives = { { text = 'Use it', type = 'item' } } }),
		Q.quest(7, { title = 'Plain' }),
	}
	if extra then entries[#entries + 1] = Q.quest(8, { title = 'Arrived in combat', objectives = { { text = '0/1 Rats', type = 'monster' } } }) end
	local ids, kept = {}, {}
	for _, entry in ipairs(entries) do
		if not entry.header then
			if not (without and without[entry.id]) then
				if WITH_ITEMS[entry.id] then entry.item = item_of(entry.id) end
				ids[#ids + 1] = entry.id
				kept[#kept + 1] = entry
			end
		else
			kept[#kept + 1] = entry
		end
	end
	Q.set(kept, ids, { focused = 3, popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = 'An offer' } })
end

local function settle(seconds) RW.later(seconds or 0.1) end

local function scenario(on)
	stub.probes.scenario = on and { stages = 3, stage = 1 } or { stages = 0 }
	stub.fire_event('SCENARIO_UPDATE')
end

local POSITIONS = {
	right = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -60, y_off = -80 },
	left = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 60, y_off = -80 },
}

-- A world with the switch on, on a screen of 1000 by 600, Blizzard's tracker and
-- Misc's skin and mover built, put in a state. Returns st, TR, OT.
local function world(client, state)
	stub.probes = { watched_tasks = {}, world = {}, world_watches = 0, task_info = {}, tasks = {}, tracked = {}, achievements = {} }
	stub.instance, stub.encounter = nil, false
	local st, TR = RW.world({ client = client, misc = MISC, blizzard = true, screen = { 1000, 600 }, enabling = function() log() end })
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	local OT = TW.OT
	if state then
		T.theme(state.theme, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
		TR.config.items.placement = state.placement
		TR.config.grow = state.grow
		TR.config.height = 300
		TR.config.position = POSITIONS[state.side]
		TR.config.blizzard.mode = state.handover == 'both' and 'beside' or 'place'
		stub.size_noise = state.noise
		TR:UpdateConfig()
		TR:Refresh()
		if state.handover ~= 'own' then
			scenario(true)
			settle()
		end
		if state.collapsed then
			-- (a popup shows the window expanded, Ruling 15: collapse without one)
			stub.quests.popups = {}
			stub.fire_event('QUEST_LOG_UPDATE')
			settle(1)
			TR:SetCollapsed(true)
		end
		if state.scrolled and not state.collapsed then TR:ScrollTo(137.4) end
		TR:Refresh()
		settle(1)
	end
	return st, TR, OT
end

local function near(a, b, within) return math.abs(a - b) <= (within or 1) end

local function shown_buttons(TR)
	local list = {}
	for _, button in ipairs(TR.itemButtons or {}) do
		if button.questID and button:IsShown() then list[#list + 1] = button end
	end
	return list
end

local function concealed(OT) return near(OT.tracker:GetRight(), UIParent:GetLeft() - 100, 0.01) end

-- What every state must be, whole and consistent. where names the state.
local function expect_state(where, st, TR, OT, state)
	local off = P.off(TR.window)
	eq(#off, 0, where .. ' (the window): ' .. P.report(off))
	off = P.off(TR.holder)
	eq(#off, 0, where .. ' (the holder): ' .. P.report(off))
	if TR.itemLayer then
		off = P.off(TR.itemLayer)
		eq(#off, 0, where .. ' (the item layer): ' .. P.report(off))
	end
	eq(#stub.blocked, 0, where .. ': nothing blocked')
	eq(table.concat(OT.stray, ','), '', where .. ": nothing stray on Blizzard's tracker")
	eq(#take_errors(), 0, where .. ': no errors')

	-- Which tracker shows.
	eq(TR.handoverState, state.handover, where .. ': the handover state')
	eq(concealed(OT), state.handover == 'own', where .. ": Blizzard's tracker is off screen exactly while SaftUI's is alone")
	eq(TR.window:IsShown(), state.handover ~= 'blizzard', where .. ": SaftUI's window shows unless Blizzard's is in its place")

	-- The buttons: never dimmer than 25% while shown, none while handed over in
	-- place or with Off, and each where its placement puts it.
	local buttons = shown_buttons(TR)
	for _, button in ipairs(buttons) do
		check(button:GetAlpha() >= TR.BUTTON_MIN_ALPHA, where .. ': a shown button is never under 25%')
		check(near(button:GetAlpha(), 1, 0.001), where .. ': and at full strength out of combat')
	end
	if state.placement == 'off' or state.handover == 'blizzard' or state.collapsed then
		eq(#buttons, 0, where .. ': no button shown')
	elseif state.placement == 'row' then
		for _, button in ipairs(buttons) do
			local row = TR:GetQuestRow(button.questID)
			check(row ~= nil and row:IsVisible(), where .. ': a shown button has its row')
			if row then check(near(button:GetTop(), row:GetTop()), where .. ': at the top of its row') end
		end
		check(#buttons >= 1, where .. ': a window with item quests shows a button')
	elseif state.placement == 'beside' then
		for _, button in ipairs(buttons) do
			local left, right = TR.window:GetLeft(), TR.window:GetRight()
			check(near(button:GetRight(), left - 4) or near(button:GetLeft(), right + 4), where .. ': 4 outside the window')
		end
		check(#buttons >= 1, where .. ': a column with item quests shows a button')
	end
end

------------------------------------------------------------------ every state

test('every state on every look and client sits on whole pixels with nothing blocked', function()
	local checked = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, state in ipairs(STATES) do
			local where = name_of(client, state)
			local st, TR, OT = world(client, state)
			expect_state(where, st, TR, OT, state)
			-- A second refresh moves nothing.
			TR:Refresh()
			settle(1)
			expect_state(where .. ' (again)', st, TR, OT, state)
			stub.size_noise = 0
			checked = checked + 1
		end
	end
	eq(checked, 2 * #STATES, 'every state ran on both clients')
end)

------------------------------------------------------------------ combat

local OTHER_THEME = { thick = 'thin', thin = 'blizzard', blizzard = 'thick' }

test('combat in and out at every state: no secure call or frame in combat, the buttons stay and never go under 25%, one pass after', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, state in ipairs(STATES) do
			local where = name_of(client, state)
			local st, TR, OT = world(client, state)
			local before = {}
			for _, button in ipairs(shown_buttons(TR)) do before[button] = { button:GetLeft(), button:GetTop() } end
			TW.count_from_now()
			TW.combat(true)
			-- The quest above completes and one with an item arrives; the profile changes
			-- (width, item size, look); a zone collapses; the list scrolls.
			log({ [1] = true }, true)
			if state.collapsed then stub.quests.popups = {} end -- (a popup would show the window expanded)
			stub.fire_event('QUEST_LOG_UPDATE')
			settle(1)
			TR.config.width = 300
			TR.config.items.size = 32
			T.theme(OTHER_THEME[state.theme], function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
			TR:ToggleZone('Westfall')
			TR:Refresh()
			if (TR.scrollRange or 0) > 0 then TR:ScrollTo(20) end
			settle(1)
			TW.count_stop()
			eq(TW.counts.secure, 0, where .. ': no secure frame made in combat')
			eq(#stub.blocked, 0, where .. ': no secure call in combat')
			for button, place in pairs(before) do
				eq(button:GetLeft() .. ',' .. button:GetTop(), place[1] .. ',' .. place[2], where .. ': a button never moves in combat')
			end
			for _, button in ipairs(shown_buttons(TR)) do
				check(button:GetAlpha() >= TR.BUTTON_MIN_ALPHA, where .. ': a button shown in combat is never under 25%')
			end
			eq(#take_errors(), 0, where .. ': no errors in combat')

			local passes = 0
			local refresh = TR.RefreshItems
			TR.RefreshItems = function(self, ...)
				passes = passes + 1
				return refresh(self, ...)
			end
			TW.combat(false)
			TR.RefreshItems = refresh
			eq(passes, 1, where .. ': combat ends: one pass')
			settle(1)
			expect_state(where .. ' after combat', st, TR, OT, state)
			stub.size_noise = 0
		end
	end
end)

------------------------------------------------------------------ no new frame

-- What /sui changes, a profile switch and a theme change do to a tracker that is
-- already drawn: each one sets values and runs TR:UpdateConfig (as Config:UpdateConfig
-- does), and the pools, the layer and the fader are made once, so nothing is made.
local CHANGES = {
	-- (a look's art is made by Core's theme engine the first time it is drawn, so the
	-- look is tried once, before the count, as a player's second change to it is)
	{ 'a theme change', function(st, TR, state)
		local function switch(name) T.theme(name, function() TR:UpdateConfig(); st:ColorsChanged('theme') end) end
		TW.count_stop()
		switch(OTHER_THEME[state.theme])
		switch(state.theme)
		TW.count_from_now()
		switch(OTHER_THEME[state.theme])
	end },
	{ 'a profile switch (position, size, Grow, background, header and count)', function(st, TR, state)
		TR.config.position = POSITIONS[state.side == 'right' and 'left' or 'right']
		TR.config.width, TR.config.height = 320, 240
		TR.config.grow = state.grow == 'down' and 'up' or 'down'
		TR.config.background = 'solid'
		TR.config.header, TR.config.count = false, false
		TR:UpdateConfig()
	end },
	{ '/sui changes to the quests (zones, spacing, tags, level, bars, timers, waypoint, finished objectives)', function(st, TR)
		local quests = TR.config.quests
		quests.zones, quests.spacing, quests.tags, quests.level = false, 4, false, true
		quests.bars, quests.timers, quests.waypoint, quests.finished_objectives = false, false, false, true
		TR:UpdateConfig()
	end },
	{ '/sui changes to the items (size, cooldown, count, range; row and beside swap)', function(st, TR, state)
		local items = TR.config.items
		items.size, items.cooldown, items.count, items.range = 36, false, false, false
		if state.placement == 'row' then items.placement = 'beside' elseif state.placement == 'beside' then items.placement = 'row' end
		TR:UpdateConfig()
	end },
	{ '/sui changes to the visibility (fades and hides)', function(st, TR)
		local visibility = TR.config.visibility
		visibility.combat, visibility.mouseoff, visibility.fade_alpha = 'fade', 'fade', 0.5
		visibility.background_hover, visibility.items = true, true
		TR:UpdateConfig()
		visibility.combat, visibility.mouseoff, visibility.background_hover, visibility.items = 'show', 'show', false, false
		TR:UpdateConfig()
	end },
}

test('a theme change, a profile switch and /sui changes at every state make no new frame', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, state in ipairs(STATES) do
			for _, change in ipairs(CHANGES) do
				local where = name_of(client, state) .. ', ' .. change[1]
				local st, TR, OT = world(client, state)
				TW.count_from_now()
				change[2](st, TR, state)
				TR:Refresh()
				settle(1)
				TW.count_stop()
				eq(TW.counts.frames, 0, where .. ': no new frame')
				eq(TW.counts.secure, 0, where .. ': no new secure frame')
				eq(TW.counts.hooks, 0, where .. ': no new hook')
				eq(#stub.blocked, 0, where .. ': nothing blocked')
				eq(table.concat(OT.stray, ','), '', where .. ": nothing stray on Blizzard's tracker")
				eq(#take_errors(), 0, where .. ': no errors')
				stub.size_noise = 0
			end
		end
	end
end)

------------------------------------------------------------------ a placement change in combat

-- Task 9 left this open (its M4): a profile switch between In the row, Beside the
-- tracker and Off while in combat. Decided here: it stays as it is, and is
-- documented (.agents/taint.md rule 15). The change is saved and the rows draw
-- what they can (the plain or greyed icon, the number's room); no secure frame
-- is made, and no button is shown, hidden, moved or given an item; each stays
-- where it was, dimmed to 40% when its place is no longer its row's, never under
-- 25%; and one pass at the end of combat puts every button where the new
-- placement says, the layer made then if it had not been. The alternative,
-- changing the buttons in combat, is not possible: they are secure.
test('a profile switch between In the row, Beside the tracker and Off in combat: nothing secure runs, one pass after puts it right', function()
	local PLACEMENTS = { 'row', 'beside', 'off' }
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, handover in ipairs({ 'own', 'both', 'blizzard' }) do
			for _, from in ipairs(PLACEMENTS) do
				for _, to in ipairs(PLACEMENTS) do
					if from ~= to then
						local state = { theme = 'thick', placement = from, grow = 'down', handover = handover, collapsed = false, scrolled = false, side = 'right', noise = 0 }
						local where = ('%s, %s to %s, handover %s'):format(client, from, to, handover)
						local st, TR, OT = world(client, state)
						expect_state(where .. ' before', st, TR, OT, state)
						local before = {}
						for _, button in ipairs(shown_buttons(TR)) do before[button] = { button:GetLeft(), button:GetTop() } end
						TW.count_from_now()
						TW.combat(true)
						TR.config.items.placement = to
						TR:UpdateConfig()
						TR:Refresh()
						settle(1)
						TW.count_stop()
						eq(TW.counts.secure, 0, where .. ': no secure frame made in combat')
						eq(#stub.blocked, 0, where .. ': no secure call in combat')
						for button, place in pairs(before) do
							eq(button:GetLeft() .. ',' .. button:GetTop(), place[1] .. ',' .. place[2], where .. ': a button stays where it was')
							eq(button:IsShown(), true, where .. ': and shown')
						end
						for _, button in ipairs(shown_buttons(TR)) do
							check(button:GetAlpha() >= TR.BUTTON_MIN_ALPHA, where .. ': never under 25%')
						end
						eq(#take_errors(), 0, where .. ': no errors in combat')
						local passes = 0
						local refresh = TR.RefreshItems
						TR.RefreshItems = function(self, ...)
							passes = passes + 1
							return refresh(self, ...)
						end
						TW.combat(false)
						TR.RefreshItems = refresh
						eq(passes, 1, where .. ': combat ends: one pass')
						settle(1)
						state.placement = to
						expect_state(where .. ' after', st, TR, OT, state)
					end
				end
			end
		end
	end
end)

------------------------------------------------------------------ off at the end

-- With the switch off (it ships off, and is read once at login), SaftUI-Tracker
-- changes nothing: Blizzard's tracker, the skin and the skin's mover behave exactly
-- as when SaftUI-Tracker is not installed at all, through a session's worth of
-- events. The same script runs in both worlds, and what each step leaves is
-- compared: Blizzard's tracker's points, shown state, alpha, clamp and scripts, the
-- skin's holder, the movers there are, every method called on Blizzard's tracker
-- and its modules, and the frames made since login.
local function session(client, without)
	stub.probes = { watched_tasks = {}, world = {}, world_watches = 0, task_info = {}, tasks = {}, tracked = {}, achievements = {} }
	stub.instance, stub.encounter = nil, false
	local made = 0
	local steps = {}
	RW.mouse_off()
	local st, TR = TW.world({ client = client, misc = MISC, blizzard = true, screen = { 1000, 600 }, without = without,
		enabling = function()
			local create = CreateFrame
			CreateFrame = function(...)
				made = made + 1
				return create(...)
			end
		end })
	local OT, OTP = TW.OT, TW.OTP
	OT.watch_calls()
	local function movers()
		local names = {}
		for name in pairs(st.EditModeFrames.movers) do names[#names + 1] = name end
		table.sort(names)
		return table.concat(names, ',')
	end
	local function step(name)
		RW.later(1)
		steps[#steps + 1] = { name = name, state = table.concat({
			TW.snapshot(OT.tracker), TW.snapshot(OTP.holder), movers(), OT.called(), 'frames ' .. made,
			'blocked ' .. #stub.blocked, 'errors ' .. #take_errors(),
		}, ' | ') }
	end
	local function profile_update()
		OTP:UpdateConfig()
		if TR then TR:UpdateConfig() end
	end
	step('login')
	-- Quests change, and the game says so.
	log()
	stub.fire_event('QUEST_LOG_UPDATE')
	stub.fire_event('QUEST_WATCH_LIST_CHANGED')
	step('quests')
	-- Combat in and out, with Blizzard laying out meanwhile.
	TW.combat(true)
	OT.manage()
	step('combat')
	TW.combat(false)
	step('combat over')
	OT.manage()
	OT.apply_layout()
	OT.show()
	step("Blizzard's own layout")
	-- A scenario starts: with the switch off nothing hands over.
	scenario(true)
	stub.fire_event('PLAYER_ENTERING_WORLD')
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	step('a scenario starts')
	scenario(false)
	step('and ends')
	-- The look changes and a profile is switched.
	T.theme('blizzard', function() profile_update(); st:ColorsChanged('theme') end)
	step('Blizzard look')
	T.theme('thick', function() profile_update(); st:ColorsChanged('theme') end)
	st.config.profile.objectivetracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -300, y_off = -50 }
	profile_update()
	step('a profile switch')
	-- A profile that has the switch on, mid-session: the switch is read once, at login.
	if TR then
		st.config.profile.tracker.enable = true
		profile_update()
		step('a profile with the switch on')
		eq(TR:IsOn(), false, 'still off this session')
		check(not TR.built, 'nothing built')
	end
	return steps, st
end

test('off at the end: Blizzard\'s tracker, the skin and its mover exactly as with SaftUI-Tracker not loaded', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local absent = session(client, true)
		local off, st = session(client, false)
		for index, expected in ipairs(absent) do
			if expected.name == 'a profile with the switch on' then break end
			eq(off[index].name, expected.name, client .. ': the same step')
			eq(off[index].state, expected.state, client .. ': after "' .. expected.name .. '", as with SaftUI-Tracker not loaded')
		end
		check(#off > #absent - 1, client .. ': every step ran')
		eq(st.EditModeFrames.movers.tracker, nil, client .. ': no mover of SaftUI\'s tracker')
		check(st.EditModeFrames.movers.objectivetracker ~= nil or TW.OTP.holder ~= nil, client .. ": the skin's mover is there")
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)
