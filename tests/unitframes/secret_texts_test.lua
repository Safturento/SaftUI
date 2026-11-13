-- Unit frame texts with secret values, as the game hands them to an addon in
-- restricted content (enemy nameplates above all): the st:name tag
-- (SaftUI-Unitframes/tags.lua) and the health text (elements/health.lua's
-- PostUpdate).
--
-- Real: Core's helpers and profile defaults, the unit frames' defaults filled
-- the way AceDB fills them, config/profiles.lua (UF:GetProfileConfig),
-- config/groupoptions.lua and config/config.lua, updaters.lua and
-- constructors.lua (the bar and its text), elements/health.lua, and tags.lua
-- with LibStringFormat-1.0 as st.StringFormat (as init.lua makes it). The
-- stubs' C_StringUtil.WrapString and AbbreviateNumbers (tests/wow/game.lua)
-- give a table for a secret, so a case can read what the game was asked to
-- join or shorten.
--
-- Stand-ins, as config_test.lua and power_text_test.lua have them:
--   * UF:RegisterElement, a copy of unitframes.lua's table store (lines
--     126-134); unitframes.lua needs oUF, which isn't loaded here.
--   * UF.oUF, as far as tags.lua uses it: oUF's tag tables, where tags.lua
--     registers st:name (oUF calls a tag with the unit, the real unit and the
--     tag's argument, the config unit), and the class colours (oUF's own, into
--     which UF:UpdateColors merges the profile's; here the profile's).
--   * Secrets from tests/lib/secrets.lua, installed into issecretvalue by each
--     world and taken out again when the file is done.
--   * UnitHealthPercent returns a secret percent (secretPercent) and records its
--     arguments (lastHealthPercentArgs), as UnitPowerPercent does in
--     power_text_test.lua. CurveConstants.ScaleTo100 is Blizzard's 0-100 curve;
--     only its identity matters here.
--   * A case that hands the health text a secret swaps its SetText or
--     SetFormattedText for a recorder: the game's take a secret, the stub's
--     only take strings and numbers.
--
-- world(client) builds all of it on one client. The file starts on Forever; the
-- health cases with a secret health run on both clients, last.
local T = load_test_file('lib/theme_helpers.lua')
local S = load_test_file('lib/secrets.lua')

local st, UF, P, tag, secretPercent, lastHealthPercentArgs
-- Puts back the issecretvalue the current world had before S.install, or nil
-- before the first world.
local restoreSecrets

-- Each world installs the secrets once, and puts the last world's install
-- back first, so wrappers never pile up; the file's last case puts the last
-- one back.
local function world(client)
	if restoreSecrets then restoreSecrets() end
	st = T.client(client)
	load_saftui('SaftUI-Unitframes/config/default.lua')
	apply_defaults()
	UF = st:NewModule('Unitframes')
	UF.elements = {}
	function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
		self.elements[name] = { name = name, Constructor = Constructor, UpdateConfig = UpdateConfig,
			GetConfigTable = GetConfigTable, ValidUnit = ValidUnit }
	end
	load_saftui('SaftUI-Unitframes/config/profiles.lua')
	load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
	load_saftui('SaftUI-Unitframes/config/config.lua')
	load_saftui('SaftUI-Unitframes/updaters.lua')
	load_saftui('SaftUI-Unitframes/constructors.lua')
	load_saftui('SaftUI-Unitframes/elements/health.lua')
	UF.oUF = { Tags = { Events = {}, Methods = {} }, colors = { class = st.config.profile.colors.class } }
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st.StringFormat = LibStub('LibStringFormat-1.0')
	load_saftui('SaftUI-Unitframes/tags.lua')

	restoreSecrets = S.install()
	secretPercent = S.secret('PERCENT')
	CurveConstants = { ScaleTo100 = {} }
	function UnitHealthPercent(...)
		lastHealthPercentArgs = { ... }
		return secretPercent
	end
	P = UF:GetProfileConfig()
	tag = UF.oUF.Tags.Methods['st:name']
end
world('forever')

local function copy(t)
	if type(t) ~= 'table' then return t end
	local c = {}
	for k, v in pairs(t) do c[k] = copy(v) end
	if t.GetRGB then return CreateColor(t:GetRGB()) end
	return c
end

-- An element built by its own constructor, on a unit frame whose config is a
-- copy of the base unit defaults, as bar_colors_test.lua builds its bars.
local function bar(element_name)
	local unit_defaults = st.defaults.unitframes.profiles['**']
	local defaults = unit_defaults['**'] or unit_defaults
	local frame = CreateFrame('Button', 'TestUnitFrame', UIParent) -- its parts are named after it
	frame.config = { health = copy(defaults.health) }
	frame.GetConfig = function(self) return self.config end
	frame.TextOverlay = CreateFrame('Frame', nil, frame)
	return UF.elements[element_name].Constructor(frame), frame
end

------------------------------------------------------------------ the name tag

test('the name tag wraps a secret name in its hostile colour with C_StringUtil.WrapString', function()
	local name = S.secret('NAME')
	P.target.name.color_hostile, P.target.name.showLevel = true, false
	stub.units.target = { name = name, level = 22, reaction = 2 }
	local text = tag('target', 'target', 'target')
	check(type(text) == 'table' and text.wrapped == name, 'WrapString got the name')
	eq(text.prefix, '|cff' .. st.StringFormat:ToHex(st.config.profile.colors.text.red:GetRGB()), 'red before it')
	eq(text.suffix, '|r', 'and the colour closed after it')
end)
test('the name tag leaves out a secret level, reaction or classification, with no error', function()
	P.target.name.showLevel, P.target.name.show_classification, P.target.name.color_hostile = true, true, true
	stub.units.target = { name = 'Mob', level = S.secret('LVL'), reaction = S.secret('REACT'), classification = S.secret('CLS') }
	local ok, text = pcall(tag, 'target', 'target', 'target')
	check(ok, tostring(text)); eq(text, 'Mob', 'just the name')
end)
test('All caps leaves a secret name as it is', function()
	P.target.name.allCaps = true
	stub.units.target = { name = S.secret('NAME'), level = 22, reaction = 5 }
	check(pcall(tag, 'target', 'target', 'target'), 'no strupper on a secret')
end)
test('the name tag reads no UnitIsUnit: the 2019 target mark is gone, the target border replaces it', function()
	check(not read_saftui_source('SaftUI-Unitframes/tags.lua'):find('UnitIsUnit', 1, true), 'not in tags.lua')
end)

test('a secret name keeps the plain level part before it, and a class colour around it', function()
	local name = P.target.name
	name.allCaps, name.showLevel, name.color_hostile, name.colorClass = false, true, false, true
	stub.units.target = { name = S.secret('NAME'), level = 22, class = 'MAGE', player = true, classification = 'elite', reaction = 5 }
	local text = tag('target', 'target', 'target')
	local yellow = st.StringFormat:ToHex(st.config.profile.colors.text.yellow:GetRGB()) -- 22 against the player's 20
	local mage = st.StringFormat:ToHex(st.config.profile.colors.class.MAGE:GetRGB())
	check(type(text) == 'table', 'wrapped by the game')
	eq(text.prefix, '|cff' .. yellow .. '22+|r |cff' .. mage, 'the level and its mark, then the class colour')
	eq(text.suffix, '|r', 'closed after the name')
	-- A secret class can't pick a colour: the name is left uncoloured.
	stub.units.target.class = S.secret('CLASS')
	text = tag('target', 'target', 'target')
	eq(text.prefix, '|cff' .. yellow .. '22+|r ', 'just the level part')
	eq(text.suffix, '', 'and nothing to close')
	name.colorClass = false
end)

test('a plain name is built as before: the level part, then the name in its hostile colour', function()
	local name = P.target.name
	name.allCaps, name.showLevel, name.color_hostile, name.colorClass = false, true, true, false
	stub.units.target = { name = 'Kobold Miner', level = 22, classification = 'rare', reaction = 2 }
	local yellow = st.StringFormat:ToHex(st.config.profile.colors.text.yellow:GetRGB())
	local red = st.StringFormat:ToHex(st.config.profile.colors.text.red:GetRGB())
	eq(tag('target', 'target', 'target'), '|cff' .. yellow .. '22R|r |cff' .. red .. 'Kobold Miner|r')
	name.allCaps = true
	eq(tag('target', 'target', 'target'), '|cff' .. yellow .. '22R|r |cff' .. red .. 'KOBOLD MINER|r', 'All caps')
	-- No level part (Level off, no mark) and no colour: just the name.
	name.allCaps, name.showLevel, name.color_hostile = false, false, false
	stub.units.target.classification = 'normal'
	eq(tag('target', 'target', 'target'), 'Kobold Miner', 'no empty colour codes around nothing')
	-- A secret level with a plain mark: the mark, with no level to colour it.
	name.showLevel = true
	stub.units.target.level, stub.units.target.classification = S.secret('LVL'), 'elite'
	eq(tag('target', 'target', 'target'), '+ Kobold Miner', 'the mark in the text colour')
	stub.units.target = nil
end)

------------------------------------------------------------------ the health text

test('health percent with plain values is unchanged', function()
	local health = bar('Health'); health.config.text.percent = true
	health.PostUpdate(health, 'target', 72, 100)
	eq(health.text:GetText(), '72')
end)

test('the health value is whole by default, and Short shortens it: 12.5K, 1.2M', function()
	local health = bar('Health')
	health.config.text.boss_percent = false
	eq(health.config.text.short, false, 'Short is off by default')
	health.PostUpdate(health, 'target', 12500, 20000)
	eq(health.text:GetText(), '12500', 'the whole value with Short off')
	health.config.text.short = true
	for _, case in ipairs({ { 999, '999' }, { 1000, '1K' }, { 1500, '1.5K' }, { 12500, '12.5K' }, { 123456, '123.4K' },
			{ 1234567, '1.2M' }, { 45000000, '45M' }, { 2500000000, '2.5B' } }) do
		health.PostUpdate(health, 'target', case[1], case[1] * 2)
		eq(health.text:GetText(), case[2], case[1] .. ' in short')
	end
	-- Dead still wins.
	stub.units.target = { name = 'Mob', dead = true }
	health.PostUpdate(health, 'target', 0, 100)
	eq(health.text:GetText(), 'Dead')
	stub.units.target = nil
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': health percent with a secret health is drawn from UnitHealthPercent', function()
		world(client)
		local health = bar('Health'); health.config.text.percent = true
		local fmt, value
		health.text.SetFormattedText = function(_, f, v) fmt, value = f, v end
		local ok, err = pcall(health.PostUpdate, health, 'nameplate1', S.secret('CUR'), S.secret('MAX'))
		check(ok, tostring(err)); eq(fmt, '%.0f'); check(value == secretPercent, 'the game formats the percent')
		check(lastHealthPercentArgs[1] == 'nameplate1' and lastHealthPercentArgs[2] == true and lastHealthPercentArgs[3] == CurveConstants.ScaleTo100, 'scaled to 0-100')
	end)

	test(client .. ': the short health value with a secret health is shortened by the game', function()
		world(client)
		-- A plate's text: Short on, Percent and Boss percent off.
		local health = bar('Health'); health.config.text.short, health.config.text.boss_percent = true, false
		local shown
		health.text.SetText = function(_, v) shown = v end
		local current = S.secret('CUR')
		local ok, err = pcall(health.PostUpdate, health, 'nameplate1', current, S.secret('MAX'))
		check(ok, tostring(err))
		check(type(shown) == 'table' and shown.abbreviated == current, 'AbbreviateNumbers got the secret health, and SetText its result')
		-- With the same options as a plain value, so the text looks the same either way.
		eq(type(shown) == 'table' and AbbreviateNumbers(12500, shown.options), '12.5K', 'in the short form')
	end)
end

test('the secrets come out of issecretvalue once the file is done with them', function()
	restoreSecrets()
	restoreSecrets = nil
	eq(issecretvalue(S.secret('AFTER')), false, 'a secret made now is a plain value again')
end)
