-- The Enemy nameplates and Friendly nameplates pages in /sui
-- (SaftUI-Unitframes/config/config.lua):
--   - the two pages follow Raid 40 in the unit picker, Enemy first; neither
--     has Copy from, and no unit's Copy from offers either;
--   - the Friendly page's General has Friendly plates (the game's friendly
--     plates, nameplate.friendly), its box, Theme, Background, Width and
--     Height, and its element tabs are a plate's but Threat;
--   - each page's box ("Use enemy nameplates' settings" on the Friendly page,
--     "Use friendly nameplates' settings" on the Enemy page) hides the rest
--     of its page while it's checked, but the on/off switches and, on the
--     Enemy page, threat; a line under it says where the look comes from;
--   - while one box is checked the other page's is disabled, with a line
--     saying the other kind uses that page;
--   - unchecking brings the settings back as they were, and the tab chosen
--     before the box was checked, which the window's stored selection kept
--     while the box hid it;
--   - a box re-applies the plates (UF:UpdateConfig for a plate key) and their
--     size (UF:ApplyPlateSize). That a shown plate's base_unit follows is
--     Task 4's end-to-end test (ruling P1): it needs the plates' code;
--   - another nameplate addon: both pages say which, and everything on them
--     is disabled.
--
-- The world is nameplate_page_test.lua's: nameplate_world.lua's (see its top),
-- which has the real config/config.lua and every unit's defaults, with SaftUI's
-- options window, model and widgets loaded, so the pages are read through
-- UF:GetConfigTable() and st.OptionsModel as the window reads them.
local NP = load_test_file('unitframes/nameplate_world.lua')

local PLAYERS, NPCS = 'nameplateShowFriendlyPlayers', 'nameplateShowFriendlyNpcs'
-- Each page's tabs, in the order the window shows them: a plate's element
-- tabs (Subtext after Name), and Threat on the Enemy page only.
local ENEMY_TABS = 'general,Health,Threat,Name,Subtext,Castbar,Buffs,Debuffs,RaidTargetIndicator,QuestIndicator'
local FRIENDLY_TABS = 'general,Health,Name,Subtext,Castbar,Buffs,Debuffs,RaidTargetIndicator,QuestIndicator'
local ENEMY_BOX, FRIENDLY_BOX = "Use friendly nameplates' settings", "Use enemy nameplates' settings"
local ENEMY_USES_FRIENDLY = "Enemy nameplates use the Friendly nameplates page's settings, all but threat, which stays on this page."
local FRIENDLY_USES_ENEMY = "Friendly nameplates use the Enemy nameplates page's settings. They never show threat."
local FRIENDLY_USES_THIS = "Friendly nameplates use this page's settings. To check this box, uncheck Use enemy nameplates' settings on the Friendly nameplates page."
local ENEMY_USES_THIS = "Enemy nameplates use this page's settings, all but threat. To check this box, uncheck Use friendly nameplates' settings on the Enemy nameplates page."

local function world(client)
	local st, UF = NP.world(client or 'forever')
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_saftui('SaftUI-Core/Config/optionswindow.lua')
	load_test_file('core/options_walk.lua')
	st.config.char = {}
	ReloadUI = function() end
	return st, UF
end

-- The unit frames' page as the window builds it, picked on pick (General,
-- unless tab says otherwise), and the root it was read from. A pick that
-- isn't there would open the first unit instead, so that's an error.
local function page(UF, pick, tab)
	local root = { Unitframes = UF:GetConfigTable() }
	local view = SaftUI.OptionsModel.BuildView(root, 'Unitframes', { pick = pick, tab = tab or 'general' })
	assert(view.picker.selected == pick, 'no ' .. pick .. ' page')
	return root, view
end

-- The unit frames' page as the window builds it from its stored selection
-- (the pick and the tab last clicked), which building it never changes.
local function view_of(UF, selection)
	return SaftUI.OptionsModel.BuildView({ Unitframes = UF:GetConfigTable() }, 'Unitframes', selection)
end

-- The view's rows, in the order the window draws them.
local function rows(view)
	local out = {}
	for _, section in ipairs(view.sections) do
		for _, row in ipairs(section.rows) do out[#out + 1] = row end
	end
	return out
end

local function keys(view)
	local out = {}
	for i, row in ipairs(rows(view)) do out[i] = row.key end
	return table.concat(out, ',')
end

local function row_for(view, key)
	for _, row in ipairs(rows(view)) do
		if row.key == key then return row end
	end
end

local function tabs(view)
	local out = {}
	for i, tab in ipairs(view.tabs) do out[i] = tab.key end
	return table.concat(out, ',')
end

-- Sets key on pick's tab (General unless tab says) as the window does (the
-- row's set, inherited where it has none of its own). Returns what OM.Set does.
local function set(UF, pick, key, value, tab)
	local root, view = page(UF, pick, tab)
	local row = row_for(view, key)
	assert(row, 'no row ' .. key .. ' on ' .. pick .. ' ' .. (tab or 'general'))
	return SaftUI.OptionsModel.Set(root, row, value)
end

-- What key's row on pick's tab shows, read as the window reads it.
local function get(UF, pick, key, tab)
	local root, view = page(UF, pick, tab)
	local row = row_for(view, key)
	assert(row, 'no row ' .. key .. ' on ' .. pick .. ' ' .. (tab or 'general'))
	return SaftUI.OptionsModel.Get(root, row)
end

------------------------------------------------------------------ the two pages

test('the two pages: Enemy nameplates then Friendly nameplates after Raid 40, with no Copy from, and neither offered in Copy from', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		-- Two units for the picker to put them after.
		UF.units.player = CreateFrame('Frame', nil, UIParent)
		UF.groups = { raid40 = CreateFrame('Frame', nil, UIParent) }
		UF.holders.raid40 = CreateFrame('Frame', nil, UIParent)

		local root, view = page(UF, 'nameplate')
		local picked, names = {}, {}
		for i, entry in ipairs(view.picker.values) do picked[i], names[i] = entry.key, entry.name end
		eq(table.concat(picked, ','), 'player,raid40,nameplate,friendlynameplate,profile', client .. ': Enemy, then Friendly, after Raid 40')
		eq(names[3], 'Enemy nameplates', client .. ': the Enemy page')
		eq(names[4], 'Friendly nameplates', client .. ': the Friendly page')

		local args = root.Unitframes.args
		eq(args.nameplate.args.copy, nil, client .. ': no Copy from on the Enemy page')
		eq(args.friendlynameplate.args.copy, nil, client .. ': nor on the Friendly page')
		check(args.player.args.copy ~= nil, client .. ": the player's keeps it")

		-- What another unit's Copy from offers (the dialog's own table).
		local dialog
		local real = st.OptionsWindow.OpenDialog
		st.OptionsWindow.OpenDialog = function(_, _, options) dialog = options end
		UF:OpenCopyTable('player')
		st.OptionsWindow.OpenDialog = real
		local offered = dialog.args.copy_from.values()
		check(offered.target ~= nil, client .. ': target is offered')
		check(UF:GetProfileConfig().friendlynameplate ~= nil, client .. ': the profile has the friendly plates')
		eq(offered.nameplate, nil, client .. ': the enemy plates are not')
		eq(offered.friendlynameplate, nil, client .. ': nor the friendly plates')

		-- AceConfigRegistry takes it, SaftUI's fields aside.
		local ok, err = pcall(LibStub('AceConfigRegistry-3.0').ValidateOptionsTable, LibStub('AceConfigRegistry-3.0'),
			ace_ready({ name = st.name, type = 'group', args = root }), st.name)
		check(ok, client .. ': valid: ' .. tostring(err))
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('the Enemy page: Nameplates, Threat when solo, its box, Theme, Background, Width and Height; Friendly plates is on the Friendly page', function()
	local st, UF = world('forever')
	local root, view = page(UF, 'nameplate')
	eq(keys(view), 'enable,threat_solo,use_friendly,theme,background,width,height', 'in order, no line with no box checked')
	local general = root.Unitframes.args.nameplate.args.general.args
	eq(general.use_friendly.name, ENEMY_BOX, "the box's name")
	eq(general.use_friendly.desc, "Draws enemy and neutral nameplates with the Friendly nameplates page's settings, and hides this page's other settings, which are kept for when it's unchecked. Threat when solo and the Threat tab stay, and still apply.", "the box's desc")
	eq(general.width.desc, "Enemy nameplates' width: the health bar and the area you click. The game stacks every nameplate at this size.", "Width's desc")
	eq(general.height.desc, "Enemy nameplates' height: the health bar and the area you click. The game stacks every nameplate at this size.", "Height's desc")
	check(general.theme.desc:find('enemy nameplate', 1, true) ~= nil, "Theme says it's the enemy plates': " .. general.theme.desc)
	eq(general.friendly, nil, 'no Friendly plates')
	eq(row_for(view, 'use_friendly').disabled, false, 'the box is enabled')
	eq(tabs(view), ENEMY_TABS, 'its tabs, Threat among them')
	eq(get(UF, 'nameplate', 'use_friendly'), false, 'the box reads nameplate.use_friendly')
end)

test("the Friendly page: Friendly plates, its box, Theme, Background, Width and Height, and a plate's element tabs but Threat", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local root, view = page(UF, 'friendlynameplate')
		local config = root.Unitframes.args.friendlynameplate
		local general = config.args.general.args
		eq(keys(view), 'friendly,use_enemy,theme,background,width,height', client .. ': in order, no line with no box checked')
		for key, name in pairs({ friendly = 'Friendly plates', use_enemy = FRIENDLY_BOX, theme = 'Theme',
				background = 'Background', width = 'Width', height = 'Height' }) do
			eq(general[key].name, name, client .. ': ' .. key .. ' is ' .. name)
		end
		eq(general.friendly.desc, "Shows nameplates over friendly players and NPCs: SaftUI's outside instances, Blizzard's inside them. Off, friendly units have none.", client .. ": Friendly plates' desc")
		eq(general.use_enemy.desc, "Draws friendly nameplates with the Enemy nameplates page's settings, and hides this page's other settings, which are kept for when it's unchecked. Friendly nameplates never show threat.", client .. ": the box's desc")
		eq(general.width.desc, "Friendly nameplates' width, centred on the plate: the area you click. While enemy nameplates use this page, the game stacks every nameplate at this size.", client .. ": Width's desc")
		eq(general.height.desc, "Friendly nameplates' height, centred on the plate: the area you click. While enemy nameplates use this page, the game stacks every nameplate at this size.", client .. ": Height's desc")
		check(general.theme.desc:find('friendly nameplate', 1, true) ~= nil, client .. ": Theme says it's the friendly plates': " .. general.theme.desc)
		eq(general.background.order, general.theme.order + 0.5, client .. ': Background right after Theme')
		for _, row in ipairs(rows(view)) do
			check(not row.disabled, client .. ': ' .. row.key .. ' is enabled')
		end

		-- The game places each plate: no Position, Layout or Range.
		eq(general.position, nil, client .. ': no Position')
		eq(general.layout, nil, client .. ': no Layout')
		eq(general.range_alpha, nil, client .. ': no Range')
		eq(general.enable, nil, client .. ': no Nameplates (the Enemy page has it)')
		eq(general.threat_solo, nil, client .. ': no Threat when solo')
		eq(tabs(view), FRIENDLY_TABS, client .. ': the element tabs but Threat')

		-- The tabs read and write the friendly config.
		eq(get(UF, 'friendlynameplate', 'enable', 'Health'), false, client .. ": Health reads the friendly config's")
		eq(get(UF, 'nameplate', 'enable', 'Health'), true, client .. ": the Enemy page's reads the enemy one")
		eq(get(UF, 'friendlynameplate', 'use_enemy'), false, client .. ': the box reads friendlynameplate.use_enemy')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("the Friendly page's settings are the friendly config's, and re-apply the plates", function()
	local st, UF = world('forever')
	UF:SpawnNameplates()
	local P = UF:GetProfileConfig()
	local applied = {}
	local real = UF.UpdateConfig
	UF.UpdateConfig = function(self, unit, element)
		applied[#applied + 1] = tostring(unit) .. (element and ('.' .. element) or '')
		return real(self, unit, element)
	end
	check(set(UF, 'friendlynameplate', 'theme', 'thin'), 'Theme set')
	eq(P.friendlynameplate.theme, 'thin', 'saved on the friendly config')
	check(set(UF, 'friendlynameplate', 'width', '180'), 'Width set')
	eq(P.friendlynameplate.width, 180, 'saved as a number')
	eq(P.nameplate.width, 200, "the enemy plates' untouched")
	check(set(UF, 'friendlynameplate', 'enable', true, 'Health'), 'Health on')
	eq(P.friendlynameplate.health.enable, true, 'saved on the friendly config')
	eq(P.nameplate.health.enable, true, "the enemy plates' as they were")
	eq(table.concat(applied, ','), 'friendlynameplate,friendlynameplate,friendlynameplate.Health', 'each re-applies the friendly plates')
	UF.UpdateConfig = real
	eq(#take_errors(), 0, 'no error')
end)

test("Friendly plates reads and writes nameplate.friendly and sets the game's friendly plates", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		UF:SpawnNameplates()
		UF:ApplyNameplateCVars()
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': on with Friendly plates on')
		eq(get(UF, 'friendlynameplate', 'friendly'), true, client .. ': reads nameplate.friendly')

		check(set(UF, 'friendlynameplate', 'friendly', false), client .. ': Friendly plates off')
		eq(UF:GetProfileConfig().nameplate.friendly, false, client .. ': saved on nameplate')
		eq(rawget(UF:GetProfileConfig().friendlynameplate, 'friendly'), nil, client .. ': not on the friendly config')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', client .. ': both off')
		eq(get(UF, 'friendlynameplate', 'friendly'), false, client .. ': read back')
		check(set(UF, 'friendlynameplate', 'friendly', true), client .. ': Friendly plates on')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': both on')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the boxes

test('checking a box hides the page: all but the switches, and threat on the Enemy page', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)

		-- The Friendly page's box.
		check(set(UF, 'friendlynameplate', 'use_enemy', true), client .. ': the Friendly box checked')
		eq(UF:GetProfileConfig().friendlynameplate.use_enemy, true, client .. ': saved')
		local root, view = page(UF, 'friendlynameplate')
		eq(keys(view), 'friendly,use_enemy,box_note', client .. ': only Friendly plates, the box and its line')
		eq(row_for(view, 'box_note').type, 'description', client .. ': a description')
		eq(row_for(view, 'box_note').name, FRIENDLY_USES_ENEMY, client .. ': it says where the look comes from')
		eq(tabs(view), 'general', client .. ': every element tab hidden')
		root, view = page(UF, 'friendlynameplate', 'Health')
		eq(view.tab, 'general', client .. ': a hidden tab opens General')
		-- The window's stored selection, which only a click changes: the tab
		-- chosen before the box was checked.
		local chosen = { pick = 'friendlynameplate', tab = 'Health' }
		eq(view_of(UF, chosen).tab, 'general', client .. ': the chosen tab hidden: General')
		-- Nor are the hidden settings found by the search.
		for _, result in ipairs(SaftUI.OptionsModel.Search(root, 'Max width')) do
			check(result.path[2] ~= 'friendlynameplate', client .. ': no hidden setting found: ' .. table.concat(result.path, '.'))
		end
		check(#SaftUI.OptionsModel.Search(root, 'Max width') > 0, client .. ": other units' still are")

		-- The Enemy page shows everything, its box disabled.
		root, view = page(UF, 'nameplate')
		eq(keys(view), 'enable,threat_solo,use_friendly,box_note,theme,background,width,height', client .. ': the Enemy page whole')
		eq(tabs(view), ENEMY_TABS, client .. ': and its tabs')
		check(set(UF, 'friendlynameplate', 'use_enemy', false), client .. ': unchecked')
		eq(view_of(UF, chosen).tab, 'Health', client .. ': unchecked: the tab chosen before opens again')
		eq(chosen.tab, 'Health', client .. ': the stored selection kept')

		-- The Enemy page's box.
		check(set(UF, 'nameplate', 'use_friendly', true), client .. ': the Enemy box checked')
		eq(UF:GetProfileConfig().nameplate.use_friendly, true, client .. ': saved')
		root, view = page(UF, 'nameplate')
		eq(keys(view), 'enable,threat_solo,use_friendly,box_note', client .. ': Nameplates, Threat when solo, the box and its line')
		eq(row_for(view, 'box_note').name, ENEMY_USES_FRIENDLY, client .. ': it says all but threat comes from the Friendly page')
		eq(tabs(view), 'general,Threat', client .. ': the Threat tab stays')
		root, view = page(UF, 'nameplate', 'Threat')
		eq(view.tab, 'Threat', client .. ': and opens')
		local enemyChosen = { pick = 'nameplate', tab = 'Castbar' }
		eq(view_of(UF, enemyChosen).tab, 'general', client .. ': the chosen Castbar tab hidden: General')
		eq(keys(view), 'enable,font,alpha,position', client .. ': with its settings')
		for _, row in ipairs(rows(view)) do
			check(not row.disabled, client .. ': Threat ' .. row.key .. ' is enabled')
		end

		-- The Friendly page shows everything, its box disabled.
		root, view = page(UF, 'friendlynameplate')
		eq(keys(view), 'friendly,use_enemy,box_note,theme,background,width,height', client .. ': the Friendly page whole')
		eq(tabs(view), FRIENDLY_TABS, client .. ': and its tabs')
		check(set(UF, 'nameplate', 'use_friendly', false), client .. ': the Enemy box unchecked')
		eq(view_of(UF, enemyChosen).tab, 'Castbar', client .. ': unchecked: the Castbar tab chosen before opens again')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("one box at a time: the other page's box is disabled, with a line saying the other kind uses that page", function()
	local st, UF = world('forever')
	check(set(UF, 'friendlynameplate', 'use_enemy', true), 'the Friendly box checked')
	local root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, true, "the Enemy page's box is disabled")
	eq(row_for(view, 'box_note').name, FRIENDLY_USES_THIS, 'its line says friendly plates use this page')
	eq(row_for(view, 'box_note').disabled, false, 'at full strength')
	for _, row in ipairs(rows(view)) do
		if row.key ~= 'use_friendly' then check(not row.disabled, row.key .. ' is enabled') end
	end
	root, view = page(UF, 'friendlynameplate')
	eq(row_for(view, 'use_enemy').disabled, false, 'the checked box can be unchecked')
	check(set(UF, 'friendlynameplate', 'use_enemy', false), 'unchecked')
	root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, false, "the Enemy page's box is free again")
	eq(row_for(view, 'box_note'), nil, 'and its line gone')

	check(set(UF, 'nameplate', 'use_friendly', true), 'the Enemy box checked')
	root, view = page(UF, 'friendlynameplate')
	eq(row_for(view, 'use_enemy').disabled, true, "the Friendly page's box is disabled")
	eq(row_for(view, 'box_note').name, ENEMY_USES_THIS, 'its line says enemy plates use this page, all but threat')
	root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, false, 'the checked box can be unchecked')

	-- Both checked (a profile from elsewhere): neither is disabled, so either
	-- can be unchecked, and each page says it uses the other.
	UF:GetProfileConfig().friendlynameplate.use_enemy = true
	root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, false, 'both checked: the Enemy box is free')
	eq(row_for(view, 'box_note').name, ENEMY_USES_FRIENDLY, 'the Enemy line')
	root, view = page(UF, 'friendlynameplate')
	eq(row_for(view, 'use_enemy').disabled, false, 'both checked: the Friendly box is free')
	eq(row_for(view, 'box_note').name, FRIENDLY_USES_ENEMY, 'the Friendly line')
	eq(#take_errors(), 0, 'no error')
end)

test('unchecking brings the settings back as they were', function()
	local st, UF = world('forever')
	UF:SpawnNameplates()
	check(set(UF, 'friendlynameplate', 'theme', 'thin'), 'Friendly Theme set')
	check(set(UF, 'friendlynameplate', 'width', '180'), 'Friendly Width set')
	check(set(UF, 'friendlynameplate', 'enable', true, 'Castbar'), 'Friendly castbar on')
	check(set(UF, 'nameplate', 'theme', 'thick'), 'Enemy Theme set')
	check(set(UF, 'nameplate', 'height', '24'), 'Enemy Height set')
	check(set(UF, 'nameplate', 'enable', false, 'Buffs'), 'Enemy buffs off')

	check(set(UF, 'friendlynameplate', 'use_enemy', true), 'the Friendly box checked')
	eq(UF:GetProfileConfig().friendlynameplate.theme, 'thin', 'the hidden settings are kept')
	check(set(UF, 'friendlynameplate', 'use_enemy', false), 'and unchecked')
	local _, view = page(UF, 'friendlynameplate')
	eq(keys(view), 'friendly,use_enemy,theme,background,width,height', 'General whole again')
	eq(tabs(view), FRIENDLY_TABS, 'and the tabs')
	eq(get(UF, 'friendlynameplate', 'theme'), 'thin', 'Theme as it was')
	eq(get(UF, 'friendlynameplate', 'width'), '180', 'Width as it was')
	eq(get(UF, 'friendlynameplate', 'enable', 'Castbar'), true, 'the castbar as it was')

	check(set(UF, 'nameplate', 'use_friendly', true), 'the Enemy box checked')
	eq(UF:GetProfileConfig().nameplate.height, 24, 'the hidden settings are kept')
	check(set(UF, 'nameplate', 'use_friendly', false), 'and unchecked')
	_, view = page(UF, 'nameplate')
	eq(keys(view), 'enable,threat_solo,use_friendly,theme,background,width,height', 'General whole again')
	eq(tabs(view), ENEMY_TABS, 'and the tabs')
	eq(get(UF, 'nameplate', 'theme'), 'thick', 'Theme as it was')
	eq(get(UF, 'nameplate', 'height'), '24', 'Height as it was')
	eq(get(UF, 'nameplate', 'enable', 'Buffs'), false, 'the buffs as they were')
	eq(#take_errors(), 0, 'no error')
end)

test('a box re-applies every plate and the plate size', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		check(UF:SpawnNameplates(), client .. ': spawned')
		local updates, sizes = {}, 0
		local realUpdate, realSize = UF.UpdateConfig, UF.ApplyPlateSize
		UF.UpdateConfig = function(self, unit, element)
			updates[#updates + 1] = tostring(unit) .. (element and ('.' .. element) or '')
			return realUpdate(self, unit, element)
		end
		UF.ApplyPlateSize = function(self, ...)
			sizes = sizes + 1
			return realSize(self, ...)
		end
		local function plate_update()
			for _, unit in ipairs(updates) do
				if UF.IsPlateUnit(unit) then return true end
			end
			return false
		end

		for _, box in ipairs({ { 'nameplate', 'use_friendly' }, { 'friendlynameplate', 'use_enemy' } }) do
			for _, value in ipairs({ true, false }) do
				updates, sizes = {}, 0
				local what = client .. ': ' .. box[2] .. ' ' .. tostring(value)
				check(set(UF, box[1], box[2], value), what)
				check(plate_update(), what .. ': the plates re-applied (' .. table.concat(updates, ',') .. ')')
				check(sizes > 0, what .. ': the plate size set')
			end
		end
		UF.UpdateConfig, UF.ApplyPlateSize = realUpdate, realSize
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ standing down

test('another nameplate addon loaded: both pages say which, and everything on them is disabled', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.loaded_addons.Plater = true
		for _, pick in ipairs({ 'nameplate', 'friendlynameplate' }) do
			local root, view = page(UF, pick)
			local where = client .. ' ' .. pick
			eq(root.Unitframes.args[pick].disabled(), true, where .. ': the group is disabled')
			local list = rows(view)
			eq(list[1].name, "Nameplates are drawn by Plater. Turn it off to use SaftUI's.", where .. ': the line first')
			eq(list[1].disabled, false, where .. ': not dimmed')
			for i = 2, #list do
				check(list[i].disabled, where .. ': ' .. list[i].key .. ' is disabled')
			end
			for _, tab in ipairs(view.tabs) do
				check(tab.disabled, where .. ': ' .. tab.key .. ' is disabled')
			end
		end

		-- A box checked: the line still shows, the other box stays disabled.
		UF:GetProfileConfig().friendlynameplate.use_enemy = true
		local _, view = page(UF, 'friendlynameplate')
		eq(rows(view)[1].name, "Nameplates are drawn by Plater. Turn it off to use SaftUI's.", client .. ': the line shows with the box checked')
		eq(row_for(view, 'use_enemy').disabled, true, client .. ': the checked box disabled too')
		_, view = page(UF, 'nameplate')
		eq(row_for(view, 'use_friendly').disabled, true, client .. ': the Enemy box disabled')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)
