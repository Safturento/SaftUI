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

local values, pos, resets, tint
hideHotkey = false
disableCooldown = false -- Cooldown's item disabled
showTint = false -- a color in each menu (hidden, so no search or layout counts it, until a case shows it)

local function fresh()
	values = { hotkey = true, outline = 'none', size = 10, plain = true }
	pos = { point = 'TOPRIGHT', rel_point = 'TOPRIGHT', x_off = -3, y_off = -3 }
	tint = { 1, 0, 0 }
	resets = 0
	hideHotkey, disableCooldown, showTint = false, false, false
end
fresh()

-- A text's menu: Outline (a select, disabled from a Size of 18 up), Size (a
-- range), its Position, a centred Reset, and Tint (a color) while showTint.
local function TextMenu(name)
	return {
		type = 'group', name = name,
		get = function(info) return values[info[#info]] end,
		set = function(info, value) values[info[#info]] = value end,
		args = {
			outline = { order = 1, type = 'select', name = 'Outline', desc = 'Its outline.', values = { none = 'None', thick = 'Thick' },
				disabled = function() return values.size >= 18 end },
			size = { order = 2, type = 'range', name = 'Size', desc = 'Its size.', min = 6, max = 20, step = 1 },
			tint = { order = 5, type = 'color', name = 'Tint', desc = 'Its tint.', hidden = function() return not showTint end,
				get = function() return tint[1], tint[2], tint[3] end,
				set = function(_, r, g, b) tint = { r, g, b } end },
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
					disabled = function() return disableCooldown end,
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
	-- As tall as the title and the body. Reset, the closing line, floats 24
	-- under the Position block's panel (Thick), so the menu ends as far under
	-- it: 24, where a last row on a panel has 12.
	eq(menuCell('position').frame:GetBottom() - reset:GetTop(), 24, 'Reset 24 under the panel above it')
	eq(reset:GetBottom() - m.frame:GetBottom(), 24, 'the menu ends 24 under it, as far')
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

------------------------------------------------------------------ fix round 1

test('MenuPlace: inside the screen edge margin; the side that goes less far past; the exact edge', function()
	local function at(...) return table.concat({ OW.MenuPlace(...) }, ',') end
	local margin = { left = 20, right = 20, top = 20, bottom = 20 }
	-- Fitting below by 10, less than a margin of 20: above.
	eq(at({ left = 600, right = 616, top = 338, bottom = 314 }, 400, 300, 1920, 1080), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'no margin: below, 10 to spare')
	eq(at({ left = 600, right = 616, top = 338, bottom = 314 }, 400, 300, 1920, 1080, margin), 'BOTTOMRIGHT,TOPRIGHT,0,4', 'the margin: above')
	-- Right-aligned 10 inside the screen's left, 10 past the margin's: left-aligned.
	eq(at({ left = 394, right = 410, top = 500, bottom = 476 }, 400, 300, 1920, 1080), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'no margin: right-aligned')
	eq(at({ left = 394, right = 410, top = 500, bottom = 476 }, 400, 300, 1920, 1080, margin), 'TOPLEFT,BOTTOMLEFT,0,-4', 'the margin: left-aligned')
	-- Too narrow a screen either way: the side that goes less far past it.
	eq(at({ left = 300, right = 316, top = 500, bottom = 476 }, 400, 300, 500, 1080), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'right-aligned past by 84, left-aligned by 200')
	eq(at({ left = 150, right = 166, top = 500, bottom = 476 }, 400, 300, 500, 1080), 'TOPLEFT,BOTTOMLEFT,0,-4', 'right-aligned past by 234, left-aligned by 50')
	-- At the exact edge: its left on the screen's, right-aligned.
	eq(at({ left = 384, right = 400, top = 500, bottom = 476 }, 400, 300, 1920, 1080), 'TOPRIGHT,BOTTOMRIGHT,0,-4', "its left on the screen's")
end)

test("the menu's place: its dots read in the menu's units, inside the margin it's clamped to", function()
	fresh()
	-- An item drawn at half the menu's scale.
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetScale(0.5)
	content:SetSize(774, 600)
	local root = { page = { type = 'group', name = 'Page', args = { hotkey = HotkeyItem() } } }
	local body = OB.New(content, root, function() end, 774)
	local function at(bottom) -- the dots' bottom, in the menu's units
		content:ClearAllPoints()
		content:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', 1400, 1200)
		body:Release()
		body:Draw(OM.BuildView(root, 'page').sections)
		local dots = body.cells[1].widget.dots
		content:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', 1400, 1200 + (bottom * 2 - dots:GetBottom()))
		eq(math.floor(dots:GetBottom() * dots:GetEffectiveScale() / M().frame:GetEffectiveScale() + 0.5), bottom, 'the dots placed')
		OW:OpenMenu(body.cells[1].widget)
		local p = point(M().frame)
		OW:CloseMenu()
		return p
	end
	content:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', 1400, 1200)
	body:Draw(OM.BuildView(root, 'page').sections)
	OW:OpenMenu(body.cells[1].widget) -- built, for its height
	local height = M().frame:GetHeight()
	OW:CloseMenu()
	check(height > 100, 'a menu of some height')
	local margin = st.config.profile.misc.clamp_inset
	st.config.profile.misc.clamp_inset = 0
	eq(at(height + 4 + 10), 'TOPRIGHT', 'room below, in its units: below')
	-- Read in the dots' own units the bottom would be twice as high, and room below.
	eq(at(math.floor((height + 4) * 0.75)), 'BOTTOMRIGHT', 'no room below in its units: above')
	st.config.profile.misc.clamp_inset = 30
	st:UpdateScreenMargin()
	eq(at(height + 4 + 10), 'BOTTOMRIGHT', 'room below the screen but not the margin: above')
	st.config.profile.misc.clamp_inset = margin
	st:UpdateScreenMargin()
	body:Release()
end)

test("the small dialog opened again, or drawn again by its own set, under its item's menu", function()
	open_items()
	local plain = { type = 'toggle', name = 'Plain', desc = 'Plain.', order = 2,
		get = function() return values.plain end, set = function(_, v) values.plain = v end }
	OW:OpenDialog('D1', { type = 'group', name = 'D', args = { hotkey = HotkeyItem(), plain = plain } })
	local d = OW.GetDialogFrames()
	click(d.body.cells[1].widget.dots)
	check(OW:IsMenuShown(), 'its menu open')
	-- The dialog's own set (one of its rows): drawn again, and the menu with it.
	local before, plainCell = menuCell('size'), nil
	for _, c in ipairs(d.body.cells) do
		if c.row.key == 'plain' then plainCell = c end
	end
	plainCell.widget:Commit(false)
	eq(values.plain, false, 'set')
	check(OW:IsMenuShown(), 'the menu stays')
	check(menuCell('size') ~= before, 'drawn again with the dialog')
	eq((select(2, point(M().frame))), d.body.cells[1].widget.dots, "on its item's dots")
	eq(M().owner.body, d.body)

	-- Opened again on other options: the menu goes, never left on the new item.
	OW:OpenDialog('D2', { type = 'group', name = 'D2', args = { hotkey = { order = 1, type = 'item', name = 'Other', desc = 'Other.', size = 'small',
		get = function() return true end, set = function() end,
		menu = { type = 'group', name = 'Other', args = {
			other = { type = 'toggle', name = 'Other toggle', desc = 'Other.', get = function() return true end, set = function() end },
		} } } } })
	check(not OW:IsMenuShown(), 'closed')
	eq(#M().body.cells, 0, 'its rows released')
	eq(d.body.cells[1].row.name, 'Other', 'the dialog shows the new options')

	-- A page item's menu stays when the dialog opens again.
	click(dots('hotkey'))
	OW:OpenDialog('D3', { type = 'group', name = 'D3', args = { hotkey = HotkeyItem() } })
	check(OW:IsMenuShown(cell('hotkey').widget), "a page item's menu stays")
	close_all()
end)

test("a disabled item's menu doesn't open, from its dots or from search", function()
	open_items()
	disableCooldown = true
	OW:Render()
	local w = cell('cooldown').widget
	check(w.disabled, 'Cooldown disabled')
	eq(OW:OpenMenu(w), false, 'OpenMenu refuses it')
	check(not OW:IsMenuShown())
	eq(OW:OpenMenu({ row = cell('hotkey').row, dots = dots('hotkey') }), false, 'a widget no body drew: false')
	OW:Navigate('Loot')
	frames().search:SetText('Outline')
	tick(0.3)
	local found
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.menu and c.row.path[#c.row.path] == 'cooldown' then found = c end
	end
	check(found ~= nil, "Cooldown's Outline is found")
	click(found.frame)
	eq(OW:GetState().page, 'Items', 'the page opens')
	eq(T.rgb(cell('cooldown').label:GetTextColor()), T.rgb(st.config.profile.colors.text.blue:GetRGB()), 'the item marked blue')
	check(not OW:IsMenuShown(), 'its menu stays shut')
	close_all()
end)

test("a click outside while the color picker is open is the picker's: the menu stays, and Cancel puts the color back", function()
	open_items()
	showTint = true
	click(dots('hotkey'))
	local c = menuCell('tint')
	check(c ~= nil, 'a color in the menu')
	click(c.widget.frame)
	check(ColorPickerFrame:IsShown(), 'the picker opens')
	stub.pick_color(0, 1, 0)
	eq(table.concat(tint, ','), '0,1,0', 'a pick is set')
	stub.fire_script(M().catcher, 'OnMouseDown', 'LeftButton')
	check(OW:IsMenuShown(), 'the menu stays under the picker')
	stub.color_picker_cancel()
	eq(table.concat(tint, ','), '1,0,0', 'Cancel puts the color back')
	check(not ColorPickerFrame:IsShown(), 'the picker gone')
	tick()
	stub.fire_script(M().catcher, 'OnMouseDown', 'LeftButton')
	check(not OW:IsMenuShown(), 'then a click outside closes it')
	close_all()
end)

test('the mouse wheel stops at the menu and its catcher', function()
	open_items()
	click(dots('hotkey'))
	local m = M()
	for name, f in pairs({ catcher = m.catcher, menu = m.frame }) do
		check(f:IsMouseWheelEnabled(), name .. ' takes the wheel')
		check(f:GetScript('OnMouseWheel') ~= nil, name .. ' has a wheel script')
		stub.fire_script(f, 'OnMouseWheel', -1)
	end
	check(OW:IsMenuShown(), 'nothing closed')
	eq((select(2, point(m.frame))), dots('hotkey'), 'still on its dots')
	close_all()
end)

test("the menu's title takes Text > Grey on each draw", function()
	open_items()
	click(dots('hotkey'))
	local grey = st.config.profile.colors.text.grey
	local r, g, b = grey.r, grey.g, grey.b
	grey.r, grey.g, grey.b = 0.2, 0.4, 0.6
	OW:Render()
	eq(T.rgb(M().title:GetTextColor()), '0.20,0.40,0.60', 'a changed grey')
	grey.r, grey.g, grey.b = r, g, b
	OW:Render()
	eq(T.rgb(M().title:GetTextColor()), T.rgb(r, g, b), 'and back')
	close_all()
end)

test("a failed validate in the menu draws nothing again, and shows where its item is: the window's status line, or the dialog's", function()
	open_items()
	click(dots('hotkey'))
	local size = M().body.root.menu.args.size
	size.validate = function() return 'Size: too big' end
	local renders, before = OW.GetRenderCount(), menuCell('size')
	menuCell('size').widget:Commit(19)
	eq(frames().status:GetText(), 'Size: too big', "in the window's status line")
	eq(OW.GetRenderCount(), renders, 'no render')
	eq(menuCell('size'), before, 'the menu not drawn again')
	size.validate = nil
	menuCell('size').widget:Commit(12)
	eq(frames().status:GetText(), '', 'a good set clears it')
	OW:CloseMenu()

	-- An item in the dialog: the dialog's status line, which is over the window's.
	OW:OpenDialog('Dialog', { type = 'group', name = 'Dialog', args = { hotkey = HotkeyItem() } })
	local d = OW.GetDialogFrames()
	click(d.body.cells[1].widget.dots)
	size = M().body.root.menu.args.size
	size.validate = function() return 'Size: too big' end
	menuCell('size').widget:Commit(19)
	eq(d.status:GetText(), 'Size: too big', "in the dialog's status line")
	eq(frames().status:GetText(), '', "not the window's, behind it")
	size.validate = nil
	menuCell('size').widget:Commit(12)
	eq(d.status:GetText(), '', 'a good set clears it')
	close_all()
end)

test('closing the menu releases its rows and takes a confirm still open from it', function()
	open_items()
	click(dots('hotkey'))
	check(#M().body.cells > 0, 'rows drawn')
	OW:CloseMenu()
	eq(#M().body.cells, 0, 'its rows released')
	eq(#M().body.pools.row.used, 0, 'every row frame back in its pool')
	click(dots('hotkey'))
	M().body.root.menu.args.reset.confirm = true
	click(menuCell('reset').widget.frame)
	check(W.ConfirmText() ~= nil, 'a confirm from it')
	OW:CloseMenu()
	eq(W.ConfirmText(), nil, 'gone with the menu')
	eq(resets, 0, 'nothing ran')
	close_all()
end)

test('a drag in the menu: another of its rows follows it, and a render meanwhile leaves its rows', function()
	open_items()
	click(dots('hotkey'))
	local outline, slider = menuCell('outline'), menuCell('size').widget
	check(not outline.widget.disabled, 'Outline enabled at 10')
	stub.mouse_buttons.LeftButton = true
	slider.dragging = true
	slider:Commit(18)
	check(outline.widget.disabled, 'Outline follows the drag: disabled at 18')
	eq(T.rgb(outline.label:GetTextColor()), T.rgb(st.config.profile.colors.text.grey:GetRGB()), 'its label grey')
	OW:Render() -- a render from elsewhere (a ConfigTableChange)
	eq(menuCell('outline'), outline, 'its rows kept under the held slider')
	eq(menuCell('size').widget, slider, 'the slider not taken from under the mouse')
	stub.mouse_buttons.LeftButton = nil
	slider.dragging = nil
	slider:Commit(18)
	check(menuCell('outline') ~= outline, 'drawn again once let go')
	check(menuCell('outline').widget.disabled, 'Outline still disabled')
	close_all()
end)

test("going to the item's own page and tab closes its menu; a result for the item's own row opens the page, not the menu", function()
	open_items()
	click(dots('hotkey'))
	OW:Navigate('Items', { tab = 'texts' })
	check(not OW:IsMenuShown(), "the item's own page and tab: closed")
	OW:Navigate('Loot')
	frames().search:SetText('Hotkey')
	tick(0.3)
	local own
	for _, c in ipairs(OW.GetDrawnRows()) do
		if not c.row.menu and c.row.path[#c.row.path] == 'hotkey' then own = c end
	end
	check(own ~= nil, "a result for Hotkey's own row")
	click(own.frame)
	eq(OW:GetState().page, 'Items', 'its page')
	eq(T.rgb(cell('hotkey').label:GetTextColor()), T.rgb(st.config.profile.colors.text.blue:GetRGB()), 'the item marked blue')
	check(not OW:IsMenuShown(), 'its menu shut')
	close_all()
end)

test("OM.Search in menus: a footer item's results keep footer; no description, no menu that isn't a group; the cap", function()
	local function toggle(name, order) return { type = 'toggle', name = name, desc = name .. '.', order = order } end
	local function item(menu) return { type = 'item', name = 'It', desc = 'It.', order = 1, menu = menu } end
	local root = {
		Pg = { type = 'group', name = 'Pg', args = {
			it = item({ type = 'group', name = 'It', args = {
				words = { type = 'description', name = 'Outline words', order = 1 },
				outline = toggle('Outline', 2),
			} }),
			loose = { type = 'item', name = 'Loose', desc = 'Loose.', order = 2, menu = { args = { outline = toggle('Outline', 1) } } },
		}, footer = { type = 'group', name = 'Foot', args = {
			fit = item({ type = 'group', name = 'It', args = { outline = toggle('Outline', 1) } }),
		} } },
	}
	local out = {}
	for _, r in ipairs(OM.Search(root, 'Outline')) do
		out[#out + 1] = r.name .. '@' .. table.concat(r.path, '.') .. (r.menu and '+menu' or '') .. (r.footer and '+footer' or '')
	end
	eq(table.concat(out, ','), 'Outline@Pg.it+menu,Outline@Pg.fit+menu+footer',
		"the page's item's, then the footer's with footer; no description, no menu that isn't a group")
	local many = {}
	for i = 1, 150 do many['x' .. i] = toggle('Many ' .. i, i) end
	local big = { Pg = { type = 'group', name = 'Pg', args = { it = item({ type = 'group', name = 'It', args = many }) } } }
	eq(#OM.Search(big, 'Many'), 100, 'at most 100, in a menu too')
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
	eq(menuCell('reset').frame:GetBottom() - m.frame:GetBottom(), 12, 'nothing floats: the menu ends 12 under its last row')
	eq(menuCell('size').frame:GetWidth(), 376, 'a row the whole body')
	theme('thick')
	close_all()
end)

------------------------------------------------------------------ whole pixels

-- As the small dialog (options_small_dialog_test.lua's whole pixels): the
-- menu, placed by a corner on its item's dots, and everything in it on whole
-- pixels, from the window's page and from the small dialog (whose height is
-- as often odd as even), below its dots or above them, and with the game's
-- read-back hair (stub.size_noise) either way, which made its floating Reset
-- 27 tall for a 26 button and set the button half a unit down it.
local P = load_test_file('lib/pixels.lua')

test('the menu and everything in it sit on whole pixels, from the page or the small dialog, below or above its dots', function()
	local function on(value) return { get = function() return value end, set = function() end } end
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		for _, noise in ipairs({ 0, 2 ^ -14, -2 ^ -14 }) do
			stub.size_noise = noise
			-- The window centred (the menu below the dots), and low on the screen (above them).
			for _, low in ipairs({ false, true }) do
				st.config.global.optionsWindow = low and { point = 'CENTER', x = 0, y = -300 } or nil
				local where = ('%s, noise %s%s'):format(look, noise, low and ', the window low' or '')
				open_items()
				click(dots('hotkey'))
				check(OW:IsMenuShown(), where .. ': open')
				local off = P.off(M().frame)
				eq(#off, 0, where .. ', from the page: ' .. P.report(off))
				OW:CloseMenu()
				for count = 0, 3 do
					local args = { hotkey = HotkeyItem() }
					for i = 1, count do
						local t = on(true)
						t.order, t.type, t.name = 1 + i, 'toggle', 'Toggle ' .. i
						args['t' .. i] = t
					end
					OW:OpenDialog('Dialog', { type = 'group', name = 'Dialog', args = args })
					click(OW.GetDialogFrames().body.cells[1].widget.dots)
					check(OW:IsMenuShown(), where .. ', ' .. count .. ' toggles: open')
					off = P.off(M().frame)
					eq(#off, 0, where .. ', from the dialog with ' .. count .. ' toggles: ' .. P.report(off))
					OW:CloseDialog()
				end
				close_all()
			end
		end
	end
	stub.size_noise = 0
	st.config.global.optionsWindow = nil
	theme('thick')
end)
