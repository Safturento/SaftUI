local st = SaftUI

local CO = st:NewModule('Colors')

-- Tells every module that shows profile colors that a group of them changed
-- (the Colors tab calls this after an edit). group is 'text', 'button',
-- 'class', 'reaction', 'renown', 'power', 'item_quality' or 'status'. Each
-- module's OnColorsChanged(group) runs in xpcall, so one that errors doesn't
-- stop the rest.
function st:ColorsChanged(group)
	for _, module in pairs(st.modules) do
		if module.OnColorsChanged then
			xpcall(module.OnColorsChanged, geterrorhandler(), module, group)
		end
	end
end

-- The color for an item quality: the profile's, else Blizzard's, else nil.
-- Either object has r, g and b.
function st:QualityColor(quality)
	if quality == nil then return nil end
	return st.config.profile.colors.item_quality[quality] or (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality])
end

local RELOAD_NOTE = 'Most of SaftUI reads these when it builds its frames: reload (Reload UI, bottom left) to see a change everywhere.'

-- The Colors tab's sections, in order. A section is { key, name, note,
-- hasAlpha, colors }: key is its group's key, note shows under its title,
-- hasAlpha gives its swatches an opacity slider. A color is { group, key,
-- name, desc }: group is the profile key st:ColorsChanged takes, key the
-- subkey of st.config.profile.colors[group] (nil for renown, which is that
-- key's color itself).
local function Colors(group, list)
	local out = {}
	for i, entry in ipairs(list) do
		out[i] = { group = group, key = entry[1], name = entry[2], desc = entry[3] }
	end
	return out
end

local function Reaction(name)
	return ('The experience bar and loot feed bar while your standing is %s, and unit frames of NPCs that are %s to you.'):format(name, name)
end

CO.SECTIONS = {
	{
		key = 'text', name = 'Text', note = RELOAD_NOTE,
		colors = Colors('text', {
			{ 'normal', 'Text', "Ordinary text: the options window, totem timers and the micro menu's stats." },
			{ 'grey', 'Grey', "Dimmed text: the options window's hints and disabled controls, and a unit frame's level tag for a far lower level." },
			{ 'red', 'Red', "Warnings and Pass: loot roll Pass buttons and timers, a unit frame's level tag for a much higher level, DPS role marks, and expiring totem timers." },
			{ 'orange', 'Orange', "A unit frame's level tag for a somewhat higher level, and the poor end of the micro menu's stats." },
			{ 'yellow', 'Yellow', "Greed on loot rolls, a unit frame's level tag near your level, unfriendly names and the micro menu's alert flash." },
			{ 'green', 'Green', "Good or active things: edit mode being on, healer role marks, a lower level's tag, and bag item levels for a Bind on Equip item." },
			{ 'blue', 'Blue', "Selected options window tabs and rows, and tank role marks on unit frames." },
			{ 'purple', 'Purple', 'Transmog on loot rolls: the roll buttons and the roll counts.' },
			{ 'cyan', 'Cyan', 'Warbound item levels and the warband bank count in bags.' },
			{ 'white', 'White', 'Need on loot rolls, and plain item levels and counts in bags.' },
		}),
	},
	{
		key = 'button', name = 'Buttons', note = RELOAD_NOTE, hasAlpha = true,
		colors = Colors('button', {
			{ 'normal', 'Normal', "The resting fill of SaftUI's check boxes and scroll bars." },
			{ 'hover', 'Hover', "A checked check box, a hovered scroll bar and micro menu button, and resize handles." },
			{ 'pushed', 'Pushed', 'A pressed scroll bar or micro menu button.' },
			{ 'red', 'Red', "Locked bank slots, and the flash on an action bar or totem button." },
			{ 'green', 'Green', "The border of an equipped item's action button." },
			{ 'blue', 'Blue', 'The accent color: hovered and active controls, and the options window\'s tabs and slider fill.' },
			{ 'yellow', 'Yellow', 'The yellow button fill; SaftUI has no control that shows it yet.' },
			{ 'grey', 'Grey', "The combined bank's visibility toggle and the edit mode picker's hint line." },
		}),
	},
	{
		key = 'class', name = 'Class',
		colors = Colors('class', {
			{ 'DEATHKNIGHT', 'Death Knight' }, { 'DEMONHUNTER', 'Demon Hunter' }, { 'DRUID', 'Druid' },
			{ 'EVOKER', 'Evoker' }, { 'HUNTER', 'Hunter' }, { 'MAGE', 'Mage' }, { 'MONK', 'Monk' },
			{ 'PALADIN', 'Paladin' }, { 'PRIEST', 'Priest' }, { 'ROGUE', 'Rogue' }, { 'SHAMAN', 'Shaman' },
			{ 'WARLOCK', 'Warlock' }, { 'WARRIOR', 'Warrior' },
		}),
	},
	{
		key = 'reaction', name = 'Reputation',
		colors = (function()
			local list = Colors('reaction', {
				{ 1, 'Hated' }, { 2, 'Hostile' }, { 3, 'Unfriendly' }, { 4, 'Neutral' },
				{ 5, 'Friendly' }, { 6, 'Honored' }, { 7, 'Revered' }, { 8, 'Exalted' },
			})
			for _, color in ipairs(list) do
				color.desc = Reaction(color.name:lower())
			end
			list[#list + 1] = { group = 'renown', key = nil, name = 'Renown',
				desc = "The experience bar and loot feed's bar for a renown (major faction) track." }
			return list
		end)(),
	},
	{
		key = 'power', name = 'Power',
		colors = Colors('power', {
			{ 'MANA', 'Mana' }, { 'RAGE', 'Rage' }, { 'FOCUS', 'Focus' }, { 'ENERGY', 'Energy' },
			{ 'RUNIC_POWER', 'Runic power' }, { 'COMBO_POINTS', 'Combo points' }, { 'HOLY_POWER', 'Holy power' },
			{ 'CHI', 'Chi' }, { 'SOUL_SHARDS', 'Soul shards' }, { 'LUNAR_POWER', 'Astral power' },
			{ 'INSANITY', 'Insanity' }, { 'MAELSTROM', 'Maelstrom' }, { 'FURY', 'Fury' }, { 'PAIN', 'Pain' },
			{ 'ARCANE_CHARGES', 'Arcane charges' }, { 'RUNES', 'Runes' }, { 'ALTPOWER', 'Alternate power' },
			{ 'AMMOSLOT', 'Ammo' }, { 'FUEL', 'Fuel' }, { 'POWER_TYPE_STEAM', 'Steam' },
			{ 'POWER_TYPE_PYRITE', 'Pyrite' },
		}),
	},
	{
		key = 'item_quality', name = 'Item quality',
		colors = Colors('item_quality', {
			{ 0, 'Poor' }, { 1, 'Common' }, { 2, 'Uncommon' }, { 3, 'Rare' }, { 4, 'Epic' }, { 5, 'Legendary' },
			{ 6, 'Artifact' }, { 7, 'Heirloom' }, { 8, 'WoW Token' },
		}),
	},
	{
		key = 'status', name = 'Status',
		colors = Colors('status', {
			{ 'disconnected', 'Disconnected', 'Unit frame health bars of party and raid members who are offline.' },
			{ 'tapped', 'Tapped', 'Unit frame health bars of enemies that another player has tagged.' },
		}),
	},
}

-- Colors whose readers are generic share a sentence per section.
local GENERIC_DESC = {
	class = 'The %s class color on unit frames, name tags and raid frames.',
	power = 'The %s power bar on unit frames.',
	item_quality = 'The %s item color: item names in the loot feed and loot rolls, and item borders in bags.',
}
for _, section in ipairs(CO.SECTIONS) do
	local pattern = GENERIC_DESC[section.key]
	for _, color in ipairs(section.colors) do
		if not color.desc and pattern then
			color.desc = pattern:format(color.name)
		end
	end
end

-- The profile's color for a row: st.config.profile.colors[group][key], read
-- at call time so a profile switch reaches the new profile's table.
local function ProfileColor(color)
	local group = st.config.profile.colors[color.group]
	if color.key == nil then return group end
	return group[color.key]
end

local function SectionGroup(section, index)
	local args = {}
	for i, color in ipairs(section.colors) do
		args[tostring(color.key or color.group)] = {
			type = 'color',
			size = 'small',
			order = i,
			name = color.name,
			desc = color.desc,
			hasAlpha = section.hasAlpha or nil,
			get = function()
				return ProfileColor(color):GetRGBA()
			end,
			set = function(_, r, g, b, a)
				local c = ProfileColor(color)
				c.r, c.g, c.b = r, g, b
				if section.hasAlpha then c.a = a end
				st:ColorsChanged(color.group)
			end,
		}
	end
	args.reset = {
		type = 'execute',
		size = 'small',
		order = #section.colors + 1,
		name = 'Reset',
		desc = "Puts every color in this section back to SaftUI's default.",
		confirm = true,
		confirmText = ("Reset the %s colors to SaftUI's defaults?"):format(section.name),
		func = function()
			local seen, groups = {}, {}
			for _, color in ipairs(section.colors) do
				local from = st.defaults.colors[color.group]
				if color.key ~= nil then from = from[color.key] end
				local c = ProfileColor(color)
				c.r, c.g, c.b, c.a = from.r, from.g, from.b, from.a
				if not seen[color.group] then
					seen[color.group] = true
					groups[#groups + 1] = color.group
				end
			end
			for _, group in ipairs(groups) do st:ColorsChanged(group) end
		end,
	}
	return {
		type = 'group',
		inline = true,
		order = index,
		name = section.name,
		desc = section.note,
		args = args,
	}
end

-- The Colors tab of Global Settings: one inline section per color group, a
-- swatch per color and a Reset button. Each row's get and set are bound to its
-- own color, so they read no info.
function CO:GetConfigTable()
	local args = {}
	for i, section in ipairs(CO.SECTIONS) do
		args[section.key] = SectionGroup(section, i)
	end
	return { type = 'group', name = 'Colors', order = 2, args = args }
end
