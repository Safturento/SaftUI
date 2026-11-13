-- The Enemy nameplates page in /sui (SaftUI-Unitframes/nameplates/options.lua)
-- and the game's nameplate settings SaftUI sets while its plates are drawn
-- (SaftUI-Unitframes/nameplates/cvars.lua):
--   - the page follows Raid 40 in the unit picker; its General tab has
--     Nameplates, Threat when solo, its box, Theme, Background, Width and
--     Height, and no Position, Layout or Range; its element tabs are every
--     unit's (by ValidUnit), and it has no Copy from. Friendly plates is on the
--     Friendly nameplates page (friendly_page_test.lua has that page and the
--     boxes);
--   - turning Nameplates off puts the game's settings back and asks for a
--     reload; Friendly plates sets the game's friendly plates, out of combat;
--   - the user's own settings are recorded once per character, the first time
--     SaftUI changes them, put back when Nameplates is turned off (a value the
--     game refuses stays recorded), and recorded anew the next time; with
--     Nameplates off nothing is set, even while SaftUI's plates are still up
--     before the reload;
--   - OnEnable sets them for SaftUI's plates, puts them back with Nameplates
--     off, and touches nothing while another nameplate addon draws the plates,
--     whose name the page then shows over its options, all disabled.
--
-- The world is nameplate_world.lua's (see its top), which has the real
-- config/config.lua and nameplates/options.lua, with SaftUI's options window,
-- model and widgets loaded as config_test.lua loads them, so the page is read
-- through UF:GetConfigTable() and st.OptionsWidgets.Confirm draws its dialog.
-- ReloadUI is a recorder. The game's settings are tests/wow/game.lua's
-- stub.cvars. st.config.char is AceDB's per-character table, which the shell
-- doesn't have: {} for each world, as for a new character.
local NP = load_test_file('unitframes/nameplate_world.lua')

local PLAYERS, NPCS = 'nameplateShowFriendlyPlayers', 'nameplateShowFriendlyNpcs'

local reloads
local function world(client)
	local st, UF = NP.world(client or 'forever')
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	load_test_file('lib/options_walk.lua')
	st.config.char = {}
	reloads = 0
	ReloadUI = function() reloads = reloads + 1 end
	return st, UF
end

-- The unit frames' page as the window builds it, picked on the nameplates
-- (General, unless selection says otherwise), and the root it was read from.
local function page(UF, selection)
	local root = { Unitframes = UF:GetConfigTable() }
	return root, SaftUI.OptionsModel.BuildView(root, 'Unitframes', selection or { pick = 'nameplate', tab = 'general' })
end

-- The view's rows, in the order the window draws them.
local function rows(view)
	local out = {}
	for _, section in ipairs(view.sections) do
		for _, row in ipairs(section.rows) do out[#out + 1] = row end
	end
	return out
end

local function row_for(view, key)
	for _, row in ipairs(rows(view)) do
		if row.key == key then return row end
	end
end

-- Sets General's key as the window does (the row's set, inherited where it
-- has none of its own). Returns what OM.Set does. Friendly plates is on the
-- Friendly nameplates page (friendly_page_test.lua), the rest on the Enemy one.
local function set(UF, key, value)
	local root, view = page(UF, { pick = key == 'friendly' and 'friendlynameplate' or 'nameplate', tab = 'general' })
	local row = row_for(view, key)
	assert(row, 'no General row ' .. key)
	return SaftUI.OptionsModel.Set(root, row, value)
end

-- Every C_CVar.SetCVar call from now, as 'name=value', in order.
local function watch_sets()
	local calls = {}
	local real = C_CVar.SetCVar
	C_CVar.SetCVar = function(name, value)
		calls[#calls + 1] = name .. '=' .. tostring(value)
		return real(name, value)
	end
	return calls
end

local click = stub.click

local function record(st)
	return st.config.char.nameplateCVars
end

-- UF:OnEnable, with what it does before the nameplates left out: spawning
-- the other units (their frames are plain ones here), the group headers,
-- placing every frame, the movers and Blizzard's raid frames. Those need
-- oUF's group headers and edit mode, which this world doesn't have.
local function enable(UF)
	NP.ouf.Spawn = function(_, _, name) return CreateFrame('Button', name, UIParent) end
	for _, step in ipairs({ 'CreateGroupHeaders', 'ApplyConfig', 'RegisterMovers', 'SetupBlizzardRaidFrames' }) do
		UF[step] = function() end
	end
	UF:OnEnable()
end

------------------------------------------------------------------ the stub

test("the game's settings (tests/wow/game.lua's C_CVar): strings, unknown names, and refused in combat", function()
	world('forever')
	eq(C_CVar.GetCVar(PLAYERS), '0', 'friendly plates off by default')
	eq(C_CVar.GetCVar('noSuchSetting'), nil, 'a setting the client lacks: nil')
	eq(C_CVar.SetCVar('noSuchSetting', '1'), false, 'which it refuses to set')
	eq(C_CVar.GetCVar('noSuchSetting'), nil, 'and still lacks')
	eq(C_CVar.SetCVar(PLAYERS, 1), true, 'set')
	eq(C_CVar.GetCVar(PLAYERS), '1', 'kept as a string')
	stub.in_combat = true
	eq(C_CVar.SetCVar(PLAYERS, '0'), false, 'refused in combat')
	eq(C_CVar.GetCVar(PLAYERS), '1', 'unchanged')
	eq(#stub.blocked, 1, 'noted as blocked')
	eq(stub.blocked[1][1], C_CVar, 'by C_CVar')
	eq(stub.blocked[1][2], PLAYERS, 'and the setting')
	stub.in_combat = false
end)

------------------------------------------------------------------ the page

-- The page is Enemy nameplates, and Friendly plates is on the Friendly
-- nameplates page, with the box in its place here (friendly_page_test.lua
-- tests both pages and the boxes).
test('the Enemy nameplates page follows Raid 40; General has Nameplates, Threat when solo, its box, Theme, Background, Width and Height, and no Position', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		-- Two units for the picker to put it after.
		UF.units.player = CreateFrame('Frame', nil, UIParent)
		UF.groups = { raid40 = CreateFrame('Frame', nil, UIParent) }
		UF.holders.raid40 = CreateFrame('Frame', nil, UIParent)

		local root, view = page(UF, { pick = 'nameplate' })
		local picked = {}
		for i, entry in ipairs(view.picker.values) do picked[i] = entry.key end
		eq(table.concat(picked, ','), 'player,raid40,nameplate,friendlynameplate,profile', client .. ': Enemy nameplates follows Raid 40, Friendly nameplates it')
		eq(view.picker.selected, 'nameplate', client .. ': picked')
		local config = root.Unitframes.args.nameplate
		eq(config.name, 'Enemy nameplates', client .. ': its name')

		local general = config.args.general
		local keys = {}
		for key in pairs(general.args) do keys[#keys + 1] = key end
		table.sort(keys)
		eq(table.concat(keys, ','), 'background,box_note,enable,height,theme,threat_solo,use_friendly,width', client .. ": General's rows")
		for key, name in pairs({ enable = 'Nameplates', threat_solo = 'Threat when solo', use_friendly = "Use friendly nameplates' settings",
				theme = 'Theme', background = 'Background', width = 'Width', height = 'Height' }) do
			eq(general.args[key].name, name, client .. ': ' .. key .. ' is ' .. name)
		end
		eq(general.args.enable.desc, "Draws nameplates in SaftUI's look: enemies and neutral units, and friendly ones outside instances. Changes after a reload.", client .. ": Nameplates' desc")
		eq(general.args.threat_solo.desc, "Tints enemy health bars by your threat while you're on your own too. In a party or raid they're always tinted.", client .. ": Threat when solo's desc")
		eq(general.args.width.desc, "Enemy nameplates' width: the health bar and the area you click. The game stacks every nameplate at this size.", client .. ": Width's desc")
		eq(general.args.height.desc, "Enemy nameplates' height: the health bar and the area you click. The game stacks every nameplate at this size.", client .. ": Height's desc")
		check(general.args.theme.desc:find('nameplate', 1, true) ~= nil, client .. ": Theme says it's the plates': " .. general.args.theme.desc)
		eq(general.args.background.order, general.args.theme.order + 0.5, client .. ': Background right after Theme')

		-- In the order the window draws them: the two toggles and the box on a
		-- line. The box's line shows only while a box is checked.
		local drawn = {}
		for i, row in ipairs(rows(view)) do drawn[i] = row.key end
		eq(table.concat(drawn, ','), 'enable,threat_solo,use_friendly,theme,background,width,height', client .. ': in order')
		for _, row in ipairs(rows(view)) do
			check(not row.disabled, client .. ': ' .. row.key .. ' is enabled with no other nameplate addon')
		end

		-- The game places each plate and gives them all one size.
		eq(general.args.position, nil, client .. ': no Position')
		eq(general.args.layout, nil, client .. ': no Layout')
		eq(general.args.range_alpha, nil, client .. ': no Range')
		eq(config.args.copy, nil, client .. ': no Copy from')

		-- Every element tab whose ValidUnit takes a plate.
		local tabs = {}
		for key, option in pairs(config.args) do
			if key ~= 'general' and option.type == 'group' then tabs[#tabs + 1] = key end
		end
		table.sort(tabs)
		eq(table.concat(tabs, ','), 'Buffs,Castbar,Debuffs,Health,Name,QuestIndicator,RaidTargetIndicator,Subtext,Threat', client .. ': its element tabs')

		-- A plate shows any unit but an offline player, so Health's colors
		-- have every flag but Disconnected.
		eq(UF.CanShow('nameplate', 'offline'), false, client .. ': no offline players')
		for _, kind in ipairs({ 'players', 'npcs', 'pets', 'mobs' }) do
			eq(UF.CanShow('nameplate', kind), true, client .. ': it shows ' .. kind)
		end
		local colors = config.args.Health.args.colors.args
		eq(colors.colorDisconnected, nil, client .. ': no Disconnected')
		for _, flag in ipairs({ 'colorTapping', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction' }) do
			check(colors[flag] ~= nil, client .. ': Health has ' .. flag)
		end

		-- AceConfigRegistry takes it, SaftUI's fields aside.
		local ok, err = pcall(LibStub('AceConfigRegistry-3.0').ValidateOptionsTable, LibStub('AceConfigRegistry-3.0'),
			ace_ready({ name = st.name, type = 'group', args = root }), st.name)
		check(ok, client .. ': valid: ' .. tostring(err))
	end
end)

test("Threat when solo, Theme, Background, Width and Height are saved and re-applied; Width and Height set every plate's size", function()
	local st, UF = world('forever')
	check(UF:SpawnNameplates(), 'spawned')
	local P = UF:GetProfileConfig().nameplate
	local applied = {}
	local real = UF.UpdateConfig
	UF.UpdateConfig = function(self, unit, element)
		applied[#applied + 1] = tostring(unit) .. (element and ('.' .. element) or '')
		return real(self, unit, element)
	end

	check(set(UF, 'threat_solo', true), 'Threat when solo set')
	eq(P.threat_solo, true, 'saved')
	check(set(UF, 'theme', 'thin'), 'Theme set')
	eq(P.theme, 'thin', 'saved')
	check(set(UF, 'background', 'transparent'), 'Background set')
	eq(P.background, 'transparent', 'saved')
	eq(table.concat(applied, ','), 'nameplate,nameplate,nameplate', 'each re-applies the nameplates')

	-- An input: the box's text is saved as a number.
	check(set(UF, 'width', '240'), 'Width set')
	eq(P.width, 240, 'saved as a number')
	eq(table.concat(stub.nameplate_size, 'x'), table.concat({ UF.PlateDriverSize(240, 20) }, 'x'), "every plate's width")
	check(set(UF, 'height', '24'), 'Height set')
	eq(P.height, 24, 'saved as a number')
	eq(table.concat(stub.nameplate_size, 'x'), table.concat({ UF.PlateDriverSize(240, 24) }, 'x'), "every plate's height")
	eq(#applied, 5, 'each re-applied the nameplates')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ Nameplates and Friendly plates

test('turning Nameplates off puts the game settings back and asks for a reload', function()
	local st, UF = world('forever')
	local W = st.OptionsWidgets
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', "SaftUI's friendly plates")

	check(set(UF, 'enable', false), 'Nameplates turned off')
	eq(UF:GetProfileConfig().nameplate.enable, false, 'saved')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', "the user's settings are back")
	eq(record(st), nil, 'the record is cleared')
	eq(W.ConfirmText(), 'Nameplates change after a reload. Reload now?', 'it asks')
	eq(reloads, 0, 'nothing reloaded before Yes')
	click(W.GetDialogFrames().yes)
	eq(reloads, 1, 'Yes reloads')
	eq(W.ConfirmText(), nil, 'the dialog closed')

	-- On again before the reload: SaftUI's plates are still up, so they get
	-- SaftUI's settings again, recorded anew.
	stub.cvars[PLAYERS] = '1'
	check(set(UF, 'enable', true), 'Nameplates turned on')
	eq(UF:GetProfileConfig().nameplate.enable, true, 'saved')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', "SaftUI's again")
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '10', 'what they were, recorded')
	eq(W.ConfirmText(), 'Nameplates change after a reload. Reload now?', 'it asks again')
	click(W.GetDialogFrames().no)
	eq(reloads, 1, 'No reloads nothing')
	eq(#take_errors(), 0, 'no error')
end)

test('turning Nameplates on while they were off at login sets nothing until the reload', function()
	local st, UF = world('forever')
	UF:GetProfileConfig().nameplate.enable = false
	check(not UF:SpawnNameplates(), 'not spawned')
	local calls = watch_sets()
	check(set(UF, 'enable', true), 'Nameplates turned on')
	eq(#calls, 0, 'nothing set: no plates of SaftUI\'s yet')
	eq(record(st), nil, 'nothing recorded')
	eq(st.OptionsWidgets.ConfirmText(), 'Nameplates change after a reload. Reload now?', 'it asks')
end)

test("Friendly plates sets the game's friendly plates for players and NPCs, out of combat", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		UF:SpawnNameplates()
		UF:ApplyNameplateCVars()
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': on with Friendly plates on')

		check(set(UF, 'friendly', false), client .. ': Friendly plates off')
		eq(UF:GetProfileConfig().nameplate.friendly, false, client .. ': saved')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', client .. ': both off')
		check(set(UF, 'friendly', true), client .. ': Friendly plates on')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': both on')

		-- In combat the game refuses them: SaftUI waits for the end of combat.
		stub.in_combat = true
		check(set(UF, 'friendly', false), client .. ': Friendly plates off in combat')
		eq(UF:GetProfileConfig().nameplate.friendly, false, client .. ': saved at once')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', client .. ': no change in combat')
		eq(#stub.blocked, 0, client .. ': nothing tried in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', client .. ': set once combat ends')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("setting the game's plates puts Blizzard's widgets back on SaftUI's plates (Blizzard re-anchors them on the friendly NPC setting)", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		UF:SpawnNameplates()
		local refreshed = 0
		local real = UF.RefreshPlateWidgets
		UF.RefreshPlateWidgets = function(self, ...) refreshed = refreshed + 1 return real(self, ...) end
		local ok, err = pcall(function()
			UF:ApplyNameplateCVars()
			eq(refreshed, 1, client .. ': refreshed once after the settings are set')
			check(set(UF, 'friendly', false), client .. ': Friendly plates off')
			eq(refreshed, 2, client .. ': and again when Friendly plates changes them')
			-- Nameplates off (the reload declined): nothing set, nothing refreshed.
			UF:GetProfileConfig().nameplate.enable = false
			UF:ApplyNameplateCVars()
			eq(refreshed, 2, client .. ': nothing with Nameplates off')
		end)
		UF.RefreshPlateWidgets = real
		check(ok, client .. ': ' .. tostring(err))
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('Friendly plates with Nameplates off, or another addon drawing the plates, is only saved', function()
	local st, UF = world('forever')
	UF:GetProfileConfig().nameplate.enable = false
	UF:SpawnNameplates()
	local calls = watch_sets()
	check(set(UF, 'friendly', false), 'Friendly plates off')
	eq(UF:GetProfileConfig().nameplate.friendly, false, 'saved')
	eq(#calls, 0, 'nothing set')

	st, UF = world('forever')
	stub.loaded_addons.Plater = true
	UF:SpawnNameplates()
	calls = watch_sets()
	UF:ApplyNameplateCVars()
	eq(#calls, 0, "another addon's plates: nothing set")
	eq(record(st), nil, 'nothing recorded')
end)

------------------------------------------------------------------ the record

test("the user's previous settings are recorded once, the first time SaftUI changes them", function()
	local st, UF = world('forever')
	stub.cvars[PLAYERS], stub.cvars[NPCS] = '1', '0'
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '10', 'recorded as they were')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', "SaftUI's")

	set(UF, 'friendly', false)
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '10', 'Friendly plates off: the record unchanged')
	set(UF, 'friendly', true)
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '10', 'on again: unchanged')
	UF:ApplyNameplateCVars()
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '10', 'applied again: unchanged')

	UF:RestoreNameplateCVars()
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '10', 'put back')
	eq(record(st), nil, 'the record cleared')
	local calls = watch_sets()
	UF:RestoreNameplateCVars()
	eq(#calls, 0, 'nothing to put back a second time')
end)

test('a second on/off cycle records anew', function()
	local st, UF = world('forever')
	stub.cvars[PLAYERS], stub.cvars[NPCS] = '1', '0'
	enable(UF)
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', 'first session: SaftUI\'s')
	set(UF, 'enable', false)
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '10', 'turned off: put back exactly')
	eq(record(st), nil, 'nothing recorded')

	-- The user changes the game's setting, then turns SaftUI's plates on again
	-- and reloads. The character's saved variables and the game's settings
	-- outlive the reload.
	stub.cvars[PLAYERS] = '0'
	UF:GetProfileConfig().nameplate.enable = true
	local char, cvars = st.config.char, stub.cvars
	local profile = UF:GetProfileConfig().nameplate

	st, UF = world('forever')
	st.config.char, stub.cvars = char, cvars
	for key, value in pairs(profile) do UF:GetProfileConfig().nameplate[key] = value end
	enable(UF)
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '00', 'second session: what was set then')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', "SaftUI's")
	set(UF, 'enable', false)
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', "turned off: the user's new settings back")
	eq(#take_errors(), 0, 'no error')
end)

test('a setting this client lacks is skipped', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.cvars[NPCS] = nil
		UF:SpawnNameplates()
		local calls = watch_sets()
		UF:ApplyNameplateCVars()
		eq(table.concat(calls, ','), PLAYERS .. '=1', client .. ': only the one it has')
		eq(record(st)[NPCS], nil, client .. ': nothing recorded for it')
		eq(record(st)[PLAYERS], '0', client .. ': the other recorded')
		UF:RestoreNameplateCVars()
		eq(stub.cvars[PLAYERS], '0', client .. ': put back')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('putting the settings back waits for the end of combat', function()
	local st, UF = world('forever')
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	stub.in_combat = true
	UF:RestoreNameplateCVars()
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', 'unchanged in combat')
	check(record(st) ~= nil, 'the record kept')
	eq(#stub.blocked, 0, 'nothing tried')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', 'put back once combat ends')
	eq(record(st), nil, 'and the record cleared')
end)

test('each character records and puts back its own settings', function()
	-- A login on character, with the game's settings cvars, keeping the
	-- account's saved variables (global) and the character's (char).
	local global = {}
	local function login(char, cvars)
		local st, UF = world('forever')
		st.config.global, st.config.char, stub.cvars = global, char, cvars
		enable(UF)
		return st, UF
	end
	local alice, bob = {}, {}
	local aliceCVars = { [PLAYERS] = '1', [NPCS] = '0' }
	local bobCVars = { [PLAYERS] = '0', [NPCS] = '1' }

	login(alice, aliceCVars)
	eq(alice.nameplateCVars[PLAYERS] .. alice.nameplateCVars[NPCS], '10', "the first character's, recorded")
	local st, UF = login(bob, bobCVars)
	eq(bob.nameplateCVars[PLAYERS] .. bob.nameplateCVars[NPCS], '01', "the second's, its own")
	eq(alice.nameplateCVars[PLAYERS] .. alice.nameplateCVars[NPCS], '10', "the first's untouched")
	eq(global.nameplateCVars, nil, 'nothing account-wide')

	set(UF, 'enable', false)
	eq(bobCVars[PLAYERS] .. bobCVars[NPCS], '01', 'the second character turns it off: its own back')
	eq(bob.nameplateCVars, nil, 'its record cleared')
	eq(alice.nameplateCVars[PLAYERS] .. alice.nameplateCVars[NPCS], '10', "the first's kept")

	st, UF = login(alice, aliceCVars)
	eq(aliceCVars[PLAYERS] .. aliceCVars[NPCS], '11', "the first still has SaftUI's")
	set(UF, 'enable', false)
	eq(aliceCVars[PLAYERS] .. aliceCVars[NPCS], '10', 'the first turns it off: its own back')
	eq(alice.nameplateCVars, nil, 'its record cleared')
	eq(#take_errors(), 0, 'no error')
end)

test('a setting the game refuses to put back stays recorded', function()
	local st, UF = world('forever')
	stub.cvars[PLAYERS], stub.cvars[NPCS] = '1', '0'
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	local real = C_CVar.SetCVar
	C_CVar.SetCVar = function(name, value)
		if name == NPCS then return false end
		return real(name, value)
	end
	UF:RestoreNameplateCVars()
	eq(stub.cvars[PLAYERS], '1', 'the one it took is back')
	eq(record(st) and record(st)[PLAYERS], nil, 'and no longer recorded')
	eq(record(st) and record(st)[NPCS], '0', 'the refused one is still recorded')
	C_CVar.SetCVar = real
	UF:RestoreNameplateCVars()
	eq(stub.cvars[NPCS], '0', 'put back next time')
	eq(record(st), nil, 'the record cleared')
end)

test('Nameplates off before the reload: Friendly plates sets nothing, and a restore waiting out combat stands', function()
	local st, UF = world('forever')
	stub.cvars[PLAYERS], stub.cvars[NPCS] = '1', '0'
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	set(UF, 'enable', false)
	click(st.OptionsWidgets.GetDialogFrames().no)
	check(UF.plateDriver ~= nil, "the reload declined: SaftUI's plates still up")
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '10', "the user's settings back")
	local calls = watch_sets()
	set(UF, 'friendly', false)
	set(UF, 'friendly', true)
	UF:ApplyNameplateCVars()
	eq(#calls, 0, 'Friendly plates and applying set nothing')
	eq(record(st), nil, 'and record nothing')

	-- In combat: Nameplates goes off (the restore waits), then something
	-- applies (Friendly plates, in game). The restore still runs.
	st, UF = world('forever')
	stub.cvars[PLAYERS], stub.cvars[NPCS] = '1', '0'
	UF:SpawnNameplates()
	UF:ApplyNameplateCVars()
	stub.in_combat = true
	UF:GetProfileConfig().nameplate.enable = false
	UF:RestoreNameplateCVars()
	UF:ApplyNameplateCVars()
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '10', 'put back once combat ends')
	eq(record(st), nil, 'the record cleared')
end)

------------------------------------------------------------------ at login

test('Nameplates on at login: OnEnable spawns the plates and sets the game settings', function()
	local st, UF = world('forever')
	enable(UF)
	check(UF.plateDriver ~= nil, 'spawned')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', "SaftUI's friendly plates")
	eq(record(st)[PLAYERS] .. record(st)[NPCS], '00', "the user's recorded")

	-- A /reload in combat: they wait for the end of it.
	st, UF = world('forever')
	stub.in_combat = true
	enable(UF)
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '00', 'not in combat')
	eq(#stub.blocked, 0, 'nothing tried')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(stub.cvars[PLAYERS] .. stub.cvars[NPCS], '11', 'set once combat ends')
end)

test('Nameplates off at login with a record: it is put back. Stood down: nothing set or restored', function()
	local st, UF = world('forever')
	UF:GetProfileConfig().nameplate.enable = false
	st.config.char.nameplateCVars = { [PLAYERS] = '1' }
	stub.cvars[PLAYERS] = '0'
	enable(UF)
	eq(UF.plateDriver, nil, 'no plates')
	eq(stub.cvars[PLAYERS], '1', 'put back')
	eq(record(st), nil, 'the record cleared')

	-- No record: nothing to put back.
	st, UF = world('forever')
	UF:GetProfileConfig().nameplate.enable = false
	local calls = watch_sets()
	enable(UF)
	eq(#calls, 0, 'off with no record: nothing set')

	-- Another nameplate addon draws the plates, whatever Nameplates says.
	for _, on in ipairs({ true, false }) do
		st, UF = world('forever')
		stub.loaded_addons.Plater = true
		UF:GetProfileConfig().nameplate.enable = on
		st.config.char.nameplateCVars = { [PLAYERS] = '1' }
		stub.cvars[PLAYERS] = '0'
		calls = watch_sets()
		enable(UF)
		eq(UF.plateDriver, nil, 'stood down')
		eq(#calls, 0, 'Plater, Nameplates ' .. tostring(on) .. ': no C_CVar.SetCVar call')
		eq(record(st) and record(st)[PLAYERS], '1', 'the record kept')
		eq(stub.cvars[PLAYERS], '0', 'the setting left as it is')
	end
end)

------------------------------------------------------------------ standing down

test('another nameplate addon loaded: the page says which, and its options are disabled', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.loaded_addons.Plater = true
		local root, view = page(UF, { pick = 'nameplate' })
		local config = root.Unitframes.args.nameplate
		eq(config.disabled(), true, client .. ': the group is disabled')

		-- The window chooses no tab when every one is disabled, so the line
		-- sits above the tabs, where it shows whichever is chosen.
		local first = rows(view)[1]
		eq(first and first.type, 'description', client .. ': a line first')
		eq(first and first.name, "Nameplates are drawn by Plater. Turn it off to use SaftUI's.", client .. ': naming the addon')
		eq(first and first.disabled, false, client .. ': not dimmed')
		eq(view.tab, nil, client .. ': no tab chosen')
		check(#view.tabs > 1, client .. ': the tabs are there')
		for _, tab in ipairs(view.tabs) do
			check(tab.disabled, client .. ': ' .. tab.key .. ' is disabled')
		end

		-- On General: the line, then every row dimmed.
		root, view = page(UF)
		local list = rows(view)
		eq(list[1].name, "Nameplates are drawn by Plater. Turn it off to use SaftUI's.", client .. ': the line first on General too')
		for i = 2, #list do
			check(list[i].disabled, client .. ': ' .. list[i].key .. ' is disabled')
		end
		eq(#list, 8, client .. ': the line and General\'s seven rows')

		-- ElvUI's name, while its nameplates are on.
		st, UF = world(client)
		stub.loaded_addons.ElvUI = true
		ElvUI = { { private = { nameplates = { enable = true } } } }
		root, view = page(UF, { pick = 'nameplate' })
		eq(rows(view)[1].name, "Nameplates are drawn by ElvUI. Turn it off to use SaftUI's.", client .. ': ElvUI')
		local ok, err = pcall(LibStub('AceConfigRegistry-3.0').ValidateOptionsTable, LibStub('AceConfigRegistry-3.0'),
			ace_ready({ name = st.name, type = 'group', args = root }), st.name)
		check(ok, client .. ': valid: ' .. tostring(err))

		-- None: no line, nothing disabled.
		st, UF = world(client)
		root, view = page(UF, { pick = 'nameplate' })
		eq(root.Unitframes.args.nameplate.disabled(), false, client .. ': not disabled')
		eq(rows(view)[1].key, 'enable', client .. ': General first, no line')
		eq(view.tab, 'general', client .. ': General chosen')
	end
end)

------------------------------------------------------------------ the frame the Position editors place

test("UF:GetConfigFrame('nameplate') is the plate with the lowest number, or nil", function()
	local st, UF = world('forever')
	eq(UF:GetConfigFrame('nameplate'), nil, 'none before a plate shows')
	UF:SpawnNameplates()
	eq(UF:GetConfigFrame('nameplate'), nil, 'none before a plate shows, spawned')
	local one = NP.add('nameplate1')
	local two = NP.add('nameplate2')
	local three = NP.add('nameplate3')
	eq(UF:GetConfigFrame('nameplate'), one, 'NamePlate1\'s frame')
	UF.nameplates[1] = nil
	eq(UF:GetConfigFrame('nameplate'), two, 'the lowest left')
	local target = UF:ConfigTarget('nameplate', 'Health')
	eq(target(), two.Health, "an element's Position places it on that plate")
	check(three ~= nil, 'a third')
end)
