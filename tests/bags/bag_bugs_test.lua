-- Five bugs in SaftUI-Bags, each with the check that failed before its fix:
-- closing the bags clears the new-item glow (containers/bag.lua), a currency
-- slot's shift-click links its currency (currencies.lua), a nil or hidden
-- window isn't updated (container.lua), the item sort reads the fields the
-- game gives (category.lua), and a slot made for a missing category says so
-- (slot.lua). bags/bag_world.lua's bags under bags/container_helpers.lua's
-- views world, with the real containers/bag.lua.
local H = load_test_file('bags/container_helpers.lua')

local INV, W

local function world()
	INV, W = H.views_world('forever')
	load_saftui('SaftUI-Bags/containers/bag.lua')
	W.bag(0, 20, 'Backpack')
	INV.config.bag.view = 'compact'
	INV.config.bag.emptySlots = 'off'
	local container = H.window('bag')
	return container
end

-- The slots of a window, in the order its categories hold them, by item name.
local function names(items)
	local out = {}
	for _, item in ipairs(items) do out[#out + 1] = item.name .. ':' .. item.count .. ':' .. item.itemID end
	return table.concat(out, ' ')
end

test('closing the bags clears the new-item glow of every item slot', function()
	local container = world()
	W.put(0, 1, W.item(101, 'Ore', 'Miscellaneous', 1))
	W.put(0, 3, W.item(102, 'Rock', 'Quest', 5))
	INV:UpdateContainer('bag', true)
	-- WoW's C_NewItems isn't stubbed: a recorder of the calls.
	local cleared = {}
	_G.C_NewItems = { RemoveNewItem = function(bagID, slotID) cleared[#cleared + 1] = bagID .. ':' .. slotID end }
	INV:HideBags()
	table.sort(cleared)
	eq(table.concat(cleared, ' '), '0:1 0:3', 'RemoveNewItem ran for each filled slot')
	check(not container:IsShown(), 'the window is hidden')
	eq(#take_errors(), 0, 'no errors')
end)

test('a shift-click on a currency slot links that currency', function()
	world()
	local linked = {}
	-- Blizzard's own: the link goes into the chat box. A recorder.
	_G.HandleModifiedItemClick = function(link) linked[#linked + 1] = link end
	-- The default key binding of the chat link click is Shift.
	_G.IsModifiedClick = function(action) return action == 'CHATLINK' and IsShiftKeyDown() end
	C_CurrencyInfo.GetCurrencyListLink = function(index) return 'currency-link-' .. index end
	local slot = { currencyIndex = 7, elementData = { currencyIndex = 7, currencyID = 1000 } }
	stub.shift_down = true
	INV:CurrencyOnClick(slot)
	stub.shift_down = false
	eq(#linked, 1, 'one link')
	eq(linked[1], 'currency-link-7', "the slot's currency")
	eq(#take_errors(), 0, 'no errors')
end)

test('UpdateContainer: no window returns, a hidden one is not laid out', function()
	local container = world()
	W.put(0, 1, W.item(101, 'Ore', 'Miscellaneous', 1))
	INV:UpdateContainer('bag', true)
	INV.containers.nope = nil
	INV:UpdateContainer('nope', true)
	eq(#take_errors(), 0, 'a window that does not exist is no error')

	local layouts = 0
	local layout = INV.UpdateContainerLayout
	INV.UpdateContainerLayout = function(...) layouts = layouts + 1 return layout(...) end
	container:Hide()
	W.put(0, 2, W.item(102, 'Rock', 'Quest', 5))
	INV:UpdateContainer('bag', true)
	eq(layouts, 0, 'a hidden window is not laid out')
	local sorted = INV:GetSortedInventory('bag')
	local count = 0
	for _, items in pairs(sorted) do count = count + #items end
	eq(count, 2, 'the read itself sees both items')
	local shown = 0
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			if slot:IsShown() and slot.info and slot.info.name == 'Rock' then shown = shown + 1 end
		end
	end
	eq(shown, 0, 'the item that came while it was hidden has no slot yet')

	-- The first update, which makes every slot before the window opens, asks
	-- for it by name.
	INV:UpdateContainer('bag', nil, true)
	check(#container.categories.Quest.slots > 0, 'asked for while hidden, its slots are made')
	container:Show()
	INV:UpdateContainer('bag', true)
	eq(layouts > 0, true, 'a shown window is laid out')
	INV.UpdateContainerLayout = layout
	eq(#take_errors(), 0, 'no errors')
end)

test('the item sort: bigger stacks first, then the higher item ID', function()
	world()
	-- Two stacks of one item, the smaller in the first slot.
	W.put(0, 1, W.item(501, 'Ore', 'Miscellaneous', 1, { count = 3, maxStack = 20 }))
	W.put(0, 2, W.item(501, 'Ore', 'Miscellaneous', 1, { count = 5, maxStack = 20 }))
	INV.config.stackItems = false
	local sorted = INV:GetSortedInventory('bag')
	eq(names(sorted.Miscellaneous), 'Ore:5:501 Ore:3:501', 'the 5 stack before the 3 stack')

	-- Two items equal on everything before the count: the ID decides.
	W.bags[0].items = {}
	W.put(0, 1, W.item(601, 'Twin', 'Miscellaneous', 1))
	W.put(0, 2, W.item(602, 'Twin', 'Miscellaneous', 1))
	sorted = INV:GetSortedInventory('bag')
	eq(names(sorted.Miscellaneous), 'Twin:1:602 Twin:1:601', 'the higher ID first')
	eq(#take_errors(), 0, 'no errors')
end)

test('CreateSlot for a category that does not exist says so', function()
	local container = world()
	local ok, err = pcall(INV.CreateSlot, INV, container, 'No Such Category')
	check(not ok, 'it errors')
	check(tostring(err):find('Category "No Such Category" does not exist', 1, true), 'with the assert message, got: ' .. tostring(err))
end)
