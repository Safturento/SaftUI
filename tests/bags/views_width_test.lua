-- How wide the section views (One bag, Multi bag and Rows) make a window
-- (layout.lua's INV:LayoutSections and INV:SectionLineSlots): as many slots
-- as the widest section shows, from perrow (one Compact column) up to
-- perrow * maxColumns, held while the window is open (it widens at once, and
-- narrows again only after a close or a view switch), Compact unchanged, and
-- every frame and slot on whole pixels. The same world as
-- views_layout_test.lua.
local H = load_test_file('bags/container_helpers.lua')
local P = load_test_file('lib/pixels.lua')

local INV, W
local bw, bh, sp, padding
-- The least line: perrow, or the slots the header's least width has room for.
local F

-- The bag window in view, perrow 4 and maxColumns 3 (a line of at most 12),
-- laid out with the bag's items given by counts: how many items of each class
-- go in the backpack, one section (Rows) per class. Free slots aren't shown.
local CLASSES = { Consumable = 'Consumable', Weapon = 'Weapon', ['Trade Goods'] = 'Trade Goods', Armor = 'Armor' }
local function fill(counts)
	for slot = 1, 40 do W.bags[0].items[slot] = nil end
	local slot, id = 0, 500
	for _, class in ipairs({ 'Consumable', 'Weapon', 'Trade Goods', 'Armor' }) do
		for i = 1, counts[class] or 0 do
			slot, id = slot + 1, id + 1
			W.put(0, slot, W.item(id, class .. ' ' .. i, CLASSES[class], 100 - i))
		end
	end
end

local function world(view, counts, setup)
	INV, W = H.views_world('forever')
	bw, bh, sp = INV:GetButtonWidth(), INV:GetButtonHeight(), INV.config.buttonspacing
	padding = INV.config.padding
	W.bag(0, 40, 'Backpack')
	fill(counts)
	INV.config.stackItems = false
	INV.config.bag.view = view
	INV.config.bag.emptySlots = 'off'
	INV.config.bag.perrow = 4
	INV.config.bag.maxColumns = 3
	if setup then setup() end
	local container = H.window('bag')
	-- As INV:CreateContainer hooks it: closing a window releases its layout.
	container:HookScript('OnHide', function() INV:ReleaseLayout(container) end)
	INV:UpdateContainer('bag', true)
	F = math.max(INV.config.bag.perrow, math.floor((INV:HeaderMinWidth(container) - padding * 2 + sp) / (bw + sp)))
	return container
end

local function line(n) return n * (bw + sp) - sp end

-- The window as wide as n slots and the padding (or its header, if that is wider).
local function window_width(c, n)
	return math.max(line(n) + padding * 2, INV:HeaderMinWidth(c))
end

local function update(c)
	INV:UpdateContainer('bag', true)
end

local function switch(view)
	INV.config.bag.view = view
	INV:ApplyView('bag')
end

local SPARSE = { Consumable = 3, Weapon = 2, ['Trade Goods'] = 2, Armor = 5 }

test('rows: sections of 3, 2, 2 and 5 items make a line of 5 slots', function()
	local c = world('rows', SPARSE)
	eq(INV:LineSlots('bag', 'rows'), 12, 'the most a line holds is perrow * maxColumns')
	for _, name in ipairs({ 'Consumables', 'Weapons', 'Trade Goods', 'Armor' }) do
		local frame = c.categories[name]
		check(frame:IsShown(), name .. ' shown')
		eq(frame:GetWidth(), line(5), name .. ': a frame of the line, five slots')
	end
	eq(c.scrollFrame:GetWidth(), line(5), 'the scroll frame is the line')
	eq(c:GetWidth(), window_width(c, 5), 'and the window the line and its padding')
	local armor = c.categories.Armor
	eq(armor.slots[5]:GetTop(), armor.slots[1]:GetTop(), 'the fifth armor is on the first line')
	eq(armor.slots[5]:GetRight(), armor:GetRight(), 'at the right edge of the line')
	eq(armor.numRows, 1, 'five armors, one line')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: a section of 30 items caps the line at perrow * maxColumns', function()
	local c = world('rows', { Consumable = 30, Weapon = 2 })
	eq(c.categories.Weapons:GetWidth(), line(12), 'a line of twelve')
	eq(c.categories.Consumables:GetWidth(), line(12), 'for every section')
	eq(c.categories.Consumables.numRows, 3, 'thirty consumables wrap at twelve: three lines')
	eq(c:GetWidth(), window_width(c, 12), 'the window')
	eq(#take_errors(), 0, 'no errors')
end)

test("rows: one item is the floor: perrow, or what the header's least width has room for", function()
	local c = world('rows', { Weapon = 1 })
	eq(c.categories.Weapons:GetWidth(), line(F), 'the floor wide')
	eq(c:GetWidth(), window_width(c, F), 'the window is as wide as the floor')
	local none = world('rows', {})
	eq(none:GetWidth(), window_width(none, F), 'no items: the same')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: Compact is as wide as it was, by its columns', function()
	local c = world('compact', SPARSE)
	eq(INV:LineSlots('bag', 'compact'), 4, "Compact's line is perrow")
	local used = 0
	for _, column in ipairs(c.columns) do if #column.categories > 0 then used = used + 1 end end
	eq(c.scrollFrame:GetWidth(), used * (c.columns[1]:GetWidth() + sp) - sp, 'only the columns in use')
	eq(#take_errors(), 0, 'no errors')
end)

test('the window holds its width while open, widens at once, and releases it on a switch or a close', function()
	local c = world('rows', { Consumable = 9, Weapon = 2 })
	eq(c.categories.Weapons:GetWidth(), line(9), 'nine consumables: a line of nine')
	local width = c:GetWidth()

	-- Items leave while open: the window keeps its width, the items close up.
	for slot = 1, 8 do W.bags[0].items[slot] = nil end
	update(c)
	eq(c.categories.Consumables:GetWidth(), line(9), 'the frames keep the line')
	eq(c.scrollFrame:GetWidth(), line(9), 'the scroll frame too')
	eq(c:GetWidth(), width, 'the window did not narrow')
	eq(c.categories.Weapons.slots[2]:GetTop(), c.categories.Weapons.slots[1]:GetTop(), 'the items stay on their line')

	-- A section that needs more widens it at once.
	for i = 1, 11 do W.put(0, 20 + i, W.item(700 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
	update(c)
	eq(c.categories['Trade Goods']:GetWidth(), line(11), 'eleven trade goods: a line of eleven')
	eq(c.categories.Weapons:GetWidth(), line(11), 'every section')
	eq(c:GetWidth(), window_width(c, 11), 'the window')

	-- They go again: held at eleven.
	for i = 1, 11 do W.bags[0].items[20 + i] = nil end
	update(c)
	eq(c:GetWidth(), window_width(c, 11), 'held')

	-- Closed and opened again (OnHide releases the layout): afresh.
	c:Hide()
	INV:ReleaseLayout(c)
	eq(c.sectionLine, nil, 'a release forgets the window\'s line')
	eq(INV:SlotLine(c), INV:LineSlots('bag', 'rows'), 'and a slot made now takes the most a line holds')
	c:Show()
	update(c)
	eq(c.scrollFrame:GetWidth(), line(F), 'reopened, as narrow as the items need: the floor')
	eq(c.categories.Weapons:GetWidth(), line(F), 'and the frames')

	-- A view switch releases it too.
	for i = 1, 11 do W.put(0, 20 + i, W.item(700 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
	update(c)
	eq(c.scrollFrame:GetWidth(), line(11), 'wide again')
	for i = 1, 11 do W.bags[0].items[20 + i] = nil end
	switch('compact')
	switch('rows')
	eq(c.scrollFrame:GetWidth(), line(F), 'after a switch away and back, released')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: slots follow the line when it changes', function()
	local c = world('rows', { Weapon = 5 })
	local weapons = c.categories.Weapons
	eq(weapons.slots[5]:GetTop(), weapons.slots[1]:GetTop(), 'five weapons on one line of five')
	for i = 1, 8 do W.put(0, 10 + i, W.item(800 + i, 'Cuirass ' .. i, 'Armor', 10)) end
	update(c)
	eq(weapons:GetWidth(), line(8), 'a line of eight')
	eq(weapons.slots[8]:GetTop(), weapons.slots[1]:GetTop(), 'a slot made in the pool sits on the first line at eight')
	eq(c.categories.Armor.slots[8]:GetTop(), c.categories.Armor.slots[1]:GetTop(), 'eight armors, one line')
	for i = 1, 20 do W.put(0, 20 + i, W.item(900 + i, 'Plate ' .. i, 'Armor', 10)) end
	update(c)
	eq(weapons:GetWidth(), line(12), 'capped at twelve')
	eq(c.categories.Armor.slots[13]:GetTop(), c.categories.Armor.slots[1]:GetBottom() - sp, 'the thirteenth armor starts the second line')
	eq(c.categories.Armor.slots[13]:GetLeft(), c.categories.Armor.slots[1]:GetLeft(), 'at the left')
	eq(#take_errors(), 0, 'no errors')
end)

test('multi bag: the line is the widest bag, one bag section each', function()
	local c = world('multibag', { Consumable = 7 }, function()
		W.bag(1, 16, 'Bag')
		W.put(1, 1, W.item(201, 'Axe', 'Weapon', 70))
		W.put(1, 2, W.item(202, 'Sword', 'Weapon', 50))
	end)
	eq(c.categories['view:bag0']:GetWidth(), line(7), 'the backpack holds seven: a line of seven')
	eq(c.categories['view:bag1']:GetWidth(), line(7), 'the bag with two is as wide')
	eq(c:GetWidth(), window_width(c, 7), 'the window')
	eq(#take_errors(), 0, 'no errors')
end)

test('one bag: the main grid sets the line, and every slot shown fills the full width', function()
	local c = world('onebag', { Consumable = 6 })
	eq(c.categories['view:main']:GetWidth(), line(6), 'six items: a line of six')
	eq(c:GetWidth(), window_width(c, 6), 'the window')

	local full = world('onebag', { Consumable = 6 }, function() INV.config.bag.emptySlots = 'all' end)
	local main = full.categories['view:main']
	eq(main:GetWidth(), line(12), 'a grid of every slot (forty) needs the full width')
	eq(full:GetWidth(), window_width(full, 12), 'the window is as wide as it was')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows with Grouped empty slots: the Empty Slots section counts its buttons, not its free slots', function()
	local c = world('rows', { Weapon = 2 }, function() INV.config.bag.emptySlots = 'grouped' end)
	local empties = c.categories['Empty Slots']
	check(empties and empties:IsShown(), 'the Empty Slots section shows')
	eq(empties:GetWidth(), line(F), 'one grouped button: the floor')
	eq(#take_errors(), 0, 'no errors')
end)

test('the sections and slots sit on whole pixels, and the window is a whole width, at a narrow width', function()
	for _, view in ipairs({ 'rows', 'onebag', 'multibag' }) do
		local c = world(view, SPARSE)
		eq(P.report(P.off(c.scrollFrame.ScrollChild)), P.report({}), view .. ': every section and slot on a whole pixel')
		eq(c:GetWidth() % 1, 0, view .. ': a whole width')
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the invariant

-- At every moment, in combat or not: every shown item button lies inside its
-- section frame, no two sections overlap, and every section lies inside the
-- window.
local EPS = 0.01
local function invariant(c, label)
	local frames = {}
	for name, frame in pairs(c.categories) do
		if frame:IsShown() and frame.container == c and not (name == 'Currencies') then
			table.insert(frames, frame)
			for i, slot in ipairs(frame.slots) do
				if slot:IsShown() then
					local where = label .. ': ' .. name .. ' slot ' .. i
					check(slot:GetLeft() >= frame:GetLeft() - EPS and slot:GetRight() <= frame:GetRight() + EPS, where .. ' inside its frame sideways')
					check(slot:GetTop() <= frame:GetTop() + EPS and slot:GetBottom() >= frame:GetBottom() - EPS, where .. ' inside its frame down')
				end
			end
			check(frame:GetLeft() >= c.scrollFrame:GetLeft() - EPS and frame:GetRight() <= c.scrollFrame:GetRight() + EPS, label .. ': ' .. name .. ' inside the scroll frame')
		end
	end
	table.sort(frames, function(a, b) return a:GetTop() > b:GetTop() end)
	for i = 2, #frames do
		check(frames[i]:GetTop() <= frames[i - 1]:GetBottom() + EPS, label .. ': ' .. frames[i].name .. ' below ' .. frames[i - 1].name)
	end
	check(c.scrollFrame:GetRight() <= c:GetRight() + EPS, label .. ': the scroll frame inside the window')
end

local function in_combat(fn)
	stub.in_combat = true
	fn()
	stub.in_combat = false
end

local function moves(c)
	local n = 0
	for _, frame in pairs(c.categories) do
		for _, slot in ipairs(frame.slots) do
			for _, method in ipairs({ 'SetPoint', 'ClearAllPoints' }) do
				local original = slot[method]
				slot[method] = function(...) n = n + 1 return original(...) end
			end
		end
	end
	return function() return n end
end

test('combat: opened after a close, with a section that grew while closed', function()
	local c = world('rows', { Consumable = 5, Weapon = 2 }) -- a line of five (or the floor, if wider)
	local line5 = c.categories.Consumables:GetWidth()
	c:Hide()
	for i = 1, 3 do W.put(0, 30 + i, W.item(900 + i, 'Tonic ' .. i, 'Consumable', 10)) end
	local moved
	in_combat(function()
		c:Show()
		moved = moves(c)
		update(c)
		invariant(c, 'opened in combat')
		eq(moved(), 0, 'no item button moved in combat')
		eq(c.categories.Consumables:GetWidth(), line5, 'frames keep the line their slots are anchored at')
		eq(c.categories.Consumables.numRows, 8 > F and 2 or 1, 'rows follow that line')
	end)
	eq(#take_errors(), 0, 'no errors')
end)

test('combat: a category first shown in combat with more items than the line', function()
	local c = world('rows', { Weapon = 2 })
	local before = c:GetWidth()
	in_combat(function()
		local moved = moves(c)
		for i = 1, 7 do W.put(0, 30 + i, W.item(900 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
		update(c)
		invariant(c, 'new section in combat')
		eq(moved(), 0, 'no item button moved')
		check(c:GetWidth() >= before, 'the window did not narrow')
	end)
	eq(#take_errors(), 0, 'no errors')
end)

test('after combat the window lays out again to the rule', function()
	local c = world('rows', { Weapon = 2 })
	in_combat(function()
		for i = 1, 7 do W.put(0, 30 + i, W.item(900 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
		update(c)
	end)
	stub.fire_event('PLAYER_REGEN_ENABLED')
	update(c)
	eq(c.categories['Trade Goods']:GetWidth(), line(math.max(7, F)), 'seven trade goods: a line of seven')
	eq(c.categories.Weapons:GetWidth(), line(math.max(7, F)), 'every section')
	invariant(c, 'after combat')
	local top = c.categories['Trade Goods'].slots
	eq(top[7]:GetTop(), top[1]:GetTop(), 'the seventh on the first line')
	eq(#take_errors(), 0, 'no errors')
end)

test('after combat a layout is queued for a window opened in combat with a stale line', function()
	local c = world('rows', { Consumable = 5, Weapon = 2 })
	c:Hide()
	for i = 1, 8 do W.put(0, 30 + i, W.item(900 + i, 'Tonic ' .. i, 'Consumable', 10)) end
	in_combat(function() c:Show() update(c) end)
	INV.NEED_UPDATE = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check(INV.NEED_UPDATE, 'a full update is queued when combat ends')
	update(c)
	eq(c.categories.Consumables:GetWidth(), line(math.max(13, F) > 12 and 12 or math.max(13, F)), 'at the line the rule gives')
	invariant(c, 'caught up')
end)

test('combat: items arriving while open keep every item inside its section', function()
	local c = world('rows', { Consumable = 6, Weapon = 2 })
	in_combat(function()
		local moved = moves(c)
		for i = 1, 4 do W.put(0, 30 + i, W.item(900 + i, 'Tonic ' .. i, 'Consumable', 10)) end
		update(c)
		invariant(c, 'loot in combat')
		eq(moved(), 0, 'no item button moved')
	end)
	eq(#take_errors(), 0, 'no errors')
end)

test('a Bags setting changed, then combat: slotLine is true and the invariant holds', function()
	local c = world('rows', { Consumable = 5, Weapon = 2 })
	INV:UpdateConfig('bag')
	INV:StyleContainerContents(c)
	update(c)
	for name, frame in pairs(c.categories) do
		if frame.slotLine and frame.slots[frame.slotLine + 1] then
			eq(select(2, frame.slots[frame.slotLine + 1]:GetPoint(1)), frame.slots[1], name .. ': slot after the line is under the first, as slotLine says')
		end
	end
	c:Hide()
	in_combat(function()
		for i = 1, 3 do W.put(0, 30 + i, W.item(900 + i, 'Tonic ' .. i, 'Consumable', 10)) end
		c:Show()
		update(c)
		invariant(c, 'setting then combat')
	end)
	eq(#take_errors(), 0, 'no errors')
end)

test('slotLine is recorded by every path that anchors slots', function()
	local c = world('compact', { Consumable = 5, Weapon = 2 })
	switch('rows')
	local cap = INV:LineSlots('bag', 'rows')
	for name, frame in pairs(c.categories) do
		if #frame.slots > 0 and name ~= 'Currencies' then
			check(frame.slotLine == cap or frame.slotLine == c.sectionLine, name .. ': recorded after a view switch: ' .. tostring(frame.slotLine))
		end
	end
	INV:ReleaseLayout(c)
	switch('compact')
	for name, frame in pairs(c.categories) do
		if #frame.slots > 0 and name ~= 'Currencies' then eq(frame.slotLine, 4, name .. ': Compact records perrow') end
	end
	switch('rows')
	local armor = c.categories.Armor
	local line = armor.slotLine
	local made = #armor.slots
	INV:CreateSlot(c, 'Armor')
	eq(armor.slotLine, line, 'a new slot anchors at the frame\'s line and leaves it')
	eq(#armor.slots, made + 1, 'made')
	INV:ReleaseLayout(c)
	INV:SetSlotPosition(armor.slots[#armor.slots], armor, c)
	eq(armor.slotLine, line, 'released, a slot still anchors at the frame\'s own line')
	eq(#take_errors(), 0, 'no errors')
end)

local function currencies_world(view, counts, n)
	return world(view, counts, function()
		C_CurrencyInfo.RequestCurrencyDataForAccountCharacters = function() end
		C_CurrencyInfo.GetCurrencyListSize = function() return n end
		C_CurrencyInfo.GetCurrencyListInfo = function(i)
			return { name = 'Coin ' .. i, quantity = i, iconFileID = i, isHeader = false }
		end
		C_CurrencyInfo.GetCurrencyListLink = function(i) return 'currency:' .. i end
		C_CurrencyInfo.GetCurrencyIDFromLink = function(link) return tonumber(link:match('%d+')) end
		C_CurrencyInfo.GetBasicCurrencyInfo = function() return { quality = 1 } end
	end)
end

test('the Currencies section decides the line when it has the most, once per layout', function()
	local calls = 0
	local c = currencies_world('rows', { Weapon = 2 }, 10)
	local original = INV.GetCurrencies
	INV.GetCurrencies = function(...) calls = calls + 1 return original(...) end
	update(c)
	INV.GetCurrencies = original
	check(c.categories.Currencies:IsShown(), 'the Currencies section shows')
	eq(c.categories.Weapons:GetWidth(), line(10), 'ten currencies, two weapons: a line of ten')
	eq(c.categories.Currencies:GetWidth(), line(10), 'the Currencies frame too')
	eq(calls, 1, 'GetCurrencies once per layout')
	eq(#take_errors(), 0, 'no errors')
end)

test("a bank in Rows: sections of 3, 2, 2 and 5 are a line of 5 (or what the header's room allows)", function()
	INV, W = H.views_world('forever')
	bw, bh, sp = INV:GetButtonWidth(), INV:GetButtonHeight(), INV.config.buttonspacing
	padding = INV.config.padding
	local tab = INV.bagIds.combinedbank[1]
	W.bag(tab, 98, 'Bank')
	local slot, id = 0, 500
	for _, class in ipairs({ 'Consumable', 'Weapon', 'Trade Goods', 'Armor' }) do
		for i = 1, ({ Consumable = 3, Weapon = 2, ['Trade Goods'] = 2, Armor = 5 })[class] do
			slot, id = slot + 1, id + 1
			W.put(tab, slot, W.item(id, class .. i, class, 50 - i))
		end
	end
	INV.config.stackItems = false
	INV.config.combinedbank.view = 'rows'
	INV.config.combinedbank.perrow = 4
	INV.config.combinedbank.maxColumns = 5
	local c = H.window('combinedbank')
	c:HookScript('OnHide', function() INV:ReleaseLayout(c) end)
	INV:UpdateContainer('combinedbank', true)
	local fit = math.floor((INV:HeaderMinWidth(c) - padding * 2 + sp) / (bw + sp))
	local want = math.min(20, math.max(5, fit))
	eq(c.sectionLine, want, 'a line of five, or the header-wide slots if more')
	check(want < 20, 'far under the cap of twenty')
	eq(c.scrollFrame:GetWidth(), line(want), 'the scroll frame')
	eq(c:GetWidth() % 1, 0, 'a whole width')
	check(c:GetWidth() <= line(want) + padding * 2 + bw + sp, 'no blank strip as wide as a slot')
	eq(#take_errors(), 0, 'no errors')
end)

test('the window uses the room its header needs: whole slots, never over the cap', function()
	local c = world('rows', { Weapon = 1 }, function() INV.config.bag.perrow = 2 end)
	local room = math.floor((INV:HeaderMinWidth(c) - padding * 2 + sp) / (bw + sp))
	check(room > 2, 'the header is wider than two slots (the test means something)')
	eq(c.sectionLine, math.min(room, INV:LineSlots('bag', 'rows')), 'the line grows to fit the header')
	eq(c:GetWidth() % 1, 0, 'a whole width')
	check(c:GetWidth() - padding * 2 - c.scrollFrame:GetWidth() < bw + sp, 'under a slot of blank on the right')
	eq(#take_errors(), 0, 'no errors')
end)

test('a title longer than the line is cut with dots inside it, the count kept', function()
	local c = world('rows', { Weapon = 2 })
	local weapons = c.categories.Weapons
	local items = {}
	for _, s in ipairs(weapons.slots) do if s.info then table.insert(items, s.info) end end
	INV:UpdateCategory('bag', 'Weapons', items, 'A very long category name that cannot possibly fit (12)', F)
	local text = weapons.header.text
	check(text:GetUnboundedStringWidth() <= weapons:GetWidth(), 'the title fits the frame')
	check(text:GetText():find('%.%.%. %(12%)$'), 'cut with dots, the count at the end: ' .. tostring(text:GetText()))
	INV:UpdateCategory('bag', 'Weapons', items, 'Short (2)', F)
	eq(text:GetText(), 'Short (2)', 'a short title is left alone')
	eq(#take_errors(), 0, 'no errors')
end)

test("in Compact a title longer than its column is cut with dots inside it too, the count kept, on whole pixels", function()
	for _, title in ipairs({ 'Flasks/Potions/Food', 'Professions/Recipes', 'Paladin/Priest/Warlock' }) do
		local c = world('compact', { Weapon = 2 })
		local weapons = c.categories.Weapons
		local items = {}
		for _, s in ipairs(weapons.slots) do if s.info then table.insert(items, s.info) end end
		-- Colus 15 is wider than the stubs' size-only measure: a long name stands in.
		local long = title .. ' and then some more words to be sure it cannot fit (22)'
		INV:UpdateCategory('bag', 'Weapons', items, long, F)
		local text = weapons.header.text
		check(text:GetUnboundedStringWidth() <= weapons:GetWidth(), title .. ': the title fits its column')
		check(text:GetText():find('%.%.%. %(22%)$'), title .. ': cut with dots, the count at the end: ' .. tostring(text:GetText()))
		eq(weapons:GetWidth() % 1, 0, 'the column is a whole width')
		eq(text:GetWidth() % 1, 0, 'and the title is cut to a whole width')
		INV:UpdateCategory('bag', 'Weapons', items, 'Short (2)', F)
		eq(text:GetText(), 'Short (2)', 'a short title is left alone')
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ Compact, Items per row changed while closed

-- No two shown category frames overlap (Compact has several columns), each
-- is as wide as its column, and every shown item button is inside its frame.
local function compact_ok(c, label)
	local frames = {}
	for name, frame in pairs(c.categories) do
		if frame:IsShown() and name ~= 'Currencies' then
			table.insert(frames, frame)
			eq(frame:GetWidth(), c.columns[1]:GetWidth(), label .. ': ' .. name .. ' as wide as its column')
			for i, slot in ipairs(frame.slots) do
				if slot:IsShown() then
					check(slot:GetLeft() >= frame:GetLeft() - EPS and slot:GetRight() <= frame:GetRight() + EPS
						and slot:GetBottom() >= frame:GetBottom() - EPS and slot:GetTop() <= frame:GetTop() + EPS,
						label .. ': ' .. name .. ' slot ' .. i .. ' inside its frame')
				end
			end
		end
	end
	for i = 1, #frames do
		for j = i + 1, #frames do
			local a, b = frames[i], frames[j]
			local w = math.min(a:GetRight(), b:GetRight()) - math.max(a:GetLeft(), b:GetLeft())
			local h = math.min(a:GetTop(), b:GetTop()) - math.max(a:GetBottom(), b:GetBottom())
			check(not (w > EPS and h > EPS), label .. ': ' .. a.name .. ' and ' .. b.name .. ' do not overlap')
		end
	end
end

test('Compact: Items per row changed while the bags are closed, then opened in combat', function()
	local c = world('compact', { Consumable = 5, Weapon = 2, ['Trade Goods'] = 2, Armor = 5 })
	c:Hide()
	INV.config.bag.perrow = 3
	INV:UpdateConfig('bag')
	INV:StyleContainerContents(c)
	in_combat(function()
		local moved = moves(c)
		c:Show()
		update(c)
		compact_ok(c, 'bags')
		eq(moved(), 0, 'no item button moved in combat')
	end)
	stub.fire_event('PLAYER_REGEN_ENABLED')
	update(c)
	compact_ok(c, 'bags after combat')
	eq(#take_errors(), 0, 'no errors')
end)

test('Compact: the same in the combined bank', function()
	INV, W = H.views_world('forever')
	bw, bh, sp = INV:GetButtonWidth(), INV:GetButtonHeight(), INV.config.buttonspacing
	padding = INV.config.padding
	local tab = INV.bagIds.combinedbank[1]
	W.bag(tab, 60, 'Bank')
	local slot, id = 0, 500
	for _, class in ipairs({ 'Consumable', 'Weapon', 'Trade Goods', 'Armor' }) do
		for i = 1, 4 do
			slot, id = slot + 1, id + 1
			W.put(tab, slot, W.item(id, class .. i, class, 50 - i))
		end
	end
	INV.config.stackItems = false
	INV.config.combinedbank.view = 'compact'
	INV.config.combinedbank.perrow = 4
	H.window('bag') -- the Currencies category is the bag window's
	local c = H.window('combinedbank')
	c:HookScript('OnHide', function() INV:ReleaseLayout(c) end)
	INV:UpdateContainer('combinedbank', true)
	c:Hide()
	INV.config.combinedbank.perrow = 2
	INV:UpdateConfig('combinedbank')
	INV:StyleContainerContents(c)
	in_combat(function()
		c:Show()
		INV:UpdateContainer('combinedbank', true)
		compact_ok(c, 'bank')
	end)
	eq(#take_errors(), 0, 'no errors')
end)

test('combat: two frames on different lines, the narrower holding more items than its line', function()
	local c = world('rows', { Consumable = 5 })
	in_combat(function()
		for i = 1, 3 do W.put(0, 30 + i, W.item(900 + i, 'Tonic ' .. i, 'Consumable', 10)) end
		for i = 1, 7 do W.put(0, 34 + i, W.item(950 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
		update(c)
		local cons = c.categories.Consumables
		check(cons.slotLine < c.categories['Trade Goods'].slotLine, 'the frames are anchored at different lines')
		eq(cons.numRows, 2, 'eight consumables wrap at their own line')
		invariant(c, 'two lines')
	end)
	eq(#take_errors(), 0, 'no errors')
end)

-- A font change lays the windows out again only when a window title's look
-- changed (Window titles, or the bags' Title font), and the layout is an update
-- that skips the category rebuild and the skin, once a frame.
local function title_world(view)
	local c = world(view, SPARSE)
	INV.UpdateGold = function() end
	H.search(c)
	SaftUI:FontsChanged() -- the first change seeds the look the bags compare with
	INV:UpdateHandler(nil, 1)
	return c
end

local function counted(name)
	local box = { n = 0 }
	local fn = INV[name]
	INV[name] = function(...) box.n = box.n + 1; return fn(...) end
	box.restore = function() INV[name] = fn end
	return box
end

test('a Window titles change that widens the window title widens the window, with no category rebuild', function()
	for _, view in ipairs({ 'compact', 'rows' }) do
		local c = title_world(view)
		local width = c:GetWidth()
		-- A wider font for Window titles: the title is 200 wider than the window had room for.
		local titleWidth = c.title:GetStringWidth() + (width - INV:HeaderMinWidth(c)) + 200
		c.title.GetStringWidth = function() return titleWidth end
		SaftUI.config.profile.headers.font = { font_size = 30 }
		local sorts, rebuilds = counted('GetSortedInventory'), counted('CategoriesChanged')
		SaftUI:FontsChanged()
		INV:UpdateHandler(nil, 1)
		sorts.restore()
		rebuilds.restore()
		check(c:GetWidth() > width, view .. ': the window is wider than it was')
		check(c:GetWidth() >= INV:HeaderMinWidth(c), view .. ': and holds the title')
		check(INV:HeaderMinWidth(c) >= width + 200, view .. ': the least width counts the new title')
		check(sorts.n <= 1, view .. ': the items were read and sorted once, as a bag event does')
		eq(rebuilds.n, 0, view .. ': with no category rebuild (no CategoriesChanged)')
		local errors = take_errors()
		eq(#errors, 0, view .. ': no errors ' .. tostring(errors[1]))
	end
end)

test("a font change that leaves a window title's look alone costs the bags nothing; the bags' Title font counts", function()
	for _, view in ipairs({ 'compact', 'rows' }) do
		local c = title_world(view)
		local queued, updates = counted('QueueUpdate'), counted('UpdateContainer')
		-- Large numbers and Small text: not what a window title draws in.
		SaftUI.config.profile.fonts.pixel_med.font_size = 31
		SaftUI:FontsChanged()
		SaftUI.config.profile.fonts.pixel.font_size = 11
		SaftUI:FontsChanged()
		INV:UpdateHandler(nil, 1)
		eq(queued.n, 0, view .. ': no layout asked for')
		eq(updates.n, 0, view .. ': and no update run')
		-- The bags' own Title font, with a change that reaches FontsChanged (a shared font it names).
		INV.config.fonts.titles = { font_size = 22 }
		SaftUI:FontsChanged()
		eq(queued.n, 1, view .. ": the bags' Title font changed: a layout asked for")
		-- Window titles naming a shared font: that font's change counts.
		SaftUI.config.profile.headers.font = 'pixel_med'
		SaftUI:FontsChanged()
		queued.n = 0
		SaftUI.config.profile.fonts.pixel_med.font_size = 40
		SaftUI:FontsChanged()
		eq(queued.n, 1, view .. ': the shared font Window titles names changed: a layout asked for')
		queued.restore()
		updates.restore()
		eq(#take_errors(), 0, view .. ': no errors')
	end
end)

test('many font steps in one frame lay the windows out once', function()
	for _, view in ipairs({ 'compact', 'rows' }) do
		local c = title_world(view)
		local updates = counted('UpdateContainer')
		for size = 20, 29 do -- a Size drag on Window titles: ten steps
			SaftUI.config.profile.headers.font = { font_size = size }
			SaftUI:FontsChanged()
		end
		eq(updates.n, 0, view .. ': nothing laid out at once, on any step')
		INV:UpdateHandler(nil, 1)
		eq(updates.n, 1, view .. ': one update for the ten steps')
		INV:UpdateHandler(nil, 1)
		eq(updates.n, 1, view .. ': and none after it')
		updates.restore()
		eq(#take_errors(), 0, view .. ': no errors')
	end
end)
