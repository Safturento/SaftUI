-- SaftUI's tracker's nearest quest item button and its key
-- (SaftUI-Tracker/nearest.lua; design: "The nearest quest item button"): which
-- quest's item it offers (TR.ChooseNearest, the P4 seam), the holder, button and
-- mover, what it does in combat (nothing secure: it keeps its item, dims when its
-- quest's item is gone, and catches up when combat ends), and the key, which is
-- the game's own binding (.agents/taint.md rule 6 and 15: SetBinding and
-- SaveBindings are blocked in combat).
--
-- Real: SaftUI-Tracker's files, Core's helpers, the theme engine and edit mode,
-- the quest, binding and secure button stubs. The scroll frame is
-- tracker_world.lua's stand-in. Not mimicked: the game's protection of a holder
-- a secure button is a child of, so the tests mark the holder protected once its
-- button exists, as the game would.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q
local T = load_test_file('lib/theme_helpers.lua')
local P = load_test_file('lib/pixels.lua')

local COMMAND = 'CLICK SaftUITrackerNearestItem:LeftButton'

local function item_of(id)
	return { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 }
end

-- Quests with items in one zone, all tracked: extra[id] adds to a quest's fields
-- (inArea, distance = { sq, onContinent }, item).
local function log(ids, extra)
	local entries = { Q.header('Elwynn Forest') }
	for _, id in ipairs(ids) do
		local fields = { item = item_of(id), objectives = { { text = '1/2 Wolves', type = 'monster' } } }
		for key, value in pairs(extra and extra[id] or {}) do fields[key] = value end
		entries[#entries + 1] = Q.quest(id, fields)
	end
	Q.set(entries, ids)
end

-- The log entry of a quest, to change what the game would say.
local function entry(id)
	for _, e in ipairs(stub.quests.log) do
		if e.id == id then return e end
	end
end

local function settle()
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
end

-- The nearest button on, quests 1 to 3 with the distances given.
local DISTANCES = {
	[1] = { distance = { sq = 100, onContinent = true } },
	[2] = { distance = { sq = 50, onContinent = true } },
	[3] = { distance = { sq = 200, onContinent = true } },
}

-- The game protects the holder of a secure button (and what that is anchored to);
-- the stubs don't model the spread, so a test marks the holder once its button
-- exists, and every combat path then has to leave it alone.
local function protect(TR)
	if TR.nearestButton and TR.nearestHolder then stub.state(TR.nearestHolder).protected = true end
end

local function world(opts)
	opts = opts or {}
	stub.bindings, stub.saved_bindings, stub.rejected_keys = {}, {}, {}
	stub.cast_on_key_down, stub.secure_clicks = true, {}
	local on = opts.nearest ~= false
	opts.enabling = function(st)
		stub.real_zone_text = 'Elwynn Forest'
		local tracker = st.config.profile.tracker
		tracker.items.nearest = on
		if opts.configure then opts.configure(tracker) end
		log(opts.ids or { 1, 2, 3 }, opts.extra or DISTANCES)
	end
	local st, TR = RW.world(opts)
	protect(TR)
	return st, TR
end

local function button(TR) return TR.nearestButton end
local function item_of_button(TR) return button(TR) and button(TR):GetAttribute('item') or nil end
local function last_use() return stub.secure_clicks[#stub.secure_clicks] end

------------------------------------------------------------------ the choice

test('the choice: inside its area, else the focused quest, else the nearest on your continent, else the game\'s order; no distance is farthest', function()
	local st, TR = world({ nearest = false })
	eq(TR.NEAREST_INTERVAL, 1, 'NEAREST_INTERVAL')
	eq(TR.NEAREST_COMMAND, COMMAND, 'the binding\'s command')
	local Choose = TR.ChooseNearest
	local function c(id, fields)
		local quest = { id = id }
		for key, value in pairs(fields or {}) do quest[key] = value end
		return quest
	end
	eq(Choose({}, nil), nil, 'nothing to choose')
	eq(Choose({}, 5), nil, 'nothing even with a focus')

	-- 1. Inside its area beats the focus and every distance.
	local list = { c(1, { distanceSq = 1, onContinent = true }), c(2), c(3, { inArea = true, distanceSq = 9999, onContinent = true }) }
	eq(Choose(list, 1).id, 3, 'inside its area: before the focused and the nearest')
	-- Two inside: the focused one, else the first in the game\'s order.
	list = { c(1, { inArea = true }), c(2, { inArea = true }), c(3) }
	eq(Choose(list, 2).id, 2, 'two inside: the focused one')
	eq(Choose(list, 3).id, 1, 'two inside, the focus is not one: the first in the game\'s order')
	eq(Choose(list, nil).id, 1, 'two inside, no focus: the first')
	list = { c(1, { inArea = false }), c(2) }
	eq(Choose(list, nil).id, 1, 'not inside is not inside')

	-- 2. The focused quest, if it has an item (it is a candidate).
	list = { c(1, { distanceSq = 1, onContinent = true }), c(2, { distanceSq = 500, onContinent = true }) }
	eq(Choose(list, 2).id, 2, 'the focused quest before a nearer one')
	eq(Choose(list, 99).id, 1, 'a focus with no item is no candidate: on to the distance')

	-- 3. The smallest distance on your continent.
	list = { c(1, { distanceSq = 300, onContinent = true }), c(2, { distanceSq = 40, onContinent = true }), c(3, { distanceSq = 70, onContinent = true }) }
	eq(Choose(list, nil).id, 2, 'the smallest distance')
	list = { c(1, { distanceSq = 5, onContinent = false }), c(2, { distanceSq = 80, onContinent = true }) }
	eq(Choose(list, nil).id, 2, 'a quest on another continent is not on your continent')
	list = { c(1), c(2, { distanceSq = 80, onContinent = true }) }
	eq(Choose(list, nil).id, 2, 'a quest with no distance is farthest')
	list = { c(1, { distanceSq = 0, onContinent = true }), c(2, { distanceSq = 0, onContinent = true }) }
	eq(Choose(list, nil).id, 1, 'a tie goes to the game\'s order')
	list = { c(1, { distanceSq = 60, onContinent = true }), c(2, { distanceSq = 60, onContinent = true }), c(3, { distanceSq = 61, onContinent = true }) }
	eq(Choose(list, nil).id, 1, 'a tie between the nearest: the first')

	-- 4. The game's order.
	list = { c(7), c(8), c(9) }
	eq(Choose(list, nil).id, 7, 'no distance, no area, no focus: the first')
	list = { c(7, { distanceSq = 5, onContinent = false }), c(8) }
	eq(Choose(list, nil).id, 7, 'nothing on your continent: the first')
	eq(#take_errors(), 0, 'no errors')
end)

test('P4 fallback: with distance and areas not answering, focus then the game\'s order', function()
	local inside, distance = C_Minimap.IsInsideQuestBlob, C_QuestLog.GetDistanceSqToQuest
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = world({ client = client, before = function()
			C_Minimap.IsInsideQuestBlob, C_QuestLog.GetDistanceSqToQuest = nil, nil
		end, extra = { [3] = { inArea = true, distance = { sq = 1, onContinent = true } } } })
		-- (the stubs' answers are gone, so the quests carry none)
		eq(item_of_button(TR), 'item:1001', client .. ': no area, no distance, no focus: the game\'s order')
		C_QuestLog.GetDistanceSqToQuest, C_Minimap.IsInsideQuestBlob = nil, nil
		stub.quests.focused = 3
		stub.fire_event('SUPER_TRACKING_CHANGED')
		RW.later(1)
		eq(item_of_button(TR), 'item:1003', client .. ': the focused quest')
		stub.quests.focused = 0
		stub.fire_event('SUPER_TRACKING_CHANGED')
		RW.later(1)
		eq(item_of_button(TR), 'item:1001', client .. ': the focus gone: the game\'s order')
		eq(#take_errors(), 0, client .. ': no error from a missing API')
	end
	C_Minimap.IsInsideQuestBlob, C_QuestLog.GetDistanceSqToQuest = inside, distance
end)

test('only tracked quests with an item are candidates', function()
	local st, TR = world({ ids = { 2 } })
	TR.config.quests.show = 'zone'
	TR:UpdateConfig()
	-- Quest 4 is in the zone but not tracked, with an item and the nearest; quest 5
	-- is tracked and has no item.
	local entries = { Q.header('Elwynn Forest') }
	entries[#entries + 1] = Q.quest(2, { item = item_of(2), distance = { sq = 90, onContinent = true } })
	entries[#entries + 1] = Q.quest(4, { item = item_of(4), distance = { sq = 1, onContinent = true } })
	entries[#entries + 1] = Q.quest(5, { distance = { sq = 0, onContinent = true } })
	Q.set(entries, { 2, 5 })
	settle()
	check(RW.quest(TR, 4) ~= nil, 'the untracked zone quest is drawn')
	eq(item_of_button(TR), 'item:1002', 'an untracked quest of the zone is never offered, even the nearest')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the button and when it shows

test('off by default: no button, a holder and a disabled mover; on: the holder, the button, the item', function()
	local st, TR = world({ nearest = false })
	local holder = TR.nearestHolder
	check(holder ~= nil, 'the holder is made with the tracker')
	eq(holder, _G.SaftUITrackerNearestHolder, 'named SaftUITrackerNearestHolder')
	eq(TR.nearestButton, nil, 'but no button while it is off')
	eq(_G.SaftUITrackerNearestItem, nil, 'no secure frame by its name')
	eq(TW.counts.secure, 0, 'no secure frame made by the build')
	local mover = st.EditModeFrames.movers.trackernearest
	check(mover, 'the mover is registered')
	eq(mover.def.frame, holder, 'on the holder')
	eq(mover.def.label, 'Nearest quest item', 'label')
	eq(mover.def.module, 'Tracker', 'module')
	eq(table.concat(mover.def.configPath, '.'), 'Tracker.items', 'configPath')
	eq(st.EditModeFrames:IsMoverDisabled(mover), true, 'disabled while off')
	local default = mover.def.getDefaultPosition()
	eq(default.point .. default.rel_point, 'TOPRIGHTTOPRIGHT', 'the default spot')
	eq(default.x_off, -320, 'x')
	eq(default.y_off, -275, 'y on Forever')
	check(default ~= st.defaults.tracker.items.nearest_position, 'a copy of the default')
	default.x_off = 1
	eq(st.defaults.tracker.items.nearest_position.x_off, -320, 'a write never reaches the defaults')

	TR.config.items.nearest = true
	TR:UpdateConfig()
	RW.later(1)
	local b = button(TR)
	check(b ~= nil, 'on: the button is made')
	eq(b, _G.SaftUITrackerNearestItem, 'named SaftUITrackerNearestItem')
	protect(TR)
	check(TR.nearestDriver ~= nil, 'its parent is a state driver frame on the holder')
	eq(b:GetParent(), TR.nearestDriver, 'a child of the driver frame')
	eq(TR.nearestDriver:GetParent(), holder, 'which is its holder\'s child')
	check(b:IsProtected(), 'a secure frame')
	eq(b:GetWidth(), 40, 'nearest_size wide')
	eq(b:GetHeight(), 40, 'and high')
	eq(holder:GetWidth(), 40, 'the holder is the same size')
	check(b:IsShown(), 'shown: it has an item')
	eq(b:GetAttribute('type'), 'item', 'a secure item button')
	eq(item_of_button(TR), 'item:1002', 'the nearest: quest 2')
	eq(st.EditModeFrames:IsMoverDisabled(mover), false, 'its mover is on')
	eq(st.EditModeFrames:IsMoverHidden(mover), false, 'and not hidden: it has an item')
	local registered = stub.state(b).click_buttons
	eq(table.concat(registered or {}, ','), 'AnyUp,AnyDown', 'registered for AnyUp and AnyDown')
	eq(#take_errors(), 0, 'no errors')
end)

test('shown only while it has an item: no item hides it and clears its attributes; off hides it', function()
	local st, TR = world()
	local b = button(TR)
	local mover = st.EditModeFrames.movers.trackernearest
	check(b:IsShown(), 'it has an item')
	-- The quests lose their items.
	log({ 1, 2, 3 }, { [1] = { item = false }, [2] = { item = false }, [3] = { item = false } })
	settle()
	check(not b:IsShown(), 'no quest has an item: hidden')
	eq(b:GetAttribute('type'), nil, 'and it uses nothing: no type')
	eq(b:GetAttribute('item'), nil, 'no item')
	eq(st.EditModeFrames:IsMoverHidden(mover), true, 'its mover is hidden while it has no item')
	eq(st.EditModeFrames:IsMoverDisabled(mover), false, 'but not disabled')
	-- An item comes back.
	log({ 1, 2, 3 }, DISTANCES)
	settle()
	check(b:IsShown(), 'an item again: shown')
	eq(b:GetAttribute('item'), 'item:1002', 'the nearest')
	-- Off.
	TR.config.items.nearest = false
	TR:UpdateConfig()
	RW.later(1)
	check(not b:IsShown(), 'off: hidden')
	eq(b:GetAttribute('type'), nil, 'off: it uses nothing')
	eq(st.EditModeFrames:IsMoverDisabled(mover), true, 'off: the mover is disabled')
	-- An empty tracker.
	TR.config.items.nearest = true
	TR:UpdateConfig()
	RW.later(1)
	check(b:IsShown(), 'on again')
	log({}, nil)
	settle()
	check(not b:IsShown(), 'no quests: hidden')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('it never hides with the tracker and does not depend on the placement of the row buttons', function()
	local st, TR = world()
	for _, placement in ipairs({ 'row', 'beside', 'off' }) do
		TR.config.items.placement = placement
		TR:UpdateConfig()
		RW.later(1)
		check(button(TR):IsShown(), placement .. ': the nearest button shows')
		eq(item_of_button(TR), 'item:1002', placement .. ': with its item')
	end
	-- Its parent is its holder, on UIParent: not the item layer, not the window.
	eq(button(TR):GetParent(), TR.nearestDriver, 'a child of its driver frame')
	eq(TR.nearestDriver:GetParent(), TR.nearestHolder, 'on its holder')
	eq(TR.nearestHolder:GetParent(), UIParent, 'the holder is on UIParent')
	eq(#take_errors(), 0, 'no errors')
end)

test('no secure frame is a child of, or anchored to, a SaftUI frame that moves: the button is on its holder, the holder on UIParent', function()
	local st, TR = world()
	local b, holder = button(TR), TR.nearestHolder
	eq(b:GetNumPoints(), 1, 'one anchor')
	local _, relative = b:GetPoint(1)
	eq(relative, holder, 'to its holder')
	for i = 1, holder:GetNumPoints() do
		local _, rel = holder:GetPoint(i)
		eq(rel, UIParent, 'the holder is anchored to UIParent')
	end
	for _, frame in ipairs({ TR.window, TR.scroll, TR.content, TR.holder }) do
		check(b:GetParent() ~= frame, 'not a child of the tracker')
		for i = 1, b:GetNumPoints() do
			local _, rel = b:GetPoint(i)
			check(rel ~= frame, 'not anchored to the tracker')
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ chosen again, frozen in combat

test('chosen again each second out of combat; frozen in combat; caught up at combat end, stub.blocked empty', function()
	local st, TR = world()
	local b = button(TR)
	eq(item_of_button(TR), 'item:1002', 'quest 2 is the nearest')
	local watcher = TR.nearestWatcher
	check(watcher:GetScript('OnUpdate') ~= nil, 'a one second tick runs while the button is on')
	-- The game moves the player: no event, only the distance changes.
	entry(3).distance = { sq = 10, onContinent = true }
	stub.fire_script(watcher, 'OnUpdate', 0.5)
	eq(item_of_button(TR), 'item:1002', 'not chosen before the second is up')
	stub.fire_script(watcher, 'OnUpdate', 0.5)
	eq(item_of_button(TR), 'item:1003', 'chosen again after a second')
	entry(1).distance = { sq = 5, onContinent = true }
	stub.fire_script(watcher, 'OnUpdate', 1)
	eq(item_of_button(TR), 'item:1001', 'and each second after')

	-- Combat: nothing secure; the button keeps its item.
	TW.combat(true)
	TW.count_from_now()
	entry(2).distance = { sq = 1, onContinent = true }
	stub.fire_script(watcher, 'OnUpdate', 1)
	stub.fire_script(watcher, 'OnUpdate', 5)
	stub.fire_event('SUPER_TRACKING_CHANGED')
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 2, true)
	settle()
	RW.later(3)
	eq(item_of_button(TR), 'item:1001', 'frozen in combat: the item it had')
	check(b:IsShown(), 'still shown')
	eq(b:GetAlpha(), 1, 'at full strength: its own quest still has the item')
	eq(#stub.blocked, 0, 'no secure call was even tried')
	-- What the key does is what the button shows.
	stub.secure_clicks = {}
	stub.press_key(b, true)
	stub.press_key(b, false)
	eq(#stub.secure_clicks, 1, 'the key uses an item once')
	eq(last_use().item, 'item:1001', 'the one the button shows, whatever is nearest now')
	TW.count_stop()
	eq(TW.counts.secure, 0, 'no secure frame made in combat')
	TW.combat(false)
	eq(item_of_button(TR), 'item:1002', 'caught up at combat end: the nearest now')
	eq(#stub.blocked, 0, 'nothing blocked at the end either')
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a button whose quest lost its item dims to 40% and still uses its own item; its tooltip names the quest; at combat end it is right', function()
	local st, TR = world()
	local b = button(TR)
	eq(item_of_button(TR), 'item:1002', 'quest 2')
	TW.combat(true)
	log({ 1, 3 }, DISTANCES) -- quest 2 turned in: its item is gone
	settle()
	eq(item_of_button(TR), 'item:1002', 'the attribute can\'t change in combat')
	check(b:IsShown(), 'still shown (it can\'t be hidden in combat)')
	eq(b:GetAlpha(), TR.DIM_ALPHA, 'dimmed to 40%')
	check(b:GetAlpha() >= TR.BUTTON_MIN_ALPHA, 'never under the floor while clickable')
	stub.fire_script(b, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[#texts], 'Quest 2', 'its tooltip names the quest it was')
	stub.fire_script(b, 'OnLeave', true)
	stub.secure_clicks = {}
	stub.press_key(b, true)
	eq(last_use().item, 'item:1002', 'a key press still names the item the button shows')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	eq(item_of_button(TR), 'item:1001', 'combat ends: the nearest of what is left')
	eq(b:GetAlpha(), 1, 'full strength again')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat the count, the cooldown and the range follow the quest while its item is the same one', function()
	local st, TR = world()
	local b = button(TR)
	TW.combat(true)
	entry(2).item.charges = 3
	entry(2).item.cooldown = { start = 100, duration = 30, enable = 1 }
	settle()
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	eq(b.count:GetText(), '3', 'the count is drawn')
	eq(stub.state(b.cooldown).cooldown_duration, 30, 'and the cooldown')
	stub.quests.log[3].item.range = 0 -- quest 2's entry
	stub.fire_script(TR.nearestWatcher, 'OnUpdate', 0.3)
	local red = ('%.2f %.2f %.2f'):format(st.config.profile.colors.text.danger:GetRGB())
	eq(('%.2f %.2f %.2f'):format(b.icon:GetVertexColor()), red, 'out of range: red, read every 0.2 s')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('a quest area entered: PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED chooses again and the accent shows', function()
	local st, TR = world()
	local b = button(TR)
	eq(item_of_button(TR), 'item:1002', 'quest 2 by distance')
	entry(3).inArea = true
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 3, true)
	eq(item_of_button(TR), 'item:1003', 'inside quest 3\'s area: quest 3')
	local accent = ('%.2f,%.2f,%.2f'):format(st.config.profile.theme.accent:GetRGB())
	eq(('%.2f,%.2f,%.2f'):format(b.backdrop:GetBackdropBorderColor()), accent, 'its border is the accent')
	entry(3).inArea = false
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 3, false)
	eq(item_of_button(TR), 'item:1002', 'out again: back to the nearest')
	eq(#take_errors(), 0, 'no errors')
end)

test('the focus counts: a super tracked quest before the distance', function()
	local st, TR = world()
	stub.quests.focused = 1
	stub.fire_event('SUPER_TRACKING_CHANGED')
	RW.later(1)
	eq(item_of_button(TR), 'item:1001', 'the focused quest')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the switch and a /reload in combat

test('with the tracker off nothing is made, bound or run', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		stub.bindings, stub.saved_bindings = {}, {}
		local st, TR = TW.world({ client = client, enabling = function(st) st.config.profile.tracker.items.nearest = true; log({ 1, 2 }, DISTANCES) end })
		eq(TW.counts.frames, 0, client .. ': no frame')
		eq(TW.counts.secure, 0, client .. ': no secure frame')
		eq(TW.counts.events, 0, client .. ': no event')
		eq(TW.counts.hooks, 0, client .. ': no hook')
		eq(TR.nearestHolder, nil, client .. ': no holder')
		eq(TR.nearestButton, nil, client .. ': no button')
		eq(_G.SaftUITrackerNearestHolder, nil, client .. ': none by name')
		eq(st.EditModeFrames.movers.trackernearest, nil, client .. ': no mover')
		eq(TR:RefreshNearest(), nil, client .. ': RefreshNearest does nothing')
		TW.combat(true)
		TW.combat(false)
		stub.fire_event('UPDATE_BINDINGS')
		eq(next(stub.bindings), nil, client .. ': no binding was set')
		eq(#stub.saved_bindings, 0, client .. ': none saved')
		eq(TW.counts.secure, 0, client .. ': still none after combat')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('a /reload in combat: the holder and mover at once, the button only when combat ends', function()
	local st, TR = world({ combat = true })
	check(TR.nearestHolder ~= nil, 'the holder is made at once (it is not secure)')
	eq(TR.nearestButton, nil, 'no button in combat')
	eq(_G.SaftUITrackerNearestItem, nil, 'none by name')
	eq(TW.counts.secure, 0, 'no secure frame made in combat')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.count_from_now()
	TW.combat(false)
	TW.count_stop()
	check(TR.nearestButton ~= nil, 'combat ends: the button is made')
	eq(TW.counts.secure, 6, 'once, with the layer, the three row buttons, the nearest button and its driver frame')
	check(TR.nearestButton:IsShown(), 'and shown with its item')
	RW.later(2)
	eq(TW.counts.secure, 6, 'and made no more')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('resized and moved in combat: nothing is touched; one pass at combat end makes it right', function()
	local st, TR = world()
	local b, holder = button(TR), TR.nearestHolder
	local mover = st.EditModeFrames.movers.trackernearest
	TW.combat(true)
	TW.count_from_now()
	TR.config.items.nearest_size = 56
	TR.config.items.nearest_position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 100, y_off = -100 }
	TR:UpdateConfig()
	mover.def.apply()
	settle()
	TW.count_stop()
	eq(b:GetWidth(), 40, 'the button keeps its size in combat')
	eq(holder:GetWidth(), 40, 'the holder too')
	local point = holder:GetPoint(1)
	eq(point, 'TOPRIGHT', 'and its place')
	eq(#stub.blocked, 0, 'nothing was even tried')
	eq(TW.counts.secure, 0, 'nothing secure was made')
	TW.combat(false)
	eq(b:GetWidth(), 56, 'combat ends: the new size')
	eq(holder:GetWidth(), 56, 'the holder')
	point = holder:GetPoint(1)
	eq(point, 'TOPLEFT', 'and the new place')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('turned off in combat: it keeps what it had until combat ends, then clears', function()
	local st, TR = world()
	local b = button(TR)
	TW.combat(true)
	TR.config.items.nearest = false
	TR:UpdateConfig()
	settle()
	check(b:IsShown(), 'shown still')
	eq(b:GetAttribute('item'), 'item:1002', 'with its item')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	check(not b:IsShown(), 'combat ends: hidden')
	eq(b:GetAttribute('type'), nil, 'and cleared')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the key

test('the key: get is GetBindingKey of the command; set clears the old keys, binds and saves; Esc clears', function()
	local st, TR = world()
	eq(TR.NearestKey(), nil, 'no key bound')
	stub.bindings.F = COMMAND
	eq(TR.NearestKey(), 'F', 'get: the bound key')
	stub.bindings.G = 'SOMETHINGELSE'
	eq(TR.NearestKey(), 'F', 'another command\'s key is not it')
	stub.bindings.F = nil
	eq(TR.NearestKey(), nil, 'unbound again')

	stub.bindings.F = COMMAND
	stub.bindings.H = COMMAND
	stub.saved_bindings = {}
	TR:SetNearestKey('SHIFT-J')
	eq(stub.bindings.F, nil, 'set: the old key is cleared')
	eq(stub.bindings.H, nil, 'all the old keys')
	eq(stub.bindings['SHIFT-J'], COMMAND, 'the new key is bound')
	eq(stub.bindings.G, 'SOMETHINGELSE', 'another command is left alone')
	eq(#stub.saved_bindings, 1, 'saved')
	eq(stub.saved_bindings[1], stub.binding_set, 'SaveBindings(GetCurrentBindingSet())')
	eq(TR.NearestKey(), 'SHIFT-J', 'and get reads it back')

	TR:SetNearestKey('')
	eq(next({ GetBindingKey(COMMAND) }), nil, 'an empty key clears it (Esc)')
	eq(#stub.saved_bindings, 2, 'and saves')
	eq(TR.NearestKey(), nil, 'no key')
	TR:SetNearestKey('')
	eq(#stub.saved_bindings, 3, 'clearing nothing is harmless')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('a key the game refuses leaves the old one bound', function()
	local st, TR = world()
	stub.bindings.F = COMMAND
	stub.rejected_keys.X = true
	TR:SetNearestKey('X')
	eq(stub.bindings.F, COMMAND, 'the old key is back')
	eq(stub.bindings.X, nil, 'the new one is not bound')
	eq(#take_errors(), 0, 'no errors')
end)

test('the key in combat: queued as tracker_binding, nothing blocked, the last one asked for is bound at combat end', function()
	local st, TR = world()
	stub.bindings.F = COMMAND
	stub.saved_bindings = {}
	TW.combat(true)
	TR:SetNearestKey('J')
	TR:SetNearestKey('K')
	eq(TR.NearestKey(), 'F', 'in combat the old key still reads')
	eq(stub.bindings.F, COMMAND, 'and is bound')
	eq(#stub.blocked, 0, 'SetBinding and SaveBindings were not even tried')
	eq(#stub.saved_bindings, 0, 'nothing saved')
	TW.combat(false)
	eq(stub.bindings.F, nil, 'combat ends: the old key goes')
	eq(stub.bindings.K, COMMAND, 'the last key asked for is bound')
	eq(stub.bindings.J, nil, 'not the one before')
	eq(#stub.saved_bindings, 1, 'saved once')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('the stubs refuse SetBinding and SaveBindings in combat, as the game does', function()
	stub.bindings, stub.saved_bindings = {}, {}
	stub.in_combat = true
	SetBinding('F', COMMAND)
	SaveBindings(GetCurrentBindingSet())
	stub.in_combat = false
	eq(next(stub.bindings), nil, 'nothing bound')
	eq(#stub.saved_bindings, 0, 'nothing saved')
	eq(#stub.blocked, 2, 'both refused')
	eq(stub.blocked[1][1], SetBinding, 'SetBinding')
	eq(stub.blocked[1][2], 'F', 'for the key')
	eq(stub.blocked[2][1], SaveBindings, 'SaveBindings')
	stub.blocked = {}
end)

test('the Key row: a keybinding on the Items tab, get and set the game\'s binding, its default resets to no key', function()
	local st, TR = world()
	local tab = TR.ItemsTab()
	local key = tab.args.key
	eq(key.type, 'keybinding', 'type')
	eq(key.name, 'Key', 'name')
	check(type(key.desc) == 'string' and key.desc ~= '', 'a desc')
	stub.bindings.F = COMMAND
	eq(key.get({}), 'F', 'get is the binding')
	key.set({}, 'G')
	eq(stub.bindings.G, COMMAND, 'set binds')
	eq(stub.bindings.F, nil, 'and clears the old')
	eq(key.default.differs(), true, 'a bound key differs from the default')
	key.default.reset()
	eq(TR.NearestKey(), nil, 'reset: no key')
	eq(key.default.differs(), false, 'no longer differs')
	eq(key.default.text, 'Not bound', 'the default reads Not bound')
	-- The nearest rows around it.
	eq(tab.args.nearest.type, 'toggle', 'Nearest quest item button')
	eq(tab.args.nearest.default.value(), false, 'off by default')
	eq(tab.args.nearest_size.type, 'range', 'Nearest button size')
	eq(tab.args.nearest_size.default.value(), 40, 'default 40')
	eq(tab.args.nearest_position.type, 'position', 'Position')
	eq(tab.args.nearest_position.order, 1000, 'last')
	eq(tab.args.nearest_position.name, 'Position', 'named Position')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Position row moves the holder and saves nearest_position', function()
	local st, TR = world()
	local position = TR.ItemsTab().args.nearest_position
	position.set({}, 'x_off', -100)
	eq(TR.config.items.nearest_position.x_off, -100, 'saved')
	TR:UpdateConfig()
	local _, _, _, x = TR.nearestHolder:GetPoint(1)
	eq(x, -100, 'the holder follows')
	eq(position.get({}, 'x_off'), -100, 'and reads it back')
	position.default.reset()
	eq(TR.config.items.nearest_position.x_off, -320, 'reset to the default')
	eq(#take_errors(), 0, 'no errors')
end)

test('a key bound once uses the item once per press with ActionButtonUseKeyDown on and off', function()
	local st, TR = world()
	local b = button(TR)
	TR:SetNearestKey('J')
	for _, key_down in ipairs({ true, false }) do
		stub.cast_on_key_down = key_down
		stub.secure_clicks = {}
		stub.press_key(b, true)
		stub.press_key(b, false)
		eq(#stub.secure_clicks, 1, 'on key down ' .. tostring(key_down) .. ': one use per press')
		eq(last_use().down, key_down, 'on the ' .. (key_down and 'press' or 'release'))
		eq(last_use().type, 'item', 'by its type')
		eq(last_use().item, 'item:1002', 'and its item')
		-- Held: the game repeats nothing; a second press is a second use.
		stub.press_key(b, true)
		stub.press_key(b, false)
		eq(#stub.secure_clicks, 2, 'a second press, a second use')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a key with no item uses nothing, whether or not the game delivers its click to a hidden button', function()
	local st, TR = world()
	local b = button(TR)
	log({}, nil)
	settle()
	check(not b:IsShown(), 'hidden')
	stub.secure_clicks = {}
	-- Whether the engine delivers a CLICK binding to a hidden button can't be read
	-- from Lua; the safety is that a button with no item has no type.
	stub.click_unchecked(b, 'LeftButton', true)
	stub.click_unchecked(b, 'LeftButton', false)
	eq(#stub.secure_clicks, 0, 'nothing was used')
	eq(b:GetAttribute('type'), nil, 'and it has no type to use it with')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ its look

test('its key in the Pixel font at the top right, refreshed on UPDATE_BINDINGS', function()
	local st, TR = world()
	local b = button(TR)
	local text = b.keyText
	check(text ~= nil, 'a key text')
	eq(text:GetFontObject(), st:GetFont('pixel'), 'in the Pixel font')
	local point, _, relPoint = text:GetPoint(1)
	eq(point .. relPoint, 'TOPRIGHTTOPRIGHT', 'at the top right')
	check(not text:IsShown(), 'no key, no text')
	stub.bindings['SHIFT-F'] = COMMAND
	stub.fire_event('UPDATE_BINDINGS')
	check(text:IsShown(), 'a key: shown')
	eq(text:GetText(), 'SF', 'shortened as the action bars do')
	stub.bindings['SHIFT-F'] = nil
	stub.bindings.BUTTON4 = COMMAND
	stub.fire_event('UPDATE_BINDINGS')
	eq(text:GetText(), 'M4', 'a mouse button')
	stub.bindings.BUTTON4 = nil
	stub.bindings.F = COMMAND
	stub.fire_event('UPDATE_BINDINGS')
	eq(text:GetText(), 'F', 'a plain key')
	-- In combat the text is only drawn (a font string of a child frame).
	TW.combat(true)
	stub.bindings.F = nil
	stub.bindings['CTRL-ALT-Q'] = COMMAND
	stub.fire_event('UPDATE_BINDINGS')
	eq(text:GetText(), 'CAQ', 'refreshed in combat too')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	stub.bindings['CTRL-ALT-Q'] = nil
	stub.fire_event('UPDATE_BINDINGS')
	check(not text:IsShown(), 'unbound: hidden again')
	-- A key bound before the button is made shows when it is.
	eq(#take_errors(), 0, 'no errors')
end)

test('a key bound before the button exists shows when it is made', function()
	local st, TR = world({ nearest = false })
	stub.bindings.F = COMMAND
	TR.config.items.nearest = true
	TR:UpdateConfig()
	RW.later(1)
	check(button(TR).keyText:IsShown(), 'shown')
	eq(button(TR).keyText:GetText(), 'F', 'with the key')
	eq(#take_errors(), 0, 'no errors')
end)

test('its tooltip: the item, then the quest\'s title, obeying Tooltips', function()
	local st, TR = world()
	local b = button(TR)
	stub.fire_script(b, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[1], 'quest item 3', 'the game\'s tooltip for the quest item (the header is the first entry)')
	eq(texts[2], 'Quest 2', 'then the quest\'s title')
	check(GameTooltip:IsShown(), 'shown')
	eq(GameTooltip:GetOwner(), b, 'owned by the button')
	stub.fire_script(b, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'hidden with the mouse')
	TR.config.quests.tooltips = false
	stub.fire_script(b, 'OnEnter', true)
	check(not GameTooltip:IsShown(), 'Tooltips off: none')
	stub.fire_script(b, 'OnLeave', true)
	eq(#take_errors(), 0, 'no errors')
end)

test('its look is the row buttons\': kind action in the tracker\'s pair, the icon cropped, a hover; whole pixels under the three looks', function()
	local checked = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				for _, size in ipairs({ 24, 40, 64 }) do
					local where = ('%s, %s, noise %g, size %d'):format(client, theme, noise, size)
					local st, TR = world({ client = client })
					T.theme(theme, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
					TR.config.items.nearest_size = size
					stub.size_noise = noise
					TR:UpdateConfig()
					TR:Refresh()
					RW.later(1)
					local b = button(TR)
					eq(b:GetWidth() > size - 1 and b:GetWidth() < size + 1, true, where .. ': the size')
					local off = P.off(TR.nearestHolder)
					eq(#off, 0, where .. ' (the holder): ' .. P.report(off))
					off = P.off(b)
					eq(#off, 0, where .. ' (the button): ' .. P.report(off))
					stub.size_noise = 0
					checked = checked + 1
				end
			end
		end
	end
	eq(checked, 2 * 3 * 3 * 3, 'every combination ran')
	local st, TR = world()
	local b = button(TR)
	check(b.backdrop ~= nil, 'drawn')
	eq(b.hover:GetDrawLayer(), 'HIGHLIGHT', 'the hover is in the HIGHLIGHT layer')
	local trim = st.config.profile.misc.icon_trim
	local l, r, t, bottom = st:IconTexCoords(trim, 40, 40)
	local probe = UIParent:CreateTexture(nil, 'ARTWORK')
	probe:SetTexCoord(l, r, t, bottom)
	check(table.concat({ b.icon:GetTexCoord() }, ',') == table.concat({ probe:GetTexCoord() }, ','), 'the icon cropped by Icon zoom')
	eq(b.icon:GetTexture(), 134402, 'the quest item\'s texture')
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile switch to another nearest spot and size places the holder; the mover reads and writes the profile', function()
	local st, TR = world()
	local mover = st.EditModeFrames.movers.trackernearest
	local position = mover.def.getPosition()
	eq(position, TR.config.items.nearest_position, 'the mover reads the profile\'s position')
	mover.def.setPosition({ point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 7, y_off = 9 })
	eq(TR.config.items.nearest_position.x_off, 7, 'and writes it')
	mover.def.apply()
	local point, _, _, x, y = TR.nearestHolder:GetPoint(1)
	eq(point, 'CENTER', 'apply places the holder')
	eq(x, 7, 'at x')
	eq(y, 9, 'and y')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ fix round 1

local function printed(fn)
	local real, lines = print, {}
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

test('the tick keeps the cooldown and the range the button read itself, never the model\'s stale ones', function()
	local st, TR = world()
	local b, watcher = button(TR), TR.nearestWatcher
	entry(2).item.cooldown = { start = 100, duration = 30, enable = 1 }
	stub.fire_event('BAG_UPDATE_COOLDOWN') -- no refresh: the model still has none
	eq(stub.state(b.cooldown).cooldown_duration, 30, 'the swipe is drawn')
	stub.fire_script(watcher, 'OnUpdate', 1)
	eq(stub.state(b.cooldown).cooldown_duration, 30, 'and the once a second choice leaves it')
	stub.quests.log[3].item.range = 0 -- quest 2's entry
	stub.fire_script(watcher, 'OnUpdate', 0.25)
	eq(b.range, 0, 'out of range, read live')
	stub.fire_script(watcher, 'OnUpdate', 0.75)
	eq(b.range, 0, 'and the choice does not put the model\'s value back')
	local red = ('%.2f %.2f %.2f'):format(st.config.profile.colors.text.danger:GetRGB())
	eq(('%.2f %.2f %.2f'):format(b.icon:GetVertexColor()), red, 'still red')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Position row refuses an anchor that would protect the tracker window or what moves with it, and says why', function()
	local st, TR = world()
	local position = TR.ItemsTab().args.nearest_position
	_G.NearestTestRow, _G.NearestTestContent = RW.quest(TR, 1), TR.content
	for _, name in ipairs({ 'SaftUITracker', 'NearestTestRow', 'NearestTestContent' }) do
		local result = position.validate({}, 'frame', name)
		check(type(result) == 'string' and result:find('changes size in combat', 1, true), name .. ' is refused with the reason: ' .. tostring(result))
	end
	eq(position.validate({}, 'frame', 'UIParent'), true, 'UIParent is fine')
	eq(position.validate({}, 'frame', 'SaftUITrackerHolder'), true, 'so is the tracker\'s holder (placed through SafeReposition)')
	-- A frame anchored to the window moves with it.
	local hung = CreateFrame('Frame', 'NearestTestHung', UIParent)
	hung:SetPoint('TOPLEFT', TR.window, 'BOTTOMLEFT')
	check(type(position.validate({}, 'frame', 'NearestTestHung')) == 'string', 'a frame anchored to the window is refused')
	-- A saved position that names the window (an import) is placed on UIParent.
	TR.config.items.nearest_position.frame = 'SaftUITracker'
	TR:UpdateConfig()
	local _, relative = TR.nearestHolder:GetPoint(1)
	eq(relative, UIParent, 'the holder is on UIParent whatever the profile says')
	eq(TR.config.items.nearest_position.frame, 'SaftUITracker', 'and the profile is left as it was')
	-- Nothing of the window is anchored to the holder's chain.
	for i = 1, TR.window:GetNumPoints() do
		local _, rel = TR.window:GetPoint(i)
		check(rel ~= TR.nearestHolder and rel ~= TR.nearestDriver and rel ~= button(TR), 'the window never hangs from the nearest button')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('combat events leave the protected holder alone: UPDATE_BINDINGS, BAG_UPDATE_COOLDOWN, the area, the focus, the tick, a quest update', function()
	local st, TR = world()
	local holder = TR.nearestHolder
	check(stub.state(holder).protected, 'the holder is marked protected, as the game protects it')
	local before = TW.snapshot(holder)
	TW.combat(true)
	stub.bindings.F = COMMAND
	stub.fire_event('UPDATE_BINDINGS')
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 2, true)
	stub.fire_event('SUPER_TRACKING_CHANGED')
	stub.fire_script(TR.nearestWatcher, 'OnUpdate', 1)
	settle()
	TR:UpdateConfig()
	st:ColorsChanged('button')
	eq(TW.snapshot(holder), before, 'the holder is as it was')
	eq(holder:GetWidth(), 40, 'its size')
	eq(#stub.blocked, 0, 'nothing was even tried on it')
	TW.combat(false)
	eq(#stub.blocked, 0, 'nor at the end')
	eq(#take_errors(), 0, 'no errors')
end)

test('SaveBindings gets the current binding set: the character set too', function()
	local st, TR = world()
	stub.binding_set = 2
	stub.saved_bindings = {}
	TR:SetNearestKey('J')
	eq(stub.saved_bindings[1], 2, 'SaveBindings(GetCurrentBindingSet()) with the character set')
	stub.binding_set = 1
	eq(#take_errors(), 0, 'no errors')
end)

test('an item that changes in combat: the icon and the attribute stay the old ones, the button dims, the new one comes at the end', function()
	local st, TR = world()
	local b = button(TR)
	eq(b.icon:GetTexture(), 134402, 'quest 2\'s icon')
	TW.combat(true)
	entry(2).item = item_of(9)
	settle()
	eq(b.icon:GetTexture(), 134402, 'the icon is still the item it uses')
	eq(b:GetAttribute('item'), 'item:1002', 'and so is the attribute')
	eq(b:GetAlpha(), TR.DIM_ALPHA, 'dimmed: its item is not the quest\'s now')
	stub.secure_clicks = {}
	stub.press_key(b, true)
	eq(last_use().item, 'item:1002', 'the key uses what the button shows')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	eq(b:GetAttribute('item'), 'item:1009', 'combat ends: the new item')
	eq(b.icon:GetTexture(), 134409, 'and its icon')
	eq(b:GetAlpha(), 1, 'full strength')
	eq(#take_errors(), 0, 'no errors')
end)

test('a key taken from another action, or refused, is said in chat, as /sui kb does', function()
	local st, TR = world()
	stub.binding_names[COMMAND] = 'Use the nearest quest item'
	stub.binding_names.ACTIONBUTTON1 = 'Action Button 1'
	stub.bindings.F = 'ACTIONBUTTON1'
	local lines = printed(function() TR:SetNearestKey('F') end)
	eq(#lines, 1, 'one line')
	check(lines[1]:find('F bound to Use the nearest quest item (was Action Button 1).', 1, true), 'names what it was: ' .. lines[1])
	eq(stub.bindings.F, COMMAND, 'and it is bound')
	lines = printed(function() TR:SetNearestKey('G') end)
	check(lines[1]:find('G bound to Use the nearest quest item.', 1, true) and not lines[1]:find('was', 1, true), 'a free key: no was: ' .. lines[1])
	lines = printed(function() TR:SetNearestKey('G') end)
	check(not lines[1]:find('was', 1, true), 'the same key again: no was')
	stub.rejected_keys.X = true
	lines = printed(function() TR:SetNearestKey('X') end)
	check(lines[1]:find("Can't bind X to Use the nearest quest item.", 1, true), 'a refusal says so: ' .. lines[1])
	eq(stub.bindings.G, COMMAND, 'and the old key is back')
	eq(#printed(function() TR:SetNearestKey('') end), 0, 'clearing says nothing')
	-- In combat it says it when the change is made.
	TW.combat(true)
	lines = printed(function() TR:SetNearestKey('H') end)
	eq(#lines, 0, 'nothing in combat')
	lines = printed(function() TW.combat(false) end)
	eq(#lines, 1, 'one line at the end')
	eq(#take_errors(), 0, 'no errors')
end)

test('the button hides in a pet battle by a visibility driver on its parent, set when the button is made, out of combat', function()
	local st, TR = world()
	local driver = TR.nearestDriver
	eq(driver, _G.SaftUITrackerNearestDriver, 'named')
	check(driver:IsProtected(), 'a secure state frame')
	eq(stub.state(driver).state_drivers['state-visibility'], TR.ITEM_DRIVER, 'the item layer\'s driver: [petbattle] hide; show')
	eq(driver:GetNumPoints(), 2, 'it fills the holder')
	check(not driver:IsMouseEnabled(), 'and takes no mouse')
	eq(button(TR):GetParent(), driver, 'the button is its child')
	-- A /reload in combat makes none of it until the end.
	local _, TR2 = world({ combat = true })
	eq(TR2.nearestDriver, nil, 'no driver in combat')
	TW.combat(false)
	check(TR2.nearestDriver ~= nil, 'made when combat ends')
	eq(#take_errors(), 0, 'no errors')
end)

test('st:ShortBindingKey, Core\'s: modifiers as letters, mouse buttons, numpad, a short key unchanged', function()
	local st = world({ nearest = false })
	local cases = {
		['SHIFT-F'] = 'SF', ['CTRL-ALT-Q'] = 'CAQ', ['BUTTON4'] = 'M4', ['NUMPAD5'] = 'N5', ['MOUSEWHEELUP'] = 'MU',
		['SHIFT-MOUSEWHEELDOWN'] = 'SMD', ['SPACE'] = 'SpB', ['F'] = 'F', ['SF'] = 'SF', ['PAGEUP'] = 'PU',
	}
	for key, short in pairs(cases) do eq(st:ShortBindingKey(key), short, key) end
end)

test('with the setting off and no button, combat queues and dims nothing', function()
	local st, TR = world({ nearest = false })
	local queued = 0
	local queue = st.QueueAfterCombat
	st.QueueAfterCombat = function(self, key, fn)
		if key == 'tracker_nearest' then queued = queued + 1 end
		return queue(self, key, fn)
	end
	TW.combat(true)
	settle()
	TW.combat(false)
	st.QueueAfterCombat = queue
	eq(queued, 0, 'nothing queued for the nearest button')
	eq(#take_errors(), 0, 'no errors')
end)

test('the holder and the button are one whole-pixel size; the tick stops when the setting goes off; a recolor reaches the button', function()
	local st, TR = world()
	TR.config.items.nearest_size = 25.3
	TR:UpdateConfig()
	RW.later(1)
	eq(button(TR):GetWidth(), TR.nearestHolder:GetWidth(), 'the same size')
	local watcher = TR.nearestWatcher
	check(watcher:GetScript('OnUpdate') ~= nil, 'ticking while on')
	local colored = 0
	local color = TR.ColorNearest
	TR.ColorNearest = function(...) colored = colored + 1; return color(...) end
	st:ColorsChanged('button')
	TR.ColorNearest = color
	eq(colored, 1, 'a Colors change reaches the button')
	TR.config.items.nearest = false
	TR:UpdateConfig()
	RW.later(1)
	eq(watcher:GetScript('OnUpdate'), nil, 'off: no tick')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ fix round 2

test('a chain made later falls back at the next placement; the saved position is left as it was', function()
	local st, TR = world()
	local hung = CreateFrame('Frame', 'NearestTestChain', UIParent)
	hung:SetPoint('CENTER')
	TR.config.items.nearest_position = { point = 'TOPLEFT', frame = 'NearestTestChain', rel_point = 'BOTTOMLEFT', x_off = 3, y_off = 4 }
	TR:UpdateConfig()
	local _, relative = TR.nearestHolder:GetPoint(1)
	eq(relative, hung, 'an accepted frame')
	-- Its own Position row (which only refuses loops) now hangs it from the window.
	hung:ClearAllPoints()
	hung:SetPoint('TOPLEFT', TR.window, 'BOTTOMLEFT')
	TR:UpdateConfig()
	_, relative = TR.nearestHolder:GetPoint(1)
	eq(relative, UIParent, 'the chain through the window is seen at the placement: UIParent')
	eq(TR.config.items.nearest_position.frame, 'NearestTestChain', 'the profile is untouched')
	eq(#take_errors(), 0, 'no errors')
end)

test('Blizzard\'s tracker, which SaftUI\'s conceals, is no anchor while SaftUI owns it', function()
	local st, TR = world({ blizzard = true })
	local position = TR.ItemsTab().args.nearest_position
	check(_G.ObjectiveTrackerFrame ~= nil, 'the fixture made it')
	local result = position.validate({}, 'frame', 'ObjectiveTrackerFrame')
	check(type(result) == 'string' and result:find("Blizzard's tracker", 1, true), 'refused, with its own reason: ' .. tostring(result))
	local hung = CreateFrame('Frame', 'NearestTestBlizzardHung', UIParent)
	hung:SetPoint('TOPLEFT', _G.ObjectiveTrackerFrame, 'BOTTOMLEFT')
	check(type(position.validate({}, 'frame', 'NearestTestBlizzardHung')) == 'string', 'and what hangs from it')
	TR.config.items.nearest_position = { point = 'TOPLEFT', frame = 'ObjectiveTrackerFrame', rel_point = 'TOPLEFT', x_off = 0, y_off = 0 }
	TR:UpdateConfig()
	local _, relative = TR.nearestHolder:GetPoint(1)
	eq(relative, UIParent, 'a saved one is placed on UIParent')
	eq(position.validate({}, 'frame', 'UIParent'), true, 'UIParent is fine')
	-- Without the tracker owning Blizzard's, nothing is refused on its account.
	local _, TR2 = world()
	eq(TR2.NearestAnchorRefusal(nil), nil, 'no frame, no refusal')
	eq(#take_errors(), 0, 'no errors')
end)

test('edit mode and the Position row start from the placed position, not the refused saved one', function()
	local st, TR = world()
	local mover = st.EditModeFrames.movers.trackernearest
	local position = TR.ItemsTab().args.nearest_position
	TR.config.items.nearest_position = { point = 'TOPLEFT', frame = 'SaftUITracker', rel_point = 'BOTTOMLEFT', x_off = 5, y_off = 6 }
	TR:UpdateConfig()
	eq(mover.def.getPosition().frame, 'UIParent', 'the mover reads the placed position')
	eq(position.get({}, 'frame'), 'UIParent', 'and so does the row')
	eq(TR.config.items.nearest_position.frame, 'SaftUITracker', 'the profile is not written by a read')
	-- A drag's commit saves the UIParent form and heals the profile.
	mover.def.setPosition({ point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 1, y_off = 2 })
	eq(TR.config.items.nearest_position.frame, 'UIParent', 'healed')
	eq(mover.def.getPosition(), TR.config.items.nearest_position, 'and an accepted position is the profile\'s own table')
	eq(#take_errors(), 0, 'no errors')
end)

test('the holder and the button are the rounded size, in whole pixels', function()
	local st, TR = world({ screen = { 1920, 1080 } })
	TR.config.items.nearest_size = 25.3
	TR:UpdateConfig()
	RW.later(1)
	local rounded = st:RoundToPixel(25.3, TR.nearestHolder)
	check(rounded ~= 25.3, 'the size needs rounding at this scale')
	eq(button(TR):GetWidth(), rounded, 'the button is the rounded size')
	eq(TR.nearestHolder:GetWidth(), rounded, 'and so is the holder')
	local off = P.off(TR.nearestHolder)
	eq(#off, 0, 'whole pixels: ' .. P.report(off))
	eq(#take_errors(), 0, 'no errors')
end)
