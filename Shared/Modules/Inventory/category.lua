local st = SaftUI
local INV = st:GetModule('Inventory')

INV.CATEGORY_TITLE_HEIGHT = 17
INV.CATEGORY_SLOT_POOL = 10

--tests an item against all categories and returns the first one that meets the criteria.
--itemID,name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText
function INV:GetItemCategory(info)
	if info.class == 'Armor' or info.class == 'Weapon' then
		local isItemInSet, itemSetList = C_Container.GetContainerItemEquipmentSetInfo(info.bagID, info.slotID)
		if isItemInSet then
			return 'Set: ' .. select(1, strsplit(',', itemSetList))
		end

		--for i, category in ipairs(self.filters.itemrack) do
		--	if category.func(info) then
		--		return category.name
		--	end
		--end
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

function INV:GetInventoryItemInfo(bagID, slotID)
	local item = C_Container.GetContainerItemInfo(bagID, slotID)
	if item then
		local tooltipText = self:ScanBagItem(bagID,slotID)
		local name, _, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
			itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.hyperlink)

		if not name then
			local itemString = select(3, strfind(item.hyperlink, "|H(.+)|h"))
			local itemType, itemId = string.split(':', itemString)

			if itemType == "keystone" then
				name, _, _, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
					itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemId)
				class = 'Key'
				quality = 4

			elseif itemType == 'battlepet' then
				--print(string.split(':', itemString))
			end
		end

		if name then
			local item = {
				name = name,
				ilvl = GetDetailedItemLevelInfo(item.hyperlink),
				reqLevel = reqLevel,
				soulbound = item.isBound,
				count = item.stackCount,
				itemID = item.itemID,
				unitPrice = vendorPrice,
				stackPrice = vendorPrice * item.stackCount,
				link = item.hyperlink,
				quality = quality or 0,
				class = class,
				subclass = subclass,
				maxStack = maxStack,
				equipSlot = equipSlot,
				expacID = expacID,
				vendorPrice = vendorPrice,
				texture = texture,
				locked = item.locked,
				bagID = bagID,
				slotID = slotID,
				tooltipText = tooltipText,
				sortString = (ilvl or 0) .. name .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (item.itemCount or 0),
			}

			return item
		end
	end
end


local function sortCategory(a,b) return a.sortString > b.sortString end

function INV:GetSortedInventory(id)
	local container = self.containers[id]
	if not container then 
		st:Error('container with id ', id, 'not found')
	end

	local inventory = {}

	if id == 'reagent' then
		for slotID = 1, 98 do
			local item = self:GetInventoryItemInfo(REAGENTBANK_CONTAINER, slotID)
			if item then
				local categoryName = item.subclass or "Other"

				if item.expacID then
					item.sortString = item.expacID .. item.sortString
				end
				if not inventory[categoryName] then inventory[categoryName] = {} end
				tinsert(inventory[categoryName], item)
			end
		end
	else
		for _,bagID in pairs(container.bag_ids) do
			for slotID=1, C_Container.GetContainerNumSlots(bagID) do
				local item = self:GetInventoryItemInfo(bagID, slotID)
				if item then
					local categoryName = self:GetItemCategory(item)

					if not inventory[categoryName] then inventory[categoryName] = {} end
					tinsert(inventory[categoryName], item)
				end
			end
		end
	end

	for categoryName,categoryItems in pairs(inventory) do
		if #categoryItems > 1 then
			table.sort(categoryItems, sortCategory)
		end
	end

	return inventory
end

function INV:CreateCategory(id, category_name)
	local container = self.containers[id]

	local category_frame = CreateFrame('frame', nil, container)
	category_frame.name = category_name
	category_frame:SetWidth(container:GetWidth() - self.config.padding * 2)
	category_frame.slots = {}

	local label = CreateFrame('Button', nil, category_frame)
	label:SetSize(200, INV.CATEGORY_TITLE_HEIGHT)
	label:SetPoint('TOPLEFT', category_frame)

	label.text = label:CreateFontString(nil, 'OVERLAY')
	label.text:SetFontObject(st:GetFont(st.config.profile.inventory.fonts.titles))
	label.text:SetPoint('LEFT', 0, 0)
	label.text:SetText(category_name)
	
	category_frame.label = label
	container.categories[category_name] = category_frame

	return category_frame
end

function INV:UpdateCategory(id, category_name, categoryItems)
	local container = self.containers[id]

	local category_frame = container.categories[category_name] or self:CreateCategory(id, category_name)
	-- Hide any visible icons that are no longer in use
	for i = #categoryItems + 1, #category_frame.slots do
		self:ClearSlot(category_frame.slots[i])
	end

	for i, item in pairs(categoryItems) do
		category_frame:Show()
		local slot = category_frame.slots[i] or self:CreateSlot(container, category_name)
		self:AssignSlot(container, slot, item)
	end

	-- Ensure that there's always a decent slot pool created to avoid
	-- tainting in combat
	if not InCombatLockdown() then
		for i = #category_frame.slots - #categoryItems + 1 , INV.CATEGORY_SLOT_POOL do
			self:CreateSlot(container, category_name)
		end
	end

	local numRows = math.ceil(#categoryItems/self.config[id].perrow)
	categoryHeight = (self.config.buttonheight + self.config.buttonspacing) * numRows + INV.CATEGORY_TITLE_HEIGHT
	category_frame.numRows = numRows
	category_frame:SetHeight(categoryHeight)
end

function INV:FlushCategories(container, sorted_inv)
	-- If a category was emptied it wouldn't be in the above loop.
	-- This finds those categories and hides them properly

	for category_name,category in pairs(container.categories) do
		if not (sorted_inv[category_name] or category_name == 'Bags') then
			for _,slot in pairs(category.slots) do self:ClearSlot(slot) end
			category:Hide()
		end
	end
end

function INV:InitializeAllCategories(container)
	for _,category in pairs(self.filters.categories) do
		self:CreateCategory(container, category.name)
		self:UpdateCategory(container, category.name, {})
	end
end