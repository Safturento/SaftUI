-- UF.NameParts, UF.FormatName (tags.lua) and UF.PlainHealthText
-- (elements/health.lua): the name and health text the st:name tag and
-- PostUpdateHealth build from plain values, which the nameplate preview calls
-- too. Built as name_color_test.lua builds its world, with updaters.lua (the
-- short number) and health.lua.
local T = load_test_file('lib/theme_helpers.lua')

local st = T.client('forever')
load_saftui('SaftUI-Unitframes/config/default.lua')
apply_defaults()
local UF = st:NewModule('Unitframes')
UF.elements = {}
function UF:RegisterElement() end
UF.oUF = { Tags = { Events = {}, Methods = {} },
	colors = { class = st.config.profile.colors.class, reaction = st.config.profile.colors.reaction } }
load_string_format()
load_saftui('SaftUI-Unitframes/updaters.lua')
load_saftui('SaftUI-Unitframes/constructors.lua')
load_saftui('SaftUI-Unitframes/elements/health.lua')
load_saftui('SaftUI-Unitframes/tags.lua')

local function hex(color) return '|cff' .. st.StringFormat:ToHex(color:GetRGB()) end

test('a hostile reaction gets the danger colour, a neutral one caution', function()
	local prefix, suffix = UF.NameParts({ color_hostile = true }, { reaction = 2 })
	eq(prefix, hex(st:Color('text', 'danger')))
	eq(suffix, '|r')
	prefix = UF.NameParts({ color_hostile = true }, { reaction = 4 })
	eq(prefix, hex(st:Color('text', 'caution')))
end)

test('no colour option leaves the name bare', function()
	local prefix, suffix = UF.NameParts({}, { reaction = 2 })
	eq(prefix, ''); eq(suffix, '')
end)

test('the level shows in its colour, ?? for a skull, + for an elite', function()
	local config = { showLevel = true, showMaxLevel = true, showSameLevel = true }
	local prefix = UF.NameParts(config, { level = 62, playerLevel = 60 })
	eq(prefix, st.StringFormat:ColorString('62', st:Color('text', 'caution'):GetRGB()) .. ' ')
	prefix = UF.NameParts(config, { level = -1, playerLevel = 60 })
	assert(prefix:find('??', 1, true), prefix)
	prefix = UF.NameParts({ show_classification = true }, { classification = 'elite' })
	eq(prefix, '+ ')
end)

test('a player with colorClass gets the class colour', function()
	local prefix = UF.NameParts({ colorClass = true }, { isPlayer = true, class = 'MAGE' })
	eq(prefix, hex(st.config.profile.colors.class.MAGE))
	prefix = UF.NameParts({ colorClass = true }, { isPlayer = true })
	eq(prefix, '', 'no class known')
end)

test('colorClassNPC colours a non-player, colorClassPet a pet, color_friendly a friendly', function()
	local prefix = UF.NameParts({ colorClassNPC = true }, { isPlayer = false, class = 'MAGE' })
	eq(prefix, hex(st.config.profile.colors.class.MAGE))
	eq(UF.NameParts({ colorClassNPC = true }, { class = 'MAGE' }), '', 'unknown is not an NPC')
	prefix = UF.NameParts({ colorClassPet = true }, { isPlayer = false, isPet = true, class = 'HUNTER' })
	eq(prefix, hex(st.config.profile.colors.class.HUNTER))
	prefix = UF.NameParts({ color_friendly = true }, { reaction = 5 })
	eq(prefix, hex(UF.oUF.colors.reaction[5]))
end)

test('a level part and a colour join in that order', function()
	local prefix, suffix = UF.NameParts({ showLevel = true, showMaxLevel = true, showSameLevel = true, color_hostile = true },
		{ level = 62, playerLevel = 60, reaction = 2 })
	eq(prefix, st.StringFormat:ColorString('62', st:Color('text', 'caution'):GetRGB()) .. ' ' .. hex(st:Color('text', 'danger')))
	eq(suffix, '|r')
end)

test('FormatName puts in capitals, cuts and joins', function()
	eq(UF.FormatName({ allCaps = true, maxLength = 4 }, 'Thrall', '<', '>'), '<THRA>')
	eq(UF.FormatName({ maxLength = 5 }, nil, 'a', 'b'), 'ab')
end)

test('PlainHealthText', function()
	eq(UF.PlainHealthText({ short = true }, 180000, 250000), UF.ShortNumber(180000))
	eq(UF.PlainHealthText({}, 180000, 250000), '180000')
	eq(UF.PlainHealthText({ percent = true }, 180000, 250000), '72')
	eq(UF.PlainHealthText({ hide_full = true }, 250000, 250000), '')
	eq(UF.PlainHealthText({ hide_full = true }, 1, 250000), '1')
	eq(UF.PlainHealthText({}, 0, 250000, true), 'Dead')
	eq(UF.PlainHealthText({ deficit = true }, 180000, 250000), '-70000')
	eq(UF.PlainHealthText({ deficit = true }, 250000, 250000), '', 'a zero deficit is blank')
	eq(UF.PlainHealthText({ boss_percent = true }, 180000, 250000, false, true), '180000 | 72.0')
	eq(UF.PlainHealthText({ boss_percent = true }, 180000, 250000, false, false), '180000')
end)
