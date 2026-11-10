-- The /sui pages of Bags, Chat and Loot, which build their tables only after
-- OnEnable has made frames, so Config:GetOptionsTable can't get them here. Each
-- is built with stand-ins for those frames (SaftUI's own: the bag windows' anchors, the
-- chat holder, the loot roll anchor and feed; the module methods that need them are
-- counters, with a comment where Blizzard is what they would reach). Checked for each
-- page: every option has a desc and no Ace width, Position is the last option of its
-- General group, and the new options read and write their profile keys and apply them
-- the way the module reads them.
--
-- Real: the files of the pages (SaftUI-Bags/options.lua, SaftUI-Chat/options.lua,
-- SaftUI-Loot/options.lua), the modules' defaults, Core's generators and the options model.
load_core_helpers()
load_saftui('SaftUI-Bags/config.lua')
load_saftui('SaftUI-Chat/config.lua')
load_saftui('SaftUI-Loot/config.lua')
apply_defaults()
load_test_file('core/options_walk.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local st = SaftUI
local OM, OB = st.OptionsModel, st.OptionsBody
local profile = st.config.profile

local NO_DESC = { group = true, header = true, description = true }

local function info_for(key) return { key } end

-- Every option has a desc and no width; every Position is after all of its
-- siblings. Returns the number of Position options.
local function check_page(name, tree)
	check(tree ~= nil, name .. ' builds')
	local positions = 0
	local function siblings(group, where)
		for key, option in pairs(group.args) do
			if option.type == 'position' then
				positions = positions + 1
				for other, sibling in pairs(group.args) do
					if other ~= key then
						check((sibling.order or 100) < option.order, where .. ': Position is after ' .. other)
					end
				end
			end
		end
	end
	siblings(tree, name)
	each_option(tree, function(option, path)
		local where = name .. '.' .. table.concat(path, '.')
		check(option.width == nil, where .. ' has an Ace width')
		if not NO_DESC[option.type] then
			local desc = option.desc
			check((type(desc) == 'string' and desc ~= '') or type(desc) == 'function', where .. ' has no desc')
		end
		if option.type == 'group' then siblings(option, where) end
	end)
	return positions
end

-- 'key:size col[/quarter]' for the rows of a page's section, as LayoutRows places them.
local function layout(root, page, tab, section)
	local view = OM.BuildView(root, page, { tab = tab })
	local placed = OB.LayoutRows(view.sections[section or 1].rows)
	local got = {}
	for _, p in ipairs(placed) do
		got[#got + 1] = string.format('%s:%s %s%s', p.row.key, p.row.size or 'normal', tostring(p.col),
			p.quarter and ('/' .. p.quarter) or '')
	end
	return table.concat(got, ', '), view
end

test('Bags: the new settings read and write their profile keys and apply the way the bags read them', function()
	local INV = st:NewModule('Inventory')
	st:BindModuleConfig(INV, 'inventory')
	INV.windowIds = { 'bag', 'bank' }
	INV.windowLabels = { bag = 'Bags', bank = 'Bank' }
	INV.moverIds = { bag = true, bank = true }
	INV.containers = { bag = CreateFrame('Frame', nil, UIParent) } -- exists once the bags are enabled
	local calls = {}
	local function count(name) return function() calls[#calls + 1] = name end end
	-- The module's own methods, which lay out and restyle Blizzard's item buttons.
	INV.UpdateConfig = count('UpdateConfig')
	INV.ApplyButtonSize = count('ApplyButtonSize')
	INV.QueueUpdate = count('QueueUpdate')
	INV.SyncAnchorSize = count('SyncAnchorSize')
	INV.ApplyPosition = count('ApplyPosition')
	function INV:GetAnchor() return CreateFrame('Frame', nil, UIParent) end
	load_saftui('SaftUI-Bags/options.lua')

	local tree = INV:GetConfigTable()
	eq(check_page('Bags', tree), 2, 'a Position in the bag and in the bank window')
	local general, look = tree.args.general, tree.args.look
	local config = profile.inventory

	-- The eleven settings: where each lives, and that its option reads the profile.
	local where = {
		enable = general, template = look, padding = look, categoryTitleHeight = look, scrollSpeed = general,
		autorepair = general, autovendor = general, combinedBank = general, inverted = general,
	}
	for key, group in pairs(where) do
		local option = group.args[key]
		check(option ~= nil, key .. ' has an option')
		eq(option.get and option.get(info_for(key)) or group.get(info_for(key)), config[key], key .. ' reads inventory.' .. key)
	end
	for _, key in ipairs({ 'titles', 'icons' }) do
		local option = look.args[key]
		eq(option.type, 'select', key .. ' is a select')
		eq(option.get(), config.fonts[key], key .. ' reads inventory.fonts.' .. key)
		check(option.values[config.fonts[key]] ~= nil, "its value is one of the select's font object keys")
	end

	-- Setting each writes its profile key.
	local function set(group, key, value)
		calls = {}
		local option = group.args[key]
		if option.set then option.set(info_for(key), value) else group.set(info_for(key), value) end
		return table.concat(calls, ',')
	end
	eq(set(general, 'enable', false), '', 'Enable applies nothing live (it needs a reload)')
	eq(config.enable, false, 'Enable writes inventory.enable')
	config.enable = true
	check(general.args.enable.desc:find('reload'), 'and says so')
	eq(set(general, 'inverted', false), 'QueueUpdate', 'Inverted re-lays the bags out')
	eq(config.inverted, false, 'Inverted writes inventory.inverted')
	eq(set(general, 'scrollSpeed', 5), 'QueueUpdate', 'Scroll speed')
	eq(config.scrollSpeed, 5, 'Scroll speed writes inventory.scrollSpeed')
	set(general, 'autorepair', false)
	set(general, 'autovendor', false)
	eq(config.autorepair, false, 'Auto repair writes inventory.autorepair')
	eq(config.autovendor, false, 'Auto sell junk writes inventory.autovendor')
	eq(set(general, 'combinedBank', false), 'UpdateConfig', 'Combined bank registers the layout now in use')
	eq(config.combinedBank, false, 'Combined bank writes inventory.combinedBank')
	check(general.args.combinedBank.desc:find('next time you open the bank'), 'and says when it applies')
	eq(set(look, 'padding', 14), 'ApplyButtonSize', 'Padding restyles the windows and resizes their outlines')
	eq(config.padding, 14, 'Padding writes inventory.padding')
	set(look, 'categoryTitleHeight', 40)
	eq(config.categoryTitleHeight, 40, 'Category title height writes inventory.categoryTitleHeight')
	set(look, 'template', 'thick')
	eq(config.template, 'thick', 'Template writes inventory.template')
	eq(set(look, 'titles', 'pixel'), 'UpdateConfig', 'the title font restyles the windows')
	eq(config.fonts.titles, 'pixel', 'Title font writes inventory.fonts.titles')
	set(look, 'icons', 'normal')
	eq(config.fonts.icons, 'normal', 'Icon font writes inventory.fonts.icons')

	-- Toggles pair up in quarters; each window's General ends with Position.
	local root = { Inventory = tree }
	eq(layout(root, 'Inventory', nil, 1), 'enable:small 1/1, stackItems:small 1/2, inverted:small 2/1, combinedBank:small 2/2, '
		.. 'autorepair:small 1/1, autovendor:small 1/2, scrollSpeed:normal 2'
		, 'General: the toggles in pairs, then Scroll speed')
	local view = OM.BuildView(root, 'Inventory', { tab = 'bag' })
	eq(view.sections[#view.sections].title, 'Position', "the bag window's Position is its last section")
end)

test('Bags: turned off, the page is General with the Enable toggle alone', function()
	local INV = st:GetModule('Inventory')
	profile.inventory.enable = false
	local tree = INV:GetConfigTable()
	check_page('BagsOff', tree)
	local names = {}
	for key in pairs(tree.args) do names[#names + 1] = key end
	eq(table.concat(names, ','), 'general', 'only General')
	local args = tree.args.general.args
	eq(args.enable ~= nil and next(args, next(args)) == nil, true, 'with Enable alone, so it can be turned back on')
	eq(args.enable.get ~= nil or tree.args.general.get(info_for('enable')) == false, true, 'reading the off state')
	profile.inventory.enable = true
end)

test('Chat: every option has a desc; Line spacing is left out because nothing reads it', function()
	local CHT = st:NewModule('Chat')
	st:BindModuleConfig(CHT, 'chat')
	CHT.holder = CreateFrame('Frame', nil, UIParent)
	profile.chat.width, profile.chat.height = 400, 200
	-- Both reach ChatFrame1, Blizzard's.
	function CHT:ApplyHolder() end
	function CHT:CaptureSize() end
	function CHT:ApplyAppearance() end
	load_saftui('SaftUI-Chat/options.lua')
	local tree = CHT:GetConfigTable()
	eq(check_page('Chat', tree), 1, 'one Position')
	eq(tree.args.general.args.linespacing, nil, 'no Line spacing option (ChatFrame_OnUpdate is not hooked)')
	local got = layout({ Chat = tree }, 'Chat')
	eq(got, 'width:normal 1, height:normal 2, template:normal 1, font:normal 2, fontsize:normal 1, padding:normal 2, '
		.. 'editbox_height:normal 1, tabs_fade:normal 2', 'the settings in pairs')
end)

test('Loot: Test mode is small, every option has a desc, Position is last', function()
	load_saftui('SaftUI-Loot/init.lua')
	local LT = st:GetModule('Loot')
	st:BindModuleConfig(LT, 'loot')
	LT.rollAnchor = CreateFrame('Frame', nil, UIParent)
	LT.feed = CreateFrame('Frame', nil, UIParent)
	-- Both build Blizzard's group loot roll frames and the feed's lines.
	function LT:UpdateGroupLootConfig() end
	function LT:UpdateLootFeedConfig() end
	load_saftui('SaftUI-Loot/options.lua')
	local tree = LT:GetConfigTable()
	eq(check_page('Loot', tree), 2, 'a Position for Rolls and one for Feed')
	for _, key in ipairs({ 'roll', 'feed' }) do
		local test_mode = tree.args[key].args.general.args.test_mode
		eq(test_mode.size, 'small', key .. ': Test mode is small')
	end
	local got = layout({ Loot = tree }, 'Loot', 'roll')
	eq(got:match('^test_mode:small 1/1'), 'test_mode:small 1/1', 'Test mode takes a quarter')
end)
