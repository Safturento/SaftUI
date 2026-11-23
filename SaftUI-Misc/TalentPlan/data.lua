local st = SaftUI
local TP = st:GetModule('TalentPlan')

--[[
	The talent plan's reader of the class talent tree (C_Traits, read only: it
	never buys, refunds or commits). D.Read(specGroup) gives
	  { specGroup, configID|nil, treeID, active, level,
	    nodes = { [nodeID] = { nodeID, name, icon, maxRanks, committed, staged, block } },
	    names = { { name, nodeID, maxRanks } } }
	or nil when neither the group nor the active config has a tree. A tab with
	no config of its own is read through the active config's tree with every rank
	0 and no level: the plan shows every step as upcoming.

	`staged` is the rank in the tree now, changes not yet committed counted
	(currentRank, the number Blizzard's button shows; ranksPurchased without it),
	and `committed` the rank before them (activeRank, what Blizzard's IsMaxed
	reads). Without an activeRank, a snapshot is kept of each node's rank on
	every read of a node with no staged change. (ranksPurchased once counted a
	point the window didn't show: "1 point off plan" in a talent with none.)

	tree.shape is the tree's shape for the plan's rules (simulate.lua): groups
	(the tree's displayed groups by order), budget (51: one point a level from
	10 to 60), firstLevel and lastLevel, hideSingle, and every visible node that
	is not in a hero sub tree, plannable or not: { maxRanks, cost, group (the
	first of its groupIDs the tree lists, else nil), row, gates, parents (its
	incoming edges), plannable, posY, name }. A node's gate is its row's
	(RowGates: 5 points a row in its spec). tree.real[nodeID] is the
	game's rank, isAvailable and meetsEdgeRequirements, for /sui tp check.

	Nodes are skipped when they aren't visible, have other than one entry (a
	choice node), belong to a hero talent sub tree, or have no name.
]]
local D = {}
TP.Data = D

-- snapshots[configID][nodeID] = ranksPurchased
local snapshots = {}

function D.ResetSnapshots() snapshots = {} end

-- The rank the talent window shows, staged changes counted: currentRank, as
-- Blizzard's button draws (TalentButtonSpend's rankShown), else ranksPurchased.
function D.StagedRank(info)
	if type(info.currentRank) == 'number' then return info.currentRank end
	return info.ranksPurchased or 0
end

-- The committed rank when the game gives no activeRank: stagedKind is nil,
-- 'purchase' or 'refund'; known is the snapshot, if any.
function D.CommittedRank(purchased, stagedKind, known)
	if stagedKind == nil then return purchased end
	if known ~= nil then return known end
	if stagedKind == 'purchase' then return math.max(0, purchased - 1) end
	return purchased + 1
end

-- Why a node can't be bought now, or nil when it can. gates is the node's
-- conditions (TraitCondInfo).
function D.BlockReason(info, gates, active)
	if info.canPurchaseRank then return nil end
	if not active then return 'Switch to this spec to learn it.' end
	if not info.meetsEdgeRequirements then return 'Needs the talent above it first.' end
	if not info.isAvailable then
		for _, gate in ipairs(gates or {}) do
			if gate.isGate and not gate.isMet then
				if gate.spentAmountRequired then
					return ('Needs %d points spent in the tree first.'):format(gate.spentAmountRequired)
				end
				break
			end
		end
		return 'Not available yet.'
	end
	return 'No talent points to spend.'
end

-- The row gates, by Forever's own rule (its DB2, TraitCond on each row's node
-- group): each spec's rows are its nodes' distinct posY, top first, and row r
-- (0 based) needs 5 * r points spent in the rows above it in the same spec. A
-- plan is played forward, so when a step is taken every point already in its
-- spec sits in a row above it or was itself allowed by that count: the spec's
-- total gives the same answer, which is what Sim counts (node.group). The
-- nodes' own conditions are not read for this: Forever's don't say isGate.
-- A row is ROW_HEIGHT of posY from the spec's top row, rounded, so a node a few
-- units off is in its row and a row with no visible node still counts.
D.POINTS_PER_ROW, D.ROW_HEIGHT = 5, 600
local function RowGates(shape)
	-- 'tree' is the top of every node, for a node with no listed group (it counts the tree)
	local top = {}
	for _, node in pairs(shape.nodes) do
		local y = node.posY or 0
		top.tree = math.min(top.tree or y, y)
		if node.group then top[node.group] = math.min(top[node.group] or y, y) end
	end
	for _, node in pairs(shape.nodes) do
		local row = math.max(0, math.floor(((node.posY or 0) - top[node.group or 'tree']) / D.ROW_HEIGHT + 0.5))
		node.row = row
		node.gates = row > 0 and { { required = D.POINTS_PER_ROW * row } } or {}
	end
end

-- Which group of the tree's list is the node's: the first of its groupIDs listed.
local function GroupOf(info, listed)
	for _, groupID in ipairs(info.groupIDs or {}) do
		if listed[groupID] then return groupID end
	end
end

local function set_of(list)
	local set = {}
	for _, id in ipairs(list or {}) do set[id] = true end
	return set
end

function D.Read(specGroup)
	local configID = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(specGroup)
	local readFrom = configID or C_ClassTalents.GetActiveConfigID()
	if not readFrom then return nil end
	local config = C_Traits.GetConfigInfo(readFrom)
	local treeID = config and config.treeIDs and config.treeIDs[1]
	if not treeID then return nil end

	local active = C_SpecializationInfo.GetActiveSpecGroup() == specGroup
	local tree = { specGroup = specGroup, configID = configID, treeID = treeID, active = active,
		level = configID and UnitLevel('player') or nil, nodes = {}, names = {} }

	-- a point to spend now: the tree currency's quantity, the number Blizzard's
	-- Unspent Talents shows (ClassCurrencyDisplay), staged changes counted
	local currency = configID and C_Traits.GetTreeCurrencyInfo and C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
	tree.unspent = (currency and currency[1] and currency[1].quantity or 0) > 0

	local purchases, refunds
	if configID then
		local p, r = C_Traits.GetStagedChanges(configID)
		purchases, refunds = set_of(p), set_of(r)
		snapshots[configID] = snapshots[configID] or {}
	end

	-- the tree's shape, for the plan's rules (simulate.lua)
	local treeInfo = C_Traits.GetTreeInfo and C_Traits.GetTreeInfo(readFrom, treeID)
	local shape = { groups = {}, nodes = {}, hideSingle = treeInfo and treeInfo.hideSingleRankNumbers == true or false }
	tree.shape = shape
	tree.real = {} -- the game's own word on each node, for /sui tp check
	local listed, order, edges = {}, {}, {}
	for _, g in ipairs(C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupDisplayInfoByTreeID(treeID) or {}) do
		shape.groups[#shape.groups + 1] = { id = g.groupID, name = g.displayName, order = g.orderIndex }
		listed[g.groupID] = true
	end
	table.sort(shape.groups, function(a, b) return (a.order or 0) < (b.order or 0) end)
	-- the points a plan can spend: one a level, FIRST_LEVEL to LAST_LEVEL (51)
	local M = TP.Model
	shape.budget, shape.firstLevel, shape.lastLevel = M.POINTS, M.FIRST_LEVEL, M.LAST_LEVEL

	for _, nodeID in ipairs(C_Traits.GetTreeNodes(treeID) or {}) do
		local info = C_Traits.GetNodeInfo(readFrom, nodeID)
		if info and info.isVisible and not info.subTreeID then
			local gates, parents = {}, {} -- gates: RowGates, below
			local costs = C_Traits.GetNodeCost and C_Traits.GetNodeCost(readFrom, nodeID)
			-- the same fallback as the plannable node's below: the node's, else its one entry's, else 1
			local only = info.entryIDs and #info.entryIDs == 1 and C_Traits.GetEntryInfo(readFrom, info.entryIDs[1])
			shape.nodes[nodeID] = { maxRanks = info.maxRanks or (only and only.maxRanks) or 1,
				cost = costs and costs[1] and costs[1].amount or 1,
				group = GroupOf(info, listed), gates = gates, parents = parents, plannable = false, posY = info.posY }
			order[#order + 1] = nodeID
			edges[nodeID] = info.visibleEdges
			tree.real[nodeID] = { rank = D.StagedRank(info), isAvailable = info.isAvailable,
				meetsEdgeRequirements = info.meetsEdgeRequirements }
		end
		if info and info.isVisible and not info.subTreeID and info.entryIDs and #info.entryIDs == 1 then
			local entry = C_Traits.GetEntryInfo(readFrom, info.entryIDs[1])
			local def = entry and entry.definitionID and C_Traits.GetDefinitionInfo(entry.definitionID)
			local name = def and def.overrideName
			if def and (not name or name == '') then -- "" is no override, as Blizzard reads it
				name = def.spellID and C_Spell.GetSpellName(def.spellID)
			end
			if name and name ~= '' then
				local icon = def.overrideIcon or (def.spellID and (C_Spell.GetSpellTexture(def.spellID)))
				local maxRanks = info.maxRanks or entry.maxRanks or 1
				local committed, staged = 0, 0
				if configID then
					staged = D.StagedRank(info)
					if type(info.activeRank) == 'number' then
						-- the game's own committed rank (Blizzard's IsMaxed reads it)
						committed = info.activeRank
					else
						local kind = purchases[nodeID] and 'purchase' or refunds[nodeID] and 'refund' or nil
						if kind == nil then snapshots[configID][nodeID] = staged end
						committed = D.CommittedRank(staged, kind, snapshots[configID][nodeID])
					end
				end
				local block
				if staged < maxRanks then
					local gates = {}
					for _, condID in ipairs(info.conditionIDs or {}) do
						local cond = C_Traits.GetConditionInfo(readFrom, condID)
						if cond then gates[#gates + 1] = cond end
					end
					-- another tab's node is never buyable now, whatever the game says of it
					info.canPurchaseRank = info.canPurchaseRank and active
					block = D.BlockReason(info, gates, active)
				end
				tree.nodes[nodeID] = { nodeID = nodeID, name = name, icon = icon, maxRanks = maxRanks,
					committed = committed, staged = staged, block = block }
				tree.names[#tree.names + 1] = { name = name, nodeID = nodeID, maxRanks = maxRanks }
				shape.nodes[nodeID].plannable = true
				shape.nodes[nodeID].name = name
			end
		end
	end
	-- the incoming edges: every visible node's visibleEdges, turned round
	for _, nodeID in ipairs(order) do
		for _, edge in ipairs(edges[nodeID] or {}) do
			local child = shape.nodes[edge.targetNode]
			if child then child.parents[#child.parents + 1] = { nodeID = nodeID, type = edge.type } end
		end
	end
	RowGates(shape)
	return tree
end
