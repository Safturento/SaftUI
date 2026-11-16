-- All units and the shares on each unit's page (SaftUI-Unitframes/config/sharedoptions.lua, config/config.lua): the
-- picker starts with All units; its page is the members' parts and bars with the frame's Theme and Background;
-- a member's shared row is own after a set and follows All units again on Reset; All units' rows list each
-- owner; a set on All units reaches every unit that does not own it, once on the next frame however many sets
-- came; every page set and share action leaves each member's stored value what UF:SharedValue says; nothing is
-- shared and nothing is drawn while the profile in use does not share.
--
-- Real: config_test.lua's world (page_world.lua) with config/shared.lua and config/sharedoptions.lua, on a
-- customized profile converted by UF:PrepareShared, and the options kit. Stand-in: UF:UpdateConfig, which has
-- unitframes.lua's two lines for the wiring (All units' sets propagate; a no-unit update prepares the profile)
-- and counts its calls.
local SW = load_test_file('unitframes/shared_world.lua')
local C = load_test_file('lib/color_cost.lua')
local P_ = load_test_file('lib/pixels.lua')
local PW, st, UF, OM, OW, W

local function world()
	reset_world()
	PW = load_test_file('unitframes/page_world.lua').world()
	st, UF, OM, OW, W = PW.st, PW.UF, PW.OM, PW.OW, PW.W
	load_editmode()
	load_test_file('lib/options_walk.lua')
end

-- A profile converted (customized first, or as it starts).
local function convert(customize)
	world()
	local profile = UF:GetProfileConfig()
	if customize then SW.customize(profile) end
	UF:PrepareShared()
	assert(UF:SharedReady(), 'the profile did not convert')
	return profile
end

local function tree() return { Unitframes = UF:GetConfigTable() } end

local function view_of(root, unit, tab, subtab)
	return OM.BuildView(root, 'Unitframes', { pick = unit, tab = tab, subtab = subtab })
end

local function keys_of(list)
	local out = {}
	for i, entry in ipairs(list) do out[i] = entry.key end
	return table.concat(out, ',')
end

-- The row of the option at path (keys from the root), as the model finds it.
local function row_at(root, path)
	local group = { args = root }
	for _, key in ipairs(path) do group = OM.SubOption(group, key) end
	return { option = group, path = path, type = group.type, key = path[#path] }
end

-- A part's menu row: the root the kit reads the menu through, and the row in it.
local function menu_row(root, unit, part, key)
	local item = root.Unitframes.args[unit].args.general.args.parts.args[part]
	local menu_root = OM.MenuRoot(item)
	return menu_root, row_at(menu_root, { OM.MENU_KEY, key })
end

local function part_row(root, unit, part)
	return row_at(root, { 'Unitframes', unit, 'general', 'parts', part })
end

-- Every value row of a unit's page with the root and path the kit reads it by: { root, row, key } (the tabs'
-- rows, a part menu's rows, and a mirror once).
local VALUE = { toggle = true, range = true, select = true, input = true, color = true, font = true, position = true, item = true }
local function rows_of(root, unit)
	local out = {}
	each_option({ args = { Unitframes = { type = 'group', name = 'x', args = { [unit] = root.Unitframes.args[unit] } } } }, function(option, path)
		if type(option) ~= 'table' or not VALUE[option.type] then return end
		local at
		for i = 3, #path do
			if path[i] == OM.MENU_KEY then at = i break end
		end
		if at then
			local item = { args = root }
			for i = 1, at - 1 do item = OM.SubOption(item, path[i]) end
			local walk, rel = OM.MenuRoot(item), {}
			for i = at, #path do rel[#rel + 1] = path[i] end
			out[#out + 1] = { root = walk, row = row_at(walk, rel), unit = unit }
		else
			local node = { args = root }
			for i, key in ipairs(path) do
				node = OM.SubOption(node, key)
				if node and node.mirrorOf and i < #path then return end
			end
			out[#out + 1] = { root = root, row = row_at(root, path), unit = unit }
		end
	end)
	return out
end

-- The saved path of a row below its unit, as the model reads it ('name.font'), or nil.
local function saved_of(root, row, unit)
	local group, node = { args = root }, nil
	for _, key in ipairs(row.path) do
		group = OM.SubOption(group, key)
		if group.get ~= nil and not OM.HandsOn(group) then node = group end
	end
	if not (node and type(node.saved) == 'function') then return end
	local keys = { node.saved(OM.Info(root, row.path)) }
	if keys[1] ~= 'unitframes' or keys[4] ~= unit then return end
	return table.concat(keys, '.', 5)
end

-- Each member's stored value of the key is what UF:SharedValue says, for a follower All units' (compared by the
-- entry's own compare), for an owner its own.
local function invariant(key, label)
	local entry = UF.SHARED_BY_KEY[key]
	local profile = UF:GetProfileConfig()
	local all = rawget(profile, 'all')
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if UF:HasShared(unit, key) and not UF:IsOwn(unit, key) then
			check(UF.SameShared(entry, profile[unit], all), label .. ': ' .. unit .. ' follows ' .. key)
		end
	end
end

------------------------------------------------------------------ the page

test("the picker starts with All units; its page has five tabs and the union of the members' parts, and no Position", function()
	convert(true)
	local root = tree()
	local view = OM.BuildView(root, 'Unitframes')
	eq(view.picker.values[1].key, 'all', 'All units first')
	eq(view.picker.values[1].name, 'All units')
	eq(view.picker.selected, 'all', 'the page opens on it')
	eq(keys_of(view.tabs), 'general,Health,Power,Castbar,Auras', 'five tabs')
	local general = root.Unitframes.args.all.args.general
	eq(keys_of(view.sections[1].rows), 'theme,background', 'Frame: Theme and Background alone')
	eq(general.args.position, nil, 'no Position')
	eq(general.args.frame.args.enable, nil, 'no Enable, Width or Height (each unit\'s own)')
	local parts = {}
	for key in pairs(general.args.parts.args) do parts[#parts + 1] = key end
	table.sort(parts)
	eq(table.concat(parts, ','), 'grouprole,healthtext,name,powertext,quest,raidrole,raidtarget,readycheck',
		'the parts some unit has a setting of: Ready check, not Class power, Subtext or Threat')
	-- Health shows every color flag, whatever kind of unit shows it.
	local colors
	for _, section in ipairs(view_of(root, 'all', 'Health').sections) do
		if section.title == 'Colors' then colors = section end
	end
	check(colors, 'Health has a Colors section')
	local keys = {}
	for _, row in ipairs(colors.rows) do keys[row.key] = true end
	for _, flag in ipairs({ 'colorDisconnected', 'colorTapping', 'colorClass', 'colorClassNPC', 'colorClassPet',
		'colorReaction', 'colorSmooth', 'colorHealth' }) do
		check(keys[flag], 'Health > Colors has ' .. flag)
	end
	-- No Copy from on All units; the members keep it.
	local picker = root.Unitframes.args
	eq(picker.all.pickerControl.args.copy, nil, 'All units has no Copy from')
	check(picker.all.pickerControl.args.profile and picker.all.pickerControl.args.manage, 'but the Profile and Manage')
	check(picker.target.pickerControl.args.copy ~= nil, "a unit keeps Copy from: its copies are its own settings")
end)

test('every shared setting a member page shows has a share, and every other row has none', function()
	convert(true)
	local root = tree()
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		local shared, plain = 0, 0
		for _, entry in ipairs(rows_of(root, unit)) do
			local path = saved_of(entry.root, entry.row, unit)
			local setting = path and UF.SHARED_BY_PATH[path]
			local option = entry.row.option
			if setting and UF:HasShared(unit, setting.key) then
				check(option.share ~= nil, unit .. ' ' .. path .. ' has a share')
				check(type(option.share.own) == 'function', unit .. ' ' .. path .. ' is a member page row')
				shared = shared + 1
			elseif path and not setting then
				check(option.share == nil, unit .. ' ' .. path .. ' has none: it is the unit\'s own')
				plain = plain + 1
			end
		end
		check(shared > 40, unit .. ': ' .. shared .. ' shared rows')
		check(plain >= 3, unit .. ': ' .. plain .. ' own rows')
	end
end)

------------------------------------------------------------------ a member's rows

test("a member's shared row: own after a set, and the hover line's Reset follows All units again", function()
	convert(true)
	local root = tree()
	local mroot, row = menu_row(root, 'target', 'name', 'maxLength')
	local state = OM.ShareState(mroot, row)
	eq(state.member, true)
	eq(state.own, false, 'follows at first')
	local all = rawget(UF:GetProfileConfig(), 'all').name.maxLength
	eq(OM.Get(mroot, row), all, 'showing All units\' value')
	check(OM.Set(mroot, row, all + 7))
	eq(UF:IsOwn('target', 'name.maxLength'), true, 'owned after a set')
	eq(OM.ShareState(mroot, row).own, true)
	eq(OM.Get(mroot, row), all + 7, 'and it holds the value')
	local item = OM.ShareState(root, part_row(root, 'target', 'name'))
	eq(item.marked, true, 'the Name part row is marked while anything in it is own')
	eq(OM.ShareState(mroot, row).source, 'All units')
	eq(OM.ShareState(mroot, row).page, 'Target')
	eq(OM.ShareCall(mroot, row, 'reset'), true)
	eq(UF:IsOwn('target', 'name.maxLength'), false, 'follows again')
	eq(OM.Get(mroot, row), all, 'stored = All units\'')
	eq(rawget(UF:GetProfileConfig().target, 'own')['name.maxLength'], false, 'cleared to false, never nil')
	-- Marked while anything else in the part is own (a customized profile has a few).
	local other_own = false
	for _, entry in ipairs(UF.SHARED) do
		if entry.part == 'name' and UF:IsOwn('target', entry.key) then other_own = true end
	end
	eq(OM.ShareState(root, part_row(root, 'target', 'name')).marked, other_own, 'and the part row follows what else is own')
	-- Reset puts the frames right once on the next frame.
	local calls = {}
	local real = UF.UpdateConfig
	function UF:UpdateConfig(unit, element) calls[#calls + 1] = tostring(unit) .. ':' .. tostring(element); return real(self, unit, element) end
	OM.Set(mroot, row, all + 3)
	OM.ShareCall(mroot, row, 'reset')
	SW.step(UF)
	local seen = {}
	for _, call in ipairs(calls) do seen[call] = (seen[call] or 0) + 1 end
	eq(seen['target:Name'], 2, 'the set, then once for the reset')
	UF.UpdateConfig = real
end)

test("a member's own rows keep their derived resets", function()
	convert(true)
	local root = tree()
	for _, unit in ipairs({ 'target', 'party', 'raid10' }) do
		for _, key in ipairs({ 'enable', 'width', 'height' }) do
			local row = row_at(root, { 'Unitframes', unit, 'general', 'frame', key })
			eq(OM.ShareState(root, row), nil, unit .. ' ' .. key .. ' is the unit\'s own: no share')
			eq(OM.DefaultSource(root, row), 'derived', unit .. ' ' .. key)
		end
	end
	for _, key in ipairs({ 'unitsPerColumn', 'maxColumns' }) do
		local row = row_at(root, { 'Unitframes', 'party', 'general', 'layout', key })
		eq(OM.ShareState(root, row), nil, 'party ' .. key)
		check(OM.DefaultSource(root, row) ~= 'share', 'party ' .. key .. ' keeps its own reset')
	end
	-- A shared row resets by the line's Reset (the share source), a part's box included.
	local mroot, row = menu_row(root, 'party', 'name', 'font')
	eq(OM.DefaultSource(mroot, row), 'share', 'a shared row')
	eq(OM.DefaultSource(root, part_row(root, 'party', 'name')), 'share', 'a part row: its Enable')
end)

test("a part row's share is its Enable's: own with it, and Apply to Multiple gives the picked units this unit's Show", function()
	convert(true)
	local root = tree()
	local item = part_row(root, 'target', 'healthtext')
	local profile = UF:GetProfileConfig()
	local before = profile.target.health.text.enable
	check(OM.Set(root, item, not before))
	eq(UF:IsOwn('target', 'health.text.enable'), true, 'the box is own')
	eq(OM.ShareState(root, item).own, true)
	eq(OM.ShareCall(root, item, 'apply', { 'focus', 'boss' }), true)
	for _, unit in ipairs({ 'focus', 'boss' }) do
		eq(UF:IsOwn(unit, 'health.text.enable'), true, unit .. ' owns it')
		eq(profile[unit].health.text.enable, not before, unit .. ' stores the value')
	end
	check(not UF:IsOwn('pet', 'health.text.enable'))
	local targets = OM.ShareTargets(root, item)
	local labels = {}
	for _, target in ipairs(targets) do labels[#labels + 1] = target.key end
	eq(#targets, 10, 'the other members that have it')
	check(not table.concat(labels, ','):find('target', 1, true) or table.concat(labels, ','):find('targettarget', 1, true), 'not itself')
	invariant('health.text.enable', 'after Apply to')
	eq(OM.ShareCall(root, item, 'applyAll'), true)
	eq(#UF:OwnersOf('health.text.enable'), 0, 'All: nobody owns it')
	eq(rawget(profile, 'all').health.text.enable, not before, 'All units took the value')
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if UF:HasShared(unit, 'health.text.enable') then eq(profile[unit].health.text.enable, not before, unit) end
	end
end)

------------------------------------------------------------------ All units' rows

test("All units' row: the diff icon lists each owner and its value; All makes everyone follow", function()
	convert(true)
	local root = tree()
	local mroot, row = menu_row(root, 'all', 'name', 'showLevel')
	local state = OM.ShareState(mroot, row)
	eq(state.member, false, 'a source page row')
	local owners = UF:OwnersOf('name.showLevel')
	check(#owners > 0, 'someone owns it')
	eq(#state.differs, #owners, 'one line per owner')
	for i, owner in ipairs(owners) do
		eq(state.differs[i].name, UF.UnitPageName(owner), 'in member order')
		eq(state.differs[i].value, UF.SharedText(UF.SHARED_BY_KEY['name.showLevel'], UF:GetProfileConfig()[owner].name.showLevel), 'with its value')
	end
	eq(state.offers, true)
	eq(state.shared, UF.SharedText(UF.SHARED_BY_KEY['name.showLevel'], rawget(UF:GetProfileConfig(), 'all').name.showLevel))
	eq(OM.ShareCall(mroot, row, 'applyAll'), true)
	eq(#UF:OwnersOf('name.showLevel'), 0, 'nobody owns it')
	local all = rawget(UF:GetProfileConfig(), 'all').name.showLevel
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if UF:HasShared(unit, 'name.showLevel') then eq(UF:GetProfileConfig()[unit].name.showLevel, all, unit .. ' stores it') end
	end
	eq(#OM.ShareState(mroot, row).differs, 0, 'the icon is gone')
	-- Multiple lists the owners, and the picked follow.
	UF:GetProfileConfig()
	check(OM.Set(row_at(root, { 'Unitframes', 'party' }) and (select(1, menu_row(root, 'party', 'name', 'showLevel'))), select(2, menu_row(root, 'party', 'name', 'showLevel')), not all))
	check(OM.Set(menu_row(root, 'raid10', 'name', 'showLevel'), select(2, menu_row(root, 'raid10', 'name', 'showLevel')), not all))
	local targets = OM.ShareTargets(mroot, row)
	eq(#targets, 2, 'Multiple lists the owners')
	eq(OM.ShareCall(mroot, row, 'apply', { 'party' }), true)
	eq(UF:IsOwn('party', 'name.showLevel'), false, 'party follows again')
	eq(UF:IsOwn('raid10', 'name.showLevel'), true, 'raid10 still owns')
end)

test("a part row on All units: its diff names each owner and what it owns inside the part", function()
	convert(false)
	local root = tree()
	local mroot, row = menu_row(root, 'party', 'name', 'maxLength')
	OM.Set(mroot, row, 9)
	local item = part_row(root, 'all', 'name')
	local state = OM.ShareState(root, item)
	check(state.marked == false and state.member == false)
	local names = {}
	for _, d in ipairs(state.differs) do names[d.name] = d.value end
	check(names['Party'], 'Party owns something in Name')
	check(names['Party']:find('Max length', 1, true), 'naming the setting: ' .. tostring(names['Party']))
end)

test('a set on All units reaches every unit that follows and none that owns, once per frame however many sets came', function()
	convert(true)
	local root = tree()
	local profile = UF:GetProfileConfig()
	local mroot, row = menu_row(root, 'all', 'name', 'max_width')
	-- Target owns it; the rest follow (some may own on a customized profile: ask).
	local mtarget, trow = menu_row(root, 'target', 'name', 'max_width')
	OM.Set(mtarget, trow, 33)
	local owners = {}
	for _, unit in ipairs(UF:OwnersOf('name.max_width')) do owners[unit] = true end
	check(owners.target)
	local calls = {}
	local real = UF.UpdateConfig
	function UF:UpdateConfig(unit, element) calls[#calls + 1] = tostring(unit) .. ':' .. tostring(element); return real(self, unit, element) end
	for value = 101, 120 do OM.Set(mroot, row, value) end -- a drag
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if UF:HasShared(unit, 'name.max_width') then
			eq(profile[unit].name.max_width, owners[unit] and (unit == 'target' and 33 or profile[unit].name.max_width) or 120,
				unit .. (owners[unit] and ' keeps its own' or ' follows'))
		end
	end
	local before = #calls
	local named = {}
	for i = 1, before do named[calls[i]] = (named[calls[i]] or 0) + 1 end
	eq(named['all:Name'], 20, 'each set called UpdateConfig(\'all\', \'Name\')')
	for _, unit in ipairs(UF.SHARE_MEMBERS) do eq(named[unit .. ':Name'], nil, unit .. ': not before the next frame') end
	SW.step(UF)
	named = {}
	for i = before + 1, #calls do named[calls[i]] = (named[calls[i]] or 0) + 1 end
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if UF:HasShared(unit, 'name.max_width') and not owners[unit] then
			eq(named[unit .. ':Name'], 1, unit .. ': once')
		else
			eq(named[unit .. ':Name'], nil, unit .. ': not at all')
		end
	end
	UF.UpdateConfig = real
	invariant('name.max_width', 'after the drag')
end)

test("an All units Position that would put a follower's part on itself through the frame it names is refused", function()
	convert(false)
	local root = tree()
	local mroot, row = menu_row(root, 'all', 'name', 'position')
	local profile = UF:GetProfileConfig()
	-- Target's Name element, and a frame hung from it: naming that frame would loop.
	local target_frame = UF.units.target
	target_frame.GetConfig = function() return profile.target end -- the page's frame, as UF:GetConfigFrame wants it
	target_frame.Name = CreateFrame('Frame', nil, target_frame)
	target_frame.Name.unitframe = target_frame
	target_frame.elements = { Name = target_frame.Name }
	local hung = CreateFrame('Frame', 'SaftUIPageTestHung', UIParent)
	hung:SetPoint('TOPLEFT', target_frame.Name, 'BOTTOMLEFT')
	local ok, why = OM.Validate(mroot, row, 'frame', 'SaftUIPageTestHung')
	check(ok ~= true, 'refused')
	check(tostring(why):find('Target', 1, true), 'naming the unit: ' .. tostring(why))
	-- A frame nothing hangs from the part is fine.
	local free = CreateFrame('Frame', 'SaftUIPageTestFree', UIParent)
	eq(OM.Validate(mroot, row, 'frame', 'SaftUIPageTestFree'), true)
	-- A follower that owns the position is not checked: the value is never written to it.
	OM.Set(select(1, menu_row(root, 'target', 'name', 'position')), select(2, menu_row(root, 'target', 'name', 'position')), 'x_off', 4)
	eq(UF:IsOwn('target', 'name.position'), true)
	eq(OM.Validate(mroot, row, 'frame', 'SaftUIPageTestHung'), true, 'an owner is skipped')
end)

------------------------------------------------------------------ the invariant, and where a leaf is wrapped

-- A value for the row different from what it holds, by its type.
local function other(root, row)
	local type_ = row.type
	local option = row.option
	if type_ == 'toggle' then return not OM.Get(root, row) end
	if type_ == 'range' then
		local now = OM.Get(root, row)
		local min, max = OM.Member(root, row, 'min'), OM.Member(root, row, 'max')
		if min and now ~= min then return min end
		return max
	end
	if type_ == 'select' or type_ == 'font' then
		local now = OM.Get(root, row)
		local values = OM.Values(root, row) or {}
		local list = {}
		for key in pairs(values) do list[#list + 1] = key end
		table.sort(list, function(a, b) return tostring(a) < tostring(b) end)
		if type_ == 'font' then return now == 'header' and 'normal' or 'header' end
		for _, key in ipairs(list) do
			if key ~= now then return key end
		end
	end
	if type_ == 'input' then return OM.Get(root, row) == '23' and '24' or '23' end
	return nil
end

local function mutate(root, row)
	local type_ = row.type
	if type_ == 'color' then return OM.Set(root, row, 0.1, 0.2, 0.3, 1) end
	if type_ == 'position' then return OM.Set(root, row, 'x_off', (tonumber(OM.Get(root, row, 'x_off')) or 0) + 3) end
	if type_ == 'item' then return OM.Set(root, row, not OM.Get(root, row)) end
	local value = other(root, row)
	if value == nil then return nil end
	return OM.Set(root, row, value)
end

test('the invariant after every page set and share action: stored == what a member shows, every row of All units and three members', function()
	convert(true)
	local root = tree()
	local sets = 0
	for _, unit in ipairs({ 'all', 'party', 'target', 'raid10' }) do
		for _, entry in ipairs(rows_of(root, unit)) do
			local path = saved_of(entry.root, entry.row, unit)
			local setting = path and UF.SHARED_BY_PATH[path]
			if setting and (unit == 'all' or UF:HasShared(unit, setting.key)) then
				local ok = mutate(entry.root, entry.row)
				if ok then
					sets = sets + 1
					invariant(setting.key, unit .. ' ' .. path .. ' after a set')
					if unit ~= 'all' then
						check(UF:IsOwn(unit, setting.key), unit .. ' ' .. path .. ' is own after its set')
						OM.ShareCall(entry.root, entry.row, 'reset')
						invariant(setting.key, unit .. ' ' .. path .. ' after Reset')
						eq(UF:IsOwn(unit, setting.key), false)
					else
						OM.ShareCall(entry.root, entry.row, 'applyAll')
						invariant(setting.key, 'All ' .. path .. ' after All')
						eq(#UF:OwnersOf(setting.key), 0)
					end
				end
			end
		end
	end
	check(sets > 250, 'rows set: ' .. sets)
	-- And a sync has nothing to put right after all of it.
	eq(UF:SyncShared(UF:GetProfileConfig()), 0, 'the sync writes nothing')
end)

test('a mirrored leaf is decorated once: Health text and Power text are the part menu and the tab Text section', function()
	convert(true)
	local calls = 0
	local real = UF.OwnShared
	function UF:OwnShared(...) calls = calls + 1; return real(self, ...) end
	local root = tree()
	local mroot, row = menu_row(root, 'target', 'healthtext', 'font')
	OM.Set(mroot, row, 'header')
	eq(calls, 1, 'one own call for a set through the part menu')
	-- The same option on the Health tab's Text section.
	local tab_row = row_at(root, { 'Unitframes', 'target', 'Health', 'text', 'font' })
	eq(rawequal(tab_row.option, row.option), true, 'the very table')
	calls = 0
	OM.Set(root, tab_row, 'normal')
	eq(calls, 1, 'one own call for a set through the tab')
	UF.OwnShared = real
end)

test("every unit page's rows are as they were: the same rows, saved paths, gets and sets, ranges and values", function()
	-- A page with its shares and the same page without them (an unconverted profile) list the same rows with the
	-- same saved paths, types, names, ranges and values; only `share` and the set wrapper are added.
	local function inventory()
		local root = tree()
		local out = {}
		for _, unit in ipairs({ 'player', 'target', 'party', 'raid10', 'boss', 'nameplate', 'friendlynameplate' }) do
			for _, entry in ipairs(rows_of(root, unit)) do
				local option = entry.row.option
				local values
				if type(option.values) == 'table' then
					local list = {}
					for k, v in pairs(option.values) do list[#list + 1] = tostring(k) .. '=' .. tostring(v) end
					table.sort(list)
					values = table.concat(list, ',')
				end
				out[#out + 1] = table.concat({ unit, table.concat(entry.row.path, '/'), tostring(option.type), tostring(option.name),
					tostring((saved_of(entry.root, entry.row, unit))), tostring(option.min), tostring(option.max), tostring(option.step),
					tostring(type(option.get)), tostring(option.order), values or '' }, '|')
			end
		end
		return out
	end
	world()
	local profile = UF:GetProfileConfig()
	SW.customize(profile)
	local plain = inventory() -- not converted: no share anywhere
	UF:PrepareShared()
	local shared = inventory()
	eq(#shared, #plain, 'the same number of rows')
	local differ = {}
	for i = 1, #plain do
		if shared[i] ~= plain[i] then differ[#differ + 1] = plain[i] .. ' -> ' .. shared[i] end
	end
	eq(#differ, 0, 'every row is the same but for its share: ' .. table.concat(differ, '; '):sub(1, 400))
	check(#plain > 1000, 'rows walked: ' .. #plain)
end)

------------------------------------------------------------------ Copy from stays, writing the unit's own settings

test("Copy from writes what it copies as the unit's own settings, and only where it differs from All units", function()
	convert(true)
	local profile = UF:GetProfileConfig()
	profile.player.name.font = 'header'
	local before = {}
	for _, key in ipairs({ 'name.font', 'name.showLevel', 'name.maxLength' }) do before[key] = UF:IsOwn('target', key) end
	UF:CopySettings('target', 'player', { 'name' })
	-- Target's whole Name table is Player's now; what differs from All units' is its own, the rest follows.
	eq(profile.target.name.font, 'header')
	eq(UF:IsOwn('target', 'name.font'), true, 'a font that differs from All units\' is own')
	for _, entry in ipairs(UF.SHARED) do
		if entry.key:find('^name%.') and UF:HasShared('target', entry.key) then
			local differs = not UF.SameShared(entry, profile.target, rawget(profile, 'all'))
			check(UF:IsOwn('target', entry.key) == differs or UF:IsOwn('target', entry.key), entry.key .. ': own where it differs')
			if differs then check(UF:IsOwn('target', entry.key), entry.key .. ' is own') end
			invariant(entry.key, 'after Copy from')
		end
	end
	eq(UF:SyncShared(profile), 0, 'and nothing is put back by the sync')
	eq(profile.target.name.font, 'header', 'so the font stays')
end)

------------------------------------------------------------------ cost

test('cost: a held slider on All units makes little garbage, and each follower updates once per frame', function()
	convert(true)
	local root = tree()
	local mroot, row = menu_row(root, 'all', 'name', 'max_width')
	local updates = 0
	local real = UF.UpdateConfig
	function UF:UpdateConfig(unit, element)
		if unit ~= 'all' then updates = updates + 1 end
		return real(self, unit, element)
	end
	local ignore = { [UF.sharedTicker] = true }
	-- A drag of 60 steps inside one frame, then the frame.
	local m = C.measure(function()
		for value = 1, 60 do OM.Set(mroot, row, 60 + value) end
	end, 1, ignore)
	C.print('60 steps of a slider on All units', m)
	check(m.kb / 60 < 4, ('a step makes %.1f KB of garbage'):format(m.kb / 60))
	eq(updates, 0, 'no follower is updated before the frame')
	local frame = C.measure(function() SW.step(UF) end, 1, ignore)
	local followers = 0
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		if UF:HasShared(unit, 'name.max_width') and not UF:IsOwn(unit, 'name.max_width') then followers = followers + 1 end
	end
	eq(updates, followers, 'each follower once for the whole drag')
	UF.UpdateConfig = real
end)

------------------------------------------------------------------ combat

test('in combat a share action and an All units set are table writes only (S3)', function()
	convert(true)
	local root = tree()
	local mroot, row = menu_row(root, 'all', 'name', 'alpha')
	local mparty, prow = menu_row(root, 'party', 'name', 'alpha')
	OM.Set(mparty, prow, 0.4)
	stub.in_combat = true
	local ignore = { [UF.sharedTicker] = true }
	local function measure(label, fn)
		local m = C.measure(fn, 1, ignore)
		eq(m.forbidden.total, 0, label .. ': no forbidden call')
		eq(m.made, 0, label .. ': nothing made')
	end
	measure('a set on All units', function() OM.Set(mroot, row, 0.7) end)
	measure('a set on a unit', function() OM.Set(mparty, prow, 0.6) end)
	measure('Reset', function() OM.ShareCall(mparty, prow, 'reset') end)
	measure('Apply to All', function() OM.ShareCall(mparty, prow, 'applyAll') end)
	measure('Apply to Multiple', function() OM.ShareCall(mparty, prow, 'apply', { 'raid10' }) end)
	stub.in_combat = false
	eq(#stub.blocked, 0, 'nothing blocked')
end)

------------------------------------------------------------------ drawn

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

test("All units' General draws on whole pixels under Thick, Thin and Blizzard, and hovering a part row moves nothing", function()
	convert(true)
	_G.GameTooltip = _G.GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	local OB = st.OptionsBody
	local mparty, prow = menu_row(tree(), 'party', 'name', 'maxLength')
	OM.Set(mparty, prow, 9) -- party owns something in Name: the All units row has its diff icon
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			local root = tree()
			local content = CreateFrame('Frame', nil, UIParent)
			content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
			content:SetSize(774, 900)
			local body = OB.New(content, root, nil, 774)
			body:Draw(view_of(root, 'all').sections)
			local by = {}
			for _, c in ipairs(body.cells) do by[c.row.key] = c end
			eq(#P_.off(content), 0, look .. ': whole pixels: ' .. P_.report(P_.off(content)))
			check(by.name and by.name.widget.isPart, look .. ': the Name part row')
			local frame = by.name.frame
			local function rect(region) return table.concat({ region:GetLeft(), region:GetTop(), region:GetWidth(), region:GetHeight() }, ',') end
			local label = rect(by.name.widget.label or frame)
			local row_rect = rect(frame)
			stub.fire_script(frame, 'OnEnter', true)
			eq(rect(by.name.widget.label or frame), label, look .. ': the label does not move on hover')
			eq(rect(frame), row_rect, look .. ': the row does not move on hover')
			stub.fire_script(frame, 'OnLeave', true)
			eq(rect(by.name.widget.label or frame), label, look .. ': nor on leave')
			body:Release()
		end)
	end
end)

------------------------------------------------------------------ the pages while the profile does not share

test('while the profile does not share, no page has a share and All units says why', function()
	world()
	-- Not converted yet (the world starts so).
	local tree_ = UF:GetConfigTable()
	local shares = 0
	each_option({ args = { Unitframes = tree_ } }, function(option)
		if type(option) == 'table' and option.share ~= nil then shares = shares + 1 end
	end)
	eq(shares, 0, 'no share anywhere')
	local all = tree_.args.all
	check(all.args.general.args.notice ~= nil, 'a notice')
	eq(all.args.general.args.parts, nil, 'no settings')
	eq(all.pickerControl.args.copy, nil)
	-- The button turns it on where it can be asked for: after a restore.
	check(all.args.general.args.turnOn ~= nil)
	local root = { Unitframes = tree_ }
	local view = OM.BuildView(root, 'Unitframes')
	eq(view.picker.values[1].key, 'all', 'the entry is there')
	-- A restored profile: the button is shown and works.
	UF:PrepareShared()
	check(UF:RestoreShared())
	tree_ = UF:GetConfigTable()
	eq(tree_.args.all.args.general.args.turnOn.hidden, false, 'a restored profile can be turned on again')
	tree_.args.all.args.general.args.turnOn.func()
	eq(UF:SharedReady(), true, 'turned on')
	eq(UF:GetConfigTable().args.all.args.general.args.parts ~= nil, true, 'and All units has its settings')
end)
