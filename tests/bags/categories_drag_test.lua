-- The drag in the Categories tab (SaftUI-Bags/dragparts.lua, the handle, ghost and
-- drop line the list and the rule editor both drag with): a row's handle
-- reordering the list, the window held while a drag runs, a row dragged past
-- the selected one, a drag with the list scrolled, and the rule editor's drag
-- and lists with the editor scrolled.
--
-- Real: bags/container_helpers.lua's views world (bag_world.lua's stubbed bags
-- under the module's real files) on Core's real config.lua and AceDB
-- (core/config_helpers.lua), the options window (optionsmodel.lua, the
-- widget files, optionsbody.lua, the window's files), and SaftUI-Bags'
-- options.lua, dragparts.lua, ruleeditor.lua and categoriestab.lua, all
-- loaded by categories_world.lua. Made by hand: INV:UpdateGold, which
-- INV:UpdateHandler runs first, is a no-op here (it reads the player's money
-- with GetMoney and formats it with LibStringFormat-1.0, neither loaded
-- here). The mouse, the keyboard and the frame clock are played by firing
-- scripts: the window renders on its ticker's OnUpdate, and a drag draws on
-- its frame's, which the stubs never run by themselves; a held mouse button
-- is stub.mouse_buttons.LeftButton.
local CW = load_test_file('bags/categories_world.lua')
local st, INV, B, OW, OM, W, R

-- A fresh world (categories_world.lua's), with its names set here.
local function world(client)
	local container
	container, st, INV, B, OW, OM, W, R = CW.world(client)
	return container
end
local wheel, open, SETS, in_view, ids = CW.wheel, CW.open, CW.SETS, CW.in_view, CW.ids
local MISC, cursor_on, tab, SELL, row_of = CW.MISC, CW.cursor_on, CW.tab, CW.SELL, CW.row_of
local tick, yes, click, drag_frame, inside = CW.tick, CW.yes, CW.click, CW.drag_frame, CW.inside
local tall_rule = CW.tall_rule

-- A handle dragged onto a frame's upper or lower half, the mouse held between.
local function drag(handle, onto, lower)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	if onto then cursor_on(onto, lower) else stub.cursor_x, stub.cursor_y = 0, 0 end
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
end

------------------------------------------------------------------ the tab

test("dragging a row's handle reorders the list; Miscellaneous stays last", function()
	world()
	open()
	local w = tab()
	eq(w.rows[2].id, SELL, 'Grays/Auto Vendor is second')

	-- Consumables onto Grays/Auto Vendor's upper half: just above it.
	local handle = row_of(w, 'Consumables').handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	check(w.drag ~= nil, 'a drag starts on the handle')
	check(w.ghost and w.ghost:IsShown(), 'a ghost follows the cursor')
	check(w.ghost.backdrop ~= nil, "drawn in SaftUI's theme")
	eq(w.ghost.text:GetText(), 'Consumables', 'with the name')
	cursor_on(row_of(w, SELL).frame, false)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	check(not w.ghost:IsShown(), 'the ghost is gone')
	local list = INV:GetCategoryList()
	eq(list[2].id, 'Consumables', 'Consumables is second')
	eq(list[3].id, SELL, 'Grays/Auto Vendor after it')
	w = tab()
	eq(w.rows[2].id, 'Consumables', 'the list is drawn again')

	-- Onto a row's lower half: just below it.
	drag(row_of(w, 'Quest').handle, row_of(w, SETS).frame, true)
	eq(INV:GetCategoryList()[2].id, 'Quest', 'Quest just below Equipment sets')

	-- Onto Miscellaneous's lower half: just above it, which stays last. It's
	-- at the bottom of the list, below its view: scrolled to first.
	w = tab()
	check(not in_view(w, row_of(w, MISC)), 'Miscellaneous is out of view')
	wheel(w.listScroll, -1, 50)
	check(in_view(w, row_of(w, MISC)), 'scrolled to')
	drag(row_of(w, 'Armor').handle, row_of(w, MISC).frame, true)
	list = INV:GetCategoryList()
	eq(list[#list].id, MISC, 'Miscellaneous is last')
	eq(list[#list - 1].id, 'Armor', 'Armor just above it')
	w = tab()
	check(not row_of(w, MISC).handle:IsShown(), 'Miscellaneous has no handle')

	-- Dropped where it is, or off the list: nothing moves.
	wheel(w.listScroll, 1, 50)
	local order = ids()
	local toys = row_of(w, 'Toys')
	check(in_view(w, toys), 'Toys shows')
	drag(toys.handle, toys.frame, false)
	drag(toys.handle, toys.frame, true)
	drag(toys.handle, nil)
	eq(ids(), order, 'nothing moved')
	check(not w.ghost:IsShown(), 'and no ghost')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a drag in the tab holds the window: neither the list nor the rule editor is drawn again until the mouse is let go', function()
	world()
	local rule = R.Copy(INV:GetCategoryList().byId.Consumables.rule)
	rule.items[#rule.items + 1] = { block = 'name', text = 'Elixir' }
	INV:SetCategoryRule('Consumables', rule)
	INV.categoryEditor.selected = 'Consumables'
	open()
	local w = tab()
	local told
	local real = w.onChanged
	w.onChanged = function(...)
		told = { ... }
		return real(...)
	end

	-- The list's drag (its top in view: Consumables, selected, is lower down).
	wheel(w.listScroll, 1, 50)
	local handle = row_of(w, 'Quest').handle
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	eq(told and told[3], true, 'the window is told a drag is on')
	check(told and told[4] == w, 'with the tab as the dragged widget')
	local renders = OW.GetRenderCount()
	local editor = w:EditorCell('rule').widget
	B.put(0, 7, B.item(102, 'Elixir', 'Consumable', 30))
	INV:QueueUpdate(true)
	INV:UpdateHandler()
	tick()
	tick()
	eq(OW.GetRenderCount(), renders, 'a bag update waits for the drag')
	check(tab() == w and w:EditorCell('rule').widget == editor, 'nothing in the tab was drawn again')
	check(w.drag ~= nil, 'the drag goes on')
	eq(row_of(w, 'Consumables').count:GetText(), '1', 'the count waits too')
	cursor_on(row_of(w, SETS).frame, true)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(INV:GetCategoryList()[2].id, 'Quest', 'let go: the drop moves it')
	tick()
	w = tab()
	eq(row_of(w, 'Consumables').count:GetText(), '2', 'drawn again: the new count')

	-- The rule editor's drag, inside the tab: the tab passes itself on.
	told = nil
	real = w.onChanged
	w.onChanged = function(...)
		told = { ... }
		return real(...)
	end
	editor = w:EditorCell('rule').widget
	eq(editor.rows[2].kind .. #editor.rows, 'block3', 'two blocks and the add row')
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(editor.rows[2].handle, 'OnMouseDown', 'LeftButton')
	eq(told and told[3], true, 'the window is told a drag is on')
	check(told and told[4] == w, 'with the tab as the dragged widget, not the rule editor in it')
	renders = OW.GetRenderCount()
	INV:QueueUpdate(true)
	INV:UpdateHandler()
	tick()
	eq(OW.GetRenderCount(), renders, 'a bag update waits for the drag')
	check(tab() == w and w:EditorCell('rule').widget == editor, 'the rule editor was not drawn again')
	check(editor.drag ~= nil, 'and is still dragging')
	cursor_on(editor.rows[1].frame, false)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(editor.rows[2].handle, 'OnMouseUp', 'LeftButton')
	eq(INV:GetCategoryList().byId.Consumables.rule.items[1].block, 'name', 'let go: the block moved')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ the editor's footer

test("another row dragged past the selected one leaves the list where it was dropped; the selected row's own drag, and the order's reset, bring it into view", function()
	world()
	local selected = INV:GetCategoryList()[25].id
	INV.categoryEditor.selected = selected
	open()
	local w = tab()
	check(in_view(w, row_of(w, selected)), 'opened with the selected row, 25, in view')

	-- From the list's bottom, a row under the selected one is dragged to the
	-- top (the wheel takes the list there mid-drag) and dropped on row 2.
	wheel(w.listScroll, -1, 50)
	local moving = w.rows[#w.rows - 2]
	check(in_view(w, moving), 'a row near the bottom shows')
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(moving.handle, 'OnMouseDown', 'LeftButton')
	wheel(w.listScroll, 1, 50)
	eq(w.listScroll:GetVerticalScroll(), 0, 'the list at its top')
	cursor_on(w.rows[2].frame, false)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(moving.handle, 'OnMouseUp', 'LeftButton')
	eq(INV:GetCategoryList().byId[moving.id].place, 2, 'dropped at row 2')
	eq(INV:GetCategoryList().byId[selected].place, 26, 'the selected one moved down a place')
	w = tab()
	eq(w.listScroll:GetVerticalScroll(), 0, 'the list stays where the drop was')
	check(in_view(w, row_of(w, moving.id)), 'the dropped row stays in view')
	check(not in_view(w, row_of(w, selected)), 'the selected row is left out of view')

	-- The selected row's own drag, dropped on the last whole row's lower
	-- half: it takes the next place, cut off at the view's bottom, and is
	-- brought into view by the least.
	local last
	for _, row in ipairs(w.rows) do
		if in_view(w, row) then last = row end
	end
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(row_of(w, selected).handle, 'OnMouseDown', 'LeftButton')
	cursor_on(last.frame, true)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(row_of(w, selected).handle, 'OnMouseUp', 'LeftButton')
	local place = INV:GetCategoryList().byId[selected].place
	eq(w.rows[place - 1].id, last.id, 'just under the row it was dropped on')
	w = tab()
	check(in_view(w, row_of(w, selected)), 'and shown whole')
	eq(row_of(w, selected).frame:GetBottom(), w.listScroll:GetBottom(), 'scrolled the least: at the bottom of the view')

	-- The order's reset: the selected default back in its shipped place, shown.
	wheel(w.listScroll, 1, 50)
	check(not in_view(w, row_of(w, selected)), 'scrolled away from it: cut off at the bottom')
	check(w.resetOrder:IsShown(), 'the order differs now: its reset shows')
	click(w.resetOrder)
	w = tab()
	eq(INV.categoryEditor.selected, selected, 'still selected')
	check(in_view(w, row_of(w, selected)), "the order's reset shows the selected row")
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a drag with the list scrolled: the line and the drop follow the scroll, the wheel scrolls it mid-drag, and holding near an edge scrolls it', function()
	world()
	open()
	local w = tab()
	wheel(w.listScroll, -1, 3)
	eq(w.listScroll:GetVerticalScroll(), 198, 'scrolled nine rows down')

	-- Quest's handle.
	local quest = row_of(w, 'Quest')
	stub.mouse_buttons.LeftButton = true
	st.config.profile.theme.accent:SetRGB(0.9, 0.2, 0.4) -- not the default, so a literal blue fails
	stub.fire_script(quest.handle, 'OnMouseDown', 'LeftButton')
	check(w.drag ~= nil, 'a drag')

	-- The line on the row under the cursor, where it is now.
	local target = w.rows[12]
	check(in_view(w, target), 'row 12 shows')
	cursor_on(target.frame, false)
	drag_frame(w)
	check(w.insert:IsShown(), 'the line shows')
	eq(w.insert:GetTop(), target.frame:GetTop() + 1, 'at the top of the row under the cursor, scrolled')
	local line = stub.state(w.insert).color_texture
	eq(string.format('%.2f,%.2f,%.2f', line[1], line[2], line[3]), '0.90,0.20,0.40', "the drop line is the accent")
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)

	-- The wheel mid-drag: the list scrolls, the drag goes on, the line follows.
	wheel(w.listScroll, 1)
	eq(w.listScroll:GetVerticalScroll(), 132, 'the wheel scrolls the list mid-drag')
	check(w.drag ~= nil, 'the drag goes on')
	target = w.rows[9]
	cursor_on(target.frame, false)
	drag_frame(w)
	eq(w.insert:GetTop(), target.frame:GetTop() + 1, "the line on the row now under the cursor")

	-- Held near the bottom edge it scrolls down, near the top up; not between.
	-- The band is 6 inside the edge and a row (22) outside it, so resting on
	-- the first or last row in view doesn't scroll. 264 (12 rows) a second:
	-- 33 in an eighth, 16.5 in a sixteenth.
	local scroll = w.listScroll
	local scale = scroll:GetEffectiveScale()
	local function cursor_at(x, y) stub.cursor_x, stub.cursor_y = x * scale, y * scale end
	local x = scroll:GetLeft() + 50
	for _, inside in ipairs({ 7, 11, 16 }) do
		cursor_at(x, scroll:GetBottom() + inside)
		drag_frame(w, 0.125)
		eq(scroll:GetVerticalScroll(), 132, 'on the last row in view, ' .. inside .. ' above the edge: still')
		cursor_at(x, scroll:GetTop() - inside)
		drag_frame(w, 0.125)
		eq(scroll:GetVerticalScroll(), 132, 'on the first row in view, ' .. inside .. ' under the edge: still')
	end
	cursor_at(x, scroll:GetBottom() + 3)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 33, 'near the bottom: down, 33 in an eighth of a second')
	drag_frame(w, 0.0625)
	eq(scroll:GetVerticalScroll(), 132 + 33 + 16, 'a sixteenth: 16, in whole units')
	drag_frame(w, 0.0625)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'and the half left over goes into the next')
	cursor_at(x, scroll:GetBottom() - 20)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 99, 'up to a row past the edge too')
	check(not w.insert:IsShown(), 'out of the view: no line')
	cursor_at(x, scroll:GetTop() - 3)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'near the top: up')
	cursor_at(x, (scroll:GetTop() + scroll:GetBottom()) / 2)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'in the middle: still')
	cursor_at(scroll:GetRight() + 40, scroll:GetBottom() + 3)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'beside the list: still')
	cursor_at(x, scroll:GetTop() + 25)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'more than a row above it: still')

	-- A row scrolled out of view isn't under the cursor where it would be.
	local hidden = w.rows[2]
	check(not in_view(w, hidden), 'row 2 is out of view')
	cursor_on(hidden.frame, false)
	drag_frame(w)
	check(not w.insert:IsShown(), 'no line over a row out of view')

	-- Dropped on a row in view: just above it.
	target = w.rows[20]
	check(in_view(w, target), 'row 20 shows')
	local before = target.id
	cursor_on(target.frame, false)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(quest.handle, 'OnMouseUp', 'LeftButton')
	local list = INV:GetCategoryList()
	eq(list.byId.Quest.place + 1, list.byId[before].place, 'Quest just above the row it was dropped on')
	check(w.ghost and not w.ghost:IsShown(), 'the drag is over')

	-- Let go over a row out of view: nothing moves.
	w = tab()
	local order = ids()
	wheel(w.listScroll, -1, 50)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(row_of(w, 'Quest').handle, 'OnMouseDown', 'LeftButton')
	cursor_on(w.rows[1].frame, false)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(row_of(w, 'Quest').handle, 'OnMouseUp', 'LeftButton')
	eq(ids(), order, 'nothing moved')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("the rule editor's drag and its lists work with the editor scrolled; its lists aren't cut off by it", function()
	world()
	tall_rule('Consumables', 25)
	INV.categoryEditor.selected = 'Consumables'
	open()
	local w = tab()
	local editor = w:EditorCell('rule').widget
	wheel(w.editorScroll, -1, 3)
	eq(w.editorScroll:GetVerticalScroll(), 204, 'the editor scrolled three turns')
	local scroll = w.editorScroll
	local function shows(row)
		return row.frame:GetTop() <= scroll:GetTop() and row.frame:GetBottom() >= scroll:GetBottom()
	end

	-- A block dragged onto another, both in view.
	local from, onto
	for i, row in ipairs(editor.rows) do
		if row.kind == 'block' and shows(row) then
			if not from then from = i elseif i >= from + 3 then onto = i break end
		end
	end
	check(from and onto, 'two blocks in view')
	local moving = editor.rows[from].node.text
	local ontoText = editor.rows[onto].node.text
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(editor.rows[from].handle, 'OnMouseDown', 'LeftButton')
	cursor_on(editor.rows[onto].frame, false)
	stub.fire_script(editor.frame, 'OnUpdate', 0.01)
	check(editor.insert:IsShown(), 'its line shows')
	eq(editor.insert:GetTop(), editor.rows[onto].frame:GetTop() + 1, 'on the row under the cursor, scrolled')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(editor.rows[from].handle, 'OnMouseUp', 'LeftButton')
	local items = INV:GetCategoryList().byId.Consumables.rule.items
	local at = {}
	for i, node in ipairs(items) do if node.text then at[node.text] = i end end
	eq(at[moving] + 1, at[ontoText], 'the block went just above the one it was dropped on')
	w = tab()
	eq(w.editorScroll:GetVerticalScroll(), 204, 'the editor stays scrolled')

	-- A row scrolled out of the editor's view isn't under the cursor.
	editor = w:EditorCell('rule').widget
	scroll = w.editorScroll
	local rule = INV:GetCategoryList().byId.Consumables.rule
	local hidden
	for _, row in ipairs(editor.rows) do
		if row.kind == 'block' and not shows(row) then hidden = row break end
	end
	check(hidden ~= nil, 'a block out of view, above')
	local last
	for _, row in ipairs(editor.rows) do
		if row.kind == 'block' and shows(row) then last = row end
	end
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(last.handle, 'OnMouseDown', 'LeftButton')
	cursor_on(hidden.frame, false)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(last.handle, 'OnMouseUp', 'LeftButton')
	eq(INV:GetCategoryList().byId.Consumables.rule, rule, 'nothing moved')

	-- + Block at the end of the rule, scrolled to: its list opens under it, on
	-- UIParent, out of every scroll frame.
	w = tab()
	wheel(w.editorScroll, -1, 50)
	editor = w:EditorCell('rule').widget
	local add = editor.rows[#editor.rows].fields.addBlock
	click(add)
	eq(W.ListOwner(), add, 'the list of blocks opens')
	local frame = W.GetListFrames().frame
	local parent, cut = frame:GetParent(), false
	while parent do
		if parent:IsObjectType('ScrollFrame') then cut = true end
		parent = parent:GetParent()
	end
	check(not cut, 'no scroll frame cuts it off')
	check(math.abs(frame:GetTop() - (add:GetBottom() - 2)) < 1e-6 or math.abs(frame:GetBottom() - (add:GetTop() + 2)) < 1e-6,
		'right under (or over) the button, scrolled')
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("a block dragged near the rule editor's edge scrolls it: held only, whole pixels at a steady rate, never past an end, the line follows, and nothing keeps running", function()
	world()
	tall_rule('Consumables', 25)
	INV.categoryEditor.selected = 'Consumables'
	open()
	local w = tab()
	local editor = w:EditorCell('rule').widget
	local scroll = w.editorScroll
	local scale = scroll:GetEffectiveScale()
	local function cursor_at(x, y) stub.cursor_x, stub.cursor_y = x * scale, y * scale end
	local x = scroll:GetLeft() + 50
	local function frames(n, elapsed)
		for _ = 1, n do
			stub.fire_script(w.editorDriver, 'OnUpdate', elapsed)
			stub.fire_script(editor.frame, 'OnUpdate', elapsed)
		end
	end


	-- Nothing runs until a block is held.
	eq(w.editorDriver:GetScript('OnUpdate'), nil, 'nothing runs before a drag')
	local start = scroll:GetVerticalScroll()
	local handle
	for _, row in ipairs(editor.rows) do
		if row.kind == 'block' then handle = row.handle break end
	end
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	check(editor.drag ~= nil, 'a drag in the editor')
	check(w.editorDriver:GetScript('OnUpdate') ~= nil, 'the driver runs while it is held')

	-- Resting in the middle: still.
	cursor_at(x, (scroll:GetTop() + scroll:GetBottom()) / 2)
	frames(4, 0.125)
	eq(scroll:GetVerticalScroll(), start, 'in the middle: still')

	-- Near the bottom: down, 33 in an eighth of a second; the same however the frames split.
	cursor_at(x, scroll:GetBottom() + 3)
	frames(1, 0.125)
	eq(scroll:GetVerticalScroll(), start + 33, 'near the bottom: 33 in an eighth of a second')
	frames(2, 0.0625)
	eq(scroll:GetVerticalScroll(), start + 66, 'two sixteenths: the same rate, in whole pixels')
	eq(scroll:GetVerticalScroll() % 1, 0, 'whole pixels')

	-- The line follows the row under the cursor as the content moves.
	cursor_at(x, scroll:GetBottom() + 40)
	frames(1, 0.01)
	local cy, under = stub.cursor_y / scale
	for _, row in ipairs(editor.rows) do
		if row.frame:GetTop() >= cy and row.frame:GetBottom() < cy then under = row end
	end
	check(under ~= nil, 'a row is under the cursor')
	check(editor.insert:IsShown(), 'the line shows')
	local top = editor.insert:GetTop()
	check(top == under.frame:GetTop() + 1 or top == under.frame:GetBottom() + 1, 'the line is on the row now under the cursor')

	-- Near the top: up.
	local before = scroll:GetVerticalScroll()
	cursor_at(x, scroll:GetTop() - 3)
	frames(1, 0.125)
	eq(scroll:GetVerticalScroll(), before - 33, 'near the top: up')

	-- Never past either end.
	frames(200, 0.125)
	eq(scroll:GetVerticalScroll(), 0, 'stops at the top')
	cursor_at(x, scroll:GetBottom() + 3)
	frames(400, 0.125)
	eq(scroll:GetVerticalScroll(), w.editorHeight - scroll:GetHeight(), 'stops at the bottom')

	-- Let go: no scrolling, and no OnUpdate left.
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	local after = tab().editorScroll:GetVerticalScroll()
	frames(4, 0.125)
	eq(tab().editorScroll:GetVerticalScroll(), after, 'after the drop: still')
	eq(w.editorDriver:GetScript('OnUpdate'), nil, "the tab's driver is off after the drop")
	eq(editor.frame:GetScript('OnUpdate'), nil, "none on the editor's after the drop")
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)
