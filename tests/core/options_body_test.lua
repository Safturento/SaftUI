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

test('a toggle and a color sit at their cell\'s right edge, a toggle at normal and small size and a color at normal, the label taking the rest', function()
	local body, by = draw_body(774, {
		{ 'nt', 'toggle', 'Normal toggle' }, { 'st', 'toggle', 'Small', 'small' }, { 'sc', 'color', 'Tint', 'small' }, -- the model makes it normal
		{ 'nc', 'color', 'A color that is long' },
	})
	for key, c in pairs(by) do
		local point, rel, relPoint, x = c.widget.frame:GetPoint(1)
		eq(point, 'RIGHT', key .. ' point')
		check(rel == c.frame, key .. ' is anchored to its cell')
		eq(relPoint, 'RIGHT', key .. ' at the cell\'s right')
		eq(x, 0, key .. ' offset')
		local cellWidth = c.row.size == 'small' and 165 or 359 -- under Thick: a 387 column inside its 14 of padding, a 193 quarter likewise
		eq(c.label:GetWidth(), cellWidth - c.widget:GetWidth() - 10, key .. ' label is the rest of the cell')
	end
	body:Release()
end)

test('a color row gets the room a select row gets: a normal half, so its label and its bar fit', function()
	-- Marked small, as the Colors page marks its rows: the model makes it normal.
	local body, by = draw_body(774, {
		{ 'c1', 'color', 'Tint', 'small' }, { 'c2', 'color', 'Another tint', 'small' },
		{ 'c3', 'color', 'A third' }, { 's', 'select', 'Pick' },
	})
	eq(by.c1.row.size, 'normal', 'small is not honored for a color')
	local _, _, _, x1 = by.c1.frame:GetPoint(1)
	local _, _, _, x2 = by.c2.frame:GetPoint(1)
	eq(x1, 14, 'the first in the left half, inside the padding (Thick)')
	eq(x2, 401, 'the second in the right half, not beside the first in a quarter')
	eq(by.c1.frame:GetWidth(), 359, 'a half wide, as a select\'s')
	eq(by.c1.frame:GetWidth(), by.s.frame:GetWidth(), 'as a select row')
	eq(by.c1.label:GetWidth(), 359 - 170 - 10, 'the label has the rest beside the bar')
	eq(by.c3.y, by.c1.y + 38, 'a third colour starts the next line (rows are 38 tall under Thick)')
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
	eq(c.label:GetWidth(), 359 - 18 - 10, 'the normal cell\'s width, not the small one\'s')
	eq(c.label:GetStringWidth(), c.label:GetUnboundedStringWidth(), 'so the game reports it uncut')
	body:Release()
end)

test('the body draws dividers a line tall: between the halves at 387, between two smalls of the left half at 193, and through a last line with one row (Thick)', function()
	local body, by = draw_body(774, {
		{ 'a', 'toggle', 'A', 'small' }, { 'b', 'toggle', 'B', 'small' }, { 'c', 'toggle', 'C' },
		{ 'w', 'description', 'Wide text' }, { 'd', 'toggle', 'D' },
	})
	local got = {}
	-- Under Thick the dividers are the panel's hairlines (white at 7%), not OB.LINE's.
	for _, line in ipairs(body.pools.hairline.used) do
		if line:GetWidth() == 1 then
			local _, _, _, x, y = line:GetPoint(1)
			got[#got + 1] = x .. ',' .. -y .. ',' .. line:GetHeight()
		end
	end
	table.sort(got)
	local y = by.a.y
	-- The first line's dividers start at its top; d's line, the section's last,
	-- has a divider too (its right half is empty), starting under its hairline.
	eq(table.concat(got, ' '), '193,' .. y .. ',38 387,' .. y .. ',38 387,' .. (by.d.y + 1) .. ',37',
		'none beside the wide row; one through the last line, the lone half')
	eq(#body.pools.line.used, 0, 'none from the old line pool')
	body:Release()
end)

test('a position cell is wide, has no label, is the block plus 12 tall, and shows the row\'s desc over the block', function()
	local body, by = draw_body(774, { { 'pos', 'position', 'Position' }, { 'after', 'toggle', 'After' } })
	local c = by.pos
	eq(c.height, 65 + 12, 'the widget plus 12')
	eq(c.frame:GetWidth(), 746, 'the whole line, inside the padding (Thick)')
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
	eq(c.label:GetWidth(), 165 - 18 - 10, 'the label gives way')
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
	-- Under Thick a 387 column's quarters are 193 wide with no gap, the second
	-- ending at 387, and each cell is its slot inset by 14 either side.
	eq(w.a.x, 14); eq(w.b.x, 208); eq(w.c.x, 401)
	eq(w.a.w, 165); eq(w.b.w, 165); eq(w.c.w, 359)
	eq(w.d.x, 14); eq(w.e.x, 208); eq(w.f.x, 401); eq(w.f.w, 165)
	local d = xs(520)
	eq(d.a.x, 14); eq(d.b.x, 144); eq(d.c.x, 274)
	eq(d.a.w, 102); eq(d.b.w, 102); eq(d.c.w, 232)
	eq(d.f.x, 274); eq(d.f.w, 102)
	local _, wide = draw_body(520, { { 'w', 'input', 'Wide', 'wide' } })
	eq(wide.w.frame:GetWidth(), 492, 'a wide row takes the body\'s width less the padding')
end)

test("buttons aligned right sit at the right end of a wide row's line, which ends 24 before them; centred ones in the middle; no dividers", function()
	local body, by = draw_body(520, {
		{ 'pick', 'select', 'Copy from', 'wide' },
		{ 'all', 'execute', 'All', 'small', 'right' }, { 'none', 'execute', 'None', nil, 'right' },
		{ 'a', 'toggle', 'A' }, { 'b', 'toggle', 'B' },
		{ 'ok', 'execute', 'Confirm copy', nil, 'center' }, { 'cancel', 'execute', 'Cancel', nil, 'center' },
	})
	-- All and None: 80 wide each (a small size changes nothing), 12 apart, None flush with the right edge.
	-- Under Thick the line of buttons lies in the cell, 14 in from each edge.
	eq(point_x(by.all.frame) .. '+' .. by.all.frame:GetWidth(), '334+80', 'All')
	eq(point_x(by.none.frame) .. '+' .. by.none.frame:GetWidth(), '426+80', 'None ends at 506')
	check(by.all.y == by.pick.y and by.none.y == by.pick.y, "on the wide row's line")
	-- The wide row ends 24 before All, and its label has the rest.
	eq(point_x(by.pick.frame), 14, 'the wide row at the left, inside the padding')
	eq(by.pick.frame:GetWidth(), 296, 'up to 24 before All')
	eq(by.pick.label:GetWidth(), 296 - 170 - 10, 'its label is the rest of the cell')
	local point, rel, relPoint = by.pick.widget.frame:GetPoint(1)
	check(point == 'RIGHT' and rel == by.pick.frame and relPoint == 'RIGHT', "the dropdown at its cell's right end")
	-- Each button at its cell's left, the cell as wide as the button; in its
	-- middle by its top (6 down a 38 row), on whole pixels.
	for _, key in ipairs({ 'all', 'none', 'ok', 'cancel' }) do
		local p, r, rp, x, y = by[key].widget.frame:GetPoint(1)
		check(p == 'TOPLEFT' and r == by[key].frame and rp == 'TOPLEFT' and x == 0, key .. ' at its cell\'s left')
		eq(y, -math.floor((by[key].height - 26) / 2), key .. ' in the middle of its row, by its top')
		eq(by[key].frame:GetWidth(), by[key].widget:GetWidth(), key .. "'s cell is the button's width")
	end
	-- Confirm copy and Cancel: a pair in the middle, Confirm copy first, 12 apart.
	local okWidth, cancelWidth = by.ok.widget:GetWidth(), by.cancel.widget:GetWidth()
	local left = 14 + math.floor((492 - okWidth - 12 - cancelWidth) / 2)
	eq(point_x(by.ok.frame), left, 'Confirm copy on the left')
	eq(point_x(by.cancel.frame), left + okWidth + 12, 'Cancel 12 after it')
	check(math.abs(left - (520 - (left + okWidth + 12 + cancelWidth))) <= 1, 'the same room either side')
	-- The last line, of buttons alone: under the panel, 24 below (Thick).
	check(by.ok.y == by.cancel.y and by.ok.y == by.a.y + 38 + 24, 'one line, under the toggles\' panel')
	-- The one divider is the toggles', between the halves at 260.
	local got = {}
	for _, line in ipairs(body.pools.hairline.used) do
		if line:GetWidth() == 1 then
			local _, _, _, x, y = line:GetPoint(1)
			got[#got + 1] = x .. ',' .. -y
		end
	end
	eq(table.concat(got, ' '), '260,' .. (by.a.y + 1), "none beside the buttons; the toggles' starts under the hairline above them")
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
	eq(point_x(by.pick.frame) .. '+' .. by.pick.frame:GetWidth(), '14+232', 'the wide row a half, inside the padding (Thick)')
	eq(point_x(by.all.frame) .. '+' .. by.all.frame:GetWidth(), '274+232', 'the button the other half')
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
		{ key = 'Fonts', name = 'Global settings', category = 'Other', special = 'global' },
		{ key = 'chat', name = 'Chat', category = 'Frames' },
		{ key = 'odd', name = 'Odd', category = 'Misc' },
	}
	local out = {}
	for i, entry in ipairs(OW.SidebarEntries(pages)) do out[i] = entry.group and ('[' .. entry.group .. ']') or entry.name end
	eq(table.concat(out, ','), 'Global settings,Profiles,[Frames],Unitframes,Chat,[Combat],Auras,[Info],Loot,[Misc],Odd,[Other],Zeta',
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
	eq(c.widget.frame:GetWidth(), 746, "the widget has the cell's width (the body's less the 14 of padding either side, under Thick)")
	eq(c.frame:GetWidth(), 746, 'and the cell is the whole line, inside the padding')
	local point, rel, relPoint, x, y = c.widget.frame:GetPoint(1)
	eq(point, 'TOPLEFT', "at the cell's top left")
	check(rel == c.frame, 'in its cell')
	eq(relPoint, 'TOPLEFT')
	eq(x, 0)
	eq(y, -6, '6 down')
	eq(c.height, math.ceil(746 / 7) + 12, "the widget's height, at the cell's width, rounded up, plus 12")
	eq(c.y, cell('before').y + 38, 'on the line after the normal rows (38 tall under Thick)')
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
	eq(c.widget.frame:GetWidth(), 746, "the widget has the cell's width (the body's less the padding, under Thick)")
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
	eq(c.y + c.height + 38 + 24, view, 'the fill row takes what the rows around it leave (the row after it, 38 tall under Thick, the bottom padding)')
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
	-- The game passes OnEnter and OnLeave a second argument (motion: true when
	-- the mouse moved in), so the row's scripts must not take it for an owner.
	stub.fire_script(locked.frame, 'OnEnter', true)
	check(tip.owner == locked.frame, 'the tooltip shows for the row')
	eq(table.concat(tip.lines, '|'), 'Locked|What it does.|Uncheck Other first.', 'its name, desc, then why')
	eq(tip.colors[3], red, 'why in Text > Red')
	stub.fire_script(locked.frame, 'OnLeave', true)
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

------------------------------------------------------------------ section panels, hairlines and the padding

-- A texture as 'x,y WxH' (its first point's offsets, as the content's TOPLEFT).
local function rect(tex)
	local _, _, _, x, y = tex:GetPoint(1)
	return x .. ',' .. -y .. ' ' .. tex:GetWidth() .. 'x' .. tex:GetHeight()
end

local function color_of(tex)
	local c = stub.state(tex).color_texture
	return c and (c[1] .. ',' .. c[2] .. ',' .. c[3] .. ',' .. c[4])
end

local function shown(pool)
	local list = {}
	for _, t in ipairs(pool.used) do
		if t:IsShown() then list[#list + 1] = t end
	end
	return list
end

local function sorted_rects(pool)
	local got = {}
	for _, t in ipairs(shown(pool)) do got[#got + 1] = rect(t) end
	table.sort(got)
	return got
end

local function in_look(look, fn)
	st.config.profile.theme.name = look
	local ok, err = pcall(fn)
	st.config.profile.theme.name = 'thick'
	if not ok then error(err, 0) end
end

test('OB.Hairlines: every distinct line top but the first, ascending', function()
	local OB = st.OptionsBody
	eq(#OB.Hairlines({}), 0, 'none for nothing')
	local placed = {
		{ col = 1, y = 0 }, { col = 2, y = 0 }, { col = 'full', y = 38 },
		{ col = 'buttons', y = 38 }, { col = 1, y = 76 }, { col = 1, y = 114, quarter = 1 }, { col = 1, y = 114, quarter = 2 },
	}
	eq(table.concat(OB.Hairlines(placed), ','), '38,76,114', 'the first line has none')
	eq(#OB.Hairlines({ { col = 1, y = 0 } }), 0, 'one line, none')
	eq(OB.PANELED.rowHeight .. ',' .. OB.PANELED.pad .. ',' .. OB.PANELED.columnGap .. ',' .. OB.PANELED.quarterGap, '38,14,0,0')
	eq(OB.FLAT.rowHeight .. ',' .. OB.FLAT.pad .. ',' .. OB.FLAT.columnGap .. ',' .. OB.FLAT.quarterGap, '34,0,40,24')
	eq(OB.PANELED.panels, true); eq(OB.FLAT.panels, false)
end)

test('LayoutSections gives each section the height its rows take', function()
	local laid = OW.LayoutSections({ { title = 'A', rows = { { key = 'a' }, { key = 'b' }, { key = 'c' } } } })
	eq(laid[1].rowsHeight, 68, 'two lines')
end)

test('under Thick and Thin a section sits on a faded panel, rows 38 tall, 14 in from their slots', function()
	for _, look in ipairs({ 'thick', 'thin' }) do
		in_look(look, function()
			local body, by = draw_body(774, {
				{ 'a', 'range', 'A' }, { 'b', 'range', 'B' },
				{ 'c', 'toggle', 'C', 'small' }, { 'd', 'toggle', 'D', 'small' }, { 'e', 'toggle', 'E', 'small' }, { 'f', 'toggle', 'F', 'small' },
			})
			eq(point_x(by.a.frame) .. '+' .. by.a.frame:GetWidth(), '14+359', look .. ': a half, inside its padding')
			eq(point_x(by.b.frame) .. '+' .. by.b.frame:GetWidth(), '401+359', look .. ': the second half')
			eq(table.concat({ point_x(by.c.frame), point_x(by.d.frame), point_x(by.e.frame), point_x(by.f.frame) }, ','), '14,208,401,595', look .. ': quarters')
			eq(by.c.frame:GetWidth(), 165, look .. ': a quarter inside its padding')
			eq(by.a.height, 38, look .. ': rows are 38 tall')
			local panels = shown(body.pools.panel)
			eq(#panels, 1, look .. ': one panel')
			eq(rect(panels[1]), '0,' .. by.a.y .. ' 774x76', look .. ': the rows\' top, 774 x 76')
			eq(color_of(panels[1]), table.concat(st.OptionsBody.PANEL_FILL, ','), look .. ': black at 28%')
			eq(panels[1]:GetDrawLayer(), 'BACKGROUND', look .. ': behind the rows')
			local hairlines = shown(body.pools.hairline)
			local y = by.a.y + 38
			local got, dividers = {}, {}
			for _, h in ipairs(hairlines) do
				eq(color_of(h), table.concat(st.OptionsBody.HAIRLINE, ','), look .. ': white at 7%')
				eq(h:GetDrawLayer(), 'BORDER', look .. ': in the border layer')
				if h:GetHeight() == 1 then got[#got + 1] = rect(h) else dividers[#dividers + 1] = rect(h) end
			end
			eq(table.concat(got, ' '), '0,' .. y .. ' 774x1', look .. ': one hairline, at the second line\'s top')
			table.sort(dividers)
			local y1 = by.a.y
			-- the first line has two ranges (one divider, at 387); the second two small pairs (193, 580) and the halves (387).
			-- The second line's start one pixel under the hairline at its top, so the junction isn't drawn twice.
			local want = { '193,' .. (y + 1) .. ' 1x37', '387,' .. (y + 1) .. ' 1x37', '387,' .. y1 .. ' 1x38', '580,' .. (y + 1) .. ' 1x37' }
			table.sort(want)
			eq(table.concat(dividers, ' '), table.concat(want, ' '), look .. ': dividers a line tall, under the hairline')
			eq(#shown(body.pools.line), 0, look .. ': no line between sections, none for dividers')
			body:Release()
		end)
	end
end)

test('under Blizzard the body is laid out as before, with no panel or hairline', function()
	in_look('blizzard', function()
		local body, by = draw_body(774, {
			{ 'a', 'range', 'A' }, { 'b', 'range', 'B' },
			{ 'c', 'toggle', 'C', 'small' }, { 'd', 'toggle', 'D', 'small' }, { 'e', 'toggle', 'E', 'small' }, { 'f', 'toggle', 'F', 'small' },
		})
		eq(point_x(by.a.frame) .. '+' .. by.a.frame:GetWidth(), '0+367')
		eq(point_x(by.b.frame) .. '+' .. by.b.frame:GetWidth(), '407+367')
		eq(table.concat({ point_x(by.c.frame), point_x(by.d.frame), point_x(by.e.frame), point_x(by.f.frame) }, ','), '0,196,407,603')
		eq(by.c.frame:GetWidth(), 171, 'a quarter')
		eq(by.a.height, 34, 'rows are 34 tall')
		eq(#body.pools.panel.used, 0, 'no panel')
		eq(#body.pools.hairline.used, 0, 'no hairline')
		local got = {}
		for _, line in ipairs(shown(body.pools.line)) do
			eq(color_of(line), table.concat(st.OptionsBody.LINE, ','), 'in OB.LINE')
			got[#got + 1] = rect(line)
		end
		table.sort(got)
		local y = by.a.y
		local want = { '387,' .. y .. ' 1x34', '183,' .. y + 34 .. ' 1x34', '387,' .. y + 34 .. ' 1x34', '590,' .. y + 34 .. ' 1x34' }
		table.sort(want)
		eq(table.concat(got, ' '), table.concat(want, ' '), "the dividers, at today's places")
		body:Release()
	end)
end)

test('panels, hairlines and dividers sit on whole pixels at any width', function()
	for _, width in ipairs({ 774, 520, 540, 525 }) do
		local body = draw_body(width, {
			{ 'a', 'range', 'A' }, { 'b', 'range', 'B' },
			{ 'c', 'toggle', 'C', 'small' }, { 'd', 'toggle', 'D', 'small' }, { 'e', 'toggle', 'E', 'small' }, { 'f', 'toggle', 'F', 'small' },
		})
		local count = 0
		for _, pool in ipairs({ body.pools.panel, body.pools.hairline }) do
			for _, t in ipairs(shown(pool)) do
				count = count + 1
				local _, _, _, x, y = t:GetPoint(1)
				for _, n in ipairs({ x, y, t:GetWidth(), t:GetHeight() }) do
					eq(n, math.floor(n), width .. ': a whole number')
				end
			end
		end
		check(count >= 4, width .. ': panels, hairlines and dividers were drawn')
		local x2, w2 = body:SlotRect(2)
		eq(x2 + w2, width, width .. ': the second half ends flush with the body')
		local qx, qw = body:SlotRect(1, 2)
		eq(qx + qw, body.columnWidth, width .. ': the second quarter ends flush with the column')
		for _, args in ipairs({ { 1 }, { 2 }, { 1, 1 }, { 1, 2 }, { 2, 1 }, { 2, 2 }, { 'full' } }) do
			local sx, sw = body:SlotRect(args[1], args[2])
			local cx, cw = body:CellRect(args[1], args[2])
			eq(cx .. '+' .. cw, (sx + 14) .. '+' .. (sw - 28), width .. ': the cell is the slot inset by 14')
		end
		body:Release()
	end
end)

test('position blocks, descriptions, bare rows, aligned buttons and results sit inside the padding; a fill row does not', function()
	W.Define('padbare', {
		bare = true,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = {
			SetWidth = function(self, width) self.frame:SetWidth(width) end,
			Refresh = function() end,
		},
	})
	W.Define('padfill', {
		bare = true, fill = true, minHeight = 100,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = { Refresh = function() end },
	})
	local function draw(options)
		local args = {}
		for i, o in ipairs(options) do
			args[o[1]] = { type = o[2], name = o[3], size = o[4], align = o[5], order = i, desc = o[1], func = function() end,
				values = { a = 'A' }, get = o[2] == 'range' and function() return 1 end or nil, min = 0, max = 10, step = 1 }
		end
		local root = { page = { type = 'group', name = 'Page', args = args, get = function() return true end, set = function() end } }
		return root
	end
	local function body_of(root, width)
		local body = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), root, nil, width)
		body:Draw(OM.BuildView(root, 'page').sections)
		local by = {}
		for _, c in ipairs(body.cells) do by[c.row.key] = c end
		return body, by
	end

	local body, by = body_of(draw({
		{ 'pos', 'position', 'Position' }, { 'desc', 'description', 'Some words' }, { 'bare', 'padbare', 'Bare', 'wide' },
		{ 'pick', 'select', 'Pick', 'wide' }, { 'x', 'execute', 'X', nil, 'right' }, { 'y', 'execute', 'Y', nil, 'right' },
	}), 774)
	eq(point_x(by.pos.frame), 14, 'a position row at 14')
	eq(point_x(by.desc.frame) .. '+' .. by.desc.frame:GetWidth(), '14+746', 'a description 14 in and 746 wide')
	eq(by.desc.widget:GetWidth(), 746, 'its text is wrapped to 746')
	eq(point_x(by.bare.frame) .. '+' .. by.bare.frame:GetWidth(), '14+746', 'a bare row at 14')
	eq(by.bare.widget.frame:GetWidth(), 746, 'its widget given 746')
	eq(point_x(by.y.frame) + by.y.frame:GetWidth(), 760, "a 'right' group's last button ends at 760")
	check(by.x.y == by.y.y, 'one line of buttons')
	eq(#shown(body.pools.panel), 1, 'the position block\'s section and the rows after it, one panel')
	body:Release()

	-- Results: halves at 14 and 401 on a panel.
	local root = draw({ { 'a', 'toggle', 'A' }, { 'b', 'toggle', 'B' } })
	local results = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), root, nil, 774)
	results:DrawResults(OM.BuildView(root, 'page').sections, function() end)
	local rby = {}
	for _, c in ipairs(results.cells) do rby[c.row.key] = c end
	eq(point_x(rby.a.frame) .. '+' .. rby.a.frame:GetWidth(), '14+359', 'a result in the first half')
	eq(point_x(rby.b.frame) .. '+' .. rby.b.frame:GetWidth(), '401+359', 'a result in the second')
	eq(#shown(results.pools.panel), 1, 'on a panel')
	results:Release()

	-- A fill row: the whole line, and its section has no panel.
	local fillBody, fby = body_of(draw({ { 'fill', 'padfill', 'Fill', 'wide' } }), 774)
	eq(point_x(fby.fill.frame) .. '+' .. fby.fill.frame:GetWidth(), '0+774', 'a fill row at 0, 774 wide')
	eq(#shown(fillBody.pools.panel), 0, 'no panel')
	eq(#shown(fillBody.pools.hairline), 0, 'no hairline')
	fillBody:Release()
end)

------------------------------------------------------------------ fix round 1: joined panels, fill sections, releases

-- A page of options (each { key, type, name, order, fields }) as a root.
local function tree(args)
	return { page = {
		type = 'group', name = 'Page', args = args,
		get = function() return true end, set = function() end,
	} }
end

local function toggle(name, order, fields)
	local option = { type = 'toggle', name = name, order = order }
	for k, v in pairs(fields or {}) do option[k] = v end
	return option
end

local function inline(name, order, args)
	return { type = 'group', name = name, inline = true, order = order, args = args }
end

local function button(name, order, align)
	return { type = 'execute', name = name, order = order, align = align, func = function() end }
end

local function drawn_root(root, width)
	local body = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), root, nil, width or 774)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by
end

-- The body's shown hairline textures: the lines (as wide as the body, 1 tall) and the dividers, as rects.
local function hairline_rects(body)
	local lines, dividers = {}, {}
	for _, h in ipairs(shown(body.pools.hairline)) do
		if h:GetHeight() == 1 then lines[#lines + 1] = rect(h) else dividers[#dividers + 1] = rect(h) end
	end
	table.sort(lines); table.sort(dividers)
	return lines, dividers
end

test('under panels rows after an inline group join its panel: one panel, no gap, a hairline between; a line of buttons there floats under it (Unitframes > Copy from)', function()
	for _, look in ipairs({ 'thick', 'thin' }) do
		in_look(look, function()
			local body, by = drawn_root(tree({
				settings = inline('Settings', 1, { t1 = toggle('One', 1), t2 = toggle('Two', 2) }),
				accept = button('Confirm copy', 2, 'center'), cancel = button('Cancel', 3, 'center'),
			}))
			check(by.accept.y == by.cancel.y, look .. ': Confirm copy and Cancel on one line')
			-- Buttons alone continuing the section float under its panel, 24 below, as the bottom margin under them.
			eq(by.accept.y, by.t1.y + 38 + 24, look .. ': the buttons 24 under the toggles\' panel')
			local tall = by.accept.widget:GetHeight()
			check(tall < 38, look .. ': a button is less than a row tall')
			eq(by.accept.height .. ',' .. by.accept.frame:GetHeight(), tall .. ',' .. tall, look .. ': their line as tall as the buttons')
			local panels = shown(body.pools.panel)
			eq(#panels, 1, look .. ': one panel, the toggles\'')
			eq(rect(panels[1]), '0,' .. by.t1.y .. ' 774x38', look .. ': ending above the buttons')
			local lines, dividers = hairline_rects(body)
			eq(#lines, 0, look .. ': no hairline over the buttons')
			eq(table.concat(dividers, ' '), '387,' .. by.t1.y .. ' 1x38', look .. ': the toggles\' divider only')
			local total = by.accept.frame:GetWidth() + 12 + by.cancel.frame:GetWidth()
			eq(point_x(by.accept.frame), math.floor((774 - total) / 2), look .. ': the pair in the middle')
			body:Release()
		end)
	end

	-- A continuation after a titled group in the middle of a page, and the sections on either side keep their own panels.
	local body, by = drawn_root(tree({
		first = toggle('First', 1),
		nested = inline('Nested', 2, { n1 = toggle('N1', 1), n2 = toggle('N2', 2) }),
		c = toggle('C', 3), d = toggle('D', 4),
	}))
	eq(by.c.y, by.n1.y + 38, 'the continuation directly under the group\'s rows')
	local panels = shown(body.pools.panel)
	eq(#panels, 2, 'the page\'s own section, and the group with its continuation')
	local got = { rect(panels[1]), rect(panels[2]) }
	local want = { '0,' .. by.first.y .. ' 774x38', '0,' .. by.n1.y .. ' 774x76' }
	table.sort(got); table.sort(want)
	eq(table.concat(got, ' '), table.concat(want, ' '), 'the first section\'s, and the group\'s over its continuation')
	body:Release()

	-- Blizzard keeps the 4px continuation gap and has no panel.
	in_look('blizzard', function()
		local flat, fby = drawn_root(tree({
			nested = inline('Nested', 1, { n1 = toggle('N1', 1), n2 = toggle('N2', 2) }),
			c = toggle('C', 2), d = toggle('D', 3),
		}))
		eq(fby.c.y, fby.n1.y + 34 + 4, 'Blizzard: 4 below the group\'s rows, as before')
		eq(#flat.pools.panel.used, 0, 'Blizzard: no panel')
		flat:Release()
	end)
end)

test('a section holding a fill row: the lines without a fill cell get their panel, hairlines and divider; only the fill row is bare', function()
	W.Define('mixfill', {
		bare = true, fill = true, minHeight = 100,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = { Refresh = function() end },
	})
	-- The nameplate pages' General: three toggles over the centred line.
	local body, by = drawn_root(tree({
		a = toggle('A', 1, { size = 'small' }), b = toggle('B', 2, { size = 'small' }), c = toggle('C', 3),
		sourced = { type = 'mixfill', name = 'Sourced', order = 4, size = 'wide' },
	}))
	local panels = shown(body.pools.panel)
	eq(#panels, 1, 'one panel')
	eq(panels[1] and rect(panels[1]), '0,' .. by.a.y .. ' 774x38', 'over the toggles\' line only')
	eq(point_x(by.sourced.frame) .. '+' .. by.sourced.frame:GetWidth(), '0+774', 'the fill row bare, the whole line')
	eq(point_x(by.a.frame) .. '+' .. by.a.frame:GetWidth(), '14+165', 'the toggles padded')
	local lines, dividers = hairline_rects(body)
	eq(#lines, 0, 'no hairline over the fill row')
	eq(table.concat(dividers, ' '), '193,' .. by.a.y .. ' 1x38 387,' .. by.a.y .. ' 1x38', 'the toggles\' dividers')
	body:Release()

	-- Lines either side of the fill row each get a panel; a hairline within a run only.
	body, by = drawn_root(tree({
		x1 = toggle('X1', 1), x2 = toggle('X2', 2), x3 = toggle('X3', 3), x4 = toggle('X4', 4),
		fill = { type = 'mixfill', name = 'Fill', order = 5, size = 'wide' },
		y1 = toggle('Y1', 6), y2 = toggle('Y2', 7),
	}))
	local got = {}
	for _, panel in ipairs(shown(body.pools.panel)) do got[#got + 1] = rect(panel) end
	table.sort(got)
	local want = { '0,' .. by.x1.y .. ' 774x76', '0,' .. by.y1.y .. ' 774x38' }
	table.sort(want)
	eq(table.concat(got, ' '), table.concat(want, ' '), 'a panel over the lines above the fill row, another under it')
	local lines2 = hairline_rects(body)
	eq(table.concat(lines2, ' '), '0,' .. by.x3.y .. ' 774x1', 'a hairline between the two lines above; none beside the fill row')
	eq(#shown(body.pools.panel), 2)
	body:Release()
end)

test('a divider starts under the hairline at the top of its line, so the crossing is drawn once', function()
	local body, by = drawn_root(tree({
		a = toggle('A', 1), b = toggle('B', 2), c = toggle('C', 3), d = toggle('D', 4),
		e = toggle('E', 5), f = toggle('F', 6),
	}))
	local lines, dividers = hairline_rects(body)
	eq(table.concat(lines, ' '), '0,' .. by.c.y .. ' 774x1 0,' .. by.e.y .. ' 774x1', 'the hairlines at the second and third lines')
	eq(table.concat(dividers, ' '), '387,' .. by.a.y .. ' 1x38 387,' .. (by.c.y + 1) .. ' 1x37 387,' .. (by.e.y + 1) .. ' 1x37',
		'the first line\'s divider whole, the others one pixel under their hairlines and one shorter')
	body:Release()
end)

test("a section's last line with one row: the divider runs through it, to the panel's bottom; a wide or full line has none", function()
	local body, by = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), c = toggle('C', 3) }))
	local panel = shown(body.pools.panel)[1]
	local _, dividers = hairline_rects(body)
	eq(table.concat(dividers, ' '), '387,' .. by.a.y .. ' 1x38 387,' .. (by.c.y + 1) .. ' 1x37', 'both lines')
	eq(panel:GetHeight(), 76)
	local _, _, _, _, py = panel:GetPoint(1)
	local last = shown(body.pools.hairline)
	local bottom = 0
	for _, h in ipairs(last) do
		local _, _, _, _, hy = h:GetPoint(1)
		if h:GetWidth() == 1 then bottom = math.max(bottom, -hy + h:GetHeight()) end
	end
	eq(bottom, -py + panel:GetHeight(), 'to the panel\'s bottom')
	body:Release()

	-- A lone small is a lone half too.
	body, by = drawn_root(tree({ a = toggle('A', 1, { size = 'small' }) }))
	_, dividers = hairline_rects(body)
	eq(table.concat(dividers, ' '), '387,' .. by.a.y .. ' 1x38', 'a lone small')
	body:Release()

	-- A last line of one wide row, or of buttons: none.
	body, by = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), w = toggle('W', 3, { size = 'wide' }) }))
	_, dividers = hairline_rects(body)
	eq(table.concat(dividers, ' '), '387,' .. by.a.y .. ' 1x38', 'the first line\'s only')
	body:Release()
	body, by = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), ok = button('OK', 3, 'center') }))
	_, dividers = hairline_rects(body)
	eq(table.concat(dividers, ' '), '387,' .. by.a.y .. ' 1x38', 'none beside a line of buttons')
	body:Release()

	-- Blizzard draws no more than before: no divider through a lone last half.
	in_look('blizzard', function()
		local flat, fby = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), c = toggle('C', 3) }))
		local got = {}
		for _, line in ipairs(shown(flat.pools.line)) do got[#got + 1] = rect(line) end
		eq(table.concat(got, ' '), '387,' .. fby.a.y .. ' 1x34', 'Blizzard: the first line\'s only')
		flat:Release()
	end)
end)

test('OB.Dividers with its last-line flag: a lone left half on the last line gets a half divider; without it, as before', function()
	local OB = st.OptionsBody
	local function r(key, size) return { key = key, size = size } end
	local placed = OW.LayoutRows({ r('a'), r('b'), r('c') })
	local function list(dividers)
		local got = {}
		for _, d in ipairs(dividers) do got[#got + 1] = d.at .. '@' .. d.y .. '+' .. d.height end
		return table.concat(got, ' ')
	end
	eq(list(OB.Dividers(placed)), 'half@0+34', 'today')
	eq(list(OB.Dividers(placed, nil, true)), 'half@0+34 half@34+34', 'through the last line')
	placed = OW.LayoutRows({ r('a'), r('b'), r('c'), r('w', 'wide') })
	eq(list(OB.Dividers(placed, nil, true)), 'half@0+34', 'a lone half that is not the last line gets none')
	placed = OW.LayoutRows({ r('a') })
	eq(list(OB.Dividers(placed, function() return 60 end, true)), 'half@0+60', 'as tall as the line')
end)

test('LayoutSections: with panels an untitled section after another joins it with no gap, and says so; a note or title still parts', function()
	local function rows(n)
		local list = {}
		for i = 1, n do list[i] = { key = 'r' .. i, size = 'normal' } end
		return list
	end
	local sections = {
		{ rows = rows(2) }, { title = 'Group', rows = rows(2) }, { rows = rows(2) }, { title = 'Next', rows = rows(1) },
	}
	local flat = OW.LayoutSections(sections)
	eq(flat[3].rowsY, flat[2].rowsY + flat[2].rowsHeight + 4, 'flat: 4 under the rows above')
	check(not flat[3].joins, 'flat: not joined')
	local joined = OW.LayoutSections(sections, nil, nil, nil, true)
	eq(joined[3].rowsY, joined[2].rowsY + joined[2].rowsHeight, 'panels: right under them')
	check(joined[3].joins and not joined[2].joins and not joined[1].joins and not joined[4].joins, 'only the continuation joins')
	check(joined[4].lineY ~= nil, 'a titled section still has its line')
end)

------------------------------------------------------------------ task 4 fix round 1: a section's closing buttons float

test('LayoutSections: with panels and floatOf every line of rows that float sits off the panel, FLOAT_GAP from it, lines of them 12 apart and the closing one FLOAT_GAP; else as before', function()
	local OB = st.OptionsBody
	eq(OB.FLOAT_GAP, 24, "as far under the panel as the body's bottom margin is under its rows: midway")
	eq(OB.BOTTOM, 24, "the body's bottom margin")
	local function r(key, size, align) return { key = key, size = size, align = align } end
	local floating = { ok = 24, no = 22, go = 24, reset = 24, n1 = 26, n2 = 26, n3 = 26, n4 = 26, e1 = 26, e2 = 26, close = 26 }
	local function floatOf(row) return floating[row.key] end
	local sections = {
		{ title = 'A', rows = { r('a'), r('b'), r('ok', nil, 'center'), r('no', nil, 'center') } },
		{ rows = { r('x'), r('go', 'small') } }, -- go beside x: stays
		{ title = 'B', rows = { r('reset', 'small') } }, -- a section of a lone button
		{ title = 'C', rows = { r('c'), r('ok', nil, 'center'), r('d') } }, -- buttons mid-section
	}
	local laid = OW.LayoutSections(sections, nil, nil, nil, true, floatOf)
	local function ys(entry)
		local out = {}
		for _, p in ipairs(entry.placed) do out[#out + 1] = p.row.key .. '@' .. p.y .. (p.floats and ('f' .. p.floatHeight) or '') end
		return table.concat(out, ' ')
	end
	eq(ys(laid[1]), 'a@0 b@0 ok@58f24 no@58f24', 'A: its buttons 24 under the panel, marked floats, as tall as the tallest')
	check(laid[1].endsFloating, 'A ends with them')
	eq(laid[1].rowsHeight, 34 + 24 + 24, 'A: the rows, the gap, the line')
	eq(ys(laid[2]), 'x@0 go@0', 'the continuation: a row beside the button, nothing floats')
	check(not laid[2].endsFloating)
	check(not laid[2].joins, 'after floating buttons there is no panel to join: it starts its own')
	eq(laid[2].rowsY, laid[1].rowsY + laid[1].rowsHeight + 24, '24 under the floating line')
	eq(ys(laid[3]), 'reset@6f24', 'B: a lone button floats; no panel above it: 6 down, where it would sit on one')
	eq(laid[3].rowsHeight, 30)
	eq(ys(laid[4]), 'c@0 ok@58f24 d@106', 'C: buttons mid-section float too, 24 from the panel above and from the one below')
	check(not laid[4].endsFloating, 'C ends on the panel')
	eq(laid[4].rowsHeight, 106 + 34)

	-- Lines of buttons after each other (Unit frame profiles): 12 apart, the
	-- closing line 24 under the line above it.
	local stacked = OW.LayoutSections({ { title = 'D', rows = {
		r('p', 'wide'), r('n1', 'small'), r('n2', 'small'), r('n3', 'small'), r('n4', 'small'),
		r('e1', 'small'), r('e2', 'small'), r('close', nil, 'center'),
	} } }, nil, nil, nil, true, floatOf)
	eq(ys(stacked[1]), 'p@0 n1@58f26 n2@58f26 n3@58f26 n4@58f26 e1@96f26 e2@96f26 close@146f26',
		'the panel, 24, a line, 12, a line, 24, the closing line')
	eq(stacked[1].rowsHeight, 172)

	-- A continuation that joins the panel above and starts with buttons: 24 under it.
	local joined = OW.LayoutSections({
		{ title = 'E', rows = { r('a') } }, { rows = { r('ok', nil, 'center'), r('z') } },
	}, nil, nil, nil, true, floatOf)
	check(joined[2].joins, 'it joins')
	eq(joined[2].rowsY, joined[1].rowsY + 34, 'right under the panel above')
	eq(ys(joined[2]), 'ok@24f24 z@72', 'its buttons 24 under that panel, its row 24 under them')

	-- Without floatOf, or without panels: as before.
	for _, args in ipairs({ { true }, { nil, floatOf } }) do
		local plain = OW.LayoutSections(sections, nil, nil, nil, args[1], args[2])
		eq(ys(plain[1]), 'a@0 b@0 ok@34 no@34', 'as before')
		eq(plain[1].rowsHeight, 68)
		eq(plain[1].endsFloating, nil)
		eq(ys(plain[4]), 'c@0 ok@34 d@68', 'mid-section too')
	end
end)

-- A button is placed in its row by its top, half the room above it rounded
-- down: centred, a button shorter than its line by an odd amount would sit
-- half a unit down it, between two pixels (a 26 button in the 27 line the
-- game's read-back made, in the user's screenshots). No built-in button is
-- shorter than another, so one is made 21 tall here, through the pool.
test('a button shorter than its line by an odd amount sits on whole pixels, floating or on a panel', function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			local parent = CreateFrame('Frame', nil, UIParent)
			local tall, short = W.Create(parent, 'execute'), W.Create(parent, 'execute')
			short.frame:SetHeight(21)
			tall:Release()
			short:Release() -- taken first: Confirm copy's
			local body, by = drawn_root(tree({
				t = toggle('T', 1), ok = button('Confirm copy', 2, 'center'), cancel = button('Cancel', 3, 'center'),
			}))
			body.content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
			eq(by.ok.widget.frame:GetHeight(), 21, look .. ': Confirm copy is the short one')
			local top = by.ok.widget.frame:GetTop()
			eq(top, math.floor(top), look .. ': its top on a whole pixel')
			eq(by.ok.frame:GetTop() - top, math.floor((by.ok.height - 21) / 2), look .. ': in the middle of its line, rounded down')
			body:Release()
			short.frame:SetHeight(26)
		end)
	end
end)

test("under panels a line of buttons floats off the panel wherever it is, 24 from a panel, off the padding; one beside a row stays on it; Blizzard as before", function()
	local function reset(order) return { type = 'execute', name = 'Reset', size = 'small', order = order, func = function() end } end
	local function small(name, order) return { type = 'execute', name = name, size = 'small', order = order, func = function() end } end
	in_look('thick', function()
		-- A lone Reset after two halves (a Colors section with an even count).
		local body, by = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), reset = reset(3) }))
		local panels = shown(body.pools.panel)
		eq(#panels, 1, 'one panel')
		eq(rect(panels[1]), '0,' .. by.a.y .. ' 774x38', 'ending above the Reset')
		eq(by.reset.y, by.a.y + 38 + 24, '24 under it')
		eq(point_x(by.reset.frame), 0, "at its slot's left, off the padding: in line with the panel's edge")
		local tall = by.reset.widget:GetHeight()
		eq(by.reset.height .. ',' .. by.reset.frame:GetHeight(), tall .. ',' .. tall, 'its line as tall as the button')
		local p, rel, relPoint, x, y = by.reset.widget.frame:GetPoint(1)
		check(p == 'TOPLEFT' and rel == by.reset.frame and relPoint == 'TOPLEFT' and x == 0 and y == 0, 'the button fills its line')
		local lines, dividers = hairline_rects(body)
		eq(#lines, 0, 'no hairline')
		eq(table.concat(dividers, ' '), '387,' .. by.a.y .. ' 1x38', "the halves' divider only, none beside the Reset")
		body:Release()

		-- A Reset beside a row on its line stays on the panel (an odd count).
		body, by = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), c = toggle('C', 3), reset = reset(4) }))
		panels = shown(body.pools.panel)
		eq(rect(panels[1]), '0,' .. by.a.y .. ' 774x76', 'one panel over both lines')
		eq(by.reset.y, by.c.y, 'on the last line, beside C')
		eq(point_x(by.reset.frame), 401, 'inside the padding, as any row')
		eq(by.reset.height, 38)
		body:Release()

		-- Unit frame profiles' shape: the lines of small buttons under the profile
		-- float off the panel too, 24 under it and 12 apart. Buttons that share a
		-- floating line each take their whole slot, the slots 12 apart (as the
		-- lines are): the four an even row across the body, the two under them
		-- under the first two at their width. Close, alone on the closing line,
		-- 24 under them, keeps its own width, in the middle.
		body, by = drawn_root(tree({
			pick = { type = 'select', name = 'Profile', size = 'wide', order = 1, values = { a = 'A' } },
			new = small('New', 2), copy = small('Copy', 3), rename = small('Rename', 4), delete = small('Delete', 5),
			export = small('Export', 6), import = small('Import', 7),
			close = button('Close', 8, 'center'),
		}), 520)
		panels = shown(body.pools.panel)
		eq(#panels, 1)
		eq(rect(panels[1]), '0,' .. by.pick.y .. ' 520x38', "the profile's panel only")
		eq(by.new.y, by.pick.y + 38 + 24, 'New 24 under it')
		eq(by.new.height, by.new.widget:GetHeight(), 'its line as tall as its buttons')
		local function slots(keys)
			local out = {}
			for _, key in ipairs(keys) do
				local c = by[key]
				eq(c.widget.frame:GetWidth(), c.frame:GetWidth(), key .. ': the button is its cell')
				out[#out + 1] = point_x(c.frame) .. '+' .. c.widget.frame:GetWidth()
			end
			return table.concat(out, ' ')
		end
		-- (520 - 12) / 2 = 254 a half, (254 - 12) / 2 = 121 a quarter.
		eq(slots({ 'new', 'copy', 'rename', 'delete' }), '0+121 133+121 266+121 399+121', 'four even buttons, 12 apart, edge to edge')
		eq(slots({ 'export', 'import' }), '0+121 133+121', 'the two under the first two, as wide')
		eq(by.close.widget.frame:GetWidth(), 80, 'Close keeps its own width')
		eq(by.export.y, by.new.y + by.new.height + 12, 'Export 12 under New')
		eq(by.close.y, by.export.y + by.export.height + 24, 'Close 24 under Export')
		eq(point_x(by.close.frame), math.floor((520 - by.close.frame:GetWidth()) / 2), 'in the middle')
		lines, dividers = hairline_rects(body)
		eq(#lines + #dividers, 0, 'no hairline or divider by any line of buttons')
		body:Release()

		-- A line of buttons between two runs of rows: off the panel, 24 from each;
		-- each run its own panel, its last line's divider through a lone left half.
		body, by = drawn_root(tree({
			a = toggle('A', 1), b = toggle('B', 2), c = toggle('C', 3),
			go = button('Go', 4, 'center'), stop = button('Stop', 5, 'center'),
			d = toggle('D', 6), e = toggle('E', 7),
		}))
		panels = shown(body.pools.panel)
		local got = {}
		for _, panel in ipairs(panels) do got[#got + 1] = rect(panel) end
		table.sort(got, function(x, y) return tonumber(x:match(',(%d+)')) < tonumber(y:match(',(%d+)')) end)
		eq(table.concat(got, ' '), '0,' .. by.a.y .. ' 774x76 0,' .. by.d.y .. ' 774x38', 'a panel above, one below')
		eq(by.go.y, by.c.y + 38 + 24, 'the buttons 24 under the panel above')
		eq(by.d.y, by.go.y + by.go.height + 24, 'the next panel 24 under them')
		lines, dividers = hairline_rects(body)
		eq(table.concat(lines, ' '), '0,' .. by.c.y .. ' 774x1', "the first panel's hairline only")
		local want = { '387,' .. by.a.y .. ' 1x38', '387,' .. (by.c.y + 1) .. ' 1x37', '387,' .. by.d.y .. ' 1x38' }
		table.sort(want)
		eq(table.concat(dividers, ' '), table.concat(want, ' '), "the halves' dividers, through C's lone half, none by the buttons")
		body:Release()

		-- Right-aligned buttons ending a section: at the body's right edge, in line with the panel's.
		body, by = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), x = button('X', 3, 'right'), y = button('Y', 4, 'right') }))
		eq(point_x(by.y.frame) + by.y.frame:GetWidth(), 774, "the last ends at the body's right edge")
		eq(by.x.y, by.a.y + 38 + 24)
		body:Release()

		-- Rows that continue a section after its floating buttons: a panel of their own, 24 under them.
		body, by = drawn_root(tree({
			g = inline('Group', 1, { n = toggle('N', 1), ok = button('OK', 2, 'center') }),
			after = toggle('After', 2),
		}))
		eq(by.ok.y, by.n.y + 38 + 24, "the group's buttons float")
		eq(by.after.y, by.ok.y + by.ok.height + 24, 'the rows after them 24 below')
		local got = {}
		for _, panel in ipairs(shown(body.pools.panel)) do got[#got + 1] = rect(panel) end
		table.sort(got)
		local want = { '0,' .. by.n.y .. ' 774x38', '0,' .. by.after.y .. ' 774x38' }
		table.sort(want)
		eq(table.concat(got, ' '), table.concat(want, ' '), "the group's panel, and one of their own")
		body:Release()
	end)

	-- Blizzard: no panel, nothing floats: the line where it was.
	in_look('blizzard', function()
		local flat, fby = drawn_root(tree({ a = toggle('A', 1), b = toggle('B', 2), reset = reset(3) }))
		eq(fby.reset.y, fby.a.y + 34, 'Blizzard: the next line')
		eq(fby.reset.height, 34, 'a row tall')
		eq(point_x(fby.reset.frame), 0)
		flat:Release()
		flat, fby = drawn_root(tree({
			settings = inline('Settings', 1, { t1 = toggle('One', 1), t2 = toggle('Two', 2) }),
			accept = button('Confirm copy', 2, 'center'), cancel = button('Cancel', 3, 'center'),
		}))
		eq(fby.accept.y, fby.t1.y + 34 + 4, 'Blizzard: Copy from\'s buttons 4 under the settings, as before')
		flat:Release()
	end)
end)

-- A line of buttons right under a description, mid-section, is that
-- description's: it stays on the panel with it, inside the padding, as any
-- row (review F1: the Profiles page's Reset Profile floated 24 from the text
-- that explains it, at x 0 under text at 14, as near the next panel as its
-- own). A section's closing line still floats, under a description too (the
-- bags' Miscellaneous editor's Reset under its note).
test('LayoutSections: a line of buttons right under a description, mid-section, stays on the panel with it; a closing line, or one after any other row, floats', function()
	-- A description across the line, as the model gives the Profiles page's.
	local function r(key, rowType, align)
		return { key = key, type = rowType, align = align, size = rowType == 'description' and 'wide' or nil }
	end
	local function floatOf(row) return row.type == 'execute' and 26 or nil end
	local laid = OW.LayoutSections({
		{ title = 'A', rows = { r('note', 'description'), r('go', 'execute'), r('more', 'description') } },
		{ title = 'B', rows = { r('note', 'description'), r('ok', 'execute', 'center'), r('no', 'execute', 'center') } },
		{ title = 'C', rows = { r('t', 'toggle'), r('ok', 'execute', 'center') } },
	}, nil, nil, nil, true, floatOf)
	local function ys(entry)
		local out = {}
		for _, p in ipairs(entry.placed) do out[#out + 1] = p.row.key .. '@' .. p.y .. (p.floats and 'f' or '') end
		return table.concat(out, ' ')
	end
	eq(ys(laid[1]), 'note@0 go@34 more@68', "A: Go on the panel under its note, the next row under it")
	eq(ys(laid[2]), 'note@0 ok@58f no@58f', "B: a closing pair under a note floats: they're the section's")
	check(laid[2].endsFloating, 'B ends with them')
	eq(ys(laid[3]), 't@0 ok@58f', 'C: under a toggle, the buttons float')
end)

test("the Profiles page's Reset Profile stays on the panel under the description that explains it, inside the padding", function()
	st.Config:Open('profile')
	local reset, desc
	local cells = OW.GetDrawnRows()
	for i, c in ipairs(cells) do
		if c.row.key == 'reset' then reset, desc = c, cells[i - 1] end
	end
	check(reset ~= nil, 'Reset Profile drawn')
	eq(desc.row.type, 'description', 'right after its description')
	eq(reset.y, desc.y + desc.height, 'on the next line, under it')
	eq(reset.height, 38, "a row's height, on the panel")
	eq((select(4, reset.frame:GetPoint(1))), 14, 'inside the padding, in line with the text above it')
	local on = false
	for _, p in ipairs(reset.body.pools.panel.used) do
		local _, _, _, _, py = p:GetPoint(1)
		local top, bottom = -py, -py + p:GetHeight()
		if top <= desc.y and bottom >= reset.y + reset.height then on = true end
	end
	check(on, 'one panel under the description and the button')
	close_all()
end)

test('Release hides every panel and hairline, so a smaller draw on the same body shows only its own', function()
	local body = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), nil, nil, 774)
	local big = tree({
		first = toggle('First', 1), second = toggle('Second', 2), third = toggle('Third', 3),
		g1 = inline('One', 4, { a = toggle('A', 1), b = toggle('B', 2), c = toggle('C', 3), d = toggle('D', 4) }),
		g2 = inline('Two', 5, { e = toggle('E', 1), f = toggle('F', 2), g = toggle('G', 3), h = toggle('H', 4) }),
	})
	body:SetRoot(big)
	body:Draw(OM.BuildView(big, 'page').sections)
	local panels, hairlines = #shown(body.pools.panel), #shown(body.pools.hairline)
	check(panels >= 3 and hairlines >= 5, 'a page of three sections draws several panels and hairlines')
	body:Release()
	eq(#body.pools.panel.used, 0, 'no panel in use')
	eq(#body.pools.hairline.used, 0, 'no hairline in use')
	eq(#body.pools.panel.free, panels, 'every panel back in its pool')
	eq(#body.pools.hairline.free, hairlines, 'every hairline back in its pool')
	for _, pool in ipairs({ body.pools.panel, body.pools.hairline }) do
		for _, texture in ipairs(pool.free) do check(not texture:IsShown(), 'a released texture is hidden') end
	end

	-- A smaller page on the same body: only its own.
	local small = tree({ a = toggle('A', 1), b = toggle('B', 2) })
	body:SetRoot(small)
	body:Draw(OM.BuildView(small, 'page').sections)
	eq(#shown(body.pools.panel), 1, 'one panel')
	eq(#shown(body.pools.hairline), 1, 'one hairline: the halves\' divider')
	local visible = 0
	for _, pool in ipairs({ body.pools.panel, body.pools.hairline }) do
		for _, texture in ipairs(pool.free) do
			if texture:IsShown() then visible = visible + 1 end
		end
	end
	eq(visible, 0, 'nothing left shown in the pools\' free lists')

	-- Search results release the same way.
	body:Release()
	body:DrawResults(OM.BuildView(small, 'page').sections, function() end)
	eq(#shown(body.pools.panel), 1, 'results: one panel')
	body:Release()
	eq(#body.pools.panel.used + #body.pools.hairline.used, 0, 'results released')
end)

test('through the window a page change and search results leave no panel or hairline of the page before', function()
	local function painted(color)
		local n, want = 0, table.concat(color, ',')
		for _, region in ipairs({ frames().content:GetRegions() }) do
			local c = region:GetObjectType() == 'Texture' and region:IsShown() and stub.state(region).color_texture
			if c and table.concat(c, ',') == want then n = n + 1 end
		end
		return n
	end
	local OB = st.OptionsBody
	st.Config:Open('Loot')
	OW:Navigate('Inventory', { tab = 'general' })
	local inventoryPanels, inventoryHairlines = painted(OB.PANEL_FILL), painted(OB.HAIRLINE)
	check(inventoryPanels >= 1 and inventoryHairlines >= 3, 'Inventory General draws a panel and several hairlines')
	st.Config:Open('Loot')
	eq(painted(OB.PANEL_FILL), 1, 'a one-row page: one panel, none left over')
	eq(painted(OB.HAIRLINE), 1, 'and one hairline (the divider through its one row)')
	OW:Navigate('Inventory', { tab = 'general' })
	eq(painted(OB.PANEL_FILL), inventoryPanels, 'back again: as before')
	eq(painted(OB.HAIRLINE), inventoryHairlines, 'with the same hairlines')
	frames().search:SetText('frame wid')
	tick(0.3)
	local results = #OW.GetDrawnRows()
	check(results >= 1, 'search results')
	local panels = painted(OB.PANEL_FILL)
	check(panels >= 1 and panels <= results, 'a panel per result section, none of the page before')
	frames().search:SetText('')
	close_all()
end)

test('DrawResults reads the look again: a theme switch redraws the results on the other metrics', function()
	local root = tree({ a = toggle('A', 1), b = toggle('B', 2) })
	local body = st.OptionsBody.New(CreateFrame('Frame', nil, UIParent), root, nil, 774)
	local sections = OM.BuildView(root, 'page').sections
	body:DrawResults(sections, function() end)
	eq(body.cells[1].height, 38, 'Thick: a result 38 tall')
	eq(#shown(body.pools.panel), 1, 'on a panel')
	body:Release()
	in_look('blizzard', function()
		body:DrawResults(sections, function() end)
		eq(body.cells[1].height, 34, 'Blizzard: 34 tall')
		eq(#shown(body.pools.panel), 0, 'no panel')
		eq(point_x(body.cells[2].frame) .. '+' .. body.cells[2].frame:GetWidth(), '407+367', 'the second half at 407')
		eq(point_x(body.cells[1].frame) .. '+' .. body.cells[1].frame:GetWidth(), '0+367', 'the first at 0')
		body:Release()
	end)
	body:DrawResults(sections, function() end)
	eq(body.cells[1].height, 38, 'Thick again: 38')
	eq(body.cells[1].frame:GetHeight(), 38, 'its frame too')
	body:Release()
end)

test('a tall row: its label 11 down in a 38 band under Thick (9 in 34 under Blizzard), its divider as tall as the line', function()
	local values = {}
	for i = 1, 8 do values['k' .. i] = 'Value ' .. i end
	local function page()
		return tree({
			multi = { type = 'multiselect', name = 'Many', order = 1, values = values, get = function() return false end, set = function() end },
			other = toggle('Other', 2), after = toggle('After', 3),
		})
	end
	for _, case in ipairs({ { 'thick', 38, 11 }, { 'blizzard', 34, 9 } }) do
		in_look(case[1], function()
			local body, by = drawn_root(page())
			local c = by.multi
			check(c.height > case[2], case[1] .. ': the multiselect is taller than a row')
			local _, _, _, lx, ly = c.label:GetPoint(1)
			eq(lx .. ',' .. ly, '0,-' .. case[3], case[1] .. ': its label ' .. case[3] .. ' down')
			eq(by.after.y, c.y + c.height, case[1] .. ': the next line under the tall one')
			local divider
			local pool = case[1] == 'blizzard' and body.pools.line or body.pools.hairline
			for _, t in ipairs(shown(pool)) do
				if t:GetWidth() == 1 then
					local _, _, _, _, ty = t:GetPoint(1)
					if -ty == c.y then divider = t end
				end
			end
			check(divider ~= nil, case[1] .. ': a divider on the tall line')
			eq(divider and divider:GetHeight(), c.height, case[1] .. ': as tall as the line')
			body:Release()
		end)
	end
end)

test('a titled section\'s panel starts at its rows, under the title and note', function()
	local body, by = drawn_root(tree({
		g = { type = 'group', name = 'Titled', desc = 'A note.', inline = true, order = 1, args = { a = toggle('A', 1), b = toggle('B', 2) } },
	}))
	local panel = shown(body.pools.panel)[1]
	eq(rect(panel), '0,' .. by.a.y .. ' 774x38', 'the panel at the rows\' top')
	local title = body.pools.title.used[1]
	local _, _, _, _, ty = title:GetPoint(1)
	check(-ty < by.a.y, 'the title above the rows')
	check(by.a.y - (-ty) >= 15, 'with the title\'s own height between')
	body:Release()
end)

-- The same rows under both looks, each with its own numbers: Blizzard's layout is pinned beside Thick's.
test('the bare row, description, position block, results and buttons keep their flat layout under Blizzard', function()
	W.Define('flatbare', {
		bare = true,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = {
			SetWidth = function(self, width)
				self.frame:SetWidth(width)
				self.frame:SetHeight(width / 7)
			end,
			Refresh = function() end,
		},
	})
	local looks = {
		{ 'thick', 746, 14, 38, 774 },
		{ 'blizzard', 774, 0, 34, 774 },
	}
	for _, look in ipairs(looks) do
		local name, inside, pad, rowHeight = look[1], look[2], look[3], look[4]
		in_look(name, function()
			local root = tree({
				before = toggle('Before', 1),
				pos = { type = 'position', name = 'Position', order = 2 },
				text = { type = 'description', name = 'Some words', order = 3 },
				bare = { type = 'flatbare', name = 'Bare', order = 4, size = 'wide' },
				pick = { type = 'select', name = 'Pick', order = 5, size = 'wide', values = { a = 'A' } },
				all = button('All', 6, 'right'), none = button('None', 7, 'right'),
				after = toggle('After', 8),
			})
			local body, by = drawn_root(root, 774)
			eq(point_x(by.bare.frame) .. '+' .. by.bare.frame:GetWidth(), pad .. '+' .. inside, name .. ': the bare row\'s cell')
			eq(by.bare.widget.frame:GetWidth(), inside, name .. ': its widget given the cell\'s width')
			eq(by.bare.height, math.ceil(inside / 7) + 12, name .. ': its height follows')
			eq(point_x(by.text.frame) .. '+' .. by.text.frame:GetWidth(), pad .. '+' .. inside, name .. ': the description\'s cell')
			eq(by.text.widget:GetWidth(), inside, name .. ': wrapped to it')
			eq(by.text.height, rowHeight, name .. ': a one-line description is a row tall')
			eq(point_x(by.pos.frame) .. '+' .. by.pos.frame:GetWidth(), pad .. '+' .. inside, name .. ': the position block\'s cell')
			eq(by.after.y, by.none.y + rowHeight, name .. ': the line after the buttons')
			eq(by.pick.y, by.bare.y + by.bare.height, name .. ': the select under the bare row')
			-- Buttons: the last ends flush with the line's right edge inside the padding; the wide row stops 24 short of the first.
			eq(point_x(by.none.frame) + by.none.frame:GetWidth(), 774 - pad, name .. ': None ends at the right edge')
			eq(by.pick.frame:GetWidth(), point_x(by.all.frame) - 24 - pad, name .. ': the wide row ends 24 before All')
			body:Release()

			-- A wide row alone, in a dialog's width.
			local wide = drawn_root(tree({ w = { type = 'input', name = 'Wide', order = 1, size = 'wide' } }), 520)
			eq(wide.cells[1].frame:GetWidth(), 520 - 2 * pad, name .. ': a wide row takes the body less its padding')
			wide:Release()
		end)
	end
end)
