-- SaftUI-Unitframes/config/shared.lua: the settings the unit frames share (All units): the list of
-- them against the member pages, who has and who owns a setting, the conversion and its numbers on a
-- fresh profile, every write of the API, the sync, the once-a-frame update, a conversion that fails,
-- the backup and its restore, an imported profile that has no All units, and that every call is table
-- writes only in combat.
--
-- Real: uf_world.lua's world (Core's helpers and defaults, the unit frames' defaults, config, the
-- elements) with config/shared.lua, on a profile filled the way AceDB fills one (tests/unitframes/
-- shared_world.lua; the upgrade tests use a real AceDB).
-- Stand-ins: UF:UpdateConfig where a case counts its calls.
local SW = load_test_file('unitframes/shared_world.lua')
local C = load_test_file('lib/color_cost.lua')

local st, UF, P

local function world()
	st, UF, P = SW.world()
	return st, UF, P
end

local function sorted(list)
	local copy = { unpack(list) }
	table.sort(copy)
	return copy
end

local function same_list(a, b, message)
	eq(table.concat(a, ','), table.concat(b, ','), message)
end

-- The number of settings a member owns, and which.
local function owned(unit)
	local keys = {}
	for _, entry in ipairs(UF.SHARED) do
		if UF:IsOwn(unit, entry.key) then keys[#keys + 1] = entry.key end
	end
	table.sort(keys)
	return keys
end

local function everything_follows()
	-- The invariant: every member that has a key and doesn't own it holds All units' value; an owner's is its own.
	local bad = {}
	for _, entry in ipairs(UF.SHARED) do
		for _, unit in ipairs(UF.SHARE_MEMBERS) do
			if UF:HasShared(unit, entry.key) and not UF:IsOwn(unit, entry.key) then
				if not UF.SameShared(entry, P[unit], P.all) then bad[#bad + 1] = unit .. '.' .. entry.key end
			end
		end
	end
	return #bad == 0, bad
end

test('UF.SHARED is every row the member pages show under a part or a bar, and the frame Theme and Background', function()
	world()
	eq(#UF.SHARED, 187, 'the entries')
	local seen = {}
	for _, unit in ipairs(SW.MEMBERS) do
		local keys, extra = SW.page_keys(UF, unit)
		for _, path in ipairs(extra) do check(false, unit .. "'s page has a row saved at " .. path .. ' that is no entry and not its own') end
		for key in pairs(keys) do seen[key] = true end
		-- Each page's value rows that are entries have the entry's type.
		for _, row in ipairs(SW.rows(UF, unit)) do
			local entry = row.path and UF.SHARED_BY_PATH[row.path]
			if entry and not row.hand then eq(row.type, entry.type, unit .. ' ' .. row.path .. "'s row type") end
		end
	end
	local missing = {}
	for _, entry in ipairs(UF.SHARED) do
		if not seen[entry.key] then missing[#missing + 1] = entry.key end
	end
	eq(#missing, 0, 'entries no member page has a row for: ' .. table.concat(missing, ', '))
	local count = 0
	for _ in pairs(seen) do count = count + 1 end
	eq(count, 187, 'the keys the pages show')
	-- The frame's own settings and the group layout have no entry.
	for _, key in ipairs({ 'enable', 'width', 'height', 'position', 'range_alpha.inside', 'growthDirection' }) do
		eq(UF.SHARED_BY_KEY[key], nil, key .. ' is not shared')
	end
	for _, entry in ipairs(UF.SHARED) do
		check(not entry.key:match('^classpower') and not entry.key:match('^additionalpower'), entry.key .. ' is shared')
		eq(UF.SHARED_BY_KEY[entry.key], entry, entry.key .. ' is indexed by key')
		for _, path in ipairs(entry.paths) do
			eq(UF.SHARED_BY_PATH[table.concat(path, '.')], entry, entry.key .. ' is indexed by its path')
		end
		eq(entry.since, 1, entry.key .. ' is a step 1 entry')
	end
end)

test('a member has a setting where its page shows the row', function()
	world()
	eq(UF:HasShared('player', 'name.show_classification'), false)
	eq(UF:HasShared('target', 'name.show_classification'), true)
	eq(UF:HasShared('targettarget', 'castbar.enable'), false)
	eq(UF:HasShared('party', 'readycheckindicator.enable'), true)
	eq(UF:HasShared('player', 'readycheckindicator.enable'), false)
	eq(UF:HasShared('nameplate', 'name.font'), false, 'a plate is no member')
	eq(UF:HasShared('all', 'readycheckindicator.enable'), true)
	eq(UF:HasShared('all', 'nonsense'), false)
	for _, unit in ipairs(SW.MEMBERS) do
		local keys = SW.page_keys(UF, unit)
		for _, entry in ipairs(UF.SHARED) do
			eq(UF:HasShared(unit, entry.key), keys[entry.key] == true, unit .. ' ' .. entry.key)
		end
	end
end)

test('a fresh profile converts to the spec: All units at its defaults, 155 owned settings', function()
	world()
	local before = SW.snapshot(P)
	UF:ConvertShared(P)
	eq(rawget(P.all, 'version'), 1, 'the marker')
	for _, entry in ipairs(UF.SHARED) do
		check(UF.SameShared(entry, P.all, UF.DefaultShared(entry)), entry.key .. ' in All units is its default')
	end
	local counts = { player = 29, target = 19, targettarget = 2, focus = 21, focustarget = 2, pet = 2, pettarget = 2,
		boss = 10, party = 19, raid10 = 24, raid40 = 25 }
	local total = 0
	for _, unit in ipairs(SW.MEMBERS) do
		eq(#owned(unit), counts[unit], unit .. "'s owned settings")
		total = total + #owned(unit)
	end
	eq(total, 155, 'owned settings in all')
	same_list(owned('party'), { 'buffs.cooldown.alpha', 'buffs.cooldown.timer.enable', 'buffs.enable', 'buffs.framelevel',
		'buffs.initial_anchor', 'buffs.onlyShowPlayer', 'buffs.position', 'buffs.size', 'debuffs.framelevel',
		'debuffs.grow_right', 'debuffs.initial_anchor', 'debuffs.position', 'debuffs.size',
		'grouproleindicator.enable', 'health.text.deficit', 'health.text.enable', 'name.maxLength',
		'name.position', 'name.showLevel' }, "party's owned settings")
	same_list(owned('raid10'), { 'buffs.cooldown.alpha', 'buffs.cooldown.timer.enable', 'buffs.framelevel',
		'buffs.initial_anchor', 'buffs.onlyShowPlayer', 'buffs.position', 'buffs.theme', 'debuffs.framelevel',
		'debuffs.initial_anchor', 'debuffs.max', 'debuffs.per_row', 'debuffs.position', 'debuffs.size',
		'debuffs.spacing', 'debuffs.theme', 'frame.background', 'frame.theme', 'health.text.deficit',
		'health.text.enable', 'health.text.hide_full', 'name.maxLength', 'name.position', 'name.showLevel',
		'power.height' }, "raid10's owned settings")
	same_list(UF:OwnersOf('name.position'), { 'party', 'raid10', 'raid40' })
	same_list(UF:OwnersOf('debuffs.enable'), { 'targettarget', 'focustarget', 'pet', 'pettarget', 'raid40' })
	-- Nothing a member shows changed.
	local ok, diffs = SW.same(before, SW.snapshot(P))
	check(ok, 'the members show what they showed: ' .. table.concat(diffs, ', '))
	check(everything_follows())
end)

test('a tie goes to the default, then to the first member', function()
	world()
	UF:ConvertShared(P)
	-- Castbar Enable: Player, Target, Focus and Boss on, the other four off: the default (off) wins.
	eq(P.all.castbar.enable, false)
	same_list(UF:OwnersOf('castbar.enable'), { 'player', 'target', 'focus', 'boss' })
	-- A tie the default isn't in: the first member's value. Raid 40 and Raid 10 on, the rest off: no tie. Make 5 on, 5 off
	-- of ten on a key two units lack, with a value that is neither the default.
	world()
	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget' }) do P[unit].name.alpha = 0.5 end
	for _, unit in ipairs({ 'pet', 'pettarget', 'boss', 'party', 'raid10' }) do P[unit].name.alpha = 0.25 end
	-- raid40 stays at 1: three values, 5 / 5 / 1. The first member's group wins the tie.
	UF:ConvertShared(P)
	eq(P.all.name.alpha, 0.5, 'the first member among the tied')
	same_list(UF:OwnersOf('name.alpha'), { 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' })
end)

test('the conversion runs once and writes nothing into a member', function()
	world()
	local before = SW.snapshot(P)
	UF:ConvertShared(P)
	local ok, diffs = SW.same(before, SW.snapshot(P))
	check(ok, 'no member changed: ' .. table.concat(diffs, ', '))
	local after = {}
	for _, unit in ipairs(SW.MEMBERS) do after[unit] = owned(unit) end
	P.target.castbar.height = 77 -- an edit the second call must not look at
	UF:ConvertShared(P)
	for _, unit in ipairs(SW.MEMBERS) do same_list(owned(unit), after[unit], unit .. ' owns the same') end
	eq(P.target.castbar.height, 77)
	eq(UF:SyncShared(P), 0, 'the sync has nothing to put right')
end)

test('a fresh profile writes nothing into All units', function()
	world()
	local function raw(t)
		local copy = {}
		for k, v in pairs(t) do copy[k] = type(v) == 'table' and raw(v) or v end
		return copy
	end
	local before = raw(P.all)
	UF:ConvertShared(P)
	local after = raw(P.all)
	eq(after.version, 1)
	after.version = nil
	-- Every value All units held is as it was. (Reading a setting through AceDB's wildcard makes the
	-- tables the wildcard fills, buffs.friend and buffs.enemy: they hold only defaults.)
	local function walk(was, now, path)
		for k, v in pairs(was) do
			if type(v) == 'table' then
				walk(v, type(now[k]) == 'table' and now[k] or {}, path .. '.' .. tostring(k))
			elseif path == '.debuffs' and k == 'enable' then
				-- The one value All units' own defaults give it (config/units/all.lua), written by the conversion.
				eq(v, false, 'All units held the wildcard default before')
				eq(now[k], true, 'All units takes Debuffs on')
			else
				eq(now[k], v, 'All units ' .. path .. '.' .. tostring(k))
			end
		end
		for k, v in pairs(now) do
			if was[k] == nil and k ~= 'friend' and k ~= 'enemy' and not path:find('friend', 1, true) and not path:find('enemy', 1, true) then
				if type(v) == 'table' then
					check(next(v) == nil, 'All units gained ' .. path .. '.' .. tostring(k))
				else
					check(false, 'All units gained ' .. path .. '.' .. tostring(k))
				end
			end
		end
	end
	walk(before, after, '')
end)

test('SetShared on All units writes every follower and skips an owner', function()
	world()
	UF:ConvertShared(P)
	same_list(UF:SetShared('target', 'name.font', 'pixel'), { 'target' }, 'a member write that changes it reports its unit')
	same_list(UF:SetShared('target', 'name.font', 'normal'), { 'target' })
	eq(UF:IsOwn('target', 'name.font'), true, 'target owns it')
	local changed = UF:SetShared('all', 'name.font', 'pixel')
	for _, unit in ipairs(SW.MEMBERS) do
		eq(P[unit].name.font, unit == 'target' and 'normal' or 'pixel', unit .. "'s name font")
	end
	eq(P.all.name.font, 'pixel')
	same_list(changed, { 'player', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' },
		'the ten followers in member order')
	same_list(UF:SetShared('all', 'name.font', 'pixel'), {}, 'nothing to change, nothing reported')
	-- A member that lacks the setting is never written.
	same_list(UF:SetShared('targettarget', 'castbar.enable', true), {})
	eq(UF:IsOwn('targettarget', 'castbar.enable'), false)
	check(everything_follows())
end)

test('FollowAll, ApplyToAll and ApplyTo', function()
	world()
	UF:ConvertShared(P)
	UF:SetShared('target', 'name.font', 'normal')
	UF:SetShared('all', 'name.font', 'pixel')
	same_list(UF:FollowAll('target', 'name.font'), { 'target' })
	eq(UF:IsOwn('target', 'name.font'), false)
	eq(P.target.name.font, 'pixel')
	same_list(UF:FollowAll('target', 'name.font'), {}, 'already following')
	-- Party shows levels in no profile by default: All units and all but three members do.
	same_list(UF:ApplyToAll('party', 'name.showLevel'), { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss' },
		'the members whose stored value changed (Raid 10 and Raid 40 held false already)')
	check(P.all.name.showLevel == false or P.all.name.showLevel == nil, 'All units takes false')
	for _, unit in ipairs(SW.MEMBERS) do
		eq(UF:IsOwn(unit, 'name.showLevel'), false, unit .. ' follows')
		check(not P[unit].name.showLevel, unit .. ' stores false')
	end
	-- ApplyTo from a member whose value differs from All units': the targets own it.
	UF:SetShared('target', 'health.text.percent', true)
	same_list(UF:ApplyTo('target', 'health.text.percent', { 'focus', 'boss' }), { 'focus', 'boss' })
	eq(UF:IsOwn('focus', 'health.text.percent'), true)
	eq(UF:IsOwn('boss', 'health.text.percent'), true)
	eq(P.focus.health.text.percent, true)
	eq(P.boss.health.text.percent, true)
	eq(P.player.health.text.percent, false, 'a unit that was not named is untouched')
	-- ApplyTo with the value equal to All units': the targets follow.
	UF:SetShared('pet', 'health.text.percent', false)
	same_list(UF:ApplyTo('pet', 'health.text.percent', { 'focus' }), { 'focus' })
	eq(UF:IsOwn('focus', 'health.text.percent'), false)
	eq(P.focus.health.text.percent, false)
	-- From All units: the targets follow.
	same_list(UF:ApplyTo('all', 'health.text.percent', { 'boss', 'target' }), { 'target', 'boss' }, 'in member order')
	eq(UF:IsOwn('boss', 'health.text.percent'), false)
	eq(P.target.health.text.percent, false)
	-- A target that lacks the setting is skipped.
	same_list(UF:ApplyTo('target', 'castbar.enable', { 'targettarget' }), {})
	eq(UF:IsOwn('targettarget', 'castbar.enable'), false)
	same_list(UF:OwnersOf('health.text.percent'), { 'pet' })
	check(everything_follows())
end)

test('a position is copied part by part; a missing anchor written as false', function()
	world()
	UF:ConvertShared(P)
	UF:SetShared('all', 'name.position', { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 2 })
	for _, unit in ipairs(SW.MEMBERS) do
		local position = P[unit].name.position
		if not UF:IsOwn(unit, 'name.position') then
			eq(position.point, 'TOP', unit)
			eq(position.rel_point, 'TOP', unit)
			eq(position.element, false, unit .. ' element')
			eq(position.frame, false, unit .. ' frame')
			eq(position.x_off, 0, unit .. ' x_off is a number')
			eq(position.y_off, 2, unit .. ' y_off')
		end
	end
	eq(P.target.name.position.element, false)
	-- Offsets given as text become numbers, and a part alone writes only that part.
	UF:SetShared('all', 'name.position', '8', 'x_off')
	eq(P.target.name.position.x_off, 8)
	eq(P.target.name.position.y_off, 2)
	check(everything_follows())
end)

test('a color is copied in place in each shape', function()
	world()
	local green = CreateColor(1, 1, 1)
	green:SetRGB(0, 1, 0)
	P.target.castbar.colors.normal = green
	P.focus.castbar.colors.normal = { r = 0, g = 0, b = 1 }
	P.player.castbar.colors.normal = { 0.1, 0.2, 0.3 }
	UF:ConvertShared(P)
	for _, unit in ipairs({ 'target', 'focus', 'player' }) do UF:FollowAll(unit, 'castbar.colors.normal') end
	local objectBefore, mapBefore, listBefore = P.target.castbar.colors.normal, P.focus.castbar.colors.normal, P.player.castbar.colors.normal
	UF:SetShared('all', 'castbar.colors.normal', { r = 1, g = 0, b = 0 })
	eq(rawequal(P.target.castbar.colors.normal, objectBefore), true, "target's color object keeps its identity")
	eq(rawequal(P.focus.castbar.colors.normal, mapBefore), true, "focus's map keeps its identity")
	eq(rawequal(P.player.castbar.colors.normal, listBefore), true, "player's list keeps its identity")
	local r, g, b = P.target.castbar.colors.normal:GetRGB()
	eq(r .. g .. b, '100', "the object's GetRGB")
	eq(P.focus.castbar.colors.normal.r .. P.focus.castbar.colors.normal.g .. P.focus.castbar.colors.normal.b, '100')
	eq(P.player.castbar.colors.normal[1] .. P.player.castbar.colors.normal[2] .. P.player.castbar.colors.normal[3], '100')
	check(everything_follows())
end)

test('a typeface is copied, never shared', function()
	world()
	UF:ConvertShared(P)
	local face = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }
	UF:SetShared('all', 'name.font', face)
	eq(rawequal(P.all.name.font, face), false, 'All units holds a copy of what the caller passed')
	eq(P.all.name.font.font_name, 'Homespun')
	eq(rawequal(P.target.name.font, P.all.name.font), false, "target's is a copy")
	eq(rawequal(P.player.name.font, P.target.name.font), false, 'and not shared between followers')
	eq(P.target.name.font.font_name, 'Homespun')
	P.all.name.font.font_size = 20
	eq(P.target.name.font.font_size, 12, 'a change to All units does not reach the copy by reference')
end)

test('a colortoggle row: both unticked are the same whatever the hidden color', function()
	world()
	local entry = UF.SHARED_BY_KEY['health.customColor']
	eq(entry.type, 'colortoggle')
	local a = { health = { colorCustom = false, customColor = { 1, 0, 0 } } }
	local b = { health = { colorCustom = false, customColor = { 0, 1, 0 } } }
	check(UF.SameShared(entry, a, b), 'both unticked')
	b.health.colorCustom = true
	check(not UF.SameShared(entry, a, b), 'ticked against unticked')
	a.health.colorCustom = true
	check(not UF.SameShared(entry, a, b), 'both ticked, different colors')
	b.health.customColor = { 1, 0, 0 }
	check(UF.SameShared(entry, a, b), 'both ticked, the same color')
	b.health.customColor = CreateColor(1, 0, 0)
	check(UF.SameShared(entry, a, b), 'a list and an object of the same color')
	-- Copying: the toggle and the color, in place.
	local color = { 0.5, 0.5, 0.5 }
	local to = { health = { colorCustom = false, customColor = color } }
	UF.CopyShared(entry, a, to)
	eq(to.health.colorCustom, true)
	eq(rawequal(to.health.customColor, color), true)
	eq(color[1], 1)
	-- The aura border has both hostilities' paths.
	local border = UF.SHARED_BY_KEY['buffs.border']
	local x = { buffs = { friend = { colorStealable = true }, enemy = { colorStealable = false } } }
	local y = { buffs = { friend = { colorStealable = false }, enemy = { colorStealable = true } } }
	check(not UF.SameShared(border, x, y), 'each hostility is compared')
	UF.CopyShared(border, x, y)
	check(UF.SameShared(border, x, y))
end)

test('offsets are compared as numbers, at every scale', function()
	world()
	local entry = UF.SHARED_BY_KEY['name.position']
	local function at(x) return { name = { position = { point = 'LEFT', rel_point = 'LEFT', element = 'Health', x_off = x, y_off = 0 } } } end
	check(UF.SameShared(entry, at('5'), at(5)), "'5' is 5")
	check(not UF.SameShared(entry, at(5), at(5.4)), 'a fraction is a difference: no pixel rounding in the compare')
	check(UF.SameShared(entry, { name = { position = { point = 'LEFT', element = 'Health', x_off = 0 } } },
		{ name = { position = { point = 'LEFT', rel_point = 'LEFT', element = 'Health', x_off = '0', y_off = 0 } } }),
		'a missing relative point is the point, a missing offset is 0')
	local screen = { name = { position = { point = 'LEFT', frame = 'UIParent', x_off = 0, y_off = 0 } } }
	local unit = { name = { position = { point = 'LEFT', frame = false, x_off = 0, y_off = 0 } } }
	check(not UF.SameShared(entry, screen, unit), 'the screen is not the unit frame')
end)

test('the sync puts right a drift and writes nothing else', function()
	world()
	UF:ConvertShared(P)
	eq(UF:SyncShared(P), 0, 'converted fresh: nothing to put right')
	UF:SetShared('target', 'name.font', 'normal')
	UF:FollowAll('target', 'name.font')
	rawset(P.target.name, 'font', 'pixel') -- a drift: target follows 'normal'
	eq(UF:SyncShared(P), 1)
	eq(P.target.name.font, 'normal')
	eq(UF:SyncShared(P), 0)
	-- An owner keeps its own.
	UF:SetShared('target', 'name.font', 'pixel')
	eq(UF:SyncShared(P), 0)
	eq(P.target.name.font, 'pixel')
	-- A key a member doesn't have is never written.
	P.targettarget.castbar.enable = true
	eq(UF:SyncShared(P), 0)
	eq(P.targettarget.castbar.enable, true)
end)

test('the invariant: after every API call stored equals what a member shows', function()
	world()
	UF:ConvertShared(P)
	local calls = {
		function() UF:SetShared('all', 'name.font', 'pixel') end,
		function() UF:SetShared('target', 'name.font', 'normal') end,
		function() UF:SetShared('all', 'health.text.position', { point = 'LEFT', rel_point = 'LEFT', element = 'Health', x_off = 3, y_off = 1 }) end,
		function() UF:SetShared('party', 'name.maxLength', 12) end,
		function() UF:SetShared('all', 'castbar.colors.normal', { r = 0.2, g = 0.4, b = 0.6 }) end,
		function() UF:FollowAll('party', 'name.maxLength') end,
		function() UF:ApplyToAll('raid40', 'debuffs.enable') end,
		function() UF:ApplyTo('player', 'power.height', { 'target', 'pet' }) end,
		function() UF:SetShared('all', 'buffs.border', true) end,
		function() UF:SetShared('all', 'health.customColor', { toggle = true, color = { r = 0.3, g = 0.3, b = 0.3 } }) end,
		function() UF:ApplyToAll('target', 'name.font') end,
	}
	local function first(config, entry)
		local node = config
		for _, key in ipairs(entry.paths[1]) do
			if type(node) ~= 'table' then return nil end
			node = node[key]
		end
		return node
	end
	for i, call in ipairs(calls) do
		call()
		local ok, bad = everything_follows()
		check(ok, 'after call ' .. i .. ': ' .. table.concat(bad, ', '))
		for _, entry in ipairs(UF.SHARED) do
			for _, unit in ipairs(SW.MEMBERS) do
				if UF:HasShared(unit, entry.key) and not UF:IsOwn(unit, entry.key) then
					check(rawequal(UF:SharedValue(unit, entry.key), first(P.all, entry)), unit .. ' ' .. entry.key .. ": SharedValue is All units' stored value")
				end
			end
		end
	end
	-- SharedValue is the member's own where it owns the key or doesn't have it.
	UF:SetShared('target', 'name.font', 'normal')
	eq(UF:SharedValue('target', 'name.font'), 'normal')
	eq(UF:SharedValue('all', 'name.font'), P.all.name.font)
	eq(UF:SharedValue('targettarget', 'castbar.enable'), P.targettarget.castbar.enable, 'a member that lacks it reads its stored value')
end)

test('a key no step covers fails', function()
	world()
	local entry = UF.SHARED_BY_KEY['name.font']
	entry.since = 2
	local ok, err = pcall(UF.ConvertShared, UF, P)
	entry.since = 1
	eq(ok, false)
	check(tostring(err):find('name.font', 1, true) and tostring(err):find('no conversion step covers it', 1, true), tostring(err))
	eq(rawget(P.all, 'version'), nil, 'no marker')
	-- Through the guarded entry it is reported and the profile is left alone.
	entry.since = 2
	eq(UF:PrepareShared(P), false)
	entry.since = 1
	eq(#take_errors(), 1)
end)

test('UpdateShared runs each changed unit once on the next frame, however many changes came', function()
	world()
	UF:ConvertShared(P)
	local calls = {}
	function UF:UpdateConfig(unit, element) calls[#calls + 1] = tostring(unit) .. ':' .. tostring(element) end
	local changed
	for n = 1, 50 do
		changed = UF:SetShared('all', 'name.max_width', n)
		UF:UpdateShared(changed, 'Name')
	end
	eq(#calls, 0, 'nothing yet')
	eq(UF.sharedTicker:IsShown(), true)
	SW.step(UF)
	same_list(calls, { 'player:Name', 'target:Name', 'targettarget:Name', 'focus:Name', 'focustarget:Name', 'pet:Name', 'pettarget:Name',
		'boss:Name', 'party:Name', 'raid10:Name', 'raid40:Name' }, 'one call per follower, in member order')
	eq(UF.sharedTicker:IsShown(), false)
	SW.step(UF)
	eq(#calls, 11, 'and none the frame after')
	-- A whole-unit mark covers the element marks.
	calls = {}
	UF:UpdateShared({ 'party' }, 'Name')
	UF:UpdateShared({ 'party' })
	SW.step(UF)
	same_list(calls, { 'party:nil' })
	-- Units that aren't members are left out.
	calls = {}
	UF:UpdateShared({ 'nameplate' }, 'Name')
	eq(UF.sharedTicker:IsShown(), false)
end)

test('PropagateShared copies one element\'s entries and marks only the units that changed', function()
	world()
	UF:ConvertShared(P)
	local calls = {}
	function UF:UpdateConfig(unit, element) calls[#calls + 1] = unit .. ':' .. tostring(element) end
	-- A drift only on Name's entries, in two units.
	P.all.name.font = 'pixel'
	P.all.health.text.font = 'pixel'
	local changed = UF:PropagateShared('Name')
	eq(#changed, 11, 'every member that follows the name font')
	eq(P.player.name.font, 'pixel')
	eq(P.player.health.text.font, 'normal', "another element's entries are left to its own call")
	SW.step(UF)
	eq(#calls, 11)
	eq(calls[1], 'player:Name')
	calls = {}
	same_list(UF:PropagateShared('Name'), {}, 'nothing changed, nothing marked')
	SW.step(UF)
	eq(#calls, 0)
	-- The frame's own entries.
	P.all.theme = 'thin'
	same_list(UF:PropagateShared(nil), { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party' }, 'the groups that draw in the theme own theirs')
	SW.step(UF)
	eq(calls[#calls], 'party:nil')
end)

test('in combat every API call is table writes only (S3)', function()
	world()
	UF:ConvertShared(P)
	UF:SetShared('target', 'name.font', 'normal')
	local ignore = { [UF.sharedTicker] = true }
	stub.in_combat = true
	local function measure(label, fn)
		local m = C.measure(fn, 1, ignore)
		eq(m.forbidden.total, 0, label .. ': no forbidden call')
		eq(m.made, 0, label .. ': nothing made')
		eq(m.calls.total, 0, label .. ': no setter on a widget')
	end
	measure('SetShared', function() UF:SetShared('all', 'name.font', 'pixel') end)
	measure('ApplyToAll', function() UF:ApplyToAll('party', 'name.showLevel') end)
	measure('FollowAll', function() UF:FollowAll('target', 'name.font') end)
	measure('UpdateShared', function() UF:UpdateShared({ 'player' }, 'Name') end)
	measure('SyncShared', function() UF:SyncShared(P) end)
	function UF:UpdateConfig() end -- the real one queues for the end of combat, which its own tests cover
	measure('the ticker', function() SW.step(UF) end)
	-- The conversion, on a profile that has not been converted.
	world()
	stub.in_combat = true
	measure('ConvertShared', function() UF:ConvertShared(P) end)
	world()
	stub.in_combat = true
	measure('PrepareShared', function() UF:PrepareShared(P) end)
	stub.in_combat = false
end)

test('a conversion that fails leaves every member and flag as it was, and the sync writes nothing', function()
	world()
	local before = SW.snapshot(P)
	-- The sixth member (pet) fails when read.
	local good = P.pet
	P.pet = setmetatable({}, { __index = function() error('boom', 0) end })
	local ok = UF:PrepareShared(P)
	eq(ok, false, 'reported, not raised')
	eq(#take_errors(), 1, 'through the error handler')
	P.pet = good
	eq(rawget(P.all, 'version'), nil, 'no marker')
	eq(rawget(P, 'backup'), nil, 'no backup')
	for _, unit in ipairs(SW.MEMBERS) do eq(rawget(P[unit], 'own'), nil, unit .. ' has no flags') end
	local same, diffs = SW.same(before, SW.snapshot(P))
	check(same, 'values as they were: ' .. table.concat(diffs, ', '))
	eq(UF:SharedReady(P), false)
	-- A profile that differs from All units' defaults is not overwritten by the sync of a failed conversion.
	P.target.name.font = 'pixel'
	P.pet = setmetatable({}, { __index = function() error('boom', 0) end })
	UF:PrepareShared(P)
	take_errors()
	P.pet = good
	eq(P.target.name.font, 'pixel')
	-- Not tried again this session (one message, not one per update): the owner's ask tries again, and
	-- once the profile reads it converts.
	eq(UF:PrepareShared(P), false, 'a failed profile is not retried by every update')
	eq(UF:SharedState(P), 'failed')
	eq(UF:EnableShared(P), true)
	eq(UF:SharedReady(P), true)
	eq(P.target.name.font, 'pixel')
end)

test('PrepareShared converts, then syncs only a converted profile', function()
	world()
	eq(UF:PrepareShared(P), true)
	eq(rawget(P.all, 'version'), 1)
	rawset(P.target.name, 'font', 'pixel') -- a drift
	eq(UF:PrepareShared(P), true)
	eq(P.target.name.font, 'normal', 'the sync ran')
	-- A marker above this version (a newer SaftUI converted it): left alone, no sync.
	rawset(P.all, 'version', UF.SHARED_VERSION + 1)
	rawset(P.target.name, 'font', 'pixel')
	eq(UF:PrepareShared(P), false)
	eq(UF:SharedState(P), 'newer')
	eq(P.target.name.font, 'pixel')
	-- A non-number marker counts as 0.
	rawset(P.all, 'version', 'x')
	eq(UF:SharedReady(P), false)
end)

test('the one-time backup holds the shared settings and their flags, and putting it back changes only those', function()
	world()
	P.target.name.font = 'pixel'
	P.player.buffs.size = 31
	local before = SW.snapshot(P)
	UF:ConvertShared(P)
	local backup = rawget(P, 'backup')
	eq(type(backup), 'table', 'a backup was made')
	eq(backup.version, 1)
	eq(type(backup.when), 'number')
	for _, unit in ipairs(SW.MEMBERS) do eq(type(backup.units[unit]), 'table', unit .. ' is in it') end
	eq(backup.units.nameplate, nil, 'no plate')
	eq(backup.units.all, nil, 'no All units')
	eq(backup.units.target.values['name.font'], 'pixel', 'the value it had')
	eq(backup.units.player.values['buffs.size'], 31)
	eq(backup.units.targettarget.values['castbar.enable'], nil, 'a setting the unit lacks is not in it')
	eq(getmetatable(backup.units.target), nil, 'plain data')
	-- Only the shared settings: no unit place, size or other key.
	for _, saved in pairs(backup.units) do
		for key in pairs(saved.values) do check(UF.SHARED_BY_PATH[key], key .. ' is a shared path') end
	end
	-- It is made once: later changes and another conversion leave it.
	P.target.name.font = 'normal'
	rawset(P.all, 'version', nil)
	UF:ConvertShared(P)
	eq(rawget(P, 'backup'), backup)
	eq(backup.units.target.values['name.font'], 'pixel')
	-- Changes the conversion and sharing could not make stay as the player has them now.
	P.nameplate.name.font = 'pixel'
	P.player.width = 411
	P.player.position.x_off = 123
	P.player.classpower.height = 9
	P.raid10.width = 77
	local targetTable = P.target
	UF:SetShared('target', 'name.font', 'header')
	UF:SetShared('all', 'health.text.font', 'pixel')
	check(UF.HasSharedBackup(P))
	local restored, why = UF:RestoreShared(P)
	eq(restored, true, tostring(why))
	eq(rawequal(P.target, targetTable), true, 'the unit table keeps its identity')
	eq(P.target.name.font, 'pixel', 'the setting is as it was before sharing')
	eq(P.player.health.text.font, 'normal')
	eq(rawget(P.target, 'own') == nil or rawget(P.target, 'own')['name.font'] == nil, true, 'no flag')
	eq(rawget(P.all, 'version'), nil, 'no marker')
	eq(UF:SharedReady(P), false)
	eq(P.nameplate.name.font, 'pixel', 'a plate is as the player has it')
	eq(P.player.width, 411)
	eq(P.player.position.x_off, 123)
	eq(P.player.classpower.height, 9)
	eq(P.raid10.width, 77)
	eq(rawget(P, 'backup'), backup, 'the backup stays')
	for _, unit in ipairs(SW.MEMBERS) do
		for _, entry in ipairs(UF.SHARED) do check(not UF:IsOwn(unit, entry.key), unit .. ' ' .. entry.key .. ' is not owned') end
	end
	local ok, diffs = SW.same(before, SW.snapshot(P))
	local only = {}
	for _, d in ipairs(diffs) do
		if not (d:match('^player%.width$') or d:match('^player%.position$') or d:match('^raid10%.width$')) then only[#only + 1] = d end
	end
	eq(#only, 0, 'every shared setting is as it was: ' .. table.concat(only, ', '))
	-- A restored profile is not converted again by a login or an update; asking for it is.
	eq(UF:PrepareShared(P), false)
	eq(UF:SharedState(P), 'restored')
	eq(UF:SharedReady(P), false)
	eq(UF:EnableShared(P), true)
	eq(UF:SharedReady(P), true)
	-- No backup, no restore.
	world()
	local nothing, reason = UF:RestoreShared(P)
	eq(nothing, false)
	check(type(reason) == 'string' and #reason > 0)
end)

test('a profile copy or export leaves the backup out', function()
	world()
	UF:ConvertShared(P)
	check(rawget(P, 'backup') ~= nil)
	local copy = UF.CopyProfileData(P)
	eq(rawget(copy, 'backup'), nil, 'the copy has none')
	eq(rawget(P, 'backup') ~= nil, true, 'the source keeps it')
	eq(rawget(copy.all, 'version'), 1, 'the marker is carried')
	check(rawget(copy, 'target') ~= nil or copy.target ~= nil, 'the units are carried')
	check(not rawequal(copy.target, P.target), 'a deep copy')
end)

test('the backup is small: the shared values, not the profile', function()
	world()
	SW.customize(P)
	UF:ConvertShared(P)
	local function size(value, seen)
		if type(value) ~= 'table' then return #tostring(value) + 2 end
		local total = 2
		for k, v in pairs(value) do total = total + #tostring(k) + 2 + size(v) end
		return total
	end
	local backup, rest = size(rawget(P, 'backup')), 0
	for k, v in pairs(P) do if k ~= 'backup' and type(v) == 'table' then rest = rest + size(v) end end
	print(('backup %d characters, the rest of the profile %d'):format(backup, rest))
	check(backup < rest / 2, 'smaller than half of the profile')
	check(backup < 40000, 'under 40000 characters: ' .. backup)
end)

test('the interface is table writes: no function of the file touches a frame but the ticker', function()
	local source = read_saftui_source('SaftUI-Unitframes/config/shared.lua')
	for _, word in ipairs({ 'SetPoint', 'ClearAllPoints', 'SetSize', 'SetWidth', 'SetHeight', 'SetAttribute', 'SetParent', 'RegisterEvent' }) do
		check(not source:find(word, 1, true), 'shared.lua never calls ' .. word)
	end
end)
