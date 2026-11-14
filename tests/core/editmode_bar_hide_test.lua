-- Hide until hovered, the docked edit mode bar's toggle
-- (SaftUI-Core/EditMode/Bar/bardock.lua, bargroups.lua): the toggle in the
-- options group before Detach with its two Lucide icons (square-mouse-pointer
-- off, square-dashed-mouse-pointer on, lit in the accent while on), saved with
-- the bar's settings, default off; while on the bar is hidden and a 2 px
-- accent strip as wide as the bar shows at the top edge where it sits; the
-- mouse over the strip's hot zone brings the bar down, and it stays while the
-- mouse is over it, a list is open or a box has the keyboard, and for 0.3 s
-- after; it never comes down while a mover is dragged or pressed and hides at
-- once when a drag starts; it covers nothing while hidden or down (BarRect is
-- nil, BarCoverHeight 0); combat hides it and edit mode brings it back in the
-- same state.
--
-- Real: the /sui window's world, edit mode's files and the bar's. The mouse is
-- played with stub.cursor_x and stub.cursor_y, and the bar's watcher frame's
-- OnUpdate is fired by hand with the time that passed (EM.barWatch).

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
local settings, control, frame_of, set_screen, look = EMH.settings, EMH.control, EMH.frame_of, EMH.set_screen, EMH.look

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
	stub.cursor_x, stub.cursor_y = 0, 0
	set_screen(1920, 1080)
	look('thick')
	st.config.profile.misc.clamp_inset = 2
	st:UpdateScreenMargin()
	H.close_all()
	if EM.historyList then EM.historyList:Hide() end
end

local function rgb(color) return string.format('%.2f,%.2f,%.2f', color:GetRGB()) end
local function tip_on(owner) return GameTooltip:IsShown() and GameTooltip:IsOwned(owner) end

-- The cursor at x and y in UIParent's units from its bottom left.
local function cursor(x, y)
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
end

local function bar_x() return EM:GetBar():GetLeft() - UIParent:GetLeft() end
local function screen_top() return UIParent:GetHeight() end

-- The cursor on the middle of the top edge's hot zone, on the bar, or far away.
local function over_strip() cursor(bar_x() + EM:GetBar():GetWidth() / 2, screen_top() - 2) end
local function over_bar() cursor(bar_x() + EM:GetBar():GetWidth() / 2, screen_top() - 30) end
local function away() cursor(100, 300) end

-- The game's next frames: the watcher's OnUpdate, with the time that passed.
local function tick(seconds)
	local watch = EM.barWatch
	stub.time = stub.time + seconds
	if watch and watch:IsShown() then stub.fire_script(watch, 'OnUpdate', seconds) end
end

local function turn_on()
	EM:Activate()
	over_bar()
	stub.click(frame_of('hide'))
	away()
	tick(0.1)
end

------------------------------------------------------------------ the toggle

test('the toggle is on row two between Options and Detach, with its two icons, a tooltip, and lit in the accent while on', function()
	reset()
	EM:Activate()
	local hide = control('hide')
	check(hide and hide.frame, 'a control')
	eq(hide.group.key, 'options', 'in the options group')
	check(frame_of('options'):GetRight() < frame_of('hide'):GetLeft(), 'after Options')
	check(frame_of('hide'):GetRight() < frame_of('detach'):GetLeft(), 'before Detach')
	eq(frame_of('hide'):GetWidth(), 26, '26 wide')
	eq(frame_of('hide'):GetTop(), frame_of('detach'):GetTop(), 'level with Detach')
	eq(st.icons.squareMousePointer ~= nil and st.icons.squareDashedMousePointer ~= nil, true, 'both icons are registered')
	eq(frame_of('hide').icon:GetTexture(), st.icons.squareMousePointer, 'square-mouse-pointer while off')
	check(not frame_of('hide').on, 'not lit')
	eq(EM:IsBarHideUntilHovered(), false, 'off by default')
	eq(frame_of('hide'):GetFrameLevel(), EM:GetBar():GetFrameLevel() + 2, 'two over the bar')

	-- The game's second argument to OnEnter and OnLeave is motion.
	local lines = {}
	local realAdd = GameTooltip.AddLine
	GameTooltip.AddLine = function(self, text, ...) lines[#lines + 1] = text; return realAdd(self, text, ...) end
	stub.fire_script(frame_of('hide'), 'OnEnter', true)
	GameTooltip.AddLine = realAdd
	check(tip_on(frame_of('hide')), 'a tooltip under it')
	eq(lines[1], 'Hide until hovered', 'the title')
	eq(lines[2], 'Hides this bar until the mouse reaches the top edge of the screen where it sits.', 'and the line')
	stub.fire_script(frame_of('hide'), 'OnLeave', true)

	over_bar()
	stub.click(frame_of('hide'))
	eq(EM:IsBarHideUntilHovered(), true, 'a click turns it on')
	eq(frame_of('hide').icon:GetTexture(), st.icons.squareDashedMousePointer, 'square-dashed-mouse-pointer')
	eq(frame_of('hide').on, true, 'lit')
	eq(rgb(CreateColor(frame_of('hide').icon:GetVertexColor())), rgb(st.config.profile.colors.button.blue), 'the icon in the accent')
	stub.click(frame_of('hide'))
	eq(EM:IsBarHideUntilHovered(), false, 'and again: off')
	eq(frame_of('hide').icon:GetTexture(), st.icons.squareMousePointer, 'the first icon back')
	check(not frame_of('hide').on, 'not lit')
	reset()
end)

test('the choice is saved with the bar settings, comes back after a reload, and a click in combat does nothing', function()
	reset()
	EM:Activate()
	over_bar()
	stub.click(frame_of('hide'))
	eq(st.config.global.editModeBar.hide, true, 'saved')
	local keep = st.config.global.editModeBar
	world()
	st.config.global.editModeBar = { hide = keep.hide }
	EM:Activate()
	eq(EM:IsBarHideUntilHovered(), true, 'on after a reload')
	eq(frame_of('hide').icon:GetTexture(), st.icons.squareDashedMousePointer, 'its icon too')
	check(not EM:GetBar():IsShown(), 'the bar is hidden when edit mode opens')
	over_strip()
	tick(0.016)
	over_bar()
	stub.in_combat = true
	stub.click(frame_of('hide'))
	stub.in_combat = false
	eq(EM:IsBarHideUntilHovered(), true, 'a click in combat does nothing')
	reset()
end)

test('the toggle is not in the floating window, and the window does not hide', function()
	reset()
	EM:Activate()
	over_bar()
	stub.click(frame_of('hide'))
	away()
	tick(0.5)
	check(not EM:GetBar():IsShown(), 'hidden')
	over_strip()
	tick(0.016)
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	check(window:IsShown(), 'the window shows')
	check(not frame_of('hide'):IsShown(), 'no toggle in it')
	check(not EM.barStrip:IsShown(), 'no strip')
	away()
	tick(1)
	check(window:IsShown(), 'and it stays however long the mouse is away')
	stub.click(window.dock)
	eq(EM:IsBarHideUntilHovered(), true, 'docked: still on')
	reset()
end)

------------------------------------------------------------------ hidden: the strip

test('while on, the bar is hidden and a 2 px accent strip as wide as the bar shows at the top edge where the bar sits', function()
	reset()
	turn_on()
	tick(0.5)
	local bar = EM:GetBar()
	local strip = EM.barStrip
	check(not bar:IsShown(), 'the bar is hidden')
	check(strip:IsShown() and strip.line:IsShown(), 'the strip shows')
	eq(strip.line:GetHeight(), 2, '2 px tall')
	eq(strip.line:GetWidth(), bar:GetWidth(), 'as wide as the bar')
	eq(strip.line:GetTop(), UIParent:GetTop(), 'at the top edge')
	eq(strip.line:GetLeft(), bar:GetLeft(), 'where the bar sits')
	local c = stub.state(strip.line).color_texture
	eq(string.format('%.2f,%.2f,%.2f', c[1], c[2], c[3]), rgb(st.config.profile.colors.button.blue), 'in the accent')
	check(not strip:IsMouseEnabled(), 'the hot zone takes no clicks: movers under it keep theirs')
	check(strip:GetHeight() > 2 and strip:GetHeight() <= 8, 'the hot zone is a few pixels tall: ' .. strip:GetHeight())
	eq(strip:GetWidth(), bar:GetWidth(), 'and as wide as the bar')
	eq(strip:GetTop(), UIParent:GetTop(), 'at the top edge')
	eq(#P.off(strip), 0, 'whole pixels: ' .. P.report(P.off(strip)))
	reset()
end)

test('the strip follows where the bar is slid and is gone with edit mode, in combat and with the toggle off', function()
	reset()
	EM:Activate()
	EM:SetBarX(300)
	over_bar()
	stub.click(frame_of('hide'))
	away()
	tick(0.5)
	eq(EM.barStrip:GetLeft() - UIParent:GetLeft(), 300, 'at the bar\'s place')
	-- It comes down, is slid, and goes up again where it was left.
	cursor(310, screen_top() - 2)
	tick(0.016)
	check(EM:GetBar():IsShown(), 'down')
	local bar = EM:GetBar()
	stub.mouse_buttons.LeftButton = true
	cursor(500, screen_top() - 30)
	stub.fire_script(bar, 'OnDragStart')
	cursor(700, screen_top() - 30)
	stub.fire_script(bar, 'OnUpdate', 0.016)
	tick(0.1)
	check(bar:IsShown(), 'stays down while it is dragged')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar, 'OnDragStop')
	eq(EM.barStrip:GetLeft() - UIParent:GetLeft(), 500, 'the strip moved with it')
	away()
	tick(0.5)
	check(not bar:IsShown() and EM.barStrip.line:IsShown(), 'up again, strip shown')
	EM:Deactivate()
	check(not EM.barStrip:IsShown(), 'edit mode off: no strip')
	EM:Activate()
	check(EM.barStrip:IsShown() and not bar:IsShown(), 'on again: the same state')
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not EM.barStrip:IsShown() and not bar:IsShown(), 'combat: neither')
	stub.in_combat = false
	EM:Activate()
	check(EM.barStrip:IsShown() and not bar:IsShown(), 'back after combat in the same state: hidden until hovered, strip shown')
	over_bar()
	tick(0.016)
	cursor(EM.barStrip:GetLeft() + 5, screen_top() - 2)
	tick(0.016)
	check(bar:IsShown(), 'and it comes down as before')
	reset()
end)

------------------------------------------------------------------ coming down and going up

test('the mouse over the hot zone brings the bar down at once; it stays while the mouse is over it, and goes up 0.3 s after the mouse leaves', function()
	reset()
	turn_on()
	tick(0.5)
	local bar = EM:GetBar()
	check(not bar:IsShown(), 'hidden')
	-- Beside the strip: nothing.
	cursor(bar_x() - 20, screen_top() - 2)
	tick(0.016)
	check(not bar:IsShown(), 'the mouse beside the strip: still hidden')
	-- Below the hot zone: nothing.
	cursor(bar_x() + 50, screen_top() - 40)
	tick(0.016)
	check(not bar:IsShown(), 'the mouse below the hot zone: still hidden')
	over_strip()
	tick(0.016)
	check(bar:IsShown(), 'over the strip: down at once')
	check(not EM.barStrip.line:IsShown(), 'and the strip line is not drawn over it')
	over_bar()
	tick(5)
	check(bar:IsShown(), 'over the bar: it stays however long')
	check(EM:BarRect() == nil, 'and still covers nothing')
	away()
	tick(0.2)
	check(bar:IsShown(), '0.2 s after the mouse left: still down (the grace)')
	tick(0.09)
	check(bar:IsShown(), '0.29 s: still down')
	tick(0.02)
	check(not bar:IsShown(), '0.31 s: up')
	check(EM.barStrip.line:IsShown(), 'with the strip shown again')
	reset()
end)

test('the grace holds through a mouse that leaves and comes back, so it does not flicker', function()
	reset()
	turn_on()
	tick(0.5)
	local bar = EM:GetBar()
	over_strip()
	tick(0.016)
	away()
	tick(0.25)
	over_bar()
	tick(0.016)
	away()
	tick(0.25)
	check(bar:IsShown(), 'each leave starts the grace again: still down at 0.25 s')
	tick(0.1)
	check(not bar:IsShown(), 'and up 0.3 s after the last')
	reset()
end)

test('it stays down while a list of its own is open, while a box has the keyboard, and goes up 0.3 s after they end', function()
	reset()
	add_mover('hide_list') -- the modules list has a row per module with a mover
	settings().grid = true -- the Grid size box takes the keyboard while Grid is on
	turn_on()
	tick(0.5)
	local bar = EM:GetBar()
	-- The modules list.
	over_strip()
	tick(0.016)
	stub.click(frame_of('modules'))
	eq(W.ListOwner(), frame_of('modules'), 'the modules list is open')
	away()
	tick(2)
	check(bar:IsShown(), 'the modules list is open: stays down')
	W.CloseList()
	tick(0.2)
	check(bar:IsShown(), 'closed: the grace')
	tick(0.2)
	check(not bar:IsShown(), 'and up')
	-- The History list.
	over_strip()
	tick(0.016)
	stub.click(frame_of('history'))
	check(EM:IsHistoryListShown(), 'the History list is open')
	away()
	tick(2)
	check(bar:IsShown(), 'the History list is open: stays down')
	EM:HideHistoryList()
	tick(0.4)
	check(not bar:IsShown(), 'closed: up after the grace')
	-- The Grid size box and the filter.
	for _, key in ipairs({ 'gridSize', 'filter' }) do
		over_strip()
		tick(0.016)
		local box = frame_of(key).edit or frame_of(key)
		box:SetFocus()
		away()
		tick(2)
		check(bar:IsShown(), key .. ' has the keyboard: stays down')
		box:ClearFocus()
		tick(0.4)
		check(not bar:IsShown(), key .. ' let go: up after the grace')
	end
	-- A list of someone else's does not hold it.
	over_strip()
	tick(0.016)
	W.OpenList(CreateFrame('Frame', nil, UIParent), { { key = 'a', label = 'a' } }, nil, function() end)
	away()
	tick(0.4)
	check(not bar:IsShown(), 'a list that is not the bar\'s does not hold it')
	W.CloseList()
	reset()
end)

test('it never comes down while a mover is dragged or pressed, and hides at once when a drag starts', function()
	reset()
	local mover = add_mover('hide_mover')
	turn_on()
	tick(0.5)
	local bar = EM:GetBar()
	-- A mover pressed with the mouse held: the strip does nothing.
	stub.mouse_buttons.LeftButton = true
	EM:Fire('Pressed', mover)
	over_strip()
	tick(0.016)
	check(not bar:IsShown(), 'a mover pressed, mouse held: it does not come down')
	stub.mouse_buttons.LeftButton = nil
	tick(0.016)
	check(bar:IsShown(), 'the mouse up: it comes down')
	away()
	tick(0.4)
	check(not bar:IsShown(), 'and goes up')
	-- A drag: at once, even with the mouse on the bar.
	over_strip()
	tick(0.016)
	check(bar:IsShown(), 'down')
	over_bar()
	EM:StartDrag(mover)
	check(not bar:IsShown(), 'a drag starts: hidden at once, with no grace and the mouse still over it')
	over_strip()
	tick(1)
	check(not bar:IsShown(), 'and it does not come down during the drag, over the strip')
	EM:StopDrag(mover)
	tick(0.016)
	check(bar:IsShown(), 'the drag over with the mouse on the strip: down')
	away()
	tick(0.4)
	check(not bar:IsShown(), 'and up')
	reset()
end)

------------------------------------------------------------------ what it covers

test('hidden, or down, the bar covers nothing: BarRect is nil and BarCoverHeight 0; with the toggle off it is its rect', function()
	reset()
	EM:Activate()
	check(EM:BarRect() ~= nil and EM:BarCoverHeight() > 0, 'off: the bar covers its rect')
	over_bar()
	stub.click(frame_of('hide'))
	eq(EM:BarRect(), nil, 'on, with the bar still there: no rect')
	eq(EM:BarCoverHeight(), 0, 'no cover')
	away()
	tick(0.5)
	eq(EM:BarRect(), nil, 'hidden: no rect')
	eq(EM:BarCoverHeight(), 0, 'no cover')
	over_strip()
	tick(0.016)
	check(EM:GetBar():IsShown(), 'down')
	eq(EM:BarRect(), nil, 'down: still no rect, so /sui does not jump as the bar comes and goes')
	eq(EM:BarCoverHeight(), 0, 'no cover')
	over_bar()
	stub.click(frame_of('hide'))
	check(EM:BarRect() ~= nil, 'off again: the rect')
	check(EM:GetBar():IsShown() and not EM.barStrip:IsShown(), 'the bar shows for good, with no strip')
	reset()
end)

test('/sui is not moved by the bar coming and going while hide until hovered is on', function()
	reset()
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = 0, y = 0 }
	st.Config:Open('Loot')
	local F = H.frames()
	EM:Activate()
	over_bar()
	stub.click(frame_of('hide'))
	away()
	tick(0.5)
	local top = F.window:GetTop()
	over_strip()
	tick(0.016)
	eq(F.window:GetTop(), top, 'the bar coming down does not move it')
	away()
	tick(0.5)
	eq(F.window:GetTop(), top, 'nor going up')
	H.close_all()
	reset()
end)

------------------------------------------------------------------ whole pixels

test('the bar and the strip are on whole pixels while down and hidden, under each look, with the read-back noise, at 1024, 1920 and 2560 wide', function()
	local HAIR = 2 ^ -14
	reset()
	turn_on()
	tick(0.5)
	local bar = EM:GetBar()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name)
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1024, 768 }, { 1920, 1080 }, { 2560, 1440 } }) do
				set_screen(screen[1], screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED')
				local where = ('%s noise %s at %d: '):format(name, noise, screen[1])
				away()
				tick(0.5)
				local off = P.off(EM.barStrip)
				eq(#off, 0, where .. 'hidden, the strip: ' .. P.report(off))
				over_strip()
				tick(0.016)
				check(bar:IsShown(), where .. 'down')
				off = P.off(bar)
				eq(#off, 0, where .. 'down: ' .. P.report(off))
				away()
				tick(0.5)
			end
		end
	end
	reset()
end)
