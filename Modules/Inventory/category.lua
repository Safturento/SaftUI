local st = SaftUI
local INV = st:GetModule('Inventory')

INV.CATEGORY_TITLE_HEIGHT = 17
INV.CATEGORY_SLOT_POOL = 10

local expacAbbreviations = {
	[0] = "Classic",
	[1] = "BC",
	[2] = "WotLK",
	[3] = "Cata",
	[4] = "MoP",
	[5] = "WoD",
	[6] = "Legion",
	[7] = "BfA",
	[8] = "SL",
}

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

INV.categoryNames = {
	['GRAYS'] = 'Grays/Auto Vendor',
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
	['TOY'] = 'Toy',
	['ANIMA'] = 'Anima',
	['CONDUITS'] = 'Conduits',
	['BLUEPRINT'] = 'Blueprint',
	['BATTLE_STONES'] = 'Battle-Stones',
	['CONTAINER'] = 'Container'
}

local CONDUIT_TEXT = "Add this Conduit to your collection"
local ANIMA_TEXT = "stored Anima into your covenant's Reservoir"
local CONTAINER_TEXT = "Right Click to Open"
local CONTAINER_TEXT2 = "Open the container"
local TOY_TEXT = "Adds this toy to your Toy Box"
local BLUEPRINT_TEXT = "Blueprint: "
local ARTIFACT_RELIC_TEXT = "Artifact Relic"
local USE_TEXT = "Use:"
local EQUIP_EFFECT_TEXT = "Equip:"
local COSMETIC_TEXT = "Cosmetic"
local BIND_ON_ACCOUNT = "Account Bound"
local TRAINING_STONE_TEXT = "Battle-Training Stone"
local BATTLE_STONE_TEXT = "Battle-Stone"
local RESTORED_ARTIFACT_TEXT = "Carefully crate the restored artifact"
local TRADEABLE_ITEM = "You may trade this item with players"

local function isLegacyGear(info)
	if info.expacID > 7 then return false end
	if info.equipSlot == "INVTYPE_TABARD" or info.equipSlot == "INVTYPE_BODY" then return false end
	if string.matchnocase(info.tooltipText, TRADEABLE_ITEM) then return false end
	if string.matchnocase(info.tooltipText, BIND_ON_ACCOUNT) then return false end
	if string.matchnocase(info.tooltipText, COSMETIC_TEXT) then return false end
	if string.matchnocase(info.tooltipText, USE_TEXT) or string.matchnocase(info.tooltipText, EQUIP_EFFECT_TEXT) then return false end
	if not (info.quality >= 2 and info.quality <=4) then return false end
	if (info.class == 'Armor' or info.class == 'Weapon') then return true end
	if string.matchnocase(info.tooltipText, ARTIFACT_RELIC_TEXT) then return true end

	return false
end

INV.filters = {
	itemrack = {},
	categories = {
		{ name = INV.categoryNames.GRAYS,			 	func = function(info) return info.quality == 0 or INV:ShouldAutoVendor(info.itemID) end},
		{ name = INV.categoryNames.TOY,					func = function(info) return string.matchnocase(info.tooltipText, TOY_TEXT) end},
		{ name = INV.categoryNames.ANIMA,				func = function(info) return string.matchnocase(info.tooltipText, ANIMA_TEXT) end},
		{ name = INV.categoryNames.CONDUITS,			func = function(info) return string.matchnocase(info.tooltipText, CONDUIT_TEXT) end},
		{ name = INV.categoryNames.BLUEPRINT,			func = function(info) return string.matchnocase(info.name, BLUEPRINT_TEXT) end},
		{ name = INV.categoryNames.BATTLE_STONES,		func = function(info) return string.matchnocase(info.name, BATTLE_STONE_TEXT) or string.matchnocase(info.name, TRAINING_STONE_TEXT) end},
		{ name = INV.categoryNames.CONTAINER,			func = function(info) return string.matchnocase(info.tooltipText, CONTAINER_TEXT) or string.matchnocase(info.tooltipText, CONTAINER_TEXT2) end},
		{ name = INV.categoryNames.CONSUMABLES,		 	func = function(info) return info.class == 'Consumable' end},
		{ name = INV.categoryNames.LEGACY_ARMOR_WEAPONS,func = function(info) return isLegacyGear(info) end},
		{ name = INV.categoryNames.ARMOR,			 	func = function(info) return info.class == 'Armor' end},
		{ name = INV.categoryNames.WEAPONS,			 	func = function(info) return info.class == 'Weapon' end},
		{ name = INV.categoryNames.ARCHAEOLOGY,		 	func = function(info) return customItemLists.Archaeology[info.itemID] or string.matchnocase(info.tooltipText, RESTORED_ARTIFACT_TEXT) end},
		{ name = INV.categoryNames.TRADE_GOODS,		 	func = function(info) return info.class == 'Trade Goods' or info.class == 'Gem' or info.class == 'Tradeskill' end},
		{ name = INV.categoryNames.RECIPES,			 	func = function(info) return info.class == 'Recipe' end},
		{ name = INV.categoryNames.DEVICES,			 	func = function(info) return info.subclass == 'Devices' end},
		{ name = INV.categoryNames.PETS,	 			func = function(info) return info.subclass == 'Companion Pets' or info.subclass == 'Mount' end},
		{ name = INV.categoryNames.MOUNTS,	 			func = function(info) return info.subclass == 'Companion Pets' or info.subclass == 'Mount' end},
		{ name = INV.categoryNames.QUEST,			 	func = function(info) return info.class == 'Quest' end},
		{ name = INV.categoryNames.KEYS,			 	func = function(info) return info.class == 'Key' or info.name:lower():match('%f[%a]key%f[%A]') end},
		{ name = INV.categoryNames.MISCELLANEOUS, 	 	func = function(info) return true end},
	}
}



--tests an item against all categories and returns the first one that meets the criteria.
--itemID,name,link,quality,ilvl,reqLevel,class,subclass,equipSlot,expacID,tooltipText
function INV:GetItemCategory(info)
	if info.class == 'Armor' or info.class == 'Weapon' then
		local isItemInSet, itemSetList = GetContainerItemEquipmentSetInfo(info.bagID, info.slotID)
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
	local texture, count, locked, quality, readable, lootable, itemLink, isFiltered, hasNoValue, itemID = GetContainerItemInfo(bagID,slotID)
	if itemLink then
		local tooltipText = self:ScanBagItem(bagID,slotID)
		local name, _, _, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
			itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)


		if not name then
			local itemString = select(3, strfind(itemLink, "|H(.+)|h"))
			local itemType, itemId = string.split(':', itemString)

			if itemType == "keystone" then
				name, _, _, ilvl, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice,
					itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemId)
				class = 'Key'
			elseif itemType == 'battlepet' then
				--print(string.split(':', itemString))
			end
		end

		if name then
			local itemInfo = {
				name = name,
				ilvl = GetDetailedItemLevelInfo(itemLink),
				reqLevel = reqLevel,
				count = count,
				itemID = itemID,
				itemLink = itemLink,
				quality = quality or 0,
				class = class,
				subclass = subclass,
				maxStack = maxStack,
				equipSlot = equipSlot,
				expacID = expacID,
				vendorPrice = vendorPrice,
				itemLink = itemLink,
				texture = texture,
				locked = locked,
				expacID = expacID,
				bagID = bagID,
				slotID = slotID,
				tooltipText = tooltipText,
				sortString = (ilvl or 0) .. name .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (count or 0),
			}

			return itemInfo
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
			local itemInfo = self:GetInventoryItemInfo(REAGENTBANK_CONTAINER, slotID)
			if itemInfo then
				local categoryName = itemInfo.subclass or "Other"

				if itemInfo.expacID then
					itemInfo.sortString = itemInfo.expacID .. itemInfo.sortString
				end
				if not inventory[categoryName] then inventory[categoryName] = {} end
				tinsert(inventory[categoryName], itemInfo)
			end
		end
	else
		for _,bagID in pairs(container.bag_ids) do
			for slotID=1, GetContainerNumSlots(bagID) do
				local itemInfo = self:GetInventoryItemInfo(bagID, slotID)
				if itemInfo then
					local categoryName = self:GetItemCategory(itemInfo)

					if not inventory[categoryName] then inventory[categoryName] = {} end
					tinsert(inventory[categoryName], itemInfo)
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