-- The reset walk (tests/lib/reset_walk.lua) checks what it says it checks: a
-- value row with no reset source fails, a stated one passes, a `saved` that
-- names another setting's key fails the round trip, and a default that differs
-- at start fails. Synthetic pages, on the window's world and optionsdefault.lua.
load_test_file('core/options_window_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsdefault.lua')
local OM = st.OptionsModel
local R = load_test_file('lib/reset_walk.lua')

local function world(profile)
	st.defaults.t_ = { a = true, b = true, n = 5, name = 'Hello' }
	st.config.profile.t_ = profile or { a = true, b = true, n = 5, name = 'Hello' }
end

local function group(extra)
	local g = {
		type = 'group', name = 'Box', order = 1,
		get = function(info) return st.config.profile.t_[info[#info]] end,
		set = function(info, value) st.config.profile.t_[info[#info]] = value end,
	}
	for key, value in pairs(extra) do g[key] = value end
	return g
end

local function page(box) return { Page = { type = 'group', name = 'Page', args = { box = box } } } end

local function has(problems, text)
	for _, problem in ipairs(problems) do
		if problem:find(text, 1, true) then return true end
	end
	return false
end

test('the check is real: a value row with no source fails, and a stated one passes', function()
	world()
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		args = {
			a = { type = 'toggle', name = 'Saved', order = 1 },
			n = { type = 'range', name = 'A number', order = 2, min = 0, max = 10, step = 1 },
			name = { type = 'input', name = 'Name', order = 3 },
			go = { type = 'execute', name = 'Go', order = 4, func = function() end },
			words = { type = 'description', name = 'Words', order = 5 },
		},
	}))
	local problems, walked = R.problems(root, 'Page')
	eq(#problems, 0, 'a page whose group says where it is saved passes: ' .. table.concat(problems, '; '))
	eq(walked, 3, 'three value rows walked (an execute and a description are none)')
	local ok = pcall(R.check_page, root, 'Page')
	check(ok, 'check_page passes it')

	root = page(group({
		args = {
			bare = { type = 'toggle', name = 'Bare', order = 1 },
			empty = { type = 'toggle', name = 'Empty', order = 2, noReset = '' },
			said = { type = 'toggle', name = 'Said', order = 3, noReset = 'session only' },
		},
	}))
	problems = R.problems(root, 'Page')
	eq(#problems, 2, 'a bare row and an empty noReset fail, a stated one passes: ' .. table.concat(problems, '; '))
	check(has(problems, 'Page.box.bare (toggle Bare) has no reset:'), 'the failure names the page, path, type and name')
	check(has(problems, 'Page.box.empty (toggle Empty) has an empty noReset'), 'and an empty noReset says so')
	check(not has(problems, 'Page.box.said'), 'a stated noReset passes')
end)

test('a saved that names another key fails the round trip', function()
	world()
	local root = page(group({
		saved = function() return 't_', 'b' end, -- the group reads and writes t_.a
		args = { a = { type = 'toggle', name = 'Wrong key', order = 1 } },
	}))
	local problems = R.problems(root, 'Page')
	check(has(problems, 'Page.box.a (toggle Wrong key)'), 'the problem names the row')
	check(has(problems, 'the probe changed the profile outside its saved path (t_.b): t_.a'), 'and says what it changed: ' .. table.concat(problems, '; '))
end)

test('a fresh profile shows no icon; a row whose default differs at start fails', function()
	world({ a = true, b = true, n = 5, name = 'Hello' })
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		args = { a = { type = 'toggle', name = 'On', order = 1 } },
	}))
	eq(#R.problems(root, 'Page'), 0, 'a fresh profile: no row differs')
	world({ a = false, b = true, n = 5, name = 'Hello' })
	local problems = R.problems(root, 'Page')
	check(has(problems, 'Page.box.a (toggle On) differs on a fresh profile'), 'a row that differs at start fails: ' .. table.concat(problems, '; '))
	problems = R.problems(root, 'Page', { fresh = false })
	eq(#problems, 0, 'unless the walk is told the profile is not fresh')
end)

test('a row with no default in st.defaults, and a hidden or disabled row, are not probed', function()
	world()
	st.config.profile.t_.extra = true
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		args = {
			extra = { type = 'toggle', name = 'No default', order = 1 },
			a = { type = 'toggle', name = 'Hidden', order = 2, hidden = true },
			b = { type = 'toggle', name = 'Disabled', order = 3, disabled = true },
		},
	}))
	local problems = R.problems(root, 'Page')
	eq(#problems, 1, 'only the row with no default fails: ' .. table.concat(problems, '; '))
	check(has(problems, 'no default in st.defaults at t_.extra'), 'it says where it looked')
	st.config.profile.t_.a, st.config.profile.t_.b = false, false
	eq(#R.problems(root, 'Page', { skip = { ['Page.box.extra'] = true } }), 0, 'hidden and disabled rows are never asked whether they differ; skip leaves a row out')
end)

test('a probe set that errors is a problem naming the row', function()
	world()
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		set = function(info, value) error('boom') end,
		args = { a = { type = 'toggle', name = 'Breaks', order = 1 } },
	}))
	local problems = R.problems(root, 'Page')
	check(has(problems, 'Page.box.a (toggle Breaks)'), 'the row is named: ' .. table.concat(problems, '; '))
end)

test('items, menus and picker controls are walked; the probe values reach every type', function()
	world()
	st.defaults.t_.multi = { x = true, y = false }
	st.defaults.t_.key = ''
	st.defaults.t_.color = { r = 0.9, g = 0.1, b = 0.1, a = 1 }
	st.defaults.t_.choice = 'one'
	st.defaults.t_.font = 'normal'
	local p = st.config.profile.t_
	p.multi, p.key, p.color, p.choice, p.font = { x = true, y = false }, '', { r = 0.9, g = 0.1, b = 0.1, a = 1 }, 'one', 'normal'
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		args = {
			choice = { type = 'select', name = 'Choice', order = 1, values = { one = 'One', two = 'Two' } },
			key = { type = 'keybinding', name = 'Key', order = 2 },
			font = { type = 'font', name = 'Font', order = 3 },
			multi = { type = 'multiselect', name = 'Many', order = 4, values = { x = 'X', y = 'Y' },
				get = function(_, key) return st.config.profile.t_.multi[key] end,
				set = function(_, key, value) st.config.profile.t_.multi[key] = value end,
				saved = st.Config.SavedAt('t_', 'multi') },
			color = { type = 'color', name = 'Color', order = 5, hasAlpha = true,
				get = function() local c = st.config.profile.t_.color; return c.r, c.g, c.b, c.a end,
				set = function(_, r, g, b, a) st.config.profile.t_.color = { r = r, g = g, b = b, a = a } end,
				saved = st.Config.SavedAt('t_', 'color') },
			item = { type = 'item', name = 'Item', order = 6,
				get = function() return st.config.profile.t_.a end,
				set = function(_, value) st.config.profile.t_.a = value end,
				saved = st.Config.SavedAt('t_', 'a'),
				menu = { type = 'group', name = 'Item', get = function(info) return st.config.profile.t_[info[#info]] end,
					set = function(info, value) st.config.profile.t_[info[#info]] = value end,
					saved = st.Config.SavedIn('t_'),
					args = { n = { type = 'range', name = 'Size', order = 1, min = 0, max = 10, step = 1 },
						bare = { type = 'toggle', name = 'No source here', order = 2, get = function() return true end } } } },
		},
	}))
	root.Page.pickerControl = { type = 'group', name = 'Control', args = {
		pick = { type = 'select', name = 'Profile', order = 1, values = { a = 'A' }, get = function() return 'a' end } } }
	local problems, walked = R.problems(root, 'Page')
	eq(#problems, 2, 'two problems: the menu row with no source, the picker control with none: ' .. table.concat(problems, '; '))
	check(has(problems, 'Page.box.item.menu.bare (toggle No source here) has no reset'), "an item's menu rows are walked")
	check(has(problems, 'pickerControl') or has(problems, 'Profile'), 'and a pick control (a select with a get of its own and no source)')
	check(walked >= 8, 'every value row was walked: ' .. walked)
	eq(p.multi.x, true, 'the multiselect is put back as it was')
	eq(p.color.r, 0.9, 'and the color')
	eq(p.choice, 'one', 'and the select')
end)

test('allow: a known side effect of a set is let through, and only that one', function()
	world()
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		set = function(info, value)
			st.config.profile.t_[info[#info]] = value
			st.config.profile.side_ = (st.config.profile.side_ or 0) + 1 -- a set that also marks something else
		end,
		args = { a = { type = 'toggle', name = 'Marks', order = 1 } },
	}))
	local problems = R.problems(root, 'Page')
	check(has(problems, 'outside its saved path'), 'without an allow it fails: ' .. table.concat(problems, '; '))
	problems = R.problems(root, 'Page', { allow = { ['Page.box.a'] = { 'side_' } } })
	check(not has(problems, 'outside its saved path'), 'with the key allowed for that row it passes: ' .. table.concat(problems, '; '))
	root.Page.args.box.args.b = { type = 'toggle', name = 'Same side effect', order = 2 }
	problems = R.problems(root, 'Page', { allow = { ['Page.box.a'] = { 'side_' } } })
	check(has(problems, 'Page.box.b (toggle Same side effect)'), 'another row is not let through')
	problems = R.problems(root, 'Page', { allow = { ['Page.box.a'] = { 'other_' } } })
	check(has(problems, 'Page.box.a (toggle Marks)'), 'a different key is not the one allowed')
end)

test('a reset that leaves the profile changed beyond the row is a problem', function()
	world()
	local root = page(group({
		saved = st.Config.SavedIn('t_'),
		set = function(info, value)
			st.config.profile.t_[info[#info]] = value
			if value == st.defaults.t_[info[#info]] then st.config.profile.t_.stray = true end -- only a reset writes it
		end,
		args = { a = { type = 'toggle', name = 'Strays', order = 1 } },
	}))
	local problems = R.problems(root, 'Page')
	check(has(problems, 'Page.box.a (toggle Strays)') and has(problems, 'after its reset'),
		'the stray key is found after the reset: ' .. table.concat(problems, '; '))
end)

local function uf_row()
	load_saftui('SaftUI-Unitframes/config/position.lua')
	local unitframe = CreateFrame('Frame', 'WalkUnitFrame', UIParent)
	unitframe.Health = CreateFrame('Frame', nil, unitframe)
	unitframe.elements = { Health = true }
	local part = CreateFrame('Frame', nil, unitframe)
	part.unitframe = unitframe
	local cfg = { position = { point = 'TOP', rel_point = 'TOP', element = false, frame = false, x_off = 0, y_off = 0 } }
	st.defaults.pw_ = { position = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 0 } }
	local parts = {}
	local option = st.Config.generators.uf_element_position(1, function(k) return cfg.position[k] end,
		function(k, v) parts[#parts + 1] = k; cfg.position[k] = v end, part)
	option.saved = st.Config.SavedAt('pw_', 'position')
	return page(option), cfg, parts, option
end

test('the probe of a unit frame part\'s Position moves its point and its anchor, not only x_off, and its reset is all or none', function()
	world()
	local root, cfg, parts = uf_row()
	local problems = R.problems(root, 'Page')
	eq(#problems, 0, 'a working Position passes: ' .. table.concat(problems, '; '))
	local seen = {}
	for _, part in ipairs(parts) do seen[part] = true end
	check(seen.point and seen.x_off, 'the probe changed the point and x_off')
	check(seen.element or seen.frame, 'and the anchor (' .. table.concat(parts, ',') .. ')')
end)

test('a unit frame part whose anchor can\'t be put back fails the walk', function()
	world()
	local root, cfg, parts, option = uf_row()
	local set = option.set
	-- A set that quietly ignores the anchor, as the bug did.
	option.set = function(info, part, value)
		if part == 'relative_to' or part == 'element' or part == 'frame' then return end
		return set(info, part, value)
	end
	local problems = R.problems(root, 'Page')
	check(#problems > 0, 'the walk finds it: ' .. table.concat(problems, '; '))
end)
