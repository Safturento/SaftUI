local st = SaftUI
local INV = st:GetModule('Inventory')

INV.CATEGORY_SLOT_POOL = 10

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
		local name, _, quality, _, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
			itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item.hyperlink)
		local ilvl = GetDetailedItemLevelInfo(item.hyperlink)
		if not name then
			local itemString = select(3, strfind(item.hyperlink, "|H(.+)|h"))
			local itemType, itemId = string.split(':', itemString)

			if itemType == "keystone" then
				_, _, _, keyLevel =  string.split(':', itemString)
				name, _, _, _, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
					itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemId)
				--\124cffa335ee\124Hkeystone:180653:198:15:10:136:8:0\124h[Keystone: Darkheart Thicket (15)]\124h\124r
				class = 'Key'
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

		--local upgradeInfo
		--if class == 'Armor' or class == 'Weapon' then
		--	local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
		--	local upgradable = C_ItemUpgrade.CanUpgradeItem(itemLocation);
		--	if upgradable then
		--		local quality, level, maxLevel = tooltipText:match("Upgrade Level: (%w+) (%d)/(%d)")
		--		upgradeInfo = {
		--			quality = quality,
		--			level = level,
		--			maxLevel = maxLevel,
		--			qualityIndex = upgradeQualities[quality]
		--		}
		--	end
		--end

		if name then
			return {
				name = name,
				ilvl = ilvl,
				reqLevel = reqLevel,
				soulbound = item.isBound,
				count = item.stackCount,
				--upgradeInfo = upgradeInfo,
				itemID = item.itemID,
				unitPrice = vendorPrice,
				stackPrice = vendorPrice * item.stackCount,
				link = item.hyperlink,
				quality = quality or 0,
				class = class,
				subclass = subclass,
				maxStack = maxStack,
				equipSlot = _G[equipSlot],
				expacID = expacID,
				vendorPrice = vendorPrice,
				texture = texture or item.iconFileId,
				locked = item.locked,
				bagID = bagID,
				slotID = slotID,
				tooltipText = tooltipText,
				sortString = (ilvl or 0) .. name .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (item.itemCount or 0),
			}
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

function INV:CreateCategory(id, categoryName, slotPoolFunc)
	local container = self.containers[id]

	local categoryFrame = CreateFrame('frame', nil, container)
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
	header.text:SetPoint('LEFT', -2, 0)
	header.text:SetText(categoryName)
	categoryFrame.header = header

	local filterCheckbox = st:CreateCheckButton(nil, categoryFrame)
    filterCheckbox:Hide()
    filterCheckbox:SetSize(8, 8)
    filterCheckbox:SetPoint('BOTTOM', header, 'BOTTOM', 0, 4)
    filterCheckbox:SetPoint('LEFT', header.text, 'RIGHT', 8, 0)
    filterCheckbox:HookScript('OnClick', function(self)
        INV.config.filters.categories[id][categoryName] = self:GetChecked() or nil
		INV:UpdateContainerHeight(id)
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
		self:ClearSlot(categoryFrame.slots[i])
	end

	categoryFrame.header.text:SetFormattedText("%s (%d)", categoryName, #categoryItems)

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
	categoryHeight = (self.config.buttonheight + self.config.buttonspacing) * numRows + self.config.categoryTitleHeight
	categoryFrame.numRows = numRows
	categoryFrame:SetHeight(categoryHeight)
end

function INV:FlushCategory(category)
	for _,slot in pairs(category.slots) do self:ClearSlot(slot) end
	category:Hide()
end

function INV:FlushCategories(container, sorted_inv)
	-- If a category was emptied it wouldn't be in the above loop.
	-- This finds those categories and hides them properly

	for categoryName,category in pairs(container.categories) do
		if not (sorted_inv[categoryName] or categoryName == 'Bags' or categoryName == 'Currencies') then
			INV:FlushCategory(category)
			--for _,slot in pairs(category.slots) do self:ClearSlot(slot) end
			--category:Hide()
		end
	end
end

function INV:InitializeAllCategories(containerName)
	for _,category in pairs(self.filters.categories) do
		self:CreateCategory(containerName, category.name)
		self:UpdateCategory(containerName, category.name, {})
	end
	if containerName == 'bag' then
		self:InitializeCurrencyCategory()
	end
end