-- The junk coin on item slots (SaftUI-Bags/slot.lua's INV:AssignSlot):
-- Blizzard's own JunkIcon, shown on exactly the slots whose item INV:GetVendorItems
-- would sell, in every view, at a merchant or not, and following the Protected
-- and Auto Vendor marks on the next update.
-- bags/bag_world.lua's bags under bags/container_helpers.lua's views world.
local H = load_test_file('bags/container_helpers.lua')

local INV, W

local VIEWS = { 'compact', 'rows', 'onebag', 'multibag' }

-- The backpack holds a gray ore in two stacks (5 and 3) and a protected gray;
-- bag 1 holds a second gray and two ordinary items. The stub vendor price is
-- 10 a unit, so the ore is worth 80 and the other gray 40.
local function world(view)
	INV, W = H.views_world('forever')
	load_saftui('SaftUI-Bags/autovendor.lua')
	W.bag(0, 20, 'Backpack')
	W.bag(1, 16, 'Bag')
	W.put(0, 1, W.item(501, 'Gray Ore', 'Miscellaneous', 1, { quality = 0, count = 5, maxStack = 20 }))
	W.put(0, 2, W.item(501, 'Gray Ore', 'Miscellaneous', 1, { quality = 0, count = 3, maxStack = 20 }))
	W.put(0, 3, W.item(503, 'Kept Gray', 'Miscellaneous', 1, { quality = 0 }))
	W.put(0, 4, W.item(150, 'Rock', 'Quest', 5))
	W.put(1, 1, W.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0, count = 4 }))
	W.put(1, 2, W.item(110, 'Tonic', 'Consumable', 30))
	INV.config.bag.view = view
	INV.config.bag.emptySlots = 'off'
	INV.config.protectFilter = { [503] = true }
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

-- The vendor items as "bag:slot=price" sorted, and the profit.
local function slot_of(container, name)
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			if slot:IsShown() and slot.info and slot.info.name == name then return slot end
		end
	end
end

for _, view in ipairs(VIEWS) do
	test(view .. ': the junk coin is on the slots auto vendor sells, and only those', function()
		local c = world(view)
		local function coin(name)
			local slot = slot_of(c, name)
			check(slot, name .. ' has a slot')
			return slot and slot.JunkIcon:IsShown()
		end
		eq(coin('Gray Cloth'), true, 'a sellable gray shows the coin')
		eq(coin('Gray Ore'), true, 'so does a stack of one')
		eq(coin('Kept Gray'), false, 'a protected gray does not')
		eq(coin('Rock'), false, 'an ordinary item does not')
		eq(coin('Tonic'), false, 'nor another')
		INV.config.protectFilter[503] = nil
		INV.config.protectFilter[110] = true
		INV:UpdateContainer('bag', true)
		eq(coin('Kept Gray'), true, 'unprotecting shows it on the next update')
		eq(coin('Tonic'), false, 'protecting an ordinary item changes nothing')
		INV.config.protectFilter[502] = true
		INV:UpdateContainer('bag', true)
		eq(coin('Gray Cloth'), false, 'protecting a sellable gray hides it')
		eq(#take_errors(), 0, 'no errors')
	end)
end

-- The coin reads the category the data step already worked out (info.category,
-- set by INV:ReadBags), so a full update categorizes each item once.
for _, view in ipairs({ 'compact', 'multibag' }) do
	test(view .. ': one full layout asks for each item\'s category once', function()
		world(view)
		INV.config.stackItems = false
		local calls = 0
		local real = INV.GetItemCategory
		INV.GetItemCategory = function(self, info) calls = calls + 1 return real(self, info) end
		INV:UpdateContainer('bag', true)
		INV.GetItemCategory = real
		eq(calls, 6, 'once for each of the six items in the bags')
		eq(#take_errors(), 0, 'no errors')
	end)
end
