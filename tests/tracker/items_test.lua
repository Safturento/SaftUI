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

-- A mouse click as the game delivers it to an addon's secure button: the press,
-- then the release, each one OnClick(button, down); the template acts on one of
-- them by ActionButtonUseKeyDown (SecureActionButton_OnClick, which an addon's
-- button calls without isKeyPress or isSecureAction).
local function use(b)
	stub.click(b, 'LeftButton', true)
	return stub.click(b, 'LeftButton', false)
end

-- Every region and frame under a frame, to see that nothing was made.
local function count_parts(frame)
	local n = 1
	for _, region in ipairs({ frame:GetRegions() }) do n = n + 1 end
	for _, child in ipairs({ frame:GetChildren() }) do n = n + count_parts(child) end
	return n
end

local function last_use() return stub.secure_clicks[#stub.secure_clicks] end

local function alpha_of(b) return b:GetAlpha() end

------------------------------------------------------------------ the pure parts

test('the constants, the P3 seam and the pure placement and dimming', function()
	local st, TR = world({ 1 })
	eq(TR.BUTTON_MIN_ALPHA, 0.25, 'BUTTON_MIN_ALPHA')
	eq(TR.DIM_ALPHA, 0.4, 'DIM_ALPHA')
	eq(TR.MOVE_TOLERANCE, 2, 'MOVE_TOLERANCE')
	eq(TR.ITEM_POOL_MAX, nil, 'ITEM_POOL_MAX is gone: the cap is the log\'s most, read from the game')
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

test('a click uses the quest item once, on the press or the release as ActionButtonUseKeyDown says: it registers AnyUp and AnyDown', function()
	local st, TR = world({ 1 })
	local b = button(TR, 1)
	for _, key_down in ipairs({ true, false }) do
		stub.cast_on_key_down = key_down
		stub.secure_clicks = {}
		use(b)
		eq(#stub.secure_clicks, 1, 'cast on key down ' .. tostring(key_down) .. ': one click, one use')
		eq(stub.secure_clicks[1].down, key_down, 'on the ' .. (key_down and 'press' or 'release'))
		eq(stub.secure_clicks[1].type, 'item', 'by its type')
		eq(stub.secure_clicks[1].item, 'item:1001', 'and its item')
		-- Each half alone is delivered too, or the setting could not be honored.
		stub.secure_clicks = {}
		stub.click(b, 'LeftButton', true)
		stub.click(b, 'LeftButton', false)
		eq(#stub.secure_clicks, 1, 'a second click is a second use, not two')
	end
	stub.cast_on_key_down = true
	check(stub.try_click(b, 'RightButton', true) ~= false and stub.try_click(b, 'RightButton', false) ~= false, 'every mouse button, both halves, is delivered')
	-- A key binding's click (Task 10's nearest button) follows the setting the same way.
	stub.secure_clicks = {}
	stub.press_key(b, true)
	stub.press_key(b, false)
	eq(#stub.secure_clicks, 1, 'a key press uses it once')
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
	-- (the game starts lockdown after PLAYER_REGEN_DISABLED's handlers, so the waiting
	-- refresh has already run before it; the harness starts it first, so that
	-- refresh ran in lockdown.) Then the quest above completes, and the game says so.
	log({ 2, 3 })
	stub.fire_event('QUEST_LOG_UPDATE')
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
	local accent = ('%.2f,%.2f,%.2f'):format(st.config.profile.theme.accent:GetRGB())
	local border = ('%.2f,%.2f,%.2f'):format(three.backdrop:GetBackdropBorderColor())
	eq(border, accent, 'inside the quest\'s area: the border in the accent')
	do -- a non-default accent reaches it on 'accent'
		local c = st.config.profile.theme.accent
		c:SetRGB(0.9, 0.1, 0.2)
		TR:OnColorsChanged('accent')
		eq(('%.2f,%.2f,%.2f'):format(three.backdrop:GetBackdropBorderColor()), '0.90,0.10,0.20', 'the border follows the accent')
		c:SetRGB(0, 0.68, 0.94)
		TR:OnColorsChanged('accent')
	end
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
	RW.later(1) -- (a quiet gap: the event draws at once)
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

------------------------------------------------------------------ fix round 1

test('under the Blizzard theme nothing is made or anchored on a secure button in combat: the quest-area border, cooldowns and dimming only change what exists', function()
	local st, TR = RW.world({ enabling = function()
		log({ 1, 2 }, { [2] = { inArea = true } }, { [1] = { charges = 2, cooldown = { start = 5, duration = 9, enable = 1 } } })
	end })
	T.theme('blizzard', function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	local one, two = button(TR, 1), button(TR, 2)
	local before = count_parts(TR.itemLayer)
	TW.combat(true)
	TW.count_from_now()
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 1, true)
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 2, false)
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 2, true)
	stub.quests.log[2].item.cooldown = { start = 7, duration = 3, enable = 1 }
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	log({ 2 }, { [2] = { inArea = true } })
	settle()
	TR:ColorItems()
	TW.count_stop()
	eq(count_parts(TR.itemLayer), before, 'no region or frame was made under the layer')
	eq(TW.counts.frames, 0, 'and no frame anywhere')
	eq(#stub.blocked, 0, 'nothing was refused: no region of a secure button was moved, sized or anchored')
	eq(alpha_of(one), TR.DIM_ALPHA, 'the button whose quest left dims')
	TW.combat(false)
	eq(#stub.blocked, 0, 'nor at the end')
	eq(#take_errors(), 0, 'no errors')
end)

test('the quest-area border is built when the button is made, out of combat, on a frame that is not the button', function()
	local st, TR = RW.world({ enabling = function() log({ 1 }) end })
	T.theme('blizzard', function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	local b = button(TR, 1)
	local own_before = count_parts(TR.itemLayer)
	TW.combat(true)
	stub.fire_event('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED', 1, true)
	eq(count_parts(TR.itemLayer), own_before, 'the first border in combat makes nothing')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('a change of SaftUI\'s theme restyles the buttons while the tracker follows it: the icon\'s inset, the backdrop, whole pixels', function()
	local st, TR = world({ 1, 2 })
	for _, name in ipairs({ 'blizzard', 'thin', 'thick', 'blizzard' }) do
		T.theme(name, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
		local inset = st:ThemeInset(TR.config.theme, TR.config.background, 'action') or 0
		for _, id in ipairs({ 1, 2 }) do
			local b = button(TR, id)
			local point, _, _, x, y = b.icon:GetPoint(1)
			eq(x, inset, name .. ': the icon\'s inset follows the theme')
			eq(y, -inset, name .. ': and its top')
		end
		local off = P.off(TR.itemLayer)
		eq(#off, 0, name .. ': ' .. P.report(off))
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a change of Button size restyles built buttons and keeps them at their rows\' top right', function()
	local st, TR = world({ 1, 2 })
	TR.config.items.size = 34
	TR:UpdateConfig()
	for _, id in ipairs({ 1, 2 }) do
		local b, row = button(TR, id), RW.quest(TR, id)
		eq(b:GetWidth(), 34, id .. ': the new size')
		eq(b:GetRight(), row:GetRight(), id .. ': at its row\'s right')
		eq(b:GetTop(), row:GetTop(), id .. ': and top')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('the buttons follow the window when the screen or the UI scale changes, and during an edit mode drag; in combat they dim', function()
	local st, TR = world({ 1, 2 })
	local function follows(where)
		for _, id in ipairs({ 1, 2 }) do
			-- (to the physical pixel: the screen's pixel is not a UI unit at these sizes)
			check(math.abs(button(TR, id):GetRight() - RW.quest(TR, id):GetRight()) <= 1, where .. ': ' .. id .. ' right')
			check(math.abs(button(TR, id):GetTop() - RW.quest(TR, id):GetTop()) <= 1, where .. ': ' .. id .. ' top')
		end
	end
	follows('at first')
	-- The screen gets smaller: the window hangs from UIParent's top right, the buttons from its bottom left.
	stub.screen_width, stub.screen_height = 1280, 1024
	stub.fire_script(TR.itemWatcher, 'OnSizeChanged', 1280, 1024)
	follows('a smaller screen')
	-- An edit mode drag: the mover sets the holder's point every frame.
	TR.holder:ClearAllPoints()
	TR.holder:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -200, -300)
	follows('a drag')
	-- The drop: the mover's apply.
	TR.config.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -60, y_off = -100 }
	TR:ApplyHolder()
	follows('a drop')
	-- In combat the window moving only dims.
	TW.combat(true)
	TR.holder:ClearAllPoints()
	TR.holder:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -10, -20)
	stub.fire_script(TR.itemWatcher, 'OnSizeChanged', 1280, 1024)
	for _, id in ipairs({ 1, 2 }) do eq(alpha_of(button(TR, id)), TR.DIM_ALPHA, id .. ': dimmed in combat') end
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('the scroll lock needs a button shown in a row, not the placement', function()
	local st, TR = world({ 1, 2 })
	TW.combat(true)
	check(TR:IsScrollLocked(), 'a button shown: locked')
	TR.config.items.placement = 'off' -- a profile change in combat: the buttons stay shown
	check(TR:IsScrollLocked(), 'still locked while they sit there')
	TW.combat(false)
	TR.config.items.placement = 'row'
	TR:UpdateConfig()
	TR:ToggleZone('Elwynn Forest') -- every button hidden
	TW.combat(true)
	check(not TR:IsScrollLocked(), 'every button hidden: nothing to lock for')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('a window that is hidden hides the buttons', function()
	local st, TR = world({ 1, 2 })
	TR.window:Hide()
	TR:PlaceItems()
	for _, id in ipairs({ 1, 2 }) do check(not button(TR, id):IsShown(), id .. ': hidden with the window') end
	TR.window:Show()
	TR:PlaceItems()
	for _, id in ipairs({ 1, 2 }) do check(button(TR, id):IsShown(), id .. ': back') end
end)

test('an item that changes in combat: the old button dims, the row shows the new item greyed; at combat end it is right', function()
	local st, TR = world({ 1 })
	TW.combat(true)
	stub.quests.log[2].item.link = 'item:7777'
	stub.quests.log[2].item.texture = 777
	settle()
	local b, row = button(TR, 1), RW.quest(TR, 1)
	eq(b:GetAttribute('item'), 'item:1001', 'the button still uses the old item')
	eq(alpha_of(b), TR.DIM_ALPHA, 'so it dims')
	check(row.slot:IsShown() and row.slot.icon:IsDesaturated(), 'and the row shows the new item greyed')
	eq(row.slot.icon:GetTexture(), 777, 'the new one')
	TW.combat(false)
	eq(b:GetAttribute('item'), 'item:7777', 'the new item')
	eq(alpha_of(b), 1, 'full strength')
	check(not row.slot:IsShown(), 'no greyed icon')
	eq(#take_errors(), 0, 'no errors')
end)

test('a displaced button leaves the rows under it with no greyed icon of their own; a quest with a button shown shows none', function()
	local st, TR = world({ 1, 2, 3 })
	TW.combat(true)
	log({ 2, 3 })
	settle()
	for _, id in ipairs({ 2, 3 }) do
		check(not RW.quest(TR, id).slot:IsShown(), id .. ': its own button exists, so no greyed icon (it sits dimmed elsewhere)')
	end
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('a greyed icon is only for an item whose button will come: none for an item with no link or past the pool\'s cap', function()
	local ids = { 1, 2, 3 }
	local st, TR = RW.world({ enabling = function()
		log(ids, nil, { [3] = { link = false } })
		stub.quests.log[4].item.link = nil
		stub.quests.max = 2
	end })
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	TW.combat(true)
	settle()
	local rows = { RW.quest(TR, 1), RW.quest(TR, 2), RW.quest(TR, 3) }
	check(not rows[1].slot:IsShown() and not rows[2].slot:IsShown(), 'the two with buttons show none')
	check(rows[3].slot:IsShown() and not rows[3].slot.icon:IsDesaturated(), 'one with no link and no room: a plain icon, never "its button comes"')
	TW.combat(false)
	stub.quests.max = nil
end)

test('the dimmed button\'s tooltip: the item and the quest\'s title; the dimming is cleared at combat end', function()
	local st, TR = world({ 1, 2 })
	TW.combat(true)
	log({ 2 })
	settle()
	local b = button(TR, 2)
	stub.fire_script(b, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[1], 'quest item 2', 'the game\'s item tooltip')
	eq(texts[2], 'Quest 2', 'and the quest\'s title')
	stub.fire_script(b, 'OnLeave', true)
	TW.combat(false)
	eq(b.dimmed, false, 'not dimmed after')
	stub.fire_script(b, 'OnEnter', true)
	eq(#stub.state(GameTooltip).texts, 1, 'the title line is gone')
	stub.fire_script(b, 'OnLeave', true)
	eq(#take_errors(), 0, 'no errors')
end)

test('a count that changes in combat is drawn for the same item; a cooldown waiting for the item\'s effect dims the icon and draws no swipe', function()
	local st, TR = RW.world({ enabling = function()
		log({ 1, 2 }, nil, { [1] = { charges = 3 }, [2] = { cooldown = { start = 5, duration = 9, enable = 0 } } })
	end })
	local one, two = button(TR, 1), button(TR, 2)
	eq(one.count:GetText(), '3', 'a count')
	eq(stub.state(two.cooldown).cooldown_duration, nil, 'enable 0: no swipe')
	eq(('%.1f'):format(two.icon:GetVertexColor()), '0.4', 'and the icon at 0.4')
	TW.combat(true)
	stub.quests.log[2].item.charges = 5
	settle()
	eq(one.count:GetText(), '5', 'drawn in combat')
	TW.combat(false)
end)

test('SetItemAlpha floors at BUTTON_MIN_ALPHA', function()
	local st, TR = world({ 1 })
	local b = button(TR, 1)
	TR:SetItemAlpha(b, 0.1)
	eq(b:GetAlpha(), TR.BUTTON_MIN_ALPHA, 'never below 25%')
	TR:SetItemAlpha(b, 0)
	eq(b:GetAlpha(), TR.BUTTON_MIN_ALPHA, 'not even 0')
	TR:SetItemAlpha(b, 1)
	eq(b:GetAlpha(), 1, 'and 1 is 1')
end)

test('the slot takes the row\'s clicks in Off and greyed: a left click focuses or maps, the menu opens; its icon is cropped like the button\'s', function()
	local st, TR = world({ 1 }, { combat = true })
	local row = RW.quest(TR, 1)
	local seen = {}
	TR.OnQuestClick = function(_, r, mouse) seen[#seen + 1] = mouse; check(r == row, 'the row') end
	stub.click(row.slot, 'LeftButton')
	stub.click(row.slot, 'RightButton')
	eq(table.concat(seen, ','), 'LeftButton,RightButton', 'both buttons reach the row\'s handler')
	local trim = st.config.profile.misc.icon_trim
	local probe = UIParent:CreateTexture(nil, 'ARTWORK')
	probe:SetTexCoord(st:IconTexCoords(trim, 24, 24))
	eq(table.concat({ row.slot.icon:GetTexCoord() }, ','), table.concat({ probe:GetTexCoord() }, ','), 'the slot\'s icon is cropped by Icon zoom')
	TW.combat(false)
end)

test('a scroll event runs the placement pass only: no attributes told, no style, no look resolved, no border drawn, no setter when nothing moved', function()
	local st, TR = world({ 1, 2, 3 })
	TR.config.height = 150
	TR:UpdateConfig()
	TR:ScrollTo(40)
	TR:ScrollTo(0)
	local calls = { attributes = 0, resolve = 0, border = 0, backdrop = 0, item = 0 }
	local attributes, resolve, border, backdrop = TR.ItemAttributes, st.ResolveTheme, st.SetBorderColor, st.SetBackdrop
	TR.ItemAttributes = function(...) calls.attributes = calls.attributes + 1; return attributes(...) end
	st.ResolveTheme = function(...) calls.resolve = calls.resolve + 1; return resolve(...) end
	st.SetBorderColor = function(...) calls.border = calls.border + 1; return border(...) end
	st.SetBackdrop = function(...) calls.backdrop = calls.backdrop + 1; return backdrop(...) end
	local counter = RW.calls()
	for i = 1, 20 do TR:PlaceItems() end
	counter.stop()
	TR.ItemAttributes, st.ResolveTheme, st.SetBorderColor, st.SetBackdrop = attributes, resolve, border, backdrop
	eq(calls.attributes + calls.resolve + calls.border + calls.backdrop, 0, 'none of the refresh\'s work')
	eq(counter.total, 0, 'and no setter when nothing moved')
	-- A refresh that changed nothing draws no border and tells no button anything either.
	counter = RW.calls()
	calls.attributes, calls.border = 0, 0
	TR.ItemAttributes = function(...) calls.attributes = calls.attributes + 1; return attributes(...) end
	st.SetBorderColor = function(...) calls.border = calls.border + 1; return border(...) end
	TR:Refresh() -- (a new seam function is told once)
	calls.attributes, calls.border = 0, 0
	TR:Refresh()
	counter.stop()
	TR.ItemAttributes, st.SetBorderColor = attributes, border
	eq(calls.attributes, 0, 'a refresh that changed nothing tells no button its item again')
	eq(calls.border, 0, 'and draws no border')
end)

test('combat starting with a refresh waiting, in the game\'s order: lockdown begins after PLAYER_REGEN_DISABLED, the lock is drawn once it has', function()
	local st, TR = world({ 1 })
	TR.config.visibility.scrollbar_hover = false
	TR:UpdateConfig()
	log({ 1, 2 })
	stub.fire_event('QUEST_LOG_UPDATE') -- a refresh is waiting
	stub.fire_event('PLAYER_REGEN_DISABLED') -- the handlers run out of lockdown
	check(button(TR, 2) ~= nil, 'the waiting refresh ran then: the new quest got its button')
	stub.in_combat = true -- and now lockdown begins
	stub.run_timers()
	RW.later(1)
	check(TR:IsScrollLocked(), 'locked')
	check(TR.window.barLock:IsShown(), 'barLock shows')
	eq(TR.scroll.ScrollBar:GetAlpha(), TR.DIM_ALPHA, 'the bar at 40%')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('under the Blizzard theme the ring\'s holder is over the cooldown and under the count, on purpose', function()
	local st, TR = RW.world({ enabling = function() log({ 1 }) end })
	T.theme('blizzard', function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	local b = button(TR, 1)
	local cooldown, count = b.cooldown:GetFrameLevel(), b.count:GetParent():GetFrameLevel()
	local holder
	for _, child in ipairs({ b.backdrop:GetChildren() }) do holder = child end
	check(holder ~= nil, 'the ring has a holder frame')
	check(cooldown < holder:GetFrameLevel(), 'the ring is over the swipe')
	check(holder:GetFrameLevel() < count, 'and the count over the ring')
end)

test('a drag of the holder moves the buttons with it every frame, with no edit mode event', function()
	local st, TR = world({ 1 })
	TR.holder:ClearAllPoints()
	TR.holder:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -240, -330)
	check(math.abs(button(TR, 1):GetRight() - RW.quest(TR, 1):GetRight()) <= 1, 'the button is at its row at once')
	check(math.abs(button(TR, 1):GetTop() - RW.quest(TR, 1):GetTop()) <= 1, 'and its top')
end)

test('the stubs refuse the ScriptRegion functions on a region of a secure frame in combat too', function()
	local b = CreateFrame('Button', nil, UIParent, 'SecureActionButtonTemplate')
	local t = b:CreateTexture(nil, 'ARTWORK')
	stub.in_combat = true
	t:EnableMouse(true)
	t:SetParent(UIParent)
	stub.in_combat = false
	eq(#stub.blocked, 2, 'EnableMouse and SetParent on the region are refused')
end)

------------------------------------------------------------------ the column beside the tracker (Task 9)

-- A world with quests 1..n with items and Item buttons set to Beside the tracker.
local function beside_world(ids, setup)
	local st, TR = world(ids)
	TR.config.items.placement = 'beside'
	if setup then setup(TR) end
	TR:UpdateConfig()
	settle()
	return st, TR
end

local LEFT_SIDE = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -60, y_off = -100 }
local RIGHT_SIDE = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 60, y_off = -100 }

test('the pure column: Side, the 4 gap on the nearer side, 2 under an overlap, nil out of view, numbers 1 to n', function()
	local st, TR = world({ 1 })
	local Side, Column = TR.Items.Side, TR.Items.Column
	eq(Side(900, 500), 'left', 'the holder right of the screen\'s middle: the column on the left')
	eq(Side(100, 500), 'right', 'left of it: on the right')
	eq(Side(500, 500), 'right', 'on it: the right')
	eq(TR.LAYOUT.COLUMN_GAP, 4, 'the gap')
	eq(TR.LAYOUT.COLUMN_STACK, 2, 'the stack gap')

	-- (entries, size, side, windowLeft, windowRight, viewTop, viewBottom); y is up.
	local places = Column({ { top = 500 }, { top = 400 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[1].left, 972, 'left: window left less 4 less the size')
	eq(places[1].top, 500, 'level with its title')
	eq(places[1].number, 1, 'number 1')
	eq(places[2].top, 400, 'the second level with its title')
	eq(places[2].number, 2, 'number 2')
	places = Column({ { top = 500 } }, 24, 'right', 1000, 1250, 600, 100)
	eq(places[1].left, 1254, 'right: the window\'s right and 4')

	places = Column({ { top = 500 }, { top = 490 }, { top = 489 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[1].top, 500, 'the first stays')
	eq(places[2].top, 474, 'an overlap sits 2 under the one above (its bottom 476, less 2)')
	eq(places[3].top, 448, 'and so does the next, under the moved one')
	places = Column({ { top = 500 }, { top = 476 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[2].top, 474, 'one that just touches the one above keeps 2 px from it')
	places = Column({ { top = 500 }, { top = 475 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[2].top, 474, 'and one 1 px from it')
	places = Column({ { top = 500 }, { top = 474 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[2].top, 474, 'one exactly 2 px from it stays')
	places = Column({ { top = 500 }, { top = 470 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[2].top, 470, 'and one clear of it')

	-- Out of view: the title's centre-of-button outside the scroll view. The number is kept.
	places = Column({ { top = 700 }, { top = 500 }, { top = nil }, { top = 20 } }, 24, 'left', 1000, 1250, 600, 100)
	eq(places[1], nil, 'above the view: none')
	eq(places[2].number, 2, 'the second is number 2 though the first is out of view')
	eq(places[2].top, 500, 'and the first, out of view, does not push it')
	eq(places[3], nil, 'no title (collapsed or gone): none')
	eq(places[4], nil, 'below the view: none')

	-- A stack that runs past the view's bottom hides the buttons that do not fit.
	places = Column({ { top = 150 }, { top = 140 }, { top = 130 } }, 40, 'left', 1000, 1250, 200, 100)
	eq(places[1].top, 150, 'the first fits')
	eq(places[2], nil, 'the second, stacked to 108, has its centre under the view: none')
	eq(places[3], nil, 'and so has the third')
	-- The side's test: a holder straddling the middle.
	eq(Side(500.5, 500), 'left', 'just right of the middle: left')
	eq(Side(499.5, 500), 'right', 'just left of it: right')

	-- Whole pixels.
	places = Column({ { top = 500.4 } }, 24, 'left', 1000.4, 1250.4, 600, 100, function(v) return math.floor(v / 2 + 0.5) * 2 end)
	eq(places[1].top, 500, 'the caller\'s rounding on the top')
	eq(places[1].left, 972, 'and the left')
	eq(#take_errors(), 0, 'no errors')
end)

test('the column is 4 outside the window on the side nearer the screen\'s middle, each button level with its title', function()
	local st, TR = beside_world({ 1, 2, 3 }, function(TR) TR.config.position = LEFT_SIDE end)
	eq(TR.Items.Side(TR.holder:GetCenter(), UIParent:GetCenter()), 'left', 'the tracker on the right half: the column on its left')
	eq(TR:ColumnWidth(), 24, 'the column is Button size wide')
	for _, id in ipairs({ 1, 2, 3 }) do
		local b, row = button(TR, id), RW.quest(TR, id)
		check(b ~= nil and b:IsShown(), id .. ': a button')
		eq(row.item, 'beside', id .. ': the row says its item is beside')
		check(not row.slot:IsShown(), id .. ': no slot icon in the row')
		eq(b:GetRight(), TR.window:GetLeft() - 4, id .. ': its right edge 4 outside the window')
		eq(b:GetLeft(), TR.window:GetLeft() - 4 - 24, id .. ': Button size wide')
		eq(b:GetTop(), row:GetTop(), id .. ': level with its title')
		eq(b:GetParent(), TR.itemLayer, id .. ': a child of the layer')
		eq(b:GetNumPoints(), 1, id .. ': one point')
		local _, relativeTo = b:GetPoint(1)
		eq(relativeTo, UIParent, id .. ': anchored to UIParent only')
		eq(b:GetAttribute('item'), 'item:' .. (1000 + id), id .. ': its quest\'s item')
	end
	TR.config.position = RIGHT_SIDE
	TR:UpdateConfig()
	eq(TR.Items.Side(TR.holder:GetCenter(), UIParent:GetCenter()), 'right', 'on the left half: the column on the right')
	for _, id in ipairs({ 1, 2, 3 }) do
		eq(button(TR, id):GetLeft(), TR.window:GetRight() + 4, id .. ': its left edge 4 outside the window\'s right')
		eq(button(TR, id):GetTop(), RW.quest(TR, id):GetTop(), id .. ': level with its title')
	end
	-- The tracker's own width and Grow change where the window is, and the column follows.
	TR.config.width = 300
	TR:UpdateConfig()
	eq(button(TR, 1):GetLeft(), TR.window:GetRight() + 4, 'Width: the column follows the window')
	TR.config.grow = 'up'
	TR:UpdateConfig()
	eq(button(TR, 1):GetTop(), RW.quest(TR, 1):GetTop(), 'Grow up: still level with its title')
	TR.config.grow = 'down'
	TR.config.height = 200
	TR:UpdateConfig()
	eq(button(TR, 1):GetLeft(), TR.window:GetRight() + 4, 'Max height: still beside it')
	eq(#take_errors(), 0, 'no errors')
end)

test('ColumnWidth is Button size while the column shows, else 0', function()
	local st, TR = beside_world({ 1 })
	eq(TR:ColumnWidth(), 24, 'Beside with a quest with an item: Button size')
	TR.config.items.size = 32
	TR:UpdateConfig()
	eq(TR:ColumnWidth(), 32, 'follows Button size')
	log({})
	settle()
	eq(TR:ColumnWidth(), 0, 'no quest with an item: none')
	log({ 1 })
	settle()
	TR.config.items.placement = 'row'
	TR:UpdateConfig()
	eq(TR:ColumnWidth(), 0, 'In the row: none')
	TR.config.items.placement = 'off'
	TR:UpdateConfig()
	eq(TR:ColumnWidth(), 0, 'Off: none')
	eq(#take_errors(), 0, 'no errors')
end)

test('a button that would overlap the one above sits 2 under it; one out of view is hidden', function()
	local st, TR = beside_world({ 1, 2, 3 }, function(TR)
		TR.config.items.size = 40
		TR.config.quests.spacing = 0
	end)
	local r1, r2, r3 = RW.quest(TR, 1), RW.quest(TR, 2), RW.quest(TR, 3)
	check(r2:GetTop() > r1:GetTop() - 40, 'the rows are closer than a 40 button: the second title overlaps the first button')
	local b1, b2, b3 = button(TR, 1), button(TR, 2), button(TR, 3)
	eq(b1:GetTop(), r1:GetTop(), 'the first level with its title')
	eq(b2:GetTop(), b1:GetTop() - 40 - 2, 'the second overlaps the first and sits 2 under it')
	eq(b3:GetTop(), b2:GetTop() - 40 - 2, 'and the third under the second')
	eq(b2:GetLeft(), b1:GetLeft(), 'in the same column')
	-- Rows far apart: each level with its title.
	TR.config.items.size = 16
	TR:UpdateConfig()
	for _, id in ipairs({ 1, 2, 3 }) do eq(button(TR, id):GetTop(), RW.quest(TR, id):GetTop(), id .. ': clear of the others') end

	-- Out of view.
	TR.config.height = 120
	TR:UpdateConfig()
	check(TR.scrollRange > 0, 'the list scrolls')
	check(button(TR, 1):IsShown(), 'the first is in view')
	check(not button(TR, 3):IsShown(), 'the last is out of view: hidden')
	TR:ScrollTo(TR.scrollRange)
	check(not button(TR, 1):IsShown(), 'scrolled: the first is out')
	check(button(TR, 3):IsShown(), 'and the last in')
	eq(button(TR, 3):GetTop(), RW.quest(TR, 3):GetTop(), 'level with its title, scrolled')
	-- A collapsed group and a collapsed tracker.
	TR:ScrollTo(0)
	TR:ToggleZone('Elwynn Forest')
	for index, b in ipairs(TR.itemButtons) do check(not b:IsShown(), index .. ': hidden with its group') end
	TR:ToggleZone('Elwynn Forest')
	TR:SetCollapsed(true)
	for index, b in ipairs(TR.itemButtons) do check(not b:IsShown(), index .. ': hidden with the window collapsed') end
	TR:SetCollapsed(false)
	check(button(TR, 1):IsShown(), 'and back')
	eq(#take_errors(), 0, 'no errors')
end)

test('numbers 1 to n in list order on the button and in the accent at the title\'s end, unchanged as the list scrolls', function()
	local st, TR = beside_world({ 1, 2, 3 }, function(TR) TR.config.height = 120 end)
	local accent = RW.rgb(st.config.profile.theme.accent)
	local function numbers(where)
		for index, id in ipairs({ 1, 2, 3 }) do
			local b, row = button(TR, id), RW.quest(TR, id)
			eq(b.numberText:GetText(), tostring(index), where .. ': ' .. id .. ' the number on its button')
			eq(b.numberText:GetFontObject(), st:GetFont('pixel'), where .. ': in the Pixel font')
			local point, _, relPoint = b.numberText:GetPoint(1)
			eq(point .. relPoint, 'BOTTOMLEFTBOTTOMLEFT', where .. ': at its bottom left')
			check(b.numberText:IsShown(), where .. ': shown')
			if b:IsShown() then
				eq(row.tag:GetText(), tostring(index), where .. ': ' .. id .. ' the same number in its row')
				eq(row.tag:GetFontObject(), st:GetFont('pixel'), where .. ': in the Pixel font in the row')
				eq(RW.color(row.tag), accent, where .. ': in the accent')
			end
		end
	end
	numbers('at first')
	-- The tag follows the end of the title's text.
	local row = RW.quest(TR, 1)
	check(row.tag:IsShown(), 'the tag shows')
	local _, parent, point, x = row.tag:GetPoint(1)
	eq(parent, row, 'on its row')
	check(x > (row.titleX or 0), 'after the title\'s start')
	TR:ScrollTo(TR.scrollRange)
	numbers('scrolled')
	TR:ScrollTo(0)
	TR.config.height = 560
	TR:UpdateConfig()
	-- A quest above completes and goes: the rest are numbered again out of combat.
	log({ 2, 3 })
	settle()
	eq(button(TR, 2).numberText:GetText(), '1', 'the list is numbered from 1 again')
	eq(button(TR, 3).numberText:GetText(), '2', 'in list order')
	eq(RW.quest(TR, 3).tag:GetText(), '2', 'and so is its row')
	-- A quest with no item has no number and no tag.
	log({ 2, 3, 4 }, nil, nil)
	stub.quests.log[4].item = nil
	settle()
	check(not RW.quest(TR, 4).tag:IsShown(), 'a quest with no item: no tag')
	-- In the row (not beside) there are no tags.
	TR.config.items.placement = 'row'
	TR:UpdateConfig()
	check(not RW.quest(TR, 2).tag:IsShown(), 'In the row: no tag')
	check(not button(TR, 2).numberText:IsShown(), 'and no number on the button')
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat the column stays and the list scrolls freely; at combat end the column is placed again', function()
	local st, TR = beside_world({ 1, 2, 3 }, function(TR) TR.config.height = 150 end)
	check(TR.scrollRange > 0, 'the list scrolls')
	local before = {}
	for _, id in ipairs({ 1, 2, 3 }) do
		local b = button(TR, id)
		before[id] = { b:GetLeft(), b:GetTop(), b:IsShown() }
	end
	TW.combat(true)
	TW.count_from_now()
	check(not TR:IsScrollLocked(), 'a column button does not hold the list still')
	check(not TR.window.barLock:IsShown(), 'no lock over the bar')
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), math.min(40, TR.scrollRange), 'the wheel scrolls in combat')
	TR:ScrollTo(TR.scrollRange)
	eq(TR:GetScroll(), TR.scrollRange, 'so does a drag of the bar')
	for _, id in ipairs({ 1, 2, 3 }) do
		local b = button(TR, id)
		eq(b:GetLeft(), before[id][1], id .. ': the column stayed (left)')
		eq(b:GetTop(), before[id][2], id .. ': and (top)')
		eq(b:IsShown(), before[id][3], id .. ': shown or hidden as it was')
		if b:IsShown() then eq(alpha_of(b), 1, id .. ': at full strength: its quest is still listed') end
	end
	stub.secure_clicks = {}
	use(button(TR, 2))
	eq(last_use().item, 'item:1002', 'a click still uses its quest\'s item')
	TW.count_stop()
	eq(TW.counts.secure, 0, 'no secure frame made')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	eq(button(TR, 3):GetTop(), RW.quest(TR, 3):GetTop(), 'combat ends: level with its title again')
	check(button(TR, 3):IsShown() and not button(TR, 1):IsShown(), 'the buttons of the rows in view show, the others hide')
	eq(#stub.blocked, 0, 'nothing blocked after')
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a column button follows its quest by number: a quest that went or changed its item dims, never shows another quest\'s item', function()
	local st, TR = beside_world({ 1, 2, 3 })
	TW.combat(true)
	log({ 2, 3 }) -- 1 completes and goes
	settle()
	local one, two, three = TR.itemButtons[1], TR.itemButtons[2], TR.itemButtons[3]
	eq(alpha_of(one), TR.DIM_ALPHA, 'the quest that went: its button dims')
	check(one:IsShown(), 'and stays (a secure button can\'t hide in combat)')
	eq(alpha_of(two), 1, 'the others are not dimmed by the list moving')
	eq(alpha_of(three), 1, 'nor this one')
	eq(two.numberText:GetText(), '2', 'the numbers stay as they were')
	eq(RW.quest(TR, 2).tag:GetText(), '2', 'and the row of quest 2 shows the number of its own button')
	eq(RW.quest(TR, 3).tag:GetText(), '3', 'quest 3 too')
	stub.secure_clicks = {}
	use(one)
	eq(last_use().item, 'item:1001', 'the dimmed one still uses its own quest\'s item')
	stub.fire_script(one, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[#texts], 'Quest 1', 'its tooltip names the quest')
	stub.fire_script(one, 'OnLeave', true)

	-- A quest that appears in combat has no button and no number until combat ends.
	log({ 2, 3, 4 })
	settle()
	check(button(TR, 4) == nil, 'no button for the new quest')
	check(not RW.quest(TR, 4).tag:IsShown(), 'no number')

	-- An item that changes in combat: the button keeps the old item and dims; its row shows no number.
	stub.quests.log[2].item.link = 'item:7777'
	stub.quests.log[2].item.texture = 777
	settle()
	eq(two:GetAttribute('item'), 'item:1002', 'the button still uses the old item')
	eq(alpha_of(two), TR.DIM_ALPHA, 'and dims')
	check(not RW.quest(TR, 2).tag:IsShown(), 'its row no longer shows its number (it is not that item)')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	check(button(TR, 4) ~= nil, 'combat ends: a button')
	eq(button(TR, 2):GetAttribute('item'), 'item:7777', 'the new item')
	eq(alpha_of(button(TR, 2)), 1, 'full strength')
	eq(button(TR, 4).numberText:GetText(), '3', 'numbered in list order')
	eq(RW.quest(TR, 4).tag:GetText(), '3', 'and its row')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

test('the column keeps the same secure-frame rules: only the layer is parent, only UIParent is an anchor, the regions are made with the button', function()
	local st, TR = beside_world({ 1, 2, 3 })
	for _, frame in ipairs(secure_frames(TR)) do
		check(not (frame:GetParent() ~= UIParent and frame:GetParent() ~= TR.itemLayer), 'a secure frame is on UIParent or the layer')
		for i = 1, frame:GetNumPoints() do
			local _, relativeTo = frame:GetPoint(i)
			check(relativeTo == UIParent, 'anchored to UIParent only')
		end
	end
	local made = {}
	for _, b in ipairs(TR.itemButtons) do made[b] = count_parts(b) end
	TW.combat(true)
	TW.count_from_now()
	log({ 2, 3, 4 })
	settle()
	TR.config.items.size = 32
	TR:UpdateConfig()
	TR:ScrollTo(0)
	TR.config.position = RIGHT_SIDE
	TR:UpdateConfig()
	stub.fire_script(TR.itemWatcher, 'OnSizeChanged', 1280, 1024)
	TW.count_stop()
	eq(TW.counts.secure, 0, 'no secure frame made in combat')
	eq(#stub.blocked, 0, 'nothing blocked')
	for _, b in ipairs(TR.itemButtons) do eq(count_parts(b), made[b], 'no region or frame made on a button in combat') end
	TW.combat(false)
	eq(#stub.blocked, 0, 'nor at its end')
	eq(button(TR, 2):GetLeft(), TR.window:GetRight() + 4, 'the column is on the new side, 32 wide, after combat')
	eq(#take_errors(), 0, 'no errors')
end)

test('Off: a plain icon in the row, no button, no click; the nearest button can still be on', function()
	local st, TR = world({ 1, 2 })
	TR.config.items.placement = 'off'
	TR.config.items.nearest = true
	TR:UpdateConfig()
	settle()
	for _, id in ipairs({ 1, 2 }) do
		local row = RW.quest(TR, id)
		eq(row.item, 'row', id .. ': the room is kept in the row')
		check(row.slot:IsShown(), id .. ': the icon shows')
		check(not row.slot.icon:IsDesaturated(), id .. ': plain')
		check(not row.tag:IsShown(), id .. ': no number')
		check(button(TR, id) == nil, id .. ': no button')
	end
	for index, b in ipairs(TR.itemButtons) do check(not b:IsShown(), index .. ': no button shows') end
	eq(TR:ColumnWidth(), 0, 'no column')
	check(not TR:ItemsToShow(), 'nothing for the handover to leave a button for')
	stub.secure_clicks = {}
	stub.fire_script(RW.quest(TR, 1).slot, 'OnClick', 'LeftButton')
	eq(#stub.secure_clicks, 0, 'a click on the icon uses nothing')
	TW.combat(true)
	check(not TR:IsScrollLocked(), 'in combat the list scrolls')
	TW.combat(false)
	-- Beside: the same.
	TR.config.items.placement = 'beside'
	TR:UpdateConfig()
	TW.combat(true)
	check(not TR:IsScrollLocked(), 'beside: the list scrolls in combat')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('the tracker counts the column as hovered, and the options offer Beside the tracker', function()
	local st, TR = beside_world({ 1, 2 })
	RW.mouse_off()
	check(not TR:IsHovered(), 'the mouse away: not hovered')
	RW.mouse_on(button(TR, 1))
	check(not TR.window:IsMouseOver(), 'the mouse is not over the window')
	check(TR:IsHovered(), 'but it is over the column')
	RW.mouse_off()
	TR.config.items.placement = 'row'
	TR:UpdateConfig()
	RW.mouse_on(button(TR, 1))
	check(TR:IsHovered(), 'in a row button: the window (the button is over the window)')
	RW.mouse_off()
	-- The button's tooltip is placed outside the column, off the window.
	TR.config.items.placement = 'beside'
	TR:UpdateConfig()
	stub.fire_script(button(TR, 1), 'OnEnter', true)
	check(GameTooltip:IsShown(), 'the tooltip shows')
	local point, relativeTo = GameTooltip:GetPoint(1)
	check(relativeTo == button(TR, 1), 'beside its button')
	stub.fire_script(button(TR, 1), 'OnLeave', true)
	local tab = TR.ItemsTab()
	eq(tab.args.placement.values.beside, 'Beside the tracker', 'the select offers it')
	eq(tab.args.placement.sorting[2], 'beside', 'between In the row and Off')
	eq(tab.args.placement.sorting[3], 'off', 'Off last')
	eq(#take_errors(), 0, 'no errors')
end)

test('the column follows the holder\'s drag, the screen\'s size and the UI scale; in combat it stays', function()
	local st, TR = beside_world({ 1, 2 }, function(TR) TR.config.position = LEFT_SIDE end)
	local function follows(where)
		for _, id in ipairs({ 1, 2 }) do
			check(math.abs(button(TR, id):GetRight() - (TR.window:GetLeft() - 4)) <= 1, where .. ': ' .. id .. ' 4 outside the window')
			check(math.abs(button(TR, id):GetTop() - RW.quest(TR, id):GetTop()) <= 1, where .. ': ' .. id .. ' level with its title')
		end
	end
	follows('at first')
	TR.holder:ClearAllPoints()
	TR.holder:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -240, -330)
	follows('a drag')
	stub.screen_width, stub.screen_height = 1280, 1024
	stub.fire_script(TR.itemWatcher, 'OnSizeChanged', 1280, 1024)
	follows('a smaller screen')
	local at = { button(TR, 1):GetLeft(), button(TR, 1):GetTop() }
	TW.combat(true)
	TR.holder:ClearAllPoints()
	TR.holder:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -10, -20)
	eq(button(TR, 1):GetLeft(), at[1], 'in combat it stays (left)')
	eq(button(TR, 1):GetTop(), at[2], 'and (top)')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	follows('combat over')
	eq(#take_errors(), 0, 'no errors')
end)

test('whole pixels with the column on both sides, under the three looks and size noise', function()
	local checked = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				for _, size in ipairs({ 16, 30, 40 }) do
					for _, position in ipairs({ LEFT_SIDE, RIGHT_SIDE }) do
						local where = ('%s, %s, noise %g, size %d, %s'):format(client, theme, noise, size, position.point)
						local st, TR = RW.world({ client = client, enabling = function()
							log({ 1, 2, 3 }, nil, { [1] = { charges = 4, cooldown = { start = 1, duration = 9, enable = 1 } } })
						end })
						T.theme(theme, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
						TR.config.items.placement = 'beside'
						TR.config.items.size = size
						TR.config.position = position
						stub.size_noise = noise
						TR:UpdateConfig()
						TR:Refresh()
						local off = P.off(TR.window)
						eq(#off, 0, where .. ' (the window): ' .. P.report(off))
						off = P.off(TR.itemLayer)
						eq(#off, 0, where .. ' (the layer): ' .. P.report(off))
						for _, id in ipairs({ 1, 2, 3 }) do
							local b = button(TR, id)
							check(b ~= nil and b:IsShown(), where .. ': button ' .. id)
						end
						TR:Refresh()
						off = P.off(TR.itemLayer)
						eq(#off, 0, where .. ' (again): ' .. P.report(off))
						stub.size_noise = 0
						checked = checked + 1
					end
				end
			end
		end
	end
	eq(checked, 2 * 3 * 3 * 3 * 2, 'every combination ran')
	eq(#take_errors(), 0, 'no errors')
end)

test('with the switch off the column makes nothing and runs nothing', function()
	local st, TR = TW.world({ enabling = function() log({ 1, 2 }) end })
	eq(TR:ColumnWidth(), 0, 'no column width')
	eq(TW.counts.secure, 0, 'no secure frame')
	eq(TR.itemButtons, nil, 'no pool')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ fix round 1

local function slot_text(row)
	local texts = stub.state(GameTooltip).texts
	return texts[#texts]
end

test('Beside: a quest whose item has no button shows its icon where the number goes (greyed in combat, plain with no link)', function()
	local st, TR = beside_world({ 1 })
	local row1 = RW.quest(TR, 1)
	check(row1.tag:IsShown() and not row1.slot:IsShown(), 'a quest with its button: the number, no icon')
	-- An item that appears in combat.
	TW.combat(true)
	log({ 1, 2 })
	settle()
	local row2 = RW.quest(TR, 2)
	check(row2.slot:IsShown() and row2.slot.icon:IsDesaturated(), 'greyed icon in its row')
	eq(row2.slot.icon:GetAlpha(), 0.4, 'at 40%')
	check(not row2.tag:IsShown(), 'and no number')
	local point, rel = row2.slot:GetPoint(1)
	eq(rel, row2, 'placed in its row')
	eq(row2.slot:GetLeft(), row2.tag:GetLeft(), 'where the number goes')
	stub.fire_script(row2.slot, 'OnEnter', true)
	eq(slot_text(), 'Its button comes when combat ends.', 'its tooltip')
	stub.fire_script(row2.slot, 'OnLeave', true)
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	check(not RW.quest(TR, 2).slot:IsShown() and RW.quest(TR, 2).tag:IsShown(), 'combat ends: the number replaces it')
	eq(RW.quest(TR, 2).tag:GetText(), '2', 'numbered')

	-- An item with no link: no button, a plain icon.
	log({ 1, 2, 3 }, nil, { [3] = { link = false } })
	stub.quests.log[4].item.link = nil
	settle()
	local row3 = RW.quest(TR, 3)
	check(button(TR, 3) == nil, 'no button')
	check(row3.slot:IsShown() and not row3.slot.icon:IsDesaturated(), 'a plain icon in its row')
	check(not row3.tag:IsShown(), 'no number')
	-- The title's room is the same as for a number: wide enough for a line-high icon.
	check(TR:TagRoom() >= TR:LineHeight() + 4, 'the room fits an icon one line high')
	eq(row3.slot:GetWidth(), TR:LineHeight(), 'the icon is one line high')
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a row shows a number only while a shown button carries it', function()
	local st, TR = beside_world({ 1, 2, 3 }, function(TR) TR.config.height = 120 end)
	check(not button(TR, 3):IsShown(), 'the last button is hidden (its title is out of view)')
	TW.combat(true)
	TR:ScrollTo(TR.scrollRange)
	local row = RW.quest(TR, 3)
	check(not row.tag:IsShown(), 'its row shows no number: the column has no such button on screen')
	check(row.slot:IsShown() and row.slot.icon:IsDesaturated(), 'a greyed icon instead')
	TW.combat(false)
	check(row.tag:IsShown() and row.tag:GetText() == '3', 'combat ends: the button and the number')
	eq(#take_errors(), 0, 'no errors')
end)

test('a stack that runs past the window hides the buttons that do not fit; their rows show the plain icon', function()
	local st, TR = beside_world({ 1, 2, 3, 4, 5, 6 }, function(TR)
		TR.config.items.size = 40
		TR.config.quests.spacing = 0
		TR.config.height = 200
	end)
	local bottom = TR.scroll:GetBottom()
	local shown, hidden = 0, 0
	for _, id in ipairs({ 1, 2, 3, 4, 5, 6 }) do
		local b, row = button(TR, id), RW.quest(TR, id)
		if b:IsShown() then
			shown = shown + 1
			check(b:GetTop() - 20 >= bottom, id .. ': a shown button has its centre inside the window')
			check(row.tag:IsShown(), id .. ': with its number')
		elseif row:IsVisible() and row:GetTop() - 20 >= bottom then
			hidden = hidden + 1
			check(row.slot:IsShown() and not row.slot.icon:IsDesaturated(), id .. ': a hidden button: its row shows the plain icon')
			check(not row.tag:IsShown(), id .. ': and no number')
		end
	end
	check(shown >= 1 and hidden >= 1, 'some fit and some do not (' .. shown .. ' shown, ' .. hidden .. ' hidden)')
	-- No two shown buttons are closer than 2 px.
	local previous
	for _, id in ipairs({ 1, 2, 3, 4, 5, 6 }) do
		local b = button(TR, id)
		if b:IsShown() then
			if previous then check(previous:GetBottom() - b:GetTop() >= 2, id .. ': 2 px under the one above at least') end
			previous = b
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('numbers follow the list\'s order (the current zone first), not the model\'s', function()
	local st, TR = RW.world({ enabling = function()
		local entries = {
			Q.header('Elwynn Forest'), Q.quest(1, { item = item_of(1), objectives = { { text = 'a', type = 'monster' } } }),
			Q.header('Westfall'), Q.quest(2, { item = item_of(2), objectives = { { text = 'b', type = 'monster' } } }),
		}
		Q.set(entries, { 1, 2 })
		stub.real_zone_text = 'Westfall'
	end })
	TR.config.items.placement = 'beside'
	TR:UpdateConfig()
	settle()
	eq(button(TR, 2).numberText:GetText(), '1', 'the current zone\'s quest is first in the list: number 1')
	eq(button(TR, 1).numberText:GetText(), '2', 'the other is 2')
	check(RW.quest(TR, 2):GetTop() > RW.quest(TR, 1):GetTop(), 'as drawn')
	stub.real_zone_text = ''
	eq(#take_errors(), 0, 'no errors')
end)

test('the beside title is narrowed by the number\'s room, which fits two digits; the number follows a short title', function()
	local st, TR = beside_world({ 1 })
	local row = RW.quest(TR, 1)
	local room = TR:TagRoom()
	local pixel = UIParent:CreateFontString(nil, 'OVERLAY')
	pixel:SetFontObject(st:GetFont('pixel'))
	pixel:SetText('88')
	check(room >= math.ceil(pixel:GetStringWidth()) + TR.LAYOUT.ITEM_GAP, 'the room fits "88" and the gap')
	local beside_width = row.title:GetWidth()
	TR.config.items.placement = 'row'
	TR:UpdateConfig()
	local row_width = RW.quest(TR, 1).title:GetWidth()
	TR.config.items.placement = 'off'
	TR:UpdateConfig()
	local off_width = RW.quest(TR, 1).title:GetWidth()
	eq(off_width - beside_width, room - (TR.config.items.size + TR.LAYOUT.ITEM_GAP), 'beside is narrowed by the number\'s room, not the button\'s')
	TR.config.items.placement = 'beside'
	TR:UpdateConfig()
	row = RW.quest(TR, 1)
	local _, _, _, x = row.tag:GetPoint(1)
	local unbounded = row.title.GetUnboundedStringWidth or row.title.GetStringWidth
	local reach = math.ceil(unbounded(row.title))
	eq(x, (row.titleX or 0) + math.min(reach, beside_width) + TR.LAYOUT.ITEM_GAP, 'the number sits after the title\'s last letter, not at the right edge')
	check(x < beside_width, 'short title: well inside the row')
	check(row_width > 0, 'sanity')
	eq(#take_errors(), 0, 'no errors')
end)

test('a secret title is never measured: the number is placed at the title\'s width', function()
	-- The stubs' font strings can't hold a secret, so the draw's SetText turns one into a plain
	-- text, and the title's width reads raise: the number's place must not read them.
	local S = load_test_file('lib/secrets.lua')
	local st, TR = beside_world({ 1 })
	local restore = S.install()
	local set_text = TR.SetText
	TR.SetText = function(fs, text)
		if issecretvalue(text) then
			fs.shownText = nil
			return fs:SetText('secret title')
		end
		return set_text(fs, text)
	end
	local row = RW.quest(TR, 1)
	local function refuse() error('the title\'s width was read') end
	row.title.GetUnboundedStringWidth, row.title.GetStringWidth = refuse, refuse
	stub.quests.log[2].title = S.secret('quest title')
	TR:Refresh()
	check(row.tag:IsShown(), 'the number is drawn')
	local _, _, _, x = row.tag:GetPoint(1)
	eq(x, (row.titleX or 0) + row.title:GetWidth() + TR.LAYOUT.ITEM_GAP, 'placed at the title\'s width, no width read')
	TR.SetText = set_text
	row.title.GetUnboundedStringWidth, row.title.GetStringWidth = nil, nil
	restore()
	eq(#take_errors(), 0, 'no errors')
end)

test('a holder straddling the screen\'s middle puts the column by its centre', function()
	local st, TR = beside_world({ 1 })
	local cx = UIParent:GetCenter()
	local width = TR.config.width
	-- A holder whose centre is just right of the screen's: the column is on the left.
	TR.config.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = cx - width / 2 + 5, y_off = -100 }
	TR:UpdateConfig()
	eq(button(TR, 1):GetRight(), TR.window:GetLeft() - 4, 'centre right of the middle: on the left')
	TR.config.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = cx - width / 2 - 5, y_off = -100 }
	TR:UpdateConfig()
	eq(button(TR, 1):GetLeft(), TR.window:GetRight() + 4, 'centre left of it: on the right')
	eq(#take_errors(), 0, 'no errors')
end)

test('a column button\'s tooltip sits outward from the column and names its quest', function()
	local st, TR = beside_world({ 1 }, function(TR) TR.config.position = LEFT_SIDE end)
	local b = button(TR, 1)
	stub.fire_script(b, 'OnEnter', true)
	local point, rel, relPoint = GameTooltip:GetPoint(1)
	eq(point .. relPoint, 'TOPRIGHTTOPLEFT', 'left column: the tooltip to its left')
	local texts = stub.state(GameTooltip).texts
	eq(texts[2], 'Quest 1', 'the quest\'s title under the item\'s, full strength or not')
	stub.fire_script(b, 'OnLeave', true)
	TR.config.position = RIGHT_SIDE
	TR:UpdateConfig()
	stub.fire_script(b, 'OnEnter', true)
	point, rel, relPoint = GameTooltip:GetPoint(1)
	eq(point .. relPoint, 'TOPLEFTTOPRIGHT', 'right column: to its right')
	stub.fire_script(b, 'OnLeave', true)
end)

test('Off from login makes no layer and no secure frame; a hidden column is not hovered', function()
	local st, TR = RW.world({ enabling = function()
		log({ 1, 2 })
		SaftUI.config.profile.tracker.items.placement = 'off'
	end })
	eq(TR.itemLayer, nil, 'no layer')
	eq(TW.counts.secure, 0, 'no secure frame')
	TR.config.items.placement = 'beside'
	TR:UpdateConfig()
	settle()
	RW.mouse_on(button(TR, 1))
	check(TR:IsHovered(), 'the column is hovered')
	TR.itemLayer:Hide()
	check(not TR:IsHovered(), 'with the layer hidden (a pet battle) it is not')
	TR.itemLayer:Show()
	RW.mouse_off()
end)

test('ColumnWidth counts quests whose item has a link', function()
	local st, TR = beside_world({ 1 })
	stub.quests.log[2].item.link = nil
	settle()
	eq(TR:ColumnWidth(), 0, 'an item with no link makes no column')
end)

------------------------------------------------------------------ fix round 2

test('a row whose button the stack hid keeps the plain icon in combat, not the greyed one', function()
	local st, TR = beside_world({ 1, 2, 3, 4, 5, 6 }, function(TR)
		TR.config.items.size = 40
		TR.config.quests.spacing = 0
		TR.config.height = 200
	end)
	local stacked = {}
	for _, id in ipairs({ 1, 2, 3, 4, 5, 6 }) do
		local b, row = button(TR, id), RW.quest(TR, id)
		if not b:IsShown() and row:IsVisible() and row:GetTop() - 20 >= TR.scroll:GetBottom() then stacked[#stacked + 1] = id end
	end
	check(#stacked >= 1, 'some buttons were hidden by the stack')
	TW.combat(true)
	TR:Refresh()
	TR:PlaceItems()
	for _, id in ipairs(stacked) do
		local row = RW.quest(TR, id)
		check(row.slot:IsShown() and not row.slot.icon:IsDesaturated(), id .. ': still the plain icon in combat')
	end
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	for _, id in ipairs(stacked) do
		check(not RW.quest(TR, id).slot.icon:IsDesaturated(), id .. ': plain after combat')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a quest with no link between two others leaves the numbering without a gap', function()
	local st, TR = beside_world({ 1, 2, 3 })
	stub.quests.log[3].item.link = nil -- quest 2
	settle()
	check(button(TR, 2) == nil, 'no button for it')
	eq(button(TR, 1).numberText:GetText(), '1', 'the first is 1')
	eq(button(TR, 3).numberText:GetText(), '2', 'the one after it is 2: no gap')
	eq(RW.quest(TR, 3).tag:GetText(), '2', 'and its row')
	eq(#take_errors(), 0, 'no errors')
end)

test('an out-of-view button just above the view does not push the first one in view', function()
	local st, TR = beside_world({ 1, 2, 3, 4 }, function(TR)
		TR.config.items.size = 40
		TR.config.quests.spacing = 0
		TR.config.height = 160
	end)
	TR:ScrollTo(TR.scrollRange)
	for _, id in ipairs({ 1, 2, 3, 4 }) do
		local b, row = button(TR, id), RW.quest(TR, id)
		if b:IsShown() then
			local first = true
			for _, other in ipairs({ 1, 2, 3, 4 }) do
				if other < id and button(TR, other):IsShown() then first = false end
			end
			if first then eq(b:GetTop(), row:GetTop(), id .. ': the first in view is level with its title') end
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('the number sits centred on the title\'s first line', function()
	local st, TR = beside_world({ 1 })
	local row = RW.quest(TR, 1)
	local _, _, _, _, y = row.tag:GetPoint(1)
	local line = TR:LineHeight()
	local expected = math.max(0, math.floor((line - TR.tagHeight) / 2))
	eq(-y == 0 and 0 or -y, expected, 'its y is half what the line has over the number')
	check(TR.tagHeight > 0 and TR.tagHeight <= line, 'the number is no taller than the line')
end)

------------------------------------------------------------------ final review

-- A pool button in combat that read its own cooldown (BAG_UPDATE_COOLDOWN) and its
-- own range (the range watcher) keeps both through a placement pass (a scroll, a
-- collapse, a window show or size change): DimItems copies nothing of the model's,
-- which is as old as the last quest or bag event (the nearest button's rule, rule 16).
for _, placement in ipairs({ 'row', 'beside' }) do
	test('in combat a placement pass puts no stale cooldown or range back over a ' .. placement .. ' button\'s own reads', function()
		local st, TR = world({ 1, 2, 3 })
		if placement == 'beside' then
			TR.config.items.placement = 'beside'
			TR:UpdateConfig()
			settle()
		end
		local b = button(TR, 1)
		check(b ~= nil and (b.column == true) == (placement == 'beside'), 'a ' .. placement .. ' button for quest 1')
		TW.combat(true)
		RW.later(0.2)
		stub.time = stub.time + 1
		stub.quests.log[2].item.cooldown = { start = stub.time, duration = 30, enable = 1 }
		stub.quests.log[2].item.range = 0
		stub.fire_event('BAG_UPDATE_COOLDOWN')
		stub.fire_script(TR.itemWatcher, 'OnUpdate', 1)
		eq(stub.state(b.cooldown).cooldown_duration, 30, 'the swipe is drawn from its own read')
		eq(b.range, 0, 'and the range from the watcher')
		local red = ('%.2f %.2f %.2f'):format(st.config.profile.colors.text.red:GetRGB())
		eq(('%.2f %.2f %.2f'):format(b.icon:GetVertexColor()), red, 'out of range: red')
		-- A scroll, a collapse and a size change all place the items again.
		TR:PlaceItems()
		TR:RefreshItems()
		eq(b.cdStart, stub.quests.log[2].item.cooldown.start, 'the pass leaves the swipe (the model has none)')
		eq(stub.state(b.cooldown).cooldown_duration, 30, 'still drawn')
		eq(b.range, 0, 'the range is not the model\'s old one')
		eq(('%.2f %.2f %.2f'):format(b.icon:GetVertexColor()), red, 'still red')
		eq(#stub.blocked, 0, 'nothing blocked')
		TW.combat(false)
		eq(#take_errors(), 0, 'no errors')
	end)
end

-- M7: BAG_UPDATE_COOLDOWN comes with every global cooldown in a fight.
test('BAG_UPDATE_COOLDOWN goes through a gap: the first draws at once, the rest of a burst are one draw at the gap\'s end', function()
	local st, TR = world({ 1, 2, 3 })
	RW.later(1)
	local reads = 0
	local real = GetQuestLogSpecialItemCooldown
	GetQuestLogSpecialItemCooldown = function(...) reads = reads + 1; return real(...) end
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	eq(reads, 3, 'the first event after a quiet gap reads the three buttons at once')
	for _ = 1, 20 do stub.fire_event('BAG_UPDATE_COOLDOWN') end
	eq(reads, 3, 'twenty more inside the gap read nothing yet')
	RW.later(TR.REFRESH_GAP + 0.01)
	eq(reads, 6, 'one draw when the gap ends, for all twenty')
	RW.later(1)
	eq(reads, 6, 'and no more')
	stub.quests.log[2].item.cooldown = { start = 50, duration = 20, enable = 1 }
	stub.fire_event('BAG_UPDATE_COOLDOWN')
	eq(stub.state(button(TR, 1).cooldown).cooldown_duration, 20, 'a change after a quiet gap is drawn at once')
	GetQuestLogSpecialItemCooldown = real
	eq(#take_errors(), 0, 'no errors')
end)

test('BAG_UPDATE_COOLDOWN makes no table per button: an unchanged cooldown allocates nothing and draws nothing', function()
	local st, TR = world({ 1, 2, 3, 4 }, { nearest = true })
	local b = button(TR, 1)
	stub.quests.log[2].item.cooldown = { start = 50, duration = 20, enable = 1 }
	TR:RefreshCooldowns()
	local cd = b.cd
	check(cd ~= nil and cd.duration == 20, 'drawn')
	local draws = 0
	local set = b.cooldown.SetCooldown
	b.cooldown.SetCooldown = function(...) draws = draws + 1; return set(...) end
	TR:RefreshCooldowns()
	eq(b.cd, cd, 'the same table, filled again in place')
	eq(draws, 0, 'an unchanged cooldown is not drawn again')
	stub.quests.log[2].item.cooldown = { start = 60, duration = 20, enable = 1 }
	TR:RefreshCooldowns()
	eq(b.cd, cd, 'a changed one fills the same table')
	eq(draws, 1, 'and is drawn')
	-- Allocation: with the stubs' own reads subtracted, the tracker's part is nothing.
	local function churn(f)
		collectgarbage(); collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, 200 do f() end
		local after = collectgarbage('count')
		collectgarbage('restart')
		return (after - before) / 200
	end
	local stubs = churn(function()
		for index = 1, 5 do GetQuestLogSpecialItemCooldown(index) end
	end)
	local own = churn(function() TR:RefreshCooldowns(); TR:RefreshNearestCooldown() end)
	check(own <= stubs + 0.05, ('the tracker adds no allocation to a draw: %.3f KB against the stubs\' %.3f'):format(own, stubs))
	eq(#take_errors(), 0, 'no errors')
end)
