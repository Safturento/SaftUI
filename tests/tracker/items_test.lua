-- SaftUI's tracker's quest item layer and the buttons in the rows
-- (SaftUI-Tracker/items.lua, rows.lua's item slot, window.lua's scroll lock): the
-- game's rules for secure buttons (.agents/taint.md rule 6 and 15; design: "Quest
-- item buttons"), held by the stubs: a secure template frame is protected, so in
-- combat its moves, shows, hides and attributes are refused into stub.blocked,
-- and a secure frame can't be made (TW.counts.secure counts the ones made).
--
-- Real: SaftUI-Tracker's files, Core's helpers and theme engine, the quest
-- stubs. The scroll frame is tracker_world.lua's stand-in. Not mimicked: the
-- game's own protection of a frame a secure frame is anchored to, so the layer's
-- independence of the window is checked by its anchors ('no secure frame is
-- a child of, or anchored to, a SaftUI frame that moves').
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q
local T = load_test_file('lib/theme_helpers.lua')
local P = load_test_file('lib/pixels.lua')

local function item_of(id, extra)
	local item = { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 }
	for key, value in pairs(extra or {}) do item[key] = value end
	return item
end

-- Quests with items in one zone, all tracked, each with one objective line;
-- extra[id] adds to a quest's fields, items[id] to its item's.
local function log(ids, extra, items)
	local entries = { Q.header('Elwynn Forest') }
	for _, id in ipairs(ids) do
		local fields = { item = item_of(id, items and items[id]), objectives = { { text = '1/2 Wolves', type = 'monster' } } }
		for key, value in pairs(extra and extra[id] or {}) do fields[key] = value end
		entries[#entries + 1] = Q.quest(id, fields)
	end
	Q.set(entries, ids)
end

-- The game's way: the log changes, the event, the next frame.
local function settle(seconds)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(seconds or 1)
end

local function world(ids, opts)
	opts = opts or {}
	opts.enabling = function() log(ids) end
	local st, TR = RW.world(opts)
	return st, TR
end

local function button(TR, id) return TR:GetItemButton(id) end

-- Every secure frame the tracker made: the layer and the pool.
local function secure_frames(TR)
	local list = { TR.itemLayer }
	for _, b in ipairs(TR.itemButtons or {}) do list[#list + 1] = b end
	return list
end

-- A click as the game delivers it with "cast on key down": the press.
local function use(b) return stub.click(b, 'LeftButton', true) end

local function last_use() return stub.secure_clicks[#stub.secure_clicks] end

local function alpha_of(b) return b:GetAlpha() end

------------------------------------------------------------------ the pure parts

test('the constants, the P3 seam and the pure placement and dimming', function()
	local st, TR = world({ 1 })
	eq(TR.BUTTON_MIN_ALPHA, 0.25, 'BUTTON_MIN_ALPHA')
	eq(TR.DIM_ALPHA, 0.4, 'DIM_ALPHA')
	eq(TR.MOVE_TOLERANCE, 2, 'MOVE_TOLERANCE')
	eq(TR.ITEM_POOL_MAX, 35, 'ITEM_POOL_MAX, the fallback of the log\'s most')
	eq(TR.RANGE_INTERVAL, 0.2, 'RANGE_INTERVAL')
	eq(TR.ItemPoolMax(), TR.MaxQuests(), 'the pool is capped by the log\'s most, read from the game, never a literal')
	eq(TR.MaxQuests(), 40, 'which is 40 on Forever')

	local attributes = TR.ItemAttributes({ link = 'item:6948' })
	eq(attributes.type, 'item', 'P3 as designed: type item')
	eq(attributes.item, 'item:6948', "and the item's link")

	local RowPlace, CombatAlpha = TR.Items.RowPlace, TR.Items.CombatAlpha
	-- (rowTop, rowRight, viewTop, viewBottom, size) -> left, top: y is up.
	local left, top = RowPlace(500, 300, 600, 100, 24)
	eq(left, 276, 'the button sits at the row\'s top right: left is right less the size')
	eq(top, 500, 'at its top')
	left, top = RowPlace(500.4, 300.4, 600, 100, 24)
	eq(left, 276, 'whole: the left')
	eq(top, 500, 'whole: the top')
	eq(RowPlace(nil, 300, 600, 100, 24), nil, 'a gone or collapsed row gives nothing')
	eq(RowPlace(500, nil, 600, 100, 24), nil, 'nor one with no right edge')
	-- The centre must be inside the view: top 500, size 24: centre 488.
	check(RowPlace(500, 300, 600, 488, 24), 'centre on the bottom edge is in')
	eq(RowPlace(500, 300, 600, 489, 24), nil, 'centre just under the view\'s bottom is out')
	check(RowPlace(612, 300, 600, 100, 24), 'centre 600 on the top edge is in')
	eq(RowPlace(613, 300, 600, 100, 24), nil, 'centre above the view\'s top is out')
	-- A rounding of the caller's.
	left, top = RowPlace(500.4, 300.4, 600, 100, 24, function(v) return math.floor(v / 2 + 0.5) * 2 end)
	eq(top, 500, 'the caller\'s rounding (a physical pixel) is used')

	eq(CombatAlpha(100, 100), 1, 'not moved')
	eq(CombatAlpha(100, 102), 1, 'moved 2: still 1')
	eq(CombatAlpha(100, 98), 1, 'moved 2 up: still 1')
	eq(CombatAlpha(100, 103), TR.DIM_ALPHA, 'moved more than 2: dim')
	eq(CombatAlpha(100, 97), TR.DIM_ALPHA, 'moved more than 2 the other way: dim')
	eq(CombatAlpha(100, nil), TR.DIM_ALPHA, 'a gone row: dim')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the layer and the buttons

test('out of combat: the layer and a button per quest with an item, set up by TR.ItemAttributes', function()
	local st, TR = world({ 1, 2 })
	local layer = TR.itemLayer
	check(layer ~= nil, 'the layer was made')
	eq(layer, _G.SaftUITrackerItems, 'named SaftUITrackerItems')
	eq(layer:GetParent(), UIParent, 'on UIParent')
	eq(layer:GetFrameStrata(), 'LOW', 'LOW')
	eq(layer:GetFrameLevel(), 30, 'level 30')
	check(layer:IsProtected(), 'a secure frame')
	eq(layer:GetNumPoints(), 2, 'it fills UIParent')
	check(not layer:IsMouseEnabled(), 'and takes no mouse')
	eq(stub.state(layer).state_drivers['state-visibility'], '[petbattle] hide; show', 'the visibility driver, until Task 12')
	for _, id in ipairs({ 1, 2 }) do
		local b = button(TR, id)
		check(b ~= nil, 'a button for quest ' .. id)
		eq(b:GetParent(), layer, 'a child of the layer')
		check(b:IsProtected(), 'secure')
		eq(b:GetAttribute('type'), 'item', 'type item')
		eq(b:GetAttribute('item'), 'item:' .. (1000 + id), "the quest item's link, not the log index")
		check(b:IsShown(), 'shown')
		eq(b:GetWidth(), 24, 'Button size')
	end
	eq(#TR.itemButtons, 2, 'two in the pool')
	eq(#take_errors(), 0, 'no errors')
end)

test('a click uses the quest item, on the press, with both press and release registered', function()
	local st, TR = world({ 1 })
	local b = button(TR, 1)
	stub.secure_clicks = {}
	use(b)
	eq(#stub.secure_clicks, 1, 'the press used it once')
	eq(last_use().type, 'item', 'by its type')
	eq(last_use().item, 'item:1001', 'and its item')
	stub.click(b, 'LeftButton', false)
	eq(#stub.secure_clicks, 1, 'the release is the template\'s to ignore')
	stub.cast_on_key_down = false
	stub.click(b, 'LeftButton', false)
	eq(#stub.secure_clicks, 2, 'with cast on key down off, the release uses it')
	stub.cast_on_key_down = true
	check(stub.try_click(b, 'RightButton', true) ~= false, 'every mouse button is delivered: AnyUp and AnyDown')
	eq(#take_errors(), 0, 'no errors')
end)

test('buttons sit at their row\'s top right on whole pixels, hidden out of view, collapsed or gone', function()
	local st, TR = world({ 1, 2, 3 })
	for _, id in ipairs({ 1, 2, 3 }) do
		local row, b = RW.quest(TR, id), button(TR, id)
		eq(b:GetTop(), row:GetTop(), id .. ': at its row\'s top')
		eq(b:GetRight(), row:GetRight(), id .. ': and right')
		eq(b:GetLeft(), row:GetRight() - 24, id .. ': Button size wide')
		local point, relativeTo, relativePoint = b:GetPoint(1)
		eq(point .. relativeTo:GetName() .. relativePoint, 'TOPLEFTUIParentBOTTOMLEFT', id .. ': anchored by its top left to UIParent\'s bottom left')
		check(row:GetHeight() >= 24, id .. ': the row is at least Button size tall')
	end
	-- Scrolled out of view: the list is short, the rows are not.
	TR.config.height = 120
	TR:UpdateConfig()
	check(TR.scrollRange > 0, 'the list scrolls')
	local seen = {}
	for _, id in ipairs({ 1, 2, 3 }) do seen[id] = button(TR, id):IsShown() end
	check(seen[1], 'the first is in view')
	check(not seen[3], 'the last is out of view (its centre outside the scroll frame): hidden')
	TR:ScrollTo(TR.scrollRange)
	check(not button(TR, 1):IsShown(), 'scrolled: the first is out now')
	check(button(TR, 3):IsShown(), 'and the last in')
	eq(button(TR, 3):GetTop(), RW.quest(TR, 3):GetTop(), 'at its scrolled row')
	TR:ScrollTo(0)
	TR.config.height = 560
	TR:UpdateConfig()
	-- A collapsed group: its rows are gone.
	TR:ToggleZone('Elwynn Forest')
	for index, b in ipairs(TR.itemButtons) do check(not b:IsShown(), index .. ': hidden with its group') end
	TR:ToggleZone('Elwynn Forest')
	for _, id in ipairs({ 1, 2, 3 }) do check(button(TR, id):IsShown(), id .. ': back') end
	-- A collapsed tracker.
	TR:SetCollapsed(true)
	for index, b in ipairs(TR.itemButtons) do check(not b:IsShown(), index .. ': hidden with the window collapsed') end
	TR:SetCollapsed(false)
	-- A quest that is gone.
	log({ 1, 3 })
	settle()
	check(not button(TR, 2) or not button(TR, 2):IsShown(), 'a quest that left: its button hides')
	eq(#TR.itemButtons, 3, 'the pool keeps it, for the next')
	eq(#take_errors(), 0, 'no errors')
end)

test('the title is narrowed for the button and a spare button is hidden, the pool kept', function()
	local st, TR = world({ 1, 2, 3 })
	local row = RW.quest(TR, 1)
	eq(row.item, 'row', 'the row says its item sits in it')
	log({ 2 })
	settle()
	local shown = 0
	for _, b in ipairs(TR.itemButtons) do if b:IsShown() then shown = shown + 1 end end
	eq(shown, 1, 'one button shows')
	eq(#TR.itemButtons, 3, 'the pool is never freed')
	log({ 4, 5, 6 })
	settle()
	eq(#TR.itemButtons, 3, 'new quests reuse the spare buttons')
	eq(#take_errors(), 0, 'no errors')
end)

test('the pool never passes the log\'s most', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local ids = {}
		for i = 1, 6 do ids[i] = i end
		local st, TR = RW.world({ client = client, enabling = function() log(ids); stub.quests.max = 4 end })
		stub.fire_event('QUEST_LOG_UPDATE')
		RW.later(1)
		eq(TR.ItemPoolMax(), 4, client .. ': the cap is the game\'s')
		eq(#TR.itemButtons, 4, client .. ': four buttons for six quests')
		local plain = 0
		for _, id in ipairs(ids) do
			local row = RW.quest(TR, id)
			if not button(TR, id) then
				plain = plain + 1
				check(row.slot:IsShown(), client .. ': ' .. id .. ' has its item as a plain icon in the row')
			end
		end
		eq(plain, 2, client .. ': two quests with no button')
		stub.quests.max = nil
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ combat

test('no secure button is made, placed, shown, hidden or given an attribute in combat: TW.counts.secure 0, stub.blocked empty', function()
	local st, TR = world({ 1, 2, 3 })
	check(TR.itemLayer ~= nil and #TR.itemButtons == 3, 'out of combat the layer and the buttons were made')
	TW.combat(true)
	TW.count_from_now()
	-- Everything that can change the list in combat.
	log({ 2, 3, 4, 5 }) -- 1 completes and goes; 4 and 5 are new, with items
	settle()
	TR:ToggleZone('Elwynn Forest')
	TR:ToggleZone('Elwynn Forest')
	TR:SetCollapsed(true)
	TR:SetCollapsed(false)
	TR.config.items.size = 32
	TR:UpdateConfig()
	TR.config.items.size = 24
	TR.config.theme = 'thin'
	TR:UpdateConfig()
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 2, true)
	TR:Refresh()
	RW.later(1)
	TW.count_stop()
	eq(TW.counts.secure, 0, 'no secure frame was made in combat')
	eq(#stub.blocked, 0, 'no secure call was even tried: nothing blocked')
	eq(button(TR, 4), nil, 'the new quest has no button yet')
	eq(#TR.itemButtons, 3, 'the pool did not grow')
	TW.combat(false)
	eq(#stub.blocked, 0, 'nor at the end of combat')
	check(button(TR, 4) ~= nil and button(TR, 5) ~= nil, 'combat ends: the two new quests get buttons')
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a button whose row moved more than 2 or went dims to 40% and still uses its quest\'s item; at combat end all go back', function()
	local st, TR = world({ 1, 2, 3 })
	local at = {}
	for _, id in ipairs({ 1, 2, 3 }) do at[id] = { button(TR, id):GetLeft(), button(TR, id):GetTop() } end
	TW.combat(true)
	log({ 2, 3 }) -- the quest above completes and goes
	settle()
	for _, id in ipairs({ 1, 2, 3 }) do
		local b = button(TR, id) or TR.itemButtons[id]
		check(b:IsShown(), id .. ': still shown (a secure button can\'t hide in combat)')
		eq(alpha_of(b), TR.DIM_ALPHA, id .. ': at 40%')
		check(alpha_of(b) >= TR.BUTTON_MIN_ALPHA, id .. ': never below 25%')
	end
	local two = TR.itemButtons[2]
	eq(two:GetLeft(), at[2][1], 'the second stayed where it was (left)')
	eq(two:GetTop(), at[2][2], 'and (top)')
	stub.secure_clicks = {}
	use(two)
	eq(last_use().item, 'item:1002', 'and still uses its own quest\'s item')
	use(TR.itemButtons[1])
	eq(last_use().item, 'item:1001', 'so does the one whose quest left')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	RW.later(1)
	check(not TR.itemButtons[1]:IsShown(), 'the quest that left: its button hides')
	for _, id in ipairs({ 2, 3 }) do
		local b, row = button(TR, id), RW.quest(TR, id)
		eq(alpha_of(b), 1, id .. ': back at 1')
		eq(b:GetTop(), row:GetTop(), id .. ': over its row again')
	end
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('a button whose row did not move stays at full strength in combat, and one that moved by 2 too', function()
	local st, TR = world({ 1, 2 })
	TW.combat(true)
	TR:Refresh()
	for _, id in ipairs({ 1, 2 }) do eq(alpha_of(button(TR, id)), 1, id .. ': untouched') end
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a window that shrinks or moves leaves its buttons where they were, dimmed, and nothing secure is touched', function()
	local st, TR = world({ 1, 2, 3 })
	local old = {}
	for _, id in ipairs({ 1, 2, 3 }) do old[id] = { button(TR, id):GetLeft(), button(TR, id):GetTop() } end
	TW.combat(true)
	-- Max height shrinks: the last rows' centres leave the view (the list can't scroll to them).
	TR.config.height = 120
	TR:UpdateConfig()
	local dimmed = {}
	for _, id in ipairs({ 1, 2, 3 }) do
		local b = button(TR, id)
		eq(b:GetTop(), old[id][2], id .. ': never moved')
		dimmed[id] = alpha_of(b) == TR.DIM_ALPHA
		check(b:IsShown() and alpha_of(b) >= TR.BUTTON_MIN_ALPHA, id .. ': shown and never under 25%')
	end
	check(not dimmed[1], 'the first row is still in view: at full strength')
	check(dimmed[3], 'the last row left the view: dimmed')
	-- The window moves (a profile change): every row moves, every button dims.
	TR.config.height = 560
	TR.config.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -120, y_off = -400 }
	TR:UpdateConfig()
	for _, id in ipairs({ 1, 2, 3 }) do
		eq(button(TR, id):GetTop(), old[id][2], id .. ': never moved')
		eq(alpha_of(button(TR, id)), TR.DIM_ALPHA, id .. ': dimmed')
	end
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	for _, id in ipairs({ 1, 2, 3 }) do
		eq(button(TR, id):GetTop(), RW.quest(TR, id):GetTop(), id .. ': back over its row at combat end')
		eq(alpha_of(button(TR, id)), 1, id .. ': at full strength')
	end
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('a button keeps its row\'s hover while the mouse is on it', function()
	local st, TR = world({ 1 })
	local b, row = button(TR, 1), RW.quest(TR, 1)
	stub.fire_script(b, 'OnEnter', true)
	check(row.hovered, 'the row is hovered')
	stub.fire_script(b, 'OnLeave', true)
	check(not row.hovered, 'and not after')
	eq(#take_errors(), 0, 'no errors')
end)

test('combat starting before a queued refresh', function()
	local st, TR = world({ 1, 2, 3 })
	local old = { button(TR, 3):GetLeft(), button(TR, 3):GetTop() }
	-- QUEST_LOG_UPDATE queues the refresh; combat starts; the quest above completes.
	stub.fire_event('QUEST_LOG_UPDATE')
	TW.combat(true)
	TW.count_from_now()
	log({ 2, 3 })
	stub.time = stub.time + 1
	stub.run_timers()
	TW.count_stop()
	check(RW.quest(TR, 1) == nil, 'the rows were redrawn: the quest that went has no row')
	local three = button(TR, 3)
	eq(three:GetLeft(), old[1], 'the lower button stayed at its old place (left)')
	eq(three:GetTop(), old[2], 'and (top)')
	eq(alpha_of(three), TR.DIM_ALPHA, 'at 40%')
	eq(TW.counts.secure, 0, 'no secure frame made')
	eq(#stub.blocked, 0, 'no secure call')
	local passes = 0
	local refresh = TR.RefreshItems
	TR.RefreshItems = function(self, ...)
		passes = passes + 1
		return refresh(self, ...)
	end
	TW.combat(false)
	eq(passes, 1, 'combat ends: one pass')
	eq(alpha_of(three), 1, 'back at 1')
	eq(three:GetTop(), RW.quest(TR, 3):GetTop(), 'over its row')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('a /reload in combat', function()
	local st, TR = world({ 1, 2 }, { combat = true })
	check(TR.window ~= nil and RW.quest(TR, 1) ~= nil, 'the window and the rows are built')
	eq(TW.counts.secure, 0, 'no secure frame made in combat')
	check(TR.itemLayer == nil and _G.SaftUITrackerItems == nil, 'no layer')
	for _, id in ipairs({ 1, 2 }) do
		local row = RW.quest(TR, id)
		check(row.slot:IsShown(), id .. ': the item shows in its row')
		check(row.slot.icon:IsDesaturated(), id .. ': greyed')
		eq(row.slot.icon:GetAlpha(), 0.4, id .. ': at 40%')
		eq(row.slot.icon:GetTexture(), 134400 + id, id .. ': the quest item\'s icon')
		stub.fire_script(row.slot, 'OnEnter', true)
		local texts = stub.state(GameTooltip).texts
		eq(texts[#texts], 'Its button comes when combat ends.', id .. ': its tooltip')
		stub.fire_script(row.slot, 'OnLeave', true)
	end
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.count_from_now()
	TW.combat(false)
	TW.count_stop()
	check(TR.itemLayer ~= nil, 'combat ends: the layer is made')
	eq(TW.counts.secure, 3, 'once, with its two buttons')
	for _, id in ipairs({ 1, 2 }) do
		local b = button(TR, id)
		eq(b:GetAttribute('item'), 'item:' .. (1000 + id), id .. ': attributes from TR.ItemAttributes')
		check(not RW.quest(TR, id).slot:IsShown(), id .. ': the greyed icon is gone')
	end
	RW.later(2)
	eq(TW.counts.secure, 3, 'and made no more')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('an item that appears in combat shows greyed in its row until combat ends', function()
	local st, TR = world({ 1 })
	TW.combat(true)
	log({ 1, 2 })
	settle()
	local row = RW.quest(TR, 2)
	check(row.slot:IsShown(), 'the item shows in its row')
	check(row.slot.icon:IsDesaturated(), 'greyed')
	eq(row.slot.icon:GetAlpha(), 0.4, 'at 40%')
	check(button(TR, 2) == nil, 'with no button')
	check(not RW.quest(TR, 1).slot:IsShown(), 'the quest with its button shows no greyed icon')
	TW.combat(false)
	check(button(TR, 2) ~= nil, 'combat ends: a button')
	check(not row.slot:IsShown(), 'the greyed icon goes')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('SetButtonItem refuses in combat and changes nothing', function()
	local st, TR = world({ 1 })
	local b = button(TR, 1)
	TW.combat(true)
	eq(TR:SetButtonItem(b, item_of(9)), false, 'refused in combat')
	eq(b:GetAttribute('item'), 'item:1001', 'the attribute is as it was')
	eq(#stub.blocked, 0, 'and the call was never made')
	TW.combat(false)
	eq(TR:SetButtonItem(b, item_of(9)), true, 'out of combat it applies')
	eq(b:GetAttribute('item'), 'item:1009', 'the new item')
	eq(#take_errors(), 0, 'no errors')
end)

test('P3 failed: TR.ItemAttributes giving a macro is what every button gets, and the item attribute is cleared', function()
	local st, TR = world({ 1, 2 })
	TR.ItemAttributes = function(item)
		return { type = 'macro', macrotext = '/use item:' .. item.link:match('item:(%d+)') }
	end
	TR:UpdateConfig()
	for _, id in ipairs({ 1, 2 }) do
		local b = button(TR, id)
		eq(b:GetAttribute('type'), 'macro', id .. ': type macro')
		eq(b:GetAttribute('macrotext'), '/use item:' .. (1000 + id), id .. ': its macro')
		eq(b:GetAttribute('item'), nil, id .. ': the item attribute is cleared')
	end
	TR.ItemAttributes = nil
	eq(#take_errors(), 0, 'no errors')
end)

test('the scroll lock: in combat with row buttons the wheel and bar hold, the bar at 40% with its tooltip; out of combat it scrolls', function()
	local st, TR = world({ 1, 2, 3, 4, 5, 6 })
	TR.config.height = 150
	TR:UpdateConfig()
	check(TR.scrollRange > 0, 'the list scrolls')
	check(not TR:IsScrollLocked(), 'out of combat: not locked')
	TR.config.visibility.scrollbar_hover = false -- the bar always shows, so its alpha is the lock's
	TR:UpdateConfig()
	local bar = TR.scroll.ScrollBar
	eq(bar:GetAlpha(), 1, 'the bar at full strength')
	check(not TR.window.barLock:IsShown(), 'barLock is not there')
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), 40, 'the wheel scrolls out of combat')
	TR:ScrollTo(0)

	TW.combat(true)
	check(TR:IsScrollLocked(), 'in combat with a row button shown: locked')
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), 0, 'the wheel holds')
	stub.fire_script(TR.scroll, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), 0, 'on the scroll frame too')
	bar:SetScrollPercentage(0.5)
	eq(TR:GetScroll(), 0, 'the bar holds')
	eq(bar:GetAlpha(), TR.DIM_ALPHA, 'the bar shows at 40%')
	local lock = TR.window.barLock
	check(lock:IsShown() and lock:IsMouseEnabled(), 'barLock takes the mouse over the bar')
	stub.fire_script(lock, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[1], 'Scrolling is locked', 'its tooltip title')
	eq(texts[2], 'Scrolling waits for the end of combat while quest item buttons sit in the rows.', "and its line")
	stub.fire_script(lock, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'it goes with the mouse')
	TW.combat(false)
	check(not TR:IsScrollLocked(), 'combat ends: unlocked')
	eq(bar:GetAlpha(), 1, 'the bar is back')
	check(not lock:IsShown(), 'barLock goes')
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), 40, 'it scrolls again')

	-- No row button shown in combat (all out of view, or none): the list scrolls.
	TR:UpdateConfig()
	TR.config.items.placement = 'off'
	TR:UpdateConfig()
	TW.combat(true)
	check(not TR:IsScrollLocked(), 'placement Off: nothing to lock for')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the look

test('the look: icon crop, kind action in the tracker\'s pair, cooldown, count, red out of range, the accent in the area', function()
	local items = {
		[1] = { charges = 3, cooldown = { start = 100, duration = 30, enable = 1 }, range = 1 },
		[2] = { charges = 1, range = 1 },
		[3] = { range = 1 },
	}
	local st, TR = RW.world({ enabling = function() log({ 1, 2, 3 }, { [3] = { inArea = true } }, items) end })
	local one, two, three = button(TR, 1), button(TR, 2), button(TR, 3)
	local trim = st.config.profile.misc.icon_trim
	local l, r, t, b = st:IconTexCoords(trim, 24, 24)
	local probe = UIParent:CreateTexture(nil, 'ARTWORK')
	probe:SetTexCoord(l, r, t, b)
	eq(table.concat({ one.icon:GetTexCoord() }, ','), table.concat({ probe:GetTexCoord() }, ','), 'the icon cropped by Icon zoom')
	eq(one.icon:GetTexture(), 134401, 'the quest item\'s texture')
	-- The backdrop: kind action in the tracker's Theme and Background.
	check(one.backdrop ~= nil, 'drawn')
	TR.config.theme = 'thin'
	TR.config.background = 'solid'
	TR:UpdateConfig()
	check(one.backdrop.backdropInfo ~= nil, 'Thin draws a backdrop in the tracker\'s own pair')
	-- The hover: a texture in the HIGHLIGHT layer in the accent.
	eq(one.hover:GetDrawLayer(), 'HIGHLIGHT', 'the hover is in the HIGHLIGHT layer')
	-- Cooldown: from GetQuestLogSpecialItemCooldown.
	local cd = stub.state(one.cooldown)
	eq(cd.cooldown_start, 100, 'the cooldown starts')
	eq(cd.cooldown_duration, 30, 'and lasts')
	eq(stub.state(two.cooldown).cooldown_duration, nil, 'a quest with no cooldown sets none')
	-- Count: Pixel font, bottom right, only with charges to count.
	eq(one.count:GetText(), '3', 'the count')
	eq(one.count:GetFontObject(), st:GetFont('pixel'), 'in the Pixel font')
	local point, rel, relPoint = one.count:GetPoint(1)
	eq(point .. relPoint, 'BOTTOMRIGHTBOTTOMRIGHT', 'at the bottom right')
	check(not two.count:IsShown(), 'one charge shows no count')
	-- Range: read every RANGE_INTERVAL while a button shows.
	local watcher = TR.itemWatcher
	check(watcher:GetScript('OnUpdate') ~= nil, 'the range timer runs while a button shows')
	stub.quests.log[3].item.range = 0 -- quest 2 walks out of range (its entry is log[3]: the header is first)
	stub.fire_script(watcher, 'OnUpdate', 0.1)
	local red = ('%.2f %.2f %.2f'):format(st.config.profile.colors.text.red:GetRGB())
	local function icon_color(b) return ('%.2f %.2f %.2f'):format(b.icon:GetVertexColor()) end
	check(icon_color(two) ~= red, 'not read before the interval')
	stub.fire_script(watcher, 'OnUpdate', 0.15)
	eq(icon_color(two), red, 'out of range: Text > Red')
	eq(RW.color(two.count), red, 'the count too')
	check(icon_color(one) ~= red, 'in range: not red')
	stub.quests.log[3].item.range = 1
	stub.fire_script(watcher, 'OnUpdate', 0.3)
	check(icon_color(two) ~= red, 'back in range: no longer red')
	TR.config.items.range = false
	TR:UpdateConfig()
	stub.quests.log[3].item.range = 0
	stub.fire_script(watcher, 'OnUpdate', 0.3)
	check(icon_color(two) ~= red, 'Out of range in red off: never red')
	TR.config.items.range = true
	-- The accent border inside the quest's area.
	local accent = ('%.2f,%.2f,%.2f'):format(st.config.profile.colors.button.blue:GetRGB())
	local border = ('%.2f,%.2f,%.2f'):format(three.backdrop:GetBackdropBorderColor())
	eq(border, accent, 'inside the quest\'s area: the border in the accent')
	local other = ('%.2f,%.2f,%.2f'):format(one.backdrop:GetBackdropBorderColor())
	check(other ~= accent, 'a quest with no area: not')
	stub.quests.log[4].inArea = false
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 3, false)
	border = ('%.2f,%.2f,%.2f'):format(three.backdrop:GetBackdropBorderColor())
	check(border ~= accent, 'PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED: out of the area, the accent goes')
	-- The switches.
	TR.config.items.count = false
	TR.config.items.cooldown = false
	TR:UpdateConfig()
	check(not one.count:IsShown(), 'Count off: no count')
	eq(stub.state(one.cooldown).cooldown_duration, nil, 'Cooldown off: none is drawn')
	eq(#take_errors(), 0, 'no errors')
end)

test('a cooldown that ends or starts is drawn from BAG_UPDATE_COOLDOWN with no refresh', function()
	local st, TR = world({ 1 })
	local b = button(TR, 1)
	eq(stub.state(b.cooldown).cooldown_duration, nil, 'none at first')
	stub.quests.log[2].item.cooldown = { start = 50, duration = 20, enable = 1 }
	local refreshes = 0
	local refresh = TR.Refresh
	TR.Refresh = function(self, ...) refreshes = refreshes + 1; return refresh(self, ...) end
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	eq(stub.state(b.cooldown).cooldown_duration, 20, 'the cooldown is drawn')
	eq(refreshes, 0, 'by TR:RefreshCooldowns, with no refresh')
	TW.combat(true)
	stub.quests.log[2].item.cooldown = { start = 70, duration = 10, enable = 1 }
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	eq(stub.state(b.cooldown).cooldown_start, 70, 'in combat too: a cooldown is drawing')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	TR.Refresh = refresh
	eq(#take_errors(), 0, 'no errors')
end)

test('the button\'s tooltip: the game\'s quest item tooltip, with the quest\'s title while dimmed, obeying Tooltips', function()
	local st, TR = world({ 1, 2 })
	local b = button(TR, 1)
	stub.fire_script(b, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[1], 'quest item 2', 'the game\'s tooltip for the quest\'s log index (the header is the first entry)')
	eq(#texts, 1, 'and no more while at full strength')
	check(GameTooltip:IsShown(), 'shown')
	stub.fire_script(b, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'hidden with the mouse')
	TW.combat(true)
	log({ 2 })
	settle()
	stub.fire_script(b, 'OnEnter', true)
	texts = stub.state(GameTooltip).texts
	eq(texts[#texts], 'Quest 1', 'dimmed: the quest\'s title names it')
	stub.fire_script(b, 'OnLeave', true)
	TW.combat(false)
	TR.config.quests.tooltips = false
	stub.fire_script(button(TR, 2), 'OnEnter', true)
	check(not GameTooltip:IsShown(), 'Tooltips off: none')
	eq(#take_errors(), 0, 'no errors')
end)

test('the greyed icon\'s tooltip obeys Tooltips too', function()
	local st, TR = world({ 1 }, { combat = true })
	TR.config.quests.tooltips = false
	stub.fire_script(RW.quest(TR, 1).slot, 'OnEnter', true)
	check(not GameTooltip:IsShown(), 'Tooltips off: none')
	eq(#take_errors(), 0, 'no errors')
end)

test('Item buttons Off: the item shows in the row as a plain icon, no secure frame', function()
	local st, TR = RW.world({ enabling = function() log({ 1 }) end })
	TR.config.items.placement = 'off'
	TW.count_from_now()
	TR:UpdateConfig()
	settle()
	TW.count_stop()
	local row = RW.quest(TR, 1)
	check(row.slot:IsShown(), 'the icon shows in the row')
	check(not row.slot.icon:IsDesaturated(), 'plain')
	eq(row.slot.icon:GetAlpha(), 1, 'at full strength')
	check(not TR:ItemsToShow(), 'ItemsToShow says no')
	local b = TR.itemButtons and TR.itemButtons[1]
	check(not b or not b:IsShown(), 'no button shows')
	TR.config.items.placement = 'row'
	TR:UpdateConfig()
	check(TR:ItemsToShow(), 'In the row: yes, with a quest with an item')
	log({})
	settle()
	check(not TR:ItemsToShow(), 'and no: with no quest with an item')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ independence

test('no secure frame is a child of, or anchored to, a SaftUI frame that moves: only the layer and UIParent', function()
	local st, TR = world({ 1, 2, 3 })
	local movers = { TR.window, TR.holder, TR.scroll, TR.content, TR.header }
	for _, kind in ipairs({ 'zone', 'quest', 'popup', 'empty' }) do
		for _, row in ipairs(TR.pools[kind].rows) do movers[#movers + 1] = row end
	end
	local moving = {}
	for _, frame in ipairs(movers) do moving[frame] = true end
	for _, frame in ipairs(secure_frames(TR)) do
		local parent = frame:GetParent()
		check(not moving[parent], 'a secure frame\'s parent is not a moving frame')
		check(frame == TR.itemLayer and parent == UIParent or parent == TR.itemLayer, 'the layer is on UIParent, the buttons on the layer')
		for i = 1, frame:GetNumPoints() do
			local _, relativeTo = frame:GetPoint(i)
			check(relativeTo == UIParent, 'anchored to UIParent only')
		end
	end
	check(not TR.window:IsProtected() and not TR.scroll:IsProtected(), 'the window and the list are not protected')
	for _, row in ipairs(TR.pools.quest.rows) do check(not row:IsProtected(), 'a row is not protected') end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ whole pixels and the switch

test('whole pixels with buttons in rows, under the three looks and size noise', function()
	local checked = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				for _, size in ipairs({ 16, 24, 30, 40 }) do
					local where = ('%s, %s, noise %g, size %d'):format(client, theme, noise, size)
					local st, TR = RW.world({ client = client, enabling = function()
						log({ 1, 2, 3 }, nil, { [1] = { charges = 4, cooldown = { start = 1, duration = 9, enable = 1 } } })
					end })
					T.theme(theme, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
					TR.config.items.size = size
					stub.size_noise = noise
					TR:UpdateConfig()
					TR:Refresh()
					local off = P.off(TR.window)
					eq(#off, 0, where .. ' (the window): ' .. P.report(off))
					off = P.off(TR.itemLayer)
					eq(#off, 0, where .. ' (the layer): ' .. P.report(off))
					TR:Refresh()
					off = P.off(TR.itemLayer)
					eq(#off, 0, where .. ' (again): ' .. P.report(off))
					stub.size_noise = 0
					checked = checked + 1
				end
			end
		end
	end
	eq(checked, 2 * 3 * 3 * 4, 'every combination ran')
	eq(#take_errors(), 0, 'no errors')
end)

test('off: no secure frame exists, nothing runs', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = TW.world({ client = client, enabling = function() log({ 1, 2 }) end })
		eq(TW.counts.secure, 0, client .. ': no secure frame made')
		eq(TR.itemLayer, nil, client .. ': no layer')
		eq(_G.SaftUITrackerItems, nil, client .. ': none by name')
		eq(TR.itemButtons, nil, client .. ': no pool')
		eq(TR:RefreshItems(), nil, client .. ': RefreshItems does nothing')
		eq(TR:IsScrollLocked(), false, client .. ': never locked')
		eq(TR:ItemsToShow(), false, client .. ': no items to show')
		TW.combat(true)
		TW.combat(false)
		eq(TW.counts.secure, 0, client .. ': still none after combat')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)
