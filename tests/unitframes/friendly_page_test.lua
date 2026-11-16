-- The Enemy nameplates and Friendly nameplates pages in /sui
-- (SaftUI-Unitframes/nameplates/options.lua):
--   - the two pages follow Raid 40 in the unit picker, Enemy first; neither
--     has Copy from, and no unit's Copy from offers either;
--   - the Friendly page's General has Friendly plates (the game's friendly
--     plates, nameplate.friendly), its box, Theme, Background, Width and
--     Height, and its element tabs are a plate's but Threat;
--   - each page's box ("Use enemy nameplates' settings" on the Friendly page,
--     "Use friendly nameplates' settings" on the Enemy page), while it's
--     checked, leaves its page's tabs where they are but disables them (all
--     but General, and Threat on the Enemy page), and General keeps only the
--     on/off switches and the box, with one centred line in place of the
--     rest ("Sourced from enemy nameplates");
--   - while one box is checked the other page's is disabled, and its tooltip
--     (the row's disabledDesc) says why; while another nameplate addon draws
--     the plates, it says that;
--   - unchecking brings the settings back as they were, and the tab chosen
--     before the box was checked;
--   - a box re-applies the plates (UF:UpdateConfig for a plate key) and their
--     size (UF:ApplyPlateSize). That a shown plate's base_unit follows is
--     Task 4's end-to-end test (ruling P1): it needs the plates' code;
--   - another nameplate addon: both pages say which, and everything on them
--     is disabled.
--
-- The world is nameplate_page_test.lua's: nameplate_world.lua's (see its top),
-- which has the real config/config.lua, nameplates/options.lua and every
-- unit's defaults, with SaftUI's options window, model and widgets loaded, so
-- the pages are read through UF:GetConfigTable() and st.OptionsModel as the
-- window reads them.
local NP = load_test_file('unitframes/nameplate_world.lua')

local PLAYERS, NPCS = 'nameplateShowFriendlyPlayers', 'nameplateShowFriendlyNpcs'
-- Each page's tabs, in the order the window shows them: Health, Cast bar and Auras; the
-- texts and icons are rows of General's Parts (Threat on the Enemy page only).
local ENEMY_TABS = 'general,Health,Castbar,Auras'
local FRIENDLY_TABS = 'general,Health,Castbar,Auras'
-- General's Parts rows after its own rows. While a box is checked they are hidden (each plate page's
-- keptParts in nameplates/options.lua names the ones that stay), but for the Enemy page's Threat, which stays.
local ENEMY_PARTS = ',name,subtext,healthtext,threat,raidtarget,quest'
local FRIENDLY_PARTS = ',name,subtext,healthtext,raidtarget,quest'
local ENEMY_BOX, FRIENDLY_BOX = "Use friendly nameplates' settings", "Use enemy nameplates' settings"
-- Each page's box's key.
local PLATE_BOX = { nameplate = 'use_friendly', friendlynameplate = 'use_enemy' }
local FRIENDLY_USES_THIS = "Friendly nameplates use this page's settings. To check this box, uncheck Use enemy nameplates' settings on the Friendly nameplates page."
local ENEMY_USES_THIS = "Enemy nameplates use this page's settings, all but threat. To check this box, uncheck Use friendly nameplates' settings on the Enemy nameplates page."
local DRAWN_BY_PLATER = "Nameplates are drawn by Plater. Turn it off to use SaftUI's."
-- The centred line in place of General's other settings while a page's box is checked.
local FRIENDLY_SOURCED, ENEMY_SOURCED = 'Sourced from enemy nameplates', 'Sourced from friendly nameplates'
local ENEMY_BOX_DESC = "Draws enemy and neutral nameplates with the Friendly nameplates page's settings. This page's own are set aside, kept for when it's unchecked: its Health, Cast bar and Auras tabs are disabled, and General's other settings and parts are hidden. Threat when solo and the Threat part stay, and still apply."
local FRIENDLY_BOX_DESC = "Draws friendly nameplates with the Enemy nameplates page's settings. This page's own are set aside, kept for when it's unchecked: its Health, Cast bar and Auras tabs are disabled, and General's other settings and parts are hidden. Friendly nameplates never show threat."
-- The tabs the Friendly page's box disables, and the Enemy page's (Threat stays).
local FRIENDLY_OFF_TABS = 'Health,Castbar,Auras'
local ENEMY_OFF_TABS = FRIENDLY_OFF_TABS

local function world(client)
	local st, UF = NP.world(client or 'forever')
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	load_test_file('lib/options_walk.lua')
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

-- The view's disabled tabs, in order.
local function disabled_tabs(view)
	local out = {}
	for _, tab in ipairs(view.tabs) do
		if tab.disabled then out[#out + 1] = tab.key end
	end
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
		eq(table.concat(picked, ','), 'all,player,raid40,nameplate,friendlynameplate', client .. ': All units first, Enemy, then Friendly, after Raid 40')
		eq(names[4], 'Enemy nameplates', client .. ': the Enemy page')
		eq(names[5], 'Friendly nameplates', client .. ': the Friendly page')

		local args = root.Unitframes.args
		eq(args.nameplate.pickerControl.args.copy, nil, client .. ': no Copy from on the Enemy page')
		eq(args.friendlynameplate.pickerControl.args.copy, nil, client .. ': nor on the Friendly page')
		check(args.nameplate.pickerControl.args.profile and args.friendlynameplate.pickerControl.args.manage, client .. ': Profile and Manage on both')
		check(args.player.pickerControl ~= nil, client .. ": the player's page keeps it, beside the picker")

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
	eq(keys(view), 'enable,threat_solo,use_friendly,theme,background,width,height' .. ENEMY_PARTS, 'in order, no centred line with no box checked')
	local general = root.Unitframes.args.nameplate.args.general.args
	eq(general.use_friendly.name, ENEMY_BOX, "the box's name")
	eq(general.use_friendly.desc, ENEMY_BOX_DESC, "the box's desc")
	eq(general.width.desc, "Enemy nameplates' width: the health bar and the area you click. The game stacks every nameplate at this size.", "Width's desc")
	eq(general.height.desc, "Enemy nameplates' height: the health bar and the area you click. The game stacks every nameplate at this size.", "Height's desc")
	check(general.theme.desc:find('enemy nameplate', 1, true) ~= nil, "Theme says it's the enemy plates': " .. general.theme.desc)
	eq(general.friendly, nil, 'no Friendly plates')
	eq(row_for(view, 'use_friendly').disabled, false, 'the box is enabled')
	eq(tabs(view), ENEMY_TABS, 'its tabs: Threat is a row of its Parts now')
	eq(get(UF, 'nameplate', 'use_friendly'), false, 'the box reads nameplate.use_friendly')
end)

test("the Friendly page: Friendly plates, its box, Theme, Background, Width and Height, and a plate's element tabs but Threat", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local root, view = page(UF, 'friendlynameplate')
		local config = root.Unitframes.args.friendlynameplate
		local general = config.args.general.args
		eq(keys(view), 'friendly,use_enemy,theme,background,width,height' .. FRIENDLY_PARTS, client .. ': in order, no centred line with no box checked')
		for key, name in pairs({ friendly = 'Friendly plates', use_enemy = FRIENDLY_BOX, theme = 'Theme',
				background = 'Background', width = 'Width', height = 'Height' }) do
			eq(general[key].name, name, client .. ': ' .. key .. ' is ' .. name)
		end
		eq(general.friendly.desc, "Shows nameplates over friendly players and NPCs: SaftUI's outside instances, Blizzard's inside them. Off, friendly units have none.", client .. ": Friendly plates' desc")
		eq(general.use_enemy.desc, FRIENDLY_BOX_DESC, client .. ": the box's desc")
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
		eq(tabs(view), FRIENDLY_TABS, client .. ': the element tabs, and no Threat row in its Parts')

		-- The tabs read and write the friendly config.
		eq(get(UF, 'friendlynameplate', 'enable', 'Health'), false, client .. ": Health reads the friendly config's")
		eq(get(UF, 'nameplate', 'enable', 'Health'), true, client .. ": the Enemy page's reads the enemy one")
		eq(get(UF, 'friendlynameplate', 'name'), true, client .. ": a part row's box reads the friendly config's")
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

test("checking a box: the page's tabs stay where they are, disabled but General (and Threat on the Enemy page), and General keeps its switches with a centred line in place of the rest", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local OM = SaftUI.OptionsModel

		-- The Friendly page's box.
		check(set(UF, 'friendlynameplate', 'use_enemy', true), client .. ': the Friendly box checked')
		eq(UF:GetProfileConfig().friendlynameplate.use_enemy, true, client .. ': saved')
		local root, view = page(UF, 'friendlynameplate')
		eq(keys(view), 'friendly,use_enemy,sourced', client .. ': Friendly plates, the box, and one line in place of the rest')
		local line = row_for(view, 'sourced')
		eq(line.type, 'description', client .. ': a description')
		eq(line.name, FRIENDLY_SOURCED, client .. ': saying where the settings come from')
		eq(OM.Member(root, line, 'justifyH'), 'CENTER', client .. ': centred across the page')
		eq(OM.Member(root, line, 'fill'), true, client .. ': and down the space the switches leave')
		for _, row in ipairs(rows(view)) do
			check(not row.disabled, client .. ': ' .. row.key .. ' enabled')
		end
		eq(tabs(view), FRIENDLY_TABS, client .. ': every tab still there, so nothing above the page moves')
		eq(disabled_tabs(view), FRIENDLY_OFF_TABS, client .. ': all but General disabled')
		eq(view.tab, 'general', client .. ': General open')

		-- A disabled tab the stored selection names (the page keeps one tab
		-- across its picks, so one chosen on another unit, then this page
		-- picked) opens General, with the line saying why, as when the tabs were
		-- hidden; the stored selection is kept.
		root, view = page(UF, 'friendlynameplate', 'Health')
		eq(view.tab, 'general', client .. ': the chosen Health tab disabled: General')
		eq(keys(view), 'friendly,use_enemy,sourced', client .. ': with the line')
		local chosen = { pick = 'friendlynameplate', tab = 'Health' }
		eq(view_of(UF, chosen).tab, 'general', client .. ': from the stored selection too')
		eq(chosen.tab, 'Health', client .. ': which keeps Health')
		-- Search finds neither the disabled tabs' settings (a selection can't open
		-- them) nor General's hidden ones; other units' still.
		for _, result in ipairs(OM.Search(root, 'Max width')) do
			check(result.path[2] ~= 'friendlynameplate', client .. ': no disabled tab or hidden part setting found: ' .. table.concat(result.path, '.'))
		end
		check(#OM.Search(root, 'Max width') > 0, client .. ": other units' still are")
		for _, result in ipairs(OM.Search(root, 'Width')) do
			check(not (result.path[2] == 'friendlynameplate' and result.path[3] == 'general'),
				client .. ": General's hidden Width isn't found")
		end

		-- The Enemy page shows everything, its box disabled, with no line.
		root, view = page(UF, 'nameplate')
		eq(keys(view), 'enable,threat_solo,use_friendly,theme,background,width,height' .. ENEMY_PARTS, client .. ': the Enemy page whole, no line')
		eq(tabs(view), ENEMY_TABS, client .. ': and its tabs')
		eq(disabled_tabs(view), '', client .. ': none disabled')
		check(set(UF, 'friendlynameplate', 'use_enemy', false), client .. ': unchecked')
		eq(view_of(UF, chosen).tab, 'Health', client .. ': unchecked: the tab chosen before opens')
		eq(disabled_tabs(view_of(UF, chosen)), '', client .. ': every tab enabled again')
		eq(chosen.tab, 'Health', client .. ': the stored selection kept')

		-- The Enemy page's box.
		check(set(UF, 'nameplate', 'use_friendly', true), client .. ': the Enemy box checked')
		eq(UF:GetProfileConfig().nameplate.use_friendly, true, client .. ': saved')
		root, view = page(UF, 'nameplate')
		eq(keys(view), 'enable,threat_solo,use_friendly,threat,sourced', client .. ': Nameplates, Threat when solo, the box and the line')
		eq(row_for(view, 'sourced').name, ENEMY_SOURCED, client .. ': saying where the settings come from')
		eq(tabs(view), ENEMY_TABS, client .. ': every tab still there')
		eq(disabled_tabs(view), ENEMY_OFF_TABS, client .. ': all but General and Threat disabled')
		-- Threat is a row of the Enemy page's Parts now, beside the others.
		check(row_for(view, 'threat') ~= nil, client .. ': the Threat row is in General')
		for _, key in ipairs({ 'name', 'subtext', 'healthtext', 'raidtarget', 'quest' }) do
			eq(row_for(view, key), nil, client .. ': the ' .. key .. ' row is set aside while the box is checked, as its tab was disabled')
		end
		eq(row_for(view, 'threat').disabled, false, client .. ': and enabled')
		local enemyChosen = { pick = 'nameplate', tab = 'Castbar' }
		eq(view_of(UF, enemyChosen).tab, 'general', client .. ': the chosen Castbar tab disabled: General')
		local threatFound = false
		for _, result in ipairs(OM.Search(root, 'Threat')) do
			check(result.path[2] ~= 'nameplate' or result.path[3] == 'general', client .. ': only General searched: ' .. table.concat(result.path, '.'))
			if result.path[2] == 'nameplate' and result.path[4] == 'parts' and result.path[5] == 'threat' then threatFound = true end
		end
		check(threatFound, client .. ": the Threat row's settings found")

		-- The Friendly page shows everything, its box disabled.
		root, view = page(UF, 'friendlynameplate')
		eq(keys(view), 'friendly,use_enemy,theme,background,width,height' .. FRIENDLY_PARTS, client .. ': the Friendly page whole, no line')
		eq(disabled_tabs(view), '', client .. ': its tabs enabled')
		check(set(UF, 'nameplate', 'use_friendly', false), client .. ': the Enemy box unchecked')
		eq(view_of(UF, enemyChosen).tab, 'Castbar', client .. ': unchecked: the Castbar tab chosen before opens')
		check(not rows(view_of(UF, enemyChosen))[1].disabled, client .. ': enabled')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("one box at a time: the other page's box is disabled, and hovering it says why in its tooltip", function()
	local st, UF = world('forever')
	check(set(UF, 'friendlynameplate', 'use_enemy', true), 'the Friendly box checked')
	local root, view = page(UF, 'nameplate')
	local box = row_for(view, 'use_friendly')
	eq(box.disabled, true, "the Enemy page's box is disabled")
	eq(box.disabledDesc, FRIENDLY_USES_THIS, 'its tooltip says friendly plates use this page, and how to free it')
	eq(row_for(view, 'sourced'), nil, 'no line on the page')
	for _, row in ipairs(rows(view)) do
		if row.key ~= 'use_friendly' then
			check(not row.disabled, row.key .. ' is enabled')
			eq(row.disabledDesc, nil, row.key .. ' has no reason')
		end
	end

	-- Drawn, hovering the box shows it: the box takes no mouse, so its row's tooltip shows.
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 400)
	local body = st.OptionsBody.New(content, root)
	body:Draw(view.sections)
	-- In the game a check box starts out taking the mouse (the stubs' frames
	-- don't): give them it and draw again from the pool, so only Bind can
	-- take it off the disabled box.
	local primed = {}
	for _, c in ipairs(body.cells) do
		c.widget.frame:EnableMouse(true)
		primed[c.widget.frame] = true
	end
	body:Release()
	body:Draw(view.sections)
	local cell
	for _, c in ipairs(body.cells) do if c.row.key == 'use_friendly' then cell = c end end
	check(primed[cell.widget.frame], 'the box is one that took the mouse')
	eq(cell.widget.frame:IsMouseEnabled(), false, "the disabled box gave the mouse up: its row takes it")
	stub.fire_script(cell.frame, 'OnEnter')
	local texts = stub.state(GameTooltip).texts
	eq(table.concat(texts, '|'), ENEMY_BOX .. '|' .. ENEMY_BOX_DESC .. '|' .. FRIENDLY_USES_THIS, 'its name, what it does, and why it is disabled')
	stub.fire_script(cell.frame, 'OnLeave')
	body:Release()

	root, view = page(UF, 'friendlynameplate')
	eq(row_for(view, 'use_enemy').disabled, false, 'the checked box can be unchecked')
	eq(row_for(view, 'use_enemy').disabledDesc, nil, 'no reason on it')
	check(set(UF, 'friendlynameplate', 'use_enemy', false), 'unchecked')
	root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, false, "the Enemy page's box is free again")
	eq(row_for(view, 'use_friendly').disabledDesc, nil, 'with no reason')

	check(set(UF, 'nameplate', 'use_friendly', true), 'the Enemy box checked')
	root, view = page(UF, 'friendlynameplate')
	eq(row_for(view, 'use_enemy').disabled, true, "the Friendly page's box is disabled")
	eq(row_for(view, 'use_enemy').disabledDesc, ENEMY_USES_THIS, 'its tooltip says enemy plates use this page, all but threat')
	root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, false, 'the checked box can be unchecked')

	-- Both checked (a profile from elsewhere): neither is disabled, so either
	-- can be unchecked, and each page says it's sourced from the other.
	UF:GetProfileConfig().friendlynameplate.use_enemy = true
	root, view = page(UF, 'nameplate')
	eq(row_for(view, 'use_friendly').disabled, false, 'both checked: the Enemy box is free')
	eq(row_for(view, 'sourced').name, ENEMY_SOURCED, 'the Enemy line')
	root, view = page(UF, 'friendlynameplate')
	eq(row_for(view, 'use_enemy').disabled, false, 'both checked: the Friendly box is free')
	eq(row_for(view, 'sourced').name, FRIENDLY_SOURCED, 'the Friendly line')
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
	eq(keys(view), 'friendly,use_enemy,theme,background,width,height' .. FRIENDLY_PARTS, 'General whole again')
	eq(tabs(view), FRIENDLY_TABS, 'and the tabs')
	eq(disabled_tabs(view), '', 'every one enabled')
	eq(get(UF, 'friendlynameplate', 'theme'), 'thin', 'Theme as it was')
	eq(get(UF, 'friendlynameplate', 'width'), '180', 'Width as it was')
	eq(get(UF, 'friendlynameplate', 'enable', 'Castbar'), true, 'the castbar as it was')

	check(set(UF, 'nameplate', 'use_friendly', true), 'the Enemy box checked')
	eq(UF:GetProfileConfig().nameplate.height, 24, 'the hidden settings are kept')
	check(set(UF, 'nameplate', 'use_friendly', false), 'and unchecked')
	_, view = page(UF, 'nameplate')
	eq(keys(view), 'enable,threat_solo,use_friendly,theme,background,width,height' .. ENEMY_PARTS, 'General whole again')
	eq(tabs(view), ENEMY_TABS, 'and the tabs')
	eq(disabled_tabs(view), '', 'every one enabled')
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

test('another nameplate addon loaded: both pages say which, and everything on them is disabled, the boxes saying why', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.loaded_addons.Plater = true
		for _, pick in ipairs({ 'nameplate', 'friendlynameplate' }) do
			local root, view = page(UF, pick)
			local where = client .. ' ' .. pick
			eq(root.Unitframes.args[pick].disabled(), true, where .. ': the group is disabled')
			local list = rows(view)
			eq(list[1].name, DRAWN_BY_PLATER, where .. ': the line first')
			eq(list[1].disabled, false, where .. ': not dimmed')
			for i = 2, #list do
				check(list[i].disabled, where .. ': ' .. list[i].key .. ' is disabled')
			end
			for _, tab in ipairs(view.tabs) do
				check(tab.disabled, where .. ': ' .. tab.key .. ' is disabled')
			end
			local box = row_for(view, PLATE_BOX[pick])
			eq(box.disabledDesc, DRAWN_BY_PLATER, where .. ": the box's tooltip says which addon")
		end

		-- A box checked: the line still shows, everything stays disabled, and
		-- each box's tooltip names the addon, the other page's included.
		UF:GetProfileConfig().friendlynameplate.use_enemy = true
		local _, view = page(UF, 'friendlynameplate')
		eq(rows(view)[1].name, DRAWN_BY_PLATER, client .. ': the line shows with the box checked')
		eq(row_for(view, 'use_enemy').disabled, true, client .. ': the checked box disabled too')
		eq(row_for(view, 'use_enemy').disabledDesc, DRAWN_BY_PLATER, client .. ': saying which addon')
		eq(row_for(view, 'sourced').disabled, true, client .. ': the centred line dimmed with the rest')
		for _, tab in ipairs(view.tabs) do
			check(tab.disabled, client .. ': with the box checked ' .. tab.key .. ' is disabled')
		end
		_, view = page(UF, 'nameplate')
		eq(row_for(view, 'use_friendly').disabled, true, client .. ': the Enemy box disabled')
		eq(row_for(view, 'use_friendly').disabledDesc, DRAWN_BY_PLATER, client .. ': saying which addon, not the other box')
		for _, tab in ipairs(view.tabs) do
			check(tab.disabled, client .. ': the Enemy page with the other box checked: ' .. tab.key .. ' is disabled')
		end
		UF:GetProfileConfig().friendlynameplate.use_enemy = false
		UF:GetProfileConfig().nameplate.use_friendly = true
		_, view = page(UF, 'nameplate')
		for _, tab in ipairs(view.tabs) do
			check(tab.disabled, client .. ': its own box checked: ' .. tab.key .. ' (Threat too) is disabled')
		end
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("General's toggles keep their panel while the box is checked: only the centred line under them is bare", function()
	local st, UF = world('forever')
	local theme = st.config.profile.theme.name
	st.config.profile.theme.name = 'thick'
	for _, case in ipairs({ { 'nameplate', 'use_friendly' }, { 'friendlynameplate', 'use_enemy' } }) do
		local name, box = case[1], case[2]
		for _, checked in ipairs({ false, true }) do
			check(set(UF, name, box, checked), name .. ': the box ' .. tostring(checked))
			local root, view = page(UF, name)
			local content = CreateFrame('Frame', nil, UIParent)
			local body = st.OptionsBody.New(content, root, nil, 774)
			body:Draw(view.sections)
			local first, sourced
			for _, c in ipairs(body.cells) do
				first = first or c
				if c.row.key == 'sourced' then sourced = c end
			end
			local panels = {}
			for _, p in ipairs(body.pools.panel.used) do
				if p:IsShown() then panels[#panels + 1] = p end
			end
			local label = name .. ' ' .. tostring(checked)
			-- Unchecked: the toggles' panel and the Parts'. Checked: the Parts are hidden (the Friendly page has no
			-- Parts section then; the Enemy page keeps Threat's).
			local want = (not checked or (name == 'nameplate')) and 2 or 1
			eq(#panels, want, label .. ': the toggles panel, and the Parts section unless set aside')
			local _, _, _, _, top = panels[1]:GetPoint(1)
			eq(-top, first.y, label .. ': from the first row')
			if checked then
				check(sourced ~= nil, label .. ': the centred line')
				if name == 'nameplate' then
					-- The kept Threat row's section sits directly under the toggles' panel, then the line under it.
					local _, _, _, _, top2 = panels[2]:GetPoint(1)
					eq(-top2 + panels[2]:GetHeight(), sourced.y, label .. ': the line directly under the Parts panel')
					check(-top2 >= -top + panels[1]:GetHeight(), label .. ': the Parts panel is below the toggles')
				else
					eq(-top + panels[1]:GetHeight(), sourced.y, label .. ': to the line, which is not under it')
				end
				local _, _, _, x = sourced.frame:GetPoint(1)
				eq(x .. '+' .. sourced.frame:GetWidth(), '0+774', label .. ': the line bare, the whole width')
				local _, _, _, fx = first.frame:GetPoint(1)
				eq(fx, 14, label .. ': the toggles padded')
			else
				check(sourced == nil, label .. ': no line')
			end
			body:Release()
		end
	end
	st.config.profile.theme.name = theme
end)

------------------------------------------------------------------ the Parts section (Ruling 31)

test("with Use enemy nameplates' settings checked the Parts section hides, and comes back whole", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local _, UF = world(client)
		local root, view = page(UF, 'friendlynameplate')
		local parts = root.Unitframes.args.friendlynameplate.args.general.args.parts
		eq(type(parts.hidden), 'function', client .. ': the section has a hidden rule, none of its rows kept')
		eq(keys(view), 'friendly,use_enemy,theme,background,width,height' .. FRIENDLY_PARTS, client .. ': drawn unchecked')

		check(set(UF, 'friendlynameplate', 'use_enemy', true), client .. ': checked')
		_, view = page(UF, 'friendlynameplate')
		eq(keys(view), 'friendly,use_enemy,sourced', client .. ': the switches, the box and the line')
		for _, key in ipairs({ 'name', 'subtext', 'healthtext', 'raidtarget', 'quest' }) do
			eq(row_for(view, key), nil, client .. ': ' .. key .. ' is hidden')
		end
		eq(row_for(view, 'sourced').name, 'Sourced from enemy nameplates', client .. ': the line is last')
		local list = rows(view)
		eq(list[#list].key, 'sourced', client .. ': nothing under the line')

		check(set(UF, 'friendlynameplate', 'use_enemy', false), client .. ': unchecked')
		_, view = page(UF, 'friendlynameplate')
		eq(keys(view), 'friendly,use_enemy,theme,background,width,height' .. FRIENDLY_PARTS, client .. ': every row back')
	end
end)

test('another nameplate addon: every part row is disabled, the stand-down line reads at full strength', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local _, UF = world(client)
		stub.loaded_addons.Plater = true
		for _, pick in ipairs({ 'nameplate', 'friendlynameplate' }) do
			local _, view = page(UF, pick)
			local list = rows(view)
			eq(list[1].name, DRAWN_BY_PLATER, client .. ' ' .. pick .. ': the line first')
			eq(list[1].disabled, false, client .. ' ' .. pick .. ': at full strength')
			local seen = 0
			for _, key in ipairs({ 'name', 'subtext', 'healthtext', 'threat', 'raidtarget', 'quest' }) do
				local row = row_for(view, key)
				if row then
					seen = seen + 1
					eq(row.disabled, true, client .. ' ' .. pick .. ': ' .. key .. ' is disabled')
				end
			end
			eq(seen, pick == 'nameplate' and 6 or 5, client .. ' ' .. pick .. ': the part rows are shown, dimmed')
		end
		-- The box checked too: the rows kept stay disabled by the stand-down.
		UF:GetProfileConfig().nameplate.use_friendly = true
		local _, view = page(UF, 'nameplate')
		eq(row_for(view, 'threat').disabled, true, client .. ': Threat disabled while the plates are another addon\'s')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)
