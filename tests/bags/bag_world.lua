-- What the bag data tests share (views_data_test.lua): a stubbed bag world on
-- the module's real files. Not a test (no _test suffix), so the runner doesn't
-- run it; load it with load_test_file('bags/bag_world.lua').
--
-- Real: SaftUI-Bags' config.lua, inventory.lua, filters.lua (the category
-- rules), category.lua, slot.lua, views.lua and tooltipscanner.lua.
--
-- Made by hand, for Blizzard API the stubs don't have, each as far as the real
-- code under test reads it:
--   - C_Container: bags of slots holding items, a bag name, a free count and a
--     bag family (W.bag, W.item below);
--   - GetAverageItemLevel (the Grays rule reads it for armor and weapons);
--   - the bag items bags are made of, as far as the special bags' titles read
--     them (W.bag_item below): C_Container.ContainerIDToInventoryID,
--     GetInventoryItemID and C_Item.GetItemInfoInstant's subtype;
--   - C_Item and ItemLocation, as far as INV:GetInventoryItemInfo reads them
--     (an item's name, class and quality, never its tooltip).
-- An item is a table of the fields INV:GetInventoryItemInfo and the category
-- rules read; W.item fills in the rest.

local W = {}

-- A fresh world. client is 'forever' (the default; no reagent bag) or 'retail'
-- (the reagent bag, bag 5 in the stubbed enum). Returns the Inventory module.
function W.fresh(client)
	client = client or 'forever'
	reset_world()
	stub.interface = client == 'retail' and 120000 or 16001
	-- constants.lua reads the interface when it loads, so load it again.
	load_saftui('SaftUI-Core/constants.lua')
	if client == 'forever' then
		-- Forever has no reagent bag. (The stubbed enum is retail's.)
		Enum.BagIndex.ReagentBag = nil
	end
	load_core_helpers()
	load_saftui('SaftUI-Core/Utilities/utilities.lua') -- slot.lua's module
	load_saftui('SaftUI-Bags/config.lua')
	apply_defaults()
	-- slot.lua post-hooks Blizzard's stack split button at load; it is also where
	-- the Grays rule's INV:IsProtected lives.
	_G.StackSplitFrameOkay_Click = function() end
	for _, file in ipairs({ 'inventory', 'tooltipscanner', 'filters', 'category', 'slot', 'views' }) do
		load_saftui('SaftUI-Bags/' .. file .. '.lua')
	end
	local INV = SaftUI:GetModule('Inventory')
	SaftUI:BindModuleConfig(INV, 'inventory')
	INV:InitializeTooltipScanner()
	W.INV = INV
	W.bags = {}
	W.stub_api()
	return INV
end

-- A bag: slots (how many), name, family (0 for a normal bag), and items[slot].
function W.bag(bagID, slots, name, family, items)
	W.bags[bagID] = { slots = slots, name = name, family = family or 0, items = items or {} }
end

-- The item a bag slot of the player holds (the bag itself, as the title bar's
-- slots show it): its item subtype, as GetItemInfoInstant answers it, localized
-- ("Reagent Bag", "Herb Bag"), or nil for an item that gives none. A bag with
-- no bag item (the default) has no item in its slot at all.
function W.bag_item(bagID, subtype, itemID)
	W.bags[bagID].bagItem = { itemID = itemID or 9000 + bagID, subtype = subtype }
end

-- An item as a bag slot holds it. Name and class are what the category rules
-- read; ilvl sorts it (the existing item sort is by the sort string).
function W.item(itemID, name, class, ilvl, extra)
	local item = { itemID = itemID, name = name, class = class or 'Miscellaneous',
		ilvl = ilvl or 1, quality = 1, count = 1, maxStack = 1 }
	for k, v in pairs(extra or {}) do item[k] = v end
	return item
end

-- Puts an item in a slot.
function W.put(bagID, slot, item) W.bags[bagID].items[slot] = item end

-- Makes the container the views read from the module's bag ids.
function W.container(id)
	local INV = W.INV
	INV.containers[id] = { bag_ids = INV.bagIds[id], categories = {}, id = id }
	return INV.containers[id]
end

function W.stub_api()
	_G.GetAverageItemLevel = function() return 100 end
	_G.C_Container = {
		GetContainerNumSlots = function(bagID) return W.bags[bagID] and W.bags[bagID].slots or 0 end,
		GetContainerNumFreeSlots = function(bagID)
			local bag = W.bags[bagID]
			if not bag then return 0, 0 end
			local used = 0
			for _ in pairs(bag.items) do used = used + 1 end
			return bag.slots - used, bag.family
		end,
		GetBagName = function(bagID) return W.bags[bagID] and W.bags[bagID].name end,
		-- The backpack has no inventory slot; every other bag has one, 500 + its id here.
		ContainerIDToInventoryID = function(bagID)
			if bagID == Enum.BagIndex.Backpack then error('no inventory slot for the backpack') end
			return 500 + bagID
		end,
		GetContainerItemLink = function() return nil end,
		GetContainerItemEquipmentSetInfo = function(bagID, slot)
			local item = W.bags[bagID].items[slot]
			if item and item.set then return true, item.set .. ',' end
			return false
		end,
		GetContainerItemInfo = function(bagID, slot)
			local item = W.bags[bagID] and W.bags[bagID].items[slot]
			if not item then return nil end
			return {
				hyperlink = '|Hitem:' .. item.itemID .. '|h[' .. item.name .. ']|h',
				stackCount = item.count, isBound = false, itemID = item.itemID,
				quality = item.quality, locked = false, iconFileID = 1, itemName = item.name,
			}
		end,
	}
	_G.GetInventoryItemID = function(unit, invID)
		local bag = unit == 'player' and W.bags[invID - 500]
		return bag and bag.bagItem and bag.bagItem.itemID
	end
	local function bagItemByID(itemID)
		for _, bag in pairs(W.bags) do
			if bag.bagItem and bag.bagItem.itemID == itemID then return bag.bagItem end
		end
	end
	local function itemByLink(link)
		local id = tonumber(link:match('item:(%d+)'))
		for _, bag in pairs(W.bags) do
			for _, item in pairs(bag.items) do
				if item.itemID == id then return item end
			end
		end
	end
	_G.C_Item = {
		GetItemInfo = function(link)
			local item = itemByLink(link)
			if not item or item.loading then return nil end
			-- name, link, quality, ilvl, reqLevel, class, subclass, stackCount,
			-- equipSlot, texture, vendorPrice, classID, subclassID, bindType, expacID
			return item.name, link, item.quality, 0, 0, item.class, item.subclass, 1,
				nil, 1, 10, 0, 0, 0, 0
		end,
		GetDetailedItemLevelInfo = function(link)
			local item = itemByLink(link)
			return item and item.ilvl
		end,
		IsBound = function() return false end,
		-- itemID, type, subtype, equipLoc, icon, classID, subclassID
		GetItemInfoInstant = function(itemID)
			local bagItem = bagItemByID(itemID)
			if not bagItem then return nil end
			return itemID, 'Container', bagItem.subtype, 'INVTYPE_BAG', 1, 1, 0
		end,
		GetItemMaxStackSize = function() return 1 end,
	}
	-- GetItemMaxStackSize takes the item's location, which carries its bag and slot.
	_G.ItemLocation = { CreateFromBagAndSlot = function(_, bagID, slot) return { bagID = bagID, slot = slot } end }
	C_Item.GetItemMaxStackSize = function(location)
		local item = W.bags[location.bagID].items[location.slot]
		return item and item.maxStack or 1
	end
	Enum.ItemBind = Enum.ItemBind or { OnUse = 2, OnEquip = 2 }
end

return W
