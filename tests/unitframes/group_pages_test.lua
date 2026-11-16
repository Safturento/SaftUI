-- The group pages: Party, Raid 10, Raid 40 and Boss in /sui, on the part-row pages (Task 3 built the
-- pages, config/groupoptions.lua adds the groups' own sections). General reads Frame, Position, Layout,
-- Range (not on boss), Parts; Ready check is a part of the groups only; Layout, Range and Test mode keep
-- their resets; the raid groups' Enable keeps its words about Blizzard's raid frames; and the safety rule
-- of the work: building, drawing and opening the group pages writes no saved setting.
--
-- Real: config_test.lua's world (page_world.lua), as parts_test.lua loads it. Stand-in: UF:UpdateConfig,
-- which counts its calls. The previews (grouppreview.lua) are in group_preview_test.lua.
local PW = load_test_file('unitframes/page_world.lua').world()
local st, UF, OM, OW, W = PW.st, PW.UF, PW.OM, PW.OW, PW.W
load_editmode()
local OB = st.OptionsBody

local GROUPS = { 'party', 'raid10', 'raid40', 'boss' }
local RAIDS = { 'party', 'raid10', 'raid40' }

local function tree() return { Unitframes = UF:GetConfigTable() } end

local function view_of(root, unit, tab, subtab)
	return OM.BuildView(root, 'Unitframes', { pick = unit, tab = tab, subtab = subtab })
end

local function titles(view)
	local out = {}
	for i, section in ipairs(view.sections) do out[i] = section.title or '-' end
	return table.concat(out, '|')
end

local function section_of(view, title)
	for _, section in ipairs(view.sections) do
		if section.title == title then return section end
	end
end

local function keys_of(section)
	local out = {}
	for i, row in ipairs(section.rows) do out[i] = row.key end
	return table.concat(out, ',')
end

local function general_of(root, unit) return root.Unitframes.args[unit].args.general end

local function row_for(root, unit, ...)
	local path, option = { 'Unitframes', unit, 'general' }, general_of(root, unit)
	for _, key in ipairs({ ... }) do
		path[#path + 1] = key
		option = option.args[key]
	end
	return { path = path, option = option, type = option.type, key = path[#path] }
end

------------------------------------------------------------------ the order

test("a group's General reads Frame, Position, Layout, Range, Parts; boss has no Range", function()
	local root = tree()
	for _, unit in ipairs(RAIDS) do
		eq(titles(view_of(root, unit)), 'Frame|Position|Layout|Range|Parts', unit)
	end
	eq(titles(view_of(root, 'boss')), 'Frame|Position|Layout|Parts', 'boss: no Range')
	-- By their order values too: the sections are not left to sort by luck.
	for _, unit in ipairs(GROUPS) do
		local args = general_of(root, unit).args
		eq(args.frame.order, 1, unit .. ': Frame first')
		eq(args.position.order, 2, unit .. ': Position second')
		eq(args.layout.order, 6, unit .. ': Layout')
		eq(args.parts.order, 2000, unit .. ': Parts last')
		if unit == 'boss' then
			eq(args.range_alpha, nil, 'boss: no Range')
		else
			eq(args.range_alpha.order, 500, unit .. ': Range between Layout and Parts')
		end
	end
	-- Frame's rows, and Range's.
	eq(keys_of(section_of(view_of(root, 'party'), 'Frame')), 'enable,theme,background,width,height', "Frame's rows")
	eq(keys_of(section_of(view_of(root, 'party'), 'Range')), 'inside,outside', "Range's rows")
end)

test("a group's General has no tab but its own five, and the same Position as every unit's", function()
	local root = tree()
	for _, unit in ipairs(GROUPS) do
		local tabs = {}
		for i, tab in ipairs(view_of(root, unit).tabs) do tabs[i] = tab.key end
		eq(table.concat(tabs, ','), 'general,Health,Power,Castbar,Auras', unit .. ': the five tabs')
		eq(general_of(root, unit).args.position.type, 'position', unit .. ": General's Position is the frame's")
	end
end)

test('Ready check is a part on the groups only', function()
	local root = tree()
	for _, unit in ipairs(RAIDS) do
		local item = general_of(root, unit).args.parts.args.readycheck
		check(item ~= nil, unit .. ': Ready check is a part')
		if item then eq(item.name, 'Ready check', unit .. ': by that name') end
	end
	eq(general_of(root, 'boss').args.parts.args.readycheck, nil, 'boss has no Ready check')
	for _, unit in ipairs({ 'player', 'target', 'focus', 'pet' }) do
		eq(general_of(root, unit).args.parts.args.readycheck, nil, unit .. ': no Ready check on a single unit')
	end
end)

------------------------------------------------------------------ the groups' own rows

test("Layout, Range and Test mode keep their own resets; Test mode its noReset", function()
	local root = tree()
	for _, unit in ipairs(GROUPS) do
		local layout = general_of(root, unit).args.layout
		check(layout.args.test_mode.noReset and layout.args.test_mode.noReset ~= '', unit .. ': Test mode says why it has no reset')
		eq(OM.DefaultSource(root, row_for(root, unit, 'layout', 'test_mode')), 'none', unit .. ": Test mode's source is its stated noReset")
		for key, option in pairs(layout.args) do
			if key ~= 'test_mode' then
				local source = OM.DefaultSource(root, row_for(root, unit, 'layout', key))
				check(source ~= nil and source ~= 'none', unit .. ' Layout ' .. key .. ': has a reset source (' .. tostring(source) .. ')')
				check(option.noReset == nil, unit .. ' Layout ' .. key .. ': no noReset')
			end
		end
		if unit ~= 'boss' then
			for _, key in ipairs({ 'inside', 'outside' }) do
				local source = OM.DefaultSource(root, row_for(root, unit, 'range_alpha', key))
				check(source ~= nil and source ~= 'none', unit .. ' Range ' .. key .. ': has a reset source (' .. tostring(source) .. ')')
			end
		end
	end
	-- A changed value shows its reset, and the reset puts the default back and writes nothing else.
	local config = UF:GetProfileConfig()
	local row = row_for(root, 'party', 'layout', 'spacing')
	local default = config.party.spacing
	OM.Set(root, row, default + 3)
	eq(config.party.spacing, default + 3, 'Spacing written at its saved place')
	eq(OM.DefaultDiffers(root, row), true, 'and it differs')
	check(OM.DefaultReset(root, row), 'its reset runs')
	eq(config.party.spacing, default, 'back at the default')
	local out = row_for(root, 'raid40', 'range_alpha', 'outside')
	local was = config.raid40.range_alpha.outside
	OM.Set(root, out, 0.25)
	eq(config.raid40.range_alpha.outside, 0.25, 'Range written at its saved place')
	check(OM.DefaultReset(root, out), 'its reset runs')
	eq(config.raid40.range_alpha.outside, was, 'back at the default')
end)

test("the raid groups' Enable keeps its words about Blizzard's raid frames; Party's has none", function()
	local root = tree()
	for _, unit in ipairs({ 'raid10', 'raid40' }) do
		local enable = general_of(root, unit).args.frame.args.enable
		check(enable.desc:find("Blizzard's raid frames are hidden", 1, true) ~= nil, unit .. ': the Enable desc')
		check(enable.desc:find('Turning both raid groups off', 1, true) ~= nil, unit .. ': and what turning both off does')
	end
	local party = general_of(root, 'party').args.frame.args.enable
	check(not (party.desc or ''):find('raid frames', 1, true), "Party's Enable says nothing of the raid frames")
end)

------------------------------------------------------------------ the safety rule

local function raw_copy(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	local key, each = next(value)
	while key ~= nil do
		copy[key] = raw_copy(each)
		key, each = next(value, key)
	end
	return copy
end

local function first_difference(a, b, where)
	if type(a) ~= type(b) then return where .. ': a ' .. type(a) .. ' became a ' .. type(b) end
	if type(a) ~= 'table' then
		if a ~= b and not (a ~= a and b ~= b) then return ('%s: %s became %s'):format(where, tostring(a), tostring(b)) end
		return nil
	end
	for key, each in pairs(a) do
		local found = first_difference(each, b[key], where .. '.' .. tostring(key))
		if found then return found end
	end
	for key in pairs(b) do
		if a[key] == nil then return where .. '.' .. tostring(key) .. ' was made' end
	end
end

local function draw_general(root, unit)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 900)
	local body = OB.New(content, root, nil, 774)
	body:Draw(view_of(root, unit).sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by
end

-- Every group page built, every tab and sub tab viewed, General drawn, every part's menu opened, the
-- dots' counts read, and search run.
local function every_group_page_and_menu(root)
	for _, unit in ipairs(GROUPS) do
		local page = view_of(root, unit)
		for _, tab in ipairs(page.tabs) do
			local view = view_of(root, unit, tab.key)
			for _, sub in ipairs(view.subtabs) do view_of(root, unit, tab.key, sub.key) end
		end
		local body, by = draw_general(root, unit)
		for _, cell in pairs(by) do
			if cell.widget and cell.widget.isPart then
				cell.widget:OpenMenu()
				OW:CloseMenu()
			end
			if cell.row.type == 'item' then OM.MenuOffers(root, cell.row) end
		end
		body:Release()
	end
	OM.Search(root, 'spacing')
	OM.Search(root, 'ready')
end

test('S1: building, drawing and opening every group page writes no saved setting, on a fresh profile and a customized one', function()
	local function check_profile(label)
		local before = raw_copy(st.config.profile.unitframes)
		every_group_page_and_menu(tree())
		local found = first_difference(before, raw_copy(st.config.profile.unitframes), 'unitframes')
		eq(found, nil, label .. ': the saved data as it was: ' .. tostring(found))
		every_group_page_and_menu(tree())
		found = first_difference(before, raw_copy(st.config.profile.unitframes), 'unitframes')
		eq(found, nil, label .. ': and again: ' .. tostring(found))
	end
	check_profile('fresh')
	local config = UF:GetProfileConfig()
	config.party.name.font = 'pixel'
	config.party.name.showLevel = true
	config.party.spacing, config.party.showPlayer = 9, true
	config.raid10.range_alpha.outside = 0.2
	config.raid40.unitsPerColumn, config.raid40.maxColumns = 8, 3
	config.raid40.readycheckindicator.enable = false
	config.boss.growthDirection, config.boss.spacing = 'LEFT', 30
	config.boss.name.position = { point = 'TOP', rel_point = 'BOTTOM', frame = 'NotThere', x_off = '4', y_off = 0 }
	config.raid10.health.text.position = { point = 'LEFT', rel_point = 'LEFT', x_off = '5', y_off = '-2' }
	check_profile('customized')
end)

test('S3: a group part row\'s box set in combat only writes and calls UF:UpdateConfig, which queues', function()
	local root = tree()
	local item = general_of(root, 'party').args.parts.args.readycheck
	local row = { path = { 'Unitframes', 'party', 'general', 'parts', 'readycheck' }, option = item, type = 'item', key = 'readycheck' }
	local config = UF:GetProfileConfig().party.readycheckindicator
	local was = config.enable
	stub.in_combat = true
	local n = PW.updates
	OM.Set(root, row, not was)
	stub.in_combat = false
	eq(config.enable, not was, 'written where the element saves it')
	eq(PW.updates, n + 1, 'and UF:UpdateConfig called once')
	config.enable = was
end)
