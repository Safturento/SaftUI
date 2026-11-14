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
local function world(on)
	local st, TR = TW.world({ on = on })
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
	eq(enable.default.value(), false, 'its default')
	local orders = { quests = 2, items = 3, visibility = 4, blizzard = 5 }
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
	local tree = TR:GetConfigTable()
	local values = 0
	each_option(tree, function(option, path)
		local where = table.concat(path, '.')
		if not NO_DESC[option.type] then
			check(type(option.desc) == 'string' and option.desc ~= '', where .. ' has a desc')
		end
		check(option.width == nil, where .. ' has no Ace width')
		check(not (option.type == 'execute' and tostring(option.name):find('Reset')), where .. ' is no Reset button')
		if VALUE_TYPES[option.type] then
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
	-- A table default: reset writes a copy, never the default itself.
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
