-- /sui's third size, the bar (SaftUI-Core/Config/optionssizes.lua's
-- S.BuildMini and S.DrawMini, optionswindow.lua's Relayout and Draw at the
-- bar): a 42 tall bar at the window's top right corner with the name, the
-- page, the tab, grow and close; what shrinking closes; growing back to the
-- page, tab, pick, search and scroll it had; its drag and its click; Esc,
-- combat and keybind mode; /sui, a path and a mover's click while the bar
-- shows; the corner, the margin and the grip; the sidebar's brand; the names
-- following a rename and cut to the bar's width; whole pixels. The bar under
-- Blizzard is options_settings_test.lua's.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua, which loads edit mode), the model, the widgets, the
-- body and the window (the world options_window_helpers.lua loads). The mouse
-- and the frame clock are played by firing scripts (stub.fire_script).
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OW, W, EM, OB = st.OptionsWindow, st.OptionsWidgets, st.EditModeFrames, st.OptionsBody
local theme, close_all, frames, click, tick = H.theme, H.close_all, H.frames, H.click, H.tick
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

-- Time passes past the size guard (OW.SIZE_GUARD).
local function wait() stub.time = stub.time + 0.31 end

local function to_half()
	wait()
	OW:SetWindowSize('half')
end

local function to_mini()
	wait()
	OW:SetWindowSize('mini')
end

local function reset()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
end

local function rgb(fs)
	local r, g, b = fs:GetTextColor()
	return ('%.2f,%.2f,%.2f'):format(r, g, b)
end

local function color_of(c) return ('%.2f,%.2f,%.2f'):format(c:GetRGB()) end

-- Sixty toggles: a page that scrolls.
local manyValue = {}
local MANY = st:NewModule('MiniMany')
function MANY:GetConfigTable()
	local args = {}
	for i = 1, 60 do
		args['t' .. i] = { order = i, type = 'toggle', name = 'Toggle ' .. i, desc = 'Toggle ' .. i,
			get = function() return manyValue[i] end, set = function(_, v) manyValue[i] = v end }
	end
	return { name = 'Many', type = 'group', category = 'Frames', args = args }
end

-- A page and one tab whose names can change.
local pageName = 'Short'
local RENAME = st:NewModule('MiniRename')
function RENAME:GetConfigTable()
	local function tab(name, order)
		return { order = order, name = name, type = 'group', args = { on = { type = 'toggle', name = 'On',
			get = function() return true end, set = function() end } } }
	end
	return {
		name = function() return pageName end, type = 'group', category = 'Frames', childGroups = 'tab',
		args = { a = tab(function() return pageName .. ' tab' end, 1), b = tab('Other tab', 2) },
	}
end

-- One item with a menu.
local ITEMS = st:NewModule('MiniItems')
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

local function ceil_width(fs) return math.ceil(fs:GetUnboundedStringWidth()) end

------------------------------------------------------------------ the bar

test('Shrink at half: a 42 tall bar at the same corner with the name, the page, the tab, grow and close', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'power'); to_half()
	local F = frames(); local w = F.window
	local right, top = w:GetRight(), w:GetTop()
	check(F.shrink:IsShown() and F.grow:IsShown(), 'shrink shows at half now, beside grow')
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'mini'); check(OW:IsShown(), 'still the window, shown')
	eq(w:GetHeight(), 42); eq(w:GetRight(), right); eq(w:GetTop(), top)
	for _, part in ipairs({ 'side', 'main', 'footer', 'grip', 'sizer', 'innerList', 'innerSettings', 'titleBar', 'titleText' }) do
		check(not F[part]:IsShown(), part .. ' hidden')
	end
	check(F.mini:IsShown(), 'the bar shows')
	check(not F.shrink:IsShown() and not F.grow:IsShown(), "the header's arrows are hidden")
	eq(F.miniBrand:GetText(), OW.BrandText(), 'SaftUI, UI in the accent')
	eq(F.miniPage:GetText() .. '/' .. F.miniTab:GetText(), 'Unitframes/Power', 'the page and the tab')
	eq(F.miniBrand:GetFontObject(), OB.Font('mini'), 'the name in the mini font')
	eq(F.miniPage:GetFontObject(), OB.Font('group'), 'the page in group')
	eq(F.miniTab:GetFontObject(), OB.Font('field'), 'the tab in field')
	eq(rgb(F.miniPage), color_of(st.config.profile.colors.text.grey), 'the page in Text > Grey')
	eq(rgb(F.miniTab), color_of(st.config.profile.colors.text.grey), 'the tab in Text > Grey')
	eq(st:DrawnKind(w), 'panel', 'drawn as a panel')
	eq(st.config.global.optionsWindow.size, 'half', 'a bar comes back as half')
	-- 12 in; each part 8 after the last; close 8 in from the right; grow and close centred on the 42.
	eq(F.miniBrand:GetLeft() - w:GetLeft(), 12, 'the name 12 in')
	eq(F.miniPage:GetLeft(), F.miniBrand:GetRight() + 8, 'the page 8 after')
	eq(F.miniTab:GetLeft(), F.miniPage:GetRight() + 8, 'the tab 8 after')
	local sum = 12 + 54 + 8 + ceil_width(F.miniPage) + 8 + ceil_width(F.miniTab) + 8 + 56 + 8
	eq(F.miniGrow:GetLeft(), F.miniTab:GetRight() + 8 + sum % 2, 'grow 8 after the tab, 9 when the width was rounded up to even')
	eq(F.close:GetLeft(), F.miniGrow:GetRight() + 8, 'close 8 after grow')
	eq(w:GetRight() - F.close:GetRight(), 8, 'close 8 in from the right')
	eq(F.miniGrow:GetWidth() .. 'x' .. F.miniGrow:GetHeight(), '24x24', "grow is the close X's size")
	eq(w:GetTop() - F.miniGrow:GetTop(), 9, 'grow 9 from the top'); eq(F.miniGrow:GetBottom() - w:GetBottom(), 9, 'and 9 from the bottom')
	eq(w:GetTop() - F.close:GetTop(), 9, 'close 9 from the top'); eq(F.close:GetBottom() - w:GetBottom(), 9, 'and 9 from the bottom')
	eq(w:GetWidth() % 2, 0, 'even'); check(w:GetWidth() <= 400, 'at most 400')
	eq(w:GetWidth(), sum + sum % 2, 'the parts add up, rounded up to even')
	eq(F.miniGrow.icon:GetTexture(), st.icons.maximize2, 'grow wears maximize-2')
	eq(F.miniGrow.icon:GetWidth(), 16, 'at 16')
	eq(F.close:GetParent(), w, 'the close X is still the window\'s'); check(F.close:GetFrameLevel() > F.mini:GetFrameLevel(), 'over the bar')
	check(F.miniGrow:GetFrameLevel() > F.mini:GetFrameLevel() and F.miniNames:GetFrameLevel() > F.mini:GetFrameLevel(), 'its buttons over it')
	-- The tooltips.
	local function tip(button)
		local title, lines = button.tip(button)
		return title .. ' | ' .. table.concat(lines, ' | ')
	end
	eq(tip(F.miniGrow), 'Grow to half | Back to the page as you left it.')
	stub.fire_script(F.miniGrow, 'OnEnter', true)
	check(GameTooltip:IsOwned(F.miniGrow), "grow's tooltip")
	stub.fire_script(F.miniGrow, 'OnLeave', true)
	wait(); click(F.miniGrow)
	eq(OW:GetWindowSize(), 'half', 'grow grows to half')
	eq(w:GetHeight(), OW.WindowHeight(OW.LAYOUT.own), 'the window\'s height again')
	check(F.main:IsShown() and F.footer:IsShown() and F.grip:IsShown() and F.sizer:IsShown() and F.side:IsShown(), 'its parts back')
	check(not F.mini:IsShown(), 'the bar gone')
	eq(st:DrawnKind(w), 'window', 'drawn as a window')
	eq(w:GetRight(), right); eq(w:GetTop(), top)
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('a bar only from half; shrink twice quickly stops at half; Shrink and Grow at the ends', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	wait()
	eq(OW:SetWindowSize('mini'), false, 'not from full')
	click(F.shrink)
	click(F.shrink)
	eq(OW:GetWindowSize(), 'half', 'a fast double click stops at half (the guard)')
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'mini')
	eq(OW:Shrink(), false, 'nothing past the bar')
	eq(OW:SetWindowSize('mini'), false, 'no change')
	wait(); click(F.miniGrow)
	eq(stub.try_click(F.miniGrow), false, 'the button went at half: a fast second click is not delivered')
	eq(OW:GetWindowSize(), 'half', 'grow then a fast second click stays at half')
	check(not F.miniGrow:IsVisible(), 'grow gone at half')
	wait(); stub.in_combat = true
	eq(OW:SetWindowSize('mini'), false, 'refused in combat')
	stub.in_combat = false
	check(W.OpenColorPicker(F.window, { r = 1, g = 0, b = 0, onChange = function() end }), 'a color picker opens')
	eq(OW:SetWindowSize('mini'), false, 'refused while it is open')
	check(F.shrink.disabled, 'and shrink is disabled')
	W.CloseColorPicker()
	eq(OW:SetWindowSize('mini'), true, 'then it works')
	eq(OW:SetWindowSize('half'), true, 'a bar grows to half by SetWindowSize')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('shrinking to the bar closes a menu, the small dialog and a list, takes the keyboard, and clears the status', function()
	reset()
	st.Config:Open('MiniItems', 'texts'); to_half()
	local F = frames()
	-- The small dialog.
	check(OW:OpenDialog('A dialog', { type = 'group', name = 'A dialog', args = { on = { type = 'toggle', name = 'On',
		get = function() return true end, set = function() end } } }), 'the dialog opens')
	wait(); OW:Shrink()
	eq(OW:GetWindowSize(), 'mini')
	check(not OW:IsDialogShown(), 'the dialog is closed')
	wait(); OW:Grow()
	-- An item's menu.
	click(H.cell('hotkey').widget.dots)
	check(OW:IsMenuShown(), "the item's menu opens")
	wait(); OW:Shrink()
	eq(OW:GetWindowSize(), 'mini'); check(not OW:IsMenuShown(), 'the menu is closed')
	wait(); OW:Grow()
	-- A dropdown's list.
	st.Config:Open('Unitframes', 'player', 'general')
	click(F.picker.frame)
	check(W.ListOwner() ~= nil, 'the list is open')
	wait(); OW:Shrink()
	eq(OW:GetWindowSize(), 'mini'); eq(W.ListOwner(), nil, 'the list is closed')
	check(not W.GetListFrames().catcher:IsShown(), 'with its catcher')
	wait(); OW:Grow()
	-- The keyboard and the status.
	F.search:SetFocus()
	OW:SetStatus('Size: a number, please')
	eq(F.status:GetText(), 'Size: a number, please')
	wait(); OW:Shrink()
	eq(GetCurrentKeyBoardFocus(), nil, 'no box has the keyboard')
	eq(F.status:GetText(), '', 'the status is clear')
	wait(); OW:Grow()
	eq(F.status:GetText(), '', 'and stays clear')
	-- A box outside the window keeps the keyboard.
	local outside = CreateFrame('EditBox', nil, UIParent)
	outside:SetFontObject(W.GetFont())
	outside:SetFocus()
	wait(); OW:Shrink()
	eq(GetCurrentKeyBoardFocus(), outside, "a box that isn't the window's keeps it")
	outside:ClearFocus()
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('growing back: half at the page, tab, pick, scroll and search it had', function()
	reset()
	st.Config:Open('MiniMany'); to_half()
	local F, S = frames(), OW.S
	S.SetScroll(120)
	eq(S.scrollOffset, 120, 'scrolled at half')
	S.navOffset = 5 -- a value the bar's render must not clamp away or reset
	local nav = S.navOffset
	to_mini()
	st.Config:Refresh(); tick()
	eq(#OW.GetDrawnRows(), 0, 'a render at the bar draws no page')
	eq(S.scrollOffset, 120, 'the offset is kept'); eq(S.navOffset, nav, "and the nav's")
	wait(); OW:Grow()
	eq(F.body:GetVerticalScroll(), 120, 'half again at exactly the scroll it had')
	check(#OW.GetDrawnRows() > 0, 'the page is drawn')
	-- The pick and the tab.
	st.Config:Open('Unitframes', 'target', 'power'); to_mini()
	wait(); OW:Grow()
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/target/power', 'the page, pick and tab kept')
	-- A search.
	st.Config:Open('MiniMany'); S.SetScroll(0)
	F.search:SetText('Toggle 5'); tick(0.3)
	eq(OW:GetState().search, 'Toggle 5', 'a search is running')
	S.SetScroll(40)
	to_mini()
	eq(F.miniPage:GetText() .. ' ' .. F.miniTab:GetText(), 'Search "Toggle 5"', "the bar's page is Search and its tab the text")
	wait(); OW:Grow()
	eq(OW:GetState().search, 'Toggle 5', 'the results page again')
	eq(F.body:GetVerticalScroll(), S.scrollOffset, 'at its scroll')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('a click on the names grows it; a drag anywhere but its buttons moves it and is no click', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'power'); to_half(); to_mini()
	local F = frames(); local w, names = F.window, F.miniNames
	eq(names:GetLeft(), F.miniPage:GetLeft(), 'the names button starts at the page'); eq(names:GetRight(), F.miniTab:GetRight(), 'and ends at the tab')
	eq(names:GetHeight(), 42, 'the bar tall')
	wait() -- past the size guard, so only the dragged flag can stop the click below
	stub.fire_script(names, 'OnMouseDown', 'LeftButton')
	eq(names.dragged, false, 'a press is no drag yet')
	stub.fire_script(names, 'OnDragStart')
	eq(names.dragged, true); eq(stub.state(w).moving, true, 'the window moves')
	w:ClearAllPoints(); w:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -300, -100) -- where the mouse left it
	stub.fire_script(names, 'OnDragStop')
	eq(stub.state(w).moving, false)
	stub.fire_script(names, 'OnClick', 'LeftButton')
	eq(OW:GetWindowSize(), 'mini', 'the click at the end of a drag does nothing')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'TOPRIGHT -300 -100', 'the corner saved from where it shows')
	-- The bar itself drags too.
	stub.fire_script(F.mini, 'OnDragStart')
	eq(stub.state(w).moving, true, 'a drag on the bar moves the window')
	w:ClearAllPoints(); w:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -250, -60)
	stub.fire_script(F.mini, 'OnDragStop')
	eq(saved.x .. ' ' .. saved.y, '-250 -60')
	wait()
	stub.fire_script(names, 'OnMouseDown', 'LeftButton')
	stub.fire_script(names, 'OnClick', 'LeftButton')
	eq(OW:GetWindowSize(), 'half', 'a plain click grows it to half')
	eq(w:GetRight(), UIParent:GetRight() - 250, 'at the corner it was left at')
	-- The tooltip: the path, and what a click and a drag do. It takes only (self).
	wait(); OW:Shrink()
	stub.fire_script(names, 'OnEnter', true)
	check(GameTooltip:IsOwned(names), 'owned by the names')
	local texts = stub.state(GameTooltip).texts
	eq(texts[1], 'Unitframes > Player > Power', 'the path'); eq(texts[2], 'Click to grow to half. Drag to move.')
	stub.fire_script(names, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone when it leaves')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('Esc, combat and keybind mode close the bar; it opens again at half', function()
	reset()
	st.Config:Open('Loot'); to_half(); to_mini()
	stub.fire_script(frames().keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsShown(), 'Esc closes the bar')
	st.Config:Open()
	check(OW:IsShown(), 'it opens'); eq(OW:GetWindowSize(), 'half', 'at half'); eq(frames().window:GetHeight(), OW.WindowHeight(OW.LAYOUT.own), 'with its height')
	check(frames().main:IsShown(), 'and its parts')
	-- Combat.
	to_mini()
	st.Config:PLAYER_REGEN_DISABLED()
	check(not OW:IsShown(), 'combat closes the bar')
	stub.in_combat = true
	st.Config:Open()
	check(not OW:IsShown(), 'and /sui refuses to open there')
	eq(OW:Open({}), false)
	stub.in_combat = false
	st.Config:Open(); eq(OW:GetWindowSize(), 'half', 'out of combat it opens at half')
	-- Keybind mode's own calls.
	to_mini()
	eq(st.Config:GetWindow(), frames().window, 'the window is the frame at the bar')
	st.Config:Close()
	check(not OW:IsShown(), 'closed')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('/sui, a path, and a mover\'s click while the bar shows grow it to half on that page', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'power'); to_half(); to_mini()
	st.Config:Open()
	eq(OW:GetWindowSize(), 'half', '/sui grows it'); eq(OW:GetState().tab, 'power', 'on the page it had')
	check(frames().main:IsShown() and not frames().mini:IsShown(), 'drawn as half')
	wait(); OW:Shrink()
	st.Config:Open('Loot')
	eq(OW:GetWindowSize(), 'half', 'a path grows it'); eq(OW:GetState().page, 'Loot', 'on that page')
	eq(st.config.global.optionsWindow.size, 'half', 'and the save stays half')
	-- A mover on the Loot page.
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50); frame:SetPoint('CENTER')
	local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
	local mover = st:RegisterConfigMover(frame, { key = 'mini_mover', config = function() return config end,
		apply = function() end, configPath = { 'Loot' } })
	st.Config:Open('Chat'); wait(); OW:Shrink()
	EM:Select(mover)
	eq(OW:GetWindowSize(), 'half', "selecting a mover grows it"); eq(OW:GetState().page, 'Loot', 'on its page')
	-- The mover already selected: a click on its overlay grows the bar to its
	-- page (from another page, so the click must have navigated); at half it
	-- leaves /sui on the page it shows; closed it opens /sui.
	OW:Navigate('Chat'); wait(); OW:Shrink()
	eq(OW:GetWindowSize(), 'mini')
	mover.dragged = false
	-- (the stubs never show the mover overlay of a mover not in edit mode: press it unchecked)
	stub.click_unchecked(mover.overlay)
	eq(OW:GetWindowSize(), 'half', 'a click on the selected mover grows the bar'); eq(OW:GetState().page, 'Loot', 'to the mover\'s page')
	OW:Navigate('Chat')
	stub.click_unchecked(mover.overlay)
	eq(OW:GetState().page, 'Chat', "at half the click leaves /sui on the page it shows"); eq(OW:GetWindowSize(), 'half')
	st.Config:Close()
	stub.click_unchecked(mover.overlay)
	check(OW:IsShown(), 'closed: the click opens it')
	-- A drag is no click.
	st.Config:Close()
	mover.dragged = true
	stub.click_unchecked(mover.overlay)
	check(not OW:IsShown(), 'a drag is no click')
	mover.dragged = false
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('the height grip and the margin leave the bar alone; a bar low on the screen grows back with its anchor kept', function()
	reset()
	st.Config:Open('Loot'); to_half(); to_mini()
	local F = frames(); local w = F.window
	st:UpdateScreenMargin()
	eq(w:GetHeight(), 42, 'the margin leaves it 42')
	check(not F.grip:IsShown(), 'no grip')
	st.config.profile.misc.clamp_inset = st.config.profile.misc.clamp_inset + 10
	st:UpdateScreenMargin()
	eq(w:GetHeight(), 42, 'a margin change leaves it 42')
	st.config.profile.misc.clamp_inset = st.config.profile.misc.clamp_inset - 10
	st:UpdateScreenMargin()
	-- A corner low on the screen.
	OW:Grow(); wait(); st.Config:Close()
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = -100, y = -1040, size = 'half' }
	st.Config:Open('Loot')
	to_mini()
	local _, _, _, x, y = w:GetPoint(1)
	eq(x .. ' ' .. y, '-100 -1040', 'the bar is at the corner')
	wait(); OW:Grow()
	_, _, _, x, y = w:GetPoint(1)
	eq(x .. ' ' .. y, '-100 -1040', 'grown, the anchor is the same')
	local saved = st.config.global.optionsWindow
	eq(saved.x .. ' ' .. saved.y .. ' ' .. saved.size, '-100 -1040 half', 'and the save too')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test("the sidebar's brand: Saft in the text colour, UI in the accent, read at each draw", function()
	reset()
	st.Config:Open('Loot')
	local F = frames()
	local blue = st.config.profile.colors.button.blue
	local function hex() return ('%02x%02x%02x'):format(math.floor(blue.r * 255 + 0.5), math.floor(blue.g * 255 + 0.5), math.floor(blue.b * 255 + 0.5)) end
	eq(OW.BrandText(), 'Saft|cff' .. hex() .. 'UI|r', 'the text')
	eq(F.brandName:GetText(), OW.BrandText(), 'the sidebar draws it')
	eq(rgb(F.brandName), color_of(st.config.profile.colors.text.normal), 'Saft is in the text colour')
	local r, g, b = blue.r, blue.g, blue.b
	blue.r, blue.g, blue.b = 0.9, 0.1, 0.2
	OW:Render()
	eq(F.brandName:GetText(), 'Saft|cffe61a33UI|r', 'a new accent at the next render')
	eq(OW.BrandText(), 'Saft|cffe61a33UI|r')
	blue.r, blue.g, blue.b = r, g, b
	to_half(); to_mini()
	eq(F.miniBrand:GetText(), OW.BrandText(), 'the bar too')
	reset()
end)

test('the bar follows a rename of its page and tab, and is cut to fit, never drawn past the bar', function()
	reset()
	pageName = 'Short'
	st.Config:Open('MiniRename'); to_half(); to_mini()
	local F = frames()
	eq(F.miniPage:GetText() .. '/' .. F.miniTab:GetText(), 'Short/Short tab')
	local width = F.window:GetWidth()
	pageName = 'A longer name'
	st.Config:Refresh(); tick()
	eq(OW:GetWindowSize(), 'mini', 'still the bar')
	eq(F.miniPage:GetText() .. '/' .. F.miniTab:GetText(), 'A longer name/A longer name tab', 'the new names')
	check(F.window:GetWidth() > width, 'the bar is wider')
	eq(F.window:GetWidth() % 2, 0, 'and even')
	-- Too long: the tab is cut first, then the page.
	pageName = string.rep('W', 60)
	st.Config:Refresh(); tick()
	local w = F.window
	eq(w:GetWidth(), 400, 'the bar stops at 400')
	check(not F.miniTab:IsShown(), 'the tab goes first')
	check(F.miniPage:GetRight() + 8 <= F.miniGrow:GetLeft(), 'the page ends before grow')
	check(F.miniNames:GetRight() <= F.miniGrow:GetLeft(), 'the names button too')
	check(F.close:GetRight() <= w:GetRight() and F.miniBrand:GetLeft() >= w:GetLeft(), 'nothing past the bar')
	eq(F.miniPage:GetWidth(), 400 - (12 + 54 + 8 + 8 + 56 + 8), 'the page cut to the room')
	-- A tab alone too long: cut, still inside.
	pageName = 'Mid'
	st.Config:Refresh(); tick()
	check(F.miniTab:IsShown() and F.miniTab:GetRight() + 8 <= F.miniGrow:GetLeft(), 'a normal tab fits again')
	-- A profile switch redraws the bar too.
	pageName = 'Short'
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('opening again after the window closed as a bar: half, with the bar gone', function()
	reset()
	st.Config:Open('Loot'); to_half(); to_mini()
	st.Config:Close()
	eq(st.config.global.optionsWindow.size, 'half')
	st.Config:Open('Loot')
	local F = frames()
	eq(OW:GetWindowSize(), 'half'); check(not F.mini:IsShown() and F.main:IsShown(), 'half is drawn')
	eq(F.window:GetWidth(), 654)
	eq(st:DrawnKind(F.window), 'window')
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

test('a theme change at the bar keeps it a bar', function()
	reset()
	st.Config:Open('Unitframes', 'player', 'power'); to_half(); to_mini()
	local F = frames()
	theme('thin')
	eq(OW:GetWindowSize(), 'mini'); eq(F.window:GetHeight(), 42); eq(st:DrawnKind(F.window), 'panel', 'Thin: still a panel')
	theme('thick')
	eq(st:DrawnKind(F.window), 'panel', 'Thick again: still a panel')
	check(F.mini:IsShown() and not F.main:IsShown(), 'the bar')
	reset()
end)

test('whole pixels at the bar under Thick and Thin, with the size noise up, down and off', function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		theme(name)
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			st.config.global.optionsWindow = nil
			st.Config:Close(); st.Config:Open('Unitframes', 'player', 'power')
			local F = frames()
			to_half(); to_mini()
			local off = P.off(F.window)
			eq(#off, 0, name .. ' noise ' .. noise .. ': ' .. P.report(off))
			OW:Render()
			off = P.off(F.window)
			eq(#off, 0, name .. ' noise ' .. noise .. ' drawn again: ' .. P.report(off))
		end
		stub.size_noise = 0
	end
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ fix round 1

-- A page with exactly one tab.
local ONE = st:NewModule('MiniOneTab')
function ONE:GetConfigTable()
	return { name = 'One tab', type = 'group', category = 'Frames', childGroups = 'tab', args = {
		only = { order = 1, type = 'group', name = 'Only tab', args = { on = { type = 'toggle', name = 'On',
			get = function() return true end, set = function() end } } } } }
end

test('a page with exactly one tab shows no tab name on the bar', function()
	reset()
	st.Config:Open('MiniOneTab'); to_half(); to_mini()
	local F = frames()
	eq(F.miniPage:GetText() .. '/' .. F.miniTab:GetText(), 'One tab/', 'one tab: no tab name')
	check(not F.miniTab:IsShown(), 'the tab hidden')
	eq(F.miniNames:GetRight(), F.miniPage:GetRight(), 'the names end at the page')
	reset()
end)

test("a double click whose second click lands on the other size's arrow does nothing", function()
	reset()
	st.Config:Open('Loot'); to_half()
	local F = frames()
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'mini')
	click(F.miniGrow)
	eq(OW:GetWindowSize(), 'mini', "half's shrink then the bar's grow, which sits about there: held by the guard")
	stub.fire_script(F.miniNames, 'OnMouseDown', 'LeftButton')
	click(F.miniNames)
	eq(OW:GetWindowSize(), 'mini', 'and on the names')
	wait(); click(F.miniGrow)
	eq(OW:GetWindowSize(), 'half')
	click(F.shrink)
	eq(OW:GetWindowSize(), 'half', "the bar's grow then half's shrink: held too")
	reset()
end)

test('on a screen too narrow for half the bar still grows to half, by its arrow, its names and /sui alike', function()
	reset()
	st.Config:Open('Loot'); to_half(); to_mini()
	local F = frames()
	local old = UIParent:GetScale()
	stub.screen_width = 600
	OW:Render()
	check(not OW.Fits(OW.LAYOUT.own, 'half', true), 'half does not fit')
	check(not F.miniGrow.disabled, 'grow is not disabled: half is the floor (Ruling 4)')
	wait(); click(F.miniGrow)
	eq(OW:GetWindowSize(), 'half', 'it grows')
	to_mini()
	st.Config:Open()
	eq(OW:GetWindowSize(), 'half', '/sui grows it too')
	stub.screen_width = 1920
	UIParent:SetScale(old)
	reset()
end)

test('the bar keeps only its own edges in the screen margin, under Blizzard too', function()
	reset()
	theme('blizzard')
	st.Config:Open('Loot'); to_half()
	local F = frames()
	local margin = math.max(0, st.config.profile.misc.clamp_inset)
	local l, r, t, b = F.window:GetClampRectInsets()
	check(l ~= -margin or r ~= margin or t ~= margin or b ~= -margin, 'half keeps the metal in as well')
	to_mini()
	l, r, t, b = F.window:GetClampRectInsets()
	eq(l .. ' ' .. r .. ' ' .. t .. ' ' .. b, (-margin) .. ' ' .. margin .. ' ' .. margin .. ' ' .. (-margin), 'the bar: the margin only')
	wait(); OW:Grow()
	l, r, t, b = F.window:GetClampRectInsets()
	check(l ~= -margin or r ~= margin or t ~= margin or b ~= -margin, 'grown, the metal again')
	reset()
end)
