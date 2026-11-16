-- /sui's search over the unit frame pages (OM.Search in SaftUI-Core/Config/optionsmodel.lua, the window's search box
-- and a result's click), as the parts and All units reshaped them: a part row by its name; a setting in a part's menu
-- by its name or the part's, which opens the unit's General and the part's menu; a two-place text setting (Health
-- text and Power text, one set of tables in the part's menu and on the tab) listed once, at its part; a part
-- declared a tab (Additional power) searched as its tab's rows; a plate page's disabled tabs and hidden part rows
-- not searched; All units listed before the units, as the picker orders them; a unit that follows All units listed
-- as any unit is; and a search that reads and writes nothing.
--
-- Real: page_world.lua's world (the options model, widgets, body and window, the unit frames' pages and shared
-- settings), on a profile converted by UF:PrepareShared. Stand-in: UF:UpdateConfig, as page_world.lua has it.
local PW = load_test_file('unitframes/page_world.lua').world()
local st, UF, OM, OW = PW.st, PW.UF, PW.OM, PW.OW

local click, tick = stub.click, tick_options_window
-- The sidebar asks Config for its commands and the database for the profile's name (config.lua and AceDB,
-- which this world does not load): none, and a name.
function st.Config:GetCommands() return {} end
if not st.config.GetCurrentProfile then function st.config:GetCurrentProfile() return 'SaftUI' end end

-- The page's units, in the picker's order, with All units first.
local UNITS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate' }

local function tree() return { Unitframes = UF:GetConfigTable() } end

local function pathText(result) return table.concat(result.path, '.') end

-- The results whose setting is named name, as 'unit:path' (+menu), in the order the model lists them.
local function listing(root, text, name)
	local out = {}
	for _, r in ipairs(OM.Search(root, text)) do
		if name == nil or r.name == name then out[#out + 1] = r.path[2] .. ':' .. table.concat(r.path, '.', 3) .. (r.menu and '+menu' or '') end
	end
	return out
end

local function count(list, pattern)
	local n = 0
	for _, each in ipairs(list) do
		if each:find(pattern) then n = n + 1 end
	end
	return n
end

-- A deep copy that reads only what is there (next, no __index: AceDB's wildcard makes a table on a read of a key
-- it has none of), and where two copies first differ.
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

local function convert()
	UF:PrepareShared()
	assert(UF:SharedReady(), 'the profile did not convert')
end

------------------------------------------------------------------ the parts

test("a part by its name: a result per page that has the part, at General's part, with no menu", function()
	convert()
	local root = tree()
	local expected = {}
	for _, unit in ipairs({ 'all', unpack(UNITS) }) do
		local parts = root.Unitframes.args[unit].args.general.args.parts.args
		if parts.quest then expected[#expected + 1] = unit end
	end
	check(#expected >= 8, 'the Quest part is on many pages: ' .. #expected)
	local got = {}
	local results = OM.Search(root, 'Quest')
	check(#results < 100, 'under the 100 cap, or the list below would be cut: ' .. #results)
	for _, r in ipairs(results) do
		if r.name == 'Quest' then
			got[#got + 1] = r.path[2]
			eq(table.concat(r.path, '.', 3), 'general.parts.quest', r.path[2] .. ': the part row')
			eq(r.menu, nil, r.path[2] .. ': its own row, not its menu')
			eq(r.sectionTitle, 'Parts', r.path[2] .. ': in the Parts section')
		end
	end
	eq(table.concat(got, ','), table.concat(expected, ','), 'one per page that has it, All units first, the pages in the picker order')
end)

test("a part's name lists its menu's settings after it; with a part many pages share the 100-result cap cuts the last pages", function()
	convert()
	local results = OM.Search(tree(), 'Health text')
	eq(#results, 100, 'the cap')
	local rows = {}
	for _, r in ipairs(results) do
		if r.name == 'Health text' then rows[#rows + 1] = r.path[2] end
	end
	eq(table.concat(rows, ','), 'all,' .. table.concat(UNITS, ',', 1, 11), "All units and then the pages in the picker's order, to the cap")
	-- Each part row is followed by its own menu's settings before the next page's.
	eq(results[1].name, 'Health text')
	eq(results[1].menu, nil)
	eq(results[2].menu, true, "then the part's menu settings")
	eq(results[2].path[5], 'healthtext')
end)

test("a setting in a part's menu: found by its name, the part's name or the page's, listed on the part's path with menu", function()
	convert()
	local root = tree()
	-- Its name.
	local hits = listing(root, 'Show level', 'Show level')
	eq(#hits, 14, 'a result on every page, All units included')
	for _, hit in ipairs(hits) do check(hit:find('general.parts.name+menu', 1, true), 'on the Name part, opening its menu: ' .. hit) end
	for _, r in ipairs(OM.Search(root, 'Show level')) do
		eq(r.sectionTitle, 'Name', r.path[2] .. ': the part is the section')
		eq(r.menu, true)
	end
	-- The part's name lists every setting of its menu.
	local menu = 0
	for _, r in ipairs(OM.Search(root, 'Class power')) do
		if r.path[2] == 'player' and r.menu then
			menu = menu + 1
			eq(r.path[5], 'classpower', 'at the part')
			eq(r.sectionTitle, 'Class power')
		end
	end
	check(menu >= 3, "the part's name finds its menu's settings: " .. menu)
end)

test("a part's menu result opens the unit's General and the part's menu, from the search box", function()
	convert()
	OW:Open({ 'Unitframes', 'target', 'general' }, tree())
	local f = OW.GetFrames()
	f.search:SetText('Show level')
	tick(0.3)
	local found
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.menu and c.row.path[2] == 'player' and c.row.path[#c.row.path] == 'name' then found = c end
	end
	check(found ~= nil, "a result for Player's Name > Show level")
	eq(found.row.name, 'Show level')
	click(found.frame)
	local state = OW:GetState()
	eq(state.page, 'Unitframes')
	eq(state.pick, 'player', "Player's page")
	eq(state.tab, 'general', 'General')
	local name
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == 'name' and c.row.path[2] == 'player' then name = c end
	end
	check(name ~= nil, "the Name part's row is drawn")
	check(OW:IsMenuShown(name.widget), "and its menu is open")
	check(OW.S.scrollOffset <= name.sectionY, "the part's row is not scrolled past")
	OW:CloseMenu()
	OW:Close()
end)

test("OW:Reveal of a part's path opens the unit's General and brings the part row into view", function()
	convert()
	OW:Open({ 'Unitframes', 'target', 'general' }, tree())
	OW:Reveal({ 'Unitframes', 'raid40', 'general', 'parts', 'name' })
	local state = OW:GetState()
	eq(state.pick, 'raid40', "Raid 40's page")
	eq(state.tab, 'general', 'General')
	local drawn
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == 'name' then drawn = c end
	end
	check(drawn ~= nil, 'the Name row is drawn')
	OW:Close()
end)

------------------------------------------------------------------ the two-place texts

test('a two-place text setting is listed once per unit, at its part: Deficit, and Power text\'s Short', function()
	convert()
	local root = tree()
	local hits = listing(root, 'Deficit', 'Deficit')
	eq(#hits, 14, 'one result per page, All units included')
	for _, hit in ipairs(hits) do
		check(hit:find('general.parts.healthtext+menu', 1, true), "at the Health text part, in its menu: " .. hit)
		check(not hit:find(':Health', 1, true), "not at the Health tab's Text section: " .. hit)
	end
	-- Power text too (a Text section on the Power tab, the part's mirror).
	for _, text in ipairs({ 'Short', 'Hide full' }) do
		local seen = {}
		for _, r in ipairs(OM.Search(root, text)) do
			if r.name == text then
				check(not ((r.path[3] == 'Health' or r.path[3] == 'Power') and r.path[4] == 'text'),
					text .. ": no result in the Health or Power tab's Text section: " .. pathText(r))
				if r.path[4] == 'parts' then
					local key = r.path[2] .. '.' .. r.path[5]
					check(not seen[key], text .. ' once at ' .. key)
					seen[key] = true
				end
			end
		end
		check(next(seen) ~= nil, text .. ' is found at a part')
	end
	-- The tab's mirror rows are not searched under the tab's name either: 'Health' finds no Text-section row.
	for _, r in ipairs(OM.Search(root, 'Health')) do
		if r.path[2] == 'player' and r.path[3] == 'Health' then
			check(r.path[4] ~= 'text', "no row of Health's Text section: " .. pathText(r))
		end
	end
end)

------------------------------------------------------------------ a part declared a tab

test("a part declared a tab (Additional power) is searched as its tab's rows, with no part row", function()
	convert()
	local root = tree()
	local rows, partHit = 0, 0
	for _, r in ipairs(OM.Search(root, 'Additional power')) do
		if r.path[2] == 'player' then
			eq(r.tabName:find('Additional power', 1, true) ~= nil, true, 'under the tab: ' .. tostring(r.tabName))
			eq(r.path[3], 'Power', 'on the Power page, a tab under it')
			eq(r.path[4], 'AdditionalPower', "the tab's own group")
			eq(r.menu, nil, 'no menu')
			rows = rows + 1
		end
		if r.path[4] == 'parts' then partHit = partHit + 1 end
	end
	check(rows > 10, "the tab's rows are found by its name: " .. rows)
	eq(partHit, 0, 'no Parts row for it')
	-- A setting of the tab, by its own name: Reverse fill is the tab's, and listed once per unit that has it.
	local hits = listing(root, 'Reverse fill', 'Reverse fill')
	check(count(hits, '^player:Power%.AdditionalPower%.reverse_fill$') == 1, "Player's: once, at the tab: " .. table.concat(hits, ', '))
	eq(count(hits, 'parts'), 0, 'none at a part')
end)

------------------------------------------------------------------ the plate pages

test("a plate page whose box is checked: the tabs it can't open and the part rows it sets aside are not searched", function()
	convert()
	local config = UF:GetProfileConfig()
	-- Before: Enemy nameplates list Name's menu and Castbar's tab.
	local before = OM.Search(tree(), 'Show level')
	local names = 0
	for _, r in ipairs(before) do
		if r.path[2] == 'nameplate' and r.path[5] == 'name' then names = names + 1 end
	end
	eq(names, 1, "Enemy's Name menu found while its box is unchecked")
	local castbarBefore = 0
	for _, r in ipairs(OM.Search(tree(), 'Width')) do
		if r.path[2] == 'nameplate' and r.path[3] == 'Castbar' then castbarBefore = castbarBefore + 1 end
	end
	check(castbarBefore > 0, "and its Cast bar tab's rows: " .. castbarBefore)

	config.nameplate.use_friendly = true
	local root = tree()
	for _, r in ipairs(OM.Search(root, 'Show level')) do
		check(not (r.path[2] == 'nameplate'), 'no Name result on the Enemy page: ' .. pathText(r))
	end
	for _, r in ipairs(OM.Search(root, 'Name')) do
		check(not (r.path[2] == 'nameplate' and r.path[3] == 'general' and r.path[5] == 'name'),
			'nor the Name row itself: ' .. pathText(r))
	end
	for _, r in ipairs(OM.Search(root, 'Width')) do
		check(not (r.path[2] == 'nameplate' and (r.path[3] == 'Castbar' or r.path[3] == 'Health')), "nor a disabled tab's rows: " .. pathText(r))
	end
	check(#listing(root, 'Show level') >= 12, "the other pages' still are")
	-- The Threat part stays on the page, so its menu is still found.
	local threat = 0
	for _, r in ipairs(OM.Search(root, 'Threat')) do
		if r.path[2] == 'nameplate' and r.path[5] == 'threat' then threat = threat + 1 end
	end
	check(threat > 0, 'Threat, which the page keeps, is searched')

	config.nameplate.use_friendly = false
	eq(#listing(tree(), 'Show level', 'Show level'), 14, 'unchecked: every page lists it again')
end)

------------------------------------------------------------------ All units

-- The decision the spec leaves open (section 5 names only "search runs over every pick as today, All units
-- included"): the search is a read of the model's pages and knows nothing of who owns a value, so a unit that
-- follows All units lists a setting exactly as one that owns it does, and an own mark changes no result.
test('G13: All units is listed first for a setting it holds, then each unit in the picker\'s order', function()
	convert()
	local results = OM.Search(tree(), 'Show level')
	local order = {}
	for _, r in ipairs(results) do order[#order + 1] = r.path[2] end
	eq(table.concat(order, ','), 'all,' .. table.concat(UNITS, ','), 'All units, then the pages as the picker lists them')
	eq(results[1].tabName, 'All units > General', "All units' result is named so")
	eq(results[1].path[5], 'name')
	eq(results[1].menu, true)
	-- A part row too, and a menu setting of a text.
	local order2 = {}
	for _, r in ipairs(OM.Search(tree(), 'Deficit')) do order2[#order2 + 1] = r.path[2] end
	eq(table.concat(order2, ','), 'all,' .. table.concat(UNITS, ','))
end)

test('a unit that follows All units lists a setting as one that owns it does; owning changes no result', function()
	convert()
	local before = listing(tree(), 'Show level', 'Show level')
	check(not UF:IsOwn('target', 'name.showLevel'), 'Target follows All units')
	local config = UF:GetProfileConfig()
	-- Target owns it after an edit through the page.
	local item = tree().Unitframes.args.target.args.general.args.parts.args.name
	local menuRoot = OM.MenuRoot(item)
	local group = { args = menuRoot }
	local row_group = OM.SubOption(OM.SubOption(group, OM.MENU_KEY), 'showLevel')
	local row = { option = row_group, path = { OM.MENU_KEY, 'showLevel' }, type = row_group.type, key = 'showLevel' }
	check(OM.Set(menuRoot, row, not config.target.name.showLevel))
	check(UF:IsOwn('target', 'name.showLevel'), 'Target owns it now')
	eq(table.concat(listing(tree(), 'Show level', 'Show level'), ','), table.concat(before, ','), 'the same results, the same order')
	-- And a follower's result is a result of the unit's own page, never All units' repeated.
	local own = 0
	for _, hit in ipairs(before) do
		if hit:find('^target:') then own = own + 1 end
	end
	eq(own, 1, "Target's own result, once")
end)

------------------------------------------------------------------ S2

for _, case in ipairs({ { 'a fresh profile', function() end }, { 'a customized profile', function()
	local config = UF:GetProfileConfig()
	config.party.name.showLevel = true
	config.player.health.text.deficit = true
	config.nameplate.use_friendly = true
end } }) do
	test('S2: a search reads and writes nothing, on ' .. case[1], function()
		convert()
		case[2]()
		local profile = st.config.profile.unitframes
		local before = raw_copy(profile)
		local updates = PW.updates
		for _, text in ipairs({ 'Show level', 'Deficit', 'Health text', 'Additional power', 'Spacing', 'Castbar', 'font', 'position', 'Name' }) do
			OM.Search(tree(), text)
		end
		eq(first_difference(before, raw_copy(profile), 'unitframes'), nil, 'the profile is as it was')
		eq(PW.updates, updates, 'no UpdateConfig')
		-- Through the window too: the box, a result's click.
		OW:Open({ 'Unitframes', 'player', 'general' }, tree())
		OW.GetFrames().search:SetText('Show level')
		tick(0.3)
		for _, c in ipairs(OW.GetDrawnRows()) do
			if c.row.menu and c.row.path[2] == 'target' then click(c.frame) break end
		end
		OW:CloseMenu()
		OW:Close()
		eq(first_difference(before, raw_copy(profile), 'unitframes'), nil, 'and after the window searched and a result opened')
	end)
end
