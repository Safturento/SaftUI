-- The unit pages: each unit frame's /sui page from its parts (SaftUI-Unitframes/config/parts.lua,
-- config/config.lua): five tabs, General's Frame, Position and Parts sections, the parts as half
-- rows with a summary, a box and a menu of the very option tables the elements built, Health
-- text and Power text drawn on their tabs too (mirrors), and the safety rule of the work: the
-- page changes nothing a unit frame shows, and building, drawing or opening any of it writes
-- no saved setting.
--
-- Real: config_test.lua's world (page_world.lua): the real defaults, AceConfigRegistry, the
-- options model, widgets, body and window, the element files and the plate pages. Stand-in:
-- UF:UpdateConfig, which counts its calls (the real one needs oUF).
local PW = load_test_file('unitframes/page_world.lua').world()
local st, UF, OM, OW, W = PW.st, PW.UF, PW.OM, PW.OW, PW.W
load_editmode() -- the summary's tip is edit mode's words (EM.CoordinatesText)
local OB = st.OptionsBody
local P = load_test_file('lib/pixels.lua')
local C = load_test_file('lib/color_cost.lua')
local R = load_test_file('lib/reset_walk.lua')

local UNITS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate' }

local function tree() return { Unitframes = UF:GetConfigTable() } end

local function view_of(root, unit, tab, subtab)
	return OM.BuildView(root, 'Unitframes', { pick = unit, tab = tab, subtab = subtab })
end

local function keys_of(list)
	local out = {}
	for i, entry in ipairs(list) do out[i] = entry.key end
	return table.concat(out, ',')
end

-- The section titled title of a view ('-' for no title), and the keys of its rows.
local function titles(view)
	local out = {}
	for i, section in ipairs(view.sections) do out[i] = section.title or '-' end
	return table.concat(out, '|')
end

local function raw_count(t)
	local n, key = 0, next(t)
	while key ~= nil do n = n + 1; key = next(t, key) end
	return n
end

local function section_rows(view, title)
	for _, section in ipairs(view.sections) do
		if section.title == title then return keys_of(section.rows), section end
	end
end

local function parts_of(root, unit)
	return root.Unitframes.args[unit].args.general.args.parts
end

local function part_item(root, unit, key)
	return parts_of(root, unit).args[key]
end

------------------------------------------------------------------ the tabs

test("each unit's tabs: General, Health, Power, Cast bar and Auras, with the second rows under Power and Auras", function()
	local root = tree()
	local FIVE = 'general,Health,Power,Castbar,Auras'
	for _, unit in ipairs({ 'target', 'focus', 'pet', 'boss', 'party', 'raid10', 'raid40' }) do
		eq(keys_of(view_of(root, unit).tabs), FIVE, unit .. ': five tabs')
	end
	eq(keys_of(view_of(root, 'player').tabs), FIVE, 'player: five tabs')
	for _, unit in ipairs({ 'targettarget', 'focustarget', 'pettarget' }) do
		eq(keys_of(view_of(root, unit).tabs), 'general,Health,Power,Auras', unit .. ': no cast bar on a unit\'s target')
	end
	for _, unit in ipairs({ 'nameplate', 'friendlynameplate' }) do
		eq(keys_of(view_of(root, unit).tabs), 'general,Health,Castbar,Auras', unit .. ': a plate has no power bar')
	end

	-- Cast bar is the tab's name; its key and its saved keys stay.
	eq(root.Unitframes.args.player.args.Castbar.name, 'Cast bar', "the tab's name")
	eq(UF:GetProfileConfig().player.castbar ~= nil, true, 'saved under castbar, as before')

	-- Player's Power has a second row, Power bar and Additional power; no other unit's has.
	local power = view_of(root, 'player', 'Power')
	eq(keys_of(power.subtabs), 'bar,AdditionalPower', "player's Power: its second row")
	eq(power.subtab, 'bar', 'opens on the bar')
	local names = {}
	for i, entry in ipairs(power.subtabs) do names[i] = entry.name end
	eq(table.concat(names, ','), 'Power bar,Additional power', 'named')
	for _, unit in ipairs({ 'target', 'party', 'boss' }) do
		eq(#view_of(root, unit, 'Power').subtabs, 0, unit .. ': no second row under Power')
	end

	-- Auras: Buffs and Debuffs, on every unit with an Auras tab.
	for _, unit in ipairs(UNITS) do
		local auras = view_of(root, unit, 'Auras')
		eq(keys_of(auras.subtabs), 'Buffs,Debuffs', unit .. ': Auras has Buffs and Debuffs')
	end
end)

test('a second row draws one sub tab at a time: the selected one only, not both stacked', function()
	local root = tree()
	local buffs = view_of(root, 'target', 'Auras', 'Buffs')
	local debuffs = view_of(root, 'target', 'Auras', 'Debuffs')
	for _, view in ipairs({ buffs, debuffs }) do
		local seen = {}
		for _, section in ipairs(view.sections) do
			for _, row in ipairs(section.rows) do seen[row.path[4]] = true end
		end
		eq(seen.Buffs and seen.Debuffs, nil, 'not both at once')
	end
	check(buffs.sections[1].rows[1].path[4] == 'Buffs' and debuffs.sections[1].rows[1].path[4] == 'Debuffs', 'each its own')
	-- Power bar and Additional power.
	local bar = view_of(root, 'player', 'Power', 'bar')
	local more = view_of(root, 'player', 'Power', 'AdditionalPower')
	eq(bar.sections[1].rows[1].path[4], 'bar', 'the bar')
	eq(more.sections[1].rows[1].path[4], 'AdditionalPower', 'Additional power')
end)

-- The bars' tabs: the size line (Width, Relative, Height, Relative: an untitled group) stays in the bar's first
-- section, and Position is the next panel, after it (spec section 1).
test("Health, Power bar and Additional power: Position comes after the bar's settings and the size line", function()
	local root = tree()
	for _, case in ipairs({ { 'target', 'Health' }, { 'player', 'Health' }, { 'target', 'Power' }, { 'player', 'Power', 'bar' },
			{ 'player', 'Power', 'AdditionalPower' }, { 'nameplate', 'Health' } }) do
		local view = view_of(root, case[1], case[2], case[3])
		local where = table.concat(case, '.')
		local at, sawWidth, sawFill
		for i, section in ipairs(view.sections) do
			for _, row in ipairs(section.rows) do
				if row.key == 'width' then sawWidth = i end
				if row.key == 'reverse_fill' or row.key == 'enable' then sawFill = sawFill or i end
				if row.type == 'position' and not at then at = i end
			end
		end
		check(at ~= nil and sawWidth ~= nil, where .. ': has a Position and a size line')
		check(sawWidth < at, where .. ': the size line (section ' .. tostring(sawWidth) .. ') is before Position (' .. tostring(at) .. ')')
		eq(sawFill, 1, where .. ': the bar rows are the first section')
		-- Position is the second panel: only untitled sections (the size line) stand between.
		for i = 2, at - 1 do eq(view.sections[i].title, nil, where .. ': section ' .. i .. ' before Position is an untitled continuation') end
	end
end)

------------------------------------------------------------------ the Parts rows

local PARTS = {
	player = 'name,healthtext,powertext,classpower,raidtarget,raidrole,grouprole,quest',
	group = 'name,healthtext,powertext,raidtarget,raidrole,grouprole,readycheck,quest',
	single = 'name,healthtext,powertext,raidtarget,raidrole,grouprole,quest',
	nameplate = 'name,subtext,healthtext,threat,raidtarget,quest',
	friendlynameplate = 'name,subtext,healthtext,raidtarget,quest',
}

test("each unit's Parts rows, in order: half rows with a summary, a menu and a title", function()
	local root = tree()
	local want = {
		player = PARTS.player, party = PARTS.group, raid10 = PARTS.group, raid40 = PARTS.group,
		nameplate = PARTS.nameplate, friendlynameplate = PARTS.friendlynameplate,
	}
	for _, unit in ipairs({ 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss' }) do want[unit] = PARTS.single end
	for _, unit in ipairs(UNITS) do
		local rows = section_rows(view_of(root, unit), 'Parts')
		eq(rows, want[unit], unit .. ': the Parts, in order')
		for key, item in pairs(parts_of(root, unit).args) do
			local where = unit .. ' ' .. key
			eq(item.type, 'item', where .. ': an item')
			eq(item.size, nil, where .. ': no size: a half row')
			eq(item.resetsMenu, nil, where .. ': no whole-part reset: its reset is its box\'s')
			eq(item.menuTitle, item.name, where .. ': its menu is titled with its name')
			eq(type(item.summary), 'function', where .. ': a summary')
			eq(type(item.menu), 'table', where .. ': a menu')
			eq(item.menu.args.enable, nil, where .. ': Enable is the box, not in the menu')
			eq(item.order, UF.PartFor(key) and (function()
				for index, part in ipairs(UF.PARTS) do if part.key == key then return index end end
			end)(), where .. ': at its place in UF.PARTS')
			check(type(item.desc) == 'string' and item.desc ~= '', where .. ': a desc')
		end
	end
	-- UF.UnitParts is the same list.
	for _, unit in ipairs(UNITS) do
		local keys = {}
		for i, part in ipairs(UF.UnitParts(unit)) do keys[i] = part.key end
		local rows = {}
		for key in pairs(parts_of(root, unit).args) do rows[#rows + 1] = key end
		local wantKeys = {}
		for key in want[unit]:gmatch('[^,]+') do wantKeys[#wantKeys + 1] = key end
		-- Additional power is a tab, so it is a part of Player but no row.
		local without = {}
		for _, key in ipairs(keys) do if key ~= 'additionalpower' then without[#without + 1] = key end end
		eq(table.concat(without, ','), want[unit], unit .. ': UF.UnitParts')
	end
end)

test("General's sections: Frame, Position, Layout and Range where a group has them, then Parts", function()
	local root = tree()
	eq(titles(view_of(root, 'player')), 'Frame|Position|Parts', 'player')
	eq(titles(view_of(root, 'target')), 'Frame|Position|Parts', 'target')
	eq(titles(view_of(root, 'boss')), 'Frame|Position|Layout|Parts', 'boss: Layout')
	for _, unit in ipairs({ 'party', 'raid10', 'raid40' }) do
		eq(titles(view_of(root, unit)), 'Frame|Position|Layout|Range|Parts', unit .. ': Layout and Range')
	end
	eq(select(1, section_rows(view_of(root, 'player'), 'Frame')), 'enable,theme,background,width,height', "Frame's rows")
	eq(select(1, section_rows(view_of(root, 'party'), 'Layout')), 'test_mode,showPlayer,growthDirection,initialAnchor,spacing,columnSpacing,unitsPerColumn,maxColumns',
		"Party's Layout")
	eq(select(2, section_rows(view_of(root, 'player'), 'Parts')).note, 'Each text, icon and small part of the unit frame. The dots open its settings.',
		"the Parts section's note")
	-- The nameplate pages keep their own General, with a Parts section last (their box's rules are Task 5's).
	eq(titles(view_of(root, 'nameplate')), '-|Parts', 'Enemy nameplates: their own rows, then Parts')
	eq(titles(view_of(root, 'friendlynameplate')), '-|Parts', 'Friendly nameplates')
	-- The raid groups' Enable says what hiding Blizzard's raid frames does, at its new place.
	local enable = root.Unitframes.args.raid10.args.general.args.frame.args.enable
	check(enable.desc:find("Blizzard's raid frames are hidden", 1, true) ~= nil, "the raid groups' Enable desc")
	-- The mover's path still ends at General, and General's Position is the unit's own.
	eq(root.Unitframes.args.player.args.general.args.position.type, 'position', 'the frame Position stays a child of General')
end)

------------------------------------------------------------------ a part row is its element's options

-- The element's own group for a unit, as its GetConfigTable builds it.
local function element_group(unit, element)
	return UF.elements[element].GetConfigTable(unit)
end

test("a part row is its element's options: the box its Enable, the menu every other row, the same tables", function()
	local root = tree()
	local P_ = UF:GetProfileConfig()
	for _, unit in ipairs({ 'player', 'target', 'party', 'boss' }) do
		for _, part in ipairs(UF.UnitParts(unit)) do
			if part.place == 'row' and not part.sub then
				local item = part_item(root, unit, part.key)
				local group = element_group(unit, part.element)
				local where = unit .. ' ' .. part.key
				-- Every option of the element's group but Enable is in the menu, as a table of its own kind.
				for key, option in pairs(group.args) do
					if key ~= 'enable' then
						check(item.menu.args[key] ~= nil, where .. ': ' .. key .. ' is in the menu')
						eq(item.menu.args[key].type, option.type, where .. ': ' .. key .. ' keeps its type')
						eq(item.menu.args[key].name, option.name, where .. ': ' .. key .. ' keeps its name')
					end
				end
				for key in pairs(item.menu.args) do
					check(group.args[key] ~= nil and key ~= 'enable', where .. ': ' .. key .. ' is one of the element\'s')
				end
				-- The menu carries what its options inherit.
				eq(type(item.menu.get), 'function', where .. ': the menu has the group\'s get')
				eq(type(item.menu.set), 'function', where .. ': and its set')
				eq(type(item.menu.saved), 'function', where .. ': and its saved')
				eq(item.menu.name, part.name, where .. ': named for the part')
				eq(item.menu.inline, nil, where .. ': not inline')
			end
		end
	end

	-- The box is the part's Enable: it reads it, and a set writes it and re-applies the part.
	local item = part_item(root, 'player', 'name')
	local name = P_.player.name
	local before = name.enable
	eq(item:get(), before, 'the box reads name.enable')
	eq(item.menu.args.enable, nil, 'no Enable in the menu')
	local n = PW.updates
	local calls = {}
	local real = UF.UpdateConfig
	function UF:UpdateConfig(unit, element) calls[#calls + 1] = tostring(unit) .. ':' .. tostring(element); return real(self, unit, element) end
	item.set(nil, not before)
	UF.UpdateConfig = real
	eq(name.enable, not before, 'a set writes name.enable')
	eq(table.concat(calls, ','), 'player:Name', 'and applies the Name element for the unit')
	item.set(nil, before)
	-- Through the model, as the window sets it.
	local row = { path = { 'Unitframes', 'player', 'general', 'parts', 'name' }, option = item, type = 'item', key = 'name' }
	check(OM.Set(root, row, not before), 'OM.Set writes it')
	eq(name.enable, not before, 'name.enable')
	OM.Set(root, row, before)
	eq(name.enable, before, 'and back')
	eq(OM.Get(root, row), before, 'OM.Get reads it')

	-- A menu row reads and writes the element's own key through the menu's get and set.
	local menuRoot = OM.MenuRoot(item)
	local font = { path = { OM.MENU_KEY, 'allCaps' }, option = item.menu.args.allCaps, type = 'toggle', key = 'allCaps' }
	eq(OM.Get(menuRoot, font), name.allCaps, "All caps reads name.allCaps through the menu's get")
	local caps = name.allCaps
	OM.Set(menuRoot, font, not caps)
	eq(name.allCaps, not caps, 'and writes it')
	name.allCaps = caps

	-- Subtext has no Enable: no box (its room kept), no saved of its own.
	local subtext = part_item(root, 'nameplate', 'subtext')
	eq(subtext.get, false, 'Subtext: get is false')
	eq(subtext.reserveBox, true, 'its box room is kept')
	eq(subtext.saved, nil, 'no saved: there is no setting for the box')
	eq(subtext.set, nil, 'no set')
	eq(subtext.menu.args.enable, nil, 'no Enable in its menu either')
	check(subtext.menu.args.npc ~= nil and subtext.menu.args.position ~= nil, 'its menu holds its settings')
	-- Other parts' boxes are saved where their Enable always was.
	local expect = { name = 'name', raidtarget = 'raidtargetindicator', quest = 'questindicator', classpower = 'classpower' }
	for key, config in pairs(expect) do
		local saved = { part_item(root, 'player', key).saved({}) }
		eq(table.concat(saved, '.'), 'unitframes.profiles.' .. UF:GetProfile() .. '.player.' .. config .. '.enable', key .. ': saved')
	end
	local text = { part_item(root, 'player', 'healthtext').saved({}) }
	eq(table.concat(text, '.'), 'unitframes.profiles.' .. UF:GetProfile() .. '.player.health.text.enable', 'Health text: saved under health.text')
end)

------------------------------------------------------------------ every row has a home

-- The saved path of the value row at path in root, as the options kit finds it (the nearest group
-- with a get of its own that gives a saved), or nil.
local function saved_of(root, path)
	local group, node = { args = root }, nil
	for _, key in ipairs(path) do
		group = OM.SubOption(group, key)
		if not group then return nil end
		if group.get ~= nil and not OM.HandsOn(group) then node = group end
	end
	if node and type(node.saved) == 'function' then return table.concat({ node.saved(OM.Info(root, path)) }, '.') end
end

local NOT_VALUE = { group = true, header = true, description = true, execute = true }

-- Adds one entry per value row under group (at path in root) to counts: its saved path, else its
-- name and desc. A group that says mirrorOf is left out (its rows are its part's, counted there);
-- an item counts its box (when it has one) and then its menu's rows.
local function count_rows(counts, root, group, path)
	for key, option in pairs(group.args or {}) do
		local at = { unpack(path) }
		at[#at + 1] = key
		if option.type == 'group' then
			if not option.mirrorOf then count_rows(counts, root, option, at) end
		elseif option.type == 'item' then
			if option.get ~= false and option.saved then
				local id = saved_of(root, at) or ('box:' .. option.name)
				counts[id] = (counts[id] or 0) + 1
			end
			if option.menu then
				local menuRoot = OM.MenuRoot(option)
				count_rows(counts, menuRoot, option.menu, { OM.MENU_KEY })
			end
		elseif not NOT_VALUE[option.type] then
			local id = saved_of(root, at) or ('nosaved:' .. tostring(option.name) .. '|' .. tostring(option.desc))
			counts[id] = (counts[id] or 0) + 1
		end
	end
end

local function total(counts)
	local n = 0
	for _, count in pairs(counts) do n = n + count end
	return n
end

local function differences(a, b)
	local out = {}
	for id, count in pairs(a) do
		if b[id] ~= count then out[#out + 1] = ('%s: %d before, %d after'):format(id, count, b[id] or 0) end
	end
	for id, count in pairs(b) do
		if a[id] == nil then out[#out + 1] = ('%s: 0 before, %d after'):format(id, count) end
	end
	table.sort(out)
	return out
end

test("every row of today's pages has a home: the saved paths of the value rows are the same, the mirrors counted once", function()
	local grand = 0
	for _, unit in ipairs(UNITS) do
		local root = tree()
		local page = root.Unitframes.args[unit]
		-- Before: General as it is without its Parts, and each element's group as it built it, one per
		-- tab, which is where the old page had them.
		local before = {}
		local general = {}
		for key, option in pairs(page.args.general.args) do
			if key ~= 'parts' then general[key] = option end
		end
		count_rows(before, root, { args = general, type = 'group' }, { 'Unitframes', unit, 'general' })
		for element, registered in pairs(UF.elements) do
			if registered.GetConfigTable and (not registered.ValidUnit or registered.ValidUnit(unit)) then
				local group = registered.GetConfigTable(unit)
				local scratch = { Unitframes = { type = 'group', name = 'x', args = { [unit] = { type = 'group', name = unit, args = { [element] = group } } } } }
				count_rows(before, scratch, group, { 'Unitframes', unit, element })
			end
		end
		-- After: the page as it is, whole.
		local after = {}
		count_rows(after, root, page, { 'Unitframes', unit })
		local diff = differences(before, after)
		eq(#diff, 0, unit .. ': ' .. table.concat(diff, '; '):sub(1, 400))
		check(total(after) > 100, unit .. ': rows walked: ' .. total(after))
		grand = grand + total(after)
	end
	check(grand > 1000, 'every unit: ' .. grand)
end)

------------------------------------------------------------------ Health text and Power text, in two places

test("Health text and Power text: the tab's Text section is the part's very tables", function()
	local root = tree()
	for _, case in ipairs({ { 'player', 'Health', 'healthtext' }, { 'target', 'Health', 'healthtext' },
			{ 'party', 'Power', 'powertext' }, { 'boss', 'Power', 'powertext' }, { 'nameplate', 'Health', 'healthtext' } }) do
		local unit, tab, key = case[1], case[2], case[3]
		local item = part_item(root, unit, key)
		local text = root.Unitframes.args[unit].args[tab].args.text
		local where = unit .. ' ' .. tab
		eq(table.concat(text.mirrorOf, '.'), 'general.parts.' .. key, where .. ': the Text section says it mirrors the part')
		check(OM.MirrorOf(root, { 'Unitframes', unit, tab, 'text' }) ~= nil, where .. ': the model resolves it')
		eq(table.concat(OM.MirrorOf(root, { 'Unitframes', unit, tab, 'text' }), '.'), 'Unitframes.' .. unit .. '.general.parts.' .. key, where .. ': to the part row')
		local leaves = 0
		for leaf, option in pairs(text.args) do
			if leaf ~= 'enable' then
				leaves = leaves + 1
				check(rawequal(option, item.menu.args[leaf]), where .. ': ' .. leaf .. ' is the menu\'s own table')
			end
		end
		for leaf in pairs(item.menu.args) do
			check(text.args[leaf] ~= nil, where .. ': the menu\'s ' .. leaf .. ' is on the tab too')
		end
		check(leaves >= 5, where .. ': leaves compared: ' .. leaves)
		-- The tab keeps the part's Enable, saved where the box is.
		check(text.args.enable ~= nil, where .. ': the Text section keeps its Enable')
		-- The tab's group carries what the rows inherit, so each has its reset there.
		eq(type(text.get), 'function', where .. ': get'); eq(type(text.set), 'function', where .. ': set')
		eq(type(text.saved), 'function', where .. ': saved')
		-- A change through the menu shows on the tab, and the other way: one value.
		local config = unit == 'nameplate' and UF:GetProfileConfig().nameplate or UF:GetProfileConfig()[unit]
		local store = config[tab:lower()].text
		local toggle = 'hide_full'
		local menuRoot = OM.MenuRoot(item)
		local viaMenu = { path = { OM.MENU_KEY, toggle }, option = item.menu.args[toggle], type = 'toggle', key = toggle }
		local viaTab = { path = { 'Unitframes', unit, tab, 'text', toggle }, option = text.args[toggle], type = 'toggle', key = toggle }
		local was = store[toggle]
		OM.Set(menuRoot, viaMenu, not was)
		eq(OM.Get(root, viaTab), not was, where .. ': set in the menu, read on the tab')
		OM.Set(root, viaTab, was)
		eq(OM.Get(menuRoot, viaMenu), was, where .. ': set on the tab, read in the menu')
		eq(store[toggle], was, where .. ': one stored value')
	end
	-- The part is the one search finds: the tab's Text rows are left out.
	local hits = OM.Search(tree(), 'Hide full')
	local seen = {}
	for _, hit in ipairs(hits) do
		local at = table.concat(hit.path, '.')
		if hit.path[2] == 'player' then
			check(not at:find('%.Health') and not at:find('%.Power%.bar'), 'not found again on a tab: ' .. at)
			if hit.path[3] == 'general' then seen[#seen + 1] = at end
		end
	end
	table.sort(seen)
	eq(table.concat(seen, ','), 'Unitframes.player.general.parts.healthtext,Unitframes.player.general.parts.powertext',
		"Hide full is found once at each text part, not again on the Health and Power tabs")
end)

------------------------------------------------------------------ the summary

test("the summary names the anchor, and its tip the whole position", function()
	local root = tree()
	local config = UF:GetProfileConfig()
	local function summary(unit, key, info)
		return part_item(root, unit, key).summary(info or {})
	end
	-- Defaults: the health text sits on the health bar, the class power on the screen, a name in the unit frame.
	config.player.health.text.position = { point = 'RIGHT', rel_point = 'RIGHT', element = 'Health', x_off = -7, y_off = -1 }
	local word, tip = summary('player', 'healthtext')
	eq(word, 'Health', "player's Health text: the anchor")
	eq(tip, 'Right of Health: -7, -1', 'and the full position in its tip')
	-- The tip names an element as the page does (L16): "Cast bar", not the key Castbar.
	config.player.name.position = { point = 'LEFT', rel_point = 'RIGHT', element = 'Castbar', x_off = 2, y_off = 3 }
	local _, castTip = summary('player', 'name')
	eq(castTip, 'Left to right of Cast bar: 2, 3', "the tip's namer is UF.ELEMENT_NAMES")
	eq((summary('player', 'classpower')), 'Screen', "player's Class power sits on the screen")
	eq((summary('party', 'name')), 'Health', "party's Name is on the Health bar")
	eq((summary('player', 'raidtarget')), 'Unit frame', "Raid target sits in the unit frame")
	-- The words: an element by its name as the pages name it, the screen, a unit's frame, another frame, the unit frame.
	local function word_of(position) return UF.PartAnchorWord('player', position) end
	eq(word_of({ point = 'LEFT', element = 'Castbar' }), 'Cast bar', 'an element, as the page names it')
	eq(word_of({ point = 'LEFT', element = 'ClassPower' }), 'Class power', 'two words')
	eq(word_of({ point = 'LEFT', element = 'AdditionalPower' }), 'Additional power', 'Additional power')
	eq(word_of({ point = 'LEFT', element = 'RaidTargetIndicator' }), 'Raid target', 'an indicator by its label')
	eq(word_of({ point = 'LEFT', frame = 'UIParent' }), 'Screen', 'UIParent')
	eq(word_of({ point = 'LEFT', frame = 'SaftUI_Player' }), 'Player', "SaftUI_Player is Player's frame")
	eq(word_of({ point = 'LEFT', frame = 'SaftUI_Raid10' }), 'Raid 10', 'a group by its page name')
	eq(word_of({ point = 'LEFT', frame = 'MyFrame' }), 'MyFrame', 'another frame as it was typed')
	eq(word_of({ point = 'LEFT', frame = false, element = false }), 'Unit frame', 'cleared keys: the unit frame')
	eq(word_of({ point = 'LEFT' }), 'Unit frame', 'nothing: the unit frame')
	eq(word_of('nothing'), nil, 'no position, no word')
	-- A part anchored to the player's frame.
	config.player.questindicator.position = { point = 'LEFT', rel_point = 'RIGHT', frame = 'SaftUI_Player', x_off = 2, y_off = 0 }
	eq((summary('player', 'quest')), 'Player', 'a part anchored to SaftUI_Player')
	-- An element the unit does not have falls back as the frame places it: to the unit frame.
	eq(UF.PartAnchorWord('targettarget', { point = 'LEFT', element = 'Castbar' }), 'Unit frame', "targettarget has no Cast bar")
	-- The summary only reads: nothing written, no table of the profile made.
	local before = raw_count(config.player.questindicator.position)
	summary('player', 'quest')
	eq(raw_count(config.player.questindicator.position), before, 'reads only')
end)

test('search still finds the Cast bar tab by its old word, Castbar', function()
	local hits = OM.Search(tree(), 'Castbar')
	local rows = 0
	for _, hit in ipairs(hits) do
		if hit.path[2] == 'player' and hit.path[3] == 'Castbar' then rows = rows + 1 end
	end
	check(rows > 5, "'Castbar' finds the Cast bar tab's rows: " .. rows)
	check(#OM.Search(tree(), 'Cast bar') > 0, 'and its new name')
end)

------------------------------------------------------------------ the menus' size

local function in_look(look, fn)
	local was = st.config.profile.theme.name
	st.config.profile.theme.name = look
	local ok, err = pcall(fn)
	W.CloseList()
	OW:CloseMenu()
	st.config.profile.theme.name = was
	stub.cursor_x, stub.cursor_y = 0, 0
	stub.size_noise = 0
	if not ok then error(err, 0) end
end

-- General drawn in a body on its own, for the part rows' widgets.
local function draw_general(root, unit, width, half)
	width = width or 774
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(width, 900)
	local body = OB.New(content, root, nil, width)
	if half then body:SetWidth(width, true) end
	body:Draw(view_of(root, unit).sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

for _, unit in ipairs(UNITS) do
	test(unit .. ": each part menu fits the rule (Ruling 26): under Thick at full size, no taller than the options window's least height", function()
		in_look('thick', function()
			local root = tree()
			local limit = OW.LAYOUT.own.height
			eq(limit, 700, 'the rule is 700')
			local body, by = draw_general(root, unit)
			local opened = 0
			for key, cell in pairs(by) do
				if cell.row.type == 'item' and cell.widget.isPart then
					check(cell.widget:OpenMenu(), unit .. ' ' .. key .. ': the menu opens')
					local frame = OW.GetMenuFrames().frame
					local height = frame:GetHeight()
					check(height <= limit, ("%s's menu is %d tall on %s, over the %d rule: declare it a tab in UF.PARTS"):format(key, height, unit, limit))
					-- Fixed row metrics: a note or a description row would make the height depend on the text.
					local menu = cell.row.option.menu
					for leaf, option in pairs(menu.args) do
						check(option.type ~= 'description', unit .. ' ' .. key .. ': ' .. leaf .. ' is no description row')
					end
					OW:CloseMenu()
					opened = opened + 1
				end
			end
			check(opened >= 5, unit .. ': menus opened: ' .. opened)
			body:Release()
		end)
	end)
end

test("Additional power is a page: its menu, were it a row, is over the rule", function()
	in_look('thick', function()
		local root = tree()
		local part = UF.PartFor('additionalpower')
		eq(part.place, 'tab', 'declared a tab')
		eq(part.under, 'Power', 'under Power')
		-- Built as a row, its menu is over 700 (so it is a tab): measure it here, off the page.
		local group = element_group('player', 'AdditionalPower')
		local item = UF.PartRow('player', part, group, 7)
		local menuRoot = OM.MenuRoot(item)
		local content = CreateFrame('Frame', nil, UIParent)
		content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
		content:SetSize(376, 2000)
		local body = OB.New(content, menuRoot, nil, 376)
		body:SetWidth(376, true)
		body:Draw(OM.BuildView(menuRoot, OM.MENU_KEY).sections)
		local bottom = 0
		for _, c in ipairs(body.cells) do bottom = math.max(bottom, c.y + (c.frame:GetHeight() or 0)) end
		check(bottom > OW.LAYOUT.own.height, 'its rows alone are ' .. bottom .. ' tall, over the rule')
		body:Release()
	end)
end)

------------------------------------------------------------------ declaring a part a tab

test("declaring a part a tab moves it and nothing else: the tables are the same, the saved paths the same", function()
	local part = UF.PartFor('classpower')
	eq(part.place, 'row', 'a row by default')
	-- The same group as a row and as a tab: the one set of option tables.
	local group = element_group('player', 'ClassPower')
	local item = UF.PartRow('player', part, group, 6)
	local tab = UF.PartTab('player', part, group)
	for key, option in pairs(item.menu.args) do
		check(rawequal(tab.args[key], option), key .. ' is the same table in the menu and on the tab')
	end
	for key in pairs(tab.args) do
		check(key == 'enable' or item.menu.args[key] ~= nil, key .. ' is on both')
	end
	check(tab.args.enable ~= nil, 'the tab keeps its Enable, first')
	eq(tab.inline, false, 'a tab is not inline')
	eq(tab.name, 'Class power', 'named for the part')

	-- On the page: Player gains the ClassPower tab, Parts loses the row; every other row stays.
	local rows = {}
	local counts = {}
	local root = tree()
	count_rows(counts, root, root.Unitframes.args.player, { 'Unitframes', 'player' })
	local beforeTotal = total(counts)
	eq(keys_of(view_of(root, 'player').tabs), 'general,Health,Power,Castbar,Auras', 'five tabs with a row')
	part.place = 'tab'
	local ok, err = pcall(function()
		local moved = tree()
		eq(keys_of(view_of(moved, 'player').tabs), 'general,Health,Power,ClassPower,Castbar,Auras', 'ClassPower is a tab now')
		eq(section_rows(view_of(moved, 'player'), 'Parts'), 'name,healthtext,powertext,raidtarget,raidrole,grouprole,quest', 'and not a row')
		local after = {}
		count_rows(after, moved, moved.Unitframes.args.player, { 'Unitframes', 'player' })
		local diff = differences(counts, after)
		eq(#diff, 0, 'the same value rows, the same saved paths: ' .. table.concat(diff, '; '):sub(1, 300))
		eq(total(after), beforeTotal, 'as many')
	end)
	part.place = 'row'
	if not ok then error(err, 0) end
	-- Put back.
	eq(keys_of(view_of(tree(), 'player').tabs), 'general,Health,Power,Castbar,Auras', 'a row again')
end)

test("a part declared under a tab the unit does not have is reported once and kept as a tab of its own, not dropped", function()
	local part = UF.PartFor('additionalpower')
	local was = part.under
	part.under = 'NoSuchTab'
	local handler, reports = geterrorhandler(), {}
	seterrorhandler(function(message) reports[#reports + 1] = tostring(message) end)
	local ok, err = pcall(function()
		local root = tree()
		eq(keys_of(view_of(root, 'player').tabs):find('AdditionalPower', 1, true) ~= nil, true, 'its settings are a tab of their own')
		eq(keys_of(view_of(root, 'target').tabs):find('AdditionalPower', 1, true), nil, 'other units have no such part')
	end)
	seterrorhandler(handler)
	part.under = was
	if not ok then error(err, 0) end
	eq(#reports, 1, 'reported once: ' .. table.concat(reports, ' | '))
	check(reports[1] and reports[1]:find('NoSuchTab', 1, true), 'naming the missing tab')
end)

------------------------------------------------------------------ whole pixels

test('whole pixels: Player General and its Name menu under Thick, Thin and Blizzard, at full size and half', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			in_look(look, function()
				stub.size_noise = noise
				for _, half in ipairs({ false, true }) do
					local root = tree()
					local width = half and (look == 'blizzard' and 368 or 388) or 774
					local body, by, content = draw_general(root, 'player', width, half)
					local where = ('%s, noise %s, %s'):format(look, noise, half and 'half' or 'full')
					local off = P.off(content)
					eq(#off, 0, where .. ': General: ' .. P.report(off))
					check(by.name and by.name.widget.isPart, where .. ': the Name part row')
					-- The Name menu, whole.
					check(by.name.widget:OpenMenu(), where .. ': the Name menu opens')
					local frame = OW.GetMenuFrames().frame
					off = P.off(frame)
					eq(#off, 0, where .. ': the Name menu: ' .. P.report(off))
					OW:CloseMenu()
					body:Release()
				end
			end)
		end
	end
end)

test("the Position block of a part's menu fits the cell under Thick, Thin and Blizzard", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			local root = tree()
			local body, by = draw_general(root, 'player')
			check(by.name.widget:OpenMenu(), look .. ': opens')
			local frames = OW.GetMenuFrames()
			local menuBody = frames.body
			local block
			for _, cell in ipairs(menuBody.cells) do
				if cell.row.type == 'position' then block = cell end
			end
			if check(block ~= nil, look .. ': the Position block is drawn') then
				-- The block's own widgets (its X and Y steppers sit at its right), not the row's frame.
				local cellRight = block.frame:GetRight()
				local widgetRight = block.widget.frame:GetRight()
				local function deepest(frame, right)
					for _, child in ipairs({ frame:GetChildren() }) do
						if child:IsShown() and child:GetRight() then right = math.max(right, child:GetRight()) end
						right = deepest(child, right)
					end
					return right
				end
				local right = deepest(block.widget.frame, widgetRight)
				check(right <= cellRight + 0.01, ('%s: the block ends at %s, past its cell at %s'):format(look, tostring(right), tostring(cellRight)))
			end
			OW:CloseMenu()
			body:Release()
		end)
	end
end)

test("the Position block's TO dropdown is sized to its column: the name box under it is as wide, and the gap after it is 12", function()
	in_look('thick', function()
		local root = tree()
		local body, by = draw_general(root, 'player')
		check(by.name.widget:OpenMenu(), 'opens')
		local menuBody = OW.GetMenuFrames().body
		local block
		for _, cell in ipairs(menuBody.cells) do
			if cell.row.type == 'position' then block = cell end
		end
		if check(block ~= nil, 'the Position block is drawn') then
			local w = block.widget
			eq(w.select:GetWidth(), 136, 'the dropdown is selectWidth wide, not 140')
			eq(w.name:GetWidth(), w.select:GetWidth(), 'the name box under it as wide')
			eq(w.atSquare:GetLeft() - w.select:GetRight(), 12, 'the gap after the dropdown')
		end
		OW:CloseMenu()
		body:Release()
	end)
end)

------------------------------------------------------------------ the standing checks

-- A deep copy that reads only what is there (next, no __index: AceDB's wildcard makes a table
-- on a read of a key it has none of), and where two copies first differ.
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

-- A profile as a player customizes it: a font changed on every unit, Party's names with levels, a
-- typeface table on one unit, a color object and a color list on two cast bars, a position with no
-- element, string offsets, a custom color ticked.
local function customize()
	local config = UF:GetProfileConfig()
	for _, unit in ipairs(UNITS) do config[unit].name.font = 'pixel' end
	config.party.name.showLevel = true
	config.player.name.font = { file = 'Fonts\\FRIZQT__.TTF', size = 13, outline = 'THICKOUTLINE' }
	config.target.castbar.colors.normal = CreateColor(0.1, 0.2, 0.3)
	config.focus.castbar.colors.normal = { r = 0.3, g = 0.2, b = 0.1 }
	config.player.health.text.position = { point = 'LEFT', rel_point = 'LEFT', x_off = '5', y_off = '-2' }
	config.raid10.name.position = { point = 'TOP', rel_point = 'BOTTOM', frame = 'NotThere', x_off = 0, y_off = 0 }
	config.boss.health.colorCustom = true
	config.boss.health.customColor = CreateColor(0.5, 0.5, 0.1)
	config.player.classpower.spacing = 9
	config.nameplate.threat.enable = false
	config.friendlynameplate.questindicator.enable = true
end

local function every_page_and_menu(root)
	for _, unit in ipairs(UNITS) do
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
		end
		body:Release()
		-- Search, and the dots' counts.
		for _, cell in pairs(by) do
			if cell.row.type == 'item' then OM.MenuOffers(root, cell.row) end
		end
	end
	OM.Search(root, 'font')
	OM.Search(root, 'position')
end

for _, case in ipairs({ { 'a fresh profile', function() end }, { 'a customized profile', customize } }) do
	test('S2: building every page, drawing General and opening every part menu writes nothing, on ' .. case[1], function()
		in_look('thick', function()
			local config = UF:GetProfileConfig() -- the profile in use, made
			case[2]()
			local before = raw_copy(st.config.profile.unitframes)
			local root = tree()
			every_page_and_menu(root)
			local after = raw_copy(st.config.profile.unitframes)
			local found = first_difference(before, after, 'unitframes')
			eq(found, nil, 'the profile as it was: ' .. tostring(found))
			-- And the page built again from the same profile, with a menu drawn twice.
			every_page_and_menu(tree())
			found = first_difference(before, raw_copy(st.config.profile.unitframes), 'unitframes')
			eq(found, nil, 'and again: ' .. tostring(found))
			check(config ~= nil, 'the profile is in use')
		end)
	end)
end

test('S3: a part row\'s box set in combat only writes and calls UF:UpdateConfig, which queues: no frame is touched', function()
	local root = tree()
	local item = part_item(root, 'player', 'name')
	local row = { path = { 'Unitframes', 'player', 'general', 'parts', 'name' }, option = item, type = 'item', key = 'name' }
	local name = UF:GetProfileConfig().player.name
	local was = name.enable
	stub.in_combat = true
	local n = PW.updates
	local m = C.measure(function() OM.Set(root, row, not was) end)
	stub.in_combat = false
	eq(name.enable, not was, 'written')
	eq(PW.updates, n + 1, 'and UF:UpdateConfig called once')
	eq(m.forbidden.total, 0, 'no Show, Hide, SetPoint or the like')
	eq(m.made, 0, 'no frame made')
	name.enable = was
	-- The summary, a draw's reads, and the dots' count make nothing either.
	local read = C.measure(function()
		item.summary({})
		OM.MenuOffers(root, row)
	end)
	eq(read.forbidden.total, 0, 'reading a part row touches no frame')
	eq(read.made, 0, 'and makes none')
end)

test("a unit's frame Position and the part rows' Position blocks are different blocks: the page has no Position twice with one saved path", function()
	local root = tree()
	local seen = {}
	for _, unit in ipairs(UNITS) do
		local counts = {}
		count_rows(counts, root, root.Unitframes.args[unit], { 'Unitframes', unit })
		for id, count in pairs(counts) do
			if id:find('%.position$') then eq(count, 1, unit .. ': ' .. id .. ' appears once') end
		end
		seen[#seen + 1] = unit
	end
	eq(#seen, 13, 'every page')
end)

-- S1 on a customized profile. The walk's own round trips start from the defaults (reset_walk.lua says so), so
-- these are the part rows' resets from where a player's profile is: each setting customize() changed shows
-- its reset, and the reset puts back the default and nothing else. Last: customize() leaves its changes.
test("S1: on a customized profile each changed part setting resets to its default, and nothing else changes", function()
	customize()
	local root = tree()
	local profile = UF:GetProfile()
	local cases = {
		-- unit, part, menu key (nil: the box), the config path of the setting.
		{ 'party', 'name', 'showLevel', { 'name', 'showLevel' } },
		{ 'player', 'name', 'font', { 'name', 'font' } },
		{ 'player', 'healthtext', 'position', { 'health', 'text', 'position' } },
		{ 'player', 'classpower', 'spacing', { 'classpower', 'spacing' } },
		{ 'nameplate', 'threat', nil, { 'threat', 'enable' } },
		{ 'friendlynameplate', 'quest', nil, { 'questindicator', 'enable' } },
	}
	for _, case in ipairs(cases) do
		local unit, key, leaf, path = case[1], case[2], case[3], case[4]
		local item = part_item(root, unit, key)
		local menuRoot, row = OM.MenuRoot(item), nil
		if leaf then
			row = { path = { OM.MENU_KEY, leaf }, option = item.menu.args[leaf], type = item.menu.args[leaf].type, key = leaf }
		else
			menuRoot = root
			row = { path = { 'Unitframes', unit, 'general', 'parts', key }, option = item, type = 'item', key = key }
		end
		local where = unit .. ' ' .. key .. (leaf and ('.' .. leaf) or ' box')
		local differs = OM.DefaultDiffers(menuRoot, row)
		eq(differs, true, where .. ': differs from its default')
		local before = raw_copy(st.config.profile.unitframes)
		check(OM.DefaultReset(menuRoot, row), where .. ': its reset runs')
		eq(OM.DefaultDiffers(menuRoot, row), false, where .. ': at its default again')
		local after = raw_copy(st.config.profile.unitframes)
		-- Only the setting's own place changed.
		local node_before, node_after = before.profiles[profile][unit], after.profiles[profile][unit]
		for i = 1, #path do
			local last = i == #path
			if last then
				node_before[path[i]], node_after[path[i]] = nil, nil
			else
				node_before, node_after = node_before[path[i]], node_after[path[i]]
			end
		end
		local found = first_difference(before, after, 'unitframes')
		eq(found, nil, where .. ': nothing but the setting changed: ' .. tostring(found))
	end
end)

test('every registered element that has options has a name in UF.ELEMENT_NAMES', function()
	local missing = {}
	for key, element in pairs(PW.UF.elements) do
		if element.GetConfigTable and not PW.UF.ELEMENT_NAMES[key] then missing[#missing + 1] = key end
	end
	table.sort(missing)
	eq(table.concat(missing, ','), '', 'elements the TO dropdown would show by key')
end)
