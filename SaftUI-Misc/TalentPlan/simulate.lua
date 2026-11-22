local st = SaftUI
local TP = st:GetModule('TalentPlan')

--[[
	The plan's simulation, pure (no WoW API, no st: calls). It plays the plan's
	steps (a list of node IDs) against the tree's shape and says, for each step,
	whether the game would have allowed it at that point, and for each node its
	state after the last step. The shape is read by data.lua:
	{ groups = { { id, name, order } }, budget, hideSingle,
	  nodes = { [id] = { maxRanks, cost, group, gates = { { required } },
	                     parents = { { nodeID, type } }, plannable, name } } }.
	A gate counts the points spent in the node's group when it has one, else in
	the whole tree. A prerequisite edge needs its parent maxed. Every rule lives
	in Legal, so Run, CanAdd, CanRemove and the node states never disagree.
]]
local Sim = {}
TP.Sim = Sim

-- Enum.TraitEdgeType, literal (pure).
Sim.EDGE = { REQUIRED = 3, SUFFICIENT = 2 }

local function groupName(shape, groupID)
	for _, g in ipairs(shape.groups or {}) do
		if g.id == groupID then return g.name end
	end
end

-- Is the node's gate met? false, required, scope name when not.
local function GateMet(shape, node, spent)
	for _, gate in ipairs(node.gates or {}) do
		local have = node.group and (spent[node.group] or 0) or (spent.total or 0)
		if have < gate.required then
			return false, gate.required, node.group and groupName(shape, node.group) or nil
		end
	end
	return true
end

-- Are the node's prerequisite edges met? false, the parent's name when not.
local function EdgesMet(shape, node, ranks)
	local function maxed(id)
		local p = shape.nodes[id]
		return p ~= nil and (ranks[id] or 0) >= p.maxRanks
	end
	local firstSufficient, anySufficient
	for _, e in ipairs(node.parents or {}) do
		local p = shape.nodes[e.nodeID]
		local name = p and p.name or 'the talent above'
		if e.type == Sim.EDGE.REQUIRED then
			if not maxed(e.nodeID) then return false, name end
		elseif e.type == Sim.EDGE.SUFFICIENT then
			firstSufficient = firstSufficient or name
			if maxed(e.nodeID) then anySufficient = true end
		end
	end
	if firstSufficient and not anySufficient then return false, firstSufficient end
	return true
end

-- The one rule: may the node get one more rank, with these ranks and spent?
-- ok, reason, kind ('gated' | 'locked' | 'disabled', for the node's state).
local function Legal(shape, ranks, spent, nodeID)
	local node = shape.nodes[nodeID]
	if not node or not node.plannable then return false, "This talent can't be planned.", 'disabled' end
	if (ranks[nodeID] or 0) >= node.maxRanks then
		return false, ('All %d ranks are planned.'):format(node.maxRanks), 'disabled'
	end
	local gateOK, required, scope = GateMet(shape, node, spent)
	if not gateOK then
		return false, ('Needs %d points in %s first.'):format(required, scope or 'the tree'), 'gated'
	end
	local edgeOK, parentName = EdgesMet(shape, node, ranks)
	if not edgeOK then return false, ('Needs %s first.'):format(parentName), 'locked' end
	if shape.budget and (spent.total or 0) + (node.cost or 1) > shape.budget then
		return false, 'No points left at this level.', 'disabled'
	end
	return true
end

local function Spend(shape, ranks, spent, nodeID)
	ranks[nodeID] = (ranks[nodeID] or 0) + 1
	local node = shape.nodes[nodeID]
	if node then
		local cost = node.cost or 1
		spent.total = spent.total + cost
		if node.group then spent[node.group] = (spent[node.group] or 0) + cost end
	end
end

local function NodeState(shape, ranks, spent, id, errored)
	local node = shape.nodes[id]
	local rank = ranks[id] or 0
	if errored then return 'error' end
	if node.plannable and rank >= node.maxRanks then return 'maxed' end
	local ok, reason, kind = Legal(shape, ranks, spent, id)
	if ok then return 'selectable', nil end
	if rank > 0 then return 'partial', reason end
	return kind == 'gated' and 'gated' or kind == 'locked' and 'locked' or 'disabled', reason
end

function Sim.Run(shape, steps)
	local ranks, spent, out, bad = {}, { total = 0 }, {}, {}
	for i, id in ipairs(steps or {}) do
		local ok, reason = Legal(shape, ranks, spent, id)
		out[i] = { ok = ok, reason = (not ok) and reason or nil }
		if not ok then bad[id] = true end
		Spend(shape, ranks, spent, id)
	end
	local nodes = {}
	for id in pairs(shape.nodes) do
		local state, reason = NodeState(shape, ranks, spent, id, bad[id])
		nodes[id] = { rank = ranks[id] or 0, state = state, reason = reason }
	end
	return { ranks = ranks, spent = spent, steps = out, nodes = nodes }
end

local function Insert(steps, nodeID, after)
	local out, at = {}, after == nil and #steps or math.min(after, #steps)
	for i = 1, at do out[#out + 1] = steps[i] end
	out[#out + 1] = nodeID
	for i = at + 1, #steps do out[#out + 1] = steps[i] end
	return out, at + 1
end

-- Would the step be legal where it goes, without breaking a later one?
function Sim.CanAdd(shape, steps, nodeID, after)
	local before = Sim.Run(shape, steps)
	local new, at = Insert(steps, nodeID, after)
	local run = Sim.Run(shape, new)
	if not run.steps[at].ok then return false, run.steps[at].reason end
	for i = at + 1, #new do
		if before.steps[i - 1].ok and not run.steps[i].ok then
			return false, 'Other planned talents need this rank.'
		end
	end
	return true
end

-- Would taking the node's last planned rank out leave every step still legal?
function Sim.CanRemove(shape, steps, nodeID)
	local last
	for i = #steps, 1, -1 do
		if steps[i] == nodeID then last = i; break end
	end
	if not last then return false, 'Other planned talents need this rank.' end
	local before = Sim.Run(shape, steps)
	local new = {}
	for i, id in ipairs(steps) do if i ~= last then new[#new + 1] = id end end
	local run = Sim.Run(shape, new)
	for i = last + 1, #steps do
		if before.steps[i].ok and not run.steps[i - 1].ok then
			return false, 'Other planned talents need this rank.'
		end
	end
	return true
end

-- The rules over the real ranks, against what the game says: the nodes where
-- they disagree. real[id] = { rank, isAvailable, meetsEdgeRequirements }.
function Sim.Check(shape, real)
	local ranks, spent = {}, { total = 0 }
	for id, r in pairs(real) do
		local node = shape.nodes[id]
		if node and (r.rank or 0) > 0 then
			ranks[id] = r.rank
			local cost = (node.cost or 1) * r.rank
			spent.total = spent.total + cost
			if node.group then spent[node.group] = (spent[node.group] or 0) + cost end
		end
	end
	local ids = {}
	for id in pairs(real) do if shape.nodes[id] then ids[#ids + 1] = id end end
	table.sort(ids)
	local out = {}
	for _, id in ipairs(ids) do
		local node, r = shape.nodes[id], real[id]
		local gate = GateMet(shape, node, spent)
		if r.isAvailable ~= nil and r.isAvailable ~= gate then
			out[#out + 1] = { nodeID = id, field = 'gated', game = r.isAvailable, sim = gate }
		end
		local edge = EdgesMet(shape, node, ranks)
		if r.meetsEdgeRequirements ~= nil and r.meetsEdgeRequirements ~= edge then
			out[#out + 1] = { nodeID = id, field = 'locked', game = r.meetsEdgeRequirements, sim = edge }
		end
	end
	return out
end

-- Blizzard's GetSpendText rule: a rank above 0, or a node that can be taken;
-- no number for a one rank node when the tree hides them.
function Sim.ShowCount(shape, nodeID, rank, state)
	local node = shape.nodes[nodeID]
	if node and shape.hideSingle and node.maxRanks == 1 and rank <= 1 then return false end
	return rank > 0 or state == 'selectable'
end
