-- The st:name tag's friendly colour (NameColor in SaftUI-Unitframes/tags.lua):
-- the Color friendly option colours a friendly unit's name in its reaction
-- colour; players keep their class colour, and with the option off nothing
-- changes. Built as secret_texts_test.lua builds its world: Core's helpers and
-- defaults, the unit frames' defaults, config/profiles.lua,
-- config/groupoptions.lua, config/config.lua, tags.lua and
-- nameplates/options.lua, with a stand-in UF:RegisterElement and UF.oUF (its
-- tag tables and the colours, where oUF's reaction table holds the profile's
-- colours as UF:UpdateColors merges them).
local T = load_test_file('lib/theme_helpers.lua')
local S = load_test_file('lib/secrets.lua')

local st = T.client('forever')
load_saftui('SaftUI-Unitframes/config/default.lua')
apply_defaults()
local UF = st:NewModule('Unitframes')
UF.elements = {}
function UF:RegisterElement() end
load_saftui('SaftUI-Unitframes/config/profiles.lua')
load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
load_saftui('SaftUI-Unitframes/config/parts.lua')
load_saftui('SaftUI-Unitframes/config/config.lua')
UF.oUF = { Tags = { Events = {}, Methods = {} },
	colors = { class = st.config.profile.colors.class, reaction = st.config.profile.colors.reaction } }
load_string_format()
load_saftui('SaftUI-Unitframes/tags.lua')
load_saftui('SaftUI-Unitframes/nameplates/options.lua')
local restoreSecrets = S.install()

local P = UF:GetProfileConfig()
local tag = UF.oUF.Tags.Methods['st:name']
local function hex(color) return '|cff' .. st.StringFormat:ToHex(color:GetRGB()) end

local function setup(config, unit)
	local name = P.target.name
	name.showLevel, name.show_classification, name.allCaps = false, false, false
	name.colorClass, name.color_hostile, name.color_friendly = false, false, nil
	for k, v in pairs(config) do name[k] = v end
	stub.units.target = unit
end

test('color_friendly colours a friendly NPC in its reaction colour', function()
	for _, reaction in ipairs({ 5, 8 }) do
		setup({ color_friendly = true }, { name = 'Guard', level = 20, reaction = reaction })
		eq(tag('target', 'target', 'target'), hex(UF.oUF.colors.reaction[reaction]) .. 'Guard|r', 'reaction ' .. reaction)
	end
end)

test('players keep their class colour', function()
	setup({ colorClass = true, color_friendly = true },
		{ name = 'Mage', level = 20, class = 'MAGE', player = true, reaction = 5 })
	eq(tag('target', 'target', 'target'), hex(st.config.profile.colors.class.MAGE) .. 'Mage|r')
end)

test('color_friendly is off by default and leaves a friendly NPC uncoloured', function()
	local defaults = st.defaults.unitframes.profiles['**']
	eq((defaults['**'] or defaults).name.color_friendly, false, 'the base default')
	setup({}, { name = 'Guard', level = 20, reaction = 5 })
	P.target.name.color_friendly = false
	eq(tag('target', 'target', 'target'), 'Guard')
	P.target.name.color_friendly = nil
	eq(tag('target', 'target', 'target'), 'Guard', 'unset')
end)

test('hostile red and neutral yellow are unchanged, with the option on or off', function()
	-- Danger and Caution at values that are not their defaults, so a hardcoded color fails.
	st.config.profile.colors.text.danger:SetRGB(0.9, 0.2, 0.2); st.config.profile.colors.text.caution:SetRGB(0.7, 0.7, 0.2)
	for _, friendly in ipairs({ false, true }) do
		setup({ color_hostile = true, color_friendly = friendly }, { name = 'Mob', level = 20, reaction = 2 })
		eq(tag('target', 'target', 'target'), hex(st.config.profile.colors.text.danger) .. 'Mob|r')
		stub.units.target.reaction = 4
		eq(tag('target', 'target', 'target'), hex(st.config.profile.colors.text.caution) .. 'Mob|r')
	end
	setup({ color_friendly = true }, { name = 'Mob', level = 20, reaction = 2 })
	eq(tag('target', 'target', 'target'), 'Mob', 'a hostile unit is not coloured by color_friendly alone')
end)

test('a secret reaction gives no colour and no error', function()
	setup({ color_friendly = true, color_hostile = true }, { name = 'Guard', level = 20, reaction = S.secret('REACT') })
	local ok, text = pcall(tag, 'target', 'target', 'target')
	check(ok, tostring(text)); eq(text, 'Guard')
end)

test("the name redraws on a faction change, not on every target change, and reads no 'target' unit", function()
	local events = {}
	for event in UF.oUF.Tags.Events['st:name']:gmatch('%S+') do events[event] = true end
	check(events.UNIT_FACTION, 'a neutral unit turning hostile redraws its name colour')
	check(not events.PLAYER_TARGET_CHANGED, 'no redraw of every plate on a target change')
	-- oUF's target frame updates its own tags on a target change (Libraries/oUF/units.lua,
	-- HandleUnit), which this test doesn't load. The tag must then read only the
	-- unit it is given: record every unit the game is asked about.
	local seen = {}
	local names = { 'UnitLevel', 'UnitReaction', 'UnitName', 'UnitClass', 'UnitIsPlayer', 'UnitClassification',
		'UnitPlayerControlled', 'UnitInPartyIsAI' }
	local originals = {}
	for _, fn in ipairs(names) do
		originals[fn] = _G[fn]
		if originals[fn] then
			_G[fn] = function(unit, ...) seen[unit] = true; return originals[fn](unit, ...) end
		end
	end
	setup({ showLevel = true, show_classification = true, colorClass = true, color_hostile = true, color_friendly = true },
		{ name = 'Mob', level = 20, reaction = 2, class = 'MAGE' })
	stub.units.nameplate1 = stub.units.target
	pcall(tag, 'nameplate1', 'nameplate1', 'target')
	for _, fn in ipairs(names) do _G[fn] = originals[fn] end
	stub.units.nameplate1 = nil
	check(seen.nameplate1, 'it read the unit it was given')
	check(not seen.target, "and never 'target'")
end)

test('the secrets are put back', function()
	stub.units.target = nil
	restoreSecrets()
	check(true)
end)

test("the Color hostile and Color by reaction descriptions name the color roles, not their hues, which the player can change", function()
	local function line(path, needle)
		for text in read_saftui_source(path):gmatch('[^\n]+') do
			if text:find(needle, 1, true) then return text end
		end
		error(path .. ' has no line with ' .. needle)
	end
	local hostile = line('SaftUI-Unitframes/elements/name.lua', "'Color hostile'")
	check(hostile:find('Danger', 1, true) and hostile:find('Caution', 1, true), 'Color hostile names Danger and Caution')
	check(not hostile:find('red') and not hostile:find('yellow'), 'and no hue')
	local desc = line('SaftUI-Unitframes/config/config.lua', 'By how the unit stands with you')
	check(desc:find('Reputation', 1, true) and not desc:find('red') and not desc:find('yellow') and not desc:find('green'), 'Color by reaction names the Reputation colors, no hue')
end)
