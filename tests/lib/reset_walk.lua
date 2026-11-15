-- The reset walk: checks that every value row of a /sui page has a reset, and
-- that each derived one round-trips. Not a test (no _test suffix), so the
-- runner doesn't run it. A page's test calls it from a world that has the
-- page's real option table:
--
--   local R = load_test_file('lib/reset_walk.lua')
--   R.check_page(root, 'Chat')                      -- check(false, problem) for each problem
--   local problems, walked = R.problems(root, 'Chat', { fresh = true, probe = true, skip = {} })
--
-- root is the options tree as the model reads it (OM.BuildView's root: page
-- keys to groups, as st.Config:GetOptionsTable() gives, or a table of its own),
-- pageKey the page's key in it. opts: fresh (default true) checks no derived or
-- mover row differs on the profile as it is, which the caller made fresh; probe
-- (default true) round-trips every derived row; skip = { ['<path joined by .>']
-- = true } leaves a row out of everything, for one a page can't walk (give the
-- reason in the page's test).
--
-- It walks with each_option every option under the page, an item's menu rows
-- on OM.MenuRoot(item) with a { 'menu', ... } path, and every group's
-- pickerControl on its own tree. For each value row (a toggle, range, select,
-- multiselect, input, color, keybinding, font, position, item or a custom type
-- that isn't one of the bags' lists):
--   1. it has a reset source (OM.DefaultSource: share, default, mover, derived,
--      or none by a stated, non-empty noReset), else "has no reset: ...";
--   2. a derived row's saved path has a default (st:DefaultAt);
--   3. on the profile as it is, no derived or mover row differs (a row that
--      does is "differs on a fresh profile"; with fresh = false it is left
--      unprobed instead);
--   4. a derived row round-trips: a probe value (below) set through the row's
--      set makes it differ and changes the profile only under its saved path,
--      and its reset makes it the same again with the default saved; any error
--      the game would report during it is a problem naming the row.
-- A hidden or disabled row is checked for a source, never probed and never asked
-- whether it differs. The probe value, as the audit set one: a toggle or item
-- flipped, a range one step (else bigStep, else 1) up or down at its max, another
-- select key, a multiselect's first key flipped, an input's number plus 1 (else
-- '7' for a pattern row, else its text plus 'z'), a color's red plus 0.37
-- wrapped, a position's x_off plus 3, a font 'pixel' ('normal' when it holds
-- 'pixel'), a keybinding 'CTRL-F12'. The row is put back as it was.

local st = SaftUI
local OM = st.OptionsModel
if not OM.DefaultSource then load_saftui('SaftUI-Core/Config/optionsdefault.lua') end
if not each_option then load_test_file('lib/options_walk.lua') end

local R = {}

local VALUE = {
	toggle = true, range = true, select = true, multiselect = true, input = true, color = true,
	keybinding = true, font = true, position = true, item = true,
}
-- The bags' own types: lists, with a reset of their own (a titled rule row can carry one).
local LISTS = { bagcategories = true, bagitems = true }

local function Joined(path) return table.concat(path, '.') end

local function Plain(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for key, each in pairs(value) do copy[key] = Plain(each) end
	return copy
end

-- Every leaf that differs between two plain copies, as a path (a list of keys).
local function Changes(a, b, path, out)
	for key, value in pairs(a) do
		local other = b[key]
		path[#path + 1] = key
		if type(value) == 'table' and type(other) == 'table' then
			Changes(value, other, path, out)
		elseif value ~= other then
			out[#out + 1] = { unpack(path) }
		end
		path[#path] = nil
	end
	for key, value in pairs(b) do
		if a[key] == nil then
			local at = { unpack(path) }
			at[#at + 1] = key
			out[#out + 1] = at
		end
	end
	return out
end

local function Under(path, saved)
	if #path < #saved then return false end
	for i = 1, #saved do
		if tostring(path[i]) ~= tostring(saved[i]) then return false end
	end
	return true
end

-- The tree and the path a row is read from: an item's menu rows are on
-- OM.MenuRoot(item) under { 'menu', ... }.
local function Resolve(root, path)
	local group = { args = root }
	for i, key in ipairs(path) do
		if key == 'menu' and group.type == 'item' and type(group.menu) == 'table' then
			local rest = { 'menu' }
			for j = i + 1, #path do rest[#rest + 1] = path[j] end
			return OM.MenuRoot(group), rest
		end
		group = OM.SubOption(group, key)
		if not group then return root, path end
	end
	return root, path
end

local function Named(root, row)
	local ok, name = pcall(OM.Member, root, row, 'name')
	return ok and type(name) == 'string' and name or tostring(row.key)
end

local function Describe(path, row)
	return ('%s (%s %s)'):format(Joined(path), row.type, tostring(row.name))
end

-- The node that gives the row its get, as the model finds it.
local function GetNode(root, row)
	local group, node = { args = root }, nil
	for _, key in ipairs(row.path) do
		group = OM.SubOption(group, key)
		if group.get ~= nil then node = group end
	end
	return node
end

local function SavedPath(root, row)
	local node = GetNode(root, row)
	if not (node and type(node.saved) == 'function') then return nil end
	return { node.saved(OM.Info(root, row.path)) }
end

local function Probe(root, row, current)
	local rowType, option = row.type, row.option
	if rowType == 'toggle' or rowType == 'item' then
		return not current
	elseif rowType == 'range' then
		local step = OM.Member(root, row, 'step') or OM.Member(root, row, 'bigStep') or 1
		local max = OM.Member(root, row, 'max')
		if max and current + step > max then return current - step end
		return current + step
	elseif rowType == 'select' then
		for _, entry in ipairs(OM.Values(root, row)) do
			if entry.key ~= current then return entry.key end
		end
		return current
	elseif rowType == 'multiselect' then
		local value = {}
		for key, on in pairs(current) do value[key] = on end
		local first = OM.Values(root, row)[1]
		if first then value[first.key] = not value[first.key] end
		return value
	elseif rowType == 'input' then
		local number = tonumber(current)
		if number then return tostring(number + 1) end
		if option.pattern then return '7' end
		return tostring(current) .. 'z'
	elseif rowType == 'color' then
		local value = { current[1], current[2], current[3], current[4] }
		value[1] = ((value[1] or 0) + 0.37) % 1
		return value
	elseif rowType == 'position' then
		local value = {}
		for key, part in pairs(current) do value[key] = part end
		value.x_off = (tonumber(value.x_off) or 0) + 3
		return value
	elseif rowType == 'font' then
		return current == 'pixel' and 'normal' or 'pixel'
	elseif rowType == 'keybinding' then
		return 'CTRL-F12'
	end
	return current
end

local function RoundTrip(root, row, label, problems)
	local saved = SavedPath(root, row)
	local function Errors(step)
		for _, err in ipairs(take_errors()) do
			problems[#problems + 1] = ('%s: an error during the %s: %s'):format(label, step, tostring(err))
		end
	end
	local before = OM.ValueOf(root, row)
	local snapshot = Plain(st.config.profile)
	local probe = Probe(root, row, before)
	local ok, message = OM.WriteValue(root, row, probe)
	Errors('probe set')
	if not ok then
		problems[#problems + 1] = ('%s: its probe was not set: %s'):format(label, tostring(message))
		return
	end
	if not OM.DefaultDiffers(root, row) then
		problems[#problems + 1] = ('%s: the probe set did not make it differ from its default'):format(label)
	end
	if saved then
		for _, at in ipairs(Changes(snapshot, Plain(st.config.profile), {}, {})) do
			if not Under(at, saved) then
				problems[#problems + 1] = ('%s: the probe changed the profile outside its saved path (%s): %s'):format(
					label, table.concat(saved, '.'), table.concat(at, '.'))
			end
		end
	end
	local reset, why = OM.DefaultReset(root, row)
	Errors('reset')
	if not reset then
		problems[#problems + 1] = ('%s: its reset did not run: %s'):format(label, tostring(why))
	elseif OM.DefaultDiffers(root, row) then
		problems[#problems + 1] = ('%s: it still differs after its reset'):format(label)
	else
		local found, default = st:DefaultAt(unpack(saved or {}))
		if found and not OM.SameValue(row.type, OM.ValueOf(root, row), OM.DefaultValueOf(root, row, default),
				{ hasAlpha = OM.Member(root, row, 'hasAlpha'), relative = row.option.target == 'select' }) then
			problems[#problems + 1] = ('%s: its reset did not save the default'):format(label)
		end
	end
	-- Back as it was.
	OM.WriteValue(root, row, before)
	Errors('restore')
end

local function CheckRow(root, row, path, opts, problems)
	local label = Describe(path, row)
	local source = OM.DefaultSource(root, row)
	if source == nil then
		if row.option.noReset == '' then
			problems[#problems + 1] = label .. ' has an empty noReset: say why it has no reset'
		else
			problems[#problems + 1] = label .. ' has no reset: give the group that gives its get `saved`, or the row `default` or `noReset`'
		end
		return
	end
	if source ~= 'derived' and source ~= 'mover' then return end
	local hidden = OM.Member(root, row, 'hidden') and true or false
	if hidden or OM.IsDisabled(root, row) then return end
	if source == 'derived' then
		local saved = SavedPath(root, row)
		local found = saved and st:DefaultAt(unpack(saved))
		if not found then
			problems[#problems + 1] = ('%s: no default in st.defaults at %s'):format(label, saved and table.concat(saved, '.') or '?')
			return
		end
	end
	local differs = OM.DefaultDiffers(root, row)
	if differs and opts.fresh ~= false then
		problems[#problems + 1] = label .. ' differs on a fresh profile: its default is not what its get shows at start'
		return
	end
	-- A row that already differs (fresh = false) is not probed: its probe
	-- value could be the default.
	if source == 'derived' and opts.probe ~= false and not differs then RoundTrip(root, row, label, problems) end
end

local function IsValueRow(option)
	if type(option) ~= 'table' then return false end
	return VALUE[option.type] or (st.OptionsWidgets.CUSTOM[option.type] ~= nil and not LISTS[option.type])
end

local function Walk(root, pageKey, opts, problems)
	local walked = 0
	-- rowRoot and rowPath are what the model reads the row by, labelPath the walk's own.
	local function Visit(rowRoot, rowPath, option, labelPath)
		if not IsValueRow(option) then return end
		if opts.skip and opts.skip[Joined(labelPath)] then return end
		local row = { option = option, path = rowPath, type = option.type, key = labelPath[#labelPath] }
		row.name = Named(rowRoot, row)
		walked = walked + 1
		CheckRow(rowRoot, row, labelPath, opts, problems)
	end
	each_option({ args = { [pageKey] = root[pageKey] } }, function(option, path)
		local rowRoot, rowPath = Resolve(root, path)
		Visit(rowRoot, rowPath, option, path)
		-- A group's pickerControl: its options, on a tree of their own.
		if type(option) == 'table' and type(option.pickerControl) == 'table' then
			local tree = { [OM.PICKER_CONTROL_KEY] = option.pickerControl }
			each_option({ args = tree }, function(inner, innerPath) Visit(tree, innerPath, inner, innerPath) end)
		end
	end)
	return walked
end

function R.problems(root, pageKey, opts)
	opts = opts or {}
	local problems = {}
	local walked = Walk(root, pageKey, opts, problems)
	return problems, walked
end

function R.check_page(root, pageKey, opts)
	local problems, walked = R.problems(root, pageKey, opts)
	for _, problem in ipairs(problems) do check(false, problem) end
	check(walked > 0, ('the reset walk of %s found no value rows'):format(pageKey))
	return walked
end

return R
