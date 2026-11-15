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
-- mover or hand default row differs on the profile as it is, which the caller made fresh; probe
-- (default true) round-trips every derived row; skip = { ['<path joined by .>']
-- = true } leaves a row out of everything, for one a page can't walk (give the
-- reason in the page's test); allow = { ['<row path joined by .>'] = { '<profile
-- key joined by .>', ... } } lets a row's set (and its reset) write those keys
-- outside its saved path, a key or anything below it, and keeps the rest of the
-- row's round trip. For a set with a known side effect, say Theme > Theme marking
-- fonts.version: allow = { ['Fonts.theme.theme'] = { 'fonts.version' } }.
--
-- It walks with each_option every option under the page, an item's menu rows
-- on OM.MenuRoot(item) with a { 'menu', ... } path, and every group's
-- pickerControl on its own tree. For each value row (a toggle, range, select,
-- multiselect, input, color, keybinding, font, position, item or a custom type
-- that isn't one of the bags' lists):
--   1. it has a reset source (OM.DefaultSource: share, default, mover, derived,
--      or none by a stated, non-empty noReset), else "has no reset: ...";
--   2. a derived row's saved path has a default (st:DefaultAt);
--   3. on the profile as it is, no derived, mover or hand default row differs (a row that
--      does is "differs on a fresh profile"; with fresh = false it is left
--      unprobed instead);
--   4. a derived row round-trips: a probe value (below) set through the row's
--      set makes it differ and changes the profile only under its saved path
--      (or an allowed key), and its reset makes it the same again with the
--      default saved and leaves the whole profile as it was before the probe
--      (numbers within 1e-4, nil and false alike, a frame nil or 'UIParent' alike,
--      offsets as whole pixels, an allowed key excepted); any error the game
--      would report during it is a problem naming the row.
-- A hidden or disabled row is checked for a source, never probed and never asked
-- whether it differs. The probe value, as the audit set one: a toggle or item
-- flipped, a range one step (else bigStep, else 1) up or down at its max, another
-- select key, a multiselect's first key flipped, an input's number plus 1 (else
-- '7' for a pattern row, else its text plus 'z'), a color's red plus 0.37
-- wrapped, a position's x_off plus 3 and its point moved (and, with an element
-- dropdown, its anchor put on another choice of the row's values), a font 'pixel' ('normal' when it holds
-- 'pixel'), a keybinding 'CTRL-F12'. The row is put back as it was.

local st = SaftUI
-- The model as it is now, read on each use: a test may load the model again after this file.
local OM = setmetatable({}, { __index = function(_, key) return SaftUI.OptionsModel[key] end })
if not each_option then load_test_file('lib/options_walk.lua') end

local R = {}

local VALUE = {
	toggle = true, range = true, select = true, multiselect = true, input = true, color = true,
	keybinding = true, font = true, position = true, item = true,
}
-- The bags' own types: lists, with a reset of their own (a titled rule row can carry one).
local LISTS = { bagcategories = true, bagitems = true }

local abs = math.abs

local function Joined(path) return table.concat(path, '.') end

local function Plain(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for key, each in pairs(value) do copy[key] = Plain(each) end
	return copy
end

-- Whether two saved values are the same for the reset's purposes: numbers
-- within 1e-4, nil and false alike, a frame nil or 'UIParent' alike, offsets as
-- the position set stores them (whole pixels).
local function Equivalent(key, a, b)
	if a == b then return true end
	if type(a) == 'number' and type(b) == 'number' then
		if abs(a - b) <= 1e-4 then return true end
		if key == 'x_off' or key == 'y_off' then
			return abs(tonumber(st:RoundToPixel(a)) - tonumber(st:RoundToPixel(b))) <= 1e-4
		end
		return false
	end
	if not a and not b then return true end
	if key == 'frame' and (not a or a == 'UIParent') and (not b or b == 'UIParent') then return true end
	return false
end

-- Every leaf that differs between two profile-shaped tables, as a path (a list of
-- keys); loose compares with Equivalent. out.strict is set when anything differs
-- exactly, which a loose compare lets pass (nil for false, 0.5 for 0.50001).
local function Changes(a, b, path, out, loose)
	for key, value in pairs(a) do
		local other = rawget(b, key)
		path[#path + 1] = key
		if type(value) == 'table' and type(other) == 'table' then
			Changes(value, other, path, out, loose)
		elseif type(value) == 'table' and not other and loose and next(value) == nil then
			out.strict = true -- an empty table against none
		elseif loose then
			if value ~= other then out.strict = true end
			if type(value) == 'table' or type(other) == 'table' or not Equivalent(key, value, other) then
				out[#out + 1] = { unpack(path) }
			end
		elseif value ~= other then
			out[#out + 1] = { unpack(path) }
		end
		path[#path] = nil
	end
	for key, value in pairs(b) do
		if rawget(a, key) == nil then
			out.strict = true
			local at = { unpack(path) }
			at[#at + 1] = key
			if not (loose and (type(value) ~= 'table' and Equivalent(key, nil, value) or (type(value) == 'table' and next(value) == nil))) then
				out[#out + 1] = at
			end
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

-- Whether a changed profile path is a key the row's allow list names, or below one.
local function Allowed(path, allowed)
	if not allowed then return false end
	local text = Joined(path)
	for _, key in ipairs(allowed) do
		if text == key or text:sub(1, #key + 1) == key .. '.' then return true end
	end
	return false
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
		if not group then return nil end
		if group.get ~= nil and not OM.HandsOn(group) then node = group end
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
		value.point = value.point == 'TOPLEFT' and 'TOPRIGHT' or 'TOPLEFT'
		if option.target == 'select' and option.unitKey then
			-- Another choice of the anchor dropdown, as its own set takes it.
			local now = OM.Get(root, row, 'relative_to')
			for _, entry in ipairs(OM.Values(root, row)) do
				if entry.key ~= now then
					value.element, value.frame = nil, nil
					if entry.key == option.nameKey then
						value.frame = 'UIParent'
					elseif entry.key ~= option.unitKey then
						value.element = entry.key
					end
					break
				end
			end
		end
		return value
	elseif rowType == 'font' then
		return current == 'pixel' and 'normal' or 'pixel'
	elseif rowType == 'keybinding' then
		return 'CTRL-F12'
	end
	return current
end

-- ctx.base is a copy of the profile as the walk last found it whole, kept while
-- every row leaves it exactly so; a row that leaves it changed (an allowed side
-- effect, a nil that became false) or fails drops it and the next row copies again.
-- The live profile is compared with it in place, twice a row.
local function RoundTrip(root, row, label, allowed, problems, ctx)
	local saved = SavedPath(root, row)
	local function Errors(step)
		for _, err in ipairs(take_errors()) do
			problems[#problems + 1] = ('%s: an error during the %s: %s'):format(label, step, tostring(err))
		end
	end
	local before = OM.ValueOf(root, row)
	local snapshot = ctx.base or Plain(st.config.profile)
	ctx.base = nil -- kept again only by a row that leaves the profile exactly as it was
	local probe = Probe(root, row, before)
	local ok, message = OM.WriteValue(root, row, probe)
	Errors('probe set')
	if not ok then
		problems[#problems + 1] = ('%s: its probe was not set: %s'):format(label, tostring(message))
		OM.WriteValue(root, row, before)
		Errors('restore')
		return
	end
	if row.type == 'position' and not OM.SameValue('position', OM.ValueOf(root, row), probe,
			{ relative = row.option.target == 'select' }) then
		problems[#problems + 1] = ('%s: its set did not take the probe position (its anchor, point or offsets)'):format(label)
	end
	if not OM.DefaultDiffers(root, row) then
		problems[#problems + 1] = ('%s: the probe set did not make it differ from its default'):format(label)
	end
	if saved then
		for _, at in ipairs(Changes(snapshot, st.config.profile, {}, {})) do
			if not Under(at, saved) and not Allowed(at, allowed) then
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
		-- The profile as it was before the probe, key for key.
		local after = Changes(snapshot, st.config.profile, {}, {}, true)
		for _, at in ipairs(after) do
			if not Allowed(at, allowed) then
				problems[#problems + 1] = ('%s: after its reset the profile differs from before the probe: %s'):format(
					label, table.concat(at, '.'))
			end
		end
		if not after.strict then ctx.base = snapshot end
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
	if source ~= 'derived' and source ~= 'mover' and source ~= 'default' then return end
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
	if source == 'derived' and opts.probe ~= false and not differs then RoundTrip(root, row, label, opts.allow and opts.allow[Joined(path)], problems, opts.ctx) end
end

local function IsValueRow(option)
	if type(option) ~= 'table' then return false end
	if VALUE[option.type] then return true end
	-- A type the bags (or a test) define: only where the widget files are loaded.
	local W = st.OptionsWidgets
	local custom = W and W.CUSTOM and W.CUSTOM[option.type]
	return custom ~= nil and not LISTS[option.type]
end

local function Walk(root, pageKey, opts, problems)
	local walked = 0
	opts.ctx = {}
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
			each_option({ args = tree }, function(inner, innerPath)
				-- Read by its own path on its own tree, but named for the group it belongs to (page and unit).
				local label = { unpack(path) }
				for _, key in ipairs(innerPath) do label[#label + 1] = key end
				Visit(tree, innerPath, inner, label)
			end)
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
