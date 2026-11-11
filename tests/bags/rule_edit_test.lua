-- The rule tree's edits and its outline (SaftUI-Bags/rules.lua), which the
-- outline rule editor (ruleeditor.lua) works through: new nodes (NewBlock,
-- NewGroup), Insert, Remove, Move, Flip and ToggleNot at a path, R.Outline's
-- rows and R.DropAt's drop spots. Pure: plain tables in and out.
-- bags/bag_world.lua loads the real files.
local BW = load_test_file('bags/bag_world.lua')
local INV = BW.fresh()
local R = INV.Rules

local function blk(id, params, negate)
	local b = { block = id, negate = negate }
	for k, v in pairs(params or {}) do b[k] = v end
	return b
end

-- A tooltip block named by its text, so a shape reads it.
local function t(text) return blk('tooltip', { text = text }) end

local function grp(op, items, negate) return { op = op, items = items, negate = negate } end

local function p(path)
	if path == nil then return 'nil' end
	return '{' .. table.concat(path, ',') .. '}'
end

-- A rule as text: AND(a,OR(b,c)), a block by its text (else its type), ! for NOT.
local function shape(node)
	if type(node) ~= 'table' then return tostring(node) end
	local neg = node.negate == true and '!' or ''
	if node.op ~= nil then
		local parts = {}
		for i = 1, #(node.items or {}) do parts[i] = shape(node.items[i]) end
		return neg .. tostring(node.op):upper() .. '(' .. table.concat(parts, ',') .. ')'
	end
	return neg .. tostring(node.text or node.block)
end

------------------------------------------------------------------ edits

test('Insert, Remove, Flip and ToggleNot at a path', function()
	local rule = grp('and', { t('a'), grp('or', { t('b') }) })

	check(R.Insert(rule, {}, 2, t('x')), 'insert at the root')
	eq(shape(rule), 'AND(a,x,OR(b))', 'before the second item')
	check(R.Insert(rule, { 3 }, 1, t('y')), 'insert first in a nested group')
	eq(shape(rule), 'AND(a,x,OR(y,b))', 'first in it')
	check(R.Insert(rule, { 3 }, 3, t('z')), "insert at a group's end")
	eq(shape(rule), 'AND(a,x,OR(y,b,z))', 'at its end')
	check(R.Insert(rule, {}, nil, t('w')), 'no index is the end')
	eq(shape(rule), 'AND(a,x,OR(y,b,z),w)', 'at the end')
	check(not R.Insert(rule, { 1 }, 1, t('q')), 'not into a block')
	check(not R.Insert(rule, {}, 9, t('q')), 'not past the end')
	check(not R.Insert(rule, {}, 0, t('q')), 'not before the start')
	check(not R.Insert(rule, { 9 }, 1, t('q')), 'not into nothing')
	eq(shape(rule), 'AND(a,x,OR(y,b,z),w)', 'a refused insert changes nothing')

	local removed = R.Remove(rule, { 3, 2 })
	eq(removed and removed.text, 'b', 'Remove returns the node')
	eq(shape(rule), 'AND(a,x,OR(y,z),w)', 'and takes it out')
	eq(shape(R.Remove(rule, { 3 })), 'OR(y,z)', 'a group goes with its children')
	eq(shape(rule), 'AND(a,x,w)', 'gone')
	eq(R.Remove(rule, {}), nil, 'the root is never removed')
	eq(R.Remove(rule, { 9 }), nil, 'nothing there')
	eq(R.Remove(rule, { 1, 1 }), nil, 'nothing inside a block')
	eq(shape(rule), 'AND(a,x,w)', 'a refused remove changes nothing')

	rule = grp('and', { t('a'), grp('or', { t('b') }) })
	check(R.Flip(rule, { 2 }), 'flip a nested group')
	eq(rule.items[2].op, 'and', 'OR becomes AND')
	check(R.Flip(rule, { 2 }), 'and back')
	eq(rule.items[2].op, 'or', 'AND becomes OR')
	check(R.Flip(rule, {}), 'flip the root')
	eq(rule.op, 'or', 'the root flips')
	check(not R.Flip(rule, { 1 }), 'a block has no operator')
	check(not R.Flip(rule, { 9 }), 'nothing there')

	check(R.ToggleNot(rule, { 1 }), 'NOT on a block')
	eq(rule.items[1].negate, true, 'negated')
	check(R.ToggleNot(rule, { 1 }), 'NOT again')
	eq(rule.items[1].negate, nil, 'off is nil, not false')
	check(R.ToggleNot(rule, { 2 }), 'NOT on a group')
	eq(rule.items[2].negate, true, 'the group is negated')
	check(not R.ToggleNot(rule, {}), 'never on the root')
	eq(rule.negate, nil, 'the root stays plain')
	check(not R.ToggleNot(rule, { 9 }), 'nothing there')
end)

test('NewGroup takes the other operator; NewBlock gives each type its new params', function()
	local g = R.NewGroup('and')
	eq(g.op, 'or', 'under AND, an OR')
	eq(type(g.items), 'table', 'with items')
	eq(#g.items, 0, 'none yet')
	eq(g.negate, nil, 'not negated')
	eq(R.NewGroup('or').op, 'and', 'under OR, an AND')
	check(R.NewGroup('and').items ~= R.NewGroup('and').items, 'a new table each time')

	for _, type_ in ipairs(R.BLOCKS) do
		local b = R.NewBlock(type_.id)
		local want = type_.new()
		want.block = type_.id
		check(R.Equal(b, want), type_.id .. ': its type and its new params')
	end
	check(R.Equal(R.NewBlock('tooltip'), { block = 'tooltip', text = '' }), 'tooltip: empty text')
	check(R.Equal(R.NewBlock('class'), { block = 'class' }), 'class: none picked')
	check(R.Equal(R.NewBlock('subclass'), { block = 'subclass', subclasses = {} }), 'subclass: none picked')
	check(R.Equal(R.NewBlock('ilvl'), { block = 'ilvl', min = 0 }), 'ilvl: at least 0')
	check(R.Equal(R.NewBlock('reagent'), { block = 'reagent', value = true }), 'reagent: yes')
	check(R.Equal(R.NewBlock('oldgear'), { block = 'oldgear', levels = 10, expansion = 9, share = 0.9 }),
		"oldgear: today's thresholds")
	check(R.Equal(R.NewBlock('protected'), { block = 'protected' }), 'protected: no params')
	check(R.NewBlock('items').ids ~= R.NewBlock('items').ids, 'fresh tables each time')
	eq(R.NewBlock('nope'), nil, 'no block of an unknown type')
end)

test('Move within a group, between groups and into an empty group, never into itself', function()
	local function rule() return grp('and', { t('a'), grp('or', { t('b'), t('c') }), t('d'), grp('and', {}) }) end
	local before = shape(rule())
	eq(before, 'AND(a,OR(b,c),d,AND())', 'the rule')

	local r = rule()
	check(R.Move(r, { 1 }, {}, 4), 'down within a group')
	eq(shape(r), 'AND(OR(b,c),d,a,AND())', 'a after d')
	r = rule()
	check(R.Move(r, { 3 }, {}, 1), 'up within a group')
	eq(shape(r), 'AND(d,a,OR(b,c),AND())', 'd first')
	r = rule()
	check(R.Move(r, { 3 }, { 2 }, 1), 'into another group')
	eq(shape(r), 'AND(a,OR(d,b,c),AND())', 'd first in the OR')
	r = rule()
	check(R.Move(r, { 1 }, { 2 }, 3), 'into a group after it, whose index shifts')
	eq(shape(r), 'AND(OR(b,c,a),d,AND())', "a at the OR's end")
	r = rule()
	check(R.Move(r, { 2, 2 }, {}, 5), 'out of a group')
	eq(shape(r), 'AND(a,OR(b),d,AND(),c)', "c at the root's end")
	r = rule()
	check(R.Move(r, { 1 }, { 4 }, 1), 'into an empty group')
	eq(shape(r), 'AND(OR(b,c),d,AND(a))', 'a in it')
	r = rule()
	check(R.Move(r, { 2 }, { 4 }, 1), 'a group, with its children')
	eq(shape(r), 'AND(a,d,AND(OR(b,c)))', 'the OR in the AND')

	r = rule()
	check(not R.Move(r, { 2 }, { 2 }, 1), 'not into itself')
	check(not R.Move(r, { 1 }, {}, 1), 'not to just before itself')
	check(not R.Move(r, { 1 }, {}, 2), 'not to just after itself')
	check(not R.Move(r, {}, {}, 1), 'not the root')
	check(not R.Move(r, { 9 }, {}, 1), 'not a node that is not there')
	check(not R.Move(r, { 1 }, { 3 }, 1), 'not into a block')
	check(not R.Move(r, { 1 }, { 9 }, 1), 'not into nothing')
	check(not R.Move(r, { 1 }, {}, 9), 'not past the end')
	check(not R.Move(r, { 1 }, {}, 0), 'not before the start')
	eq(shape(r), before, 'a refused move changes nothing')
	r = grp('and', { grp('or', { grp('and', { t('x') }) }) })
	check(not R.Move(r, { 1 }, { 1, 1 }, 1), 'not into its own subtree')
	eq(shape(r), 'AND(OR(AND(x)))', 'unchanged')
end)

------------------------------------------------------------------ the outline

test('Outline: rows in order with their depths, group title rows and add rows', function()
	local rule = grp('and', { t('a'), grp('or', { t('b'), grp('and', {}, true) }), t('c') })
	local rows = R.Outline(rule)
	local got = {}
	for i, row in ipairs(rows) do
		got[i] = row.kind .. p(row.path) .. 'd' .. row.depth .. ':' .. row.op
	end
	eq(table.concat(got, ' '), table.concat({
		'block{1}d0:and',
		'group{2}d0:and',
		'block{2,1}d1:or',
		'group{2,2}d1:or',
		'add{2,2}d2:and',
		'add{2}d1:or',
		'block{3}d0:and',
		'add{}d0:and',
	}, ' '), 'each row: its kind, path, depth and the operator of the group it hangs off')
	check(rows[1].node == rule.items[1], "a block row's node is the block")
	check(rows[2].node == rule.items[2], "a group title row's node is the group")
	check(rows[6].node == rule.items[2], "an add row's node is its group")
	check(rows[8].node == rule, "the root's add row's node is the root")
	check(rows[2].path ~= rows[6].path, 'each row has its own path table')

	-- Nodes that aren't a readable group are rows of their own, never opened.
	local odd = grp('or', { 'garbage', blk('future', { x = 1 }), { op = 'xor', items = { t('e') } }, { op = 'and' } })
	rows = R.Outline(odd)
	got = {}
	for i, row in ipairs(rows) do got[i] = row.kind .. p(row.path) end
	eq(table.concat(got, ' '), 'block{1} block{2} block{3} block{4} add{}', 'unreadable nodes are block rows')

	eq(#R.Outline(nil), 0, 'a rule that is not a table has no rows')
	eq(#R.Outline({ op = 'xor', items = {} }), 0, 'nor does a root of an unknown operator')
	eq(#R.Outline(grp('and', {})), 1, 'an empty rule is its add row')
end)

test("DropAt: before or after a block, first in a group, at a group's end", function()
	local rule = grp('and', { t('a'), grp('or', { t('b'), grp('and', {}) }), t('c') })
	local rows = R.Outline(rule)
	-- 1 a, 2 OR title, 3 b, 4 AND title, 5 AND's add, 6 OR's add, 7 c, 8 root's add.
	local function drop(i, lower)
		local parent, index = R.DropAt(rows, i, lower)
		return p(parent) .. '#' .. tostring(index)
	end
	eq(drop(1, false), '{}#1', 'upper half of a block: before it')
	eq(drop(1, true), '{}#2', 'lower half of a block: after it')
	eq(drop(2, false), '{}#2', 'upper half of a group title: before the group')
	eq(drop(2, true), '{2}#1', 'lower half of a group title: first in it')
	eq(drop(3, true), '{2}#2', 'after a block in a group')
	eq(drop(4, true), '{2,2}#1', 'first in an empty group')
	eq(drop(5, false), '{2,2}#1', "an empty group's add row: its end")
	eq(drop(6, false), '{2}#3', "an add row's upper half: its group's end")
	eq(drop(6, true), '{2}#3', 'and its lower half too')
	eq(drop(8, true), '{}#4', "the root's add row: the root's end")
	eq(R.DropAt(rows, 99, false), nil, 'no row, no drop')

	local parent = R.DropAt(rows, 3, false)
	parent[1] = 7
	eq(p(rows[3].path), '{2,1}', "the path given is a copy, not the row's")

	-- A drag of c over b's upper half puts it first in the OR.
	local to, index = R.DropAt(rows, 3, false)
	check(R.Move(rule, rows[7].path, to, index), 'the move')
	eq(shape(rule), 'AND(a,OR(c,b,AND()))', 'c before b')
end)
