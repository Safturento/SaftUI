-- SaftUI-Core/Config/optionsbody.lua at half: the body of the /sui window when
-- the window is half wide (388 under Thick and Thin, 368 under Blizzard), which
-- lays each row out one size larger (OB.HalfSize), so the page is one column.
-- body:SetWidth(width, half) tells it; the next Draw lays the page out so.
--
-- Real: the body, the model, the widgets and the window's files
-- (options_window_helpers.lua). The pages are synthetic, one per case, and the
-- action bars page at half is in tests/actionbars/page_test.lua, the unit frames'
-- notes at half in tests/unitframes/config_test.lua.
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OM, OB = st.OptionsModel, st.OptionsBody

local function look(name, fn)
	st.config.profile.theme.name = name
	local ok, err = pcall(fn)
	st.config.profile.theme.name = 'thick'
	stub.size_noise = 0
	if not ok then error(err, 0) end
end

-- A body of width on a fresh content frame, told half (or not) before it draws,
-- with the given options on one page (each { key, type, name, size, align }).
-- Returns the body, its cells by key and the content frame.
local function draw_body(width, options, half)
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
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(width, 900)
	local body = OB.New(content, root, nil, width)
	if half ~= nil then body:SetWidth(width, half) end
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- The shown textures of a body's pool, as { x, y, width, height }, by y then x.
local function pieces(pool)
	local out = {}
	for _, t in ipairs(pool.used) do
		local _, _, _, x, y = t:GetPoint(1)
		out[#out + 1] = { x = x, y = -y, w = t:GetWidth(), h = t:GetHeight() }
	end
	table.sort(out, function(a, b) if a.y ~= b.y then return a.y < b.y end return a.x < b.x end)
	return out
end

local ROWS = {
	{ 'enable', 'toggle', 'Enable' }, { 'theme', 'select', 'Theme' }, { 'width', 'range', 'Width' }, { 'height', 'range', 'Height' },
	{ 'bg', 'select', 'Background' }, { 'tex', 'select', 'Texture' },
	{ 'q1', 'toggle', 'Hotkey', 'small' }, { 'q2', 'toggle', 'Stack count', 'small' },
	{ 'q3', 'toggle', 'Macro name', 'small' }, { 'q4', 'toggle', 'Cooldown', 'small' },
}

test('OB.HalfSize reads each row one size larger; a wide row stays wide', function()
	eq(OB.HalfSize({ size = 'small' }), 'normal', 'a quarter takes half of the narrow body')
	eq(OB.HalfSize({ size = 'normal' }), 'wide', 'a half takes the whole line')
	eq(OB.HalfSize({}), 'wide', 'no size is normal')
	eq(OB.HalfSize({ size = 'wide' }), 'wide', 'a wide row stays')
end)

test('at 388 under Thick and Thin: halves stack in their order, quarters pair up, each as wide as today', function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		look(name, function()
			local body, by, content = draw_body(388, ROWS, true)
			eq(body.width, 388); eq(body.half, true)
			eq(body.columnWidth, 194, name .. ': the halves are 194')
			local x1, w1 = body:SlotRect(1)
			local x2, w2 = body:SlotRect(2)
			eq(x1 .. ',' .. w1 .. ' ' .. x2 .. ',' .. w2, '0,194 194,194', name .. ': flush')
			local top = OB.TOP
			for i, key in ipairs({ 'enable', 'theme', 'width', 'height', 'bg', 'tex' }) do
				local c = by[key]
				eq(c.x .. ',' .. c.frame:GetWidth(), '14,360', name .. ' ' .. key .. ': 360 cell at 14')
				eq(c.y, top + (i - 1) * 38, name .. ' ' .. key .. ': one to a line, in its order')
			end
			eq(by.q1.x .. ',' .. by.q1.frame:GetWidth() .. ',' .. by.q1.y, '14,166,' .. (top + 6 * 38), name .. ': q1')
			eq(by.q2.x .. ',' .. by.q2.frame:GetWidth() .. ',' .. by.q2.y, '208,166,' .. (top + 6 * 38), name .. ': q2 on its line')
			eq(by.q3.x .. ',' .. by.q3.y, '14,' .. (top + 7 * 38), name .. ': q3 on the next')
			eq(by.q4.x .. ',' .. by.q4.y, '208,' .. (top + 7 * 38), name .. ': q4')
			-- A divider at 194 on each line of two quarters (and only those), a
			-- hairline at the top of every line but the first.
			local dividers, hairlines = {}, {}
			for _, p in ipairs(pieces(body.pools.hairline)) do
				if p.w == 1 then dividers[#dividers + 1] = p else hairlines[#hairlines + 1] = p end
			end
			eq(#dividers, 2, name .. ': a divider on each line of two')
			eq(dividers[1].x .. ',' .. dividers[1].y, '194,' .. (top + 6 * 38 + 1), name .. ': first divider, under the line\'s hairline')
			eq(dividers[2].x .. ',' .. dividers[2].y, '194,' .. (top + 7 * 38 + 1))
			eq(#hairlines, 7, name .. ': every line but the first')
			for i, p in ipairs(hairlines) do
				eq(p.w, 388, name .. ': a hairline the body wide')
				eq(p.y, top + i * 38, name .. ': at the top of line ' .. (i + 1))
			end
			-- Back to two columns: as options_body_test.lua pins them.
			body:Release()
			body:SetWidth(774, false)
			body:Draw(OM.BuildView(body.root, 'page').sections)
			eq(body.half, false)
			local back = {}
			for _, c in ipairs(body.cells) do back[c.row.key] = c end
			eq(back.enable.x .. ',' .. back.theme.x, '14,401', name .. ': two columns again at 774')
			eq(back.enable.y, back.theme.y, 'on one line')
			body:Release()
		end)
	end
end)

test('at 368 under Blizzard: the two columns 24 apart, each as wide as a quarter is today', function()
	look('blizzard', function()
		local body, by = draw_body(368, ROWS, true)
		eq(body.columnWidth, 172)
		local x1, w1 = body:SlotRect(1)
		local x2, w2 = body:SlotRect(2)
		eq(x1 .. ',' .. w1 .. ' ' .. x2 .. ',' .. w2, '0,172 196,172')
		eq(by.enable.x .. ',' .. by.enable.frame:GetWidth(), '0,368', 'a mapped half is the whole 368')
		eq(by.q1.x .. ',' .. by.q1.frame:GetWidth(), '0,172', 'a quarter is a column')
		eq(by.q2.x .. ',' .. by.q2.frame:GetWidth(), '196,172')
		eq(by.q1.y, by.q2.y, 'on one line')
		local found
		for _, p in ipairs(pieces(body.pools.line)) do
			if p.w == 1 then found = (found and found .. ' ' or '') .. p.x end
		end
		eq(found, '184 184', 'a divider in the middle of the 24 gap, on each line of two')
		body:Release()
	end)
end)

test("a small input keeps its 60 box; a section's titles and notes take the narrower width", function()
	local body, by = draw_body(388, { { 'name', 'input', 'Name', 'small' }, { 'other', 'input', 'Other' } }, true)
	eq(by.name.widget.frame:GetWidth(), 60, 'a small input at half is the 60 box')
	body:Release()

	local root = { page = {
		type = 'group', name = 'Page', args = {
			box = { type = 'group', inline = true, name = 'Box', desc = 'A note', order = 1, args = {
				a = { type = 'toggle', name = 'A', order = 1, get = function() return true end, set = function() end },
			} },
		},
	} }
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetSize(774, 400)
	body = OB.New(content, root, nil, 774)
	body:Draw(OM.BuildView(root, 'page').sections)
	eq(body.pools.title.used[1]:GetWidth(), 774)
	eq(body.pools.note.used[1]:GetWidth(), 774)
	body:Release()
	body:SetWidth(388, true)
	local count = 0
	for _, pool in ipairs({ body.pools.title, body.pools.note }) do
		for _, list in ipairs({ pool.used, pool.free }) do
			for _, fs in ipairs(list) do
				count = count + 1
				eq(fs:GetWidth(), 388, 'a pooled title or note, used or free')
			end
		end
	end
	check(count >= 2, 'the pooled ones were checked')
	body:Draw(OM.BuildView(root, 'page').sections)
	eq(body.pools.title.used[1]:GetWidth(), 388, 'the title drawn at the narrow width')
	eq(body.pools.note.used[1]:GetWidth(), 388)
	-- One acquired new after the change takes it too.
	local extra = body.pools.title.make()
	eq(extra:GetWidth(), 388, 'a title made after the change')
	body:Release()
end)

test('buttons aligned right join a row that is wide of its own, never one the half made wide', function()
	local placed = OB.LayoutRows({ { key = 'sel' }, { key = 'a', align = 'right' }, { key = 'b', align = 'right' } }, nil, OB.HalfSize)
	eq(placed[1].y, 0, 'sel on its line')
	eq(placed[2].y, 34, 'a on a line of its own')
	eq(placed[3].y, 34, 'b beside it')
	eq(placed[1].buttons, nil, 'sel has no buttons on its line')

	placed = OB.LayoutRows({ { key = 'w', size = 'wide' }, { key = 'a', align = 'right' } }, nil, OB.HalfSize)
	eq(placed[2].y, 0, 'a on the line of a row wide of its own')
	check(placed[1].buttons ~= nil and placed[1].buttons.rows[1].key == 'a', "placed[1].buttons is a's group")

	-- With no sizeOf: today's cases.
	placed = OB.LayoutRows({ { key = 'w', size = 'wide' }, { key = 'a', align = 'right' } })
	eq(placed[2].y, 0, 'unchanged: a wide row takes the group')
	placed = OB.LayoutRows({ { key = 'sel' }, { key = 'a', align = 'right' } })
	eq(placed[2].y, 34, 'unchanged: a normal row does not')
end)

test('search results are one to a line at half', function()
	local function root()
		local args = {}
		for i, name in ipairs({ 'One', 'Two', 'Three' }) do
			args['r' .. i] = { type = 'toggle', name = name, order = i, get = function() return true end, set = function() end }
		end
		return { page = { type = 'group', name = 'Page', args = args } }
	end
	local r = root()
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetSize(388, 400)
	local body = OB.New(content, r, nil, 388)
	body:SetWidth(388, true)
	body:DrawResults(OM.BuildView(r, 'page').sections, function() end)
	eq(#body.cells, 3)
	local first = body.cells[1].y
	for i, c in ipairs(body.cells) do
		eq(c.y - first, (i - 1) * 38, 'result ' .. i .. ' a line under the last')
		local _, _, _, x = c.frame:GetPoint(1)
		eq(x .. ',' .. c.frame:GetWidth(), '14,360', 'one to a line, the whole line')
	end
	body:Release()
	-- Not at half: two to a line, as before.
	body:SetWidth(774, false)
	body:DrawResults(OM.BuildView(r, 'page').sections, function() end)
	eq(body.cells[1].y, body.cells[2].y, 'two to a line at full')
	body:Release()
end)

test('a half body sits on whole pixels under every look, with the read-back noise', function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name, function()
			local width = name == 'blizzard' and 368 or 388
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				stub.size_noise = noise
				local body, _, content = draw_body(width, ROWS, true)
				local off = P.off(content)
				eq(#off, 0, name .. ' noise ' .. noise .. ': ' .. P.report(off))
				body:Release()
			end
		end)
	end
end)

test("a width change closes a color picker open from the body, before the page is drawn again; the same width leaves it", function()
	local W = st.OptionsWidgets
	local body, by = draw_body(774, { { 'c', 'color', 'Color' } }, false)
	local owner = by.c.widget.frame
	check(W.OpenColorPicker(owner, { r = 1, g = 0, b = 0, a = 1, onChange = function() end }), 'the picker opens')
	body:SetWidth(774, false)
	check(W.ColorPickerShown(), 'the same width and size: it stays')
	body:SetWidth(388, true)
	check(not W.ColorPickerShown(), 'half: it is closed')
	body:Release()
	body:Draw(OM.BuildView(body.root, 'page').sections)
	check(not W.ColorPickerShown(), 'and the draw opens none')
	body:Release()
end)

------------------------------------------------------------------ fix round 1

local N = load_test_file('lib/halfnotes.lua')

-- A page of one inline section with a note and two rows, drawn at width.
local function noted(width, half, note)
	local root = { page = {
		type = 'group', name = 'Page', args = {
			box = { type = 'group', inline = true, name = 'Box', desc = note, order = 1, args = {
				a = { type = 'toggle', name = 'A', order = 1, get = function() return true end, set = function() end },
				b = { type = 'toggle', name = 'B', order = 2, get = function() return true end, set = function() end },
			} },
		},
	} }
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(width, 900)
	local body = OB.New(content, root, nil, width)
	body:SetWidth(width, half)
	local height = body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content, height
end

local LONG = string.rep('word ', 24) .. 'end.' -- 100 characters: wider than 388 at 13 pt, narrower than 774

test("LayoutSections takes the height of each note from noteHeightOf; none given, the one line's 13", function()
	local sections = { { title = 'T', note = 'N', rows = { { key = 'a' } } } }
	local one = OB.LayoutSections(sections)
	local tall = OB.LayoutSections(sections, nil, nil, nil, nil, nil, function() return 39 end)
	eq(tall[1].rowsY - one[1].rowsY, 39 - 13, 'the rows are as much further down as the note is taller')
	eq(one[1].noteY, tall[1].noteY, 'the note starts where it did')
end)

test('a note that fits on one line lays out as it did; one that does not wraps to the body and moves the rows down', function()
	local _, byFull = noted(774, false, LONG)
	local _, byHalf, _, hHalf = noted(388, true, LONG)
	local _, byShort = noted(388, true, 'A short note.')
	local _, byShortFull = noted(774, false, 'A short note.')
	eq(byShort.a.y, byShortFull.a.y, 'a short note: the same rows y at half as at full')
	check(byHalf.a.y > byFull.a.y, 'a long note at half pushes the rows down')
	eq((byHalf.a.y - byFull.a.y) % 1, 0, 'by whole pixels')
	local body, _, content = noted(388, true, LONG)
	check(N.check(body, 'long note at 388') == 1, 'one note checked')
	body:Release()
	body, _, content = noted(774, false, LONG)
	N.check(body, 'long note at 774')
	body:Release()
end)

test('the real Colors, Icons and font notes at half: wrapped, clear of the rows, whole pixels under every look', function()
	local views = { { 'Fonts', { tab = 'colors' } }, { 'Fonts', { tab = 'general' } }, { 'Fonts', { tab = 'fonts' } } }
	local seen = 0
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name, function()
			local width = name == 'blizzard' and 368 or 388
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				stub.size_noise = noise
				for _, v in ipairs(views) do
					local root = st.Config:GetOptionsTable()
					local content = CreateFrame('Frame', nil, UIParent)
					content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
					content:SetSize(width, 4000)
					local body = OB.New(content, root, nil, 774)
					body:SetWidth(width, true)
					body:Draw(OM.BuildView(root, v[1], v[2]).sections)
					local where = name .. ' ' .. v[2].tab .. ' noise ' .. noise
					seen = seen + N.check(body, where)
					local off = P.off(content)
					eq(#off, 0, where .. ': ' .. P.report(off))
					body:Release()
				end
			end
		end)
	end
	check(seen >= 3 * 3 * 3, 'the pages have notes (' .. seen .. ' checked)')
end)

test('oneColumn wins over half: every row stays wide, one to a line', function()
	local store, args = {}, {}
	for i, key in ipairs({ 'a', 'b', 'c' }) do
		args[key] = { type = 'toggle', name = key, order = i, size = i == 3 and 'small' or nil, get = function() return true end, set = function() end }
	end
	local root = { page = { type = 'group', name = 'Page', args = args } }
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetSize(376, 400)
	local body = OB.New(content, root, nil, 376, { oneColumn = true })
	body:SetWidth(376, true)
	body:Draw(OM.BuildView(root, 'page').sections)
	local ys = {}
	for _, c in ipairs(body.cells) do
		ys[#ys + 1] = c.y
		eq(c.frame:GetWidth(), 376 - 28, c.row.key .. ': the whole line (a half body would give a small row a half)')
	end
	eq(ys[1] ~= ys[2] and ys[2] ~= ys[3], true, 'one to a line')
	body:Release()
end)

test('a color picker closes when only half changes, the width the same', function()
	local W = st.OptionsWidgets
	local body, by = draw_body(388, { { 'c', 'color', 'Color' } }, false)
	check(W.OpenColorPicker(by.c.widget.frame, { r = 1, g = 0, b = 0, a = 1, onChange = function() end }), 'the picker opens')
	body:SetWidth(388, false)
	check(W.ColorPickerShown(), 'nothing changed: it stays')
	body:SetWidth(388, true)
	check(not W.ColorPickerShown(), 'half changed at 388: it closes')
	body:Release()
end)

test('a description wraps to its 360 cell at half, not to the body', function()
	local body, by = draw_body(388, { { 'text', 'description', 'Some words.' } }, true)
	eq(by.text.widget.frame:GetWidth(), 360, 'Thick: the cell, 388 less the padding')
	body:Release()
	look('blizzard', function()
		local blizzard, row = draw_body(368, { { 'text', 'description', 'Some words.' } }, true)
		eq(row.text.widget.frame:GetWidth(), 368, 'Blizzard: no padding, the body')
		blizzard:Release()
	end)
end)
