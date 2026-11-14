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
	EMH.look('thick')
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

test('tops line up across a gap of 60 and of 400, not of 401', function()
	local me = world()
	-- ref is a tall frame (top 242, middle 140, bottom 42) to the right of the
	-- dragged one, their outlines gap apart sideways (a gap of 400 puts ref's right
	-- at 869 of the screen's 960). 7 down puts the dragged
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
	eq(topsAt(400), 220, 'a gap of 400: still')
	eq(topsAt(401), 223, 'a gap of 401: the cursor\'s')
	eq(EM.SNAP_NEAR, 400, 'the nearness is 400')
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

-- SaftUI's own default player and target frames: TOPRIGHT at -157 and TOPLEFT
-- at +158 from the screen's middle, tops at -130 (units/player.lua, target.lua),
-- 311 apart outline to outline.
test("the default player and target frames' tops still line up across the middle", function()
	reset()
	local function unit(key, point, x, w)
		local frame = CreateFrame('Frame', nil, UIParent)
		frame:SetSize(w, 60)
		local config = { position = { point = point, x_off = x, y_off = -130 } }
		local function apply()
			local pos = config.position
			frame:ClearAllPoints()
			frame:SetPoint(pos.point, UIParent, 'CENTER', pos.x_off, pos.y_off)
		end
		apply()
		local mover = st:RegisterConfigMover(frame, { key = key, config = function() return config end, apply = apply })
		added[key] = true
		return mover, config
	end
	local player = unit('player', 'TOPRIGHT', -157, 200)
	local target, config = unit('target', 'TOPLEFT', 158, 200)
	local l, r = EM.GetOutlineRect(player), select(2, EM.GetOutlineRect(player))
	local tl = EM.GetOutlineRect(target)
	eq(tl - r, 311, 'their outlines are 311 apart')
	EM:Activate()
	settings().snap_frames = true
	-- 3 down from the player's top (-130): a drag up by 1 leaves it 2 under, and
	-- the snap puts it level.
	config.position.y_off = -133
	target.def.apply()
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 1000 * scale, 500 * scale
	EM:StartDrag(target)
	stub.cursor_y = 501 * scale
	EM:UpdateDrag(target)
	eq(target.drag.y, -130, 'the tops line up')
	EM:StopDrag(target)
	reset()
end)

------------------------------------------------------------------ Snap to grid

-- A grid line is lined up by a frame's visible border: the outline's line, a
-- pixel wide on each side. A line at p is the pixel [p, p + pixel). The left and
-- bottom border is the outline's first pixel, [edge, edge + pixel), and the
-- right and top border its last, [edge - pixel, edge). The middle is no grid
-- candidate.
local function gridWorld(look)
	reset()
	EMH.look(look)
	EM:Activate()
	settings().snap_frames, settings().snap_grid = false, true
	return EM:GetGridCenter()
end

-- A mover w x h at the screen's middle; moved so that its outline's edge or
-- middle is at v, then dragged by nothing. Returns the outline after the snap.
-- side: 'left', 'right', 'bottom', 'top', 'middleX' or 'middleY' (the other axis
-- is put on 0, 8 from nothing: the line's own, left to its own snapping, so a
-- second grid snap shows in the other numbers only).
local function gridDrag(key, h, edges)
	local mover = add_mover(key, 0, 0, { h = h })
	EM:UpdateShown()
	local l, r, b, t = EM.GetOutlineRect(mover)
	local pos = mover.def.getPosition()
	pos.x_off = pos.x_off + (edges.l or (edges.r and edges.r - (r - l)) or (edges.mx - (r - l) / 2)) - l
	pos.y_off = pos.y_off + (edges.b or (edges.t and edges.t - (t - b)) or (edges.my - (t - b) / 2)) - b
	mover.def.apply()
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 1000 * scale, 500 * scale
	EM:StartDrag(mover)
	EM:UpdateDrag(mover)
	EM:StopDrag(mover)
	return EM.GetOutlineRect(mover)
end

local function onLine(v, center, size)
	local k = (v - center) / size
	return math.abs(k - math.floor(k + 0.5)) < 1e-6
end

for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
	test('Snap to grid under ' .. look .. ': the border on the side that snaps covers the grid line', function()
		local cx, cy = gridWorld(look)
		local size = settings().grid_size
		local pixel = st:GetPixelSize(UIParent)
		eq(size, 32, 'the default grid size')
		eq(pixel, 1, 'a pixel is a unit at this scale')
		-- Under Thick and Thin the overlay's backdrop is the outline: its line is the
		-- border the player sees, so the box measured is the one drawn.
		local probe = add_mover('probe', 0, 0)
		EM:UpdateShown()
		if look ~= 'blizzard' then
			local bl, br, bb, bt = EM.GetRectInUI(probe.overlay.backdrop)
			local l, r, b, t = EM.GetOutlineRect(probe)
			eq(table.concat({ bl, br, bb, bt }, ','), table.concat({ l, r, b, t }, ','), 'the outline is the backdrop the border is drawn on')
		end
		EM.movers.probe.overlay:Hide()
		EM.movers.probe, added.probe = nil, nil

		local base = cx - 320
		local l = gridDrag('gl', 50, { l = base + 5, b = cy - 320 + 5 })
		check(onLine(l, cx, size), 'left: the border pixel starts on the line')
		local _, r = gridDrag('gr', 50, { r = base + 32 - 4, b = cy - 320 + 5 })
		check(onLine(r - pixel, cx, size), 'right: the border pixel [r - 1, r) is the line')
		local _, _, b = gridDrag('gb', 50, { l = base + 5, b = cy - 320 + 3 })
		check(onLine(b, cy, size), 'bottom: the border pixel starts on the line')
		local _, _, _, t = gridDrag('gt', 50, { l = base + 5, t = cy - 320 + 32 - 4 })
		check(onLine(t - pixel, cy, size), 'top: the border pixel [t - 1, t) is the line')
		reset()
	end)

	test('Snap to grid under ' .. look .. ': a frame whose only match is its middle does not snap', function()
		local cx, cy = gridWorld(look)
		-- The middle 2 past a line, and every edge 10 or more from lines (8 is the
		-- reach): h 28 is an outline 30 or 32 high, 100 wide one 102 or 104.
		local l, r, b, t = gridDrag('gm', 28, { mx = cx - 320 + 2, my = cy - 320 + 2 })
		eq((l + r) / 2, cx - 320 + 2, 'the middle stays where it was')
		eq((b + t) / 2, cy - 320 + 2, 'on both axes')
		check(not onLine(l, cx, 32) and not onLine(r - 1, cx, 32), 'no border moved onto a line')
		reset()
	end)
end

------------------------------------------------------------------ the guides' details

local function parts(text)
	local out = {}
	for v in text:gmatch('[^,]+') do out[#out + 1] = tonumber(v) end
	return out
end

test("a guide lies on the border's pixel: a top or right line one pixel in, a left or bottom line at it", function()
	local me = world()
	-- Tops: ref (top outline 242, 60 right of the dragged one); the dragged top
	-- 3 under it. Both top borders are the pixel [781, 782).
	add_mover('ref', 477, 140, { h = 200 })
	EM:UpdateShown()
	drag(me, 0, -7, true)
	local g = parts(guide('y'))
	eq(g[2], 781, 'the top guide is the pixel under the line, on both top borders')
	eq(g[4], 1, 'a pixel high')
	EM:StopDrag(me)
	EM.movers.ref.overlay:Hide()
	EM.movers.ref, added.ref = nil, nil

	-- Rights: r2's right outline is the dragged one's (365 from the middle).
	add_mover('r2', 283, 0, { w = 160, h = 50 })
	EM:UpdateShown()
	drag(me, 2, 0, true)
	g = parts(guide('x'))
	eq(g[1], 960 + 365 - 1, 'the right guide is the pixel before the line')
	eq(g[3], 1, 'a pixel wide')
	EM:StopDrag(me)
	reset()
end)

test('the guides are one physical pixel and on whole pixels where a unit is not a pixel', function()
	local me = world()
	UIParent:SetScale(768 / 1080 * 1.25)
	local pixel = st:GetPixelSize(UIParent)
	check(pixel > 0 and math.abs(pixel - 1) > 0.1, 'a pixel is not a unit here (' .. tostring(pixel) .. ')')
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 1000 * scale, 500 * scale
	EM:StartDrag(me)
	stub.cursor_x, stub.cursor_y = (1000 - 310) * scale, (500 - 226) * scale
	EM:UpdateDrag(me)
	local gx, gy = EM.snapGuides.x, EM.snapGuides.y
	check(gx:IsShown() and gy:IsShown(), 'the centre guides show')
	check(math.abs(gx:GetWidth() - pixel) < 1e-6, 'the vertical one is a pixel wide')
	check(math.abs(gy:GetHeight() - pixel) < 1e-6, 'the horizontal one is a pixel high')
	local function whole(v) return math.abs(v / pixel - math.floor(v / pixel + 0.5)) < 1e-6 end
	check(whole(gx:GetLeft()) and whole(gy:GetBottom()), 'both sit on whole pixels')
	EM:StopDrag(me)

	-- A target's line that is between two pixels: the guide is put on one.
	add_mover('ref', 500.3, 230.4)
	EM:UpdateShown()
	local pos = me.def.getPosition()
	pos.x_off, pos.y_off = 313, 230
	me.def.apply()
	stub.cursor_x, stub.cursor_y = 1000 * scale, 500 * scale
	EM:StartDrag(me)
	stub.cursor_x = (1000 + 80) * scale
	EM:UpdateDrag(me)
	check(gx:IsShown(), 'the edge guide shows')
	check(whole(gx:GetLeft()), 'on a whole pixel though the line is not (' .. tostring(gx:GetLeft()) .. ')')
	EM:StopDrag(me)
	reset()
end)

test('the guide frame: above the overlays, under the bar, no mouse, in the accent', function()
	local me = world()
	drag(me, -310, -226, true)
	eq(EM.guideFrame:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	eq(EM.guideFrame:GetFrameLevel(), 9100, 'over the overlays (9000 at most), under the bar (9500)')
	check(not EM.guideFrame:IsMouseEnabled(), 'it takes no mouse')
	local r, g, b = unpack(stub.state(EM.snapGuides.x).color_texture)
	local blue = st.config.profile.colors.button.blue
	local br, bg, bb = blue:GetRGB()
	check(math.abs(r - br) < 1e-3 and math.abs(g - bg) < 1e-3 and math.abs(b - bb) < 1e-3, 'Button > Blue')
	EM:StopDrag(me)
	local saved = st.config.profile.colors.button.blue
	st.config.profile.colors.button.blue = { GetRGB = function() return 0.25, 0.5, 0.75 end }
	drag(me, -310, -226, true)
	r, g, b = unpack(stub.state(EM.snapGuides.x).color_texture)
	check(math.abs(r - 0.25) < 1e-3 and math.abs(g - 0.5) < 1e-3 and math.abs(b - 0.75) < 1e-3, 'it follows a change of the accent')
	EM:StopDrag(me)
	st.config.profile.colors.button.blue = saved
	reset()
end)

test('no guide when the screen edge margin pulled the outline off the line', function()
	local me = world()
	-- edge is against the screen's right edge; the dragged one is taken to its
	-- lines (3 off), and the margin stops it short of them.
	add_mover('edge', 910, 100)
	EM:UpdateShown()
	local x = drag(me, 594, 0, true)
	check(x < 313 + 594, 'the margin stopped it (' .. tostring(x) .. ')')
	eq(guide('x') .. guide('y'), 'nonenone', 'and no guide shows a line it is not on')
	EM:StopDrag(me)
	reset()
end)

test('a guide that fails does not stop the frame following the cursor', function()
	local me = world()
	local real = EM.UpdateSnapGuides
	EM.UpdateSnapGuides = function() error('guide broke') end
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 1000 * scale, 500 * scale
	EM:StartDrag(me)
	stub.cursor_x, stub.cursor_y = 1040 * scale, 500 * scale
	pcall(EM.UpdateDrag, EM, me)
	EM.UpdateSnapGuides = real
	eq(me.drag.x, 353, 'the offset is the cursor\'s')
	eq(me.def.frame:GetLeft(), 960 + 353 - 50, 'and the frame has moved')
	EM:StopDrag(me)
	reset()
end)
