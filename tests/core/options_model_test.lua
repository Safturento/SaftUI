-- SaftUI-Core/Config/optionsmodel.lua, the options model. It turns the /sui
-- option tree (AceConfig-3.0 tables) into what SaftUI's options window draws
-- (pages, tabs, a picker, sections and rows), and runs AceConfig's contract
-- for it (info tables, inherited members, get, set, validate, confirm) the
-- way AceConfigDialog-3.0 does.
--
-- Synthetic option tables pin each rule. Then the real tree that Core's real
-- Config/config.lua builds (config_helpers.lua): SaftUI-Misc/experience.lua's
-- page, with its Position option last in its General tab, and
-- AceDBOptions-3.0's profiles table on a real AceDB-3.0.

-- First, in the bare shell: the model needs nothing but SaftUI.
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local st = SaftUI
local OM = st.OptionsModel

-- The real tree's world, with the Experience module enabled as at login.
load_test_file('core/config_helpers.lua')
CreateFrame('Frame', 'Minimap', UIParent) -- the bar's default position anchors to it
load_saftui('SaftUI-Misc/experience.lua')
local XP = st:GetModule('Experience')
XP:Enable()

------------------------------------------------------------------ helpers

-- An option of the given type and name, with any other fields.
local function opt(otype, name, fields)
	local option = { type = otype, name = name }
	for key, value in pairs(fields or {}) do option[key] = value end
	return option
end

local function group(name, args, fields)
	local option = opt('group', name, fields)
	option.args = args or {}
	return option
end

-- The keys of a list of entries, joined with commas.
local function keys(list)
	local out = {}
	for i, entry in ipairs(list or {}) do out[i] = tostring(entry.key) end
	return table.concat(out, ',')
end

-- A view's sections as 'title:key,key|title:key', '-' for no title.
local function layout(view)
	local out = {}
	for i, section in ipairs(view.sections) do
		out[i] = (section.title or '-') .. ':' .. keys(section.rows)
	end
	return table.concat(out, '|')
end

-- The view's row with this key, and its section.
local function row(view, key)
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do
			if r.key == key then return r, section end
		end
	end
end

local function all_rows(view)
	local out = {}
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do out[#out + 1] = r end
	end
	return out
end

-- Search results as their paths, 'Page.tab.key,...'.
local function paths(results)
	local out = {}
	for i, result in ipairs(results) do out[i] = table.concat(result.path, '.') end
	return table.concat(out, ',')
end

local function has_key(list, key)
	for _, entry in ipairs(list) do
		if entry.key == key then return true end
	end
	return false
end

-- Shaped like SaftUI-Unitframes' tree once it picks units: a unit picker,
-- element tabs inside, and an element's own groups below those.
local function unitframes_root()
	return {
		Unitframes = group('Unitframes', {
			player = group('Player', {
				copy = opt('execute', 'Copy from', { order = -99, func = function() end }),
				general = group('General', {
					enable = opt('toggle', 'Enable', { order = 0 }),
					position = group('Position', { point = opt('select', 'Anchor', { values = {} }) }, { inline = true, order = 5 }),
				}, { order = 0 }),
				health = group('Health', {
					enable = opt('toggle', 'Enable', { order = 0 }),
					text = group('Text', { size = opt('range', 'Font size') }, { order = 2, desc = 'The health text.' }),
				}, { order = 1 }),
			}, { order = 1, childGroups = 'tab' }),
			target = group('Target', {
				general = group('General', { enable = opt('toggle', 'Enable') }),
			}, { order = 2, childGroups = 'tab' }),
		}, { childGroups = 'select' }),
	}
end

-- Shaped like SaftUI-Minimap's once config.lua has reshaped it: one General
-- tab with the Position box merged in.
local function minimap_page()
	return group('Minimap', {
		general = group('General', {
			size = opt('range', 'Size', { order = 1 }),
			secret = opt('range', 'Secret size', { order = 2, hidden = true }),
			gui = opt('range', 'Gui size', { order = 3, guiHidden = true }),
			text = opt('description', 'Size matters here', { order = 4 }),
			position = group('Position', { point = opt('select', 'Anchor', { values = {} }) }, { inline = true, order = 1000 }),
		}, { order = 1 }),
	}, { childGroups = 'tab' })
end

------------------------------------------------------------------ pages

test('Pages: in order then name, topmenu and hidden groups left out, Fonts and profile special, Other by default', function()
	local root = {
		topmenu = group('', { edit_mode = opt('execute', 'Edit mode', { order = 1, func = function() end }) }, { inline = true, order = 0 }),
		profile = group('Profiles', {}, { order = -999 }),
		Fonts = group('Fonts', {}, { order = 1 }),
		Zeta = group('Zeta', {}, { category = 'Info' }),
		Alpha = group('Alpha', {}, { category = 'Frames' }),
		Early = group('Early', {}, { order = 5, category = 'Combat', desc = 'Comes first.' }),
		Dyn = group(function(info) return 'Made ' .. info[#info] end),
		Gone = group('Gone', {}, { hidden = true }),
		Gui = group('Gui', {}, { guiHidden = true }),
		loose = opt('toggle', 'Not a page'),
	}
	local pages = OM.Pages(root)
	eq(keys(pages), 'Fonts,Early,Alpha,Dyn,Zeta,profile',
		'by order, then name (Alpha, Made Dyn, Zeta at the default 100); a negative order last, as AceConfigDialog sorts')
	local by = {}
	for _, page in ipairs(pages) do by[page.key] = page end
	eq(by.Fonts.name, 'Global Settings', 'Fonts is named Global Settings')
	eq(by.Fonts.special, 'global', 'Fonts is the global page')
	eq(by.profile.special, 'profiles', 'profile is the profiles page')
	eq(by.profile.name, 'Profiles', 'and keeps its name')
	eq(by.Alpha.special, nil, 'a module page is not special')
	eq(by.Alpha.category, 'Frames', 'category comes from the group')
	eq(by.Dyn.category, 'Other', 'no category gives Other')
	eq(by.Dyn.name, 'Made Dyn', 'a function name is called with info')
	eq(by.Early.desc, 'Comes first.', 'desc')
end)

------------------------------------------------------------------ nesting

test("tabs: non-inline child groups are tabs, under tree or tab; the first is selected; the page's own options come first", function()
	local function module(childGroups)
		return group('Mod', {
			enable = opt('toggle', 'Enable', { order = 1 }),
			general = group('General', { size = opt('range', 'Size') }, { order = 1 }),
			colors = group('Colors', { bar = opt('color', 'Bar') }, { order = 2 }),
			box = group('Box', { a = opt('toggle', 'A') }, { inline = true, order = 3, desc = 'A note.' }),
		}, { desc = 'A module.', childGroups = childGroups })
	end
	for _, childGroups in ipairs({ false, 'tree', 'tab' }) do
		local label = ' (childGroups ' .. tostring(childGroups or 'nil') .. ')'
		local root = { Mod = module(childGroups or nil) }
		local view = OM.BuildView(root, 'Mod')
		eq(view.title, 'Mod', 'title' .. label)
		eq(view.desc, 'A module.', 'desc' .. label)
		eq(keys(view.tabs), 'general,colors', 'tabs' .. label)
		eq(view.tab, 'general', 'the first tab' .. label)
		check(view.picker == nil and #view.subtabs == 0 and view.subtab == nil, 'no picker or second row' .. label)
		eq(layout(view), '-:enable|Box:a|-:size', "the page's own options and inline group, then the tab's" .. label)
		eq(view.sections[2].note, 'A note.', "the inline group's desc is its note" .. label)
		view = OM.BuildView(root, 'Mod', { tab = 'colors' })
		eq(view.tab, 'colors', 'a chosen tab' .. label)
		eq(layout(view), '-:enable|Box:a|-:bar', "and its rows" .. label)
		eq(OM.BuildView(root, 'Mod', { tab = 'nope' }).tab, 'general', "a tab that isn't there falls back to the first" .. label)
	end
	eq(OM.BuildView({}, 'Missing'), nil, 'no page, no view')
end)

test('a picker: childGroups = select makes the child groups a picker, titled with the group name', function()
	local root = { Bars = group('Bars', {
		bar1 = group('Bar 1', { size = opt('range', 'Size') }, { order = 1 }),
		bar2 = group('Bar 2', { alpha = opt('range', 'Alpha') }, { order = 2 }),
	}, { childGroups = 'select' }) }
	local view = OM.BuildView(root, 'Bars')
	check(view.picker ~= nil, 'a picker')
	eq(view.picker.name, 'Bars', "titled with the group's name, as AceConfigDialog's dropdown group is")
	eq(keys(view.picker.values), 'bar1,bar2', 'its values')
	eq(view.picker.values[2].name, 'Bar 2', 'with names')
	eq(view.picker.selected, 'bar1', 'the first by default')
	eq(#view.tabs, 0, 'no tabs')
	eq(layout(view), '-:size', "the picked group's rows")
	view = OM.BuildView(root, 'Bars', { pick = 'bar2' })
	eq(view.picker.selected, 'bar2', 'a chosen pick')
	eq(layout(view), '-:alpha', 'and its rows')
end)

test('a tab with child groups of its own gets a second tab row', function()
	local root = { Deep = group('Deep', {
		one = group('One', {
			top = opt('toggle', 'Top', { order = 0 }),
			a = group('A', { x = opt('toggle', 'X') }, { order = 1 }),
			b = group('B', { y = opt('toggle', 'Y') }, { order = 2 }),
		}, { order = 1 }),
		two = group('Two', { z = opt('toggle', 'Z') }, { order = 2 }),
	}) }
	local view = OM.BuildView(root, 'Deep')
	eq(keys(view.tabs), 'one,two', 'tabs')
	eq(view.tab, 'one', 'first tab')
	eq(keys(view.subtabs), 'a,b', 'the second row')
	eq(view.subtab, 'a', 'its first')
	eq(layout(view), '-:top|-:x', "the tab's own options, then the subtab's")
	view = OM.BuildView(root, 'Deep', { tab = 'one', subtab = 'b' })
	eq(view.subtab, 'b', 'a chosen subtab')
	eq(layout(view), '-:top|-:y', 'and its rows')
	view = OM.BuildView(root, 'Deep', { tab = 'two' })
	check(#view.subtabs == 0 and view.subtab == nil, 'a tab without child groups has no second row')
	eq(layout(view), '-:z', 'its rows')
end)

test('a picker inside a tab: a tab that says select', function()
	local root = { Units = group('Units', {
		frames = group('Frames', {
			player = group('Player', { w = opt('range', 'Width') }, { order = 1 }),
			target = group('Target', { h = opt('range', 'Height') }, { order = 2 }),
		}, { order = 1, childGroups = 'select' }),
		other = group('Other', { o = opt('toggle', 'O') }, { order = 2 }),
	}) }
	local view = OM.BuildView(root, 'Units')
	eq(keys(view.tabs), 'frames,other', 'tabs')
	eq(view.tab, 'frames', 'first tab')
	eq(view.picker and view.picker.name, 'Frames', "the tab's child groups are the picker")
	eq(keys(view.picker.values), 'player,target', 'its values')
	eq(view.picker.selected, 'player', 'its first')
	eq(#view.subtabs, 0, 'no second tab row')
	eq(layout(view), '-:w', "the pick's rows")
	view = OM.BuildView(root, 'Units', { tab = 'frames', pick = 'target' })
	eq(view.picker.selected, 'target', 'a chosen pick')
	eq(layout(view), '-:h', 'and its rows')
	view = OM.BuildView(root, 'Units', { tab = 'other' })
	eq(view.picker, nil, 'another tab has no picker')
	eq(layout(view), '-:o', 'its rows')
end)

test('a page picker with tabs inside, and a third non-inline level drawn as a section (Unitframes-shaped)', function()
	local root = unitframes_root()
	local view = OM.BuildView(root, 'Unitframes')
	eq(view.picker.name, 'Unitframes', 'the unit picker')
	eq(keys(view.picker.values), 'player,target', 'units')
	eq(view.picker.selected, 'player', 'the first unit')
	eq(keys(view.tabs), 'general,health', "the unit's element tabs")
	eq(view.tab, 'general', 'the first element')
	eq(#view.subtabs, 0, 'no second row')
	eq(layout(view), '-:copy|-:enable|Position:point', "the unit's own Copy from, then General's rows and its Position box")
	view = OM.BuildView(root, 'Unitframes', { pick = 'player', tab = 'health' })
	eq(layout(view), '-:copy|-:enable|Text:size', "Health's Text group, a level below the tabs, is a section")
	local _, section = row(view, 'size')
	eq(section.note, 'The health text.', "the group's desc is the section's note")
	view = OM.BuildView(root, 'Unitframes', { pick = 'target' })
	eq(view.picker.selected, 'target', 'another unit')
	eq(keys(view.tabs), 'general', 'its tabs')
	eq(layout(view), '-:enable', 'its rows')
end)

test('SelectionForPath: a path of option keys (edit mode, /sui) to a page and selection', function()
	local root = unitframes_root()
	root.Minimap = minimap_page()
	local page, selection = OM.SelectionForPath(root, { 'Unitframes', 'player', 'general' })
	eq(page, 'Unitframes', 'the page')
	check(selection.pick == 'player' and selection.tab == 'general' and selection.subtab == nil, 'the unit and its tab')
	local view = OM.BuildView(root, page, selection)
	check(view.picker.selected == 'player' and view.tab == 'general', 'the view opens there')
	page, selection = OM.SelectionForPath(root, { 'Unitframes', 'target', 'general' })
	check(selection.pick == 'target' and selection.tab == 'general', 'another unit')
	page, selection = OM.SelectionForPath(root, { 'Unitframes', 'player', 'health', 'text', 'size' })
	check(selection.pick == 'player' and selection.tab == 'health' and selection.subtab == nil,
		'keys past the tab level are sections on the page, so they select nothing more')
	page, selection = OM.SelectionForPath(root, { 'Minimap', 'general' })
	check(page == 'Minimap' and selection.tab == 'general' and selection.pick == nil, "the Minimap mover's path")
	page, selection = OM.SelectionForPath(root, { 'Minimap', 'general', 'position' })
	eq(selection.tab, 'general', 'an inline group selects nothing more')
	page, selection = OM.SelectionForPath(root, { 'Minimap' })
	check(page == 'Minimap' and next(selection) == nil, 'a page alone selects nothing, so it opens on its first tab')
	page, selection = OM.SelectionForPath(root, { 'Unitframes', 'nobody' })
	check(page == 'Unitframes' and next(selection) == nil, 'a key that is no pick or tab selects nothing')
	eq(OM.SelectionForPath(root, { 'Missing' }), nil, 'no such page')
end)

test('sections: inline groups are titled with name and desc, a header starts one, groups inside inline groups are sections, empty ones dropped', function()
	local root = { Sect = group('Sect', {
		a = opt('toggle', 'A', { order = 1 }),
		head = opt('header', 'Colors', { order = 2 }),
		b = opt('color', 'B', { order = 3 }),
		box = group('Box', {
			c = opt('toggle', 'C', { order = 1 }),
			inner = group('Inner', { d = opt('toggle', 'D') }, { order = 2 }),
		}, { inline = true, order = 4, desc = 'About the box.' }),
		e = opt('toggle', 'E', { order = 5 }),
		empty = group('Empty', { gone = opt('toggle', 'Gone', { hidden = true }) }, { inline = true, order = 6 }),
		untitled = group('', { f = opt('toggle', 'F') }, { inline = true, order = 7 }),
	}) }
	local view = OM.BuildView(root, 'Sect')
	eq(layout(view), '-:a|Colors:b|Box:c|Inner:d|-:e|-:f',
		'a header and each inline group start a section, and what follows a group continues untitled')
	eq(view.sections[1].note, nil, 'no note without a desc')
	eq(view.sections[3].note, 'About the box.', "the inline group's desc is the note")
	-- The spec's rule: childGroups = 'inline' on a group makes its child
	-- groups sections, not tabs.
	root.Flat = group('Flat', { g = group('G', { x = opt('toggle', 'X') }) }, { childGroups = 'inline' })
	view = OM.BuildView(root, 'Flat')
	eq(#view.tabs, 0, 'no tabs')
	eq(layout(view), 'G:x', 'the child group is a section')
end)

------------------------------------------------------------------ rows

test('rows: size is the option\'s small or wide; Ace width is ignored; small only for toggle, color, execute, input', function()
	local root = { Sizes = group('Sizes', {
		t = opt('toggle', 'T', { order = 1, size = 'small' }),
		c = opt('color', 'C', { order = 2, size = 'small' }),
		e = opt('execute', 'E', { order = 3, size = 'small' }),
		i = opt('input', 'I', { order = 4, size = 'small' }),
		r = opt('range', 'R', { order = 5, size = 'small' }),
		s = opt('select', 'S', { order = 6, size = 'wide' }),
		w = opt('toggle', 'W', { order = 7, width = 'full' }),
		h = opt('toggle', 'H', { order = 8, size = 'huge' }),
		d = opt('description', 'D', { order = 9, size = 'small' }),
		p = opt('position', 'P', { order = 10, get = function() end, set = function() end }),
	}) }
	local view = OM.BuildView(root, 'Sizes')
	local function size(key) return row(view, key).size end
	eq(size('t'), 'small', 'a small toggle')
	eq(size('c'), 'small', 'a small color')
	eq(size('e'), 'small', 'a small execute')
	eq(size('i'), 'small', 'a small input')
	eq(size('r'), 'normal', 'a range cannot be small')
	eq(size('s'), 'wide', 'wide')
	eq(size('w'), 'normal', "Ace's width is not read")
	eq(size('h'), 'normal', 'an unknown size is normal')
	eq(size('d'), 'wide', 'a description is wide, whatever its size')
	eq(size('p'), 'wide', 'a position row is wide')
	eq(row(view, 't').width, nil, 'rows carry no width')
end)

test('a position row gets a section of its own, titled with its name; rows after it continue untitled', function()
	local root = { Pos = group('Pos', {
		a = opt('toggle', 'A', { order = 1 }),
		pos = opt('position', 'Position', { order = 2, get = function() end, set = function() end }),
		b = opt('toggle', 'B', { order = 3 }),
	}) }
	eq(layout(OM.BuildView(root, 'Pos')), '-:a|Position:pos|-:b', 'sections')
end)


test('rows: in order (100 by default, negatives last), then name, then key', function()
	local root = { Order = group('Order', {
		z = opt('toggle', 'Zed', { order = 1 }),
		a = opt('toggle', 'alpha', { order = 1, desc = 'A tip.' }), -- names compare uppercased, as AceConfigDialog's do
		n = opt('toggle', 'No order'),
		neg = opt('toggle', 'Negative', { order = -1 }),
		f = opt('toggle', 'Full', { order = 2, width = 'full' }),
		d = opt('toggle', 'Double', { order = 3, width = 'double' }),
		h = opt('toggle', 'Half', { order = 4, width = 'half' }),
		num = opt('range', 'Number', { order = 5, width = 0.5 }),
		big = opt('range', 'Big number', { order = 5.5, width = 1.5 }),
		text = opt('description', 'Some text', { order = 6 }),
		textw = opt('description', 'Narrow text', { order = 7, width = 'normal' }),
		same2 = opt('toggle', 'Same', { order = 8 }),
		same1 = opt('toggle', 'Same', { order = 8 }),
		fnorder = opt('toggle', 'Fn', { order = function() return 9 end }),
	}) }
	local view = OM.BuildView(root, 'Order')
	eq(layout(view), '-:a,z,f,d,h,num,big,text,textw,same1,same2,fnorder,n,neg', 'the order')
	local r = row(view, 'a')
	eq(r.key, 'a', 'key')
	eq(r.type, 'toggle', 'type')
	eq(r.name, 'alpha', 'name')
	eq(r.desc, 'A tip.', 'desc')
	eq(r.disabled, false, 'disabled')
	eq(table.concat(r.path, '.'), 'Order.a', 'path from the root')
	eq(r.option, root.Order.args.a, 'the option table')
end)

test('hidden and disabled: booleans, functions, guiHidden, and values inherited from a parent group', function()
	local state = { hide = true, lock = true }
	local seen = {}
	local root = { Vis = group('Vis', {
		shown = opt('toggle', 'Shown', { order = 1 }),
		hiddenBool = opt('toggle', 'Hidden', { order = 2, hidden = true }),
		hiddenFn = opt('toggle', 'Hidden fn', { order = 3, hidden = function() return state.hide end }),
		gui = opt('toggle', 'Gui hidden', { order = 4, guiHidden = true }),
		override = opt('toggle', 'Shown anyway', { order = 5, hidden = true, guiHidden = false }),
		off = opt('toggle', 'Off', { order = 6, disabled = true }),
		offFn = opt('toggle', 'Off fn', { order = 7, disabled = function() return state.lock end }),
		locked = group('Locked', {
			child = opt('toggle', 'Child', { order = 1 }),
			free = opt('toggle', 'Free', { order = 2, disabled = false }),
		}, { inline = true, order = 8, disabled = function(info)
			seen[#seen + 1] = info[#info]
			return state.lock
		end }),
		secret = group('Secret', {
			one = opt('toggle', 'One', { order = 1 }),
			two = opt('toggle', 'Two', { order = 2 }),
		}, { inline = true, order = 9, hidden = function(info) return info[#info] == 'two' end }),
		gone = group('Gone', { x = opt('toggle', 'X') }, { inline = true, order = 10, hidden = true }),
	}) }
	local view = OM.BuildView(root, 'Vis')
	eq(layout(view), '-:shown,override,off,offFn|Locked:child,free|Secret:one',
		"hidden true, a hidden function, guiHidden and a hidden group are left out; guiHidden = false shows an option anyway; a group's hidden function is called for each child")
	local function disabled(key) return row(view, key).disabled end
	check(disabled('shown') == false and disabled('off') == true and disabled('offFn') == true, 'disabled true and a disabled function')
	eq(disabled('child'), true, "the group's disabled is inherited")
	eq(seen[1], 'child', "the group's disabled function is called with the child's info")
	eq(disabled('free'), false, "an option's own disabled = false wins")
	local locked = view
	state.hide, state.lock = false, false
	view = OM.BuildView(root, 'Vis')
	eq(layout(view), '-:shown,hiddenFn,override,off,offFn|Locked:child,free|Secret:one', 'a hidden function is read again')
	check(disabled('offFn') == false and disabled('child') == false and disabled('off') == true, 'and so is a disabled function')

	-- IsDisabled checks a row built earlier as it is now (the window, mid-drag).
	local offFn, child = row(locked, 'offFn'), row(locked, 'child')
	check(offFn.disabled and child.disabled, 'built while locked')
	check(OM.IsDisabled(root, offFn) == false and OM.IsDisabled(root, child) == false, 'unlocked now: its own and an inherited disabled')
	check(OM.IsDisabled(root, row(locked, 'off')) == true and OM.IsDisabled(root, row(locked, 'free')) == false, 'true stays true, false = false wins')
	state.lock = true
	check(OM.IsDisabled(root, row(view, 'offFn')) == true, 'and the other way')
end)

test('tabs: hidden ones are left out, disabled ones are listed but not selected by default', function()
	local root = { Tabs = group('Tabs', {
		first = group('First', { a = opt('toggle', 'A') }, { order = 1, disabled = true }),
		second = group('Second', { b = opt('toggle', 'B') }, { order = 2 }),
		gone = group('Gone', { c = opt('toggle', 'C') }, { order = 3, hidden = true }),
		gui = group('Gui', { d = opt('toggle', 'D') }, { order = 4, guiHidden = true }),
	}) }
	local view = OM.BuildView(root, 'Tabs')
	eq(keys(view.tabs), 'first,second', 'hidden tabs left out')
	check(view.tabs[1].disabled == true and view.tabs[2].disabled == false, 'a disabled tab is marked')
	eq(view.tab, 'second', 'the first tab that is not disabled, as AceConfigDialog selects')
	eq(layout(view), '-:b', 'its rows')
	view = OM.BuildView(root, 'Tabs', { tab = 'first' })
	eq(view.tab, 'first', 'a disabled tab chosen by key still opens, as a saved AceConfigDialog selection does')
	eq(row(view, 'a').disabled, true, "its rows inherit the tab's disabled")
	eq(OM.BuildView(root, 'Tabs', { tab = 'gone' }).tab, 'second', 'a hidden tab is never selected')
end)

------------------------------------------------------------------ get, set, validate

test('get, set and validate through a handler with method-name strings, and through inherited get and set', function()
	local handler = { store = { name = 'Ann' } }
	function handler:Get(info) return self.store[info[#info]] end
	function handler:Set(info, value) self.store[info[#info]] = value end
	function handler:Check(info, value)
		if value == 'bad' then return 'No bad names' end
		return true
	end
	local sub, flags, color = {}, {}, { 0.1, 0.2, 0.3, 0.4 }
	local root = { H = group('H', {
		name = opt('input', 'Name', { order = 1, validate = 'Check' }),
		plain = opt('input', 'Plain', { order = 2 }),
		usage = opt('input', 'Usage', { order = 3, validate = function() return false end, usage = 'Type a word' }),
		bare = opt('input', 'Bare', { order = 4, validate = function() return false end }),
		digits = opt('input', 'Digits', { order = 5, pattern = '^%d+$' }),
		sub = group('Sub', {
			inner = opt('toggle', 'Inner', { order = 1 }),
			own = opt('toggle', 'Own', { order = 2, get = function() return 'own' end }),
		}, { inline = true, order = 6,
			get = function(info) return sub[info[#info]] end,
			set = function(info, value) sub[info[#info]] = value end }),
		readonly = opt('input', 'No get', { order = 7, get = false }),
		multi = opt('multiselect', 'Multi', { order = 8, values = { a = 'A', b = 'B' },
			get = function(info, key) return flags[key] end,
			set = function(info, key, value) flags[key] = value end }),
		color = opt('color', 'Color', { order = 9, hasAlpha = true,
			get = function() return unpack(color) end,
			set = function(info, r, g, b, a) color = { r, g, b, a } end }),
	}, { handler = handler, get = 'Get', set = 'Set' }) }
	local view = OM.BuildView(root, 'H')
	local name = row(view, 'name')
	eq(OM.Get(root, name), 'Ann', "the handler's Get method")
	eq(OM.Set(root, name, 'Bob'), true, 'a set')
	eq(handler.store.name, 'Bob', "goes through the handler's Set method")
	eq(OM.Get(root, name), 'Bob', 'and reads back')
	local ok, err = OM.Set(root, name, 'bad')
	check(ok == false and err == 'No bad names', "a validate method's string is the message")
	eq(handler.store.name, 'Bob', 'and nothing is set')
	ok, err = OM.Validate(root, name, 'bad')
	check(ok == false and err == 'No bad names', 'Validate alone gives the same')
	eq(OM.Validate(root, name, 'Cy'), true, 'and true for a good value')
	ok, err = OM.Set(root, row(view, 'usage'), 'x')
	check(ok == false and err == 'Usage: Type a word', 'a false validate shows the usage')
	ok, err = OM.Set(root, row(view, 'bare'), 'x')
	check(ok == false and err == 'Bare: Invalid Value', 'or Invalid Value, as AceConfigDialog words it')
	ok, err = OM.Set(root, row(view, 'digits'), 'abc')
	check(ok == false and err == 'Digits: Expected ^%d+$', "an input's pattern is checked first")
	eq(OM.Set(root, row(view, 'digits'), '42'), true, 'a value that matches is set')
	eq(handler.store.digits, '42', 'through the handler')
	eq(OM.Set(root, row(view, 'plain'), 'p'), true, 'no validate')
	eq(handler.store.plain, 'p', 'set')
	local inner = row(view, 'inner')
	eq(OM.Set(root, inner, true), true, 'a set in the inline group')
	check(sub.inner == true and handler.store.inner == nil, "the group's own set wins over the page's")
	eq(OM.Get(root, inner), true, "and the group's own get")
	eq(OM.Get(root, row(view, 'own')), 'own', "an option's own get wins over its group's")
	eq(OM.Get(root, row(view, 'readonly')), false, "get = false stops inheriting: it reads false, as AceDBOptions' New does")
	local multi = row(view, 'multi')
	eq(OM.Set(root, multi, 'b', true), true, 'a multiselect set(info, key, value)')
	check(flags.b == true and flags.a == nil, 'sets that key')
	check(OM.Get(root, multi, 'b') == true and OM.Get(root, multi, 'a') == nil, 'and get(info, key) reads it')
	local r, g, b, a = OM.Get(root, row(view, 'color'))
	check(r == 0.1 and g == 0.2 and b == 0.3 and a == 0.4, "a color's get gives r, g, b and a")
	OM.Set(root, row(view, 'color'), 1, 0.5, 0, 0.25)
	check(color[1] == 1 and color[2] == 0.5 and color[3] == 0 and color[4] == 0.25, 'and its set takes them')
end)

test("errors: a set or validate that errors is reported and fails; a handler method that isn't there errors, as AceConfigDialog's do", function()
	local root = { E = group('E', {
		broken = opt('toggle', 'Broken', { order = 1, set = function() error('set broke') end }),
		badcheck = opt('toggle', 'Bad check', { order = 2, validate = function() error('check broke') end, set = function() end }),
		missing = opt('toggle', 'Missing', { order = 3, get = 'Nope' }),
	}, { handler = {} }) }
	local view = OM.BuildView(root, 'E')
	eq(OM.Set(root, row(view, 'broken'), true), false, 'a set that errors gives false')
	local errors = take_errors()
	check(#errors == 1 and tostring(errors[1]):find('set broke', 1, true) ~= nil, 'and its error goes to the error handler')
	local ok, err = OM.Set(root, row(view, 'badcheck'), true)
	check(ok == false and err == 'Bad check: Invalid Value', 'a validate that errors fails validation')
	errors = take_errors()
	check(#errors == 1 and tostring(errors[1]):find('check broke', 1, true) ~= nil, 'and its error goes to the error handler')
	local okGet, message = pcall(OM.Get, root, row(view, 'missing'))
	check(not okGet and tostring(message):find("Method Nope doesn't exist in handler for type get", 1, true) ~= nil,
		'a missing method errors')
end)

test("info: info[#info] is the key, arg passes through, and info.options is AceConfig's table around the root", function()
	local seen
	local handler = {}
	local root = { Info = group('Info', {
		box = group('Box', {
			field = opt('toggle', 'Field', { arg = 'payload', get = function(info) seen = info; return true end }),
		}, { inline = true }),
	}, { handler = handler }) }
	local r = row(OM.BuildView(root, 'Info'), 'field')
	OM.Get(root, r)
	eq(#seen, 3, 'the path')
	check(seen[1] == 'Info' and seen[2] == 'box', 'from the root')
	eq(seen[#seen], 'field', 'info[#info] is the option key')
	eq(seen.arg, 'payload', 'info.arg')
	eq(seen.handler, handler, 'the nearest handler, inherited')
	eq(seen.option, r.option, 'info.option')
	eq(seen.type, 'toggle', 'info.type')
	eq(seen.uiType, 'dialog', 'info.uiType')
	eq(seen.uiName, st.name, 'info.uiName')
	check(seen.appName == st.name and seen[0] == st.name, 'the app name, as AceConfig registered it')
	eq(seen.options.args, root, 'info.options is the table AceConfig registered, its args the root')
	eq(seen.options.type, 'group', 'a group')
	local info = OM.Info(root, { 'Info', 'box', 'field' })
	check(info[3] == 'field' and info.arg == 'payload' and info.handler == handler and info.option == r.option
		and info.options.args == root and info.uiType == 'dialog', 'OM.Info builds the same')
end)

test("info.options works with SaftUI's own code that walks it (Config/widgets.lua's number inputs)", function()
	local store = { width = 200 }
	local root = { Box = group('Box', {
		width = st.Config.generators.width(1),
	}, {
		get = function(info) return store[info[#info]] end,
		set = function(info, value) store[info[#info]] = value end,
	}) }
	local r = row(OM.BuildView(root, 'Box'), 'width')
	eq(OM.Get(root, r), '200', "the box shows the group's number as text (NumberInputGet finds the get through info.options)")
	eq(OM.Set(root, r, '250'), true, 'set')
	eq(store.width, 250, 'and stored as a number')
end)

test("Member: a description's image, its size and imageCoords, as AceConfigDialog reads them", function()
	local trim = 0.1
	local handler = { Coords = function(_, info) return { 0, 1, 0, 1 }, info[#info] end }
	local root = { Pics = group('Pics', {
		path = opt('description', 'Path', { order = 1, image = 'Interface\\Icons\\X', imageWidth = 36, imageHeight = 20,
			imageCoords = { 0.1, 0.9, 0.1, 0.9 } }),
		fn = opt('description', 'Fn', { order = 2,
			image = function(info) return 'Interface\\Icons\\' .. info[#info], 24, 28 end,
			imageCoords = function() return { trim, 1 - trim, trim, 1 - trim } end }),
		method = opt('description', 'Method', { order = 3, image = 136048, imageCoords = 'Coords' }),
	}, { handler = handler }) }
	local view = OM.BuildView(root, 'Pics')
	local p, f, m = row(view, 'path'), row(view, 'fn'), row(view, 'method')
	eq(OM.Member(root, p, 'image'), 'Interface\\Icons\\X', 'a path is the image, not a method name')
	eq(OM.Member(root, p, 'imageWidth') .. 'x' .. OM.Member(root, p, 'imageHeight'), '36x20', 'its size')
	eq(table.concat(OM.Member(root, p, 'imageCoords'), ','), '0.1,0.9,0.1,0.9', 'a table of coords')
	local image, width, height = OM.Member(root, f, 'image')
	eq(image .. ' ' .. width .. 'x' .. height, 'Interface\\Icons\\fn 24x28', 'a function gives the texture, width and height, called with info')
	eq(table.concat(OM.Member(root, f, 'imageCoords'), ','), '0.1,0.9,0.1,0.9', 'a coords function')
	trim = 0.2
	eq(table.concat(OM.Member(root, f, 'imageCoords'), ','), '0.2,0.8,0.2,0.8', 'called again on each read')
	eq(OM.Member(root, m, 'image'), 136048, 'a fileID')
	local coords, key = OM.Member(root, m, 'imageCoords')
	eq(table.concat(coords, ',') .. ' ' .. key, '0,1,0,1 method', "a string is a handler method's name, as AceConfigDialog reads imageCoords")
end)

------------------------------------------------------------------ values, confirm

test('Values: read again on every call, so a list that depends on another setting follows it; sorting orders it, else the keys do', function()
	local settings = { kind = 'fruit' }
	local root = { V = group('V', {
		kind = opt('select', 'Kind', { order = 1, values = { fruit = 'Fruit', veg = 'Vegetable' },
			get = function() return settings.kind end,
			set = function(_, value) settings.kind = value end }),
		item = opt('select', 'Item', { order = 2, values = function()
			if settings.kind == 'fruit' then return { apple = 'Apple', pear = 'Pear' } end
			return { leek = 'Leek' }
		end }),
		sorted = opt('select', 'Sorted', { order = 3, values = { a = 'Alpha', b = 'Bravo', c = 'Charlie' }, sorting = { 'c', 'a', 'b' } }),
		sortfn = opt('select', 'Sort fn', { order = 4, values = { a = 'Alpha', b = 'Bravo' }, sorting = function() return { 'b', 'a' } end }),
		numbers = opt('select', 'Numbers', { order = 5, values = { [10] = 'Ten', [9] = 'Nine', [2] = 'Two' } }),
		bykey = opt('select', 'By key', { order = 6, values = { b = 'Apple', a = 'Zebra' } }),
		method = opt('multiselect', 'Method', { order = 7, values = 'List' }),
	}, { handler = { List = function(self, info) return { x = info[#info] } end } }) }
	local view = OM.BuildView(root, 'V')
	local item = row(view, 'item')
	eq(keys(OM.Values(root, item)), 'apple,pear', 'the values')
	eq(OM.Values(root, item)[1].name, 'Apple', 'with names')
	eq(OM.Set(root, row(view, 'kind'), 'veg'), true, 'another setting changes')
	eq(keys(OM.Values(root, item)), 'leek', 'the same row reads its values again')
	eq(keys(OM.Values(root, row(view, 'sorted'))), 'c,a,b', 'sorting gives the order')
	eq(keys(OM.Values(root, row(view, 'sortfn'))), 'b,a', 'a sorting function too')
	eq(keys(OM.Values(root, row(view, 'numbers'))), '2,9,10', "number keys sort as numbers, as AceGUI's dropdown sorts")
	eq(keys(OM.Values(root, row(view, 'bykey'))), 'a,b', "without sorting, by key, as AceGUI's dropdown sorts")
	local listed = OM.Values(root, row(view, 'method'))
	check(#listed == 1 and listed[1].key == 'x' and listed[1].name == 'method', 'a handler method name, called with info')
end)

test("Confirm: confirmText, else the name and desc as AceConfigDialog asks; a function's or method's string; inherited", function()
	local handler = { Ask = function(self, info) return 'Asked about ' .. info[#info] end }
	local root = { C = group('C', {
		text = opt('execute', 'Reset', { order = 1, confirm = true, confirmText = 'Really reset?' }),
		desc = opt('execute', 'Wipe', { order = 2, desc = 'Wipes it all', confirm = true }),
		bare = opt('execute', 'Go', { order = 3, confirm = true }),
		fn = opt('execute', 'Fn', { order = 4, confirm = function(info) return 'Delete ' .. info[#info] .. '?' end }),
		fntrue = opt('execute', 'Fn true', { order = 5, confirm = function() return true end, confirmText = 'Sure?' }),
		fnfalse = opt('execute', 'Fn false', { order = 6, confirm = function() return false end }),
		fnone = opt('execute', 'Fn one', { order = 6.1, confirm = function() return 1 end }),
		fnerror = opt('execute', 'Fn error', { order = 6.2, confirm = function() error('confirm broke') end }),
		method = opt('execute', 'Method', { order = 7, confirm = 'Ask' }),
		none = opt('execute', 'None', { order = 8 }),
		careful = group('Careful', { flag = opt('toggle', 'Flag') }, { inline = true, order = 9, confirm = true }),
		value = opt('select', 'Value', { order = 10, values = {}, confirm = function(info, value) return 'Pick ' .. tostring(value) .. '?' end }),
	}, { handler = handler }) }
	local view = OM.BuildView(root, 'C')
	local function confirm(key, ...) return OM.Confirm(root, row(view, key), ...) end
	eq(confirm('text'), 'Really reset?', 'confirmText')
	eq(confirm('desc'), 'Wipe - Wipes it all', 'no confirmText: the name and desc')
	eq(confirm('bare'), 'Go', 'or the name alone')
	eq(confirm('fn'), 'Delete fn?', "a function's string, called with info")
	eq(confirm('fntrue'), 'Sure?', 'a function returning true uses confirmText')
	eq(confirm('fnfalse'), nil, 'a function returning false asks nothing')
	eq(confirm('fnone'), nil, 'nor one returning 1: only true or a string asks, as in AceConfigDialog')
	eq(confirm('fnerror'), nil, 'a function that errors asks nothing')
	local errors = take_errors()
	check(#errors == 1 and tostring(errors[1]):find('confirm broke', 1, true) ~= nil, 'and its error goes to the error handler')
	eq(confirm('method'), 'Asked about method', "a handler method's string")
	eq(confirm('none'), nil, 'no confirm asks nothing')
	eq(confirm('flag'), 'Flag', "confirm is inherited from the group")
	eq(confirm('value', 'x'), 'Pick x?', 'the new value is passed to a confirm function')
end)

------------------------------------------------------------------ search

test('Search: option names, section and tab titles, any case; hidden options and descriptions skipped; at most 100', function()
	local root = unitframes_root()
	root.Minimap = minimap_page()
	local results = OM.Search(root, 'SIZE')
	eq(paths(results), 'Minimap.general.size,Unitframes.player.health.text.size',
		'names, any case, by page; hidden, guiHidden and description rows skipped')
	local first, second = results[1], results[2]
	check(first.pageKey == 'Minimap' and first.name == 'Size' and first.tabName == 'General' and first.sectionTitle == nil,
		'a result has its page, name, tab and section')
	check(second.pageKey == 'Unitframes' and second.name == 'Font size' and second.tabName == 'Player > Health'
		and second.sectionTitle == 'Text', 'the tab name runs through the picker and the tab')
	eq(paths(OM.Search(root, 'position')), 'Minimap.general.position.point,Unitframes.player.general.position.point',
		"every row of a section whose title matches")
	eq(OM.Search(root, 'position')[1].sectionTitle, 'Position', 'with the section title')
	eq(paths(OM.Search(root, 'health')), 'Unitframes.player.health.enable,Unitframes.player.health.text.size',
		'every row under a tab whose name matches')
	eq(paths(OM.Search(root, 'target')), 'Unitframes.target.general.enable', 'and under a matching pick')
	eq(#OM.Search(root, 'secret'), 0, 'hidden options are not found')
	eq(#OM.Search(root, 'matters'), 0, 'descriptions are not searched')
	eq(#OM.Search(root, ''), 0, 'no text, no results')
	eq(#OM.Search(root, '   '), 0, 'nor only spaces')
	eq(#OM.Search(root, '(%'), 0, 'the text is plain, not a pattern')
	local many = {}
	for i = 1, 150 do many['opt' .. i] = opt('toggle', 'Option ' .. i, { order = i }) end
	eq(#OM.Search({ Many = group('Many', many) }, 'option'), 100, 'at most 100 results')
end)

------------------------------------------------------------------ the real tree

test('Experience on the real tree: the General page with its rows, then its Position option', function()
	local root = st.Config:GetOptionsTable()
	eq(keys(OM.Pages(root)), 'Fonts,Experience,profile', "the real tree's pages; topmenu left out")
	local view = OM.BuildView(root, 'Experience')
	eq(view.title, 'Experience', 'title')
	eq(keys(view.tabs), 'general', 'Position is in General, so General is the only tab')
	eq(view.tab, 'general', 'and selected')
	eq(layout(view), '-:theme,background,spacing,height,width,normal_color,rested_color,rest_alpha|Position:position',
		"General's rows, then the Position option in a section of its own")
	local config = st.config.profile.experience
	local width = row(view, 'width')
	eq(OM.Get(root, width), config.width, "General's get reads the profile")
	eq(OM.Set(root, width, 300), true, 'a set')
	eq(config.width, 300, "General's set writes the profile")
	eq(XP.container:GetWidth(), 300, 'and the bar updates')
	local pos = row(view, 'position')
	eq(pos.type, 'position', 'one Position row')
	eq(OM.Get(root, pos, 'point'), config.position.point, "Position's own get, the part first")
	eq(OM.Get(root, pos, 'x_off'), tonumber(config.position.x_off) or 0, 'an offset as a number')
	eq(OM.Set(root, pos, 'x_off', 12), true, 'a set, the part first')
	eq(config.position.x_off, 12, 'is stored as a number')
	local ok, err = OM.Set(root, pos, 'frame', 'NoSuchFrame')
	check(ok == false and err == "Frame doesn't exist", "a typed frame goes through its validate (st:ValidateAnchor)")
	local rested = st.config.profile.colors.experience.rested
	local r, g, b = OM.Get(root, row(view, 'rested_color'))
	check(r == rested.r and g == rested.g and b == rested.b, 'a color option reads r, g, b')
	OM.Set(root, row(view, 'rested_color'), 1, 0, 0)
	check(rested.r == 1 and rested.g == 0 and rested.b == 0, 'and sets them')
	local page, selection = OM.SelectionForPath(root, { 'Experience', 'general' })
	check(page == 'Experience' and selection.tab == 'general', "the bar's mover path opens General")
	local found = OM.Search(root, 'rested')
	eq(paths(found), 'Experience.general.rested_color,Experience.general.rest_alpha', 'search finds the rested options')
	eq(found[1].tabName, 'General', 'on the General tab')
	local fonts = OM.BuildView(root, 'Fonts')
	eq(fonts.title, 'Global Settings', 'the Fonts page is Global Settings')
	eq(fonts.tab, 'general', 'it opens on its General tab')
	fonts = OM.BuildView(root, 'Fonts', { tab = 'fonts' })
	check(#fonts.sections > 0 and fonts.sections[1].title ~= nil and row(fonts, 'font_size') ~= nil,
		'each font is a titled section of rows')
end)

test("the profiles table: AceDBOptions' real table on a real AceDB reads and sets through its handler", function()
	local root = st.Config:GetOptionsTable()
	local db = st.config
	local start = db:GetCurrentProfile()
	eq(start, 'Tester - Testrealm', "AceDB starts on the character's profile")
	local view = OM.BuildView(root, 'profile')
	eq(view.title, 'Profiles', 'title')
	eq(layout(view), '-:desc,descreset,reset,current,choosedesc,new,choose,copydesc,copyfrom,deldesc,delete',
		'every option is a row, in order')
	local choose = row(view, 'choose')
	eq(OM.Get(root, choose), start, "Existing Profiles reads the current profile (the handler's GetCurrentProfile)")
	check(row(view, 'current').name:find(start, 1, true) ~= nil, "the Current Profile line's name reads info.handler")
	local listed = OM.Values(root, choose)
	check(has_key(listed, 'Default') and has_key(listed, start), "its values (ListProfiles with arg 'common')")
	eq(row(view, 'copyfrom').disabled, true, "Copy From is disabled with no other profile (the handler's HasNoProfiles)")
	eq(OM.Get(root, row(view, 'new')), false, 'New reads false (get = false)')
	eq(OM.Confirm(root, row(view, 'delete')), 'Are you sure you want to delete the selected profile?', 'Delete confirms')
	eq(OM.Confirm(root, choose), nil, 'Existing Profiles does not')

	eq(OM.Set(root, choose, 'Default'), true, 'choosing a profile')
	eq(db:GetCurrentProfile(), 'Default', 'switches the real database')
	eq(OM.Get(root, choose), 'Default', 'and reads back')
	view = OM.BuildView(root, 'profile')
	local copyfrom = row(view, 'copyfrom')
	eq(copyfrom.disabled, false, 'with a second profile, Copy From is enabled')
	eq(keys(OM.Values(root, copyfrom)), start, "and lists the other profile (arg 'nocurrent')")

	eq(OM.Set(root, row(view, 'delete'), start), true, 'deleting a profile')
	local remaining = {}
	for _, name in ipairs(db:GetProfiles()) do remaining[name] = true end
	check(remaining.Default and not remaining[start], 'removes it from the database')
	eq(OM.Set(root, row(view, 'new'), 'Fresh'), true, 'a new profile')
	eq(db:GetCurrentProfile(), 'Fresh', 'is made and switched to')
	db.profile.experience.width = 999
	eq(OM.Set(root, row(view, 'reset')), true, "Reset Profile (an execute with func = 'Reset')")
	eq(db.profile.experience.width, st.defaults.experience.width, 'resets the real profile')
end)
