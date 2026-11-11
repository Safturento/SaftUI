-- The data behind the bag views (SaftUI-Bags/views.lua and the empty slot
-- building in category.lua): the category order every view shares, bag info
-- and which bags are special, the section lists of One bag, Multi bag and
-- Rows, empty slots by mode for every window, and Compact's inventory staying
-- what it was. Nothing here draws. bags/bag_world.lua loads the real files over a stubbed bag world.
local W = load_test_file('bags/bag_world.lua')

local INV

-- Item infos as text, in order: names, an empty slot as <empty> or <empty xN>.
local function names(items)
	local out = {}
	for i, info in ipairs(items) do
		out[i] = info.empty and ('<empty' .. (info.count and (' x' .. info.count) or '') .. '>') or info.name
	end
	return table.concat(out, ',')
end

local function titles(sections)
	local out = {}
	for i, s in ipairs(sections) do out[i] = s.title == false and '-' or s.title end
	return table.concat(out, ' | ')
end

local function kinds(sections)
	local out = {}
	for i, s in ipairs(sections) do out[i] = s.kind end
	return table.concat(out, ',')
end

local function section(sections, key)
	for _, s in ipairs(sections) do if s.key == key then return s end end
end

local function count_empty(items)
	local n = 0
	for _, info in ipairs(items) do if info.empty then n = n + 1 end end
	return n
end

-- Backpack 20 slots, bag 1 (10 slots), and a third bag: on Forever a herb bag
-- (bag 2, family 32, 12 slots, two herbs), on retail the reagent bag (bag 5,
-- 36 slots, two reagents). The ilvl is what the item sort goes by (higher
-- first). Returns the bag window's container, with a Currencies category.
local function world(client)
	INV = W.fresh(client)
	W.bag(0, 20, 'Backpack')
	W.bag(1, 10, 'Bag')
	W.put(0, 1, W.item(1, 'Sword', 'Weapon', 50))
	W.put(0, 2, W.item(2, 'Elixir', 'Consumable', 10))
	W.put(0, 3, W.item(3, 'Helm', 'Armor', 60))
	W.put(0, 4, W.item(4, 'Rock', 'Quest', 25))
	W.put(0, 5, W.item(5, 'Plank', 'Trade Goods', 15))
	W.put(1, 1, W.item(6, 'Axe', 'Weapon', 70))
	W.put(1, 2, W.item(7, 'Tonic', 'Consumable', 20))
	if client == 'retail' then
		W.bag(5, 36, 'Reagent Bag')
		W.put(5, 1, W.item(8, 'Sunblossom', 'Trade Goods', 19))
		W.put(5, 2, W.item(9, 'Bar', 'Trade Goods', 18))
	else
		W.bag(2, 12, 'Herb Bag', 32)
		W.put(2, 1, W.item(8, 'Sunblossom', 'Trade Goods', 19))
		W.put(2, 2, W.item(9, 'Peacebloom', 'Trade Goods', 18))
	end
	INV.config.stackItems = false
	local container = W.container('bag')
	container.categories.Currencies = {}
	return container
end

-- Free slots in that world: backpack 15, bag 1 8; herb bag 10 or reagent bag 34.

test('CategoryRank follows the list: sets, then the list, then an unknown key, then Miscellaneous, then Empty Slots', function()
	world()
	local list = INV:GetCategoryList()
	local n = #list
	eq(list[1].id, 'Equipment sets', 'the sets entry is first by default')
	eq(INV:CategoryRank('Set: Alpha'), 1, "a set ranks as the sets entry")
	eq(INV:CategoryRank('Set: Zed'), 1, 'every set shares its rank')
	eq(INV:CategoryRank('Grays/Auto Vendor'), 2, 'the first rule')
	eq(INV:CategoryRank('Weapons'), list.byId.Weapons.place, 'a category is its place in the list')
	eq(INV:CategoryRank('Miscellaneous'), n, 'Miscellaneous, last')
	eq(INV:CategoryRank('Herb'), n - 0.5, 'a key the list lacks (a deleted category still on screen): before Miscellaneous')
	eq(INV:CategoryRank('Other'), n - 0.5, 'Other likewise')
	eq(INV:CategoryRank(INV.EMPTY_SLOTS_CATEGORY), n + 1, 'Empty Slots, after the list')

	local function order(keys)
		table.sort(keys, function(a, b) return INV:CategoryBefore(a, b) end)
		return table.concat(keys, ' | ')
	end
	eq(order({ 'Empty Slots', 'Miscellaneous', 'Herb', 'Weapons', 'Set: Zed', 'Consumables', 'Set: Alpha', 'Armor' }),
		'Set: Alpha | Set: Zed | Consumables | Armor | Weapons | Herb | Miscellaneous | Empty Slots',
		'sets by name, the list in order, unknown keys, Miscellaneous, Empty Slots')
	eq(order({ 'Other', 'Herb' }), 'Herb | Other', 'unknown keys by name')

	-- A saved order: Weapons first, the sets entry after Armor. Ranks follow it.
	local ids = {}
	for _, entry in ipairs(list) do
		if entry.id ~= 'Weapons' and entry.id ~= 'Equipment sets' then ids[#ids + 1] = entry.id end
		if entry.id == 'Armor' then ids[#ids + 1] = 'Equipment sets' end
	end
	table.insert(ids, 1, 'Weapons')
	INV:CategoryStore().order = ids
	INV:CategoryStore().edits.Armor = { name = 'Gear' }
	INV:CategoriesChanged()
	eq(INV:CategoryRank('Weapons'), 1, 'moved first, Weapons ranks first')
	eq(INV:CategoryRank('Set: Alpha'), INV:CategoryRank('Armor') + 1, 'a set ranks where the sets entry is now')
	eq(order({ 'Set: Alpha', 'Armor', 'Weapons', 'Consumables', 'Miscellaneous' }),
		'Weapons | Consumables | Armor | Set: Alpha | Miscellaneous', 'the order follows')
	eq(INV:CategoryRank('Armor'), INV:GetCategoryList().byId.Armor.place, 'a renamed category keeps its key and rank')
end)

test('SortByPriority: category priority, then the item sort, empty slots last', function()
	world()
	local read = {}
	for slot = 1, 5 do read[#read + 1] = INV:GetInventoryItemInfo(0, slot, 'bag') end
	read[#read + 1] = INV:GetInventoryItemInfo(1, 1, 'bag')
	table.insert(read, 1, { empty = true, name = '', tooltipText = '', sortString = '', vendorPrice = 0, bagID = 0, slotID = 9 })
	local same = INV:SortByPriority(read)
	eq(same, read, 'sorts in place and returns the list')
	eq(names(read), 'Elixir,Helm,Axe,Sword,Plank,Rock,<empty>',
		'consumables, armor, weapons (the axe first: higher item level), trade goods, quest, then the empty slot')
end)

test('GetBagInfo: id, name, total, free and special; the backpack is never special', function()
	world()
	local pack = INV:GetBagInfo(0)
	eq(pack.id, 0, 'id'); eq(pack.name, 'Backpack', 'name from the client'); eq(pack.total, 20, 'total')
	eq(pack.free, 15, 'free'); eq(pack.special, false, 'the backpack is not special')
	eq(INV:GetBagInfo(1).special, false, 'a normal bag is not special')
	local herb = INV:GetBagInfo(2)
	eq(herb.special, true, 'a herb bag (family 32) is special')
	eq(herb.name, 'Herb Bag', 'its name'); eq(herb.total, 12, 'total'); eq(herb.free, 10, 'free')
	-- A backpack with a family is still not special.
	W.bags[0].family = 32
	eq(INV:GetBagInfo(0).special, false, 'the backpack is never special')
end)

test('GetBagInfo: a name the client lacks falls back to a tab name, then Backpack, Bank tab N, Bag N', function()
	world()
	W.bags[0].name, W.bags[1].name = nil, nil
	eq(INV:GetBagInfo(0).name, 'Backpack', 'the backpack')
	eq(INV:GetBagInfo(1).name, 'Bag 1', 'a bag')
	local tab1, tab2 = INV.bagIds.bank[1], INV.bagIds.bank[2]
	W.bag(tab1, 98, nil); W.bag(tab2, 98, nil)
	eq(INV:GetBagInfo(tab1).name, 'Bank tab 1', 'a bank tab by its place in the bank')
	eq(INV:GetBagInfo(tab2).name, 'Bank tab 2', 'the second')
	-- The client names bank tabs the player renamed.
	_G.C_Bank = { FetchPurchasedBankTabData = function(bankType)
		return bankType == 0 and { { ID = tab2, name = 'Potions' } } or {}
	end }
	Enum.BankType = { Character = 0, Account = 2 }
	eq(INV:GetBagInfo(tab2).name, 'Potions', 'a tab name the client has')
	eq(INV:GetBagInfo(tab1).name, 'Bank tab 1', 'a tab it has no name for')
end)

test("GetBagInfo: a blank name from the client ('') is no name, so the fallbacks name the bag", function()
	world()
	-- C_Container.GetBagName never returns nil (Nilable = false on both clients).
	W.bags[0].name, W.bags[1].name = '', ''
	eq(INV:GetBagInfo(0).name, 'Backpack', 'the backpack')
	eq(INV:GetBagInfo(1).name, 'Bag 1', 'a bag')
	local tab1, tab2 = INV.bagIds.bank[1], INV.bagIds.bank[2]
	W.bag(tab1, 98, ''); W.bag(tab2, 98, '')
	eq(INV:GetBagInfo(tab1).name, 'Bank tab 1', 'a bank tab')
	_G.C_Bank = { FetchPurchasedBankTabData = function(bankType)
		return bankType == 0 and { { ID = tab2, name = 'Potions' } } or {}
	end }
	Enum.BankType = { Character = 0, Account = 2 }
	eq(INV:GetBagInfo(tab2).name, 'Potions', 'a tab the player named')
	eq(INV:GetBagInfo(tab1).name, 'Bank tab 1', 'and one they did not')
end)

test("special bags in the bank: Forever's bank bags by their family, never its base bank or retail's tabs", function()
	world('forever')
	local base, slot2, slot3 = INV.bagIds.bank[1], INV.bagIds.bank[2], INV.bagIds.bank[3]
	-- Forever: tab 1 is the base bank, each later tab a bag slot.
	W.bag(base, 28, 'Bank', 32)
	W.bag(slot2, 12, 'Herb Bag', 32)
	W.bag(slot3, 16, 'Bag')
	eq(INV:GetBagInfo(base).special, false, 'Forever: the base bank never, whatever its family')
	eq(INV:GetBagInfo(slot2).special, true, 'Forever: a herb bag in a bank bag slot is')
	eq(INV:GetBagInfo(slot3).special, false, 'Forever: a normal bag in one is not')

	world('retail')
	local tab2, warband2 = INV.bagIds.bank[2], INV.bagIds.warband[2]
	W.bag(tab2, 98, 'Tab', 32); W.bag(warband2, 98, 'Warband tab', 32)
	eq(INV:GetBagInfo(tab2).special, false, "retail: a bank tab never, whatever its family")
	eq(INV:GetBagInfo(warband2).special, false, 'retail: nor a warband tab')
end)

test('Forever bank in One bag: a herb bag in a bank bag slot has its own section, its items and free slots apart', function()
	world('forever')
	local base, slot2 = INV.bagIds.bank[1], INV.bagIds.bank[2]
	W.bag(base, 28, 'Bank')
	W.bag(slot2, 12, 'Herb Bag', 32)
	W.put(base, 1, W.item(30, 'Gold Bar', 'Trade Goods', 30))
	W.put(slot2, 1, W.item(31, 'Mageroyal', 'Trade Goods', 20))
	W.container('bank')
	INV.config.bank.emptySlots = 'grouped'
	local one = INV:GetViewSections('bank', 'onebag')
	eq(titles(one), '- | Herb Bag (1 / 12)', 'the main grid, then the herb bag, titled')
	eq(names(one[1].items), 'Gold Bar,<empty x27>', "main: the bank's items, and its free slots alone")
	eq(names(one[2].items), 'Mageroyal,<empty x11>', "the herb bag's, in its section")
end)

-- The grey a special bag's type is drawn in (the Colors tab's Text -> Grey), as
-- the color code in its title.
local function grey()
	local r, g, b = SaftUI.config.profile.colors.text.grey:GetRGB()
	return ('|cff%02x%02x%02x'):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

test("a Forever herb bag's section names its type after its name, in grey", function()
	world('forever')
	W.bag(2, 12, 'Mantid Satchel', 32, { [1] = W.item(8, 'Sunblossom', 'Trade Goods', 19), [2] = W.item(9, 'Peacebloom', 'Trade Goods', 18) })
	W.bag_item(2, 'Herb Bag')
	W.bag_item(1, 'Bag') -- a normal bag's item has a subtype too: it is no special bag
	local expected = 'Mantid Satchel ' .. grey() .. '\194\183 Herb Bag|r (2 / 12)'
	eq(INV:GetBagInfo(2).special, true, 'the herb bag is special')
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | ' .. expected .. ' | Currencies', 'Multi bag: only the special bag has a type')
	eq(titles(INV:GetViewSections('bag', 'onebag')), '- | ' .. expected .. ' | Currencies', 'One bag: under the main grid')
	eq(titles(INV:GetViewSections('bag', 'rows')):find('Herb Bag', 1, true), nil, "Rows' sections are categories: no bag title")
end)

test("the retail reagent bag's section names its type", function()
	world('retail')
	W.bags[5].name = "Shipwright's Satchel"
	W.bag_item(5, 'Reagent Bag')
	local expected = "Shipwright's Satchel " .. grey() .. '\194\183 Reagent Bag|r (2 / 36)'
	eq(titles(INV:GetViewSections('bag', 'onebag')), '- | ' .. expected .. ' | Currencies', 'One bag')
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | ' .. expected .. ' | Currencies', 'Multi bag')
end)

test('no type for a normal bag, the backpack, a bag whose item gives no subtype, or a type that is the name', function()
	world('forever')
	W.bag_item(1, 'Bag')
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies',
		'a normal bag, the backpack, and a herb bag with no bag item: no type')
	W.bag_item(2, nil) -- the item answers no subtype
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies', 'no subtype: no type')
	W.bag_item(2, '')
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies', 'an empty subtype: no type')
	W.bag_item(2, 'Herb Bag') -- named as its type: said once
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies', 'a name that is the type: not said twice')
	eq(#take_errors(), 0, 'no errors')
end)

test('a client without C_Item.GetItemInfoInstant uses the global one', function()
	world('forever')
	W.bag_item(2, 'Herb Bag')
	local instant = C_Item.GetItemInfoInstant
	C_Item.GetItemInfoInstant = nil
	_G.GetItemInfoInstant = instant
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies', 'named as its type: said once')
	W.bags[2].name = 'Mantid Satchel'
	eq(titles(INV:GetViewSections('bag', 'multibag')),
		'Backpack (5 / 20) | Bag (2 / 10) | Mantid Satchel ' .. grey() .. '\194\183 Herb Bag|r (2 / 12) | Currencies', 'the global answers')
end)

test("a Forever bank bag slot's herb bag names its type in the bank's sections", function()
	world('forever')
	local base, slot2 = INV.bagIds.bank[1], INV.bagIds.bank[2]
	W.bag(base, 28, 'Bank')
	W.bag(slot2, 12, 'Bank Satchel', 32)
	W.bag_item(slot2, 'Herb Bag')
	W.put(slot2, 1, W.item(31, 'Mageroyal', 'Trade Goods', 20))
	W.container('bank')
	eq(titles(INV:GetViewSections('bank', 'onebag')), '- | Bank Satchel ' .. grey() .. '\194\183 Herb Bag|r (1 / 12)', 'One bag')
	eq(INV:GetBagInfo(base).special, false, 'the base bank is no special bag')
	check(titles(INV:GetViewSections('bank', 'multibag')):find('Bank Satchel ' .. grey() .. '\194\183 Herb Bag|r (1 / 12)', 1, true),
		'Multi bag: its section too')
end)

test('Forever: no reagent bag; a profession bag is special', function()
	world('forever')
	eq(INV:IsReagentBag(5), false, 'no reagent bag')
	eq(INV:GetBagInfo(2).special, true, 'the herb bag is special')
	local sections = INV:GetViewSections('bag', 'multibag')
	eq(titles(sections), 'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies', 'three bags')
end)

test('retail: the reagent bag is special', function()
	world('retail')
	eq(INV:GetBagInfo(5).special, true, 'the reagent bag is special')
	eq(INV:GetBagInfo(1).special, false, 'a normal bag is not')
	local sections = INV:GetViewSections('bag', 'onebag')
	eq(titles(sections), '- | Reagent Bag (2 / 36) | Currencies', 'a main section, the reagent bag, currencies')
	eq(names(sections[2].items), 'Sunblossom,Bar', 'its items')
end)

test('onebag: one untitled main section in priority order, then a section per special bag, then currencies', function()
	local container = world('forever')
	local sections, numItems, numLoading = INV:GetViewSections('bag', 'onebag')
	eq(kinds(sections), 'main,bag,currencies', 'kinds')
	eq(titles(sections), '- | Herb Bag (2 / 12) | Currencies', 'titles')
	eq(names(sections[1].items), 'Tonic,Elixir,Helm,Axe,Sword,Plank,Rock', 'main: priority order across both normal bags')
	eq(names(sections[2].items), 'Sunblossom,Peacebloom', "the herb bag's items are not in main")
	eq(#sections[3].items, 0, 'currencies hold no item infos')
	eq(numItems, 9, 'numItems'); eq(numLoading, 0, 'numLoading')

	container.categories.Currencies = nil
	eq(kinds(INV:GetViewSections('bag', 'onebag')), 'main,bag', 'no currencies where the category does not exist')
end)

test('multibag: a section per bag in bag order, titled name (used / total), each in priority order', function()
	world('forever')
	local sections = INV:GetViewSections('bag', 'multibag')
	eq(kinds(sections), 'bag,bag,bag,currencies', 'kinds')
	eq(titles(sections), 'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Currencies', 'titles')
	eq(names(sections[1].items), 'Elixir,Helm,Sword,Plank,Rock', 'the backpack: priority order')
	eq(names(sections[2].items), 'Tonic,Axe', 'bag 1')
	eq(names(sections[3].items), 'Sunblossom,Peacebloom', 'the herb bag')
end)

test('multibag: a bag with no items keeps its titled section', function()
	world('forever')
	W.bag(3, 10, 'Bag')
	local sections = INV:GetViewSections('bag', 'multibag')
	eq(titles(sections), 'Backpack (5 / 20) | Bag (2 / 10) | Herb Bag (2 / 12) | Bag (0 / 10) | Currencies',
		'bag 3 is there with nothing in it (bag 4, with no bag in it, is not)')
	eq(names(section(sections, 'bag3').items), '', 'and holds nothing')
end)

test('rows: a section per category in priority order, Empty Slots then Currencies last', function()
	world('forever')
	INV.config.bag.emptySlots = 'grouped'
	-- Two sets, out of name order.
	W.bags[0].items[3].set = 'Beta'
	W.bags[1].items[1].set = 'Alpha'
	local sections = INV:GetViewSections('bag', 'rows')
	eq(titles(sections),
		'Set: Alpha (1) | Set: Beta (1) | Consumables (2) | Weapons (1) | Trade Goods (3) | Quest (1) | Empty Slots (33) | Currencies',
		'sets by name, the rules in order, Empty Slots, Currencies')
	eq(kinds(sections), 'category,category,category,category,category,category,category,currencies', 'kinds')
	eq(names(section(sections, 'Consumables').items), 'Tonic,Elixir', 'a category is in the item sort')
	eq(names(section(sections, 'Trade Goods').items), 'Sunblossom,Peacebloom,Plank', 'a category spans every bag (item level 19, 18, 15)')
	eq(names(section(sections, 'Empty Slots').items), '<empty x33>', 'empty slots')
end)

test('rows: no empty slots section when there are none to show', function()
	world('forever')
	eq(titles(INV:GetViewSections('bag', 'rows')), 'Consumables (2) | Armor (1) | Weapons (2) | Trade Goods (3) | Quest (1) | Currencies', 'off')
end)

test('empty slots per mode, per view: One bag', function()
	world('forever')
	INV.config.bag.emptySlots = 'off'
	local sections = INV:GetViewSections('bag', 'onebag')
	eq(count_empty(sections[1].items) + count_empty(sections[2].items), 0, 'off: none')

	INV.config.bag.emptySlots = 'grouped'
	sections = INV:GetViewSections('bag', 'onebag')
	eq(names(sections[1].items), 'Tonic,Elixir,Helm,Axe,Sword,Plank,Rock,<empty x23>', 'grouped: one for the normal bags, last')
	eq(names(sections[2].items), 'Sunblossom,Peacebloom,<empty x10>', 'and one for the herb bag, in its section')
	local main = sections[1].items[8]
	eq(main.bagID, 0, 'it points at the first free slot'); eq(main.slotID, 6, 'slot 6 of the backpack')
	eq(sections[2].items[3].bagID, 2, 'the herb bag one is in the herb bag'); eq(sections[2].items[3].slotID, 3, 'its slot 3')

	INV.config.bag.emptySlots = 'all'
	sections = INV:GetViewSections('bag', 'onebag')
	eq(count_empty(sections[1].items), 23, 'all: every free slot of the normal bags')
	eq(count_empty(sections[2].items), 10, 'and of the herb bag')
	eq(names({ unpack(sections[1].items, 1, 7) }), 'Tonic,Elixir,Helm,Axe,Sword,Plank,Rock', 'items first')
	eq(sections[1].items[8].bagID .. ':' .. sections[1].items[8].slotID, '0:6', 'then the free slots in bag order')
	eq(sections[1].items[8 + 15].bagID .. ':' .. sections[1].items[8 + 15].slotID, '1:3', 'backpack first, then bag 1')
	eq(sections[1].items[8].count, nil, 'an all slot has no count')
end)

test('empty slots per mode, per view: Multi bag', function()
	world('forever')
	INV.config.bag.emptySlots = 'off'
	local sections = INV:GetViewSections('bag', 'multibag')
	eq(count_empty(sections[1].items) + count_empty(sections[2].items) + count_empty(sections[3].items), 0, 'off: none')

	INV.config.bag.emptySlots = 'grouped'
	sections = INV:GetViewSections('bag', 'multibag')
	eq(names(sections[1].items), 'Elixir,Helm,Sword,Plank,Rock,<empty x15>', 'grouped: one per bag, with its free count')
	eq(names(sections[2].items), 'Tonic,Axe,<empty x8>', 'bag 1')
	eq(names(sections[3].items), 'Sunblossom,Peacebloom,<empty x10>', 'the herb bag')

	INV.config.bag.emptySlots = 'all'
	sections = INV:GetViewSections('bag', 'multibag')
	eq(count_empty(sections[1].items), 15, 'all: each bag its own')
	eq(count_empty(sections[2].items), 8, 'bag 1')
	eq(count_empty(sections[3].items), 10, 'the herb bag')
	eq(sections[2].items[3].bagID, 1, 'in its own bag')
end)

test('empty slots per mode, per view: Rows, and Compact', function()
	world('retail')
	INV.config.bag.emptySlots = 'grouped'
	local sections = INV:GetViewSections('bag', 'rows')
	local empties = section(sections, 'Empty Slots')
	eq(names(empties.items), '<empty x23>,<empty x34>', 'grouped: one for the bags and one for the reagent bag')
	eq(empties.title, 'Empty Slots (57)', 'titled with the free slots')
	local inventory = INV:GetSortedInventory('bag')
	eq(names(inventory['Empty Slots']), '<empty x23>,<empty x34>', 'Compact: the same two')

	INV.config.bag.emptySlots = 'all'
	empties = section(INV:GetViewSections('bag', 'rows'), 'Empty Slots')
	eq(#empties.items, 57, 'all: every free slot')
	eq(empties.items[23].bagID .. ':' .. empties.items[24].bagID, '1:5', 'the bags first, then the reagent bag')
	eq(#INV:GetSortedInventory('bag')['Empty Slots'], 57, 'Compact: every free slot')

	INV.config.bag.emptySlots = 'off'
	eq(section(INV:GetViewSections('bag', 'rows'), 'Empty Slots'), nil, 'off: no section')
	eq(INV:GetSortedInventory('bag')['Empty Slots'], nil, 'Compact: none')
end)

test('empty slots per mode, per view: the bank window', function()
	world('forever')
	local tab1, tab2 = INV.bagIds.bank[1], INV.bagIds.bank[2]
	W.bag(tab1, 10, 'Tab 1'); W.bag(tab2, 10, 'Tab 2')
	W.put(tab1, 1, W.item(20, 'Gold Bar', 'Trade Goods', 30))
	W.put(tab1, 2, W.item(21, 'Silver Bar', 'Trade Goods', 20))
	W.put(tab1, 3, W.item(22, 'Iron Bar', 'Trade Goods', 10))
	W.container('bank')

	eq(count_empty(INV:GetViewSections('bank', 'rows')[1].items), 0, 'off by default: none')
	INV.config.bank.emptySlots = 'grouped'
	local rows = INV:GetViewSections('bank', 'rows')
	eq(names(section(rows, 'Empty Slots').items), '<empty x17>', 'rows, grouped: one for the whole bank')
	eq(names(INV:GetSortedInventory('bank')['Empty Slots']), '<empty x17>', 'Compact, grouped: the same')
	local multi = INV:GetViewSections('bank', 'multibag')
	eq(titles(multi), 'Tab 1 (3 / 10) | Tab 2 (0 / 10)', 'one section per tab (the bank has no currencies)')
	eq(names(multi[1].items), 'Gold Bar,Silver Bar,Iron Bar,<empty x7>', 'multibag, grouped: one per tab')
	eq(names(multi[2].items), '<empty x10>', 'the second tab')
	local one = INV:GetViewSections('bank', 'onebag')
	eq(titles(one), '-', 'onebag: one main section')
	eq(names(one[1].items), 'Gold Bar,Silver Bar,Iron Bar,<empty x17>', 'grouped: one for the bank')
end)

test('empty slots per mode, per view: the combined bank has one for the bank and one for the warband bank', function()
	world('retail')
	local bankTab, warbandTab = INV.bagIds.bank[1], INV.bagIds.warband[1]
	W.bag(bankTab, 10, 'Bank 1'); W.bag(warbandTab, 20, 'Warband 1')
	W.put(bankTab, 1, W.item(20, 'Gold Bar', 'Trade Goods', 30))
	W.container('combinedbank')
	INV.config.combinedbank.emptySlots = 'grouped'
	eq(names(section(INV:GetViewSections('combinedbank', 'rows'), 'Empty Slots').items), '<empty x9>,<empty x20>', 'rows')
	eq(names(INV:GetSortedInventory('combinedbank')['Empty Slots']), '<empty x9>,<empty x20>', 'Compact')
	eq(titles(INV:GetViewSections('combinedbank', 'multibag')), 'Bank 1 (1 / 10) | Warband 1 (0 / 20)', 'multibag')
	local one = INV:GetViewSections('combinedbank', 'onebag')
	eq(names(one[1].items), 'Gold Bar,<empty x9>,<empty x20>', 'onebag: the bank, then the warband bank')
	eq(one[1].items[2].bagID .. ':' .. one[1].items[3].bagID, bankTab .. ':' .. warbandTab, 'each in its own bank')
	INV.config.combinedbank.emptySlots = 'all'
	one = INV:GetViewSections('combinedbank', 'onebag')
	eq(#one[1].items, 30, 'onebag, all: the item and every free slot')
	eq(one[1].items[10].bagID .. ':' .. one[1].items[11].bagID, bankTab .. ':' .. warbandTab, "the bank's, then the warband bank's")
end)

test('views: stacks merge, and a loading item is counted but not shown', function()
	world('retail')
	INV.config.stackItems = true
	W.put(0, 10, W.item(50, 'Herb', 'Trade Goods', 40, { maxStack = 20, count = 5 }))
	W.put(1, 5, W.item(50, 'Herb', 'Trade Goods', 40, { maxStack = 20, count = 6 }))
	W.put(5, 3, W.item(50, 'Herb', 'Trade Goods', 40, { maxStack = 20, count = 7 }))
	W.put(1, 6, W.item(51, 'Mystery', 'Trade Goods', 1, { loading = true }))
	local rows, numItems, numLoading = INV:GetViewSections('bag', 'rows')
	eq(numItems, 13, 'items read'); eq(numLoading, 1, 'one loading')
	local goods = section(rows, 'Trade Goods').items
	local herbs = {}
	for _, info in ipairs(goods) do if info.name == 'Herb' then herbs[#herbs + 1] = info.count end end
	table.sort(herbs)
	eq(table.concat(herbs, ','), '7,11', 'rows: the bags merge, the reagent bag stays apart')
	local one = INV:GetViewSections('bag', 'onebag')
	eq(names(one[1].items):find('Mystery'), nil, 'a loading item is not in a section')
	herbs = {}
	for _, info in ipairs(one[1].items) do if info.name == 'Herb' then herbs[#herbs + 1] = info.count end end
	eq(table.concat(herbs, ','), '11', 'onebag: main merges across normal bags')
	local multi = INV:GetViewSections('bag', 'multibag')
	eq(names(multi[2].items), 'Tonic,Axe,Herb', 'multibag: stacks do not merge across bags, so bag 1 keeps its own')
	eq(multi[2].items[3].count, 6, 'its own count')
end)

test('Compact: GetSortedInventory gives what it gave, for the bag window', function()
	world('forever')
	local inventory, numItems, numLoading = INV:GetSortedInventory('bag')
	eq(numItems, 9, 'numItems'); eq(numLoading, 0, 'numLoading')
	eq(names(inventory.Consumables), 'Tonic,Elixir', 'a category sorted by the item sort')
	eq(names(inventory.Weapons), 'Axe,Sword', 'weapons')
	eq(names(inventory['Trade Goods']), 'Sunblossom,Peacebloom,Plank', 'a category spans bags')
	eq(inventory['Empty Slots'], nil, 'no empty slots by default')
	INV.config.bag.emptySlots = 'grouped'
	eq(names(INV:GetSortedInventory('bag')['Empty Slots']), '<empty x33>', 'grouped: one per kind (the herb bag is a normal bag)')
	INV.config.bag.emptySlots = 'all'
	eq(#INV:GetSortedInventory('bag')['Empty Slots'], 33, 'all: every free slot')
	stub.in_combat = true
	W.container('bag').categories['Empty Slots'] = { slots = { 1, 2, 3 } }
	eq(#INV:GetSortedInventory('bag')['Empty Slots'], 3, 'all, in combat: no more than the buttons made')
	stub.in_combat = false
end)

test('defaults: every window is compact with empty slots off', function()
	world('forever')
	for _, id in ipairs({ 'bag', 'bank', 'warband', 'combinedbank' }) do
		eq(INV.config[id].view, 'compact', id .. ' view')
		eq(INV.config[id].emptySlots, 'off', id .. ' empty slots')
	end
end)
