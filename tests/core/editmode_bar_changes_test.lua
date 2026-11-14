-- The edit mode bar's changes group and the History list (SaftUI-Core/EditMode/
-- Bar/barchanges.lua, historylist.lua): Undo, Redo, History and Reset, their
-- states and tooltips, the status line that says what they did, the list of
-- steps (newest first, a row goes back to that point, a row's revert, the
-- scroll, the length box, Esc), the history_limit setting, and the whole-pixel
-- layout of the list under each theme.
--
-- Real: the /sui window's world (core/options_window_helpers.lua), edit mode's
-- files and the bar's (load_editmode_bar), a real AceDB profile. Movers are made
-- through st:RegisterConfigMover on bare frames, with defaults. The mouse is
-- played by stub.cursor_x/y and firing scripts (stub.click, stub.fire_script;
-- the game's second argument to OnEnter and OnLeave, motion, is passed as
-- true), the clock by stub.time and stub.run_timers.

local P = load_test_file('lib/pixels.lua')

local H, st, EM, W, History

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, W = st.EditModeFrames, st.OptionsWidgets
	History = EM.History
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local settings, control, frame_of, set_screen, look = EMH.settings, EMH.control, EMH.frame_of, EMH.set_screen, EMH.look

set_screen(1920, 1080)
local SCALE = UIParent:GetEffectiveScale()

local function rgb(color) return string.format('%.2f,%.2f,%.2f', color:GetRGB()) end
local function colors() return st.config.profile.colors end
-- The colour a colour texture is filled with, as r,g,b and its alpha.
local function fill(texture)
	local c = stub.state(texture).color_texture
	return string.format('%.2f,%.2f,%.2f', c[1], c[2], c[3]), c[4]
end


-- The tooltip's lines as they are added: { text, color } each, title first.
local lines = {}
local realAddLine
local function watch_tooltip()
	if realAddLine then return end
	realAddLine = GameTooltip.AddLine
	GameTooltip.AddLine = function(self, text, r, g, b, wrap)
		lines[#lines + 1] = { text = text, color = r and string.format('%.2f,%.2f,%.2f', r, g, b) or nil }
		return realAddLine(self, text, r, g, b, wrap)
	end
end
local function hover(owner)
	watch_tooltip()
	lines = {}
	stub.fire_script(owner, 'OnEnter', true)
end
local function unhover(owner) stub.fire_script(owner, 'OnLeave', true) end

-- Whether the tooltip is up and is owner's.
local function tip_on(owner) return GameTooltip:IsShown() and GameTooltip:IsOwned(owner) end

local added = {}

-- A mover on a 100 x 50 frame, its position in config.position, a default of
-- the screen's middle; apply places the frame from it and counts its calls.
local function add_mover(key, label, extra)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	local config = { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } }
	local calls = { apply = 0 }
	local function apply()
		calls.apply = calls.apply + 1
		local pos = config.position
		st:SafeReposition(frame, 'bar_changes_' .. key, function()
			frame:ClearAllPoints()
			frame:SetPoint(pos.point, st:ResolveFrame(pos.frame) or UIParent, pos.rel_point or pos.point,
				tonumber(pos.x_off) or 0, tonumber(pos.y_off) or 0)
		end)
	end
	apply()
	calls.apply = 0
	local spec = {
		key = key, label = label, config = function() return config end, apply = apply,
		defaults = function() return { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } } end,
	}
	for field, value in pairs(extra or {}) do spec[field] = value end
	local mover = st:RegisterConfigMover(frame, spec)
	added[key] = true
	return mover, config, calls, frame
end

local function reset()
	if EM.active then EM:Deactivate() end
	for key in pairs(added) do
		local mover = EM.movers[key]
		if mover then mover.overlay:Hide() end
		EM.movers[key] = nil
		added[key] = nil
	end
	local s = settings()
	s.grid, s.snap_grid, s.snap_frames, s.coordinates, s.dim = false, false, false, false, true
	s.show_hidden, s.show_disabled, s.hidden_modules = true, false, {}
	s.history_limit = 50
	History:SetLimit(50)
	History:Clear()
	EM:SetFilter('')
	EM:SetBarStatus('')
	stub.in_combat = false
	stub.size_noise = 0
	stub.time = 1000
	stub.cursor_x, stub.cursor_y = 500, 500
	set_screen(1920, 1080)
	look('thick')
	H.close_all()
	local list = EM.historyList
	if list then list:Hide() end
	take_errors()
end

-- A drag of dx, dy UIParent units from press to release.
local function drag(mover, dx, dy)
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(mover)
	stub.cursor_x, stub.cursor_y = 500 + (dx or 0) * SCALE, 500 + (dy or 0) * SCALE
	EM:UpdateDrag(mover)
	stub.time = stub.time + 0.2
	EM:UpdateDrag(mover)
	EM:StopDrag(mover)
	stub.time = stub.time + 2 -- the next step is its own
end

local function status() return EM.statusText and EM.statusText:GetText() or '' end
local function labels(list)
	local out = {}
	for i, row in ipairs(list.rows) do
		if row:IsShown() then out[#out + 1] = row.label:GetText() end
	end
	return out
end

------------------------------------------------------------------ the group

test('the changes group: Undo, Redo, History and Reset, at the right, before Options, with the Lucide icons', function()
	reset()
	EM:Activate()
	local keys = {}
	for _, key in ipairs({ 'undo', 'redo', 'history', 'reset' }) do
		local c = control(key)
		check(c and c.frame and c.Lay, key .. ' is a control')
		eq(c.group.key, 'changes', key .. ': in the changes group')
		eq(c.group.side .. c.group.order, 'right80', key .. ': right, order 80')
		eq(c.section, 'changes', key .. ': section')
		eq(c:Lay(0, false), 26, key .. ': 26 wide')
		keys[#keys + 1] = frame_of(key):GetLeft()
	end
	for i = 2, #keys do check(keys[i] > keys[i - 1], 'left to right: ' .. i) end
	check(frame_of('options'):GetLeft() > keys[4], 'Options after Reset')
	eq(frame_of('undo').icon:GetTexture(), st.icons.undo2, 'undo-2')
	eq(frame_of('redo').icon:GetTexture(), st.icons.redo2, 'redo-2')
	eq(frame_of('history').icon:GetTexture(), st.icons.history, 'history')
	eq(frame_of('reset').icon:GetTexture(), st.icons.rotateCcw, 'rotate-ccw')
	for _, key in ipairs({ 'undo', 'redo', 'history', 'reset' }) do
		local frame = frame_of(key)
		eq(frame:GetFrameLevel(), 9502, key .. ': two over the bar')
		local _, _, _, _, y = frame:GetPoint(1)
		eq(y, -7, key .. ': centred on whole pixels')
	end
	reset()
end)

test('Undo, Redo and Reset are enabled by what they can do, and their tooltips name the mover they will move', function()
	reset()
	local player = add_mover('player', 'Player')
	EM:Activate()
	local undo, redo, rst = frame_of('undo'), frame_of('redo'), frame_of('reset')
	check(undo.disabled and redo.disabled and rst.disabled, 'empty: all three are off')
	hover(undo)
	eq(lines[1].text, 'Undo', 'Undo titled')
	eq(lines[2].text, 'Nothing to undo.', 'and says why')
	eq(lines[2].color, rgb(colors().text.red), 'in red')
	unhover(undo)
	hover(redo)
	eq(lines[1].text, 'Redo', 'Redo titled')
	eq(lines[2].text, 'Nothing to redo.', 'and says why')
	eq(lines[2].color, rgb(colors().text.red), 'in red')
	unhover(redo)
	hover(rst)
	eq(lines[1].text, 'Reset', 'Reset titled')
	eq(lines[2].text, 'Select a frame first.', 'with no selection')
	eq(lines[2].color, rgb(colors().text.red), 'in red')
	unhover(rst)

	drag(player, 40, 0)
	check(not undo.disabled and redo.disabled, 'a drag: Undo on, Redo off')
	hover(undo)
	eq(lines[1].text, 'Undo', 'title')
	eq(lines[2].text, 'Puts Player back where it was before.', 'it names the mover')
	eq(lines[2].color, rgb(colors().text.normal), 'in the normal colour')
	unhover(undo)
	check(rst.disabled, 'still nothing selected: Reset is off')
	EM:Select(player)
	check(not rst.disabled, 'select it: Reset is on')
	hover(rst)
	eq(lines[2].text, 'Player goes back to its default place.', "Reset's line")
	unhover(rst)

	stub.click(undo)
	check(undo.disabled and not redo.disabled, 'undone: Redo on')
	hover(redo)
	eq(lines[2].text, 'Moves Player again.', "Redo's line")
	unhover(redo)
	check(rst.disabled, 'Player is at its default again: Reset is off')
	hover(rst)
	eq(lines[2].text, 'Player is already in its default place.', 'and says so')
	eq(lines[2].color, rgb(colors().text.red), 'in red')
	unhover(rst)

	-- A step with no mover to name says what it is.
	History:Clear()
	History:Push({ kind = 'bulk', label = 'Copied A to B', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 5, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	hover(undo)
	eq(lines[2].text, 'Undoes Copied A to B.', 'a step with no target: its label')
	unhover(undo)
	History:Undo()
	hover(redo)
	eq(lines[2].text, 'Redoes Copied A to B.', "Redo's, the same way")
	unhover(redo)
	reset()
end)

test('a tooltip that is showing follows the history', function()
	reset()
	local player = add_mover('player', 'Player')
	EM:Activate()
	local undo = frame_of('undo')
	hover(undo)
	eq(lines[2].text, 'Nothing to undo.', 'nothing yet')
	lines = {}
	History:Push({ kind = 'move', target = 'player', label = 'Moved Player', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 5, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	check(GameTooltip:IsOwned(undo), 'still showing')
	eq(lines[2] and lines[2].text, 'Puts Player back where it was before.', 'it now says what Undo does')
	unhover(undo)
	reset()
end)

------------------------------------------------------------------ Undo, Redo, the status line

test('Undo moves the frame back and says so in the status line, naming a mover the filter hides', function()
	reset()
	local player, config, calls = add_mover('player', 'Player')
	EM:Activate()
	EM:Select(player)
	drag(player, 40, 0)
	eq(config.position.x_off, 40, 'dragged')
	calls.apply = 0
	stub.click(frame_of('undo'))
	eq(config.position.x_off, 0, 'Undo: the position is back')
	check(calls.apply >= 1, 'and apply ran')
	eq(status(), 'Undid: Moved Player', 'the status says what it undid')
	eq(EM.selected, player, 'the selection did not change')
	stub.click(frame_of('redo'))
	eq(config.position.x_off, 40, 'Redo: moved again')
	eq(status(), 'Redid: Moved Player', 'the status')

	EM:SetFilter('zzz')
	check(not player.overlay:IsShown(), 'the filter hides its mover')
	local selected = EM.selected -- the filter let go of it (a selected mover that stops showing is deselected)
	stub.click(frame_of('undo'))
	eq(status(), 'Undid: Moved Player. Its mover is hidden by Show or the filter.', 'the status adds that its mover is hidden')
	eq(EM.selected, selected, 'the selection did not change')
	EM:SetFilter('')

	-- Off screen: an outline that is nowhere on the screen counts as hidden.
	stub.click(frame_of('redo'))
	eq(status(), 'Redid: Moved Player', 'shown: no addition')
	History:Clear()
	config.position.x_off = 5000
	player.def.apply()
	History:Push({ kind = 'move', target = 'player', label = 'Moved Player', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 },
			new = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 5000, y_off = 0 } } } })
	EM:UndoStep()
	eq(status(), 'Undid: Moved Player', 'back on screen: no addition')
	EM:RedoStep()
	eq(status(), 'Redid: Moved Player. Its mover is hidden by Show or the filter.', 'its outline is off the screen: the addition')
	reset()
end)

test('the status line clears after STATUS_SECONDS, on a new status and when edit mode turns off', function()
	reset()
	local player = add_mover('player', 'Player')
	EM:Activate()
	eq(EM.STATUS_SECONDS, 6, 'six seconds')
	drag(player, 40, 0)
	stub.click(frame_of('undo'))
	eq(status(), 'Undid: Moved Player', 'shown')
	check(EM.statusText:IsShown(), 'and visible')
	stub.time = stub.time + 5
	stub.run_timers()
	eq(status(), 'Undid: Moved Player', 'still there at 5 seconds')
	stub.click(frame_of('redo'))
	stub.time = stub.time + 5
	stub.run_timers()
	eq(status(), 'Redid: Moved Player', 'a new status has its own clock: the first one running out does not clear it')
	stub.time = stub.time + 2
	stub.run_timers()
	eq(status(), '', 'cleared 6 seconds after the newest')
	check(not EM.statusText:IsShown(), 'and hidden')

	EM:SetBarStatus('something')
	EM:Deactivate()
	eq(status(), '', 'Disabled clears it')
	reset()
end)

test('the status line sits in the gap: small and grey, right-aligned 12 short of the first right divider, cut to the room, taking no mouse', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	EM:SetBarStatus('Undid: Moved Player')
	local text = EM.statusText
	eq(text:GetParent(), bar, 'on the bar')
	eq(rgb(CreateColor(text:GetTextColor())), rgb(colors().text.grey), 'Text > Grey')
	eq(text:GetFontObject(), st.OptionsBody.Font('small'), 'the small font')
	eq(text:GetJustifyH(), 'RIGHT', 'right-aligned')
	local divider = frame_of('undo'):GetLeft() - UIParent:GetLeft() - 1 - 8 -- the divider before the changes group
	eq(text:GetRight() - UIParent:GetLeft(), divider - 12, '12 short of the divider')
	eq(text:GetWidth(), math.ceil(text:GetStringWidth()), "as wide as the text, a whole number")
	local left, _, _, _ = text:GetLeft(), 0, 0, 0
	eq(left, math.floor(left), 'on a whole pixel')
	check(not text:IsMouseEnabled(), 'takes no mouse')

	EM:SetBarStatus(('x'):rep(400))
	local gapLeft, gapRight = EM:BarGap()
	check(text:GetLeft() - UIParent:GetLeft() >= gapLeft, 'cut to the room: not into the left groups')
	eq(text:GetRight() - UIParent:GetLeft(), gapRight - 12, 'still right-aligned')
	reset()
end)

test('a bar too narrow for any gap shows no status text', function()
	reset()
	EM:Activate()
	set_screen(800, 600)
	EM:LayoutBar()
	EM:SetBarStatus('Undid: Moved Player')
	local gapLeft, gapRight = EM:BarGap()
	check(gapRight - 12 - gapLeft >= 0 or not EM.statusText:IsShown() or EM.statusText:GetWidth() == 0, 'no negative width')
	check(EM.statusText:GetWidth() >= 0, 'never negative')
	reset()
end)

test('Reset resets the selected mover and can be undone from the bar', function()
	reset()
	local player, config = add_mover('player', 'Player')
	EM:Activate()
	EM:Select(player)
	EM:Nudge(player, 'RIGHT', true)
	eq(config.position.x_off, 10, 'nudged')
	stub.click(frame_of('reset'))
	eq(config.position.x_off, 0, 'Reset: at its default')
	eq(History.Label(History:Steps()[#History:Steps()]), 'Reset Player', 'a step of its own')
	eq(status(), 'Reset Player', 'the status says so')
	stub.click(frame_of('undo'))
	eq(config.position.x_off, 10, 'Undo: the nudged spot again')
	eq(status(), 'Undid: Reset Player', 'named')
	check(not frame_of('reset').disabled, 'and Reset is on again')
	reset()
end)

test('Undo, Redo, Reset and the list do nothing in combat; a refusal is shown and changes nothing', function()
	reset()
	local player, config = add_mover('player', 'Player')
	EM:Activate()
	EM:Select(player)
	drag(player, 40, 0)
	stub.in_combat = true
	stub.click(frame_of('undo'))
	eq(config.position.x_off, 40, 'Undo does nothing in combat')
	stub.click(frame_of('reset'))
	eq(config.position.x_off, 40, 'nor does Reset')
	eq(#History:Steps(), 1, 'no step was added')
	stub.in_combat = false
	local ok, message = EM:UndoStep()
	eq(ok, true, 'out of combat it works')
	stub.in_combat = true
	ok, message = EM:RedoStep()
	eq(ok, false, "EM:RedoStep refuses in combat")
	eq(message, "Can't redo in combat.", 'with the history\'s message')
	stub.in_combat = false
	reset()
end)

test("a refused step (a write that errors, a stale one) is shown as the refusal and leaves the buttons' states alone", function()
	reset()
	local player, config = add_mover('player', 'Player')
	EM:Activate()
	drag(player, 40, 0)
	local fail = false
	local real = player.def.setPosition
	player.def.setPosition = function(position)
		if fail then error('write failed') end
		return real(position)
	end
	fail = true
	local undo, redo = frame_of('undo'), frame_of('redo')
	stub.click(undo)
	eq(status(), "Player couldn't be undone; the step was put back.", "the history's message, as it is")
	check(not undo.disabled and redo.disabled, 'the step stays applied: Undo on, Redo off')
	eq(History:Position(), 1, 'at the same position')
	eq(#take_errors(), 1, 'the error was reported once')
	fail = false
	stub.click(undo)
	eq(status(), 'Undid: Moved Player', 'and it works once the write does')
	fail = true
	stub.click(frame_of('redo'))
	eq(status(), "Player couldn't be redone; the step was put back.", 'Redo too')
	check(undo.disabled and not redo.disabled, 'still undone')
	take_errors()
	fail = false

	-- Stale: something else moved it.
	stub.click(frame_of('redo'))
	config.position.x_off = 77
	stub.click(undo)
	eq(status(), 'Player was changed since; its earlier steps are dropped.', 'a stale step says so')
	check(undo.disabled, 'and Undo follows the history: nothing left')
	reset()
end)

test("a jump's note is about the steps it walked, and a jump that stops part way says where", function()
	reset()
	local p1 = add_mover('p1', 'P1')
	local p2, c2 = add_mover('p2', 'P2')
	local p3 = add_mover('p3', 'P3')
	EM:Activate()
	drag(p1, 10, 0)
	drag(p2, 20, 0)
	EM:SetFilter('p1') -- P2's mover is hidden, P1's shows
	check(p1.overlay:IsShown() and not p2.overlay:IsShown(), 'only P1 shows')
	EM:JumpToStep(1)
	eq(status(), 'Went back to: Moved P1. Its mover is hidden by Show or the filter.', 'the step that moved is P2, which is hidden')
	EM:SetFilter('')
	EM:JumpToStep(2)
	eq(status(), 'Went to: Moved P2', 'a jump forward; nothing hidden: no note')

	-- Part way: P2 is moved from outside, then a jump to the start.
	reset()
	p1 = add_mover('p1', 'P1')
	p2, c2 = add_mover('p2', 'P2')
	p3 = add_mover('p3', 'P3')
	EM:Activate()
	drag(p1, 10, 0)
	drag(p2, 20, 0)
	drag(p3, 30, 0)
	c2.position.x_off = 77
	EM:JumpToStep(0)
	eq(status(), 'Went back part way, to Moved P1: P2 was changed since; its earlier steps are dropped.', 'it says it stopped, where, and why')
	eq(History:Position(), 1, 'at P1')
	-- A refusal before anything moved is the refusal alone.
	stub.in_combat = true
	EM:JumpToStep(0)
	eq(status(), "Can't undo in combat.", 'a refusal with no progress')
	stub.in_combat = false
	reset()
end)

test('EM.Ago: now under 5 seconds, then seconds, minutes, hours', function()
	eq(EM.Ago(0), 'now', '0')
	eq(EM.Ago(4.9), 'now', 'under 5')
	eq(EM.Ago(5), '5s ago', '5')
	eq(EM.Ago(59), '59s ago', '59')
	eq(EM.Ago(60), '1m ago', 'a minute')
	eq(EM.Ago(125), '2m ago', 'two')
	eq(EM.Ago(3599), '59m ago', '59 minutes')
	eq(EM.Ago(3600), '1h ago', 'an hour')
	eq(EM.Ago(7300), '2h ago', 'two hours')
	eq(EM.Ago(-3), 'now', 'a clock that went back')
end)

------------------------------------------------------------------ the list

-- Three movers and a step each, the newest Focus.
local function three()
	local p, pc = add_mover('player', 'Player')
	local t, tc = add_mover('target', 'Target')
	local f, fc = add_mover('focus', 'Focus')
	EM:Activate()
	drag(p, 10, 0)
	drag(t, 20, 0)
	drag(f, 30, 0)
	return p, t, f, pc, tc, fc
end

test('the History list: newest first, the current step marked, undone ones grey, a row click goes back to it', function()
	reset()
	local p, t, f, pc, tc, fc = three()
	local button = frame_of('history')
	check(not button.on, 'History is off at first')
	stub.click(button)
	local list = EM:GetHistoryList()
	check(list:IsShown() and EM:IsHistoryListShown(), 'the list is shown')
	check(button.on == true, 'History is on while the list is open')
	eq(table.concat(labels(list), '|'), 'Moved Focus|Moved Target|Moved Player|Before these changes', 'newest first, then the start')
	check(list.rows[1].mark:IsShown() and not list.rows[2].mark:IsShown(), 'the first row has the mark')
	eq(list.rows[1].mark:GetWidth(), 2, 'a 2px mark')
	eq((fill(list.rows[1].mark)), rgb(colors().button.blue), 'in the accent')
	eq(list.rows[1].detail:GetText(), 'now', 'its detail is how long ago')
	eq(rgb(CreateColor(list.rows[1].label:GetTextColor())), rgb(colors().text.normal), 'applied: normal')

	stub.click(frame_of('undo'))
	check(not list.rows[1].mark:IsShown() and list.rows[2].mark:IsShown(), 'undo: the mark moves to the second')
	eq(rgb(CreateColor(list.rows[1].label:GetTextColor())), rgb(colors().text.grey), 'the undone one is grey')
	eq(list.rows[1].detail:GetText(), 'undone', 'and says undone')
	eq(list.rows[2].detail:GetText(), 'now', 'the applied ones do not')

	stub.click(list.rows[3])
	eq(History:Position(), 1, 'a click on the third row: back to just after Moved Player')
	eq(pc.position.x_off, 10, 'Player is where it was')
	eq(tc.position.x_off, 0, 'Target is back')
	eq(fc.position.x_off, 0, 'Focus is back')
	eq(status(), 'Went back to: Moved Player', 'the status says so')
	check(list.rows[3].mark:IsShown(), 'the mark follows')
	stub.click(list.rows[4])
	eq(History:Position(), 0, "'Before these changes': position 0")
	eq(pc.position.x_off, 0, 'Player is at the start')
	eq(status(), 'Went back to: Before these changes', 'named')
	check(History:CanRedo(), 'Redo still works')
	check(list.rows[4].mark:IsShown(), 'the start row is marked')
	stub.click(frame_of('redo'))
	eq(pc.position.x_off, 10, 'Redo brings the first step back')
	stub.click(list.rows[1])
	eq(History:Position(), 3, 'a row above the current one goes forward')
	eq(fc.position.x_off, 30, 'to the newest')
	reset()
end)

test('the list ages its details: now, then seconds, minutes and hours, as time passes', function()
	reset()
	three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	local made = History:Steps()[3].time
	stub.time = made + 7
	stub.fire_script(list, 'OnUpdate', 0.5)
	eq(list.rows[1].detail:GetText(), 'now', 'a half second is not a tick: still the old text')
	stub.fire_script(list, 'OnUpdate', 0.6)
	eq(list.rows[1].detail:GetText(), '7s ago', 'seconds')
	stub.time = made + 127
	stub.fire_script(list, 'OnUpdate', 1.1)
	eq(list.rows[1].detail:GetText(), '2m ago', 'minutes')
	stub.time = made + 7300
	stub.fire_script(list, 'OnUpdate', 1.1)
	eq(list.rows[1].detail:GetText(), '2h ago', 'hours')
	reset()
end)

test("a bulk step's detail is its number of settings; a row's tooltip is its label and what a click does", function()
	reset()
	local p = add_mover('player', 'Player')
	local t = add_mover('target', 'Target')
	EM:Activate()
	History:Push({ kind = 'bulk', label = 'Copied Target to Player', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 3, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } },
		{ kind = 'position', where = 'target', old = { point = 'CENTER', x_off = 5, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	eq(list.rows[1].detail:GetText(), '2 settings', 'two settings')
	hover(list.rows[1])
	eq(lines[1].text, 'Copied Target to Player', 'the label')
	eq(lines[2].text, 'Goes back to just after this step; the steps after it stay until you make a new change.', 'what a click does')
	unhover(list.rows[1])
	hover(list.rows[2])
	eq(lines[1].text, 'Before these changes', 'the start row')
	check(lines[2] ~= nil, 'with a line too')
	unhover(list.rows[2])
	reset()
end)

test('a row under the mouse is filled at 25% accent, or with the dropdown list\'s rowHover under Blizzard', function()
	reset()
	three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	local row = list.rows[2]
	check(not row.hover:IsShown(), 'not hovered: no fill')
	stub.fire_script(row, 'OnEnter', true)
	check(row.hover:IsShown(), 'under the mouse: filled')
	eq(row.hover:GetAlpha(), 0.25, 'at 25%')
	eq((fill(row.hover)), rgb(colors().button.blue), 'in the accent')
	stub.fire_script(row, 'OnLeave', true)
	check(not row.hover:IsShown(), 'left: no fill')
	look('blizzard')
	stub.fire_script(row, 'OnEnter', true)
	eq(row.hover:GetAtlas(), st.ThemeArt.Control('dropdown').rowHover, "Blizzard: the dropdown list's rowHover")
	eq(row.hover:GetAlpha(), 1, 'at full alpha')
	stub.fire_script(row, 'OnLeave', true)
	reset()
end)

test("a row's revert shows on applied steps, enabled only when nothing later touched its mover, with the reason when not", function()
	reset()
	local p, t, f, pc, tc, fc = three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	-- Player (step 1), Target (2), Focus (3): each is alone on its mover.
	local row = list.rows[3] -- Moved Player
	check(row.revert:IsShown() and not row.revert.disabled, "Player's revert is enabled: nothing later touched it")
	eq(row.revert.icon:GetTexture(), st.icons.rotateCcw, 'a rotate-ccw icon')
	eq(row.revert:GetWidth(), 14, '14 square')
	hover(row.revert)
	eq(lines[2].color, rgb(colors().text.normal), 'enabled: a normal line')
	unhover(row.revert)
	stub.click(row.revert)
	eq(pc.position.x_off, 0, 'reverted: Player is back at the start')
	eq(tc.position.x_off, 20, 'the later steps stay')
	eq(#History:Steps(), 4, 'a new top step')
	eq(History.Label(History:Steps()[4]), 'Reverted: Moved Player', 'named')
	eq(status(), 'Reverted: Moved Player', 'the status says so')
	eq(labels(list)[1], 'Reverted: Moved Player', 'and it tops the list')

	-- Player moved twice: the older step is covered by the later.
	reset()
	local p2, _, _, pc2 = three()
	drag(p2, 15, 0)
	stub.click(frame_of('history'))
	list = EM:GetHistoryList()
	eq(labels(list)[1], 'Moved Player', 'the newest step')
	local older = list.rows[4] -- the first Moved Player
	eq(older.label:GetText(), 'Moved Player', 'the older one')
	check(older.revert:IsShown(), 'its revert shows')
	check(older.revert.disabled, "disabled: Player moved again later")
	hover(older.revert)
	eq(lines[2].text, 'Changed again later: go back to this point instead.', 'its tooltip says why')
	eq(lines[2].color, rgb(colors().text.red), 'in red')
	unhover(older.revert)
	stub.click(older.revert)
	eq(#History:Steps(), 4, 'a disabled revert does nothing')

	-- A bulk step is not reverted on its own.
	reset()
	add_mover('player', 'Player')
	add_mover('target', 'Target')
	EM:Activate()
	History:Push({ kind = 'bulk', label = 'Copied A to B', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 3, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	stub.click(frame_of('history'))
	list = EM:GetHistoryList()
	check(list.rows[1].revert:IsShown() and list.rows[1].revert.disabled, 'a bulk step: shown and disabled')
	hover(list.rows[1].revert)
	eq(lines[2].text, "A copy can't be reverted on its own: go back to this point instead.", 'with its reason')
	unhover(list.rows[1].revert)
	reset()
end)

test("a row's revert shows when the step is applied (ok, or a reason), not on undone steps or the start row", function()
	reset()
	three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	stub.click(frame_of('undo'))
	check(not list.rows[1].revert:IsShown(), 'an undone step has none')
	check(list.rows[2].revert:IsShown(), 'an applied one has')
	check(not list.rows[4].revert:IsShown(), 'the start row has none')
	reset()
end)

test("a revert that is refused shows the history's message and the list is as it was", function()
	reset()
	local p, t, f, pc = three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	local fail = false
	local real = p.def.setPosition
	p.def.setPosition = function(position)
		if fail then error('write failed') end
		return real(position)
	end
	fail = true
	stub.click(list.rows[3].revert)
	eq(status(), "Player couldn't be reverted; the step was put back.", 'the refusal, as it is')
	eq(#History:Steps(), 3, 'no step was added')
	eq(pc.position.x_off, 10, 'and nothing moved')
	eq(#take_errors(), 1, 'reported once')
	fail = false
	reset()
end)

test('a change whose old is nil (a first move) reads through its label and the list opens without error', function()
	reset()
	add_mover('player', 'Player')
	EM:Activate()
	History:Push({ kind = 'move', target = 'player', label = 'Moved Player', changes = {
		{ kind = 'position', where = 'player', old = nil, new = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } } } })
	-- Player is at nothing-saved on the way in: the write of old nil is a plain nil.
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	eq(labels(list)[1], 'Moved Player', 'the label reads')
	hover(list.rows[1])
	check(#lines >= 2, 'its tooltip shows')
	unhover(list.rows[1])
	hover(frame_of('undo'))
	eq(lines[2].text, 'Puts Player back where it was before.', 'Undo names it')
	unhover(frame_of('undo'))
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

-- 20 steps, a mover each time round.
local function twenty()
	local movers = {}
	for i = 1, 4 do movers[i] = add_mover('m' .. i, 'M' .. i) end
	EM:Activate()
	for n = 1, 20 do drag(movers[(n - 1) % 4 + 1], n, 0) end
	return movers
end

test('the History list scrolls past 12 rows, sets its length, and closes on Esc, History, Exit and combat', function()
	reset()
	twenty()
	local button = frame_of('history')
	stub.click(button)
	local list = EM:GetHistoryList()
	eq(EM.HISTORY.WIDTH .. ',' .. EM.HISTORY.PAD .. ',' .. EM.HISTORY.ROW .. ',' .. EM.HISTORY.ROWS .. ',' .. EM.HISTORY.LEVEL .. ',' .. EM.HISTORY.WHEEL,
		'300,12,26,12,9700,3', "the spec's numbers")
	local shown = 0
	for _, row in ipairs(list.rows) do if row:IsShown() then shown = shown + 1 end end
	eq(shown, 12, '21 entries: 12 rows shown')
	eq(list.offset, 0, 'at the top')
	eq(list.rows[1].label:GetText(), 'Moved M4', 'the newest first')
	check(list.bar:IsShown(), 'the scroll bar shows')
	stub.fire_script(list, 'OnMouseWheel', -1)
	eq(list.offset, 3, 'wheel -1 scrolls 3 rows')
	eq(list.rows[1].index, 17, 'row 1 is now step 17')
	stub.fire_script(list, 'OnMouseWheel', -1)
	stub.fire_script(list, 'OnMouseWheel', -1)
	stub.fire_script(list, 'OnMouseWheel', -1)
	stub.fire_script(list, 'OnMouseWheel', -1)
	eq(list.offset, 9, 'stops at the end: 21 entries less 12 rows')
	eq(list.rows[12].label:GetText(), 'Before these changes', 'the last row is the start')
	stub.fire_script(list, 'OnMouseWheel', 1)
	eq(list.offset, 6, 'and back')
	local companion = st.OptionsBody.Companion(list.bar)
	check(companion ~= nil, 'the Blizzard bar is its companion')
	list.set(0)
	eq(list.offset, 0, 'the bar scrolls it too')

	-- The length.
	local box = list.box
	eq(box.edit:GetText(), '50', 'the box shows the length')
	box.edit:SetText('5')
	stub.fire_script(box.edit, 'OnEnterPressed')
	eq(settings().history_limit, 5, 'history_limit is saved')
	eq(History.limit, 5, 'and applied')
	eq(#History:Steps(), 20, 'nothing is thrown away until the next step')
	eq(box.edit:GetText(), '5', 'the box shows it')
	box.edit:SetText('2000')
	stub.fire_script(box.edit, 'OnEnterPressed')
	eq(settings().history_limit, 1000, '2000 gives 1000')
	eq(History.limit, 1000, 'applied')
	eq(box.edit:GetText(), '1000', 'the box shows the clamp')
	box.edit:SetText('abc')
	stub.fire_script(box.edit, 'OnEnterPressed')
	eq(History.limit, 1000, 'text changes nothing')
	eq(box.edit:GetText(), '1000', 'and the box shows what is kept')
	stub.click(box.pair.down)
	eq(History.limit, 990, 'the arrows step by 10')
	stub.click(box.pair.up)
	eq(History.limit, 1000, 'and up')

	-- Esc: only the list.
	st.Config:Open('Loot')
	check(st.OptionsWindow:IsShown(), '/sui is open')
	stub.fire_script(list.keys, 'OnKeyDown', 'ESCAPE')
	check(not list:IsShown() and not EM:IsHistoryListShown(), 'Esc closes the list')
	check(st.OptionsWindow:IsShown(), 'and /sui is still open')
	check(EM.active, 'and edit mode is still on')
	check(not button.on, 'History is off again')
	check(not list.keys:IsShown(), 'the catcher is off with the list')
	-- Another key goes on to the game.
	stub.click(button)
	stub.fire_script(list.keys, 'OnKeyDown', 'A')
	check(list:IsShown(), 'another key does not close it')
	eq(list.keys:GetParent(), list, 'the catcher is a child of the list')
	check(list.keys:IsKeyboardEnabled(), 'taking keys while shown')
	-- History again.
	stub.click(button)
	check(not list:IsShown(), 'History again closes it')
	-- Exit (edit mode off).
	stub.click(button)
	check(list:IsShown(), 'open again')
	EM:Deactivate()
	check(not list:IsShown(), 'Disabled closes it')
	-- Combat.
	EM:Activate()
	stub.click(button)
	check(list:IsShown(), 'open once more')
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not list:IsShown(), 'combat closes it')
	reset()
end)

test("the length box is not refreshed while it has the keyboard: 200 typed across two ticks commits 200", function()
	reset()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	local edit = list.box.edit
	edit:SetFocus()
	edit:SetText('2')
	stub.fire_script(list, 'OnUpdate', 1.1)
	eq(edit:GetText(), '2', 'the first tick leaves what is typed')
	edit:SetText('200')
	stub.fire_script(list, 'OnUpdate', 1.1)
	eq(edit:GetText(), '200', 'and the second')
	EM:RefreshHistoryList()
	eq(edit:GetText(), '200', 'so does any other refresh')
	stub.fire_script(edit, 'OnEnterPressed')
	eq(History.limit, 200, 'Enter commits 200')
	eq(settings().history_limit, 200, 'the setting too')
	check(not edit:HasFocus(), 'Enter lets go')
	edit:SetText('7')
	stub.fire_script(list, 'OnUpdate', 1.1)
	eq(edit:GetText(), '200', 'without the keyboard the tick shows what the history keeps')
	reset()
end)

test("an arrow pressed while the length box has the keyboard shows its value, and Enter keeps it", function()
	reset()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	local box = list.box
	box.edit:SetFocus()
	stub.click(box.pair.up)
	stub.click(box.pair.up)
	eq(History.limit, 70, 'the arrows set the length')
	eq(box.edit:GetText(), '70', 'and the box shows it')
	stub.fire_script(list, 'OnUpdate', 1.1)
	eq(box.edit:GetText(), '70', 'the tick leaves it')
	stub.fire_script(box.edit, 'OnEnterPressed')
	eq(History.limit, 70, 'Enter does not put the old number back')
	box.edit:SetFocus()
	box.edit:SetText('9')
	stub.click(box.pair.down)
	eq(box.edit:GetText(), '60', 'an arrow after typing shows the new value')
	reset()
end)

test("the length box lets go of the keyboard when the list closes, a mover is pressed or dragged, edit mode closes, and in combat", function()
	local function focused_box()
		reset()
		local mover = add_mover('focus_test', 'Focus test')
		EM:Activate()
		EM:SetBarFloating(false)
		stub.click(frame_of('history'))
		local list = EM:GetHistoryList()
		list.box.edit:SetFocus()
		check(list.box.edit:HasFocus(), 'it has focus')
		return list.box.edit, mover
	end
	local edit, mover = focused_box()
	EM:HideHistoryList()
	check(not edit:HasFocus(), 'the list closing')
	edit, mover = focused_box()
	stub.fire_script(mover.overlay, 'OnMouseDown', 'LeftButton')
	check(not edit:HasFocus(), 'a mover pressed')
	edit, mover = focused_box()
	EM:StartDrag(mover); EM:StopDrag(mover)
	check(not edit:HasFocus(), 'a drag started')
	edit = focused_box()
	EM:Deactivate()
	check(not edit:HasFocus(), 'edit mode disabled')
	edit = focused_box()
	EM:SetBarFloating(true)
	check(not edit:HasFocus(), 'Detach closes the list')
	EM:SetBarFloating(false)
	edit = focused_box()
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not edit:HasFocus(), 'combat')
	reset()
end)

test('the list: a click, a revert and the length box do nothing in combat', function()
	reset()
	local p, t, f, pc = three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	EM:SetBarStatus('')
	stub.in_combat = true
	stub.click(list.rows[3])
	eq(History:Position(), 3, 'a row click does nothing in combat')
	eq(status(), '', 'and says nothing')
	stub.click(list.rows[3].revert)
	eq(#History:Steps(), 3, 'nor does a revert')
	eq(status(), '', 'and says nothing')
	stub.click(frame_of('undo'))
	stub.click(frame_of('history'))
	eq(status(), '', 'the buttons say nothing either')
	check(EM:IsHistoryListShown(), "and History does not toggle the list")
	list.box.edit:SetText('5')
	stub.fire_script(list.box.edit, 'OnEnterPressed')
	eq(History.limit, 50, 'the length box sets nothing in combat')
	eq(settings().history_limit, 50, 'nor the setting')
	stub.click(list.box.pair.down)
	eq(History.limit, 50, 'nor do its arrows')
	stub.in_combat = false
	reset()
end)

test('the list is placed 6 under the History button, its top right on the button\'s bottom right, in front of the bar', function()
	reset()
	three()
	local button = frame_of('history')
	stub.click(button)
	local list = EM:GetHistoryList()
	eq(list:GetRight(), button:GetRight(), 'right edges meet')
	eq(list:GetTop(), button:GetBottom() - 6, '6 under')
	eq(list:GetWidth(), 300, '300 wide')
	eq(list:GetFrameStrata() .. list:GetFrameLevel(), 'FULLSCREEN_DIALOG9700', 'over the bar')
	eq(st:DrawnKind(list), 'panel', 'drawn as a panel in the theme')
	check(list:IsMouseEnabled(), 'it takes the mouse')
	eq(list.title:GetText(), 'History', 'titled')
	eq(list.title:GetFontObject(), st.OptionsBody.Font('group'), 'in the group font')
	eq(rgb(CreateColor(list.title:GetTextColor())), rgb(colors().text.grey), 'Text > Grey')
	eq(list.foot1:GetText(), 'Keep the last', 'the foot')
	eq(list.foot2:GetText(), 'steps (up to 1000)', 'and its end')
	eq(list.box:GetWidth(), 54, 'a 54 wide box')
	-- The rows: 26 tall with the hairline between.
	eq(list.rows[1]:GetHeight(), 26, 'a row is 26 tall')
	eq(list.rows[1]:GetTop() - list.rows[2]:GetTop(), 26, 'stacked at 26')
	eq(list.rows[1]:GetWidth(), 300 - 24, 'PAD in from each side')
	check(list.rows[1].line:IsShown() and not list.rows[4].line:IsShown(), 'a hairline between rows, none under the last')
	local hairline, alpha = fill(list.rows[1].line)
	eq(hairline, '1.00,1.00,1.00', 'the hairline is white')
	eq(alpha, 0.07, 'at 7%')
	eq(list.rows[1].line:GetHeight(), 1, 'a pixel tall')
	reset()
end)

test('a click on the current row does nothing; a step with a part that is gone says so', function()
	reset()
	local p, t, f, pc = three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	EM:SetBarStatus('')
	stub.click(list.rows[1])
	eq(status(), '', 'the current row: no change, no status')
	eq(History:Position(), 3, 'still there')

	History:Clear()
	History:Push({ kind = 'bulk', label = 'Copied A to B', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 },
			new = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 10, y_off = 0 } },
		{ kind = 'position', where = 'ghost', old = { point = 'CENTER', x_off = 1, y_off = 0 }, new = { point = 'CENTER', x_off = 2, y_off = 0 } } } })
	stub.click(frame_of('undo'))
	eq(status(), "Undid: Copied A to B ghost isn't there now; skipped.", 'what was skipped follows')
	reset()
end)

test('a message the status line is too narrow for is also shown in full under the control that was pressed, for the same time', function()
	watch_tooltip()
	for _, size in ipairs({ { 1024, 768 }, { 800, 600 } }) do
		reset()
		set_screen(size[1], size[2])
		local player, config = add_mover('player', 'Player')
		EM:Activate()
		EM:LayoutBar()
		drag(player, 40, 0)
		config.position.x_off = 77 -- moved from outside: Undo is refused
		local message = 'Player was changed since; its earlier steps are dropped.'
		local undo = frame_of('undo')
		lines = {}
		stub.click(undo)
		eq(status(), message, size[1] .. ': the status line has the message (cut to its room)')
		check(EM.statusCut, size[1] .. ': and knows it is cut')
		check(tip_on(undo), size[1] .. ': the tooltip is under the pressed control')
		local text = {}
		for _, line in ipairs(lines) do text[#text + 1] = line.text end
		check(table.concat(text, '|'):find(message, 1, true), size[1] .. ': with the whole message')
		eq(lines[#lines].color, rgb(colors().text.red), size[1] .. ': a refusal in red')
		stub.time = stub.time + 5
		stub.run_timers()
		check(tip_on(undo), 'still there at 5 seconds')
		stub.time = stub.time + 2
		stub.run_timers()
		check(not tip_on(undo), 'gone at 6')
		eq(status(), '', 'with the status line')
		-- In combat it is not shown.
		stub.in_combat = true
		EM:SetBarStatus(message, undo, true)
		check(not tip_on(undo), 'nothing in combat')
		stub.in_combat = false
		EM:SetBarStatus('')
		eq(#P.off(EM:GetBar()), 0, size[1] .. ': the bar is still on whole pixels')
	end
	reset()
	local player, config = add_mover('player', 'Player')
	EM:Activate()
	drag(player, 40, 0)
	config.position.x_off = 77
	stub.click(frame_of('undo'))
	check(not EM.statusCut and not tip_on(frame_of('undo')), 'at 1920 the line holds it: no tooltip')
	reset()
end)

test('the status line and the open list are placed again when the bar lays out again', function()
	reset()
	local player = add_mover('player', 'Player')
	EM:Activate()
	drag(player, 40, 0)
	stub.click(frame_of('undo'))
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	local text = EM.statusText
	text:ClearAllPoints()
	text:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 3, -3)
	list:ClearAllPoints()
	list:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, -200)
	EM:LayoutBar()
	local _, gapRight = EM:BarGap()
	eq(text:GetRight() - UIParent:GetLeft(), gapRight - 12, 'the status line is back in the gap')
	eq(list:GetRight(), frame_of('history'):GetRight(), 'the list is back under History')
	reset()
end)

test("the length box shows what the history keeps, not the saved setting", function()
	reset()
	EM:Activate()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	settings().history_limit = 77
	History:SetLimit(33)
	list.box:Refresh()
	eq(list.box.edit:GetText(), '33', 'History.limit')
	reset()
end)

test('the list is kept in the screen margin, starts at the top when reopened, and a .5 length rounds up', function()
	reset()
	twenty()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	check(list:IsClampedToScreen(), 'clamped to the screen margin (st:KeepInScreenMargin)')
	stub.fire_script(list, 'OnMouseWheel', -1)
	eq(list.offset, 3, 'scrolled')
	stub.click(frame_of('history'))
	stub.click(frame_of('history'))
	eq(list.offset, 0, 'reopened at the top')
	eq(list.rows[1].index, 20, 'the newest first again')
	EM:SetSetting('history_limit', 12.5)
	eq(settings().history_limit, 13, '12.5 rounds up')
	eq(History.limit, 13, 'and so does the history')
	reset()
end)

test('lowering the length trims at the next step, not before', function()
	reset()
	local movers = twenty()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	list.box.edit:SetText('5')
	stub.fire_script(list.box.edit, 'OnEnterPressed')
	eq(#History:Steps(), 20, 'nothing lost to a slider dragged down')
	list.box.edit:SetText('50')
	stub.fire_script(list.box.edit, 'OnEnterPressed')
	eq(#History:Steps(), 20, 'and back up')
	list.box.edit:SetText('5')
	stub.fire_script(list.box.edit, 'OnEnterPressed')
	drag(movers[1], 99, 0)
	eq(#History:Steps(), 5, 'the next step trims to the limit')
	reset()
end)

test("a row's tooltip follows the list when it refreshes under the mouse; a one-key copy says '1 setting'; the open list fades with the bar during a drag", function()
	reset()
	local p, t, f = three()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	hover(list.rows[1])
	eq(lines[1].text, 'Moved Focus', 'the newest')
	lines = {}
	drag(p, 5, 0)
	check(GameTooltip:IsOwned(list.rows[1]), 'still under the mouse')
	eq(lines[1] and lines[1].text, 'Moved Player', 'the tooltip names what the row says now')
	unhover(list.rows[1])

	History:Push({ kind = 'bulk', label = 'Copied A to B', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 3, y_off = 0 },
			new = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 4, y_off = 0 } } } })
	eq(list.rows[1].detail:GetText(), '1 setting', 'one key')

	-- The drag fade.
	check(list.rows[2]:IsMouseEnabled(), 'a row takes the mouse')
	EM:StartDrag(f)
	eq(list:GetAlpha(), EM.BAR.DRAG_ALPHA, 'the list fades with the bar')
	check(not list.rows[2]:IsMouseEnabled() and not list:IsMouseEnabled(), 'and is off the mouse')
	EM:StopDrag(f)
	eq(list:GetAlpha(), 1, 'full again')
	check(list.rows[2]:IsMouseEnabled() and list:IsMouseEnabled(), 'with the mouse back')
	reset()
end)

test('Reset, Undo and Redo of a unit with a change under the bar still work at the narrowest stage', function()
	reset()
	set_screen(800, 600)
	local player = add_mover('player', 'Player')
	EM:Activate()
	EM:LayoutBar()
	EM:Select(player)
	drag(player, 40, 0)
	stub.click(frame_of('undo'))
	check(History:CanRedo(), 'Undo works at 800 wide')
	reset()
end)

------------------------------------------------------------------ whole pixels and looks

local function all_whole(list, where)
	for _, noise in ipairs({ 0, 2 ^ -14, -(2 ^ -14) }) do
		stub.size_noise = noise
		EM:LayoutBar()
		EM:RefreshHistoryList()
		local off = P.off(list)
		eq(#off, 0, where .. ' (noise ' .. noise .. '): ' .. P.report(off))
		off = P.off(EM:GetBar())
		eq(#off, 0, where .. ' bar (noise ' .. noise .. '): ' .. P.report(off))
	end
	stub.size_noise = 0
end

for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
	test('whole pixels: the bar with its changes group and the list with its scroll bar and its box, ' .. name, function()
		reset()
		look(name)
		twenty()
		stub.click(frame_of('history'))
		local list = EM:GetHistoryList()
		EM:SetBarStatus('Undid: Moved M4')
		all_whole(list, name .. ' scrolling')
		stub.fire_script(list, 'OnMouseWheel', -1)
		all_whole(list, name .. ' scrolled')
		for i = 1, 6 do EM:UndoStep() end
		all_whole(list, name .. ' after undo')
		History:Clear()
		all_whole(list, name .. ' empty')
		hover(frame_of('undo'))
		unhover(frame_of('undo'))
		reset()
	end)
end

test('under Blizzard the list is the panel, the rows and the scroll bar draw, and switching theme redraws them', function()
	reset()
	twenty()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	look('blizzard')
	eq(st:DrawnKind(list), 'panel', 'the panel kind under Blizzard')
	local companion = st.OptionsBody.Companion(list.bar)
	check(companion.frame:IsShown(), "Blizzard's scroll bar shows")
	check(not list.bar:IsShown(), 'and the flat one does not')
	look('thick')
	check(list.bar:IsShown() and not companion.frame:IsShown(), 'back to the flat bar')
	reset()
end)

------------------------------------------------------------------ the setting

test('the History length row on the Edit mode tab', function()
	reset()
	local row = st.Config:GetOptionsTable().Fonts.args.editmode.args.general.args.history_limit
	check(row ~= nil, 'there is a row')
	eq(row.type, 'range', 'a range')
	eq(row.min, 1, 'from 1')
	eq(row.max, 1000, 'to 1000')
	local general = st.Config:GetOptionsTable().Fonts.args.editmode.args.general
	local info = { 'history_limit' }
	general.set(info, 7)
	eq(History.limit, 7, 'setting it sets the history limit')
	eq(settings().history_limit, 7, 'and the profile')
	eq(general.get(info), 7, 'and the row reads it')
	reset()
end)

test('history_limit: 50 by default, clamped 1 to 1000 by EM:SetSetting, applied at load and on a profile change', function()
	reset()
	eq(st.defaults.editmode.history_limit, 50, 'the default is 50')
	EM:SetSetting('history_limit', 0)
	eq(settings().history_limit, 1, 'clamped to 1')
	eq(History.limit, 1, 'applied')
	EM:SetSetting('history_limit', 5000)
	eq(settings().history_limit, 1000, 'clamped to 1000')
	EM:SetSetting('history_limit', 12.4)
	eq(settings().history_limit, 12, 'a whole number')
	EM:SetSetting('history_limit', 0 / 0)
	eq(settings().history_limit, 12, 'NaN changes nothing')
	EM:SetSetting('history_limit', 'x')
	eq(settings().history_limit, 12, 'text changes nothing')
	eq(History.limit, 12, 'and the history keeps 12')

	-- At load: the saved value is applied when edit mode is enabled.
	settings().history_limit = 9
	History:SetLimit(50)
	EM:OnEnable()
	eq(History.limit, 9, 'the saved limit is applied at load')
	-- On a profile change (SettingsChanged with nil, as EM:UpdateConfig fires).
	settings().history_limit = 33
	EM:UpdateConfig()
	eq(History.limit, 33, 'and when the profile changes')
	-- A set that sticks shows in a box that was left showing something else.
	EM:Activate()
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	EM:SetSetting('history_limit', 'x')
	eq(list.box.edit:GetText(), '33', 'the box shows what the history keeps')
	reset()
end)

test('EM.HISTORY and EM:ToggleHistoryList', function()
	reset()
	EM:Activate()
	check(not EM:IsHistoryListShown(), 'closed at first')
	EM:ToggleHistoryList()
	check(EM:IsHistoryListShown(), 'toggled open')
	EM:ToggleHistoryList()
	check(not EM:IsHistoryListShown(), 'toggled shut')
	reset()
end)
