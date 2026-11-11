-- Auto vendor (SaftUI-Bags/autovendor.lua): INV:GetVendorItems reads the bags,
-- not the category frames, so it gives the same items, every stack and the same
-- profit in Compact, Rows, One bag and Multi bag (the last two flush the
-- Grays/Auto Vendor frame); a protected item is never sold; the footer's
-- Vendor profit line shows the same in every view.
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
local function sold()
	local items, profit = INV:GetVendorItems()
	local out = {}
	for _, info in ipairs(items) do
		out[#out + 1] = info.bagID .. ':' .. info.slotID .. '=' .. info.stackPrice
	end
	table.sort(out)
	return table.concat(out, ' '), profit
end

local function slot_of(container, name)
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			if slot:IsShown() and slot.info and slot.info.name == name then return slot end
		end
	end
end

-- INV:VendorCategory sold every slot of a category frame with none of
-- INV:IsAutoVendorItem's checks. Nothing called it.
test('auto vendor sells only through GetVendorItems: VendorCategory is gone', function()
	world('compact')
	check(INV.VendorCategory == nil, 'VendorCategory is gone')
	check(type(INV.AutoVendor) == 'function' and type(INV.GetVendorItems) == 'function', 'AutoVendor and GetVendorItems stay')
end)

for _, view in ipairs(VIEWS) do
	for _, merge in ipairs({ false, true }) do
		test(view .. (merge and ', merged stacks' or '') .. ': GetVendorItems gives every stack of every sellable item', function()
			world(view)
			INV.config.stackItems = merge
			INV:UpdateContainer('bag', true)
			local items, profit = sold()
			eq(items, '0:1=50 0:2=30 1:1=40', 'both ore stacks and the cloth; not the protected gray, the rock or the tonic')
			eq(profit, 120, 'the profit is the sum of every stack')
			eq(#take_errors(), 0, 'no errors')
		end)
	end

	test(view .. ': a protected item is never included, and unprotecting includes it', function()
		world(view)
		INV.config.protectFilter[503] = nil
		INV:UpdateContainer('bag', true)
		local items = sold()
		check(items:find('0:3=', 1, true), 'the item is sold once unprotected')
		INV.config.protectFilter[503] = true
		INV:UpdateContainer('bag', true)
		check(not sold():find('0:3=', 1, true), 'and not again once protected')
	end)

	test(view .. ": the footer's Vendor profit line", function()
		world(view)
		local lines = {}
		_G.GameTooltip = _G.GameTooltip or CreateFrame('Frame', 'GameTooltip', UIParent)
		for _, method in ipairs({ 'SetOwner', 'ClearAllPoints', 'SetPoint', 'ClearLines', 'AddLine', 'Show' }) do
			GameTooltip[method] = GameTooltip[method] or function() end
		end
		GameTooltip.AddDoubleLine = function(_, left, right) lines[left] = right end
		-- The gold formatter is a library the world doesn't load: say the amount.
		SaftUI.StringFormat = { GoldFormat = function(_, money) return 'gold ' .. money end }
		SaftUI.config.realm = SaftUI.config.realm or {}
		SaftUI.config.realm.summary = SaftUI.config.realm.summary or {}
		INV.HasWarbandBank = function() return false end
		INV:DisplayServerGold()
		eq(lines['Vendor profit'], 'gold 120', 'the same profit in every view')
	end)
end
