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
load_test_file('lib/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsdefault.lua')
assert(SaftUI.OptionsModel.DefaultSource, 'derived defaults are on the options model')
load_saftui('SaftUI-Core/Config/optionsdefault.lua') -- after the model, as the TOC has it
load_saftui('SaftUI-Core/Config/optionsdefault.lua')
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
	INV.ApplyFonts = function(_, which) calls[#calls + 1] = 'ApplyFonts:' .. which end
	function INV:GetAnchor() return CreateFrame('Frame', nil, UIParent) end
	-- The views' order and words, which the View select lists; the switch is a counter.
	-- views.lua takes INV.IndexOf at load; inventory.lua's, copied here as that file can't load
	-- (its NewModule would clash with the stub).
	function INV.IndexOf(list, value)
		for i, v in ipairs(list or {}) do
			if v == value then return i end
		end
	end
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
		eq(option.type, 'font', key .. ' is a font row')
		eq(option.get(), config.fonts[key], key .. ' reads inventory.fonts.' .. key)
		check(st:IsSharedFont(config.fonts[key]), "its value is a shared font's key")
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
	eq(set(look, 'titles', 'pixel'), 'ApplyFonts:titles', "the title font restyles the titles' texts, never the layout (bags/font_drag_test.lua)")
	eq(config.fonts.titles, 'pixel', 'Title font writes inventory.fonts.titles')
	eq(set(look, 'icons', 'normal'), 'ApplyFonts:icons', "the icon font restyles the slots' texts")
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
		eq(set(window, 'emptySlots', 'all'), 'UpdateConfig,SyncAnchorSize',
			id .. ": Empty slots goes through the window's General set, which re-packs every window (UpdateConfig)")
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

	-- The Categories tab, after the windows: one wide row, the tab widget, with a desc.
	local categories = tree.args.categories
	check(categories ~= nil and categories.type == 'group', 'a Categories tab')
	eq(categories.name, 'Categories', 'named Categories')
	check(categories.order > tree.args.bag.order and categories.order > tree.args.bank.order, 'after the windows')
	view = OM.BuildView(root, 'Inventory', { tab = 'categories' })
	eq(view.tabs[#view.tabs].key, 'categories', 'the last tab')
	eq(#view.sections, 1, 'one section')
	eq(#view.sections[1].rows, 1, 'of one row')
	local row = view.sections[1].rows[1]
	eq(row.key .. ':' .. row.type .. ':' .. row.size, 'categories:bagcategories:wide', 'the tab widget, wide')
	eq(row.name, 'Categories', 'named Categories')
	check(type(row.desc) == 'string' and row.desc ~= '', 'with a desc')
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

test('Chat: every option has a desc; Line spacing is left out because nothing reads it; Font size is gone, the font row has the size in its dots', function()
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
	eq(got, 'width:normal 1, height:normal 2, theme:normal 1, background:normal 2, font:normal 1, padding:normal 2, '
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

test("Action bars: tooltips, Position last on each bar and extra, Theme and Background on All bars, and the texts' Position blocks over the stored keys", function()
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
	AB.barTypes = { pet = { texts = { hotkey = true, countdown = true } }, stance = { texts = { hotkey = true, countdown = true } } }
	-- The bars are secure and the skin restyles their buttons: counters here.
	local calls = {}
	local function count(name) return function(_, id) calls[#calls + 1] = name .. (id and (':' .. id) or '') end end
	AB.UpdateBar, AB.UpdateBars, AB.LayoutBar = count('UpdateBar'), count('UpdateBars'), count('LayoutBar')
	AB.LayoutExtra, AB.UpdateConfig = count('LayoutExtra'), count('UpdateConfig')
	load_saftui('SaftUI-ActionBars/shared.lua')
	AB.COUNTDOWN_CVAR = 'countdownForCooldowns' -- skin.lua's, which this world stands in for
	load_saftui('SaftUI-ActionBars/textoptions.lua')
	load_saftui('SaftUI-ActionBars/options.lua')
	AB:ConvertProfile() -- the world the game reaches: a converted profile
	-- All bars' places differ from what any bar stores, so a bar that follows
	-- can only show All bars'.
	for _, kind in ipairs(AB.TEXT_KINDS) do AB:SetSetting('all', kind .. '.position', 3, 'x_off') end

	local tree = AB:GetConfigTable()
	-- A Position on each bar and each extra button, and in each text's menu:
	-- All bars' four, each bar's four, the pet and stance bars' two.
	local texts = 9 * 4 + 2 * 2
	eq(check_page('ActionBars', tree), 10 + 3 + texts, 'a Position for every bar, extra button and text')
	eq(tree.pickerLabel, 'Bar', 'the picker is labelled Bar')
	eq(OM.BuildView({ ActionBars = tree }, 'ActionBars').picker.name, 'Bar', 'and the window shows it')
	local picked = {}
	for _, entry in ipairs(OM.BuildView({ ActionBars = tree }, 'ActionBars').picker.values) do picked[#picked + 1] = entry.key end
	eq(table.concat(picked, ','), 'all,bar1,bar2,bar3,bar4,bar5,bar6,bar7,bar8,pet,stance,extra,zone,vehicleleave',
		'the picker lists All bars, the bars and the extras, and nothing is above it')
	for key, option in pairs(tree.args) do eq(option.type, 'group', key .. ' is a pick') end

	-- Theme and Background, in All bars' Look, read and write actionbars.theme
	-- and .background, and restyle every bar at once.
	local look = tree.args.all.args.look.args
	eq(look.template, nil, 'no Template')
	for key, name in pairs({ theme = 'Theme', background = 'Background' }) do
		local option = look[key]
		eq(option.type, 'select', name .. ' is a select')
		eq(option.name, name, name .. ' is named so')
		eq(option.get(), profile.actionbars[key], name .. ' reads actionbars.' .. key)
		calls = {}
		option.set(info_for(key), key == 'theme' and 'thin' or 'solid')
		eq(profile.actionbars[key], key == 'theme' and 'thin' or 'solid', name .. ' writes actionbars.' .. key)
		eq(table.concat(calls, ','), 'UpdateConfig', 'and re-skins the bars and extras')
		profile.actionbars[key] = 'theme'
	end
	check(look.theme.values.thin ~= nil and look.theme.values.thicktransparent == nil,
		'Theme offers the themes, not the old template names')
	check(look.theme.order < look.background.order, 'Theme, then Background')

	-- All bars and each bar: one page, no tabs; the Text section has the hotkey,
	-- count, macro and cooldown numbers (the pet and stance bars only the hotkey
	-- and the numbers), each a small item whose menu ends with a Position block
	-- named Position with no target, over the text's stored keys. The numbers
	-- share no Show.
	-- All bars last: its sets would move every bar that follows it.
	local pages = {}
	for _, id in ipairs(AB.BAR_IDS) do pages[#pages + 1] = id end
	pages[#pages + 1] = 'all'
	for _, id in ipairs(pages) do
		local page = tree.args[id]
		eq(page.childGroups, nil, id .. ' is one page, no tabs')
		local want = (id == 'pet' or id == 'stance') and 'countdown,hotkey' or 'count,countdown,hotkey,macro'
		local kinds = {}
		for kind in pairs(page.args.text.args) do kinds[#kinds + 1] = kind end
		table.sort(kinds)
		eq(table.concat(kinds, ','), want, id .. ' text section')
		local store = id == 'all' and profile.actionbars.all or profile.actionbars[id]
		for kind, item in pairs(page.args.text.args) do
			local where = id .. ' ' .. kind
			eq(item.type .. ' ' .. item.size, 'item small', where .. ' is a small item')
			local option = item.menu.args.position
			eq(option.type, 'position', where .. ' is a Position block')
			eq(option.target, nil, where .. ' has no TO part')
			eq(option.name, 'Position', where .. "'s block is named Position (the menu's title names the text)")
			if kind == 'countdown' then
				eq(item.share, nil, where .. ': no shared Show')
			else
				check(item.share ~= nil, where .. ': its Show is shared')
			end
			local at = { 'menu', 'position' }
			for _, part in ipairs({ 'point', 'rel_point', 'x_off', 'y_off' }) do
				local shown = AB:GetSetting(id, kind .. '.position', part)
				eq(option.get(at, part), part:find('_off') and (tonumber(shown) or 0) or shown,
					where .. ' reads the effective ' .. part)
			end
			if id ~= 'all' and not AB:IsOwn(id, kind .. '.position') then
				eq(option.get(at, 'x_off'), 3, where .. ' follows All bars')
			end
			-- No 50 limit: the stored offset can be set past it.
			calls = {}
			option.set(at, 'x_off', 120)
			option.set(at, 'point', 'CENTER')
			eq(store.text[kind].x_off, 120, where .. ' writes text.' .. kind .. '.x_off')
			eq(store.text[kind].point, 'CENTER', where .. ' writes text.' .. kind .. '.point')
			local update = id == 'all' and 'UpdateBars' or 'UpdateBar:' .. id
			eq(table.concat(calls, ','), update .. ',' .. update, 'each change applies through ' .. update)
			eq(item.menu.args.size.max, 32, 'Size keeps its range')
		end
	end

	-- Position last on each bar and each extra button.
	for _, id in ipairs({ 'bar1', 'pet', 'extra', 'zone', 'vehicleleave' }) do
		local view = OM.BuildView({ ActionBars = tree }, 'ActionBars', { pick = id })
		eq(view.sections[#view.sections].title, 'Position', id .. ' ends with the Position section')
	end
end)
