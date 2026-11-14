-- The /sui window's sidebar toggle (SaftUI-Core/Config/optionsnav.lua:
-- OW:IsSidebarShown, OW:SetSidebarShown, F.sideToggle and S.PlaceSideToggle;
-- optionswindow.lua's Relayout with S.sidebar): the sidebar collapses and is
-- shown again at full and at half, the window narrowing from its left, the
-- page and the window's right edge and top never moving; the toggle's two
-- places and looks, what it refuses, what it closes, what it keeps; the state
-- remembered. Real: Core's Config on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window (options_window_helpers.lua).
-- The mouse and the frame clock are played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OW, W = st.OptionsWindow, st.OptionsWidgets
local theme, close_all, frames, click, tick = H.theme, H.close_all, H.frames, H.click, H.tick
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local SCALE = UIParent:GetScale()

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

-- A button's tooltip lines as 'title | line | red:line'.
local function tip_text(button)
	local title, lines = button.tip(button)
	local out = { title }
	for _, line in ipairs(lines or {}) do
		out[#out + 1] = type(line) == 'table' and ((line.red and 'red:' or '') .. line.text) or line
	end
	return table.concat(out, ' | ')
end

local function reset()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
	reset_screen()
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
	click(F.sideToggle)
	eq(OW:IsSidebarShown(), false); eq(w:GetWidth(), 832); eq(w:GetRight(), right); eq(w:GetTop(), top)
	check(not F.side:IsShown(), 'the sidebar hidden')
	eq(F.main:GetLeft(), mainLeft, 'the main column stays'); eq(F.title:GetLeft(), titleLeft); eq(F.body:GetLeft(), bodyLeft)
	eq(st.config.global.optionsWindow.sidebar, false, 'remembered')
	eq(F.sideToggle:GetLeft(), F.main:GetLeft() + 28, "the toggle at the footer's left")
	eq(F.sideToggle:GetParent(), F.footer, 'in the footer')
	eq(F.sideToggle.icon:GetTexture(), st.icons.panelLeftClose, 'its arrow points left: show')
	eq(tip_text(F.sideToggle), 'Show the sidebar | Shows the page list again.')
	click(F.sideToggle)
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
	click(F.sideToggle)
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
	click(F.sideToggle)
	eq(GetCurrentKeyBoardFocus(), nil, 'the box lost the keyboard')
	eq(OW:GetState().search, 'width', 'the search is kept'); eq(F.title:GetText(), 'Search', 'the results still shown')
	check(not F.search:IsVisible(), 'and the box is hidden')
	click(F.sideToggle)
	eq(F.search:GetText(), 'width'); check(not F.search.hint:IsShown(), 'its hint hidden')
	eq(F.title:GetText(), 'Search', 'the results still shown')
	-- A search typed but not yet run when the sidebar collapses still runs.
	F.search:SetText('')
	eq(OW:GetState().search, '')
	F.search:SetFocus(); F.search:SetText('power')
	click(F.sideToggle)
	eq(GetCurrentKeyBoardFocus(), nil)
	tick(0.5)
	eq(OW:GetState().search, 'power', 'the search ran')
	eq(F.title:GetText(), 'Search')
	-- A box that isn't the window's keeps the keyboard.
	click(F.sideToggle)
	local outside = CreateFrame('EditBox', nil, UIParent)
	outside:SetFontObject(W.GetFont())
	outside:SetFocus()
	click(F.sideToggle)
	eq(GetCurrentKeyBoardFocus(), outside, 'a box outside the window keeps it')
	outside:ClearFocus()
	eq(#take_errors(), 0, 'no errors')
	reset()
end)

test('page, tab, pick and search are kept across a collapse', function()
	reset()
	st.Config:Open('Unitframes', 'target', 'power')
	local before = OW:GetState()
	click(frames().sideToggle)
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
	eq(tip_text(F.sideToggle), 'Collapse the sidebar | Hides the page list; the window narrows from its left. | red:Close the color picker first.')
	wait(); click(F.sideToggle)
	eq(OW:IsSidebarShown(), true, 'a click does nothing')
	eq(OW:SetSidebarShown(false), false)
	check(W.ColorPickerShown(), 'and the picker stays')
	W.CloseColorPicker()
	check(not F.sideToggle.disabled, 'enabled again')
	click(F.sideToggle)
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
	eq(tip_text(F.sideToggle), 'Show the sidebar | Shows the page list again. | red:The screen is too narrow for the sidebar at full size. Shrink to half first.')
	wait(); click(F.sideToggle)
	eq(OW:IsSidebarShown(), false, 'a click does nothing'); eq(F.window:GetWidth(), 832)
	eq(OW:SetSidebarShown(true), false)
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'half')
	check(not F.sideToggle.disabled, 'at half it is enabled')
	eq(tip_text(F.sideToggle), 'Show the sidebar | Shows the page list again.')
	click(F.sideToggle)
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
	click(F.sideToggle)
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
	eq(F.footerRegion:GetLeft(), F.sideToggle:GetRight() + 12, 'collapsed: 12 after the toggle')
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
	check(F.status:IsShown(), 'the status has the region')
	OW:SetSidebarShown(true)
	check(not F.footerControl:IsShown(), 'at W3 too')
	wait(); OW:SetWindowSize('full')
	OW:SetSidebarShown(false); OW:SetSidebarShown(true)
	check(F.footerControl:IsShown(), 'back at full: shown again')
	clear_of_toggle()
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
			check(OW:SetSidebarShown(false)); check_pixels('W2')
			wait(); check(OW:SetWindowSize('half')); check_pixels('W4')
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
