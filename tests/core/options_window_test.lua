-- SaftUI-Core/Config/optionswindow.lua, SaftUI's options window (st.OptionsWindow),
-- and its wiring in SaftUI-Core/Config/config.lua (st.Config:Open, Close,
-- GetWindow, Refresh, the commands, PLAYER_REGEN_DISABLED, the rebuild on a
-- profile change).
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (optionswidgets.lua), the body (optionsbody.lua), the window, and edit mode. The /sui tree is the real
-- one Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and synthetic modules registered here: one
-- shaped like Unitframes (a unit picker, element tabs) and small ones for the
-- sidebar's categories. The mouse, the keyboard and the frame clock are played
-- by firing scripts (stub.fire_script): the window re-renders and searches on
-- its ticker's OnUpdate, which the stubs never run by themselves.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionswidgets.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_saftui('SaftUI-Core/Config/optionswindow.lua')
local OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow

------------------------------------------------------------------ the synthetic modules

-- Unitframes' shape: childGroups = 'select' on the module (its units are the
-- picker), a profile group with a negative order, and units whose element
-- groups are tabs. Values live in uf, read and written at call time.
local uf = {
	player = { enable = true, width = 200, power = { enable = true, height = 10 } },
	target = { enable = true, width = 180, power = { enable = true, height = 8 } },
}
local hideTarget = false
local ufProfile = 'Main'
local ufPickerLabel -- the page's pickerLabel, when a test sets one

local function UnitTable(unit, name)
	local cfg = uf[unit]
	return {
		name = name,
		type = 'group',
		childGroups = 'tab',
		hidden = unit == 'target' and function() return hideTarget end or nil,
		args = {
			copy = { name = 'Copy from', type = 'execute', order = -99, func = function() end },
			general = {
				order = 0, name = 'General', type = 'group',
				get = function(info) return cfg[info[#info]] end,
				set = function(info, value) cfg[info[#info]] = value end,
				args = {
					enable = { order = 1, type = 'toggle', name = 'Enable' },
					width = { order = 2, type = 'range', name = 'Frame width', min = 10, max = 600, step = 1 },
				},
			},
			power = {
				order = 1, name = 'Power', type = 'group',
				get = function(info) return cfg.power[info[#info]] end,
				set = function(info, value) cfg.power[info[#info]] = value end,
				args = {
					enable = { order = 1, type = 'toggle', name = 'Enable' },
					height = {
						order = 2, type = 'range', name = 'Bar height', min = 1, max = 50, step = 1,
						hidden = function() return not cfg.power.enable end,
					},
					size = {
						order = 3, type = 'input', name = 'Size',
						validate = function(_, value) return tonumber(value) ~= nil or 'Size: a number, please' end,
						get = function() return '1' end,
						set = function() end,
					},
				},
			},
		},
	}
end

local UFM = st:NewModule('Unitframes')
function UFM:GetConfigTable()
	return {
		name = 'Unitframes',
		type = 'group',
		childGroups = 'select',
		pickerLabel = ufPickerLabel,
		category = 'Frames',
		args = {
			profile = {
				order = -99, name = 'Profile', type = 'group',
				args = {
					current = {
						order = 1, type = 'select', name = 'Profile', values = { Main = 'Main', Alt = 'Alt' },
						-- As UF's real profile select does: its get notifies the registry.
						get = function() st.Config:Refresh(); return ufProfile end,
						set = function(_, value) ufProfile = value end,
					},
				},
			},
			player = UnitTable('player', 'Player'),
			target = UnitTable('target', 'Target'),
		},
	}
end

-- One small page per category, to see the sidebar group them.
local function SmallModule(key, name, category, order)
	local module = st:NewModule(key)
	function module:GetConfigTable()
		return {
			name = name, type = 'group', category = category, order = order,
			args = { general = { name = 'General', type = 'group', args = {
				on = { type = 'toggle', name = name .. ' on', get = function() return true end, set = function() end },
			} } },
		}
	end
	return module
end
SmallModule('Chat', 'Chat', 'Frames')

-- Inventory's shape: tabs (settings for every window, then each window), and a
-- window's own groups as a second tab row. Its General tab also has rows that
-- follow its Columns slider, for a drag: a box showing the value, a toggle
-- disabled at 8 columns or more, and one hidden at 9 or more.
local bagValue = 5
local columns = 5
local INVM = st:NewModule('Inventory')
function INVM:GetConfigTable()
	local function toggle(name) return { type = 'toggle', name = name, get = function() return true end, set = function() end } end
	local wide, extra = toggle('Wide slots'), toggle('Extra row')
	wide.order, wide.disabled = 3, function() return columns >= 8 end
	extra.order, extra.hidden = 4, function() return columns >= 9 end
	return {
		name = 'Bags', type = 'group', category = 'Frames',
		args = {
			general = { order = 0, name = 'General', type = 'group', args = {
				merge = toggle('Merge stacks'),
				columns = { order = 1, type = 'range', name = 'Columns', min = 1, max = 12, step = 1,
					get = function() return columns end, set = function(_, v) columns = v end },
				columns_shown = { order = 2, type = 'input', name = 'Columns shown',
					get = function() return tostring(columns) end, set = function() end },
				wide = wide,
				extra = extra,
			} },
			bag = {
				order = 1, name = 'Bag', type = 'group',
				args = {
					general = { order = 1, name = 'General', type = 'group', args = {
						size = { type = 'range', name = 'Slot size', min = 1, max = 10, step = 1,
							get = function() return bagValue end, set = function(_, v) bagValue = v end },
					} },
					text = { order = 2, name = 'Text', type = 'group', args = { count = toggle('Show count') } },
				},
			},
		},
	}
end
SmallModule('Auras', 'Auras', 'Combat')
SmallModule('Loot', 'Loot', 'Info')
SmallModule('Zeta', 'Zeta', nil) -- no category: Other

------------------------------------------------------------------ helpers

local function frames() return OW.GetFrames() end

local function keys(list, field)
	local out = {}
	for i, entry in ipairs(list) do out[i] = tostring(entry[field or 'key']) end
	return table.concat(out, ',')
end

-- The drawn body rows, as 'key' (or 'key=name') in order.
local function drawn()
	local out = {}
	for i, cell in ipairs(OW.GetDrawnRows()) do out[i] = cell.row.key end
	return table.concat(out, ',')
end

local function cell(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

local function click(frame, ...) stub.fire_script(frame, 'OnClick', ...) end

-- One frame passes on the window's clock.
local function tick(elapsed) stub.fire_script(frames().ticker, 'OnUpdate', elapsed or 0.01) end

-- What fn printed to chat (WoW's print), joined.
local function printed(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return table.concat(lines, '\n')
end

local function close_all()
	st.Config:Close()
	stub.in_combat = false
	hideTarget = false
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

------------------------------------------------------------------ the body

-- A body of width, on a fresh content frame, with the given options on one
-- page (each { key, type, name, size }). Returns the body and its cells by key.
local function draw_body(width, options)
	local store, args = {}, {}
	for i, o in ipairs(options) do
		args[o[1]] = { type = o[2], name = o[3], size = o[4], order = i, min = 0, max = 10, step = 1, values = { a = 'A' } }
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

------------------------------------------------------------------ opening, the sidebar and the wiring

test('Config:Open shows the window; GetWindow is truthy only while it is open', function()
	eq(st.Config:GetWindow(), nil, 'nothing before it opens')
	st.Config:Open()
	check(OW:IsShown(), 'shown')
	check(st.Config:GetWindow() ~= nil, 'GetWindow while open')
	eq(st.Config:GetWindow(), frames().window, 'it is the window frame')
	st.Config:Close()
	check(not OW:IsShown(), 'Close hides it')
	eq(st.Config:GetWindow(), nil, 'GetWindow nil once closed')

	-- The close X (st:CreateCloseButton) and the footer's Close do the same.
	st.Config:Open()
	click(st:GetCloseButton(frames().window))
	eq(st.Config:GetWindow(), nil, 'the X closes it')
	st.Config:Open()
	click(frames().closeButton)
	eq(st.Config:GetWindow(), nil, 'Close closes it')
end)

test('the sidebar: commands, Global Settings, Profiles, then the categories in order', function()
	local ran = 0
	st.Config:AddCommand('kb', 'Keybinds', function() ran = ran + 1 end)
	st.Config:Open()
	eq(keys(frames().actions, 'label'), 'Edit mode,Keybinds', 'Edit mode, then each AddCommand')
	click(frames().actions[2])
	eq(ran, 1, 'a command button runs its func')

	local names = {}
	for i, item in ipairs(frames().nav) do names[i] = item.group and ('[' .. item.group .. ']') or item.name end
	eq(table.concat(names, ','), 'Global Settings,Profiles,[Frames],Bags,Chat,Unitframes,[Combat],Auras,[Info],Loot,[Other],Zeta',
		'drawn in order')
	check(st.Config:GetOptionsTable().topmenu == nil, 'no topmenu group any more')
	eq(type(st.Config:GetCommands()), 'table', 'the commands, for the sidebar')
	eq(st.Config:GetCommands()[1].label, 'Keybinds', 'as added')

	-- Clicking an entry opens its page.
	for _, item in ipairs(frames().nav) do
		if item.key == 'Loot' then click(item) end
	end
	eq(OW:GetState().page, 'Loot', 'clicked page')
	eq(frames().title:GetText(), 'Loot', 'its title')
	close_all()
end)

test("a real module's category: Experience is under Info", function()
	CreateFrame('Frame', 'Minimap', UIParent)
	load_saftui('SaftUI-Misc/experience.lua')
	st:GetModule('Experience'):Enable()
	local root = st.Config:GetOptionsTable()
	local found = false
	for _, page in ipairs(OM.Pages(root)) do
		if page.key == 'Experience' then
			found = true
			eq(page.category, 'Info', 'Experience is Info')
		end
	end
	check(found, 'Experience has a page')
end)

test('Global Settings has General, Fonts, Colors, Theme and Edit mode tabs, and the sidebar has no Edit mode page', function()
	local root = st.Config:GetOptionsTable()
	eq(root.EditMode, nil, 'no EditMode page in the tree')
	for _, page in ipairs(OM.Pages(root)) do
		check(page.key ~= 'EditMode', 'no EditMode page')
	end
	-- Zeta is the only page left in Other here; with none, there is no heading.
	for _, entry in ipairs(OW.SidebarEntries(OM.Pages({ Fonts = root.Fonts, profile = root.profile }))) do
		check(entry.group ~= 'Other', 'no Other heading when nothing is uncategorized')
	end

	local view = OM.BuildView(root, 'Fonts')
	eq(view.title, 'Global Settings', 'the page')
	eq(keys(view.tabs), 'general,fonts,colors,theme,editmode', 'General, Fonts, Colors, Theme, then Edit mode')
	eq(keys(view.tabs, 'name'), 'General,Fonts,Colors,Theme,Edit mode', 'tab names')
	eq(view.tab, 'general', 'General is the tab the page opens on')
	eq(root.Colors, nil, 'no Colors page in the tree')
	eq(root.General, nil, 'no General page in the tree')
	eq(root.Fonts.order, 1, 'the page keeps its place')
	eq(root.Fonts.desc, "Settings used across SaftUI: icon zoom and window title bars, fonts, colors, themes, and edit mode's grid and snapping.")

	view = OM.BuildView(root, 'Fonts', { tab = 'editmode' })
	eq(view.tab, 'editmode', 'Edit mode selected')
	eq(#view.subtabs, 0, 'its settings are a section of the tab, not another tab row')
	local grid
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'grid' then grid = r end
		end
	end
	check(grid ~= nil, 'Show grid is a row')
	local before = st.EditModeFrames:GetSettings().grid
	eq(OM.Get(root, grid), before, 'reads the setting')
	OM.Set(root, grid, not before)
	eq(st.EditModeFrames:GetSettings().grid, not before, 'setting it changes the edit mode settings')
	OM.Set(root, grid, before)

	-- The Fonts tab still reads the font settings.
	view = OM.BuildView(root, 'Fonts', { tab = 'fonts' })
	local size
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'font_size' and not size then size = r end
		end
	end
	check(size ~= nil, 'a font size row')
	check(type(OM.Get(root, size)) == 'number', 'reads a number')
end)

test("Icon zoom's box shows the profile's fraction as a percent, and a typed percent stores the fraction", function()
	st.Config:Open('Fonts', 'general')
	eq(OW:GetState().tab, 'general', 'the General tab')
	eq(drawn(), 'icon_trim,icon_preview,header_height,clamp_inset', "the tab's rows, Icon zoom's preview after it")
	local w = cell('icon_trim').widget
	eq(w.edit:GetText(), '6.5%', 'the default 0.065 shows as 6.5%')
	w.edit:SetText('10')
	stub.fire_script(w.edit, 'OnEnterPressed')
	eq(st.config.profile.misc.icon_trim, 0.1, 'typed 10 stores 0.1')
	eq(cell('icon_trim').widget.edit:GetText(), '10%', 'and shows 10%')
	w = cell('icon_trim').widget
	w.edit:SetText('35%')
	stub.fire_script(w.edit, 'OnEnterPressed')
	eq(st.config.profile.misc.icon_trim, 0.2, 'past the top, 20%')
	st.config.profile.misc.icon_trim = 0.065
	close_all()
end)

test("Open({'Unitframes','player','general'}) selects the page, the picker value and the tab", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local state = OW:GetState()
	eq(state.page, 'Unitframes', 'page')
	eq(state.pick, 'player', 'picker')
	eq(state.tab, 'general', 'tab')
	eq(frames().picker.text:GetText(), 'Player', 'the picker shows the unit')
	eq(keys(frames().tabs, 'key'), 'general,power', 'the element tabs')
	check(frames().tabs[1].active and not frames().tabs[2].active, 'General is the active tab')
	eq(drawn(), 'copy,enable,width', "the unit's Copy from, then General's rows")

	-- Another path, with the window already open.
	st.Config:Open('Unitframes', 'target', 'power')
	state = OW:GetState()
	eq(state.pick .. '/' .. state.tab, 'target/power', 'target, Power')
	eq(drawn(), 'copy,enable,height,size', "Power's rows")

	-- Picker values: the units, then the profile group (negative order sorts last).
	eq(keys(OM.BuildView(OW:GetRoot(), 'Unitframes').picker.values), 'player,target,profile', 'picker entries')
	close_all()
end)

test("the picker is labelled with the page's pickerLabel, else its name", function()
	local function label()
		st.Config:Open('Unitframes', 'player')
		local drawnLabel = frames().pickerLabel:GetText()
		eq(OM.BuildView(OW:GetRoot(), 'Unitframes').picker.name, drawnLabel, 'the view and the window agree')
		close_all()
		return drawnLabel
	end
	eq(label(), 'Unitframes', 'no pickerLabel: the page name')
	ufPickerLabel = 'Unit'
	st.Config:Refresh()
	eq(label(), 'Unit', 'pickerLabel set: the label')
	ufPickerLabel = nil
end)

test("Open({'Inventory','bag','text'}) selects the tab and the second row's tab", function()
	st.Config:Open('Inventory', 'bag', 'text')
	local state = OW:GetState()
	eq(state.page .. '/' .. state.tab .. '/' .. state.subtab, 'Inventory/bag/text', 'tab and subtab')
	eq(state.pick, nil, 'no picker')
	eq(keys(frames().tabs, 'key'), 'general,bag', 'the first row')
	eq(keys(frames().subtabs, 'key'), 'general,text', 'the second row')
	check(frames().subtabs[2].active, 'Text is active')
	check(frames().subLine:IsShown(), "the second row's line")
	check(not frames().picker.frame:IsShown(), 'no picker drawn')
	eq(drawn(), 'count', "Text's row")
	click(frames().subtabs[1])
	eq(drawn(), 'size', 'a subtab click')
	click(frames().tabs[1])
	eq(OW:GetState().tab, 'general', 'a tab click')
	eq(#frames().subtabs, 0, 'General has no second row')
	check(not frames().subLine:IsShown(), 'nor its line')
	close_all()
end)

test('the select list and the confirm dialog sit above the window', function()
	st.Config:Open('Unitframes', 'player', 'general')
	eq(frames().window:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'the window, like the old AceGUI one')
	click(frames().picker.frame)
	eq(W.GetListFrames().catcher:GetFrameStrata(), 'TOOLTIP', 'the list above it')
	W.CloseList()
	W.Confirm('Sure?', function() end)
	eq(W.GetDialogFrames().catcher:GetFrameStrata(), 'TOOLTIP', 'the dialog above it')
	st.Config:Close()
	eq(W.ConfirmText(), nil, 'closing the window answers the dialog No')
	close_all()
end)

test('rerender after set: a set that hides an option removes its row', function()
	st.Config:Open('Unitframes', 'player', 'power')
	eq(drawn(), 'copy,enable,height,size', 'height shows while power is on')
	local before = OW.GetRenderCount()
	click(cell('enable').widget.frame)
	eq(uf.player.power.enable, false, 'set through the model')
	eq(drawn(), 'copy,enable,size', 'height is gone on the render after the set')
	eq(OW.GetRenderCount(), before + 1, 'one render')
	click(cell('enable').widget.frame)
	eq(drawn(), 'copy,enable,height,size', 'and back')
	close_all()
end)

test('a validate failure shows in the status line and sets nothing', function()
	st.Config:Open('Unitframes', 'player', 'power')
	local box = cell('size').widget.frame
	box:SetText('abc')
	stub.fire_script(box, 'OnEnterPressed')
	eq(frames().status:GetText(), 'Size: a number, please', 'the validate message')
	OW:SetStatus('Something else')
	eq(frames().status:GetText(), 'Something else', 'SetStatus')
	OW:Navigate('Loot')
	eq(frames().status:GetText(), '', 'cleared by navigating')
	close_all()
end)

test('ConfigTableChange re-renders on the next frame, coalesced, and keeps the selection', function()
	st.Config:Open('Unitframes', 'target', 'power')
	local before = OW.GetRenderCount()
	uf.target.power.enable = false
	st.Config:Refresh()
	st.Config:Refresh()
	eq(drawn(), 'copy,enable,height,size', 'not re-rendered straight away')
	eq(OW.GetRenderCount(), before, 'no render yet')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'two changes, one render')
	eq(drawn(), 'copy,enable,size', 'the hidden row is gone')
	eq(OW:GetState().pick .. '/' .. OW:GetState().tab, 'target/power', 'the picker and tab stay')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'nothing more to do')
	uf.target.power.enable = true

	-- A pick that vanishes falls back to the first; when it's back, it's selected again.
	hideTarget = true
	st.Config:Refresh(); tick()
	eq(OW:GetState().pick, 'player', 'target hidden: the first unit')
	hideTarget = false
	st.Config:Refresh(); tick()
	eq(OW:GetState().pick, 'target', 'target is back')
	close_all()
end)

test("a get that notifies the registry doesn't re-render in a loop", function()
	st.Config:Open('Unitframes', 'profile')
	eq(OW:GetState().pick, 'profile', 'the profile group')
	eq(drawn(), 'current', 'its select')
	local before = OW.GetRenderCount()
	tick(); tick(); tick()
	eq(OW.GetRenderCount(), before, 'gets during a render are ignored')

	-- Opening its list runs the get again: the render waits until the list closes.
	click(cell('current').widget.frame)
	check(W.ListOwner() ~= nil, 'the list is open')
	tick(); tick()
	eq(OW.GetRenderCount(), before, 'no render under the open list')
	check(W.ListOwner() ~= nil, 'still open')
	click(W.GetListFrames().rows[1]) -- Alt
	eq(ufProfile, 'Alt', 'picked')
	eq(OW.GetRenderCount(), before + 1, 'the set re-renders once')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'and nothing is left pending')
	close_all()
end)

test("a slider drag doesn't re-render until the mouse is let go", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true -- held for the whole drag, as in game
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(250)
	w.slider:SetValue(260)
	eq(uf.player.width, 260, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	st.Config:Refresh(); tick()
	eq(OW.GetRenderCount(), before, 'nor from the registry')
	eq(cell('width').widget, w, 'the same slider is still drawn')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'the pending one went with it')
	close_all()
end)

-- In game a click on the track can move the slider before its OnMouseDown
-- runs; a render then would take the slider out from under the drag.
test("a drag whose first move comes before its mouse-down still doesn't re-render until let go", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	w.slider:SetValue(250)
	eq(OW.GetRenderCount(), before, 'no render from the first move')
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(260)
	eq(uf.player.width, 260, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	eq(cell('width').widget, w, 'the same slider is still drawn')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	close_all()
end)

test('a drag whose mouse-up never arrives still renders once the button is up', function()
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	w.slider:SetValue(255)
	tick()
	eq(OW.GetRenderCount(), before, 'held: no render')
	stub.mouse_buttons.LeftButton = nil
	tick()
	eq(OW.GetRenderCount(), before + 1, 'released: the page catches up')
	close_all()
end)

-- A texture's eight corners as text, rounded so float drift doesn't decide a
-- check; corners(l, r, t, b) is what SetTexCoord(l, r, t, b) gives back.
local function coords_of(texture)
	local out = {}
	for i, v in ipairs({ texture:GetTexCoord() }) do out[i] = string.format('%.4f', v) end
	return table.concat(out, ',')
end
local function corners(l, r, t, b)
	local out = {}
	for i, v in ipairs({ l, t, l, b, r, t, r, b }) do out[i] = string.format('%.4f', v) end
	return table.concat(out, ',')
end

test('mid-drag the other rows read their rows again in place: values and disabled follow, no row comes or goes', function()
	st.Config:Open('Inventory', 'general')
	eq(drawn(), 'columns,columns_shown,wide,extra,merge', "the General tab's rows")
	local w = cell('columns').widget
	local cellsBefore, widgetsBefore = {}, {}
	for i, c in ipairs(OW.GetDrawnRows()) do cellsBefore[i], widgetsBefore[i] = c, c.widget end
	local pooled = W.Pooled('toggle') .. ',' .. W.Pooled('input') .. ',' .. W.Pooled('range')
	-- The dragged slider is refreshed by its own commit, and by nothing else.
	local refreshes, refresh = 0, w.Refresh
	w.Refresh = function(...) refreshes = refreshes + 1; return refresh(...) end

	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(9)
	w.Refresh = refresh
	eq(columns, 9, 'set while dragging')
	eq(refreshes, 1, "the slider was refreshed once, by its commit")
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	eq(cell('columns_shown').widget.frame:GetText(), '9', "another row's value follows the drag")
	check(cell('wide').widget:IsDisabled(), 'a row disabled at 8 or more is disabled now')
	local r, g, b = cell('wide').label:GetTextColor()
	local gr, gg, gb = st.config.profile.colors.text.grey:GetRGB()
	check(r == gr and g == gg and b == gb, 'and its label is grey')
	eq(drawn(), 'columns,columns_shown,wide,extra,merge', 'a row hidden at 9 or more stays until the drag ends')
	for i, c in ipairs(OW.GetDrawnRows()) do
		check(c == cellsBefore[i] and c.widget == widgetsBefore[i], 'cell ' .. i .. ' and its widget are the ones drawn')
	end
	eq(W.Pooled('toggle') .. ',' .. W.Pooled('input') .. ',' .. W.Pooled('range'), pooled, 'nothing was released')

	-- Back under 8: enabled again, label in the normal color.
	w.slider:SetValue(7)
	check(not cell('wide').widget:IsDisabled(), 'enabled again')
	r, g, b = cell('wide').label:GetTextColor()
	local nr, ng, nb = st.config.profile.colors.text.normal:GetRGB()
	check(r == nr and g == ng and b == nb, 'and its label is the normal color')
	w.slider:SetValue(9)

	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	eq(drawn(), 'columns,columns_shown,wide,merge', 'which leaves the hidden row out')
	eq(cell('columns_shown').widget.frame:GetText(), '9', 'the value as it was set')
	check(cell('wide').widget:IsDisabled(), 'still disabled')
	columns = 5
	close_all()
end)

test("dragging Icon zoom crops its preview as it goes, with no render, and the slider stays the one dragged", function()
	st.Config:Open('Fonts', 'general')
	local w = cell('icon_trim').widget
	local preview = cell('icon_preview').widget
	eq(preview.type, 'description', 'the preview is a description row')
	eq(preview.image:GetTexture(), 'Interface\\Icons\\Spell_Nature_Lightning', 'with the lightning icon')
	eq(preview.image:GetWidth() .. 'x' .. preview.image:GetHeight(), '36x36', 'at 36 by 36')
	eq(coords_of(preview.image), corners(st:IconTexCoords(0.065, 36, 36)), 'cut at the default zoom')
	eq(coords_of(preview.image), corners(0.065, 0.935, 0.065, 0.935), 'which is 6.5% off each edge')

	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(0.15)
	eq(st.config.profile.misc.icon_trim, 0.15, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	eq(cell('icon_trim').widget, w, 'the same slider is still drawn')
	eq(cell('icon_preview').widget, preview, 'and the same preview')
	eq(coords_of(preview.image), corners(st:IconTexCoords(0.15, 36, 36)), 'the preview follows the drag')
	w.slider:SetValue(0)
	eq(coords_of(preview.image), corners(0, 1, 0, 1), 'at 0%, the whole icon')
	w.slider:SetValue(0.2)

	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	eq(coords_of(cell('icon_preview').widget.image), corners(0.2, 0.8, 0.2, 0.8), 'drawn again at the zoom left set')

	-- A typed zoom re-renders at once, so the preview takes it too.
	local edit = cell('icon_trim').widget.edit
	edit:SetText('10')
	stub.fire_script(edit, 'OnEnterPressed')
	eq(coords_of(cell('icon_preview').widget.image), corners(0.1, 0.9, 0.1, 0.9), 'a typed 10%')
	st.config.profile.misc.icon_trim = 0.065
	close_all()
end)

-- A 1px border blurs when its frame sits between two pixels. The window is on
-- whole pixels (SaftUI's scale makes a unit a pixel), so every cell of the body
-- must start and end on whole units too: a quarter of a 367 column is 171.5.
test('every cell of the body starts and ends on whole pixels, at any width', function()
	local OB = st.OptionsBody
	for _, width in ipairs({ OB.WIDTH, 775, 480 }) do
		local body = OB.New(CreateFrame('Frame', nil, UIParent), nil, function() end, width)
		local spans = {}
		for _, col in ipairs({ 'full', 1, 2 }) do
			for _, quarter in ipairs(col == 'full' and { false } or { false, 1, 2 }) do
				local x, w = body:CellRect(col, quarter or nil)
				spans[#spans + 1] = { col, quarter, x, w }
				eq(x, math.floor(x), ('width %d, col %s, quarter %s: x %s is whole'):format(width, tostring(col), tostring(quarter), tostring(x)))
				eq(w, math.floor(w), ('width %d, col %s, quarter %s: width %s is whole'):format(width, tostring(col), tostring(quarter), tostring(w)))
			end
		end
		local x1, w1 = body:CellRect(1)
		local x2, w2 = body:CellRect(2)
		eq(x2 + w2, width, 'the second column ends at the body\'s edge')
		local q2x, q2w = body:CellRect(1, 2)
		eq(q2x + q2w, x1 + w1, "a column's second quarter ends at the column's edge")
	end
end)

test('the picker and tabs switch the selection', function()
	st.Config:Open('Unitframes', 'player', 'general')
	click(frames().tabs[2])
	eq(OW:GetState().tab, 'power', 'a tab click')
	click(frames().picker.frame)
	local list = W.GetListFrames()
	local labels = {}
	for i, row in ipairs(list.rows) do
		if row:IsShown() then labels[#labels + 1] = row.text:GetText() end
	end
	eq(table.concat(labels, ','), 'Player,Target,Profile', 'the picker lists the groups')
	click(list.rows[2])
	eq(OW:GetState().pick, 'target', 'picked Target')
	eq(OW:GetState().tab, 'power', 'the tab is kept')
	close_all()
end)

------------------------------------------------------------------ search

test('search waits for typing to pause, shows results by page, and a click goes there', function()
	st.Config:Open('Loot')
	local box = frames().search
	local calls, search = 0, OM.Search
	OM.Search = function(...) calls = calls + 1; return search(...) end

	box:SetFocus()
	box:SetText('frame w')
	tick(0.1)
	eq(calls, 0, 'not yet')
	box:SetText('frame wid')
	tick(0.2)
	eq(calls, 0, 'typing again starts the wait over')
	tick(0.1)
	eq(calls, 1, 'searched once the typing paused')
	eq(OW:GetState().search, 'frame wid', 'searching')
	eq(frames().title:GetText(), 'Search', 'the results page')
	local results = OW.GetDrawnRows()
	eq(#results, 2, 'Frame width for both units')
	eq(results[1].row.name, 'Frame width', 'a result')
	tick(1)
	eq(calls, 1, 'no more searches')

	click(results[2].frame)
	OM.Search = search
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/target/general', 'went to the result')
	eq(box:GetText(), '', 'the box is cleared')
	eq(state.search, '', 'not searching')
	check(cell('width') ~= nil, 'the row is drawn')
	box:ClearFocus()
	close_all()
end)

test('a search still waiting for typing to pause gives way to navigating', function()
	st.Config:Open('Loot')
	local box = frames().search
	box:SetFocus()
	-- Typing, the search not run yet: each part starts from an empty box.
	local function type_search()
		box:SetText('')
		box:SetText('frame')
		eq(OW:GetState().search, '', 'typed, not searched yet')
	end

	-- The sidebar (OW:Navigate).
	type_search()
	for _, item in ipairs(frames().nav) do
		if item.key == 'Chat' then click(item) end
	end
	tick(1)
	eq(OW:GetState().search, '', 'a page click: no search ran after it')
	eq(frames().title:GetText(), 'Chat', 'the page stays')
	eq(box:GetText(), '', 'the box is cleared')

	-- Open with a path, the window open (an edit mode click).
	type_search()
	st.Config:Open('Unitframes', 'player', 'general')
	tick(1)
	eq(OW:GetState().search, '', 'Open: no search ran after it')
	eq(OW:GetState().page .. '/' .. OW:GetState().tab, 'Unitframes/general', 'the page stays')

	-- A tab, and the picker (Select).
	type_search()
	click(frames().tabs[2])
	tick(1)
	eq(OW:GetState().search, '', 'a tab click: no search ran after it')
	eq(OW:GetState().tab, 'power', 'the tab stays')
	type_search()
	click(frames().picker.frame)
	click(W.GetListFrames().rows[2]) -- Target
	tick(1)
	eq(OW:GetState().search, '', 'a pick: no search ran after it')
	eq(OW:GetState().pick, 'target', 'the pick stays')
	box:ClearFocus()
	close_all()
end)

test('clearing the search box goes back to the page', function()
	st.Config:Open('Loot')
	frames().search:SetText('enable')
	tick(0.3)
	eq(OW:GetState().search, 'enable', 'searching')
	frames().search:SetText('')
	eq(OW:GetState().search, '', 'cleared at once')
	eq(frames().title:GetText(), 'Loot', 'the page is back')
	close_all()
end)

------------------------------------------------------------------ moving, keys, combat

test('the position is saved when a drag ends and restored on open', function()
	st.Config:Open()
	local window = frames().window
	stub.fire_script(frames().header, 'OnDragStart')
	eq(stub.state(window).moving, true, 'dragging the header moves the window')
	window:ClearAllPoints()
	window:SetPoint('CENTER', UIParent, 'CENTER', 120, -40) -- where the mouse left it
	stub.fire_script(frames().header, 'OnDragStop')
	eq(stub.state(window).moving, false, 'stopped')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'CENTER 120 -40', 'saved account-wide')

	st.Config:Close()
	st.config.global.optionsWindow = { point = 'CENTER', x = -200, y = 50 }
	st.Config:Open()
	local cx, cy = window:GetCenter()
	local ux, uy = UIParent:GetCenter()
	eq((cx - ux) .. ',' .. (cy - uy), '-200,50', 'restored')

	st.Config:Close()
	st.config.global.optionsWindow = { point = 'NOWHERE', x = 'a' }
	st.Config:Open()
	cx, cy = window:GetCenter()
	eq((cx - ux) .. ',' .. (cy - uy), '0,0', 'a bad saved value: centered')
	st.config.global.optionsWindow = nil
	close_all()
end)

test('Esc closes the window through its own catcher; other keys pass on', function()
	st.Config:Open()
	local keys = frames().keys
	check(keys:IsShown() and keys:IsKeyboardEnabled(), 'the catcher is on while open')
	stub.fire_script(keys, 'OnKeyDown', 'A')
	check(OW:IsShown(), 'A: still open')
	eq(keys:GetPropagateKeyboardInput(), true, 'A goes on to the game')

	frames().search:SetFocus()
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(OW:IsShown(), 'Esc with a box focused is the box\'s')
	eq(keys:GetPropagateKeyboardInput(), true, 'passed on')
	frames().search:ClearFocus()

	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsShown(), 'Esc closes it')
	eq(keys:GetPropagateKeyboardInput(), false, 'Esc is kept')
	check(not keys:IsKeyboardEnabled(), 'the catcher is off once closed')
	check(UISpecialFrames == nil, "Blizzard's UISpecialFrames isn't used")
	close_all()
end)

test("Esc passes on while Blizzard's color picker is open, so it closes the picker, not the window", function()
	st.Config:Open('Loot')
	local keys = frames().keys
	ColorPickerFrame:SetupColorPickerAndShow({ r = 1, g = 0, b = 0, swatchFunc = function() end, cancelFunc = function() end })
	check(ColorPickerFrame:IsShown(), 'the picker is open')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(OW:IsShown(), 'the window stays open')
	eq(keys:GetPropagateKeyboardInput(), true, 'Esc is passed on')
	stub.color_picker_cancel()
	check(not ColorPickerFrame:IsShown(), 'the picker closed')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsShown(), 'then Esc closes the window')
	close_all()
end)

test('PLAYER_REGEN_DISABLED closes the window', function()
	st.Config:Open()
	local said = printed(function() stub.fire_event('PLAYER_REGEN_DISABLED') end) -- fires just before the lockdown
	check(said:find('closed: entering combat', 1, true) ~= nil, 'says why')
	check(not OW:IsShown(), 'closed')
	eq(st.Config:GetWindow(), nil, 'GetWindow nil')
	check(not frames().keys:IsKeyboardEnabled(), 'the key catcher is off')
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not OW:IsShown(), 'nothing to close the second time')
	close_all()
end)

test('Open in combat refuses', function()
	stub.in_combat = true
	local said = printed(function() st.Config:Open('Loot') end)
	check(said:find("Can't open SaftUI options in combat.", 1, true) ~= nil, 'says why')
	check(not OW:IsShown(), 'not shown')
	eq(st.Config:GetWindow(), nil, 'no window')
	eq(OW:Open({ 'Loot' }), false, 'OW:Open refuses too')
	close_all()
end)

------------------------------------------------------------------ the footer and profiles

test('the footer region sits between Reload UI and Close', function()
	st.Config:Open()
	local f = frames()
	local region = OW:GetFooter()
	eq(region, f.footerRegion, 'the region')
	check(region:GetLeft() >= f.reloadButton:GetRight(), 'right of Reload UI')
	check(region:GetRight() <= f.closeButton:GetLeft(), 'left of Close')
	check(f.reloadButton:GetLeft() < f.closeButton:GetLeft(), 'Reload UI on the left')
	close_all()
end)

-- Whether frame is inside ancestor (its parent, or its parent's, ...).
local function inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

test("edit mode's footer buttons sit on the window's footer while edit mode is on and the window is open", function()
	local EM = st.EditModeFrames
	-- OnEnable (EditMode/settings.lua) makes them with st:CreateButton: Grid,
	-- Snap to grid, Snap to frames, -, the size, +. Keep them as they're made.
	local buttons, createButton = {}, st.CreateButton
	st.CreateButton = function(...)
		local button = createButton(...)
		buttons[#buttons + 1] = button
		return button
	end
	EM:Enable()
	st.CreateButton = createButton
	eq(#take_errors(), 0, 'edit mode enabled without errors')
	eq(#buttons, 6, 'six buttons')
	local grid, plus = buttons[1], buttons[6]
	local region = OW:GetFooter()

	st.Config:Open('Loot')
	check(not grid:IsVisible(), 'edit mode off: not shown')
	printed(function() EM:Activate() end)
	check(grid:IsVisible() and plus:IsVisible(), 'edit mode on, window open: shown')
	check(inside(grid, region), "on the window's footer region")
	check(grid:GetLeft() >= region:GetLeft() and plus:GetRight() <= region:GetRight(), 'inside it, left to right')
	check(frames().status:GetLeft() >= plus:GetRight(), 'the status line starts clear of them')

	st.Config:Close()
	check(not grid:IsVisible(), 'window closed: not shown')
	check(not inside(grid, region), 'and taken off it')
	st.Config:Open('Loot')
	check(grid:IsVisible() and inside(grid, region), 'opened again in edit mode: back')
	printed(function() EM:Deactivate() end)
	check(not grid:IsVisible(), 'edit mode off: not shown')
	check(not inside(grid, region), 'and taken off it')
	eq(frames().status:GetLeft(), region:GetLeft(), 'the status line has the region back')
	check(OW:IsShown(), 'the window stays open')

	-- Edit mode works with the window closed; the buttons just don't show.
	st.Config:Close()
	printed(function() EM:Activate() end)
	check(not grid:IsVisible(), 'edit mode on, window closed: not shown')
	printed(function() EM:Deactivate() end)
	close_all()
end)

test('a profile change rebuilds the open window from the new tree', function()
	st.Config:Open('Loot')
	local old = OW:GetRoot()
	st.config:SetProfile('Second')
	check(OW:GetRoot() ~= old, 'a new tree')
	tick()
	check(frames().profile:GetText():find('Second', 1, true) ~= nil, 'the sidebar names the new profile')
	eq(OW:GetState().page, 'Loot', 'still on the page')
	st.config:SetProfile('Default')
	close_all()
end)

------------------------------------------------------------------ OpenDialog

-- A table of the dialog's own: get and set on the group, a range hidden while
-- the toggle is off, and an inline group with a button.
local dialogValues, dialogRuns = { on = true, size = 5 }, 0
local function DialogTable()
	return {
		type = 'group', name = 'The group',
		get = function(info) return dialogValues[info[#info]] end,
		set = function(info, value) dialogValues[info[#info]] = value end,
		args = {
			on = { order = 1, type = 'toggle', name = 'On' },
			size = {
				order = 2, type = 'range', name = 'Size', min = 1, max = 10, step = 1,
				hidden = function() return not dialogValues.on end,
			},
			stuff = {
				order = 3, type = 'group', inline = true, name = 'Stuff',
				args = { go = { type = 'execute', name = 'Go', func = function() dialogRuns = dialogRuns + 1 end } },
			},
		},
	}
end

local function dialogRows()
	local out = {}
	for i, c in ipairs(OW.GetDialogFrames().body.cells) do out[i] = c.row.key end
	return table.concat(out, ',')
end

local function dialogCell(key)
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

test('OpenDialog draws a table of its own in a small SaftUI dialog above the window', function()
	st.Config:Open('Loot')
	eq(OW:OpenDialog('My dialog', DialogTable()), true, 'it opens')
	local d = OW.GetDialogFrames()
	check(d.frame:IsShown(), 'shown')
	eq(d.title:GetText(), 'My dialog', 'its title')
	eq(dialogRows(), 'on,size,go', "the table's rows, its inline group a section")
	eq(d.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG', "the window's strata")
	check(d.frame:GetFrameLevel() > frames().window:GetFrameLevel() + 10, 'well above the window')
	check(st:GetCloseButton(d.frame) ~= nil, 'the close X')
	eq(drawn(), 'on', "the window's page is drawn as it was")

	-- Its own set re-renders it, not the window.
	local before = OW.GetRenderCount()
	click(dialogCell('on').widget.frame)
	eq(dialogValues.on, false, 'set through the model')
	eq(dialogRows(), 'on,go', 'the hidden range is gone')
	eq(OW.GetRenderCount(), before, "the window didn't render")
	click(dialogCell('go').widget.frame)
	eq(dialogRuns, 1, 'the button runs')
	dialogValues.on = true

	click(st:GetCloseButton(d.frame))
	check(not d.frame:IsShown(), 'the X closes it')
	eq(#d.body.cells, 0, 'and releases its rows')
	check(OW:IsShown(), 'the window stays open')
	close_all()
end)

test("OpenDialog's title can be a function, read on each render", function()
	local picked
	local options = DialogTable()
	options.args.on.set = function(_, value) picked = value end
	OW:OpenDialog(function() return picked == nil and 'Pick one' or 'Picked' end, options)
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Pick one', 'before')
	click(dialogCell('on').widget.frame)
	eq(d.title:GetText(), 'Picked', 'after the set')
	OW:CloseDialog()
end)

test("a drag in the dialog refreshes its other rows in place too; it's drawn again when let go", function()
	local size = 5
	OW:OpenDialog('Drag', {
		type = 'group', name = 'Drag',
		args = {
			size = { order = 1, type = 'range', name = 'Size', min = 1, max = 10, step = 1,
				get = function() return size end, set = function(_, v) size = v end },
			shown = { order = 2, type = 'input', name = 'Size shown',
				get = function() return tostring(size) end, set = function() end },
		},
	})
	local w, sizeRow = dialogCell('size').widget, dialogCell('size').row
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(8)
	eq(size, 8, 'set while dragging')
	eq(dialogCell('shown').widget.frame:GetText(), '8', 'the other row follows')
	-- A render builds the rows anew from the model; mid-drag they're the ones drawn.
	eq(dialogCell('size').row, sizeRow, 'not drawn again mid-drag')
	eq(dialogCell('size').widget, w, 'the slider is the one dragged')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	check(dialogCell('size').row ~= sizeRow, 'drawn again when let go')
	eq(dialogCell('shown').widget.frame:GetText(), '8', 'with the value set')
	OW:CloseDialog()
end)

test('Esc closes the dialog through its own catcher, and leaves the window open', function()
	st.Config:Open('Loot')
	OW:OpenDialog('Esc', DialogTable())
	local keys = OW.GetDialogFrames().keys
	check(keys:IsKeyboardEnabled(), 'its catcher is on while it shows')
	stub.fire_script(keys, 'OnKeyDown', 'A')
	check(OW:IsDialogShown(), 'A: still open')
	eq(keys:GetPropagateKeyboardInput(), true, 'A goes on')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not OW:IsDialogShown(), 'Esc closes it')
	eq(keys:GetPropagateKeyboardInput(), false, 'Esc is kept, so the window under it stays')
	check(not keys:IsKeyboardEnabled(), 'the catcher is off once closed')
	check(OW:IsShown(), 'the window is still open')
	close_all()
end)

test('the dialog closes with the window and on entering combat, and refuses to open in combat', function()
	st.Config:Open('Loot')
	OW:OpenDialog('With the window', DialogTable())
	st.Config:Close()
	check(not OW:IsDialogShown(), 'closing the window closes it')

	-- Without the window too.
	OW:OpenDialog('Alone', DialogTable())
	check(OW:IsDialogShown(), 'open without the window')
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not OW:IsDialogShown(), 'entering combat closes it')

	stub.in_combat = true
	eq(OW:OpenDialog('Combat', DialogTable()), false, 'refused in combat')
	check(not OW:IsDialogShown(), 'not shown')
	close_all()
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
	W.Define('windowfill', {
		bare = true,
		fill = true,
		minHeight = 100,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = {
			SetWidth = function(self, width) self.frame:SetWidth(width) end,
			SetHeight = function(self, height)
				self.frame:SetHeight(height)
				heights[#heights + 1] = height
			end,
			Refresh = function() end,
		},
	})
	eq(W.CUSTOM.windowfill.fill, true, 'W.CUSTOM marks it fill')
	eq(W.CUSTOM.windowfill.minHeight, 100, 'with its least height')
	local module = st:NewModule('FillRows')
	function module:GetConfigTable()
		local function toggle(name, order)
			return { type = 'toggle', name = name, desc = name, order = order, get = function() return true end, set = function() end }
		end
		return {
			name = 'Fill rows', type = 'group', category = 'Frames',
			args = {
				before = toggle('Before', 1),
				fill = { type = 'windowfill', name = 'Fill', desc = 'A fill row.', size = 'wide', order = 2 },
				after = toggle('After', 3),
			},
		}
	end

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

------------------------------------------------------------------ under the Blizzard theme

local function theme(name)
	st.config.profile.theme.name = name
	OW:Render() -- the window renders again after a theme change
end

local function rgba(...) return string.format('%.2f,%.2f,%.2f,%.2f', ...) end

-- The textures shown on a frame (shown and not see-through).
local function shown_textures(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 then
			out[#out + 1] = region
		end
	end
	return out
end

-- The atlases shown on a frame, sorted and comma-joined.
local function atlases_of(frame)
	local out = {}
	for _, region in ipairs(shown_textures(frame)) do
		if region:GetAtlas() then out[#out + 1] = region:GetAtlas() end
	end
	table.sort(out)
	return table.concat(out, ',')
end

-- Whether region lies inside frame's rect on screen.
local function within(region, frame)
	local e = 0.001
	return region:GetLeft() >= frame:GetLeft() - e and region:GetRight() <= frame:GetRight() + e
		and region:GetBottom() >= frame:GetBottom() - e and region:GetTop() <= frame:GetTop() + e
end

local function art_inside(frame, name)
	for _, region in ipairs(shown_textures(frame)) do
		check(within(region, frame), name .. ': ' .. tostring(region:GetAtlas() or region:GetTexture()) .. ' inside its rect')
	end
end

local function size_of(frame) return frame:GetWidth() .. 'x' .. frame:GetHeight() end

-- Every texture shown on frame is anchored to fill it exactly: for the
-- sidebar's entries, which sit in a scroll child the stubs don't place.
local function art_fills(frame, name)
	for _, region in ipairs(shown_textures(frame)) do
		local points = {}
		for i = 1, region:GetNumPoints() do
			local point, rel, relPoint, x, y = region:GetPoint(i)
			check(rel == frame and point == relPoint and x == 0 and y == 0, name .. ': ' .. tostring(region:GetAtlas()) .. ' on its edges')
			points[#points + 1] = point
		end
		table.sort(points)
		eq(table.concat(points, ','), 'BOTTOMRIGHT,TOPLEFT', name .. ': ' .. tostring(region:GetAtlas()) .. ' fills it')
	end
end

local BOX = { fill = rgba(unpack(st.BOX_COLORS.field)), bg = rgba(unpack(st.BOX_COLORS.bg)), edge = rgba(unpack(st.BOX_COLORS.edge)) }

test("the tabs are Blizzard's Settings tabs, the active one picked, with no underline", function()
	theme('thick')
	st.Config:Open('Inventory', 'bag', 'text')
	local rows = { tab = frames().tabs, subtab = frames().subtabs }
	local sizes = {}
	for slot, tabs in pairs(rows) do
		check(#tabs > 1, 'a row of ' .. slot .. 's')
		for i, tab in ipairs(tabs) do
			eq(atlases_of(tab), '', 'Thick: ' .. slot .. ' ' .. i .. ' has no Blizzard art')
			eq(tab.underline:IsShown(), tab.active, 'Thick: only the active ' .. slot .. ' is underlined')
			sizes[slot .. i] = size_of(tab)
		end
	end

	theme('blizzard')
	rows = { tab = frames().tabs, subtab = frames().subtabs }
	for slot, tabs in pairs(rows) do
		local picked = 0
		for i, tab in ipairs(tabs) do
			local name = slot .. ' ' .. i
			check(not tab.underline:IsShown(), name .. ': no underline')
			if tab.active then
				picked = picked + 1
				eq(atlases_of(tab), 'Options_Tab_Active_Left,Options_Tab_Active_Middle,Options_Tab_Active_Right', name .. ': picked')
			else
				eq(atlases_of(tab), 'Options_Tab_Left,Options_Tab_Middle,Options_Tab_Right', name .. ': a tab')
			end
			art_inside(tab, name)
			eq(size_of(tab), sizes[slot .. i], name .. ' keeps its size')
		end
		eq(picked, 1, 'one ' .. slot .. ' picked')
	end
	-- Another tab picked: the art follows.
	click(frames().subtabs[1])
	for _, tab in ipairs(frames().subtabs) do
		eq(atlases_of(tab):find('Active', 1, true) ~= nil, tab.active, 'the picked subtab follows the pick')
	end

	theme('thick')
	for slot, tabs in pairs({ tab = frames().tabs, subtab = frames().subtabs }) do
		for i, tab in ipairs(tabs) do
			eq(atlases_of(tab), '', 'Thick again: ' .. slot .. ' ' .. i .. ' has no Blizzard art')
			eq(tab.underline:IsShown(), tab.active, 'Thick again: the active ' .. slot .. ' underlined')
		end
	end
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the sidebar's open page sits on Options_List_Active", function()
	theme('thick')
	st.Config:Open('Loot')
	local function items()
		local active, other
		for _, item in ipairs(frames().nav) do
			if item.key and item.active then active = item elseif item.key and not other then other = item end
		end
		return active, other
	end
	local active, other = items()
	check(active.bar:IsShown() and active.bg:IsShown(), "Thick: the open page's blue bar and fill")
	eq(atlases_of(active), '', 'Thick: no Blizzard art')
	stub.fire_script(other, 'OnEnter')
	check(other.bg:IsShown(), 'Thick: the hover fill')
	eq(atlases_of(other), '', 'Thick: no hover art')
	stub.fire_script(other, 'OnLeave')

	theme('blizzard')
	active, other = items()
	eq(atlases_of(active), 'Options_List_Active', 'the open page on Options_List_Active')
	check(not active.bar:IsShown() and not active.bg:IsShown(), 'no blue bar or fill')
	art_fills(active, 'the open page')
	eq(atlases_of(other), '', 'another page: no art')
	stub.fire_script(other, 'OnEnter')
	eq(atlases_of(other), 'Options_List_Hover', 'under the mouse: Options_List_Hover')
	check(not other.bg:IsShown(), 'and no flat hover')
	art_fills(other, 'the page under the mouse')
	stub.fire_script(other, 'OnLeave')
	eq(atlases_of(other), '', 'the mouse gone')
	eq(size_of(active), '207x26', 'an entry keeps its size')

	theme('thick')
	active, other = items()
	check(active.bar:IsShown() and active.bg:IsShown(), "Thick again: the open page's blue bar and fill")
	eq(atlases_of(active), '', 'Thick again: no Blizzard art')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the search box carries SearchBoxTemplate's art", function()
	theme('thick')
	st.Config:Open('Loot')
	local box = frames().search
	local _, _, _, hintX = box.hint:GetPoint(1)
	eq(hintX, 8, 'Thick: the hint 8 in')
	eq(atlases_of(box), '', 'Thick: no Blizzard art')
	check(box.backdropInfo ~= nil and box.outline:IsShown(), 'Thick: its own box')

	theme('blizzard')
	eq(box.backdropInfo, nil, 'its own box off')
	check(not box.outline:IsShown(), 'and its dark line')
	eq(atlases_of(box), 'common-search-border-left,common-search-border-middle,common-search-border-right,common-search-magnifyingglass',
		"SearchBoxTemplate's border and magnifying glass")
	art_inside(box, 'the search box')
	eq(size_of(box), '190x24', 'it keeps its size')
	local glass
	for _, region in ipairs(shown_textures(box)) do
		if region:GetAtlas() == 'common-search-magnifyingglass' then glass = region end
	end
	local _, _, _, glassX = box.hint:GetPoint(1)
	check(glassX >= glass:GetRight() - box:GetLeft(), 'the hint clear of the glass')
	local left = box:GetTextInsets()
	eq(left, glassX, 'and the text starts where the hint does')

	theme('thick')
	eq(atlases_of(box), '', 'Thick again: no Blizzard art')
	check(box.backdropInfo ~= nil and box.outline:IsShown(), 'Thick again: its own box')
	eq(rgba(box:GetBackdropColor()), BOX.fill, 'Thick again: its fill')
	_, _, _, hintX = box.hint:GetPoint(1)
	eq(hintX, 8, 'Thick again: the hint 8 in')
	eq((box:GetTextInsets()), 8, 'Thick again: the text 8 in')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the footer's and the sidebar's buttons are panel buttons", function()
	theme('thick')
	st.Config:Open('Loot')
	local f = frames()
	local buttons = { reload = f.reloadButton, close = f.closeButton, editmode = f.actions[1] }
	local function panel(button)
		local n = 0
		for _, region in ipairs(shown_textures(button)) do
			local file = region:GetTexture()
			if type(file) == 'string' and file:find('UI-Panel-Button-Up', 1, true) then n = n + 1 end
		end
		return n
	end
	local sizes = {}
	for name, button in pairs(buttons) do
		eq(panel(button), 0, 'Thick: ' .. name .. ' is no panel button')
		eq(rgba(button:GetBackdropColor()), BOX.bg, 'Thick: ' .. name .. "'s own fill")
		sizes[name] = size_of(button)
	end

	theme('blizzard')
	for name, button in pairs(buttons) do
		eq(panel(button), 3, name .. " is Blizzard's panel button")
		eq(button.backdropInfo, nil, name .. ': its own box off')
		check(not button.outline:IsShown(), name .. ': and its dark line')
		art_inside(button, name)
		eq(size_of(button), sizes[name], name .. ' keeps its size')
	end

	theme('thick')
	for name, button in pairs(buttons) do
		eq(panel(button), 0, 'Thick again: ' .. name .. ' is no panel button')
		eq(rgba(button:GetBackdropColor()), BOX.bg, 'Thick again: ' .. name .. "'s own fill")
		eq(rgba(button:GetBackdropBorderColor()), BOX.edge, 'Thick again: ' .. name .. "'s own edge")
		check(button.outline:IsShown(), 'Thick again: ' .. name .. "'s dark line")
	end
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('under Thick and Thin /sui is unchanged', function()
	-- A page with a row of every type, on two tabs so the tabs draw.
	local store = {
		toggle = true, range = 3, select = 'a', input = 'text', color = { 1, 0, 0, 1 }, keybinding = 'K',
		multiselect = { a = true },
		position = { point = 'TOP', rel_point = 'TOP', x_off = 1, y_off = 2, frame = 'UIParent' },
	}
	local EVERY = st:NewModule('EveryType')
	function EVERY:GetConfigTable()
		local function o(t, order, fields)
			local option = { type = t, name = 'A ' .. t, order = order }
			for k, v in pairs(fields or {}) do option[k] = v end
			return option
		end
		return {
			name = 'Every type', type = 'group', category = 'Info', childGroups = 'tab',
			args = {
				one = {
					order = 1, name = 'One', type = 'group',
					get = function(info, part)
						local v = store[info[#info]]
						if info[#info] == 'position' or info[#info] == 'multiselect' then return v[part] end
						if type(v) == 'table' then return unpack(v) end
						return v
					end,
					set = function() end,
					args = {
						toggle = o('toggle', 1),
						small = o('toggle', 2, { size = 'small' }),
						range = o('range', 3, { min = 0, max = 10, step = 1 }),
						select = o('select', 4, { values = { a = 'A', b = 'B' } }),
						multiselect = o('multiselect', 5, { values = { a = 'A', b = 'B' } }),
						input = o('input', 6),
						smallinput = o('input', 7, { size = 'small', get = function() return 'x' end }),
						color = o('color', 8),
						execute = o('execute', 9, { func = function() end }),
						keybinding = o('keybinding', 10),
						description = o('description', 11),
						position = o('position', 12, { target = 'name' }),
					},
				},
				two = { order = 2, name = 'Two', type = 'group', args = {
					on = { type = 'toggle', name = 'On', get = function() return true end, set = function() end },
				} },
			},
		}
	end

	-- What /sui draws: each cell's rect, each widget's frame size, the colors
	-- of every box shown in it (Box: fill, edge and the dark line), and the
	-- window's own boxes and buttons and tabs. sizesOnly leaves the colors out.
	local function whole(v) return v == math.floor(v) end
	local function drawn(sizesOnly)
		local out = {}
		local function add(s) out[#out + 1] = s end
		local function rect(name, frame)
			local l, t, r, b = frame:GetLeft(), frame:GetTop(), frame:GetRight(), frame:GetBottom()
			for _, v in ipairs({ l, t, r, b }) do check(whole(v), name .. ' on whole pixels') end
			add(name .. ' ' .. size_of(frame))
		end
		local function boxes(frame, name)
			if not frame:IsShown() or sizesOnly then return end
			if frame.backdropInfo then
				add(name .. ' fill ' .. rgba(frame:GetBackdropColor()) .. ' edge ' .. rgba(frame:GetBackdropBorderColor()))
			end
			for i, child in ipairs({ frame:GetChildren() }) do boxes(child, name .. '.' .. i) end
		end
		for _, cell in ipairs(OW.GetDrawnRows()) do
			local key = cell.row.key
			local _, _, _, x, y = cell.frame:GetPoint(1)
			check(whole(x) and whole(y), key .. ': its cell on whole pixels')
			add(key .. ' cell ' .. x .. ',' .. y .. ' ' .. size_of(cell.frame))
			rect(key .. ' widget', cell.widget.frame)
			boxes(cell.widget.frame, key)
		end
		local f = frames()
		for _, name in ipairs({ 'search', 'reloadButton', 'closeButton' }) do
			rect(name, f[name])
			boxes(f[name], name)
		end
		for i, button in ipairs(f.actions) do
			rect('action ' .. i, button)
			boxes(button, 'action ' .. i)
		end
		for i, tab in ipairs(f.tabs) do
			rect('tab ' .. i, tab)
			if not sizesOnly then add('tab ' .. i .. ' underline ' .. tostring(tab.underline:IsShown())) end
		end
		check(#OW.GetDrawnRows() >= 12, 'a row of every type')
		return table.concat(out, '\n')
	end

	theme('thick')
	st.Config:Open('EveryType')
	local thick = drawn()
	local sizes = drawn(true)
	theme('blizzard')
	eq(drawn(true), sizes, 'Blizzard: every cell and widget keeps its rect')
	theme('thin')
	eq(drawn(), thick, 'Thin: as under Thick before Blizzard')
	theme('thick')
	eq(drawn(), thick, 'Thick again: as before Blizzard')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
