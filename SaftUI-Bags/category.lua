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
INV.CompareItems = sortCategory

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

-- A window's Empty slots setting, 'grouped' or 'all'; nil for 'off' (and for a
-- window with no such setting).
function INV:GetEmptySlotMode(id)
	local config = self.config[id]
	local mode = config and config.emptySlots
	if mode == 'grouped' or mode == 'all' then return mode end
end

-- In combat: once combat ends, makes the slot buttons that are missing
-- (EnsureSlotPools) and updates the windows again (one pending run). Returns
-- true then; out of combat it does nothing and returns false.
function INV:QueueSlotTopUp()
	return st:QueueAfterCombat('InventorySlotPool', function()
		INV:EnsureSlotPools()
		INV:QueueUpdate(true)
	end)
end

-- In combat no slot button can be made (see CreateSlot), so a category frame
-- (by name) shows no more of infos than it has buttons left after its
-- numItems slots, none before the frame is made, and the rest once combat
-- ends (QueueSlotTopUp). Compact's Empty Slots goes through it, and every
-- view's sections: their free slots, and the items of Rows' categories and of
-- One bag's and Multi bag's sections. Trims infos in place and returns it.
function INV:FitSlots(id, name, numItems, infos)
	if not InCombatLockdown() then return infos end
	local frame = self.containers[id].categories[name]
	local room = max(0, (frame and #frame.slots or 0) - numItems)
	if #infos > room then
		for i = #infos, room + 1, -1 do infos[i] = nil end
		self:QueueSlotTopUp()
	end
	return infos
end

-- Gives a window's category frame of that name at least `slots` buttons,
-- making the frame first if it isn't (hidden until a layout shows it, with
-- its title, which places its first button: INV:SetSlotPosition). Out of
-- combat; in combat it queues the top-up instead and returns true.
local function FillPool(self, container, name, slots, title)
	local frame = container.categories[name]
	if frame and #frame.slots >= slots then return end
	if self:QueueSlotTopUp() then return true end
	if not frame then
		self:UpdateCategory(container.id, name, {}, title)
		frame = container.categories[name]
		frame:Hide()
	end
	for _ = #frame.slots + 1, slots do self:CreateSlot(container, name) end
end

--[[
	Makes the slot buttons a window's view needs (every window's, with no id),
	before a fight can need them. Buttons made in combat are flagged as broken
	(see CreateSlot), so this happens out of combat, on every bag update, even
	with the window closed, so a bigger bag being equipped is covered too. In
	combat it queues itself for the end of combat (QueueSlotTopUp).
	  - Compact and Rows: the Empty Slots category, whenever the window's
	    Empty slots setting shows free slots. The category itself, with
	    UpdateCategory's spare buttons (enough for 'grouped', one slot per
	    kind of bag), before any free slot needs it: the bag window's is made
	    at login (InitializeAllCategories), the bank windows' here. With 'all'
	    (Every slot), a button for every bag slot, since a fight can free any
	    number of them. The other categories have UpdateCategory's spare
	    buttons, as Compact always has.
	  - One bag and Multi bag: each section's frame, with a button for every
	    slot of its bags (INV:GetSectionPools), so a fight's loot never needs
	    one, however much of it lands in one section.
]]
function INV:EnsureSlotPools(id)
	if not id then
		for windowId in pairs(self.containers) do self:EnsureSlotPools(windowId) end
		return
	end
	local container = self.containers[id]
	if not container then return end
	local view = self:GetLaidOutView(container)

	if view == 'onebag' or view == 'multibag' then
		for name, pool in pairs(self:GetSectionPools(id, view)) do
			local title
			if pool.untitled then title = false end
			if FillPool(self, container, name, pool.slots, title) then return end
		end
		return
	end

	local mode = self:GetEmptySlotMode(id)
	if not mode then return end
	local total = 0
	if mode == 'all' then
		for _, bagID in pairs(container.bag_ids) do
			total = total + C_Container.GetContainerNumSlots(bagID)
		end
	end
	FillPool(self, container, self.EMPTY_SLOTS_CATEGORY, total)
end

-- Reads a window's bags once, for GetSortedInventory and the views. Returns:
--   bags: one record per bag ID, in the window's bag order: `id`, `items` (the
--     item infos in slot order, after stacks are merged) and `free` (the free
--     slot IDs, in order);
--   numItems, numLoading;
--   categoryOf: item info -> its category name.
-- groupOf(bagID) names the group a bag merges stacks in (when stackItems is
-- on): the same item in two groups stays two slots. A stack merges into the
-- first slot of its item in the group, which stays where it was. noMerge
-- reads every stack as its own item, whatever stackItems says (auto vendor
-- sells slot by slot).
function INV:ReadBags(id, groupOf, noMerge)
	local container = self.containers[id]
	if not container then
		st:Error('container with id ', id, 'not found')
	end

	local bags, categoryOf = {}, {}
	local merged = {}
	local merge = self.config.stackItems and not noMerge
	local numItems, numLoading = 0, 0
	for _, bagID in pairs(container.bag_ids) do
		local group = groupOf(bagID)
		local bag = { id = bagID, items = {}, free = {} }
		tinsert(bags, bag)
		for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
			local item = self:GetInventoryItemInfo(bagID, slotID, id)
			if item then
				numItems = numItems + 1
				if item.loading then
					numLoading = numLoading + 1
				else
					local mergeKey = tostring(item.itemID) .. ':' .. group
					if merge and merged[mergeKey] and item.maxStack > 1 then
						merged[mergeKey].count = merged[mergeKey].count + item.count
					else
						categoryOf[item] = self:GetItemCategory(item)
						-- For the slot's junk coin (INV:IsAutoVendorItem), so it needn't
						-- categorize again.
						item.category = categoryOf[item]
						tinsert(bag.items, item)
						if merge and item.maxStack > 1 then
							merged[mergeKey] = item
						end
					end
				end
			else
				tinsert(bag.free, slotID)
			end
		end
	end
	return bags, numItems, numLoading, categoryOf
end

-- The empty slot infos for a list of bag records (see ReadBags), by mode:
-- 'all' is one per free slot, in order; 'grouped' is one pointing at the first
-- free slot, with `count` the number of free slots, or none if there are none.
function INV:GetEmptySlots(id, bags, mode)
	local empties = {}
	if mode ~= 'all' and mode ~= 'grouped' then return empties end
	local first, count = nil, 0
	for _, bag in ipairs(bags) do
		for _, slotID in ipairs(bag.free) do
			count = count + 1
			if mode == 'all' then
				tinsert(empties, GetEmptySlotInfo(bag.id, slotID, id))
			elseif not first then
				first = GetEmptySlotInfo(bag.id, slotID, id)
			end
		end
	end
	if first then
		first.count = count
		empties[1] = first
	end
	return empties
end

-- The kind of bag a free slot is in, for the views that don't show bags apart
-- (Compact and Rows): 2 for the reagent bag, and in the combined bank for the
-- warband bank; 1 for the rest.
local function EmptySlotKind(INV, id, bagID)
	if INV:IsReagentBag(bagID) then return 2 end
	if id == 'combinedbank' then
		for _, warbandID in ipairs(INV.bagIds.warband or {}) do
			if warbandID == bagID then return 2 end
		end
	end
	return 1
end

-- The empty slot infos of every kind of bag, the first kind's first.
function INV:GetEmptySlotsByKind(id, bags, mode)
	local kinds = { {}, {} }
	for _, bag in ipairs(bags) do
		tinsert(kinds[EmptySlotKind(self, id, bag.id)], bag)
	end
	local empties = self:GetEmptySlots(id, kinds[1], mode)
	for _, info in ipairs(self:GetEmptySlots(id, kinds[2], mode)) do tinsert(empties, info) end
	return empties
end

function INV:GetSortedInventory(id)
	local bags, numItems, numLoading, categoryOf = self:ReadBags(id, function(bagID)
		-- The reagent bag is its own kind of bag: the same item in it and in a
		-- normal bag stays two slots when stacks are merged.
		return self:IsReagentBag(bagID) and 'reagent' or 'bag'
	end)

	local inventory = {}
	for _, bag in ipairs(bags) do
		for _, item in ipairs(bag.items) do
			local categoryName = categoryOf[item]
			if not inventory[categoryName] then inventory[categoryName] = {} end
			tinsert(inventory[categoryName], item)
		end
	end

	-- Normal bags first, then the reagent bag. This category isn't sorted below,
	-- so it keeps that order. Grouped is one slot per kind of bag, pointing at
	-- its first free slot, so an item dropped on it lands there.
	local mode = self:GetEmptySlotMode(id)
	if mode then
		-- In combat no button can be made, so show only as many as exist; the
		-- queued pool top-up asks for a full update when combat ends.
		local empties = self:FitSlots(id, self.EMPTY_SLOTS_CATEGORY, 0, self:GetEmptySlotsByKind(id, bags, mode))
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

-- Fills a category frame with its items (made if it isn't), shows it and sizes
-- it. title is its header's text: by default its name and how many it holds
-- ("Armor (3)"), and false for none, the header hidden and taking no height.
-- lineSlots is how many slots a line holds, by default the line of the view
-- the window is laid out in (INV:LineSlots).
function INV:UpdateCategory(id, categoryName, categoryItems, title, lineSlots)
	local container = self.containers[id]
	lineSlots = lineSlots or self:LineSlots(id, self:GetLaidOutView(container))

	local categoryFrame = container.categories[categoryName] or self:CreateCategory(id, categoryName)
	categoryFrame:Show()
	-- Set before any slot is made: INV:SetSlotPosition puts the first slot of
	-- an untitled frame at its top.
	categoryFrame.untitled = title == false
	categoryFrame.header:SetShown(title ~= false)

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
	if title then
		categoryFrame.header.text:SetText(title)
	elseif title == nil then
		categoryFrame.header.text:SetFormattedText("%s (%d)", categoryName, numShown)
	end

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

	local spacing = self.config.buttonspacing
	local numRows = math.ceil(#categoryItems / lineSlots)
	categoryFrame.numRows = numRows
	local rowsHeight = (self:GetButtonHeight() + spacing) * numRows
	if title == false then
		categoryFrame:SetHeight(max(0, rowsHeight - spacing))
	else
		categoryFrame:SetHeight(rowsHeight + self.config.categoryTitleHeight)
	end
	categoryFrame:SetWidth((self:GetButtonWidth() + spacing) * lineSlots - spacing)
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