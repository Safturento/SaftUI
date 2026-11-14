-- Snap to frames on the edit mode's whole world (SaftUI-Core/EditMode/snap.lua,
-- mover.lua): a drag in empty space, far from every shown mover, is left where
-- the cursor put it; only a target within reach pulls. The owner's report: with
-- Snap to frames on, a dragged mover snapped to something with nothing around.
--
-- Real: Core's helpers, edit mode's files and the bar's, the default settings
-- (Show hidden on, Show disabled off, Dim world on, Grid and both snaps off
-- until a test turns Snap to frames on). Movers are registered with
-- st:RegisterConfigMover on bare frames, a row of them along the bottom and a
-- column down the left as in the real UI; the mouse is stub.cursor_x/y.

local st, EM

local function build()
	load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM = st.EditModeFrames
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local settings, set_screen = EMH.settings, EMH.set_screen

local added = {}

-- A mover on a w x h frame at x, y from the screen's middle (UIParent units).
local function add_mover(key, x, y, extra)
	extra = extra or {}
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(extra.w or 100, extra.h or 50)
	local config = { position = { point = 'CENTER', x_off = x, y_off = y } }
	local function apply()
		local pos = config.position
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.point, pos.x_off, pos.y_off)
	end
	apply()
	local spec = { key = key, config = function() return config end, apply = apply }
	for field, value in pairs(extra) do
		if field ~= 'w' and field ~= 'h' then spec[field] = value end
	end
	local mover = st:RegisterConfigMover(frame, spec)
	added[key] = true
	return mover, config
end

local function reset()
	if EM.active then EM:Deactivate() end
	for key in pairs(added) do
		EM.movers[key].overlay:Hide()
		EM.movers[key] = nil
		added[key] = nil
	end
	local s = settings()
	s.show_hidden, s.show_disabled, s.hidden_modules = true, false, {}
	s.grid, s.snap_grid, s.snap_frames, s.coordinates, s.dim = false, false, false, false, true
	EM:SetFilter('')
	set_screen(1920, 1080)
end

-- The real UI's layout, roughly: bars in a row along the bottom (x -400 to 400,
-- y -480), a column down the left (x -900, y 300 down to -150). Every mover is
-- 100 x 50 except the dragged one, which is 100 x 40 and in the empty upper
-- right: 313 right of and 230 above the screen's middle, where none of its
-- edges is within reach of a line of any other mover.
local function world()
	reset()
	for i = 1, 9 do add_mover('bar' .. i, -400 + (i - 1) * 100, -480) end
	for i = 1, 4 do add_mover('col' .. i, -900, 300 - (i - 1) * 150) end
	local me = add_mover('me', 313, 230, { h = 40 })
	EM:Activate()
	settings().snap_frames = true
	return me
end

-- Drags mover by (dx, dy) from where it is, the cursor as the game would have
-- it: a press, a pickup, a move, from the world's spot. Returns the offsets the
-- drag ended at; the drag ends unless hold, which leaves it on.
local function drag(mover, dx, dy, hold)
	local pos = mover.def.getPosition() -- back where the world put it
	pos.x_off, pos.y_off = 313, 230
	mover.def.apply()
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 1000 * scale, 500 * scale
	EM:StartDrag(mover)
	stub.cursor_x, stub.cursor_y = (1000 + dx) * scale, (500 + dy) * scale
	EM:UpdateDrag(mover)
	local x, y = mover.drag.x, mover.drag.y
	if not hold then EM:StopDrag(mover) end
	return x, y
end

test('a drag far from every shown mover lands exactly where the cursor put it', function()
	local me = world()
	-- 10 left puts the dragged middle (x 303) 3 from the middle of bar7 (300),
	-- which is 700 px below it.
	local x, y = drag(me, -10, 5)
	eq(x, 303, 'x is the cursor\'s, not pulled onto a bar 700 below')
	eq(y, 235, 'y is the cursor\'s')
	reset()
end)

test('a column of movers far to the left pulls a drag along its rows no more', function()
	local me = world()
	-- 44 up puts the dragged middle (y 274) 1 from col1's bottom (273), 1200 px
	-- away across the screen.
	local x, y = drag(me, 0, 44)
	eq(x, 313, 'x is the cursor\'s')
	eq(y, 274, 'y is the cursor\'s')
	reset()
end)

test('a shown mover within reach still pulls, along its own edges', function()
	local me = world()
	add_mover('near', 500, 230)
	EM:UpdateShown()
	-- 80 right puts the dragged right (445) 3 from near's left (448); their
	-- heights overlap, and the middles line up as they are.
	local x, y = drag(me, 80, 0)
	eq(x, 396, 'the right edge is pulled onto near\'s left')
	eq(y, 230, 'the middles stay lined up')
	reset()
end)

test('a mover the rule hides is no target: hidden, disabled, filtered out or in an unticked module', function()
	local me = world()
	local ghost = add_mover('ghost', 500, 230, { module = 'Chat', isHidden = function() return true end })
	local function dragged() return (drag(me, 80, 0)) end
	check(ghost.overlay:IsShown(), 'Show hidden is on: the hidden mover shows')
	eq(dragged(), 396, 'and it pulls')

	EM:SetSetting('show_hidden', false)
	check(not ghost.overlay:IsShown(), 'Show hidden off hides it')
	eq(dragged(), 393, 'and it pulls no more')
	EM:SetSetting('show_hidden', true)

	local off = add_mover('off', 500, 230, { module = 'Chat', isDisabled = function() return true end })
	EM:UpdateShown()
	check(not off.overlay:IsShown(), 'Show disabled is off: a disabled mover does not show')
	EM.movers.ghost.overlay:Hide()
	EM.movers.ghost = nil
	added.ghost = nil
	eq(dragged(), 393, 'a disabled mover is no target')
	EM.movers.off.overlay:Hide()
	EM.movers.off = nil
	added.off = nil

	add_mover('near', 500, 230, { module = 'Chat' })
	EM:UpdateShown()
	eq(dragged(), 396, 'a shown one pulls')
	EM:SetModuleShown('Chat', false)
	eq(dragged(), 393, 'unticked, its module pulls no more')
	EM:SetModuleShown('Chat', true)
	EM:SetFilter('me')
	eq(dragged(), 393, 'a filter that leaves it out')
	reset()
end)

test('none of edit mode\'s own frames is a target: the lines are the centre\'s and the movers\'', function()
	local me = world()
	EM:SetSetting('grid', true)
	EM:SetSetting('dim', true)
	EM:SetSetting('coordinates', true)
	EM:SetBarFloating(true)
	EM:Select(EM.movers.bar1)
	local xl, yl = EM:GetSnapLines(me)
	-- the screen's centre line, and three lines for each of the 13 other movers
	eq(#xl, 1 + 3 * 13, 'x lines')
	eq(#yl, 1 + 3 * 13, 'y lines')
	EM:SetBarFloating(false)
	xl, yl = EM:GetSnapLines(me)
	eq(#xl, 1 + 3 * 13, 'x lines, the bar docked')
	reset()
end)

test('the screen\'s centre lines pull a drag in empty space (by design, with or without the grid)', function()
	reset()
	local me = add_mover('me', 313, 230)
	EM:Activate()
	settings().snap_frames = true
	local x, y = drag(me, -310, -226)
	eq(x, 0, 'the middle is pulled onto the centre line')
	eq(y, 0, 'and the other axis too')
	reset()
end)

test('Snap to grid alone puts a dragged outline edge on a grid line, whatever the movers around', function()
	local me = world()
	settings().snap_frames, settings().snap_grid = false, true
	local size = settings().grid_size
	local cx = EM:GetGridCenter()
	-- A drag of 7 right, with the grid's lines every grid size from the middle.
	local x = drag(me, 7, 0)
	local left = cx + x - 50 - EM.OutlineOutset() -- the outline's left, in UIParent units
	local mid, right = cx + x, cx + x + 50 + EM.OutlineOutset()
	local function onLine(v) return math.abs((v - cx) / size - math.floor((v - cx) / size + 0.5)) < 1e-6 end
	check(onLine(left) or onLine(mid) or onLine(right), 'an edge of the outline is on a grid line')
	reset()
end)

test('tops line up across a gap of 60 and of 200, not of 201', function()
	local me = world()
	-- ref is a tall frame (top 242, middle 140, bottom 42) to the right of the
	-- dragged one, their outlines gap apart sideways. 7 down puts the dragged
	-- top (245) 3 under ref's top.
	local function topsAt(gap)
		local ref = add_mover('ref', 417 + gap, 140, { h = 200 })
		EM:UpdateShown()
		local _, y = drag(me, 0, -7)
		EM.movers.ref.overlay:Hide()
		EM.movers.ref = nil
		added.ref = nil
		return y
	end
	eq(topsAt(60), 220, 'a gap of 60: the tops line up')
	eq(topsAt(200), 220, 'a gap of 200: still')
	eq(topsAt(201), 223, 'a gap of 201: the cursor\'s')
	eq(EM.SNAP_NEAR, 200, 'the nearness is 200')
	eq(EM.SNAP_REACH, 8, 'the snap distance stays 8')
	reset()
end)

local function guide(which)
	local g = EM.snapGuides and EM.snapGuides[which]
	if not g or not g:IsShown() then return 'none' end
	return table.concat({ g:GetLeft(), g:GetBottom(), g:GetWidth(), g:GetHeight() }, ',')
end

test('a guide shows what a drag snapped to: an edge, a middle, the screen center', function()
	local me = world()
	add_mover('near', 500, 230)
	EM:UpdateShown()
	-- The dragged right outline (448) on near's left outline: an edge snap on x,
	-- the middles lined up on y. The screen is 1920 x 1080, its middle (960, 540).
	drag(me, 80, 0, true)
	check(EM.guideFrame:IsShown(), 'the guide frame shows')
	-- x: along 960 + 448 = 1408, 743 (near's bottom outline) to 797 (its top)
	eq(guide('x'), '1408,743,1,54', 'the x guide: the edge, from the far edge to the far edge')
	-- y: along 540 + 230 = 770, from the dragged left outline 1304 to near's right outline 1512
	eq(guide('y'), '1304,770,208,1', 'the y guide: the middle')
	EM:StopDrag(me)
	eq(guide('x') .. guide('y'), 'nonenone', 'the drop clears them')
	check(not EM.guideFrame:IsShown(), 'and the frame')

	drag(me, -310, -226, true)
	eq(guide('x'), '960,0,1,1080', 'the screen center: the whole height')
	eq(guide('y'), '0,540,1920,1', 'and the whole width')
	EM:StopDrag(me)
	reset()
end)

test('no guide without a snap, none for the grid, none after Disabled or in combat', function()
	local me = world()
	drag(me, -10, 5, true)
	-- (303 is 3 from bar7's middle, 700 below: no target)
	eq(guide('x') .. guide('y'), 'nonenone', 'nothing near: none')
	EM:StopDrag(me)

	settings().snap_frames, settings().snap_grid = false, true
	drag(me, 7, 0, true)
	eq(guide('x') .. guide('y'), 'nonenone', 'Snap to grid: none, the grid shows')
	EM:StopDrag(me)

	settings().snap_frames, settings().snap_grid = true, false
	drag(me, -310, -226, true)
	check(guide('x') ~= 'none', 'a snap: shown')
	EM:Deactivate()
	eq(guide('x') .. guide('y'), 'nonenone', 'Disabled clears them')

	EM:Activate()
	local scale = UIParent:GetEffectiveScale()
	drag(me, -310, -226, true)
	check(guide('x') ~= 'none', 'a snap again')
	stub.in_combat = true
	stub.cursor_x = stub.cursor_x + scale
	EM:UpdateDrag(me)
	eq(guide('x') .. guide('y'), 'nonenone', 'in combat: none')
	stub.in_combat = false
	EM:StopDrag(me)
	reset()
end)
