-- Scrolling in the Categories tab (SaftUI-Bags/categoriestab.lua): the list and
-- the editor each scrolling on their own, under Blizzard on its minimal scroll
-- bar, a bag update waiting while a thumb is held, the editor's fixed footer
-- (Caught now above Pinned items), and each pane keeping its scroll when the
-- tab is drawn again.
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
local wheel, SETS, tall_rule, same_rgb, cell = CW.wheel, CW.SETS, CW.tall_rule, CW.same_rgb, CW.cell
local tab, open, tick, row_of, inside = CW.tab, CW.open, CW.tick, CW.row_of, CW.inside
local editor_keys, icons, click, SELL, in_view = CW.editor_keys, CW.icons, CW.click, CW.SELL, CW.in_view
local pick = CW.pick

-- Whether a frame lies whole inside another's rect.
local function within(frame, outer)
	return frame:GetLeft() >= outer:GetLeft() and frame:GetRight() <= outer:GetRight()
		and frame:GetTop() <= outer:GetTop() and frame:GetBottom() >= outer:GetBottom()
end

-- n items not in the bags (item IDs from first) pinned to category id.
local function pin_many(id, first, n)
	for itemID = first, first + n - 1 do INV:PinItem(itemID, id) end
end

------------------------------------------------------------------ scrolling

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

	-- The editor: the tab's height less its footer, from 234, 540 wide;
	-- Equipment sets' fits.
	eq(w.editorScroll:GetScrollChild(), w.pane, "the editor's rows scroll in it")
	eq(w.editorScroll:GetLeft() - left, 234, 'from 234')
	eq(w.editorScroll:GetWidth(), 540, '540 wide')
	check(w.footer:GetHeight() > 0, 'a footer')
	eq(w.editorScroll:GetHeight(), height - w.footer:GetHeight(), 'the tab high, less the footer')
	check(w.pane:GetHeight() < w.editorScroll:GetHeight(), "Equipment sets' editor fits")
	check(not w.editorBar:IsShown(), 'no bar')
	eq(w.divider:GetHeight(), height, 'the divider down the whole tab')

	-- A rule taller than the tab: the editor's bar, 10 to its right, where the
	-- body's own would be, inside the body's clip.
	tall_rule('Toys', 25)
	INV.categoryEditor.selected = 'Toys'
	OW:Render()
	w = tab()
	check(w.pane:GetHeight() > w.editorScroll:GetHeight(), "Toys' editor is taller than its view")
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
	eq(w.editorScroll:GetVerticalScroll(), w.pane:GetHeight() - w.editorScroll:GetHeight(), "the editor no further than its end")

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

test("under Blizzard the list and the editor scroll on Blizzard's minimal scroll bar, each where there is room", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		tall_rule('Toys', 25)
		INV.categoryEditor.selected = 'Toys'
		st.config.profile.theme.name = 'blizzard'
		st:ThemeChanged()
		open()
		local F = OW.GetFrames()
		local w = tab()
		local top = w.frame:GetTop()
		check(#w.rows * 22 > w.listScroll:GetHeight(), client .. ': the list has more than it shows')
		check(w.pane:GetHeight() > w.editorScroll:GetHeight(), client .. ': and the editor')

		-- The list's: narrow, 4 right of the list, short of the divider.
		local list = st.OptionsBody.Companion(w.listBar)
		check(list.frame:IsShown(), client .. ': the list has a bar')
		check(not w.listBar:IsShown(), client .. ': not the 3px one')
		eq(list.up:GetWidth() .. 'x' .. list.up:GetHeight(), '8x5', client .. ': narrow')
		eq(list.track:GetLeft() - w.listScroll:GetRight(), 4, client .. ': 4 right of the list')
		check(list.frame:GetRight() <= w.divider:GetLeft(), client .. ': at or before the divider')
		eq(list.up:GetTop(), top, client .. ': from the top')
		eq(list.down:GetBottom(), w.listScroll:GetBottom(), client .. ": to the list's bottom")

		-- The editor's: wide, 12 right of the editor, inside the body's clip.
		local editor = st.OptionsBody.Companion(w.editorBar)
		check(editor.frame:IsShown(), client .. ': the editor has a bar')
		check(not w.editorBar:IsShown(), client .. ': not the 3px one')
		eq(editor.up:GetWidth() .. 'x' .. editor.up:GetHeight(), '17x11', client .. ': wide')
		eq(editor.track:GetLeft() - w.editorScroll:GetRight(), 12, client .. ': 12 right of the editor')
		check(editor.down:GetRight() <= F.body:GetRight(), client .. ": inside the body's clip")
		eq(editor.up:GetTop(), top, client .. ': from the top')
		eq(editor.down:GetBottom(), w.editorScroll:GetBottom(), client .. ': to the bottom')

		-- Each scrolls its own pane.
		stub.fire_script(list.down, 'OnClick', 'LeftButton')
		eq(w.listScroll:GetVerticalScroll(), 66, client .. ": the list's arrow: three rows")
		eq(INV.categoryEditor.listOffset, 66, client .. ': kept')
		eq(w.editorScroll:GetVerticalScroll(), 0, client .. ': the editor stays')
		stub.fire_script(editor.down, 'OnClick', 'LeftButton')
		eq(w.editorScroll:GetVerticalScroll(), 68, client .. ": the editor's arrow: two of the body's rows")
		eq(INV.categoryEditor.editorOffset, 68, client .. ': kept')
		eq(w.listScroll:GetVerticalScroll(), 66, client .. ': the list stays')
		wheel(w.listScroll, -1)
		eq(w.listScroll:GetVerticalScroll(), 132, client .. ': the wheel as before')
		-- The wheel over a bar (outside its pane) scrolls that pane too.
		check(list.frame:IsMouseWheelEnabled() and editor.frame:IsMouseWheelEnabled(), client .. ': the bars take the wheel')
		wheel(list.frame, -1)
		eq(w.listScroll:GetVerticalScroll(), 198, client .. ": the wheel over the list's bar: three rows")
		wheel(editor.frame, -1)
		eq(w.editorScroll:GetVerticalScroll(), 136, client .. ": over the editor's: two of the body's rows")

		-- Under Thick: the 3px bars, as before.
		st.config.profile.theme.name = 'thick'
		st:ThemeChanged()
		OW:Render()
		w = tab()
		list, editor = st.OptionsBody.Companion(w.listBar), st.OptionsBody.Companion(w.editorBar)
		check(w.listBar:IsShown() and w.editorBar:IsShown(), client .. ': Thick: the 3px bars')
		check(not list.frame:IsShown() and not editor.frame:IsShown(), client .. ': Thick: no Blizzard bars')
		eq(w.listBar:GetLeft() - w.listScroll:GetRight(), 4, client .. ': Thick: 4 right of the list')
		eq(w.editorBar:GetLeft() - w.editorScroll:GetRight(), 10, client .. ': Thick: 10 right of the editor')
		eq(#take_errors(), 0, client .. ': no errors')
		st.Config:Close()
	end
end)

test('a bag update waits while a scroll thumb is held, and draws once it is let go or its button is found up', function()
	world()
	tall_rule('Toys', 25)
	INV.categoryEditor.selected = 'Toys'
	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	open()
	local w = tab()
	local bar = st.OptionsBody.Companion(w.editorBar)
	check(bar.frame:IsShown(), "the editor's bar")
	eq(row_of(w, 'Consumables').count:GetText(), '1', 'one in Consumables')

	-- Held: the render waits, and the tab isn't drawn again under the drag.
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	check(W.ScrollBarHeld(), 'a thumb is held')
	local renders = OW.GetRenderCount()
	B.put(0, 7, B.item(102, 'Elixir', 'Consumable', 30))
	INV:QueueUpdate(true)
	INV:UpdateHandler()
	tick()
	tick()
	eq(OW.GetRenderCount(), renders, 'a bag update waits for the thumb')
	check(tab() == w and bar.frame:IsShown(), 'the tab not drawn again')
	check(W.ScrollBarHeld(), 'the thumb still held')
	eq(row_of(w, 'Consumables').count:GetText(), '1', 'the count waits too')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar.thumb, 'OnMouseUp', 'LeftButton')
	check(not W.ScrollBarHeld(), 'let go')
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'let go: drawn')
	w = tab()
	eq(row_of(w, 'Consumables').count:GetText(), '2', 'the new count')

	-- A thumb whose mouse up never came: its button found up, the render runs.
	bar = st.OptionsBody.Companion(w.editorBar)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	renders = OW.GetRenderCount()
	INV:QueueUpdate(true)
	INV:UpdateHandler()
	tick()
	eq(OW.GetRenderCount(), renders, 'held: waits')
	stub.mouse_buttons.LeftButton = nil
	check(not W.ScrollBarHeld(), 'the button up: no thumb held')
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'drawn')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

------------------------------------------------------------------ the editor's footer

test("the editor's footer: Caught now above Pinned items at the pane's bottom, as tall as they need, the rest scrolling above it", function()
	world()
	INV:PinItem(301, 'Consumables')
	INV.categoryEditor.selected = 'Consumables'
	open()
	local w = tab()
	local height = w.frame:GetHeight()
	local caught, pins = w:EditorCell('caught'), w:EditorCell('pins')
	check(caught and pins, 'EditorCell finds both')
	check(inside(caught.frame, w.footer) and inside(pins.frame, w.footer), 'both in the footer')
	check(caught.frame:GetTop() > pins.frame:GetTop(), 'Caught now above Pinned items')
	eq(caught.widget.frame:GetWidth(), 540, "the pane's full width")
	eq(pins.widget.frame:GetWidth(), 540, "the pane's full width")
	eq(w.footer:GetLeft() - w.frame:GetLeft(), 234, "in the editor's column")
	eq(w.footer:GetWidth(), 540, '540 wide')
	eq(w.footer:GetBottom(), w.frame:GetBottom(), "at the pane's bottom")
	eq(w.footer:GetHeight(), w.footerContent + 1, 'as tall as its strips and its edge')
	check(w.footer:GetHeight() < math.floor(height / 2), 'which here is under half the pane')
	eq(w.footerScroll:GetScrollChild(), w.footerPane, 'the strips scroll in the footer')
	eq(w.footerScroll:GetTop(), w.footer:GetTop() - 1, 'its view under the edge')
	eq(w.footerScroll:GetBottom(), w.footer:GetBottom(), "down to the footer's bottom")
	eq(w.footerPane:GetHeight(), w.footerContent, 'as tall as the strips drawn')
	eq(w.editorScroll:GetHeight(), height - w.footer:GetHeight(), "the editor's view the rest of the pane")
	eq(w.editorScroll:GetBottom(), w.footer:GetTop(), 'right above the footer')
	eq(editor_keys(w), 'name,enabled,show,rule,reset,delete', 'the rest in the editor, Reset and Delete at its end')
	eq(w.footerLine:GetTop(), w.footer:GetTop(), 'its edge at its top')
	eq(w.footerLine:GetWidth(), 540, 'across it')
	eq(w.footerLine:GetHeight(), 1, '1 tall')
	eq(w.footerLine:GetAtlas(), nil, 'Thick: no atlas')
	check(same_rgb(stub.state(w.footerLine).color_texture, { unpack(st.OptionsBody.LINE) }), "Thick: the body's line color")
	check(not w.footerBar:IsShown(), 'nothing to scroll')
	eq(w.footerScroll:GetVerticalScroll(), 0, 'not scrolled')

	-- No pins: Caught now alone, as today, the footer shorter.
	local before = w.footer:GetHeight()
	INV:UnpinItem(301)
	OW:Render()
	w = tab()
	eq(w:EditorCell('pins'), nil, 'no pins: no row')
	check(inside(w:EditorCell('caught').frame, w.footer), 'Caught now in the footer')
	eq(w.footer:GetHeight(), w.footerContent + 1, 'as tall as it needs')
	check(w.footer:GetHeight() < before, 'shorter')
	eq(w.editorScroll:GetHeight(), height - w.footer:GetHeight(), "the editor's view grows")
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('a footer taller than half the pane scrolls on its own, with the same bar as the other areas', function()
	world()
	pin_many('Consumables', 2000, 80)
	pin_many('Trade Goods', 2100, 80)
	INV.categoryEditor.selected = 'Consumables'
	open()
	local F = OW.GetFrames()
	local w = tab()
	local height = w.frame:GetHeight()
	check(w.footerContent + 1 > math.floor(height / 2), 'its strips are taller than half the pane')
	eq(w.footer:GetHeight(), math.floor(height / 2), 'half the pane')
	eq(w.footer:GetBottom(), w.frame:GetBottom(), 'at its bottom')
	eq(w.footerScroll:GetHeight(), w.footer:GetHeight() - 1, 'its view under its edge')
	eq(w.editorScroll:GetHeight(), height - w.footer:GetHeight(), 'the editor the rest')
	check(w.footerBar:IsShown(), 'a bar')
	eq(w.footerBar:GetWidth(), 3, '3 wide')
	eq(w.footerBar:GetLeft() - w.footerScroll:GetRight(), 10, "10 to its right, as the editor's")
	eq(w.footerBar:GetTop(), w.footerScroll:GetTop(), 'from the top of its view')
	check(w.footerBar:GetRight() <= F.body:GetRight(), "inside the body's clip")

	-- The wheel over it scrolls it only.
	wheel(w.footerScroll, -1)
	eq(w.footerScroll:GetVerticalScroll(), 68, "two of the body's rows a turn")
	eq(INV.categoryEditor.footerOffset, 68, 'kept')
	eq(w.editorScroll:GetVerticalScroll(), 0, 'the editor stays')
	check(w.footerBar:GetTop() < w.footerScroll:GetTop(), 'its bar down')
	OW:Render()
	w = tab()
	eq(w.footerScroll:GetVerticalScroll(), 68, 'kept when the tab is drawn again')

	-- A taller tab (/sui grown taller, through its fill row's SetHeight): the
	-- footer and the editor follow it, the footer's scroll kept.
	w:SetHeight(height + 200)
	eq(w.footer:GetHeight(), math.floor((height + 200) / 2), 'half the taller pane')
	eq(w.footer:GetBottom(), w.frame:GetBottom(), "at the taller pane's bottom")
	eq(w.editorScroll:GetHeight(), height + 200 - w.footer:GetHeight(), 'the editor the rest')
	eq(w.footerScroll:GetHeight(), w.footer:GetHeight() - 1, 'its view under its edge')
	eq(w.footerScroll:GetVerticalScroll(), 68, 'its scroll kept')
	-- Tall enough for all of it: as tall as its strips, nothing to scroll.
	w:SetHeight(2 * (w.footerContent + 1))
	eq(w.footer:GetHeight(), w.footerContent + 1, 'as tall as its strips')
	eq(w.footerScroll:GetVerticalScroll(), 0, 'nothing to scroll')
	check(not w.footerBar:IsShown(), 'no bar')
	w:SetHeight(height)
	eq(w.footer:GetHeight(), math.floor(height / 2), 'back to half the pane')
	eq(w.footerScroll:GetVerticalScroll(), 68, 'scrolled where it was')

	local strip = icons(w:EditorCell('pins').widget)
	local last = strip[#strip]
	eq(last.entry.itemID, 2079, 'the last pin')
	check(not within(last, w.footerScroll), 'out of view')
	wheel(w.footerScroll, -1, 50)
	eq(w.footerScroll:GetVerticalScroll(), w.footerContent - w.footerScroll:GetHeight(), 'no further than its end')

	-- The X on a pin scrolled into view unpins it.
	check(within(last, w.footerScroll), 'scrolled into view')
	click(last.remove)
	eq(INV:GetPin(2079), nil, 'unpinned')
	w = tab()
	eq(#icons(w:EditorCell('pins').widget), 79, 'and it leaves the strip')
	check(w.footerScroll:GetVerticalScroll() > 0, 'the footer stays scrolled')

	-- Another category's footer starts at its top, as its editor does.
	INV.categoryEditor.selected = 'Trade Goods'
	OW:Render()
	w = tab()
	check(w.footerContent + 1 > math.floor(height / 2), 'Trade Goods has as much to scroll')
	eq(w.footerScroll:GetVerticalScroll(), 0, "another category's starts at its top")
	eq(INV.categoryEditor.footerOffset, 0, 'kept as 0')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test('with the footer fixed, a long rule and the items it catches are in view at once', function()
	world()
	INV.categoryEditor.selected = SELL
	open()
	local F = OW.GetFrames()
	local w = tab()
	check(w.pane:GetHeight() > w.editorScroll:GetHeight(), "Grays/Auto Vendor's rule is taller than the editor's view")
	local icon = icons(w:EditorCell('caught').widget)[1]
	eq(icon.entry.itemID, 502, 'the gray cloth')
	local editor = w:EditorCell('rule').widget
	local function lit()
		local out = {}
		for _, row in ipairs(editor.rows) do
			if row.tint:IsShown() then out[#out + 1] = row end
		end
		return out
	end
	local function tinted()
		local out = {}
		for i, row in ipairs(lit()) do out[i] = row.kind .. '{' .. table.concat(row.path, ',') .. '}' end
		return table.concat(out, ' ')
	end
	GameTooltip:SetSize(300, 200)

	-- The editor at its top: the block that caught the cloth and the cloth both show.
	stub.fire_script(icon, 'OnEnter')
	eq(tinted(), 'block{1,1}', 'the block that caught it lights up')
	check(within(lit()[1].frame, w.editorScroll), "in the editor's view")
	check(within(icon, w.footerScroll), "with the icon in the footer's")
	stub.fire_script(icon, 'OnLeave')

	-- The editor at its end: the icon where it was, in the tab, its hover and
	-- tooltip as before.
	local top = icon:GetTop()
	wheel(w.editorScroll, -1, 50)
	eq(w.editorScroll:GetVerticalScroll(), w.pane:GetHeight() - w.editorScroll:GetHeight(), 'the editor at its end')
	eq(icon:GetTop(), top, 'the icon stays where it was')
	check(within(icon, w.frame), 'inside the tab')
	check(within(icon, w.footerScroll), "in the footer's view")
	stub.fire_script(icon, 'OnEnter')
	eq(tinted(), 'block{1,1}', 'the block that caught it lights up')
	check(GameTooltip:IsOwned(icon), 'its tooltip')
	eq(GameTooltip:GetLeft(), F.window:GetRight() + 4, 'beside the window')
	eq(GameTooltip:GetTop(), icon:GetTop(), "level with the icon's top")
	stub.fire_script(icon, 'OnLeave')
	eq(tinted(), '', 'gone when the mouse leaves')
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)

test("under Blizzard the footer's edge is the Settings divider and its bar Blizzard's", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		pin_many('Consumables', 2000, 80)
		INV.categoryEditor.selected = 'Consumables'
		st.config.profile.theme.name = 'blizzard'
		st:ThemeChanged()
		open()
		local F = OW.GetFrames()
		local w = tab()
		eq(w.footerLine:GetAtlas(), 'Options_HorizontalDivider', client .. ': the Settings divider')
		eq(w.footerLine:GetHeight(), 1, client .. ': 1 tall')
		eq(w.footerLine:GetWidth(), 540, client .. ': across the footer')
		eq(w.footer:GetHeight(), math.floor(w.frame:GetHeight() / 2), client .. ': half the pane')
		local bar = st.OptionsBody.Companion(w.footerBar)
		check(bar.frame:IsShown(), client .. ": Blizzard's bar")
		check(not w.footerBar:IsShown(), client .. ': not the 3px one')
		eq(bar.up:GetWidth() .. 'x' .. bar.up:GetHeight(), '17x11', client .. ': wide, as the editor\'s')
		eq(bar.track:GetLeft() - w.footerPane:GetRight(), 12, client .. ": 12 right of the footer's pane")
		eq(bar.up:GetTop(), w.footerScroll:GetTop(), client .. ': from the top of its view')
		eq(bar.down:GetBottom(), w.footerScroll:GetBottom(), client .. ': to its bottom')
		check(bar.down:GetRight() <= F.body:GetRight(), client .. ": inside the body's clip")
		stub.fire_script(bar.down, 'OnClick', 'LeftButton')
		eq(w.footerScroll:GetVerticalScroll(), 68, client .. ": its arrow: two of the body's rows")
		eq(w.editorScroll:GetVerticalScroll(), 0, client .. ': the editor stays')

		-- Thick again: the color line, the 3px bar.
		st.config.profile.theme.name = 'thick'
		st:ThemeChanged()
		OW:Render()
		w = tab()
		bar = st.OptionsBody.Companion(w.footerBar)
		eq(w.footerLine:GetAtlas(), nil, client .. ': Thick: no atlas')
		check(same_rgb(stub.state(w.footerLine).color_texture, { unpack(st.OptionsBody.LINE) }), client .. ": Thick: the body's line color")
		check(w.footerBar:IsShown() and not bar.frame:IsShown(), client .. ': Thick: the 3px bar')
		eq(#take_errors(), 0, client .. ': no errors')
		st.Config:Close()
	end
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
	eq(#take_errors(), 0, 'no errors')
	st.Config:Close()
end)
