-- An item's menu (SaftUI-Core/Config/optionsmenu.lua): OW:OpenMenu,
-- OW:CloseMenu, OW:IsMenuShown, OW.MenuPlace and S.FollowMenu, the window's
-- and the small dialog's wiring (optionswindow.lua, optionssmalldialog.lua),
-- and search finding a menu's settings (OM.Search).
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window's files, as
-- options_window_helpers.lua loads them, with its synthetic modules, and the
-- /sui tree Config:GetOptionsTable builds. Items, a synthetic module here, has
-- two tabs: Texts, with two items whose menus hold a select, a range, a
-- Position and a centred Reset (Hotkey with a Show box, Cooldown with none),
-- and Other. The mouse, the keyboard and the frame clock are played by firing
-- scripts (stub.fire_script), OnEnter and OnLeave with true as the game
-- passes them.
local H = load_test_file('core/options_window_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local st = SaftUI
local OM, W, OB, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local close_all, frames, click, cell, tick, theme = H.close_all, H.frames, H.click, H.cell, H.tick, H.theme
local drawn = T.watch() -- before the menu is first built, so its draw is seen

------------------------------------------------------------------ the Items module

local values, pos, resets
hideHotkey = false

local function fresh()
	values = { hotkey = true, outline = 'none', size = 10, plain = true }
	pos = { point = 'TOPRIGHT', rel_point = 'TOPRIGHT', x_off = -3, y_off = -3 }
	resets = 0
	hideHotkey = false
end
fresh()

-- A text's menu: Outline (a select), Size (a range), its Position, a centred Reset.
local function TextMenu(name)
	return {
		type = 'group', name = name,
		get = function(info) return values[info[#info]] end,
		set = function(info, value) values[info[#info]] = value end,
		args = {
			outline = { order = 1, type = 'select', name = 'Outline', desc = 'Its outline.', values = { none = 'None', thick = 'Thick' } },
			size = { order = 2, type = 'range', name = 'Size', desc = 'Its size.', min = 6, max = 20, step = 1 },
			position = st.Config.generators.position(3, false, function(part) return pos[part] end,
				function(part, value) pos[part] = value end, nil, 'Where it sits.', 'Position'),
			reset = { order = 4, type = 'execute', name = 'Reset', desc = 'Back to the default.', align = 'center',
				func = function() resets = resets + 1 end },
		},
	}
end

local function HotkeyItem(extra)
	local item = {
		order = 1, type = 'item', name = 'Hotkey', desc = 'The key.', size = 'small', menuTitle = 'Hotkey text',
		hidden = function() return hideHotkey end,
		get = function() return values.hotkey end,
		set = function(_, value) values.hotkey = value end,
		menu = TextMenu('Hotkey'),
	}
	for key, value in pairs(extra or {}) do item[key] = value end
	return item
end

local ITM = st:NewModule('Items')
function ITM:GetConfigTable()
	return {
		name = 'Items', type = 'group', category = 'Frames',
		args = {
			texts = { order = 1, type = 'group', name = 'Texts', args = {
				hotkey = HotkeyItem(),
				-- No Show: no box; its menu titled with menuTitle as a function.
				cooldown = { order = 2, type = 'item', name = 'Cooldown', desc = 'The numbers.', size = 'small',
					menuTitle = function() return 'Cooldown numbers' end, menu = TextMenu('Cooldown') },
			} },
			other = { order = 2, type = 'group', name = 'Other', args = {
				plain = { type = 'toggle', name = 'Plain', desc = 'Plain.',
					get = function() return values.plain end, set = function(_, v) values.plain = v end },
			} },
		},
	}
end

------------------------------------------------------------------ helpers

local function M() return OW.GetMenuFrames() end

local function menuCell(key)
	for _, c in ipairs(M().body.cells) do
		if c.row.key == key then return c end
	end
end

local function open_items()
	fresh()
	st.Config:Open('Items', 'texts')
end

local function dots(key) return cell(key).widget.dots end

local function tab(key)
	for _, t in ipairs(frames().tabs) do
		if t.key == key then return t end
	end
end

local function point(region)
	local p, rel, relPoint, x, y = region:GetPoint(1)
	return p, rel, relPoint, x, y
end

------------------------------------------------------------------ MenuPlace

test('MenuPlace: under the dots, right-aligned; flipped above near the bottom; left-aligned near the left', function()
	local function at(...) return table.concat({ OW.MenuPlace(...) }, ',') end
	eq(at({ left = 600, right = 616, top = 500, bottom = 476 }, 400, 300, 1920, 1080), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'below')
	eq(at({ left = 600, right = 616, top = 200, bottom = 176 }, 400, 300, 1920, 1080), 'BOTTOMRIGHT,TOPRIGHT,0,4', 'above, near the bottom')
	eq(at({ left = 100, right = 116, top = 500, bottom = 476 }, 400, 300, 1920, 1080), 'TOPLEFT,BOTTOMLEFT,0,-4', 'to the right, near the left')
	eq(at({ left = 100, right = 116, top = 200, bottom = 176 }, 400, 300, 1920, 1080), 'BOTTOMLEFT,TOPLEFT,0,4', 'both')
	-- No room either way: the side with more of it.
	eq(at({ left = 600, right = 616, top = 300, bottom = 276 }, 400, 300, 1920, 500), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'more room below')
	eq(at({ left = 600, right = 616, top = 224, bottom = 200 }, 400, 300, 1920, 500), 'BOTTOMRIGHT,TOPRIGHT,0,4', 'more room above')
end)

------------------------------------------------------------------ opening

test('the dots open the menu: over the dialog, one column, titled, the position block in it', function()
	open_items()
	check(not OW:IsMenuShown(), 'none to start')
	click(dots('hotkey'))
	local m = M()
	check(OW:IsMenuShown(), 'the dots open it')
	check(OW:IsMenuShown(cell('hotkey').widget), "it's Hotkey's")
	check(not OW:IsMenuShown(cell('cooldown').widget), "not Cooldown's")
	eq(m.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG', "the window's strata")
	eq(m.frame:GetFrameLevel(), 410, "over the small dialog's 300")
	eq(m.frame:GetWidth(), 400, '400 wide')
	eq(m.catcher:GetFrameStrata(), 'FULLSCREEN_DIALOG')
	eq(m.catcher:GetFrameLevel(), 400, 'its catcher just under it')
	check(m.catcher:IsShown() and m.catcher:IsMouseEnabled(), 'taking the mouse')
	eq(m.catcher:GetWidth() .. 'x' .. m.catcher:GetHeight(), UIParent:GetWidth() .. 'x' .. UIParent:GetHeight(), 'over UIParent')
	check(cell('hotkey').body.cells == OW.GetDrawnRows(), "the item is the page's")
	eq(m.owner.body, cell('hotkey').body, "the page's body")
	eq(m.owner.path[#m.owner.path], 'hotkey', 'and the item by its path')

	-- Its title and anchor.
	eq(m.title:GetText(), 'Hotkey text', 'titled with menuTitle')
	eq(m.title:GetLeft() - m.frame:GetLeft(), 12, '12 in')
	eq(m.frame:GetTop() - m.title:GetTop(), 10, '10 down')
	local p, rel, relPoint, x, y = point(m.frame)
	eq(p .. ' ' .. relPoint .. ' ' .. x .. ',' .. y, 'TOPRIGHT BOTTOMRIGHT 0,-4', "its right on the dots' right, 4 under them")
	eq(rel, dots('hotkey'), 'anchored to the dots')

	-- One column: every row the body's width, inside its padding.
	eq(m.body.width, 376, 'the body 376 wide')
	eq(m.body.oneColumn, true)
	for _, key in ipairs({ 'outline', 'size' }) do
		local c = menuCell(key)
		eq(c.frame:GetLeft() - m.content:GetLeft(), 14, key .. ': in the padding')
		eq(c.frame:GetWidth(), 376 - 28, key .. ': across the body')
	end
	check(menuCell('size').frame:GetTop() < menuCell('outline').frame:GetTop(), 'one under the other')
	local titled = false
	for _, t in ipairs(m.body.pools.title.used) do
		if t:GetText() == 'Position' then titled = true end
	end
	check(titled, 'a Position section')
	check(menuCell('position') ~= nil, 'with its block')
	local reset = menuCell('reset').widget.frame
	eq(math.floor(reset:GetLeft() - m.content:GetLeft() + reset:GetWidth() / 2), 188, 'Reset centred')
	-- As tall as the title and the body.
	local last = reset:GetBottom()
	eq(last - m.frame:GetBottom(), 12, 'the menu ends 12 under its last row')
	check(m.content:GetParent() == m.frame, "the body's view is the menu")

	-- The dots again close it; another item's open it on that item.
	click(dots('hotkey'))
	check(not OW:IsMenuShown(), 'the dots again: closed')
	click(dots('hotkey'))
	click(dots('cooldown'))
	check(OW:IsMenuShown(cell('cooldown').widget), "the second's menu")
	eq(m.title:GetText(), 'Cooldown numbers', 'menuTitle as a function')
	eq((select(2, point(m.frame))), dots('cooldown'), 'at its dots')
	eq(M(), m, 'one menu')
	close_all()
end)

test('the menu closes on Esc, a click outside, another pick or tab, and the window closing', function()
	open_items()
	local m = M()
	-- Esc: the window's keys pass it while the menu shows; the menu's take it.
	click(dots('hotkey'))
	check(m.keys:IsShown() and m.keys:IsKeyboardEnabled(), "the menu's keys are on")
	stub.fire_script(frames().keys, 'OnKeyDown', 'ESCAPE')
	eq(frames().keys:GetPropagateKeyboardInput(), true, "the window's keys pass Esc on")
	check(OW:IsShown() and OW:IsMenuShown(), 'nothing closed')
	stub.fire_script(m.keys, 'OnKeyDown', 'A')
	eq(m.keys:GetPropagateKeyboardInput(), true, 'A goes on')
	check(OW:IsMenuShown(), 'A: still open')
	stub.fire_script(m.keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsMenuShown(), 'Esc closes it')
	eq(m.keys:GetPropagateKeyboardInput(), false, 'Esc is kept')
	check(OW:IsShown(), 'the window still shown')
	check(not m.keys:IsKeyboardEnabled(), 'its keys off')
	check(not m.catcher:IsShown(), 'its catcher gone')
	stub.fire_script(frames().keys, 'OnKeyDown', 'ESCAPE')
	eq(frames().keys:GetPropagateKeyboardInput(), false, 'then Esc is the window\'s again')
	check(not OW:IsShown(), 'and closes it')

	-- A click outside.
	open_items()
	click(dots('hotkey'))
	stub.fire_script(m.catcher, 'OnMouseDown', 'LeftButton')
	check(not OW:IsMenuShown(), 'a click outside closes it')

	-- A tab (the one shown too: its item is drawn again), a page, the window.
	click(dots('hotkey'))
	click(tab('texts'))
	check(not OW:IsMenuShown(), 'a tab closes it, the one shown too')
	click(dots('hotkey'))
	click(tab('other'))
	check(not OW:IsMenuShown(), 'another tab closes it')
	click(tab('texts'))
	click(dots('hotkey'))
	OW:Navigate('Loot')
	check(not OW:IsMenuShown(), 'another page closes it')
	OW:Navigate('Items', { tab = 'texts' })
	click(dots('hotkey'))
	st.Config:Close()
	check(not OW:IsMenuShown(), 'closing the window closes it')

	-- Combat.
	open_items()
	click(dots('hotkey'))
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not OW:IsMenuShown(), 'entering combat closes it')
	open_items()
	stub.in_combat = true
	eq(OW:OpenMenu(cell('hotkey').widget), false, 'refused in combat')
	check(not OW:IsMenuShown())
	stub.in_combat = false
	eq(OW:OpenMenu({ row = { option = {}, path = {} } }), false, 'a row with no menu: false')
	close_all()
end)

------------------------------------------------------------------ following

test('the menu follows its item through a redraw, and closes when the item is gone', function()
	open_items()
	click(dots('hotkey'))
	local m = M()
	eq(menuCell('size').widget.edit:GetText(), '10', 'its Size')
	values.size = 15
	OW:Render()
	check(OW:IsMenuShown(), 'still shown')
	eq((select(2, point(m.frame))), dots('hotkey'), "anchored to the redrawn cell's dots")
	eq(m.owner.path[#m.owner.path], 'hotkey')
	eq(menuCell('size').widget.edit:GetText(), '15', 'showing the new value')

	-- Typing in it: the page draws again, the menu keeps its rows and its place.
	local before = menuCell('size')
	menuCell('size').widget.edit:SetFocus()
	OW:Render()
	eq(menuCell('size'), before, 'not drawn again while typed in')
	eq((select(2, point(m.frame))), dots('hotkey'), 'still on its dots')
	menuCell('size').widget.edit:ClearFocus()

	-- A new tree (a profile change): the menu moves onto the new item's menu.
	local oldMenu = m.body.root.menu
	OW:SetRoot(st.Config:GetOptionsTable())
	tick()
	check(OW:IsMenuShown(), 'a new tree: still shown')
	check(m.body.root.menu ~= oldMenu, "drawn from the new tree's item")
	eq(m.body.root.menu, cell('hotkey').row.option.menu, "the redrawn item's menu")
	eq((select(2, point(m.frame))), dots('hotkey'), 'on its dots')

	hideHotkey = true
	OW:Render()
	check(not OW:IsMenuShown(), 'its item gone: closed')
	close_all()
end)

test('a set in the menu draws the page and the menu again', function()
	open_items()
	click(dots('hotkey'))
	local before = OW.GetRenderCount()
	local w = menuCell('size').widget
	w:Commit(12)
	eq(values.size, 12, 'set')
	eq(OW.GetRenderCount(), before + 1, 'the page drawn once again')
	check(OW:IsMenuShown(), 'the menu still shown')
	eq(menuCell('size').widget.edit:GetText(), '12', 'with the value')

	-- A failed validate shows in the window's status line.
	local size = M().body.root.menu.args.size
	size.validate = function() return 'Size: too big' end
	menuCell('size').widget:Commit(19)
	eq(frames().status:GetText(), 'Size: too big', "in the window's status line")
	eq(values.size, 12, 'nothing set')
	size.validate = nil

	-- Mid-drag the menu's own rows follow in place.
	local cellBefore = menuCell('outline')
	local renders = OW.GetRenderCount()
	local slider = menuCell('size').widget
	stub.mouse_buttons.LeftButton = true
	slider.dragging = true
	slider:Commit(14)
	eq(OW.GetRenderCount(), renders, 'no render mid-drag')
	eq(menuCell('outline'), cellBefore, 'the rows kept')
	stub.mouse_buttons.LeftButton = nil
	slider.dragging = nil
	slider:Commit(14)
	eq(OW.GetRenderCount(), renders + 1, 'drawn when let go')

	-- While Blizzard's color picker is open the render waits for it, as the window's does.
	ColorPickerFrame:SetupColorPickerAndShow({ r = 1, g = 0, b = 0, swatchFunc = function() end, cancelFunc = function() end })
	renders = OW.GetRenderCount()
	menuCell('size').widget:Commit(16)
	eq(values.size, 16, 'set')
	eq(OW.GetRenderCount(), renders, 'no render while the picker is open')
	tick()
	eq(OW.GetRenderCount(), renders, 'nor on the next frame')
	ColorPickerFrame:Hide()
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'drawn once it closes')
	eq(menuCell('size').widget.edit:GetText(), '16', 'the menu with it')
	close_all()
end)

test('a dropdown inside the menu opens above it, and closing the list leaves the menu', function()
	open_items()
	click(dots('hotkey'))
	local select = menuCell('outline').widget.frame
	click(select)
	eq(W.ListOwner(), select, "the menu's select owns the list")
	local list = W.GetListFrames()
	eq(list.catcher:GetFrameStrata(), 'TOOLTIP', 'above the menu')
	stub.fire_script(list.catcher, 'OnKeyDown', 'ESCAPE')
	eq(W.ListOwner(), nil, 'Esc closes the list')
	check(OW:IsMenuShown(), 'and leaves the menu')
	click(select)
	stub.fire_script(list.catcher, 'OnMouseDown', 'LeftButton')
	eq(W.ListOwner(), nil, "a click on the list's catcher closes the list")
	check(OW:IsMenuShown(), 'and leaves the menu')

	-- A render while the list is open leaves the menu's rows; a pick draws them again.
	click(select)
	local before = menuCell('outline')
	OW:Render()
	eq(menuCell('outline'), before, 'not drawn again under its list')
	eq(W.ListOwner(), select, 'the list still open')
	click(list.rows[2]) -- Thick
	eq(values.outline, 'thick', 'picked')
	check(OW:IsMenuShown(), 'the menu stays')
	eq(menuCell('outline').widget.text:GetText(), 'Thick', 'showing the pick')

	-- Closing the menu closes its list.
	click(menuCell('outline').widget.frame)
	OW:CloseMenu()
	eq(W.ListOwner(), nil, 'the list goes with the menu')

	-- A confirm from it opens above it; No leaves the menu, Yes runs and draws it again.
	click(dots('hotkey'))
	M().body.root.menu.args.reset.confirm = true
	click(menuCell('reset').widget.frame)
	local confirm = W.GetDialogFrames()
	check(W.ConfirmText() ~= nil, 'the confirm asks')
	eq(confirm.catcher:GetFrameStrata(), 'TOOLTIP', 'above the menu')
	local before = menuCell('reset')
	OW:Render()
	eq(menuCell('reset'), before, 'not drawn again under the confirm')
	stub.fire_script(confirm.catcher, 'OnMouseDown', 'LeftButton')
	eq(W.ConfirmText(), nil, 'a click outside answers No')
	check(OW:IsMenuShown(), 'and leaves the menu')
	eq(resets, 0, 'nothing ran')
	click(menuCell('reset').widget.frame)
	click(confirm.yes)
	eq(resets, 1, 'Yes runs it')
	check(OW:IsMenuShown(), 'the menu stays')
	M().body.root.menu.args.reset.confirm = nil
	close_all()
end)

test('a menu from an item in the small dialog opens over it and closes with it', function()
	open_items()
	OW:OpenDialog('Dialog', { type = 'group', name = 'Dialog', args = { hotkey = HotkeyItem() } })
	local d = OW.GetDialogFrames()
	local item = d.body.cells[1]
	eq(item.row.key, 'hotkey')
	click(item.widget.dots)
	local m = M()
	check(OW:IsMenuShown(), 'open')
	eq(m.owner.body, d.body, "the dialog's body")
	check(m.frame:GetFrameLevel() > d.frame:GetFrameLevel(), "over the dialog")
	-- Esc: the dialog's keys pass it while the menu shows.
	stub.fire_script(d.keys, 'OnKeyDown', 'ESCAPE')
	eq(d.keys:GetPropagateKeyboardInput(), true, "the dialog's keys pass Esc on")
	check(OW:IsDialogShown(), 'the dialog stays')

	OW:Render()
	check(OW:IsMenuShown(), 'a render: still shown')
	eq(m.owner.body, d.body)
	eq((select(2, point(m.frame))), d.body.cells[1].widget.dots, "on the dialog's item")

	-- A set in it draws the dialog again too.
	local itemBefore = d.body.cells[1]
	menuCell('size').widget:Commit(11)
	eq(values.size, 11)
	check(OW:IsMenuShown(), 'still shown')
	check(d.body.cells[1] ~= itemBefore, 'the dialog drawn again')
	eq((select(2, point(m.frame))), d.body.cells[1].widget.dots, 'the menu on its item still')

	OW:CloseDialog()
	check(not OW:IsMenuShown(), 'the dialog closing closes it')

	-- A page item's menu stays when a dialog closes.
	OW:OpenDialog('Dialog', { type = 'group', name = 'Dialog', args = { hotkey = HotkeyItem() } })
	click(dots('hotkey'))
	OW:CloseDialog()
	check(OW:IsMenuShown(), "a page item's menu stays")
	close_all()

	-- The dialog without the window: a set in the menu draws the dialog and the menu.
	fresh()
	OW:OpenDialog('Alone', { type = 'group', name = 'Dialog', args = { hotkey = HotkeyItem() } })
	check(not OW:IsShown(), 'no window')
	click(d.body.cells[1].widget.dots)
	itemBefore = d.body.cells[1]
	local sizeBefore = menuCell('size')
	menuCell('size').widget:Commit(13)
	eq(values.size, 13)
	check(d.body.cells[1] ~= itemBefore, 'the dialog drawn again')
	check(menuCell('size') ~= sizeBefore, 'and the menu')
	eq(menuCell('size').widget.edit:GetText(), '13')
	OW:CloseDialog()
	check(not OW:IsMenuShown())
	close_all()
end)

------------------------------------------------------------------ search

test("search finds a menu's setting and opens the page and the menu", function()
	open_items()
	OW:Navigate('Loot')
	frames().search:SetText('Outline')
	tick(0.3)
	local found
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.menu and c.row.path[#c.row.path] == 'hotkey' then found = c end
	end
	check(found ~= nil, "a result for Hotkey's Outline")
	eq(found.row.name, 'Outline', "named the setting's name")
	click(found.frame)
	eq(OW:GetState().page, 'Items', 'the page shown')
	eq(OW:GetState().tab, 'texts', 'on its tab')
	eq(T.rgb(cell('hotkey').label:GetTextColor()), T.rgb(st.config.profile.colors.text.blue:GetRGB()), 'the item\'s label Text > Blue')
	check(OW:IsMenuShown(cell('hotkey').widget), 'and its menu open')
	close_all()
end)

test("OM.Search: a menu's settings by their name, the item's name, or a tab's; hidden ones left out", function()
	local root = st.Config:GetOptionsTable()
	local function find(text)
		local out = {}
		for _, r in ipairs(OM.Search(root, text)) do
			if r.pageKey == 'Items' then
				out[#out + 1] = r.name .. '@' .. r.path[#r.path] .. (r.menu and '+menu' or '') .. ':' .. tostring(r.sectionTitle)
			end
		end
		return table.concat(out, ',')
	end
	fresh()
	eq(find('Outline'), 'Outline@hotkey+menu:Hotkey,Outline@cooldown+menu:Cooldown', 'by name, under the item')
	eq(find('Hotkey'), 'Hotkey@hotkey:nil,Outline@hotkey+menu:Hotkey,Size@hotkey+menu:Hotkey,Position@hotkey+menu:Hotkey,Reset@hotkey+menu:Hotkey',
		'the item, then its menu by its name')
	local all = OM.Search(root, 'Texts')
	local menus = 0
	for _, r in ipairs(all) do if r.menu then menus = menus + 1 end end
	eq(menus, 8, 'a tab name finds every menu setting under it')
	hideHotkey = true
	eq(find('Outline'), 'Outline@cooldown+menu:Cooldown', 'a hidden item: none of its menu')
	hideHotkey = false
end)

------------------------------------------------------------------ the look

test('Blizzard: the menu drawn as the dialog is, its body without panels', function()
	open_items()
	click(dots('hotkey'))
	local m = M()
	eq(drawn(m.frame), 'theme,solid,panel', 'drawn as the small dialog')
	eq(m.body.metrics, OB.PANELED, 'Thick: panels')
	check(#m.body.pools.panel.used > 0, 'drawn')
	OW:CloseMenu()
	theme('blizzard')
	click(dots('hotkey'))
	eq(m.body.metrics, OB.FLAT, 'Blizzard: flat')
	eq(#m.body.pools.panel.used, 0, 'no panels')
	eq(menuCell('size').frame:GetWidth(), 376, 'a row the whole body')
	theme('thick')
	close_all()
end)
