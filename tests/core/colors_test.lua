-- Core's color groundwork: the profile defaults a color option or unit frame
-- reads, st:QualityColor, and st:ColorsChanged (SaftUI-Core/Media/colors.lua).
load_test_file('core/config_helpers.lua')
local st = SaftUI

test('the status colors are colors with r, g and b, not lists, so unit frames read them', function()
	for _, key in ipairs({ 'disconnected', 'tapped' }) do
		local c = st.config.profile.colors.status[key]
		eq(c.r, 0.6, key); eq(c.g, 0.6, key); eq(c.b, 0.6, key)
		eq(c[1], nil, key .. ' is not a list')
		check(c.GetRGB, key .. ' has the color methods')
	end
end)

test('Heirloom and WoW Token have colors, and Arcane charges is in range', function()
	for _, q in ipairs({ 7, 8 }) do
		local r, g, b = st.config.profile.colors.item_quality[q]:GetRGB()
		eq(r .. ',' .. g .. ',' .. b, '0,0.8,1', 'quality ' .. q)
	end
	eq(st.config.profile.colors.power.ARCANE_CHARGES.b, 0.94)
end)

test("QualityColor: the profile's color, else Blizzard's, else nil", function()
	check(st:QualityColor(3) == st.config.profile.colors.item_quality[3], "the profile's own object")
	_G.ITEM_QUALITY_COLORS = { [9] = { r = 1, g = 0, b = 0 } }
	eq(st:QualityColor(9).r, 1, "Blizzard's for a quality the profile has no color for")
	eq(st:QualityColor(10), nil, 'no color anywhere')
	eq(st:QualityColor(nil), nil, 'no quality')
end)

test('ColorsChanged calls OnColorsChanged with the group on every module that has one, past one that errors', function()
	local got = {}
	st:NewModule('ColorsTestA').OnColorsChanged = function() error('boom') end
	st:NewModule('ColorsTestB').OnColorsChanged = function(_, group) got[#got + 1] = group end
	st:ColorsChanged('class')
	eq(table.concat(got, ','), 'class')
	eq(#take_errors(), 1, 'the error is reported, not raised')
end)

------------------------------------------------------------------ the Colors tab

local function ByOrder(t)
	local out = {}
	for key, v in pairs(t) do out[#out + 1] = { key = key, v = v } end
	table.sort(out, function(a, b) return a.v.order < b.v.order end)
	return out
end

local function Tab() return st.Config:GetOptionsTable().Fonts.args.colors end
local function Section(key) return Tab().args[key] end

local NOTE = 'Most of SaftUI reads these when it builds its frames: reload (Reload UI, bottom right) to see a change everywhere.'

test('the sections and their colors, in order, as small color swatches with tooltips, each with its own reset and no section Reset', function()
	local sections, names = ByOrder(Tab().args), {}
	for i, s in ipairs(sections) do names[i] = s.v.name end
	eq(table.concat(names, ','), 'Text,Buttons,Class,Reputation,Power,Item quality,Status,Threat')

	local expected = {
		text = 'Text,Grey,Red,Orange,Yellow,Green,Blue,Purple,Cyan,White',
		button = 'Normal,Hover,Pushed,Red,Green,Blue,Yellow,Grey',
		class = 'Death Knight,Demon Hunter,Druid,Evoker,Hunter,Mage,Monk,Paladin,Priest,Rogue,Shaman,Warlock,Warrior',
		reaction = 'Hated,Hostile,Unfriendly,Neutral,Friendly,Honored,Revered,Exalted,Renown',
		power = 'Mana,Rage,Focus,Energy,Runic power,Combo points,Holy power,Chi,Soul shards,Astral power,Insanity,Maelstrom,Fury,Pain,Arcane charges,Ammo,Fuel,Steam,Pyrite',
		item_quality = 'Poor,Common,Uncommon,Rare,Epic,Legendary,Artifact,Heirloom,WoW Token',
		status = 'Disconnected,Tapped',
		threat = 'Warning,Bad',
	}
	for _, s in ipairs(sections) do
		local rows, rowNames = ByOrder(s.v.args), {}
		eq(s.v.args.reset, nil, s.key .. ': no section Reset')
		for i, r in ipairs(rows) do
			rowNames[i] = r.v.name
			eq(r.v.type, 'color', s.key .. ' ' .. r.v.name); eq(r.v.size, 'small', r.v.name)
			check(type(r.v.desc) == 'string' and r.v.desc ~= '', s.key .. ' ' .. r.v.name .. ' has a desc')
			eq(r.v.hasAlpha, s.key == 'button' or nil, s.key .. ' ' .. r.v.name .. ' hasAlpha')
			local d = r.v.default
			check(type(d) == 'table' and type(d.differs) == 'function' and type(d.reset) == 'function' and type(d.value) == 'function',
				s.key .. ' ' .. r.v.name .. ': its own reset (default)')
			eq(d.differs(), false, s.key .. ' ' .. r.v.name .. ': at its default on a new profile')
		end
		eq(table.concat(rowNames, ','), expected[s.key], s.key)
	end
end)

test('Text and Buttons say a change shows after a reload; the others have no note', function()
	eq(Section('text').desc, NOTE)
	eq(Section('button').desc, NOTE)
	for _, key in ipairs({ 'class', 'reaction', 'power', 'item_quality', 'status', 'threat' }) do
		eq(Section(key).desc, nil, key)
	end
end)

local function Recorder()
	local got, orig = {}, st.ColorsChanged
	st.ColorsChanged = function(_, group) got[#got + 1] = group end
	return got, function() st.ColorsChanged = orig end
end

test('a set writes onto the profile color itself and says which group changed', function()
	local got, restore = Recorder()
	local mage = st.config.profile.colors.class.MAGE
	Section('class').args.MAGE.set({}, 0.1, 0.2, 0.3, 0.9)
	check(st.config.profile.colors.class.MAGE == mage, 'the same table')
	local r, g, b, a = mage:GetRGBA()
	eq(r .. ',' .. g .. ',' .. b, '0.1,0.2,0.3')
	eq(a, 1, 'class has no alpha: unchanged')
	eq(got[#got], 'class')

	Section('button').args.blue.set({}, 0.1, 0.1, 0.1, 0.5)
	eq(st.config.profile.colors.button.blue.a, 0.5, 'Buttons write alpha')

	local before = st.config.profile.colors.text.red.a
	Section('text').args.red.set({}, 0.5, 0.5, 0.5, 0.5)
	eq(st.config.profile.colors.text.red.a, before, 'Text leaves alpha alone')

	local renown = st.config.profile.colors.renown
	Section('reaction').args.renown.set({}, 0.2, 0.3, 0.4)
	check(st.config.profile.colors.renown == renown, 'renown is the top-level color itself')
	eq(renown.g, 0.3)
	eq(got[#got], 'renown')

	Section('item_quality').args['0'].set({}, 0.7, 0.7, 0.7)
	eq(st.config.profile.colors.item_quality[0].r, 0.7, 'a numeric key')
	restore()
end)

test('after a profile switch, get and set reach the new profile', function()
	local _, restore = Recorder()
	local mage, first = Section('class').args.MAGE, st.config:GetCurrentProfile()
	mage.set({}, 0.1, 0.2, 0.3)
	st.config:SetProfile('ColorsTestTwo')
	local r = mage.get({})
	eq(r, st.defaults.colors.class.MAGE.r, 'the new profile has the default Mage color')
	mage.set({}, 0.9, 0.9, 0.9)
	eq(st.config.profile.colors.class.MAGE.r, 0.9, 'set reaches the new profile')
	st.config:SetProfile(first)
	eq(mage.get({}), 0.1, "the first profile's value is as it was")
	restore()
end)

test("a color's own reset: it differs once changed, puts back its own color (alpha too) and says its group changed", function()
	local got, restore = Recorder()
	local class = Section('class')
	class.args.MAGE.set({}, 0.1, 0.1, 0.1)
	class.args.ROGUE.set({}, 0.2, 0.2, 0.2)
	check(class.args.MAGE.default.differs(), 'Mage differs')
	check(class.args.ROGUE.default.differs(), 'Rogue differs')
	check(not class.args.WARRIOR.default.differs(), 'Warrior, untouched, does not')
	local d = st.defaults.colors.class.MAGE
	eq(table.concat({ class.args.MAGE.default.value() }, ','), table.concat({ d.r, d.g, d.b, d.a }, ','), "its value: the default's r, g, b, a")
	for i = #got, 1, -1 do got[i] = nil end
	class.args.MAGE.default.reset()
	local c = st.config.profile.colors.class.MAGE
	eq(c.r .. ',' .. c.g .. ',' .. c.b, d.r .. ',' .. d.g .. ',' .. d.b, 'Mage back to its default')
	check(not class.args.MAGE.default.differs(), 'and no longer differs')
	eq(st.config.profile.colors.class.ROGUE.r, 0.2, 'Rogue left as it was')
	eq(table.concat(got, ','), 'class', 'its group changed, once, as the section Reset said')
	class.args.ROGUE.default.reset()

	-- A pick within a hair of the default (the picker's floats) is the default.
	local m = st.defaults.colors.class.MAGE
	class.args.MAGE.set({}, m.r + 0.0004, m.g, m.b)
	check(not class.args.MAGE.default.differs(), 'the same hex: not different')

	-- Renown, the top-level color; Buttons with an opacity; Text, whose alpha the tab never shows.
	for i = #got, 1, -1 do got[i] = nil end
	Section('reaction').args.renown.set({}, 0, 0, 0)
	check(Section('reaction').args.renown.default.differs(), 'renown differs')
	Section('reaction').args.renown.default.reset()
	eq(st.config.profile.colors.renown.r, st.defaults.colors.renown.r, 'renown is reset')
	eq(got[#got], 'renown', 'and says renown changed')

	local blue = Section('button').args.blue
	local b = st.config.profile.colors.button.blue
	blue.set({}, b.r, b.g, b.b, 0.25)
	check(blue.default.differs(), 'Buttons: a new opacity alone differs')
	blue.default.reset()
	eq(st.config.profile.colors.button.blue.a, st.defaults.colors.button.blue.a, 'and its reset puts the opacity back')

	Section('text').args.red.default.reset() -- an earlier case set it
	local red = st.config.profile.colors.text.red
	local alpha = red.a
	red.a = 0.3
	check(not Section('text').args.red.default.differs(), "Text: an alpha the tab can't show is no difference")
	red.r = 0.123
	Section('text').args.red.default.reset()
	eq(red.a, st.defaults.colors.text.red.a, 'its reset puts the alpha back with the rest, as the section Reset did')
	red.a = alpha
	restore()
end)

test('the class power colors say they are the player frame\'s class power points, and Runes and Alternate power have no row', function()
	local power = Section('power').args
	check(power.COMBO_POINTS.desc:find('class power points', 1, true), 'combo points')
	check(power.ARCANE_CHARGES.desc:find('Retail only', 1, true), 'arcane charges are retail only')
	-- The bundled oUF builds paladin and warlock class power only from Cataclysm on.
	check(power.HOLY_POWER.desc:find('Retail only', 1, true), 'holy power is retail only')
	check(power.SOUL_SHARDS.desc:find('Retail only', 1, true), 'soul shards are retail only')
	check(not power.COMBO_POINTS.desc:find('Retail only', 1, true), 'combo points show on Forever')
	check(not power.CHI.desc:find('Retail only', 1, true), 'chi shows on Forever')
	check(power.MANA.desc:find('power bar', 1, true), 'mana stays a power bar')
	eq(power.RUNES, nil, 'no Runes row')
	eq(power.ALTPOWER, nil, 'no Alternate power row')
	check(Section('class').args.MAGE.desc:find('tooltip', 1, true), "a class color's tooltip names the unit tooltip")
end)

test('the roll timer bars are under Buttons Blue, not Item quality, and the difficulty badge covers every instance', function()
	-- The roll timer's OnUpdate paints it Buttons Blue every frame.
	local quality = Section('item_quality').args
	check(not quality['3'].desc:find('timer', 1, true), 'Item quality names no timer bar')
	check(Section('button').args.blue.desc:find('loot roll timer bars', 1, true), 'Buttons Blue names the roll timer bars')
	check(Section('button').args.blue.desc:find("loot roll you've chosen on", 1, true), "and a held roll's lit border and label")
	check(quality['1'].desc:find('normal instances', 1, true), 'the badge is shown in raids too')
	check(Section('text').args.normal.desc:find('summon button', 1, true), "Text names the totem bar summon button's arrow")
	for key, word in pairs({ blue = 'Alliance', red = 'Horde', yellow = 'Neutral' }) do
		check(Section('text').args[key].desc:find(word .. ' on the zone text', 1, true), 'Text ' .. key .. ' names ' .. word .. ' on the zone text')
	end
end)
