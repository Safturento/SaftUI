-- st:DefaultAt answers exactly what a fresh AceDB-3.0 profile holds, checked
-- against a real AceDB:New over every addon's real defaults: for every leaf
-- (the walk is over AceDB's own filled profile, so it finds every key AceDB
-- made, through '*' and '**' too, each wildcard probed with a key nothing
-- names), and for every table of plain values a row can be saved at (a
-- position, a color, a multiselect), on the default profile and on one of
-- another name. The bundled AceDB is loaded and read, never changed.
load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsdefault.lua')

-- Every addon's defaults, as the game loads them (Core's came with the helpers).
local FILES = {
	'SaftUI-ActionBars/config.lua', 'SaftUI-Bags/config.lua', 'SaftUI-Chat/config.lua', 'SaftUI-Loot/config.lua',
	'SaftUI-Minimap/config.lua', 'SaftUI-Misc/config.lua', 'SaftUI-Tracker/config.lua',
	'SaftUI-Unitframes/config/default.lua',
}
for _, unit in ipairs({ 'arena', 'boss', 'focus', 'focustarget', 'friendlynameplate', 'nameplate', 'party', 'pet',
		'pettarget', 'player', 'raid10', 'raid40', 'target', 'targettarget' }) do
	FILES[#FILES + 1] = 'SaftUI-Unitframes/config/units/' .. unit .. '.lua'
end

test('every addon\'s defaults load', function()
	for _, file in ipairs(FILES) do
		-- A file that reads a module it doesn't make gets the module made.
		local ok, err = pcall(load_saftui, file)
		for _ = 1, 5 do
			local name = not ok and tostring(err):match("Cannot find module '([^']+)'")
			if not name then break end
			st:NewModule(name)
			ok, err = pcall(load_saftui, file)
		end
		check(ok, file .. ': ' .. tostring(err))
	end
	check(st.defaults.unitframes ~= nil and st.defaults.chat ~= nil and st.defaults.colors ~= nil, 'the defaults are there')
end)

local function is_plain(t)
	for _, v in pairs(t) do
		if type(v) == 'table' then return false end
	end
	return true
end

-- Walks AceDB's filled table (the ground truth) and asks DefaultAt for every
-- leaf and every table of plain values; collects what disagrees.
local function compare(db_table, prefix, diffs, stats, positions)
	local mt = getmetatable(db_table)
	local keys = {}
	for key in pairs(db_table) do keys[#keys + 1] = key end
	if mt and mt.__index then keys[#keys + 1] = 'zz_nothing_names_this' end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	for _, key in ipairs(keys) do
		local value = db_table[key] -- a wildcard makes it
		prefix[#prefix + 1] = key
		local name = table.concat(prefix, '.')
		if type(value) == 'table' then
			if next(value) ~= nil and is_plain(value) then
				stats.tables = stats.tables + 1
				if value.point ~= nil and positions then positions[#positions + 1] = { { unpack(prefix) }, value } end
				local found, mine = st:DefaultAt(unpack(prefix))
				if not found or type(mine) ~= 'table' then
					diffs[#diffs + 1] = name .. ': AceDB has a table, DefaultAt found ' .. tostring(found) .. ' ' .. tostring(mine)
				else
					for k, v in pairs(value) do
						if mine[k] ~= v then diffs[#diffs + 1] = name .. '.' .. tostring(k) .. ': AceDB ' .. tostring(v) .. ', DefaultAt ' .. tostring(mine[k]) end
					end
					for k, v in pairs(mine) do
						if value[k] ~= v then diffs[#diffs + 1] = name .. '.' .. tostring(k) .. ': DefaultAt ' .. tostring(v) .. ', AceDB ' .. tostring(value[k]) end
					end
				end
			end
			compare(value, prefix, diffs, stats, positions)
		else
			stats.leaves = stats.leaves + 1
			local found, mine = st:DefaultAt(unpack(prefix))
			if not found or mine ~= value then
				diffs[#diffs + 1] = name .. ': AceDB ' .. tostring(value) .. ', DefaultAt ' .. tostring(found) .. ' ' .. tostring(mine)
			end
		end
		prefix[#prefix] = nil
	end
end

local function against_acedb(profile_name, from)
	local AceDB = LibStub('AceDB-3.0')
	local db = AceDB:New('DefaultAtProbeDB' .. profile_name, { profile = st.defaults }, profile_name)
	local root = db.profile
	local prefix = {}
	for _, key in ipairs(from or {}) do
		root = root[key]
		prefix[#prefix + 1] = key
	end
	local diffs, stats, positions = {}, { leaves = 0, tables = 0 }, {}
	compare(root, prefix, diffs, stats, positions)
	table.sort(diffs)
	return diffs, stats, positions
end

test('DefaultAt agrees with AceDB on every leaf and every table of plain values, on the default profile', function()
	local diffs, stats = against_acedb('SaftUI')
	check(stats.leaves > 1000 and stats.tables > 100, ('it walked %d leaves and %d tables'):format(stats.leaves, stats.tables))
	for i = 1, math.min(#diffs, 25) do check(false, diffs[i]) end
	eq(#diffs, 0, #diffs .. ' places differ from AceDB')
end)

test('and on a unit frame profile of another name', function()
	local diffs, stats = against_acedb('Healer', { 'unitframes', 'profiles', 'Healer' })
	check(stats.leaves > 500, 'it walked ' .. stats.leaves .. ' leaves')
	for i = 1, math.min(#diffs, 25) do check(false, diffs[i]) end
	eq(#diffs, 0, #diffs .. ' places differ from AceDB')
end)

-- Whether the table DefaultAt gives is the table AceDB filled, key for key, nested tables too
-- (AceDB's wildcard metatables aside: only keys it made are compared).
local function deep_same(mine, theirs, path, why)
	for k, v in pairs(theirs) do
		if type(v) == 'table' then
			if type(mine[k]) ~= 'table' or not deep_same(mine[k], v, path .. '.' .. tostring(k), why) then
				why[1] = why[1] or (path .. '.' .. tostring(k) .. ' is a table in AceDB, not in DefaultAt')
				return false
			end
		elseif mine[k] ~= v then
			why[1] = path .. '.' .. tostring(k) .. ': AceDB ' .. tostring(v) .. ', DefaultAt ' .. tostring(mine[k])
			return false
		end
	end
	for k in pairs(mine) do
		if theirs[k] == nil then why[1] = path .. '.' .. tostring(k) .. ': DefaultAt has it, AceDB does not'; return false end
	end
	return true
end

test('a synthetic profile of every rule: own table, sibling **, existing tables, plain against table, last wildcard', function()
	local RULES = {
		own = { part = { a = 1 }, ['**'] = { part = { b = 2 }, plain = 7 } },
		clash = { k = { x = 1 }, ['**'] = { k = 5 } },
		later = { ['**'] = { k = { x = 1 } }, named = { k = 5 } },
		elements = { only = { y = 1 }, ['**'] = { z = 3 } },
		['**'] = { part = { c = 3 }, wild = { w = 1 } },
		star = { ['*'] = 9 },
		two = { ['**'] = { kind = 'first' } },
		nest = { ['**'] = { deep = { v = 1, sub = { s = 1 } } }, a = { deep = { u = 2, sub = { t = 2 } } }, b = { other = 1 } },
		-- two candidates at one level, each with a wildcard: the last one's wins
		dup = { ['**'] = { z = 1 } },
		merged = { m = { own = { p = 1 } }, ['**'] = { m = { own = { q = 2 }, ['**'] = { r = 3 } } } },
	}
	RULES['**']['**'] = { z = 2 }
	st.defaults.rules_ = RULES
	local AceDB = LibStub('AceDB-3.0')
	local n = 0
	local function same(...)
		local path = { ... }
		n = n + 1
		-- A fresh AceDB for each path, so nothing an earlier read made is in the way.
		local db = AceDB:New('DefaultAtRulesDB' .. n, { profile = { rules_ = RULES } })
		local value = db.profile
		for _, key in ipairs(path) do
			if type(value) ~= 'table' then value = nil; break end
			value = value[key]
		end
		local found, mine = st:DefaultAt(unpack(path))
		if value == nil then return not found, 'AceDB has none, DefaultAt ' .. tostring(mine) end
		if type(value) == 'table' then
			if not (found and type(mine) == 'table') then return false, 'not a table' end
			local why = {}
			return deep_same(mine, value, table.concat(path, '.'), why), why[1]
		end
		return found and mine == value, tostring(value) .. ' vs ' .. tostring(mine)
	end
	for _, path in ipairs({
		{ 'rules_', 'own', 'part' }, { 'rules_', 'own', 'plain' }, { 'rules_', 'clash', 'k' }, { 'rules_', 'later', 'k' },
		{ 'rules_', 'later', 'named', 'k' }, { 'rules_', 'nest', 'a', 'deep' }, { 'rules_', 'nest', 'b', 'deep' },
		{ 'rules_', 'nest', 'b', 'deep', 'v' }, { 'rules_', 'nest', 'a', 'deep', 'v' }, { 'rules_', 'nest', 'a' },
		{ 'rules_', 'nest', 'a', 'deep', 'sub' }, { 'rules_', 'elements', 'only' },
		{ 'rules_', 'elements', 'only', 'z' }, { 'rules_', 'unnamed', 'part' }, { 'rules_', 'unnamed', 'wild' },
		{ 'rules_', 'star', 'anything' }, { 'rules_', 'two', 'kind' }, { 'rules_', 'dup', 'q', 'z' }, { 'rules_', 'dup', 'q' },
		{ 'rules_', 'merged', 'm' }, { 'rules_', 'merged', 'm', 'own' }, { 'rules_', 'merged', 'm', 'zz', 'r' },
	}) do
		local ok, why = same(unpack(path))
		check(ok, table.concat(path, '.') .. ': ' .. tostring(why))
	end
end)

-- The icon's own read of a merged default (it reads parts from the merged tables,
-- and builds none) against AceDB: a position row saved at every position table of
-- AceDB's filled profile is at its default, with an element dropdown or without.
test('the icon\'s read of every position default agrees with AceDB: no row differs on a fresh profile', function()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionsdefault.lua')
	local OM = st.OptionsModel
	local diffs, _, positions = against_acedb('SaftUI')
	check(#positions > 50, 'it found ' .. #positions .. ' position tables')
	local bad = 0
	for _, target in ipairs({ false, 'name', 'select' }) do
		for _, entry in ipairs(positions) do
			local path, tbl = entry[1], entry[2]
			local option = { type = 'position', name = 'P', order = 1, target = target or nil,
				get = function(_, part) return tbl[part] end, set = function() end,
				saved = function() return unpack(path) end }
			local root = { Page = { type = 'group', name = 'Page', args = { p = option } } }
			local row = { option = option, path = { 'Page', 'p' }, type = 'position', key = 'p' }
			if OM.DefaultDiffers(root, row) then
				bad = bad + 1
				if bad <= 20 then check(false, table.concat(path, '.') .. ' differs from its own default (target ' .. tostring(target) .. ')') end
			end
		end
	end
	eq(bad, 0, 'no position row differs on a fresh profile')
end)
