-- The bag views' switch (SaftUI-Bags/container.lua's INV:CreateViewButtons and
-- INV:SetView, SaftUI-Bags/options.lua's View and Empty slots): four small icon
-- buttons in each window's title bar, left of the close button, in the order
-- One bag, Multi bag, Compact, Rows, with a tooltip naming the view; the
-- current one lit with Buttons -> Blue, kept through a theme recolor and
-- redraw and relit when Blue changes, the icons in Text -> Normal; a click,
-- or the /sui View select, saves the window's own view, refreshes an open /sui
-- and lays it out, a view that is already the window's changing nothing; and a
-- switch in combat lighting the button and saving the view at once while the
-- layout follows after combat, no slot or category frame moved in the fight.
-- The /sui options: View and Empty slots for every window, with a desc, a size
-- and no Ace width, and Empty slots re-packing an open Compact window.
--
-- bags/container_helpers.lua's views world, with the module's real options.lua.
local H = load_test_file('bags/container_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')

local INV, W

local VIEWS = { 'onebag', 'multibag', 'compact', 'rows' }
local LABELS = { onebag = 'One bag', multibag = 'Multi bag', compact = 'Compact', rows = 'Rows' }

-- A world with the real /sui page of Bags, and the bag window in Compact with
-- a few items. client is 'forever' (the default) or 'retail'.
local function world(client)
	INV, W = H.views_world(client or 'forever')
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	W.bag(0, 20, 'Backpack')
	W.bag(1, 16, 'Bag')
	for i = 1, 12 do W.put(0, i, W.item(100 + i, 'Tonic ' .. i, 'Consumable', 40 - i)) end
	W.put(1, 1, W.item(201, 'Axe', 'Weapon', 70))
	INV.config.stackItems = false
	load_saftui('SaftUI-Bags/options.lua')
	-- What the page waits for: every window with a mover, and its anchor frame.
	for _, id in ipairs(INV.windowIds) do INV.moverIds[id] = true end
	function INV:GetAnchor() return CreateFrame('Frame', nil, UIParent) end
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

local function click(button) stub.fire_script(button, 'OnClick') end

local function blue() return T.text(SaftUI.config.profile.colors.button.blue:GetRGB()) end

-- The border color of a view button, as text.
local function border(button) return T.edge_rgb(button.backdrop) end

-- Which of a window's view buttons are lit (Buttons -> Blue), as 'a,b'.
local function lit(container)
	local out = {}
	for _, view in ipairs(VIEWS) do
		if border(container.viewButtons[view]) == blue() then out[#out + 1] = view end
	end
	return table.concat(out, ',')
end

-- A window of another kind, made like the bag's.
local function window(id)
	local container = H.window(id)
	return container
end

------------------------------------------------------------------ the buttons

test('each window has the four view buttons in order left of the close button, with tooltips', function()
	world('retail')
	for _, id in ipairs({ 'bag', 'bank', 'warband', 'combinedbank' }) do
		local container = INV.containers[id] or window(id)
		local close = SaftUI:GetCloseButton(container)
		check(close ~= nil, id .. ': a close button')
		local header = container.header
		local previous
		for i, view in ipairs(VIEWS) do
			local button = container.viewButtons and container.viewButtons[view]
			check(button ~= nil, id .. ': a button for ' .. view)
			if button then
				eq(button:GetWidth(), header:GetHeight() - 8, id .. ' ' .. view .. ': the header height less 8 wide')
				eq(button:GetHeight(), header:GetHeight() - 8, id .. ' ' .. view .. ': and as tall')
				check(button:GetTop() <= header:GetTop() and button:GetBottom() >= header:GetBottom(),
					id .. ' ' .. view .. ': inside the header')
				if previous then
					check(previous:GetRight() <= button:GetLeft(), id .. ' ' .. view .. ': right of ' .. tostring(VIEWS[i - 1]))
				end
				previous = button
				-- The tooltip names the view.
				GameTooltip:Hide()
				stub.fire_script(button, 'OnEnter')
				check(GameTooltip:IsShown(), id .. ' ' .. view .. ': a tooltip')
				eq(GameTooltip:GetOwner(), button, id .. ' ' .. view .. ': on its button')
				eq(stub.state(GameTooltip).texts[1], LABELS[view], id .. ' ' .. view .. ': it names the view')
				stub.fire_script(button, 'OnLeave')
				check(not GameTooltip:IsShown(), id .. ' ' .. view .. ': gone on leave')
			end
		end
		if previous then
			check(previous:GetRight() <= close:GetLeft(), id .. ': Rows is left of the close button')
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a button draws its icon from plain textures and its border in the theme as a small kind', function()
	local container = world()
	local drawn = T.watch()
	-- A new window is drawn through the same call.
	local fresh = window('bank')
	for _, view in ipairs(VIEWS) do
		local button = fresh.viewButtons[view]
		eq(drawn(button), 'theme,theme,small', view .. ': SetBackdrop(button, theme, theme, small)')
		check(button.backdrop ~= nil, view .. ': bordered')
		local textures = 0
		for _, region in ipairs({ button:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:GetAlpha() > 0 then textures = textures + 1 end
		end
		check(textures >= 1, view .. ': an icon made of textures')
	end
	check(container ~= nil, 'the bag window exists')
end)

test('the tooltip names the view', function()
	local container = world()
	for _, view in ipairs(VIEWS) do
		GameTooltip:Hide()
		stub.fire_script(container.viewButtons[view], 'OnEnter')
		eq(stub.state(GameTooltip).texts[1], LABELS[view], view .. ': its name')
	end
end)

test('no view button overlaps the title, the close button or another button, in a window at its narrowest', function()
	local container = world()
	-- Nothing in the bag: the narrowest a window gets (one column).
	W.bags = {}
	W.bag(0, 20, 'Backpack')
	INV:UpdateContainer('bag', true)
	for _, id in ipairs({ 'bag', 'bank' }) do
		local c = INV.containers[id] or window(id)
		c.title:SetText(id == 'bag' and 'Bags' or 'Bank')
		INV:UpdateContainer(id, true)
		local titleWidth = c.title:GetStringWidth()
		local center = (c:GetLeft() + c:GetRight()) / 2
		local first = c.viewButtons.onebag
		check(center + titleWidth / 2 <= first:GetLeft(), id .. ': the title ends before the first button')
		check(c.viewButtons.rows:GetRight() <= SaftUI:GetCloseButton(c):GetLeft(), id .. ': and the buttons before the close button')
	end
end)

test("the buttons follow the title bar's height", function()
	local container = world()
	SaftUI.config.profile.headers.height = 40
	SaftUI:UpdateHeader()
	for _, view in ipairs(VIEWS) do
		eq(container.viewButtons[view]:GetWidth(), 32, view .. ': the new height less 8 wide')
		eq(container.viewButtons[view]:GetHeight(), 32, view .. ': and tall')
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ switching

test('a click switches the view, saves it per window, and lights its button', function()
	local container = world('retail')
	local bank = window('bank')
	eq(INV.config.bag.view, 'compact', 'the bag starts in Compact')
	eq(lit(container), 'compact', 'with Compact lit')
	eq(lit(bank), 'compact', "and the bank's Compact lit")

	click(container.viewButtons.multibag)
	eq(INV.config.bag.view, 'multibag', 'saved in the bag window')
	eq(lit(container), 'multibag', 'only Multi bag lit')
	eq(INV.config.bank.view, 'compact', "the bank's view is its own")
	eq(lit(bank), 'compact', "and its buttons didn't move")
	eq(container.view, 'multibag', 'the window laid out in it')

	click(container.viewButtons.rows)
	eq(INV.config.bag.view, 'rows', 'then Rows')
	eq(lit(container), 'rows', 'only Rows lit')

	click(bank.viewButtons.onebag)
	eq(INV.config.bank.view, 'onebag', 'the bank saves its own')
	eq(INV.config.bag.view, 'rows', 'and the bag keeps Rows')
	eq(#take_errors(), 0, 'no errors')
end)

test('the /sui View select and the buttons stay in step', function()
	local container = world()
	local tree = INV:GetConfigTable()
	local view = tree.args.bag.args.general.args.view
	check(view ~= nil, 'the bag window has a View option')
	eq(view.type, 'select', 'a select')
	eq(view.name, 'View', 'named View')
	eq(table.concat(view.sorting, ','), table.concat(VIEWS, ','), 'in the buttons order')
	for _, v in ipairs(VIEWS) do eq(view.values[v], LABELS[v], v .. ' is worded as its tooltip') end

	local function get() return tree.args.bag.args.general.get({ 'view' }) end
	eq(get(), 'compact', 'reads the window')
	view.set({ 'view' }, 'rows')
	eq(INV.config.bag.view, 'rows', 'set saves it')
	eq(lit(container), 'rows', 'and lights its button')
	eq(container.view, 'rows', 'and lays the window out')
	click(container.viewButtons.onebag)
	eq(get(), 'onebag', 'a click shows in the select')
	eq(lit(container), 'onebag', 'and in the buttons')

	-- A profile change re-points the buttons at the new profile's view.
	INV.config.bag.view = 'multibag'
	INV:UpdateConfig('bag')
	eq(lit(container), 'multibag', 'a profile switch relights the button')
	eq(#take_errors(), 0, 'no errors')
end)

test('a switch refreshes an open /sui, so its View select shows the new view', function()
	local container = world()
	-- st.Config:Refresh is AceConfigRegistry's NotifyChange in game, which
	-- re-renders an open /sui (and does nothing with it closed); the shell's
	-- is a no-op, so count the calls.
	local refreshes = 0
	local refresh = SaftUI.Config.Refresh
	SaftUI.Config.Refresh = function(...)
		refreshes = refreshes + 1
		return refresh(...)
	end
	local view = INV:GetConfigTable().args.bag.args.general.args.view
	click(container.viewButtons.rows)
	eq(refreshes, 1, 'a click refreshes /sui')
	eq(INV.config.bag.view, 'rows', 'after saving the view, which its select reads')
	click(container.viewButtons.rows)
	view.set({ 'view' }, 'rows')
	eq(refreshes, 1, "the window's own view: no refresh")
	view.set({ 'view' }, 'onebag')
	eq(refreshes, 2, 'the select itself refreshes the page too')
	stub.in_combat = true
	click(container.viewButtons.multibag)
	eq(refreshes, 3, 'in combat, at once, as the view saves')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(refreshes, 3, 'and not again when the layout follows')
	SaftUI.Config.Refresh = refresh
	eq(#take_errors(), 0, 'no errors')
end)

test('a view the window already has changes nothing: no re-layout, nothing moved', function()
	local container = world()
	local tree = INV:GetConfigTable()
	local view = tree.args.bag.args.general.args.view
	local applied, layouts = 0, 0
	local applyView, layoutSections = INV.ApplyView, INV.LayoutSections
	INV.ApplyView = function(...) applied = applied + 1 return applyView(...) end
	INV.LayoutSections = function(...) layouts = layouts + 1 return layoutSections(...) end
	local updates = 0
	local updateContainerLayout = INV.UpdateContainerLayout
	INV.UpdateContainerLayout = function(...) updates = updates + 1 return updateContainerLayout(...) end

	-- A click on the lit button, and the select set to its own value.
	local snap = H.snapshot(container)
	click(container.viewButtons.compact)
	view.set({ 'view' }, 'compact')
	INV:SetView('bag', 'compact')
	eq(applied, 0, 'no ApplyView')
	eq(updates, 0, 'no layout')
	check(H.same(H.snapshot(container), snap), 'the window as it was')
	eq(lit(container), 'compact', 'still lit')

	-- The same holds in another view.
	click(container.viewButtons.rows)
	eq(applied, 1, 'a real switch applies once')
	local after = H.snapshot(container)
	updates = 0
	click(container.viewButtons.rows)
	view.set({ 'view' }, 'rows')
	eq(applied, 1, 'Rows again: nothing')
	eq(updates, 0, 'no layout')
	check(H.same(H.snapshot(container), after), 'the window as it was')
	eq(#take_errors(), 0, 'no errors')
end)

test('an unknown view is ignored', function()
	local container = world()
	INV:SetView('bag', 'sideways')
	eq(INV.config.bag.view, 'compact', 'the saved view stays')
	eq(lit(container), 'compact', 'and its button lit')
end)

------------------------------------------------------------------ the lit border

test('the lit button keeps its blue through a recolor and a redraw, and the old one returns to the theme', function()
	local container = world()
	local compact, rows = container.viewButtons.compact, container.viewButtons.rows
	local thick = SaftUI.config.profile.templates.thick
	eq(border(compact), blue(), 'Compact lit')

	-- A theme recolor.
	thick.bordercolor = { 0.7, 0.2, 0.2, 1 }
	SaftUI:RecolorThemed()
	eq(border(compact), blue(), 'after a recolor, still blue')
	eq(border(rows), T.text(0.7, 0.2, 0.2), "and the others take the theme's new border")

	-- A theme redraw.
	SaftUI.config.profile.theme.name = 'thin'
	SaftUI:RedrawThemed()
	eq(border(compact), blue(), 'after a redraw, still blue')
	eq(T.around(compact.backdrop, compact), T.around(rows.backdrop, rows), 'drawn at the same inset as the others')

	-- A Buttons -> Blue change, as the Colors tab sends it.
	local blueColor = SaftUI.config.profile.colors.button.blue
	blueColor.r, blueColor.g, blueColor.b = 0.9, 0.9, 0.1
	SaftUI:ColorsChanged('button')
	eq(border(compact), blue(), 'a Blue change relights it')
	eq(border(compact), T.text(0.9, 0.9, 0.1), 'in the new Blue')

	-- Switching lights the new one and the old one is the theme's again.
	click(rows)
	eq(border(rows), blue(), 'Rows lit')
	eq(border(compact), border(container.viewButtons.multibag), "Compact is the theme's border again")
	SaftUI.config.profile.templates.thin.bordercolor = { 0.1, 0.8, 0.8, 1 }
	SaftUI:RecolorThemed()
	eq(border(compact), T.text(0.1, 0.8, 0.8), 'a recolor leaves it the theme\'s, not blue')
	eq(border(rows), blue(), 'and Rows blue')
	eq(#take_errors(), 0, 'no errors')
end)

test('the icons take Colors -> Text -> Normal at once, in every window', function()
	local container = world()
	local bank = window('bank')
	local normal = SaftUI.config.profile.colors.text.normal
	-- The color of every glyph piece of a window's buttons, as 'r,g,b' text, if they're all one.
	local function glyphs(c)
		local colors = {}
		for _, view in ipairs(VIEWS) do
			for _, piece in ipairs(c.viewButtons[view].glyph) do
				local rgba = stub.state(piece).color_texture
				colors[T.text(rgba[1], rgba[2], rgba[3])] = true
			end
		end
		local out = {}
		for color in pairs(colors) do out[#out + 1] = color end
		return table.concat(out, ' | ')
	end
	eq(glyphs(container), T.text(normal:GetRGB()), "the icons start in Text -> Normal")

	-- A Text -> Normal change, as the Colors tab sends it.
	normal.r, normal.g, normal.b = 0.2, 0.6, 0.4
	SaftUI:ColorsChanged('text')
	eq(glyphs(container), T.text(0.2, 0.6, 0.4), 'the bags: in the new color')
	eq(glyphs(bank), T.text(0.2, 0.6, 0.4), 'the bank: too')
	eq(border(container.viewButtons.compact), blue(), 'the lit border stays Blue')
	eq(glyphs(window('warband')), T.text(0.2, 0.6, 0.4), 'a window made after: in the new color')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ combat

-- Counts the calls on every slot and category frame of a window to what
-- moves, sizes, reparents, shows or hides them (as views_layout_test.lua's).
local function watch_moves(container)
	local calls = { n = 0 }
	local function watch(frame)
		for _, method in ipairs({ 'SetPoint', 'ClearAllPoints', 'SetParent', 'SetSize', 'SetWidth', 'SetHeight', 'Show', 'Hide' }) do
			local original = frame[method]
			frame[method] = function(...)
				calls.n = calls.n + 1
				return original(...)
			end
		end
	end
	for _, category in pairs(container.categories) do
		watch(category)
		for _, slot in ipairs(category.slots) do watch(slot) end
	end
	for _, column in ipairs(container.columns) do watch(column) end
	return calls
end

test('a switch in combat lights the button at once and lays out after combat, with no slot moved in combat', function()
	local container = world()
	local snap = H.snapshot(container)
	local calls = watch_moves(container)
	local layouts = 0
	local layoutSections = INV.LayoutSections
	INV.LayoutSections = function(...)
		layouts = layouts + 1
		return layoutSections(...)
	end

	stub.in_combat = true
	click(container.viewButtons.rows)
	eq(INV.config.bag.view, 'rows', 'saved at once')
	eq(lit(container), 'rows', 'its button lit at once')
	eq(calls.n, 0, 'no slot, category or column moved, sized, reparented, shown or hidden')
	check(H.same(H.snapshot(container), snap), 'the window as it was')
	eq(layouts, 0, 'no layout in combat')

	-- Another click in the fight, and the select.
	click(container.viewButtons.onebag)
	eq(lit(container), 'onebag', 'the next click lights its own')
	eq(calls.n, 0, 'still nothing moved')

	-- Back where the window is laid out: nothing is left to do after combat.
	click(container.viewButtons.compact)
	eq(lit(container), 'compact', 'back to Compact, lit')
	eq(calls.n, 0, 'nothing moved')

	click(container.viewButtons.rows)
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(layouts, 1, 'after combat: laid out once')
	eq(container.view, 'rows', 'in Rows')
	eq(lit(container), 'rows', 'still lit')
	eq(#take_errors(), 0, 'no errors')
end)

test('a switch back to the laid-out view in combat leaves nothing to do after combat', function()
	local container = world()
	local layouts = 0
	local layoutSections = INV.LayoutSections
	INV.LayoutSections = function(...)
		layouts = layouts + 1
		return layoutSections(...)
	end
	local snap = H.snapshot(container)
	stub.in_combat = true
	click(container.viewButtons.rows)
	click(container.viewButtons.compact)
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(layouts, 0, 'no layout')
	check(H.same(H.snapshot(container), snap), 'the window as it was')
	eq(lit(container), 'compact', 'Compact lit')
end)

------------------------------------------------------------------ options

test('every window offers Empty slots; the bank windows default to off', function()
	world('retail')
	local tree = INV:GetConfigTable()
	for _, id in ipairs({ 'bag', 'bank', 'combinedbank', 'warband' }) do
		local group = tree.args[id].args.general
		local option = group.args.emptySlots
		check(option ~= nil, id .. ' has Empty slots')
		eq(option.type, 'select', id .. ': a select')
		eq(table.concat(option.sorting, ','), 'off,grouped,all', id .. ': off, grouped, every slot')
		eq(group.get({ 'emptySlots' }), 'off', id .. ' defaults to off')
		eq(group.args.view ~= nil, true, id .. ' has View')
	end
	-- Set, it saves and lays the windows out again.
	local queued = {}
	INV.QueueUpdate = function(_, full) queued[#queued + 1] = tostring(full) end
	local option = tree.args.bank.args.general.args.emptySlots
	if option.set then option.set({ 'emptySlots' }, 'grouped') else tree.args.bank.args.general.set({ 'emptySlots' }, 'grouped') end
	eq(INV.config.bank.emptySlots, 'grouped', 'Empty slots saves in the bank window')
	eq(INV.config.bag.emptySlots, 'off', 'not the bag window')
	eq(table.concat(queued, ','), 'true', 'and updates the windows')
end)

test('Empty slots re-packs an open Compact window: Off, Every slot, then Off again, as on 1081e68', function()
	local container = world()
	container:Show()
	H.search(container) -- the bag window's, which INV:UpdateVisibleContainers reads
	-- A third category, packed afresh as the window opens.
	W.put(1, 2, W.item(301, 'Plank', 'Trade Goods', 15))
	INV:ReleaseLayout(container)
	INV:UpdateContainer('bag', true)
	local where, height, width = H.where(container), container:GetHeight(), container:GetWidth()
	local general = INV:GetConfigTable().args.bag.args.general
	-- Sets Empty slots as /sui does, then runs the update it queued, as the
	-- module's updater does on the next frame.
	local function set(mode)
		local option = general.args.emptySlots
		if option.set then option.set({ 'emptySlots' }, mode) else general.set({ 'emptySlots' }, mode) end
		check(INV.NEED_UPDATE, mode .. ': an update is queued')
		INV.NEED_UPDATE = false
		local layout = INV.UPDATE_LAYOUT
		INV.UPDATE_LAYOUT = false
		INV:UpdateVisibleContainers(layout)
	end
	-- Where the categories are and how big the window is.
	local function packing()
		local out = {}
		for name, place in pairs(H.where(container)) do out[#out + 1] = name .. '=' .. place end
		table.sort(out)
		return table.concat(out, ' ') .. ' ' .. container:GetWidth() .. 'x' .. container:GetHeight()
	end

	set('all')
	check(container.categories['Empty Slots']:IsShown(), 'Every slot: Empty Slots shown')
	local shown = packing()
	INV:ReleaseLayout(container)
	INV:UpdateContainer('bag', true)
	eq(shown, packing(), 'Every slot: packed as a window opened with it')

	set('off')
	check(not container.categories['Empty Slots']:IsShown(), 'Off: Empty Slots gone')
	check(H.same(H.where(container), where), 'Off: every category back where it was')
	eq(container:GetHeight(), height, 'Off: the window as tall as before')
	eq(container:GetWidth(), width, 'Off: and as wide')
	eq(#take_errors(), 0, 'no errors')
end)

test('View and Empty slots have descs, the size a select takes, and no width', function()
	world('retail')
	local tree = INV:GetConfigTable()
	for _, id in ipairs({ 'bag', 'bank', 'combinedbank', 'warband' }) do
		for _, key in ipairs({ 'view', 'emptySlots' }) do
			local option = tree.args[id].args.general.args[key]
			local where = id .. '.' .. key
			check(type(option.desc) == 'string' and option.desc ~= '', where .. ' has a desc')
			eq(option.size, nil, where .. ' takes the select\'s normal size: a half line, as no select is small')
			eq(option.width, nil, where .. ' has no Ace width')
		end
	end
end)
