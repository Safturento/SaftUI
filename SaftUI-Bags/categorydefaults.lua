local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The default categories: the hard-coded filters of earlier versions, as
	block rules (see rules.lua), in their order, after the Equipment sets entry
	and before Miscellaneous. Each catches exactly what its filter caught on an
	English client, except the changes the bag categories plan lists (Delves'
	"Curio" is a whole word now, so "Curious" is not Delves).

	Class and subclass blocks name their class in English here, and Build
	resolves the names against this client's item classes (INV.ItemClasses):
	  { block = 'class', className = 'Armor' }         one class block per ID,
	                                                   OR'ed in a group when several
	  { block = 'class', classEnum = 'Battlepet' }     Enum.ItemClass[key], with the
	                                                   IDs INV:GetInventoryItemInfo
	                                                   gives keystones and caged pets
	  { block = 'subclass', subclassNames = { ... } }  one subclass block per class
	                                                   the names resolve in, OR'ed
	                                                   when several
	A name that resolves to nothing is simplified so the rule still matches
	what the name test matched: in an OR it is dropped; negated inside an AND
	it is dropped; plain inside an AND it makes that AND match nothing (and so
	on up). A root left with nothing is an empty group, which matches nothing.
	A block that comes out twice in one OR is kept once.

	  CD.Build()       -> the entries, in order, resolved for this client and
	                      cached: { id, name, enabled, hide, rule, kind
	                      ('sets' | 'rule' | 'misc'), sells, default = true }.
	                      Shared: read them, never change them.
	  CD.Resolve(rule) -> a rule with its names resolved (what Build does to each)
	  CD.Reset()       drops the cache
]]
local CD = {}
INV.CategoryDefaults = CD

local R = INV.Rules
local IC = INV.ItemClasses

-------------------------------------------------------------------- notation

local function AND(...) return { op = 'and', items = { ... } } end
local function OR(...) return { op = 'or', items = { ... } } end
local function NOT(node) node.negate = true return node end
local function tooltip(text, word) return { block = 'tooltip', text = text, word = word } end
local function name(text, word) return { block = 'name', text = text, word = word } end
local function nameis(text) return { block = 'nameis', text = text } end
local function class(className) return { block = 'class', className = className } end
local function classEnum(key) return { block = 'class', classEnum = key } end
local function subclass(...) return { block = 'subclass', subclassNames = { ... } } end
local function items(ids) return { block = 'items', ids = ids } end

local ARCHAEOLOGY = {
	-- keystones
	52843, 63127, 63128, 64392, 64394, 64395, 64396, 64397, 154990, 154989, 79868, 79869, 95373, 108439,
	109584, 109585, 130904, 130905, 130903,
	-- fragment crates
	87399, 87533, 87534, 87535, 87536, 87537, 87538, 87539, 87540, 87541, 117386, 117387, 117388,
	142113, 142114, 142115, 164625, 164626, 164627, 183834, 183835,
}

local DEFAULTS = {
	{ id = 'Equipment sets', kind = 'sets' },
	{ id = 'Grays/Auto Vendor', sells = true, rule = AND(
		OR(
			{ block = 'quality', qualities = { 0 } },
			{ block = 'oldgear', levels = 10, expansion = 9, share = 0.9 },
			AND({ block = 'binding', states = { 'soulbound' } }, tooltip('cffff2020Classes:'))
		),
		-- A lot of special holiday stuff is Cosmetic, fishing or account
		-- bound, and is never sold.
		NOT({ block = 'protected' }),
		NOT(subclass('Cosmetic')),
		NOT(tooltip('Fishing')),
		NOT(tooltip('Blizzard Account Bound')),
		{ block = 'vendorprice', value = true }
	) },
	{ id = 'Rogue/DK/Mage/Druid', rule = OR(tooltip('Rogue, Death Knight, Mage, Druid')) },
	{ id = 'Warrior/Hunter/Shaman', rule = OR(tooltip('Warrior, Hunter, Shaman')) },
	{ id = 'Paladin/Priest/Warlock', rule = OR(tooltip('Paladin, Priest, Warlock')) },
	{ id = 'Warrior/Rogue/Monk', rule = OR(tooltip('Warrior, Rogue, Monk')) },
	{ id = 'Hunter/Mage/Druid', rule = OR(tooltip('Hunter, Mage, Druid')) },
	{ id = 'Paladin/Priest/Shaman', rule = OR(tooltip('Paladin, Priest, Shaman')) },
	{ id = 'Death Knight/Warlock/Demon Hunter', rule = OR(tooltip('Death Knight, Warlock, Demon Hunter')) },
	{ id = 'Secrets of Azeroth', rule = OR(tooltip('Secrets of Azeroth')) },
	-- Was the pattern "Use: Grants ([,%d]+) reputation".
	{ id = 'Reputation', rule = AND(tooltip('Use: Grants '), tooltip(' reputation')) },
	{ id = 'Delves', rule = OR(tooltip('Curio', true), nameis("Delver's Bounty"), nameis("Trovehunter's Bounty")) },
	{ id = 'Container', rule = AND(
		OR(tooltip('Right Click to Open'), tooltip('Open the container'), tooltip('Open the sack'),
			tooltip('Use: collect'), tooltip('Use: Open'), tooltip('Flightstones')),
		NOT(class('Armor')),
		NOT(class('Weapon'))
	) },
	{ id = 'Toys', rule = OR(tooltip('Adds this toy to your Toy Box')) },
	{ id = 'Anima', rule = OR(tooltip("stored Anima into your covenant's Reservoir")) },
	{ id = 'Conduits', rule = OR(tooltip('Add this Conduit to your collection')) },
	{ id = 'Blueprints', rule = OR(name('Blueprint: ')) },
	{ id = 'Pets', rule = OR(name('Battle-Stone'), name('Battle-Training Stone'), subclass('Companion Pets'),
		classEnum('Battlepet')) },
	{ id = 'Housing', rule = OR(class('Housing')) },
	{ id = 'Mounts', rule = OR(subclass('Mount')) },
	{ id = 'Flasks/Potions/Food', rule = OR(subclass('Flasks & Phials', 'Potions', 'Food & Drink')) },
	{ id = 'Gems/Enchants', rule = OR(class('Gem'), subclass('Item Enhancement')) },
	{ id = 'Consumables', rule = OR(class('Consumable')) },
	{ id = 'Armor (Warbound)', rule = AND(class('Armor'), { block = 'binding', states = { 'warbound' } }) },
	{ id = 'Armor', rule = OR(class('Armor')) },
	{ id = 'Weapons', rule = OR(class('Weapon')) },
	{ id = 'Archaeology', rule = OR(items(ARCHAEOLOGY), tooltip('Carefully crate the restored artifact')) },
	-- 191784: Dragon Shard of Knowledge.
	{ id = 'Professions/Recipes', rule = OR(items({ 191784 }), tooltip('Use: Study to increase your'), class('Recipe')) },
	{ id = 'Emerald Dream', rule = OR(name('dreamseed'), name('dreamsurge')) },
	{ id = 'Trade Goods', rule = OR(class('Trade Goods'), class('Gem'), class('Tradeskill')) },
	{ id = 'Devices', rule = OR(subclass('Devices')) },
	{ id = 'Quest', rule = OR(class('Quest')) },
	{ id = 'Keys', rule = OR(class('Key'), name('key', true)) },
	{ id = 'Miscellaneous', kind = 'misc' },
}

------------------------------------------------------------------- resolving

-- What INV:GetInventoryItemInfo gives a keystone and a caged pet on a client
-- with no Enum.ItemClass.
local ENUM_FALLBACK = { Key = 13, Battlepet = 17 }

-- A node that resolves to nothing: it matches nothing (NOTHING), or, negated,
-- everything (EVERYTHING).
local NOTHING, EVERYTHING = {}, {}

local function sorted_keys(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys)
	return keys
end

-- The class or subclass blocks a named block stands for on this client.
local function named_blocks(node)
	local blocks = {}
	if node.block == 'class' then
		local ids = {}
		if node.classEnum ~= nil then
			local id = (Enum.ItemClass and Enum.ItemClass[node.classEnum]) or ENUM_FALLBACK[node.classEnum]
			if id then ids[id] = true end
		else
			ids = IC.ClassIDs(node.className)
		end
		for _, id in ipairs(sorted_keys(ids)) do blocks[#blocks + 1] = { block = 'class', class = id } end
	else
		local byClass = {}
		for _, subName in ipairs(node.subclassNames) do
			for classID, subIDs in pairs(IC.SubclassIDs(subName)) do
				byClass[classID] = byClass[classID] or {}
				for _, id in ipairs(subIDs) do byClass[classID][id] = true end
			end
		end
		for _, classID in ipairs(sorted_keys(byClass)) do
			blocks[#blocks + 1] = { block = 'subclass', class = classID, subclasses = sorted_keys(byClass[classID]) }
		end
	end
	return blocks
end

local function is_named(node)
	return node.className ~= nil or node.classEnum ~= nil or node.subclassNames ~= nil
end

local function flip(result, negate)
	if not negate then return result end
	return result == NOTHING and EVERYTHING or NOTHING
end

local function resolve(node)
	if node.op == nil then
		if not is_named(node) then return R.Copy(node) end
		local blocks = named_blocks(node)
		if #blocks == 0 then return flip(NOTHING, node.negate) end
		local out = #blocks == 1 and blocks[1] or { op = 'or', items = blocks }
		out.negate = node.negate
		return out
	end

	local isOr = node.op == 'or'
	if #node.items == 0 then return R.Copy(node) end
	local out = {}
	for _, child in ipairs(node.items) do
		local r = resolve(child)
		if r == (isOr and EVERYTHING or NOTHING) then
			-- OR(everything, ...) and AND(nothing, ...) are decided.
			return flip(r, node.negate)
		elseif r ~= (isOr and NOTHING or EVERYTHING) then
			local seen = false
			if isOr then
				for _, kept in ipairs(out) do
					if R.Equal(kept, r) then seen = true break end
				end
			end
			if not seen then out[#out + 1] = r end
		end
	end
	if #out == 0 then
		-- Every child dropped: an OR of nothing, or an AND of everything.
		return flip(isOr and NOTHING or EVERYTHING, node.negate)
	end
	return { op = node.op, negate = node.negate, items = out }
end

-- A root that resolves to nothing, or (no default does) to everything, is an
-- empty group: it matches nothing.
function CD.Resolve(rule)
	local out = resolve(rule)
	if out == NOTHING or out == EVERYTHING then return { op = rule.op, items = {} } end
	return out
end

local cache

function CD.Build()
	if cache then return cache end
	local entries = {}
	for _, def in ipairs(DEFAULTS) do
		local kind = def.kind or 'rule'
		entries[#entries + 1] = {
			id = def.id,
			name = def.id,
			enabled = true,
			hide = {},
			rule = kind == 'rule' and CD.Resolve(def.rule) or nil,
			kind = kind,
			sells = def.sells == true,
			default = true,
		}
	end
	cache = entries
	return entries
end

function CD.Reset()
	cache = nil
end
