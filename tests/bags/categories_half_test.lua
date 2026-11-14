-- The Categories tab at half width (SaftUI-Bags/categoriestab.lua): under 774
-- wide the category list is a menu on a button over the editor, which takes the
-- whole width. The button names the category and its place, two icon buttons
-- step through the list, and the menu holds the list's own rows, counts, handles,
-- ghost and drop line, with + New category and Reset all at its foot.
--
-- Real: the Categories tab's world (categories_world.lua: the views world on
-- Core's real config and the options window, with SaftUI-Bags' options.lua,
-- dragparts.lua, ruleeditor.lua and categoriestab.lua). Played by firing
-- scripts: the window renders on its ticker's OnUpdate and a drag draws on its
-- frame's, which the stubs never run by themselves; a held mouse button is
-- stub.mouse_buttons.LeftButton.
local CW = load_test_file('bags/categories_world.lua')
local P = load_test_file('lib/pixels.lua')
local st, INV, B, OW, OM, W, R

local function world(client)
	local container
	container, st, INV, B, OW, OM, W, R = CW.world(client)
	return container
end
local open, half, tab, row_of, ids, wheel = CW.open, CW.half, CW.tab, CW.row_of, CW.ids, CW.wheel
local click, tick, yes, cursor_on, drag_frame = CW.click, CW.tick, CW.yes, CW.cursor_on, CW.drag_frame
local SELL, MISC = CW.SELL, CW.MISC

-- The tip a kit button gives, as 'title | line | red:line'.
local function tip_text(button)
	local title, lines = button.tip(button)
	local out = { title }
	for _, line in ipairs(lines or {}) do
		out[#out + 1] = type(line) == 'table' and ((line.red and 'red:' or '') .. line.text) or line
	end
	return table.concat(out, ' | ')
end

-- The place of a category in the list, 1 first.
local function place_of(id)
	for i, entry in ipairs(INV:GetCategoryList()) do
		if entry.id == id then return i end
	end
end

local function closed() return not tab().menu:IsShown() end

-- A handle held down, the cursor moved onto a frame's half and let go.
local function drag(handle, onto, lower)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	if onto then cursor_on(onto, lower) else stub.cursor_x, stub.cursor_y = 0, 0 end
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
end

local function look(name)
	st.config.profile.theme.name = name
	st:ThemeChanged()
end

------------------------------------------------------------------ the layout

test('at half the list is a button over the editor naming the category and its place; the editor takes the width', function()
	world()
	open(); half()
	local w = tab()
	local list = INV:GetCategoryList()
	check(w.compact, 'compact at 388')
	eq(w.menuButton.text:GetText(), list[1].name)
	eq(w.menuButton.place:GetText(), '1 of ' .. #list)
	eq(w.menuButton.icon:GetTexture(), st.icons.list)
	eq(w.menuButton:GetWidth(), 260)
	eq(w.menuButton:GetHeight(), W.FIELD_HEIGHT)
	eq(w.prevButton:GetLeft(), w.menuButton:GetRight() + 6)
	eq(w.nextButton:GetLeft(), w.prevButton:GetRight() + 6)
	eq(w.prevButton:GetWidth() .. 'x' .. w.prevButton:GetHeight(), '24x24')
	eq(w.prevButton.icon:GetTexture(), st.icons.chevronLeft)
	eq(w.nextButton.icon:GetTexture(), st.icons.chevronRight)
	eq(w.prevButton.icon:GetWidth(), 16)
	check(not w.listPane:IsVisible(), 'the list is in the closed menu')
	check(not w.menu:IsShown(), 'closed')
	check(not w.divider:IsShown(), 'no divider')
	eq(w.editorScroll:GetLeft(), w.frame:GetLeft(), 'the editor at the left')
	eq(w.editorScroll:GetWidth(), 388, 'the whole width')
	eq(w.editorScroll:GetTop(), w.frame:GetTop() - 34, 'under the button line')
	eq(w.body.width, 388, 'the body is as wide')
	check(w.body.half, 'and one column')
	eq(w.footerBody.width, 388)
	eq(w.frame:GetWidth(), 388)
	check(w.menuButton:GetBottom() > w.editorScroll:GetTop(), 'the button is above the editor')

	-- Back at full: the list beside the editor, as before.
	OW:SetWindowSize('full'); stub.time = stub.time + 1
	w = tab()
	check(not w.compact, 'not compact at 774')
	eq(w.listPane:GetParent(), w.frame, 'the list is in the tab')
	check(w.listPane:IsVisible(), 'and shows')
	check(not w.menuButton:IsShown() and not w.prevButton:IsShown() and not w.nextButton:IsShown(), 'no button')
	eq(w.editorScroll:GetLeft(), w.frame:GetLeft() + 234, 'the editor at 234')
	eq(w.editorScroll:GetWidth(), 540)
	eq(w.body.width, 540)
	check(not w.body.half, 'two columns again')
	eq(w.editorScroll:GetTop(), w.frame:GetTop(), 'at the top')
	check(w.divider:IsShown(), 'the divider is back')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the tab changes layout as the window does and keeps its category, its scroll and its place', function()
	world()
	open()
	local w = tab()
	INV.categoryEditor.selected = 'Toys'
	OW:Render()
	w = tab()
	wheel(w.listScroll, -1, 3)
	local offset = w.listScroll:GetVerticalScroll()
	check(offset > 0, 'the list is scrolled')
	half()
	w = tab()
	eq(INV.categoryEditor.selected, 'Toys', 'half: the same category')
	eq(w.menuButton.text:GetText(), 'Toys')
	eq(w.menuButton.place:GetText(), place_of('Toys') .. ' of ' .. #INV:GetCategoryList())
	eq(INV.categoryEditor.listOffset, offset, 'the list kept its scroll')
	OW:SetWindowSize('full'); stub.time = stub.time + 1
	w = tab()
	eq(INV.categoryEditor.selected, 'Toys', 'full: the same')
	eq(w.listScroll:GetVerticalScroll(), offset, 'and its scroll')
	eq(w.row.key, 'categories')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a rule edit in progress survives the window changing size as a redraw does', function()
	world()
	INV.categoryEditor.selected = SELL
	open()
	local w = tab()
	local rule = w:EditorCell('rule')
	check(rule ~= nil, 'the rule is drawn')
	half()
	w = tab()
	check(w:EditorCell('rule') ~= nil, 'half: the rule is drawn')
	eq(INV.categoryEditor.selected, SELL, 'the same category')
	eq(w.editorScroll:GetWidth(), 388)
	OW:SetWindowSize('full'); stub.time = stub.time + 1
	eq(tab():EditorCell('rule') ~= nil, true, 'and at full')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ the menu

test('the button opens the list as a menu: the same rows and counts; a pick closes it and edits that category', function()
	world()
	open(); half()
	local w = tab()
	local list = INV:GetCategoryList()
	click(w.menuButton)
	check(w.menu:IsShown(), 'the menu shows')
	check(INV.categoryEditor.menuOpen, 'and says so')
	eq(w.menu:GetWidth(), 234)
	eq(w.menu:GetTop(), w.menuButton:GetBottom() - 4, '4 under the button')
	eq(w.menu:GetLeft(), w.menuButton:GetLeft(), 'at its left')
	eq(w.menu:GetFrameStrata(), 'FULLSCREEN_DIALOG')
	eq(w.menu:GetFrameLevel(), 410)
	eq(w.menu.catcher:GetFrameLevel(), 400)
	check(w.menu.catcher:IsShown(), 'with a catcher')
	eq(w.menu.caption:GetText(), 'Categories: drag to reorder')
	check(w.listPane:IsVisible(), 'the list shows')
	eq(w.listPane:GetParent(), w.menu, 'in the menu')
	eq(#w.rows, #list, 'a row for every category')
	eq(row_of(w, 'Consumables').count:GetText(), '1', 'with its count')
	eq(row_of(w, SELL).count:GetText(), '1')
	check(not row_of(w, MISC).handle:IsShown(), 'Miscellaneous has no handle')
	check(row_of(w, 'Armor').handle:IsShown(), 'the others do')
	check(w.rows[1].tint:IsShown(), 'the selected row is tinted')
	eq(w.listScroll:GetHeight(), 14 * 22, 'its view is 14 rows')
	check(#w.rows > 14, 'there are more rows than that')
	check(w.addButton:IsVisible() and w.resetButton:IsVisible(), '+ New category and Reset all in it')
	check(w.addButton:GetBottom() > w.menu:GetBottom(), 'inside it')
	check(w.resetButton:GetBottom() > w.menu:GetBottom())

	click(w.rows[3].frame)
	eq(INV.categoryEditor.selected, list[3].id, 'the row is the category edited')
	check(not INV.categoryEditor.menuOpen, 'the menu is closed')
	w = tab()
	check(closed(), 'and hidden')
	check(not w.menu.catcher:IsShown(), 'its catcher too')
	eq(w.menuButton.text:GetText(), list[3].name)
	eq(w.menuButton.place:GetText(), '3 of ' .. #list)
	eq(w.listPane:GetParent(), w.menu, 'the list waits in the menu')

	-- The row already edited closes it too.
	click(w.menuButton)
	click(w.rows[3].frame)
	check(closed(), 'a pick of the edited row closes it')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the menu closes on + New category, a click outside, Esc, and the window leaving half; the face opens and closes it', function()
	world()
	open(); half()
	local w = tab()
	local count = #INV:GetCategoryList()
	-- + New category
	click(w.menuButton)
	click(w.addButton)
	w = tab()
	check(closed(), '+ New category closes it')
	eq(#INV:GetCategoryList(), count + 1, 'and adds one')
	eq(w.menuButton.place:GetText(), place_of(INV.categoryEditor.selected) .. ' of ' .. (count + 1), 'the new one is edited')
	-- a click outside
	click(w.menuButton)
	stub.fire_script(w.menu.catcher, 'OnMouseDown', 'LeftButton')
	check(closed() and not INV.categoryEditor.menuOpen, 'a click outside closes it')
	check(not w.menu.catcher:IsShown(), 'with its catcher')
	-- Esc, and keys that are not Esc go on to the game
	click(w.menuButton)
	stub.fire_script(w.menu.catcher, 'OnKeyDown', 'A')
	check(w.menu:IsShown(), 'another key leaves it')
	stub.fire_script(w.menu.catcher, 'OnKeyDown', 'ESCAPE')
	check(closed(), 'Esc closes it')
	check(OW:IsShown(), 'and not the window')
	-- the face again
	click(w.menuButton)
	check(w.menu:IsShown(), 'opened')
	click(w.menuButton)
	check(closed(), 'the face closes it too')
	-- leaving half
	click(w.menuButton)
	OW:SetWindowSize('full'); stub.time = stub.time + 1
	check(closed() and not INV.categoryEditor.menuOpen, 'growing to full closes it')
	w = tab()
	eq(w.listPane:GetParent(), w.frame, 'the list is beside the editor')
	OW:SetWindowSize('half'); stub.time = stub.time + 1
	check(closed(), 'and it stays closed when back at half')
	-- the bar
	click(tab().menuButton)
	check(tab().menu:IsShown())
	check(OW:SetWindowSize('mini'), 'the bar')
	stub.time = stub.time + 1
	check(not INV.categoryEditor.menuOpen, 'the bar closes it')
	OW:SetWindowSize('half'); stub.time = stub.time + 1
	check(closed(), 'closed back at half')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the menu closes with the window, and with a page of another tab', function()
	world()
	open(); half()
	click(tab().menuButton)
	check(tab().menu:IsShown())
	st.Config:Close()
	check(not OW:IsShown(), 'the window closed')
	check(not INV.categoryEditor.menuOpen, 'and with it the menu')
	open()
	eq(OW:GetWindowSize(), 'half', 'reopened at half')
	check(closed(), 'the menu is closed')
	click(tab().menuButton)
	st.Config:Open('Inventory', 'bag') -- another tab of the page
	st.Config:Open('Inventory', 'categories')
	check(closed(), 'back on the tab it is closed')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the menu stays open through a drop, Reset all, a bag update and a redraw', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	local before = ids()
	-- a drop
	drag(row_of(w, 'Armor').handle, w.rows[2].frame, false)
	check(ids() ~= before, 'the drop moved a category')
	tick()
	w = tab()
	check(w.menu:IsShown(), 'a drop leaves it open')
	check(w.listPane:IsVisible(), 'with its list')
	check(INV.categoryEditor.menuOpen)
	-- Reset all
	click(w.resetButton)
	yes()
	tick()
	w = tab()
	check(w.menu:IsShown(), 'Reset all leaves it open')
	eq(ids(), before, 'the order is the default again')
	-- a bag update
	B.put(0, 7, B.item(102, 'Elixir', 'Consumable', 30))
	INV:QueueUpdate(true)
	INV:UpdateHandler()
	tick(); tick()
	w = tab()
	check(w.menu:IsShown(), 'a bag update leaves it open')
	eq(row_of(w, 'Consumables').count:GetText(), '2', 'with the new count')
	OW:Render()
	check(tab().menu:IsShown(), 'a redraw leaves it open')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('previous and next step through the categories, each disabled at its end', function()
	world()
	open(); half()
	local list = INV:GetCategoryList()
	local w = tab()
	check(w.prevButton.disabled, 'no previous at the first')
	eq(tip_text(w.prevButton), 'Previous category | red:This is the first category.')
	eq(tip_text(w.nextButton), 'Next category')
	check(not w.nextButton.disabled)
	click(w.prevButton)
	eq(INV.categoryEditor.selected, list[1].id, 'a disabled button does nothing')
	stub.fire_script(w.prevButton, 'OnEnter', true)
	eq(stub.state(GameTooltip).texts[1], 'Previous category', 'its tooltip shows')
	stub.fire_script(w.prevButton, 'OnLeave', true)
	click(w.nextButton)
	w = tab()
	eq(INV.categoryEditor.selected, list[2].id, 'next is the second')
	eq(w.menuButton.text:GetText(), list[2].name)
	eq(w.menuButton.place:GetText(), '2 of ' .. #list)
	check(not w.prevButton.disabled, 'previous is on now')
	eq(tip_text(w.prevButton), 'Previous category')
	click(w.prevButton)
	eq(INV.categoryEditor.selected, list[1].id, 'previous is the first again')
	-- Walk to the end: every row counts, Miscellaneous last.
	for _ = 2, #list do click(tab().nextButton) end
	w = tab()
	eq(INV.categoryEditor.selected, MISC, 'the last is Miscellaneous')
	eq(w.menuButton.place:GetText(), #list .. ' of ' .. #list)
	check(w.nextButton.disabled, 'no next at the last')
	eq(tip_text(w.nextButton), 'Next category | red:This is the last category.')
	click(w.nextButton)
	eq(INV.categoryEditor.selected, MISC, 'not wrapping round')
	-- The list shows the selected row when the menu opens.
	click(w.menuButton)
	local row = row_of(w, MISC)
	check(CW.in_view(w, row), 'the selected row is in view')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ the drag in the menu

test('dragging in the menu reorders as the list does, and scrolls it at an edge; the menu stays open after the drop', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	local list = INV:GetCategoryList()
	local want = { list[1].id, list[4].id, list[2].id, list[3].id }
	for i = 5, #list do want[i] = list[i].id end
	-- Row 4 onto the upper half of row 2.
	local handle = w.rows[4].handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	check(w.drag ~= nil, 'a drag starts on the handle')
	check(w.ghost:IsShown(), 'with a ghost')
	eq(w.ghost.text:GetText(), list[4].name)
	cursor_on(w.rows[2].frame, false)
	drag_frame(w)
	check(w.insert:IsShown(), 'the drop line shows')
	check(w.insert:GetTop() > w.rows[2].frame:GetTop() - 3, 'at the top of row 2')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(ids(), table.concat(want, ','), 'moved as at full')
	tick()
	w = tab()
	check(w.menu:IsShown(), 'the menu is open after the drop')
	check(w.listPane:IsVisible(), 'with the list')
	eq(row_of(w, list[4].id).frame:GetTop() < row_of(w, list[2].id).frame:GetTop(), false, 'the moved row is above')

	-- A drag held at the menu's bottom scrolls it.
	handle = w.rows[1].handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	local scroll = w.listScroll
	local scale = scroll:GetEffectiveScale()
	stub.cursor_x = (scroll:GetLeft() + 30) * scale
	stub.cursor_y = (scroll:GetBottom() + 2) * scale
	local from = INV.categoryEditor.listOffset
	drag_frame(w, 0.5)
	check(INV.categoryEditor.listOffset > from, 'the list scrolled down')
	stub.cursor_y = (scroll:GetTop() - 2) * scale
	local at = INV.categoryEditor.listOffset
	drag_frame(w, 0.1)
	check(INV.categoryEditor.listOffset < at, 'and up at the top')
	stub.mouse_buttons.LeftButton = nil
	stub.cursor_x, stub.cursor_y = 0, 0
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	check(w.drag == nil, 'the drag is over')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a drag in the menu that ends with the menu closing moves nothing', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	local order = ids()
	local handle = w.rows[4].handle

	-- Esc
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	check(w.drag ~= nil, 'a drag is on')
	cursor_on(w.rows[2].frame, false)
	local renders = OW.GetRenderCount()
	stub.fire_script(w.menu.catcher, 'OnKeyDown', 'ESCAPE')
	check(OW.GetRenderCount() > renders, 'the window, which waited for the drag, draws again')
	w = tab()
	check(closed(), 'Esc closed the menu')
	check(w.drag == nil, 'no drag')
	check(not (w.ghost and w.ghost:IsShown()), 'no ghost')
	check(not w.insert:IsShown(), 'no drop line')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(ids(), order, 'nothing moved')
	tick()

	-- The window closing (combat).
	click(w.menuButton)
	handle = tab().rows[4].handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	w = tab()
	check(w.drag ~= nil, 'a drag is on again')
	cursor_on(w.rows[2].frame, false)
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	stub.in_combat = false
	stub.mouse_buttons.LeftButton = nil
	check(not OW:IsShown(), 'combat closed the window')
	check(w.drag == nil and not w.ghost:IsShown(), 'the drag ended, its ghost hidden')
	eq(ids(), order, 'nothing moved')
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(ids(), order, 'still nothing')
	open()
	eq(OW:GetWindowSize(), 'half', 'open at half again')
	check(closed(), 'the menu is closed')

	-- The window leaving half.
	click(tab().menuButton)
	w = tab()
	handle = w.rows[4].handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	cursor_on(w.rows[2].frame, false)
	check(OW:SetWindowSize('full'), 'grow')
	stub.time = stub.time + 1
	stub.mouse_buttons.LeftButton = nil
	check(w.drag == nil, 'the drag is over')
	eq(ids(), order, 'nothing moved')
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(ids(), order, 'still nothing')
	OW:SetWindowSize('half'); stub.time = stub.time + 1

	-- A bag update waits for the mouse, as at full.
	click(tab().menuButton)
	w = tab()
	handle = w.rows[4].handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	renders = OW.GetRenderCount()
	B.put(0, 7, B.item(102, 'Elixir', 'Consumable', 30))
	INV:QueueUpdate(true)
	INV:UpdateHandler()
	tick(); tick()
	eq(OW.GetRenderCount(), renders, 'nothing drawn while the mouse is held')
	check(w.drag ~= nil and tab() == w, 'the drag goes on')
	check(w.menu:IsShown(), 'in the open menu')
	stub.mouse_buttons.LeftButton = nil
	stub.cursor_x, stub.cursor_y = 0, 0
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	tick()
	check(tab().menu:IsShown(), 'the menu is still open')
	eq(ids(), order, 'nothing moved')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the menu opens on the selected row: the list is scrolled to it', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	wheel(w.listScroll, -1, 50)
	check(not CW.in_view(w, w.rows[1]), 'the first row is scrolled out')
	click(w.menuButton)
	click(w.menuButton)
	check(CW.in_view(w, w.rows[1]), 'the edited category shows when it opens again')
	eq(INV.categoryEditor.listOffset, 0, 'at the top')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the bound tab changes layout live when it is given another width', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	check(w.menu:IsShown())
	w:SetWidth(774)
	check(not w.compact, 'not compact at 774')
	check(not w.menu:IsShown() and not INV.categoryEditor.menuOpen, 'the menu closed')
	eq(w.listPane:GetParent(), w.frame, 'the list in the tab')
	eq(w.editorScroll:GetLeft(), w.frame:GetLeft() + 234)
	eq(w.body.width, 540)
	w:SetWidth(388)
	check(w.compact, 'compact again at 388')
	eq(w.listPane:GetParent(), w.menu, 'the list in the menu')
	eq(w.editorScroll:GetLeft(), w.frame:GetLeft())
	eq(w.body.width, 388)
	check(closed(), 'still closed')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the button holds the icon, the name and the place apart, under every look and as the mouse comes and goes', function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		world()
		look(name)
		INV:RenameCategory('Toys', 'A category with a very long name that cannot fit the button at all')
		INV.categoryEditor.selected = 'Toys'
		open(); half()
		local face = tab().menuButton
		local function apart(where)
			check(face.icon:GetRight() <= face.text:GetLeft(), name .. ' ' .. where .. ': the name after the icon')
			eq(face.text:GetLeft(), face.icon:GetRight() + 6, name .. ' ' .. where .. ': 6 after it')
			eq(face.text:GetRight() + 6, face.place:GetLeft(), name .. ' ' .. where .. ': the place 6 after the name')
			eq(face.place:GetRight(), face:GetRight() - 26, name .. ' ' .. where .. ': 6 before the caret')
			eq(face.text:GetJustifyH(), 'LEFT', name .. ' ' .. where .. ': the name at the left')
			eq(face.icon:GetLeft(), face:GetLeft() + 8, name .. ' ' .. where .. ': the icon 8 in')
		end
		apart('at rest')
		stub.fire_script(face, 'OnEnter', true)
		apart('hovered')
		stub.fire_script(face, 'OnMouseDown', 'LeftButton')
		apart('pressed')
		stub.fire_script(face, 'OnMouseUp', 'LeftButton')
		stub.fire_script(face, 'OnLeave', true)
		apart('left')
		eq(stub.state(GameTooltip) ~= nil, true)
		eq(face.tip(face), 'Categories')
		eq(select(2, face.tip(face))[1], 'Opens the list: pick one to edit, or drag one to reorder.')
		click(face)
		look(name)
		apart('with the menu open')
		eq(#take_errors(), 0, 'no errors')
		look('thick')
		st.Config:Close()
	end
end)

------------------------------------------------------------------ Edit category

test('EditCategory from the bar, or at half with the menu open, shows the category in the button', function()
	world()
	open(); half()
	check(OW:SetWindowSize('mini'), 'the bar')
	stub.time = stub.time + 1
	INV:EditCategory('Trade Goods')
	eq(OW:GetWindowSize(), 'half', 'it opens the window at half')
	eq(OW:GetState().tab, 'categories', 'on the Categories tab')
	local w = tab()
	eq(w.menuButton.text:GetText(), 'Trade Goods', 'the button names the category')
	eq(w.menuButton.place:GetText(), place_of('Trade Goods') .. ' of ' .. #INV:GetCategoryList())
	check(closed(), 'the menu is closed')
	check(w:EditorCell('name') ~= nil, 'and its editor shows')
	eq(w:EditorCell('name').widget.frame:GetText(), 'Trade Goods')

	-- With the menu open at half: another category, the menu closed.
	click(w.menuButton)
	check(tab().menu:IsShown())
	INV:EditCategory('Armor')
	w = tab()
	check(closed(), 'EditCategory closes the menu')
	check(not INV.categoryEditor.menuOpen)
	eq(w.menuButton.text:GetText(), 'Armor')
	eq(w:EditorCell('name').widget.frame:GetText(), 'Armor')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ whole pixels

test('whole pixels at half: the button row, the open menu, a drag, under Thick, Thin and Blizzard on both clients', function()
	-- Each client and look takes one of the three noises, by turns (so each
	-- noise is walked under two of the six): three times the cases of all nine
	-- took 9 s.
	local noises, turn = { 0, 2 ^ -14, -2 ^ -14 }, 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
			turn = turn + 1
			for _, noise in ipairs({ noises[turn % 3 + 1] }) do
				world(client)
				look(name)
				stub.size_noise = noise
				local where = ('%s, %s, noise %s'):format(client, name, noise)
				open(); half()
				local w = tab()
				local off = P.off(OW:GetFrame())
				eq(#off, 0, where .. ', closed: ' .. P.report(off))
				click(w.menuButton)
				off = P.off(OW:GetFrame())
				eq(#off, 0, where .. ', window with the menu open: ' .. P.report(off))
				off = P.off(w.menu)
				eq(#off, 0, where .. ', the menu: ' .. P.report(off))
				check(w.menu:GetHeight() > 0, where .. ': the menu has a height')
				eq(w.menuButton:GetWidth() + 0.5 > 260, true, where .. ': the face')
				-- a drag in progress
				stub.mouse_buttons.LeftButton = true
				stub.fire_script(w.rows[4].handle, 'OnMouseDown', 'LeftButton')
				cursor_on(w.rows[2].frame, false)
				drag_frame(w)
				check(w.insert:IsShown() and w.ghost:IsShown(), where .. ': dragging')
				off = P.off(w.menu)
				eq(#off, 0, where .. ', the menu in a drag: ' .. P.report(off))
				off = P.off(w.ghost)
				eq(#off, 0, where .. ', the ghost: ' .. P.report(off))
				stub.mouse_buttons.LeftButton = nil
				stub.cursor_x, stub.cursor_y = 0, 0
				stub.fire_script(w.rows[4].handle, 'OnMouseUp', 'LeftButton')
				tick()
				-- the last category, and the editor of the first
				INV.categoryEditor.selected = SELL
				OW:Render()
				off = P.off(OW:GetFrame())
				eq(#off, 0, where .. ', Grays/Auto Vendor: ' .. P.report(off))
				eq(#take_errors(), 0, where .. ': no errors')
				stub.size_noise = 0
				look('thick')
				st.Config:Close()
			end
		end
	end
end)

test('a long rule wraps in the narrow editor: every field clear of its X', function()
	for _, name in ipairs({ 'thick', 'blizzard' }) do
		world()
		look(name)
		local rule = R.Copy(INV:GetCategoryList().byId[SELL].rule)
		table.insert(rule.items[1].items[3].items, { op = 'or', items = { { block = 'oldgear', levels = 10, expansion = 9, share = 0.9 } } })
		INV:SetCategoryRule(SELL, rule)
		INV.categoryEditor.selected = SELL
		open(); half()
		local w = tab()
		local editor = w:EditorCell('rule').widget
		local pad = name == 'blizzard' and 0 or 14
		eq(editor.frame:GetWidth(), w.frame:GetWidth() - 2 * pad, name .. ": the pane's width, inside the padding")
		eq(editor.frame:GetRight(), w.frame:GetRight() - pad, name .. ': at the right of the tab')
		local oldGear, top = 0, editor.frame:GetTop()
		for i, row in ipairs(editor.rows) do
			local f = row.frame
			eq(f:GetHeight() % 26, 0, name .. ' row ' .. i .. ' is lines of 26')
			if type(row.node) == 'table' and row.node.block == 'oldgear' then
				oldGear = oldGear + 1
				check(f:GetHeight() > 26, name .. ' row ' .. i .. ': Old gear wraps onto another line')
			end
			local limit = row.remove:IsShown() and row.remove:GetLeft() or f:GetRight()
			local function fits(region, right, what)
				check(right <= limit, name .. ' row ' .. i .. ': ' .. what .. ' ends before the X')
				check(region:GetLeft() >= f:GetLeft(), name .. ' row ' .. i .. ': ' .. what .. ' starts in the row')
				check(region:GetBottom() >= f:GetBottom() and region:GetTop() <= f:GetTop(), name .. ' row ' .. i .. ': ' .. what .. ' in the row')
			end
			for fieldName, control in pairs(row.fields) do
				if control:IsShown() then
					if control.GetUnboundedStringWidth then
						fits(control, control:GetLeft() + control:GetUnboundedStringWidth(), fieldName)
					else
						fits(control, control:GetRight(), fieldName)
					end
				end
			end
			for _, caption in ipairs(row.captions) do
				fits(caption, caption:GetLeft() + caption:GetUnboundedStringWidth(), 'a caption')
			end
		end
		eq(oldGear, 2, name .. ': both Old gear rows were looked at')
		eq(editor.frame:GetHeight(), top - editor.rows[#editor.rows].frame:GetBottom(), name .. ': as tall as its rows')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(OW:GetFrame())
			eq(#off, 0, name .. ', noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0
		eq(#take_errors(), 0, 'no errors')
		look('thick')
		st.Config:Close()
	end
end)

------------------------------------------------------------------ fix round 1

test("at half the Reset button never passes the editor, whatever the category is called; at full it keeps its name", function()
	for _, name in ipairs({ 'thick', 'blizzard' }) do
		world()
		look(name)
		local long = 'Death Knight/Warlock/Demon Hunter'
		INV:RenameCategory('Toys', 'A category with a very long name that cannot fit the button at all')
		open(); half()
		local list = INV:GetCategoryList()
		check(list.byId[long], 'the longest default is there')
		for _, entry in ipairs(list) do
			INV.categoryEditor.selected = entry.id
			OW:Render()
			local w = tab()
			for _, key in ipairs({ 'reset', 'delete' }) do
				local c = w:EditorCell(key)
				if c then
					check(c.widget.frame:GetRight() <= w.editorScroll:GetRight() + 0.01,
						('%s: %s: the %s button ends inside the editor'):format(name, entry.id, key))
				end
			end
		end
		INV.categoryEditor.selected = long
		OW:Render()
		eq(tab():EditorCell('reset').widget.text:GetText(), 'Reset to default', name .. ': the face names the category')
		OW:SetWindowSize('full'); stub.time = stub.time + 1
		eq(tab():EditorCell('reset').widget.text:GetText(), 'Reset ' .. long .. ' to default', name .. ': full as before')
		st.Config:Close()
	end
end)

test('the menu and its catcher are gone when the window closes or combat starts, and no key or click is left held', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	check(w.menu.catcher:IsKeyboardEnabled(), 'the catcher takes keys while open')
	st.Config:Close()
	check(not w.menu:IsShown() and not w.menu.catcher:IsShown() and not w.menu.catcher:IsKeyboardEnabled(), 'closing /sui')
	open()
	w = tab()
	click(w.menuButton)
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	stub.in_combat = false
	check(not OW:IsShown(), 'combat closed the window')
	check(not w.menu:IsShown() and not w.menu.catcher:IsShown() and not w.menu.catcher:IsKeyboardEnabled(), 'combat')
	eq(#take_errors(), 0, 'no errors')
end)

test('Esc is kept from the game, other keys go on; the wheel stops at the menu; the face is lit while it is open', function()
	world()
	open(); half()
	local w = tab()
	click(w.menuButton)
	stub.fire_script(w.menu.catcher, 'OnKeyDown', 'A')
	eq(w.menu.catcher:GetPropagateKeyboardInput(), true, 'A goes on')
	stub.fire_script(w.menu.catcher, 'OnKeyDown', 'ESCAPE')
	eq(w.menu.catcher:GetPropagateKeyboardInput(), false, 'Esc is kept')
	for _, frame in ipairs({ w.menu, w.menu.catcher }) do
		check(frame:IsMouseWheelEnabled(), 'the wheel is taken')
		check(type(frame:GetScript('OnMouseWheel')) == 'function', 'and goes nowhere')
	end
	check(not w.menuButton.on, 'the face is not lit closed')
	click(w.menuButton)
	check(tab().menuButton.on, 'the face is lit while the menu is open')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("the list sits over the menu, the editor's view ends at its footer, and the footer is at most half the column", function()
	world()
	INV.categoryEditor.selected = 'Toys'
	for i = 1, 150 do INV:PinItem(9000 + i, 'Toys') end
	open(); half()
	local w = tab()
	click(w.menuButton)
	local base = w.menu:GetFrameLevel()
	check(w.listPane:GetFrameLevel() > base and w.listScroll:GetFrameLevel() > base, 'the pane and its scroll frame')
	check(w.list:GetFrameLevel() > base and w.rows[1].frame:GetFrameLevel() > base and w.over:GetFrameLevel() > base, 'the rows and the drop line')
	check(w.footer:IsShown(), 'there is a footer')
	eq(w.editorScroll:GetBottom(), w.footer:GetTop(), "the editor's view ends where the footer starts")
	local column = w.frame:GetHeight() - 34
	eq(w.footer:GetHeight(), math.floor(column / 2), 'a tall footer is half the column, not half the tab')
	-- Where the row starts: 14 in under Thick and Thin, 0 under Blizzard.
	eq(w.menuButton:GetLeft(), w.frame:GetLeft() + 14, 'the button row at the editor content')
	look('blizzard'); OW:Render()
	eq(tab().menuButton:GetLeft(), tab().frame:GetLeft(), 'and at 0 under Blizzard')
	look('thick')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)
