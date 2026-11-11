-- Editing the bag categories (SaftUI-Bags/categories.lua's write side): add,
-- rename, move, turn off, delete, restore and reset the list's categories, and
-- pin items to them, with every write normalized against the shipped default
-- (an edit holds only what differs), copy on write, and the bags reading it on
-- the next update. Selling stays with Grays/Auto Vendor, whatever it is called,
-- wherever it stands, and a pin never gets an item past what auto vendor
-- refuses. Combat: a write makes no frame or slot in combat.
-- bags/bag_world.lua's bags under bags/container_helpers.lua's views world.
local H = load_test_file('bags/container_helpers.lua')

local INV, W

local function same(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for k, v in pairs(a) do if not same(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

-- eq, with tables compared by what they hold.
local global_eq = eq
local function eq(actual, expected, message)
	if type(actual) == 'table' and type(expected) == 'table' then
		return check(same(actual, expected), message .. ': tables differ')
	end
	return global_eq(actual, expected, message)
end

local SELL = 'Grays/Auto Vendor'

-- The backpack: a tonic, an axe, a plank, a rock, a gray cloth (quality 0)
-- and a common bit (quality 1, a Miscellaneous class). Every item sells for
-- 10 a unit. view is the bag window's view.
local function world(view, setup)
	INV, W = H.views_world('forever')
	load_saftui('SaftUI-Bags/autovendor.lua')
	W.bag(0, 30, 'Backpack')
	W.put(0, 1, W.item(101, 'Tonic', 'Consumable', 30))
	W.put(0, 2, W.item(201, 'Axe', 'Weapon', 70))
	W.put(0, 3, W.item(301, 'Plank', 'Trade Goods', 15))
	W.put(0, 4, W.item(150, 'Rock', 'Quest', 5))
	W.put(0, 5, W.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0 }))
	W.put(0, 6, W.item(503, 'Common Bit', 'Miscellaneous', 1, { quality = 1 }))
	INV.config.stackItems = false
	INV.config.bag.view = view or 'compact'
	INV.config.bag.emptySlots = 'off'
	if setup then setup() end
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

local function update()
	INV:UpdateContainer('bag', true)
end

-- The names of the items a category frame shows, sorted.
local function shown(container, key)
	local frame = container.categories[key]
	local out = {}
	if frame and frame:IsShown() then
		for _, slot in ipairs(frame.slots) do
			if slot:IsShown() and slot.info and not slot.info.empty then out[#out + 1] = slot.info.name end
		end
	end
	table.sort(out)
	return table.concat(out, ',')
end

local function slot_of(container, name)
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			if slot:IsShown() and slot.info and slot.info.name == name then return slot end
		end
	end
end

local function category_of(name)
	local bags = INV:ReadBags('bag', function() return 'bag' end)
	for _, bag in ipairs(bags) do
		for _, item in ipairs(bag.items) do
			if item.name == name then return item.category end
		end
	end
end

local function ids()
	local out = {}
	for i, entry in ipairs(INV:GetCategoryList()) do out[i] = entry.id end
	return out
end

local function place_of(id) return INV:GetCategoryList().byId[id].place end

local function sold()
	local items = INV:GetVendorItems()
	local out = {}
	for _, info in ipairs(items) do out[#out + 1] = info.name end
	table.sort(out)
	return table.concat(out, ',')
end

local function count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

local function equal_lists(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do if a[i] ~= b[i] then return false end end
	return true
end

------------------------------------------------------------------ adding

test('AddUserCategory: "New category" just above Miscellaneous, catching nothing, with a frame in every made window', function()
	local c = world('compact')
	local bank = H.window('bank')
	local before = #INV:GetCategoryList()
	local id = INV:AddUserCategory()
	local list = INV:GetCategoryList()
	eq(id, 'custom:1', 'the first id')
	eq(#list, before + 1, 'one more in the list')
	eq(list[#list].id, 'Miscellaneous', 'Miscellaneous still last')
	eq(list[#list - 1].id, id, 'just above Miscellaneous')
	local entry = list.byId[id]
	eq(entry.name, 'New category', 'named New category')
	eq(entry.enabled, true, 'on')
	eq(next(entry.hide), nil, 'shown in every window')
	eq(entry.rule, { op = 'and', items = {} }, 'an empty rule')
	eq(entry.default, false, 'yours')
	check(c.categories[id], 'a frame in the bag window')
	check(bank.categories[id], 'and in the bank window')
	update()
	eq(shown(c, id), '', 'it catches nothing')
	eq(category_of('Common Bit'), 'Miscellaneous', 'its items still fall to Miscellaneous')
	eq(INV:AddUserCategory(), 'custom:2', 'the next id')
	eq(INV:CategoryName('custom:2'), 'New category 2', 'a taken name gets 2')
	INV:AddUserCategory()
	eq(INV:CategoryName('custom:3'), 'New category 3', 'then 3')
	eq(INV:GetCategoryList()[#INV:GetCategoryList() - 1].id, 'custom:3', 'each above Miscellaneous')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ renaming

test('RenameCategory keeps the key, frame, place, held layout and pins; the header and the Rows title show the new name', function()
	local c = world('compact')
	INV:PinItem(101, 'Weapons')
	update()
	local frame = c.categories.Weapons
	local place = place_of('Weapons')
	eq(INV:RenameCategory('Weapons', '  Blades '), true, 'accepted, trimmed')
	eq(INV:CategoryName('Weapons'), 'Blades', 'the name is trimmed')
	eq(INV:GetCategoryList().byId.Weapons.edited, true, 'an edited default')
	eq(INV:CategoryStore().edits.Weapons, { name = 'Blades' }, 'only the name is stored')
	eq(place_of('Weapons'), place, 'the same place')
	eq(INV:GetPin(101), 'Weapons', 'the pin is kept')
	update()
	check(c.categories.Weapons == frame, 'the same frame, by the same key')
	eq(shown(c, 'Weapons'), 'Axe,Tonic', 'the same items')
	check(frame.header.text:GetText():find('^Blades %(2%)'), 'the header shows the new name: ' .. tostring(frame.header.text:GetText()))
	-- Rows
	INV.config.bag.view = 'rows'
	INV:ApplyView('bag')
	local sections = INV:GetViewSections('bag', 'rows')
	local titles = {}
	for _, section in ipairs(sections) do titles[section.key] = section.title end
	eq(titles.Weapons, 'Blades (2)', 'the Rows title shows the new name')
	check(c.categories.Weapons.header.text:GetText():find('^Blades'), "and the frame's header")
	-- a user category
	local id = INV:AddUserCategory()
	eq(INV:RenameCategory(id, 'Mine'), true, 'a category of yours')
	eq(INV:CategoryName(id), 'Mine', 'renamed')
	eq(INV:RenameCategory('Weapons', 'Weapons'), true, 'the shipped name again')
	eq(INV:CategoryStore().edits.Weapons, nil, 'clears the edit')
	eq(INV:GetCategoryList().byId.Weapons.edited, false, 'no longer edited')
	eq(#take_errors(), 0, 'no errors')
end)

test('an empty name is refused', function()
	world('compact')
	eq(INV:RenameCategory('Weapons', ''), false, 'empty')
	eq(INV:RenameCategory('Weapons', '   '), false, 'blank')
	eq(INV:RenameCategory('Weapons', nil), false, 'nil')
	eq(INV:RenameCategory('Weapons', 5), false, 'not a string')
	eq(INV:RenameCategory('Nothing', 'x'), false, 'an id the list has not')
	eq(INV:CategoryName('Weapons'), 'Weapons', 'unchanged')
	eq(INV:CategoryStore().edits.Weapons, nil, 'nothing stored')
end)

------------------------------------------------------------------ on and off

test('SetCategoryEnabled: off, its items go to the next category; Miscellaneous cannot be turned off', function()
	local c = world('compact')
	update()
	eq(shown(c, 'Weapons'), 'Axe', 'Axe in Weapons')
	eq(INV:SetCategoryEnabled('Weapons', false), true, 'off')
	eq(INV:CategoryStore().edits.Weapons, { enabled = false }, 'stored as an edit')
	update()
	eq(shown(c, 'Weapons'), '', 'Weapons is empty')
	eq(category_of('Axe'), 'Miscellaneous', 'the axe goes to the next category that catches it')
	eq(INV:SetCategoryEnabled('Weapons', true), true, 'on again')
	eq(INV:CategoryStore().edits.Weapons, nil, 'the default value clears the edit')
	update()
	eq(shown(c, 'Weapons'), 'Axe', 'back')
	eq(INV:SetCategoryEnabled('Miscellaneous', false), false, 'Miscellaneous cannot be turned off')
	eq(INV:GetCategoryList().byId.Miscellaneous.enabled, true, 'still on')
	eq(INV:CategoryStore().edits.Miscellaneous, nil, 'nothing stored')
	local id = INV:AddUserCategory()
	eq(INV:SetCategoryEnabled(id, false), true, 'one of yours')
	eq(INV:GetCategoryList().byId[id].enabled, false, 'off')
	eq(INV:CategoryStore().custom[id].enabled, false, 'stored in custom')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the rule

test('SetCategoryRule applies on the next update; an edited default is edited, and setting the shipped rule back clears the edit', function()
	local c = world('compact')
	update()
	eq(shown(c, 'Consumables'), 'Tonic', 'Tonic in Consumables')
	local shipped = INV:GetDefaultCategory('Consumables').rule
	local rule = { op = 'or', items = { { block = 'class', class = 0 }, { block = 'name', text = 'axe' } } }
	eq(INV:SetCategoryRule('Consumables', rule), true, 'set')
	local stored = INV:CategoryStore().edits['Consumables'].rule
	eq(stored, rule, 'stored as given')
	check(stored ~= rule, 'a copy')
	check(stored.items ~= rule.items and stored.items[1] ~= rule.items[1], 'a deep copy')
	rule.items[2].text = 'changed afterwards'
	eq(INV:GetCategoryList().byId.Consumables.rule.items[2].text, 'axe', 'later changes to the argument do not reach the store')
	eq(INV:GetCategoryList().byId.Consumables.edited, true, 'edited')
	update()
	eq(shown(c, 'Consumables'), 'Axe,Tonic', 'the rule applies on the next update')
	-- the shipped default is never touched
	check(INV:GetDefaultCategory('Consumables').rule == shipped, 'the shipped rule is untouched')
	eq(INV:GetDefaultCategory('Consumables').rule.items[1].block, 'class', 'still its blocks')
	-- the shipped rule back
	local copy = INV.CategoryDefaults.Resolve(shipped)
	eq(INV:SetCategoryRule('Consumables', copy), true, 'the shipped rule back')
	eq(INV:CategoryStore().edits.Consumables, nil, 'clears the edit')
	eq(INV:GetCategoryList().byId.Consumables.edited, false, 'not edited')
	update()
	eq(shown(c, 'Consumables'), 'Tonic', 'as shipped')
	-- refused
	eq(INV:SetCategoryRule('Equipment sets', rule), false, 'refused for the sets entry')
	eq(INV:SetCategoryRule('Miscellaneous', rule), false, 'and Miscellaneous')
	eq(INV:SetCategoryRule('Nothing', rule), false, 'and an id the list has not')
	eq(INV:SetCategoryRule('Weapons', 'x'), false, 'and a rule that is not a table')
	eq(INV:CategoryStore().edits['Equipment sets'], nil, 'nothing stored')
	-- one of yours
	local id = INV:AddUserCategory()
	eq(INV:SetCategoryRule(id, { op = 'or', items = { { block = 'name', text = 'common' } } }), true, 'one of yours')
	update()
	eq(shown(c, id), 'Common Bit', 'catches the common bit, which would be Miscellaneous')
	eq(#take_errors(), 0, 'no errors')
end)

test('a setter never changes the shipped default or a table a list entry holds', function()
	world('compact')
	local def = INV:GetDefaultCategory('Weapons')
	local shippedRule = def.rule
	local snapshot = INV.CategoryDefaults.Resolve(shippedRule)
	local held = INV:GetCategoryList().byId.Weapons
	INV:SetCategoryRule('Weapons', { op = 'or', items = { { block = 'name', text = 'x' } } })
	INV:RenameCategory('Weapons', 'Blades')
	INV:SetCategoryEnabled('Weapons', false)
	eq(def.rule, snapshot, 'the default entry is as shipped')
	check(INV:GetDefaultCategory('Weapons').rule == shippedRule, 'the same shipped table')
	eq(held.rule, snapshot, 'an entry read before holds the rule it had')
	eq(held.name, 'Weapons', 'and its name')
	INV:ResetCategory('Weapons')
	eq(def.rule, snapshot, 'still as shipped after a reset')
	-- the store's own tables: an old entry's hide and rule
	local store = INV:CategoryStore()
	store.edits.Armor = { hide = { bag = true } }
	INV:CategoriesChanged()
	local armor = INV:GetCategoryList().byId.Armor
	local hide = armor.hide
	INV:SetCategoryRule('Armor', { op = 'or', items = { { block = 'name', text = 'y' } } })
	INV:RenameCategory('Armor', 'Mail')
	eq(hide, { bag = true }, 'the hide table an entry holds is not changed in place')
	eq(store.edits.Armor.hide, { bag = true }, 'and the edit keeps its Show in')
end)

------------------------------------------------------------------ moving

local function section_keys(view)
	local keys = {}
	for _, section in ipairs(INV:GetViewSections('bag', view)) do
		if section.kind == 'category' then keys[#keys + 1] = section.key end
	end
	return table.concat(keys, ',')
end

local function item_names(section)
	local out = {}
	for _, info in ipairs(section.items) do out[#out + 1] = info.name end
	return table.concat(out, ',')
end

test('MoveCategory reorders Rows, One bag and Multi bag; Miscellaneous stays last; Compact still packs by height', function()
	local c = world('rows')
	local rows = section_keys('rows')
	eq(rows, 'Grays/Auto Vendor,Consumables,Weapons,Trade Goods,Quest,Miscellaneous', 'Rows in list order')
	local list = INV:GetCategoryList()
	eq(INV:MoveCategory('Trade Goods', place_of('Consumables')), true, 'Trade Goods to the top of those')
	eq(section_keys('rows'), 'Grays/Auto Vendor,Trade Goods,Consumables,Weapons,Quest,Miscellaneous', 'Rows follow')
	eq(INV:CategoryStore().order[place_of('Trade Goods')], 'Trade Goods', 'the whole order is written')
	eq(#INV:CategoryStore().order, #INV:GetCategoryList(), 'all of it')
	-- One bag and Multi bag sort items by category order
	local function main_items(view)
		for _, section in ipairs(INV:GetViewSections('bag', view)) do
			if section.kind ~= 'currencies' then return item_names(section) end
		end
	end
	eq(main_items('onebag'), 'Gray Cloth,Plank,Tonic,Axe,Rock,Common Bit', 'One bag: Plank before Tonic')
	eq(main_items('multibag'), 'Gray Cloth,Plank,Tonic,Axe,Rock,Common Bit', 'Multi bag: likewise')
	INV:MoveCategory('Trade Goods', place_of('Quest'))
	eq(main_items('onebag'), 'Gray Cloth,Tonic,Axe,Rock,Plank,Common Bit', 'One bag follows the next move')
	-- Miscellaneous
	local n = #INV:GetCategoryList()
	eq(INV:MoveCategory('Miscellaneous', 1), false, 'Miscellaneous cannot move')
	eq(INV:MoveCategory('Weapons', n), true, 'nothing can go below Miscellaneous: clamped to just above it')
	local last = INV:GetCategoryList()
	eq(last[n].id, 'Miscellaneous', 'Miscellaneous is last')
	eq(last[n - 1].id, 'Weapons', 'Weapons is just above it')
	eq(INV:MoveCategory('Weapons', 0), true, 'a place below 1 is clamped')
	eq(INV:GetCategoryList()[1].id, 'Weapons', 'to the top')
	eq(INV:MoveCategory('Nothing', 2), false, 'an id the list has not')
	eq(INV:MoveCategory('Weapons', 'x'), false, 'a place that is not a number')

	-- Compact packs by height: the same columns before and after a move
	local ok = world('compact', function()
		for i = 7, 13 do W.put(0, i, W.item(100 + i, 'Tonic ' .. i, 'Consumable', 30)) end
		W.put(0, 14, W.item(204, 'Mace', 'Weapon', 60))
		W.put(0, 15, W.item(205, 'Spear', 'Weapon', 61))
	end)
	update()
	local function columns()
		local out = {}
		for index, column in ipairs(ok.columns) do
			for _, category in ipairs(column.categories) do out[category.name] = index end
		end
		return out
	end
	local before = columns()
	check(count(before) >= 3, 'the layout has columns of categories')
	INV:MoveCategory('Quest', place_of('Consumables'))
	INV:MoveCategory('Trade Goods', place_of('Consumables'))
	update()
	eq(columns(), before, 'Compact: the same columns after the move')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ removing and restoring

test('RemoveCategory: yours goes with its pins; a default goes to deleted with its pins; Miscellaneous, Grays/Auto Vendor and Equipment sets cannot be removed', function()
	local c = world('compact')
	local id = INV:AddUserCategory()
	INV:SetCategoryRule(id, { op = 'or', items = { { block = 'name', text = 'common' } } })
	INV:PinItem(101, id)
	INV:PinItem(201, 'Weapons')
	INV:PinItem(301, 'Quest')
	update()
	eq(shown(c, id), 'Common Bit,Tonic', 'the category holds its items')
	eq(INV:RemoveCategory(id), true, 'yours is removed')
	check(INV:GetCategoryList().byId[id] == nil, 'gone from the list')
	eq(INV:CategoryStore().custom[id], nil, 'and the store')
	eq(INV:GetPin(101), nil, 'its pin is gone')
	eq(INV:GetPin(201), 'Weapons', 'other pins stay')
	update()
	eq(shown(c, id), '', 'nothing left in its frame')
	eq(category_of('Tonic'), 'Consumables', 'the tonic follows the rules again')

	INV:RenameCategory('Weapons', 'Blades')
	local count_before = #INV:GetCategoryList()
	eq(INV:RemoveCategory('Weapons'), true, 'a default is removed')
	eq(#INV:GetCategoryList(), count_before - 1, 'one fewer')
	eq(INV:CategoryStore().deleted.Weapons, true, 'to deleted')
	eq(INV:CategoryStore().edits.Weapons, nil, 'its edits cleared')
	eq(INV:GetPin(201), nil, 'its pins removed')
	eq(INV:GetPin(301), 'Quest', 'others stay')
	update()
	eq(category_of('Axe'), 'Miscellaneous', 'the axe falls through')
	local deleted = INV:GetDeletedDefaults()
	eq(#deleted, 1, 'one deleted default')
	eq(deleted[1].id, 'Weapons', 'Weapons')
	eq(deleted[1].name, 'Weapons', 'as shipped')

	for _, key in ipairs({ 'Miscellaneous', SELL, 'Equipment sets' }) do
		eq(INV:RemoveCategory(key), false, key .. ' cannot be removed')
		check(INV:GetCategoryList().byId[key], key .. ' is still in the list')
	end
	eq(INV:RemoveCategory('Nothing'), false, 'an id the list has not')
	eq(INV:RemoveCategory('Weapons'), false, 'a deleted one again')
	eq(#take_errors(), 0, 'no errors')
end)

test('RestoreCategory: a deleted default back at its default place, as shipped', function()
	local c = world('compact')
	local place = place_of('Weapons')
	INV:SetCategoryRule('Weapons', { op = 'or', items = { { block = 'name', text = 'x' } } })
	INV:RenameCategory('Weapons', 'Blades')
	INV:MoveCategory('Weapons', 3)
	INV:RemoveCategory('Weapons')
	eq(#INV:GetDeletedDefaults(), 1, 'deleted')
	eq(INV:RestoreCategory('Weapons'), true, 'restored')
	eq(#INV:GetDeletedDefaults(), 0, 'no longer deleted')
	local entry = INV:GetCategoryList().byId.Weapons
	eq(entry.name, 'Weapons', 'with its shipped name')
	eq(entry.edited, false, 'as shipped')
	eq(entry.enabled, true, 'on')
	eq(entry.place, place, 'at its default place, not where it was moved to')
	update()
	eq(shown(c, 'Weapons'), 'Axe', 'it catches again')
	eq(INV:RestoreCategory('Weapons'), false, 'one that is not deleted')
	eq(INV:RestoreCategory('Nothing'), false, 'or unknown')
	-- the default order, in the list of deleted
	INV:RemoveCategory('Quest')
	INV:RemoveCategory('Armor')
	local out = {}
	for _, e in ipairs(INV:GetDeletedDefaults()) do out[#out + 1] = e.id end
	eq(out, { 'Armor', 'Quest' }, 'GetDeletedDefaults is in the default order')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ resetting

test('ResetCategory and ResetAllCategories: as shipped; your categories and their pins gone; other pins and Protected kept', function()
	local c = world('compact')
	local shippedOrder = ids()
	INV:RenameCategory('Weapons', 'Blades')
	INV:SetCategoryEnabled('Quest', false)
	INV:SetCategoryRule('Armor', { op = 'or', items = { { block = 'name', text = 'x' } } })
	INV:CategoryStore().edits.Quest.hide = { bag = true }
	INV:CategoriesChanged()
	INV:MoveCategory('Trade Goods', 2)
	INV:RemoveCategory('Keys')
	local mine = INV:AddUserCategory()
	INV:PinItem(101, mine)
	INV:PinItem(201, 'Weapons')
	INV:SetProtected(301, true)
	INV.config.protectFilter[777] = true

	eq(INV:ResetCategory('Weapons'), true, 'one default reset')
	eq(INV:CategoryName('Weapons'), 'Weapons', 'its name is as shipped')
	eq(INV:CategoryStore().edits.Weapons, nil, 'its edit is gone')
	eq(INV:ResetCategory('Quest'), true, 'name, on or off and Show in')
	eq(INV:CategoryStore().edits.Quest, nil, 'all cleared')
	eq(INV:GetCategoryList().byId.Quest.hide, {}, 'Show in is as shipped')
	eq(INV:ResetCategory('Armor'), true, 'and the rule')
	eq(INV:GetCategoryList().byId.Armor.edited, false, 'as shipped')
	eq(INV:GetPin(201), 'Weapons', 'a reset keeps its pinned items')
	eq(INV:ResetCategory(mine), false, 'one of yours has no default')
	eq(INV:ResetCategory('Nothing'), false, 'an id the list has not')
	check(INV:GetCategoryList().byId[mine], 'one of yours is still there')

	INV:RenameCategory('Weapons', 'Blades')
	INV:ResetAllCategories()
	local store = INV:CategoryStore()
	eq(store.order, nil, 'order cleared')
	eq(store.edits, {}, 'edits cleared')
	eq(store.custom, {}, 'custom cleared')
	eq(store.deleted, {}, 'deleted cleared')
	eq(ids(), shippedOrder, 'the list is as shipped')
	eq(INV:GetPin(101), nil, 'the pin to a category of yours is gone')
	eq(INV:GetPin(201), 'Weapons', 'a pin to a default stays')
	eq(INV:IsProtected(301), true, 'Protected stays')
	eq(INV:IsProtected(777), true, 'all of it')
	eq(#take_errors(), 0, 'no errors')
end)

test('a default restored or reset when another category has its name gets a number after it, so no two share a name', function()
	world('compact')
	local function names_unique()
		local seen = {}
		for _, entry in ipairs(INV:GetCategoryList()) do
			local name = entry.name:lower()
			if seen[name] then return false end
			seen[name] = true
		end
		return true
	end
	-- Delete Toys, call Pets "toys", bring Toys back.
	INV:RemoveCategory('Toys')
	INV:RenameCategory('Pets', 'toys')
	eq(INV:RestoreCategory('Toys'), true, 'restored')
	local list = INV:GetCategoryList()
	eq(list.byId.Toys.name, 'Toys (2)', 'its name is taken, in any case: numbered')
	eq(list.byId.Toys.edited, true, 'an edit, as it is not the shipped name')
	eq(list.byId.Pets.name, 'toys', 'the other keeps its name')
	check(names_unique(), 'no two share a name')

	-- Reset beside one of yours with its name, and a numbered one too.
	local mine, other = INV:AddUserCategory(), INV:AddUserCategory()
	INV:RenameCategory('Armor', 'Plate')
	INV:RenameCategory(mine, 'Armor')
	INV:RenameCategory(other, 'ARMOR (2)')
	INV:PinItem(201, 'Armor')
	eq(INV:ResetCategory('Armor'), true, 'reset')
	eq(INV:CategoryName('Armor'), 'Armor (3)', 'numbered past the names taken')
	eq(INV:CategoryStore().edits.Armor, { name = 'Armor (3)' }, 'only the name is left in its edit')
	eq(INV:GetPin(201), 'Armor', 'its pins stay')
	check(names_unique(), 'no two share a name')

	-- With the name free again, a reset gives the shipped name back.
	INV:RenameCategory(mine, 'Mine')
	eq(INV:ResetCategory('Armor'), true, 'reset again')
	eq(INV:CategoryName('Armor'), 'Armor', 'the shipped name')
	eq(INV:CategoryStore().edits.Armor, nil, 'and no edit')
	eq(INV:CategoryName('Weapons'), 'Weapons', 'a default no other name clashes with is as shipped')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ pins

test('pins: one category per item; pinning again moves it; unpinning returns it to the rules', function()
	local c = world('compact')
	eq(INV:GetPin(101), nil, 'no pin')
	eq(INV:PinItem(101, 'Weapons'), true, 'pinned')
	eq(INV:GetPin(101), 'Weapons', 'read back')
	eq(category_of('Tonic'), 'Weapons', 'the tonic is a weapon now')
	update()
	eq(shown(c, 'Weapons'), 'Axe,Tonic', 'shown there')
	INV:PinItem(101, 'Quest')
	eq(INV:GetPin(101), 'Quest', 'pinning again moves it')
	eq(count(INV.config.categoryPins), 1, 'one category per item')
	INV:PinItem(301, 'Quest')
	INV:PinItem(150, 'Quest')
	eq(INV:GetPinnedItems('Quest'), { 101, 150, 301 }, 'GetPinnedItems is ascending')
	eq(INV:GetPinnedItems('Weapons'), {}, 'and empty for another')
	eq(INV:UnpinItem(101), true, 'unpinned')
	eq(INV:GetPin(101), nil, 'gone')
	eq(category_of('Tonic'), 'Consumables', 'back to the rules')
	eq(INV:PinItem(101, 'Equipment sets'), false, 'no pin to the sets entry')
	eq(INV:PinItem(101, 'Nothing'), false, 'nor to a category the list has not')
	eq(INV:PinItem(nil, 'Quest'), false, 'nor for no item')
	eq(INV:GetPin(101), nil, 'nothing stored')
	eq(INV:UnpinItem(999), false, 'unpinning an item with no pin')
	eq(#take_errors(), 0, 'no errors')
end)

test('Auto Vendor and Protected clear each other; a protected item is never sold, pinned or not', function()
	local c = world('compact')
	eq(INV:IsAutoVendorMarked(101), false, 'not marked')
	INV:SetAutoVendorMark(101, true)
	eq(INV:IsAutoVendorMarked(101), true, 'marked')
	eq(INV:GetPin(101), SELL, 'a mark is a pin to Grays/Auto Vendor')
	eq(category_of('Tonic'), SELL, 'in Grays/Auto Vendor')
	eq(sold():find('Tonic') ~= nil, true, 'and sold')
	INV:SetProtected(101, true)
	eq(INV:IsProtected(101), true, 'protected')
	eq(INV:IsAutoVendorMarked(101), false, 'protecting clears the mark')
	eq(INV:GetPin(101), nil, 'and the pin')
	eq(sold():find('Tonic'), nil, 'never sold')
	INV:SetAutoVendorMark(101, true)
	eq(INV:IsProtected(101), false, 'marking clears Protected')
	eq(INV:GetPin(101), SELL, 'the pin is back')
	INV:SetAutoVendorMark(101, false)
	eq(INV:GetPin(101), nil, 'unmarking unpins')
	eq(INV:IsProtected(101), false, 'protected is still off')
	-- pinning to Grays/Auto Vendor clears Protected
	INV:SetProtected(101, true)
	INV:PinItem(101, SELL)
	eq(INV:IsProtected(101), false, 'pinning to Grays/Auto Vendor clears Protected')
	-- unmarking does not take a pin elsewhere
	INV:PinItem(201, 'Weapons')
	INV:SetAutoVendorMark(201, false)
	eq(INV:GetPin(201), 'Weapons', 'unmarking leaves a pin to another category')
	-- a protected item is never sold, pinned or not (a stored pin and Protected together)
	INV.config.protectFilter[503] = true
	INV.config.categoryPins[503] = SELL
	INV:CategoriesChanged()
	update()
	eq(sold():find('Common Bit'), nil, 'protected and pinned: not sold')
	eq(slot_of(c, 'Common Bit').JunkIcon:IsShown(), false, 'and no junk coin')
	eq(INV:IsProtected(999), false, 'an item not protected')
	eq(INV:IsProtected(nil), false, 'no item')
	check(INV.ShouldAutoVendor == nil, 'ShouldAutoVendor is gone')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ selling

test('auto vendor and the junk coin follow an edited Grays/Auto Vendor rule', function()
	local c = world('compact')
	update()
	eq(sold(), 'Gray Cloth', 'as shipped: the gray')
	eq(slot_of(c, 'Gray Cloth').JunkIcon:IsShown(), true, 'the coin on the gray')
	eq(slot_of(c, 'Common Bit').JunkIcon:IsShown(), false, 'none on the common item')
	INV:SetCategoryRule(SELL, { op = 'or', items = { { block = 'quality', qualities = { 1 } } } })
	update()
	local names = sold()
	check(names:find('Common Bit'), 'quality 1 items are sold: ' .. names)
	check(not names:find('Gray Cloth'), 'a gray is not')
	eq(slot_of(c, 'Common Bit').JunkIcon:IsShown(), true, 'the coin follows the rule')
	eq(slot_of(c, 'Gray Cloth').JunkIcon:IsShown(), false, 'and leaves the gray')
	eq(#take_errors(), 0, 'no errors')
end)

test('Grays/Auto Vendor renamed and moved still sells; turned off, nothing is sold and no coin shows', function()
	local c = world('compact')
	update()
	INV:RenameCategory(SELL, 'Junk')
	INV:MoveCategory(SELL, #INV:GetCategoryList() - 1)
	update()
	eq(INV:GetCategoryList()[#INV:GetCategoryList() - 1].id, SELL, 'moved down to the last place')
	eq(INV:CategoryName(SELL), 'Junk', 'renamed')
	eq(sold(), 'Gray Cloth', 'it still sells')
	eq(slot_of(c, 'Gray Cloth').JunkIcon:IsShown(), true, 'with the coin')
	check(c.categories[SELL].header.text:GetText():find('^Junk'), 'under its new name')
	-- a renamed category that is not it does not sell
	INV:SetCategoryRule('Quest', { op = 'or', items = { { block = 'name', text = 'gray' } } })
	INV:RenameCategory('Quest', SELL)
	update()
	eq(sold(), '', 'a category that took its name sells nothing: it caught the gray first')
	INV:ResetCategory('Quest')
	-- a pin to it, then off
	INV:SetAutoVendorMark(101, true)
	update()
	check(sold():find('Tonic'), 'a marked item sells while it is on')
	INV:SetCategoryEnabled(SELL, false)
	update()
	eq(sold(), '', 'turned off: nothing is sold')
	for _, name in ipairs({ 'Gray Cloth', 'Tonic', 'Common Bit', 'Axe' }) do
		eq(slot_of(c, name).JunkIcon:IsShown(), false, 'no coin on ' .. name)
	end
	eq(category_of('Tonic'), 'Consumables', 'a pin to a category that is off is ignored')
	INV:SetCategoryEnabled(SELL, true)
	update()
	check(sold():find('Gray Cloth'), 'on again: it sells')
	eq(#take_errors(), 0, 'no errors')
end)

-- Every edit the editor makes commits at once, so a rule left mid-edit is the
-- rule auto vendor follows at the next merchant. Each edit here starts from
-- the shipped rule and is reset after.
test('a half-edited Grays/Auto Vendor rule never sells more than the shipped one', function()
	world('compact')
	update()
	local R = INV.Rules
	eq(sold(), 'Gray Cloth', 'as shipped: the gray')
	local shipped = INV:GetCategoryList().byId[SELL].rule
	eq(shipped.op, 'and', 'the root is an AND')
	eq(shipped.items[1].op, 'or', 'its first child is the inner OR')
	eq(#shipped.items[1].items, 3, 'of three')

	local function edited(fn)
		local rule = R.Copy(INV:GetCategoryList().byId[SELL].rule)
		fn(rule)
		INV:SetCategoryRule(SELL, rule)
		update()
		local names = sold()
		INV:ResetCategory(SELL)
		update()
		return names
	end
	local function safe(names, what)
		check(names == 'Gray Cloth' or names == '', what .. ': sells only the gray, or nothing, not ' .. names)
	end

	-- The X on the inner OR's blocks, one after another, from the first and from the last.
	for k = 1, 3 do
		safe(edited(function(r) for _ = 1, k do R.Remove(r, { 1, 1 }) end end), k .. ' removed from the first')
		safe(edited(function(r) for j = 3, 4 - k, -1 do R.Remove(r, { 1, j }) end end), k .. ' removed from the last')
	end
	eq(edited(function(r) for _ = 1, 3 do R.Remove(r, { 1, 1 }) end end), '', 'the inner OR emptied: nothing is sold')

	-- + Block of every type into the inner OR and into the root, plain and NOT.
	-- Old gear and Protected are complete as made (today's thresholds, no
	-- params), so NOT on one in the inner OR is a finished rule that says
	-- "everything but": auto vendor follows it, as it follows any rule.
	local COMPLETE = { oldgear = true, protected = true }
	for _, t in ipairs(R.BLOCKS) do
		eq(edited(function(r) R.Insert(r, { 1 }, nil, R.NewBlock(t.id)) end), 'Gray Cloth', t.id .. ' in the inner OR')
		if not COMPLETE[t.id] then
			eq(edited(function(r)
				R.Insert(r, { 1 }, nil, R.NewBlock(t.id))
				R.ToggleNot(r, { 1, 4 })
			end), 'Gray Cloth', 'NOT ' .. t.id .. ' in the inner OR')
		end
		safe(edited(function(r) R.Insert(r, {}, nil, R.NewBlock(t.id)) end), t.id .. ' in the root')
		safe(edited(function(r)
			R.Insert(r, {}, nil, R.NewBlock(t.id))
			R.ToggleNot(r, { #r.items })
		end), 'NOT ' .. t.id .. ' in the root')
	end

	-- + Group, in the inner OR and in the root, plain and NOT.
	eq(edited(function(r) R.Insert(r, { 1 }, nil, R.NewGroup('or')) end), 'Gray Cloth', 'a new group in the inner OR')
	eq(edited(function(r)
		R.Insert(r, { 1 }, nil, R.NewGroup('or'))
		R.ToggleNot(r, { 1, 4 })
	end), 'Gray Cloth', 'a new NOT group in the inner OR')
	eq(edited(function(r) R.Insert(r, {}, nil, R.NewGroup('and')) end), '', 'a new group in the root: nothing until it has blocks')
	eq(edited(function(r)
		R.Insert(r, {}, nil, R.NewGroup('and'))
		R.ToggleNot(r, { #r.items })
	end), '', 'a new NOT group in the root: nothing either')

	eq(sold(), 'Gray Cloth', 'reset: the gray again')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ combat

test('a category made out of combat has its frames; pinning to it in combat makes no frame or slot, and the item shows there after the update', function()
	local c = world('compact')
	local id = INV:AddUserCategory()
	INV:RenameCategory('Weapons', 'Blades')
	update()
	check(c.categories[id] and #c.categories[id].slots > 0, 'the new category has its frame and its slot pool')
	stub.in_combat = true
	local made = H.frames_made()
	INV:PinItem(101, id)
	INV:PinItem(150, 'Weapons')
	update()
	eq(H.frames_made(), made, 'no frame or slot made in combat')
	eq(shown(c, id), 'Tonic', 'the item shows in the category made out of combat')
	eq(shown(c, 'Weapons'), 'Axe,Rock', 'and in the renamed one')
	-- a category made in combat: queued, no frame; its items show after combat
	local late = INV:AddUserCategory()
	eq(c.categories[late], nil, 'no frame made in combat')
	INV:PinItem(301, late)
	update()
	eq(H.frames_made(), made, 'still none after an update in combat')
	eq(shown(c, late), '', 'the item is not there yet')
	eq(INV.NEED_UPDATE, true, 'an update is wanted')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check(c.categories[late], 'the frame is made when combat ends')
	INV:UpdateContainer('bag', true)
	eq(shown(c, late), 'Plank', 'and the item shows there on the next update')
	eq(#take_errors(), 0, 'no errors')
end)

test('a category made in combat has no frame in Rows either, until combat ends', function()
	local c = world('rows')
	stub.in_combat = true
	local made = H.frames_made()
	local late = INV:AddUserCategory()
	INV:PinItem(301, late)
	update()
	eq(H.frames_made(), made, 'no frame or slot made in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	INV:UpdateContainer('bag', true)
	eq(shown(c, late), 'Plank', 'after combat the item shows there')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ caches

test('every write drops the caches and queues one update with layout', function()
	world('compact')
	local mine = INV:AddUserCategory()
	INV:PinItem(101, 'Quest')
	local writes = {
		{ 'AddUserCategory', function() return INV:AddUserCategory() end },
		{ 'RenameCategory', function() return INV:RenameCategory('Weapons', 'Blades') end },
		{ 'SetCategoryEnabled', function() return INV:SetCategoryEnabled('Weapons', false) end },
		{ 'SetCategoryRule', function() return INV:SetCategoryRule('Weapons', { op = 'or', items = { { block = 'name', text = 'z' } } }) end },
		{ 'MoveCategory', function() return INV:MoveCategory('Weapons', 2) end },
		{ 'RemoveCategory (default)', function() return INV:RemoveCategory('Keys') end },
		{ 'RemoveCategory (yours)', function() return INV:RemoveCategory(mine) end },
		{ 'RestoreCategory', function() return INV:RestoreCategory('Keys') end },
		{ 'ResetCategory', function() return INV:ResetCategory('Weapons') end },
		{ 'PinItem', function() return INV:PinItem(201, 'Quest') end },
		{ 'UnpinItem', function() return INV:UnpinItem(201) end },
		{ 'SetProtected', function() return INV:SetProtected(301, true) end },
		{ 'SetAutoVendorMark', function() return INV:SetAutoVendorMark(301, true) end },
		{ 'ResetAllCategories', function() return INV:ResetAllCategories() end },
	}
	local queued, withLayout
	local real = INV.QueueUpdate
	INV.QueueUpdate = function(self, layout)
		queued = queued + 1
		if layout then withLayout = withLayout + 1 end
		return real(self, layout)
	end
	for _, write in ipairs(writes) do
		local list = INV:GetCategoryList()
		queued, withLayout = 0, 0
		write[2]()
		check(INV:GetCategoryList() ~= list, write[1] .. ': the list is read again')
		eq(queued, 1, write[1] .. ': one update queued')
		eq(withLayout, 1, write[1] .. ': with layout')
	end
	-- a refused write queues nothing
	queued = 0
	INV:RenameCategory('Weapons', '')
	INV:SetCategoryEnabled('Miscellaneous', false)
	INV:RemoveCategory('Miscellaneous')
	INV:MoveCategory('Miscellaneous', 1)
	INV:PinItem(101, 'Equipment sets')
	eq(queued, 0, 'a refused write queues nothing')
	INV.QueueUpdate = real
	eq(#take_errors(), 0, 'no errors')
end)
