-- Unit frame texts with secret values, as the game hands them to an addon in
-- restricted content (enemy nameplates above all): the st:name tag
-- (SaftUI-Unitframes/tags.lua) and the health text (elements/health.lua's
-- PostUpdate).
--
-- Real: Core's helpers and profile defaults, the unit frames' defaults filled
-- the way AceDB fills them, config/profiles.lua (UF:GetProfileConfig),
-- config/groupoptions.lua and config/config.lua, updaters.lua and
-- constructors.lua (the bar and its text), elements/health.lua, tags.lua with
-- LibStringFormat-1.0 as st.StringFormat (as init.lua makes it), and
-- nameplates/options.lua. The stubs' C_StringUtil.WrapString and
-- AbbreviateNumbers (tests/wow/game.lua) give a table for a secret, so a case
-- can read what the game was asked to join or shorten.
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
	load_saftui('SaftUI-Unitframes/elements/power.lua')
	load_saftui('SaftUI-Unitframes/elements/additionalpower.lua')
	UF.oUF = { Tags = { Events = {}, Methods = {} }, colors = { class = st.config.profile.colors.class } }
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st.StringFormat = LibStub('LibStringFormat-1.0')
	load_saftui('SaftUI-Unitframes/tags.lua')
	load_saftui('SaftUI-Unitframes/nameplates/options.lua')

	restoreSecrets = S.install()
	-- The game's: a zero gives an empty string, any other value as it is.
	function C_StringUtil.TruncateWhenZero(value)
		if not issecretvalue(value) and value == 0 then return '' end
		return value
	end
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
	frame.config = { health = copy(defaults.health), power = copy(defaults.power), additionalpower = copy(defaults.additionalpower) }
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
	eq(text.prefix, '|cff' .. st.StringFormat:ToHex(st.config.profile.colors.text.danger:GetRGB()), 'red before it')
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
	local yellow = st.StringFormat:ToHex(st.config.profile.colors.text.caution:GetRGB()) -- 22 against the player's 20
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
	local yellow = st.StringFormat:ToHex(st.config.profile.colors.text.caution:GetRGB())
	local red = st.StringFormat:ToHex(st.config.profile.colors.text.danger:GetRGB())
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

test('a level far below the player is Text > Muted (it was Grey), at a Muted that is not the default', function()
	local name = P.target.name
	name.allCaps, name.showLevel, name.color_hostile, name.colorClass = false, true, false, false
	stub.units.target = { name = 'Mob', level = 5, classification = 'normal', reaction = 5 } -- 15 below the player's 20
	local muted = st.config.profile.colors.text.muted
	local keep = { muted:GetRGB() }
	muted:SetRGB(0.2, 0.4, 0.6)
	eq(tag('target', 'target', 'target'), '|cff336699' .. '5|r Mob', 'the level in Muted')
	muted:SetRGB(unpack(keep))
	stub.units.target = nil
end)

test('a level tag takes its role by the difference from the player (20): Danger, Warning, Caution, Success, Muted, at odd values', function()
	local name = P.target.name
	name.allCaps, name.showLevel, name.color_hostile, name.colorClass = false, true, false, false
	local text = st.config.profile.colors.text
	local odd = { danger = { 0.9, 0.2, 0.2 }, warning = { 0.8, 0.4, 0.1 }, caution = { 0.7, 0.7, 0.2 }, success = { 0.2, 0.9, 0.3 }, muted = { 0.3, 0.3, 0.9 } }
	local keep = {}
	for key, c in pairs(odd) do keep[key] = { text[key]:GetRGB() }; text[key]:SetRGB(unpack(c)) end
	local function level_hex(level)
		stub.units.target = { name = 'Mob', level = level, classification = 'normal', reaction = 5 }
		return tag('target', 'target', 'target')
	end
	local function paint(key, level) return '|cff' .. st.StringFormat:ToHex(unpack(odd[key])) .. level .. '|r Mob' end
	eq(level_hex(25), paint('danger', 25), 'five or more above: Danger')
	eq(level_hex(23), paint('warning', 23), 'three or four above: Warning')
	eq(level_hex(21), paint('caution', 21), 'near your level: Caution')
	eq(level_hex(17), paint('caution', 17), 'three below is still near')
	eq(level_hex(16), paint('success', 16), 'a lower level: Success')
	eq(level_hex(10), paint('success', 10), 'ten below')
	eq(level_hex(9), paint('muted', 9), 'far below: Muted')
	for key, c in pairs(keep) do text[key]:SetRGB(unpack(c)) end
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

test('a plain full health under Deficit shows nothing, not -0; Percent rounds a plain value as it does a secret one', function()
	local health = bar('Health')
	health.config.text.deficit, health.config.text.hide_full, health.config.text.boss_percent = true, false, false
	health.PostUpdate(health, 'target', 100, 100)
	eq(health.text:GetText(), '', 'full: nothing')
	health.PostUpdate(health, 'target', 60, 100)
	eq(health.text:GetText(), '-40', 'missing: as before')
	-- Percent: '%.0f' for both, so 99.6 is 100 (a floor would say 99).
	health.config.text.deficit, health.config.text.percent = false, true
	health.PostUpdate(health, 'target', 996, 1000)
	eq(health.text:GetText(), '100', 'a plain 99.6 rounds')
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': Hide full with a secret health shows the text: the game answers no "is this zero", and nothing is compared', function()
		world(client)
		local health = bar('Health')
		health.config.text.hide_full, health.config.text.boss_percent = true, false
		-- Hide full has no use for the missing health; asking would be the old path.
		local asked
		UnitHealthMissing = function() asked = true; return S.secret('MISSING') end
		local shown
		health.text.SetText = function(_, v) shown = v end
		local current = S.secret('CUR')
		local ok, err = pcall(health.PostUpdate, health, 'raid1', current, S.secret('MAX'))
		check(ok, tostring(err))
		check(shown == current, 'the text shows')
		check(not asked, 'no missing health asked for')
		-- A plain full health still hides it.
		health.PostUpdate(health, 'raid1', 100, 100)
		eq(shown, '', 'plain and full: hidden')
		UnitHealthMissing = nil
	end)

	test(client .. ': Boss percent with a secret level shows no percent, and a secret health joins the percent in the game', function()
		world(client)
		local health = bar('Health')
		health.config.text.boss_percent = true
		local shown, fmt, args
		health.text.SetText = function(_, v) shown = v end
		health.text.SetFormattedText = function(_, f, ...) fmt, args = f, { ... } end
		-- A secret level: no percent, whatever the health is. The test model
		-- can't make a compare with a secret fail (Lua 5.1 says false where the
		-- game errors), so the guard is pinned by what it asks: the level is
		-- checked with issecretvalue before it is compared.
		local level = S.secret('LVL')
		stub.units.boss1 = { name = 'Boss', level = level }
		local current = S.secret('CUR')
		local asked
		local was = issecretvalue
		issecretvalue = function(value) if value == level then asked = true end return was(value) end
		local ok, err = pcall(health.PostUpdate, health, 'boss1', current, S.secret('MAX'))
		issecretvalue = was
		check(ok, tostring(err)); check(shown == current and fmt == nil, 'the health alone')
		check(asked, 'the level was asked about before it was compared')
		-- A plain skull level and a secret health: the game formats the parts.
		stub.units.boss1.level = -1
		shown, fmt = nil, nil
		ok, err = pcall(health.PostUpdate, health, 'boss1', current, S.secret('MAX'))
		check(ok, tostring(err))
		check(shown == nil, 'nothing written over the joined text')
		eq(fmt, '%s | %.1f', 'joined by the game')
		check(args[1] == current and args[2] == secretPercent, 'the health, then the percent')
		check(lastHealthPercentArgs[1] == 'boss1' and lastHealthPercentArgs[2] == true and lastHealthPercentArgs[3] == CurveConstants.ScaleTo100, 'scaled to 0-100')
		-- A plain health under a skull level, as before.
		health.PostUpdate(health, 'boss1', 500, 1000)
		eq(shown, '500 | 50.0', 'plain')
		stub.units.boss1 = nil
	end)
end

------------------------------------------------------------------ the power texts

-- Power's PostUpdate asks the game how much power is missing for a secret
-- value, which the stubs don't have: the amount doesn't matter here, only
-- that it isn't zero.
local function power_world()
	UnitPowerMissing = UnitPowerMissing or function() return 1 end
	C_StringUtil.TruncateWhenZero = C_StringUtil.TruncateWhenZero or function(value) return value end
	UnitPercentLast = nil
end

test('Short is off by default on the power and additional power texts, as health\'s is', function()
	eq(st.defaults.unitframes.profiles['**']['**'].power.text.short, false, 'power')
	eq(st.defaults.unitframes.profiles['**']['**'].additionalpower.text.short, false, 'additional power')
end)

test('the power text: Short shortens a plain value as health does, 1K, 12.5K, 1.2M', function()
	power_world()
	local power = bar('Power')
	power.config.enable, power.config.text.short = true, true
	local health = bar('Health')
	health.config.text.short, health.config.text.boss_percent = true, false
	for _, case in ipairs({ { 999, '999' }, { 1000, '1K' }, { 1500, '1.5K' }, { 12500, '12.5K' }, { 123456, '123.4K' },
			{ 1234567, '1.2M' }, { 2500000000, '2.5B' } }) do
		power.PostUpdate(power, 'player', case[1], 0, case[1] * 2)
		eq(power.text:GetText(), case[2], case[1] .. ' in short')
		health.PostUpdate(health, 'target', case[1], case[1] * 2)
		eq(power.text:GetText(), health.text:GetText(), case[1] .. ': what health shows')
	end
end)

test('the power text: Short off shows the value as it did, whole under 10000, shortened over', function()
	power_world()
	local power = bar('Power')
	power.config.enable = true
	eq(power.config.text.short, false, 'off by default')
	power.PostUpdate(power, 'player', 1500, 0, 3000)
	eq(power.text:GetText(), '1500', 'a value under 10000 whole')
	power.PostUpdate(power, 'player', 12500, 0, 30000)
	eq(power.text:GetText(), st.StringFormat:ShortFormat(12500, 1), 'one over 10000 as before')
end)

test('the power text: Short does not apply to Percent, nor to Hide full', function()
	power_world()
	local power = bar('Power')
	power.config.enable, power.config.text.short = true, true
	power.config.text.percent = true
	power.PostUpdate(power, 'player', 12500, 0, 25000)
	eq(power.text:GetText(), '50', 'Percent: the percent, whole, not 12.5K')
	power.config.text.percent = false
	power.config.text.hide_full = true
	power.PostUpdate(power, 'player', 25000, 0, 25000)
	eq(power.text:GetText(), '', 'Hide full: the text is empty while full')
	power.PostUpdate(power, 'player', 12500, 0, 25000)
	eq(power.text:GetText(), '12.5K', 'and short while it is not')
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the power text with a secret value: Short has the game shorten it, off shows it as it is', function()
		world(client)
		power_world()
		local power = bar('Power')
		power.config.enable = true
		local shown
		power.text.SetText = function(_, v) shown = v end
		power.text.SetFormattedText = function() error('a secret value is set with SetText') end
		local current, max = S.secret('CUR'), S.secret('MAX')
		power.config.text.short = true
		local ok, err = pcall(power.PostUpdate, power, 'player', current, 0, max)
		check(ok, tostring(err))
		check(type(shown) == 'table' and shown.abbreviated == current, 'AbbreviateNumbers got the secret power, and SetText its result')
		eq(type(shown) == 'table' and AbbreviateNumbers(12500, shown.options), '12.5K', 'in health\'s short form')
		power.config.text.short = false
		ok, err = pcall(power.PostUpdate, power, 'player', current, 0, max)
		check(ok, tostring(err))
		check(shown == current, 'Short off: the secret as it is')
	end)
end

test('the additional power text: Short shortens the mana, a secret mana too; Percent and Hide full come first', function()
	local function mana_bar()
		local ap = bar('AdditionalPower')
		ap.__owner = { unit = 'player' }
		return ap
	end
	local ap = mana_bar()
	eq(ap.config.text.short, false, 'off by default')
	ap:PostUpdate(12500, 50000)
	eq(ap.text:GetText(), '12500', 'Short off: the value whole')
	ap.config.text.short = true
	for _, case in ipairs({ { 999, '999' }, { 1500, '1.5K' }, { 12500, '12.5K' }, { 1234567, '1.2M' } }) do
		ap:PostUpdate(case[1], case[1] * 4)
		eq(ap.text:GetText(), case[2], case[1] .. ' in short')
	end
	ap.config.text.percent = true
	ap:PostUpdate(12500, 50000)
	eq(ap.text:GetText(), '25', 'Percent: the percent, not 12.5K')
	ap.config.text.percent, ap.config.text.hide_full = false, true
	ap:PostUpdate(50000, 50000)
	eq(ap.text:GetText(), '', 'Hide full: empty while full')
	ap.config.text.hide_full = false
	local shown
	ap.text.SetText = function(_, v) shown = v end
	local current = S.secret('MANA')
	local ok, err = pcall(ap.PostUpdate, ap, current, S.secret('MAX'))
	check(ok, tostring(err))
	check(type(shown) == 'table' and shown.abbreviated == current, 'a secret mana is abbreviated by the game')
	ap.config.text.short = false
	ok, err = pcall(ap.PostUpdate, ap, current, S.secret('MAX'))
	check(ok and shown == current, 'Short off: the secret as it is')
end)

test('the secrets come out of issecretvalue once the file is done with them', function()
	restoreSecrets()
	restoreSecrets = nil
	eq(issecretvalue(S.secret('AFTER')), false, 'a secret made now is a plain value again')
end)
