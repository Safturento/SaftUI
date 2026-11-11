-- What the bag data tests share (views_data_test.lua): a stubbed bag world on
-- the module's real files. Not a test (no _test suffix), so the runner doesn't
-- run it; load it with load_test_file('bags/bag_world.lua').
--
-- Real: SaftUI-Bags' config.lua, inventory.lua, itemclasses.lua, rules.lua,
-- categorydefaults.lua and categories.lua (the categories and their rules),
-- tooltipscanner.lua, category.lua, slot.lua and views.lua.
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
--     (GetItemInfo's 17 values, the item classes of the world's client, and
--     whether an item is bound);
--   - C_TooltipInfo.GetBagItem: an item's tooltip lines, by item.tooltip.
-- An item is a table of the fields INV:GetInventoryItemInfo and the category
-- rules read; W.item fills in the rest. Fields beyond name, class and ilvl:
--   link (else |Hitem:<id>|h[<name>]|h; tooltips are cached by link, so items
--   with different tooltips need different ids), tooltip (a list of strings
--   or { left, right } pairs), tooltipLoading (GetBagItem gives nothing),
--   subclass, classID, subclassID (the names and ids a client's item classes
--   give; either may be set), quality, reqLevel, equipLoc, vendorPrice (10),
--   bindType, expacID, isCraftingReagent, isBound, accountUntilEquip, set.

local W = {}

-- A fresh world. client is 'forever' (the default; no reagent bag) or 'retail'
-- (the reagent bag, bag 5 in the stubbed enum). Returns the Inventory module.
function W.fresh(client)
	client = client or 'forever'
	W.client = client
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
	-- slot.lua post-hooks Blizzard's stack split button at load.
	_G.StackSplitFrameOkay_Click = function() end
	for _, file in ipairs({ 'inventory', 'itemclasses', 'rules', 'categorydefaults', 'categories', 'tooltipscanner', 'category',
		'slot', 'views' }) do
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

-- An item's link: its own, else the item link of its id and name.
function W.link(item)
	return item.link or ('|Hitem:' .. item.itemID .. '|h[' .. item.name .. ']|h')
end

-- Puts an item in a slot.
function W.put(bagID, slot, item) W.bags[bagID].items[slot] = item end

-- Makes the container the views read from the module's bag ids.
function W.container(id)
	local INV = W.INV
	INV.containers[id] = { bag_ids = INV.bagIds[id], categories = {}, id = id }
	return INV.containers[id]
end

-- The item classes of the world's client, and of the other one.
local CLASSES = load_test_file('bags/fixtures/item_classes.lua')

local function other_client() return W.client == 'retail' and 'forever' or 'retail' end

-- The id of a class or subclass name in the world's client, else in the other
-- one (so W.item(id, name, 'Trade Goods') still works in a retail world).
local function class_id_by_name(name)
	for _, client in ipairs({ W.client, other_client() }) do
		for id, n in pairs(CLASSES[client].classes) do
			if n == name then return id end
		end
	end
end

local function subclass_id_by_name(classID, name)
	for _, client in ipairs({ W.client, other_client() }) do
		for id, n in pairs(CLASSES[client].subclasses[classID] or {}) do
			if n == name then return id end
		end
	end
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
		GetContainerItemLink = function(bagID, slot)
			local item = W.bags[bagID] and W.bags[bagID].items[slot]
			return item and W.link(item)
		end,
		GetContainerItemEquipmentSetInfo = function(bagID, slot)
			local item = W.bags[bagID].items[slot]
			if item and item.set then return true, item.set .. ',' end
			return false
		end,
		GetContainerItemInfo = function(bagID, slot)
			local item = W.bags[bagID] and W.bags[bagID].items[slot]
			if not item then return nil end
			return {
				hyperlink = W.link(item),
				stackCount = item.count, isBound = item.isBound or false, itemID = item.itemID,
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
		for _, bag in pairs(W.bags) do
			for _, item in pairs(bag.items) do
				if W.link(item) == link then return item end
			end
		end
	end
	local function tooltipData(item)
		if not item or item.tooltipLoading then return nil end
		local lines = {}
		for _, line in ipairs(item.tooltip or {}) do
			if type(line) == 'table' then
				lines[#lines + 1] = { leftText = line[1], rightText = line[2] }
			else
				lines[#lines + 1] = { leftText = line }
			end
		end
		return { lines = lines }
	end
	-- { lines = { { leftText, rightText } } }, or nothing while the item's
	-- tooltip is loading (item.tooltipLoading). GetHyperlink is what Core's
	-- Utilities:ScanItemLink reads (the upgrade level on a slot).
	_G.C_TooltipInfo = {
		GetBagItem = function(bagID, slot)
			return tooltipData(W.bags[bagID] and W.bags[bagID].items[slot])
		end,
		GetHyperlink = function(link) return tooltipData(itemByLink(link)) end,
	}
	local function itemAt(location) return W.bags[location.bagID].items[location.slot] end
	_G.C_Item = {
		GetItemInfo = function(link)
			-- Keystones and caged pets are not items to the client: no info.
			if not link:find('^|Hitem:') then return nil end
			local item = itemByLink(link)
			if not item or item.loading then return nil end
			-- Given ids, the names come from the world's client; given names, the
			-- ids come from the tables (this client's, else the other's).
			local classID, subclassID = item.classID, item.subclassID
			local class, subclass = item.class, item.subclass
			if classID == nil then classID = class_id_by_name(class) end
			if class == nil or item.classID ~= nil then class = CLASSES[W.client].classes[classID] end
			if subclassID == nil then
				subclassID = subclass and subclass_id_by_name(classID, subclass) or 0
			end
			if subclass == nil or item.subclassID ~= nil then
				subclass = (CLASSES[W.client].subclasses[classID] or {})[subclassID]
			end
			-- name, link, quality, ilvl, reqLevel, class, subclass, stackCount,
			-- equipLoc, texture, vendorPrice, classID, subclassID, bindType,
			-- expacID, setID, isCraftingReagent
			return item.name, link, item.quality, 0, item.reqLevel or 0, class, subclass, 1,
				item.equipLoc, 1, item.vendorPrice == nil and 10 or item.vendorPrice,
				classID or 0, subclassID, item.bindType or 0, item.expacID or 0, nil,
				item.isCraftingReagent
		end,
		GetItemClassInfo = function(classID) return CLASSES[W.client].classes[classID] end,
		GetItemSubClassInfo = function(classID, subclassID)
			return (CLASSES[W.client].subclasses[classID] or {})[subclassID]
		end,
		GetDetailedItemLevelInfo = function(link)
			local item = itemByLink(link)
			return item and item.ilvl
		end,
		IsBound = function(location) return itemAt(location).isBound or false end,
		IsBoundToAccountUntilEquip = function(location) return itemAt(location).accountUntilEquip or false end,
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
