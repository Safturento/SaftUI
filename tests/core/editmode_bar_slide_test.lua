-- Sliding the docked edit mode bar along the top of the screen
-- (SaftUI-Core/EditMode/Bar/bardock.lua): it starts in the middle, any part of
-- it that is not a control drags it left and right (never up or down), it is
-- kept inside the screen edge margin, its x offset is saved with the bar's
-- other settings (st.config.global.editModeBar.dockX) and comes back after a
-- reload, a screen or scale change and a profile change; a drag on a control
-- does not slide it, none starts while a mover is dragged, one ends cleanly
-- when the mouse-up is missed, in combat and when edit mode closes, and a
-- double click on the blank part returns it to the middle.
--
-- Real: the /sui window's world, edit mode's files and the bar's, a real AceDB
-- profile. The mouse is played by firing scripts (OnDragStart, OnUpdate,
-- OnDragStop on the bar) with stub.cursor_x and stub.mouse_buttons.

local P = load_test_file('lib/pixels.lua')

local H, st, EM, W

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, W = st.EditModeFrames, st.OptionsWidgets
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

local function world()
	reset_world()
	build()
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local settings, frame_of, set_screen, look = EMH.settings, EMH.frame_of, EMH.set_screen, EMH.look

local added = {}
local function add_mover(key)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint('CENTER')
	local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
	local mover = st:RegisterConfigMover(frame, { key = key, config = function() return config end, apply = function() end })
	added[key] = true
	return mover
end

local function reset()
	if EM.active then EM:Deactivate() end
	for key in pairs(added) do
		local mover = EM.movers[key]
		if mover then mover.overlay:Hide() end
		EM.movers[key] = nil
		added[key] = nil
	end
	EM:SetBarFloating(false)
	st.config.global.editModeBar = nil
	EM:SetBarStatus('')
	stub.in_combat = false
	stub.size_noise = 0
	stub.time = 1000
	stub.mouse_buttons = {}
	set_screen(1920, 1080)
	look('thick')
	st.config.profile.misc.clamp_inset = 2
	st:UpdateScreenMargin()
	H.close_all()
end

local function margin() return st.config.profile.misc.clamp_inset end
local function whole(v) return math.floor(v + 0.5) end
local function left_of(bar) return bar:GetLeft() - UIParent:GetLeft() end
local function middle(bar) return math.floor((UIParent:GetWidth() - bar:GetWidth()) / 2) end

local function cursor_at(x) stub.cursor_x = x * UIParent:GetEffectiveScale() end

-- The mouse goes down on the bar at x, moves to `to`, and (unless stay) goes up.
local function slide(bar, from, to, stay)
	cursor_at(from)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar, 'OnMouseDown', 'LeftButton')
	stub.fire_script(bar, 'OnDragStart')
	cursor_at(to)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	if stay then return end
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar, 'OnDragStop')
	stub.fire_script(bar, 'OnMouseUp', 'LeftButton')
end

local function saved_x() return st.config.global.editModeBar and st.config.global.editModeBar.dockX end

------------------------------------------------------------------ the place

test('the bar starts in the middle of the top edge and is a drag handle on its blank parts', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	eq(left_of(bar), middle(bar), 'in the middle')
	eq(bar:GetTop(), UIParent:GetTop(), 'against the top')
	eq(saved_x(), nil, 'nothing saved until it is moved')
	check(bar:IsMouseEnabled(), 'takes the mouse')
	eq(stub.state(bar).drag_buttons[1], 'LeftButton', 'dragged with the left button')
	reset()
end)

test('a drag slides it by how far the cursor moved, along the top only, and drops it on whole pixels', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local start = left_of(bar)
	slide(bar, 900, 1100)
	eq(left_of(bar), start + 200, 'moved 200 right')
	eq(bar:GetTop(), UIParent:GetTop(), 'still against the top')
	eq(saved_x(), start + 200, 'saved on the drop, whole')
	slide(bar, 900.4, 700.8)
	eq(left_of(bar), start + 200 + whole(700.8 - 900.4), 'a fractional cursor: the offset is whole')
	eq(left_of(bar), math.floor(left_of(bar)), 'whole')
	eq(saved_x(), left_of(bar), 'and saved whole')
	local off = P.off(bar)
	eq(#off, 0, 'whole pixels: ' .. P.report(off))
	reset()
end)

test('while it is dragged it follows the cursor, and the place is saved only when it is dropped', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local start = left_of(bar)
	slide(bar, 900, 1000, true)
	eq(left_of(bar), start + 100, 'following')
	eq(saved_x(), nil, 'not saved yet')
	cursor_at(1100)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	eq(left_of(bar), start + 200, 'and on')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar, 'OnDragStop')
	eq(saved_x(), start + 200, 'saved at the drop')
	eq(stub.state(bar).scripts.OnUpdate, nil, 'and no OnUpdate left running')
	reset()
end)

test('it stops at the screen edge margin on both sides', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	slide(bar, 900, -3000)
	eq(left_of(bar), margin(), 'at the left margin')
	eq(saved_x(), margin(), 'saved there')
	slide(bar, 100, 5000)
	eq(UIParent:GetRight() - bar:GetRight(), margin(), 'at the right margin')
	eq(saved_x(), math.floor(UIParent:GetWidth() - margin() - bar:GetWidth()), 'saved there')
	st.config.profile.misc.clamp_inset = 30
	st:UpdateScreenMargin()
	eq(UIParent:GetRight() - bar:GetRight(), 30, 'a bigger margin puts it back in')
	slide(bar, 900, -3000)
	eq(left_of(bar), 30, 'and the left stops there')
	reset()
end)

------------------------------------------------------------------ saved

test('the place is saved with the bar settings, comes back after a reload, and is kept across a profile change', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	slide(bar, 900, 1000)
	local x = saved_x()
	check(x ~= middle(bar), 'moved')
	EM:SetBarFloating(true)
	eq(saved_x(), x, 'detaching keeps it')
	EM:SetBarFloating(false)
	eq(left_of(bar), x, 'docking returns the bar to its saved place')
	local keep = st.config.global.editModeBar
	world()
	st.config.global.editModeBar = { floating = false, dockX = keep.dockX }
	EM:Activate()
	bar = EM:GetBar()
	eq(left_of(bar), x, 'after a reload: where it was left')
	-- A profile switch tells every setting it changed; the place is not the profile's.
	EM:UpdateConfig()
	eq(left_of(bar), x, 'a profile change leaves it')
	reset()
end)

test('a screen or scale change puts it back inside, and the saved place is kept as it was', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	slide(bar, 900, 1500)
	local x = saved_x()
	check(x > 800, 'far to the right: ' .. x)
	set_screen(1024, 768)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	stub.run_timers()
	check(UIParent:GetRight() - bar:GetRight() >= margin(), 'inside the smaller screen: ' .. bar:GetRight())
	eq(bar:GetTop(), UIParent:GetTop(), 'still against the top')
	eq(saved_x(), x, 'the saved place is not rewritten')
	set_screen(1920, 1080)
	stub.fire_event('UI_SCALE_CHANGED')
	stub.run_timers()
	eq(left_of(bar), x, 'back where it was on the big screen')
	-- A saved place that is not a number is the middle.
	st.config.global.editModeBar.dockX = 'a'
	EM:LayoutBar()
	eq(left_of(bar), middle(bar), 'bad value: the middle')
	st.config.global.editModeBar.dockX = 0 / 0
	EM:LayoutBar()
	eq(left_of(bar), middle(bar), 'NaN: the middle')
	reset()
end)

------------------------------------------------------------------ what starts and ends a slide

test('a drag that starts on a control does not slide the bar, and a click on one is still a click', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local start = left_of(bar)
	local grid = frame_of('grid')
	cursor_at(900)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(grid, 'OnMouseDown', 'LeftButton')
	cursor_at(1200)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(grid, 'OnMouseUp', 'LeftButton')
	eq(left_of(bar), start, 'no slide')
	eq(saved_x(), nil, 'nothing saved')
	stub.click(grid)
	eq(settings().grid, true, 'the click toggled Grid')
	reset()
end)

test('no slide starts while a mover is dragged, and a mover drag ends none: the bar takes no mouse then', function()
	reset()
	local mover = add_mover('slide_mover')
	EM:Activate()
	local bar = EM:GetBar()
	local start = left_of(bar)
	EM:StartDrag(mover)
	check(not bar:IsMouseEnabled(), 'the bar lets go of the mouse')
	cursor_at(900)
	stub.fire_script(bar, 'OnDragStart')
	cursor_at(1200)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	eq(left_of(bar), start, 'a drag script that reaches it anyway slides nothing')
	EM:StopDrag(mover)
	check(bar:IsMouseEnabled(), 'the mouse is back')
	eq(saved_x(), nil, 'nothing saved')
	reset()
end)

test('a slide ends cleanly: a mouse-up that is missed, combat, and edit mode closing', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local start = left_of(bar)
	-- The mouse-up goes missed (released outside the game): the next OnUpdate sees no button.
	slide(bar, 900, 1000, true)
	stub.mouse_buttons.LeftButton = nil
	cursor_at(1300)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	eq(left_of(bar), start + 100, 'ends where it was; the cursor moving on does nothing')
	eq(saved_x(), start + 100, 'saved')
	eq(stub.state(bar).scripts.OnUpdate, nil, 'no OnUpdate left')
	-- Combat: edit mode closes, the slide with it.
	slide(bar, 900, 1000, true)
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	stub.in_combat = false
	check(not bar:IsShown(), 'combat hid the bar')
	eq(stub.state(bar).scripts.OnUpdate, nil, 'the slide ended')
	eq(saved_x(), start + 200, 'at the place it had reached')
	EM:Activate()
	cursor_at(1500)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	eq(left_of(bar), start + 200, 'and a bar shown again does not go on following the cursor')
	-- Edit mode closing by Exit.
	stub.mouse_buttons.LeftButton = true
	slide(bar, 900, 950, true)
	EM:Deactivate()
	eq(stub.state(bar).scripts.OnUpdate, nil, 'Exit ends it too')
	eq(saved_x(), start + 250, 'saved')
	reset()
end)

test('a double click on the blank part returns the bar to the middle; a single click, or one on a control, does not', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	slide(bar, 900, 1100)
	local moved = left_of(bar)
	check(moved ~= middle(bar), 'moved off the middle')
	stub.time = stub.time + 10
	stub.fire_script(bar, 'OnMouseUp', 'LeftButton')
	eq(left_of(bar), moved, 'one click: nothing')
	stub.time = stub.time + 0.2
	stub.fire_script(bar, 'OnMouseUp', 'LeftButton')
	eq(left_of(bar), middle(bar), 'two close together: the middle')
	eq(saved_x(), nil, 'and the saved place is cleared, so it follows the screen again')
	-- Two clicks far apart are two clicks.
	slide(bar, 900, 1100)
	moved = left_of(bar)
	stub.time = stub.time + 10
	stub.fire_script(bar, 'OnMouseUp', 'LeftButton')
	stub.time = stub.time + 1
	stub.fire_script(bar, 'OnMouseUp', 'LeftButton')
	eq(left_of(bar), moved, 'a second click a second later: nothing')
	-- A drag's own mouse-up is not one half of a double click.
	slide(bar, 900, 1000)
	slide(bar, 900, 1000)
	eq(left_of(bar), moved + 200, 'two drags in a row are not a double click')
	-- The right button does nothing.
	stub.time = stub.time + 10
	stub.fire_script(bar, 'OnMouseUp', 'RightButton')
	stub.fire_script(bar, 'OnMouseUp', 'RightButton')
	eq(left_of(bar), moved + 200, 'right clicks: nothing')
	reset()
end)

test('the bar is on whole pixels after a slide, under each look, with the read-back noise, at 1024, 1920 and 2560 wide', function()
	local HAIR = 2 ^ -14
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name)
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1024, 768 }, { 1920, 1080 }, { 2560, 1440 } }) do
				set_screen(screen[1], screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED')
				slide(bar, 400.3, 520.8)
				local where = ('%s noise %s at %d: '):format(name, noise, screen[1])
				local off = P.off(bar)
				eq(#off, 0, where .. P.report(off))
				eq(left_of(bar), math.floor(left_of(bar)), where .. 'an offset that is whole')
				eq(bar:GetTop(), UIParent:GetTop(), where .. 'against the top')
			end
		end
	end
	reset()
end)
