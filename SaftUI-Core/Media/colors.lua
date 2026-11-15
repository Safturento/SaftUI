local st = SaftUI

local CO = st:NewModule('Colors')

-- Tells every module that shows profile colors that a group of them changed
-- (the Colors tab calls this after an edit). group is 'text', 'button',
-- 'class', 'roles', 'reaction', 'renown', 'factions', 'power', 'item_quality',
-- 'loot', 'status', 'threat' or 'objectives'. Each module's
-- OnColorsChanged(group) runs in xpcall, so one that errors doesn't stop the
-- rest.
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

------------------------------------------------------------------ the accessor

-- The color for a group and key, as an object with r, g, b and a. The default
-- decides what exists: st.defaults.colors[group][key] (for 'accent', which
-- takes no key, st.defaults.theme.accent), or the read raises
-- 'SaftUI: no color <group>.<key>' at the caller of st:Color, whatever the
-- profile holds. The value is the active profile's own object, read now (so a
-- profile switch reaches the new one), else the default's: a profile that has
-- no config yet, or a group or color that isn't a table, reads as the default.
local function Resolve(group, key, level)
	local defaults = st.defaults
	local default
	if group == 'accent' then
		default = defaults and defaults.theme and defaults.theme.accent
	else
		local from = defaults and defaults.colors and defaults.colors[group]
		if type(from) == 'table' then
			if key == nil then
				-- Only a default that is itself a color has no key (renown).
				if type(from.r) == 'number' then default = from end
			else
				default = from[key]
			end
		end
	end
	if type(default) ~= 'table' then
		local name = group == 'accent' and 'accent' or (tostring(group) .. '.' .. tostring(key))
		error('SaftUI: no color ' .. name, level)
	end

	local profile = st.config and st.config.profile
	if type(profile) ~= 'table' then return default end
	local saved
	if group == 'accent' then
		saved = type(profile.theme) == 'table' and profile.theme.accent
	else
		local colors = profile.colors
		local holder = type(colors) == 'table' and colors[group]
		if key == nil then saved = holder elseif type(holder) == 'table' then saved = holder[key] end
	end
	-- Every color AceDB fills has the methods; a bare table (a hand edit, or a
	-- migration's write into a group that wasn't a table) reads as the default.
	if type(saved) == 'table' and saved.GetRGB then return saved end
	return default
end

function st:Color(group, key)
	return Resolve(group, key, 3)
end

-- r, g, b and the alpha a reader draws: its strength times the color's own
-- opacity (a color with no a is fully opaque).
function st:ColorRGBA(group, key, strength)
	local c = Resolve(group, key, 3)
	return c.r, c.g, c.b, (strength or 1) * (c.a or 1)
end

------------------------------------------------------------------ the migration

-- Today's shipped value of every retired key, frozen (AceDB saves only the
-- channels that differ from a default; once a default is gone, the rest come
-- from here). Never edited after it lands.
CO.OLD_COLORS = {
	['text.grey'] = { r = 150/255, g = 150/255, b = 150/255 },
	['text.white'] = { r = 1, g = 1, b = 1 },
	['text.red'] = { r = 220/255, g = 100/255, b = 100/255 },
	['text.orange'] = { r = 220/255, g = 150/255, b = 100/255 },
	['text.yellow'] = { r = 200/255, g = 200/255, b = 100/255 },
	['text.green'] = { r = 60/255, g = 240/255, b = 60/255 },
	['text.blue'] = { r = 0, g = 0.68, b = 0.94, a = 1 },
	['text.purple'] = { r = 197/255, g = 128/255, b = 255/255 },
	['text.cyan'] = { r = 120/255, g = 202/255, b = 250/255 },
	['button.red'] = { r = 0.6, g = 0.1, b = 0.1, a = 0.8 },
	['button.green'] = { r = 0.1, g = 0.6, b = 0.1, a = 0.8 },
	['button.blue'] = { r = 0, g = 0.68, b = 0.94, a = 0.8 },
	['button.yellow'] = { r = 0.6, g = 0.6, b = 0.1, a = 0.8 },
	['button.grey'] = { r = 150/255, g = 150/255, b = 150/255 },
}

-- One step per change of the colors' keys, run in order on a profile saved
-- before it. A step is { copy, retire }: copy lists { source, destination, ...}
-- (a customized source's color goes into each destination), retire the paths
-- that leave. A path is 'group.key' under profile.colors. The steps are never
-- edited once shipped; each change appends one.
CO.MIGRATION_STEPS = {
	{
		copy = {
			{ 'text.white', 'loot.need' },
			{ 'text.yellow', 'loot.greed', 'factions.Neutral' },
			{ 'text.purple', 'loot.transmog' },
			{ 'text.red', 'loot.pass', 'roles.DAMAGER', 'factions.Horde' },
			{ 'text.green', 'roles.HEALER' },
			{ 'text.blue', 'roles.TANK', 'factions.Alliance' },
			{ 'button.yellow', 'loot.mount' },
		},
		retire = { 'text.purple', 'button.yellow' },
	},
}

local function SplitPath(path)
	return path:match('^([^.]+)%.(.+)$')
end

local function Byte(v) return math.floor(v * 255 + 0.5) end

-- The color a source was customized to, as { r, g, b }, or nil when it was
-- not: no saved table, or a color that is its old value to the byte (the
-- Colors tab's SameColor). A channel saved as anything but a number takes the
-- old value's.
local function CustomizedColor(profile, path)
	local group, key = SplitPath(path)
	local holder = profile.colors[group]
	local saved = type(holder) == 'table' and holder[key]
	local old = CO.OLD_COLORS[path]
	if type(saved) ~= 'table' or not old then return nil end
	local c = {}
	for _, channel in ipairs({ 'r', 'g', 'b' }) do
		c[channel] = type(saved[channel]) == 'number' and saved[channel] or old[channel]
	end
	if Byte(c.r) == Byte(old.r) and Byte(c.g) == Byte(old.g) and Byte(c.b) == Byte(old.b) then return nil end
	return c
end

-- Puts c's r, g and b (never an alpha) into a destination. A color table that
-- is there is written into in place, so the active profile's keeps its
-- methods; else a plain one is made, and its group first when that isn't a
-- table.
local function WriteColor(profile, path, c)
	local group, key = SplitPath(path)
	local holder = profile.colors[group]
	if type(holder) ~= 'table' then
		holder = {}
		profile.colors[group] = holder
	end
	local dest = holder[key]
	if type(dest) == 'table' then
		dest.r, dest.g, dest.b = c.r, c.g, c.b
	else
		holder[key] = { r = c.r, g = c.g, b = c.b }
	end
end

local function RunStep(profile, step)
	for _, copy in ipairs(step.copy or {}) do
		local c = CustomizedColor(profile, copy[1])
		if c then
			for i = 2, #copy do WriteColor(profile, copy[i], c) end
		end
	end
	for _, path in ipairs(step.retire or {}) do
		local group, key = SplitPath(path)
		local holder = profile.colors[group]
		if type(holder) == 'table' then holder[key] = nil end
	end
end

-- Brings a profile's colors up to the last step: every step after the
-- profile's colors.version runs, then the version is the last step's. A
-- version only rises (a number at or above the last step runs nothing and
-- stays; anything else counts as 0). Table writes only, so it runs in combat,
-- and running it again changes nothing. A profile with no colors table is left
-- alone. Called at login and on every profile change, copy and reset
-- (Config:UpdateConfig).
function st:MigrateColors(profile)
	if type(profile) ~= 'table' or type(profile.colors) ~= 'table' then return end
	local colors = profile.colors
	local from = type(colors.version) == 'number' and colors.version or 0
	local last = #CO.MIGRATION_STEPS
	for n = 1, last do
		if n > from then RunStep(profile, CO.MIGRATION_STEPS[n]) end
	end
	if last > from then colors.version = last end
end

local RELOAD_NOTE = 'Most of SaftUI reads these when it builds its frames: reload (Reload UI, bottom right) to see a change everywhere.'

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
	return ("The experience bar's reputation bar and the loot feed bar while your standing is %s, and unit frames and the unit tooltip's name and border of NPCs that are %s to you."):format(name, name)
end

CO.SECTIONS = {
	{
		key = 'text', name = 'Text', note = RELOAD_NOTE,
		colors = Colors('text', {
			{ 'normal', 'Text', "Ordinary text: the options window, totem timers, the flyout arrow on the totem bar's summon button, and an enemy nameplate's threat text while your threat on it is fine." },
			{ 'grey', 'Grey', "Dimmed text: the options window's hints and disabled controls, and a unit frame's level tag for a far lower level." },
			{ 'red', 'Red', "Warnings: loot roll timers under a minute, a unit frame's level tag for a much higher level and expiring totem timers. Also a durability under 20% in the durability figure's tooltip." },
			{ 'orange', 'Orange', "A unit frame's level tag for a somewhat higher level, and the poor end of the micro menu's stats. Also a durability from 20% to 49% in the durability figure's tooltip." },
			{ 'yellow', 'Yellow', "A unit frame's level tag near your level, unfriendly names, and the micro menu's alert flash and the middle of its stats." },
			{ 'green', 'Green', "Good things: a lower level's tag, bag item levels for a Bind on Equip item, the winner's roll in the loot feed's roll tooltip, and the good end of the micro menu's stats. Also a durability from 50% up in the durability figure's tooltip." },
			{ 'blue', 'Blue', "Selected options window tabs and rows." },
			{ 'cyan', 'Cyan', 'Warbound item levels and the warband bank count in bags.' },
			{ 'white', 'White', 'Plain item levels and counts in bags, and item levels on the character frame.' },
		}),
	},
	{
		key = 'button', name = 'Buttons', note = RELOAD_NOTE, hasAlpha = true,
		colors = Colors('button', {
			{ 'normal', 'Normal', "A SaftUI button's or check box's highlight, a scroll bar thumb at rest, and the micro menu's button highlight." },
			{ 'hover', 'Hover', "A checked check box, a hovered scroll bar thumb, the minimap tracking button's hover, micro menu button highlights and resize handles." },
			{ 'pushed', 'Pushed', 'A pressed SaftUI button, scroll bar thumb or micro menu button.' },
			{ 'red', 'Red', "Locked bank slots, and the flash on an action bar or totem button." },
			{ 'green', 'Green', "The border of an equipped item's action button." },
			{ 'blue', 'Blue', 'The accent color: hovered and active controls, the options window\'s tabs and slider fill, loot roll timer bars, and the border and label of a loot roll you\'ve chosen on.' },
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
		key = 'roles', name = 'Roles', note = RELOAD_NOTE,
		colors = Colors('roles', {
			{ 'TANK', 'Tank', "The role corner of a tank on unit frames, and in the group test previews." },
			{ 'HEALER', 'Healer', "The role corner of a healer on unit frames, and in the group test previews." },
			{ 'DAMAGER', 'Damage', "The role corner of a damage dealer, or of a unit with no role, on unit frames and in the group test previews: shown with Show damage dealers." },
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
				desc = "The experience bar's reputation bar and the loot feed's bar for a renown (major faction) track." }
			return list
		end)(),
	},
	{
		key = 'factions', name = 'Factions', note = RELOAD_NOTE,
		colors = Colors('factions', {
			{ 'Alliance', 'Alliance', "Alliance on the zone text and the world map's zone names: a zone the Alliance holds." },
			{ 'Horde', 'Horde', "Horde on the zone text and the world map's zone names: a zone the Horde holds." },
			{ 'Neutral', 'Neutral', "Neutral on the zone text and the world map's zone names: a contested zone or a sanctuary." },
		}),
	},
	{
		key = 'power', name = 'Power',
		colors = Colors('power', {
			{ 'MANA', 'Mana' }, { 'RAGE', 'Rage' }, { 'FOCUS', 'Focus' }, { 'ENERGY', 'Energy' },
			{ 'RUNIC_POWER', 'Runic power' }, { 'COMBO_POINTS', 'Combo points' }, { 'HOLY_POWER', 'Holy power' },
			{ 'CHI', 'Chi' }, { 'SOUL_SHARDS', 'Soul shards' }, { 'LUNAR_POWER', 'Astral power' },
			{ 'INSANITY', 'Insanity' }, { 'MAELSTROM', 'Maelstrom' }, { 'FURY', 'Fury' }, { 'PAIN', 'Pain' },
			{ 'ARCANE_CHARGES', 'Arcane charges' },
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
		key = 'loot', name = 'Loot', note = RELOAD_NOTE,
		colors = Colors('loot', {
			{ 'need', 'Need', "Need on loot rolls: the Need button's letter, and Need in the loot feed's roll tooltip." },
			{ 'greed', 'Greed', "Greed on loot rolls: the Greed button's letter, the roll counts of Greed and its line in the loot feed's roll tooltip." },
			{ 'transmog', 'Transmog', "Transmog on loot rolls: the Transmog button's letter, the roll counts of Transmog and its line in the loot feed's roll tooltip." },
			{ 'pass', 'Pass', "Pass on loot rolls: the Pass button's letter, and All passed (on the feed line and in its roll tooltip) and Pass: in the loot feed's roll tooltip." },
			{ 'mount', 'Mount', "A fresh mount's entry in the loot feed: its border and fill, and its icon's border." },
		}),
	},
	{
		key = 'status', name = 'Status',
		colors = Colors('status', {
			{ 'disconnected', 'Disconnected', 'Unit frame health bars of party and raid members who are offline.' },
			{ 'tapped', 'Tapped', 'Unit frame health bars of enemies that another player has tagged.' },
		}),
	},
	{
		key = 'threat', name = 'Threat',
		colors = Colors('threat', {
			{ 'warning', 'Warning', "An enemy nameplate's health bar and threat text when you're about to pull it as damage or healing, or about to lose it as a tank." },
			{ 'bad', 'Bad', "An enemy nameplate's health bar and threat text when it's attacking you as damage or healing, or someone else while you tank." },
		}),
	},
	{
		key = 'objectives', name = 'Objectives',
		colors = Colors('objectives', {
			{ 'completed', 'Completed', "The line of a finished objective in SaftUI's objective tracker, and in Blizzard's tracker while Skinning -> Objective tracker is on. Blizzard's own is a plain grey; a line you haven't finished keeps its normal color." },
			{ 'failed', 'Failed', "The line of a failed objective in SaftUI's objective tracker, and in Blizzard's tracker while Skinning -> Objective tracker is on. Under the mouse Blizzard brightens a failed quest line, as it does its unfinished lines." },
		}),
	},
}

-- Colors whose readers are generic share a sentence per section.
local GENERIC_DESC = {
	class = "The %s class color on unit frames, name tags and raid frames, and the unit tooltip's name and border.",
	power = 'The %s power bar on unit frames.',
	item_quality = "The %s item color: item names in the loot feed and loot rolls, and item and currency borders in bags.",
}
-- Power colors that SaftUI shows on the player frame's class power points
-- rather than a power bar, with where each exists: combo points (rogues, cat
-- form druids, vehicles), chi (windwalker monks), and on retail only holy power
-- (paladins), soul shards (warlocks) and arcane charges (arcane mages). The
-- bundled oUF builds paladin and warlock class power only from Cataclysm on
-- (GameCompatibility.Cataclysm) and arcane charges only on Midnight, so
-- Forever shows those three nowhere.
local CLASS_POWER_POINTS = {
	COMBO_POINTS = '', CHI = '',
	HOLY_POWER = ' Retail only.', SOUL_SHARDS = ' Retail only.', ARCANE_CHARGES = ' Retail only.',
}
-- The minimap's difficulty badge, shown in any instance, reads Common for
-- normal, Rare for heroic and Epic for mythic.
local DIFFICULTY_BADGE = { [1] = 'normal instances', [3] = 'heroic ones', [4] = 'mythic ones' }
for _, section in ipairs(CO.SECTIONS) do
	local pattern = GENERIC_DESC[section.key]
	for _, color in ipairs(section.colors) do
		if not color.desc and section.key == 'power' and CLASS_POWER_POINTS[color.key] then
			color.desc = ("The %s color on the player frame's class power points."):format(color.name:lower()) .. CLASS_POWER_POINTS[color.key]
		elseif not color.desc and pattern then
			color.desc = pattern:format(color.name)
			if section.key == 'item_quality' and DIFFICULTY_BADGE[color.key] then
				color.desc = color.desc .. " It also colors the minimap's difficulty badge for " .. DIFFICULTY_BADGE[color.key] .. '.'
			end
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

-- SaftUI's default for a row: st.defaults.colors[group][key], as ProfileColor.
local function DefaultColor(color)
	local from = st.defaults.colors[color.group]
	if color.key == nil then return from end
	return from[color.key]
end

-- Whether two colors look the same where the Colors tab shows them: each
-- channel as a whole 0-255 (the swatch's hex), and with an opacity (hasAlpha)
-- its whole percent.
local function SameColor(a, b, hasAlpha)
	local function byte(v) return math.floor((v or 0) * 255 + 0.5) end
	if byte(a.r) ~= byte(b.r) or byte(a.g) ~= byte(b.g) or byte(a.b) ~= byte(b.b) then return false end
	return not hasAlpha or math.floor((a.a or 1) * 100 + 0.5) == math.floor((b.a or 1) * 100 + 0.5)
end

-- A color's own reset (the options kit's default field, optionsmodel.lua): a
-- reset icon by the color's swatch while it differs from SaftUI's default; it
-- puts that back, alpha too, and says the group changed, as a Reset of the
-- whole section did for each of its colors.
local function ColorDefault(section, color)
	return {
		differs = function() return not SameColor(ProfileColor(color), DefaultColor(color), section.hasAlpha) end,
		reset = function()
			local from, c = DefaultColor(color), ProfileColor(color)
			c.r, c.g, c.b, c.a = from.r, from.g, from.b, from.a
			st:ColorsChanged(color.group)
		end,
		value = function()
			local from = DefaultColor(color)
			return from.r, from.g, from.b, from.a
		end,
	}
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
			default = ColorDefault(section, color),
		}
	end
	return {
		type = 'group',
		inline = true,
		order = index,
		name = section.name,
		desc = section.note,
		args = args,
	}
end

-- The Colors tab of Global settings: one inline section per color group, a
-- color swatch per color, each with its own reset by it while it differs
-- from SaftUI's default (no section Reset). Each row's get and set are bound
-- to its own color, so they read no info.
function CO:GetConfigTable()
	local args = {}
	for i, section in ipairs(CO.SECTIONS) do
		args[section.key] = SectionGroup(section, i)
	end
	return { type = 'group', name = 'Colors', order = 2, args = args }
end
