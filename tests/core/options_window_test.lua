-- SaftUI-Core/Config/optionswindow.lua, SaftUI's options window (st.OptionsWindow),
-- and its wiring in SaftUI-Core/Config/config.lua (st.Config:Open, Close,
-- GetWindow, Refresh, the commands, PLAYER_REGEN_DISABLED, the rebuild on a
-- profile change).
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (optionswidgets.lua), the body (optionsbody.lua), the window, and edit mode. The /sui tree is the real
-- one Config:GetOptionsTable builds, from the real Fonts and EditMode modules,
-- AceDBOptions' profiles table, and synthetic modules registered here: one
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
-- window's own groups as a second tab row.
local bagValue = 5
local INVM = st:NewModule('Inventory')
function INVM:GetConfigTable()
	local function toggle(name) return { type = 'toggle', name = name, get = function() return true end, set = function() end } end
	return {
		name = 'Bags', type = 'group', category = 'Frames',
		args = {
			general = { order = 0, name = 'General', type = 'group', args = { merge = toggle('Merge stacks') } },
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

test('LayoutRows: normal rows alternate columns 1 and 2, a full row takes a line of its own, y steps by 34', function()
	local rows = {
		{ key = 'a', width = 'normal' }, { key = 'b', width = 'normal' },
		{ key = 'c', width = 'normal' }, { key = 'wide', width = 'full' },
		{ key = 'd', width = 'normal' }, { key = 'e', width = 'normal' }, { key = 'f', width = 'normal' },
	}
	local placed, height = OW.LayoutRows(rows)
	local got = {}
	for i, p in ipairs(placed) do got[i] = p.row.key .. ':' .. tostring(p.col) .. '@' .. p.y end
	eq(table.concat(got, ' '), 'a:1@0 b:2@0 c:1@34 wide:full@68 d:1@102 e:2@102 f:1@136', 'columns and lines')
	eq(height, 170, 'five lines of 34')

	-- A full row right after a full row, and one first.
	placed, height = OW.LayoutRows({ { key = 'x', width = 'full' }, { key = 'y', width = 'full' }, { key = 'z', width = 'normal' } })
	eq(placed[1].y .. ',' .. placed[2].y .. ',' .. placed[3].y, '0,34,68', 'each full row its own line')
	eq(height, 102, 'three lines')

	-- A taller row makes its line taller.
	placed, height = OW.LayoutRows(rows, function(row) return row.key == 'b' and 60 or 34 end)
	eq(placed[3].y, 60, 'the line after a 60-high cell starts at 60')
	eq(height, 196, 'total')

	eq(select(2, OW.LayoutRows({})), 0, 'no rows, no height')
end)

test('LayoutSections: titled sections get a line, an untitled one after a nested group continues without one', function()
	local function rows(n)
		local list = {}
		for i = 1, n do list[i] = { key = 'r' .. i, width = 'normal' } end
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
	eq(table.concat(names, ','), 'Global Settings,Profiles,[Frames],Bags,Chat,Unitframes,[Combat],Auras,[Info],Loot,[Other],Edit mode,Zeta',
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
	for _, page in ipairs(OM.Pages(root)) do
		if page.key == 'Experience' then eq(page.category, 'Info', 'Experience is Info') end
	end
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
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(250)
	w.slider:SetValue(260)
	eq(uf.player.width, 260, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	st.Config:Refresh(); tick()
	eq(OW.GetRenderCount(), before, 'nor from the registry')
	eq(cell('width').widget, w, 'the same slider is still drawn')
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'the pending one went with it')
	close_all()
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
