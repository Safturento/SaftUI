-- Edit mode's bar (SaftUI-Core/EditMode/Bar/): the strip across the top of the
-- screen that holds edit mode's controls, its layout at each width and stage,
-- its looks, and what leaving the /sui footer means: the footer holds Reload
-- UI, the status line, the page's own control and Close, and the sidebar's Edit
-- mode button is on in the accent while edit mode is.
--
-- Real: the /sui window's world (core/options_window_helpers.lua: the real
-- Config, the kit's controls, the window), edit mode's files and the bar's
-- (load_editmode_bar). The mouse is played by firing scripts (stub.fire_script,
-- stub.click: the game's second argument to OnEnter and OnLeave, motion, is
-- passed as true), the screen by stub.screen_width and UIParent's scale.
-- A case that needs another client builds the world again (world(client)), so
-- the helpers are read from H, never kept in a local.

local P = load_test_file('lib/pixels.lua')
local T = load_test_file('lib/theme_helpers.lua')

local H, st, EM, OW, W

-- The world: the window's, edit mode's files and the bar's, edit mode enabled.
local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, OW, W = st.EditModeFrames, st.OptionsWindow, st.OptionsWidgets
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

-- A fresh world on a client (nil: Forever).
local function world(client)
	if client then use_client(client) else reset_world() end
	build()
end

build()

local function settings() return EM:GetSettings() end
local function control(key) return EM:BarControl(key) end
local function frame_of(key) return EM:BarControl(key).frame end

-- A screen of width x height physical pixels at SaftUI's scale: a UIParent unit
-- a pixel.
local function set_screen(width, height)
	stub.screen_width, stub.screen_height = width, height
	UIParent:SetScale(768 / height)
end

-- What fn printed to chat, joined.
local function printed(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return table.concat(lines, '\n')
end

local function add_mover(key, extra)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint('CENTER')
	local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
	local spec = { key = key, config = function() return config end, apply = function() end }
	for field, value in pairs(extra or {}) do spec[field] = value end
	return st:RegisterConfigMover(frame, spec)
end

-- The tooltip's lines as they are added: { text, color } each, with its title first.
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
local function hover(owner, target)
	watch_tooltip()
	lines = {}
	stub.fire_script(target or owner, 'OnEnter', true)
end

local function rgb(color) return string.format('%.2f,%.2f,%.2f', color:GetRGB()) end

-- Puts SaftUI's theme on, as the Theme tab does.
local function look(name)
	st.config.profile.theme.name = name
	st:ThemeChanged()
end

local function reset_edit_mode()
	if EM.active then EM:Deactivate() end
	for _, key in ipairs({ 'grid', 'snap_grid', 'snap_frames' }) do settings()[key] = false end
	settings().grid_size = 32
	settings().dim, settings().coordinates = true, false
	stub.in_combat = false
	stub.size_noise = 0
	H.close_all()
end

local function textures_shown(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 then out[#out + 1] = region end
	end
	return out
end

local function atlases_of(frame)
	local out = {}
	for _, region in ipairs(textures_shown(frame)) do
		if region:GetAtlas() then out[#out + 1] = region:GetAtlas() end
	end
	table.sort(out)
	return table.concat(out, ',')
end

local function panel_pieces(frame)
	local n = 0
	for _, region in ipairs(textures_shown(frame)) do
		local file = region:GetTexture()
		if type(file) == 'string' and file:match('^Interface\\Buttons\\UI%-Panel%-Button%-Up$') then n = n + 1 end
	end
	return n
end

------------------------------------------------------------------ shown and hidden

test('the bar shows while edit mode is on, with /sui open or closed, and hides when it turns off', function()
	EM:Activate()
	local bar = EM:GetBar()
	check(bar:IsShown(), 'on, /sui closed: shown')
	st.Config:Open('Loot')
	check(bar:IsShown(), '/sui open: still shown')
	H.close_all()
	EM:Deactivate()
	check(not bar:IsShown(), 'off: hidden')
	reset_edit_mode()
end)

test('across the top, 40 tall, drawn as a panel in the theme; the bar itself takes no mouse, its controls do', function()
	EM:Activate()
	local bar = EM:GetBar()
	eq(bar:GetHeight(), 40, '40 tall')
	eq(bar:GetTop(), UIParent:GetTop(), 'at the top')
	eq(bar:GetLeft(), UIParent:GetLeft(), 'from the left')
	eq(bar:GetWidth(), UIParent:GetWidth(), 'full width')
	eq(st:DrawnKind(bar), 'panel', 'a panel')
	check(not bar:IsMouseEnabled(), 'a click between controls reaches the mover under it')
	check(frame_of('grid'):IsMouseEnabled(), 'the controls take it')
	eq(bar:GetFrameStrata() .. bar:GetFrameLevel(), 'FULLSCREEN_DIALOG9500', 'over the movers and /sui')
	for _, key in ipairs({ 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'options' }) do
		local frame = frame_of(key)
		eq(frame:GetFrameLevel(), 9502, key .. ': two over the bar')
		eq(frame:GetParent(), bar, key .. ': a child of the bar')
		local _, _, _, _, y = frame:GetPoint(1)
		local expect = ({ gridSize = -9 })[key] or -7
		eq(y, expect, key .. ': centred on whole pixels')
	end
	reset_edit_mode()
end)

test('the groups and their controls: exit, then the grid group (grid, size, two snaps, Dim world, Coordinates), Options on the right', function()
	EM:Activate()
	local keys = {}
	for _, key in ipairs({ 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'options' }) do
		local c = EM:BarControl(key)
		check(c and c.frame and c.Lay, key .. ' is a control with a frame and a Lay')
		keys[#keys + 1] = ('%s:%s'):format(key, c.section)
	end
	eq(table.concat(keys, ' '), 'exit:title grid:grid gridSize:grid snapGrid:grid snapFrames:grid dim:grid coordinates:grid options:changes', "each in its group's section")
	eq(control('options').align, 'right', 'Options aligns right')
	local xs = {}
	for _, key in ipairs({ 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'options' }) do xs[#xs + 1] = frame_of(key):GetLeft() end
	for i = 2, #xs do check(xs[i] > xs[i - 1], 'left to right: ' .. i) end
	eq(xs[1] - UIParent:GetLeft(), 10, 'Exit 10 in')
	eq(UIParent:GetRight() - frame_of('options'):GetRight(), 10, 'Options 10 from the right')
	eq(EM:BarControl('nothing'), nil, 'no such control')
	reset_edit_mode()
end)

------------------------------------------------------------------ the controls

test('Grid, Snap to grid and Snap to frames toggle their settings, show on in the accent, and are saved in the profile', function()
	EM:Activate()
	for _, case in ipairs({ { 'grid', 'grid' }, { 'snapGrid', 'snap_grid' }, { 'snapFrames', 'snap_frames' } }) do
		local key, setting = case[1], case[2]
		local frame = frame_of(key)
		check(not frame.on and not settings()[setting], key .. ': off at first')
		stub.click(frame)
		check(settings()[setting] == true and frame.on == true, key .. ': on')
		eq(st.config.profile.editmode[setting], true, key .. ': saved in the profile')
		stub.fire_script(frame, 'OnLeave', true)
		eq(rgb(CreateColor(frame.icon:GetVertexColor())), rgb(st.config.profile.colors.button.blue), key .. ': its icon in the accent')
		if key == 'grid' then check(EM.gridFrame:IsShown(), 'the grid shows') end
		stub.click(frame)
		check(settings()[setting] == false and not frame.on, key .. ': off again')
		if key == 'grid' then check(not EM.gridFrame:IsShown(), 'the grid hides') end
	end
	reset_edit_mode()
end)

test('Dim world and Coordinates toggle their settings, light in the accent, are saved in the profile, and have tooltips', function()
	EM:Activate()
	local dim, coordinates = frame_of('dim'), frame_of('coordinates')
	eq(dim.icon:GetTexture(), st.icons.layers, 'Dim world: the layers icon')
	eq(coordinates.icon:GetTexture(), st.icons.mapPin, 'Coordinates: the map pin icon')
	check(dim.on == true and settings().dim == true, 'Dim world is on by default')
	check(not coordinates.on and settings().coordinates == false, 'Coordinates is off by default')
	check(EM.dimFrame:IsShown(), 'the world is dimmed')
	stub.click(dim)
	check(settings().dim == false and not dim.on and not EM.dimFrame:IsShown(), 'Dim world off: setting, light and layer')
	eq(st.config.profile.editmode.dim, false, 'saved in the profile')
	stub.click(dim)
	check(settings().dim == true and dim.on and EM.dimFrame:IsShown(), 'Dim world on again')
	stub.click(coordinates)
	check(settings().coordinates == true and coordinates.on == true, 'Coordinates on')
	eq(st.config.profile.editmode.coordinates, true, 'saved in the profile')
	stub.fire_script(coordinates, 'OnLeave', true)
	eq(rgb(CreateColor(coordinates.icon:GetVertexColor())), rgb(st.config.profile.colors.button.blue), 'its icon in the accent')
	stub.click(coordinates)
	check(settings().coordinates == false and not coordinates.on, 'Coordinates off again')

	hover(dim)
	eq(lines[1].text, 'Dim world', 'title')
	eq(lines[2].text, 'Darkens the game world behind your frames while edit mode is on.', "the spec's line")
	stub.fire_script(dim, 'OnLeave', true)
	hover(coordinates)
	eq(lines[1].text, 'Coordinates', 'title')
	eq(lines[2].text, "Shows the selected frame's position by the corner it's anchored by.", "the spec's line")
	stub.fire_script(coordinates, 'OnLeave', true)

	-- A profile change moves both.
	st.config.profile.editmode.coordinates = true
	EM:Fire('SettingsChanged')
	check(coordinates.on == true, 'a profile change shows Coordinates on')
	reset_edit_mode()
end)

test('Grid size: the arrows step by 4 within 8 to 128, any whole size can be typed, and it is off while Grid and Snap to grid are', function()
	EM:Activate()
	EM:SetSetting('grid', true)
	local box = frame_of('gridSize')
	eq(box.edit:GetText(), '32', 'shows the size')
	stub.click(box.pair.up)
	eq(settings().grid_size, 36, '32 up: 36')
	eq(box.edit:GetText(), '36', 'and the box shows it')
	stub.click(box.pair.down); stub.click(box.pair.down)
	eq(settings().grid_size, 28, 'down twice: 28')

	box.edit:SetText('30')
	stub.fire_script(box.edit, 'OnEnterPressed')
	eq(settings().grid_size, 30, 'any whole size can be typed')
	local cx = EM:GetGridCenter()
	local found = false
	for _, region in ipairs({ EM.gridFrame:GetRegions() }) do
		local point, _, _, x = region:GetPoint(1)
		if region:IsShown() and point == 'TOPLEFT' and x == cx + 30 then found = true end
	end
	check(found, 'the grid redraws: a line at the centre + 30')
	box.edit:SetText('7'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(settings().grid_size, 8, '7: 8')
	box.edit:SetText('200'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(settings().grid_size, 128, '200: 128')
	box.edit:SetText('abc'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(settings().grid_size, 128, 'not a number: unchanged')
	eq(box.edit:GetText(), '128', 'and the box puts it back')

	check(not box.disabled, 'enabled with Grid on')
	EM:SetSetting('grid', false)
	check(box.disabled, 'Grid and Snap to grid off: disabled')
	eq(box:GetAlpha(), 0.4, 'dimmed')
	hover(box, box.edit)
	check(GameTooltip:IsOwned(box), 'its tooltip shows')
	eq(lines[1].text, 'Grid size', 'titled')
	eq(lines[#lines].text, 'Turn on Grid or Snap to grid to use it.', 'the last line says why')
	eq(lines[#lines].color, rgb(st.config.profile.colors.text.red), 'in red')
	stub.click(box.pair.up)
	eq(settings().grid_size, 128, 'the arrows do nothing')
	stub.fire_script(box.edit, 'OnLeave', true)
	EM:SetSetting('snap_grid', true)
	check(not box.disabled, 'Snap to grid alone enables it')
	hover(box, box.edit)
	eq(#lines, 2, 'and the tooltip drops the warning')
	stub.fire_script(box.edit, 'OnLeave', true)
	reset_edit_mode()
end)

test("an open /sui shows a new Grid size on its slider, from the bar or the tab", function()
	EM:Activate()
	EM:SetSetting('grid', true) -- the box is off without Grid or Snap to grid
	st.Config:Open('Fonts', 'editmode')
	local function slider_text()
		return H.cell('grid_size').widget.edit:GetText()
	end
	eq(slider_text(), '32', 'the slider shows 32')
	stub.click(frame_of('gridSize').pair.up)
	H.tick(); H.tick()
	eq(slider_text(), '36', 'after the bar steps it, the next render shows 36')
	local cell = H.cell('grid_size')
	cell.widget.edit:SetText('52')
	stub.fire_script(cell.widget.edit, 'OnEnterPressed')
	eq(settings().grid_size, 52, 'the tab sets it through EM:SetSetting')
	eq(frame_of('gridSize').edit:GetText(), '52', 'and the bar shows it')
	H.close_all()
	reset_edit_mode()
end)

test('EM:SetSetting: grid_size a whole number from 8 to 128, other keys as given; SettingsChanged carries the key', function()
	local got = {}
	EM:On('SettingsChanged', function(key) got[#got + 1] = tostring(key) end)
	EM:SetSetting('grid_size', 40.4)
	eq(settings().grid_size, 40, 'rounded')
	EM:SetSetting('grid_size', 1000)
	eq(settings().grid_size, 128, 'clamped high')
	EM:SetSetting('grid_size', -5)
	eq(settings().grid_size, 8, 'clamped low')
	EM:SetSetting('grid_size', 'x')
	eq(settings().grid_size, 8, 'not a number: unchanged')
	EM:SetGridSize(64)
	eq(settings().grid_size, 64, 'EM:SetGridSize')
	EM:StepGridSize(EM.GRID_STEP)
	eq(settings().grid_size, 68, 'EM:StepGridSize')
	EM:SetSetting('snap_frames', true)
	eq(settings().snap_frames, true, 'another key')
	eq(table.concat(got, ','), 'grid_size,grid_size,grid_size,grid_size,grid_size,snap_frames', 'the key; none for what changed nothing')
	eq(EM.MIN_GRID_SIZE .. ',' .. EM.MAX_GRID_SIZE .. ',' .. EM.GRID_STEP, '8,128,4', 'the range and the step')
	reset_edit_mode()
end)

test('a profile change tells everything that settings changed, with no key', function()
	local got
	EM:On('SettingsChanged', function(...) got = select('#', ...) .. ':' .. tostring((...)) end)
	EM:UpdateConfig()
	eq(got, '0:nil', 'SettingsChanged, no key')
end)

test('Exit turns edit mode off; with Blizzard Edit Mode open its tooltip says that one stays open', function()
	EM:Activate()
	local exit = frame_of('exit')
	hover(exit)
	eq(lines[1].text, 'Exit', 'titled')
	eq(#lines, 2, 'one line with Blizzard closed')
	eq(lines[2].text, 'Turns edit mode off. Your moves are already saved.', 'its line')
	stub.fire_script(exit, 'OnLeave', true)
	check(not EM:IsBlizzardEditModeOpen(), 'no Blizzard Edit Mode: not open')
	_G.EditModeManagerFrame = CreateFrame('Frame', nil, UIParent)
	_G.EditModeManagerFrame:Show()
	check(EM:IsBlizzardEditModeOpen(), 'shown: open')
	hover(exit)
	eq(#lines, 3, 'a third line while it is open')
	eq(lines[3].text, "Blizzard's Edit Mode stays open; close it with its own button.", 'the line')
	stub.fire_script(exit, 'OnLeave', true)
	_G.EditModeManagerFrame:Hide()
	check(not EM:IsBlizzardEditModeOpen(), 'hidden: not open')
	stub.click(exit)
	check(not EM.active, 'Exit turned edit mode off')
	_G.EditModeManagerFrame = nil
	check(not EM:IsBlizzardEditModeOpen(), 'none at all: not open')
	reset_edit_mode()
end)

test("Options opens the selected mover's page, or Global settings > Edit mode with none selected", function()
	EM:Activate()
	local options = frame_of('options')
	hover(options)
	eq(lines[2].text, "Opens edit mode's settings in /sui.", 'with none selected, the tooltip says so')
	stub.fire_script(options, 'OnLeave', true)
	stub.click(options)
	local state = OW:GetState()
	eq(state.page .. '/' .. tostring(state.tab), 'Fonts/editmode', 'none selected: Global settings, the Edit mode tab')
	H.close_all()

	local mover = add_mover('loot_test', { label = 'Loot test', configPath = { 'Loot', 'general' } })
	EM:Select(mover)
	H.close_all()
	hover(options)
	eq(lines[2].text, "Opens Loot test's page in /sui.", "the tooltip names the mover")
	stub.fire_script(options, 'OnLeave', true)
	stub.click(options)
	eq(OW:GetState().page, 'Loot', "the selected mover's page")
	H.close_all()

	-- A selected mover with no page to open: Options still opens something.
	local bare = add_mover('bare_test', { label = 'Bare' })
	EM:Select(bare)
	H.close_all()
	stub.click(options)
	eq(OW:GetState().page, 'Fonts', 'a mover with no page: the Edit mode tab')
	H.close_all()
	EM:Select(nil)
	reset_edit_mode()
end)

test('the bar fades and takes no mouse while a mover is dragged', function()
	EM:Activate()
	local bar = EM:GetBar()
	local mover = add_mover('drag_test')
	local function mouse_on()
		local n = 0
		for _, key in ipairs({ 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'options' }) do
			local c = EM:BarControl(key)
			if c.frame:IsMouseEnabled() then n = n + 1 end
			if c.frame.edit and c.frame.edit:IsMouseEnabled() then n = n + 1 end
			if c.frame.pair and (c.frame.pair.up:IsMouseEnabled() or c.frame.pair.down:IsMouseEnabled()) then n = n + 1 end
		end
		return n
	end
	local box = frame_of('gridSize')
	-- In the game an edit box and a button take the mouse by themselves; the stub's do not.
	for _, f in ipairs({ box.edit, box.pair.up, box.pair.down }) do f:EnableMouse(true) end
	local before = mouse_on()
	check(before > 0, 'controls take the mouse')
	eq(bar:GetAlpha(), 1, 'full alpha')
	local events = {}
	EM:On('DragStarted', function(m) events[#events + 1] = 'started ' .. m.key end)
	EM:On('DragStopped', function(m) events[#events + 1] = 'stopped ' .. m.key end)
	EM:StartDrag(mover)
	eq(bar:GetAlpha(), 0.25, 'faded to 0.25')
	eq(mouse_on(), 0, 'no control takes the mouse')
	check(bar:IsShown(), 'still there')
	EM:StopDrag(mover)
	eq(bar:GetAlpha(), 1, 'back')
	eq(mouse_on(), before, 'the controls take the mouse again, the same ones')
	check(frame_of('grid'):IsMouseEnabled(), 'Grid among them')
	check(box.edit:IsMouseEnabled() and box.pair.up:IsMouseEnabled() and box.pair.down:IsMouseEnabled(), "the box's own frames too")
	check(not bar:IsMouseEnabled() and not box:IsMouseEnabled(), 'the bar and the box frame never take it')
	eq(table.concat(events, ','), 'started drag_test,stopped drag_test', 'DragStarted and DragStopped, with the mover')

	-- A drag a profile change drops is stopped too.
	EM:StartDrag(mover)
	eq(bar:GetAlpha(), 0.25, 'faded again')
	EM:UpdateConfig()
	eq(bar:GetAlpha(), 1, 'a drag dropped by UpdateConfig: back')
	eq(events[#events], 'stopped drag_test', 'and it said so')
	reset_edit_mode()
end)

test('a drag whose commit errors still ends: the bar is whole again, and the error is reported', function()
	EM:Activate()
	local bar = EM:GetBar()
	local fail = false
	local mover = add_mover('bad_commit', { apply = function() if fail then error('boom') end end })
	local stopped = 0
	EM:On('DragStopped', function(m) if m == mover then stopped = stopped + 1 end end)
	take_errors()
	EM:StartDrag(mover)
	fail = true
	EM:StopDrag(mover)
	fail = false
	eq(#take_errors(), 1, 'the error reached the error handler')
	eq(stopped, 1, 'DragStopped fired anyway')
	eq(bar:GetAlpha(), 1, 'full alpha')
	check(frame_of('grid'):IsMouseEnabled(), 'the controls take the mouse')
	reset_edit_mode()
end)

test('a bar left mid-drag is whole again after edit mode closes and opens', function()
	EM:Activate()
	local bar = EM:GetBar()
	local mover = add_mover('left_over')
	EM:StartDrag(mover)
	mover.drag = nil -- as if nothing will ever end it
	eq(bar:GetAlpha(), 0.25, 'faded')
	EM:Deactivate()
	eq(bar:GetAlpha(), 1, 'Disabled puts the fade back')
	check(frame_of('grid'):IsMouseEnabled(), 'and the mouse')
	EM:StartDrag(mover)
	mover.drag = nil
	bar:Show()
	stub.fire_script(bar, 'OnHide')
	EM.active = false
	EM:Activate()
	eq(bar:GetAlpha(), 1, 'Enabled starts with a live bar')
	check(frame_of('grid'):IsMouseEnabled(), 'the controls take the mouse')
	reset_edit_mode()
end)

test("the Grid size box lets go of the keyboard when a mover is pressed or dragged, or edit mode closes", function()
	EM:Activate()
	EM:SetSetting('grid', true) -- a disabled box takes no focus
	local mover = add_mover('focus_test')
	local edit = frame_of('gridSize').edit
	for _, how in ipairs({ 'Pressed', 'DragStarted', 'Disabled' }) do
		edit:SetFocus()
		check(edit:HasFocus(), how .. ': it has focus')
		if how == 'Pressed' then stub.fire_script(mover.overlay, 'OnMouseDown', 'LeftButton')
		elseif how == 'DragStarted' then EM:StartDrag(mover); EM:StopDrag(mover)
		else EM:Deactivate() end
		check(not edit:HasFocus(), how .. ': focus let go')
	end
	reset_edit_mode()
end)

test('Pressed fires with the mover when the mouse goes down on its outline, and ColorsChanged with the group', function()
	EM:Activate()
	local mover = add_mover('press_test')
	local pressed, colors = {}, {}
	EM:On('Pressed', function(m) pressed[#pressed + 1] = m.key end)
	EM:On('ColorsChanged', function(group) colors[#colors + 1] = group end)
	stub.fire_script(mover.overlay, 'OnMouseDown', 'LeftButton')
	eq(table.concat(pressed, ','), 'press_test', 'Pressed')
	st:ColorsChanged('theme')
	st:ColorsChanged('button')
	eq(table.concat(colors, ','), 'theme,button', 'every group, theme and the rest')
	eq(EM.MoverName(mover), 'press_test', 'MoverName: the key with no label text')
	mover.label:SetText('Bar 1\noff')
	eq(EM.MoverName(mover), 'Bar 1', "MoverName: the label's first line")
	reset_edit_mode()
end)

test('a recolor reaches the bar: Button > Blue changes the accent on an icon that is on', function()
	EM:Activate()
	EM:SetSetting('grid', true)
	local frame = frame_of('grid')
	local blue = st.config.profile.colors.button.blue
	local r, g, b = blue:GetRGB()
	blue:SetRGB(0.9, 0.1, 0.2)
	st:ColorsChanged('button')
	eq(rgb(CreateColor(frame.icon:GetVertexColor())), '0.90,0.10,0.20', 'the new accent')
	blue:SetRGB(r, g, b)
	st:ColorsChanged('button')
	reset_edit_mode()
end)

test('in combat the bar hides with edit mode and its buttons do nothing', function()
	EM:Activate()
	EM:SetSetting('grid', true) -- the box is on, so only Guard stops it
	local bar = EM:GetBar()
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not bar:IsShown(), 'entering combat: hidden')
	check(not EM.active, 'edit mode off')
	EM.active = true -- the bar's buttons, should one be pressed in that last moment
	stub.in_combat = true
	settings().grid = false
	stub.click(frame_of('grid'))
	eq(settings().grid, false, 'Grid unchanged')
	stub.click(frame_of('snapFrames'))
	eq(settings().snap_frames, false, 'Snap to frames unchanged')
	stub.click(frame_of('dim'))
	eq(settings().dim, true, 'Dim world unchanged')
	stub.click(frame_of('coordinates'))
	eq(settings().coordinates, false, 'Coordinates unchanged')
	settings().grid = true
	stub.click(frame_of('gridSize').pair.up)
	eq(settings().grid_size, 32, 'Grid size arrow does nothing')
	frame_of('gridSize').edit:SetText('50')
	stub.fire_script(frame_of('gridSize').edit, 'OnEnterPressed')
	eq(settings().grid_size, 32, 'a typed size does nothing')
	settings().grid = false
	stub.click(frame_of('options'))
	check(not OW:IsShown(), 'Options opens nothing')
	stub.click(frame_of('exit'))
	check(EM.active, 'Exit does nothing')
	EM.active = false
	reset_edit_mode()
end)

test('turning edit mode on or off prints nothing; the combat refusal still does', function()
	eq(printed(function() EM:Activate() end), '', 'on: nothing')
	eq(printed(function() EM:Deactivate() end), '', 'off: nothing')
	stub.in_combat = true
	local said = printed(function() EM:Activate() end)
	check(said:find("Can't open edit mode in combat.", 1, true), 'in combat it still says: ' .. said)
	check(not EM.active, 'and does not turn on')
	reset_edit_mode()
end)

------------------------------------------------------------------ layout

test('EM.BarLayout: left groups from 10, controls 4 apart, 8 + 1 + 8 between groups, a divider before the right ones, fits at a gap of 12', function()
	local groups = {
		{ side = 'left', widths = { 80 } },
		{ side = 'left', widths = { 26, 54 } },
		{ side = 'right', widths = { 26, 26 } },
	}
	local xs, dividers, fits = EM.BarLayout(600, groups)
	eq(xs[1][1], 10, 'the first control at PAD')
	eq(xs[2][1], 107, 'the next group after 8, 1 and 8')
	eq(xs[2][2], 137, '4 after its first control')
	eq(xs[3][1], 534, 'the right group ends 10 short of the right end: 590')
	eq(xs[3][2], 564, 'its controls 4 apart')
	eq(table.concat(dividers, ','), '98,525', 'a divider between left groups, and one before the right ones')
	eq(fits, true, 'fits')
	local _, _, atEdge = EM.BarLayout(278, groups)
	eq(atEdge, true, 'a gap of exactly 12 fits (left end 191, divider 203)')
	local _, _, tight = EM.BarLayout(277, groups)
	eq(tight, false, 'a gap of 11 does not')
	for g, row in ipairs(xs) do
		for c, x in pairs(row) do eq(x, math.floor(x), ('x[%d][%d] whole'):format(g, c)) end
	end

	-- A width of 0 is skipped; a group with none is skipped whole, divider and all.
	xs, dividers = EM.BarLayout(600, {
		{ side = 'left', widths = { 80, 0, 20 } },
		{ side = 'left', widths = { 0, 0 } },
		{ side = 'left', widths = { 30 } },
		{ side = 'right', widths = { 0 } },
		{ side = 'right', widths = { 26 } },
	})
	eq(xs[1][1] .. ',' .. tostring(xs[1][2]) .. ',' .. xs[1][3], '10,nil,94', 'a 0 width takes no room and no gap')
	eq(xs[3][1], 131, 'the next group follows the empty one as if it were not there (114 + 8 + 1 + 8)')
	eq(table.concat(dividers, ','), '122,555', 'one divider before the left group after the empty one, one before the right')
	eq(xs[5][1], 564, 'the one right control ends at 590')
	-- With no right groups the bar's right end less PAD is the limit.
	local _, _, none = EM.BarLayout(110, { { side = 'left', widths = { 78 } } })
	eq(none, true, 'no right groups: the right end less PAD is the limit (88 + 12 <= 100)')
	_, _, none = EM.BarLayout(109, { { side = 'left', widths = { 78 } } })
	eq(none, false, 'one less does not fit')
end)

test('a narrow screen gives way in order: the filter, the caption, the face, then Exit and Options lose their words', function()
	EM:Activate()
	local exit, options = frame_of('exit'), frame_of('options')
	local full = EM:BarWidthAt(0)
	set_screen(full, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), 0, 'at the width stage 0 needs: stage 0')
	check(exit:GetWidth() > 26 and options:GetWidth() > 26, 'Exit and Options with their words')
	check(exit.text:IsShown() and options.text:IsShown(), 'their labels show')
	set_screen(full - 1, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	check(EM:LayoutBar() >= 1, 'one pixel less: a later stage')
	set_screen(EM:BarWidthAt(3) - 1, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), 4, 'less than stage 3 needs: stage 4')
	eq(exit:GetWidth() .. 'x' .. options:GetWidth(), '26x26', 'Exit and Options are 26 wide')
	check(not exit.text:IsShown() and not options.text:IsShown(), 'their labels are hidden')
	hover(exit)
	eq(lines[1].text, 'Exit', 'and their tooltips name them')
	stub.fire_script(exit, 'OnLeave', true)
	hover(options)
	eq(lines[1].text, 'Options', 'Options too')
	stub.fire_script(options, 'OnLeave', true)
	check(EM:BarWidthAt(4) < EM:BarWidthAt(3), 'stage 4 needs less width')
	eq(EM:LayoutBar(), 4, 'the width asked about does not change the stage')

	-- Too narrow even then: the last stage, and nothing hides the controls.
	set_screen(100, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), EM.BAR.STAGES - 1, 'nothing fits: the last stage')
	set_screen(1920, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), 0, 'a wide screen again: stage 0')
	check(exit.text:IsShown(), 'the words are back')
	reset_edit_mode()
end)

test("the bar lays out again on UI_SCALE_CHANGED, DISPLAY_SIZE_CHANGED and its own size change", function()
	EM:Activate()
	local bar = EM:GetBar()
	local options = frame_of('options')
	set_screen(1366, 768)
	stub.fire_event('UI_SCALE_CHANGED')
	eq(UIParent:GetRight() - options:GetRight(), 10, 'UI_SCALE_CHANGED: Options 10 from the new right end')
	set_screen(1600, 900)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(UIParent:GetRight() - options:GetRight(), 10, 'DISPLAY_SIZE_CHANGED: and again')
	set_screen(1280, 720)
	stub.fire_script(bar, 'OnSizeChanged', 1280, 40)
	eq(UIParent:GetRight() - options:GetRight(), 10, 'OnSizeChanged: and again')
	set_screen(1920, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	reset_edit_mode()
end)

-- Every piece of the bar on whole pixels, under each look, at each screen, with
-- the game's read-back noise (a hair either way, and none).
test("every piece of the bar sits on whole pixels, at any screen, under each look, with the game's read-back noise, and after a UI scale change", function()
	local HAIR = 2 ^ -14
	EM:Activate()
	EM:SetSetting('grid', true)
	EM:SetSetting('snap_frames', true)
	local bar = EM:GetBar()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name)
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1920, 1080 }, { 1366, 768 }, { 1024, 768 }, { 800, 600 } }) do
				set_screen(screen[1], screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED')
				local where = ('%s noise %s at %dx%d: '):format(name, noise, screen[1], screen[2])
				local off = P.off(bar)
				eq(#off, 0, where .. P.report(off))
				stub.fire_script(frame_of('exit'), 'OnMouseDown', 'LeftButton')
				off = P.off(bar)
				eq(#off, 0, where .. 'pressed: ' .. P.report(off))
				stub.fire_script(frame_of('exit'), 'OnMouseUp', 'LeftButton')
			end
			-- SaftUI's scale for a new screen (what a reload gives: it sets
			-- UIParent's scale at login only), then the event.
			set_screen(1600, 900)
			stub.fire_event('UI_SCALE_CHANGED')
			local off = P.off(bar)
			eq(#off, 0, name .. ' noise ' .. noise .. ' after a UI scale change: ' .. P.report(off))
		end
	end
	set_screen(1920, 1080)
	stub.size_noise = 0
	look('thick')
	reset_edit_mode()
end)

test("at a scale that is not SaftUI's the controls still sit whole from the bar, and Options ends 10 short of its width", function()
	EM:Activate()
	local bar = EM:GetBar()
	set_screen(1920, 1080)
	UIParent:SetScale(0.71) -- UIParent's own edges are fractional here: nothing anchored to them can be whole
	stub.fire_event('UI_SCALE_CHANGED')
	local width = math.floor(bar:GetWidth() + 0.5)
	for _, key in ipairs({ 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'options' }) do
		local _, _, _, x, y = frame_of(key):GetPoint(1)
		eq(x, math.floor(x), key .. ': x whole from the bar')
		eq(y, math.floor(y), key .. ': y whole from the bar')
	end
	local _, _, _, ox = frame_of('options'):GetPoint(1)
	eq(ox + frame_of('options'):GetWidth(), width - 10, "Options ends 10 short of the bar's rounded width")
	set_screen(1920, 1080)
	reset_edit_mode()
end)

test("hover with the game's motion argument shows each control's tooltip under it", function()
	EM:Activate()
	for _, key in ipairs({ 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'options' }) do
		local c = EM:BarControl(key)
		local target = c.frame.edit or c.frame
		hover(c.frame, target)
		check(GameTooltip:IsOwned(c.frame) and GameTooltip:IsShown(), key .. ': owned by the control and shown')
		eq(stub.state(GameTooltip).anchor, 'ANCHOR_BOTTOM', key .. ': under it')
		check(#lines >= 2, key .. ': a title and a line')
		stub.fire_script(target, 'OnLeave', true)
		check(not GameTooltip:IsShown(), key .. ': hidden on leave')
	end
	-- Exiting with the mouse on a control leaves no tooltip behind.
	hover(frame_of('grid'))
	EM:Deactivate()
	check(not GameTooltip:IsShown(), 'edit mode off: no tooltip left')
	reset_edit_mode()
end)

------------------------------------------------------------------ /sui

test("/sui's footer: Reload UI, the status line from the left, the page's control centred, Close; no edit mode buttons", function()
	eq(OW.GetFooter, nil, 'the window has no GetFooter')
	eq(OW.SetFooterInset, nil, 'and no SetFooterInset')
	EM:Activate()
	st.Config:Open('Unitframes', 'player', 'general')
	local f = H.frames()
	local region = f.footerRegion
	local function from_left(frame) return frame:GetLeft() - region:GetLeft() end
	local function from_right(frame) return region:GetRight() - frame:GetRight() end
	check(f.footerControl:IsShown(), "the page's control shows")
	check(math.abs(from_left(f.footerLabel) - from_right(f.footerWidgets[2].frame)) <= 1,
		'centred: ' .. from_left(f.footerLabel) .. ' and ' .. from_right(f.footerWidgets[2].frame))
	eq(f.status:GetLeft(), region:GetLeft(), 'the status line from the left of the region')
	for _, child in ipairs({ region:GetChildren() }) do
		check(child == f.footerControl, 'nothing in the region but the page control')
	end
	local x, shown = OW.FooterPlace(400, 60, 200)
	eq(x .. tostring(shown), '70true', 'FooterPlace: centred while it fits')
	x, shown = OW.FooterPlace(200, 60, 180)
	eq(x .. tostring(shown), '20false', 'else the right end, without its label')
	x, shown = OW.FooterPlace(301, 60, 240)
	eq(x .. tostring(shown), '0true', 'a region exactly the control wide: from its left, label and all (centred rounds down)')
	H.close_all()
	reset_edit_mode()
end)

test("the sidebar's Edit mode button is on in the accent while edit mode is, never green", function()
	st.Config:Open('Loot')
	local button = H.frames().actions[1]
	local green, blue = rgb(st.config.profile.colors.text.green), rgb(st.config.profile.colors.button.blue)
	check(not button.on, 'off while edit mode is')
	EM:Activate()
	eq(button.on, true, 'on while edit mode is')
	check(rgb(CreateColor(button.text:GetTextColor())) ~= green, 'its label is not green')
	eq(rgb(CreateColor(button:GetBackdropBorderColor())), blue, 'its edge is the accent')
	look('blizzard'); H.theme('blizzard')
	button = H.frames().actions[1]
	eq(rgb(CreateColor(button.text:GetTextColor())), blue, 'under Blizzard its label is blue')
	look('thick'); H.theme('thick')
	EM:Deactivate()
	check(not H.frames().actions[1].on, 'off again with edit mode')
	H.close_all()
	reset_edit_mode()
end)

------------------------------------------------------------------ looks

test("under Blizzard, on both clients: the panel's art, Blizzard's panel buttons, the icons in accent when on, the box's art", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local where = client .. ': '
		look('blizzard')
		EM:Activate()
		EM:SetSetting('grid', true)
		local bar = EM:GetBar()
		local reference = CreateFrame('Frame', nil, UIParent)
		st:SetBackdrop(reference, 'theme', 'theme', 'panel')
		check(T.art(bar.backdrop) ~= '', where .. 'the bar wears Blizzard art')
		eq(T.art(bar.backdrop), T.art(reference.backdrop), where .. "the panel kind's Blizzard art")
		for _, key in ipairs({ 'exit', 'options' }) do
			eq(panel_pieces(frame_of(key)), 3, where .. key .. ": Blizzard's panel button")
			eq(frame_of(key).backdropInfo, nil, where .. key .. ': no box')
		end
		local grid = frame_of('grid')
		eq(rgb(CreateColor(grid.icon:GetVertexColor())), rgb(st.config.profile.colors.button.blue), where .. 'Grid on: the icon in the accent')
		eq(grid.backdropInfo, nil, where .. 'no blue edge')
		eq(rgb(CreateColor(frame_of('snapGrid').icon:GetVertexColor())), rgb(st.config.profile.colors.text.grey), where .. 'Snap to grid off: grey')
		local box = frame_of('gridSize')
		eq(atlases_of(box.edit), 'auctionhouse-ui-inputfield-left,auctionhouse-ui-inputfield-middle,auctionhouse-ui-inputfield-right', where .. "the box's input art")
		eq(atlases_of(box.pair.up), 'minimal-scrollbar-arrow-top', where .. 'and its stepper')
		local lines_shown = 0
		for _, region in ipairs({ bar:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetWidth() == 1 and region:GetHeight() == 26 then
				lines_shown = lines_shown + 1
			end
		end
		eq(lines_shown, 4, where .. 'every divider still shown (exit, grid, show, filter, options: four between five groups)')

		look('thick')
		check(box.edit.backdropInfo ~= nil, where .. 'back to Thick: the box has its edges again')
		check(frame_of('exit').backdropInfo ~= nil, where .. 'and Exit its box')
		eq(rgb(CreateColor(frame_of('grid'):GetBackdropBorderColor())), rgb(st.config.profile.colors.button.blue), where .. 'Grid on: the accent edge')
		EM:Deactivate()
	end
	world()
end)
