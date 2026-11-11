-- How the bag views other than Compact lay a window out (SaftUI-Bags/
-- container.lua's INV:LayoutSections and INV:ApplyView, with INV:UpdateCategory,
-- INV:SetSlotPosition and the currency slots): each section a full-width
-- category frame stacked top to bottom, its slots in lines of
-- INV:LineSlots, the window as wide as Compact's with every column in use and
-- not shrinking while open, Compact back exactly after a switch, the Rows
-- view's hidden categories, and a switch in combat waiting for the end of it.
-- Free slots in Every slot mode get their buttons out of combat, and in combat
-- show no more than there are buttons.
--
-- bags/container_helpers.lua's views world: bag_world.lua's stubbed bags under
-- the module's real files (container.lua, category.lua, slot.lua, views.lua,
-- currencies.lua, movers.lua, inventory.lua), and its stand-ins for the
-- Blizzard templates and API the slots are made of. The currencies case gives
-- C_CurrencyInfo a currency list, as far as INV:GetCurrencies, the currency
-- slots and their borders read it.
local H = load_test_file('bags/container_helpers.lua')

local INV, W

-- Sizes from the defaults: slots 60 by 50, 3 apart, 50 tall titles, 10 padding.
local bw, bh, sp, title, padding

-- The bag window in view, laid out: the backpack (20 slots) holds twelve
-- consumables, bag 1 (16 slots) two weapons and a trade good, and no free
-- slots are shown. setup, if given, runs before the window is made.
local function world(view, setup)
	INV, W = H.views_world('forever')
	bw, bh, sp = INV:GetButtonWidth(), INV:GetButtonHeight(), INV.config.buttonspacing
	title, padding = INV.config.categoryTitleHeight, INV.config.padding
	W.bag(0, 20, 'Backpack')
	W.bag(1, 16, 'Bag')
	for i = 1, 12 do W.put(0, i, W.item(100 + i, 'Tonic ' .. i, 'Consumable', 40 - i)) end
	W.put(1, 1, W.item(201, 'Axe', 'Weapon', 70))
	W.put(1, 2, W.item(202, 'Sword', 'Weapon', 50))
	W.put(1, 3, W.item(301, 'Plank', 'Trade Goods', 15))
	INV.config.stackItems = false
	INV.config.bag.view = view or 'compact'
	INV.config.bag.emptySlots = 'off'
	if setup then setup() end
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

-- Switches the bag window's view, as the title bar's buttons will.
local function switch(view)
	INV.config.bag.view = view
	INV:ApplyView('bag')
end

-- The width of a line of n slots.
local function line(n) return n * (bw + sp) - sp end

local function shown_slots(frame)
	local n = 0
	for _, slot in ipairs(frame.slots) do if slot:IsShown() then n = n + 1 end end
	return n
end

local function empty_slots(frame)
	local n = 0
	for _, slot in ipairs(frame.slots) do if slot:IsShown() and slot.info.empty then n = n + 1 end end
	return n
end

------------------------------------------------------------------ Rows

test('rows: each category full width, stacked in priority order, wrapping at perrow * maxColumns', function()
	local c = world('rows')
	eq(INV:LineSlots('bag', 'rows'), 9, 'rows: perrow 3 * maxColumns 3')
	eq(INV:LineSlots('bag', 'compact'), 3, 'compact: perrow')
	local child = c.scrollFrame.ScrollChild
	local cons, weapons, goods = c.categories.Consumables, c.categories.Weapons, c.categories['Trade Goods']
	for name, frame in pairs({ Consumables = cons, Weapons = weapons, ['Trade Goods'] = goods }) do
		check(frame:IsShown(), name .. ' shown')
		eq(frame:GetWidth(), line(9), name .. ': full width, a line of nine')
		eq(frame:GetLeft(), child:GetLeft(), name .. ': at the left edge')
	end
	eq(cons:GetTop(), child:GetTop(), 'Consumables first, at the top')
	eq(weapons:GetTop(), cons:GetBottom() - sp, 'then Weapons, one spacing below')
	eq(goods:GetTop(), weapons:GetBottom() - sp, 'then Trade Goods')
	eq(cons.header.text:GetText(), 'Consumables (12)', 'titled as Compact titles it')

	eq(cons.numRows, 2, 'twelve consumables are two lines')
	eq(cons:GetHeight(), title + 2 * (bh + sp), 'the title and two lines')
	eq(weapons.numRows, 1, 'two weapons are one')
	local s = cons.slots
	eq(s[1]:GetTop(), cons:GetTop() - title - sp, 'the first slot under the title')
	eq(s[9]:GetTop(), s[1]:GetTop(), 'the ninth still on the first line')
	eq(s[9]:GetRight(), cons:GetRight(), 'which fills the width')
	eq(s[10]:GetLeft(), s[1]:GetLeft(), 'the tenth starts the second line')
	eq(s[10]:GetTop(), s[1]:GetBottom() - sp, 'one spacing below the first')
	eq(s[12]:GetBottom(), cons:GetBottom(), 'the frame ends with its last line')
	eq(shown_slots(cons), 12, 'twelve slots shown')

	for i, column in ipairs(c.columns) do check(not column:IsShown(), "Compact's column " .. i .. ' hidden') end
	check(not c.categories.Armor:IsShown(), 'a category with no items is hidden')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: the window is as wide as Compact with every column in use', function()
	local c = world('compact')
	check(#c.columns[3].categories > 0, 'Compact uses all three columns (the test means something)')
	local width, scroll = c:GetWidth(), c.scrollFrame:GetWidth()
	switch('rows')
	eq(c:GetWidth(), width, 'the window keeps its width')
	eq(c.scrollFrame:GetWidth(), scroll, 'and so does the scroll frame')
	eq(scroll, line(9), 'a line of nine')
	eq(c:GetWidth(), line(9) + padding * 2, 'and the padding')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: categories hidden in the profile (filters.categories[id]) stay hidden', function()
	local c = world('rows')
	INV.config.filters.categories.bag.Weapons = true
	INV:UpdateContainer('bag', true)
	check(not c.categories.Weapons:IsShown(), 'Weapons hidden')
	eq(c.categories['Trade Goods']:GetTop(), c.categories.Consumables:GetBottom() - sp, 'Trade Goods closes up under Consumables')
	for _, section in ipairs(INV:GetViewSections('bag', 'rows')) do
		check(section.key ~= 'Weapons', 'no Weapons section in Rows')
	end
	local main = INV:GetViewSections('bag', 'onebag')[1]
	local axe
	for _, info in ipairs(main.items) do if info.name == 'Axe' then axe = true end end
	check(axe, 'One bag still shows the weapons: it is about bags, not categories')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ switching

test('switching compact → rows → compact restores Compact exactly', function()
	local c = world('compact')
	local where, snap = H.where(c), H.snapshot(c)
	local counts = {}
	for name, category in pairs(c.categories) do counts[name] = #category.slots end

	switch('rows')
	eq(c.categories.Consumables:GetWidth(), line(9), 'in Rows (the switch happened)')
	eq(c.categories.Consumables.slots[4]:GetTop(), c.categories.Consumables.slots[1]:GetTop(), 'slot 4 on the first line')
	switch('compact')
	check(H.same(H.where(c), where), 'every category back in its column and place')
	check(H.same(H.snapshot(c), snap), 'every frame, slot and the window where they were')
	for name, category in pairs(c.categories) do
		eq(#category.slots, counts[name], name .. ': the same slots')
	end
	for i, column in ipairs(c.columns) do check(column:IsShown(), 'column ' .. i .. ' back') end

	local before = H.frames_made()
	switch('rows')
	switch('compact')
	eq(H.frames_made(), before, 'no new frames on the second switch')
	check(H.same(H.snapshot(c), snap), 'and Compact as it was')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ open

test('loot arriving in rows view updates the section and the window does not shrink while open', function()
	local c = world('rows')
	local cons, weapons = c.categories.Consumables, c.categories.Weapons
	W.put(0, 13, W.item(113, 'Tonic 13', 'Consumable', 1))
	INV:UpdateContainer('bag', true)
	eq(cons.header.text:GetText(), 'Consumables (13)', 'the section counts the new item')
	eq(shown_slots(cons), 13, 'and shows it')
	eq(cons.slots[13]:GetTop(), cons.slots[10]:GetTop(), 'on the second line')
	local height, scroll = c:GetHeight(), c.scrollFrame:GetHeight()

	for slot = 1, 4 do W.bags[0].items[slot] = nil end -- sold
	INV:UpdateContainer('bag', true)
	eq(cons.numRows, 1, 'nine consumables left: one line')
	eq(weapons:GetTop(), cons:GetBottom() - sp, 'the sections below close up')
	eq(c.scrollFrame:GetHeight(), scroll, 'the window does not shrink while open')
	eq(c:GetHeight(), height, 'its height kept')

	W.put(1, 4, W.item(203, 'Mace', 'Weapon', 60))
	W.put(1, 5, W.item(204, 'Bow', 'Weapon', 40))
	W.put(1, 6, W.item(205, 'Dagger', 'Weapon', 30))
	W.put(1, 7, W.item(206, 'Staff', 'Weapon', 20))
	W.put(1, 8, W.item(207, 'Wand', 'Weapon', 10))
	W.put(1, 9, W.item(208, 'Club', 'Weapon', 5))
	W.put(1, 10, W.item(209, 'Spear', 'Weapon', 4))
	W.put(1, 11, W.item(210, 'Fist', 'Weapon', 3))
	W.put(0, 1, W.item(114, 'Tonic 14', 'Consumable', 2))
	INV:UpdateContainer('bag', true)
	eq(weapons.numRows, 2, 'ten weapons: two lines')
	check(c.scrollFrame:GetHeight() > scroll, 'the window grows when it must')
	local grown = c.scrollFrame:GetHeight()

	-- Closed (its OnHide releases the layout) and opened again: afresh.
	c:Hide()
	INV:ReleaseLayout(c)
	c:Show()
	for slot = 1, 11 do W.bags[1].items[slot] = nil end
	INV:UpdateContainer('bag', true)
	check(c.scrollFrame:GetHeight() < grown, 'reopened, it fits its items again')
	eq(#take_errors(), 0, 'no errors')
end)

test('an untitled section has no header height', function()
	local c = world('onebag')
	local child = c.scrollFrame.ScrollChild
	local main = c.categories['view:main']
	check(main and main:IsShown(), "One bag's main section is shown")
	check(not main.header:IsShown(), 'its header is hidden')
	eq(main:GetTop(), child:GetTop(), 'at the top')
	eq(main.numRows, 2, 'fifteen items: two lines of nine')
	eq(main:GetHeight(), 2 * (bh + sp) - sp, 'two lines and no title')
	eq(main.slots[1]:GetTop(), main:GetTop(), 'the first slot at its top')
	eq(main.slots[1]:GetLeft(), main:GetLeft(), 'and left')
	eq(main.slots[15]:GetBottom(), main:GetBottom(), 'the last line at its bottom')
	eq(main:GetWidth(), line(9), 'full width')
	eq(#take_errors(), 0, 'no errors')
end)

test('SetSlotPosition with perrow 1 stacks slots vertically', function()
	local c = world('compact', function() INV.config.bag.perrow = 1 end)
	local s = c.categories.Weapons.slots
	eq(s[2]:GetLeft(), s[1]:GetLeft(), 'the second slot under the first')
	eq(s[2]:GetTop(), s[1]:GetBottom() - sp, 'one spacing below')
	eq(c.categories.Weapons.numRows, 2, 'two weapons are two lines')
	INV:SetSlotPosition(s[3], c.categories.Weapons, c, 1)
	eq(s[3]:GetTop(), s[2]:GetBottom() - sp, 'with the line width given: the third under the second')
	eq(s[3]:GetLeft(), s[1]:GetLeft(), 'in the same column')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ combat

-- Counts the calls on every slot and category frame of a window to what
-- moves, sizes, reparents, shows or hides them; they all pass through.
local function watch_moves(container)
	local calls = { n = 0 }
	local function watch(frame)
		for _, method in ipairs({ 'SetPoint', 'ClearAllPoints', 'SetParent', 'SetSize', 'SetWidth', 'SetHeight', 'Show', 'Hide' }) do
			local original = frame[method]
			frame[method] = function(...)
				calls.n = calls.n + 1
				return original(...)
			end
		end
	end
	for _, category in pairs(container.categories) do
		watch(category)
		for _, slot in ipairs(category.slots) do watch(slot) end
	end
	return calls
end

test('ApplyView in combat queues, and applies after combat', function()
	local c = world('compact')
	local snap = H.snapshot(c)
	local cons = c.categories.Consumables
	local calls = watch_moves(c)
	local layouts = 0
	local layoutSections = INV.LayoutSections
	INV.LayoutSections = function(...)
		layouts = layouts + 1
		return layoutSections(...)
	end

	stub.in_combat = true
	switch('rows')
	switch('rows')
	eq(calls.n, 0, 'nothing moved, sized, reparented, shown or hidden in combat')
	check(H.same(H.snapshot(c), snap), 'the window as it was')
	eq(layouts, 0, 'no layout')

	-- Loot in the fight lays the window out in the view it is in.
	W.put(0, 13, W.item(113, 'Tonic 13', 'Consumable', 1))
	INV:UpdateContainer('bag', true)
	eq(layouts, 0, 'still Compact')
	eq(cons:GetWidth(), line(3), 'its old line width')
	eq(cons.slots[4]:GetLeft(), cons.slots[1]:GetLeft(), 'slot 4 still starts the second line')
	eq(shown_slots(cons), 13, 'with the new item')

	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(layouts, 1, 'after combat: laid out once, for both switches')
	eq(cons:GetWidth(), line(9), 'in Rows')
	eq(cons.slots[4]:GetTop(), cons.slots[1]:GetTop(), 'slot 4 on the first line')
	eq(cons.slots[10]:GetLeft(), cons.slots[1]:GetLeft(), 'slot 10 starts the second')
	for i, column in ipairs(c.columns) do check(not column:IsShown(), 'column ' .. i .. ' hidden') end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ empty slots

-- Slots made in combat are broken (INV:CreateSlot flags and reports them).
local function made_in_combat(container)
	local n = 0
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do if slot.tainted then n = n + 1 end end
	end
	return n
end

test('Every slot, any window: buttons made out of combat, and in combat no more free slots than buttons', function()
	-- The bank in Rows: its Empty Slots buttons are made out of combat, a
	-- button for every bank slot.
	local c = world('compact')
	local tab1, tab2, tab3 = INV.bagIds.bank[1], INV.bagIds.bank[2], INV.bagIds.bank[3]
	W.bag(tab1, 28, 'Bank')
	W.bag(tab2, 10, 'Bank bag')
	W.put(tab1, 1, W.item(401, 'Gold Bar', 'Trade Goods', 30))
	INV.config.bank.view = 'rows'
	INV.config.bank.emptySlots = 'all'
	local bank = H.window('bank')
	INV:UpdateContainer('bank', true)
	local empties = bank.categories['Empty Slots']
	check(empties and empties:IsShown(), "the bank's Empty Slots section")
	check(#empties.slots >= 38, 'a button for every bank slot, made out of combat: ' .. #empties.slots)
	eq(empty_slots(empties), 37, 'every free slot shown')

	-- A bigger bank bag in the fight: no button is made, and no more free
	-- slots show than there are buttons.
	stub.in_combat = true
	local buttons = #empties.slots
	W.bag(tab3, 40, 'Big bag')
	INV:UpdateContainer('bank', true)
	eq(#empties.slots, buttons, 'no button made in combat')
	eq(empty_slots(empties), buttons, 'as many free slots as buttons')
	eq(made_in_combat(bank), 0, 'no broken slot')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check(#empties.slots >= 78, 'after combat the buttons are made: ' .. #empties.slots)
	INV:UpdateContainer('bank', true)
	eq(empty_slots(empties), 77, 'and every free slot shows')

	-- One bag's main section holds items and free slots together: in combat
	-- its free slots take only the buttons its items leave.
	INV.config.bag.emptySlots = 'all'
	switch('onebag')
	local main = c.categories['view:main']
	eq(empty_slots(main), 21, 'every free slot of the two bags (36 slots, 15 items)')
	stub.in_combat = true
	buttons = #main.slots
	W.bag(2, 40, 'Big bag')
	INV:UpdateContainer('bag', true)
	eq(#main.slots, buttons, 'no button made in combat')
	eq(shown_slots(main), buttons, 'the items and as many free slots as fit')
	eq(made_in_combat(c), 0, 'no broken slot')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	INV:UpdateContainer('bag', true)
	eq(empty_slots(main), 61, 'after combat, all 61')
	eq(made_in_combat(c), 0, 'still no broken slot')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ currencies

test('currencies wrap at the line width, whichever window updates', function()
	-- Twelve currencies, as C_CurrencyInfo lists them.
	local c = world('rows', function()
		C_CurrencyInfo.RequestCurrencyDataForAccountCharacters = function() end
		C_CurrencyInfo.GetCurrencyListSize = function() return 12 end
		C_CurrencyInfo.GetCurrencyListInfo = function(i)
			return { name = 'Coin ' .. i, quantity = i, iconFileID = i, isHeader = false }
		end
		C_CurrencyInfo.GetCurrencyListLink = function(i) return 'currency:' .. i end
		C_CurrencyInfo.GetCurrencyIDFromLink = function(link) return tonumber(link:match('%d+')) end
		C_CurrencyInfo.GetBasicCurrencyInfo = function() return { quality = 1 } end
	end)
	local currencies = c.categories.Currencies
	check(currencies and currencies:IsShown(), 'the Currencies section')
	-- The currency slots by currency, as the last update gave them out.
	local function currency_slots()
		local out = {}
		for slot in currencies.slotPool:EnumerateActive() do out[slot.elementData.id] = slot end
		return out
	end
	local slots = currency_slots()
	eq(currencies:GetTop(), c.categories['Trade Goods']:GetBottom() - sp, 'the last section')
	eq(currencies:GetWidth(), line(9), 'full width')
	eq(currencies.numRows, 2, 'twelve currencies: two lines of nine')
	eq(slots[9]:GetTop(), slots[1]:GetTop(), 'the ninth on the first line')
	eq(slots[10]:GetLeft(), slots[1]:GetLeft(), 'the tenth starts the second')

	-- The bank's updates refresh the bag window's currencies too.
	W.bag(INV.bagIds.bank[1], 28, 'Bank')
	H.window('bank')
	INV:UpdateContainer('bank', true)
	slots = currency_slots()
	eq(slots[9]:GetTop(), slots[1]:GetTop(), 'a bank update keeps them in lines of nine')
	eq(currencies.numRows, 2, 'two lines')

	switch('compact')
	slots = currency_slots()
	eq(slots[4]:GetLeft(), slots[1]:GetLeft(), 'Compact: lines of three again')
	eq(currencies.numRows, 4, 'four lines')
	eq(currencies:GetWidth(), line(3), "as wide as Compact's column, its Filter button at the column's edge")
	eq(#take_errors(), 0, 'no errors')
end)
