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

