-- The edit mode bar's floating window (SaftUI-Core/EditMode/Bar/barwindow.lua):
-- Detach turns the bar into a small window holding the same controls in
-- sections, Dock puts them back; the window's pure layout, its whole-pixel
-- drawing under each theme, its drag by the title, the place and the mode it
-- keeps in st.config.global.editModeBar, the screen margin, its level against
-- /sui and the lists, the History list beside it, its status line, the fade
-- during a mover's drag, and the cover height the docked bar gives
-- (EM:BarCoverHeight, which EM:ScreenTop reads).
--
-- Real: the /sui window's world (core/options_window_helpers.lua), edit mode's
-- files and the bar's (load_editmode_bar), a real AceDB profile. The mouse is
-- played by firing scripts (stub.click, stub.fire_script; the game's second
-- argument to OnEnter and OnLeave, motion, is passed as true). Not mimicked by
-- the stub: the frame following the cursor in StartMoving, the anchor the game
-- gives it at the end, the clamp, a font string wrapping: a case places the
-- window itself between the drag's two scripts.

local P = load_test_file('lib/pixels.lua')
local T = load_test_file('lib/theme_helpers.lua')

local H, st, EM, W, History

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
	EM, W = st.EditModeFrames, st.OptionsWidgets
	History = EM.History
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

local function world(client)
	if client then use_client(client) else reset_world() end
	build()
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local settings, control, frame_of, set_screen, look = EMH.settings, EMH.control, EMH.frame_of, EMH.set_screen, EMH.look

set_screen(1920, 1080)

local function rgb(color) return string.format('%.2f,%.2f,%.2f', color:GetRGB()) end

local added = {}
local function add_mover(key)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	local config = { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } }
	local function apply()
		local pos = config.position
		st:SafeReposition(frame, 'bar_window_' .. key, function()
			frame:ClearAllPoints()
			frame:SetPoint(pos.point, UIParent, pos.rel_point or pos.point, tonumber(pos.x_off) or 0, tonumber(pos.y_off) or 0)
		end)
	end
	apply()
	local mover = st:RegisterConfigMover(frame, {
		key = key, label = key, config = function() return config end, apply = apply,
		defaults = function() return { position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 } } end,
	})
	added[key] = true
	return mover, config, frame
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
	local s = settings()
	s.grid, s.snap_grid, s.snap_frames, s.coordinates, s.dim = false, false, false, false, true
	s.show_hidden, s.show_disabled, s.hidden_modules = true, false, {}
	History:Clear()
	EM:SetFilter('')
	EM:SetBarStatus('')
	stub.in_combat = false
	stub.size_noise = 0
	stub.time = 1000
	set_screen(1920, 1080)
	look('thick')
	st.config.profile.misc.clamp_inset = 2
	st:UpdateScreenMargin()
	H.close_all()
	if EM.historyList then EM.historyList:Hide() end
end

local function left_of(frame) return frame:GetLeft() - UIParent:GetLeft() end
local function top_of(frame) return frame:GetTop() - UIParent:GetTop() end
local function drag_title(window, left, top)
	stub.fire_script(window.title, 'OnDragStart')
	window:ClearAllPoints()
	window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', left, top)
	stub.fire_script(window.title, 'OnDragStop')
end
local function margin() return st.config.profile.misc.clamp_inset end

-- The scale runtime for a case: pixel for pixel on the file's 1920 x 1080 screen
-- (1920 units wide), until Apply changes it. reset() puts the screen back.
local function runtime()
	set_screen(1920, 1080)
	start_uiscale({ mode = 'pixel', size = 1 })
end
local function end_runtime()
	st.config.global.uiScale = nil
end

------------------------------------------------------------------ detach and dock

test('Detach turns the bar into a window holding the same controls in sections; Dock puts them back', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local detach = control('detach')
	check(detach, 'the bar has a detach control')
	eq(detach.section, 'title', 'in the title section')
	eq(detach.group.key, 'options', 'in the options group')
	check(frame_of('detach'):GetLeft() > frame_of('options'):GetLeft(), 'at the docked options group end')
	eq(frame_of('detach').icon:GetTexture(), st.icons.pictureInPicture2, 'picture-in-picture-2')
	check(bar:IsShown(), 'docked: the bar')
	eq(EM:IsBarFloating(), false, 'docked to start with')

	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	check(window:IsShown() and not bar:IsShown(), 'the window, not the bar')
	eq(window:GetWidth(), 312, '312 wide')
	eq(EM:IsBarFloating(), true, 'floating')
	eq(st.config.global.editModeBar.floating, true, 'the mode saved')
	eq(frame_of('grid'):GetParent(), window, 'the controls moved into it')
	eq(frame_of('undo'):GetParent(), window, 'all of them')
	check(not frame_of('detach'):IsShown(), 'detach is not shown in the window')
	check(window.dock:IsShown(), 'dock is')
	eq(window.dock.icon:GetTexture(), st.icons.panelTop, 'panel-top')
	eq(window.dock:GetParent(), window, 'dock is in the window')

	-- Sections in order, captions, the controls under them; no Show caption.
	eq(#EM.WINDOW_SECTIONS, 3, 'three sections')
	local captions = {}
	for i, section in ipairs(EM.WINDOW_SECTIONS) do captions[i] = window.captions[section.key]:GetText() end
	eq(table.concat(captions, '|'), 'Grid and snap|Show|Changes', 'Grid and snap, Show, Changes')
	eq(control('caption'), nil, 'there is no Show caption control: the section has one')
	for _, section in ipairs(EM.WINDOW_SECTIONS) do
		local r, g, b = window.captions[section.key]:GetTextColor()
		eq(T.rgb(r, g, b), T.rgb(st.config.profile.colors.text.muted:GetRGB()), section.key .. "'s caption is Text > Muted")
	end
	do -- the filter box's glass and hint
		local box = frame_of('filter')
		eq(T.rgb(box.icon:GetVertexColor()), T.rgb(st.config.profile.colors.text.muted:GetRGB()), "the filter's icon is Text > Muted")
		eq(T.rgb(box.hint:GetTextColor()), T.rgb(st.config.profile.colors.text.muted:GetRGB()), 'and its hint')
	end
	eq(top_of(frame_of('grid')), top_of(frame_of('coordinates')), 'Grid and snap on one line')
	eq(top_of(frame_of('showDisabled')), top_of(frame_of('showHidden')), 'the two Show toggles on one line')
	eq(top_of(frame_of('modules')), top_of(frame_of('filter')), 'the face and the filter on the next')
	check(top_of(frame_of('modules')) < top_of(frame_of('showDisabled')), 'under the toggles')
	check(top_of(frame_of('showDisabled')) < top_of(frame_of('grid')), 'Show is under Grid and snap')
	check(top_of(frame_of('undo')) < top_of(frame_of('modules')), 'Changes is under Show')
	check(top_of(frame_of('undo')) == top_of(frame_of('options')) , 'Options on the Changes line')
	-- The options are right-aligned in Changes; Exit is compact, in the title.
	eq(frame_of('options'):GetRight(), window:GetLeft() + 312 - 12, 'Options ends at the right padding')
	eq(frame_of('exit'):GetWidth(), 26, 'Exit is compact')
	eq(frame_of('exit'):GetRight(), window:GetRight() - 8, 'Exit 8 in from the right')
	eq(window.dock:GetRight(), frame_of('exit'):GetLeft() - 4, 'dock 4 left of Exit')
	check(frame_of('exit').compact, 'compact')
	check(frame_of('exit'):GetBottom() > window:GetTop() - 42, 'Exit is in the title row')
	eq(window.dock:GetTop(), frame_of('exit'):GetTop(), 'level with Dock')
	for _, key in ipairs({ 'grid', 'filter', 'undo', 'options', 'exit' }) do
		eq(frame_of(key):GetFrameLevel(), window:GetFrameLevel() + 2, key .. ': raised again over the window')
	end

	-- Dock: the bar again.
	stub.click(window.dock)
	check(bar:IsShown() and not window:IsShown(), 'the bar again')
	eq(frame_of('grid'):GetParent(), bar, 'the controls back on it')
	eq(EM:IsBarFloating(), false, 'docked')
	eq(st.config.global.editModeBar.floating, false, 'saved')
	check(frame_of('detach'):IsShown(), 'detach is back')
	check(not window.dock:IsShown() or not window:IsShown(), 'and Dock goes with the window')
	eq(frame_of('grid'):GetFrameLevel(), bar:GetFrameLevel() + 2, 'raised over the bar')
	reset()
end)

test('the mode keeps the shown state: detaching with edit mode off shows nothing, and the lists close', function()
	reset()
	EM:SetBarFloating(true)
	local window = EM:GetBarWindow()
	check(not window:IsShown() and not EM:GetBar():IsShown(), 'edit mode off: neither shows')
	EM:Activate()
	check(window:IsShown() and not EM:GetBar():IsShown(), 'on: the window')
	stub.click(frame_of('history'))
	check(EM:IsHistoryListShown(), 'the History list is open')
	frame_of('filter'):SetFocus()
	W.OpenCheckList(frame_of('modules'), { { key = 'a', label = 'A' } }, function() return true end, function() end)
	eq(W.ListOwner(), frame_of('modules'), 'the kit list is open')
	stub.click(window.dock)
	check(not EM:IsHistoryListShown(), 'docking closes the History list')
	eq(W.ListOwner(), nil, 'and the kit list')
	check(not frame_of('filter'):HasFocus(), 'and drops the filter focus')
	stub.click(frame_of('history'))
	frame_of('filter'):SetFocus()
	EM:SetSetting('grid', true)
	frame_of('gridSize').edit:SetFocus()
	stub.click(frame_of('detach'))
	check(not EM:IsHistoryListShown(), 'detaching closes the History list')
	check(not frame_of('filter'):HasFocus(), 'and drops the filter focus')
	check(not frame_of('gridSize').edit:HasFocus(), "and the Grid size box's")
	reset()
end)

test('the mode is saved and comes back after a reload; exit hides the window and combat does too', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	drag_title(window, 300, -120)
	local saved = st.config.global.editModeBar
	eq(tostring(saved.floating) .. ',' .. saved.x .. ',' .. saved.y, 'true,300,-120', 'mode and place saved, whole')
	local config = st.config.global.editModeBar
	world()
	st.config.global.editModeBar = { floating = config.floating, x = config.x, y = config.y }
	check(EM:IsBarFloating(), 'floating in the new world')
	EM:Activate()
	window = EM:GetBarWindow()
	check(window:IsShown() and not EM:GetBar():IsShown(), 'the window shows on Activate')
	eq(frame_of('grid'):GetParent(), window, 'the controls are in it')
	eq(left_of(window) .. ',' .. top_of(window), '300,-120', 'where it was left')
	EM:Deactivate()
	check(not window:IsShown() and not EM:GetBar():IsShown(), 'Exit hides it')
	EM:Activate()
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not window:IsShown(), 'combat hides it with edit mode')
	stub.in_combat = false
	check(EM:IsBarFloating(), 'the mode stays')
	reset()
end)

test('a click on Detach or Dock does nothing in combat', function()
	reset()
	EM:Activate()
	stub.in_combat = true
	stub.click(frame_of('detach'))
	eq(EM:IsBarFloating(), false, 'detach: nothing')
	stub.in_combat = false
	stub.click(frame_of('detach'))
	stub.in_combat = true
	stub.click(EM:GetBarWindow().dock)
	eq(EM:IsBarFloating(), true, 'dock: nothing')
	stub.in_combat = false
	reset()
end)

------------------------------------------------------------------ the layout

test('the window lays out on whole pixels, wraps each section, and is as tall as its contents', function()
	local W_ = EM.WINDOW
	eq(W_.WIDTH .. ',' .. W_.PAD .. ',' .. W_.TITLE .. ',' .. W_.CAPTION .. ',' .. W_.CAPTION_GAP .. ',' .. W_.SECTION_PAD .. ',' .. W_.GAP,
		'312,12,42,13,4,8,4', 'the numbers')
	local rows, height = EM.WindowLayout(312, {
		{ widths = { 26, 54, 26, 26, 26, 26 } },
		{ widths = { 26, 26, 140, 140 } },
		{ widths = { 26, 26, 26, 26, 80 }, aligns = { nil, nil, nil, nil, 'right' } },
	})
	-- Section 1: one line, from PAD, 4 apart.
	local x1 = {}
	for c = 1, 6 do x1[c] = rows[1][c].x end
	eq(table.concat(x1, ','), '12,42,100,130,160,190', 'section 1 on one line')
	eq(rows[1][1].y, rows[1][6].y, 'at one y')
	-- Section 2: the toggles on a line, the face and the filter on the second.
	eq(rows[2][1].y, rows[2][2].y, 'the toggles share a line')
	eq(rows[2][3].y, rows[2][1].y + 26 + 4, 'the face on a second line')
	eq(rows[2][4].y, rows[2][3].y, 'with the filter')
	eq(rows[2][3].x .. ',' .. rows[2][4].x, '12,156', 'from the left, 4 apart')
	-- Section 3: the options end at the right padding, 312 - 12.
	eq(rows[3][5].x + 80, 300, 'the 80 ends at 300')
	eq(rows[3][5].y, rows[3][1].y, 'on the line')
	-- Heights: title 42; sections of 8 + 13 + 4 + lines + 8; a 1px line between.
	eq(rows[1].caption, 42 + 8, 'the first caption')
	eq(rows[1][1].y, 42 + 8 + 13 + 4, 'the first line')
	eq(rows[2].rule, rows[1].bottom, 'a 1px line under section 1')
	eq(height, 251, 'as tall as its contents')
	for s = 1, 3 do
		for c, spot in ipairs(rows[s]) do
			eq(spot.x, math.floor(spot.x), 'x whole: ' .. s .. '/' .. c)
			eq(spot.y, math.floor(spot.y), 'y whole: ' .. s .. '/' .. c)
		end
	end
	eq(height, math.floor(height), 'height whole')
	-- A width of 0 is not shown; a section with none has no caption and no line.
	local rows2, height2 = EM.WindowLayout(312, { { widths = { 0, 26 } }, { widths = { 0 } }, { widths = { 26 } } })
	eq(rows2[1][1], nil, 'a 0 is skipped')
	eq(rows2[1][2].x, 12, 'and the next starts the line')
	eq(rows2[2].top, nil, 'an empty section has no place')
	eq(height2, 42 + (8 + 13 + 4 + 26 + 8) + 1 + (8 + 13 + 4 + 26 + 8), 'two sections and a line')
	-- A wide control wraps; right-aligned ones end the line.
	local rows3 = EM.WindowLayout(312, { { widths = { 200, 100 } }, { widths = { 26, 80, 26 }, aligns = { nil, 'right', nil } } })
	eq(rows3[1][2].y, rows3[1][1].y + 30, 'a control that does not fit wraps')
	eq(rows3[2][2].x + 80, 300, 'right-aligned: at the right end')
	eq(rows3[2][3].y, rows3[2][2].y + 30, 'and it ends the line')
end)

local function frames_in_window_whole(where)
	local window = EM:GetBarWindow()
	for _, noise in ipairs({ 0, 2 ^ -14, -(2 ^ -14) }) do
		stub.size_noise = noise
		EM:LayoutBar()
		local off = P.off(window)
		eq(#off, 0, where .. ' (noise ' .. noise .. '): ' .. P.report(off))
	end
	stub.size_noise = 0
end

for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
	test('whole pixels: the window, its controls, its status line and after a drag between pixels, ' .. name, function()
		reset()
		look(name)
		for _, size in ipairs({ { 1920, 1080 }, { 1024, 768 } }) do
			set_screen(size[1], size[2])
			EM:Activate()
			stub.click(frame_of('detach'))
			local window = EM:GetBarWindow()
			EM:SetSetting('grid', true)
			frames_in_window_whole(name .. ' ' .. size[1])
			EM:SetBarStatus('Undid: Moved Player. Its mover is hidden by Show or the filter.')
			frames_in_window_whole(name .. ' ' .. size[1] .. ' with a status')
			EM:SetBarStatus('')
			-- A drag that ends between pixels.
			stub.fire_script(window.title, 'OnDragStart')
			window:ClearAllPoints()
			window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 133.37, -91.62)
			stub.fire_script(window.title, 'OnDragStop')
			local x, y = left_of(window), top_of(window)
			eq(x, math.floor(x), name .. ': the window ends on a whole x')
			eq(y, math.floor(y), name .. ': and y')
			frames_in_window_whole(name .. ' ' .. size[1] .. ' after a drag')
			stub.click(window.dock)
			EM:Deactivate()
		end
		reset()
	end)
end

test('the window lays out again on the screen events and at a new size, and its height follows its contents', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	local height = window:GetHeight()
	eq(height, 251, 'tall enough for its sections')
	EM:SetBarStatus('Reset Player')
	check(window:GetHeight() > height, 'a status line makes room under Changes')
	local text = EM.statusText
	eq(text:GetParent(), window, 'the status line is in the window')
	check(text:GetTop() <= frame_of('undo'):GetBottom(), 'under the Changes section')
	check(text:GetLeft() >= window:GetLeft() + 12 - 0.5, 'inside the padding')
	check(not EM.statusCut, 'never cut in the window')
	eq(text:GetJustifyH(), 'LEFT', 'from the left')
	EM:SetBarStatus('')
	eq(window:GetHeight(), height, 'back when it clears')
	set_screen(1024, 768)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(window:GetWidth(), 312, 'still 312')
	st.config.global.editModeBar.x = 900
	window:ClearAllPoints()
	window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 900, -80)
	stub.fire_event('UI_SCALE_CHANGED')
	check(window:GetRight() - UIParent:GetLeft() <= 1024 - margin(), 'UI_SCALE_CHANGED puts it back inside too')
	check(window:GetRight() - UIParent:GetLeft() <= 1024, 'on the smaller screen')
	-- Docked again, the bar has no status line: the message is a tooltip.
	stub.click(EM:GetBarWindow().dock)
	EM:SetBarStatus('Reset Player')
	check(not EM.statusText:IsShown() and EM.statusCut, 'no line on the bar again')
	reset()
end)

------------------------------------------------------------------ the drag, the margin and the saved place

test('dragged by its title it stays inside the screen margin, and keeps its place across a reload', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	check(window:IsMovable(), 'movable')
	check(window:IsClampedToScreen(), 'kept in the margin by the game too (st:KeepInScreenMargin)')
	eq(stub.state(window.title).drag_buttons[1], 'LeftButton', 'dragged by its title row')
	check(window.title:IsMouseEnabled(), 'the title takes the mouse')
	stub.fire_script(window.title, 'OnDragStart')
	eq(stub.state(window).moving, true, 'StartMoving')
	window:ClearAllPoints()
	window:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', -150, -90)
	stub.fire_script(window.title, 'OnDragStop')
	eq(stub.state(window).moving, false, 'StopMovingOrSizing')
	check(left_of(window) >= margin(), 'left is in the margin: ' .. left_of(window))
	local saved = st.config.global.editModeBar
	eq(saved.x, left_of(window), 'saved x is where it shows, whole')
	eq(saved.y, top_of(window), 'saved y too')
	-- Past the top and bottom, and the right.
	drag_title(window, 5000, 400)
	check(UIParent:GetRight() - window:GetRight() >= margin(), 'right edge in the margin')
	check(window:GetTop() <= UIParent:GetTop() - margin(), 'top in the margin')
	drag_title(window, 100, -5000)
	check(window:GetBottom() - UIParent:GetBottom() >= margin(), 'bottom in the margin')
	drag_title(window, 321.4, -210.6)
	eq(left_of(window) .. ',' .. top_of(window), '321,-211', 'rounded to whole pixels')
	eq(st.config.global.editModeBar.x .. ',' .. st.config.global.editModeBar.y, '321,-211', 'and saved so')
	reset()
end)

test("with no saved place it is centred 80 down; a saved place the screen no longer has comes back inside the margin", function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	eq(left_of(window), math.floor((UIParent:GetWidth() - 312) / 2), 'centred')
	eq(top_of(window), -80, '80 down')
	EM:Deactivate()
	st.config.global.editModeBar = { floating = true, x = 3000, y = -80 }
	set_screen(1024, 768)
	EM:Activate()
	check(window:IsShown(), 'shown')
	check(window:GetRight() - UIParent:GetLeft() <= 1024 - margin(), 'the right edge is inside: ' .. window:GetRight())
	eq(st.config.global.editModeBar.x, 3000, 'the saved place is kept as it was')
	set_screen(800, 600)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	check(window:GetRight() - UIParent:GetLeft() <= 800 - margin(), 'again at 800 wide')
	-- A bad save falls back to the default place.
	EM:Deactivate()
	st.config.global.editModeBar = { floating = true, x = 'a', y = {} }
	set_screen(1920, 1080)
	EM:Activate()
	eq(left_of(window) .. ',' .. top_of(window), math.floor((1920 - 312) / 2) .. ',-80', 'bad values: the default place')
	reset()
end)

test('a change of the screen edge margin puts the window back inside', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	drag_title(window, 0, -80)
	eq(left_of(window), margin(), 'at the margin')
	st.config.profile.misc.clamp_inset = 30
	st:UpdateScreenMargin()
	eq(left_of(window), 30, 'pushed in to the new margin')
	st.config.profile.misc.clamp_inset = 2
	st:UpdateScreenMargin()
	reset()
end)

------------------------------------------------------------------ over and under

test('the window sits over /sui and under the lists; the History list opens beside it', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	eq(window:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	eq(window:GetFrameLevel(), EM.BAR.LEVEL, 'level 9500')
	st.Config:Open()
	local sui = H.frames().window
	check(window:GetFrameLevel() > sui:GetFrameLevel(), 'over /sui')
	local list = EM:GetHistoryList()
	check(list:GetFrameLevel() > window:GetFrameLevel(), 'the History list over it')
	W.OpenCheckList(frame_of('modules'), { { key = 'a', label = 'A' } }, function() return true end, function() end)
	local owned = false
	for _, frame in ipairs({ UIParent:GetChildren() }) do
		if frame:IsShown() and frame:GetFrameStrata() == 'TOOLTIP' then owned = true end
	end
	check(owned, "the Show face's check list is in TOOLTIP strata, over the window")
	W.CloseList()

	-- Beside the window: its top left 8 right of the window's top right.
	drag_title(window, 600, -200)
	stub.click(frame_of('history'))
	check(EM:IsHistoryListShown(), 'open')
	eq(left_of(list), left_of(window) + 312 + 8, 'left = window right + 8')
	eq(top_of(list), top_of(window), 'level with its top')
	-- No room on the right: its top right 8 left of the window's top left.
	drag_title(window, 5000, -200)
	eq(UIParent:GetRight() - UIParent:GetLeft() - (left_of(window) + 312) , margin(), 'the window is at the right edge')
	check(list:GetRight() == window:GetLeft() - 8, 'right = window left - 8: ' .. list:GetRight() .. ' vs ' .. window:GetLeft())
	eq(top_of(list), top_of(window), 'level with its top')
	-- Back to the left side when there is room.
	drag_title(window, 100, -200)
	eq(left_of(list), left_of(window) + 312 + 8, 'on the right again')
	-- Docked: under the History button as before.
	stub.click(EM:GetBarWindow().dock)
	check(not EM:IsHistoryListShown(), 'docking closes it')
	stub.click(frame_of('history'))
	eq(list:GetRight(), frame_of('history'):GetRight(), 'docked: its top right on the button')
	reset()
end)

test('the window under Blizzard on both clients, and while a mover is dragged', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local where = client .. ': '
		look('blizzard')
		EM:Activate()
		stub.click(frame_of('detach'))
		local window = EM:GetBarWindow()
		local reference = CreateFrame('Frame', nil, UIParent)
		st:SetBackdrop(reference, 'theme', 'theme', 'panel')
		check(T.art(window.backdrop) ~= '', where .. 'the window wears Blizzard art')
		eq(T.art(window.backdrop), T.art(reference.backdrop), where .. "the panel kind's Blizzard art")
		for _, button in ipairs({ window.dock, frame_of('exit'), frame_of('undo') }) do
			eq(button.backdropInfo, nil, where .. 'no box under Blizzard')
		end
		local pieces = 0
		for _, region in ipairs({ window.dock:GetRegions() }) do
			local file = region:GetObjectType() == 'Texture' and region:GetTexture()
			if type(file) == 'string' and file:match('UI%-Panel%-Button%-Up$') then pieces = pieces + 1 end
		end
		eq(pieces, 3, where .. "dock wears Blizzard's panel button art")
		pieces = 0
		for _, region in ipairs({ frame_of('exit'):GetRegions() }) do
			local file = region:GetObjectType() == 'Texture' and region:GetTexture()
			if type(file) == 'string' and file:match('UI%-Panel%-Button%-Up$') then pieces = pieces + 1 end
		end
		eq(pieces, 3, where .. 'and Exit')
		look('thick')
		check(window.dock.backdropInfo ~= nil, where .. 'back to Thick: dock has its box again')
		EM:Deactivate()
	end
	world()
end)

test('while a mover is dragged the window fades and takes no mouse, and comes back; it is no mover', function()
	reset()
	local mover = add_mover('floaty')
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	check(window:IsMouseEnabled(), 'the window takes the mouse (a click on it selects no mover under it)')
	check(frame_of('undo'):IsMouseEnabled() and window.dock:IsMouseEnabled() and window.title:IsMouseEnabled(), 'its controls do')
	EM:StartDrag(mover)
	eq(window:GetAlpha(), EM.BAR.DRAG_ALPHA, 'faded')
	check(not window:IsMouseEnabled() and not frame_of('undo'):IsMouseEnabled(), 'off the mouse')
	check(not window.dock:IsMouseEnabled() and not window.title:IsMouseEnabled(), 'dock and the title too')
	check(not frame_of('filter'):IsMouseEnabled(), 'the filter box too')
	EM:StopDrag(mover)
	eq(window:GetAlpha(), 1, 'full again')
	check(window:IsMouseEnabled() and frame_of('undo'):IsMouseEnabled() and window.dock:IsMouseEnabled() and window.title:IsMouseEnabled(), 'the mouse is back')
	-- A drag that never reported its end is repaired by Exit and entering again.
	EM:StartDrag(mover)
	EM:Deactivate()
	EM:Activate()
	eq(window:GetAlpha(), 1, 'whole again after Exit and Activate')
	check(window:IsMouseEnabled(), 'with its mouse')
	for _, registered in pairs(EM.movers) do check(registered.frame ~= window, 'the window is no mover, so nothing snaps to it') end
	reset()
end)

test('the History list fades with the window while a mover is dragged', function()
	reset()
	local mover = add_mover('floaty')
	EM:Activate()
	stub.click(frame_of('detach'))
	stub.click(frame_of('history'))
	local list = EM:GetHistoryList()
	EM:StartDrag(mover)
	eq(list:GetAlpha(), EM.BAR.DRAG_ALPHA, 'faded')
	EM:StopDrag(mover)
	eq(list:GetAlpha(), 1, 'full')
	reset()
end)

------------------------------------------------------------------ what keeps clear of the bar

test('the bar covers its rect at the top while docked and shown, nothing floating or hidden; BarCoverHeight is that rect\'s height', function()
	reset()
	local top = UIParent:GetHeight()
	local inset = st:ThemeInset('theme', 'theme', 'panel')
	eq(EM:BarCoverHeight(), 0, 'not built or shown: 0')
	eq(EM:BarRect(), nil, 'and no rect')
	EM:Activate()
	eq(EM:BarCoverHeight(), EM.BAR.HEIGHT + inset, 'docked and shown: its height and the line it draws')
	local rect = EM:BarRect()
	eq(rect.top, top, 'flush with the screen top')
	eq(rect.top - rect.bottom, EM:BarCoverHeight(), 'BarCoverHeight is its height')
	local bar = EM:GetBar()
	eq(rect.left, bar:GetLeft() - UIParent:GetLeft() - inset, 'its left, the line it draws included')
	eq(rect.right, bar:GetRight() - UIParent:GetLeft() + inset, 'and its right')
	stub.click(frame_of('detach'))
	eq(EM:BarCoverHeight(), 0, 'floating: 0')
	eq(EM:BarRect(), nil, 'no rect')
	-- The label can sit in the strip the bar covered.
	local spot = { EM.CoordinatesSpot('TOPLEFT', { left = 100, right = 260, bottom = 1007, top = 1035 }, 120, 12, 1920, top) }
	eq(spot[2], 1037, 'above the outline, where the bar would have been')
	stub.click(EM:GetBarWindow().dock)
	eq(EM:BarCoverHeight(), EM.BAR.HEIGHT + inset, 'docked again: back')
	EM:Deactivate()
	eq(EM:BarCoverHeight(), 0, 'hidden: 0')
	EM:SetBarFloating(true)
	EM:Activate()
	eq(EM:BarCoverHeight(), 0, 'floating on Activate: 0')
	reset()
end)

test('a mover can be dragged into the strip the bar covered once the bar floats, and nothing moves when it docks', function()
	reset()
	local mover, config = add_mover('strip')
	EM:Activate()
	stub.click(frame_of('detach'))
	config.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 100, y_off = -5 }
	EM.movers.strip.def.apply()
	local l, r, b, t = EM.GetOutlineRect(mover)
	check(t > UIParent:GetHeight() - EM.BAR.HEIGHT, 'its outline is up in the strip')
	stub.click(EM:GetBarWindow().dock)
	eq(config.position.y_off, -5, 'docking leaves its place alone')
	-- ...and the filter's Enter selection reaches it under the bar.
	EM:SetFilter('strip')
	EM:SelectFirstMatch()
	eq(EM.selected, mover, 'Enter in the filter selects it')
	reset()
end)

test('the Coordinates label follows the mode: under the bar it keeps clear of it, and it re-places itself when the bar detaches or docks', function()
	reset()
	local mover, config = add_mover('coord')
	local bar_x = 0
	EM:Activate()
	local rect = EM:BarRect()
	-- A mover right under the bar's rect, its top at the screen's top.
	config.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = rect.left + 20, y_off = -2 }
	EM.movers.coord.def.apply()
	EM:SetSetting('coordinates', true)
	EM:Select(mover)
	local docked = EM.coordinates:GetTop()
	check(docked <= rect.bottom + 1e-3, 'docked: the label is under the bar, not on it: ' .. docked .. ' vs ' .. rect.bottom)
	stub.click(frame_of('detach'))
	local floating = EM.coordinates:GetTop()
	check(floating > docked, 'floating: the label can go above the frame, in the strip: ' .. docked .. ' -> ' .. floating)
	stub.click(EM:GetBarWindow().dock)
	eq(EM.coordinates:GetTop(), docked, 'docked: under the bar again')
	-- Beside the bar the strip is free: the label goes above the frame as when floating.
	config.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 100, y_off = -2 }
	EM.movers.coord.def.apply()
	EM:UpdateCoordinates()
	eq(EM.coordinates:GetTop(), floating - 0, 'beside the bar: where it is when floating')
	reset()
end)

------------------------------------------------------------------ fix round 1

local function levels_under(frame, base, out)
	for _, child in ipairs({ frame:GetChildren() }) do
		out[#out + 1] = child:GetFrameLevel() - base
		levels_under(child, base, out)
	end
	return out
end

-- Every control's level, and each descendant's, relative to the control's parent.
local function level_shape()
	local out = {}
	for _, c in ipairs(EM:BarControls()) do
		local base = c.frame:GetParent():GetFrameLevel()
		out[#out + 1] = c.key .. ':' .. (c.frame:GetFrameLevel() - base) .. '/' .. table.concat(levels_under(c.frame, base, {}), ',')
	end
	return table.concat(out, ' ')
end

test("a long status after a short one grows the window to the long one's wrapped height: it is measured with no height of its own", function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	local base = window:GetHeight()
	EM:SetBarStatus('Reset Player')
	eq(window:GetHeight(), base + 13 + 8, 'one line (the small font is 13 tall in the stub)')
	eq(EM.statusText:GetStringHeight(), 13, 'one line')
	local long = 'Undid: Moved Player. Its mover is hidden by Show or the filter.'
	EM:SetBarStatus(long)
	eq(window:GetHeight(), base + 26 + 8, 'two lines of 288: the whole of it, not the height the short one left')
	eq(EM.statusText:GetStringHeight(), 26, 'the text is not cut to its old height')
	EM:SetBarStatus('Reset Player')
	eq(window:GetHeight(), base + 13 + 8, 'and back to one line')
	reset()
end)

test('a control and everything under it keep the same levels over their parent through any number of Detach and Dock', function()
	reset()
	EM:Activate()
	EM:SetSetting('grid', true)
	local docked = level_shape()
	check(docked:find('gridSize:2/', 1, true), 'the number box is two over the bar')
	for round = 1, 4 do
		stub.click(frame_of('detach'))
		eq(level_shape(), docked, 'floating, round ' .. round .. ': the same shape over the window')
		stub.click(EM:GetBarWindow().dock)
		eq(level_shape(), docked, 'docked, round ' .. round .. ': the same shape over the bar')
	end
	stub.click(frame_of('detach'))
	eq(EM:GetBarWindow().dock:GetFrameLevel(), EM:GetBarWindow():GetFrameLevel() + 2, 'Dock is two over the window, over its title')
	check(EM:GetBarWindow().dock:GetFrameLevel() > EM:GetBarWindow().title:GetFrameLevel(), 'so it takes the clicks')
	reset()
end)

test('a window hidden mid-drag stops moving; a screen change that fires before UIParent resizes is placed again on the next frame', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	stub.fire_script(window.title, 'OnDragStart')
	eq(stub.state(window).moving, true, 'moving')
	EM:Deactivate()
	eq(stub.state(window).moving, false, 'hiding it stops the move')
	EM:Activate()
	st.config.global.editModeBar.x = 1500
	set_screen(1920, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	set_screen(1024, 768) -- UIParent gets its new size after the event
	stub.run_timers()
	check(window:GetRight() - UIParent:GetLeft() <= 1024 - margin(), 'placed against the new size: ' .. window:GetRight())
	reset()
end)

test('the status clears and the default place is written on a mode change; centring in a line; the line under the title; Dock raised', function()
	reset()
	EM:Activate()
	EM:SetBarStatus('Reset Player')
	stub.click(frame_of('detach'))
	eq(EM.statusText:GetText(), '', 'a mode change clears the status')
	local saved = st.config.global.editModeBar
	eq(saved.x .. ',' .. saved.y, math.floor((1920 - 312) / 2) .. ',-80', 'the default place is written on Detach')
	local window = EM:GetBarWindow()
	eq(frame_of('gridSize'):GetTop(), frame_of('grid'):GetTop() - 2, 'the 22 tall box is centred in its 26 line')
	local rule = window.rules[1]
	eq(rule:GetTop(), window:GetTop() - (EM.WINDOW.TITLE - 1), 'a line under the title')
	eq(rule:GetWidth(), 312, 'across the window')
	reset()
end)

test('a right-aligned control ends its line even where room is left', function()
	local rows = EM.WindowLayout(312, { { widths = { 26, 80, 26 }, aligns = { nil, 'right', nil } } })
	eq(rows[1][2].y, rows[1][1].y, 'the options on the first line')
	eq(rows[1][3].y, rows[1][1].y + 30, 'the next one on a line of its own, though it would fit')
end)

test('the History list takes the side with room inside the margin; with room on neither, the side with more', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	local list = EM:GetHistoryList()
	st.config.profile.misc.clamp_inset = 30
	st:UpdateScreenMargin()
	stub.click(frame_of('history'))
	drag_title(window, 1271, -100) -- 299 from the margin: it does not fit on the right
	eq(list:GetRight(), window:GetLeft() - 8, 'left of the window: the margin counts')
	drag_title(window, 1260, -100) -- 310: it fits
	eq(list:GetLeft(), window:GetRight() + 8, 'right of the window')
	set_screen(800, 600)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	drag_title(window, 200, -100)
	eq(list:GetLeft(), window:GetRight() + 8, 'room on neither side: the right has more (278 against 190)')
	drag_title(window, 290, -100)
	eq(list:GetRight(), window:GetLeft() - 8, 'and here the left (280 against 188)')
	reset()
end)

-- The profile update (the pass) taken out, so what a case shows is the scale's
-- change callback alone, and not the margin's hooks the pass would also run.
-- Returns the call that puts it back.
local function without_the_pass()
	local own = rawget(st.Config, 'UpdateConfig')
	st.Config.UpdateConfig = function() end
	return function() st.Config.UpdateConfig = own end
end

test('the change callback puts the floating window and the History list back inside the margin', function()
	reset()
	local restore = without_the_pass()
	runtime()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	local list = EM:GetHistoryList()
	st.config.profile.misc.clamp_inset = 20
	st:UpdateScreenMargin()
	stub.click(frame_of('history'))
	drag_title(window, 1250, -100)
	local width = UIParent:GetWidth()
	eq(list:GetLeft(), window:GetRight() + 8, 'on a 1920 wide screen the list is right of the window')
	check(list:GetRight() - UIParent:GetLeft() <= width - margin(), 'and inside the margin')
	local saved = st.config.global.editModeBar.x
	-- Automatic at 150%: 1706.7 units wide, with no screen event.
	st.UIScale:Apply({ mode = 'auto', size = 1.5 })
	stub.run_timers()
	local narrower = UIParent:GetWidth()
	check(narrower < 1710 and narrower > 1700, 'the screen is 1707 units wide now: ' .. narrower)
	check(window:GetRight() - UIParent:GetLeft() <= narrower - margin(), 'the window is inside the margin')
	check(list:GetRight() - UIParent:GetLeft() <= narrower - margin(), 'the list is inside it too: ' .. list:GetRight())
	check(list:GetLeft() - UIParent:GetLeft() >= margin(), 'and not off the left edge')
	eq(list:GetRight(), window:GetLeft() - 8, 'it went to the window\'s left, where there is room')
	eq(st.config.global.editModeBar.x, saved, 'the saved place is left as it was')
	-- Back: the window is where it was saved.
	st.UIScale:Apply(nil)
	stub.run_timers()
	eq(left_of(window), saved, 'and back where it was saved')
	check(UIParent:GetWidth() > 1900, 'on the wide screen')
	eq(#take_errors(), 0, 'no errors')
	restore()
	end_runtime()
	reset()
end)

-- Last: a group added to the bar stays in it for the rest of the file.
test('a group added while floating is in the window, and a control whose section the window lacks goes in the last one', function()
	reset()
	EM:Activate()
	stub.click(frame_of('detach'))
	local window = EM:GetBarWindow()
	EM:AddBarGroup({
		key = 'zzextra', order = 95, side = 'right',
		controls = function(parent)
			local button = W.IconButton(parent, st.icons.history, function() return 'Extra', { 'x' } end)
			return { { key = 'extra', frame = button, Lay = function() return 26 end } }
		end,
	})
	eq(frame_of('extra'):GetParent(), window, 'built into the window')
	eq(frame_of('extra'):GetFrameLevel(), window:GetFrameLevel() + 2, 'two over it')
	check(frame_of('extra'):IsShown(), 'shown')
	local _, anchor = frame_of('extra'):GetPoint(1)
	eq(anchor, window, 'anchored to the window, not the hidden bar')
	check(top_of(frame_of('extra')) <= top_of(frame_of('undo')), 'in the last section, under the Show one')
	world()
end)
