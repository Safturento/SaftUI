-- Item groups (SaftUI-Bags/itemgroups.lua): the list, a client's set read at
-- call time, the "Item group is" rule block (unreadable when it names no
-- group), and the Fish default category before the food, on Forever and
-- retail. The data is set here by hand; bags/bag_world.lua loads the real
-- files over a stubbed bag world.
local W = load_test_file('bags/bag_world.lua')

local INV, R, IG, nextSlot

local DATA = { forever = { fish = { [6303] = true } } }

local function world(client, data)
	INV = W.fresh(client)
	INV.ItemGroupsData = data
	R, IG = INV.Rules, INV.ItemGroups
	W.bag(0, 200, 'Backpack')
	W.container('bag')
	nextSlot = 0
	return INV
end

local function put(fields)
	nextSlot = nextSlot + 1
	W.put(0, nextSlot, W.item(fields.itemID, fields.name, nil, 1, fields))
	local info = INV:GetInventoryItemInfo(0, nextSlot, 'bag')
	check(info and not info.loading, fields.name .. ' reads as an item')
	return info
end

local function match(rule, info)
	return R.Compile(rule)(info) and true or false
end

local FISH = { block = 'group', group = 'fish' }
local function OR(...) return { op = 'or', items = { ... } } end
local function AND(...) return { op = 'and', items = { ... } } end
local function NOT(node) return { op = 'or', negate = true, items = { node } } end

test('the groups, their labels and this client\'s sets', function()
	world('forever', DATA)
	eq(#IG.Groups(), 1, 'one group')
	eq(IG.Groups()[1].id, 'fish', 'Fish')
	eq(IG.Groups()[1].label, 'Fish', 'its label')
	eq(IG.Label('fish'), 'Fish', 'a label by id')
	eq(IG.Label('nope'), nil, 'an unknown id has none')
	eq(IG.Label(5), nil, 'nor a number')
	eq(IG.Set('fish')[6303], true, 'Forever: the set')
	eq(next(IG.Set('nope')), nil, 'an unknown group: empty')
	INV.ItemGroupsData = nil
	eq(next(IG.Set('fish')), nil, 'no data at all: empty, no error')
	INV.ItemGroupsData = DATA
	eq(IG.Set('fish')[6303], true, 'read at call time: the data set later counts')
	world('retail', DATA)
	eq(next(IG.Set('fish')), nil, 'retail has no Fish set here')
	INV.ItemGroupsData = { retail = { fish = { [1] = true } } }
	eq(IG.Set('fish')[1], true, 'and takes its own when it has one')
end)

test('the group block matches the set, and nothing it cannot read', function()
	world('forever', DATA)
	local fish = put({ itemID = 6303, name = 'Raw Slitherskin Mackerel', classID = 7, subclassID = 8 })
	local other = put({ itemID = 6292, name = 'Something Else', classID = 7, subclassID = 8 })
	eq(match(OR(FISH), fish), true, 'a fish')
	eq(match(OR(FISH), other), false, 'not another item')
	eq(match(OR(FISH), { name = 'No ID' }), false, 'not an info with no itemID')
	for label, bad in pairs({ ['no group'] = { block = 'group' }, ['an unknown group'] = { block = 'group', group = 'nope' },
		['a number'] = { block = 'group', group = 5 } }) do
		eq(match(OR(bad), fish), false, 'OR of ' .. label .. ' matches nothing')
		eq(match(AND(bad, { block = 'items', ids = { 6303 } }), fish), false, 'AND(' .. label .. ', anything) matches nothing')
		eq(match(OR(NOT(bad)), fish), false, 'NOT of ' .. label .. ' matches nothing')
		eq(match(AND({ block = 'items', ids = { 6303 } }, NOT(bad)), fish), false, 'and not inside an AND')
	end
	eq(match(AND({ block = 'items', ids = { 6303 } }, NOT(FISH)), fish), false, 'NOT of a readable group flips')
	eq(match(AND({ block = 'items', ids = { 6292 } }, NOT(FISH)), other), true, 'and keeps the rest')
end)

test('the block is described, made, and listed', function()
	world('forever', DATA)
	eq(R.Describe(OR(FISH), { 1 }), 'Item group is Fish', 'described')
	eq(R.Describe(OR({ block = 'group', group = 'nope' }), { 1 }), 'Item group is nope', 'an unknown group by its id')
	eq(R.Describe(OR({ block = 'group' }), { 1 }), 'Item group is (none)', 'an unset group')
	local new = R.NewBlock('group')
	eq(new.block, 'group', 'a group block')
	eq(new.group, nil, 'with no group yet')
	eq(next(new, next(new)), nil, 'and nothing else')
	eq(match(OR(new), put({ itemID = 6303, name = 'Raw Fish', classID = 7, subclassID = 8 })), false, 'it is unreadable')
	eq(R.BlockType('group').label, 'Item group is', 'its label')
end)

test('Forever: Fish files before the food and the trade goods', function()
	world('forever', DATA)
	local list = INV:GetCategoryList()
	local at = {}
	for i, entry in ipairs(list) do at[entry.id] = i end
	eq(at['Fish'], at['Flasks/Potions/Food'] - 1, 'Fish sits right before Flasks/Potions/Food')
	eq((INV:GetItemCategory(put({ itemID = 6303, name = 'Raw Slitherskin Mackerel', classID = 0, subclassID = 5 }))), 'Fish',
		'food that is a fish')
	eq((INV:GetItemCategory(put({ itemID = 13935, name = 'Baked Salmon', classID = 0, subclassID = 5 }))),
		'Flasks/Potions/Food', 'other food')
	eq((INV:GetItemCategory(put({ itemID = 6303, name = 'Raw Slitherskin Mackerel', classID = 7, subclassID = 8 }))), 'Fish',
		'a trade good that is a fish')
	eq(#take_errors(), 0, 'no errors')
end)

test('retail: the fish group is empty, nothing errors', function()
	world('retail', DATA)
	eq((INV:GetItemCategory(put({ itemID = 6303, name = 'Raw Slitherskin Mackerel', classID = 7, subclassID = 8 }))),
		'Trade Goods', 'it stays a trade good')
	check(INV:GetCategoryList().byId['Fish'], 'the category is still listed')
	eq(#take_errors(), 0, 'no errors')
end)

test('profiles: a saved order without Fish, and a category named Fish', function()
	world('forever', DATA)
	local order = {}
	for _, def in ipairs(INV.CategoryDefaults.Build()) do
		if def.id ~= 'Fish' then order[#order + 1] = def.id end
	end
	local store = INV:CategoryStore()
	store.order = order
	INV:CategoriesChanged()
	local list = INV:GetCategoryList()
	local at = {}
	for i, entry in ipairs(list) do at[entry.id] = i end
	eq(at['Fish'], at['Mounts'] + 1, 'the old order gets Fish right after Mounts')
	check(list.byId['Fish'].default, 'it is the default')

	-- Your own category named Fish: both stay, under different names.
	store.custom['custom:1'] = { name = 'Fish', enabled = true, hide = {},
		rule = { op = 'or', items = { { block = 'items', ids = { 1 } } } } }
	store.order = order
	table.insert(order, #order, 'custom:1')
	INV:CategoriesChanged()
	list = INV:GetCategoryList()
	local names, seen = {}, {}
	for _, entry in ipairs(list) do
		check(not seen[entry.name], 'one entry named ' .. entry.name)
		seen[entry.name] = true
		names[#names + 1] = entry.name
	end
	check(list.byId['Fish'] and list.byId['custom:1'], 'both are there')
	eq(list.byId['custom:1'].name, 'Fish', 'yours keeps its name')
	eq(list.byId['Fish'].name, 'Fish (2)', 'the default is numbered')
	eq(#take_errors(), 0, 'no errors')
end)
