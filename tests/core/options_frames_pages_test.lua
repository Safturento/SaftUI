-- The /sui pages of Bags, Chat, Loot and Action bars, which build their tables only after
-- OnEnable has made frames, so Config:GetOptionsTable can't get them here. Each
-- is built with stand-ins for those frames (SaftUI's own: the bag windows' anchors, the
-- chat holder, the loot roll anchor and feed, the action bars and extra buttons; the module methods that need them are
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
load_saftui('SaftUI-ActionBars/config.lua')
load_saftui('SaftUI-ActionBars/init.lua') -- the bar ids and labels
apply_defaults()
load_test_file('core/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')
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
	-- Nothing on it is a Template, Highlight or Close Button, or an old template name.
	T.check_no_old_names(tree, name)
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
	-- The views' order and words, which the View select lists; the switch is a counter.
	load_saftui('SaftUI-Bags/views.lua')
	INV.SetView = function(_, id, view) calls[#calls + 1] = 'SetView:' .. id .. ':' .. view end
	load_saftui('SaftUI-Bags/options.lua')

	local tree = INV:GetConfigTable()
	eq(check_page('Bags', tree), 2, 'a Position in the bag and in the bank window')
	local general, look = tree.args.general, tree.args.look
	local config = profile.inventory

	-- The settings: where each lives, and that its option reads the profile.
	local where = {
		enable = general, theme = look, background = look, buttontheme = look, buttonbackground = look,
		padding = look, categoryTitleHeight = look, scrollSpeed = general,
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
	eq(look.args.template, nil, 'no Template')
	for key, value in pairs({ theme = 'thin', background = 'solid', buttontheme = 'thin', buttonbackground = 'solid' }) do
		eq(set(look, key, value), 'ApplyButtonSize', key .. ' restyles the windows and slots')
		eq(config[key], value, key .. ' writes inventory.' .. key)
		config[key] = 'theme'
	end
	eq(set(look, 'titles', 'pixel'), 'UpdateConfig', 'the title font restyles the windows')
	eq(config.fonts.titles, 'pixel', 'Title font writes inventory.fonts.titles')
	set(look, 'icons', 'normal')
	eq(config.fonts.icons, 'normal', 'Icon font writes inventory.fonts.icons')

	-- Each window's View and Empty slots: the same keys in the bag and the bank.
	for _, id in ipairs({ 'bag', 'bank' }) do
		local window = tree.args[id].args.general
		eq(window.get(info_for('view')), 'compact', id .. ': View reads the default, Compact')
		eq(table.concat(window.args.view.sorting, ','), 'onebag,multibag,compact,rows', id .. ': View lists the views in order')
		eq(window.args.view.values.multibag, 'Multi bag', id .. ': in words')
		calls = {}
		window.args.view.set(info_for('view'), 'rows')
		eq(table.concat(calls, ','), 'SetView:' .. id .. ':rows', id .. ': View goes through INV:SetView')
		eq(window.get(info_for('emptySlots')), 'off', id .. ': Empty slots reads the default, off')
		calls = {}
		window.args.emptySlots.set(info_for('emptySlots'), 'all')
		eq(table.concat(calls, ','), 'QueueUpdate', id .. ': Empty slots lays the windows out again')
		eq(config[id].emptySlots, 'all', id .. ': and writes inventory.' .. id .. '.emptySlots')
		config[id].emptySlots = 'off'
	end

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
	eq(got, 'width:normal 1, height:normal 2, theme:normal 1, background:normal 2, font:normal 1, fontsize:normal 2, '
		.. 'padding:normal 1, editbox_height:normal 2, tabs_fade:normal 1', 'the settings in pairs')
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

test('Action bars: tooltips, Position last, the Theme and Background options, and the Text positions over the stored keys', function()
	local AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	AB.EXTRA_IDS = { 'extra', 'zone', 'vehicleleave' }
	AB.EXTRA_LABELS = { extra = 'Extra action button', zone = 'Zone ability', vehicleleave = 'Leave vehicle button' }
	AB.built = true
	AB.bars, AB.extras = {}, {}
	for _, id in ipairs(AB.BAR_IDS) do
		AB.bars[id] = { buttons = {} }
		for i = 1, (id == 'pet' or id == 'stance') and 10 or 12 do AB.bars[id].buttons[i] = {} end
	end
	for _, id in ipairs(AB.EXTRA_IDS) do AB.extras[id] = CreateFrame('Frame', nil, UIParent) end
	AB.barTypes = { pet = { texts = { hotkey = true } }, stance = { texts = { hotkey = true } } }
	-- The bars are secure and the skin restyles their buttons: counters here.
	local calls = {}
	local function count(name) return function(_, id) calls[#calls + 1] = name .. (id and (':' .. id) or '') end end
	AB.UpdateBar, AB.LayoutBar, AB.LayoutExtra, AB.UpdateConfig = count('UpdateBar'), count('LayoutBar'), count('LayoutExtra'), count('UpdateConfig')
	load_saftui('SaftUI-ActionBars/options.lua')

	local tree = AB:GetConfigTable()
	-- A Position in each bar's General, each extra's General and each text of the Text tabs.
	local texts = 8 * 3 + 2
	eq(check_page('ActionBars', tree), 10 + 3 + texts, 'a Position for every bar, extra button and text')
	eq(tree.pickerLabel, 'Bar', 'the picker is labelled Bar')
	eq(OM.BuildView({ ActionBars = tree }, 'ActionBars').picker.name, 'Bar', 'and the window shows it')
	local picked = {}
	for _, entry in ipairs(OM.BuildView({ ActionBars = tree }, 'ActionBars').picker.values) do picked[#picked + 1] = entry.key end
	eq(table.concat(picked, ','), 'bar1,bar2,bar3,bar4,bar5,bar6,bar7,bar8,pet,stance,extra,zone,vehicleleave',
		'the picker lists the bars and extras, not the Theme and Background options')

	-- Theme and Background read and write actionbars.theme and .background, and
	-- restyle every bar at once.
	eq(tree.args.template, nil, 'no Template')
	for key, name in pairs({ theme = 'Theme', background = 'Background' }) do
		local option = tree.args[key]
		eq(option.type, 'select', name .. ' is a select')
		eq(option.name, name, name .. ' is named so')
		eq(option.get(), profile.actionbars[key], name .. ' reads actionbars.' .. key)
		calls = {}
		option.set(info_for(key), key == 'theme' and 'thin' or 'solid')
		eq(profile.actionbars[key], key == 'theme' and 'thin' or 'solid', name .. ' writes actionbars.' .. key)
		eq(table.concat(calls, ','), 'UpdateConfig', 'and re-skins the bars and extras')
		profile.actionbars[key] = 'theme'
	end
	check(tree.args.theme.values.thin ~= nil and tree.args.theme.values.thicktransparent == nil,
		'Theme offers the themes, not the old template names')
	check(tree.args.theme.order < tree.args.background.order, 'Theme, then Background')

	-- Each bar: Position last in General; the Text tab has the hotkey, count and macro (the
	-- pet and stance bars only the hotkey), each a Position block with no target over the
	-- text's stored keys.
	for _, id in ipairs(AB.BAR_IDS) do
		local bar = tree.args[id]
		eq(bar.childGroups, 'tab', id .. ' declares its own tabs')
		local want = (id == 'pet' or id == 'stance') and 'hotkey' or 'count,hotkey,macro'
		local kinds = {}
		for kind in pairs(bar.args.text.args) do kinds[#kinds + 1] = kind end
		table.sort(kinds)
		eq(table.concat(kinds, ','), want, id .. ' text tab')
		for kind, group in pairs(bar.args.text.args) do
			local option = group.args.position
			eq(option.type, 'position', id .. ' ' .. kind .. ' is a Position block')
			eq(option.target, nil, id .. ' ' .. kind .. ' has no TO part')
			check(group.args.show.size == 'small', id .. ' ' .. kind .. ': Show is small')
			for _, part in ipairs({ 'point', 'rel_point', 'x_off', 'y_off' }) do
				local stored = profile.actionbars[id].text[kind][part]
				eq(option.get(info_for('position'), part), part:find('_off') and (tonumber(stored) or 0) or stored,
					id .. ' ' .. kind .. ' reads text.' .. kind .. '.' .. part)
			end
			-- No 50 limit: the stored offset can be set past it.
			calls = {}
			option.set(info_for('position'), 'x_off', 120)
			option.set(info_for('position'), 'point', 'CENTER')
			eq(profile.actionbars[id].text[kind].x_off, 120, id .. ' ' .. kind .. ' writes text.' .. kind .. '.x_off')
			eq(profile.actionbars[id].text[kind].point, 'CENTER', id .. ' ' .. kind .. ' writes text.' .. kind .. '.point')
			eq(table.concat(calls, ','), 'UpdateBar:' .. id .. ',UpdateBar:' .. id, 'each change applies through UpdateBar')
			eq(group.args.size.max, 32, 'Size keeps its range')
		end
	end
	local view = OM.BuildView({ ActionBars = tree }, 'ActionBars', { pick = 'bar1', tab = 'general' })
	eq(view.sections[#view.sections].title, 'Position', "General ends with the Position section")
end)
