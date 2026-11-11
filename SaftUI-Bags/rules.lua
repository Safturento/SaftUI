local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The category rule evaluator. A rule is a tree of plain tables:

	  group = { op = 'and' | 'or', negate = true | nil, items = { node, ... } }
	  block = { block = '<type id>', negate = true | nil, ...params }

	  R.Compile(rule)       -> fn(info) -> matched, path   (path: the deciding node's)
	  R.Describe(rule, path) -> string
	  R.BLOCKS, R.BlockType(id)
	  R.Strip(s), R.HasWord(lowerSubject, lowerWord)
	  R.Copy, R.Equal, R.NodeAt, R.IsGroup(node)
	  R.QUALITY_LABELS, R.BINDING_STATES, R.SLOTS, R.ExpansionLabel(n)

	The outline editor's side (ruleeditor.lua), at the end:
	  R.NewBlock(typeId), R.NewGroup(parentOp)
	  R.Insert, R.Remove, R.Move, R.Flip, R.ToggleNot   edits in place, by path
	  R.Outline(rule) -> rows, R.DropAt(rows, i, lower) -> parentPath, index

	Compiling turns the tree into closures, strips the needles and builds the
	sets once. Evaluating reads the item's facts (see INV:GetInventoryItemInfo)
	and strips nothing. A block of an unknown type, with missing or wrongly typed
	params, a group of an unknown op or with no items table, or a rule that isn't
	a table is UNREADABLE: it matches nothing, negated or not, and never errors.
	A group with no readable child (empty, or all unreadable) is unreadable too.
	A parent skips its unreadable children when it decides, so OR(unreadable, X)
	and AND(unreadable, X) are X, and NOT never turns "can't read" into "matches
	everything" (an editor mid-edit makes these: a new NOT group, a block before
	its text is typed). At the root, unreadable matches nothing.
]]
local R = {}
INV.Rules = R

local strlower, strfind, strsub = strlower, string.find, string.sub

local function is_num(v) return type(v) == 'number' and v == v end

-------------------------------------------------------------------- text

-- Core's string.unmagic turns % into a space and drops ^ $ ( ) . [ ] * + - ?.
function R.Strip(s)
	return strlower(string.unmagic(s))
end

-- A plain find of lowerWord in lowerSubject at a place where the characters
-- around it aren't letters (or are the ends). Every occurrence is tried.
function R.HasWord(subject, word)
	if type(subject) ~= 'string' or type(word) ~= 'string' or word == '' then return false end
	local len = #word
	local from = 1
	while true do
		local s = strfind(subject, word, from, true)
		if not s then return false end
		local before = s > 1 and strsub(subject, s - 1, s - 1) or ''
		local after = strsub(subject, s + len, s + len)
		if not strfind(before, '^%a') and not strfind(after, '^%a') then return true end
		from = s + 1
	end
end

------------------------------------------------------------------- labels

R.QUALITY_LABELS = { [0] = 'Poor', 'Common', 'Uncommon', 'Rare', 'Epic', 'Legendary', 'Artifact', 'Heirloom' }

R.BINDING_STATES = {
	{ 'soulbound', 'Soulbound' },
	{ 'boe', 'Bind on equip' },
	{ 'warbound', 'Warbound' },
	{ 'none', 'Not bound' },
}

R.SLOTS = {}
for _, token in ipairs({
	'INVTYPE_HEAD', 'INVTYPE_NECK', 'INVTYPE_SHOULDER', 'INVTYPE_BODY', 'INVTYPE_CHEST', 'INVTYPE_ROBE',
	'INVTYPE_WAIST', 'INVTYPE_LEGS', 'INVTYPE_FEET', 'INVTYPE_WRIST', 'INVTYPE_HAND', 'INVTYPE_FINGER',
	'INVTYPE_TRINKET', 'INVTYPE_CLOAK', 'INVTYPE_WEAPON', 'INVTYPE_2HWEAPON', 'INVTYPE_WEAPONMAINHAND',
	'INVTYPE_WEAPONOFFHAND', 'INVTYPE_SHIELD', 'INVTYPE_HOLDABLE', 'INVTYPE_RANGED', 'INVTYPE_RANGEDRIGHT',
	'INVTYPE_THROWN', 'INVTYPE_RELIC', 'INVTYPE_TABARD', 'INVTYPE_BAG',
}) do
	R.SLOTS[#R.SLOTS + 1] = { token, type(_G[token]) == 'string' and _G[token] or token }
end

function R.ExpansionLabel(n)
	local label = _G['EXPANSION_NAME' .. tostring(n)]
	if type(label) == 'string' and label ~= '' then return label end
	return 'Expansion ' .. tostring(n)
end

local function slot_label(token)
	local label = type(token) == 'string' and _G[token]
	return type(label) == 'string' and label or tostring(token)
end

local function binding_label(state)
	for _, pair in ipairs(R.BINDING_STATES) do
		if pair[1] == state then return pair[2] end
	end
	return tostring(state)
end

local function quality_label(q) return R.QUALITY_LABELS[q] or tostring(q) end

--------------------------------------------------------------- tree helpers

function R.Copy(node)
	if type(node) ~= 'table' then return node end
	local out = {}
	for k, v in pairs(node) do out[k] = R.Copy(v) end
	return out
end

function R.Equal(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for k, v in pairs(a) do
		if not R.Equal(v, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

function R.NodeAt(rule, path)
	local node = rule
	if type(node) ~= 'table' or type(path) ~= 'table' then return nil end
	for _, index in ipairs(path) do
		if type(node.items) ~= 'table' or node.block ~= nil then return nil end
		node = node.items[index]
		if type(node) ~= 'table' then return nil end
	end
	return node
end

-- A group this version can read: an AND or OR with an items table.
function R.IsGroup(node)
	return type(node) == 'table' and node.block == nil and (node.op == 'and' or node.op == 'or')
		and type(node.items) == 'table'
end

------------------------------------------------------------------- blocks

-- The numbers (or strings) of an array, as a set; nil when it isn't an array.
local function set_of(list, kind)
	if type(list) ~= 'table' then return nil end
	local set = {}
	for _, v in ipairs(list) do
		if type(v) == kind and v == v then set[v] = true end
	end
	return set
end

local function count_of(list)
	local n = 0
	if type(list) == 'table' then
		for _, v in ipairs(list) do if is_num(v) then n = n + 1 end end
	end
	return n
end

local function text_of(node)
	return type(node.text) == 'string' and node.text or ''
end

-- Each compiler takes the node and returns matcher(info) -> bool, or nil when
-- the node's params can't be read.
local compilers = {}
-- Each describer takes the node and returns its words.
local describers = {}

local function text_block(strippedField, lowerField)
	return function(node)
		local text = node.text
		if type(text) ~= 'string' then return nil end
		local needle = R.Strip(text)
		if needle == '' then return nil end
		if node.word == true then
			local word = strlower(text)
			return function(info) return R.HasWord(info[lowerField], word) end
		end
		return function(info)
			local subject = info[strippedField]
			return type(subject) == 'string' and strfind(subject, needle, 1, true) ~= nil
		end
	end
end

compilers.tooltip = text_block('tooltipStripped', 'tooltipLower')
compilers.name = text_block('nameStripped', 'nameLower')

local function contains(label)
	return function(node)
		return label .. ' contains "' .. text_of(node) .. '"' .. (node.word == true and ' (whole word)' or '')
	end
end
describers.tooltip = contains('Tooltip')
describers.name = contains('Name')

function compilers.nameis(node)
	if type(node.text) ~= 'string' or node.text == '' then return nil end
	local want = strlower(node.text)
	return function(info) return info.nameLower == want end
end
describers.nameis = function(node) return 'Name is "' .. text_of(node) .. '"' end

function compilers.class(node)
	local class = node.class
	if not is_num(class) then return nil end
	return function(info) return info.classID == class end
end
describers.class = function(node)
	local name = is_num(node.class) and INV.ItemClasses.ClassName(node.class)
	if name then return 'Class is ' .. name end
	return 'Class is class ' .. tostring(node.class)
end

function compilers.subclass(node)
	local class, set = node.class, set_of(node.subclasses, 'number')
	if not is_num(class) or not set then return nil end
	return function(info) return info.classID == class and set[info.subclassID] == true end
end
describers.subclass = function(node)
	local names = {}
	if type(node.subclasses) == 'table' then
		for _, id in ipairs(node.subclasses) do
			names[#names + 1] = (is_num(node.class) and INV.ItemClasses.SubclassName(node.class, id)) or ('subclass ' .. tostring(id))
		end
	end
	return 'Subclass is ' .. table.concat(names, ', ')
end

local function list_block(param, kind, field)
	return function(node)
		local set = set_of(node[param], kind)
		if not set then return nil end
		return function(info)
			local v = info[field]
			return v ~= nil and set[v] == true
		end
	end
end

local function list_words(prefix, param, label)
	return function(node)
		local out = {}
		if type(node[param]) == 'table' then
			for _, v in ipairs(node[param]) do out[#out + 1] = label(v) end
		end
		return prefix .. table.concat(out, ', ')
	end
end

compilers.quality = list_block('qualities', 'number', 'quality')
describers.quality = list_words('Quality is ', 'qualities', quality_label)

compilers.slot = list_block('slots', 'string', 'equipLoc')
describers.slot = list_words('Equip slot is ', 'slots', slot_label)

compilers.expansion = list_block('expansions', 'number', 'expacID')
describers.expansion = list_words('Expansion is ', 'expansions', R.ExpansionLabel)

compilers.items = list_block('ids', 'number', 'itemID')
describers.items = function(node)
	local n = count_of(node.ids)
	return 'Item is one of ' .. n .. (n == 1 and ' item' or ' items')
end

local function level_block(field)
	return function(node)
		local min, max = node.min, node.max
		if (min ~= nil and not is_num(min)) or (max ~= nil and not is_num(max)) or (min == nil and max == nil) then
			return nil
		end
		return function(info)
			local v = info[field]
			if not is_num(v) then v = 0 end
			return (min == nil or v >= min) and (max == nil or v <= max)
		end
	end
end

local function level_words(label)
	return function(node)
		local min, max = node.min, node.max
		if min ~= nil and max ~= nil then return label .. ' ' .. tostring(min) .. ' to ' .. tostring(max) end
		if min ~= nil then return label .. ' at least ' .. tostring(min) end
		if max ~= nil then return label .. ' at most ' .. tostring(max) end
		return label
	end
end

compilers.ilvl = level_block('ilvl')
describers.ilvl = level_words('Item level')
compilers.reqlevel = level_block('reqLevel')
describers.reqlevel = level_words('Required level')

function compilers.binding(node)
	local set = set_of(node.states, 'string')
	if not set then return nil end
	return function(info)
		if set.soulbound and info.isSoulbound then return true end
		if set.boe and info.isBoE then return true end
		if set.warbound and info.isWarbound then return true end
		return set.none == true and not (info.isSoulbound or info.isBoE or info.isWarbound)
	end
end
describers.binding = list_words('Binding is ', 'states', binding_label)

function compilers.reagent(node)
	local want = node.value
	if type(want) ~= 'boolean' then return nil end
	return function(info) return (info.isCraftingReagent and true or false) == want end
end
describers.reagent = function(node) return 'Crafting reagent: ' .. (node.value == true and 'yes' or 'no') end

function compilers.vendorprice(node)
	local want = node.value
	if type(want) ~= 'boolean' then return nil end
	return function(info) return ((info.vendorPrice or 0) > 0) == want end
end
describers.vendorprice = function(node) return 'Has vendor price: ' .. (node.value == true and 'yes' or 'no') end

-- Today's isLegacyGear, with the thresholds from the block.
local OLD_GEAR_TOOLTIP = { 'you may trade this item with players', 'account bound', 'cosmetic' }

function compilers.oldgear(node)
	local levels, expansion, share = node.levels, node.expansion, node.share
	if not (is_num(levels) and is_num(expansion) and is_num(share)) then return nil end
	return function(info)
		if not INV.ItemClasses.IsGear(info) or info.isWarbound then return false end
		local req, expac, ilvl, quality = info.reqLevel, info.expacID, info.ilvl, info.quality
		if not (is_num(req) and is_num(expac) and is_num(ilvl) and is_num(quality)) then return false end
		if quality < 2 or quality > 4 then return false end
		if expac > expansion then return false end
		if (UnitLevel('player') or 0) - req < levels then return false end
		local average = type(GetAverageItemLevel) == 'function' and GetAverageItemLevel()
		if not is_num(average) or ilvl > average * share then return false end
		local tooltip = info.tooltipStripped
		if type(tooltip) == 'string' then
			for _, text in ipairs(OLD_GEAR_TOOLTIP) do
				if strfind(tooltip, text, 1, true) then return false end
			end
		end
		return true
	end
end
describers.oldgear = function() return 'Old gear for my level' end

compilers.protected = function()
	return function(info)
		return info.itemID ~= nil and INV.IsProtected ~= nil and INV:IsProtected(info.itemID) and true or false
	end
end
describers.protected = function() return 'Protected' end

R.BLOCKS = {
	{ id = 'tooltip', label = 'Tooltip contains', new = function() return { text = '' } end },
	{ id = 'name', label = 'Name contains', new = function() return { text = '' } end },
	{ id = 'nameis', label = 'Name is', new = function() return { text = '' } end },
	{ id = 'class', label = 'Class is', new = function() return {} end },
	{ id = 'subclass', label = 'Subclass is', new = function() return { subclasses = {} } end },
	{ id = 'quality', label = 'Quality is', new = function() return { qualities = {} } end },
	{ id = 'ilvl', label = 'Item level', new = function() return { min = 0 } end },
	{ id = 'reqlevel', label = 'Required level', new = function() return { min = 0 } end },
	{ id = 'slot', label = 'Equip slot is', new = function() return { slots = {} } end },
	{ id = 'binding', label = 'Binding is', new = function() return { states = {} } end },
	{ id = 'expansion', label = 'Expansion is', new = function() return { expansions = {} } end },
	{ id = 'reagent', label = 'Crafting reagent', new = function() return { value = true } end },
	{ id = 'vendorprice', label = 'Has vendor price', new = function() return { value = true } end },
	{ id = 'items', label = 'Item is one of', new = function() return { ids = {} } end },
	{ id = 'oldgear', label = 'Old gear for my level',
		new = function() return { levels = 10, expansion = 9, share = 0.9 } end },
	{ id = 'protected', label = 'Protected', new = function() return {} end },
}

local by_id = {}
for _, t in ipairs(R.BLOCKS) do by_id[t.id] = t end

function R.BlockType(id)
	return by_id[id]
end

----------------------------------------------------------------- compiling

local function never() return false end

local function prefix(index, path)
	local out = { index }
	for i = 1, #path do out[i + 1] = path[i] end
	return out
end

local compile_node

-- Returns fn, readable. An unreadable node (see the header) is never() and
-- its parent skips it.
local function compile_group(node)
	local op = node.op
	local items = node.items
	if (op ~= 'and' and op ~= 'or') or type(items) ~= 'table' then return never, false end
	local fns, index = {}, {} -- the readable children, and where each sits in items
	local firstPlain -- AND: the first readable child that isn't negated
	for i = 1, #items do
		local fn, readable = compile_node(items[i])
		if readable then
			fns[#fns + 1], index[#fns + 1] = fn, i
			if not firstPlain and items[i].negate ~= true then firstPlain = #fns end
		end
	end
	local n = #fns
	if n == 0 then return never, false end
	local negate = node.negate == true
	local isOr = op == 'or'
	return function(info)
		local matched, path = false, nil
		if isOr then
			for k = 1, n do
				local m, p = fns[k](info)
				if m then matched, path = true, prefix(index[k], p); break end
			end
		else
			matched = true
			local decided
			for k = 1, n do
				local m, p = fns[k](info)
				if not m then matched = false; break end
				if k == firstPlain then decided = p end
			end
			if matched then path = firstPlain and prefix(index[firstPlain], decided) or {} end
		end
		if negate then
			if matched then return false, nil end
			return true, {}
		end
		return matched, path
	end, true
end

local function compile_block(node)
	local type_ = node.block
	local compiler = type(type_) == 'string' and compilers[type_]
	local matcher = compiler and compiler(node)
	if not matcher then return never, false end
	local negate = node.negate == true
	return function(info)
		local m = matcher(info) and true or false
		if negate then m = not m end
		return m, m and {} or nil
	end, true
end

function compile_node(node)
	if type(node) ~= 'table' then return never, false end
	if node.op ~= nil then return compile_group(node) end
	if node.block ~= nil then return compile_block(node) end
	return never, false
end

function R.Compile(rule)
	local fn = compile_node(rule)
	return function(info)
		if type(info) ~= 'table' then return false, nil end
		return fn(info)
	end
end

----------------------------------------------------------------- describing

-- ' (in OR #1 > AND #2)': the groups above the node at path[1..depth], outermost first.
local function groups_suffix(rule, path, depth)
	local names = {}
	for j = 1, depth - 1 do
		local prefixPath = {}
		for k = 1, j do prefixPath[k] = path[k] end
		local group = R.NodeAt(rule, prefixPath)
		local op = type(group) == 'table' and group.op
		names[#names + 1] = (type(op) == 'string' and op:upper() or '?') .. ' #' .. tostring(path[j])
	end
	if #names == 0 then return '' end
	return ' (in ' .. table.concat(names, ' > ') .. ')'
end

function R.Describe(rule, path)
	if type(path) ~= 'table' then return '' end
	local node = R.NodeAt(rule, path)
	if not node then return '' end
	local negated = node.negate == true and 'NOT ' or ''
	local depth = #path
	if node.block ~= nil then
		local describer = type(node.block) == 'string' and describers[node.block]
		local words = describer and describer(node) or 'Unknown block'
		return negated .. words .. groups_suffix(rule, path, depth)
	end
	if depth == 0 then return negated .. 'its rule as a whole' end
	local op = type(node.op) == 'string' and node.op:upper() or '?'
	return negated .. op .. ' #' .. tostring(path[depth]) .. groups_suffix(rule, path, depth)
end

------------------------------------------------------------------- editing

--[[
	What the outline editor (ruleeditor.lua) works through. The edits change
	the rule they're given, in place: the editor hands them a copy (R.Copy) of
	the stored rule and sets the copy, since the stored rule can be the shipped
	default's own table. Each returns whether it changed anything (Remove the
	node it took out), and a refused edit changes nothing.
]]

local tinsert, tremove = table.insert, table.remove

local function copy_path(path)
	local out = {}
	for i = 1, #path do out[i] = path[i] end
	return out
end

-- The path's parent's path and its index there.
local function split(path)
	local parent = copy_path(path)
	local index = tremove(parent)
	return parent, index
end

-- Whether path starts with (or is) prefix.
local function starts_with(path, prefix)
	if #path < #prefix then return false end
	for i = 1, #prefix do
		if path[i] ~= prefix[i] then return false end
	end
	return true
end

-- A new block of the type: { block = typeId, <its new params> }, or nil.
function R.NewBlock(typeId)
	local type_ = by_id[typeId]
	if not type_ then return nil end
	local node = type_.new()
	node.block = typeId
	return node
end

-- A new empty group under a parent of parentOp: the other operator, as a
-- group of the same one would change nothing.
function R.NewGroup(parentOp)
	return { op = parentOp == 'and' and 'or' or 'and', items = {} }
end

-- node into the group at parentPath, at index (its end when nil).
function R.Insert(rule, parentPath, index, node)
	local parent = R.NodeAt(rule, parentPath)
	if not R.IsGroup(parent) or node == nil then return false end
	local n = #parent.items
	if index == nil then index = n + 1 end
	if type(index) ~= 'number' or index < 1 or index > n + 1 then return false end
	tinsert(parent.items, index, node)
	return true
end

-- Takes the node at path out of its group and returns it; never the root.
function R.Remove(rule, path)
	if type(path) ~= 'table' or #path == 0 then return nil end
	local parentPath, index = split(path)
	local parent = R.NodeAt(rule, parentPath)
	if not R.IsGroup(parent) or type(index) ~= 'number' or index < 1 or index > #parent.items then return nil end
	return tremove(parent.items, index)
end

-- Moves the node at fromPath to index in the group at toParentPath, both
-- read before the move (so a drop spot from R.DropAt works as it is). Refused
-- for the root, a move into the node itself or its own subtree, and a move
-- to where it already is (just before or just after itself).
function R.Move(rule, fromPath, toParentPath, toIndex)
	if type(fromPath) ~= 'table' or #fromPath == 0 or type(toParentPath) ~= 'table' then return false end
	local fromParentPath, fromIndex = split(fromPath)
	local fromParent = R.NodeAt(rule, fromParentPath)
	if not R.IsGroup(fromParent) or type(fromIndex) ~= 'number' or fromIndex < 1 or fromIndex > #fromParent.items then
		return false
	end
	if starts_with(toParentPath, fromPath) then return false end
	local toParent = R.NodeAt(rule, toParentPath)
	if not R.IsGroup(toParent) then return false end
	if type(toIndex) ~= 'number' or toIndex < 1 or toIndex > #toParent.items + 1 then return false end
	if toParent == fromParent and (toIndex == fromIndex or toIndex == fromIndex + 1) then return false end
	-- The groups are held as tables, so taking the node out first can't shift them.
	local node = tremove(fromParent.items, fromIndex)
	if toParent == fromParent and toIndex > fromIndex then toIndex = toIndex - 1 end
	tinsert(toParent.items, toIndex, node)
	return true
end

-- AND to OR and back, for the group at path.
function R.Flip(rule, path)
	local node = R.NodeAt(rule, path)
	if not R.IsGroup(node) then return false end
	node.op = node.op == 'and' and 'or' or 'and'
	return true
end

-- NOT on and off (negate true or nil) for the node at path; never the root.
function R.ToggleNot(rule, path)
	if type(path) ~= 'table' or #path == 0 then return false end
	local node = R.NodeAt(rule, path)
	if type(node) ~= 'table' then return false end
	node.negate = node.negate ~= true or nil
	return true
end

--[[
	The outline: the rows the editor draws, in order. Each is
	  { kind = 'block' | 'group' | 'add', path, depth, node, op }
	A group inside the root has a title row (kind 'group', its path), then its
	rows; every group, the root too, ends with an add row (its path, its node
	the group). depth counts the groups between the root and the row (the
	root's own rows are 0), and op is the operator of the group whose line the
	row hangs off: the parent's for a block or a title, the group's own for an
	add row. A node that isn't a readable group (R.IsGroup) is a block row
	whatever it holds, so data this version can't read is a row the editor
	can show and remove. A rule that isn't a readable group has no rows.
]]
function R.Outline(rule)
	local rows = {}
	if not R.IsGroup(rule) then return rows end
	local function walk(group, path, depth)
		for i = 1, #group.items do
			local node = group.items[i]
			local nodePath = copy_path(path)
			nodePath[#nodePath + 1] = i
			if R.IsGroup(node) then
				rows[#rows + 1] = { kind = 'group', path = nodePath, depth = depth, node = node, op = group.op }
				walk(node, nodePath, depth + 1)
			else
				rows[#rows + 1] = { kind = 'block', path = nodePath, depth = depth, node = node, op = group.op }
			end
		end
		rows[#rows + 1] = { kind = 'add', path = copy_path(path), depth = depth, node = group, op = group.op }
	end
	walk(rule, {}, 0)
	return rows
end

-- Where a node dropped over rows[i] goes: the group's path and the index in
-- it (as R.Move takes them), or nil. lower is the row's lower half.
--   - the upper half of a block or group title row: before it;
--   - the lower half of a block row: after it;
--   - the lower half of a group title row: first in that group;
--   - an add row: at its group's end.
function R.DropAt(rows, i, lower)
	local row = rows[i]
	if not row then return nil end
	if row.kind == 'add' then return copy_path(row.path), #row.node.items + 1 end
	if row.kind == 'group' and lower then return copy_path(row.path), 1 end
	local parentPath, index = split(row.path)
	if lower then index = index + 1 end
	return parentPath, index
end
