-- SaftUI-Core/Config/optionswindow.lua's frame: search, the saved position, Esc
-- and the other keys, combat, the footer and edit mode's footer buttons, and
-- the window rebuilding from the new tree on a profile change.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow
local close_all, frames, cell, tick, click = H.close_all, H.frames, H.cell, H.tick, H.click
local keys = H.keys

-- What fn printed to chat (WoW's print), joined.
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

-- Whether frame is inside ancestor (its parent, or its parent's, ...).
local function inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

------------------------------------------------------------------ search

test('search waits for typing to pause, shows results by page, and a click goes there', function()
	st.Config:Open('Loot')
	local box = frames().search
	local calls, search = 0, OM.Search
	OM.Search = function(...) calls = calls + 1; return search(...) end

	box:SetFocus()
	box:SetText('frame w')
	tick(0.1)
	eq(calls, 0, 'not yet')
	box:SetText('frame wid')
	tick(0.2)
	eq(calls, 0, 'typing again starts the wait over')
	tick(0.1)
	eq(calls, 1, 'searched once the typing paused')
	eq(OW:GetState().search, 'frame wid', 'searching')
	eq(frames().title:GetText(), 'Search', 'the results page')
	local results = OW.GetDrawnRows()
	eq(#results, 2, 'Frame width for both units')
	eq(results[1].row.name, 'Frame width', 'a result')
	tick(1)
	eq(calls, 1, 'no more searches')

	click(results[2].frame)
	OM.Search = search
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/target/general', 'went to the result')
	eq(box:GetText(), '', 'the box is cleared')
	eq(state.search, '', 'not searching')
	check(cell('width') ~= nil, 'the row is drawn')
	box:ClearFocus()
	close_all()
end)

test('a search still waiting for typing to pause gives way to navigating', function()
	st.Config:Open('Loot')
	local box = frames().search
	box:SetFocus()
	-- Typing, the search not run yet: each part starts from an empty box.
	local function type_search()
		box:SetText('')
		box:SetText('frame')
		eq(OW:GetState().search, '', 'typed, not searched yet')
	end

	-- The sidebar (OW:Navigate).
	type_search()
	for _, item in ipairs(frames().nav) do
		if item.key == 'Chat' then click(item) end
	end
	tick(1)
	eq(OW:GetState().search, '', 'a page click: no search ran after it')
	eq(frames().title:GetText(), 'Chat', 'the page stays')
	eq(box:GetText(), '', 'the box is cleared')

	-- Open with a path, the window open (an edit mode click).
	type_search()
	st.Config:Open('Unitframes', 'player', 'general')
	tick(1)
	eq(OW:GetState().search, '', 'Open: no search ran after it')
	eq(OW:GetState().page .. '/' .. OW:GetState().tab, 'Unitframes/general', 'the page stays')

	-- A tab, and the picker (Select).
	type_search()
	click(frames().tabs[2])
	tick(1)
	eq(OW:GetState().search, '', 'a tab click: no search ran after it')
	eq(OW:GetState().tab, 'power', 'the tab stays')
	type_search()
	click(frames().picker.frame)
	click(W.GetListFrames().rows[2]) -- Target
	tick(1)
	eq(OW:GetState().search, '', 'a pick: no search ran after it')
	eq(OW:GetState().pick, 'target', 'the pick stays')
	box:ClearFocus()
	close_all()
end)

test('clearing the search box goes back to the page', function()
	st.Config:Open('Loot')
	frames().search:SetText('enable')
	tick(0.3)
	eq(OW:GetState().search, 'enable', 'searching')
	frames().search:SetText('')
	eq(OW:GetState().search, '', 'cleared at once')
	eq(frames().title:GetText(), 'Loot', 'the page is back')
	close_all()
end)

------------------------------------------------------------------ moving, keys, combat

test('the position is saved when a drag ends and restored on open', function()
	st.Config:Open()
	local window = frames().window
	stub.fire_script(frames().header, 'OnDragStart')
	eq(stub.state(window).moving, true, 'dragging the header moves the window')
	window:ClearAllPoints()
	window:SetPoint('CENTER', UIParent, 'CENTER', 120, -40) -- where the mouse left it
	stub.fire_script(frames().header, 'OnDragStop')
	eq(stub.state(window).moving, false, 'stopped')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'CENTER 120 -40', 'saved account-wide')

	st.Config:Close()
	st.config.global.optionsWindow = { point = 'CENTER', x = -200, y = 50 }
	st.Config:Open()
	local cx, cy = window:GetCenter()
	local ux, uy = UIParent:GetCenter()
	eq((cx - ux) .. ',' .. (cy - uy), '-200,50', 'restored')

	st.Config:Close()
	st.config.global.optionsWindow = { point = 'NOWHERE', x = 'a' }
	st.Config:Open()
	cx, cy = window:GetCenter()
	eq((cx - ux) .. ',' .. (cy - uy), '0,0', 'a bad saved value: centered')
	st.config.global.optionsWindow = nil
	close_all()
end)

test('Esc closes the window through its own catcher; other keys pass on', function()
	st.Config:Open()
	local keys = frames().keys
	check(keys:IsShown() and keys:IsKeyboardEnabled(), 'the catcher is on while open')
	stub.fire_script(keys, 'OnKeyDown', 'A')
	check(OW:IsShown(), 'A: still open')
	eq(keys:GetPropagateKeyboardInput(), true, 'A goes on to the game')

	frames().search:SetFocus()
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(OW:IsShown(), 'Esc with a box focused is the box\'s')
	eq(keys:GetPropagateKeyboardInput(), true, 'passed on')
	frames().search:ClearFocus()

	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsShown(), 'Esc closes it')
	eq(keys:GetPropagateKeyboardInput(), false, 'Esc is kept')
	check(not keys:IsKeyboardEnabled(), 'the catcher is off once closed')
	check(UISpecialFrames == nil, "Blizzard's UISpecialFrames isn't used")
	close_all()
end)

test("Esc passes on while Blizzard's color picker is open, so it closes the picker, not the window", function()
	st.Config:Open('Loot')
	local keys = frames().keys
	ColorPickerFrame:SetupColorPickerAndShow({ r = 1, g = 0, b = 0, swatchFunc = function() end, cancelFunc = function() end })
	check(ColorPickerFrame:IsShown(), 'the picker is open')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(OW:IsShown(), 'the window stays open')
	eq(keys:GetPropagateKeyboardInput(), true, 'Esc is passed on')
	stub.color_picker_cancel()
	check(not ColorPickerFrame:IsShown(), 'the picker closed')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsShown(), 'then Esc closes the window')
	close_all()
end)

test('PLAYER_REGEN_DISABLED closes the window', function()
	st.Config:Open()
	local said = printed(function() stub.fire_event('PLAYER_REGEN_DISABLED') end) -- fires just before the lockdown
	check(said:find('closed: entering combat', 1, true) ~= nil, 'says why')
	check(not OW:IsShown(), 'closed')
	eq(st.Config:GetWindow(), nil, 'GetWindow nil')
	check(not frames().keys:IsKeyboardEnabled(), 'the key catcher is off')
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not OW:IsShown(), 'nothing to close the second time')
	close_all()
end)

test('Open in combat refuses', function()
	stub.in_combat = true
	local said = printed(function() st.Config:Open('Loot') end)
	check(said:find("Can't open SaftUI options in combat.", 1, true) ~= nil, 'says why')
	check(not OW:IsShown(), 'not shown')
	eq(st.Config:GetWindow(), nil, 'no window')
	eq(OW:Open({ 'Loot' }), false, 'OW:Open refuses too')
	close_all()
end)

------------------------------------------------------------------ the footer and profiles

test('the footer region sits between Reload UI and Close', function()
	st.Config:Open()
	local f = frames()
	local region = OW:GetFooter()
	eq(region, f.footerRegion, 'the region')
	check(region:GetLeft() >= f.reloadButton:GetRight(), 'right of Reload UI')
	check(region:GetRight() <= f.closeButton:GetLeft(), 'left of Close')
	check(f.reloadButton:GetLeft() < f.closeButton:GetLeft(), 'Reload UI on the left')
	close_all()
end)

test("edit mode's footer buttons sit on the window's footer while edit mode is on and the window is open", function()
	local EM = st.EditModeFrames
	-- OnEnable (EditMode/settings.lua) makes them with st:CreateButton: Grid,
	-- Snap to grid, Snap to frames, -, the size, +. Keep them as they're made.
	local buttons, createButton = {}, st.CreateButton
	st.CreateButton = function(...)
		local button = createButton(...)
		buttons[#buttons + 1] = button
		return button
	end
	EM:Enable()
	st.CreateButton = createButton
	eq(#take_errors(), 0, 'edit mode enabled without errors')
	eq(#buttons, 6, 'six buttons')
	local grid, plus = buttons[1], buttons[6]
	local region = OW:GetFooter()

	st.Config:Open('Loot')
	check(not grid:IsVisible(), 'edit mode off: not shown')
	printed(function() EM:Activate() end)
	check(grid:IsVisible() and plus:IsVisible(), 'edit mode on, window open: shown')
	check(inside(grid, region), "on the window's footer region")
	check(grid:GetLeft() >= region:GetLeft() and plus:GetRight() <= region:GetRight(), 'inside it, left to right')
	check(frames().status:GetLeft() >= plus:GetRight(), 'the status line starts clear of them')

	st.Config:Close()
	check(not grid:IsVisible(), 'window closed: not shown')
	check(not inside(grid, region), 'and taken off it')
	st.Config:Open('Loot')
	check(grid:IsVisible() and inside(grid, region), 'opened again in edit mode: back')
	printed(function() EM:Deactivate() end)
	check(not grid:IsVisible(), 'edit mode off: not shown')
	check(not inside(grid, region), 'and taken off it')
	eq(frames().status:GetLeft(), region:GetLeft(), 'the status line has the region back')
	check(OW:IsShown(), 'the window stays open')

	-- Edit mode works with the window closed; the buttons just don't show.
	st.Config:Close()
	printed(function() EM:Activate() end)
	check(not grid:IsVisible(), 'edit mode on, window closed: not shown')
	printed(function() EM:Deactivate() end)
	close_all()
end)

test('a profile change rebuilds the open window from the new tree', function()
	st.Config:Open('Loot')
	local old = OW:GetRoot()
	st.config:SetProfile('Second')
	check(OW:GetRoot() ~= old, 'a new tree')
	tick()
	check(frames().profile:GetText():find('Second', 1, true) ~= nil, 'the sidebar names the new profile')
	eq(OW:GetState().page, 'Loot', 'still on the page')
	st.config:SetProfile('Default')
	close_all()
end)
