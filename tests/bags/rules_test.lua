-- The rule evaluator (SaftUI-Bags/rules.lua): AND/OR/NOT trees of blocks over
-- an item's info, the deciding node a match reports, the words that describe
-- it, and that rule data this version can't read matches nothing and never
-- errors. bags/bag_world.lua loads the real files, with the client's item
-- classes.
local W = load_test_file('bags/bag_world.lua')

local INV, R

local function world(client)
	INV = W.fresh(client)
	R = INV.Rules
	return INV
end

-- An item's info: the facts the blocks read, with the stripped and lowercased
-- text the way INV:GetInventoryItemInfo gives it.
local function info(fields)
	local i = { itemID = 1, quality = 1, ilvl = 1 }
	for k, v in pairs(fields or {}) do i[k] = v end
	if i.name then i.nameLower = i.name:lower(); i.nameStripped = R.Strip(i.name) end
	if i.tooltip then i.tooltipLower = i.tooltip:lower(); i.tooltipStripped = R.Strip(i.tooltip) end
	return i
end

local function blk(id, params, negate)
	local b = { block = id, negate = negate }
	for k, v in pairs(params or {}) do b[k] = v end
	return b
end

local function grp(op, items, negate) return { op = op, items = items, negate = negate } end

local function match(rule, i)
	local m, path = R.Compile(rule)(i)
	return m and true or false, path
end

local function p(path)
	if path == nil then return 'nil' end
	return '{' .. table.concat(path, ',') .. '}'
end

local function one(b, i)
	return (match(grp('or', { b }), i))
end

test('AND, OR and NOT', function()
	world()
	local yes, no = blk('reagent', { value = true }), blk('reagent', { value = false })
	local i = info({ isCraftingReagent = true })
	eq(match(grp('and', { yes, yes }), i), true, 'AND of two true')
	eq(match(grp('and', { yes, no }), i), false, 'AND with a false')
	eq(match(grp('or', { no, yes }), i), true, 'OR with a true')
	eq(match(grp('or', { no, no }), i), false, 'OR of two false')
	eq(match(grp('or', { blk('reagent', { value = true }, true) }), i), false, 'NOT block')
	eq(match(grp('or', { blk('reagent', { value = false }, true) }), i), true, 'NOT of a false block')
	eq(match(grp('and', { yes, no }, true), i), true, 'NOT group')
	eq(match(grp('or', { yes }, true), i), false, 'NOT of a true group')
end)

test('nested groups: x AND (y OR z)', function()
	world()
	local x = blk('quality', { qualities = { 3 } })
	local y = blk('class', { class = 4 })
	local z = blk('class', { class = 2 })
	local rule = grp('and', { x, grp('or', { y, z }) })
	eq(match(rule, info({ quality = 3, classID = 2 })), true, 'x and z')
	eq(match(rule, info({ quality = 3, classID = 4 })), true, 'x and y')
	eq(match(rule, info({ quality = 3, classID = 0 })), false, 'x only')
	eq(match(rule, info({ quality = 1, classID = 4 })), false, 'y only')
end)

test('unreadable groups match nothing, and a NOT never flips them', function()
	world()
	local real = blk('class', { class = 4 })
	local i, other = info({ classID = 4 }), info({ classID = 2 })
	eq(match(grp('and', {}), i), false, 'empty AND')
	eq(match(grp('or', {}), i), false, 'empty OR')
	eq(match(grp('and', {}, true), i), false, 'NOT empty AND')
	eq(match(grp('or', {}, true), i), false, 'NOT empty OR')
	eq(match(grp('or', { blk('tooltip', { text = '' }) }, true), i), false, 'NOT OR(empty tooltip)')
	eq(match(grp('or', { { block = 'future' } }, true), i), false, 'NOT OR(future block)')
	eq(match(grp('and', { { block = 'future' } }, true), i), false, 'NOT AND(future block)')
	eq(match(grp('or', { grp('and', {}, true) }, true), i), false, 'NOT of a group of unreadable groups')
	-- Unreadable children are skipped.
	local junk = blk('tooltip', { text = '' })
	local m, path = match(grp('or', { junk, real }), i)
	eq(m, true, 'OR(unreadable, X) is X'); eq(p(path), '{2}', 'with the real index')
	eq(match(grp('or', { junk, real }), other), false, 'OR(unreadable, X) false when X is')
	m, path = match(grp('and', { junk, real }), i)
	eq(m, true, 'AND(unreadable, X) is X'); eq(p(path), '{2}', 'with the real index')
	eq(match(grp('and', { junk, real }), other), false, 'AND(unreadable, X) false when X is')
	-- A NOT group of nothing readable inside an OR, beside a real block.
	local notEmpty = grp('or', { junk }, true)
	m, path = match(grp('or', { notEmpty, real }), i)
	eq(m, true, 'NOT group inside an OR next to a real block'); eq(p(path), '{2}', 'the real block decides')
	eq(match(grp('or', { notEmpty, real }), other), false, 'and does not catch what the real block does not')
	eq(match(grp('or', { notEmpty }), i), false, 'alone it catches nothing')
	-- The Grays shape: real AND NOT(empty tooltip block).
	local grays = grp('and', { real, grp('or', { junk }, true) })
	eq(match(grays, i), true, 'Grays-shaped: catches what the real block catches')
	eq(match(grays, other), false, 'Grays-shaped: and nothing else')
	-- A readable NOT group still flips.
	eq(match(grp('and', { real, grp('or', { blk('class', { class = 2 }) }, true) }), i), true, 'a readable NOT group flips')
	eq(match(grp('and', { real, grp('or', { blk('class', { class = 4 }) }, true) }), i), false, 'and excludes')
end)

test('tooltip and name: plain, case-insensitive, and whole word', function()
	world()
	local function tip(text, word, tooltip)
		return one(blk('tooltip', { text = text, word = word }), info({ tooltip = tooltip }))
	end
	local function nm(text, word, name)
		return one(blk('name', { text = text, word = word }), info({ name = name }))
	end
	eq(nm('Battle-Stone', nil, 'Flawless Battle-Stone'), true, 'Battle-Stone')
	eq(nm('battle-stone', nil, 'Flawless BATTLE-STONE'), true, 'any case')
	eq(nm('Battle-Stone', nil, 'Flawless Stone'), false, 'absent')
	eq(tip('100%', nil, 'Increases it by 100% for'), true, '100% is plain text')
	eq(tip('%d+', nil, 'Use: Grants 250 reputation'), false, 'a Lua pattern is plain text')
	eq(tip('Grants', nil, 'Use: Grants 250 reputation'), true, 'tooltip contains')
	eq(nm('Grants', nil, 'Use: Grants 250 reputation'), true, 'name contains')
	eq(tip('Curio', true, 'Combat Curio'), true, 'word at the end')
	eq(tip('Curio', true, 'Combat Curio.'), true, 'word before a period')
	eq(tip('Curio', true, 'Combat Curious'), false, 'not Curious')
	eq(tip('Curio', true, 'Curio'), true, 'the whole text')
	eq(nm('key', true, 'Rusty Key'), true, 'Rusty Key')
	eq(nm('key', true, 'Key-Ring'), true, 'Key-Ring')
	eq(nm('key', true, 'Keystone'), false, 'not Keystone')
	eq(nm('key', true, 'Monkey'), false, 'not Monkey')
	eq(nm('key', true, 'Monkey Key'), true, 'every occurrence is tried')
	eq(nm('', nil, 'Anything'), false, 'empty text matches nothing')
	eq(nm('.', nil, 'Anything'), false, 'text that strips to empty matches nothing')
	eq(nm('', true, 'Anything'), false, 'empty word matches nothing')
	eq(tip('Grants', nil, nil), false, 'no tooltip')
	eq(R.HasWord('rusty key', 'key'), true, 'HasWord')
	eq(R.HasWord('monkey', 'key'), false, 'HasWord inside a word')
	eq(R.HasWord('x', ''), false, 'HasWord of nothing')
	eq(R.Strip('Battle-Stone 100%'), 'battlestone 100 ', 'Strip')
end)

test('Name is: exact, any case', function()
	world()
	local b = blk('nameis', { text = 'Hearthstone' })
	eq(one(b, info({ name = 'Hearthstone' })), true, 'exact')
	eq(one(b, info({ name = 'HEARTHSTONE' })), true, 'any case')
	eq(one(blk('nameis', { text = 'HearthSTONE' }), info({ name = 'hearthstone' })), true, 'any case in the rule')
	eq(one(b, info({ name = 'Hearthstone of Doom' })), false, 'not a part')
	eq(one(blk('nameis', { text = '' }), info({ name = '' })), false, 'empty text')
end)

test('class and subclass by ID', function()
	world()
	local i = info({ classID = 4, subclassID = 2 })
	eq(one(blk('class', { class = 4 }), i), true, 'class')
	eq(one(blk('class', { class = 2 }), i), false, 'another class')
	eq(one(blk('subclass', { class = 4, subclasses = { 1, 2 } }), i), true, 'subclass in the list')
	eq(one(blk('subclass', { class = 4, subclasses = { 1, 3 } }), i), false, 'subclass not in the list')
	eq(one(blk('subclass', { class = 2, subclasses = { 2 } }), i), false, 'subclass of another class')
	eq(one(blk('subclass', { class = 4, subclasses = {} }), i), false, 'no subclasses')
	eq(one(blk('class', { class = 4 }), info()), false, 'no class on the item')
end)

test('quality', function()
	world()
	local b = blk('quality', { qualities = { 0, 4 } })
	eq(one(b, info({ quality = 0 })), true, 'poor')
	eq(one(b, info({ quality = 4 })), true, 'epic')
	eq(one(b, info({ quality = 2 })), false, 'uncommon')
	eq(one(blk('quality', { qualities = {} }), info({ quality = 2 })), false, 'none listed')
	eq(one(b, info({ quality = false })), false, 'no quality')
end)

test('item level and required level: at least, at most, between', function()
	world()
	for _, kind in ipairs({ { 'ilvl', 'ilvl' }, { 'reqlevel', 'reqLevel' } }) do
		local id, field = kind[1], kind[2]
		local function at(params, v) return one(blk(id, params), info({ [field] = v })) end
		eq(at({ min = 10 }, 10), true, id .. ' at least, equal')
		eq(at({ min = 10 }, 9), false, id .. ' at least, below')
		eq(at({ max = 10 }, 10), true, id .. ' at most, equal')
		eq(at({ max = 10 }, 11), false, id .. ' at most, above')
		eq(at({ min = 5, max = 10 }, 5), true, id .. ' between, low edge')
		eq(at({ min = 5, max = 10 }, 10), true, id .. ' between, high edge')
		eq(at({ min = 5, max = 10 }, 4), false, id .. ' between, below')
		eq(at({ min = 5, max = 10 }, 11), false, id .. ' between, above')
		eq(at({ min = 0 }, false), true, id .. ' a missing level counts as 0 for min 0')
		eq(at({ min = 1 }, false), false, id .. ' a missing level counts as 0')
		eq(at({ max = 3 }, false), true, id .. ' a missing level is under max')
	end
end)

test('equip slot', function()
	world()
	local b = blk('slot', { slots = { 'INVTYPE_HEAD', 'INVTYPE_CLOAK' } })
	eq(one(b, info({ equipLoc = 'INVTYPE_HEAD' })), true, 'head')
	eq(one(b, info({ equipLoc = 'INVTYPE_CLOAK' })), true, 'cloak')
	eq(one(b, info({ equipLoc = 'INVTYPE_FEET' })), false, 'feet')
	eq(one(b, info({ equipLoc = '' })), false, 'not equippable')
	eq(one(b, info()), false, 'no slot')
end)

test('binding: each state, and not bound', function()
	world()
	local function has(states, fields) return one(blk('binding', { states = states }), info(fields)) end
	eq(has({ 'soulbound' }, { isSoulbound = true }), true, 'soulbound')
	eq(has({ 'soulbound' }, {}), false, 'not soulbound')
	eq(has({ 'boe' }, { isBoE = true }), true, 'boe')
	eq(has({ 'boe' }, { isSoulbound = true }), false, 'not boe')
	eq(has({ 'warbound' }, { isWarbound = true }), true, 'warbound')
	eq(has({ 'warbound' }, {}), false, 'not warbound')
	eq(has({ 'none' }, {}), true, 'not bound')
	eq(has({ 'none' }, { isBoE = true }), false, 'boe is not "not bound"')
	eq(has({ 'none' }, { isSoulbound = true }), false, 'soulbound is not "not bound"')
	eq(has({ 'none' }, { isWarbound = true }), false, 'warbound is not "not bound"')
	eq(has({ 'boe', 'warbound' }, { isWarbound = true }), true, 'any listed state')
	eq(has({}, { isSoulbound = true }), false, 'none listed')
end)

test('expansion', function()
	world()
	local b = blk('expansion', { expansions = { 0, 9 } })
	eq(one(b, info({ expacID = 0 })), true, 'classic')
	eq(one(b, info({ expacID = 9 })), true, 'dragonflight')
	eq(one(b, info({ expacID = 3 })), false, 'another')
	eq(one(b, info()), false, 'no expansion')
end)

test('crafting reagent and vendor price: yes and no', function()
	world()
	local function r(v, f) return one(blk('reagent', { value = v }), info(f)) end
	eq(r(true, { isCraftingReagent = true }), true, 'reagent yes')
	eq(r(true, {}), false, 'not a reagent, yes')
	eq(r(false, {}), true, 'not a reagent, no')
	eq(r(false, { isCraftingReagent = true }), false, 'reagent, no')
	local function v(value, price) return one(blk('vendorprice', { value = value }), info({ vendorPrice = price })) end
	eq(v(true, 5), true, 'price yes')
	eq(v(true, 0), false, 'zero price, yes')
	eq(v(true, nil), false, 'no price, yes')
	eq(v(false, 0), true, 'zero price, no')
	eq(v(false, nil), true, 'no price, no')
	eq(v(false, 5), false, 'price, no')
end)

test('item is one of', function()
	world()
	local b = blk('items', { ids = { 6948, 5512 } })
	eq(one(b, info({ itemID = 6948 })), true, 'first')
	eq(one(b, info({ itemID = 5512 })), true, 'second')
	eq(one(b, info({ itemID = 1 })), false, 'other')
	eq(one(blk('items', { ids = {} }), info({ itemID = 1 })), false, 'empty list')
end)

test("old gear: today's thresholds, and edited ones", function()
	world()
	stub.level = 80
	_G.GetAverageItemLevel = function() return 300 end
	local good = { classID = 4, ilvl = 270, quality = 3, reqLevel = 60, expacID = 5, isWarbound = false,
		tooltip = 'Binds when picked up' }
	local function old(params, over)
		local f = {}
		for k, v in pairs(good) do f[k] = v end
		for k, v in pairs(over or {}) do f[k] = v end
		return one(blk('oldgear', params or R.BlockType('oldgear').new()), info(f))
	end
	local n = R.BlockType('oldgear').new()
	eq(n.levels, 10, 'new: levels'); eq(n.expansion, 9, 'new: expansion'); eq(n.share, 0.9, 'new: share')
	eq(old(), true, 'caught at 270 of 300')
	eq(old(nil, { ilvl = 271 }), false, '271 is not')
	eq(old({ levels = 10, expansion = 9, share = 0.5 }), false, 'a lower share moves the line')
	eq(old({ levels = 10, expansion = 9, share = 0.5 }, { ilvl = 150 }), true, 'and catches under it')
	eq(old(nil, { classID = 2 }), true, 'a weapon')
	eq(old(nil, { classID = 0 }), false, 'a consumable is not gear')
	eq(old(nil, { isWarbound = true }), false, 'warbound is not')
	eq(old(nil, { reqLevel = 70 }), true, 'exactly levels below')
	eq(old(nil, { reqLevel = 71 }), false, 'too close in level')
	eq(old({ levels = 5, expansion = 9, share = 0.9 }, { reqLevel = 71 }), true, 'an edited levels')
	eq(old(nil, { expacID = 9 }), true, 'expansion 9 is caught')
	eq(old(nil, { expacID = 10 }), false, 'expansion 10 is not')
	eq(old({ levels = 10, expansion = 4, share = 0.9 }), false, 'an edited expansion')
	eq(old(nil, { quality = 1 }), false, 'common is not')
	eq(old(nil, { quality = 2 }), true, 'uncommon')
	eq(old(nil, { quality = 4 }), true, 'epic')
	eq(old(nil, { quality = 5 }), false, 'legendary is not')
	eq(old(nil, { tooltip = 'You may trade this item with players' }), false, 'tradeable')
	eq(old(nil, { tooltip = 'Account Bound' }), false, 'account bound')
	eq(old(nil, { tooltip = 'Cosmetic' }), false, 'cosmetic')
	eq(old(nil, { tooltip = false }), true, 'no tooltip text')
	eq(old(nil, { reqLevel = false }), false, 'no required level')
	eq(old(nil, { expacID = false }), false, 'no expansion')
	eq(old(nil, { ilvl = false }), false, 'no item level')
end)

test('protected: the Protected list', function()
	world()
	INV.config.protectFilter = { [77] = true }
	eq(one(blk('protected'), info({ itemID = 77 })), true, 'on the list')
	eq(one(blk('protected'), info({ itemID = 78 })), false, 'not on it')
end)

test("the deciding node: OR's first match, AND's first non-negated child, nested", function()
	world()
	local t, f = blk('reagent', { value = true }), blk('reagent', { value = false })
	local i = info({ isCraftingReagent = true })
	local function path(rule) local m, pa = match(rule, i); return m and p(pa) or 'no match' end
	eq(path(grp('or', { f, t, t })), '{2}', 'OR: the first that matched')
	eq(path(grp('and', { t, t })), '{1}', 'AND: the first child')
	eq(path(grp('and', { blk('reagent', { value = false }, true), t })), '{2}', 'AND: skips a negated child')
	eq(path(grp('and', { blk('reagent', { value = false }, true), blk('reagent', { value = false }, true) })), '{}',
		'AND of only negated children decides itself')
	eq(path(grp('or', { f, grp('and', { f, t }), grp('or', { f, t }) })), '{3,2}', 'OR into a nested OR')
	eq(path(grp('or', { grp('and', { blk('reagent', { value = false }, true), t }) })), '{1,2}', 'nested AND')
	eq(path(grp('or', { f, grp('or', { f, t }, true) }) ), 'no match', 'NOT of a matching group: no match')
	eq(path(grp('or', { f, grp('or', { f }, true) })), '{2}', 'a negated group that matched decides itself')
	eq(path(grp('and', { grp('and', { t, t }) })), '{1,1}', 'AND into AND')
	eq(path(blk('reagent', { value = true })), '{}', 'a block root is its own node')
	eq(path(grp('and', { t }, true)), 'no match', 'negated and not matched')
	local m, pa = match(grp('or', { f }), i)
	eq(m, false, 'no match'); eq(pa, nil, 'and no path')
	eq(path(grp('and', { f }, true)), '{}', 'a negated root that matched decides itself')
	eq(path(grp('or', { grp('or', {}), t })), '{2}', 'an unreadable child is skipped in the path')
end)

test('Describe: every block type, NOT, and the group path', function()
	world()
	local IC = INV.ItemClasses
	local function d(b) return R.Describe(grp('or', { b }), { 1 }) end
	local armor = IC.ClassName(4)
	eq(d(blk('tooltip', { text = 'Use' })), 'Tooltip contains "Use"', 'tooltip')
	eq(d(blk('tooltip', { text = 'Use', word = true })), 'Tooltip contains "Use" (whole word)', 'tooltip word')
	eq(d(blk('name', { text = 'Key' })), 'Name contains "Key"', 'name')
	eq(d(blk('name', { text = 'Key', word = true })), 'Name contains "Key" (whole word)', 'name word')
	eq(d(blk('nameis', { text = 'Hearthstone' })), 'Name is "Hearthstone"', 'nameis')
	eq(d(blk('class', { class = 4 })), 'Class is ' .. armor, 'class')
	eq(d(blk('class', { class = 38 })), 'Class is class 38', 'class with no name')
	eq(d(blk('subclass', { class = 4, subclasses = { 1, 2 } })),
		'Subclass is ' .. IC.SubclassName(4, 1) .. ', ' .. IC.SubclassName(4, 2), 'subclass')
	eq(d(blk('quality', { qualities = { 2, 4 } })), 'Quality is Uncommon, Epic', 'quality')
	eq(d(blk('slot', { slots = { 'INVTYPE_HEAD', 'INVTYPE_CLOAK' } })),
		'Equip slot is ' .. (_G.INVTYPE_HEAD or 'INVTYPE_HEAD') .. ', ' .. (_G.INVTYPE_CLOAK or 'INVTYPE_CLOAK'), 'slot')
	eq(d(blk('binding', { states = { 'soulbound', 'none' } })), 'Binding is Soulbound, Not bound', 'binding')
	eq(d(blk('binding', { states = { 'boe', 'warbound' } })), 'Binding is Bind on equip, Warbound', 'binding 2')
	eq(d(blk('expansion', { expansions = { 0, 99 } })),
		'Expansion is ' .. R.ExpansionLabel(0) .. ', Expansion 99', 'expansion')
	eq(d(blk('ilvl', { min = 5 })), 'Item level at least 5', 'ilvl min')
	eq(d(blk('ilvl', { max = 9 })), 'Item level at most 9', 'ilvl max')
	eq(d(blk('ilvl', { min = 5, max = 9 })), 'Item level 5 to 9', 'ilvl between')
	eq(d(blk('reqlevel', { min = 5 })), 'Required level at least 5', 'req min')
	eq(d(blk('reqlevel', { max = 9 })), 'Required level at most 9', 'req max')
	eq(d(blk('reqlevel', { min = 5, max = 9 })), 'Required level 5 to 9', 'req between')
	eq(d(blk('reagent', { value = true })), 'Crafting reagent: yes', 'reagent yes')
	eq(d(blk('reagent', { value = false })), 'Crafting reagent: no', 'reagent no')
	eq(d(blk('vendorprice', { value = true })), 'Has vendor price: yes', 'price yes')
	eq(d(blk('vendorprice', { value = false })), 'Has vendor price: no', 'price no')
	eq(d(blk('items', { ids = { 1, 2, 3 } })), 'Item is one of 3 items', 'items')
	eq(d(blk('items', { ids = { 1 } })), 'Item is one of 1 item', 'one item')
	eq(d(blk('oldgear', {})), 'Old gear for my level', 'oldgear')
	eq(d(blk('protected')), 'Protected', 'protected')
	eq(d(blk('future')), 'Unknown block', 'unknown')
	eq(d(blk('protected', nil, true)), 'NOT Protected', 'NOT')
	eq(d(blk('future', nil, true)), 'NOT Unknown block', 'NOT unknown')
	-- The group path.
	local x = blk('protected')
	local rule = grp('or', { x, grp('or', { x, grp('and', { x, x }) }), grp('and', { x }, true) })
	eq(R.Describe(rule, { 1 }), 'Protected', 'a child of the root')
	eq(R.Describe(rule, { 2, 1 }), 'Protected (in OR #2)', 'one group deep')
	eq(R.Describe(rule, { 2, 2, 2 }), 'Protected (in OR #2 > AND #2)', 'two groups deep')
	eq(R.Describe(rule, {}), 'its rule as a whole', 'the root')
	eq(R.Describe(rule, { 2 }), 'OR #2', 'a nested group')
	eq(R.Describe(rule, { 2, 2 }), 'AND #2 (in OR #2)', 'a nested group with a parent')
	eq(R.Describe(rule, { 3 }), 'NOT AND #3', 'a negated nested group')
	eq(R.Describe(rule, { 9 }), '', 'no such node')
	eq(R.Describe(rule, nil), '', 'no path')
end)

test('tree helpers and labels', function()
	world()
	local a = grp('or', { blk('items', { ids = { 1, 2 } }), grp('and', { blk('protected') }) })
	local b = R.Copy(a)
	eq(R.Equal(a, b), true, 'a copy is equal')
	check(a ~= b and a.items ~= b.items and a.items[1].ids ~= b.items[1].ids, 'and deep')
	b.items[1].ids[2] = 3
	eq(R.Equal(a, b), false, 'a change shows')
	eq(a.items[1].ids[2], 2, 'and leaves the original')
	eq(R.Equal(1, 1), true, 'numbers'); eq(R.Equal(1, '1'), false, 'types')
	eq(R.Equal({}, { x = 1 }), false, 'extra key'); eq(R.Equal({ x = 1 }, {}), false, 'missing key')
	eq(R.NodeAt(a, {}), a, 'NodeAt root')
	eq(R.NodeAt(a, { 2, 1 }), a.items[2].items[1], 'NodeAt nested')
	eq(R.NodeAt(a, { 5 }), nil, 'NodeAt missing')
	eq(R.NodeAt(a, { 1, 1 }), nil, 'NodeAt into a block')
	eq(R.NodeAt(nil, {}), nil, 'NodeAt of nothing')
	eq(R.QUALITY_LABELS[0], 'Poor', 'poor'); eq(R.QUALITY_LABELS[7], 'Heirloom', 'heirloom')
	eq(#R.BINDING_STATES, 4, 'binding states'); eq(R.BINDING_STATES[4][2], 'Not bound', 'not bound')
	eq(R.SLOTS[1][1] ~= nil and R.SLOTS[1][2] ~= nil, true, 'slots are { token, label }')
	local ids = {}
	for i, t in ipairs(R.BLOCKS) do ids[i] = t.id; eq(type(t.label), 'string', t.id .. ' label'); eq(type(t.new()), 'table', t.id .. ' new') end
	eq(table.concat(ids, ','),
		'tooltip,name,nameis,class,subclass,quality,ilvl,reqlevel,slot,binding,expansion,reagent,vendorprice,items,oldgear,protected',
		'the block picker order')
	eq(R.BlockType('ilvl').label, 'Item level', 'BlockType'); eq(R.BlockType('nope'), nil, 'unknown BlockType')
	_G.EXPANSION_NAME3 = 'Wrath'
	eq(R.ExpansionLabel(3), 'Wrath', 'a named expansion'); eq(R.ExpansionLabel(98), 'Expansion 98', 'unnamed')
	R.BlockType('quality').new().qualities[1] = 5
	eq(#R.BlockType('quality').new().qualities, 0, 'new makes fresh params')
end)

test('unknown block types and malformed params match nothing and never error', function()
	world()
	local i = info({ name = 'Thing', tooltip = 'Some text', classID = 4, subclassID = 1, quality = 3, ilvl = 10,
		isCraftingReagent = true, itemID = 5, equipLoc = 'INVTYPE_HEAD', expacID = 1, reqLevel = 5, vendorPrice = 3 })
	local bad = {
		{ block = 'future' },
		{ block = 'future', negate = true },
		{ block = 'tooltip' },
		{ block = 'tooltip', text = 5 },
		{ block = 'tooltip', text = 'x', negate = true },
		{ block = 'name' }, { block = 'nameis' }, { block = 'nameis', text = {} },
		{ block = 'class', class = 'x' }, { block = 'class' },
		{ block = 'subclass', class = 4 }, { block = 'subclass', subclasses = { 1 } },
		{ block = 'subclass', class = 4, subclasses = 'x' },
		{ block = 'quality' }, { block = 'quality', qualities = 3 },
		{ block = 'ilvl' }, { block = 'ilvl', min = 'x' }, { block = 'reqlevel', max = {} },
		{ block = 'slot', slots = 'INVTYPE_HEAD' }, { block = 'binding', states = true },
		{ block = 'expansion' }, { block = 'reagent' }, { block = 'reagent', value = 'yes' },
		{ block = 'vendorprice', value = 1 }, { block = 'items' }, { block = 'items', ids = 5 },
		{ block = 'oldgear', levels = 'x', expansion = 9, share = 0.9 },
		{ block = 'oldgear', levels = 10, expansion = 9 },
		{ block = 5 }, { block = {} }, {}, 'a string', 5, true,
		{ op = 'xor', items = { blk('protected') } },
		{ op = 'xor', items = {}, negate = true },
		{ op = 'and' }, { op = 'or', items = 'x' }, { op = 'and', items = 5, negate = true },
		{ op = 5, items = {} },
	}
	for n, rule in ipairs(bad) do
		for _, root in ipairs({ grp('or', { rule }), grp('and', { rule }), rule }) do
			local ok, m, path = pcall(function() return R.Compile(root)(i) end)
			check(ok, 'case ' .. n .. ' errors: ' .. tostring(m))
			eq(m and true or false, false, 'case ' .. n .. ' matches nothing')
			eq(path, nil, 'case ' .. n .. ' has no path')
		end
		local ok, text = pcall(R.Describe, grp('or', { rule }), { 1 })
		check(ok, 'Describe of case ' .. n .. ' errors: ' .. tostring(text))
		eq(type(text), 'string', 'Describe of case ' .. n)
	end
	-- Unknown beside known blocks doesn't spoil them.
	eq(match(grp('or', { { block = 'future' }, blk('class', { class = 4 }) }), i), true, 'OR still finds the good one')
	eq(match(grp('and', { { block = 'future' }, blk('class', { class = 4 }) }), i), true, 'AND skips the unknown one')
	-- Rules that aren't rules.
	for _, rule in ipairs({ 'x', 5, true, false }) do
		eq(R.Compile(rule)(i) and true or false, false, 'a ' .. type(rule) .. ' as a rule')
	end
	eq(R.Compile(nil)(i) and true or false, false, 'R.Compile(nil)')
	eq(R.Compile(grp('or', { blk('protected') }))(nil) and true or false, false, 'no info')
	eq(R.Describe(nil, {}), '', 'Describe of nothing')
	eq(R.Describe('x', { 1 }), '', 'Describe of a string')
	eq(R.NodeAt('x', {}), nil, 'NodeAt of a string')
	eq(R.Copy(nil), nil, 'Copy of nil'); eq(R.Copy(5), 5, 'Copy of a number')
end)

test('evaluating strips no text', function()
	world()
	local blocks = {}
	for n = 1, 20 do
		blocks[n] = (n % 2 == 0) and blk('tooltip', { text = 'Word' .. n, word = n % 4 == 0 })
			or blk('name', { text = 'Name-' .. n })
	end
	local rule = grp('or', blocks)
	local i = info({ name = 'Something Plain', tooltip = 'A tooltip with 100% nothing' })
	local calls = 0
	-- rules.lua captures strlower when it loads, so the wrapper goes in first
	-- and the file loads again over it.
	local unmagic, lower = string.unmagic, _G.strlower
	string.unmagic = function(...) calls = calls + 1; return unmagic(...) end
	_G.strlower = function(...) calls = calls + 1; return lower(...) end
	load_saftui('SaftUI-Bags/rules.lua')
	R = INV.Rules
	local fn = R.Compile(rule) -- compiling may strip the needles
	check(calls > 0, 'the wrapper sees compile-time strips')
	calls = 0
	for _ = 1, 3 do fn(i) end
	eq(calls, 0, 'no strips while evaluating')
	local m = fn(i)
	eq(m and true or false, false, 'and no match')
end)
