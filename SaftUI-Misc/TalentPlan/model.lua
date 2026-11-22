local st = SaftUI
local TP = st:GetModule('TalentPlan')

--[[
	The talent plan's rules, pure (no WoW API). A plan is
	{ id, name, steps = { nodeID, ... }, phases = { { at, name, color }, ... } }:
	step i is the pick made at level FIRST_LEVEL + i - 1, and a phase's `at` is
	the index of the step it starts before (#steps + 1 is an empty phase at the
	end). A step's rank is how many times its node has come so far in the list,
	so it renumbers when steps move.
]]
local M = {}
TP.Model = M

M.FIRST_LEVEL = 10
M.PHASE_COLORS = { 'blue', 'orange', 'yellow', 'red', 'green' }
M.PHASE_RGB = {
	blue = { 0.31, 0.60, 0.96 },
	orange = { 0.96, 0.58, 0.20 },
	yellow = { 0.96, 0.84, 0.27 },
	red = { 0.90, 0.30, 0.30 },
	green = { 0.40, 0.80, 0.40 },
}

function M.NewPlan(id, name)
	return { id = id, name = name, steps = {}, phases = {} }
end

function M.Level(index)
	return M.FIRST_LEVEL + index - 1
end

-- { [index] = rank }
function M.Ranks(steps)
	local seen, ranks = {}, {}
	for i = 1, #steps do
		local id = steps[i]
		seen[id] = (seen[id] or 0) + 1
		ranks[i] = seen[id]
	end
	return ranks
end

function M.PlannedRanks(plan, nodeID)
	local n = 0
	for i = 1, #plan.steps do
		if plan.steps[i] == nodeID then n = n + 1 end
	end
	return n
end

-- { { index, rank, level }, ... }, in list order
function M.StepsOf(plan, nodeID)
	local out, ranks = {}, M.Ranks(plan.steps)
	for i = 1, #plan.steps do
		if plan.steps[i] == nodeID then
			out[#out + 1] = { index = i, rank = ranks[i], level = M.Level(i) }
		end
	end
	return out
end

local function shiftPhases(plan, after, by)
	for _, phase in ipairs(plan.phases) do
		if phase.at > after then phase.at = phase.at + by end
	end
end

-- Appends (after nil, nothing shifts) or inserts at after + 1. Gives the index.
function M.AddStep(plan, nodeID, after)
	if after == nil then
		plan.steps[#plan.steps + 1] = nodeID
		return #plan.steps
	end
	table.insert(plan.steps, after + 1, nodeID)
	shiftPhases(plan, after, 1)
	return after + 1
end

function M.RemoveStep(plan, index)
	table.remove(plan.steps, index)
	shiftPhases(plan, index, -1)
end

-- Removes the node's last step. Gives its index, or nil if the plan has none.
function M.RemoveLastOf(plan, nodeID)
	for i = #plan.steps, 1, -1 do
		if plan.steps[i] == nodeID then
			M.RemoveStep(plan, i)
			return i
		end
	end
end

--[[
	Where each step stands against the talent window. nodes[nodeID] =
	{ committed, staged, maxRanks, block }; a node that isn't there is a missing
	step. Rows are { index, nodeID, rank, level, state, waiting, block }, state
	'learned' | 'pending' (staged, not yet applied) | 'upcoming' | 'missing'.
	The waiting row is the first that is neither learned nor missing, when its
	level has been reached; it alone carries the node's block. summary =
	{ learned, total (steps that aren't missing), waiting (its index) }. With
	level nil nothing is waiting.
]]
function M.States(plan, nodes, level)
	local ranks, rows = M.Ranks(plan.steps), {}
	local summary = { learned = 0, total = 0 }
	for i = 1, #plan.steps do
		local nodeID, rank = plan.steps[i], ranks[i]
		local node = nodes[nodeID]
		local row = { index = i, nodeID = nodeID, rank = rank, level = M.Level(i) }
		if not node then
			row.state = 'missing'
		else
			summary.total = summary.total + 1
			if (node.committed or 0) >= rank then
				row.state = 'learned'
				summary.learned = summary.learned + 1
			elseif (node.staged or 0) >= rank then
				row.state = 'pending'
			else
				row.state = 'upcoming'
			end
		end
		rows[i] = row
	end
	if level then
		for _, row in ipairs(rows) do
			if row.state ~= 'learned' and row.state ~= 'missing' then
				if row.level <= level then
					row.waiting = true
					row.block = nodes[row.nodeID].block
					summary.waiting = row.index
				end
				break
			end
		end
	end
	return rows, summary
end

-- Ranks taken beyond what the plan wants, summed over the nodes.
function M.OffPlan(plan, nodes)
	local n = 0
	for nodeID, node in pairs(nodes) do
		n = n + math.max(0, (node.committed or 0) - M.PlannedRanks(plan, nodeID))
	end
	return n
end

-- base, then base .. ' 2', ' 3', ... ; names is a set of names in use.
function M.UniqueName(names, base)
	if not names[base] then return base end
	local n = 2
	while names[base .. ' ' .. n] do n = n + 1 end
	return base .. ' ' .. n
end
