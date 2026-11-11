-- The One bag and Multi bag views laid out (SaftUI-Bags/views.lua's sections
-- through INV:LayoutSections and INV:ApplyView): One bag's untitled main grid
-- with the special bags and Currencies titled under it, Multi bag's titled
-- section per bag or bank tab (a combined bank's bank, then its warband bank,
-- whichever eye was toggled), an empty bag keeping its title, search dimming in
-- every section and a view switch applying it again, Currencies last in every
-- view with its Filter button on its header, the profile's hidden categories
-- not applying, the window as wide as Rows, and the carried review items: no
-- frame changing between titled and untitled across views, free slots in
-- combat in a Multi bag section, One bag <-> Multi bag <-> Compact round trips,
-- and a fight's loot never making a button (each section has one per slot of
-- its bags, and in combat shows no more than it has). bags/bag_world.lua's
-- bags under bags/container_helpers.lua's views world.
local H = load_test_file('bags/container_helpers.lua')

local INV, W
local bw, bh, sp, title, padding

-- The bag window in view, laid out: the backpack (20 slots) holds twelve
-- consumables and a quest item, bag 1 (16 slots) two weapons and a trade good,
-- and a herb bag (bag 2, 12 slots, family 32) two herbs. Twelve currencies.
local function world(view, setup)
	INV, W = H.views_world('forever')
	bw, bh, sp = INV:GetButtonWidth(), INV:GetButtonHeight(), INV.config.buttonspacing
	title, padding = INV.config.categoryTitleHeight, INV.config.padding
	W.bag(0, 20, 'Backpack')
	W.bag(1, 16, 'Bag')
	W.bag(2, 12, 'Herb Bag', 32)
	for i = 1, 12 do W.put(0, i, W.item(100 + i, 'Tonic ' .. i, 'Consumable', 40 - i)) end
	W.put(0, 13, W.item(150, 'Rock', 'Quest', 5))
	W.put(1, 1, W.item(201, 'Axe', 'Weapon', 70))
	W.put(1, 2, W.item(202, 'Sword', 'Weapon', 50))
	W.put(1, 3, W.item(301, 'Plank', 'Trade Goods', 15))
	W.put(2, 1, W.item(401, 'Sunblossom', 'Trade Goods', 19))
	W.put(2, 2, W.item(402, 'Peacebloom', 'Trade Goods', 18))
	INV.config.stackItems = false
	INV.config.bag.view = view or 'compact'
	INV.config.bag.emptySlots = 'off'
	C_CurrencyInfo.RequestCurrencyDataForAccountCharacters = function() end
	C_CurrencyInfo.GetCurrencyListSize = function() return 12 end
	C_CurrencyInfo.GetCurrencyListInfo = function(i)
		return { name = 'Coin ' .. i, quantity = i, iconFileID = i, isHeader = false }
	end
	C_CurrencyInfo.GetCurrencyListLink = function(i) return 'currency:' .. i end
	C_CurrencyInfo.GetCurrencyIDFromLink = function(link) return tonumber(link:match('%d+')) end
	C_CurrencyInfo.GetBasicCurrencyInfo = function() return { quality = 1 } end
	if setup then setup() end
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

local function switch(view)
	INV.config.bag.view = view
	INV:ApplyView('bag')
end

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

-- The names of the shown slots of a frame, in order.
local function slot_names(frame)
	local out = {}
	for _, slot in ipairs(frame.slots) do
		if slot:IsShown() and slot.info and not slot.info.empty then out[#out + 1] = slot.info.name end
	end
	return table.concat(out, ',')
end

-- The shown category frames of a window, top to bottom, by their names.
local function stack(container)
	local shown = {}
	for name, frame in pairs(container.categories) do
		if frame:IsShown() then shown[#shown + 1] = { name = name, top = frame:GetTop() } end
	end
	table.sort(shown, function(a, b) return a.top > b.top end)
	local out = {}
	for i, entry in ipairs(shown) do out[i] = entry.name end
	return table.concat(out, ' | ')
end

------------------------------------------------------------------ One bag

test('onebag: the main grid has no heading; special bag sections and Currencies follow, titled', function()
	local c = world('onebag')
	local main, herb, currencies = c.categories['view:main'], c.categories['view:bag2'], c.categories.Currencies
	check(main:IsShown() and not main.header:IsShown(), 'the main grid, with no heading')
	eq(main.numRows, 2, 'sixteen items in two lines of nine')
	eq(shown_slots(main), 16, 'the items of the backpack and bag 1')
	check(not slot_names(main):find('Sunblossom'), 'the herb bag items are not in the main grid')
	check(herb:IsShown() and herb.header:IsShown(), "the herb bag's section, titled")
	eq(herb.header.text:GetText(), 'Herb Bag (2 / 12)', 'its name and how full it is')
	eq(slot_names(herb), 'Sunblossom,Peacebloom', 'its items, in the item sort')
	check(currencies:IsShown() and currencies.header:IsShown(), 'Currencies, titled')
	eq(currencies.header.text:GetText(), 'Currencies', 'as Currencies')
	eq(stack(c), 'view:main | view:bag2 | Currencies', 'main, special bags, then Currencies')
	local child = c.scrollFrame.ScrollChild
	eq(main:GetTop(), child:GetTop(), 'the main grid at the top')
	eq(herb:GetTop(), main:GetBottom() - sp, 'the herb bag one spacing under it')
	eq(currencies:GetTop(), herb:GetBottom() - sp, 'Currencies one spacing under that')
	for i, column in ipairs(c.columns) do check(not column:IsShown(), "Compact's column " .. i .. ' hidden') end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ Multi bag

test('multibag: a titled section per bag; the bank window shows a section per tab', function()
	local c = world('multibag')
	eq(stack(c), 'view:bag0 | view:bag1 | view:bag2 | Currencies', 'a section per bag, then Currencies')
	local pack, bag, herb = c.categories['view:bag0'], c.categories['view:bag1'], c.categories['view:bag2']
	eq(pack.header.text:GetText(), 'Backpack (13 / 20)', 'titled with the name and used / total')
	eq(bag.header.text:GetText(), 'Bag (3 / 16)', 'the second bag')
	eq(herb.header.text:GetText(), 'Herb Bag (2 / 12)', 'the herb bag')
	for _, frame in ipairs({ pack, bag, herb }) do
		check(frame.header:IsShown(), frame.name .. ': titled')
		eq(frame:GetWidth(), line(9), frame.name .. ': full width')
	end
	eq(slot_names(bag), 'Axe,Sword,Plank', "a bag's items: by category, then the item sort")
	eq(slot_names(pack):sub(-4), 'Rock', 'the quest item after the consumables')
	eq(pack:GetTop(), c.scrollFrame.ScrollChild:GetTop(), 'the first at the top')
	eq(bag:GetTop(), pack:GetBottom() - sp, 'the next one spacing under')

	local tab1, tab2 = INV.bagIds.bank[1], INV.bagIds.bank[2]
	W.bag(tab1, 10, 'Tab 1'); W.bag(tab2, 10, 'Tab 2')
	W.put(tab1, 1, W.item(501, 'Gold Bar', 'Trade Goods', 30))
	INV.config.bank.view = 'multibag'
	local bank = H.window('bank')
	INV:UpdateContainer('bank', true)
	eq(stack(bank), 'view:bag' .. tab1 .. ' | view:bag' .. tab2, 'the bank: a section per tab, no Currencies')
	eq(bank.categories['view:bag' .. tab1].header.text:GetText(), 'Tab 1 (1 / 10)', 'titled by tab')
	eq(bank.categories['view:bag' .. tab2].header.text:GetText(), 'Tab 2 (0 / 10)', 'an empty tab, too')
	eq(#take_errors(), 0, 'no errors')
end)

test('multibag: an empty bag with Empty slots off still shows its title', function()
	local c = world('multibag', function() W.bag(3, 8, 'Empty Bag') end)
	local empty = c.categories['view:bag3']
	check(empty and empty:IsShown(), "the empty bag's section is shown")
	check(empty.header:IsShown(), 'with its header')
	eq(empty.header.text:GetText(), 'Empty Bag (0 / 8)', 'its title')
	eq(empty:GetHeight(), title, 'as tall as the title')
	eq(shown_slots(empty), 0, 'no slots')
	eq(c.categories['view:bag2']:GetTop(), c.categories['view:bag1']:GetBottom() - sp, 'in its place in the stack')
	eq(empty:GetTop(), c.categories['view:bag2']:GetBottom() - sp, 'after the herb bag (bag order)')
	eq(#take_errors(), 0, 'no errors')
end)

test("combined bank multibag: the bank's sections, then the warband bank's", function()
	INV, W = H.views_world('retail')
	W.bag(0, 20, 'Backpack')
	local bankTab, bankTab2, warbandTab = INV.bagIds.bank[1], INV.bagIds.bank[2], INV.bagIds.warband[1]
	W.bag(bankTab, 10, 'Bank 1'); W.bag(bankTab2, 10, 'Bank 2'); W.bag(warbandTab, 20, 'Warband 1')
	W.put(bankTab, 1, W.item(601, 'Gold Bar', 'Trade Goods', 30))
	W.put(warbandTab, 1, W.item(602, 'Silver Bar', 'Trade Goods', 20))
	INV.config.stackItems = false
	INV.config.combinedbank.view = 'multibag'
	local c = H.window('combinedbank')
	INV:UpdateContainer('combinedbank', true)
	eq(stack(c), ('view:bag%d | view:bag%d | view:bag%d'):format(bankTab, bankTab2, warbandTab),
		"the bank's tabs, then the warband bank's")
	eq(c.categories['view:bag' .. warbandTab].header.text:GetText(), 'Warband 1 (1 / 20)', 'the warband tab titled')
	eq(slot_names(c.categories['view:bag' .. warbandTab]), 'Silver Bar', 'with its own items')
	eq(#take_errors(), 0, 'no errors')
end)

test("combined bank multibag: the bank's sections stay first after the bank selector's eyes are toggled", function()
	INV, W = H.views_world('retail')
	load_saftui('SaftUI-Bags/containers/combinedbank.lua') -- INV:UpdateContainerBagIds, the eyes' click
	local bankTab, bankTab2, warbandTab = INV.bagIds.bank[1], INV.bagIds.bank[2], INV.bagIds.warband[1]
	W.bag(bankTab, 10, 'Bank 1'); W.bag(bankTab2, 10, 'Bank 2'); W.bag(warbandTab, 20, 'Warband 1')
	INV.config.stackItems = false
	INV.config.combinedbank.view = 'multibag'
	local c = H.window('combinedbank')
	INV:UpdateContainer('combinedbank', true)
	local both = ('view:bag%d | view:bag%d | view:bag%d'):format(bankTab, bankTab2, warbandTab)
	eq(stack(c), both, 'the bank, then the warband bank')
	INV:UpdateContainerBagIds('warband', false)
	eq(stack(c), ('view:bag%d | view:bag%d'):format(bankTab, bankTab2), 'the warband eye closed: the bank alone')
	INV:UpdateContainerBagIds('warband', true)
	eq(stack(c), both, 'opened again: the bank, then the warband bank')
	INV:UpdateContainerBagIds('bank', false)
	eq(stack(c), 'view:bag' .. warbandTab, 'the bank eye closed: the warband bank alone')
	INV:UpdateContainerBagIds('bank', true)
	eq(stack(c), both, 'opened again: the bank still first')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ every view

test('search dims non-matching items in every section', function()
	for _, view in ipairs({ 'onebag', 'multibag' }) do
		local c = world(view)
		c:Show()
		INV:UpdateSearchFilter({ GetText = function() return 'sunblossom' end })
		local lit, dim = 0, 0
		for _, frame in pairs(c.categories) do
			for _, slot in ipairs(frame.slots) do
				if slot:IsShown() then
					if slot:GetAlpha() == 1 then lit = lit + 1 else dim = dim + 1 end
				end
			end
		end
		eq(lit, 1, view .. ': only the Sunblossom lit')
		check(dim >= 15, view .. ': everything else dimmed, in every section: ' .. dim)
		local herb = c.categories['view:bag2']
		for _, slot in ipairs(herb.slots) do
			if slot:IsShown() then
				eq(slot:GetAlpha(), slot.info.name == 'Sunblossom' and 1 or 0.1, view .. ': ' .. slot.info.name .. ' in the herb section')
			end
		end
		INV:UpdateSearchFilter({ GetText = function() return '' end })
		for _, frame in pairs(c.categories) do
			for _, slot in ipairs(frame.slots) do
				if slot:IsShown() then eq(slot:GetAlpha(), 1, view .. ': no search, all lit') end
			end
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

-- How many of a window's shown item slots are lit and dimmed: 'lit/dimmed'.
local function lit_dimmed(container)
	local lit, dim = 0, 0
	for _, frame in pairs(container.categories) do
		for _, slot in ipairs(frame.slots) do
			if slot:IsShown() then
				if slot:GetAlpha() == 1 then lit = lit + 1 else dim = dim + 1 end
			end
		end
	end
	return lit .. '/' .. dim
end

test('a view switch dims the new view as the search says, and a search cleared in another view lights it again', function()
	local c = world('compact')
	c:Show()
	local search = H.search(c)
	INV:UpdateContainer('bag', true)
	search:SetText('axe')
	eq(lit_dimmed(c), '1/17', 'Compact: only the Axe lit')
	for _, view in ipairs({ 'onebag', 'multibag', 'rows', 'compact' }) do
		switch(view)
		eq(lit_dimmed(c), '1/17', view .. ': the search still dims all but the Axe')
	end

	-- Typed in One bag, cleared in Compact: One bag comes back with no search.
	switch('onebag')
	search:SetText('rock')
	eq(lit_dimmed(c), '1/17', 'One bag: only the Rock lit')
	switch('compact')
	search:SetText('')
	eq(lit_dimmed(c), '18/0', 'Compact: no search, all lit')
	switch('onebag')
	eq(lit_dimmed(c), '18/0', 'One bag: no search, all lit')
	eq(#take_errors(), 0, 'no errors')
end)

test('Currencies is the last section in each view, its Filter button on its header, hidden when its hide flag is set', function()
	local c = world('compact')
	local currencies = c.categories.Currencies
	for _, view in ipairs({ 'onebag', 'multibag', 'rows' }) do
		switch(view)
		check(currencies:IsShown(), view .. ': Currencies shown')
		check(currencies.header:IsShown(), view .. ': titled')
		local filter = currencies.header.filterButton
		check(filter and filter:GetParent() == currencies.header, view .. ': its Filter button is on the header')
		check(filter:IsShown(), view .. ': shown')
		eq(currencies.filterButton, filter, view .. ': the one the section reads')
		local last = stack(c):match('([^|]+)$'):gsub('%s', '')
		eq(last, 'Currencies', view .. ': last')
		local lowest
		for name, frame in pairs(c.categories) do
			if frame:IsShown() and name ~= 'Currencies' then
				lowest = math.min(lowest or math.huge, frame:GetBottom())
			end
		end
		eq(currencies:GetTop(), lowest - sp, view .. ': one spacing under the last other section')
		eq(currencies.numRows, 2, view .. ': twelve currencies wrap at nine')

		INV.config.filters.categories.bag.Currencies = true
		INV:UpdateContainer('bag', true)
		check(not currencies:IsShown(), view .. ': hidden by its hide flag')
		for name, frame in pairs(c.categories) do
			if frame:IsShown() then check(name ~= 'Currencies', view .. ': no Currencies in the stack') end
		end
		INV.config.filters.categories.bag.Currencies = nil
		INV:UpdateContainer('bag', true)
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('onebag and multibag show items of categories hidden in the profile', function()
	local c = world('rows')
	INV.config.filters.categories.bag.Weapons = true
	INV:UpdateContainer('bag', true)
	check(not c.categories.Weapons:IsShown(), 'Rows hides Weapons (the test means something)')
	switch('onebag')
	check(slot_names(c.categories['view:main']):find('Axe'), 'One bag shows the Axe')
	check(slot_names(c.categories['view:main']):find('Sword'), 'and the Sword')
	switch('multibag')
	eq(slot_names(c.categories['view:bag1']), 'Axe,Sword,Plank', 'Multi bag shows the weapons in their bag')
	eq(#take_errors(), 0, 'no errors')
end)

test('onebag and multibag are as wide as rows', function()
	local c = world('rows')
	local width, scroll = c:GetWidth(), c.scrollFrame:GetWidth()
	for _, view in ipairs({ 'onebag', 'multibag', 'compact' }) do
		switch(view)
		eq(c:GetWidth(), width, view .. ': the window as wide as in Rows')
		eq(c.scrollFrame:GetWidth(), scroll, view .. ': and its scroll frame')
	end
	switch('onebag')
	eq(c.categories['view:main']:GetWidth(), line(9), 'One bag: sections a line of nine')
	switch('multibag')
	eq(c.categories['view:bag0']:GetWidth(), line(9), 'Multi bag: likewise')
	eq(c:GetWidth(), line(9) + padding * 2, 'and the padding')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ carried review items

test('no category frame is untitled in one view and titled in another', function()
	local c = world('compact', function() W.bag(3, 8, 'Empty Bag') end)
	INV.config.bag.emptySlots = 'grouped'
	local seen = {}
	local function note(view)
		for name, frame in pairs(c.categories) do
			if frame:IsShown() then
				local untitled = frame.untitled and true or false
				seen[name] = seen[name] or untitled
				eq(seen[name], untitled, ('%s: %s keeps its titled/untitled state'):format(view, name))
			end
		end
	end
	for _, view in ipairs({ 'compact', 'onebag', 'multibag', 'rows', 'onebag', 'multibag', 'compact' }) do
		switch(view)
		note(view)
	end
	-- A bag turning special (a family change) moves its items between the
	-- main grid and its own titled section: neither frame changes state.
	W.bags[1].family = 32
	switch('onebag')
	note('onebag, bag 1 special')
	check(c.categories['view:bag1']:IsShown() and c.categories['view:bag1'].header:IsShown(), 'bag 1 titled once special')
	W.bags[1].family = 0
	INV:UpdateContainer('bag', true)
	note('onebag, bag 1 normal again')
	eq(#take_errors(), 0, 'no errors')
end)

test('Multi bag, Every slot: a slot freed in combat shows at once on a button made beforehand', function()
	local c = world('multibag', function() INV.config.bag.emptySlots = 'all' end)
	local bag = c.categories['view:bag1']
	eq(shown_slots(bag), 16, 'the 3 items and 13 free slots')
	eq(empty_slots(bag), 13, 'free slots')

	stub.in_combat = true
	W.bags[1].items[2] = nil -- the Sword sold in the fight
	local made = H.frames_made()
	INV:UpdateContainer('bag', true)
	eq(H.frames_made(), made, 'no frame made in combat')
	eq(empty_slots(bag), 14, 'the freed slot shows at once')
	eq(shown_slots(bag), 16, 'the section is still its 16 slots')
	eq(bag.header.text:GetText(), 'Bag (2 / 16)', 'its title counts it')

	-- A bag that grows in the fight: free slots only as far as there are buttons.
	local buttons = #bag.slots
	W.bags[1].slots = buttons + 20
	INV:UpdateContainer('bag', true)
	eq(#bag.slots, buttons, 'no button made in combat')
	eq(shown_slots(bag), buttons, 'free slots up to the buttons it has')
	for _, frame in pairs(c.categories) do
		for _, slot in ipairs(frame.slots) do check(not slot.tainted, 'no broken slot') end
	end
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	INV:UpdateContainer('bag', true)
	eq(shown_slots(bag), buttons + 20, 'after combat, every free slot')
	eq(#take_errors(), 0, 'no errors')
end)

test('compact -> onebag -> multibag -> compact restores Compact exactly, with no new frames the second time', function()
	local c = world('compact')
	local where, snap = H.where(c), H.snapshot(c)
	local counts = {}
	for name, category in pairs(c.categories) do counts[name] = #category.slots end

	switch('onebag')
	check(c.categories['view:main']:IsShown(), 'One bag (the switch happened)')
	switch('multibag')
	check(c.categories['view:bag0']:IsShown() and not c.categories['view:main']:IsShown(), 'Multi bag')
	switch('compact')
	check(H.same(H.where(c), where), 'every category back in its column and place')
	check(H.same(H.snapshot(c), snap), 'every frame, slot and the window where they were')
	for name, category in pairs(c.categories) do
		if counts[name] then eq(#category.slots, counts[name], name .. ': the same slots') end
	end
	for name, category in pairs(c.categories) do
		if name:sub(1, 5) == 'view:' then check(not category:IsShown(), name .. ' hidden in Compact') end
	end
	for i, column in ipairs(c.columns) do check(column:IsShown(), 'column ' .. i .. ' back') end

	local before = H.frames_made()
	switch('multibag')
	switch('onebag')
	switch('compact')
	eq(H.frames_made(), before, 'no new frames on the second round')
	check(H.same(H.snapshot(c), snap), 'and Compact as it was')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ buttons in combat

-- Slots made in combat are broken (INV:CreateSlot flags and reports them).
local function made_in_combat(container)
	local n = 0
	for _, frame in pairs(container.categories) do
		for _, slot in ipairs(frame.slots) do if slot.tainted then n = n + 1 end end
	end
	return n
end

-- How many shown slots of a window hold an item whose name starts with prefix.
local function shown_named(container, prefix)
	local n = 0
	for _, frame in pairs(container.categories) do
		for _, slot in ipairs(frame.slots) do
			if slot:IsShown() and slot.info and not slot.info.empty and slot.info.name:sub(1, #prefix) == prefix then n = n + 1 end
		end
	end
	return n
end

test('One bag and Multi bag: eleven new items looted in one fight make no button, in the bag and the bank window', function()
	for _, view in ipairs({ 'onebag', 'multibag' }) do
		-- The bag window: loot fills bag 1 (13 free slots) first.
		local c = world(view)
		stub.in_combat = true
		for i = 1, 11 do W.put(1, 3 + i, W.item(700 + i, 'Loot ' .. i, 'Trade Goods', 10 + i)) end
		local made = H.frames_made()
		INV:UpdateContainer('bag', true)
		eq(H.frames_made(), made, view .. ', bags: no frame made in combat')
		eq(made_in_combat(c), 0, view .. ', bags: no broken slot')
		eq(shown_named(c, 'Loot '), 11, view .. ', bags: every new item shows at once')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')

		-- The bank window: Forever's base bank tab, 28 slots, one bar in it.
		local tab = INV.bagIds.bank[1]
		W.bag(tab, 28, 'Bank')
		W.put(tab, 1, W.item(501, 'Gold Bar', 'Trade Goods', 30))
		INV.config.bank.view = view
		local bank = H.window('bank')
		INV:UpdateContainer('bank', true)
		stub.in_combat = true
		for i = 1, 11 do W.put(tab, 1 + i, W.item(800 + i, 'Bar ' .. i, 'Trade Goods', 10 + i)) end
		made = H.frames_made()
		INV:UpdateContainer('bank', true)
		eq(H.frames_made(), made, view .. ', bank: no frame made in combat')
		eq(made_in_combat(bank), 0, view .. ', bank: no broken slot')
		eq(shown_named(bank, 'Bar '), 11, view .. ', bank: every new bar shows at once')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a section shows no more items than it has buttons, and the rest once combat ends', function()
	-- Multi bag: a bag that turns up in the fight with items in it has no
	-- buttons yet.
	local c = world('multibag')
	stub.in_combat = true
	W.bag(3, 8, 'New Bag')
	for i = 1, 5 do W.put(3, i, W.item(900 + i, 'Ore ' .. i, 'Trade Goods', 5)) end
	INV:UpdateContainer('bag', true)
	eq(made_in_combat(c), 0, 'Multi bag: no broken slot')
	eq(shown_named(c, 'Ore '), 0, "Multi bag: the new bag's items wait for the end of combat")
	stub.in_combat = false
	INV.NEED_UPDATE = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check(INV.NEED_UPDATE, 'Multi bag: after combat an update is asked for')
	INV:UpdateContainer('bag', true)
	eq(shown_named(c, 'Ore '), 5, 'Multi bag: then they show')
	eq(made_in_combat(c), 0, 'Multi bag: still no broken slot')

	-- Rows: a category given more new items in the fight than its spare buttons.
	c = world('rows')
	local goods = c.categories['Trade Goods']
	local buttons = #goods.slots
	stub.in_combat = true
	for i = 1, buttons do W.put(1, 3 + i, W.item(950 + i, 'Ingot ' .. i, 'Trade Goods', 5)) end
	INV:UpdateContainer('bag', true)
	eq(#goods.slots, buttons, 'Rows: no button made in combat')
	eq(shown_slots(goods), buttons, 'Rows: as many items as there are buttons')
	eq(made_in_combat(c), 0, 'Rows: no broken slot')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	INV:UpdateContainer('bag', true)
	eq(shown_slots(goods), buttons + 3, 'Rows: after combat, all of them')
	eq(#take_errors(), 0, 'no errors')
end)
