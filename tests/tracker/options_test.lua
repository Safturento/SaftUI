-- SaftUI-Tracker's page in /sui, as far as it exists (each later task's rows
-- pass through these checks):
--   - Tracker under Info, its tabs in order, General first with the switch,
--     every other tab disabled while the tracker is off;
--   - every option has a desc and no Ace width; every value option has a
--     default that resets it to st.defaults.tracker (differs, reset, value),
--     and there is no Reset button;
--   - the tree passes AceConfigRegistry-3.0's validator.
--
-- Real: SaftUI-Tracker's files, Core's helpers and edit mode (tracker_world.lua),
-- the options kit's model and dialog, and AceConfigRegistry-3.0's validator
-- (its library loaded as core/config_helpers.lua loads it; not that world's
-- AceDB, which is made before a later addon's defaults could join it).
local TW = load_test_file('tracker/tracker_world.lua')

local VALUE_TYPES = { toggle = true, range = true, select = true, color = true, input = true, multiselect = true }
local NO_DESC = { group = true, description = true, header = true }

-- A fresh world with the real Config on top of the tracker's.
local function world(on, client)
	local st, TR = TW.world({ on = on, client = client })
	load_test_file('lib/options_walk.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	return st, TR
end

test('the page: Tracker under Info, its tabs in order, General first with the switch, the others disabled while off', function()
	local st, TR = world(false)
	local page = TR:GetConfigTable()
	eq(page.name, 'Tracker', 'the name')
	eq(page.category, 'Info', 'under Info')
	eq(page.type, 'group')
	eq(page.childGroups, 'tab', 'tabs')
	eq(page.args.general.order, 1, 'General first')
	eq(page.args.general.name, 'General')
	local enable = page.args.general.args.enable
	eq(enable.type, 'toggle')
	eq(enable.name, "SaftUI's tracker")
	eq(enable.desc, "Draws your quests in SaftUI's own tracker, grouped by zone, in place of Blizzard's objective tracker. Changes after a reload.")
	eq(enable.default.value(), true, 'its default: on')
	local orders = { quests = 2, colors = 2.5, items = 3, visibility = 4, blizzard = 5 }
	local seen = 0
	for key, tab in pairs(page.args) do
		if key ~= 'general' and key ~= 'tracked_by' then
			seen = seen + 1
			eq(tab.order, orders[key], key .. "'s order")
			eq(tab.disabled(), true, key .. ' is disabled while off')
			eq(tab.disabledDesc(), "Turn on SaftUI's tracker (General) and reload.", key .. "'s disabledDesc")
		end
	end
	local tab = TR.Tab(2, 'Quests', {})
	eq(tab.disabled(), true, 'a tab is disabled while off')
	local _, TR2 = world(true)
	eq(TR2.Tab(2, 'Quests', {}).disabled(), false, 'and not while on')
	eq(#take_errors(), 0, 'no errors')
end)

test('every option has a desc and no width; every value option has a default that resets it to st.defaults.tracker', function()
	local st, TR = world(false)
	st.config.profile.tracker.enable = true -- the shipped default: the walk starts from every option at its default (this session's switch is still off)
	local tree = TR:GetConfigTable()
	local values = 0
	each_option(tree, function(option, path)
		local where = table.concat(path, '.')
		if not NO_DESC[option.type] then
			-- A desc may be a function (Left click's follows P5), read as the page does.
			local desc = type(option.desc) == 'function' and option.desc() or option.desc
			check(type(desc) == 'string' and desc ~= '', where .. ' has a desc')
		end
		check(option.width == nil, where .. ' has no Ace width')
		check(not (option.type == 'execute' and tostring(option.name):find('Reset')), where .. ' is no Reset button')
		-- The Colors tab's rows follow a color until one is picked, with a hand
		-- default of their own (colors_test.lua).
		if VALUE_TYPES[option.type] and path[1] ~= 'colors' then
			values = values + 1
			check(type(option.default) == 'table', where .. ' has a default')
			local key = path[#path]
			-- General's keys sit under no group; any other tab is the group, however
			-- deep the option is nested in it.
			local group = path[1] ~= 'general' and path[1] or nil
			local default = st.defaults.tracker
			if group then default = default[group] end
			eq(option.default.value(), default[key], where .. ' default value')
			eq(option.default.differs(), false, where .. ' does not differ at first')
			local setting = group and TR.config[group] or TR.config
			local other = default[key] == false and true or default[key] == true and false or nil
			if other ~= nil then
				setting[key] = other
				eq(option.default.differs(), true, where .. ' differs once changed')
				option.default.reset()
				eq(setting[key], default[key], where .. ' reset to the default')
				eq(option.default.differs(), false, where .. ' no longer differs')
			end
		end
	end)
	check(values >= 1, 'at least the switch')
	eq(#take_errors(), 0, 'no errors')
end)

test('SettingDefault: General keys and groups, a copy on reset', function()
	local st, TR = world(false)
	local cases = {
		{ nil, 'width', 300 }, { 'quests', 'spacing', 20 }, { 'items', 'size', 40 },
		{ 'visibility', 'fade_alpha', 0.9 }, { 'blizzard', 'mode', 'beside' }, { 'quests', 'level', not st.forever },
	}
	for _, case in ipairs(cases) do
		local group, key, value = case[1], case[2], case[3]
		local where = tostring(group) .. '.' .. key
		local default = TR.SettingDefault(group, key)
		local config = group and TR.config[group] or TR.config
		local shipped = group and st.defaults.tracker[group][key] or st.defaults.tracker[key]
		eq(default.value(), shipped, where .. ' value')
		eq(default.differs(), false, where .. ' starts equal')
		config[key] = value
		eq(default.differs(), true, where .. ' differs')
		default.reset()
		eq(config[key], shipped, where .. ' reset')
		eq(default.differs(), false, where .. ' equal again')
	end
	-- A table default: reset writes a copy, never the default itself (the nearest
	-- button's Position row takes its mover's reset, below, but SettingDefault stays).
	local position = TR.SettingDefault('items', 'nearest_position')
	TR.config.items.nearest_position.x_off = 5
	eq(position.differs(), true, 'a changed position differs')
	position.reset()
	eq(TR.config.items.nearest_position.x_off, st.defaults.tracker.items.nearest_position.x_off, 'reset')
	check(TR.config.items.nearest_position ~= st.defaults.tracker.items.nearest_position, 'a copy')
	TR.config.items.nearest_position.x_off = 7
	eq(st.defaults.tracker.items.nearest_position.x_off, -320, 'the default is untouched')
	eq(#take_errors(), 0, 'no errors')
end)

test("the tree passes AceConfigRegistry's validator", function()
	for _, standing in ipairs({ false, true }) do
		local _, TR = TW.world({ on = true, addons = standing and { 'KaLiQuest' } or nil })
		load_test_file('lib/options_walk.lua')
		load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
		load_saftui('SaftUI-Core/Libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua')
		load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
		local Registry = LibStub('AceConfigRegistry-3.0')
		local tree = TR:GetConfigTable()
		check((tree.args.tracked_by ~= nil) == standing, 'the line shows only while standing down')
		local ok, err = pcall(Registry.ValidateOptionsTable, Registry,
			ace_ready({ type = 'group', name = 'SaftUI', args = { Tracker = tree } }), 'SaftUI')
		check(ok, (standing and 'standing down' or 'normal') .. ': the page is valid: ' .. tostring(err))
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('the Quests tab: every setting, in order, saving into tracker.quests and drawing the rows again', function()
	local st, TR = world(true)
	local tab = TR:GetConfigTable().args.quests
	eq(tab.name, 'Quests', 'the name')
	eq(tab.order, 2, 'second')
	eq(tab.disabled(), false, 'on while the tracker is on')
	local order = {}
	for key, option in pairs(tab.args) do order[#order + 1] = { key, option.order } end
	table.sort(order, function(a, b) return a[2] < b[2] end)
	local keys = {}
	for i, entry in ipairs(order) do keys[i] = entry[1] end
	eq(table.concat(keys, ' '),
		'show zones current_first order finished_first level tags difficulty icons hide_finished finished_objectives bars timers waypoint tooltips left_click spacing colors',
		'the settings of the design, then the description row')
	eq(tab.args.tooltips.type, 'toggle', 'Tooltips is a toggle')
	eq(tab.args.left_click.type, 'select', 'Left click is a select')
	eq(tab.args.left_click.values().map .. '|' .. tab.args.left_click.values().focus, 'Show on map|Focus', 'Show on map or Focus')
	eq(tab.args.left_click.get(), 'map', 'Show on map by default')
	TR.SHOW_ON_MAP = false
	check(tab.args.left_click.values().map == nil, 'Focus only once Show on map is not allowed')
	eq(tab.args.left_click.get(), 'focus', 'and the saved map reads as focus')
	local default = tab.args.left_click.default
	check(not default.differs(), 'no reset icon: the saved map reads as focus, which is its default as it acts here')
	eq(default.value(), 'focus', 'its default as it acts')
	check(tab.args.left_click.desc():find('focuses the quest', 1, true) and not tab.args.left_click.desc():find('opens the quest on the map', 1, true), 'its desc stops describing Show on map')
	TR.SHOW_ON_MAP = true
	eq(default.value(), 'map', 'and Show on map when allowed')
	check(tab.args.left_click.desc():find('opens the quest on the map', 1, true), 'with its desc')
	eq(tab.args.show.values.tracked, 'Tracked quests', 'Show: tracked quests')
	eq(tab.args.show.values.zone, "Tracked and the current zone's", "or the current zone's")
	eq(tab.args.order.values.game, "The game's order", 'Order: the game\'s')
	eq(tab.args.order.values.log, 'Quest log order', 'the log\'s')
	eq(tab.args.order.values.level, 'Level', 'or level')
	eq(tab.args.spacing.min .. ' ' .. tab.args.spacing.max, '0 20', 'Spacing 0 to 20')
	eq(tab.args.colors.type, 'description', 'the last row is a description')
	eq(tab.args.colors.name, 'Finished and failed objectives take Global settings > Colors > Objectives.', 'its words')
	check(not tab.args.current_first.disabled(), 'Current zone first is enabled with Group by zone on...')
	TR.config.quests.zones = false
	check(tab.args.current_first.disabled(), '... and disabled with it off')
	TR.config.quests.zones = true

	-- A set saves and draws again: Level shows in the titles at once.
	stub.real_zone_text = 'A'
	local Q = load_test_file('tracker/quest_log.lua')
	Q.set({ Q.header('A'), Q.quest(1, { level = 12 }) }, { 1 })
	stub.run_timers()
	TR:Refresh()
	local row = TR:GetQuestRow(1)
	local before = row.title:GetText()
	tab.set({ 'quests', 'level' }, not TR.config.quests.level)
	check(row.title:GetText() ~= before, 'the title changed at once: ' .. tostring(before) .. ' -> ' .. tostring(row.title:GetText()))
	tab.set({ 'quests', 'spacing' }, 3)
	eq(TR.config.quests.spacing, 3, 'saved')
	eq(tab.get({ 'quests', 'spacing' }), 3, 'and read back')
	eq(#take_errors(), 0, 'no errors')
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test('every value row of the Tracker page has a reset, on ' .. client, function()
		local st, TR = world(true, client)
		local R = load_test_file('lib/reset_walk.lua')
		R.check_page({ Tracker = TR:GetConfigTable() }, 'Tracker')
		eq(#take_errors(), 0, 'no errors')
	end)
end

test("both of the tracker's Positions reset through their movers from the /sui row, and Undo takes each back", function()
	local st, TR = world(true)
	local EM, OM = st.EditModeFrames, st.OptionsModel
	local root = { Tracker = TR:GetConfigTable() }
	for _, case in ipairs({
		{ key = 'tracker', tab = 'general', get = function() return TR.config.position end },
		{ key = 'trackernearest', tab = 'items', get = function() return TR.config.items.nearest_position end },
	}) do
		local mover = EM.movers[case.key]
		check(mover, case.key .. ': the mover is registered')
		local row = { option = root.Tracker.args[case.tab].args[case.key == 'tracker' and 'position' or 'nearest_position'],
			path = { 'Tracker', case.tab, case.key == 'tracker' and 'position' or 'nearest_position' }, type = 'position',
			key = 'position' }
		eq(OM.DefaultSource(root, row), 'mover', case.key .. ": the row's reset is its mover's")
		local default = EM:GetDefaultPosition(mover)
		eq(OM.DefaultDiffers(root, row), false, case.key .. ': at its default spot nothing differs')

		-- A drag, as the mover records it.
		local before = EM.SavedPosition(mover)
		local moved = EM.SavedPosition(mover)
		moved.x_off, moved.y_off = -100, -50
		mover.def.setPosition(moved)
		mover.def.apply()
		EM:RecordMove(mover, 'move', before)
		eq(OM.DefaultDiffers(root, row), true, case.key .. ': a moved one differs')

		check(OM.DefaultReset(root, row), case.key .. ': the row resets')
		local now = case.get()
		eq(now.x_off .. ',' .. now.y_off, default.x_off .. ',' .. default.y_off, case.key .. ': to its default spot')
		eq(OM.DefaultDiffers(root, row), false, case.key .. ': nothing left to reset')

		EM.History:Undo()
		now = case.get()
		eq(now.x_off .. ',' .. now.y_off, '-100,-50', case.key .. ': Undo takes the reset back')
		EM.History:Undo()
	end
	eq(#take_errors(), 0, 'no errors')
end)
