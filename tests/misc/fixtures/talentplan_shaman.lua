--[[
	The shaman talent tree as names, for the talent plan's parser: the 20 talents
	of the owner's Enhancement guide and three decoys. Node IDs and max ranks are
	fixture data. Load it with `local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')`;
	SH.NAMES is the list TP.Parse takes ({ name, nodeID, maxRanks }) and SH.ID[name]
	a name's node ID.

	SH.install(opts) fills stub.traits (tests/wow/traits.lua) with this tree:
	config 1001 for spec group 1 and tree 501, holding the 23 nodes, each visible,
	purchasable and with one entry, plus a choice node (130, two entries) and an
	invisible one (131), which the talent plan's reader skips. opts.ranks[name] = n
	sets a node's ranksPurchased; opts.second = true adds config 1002 for group 2
	(the same tree, no ranks). It returns SH.world = { configID, treeID, second }.
]]
local SH = { NAMES = {}, ID = {} }

local list = {
	{ 'Thundering Strikes', 5 }, { 'Mental Dexterity', 3 }, { 'Ancestral Knowledge', 5 },
	{ 'Shamanistic Focus', 1 }, { 'Elemental Weapons', 3 },
	{ 'Stormstrike', 1 }, { 'Improved Ghost Wolf', 2 }, { 'Flurry', 5 },
	{ 'Improved Stormstrike', 2 }, { 'Mental Quickness', 3 },
	{ 'Spirit Weapons', 1 }, { 'Maelstrom Weapon', 5 }, { 'Tidal Focus', 5 },
	{ 'Mindfulness', 3 }, { 'Concussion', 5 },
	{ 'Call of Flame', 3 }, { 'Elemental Devastation', 3 }, { 'Elemental Focus', 1 },
	{ 'Reverberation', 5 }, { 'Trial by Fire', 3 },
	-- decoys
	{ 'Improved Lightning Shield', 3 }, { "Nature's Guardian", 5 }, { 'Totemic Focus', 5 },
}

for i, t in ipairs(list) do
	SH.NAMES[i] = { name = t[1], nodeID = 100 + i, maxRanks = t[2] }
	SH.ID[t[1]] = 100 + i
end

local CONFIG, TREE, SECOND = 1001, 501, 1002

local function node_info(nodeID, maxRanks, entryIDs, ranks, visible)
	return { ID = nodeID, entryIDs = entryIDs, entryIDsWithCommittedRanks = {}, canPurchaseRank = true,
		canRefundRank = false, isAvailable = true, isVisible = visible, ranksPurchased = ranks or 0,
		maxRanks = maxRanks, meetsEdgeRequirements = true, conditionIDs = {}, groupIDs = {} }
end

function SH.install(opts)
	opts = opts or {}
	stub.reset_traits()
	local tr = stub.traits
	tr.group_configs[1] = CONFIG
	tr.configs[CONFIG] = { treeIDs = { TREE } }
	tr.trees[TREE] = {}
	tr.nodes[CONFIG] = {}
	local function add(nodeID, name, maxRanks, ranks, visible, entryCount)
		local entryIDs = {}
		for e = 1, entryCount or 1 do
			local entryID = 1000 * e + nodeID
			entryIDs[e] = entryID
			tr.entries[entryID] = { definitionID = entryID + 1000000, maxRanks = maxRanks, type = 1 }
			tr.definitions[entryID + 1000000] = { spellID = entryID + 2000000 }
			tr.spells[entryID + 2000000] = { name = name, icon = 134000 + nodeID }
		end
		table.insert(tr.trees[TREE], nodeID)
		tr.nodes[CONFIG][nodeID] = node_info(nodeID, maxRanks, entryIDs, ranks, visible)
	end
	for _, n in ipairs(SH.NAMES) do
		add(n.nodeID, n.name, n.maxRanks, opts.ranks and opts.ranks[n.name], true)
	end
	add(130, 'Ancestral Swiftness', 1, 0, true, 2)
	add(131, 'Hidden Node', 1, 0, false)
	if opts.second then
		tr.group_configs[2] = SECOND
		tr.configs[SECOND] = { treeIDs = { TREE } }
		tr.nodes[SECOND] = {}
		for nodeID, info in pairs(tr.nodes[CONFIG]) do
			local copy = {}
			for k, v in pairs(info) do copy[k] = v end
			copy.ranksPurchased = 0
			tr.nodes[SECOND][nodeID] = copy
		end
	end
	SH.world = { configID = CONFIG, treeID = TREE, second = opts.second and SECOND or nil }
	return SH.world
end

return SH
