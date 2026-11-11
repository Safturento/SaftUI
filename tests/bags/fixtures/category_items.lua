-- Items for the default categories (category_defaults_test.lua): at least one
-- for every default, the ones each must not catch, and today's overlaps. Not a
-- test (no _test suffix): load it with
-- load_test_file('bags/fixtures/category_items.lua').
--
-- Each is { label, item = <bag_world W.item fields>, expect = '<key>' }, with:
--   - the item's classID and subclassID given, so its class and subclass names
--     are the ones the world's client gives them (bag_world's C_Item);
--   - client = 'forever' or 'retail' for an item only that client has (or that
--     only one client files this way); none for both;
--   - protected = true for an item on the Protected list;
--   - changed = true where the defaults file it differently from today's
--     filters on purpose (the plan's list), so expect is the new key.
-- Every itemID and name is its own: tooltips are cached by link.
--
-- Read in a world where the player is level 80 with an average item level of
-- 300 (the old gear items are measured against that).
return {
	-- Equipment sets
	{ 'a plate helm in the set "Tank"', item = { itemID = 1001, name = 'Tank Helm', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_HEAD', quality = 4, reqLevel = 80, ilvl = 300, set = 'Tank' }, expect = 'Set: Tank' },

	-- Grays/Auto Vendor: caught
	{ 'a grey "Broken Fang"', item = { itemID = 1101, name = 'Broken Fang', classID = 15, subclassID = 0, quality = 0 },
		expect = 'Grays/Auto Vendor' },
	{ 'old gear: rare plate, level 30, expansion 2, item level 60', item = { itemID = 1102, name = 'Old Plate Legs',
		classID = 4, subclassID = 4, equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 2, ilvl = 60 },
		expect = 'Grays/Auto Vendor' },
	{ 'a soulbound robe with the red Classes: line', item = { itemID = 1103, name = 'Robe of the Archmage',
		classID = 4, subclassID = 1, equipLoc = 'INVTYPE_ROBE', reqLevel = 80, ilvl = 300, isBound = true,
		tooltip = { 'Robe of the Archmage', 'Soulbound', '|cffff2020Classes: Mage|r' } }, expect = 'Grays/Auto Vendor' },
	{ 'old gear: a weapon', item = { itemID = 1104, name = 'Old Blade', classID = 2, subclassID = 7,
		equipLoc = 'INVTYPE_WEAPON', quality = 2, reqLevel = 30, expacID = 2, ilvl = 60 }, expect = 'Grays/Auto Vendor' },
	{ 'old gear: epic, at exactly 90% of the average item level, 10 levels below', item = { itemID = 1105,
		name = 'Old Epic Helm', classID = 4, subclassID = 3, equipLoc = 'INVTYPE_HEAD', quality = 4, reqLevel = 70,
		expacID = 9, ilvl = 270 }, expect = 'Grays/Auto Vendor' },

	-- Grays/Auto Vendor: not caught
	{ 'a Protected grey', item = { itemID = 1111, name = 'Kept Fang', classID = 15, subclassID = 0, quality = 0 },
		protected = true, expect = 'Miscellaneous' },
	{ 'grey Cosmetic armor', item = { itemID = 1112, name = 'Festive Hat', classID = 4, subclassID = 5,
		equipLoc = 'INVTYPE_HEAD', quality = 0 }, expect = 'Armor' },
	{ 'a grey with "Fishing"', item = { itemID = 1113, name = 'Old Bobber', classID = 15, subclassID = 0, quality = 0,
		tooltip = { 'Old Bobber', 'Fishing' } }, expect = 'Miscellaneous' },
	{ 'a grey with "Blizzard Account Bound"', item = { itemID = 1114, name = 'Old Coin', classID = 15, subclassID = 0,
		quality = 0, tooltip = { 'Old Coin', 'Blizzard Account Bound' } }, expect = 'Miscellaneous' },
	{ 'a grey with no vendor price', item = { itemID = 1115, name = 'Worthless Shard', classID = 15, subclassID = 0,
		quality = 0, vendorPrice = 0 }, expect = 'Miscellaneous' },
	{ 'old gear 9 levels below', item = { itemID = 1116, name = 'Recent Legs', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 71, expacID = 2, ilvl = 60 }, expect = 'Armor' },
	{ 'old gear from expansion 10', item = { itemID = 1117, name = 'New Expansion Legs', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 10, ilvl = 60 }, expect = 'Armor' },
	{ 'old gear over 90% of the average item level', item = { itemID = 1118, name = 'Timewalking Legs',
		classID = 4, subclassID = 4, equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 2, ilvl = 271 },
		expect = 'Armor' },
	{ 'old gear that is legendary', item = { itemID = 1119, name = 'Old Legendary Legs', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_LEGS', quality = 5, reqLevel = 30, expacID = 2, ilvl = 60 }, expect = 'Armor' },
	{ 'old gear that is common', item = { itemID = 1120, name = 'Old Common Legs', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_LEGS', quality = 1, reqLevel = 30, expacID = 2, ilvl = 60 }, expect = 'Armor' },
	{ 'old gear you may still trade', item = { itemID = 1121, name = 'Tradeable Legs', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 2, ilvl = 60,
		tooltip = { 'You may trade this item with players that were also eligible to loot this item' } },
		expect = 'Armor' },
	{ 'old gear that is account bound', item = { itemID = 1122, name = 'Heirloom Legs', classID = 4, subclassID = 4,
		equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 2, ilvl = 60,
		tooltip = { 'Account Bound' } }, expect = 'Armor' },
	{ 'old gear with "Cosmetic" in its tooltip', item = { itemID = 1123, name = 'Costume Legs', classID = 4,
		subclassID = 4, equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 2, ilvl = 60,
		tooltip = { 'Cosmetic' } }, expect = 'Armor' },
	{ 'old gear that is warbound until equipped', item = { itemID = 1124, name = 'Warbound Old Legs', classID = 4,
		subclassID = 4, equipLoc = 'INVTYPE_LEGS', quality = 3, reqLevel = 30, expacID = 2, ilvl = 60,
		accountUntilEquip = true }, expect = 'Armor (Warbound)' },
	{ 'a soulbound robe with a white Classes: line', item = { itemID = 1125, name = 'Robe of the Apprentice',
		classID = 4, subclassID = 1, equipLoc = 'INVTYPE_ROBE', reqLevel = 80, ilvl = 300, isBound = true,
		tooltip = { 'Robe of the Apprentice', 'Soulbound', 'Classes: Mage' } }, expect = 'Armor' },
	{ 'a robe with the red Classes: line, not soulbound', item = { itemID = 1126, name = 'Robe of the Magus',
		classID = 4, subclassID = 1, equipLoc = 'INVTYPE_ROBE', reqLevel = 80, ilvl = 300,
		tooltip = { 'Robe of the Magus', '|cffff2020Classes: Mage|r' } }, expect = 'Armor' },

	-- The tier token groups
	{ 'a token for Rogue, Death Knight, Mage, Druid', item = { itemID = 1201, name = 'Dreadful Helm Module',
		classID = 15, subclassID = 0, quality = 4, tooltip = { 'Dreadful Helm Module', 'Classes: Rogue, Death Knight, Mage, Druid' } },
		expect = 'Rogue/DK/Mage/Druid' },
	{ 'a mail helm for Warrior, Hunter, Shaman (not Armor)', item = { itemID = 1202, name = 'Mystic Helm', classID = 4,
		subclassID = 3, equipLoc = 'INVTYPE_HEAD', quality = 4, reqLevel = 80, ilvl = 300,
		tooltip = { 'Mystic Helm', 'Classes: Warrior, Hunter, Shaman' } }, expect = 'Warrior/Hunter/Shaman' },
	{ 'a token for Paladin, Priest, Warlock', item = { itemID = 1203, name = 'Conqueror Chest Token', classID = 15,
		subclassID = 0, quality = 4, tooltip = { 'Classes: Paladin, Priest, Warlock' } }, expect = 'Paladin/Priest/Warlock' },
	{ 'a token for Warrior, Rogue, Monk', item = { itemID = 1204, name = 'Zenith Chest Token', classID = 15,
		subclassID = 0, quality = 4, tooltip = { 'Classes: Warrior, Rogue, Monk' } }, expect = 'Warrior/Rogue/Monk' },
	{ 'a token for Hunter, Mage, Druid', item = { itemID = 1205, name = 'Mystic Chest Token', classID = 15,
		subclassID = 0, quality = 4, tooltip = { 'Classes: Hunter, Mage, Druid' } }, expect = 'Hunter/Mage/Druid' },
	{ 'a token for Paladin, Priest, Shaman', item = { itemID = 1206, name = 'Venerated Chest Token', classID = 15,
		subclassID = 0, quality = 4, tooltip = { 'Classes: Paladin, Priest, Shaman' } }, expect = 'Paladin/Priest/Shaman' },
	{ 'a token for Death Knight, Warlock, Demon Hunter', item = { itemID = 1207, name = 'Dreadful Chest Token',
		classID = 15, subclassID = 0, quality = 4, tooltip = { 'Classes: Death Knight, Warlock, Demon Hunter' } },
		expect = 'Death Knight/Warlock/Demon Hunter' },

	{ 'a Secrets of Azeroth item', item = { itemID = 1301, name = 'Torch of Pyrreth', classID = 15, subclassID = 4,
		tooltip = { 'Torch of Pyrreth', 'Secrets of Azeroth' } }, expect = 'Secrets of Azeroth' },
	{ 'a reputation token', item = { itemID = 1302, name = 'Dreamy Insignia', classID = 15, subclassID = 4,
		tooltip = { 'Dreamy Insignia', 'Use: Grants 1,500 reputation with the Dream Wardens.' } }, expect = 'Reputation' },

	-- Delves
	{ 'right text "Combat Curio"', item = { itemID = 1401, name = 'Ebon Bulwark', classID = 15, subclassID = 4,
		tooltip = { 'Ebon Bulwark', { 'Unique', 'Combat Curio' } } }, expect = 'Delves' },
	{ "Delver's Bounty", item = { itemID = 1402, name = "Delver's Bounty", classID = 15, subclassID = 4 },
		expect = 'Delves' },
	{ "Trovehunter's Bounty", item = { itemID = 1403, name = "Trovehunter's Bounty", classID = 15, subclassID = 4 },
		expect = 'Delves' },
	{ '"Curious Coin", whose tooltip says "Curious"', item = { itemID = 1404, name = 'Curious Coin', classID = 15,
		subclassID = 4, tooltip = { 'Curious Coin', 'A Curious coin from far away.' } },
		expect = 'Miscellaneous', changed = true },

	-- Container
	{ '"<Right Click to Open>"', item = { itemID = 1501, name = 'Satchel of Spoils', classID = 15, subclassID = 4,
		tooltip = { 'Satchel of Spoils', '<Right Click to Open>' } }, expect = 'Container' },
	{ 'a Flightstones pouch', item = { itemID = 1502, name = 'Pouch of Stones', classID = 15, subclassID = 4,
		tooltip = { 'Use: Gain 15 Flightstones.' } }, expect = 'Container' },
	{ 'armor with "Use: Open"', item = { itemID = 1503, name = 'Gilded Chest', classID = 4, subclassID = 1,
		equipLoc = 'INVTYPE_CHEST', reqLevel = 80, ilvl = 300, tooltip = { 'Use: Open a portal home.' } },
		expect = 'Armor' },
	{ 'a weapon with "Right Click to Open"', item = { itemID = 1504, name = 'Puzzle Blade', classID = 2, subclassID = 7,
		equipLoc = 'INVTYPE_WEAPON', reqLevel = 80, ilvl = 300, tooltip = { '<Right Click to Open>' } },
		expect = 'Weapons' },

	{ 'a toy', item = { itemID = 1601, name = 'Toy Train Set', classID = 15, subclassID = 4,
		tooltip = { 'Use: Adds this toy to your Toy Box.' } }, expect = 'Toys' },
	{ 'anima', item = { itemID = 1602, name = 'Anima Crystal', classID = 15, subclassID = 4,
		tooltip = { "Use: Deposit 35 stored Anima into your covenant's Reservoir." } }, expect = 'Anima' },
	{ 'a conduit', item = { itemID = 1603, name = 'Fortifying Ingredients', classID = 15, subclassID = 4,
		tooltip = { 'Use: Add this Conduit to your collection at the Forge of Bonds.' } }, expect = 'Conduits' },
	{ 'a blueprint', item = { itemID = 1604, name = 'Blueprint: Mechagon Tinkering', classID = 15, subclassID = 4 },
		expect = 'Blueprints' },

	-- Pets
	{ '"Flawless Battle-Stone"', item = { itemID = 1701, name = 'Flawless Battle-Stone', classID = 15, subclassID = 4 },
		expect = 'Pets' },
	{ '"Ultimate Battle-Training Stone"', item = { itemID = 1702, name = 'Ultimate Battle-Training Stone',
		classID = 15, subclassID = 4 }, expect = 'Pets' },
	{ 'a caged pet', item = { itemID = 1703, name = 'Mechanical Squirrel', quality = 3,
		link = '|Hbattlepet:339:25:3:1400:276:276|h[Mechanical Squirrel]|h' }, expect = 'Pets' },
	{ 'a Companion Pets item (15/2)', client = 'retail', item = { itemID = 1704, name = 'Squirrel in a Box',
		classID = 15, subclassID = 2 }, expect = 'Pets' },
	{ 'a Forever Pet item (15/2 is "Pet" there)', client = 'forever', item = { itemID = 1705,
		name = 'Squirrel in a Crate', classID = 15, subclassID = 2 }, expect = 'Miscellaneous' },
	-- Today's filter compared the class name "Battle Pet", which only a caged
	-- pet's info has; retail names class 17 "Battle Pets". The defaults go by
	-- the class ID (ruling C3).
	{ 'a retail item of class 17 ("Battle Pets") with an item link', client = 'retail', item = { itemID = 1706,
		name = 'Pet Cage', classID = 17, subclassID = 0 }, expect = 'Pets', changed = true },

	{ 'a housing item (class 20)', client = 'retail', item = { itemID = 1801, name = 'Wooden Chair', classID = 20,
		subclassID = 0 }, expect = 'Housing' },
	{ 'a mount (15/5)', item = { itemID = 1802, name = 'Reins of the Swift Spectral Tiger', classID = 15,
		subclassID = 5 }, expect = 'Mounts' },

	-- Flasks/Potions/Food, Gems/Enchants, Consumables
	{ 'a potion (0/1)', item = { itemID = 1901, name = 'Healing Draught', classID = 0, subclassID = 1 },
		expect = 'Flasks/Potions/Food' },
	{ 'food (0/5)', item = { itemID = 1902, name = 'Roasted Boar Meat', classID = 0, subclassID = 5 },
		expect = 'Flasks/Potions/Food' },
	{ 'a retail flask (0/3, "Flasks & Phials")', client = 'retail', item = { itemID = 1903, name = 'Flask of Power',
		classID = 0, subclassID = 3 }, expect = 'Flasks/Potions/Food' },
	{ 'a Forever flask (0/3, "Flasks")', client = 'forever', item = { itemID = 1904, name = 'Flask of Titans',
		classID = 0, subclassID = 3 }, expect = 'Consumables' },
	{ 'a retail gem (class 3)', client = 'retail', item = { itemID = 1905, name = 'Inscribed Opal', classID = 3,
		subclassID = 0 }, expect = 'Gems/Enchants' },
	{ 'a retail enchant (class 8, "Item Enhancement")', client = 'retail', item = { itemID = 1906,
		name = 'Enchant Chest Vellum', classID = 8, subclassID = 4 }, expect = 'Miscellaneous' },
	{ 'a consumable (0/8)', item = { itemID = 1907, name = 'Rune of Warding', classID = 0, subclassID = 8 },
		expect = 'Consumables' },
	{ 'a Devices consumable (0/14) goes to Consumables, which comes first', item = { itemID = 1908,
		name = 'Goblin Rocket Launcher', classID = 0, subclassID = 14 }, expect = 'Consumables' },

	-- Armor and weapons
	{ 'a chest warbound until equipped', item = { itemID = 2001, name = 'Warbound Breastplate', classID = 4,
		subclassID = 4, equipLoc = 'INVTYPE_CHEST', quality = 3, reqLevel = 80, ilvl = 300, accountUntilEquip = true },
		expect = 'Armor (Warbound)' },
	{ 'a cloth chest', item = { itemID = 2002, name = 'Cloth Vest', classID = 4, subclassID = 1,
		equipLoc = 'INVTYPE_CHEST', reqLevel = 80, ilvl = 300 }, expect = 'Armor' },
	{ 'a sword', item = { itemID = 2003, name = 'Steel Sword', classID = 2, subclassID = 7, equipLoc = 'INVTYPE_WEAPON',
		reqLevel = 80, ilvl = 300 }, expect = 'Weapons' },
	{ 'a grey sword', item = { itemID = 2004, name = 'Rusty Sword', classID = 2, subclassID = 7,
		equipLoc = 'INVTYPE_WEAPON', quality = 0, reqLevel = 80, ilvl = 300 }, expect = 'Grays/Auto Vendor' },

	-- Archaeology, Professions/Recipes
	{ 'Archaeology item 52843', item = { itemID = 52843, name = 'Dwarf Rune Stone', classID = 15, subclassID = 4 },
		expect = 'Archaeology' },
	{ 'a restored artifact crate line', item = { itemID = 2101, name = 'Restored Artifact', classID = 15, subclassID = 4,
		tooltip = { 'Use: Carefully crate the restored artifact.' } }, expect = 'Archaeology' },
	{ 'item 191784', item = { itemID = 191784, name = 'Dragon Shard of Knowledge', classID = 15, subclassID = 4 },
		expect = 'Professions/Recipes' },
	{ 'a profession study item', item = { itemID = 2102, name = "Alchemist's Notes", classID = 15, subclassID = 4,
		tooltip = { 'Use: Study to increase your Alchemy knowledge by 1.' } }, expect = 'Professions/Recipes' },
	{ 'a recipe (class 9)', item = { itemID = 2103, name = 'Recipe: Elixir of Wisdom', classID = 9, subclassID = 6 },
		expect = 'Professions/Recipes' },

	-- Emerald Dream, Trade Goods, Quest, Keys, Miscellaneous
	{ 'a trade good "Emerald Dreamseed" (not Trade Goods)', item = { itemID = 2201, name = 'Emerald Dreamseed',
		classID = 7, subclassID = 11 }, expect = 'Emerald Dream' },
	{ 'a herb "Peacebloom" (7/9)', item = { itemID = 2202, name = 'Peacebloom', classID = 7, subclassID = 9 },
		expect = 'Trade Goods' },
	{ 'a quest item "Rusty Key" (not Keys)', item = { itemID = 2203, name = 'Rusty Key', classID = 12, subclassID = 0 },
		expect = 'Quest' },
	{ '"Skeleton Key" (class 13)', item = { itemID = 2204, name = 'Skeleton Key', classID = 13, subclassID = 0 },
		expect = 'Keys' },
	{ 'a keystone', item = { itemID = 2205, name = 'Keystone: Darkflame Cleft', quality = 4,
		link = '|Hkeystone:180653:504:11:162:10:9:0:0|h[Keystone: Darkflame Cleft (11)]|h' }, expect = 'Keys' },
	{ 'a Miscellaneous item "Key-Ring of Doom"', item = { itemID = 2206, name = 'Key-Ring of Doom', classID = 15,
		subclassID = 4 }, expect = 'Keys' },
	{ '"Monkey Paw" ("key" inside a word)', item = { itemID = 2207, name = 'Monkey Paw', classID = 15, subclassID = 4 },
		expect = 'Miscellaneous' },
	{ '"Lucky Rock"', item = { itemID = 2301, name = 'Lucky Rock', classID = 15, subclassID = 4 },
		expect = 'Miscellaneous' },
}
