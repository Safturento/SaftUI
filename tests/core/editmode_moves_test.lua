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
