-- Walking SaftUI's /sui option tables, for the tests that check every option
-- of a tree. Not a test (no _test suffix), so the runner doesn't run it. A
-- test loads it with load_test_file('core/options_walk.lua'), which defines:
--
--   each_option(tree, fn)  calls fn(option, path) for every option under tree
--                          (a group: its args, their args, ...), groups
--                          included, in key order. path is the list of keys
--                          from tree down to the option.
--   ace_ready(tree)        a copy of tree that AceConfigRegistry-3.0's
--                          validator can check: SaftUI's own fields
--                          (category, size, target, nameKey) are left off
--                          every option, and the options of SaftUI's own type,
--                          position, are left out. AceConfig knows neither, so
--                          its validator rejects them; everything else in the
--                          tree is AceConfig's, so it checks the rest. The
--                          copy is of the options and their args, all the way
--                          down; other members (values, handlers, functions)
--                          are shared, and tree itself is untouched.

local SAFTUI_FIELDS = { category = true, size = true, target = true, nameKey = true }

local function SortedKeys(args)
	local keys = {}
	for key in pairs(args) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	return keys
end

local function Walk(group, fn, path)
	if type(group.args) ~= 'table' then return end
	for _, key in ipairs(SortedKeys(group.args)) do
		local option = group.args[key]
		local childPath = {}
		for i, k in ipairs(path) do childPath[i] = k end
		childPath[#childPath + 1] = key
		fn(option, childPath)
		if type(option) == 'table' and option.type == 'group' then
			Walk(option, fn, childPath)
		end
	end
end

function each_option(tree, fn)
	Walk(tree, fn, {})
end

function ace_ready(tree)
	local copy = {}
	for key, value in pairs(tree) do
		if not SAFTUI_FIELDS[key] then copy[key] = value end
	end
	if type(tree.args) == 'table' then
		copy.args = {}
		for key, option in pairs(tree.args) do
			if type(option) ~= 'table' then
				copy.args[key] = option -- malformed: left for the validator to report
			elseif option.type ~= 'position' then
				copy.args[key] = ace_ready(option)
			end
		end
	end
	return copy
end
