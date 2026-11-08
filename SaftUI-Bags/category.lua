local st = SaftUI
local INV = st:GetModule('Inventory')

INV.CATEGORY_SLOT_POOL = 10
INV.EMPTY_SLOTS_CATEGORY = 'Empty Slots'

-- Whether a bag ID is the reagent bag. Guarded because the enum entry only
-- exists on clients that have a reagent bag.
function INV:IsReagentBag(bagID)
	return Enum.BagIndex ~= nil and Enum.BagIndex.ReagentBag ~= nil and bagID == Enum.BagIndex.ReagentBag
end

local upgradeQualities = {
	Adventurer = 1,
	Veteran = 2,
	Champion = 3,
	Hero = 4,
	Myth = 5,
}

--tests an item against all categories and returns the first one that meets the criteria.
--itemID,name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText
function INV:GetItemCategory(info)
	if st.retail and (info.class == 'Armor' or info.class == 'Weapon') then
		local isItemInSet, itemSetList = C_Container.GetContainerItemEquipmentSetInfo(info.bagID, info.slotID)
		if isItemInSet then
			return 'Set: ' .. select(1, strsplit(',', itemSetList))
		end
	end

	 --Reagent bag gets special categories
	if info.bagID == REAGENTBANK_CONTAINER then
		return info.subclass or "Other"
	end

	for i, category in ipairs(self.filters.categories) do
		if category.func(info) then
			return category.name
		end
	end

	-- not all items will fit a category, place those items in Miscellaneous
	return "Miscellaneous"
end

--function INV:UpdateItemRackCategories()
--	if not ItemRackUser then return end
--	local categories = {}
--
--	for set_name, set_items in pairs(ItemRackUser.Sets) do
--		if not (set_name:sub(1,1) == '~') then
--			local category = {
--				name = 'ItemRack: '..set_name,
--				items = {},
--			}
--
--			for slot_id, item_link in pairs(set_items.equip) do
--				category.items['item:'..item_link] = true
--			end
--
--			category.func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot)
--				local item_string = string.match(link, "item[%-?%d:]+")
--				return category.items[item_string]
--			end
--
--			tinsert(categories, category)
--		end
--	end
--
--	self.filters.itemrack = categories
--
--	self:QueueUpdate()
--end

function INV:GetInventoryItemInfo(bagID, slotID, containerId)
	local item = C_Container.GetContainerItemInfo(bagID, slotID)
	if item then
		local tooltipText = self:ScanBagItem(bagID, slotID)
		local name, _, quality, _, reqLevel, class, subclass, _, equipSlot, texture, vendorPrice,
			itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = C_Item.GetItemInfo(item.hyperlink)
		local itemLevel = C_Item.GetDetailedItemLevelInfo(item.hyperlink)
		if not name then
			local itemString = select(3, strfind(item.hyperlink, "|H(.+)|h"))
			local itemType, itemId = string.split(':', itemString)

			if itemType == "keystone" then
				--StaticPopup_Show("EXTRACT_LINK_DIALOG", nil, nil, item.hyperlink)
				--\124cnIQ4:\124Hkeystone:180653:504:11:162:10:9:0:0\124h[Keystone: Darkflame Cleft (11)]\124h\124r

				_, _, _, keyLevel =  string.split(':', itemString)

				name = item.itemName
				class = 'Key'
				vendorPrice = 0
				texture = item.iconFileID
				item.stackCount = tonumber(keyLevel)
				quality = 4

			elseif itemType == 'battlepet' then
				--petlink = string.format("%s|Hbattlepet:%s:%s:%s:%s:%s:%s|h[%s]|h|r", ITEM_QUALITY_COLORS[quality].hex, speciesID, level, quality, health, power, speed, name)
				--speciesID, level, quality, health, power, speed, name =  string.split(':', itemString)
				local petLevel =  select(3, string.split(':', itemString))

				name = item.itemName
				class='Battle Pet'
				item.stackCount = tonumber(petLevel)
				vendorPrice = 0
				quality = item.quality
				texture = item.iconFileID
			end
		end

		if name then
			local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)

			return {
				name = name,
				ilvl = itemLevel,
				reqLevel = reqLevel,
				isWarbound = (C_Item.IsBoundToAccountUntilEquip and C_Item.IsBoundToAccountUntilEquip(itemLocation) and not C_Item.IsBound(itemLocation))
						or string.matchnocase(tooltipText, "Warbound"),
				--bindType == Enum.ItemBind.ToBnetAccount
				--		  or bindType == Enum.ItemBind.ToWoWAccount
				--		  or bindType == Enum.ItemBind.ToBnetAccountUntilEquipped,
				isBoE = (not item.isBound) and (bindType == Enum.ItemBind.OnUse
						or bindType == Enum.ItemBind.OnEquip),
				isSoulbound = item.isBound,
				count = item.stackCount,
				--upgradeInfo = upgradeInfo,
				itemID = item.itemID,
				unitPrice = vendorPrice,
				stackPrice = vendorPrice * item.stackCount,
				link = item.hyperlink,
				quality = quality or 0,
				class = class,
				subclass = subclass,
				maxStack = C_Item.GetItemMaxStackSize(itemLocation) or 1,
				equipSlot = _G[equipSlot],
				expacID = expacID,
				vendorPrice = vendorPrice,
				texture = texture or item.iconFileId,
				locked = item.locked,
				container = containerId,
				bagID = bagID,
				slotID = slotID,
				tooltipText = tooltipText,
				sortString = (itemLevel or 0) .. name .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (item.itemCount or 0) .. (item.itemId or 0),
			}
		else
			return {
				loading = true
			}
		end
	end
end


local function sortCategory(a,b) return a.sortString > b.sortString end

-- The info for a free bag slot. It carries the fields the readers of slot.info
-- use (vendor price, name, tooltip text) as harmless blanks, and `empty` so
-- code that cares can tell it from an item. `count` is only set on a grouped
-- slot, where it is how many free slots of that kind there are.
local function GetEmptySlotInfo(bagID, slotID, containerId)
	return {
		empty = true,
		name = '',
		tooltipText = '',
		sortString = '',
		vendorPrice = 0,
		stackPrice = 0,
		container = containerId,
		bagID = bagID,
		slotID = slotID,
	}
end

-- Makes sure the Empty Slots category has a button for every bag slot when the
-- setting is 'all' (Every slot). Buttons made in combat are flagged as broken (see
-- CreateSlot), and a fight can free any number of slots, so they are all made
-- ahead of time, out of combat. Runs on every bag update, so a bigger bag
-- being equipped is covered too.
function INV:EnsureEmptySlotPool()
	local container = self.containers.bag
	if not container or self.config.bag.emptySlots ~= 'all' then return end

	local category = container.categories[self.EMPTY_SLOTS_CATEGORY]
	if not category then return end

	local total = 0
	for _, bagID in pairs(container.bag_ids) do
		total = total + C_Container.GetContainerNumSlots(bagID)
	end
	if #category.slots >= total then return end

	if st:QueueAfterCombat('InventoryEmptySlotPool', function()
		INV:EnsureEmptySlotPool()
		INV:QueueUpdate(true)
	end) then return end

	for _ = #category.slots + 1, total do
		self:CreateSlot(container, self.EMPTY_SLOTS_CATEGORY)
	end
end

function INV:GetSortedInventory(id)
	local container = self.containers[id]
	if not container then 
		st:Error('container with id ', id, 'not found')
	end

    local cachedItems = {}

	-- Free slots only show in the bag window, and only when asked for.
	local emptyMode = id == 'bag' and self.config.bag.emptySlots
	if emptyMode ~= 'grouped' and emptyMode ~= 'all' then emptyMode = nil end
	local emptyNormal, emptyReagent = {}, {}
	local numFreeNormal, numFreeReagent = 0, 0

	local inventory = {}
	local numItems = 0
	local numLoading = 0
	for _,bagID in pairs(container.bag_ids) do
		-- The reagent bag is its own kind of bag: the same item in it and in a
		-- normal bag stays two slots when stacks are merged.
		local isReagent = self:IsReagentBag(bagID)
		for slotID=1, C_Container.GetContainerNumSlots(bagID) do
			local item = self:GetInventoryItemInfo(bagID, slotID, id)
			if item then
				numItems = numItems + 1
				if item.loading then
					numLoading = numLoading + 1
				else
					local categoryName = self:GetItemCategory(item)

					if not inventory[categoryName] then inventory[categoryName] = {} end
					local mergeKey = tostring(item.itemID) .. (isReagent and ':reagent' or ':bag')
					if self.config.stackItems and cachedItems[mergeKey] and item.maxStack > 1 then
                        local cachedItem = cachedItems[mergeKey]
                        inventory[categoryName][cachedItem.index].count
                            = inventory[categoryName][cachedItem.index].count + item.count
					else
                        tinsert(inventory[categoryName], item)
                        if self.config.stackItems and not cachedItems[mergeKey] and item.maxStack > 1 then
                            cachedItems[mergeKey] = {
                                index = #inventory[categoryName],
                            }
                        end
                    end
				end
			elseif emptyMode then
				-- Grouped only needs the first free slot of each kind; every
				-- slot needs them all.
				if isReagent then
					numFreeReagent = numFreeReagent + 1
				else
					numFreeNormal = numFreeNormal + 1
				end
				local list = isReagent and emptyReagent or emptyNormal
				if emptyMode == 'all' or #list == 0 then
					tinsert(list, GetEmptySlotInfo(bagID, slotID, id))
				end
			end
		end
	end

	-- Normal bags first, then the reagent bag. This category isn't sorted below,
	-- so it keeps that order.
	if emptyMode == 'all' then
		local empties = {}
		for _, info in ipairs(emptyNormal) do tinsert(empties, info) end
		for _, info in ipairs(emptyReagent) do tinsert(empties, info) end
		-- In combat no button can be made, so show only as many as exist; the
		-- queued pool top-up asks for a full update when combat ends.
		local made = container.categories[self.EMPTY_SLOTS_CATEGORY]
		if made and InCombatLockdown() then
			for i = #empties, #made.slots + 1, -1 do empties[i] = nil end
		end
		if #empties > 0 then inventory[self.EMPTY_SLOTS_CATEGORY] = empties end
	elseif emptyMode == 'grouped' then
		-- One slot per kind of bag, pointing at its first free slot, so an item
		-- dropped on it lands there. A kind with no free slots has no slot.
		local empties = {}
		for kind, list in ipairs({ emptyNormal, emptyReagent }) do
			if #list > 0 then
				list[1].count = kind == 1 and numFreeNormal or numFreeReagent
				tinsert(empties, list[1])
			end
		end
		if #empties > 0 then inventory[self.EMPTY_SLOTS_CATEGORY] = empties end
	end

	for categoryName,categoryItems in pairs(inventory) do
		if #categoryItems > 1 and categoryName ~= self.EMPTY_SLOTS_CATEGORY then
			table.sort(categoryItems, sortCategory)
		end
	end

	return inventory, numItems, numLoading
end

function INV:CreateCategory(id, categoryName, slotPoolFunc)
	local container = self.containers[id]

	local categoryFrame = CreateFrame('frame', container:GetName() .. '_' .. categoryName, container.scrollFrame.ScrollChild)
	categoryFrame.container = container
	categoryFrame.name = categoryName
	categoryFrame:SetWidth(container:GetWidth() - self.config.padding * 2)
	categoryFrame.slots = {}
	if slotPoolFunc then
		categoryFrame.slotPool = slotPoolFunc(categoryFrame)
	else
		categoryFrame.slotPool = CreateObjectPool(
			function() return INV:CreateSlot(container, categoryName) end,
			function(_, slot) INV:ClearSlot(slot) end
		)
	end

	local header = CreateFrame('Button', nil, categoryFrame)
	header:SetHeight(self.config.categoryTitleHeight)
	header:SetPoint('TOPLEFT', categoryFrame)
	header:SetPoint('TOPRIGHT', categoryFrame)

	header.text = header:CreateFontString(nil, 'OVERLAY')
	header.text:SetFontObject(st:GetFont(st.config.profile.inventory.fonts.titles))
	header.text:SetPoint('BOTTOMLEFT', 2, 2)
	header.text:SetText(categoryName)
	categoryFrame.header = header

	local filterCheckbox = st:CreateCheckButton(nil, categoryFrame)
    filterCheckbox:Hide()
    filterCheckbox:SetSize(8, 8)
    filterCheckbox:SetPoint('BOTTOM', header, 'BOTTOM', 0, 4)
    filterCheckbox:SetPoint('LEFT', header.text, 'RIGHT', 8, 0)
    filterCheckbox:HookScript('OnClick', function(self)
        INV.config.filters.categories[id][categoryName] = self:GetChecked() or nil
		INV:UpdateContainerLayout(id)
    end)
	filterCheckbox:SetChecked(INV.config.filters.categories[id][categoryName])
	categoryFrame.filterCheckbox = filterCheckbox

	container.categories[categoryName] = categoryFrame

	return categoryFrame
end

function INV:UpdateCategory(id, categoryName, categoryItems)
	local container = self.containers[id]

	local categoryFrame = container.categories[categoryName] or self:CreateCategory(id, categoryName)
	categoryFrame:Show()

	-- Hide any visible icons that are no longer in use
	for i = #categoryItems + 1, #categoryFrame.slots do
		if categoryFrame.slots[i].info then self:ClearSlot(categoryFrame.slots[i]) end
	end

	-- A grouped empty slot stands for several free slots, so count those.
	local numShown = #categoryItems
	if categoryName == self.EMPTY_SLOTS_CATEGORY then
		numShown = 0
		for _, item in pairs(categoryItems) do numShown = numShown + (item.count or 1) end
	end
	categoryFrame.header.text:SetFormattedText("%s (%d)", categoryName, numShown)

	for i, item in pairs(categoryItems) do
		local slot = categoryFrame.slots[i] or self:CreateSlot(container, categoryName)
		self:AssignSlot(container, slot, item)
	end

	-- Ensure that there's always a decent slot pool created to avoid
	-- tainting in combat
	if not InCombatLockdown() then
		for i = #categoryFrame.slots - #categoryItems + 1 , INV.CATEGORY_SLOT_POOL do
			self:CreateSlot(container, categoryName)
		end
	end

	local numRows = math.ceil(#categoryItems/self.config[id].perrow)
	categoryFrame.numRows = numRows
	categoryFrame:SetHeight((self:GetButtonHeight() + self.config.buttonspacing) * numRows + self.config.categoryTitleHeight)
	categoryFrame:SetWidth((self:GetButtonWidth() + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing)
end

function INV:FlushCategory(category)
	for _,slot in pairs(category.slots) do
		if slot.info then self:ClearSlot(slot) end
	end
	category:Hide()
end

function INV:FlushCategories(container, sorted_inv)
	-- If a category was emptied it wouldn't be in the above loop.
	-- This finds those categories and hides them properly

	for categoryName,category in pairs(container.categories) do
		if not (sorted_inv[categoryName] or categoryName == 'Bags' or categoryName == 'Currencies') then
			INV:FlushCategory(category)
		end
	end
end

function INV:InitializeAllCategories(containerName)
	for _,category in pairs(self.filters.categories) do
		self:CreateCategory(containerName, category.name)
		self:UpdateCategory(containerName, category.name, {})
	end
	if containerName == 'bag' then
		-- Made now, out of combat, with its slot pool, even while the setting is
		-- off: it is flushed like any empty category until it has slots.
		self:CreateCategory(containerName, self.EMPTY_SLOTS_CATEGORY)
		self:UpdateCategory(containerName, self.EMPTY_SLOTS_CATEGORY, {})
		self:InitializeCurrencyCategory()
	end
end