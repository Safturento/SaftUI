local ADDON_NAME, st = ...
local INV = st:GetModule('Inventory')
INV.CATEGORY_TITLE_HEIGHT = 17

INV.CATEGORY_FILTERS = {
	{ name = 'Grays',				func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return quality == 0 end},
	{ name = 'Consumables',		func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return class == 'Consumable' end},
	{ name = 'Armor',				func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return class == 'Armor' end},
	{ name = 'Weapons',			func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return class == 'Weapon' end},
	{ name = 'Trade Goods',		func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return class == 'Trade Goods' or class == 'Gem' or class == 'Tradeskill' end},
	{ name = 'Recipes',			func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return class == 'Recipe' end},
	{ name = 'Devices',			func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return subclass == 'Devices' end},
	{ name = 'Pets & Mounts',	func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return subclass == 'Companion Pets' or subclass == 'Mount' end},
	{ name = 'Quest',				func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return class == 'Quest' end},
	
	{ name = 'Miscellaneous', func = function(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) return true end},
}

--tests an item against all categories and returns the first one that meets the criteria.
function INV:GetItemCategory(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot)
	for i, category in ipairs(INV.CATEGORY_FILTERS) do
		if category.func(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot) then
			return category.name
		end
	end

	-- not all items will fit a category, place those items in Miscellaneous
	return "Miscellaneous"
end

local function sortCategory(a,b) return a.sortString > b.sortString end

function INV:GetSortedInventory(id)
	local container = self.containers[id]
	if not container then 
		print('container with id ', id, 'not found')
	end

	local inventory = {}
	
	for _,bagID in pairs(container.bag_ids) do
		for slotID=1, GetContainerNumSlots(bagID) do
			local texture, count, locked, quality, readable, lootable, clink, isFiltered, hasNoValue, itemID = GetContainerItemInfo(bagID,slotID)
			if clink then
				local name, clink, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(clink)

				if name then
					--Create custom categories here to replace actual category value
					local category_name = self:GetItemCategory(name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,lootable)

					if not inventory[category_name] then inventory[category_name] = {} end

					tinsert(inventory[category_name], {
						name = name,
						quality = quality or 0,
						ilvl = ilvl,
						reqLevel = reqLevel,
						class = class,
						subclass = subclass,
						maxStack = maxStack,
						equipSlot = equipSlot,
						vendorPrice = vendorPrice,
						bagID = bagID,
						slotID = slotID,
						sortString = name .. (ilvl or 0) .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (count or 0),
						clink = clink,
						texture = texture,
						count = count,
						locked = locked
					})
				end
			end
		end
	end

	for category_name,categoryItems in pairs(inventory) do
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

	for i, itemInfo in pairs(categoryItems) do
		if not category_frame:IsShown()
			then category_frame:Show()
		end
		local slot = category_frame.slots[i] or self:CreateSlot(container, category_name)
		self:AssignSlot(container, slot, itemInfo)
	end

	local numRows = math.ceil(#categoryItems/self.config[id].perrow)
	categoryHeight = (self.config.buttonsize + self.config.buttonspacing) * numRows + INV.CATEGORY_TITLE_HEIGHT
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