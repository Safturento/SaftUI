-- The Categories tab in /sui > Bags (SaftUI-Bags/categoriestab.lua), the list on
-- the left: the Bags page's Categories tab, the list with its handles, counts
-- and markers, + New category, Reset all, the list under Blizzard, and the open
-- tab following bag updates, EditCategory (INV:EditCategory) and a profile
-- switch.
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
local cell, open, rgb, SETS, same_rgb = CW.cell, CW.open, CW.rgb, CW.SETS, CW.same_rgb
local MISC, click, tab, SELL, row_of = CW.MISC, CW.click, CW.tab, CW.SELL, CW.row_of
local pick, yes, no, ids, cursor_on = CW.pick, CW.yes, CW.no, CW.ids, CW.cursor_on
local drag_frame, tick = CW.drag_frame, CW.tick

local function drawn()
	local out = {}
	for i, c in ipairs(OW.GetDrawnRows()) do out[i] = c.row.key end
	return table.concat(out, ',')
end

-- The open list's labels, and a click on one of them.
local function list_labels()
	local out = {}
	for i, entry in ipairs(W.GetListFrames().entries or {}) do out[i] = entry.label end
	return table.concat(out, ',')
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
	local pinned = st.config.profile.theme.accent -- a non-default accent: a literal blue fails
	pinned:SetRGB(0.9, 0.1, 0.2)
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
	check(same_rgb({ row_of(w, SELL).count:GetTextColor() }, rgb('text', 'muted')), 'counts are grey')
	local consumables = row_of(w, 'Consumables')
	eq(consumables.count:GetRight(), consumables.frame:GetRight() - 8, 'at the right')

	-- Markers: an edited default, and one of yours.
	local wood = row_of(w, 'Trade Goods')
	eq(wood.name:GetText(), 'Wood', 'a renamed default shows its name')
	check(wood.marker:IsShown(), 'an edited default has a marker')
	eq(wood.marker:GetText(), 'edited', 'edited')
	check(same_rgb({ wood.marker:GetTextColor() }, rgb('text', 'muted')), 'the edited marker is Muted (a listed change from orange)')
	check(wood.marker:GetLeft() >= wood.name:GetLeft() + wood.name:GetWidth(), 'after the name')
	eq(row_of(w, mine).marker:GetText(), 'yours', 'one of yours')
	do -- the handle's six dots are Muted
		local dots = 0
		for _, region in ipairs({ wood.handle:GetRegions() }) do
			local color = region:GetObjectType() == 'Texture' and stub.state(region).color_texture
			if color then
				dots = dots + 1
				check(same_rgb(color, rgb('text', 'muted')), 'a handle dot is Muted')
			end
		end
		eq(dots, 6, 'six dots')
	end
	check(same_rgb({ row_of(w, mine).marker:GetTextColor() }, rgb('text', 'muted')), 'and so is the yours marker')
	check(not row_of(w, 'Armor').marker:IsShown(), 'a default as shipped has none')

	-- Off: grey, with a line through its name.
	local quest = row_of(w, 'Quest')
	check(quest.strike:IsShown(), 'a category that is off is struck through')
	eq(quest.strike:GetHeight(), 1, 'by a 1px line')
	eq(quest.strike:GetLeft(), quest.name:GetLeft(), 'from the start of its name')
	eq(quest.strike:GetWidth(), quest.name:GetWidth(), 'across it')
	check(same_rgb(stub.state(quest.strike).color_texture, rgb('text', 'muted')), 'in Muted')
	check(same_rgb({ quest.name:GetTextColor() }, rgb('text', 'muted')), 'its name is grey')
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
	check(same_rgb(stub.state(consumables.bar).color_texture, rgb('accent')), 'the accent')

	-- A handle on every row but Miscellaneous.
	for _, row in ipairs(w.rows) do
		eq(row.handle:IsShown(), row.id ~= MISC, row.id .. ': a handle unless Miscellaneous')
	end

	-- Under the list: + New category, in blue, under its view (the shipped list
	-- is longer than it shows; see the scrolling tests). The order's reset icon
	-- is not there while the order is as shipped.
	eq(w.addButton.text:GetText(), '+ New category', '+ New category')
	check(same_rgb({ w.addButton.text:GetTextColor() }, rgb('accent')), 'in blue')
	eq(w.listScroll:GetBottom() - w.addButton:GetTop(), 8, "8 under the list's view")
	check(not w.resetOrder:IsShown(), "no order's reset at the shipped order")
	eq(w.resetButton, nil, 'no Reset all')

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
	pinned:SetRGB(0, 0.68, 0.94)
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

test("the order's reset: shown once a shipped category moves, it puts SaftUI's order back with your own where they are", function()
	world()
	local shipped = INV:GetCategoryList()
	local shippedIds = {}
	for i, entry in ipairs(shipped) do shippedIds[i] = entry.id end
	INV:RenameCategory('Armor', 'Plate') -- an edit of another field is no difference of order
	INV:PinItem(301, 'Consumables')
	check(not INV:CategoryOrderDiffers(), 'a rename leaves the order as shipped')
	local mine = INV:AddUserCategory()
	check(not INV:CategoryOrderDiffers(), 'so does a category of your own, last above Miscellaneous')
	INV:MoveCategory('Toys', INV:GetCategoryList().byId.Reputation.place)
	INV:MoveCategory(mine, INV:GetCategoryList().byId.Toys.place + 1) -- right after Toys
	local at = INV:GetCategoryList().byId
	check(at.Toys.place < at.Reputation.place and at[mine].place == at.Toys.place + 1, 'Toys is above Reputation now, yours right after it')
	check(INV:CategoryOrderDiffers(), 'the order differs')
	open()
	local w = tab()
	check(w.resetOrder:IsShown(), "the order's reset shows")
	eq(w.resetButton, nil, 'there is no Reset all')
	check(same_rgb({ w.resetOrder.icon:GetVertexColor() }, rgb('text', 'muted')), 'in Text > Muted at rest')
	check(w.resetOrder:GetLeft() > w.addButton:GetRight(), 'after + New category')
	local tip, saved = { lines = {} }, _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines = {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		Show = function() end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner = nil end,
	}
	stub.fire_script(w.resetOrder, 'OnEnter')
	eq(tip.owner, w.resetOrder, 'it has a tooltip')
	eq(table.concat(tip.lines, ' | '), "Reset | Order goes back to its default: SaftUI's order, with your own categories where they are.", 'its words')
	check(same_rgb({ w.resetOrder.icon:GetVertexColor() }, rgb('accent')), 'the accent under the mouse')
	stub.fire_script(w.resetOrder, 'OnLeave')
	_G.GameTooltip = saved
	eq(tip.owner, nil, 'the tooltip goes')
	check(same_rgb({ w.resetOrder.icon:GetVertexColor() }, rgb('text', 'muted')), 'and Muted again')

	click(w.resetOrder)
	eq(W.ConfirmText(), nil, 'it asks nothing')
	local now = {}
	for i, entry in ipairs(INV:GetCategoryList()) do now[i] = entry.id end
	local want = {}
	for _, id in ipairs(shippedIds) do
		if id ~= MISC then want[#want + 1] = id end
		if id == 'Toys' then want[#want + 1] = mine end
	end
	want[#want + 1] = MISC
	eq(table.concat(now, ','), table.concat(want, ','), "SaftUI's order, yours right after Toys, Miscellaneous last")
	check(not INV:CategoryOrderDiffers(), 'the order is the default')
	eq(INV:CategoryName('Armor'), 'Plate', 'a rename stays')
	eq(INV:GetPin(301), 'Consumables', 'a pin stays')
	w = tab()
	check(not w.resetOrder:IsShown(), 'the icon goes')
	eq(#w.rows, #INV:GetCategoryList(), 'the list is drawn again')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ the editor's footer

test("under Blizzard the category list is the Settings category list; its handles, counts, markers and drop line stay", function()
	local function px(a, b) return string.format('%d', math.floor(a - b + 0.5)) end
	local function around(outer, inner)
		return table.concat({ px(outer:GetLeft(), inner:GetLeft()), px(outer:GetTop(), inner:GetTop()),
			px(outer:GetRight(), inner:GetRight()), px(outer:GetBottom(), inner:GetBottom()) }, ',')
	end
	local function color(fs) return string.format('%.2f,%.2f,%.2f', fs:GetTextColor()) end
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		INV:SetCategoryEnabled('Quest', false)
		INV.categoryEditor.selected = 'Consumables'
		st.config.profile.theme.name = 'blizzard'
		st:ThemeChanged()
		open()
		local w = tab()
		local grey = string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.muted:GetRGB())
		local sel, other, off = row_of(w, 'Consumables'), row_of(w, SETS), row_of(w, 'Quest')
		eq(sel.tint:GetAtlas(), 'Options_List_Active', client .. ': the picked row on the active art')
		eq(around(sel.tint, sel.frame), '0,0,0,0', client .. ': filling the row')
		check(not sel.bar:IsShown(), client .. ': no blue bar')
		eq(color(sel.name), '1.00,1.00,1.00', client .. ': the picked name is white')
		eq(color(other.name), '1.00,0.82,0.00', client .. ': the others are gold')
		check(not other.tint:IsShown(), client .. ': not tinted')
		local tinted = {}
		for _, row in ipairs(w.rows) do
			if row.frame:IsShown() and row.tint:IsShown() then tinted[#tinted + 1] = row.id end
		end
		eq(table.concat(tinted, ','), 'Consumables', client .. ': only the picked row on the active art')
		stub.fire_script(other.frame, 'OnEnter')
		eq(other.frame.hover:GetAtlas(), 'Options_List_Hover', client .. ': the hover art')
		check(other.frame.hover:IsShown(), client .. ': shown')
		stub.fire_script(other.frame, 'OnLeave')
		eq(color(off.name), grey, client .. ': an off category is grey')
		check(off.strike:IsShown(), client .. ': and struck through')
		check(sel.handle:IsShown(), client .. ': the handle stays')
		eq(color(sel.count), grey, client .. ': counts stay grey')
		eq(sel.frame:GetWidth() .. 'x' .. sel.frame:GetHeight(), '210x22', client .. ': the row is the same size')

		-- A drag still draws the drop line.
		local handle = row_of(w, 'Armor').handle
		stub.mouse_buttons.LeftButton = true
		stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
		cursor_on(sel.frame, true)
		drag_frame(w)
		check(w.insert:IsShown(), client .. ': the drop line')
		stub.mouse_buttons.LeftButton = nil
		stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
		INV.categoryEditor.selected = 'Consumables'
		OW:Render()

		-- Thick: as before.
		st.config.profile.theme.name = 'thick'
		st:ThemeChanged()
		OW:Render()
		w = tab()
		sel = row_of(w, 'Consumables')
		eq(sel.tint:GetAtlas(), nil, client .. ': Thick: a color tint')
		check(sel.tint:IsShown() and sel.bar:IsShown(), client .. ': Thick: the blue tint and bar')
		check(same_rgb({ sel.name:GetTextColor() }, rgb('text', 'normal')), client .. ': Thick: the normal text color')
		check(same_rgb(stub.state(sel.bar).color_texture, rgb('accent')), client .. ': Thick: the accent')
		local hover = row_of(w, SETS).frame.hover
		stub.fire_script(row_of(w, SETS).frame, 'OnEnter')
		eq(hover:GetAtlas(), nil, client .. ': Thick: no hover art')
		check(hover:IsShown(), client .. ': Thick: the hover shows')
		local c = stub.state(hover).color_texture
		check(same_rgb(c, rgb('accent')), client .. ': Thick: an accent hover')
		eq(c[4], st.TINT_ROW, client .. ': at the row tint, the same as the selected row')
		eq(c[4], 0.25, client .. ': 25%')
		eq(stub.state(sel.tint).color_texture[4], st.TINT_ROW, client .. ': the selected row at the row tint')
		eq(hover:GetAlpha(), 1, client .. ': its alpha in its color')
		stub.fire_script(row_of(w, SETS).frame, 'OnLeave')
		check(not hover:IsShown(), client .. ': Thick: gone when the mouse leaves')
		eq(#take_errors(), 0, client .. ': no errors')
		st.Config:Close()
	end
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
