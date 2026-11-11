-- The Categories tab in /sui > Bags (SaftUI-Bags/categoriestab.lua): the
-- bagcategories widget (the category list on the left, with its handles,
-- counts and markers, + New category and Reset all, and the selected
-- category's editor on the right, filling the body's view and each scrolling
-- on its own), INV:CategoryEditorOptions, the bagitems widget (Pinned items,
-- Caught now), INV:CountCategories, INV:EditCategory, and the open tab
-- following bag updates and a profile switch.
--
-- Real: bags/container_helpers.lua's views world (bag_world.lua's stubbed bags
-- under the module's real files) on Core's real config.lua and AceDB
-- (core/config_helpers.lua), the options window (optionsmodel.lua,
-- optionswidgets.lua, optionsbody.lua, optionswindow.lua), and SaftUI-Bags'
-- options.lua, ruleeditor.lua and categoriestab.lua. Made by hand:
-- INV:UpdateGold, which INV:UpdateHandler runs first, is a no-op here (it
-- reads the player's money with GetMoney and formats it with
-- LibStringFormat-1.0, neither loaded here). The mouse, the keyboard and the
-- frame clock are played by firing scripts: the window renders on its
-- ticker's OnUpdate, and a drag draws on its frame's, which the stubs never
-- run by themselves; a held mouse button is stub.mouse_buttons.LeftButton.
local H = load_test_file('bags/container_helpers.lua')

local st, INV, B, OW, OM, W, R

local SELL, SETS, MISC = 'Grays/Auto Vendor', 'Equipment sets', 'Miscellaneous'

-- The backpack: a tonic (Consumables), a gray cloth (Grays/Auto Vendor, by its
-- quality), a plank and a board (Trade Goods), a common bit (Miscellaneous)
-- and a mace in the Heal equipment set. The bag window is laid out in Compact.
local function world(client)
	INV, B = H.views_world(client or 'forever', function() load_test_file('core/config_helpers.lua') end)
	st = SaftUI
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_saftui('SaftUI-Core/Config/optionswindow.lua')
	load_saftui('SaftUI-Bags/options.lua')
	load_saftui('SaftUI-Bags/ruleeditor.lua')
	load_saftui('SaftUI-Bags/categoriestab.lua')
	OW, OM, W, R = st.OptionsWindow, st.OptionsModel, st.OptionsWidgets, INV.Rules
	-- The money in the bag window's footer (GetMoney, LibStringFormat-1.0).
	INV.UpdateGold = function() end
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	B.bag(0, 20, 'Backpack')
	B.put(0, 1, B.item(101, 'Tonic', 'Consumable', 30))
	B.put(0, 2, B.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0 }))
	B.put(0, 3, B.item(301, 'Plank', 'Trade Goods', 15))
	B.put(0, 4, B.item(302, 'Board', 'Trade Goods', 15))
	B.put(0, 5, B.item(503, 'Common Bit', 'Miscellaneous', 1))
	B.put(0, 6, B.item(601, 'Healing Mace', 'Weapon', 50, { set = 'Heal' }))
	INV.config.stackItems = false
	INV.config.bag.view = 'compact'
	INV.config.bag.emptySlots = 'off'
	local container = H.window('bag')
	H.search(container)
	INV:RegisterMovers()
	INV:UpdateContainer('bag', true)
	take_errors()
	return container
end

------------------------------------------------------------------ helpers

local function open()
	st.Config:Open('Inventory', 'categories')
end

local function cell(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

local function drawn()
	local out = {}
	for i, c in ipairs(OW.GetDrawnRows()) do out[i] = c.row.key end
	return table.concat(out, ',')
end

-- The tab's widget, as the window drew it last.
local function tab() return cell('categories').widget end

local function tick() stub.fire_script(OW.GetFrames().ticker, 'OnUpdate', 0.01) end
local function click(frame, ...) stub.fire_script(frame, 'OnClick', ...) end

local function enter(box, text)
	box:SetText(text)
	stub.fire_script(box, 'OnEnterPressed')
end

local function rgb(group, name) return { st.config.profile.colors[group][name]:GetRGB() } end
local function same_rgb(c, want)
	return math.abs(c[1] - want[1]) < 1e-6 and math.abs(c[2] - want[2]) < 1e-6 and math.abs(c[3] - want[3]) < 1e-6
end

-- The list's row of a category.
local function row_of(w, id)
	for _, row in ipairs(w.rows) do
		if row.id == id then return row end
	end
end

local function ids()
	local out = {}
	for i, entry in ipairs(INV:GetCategoryList()) do out[i] = entry.id end
	return table.concat(out, ',')
end

-- Puts the cursor on a frame's upper or lower half.
local function cursor_on(frame, lower)
	local l, b, width, h = frame:GetRect()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x = (l + width / 2) * scale
	stub.cursor_y = (b + (lower and 0.25 or 0.75) * h) * scale
end

-- Turns of the mouse wheel over frame: 1 scrolls up, -1 down.
local function wheel(frame, delta, times)
	for _ = 1, times or 1 do stub.fire_script(frame, 'OnMouseWheel', delta) end
end

-- Whether a list row's whole frame shows in the list's view.
local function in_view(w, row)
	return row.frame:GetTop() <= w.listScroll:GetTop() and row.frame:GetBottom() >= w.listScroll:GetBottom()
end

-- A frame of a drag: its frame's OnUpdate, as the game runs it each frame.
local function drag_frame(w, elapsed) stub.fire_script(w.frame, 'OnUpdate', elapsed or 0.01) end

-- A handle dragged onto a frame's upper or lower half, the mouse held between.
local function drag(handle, onto, lower)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	if onto then cursor_on(onto, lower) else stub.cursor_x, stub.cursor_y = 0, 0 end
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
end

-- The open list's labels, and a click on one of them.
local function list_labels()
	local out = {}
	for i, entry in ipairs(W.GetListFrames().entries or {}) do out[i] = entry.label end
	return table.concat(out, ',')
end

local function pick(label)
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() and row.text:GetText() == label then return click(row) end
	end
	error('no list row ' .. label)
end

local function yes() click(W.GetDialogFrames().yes) end
local function no() click(W.GetDialogFrames().no) end

-- The shown icons of a bagitems widget.
local function icons(items)
	local out = {}
	for _, icon in ipairs(items.icons) do
		if icon:IsShown() then out[#out + 1] = icon end
	end
	return out
end

local function icon_ids(items)
	local out = {}
	for i, icon in ipairs(icons(items)) do out[i] = tostring(icon.entry.itemID) end
	return table.concat(out, ',')
end

-- The editor's rows, as the model gives them for a category.
local function editor_rows(id)
	local view = OM.BuildView({ category = INV:CategoryEditorOptions(id) }, 'category')
	local out, byKey = {}, {}
	for _, section in ipairs(view.sections) do
		for _, row in ipairs(section.rows) do
			out[#out + 1] = row.key
			byKey[row.key] = row
		end
	end
	return table.concat(out, ','), byKey
end

------------------------------------------------------------------ the tab

test('the Bags page has a Categories tab after the windows: one wide row with a desc', function()
	world()
	local tree = INV:GetConfigTable()
	local group = tree.args.categories
	check(group ~= nil and group.type == 'group', 'a Categories group')
	eq(group.name, 'Categories', 'named Categories')
	check(tree.args.bag ~= nil, "the bag window's tab is there to be after")
	for _, id in ipairs(INV.windowIds) do
		local window = tree.args[id]
		if window then check(group.order > window.order, 'after the ' .. id .. ' window') end
	end
	local keys = {}
	for key in pairs(group.args) do keys[#keys + 1] = key end
	eq(table.concat(keys, ','), 'categories', 'one row')
	local row = group.args.categories
	eq(row.type, 'bagcategories', 'the tab widget')
	eq(row.size, 'wide', 'wide')
	eq(row.name, 'Categories', 'named Categories')
	eq(row.desc, 'Every bag category in the order they claim items: an item goes to the first one that catches it. '
		.. 'Drag a category by its handle to move it, and select one to edit it.', 'its desc')
	eq(row.width, nil, 'no Ace width')

	open()
	eq(OW:GetState().tab, 'categories', '/sui opens on it')
	local view = OM.BuildView(OW:GetRoot(), 'Inventory')
	eq(view.tabs[#view.tabs].key, 'categories', 'the last tab')
	eq(drawn(), 'categories', 'its one row')
	local c = cell('categories')
	check(not c.label:IsShown(), 'bare: no label')
	eq(c.widget.frame:GetWidth(), 774, "the body's width")
	eq(c.height, math.ceil(c.widget.frame:GetHeight()) + 12, 'its cell is its height plus 12')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the list: every category in order, counts from the bag window, the edited and yours markers, struck through when off, the selected row', function()
	local container = world()
	INV:RenameCategory('Trade Goods', 'Wood')
	local mine = INV:AddUserCategory()
	INV:SetCategoryEnabled('Quest', false)
	INV:UpdateContainer('bag', true)
	INV.categoryEditor.selected = 'Consumables'
	open()
	local w = tab()
	local list = INV:GetCategoryList()
	eq(#w.rows, #list, 'a row per category')
	-- The rows are laid in the list's scroll child, from its top.
	local top, left = w.list:GetTop(), w.frame:GetLeft()
	for i, entry in ipairs(list) do
		local row = w.rows[i]
		eq(row.id, entry.id, 'row ' .. i .. ' in list order')
		eq(row.name:GetText(), entry.name, 'row ' .. i .. ' shows its name')
		eq(top - row.frame:GetTop(), (i - 1) * 22, 'row ' .. i .. ' under the one before')
		eq(row.frame:GetHeight(), 22, 'row ' .. i .. ' is 22 high')
		eq(row.frame:GetLeft() - left, 0, 'at the left')
		eq(row.frame:GetWidth(), 210, 'the list is 210 wide')
	end

	-- The counts are what the bag window's headers show (Compact).
	local compared = 0
	for key, frame in pairs(container.categories) do
		local row = row_of(w, key)
		if row and frame:IsShown() then
			local n = frame.header.text:GetText():match('%((%d+)%)$')
			eq(row.count:GetText(), n, key .. ': the count its header shows')
			compared = compared + 1
		end
	end
	check(compared >= 4, 'compared with the shown headers')
	eq(row_of(w, 'Trade Goods').count:GetText(), '2', 'Trade Goods: the plank and the board')
	eq(row_of(w, SELL).count:GetText(), '1', 'Grays/Auto Vendor: the gray cloth')
	eq(row_of(w, SETS).count:GetText(), '1', "Equipment sets: every set's items")
	check(row_of(w, MISC).count:IsShown(), 'Miscellaneous has one')
	check(not row_of(w, 'Armor').count:IsShown(), 'no count when nothing is caught')
	check(same_rgb({ row_of(w, SELL).count:GetTextColor() }, rgb('text', 'grey')), 'counts are grey')
	local consumables = row_of(w, 'Consumables')
	eq(consumables.count:GetRight(), consumables.frame:GetRight() - 8, 'at the right')

	-- Markers: an edited default, and one of yours.
	local wood = row_of(w, 'Trade Goods')
	eq(wood.name:GetText(), 'Wood', 'a renamed default shows its name')
	check(wood.marker:IsShown(), 'an edited default has a marker')
	eq(wood.marker:GetText(), 'edited', 'edited')
	check(same_rgb({ wood.marker:GetTextColor() }, rgb('text', 'orange')), 'in orange')
	check(wood.marker:GetLeft() >= wood.name:GetLeft() + wood.name:GetWidth(), 'after the name')
	eq(row_of(w, mine).marker:GetText(), 'yours', 'one of yours')
	check(not row_of(w, 'Armor').marker:IsShown(), 'a default as shipped has none')

	-- Off: grey, with a line through its name.
	local quest = row_of(w, 'Quest')
	check(quest.strike:IsShown(), 'a category that is off is struck through')
	eq(quest.strike:GetHeight(), 1, 'by a 1px line')
	eq(quest.strike:GetLeft(), quest.name:GetLeft(), 'from the start of its name')
	eq(quest.strike:GetWidth(), quest.name:GetWidth(), 'across it')
	check(same_rgb({ quest.name:GetTextColor() }, rgb('text', 'grey')), 'its name is grey')
	check(not row_of(w, 'Armor').strike:IsShown(), 'one that is on is not')
	check(same_rgb({ row_of(w, 'Armor').name:GetTextColor() }, rgb('text', 'normal')), 'and its name is not grey')

	-- The selected row: tinted blue with a 3px bar at its left.
	for _, row in ipairs(w.rows) do
		eq(row.tint:IsShown(), row.id == 'Consumables', row.id .. ': tinted only when selected')
		eq(row.bar:IsShown(), row.id == 'Consumables', row.id .. ': the bar only when selected')
	end
	eq(consumables.bar:GetWidth(), 3, 'the bar is 3 wide')
	eq(consumables.bar:GetLeft(), consumables.frame:GetLeft(), 'at the left')
	eq(consumables.bar:GetHeight(), 22, 'the whole row high')
	check(same_rgb(stub.state(consumables.bar).color_texture, rgb('button', 'blue')), 'blue')

	-- A handle on every row but Miscellaneous.
	for _, row in ipairs(w.rows) do
		eq(row.handle:IsShown(), row.id ~= MISC, row.id .. ': a handle unless Miscellaneous')
	end

	-- Under the list: + New category and Reset all, in blue, under its view
	-- (the shipped list is longer than it shows; see the scrolling tests).
	eq(w.addButton.text:GetText(), '+ New category', '+ New category')
	eq(w.resetButton.text:GetText(), 'Reset all', 'Reset all')
	check(same_rgb({ w.addButton.text:GetTextColor() }, rgb('text', 'blue')), 'in blue')
	check(same_rgb({ w.resetButton.text:GetTextColor() }, rgb('text', 'blue')), 'both')
	eq(w.listScroll:GetBottom() - w.addButton:GetTop(), 8, "8 under the list's view")
	check(w.resetButton:GetLeft() > w.addButton:GetRight(), 'side by side')

	-- The editor pane: from 234, 540 wide.
	eq(w.pane:GetLeft() - left, 234, 'the editor starts at 234')
	eq(w.pane:GetWidth(), 540, 'and is 540 wide')
	eq(w:EditorCell('name').widget.frame:GetText(), 'Consumables', "the editor shows the selected category's")

	-- A click selects a row.
	click(row_of(w, 'Armor').frame)
	eq(INV.categoryEditor.selected, 'Armor', 'selected')
	w = tab()
	check(row_of(w, 'Armor').tint:IsShown() and not row_of(w, 'Consumables').tint:IsShown(), 'the tint moved')
	eq(w:EditorCell('name').widget.frame:GetText(), 'Armor', 'and the editor')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

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

test('+ New category adds one above Miscellaneous and selects it; with a deleted default it offers Restore a default...', function()
	world()
	open()
	click(tab().addButton)
	eq(W.ListOwner(), nil, 'with no deleted default, no list')
	local list = INV:GetCategoryList()
	local new = list[#list - 1]
	eq(new.name, 'New category', 'a new category')
	eq(new.default, false, 'of yours')
	eq(list[#list].id, MISC, 'above Miscellaneous')
	eq(INV.categoryEditor.selected, new.id, 'selected')
	local w = tab()
	eq(w:EditorCell('name').widget.frame:GetText(), 'New category', 'in the editor')
	check(row_of(w, new.id).tint:IsShown(), 'and the list')

	-- A deleted default: a list of New category and Restore a default...
	INV:RemoveCategory('Toys')
	OW:Render()
	w = tab()
	click(w.addButton)
	eq(W.ListOwner(), w.addButton, 'a list opens')
	eq(list_labels(), 'New category,Restore a default...', 'New category or Restore a default...')
	pick('Restore a default...')
	eq(W.ListOwner(), w.addButton, 'then a list of the deleted defaults')
	eq(list_labels(), 'Toys', 'by name')
	pick('Toys')
	check(INV:GetCategoryList().byId.Toys ~= nil, 'Toys is back')
	eq(INV.categoryEditor.selected, 'Toys', 'and selected')
	check(row_of(tab(), 'Toys').tint:IsShown(), 'in the list')

	INV:RemoveCategory('Anima')
	OW:Render()
	click(tab().addButton)
	pick('New category')
	list = INV:GetCategoryList()
	eq(list[#list - 1].name, 'New category 2', 'New category adds one')
	eq(INV.categoryEditor.selected, list[#list - 1].id, 'selected')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('Reset all asks first, then resets', function()
	world()
	local shipped = ids()
	INV:RenameCategory('Armor', 'Plate')
	local mine = INV:AddUserCategory()
	INV:RemoveCategory('Toys')
	INV:PinItem(301, 'Consumables')
	open()
	click(tab().resetButton)
	eq(W.ConfirmText(), "Reset all categories to SaftUI's defaults? Your own categories are deleted. Pinned and Protected items are kept.",
		'it asks')
	no()
	eq(INV:CategoryName('Armor'), 'Plate', 'No changes nothing')
	check(INV:GetCategoryList().byId[mine] ~= nil, 'yours stays')
	click(tab().resetButton)
	yes()
	eq(INV:CategoryName('Armor'), 'Armor', 'Yes: the rename is gone')
	eq(INV:GetCategoryList().byId[mine], nil, 'yours are deleted')
	eq(ids(), shipped, 'the shipped list')
	eq(INV:GetPin(301), 'Consumables', 'a pin to a default stays')
	local w = tab()
	eq(#w.rows, #INV:GetCategoryList(), 'the list is drawn again')
	eq(row_of(w, 'Armor').name:GetText(), 'Armor', 'with the shipped names')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ the editor

test('the editor has its rows, each with a desc', function()
	world()
	load_test_file('core/options_walk.lua')
	INV:PinItem(301, 'Trade Goods')
	local group = INV:CategoryEditorOptions('Trade Goods')
	eq(group.type, 'group', 'a group')
	local seen = {}
	each_option(group, function(option, path)
		local key = path[#path]
		seen[#seen + 1] = key .. ':' .. option.type
		eq(option.width, nil, key .. ' has no Ace width')
		check(type(option.desc) == 'string' and option.desc ~= '', key .. ' has a desc')
	end)
	eq(table.concat(seen, ' '),
		'caught:bagitems delete:execute enabled:toggle name:input pins:bagitems reset:execute rule:bagrule show:multiselect',
		'its rows')
	local args = group.args
	eq(args.name.name, 'Name', 'Name')
	eq(args.name.desc, 'What the category is called in the bag windows. Renaming it keeps its place, its Show in choices and its pinned items.', 'its desc')
	eq(args.enabled.name, 'On', 'On')
	eq(args.enabled.size, 'small', 'small')
	eq(args.enabled.desc, 'Turned off, the items it would catch go to the next category that catches them.', 'its desc')
	eq(args.show.name, 'Show in', 'Show in')
	eq(args.show.desc, 'The windows that show this category. A hidden category still catches its items; One bag and Multi bag show every item.', 'its desc')
	eq(args.rule.name, 'Catches an item when', 'the rule')
	eq(args.rule.size, 'wide', 'wide')
	eq(args.rule.desc, 'An item goes to the first category, from the top of the list, whose rule it matches. AND needs every block, OR any one. '
		.. 'Click AND or OR to flip it, and drag a block by its handle to move it.', 'its desc')
	eq(args.pins.name, 'Pinned items', 'Pinned items')
	eq(args.pins.size, 'wide', 'wide')
	eq(args.pins.desc, 'Items you added to this category from the slot menu (Ctrl + right click an item). They go here whatever the rules say. '
		.. 'Click the X on one to unpin it.', 'its desc')
	eq(type(args.pins.onRemove), 'function', 'pins can be removed')
	eq(args.caught.name, 'Caught now', 'Caught now')
	eq(args.caught.size, 'wide', 'wide')
	eq(args.caught.desc, 'The items in your bags this category catches now. Hover one to see which block caught it.', 'its desc')
	eq(type(args.caught.onHover), 'function', 'caught items can be hovered')
	eq(args.reset.name, 'Reset Trade Goods to default', 'Reset')
	eq(args.reset.desc, 'Put this category back as SaftUI ships it: its name, on or off, Show in and rule. Its pinned items stay.', 'its desc')
	eq(args.delete.name, 'Delete', 'Delete')
	eq(args.delete.desc, 'Delete this category. Its items go to the next category that catches them.', 'its desc')

	-- In this order.
	eq(editor_rows('Trade Goods'), 'name,enabled,show,rule,pins,caught,reset,delete', 'in order')
	INV:UnpinItem(301)
	eq(editor_rows('Trade Goods'), 'name,enabled,show,rule,caught,reset,delete', 'Pinned items only when there are some')

	-- Reading and setting.
	local _, rows = editor_rows('Trade Goods')
	local root = { category = INV:CategoryEditorOptions('Trade Goods') }
	eq(OM.Get(root, rows.name), 'Trade Goods', 'Name reads the name')
	OM.Set(root, rows.name, 'Wood')
	eq(INV:CategoryName('Trade Goods'), 'Wood', 'and renames')
	eq(OM.Get(root, rows.enabled), true, 'On reads on')
	OM.Set(root, rows.enabled, false)
	eq(INV:GetCategoryList().byId['Trade Goods'].enabled, false, 'and turns it off')
	eq(OM.Get(root, rows.show, 'bank'), true, 'Show in reads each window')
	OM.Set(root, rows.show, 'bank', false)
	eq(INV:IsCategoryHidden('bank', 'Trade Goods'), true, 'and hides it there')
	OM.Set(root, rows.show, 'bank', true)
	eq(INV:IsCategoryHidden('bank', 'Trade Goods'), false, 'or shows it')

	-- Show in: Bags and Bank on Forever, which has no warband bank.
	local values = OM.Values(root, rows.show)
	local labels = {}
	for i, value in ipairs(values) do labels[i] = value.key .. '=' .. value.name end
	eq(table.concat(labels, ','), 'bag=Bags,bank=Bank', 'Bags and Bank on Forever')
	eq(#take_errors(), 0, 'no errors')

	-- A warband bank adds Warband bank and Combined bank.
	world('retail')
	check(INV:HasWarbandBank(), 'retail has a warband bank')
	local _, retailRows = editor_rows('Trade Goods')
	values = OM.Values({ category = INV:CategoryEditorOptions('Trade Goods') }, retailRows.show)
	labels = {}
	for i, value in ipairs(values) do labels[i] = value.key .. '=' .. value.name end
	eq(table.concat(labels, ','), 'bag=Bags,bank=Bank,warband=Warband bank,combinedbank=Combined bank',
		'Warband bank and Combined bank with a warband bank')
	eq(#take_errors(), 0, 'no errors')
end)

test('Equipment sets and Miscellaneous have no rule; Miscellaneous has no On or Delete; Grays/Auto Vendor has no Delete', function()
	world()
	local mine = INV:AddUserCategory()
	local keys, rows = editor_rows(SETS)
	eq(keys, 'name,enabled,show,note,caught,reset', 'Equipment sets: a note in place of a rule, no Delete')
	eq(rows.note.type, 'description', 'the note is text')
	eq(rows.note.name, 'Makes a category for each equipment set, "Set: <name>", for the armor and weapons in it. It has no rule.', 'its words')
	keys, rows = editor_rows(MISC)
	eq(keys, 'name,show,note,caught,reset', 'Miscellaneous: no On, no rule, no Delete')
	eq(rows.note.name, 'Catches every item no category above it catches. It is always last.', 'its words')
	keys, rows = editor_rows(SELL)
	eq(keys, 'name,enabled,show,rule,caught,reset', 'Grays/Auto Vendor: no Delete')
	eq(rows.enabled.desc, 'Turned off, the items it would catch go to the next category that catches them. Turned off, auto vendor sells nothing.',
		'its On says what turning it off does')
	keys = editor_rows(mine)
	eq(keys, 'name,enabled,show,rule,caught,delete', 'yours: no Reset')

	-- Reset is for an edited default.
	_, rows = editor_rows('Armor')
	eq(rows.reset.disabled, true, 'Reset is off for a default as shipped')
	INV:RenameCategory('Armor', 'Plate')
	_, rows = editor_rows('Armor')
	eq(rows.reset.disabled, false, 'and on once it is edited')
	eq(rows.reset.name, 'Reset Plate to default', 'named by its name')

	-- Drawn in the tab.
	INV.categoryEditor.selected = MISC
	open()
	local w = tab()
	local out = {}
	for i, c in ipairs(w.body.cells) do out[i] = c.row.key end
	eq(table.concat(out, ','), 'name,show,note,caught,reset', "Miscellaneous's editor in the tab")
	eq(w:EditorCell('note').widget.text:GetText(), 'Catches every item no category above it catches. It is always last.', 'the note')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("the Name box renames; it refuses an empty name or another category's, in any case, and keeps the old one", function()
	world()
	INV.categoryEditor.selected = 'Armor'
	open()
	enter(tab():EditorCell('name').widget.frame, 'Plate')
	eq(INV:CategoryName('Armor'), 'Plate', 'renamed')
	eq(row_of(tab(), 'Armor').name:GetText(), 'Plate', 'the list shows it')
	eq(row_of(tab(), 'Armor').marker:GetText(), 'edited', 'edited')

	local status = OW.GetFrames().status
	enter(tab():EditorCell('name').widget.frame, '   ')
	eq(INV:CategoryName('Armor'), 'Plate', 'an empty name is refused')
	eq(status:GetText(), 'Enter a name.', 'the status line says why')
	enter(tab():EditorCell('name').widget.frame, 'weapons')
	eq(INV:CategoryName('Armor'), 'Plate', "another category's name is refused, in any case")
	eq(status:GetText(), 'Another category is already called Weapons.', 'and says which')
	local list = INV:GetCategoryList()
	local seen = {}
	for _, entry in ipairs(list) do
		local name = entry.name:lower()
		check(not seen[name], 'no two rows have one name: ' .. entry.name)
		seen[name] = true
	end
	enter(tab():EditorCell('name').widget.frame, 'PLATE')
	eq(INV:CategoryName('Armor'), 'PLATE', 'its own name in another case is fine')
	eq(status:GetText(), '', 'with no complaint')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('Delete asks first; the selection moves to the next category', function()
	world()
	INV.categoryEditor.selected = 'Toys'
	open()
	local list = INV:GetCategoryList()
	local place = list.byId.Toys.place
	local after = list[place + 1].id
	click(tab():EditorCell('delete').widget.frame)
	eq(W.ConfirmText(), 'Delete Toys? You can bring it back with + New category > Restore a default..., or Reset all.', 'it asks')
	no()
	check(INV:GetCategoryList().byId.Toys ~= nil, 'No keeps it')
	click(tab():EditorCell('delete').widget.frame)
	yes()
	eq(INV:GetCategoryList().byId.Toys, nil, 'Yes deletes it')
	eq(INV.categoryEditor.selected, after, 'the selection moves to the category now in its place')
	local w = tab()
	check(row_of(w, after).tint:IsShown(), 'in the list')
	eq(w:EditorCell('name').widget.frame:GetText(), INV:CategoryName(after), 'and the editor')

	-- One of yours, last above Miscellaneous: its pins go back to the rules.
	local mine = INV:AddUserCategory()
	INV:PinItem(301, mine)
	INV.categoryEditor.selected = mine
	OW:Render()
	click(tab():EditorCell('delete').widget.frame)
	eq(W.ConfirmText(), 'Delete New category? Items pinned to it go back to the rules.', 'it asks')
	yes()
	eq(INV:GetCategoryList().byId[mine], nil, 'deleted')
	eq(INV:GetPin(301), nil, 'its pin is gone')
	eq(INV.categoryEditor.selected, MISC, 'Miscellaneous is in its place now')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('Reset <name> to default clears the edit and keeps the pins; the edited marker goes', function()
	world()
	INV:RenameCategory('Armor', 'Plate')
	INV:SetCategoryEnabled('Armor', false)
	INV:SetCategoryHidden('bank', 'Armor', true)
	INV:PinItem(301, 'Armor')
	INV.categoryEditor.selected = 'Armor'
	open()
	local reset = tab():EditorCell('reset')
	eq(reset.widget.text:GetText(), 'Reset Plate to default', 'named by its name')
	check(not reset.widget:IsDisabled(), 'on for an edited default')
	eq(row_of(tab(), 'Armor').marker:GetText(), 'edited', 'marked edited')
	click(reset.widget.frame)
	eq(W.ConfirmText(), nil, 'it asks nothing')
	eq(INV:CategoryStore().edits.Armor, nil, 'the edit is cleared')
	eq(INV:CategoryName('Armor'), 'Armor', 'its shipped name')
	eq(INV:GetCategoryList().byId.Armor.enabled, true, 'on')
	eq(INV:IsCategoryHidden('bank', 'Armor'), false, 'Show in as shipped')
	eq(INV:GetPin(301), 'Armor', 'its pins stay')
	local w = tab()
	local row = row_of(w, 'Armor')
	check(not row.marker:IsShown(), 'the edited marker is gone')
	eq(row.name:GetText(), 'Armor', 'the list shows the shipped name')
	check(not row.strike:IsShown(), 'and it is on')
	reset = w:EditorCell('reset')
	eq(reset.widget.text:GetText(), 'Reset Armor to default', 'Reset takes the name back')
	check(reset.widget:IsDisabled(), 'and is off: nothing to reset')
	eq(icon_ids(w:EditorCell('pins').widget), '301', 'the pin still shows')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('Caught now shows the items the category catches now; hovering one highlights the block that caught it', function()
	world()
	INV.categoryEditor.selected = SELL
	open()
	local w = tab()
	local caught = w:EditorCell('caught')
	check(caught.label:IsShown(), 'titled')
	eq(caught.label:GetText(), 'Caught now', 'Caught now')
	local items = caught.widget
	eq(icon_ids(items), '502', 'the gray cloth')
	local icon = icons(items)[1]
	eq(icon:GetWidth(), 30, 'an icon is 30 square')
	eq(icon.texture:GetTexture(), 1, "the item's icon")
	check(icon.texture.backdrop ~= nil, "with a border in SaftUI's theme")
	check(not icon.remove:IsShown(), 'no X: these are not pins')

	local editor = w:EditorCell('rule').widget
	local function tinted()
		local out = {}
		for _, row in ipairs(editor.rows) do
			if row.tint:IsShown() then out[#out + 1] = row.kind .. '{' .. table.concat(row.path, ',') .. '}' end
		end
		return table.concat(out, ' ')
	end
	eq(tinted(), '', 'nothing highlighted')
	stub.fire_script(icon, 'OnEnter')
	check(GameTooltip:IsOwned(icon), 'its tooltip')
	eq(stub.state(GameTooltip).texts[1], 'bag item 0 2', 'the item in its bag slot')
	eq(tinted(), 'block{1,1}', 'the block that caught it: Quality is Poor')
	stub.fire_script(icon, 'OnLeave')
	eq(tinted(), '', 'gone when the mouse leaves')
	check(not GameTooltip:IsShown(), 'with the tooltip')

	-- Two items; and the sets entry catches every set's.
	INV.categoryEditor.selected = 'Trade Goods'
	OW:Render()
	eq(icon_ids(tab():EditorCell('caught').widget), '301,302', 'the plank and the board')
	INV.categoryEditor.selected = SETS
	OW:Render()
	eq(icon_ids(tab():EditorCell('caught').widget), '601', 'the mace in the Heal set')
	INV.categoryEditor.selected = 'Armor'
	OW:Render()
	eq(icon_ids(tab():EditorCell('caught').widget), '', 'none')

	-- What INV:CountCategories gives, by key.
	local counts, byKey = INV:CountCategories('bag')
	eq(counts['Trade Goods'], 2, 'counts by key')
	eq(counts['Set: Heal'], 1, "a set's key")
	eq(byKey[SELL][1].itemID, 502, 'and the items')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('pinned items show, and the X unpins one', function()
	world()
	INV:PinItem(301, 'Consumables') -- the plank, in the bags
	INV:PinItem(999, 'Consumables') -- not in the bags
	INV.categoryEditor.selected = 'Consumables'
	open()
	local pins = tab():EditorCell('pins')
	check(pins.label:IsShown(), 'titled')
	eq(pins.label:GetText(), 'Pinned items', 'Pinned items')
	eq(icon_ids(pins.widget), '301,999', 'both pins')
	local plank, other = icons(pins.widget)[1], icons(pins.widget)[2]
	check(plank.remove:IsShown(), 'each with an X')
	eq(plank.remove.icon:GetTexture(), st.textures.close, 'the close texture')
	stub.fire_script(plank, 'OnEnter')
	eq(stub.state(GameTooltip).texts[1], 'bag item 0 3', 'one in the bags shows its bag slot')
	stub.fire_script(plank, 'OnLeave')
	stub.fire_script(other, 'OnEnter')
	eq(stub.state(GameTooltip).texts[1], 'item 999', 'one that is not, its item')
	stub.fire_script(other, 'OnLeave')
	eq(icon_ids(tab():EditorCell('caught').widget), '101,301', 'a pinned item in the bags is caught too')

	click(plank.remove)
	eq(INV:GetPin(301), nil, 'the X unpins it')
	eq(icon_ids(tab():EditorCell('pins').widget), '999', 'and it leaves the row')
	click(icons(tab():EditorCell('pins').widget)[1].remove)
	eq(INV:GetPin(999), nil, 'unpinned')
	eq(tab():EditorCell('pins'), nil, 'no pins: no row')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('the rule editor fits its pane: a long row wraps, every field clear of the X', function()
	world()
	-- Grays/Auto Vendor's Old gear for my level, and another two groups deep.
	local rule = R.Copy(INV:GetCategoryList().byId[SELL].rule)
	table.insert(rule.items[1].items[3].items, { op = 'or', items = { { block = 'oldgear', levels = 10, expansion = 9, share = 0.9 } } })
	INV:SetCategoryRule(SELL, rule)
	INV.categoryEditor.selected = SELL
	open()
	local w = tab()
	local editor = w:EditorCell('rule').widget
	eq(editor.frame:GetWidth(), 540, "the pane's width")
	eq(editor.frame:GetRight(), w.frame:GetRight(), 'at the right of the tab')
	local oldGear, top = 0, editor.frame:GetTop()
	for i, row in ipairs(editor.rows) do
		local f = row.frame
		eq(top - f:GetTop(), i == 1 and 0 or (top - editor.rows[i - 1].frame:GetBottom()), 'row ' .. i .. ' right under the one before')
		eq(f:GetHeight() % 26, 0, 'row ' .. i .. ' is lines of 26')
		if type(row.node) == 'table' and row.node.block == 'oldgear' then
			oldGear = oldGear + 1
			check(f:GetHeight() > 26, 'row ' .. i .. ': Old gear wraps onto another line')
		end
		local limit = row.remove:IsShown() and row.remove:GetLeft() or f:GetRight()
		local function fits(region, right, what)
			check(right <= limit, 'row ' .. i .. ': ' .. what .. ' ends before the X')
			check(region:GetLeft() >= f:GetLeft(), 'row ' .. i .. ': ' .. what .. ' starts in the row')
			check(region:GetBottom() >= f:GetBottom() and region:GetTop() <= f:GetTop(), 'row ' .. i .. ': ' .. what .. ' in the row')
		end
		for name, control in pairs(row.fields) do
			if control:IsShown() then
				if control.GetUnboundedStringWidth then
					fits(control, control:GetLeft() + control:GetUnboundedStringWidth(), name)
				else
					fits(control, control:GetRight(), name)
				end
				if control.caption then
					fits(control.caption, control.caption:GetLeft() + control.caption:GetUnboundedStringWidth(), name .. "'s caption")
				end
			end
		end
		for _, caption in ipairs(row.captions) do
			fits(caption, caption:GetLeft() + caption:GetUnboundedStringWidth(), 'a caption')
		end
	end
	eq(oldGear, 2, 'both Old gear rows were looked at')
	eq(editor.frame:GetHeight(), top - editor.rows[#editor.rows].frame:GetBottom(), 'the editor is as tall as its rows')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ scrolling

-- A rule of id's with n more Name blocks: an editor taller than the tab.
local function tall_rule(id, n)
	local rule = R.Copy(INV:GetCategoryList().byId[id].rule)
	for i = 1, n do rule.items[#rule.items + 1] = { block = 'name', text = 'Item ' .. i } end
	INV:SetCategoryRule(id, rule)
end

test("the tab fills the body's view: the list and the editor each scroll on their own, with a bar only when there's something to scroll", function()
	world()
	INV.categoryEditor.selected = SETS -- the first row: the list opens at its top
	open()
	local F = OW.GetFrames()
	local w = tab()
	local c = cell('categories')
	local view = F.body:GetHeight()
	eq(c.y + c.height + 24, view, "the tab reaches down the body's view, less its bottom padding")
	eq(F.content:GetHeight(), view, 'so the body has nothing to scroll')
	check(not F.bar:IsShown(), 'and no bar')
	local height = w.frame:GetHeight()
	eq(height, c.height - 12, 'the tab is its cell less the padding')
	local top, left = w.frame:GetTop(), w.frame:GetLeft()

	-- The list: its rows in a view from the tab's top, its footer under it.
	local rows = #w.rows * 22
	check(rows > height, 'the shipped list is longer than the tab')
	eq(w.listScroll:GetScrollChild(), w.list, 'the rows scroll in the list')
	eq(w.listScroll:GetTop(), top, 'from the top')
	eq(w.listScroll:GetLeft(), left, 'at the left')
	eq(w.listScroll:GetWidth(), 210, '210 wide')
	eq(w.listScroll:GetHeight(), height - 30, 'down to its footer: 8, then a row of 22')
	eq(w.listScroll:GetBottom() - w.addButton:GetTop(), 8, '+ New category 8 under it')
	eq(w.addButton:GetBottom(), w.frame:GetBottom(), 'at the bottom of the tab')
	local bar = w.listBar
	local shown = w.listScroll:GetHeight()
	check(bar:IsShown(), 'a bar: the list has more than it shows')
	eq(bar:GetWidth(), 3, '3 wide')
	eq(bar:GetLeft() - w.listScroll:GetRight(), 4, '4 to its right')
	check(bar:GetRight() < w.divider:GetLeft(), 'short of the divider')
	eq(bar:GetTop(), top, 'at the top')
	eq(bar:GetHeight(), math.max(20, math.floor(shown * shown / rows)), 'as tall as the share of the list it shows')
	check(same_rgb(stub.state(bar).color_texture, { unpack(st.BOX_COLORS.edge) }), "in the body's bar's color")

	-- The editor: the tab's height from 234, 540 wide; Equipment sets' fits.
	eq(w.editorScroll:GetScrollChild(), w.pane, "the editor's rows scroll in it")
	eq(w.editorScroll:GetLeft() - left, 234, 'from 234')
	eq(w.editorScroll:GetWidth(), 540, '540 wide')
	eq(w.editorScroll:GetHeight(), height, 'the tab high')
	check(w.pane:GetHeight() < height, "Equipment sets' editor fits")
	check(not w.editorBar:IsShown(), 'no bar')
	eq(w.divider:GetHeight(), height, 'the divider down the whole tab')

	-- A rule taller than the tab: the editor's bar, 10 to its right, where the
	-- body's own would be, inside the body's clip.
	tall_rule('Toys', 25)
	INV.categoryEditor.selected = 'Toys'
	OW:Render()
	w = tab()
	check(w.pane:GetHeight() > height, "Toys' editor is taller than the tab")
	bar = w.editorBar
	check(bar:IsShown(), 'the editor has a bar')
	eq(bar:GetLeft() - w.editorScroll:GetRight(), 10, '10 to its right')
	eq(bar:GetLeft() - F.content:GetLeft(), 774 + 10, "where the body's own bar would be")
	check(bar:GetRight() <= F.body:GetRight(), "inside the body's clip")
	eq(bar:GetTop(), top, 'at the top')

	-- The wheel over one scrolls that one only.
	wheel(w.listScroll, 1, 50)
	eq(w.listScroll:GetVerticalScroll(), 0, 'the list at its top')
	wheel(w.listScroll, -1)
	eq(w.listScroll:GetVerticalScroll(), 66, 'the list: three rows a turn')
	eq(w.list:GetTop(), top + 66, 'its rows move up')
	check(w.listBar:GetTop() < top, 'its bar down')
	eq(w.editorScroll:GetVerticalScroll(), 0, 'the editor stays')
	eq(F.body:GetVerticalScroll(), 0, 'and the body')
	wheel(w.editorScroll, -1)
	eq(w.editorScroll:GetVerticalScroll(), 68, 'the editor: two of the body\'s rows a turn')
	eq(w.pane:GetTop(), top + 68, 'its rows move up')
	check(w.editorBar:GetTop() < top, 'its bar down')
	eq(w.listScroll:GetVerticalScroll(), 66, 'the list stays')
	wheel(w.listScroll, -1, 50)
	eq(w.listScroll:GetVerticalScroll(), rows - shown, 'no further down than its last row')
	eq(w.listBar:GetBottom(), w.listScroll:GetBottom(), 'its bar at the bottom')
	wheel(w.listScroll, 1, 50)
	eq(w.listScroll:GetVerticalScroll(), 0, 'nor up past its first')
	wheel(w.editorScroll, -1, 50)
	eq(w.editorScroll:GetVerticalScroll(), w.pane:GetHeight() - height, "the editor no further than its end")

	-- A list that fits: no bar, and its footer right under the last row.
	for _, entry in ipairs(INV:GetCategoryList()) do
		if #INV:GetCategoryList() * 22 + 30 <= height then break end
		if entry.kind == 'rule' and not entry.sells and entry.id ~= 'Toys' then INV:RemoveCategory(entry.id) end
	end
	OW:Render()
	w = tab()
	eq(w.listScroll:GetHeight(), #w.rows * 22, 'the view is the rows')
	check(not w.listBar:IsShown(), 'no bar')
	eq(w.rows[#w.rows].frame:GetBottom() - w.addButton:GetTop(), 8, '+ New category right under the last row')
	eq(w.listScroll:GetVerticalScroll(), 0, 'nothing scrolled')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('each pane keeps its scroll when the tab is drawn again; another category\'s editor starts at its top; the list brings the selected row into view when it changes', function()
	world()
	local list = INV:GetCategoryList()
	local far = list[#list - 1].id -- just above Miscellaneous
	tall_rule(far, 25)
	tall_rule('Toys', 25)

	-- Opened on a category far down: its row is brought into view.
	INV:EditCategory(far)
	local w = tab()
	check(in_view(w, row_of(w, far)), 'opened on a category far down the list: its row shows')
	eq(row_of(w, far).frame:GetBottom(), w.listScroll:GetBottom(), 'scrolled the least: at the bottom of the view')

	-- Scrolled away from it, the list stays put when the tab is drawn again.
	wheel(w.listScroll, 1, 50)
	check(not in_view(w, row_of(w, far)), 'scrolled away from it')
	wheel(w.editorScroll, -1, 2)
	eq(w.editorScroll:GetVerticalScroll(), 136, 'and the editor down two turns')
	B.put(0, 7, B.item(102, 'Elixir', 'Consumable', 30))
	INV:QueueUpdate()
	INV:UpdateHandler()
	tick()
	w = tab()
	eq(w.listScroll:GetVerticalScroll(), 0, 'a bag update draws the tab again: the list stays at its top')
	eq(w.editorScroll:GetVerticalScroll(), 136, 'and the editor where it was')
	click(w:EditorCell('enabled').widget.frame)
	eq(INV:GetCategoryList().byId[far].enabled, false, 'a change in the editor')
	w = tab()
	eq(w.editorScroll:GetVerticalScroll(), 136, 'draws it again where it was')
	eq(w.listScroll:GetVerticalScroll(), 0, 'and the list too')

	-- Asked for again (the slot menu's Edit this category): its row shows.
	INV:EditCategory(far)
	w = tab()
	check(in_view(w, row_of(w, far)), 'EditCategory brings the selected row back into view')

	-- Another category: its editor from its top; the list stays (its row shows).
	wheel(w.listScroll, 1, 50)
	local toys = row_of(w, 'Toys')
	check(in_view(w, toys), 'Toys shows')
	wheel(w.listScroll, -1)
	local offset = w.listScroll:GetVerticalScroll()
	check(in_view(w, row_of(w, 'Toys')), 'still')
	click(row_of(w, 'Toys').frame)
	w = tab()
	eq(INV.categoryEditor.selected, 'Toys', 'Toys selected')
	eq(w.editorScroll:GetVerticalScroll(), 0, 'its editor from the top')
	eq(w.listScroll:GetVerticalScroll(), offset, 'the list where it was')
	wheel(w.editorScroll, -1)
	click(row_of(w, far).frame) -- out of view, as a click from before a scroll
	w = tab()
	eq(w.editorScroll:GetVerticalScroll(), 0, 'back to the first one: its editor from the top too')
	check(in_view(w, row_of(w, far)), 'and its row shows')

	-- + New category: one more above Miscellaneous, selected, and shown.
	wheel(w.listScroll, 1, 50)
	click(w.addButton)
	w = tab()
	local new = INV.categoryEditor.selected
	eq(INV:GetCategoryList()[#INV:GetCategoryList() - 1].id, new, 'a new category above Miscellaneous')
	check(in_view(w, row_of(w, new)), 'its row shows')

	-- Restore a default: back in its place, selected, and shown.
	INV:RemoveCategory('Consumables')
	OW:Render()
	w = tab()
	wheel(w.listScroll, -1, 50)
	click(w.addButton)
	pick('Restore a default...')
	pick('Consumables')
	w = tab()
	eq(INV.categoryEditor.selected, 'Consumables', 'restored and selected')
	check(in_view(w, row_of(w, 'Consumables')), 'its row shows')

	-- A drag that moves the selected row out of view brings it back: the list
	-- scrolled so Toys is its top row, the row above it dropped below it.
	click(row_of(w, 'Toys').frame)
	w = tab()
	wheel(w.listScroll, 1, 50)
	local place = INV:GetCategoryList().byId.Toys.place
	-- Two turns down at most, then by hand to Toys' row exactly.
	INV.categoryEditor.listOffset = (place - 1) * 22
	OW:Render()
	w = tab()
	eq(row_of(w, 'Toys').frame:GetTop(), w.listScroll:GetTop(), 'Toys is the top row in view')
	local above = w.rows[place - 1]
	check(not in_view(w, above), 'the row above it is out of view')
	drag(above.handle, row_of(w, 'Toys').frame, true)
	eq(INV:GetCategoryList().byId.Toys.place, place - 1, 'Toys moved up a place')
	w = tab()
	check(in_view(w, row_of(w, 'Toys')), 'and is brought back into view')
	eq(row_of(w, 'Toys').frame:GetTop(), w.listScroll:GetTop(), 'scrolled the least: one row up')
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
	stub.fire_script(quest.handle, 'OnMouseDown', 'LeftButton')
	check(w.drag ~= nil, 'a drag')

	-- The line on the row under the cursor, where it is now.
	local target = w.rows[12]
	check(in_view(w, target), 'row 12 shows')
	cursor_on(target.frame, false)
	drag_frame(w)
	check(w.insert:IsShown(), 'the line shows')
	eq(w.insert:GetTop(), target.frame:GetTop() + 1, 'at the top of the row under the cursor, scrolled')

	-- The wheel mid-drag: the list scrolls, the drag goes on, the line follows.
	wheel(w.listScroll, 1)
	eq(w.listScroll:GetVerticalScroll(), 132, 'the wheel scrolls the list mid-drag')
	check(w.drag ~= nil, 'the drag goes on')
	target = w.rows[9]
	cursor_on(target.frame, false)
	drag_frame(w)
	eq(w.insert:GetTop(), target.frame:GetTop() + 1, "the line on the row now under the cursor")

	-- Held near the bottom edge it scrolls down, near the top up; not between.
	-- 264 (12 rows) a second: 33 in an eighth, 16.5 in a sixteenth.
	local scroll = w.listScroll
	local scale = scroll:GetEffectiveScale()
	local function cursor_at(x, y) stub.cursor_x, stub.cursor_y = x * scale, y * scale end
	local x = scroll:GetLeft() + 50
	cursor_at(x, scroll:GetBottom() + 5)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 33, 'near the bottom: down, 33 in an eighth of a second')
	drag_frame(w, 0.0625)
	eq(scroll:GetVerticalScroll(), 132 + 33 + 16, 'a sixteenth: 16, in whole units')
	drag_frame(w, 0.0625)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'and the half left over goes into the next')
	cursor_at(x, scroll:GetBottom() - 10)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 99, 'a little past the edge too')
	check(not w.insert:IsShown(), 'out of the view: no line')
	cursor_at(x, scroll:GetTop() - 5)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'near the top: up')
	cursor_at(x, (scroll:GetTop() + scroll:GetBottom()) / 2)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'in the middle: still')
	cursor_at(scroll:GetRight() + 40, scroll:GetBottom() + 5)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'beside the list: still')
	cursor_at(x, scroll:GetTop() + 40)
	drag_frame(w, 0.125)
	eq(scroll:GetVerticalScroll(), 132 + 66, 'well above it: still')

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

------------------------------------------------------------------ live

test('a bag update while the tab is open refreshes its counts', function()
	world()
	open()
	check(INV.categoriesTabShown, 'the tab is shown')
	eq(row_of(tab(), 'Consumables').count:GetText(), '1', 'one consumable')
	B.put(0, 7, B.item(102, 'Elixir', 'Consumable', 30))
	INV:QueueUpdate()
	INV:UpdateHandler()
	tick()
	eq(row_of(tab(), 'Consumables').count:GetText(), '2', 'the update reached the open tab')

	-- Another tab, or /sui closed: nothing is drawn for a bag update.
	local refreshes = 0
	local refresh = st.Config.Refresh
	st.Config.Refresh = function(...)
		refreshes = refreshes + 1
		return refresh(...)
	end
	OW:Navigate('Inventory', { tab = 'general' })
	check(not INV.categoriesTabShown, 'another tab: not shown')
	INV:QueueUpdate()
	INV:UpdateHandler()
	eq(refreshes, 0, 'a bag update leaves /sui alone')
	open()
	check(INV.categoriesTabShown, 'back on it')
	st.Config:Close()
	check(not INV.categoriesTabShown, 'closed: not shown')
	INV:QueueUpdate()
	INV:UpdateHandler()
	eq(refreshes, 0, 'nor with /sui closed')
	st.Config.Refresh = refresh
	eq(#take_errors(), 0, 'no errors')
end)

test("a draw of the tab reads the bags once, and uses up none of an item's tooltip tries", function()
	world()
	local slow = B.item(701, 'Slow Scroll', 'Consumable', 1, { tooltipLoading = true })
	B.put(0, 8, slow)
	INV:UpdateContainer('bag', true)
	local link = B.link(slow)
	local tries = INV.tooltipTries[link]
	check(tries ~= nil and tries >= 1, "the bag window's read counts a try while the tooltip loads")
	INV:PinItem(301, 'Consumables')
	INV.categoryEditor.selected = 'Consumables'
	local reads = 0
	local read = INV.ReadBags
	INV.ReadBags = function(...)
		reads = reads + 1
		return read(...)
	end
	open()
	eq(reads, 1, 'one read of the bags for a draw: the counts, Pinned items and Caught now')
	check(tab():EditorCell('pins') ~= nil and tab():EditorCell('caught') ~= nil, 'with both item strips drawn')
	OW:Render()
	OW:Render()
	eq(reads, 3, 'and one for each draw after')
	INV.ReadBags = read
	eq(INV.tooltipTries[link], tries, 'no try used up by the draws')
	INV:UpdateContainer('bag', true)
	eq(INV.tooltipTries[link], tries + 1, "the bag window's own read still counts one")
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('EditCategory opens the tab with the category selected, the sets entry for a set', function()
	world()
	INV:EditCategory('Consumables')
	check(OW:IsShown(), '/sui opens')
	eq(OW:GetState().page, 'Inventory', 'on Bags')
	eq(OW:GetState().tab, 'categories', 'on the Categories tab')
	eq(INV.categoryEditor.selected, 'Consumables', 'with the category selected')
	check(row_of(tab(), 'Consumables').tint:IsShown(), 'in the list')
	eq(tab():EditorCell('name').widget.frame:GetText(), 'Consumables', 'and the editor')
	INV:EditCategory('Set: Heal')
	eq(INV.categoryEditor.selected, SETS, "a set's key selects the sets entry")
	check(row_of(tab(), SETS).tint:IsShown(), 'in the list')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a profile switch with the tab open selects a category of the new profile', function()
	world()
	local mine = INV:AddUserCategory()
	INV.categoryEditor.selected = mine
	open()
	check(row_of(tab(), mine).tint:IsShown(), 'yours is selected')
	st.config:SetProfile('Other')
	tick()
	local list = INV:GetCategoryList()
	eq(list.byId[mine], nil, 'the new profile has no such category')
	eq(INV.categoryEditor.selected, list[1].id, 'the first category is selected')
	local w = tab()
	eq(#w.rows, #list, "the new profile's list")
	check(w.rows[1].tint:IsShown(), 'in the list')
	eq(w:EditorCell('name').widget.frame:GetText(), list[1].name, 'and the editor')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)
