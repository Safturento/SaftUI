-- The default categories and the list the bags categorize by
-- (SaftUI-Bags/categorydefaults.lua and categories.lua): today's 33 filters as
-- block rules, in today's order after Equipment sets, catching exactly what
-- today's filters catch on both clients (fixtures/old_filters.lua is today's
-- filters.lua, the oracle; fixtures/category_items.lua the items), with the
-- deliberate changes asserted on their own; class and subclass names resolved
-- for each client; how an item gets its category (pins, sets, the rules in
-- order, Miscellaneous) and why; what auto vendor may sell; the list read from
-- the profile's store; and filters.lua gone. bags/bag_world.lua loads the real
-- files over a stubbed bag world.
local W = load_test_file('bags/bag_world.lua')
local FIXTURES = load_test_file('bags/fixtures/category_items.lua')

local INV, OLD, nextSlot

-- The world for a client: one big backpack, the player level 80 with an
-- average item level of 300 (fixtures/category_items.lua's old gear is measured
-- against that), and a fresh oracle.
local function world(client)
	INV = W.fresh(client)
	OLD = load_test_file('bags/fixtures/old_filters.lua')
	W.bag(0, 200, 'Backpack')
	W.container('bag')
	nextSlot = 0
	stub.level = 80
	_G.GetAverageItemLevel = function() return 300 end
	return INV
end

-- Puts an item (bag_world W.item fields, ids given) in the next free slot and
-- reads its info. protected puts it on both Protected lists, today's and ours.
local function put(fields, protected)
	nextSlot = (nextSlot or 0) + 1
	local copy = {}
	for k, v in pairs(fields) do copy[k] = v end
	W.put(0, nextSlot, W.item(copy.itemID, copy.name, nil, copy.ilvl, copy))
	if protected then
		INV.config.protectFilter = INV.config.protectFilter or {}
		INV.config.protectFilter[copy.itemID] = true
		OLD.protected[copy.itemID] = true
	end
	local info = INV:GetInventoryItemInfo(0, nextSlot, 'bag')
	check(info and not info.loading, (copy.name or '?') .. ' reads as an item')
	return info
end

local function key(fields, protected)
	return (INV:GetItemCategory(put(fields, protected)))
end

-- The fixtures for a client.
local function fixtures(client)
	local out = {}
	for _, f in ipairs(FIXTURES) do
		if not f.client or f.client == client then out[#out + 1] = f end
	end
	return out
end

local function fixture(label)
	for _, f in ipairs(FIXTURES) do
		if f[1] == label then return f end
	end
	error('no fixture ' .. label)
end

local function ids(list)
	local out = {}
	for i, entry in ipairs(list) do out[i] = entry.id end
	return out
end

-- A rule as short text: and(...) / or(...), ! for NOT, a class as "class N",
-- a subclass as "sub C/S,S", text blocks as tt"..." / name"..." (w: whole word).
local function render(node)
	if type(node) ~= 'table' then return '?' end
	local neg = node.negate and '!' or ''
	if node.op then
		local parts = {}
		for i, child in ipairs(node.items or {}) do parts[i] = render(child) end
		return neg .. node.op .. '(' .. table.concat(parts, ', ') .. ')'
	end
	local b = node.block
	if b == 'class' then return neg .. 'class ' .. tostring(node.class) end
	if b == 'subclass' then
		local subs = {}
		for i, s in ipairs(node.subclasses or {}) do subs[i] = tostring(s) end
		return neg .. 'sub ' .. tostring(node.class) .. '/' .. table.concat(subs, ',')
	end
	if b == 'tooltip' or b == 'name' then
		return neg .. (b == 'tooltip' and 'tt' or 'name') .. '"' .. node.text .. '"' .. (node.word and 'w' or '')
	end
	if b == 'nameis' then return neg .. 'is"' .. node.text .. '"' end
	if b == 'quality' then return neg .. 'quality ' .. table.concat(node.qualities, ',') end
	if b == 'binding' then return neg .. 'binding ' .. table.concat(node.states, ',') end
	if b == 'oldgear' then return neg .. 'oldgear ' .. node.levels .. '/' .. node.expansion .. '/' .. node.share end
	if b == 'items' then return neg .. 'items(' .. #node.ids .. ')' end
	if b == 'vendorprice' then return neg .. 'price ' .. (node.value and 'yes' or 'no') end
	return neg .. tostring(b)
end

-- Whether any node of a rule still names a class or subclass in words.
local function has_names(node)
	if type(node) ~= 'table' then return false end
	if node.className or node.classEnum or node.subclassNames then return true end
	for _, child in ipairs(node.items or {}) do
		if has_names(child) then return true end
	end
	return false
end

local function entry_of(id) return INV:GetCategoryList().byId[id] end

local function set_store(fields)
	local store = INV:CategoryStore()
	for k, v in pairs(fields) do store[k] = v end
	INV:CategoriesChanged()
	return store
end

------------------------------------------------------------------ the defaults

test("the default list is today's, in today's order, after Equipment sets", function()
	world('forever')
	local want = { 'Equipment sets' }
	for _, name in ipairs(OLD.names) do want[#want + 1] = name end
	eq(#OLD.names, 33, "today's 33 filters")
	eq(#want, 34, '34 ids')
	eq(table.concat(ids(INV:GetCategoryList()), ' | '), table.concat(want, ' | '), 'the list, in order')
	eq(table.concat(ids(INV.CategoryDefaults.Build()), ' | '), table.concat(want, ' | '), 'the defaults, in order')
	local list = INV:GetCategoryList()
	eq(list[1].kind, 'sets', 'Equipment sets is the sets entry')
	eq(list[#list].kind, 'misc', 'Miscellaneous is last')
	for i = 2, #list - 1 do
		eq(list[i].kind, 'rule', list[i].id .. ' is a rule')
		eq(list[i].name, list[i].id, list[i].id .. ': named its id')
		eq(list[i].enabled, true, list[i].id .. ': on')
		eq(list[i].default, true, list[i].id .. ': a default')
		eq(list[i].edited, false, list[i].id .. ': not edited')
		eq(list[i].place, i, list[i].id .. ': its place')
		eq(list[i].sells, list[i].id == 'Grays/Auto Vendor', list[i].id .. ': only Grays sells')
		check(type(list[i].hide) == 'table' and next(list[i].hide) == nil, list[i].id .. ': shown everywhere')
	end
	eq(INV.SELL_CATEGORY, 'Grays/Auto Vendor', 'the selling category')
	eq(INV.SETS_ENTRY, 'Equipment sets', 'the sets entry')
	eq(INV.MISC_CATEGORY, 'Miscellaneous', 'Miscellaneous')
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": every default catches what today's filter catches", function()
		world(client)
		for _, f in ipairs(fixtures(client)) do
			if not f.changed then
				local info = put(f.item, f.protected)
				eq(OLD.categorize(info), f.expect, f[1] .. ": today's filters")
				eq((INV:GetItemCategory(info)), f.expect, f[1] .. ': the defaults')
			end
		end
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('every default has an item it catches', function()
	local caught = {}
	for _, f in ipairs(FIXTURES) do caught[f.expect] = true end
	world('retail')
	for _, entry in ipairs(INV:GetCategoryList()) do
		-- Devices only holds Consumable subclass 14, which Consumables takes
		-- first (as today), and the sets entry's keys are 'Set: <name>'.
		if entry.kind == 'rule' and entry.id ~= 'Devices' then
			check(caught[entry.id], entry.id .. ' has a fixture it catches')
		end
	end
	check(caught['Set: Tank'], 'the sets entry has one')
	check(caught.Miscellaneous, 'Miscellaneous has one')
end)

local RESOLVED = {
	both = {
		['Grays/Auto Vendor'] = 'and(or(quality 0, oldgear 10/9/0.9, and(binding soulbound, tt"cffff2020Classes:")), '
			.. '!protected, !sub 4/5, !tt"Fishing", !tt"Blizzard Account Bound", price yes)',
		['Container'] = 'and(or(tt"Right Click to Open", tt"Open the container", tt"Open the sack", tt"Use: collect", '
			.. 'tt"Use: Open", tt"Flightstones"), !class 4, !class 2)',
		['Mounts'] = 'or(sub 15/5)',
		['Consumables'] = 'or(class 0)',
		['Armor (Warbound)'] = 'and(class 4, binding warbound)',
		['Armor'] = 'or(class 4)',
		['Weapons'] = 'or(class 2)',
		['Professions/Recipes'] = 'or(items(1), tt"Use: Study to increase your", class 9)',
		['Quest'] = 'or(class 12)',
		['Keys'] = 'or(class 13, name"key"w)',
		['Delves'] = 'or(tt"Curio"w, is"Delver\'s Bounty", is"Trovehunter\'s Bounty")',
		['Reputation'] = 'and(tt"Use: Grants ", tt" reputation")',
		['Archaeology'] = 'or(items(40), tt"Carefully crate the restored artifact")',
	},
	forever = {
		['Pets'] = 'or(name"Battle-Stone", name"Battle-Training Stone", class 17)',
		['Housing'] = 'or()',
		['Flasks/Potions/Food'] = 'or(sub 0/1,5)',
		['Gems/Enchants'] = 'or()',
		['Trade Goods'] = 'or(class 7)',
		['Devices'] = 'or(sub 0/14)',
	},
	retail = {
		['Pets'] = 'or(name"Battle-Stone", name"Battle-Training Stone", sub 15/2, class 17)',
		['Housing'] = 'or(class 20)',
		['Flasks/Potions/Food'] = 'or(sub 0/1,3,5)',
		['Gems/Enchants'] = 'or(class 3)',
		['Trade Goods'] = 'or(class 3, class 7)',
		['Devices'] = 'or()',
	},
}

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': names resolve for this client', function()
		world(client)
		for _, set in ipairs({ RESOLVED.both, RESOLVED[client] }) do
			for id, want in pairs(set) do
				local def = INV:GetDefaultCategory(id)
				check(def ~= nil, id .. ' is a default')
				if def then eq(render(def.rule), want, id) end
			end
		end
		for _, def in ipairs(INV.CategoryDefaults.Build()) do
			check(not has_names(def.rule), def.id .. ': no class or subclass is left as a name')
		end
		eq(INV:GetDefaultCategory('Equipment sets').rule, nil, 'the sets entry has no rule')
		eq(INV:GetDefaultCategory('Miscellaneous').rule, nil, 'nor has Miscellaneous')
		eq(INV:GetDefaultCategory('Nope'), nil, 'an id that is no default')
		-- Built once, and the same table each time.
		eq(INV.CategoryDefaults.Build(), INV.CategoryDefaults.Build(), 'cached')
		-- A class the enum names goes by the enum when the client has it.
		INV.CategoryDefaults.Reset()
		Enum.ItemClass = { Battlepet = 42, Key = 13 }
		check(render(INV:GetDefaultCategory('Pets').rule):find('class 42', 1, true), 'Battlepet from Enum.ItemClass')
		Enum.ItemClass = nil
		INV.CategoryDefaults.Reset()
	end)
end

test('a name that resolves to nothing: dropped from an OR, dropped when negated in an AND, and a plain one empties its AND', function()
	world('forever')
	local CD = INV.CategoryDefaults
	local function cls(name, negate) return { block = 'class', className = name, negate = negate } end
	local function tt(text) return { block = 'tooltip', text = text } end
	eq(render(CD.Resolve({ op = 'or', items = { cls('Gem'), tt('x') } })), 'or(tt"x")', 'OR: dropped')
	eq(render(CD.Resolve({ op = 'and', items = { cls('Gem', true), tt('x') } })), 'and(tt"x")', 'AND: a negated one dropped')
	eq(render(CD.Resolve({ op = 'and', items = { cls('Gem'), tt('x') } })), 'and()', 'AND: a plain one matches nothing')
	eq(render(CD.Resolve({ op = 'or', items = { cls('Gem') } })), 'or()', 'a root left with nothing')
	eq(render(CD.Resolve({ op = 'or', items = { tt('y'), { op = 'and', items = { cls('Gem'), tt('x') } } } })),
		'or(tt"y")', 'an AND matching nothing inside an OR is dropped')
	eq(render(CD.Resolve({ op = 'and', items = { tt('y'), { op = 'and', items = { cls('Gem'), tt('x') } } } })),
		'and()', 'and makes the AND above it match nothing too')
	eq(render(CD.Resolve({ op = 'and', items = { tt('y'), { op = 'and', negate = true, items = { cls('Gem'), tt('x') } } } })),
		'and(tt"y")', 'NOT of an AND matching nothing is dropped from an AND')
	eq(render(CD.Resolve({ op = 'or', items = { cls('Armor'), cls('Armor'), tt('x') } })), 'or(class 4, tt"x")',
		'a block twice in one OR is kept once')
	eq(render(CD.Resolve({ op = 'or', items = { { block = 'subclass', subclassNames = { 'Food & Drink', 'Potions', 'Gem' } } } })),
		'or(sub 0/1,5)', 'subclasses: one block per class, ascending, names with none left out')
	-- A name in two classes: one block per class, OR'ed in a group.
	eq(render(CD.Resolve({ op = 'and', items = { { block = 'subclass', subclassNames = { 'Miscellaneous' }, negate = true } } })),
		'and(!or(sub 2/14, sub 4/0))', 'several classes are an OR group, negated as the block was')
end)

test('Delves: "Curious" is not Delves; "Combat Curio" is', function()
	world('retail')
	local curious = put(fixture('"Curious Coin", whose tooltip says "Curious"').item)
	eq(OLD.categorize(curious), 'Delves', 'today "Curious" was Delves')
	eq((INV:GetItemCategory(curious)), 'Miscellaneous', 'now it is not')
	local curio = put(fixture('right text "Combat Curio"').item)
	eq(OLD.categorize(curio), 'Delves', 'today "Combat Curio" was Delves')
	eq((INV:GetItemCategory(curio)), 'Delves', 'and still is')
	local function both(fields)
		local info = put(fields)
		return OLD.categorize(info) .. ' -> ' .. INV:GetItemCategory(info)
	end
	eq(both({ itemID = 3001, name = 'Odd Trinket', classID = 15, subclassID = 4, tooltip = { 'It shows curiosity.' } }),
		'Delves -> Miscellaneous', '"curiosity" is not Delves now')
	eq(both({ itemID = 3002, name = 'Odd Charm', classID = 15, subclassID = 4, tooltip = { 'A curio.' } }),
		'Delves -> Delves', '"curio" at the end of a sentence is, as it was')
	eq(both({ itemID = 3003, name = 'Odd Idol', classID = 15, subclassID = 4, tooltip = { 'Type: Combat-Curio' } }),
		'Miscellaneous -> Delves', '"Curio" right after punctuation is now')
	eq(both({ itemID = 3004, name = 'Odd Box', classID = 15, subclassID = 4, tooltip = { 'Brann\'s curios' } }),
		'Delves -> Miscellaneous', 'and "curios" is not')
end)

test('Reputation: catches every "Use: Grants N reputation", and a "Use: Grants" with "reputation" apart', function()
	world('forever')
	local id = 3100
	local function both(text)
		id = id + 1
		local info = put({ itemID = id, name = 'Token ' .. id, classID = 15, subclassID = 4, tooltip = { text } })
		return OLD.categorize(info), (INV:GetItemCategory(info))
	end
	for _, text in ipairs({
		'Use: Grants 1,500 reputation with the Dream Wardens.',
		'Use: Grants 250 reputation with the Assembly of the Deeps.',
		'use: grants 10 reputation',
		'Use: Grants 1,000,000 reputation with everyone.',
	}) do
		local old, new = both(text)
		eq(old, 'Reputation', text .. ': today')
		eq(new, 'Reputation', text .. ': now')
	end
	local old, new = both('Use: Grants a random amount of reputation with a faction.')
	eq(old, 'Miscellaneous', 'today a Grants without a number was not Reputation')
	eq(new, 'Reputation', 'now it is (the one way the blocks catch more)')
	old, new = both('Use: Grants you a mount. Your reputation is unchanged.')
	eq(new, 'Reputation', 'the two phrases anywhere in the tooltip')
	old, new = both('Grants 1,500 reputation with the Dream Wardens.')
	eq(old, 'Miscellaneous', 'no "Use:": not today'); eq(new, 'Miscellaneous', 'nor now')
end)

test("today's overlaps keep their order", function()
	world('retail')
	eq(key(fixture('a retail gem (class 3)').item), 'Gems/Enchants', 'a retail gem: Gems/Enchants, not Trade Goods')
	eq(key(fixture('a mail helm for Warrior, Hunter, Shaman (not Armor)').item), 'Warrior/Hunter/Shaman',
		'a tier group mail helm: its group, not Armor')
	eq(key(fixture('a grey sword').item), 'Grays/Auto Vendor', 'a grey sword: Grays, not Weapons')
	eq(key(fixture('a retail flask (0/3, "Flasks & Phials")').item), 'Flasks/Potions/Food', 'a flask on retail')
	eq(key(fixture('a quest item "Rusty Key" (not Keys)').item), 'Quest', '"Rusty Key", a quest item: Quest')
	eq(key(fixture('a chest warbound until equipped').item), 'Armor (Warbound)', 'warbound armor: Armor (Warbound)')
	eq(key(fixture('a trade good "Emerald Dreamseed" (not Trade Goods)').item), 'Emerald Dream',
		'a Dreamseed trade good: Emerald Dream')
	world('forever')
	eq(key(fixture('a Forever flask (0/3, "Flasks")').item), 'Consumables', 'a flask on Forever: Consumables')
end)

-------------------------------------------------------------------- the list

test('first match wins; Miscellaneous is last, always on, and catches the rest', function()
	world('forever')
	local warbound = fixture('a chest warbound until equipped').item
	eq(key(warbound), 'Armor (Warbound)', 'the first category that matches')
	-- Armor before Armor (Warbound): Armor now matches first.
	local order = ids(INV:GetCategoryList())
	for i, id in ipairs(order) do
		if id == 'Armor (Warbound)' then order[i] = 'Armor' elseif id == 'Armor' then order[i] = 'Armor (Warbound)' end
	end
	set_store({ order = order })
	eq(key(warbound), 'Armor', 'moved up, Armor catches it first')
	-- Miscellaneous first in the order, and turned off: still last and on.
	table.insert(order, 1, 'Miscellaneous')
	set_store({ order = order, edits = { Miscellaneous = { enabled = false } } })
	local list = INV:GetCategoryList()
	eq(list[#list].id, 'Miscellaneous', 'Miscellaneous is last whatever the order says')
	eq(list[#list].enabled, true, 'and on')
	eq(key({ itemID = 3201, name = 'Lucky Pebble', classID = 15, subclassID = 4 }), 'Miscellaneous', 'it catches the rest')
	-- Every rule off: everything is Miscellaneous.
	local edits = {}
	for _, entry in ipairs(list) do edits[entry.id] = { enabled = false } end
	INV:CategoryStore().order = nil
	set_store({ edits = edits })
	eq(key(fixture('a cloth chest').item), 'Miscellaneous', 'with every category off, armor too')
	eq(key(fixture('a grey "Broken Fang"').item), 'Miscellaneous', 'and a grey')
	eq(#take_errors(), 0, 'no errors')
end)

test('equipment sets come first; turned off, set items go by the rules', function()
	world('forever')
	local helm = fixture('a plate helm in the set "Tank"').item
	eq(key(helm), 'Set: Tank', 'a set item: its set')
	local grey = { itemID = 3301, name = 'Grey Set Helm', classID = 4, subclassID = 4, equipLoc = 'INVTYPE_HEAD',
		quality = 0, set = 'Tank' }
	eq(key(grey), 'Set: Tank', 'before Grays too')
	local multi = { itemID = 3302, name = 'Shared Helm', classID = 4, subclassID = 4, equipLoc = 'INVTYPE_HEAD',
		reqLevel = 80, ilvl = 300, set = 'Heal,Tank' }
	eq(key(multi), 'Set: Heal', 'an item in two sets: the first')
	local bag = { itemID = 3303, name = 'Set Bandage', classID = 0, subclassID = 7, set = 'Tank' }
	eq(key(bag), 'Consumables', 'only armor and weapons go by their set')
	set_store({ edits = { ['Equipment sets'] = { enabled = false } } })
	eq(key(helm), 'Armor', 'sets off: the helm goes by the rules')
	eq(key(grey), 'Grays/Auto Vendor', 'and the grey to Grays')
	-- With no GetContainerItemEquipmentSetInfo, no item is in a set.
	set_store({ edits = {} })
	C_Container.GetContainerItemEquipmentSetInfo = nil
	eq(key(helm), 'Armor', 'no set API: no sets')
	eq(#take_errors(), 0, 'no errors')
end)

test('a pin beats the rules and the order; a pin to a category that is off or missing, or to the sets entry, is ignored', function()
	world('forever')
	local grey = fixture('a grey "Broken Fang"').item
	local helm = fixture('a plate helm in the set "Tank"').item
	INV.config.categoryPins = { [grey.itemID] = 'Weapons', [helm.itemID] = 'Keys' }
	INV:CategoriesChanged()
	eq(key(grey), 'Weapons', 'a pinned grey: its pin, not Grays')
	eq(key(helm), 'Keys', 'a pinned set item: its pin, not its set')
	INV.config.categoryPins[grey.itemID] = 'Miscellaneous'
	eq(key(grey), 'Miscellaneous', 'a pin to Miscellaneous')
	-- Pins are read at call time.
	INV.config.categoryPins[grey.itemID] = 'Toys'
	set_store({ edits = { Toys = { enabled = false } } })
	eq(key(grey), 'Grays/Auto Vendor', 'a pin to a category that is off: the rules')
	INV.config.categoryPins[grey.itemID] = 'custom:9'
	eq(key(grey), 'Grays/Auto Vendor', 'a pin to a category that does not exist')
	INV.config.categoryPins[grey.itemID] = 'Anima'
	set_store({ edits = {}, deleted = { Anima = true } })
	eq(key(grey), 'Grays/Auto Vendor', 'a pin to a deleted default')
	INV.config.categoryPins[grey.itemID] = 'Equipment sets'
	eq(key(grey), 'Grays/Auto Vendor', 'a pin to the sets entry')
	INV.config.categoryPins[grey.itemID] = 'custom:1'
	set_store({ custom = { ['custom:1'] = { name = 'Junk I keep', enabled = true, rule = { op = 'or', items = {} } } },
		order = { 'Equipment sets', 'Grays/Auto Vendor', 'custom:1' } })
	eq(key(grey), 'custom:1', "a pin to the user's category, whose rule catches nothing")
	INV.config.categoryPins = nil
	eq(key(grey), 'Grays/Auto Vendor', 'no pins at all')
	eq(#take_errors(), 0, 'no errors')
end)

test('GetItemCategory says why: pin, set, rule with its path, misc', function()
	world('forever')
	local function why(fields)
		local k, w = INV:GetItemCategory(put(fields))
		local path = w and w.path and ('{' .. table.concat(w.path, ',') .. '}') or ''
		return k .. ' ' .. (w and w.kind or 'nil') .. path
	end
	local grey = fixture('a grey "Broken Fang"').item
	eq(why(grey), 'Grays/Auto Vendor rule{1,1}', 'Grays: the OR, by quality')
	eq(why(fixture('old gear: rare plate, level 30, expansion 2, item level 60').item), 'Grays/Auto Vendor rule{1,2}',
		'Grays: the OR, by old gear')
	eq(why(fixture('a soulbound robe with the red Classes: line').item), 'Grays/Auto Vendor rule{1,3,1}',
		'Grays: the OR, by the soulbound AND')
	eq(why(fixture('a Miscellaneous item "Key-Ring of Doom"').item), 'Keys rule{2}', 'Keys by its name')
	eq(why(fixture('"Skeleton Key" (class 13)').item), 'Keys rule{1}', 'Keys by its class')
	eq(why(fixture('a plate helm in the set "Tank"').item), 'Set: Tank set', 'a set')
	eq(why(fixture('"Lucky Rock"').item), 'Miscellaneous misc', 'Miscellaneous')
	INV.config.categoryPins = { [grey.itemID] = 'Armor' }
	eq(why(grey), 'Armor pin', 'a pin')
	-- ReadBags keeps it on the info.
	INV.config.categoryPins = nil
	W.bags[0] = nil
	W.bag(0, 4, 'Backpack')
	W.put(0, 1, W.item(4001, 'Grey Thing', nil, 1, { classID = 15, subclassID = 0, quality = 0 }))
	W.put(0, 2, W.item(4002, 'Plain Thing', nil, 1, { classID = 15, subclassID = 4 }))
	local bags, _, _, categoryOf = INV:ReadBags('bag', function() return 'bag' end)
	local a, b = bags[1].items[1], bags[1].items[2]
	eq(categoryOf[a], 'Grays/Auto Vendor', 'ReadBags: the key'); eq(a.category, 'Grays/Auto Vendor', 'on the info')
	eq(a.categoryWhy and a.categoryWhy.kind, 'rule', 'and why')
	eq(a.categoryWhy and table.concat(a.categoryWhy.path, ','), '1,1', 'with its path')
	eq(b.categoryWhy and b.categoryWhy.kind, 'misc', 'the other: Miscellaneous')
end)

test('IsAutoVendorItem sells only from the selling category, and never a Protected or priceless item, whatever the rule', function()
	world('forever')
	local function sells(fields, protected)
		local info = put(fields, protected)
		return INV:IsAutoVendorItem(info), (INV:GetItemCategory(info))
	end
	local grey = fixture('a grey "Broken Fang"').item
	eq((sells(grey)), true, 'a grey in Grays/Auto Vendor sells')
	eq((sells(fixture('a soulbound robe with the red Classes: line').item)), true, 'so does the red Classes robe')
	eq((sells(fixture('"Lucky Rock"').item)), false, 'an item in Miscellaneous does not')
	eq(INV:IsAutoVendorItem(nil), false, 'no info')
	eq(INV:IsAutoVendorItem({ empty = true, vendorPrice = 10 }), false, 'an empty slot')
	local info = put(grey)
	eq(INV:IsAutoVendorItem(info, 'Miscellaneous'), false, 'the key given: another category')
	eq(INV:IsAutoVendorItem(info, 'Grays/Auto Vendor'), true, 'the key given: the selling category')
	info.category = 'Armor'
	eq(INV:IsAutoVendorItem(info), false, "info.category (ReadBags') is read when no key is given")

	-- Grays/Auto Vendor's rule catching everything grey: the guarantees still hold.
	set_store({ edits = { ['Grays/Auto Vendor'] = { rule = { op = 'or', items = { { block = 'quality', qualities = { 0 } } } } } } })
	local function held(fields, label, protected)
		local ok, k = sells(fields, protected)
		eq(k, 'Grays/Auto Vendor', label .. ': in Grays/Auto Vendor by the edited rule')
		eq(ok, false, label .. ': never sold')
	end
	held({ itemID = 5001, name = 'Kept Tooth', classID = 15, subclassID = 0, quality = 0 }, 'a Protected grey', true)
	held({ itemID = 5002, name = 'Free Tooth', classID = 15, subclassID = 0, quality = 0, vendorPrice = 0 }, 'a priceless grey')
	held({ itemID = 5003, name = 'Party Hat', classID = 4, subclassID = 5, equipLoc = 'INVTYPE_HEAD', quality = 0 },
		'grey Cosmetic armor')
	held({ itemID = 5004, name = 'Lure Box', classID = 15, subclassID = 0, quality = 0, tooltip = { 'Fishing' } },
		'a grey with "Fishing"')
	held({ itemID = 5005, name = 'Old Medal', classID = 15, subclassID = 0, quality = 0,
		tooltip = { 'Blizzard Account Bound' } }, 'a grey with "Blizzard Account Bound"')
	-- A set item: sets come first, so with sets off.
	set_store({ edits = { ['Grays/Auto Vendor'] = INV:CategoryStore().edits['Grays/Auto Vendor'],
		['Equipment sets'] = { enabled = false } } })
	held({ itemID = 5006, name = 'Grey Set Gloves', classID = 4, subclassID = 4, equipLoc = 'INVTYPE_HAND',
		quality = 0, set = 'Tank' }, 'a grey in an equipment set')
	eq((sells({ itemID = 5007, name = 'Grey Gloves', classID = 4, subclassID = 4, equipLoc = 'INVTYPE_HAND', quality = 0 })),
		true, 'the same grey out of any set sells')

	-- Pinned to Grays/Auto Vendor: the same.
	set_store({ edits = {} })
	INV.config.categoryPins = {
		[6001] = 'Grays/Auto Vendor', [6002] = 'Grays/Auto Vendor', [6003] = 'Grays/Auto Vendor',
		[6004] = 'Grays/Auto Vendor', [6005] = 'Grays/Auto Vendor', [6006] = 'Grays/Auto Vendor',
		[6007] = 'Grays/Auto Vendor',
	}
	held({ itemID = 6001, name = 'Pinned Kept Helm', classID = 4, subclassID = 4, equipLoc = 'INVTYPE_HEAD',
		reqLevel = 80, ilvl = 300 }, 'a pinned Protected helm', true)
	held({ itemID = 6002, name = 'Pinned Set Helm', classID = 4, subclassID = 4, equipLoc = 'INVTYPE_HEAD',
		reqLevel = 80, ilvl = 300, set = 'Tank' }, 'a pinned helm in an equipment set')
	held({ itemID = 6003, name = 'Pinned Hat', classID = 4, subclassID = 5, equipLoc = 'INVTYPE_HEAD' },
		'a pinned Cosmetic hat')
	held({ itemID = 6004, name = 'Pinned Pole', classID = 2, subclassID = 20, tooltip = { 'Fishing Pole' } },
		'a pinned item with "Fishing"')
	held({ itemID = 6005, name = 'Pinned Medal', classID = 15, subclassID = 4, tooltip = { 'Blizzard Account Bound' } },
		'a pinned account bound item')
	held({ itemID = 6006, name = 'Pinned Pebble', classID = 15, subclassID = 4, vendorPrice = 0 }, 'a pinned priceless item')
	eq((sells({ itemID = 6007, name = 'Pinned Pebble Two', classID = 15, subclassID = 4 })), true,
		'a pinned item past the guarantees sells')

	-- Only from the selling category, when it is on.
	INV.config.categoryPins = nil
	set_store({ edits = { ['Grays/Auto Vendor'] = { name = 'Junk' } } })
	eq((sells(grey)), true, 'renamed, it still sells')
	set_store({ edits = { ['Grays/Auto Vendor'] = { enabled = false } } })
	local ok, k = sells(grey)
	eq(k, 'Miscellaneous', 'turned off, a grey goes on down the list'); eq(ok, false, 'and nothing sells')
	eq(INV:IsAutoVendorItem(put(grey), 'Grays/Auto Vendor'), false, 'not even given its key')
	set_store({ edits = {}, custom = { ['custom:1'] = { name = 'Greys', enabled = true,
		rule = { op = 'or', items = { { block = 'quality', qualities = { 0 } } } } } },
		order = { 'custom:1', 'Equipment sets', 'Grays/Auto Vendor' } })
	ok, k = sells(grey)
	eq(k, 'custom:1', "a user's category before Grays takes the grey"); eq(ok, false, 'and it does not sell')
	eq(#take_errors(), 0, 'no errors')
end)

test('the list reads the store', function()
	world('forever')
	local defaults = ids(INV.CategoryDefaults.Build())
	-- A saved order: Weapons before Armor (Warbound), the user's category after
	-- it, Miscellaneous first, Toys missing, an id that does not exist, and
	-- Weapons twice.
	local order = {}
	for _, id in ipairs(defaults) do
		if id == 'Armor (Warbound)' then order[#order + 1] = 'Weapons'; order[#order + 1] = 'custom:1' end
		if id ~= 'Weapons' and id ~= 'Toys' and id ~= 'Miscellaneous' then order[#order + 1] = id end
	end
	table.insert(order, 1, 'Miscellaneous')
	order[#order + 1] = 'custom:7'
	order[#order + 1] = 'Weapons'
	set_store({
		order = order,
		custom = { ['custom:1'] = { name = 'Herbs', enabled = false, hide = { bank = true },
			rule = { op = 'or', items = { { block = 'subclass', class = 7, subclasses = { 9 } } } } } },
		deleted = { Anima = true, ['Grays/Auto Vendor'] = true, ['Equipment sets'] = true, Miscellaneous = true },
		edits = { Armor = { name = 'Gear', hide = { bag = true } }, Quest = { enabled = false } },
	})
	local list = INV:GetCategoryList()
	local got = table.concat(ids(list), ' | ')
	check(not got:find('Anima', 1, true), 'a deleted default is gone')
	check(not got:find('custom:7', 1, true), 'an id that does not exist is dropped')
	check(got:find('Weapons | custom:1 | Armor (Warbound)', 1, true), 'the saved order, with the user category')
	check(got:find('Container | Toys | Conduits', 1, true), 'Toys, missing from the order, after its predecessor (Anima is deleted)')
	check(got:find('^Equipment sets | Grays/Auto Vendor'), 'Equipment sets and Grays/Auto Vendor cannot be deleted')
	eq(list[#list].id, 'Miscellaneous', 'Miscellaneous last')
	local n = 0
	for _ in got:gmatch('Weapons') do n = n + 1 end
	eq(n, 1, 'each id once')
	eq(#list, 34, 'every default but Anima, and the user category')

	local herbs = list.byId['custom:1']
	eq(herbs.name, 'Herbs', 'a user category: its name'); eq(herbs.enabled, false, 'off')
	eq(herbs.hide.bank, true, 'its windows'); eq(herbs.kind, 'rule', 'a rule'); eq(herbs.default, false, 'not a default')
	eq(herbs.edited, false, 'never "edited"'); eq(herbs.sells, false, 'never sells')
	eq(herbs.place, list.byId.Weapons.place + 1, 'its place')
	local armor = list.byId.Armor
	eq(armor.name, 'Gear', 'a renamed default'); eq(armor.id, 'Armor', 'keeps its id'); eq(armor.edited, true, 'edited')
	eq(armor.hide.bag, true, 'its hide'); eq(armor.rule, INV:GetDefaultCategory('Armor').rule, 'and the default rule')
	eq(list.byId.Quest.enabled, false, 'a default turned off'); eq(list.byId.Quest.edited, true, 'is edited')
	eq(INV:CategoryName('Armor'), 'Gear', 'CategoryName: a list id is its name')
	eq(INV:CategoryName('Set: Tank'), 'Set: Tank', 'any other key is itself')
	eq(INV:CategoryPlace('Weapons'), list.byId.Weapons.place, "CategoryPlace: an id's place")
	eq(INV:CategoryPlace('Set: Tank'), 1, "a set: the sets entry's place")
	eq(INV:CategoryPlace('Anima'), nil, 'a deleted default has none')
	-- Herbs, its rule: herbs go there once it is on (it comes before Trade Goods).
	eq(key(fixture('a herb "Peacebloom" (7/9)').item), 'Trade Goods', 'off, it catches nothing')
	INV:CategoryStore().custom['custom:1'].enabled = true
	INV:CategoriesChanged()
	eq(key(fixture('a herb "Peacebloom" (7/9)').item), 'custom:1', 'on, it catches the herb')
	-- A rule edit replaces the default rule; an edit that is not a table rule matches nothing.
	INV:CategoryStore().edits.Keys = { rule = 'not a rule' }
	INV:CategoriesChanged()
	eq(key(fixture('"Skeleton Key" (class 13)').item), 'Miscellaneous', 'a rule that is not a table matches nothing')

	-- No order: the default order. Equipment sets missing from an order goes first.
	INV:CategoryStore().order = nil
	set_store({ custom = {}, deleted = {}, edits = {} })
	eq(table.concat(ids(INV:GetCategoryList()), ' | '), table.concat(defaults, ' | '), 'no order: the defaults in order')
	local noSets = {}
	for _, id in ipairs(defaults) do if id ~= 'Equipment sets' then noSets[#noSets + 1] = id end end
	set_store({ order = noSets })
	eq(INV:GetCategoryList()[1].id, 'Equipment sets', 'a default with none before it goes first')
	-- Another profile's store (a profile switch, copy or reset gives the bags
	-- a new table) is read at once, with no CategoriesChanged.
	local mine = INV.config.categories
	INV.config.categories = { edits = { Weapons = { name = 'Blades' } }, deleted = { Toys = true } }
	eq(INV:CategoryName('Weapons'), 'Blades', "another profile's store: its edits at once")
	eq(INV:CategoryPlace('Toys'), nil, 'and its deleted defaults')
	INV.config.categories = mine
	eq(INV:CategoryName('Weapons'), 'Weapons', 'and back')
	-- The store is made when missing, and read at call time.
	INV.config.categories = nil
	INV:CategoriesChanged()
	eq(#INV:GetCategoryList(), 34, 'no store: the defaults')
	local store = INV.config.categories
	check(type(store) == 'table' and type(store.edits) == 'table' and type(store.custom) == 'table'
		and type(store.deleted) == 'table' and store.nextId == 1, 'CategoryStore made it, with its sub-tables')
	-- CategoriesChanged queues a full update.
	INV.NEED_UPDATE, INV.UPDATE_LAYOUT = nil, nil
	INV:CategoriesChanged()
	eq(INV.NEED_UPDATE, true, 'an update'); eq(INV.UPDATE_LAYOUT, true, 'with the layout')
	eq(#take_errors(), 0, 'no errors')
end)

test('filters.lua is gone, and nothing reads INV.filters', function()
	eq(read_saftui_source('SaftUI-Bags/filters.lua'), nil, 'no filters.lua')
	local toc = read_saftui_source('SaftUI-Bags/SaftUI-Bags.toc')
	local files = {}
	for line in toc:gmatch('[^\n]+') do
		local file = line:match('^%s*([^#%s][^%s]*%.lua)%s*$')
		if file then files[#files + 1] = file:gsub('\\', '/') end
	end
	check(#files > 10, 'the TOC lists the files')
	local listed = table.concat(files, ',')
	check(not listed:find('filters.lua', 1, true), 'the TOC does not list filters.lua')
	check(listed:find('rules.lua,currencies.lua,categorydefaults.lua,categories.lua,tooltipscanner.lua,category.lua', 1, true),
		'the data files in the TOC, in order')
	for _, file in ipairs(files) do
		local source = read_saftui_source('SaftUI-Bags/' .. file)
		check(source ~= nil, file .. ' exists')
		if source then
			for _, word in ipairs({ 'INV.filters', 'self.filters', 'AddFilter', 'AUTO_VENDOR_CATEGORIES',
				'ItemRack', 'upgradeQualities', 'REAGENTBANK_CONTAINER' }) do
				check(not source:find(word, 1, true), file .. ' has no ' .. word)
			end
		end
	end
end)
