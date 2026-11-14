-- A jump in the history (History:JumpTo) against stepping one by one: the same
-- stored positions, the same refusals, the same frames placed, where steps
-- change anchors (a Reset onto a default that names another frame, an anchor
-- set in /sui between steps), which the position kind's check reads from the
-- frames themselves. And a jump that errors leaves nothing behind.
--
-- Real: Core's helpers, edit mode's files and bar, a real AceDB profile
-- database; the movers are on stub frames placed from a table, as a real
-- apply does.

load_test_file('core/options_window_helpers.lua')
load_editmode_bar()
local st = SaftUI
local EM = st.EditModeFrames
local History = EM.History
EM:Enable()
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
stub.screen_width, stub.screen_height = 1920, 1080
UIParent:SetScale(768 / 1080)

st.Print = function() end -- a refused anchor says so in chat; the walks make hundreds

local N = 6
local stored, defaults, frames, movers = {}, {}, {}, {}

local function P(frame, x, y)
	return { point = 'CENTER', frame = frame, rel_point = 'CENTER', x_off = x or 0, y_off = y or 0 }
end

for i = 1, N do
	local f = CreateFrame('Frame', 'EMJump' .. i, UIParent)
	f:SetSize(60, 30)
	frames[i] = f
	stored[i] = { position = P('UIParent', i * 70 - 300, 0) }
	defaults[i] = P('UIParent', 0, 0)
	local function apply()
		local pos = stored[i].position
		st:SafeReposition(f, 'jump_test_' .. i, function()
			f:ClearAllPoints()
			f:SetPoint(pos.point, st:ResolveFrame(pos.frame) or UIParent, pos.rel_point, pos.x_off, pos.y_off)
		end)
	end
	movers[i] = st:RegisterConfigMover(f, {
		key = 'jump' .. i, label = 'M' .. i, config = function() return stored[i] end, apply = apply,
		defaults = function() return { position = st.tablecopy(defaults[i], true) } end,
	})
end

local function name(i) return 'EMJump' .. i end

local function apply_all()
	for i = 1, N do frames[i]:ClearAllPoints() end
	for i = 1, N do xpcall(movers[i].def.apply, function() end) end
end

local function set_stored(i, pos) stored[i].position = st.tablecopy(pos, true) end

local function unplaced()
	local n = 0
	for i = 1, N do if frames[i]:GetNumPoints() == 0 then n = n + 1 end end
	return n
end

-- Every stored position, every field.
local function state()
	local out = {}
	for i = 1, N do
		local p = stored[i].position
		out[#out + 1] = ('%d:%s/%s/%s/%s/%s'):format(i, tostring(p.point), tostring(p.frame), tostring(p.rel_point),
			tostring(p.x_off), tostring(p.y_off))
	end
	return table.concat(out, ' ')
end

-- How many movers' stored anchors lead back to themselves.
local function loops()
	local n = 0
	for i = 1, N do
		local seen, cur = {}, i
		while cur do
			if seen[cur] then n = n + 1 break end
			seen[cur] = true
			local frame = stored[cur].position.frame
			cur = frame and tonumber(tostring(frame):match('^EMJump(%d+)$')) or nil
		end
	end
	return n
end

local function fresh()
	EM:Deactivate()
	stub.in_combat = false
	History:SetLimit(1000)
	History:Clear()
	for i = 1, N do
		set_stored(i, P('UIParent', i * 70 - 300, 0))
		defaults[i] = P('UIParent', 0, 0)
	end
	apply_all()
	EM:Activate()
	take_errors()
	stub.time = 1000
end

-- To step target, by one jump or by Undo and Redo one at a time; what it
-- leaves, and what it said.
local function walk(use_jump, target)
	local ok, message = true, nil
	if use_jump then
		ok, message = History:JumpTo(target)
	else
		while History:Position() ~= target do
			ok, message = (History:Position() > target and History.Undo or History.Redo)(History)
			if not ok then break end
		end
	end
	return {
		ok = ok, message = message, state = state(), position = History:Position(), steps = #History:Steps(),
		unplaced = unplaced(), loops = loops(), errors = #take_errors(),
	}
end

local function same(a, b, what)
	for _, field in ipairs({ 'ok', 'message', 'state', 'position', 'steps', 'unplaced', 'loops', 'errors' }) do
		eq(tostring(a[field]), tostring(b[field]), what .. ': ' .. field)
	end
end

------------------------------------------------------------------ hand-built

test('a jump that two Undos reach: an older step is valid once a later one is undone and placed', function()
	local function run(use_jump)
		fresh()
		-- 1 is anchored to 2 by the player; 1's default is UIParent, 2's anchors to 1.
		set_stored(1, P(name(2), 70, 0)); apply_all()
		defaults[1] = P('UIParent', 0, 0); defaults[2] = P(name(1), 0, -40)
		eq(EM:Reset(movers[1]), true, 'reset 1')
		stub.time = stub.time + 2
		eq(EM:Reset(movers[2]), true, 'reset 2')
		stub.time = stub.time + 2
		return walk(use_jump, 0)
	end
	local by_steps, by_jump = run(false), run(true)
	eq(by_steps.ok, true, 'two Undos work')
	eq(by_jump.ok, true, 'so does the jump')
	eq(by_jump.position, 0, 'to the start')
	eq(by_jump.steps, 2, 'no step dropped')
	same(by_steps, by_jump, 'R')
end)

test('a jump refuses an anchor set in /sui between two Resets, as stepping does, and saves no loop', function()
	local function run(use_jump)
		fresh()
		set_stored(1, P(name(2), 70, 0)); apply_all()
		defaults[1] = P('UIParent', 0, 0); defaults[2] = P('UIParent', 0, 0)
		eq(EM:Reset(movers[1]), true, 'reset 1')
		stub.time = stub.time + 2
		set_stored(2, P(name(1), 0, -40)); apply_all() -- /sui: 2 on 1, valid now
		eq(EM:Reset(movers[2]), true, 'reset 2')
		stub.time = stub.time + 2
		return walk(use_jump, 0)
	end
	local by_steps, by_jump = run(false), run(true)
	eq(by_steps.ok, false, 'stepping is refused at the second Undo')
	eq(by_jump.ok, false, 'so is the jump')
	eq(by_jump.loops, 0, 'no loop saved')
	eq(by_jump.unplaced, 0, 'every frame still placed')
	same(by_steps, by_jump, 'A')
end)

test('a jump places every step but fires PositionChanged once per mover and HistoryChanged once', function()
	fresh()
	for _ = 1, 3 do
		EM:Nudge(movers[1], 'RIGHT'); stub.time = stub.time + 2
		EM:Nudge(movers[2], 'UP'); stub.time = stub.time + 2
	end
	eq(#History:Steps(), 6, 'six steps')
	local moved, fired = {}, 0
	EM:On('PositionChanged', function(mover) moved[mover.key] = (moved[mover.key] or 0) + 1 end)
	EM:On('HistoryChanged', function() fired = fired + 1 end)
	eq(History:JumpTo(0), true, 'jumped')
	eq(moved.jump1, 1, 'mover 1 announced once')
	eq(moved.jump2, 1, 'mover 2 announced once')
	eq(fired, 1, 'HistoryChanged once')
	eq(stored[1].position.x_off, -230, 'mover 1 is back')
	eq(frames[1]:GetNumPoints(), 1, 'and placed')
end)

------------------------------------------------------------------ seeded

local seed
local function rnd(n) seed = (seed * 1103515245 + 12345) % 2147483648 return seed % n + 1 end

-- A random history of nudges, Resets, /sui anchor edits and Undos, on movers
-- with random defaults (a third anchored to another mover).
local function replay(s, actions)
	fresh()
	seed = s
	for i = 1, N do
		if rnd(3) == 1 then
			local j = rnd(N)
			if j ~= i then defaults[i] = P(name(j), 0, -40) end
		end
	end
	for _ = 1, actions do
		local kind, i = rnd(10), rnd(N)
		if kind <= 4 then
			EM:Nudge(movers[i], ({ 'UP', 'DOWN', 'LEFT', 'RIGHT' })[rnd(4)], rnd(2) == 1)
		elseif kind <= 7 then
			EM:Reset(movers[i])
		elseif kind <= 9 then
			local j = rnd(N)
			if j ~= i and st:ValidateAnchor(frames[i], name(j)) then
				local p = stored[i].position
				set_stored(i, P(name(j), p.x_off, p.y_off)); apply_all()
			end
		elseif History:CanUndo() then
			History:Undo()
		end
		stub.time = stub.time + 2
	end
	take_errors()
end

test('over 150 seeded histories a jump and stepping one by one give the same positions and refusals', function()
	local differ, jumps = 0, 0
	local first
	for s = 1, 150 do
		for _, direction in ipairs({ 'back', 'forward' }) do
			local function run(use_jump)
				replay(s, 30)
				if direction == 'back' then return walk(use_jump, 0) end
				while History:CanUndo() do if not History:Undo() then break end end
				take_errors()
				return walk(use_jump, #History:Steps())
			end
			local by_steps, by_jump = run(false), run(true)
			jumps = jumps + 1
			for _, field in ipairs({ 'ok', 'message', 'state', 'position', 'steps', 'unplaced', 'loops', 'errors' }) do
				if tostring(by_steps[field]) ~= tostring(by_jump[field]) then
					differ = differ + 1
					first = first or ('seed %d %s: %s: stepping %s, jump %s'):format(s, direction, field,
						tostring(by_steps[field]), tostring(by_jump[field]))
					break
				end
			end
		end
	end
	eq(jumps, 300, 'walks made')
	eq(differ, 0, 'walks that differ' .. (first and (' (first: ' .. first .. ')') or ''))
end)

------------------------------------------------------------------ an error

test('an error inside a jump is reported once and leaves the history as it was: Undo and Redo place frames and fire as normal', function()
	local store, boom = {}, false
	local finishes, fired, moved = 0, 0, 0
	History:RegisterKind('jump_test', {
		read = function(w) if boom and w == 'b' then error('read failed') end return store[w] end,
		write = function(w, v) store[w] = v end,
		finish = function() finishes = finishes + 1 end,
		name = function(w) return w end,
	})
	local function push(w, a, b)
		store[w] = b
		History:Push({ kind = 'move', target = w, label = w, changes = { { kind = 'jump_test', where = w, old = a, new = b } } })
		stub.time = stub.time + 2
	end
	fresh()
	EM:On('HistoryChanged', function() fired = fired + 1 end)
	push('a', 0, 1); push('b', 0, 1); push('c', 0, 1)
	boom = true
	take_errors()
	finishes, fired = 0, 0
	local ok, message = History:JumpTo(0)
	eq(ok, false, 'the jump is refused')
	eq(type(message), 'string', 'with a message')
	eq(#take_errors(), 1, 'the error is reported once')
	check(fired >= 1, 'what was held back is announced')
	boom = false
	finishes, fired = 0, 0
	local pos = History:Position()
	eq(History:Undo(), true, 'a later Undo works')
	eq(finishes, 1, 'and runs its finish')
	eq(fired, 1, 'and fires HistoryChanged')
	finishes, fired = 0, 0
	eq(History:Redo(), true, 'Redo works')
	eq(finishes, 1, 'and runs its finish')
	eq(fired, 1, 'and fires HistoryChanged')
	eq(History:Position(), pos, 'back where it was')
	-- And a position step still places its frame and tells the bar.
	History:Clear()
	local mover = movers[1]
	local moved_count = 0
	EM:On('PositionChanged', function() moved_count = moved_count + 1 end)
	local before = EM.SavedPosition(mover)
	EM:Nudge(mover, 'RIGHT')
	moved_count = 0
	eq(History:Undo(), true, 'Undo of a nudge')
	eq(moved_count, 1, 'PositionChanged fires')
	eq(stored[1].position.x_off, before.x_off, 'the position is back')
end)
