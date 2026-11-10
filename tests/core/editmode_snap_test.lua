-- Snapping while dragging in edit mode (SaftUI-Core/EditMode/snap.lua): the
-- snap math; which frames move with the dragged one (api.lua's st:MovesWith
-- and st:ValidateAnchor); the lines a drag can snap to; frames with secret
-- edges; and what EM:StartDrag (mover.lua) measures the dragged frame by.
-- Migrated from the emsim harness (test_snap.lua). Movers are registered for
-- real with st:RegisterMover, so their outlines come from real overlays.

local st, EM, settings

local function load_edit_mode()
	load_core_helpers() -- st:CreateButton, panels, fonts and the profile defaults
	for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
		load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua') -- EditMode/load.xml's order
	end
	st, EM = SaftUI, SaftUI.EditModeFrames
	settings = EM:GetSettings()
	-- A 1000 x 600 screen at the scale SaftUI sets at login: one UIParent unit
	-- per physical pixel, so UIParent is 1000 x 600 too.
	stub.screen_width, stub.screen_height = 1000, 600
	UIParent:SetScale(768 / 600)
	-- Overlays show while edit mode is on, and snapping skips hidden ones.
	EM.active = true
end

load_edit_mode()

local function has(list, v)
	for _, x in ipairs(list) do
		if x == v then return true end
	end
	return false
end

-- A frame (child of parent, default UIParent), anchored to anchor if given.
local function frame(parent, anchor)
	local f = CreateFrame('Frame', nil, parent or UIParent)
	if anchor then f:SetPoint('TOPLEFT', anchor, 'TOPLEFT') end
	return f
end

-- A frame at left..right x bottom..top in UIParent units, placed from
-- anchor's bottom left (default UIParent's, at 0, 0).
local function rectFrame(l, r, b, t, anchor, ax, ay)
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetSize(r - l, t - b)
	f:SetPoint('BOTTOMLEFT', anchor or UIParent, 'BOTTOMLEFT', l - (ax or 0), b - (ay or 0))
	return f
end

-- Registers a mover for frame, as a module would.
local function addMover(key, f, position)
	position = position or { point = 'BOTTOMLEFT', x_off = 0, y_off = 0 }
	return st:RegisterMover(key, {
		frame = f,
		getPosition = function() return position end,
		setPosition = function(pos) position = pos end,
		apply = function() end,
	})
end

test('SnapAxis, SnapDrag and SnappedOffset', function()
	check(EM.SnapAxis({ 100, 150, 200 }, { 0, 96, 300 }, 8) == -4, 'SnapAxis pulls to nearest line')
	check(EM.SnapAxis({ 100, 150, 200 }, { 205 }, 8) == 5, 'SnapAxis right edge')
	check(EM.SnapAxis({ 100, 150, 200 }, { 97, 203 }, 8) == -3, 'SnapAxis tie goes to earlier edge')
	check(EM.SnapAxis({ 100, 150, 200 }, { 120 }, 8) == 0, 'SnapAxis out of reach')
	check(EM.SnapAxis({ 100, 150, 200 }, { 108 }, 8) == 8, 'SnapAxis exactly at reach')

	local sx, sy = EM.SnapDrag({ left = 100, right = 200, bottom = 50, top = 80 }, 10, 0, { 113 }, {}, 8)
	check(sx == 3, 'SnapDrag x')
	check(sy == 0, 'SnapDrag y')
	sx, sy = EM.SnapDrag({ left = 100, right = 200, bottom = 50, top = 80 }, 0, 0, {}, { 65 }, 8)
	check(sx == 0 and sy == 0, 'SnapDrag y uses vertical center')
	sx, sy = EM.SnapDrag({ left = 100, right = 200, bottom = 50, top = 80 }, 0, 3, {}, { 68 }, 8)
	check(sy == 0 or sy == -0, 'SnapDrag y center') -- center 68 already on 68
	sx, sy = EM.SnapDrag({ left = 100, right = 200, bottom = 50, top = 80 }, 0, 5, {}, { 68 }, 8)
	check(sy == -2, 'SnapDrag y center pulls')

	check(EM.SnappedOffset(20, 10, 3, 0.5) == 26.5, 'SnappedOffset honours scale')
end)

test('st:MovesWith and st:ValidateAnchor', function()
	local target = frame()
	check(st:MovesWith(target, target), 'MovesWith self')
	check(st:MovesWith(frame(nil, target), target), 'MovesWith anchored to target')
	local mid = frame(nil, target)
	check(st:MovesWith(frame(nil, mid), target), 'MovesWith through middle')
	check(st:MovesWith(frame(target), target), 'MovesWith child')
	check(not st:MovesWith(frame(nil, frame()), target), 'MovesWith unrelated')

	-- WoW refuses an anchor loop (SetPoint errors), so c1 reports one through
	-- its own GetNumPoints / GetPoint, to check st:MovesWith still ends.
	local c1 = frame()
	local c2 = frame(nil, c1)
	function c1:GetNumPoints() return 1 end
	function c1:GetPoint() return 'TOPLEFT', c2, 'TOPLEFT', 0, 0 end
	check(not st:MovesWith(c2, target), 'MovesWith cycle terminates false')

	local f = frame()
	local ok, msg = st:ValidateAnchor(f, f)
	check(not ok and msg == "Can't anchor a frame to itself", 'Validate self')
	ok, msg = st:ValidateAnchor(f, frame(nil, f))
	check(not ok and msg == 'Anchor would create a loop', 'Validate anchored back')
	ok, msg = st:ValidateAnchor(f, frame(f))
	check(not ok and msg == 'Anchor would create a loop', 'Validate descendant')
	ok, msg = st:ValidateAnchor(f, frame())
	check(ok == true, 'Validate unrelated')
end)

local movers = {}

test('GetSnapLines', function()
	local dragged = rectFrame(0, 10, 0, 10)
	movers.me = addMover('me', dragged)
	movers.free = addMover('free', rectFrame(100, 200, 100, 140))
	movers.child = addMover('child', rectFrame(300, 400, 100, 140, dragged)) -- anchored to the dragged frame
	movers.hidden = addMover('hidden', rectFrame(600, 700, 100, 140))
	movers.hidden.overlay:Hide()
	movers.off = addMover('off', rectFrame(2000, 2100, 100, 140))

	settings.snap_grid = false
	settings.snap_frames = true
	local xl, yl = EM:GetSnapLines(movers.me)
	local cx = EM:GetGridCenter()
	-- Frames snap by their outline: the overlay's line, EM.OutlineOutset() outside it.
	check(EM.OutlineOutset() == 2, "the outline outset is Thick's 2")
	check(has(xl, 98) and has(xl, 150) and has(xl, 202), 'free x lines are its outline')
	check(has(xl, cx), 'screen center x')
	check(not has(xl, 298) and not has(xl, 350) and not has(xl, 402), 'child skipped')
	check(not has(xl, 598) and not has(xl, 650), 'hidden skipped')
	check(not has(xl, 1998), 'offscreen skipped')
	check(not has(xl, 5), 'own rect skipped')
	check(#xl == 4, 'exactly 4 x lines')
	check(has(yl, 98) and has(yl, 120) and has(yl, 142) and #yl == 4, 'y lines')

	settings.snap_frames = false
	settings.snap_grid = false
	xl, yl = EM:GetSnapLines(movers.me)
	check(#xl == 0 and #yl == 0, 'both off -> empty')
	settings.snap_grid = true
	xl, yl = EM:GetSnapLines(movers.me)
	check(has(xl, cx) and #xl == #EM.GridLinePositions(cx, 0, 1000, settings.grid_size), 'grid lines')
end)

-- A secret edge makes GetRectInUI return nil, and the other movers still give
-- lines. The stubs have no secret values, so these frames report one through
-- their own GetRight, with issecretvalue told to recognise it, as a Blizzard
-- frame (the Minimap) can in game.
test('secret values', function()
	local SECRET = {}
	local realSecret = issecretvalue
	issecretvalue = function(v) return v == SECRET or realSecret(v) end

	local secretFrame = rectFrame(100, 200, 100, 140)
	function secretFrame:GetRight() return SECRET end
	check(EM.GetRectInUI(secretFrame) == nil, 'GetRectInUI nil on a secret edge')
	check(EM.GetRectInUI(rectFrame(1, 2, 3, 4)) ~= nil, 'GetRectInUI still works on normal frames')

	local secretMover = addMover('secret', rectFrame(100, 200, 100, 140))
	function secretMover.overlay:GetRight() return SECRET end
	settings.snap_grid = false
	settings.snap_frames = true
	local ok, sxl = pcall(function() return (EM:GetSnapLines(movers.me)) end)
	check(ok, 'GetSnapLines survives a secret mover')
	check(ok and has(sxl, 98) and has(sxl, 202), 'GetSnapLines still has the other movers')

	EM.movers.secret = nil
	issecretvalue = realSecret
end)

-- StartDrag measures the overlay, not def.frame: chat's outline is padded, its
-- overlay re-anchored outside the frame (CHT:UpdateFootprint).
test('StartDrag measures the overlay', function()
	reset_world()
	load_edit_mode()

	local padded = rectFrame(100, 200, 100, 140)
	local me = addMover('me', padded, { point = 'BOTTOMLEFT', x_off = 100, y_off = 100 })
	me.overlay:ClearAllPoints()
	me.overlay:SetPoint('TOPLEFT', padded, 'TOPLEFT', -10, 10)
	me.overlay:SetPoint('BOTTOMRIGHT', padded, 'BOTTOMRIGHT', 10, -10)
	addMover('other', rectFrame(217, 300, 300, 340))

	settings.snap_frames = true
	settings.snap_grid = false
	EM:StartDrag(me)
	local r0 = me.drag.rect0
	check(r0 and r0.left == 88 and r0.right == 212 and r0.bottom == 88 and r0.top == 152, 'StartDrag rect0 is the overlay outline')
	local sdx = EM.SnapDrag(r0, 0, 0, me.drag.xLines, me.drag.yLines, EM.SNAP_REACH)
	check(sdx == 3, 'outline right (212) snaps to the other outline left (215)')
end)

-- The overlay is drawn in SaftUI's theme, so its line sits the theme's border
-- outside it: Thick's 2px, Thin's 1px. The outline snapping measures follows.
test("the outline follows SaftUI's theme: 2px out under Thick, 1px under Thin", function()
	reset_world()
	load_edit_mode()
	local function rect(mover) return table.concat({ EM.GetOutlineRect(mover) }, ',') end
	local function lineOffset(mover)
		local _, _, _, x, y = mover.overlay.backdrop:GetPoint(1)
		return x .. ',' .. y
	end

	local me = addMover('me', rectFrame(0, 10, 0, 10))
	local other = addMover('other', rectFrame(100, 200, 100, 140))
	settings.snap_grid = false
	settings.snap_frames = true

	eq(EM.OutlineOutset(), 2, 'Thick: 2')
	eq(rect(other), '98,202,98,142', 'Thick: the outline 2px outside the overlay')
	eq(lineOffset(other), '-2,2', "where the overlay's backdrop draws its line")
	local xl, yl = EM:GetSnapLines(me)
	check(has(xl, 98) and has(xl, 202) and has(yl, 98) and has(yl, 142), 'Thick: snapping measures it')

	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()
	eq(EM.OutlineOutset(), 1, 'Thin: 1')
	eq(rect(other), '99,201,99,141', 'Thin: the outline 1px outside the overlay')
	eq(lineOffset(other), '-1,1', "where the overlay's backdrop now draws its line")
	xl, yl = EM:GetSnapLines(me)
	check(has(xl, 99) and has(xl, 201) and has(yl, 99) and has(yl, 141), 'Thin: snapping measures it')
	check(not has(xl, 98) and not has(xl, 202), "Thin: not Thick's lines")

	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	eq(EM.OutlineOutset(), 2, 'back to Thick: 2')
	eq(rect(other), '98,202,98,142', 'back to Thick: 2px out again')
end)
