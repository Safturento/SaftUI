-- A frame's Position is the SECOND section of its /sui page or tab (owner,
-- 2026-11-15: "feels too important to be at the bottom"): right after the first
-- section, the one with Enable and the frame's basics. Walks every pick, tab
-- and sub tab of the pages whose real option tables a world here can build,
-- on both clients, with tests/lib/position_second.lua, and checks the rule
-- itself on small trees. (Every other page's own test walks it too: the reset
-- walk, tests/lib/reset_walk.lua, runs the same check on each page it
-- walks, in that test's world.)
--
-- Real: the options model, Tracker's, Action bars' and the unit frames' option
-- files with their modules' defaults.
-- Stand-ins: the action bars are plain frames and the unit frames' module is
-- tests/unitframes/uf_world.lua's module with its frames made by hand, as
-- unitframes/config_test.lua makes them.
local PS = load_test_file('lib/position_second.lua')
local TW = load_test_file('tracker/tracker_world.lua')

local function section(title, rows) return { title = title, rows = rows or { { type = 'toggle' } } } end

-- A tree of one page whose General tab has the given option args.
local function tree(args)
	return { Page = { type = 'group', name = 'Page', childGroups = 'tab', args = {
		general = { type = 'group', name = 'General', order = 1, args = args },
	} } }
end

local function inline(order, name)
	return { type = 'group', inline = true, order = order, name = name, args = { a = { type = 'toggle', name = 'A', order = 1 } } }
end

local function position(order, name)
	return { type = 'position', order = order, name = name or 'Position', get = function() end, set = function() end }
end

local function walk_model()
	reset_world()
	load_core_helpers()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
end

test('the checker: second passes; last of three, and first of two, fail; a lone Position passes', function()
	walk_model()
	local function problems(args) return (PS.problems(tree(args), 'Page')) end
	local rows = { enable = { type = 'toggle', name = 'Enable', order = 1 } }
	eq(#problems({ enable = rows.enable, position = position(1000) }), 0, 'rows then Position: two sections, Position second')
	eq(#problems({ enable = rows.enable, position = position(2), layout = inline(3, 'Layout'), text = inline(4, 'Text') }), 0,
		'rows, Position, then sections')
	eq(#problems({ enable = rows.enable, layout = inline(3, 'Layout'), text = inline(4, 'Text'), position = position(1000) }), 1,
		'Position last of four is a problem')
	eq(#problems({ position = position(0), enable = rows.enable, layout = inline(3, 'Layout') }), 1, 'Position first is a problem')
	eq(#problems({ position = position(1000) }), 0, 'a page that is only a Position has nothing before it')
end)

test('the checker: a part\'s Position is skipped and named, not checked', function()
	walk_model()
	local rows = { enable = { type = 'toggle', name = 'Enable', order = 1 } }
	local args = { enable = rows.enable, layout = inline(3, 'Layout'), text = inline(4, 'Text'),
		position = position(1000, 'Duration position') }
	local problems, found, skipped = PS.problems(tree(args), 'Page')
	eq(#problems, 0, 'Duration position last is left alone')
	eq(found, 0, 'no frame Position counted')
	eq(table.concat(skipped, ','), 'Page:general:Duration position', 'and named')
	-- On the Unitframes page every tab but General is an element's.
	local page = { Unitframes = { type = 'group', name = 'U', childGroups = 'tab', args = {
		general = { type = 'group', name = 'General', order = 1, args = { enable = rows.enable, position = position(2), layout = inline(3, 'Layout') } },
		castbar = { type = 'group', name = 'Castbar', order = 2, args = { enable = rows.enable, layout = inline(3, 'Layout'), position = position(1000) } },
	} } }
	local p2, found2, skipped2 = PS.problems(page, 'Unitframes')
	eq(#p2, 0, "an element tab's Position stays last")
	eq(found2, 1, "General's is the frame's")
	eq(table.concat(skipped2, ','), 'Unitframes:castbar:Position', "and the element tab's is named")
	-- The same tab on another page is the frame's, and checked.
	local p3 = PS.problems({ Other = page.Unitframes }, 'Other')
	eq(#p3, 1, 'on a page that is not the unit frames, the castbar tab is checked')
end)

-- The Positions this test leaves where their own section has them: a text's or an
-- icon's within a unit frame's bar tab (Health's and Power's Text position, the cast
-- bar's Spell name, Time and Icon, the auras' Timer and Count), built by
-- generators.uf_element_position. The bars' own Position (Health, Power, Power bar,
-- Additional power, Cast bar, Buffs, Debuffs) and General's are walked as the
-- frame's: the second section. The other parts are rows of General's Parts, whose
-- menus are no page. 'Unitframes:<tab>[/<sub tab>]:<title>', every one found on the
-- page for either client. A new text with a Position fails the match below: add it
-- here, and to PART_TITLES in lib/position_second.lua, if it is a part's.
-- (Auras' Duration and Stack count text positions, also left, are named by
-- PART_TITLES in lib/position_second.lua and walked in misc/options_pages_test.lua.)
local PART_POSITIONS = {
	'Unitframes:Auras/Buffs:Count position',
	'Unitframes:Auras/Buffs:Timer position',
	'Unitframes:Auras/Debuffs:Count position',
	'Unitframes:Auras/Debuffs:Timer position',
	'Unitframes:Castbar:Icon position',
	'Unitframes:Castbar:Spell name position',
	'Unitframes:Castbar:Time position',
	'Unitframes:Health:Text position',
	'Unitframes:Power/AdditionalPower:Text position',
	'Unitframes:Power/bar:Text position',
	'Unitframes:Power:Text position',
}

local function check_page(name, root, expect)
	local problems, found, skipped = PS.problems(root, name)
	for _, problem in ipairs(problems) do check(false, problem) end
	check(found >= (expect or 1), ('%s: %d frame Positions walked, at least %d expected'):format(name, found, expect or 1))
	return found, skipped
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test("Tracker: General's and the nearest item's Position are the second section, on " .. client, function()
		local st, TR = TW.world({ on = true, client = client })
		load_test_file('lib/options_walk.lua')
		load_saftui('SaftUI-Core/Config/optionsmodel.lua')
		local found = check_page('Tracker', { Tracker = TR:GetConfigTable() }, 2)
		eq(found, 2, "General's Position and the nearest item button's")
	end)
end

local AB_FILES = {
	'SaftUI-ActionBars/init.lua', 'SaftUI-ActionBars/shared.lua', 'SaftUI-ActionBars/skin.lua',
	'SaftUI-ActionBars/bars.lua', 'SaftUI-ActionBars/buttons.lua', 'SaftUI-ActionBars/petbar.lua',
	'SaftUI-ActionBars/stancebar.lua', 'SaftUI-ActionBars/bindings.lua', 'SaftUI-ActionBars/extras.lua',
	'SaftUI-ActionBars/textoptions.lua', 'SaftUI-ActionBars/options.lua',
}

for _, client in ipairs({ 'forever', 'retail' }) do
	test('Action bars: each bar has Position second and each extra button too, on ' .. client, function()
		use_client(client)
		load_core_helpers()
		local st = SaftUI
		load_test_file('actionbars/fixtures/libactionbutton.lua')
		load_saftui('SaftUI-ActionBars/config.lua')
		apply_defaults()
		for _, file in ipairs(AB_FILES) do load_saftui(file) end
		load_saftui('SaftUI-Core/Config/optionsmodel.lua')
		load_test_file('lib/options_walk.lua')
		local AB = st:GetModule('ActionBars')
		st:BindModuleConfig(AB, 'actionbars')
		AB:ConvertProfile()
		AB.bars, AB.extras = {}, {}
		for _, id in ipairs(AB.BAR_IDS) do
			AB.bars[id] = CreateFrame('Frame', AB:GetBarFrameName(id), UIParent)
			AB.bars[id].id, AB.bars[id].buttons = id, {}
			for i = 1, (id == 'pet' or id == 'stance') and 10 or 12 do AB.bars[id].buttons[i] = {} end
		end
		for _, id in ipairs(AB.EXTRA_IDS) do AB.extras[id] = CreateFrame('Frame', nil, UIParent) end
		AB.built = true
		-- Ten bars with a Position of their own (bars 1 to 8, pet, stance) and the extras'.
		check_page('ActionBars', { ActionBars = AB:GetConfigTable() }, 10 + #AB.EXTRA_IDS)
	end)
end

-- The unit frames' page, built as unitframes/config_test.lua builds it (its stand-ins are
-- described there): every unit's General tab, and the element tabs' Positions skipped.
for _, client in ipairs({ 'forever', 'retail' }) do
	test("Unit frames: General's Position is second for every unit, the elements' are left, on " .. client, function()
		use_client(client)
		load_core_helpers()
		load_saftui('SaftUI-Unitframes/config/position.lua')
		load_saftui('SaftUI-Unitframes/config/default.lua')
		for _, file in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
			'arena', 'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate' }) do
			load_saftui('SaftUI-Unitframes/config/units/' .. file .. '.lua')
		end
		apply_defaults()
		load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
		load_saftui('SaftUI-Core/Config/optionsmodel.lua')
		load_test_file('lib/options_walk.lua')
		local st = SaftUI
		local UF = load_test_file('unitframes/uf_world.lua').module()
		function UF:UpdateConfig() end
		UF.units, UF.groups, UF.holders = {}, {}, {}
		for _, unit in ipairs({ 'boss', 'focustarget', 'player', 'pettarget', 'target', 'pet', 'targettarget', 'focus' }) do
			UF.units[unit] = CreateFrame('Frame', nil, UIParent)
		end
		for _, group in ipairs({ 'raid40', 'party', 'raid10' }) do
			UF.groups[group] = CreateFrame('Frame', nil, UIParent)
			UF.holders[group] = CreateFrame('Frame', nil, UIParent)
		end
		UF.unit_strings = {
			player = 'Player', target = 'Target', targettarget = 'TargetTarget', focus = 'Focus',
			focustarget = 'FocusTarget', pet = 'Pet', pettarget = 'PetTarget', boss = 'Boss',
		}
		UF.group_strings = { party = 'Party', raid10 = 'Raid 10', raid40 = 'Raid 40' }
		UF.PLATE_UNITS = { nameplate = true, friendlynameplate = true }
		function UF.IsPlateUnit(unit) return UF.PLATE_UNITS[unit] == true end
		function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end
		load_saftui('SaftUI-Unitframes/config/profiles.lua')
		load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
		load_saftui('SaftUI-Unitframes/config/parts.lua')
		load_saftui('SaftUI-Unitframes/config/config.lua')
		load_saftui('SaftUI-Unitframes/updaters.lua')
		load_saftui('SaftUI-Unitframes/nameplates/nameplates.lua')
		load_saftui('SaftUI-Unitframes/nameplates/threat.lua')
		load_saftui('SaftUI-Unitframes/nameplates/options.lua')
		local OF = load_test_file('lib/options_files.lua')
		for _, path in ipairs(OF.Files('SaftUI-Unitframes/elements/')) do load_saftui(path) end
		UF.oUF = { Tags = { Events = {}, Methods = {} }, colors = { class = st.config.profile.colors.class } }
		load_string_format()
		load_saftui('SaftUI-Unitframes/tags.lua')
		load_saftui('SaftUI-Unitframes/nameplates/subtext.lua')

		-- 8 single units and 3 groups with a frame to move (boss's page has one for its five frames).
		local _, skipped = check_page('Unitframes', { Unitframes = UF:GetConfigTable() }, 11)
		local seen, names = {}, {}
		for _, name in ipairs(skipped) do
			if not seen[name] then seen[name] = true; names[#names + 1] = name end
		end
		table.sort(names)
		eq(table.concat(names, '\n'), table.concat(PART_POSITIONS, '\n'), "the element tabs' Positions left alone")
	end)
end
