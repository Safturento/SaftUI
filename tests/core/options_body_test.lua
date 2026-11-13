-- SaftUI-Core/Config/optionslayout.lua and optionsbody.lua: the layout math that
-- needs no frame (LayoutRows, Dividers, LayoutSections, SidebarEntries,
-- ButtonRow), the body that draws sections of rows into a content frame (cells,
-- dividers, whole pixels, small cells, lines of aligned buttons), and a custom
-- type's bare row: with no label, titled, and a fill row that stretches to the
-- body's height.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow
local cell, close_all, drawn, FillRowsTable, frames = H.cell, H.close_all, H.drawn, H.FillRowsTable, H.frames
local FillRowsModule, tick = H.FillRowsModule, H.tick

-- A body of width, on a fresh content frame, with the given options on one
-- page (each { key, type, name, size, align }). Returns the body and its cells by key.
local function draw_body(width, options)
	local store, args = {}, {}
	for i, o in ipairs(options) do
		args[o[1]] = { type = o[2], name = o[3], size = o[4], align = o[5], order = i, min = 0, max = 10, step = 1, values = { a = 'A' } }
		store[o[1]] = o[2] == 'toggle' and true or o[2] == 'color' and { 1, 0, 0, 1 } or o[2] == 'input' and 'text' or nil
	end
	local root = { page = {
		type = 'group', name = 'Page', args = args,
		get = function(info) local v = store[info[#info]]; if type(v) == 'table' then return unpack(v) end; return v end,
		set = function() end,
	} }
	local content = CreateFrame('Frame', nil, UIParent)
	local body = st.OptionsBody.New(content, root, nil, width)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by
end

local function point_x(frame, n)
	local _, _, _, x = frame:GetPoint(n or 1)
	return x
end

------------------------------------------------------------------ the pure layout

test('LayoutRows: smalls take quarters, two to a half; a normal takes the next whole half; a wide its own line', function()
	local function r(key, size) return { key = key, size = size } end
	local placed, height = OW.LayoutRows({
		r('a'), r('b'),
		r('c', 'small'), r('d', 'small'), r('e'),
		r('f', 'small'), r('g'),
		r('h', 'small'), r('i', 'wide'),
		r('j'), r('k', 'small'), r('l', 'small'), r('m', 'small'),
	})
	local function at(i) local p = placed[i]; return p.col .. '/' .. tostring(p.quarter) .. '@' .. p.y end
	eq(at(1), '1/nil@0'); eq(at(2), '2/nil@0')
	eq(at(3), '1/1@34'); eq(at(4), '1/2@34'); eq(at(5), '2/nil@34')
	eq(at(6), '1/1@68'); eq(at(7), '2/nil@68')          -- a normal after a lone small skips to the next half
	eq(at(8), '1/1@102'); eq(at(9), 'full/nil@136')    -- a wide starts its own line
	eq(at(10), '1/nil@170'); eq(at(11), '2/1@170'); eq(at(12), '2/2@170'); eq(at(13), '1/1@204')
	eq(height, 238)

	-- A wide row right after a wide row, and one first.
	local rows = { r('x', 'wide'), r('y', 'wide'), r('z') }
	placed, height = OW.LayoutRows(rows)
	eq(placed[1].y .. ',' .. placed[2].y .. ',' .. placed[3].y, '0,34,68', 'each wide row its own line')
	eq(height, 102, 'three lines')

	-- A taller row makes its line taller.
	rows = { r('a'), r('b'), r('c'), r('wide', 'wide'), r('d'), r('e'), r('f') }
	placed, height = OW.LayoutRows(rows, function(row) return row.key == 'b' and 60 or 34 end)
	eq(placed[3].y, 60, 'the line after a 60-high cell starts at 60')
	eq(height, 196, 'total')

	eq(select(2, OW.LayoutRows({})), 0, 'no rows, no height')
end)

test('Dividers: one between halves that both have a row, one between two smalls of a half, none across a wide row', function()
	local function r(key, size) return { key = key, size = size } end
	local rows = {
		r('a'), r('b'),                                   -- line 0: both halves
		r('c', 'small'), r('d', 'small'), r('e'),         -- line 34 (60 high): two smalls left, a normal right
		r('f', 'small'), r('g', 'small'), r('h', 'small'), r('i', 'small'), -- line 94: four smalls
		r('w', 'wide'),                                   -- line 128: no divider
		r('j', 'small'), r('k'),                          -- line 162: a lone small, then a normal right
		r('l'),                                           -- line 196: the left half only
	}
	local placed = OW.LayoutRows(rows, function(row) return row.key == 'e' and 60 or 34 end)
	local got = {}
	for _, d in ipairs(st.OptionsBody.Dividers(placed, function(row) return row.key == 'e' and 60 or 34 end)) do
		got[#got + 1] = d.at .. (d.col and ('/' .. d.col) or '') .. '@' .. d.y .. '+' .. d.height
	end
	eq(table.concat(got, ' '), 'half@0+34 half@34+60 quarter/1@34+60 half@94+34 quarter/1@94+34 quarter/2@94+34 half@162+34',
		'a line\'s dividers are its height; a wide line and a half alone get none')
	eq(#st.OptionsBody.Dividers(OW.LayoutRows({})), 0, 'no rows, no dividers')
end)

test('LayoutRows: aligned buttons in a row make a group; right ones share the line of a wide row before them, others take a line of their own', function()
	local function r(key, size, align, rowType) return { key = key, size = size, align = align, type = rowType } end
	local rows = {
		r('pick', 'wide'), r('all', 'small', 'right'), r('none', nil, 'right'), -- line 0: All and None at the wide row's right end
		r('a'), r('b'),                                                        -- line 34: the next line, as after any line
		r('ok', nil, 'center'), r('cancel', nil, 'center'),                    -- line 68: a centred pair
		r('c', 'small'), r('go', nil, 'right'),                                -- line 102: c; line 136: go alone, at the right
		r('d', 'small'),                                                       -- line 170
		r('text', 'wide', nil, 'description'), r('more', nil, 'right'),        -- 204: a description shares no line; 238: more
		r('mid', nil, 'center'),                                               -- line 272: another align, another group
	}
	local placed, height = OW.LayoutRows(rows)
	local function at(i)
		local p = placed[i]
		if p.col == 'buttons' then return p.group.align .. '#' .. p.index .. '@' .. p.y end
		return p.col .. '/' .. tostring(p.quarter) .. '@' .. p.y
	end
	local got = {}
	for i = 1, #placed do got[i] = at(i) end
	eq(table.concat(got, ' '), 'full/nil@0 right#1@0 right#2@0 1/nil@34 2/nil@34 center#1@68 center#2@68 '
		.. '1/1@102 right#1@136 1/1@170 full/nil@204 right#1@238 center#1@272', 'where each row goes')
	eq(height, 306, 'nine lines')
	check(placed[2].group == placed[3].group, 'All and None are one group')
	check(placed[1].buttons == placed[2].group, 'on the wide row\'s line')
	check(placed[11].buttons == nil, 'not on the description\'s')
	check(placed[6].group ~= placed[2].group and placed[13].group ~= placed[12].group, 'another align is another group')
	eq(#placed[2].group.rows, 2, 'the group holds its rows')
	check(placed[2].group.rows[1] == rows[2] and placed[2].group.rows[2] == rows[3], 'in order')

	-- A line holding buttons has no dividers: only a and b's line has one.
	local dividers = st.OptionsBody.Dividers(placed)
	eq(#dividers, 1, 'one divider')
	eq(dividers[1].at .. '@' .. dividers[1].y, 'half@34', "between a and b")

	-- A taller button makes its line taller, the wide row's too.
	placed, height = OW.LayoutRows({ r('pick', 'wide'), r('go', nil, 'right'), r('a') },
		function(row) return row.key == 'go' and 40 or 34 end)
	eq(placed[3].y, 40, 'the line after the 40-high button starts at 40')
	eq(height, 74)

	-- alignOf overrides the rows' align (search results draw none).
	placed = OW.LayoutRows(rows, nil, nil, function() return nil end)
	for _, p in ipairs(placed) do check(p.col ~= 'buttons', p.row.key .. ' is laid out by its size') end
end)

test("LayoutRows: buttons aligned right don't share a bare row's line, which the row draws across", function()
	W.Define('buttonsbare', {
		bare = true,
		build = function(w) w.frame = CreateFrame('Frame', nil, UIParent) end,
	})
	local function heightOf(row) return row.key == 'bare' and 60 or 34 end
	local placed, height = OW.LayoutRows({
		{ key = 'bare', type = 'buttonsbare', size = 'wide' }, { key = 'go', align = 'right' },
	}, heightOf)
	eq(placed[1].buttons, nil, "not on the bare row's line")
	eq(placed[2].col .. '@' .. placed[2].y, 'buttons@60', 'on a line of its own under it')
	eq(height, 94, 'two lines')
	-- A wide row with a label in its place shares it.
	placed, height = OW.LayoutRows({
		{ key = 'pick', type = 'select', size = 'wide' }, { key = 'go', align = 'right' },
	}, heightOf)
	check(placed[1].buttons == placed[2].group, "a select's line is shared")
	eq(placed[2].y .. ',' .. height, '0,34', 'one line')
end)

test('ButtonRow: buttons side by side 12 apart, the last at the right edge, or the row in the middle, on whole units', function()
	local ButtonRow = st.OptionsBody.ButtonRow
	local xs, left = ButtonRow({ 80, 80 }, 'right', 520)
	eq(table.concat(xs, ','), '348,440', 'the second ends at 520')
	eq(left, 348, 'the row starts at the first')
	xs, left = ButtonRow({ 118, 80 }, 'center', 520)
	eq(table.concat(xs, ','), '155,285', '155 on either side')
	eq(left, 155)
	xs = ButtonRow({ 81 }, 'center', 520)
	eq(xs[1], 219, 'rounded down to a whole unit')
end)

------------------------------------------------------------------ the body

test('a toggle and a color sit at their cell\'s right edge, at normal and small size, the label taking the rest', function()
	local body, by = draw_body(774, {
		{ 'nt', 'toggle', 'Normal toggle' }, { 'st', 'toggle', 'Small', 'small' }, { 'sc', 'color', 'Tint', 'small' },
		{ 'nc', 'color', 'A color that is long' },
	})
	for key, c in pairs(by) do
		local point, rel, relPoint, x = c.widget.frame:GetPoint(1)
		eq(point, 'RIGHT', key .. ' point')
		check(rel == c.frame, key .. ' is anchored to its cell')
		eq(relPoint, 'RIGHT', key .. ' at the cell\'s right')
		eq(x, 0, key .. ' offset')
		local cellWidth = c.row.size == 'small' and 171 or 367 -- whole pixels: a 367 column's quarter is 171
		eq(c.label:GetWidth(), cellWidth - c.widget:GetWidth() - 10, key .. ' label is the rest of the cell')
	end
	body:Release()
end)

test('a label reused from a small toggle takes the normal cell\'s width, so its text isn\'t cut', function()
	local body, by = draw_body(774, { { 't', 'toggle', 'Show', 'small' } })
	local label = by.t.label
	-- The pools belong to the body: release it and draw the normal toggle on the same one.
	body:Release()
	body.cells = {}
	local root = { page = {
		type = 'group', name = 'Page',
		args = { t = { type = 'toggle', name = 'Show damage dealers', order = 1 } },
		get = function() return true end, set = function() end,
	} }
	body:SetRoot(root)
	body:Draw(OM.BuildView(root, 'page').sections)
	local c = body.cells[1]
	check(c.label == label, 'the label was reused')
	eq(c.label:GetWidth(), 367 - 18 - 10, 'the normal cell\'s width, not the small one\'s')
	eq(c.label:GetStringWidth(), c.label:GetUnboundedStringWidth(), 'so the game reports it uncut')
	body:Release()
end)

test('the body draws dividers a line tall: between the halves at 387, between two smalls of the left half at 183', function()
	local body, by = draw_body(774, {
		{ 'a', 'toggle', 'A', 'small' }, { 'b', 'color', 'B', 'small' }, { 'c', 'toggle', 'C' },
		{ 'w', 'description', 'Wide text' }, { 'd', 'toggle', 'D' },
	})
	local got = {}
	for _, line in ipairs(body.pools.line.used) do
		if line:GetWidth() == 1 then
			local _, _, _, x, y = line:GetPoint(1)
			got[#got + 1] = x .. ',' .. -y .. ',' .. line:GetHeight()
		end
	end
	table.sort(got)
	local y = by.a.y
	eq(table.concat(got, ' '), '183,' .. y .. ',34 387,' .. y .. ',34',
		'none beside the wide row or the lone half after it')
	body:Release()
end)

test('a position cell is wide, has no label, is the block plus 12 tall, and shows the row\'s desc over the block', function()
	local body, by = draw_body(774, { { 'pos', 'position', 'Position' }, { 'after', 'toggle', 'After' } })
	local c = by.pos
	eq(c.height, 65 + 12, 'the widget plus 12')
	eq(c.frame:GetWidth(), 774, 'the whole line')
	check(not c.label:IsShown(), 'no label: the section says Position')
	local point, rel, _, x, y = c.widget.frame:GetPoint(1)
	eq(point, 'TOPLEFT', 'the block sits at the cell\'s top left')
	check(rel == c.frame, 'in the cell')
	eq(x, 0); eq(y, -6, 'with 6 above it')
	check(by.after.y >= c.y + c.height, 'the next row is under the block')
	c.row.desc = 'Where the frame sits.'
	local owner, lines = nil, {}
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) owner = frame end,
		AddLine = function(_, text) lines[#lines + 1] = text end,
		Show = function() end,
		IsOwned = function(_, frame) return owner == frame end,
		Hide = function() owner = nil end,
	}
	c.widget.onTip(true)
	check(owner == c.frame, 'the tooltip shows for the cell')
	eq(lines[2], 'Where the frame sits.', 'with the desc')
	c.widget.onTip(false)
	check(owner == nil, 'and goes')
	_G.GameTooltip = saved
	body:Release()
end)

test('a label too long for its small cell is cut to leave room for the control', function()
	local body, by = draw_body(774, { { 'x', 'toggle', 'A very very long small toggle name', 'small' } })
	local c = by.x
	eq(c.label:GetWidth(), 171 - 18 - 10, 'the label gives way')
	body:Release()
end)

test('a small input draws a 60-wide box; the same widget reused for a normal input is 170 again', function()
	local body, by = draw_body(774, { { 'i', 'input', 'Small', 'small' } })
	local first = by.i.widget
	eq(first.frame:GetWidth(), 60, 'small box')
	eq(first:GetWidth(), 60, 'and the widget says so')
	body:Release()
	local body2, by2 = draw_body(774, { { 'i', 'input', 'Normal' } })
	check(by2.i.widget == first, 'the widget was reused')
	eq(by2.i.widget.frame:GetWidth(), 170, 'a normal box again')
	eq(by2.i.widget:GetWidth(), 170)
	body2:Release()
end)

test('quarter cells are whole pixels, the second flush with its column\'s right edge, in the window and a 520 dialog body', function()
	local function xs(width)
		local body, by = draw_body(width, {
			{ 'a', 'toggle', 'A', 'small' }, { 'b', 'toggle', 'B', 'small' }, { 'c', 'input', 'C' },
			{ 'd', 'toggle', 'D', 'small' }, { 'e', 'toggle', 'E', 'small' }, { 'f', 'toggle', 'F', 'small' },
		})
		local out = {}
		for _, k in ipairs({ 'a', 'b', 'c', 'd', 'e', 'f' }) do
			out[k] = { x = point_x(by[k].frame), w = by[k].frame:GetWidth() }
		end
		body:Release()
		return out
	end
	local w = xs(774)
	-- A 367 column's quarters are 171 wide, 25 apart: the second ends at 367.
	eq(w.a.x, 0); eq(w.b.x, 196); eq(w.c.x, 407)
	eq(w.a.w, 171); eq(w.b.w, 171); eq(w.c.w, 367)
	eq(w.d.x, 0); eq(w.e.x, 196); eq(w.f.x, 407); eq(w.f.w, 171)
	local d = xs(520)
	eq(d.a.x, 0); eq(d.b.x, 132); eq(d.c.x, 280)
	eq(d.a.w, 108); eq(d.b.w, 108); eq(d.c.w, 240)
	eq(d.f.x, 280); eq(d.f.w, 108)
	local _, wide = draw_body(520, { { 'w', 'input', 'Wide', 'wide' } })
	eq(wide.w.frame:GetWidth(), 520, 'a wide row takes the body\'s width')
end)

test("buttons aligned right sit at the right end of a wide row's line, which ends 24 before them; centred ones in the middle; no dividers", function()
	local body, by = draw_body(520, {
		{ 'pick', 'select', 'Copy from', 'wide' },
		{ 'all', 'execute', 'All', 'small', 'right' }, { 'none', 'execute', 'None', nil, 'right' },
		{ 'a', 'toggle', 'A' }, { 'b', 'toggle', 'B' },
		{ 'ok', 'execute', 'Confirm copy', nil, 'center' }, { 'cancel', 'execute', 'Cancel', nil, 'center' },
	})
	-- All and None: 80 wide each (a small size changes nothing), 12 apart, None flush with the right edge.
	eq(point_x(by.all.frame) .. '+' .. by.all.frame:GetWidth(), '348+80', 'All')
	eq(point_x(by.none.frame) .. '+' .. by.none.frame:GetWidth(), '440+80', 'None ends at 520')
	check(by.all.y == by.pick.y and by.none.y == by.pick.y, "on the wide row's line")
	-- The wide row ends 24 before All, and its label has the rest.
	eq(point_x(by.pick.frame), 0, 'the wide row at the left')
	eq(by.pick.frame:GetWidth(), 324, 'up to 24 before All')
	eq(by.pick.label:GetWidth(), 324 - 170 - 10, 'its label is the rest of the cell')
	local point, rel, relPoint = by.pick.widget.frame:GetPoint(1)
	check(point == 'RIGHT' and rel == by.pick.frame and relPoint == 'RIGHT', "the dropdown at its cell's right end")
	-- Each button at its cell's left, the cell as wide as the button.
	for _, key in ipairs({ 'all', 'none', 'ok', 'cancel' }) do
		local p, r, rp, x = by[key].widget.frame:GetPoint(1)
		check(p == 'LEFT' and r == by[key].frame and rp == 'LEFT' and x == 0, key .. ' at its cell\'s left')
		eq(by[key].frame:GetWidth(), by[key].widget:GetWidth(), key .. "'s cell is the button's width")
	end
	-- Confirm copy and Cancel: a pair in the middle, Confirm copy first, 12 apart.
	local okWidth, cancelWidth = by.ok.widget:GetWidth(), by.cancel.widget:GetWidth()
	local left = math.floor((520 - okWidth - 12 - cancelWidth) / 2)
	eq(point_x(by.ok.frame), left, 'Confirm copy on the left')
	eq(point_x(by.cancel.frame), left + okWidth + 12, 'Cancel 12 after it')
	check(math.abs(left - (520 - (left + okWidth + 12 + cancelWidth))) <= 1, 'the same room either side')
	check(by.ok.y == by.cancel.y and by.ok.y == by.a.y + 34, 'one line, under the toggles')
	-- The one divider is the toggles', between the halves at 260.
	local got = {}
	for _, line in ipairs(body.pools.line.used) do
		if line:GetWidth() == 1 then
			local _, _, _, x, y = line:GetPoint(1)
			got[#got + 1] = x .. ',' .. -y
		end
	end
	eq(table.concat(got, ' '), '260,' .. by.a.y, 'none beside the buttons')
	body:Release()
end)

test('a centred pair with one button hidden draws the other centred alone', function()
	local shown = true
	local root = { page = { type = 'group', name = 'Page', args = {
		ok = { type = 'execute', name = 'Confirm copy', align = 'center', order = 1, func = function() end },
		cancel = { type = 'execute', name = 'Cancel', align = 'center', order = 2, func = function() end,
			hidden = function() return not shown end },
	} } }
	local body = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), root, nil, 520)
	local function draw()
		body:Release()
		body:Draw(OM.BuildView(root, 'page').sections)
		local by = {}
		for _, c in ipairs(body.cells) do by[c.row.key] = c end
		return by
	end
	local by = draw()
	local okWidth, cancelWidth = by.ok.widget:GetWidth(), by.cancel.widget:GetWidth()
	eq(point_x(by.ok.frame), math.floor((520 - okWidth - 12 - cancelWidth) / 2), 'the pair in the middle')
	shown = false
	by = draw()
	eq(by.cancel, nil, 'Cancel hidden')
	eq(point_x(by.ok.frame), math.floor((520 - okWidth) / 2), 'Confirm copy in the middle alone')
	eq(by.ok.frame:GetWidth(), okWidth, 'at its own width')
	body:Release()
end)

test('search results lay aligned buttons out as halves, as any result', function()
	local args = {
		pick = { type = 'select', name = 'Pick', size = 'wide', order = 1, values = { a = 'A' } },
		all = { type = 'execute', name = 'All', align = 'right', order = 2, func = function() end },
	}
	local root = { page = { type = 'group', name = 'Page', args = args, get = function() end, set = function() end } }
	local body = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), root, nil, 520)
	body:DrawResults(OM.BuildView(root, 'page').sections, function() end)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	eq(point_x(by.pick.frame) .. '+' .. by.pick.frame:GetWidth(), '0+240', 'the wide row a half')
	eq(point_x(by.all.frame) .. '+' .. by.all.frame:GetWidth(), '280+240', 'the button the other half')
	body:Release()
end)

test('LayoutSections: titled sections get a line, an untitled one after a nested group continues without one', function()
	local function rows(n)
		local list = {}
		for i = 1, n do list[i] = { key = 'r' .. i, size = 'normal' } end
		return list
	end
	local laid = OW.LayoutSections({
		{ rows = rows(2) },                                   -- the page's own options
		{ title = 'Frame', note = 'A note.', rows = rows(2) }, -- an inline group
		{ title = 'Layout', rows = rows(1) },                 -- a nested group
		{ rows = rows(2) },                                   -- rows after the nested group
	})
	eq(#laid, 4, 'four sections')
	check(laid[1].lineY == nil and laid[1].titleY == nil, 'the first section: no line, no title')
	check(laid[2].lineY ~= nil and laid[2].titleY ~= nil and laid[2].noteY ~= nil, 'a titled section: line, title, note')
	check(laid[3].lineY ~= nil, 'the nested group: a line')
	check(laid[4].lineY == nil and laid[4].titleY == nil, 'the continuation: no line, no title')
	check(laid[2].rowsY > laid[2].titleY and laid[2].titleY > laid[2].lineY, 'line, then title, then rows')
	check(laid[4].rowsY - (laid[3].rowsY + 34) < 10, 'the continuation sits right under the rows above')
end)

test('SidebarEntries: specials first, then Frames, Combat, Info, other categories, Other; pages in order', function()
	local pages = {
		{ key = 'z', name = 'Zeta', category = 'Other' },
		{ key = 'loot', name = 'Loot', category = 'Info' },
		{ key = 'profile', name = 'Profiles', category = 'Other', special = 'profiles' },
		{ key = 'uf', name = 'Unitframes', category = 'Frames' },
		{ key = 'aur', name = 'Auras', category = 'Combat' },
		{ key = 'Fonts', name = 'Global Settings', category = 'Other', special = 'global' },
		{ key = 'chat', name = 'Chat', category = 'Frames' },
		{ key = 'odd', name = 'Odd', category = 'Misc' },
	}
	local out = {}
	for i, entry in ipairs(OW.SidebarEntries(pages)) do out[i] = entry.group and ('[' .. entry.group .. ']') or entry.name end
	eq(table.concat(out, ','), 'Global Settings,Profiles,[Frames],Unitframes,Chat,[Combat],Auras,[Info],Loot,[Misc],Odd,[Other],Zeta',
		'the fixed order; pages keep the order they came in')
end)

------------------------------------------------------------------ a custom type's bare row

test("a bare row: no label, the body's width, at the cell's top left, its widget's height plus 12, and no mouse on its row", function()
	W.Define('windowbare', {
		bare = true,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = {
			-- Its height follows its width, so the cell's height shows the width came first.
			SetWidth = function(self, width)
				self.frame:SetWidth(width)
				self.frame:SetHeight(width / 7)
			end,
			Refresh = function() end,
		},
	})
	local module = st:NewModule('BareRows')
	function module:GetConfigTable()
		local function toggle(name, order)
			return { type = 'toggle', name = name, desc = name, order = order, get = function() return true end, set = function() end }
		end
		return {
			name = 'Bare rows', type = 'group', category = 'Frames',
			args = {
				before = toggle('Before', 1),
				beside = toggle('Beside', 2),
				bare = { type = 'windowbare', name = 'Bare', desc = 'A bare row.', size = 'wide', order = 3 },
				after = toggle('After', 4),
			},
		}
	end

	st.Config:Open('BareRows')
	eq(drawn(), 'before,beside,bare,after', 'the bare row between normal rows')
	local c = cell('bare')
	check(not c.label:IsShown(), 'no label')
	check(cell('before').label:IsShown(), 'a normal row has one')
	eq(c.widget.frame:GetWidth(), 774, "the widget has the body's width")
	eq(c.frame:GetWidth(), 774, 'and the cell is the whole line')
	local point, rel, relPoint, x, y = c.widget.frame:GetPoint(1)
	eq(point, 'TOPLEFT', "at the cell's top left")
	check(rel == c.frame, 'in its cell')
	eq(relPoint, 'TOPLEFT')
	eq(x, 0)
	eq(y, -6, '6 down')
	eq(c.height, math.ceil(774 / 7) + 12, "the widget's height, at the body's width, rounded up, plus 12")
	eq(c.y, cell('before').y + 34, 'on the line after the normal rows')
	eq(cell('after').y, c.y + c.height, 'and the next row under it')
	check(not c.frame:IsMouseEnabled(), 'its row takes no mouse')
	check(cell('before').frame:IsMouseEnabled() and cell('after').frame:IsMouseEnabled(), 'a normal row does')

	-- Row frames are pooled: the bare row's, drawn again for a normal row, takes the mouse again.
	-- Inventory's General tab, named: the window remembers each page's tab,
	-- and its other tabs may have too few rows to reuse the frame.
	local bareFrame = c.frame
	OW:Navigate('Inventory', { tab = 'general' })
	local reused
	for _, other in ipairs(OW.GetDrawnRows()) do
		if other.frame == bareFrame then reused = other end
	end
	check(reused ~= nil, "the bare row's frame was drawn again")
	check(reused and reused.frame:IsMouseEnabled(), 'and takes the mouse as a normal row')

	module.GetConfigTable = nil
	close_all()
end)

test("a titled bare row: its name above the widget, the desc its name's tooltip, the widget 28 down, its height plus 34", function()
	W.Define('windowtitled', {
		bare = true,
		titled = true,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = {
			SetWidth = function(self, width)
				self.frame:SetWidth(width)
				self.frame:SetHeight(40)
			end,
			Refresh = function() end,
		},
	})
	eq(W.CUSTOM.windowtitled.bare, true, 'W.CUSTOM marks it bare')
	eq(W.CUSTOM.windowtitled.titled, true, 'and titled')
	local module = st:NewModule('TitledRows')
	function module:GetConfigTable()
		local function toggle(name, order)
			return { type = 'toggle', name = name, desc = name, order = order, get = function() return true end, set = function() end }
		end
		return {
			name = 'Titled rows', type = 'group', category = 'Frames',
			args = {
				before = toggle('Before', 1),
				titled = { type = 'windowtitled', name = 'Titled', desc = 'A titled row.', size = 'wide', order = 2 },
				after = toggle('After', 3),
			},
		}
	end

	st.Config:Open('TitledRows')
	eq(drawn(), 'before,titled,after', 'the titled row between normal rows')
	local c = cell('titled')
	check(c.label:IsShown(), 'its name shows')
	eq(c.label:GetText(), 'Titled', 'its name')
	local point, rel, relPoint, x, y = c.label:GetPoint(1)
	eq(point .. relPoint, 'TOPLEFTTOPLEFT', "at the cell's top left")
	check(rel == c.frame, 'in its cell')
	eq(x, 0)
	eq(y, -6, '6 down')
	eq(c.widget.frame:GetWidth(), 774, "the widget has the body's width")
	point, rel, relPoint, x, y = c.widget.frame:GetPoint(1)
	eq(point .. relPoint, 'TOPLEFTTOPLEFT', "the widget at the cell's left")
	check(rel == c.frame, 'in its cell')
	eq(x, 0)
	eq(y, -28, '28 down, under its name')
	eq(c.height, 40 + 34, "its widget's height plus 34")
	eq(cell('after').y, c.y + c.height, 'the next row under it')
	check(not c.frame:IsMouseEnabled(), 'its row takes no mouse')

	-- The desc is its name's tooltip.
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	local tip = c.frame.titleTip
	check(tip ~= nil and tip:IsShown() and tip:IsMouseEnabled(), 'its name takes the mouse')
	point, rel, relPoint, x, y = tip:GetPoint(1)
	check(point == 'TOPLEFT' and rel == c.label and relPoint == 'TOPLEFT' and x == 0 and y == 0, 'over the name')
	eq(tip:GetWidth(), math.ceil(c.label:GetUnboundedStringWidth()), 'as wide as the name')
	eq(tip:GetHeight(), 16, 'and as tall')
	stub.fire_script(tip, 'OnEnter')
	check(GameTooltip:IsOwned(c.frame) and GameTooltip:IsShown(), 'a tooltip')
	eq(stub.state(GameTooltip).texts[1], 'Titled', 'its name')
	eq(stub.state(GameTooltip).texts[2], 'A titled row.', 'and its desc')
	stub.fire_script(tip, 'OnLeave')
	check(not GameTooltip:IsShown(), 'gone when the mouse leaves')

	-- Row frames are pooled: drawn again for a normal row, the name's hit frame goes.
	-- Inventory's General tab, named, as above.
	local titledFrame = c.frame
	OW:Navigate('Inventory', { tab = 'general' })
	local reused
	for _, other in ipairs(OW.GetDrawnRows()) do
		if other.frame == titledFrame then reused = other end
	end
	check(reused ~= nil, "the titled row's frame was drawn again")
	check(not titledFrame.titleTip:IsShown(), "a normal row has no name's hit frame")

	module.GetConfigTable = nil
	close_all()
end)

test("a fill row stretches to the body's visible height, so the body has nothing to scroll; it follows the window's size, and other pages are as they were", function()
	local heights = {}
	local module = FillRowsModule(heights)
	eq(W.CUSTOM.windowfill.fill, true, 'W.CUSTOM marks it fill')
	eq(W.CUSTOM.windowfill.minHeight, 100, 'with its least height')
	module.GetConfigTable = FillRowsTable

	-- Another page first: its height and the body's edges, to compare.
	OW:Navigate('Inventory', { tab = 'general' })
	local F = frames()
	local bodyRight = F.body:GetRight()
	eq(bodyRight, F.content:GetRight(), "a page's body clips at its content's right edge")
	local generalHeight = F.content:GetHeight()
	check(generalHeight < F.body:GetHeight(), 'a short page')

	st.Config:Open('FillRows')
	eq(drawn(), 'before,fill,after', 'the fill row between normal rows')
	local view = F.body:GetHeight()
	local c = cell('fill')
	eq(c.y + c.height + 34 + 24, view, 'the fill row takes what the rows around it leave (the row after it, the bottom padding)')
	eq(c.widget.frame:GetHeight(), c.height - 12, 'its widget is told its height: the cell less its padding')
	eq(heights[#heights], c.height - 12, 'through SetHeight')
	eq(c.widget.frame:GetWidth(), 774, "the body's width, as a bare row")
	eq(cell('after').y, c.y + c.height, 'the next row under it')
	eq(F.content:GetHeight(), view, 'the drawn height is the visible height')
	check(not F.bar:IsShown(), 'nothing to scroll: no bar')
	eq(F.body:GetRight() - F.content:GetRight(), 13, "the body's clip reaches over its own bar's place, 13 past the content, for the row's own bars")

	-- The window grows: the row follows once the body's size changes.
	local renders = OW.GetRenderCount()
	stub.fire_script(F.body, 'OnSizeChanged', F.body:GetWidth(), view)
	tick()
	eq(OW.GetRenderCount(), renders, 'the same height: no render')
	F.window:SetHeight(800)
	eq(F.body:GetHeight(), view + 100, 'a taller window, a taller body')
	stub.fire_script(F.body, 'OnSizeChanged', F.body:GetWidth(), view + 100)
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'drawn again')
	c = cell('fill')
	eq(c.widget.frame:GetHeight(), heights[#heights - 1] + 100, 'the fill row is 100 taller')
	eq(F.content:GetHeight(), view + 100, 'and the drawn height the new visible height')

	-- Too small a window: the row keeps its least height, and the body scrolls.
	F.window:SetHeight(250)
	stub.fire_script(F.body, 'OnSizeChanged', F.body:GetWidth(), F.body:GetHeight())
	tick()
	c = cell('fill')
	eq(c.widget.frame:GetHeight(), 100, 'its least height')
	check(F.content:GetHeight() > F.body:GetHeight(), 'more than the body shows')
	check(F.bar:IsShown(), 'the body has a bar')
	eq(F.bar:GetLeft() - F.content:GetLeft(), 774 + 10, 'still 10 to the right of the content')
	F.window:SetHeight(700)

	-- Other pages: drawn as before, the body back to its own edges.
	OW:Navigate('Inventory', { tab = 'general' })
	eq(F.body:GetRight(), bodyRight, "the body's edge as before")
	eq(F.content:GetHeight(), generalHeight, 'the page as tall as before')
	local before = #heights
	stub.fire_script(F.body, 'OnSizeChanged', F.body:GetWidth(), F.body:GetHeight() + 50)
	tick()
	eq(#heights, before, 'no fill row: a size change draws nothing')

	module.GetConfigTable = nil
	close_all()
end)

------------------------------------------------------------------ a disabled row's tooltip

-- GameTooltip, as a stand-in that notes each line it's given with its color.
local function watch_tooltip()
	local tip = { lines = {}, colors = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines, tip.colors = {}, {} end,
		AddLine = function(_, text, r, g, b)
			tip.lines[#tip.lines + 1] = text
			tip.colors[#tip.colors + 1] = r and string.format('%.2f,%.2f,%.2f', r, g, b) or 'default'
		end,
		Show = function() end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner = nil end,
	}
	return tip, function() _G.GameTooltip = saved end
end

-- The cursor on the middle of frame, in screen units.
local function hover(frame)
	local scale = frame:GetEffectiveScale()
	stub.cursor_x = (frame:GetLeft() + frame:GetRight()) / 2 * scale
	stub.cursor_y = (frame:GetTop() + frame:GetBottom()) / 2 * scale
end

test("a disabled row's tooltip shows its disabledDesc under its desc, in Text > Red; the mouse on its box reaches the row", function()
	local lock = true
	local function toggle(name, order, fields)
		local option = { type = 'toggle', name = name, order = order, get = function() return true end, set = function() end }
		for key, value in pairs(fields or {}) do option[key] = value end
		return option
	end
	local root = { page = { type = 'group', name = 'Page', args = {
		locked = toggle('Locked', 1, { desc = 'What it does.', disabled = function() return lock end,
			disabledDesc = function() return 'Uncheck Other first.' end }),
		free = toggle('Free', 2, { desc = 'Its own.', disabledDesc = 'Never shown: it is enabled.' }),
		bare = toggle('Bare', 3, { disabled = true, disabledDesc = 'Only why.' }),
		plain = toggle('Plain', 4, { desc = 'No reason.', disabled = true }),
	} } }
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 400)
	local body = st.OptionsBody.New(content, root, nil, 774)
	body:Draw(OM.BuildView(root, 'page').sections)
	-- In the game a check box starts out taking the mouse (the stubs' frames
	-- don't), so the boxes are given it and drawn again from the pool: only
	-- Bind can then take it off a disabled one.
	local primed = {}
	for _, c in ipairs(body.cells) do
		c.widget.frame:EnableMouse(true)
		primed[c.widget.frame] = true
	end
	body:Release()
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do
		by[c.row.key] = c
		check(primed[c.widget.frame], c.row.key .. ': a box that took the mouse, reused')
	end
	local tip, restore = watch_tooltip()
	local red = string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.red:GetRGB())

	-- The mouse on a disabled box: the box takes none, so the row is under it.
	local locked = by.locked
	eq(locked.widget.frame:IsMouseEnabled(), false, 'the disabled box gave up the mouse it had')
	hover(locked.widget.frame)
	check(locked.frame:IsMouseMotionFocus(), 'the row gets the hover over its disabled box')
	check(not locked.widget.frame:IsMouseMotionFocus(), 'not the box')
	stub.fire_script(locked.frame, 'OnEnter')
	check(tip.owner == locked.frame, 'the tooltip shows for the row')
	eq(table.concat(tip.lines, '|'), 'Locked|What it does.|Uncheck Other first.', 'its name, desc, then why')
	eq(tip.colors[3], red, 'why in Text > Red')
	stub.fire_script(locked.frame, 'OnLeave')
	check(tip.owner == nil, 'and goes')

	-- An enabled box takes the mouse, and an enabled row shows no reason.
	hover(by.free.widget.frame)
	check(by.free.widget.frame:IsMouseMotionFocus(), 'an enabled box takes the hover')
	stub.fire_script(by.free.frame, 'OnEnter')
	eq(table.concat(tip.lines, '|'), 'Free|Its own.', 'no reason while enabled')

	-- A reason alone shows; no reason, just the desc.
	stub.fire_script(by.bare.frame, 'OnEnter')
	eq(table.concat(tip.lines, '|'), 'Bare|Only why.', 'a reason with no desc still shows')
	stub.fire_script(by.plain.frame, 'OnEnter')
	eq(table.concat(tip.lines, '|'), 'Plain|No reason.', 'a disabled row with none: its desc')

	-- Enabled on the next draw: no reason, and its box takes the mouse again.
	lock = false
	body:Release()
	body:Draw(OM.BuildView(root, 'page').sections)
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	stub.fire_script(by.locked.frame, 'OnEnter')
	eq(table.concat(tip.lines, '|'), 'Locked|What it does.', 'enabled: its desc alone')
	hover(by.locked.widget.frame)
	check(by.locked.widget.frame:IsMouseMotionFocus(), 'and its box takes the hover again')
	restore()
	body:Release()
end)

------------------------------------------------------------------ an execute button's tooltip

test("an execute button shows its row's tooltip while the mouse is on it, under Thick and Blizzard; a disabled one shows why through its row", function()
	local lock = false
	local root = { page = { type = 'group', name = 'Page', args = {
		reset = { type = 'execute', name = 'Reset', order = 1, desc = 'Puts it back.', func = function() end,
			disabled = function() return lock end, disabledDesc = 'Nothing to reset.' },
		bare = { type = 'execute', name = 'Plain', order = 2, func = function() end },
	} } }
	local tip, restore = watch_tooltip()
	local red = string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.red:GetRGB())
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		st.config.profile.theme.name = look
		local content = CreateFrame('Frame', nil, UIParent)
		content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
		content:SetSize(774, 400)
		local body = st.OptionsBody.New(content, root, nil, 774)
		lock = false
		body:Draw(OM.BuildView(root, 'page').sections)
		local by = {}
		for _, c in ipairs(body.cells) do by[c.row.key] = c end
		local button = by.reset.widget.frame

		stub.fire_script(button, 'OnEnter')
		check(tip.owner == button, look .. ': the tooltip is the button\'s')
		eq(table.concat(tip.lines, '|'), 'Reset|Puts it back.', look .. ': its name and desc, no why while enabled')
		stub.fire_script(button, 'OnLeave')
		check(tip.owner == nil, look .. ': gone when the mouse leaves')
		tip.lines = {}

		-- The button's edge still lights under Thick.
		if look == 'thick' then
			local blue = { st.config.profile.colors.button.blue:GetRGB() }
			stub.fire_script(button, 'OnEnter')
			eq((button:GetBackdropBorderColor()), blue[1], 'the edge lights')
			stub.fire_script(button, 'OnLeave')
			check((button:GetBackdropBorderColor()) ~= blue[1], 'and goes out')
		end

		-- No desc and no why: no tooltip.
		stub.fire_script(by.bare.widget.frame, 'OnEnter')
		check(tip.owner == nil, look .. ': a button with nothing to say shows none')

		-- The row's own empty space keeps its tooltip.
		stub.fire_script(by.reset.frame, 'OnEnter')
		check(tip.owner == by.reset.frame, look .. ': the row beside the button shows it too')
		stub.fire_script(by.reset.frame, 'OnLeave')

		-- Disabled: the button takes no mouse, so the row under it says why.
		lock = true
		body:Release()
		body:Draw(OM.BuildView(root, 'page').sections)
		for _, c in ipairs(body.cells) do by[c.row.key] = c end
		eq(by.reset.widget.frame:IsMouseEnabled(), false, look .. ': a disabled button takes no mouse')
		stub.fire_script(by.reset.frame, 'OnEnter')
		eq(table.concat(tip.lines, '|'), 'Reset|Puts it back.|Nothing to reset.', look .. ': name, desc, then why')
		eq(tip.colors[3], red, look .. ': why in Text > Red')
		stub.fire_script(by.reset.frame, 'OnLeave')
		body:Release()
	end
	restore()
	st.config.profile.theme.name = 'thick'
end)
