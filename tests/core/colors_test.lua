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
	-- Gone again: a profile update now runs every group's whole pass, and a module
	-- that errors would report on each.
	st.modules.ColorsTestA, st.modules.ColorsTestB = nil, nil
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
	eq(table.concat(names, ','), 'Text,Buttons,Class,Roles,Reputation,Factions,Power,Item quality,Loot,Status,Threat,Objectives')

	local expected = {
		text = 'Text,Muted,Strong,Danger,Warning,Caution,Success,Shared',
		button = 'Normal,Hover,Pushed,Danger',
		class = 'Death Knight,Demon Hunter,Druid,Evoker,Hunter,Mage,Monk,Paladin,Priest,Rogue,Shaman,Warlock,Warrior',
		roles = 'Tank,Healer,Damage',
		factions = 'Alliance,Horde,Neutral',
		loot = 'Need,Greed,Transmog,Pass,Mount',
		reaction = 'Hated,Hostile,Unfriendly,Neutral,Friendly,Honored,Revered,Exalted,Renown',
		power = 'Mana,Rage,Focus,Energy,Runic power,Combo points,Holy power,Chi,Soul shards,Astral power,Insanity,Maelstrom,Fury,Pain,Arcane charges,Ammo,Fuel,Steam,Pyrite',
		item_quality = 'Poor,Common,Uncommon,Rare,Epic,Legendary,Artifact,Heirloom,WoW Token',
		status = 'Disconnected,Tapped',
		threat = 'Warning,Bad',
		objectives = 'Completed,Failed',
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

test('Text, Buttons, Roles, Factions and Loot say a change shows after a reload; the others have no note', function()
	for _, key in ipairs({ 'text', 'roles', 'factions', 'loot' }) do
		eq(Section(key).desc, NOTE, key)
	end
	eq(Section('button').desc, NOTE .. " Opacity sets how strongly each is drawn: 100% is SaftUI's own.", "Buttons add what their opacity does")
	for _, key in ipairs({ 'class', 'reaction', 'power', 'item_quality', 'status', 'threat', 'objectives' }) do
		eq(Section(key).desc, nil, key)
	end
end)

-- The groups a set or a reset says changed: they say st:ColorChanged(group, key)
-- (the key is color_live_test.lua's).
local function Recorder()
	local got, orig = {}, st.ColorChanged
	st.ColorChanged = function(_, group) got[#got + 1] = group end
	return got, function() st.ColorChanged = orig end
end

test("a Roles, Factions or Loot set and reset write the profile's own object and say their group", function()
	local got, restore = Recorder()
	for _, c in ipairs({ { 'roles', 'TANK' }, { 'factions', 'Horde' }, { 'loot', 'pass' }, { 'loot', 'mount' } }) do
		local group, key = c[1], c[2]
		local color = st.config.profile.colors[group][key]
		local row = Section(group).args[key]
		row.set({}, 0.11, 0.22, 0.33)
		check(st.config.profile.colors[group][key] == color, group .. '.' .. key .. ': the same table')
		eq(color.r .. ',' .. color.g .. ',' .. color.b, '0.11,0.22,0.33', group .. '.' .. key)
		eq(got[#got], group, group .. '.' .. key .. ': a set says its group')
		check(row.default.differs(), group .. '.' .. key .. ' differs')
		got[#got + 1] = 'x'
		row.default.reset()
		local d = st.defaults.colors[group][key]
		eq(color.r .. ',' .. color.g .. ',' .. color.b, d.r .. ',' .. d.g .. ',' .. d.b, group .. '.' .. key .. ': reset')
		eq(got[#got], group, group .. '.' .. key .. ': a reset says its group')
	end
	restore()
end)

test('a set writes onto the profile color itself and says which group changed', function()
	local got, restore = Recorder()
	local mage = st.config.profile.colors.class.MAGE
	Section('class').args.MAGE.set({}, 0.1, 0.2, 0.3, 0.9)
	check(st.config.profile.colors.class.MAGE == mage, 'the same table')
	local r, g, b, a = mage:GetRGBA()
	eq(r .. ',' .. g .. ',' .. b, '0.1,0.2,0.3')
	eq(a, 1, 'class has no alpha: unchanged')
	eq(got[#got], 'class')

	Section('button').args.hover.set({}, 0.1, 0.1, 0.1, 0.5)
	eq(st.config.profile.colors.button.hover.a, 0.5, 'Buttons write alpha, and every Buttons reader draws it (button_opacity_test.lua)')
	eq(select(4, st:ColorRGBA('button', 'hover', 0.4)), 0.2, 'a reader at 0.4 draws half of it')
	Section('button').args.hover.default.reset()
	eq(st.config.profile.colors.button.hover.a, 1, "and its reset is SaftUI's own: 100%")

	local before = st.config.profile.colors.text.danger.a
	Section('text').args.danger.set({}, 0.5, 0.5, 0.5, 0.5)
	eq(st.config.profile.colors.text.danger.a, before, 'Text leaves alpha alone')

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

test("Objectives: Completed and Failed default to the colors the skin shipped, and a reset puts one back and says 'objectives'", function()
	local got, restore = Recorder()
	local completed = Section('objectives').args.completed
	local default = st.defaults.colors.objectives
	eq(default.completed.r .. ',' .. default.completed.g .. ',' .. default.completed.b, '0.251,0.753,0.251')
	eq(default.failed.r .. ',' .. default.failed.g .. ',' .. default.failed.b, (220 / 255) .. ',' .. (100 / 255) .. ',' .. (100 / 255))
	completed.set({}, 0.1, 0.2, 0.3)
	eq(got[#got], 'objectives', 'a set says objectives')
	eq(completed.default.differs(), true, 'it differs')
	got[#got] = nil
	completed.default.reset()
	eq(st.config.profile.colors.objectives.completed.g, 0.753, 'the default is back')
	eq(got[#got], 'objectives', 'a reset says objectives')
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

	local hover = Section('button').args.hover
	local b = st.config.profile.colors.button.hover
	hover.set({}, b.r, b.g, b.b, 0.25)
	check(hover.default.differs(), 'Buttons: a new opacity alone differs')
	hover.default.reset()
	eq(st.config.profile.colors.button.hover.a, st.defaults.colors.button.hover.a, 'and its reset puts the opacity back')

	Section('text').args.danger.default.reset() -- an earlier case set it
	local red = st.config.profile.colors.text.danger
	local alpha = red.a
	red.a = 0.3
	check(not Section('text').args.danger.default.differs(), "Text: an alpha the tab can't show is no difference")
	red.r = 0.123
	Section('text').args.danger.default.reset()
	eq(red.a, st.defaults.colors.text.danger.a, 'its reset puts the alpha back with the rest, as the section Reset did')
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

test('the roll timer bars are not Item quality, Blue is on Theme > Accent, and the difficulty badge covers every instance', function()
	-- The roll timer's OnUpdate paints it in the accent every frame.
	local quality = Section('item_quality').args
	check(not quality['3'].desc:find('timer', 1, true), 'Item quality names no timer bar')
	eq(Section('button').args.blue, nil, 'Buttons has no Blue: it is the accent now')
	eq(Section('text').args.blue, nil, 'nor Text')
	eq(Section('button').args.green, nil, 'Buttons > Green went with it')
	-- Each Buttons row says which highlight it is (opacity works now: the owner lowers one and watches what fades).
	local normal, hover = Section('button').args.normal.desc, Section('button').args.hover.desc
	check(normal:find('zone text', 1, true) and normal:find('addon compartment', 1, true) and normal:find("micro menu bar's own items", 1, true), 'Normal names the bar items: ' .. normal)
	check(not normal:find('micro menu button', 1, true), 'and not the micro buttons')
	check(hover:find("micro buttons' highlight", 1, true) and hover:find('tracking, queue and expansion', 1, true), 'Hover names the micro buttons and the three minimap buttons: ' .. hover)
	check(quality['1'].desc:find('normal instances', 1, true), 'the badge is shown in raids too')
	check(Section('text').args.normal.desc:find('summon button', 1, true), "Text names the totem bar summon button's arrow")
	for _, word in ipairs({ 'Alliance', 'Horde', 'Neutral' }) do
		check(Section('factions').args[word].desc:find(word .. ' on the zone text', 1, true), 'Factions ' .. word .. ' names ' .. word .. ' on the zone text')
		for key, row in pairs(Section('text').args) do
			check(not row.desc:find(word .. ' on the zone text', 1, true), 'Text ' .. key .. ' no longer names ' .. word)
		end
	end
end)

test('no Text, Buttons, Roles, Factions or Loot row or description names a hue as the name of a color', function()
	local HUES = { 'red', 'orange', 'yellow', 'green', 'cyan', 'white', 'blue', 'purple', 'grey', 'gray' }
	for _, key in ipairs({ 'text', 'button', 'roles', 'factions', 'loot' }) do
		for rowKey, row in pairs(Section(key).args) do
			local words = (row.name .. ' ' .. row.desc):lower()
			for _, hue in ipairs(HUES) do
				check(not words:find('%f[%a]' .. hue .. '%f[%A]'), key .. ' ' .. rowKey .. ' names ' .. hue .. ': ' .. row.desc)
			end
		end
	end
end)

test('the state colors are the profile objects, each at its old default, and Buttons > Danger is at 100% (its opacity is drawn now)', function()
	local text = st.config.profile.colors.text
	local want = { strong = { 1, 1, 1 }, danger = { 220/255, 100/255, 100/255 }, warning = { 220/255, 150/255, 100/255 },
		caution = { 200/255, 200/255, 100/255 }, success = { 60/255, 240/255, 60/255 }, shared = { 120/255, 202/255, 250/255 } }
	for key, c in pairs(want) do
		eq(text[key].r .. ',' .. text[key].g .. ',' .. text[key].b, c[1] .. ',' .. c[2] .. ',' .. c[3], key)
	end
	local danger = st.config.profile.colors.button.danger
	eq(danger.r .. ',' .. danger.g .. ',' .. danger.b .. ',' .. danger.a, '0.6,0.1,0.1,1', 'Buttons > Danger')
	for _, old in ipairs({ 'white', 'red', 'orange', 'yellow', 'green', 'cyan' }) do eq(rawget(st.defaults.colors.text, old), nil, old .. ' has no default') end
	eq(rawget(st.defaults.colors.button, 'red'), nil, 'nor Buttons > Red')
end)
