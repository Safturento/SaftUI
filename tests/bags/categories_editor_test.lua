-- The category editor in /sui > Bags > Categories (SaftUI-Bags/categoriestab.lua
-- and ruleeditor.lua, INV:CategoryEditorOptions, the bagitems widget): its rows,
-- Name, Delete, the fields' own resets, Caught now and Pinned items with their
-- tooltips beside the window, and the rule editor fitting its pane.
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
local SETS, MISC, editor_keys, tab, inside = CW.SETS, CW.MISC, CW.editor_keys, CW.tab, CW.inside
local SELL, open, row_of, yes, no = CW.SELL, CW.open, CW.row_of, CW.yes, CW.no
local click, icons, tick = CW.click, CW.icons, CW.tick

local function enter(box, text)
	box:SetText(text)
	stub.fire_script(box, 'OnEnterPressed')
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

------------------------------------------------------------------ the editor

test('the editor has its rows, each with a desc', function()
	world()
	load_test_file('lib/options_walk.lua')
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
		'caught:bagitems delete:execute enabled:toggle name:input pins:bagitems rule:bagrule show:multiselect',
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
	eq(args.reset, nil, 'no Reset button: each field has its own reset')
	eq(args.delete.name, 'Delete', 'Delete')
	eq(args.delete.desc, 'Delete this category. Its items go to the next category that catches them.', 'its desc')

	-- In this order.
	eq(editor_rows('Trade Goods'), 'name,enabled,show,rule,pins,caught,delete', 'in order')
	INV:UnpinItem(301)
	eq(editor_rows('Trade Goods'), 'name,enabled,show,rule,caught,delete', 'Pinned items only when there are some')

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

	-- Show in: Bags, Bank and Combined bank on Forever, which has no warband bank
	-- but opens the combined bank by default.
	local values = OM.Values(root, rows.show)
	local labels = {}
	for i, value in ipairs(values) do labels[i] = value.key .. '=' .. value.name end
	eq(table.concat(labels, ','), 'bag=Bags,bank=Bank,combinedbank=Combined bank', 'Bags, Bank and Combined bank on Forever')
	-- Unticking the window the bank is in (the combined bank by default) hides the category there.
	check(INV.config.combinedBank, 'the bank is combined by default')
	OM.Set(root, rows.show, 'combinedbank', false)
	eq(INV:IsCategoryHidden('combinedbank', 'Trade Goods'), true, 'Combined bank hides it in the bank the player sees')
	OM.Set(root, rows.show, 'combinedbank', true)
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
	eq(keys, 'name,enabled,show,note,caught', 'Equipment sets: a note in place of a rule, no Delete')
	eq(rows.note.type, 'description', 'the note is text')
	eq(rows.note.name, 'Makes a category for each equipment set, "Set: <name>", for the armor and weapons in it. It has no rule.', 'its words')
	keys, rows = editor_rows(MISC)
	eq(keys, 'name,show,note,caught', 'Miscellaneous: no On, no rule, no Delete')
	eq(rows.note.name, 'Catches every item no category above it catches. It is always last.', 'its words')
	keys, rows = editor_rows(SELL)
	eq(keys, 'name,enabled,show,rule,caught', 'Grays/Auto Vendor: no Delete')
	eq(rows.enabled.desc, 'Turned off, the items it would catch go to the next category that catches them. Turned off, auto vendor sells nothing.',
		'its On says what turning it off does')
	keys = editor_rows(mine)
	eq(keys, 'name,enabled,show,rule,caught,delete', 'yours')

	-- Drawn in the tab.
	INV.categoryEditor.selected = MISC
	open()
	local w = tab()
	eq(editor_keys(w), 'name,show,note', "Miscellaneous's editor in the tab")
	check(inside(w:EditorCell('caught').frame, w.footer), 'Caught now in its footer')
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
	eq(W.ConfirmText(), 'Delete Toys? You can bring it back with + New category > Restore a default...', 'it asks')
	no()
	check(INV:GetCategoryList().byId.Toys ~= nil, 'No keeps it')
	click(tab():EditorCell('delete').widget.frame)
	yes()
	eq(INV:GetCategoryList().byId.Toys, nil, 'Yes deletes it')
	eq(INV.categoryEditor.selected, after, 'the selection moves to the category now in its place')
	local w = tab()
	check(SaftUI:GetState(row_of(w, after).frame, 'selected') == true, 'in the list')
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

-- Delete floats under the editor's panel. The game reads a button's height
-- back a hair over its 26 (stub.size_noise plays it), and a plain ceil made a
-- line of such buttons 27 tall, a button half a unit down it, between two
-- pixels, its border blurred. The editor, its rows and buttons, and its
-- panels and lines sit on whole pixels, with the hair either way, with
-- Delete and without it.
local P = load_test_file('lib/pixels.lua')

test("the editor's Delete, and everything in the editor, sit on whole pixels", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		for _, noise in ipairs({ 0, 2 ^ -14, -2 ^ -14 }) do
			for _, id in ipairs({ 'Armor', 'Grays/Auto Vendor' }) do
				world()
				st.config.profile.theme.name = look
				stub.size_noise = noise
				local list = INV:GetCategoryList()
				for _, entry in ipairs(list) do
					if entry.name == id or entry.id == id then INV.categoryEditor.selected = entry.id end
				end
				open()
				local w = tab()
				local where = ('%s, noise %s, %s'):format(look, noise, id)
				check(w:EditorCell('name') ~= nil, where .. ': the editor drawn')
				for _, part in ipairs({ { 'the editor', w.pane }, { 'its footer', w.footerPane } }) do
					local off = P.off(part[2])
					eq(#off, 0, where .. ', ' .. part[1] .. ': ' .. P.report(off))
				end
				stub.size_noise = 0
				st.config.profile.theme.name = 'thick'
				st.Config:Close()
			end
		end
	end
end)

-- The reset icon a drawn editor row shows, or nil.
local function reset_icon(key)
	local icon = tab():EditorCell(key).frame.defaultReset
	return icon and icon:IsShown() and icon or nil
end

test("a shipped category's fields each reset alone; there is no Reset button", function()
	world()
	INV:RenameCategory('Toys', 'Fun')
	INV:SetCategoryEnabled('Toys', false)
	INV:SetCategoryHidden('bank', 'Toys', true)
	local rule = R.Copy(INV:GetDefaultCategory('Toys').rule)
	rule.items[#rule.items + 1] = { op = 'and', items = {} }
	INV:SetCategoryRule('Toys', rule)
	INV:PinItem(301, 'Toys')
	INV.categoryEditor.selected = 'Toys'
	open()
	eq(tab():EditorCell('reset'), nil, 'no Reset button')
	for _, key in ipairs({ 'name', 'enabled', 'show', 'rule' }) do
		check(reset_icon(key), key .. ' shows its reset')
	end
	-- The rule's sits 6 after the title's text, as the kit puts a titled row's.
	local ruleCell = tab():EditorCell('rule')
	local left = select(4, ruleCell.frame.defaultReset:GetPoint(1))
	eq(left, math.ceil(ruleCell.label:GetUnboundedStringWidth()) + 6, "the rule's icon sits 6 after 'Catches an item when'")
	-- Its tooltip is a sentence: the row's name is no subject.
	local rule_icon = reset_icon('rule')
	stub.fire_script(rule_icon, 'OnEnter')
	eq(stub.state(GameTooltip).texts[2], 'The rule goes back to its default: the rule SaftUI ships.', "the rule's reset words")
	stub.fire_script(rule_icon, 'OnLeave')

	-- Each one puts back its own and leaves the others.
	click(reset_icon('name'))
	eq(INV:CategoryName('Toys'), 'Toys', "the Name's reset brings the shipped name back")
	eq(INV:GetCategoryList().byId.Toys.enabled, false, 'and leaves it off')
	eq(INV:IsCategoryHidden('bank', 'Toys'), true, 'hidden in the bank')
	check(not reset_icon('name'), "the Name's icon goes")
	check(reset_icon('enabled') and reset_icon('show') and reset_icon('rule'), 'the others stay')
	click(reset_icon('enabled'))
	eq(INV:GetCategoryList().byId.Toys.enabled, true, "On's reset")
	click(reset_icon('show'))
	eq(INV:IsCategoryHidden('bank', 'Toys'), false, "Show in's reset")
	check(reset_icon('rule'), 'the rule still differs')
	click(reset_icon('rule'))
	check(R.Equal(INV:GetCategoryList().byId.Toys.rule, INV:GetDefaultCategory('Toys').rule), "the rule's reset puts the shipped rule back")
	eq(INV:CategoryStore().edits.Toys, nil, 'nothing of the edit is left')
	for _, key in ipairs({ 'name', 'enabled', 'show', 'rule' }) do
		check(not reset_icon(key), key .. ' shows none now')
	end
	eq(INV:GetPin(301), 'Toys', 'its pins stay')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("Show in's reset covers every window the category is hidden in, one the page does not list on Forever too", function()
	world()
	check(not INV:HasWarbandBank(), 'Forever has no warband bank: Show in lists Bags, Bank and Combined bank')
	INV.categoryEditor.selected = 'Toys'
	-- Hidden in the combined bank alone (the Edit view's checkbox, or a migrated profile).
	INV:SetCategoryHidden('combinedbank', 'Toys', true)
	open()
	check(reset_icon('show'), 'hidden only in the combined bank: Show in shows its reset')
	click(reset_icon('show'))
	eq(INV:IsCategoryHidden('combinedbank', 'Toys'), false, 'and puts it back')
	eq(INV:CategoryStore().edits.Toys, nil, 'nothing of the edit is left: Toys is not edited')
	-- Three windows at once: one reset clears them all.
	INV:SetCategoryHidden('bag', 'Toys', true)
	INV:SetCategoryHidden('bank', 'Toys', true)
	INV:SetCategoryHidden('combinedbank', 'Toys', true)
	OW:Render()
	click(reset_icon('show'))
	for _, window in ipairs({ 'bag', 'bank', 'combinedbank' }) do
		eq(INV:IsCategoryHidden(window, 'Toys'), false, window .. ' shown again')
	end
	eq(INV:CategoryStore().edits.Toys, nil, 'not edited')
	check(not reset_icon('show'), 'the icon goes')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("a default shown numbered because another category has its name has no Name reset: nothing of its own to reset", function()
	world()
	local mine = INV:AddUserCategory()
	INV:RenameCategory(mine, 'Toys')
	INV.categoryEditor.selected = 'Toys'
	open()
	eq(INV:CategoryStore().edits.Toys, nil, 'Toys has no name edit')
	check(not reset_icon('name'), 'so its Name shows no reset, whatever it is drawn as')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a name reset another category blocks', function()
	world()
	INV:RenameCategory('Toys', 'Fun')
	INV:SetCategoryEnabled('Toys', false)
	INV:SetCategoryHidden('bank', 'Toys', true)
	local mine = INV:AddUserCategory()
	INV:RenameCategory(mine, 'Toys')
	INV.categoryEditor.selected = 'Toys'
	open()
	click(reset_icon('name'))
	eq(INV:CategoryName('Toys'), 'Fun', "the name stays: another category has the shipped one")
	eq(OW.GetFrames().status:GetText(), 'Another category is already called Toys.', 'the status line says why')
	check(reset_icon('name'), 'the icon stays')
	eq(INV:GetCategoryList().byId.Toys.enabled, false, 'On is untouched')
	eq(INV:IsCategoryHidden('bank', 'Toys'), true, 'and Show in')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a category of your own has no field resets', function()
	world()
	local mine = INV:AddUserCategory()
	INV:RenameCategory(mine, 'Mine')
	INV:SetCategoryEnabled(mine, false)
	INV:SetCategoryHidden('bank', mine, true)
	INV.categoryEditor.selected = mine
	open()
	for _, key in ipairs({ 'name', 'enabled', 'show', 'rule' }) do
		check(not reset_icon(key), key .. ' shows no reset')
	end
	local _, rows = editor_rows(mine)
	for _, key in ipairs({ 'name', 'enabled', 'show', 'rule' }) do
		eq(rows[key].option.noReset, 'Your own category has no shipped version.', key .. ' says why')
	end
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

test("an item's tooltip opens beside the window, out of it, level with the icon's top: on its right, or its left when the right has no room", function()
	world()
	INV:PinItem(301, SELL) -- the plank: Grays/Auto Vendor has pins and catches the gray cloth
	INV.categoryEditor.selected = SELL
	open()
	local F = OW.GetFrames()
	local window = F.window
	local function tip_rect() return GameTooltip:GetLeft(), GameTooltip:GetRight(), GameTooltip:GetTop() end
	-- The game sizes the tooltip to its lines when it's shown; the stub's keeps
	-- the size it's given, so this one is given a tooltip's size by hand.
	GameTooltip:SetSize(300, 200)
	-- The strips are in the editor's footer, in view under its rule.
	local scroll = tab().footerScroll

	for _, key in ipairs({ 'caught', 'pins' }) do
		local icon = icons(tab():EditorCell(key).widget)[1]
		check(icon:GetTop() <= scroll:GetTop() and icon:GetBottom() >= scroll:GetBottom(), key .. ': the icon shows')
		stub.fire_script(icon, 'OnEnter')
		check(GameTooltip:IsOwned(icon), key .. ': its tooltip')
		eq(stub.state(GameTooltip).anchor, 'ANCHOR_NONE', key .. ': placed by hand, not by an anchor of the owner')
		local left, _, top = tip_rect()
		eq(left, window:GetRight() + 4, key .. ": 4 right of the window's edge")
		eq(top, icon:GetTop(), key .. ": its top level with the icon's")
		check(left > window:GetRight(), key .. ': out of the window, covering nothing in it')
		stub.fire_script(icon, 'OnLeave')
		check(not GameTooltip:IsShown(), key .. ': gone when the mouse leaves')
	end

	-- The window at the screen's right edge: no room there, so on its left.
	window:ClearAllPoints()
	window:SetPoint('RIGHT', UIParent, 'RIGHT', -20, 0)
	local icon = icons(tab():EditorCell('caught').widget)[1]
	stub.fire_script(icon, 'OnEnter')
	local _, right, top = tip_rect()
	eq(right, window:GetLeft() - 4, "on the left: 4 left of the window's edge")
	eq(top, icon:GetTop(), "its top level with the icon's")
	stub.fire_script(icon, 'OnLeave')

	-- Room for it on neither side: the side with more.
	window:ClearAllPoints()
	window:SetPoint('LEFT', UIParent, 'LEFT', 100, 0)
	GameTooltip:SetSize(1000, 200)
	stub.fire_script(icon, 'OnEnter')
	eq(GameTooltip:GetLeft(), window:GetRight() + 4, 'neither fits: the right, which has more room (the game keeps it on the screen)')
	stub.fire_script(icon, 'OnLeave')

	-- A tooltip at a scale of its own (a tooltip addon's): its edges, in
	-- UIParent's units, land in the same places, and its width on the screen
	-- is its scaled one. Whole tooltip units: within half of one.
	GameTooltip:SetScale(0.8)
	local function ui(v) return v * GameTooltip:GetEffectiveScale() / UIParent:GetEffectiveScale() end
	local function near(got, want, what)
		check(math.abs(got - want) <= 0.5, what .. ': expected ' .. tostring(want) .. ', got ' .. tostring(got))
	end
	GameTooltip:SetSize(300, 200)
	window:ClearAllPoints()
	window:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	stub.fire_script(icon, 'OnEnter')
	near(ui(GameTooltip:GetLeft()), window:GetRight() + 4, 'scaled, on the right: 4 right of the window')
	near(ui(GameTooltip:GetTop()), icon:GetTop(), "scaled: level with the icon's top")
	stub.fire_script(icon, 'OnLeave')
	window:ClearAllPoints()
	window:SetPoint('RIGHT', UIParent, 'RIGHT', -20, 0)
	stub.fire_script(icon, 'OnEnter')
	near(ui(GameTooltip:GetRight()), window:GetLeft() - 4, 'scaled, on the left: 4 left of the window')
	near(ui(GameTooltip:GetTop()), icon:GetTop(), "scaled: level with the icon's top")
	stub.fire_script(icon, 'OnLeave')
	-- 340 wide at 0.8 is 272 on the screen: it fits a room of 300 on the
	-- right, though 340 wouldn't and the left has more room.
	GameTooltip:SetSize(340, 200)
	window:ClearAllPoints()
	window:SetPoint('RIGHT', UIParent, 'RIGHT', -300, 0)
	check(window:GetLeft() > 300, 'more room on the left')
	stub.fire_script(icon, 'OnEnter')
	near(ui(GameTooltip:GetLeft()), window:GetRight() + 4, 'its scaled width fits on the right')
	stub.fire_script(icon, 'OnLeave')
	GameTooltip:SetScale(1)

	-- A width it can't read (a secret value): beside the icon, not wherever
	-- the last tooltip was. Driven by hand: GetWidth on this one tooltip, and
	-- issecretvalue, give a stand-in secret.
	local secret = newproxy(true)
	local realSecret = issecretvalue
	issecretvalue = function(v) return v == secret end
	GameTooltip.GetWidth = function() return secret end
	stub.fire_script(icon, 'OnEnter')
	GameTooltip.GetWidth, issecretvalue = nil, realSecret
	eq(GameTooltip:GetNumPoints(), 1, 'one anchor')
	local point, rel, relPoint, x, y = GameTooltip:GetPoint(1)
	check(point == 'TOPLEFT' and rel == icon and relPoint == 'TOPRIGHT' and x == 4 and y == 0, "at the icon's top right, 4 out")
	stub.fire_script(icon, 'OnLeave')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("under Blizzard an item's tooltip sits 4 out from the metal, which reaches past the window's edges", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		INV.categoryEditor.selected = SELL
		st.config.profile.theme.name = 'blizzard'
		st:ThemeChanged()
		open()
		local window = OW.GetFrames().window
		local reachLeft, reachRight = st.ThemeArt.MetalReach()
		eq(reachLeft .. ',' .. reachRight, client == 'forever' and '8,2' or '8,4', client .. ': the metal past the left and right edges')
		GameTooltip:SetSize(300, 200)
		local icon = icons(tab():EditorCell('caught').widget)[1]
		stub.fire_script(icon, 'OnEnter')
		eq(GameTooltip:GetLeft(), window:GetRight() + reachRight + 4, client .. ": on the right: 4 right of the metal's edge")
		eq(GameTooltip:GetTop(), icon:GetTop(), client .. ": level with the icon's top")
		stub.fire_script(icon, 'OnLeave')
		window:ClearAllPoints()
		window:SetPoint('RIGHT', UIParent, 'RIGHT', -20, 0)
		stub.fire_script(icon, 'OnEnter')
		eq(GameTooltip:GetRight(), window:GetLeft() - reachLeft - 4, client .. ": on the left: 4 left of the metal's edge")
		stub.fire_script(icon, 'OnLeave')

		-- Under Thick, 4 from the window's own edges again.
		st.config.profile.theme.name = 'thick'
		st:ThemeChanged()
		tick()
		window:ClearAllPoints()
		window:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		icon = icons(tab():EditorCell('caught').widget)[1]
		stub.fire_script(icon, 'OnEnter')
		eq(GameTooltip:GetLeft(), window:GetRight() + 4, client .. ': Thick: 4 right of the window')
		stub.fire_script(icon, 'OnLeave')
		eq(#take_errors(), 0, client .. ': no errors')
		st.Config:Close()
	end
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
	eq(plank.remove.icon:GetTexture(), st.icons.x, "Lucide's x")
	eq(plank.remove.icon:GetWidth(), 16, 'an 8 px cross in the middle of 16')
	local muted = CW.rgb('text', 'muted')
	check(CW.same_rgb({ plank.remove.icon:GetVertexColor() }, muted), "the X is Muted at rest")
	st.config.profile.colors.text.danger:SetRGB(0.9, 0.3, 0.1) -- not the default, so a hardcoded red fails
	stub.fire_script(plank.remove, 'OnEnter')
	check(CW.same_rgb({ plank.remove.icon:GetVertexColor() }, { 0.9, 0.3, 0.1 }), 'and Text > Danger under the mouse')
	stub.fire_script(plank.remove, 'OnLeave')
	check(CW.same_rgb({ plank.remove.icon:GetVertexColor() }, muted), 'Muted again')
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
	-- The editor's body draws its sections on panels, 14 in from each edge.
	eq(editor.frame:GetWidth(), 540 - 28, "the pane's width, inside the panel's padding")
	eq(editor.frame:GetRight(), w.frame:GetRight() - 14, 'at the right of the tab, inside the padding')
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

-- The reset walk over the editor's own options (a body of its own, not a page of the options tree): a
-- field added with no reset fails here. Each kind of category has its own rows.
test("every value row of the Categories editor has a reset, for a shipped category, the sets entry, Miscellaneous and your own", function()
	world()
	local RW = load_test_file('lib/reset_walk.lua')
	local mine = INV:AddUserCategory()
	local walked = 0
	for _, id in ipairs({ 'Trade Goods', SETS, MISC, SELL, mine }) do
		walked = walked + RW.check_page({ category = INV:CategoryEditorOptions(id) }, 'category')
	end
	check(walked >= 12, 'the walk met the editors\' rows (' .. walked .. ')')
end)
