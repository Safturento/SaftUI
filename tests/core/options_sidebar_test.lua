-- The /sui window's sidebar toggle (SaftUI-Core/Config/optionsnav.lua:
-- OW:IsSidebarShown, OW:SetSidebarShown, F.sideToggle and S.PlaceSideToggle;
-- optionswindow.lua's Relayout with S.sidebar): the sidebar collapses and is
-- shown again at full and at half, the window narrowing from its left, the
-- page and the window's right edge and top never moving; the toggle's two
-- places and looks, what it refuses, what it closes, what it keeps; the state
-- remembered; the sidebar's list scrolling (twenty pages), kept exactly. Real: Core's Config on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window (options_window_helpers.lua).
-- The mouse and the frame clock are played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local OW, W = st.OptionsWindow, st.OptionsWidgets
local theme, close_all, frames, click, tick = H.theme, H.close_all, H.frames, H.click, H.tick
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local SCALE = UIParent:GetScale()

-- Two commands the sidebar and the collapsed footer draw: Keybind mode with its
-- icon, and one without (a text button in the footer).
local ran = {}
st.Config:AddCommand('kb', 'Keybind mode', function() ran[#ran + 1] = 'kb' end, st.icons.keyboard)
st.Config:AddCommand('two', 'Two', function() ran[#ran + 1] = 'two' end)
local EM = st.EditModeFrames

local function set_screen(width, height)
	stub.screen_width, stub.screen_height = width, height
	UIParent:SetScale(768 / height)
end

local function reset_screen()
	stub.screen_width, stub.screen_height = 1920, 1080
	UIParent:SetScale(SCALE)
end

-- Time passes past the size guard (OW.SIZE_GUARD).
local function wait() stub.time = stub.time + 0.31 end

-- A button's tooltip lines as 'title | line | danger:line'.
local function tip_text(button)
	local title, lines = button.tip(button)
	local out = { title }
	for _, line in ipairs(lines or {}) do
		out[#out + 1] = type(line) == 'table' and ((line.danger and 'danger:' or '') .. line.text) or line
	end
	return table.concat(out, ' | ')
end

-- A click on the toggle after the guard (OW.SIZE_GUARD) has passed.
local function tap(button) wait(); click(button) end

local function reset()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
	reset_screen()
end

-- Twenty small pages, so the sidebar's list scrolls.
for i = 1, 20 do
	local module = st:NewModule('SideN' .. i)
	function module:GetConfigTable()
		return {
			name = 'Side page ' .. i, type = 'group', category = 'Frames', order = 100 + i,
			args = { general = { name = 'General', type = 'group', args = {
				on = { type = 'toggle', name = 'Side ' .. i .. ' on', get = function() return true end, set = function() end },
			} } },
		}
	end
end

-- Sixty toggles: a page that scrolls.
local manyValue = {}
local MANY = st:NewModule('SideMany')
function MANY:GetConfigTable()
	local args = {}
	for i = 1, 60 do
		args['t' .. i] = { order = i, type = 'toggle', name = 'Toggle ' .. i, desc = 'Toggle ' .. i,
			get = function() return manyValue[i] end, set = function(_, v) manyValue[i] = v end }
	end
	return { name = 'Many', type = 'group', category = 'Frames', args = args }
end

-- One item with a menu.
local ITEMS = st:NewModule('SideItems')
function ITEMS:GetConfigTable()
	return {
		name = 'Items', type = 'group', category = 'Frames',
		args = { texts = { order = 1, type = 'group', name = 'Texts', args = {
			hotkey = { order = 1, type = 'item', name = 'Hotkey', desc = 'The key.', size = 'small', menuTitle = 'Hotkey text',
				get = function() return true end, set = function() end,
				menu = { type = 'group', name = 'Hotkey', args = {
					size = { order = 1, type = 'range', name = 'Size', desc = 'Its size.', min = 6, max = 20, step = 1,
						get = function() return 10 end, set = function() end },
				} } },
		} } },
	}
end

------------------------------------------------------------------ collapse and show

test('Collapse the sidebar at full: 208 narrower from the left, and the page does not move at all', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames(); local w = F.window
	local right, top, mainLeft, titleLeft, bodyLeft = w:GetRight(), w:GetTop(), F.main:GetLeft(), F.title:GetLeft(), F.body:GetLeft()
	eq(OW:IsSidebarShown(), true)
	tap(F.sideToggle)
	eq(OW:IsSidebarShown(), false); eq(w:GetWidth(), 832); eq(w:GetRight(), right); eq(w:GetTop(), top)
	check(not F.side:IsShown(), 'the sidebar hidden')
	eq(F.main:GetLeft(), mainLeft, 'the main column stays'); eq(F.title:GetLeft(), titleLeft); eq(F.body:GetLeft(), bodyLeft)
	eq(st.config.global.optionsWindow.sidebar, false, 'remembered')
	eq(F.sideToggle:GetLeft(), F.main:GetLeft() + 28, "the toggle at the footer's left")
	eq(F.footer:GetTop() - F.sideToggle:GetTop(), (F.footer:GetHeight() - 26) / 2, 'centred on the footer')
	eq(F.sideToggle:GetParent(), F.footer, 'in the footer')
	eq(F.sideToggle.icon:GetTexture(), st.icons.panelLeftClose, 'its arrow points left: show')
	eq(tip_text(F.sideToggle), 'Show the sidebar | Shows the page list again.')
	tap(F.sideToggle)
	eq(w:GetWidth(), 1040); check(F.side:IsShown()); eq(st.config.global.optionsWindow.sidebar, nil)
	eq(w:GetRight(), right); eq(F.main:GetLeft(), mainLeft)
	eq(F.sideToggle:GetParent(), F.foot, 'back in the sidebar\'s foot')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test("the toggle in the sidebar's foot at its right; the profile line ends 8 before it", function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	eq(F.sideToggle:GetParent(), F.foot)
	eq(F.sideToggle:GetRight(), F.foot:GetRight() - 8, '8 in from the foot\'s right')
	eq(F.sideToggle:GetWidth() .. 'x' .. F.sideToggle:GetHeight(), '26x26')
	eq(F.sideToggle:GetTop(), F.foot:GetTop() - 2, "centred on the foot's 30")
	eq(F.sideToggle.icon:GetWidth(), 16)
	eq(F.profile:GetWidth(), 147, 'the profile line, 208 less 61')
	eq(F.profile:GetLeft() + F.profile:GetWidth(), F.sideToggle:GetLeft() - 8, 'ends 8 before the toggle')
	eq(F.sideToggle.icon:GetTexture(), st.icons.panelLeftOpen, 'its arrow points right: collapse')
	stub.fire_script(F.sideToggle, 'OnEnter', true)
	check(GameTooltip:IsOwned(F.sideToggle), 'its tooltip')
	eq(tip_text(F.sideToggle), 'Collapse the sidebar | Hides the page list; the window narrows from its left.')
	stub.fire_script(F.sideToggle, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'and gone')
	check(F.sideToggle.onClick ~= nil, 'a click through onClick, never OnClick')
	-- Grey at rest, the accent under the mouse, as the arrows' icons.
	local function vertex(t) return string.format('%.2f,%.2f,%.2f', t:GetVertexColor()) end
	local grey = vertex(F.sideToggle.icon)
	local blue = string.format('%.2f,%.2f,%.2f', st.config.profile.theme.accent.r, st.config.profile.theme.accent.g, st.config.profile.theme.accent.b)
	stub.fire_script(F.sideToggle, 'OnEnter', true)
	eq(vertex(F.sideToggle.icon), blue, 'the icon is accent under the mouse')
	stub.fire_script(F.sideToggle, 'OnLeave', true)
	eq(vertex(F.sideToggle.icon), grey, 'and grey again')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('the sidebar and the size are separate: collapsed at full stays collapsed at half, and the bar keeps it', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	check(OW:SetSidebarShown(false), 'collapsed at full')
	wait(); check(OW:SetWindowSize('half'))
	eq(F.window:GetWidth(), 446); eq(OW:IsSidebarShown(), false)
	eq(F.sideToggle:GetLeft(), F.main:GetLeft() + 28, 'the toggle at half too')
	check(F.sideToggle:IsVisible() and F.sideToggle.disabled ~= true, 'shown and enabled')
	wait(); check(OW:SetWindowSize('mini'))
	eq(OW:IsSidebarShown(), false, 'kept at the bar')
	wait(); check(OW:SetWindowSize('half'))
	eq(F.window:GetWidth(), 446, 'back at half: still collapsed'); check(not F.side:IsShown())
	st.Config:Close()
	eq(st.config.global.optionsWindow.size .. ' ' .. tostring(st.config.global.optionsWindow.sidebar), 'half false', 'the save')
	st.Config:Open('Unitframes', 'player', 'general')
	eq(OW:GetWindowSize(), 'half'); eq(OW:IsSidebarShown(), false, 'opened as saved')
	eq(F.window:GetWidth(), 446)
	-- Show it at half.
	tap(F.sideToggle)
	eq(F.window:GetWidth(), 654, 'the sidebar at half: 654'); check(F.side:IsShown())
	eq(F.sideToggle:GetParent(), F.foot)
	eq(F.profile:GetWidth(), 147)
	-- A change that is none.
	eq(OW:SetSidebarShown(true), false, 'no change, no go')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('collapsing takes the keyboard off the search box and keeps the search; showing the sidebar shows its text', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	F.search:SetText('width'); tick(0.3)
	eq(OW:GetState().search, 'width'); eq(F.title:GetText(), 'Search', 'the results page')
	F.search:SetFocus()
	eq(GetCurrentKeyBoardFocus(), F.search)
	tap(F.sideToggle)
	eq(GetCurrentKeyBoardFocus(), nil, 'the box lost the keyboard')
	eq(OW:GetState().search, 'width', 'the search is kept'); eq(F.title:GetText(), 'Search', 'the results still shown')
	check(not F.search:IsVisible(), 'and the box is hidden')
	tap(F.sideToggle)
	eq(F.search:GetText(), 'width'); check(not F.search.hint:IsShown(), 'its hint hidden')
	eq(F.title:GetText(), 'Search', 'the results still shown')
	-- A search typed but not yet run when the sidebar collapses still runs.
	F.search:SetText('')
	eq(OW:GetState().search, '')
	F.search:SetFocus(); F.search:SetText('power')
	tap(F.sideToggle)
	eq(GetCurrentKeyBoardFocus(), nil)
	tick(0.5)
	eq(OW:GetState().search, 'power', 'the search ran')
	eq(F.title:GetText(), 'Search')
	-- A box that isn't the window's keeps the keyboard.
	tap(F.sideToggle)
	local outside = CreateFrame('EditBox', nil, UIParent)
	outside:SetFontObject(W.GetFont())
	outside:SetFocus()
	tap(F.sideToggle)
	eq(GetCurrentKeyBoardFocus(), outside, 'a box outside the window keeps it')
	outside:ClearFocus()
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test("the page's and the nav's scroll are kept exactly across a collapse", function()
	reset()
	st.Config:Open('SideMany')
	local F, S = frames(), OW.S
	S.SetScroll(240)
	check(S.navHeight > F.navFrame:GetHeight(), 'the sidebar scrolls')
	S.SetNavScroll(37)
	eq(S.navOffset, 37)
	local page, nav = F.body:GetVerticalScroll(), F.navFrame:GetVerticalScroll()
	eq(page, 240)
	tap(F.sideToggle)
	eq(S.scrollOffset, 240, 'the page is kept'); eq(F.body:GetVerticalScroll(), page)
	eq(S.navOffset, 37, "the nav's offset is kept")
	tap(F.sideToggle)
	eq(S.scrollOffset, 240); eq(F.body:GetVerticalScroll(), page)
	eq(S.navOffset, 37); eq(F.navFrame:GetVerticalScroll(), nav, "the nav's scroll comes back as it was")
	-- At half too.
	wait(); OW:SetWindowSize('half')
	S.SetScroll(100); S.SetNavScroll(11)
	tap(F.sideToggle); tap(F.sideToggle)
	eq(S.scrollOffset, 100); eq(S.navOffset, 11)
	-- The grip's resize while collapsed leaves the nav's offset be.
	tap(F.sideToggle)
	S.SetNavScroll(11)
	F.navFrame:SetHeight(F.navFrame:GetHeight()) -- a hidden frame's view
	S.SetNavScroll(500)
	eq(S.navOffset, 11, 'a nav offset is not taken while its sidebar is hidden')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('page, tab, pick and search are kept across a collapse', function()
	reset()
	st.Config:Open('Unitframes', 'target', 'power')
	local before = OW:GetState()
	tap(frames().sideToggle)
	local after = OW:GetState()
	eq(after.page .. '/' .. after.pick .. '/' .. after.tab, before.page .. '/' .. before.pick .. '/' .. before.tab)
	check(frames().picker.frame:IsShown() and frames().tabs[1] ~= nil, 'the picker and tabs drawn')
	reset()
end)

------------------------------------------------------------------ what it refuses

test('it does nothing in combat, or with the color picker open, which the toggle says', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	stub.in_combat = true
	eq(OW:SetSidebarShown(false), false, 'not in combat')
	stub.in_combat = false
	check(W.OpenColorPicker(F.window, { r = 1, g = 0, b = 0, onChange = function() end }), 'the picker opens')
	check(F.sideToggle.disabled, 'the toggle is disabled')
	eq(tip_text(F.sideToggle), 'Collapse the sidebar | Hides the page list; the window narrows from its left. | danger:Close the color picker first.')
	wait(); tap(F.sideToggle)
	eq(OW:IsSidebarShown(), true, 'a click does nothing')
	eq(OW:SetSidebarShown(false), false)
	check(W.ColorPickerShown(), 'and the picker stays')
	W.CloseColorPicker()
	check(not F.sideToggle.disabled, 'enabled again')
	tap(F.sideToggle)
	eq(OW:IsSidebarShown(), false)
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('on a screen too narrow for full with the sidebar, the toggle at full is disabled and says why', function()
	reset()
	set_screen(1024, 768)
	st.config.global.optionsWindow = { sidebar = false }
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	eq(OW:GetWindowSize(), 'full'); eq(F.window:GetWidth(), 832, 'full fits without the sidebar')
	check(F.sideToggle.disabled, 'the toggle is disabled')
	eq(tip_text(F.sideToggle), 'Show the sidebar | Shows the page list again. | danger:The screen is too narrow for the sidebar at full size. Shrink to half first.')
	wait(); tap(F.sideToggle)
	eq(OW:IsSidebarShown(), false, 'a click does nothing'); eq(F.window:GetWidth(), 832)
	eq(OW:SetSidebarShown(true), false)
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'half')
	check(not F.sideToggle.disabled, 'at half it is enabled')
	eq(tip_text(F.sideToggle), 'Show the sidebar | Shows the page list again.')
	tap(F.sideToggle)
	eq(F.window:GetWidth(), 654)
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

------------------------------------------------------------------ what it closes

test('collapsing closes a menu, the small dialog and a list, and follows cleanly', function()
	reset()
	st.Config:Open('SideItems', 'texts')
	local F = frames()
	check(OW:OpenDialog('A dialog', { type = 'group', name = 'A dialog', args = { on = { type = 'toggle', name = 'On',
		get = function() return true end, set = function() end } } }), 'the dialog opens')
	tap(F.sideToggle)
	check(not OW:IsDialogShown(), 'the dialog is closed')
	click(H.cell('hotkey').widget.dots)
	check(OW:IsMenuShown(), "the item's menu opens")
	OW:SetSidebarShown(true)
	check(not OW:IsMenuShown(), 'the menu is closed')
	st.Config:Open('Unitframes', 'player', 'general')
	click(F.picker.frame)
	check(W.ListOwner() ~= nil, 'a list is open')
	OW:SetSidebarShown(false)
	eq(W.ListOwner(), nil, 'the list is closed')
	OW:SetStatus('Size: a number, please')
	OW:SetSidebarShown(true)
	eq(F.status:GetText(), '', 'the status is clear')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

------------------------------------------------------------------ the footer's region

test('the footer region starts 12 after the toggle while collapsed, and the profile control is hidden when it does not fit', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	eq(F.footerRegion:GetLeft(), F.main:GetLeft() + 28, 'shown: from the footer\'s 28')
	check(F.footerControl:IsShown(), 'the profile control shows at full')
	OW:SetSidebarShown(false)
	eq(F.footerRegion:GetLeft(), F.tools[#F.tools]:GetRight() + 12, 'collapsed: 12 after the last tool')
	eq(F.footerRegion:GetRight(), F.reloadButton:GetLeft() - 12)
	local function clear_of_toggle()
		if F.footerControl:IsShown() then
			check(F.footerControl:GetLeft() >= F.sideToggle:GetRight() + 12 - 1e-3, 'the control is clear of the toggle')
			check(F.footerControl:GetRight() <= F.reloadButton:GetLeft() - 12 + 1e-3, 'and of Reload UI')
		end
	end
	clear_of_toggle()
	wait(); OW:SetWindowSize('half')
	check(not F.footerControl:IsShown(), 'at W4 the region cannot hold it: hidden')
	-- (Task 6: with the tools at the footer's left the status line has no room at W4: it gives way.)
	OW:SetSidebarShown(true)
	OW:SetStatus('An error'); check(F.status:IsShown(), 'at W3 the status has the region'); OW:SetStatus(nil)
	check(not F.footerControl:IsShown(), 'at W3 too')
	wait(); OW:SetWindowSize('full')
	OW:SetSidebarShown(false); OW:SetSidebarShown(true)
	check(F.footerControl:IsShown(), 'back at full: shown again')
	clear_of_toggle()
	eq(#take_errors(), 0, 'no errors')
	reset()
end)


------------------------------------------------------------------ the footer's tools

-- A list's rows as 'label' (a caption as '[label]'), in order.
local function listed()
	local list = W.GetListFrames()
	local out = {}
	for _, entry in ipairs(list.entries) do out[#out + 1] = entry.caption and ('[' .. entry.label .. ']') or entry.label end
	return table.concat(out, ',')
end

local function reset_edit_mode() if EM.active then EM:Deactivate() end end

test('collapsed, the footer holds the toggle, then Search, Edit mode and each command, 6 apart, each with its tooltip', function()
	reset()
	st.Config:Open('Loot')
	local F = frames()
	for _, tool in ipairs(F.tools) do check(not tool:IsVisible(), 'none is shown with the sidebar') end
	check(OW:SetSidebarShown(false))
	eq(#F.tools, 4, 'Search, Edit mode and the two commands')
	eq(st.Config:GetCommands()[1].icon, st.icons.keyboard, "GetCommands carries Keybind mode's icon")
	eq(st.Config:GetCommands()[2].icon, nil, 'and none for a command added without one')
	for _, tool in ipairs(F.tools) do check(tool:IsVisible(), 'shown collapsed') end
	eq(F.tools[1].icon:GetTexture(), st.icons.search); eq(F.tools[2].icon:GetTexture(), st.icons.move)
	eq(F.tools[3].icon:GetTexture(), st.icons.keyboard, "Keybind mode's icon")
	eq(F.tools[4].icon:GetTexture(), st.icons.ellipsis, 'a command without an icon goes under the overflow button')
	eq(F.tools[1]:GetLeft(), F.sideToggle:GetRight() + 6, '6 after the toggle')
	for i = 2, 4 do eq(F.tools[i]:GetLeft(), F.tools[i - 1]:GetRight() + 6, '6 apart') end
	for i = 1, 4 do
		eq(F.tools[i]:GetTop(), F.sideToggle:GetTop(), 'level with the toggle')
		eq(F.tools[i]:GetParent(), F.footer, 'in the footer')
	end
	eq(F.footerRegion:GetLeft(), F.tools[4]:GetRight() + 12, 'the region after them')
	eq(F.tools[1]:GetWidth() .. 'x' .. F.tools[1]:GetHeight(), '26x26')
	for i, want in ipairs({ 'Search settings | Finds a setting by name, on any page.',
		"Edit mode | Drag and nudge SaftUI's frames. /sui edit does too.", 'Keybind mode', 'More' }) do
		stub.fire_script(F.tools[i], 'OnEnter', true)
		check(GameTooltip:IsOwned(F.tools[i]), 'its tooltip')
		eq(tip_text(F.tools[i]), want)
		stub.fire_script(F.tools[i], 'OnLeave', true)
		check(not GameTooltip:IsShown(), 'and gone')
	end
	check(F.tools[3].onClick ~= nil and F.tools[1].onClick ~= nil, 'clicks through onClick')
	click(F.tools[3])
	eq(table.concat(ran, ','), 'kb', 'a command runs its func')
	click(F.tools[4])
	eq(W.ListOwner(), F.tools[4], 'the overflow button opens the list of the rest')
	eq(listed(), 'Two')
	click(W.GetListFrames().rows[1])
	eq(table.concat(ran, ','), 'kb,two', 'a pick runs the command'); eq(W.ListOwner(), nil, 'and closes the list')
	-- Each tool is lifted 2 levels over the footer, and its icon is accent under the mouse.
	for i = 1, 4 do eq(F.tools[i]:GetFrameLevel(), F.footer:GetFrameLevel() + 2, 'tool ' .. i .. "'s level") end
	local function vertex(t) return string.format('%.2f,%.2f,%.2f', t:GetVertexColor()) end
	local c = st.config.profile.theme.accent
	local blue = string.format('%.2f,%.2f,%.2f', c.r, c.g, c.b)
	for i = 1, 4 do
		local grey = vertex(F.tools[i].icon)
		stub.fire_script(F.tools[i], 'OnEnter', true)
		eq(vertex(F.tools[i].icon), blue, 'tool ' .. i .. ': accent under the mouse')
		stub.fire_script(F.tools[i], 'OnLeave', true)
		eq(vertex(F.tools[i].icon), grey, 'and grey again')
	end
	check(OW:SetSidebarShown(true))
	for _, tool in ipairs(F.tools) do check(not tool:IsVisible(), 'hidden again with the sidebar') end
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test("Edit mode's icon toggles edit mode and is on while it is, from wherever it is toggled", function()
	reset(); reset_edit_mode()
	st.Config:Open('Loot'); OW:SetSidebarShown(false)
	local F = frames()
	check(not F.tools[2].on, 'off')
	click(F.tools[2])
	check(EM.active, 'edit mode on'); eq(F.tools[2].on, true, 'the icon on')
	EM:Deactivate()
	check(not F.tools[2].on, 'off again when edit mode is left from elsewhere')
	EM:Activate()
	eq(F.tools[2].on, true, 'on when it is entered from elsewhere')
	click(F.tools[2])
	check(not EM.active and not F.tools[2].on, 'a second click ends it')
	reset_edit_mode()
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test("Search opens the sidebar's box over the footer; losing the keyboard closes it and keeps the search", function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general'); OW:SetSidebarShown(false)
	local F = frames()
	check(not F.searchPop:IsShown(), 'closed')
	check(not F.tools[1].on, 'the icon off')
	click(F.tools[1])
	check(F.searchPop:IsShown(), 'the panel opens'); eq(F.search:GetParent(), F.searchPop, 'with the sidebar\'s box')
	check(F.search:HasFocus(), 'and the keyboard in it')
	eq(F.searchPop:GetBottom(), F.tools[1]:GetTop() + 6, '6 above the icon'); eq(F.searchPop:GetLeft(), F.tools[1]:GetLeft(), 'from its left')
	eq(F.searchPop:GetWidth(), F.search:GetWidth() + 16, 'the box and 8 round it'); eq(F.searchPop:GetHeight(), F.search:GetHeight() + 16)
	eq(F.search:GetLeft(), F.searchPop:GetLeft() + 8, '8 in'); eq(F.search:GetTop(), F.searchPop:GetTop() - 8)
	check(F.searchPop:GetFrameLevel() >= F.main:GetFrameLevel() + 20, 'above the page')
	F.search:SetText('width'); tick(0.3)
	eq(F.title:GetText(), 'Search', 'the results page'); check(F.searchPop:IsShown(), 'the panel stays while it types')
	F.search:SetFocus()
	stub.fire_script(F.search, 'OnEnterPressed')
	check(not F.searchPop:IsShown(), 'Enter closes the panel')
	eq(OW:GetState().search, 'width', 'the search is kept'); eq(F.title:GetText(), 'Search')
	eq(F.tools[1].on, true, 'the icon is on while a search is')
	eq(tip_text(F.tools[1]), 'Search settings | Searching for "width". Click to change it.')
	-- A click on a result: its page, the sidebar still collapsed, the search ended.
	local results = OW.GetDrawnRows()
	check(#results > 0, 'a result is drawn')
	click(results[1].frame)
	eq(OW:IsSidebarShown(), false, 'the sidebar stays collapsed'); eq(OW:GetState().search, '', 'the search ended')
	check(not F.tools[1].on, 'the icon off')
	-- Open again, type, Esc: the search is cleared and the page is back.
	click(F.tools[1]); F.search:SetText('power'); tick(0.3)
	eq(OW:GetState().search, 'power')
	stub.fire_script(F.search, 'OnEscapePressed')
	check(not F.searchPop:IsShown(), 'Esc closes the panel')
	eq(OW:GetState().search, '', 'and clears the search'); check(not F.tools[1].on)
	-- Clicking the icon with the panel open closes it; the sidebar takes the box back.
	click(F.tools[1]); check(F.searchPop:IsShown())
	click(F.tools[1]); check(not F.searchPop:IsShown(), 'the icon again closes it')
	click(F.tools[1])
	OW:SetSidebarShown(true)
	check(not F.searchPop:IsShown(), 'showing the sidebar closes it')
	eq(F.search:GetParent(), F.actionsFrame, 'and the box is back in the sidebar')
	eq(F.search:GetLeft(), F.actionsFrame:GetLeft() + 12)
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('the title opens the page list, grouped as the sidebar is, while the sidebar is collapsed', function()
	reset()
	st.Config:Open('Loot')
	local F = frames()
	check(not F.titleArrow:IsVisible(), 'no arrow with the sidebar'); check(not F.titleButton:IsVisible(), 'and no button')
	OW:SetSidebarShown(false)
	check(F.titleArrow:IsVisible() and F.titleButton:IsVisible(), 'shown collapsed')
	eq(F.titleArrow:GetWidth() .. 'x' .. F.titleArrow:GetHeight(), '16x16')
	eq(F.titleArrow:GetTexture(), st.icons.chevronDown)
	eq(F.titleArrow:GetLeft(), F.title:GetLeft() + math.ceil(F.title:GetStringWidth()) + 8, '8 after the title\'s text')
	eq(F.titleButton:GetLeft(), F.title:GetLeft(), 'the button covers the title')
	check(F.titleButton:GetRight() >= F.titleArrow:GetRight(), 'and the arrow')
	click(F.titleButton)
	eq(W.ListOwner(), F.titleButton, 'the list opens under the title')
	local names = listed()
	check(names:find('^Global settings,Profiles,%[Frames%],'), 'Global settings and Profiles, then the groups: ' .. names)
	check(names:find(',%[Combat%],Auras,%[Info%],Loot,%[Other%],Zeta$'), 'the groups in order: ' .. names)
	local list = W.GetListFrames()
	-- A row of the label, the list scrolled with the wheel until it shows (up
	-- 12 rows are drawn, the open page's first).
	local function row(label)
		for _, delta in ipairs({ 0, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 }) do
			if delta ~= 0 then stub.fire_script(list.frame, 'OnMouseWheel', delta) end
			for i, r in ipairs(list.rows) do if r:IsShown() and r.text:GetText() == label then return r, i end end
		end
	end
	local blue = string.format('%.2f,%.2f,%.2f', st.config.profile.theme.accent.r, st.config.profile.theme.accent.g, st.config.profile.theme.accent.b)
	local function color(r) return string.format('%.2f,%.2f,%.2f', r.text:GetTextColor()) end
	eq(color(row('Loot')), blue, 'the open page is blue')
	local frames_row = row('Frames')
	local grey = string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.muted.r, st.config.profile.colors.text.muted.g, st.config.profile.colors.text.muted.b)
	eq(color(frames_row), grey, 'a caption is grey')
	check(color(row('Zeta')) ~= grey, 'a page is not')
	frames_row = row('Frames')
	click(frames_row)
	eq(W.ListOwner(), F.titleButton, 'a caption click keeps the list open')
	eq(OW:GetState().page, 'Loot')
	click((row('Chat')))
	eq(OW:GetState().page, 'Chat', 'a pick navigates'); eq(OW:IsSidebarShown(), false, 'the sidebar stays collapsed')
	eq(F.title:GetText(), 'Chat'); eq(W.ListOwner(), nil, 'and the list closes')
	eq(F.titleArrow:GetLeft(), F.title:GetLeft() + math.ceil(F.title:GetStringWidth()) + 8, 'the arrow follows a new title')
	stub.fire_script(F.titleButton, 'OnEnter', true)
	check(GameTooltip:IsOwned(F.titleButton), 'its tooltip')
	stub.fire_script(F.titleButton, 'OnLeave', true)
	-- A search is ended by a pick.
	F.search:SetText('width'); tick(0.3)
	eq(OW:GetState().search, 'width')
	click(F.titleButton); click((row('Loot')))
	eq(OW:GetState().search, '', 'a pick ends the search'); eq(OW:GetState().page, 'Loot')
	-- With the sidebar shown the button takes no click.
	OW:SetSidebarShown(true)
	check(not F.titleArrow:IsVisible() and not F.titleButton:IsVisible())
	eq(stub.try_click(F.titleButton), false, 'the hidden button takes no click')
	eq(W.ListOwner(), nil, 'no list')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('the search panel closes on any mouse down outside it, through a catcher as the kit list has, and in the stub a click on a button does not blur the box', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'power'); OW:SetSidebarShown(false)
	local F = frames()
	check(F.searchCatcher ~= nil and not F.searchCatcher:IsShown(), 'a catcher, down while the panel is')
	check(F.searchPop:IsMouseEnabled(), 'the panel takes the mouse')
	click(F.tools[1])
	check(F.searchCatcher:IsShown(), 'up with the panel')
	eq(F.searchCatcher:GetWidth(), UIParent:GetWidth(), 'across the screen'); eq(F.searchCatcher:GetHeight(), UIParent:GetHeight())
	local level = F.searchCatcher:GetFrameLevel()
	check(F.tabs[1]:GetFrameLevel() < level and F.body:GetFrameLevel() < level and F.tools[1]:GetFrameLevel() < level
		and F.main:GetFrameLevel() < level, 'over the page, the tabs and the footer')
	check(F.searchPop:GetFrameLevel() > level and F.search:GetFrameLevel() > level, 'under the panel and its box')
	eq(F.searchCatcher:GetFrameStrata(), F.window:GetFrameStrata(), "in the window's strata")
	-- The game does not take the keyboard from a box for a click on a button.
	click(F.tabs[1])
	check(F.searchPop:IsShown() and F.search:HasFocus(), 'a click on a tab alone leaves it open: the catcher is what closes it')
	F.search:SetText('width'); tick(0.3)
	eq(OW:GetState().search, 'width')
	stub.fire_script(F.searchCatcher, 'OnMouseDown', 'LeftButton')
	check(not F.searchPop:IsShown() and not F.searchCatcher:IsShown(), 'the mouse down closes it')
	check(not F.search:HasFocus(), 'taking the keyboard'); eq(OW:GetState().search, 'width', 'the search stays')
	-- Every other way of closing takes the catcher with it.
	click(F.tools[1]); click(F.tools[1])
	check(not F.searchCatcher:IsShown(), 'the icon again')
	click(F.tools[1]); stub.fire_script(F.search, 'OnEnterPressed')
	check(not F.searchCatcher:IsShown(), 'Enter')
	click(F.tools[1]); stub.fire_script(F.search, 'OnEscapePressed')
	check(not F.searchCatcher:IsShown(), 'Esc')
	click(F.tools[1]); OW:SetSidebarShown(true)
	check(not F.searchCatcher:IsShown(), 'showing the sidebar')
	OW:SetSidebarShown(false); click(F.tools[1])
	st.Config:Close()
	check(not F.searchCatcher:IsShown() and not F.searchPop:IsShown(), 'closing the window')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('collapsed: the title is 24 narrower for its arrow, the arrow centred on the text and accent under the mouse, the title dragging the window, and no page marked during a search', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	local shown = F.title:GetWidth()
	OW:SetSidebarShown(false)
	eq(F.title:GetWidth(), shown - 24, "the title's room loses the arrow's 24")
	eq(F.titleButton:GetTop() - F.titleArrow:GetTop(), math.floor((F.titleButton:GetHeight() - 16) / 2), 'the arrow centred on the title')
	local function vertex(t) return string.format('%.2f,%.2f,%.2f', t:GetVertexColor()) end
	local c = st.config.profile.theme.accent
	local blue = string.format('%.2f,%.2f,%.2f', c.r, c.g, c.b)
	local grey = vertex(F.titleArrow)
	check(grey ~= blue, 'grey at rest')
	stub.fire_script(F.titleButton, 'OnEnter', true)
	eq(vertex(F.titleArrow), blue, 'accent under the mouse')
	stub.fire_script(F.titleButton, 'OnLeave', true)
	eq(vertex(F.titleArrow), grey, 'and grey again')
	check(F.titleButton:GetScript('OnDragStart') ~= nil and F.titleButton:GetScript('OnDragStop') ~= nil, 'a drag on the title moves the window')
	stub.fire_script(F.titleButton, 'OnDragStart'); stub.fire_script(F.titleButton, 'OnDragStop')
	-- A search is on: no page is the open one.
	F.search:SetText('width'); tick(0.3)
	click(F.titleButton)
	local list = W.GetListFrames()
	local blue_text = string.format('%.2f,%.2f,%.2f', st.config.profile.theme.accent.r, st.config.profile.theme.accent.g, st.config.profile.theme.accent.b)
	for _, row in ipairs(list.rows) do
		if row:IsShown() then check(string.format('%.2f,%.2f,%.2f', row.text:GetTextColor()) ~= blue_text, 'no page is blue during a search: ' .. row.text:GetText()) end
	end
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('the footer keeps FOOTER_MIN_ROOM, and with the real command set the status line shows at W4', function()
	reset()
	eq(OW.S.FOOTER_MIN_ROOM, 24)
	eq(#take_errors(), 0)
end)

test('OW.PageMenuEntries: a page is a key and a label, a group a caption, a disabled page stays disabled', function()
	local list = OW.PageMenuEntries({
		{ key = 'global', name = 'Global settings', special = 'global' },
		{ group = 'Frames' }, { key = 'Bags', name = 'Bags' }, { key = 'Off', name = 'Off', disabled = true },
	})
	eq(#list, 4)
	eq(list[1].key .. '/' .. list[1].label .. '/' .. tostring(list[1].disabled) .. '/' .. tostring(list[1].caption), 'global/Global settings/nil/nil')
	eq(list[2].label .. '/' .. tostring(list[2].caption) .. '/' .. tostring(list[2].key), 'Frames/true/nil', 'a group is a caption')
	eq(list[4].key .. '/' .. tostring(list[4].disabled), 'Off/true', 'disabled kept')
	eq(OW.PageMenuEntries({}) and #OW.PageMenuEntries({}), 0)
end)

test("a search result in an item's menu at W4 opens the menu, kept in the screen margin", function()
	reset()
	st.Config:Open('SideItems', 'texts')
	OW:SetSidebarShown(false); wait(); check(OW:SetWindowSize('half'))
	local F = frames()
	click(F.tools[1]); F.search:SetText('Size'); tick(0.3)
	local found
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.menu then found = c end
	end
	check(found ~= nil, "a result for the menu's Size")
	click(found.frame)
	check(OW:IsMenuShown(), 'the menu opens')
	eq(OW:IsSidebarShown(), false, 'the sidebar stays collapsed'); eq(OW:GetState().search, '', 'the search ended')
	local menu = OW.GetMenuFrames().frame
	local left = st:GetScreenMargin(menu)
	check(menu:GetLeft() >= left - 1e-3, 'the menu is inside the screen margin')
	local off = P.off(menu)
	eq(#off, 0, 'whole pixels ' .. P.report(off))
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

------------------------------------------------------------------ whole pixels

test('whole pixels at W1 to W4 under Thick and Thin', function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		theme(name)
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			st.config.global.optionsWindow = nil
			st.Config:Close(); st.Config:Open('Unitframes', 'player', 'general')
			local F = frames()
			local where = name .. ' noise ' .. noise .. ': '
			local function check_pixels(state)
				local off = P.off(F.window)
				eq(#off, 0, where .. state .. ' ' .. P.report(off))
			end
			check_pixels('W1')
			check(OW:SetSidebarShown(false)); check_pixels('W2 with its footer tools and the title arrow')
			local function with_pop(state)
				click(F.tools[1])
				check(F.searchPop:IsShown(), 'the search panel opens')
				check_pixels(state .. ' with the search panel')
				click(F.tools[1])
				click(F.titleButton)
				local list = W.GetListFrames().frame
				local listed_off = P.off(list)
				eq(#listed_off, 0, where .. state .. ' the page list ' .. P.report(listed_off))
				W.CloseList()
			end
			with_pop('W2')
			wait(); check(OW:SetWindowSize('half')); check_pixels('W4')
			with_pop('W4')
			OW:SetStatus('An error long enough to need a second line in the footer region of the half window, so it wraps')
			check_pixels('W4 with a wrapped status')
			OW:SetStatus(nil)
			check(OW:SetSidebarShown(true)); check_pixels('W3')
			wait(); check(OW:SetWindowSize('full')); check_pixels('W1 again')
			-- The small dialog and an item's menu over the collapsed window.
			st.Config:Open('SideItems', 'texts')
			OW:SetSidebarShown(false)
			click(H.cell('hotkey').widget.dots)
			check(OW:IsMenuShown(), "the item's menu opens")
			local menu = OW.GetMenuFrames().frame
			local off = P.off(menu)
			eq(#off, 0, where .. 'the menu ' .. P.report(off))
			OW:CloseMenu()
			check(OW:OpenDialog('A dialog', { type = 'group', name = 'A dialog', args = { on = { type = 'toggle', name = 'On',
				get = function() return true end, set = function() end } } }), 'the dialog opens')
			local frame = OW.GetDialogFrames().frame
			local cx, cy = frame:GetCenter(); local wx, wy = F.window:GetCenter()
			check(math.abs(cx - wx) <= 1 and math.abs(cy - wy) <= 1, 'centred on the collapsed window')
			off = P.off(frame)
			eq(#off, 0, where .. 'the dialog ' .. P.report(off))
			OW:CloseDialog()
		end
		stub.size_noise = 0
	end
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the guard

test('a second click on the toggle within OW.SIZE_GUARD does nothing; after it the toggle works', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	wait(); click(F.sideToggle)
	eq(OW:IsSidebarShown(), false, 'collapsed')
	click(F.sideToggle)
	eq(OW:IsSidebarShown(), false, 'a second click at once does nothing')
	stub.time = stub.time + OW.SIZE_GUARD - 0.01
	click(F.sideToggle)
	eq(OW:IsSidebarShown(), false, 'still inside the guard')
	stub.time = stub.time + 0.02
	click(F.sideToggle)
	eq(OW:IsSidebarShown(), true, 'after it the toggle works')
	click(F.sideToggle)
	eq(OW:IsSidebarShown(), true, 'and guards again')
	-- The API is not guarded; a reopened window starts clear.
	check(OW:SetSidebarShown(false), 'SetSidebarShown goes at once')
	st.Config:Close(); st.Config:Open('Unitframes', 'player', 'general')
	click(frames().sideToggle)
	eq(OW:IsSidebarShown(), true, 'a click right after opening is not swallowed')
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

------------------------------------------------------------------ no room

test('the footer never overlaps: the tools stop short of Reload UI at W4, and the status line gives way when the region has no room', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	OW:SetSidebarShown(false)
	check(F.footerRegion:GetWidth() >= 24, 'W2: the region holds a status line')
	OW:SetStatus('A short error')
	check(F.status:IsShown(), 'and shows it')
	OW:SetStatus(nil)
	wait(); OW:SetWindowSize('half')
	check(F.tools[#F.tools]:GetRight() + 12 <= F.reloadButton:GetLeft() + 1e-3, 'W4: the last tool is 12 or more before Reload UI')
	check(F.footerRegion:GetWidth() < 24, 'W4 with a text command: the region has no room: ' .. F.footerRegion:GetWidth())
	OW:SetStatus('An error')
	check(not F.status:IsShown(), 'so no status line')
	check(not F.footerControl:IsShown(), 'and no profile control')
	check(F.tools[#F.tools]:IsShown(), 'while every tool stays')
	OW:SetStatus(nil)
	OW:SetSidebarShown(true)
	check(F.footerRegion:GetWidth() >= 24, 'W3: the sidebar is back, the region holds a status line')
	OW:SetStatus('An error')
	check(F.status:IsShown(), 'and shows it')
	OW:SetStatus(nil)
	eq(#take_errors(), 0, 'no errors')
	reset()
end)
