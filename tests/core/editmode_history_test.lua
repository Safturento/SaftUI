-- Edit mode's history store (SaftUI-Core/EditMode/history.lua): steps, merging
-- nudges by the grouping rule, the limit, undo and redo with their staleness
-- and checks, jumping, reverting one step, and when it clears. The store knows
-- no kind of thing: these cases register a test kind 'value' over a table.
--
-- Real: Core's helpers, edit mode's files and a real AceDB profile database
-- (tests/core/config_helpers.lua), whose profile changes the history clears on.

load_test_file('core/config_helpers.lua')

local st = SaftUI
local EM = st.EditModeFrames
local History = EM.History

local store, writes, finishes, fired

History:RegisterKind('value', {
	read = function(k) return store[k] end,
	write = function(k, v) store[k] = v; writes[#writes + 1] = k end,
	finish = function(ws) finishes[#finishes + 1] = #ws end,
	name = function(k) return k end,
})

EM:On('HistoryChanged', function() fired = fired + 1 end)

local function fresh()
	store, writes, finishes, fired = {}, {}, {}, 0
	stub.time = 0
	stub.in_combat = false
	History:SetLimit(50)
	History:Clear()
	fired = 0
end

-- A real action has already happened: the new value is stored, then pushed.
local function push(kind, target, k, old, new)
	store[k] = new
	return History:Push({ kind = kind, target = target, label = 'Set ' .. k,
		changes = { { kind = 'value', where = k, old = old, new = new } } })
end

test('Push records a step with its label, time and changes; a step with no net change records nothing', function()
	fresh()
	stub.time = 10
	local step = push('move', 'a', 'a', 1, 2)
	eq(History.Label(step), 'Set a', 'its label')
	eq(step.time, 10, 'its time')
	eq(#History:Steps(), 1, 'one step')
	eq(History:Position(), 1, 'applied')
	eq(fired, 1, 'HistoryChanged')
	eq(push('move', 'a', 'a', 2, '2'), nil, 'a change to the same number as a string is no change')
	eq(#History:Steps(), 1, 'nothing recorded')
	eq(fired, 1, 'and nothing fired')
	local fn = History:Push({ kind = 'move', label = function(s) return 'n=' .. #s.changes end,
		changes = { { kind = 'value', where = 'b', old = 1, new = 2 } } })
	eq(History.Label(fn), 'n=1', "a function label gets the step")
	eq(History.Places(fn)['value:b'], true, 'its place')
end)

test('nudges merge only by the grouping rule; the merged step keeps the first old and the latest new', function()
	fresh()
	stub.time = 10
	local first = push('nudge', 'a', 'a', 1, 2)
	eq(first.open, true, 'a nudge opens a run')
	stub.time = 10.5
	push('nudge', 'a', 'a', 2, 3)
	stub.time = 11.4
	local merged = push('nudge', 'a', 'a', 3, 4)
	eq(#History:Steps(), 1, 'three nudges, one step')
	eq(merged, first, 'the merged step is the first')
	eq(merged.changes[1].old, 1, 'the first old')
	eq(merged.changes[1].new, 4, 'the latest new')
	eq(merged.open, true, 'still open')
	eq(merged.last, 11.4, 'last merge time')

	stub.time = 12.41 -- 1.01 after the last
	push('nudge', 'a', 'a', 4, 5)
	eq(#History:Steps(), 2, 'a gap over MERGE_GAP starts a new step')
	push('nudge', 'b', 'b', 1, 2)
	eq(#History:Steps(), 3, 'another target starts a new step')
	push('move', 'b', 'b', 2, 3)
	eq(#History:Steps(), 4, 'a move is a step')
	eq(History:Steps()[3].open, nil, 'and closed the run before it')
	eq(History:Steps()[4].open, nil, 'a move opens no run')
	push('nudge', 'b', 'b', 3, 4)
	eq(#History:Steps(), 5, 'a nudge after a move starts a new step')
	History:CloseRun()
	push('nudge', 'b', 'b', 4, 5)
	eq(#History:Steps(), 6, 'a closed run takes no more')

	-- An undone top: no merge, and the redo steps go.
	fresh()
	push('nudge', 'a', 'a', 1, 2)
	History:Undo()
	local n = push('nudge', 'a', 'a', 1, 5)
	eq(#History:Steps(), 1, 'the redo step was discarded')
	eq(n.changes[1].new, 5, 'and the new nudge is its own step')

	-- The rule itself: even an open run takes nothing while a step is undone.
	fresh()
	push('nudge', 'a', 'a', 1, 2)
	push('move', 'b', 'b', 1, 2)
	History:Undo()
	History:Undo()
	History:Steps()[1].open = true
	eq(History.Merges(History:Steps()[2], { kind = 'nudge', target = 'b' }, stub.time), false, 'not at the top')
	eq(History.Merges(History:Steps()[1], { kind = 'nudge', target = 'a' }, stub.time), false, 'not applied (position 0)')

	-- Back to the start: no step at all.
	fresh()
	push('nudge', 'a', 'a', 1, 2)
	eq(push('nudge', 'a', 'a', 2, 1), nil, 'a run back at its start is no step')
	eq(#History:Steps(), 0, 'the step is gone')
	eq(History:Position(), 0, 'position follows')
	eq(History.Merges(nil, { kind = 'nudge' }, 0), false, 'no top, no merge')
end)

test('a new step after an undo discards the redo steps; the limit drops the oldest first', function()
	fresh()
	push('move', 'a', 'a', 1, 2); push('move', 'b', 'b', 1, 2); push('move', 'c', 'c', 1, 2)
	History:Undo()
	eq(History:CanRedo(), true, 'redo after undo')
	push('move', 'd', 'd', 1, 2)
	eq(#History:Steps(), 3, 'two kept and the new one')
	eq(History:CanRedo(), false, 'no redo after a new step')

	-- Lowering the limit is lazy: nothing goes until the next step is recorded.
	fresh()
	for i, k in ipairs({ 'a', 'b', 'c' }) do push('move', k, k, 0, i) end
	fired = 0
	History:SetLimit(2)
	eq(History.limit, 2, 'the limit is lowered')
	eq(#History:Steps(), 3, 'but no step is thrown away yet')
	eq(fired, 0, 'and nothing fires')
	History:SetLimit(5)
	eq(#History:Steps(), 3, 'raising it keeps them')
	History:SetLimit(2)
	push('move', 'd', 'd', 0, 4)
	eq(#History:Steps(), 2, 'the next step trims, the oldest first')
	eq(History:Steps()[1].changes[1].where, 'c', 'the oldest dropped')
	eq(History:Position(), 2, 'position follows')
	History:SetLimit(0); eq(History.limit, 1, '0 is the minimum')
	History:SetLimit(5000); eq(History.limit, 1000, 'capped at 1000')
	History:SetLimit(1.6); eq(History.limit, 2, 'a whole number')
	eq(History.LIMIT_MIN, 1, 'min'); eq(History.LIMIT_MAX, 1000, 'max')

	fresh()
	History:SetLimit(2)
	for i, k in ipairs({ 'a', 'b', 'c' }) do push('move', k, k, 0, i) end
	eq(#History:Steps(), 2, 'a push over the limit trims')
	eq(History:Steps()[1].changes[1].where, 'b', 'the oldest dropped first')
end)

test('Undo and Redo write through the kind and run finish once per step; in combat they refuse and write nothing', function()
	fresh()
	store.a, store.b = 0, 0
	History:Push({ kind = 'bulk', label = 'Both',
		changes = { { kind = 'value', where = 'a', old = 1, new = 2 }, { kind = 'value', where = 'b', old = 5, new = 6 } } })
	store.a, store.b = 2, 6
	local ok = History:Undo()
	eq(ok, true, 'undone')
	eq(store.a, 1, 'a back'); eq(store.b, 5, 'b back')
	eq(table.concat(writes, ','), 'b,a', 'written in reverse order')
	eq(#finishes, 1, 'finish once')
	eq(finishes[1], 2, 'with both wheres')
	eq(History:Position(), 0, 'position')
	History:Redo()
	eq(store.a, 2, 'redone'); eq(store.b, 6, 'b redone')
	eq(table.concat(writes, ','), 'b,a,a,b', 'in order for a redo')
	eq(#finishes, 2, 'finish again')

	local count = #writes
	stub.in_combat = true
	local r, message = History:Undo()
	eq(r, false, 'refused in combat')
	eq(message, "Can't undo in combat.", 'its message')
	r, message = History:Redo()
	eq(message, "Can't redo in combat.", 'redo too')
	eq(#writes, count, 'nothing written')
	eq(History:Position(), 1, 'position kept')
	stub.in_combat = false
	eq(History:Redo(), false, 'nothing to redo')
	History:Undo()
	eq(History:Undo(), false, 'nothing to undo')
end)

test('a finish that errors is reported and the step still completes', function()
	fresh()
	History:RegisterKind('boom', {
		read = function(k) return store[k] end,
		write = function(k, v) store[k] = v end,
		finish = function() error('finish failed') end,
		name = function(k) return k end,
	})
	store.a = 2
	History:Push({ kind = 'move', label = 'x', changes = { { kind = 'boom', where = 'a', old = 1, new = 2 } } })
	local ok = History:Undo()
	eq(ok, true, 'undone')
	eq(store.a, 1, 'written')
	eq(#take_errors(), 1, 'the error reached the handler')
	eq(History:Position(), 0, 'position moved')
end)

test('a stale step is dropped with the older steps on its place, and nothing is written', function()
	fresh()
	push('move', 'a', 'a', 1, 2)
	push('move', 'b', 'b', 5, 6)
	push('move', 'a', 'a', 2, 3)
	store.a = 9
	local count = #writes
	local ok, message = History:Undo()
	eq(ok, false, 'refused')
	eq(message, 'a was changed since; its earlier steps are dropped.', 'its message')
	eq(#History:Steps(), 1, "only b's step is left")
	eq(History:Steps()[1].changes[1].where, 'b', 'it is b')
	eq(store.a, 9, 'a untouched')
	eq(#writes, count, 'nothing written')
	eq(History:Position(), 1, 'position follows')

	-- A stale redo, the same.
	fresh()
	push('move', 'a', 'a', 1, 2)
	push('move', 'a', 'a', 2, 3)
	History:Undo()
	store.a = 7
	local ok2, message2 = History:Redo()
	eq(ok2, false, 'a stale redo is refused')
	eq(message2, 'a was changed since; its earlier steps are dropped.', 'same message')
	eq(#History:Steps(), 0, 'both steps on a are gone')
end)

test('a mover-like thing that is gone is skipped and the rest of the step applies, and it is reported', function()
	fresh()
	local gone = {}
	History:RegisterKind('maybe', {
		read = function(k) return store[k] end,
		write = function(k, v) store[k] = v; writes[#writes + 1] = k end,
		name = function(k) return k end,
		missing = function(k) return gone[k] == true end,
	})
	store.a, store.z = 2, 2
	History:Push({ kind = 'bulk', label = 'both', changes = {
		{ kind = 'value', where = 'a', old = 1, new = 2 }, { kind = 'maybe', where = 'z', old = 1, new = 2 } } })
	gone.z = true
	local ok, message = History:Undo()
	eq(ok, true, 'applied')
	eq(store.a, 1, 'the part that exists')
	eq(store.z, 2, 'the missing part untouched')
	eq(message, "z isn't there now; skipped.", 'reported')
end)

test('a refused check drops the step, writes nothing and returns the reason', function()
	fresh()
	History:RegisterKind('picky', {
		read = function(k) return store[k] end,
		write = function(k, v) store[k] = v; writes[#writes + 1] = k end,
		check = function(k, v) if v == 1 then return false, 'No.' end return true end,
		name = function(k) return k end,
	})
	store.a = 2
	History:Push({ kind = 'move', label = 'x', changes = { { kind = 'picky', where = 'a', old = 1, new = 2 } } })
	local ok, message = History:Undo()
	eq(ok, false, 'refused')
	eq(message, 'No.', 'the reason')
	eq(#History:Steps(), 0, 'dropped')
	eq(#writes, 0, 'nothing written')
	eq(store.a, 2, 'untouched')
end)

test('JumpTo goes to any state and every step stays redoable until a new one', function()
	fresh()
	for i = 1, 4 do push('move', 'a' .. i, 'a' .. i, 0, i) end
	local ok = History:JumpTo(1)
	eq(ok, true, 'jumped')
	eq(History:Position(), 1, 'position 1')
	eq(store.a1, 1, 'a1 as after step 1'); eq(store.a2, 0, 'a2 undone'); eq(store.a4, 0, 'a4 undone')
	eq(#History:Steps(), 4, 'all still there')
	History:JumpTo(4)
	eq(History:Position(), 4, 'back at the top')
	eq(store.a4, 4, 'all back')
	History:JumpTo(0)
	eq(History:Position(), 0, 'before every step')
	eq(store.a1, 0, 'a1 undone')
	eq(History:JumpTo(9), false, 'no such step')
	-- It stops at the first refusal.
	History:JumpTo(4)
	store.a3 = 99
	local r, message = History:JumpTo(0)
	eq(r, false, 'refused midway')
	eq(message, 'a3 was changed since; its earlier steps are dropped.', 'why')
	eq(store.a4, 0, 'a4 was undone before it stopped')
end)

test('a long jump runs each kind\'s finish and HistoryChanged once, and ends where stepping one by one does', function()
	fresh()
	for i = 1, 4 do push('move', 'a' .. i, 'a' .. i, 0, i) end
	push('move', 'a1', 'a1', 1, 10)
	local function copy() local out = {} for k, v in pairs(store) do out[k] = v end return out end
	local function same(a, b)
		for k, v in pairs(a) do if b[k] ~= v then return false end end
		for k, v in pairs(b) do if a[k] ~= v then return false end end
		return true
	end
	-- One by one.
	for _ = 1, 5 do History:Undo() end
	local stepwise = copy()
	for _ = 1, 5 do History:Redo() end
	-- The same, as a jump.
	finishes, fired = {}, 0
	eq(History:JumpTo(0), true, 'jumped')
	eq(History:Position(), 0, 'to the start')
	eq(#finishes, 1, 'the kind finished once')
	eq(finishes[1], 4, 'with the places of every step, each once')
	eq(fired, 1, 'HistoryChanged fired once')
	check(same(copy(), stepwise), 'the same values as stepping one by one')
	finishes, fired = {}, 0
	History:JumpTo(5)
	eq(#finishes, 1, 'and forward: one finish'); eq(fired, 1, 'one HistoryChanged')
	eq(store.a1, 10, 'every step redone')
	-- A refusal part way still announces once, for what was walked.
	finishes, fired = {}, 0
	store.a3 = 99
	local ok = History:JumpTo(0)
	eq(ok, false, 'refused')
	eq(#finishes, 1, 'one finish for what was undone'); eq(fired, 1, 'one HistoryChanged')
	eq(store.a4, 0, 'a4 was undone')
	-- A single step still announces at once.
	fresh()
	push('move', 'a', 'a', 0, 1)
	fired = 0
	History:Undo()
	eq(fired, 1, 'Undo: one')
end)

test('Revert puts back one older step as a new step, only when nothing later touched its place and it is not stale', function()
	fresh()
	push('move', 'a', 'a', 1, 2)
	push('move', 'b', 'b', 5, 6)
	eq(History:CanRevert(1), true, 'a step nothing touched since')
	local ok = History:Revert(1)
	eq(ok, true, 'reverted')
	eq(store.a, 1, 'a back')
	eq(store.b, 6, 'b untouched')
	eq(#History:Steps(), 3, 'a new step')
	eq(History.Label(History:Steps()[3]), 'Reverted: Set a', 'its label')
	eq(History:Steps()[3].kind, 'revert', 'its kind')
	eq(History:Steps()[3].changes[1].old, 2, 'what was there')
	eq(History:Steps()[3].changes[1].new, 1, "the step's old")
	History:Undo()
	eq(store.a, 2, 'the revert can be undone')

	fresh()
	push('move', 'a', 'a', 1, 2)
	push('move', 'a', 'a', 2, 3)
	local can, why = History:CanRevert(1)
	eq(can, false, 'changed again')
	eq(why, 'Changed again later: go back to this point instead.', 'why')
	eq(select(2, History:Revert(1)), why, 'Revert says so')

	fresh()
	History:Push({ kind = 'bulk', label = 'Copy', changes = { { kind = 'value', where = 'a', old = 1, new = 2 } } })
	can, why = History:CanRevert(1)
	eq(can, false, 'a bulk step'); eq(why, "A copy can't be reverted on its own: go back to this point instead.", 'why')

	fresh()
	push('move', 'a', 'a', 1, 2)
	History:Undo()
	can, why = History:CanRevert(1)
	eq(can, false, 'an undone step'); eq(why, nil, 'shows no control: no reason')

	fresh()
	push('move', 'a', 'a', 1, 2)
	store.a = 8
	can, why = History:CanRevert(1)
	eq(can, false, 'stale'); eq(why, 'a was changed since.', 'why')
	eq(History:CanRevert(5), false, 'no such step')

	fresh()
	push('move', 'a', 'a', 1, 2)
	stub.in_combat = true
	eq(History:Revert(1), false, 'not in combat')
	eq(store.a, 2, 'nothing written')
end)

test('the history clears on a profile change, copy or reset, not on a theme change and not on leaving edit mode', function()
	fresh()
	local config = st.config
	local first = config:GetCurrentProfile()
	push('move', 'a', 'a', 1, 2)
	st:ThemeChanged()
	eq(#History:Steps(), 1, 'a theme change keeps it')
	EM:Activate()
	EM:Deactivate()
	eq(#History:Steps(), 1, 'leaving edit mode keeps it')
	config:SetProfile('HistoryOther')
	eq(#History:Steps(), 0, 'a profile change clears it')
	eq(History:Position(), 0, 'and the position')
	push('move', 'a', 'a', 1, 2)
	config:CopyProfile(first)
	eq(#History:Steps(), 0, 'a copy clears it')
	push('move', 'a', 'a', 1, 2)
	config:ResetProfile()
	eq(#History:Steps(), 0, 'a reset clears it')
	config:SetProfile(first)
end)

test('Same: numbers and their strings, nested tables, nil', function()
	local Same = History.Same
	eq(Same({ x = '12', y = { 1 } }, { x = 12, y = { 1 } }), true, 'a string number and a number')
	eq(Same(nil, false), false, 'nil is not false')
	eq(Same(nil, nil), true, 'nil is nil')
	eq(Same(1, 1.00001), true, 'noise under 1e-4')
	eq(Same(1, 1.1), false, 'a real difference')
	eq(Same({ 1 }, { 1, 2 }), false, 'an extra key')
	eq(Same({ a = 1 }, { b = 1 }), false, 'another key')
	eq(Same('a', 'b'), false, 'strings')
	eq(Same('abc', 'abc'), true, 'the same string')
	eq(Same(0, nil), false, '0 is not nil')
end)

------------------------------------------------------------ fix round 1

test('false and nil are values: undo writes old exactly, redo writes new, neither is stale when the store matches', function()
	local cases = {
		{ 'false to true', false, true }, { 'true to false', true, false },
		{ 'nil to a value', nil, 5 }, { 'a value to nil', 250, nil },
		{ 'false to nil', false, nil }, { 'nil to false', nil, false },
	}
	for _, case in ipairs(cases) do
		local label, old, new = case[1], case[2], case[3]
		fresh()
		local step = push('move', 'a', 'k', old, new)
		check(step ~= nil, label .. ': recorded')
		local ok, message = History:Undo()
		eq(ok, true, label .. ': undo succeeds (' .. tostring(message) .. ')')
		eq(store.k, old, label .. ': undo wrote old exactly')
		eq(History:Position(), 0, label .. ': position moved')
		ok, message = History:Redo()
		eq(ok, true, label .. ': redo succeeds (' .. tostring(message) .. ')')
		eq(store.k, new, label .. ': redo wrote new exactly')
		eq(#History:Steps(), 1, label .. ': the step is kept')
		-- Revert writes the step's old and records a revert holding it.
		local can = History:CanRevert(1)
		eq(can, true, label .. ': can revert')
		ok = History:Revert(1)
		eq(ok, true, label .. ': revert succeeds')
		eq(store.k, old, label .. ': revert wrote old exactly')
		eq(History:Steps()[2].changes[1].new, old, label .. ': the revert step holds old')
	end
end)

test('a stale redo or a refused one leaves the position right when an applied step sits below it', function()
	fresh()
	push('move', 'b', 'b', 5, 6)
	push('move', 'a', 'a', 1, 2)
	push('move', 'a', 'a', 2, 3)
	History:Undo()
	store.a = 7
	local ok = History:Redo()
	eq(ok, false, 'the redo is stale')
	eq(#History:Steps(), 1, 'the step and the older step on a are dropped')
	eq(History:Position(), 1, 'the unrelated applied step stays applied')
	eq(History:CanRedo(), false, 'nothing to redo')

	fresh()
	History:RegisterKind('nope', {
		read = function(k) return store[k] end, write = function(k, v) store[k] = v end,
		check = function(_, v) if v == 2 then return false, 'No.' end return true end, name = function(k) return k end,
	})
	push('move', 'b', 'b', 5, 6)
	store.c = 2
	History:Push({ kind = 'move', label = 'x', changes = { { kind = 'nope', where = 'c', old = 1, new = 2 } } })
	push('move', 'b', 'b', 6, 7)
	History:JumpTo(1)
	eq(select(2, History:Redo()), 'No.', 'a refused redo says why')
	eq(History:Position(), 1, 'the position stays')
	eq(#History:Steps(), 2, 'only the refused step is dropped')
end)

test('Clear fires HistoryChanged; undo and redo close the run; a gap of exactly MERGE_GAP merges', function()
	fresh()
	push('move', 'a', 'a', 1, 2)
	fired = 0
	History:Clear()
	eq(fired, 1, 'Clear fires')

	fresh()
	stub.time = 10
	push('nudge', 'a', 'a', 1, 2)
	History:Undo()
	eq(History:Steps()[1].open, nil, 'undo closed the run')
	History:Redo()
	eq(History:Steps()[1].open, nil, 'redo closed it too')
	stub.time = 10.2
	push('nudge', 'a', 'a', 2, 3)
	eq(#History:Steps(), 2, 'a nudge right after a redo is a new step')

	fresh()
	stub.time = 10
	push('nudge', 'a', 'a', 1, 2)
	stub.time = 11
	push('nudge', 'a', 'a', 2, 3)
	eq(#History:Steps(), 1, 'exactly MERGE_GAP later still merges')
end)

test('lowering the limit while steps are undone keeps the redo chain until the next step, which then trims without a gap', function()
	fresh()
	for i = 1, 6 do push('move', 'a', 'a', i - 1, i) end
	History:JumpTo(3)
	History:SetLimit(2)
	eq(#History:Steps(), 6, 'nothing trimmed yet')
	History:JumpTo(6)
	eq(store.a, 6, 'the whole redo chain still applies')
	History:JumpTo(3)
	push('move', 'a', 'a', 3, 30) -- discards the redo steps, then trims the oldest applied
	eq(#History:Steps(), 2, 'at the limit')
	eq(History:Position(), 2, 'both applied')
	History:Undo(); History:Undo()
	eq(store.a, 2, 'back to where step 2 left it (steps 1 and 2 were dropped)')
end)

test('SetLimit rejects NaN and non-numbers, rounds, and clamps to 1 and 1000', function()
	fresh()
	History:SetLimit(30)
	History:SetLimit(0 / 0); eq(History.limit, 30, 'NaN is rejected')
	History:SetLimit('abc'); eq(History.limit, 30, 'text is rejected')
	History:SetLimit(nil); eq(History.limit, 30, 'nil is rejected')
	History:SetLimit({}); eq(History.limit, 30, 'a table is rejected')
	History:SetLimit('12'); eq(History.limit, 12, 'a number typed as text is taken')
	History:SetLimit(-5); eq(History.limit, 1, 'below 1 is 1')
	History:SetLimit(5000); eq(History.limit, 1000, 'capped at 1000')
	History:SetLimit(math.huge); eq(History.limit, 1000, 'infinity is the cap')
	push('move', 'a', 'a', 0, 1)
	History:SetLimit(0 / 0)
	eq(History:Position(), 1, 'a rejected limit never touches the position')
end)

test('JumpTo refuses a non-integer or out-of-range index at once, writing nothing', function()
	fresh()
	push('move', 'a', 'a', 0, 1); push('move', 'b', 'b', 0, 1)
	for _, n in ipairs({ 1.5, -1, 3, 0 / 0, math.huge }) do
		local ok, message = History:JumpTo(n)
		eq(ok, false, tostring(n) .. ': refused')
		eq(message, 'No such step.', tostring(n) .. ': why')
	end
	eq(History:JumpTo('1'), false, 'text is refused')
	eq(#writes, 0, 'nothing written')
	eq(History:Position(), 2, 'position kept')
end)

test('a merge matches changes by their place, not by the identity of where', function()
	fresh()
	History:RegisterKind('tv', {
		read = function(w) return store[w.id] end, write = function(w, v) store[w.id] = v end,
		place = function(w) return 'tv:' .. w.id end, name = function(w) return w.id end,
	})
	local function nudge(old, new)
		store.x = new
		return History:Push({ kind = 'nudge', target = 't', label = 'n',
			changes = { { kind = 'tv', where = { id = 'x' }, old = old, new = new } } })
	end
	stub.time = 10
	nudge(1, 2)
	stub.time = 10.5
	nudge(2, 3)
	eq(#History:Steps(), 1, 'one step')
	eq(#History:Steps()[1].changes, 1, 'one change, not a duplicate')
	eq(History:Steps()[1].changes[1].old, 1, 'the first old')
	eq(History:Steps()[1].changes[1].new, 3, 'the latest new')
end)

test('a nudge that does not start where the run left off is a new step', function()
	fresh()
	stub.time = 10
	push('nudge', 'a', 'a', 1, 2)
	stub.time = 10.2
	push('nudge', 'a', 'a', 7, 8) -- something else moved it from 2 to 7 in between
	eq(#History:Steps(), 2, 'a new step')
	eq(History:Steps()[1].changes[1].new, 2, 'the run kept its own end')
end)

test('a write that errors rolls the step back: what was written is put back and placed, the step stays', function()
	fresh()
	local rolled = {}
	History:RegisterKind('fragile', {
		read = function(k) return store[k] end,
		write = function(k, v) if k == 'bad' and v == 1 then error('write failed') end store[k] = v end,
		finish = function(ws) rolled[#rolled + 1] = table.concat(ws, ',') end,
		name = function(k) return k end,
	})
	store.a, store.bad, store.c = 2, 2, 2
	History:Push({ kind = 'bulk', label = 'three', changes = {
		{ kind = 'fragile', where = 'a', old = 1, new = 2 },
		{ kind = 'fragile', where = 'bad', old = 1, new = 2 },
		{ kind = 'fragile', where = 'c', old = 1, new = 2 } } })
	local ok, message = History:Undo()
	eq(ok, false, 'refused')
	check(message and message:find('bad', 1, true), 'names what failed: ' .. tostring(message))
	eq(store.c, 2, 'c (written first) is put back')
	eq(store.a, 2, 'a was never written')
	eq(store.bad, 2, 'bad untouched')
	eq(History:Position(), 1, 'the step is still applied')
	eq(#History:Steps(), 1, 'and kept')
	eq(rolled[#rolled], 'c', 'the rolled-back part was placed again')
	eq(#take_errors(), 1, 'the error reached the handler once')
end)

test('Revert reports a failed write as a refusal: false and the message, the step stays applied, no step is added', function()
	fresh()
	local failing = false
	History:RegisterKind('fragile2', {
		read = function(k) return store[k] end,
		write = function(k, v) if failing then error('write failed') end store[k] = v end,
		name = function(k) return k end,
	})
	store.a = 2
	History:Push({ kind = 'move', target = 'a', label = 'Moved a', changes = {
		{ kind = 'fragile2', where = 'a', old = 1, new = 2 } } })
	failing = true
	local ok, message = History:Revert(1)
	eq(ok, false, 'refused')
	eq(message, "a couldn't be reverted; the step was put back.", 'with the message')
	eq(#History:Steps(), 1, 'no step was added')
	eq(History:Position(), 1, 'the step is still applied')
	eq(store.a, 2, 'the value is as it was')
	eq(#take_errors(), 1, 'the error was reported once')
	failing = false
	local reverted, why = History:Revert(1)
	eq(reverted, true, 'it works once the write does')
	eq(why, nil, 'a revertable step gives true and no reason')
	eq(store.a, 1, 'the old value is back')
	eq(#History:Steps(), 2, 'as a new step')
end)
