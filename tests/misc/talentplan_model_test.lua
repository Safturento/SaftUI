-- SaftUI-Misc/TalentPlan/model.lua: the plan's pure rules. No WoW API.
load_saftui('SaftUI-Misc/TalentPlan/talentplan.lua')
load_saftui('SaftUI-Misc/TalentPlan/model.lua')
local M = SaftUI:GetModule('TalentPlan').Model

test('ranks count each node so far, and renumber when steps swap', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 7, 7, 9, 7 }
	local r = M.Ranks(plan.steps)
	eq(r[1], 1); eq(r[2], 2); eq(r[3], 1); eq(r[4], 3)
	plan.steps = { 7, 9, 7, 7 } -- a rank 2 moved below another node
	r = M.Ranks(plan.steps); eq(r[3], 2, 'renumbered in list order')
	eq(M.Level(1), 10); eq(M.Level(51), 60)
end)

test('AddStep appends without shifting a trailing phase, and inserts after a row shifting later phases', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3 }
	plan.phases = { { at = 2, name = 'B', color = 'blue' }, { at = 4, name = 'C', color = 'red' } }
	eq(M.AddStep(plan, 5), 4); eq(plan.phases[2].at, 4, 'trailing phase now holds the appended step')
	eq(M.AddStep(plan, 6, 1), 2); eq(plan.steps[2], 6)
	eq(plan.phases[1].at, 3, 'phase after the row moves down'); eq(plan.phases[2].at, 5)
end)

test('RemoveStep and RemoveLastOf shift phases up', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 1, 3 }
	plan.phases = { { at = 3, name = 'B', color = 'blue' } }
	eq(M.RemoveLastOf(plan, 1), 3); eq(#plan.steps, 3); eq(plan.phases[1].at, 3)
	M.RemoveStep(plan, 1); eq(plan.phases[1].at, 2)
	eq(M.RemoveLastOf(plan, 99), nil)
end)

test('States: learned, waiting, pending, upcoming, missing, blocked', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 1, 2, 3, 4, 2 }
	local nodes = {
		[1] = { committed = 2, staged = 2, maxRanks = 2 },
		[2] = { committed = 0, staged = 1, maxRanks = 2 },         -- rank 1 staged
		[3] = { committed = 0, staged = 0, maxRanks = 1, block = 'Needs the talent above it first.' },
		-- 4 is missing
	}
	local rows, sum = M.States(plan, nodes, 13)
	eq(rows[1].state, 'learned'); eq(rows[2].state, 'learned')
	eq(rows[3].state, 'pending'); check(rows[3].waiting, 'a staged step is still the waiting one')
	eq(rows[4].state, 'upcoming'); check(not rows[4].waiting)
	eq(rows[5].state, 'missing'); eq(rows[6].state, 'upcoming')
	eq(sum.learned, 2); eq(sum.total, 5, 'missing steps are not counted'); eq(sum.waiting, 3)
	nodes[2].staged = 0
	rows, sum = M.States(plan, nodes, 13)
	eq(rows[3].state, 'upcoming'); check(rows[3].waiting); eq(rows[3].block, nil)
	nodes[2].committed, nodes[2].staged = 1, 1
	rows, sum = M.States(plan, nodes, 13)
	eq(sum.waiting, 4); eq(rows[4].block, 'Needs the talent above it first.', 'the waiting row carries its block')
	rows, sum = M.States(plan, nodes, 12); eq(sum.waiting, nil, 'step 4 is level 13: nothing waits at 12')
	rows, sum = M.States(plan, nodes, nil); eq(sum.waiting, nil, 'no level: no config, all upcoming')
end)

test('a missing step is never waiting, and the next one is', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 4, 2 }
	local rows, sum = M.States(plan, { [2] = { committed = 0, staged = 0, maxRanks = 1 } }, 60)
	eq(rows[1].state, 'missing'); eq(sum.waiting, 2)
end)

test('OffPlan counts ranks beyond the plan', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2 }
	eq(M.OffPlan(plan, { [1] = { committed = 3 }, [2] = { committed = 1 }, [5] = { committed = 1 } }), 3)
end)

test('StepsOf and UniqueName', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 1 }
	local s = M.StepsOf(plan, 1)
	eq(#s, 2); eq(s[2].index, 3); eq(s[2].rank, 2); eq(s[2].level, 12)
	eq(M.UniqueName({ Imported = true, ['Imported 2'] = true }, 'Imported'), 'Imported 3')
end)

test('Entries put phases before their first step and empty ones last', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3 }
	plan.phases = { { at = 1, name = 'A', color = 'blue' }, { at = 3, name = 'B', color = 'red' }, { at = 4, name = 'C', color = 'green' } }
	local e = M.Entries(plan)
	eq(#e, 6); eq(e[1].kind, 'phase'); eq(e[2].index, 1); eq(e[4].phase, 2); eq(e[6].phase, 3)
end)

test('moving a rank 2 above its rank 1 renumbers; moving a header regroups', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 7, 8, 7 }
	plan.phases = { { at = 2, name = 'B', color = 'blue' } }
	-- entries: step1(7) | phase B | step2(8) | step3(7)
	M.MoveEntry(plan, 4, 1)
	eq(plan.steps[1], 7); eq(M.Ranks(plan.steps)[1], 1); eq(M.Ranks(plan.steps)[2], 2)
	eq(plan.phases[1].at, 3, 'the header stays before 8')
	M.MoveEntry(plan, 3, 1) -- the header to the top
	eq(plan.phases[1].at, 1); eq(M.PhaseOf(plan, 3), 1)
	local before = table.concat(plan.steps, ','); M.MoveEntry(plan, 2, 2); eq(table.concat(plan.steps, ','), before)
end)

test('phases: add, colors, range, remove', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3, 4 }
	eq(M.NextColor(plan), 'blue'); M.AddPhase(plan, 1, 'A', 'blue'); eq(M.NextColor(plan), 'orange')
	M.AddPhase(plan, 3, 'B', 'orange')
	local a, b = M.PhaseRange(plan, 1); eq(a, 10); eq(b, 11)
	M.RemovePhase(plan, 1); eq(#plan.phases, 1); eq(M.PhaseOf(plan, 1), nil)
end)

test('MoveEntry gives the step index map, keeps phases in order, and normalizes an empty trailing phase', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3 }
	plan.phases = { { at = 5, name = 'E', color = 'red' } } -- empty, past the end (AddStep after the last step)
	local map = M.MoveEntry(plan, 1, 3)
	eq(map[1], 3); eq(map[2], 1); eq(map[3], 2)
	eq(plan.phases[1].at, 4, 'still after every step')
	eq(M.PhaseRange(plan, 1), nil, 'and empty')
	M.MoveEntry(plan, 4, 4)
	-- dropping a step at the end keeps the empty phase last
	M.MoveEntry(plan, 1, 4)
	eq(plan.phases[1].at, 3)
	eq(M.PhaseRange(plan, 1), 12, 'a step dropped after the header joins it')
end)

test('colors cycle once all five are in use', function()
	local plan = M.NewPlan(1, 'p')
	for i = 1, 5 do M.AddPhase(plan, 1, 'p' .. i, M.NextColor(plan)) end
	eq(M.NextColor(plan), 'blue')
	M.AddPhase(plan, 1, 'p6', 'blue'); eq(M.NextColor(plan), 'orange')
	eq(M.PhaseRange(plan, 99), nil)
end)
