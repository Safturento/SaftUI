-- The item facts the category blocks read (SaftUI-Bags/itemclasses.lua, the
-- scanner in tooltipscanner.lua and INV:GetInventoryItemInfo in category.lua):
-- class and subclass names resolved to this client's ids, the ids and the
-- stripped and lowercased text on an item's info, a keystone's and a caged
-- pet's classes, and items that wait for their tooltip (held for a few reads,
-- then filed without text, and refiled once it arrives). bags/bag_world.lua
-- loads the real files over a stubbed bag world.
local W = load_test_file('bags/bag_world.lua')

local INV

local function world(client)
	INV = W.fresh(client)
	W.bag(0, 20, 'Backpack')
	W.container('bag')
	return INV
end

-- The ids a ClassIDs or SubclassIDs result holds, as text, in order.
local function ids(set)
	local out = {}
	for id in pairs(set) do out[#out + 1] = id end
	table.sort(out)
	return table.concat(out, ',')
end

local function sub_ids(by_class)
	local classes = {}
	for classID in pairs(by_class) do classes[#classes + 1] = classID end
	table.sort(classes)
	local out = {}
	for _, classID in ipairs(classes) do
		out[#out + 1] = classID .. '=' .. table.concat(by_class[classID], '/')
	end
	return table.concat(out, ' ')
end

local function read(id)
	return INV:ReadBags(id or 'bag', function() return 'bag' end)
end

test("item classes: names resolve to this client's IDs", function()
	world('forever')
	local IC = INV.ItemClasses
	eq(ids(IC.ClassIDs('Trade Goods')), '7', 'Forever: Trade Goods')
	eq(ids(IC.ClassIDs('Tradeskill')), '', 'Forever: no Tradeskill')
	eq(ids(IC.ClassIDs('Gem')), '', 'Forever: no Gem')
	eq(sub_ids(IC.SubclassIDs('Flasks & Phials')), '', 'Forever: no Flasks & Phials')
	eq(sub_ids(IC.SubclassIDs('Companion Pets')), '', 'Forever: no Companion Pets')
	eq(sub_ids(IC.SubclassIDs('Devices')), '0=14', 'Forever: Devices is consumable 14 only (the obsolete one has its suffix)')
	eq(IC.ClassName(7), 'Trade Goods', 'ClassName')
	eq(IC.ClassName(17), nil, 'Forever has no class 17')
	eq(IC.SubclassName(15, 5), 'Mount', 'SubclassName')
	eq(IC.SubclassName(15, 99), nil, 'an unknown subclass')

	world('retail')
	IC = INV.ItemClasses
	eq(ids(IC.ClassIDs('Tradeskill')), '7', 'retail: Tradeskill')
	eq(ids(IC.ClassIDs('Gem')), '3', 'retail: Gem')
	eq(ids(IC.ClassIDs('Housing')), '20', 'retail: Housing')
	eq(sub_ids(IC.SubclassIDs('Flasks & Phials')), '0=3', 'retail: Flasks & Phials')
	eq(sub_ids(IC.SubclassIDs('Item Enhancement')), '', 'retail: Item Enhancement is a class, and its subclass has a suffix')
	eq(sub_ids(IC.SubclassIDs('Devices')), '', 'retail: no Devices')
end)

test('item classes: lists by id, and gear is Armor and Weapon', function()
	world('forever')
	local IC = INV.ItemClasses
	local classes = IC.Classes()
	for i = 2, #classes do
		check(classes[i - 1].id < classes[i].id, 'Classes is by id')
	end
	eq(classes[1].id, 0, 'first class'); eq(classes[1].name, 'Consumable', 'its name')
	local subs = IC.Subclasses(15)
	for i = 2, #subs do check(subs[i - 1].id < subs[i].id, 'Subclasses is by id') end
	eq(#IC.Subclasses(99), 0, 'an unknown class has none')
	local armor, weapon = ids(IC.ClassIDs('Armor')), ids(IC.ClassIDs('Weapon'))
	check(IC.IsGear({ classID = tonumber(armor) }), 'armor is gear')
	check(IC.IsGear({ classID = tonumber(weapon) }), 'a weapon is gear')
	check(not IC.IsGear({ classID = 7 }), 'trade goods are not')
	check(not IC.IsGear({}), 'an item with no class is not')
end)

test('GetInventoryItemInfo gives the IDs and the text the blocks read', function()
	world('retail')
	W.put(0, 1, W.item(1, 'Flawless Battle-Stone', 'Battle Pets', 1, {
		classID = 17, subclassID = 0, equipLoc = 'INVTYPE_TRINKET', isCraftingReagent = true,
		tooltip = { 'Flawless Battle-Stone', { 'Binds to account', 'Use: 100%' } },
	}))
	local info = INV:GetInventoryItemInfo(0, 1, 'bag')
	eq(info.nameStripped, 'flawless battlestone', 'the name, stripped')
	eq(info.nameLower, 'flawless battle-stone', 'the name, lowercased')
	eq(info.tooltipText, ' Flawless BattleStone Binds to account Use: 100 ',
		'tooltipText is as today')
	eq(info.tooltipLower, ' flawless battle-stone binds to account use: 100%', 'the raw text, lowercased')
	eq(info.tooltipStripped, ' flawless battlestone binds to account use: 100 ', 'the text, stripped and lowercased')
	eq(info.classID, 17, 'classID'); eq(info.subclassID, 0, 'subclassID')
	eq(info.equipLoc, 'INVTYPE_TRINKET', 'equipLoc is the raw token')
	eq(info.isCraftingReagent, true, 'isCraftingReagent')
	eq(info.bindType, 0, 'bindType')
end)

test('a keystone and a caged pet get the Key and Battle Pet classes', function()
	world('retail')
	W.put(0, 1, W.item(1, 'Keystone: Darkflame Cleft', 'Key', 1, {
		link = '|Hkeystone:180653:504:11:162:10:9:0:0|h[Keystone: Darkflame Cleft (11)]|h', quality = 4 }))
	W.put(0, 2, W.item(2, 'Mechanical Squirrel', 'Battle Pet', 1, {
		link = '|Hbattlepet:339:25:3:1400:276:276|h[Mechanical Squirrel]|h', quality = 3 }))
	local key = INV:GetInventoryItemInfo(0, 1, 'bag')
	eq(key.classID, 13, 'keystone: Key')
	local pet = INV:GetInventoryItemInfo(0, 2, 'bag')
	eq(pet.classID, 17, 'caged pet: Battle Pet')
	eq(pet.nameLower, 'mechanical squirrel', 'the pet is named')
end)

test('an item whose tooltip has not loaded is loading, and is filed once it loads', function()
	world('forever')
	local item = W.item(1, 'Helm', 'Armor', 10, { tooltip = { 'Binds when picked up' }, tooltipLoading = true })
	W.put(0, 1, item)
	local info = INV:GetInventoryItemInfo(0, 1, 'bag')
	eq(info.loading, true, 'loading'); eq(info.tooltip, true, 'because of its tooltip')
	local bags, numItems, numLoading, categoryOf = read()
	eq(numItems, 1, 'one item'); eq(numLoading, 1, 'still loading')
	eq(#bags[1].items, 0, 'not filed'); eq(next(categoryOf), nil, 'with no category')
	item.tooltipLoading = nil
	bags, numItems, numLoading, categoryOf = read()
	eq(numLoading, 0, 'loaded')
	eq(#bags[1].items, 1, 'filed')
	eq(categoryOf[bags[1].items[1]], 'Armor', 'under its category')
end)

test('a tooltip that never loads holds its item for 10 reads, then it is filed without text, and moves when the text arrives', function()
	world('forever')
	local item = W.item(1, 'Old Bobber', 'Miscellaneous', 10, { quality = 0, tooltip = { 'Fishing' }, tooltipLoading = true })
	W.put(0, 1, item)
	eq(INV.TOOLTIP_TRIES, 10, 'the number of reads held')
	for n = 1, INV.TOOLTIP_TRIES do
		local _, _, numLoading = read()
		eq(numLoading, 1, 'read ' .. n .. ' is held')
	end
	local bags, _, numLoading, categoryOf = read()
	eq(numLoading, 0, 'the next read files it')
	local info = bags[1].items[1]
	eq(info.tooltipText, '', 'with no text')
	eq(categoryOf[info], 'Grays/Auto Vendor', 'a gray, by what its info says (no Fishing text to keep it from selling)')
	-- Not cached: the text arriving later is read.
	item.tooltipLoading = nil
	bags, _, numLoading, categoryOf = read()
	eq(numLoading, 0, 'still not loading')
	eq(bags[1].items[1].tooltipLower, ' fishing', 'the text is there now')
	check(categoryOf[bags[1].items[1]] ~= 'Grays/Auto Vendor', 'and the item moves out of Grays: its text says Fishing')
end)

test('with no C_TooltipInfo, items are filed with no tooltip text, never loading', function()
	world('forever')
	_G.C_TooltipInfo = nil
	W.put(0, 1, W.item(1, 'Helm', 'Armor', 10, { tooltip = { 'Fishing' } }))
	local text, raw, ready = INV:ScanBagItem(0, 1)
	eq(text, '', 'no text'); eq(raw, '', 'no raw text'); eq(ready, true, 'ready')
	local bags, _, numLoading = read()
	eq(numLoading, 0, 'never loading')
	eq(#bags[1].items, 1, 'filed')
	eq(bags[1].items[1].tooltipText, '', 'with no text')
	eq(bags[1].items[1].tooltipStripped, '', 'stripped too')
end)

test('ScanBagItem: both texts per link, cached, and an empty slot is ready with nothing', function()
	world('forever')
	W.put(0, 1, W.item(1, 'Helm', 'Armor', 10, { tooltip = { 'Fire-Resist 5%' } }))
	local text, raw, ready = INV:ScanBagItem(0, 1)
	eq(raw, ' Fire-Resist 5%', 'raw as the client gave it'); eq(text, ' FireResist 5 ', 'through unmagic'); eq(ready, true, 'ready')
	W.bags[0].items[1].tooltip = { 'changed' }
	eq(INV:ScanBagItem(0, 1), ' FireResist 5 ', 'cached by link')
	local t, r, ok = INV:ScanBagItem(0, 2)
	eq(t, ''); eq(r, ''); eq(ok, true, 'no link: ready')
end)

test('a waiting tooltip queues one retry', function()
	world('forever')
	W.put(0, 1, W.item(1, 'Helm', 'Armor', 10, { tooltipLoading = true }))
	W.put(0, 2, W.item(2, 'Cap', 'Armor', 10, { tooltipLoading = true }))
	INV.NEED_UPDATE = nil
	read(); read()
	eq(#stub.timers, 1, 'two reads, one timer')
	eq(stub.run_timers(), 0, 'not due yet')
	eq(INV.NEED_UPDATE, nil, 'no update yet')
	stub.time = stub.time + INV.TOOLTIP_RETRY
	eq(stub.run_timers(), 1, 'the timer runs')
	eq(INV.NEED_UPDATE, true, 'it queued an update')
	eq(INV.UPDATE_LAYOUT, true, 'with the layout')
	read()
	eq(#stub.timers, 1, 'a later wait queues the next retry')
end)
