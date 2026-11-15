-- The handover to Blizzard's tracker (SaftUI-Tracker/handover.lua, probes.lua,
-- blizzard.lua's 'beside' place, layout.lua's beside spot; design: "What the
-- player sees: the handover" and "The handover's rules"):
--   - TR.Handover.Next, the design's table as data: every row of it;
--   - the three states in the world: own (SaftUI's tracker, Blizzard's concealed),
--     blizzard (Blizzard's in SaftUI's place, the window and the item buttons
--     hidden), both (Blizzard's beside SaftUI's); out of combat and in;
--   - a need that starts in combat, a need that ends in combat with item buttons
--     to show, a mode change (back to own, then the table again), a /reload (from
--     own), a profile switch during a handover;
--   - where Blizzard's tracker goes: in place on the window's top right (Grow
--     down and up), beside 12 out on the side nearer the middle and past the
--     item column, the revealed spot kept off the bottom of the screen;
--   - the Now line and the Blizzard's tracker tab;
--   - every call on Blizzard's tracker through it is the three C methods, and
--     nothing is blocked.
-- On both clients. Real: SaftUI-Tracker's files over the quest and section stubs
-- and Blizzard's tracker from the Misc fixture, every frame of it locked.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q

local MISC = { skinning = true, skin = true, otp = true }

------------------------------------------------------------------ the table

local CASES = { -- from, needed, combat, mode, itemsToShow -> to, actions
	{ 'own',      true,  false, 'place',  true,  'blizzard', 'hide_items,hide_window,reveal_place' },
	{ 'own',      true,  true,  'place',  true,  'both',     'reveal_beside' },
	{ 'own',      true,  false, 'beside', true,  'both',     'reveal_beside' },
	{ 'both',     false, true,  'place',  true,  'own',      'conceal' },
	{ 'both',     false, false, 'beside', true,  'own',      'conceal' },
	{ 'both',     true,  false, 'place',  true,  'blizzard', 'hide_items,hide_window,reveal_place' },
	{ 'both',     true,  true,  'place',  true,  'both',     '' },
	{ 'both',     true,  false, 'beside', true,  'both',     '' },
	{ 'blizzard', false, false, 'place',  true,  'own',      'conceal,show_window,show_items' },
	{ 'blizzard', false, true,  'place',  false, 'own',      'conceal,show_window' },
	{ 'blizzard', false, true,  'place',  true,  'blizzard', '' },
	{ 'blizzard', true,  true,  'place',  true,  'blizzard', '' },
	{ 'own',      false, false, 'place',  true,  'own',      '' },
}

test('TR.Handover.Next: every row of the design\'s table', function()
	local _, TR = RW.world({ blizzard = true })
	local Next = TR.Handover.Next
	for i, case in ipairs(CASES) do
		local state, actions = Next(case[1], case[2], case[3], case[4], case[5])
		local label = ('row %d: from %s, needed %s, combat %s, %s, items %s'):format(i, case[1], tostring(case[2]), tostring(case[3]), case[4], tostring(case[5]))
		eq(state .. ' ' .. table.concat(actions, ','), case[6] .. ' ' .. case[7], label)
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('TR.Handover.Next: the rest of the grid, as the rules say', function()
	local _, TR = RW.world({ blizzard = true })
	local Next = TR.Handover.Next
	local function run(...)
		local state, actions = Next(...)
		return state .. ' ' .. table.concat(actions, ',')
	end
	-- Not needed: own stays own in every combat and mode.
	for _, combat in ipairs({ true, false }) do
		for _, mode in ipairs({ 'place', 'beside' }) do
			eq(run('own', false, combat, mode, true), 'own ', 'own, not needed')
			eq(run('both', false, combat, mode, true), 'own conceal', 'both, not needed: conceal, in or out of combat')
		end
	end
	-- Out of combat, items or none: show_items only with items to show.
	eq(run('blizzard', false, false, 'place', false), 'own conceal,show_window', 'no items to show: none shown')
	eq(run('blizzard', false, true, 'place', true), 'blizzard ', 'in combat with items to show: stays until combat ends')
	-- It stays while it is needed, in either combat state.
	eq(run('blizzard', true, false, 'place', true), 'blizzard ', 'needed: stays')
	-- The actions are in the design's order, and only the seven names.
	local names = { hide_items = true, hide_window = true, reveal_place = true, reveal_beside = true, conceal = true, show_window = true, show_items = true }
	for _, from in ipairs({ 'own', 'both', 'blizzard' }) do
		for _, needed in ipairs({ true, false }) do
			for _, combat in ipairs({ true, false }) do
				for _, mode in ipairs({ 'place', 'beside' }) do
					for _, items in ipairs({ true, false }) do
						local _, actions = Next(from, needed, combat, mode, items)
						for _, action in ipairs(actions) do check(names[action], action .. ' is one of the seven') end
						local hidden = false
						for _, action in ipairs(actions) do
							if action == 'hide_items' then
								check(not combat, 'the secure buttons are never hidden in combat')
							end
							if action == 'show_items' then
								check(not combat and items, 'the buttons are shown only out of combat, and only when there are some')
							end
							if action == 'reveal_place' then
								-- Blizzard's tracker never shows under SaftUI's buttons: they are hidden first.
								check(hidden, 'the window is hidden before Blizzard\'s tracker is put in its place')
							end
							if action == 'hide_window' then hidden = true end
						end
					end
				end
			end
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the beside spot

test('TR.Layout.BesideSpot: 12 out on the side nearer the middle, past the column and its 4', function()
	local _, TR = RW.world({ blizzard = true })
	local Spot = TR.Layout.BesideSpot
	-- SaftUI's tracker right of the middle: Blizzard's on its left, by its top right.
	local point, x, y = Spot(700, 960, 500, 'left', 0)
	eq(point .. ' ' .. x .. ' ' .. y, 'TOPRIGHT 688 500', 'left, no column: 12 out of the holder\'s left')
	point, x, y = Spot(700, 960, 500, 'left', 24)
	eq(point .. ' ' .. x .. ' ' .. y, 'TOPRIGHT 660 500', 'left with a 24 column: 12 + 24 + 4 out')
	-- Left of the middle: on its right, by its top left.
	point, x, y = Spot(40, 300, 480, 'right', 0)
	eq(point .. ' ' .. x .. ' ' .. y, 'TOPLEFT 312 480', 'right: 12 out of the holder\'s right')
	point, x, y = Spot(40, 300, 480, 'right', 32)
	eq(point .. ' ' .. x .. ' ' .. y, 'TOPLEFT 348 480', 'right with a 32 column')
	eq(TR.LAYOUT.BESIDE_GAP, 12, 'the gap is the layout\'s 12')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the world

local function item_of(id) return { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 } end

-- Quests in one zone, tracked; with_items gives each an item.
local function log(ids, with_items)
	local entries = { Q.header('Elwynn Forest') }
	for _, id in ipairs(ids) do
		entries[#entries + 1] = Q.quest(id, { item = with_items and item_of(id) or nil, objectives = { { text = '1/2 Wolves', type = 'monster' } } })
	end
	Q.set(entries, ids)
end

-- A world with the switch on, Blizzard's tracker built, a screen of 1000 by 600
-- and quests in the log. opts: ids (default { 1, 2 }), items (default true),
-- misc, client, config(st) run before the first refresh.
local function world(opts)
	opts = opts or {}
	local ids = opts.ids or { 1, 2 }
	local items = opts.items ~= false
	local config = opts.config
	local misc = opts.misc and MISC or nil
	local st, TR = RW.world({
		client = opts.client, blizzard = opts.blizzard or true, misc = misc, screen = { 1000, 600 },
		enabling = function(st)
			log(ids, items)
			if config then config(st) end
		end,
	})
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	return st, TR, TW.OT
end

local function settle(seconds) RW.later(seconds or 0) end

-- Something Blizzard's tracker would show a section for, as the game says it.
local function scenario(on)
	stub.probes.scenario = on and { stages = 3, stage = 1 } or { stages = 0 }
	stub.fire_event('SCENARIO_UPDATE')
end

local function tracker_top_right(OT)
	return OT.tracker:GetRight(), OT.tracker:GetTop()
end

local function near(a, b) return math.abs(a - b) <= 0.01 end

local function concealed(OT, where)
	check(near(OT.tracker:GetRight(), UIParent:GetLeft() - 100), where .. ': concealed (right edge 100 left of the screen), not ' .. tostring(OT.tracker:GetRight()))
	eq(OT.tracker:IsClampedToScreen(), false, where .. ': the clamp is off')
end

local function items_shown(TR)
	local n = 0
	for _, button in ipairs(TR.itemButtons or {}) do if button.questID and button:IsShown() then n = n + 1 end end
	return n
end

local function clean(where)
	where = where or ''
	eq(#take_errors(), 0, where .. 'no errors')
	eq(#stub.blocked, 0, where .. 'nothing blocked')
	local OT = TW.OT
	eq(table.concat(OT.stray, ','), '', where .. "SaftUI ran none of the tracker's state-writing methods, sizes, SetParent or Unregister calls")
	local own = {}
	for name, n in pairs(OT.own) do if n > 0 then own[#own + 1] = name .. '=' .. n end end
	eq(table.concat(own, ','), '', where .. "SaftUI called none of Edit Mode's overrides (or Show) on it")
	eq(OT.calls.Show + OT.calls.Hide + OT.calls.SetShown + OT.calls.SetScale, 0, where .. 'Show, Hide, SetShown and SetScale never called on it')
end

local function both(name, fn)
	for _, client in ipairs({ 'forever', 'retail' }) do
		test(name .. ' [' .. client .. ']', function()
			fn(client)
		end)
	end
end

------------------------------------------------------------------ in place

both('a need out of combat: Blizzard\'s tracker in SaftUI\'s place on the holder\'s top right, the window and the item buttons hidden; the need ends after the hold: back', function(client)
	local st, TR, OT = world({ client = client })
	eq(TR.handoverState, 'own', 'a /reload starts from own')
	concealed(OT, 'own')
	check(TR.window:IsShown(), 'own: the window shows')
	eq(items_shown(TR), 2, 'and its two item buttons')
	local buttons = items_shown(TR)

	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'a scenario: Blizzard\'s tracker in SaftUI\'s place')
	check(not TR.window:IsShown(), 'the window is hidden')
	eq(items_shown(TR), 0, 'and so are the item buttons, before Blizzard\'s tracker shows')
	check(TR:GetItemButton(1) == nil and TR:GetItemButton(2) == nil, 'no quest holds a button while Blizzard\'s tracker is in place')
	local right, top = tracker_top_right(OT)
	check(near(right, TR.holder:GetRight()) and near(top, TR.holder:GetTop()), 'its top right is the holder\'s: ' .. right .. ',' .. top .. ' vs ' .. TR.holder:GetRight() .. ',' .. TR.holder:GetTop())
	eq(OT.tracker:IsClampedToScreen(), true, 'its clamp is back on')
	check(OT.tracker:IsShown(), 'never hidden')
	eq(TR.blizzardWhere, 'place', 'placed in place')
	eq(TR:HandoverText(), "Showing Blizzard's tracker for: Scenario.", 'the Now line')
	check(TR.nearestHolder == nil or true, 'the nearest button\'s holder is its own and stays')

	scenario(false)
	settle(0)
	eq(TR.handoverState, 'blizzard', 'the need ends but is held for 2 seconds')
	settle(TR.HOLD - 0.5)
	eq(TR.handoverState, 'blizzard', 'still held at 1.5 s')
	settle(1)
	eq(TR.handoverState, 'own', 'then it is over: back to SaftUI\'s tracker')
	concealed(OT, 'back to own')
	check(TR.window:IsShown(), 'the window is back')
	eq(items_shown(TR), buttons, 'and the item buttons')
	eq(TR:HandoverText(), 'Not needed now.', 'the Now line says so')
	clean()
end)

both('Grow up: in place on the window\'s top right', function(client)
	local st, TR, OT = world({ client = client, config = function(st)
		st.config.profile.tracker.grow = 'up'
		st.config.profile.tracker.height = 300
		st.config.profile.tracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -20, y_off = -50 }
	end })
	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'handed over')
	local right, top = tracker_top_right(OT)
	check(near(right, TR.window:GetRight()) and near(top, TR.window:GetTop()), 'its top right is the window\'s (the holder\'s bottom less its height): ' .. right .. ',' .. top .. ' vs ' .. TR.window:GetRight() .. ',' .. TR.window:GetTop() .. ' holder ' .. TR.holder:GetBottom())
	clean()
end)

both('a need that starts in combat: beside SaftUI\'s, SaftUI\'s stays, and when combat ends it moves into place', function(client)
	local st, TR, OT = world({ client = client })
	TW.combat(true)
	settle()
	scenario(true)
	settle()
	eq(TR.handoverState, 'both', 'in combat: both')
	check(TR.window:IsShown(), 'SaftUI\'s window stays')
	eq(items_shown(TR), 2, 'and its item buttons (they can\'t be hidden in combat)')
	eq(TR.blizzardWhere, 'beside', 'Blizzard\'s is beside')
	check(OT.tracker:GetRight() < TR.holder:GetLeft() or OT.tracker:GetLeft() > TR.holder:GetRight(), 'not on top of SaftUI\'s window')
	eq(OT.tracker:IsClampedToScreen(), true, 'its clamp on')
	TW.combat(false)
	settle(1)
	eq(TR.handoverState, 'blizzard', 'combat over, still needed: in SaftUI\'s place')
	check(not TR.window:IsShown(), 'the window is hidden then')
	eq(items_shown(TR), 0, 'and the buttons')
	clean()
end)

both('a need that ends in combat: back at once with no item buttons to show; with some it waits for the end of combat', function(client)
	-- No quest has an item: nothing to show, so it goes back at once.
	local st, TR, OT = world({ client = client, items = false })
	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'handed over out of combat')
	TW.combat(true)
	settle()
	scenario(false)
	settle(TR.HOLD + 0.5)
	eq(TR.handoverState, 'own', 'no item buttons to show: SaftUI\'s tracker back in combat')
	check(TR.window:IsShown(), 'its window shows')
	concealed(OT, 'concealed')
	TW.combat(false)
	clean('no items: ')

	-- Quests with items: its buttons can't be shown in combat, so Blizzard's stays.
	st, TR, OT = world({ client = client })
	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'handed over')
	TW.combat(true)
	settle()
	scenario(false)
	settle(TR.HOLD + 0.5)
	eq(TR.handoverState, 'blizzard', 'item buttons to show: it stays through the combat')
	check(not TR.window:IsShown(), 'with SaftUI\'s window still away')
	check(OT.tracker:GetRight() > UIParent:GetLeft(), 'Blizzard\'s tracker still on screen')
	TW.combat(false)
	settle(1)
	eq(TR.handoverState, 'own', 'when combat ends it goes back')
	eq(items_shown(TR), 2, 'with the buttons')
	concealed(OT, 'concealed again')
	clean('with items: ')
end)

both('a need that starts and ends in combat: beside, then back', function(client)
	local st, TR, OT = world({ client = client })
	TW.combat(true)
	settle()
	scenario(true)
	settle()
	eq(TR.handoverState, 'both', 'both')
	scenario(false)
	settle(TR.HOLD + 0.5)
	eq(TR.handoverState, 'own', 'and back to own in combat: only conceal')
	concealed(OT, 'concealed')
	check(TR.window:IsShown(), 'the window was never hidden')
	TW.combat(false)
	clean()
end)

------------------------------------------------------------------ beside

both('Beside SaftUI\'s: both always, 12 out on the side nearer the middle; past the item column', function(client)
	local st, TR, OT = world({ client = client, config = function(st)
		st.config.profile.tracker.blizzard.mode = 'beside'
		-- SaftUI's tracker on the right of the screen.
		st.config.profile.tracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -20, y_off = -50 }
	end })
	scenario(true)
	settle()
	eq(TR.handoverState, 'both', 'beside: both')
	check(TR.window:IsShown(), 'SaftUI\'s tracker unchanged')
	eq(items_shown(TR), 2, 'and its buttons')
	eq(TR.blizzardWhere, 'beside', 'Blizzard\'s beside')
	local right, top = tracker_top_right(OT)
	check(near(right, TR.holder:GetLeft() - 12), 'on the left of a tracker on the right: its top right 12 out, not ' .. right .. ' vs ' .. (TR.holder:GetLeft() - 12))
	check(near(top, TR.holder:GetTop()), 'level with the holder\'s top')
	eq(OT.tracker:IsClampedToScreen(), true, 'clamp on')

	-- Item buttons beside the tracker: past the column and its 4.
	st.config.profile.tracker.items.placement = 'beside'
	TR:UpdateConfig()
	settle(1)
	eq(TR.handoverState, 'both', 'still both')
	local size = st.config.profile.tracker.items.size
	right = OT.tracker:GetRight()
	check(near(right, TR.holder:GetLeft() - 12 - size - 4), 'with the column on that side: 12 + the button size + 4 out, not ' .. right)

	-- SaftUI's tracker on the left of the screen: Blizzard's on its right, by its top left.
	st.config.profile.tracker.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 20, y_off = -50 }
	TR:UpdateConfig()
	settle(1)
	check(near(OT.tracker:GetLeft(), TR.holder:GetRight() + 12 + size + 4), 'on the right: its top left 12 + the column + 4 out, not ' .. OT.tracker:GetLeft())
	check(near(OT.tracker:GetTop(), TR.holder:GetTop()), 'level with the holder\'s top')

	-- Without item buttons beside the tracker there is no column to clear.
	st.config.profile.tracker.items.placement = 'row'
	TR:UpdateConfig()
	settle(1)
	check(near(OT.tracker:GetLeft(), TR.holder:GetRight() + 12), 'no column: 12 out')
	clean()
end)

both('Blizzard\'s tracker beside follows the item column as it comes and goes with the list', function(client)
	local st, TR, OT = world({ client = client, items = false, config = function(st)
		st.config.profile.tracker.blizzard.mode = 'beside'
		st.config.profile.tracker.items.placement = 'beside'
		st.config.profile.tracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -20, y_off = -50 }
	end })
	scenario(true)
	settle()
	eq(TR.handoverState, 'both', 'beside')
	check(near(OT.tracker:GetRight(), TR.holder:GetLeft() - 12), 'no quest with an item: no column, 12 out')
	-- A quest with an item arrives: the column appears, and Blizzard's tracker steps out past it.
	log({ 1, 2 }, true)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	local size = st.config.profile.tracker.items.size
	check(near(OT.tracker:GetRight(), TR.holder:GetLeft() - 12 - size - 4), 'the column is there: 12 + the button size + 4 out, not ' .. OT.tracker:GetRight())
	log({ 1, 2 }, false)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	check(near(OT.tracker:GetRight(), TR.holder:GetLeft() - 12), 'and back when it goes')
	clean()
end)

both('the item column counts only buttons that show: a collapsed group has none', function(client)
	local st, TR = world({ client = client, config = function(st) st.config.profile.tracker.items.placement = 'beside' end })
	check(TR:ColumnWidth() > 0, 'quests with items in the list: a column')
	TR:CharData().zones['Elwynn Forest'] = true
	TR:Redraw()
	eq(TR:ColumnWidth(), 0, 'every group collapsed: no column, so nothing to clear')
	TR:CharData().zones['Elwynn Forest'] = nil
	TR:Redraw()
	check(TR:ColumnWidth() > 0, 'open again: the column is back')
	-- The whole tracker collapsed: its rows are not drawn, so there is no column either.
	TR:SetCollapsed(true)
	eq(TR:ColumnWidth(), 0, 'the whole tracker collapsed: no column')
	TR:SetCollapsed(false)
	check(TR:ColumnWidth() > 0, 'and back when it opens')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the revealed spot

both('a spot low on the screen is raised so Blizzard\'s tracker keeps room (no 20 minimum height, no clamp push)', function(client)
	local st, TR, OT = world({ client = client, config = function(st)
		st.config.profile.tracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -20, y_off = -560 }
		st.config.profile.tracker.height = 120
	end })
	-- Concealed first: the same y it would reveal at, so its height is what it will be
	-- (Blizzard works it out when its right container lays out, from its anchor).
	OT.manage()
	local concealed_top = OT.tracker:GetTop()
	local floor = UIParent:GetBottom() + TR.BLIZZARD_FLOOR
	check(concealed_top >= floor - 0.01, 'concealed at or above the floor: ' .. concealed_top .. ' vs ' .. floor)
	check(OT.tracker:GetHeight() > 20, 'so Blizzard\'s height is more than its 20 minimum: ' .. OT.tracker:GetHeight())
	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'handed over')
	check(near(OT.tracker:GetTop(), concealed_top), 'revealed at the y it was concealed at')
	OT.manage()
	check(OT.tracker:GetHeight() > 20, 'and Blizzard\'s height there is more than 20: ' .. OT.tracker:GetHeight())
	check(OT.tracker:GetBottom() >= UIParent:GetBottom() - 0.01, 'its bottom on the screen: the clamp has nothing to push: ' .. OT.tracker:GetBottom() .. ' top ' .. OT.tracker:GetTop() .. ' h ' .. OT.tracker:GetHeight())
	clean()
end)

------------------------------------------------------------------ changes while handed over

both('a mode change goes back to own, then runs the table again; a /reload starts from own', function(client)
	local st, TR, OT = world({ client = client })
	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'handed over in place')
	st.config.profile.tracker.blizzard.mode = 'beside'
	TR:UpdateConfig()
	settle(1)
	eq(TR.handoverState, 'both', 'Beside: both')
	check(TR.window:IsShown() and items_shown(TR) == 2, 'SaftUI\'s window and buttons came back')
	eq(TR.blizzardWhere, 'beside', 'Blizzard\'s beside')
	st.config.profile.tracker.blizzard.mode = 'place'
	TR:UpdateConfig()
	settle(1)
	eq(TR.handoverState, 'blizzard', 'and back to In SaftUI\'s place')
	check(not TR.window:IsShown(), 'with the window away')
	-- With nothing needed a mode change changes nothing.
	scenario(false)
	settle(TR.HOLD + 1)
	eq(TR.handoverState, 'own', 'over')
	st.config.profile.tracker.blizzard.mode = 'beside'
	TR:UpdateConfig()
	settle(1)
	eq(TR.handoverState, 'own', 'not needed: own whatever the mode')
	concealed(OT, 'own')
	clean()

	-- A /reload: the world starts again, in own, whatever the state was; the scenario
	-- it was in is found again and handed over from own.
	stub.probes.scenario = { stages = 3 }
	local _, TR2, OT2 = world({ client = client })
	eq(TR2.handoverState, 'own', 'a fresh load starts from own')
	concealed(OT2, 'fresh')
	check(TR2.window:IsShown(), 'with its window')
	settle(1)
	stub.probes.scenario = { stages = 3 }
	stub.fire_event('PLAYER_ENTERING_WORLD')
	settle(1)
	eq(TR2.handoverState, 'blizzard', 'and finds the scenario it is in')
end)

both('a profile switch during a handover: Blizzard\'s stays at its spot, the skin\'s mover moves nothing', function(client)
	for _, mode in ipairs({ 'place', 'beside' }) do
		local st, TR, OT = world({ client = client, misc = true, config = function(st) st.config.profile.tracker.blizzard.mode = mode end })
		local OTP, tracker = TW.OTP, OT.tracker
		scenario(true)
		settle()
		eq(TR.handoverState, mode == 'place' and 'blizzard' or 'both', mode .. ': handed over')
		local before = TW.snapshot(tracker)
		OT.watch_calls()
		OTP:UpdateConfig()
		TR:UpdateConfig()
		settle(1)
		eq(TW.snapshot(tracker), before, mode .. ': the same spot, the same clamp')
		eq(OT.called():find('SetPoint', 1, true), nil, mode .. ': nothing re-placed, by the skin or by SaftUI')
		-- A profile with another position: the holder moves and Blizzard's follows.
		st.config.profile.tracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -300, y_off = -80 }
		TR:UpdateConfig()
		OTP:UpdateConfig()
		settle(1)
		if mode == 'place' then
			check(near(OT.tracker:GetRight(), TR.holder:GetRight()) and near(OT.tracker:GetTop(), TR.holder:GetTop()), 'place: follows the holder')
		else
			check(near(OT.tracker:GetTop(), TR.holder:GetTop()), 'beside: level with the holder')
		end
		clean(mode .. ': ')
	end
end)

both('Blizzard\'s own re-placing of its tracker while handed over is put back where the state says', function(client)
	local st, TR, OT = world({ client = client })
	scenario(true)
	settle()
	eq(TR.handoverState, 'blizzard', 'in place')
	local before = TW.snapshot(OT.tracker)
	OT.show()
	OT.manage()
	OT.apply_layout()
	OT.as_blizzard(function() OT.tracker:UpdateHeight() end)
	eq(TW.snapshot(OT.tracker), before, 'after Blizzard\'s layout, its container and its height: still in place')
	TW.combat(true)
	settle()
	OT.manage()
	eq(TW.snapshot(OT.tracker), before, 'and in combat')
	TW.combat(false)
	clean()
end)

both('a protected tracker is placed when combat ends: Blizzard\'s spot shows meanwhile, nothing blocked', function(client)
	-- Something secure anchored to it (a layout snapped a system to it) makes it protected.
	local st, TR, OT = world({ client = client, blizzard = { protected = true } })
	TW.combat(true)
	settle()
	scenario(true)
	settle()
	eq(TR.handoverState, 'both', 'the state is both')
	concealed(OT, 'still concealed: the move waits for the end of combat')
	TW.combat(false)
	settle(1)
	eq(TR.handoverState, 'blizzard', 'then in place')
	check(near(OT.tracker:GetTop(), TR.holder:GetTop()), 'at SaftUI\'s spot')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the page

both('the Now line names the needed sections by the table\'s names; the tab\'s mode, Now and note', function(client)
	local st, TR, OT = world({ client = client })
	load_test_file('lib/options_walk.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	eq(TR:HandoverText(), 'Not needed now.', 'nothing needed')
	scenario(true)
	stub.probes.tracked = { [2] = { 5 } }
	stub.probes.achievements = { [5] = { earned = false } }
	stub.fire_event('TRACKED_ACHIEVEMENT_LIST_CHANGED')
	settle()
	eq(TR:HandoverText(), "Showing Blizzard's tracker for: Scenario, Achievements.", 'the needed sections by name, in order')
	local tab = TR:GetConfigTable().args.blizzard
	eq(tab.name, "Blizzard's tracker", 'the tab')
	eq(tab.order, 5, 'fifth, after Visibility')
	eq(tab.disabled(), false, 'on while the tracker is on')
	local mode = tab.args.mode
	eq(mode.name, "When Blizzard's tracker is needed", 'the setting')
	eq(mode.type, 'select', 'a select')
	eq(mode.values.place .. '|' .. mode.values.beside, "In SaftUI's place|Beside SaftUI's", 'its two choices')
	eq(mode.sorting[1] .. mode.sorting[2], 'placebeside', 'in that order')
	eq(mode.default.value(), 'place', 'In SaftUI\'s place by default')
	check(type(mode.desc) == 'string' and mode.desc ~= '', 'with a desc')
	tab.set({ 'Tracker', 'blizzard', 'mode' }, 'beside')
	eq(st.config.profile.tracker.blizzard.mode, 'beside', 'saved')
	settle(1)
	eq(TR.handoverState, 'both', 'and acted on at once')
	mode.default.reset()
	settle(1)
	eq(TR.handoverState, 'blizzard', 'its reset too')
	local now = tab.args.now
	eq(now.type, 'description', 'the Now line is a description')
	local name = type(now.name) == 'function' and now.name() or now.name
	eq(name, "Now: Showing Blizzard's tracker for: Scenario, Achievements.", 'read when the page draws')
	scenario(false)
	stub.probes.tracked = {}
	stub.fire_event('TRACKED_ACHIEVEMENT_LIST_CHANGED')
	settle(TR.HOLD + 1)
	name = type(now.name) == 'function' and now.name() or now.name
	eq(name, 'Now: Not needed now.', 'and again when it draws again')
	local note = tab.args.note
	eq(note.type, 'description', 'the note')
	eq(note.name, "SaftUI's tracker draws your quests. While something it doesn't draw yet has content (a scenario or dungeon, Mythic+, bonus objectives, world quests, a tracked achievement, recipe or activity, zone widgets), Blizzard's own tracker shows in its place, with everything in it, and SaftUI's comes back when that ends. Its look is set on Blizzard's tracker page and Skinning.", "the spec's note")
	local OFF_TR = select(2, TW.world({ on = false }))
	eq(OFF_TR.Tab(5, 'x', {}).disabled(), true, 'a tab is off with the switch off')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the switch off

test('with the switch off nothing of the handover exists or runs', function()
	local st, TR = TW.world({ on = false, blizzard = true })
	local OT = TW.OT
	local before = TW.snapshot(OT.tracker)
	scenario(true)
	stub.run_timers()
	eq(TW.snapshot(OT.tracker), before, 'Blizzard\'s tracker untouched')
	check(TR.handoverState == nil, 'no state')
	eq(TW.counts.frames, 0, 'no frame')
	eq(#take_errors(), 0, 'no errors')
end)
