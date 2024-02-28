local st = SaftUI
local INV = st:GetModule('Inventory')


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

INV.AUTO_VENDOR_CATEGORIES = {}

local CONDUIT_TEXT = "Add this Conduit to your collection"
local ANIMA_TEXT = "stored Anima into your covenant's Reservoir"
local RIGHT_CLICK_TO_OPEN = "Right Click to Open"
local OPEN_THE_CONTAINER = "Open the container"
local OPEN_THE_SACK = "Open the sack"
local USE_COLLECT = "Use: collect"
local TOY_TEXT = "Adds this toy to your Toy Box"
local BLUEPRINT_TEXT = "Blueprint: "
local ARTIFACT_RELIC_TEXT = "Artifact Relic"
local USE_TEXT = "Use:"
local USE_GRANTS = "Use: Grants ([,%d]+) reputation"
local EQUIP_EFFECT_TEXT = "Equip:"
local COSMETIC_TEXT = "Cosmetic"
local BIND_ON_ACCOUNT = "Account Bound"
local TRAINING_STONE_TEXT = "Battle-Training Stone"
local BATTLE_STONE_TEXT = "Battle-Stone"
local RESTORED_ARTIFACT_TEXT = "Carefully crate the restored artifact"
local TRADEABLE_ITEM = "You may trade this item with players"
local DRAGON_ISLES_PROFESSION = "Study to increase your Dragon Isles"
local RED_CLASS = 'cffff2020Classes:'

local function isLegacyGear(item)
	if not (item.class == 'Armor' or item.class == 'Weapon') then
		return false
	end

	local requiredLevelDifference = UnitLevel('player') - item.reqLevel
	if UnitLevel('player') ~= MAX_PLAYER_LEVEL then
		return false
	end

    if item.expacID > 7
    or item.equipSlot == "INVTYPE_TABARD"
    or item.equipSlot == "INVTYPE_BODY"
    or not (item.quality >= 2 and item.quality <=4)
    or string.matchnocase(item.tooltipText, TRADEABLE_ITEM)
    or string.matchnocase(item.tooltipText, BIND_ON_ACCOUNT)
    or string.matchnocase(item.tooltipText, COSMETIC_TEXT)
    or string.matchnocase(item.tooltipText, USE_TEXT)
    or string.matchnocase(item.tooltipText, EQUIP_EFFECT_TEXT)
	or not string.matchnocase(item.tooltipText, ARTIFACT_RELIC_TEXT)
	then return false end

	return true
end

INV.filters = {
	itemrack = {},
	categories = {},
	currency = {},
}

function INV:AddFilter(name, func, options)
	if not options then options = {} end
	tinsert(self.filters.categories, options['index'] or #self.filters.categories+1, { name = name, func = func })

	if options['autoVendor'] then
		tinsert(INV.AUTO_VENDOR_CATEGORIES, name)
	end
end

INV:AddFilter("Grays/Auto Vendor", function(item)
	-- A lot of special holiday stuff falls into these categories and we should never auto vendor them
	if item.subclass == "Cosmetic" then return false end

	if item.ilvl <= 4
	or string.matchnocase(item.tooltipText, "Fishing")
	or string.matchnocase(item.tooltipText, "Blizzard Account Bound") then
		return false
	end

	-- Can't vendor priceless items..
	if item.vendorPrice == 0 then return false end

	return item.quality == 0
		or (isLegacyGear(item) and item.quality < 5)
		or item.soulbound and string.matchnocase(item.tooltipText, RED_CLASS)
		or INV:ShouldAutoVendor(item.itemID)
end, { autoVendor = true })

INV:AddFilter("Reputation", function(item)
	return string.matchnocase(item.tooltipText, USE_GRANTS)
end)

INV:AddFilter("Container", function(item)
	return string.matchnocase(item.tooltipText, RIGHT_CLICK_TO_OPEN)
		or string.matchnocase(item.tooltipText, OPEN_THE_CONTAINER)
		or string.matchnocase(item.tooltipText, OPEN_THE_SACK)
		or string.matchnocase(item.tooltipText, USE_COLLECT)
		or string.matchnocase(item.tooltipText, "Flightstones")
end)

INV:AddFilter("Toys", function(item)
	return string.matchnocase(item.tooltipText, TOY_TEXT)
end)

INV:AddFilter("Anima", function(item)
	return string.matchnocase(item.tooltipText, ANIMA_TEXT)
end)

INV:AddFilter("Conduits", function(item)
	return string.matchnocase(item.tooltipText, CONDUIT_TEXT)
end)

INV:AddFilter("Blueprints", function(item)
	return string.matchnocase(item.name, BLUEPRINT_TEXT)
end)

INV:AddFilter("Pets", function(item)
	return string.matchnocase(item.name, BATTLE_STONE_TEXT)
		or string.matchnocase(item.name, TRAINING_STONE_TEXT)
		or item.subclass == 'Companion Pets'
		or item.class == 'Battle Pet'
end)

INV:AddFilter("Mounts", function(item)
	return item.subclass == 'Mount'
end)

INV:AddFilter("Flasks/Potions/Food", function(item)
	return item.subclass == 'Flasks & Phials'
		or item.subclass == 'Potions'
		or item.subclass == 'Food & Drink'
end)

INV:AddFilter("Consumables", function(item)
	return item.class == 'Consumable'
end)

INV:AddFilter("Armor", function(item)
	return item.class == 'Armor'
end)

INV:AddFilter("Weapons", function(item)
	return item.class == 'Weapon'
end)

INV:AddFilter("Archaeology", function(item)
	return customItemLists.Archaeology[item.itemID]
		or string.matchnocase(item.tooltipText, RESTORED_ARTIFACT_TEXT)
end)

INV:AddFilter("Professions/Recipes", function(item)
	return item.itemID == 191784 -- Dragon Shard of Knowledge
		or string.matchnocase(item.tooltipText, DRAGON_ISLES_PROFESSION)
		or item.class == 'Recipe'
end)

INV:AddFilter("Emerald Dream", function(item)
	return string.matchnocase(item.name, "dreamseed")
		or string.matchnocase(item.name, "dreamsurge")
end)

INV:AddFilter("Trade Goods", function(item)
	return item.class == 'Trade Goods'
		or item.class == 'Gem'
		or item.class == 'Tradeskill'
end)

INV:AddFilter("Devices", function(item)
	return item.subclass == 'Devices'
end)

INV:AddFilter("Quest", function(item)
	return item.class == 'Quest'
end)

INV:AddFilter("Keys", function(item)
	return item.class == 'Key'
		or item.name:lower():match('%f[%a]key%f[%A]')
end)

INV:AddFilter("Miscellaneous", function(item)
	return true
end)