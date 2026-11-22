-- SaftUI-Misc/TalentPlan/simulate.lua: the plan's simulation by the tree's rules. No WoW API.
load_saftui('SaftUI-Misc/TalentPlan/talentplan.lua')
load_saftui('SaftUI-Misc/TalentPlan/model.lua')
load_saftui('SaftUI-Misc/TalentPlan/simulate.lua')
local Sim = SaftUI:GetModule('TalentPlan').Sim

local A, B, C = 1, 2, 3
local a1, a2, a3, a4, b1, b2, x1 = 11, 12, 13, 14, 21, 22, 99
local REQ, SUF = Sim.EDGE.REQUIRED, Sim.EDGE.SUFFICIENT

local function shape()
	return {
		groups = { { id = A, name = 'A', order = 1 }, { id = B, name = 'B', order = 2 }, { id = C, name = 'C', order = 3 } },
		nodes = {
			[a1] = { maxRanks = 5, cost = 1, group = A, gates = {}, parents = {}, plannable = true, name = 'a1' },
			[a2] = { maxRanks = 3, cost = 1, group = A, gates = {}, parents = {}, plannable = true, name = 'a2' },
			[a3] = { maxRanks = 1, cost = 1, group = A, gates = { { required = 5 } }, parents = {}, plannable = true, name = 'a3' },
			[a4] = { maxRanks = 1, cost = 1, group = A, gates = { { required = 10 } }, parents = { { nodeID = a3, type = REQ } }, plannable = true, name = 'a4' },
			[b1] = { maxRanks = 2, cost = 1, group = B, gates = {}, parents = {}, plannable = true, name = 'b1' },
			[b2] = { maxRanks = 1, cost = 1, group = B, gates = { { required = 5 } }, parents = {}, plannable = true, name = 'b2' },
			[x1] = { maxRanks = 1, cost = 1, group = A, gates = {}, parents = {}, plannable = false, name = 'x1' },
		},
	}
end
local function times(id, n, into)
	into = into or {}
	for _ = 1, n do into[#into + 1] = id end
	return into
end
local function concat(...)
	local out = {}
	for _, t in ipairs({ ... }) do for _, v in ipairs(t) do out[#out + 1] = v end end
	return out
end

test('an empty plan: row one selectable, the rest gated', function()
	local r = Sim.Run(shape(), {})
	eq(r.nodes[a1].state, 'selectable'); eq(r.nodes[a2].state, 'selectable'); eq(r.nodes[b1].state, 'selectable')
	eq(r.nodes[a3].state, 'gated'); eq(r.nodes[b2].state, 'gated')
	eq(r.nodes[a4].state, 'gated', 'the gate before the edge')
	eq(r.spent.total, 0)
end)

test("gates count the node's own tree", function()
	local r = Sim.Run(shape(), times(a1, 5))
	eq(r.nodes[a3].state, 'selectable'); eq(r.nodes[b2].state, 'gated')
	eq(r.spent.total, 5); eq(r.spent[A], 5); eq(r.spent[B] or 0, 0)
end)

test('a tree with no groups gates on the total', function()
	local s = shape(); s.groups = {}
	for _, n in pairs(s.nodes) do n.group = nil end
	local r = Sim.Run(s, times(a1, 5))
	eq(r.nodes[a3].state, 'selectable'); eq(r.nodes[b2].state, 'selectable')
	eq(Sim.CanAdd(s, {}, b2), false)
	eq(Sim.CanAdd(s, times(b1, 2, times(a1, 3)), b2), true)
end)

test('required and sufficient edges', function()
	local steps = concat(times(a1, 5), times(a2, 3), times(b1, 2))
	eq(Sim.Run(shape(), steps).nodes[a4].state, 'gated', 'ten points not yet in A')
	local s = shape()
	s.nodes[a1].maxRanks = 6
	s.nodes[a2].maxRanks = 4
	steps = concat(times(a1, 6), times(a2, 4))
	local r = Sim.Run(s, steps)
	eq(r.spent[A], 10); eq(r.nodes[a4].state, 'locked', 'gate met, a3 not maxed')
	eq(select(2, Sim.CanAdd(s, steps, a4)), 'Needs a3 first.')
	eq(Sim.Run(s, concat(steps, { a3 })).nodes[a4].state, 'selectable')

	local t = shape()
	t.nodes[b2].gates = {}
	t.nodes[b2].parents = { { nodeID = a2, type = SUF }, { nodeID = b1, type = SUF } }
	eq(Sim.Run(t, {}).nodes[b2].state, 'locked')
	eq(Sim.Run(t, times(a2, 3)).nodes[b2].state, 'selectable', 'either sufficient parent opens it')
	eq(Sim.Run(t, times(b1, 2)).nodes[b2].state, 'selectable')
	eq(Sim.Run(t, { a2 }).nodes[b2].state, 'locked')
end)

test('cost counts', function()
	local s = shape(); s.nodes[a2].cost = 2
	local r = Sim.Run(s, { a2, a1 })
	eq(r.spent.total, 3); eq(r.spent[A], 3)
end)

test('ranks, maxed and partial', function()
	local r = Sim.Run(shape(), times(a2, 3))
	eq(r.nodes[a2].state, 'maxed'); eq(r.nodes[a2].rank, 3); eq(r.ranks[a2], 3)
	eq(Sim.Run(shape(), { a2 }).nodes[a2].state, 'selectable')
	local s = shape(); s.budget = 1
	r = Sim.Run(s, { a2 })
	eq(r.nodes[a2].state, 'partial'); eq(r.nodes[b1].state, 'disabled')
end)

test('a moved step is flagged, still counted', function()
	local r = Sim.Run(shape(), concat({ a3 }, times(a1, 5)))
	eq(r.steps[1].ok, false); eq(r.steps[1].reason, 'Needs 5 points in A first.')
	eq(r.nodes[a3].reason, 'Needs 5 points in A first.', 'an error node says why')
	eq(r.ranks[a3], 1); eq(r.nodes[a3].state, 'error')
	eq(r.steps[2].ok, true)
end)

test('CanAdd follows the order', function()
	local ok, why = Sim.CanAdd(shape(), times(a1, 4), a3)
	eq(ok, false); eq(why, 'Needs 5 points in A first.')
	eq(Sim.CanAdd(shape(), times(a1, 5), a3), true)
	eq(Sim.CanAdd(shape(), times(a1, 5), a3, 0), false, 'inserted first')
	eq(select(2, Sim.CanAdd(shape(), times(a1, 5), a3, 0)), 'Needs 5 points in A first.')
	eq(Sim.CanAdd(shape(), times(a1, 5), a3, 5), true, 'inserted after the fifth')
	ok, why = Sim.CanAdd(shape(), times(a2, 3), a2)
	eq(ok, false); eq(why, 'All 3 ranks are planned.')
	ok, why = Sim.CanAdd(shape(), {}, x1)
	eq(ok, false); eq(why, "This talent can't be planned.")
	local s = shape(); s.budget = 1
	eq(select(2, Sim.CanAdd(s, { a1 }, a2)), 'No points left: the last one comes at level 60.')
	-- an insert that starves a later step is refused
	s.budget = 6
	ok, why = Sim.CanAdd(s, concat(times(a1, 5), { a3 }), a2, 0)
	eq(ok, false); eq(why, 'No points left: the last one comes at level 60.')
end)

test('CanRemove refuses a rank a later step needs', function()
	local ok, why = Sim.CanRemove(shape(), concat(times(a1, 5), { a3 }), a1)
	eq(ok, false); eq(why, 'Other planned talents need this rank.')
	eq(Sim.CanRemove(shape(), concat(times(a1, 6), { a3 }), a1), true, 'the sixth was after')
	ok, why = Sim.CanRemove(shape(), { a1 }, a2)
	eq(ok, false); eq(why, 'Not in the plan.')
end)

test('with levels, a refusal names the talent and level that need the rank; 51 points cap the plan', function()
	local s = shape(); s.firstLevel, s.lastLevel = 10, 60
	local ok, why = Sim.CanRemove(s, concat(times(a1, 5), { a3 }), a1)
	eq(ok, false); eq(why, 'a3 at level 15 needs this rank.')
	s.budget = 6
	ok, why = Sim.CanAdd(s, concat(times(a1, 5), { a3 }), a2, 0)
	eq(ok, false); eq(why, 'No points left: the last one comes at level 60.', 'an insert that starves a later step says so')
	s.budget = 51
	local full = concat(times(a1, 5), times(a2, 3), times(b1, 2))
	for _ = 1, 41 do full[#full + 1] = b2 end -- the plan's count, not a legal plan: only the budget matters here
	ok, why = Sim.CanAdd(s, full, a3)
	eq(ok, false); eq(why, 'No points left: the last one comes at level 60.')
	table.remove(full)
	eq(Sim.CanAdd(s, full, a3), true, 'the 51st point')
end)

test('a gate in an unlisted group counts the tree; a negative after clamps', function()
	local s = shape(); s.nodes[a3].group = 77
	local ok, why = Sim.CanAdd(s, times(b1, 2, times(a1, 2)), a3)
	eq(ok, false); eq(why, 'Needs 5 points in the tree first.')
	eq(Sim.CanAdd(s, times(b1, 2, times(a1, 3)), a3), true)
	eq(Sim.CanAdd(shape(), times(a1, 5), a3, -3), false, 'clamped to the front')
end)

test('Check names the nodes the game disagrees on', function()
	local real = { [a1] = { rank = 5, isAvailable = true, meetsEdgeRequirements = true },
		[a3] = { rank = 0, isAvailable = false, meetsEdgeRequirements = true } }
	local out = Sim.Check(shape(), real)
	eq(#out, 1); eq(out[1].nodeID, a3); eq(out[1].field, 'gated'); eq(out[1].game, false); eq(out[1].sim, true)
	real[a3].isAvailable = true
	eq(#Sim.Check(shape(), real), 0)
	real[a3].meetsEdgeRequirements = false
	out = Sim.Check(shape(), real)
	eq(#out, 1); eq(out[1].field, 'locked'); eq(out[1].sim, true)
end)

test('ShowCount', function()
	local s = shape()
	eq(Sim.ShowCount(s, a1, 0, 'gated'), false)
	eq(Sim.ShowCount(s, a1, 0, 'selectable'), true)
	eq(Sim.ShowCount(s, a1, 2, 'partial'), true)
	eq(Sim.ShowCount(s, a3, 1, 'maxed'), true, 'hideSingle off')
	s.hideSingle = true
	eq(Sim.ShowCount(s, a3, 1, 'maxed'), false); eq(Sim.ShowCount(s, a3, 0, 'selectable'), false)
	eq(Sim.ShowCount(s, a1, 1, 'partial'), true, 'a multi-rank node still shows')
end)

test('CanMove refuses a drag that breaks a step, naming it, and allows one that breaks none', function()
	local s = shape(); s.firstLevel = 10
	local steps = concat(times(a1, 5), { a3, b1 })
	local ok, why = Sim.CanMove(s, steps, 6, 1)
	eq(ok, false); eq(why, 'a3 at level 10: Needs 5 points in A first.')
	ok, why = Sim.CanMove(s, steps, 1, 6)
	eq(ok, false); eq(why, 'a3 at level 14: Needs 5 points in A first.')
	eq(Sim.CanMove(s, steps, 7, 1), true, 'b1 can go first')
	eq(Sim.CanMove(s, steps, 3, 3), true, 'no move')
	-- a step that was already broken doesn't block a move
	local broken = concat({ a3 }, times(a1, 5), { b1 })
	eq(Sim.CanMove(s, broken, 7, 2), true)
end)
