-- The Categories tab in /sui > Bags (SaftUI-Bags/categoriestab.lua): the
-- bagcategories widget (the category list on the left, with its handles,
-- counts and markers, + New category and Reset all, and the selected
-- category's editor on the right), INV:CategoryEditorOptions, the bagitems
-- widget (Pinned items, Caught now), INV:CountCategories, INV:EditCategory,
-- and the open tab following bag updates and a profile switch.
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
-- ticker's OnUpdate, which the stubs never run by themselves, and a held
-- mouse button is stub.mouse_buttons.LeftButton.
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
	-- The game puts a scroll frame's child at its top left (less the scroll,
	-- none here); the stubbed scroll frame doesn't place it, so the rows'
	-- edges (and IsMouseOver, for a drag) can be read.
	local F = OW.GetFrames()
	if F.content:GetNumPoints() == 0 then F.content:SetPoint('TOPLEFT', F.body, 'TOPLEFT') end
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
	local top, left = w.frame:GetTop(), w.frame:GetLeft()
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

	-- Under the list: + New category and Reset all, in blue.
	eq(w.addButton.text:GetText(), '+ New category', '+ New category')
	eq(w.resetButton.text:GetText(), 'Reset all', 'Reset all')
	check(same_rgb({ w.addButton.text:GetTextColor() }, rgb('text', 'blue')), 'in blue')
	check(same_rgb({ w.resetButton.text:GetTextColor() }, rgb('text', 'blue')), 'both')
	local last = w.rows[#w.rows].frame
	eq(last:GetBottom() - w.addButton:GetTop(), 8, 'under the last row')
	check(w.resetButton:GetLeft() > w.addButton:GetRight(), 'side by side')

	-- The editor pane: from 234, 540 wide; the tab as tall as its taller pane.
	eq(w.pane:GetLeft() - left, 234, 'the editor starts at 234')
	eq(w.pane:GetWidth(), 540, 'and is 540 wide')
	local listHeight = top - w.addButton:GetBottom()
	eq(w.frame:GetHeight(), math.max(listHeight, w.pane:GetHeight()), 'as tall as the taller pane')
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

	-- Onto Miscellaneous's lower half: just above it, which stays last.
	w = tab()
	drag(row_of(w, 'Armor').handle, row_of(w, MISC).frame, true)
	list = INV:GetCategoryList()
	eq(list[#list].id, MISC, 'Miscellaneous is last')
	eq(list[#list - 1].id, 'Armor', 'Armor just above it')
	w = tab()
	check(not row_of(w, MISC).handle:IsShown(), 'Miscellaneous has no handle')

	-- Dropped where it is, or off the list: nothing moves.
	local order = ids()
	local toys = row_of(w, 'Toys')
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

	-- The list's drag.
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
