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

INV.categoryNames = {
	['TRASH'] = 'Grays/Auto Vendor',
	['FLASKS_POTIONS'] = 'Flasks/Potions',
	['FLASKS'] = 'Flasks',
	['POTIONS'] = 'Potions',
	['CONSUMABLES'] = 'Consumables',
	['LEGACY_ARMOR_WEAPONS'] = 'Legacy Armor/Weapons',
	['ARMOR'] = 'Armor',
	['WEAPONS'] = 'Weapons',
	['ARCHAEOLOGY'] = 'Archaeology',
	['TRADE_GOODS'] = 'Trade Goods',
	['RECIPES'] = 'Professions/Recipes',
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

INV.AUTO_VENDOR_CATEGORIES = {
	INV.categoryNames.TRASH,
	INV.categoryNames.LEGACY_ARMOR_WEAPONS
}

local CONDUIT_TEXT = "Add this Conduit to your collection"
local ANIMA_TEXT = "stored Anima into your covenant's Reservoir"
local CONTAINER_RIGHT_CLICK = "Right Click to Open"
local CONTAINER_OPEN = "Open the container"
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
local DRAGON_ISLES_PROFESSION = "Study to increase your Dragon Isles"
local RED_CLASS = 'cffff2020Classes:'

local function isLegacyGear(item)
	if not (item.class == 'Armor' or item.class == 'Weapon') then
		return false
	end

	local requiredLevelDifference = UnitLevel('player') - item.reqLevel
	if UnitLevel('player') ~= MAX_PLAYER_LEVEL and requiredLevelDifference > 10 or requiredLevelDifference > 20 then
		return true
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
	categories = {
		[1] = {
			name = INV.categoryNames.TRASH,
			func = function(item)
				return item.quality == 0
					or item.soulbound and string.matchnocase(item.tooltipText, RED_CLASS)
					or INV:ShouldAutoVendor(item.itemID)
			end
		},
		[2] = {
			name = INV.categoryNames.TOY,
			func = function(item)
				return string.matchnocase(item.tooltipText, TOY_TEXT)
			end
		},
		[3] = {
			name = INV.categoryNames.ANIMA,
			func = function(item)
				return string.matchnocase(item.tooltipText, ANIMA_TEXT)
			end
		},
		[4] = {
			name = INV.categoryNames.CONDUITS,
			func = function(item)
				return string.matchnocase(item.tooltipText, CONDUIT_TEXT)
			end
		},
		[5] = {
			name = INV.categoryNames.BLUEPRINT,
			func = function(item)
				return string.matchnocase(item.name, BLUEPRINT_TEXT)
			end
		},
		[6] = {
			name = INV.categoryNames.BATTLE_STONES,
			func = function(item)
				return string.matchnocase(item.name, BATTLE_STONE_TEXT)
					or string.matchnocase(item.name, TRAINING_STONE_TEXT)
			end
		},
		[7] = {
			name = INV.categoryNames.CONTAINER,
			func = function(item)
				return string.matchnocase(item.tooltipText, CONTAINER_RIGHT_CLICK)
					or string.matchnocase(item.tooltipText, CONTAINER_OPEN)
			end
		},
		[8] = {
			name = INV.categoryNames.FLASKS,
			func = function(item)
				return item.subclass == 'Flask'
			end
		},
		[9] = {
			name = INV.categoryNames.POTIONS,
			func = function(item)
				return item.subclass == 'Potion'
			end
		},
		[10] = {
			name = INV.categoryNames.CONSUMABLES,
			func = function(item)
				return item.class == 'Consumable'
			end
		},
		[11] = {
			name = INV.categoryNames.LEGACY_ARMOR_WEAPONS,
			func = function(item)
				return isLegacyGear(item)
			end
		},
		[12] = {
			name = INV.categoryNames.ARMOR,
			func = function(item)
				return item.class == 'Armor'
			end
		},
		[13] = {
			name = INV.categoryNames.WEAPONS,
			func = function(item)
				return item.class == 'Weapon'
			end
		},
		[14] = {
			name = INV.categoryNames.ARCHAEOLOGY,
			func = function(item)
				return customItemLists.Archaeology[item.itemID]
						or string.matchnocase(item.tooltipText, RESTORED_ARTIFACT_TEXT)
			end
		},
		[15] = {
			name = INV.categoryNames.RECIPES,
		  	func = function(item)
				return item.itemID == 191784 -- Dragon Shard of Knowledge
					or string.matchnocase(item.tooltipText, DRAGON_ISLES_PROFESSION)
					or item.class == 'Recipe'
			end
		},
		[16] = {
			name = INV.categoryNames.TRADE_GOODS,
			func = function(item)
				return item.class == 'Trade Goods'
					or item.class == 'Gem'
					or item.class == 'Tradeskill'
			end
		},
		[17] = {
			name = INV.categoryNames.DEVICES,
			func = function(item)
				return item.subclass == 'Devices'
			end
		},
		[18] = {
			name = INV.categoryNames.PETS,
			func = function(item)
				return item.subclass == 'Companion Pets'
					or item.subclass == 'Mount'
			end
		},
		[19] = {
			name = INV.categoryNames.MOUNTS,
			func = function(item)
				return item.subclass == 'Companion Pets'
					or item.subclass == 'Mount'
			end
		},
		[20] = {
			name = INV.categoryNames.QUEST,
			func = function(item)
				return item.class == 'Quest'
			end
		},
		[21] = {
			name = INV.categoryNames.KEYS,
			func = function(item)
				return item.class == 'Key'
					or item.name:lower():match('%f[%a]key%f[%A]')
			end
		},
		[22] = {
			name = INV.categoryNames.MISCELLANEOUS,
			func = function(item)
				return true
			end
		},
	}
}