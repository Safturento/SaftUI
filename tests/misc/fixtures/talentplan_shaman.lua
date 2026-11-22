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

	opts.shape = true gives the tree the shape the planning rules read: three
	groups (SH.GROUP: Elemental 701, Enhancement 702, Restoration 703, in that
	order), the nodes spread over them (Enhancement 101 to 115, Elemental 116 to
	121, Restoration 122 and 123), five to a row (posY 2130, 2730, 3330: Forever's 600 apart), a gate on
	each row after the first (isGate, spentAmountRequired 5 per row above, a
	condition of the node), two prerequisite edges, fixture data (Spirit
	Weapons to Stormstrike, Stormstrike to Improved Stormstrike, type 3), and
	the choice node 130 (group 703) as the parent of Totemic Focus.
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
SH.GROUP = { Elemental = 701, Enhancement = 702, Restoration = 703 }

local function node_info(nodeID, maxRanks, entryIDs, ranks, visible)
	return { ID = nodeID, entryIDs = entryIDs, entryIDsWithCommittedRanks = {}, canPurchaseRank = true,
		canRefundRank = false, isAvailable = true, isVisible = visible, ranksPurchased = ranks or 0,
		maxRanks = maxRanks, meetsEdgeRequirements = true, conditionIDs = {}, groupIDs = {} }
end

-- Groups, rows, gates and edges, written onto the nodes of config 1001 (and 1002).
function SH.shape(tr)
	tr.groups[TREE] = { { groupID = 701, orderIndex = 1, displayName = 'Elemental' },
		{ groupID = 702, orderIndex = 2, displayName = 'Enhancement' },
		{ groupID = 703, orderIndex = 3, displayName = 'Restoration' } }
	local nodes = tr.nodes[CONFIG]
	local function place(nodeID, group, row)
		local info = nodes[nodeID]
		info.groupIDs, info.posY = { group }, 2130 + (row - 1) * 600 -- Forever's rows: 2130, 2730, ...
		if row > 1 then
			local cond = 9000 + nodeID
			tr.conditions[cond] = { isGate = true, isMet = false, spentAmountRequired = 5 * (row - 1), traitCurrencyID = 800 }
			info.conditionIDs = { cond }
		end
	end
	for i = 1, 15 do place(100 + i, 702, math.ceil(i / 5)) end
	for i = 16, 21 do place(100 + i, 701, math.ceil((i - 15) / 5)) end
	place(122, 703, 1); place(123, 703, 2)
	place(130, 703, 1)
	nodes[SH.ID['Spirit Weapons']].visibleEdges = { { targetNode = SH.ID.Stormstrike, type = 3, isActive = false } }
	nodes[SH.ID.Stormstrike].visibleEdges = { { targetNode = SH.ID['Improved Stormstrike'], type = 3, isActive = false } }
	nodes[130].visibleEdges = { { targetNode = SH.ID['Totemic Focus'], type = 3, isActive = false } }
	if tr.nodes[SECOND] then
		for nodeID, info in pairs(nodes) do
			for _, k in ipairs({ 'groupIDs', 'posY', 'conditionIDs', 'visibleEdges' }) do tr.nodes[SECOND][nodeID][k] = info[k] end
		end
	end
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
	if opts.shape then SH.shape(tr) end
	SH.world = { configID = CONFIG, treeID = TREE, second = opts.second and SECOND or nil }
	return SH.world
end

return SH
