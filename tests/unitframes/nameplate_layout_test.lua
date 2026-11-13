-- The nameplate's layout: the plate's defaults
-- (SaftUI-Unitframes/config/units/nameplate.lua), the name's Max width
-- (elements/name.lua) and the quest icon (elements/indicators.lua):
--   - the bar is 200 by 20 and fills the plate, the name inside it on the
--     left, cut at 150 pixels, the health inside on the right as a short
--     value (12.5K), never a percent;
--   - the castbar hangs 6 under the bar, 182 by 12, its 12x12 icon 6 to its
--     left, so the row starts at the bar's left edge; the spell name inside on
--     the left, no time, and a grey for a cast that can't be interrupted;
--   - up to 6 of the player's debuffs above the bar from its left edge, up to
--     4 buffs the player can purge right of it, and nothing of the layout's
--     above the bar's right end (where the threat text goes);
--   - the quest icon left of the bar, the raid mark centred above the debuff
--     row;
--   - hostile names coloured, with no level and no classification mark;
--   - the quest icon shows for a unit tied to one of the player's active
--     quests, else for a quest boss, a secret answer counting as no, and
--     every frame that shows it asks again when the quest log changes;
--   - Max width on every unit's Name tab, 0 leaving the name unsized.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), the plates spawned with the defaults as
-- they are. Rects are compared only between SaftUI's parts, which share a
-- scale. The stand-in runs no element updates of its own: a cast, an aura or a
-- tag never arrives, so what they would show is driven here by hand (the
-- health's PostUpdate, the name tag's text, the quest icon's ForceUpdate).
local NP = load_test_file('unitframes/nameplate_world.lua')
local S = load_test_file('lib/secrets.lua')

-- A world with the plates spawned, and the nameplate's config.
local function world(client)
	local st, UF = NP.world(client or 'forever')
	UF:SpawnNameplates()
	return st, UF, UF:GetProfileConfig().nameplate
end

-- An enemy on a plate: a hostile level 22 elite Kobold (fields add to it or
-- replace its own). Returns SaftUI's frame on the plate.
local function enemy(unit, fields)
	local data = { name = 'Kobold', level = 22, reaction = 2, classification = 'elite', friend = false, attackable = true }
	for key, value in pairs(fields or {}) do data[key] = value end
	stub.units[unit] = data
	return NP.add(unit)
end

-- A region's first point, as 'POINT,relative,RELPOINT,x,y' with relative
-- named by who (a table of region -> name).
local function point(region, who)
	local p, rel, relPoint, x, y = region:GetPoint(1)
	return table.concat({ tostring(p), tostring(who[rel] or rel), tostring(relPoint), tostring(x), tostring(y) }, ',')
end

-- Whether two regions' rects overlap (sharing only an edge doesn't count).
local function overlaps(a, l, r, b, t)
	local al, ar, ab, at = a:GetLeft(), a:GetRight(), a:GetBottom(), a:GetTop()
	return al < r and ar > l and ab < t and at > b
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the bar is 200 by 20 and fills the plate; the name inside left, the health value inside right', function()
		local st, UF, P = world(client)
		local frame = enemy('nameplate1')
		local health = frame.Health
		eq(health:GetWidth(), 200, 'the bar is 200 wide')
		eq(health:GetHeight(), 20, 'and 20 tall')
		check(UF.FillsFrame(P.health), "the bar's config fills its frame")
		check(near(health:GetLeft(), frame:GetLeft()) and near(health:GetRight(), frame:GetRight())
			and near(health:GetTop(), frame:GetTop()) and near(health:GetBottom(), frame:GetBottom()),
			'the bar covers the plate frame')

		local who = { [health] = 'Health' }
		eq(point(frame.Name, who), 'LEFT,Health,LEFT,4,0', 'the name 4 in from the bar\'s left')
		eq(point(health.text, who), 'RIGHT,Health,RIGHT,-4,0', 'the health text 4 in from its right')
		eq(frame.Name:IsShown(), true, 'the name shown')
		eq(health.text:IsShown(), true, 'the health text shown')

		-- The health as a short value, a skull-level unit's too: no percent.
		local text = P.health.text
		eq(text.short, true, 'Short on')
		eq(text.percent, false, 'Percent off')
		eq(text.boss_percent, false, 'Boss percent off')
		health.PostUpdate(health, 'nameplate1', 12500, 20000)
		eq(health.text:GetText(), '12.5K', 'the health in short form')
		stub.units.nameplate1.level = -1
		health.PostUpdate(health, 'nameplate1', 1250000, 2000000)
		eq(health.text:GetText(), '1.2M', "a skull-level unit's health with no percent after it")
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ": the castbar hangs 6 under the bar, 182 by 12, its 12x12 icon to its left so the row starts at the bar's left edge", function()
		local st, UF, P = world(client)
		local frame = enemy('nameplate1')
		local health, castbar = frame.Health, frame.Castbar
		eq(P.castbar.enable, true, 'the castbar on')
		eq(frame:IsElementEnabled('Castbar'), true, "enabled in oUF on an enemy's plate")
		check(near(castbar:GetTop(), health:GetBottom() - 6), 'its top 6 under the bar')
		check(near(castbar:GetRight(), health:GetRight()), "its right on the bar's right")
		eq(castbar:GetWidth(), 182, '182 wide')
		eq(castbar:GetHeight(), 12, '12 tall')

		local icon = castbar.Icon
		eq(P.castbar.icon.enable, true, 'the icon on')
		eq(icon:IsShown(), true, 'the icon shown with the castbar')
		eq(icon:GetWidth(), 12, 'the icon 12 wide')
		eq(icon:GetHeight(), 12, 'and 12 tall')
		check(near(icon:GetRight(), castbar:GetLeft() - 6), 'the icon 6 left of the castbar')
		check(near(icon:GetLeft(), health:GetLeft()), "so the row starts at the bar's left edge")
		check(near((icon:GetTop() + icon:GetBottom()) / 2, (castbar:GetTop() + castbar:GetBottom()) / 2), 'level with the castbar')

		eq(point(castbar.Text, { [castbar] = 'Castbar' }), 'LEFT,Castbar,LEFT,4,0', 'the spell name 4 in from the castbar\'s left')
		eq(castbar.Text:IsShown(), true, 'the spell name shown')
		eq(castbar.Time:IsShown(), false, 'no time')

		local r, g, b = castbar.colors.notInterruptible:GetRGB()
		check(near(r, 0.6) and near(g, 0.6) and near(b, 0.6), ("a cast that can't be interrupted in grey, got %s %s %s"):format(r, g, b))
		r, g, b = castbar.colors.normal:GetRGB()
		check(near(r, 0.5) and near(g, 0.7) and near(b, 0.9), "the castbar's own colour every unit's")
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ': up to 6 of your debuffs above the bar, from its left edge growing right; up to 4 purgeable buffs right of it', function()
		local st, UF, P = world(client)
		local frame = enemy('nameplate1')
		local health, debuffs, buffs = frame.Health, frame.Debuffs, frame.Buffs

		eq(debuffs.enabled, true, 'debuffs on')
		check(near(debuffs:GetLeft(), health:GetLeft()) and near(debuffs:GetBottom(), health:GetTop() + 6),
			"the debuff row 6 above the bar, from its left edge")
		eq(debuffs:GetWidth(), 150, '6 debuffs and 5 gaps: 150 wide')
		eq(debuffs:GetHeight(), 20, 'one row, 20 tall')
		eq(debuffs.elementSpacing, 6, '6 apart')
		eq(debuffs.flow.anchor, 'BOTTOMLEFT', 'the first at the bottom left')
		eq(debuffs.flow.growthX, 1, 'growing right')
		eq(debuffs.flow.growthY, 1, 'and up')
		eq(debuffs.flow.lineSize, 150, 'six to a row')
		local group = debuffs.groups[debuffs.groupKey]
		eq(group.options.maxFrameCount, 6, 'up to 6')
		eq(group.options.size, 20, '20px')
		eq(group.filter, 'HARMFUL|INCLUDE_NAME_PLATE_ONLY', "a plate's debuffs")
		eq(group.candidateFilters and group.candidateFilters.isFromPlayerOrPlayerPet, true, "only yours and your pet's")

		eq(buffs.enabled, true, 'buffs on')
		eq(P.buffs.purgeable, true, 'Only buffs I can purge on')
		check(near(buffs:GetLeft(), health:GetRight() + 6) and near(buffs:GetTop(), health:GetTop()),
			"the buff row 6 right of the bar, level with its top")
		eq(buffs:GetWidth(), 98, '4 buffs and 3 gaps: 98 wide')
		eq(buffs:GetHeight(), 20, 'one row, 20 tall')
		eq(buffs.elementSpacing, 6, '6 apart')
		eq(buffs.flow.anchor, 'TOPLEFT', 'the first at the top left')
		eq(buffs.flow.growthX, 1, 'growing right')
		eq(buffs.flow.lineSize, 98, 'four to a row')
		group = buffs.groups[buffs.groupKey]
		eq(group.options.maxFrameCount, 4, 'up to 4')
		eq(group.options.size, 20, '20px')
		eq(group.options.showStealableBorder, true, 'a border on the ones you can steal')
		eq(group.filter, (UF.PurgeFilter(UF:KnownRemovals())), 'the ones you can purge')

		-- Nothing of the layout above the bar's right end, where the threat text
		-- goes: the strip right of the debuff row, from the bar's top to the
		-- raid mark's height.
		local l, r = debuffs:GetRight(), health:GetRight()
		local b, t = health:GetTop(), frame.RaidTargetIndicator:GetBottom()
		check(r - l >= 50, 'a free strip at least 50 wide')
		for name, region in pairs({ Debuffs = debuffs, Buffs = buffs, Castbar = frame.Castbar, Icon = frame.Castbar.Icon,
				QuestIndicator = frame.QuestIndicator, RaidTargetIndicator = frame.RaidTargetIndicator, Health = health }) do
			check(not overlaps(region, l, r, b, t), name .. ' leaves the space above the bar\'s right end free')
		end
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ': the quest icon left of the bar; the raid mark centred above the debuff row', function()
		local st, UF, P = world(client)
		local frame = enemy('nameplate1')
		local health, quest, mark = frame.Health, frame.QuestIndicator, frame.RaidTargetIndicator
		eq(P.questindicator.enable, true, 'the quest icon on')
		eq(quest:GetWidth(), 16, 'the quest icon 16 wide')
		eq(quest:GetHeight(), 16, 'and 16 tall')
		check(near(quest:GetRight(), health:GetLeft() - 6), "its right 6 left of the bar's left")
		check(near((quest:GetTop() + quest:GetBottom()) / 2, (health:GetTop() + health:GetBottom()) / 2), 'level with the bar')

		eq(P.raidtargetindicator.enable, true, 'the raid mark on')
		eq(mark:GetWidth(), 16, 'the raid mark 16 wide')
		eq(mark:GetHeight(), 16, 'and 16 tall')
		check(near(mark:GetBottom(), health:GetTop() + 32), 'its bottom 32 over the bar')
		check(near(mark:GetBottom(), frame.Debuffs:GetTop() + 6), '6 above the debuff row')
		check(near((mark:GetLeft() + mark:GetRight()) / 2, (health:GetLeft() + health:GetRight()) / 2), 'centred over the bar')
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ': hostile names coloured, no level and no classification mark', function()
		local st, UF, P = world(client)
		local frame = enemy('nameplate1')
		eq(P.name.showLevel, false, 'Show level off')
		eq(P.name.show_classification, false, 'Classification off')
		eq(P.name.color_hostile, true, 'Color hostile on')
		local red = st.StringFormat:ToHex(st.config.profile.colors.text.red:GetRGB())
		eq(UF.oUF.Tags.Methods['st:name']('nameplate1', nil, 'nameplate'), '|cff' .. red .. 'Kobold|r',
			'the name in red, nothing before it')
		eq(#take_errors(), 0, 'no error')
	end)
end

test('a long name is cut at 150 pixels', function()
	local st, UF, P = world()
	local frame = enemy('nameplate1')
	local name = frame.Name
	eq(P.name.max_width, 150, 'Max width 150')
	eq(name:GetWidth(), 150, 'the name 150 wide')
	eq(name:CanWordWrap(), false, 'on one line')
	eq(name:GetJustifyH(), 'LEFT', 'from its left, where its point puts it')
	-- A secret name reaches the text whole (the tag can't shorten it).
	name:SetText(('Kobold '):rep(10))
	check(name:GetUnboundedStringWidth() > 150, 'the name is longer than that')
	check(name:GetStringWidth() <= 150, 'and the game cuts it at 150, got ' .. tostring(name:GetStringWidth()))
end)

test('the quest icon shows for a unit tied to an active quest, or a quest boss; a secret answer hides it', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		local restore = S.install()
		local frame = enemy('nameplate1')
		local quest = frame.QuestIndicator
		local function ask(label)
			quest:ForceUpdate()
			return quest:IsShown()
		end
		check(quest.Override ~= nil, client .. ": SaftUI's own update, in place of oUF's")
		stub.units.nameplate1.quest = true
		eq(ask(), true, client .. ': a unit one of your quests needs')
		stub.units.nameplate1.quest, stub.units.nameplate1.quest_boss = false, true
		eq(ask(), true, client .. ': a quest boss')
		stub.units.nameplate1.quest_boss = false
		eq(ask(), false, client .. ': neither')
		stub.units.nameplate1.quest = S.secret('Q')
		eq(ask(), false, client .. ': a secret answer counts as no')
		stub.units.nameplate1.quest, stub.units.nameplate1.quest_boss = false, S.secret('B')
		eq(ask(), false, client .. ': a secret quest boss answer too')
		stub.units.nameplate1.quest = true
		eq(ask(), true, client .. ': a quest unit with a secret quest boss answer')

		-- An event for another unit leaves it alone, as oUF's own update does.
		stub.units.nameplate1.quest = false
		quest.Override(frame, 'UNIT_CLASSIFICATION_CHANGED', 'nameplate2')
		eq(quest:IsShown(), true, client .. ": another unit's event changes nothing")

		-- Off in the config: hidden, whatever the unit.
		UF:GetProfileConfig().nameplate.questindicator.enable = false
		UF:UpdateConfig('nameplate', 'QuestIndicator')
		stub.units.nameplate1.quest = true
		eq(ask(), false, client .. ': off, never shown')
		eq(#take_errors(), 0, client .. ': no error')
		restore()
	end
end)

test('a finished quest hides the icon at the next quest log update', function()
	local st, UF, P = world()
	local frame = enemy('nameplate1', { quest = true })
	local quest = frame.QuestIndicator
	quest:ForceUpdate()
	eq(quest:IsShown(), true, 'shown while the quest is on')
	stub.units.nameplate1.quest = false
	stub.fire_event('QUEST_LOG_UPDATE')
	eq(quest:IsShown(), false, 'hidden once it is done')
	stub.units.nameplate1.quest = true
	stub.fire_event('QUEST_LOG_UPDATE')
	eq(quest:IsShown(), true, 'and shown for the next one')

	-- Only where oUF runs the icon and the config wants it: not on a friend's
	-- plate (off in the friendly config: disabled in oUF), nor on a plate that
	-- shows only widgets (paused in oUF), nor with the icon off.
	stub.units.nameplate2 = { name = 'Guard', friend = true, attackable = false }
	local ally = NP.add('nameplate2')
	stub.units.nameplate3 = { name = 'Flag', quest = true, friend = false, attackable = true }
	local widgets = NP.add('nameplate3', { widgets_only = true })
	check(widgets:IsElementPaused('QuestIndicator'), "the widget plate's quest icon is paused")
	local asked = {}
	for _, f in ipairs({ frame, ally, widgets }) do
		local real = f.QuestIndicator.ForceUpdate
		f.QuestIndicator.ForceUpdate = function(...)
			asked[f] = (asked[f] or 0) + 1
			return real(...)
		end
	end
	stub.fire_event('QUEST_LOG_UPDATE')
	eq(asked[frame], 1, "the enemy's plate asks")
	eq(asked[ally], nil, "a friend's plate doesn't")
	eq(asked[widgets], nil, 'nor a plate that shows only widgets')
	P.questindicator.enable = false
	UF:UpdateConfig('nameplate', 'QuestIndicator')
	stub.fire_event('QUEST_LOG_UPDATE')
	eq(asked[frame], 1, 'nor one with the icon off')

	-- A unit frame's: oUF keeps every element it has enabled whatever the
	-- config says, so the icon off (every unit's default) is skipped by the
	-- config alone.
	local target = NP.ouf:Spawn('target', 'SaftUI_Target')
	UF.units.target = target
	UF:UpdateUnitFrame(target)
	check(target:IsElementEnabled('QuestIndicator'), "the target's quest icon is enabled in oUF")
	local real = target.QuestIndicator.ForceUpdate
	target.QuestIndicator.ForceUpdate = function(...)
		asked[target] = (asked[target] or 0) + 1
		return real(...)
	end
	stub.fire_event('QUEST_LOG_UPDATE')
	eq(asked[target], nil, "the target's, off by default, doesn't ask")
	UF:GetProfileConfig().target.questindicator.enable = true
	UF:UpdateConfig('target', 'QuestIndicator')
	stub.fire_event('QUEST_LOG_UPDATE')
	eq(asked[target], 1, 'and asks once turned on')
	eq(#take_errors(), 0, 'no error')
end)

test("Max width is on every unit's Name tab", function()
	local st, UF = world()
	local P = UF:GetProfileConfig()
	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget',
			'boss', 'party', 'raid10', 'raid40', 'nameplate' }) do
		local tab = UF.elements.Name.GetConfigTable(unit)
		local option = tab.args.max_width
		if check(option ~= nil, unit .. ' has Max width') then
			eq(option.type, 'range', unit .. ': a range')
			eq(option.name, 'Max width', unit .. ': named')
			eq(option.min, 0, unit .. ': from 0')
			eq(option.max, 600, unit .. ': to 600')
			eq(option.step, 1, unit .. ': in steps of 1')
			check(type(option.desc) == 'string' and option.desc ~= '', unit .. ': with a desc')
			eq(tab.get({ 'max_width' }), unit == 'nameplate' and 150 or 0, unit .. "'s default")
		end
	end

	-- The target's name, unsized at 0, sized and unsized again through the option.
	local target = NP.ouf:Spawn('target', 'SaftUI_Target')
	UF.units.target = target
	UF:UpdateUnitFrame(target)
	local name = target.Name
	name:SetText(('Kobold '):rep(10))
	local function unsized(label)
		eq(name:GetWidth(), 0, label .. ': no width')
		eq(name:CanWordWrap(), true, label .. ': wraps as a font string does')
		eq(name:GetStringWidth(), name:GetUnboundedStringWidth(), label .. ': not cut')
	end
	unsized('0 on target')
	local tab = UF.elements.Name.GetConfigTable('target')
	tab.set({ 'max_width' }, 100)
	eq(P.target.name.max_width, 100, 'the option sets it')
	eq(name:GetWidth(), 100, 'the name 100 wide')
	eq(name:CanWordWrap(), false, 'on one line')
	tab.set({ 'max_width' }, 0)
	unsized('back to 0')
	eq(#take_errors(), 0, 'no error')
end)
