-- Edit mode's side of the history (SaftUI-Core/EditMode/moves.lua and the four
-- changes in mover.lua): a drag is one step, nudges merge into a run, Reset is
-- a step of its own, and Undo and Redo put a position back through the same
-- path a drag's commit uses (the mover's setPosition, then its apply).
--
-- Real: Core's helpers, edit mode's files and a real AceDB profile database
-- (tests/core/config_helpers.lua, under the /sui window's world). Movers are made through st:RegisterConfigMover
-- on stub frames; the mouse is stub.cursor_x/y and the clock stub.time.

load_test_file('core/options_window_helpers.lua') -- the window's world, on config_helpers'

local st = SaftUI
local EM = st.EditModeFrames
local History = EM.History

stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600) -- one UIParent unit per physical pixel
EM:Enable()

local SCALE = UIParent:GetEffectiveScale()

local function settings() return EM:GetSettings() end

-- A mover on a 100 x 50 frame whose position is config.position; apply places
-- the frame from it (through SafeReposition, as every real apply does) and
-- counts its calls. extra goes into the registration.
local function add_mover(key, label, extra)
	local frame = CreateFrame('Frame', 'EMMoves' .. key, UIParent)
	frame:SetSize(100, 50)
	local config = { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } }
	local calls = { apply = 0 }
	local function apply()
		calls.apply = calls.apply + 1
		local pos = config.position
		st:SafeReposition(frame, 'moves_test_' .. key, function()
			frame:ClearAllPoints()
			frame:SetPoint(pos.point, st:ResolveFrame(pos.frame) or UIParent, pos.rel_point or pos.point,
				tonumber(pos.x_off) or 0, tonumber(pos.y_off) or 0)
		end)
	end
	apply()
	calls.apply = 0
	local spec = { key = key, label = label, config = function() return config end, apply = apply }
	for field, value in pairs(extra or {}) do spec[field] = value end
	local mover = st:RegisterConfigMover(frame, spec)
	return mover, config, calls, frame
end

local movers = {}
local function reset_world()
	if EM.active then EM:Deactivate() end
	for key, mover in pairs(movers) do
		mover.overlay:Hide()
		EM.movers[key] = nil
	end
	movers = {}
	stub.in_combat = false
	stub.time = 100
	stub.cursor_x, stub.cursor_y = 500, 500
	stub.blocked = {}
	settings().snap_grid, settings().snap_frames = false, false
	History:SetLimit(50)
	History:Clear()
end

local function make(key, label, extra)
	local mover, config, calls, frame = add_mover(key, label, extra)
	movers[key] = mover
	return mover, config, calls, frame
end

-- A drag of dx UIParent units from press to release.
local function drag(mover, dx, dy)
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(mover)
	stub.cursor_x, stub.cursor_y = 500 + (dx or 0) * SCALE, 500 + (dy or 0) * SCALE
	EM:UpdateDrag(mover)
	stub.time = stub.time + 0.2
	EM:UpdateDrag(mover)
	EM:StopDrag(mover)
end

test('a drag from press to release is one step "Moved Player"; a click or a drag back to the start records nothing', function()
	reset_world()
	local p, config = make('player', 'Player')
	EM:Activate()
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(p)
	stub.cursor_x = 500 + 40 * SCALE
	EM:UpdateDrag(p)
	stub.time = stub.time + 0.2
	EM:UpdateDrag(p) -- a tick writes into the table getPosition returns
	EM:StopDrag(p)
	eq(#History:Steps(), 1, 'one step')
	local step = History:Steps()[1]
	eq(History.Label(step), 'Moved Player', 'its label')
	eq(step.kind, 'move', 'its kind')
	eq(step.target, 'player', 'its target')
	eq(step.changes[1].old.x_off, 0, 'old x')
	eq(step.changes[1].new.x_off, 40, 'new x')
	check(step.changes[1].old ~= config.position, "the old is not the table getPosition returns")
	check(step.changes[1].new ~= config.position, "nor is the new")

	reset_world()
	p, config = make('player', 'Player')
	EM:Activate()
	EM:StartDrag(p)
	EM:StopDrag(p)
	eq(#History:Steps(), 0, 'a click: none')
	drag(p, 30, 0)
	eq(#History:Steps(), 1, 'a drag')
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(p)
	stub.cursor_x = 500 - 30 * SCALE
	EM:UpdateDrag(p)
	EM:StopDrag(p)
	eq(config.position.x_off, 0, 'a drag back')
	eq(#History:Steps(), 2, 'that is a step of its own: it undoes the first')
	reset_world()
	p, config = make('player', 'Player')
	EM:Activate()
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(p)
	stub.cursor_x = 500 + 25 * SCALE
	EM:UpdateDrag(p)
	stub.cursor_x = 500
	EM:UpdateDrag(p)
	EM:StopDrag(p)
	eq(#History:Steps(), 0, 'a drag out and back in one go: none')
end)

test('a run of nudges under a second apart is one step, "Nudged Player by 3, 0"; selecting another, a drag or Exit starts a new one', function()
	reset_world()
	local p, config = make('player', 'Player')
	local q = make('target', 'Target')
	EM:Activate()
	EM:Select(p)
	for _ = 1, 3 do
		stub.time = stub.time + 0.3
		EM:Nudge(p, 'RIGHT')
	end
	eq(#History:Steps(), 1, 'one step')
	eq(History.Label(History:Steps()[1]), 'Nudged Player by 3, 0', 'the net offset')
	eq(History:Steps()[1].changes[1].old.x_off, 0, 'from where it began')
	eq(config.position.x_off, 3, 'three pixels')

	stub.time = stub.time + 0.3
	EM:Select(q); EM:Select(p)
	EM:Nudge(p, 'RIGHT')
	eq(#History:Steps(), 2, 'selecting another closed the run')

	drag(p, 20, 0)
	EM:Nudge(p, 'RIGHT')
	eq(#History:Steps(), 4, 'a drag between: a new step')

	EM:Deactivate()
	EM:Activate()
	EM:Select(p)
	EM:Nudge(p, 'RIGHT')
	EM:Deactivate()
	EM:Activate()
	EM:Select(p)
	EM:Nudge(p, 'RIGHT')
	eq(#History:Steps(), 6, 'Exit and enter again: a new step each time')
	stub.time = stub.time + 5
	EM:Nudge(p, 'UP')
	eq(#History:Steps(), 7, 'a gap over a second: a new step')
	eq(History.Label(History:Steps()[7]), 'Nudged Player by 0, 1', 'its label')
	EM:Nudge(p, 'DOWN')
	eq(#History:Steps(), 6, 'a nudge back to the start of the run: no step')
end)

test('leaving edit mode closes a run of nudges even when nothing is selected', function()
	reset_world()
	local p = make('player', 'Player')
	EM:Activate()
	EM:Nudge(p, 'RIGHT') -- nothing selected, as a caller outside the key catcher
	eq(History:Steps()[1].open, true, 'a run is open')
	EM:Deactivate()
	eq(History:Steps()[1].open, nil, 'Exit closed it')
	EM:Activate()
	EM:Nudge(p, 'RIGHT')
	eq(#History:Steps(), 2, 'the next nudge is a new step')
end)

test('Reset puts the default copy through setPosition and apply, is its own step, closes a run, and can be undone', function()
	reset_world()
	local defaults = { position = { point = 'TOP', frame = 'UIParent', rel_point = 'TOP', x_off = 0, y_off = -40 } }
	local p, config, calls = make('player', 'Player', { defaults = function() return defaults end })
	EM:Activate()
	EM:Select(p)
	EM:Nudge(p, 'RIGHT')
	calls.apply = 0
	local moved = 0
	EM:On('PositionChanged', function() moved = moved + 1 end)
	local ok, message = EM:Reset(p)
	eq(moved, 1, 'PositionChanged fired for the reset')
	eq(ok, true, 'reset')
	eq(message, 'Reset Player', 'its message')
	eq(#History:Steps(), 2, 'two steps')
	eq(History.Label(History:Steps()[2]), 'Reset Player', 'the second is the reset')
	eq(History:Steps()[2].kind, 'reset', 'its kind')
	eq(calls.apply, 1, 'apply ran')
	eq(config.position.y_off, -40, 'the default place')
	eq(config.position.point, 'TOP', 'the default point')
	check(config.position ~= defaults.position, 'the stored position is not the defaults table')
	EM:Nudge(p, 'RIGHT')
	eq(defaults.position.x_off, 0, 'a nudge after it leaves the defaults alone')
	eq(#History:Steps(), 3, 'a nudge after a reset is its own step: the reset never merges')
	History:Undo()
	History:Undo()
	eq(config.position.point, 'CENTER', 'undo of the reset: back to the nudged spot')
	eq(config.position.x_off, 1, 'with its offset')
	local fired = 0
	EM:On('PositionChanged', function() fired = fired + 1 end)
	History:Redo()
	eq(config.position.point, 'TOP', 'redo of the reset')
	eq(fired, 1, 'PositionChanged fired for the redo')
	check(calls.apply >= 3, 'apply ran for undo and redo too')
end)

test('CanReset says why not: none selected, no default, already there (strings and numbers alike)', function()
	reset_world()
	local ok, why = EM:CanReset(nil)
	eq(ok, false, 'none selected'); eq(why, 'Select a frame first.', 'why')
	local a = make('thing', 'Thing')
	ok, why = EM:CanReset(a)
	eq(ok, false, 'no default'); eq(why, 'Thing has no default place.', 'named')
	local b = make('reasoned', 'Reasoned', { noDefaultReason = 'Because.' })
	eq(select(2, EM:CanReset(b)), 'Because.', 'its own reason')
	local c, config = make('player', 'Player', {
		defaults = function() return { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } } end })
	config.position = { point = 'CENTER', x_off = '0', y_off = '0' }
	ok, why = EM:CanReset(c)
	eq(ok, false, 'already there'); eq(why, 'Player is already in its default place.', 'strings and numbers alike')
	config.position.x_off = 3
	eq(EM:CanReset(c), true, 'somewhere else')
	stub.in_combat = true
	ok, why = EM:CanReset(c)
	eq(ok, false, 'combat'); eq(why, "Can't reset in combat.", 'why')
	eq(EM:Reset(c), false, 'Reset refuses too')
	eq(config.position.x_off, 3, 'and changes nothing')
	eq(#History:Steps(), 0, 'records nothing')
end)

test('EM.SamePosition: points, the missing rel_point, the frame spellings, offsets as numbers; EM.CopyPosition is deep', function()
	local Same = EM.SamePosition
	eq(Same({ point = 'A', x_off = 1 }, { point = 'A', rel_point = 'A', frame = 'UIParent', x_off = '1', y_off = 0 }), true, 'same')
	eq(Same({ point = 'A', frame = UIParent }, { point = 'A' }), true, 'UIParent, a name and none are one')
	eq(Same({ point = 'A' }, { point = 'B' }), false, 'point')
	eq(Same({ point = 'A', rel_point = 'B' }, { point = 'A' }), false, 'rel_point')
	eq(Same({ point = 'A', frame = 'X' }, { point = 'A' }), false, 'frame')
	eq(Same({ point = 'A', x_off = 1 }, { point = 'A', x_off = 1.00001 }), true, 'float noise')
	eq(Same({ point = 'A', y_off = 1 }, { point = 'A', y_off = 1.5 }), false, 'a real difference')
	eq(Same(nil, nil), true, 'nil and nil'); eq(Same(nil, { point = 'A' }), false, 'nil and a position')
	local original = { point = 'A', nested = { 1 } }
	local copy = EM.CopyPosition(original)
	copy.nested[1] = 2; copy.point = 'B'
	eq(original.nested[1], 1, 'deep'); eq(original.point, 'A', 'a copy')
	eq(EM.MoveLabel('nudge', 'X', { x_off = 0, y_off = 0 }, { x_off = -2.26, y_off = 0.04 }), 'Nudged X by -2.3, 0', 'one decimal, no -0')
end)

test('undo of a move on a secure frame: refused in combat with nothing blocked; out of combat it moves through apply only', function()
	reset_world()
	local p, config, calls, frame = make('player', 'Player')
	frame.IsProtected = function() return true, true end
	EM:Activate()
	drag(p, 40, 0)
	eq(config.position.x_off, 40, 'dragged')
	calls.apply = 0
	stub.in_combat = true
	local ok, message = History:Undo()
	eq(ok, false, 'refused in combat')
	eq(message, "Can't undo in combat.", 'why')
	eq(config.position.x_off, 40, 'position unchanged')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(calls.apply, 0, 'apply not called')
	stub.in_combat = false
	ok = History:Undo()
	eq(ok, true, 'out of combat')
	eq(calls.apply, 1, 'apply called once')
	eq(config.position.x_off, 0, 'the position')
	eq(select(4, frame:GetPoint(1)), 0, 'the frame placed by apply (its SafeReposition)')
	eq(#stub.blocked, 0, 'still nothing blocked')
	eq(#History:Steps(), 1, 'the undo is not a new step')
	History:Redo()
	eq(select(4, frame:GetPoint(1)), 40, 'redo places it too')
	eq(#History:Steps(), 1, 'and records nothing')
end)

test('edit mode closing for combat mid-drag commits the drag and records it; a profile change mid-drag records nothing', function()
	reset_world()
	local p, config = make('player', 'Player')
	EM:Activate()
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(p)
	stub.cursor_x = 500 + 20 * SCALE
	EM:UpdateDrag(p)
	stub.fire_event('PLAYER_REGEN_DISABLED')
	eq(#History:Steps(), 1, 'one step')
	eq(History.Label(History:Steps()[1]), 'Moved Player', 'its label')
	eq(config.position.x_off, 20, 'committed')

	reset_world()
	p, config = make('player', 'Player')
	EM:Activate()
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(p)
	stub.cursor_x = 500 + 20 * SCALE
	EM:UpdateDrag(p)
	local first = st.config:GetCurrentProfile()
	st.config:SetProfile('HistoryMovesOther')
	eq(#History:Steps(), 0, 'dropped: no step')
	EM:StopDrag(p)
	eq(#History:Steps(), 0, 'and still none after the release')
	st.config:SetProfile(first)
end)

test('an undo that would anchor a frame to one now anchored to it is refused, dropped, and said in chat', function()
	reset_world()
	local p, pconfig, _, pframe = make('p', 'P')
	local q, _, _, qframe = make('q', 'Q')
	-- p's step restores an anchor to q's frame; q is anchored to p since.
	local old = { point = 'CENTER', frame = 'EMMovesq', rel_point = 'CENTER', x_off = 0, y_off = 0 }
	History:Push({ kind = 'move', target = 'p', label = 'Moved P', changes = {
		{ kind = 'position', where = 'p', old = old, new = EM.CopyPosition(pconfig.position) } } })
	qframe:ClearAllPoints()
	qframe:SetPoint('CENTER', pframe, 'CENTER')
	local said = {}
	local real = print
	print = function(...) said[#said + 1] = table.concat({ tostring((...)), select(2, ...) ~= nil and tostring(select(2, ...)) or nil }, ' ') end
	local ok, message = History:Undo()
	print = real
	eq(ok, false, 'refused')
	eq(message, 'Anchor would create a loop', 'the reason')
	eq(#History:Steps(), 0, 'the step is gone')
	check(table.concat(said, '|'):find('Anchor would create a loop', 1, true), 'printed to chat')
	eq(pconfig.position.frame, 'UIParent', 'the position is as it was')
end)

test('Reset refuses a default that would anchor a frame to one anchored to it, and writes nothing', function()
	reset_world()
	local e, econfig, _, eframe = make('echo', 'Echo')
	local f, fconfig, _, fframe = make('foxtrot', 'Foxtrot', {
		defaults = function() return { position = { point = 'LEFT', frame = 'EMMovesecho', rel_point = 'RIGHT', x_off = 7, y_off = 0 } } end,
	})
	-- echo is anchored to foxtrot (by the player, in /sui); foxtrot's default anchors to echo.
	econfig.position = { point = 'RIGHT', frame = 'EMMovesfoxtrot', rel_point = 'LEFT', x_off = -7, y_off = 0 }
	e.def.apply()
	fconfig.position.x_off = 30
	f.def.apply()
	EM:Activate()
	EM:Select(f)
	local ok, why = EM:CanReset(f)
	eq(ok, false, 'CanReset refuses')
	eq(why, "Foxtrot can't go back to its default place: Anchor would create a loop.", 'with the reason')
	local before = fconfig.position.x_off
	ok = EM:Reset(f)
	eq(ok, false, 'Reset refuses too')
	eq(fconfig.position.x_off, before, 'the profile is unchanged')
	eq(fconfig.position.frame, 'UIParent', 'still anchored where it was')
	eq(#History:Steps(), 0, 'no step recorded')
	eq(fframe:GetNumPoints(), 1, 'the frame is still placed')
	eq(#take_errors(), 0, 'no error')
end)

test('a mover that no longer exists is skipped, not an error', function()
	reset_world()
	local p, config = make('player', 'Player')
	EM:Activate()
	drag(p, 40, 0)
	EM.movers.player = nil
	local ok, message = History:Undo()
	eq(ok, true, 'the step still applies')
	eq(message, "player isn't there now; skipped.", 'and says what was skipped')
	eq(config.position.x_off, 40, 'nothing written to it')
	eq(#take_errors(), 0, 'no error')
	EM.movers.player = p
end)

test('EM:RecordMove names the mover when its label is read later', function()
	reset_world()
	local p, config = make('player', 'Player')
	local before = EM.CopyPosition(config.position)
	config.position.x_off = 2
	local step = EM:RecordMove(p, 'nudge', before)
	eq(History.Label(step), 'Nudged Player by 2, 0', 'a nudge reads its net offset')
	eq(step.open, true, 'a nudge opens a run')
end)

------------------------------------------------------------ fix round 1

test('a nudge whose apply errors is recorded, closes the run and leaves undo working', function()
	reset_world()
	local failing = false
	local p, config, calls = make('player', 'Player')
	local real = p.def.apply
	p.def.apply = function() if failing then error('apply failed') end real() end
	EM:Activate()
	drag(p, 10, 0)
	EM:Nudge(p, 'RIGHT')
	failing = true
	EM:Nudge(p, 'RIGHT') -- the error is the handler's, not the key catcher's
	check(#take_errors() >= 1, 'the error reached the handler')
	eq(config.position.x_off, 12, 'the position was stored')
	eq(#History:Steps(), 2, 'the nudge run is one step, recorded with the erroring nudge')
	eq(History:Steps()[2].changes[1].new.x_off, 12, 'its new is what was stored')
	eq(History:Steps()[2].open, nil, 'and the run is closed')
	failing = false
	local ok = History:Undo()
	eq(ok, true, 'undo is not refused')
	eq(config.position.x_off, 10, 'back to where the nudges began')
	eq(#History:Steps(), 2, 'earlier steps survive')
end)

test('the position kind stores copies: later drags never reach the steps', function()
	reset_world()
	local p, config = make('player', 'Player')
	EM:Activate()
	drag(p, 40, 0)
	History:Undo()
	drag(p, 15, 0) -- its ticks write into the stored table
	eq(History:Steps()[1].changes[1].old.x_off, 0, "the step's old is untouched")
	eq(History:Steps()[1].changes[1].new.x_off, 15, 'and the new step has its own')
	History:Undo()
	History:Redo()
	History:Undo()
	eq(config.position.x_off, 0, 'undo goes back to the start')
	check(config.position ~= History:Steps()[1].changes[1].old, 'the stored table is not the step\'s own')
end)

test('CanReset: combat does not hide the other reasons', function()
	reset_world()
	local a = make('thing', 'Thing')
	stub.in_combat = true
	eq(select(2, EM:CanReset(a)), 'Thing has no default place.', 'no default first')
	local b = make('reasoned', 'Reasoned', { noDefaultReason = 'Because.' })
	eq(select(2, EM:CanReset(b)), 'Because.', 'its own reason first')
	local c = make('player', 'Player', { defaults = function()
		return { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } } end })
	eq(select(2, EM:CanReset(c)), 'Player is already in its default place.', 'already there first')
end)

test('a position set from outside the history makes the next undo stale, with the real position kind', function()
	reset_world()
	local p, config = make('player', 'Player')
	EM:Activate()
	drag(p, 40, 0)
	config.position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 99, y_off = 0 } -- /sui
	local ok, message = History:Undo()
	eq(ok, false, 'refused')
	eq(message, 'Player was changed since; its earlier steps are dropped.', 'why')
	eq(config.position.x_off, 99, 'nothing written')
	eq(#History:Steps(), 0, 'dropped')
end)

test('a position set from outside between two nudges ends the run', function()
	reset_world()
	local p, config = make('player', 'Player')
	EM:Activate()
	EM:Nudge(p, 'RIGHT')
	config.position.y_off = 77 -- a /sui change, within a second
	EM:Nudge(p, 'RIGHT')
	eq(#History:Steps(), 2, 'the second nudge is its own step')
	eq(History.Label(History:Steps()[2]), 'Nudged Player by 1, 0', 'and does not carry the /sui change')
	History:Undo()
	eq(config.position.y_off, 77, "undo leaves the /sui change alone")
end)

test('a mover that has no saved position goes back to none, not to the position it invents', function()
	reset_world()
	local saved
	local frame = CreateFrame('Frame', 'EMMovesInvented', UIParent)
	frame:SetSize(100, 50)
	local function apply()
		local pos = saved or { point = 'CENTER', x_off = 5, y_off = 5 }
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.point, pos.x_off, pos.y_off)
	end
	apply()
	local mover = st:RegisterMover('invented', {
		frame = frame, label = 'Invented', apply = apply,
		getPosition = function() return saved or { point = 'CENTER', x_off = 5, y_off = 5 } end,
		getSavedPosition = function() return saved end,
		setPosition = function(position) saved = position end,
	})
	movers.invented = mover
	EM:Activate()
	EM:Nudge(mover, 'RIGHT')
	check(saved ~= nil, 'the nudge saved a position')
	eq(History.Label(History:Steps()[1]), 'Nudged Invented by 1, 0', 'its label reads the offset from the invented spot')
	History:Undo()
	eq(saved, nil, 'undo clears the saved position again')
	eq(select(4, frame:GetPoint(1)), 5, 'the frame is at the invented spot')
	History:Redo()
	eq(saved.x_off, 6, 'redo saves it')
	eq(EM:Reset(mover), false, 'no default')
end)

test('a random run of moves, nudges, resets, undos, redos and jumps goes back to the start and forward to the end exactly', function()
	reset_world()
	History:SetLimit(1000)
	local seed = 12345
	local function rand(n) -- a small deterministic generator
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed % n + 1
	end
	local defaults = { position = { point = 'TOP', frame = 'UIParent', rel_point = 'TOP', x_off = 0, y_off = -40 } }
	local list, configs = {}, {}
	for i = 1, 3 do
		local m, config = make('rm' .. i, 'RM' .. i, i ~= 3 and { defaults = function() return defaults end } or nil)
		list[i], configs[i] = m, config
	end
	configs[2].position = { point = 'BOTTOM', x_off = '12', y_off = 3 } -- an older profile: strings, missing fields
	local function snapshot()
		local out = {}
		for i = 1, 3 do
			local pos = configs[i].position
			local parts = {}
			for _, f in ipairs({ 'point', 'frame', 'rel_point', 'x_off', 'y_off' }) do
				parts[#parts + 1] = f .. '=' .. type(pos[f]) .. ':' .. tostring(pos[f])
			end
			out[i] = table.concat(parts, ',')
		end
		return table.concat(out, '|')
	end
	EM:Activate()
	local start = snapshot()
	for _ = 1, 300 do
		local m = list[rand(3)]
		local op = rand(8)
		stub.time = stub.time + rand(14) / 10
		if op <= 2 then drag(m, rand(60) - 30, rand(40) - 20)
		elseif op <= 4 then EM:Select(m); EM:Nudge(m, ({ 'UP', 'DOWN', 'LEFT', 'RIGHT' })[rand(4)], rand(4) == 1)
		elseif op == 5 then EM:Reset(m)
		elseif op == 6 then History:Undo()
		elseif op == 7 then History:Redo()
		else History:JumpTo(rand(#History:Steps() + 1) - 1) end
	end
	local position = History:Position()
	local finish = snapshot()
	eq(#take_errors(), 0, 'no errors')
	eq(History:JumpTo(0), true, 'jumped to the start')
	eq(snapshot(), start, 'undo of everything is the start, field for field')
	eq(History:JumpTo(position), true, 'jumped back')
	eq(snapshot(), finish, 'redo of everything is the end, field for field')
end)
