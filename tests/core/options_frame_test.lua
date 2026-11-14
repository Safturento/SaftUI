-- SaftUI-Core/Config/optionswindow.lua's frame: search, the saved position, Esc
-- and the other keys, combat, the footer, and
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

test('the search box sits in the sidebar, above Edit mode and the command buttons, as wide as their line', function()
	st.Config:Open('Loot')
	local f = frames()
	local edit = f.actions[1]
	check(inside(f.search, f.side), 'in the sidebar')
	check(not inside(f.search, f.main), 'not in the main column')
	eq(f.search:GetLeft() - f.actionsFrame:GetLeft(), 12, '12 in, as the buttons')
	eq(f.search:GetLeft(), edit:GetLeft(), 'its left on the buttons\'')
	eq(f.search:GetWidth(), 2 * edit:GetWidth() + 6, 'as wide as two buttons and their gap')
	eq(f.actionsFrame:GetTop() - f.search:GetTop(), 10, 'at the top of the sidebar\'s actions')
	eq(f.search:GetBottom() - edit:GetTop(), 8, '8 above the first line of buttons')
	eq(edit:GetBottom() - f.actionsFrame:GetBottom(), 10, 'the actions end 10 under the buttons')
	eq(f.navFrame:GetTop(), f.actionsFrame:GetBottom() - 1, 'the pages under them')

	-- Searching from there.
	f.search:SetText('frame wid')
	tick(0.3)
	eq(OW:GetState().search, 'frame wid', 'it searches')
	eq(#OW.GetDrawnRows(), 2, 'the results')
	f.search:SetText('')
	eq(OW:GetState().search, '', 'and clears')
	close_all()
end)

test('the first tab line holds tabs across the whole width: no room is kept for the search box', function()
	local module = st:GetModule('ManyTabs', true) or st:NewModule('ManyTabs')
	function module:GetConfigTable()
		local args = {}
		for i = 1, 8 do
			args['t' .. i] = { order = i, type = 'group', name = 'Tabname' .. i, args = {
				on = { type = 'toggle', name = 'Switch', get = function() return true end, set = function() end },
			} }
		end
		return { name = 'Many tabs', type = 'group', category = 'Info', childGroups = 'tab', args = args }
	end
	st.Config:Open('ManyTabs')
	-- Each tab 'TabnameN' is 72 wide (8 characters of 17 at half their size, and
	-- 4), 22 apart: 730, past the 562 the line held beside the search box.
	local tabs = frames().tabs
	eq(#tabs, 8, 'eight tabs')
	for i, tab in ipairs(tabs) do eq(tab:GetTop(), tabs[1]:GetTop(), 'tab ' .. i .. ' on the first line') end
	eq(tabs[8]:GetRight() - tabs[1]:GetLeft(), 730, 'across the width the search box took')
	eq(frames().tabLine:GetTop(), tabs[1]:GetBottom(), 'one line of tabs')
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
	local region = f.footerRegion
	check(region:GetLeft() >= f.reloadButton:GetRight(), 'right of Reload UI')
	check(region:GetRight() <= f.closeButton:GetLeft(), 'left of Close')
	check(f.reloadButton:GetLeft() < f.closeButton:GetLeft(), 'Reload UI on the left')
	close_all()
end)

------------------------------------------------------------------ the page's footer control

-- The footer control as drawn: its frame, its label and its widgets.
local function control()
	local f = frames()
	return f.footerControl, f.footerLabel, f.footerWidgets
end

-- Where a frame's left edge sits in the footer's region, and how far its right
-- edge stops short of the region's right.
local function from_left(frame) return frame:GetLeft() - frames().footerRegion:GetLeft() end
local function from_right(frame) return frames().footerRegion:GetRight() - frame:GetRight() end

-- The labels a select's open list shows, in order.
local function listed()
	local out = {}
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() then out[#out + 1] = row.text:GetText() end
	end
	return table.concat(out, ',')
end

test("a page's footer field: its control in the footer, centred between Reload UI and Close; other pages have none", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	local frame, label, widgets = control()
	local region = f.footerRegion
	check(frame:IsShown(), 'shown on Unitframes')
	check(inside(frame, region), "in the footer's region")
	eq(label:GetText(), 'Unit frame profile', "the footer group's name is its label")
	check(label:IsShown(), 'the label shows')
	eq(#widgets, 2, 'a widget per option')
	eq(widgets[1].type .. ',' .. widgets[2].type, 'select,execute', 'the dropdown, then Manage, in order')
	eq(widgets[1].text:GetText(), 'Main', 'the dropdown shows the value')
	eq(widgets[2].text:GetText(), 'Manage', 'the button')
	eq(widgets[1].frame:GetWidth(), W.WIDTH.select, "the kit's own dropdown")
	-- Left to right: the label, the dropdown, Manage, 8 apart.
	eq(from_left(label), from_left(frame), 'the label first')
	eq(from_left(widgets[1].frame), from_left(label) + label:GetStringWidth() + 8, 'the dropdown 8 after the label')
	eq(from_left(widgets[2].frame), from_left(widgets[1].frame) + widgets[1].frame:GetWidth() + 8, 'Manage 8 after it')
	check(math.abs(from_left(label) - from_right(widgets[2].frame)) <= 1,
		'centred: ' .. from_left(label) .. ' and ' .. from_right(widgets[2].frame))
	local _, ly = label:GetCenter()
	local _, ry = region:GetCenter()
	eq(ly, ry, 'on the region\'s middle line')
	-- The status line stops short of it.
	eq(f.status:GetLeft(), region:GetLeft(), 'the status line from the left')
	eq(f.status:GetRight(), frame:GetLeft() - 12, 'and 12 short of the control')

	-- A page without the field: the footer as before.
	OW:Navigate('Loot')
	check(not frame:IsShown(), 'none on Loot')
	eq(#f.footerWidgets, 0, 'its widgets released')
	eq(f.status:GetLeft(), region:GetLeft(), 'the status line has the whole region')
	eq(f.status:GetRight(), region:GetRight(), 'to its right end')
	check(f.status:IsShown(), 'shown')
	OW:Navigate('Unitframes')
	check(frame:IsShown(), 'back on Unitframes')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the footer's dropdown lists its values and sets through the model; the page draws again and the list follows", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local dropdown = select(3, control())[1]
	click(dropdown.frame)
	eq(listed(), 'Alt,Main', 'its values')
	local before = OW.GetRenderCount()
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() and row.text:GetText() == 'Alt' then click(row) break end
	end
	eq(ufProfile, 'Alt', 'set through the option')
	eq(OW.GetRenderCount(), before + 1, 'the page drawn again')
	eq(select(3, control())[1].text:GetText(), 'Alt', 'the dropdown shows it')
	tick(); tick()
	eq(OW.GetRenderCount(), before + 1, "its get's notifying doesn't draw it again and again")

	-- A value made elsewhere (a new profile): the next render lists it.
	ufProfiles.Fresh = 'Fresh'
	st.Config:Refresh(); tick()
	click(select(3, control())[1].frame)
	eq(listed(), 'Alt,Fresh,Main', 'the list follows')
	W.CloseList()
	ufProfiles.Fresh, ufProfile = nil, 'Main'
	st.Config:Refresh(); tick()
	eq(select(3, control())[1].text:GetText(), 'Main', 'and the value')

	-- Manage runs its func.
	click(select(3, control())[2].frame)
	eq(ufManaged, 1, 'Manage clicked')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("search results draw no page, so no footer control; leaving search brings it back", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	f.search:SetText('enable')
	tick(0.3)
	eq(OW:GetState().search, 'enable', 'searching')
	check(not f.footerControl:IsShown(), 'no control over the results')
	eq(f.status:GetRight(), f.footerRegion:GetRight(), 'the status line has the whole region')
	f.search:SetText('')
	check(f.footerControl:IsShown(), 'the page and its control are back')
	close_all()
end)

-- A validate error about as long as the longest real one (an anchor's).
local ERROR_TEXT = "Can't anchor a frame to itself"

local function status_width(f) return f.status:GetRight() - f.status:GetLeft() end

for _, look in ipairs({ 'thick', 'blizzard' }) do
	test('a validate error on a page with a footer control (' .. look .. '): the status line gets room, the control drops its label for it and comes back', function()
		H.theme(look)
		st.Config:Open('Unitframes', 'player', 'general')
		local f = frames()
		local frame, label, widgets = control()
		local region = f.footerRegion
		local centred = from_left(label)
		local last = widgets[2].frame

		-- The label drops, the widgets are at the right end, the status has the rest.
		OW:SetStatus(ERROR_TEXT)
		check(f.status:IsShown() and frame:IsShown(), 'both show')
		check(not label:IsShown(), 'the label is dropped while the error shows')
		eq(from_right(last), 0, 'the widgets at the right end, beside Close')
		eq(f.status:GetRight(), frame:GetLeft() - 12, 'the status line ends 12 before the control')
		check(status_width(f) >= f.status:GetStringWidth(), 'room for the whole error: ' .. status_width(f) .. ' for ' .. f.status:GetStringWidth())
		OW:SetStatus(nil)
		check(label:IsShown(), 'the label comes back when the status clears')
		eq(from_left(label), centred, 'the control is centred again')

		-- A region narrower than the widgets and the gap (never so in the window as
		-- it is built): the control hides for the error, the status line takes it all.
		local bare = last:GetRight() - widgets[1].frame:GetLeft()
		local left = region:GetLeft() - f.reloadButton:GetRight()
		region:ClearAllPoints()
		region:SetPoint('LEFT', f.reloadButton, 'RIGHT', left, 0)
		region:SetWidth(bare + 8)
		OW:SetStatus(nil)
		check(frame:IsShown(), 'the control shows at the right end with no error')
		OW:SetStatus(ERROR_TEXT)
		check(not frame:IsShown(), 'no room beside it for the error: the control hides')
		check(f.status:IsShown(), 'the status line shows')
		eq(f.status:GetLeft(), region:GetLeft(), 'from the region\'s left')
		eq(f.status:GetRight(), region:GetRight(), 'to the right end')
		OW:SetStatus(nil)
		check(frame:IsShown() and widgets[1].frame:IsVisible(), 'the control is back when the status clears')
		region:ClearAllPoints()
		region:SetPoint('LEFT', f.reloadButton, 'RIGHT', left, 0)
		region:SetPoint('RIGHT', f.closeButton, 'LEFT', -left, 0)
		OW:SetStatus(nil)
		eq(from_left(label), centred, 'and centred in the region again')
		H.theme('thick')
		close_all()
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('leaving a page whose control hid for an error shows the status line again; a page without the control has none of it', function()
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	local region = f.footerRegion
	local bare = f.footerWidgets[2].frame:GetRight() - f.footerWidgets[1].frame:GetLeft()
	local left = region:GetLeft() - f.reloadButton:GetRight()
	region:ClearAllPoints()
	region:SetPoint('LEFT', f.reloadButton, 'RIGHT', left, 0)
	region:SetWidth(bare + 8)
	OW:SetStatus(ERROR_TEXT)
	check(not f.footerControl:IsShown(), 'the control is hidden for the error')
	OW:Navigate('Loot') -- clears the status, and the new page has no control
	check(f.status:IsShown(), 'the status line is shown on Loot')
	OW:SetStatus(ERROR_TEXT)
	check(f.status:IsShown(), 'and shows an error')
	eq(f.status:GetRight(), region:GetRight(), 'to the right end')
	region:ClearAllPoints()
	region:SetPoint('LEFT', f.reloadButton, 'RIGHT', left, 0)
	region:SetPoint('RIGHT', f.closeButton, 'LEFT', -left, 0)
	OW:Navigate('Unitframes')
	check(f.footerControl:IsShown(), 'the control is back on Unitframes')
	close_all()
end)

test("a footer that is hidden draws nothing", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	local frame, _, widgets = control()
	check(#widgets == 2 and frame:IsShown(), 'drawn')
	local page = OW:GetRoot().Unitframes
	local footer = page.footer
	page.footer = { type = 'group', name = footer.name, args = footer.args, hidden = true }
	OW:Render()
	check(not frame:IsShown(), 'a hidden footer: no control')
	eq(#f.footerWidgets, 0, 'and no widgets')
	check(f.status:IsShown(), 'the status line has the region')
	page.footer = footer
	OW:Render()
	check(frame:IsShown() and #f.footerWidgets == 2, 'shown when it is not hidden')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the footer's dropdown and Manage show their option's tooltip; the game's motion argument is no trouble", function()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	local dropdown, manage = f.footerWidgets[1], f.footerWidgets[2]
	for _, case in ipairs({ { dropdown, 'Profile', 'The profile.' }, { manage, 'Manage', 'Manages the profiles.' } }) do
		local widget, name, desc = case[1], case[2], case[3]
		stub.fire_script(widget.frame, 'OnEnter', true) -- the game's second argument, motion
		check(GameTooltip:IsOwned(widget.frame) and GameTooltip:IsShown(), name .. ': a tooltip over it')
		local texts = stub.state(GameTooltip).texts -- the stub keeps every line added
		eq(texts[#texts - 1], name, name .. ': its name')
		eq(texts[#texts], desc, name .. ': its desc')
		stub.fire_script(widget.frame, 'OnLeave', true)
		check(not GameTooltip:IsShown(), name .. ': gone when the mouse leaves')
	end
	-- Drawn again (pooled frames): still one tip, for the right option; none once released.
	OW:Render()
	stub.fire_script(f.footerWidgets[1].frame, 'OnEnter', true)
	local texts = stub.state(GameTooltip).texts
	eq(texts[#texts - 1], 'Profile', 'drawn again: its tooltip')
	stub.fire_script(f.footerWidgets[1].frame, 'OnLeave', true)
	local released = f.footerWidgets[1].frame
	OW:Navigate('Loot')
	stub.fire_script(released, 'OnEnter', true)
	check(not GameTooltip:IsShown(), 'a released widget shows no tip')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("a search result for the footer's options opens the page as it is: the page's pick and tab stay, and a footer key that matches a unit opens nothing else", function()
	st.Config:Open('Unitframes', 'target', 'power')
	local f = frames()
	eq(OW:GetState().pick, 'target', 'on Target')
	f.search:SetText('manage')
	tick(0.3)
	local result
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == 'manage' then result = c end
	end
	check(result ~= nil, 'a result for Manage')
	click(result.frame)
	local state = OW:GetState()
	eq(state.page, 'Unitframes', 'the page opened')
	eq(state.pick, 'target', 'on the unit that was picked')
	eq(state.tab, 'power', 'and the tab that was open')
	check(f.footerControl:IsShown(), 'with its control')

	-- A footer option keyed like a unit: still only the page.
	local footer = OW:GetRoot().Unitframes.footer
	footer.args.player = { order = 9, type = 'execute', name = 'Player thing', func = function() end }
	f.search:SetText('player thing')
	tick(0.3)
	result = nil
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == 'player' then result = c end
	end
	check(result ~= nil, 'a result for it')
	click(result.frame)
	eq(OW:GetState().pick, 'target', 'the pick is not Player')
	footer.args.player = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ a pick's control beside the picker

-- The player's control (ufPickerControl, the helpers' Unitframes): Copy from
-- and Swap, two buttons; ran counts their clicks.
local function picker_control(ran)
	return {
		type = 'group', name = '',
		args = {
			copy = { order = 1, type = 'execute', name = 'Copy from', desc = 'Copies settings onto this unit.',
				func = function() ran.copy = (ran.copy or 0) + 1 end },
			swap = { order = 2, type = 'execute', name = 'Swap', desc = 'Swaps them.',
				func = function() ran.swap = (ran.swap or 0) + 1 end },
		},
	}
end

-- Picks key in the picker's list.
local function pick(key)
	click(frames().picker.frame)
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() and row.text:GetText() == key then click(row) return end
	end
	error('no pick ' .. key)
end

test("a pick's pickerControl: its buttons on the picker's line, 12 right of the dropdown and apart; a pick without one has none", function()
	local P = load_test_file('lib/pixels.lua')
	local HAIR = 2 ^ -14
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		-- The first look reads sizes back exactly, the others a hair off.
		stub.size_noise = ({ thick = 0, thin = HAIR, blizzard = -HAIR })[look]
		H.theme(look)
		local ran = {}
		ufPickerControl = picker_control(ran)
		st.Config:Open('Unitframes', 'player', 'power')
		local f = frames()
		local picker, widgets = f.picker.frame, f.pickerWidgets
		eq(#widgets, 2, look .. ': a widget per option')
		eq(widgets[1].type .. ',' .. widgets[2].type, 'execute,execute', look .. ": the kit's buttons")
		eq(widgets[1].text:GetText() .. ',' .. widgets[2].text:GetText(), 'Copy from,Swap', look .. ': in order')
		eq(widgets[1].frame:GetLeft(), picker:GetRight() + 12, look .. ': 12 right of the dropdown')
		eq(widgets[2].frame:GetLeft(), widgets[1].frame:GetRight() + 12, look .. ': the next 12 after it')
		local _, py = picker:GetCenter()
		local _, by = widgets[1].frame:GetCenter()
		eq(by, py, look .. ": on the picker's middle line")
		local off = {}
		for _, w in ipairs(widgets) do
			for _, o in ipairs(P.off(w.frame)) do off[#off + 1] = o end
		end
		eq(#off, 0, look .. ': on whole pixels: ' .. P.report(off))

		-- A click runs it, and the page draws again where it was.
		local before = OW.GetRenderCount()
		click(f.pickerWidgets[1].frame)
		eq(ran.copy, 1, look .. ': Copy from ran')
		eq(OW.GetRenderCount(), before + 1, look .. ': the page drawn again')
		eq(OW:GetState().tab, 'power', look .. ': on the tab it was')
		eq(#f.pickerWidgets, 2, look .. ': and the control with it')

		-- Target has none; back on Player, there again; a page with no picker, none.
		pick('Target')
		eq(OW:GetState().pick, 'target', look .. ': on Target')
		eq(#f.pickerWidgets, 0, look .. ': none on a pick without one')
		pick('Player')
		eq(#f.pickerWidgets, 2, look .. ': back on Player')
		OW:Navigate('Loot')
		eq(#f.pickerWidgets, 0, look .. ': none on a page with no picker')
		close_all()
	end
	stub.size_noise = 0
	H.theme('thick')
	ufPickerControl = nil
	eq(#take_errors(), 0, 'no errors')
end)

test("a pick's control shows each option's tooltip, follows disabled and hidden, and goes with the results page", function()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	local ran = {}
	ufPickerControl = picker_control(ran)
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	local copy = f.pickerWidgets[1]
	stub.fire_script(copy.frame, 'OnEnter', true) -- the game's second argument, motion
	check(GameTooltip:IsOwned(copy.frame) and GameTooltip:IsShown(), 'a tooltip over it')
	local texts = stub.state(GameTooltip).texts
	eq(texts[#texts - 1], 'Copy from', 'its name')
	eq(texts[#texts], 'Copies settings onto this unit.', 'its desc')
	stub.fire_script(copy.frame, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone when the mouse leaves')

	-- Disabled and hidden, read at each render as a page's rows.
	ufPickerControl.args.copy.disabled = true
	ufPickerControl.args.swap.hidden = true
	st.Config:Open('Unitframes', 'player', 'general')
	eq(#f.pickerWidgets, 1, 'a hidden one is left out')
	check(f.pickerWidgets[1]:IsDisabled(), 'a disabled one is dimmed')
	click(f.pickerWidgets[1].frame)
	eq(ran.copy, nil, 'and does nothing')

	-- The results page has no picker, so no control.
	f.search:SetText('enable')
	tick(0.3)
	eq(f.title:GetText(), 'Search', 'searching')
	eq(#f.pickerWidgets, 0, 'no control on the results')
	f.search:SetText('')
	tick(0.3)
	eq(#f.pickerWidgets, 1, 'back with the page')
	ufPickerControl = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("a search finds a pick's control's options, and a result opens the page at that pick", function()
	local ran = {}
	ufPickerControl = picker_control(ran)
	st.Config:Open('Unitframes', 'target', 'power')
	local f = frames()
	f.search:SetText('swap')
	tick(0.3)
	local results = OW.GetDrawnRows()
	eq(#results, 1, 'one result')
	eq(results[1].row.name, 'Swap', 'the option')
	click(results[1].frame)
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick, 'Unitframes/player', 'the page, at that pick')
	eq(#f.pickerWidgets, 2, 'with its control')
	ufPickerControl = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('OW.FooterPlace: centred while it fits, else the right end without the label', function()
	-- regionWidth, labelWidth (with its gap), widgetsWidth -> x, label shown.
	local function place(...)
		local x, shown = OW.FooterPlace(...)
		return x .. (shown and ' label' or ' bare')
	end
	eq(place(600, 140, 260), '100 label', 'centred')
	eq(place(601, 140, 260), '100 label', 'centred on a whole pixel')
	eq(place(400, 140, 260), '0 label', 'exactly as wide as the control: from the left')
	eq(place(399, 140, 260), '139 bare', 'a pixel too narrow: the label goes, the widgets at the right end')
	eq(place(300, 140, 260), '40 bare', 'a region too narrow for it all: without the label')
	eq(place(200, 140, 260), '-60 bare', 'narrower than the widgets: they still end at the right end')
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
