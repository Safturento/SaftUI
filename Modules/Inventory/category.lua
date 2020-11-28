local st = SaftUI
local INV = st:GetModule('Inventory')

INV.CATEGORY_TITLE_HEIGHT = 17
INV.CATEGORY_SLOT_POOL = 10

INV.categoryNames = {
	['GRAYS'] = 'Grays',
	['CONSUMABLES'] = 'Consumables',
	['LEGACY_ARMOR_WEAPONS'] = 'Legacy Armor/Weapons',
	['ARMOR'] = 'Armor',
	['WEAPONS'] = 'Weapons',
	['ARCHAEOLOGY'] = 'Archaeology',
	['TRADE_GOODS'] = 'Trade Goods',
	['RECIPES'] = 'Recipes',
	['DEVICES'] = 'Devices',
	['PETS'] = 'Pets',
	['MOUNTS'] = 'Mounts',
	['QUEST'] = 'Quest',
	['KEYS'] = 'Keys',
	['MISCELLANEOUS'] = 'Miscellaneous',
}

local CONDUIT_TEXT = "Add this Conduit to your collection"
local ANIMA_TEXT = "stored Anima into your covenant's Reservoir"
local CONTAINER_TEXT = "Right Click to Open"
local TOY_TEXT = "Adds this toy to your Toy Box"

local customItemLists = {
	["Archaeology"] = {
		-- keystones
		[52843] = 'dwarf-rune-stone',
		[63127] = 'highborne-scroll',
		[63128] = 'troll-tablet',
		[64392] = 'orc-blood-text',
		[64394] = 'draenei-tome',
		[64395] = 'vrykul-rune-stick',
		[64396] = 'nerubian-obelisk',
		[64397] = 'tolvir-hieroglyphic',
		[154990] = 'etched-drust-bone',
		[154989] = 'zandalari-idol',
		[79868] = 'pandaren-pottery-shard',
		[79869] = 'mogu-statue-piece',
		[95373] = 'mantid-amber-sliver',
		[108439] = 'draenor-clan-orator-cane',
		[109584] = 'ogre-missive',
		[109585] = 'arakkoa-cipher',
		[130904] = 'highmountain-ritual-stone',
		[130905] = 'mark-of-the-deceiver',
		[130903] = 'ancient-suramar-scroll',
		--fragment crates
		[87399] = 'restored-artifact',
		[87533] = 'crate-of-dwarven-archaeology-fragments',
		[87534] = 'crate-of-draenei-archaeology-fragments',
		[87535] = 'crate-of-fossil-archaeology-fragments',
		[87536] = 'crate-of-night-elf-archaeology-fragments',
		[87537] = 'crate-of-nerubian-archaeology-fragments',
		[87538] = 'crate-of-orc-archaeology-fragments',
		[87539] = 'crate-of-tolvir-archaeology-fragments',
		[87540] = 'crate-of-troll-archaeology-fragments',
		[87541] = 'crate-of-vrykul-archaeology-fragments',
		[117386] = 'crate-of-pandaren-archaeology-fragments',
		[117387] = 'crate-of-mogu-archaeology-fragments',
		[117388] = 'crate-of-mantid-archaeology-fragments',
		[142113] = 'crate-of-arakkoa-archaeology-fragments',
		[142114] = 'crate-of-draenor-clans-archaeology-fragments',
		[142115] = 'crate-of-ogre-archaeology-fragments',
		[164625] = 'crate-of-demon-archaeology-fragments',
		[164626] = 'crate-of-highborne-archaeology-fragments',
		[164627] = 'crate-of-highmountain-tauren-archaeology-fragments',
		[183834] = 'crate-of-drust-archaeology-fragments',
		[183835] = 'crate-of-zandalari-archaeology-fragments',
	}
}

INV.filters = {
	itemrack = {},
	categories = {
		{ name = INV.categoryNames.GRAYS,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return quality == 0 end},
		{ name = "Toy",									func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return string.match(strlower(tooltipText), strlower(TOY_TEXT)) end},
		{ name = "Anima",								func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return string.match(strlower(tooltipText), strlower(ANIMA_TEXT)) end},
		{ name = "Conduits",							func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return string.match(strlower(tooltipText), strlower(CONDUIT_TEXT)) end},
		{ name = "Container",							func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return string.match(strlower(tooltipText), strlower(CONTAINER_TEXT)) end},
		{ name = INV.categoryNames.CONSUMABLES,		 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Consumable' end},
		{ name = INV.categoryNames.LEGACY_ARMOR_WEAPONS,func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText)
			return (class == 'Armor' or class == 'Weapon') and (quality >= 2 and quality <=4) and expacID < 7 end},
		{ name = INV.categoryNames.ARMOR,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Armor' end},
		{ name = INV.categoryNames.WEAPONS,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Weapon' end},
		{ name = INV.categoryNames.ARCHAEOLOGY,		 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return customItemLists.Archaeology[itemID] end},
		{ name = INV.categoryNames.TRADE_GOODS,		 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Trade Goods' or class == 'Gem' or class == 'Tradeskill' end},
		{ name = INV.categoryNames.RECIPES,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Recipe' end},
		{ name = INV.categoryNames.DEVICES,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return subclass == 'Devices' end},
		{ name = INV.categoryNames.PETS,	 			func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return subclass == 'Companion Pets' or subclass == 'Mount' end},
		{ name = INV.categoryNames.MOUNTS,	 			func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return subclass == 'Companion Pets' or subclass == 'Mount' end},
		{ name = INV.categoryNames.QUEST,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Quest' end},
		{ name = INV.categoryNames.KEYS,			 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return class == 'Key' or name:lower():match('%f[%a]key%f[%A]') end},
		{ name = INV.categoryNames.MISCELLANEOUS, 	 	func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) return true end},
	}
}

--tests an item against all categories and returns the first one that meets the criteria.
function INV:GetItemCategory(itemID,name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText)
	if class == 'Armor' or class == 'Weapon' then
		for i, category in ipairs(self.filters.itemrack) do
			if category.func(itemID,name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) then
				return category.name
			end
		end
	end

	for i, category in ipairs(self.filters.categories) do
		if category.func(itemID,name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText) then
			return category.name
		end
	end

	-- not all items will fit a category, place those items in Miscellaneous
	return "Miscellaneous"
end

function INV:UpdateItemRackCategories()
	if not ItemRackUser then return end
	local categories = {}

	for set_name, set_items in pairs(ItemRackUser.Sets) do
		if not (set_name:sub(1,1) == '~') then
			local category = {
				name = 'ItemRack: '..set_name,
				items = {},
			}

			for slot_id, item_link in pairs(set_items.equip) do
				category.items['item:'..item_link] = true
			end

			category.func = function(itemID, name,link,quality,ilvl,reqLevel,class,subclass,equipSlot)
				local item_string = string.match(link, "item[%-?%d:]+")
				return category.items[item_string]
			end

			tinsert(categories, category)
		end
	end

	self.filters.itemrack = categories

	self:QueueUpdate()
end

local function sortCategory(a,b) return a.sortString > b.sortString end

function INV:GetSortedInventory(id)
	local container = self.containers[id]
	if not container then 
		st:Error('container with id ', id, 'not found')
	end

	local inventory = {}
	
	for _,bagID in pairs(container.bag_ids) do
		for slotID=1, GetContainerNumSlots(bagID) do
			local texture, count, locked, quality, readable, lootable, clink, isFiltered, hasNoValue, itemID = GetContainerItemInfo(bagID,slotID)
			if clink then
				local tooltipText = self:ScanBagItem(bagID,slotID)
				local name, clink, quality, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
					itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(clink)
				if name then
					ilvl = GetDetailedItemLevelInfo(clink)
					--Create custom categories here to replace actual category value
					local category_name = self:GetItemCategory(itemID,name,clink,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText)

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
						sortString = (ilvl or 0) .. name .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (count or 0),
						clink = clink,
						texture = texture,
						count = count,
						locked = locked,
						expacID = expacID
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

	-- Ensure that there's always a decent slot pool created to avoid
	-- tainting in combat
	if not InCombatLockdown() then
		for i = #category_frame.slots - #categoryItems + 1 , INV.CATEGORY_SLOT_POOL do
			self:CreateSlot(container, category_name)
		end
	end

	local numRows = math.ceil(#categoryItems/self.config[id].perrow)
	categoryHeight = (self.config.buttonheight + self.config.buttonspacing) * numRows + INV.CATEGORY_TITLE_HEIGHT
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
	end
end