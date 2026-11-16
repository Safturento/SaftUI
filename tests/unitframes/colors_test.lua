-- UF:OnColorsChanged (unitframes.lua): a class, reputation, power or status
-- color change from the Colors tab recolors every unit frame at once, without
-- UpdateConfig or ApplyConfig. Loads the real unitframes.lua over a stand-in
-- oUF (its colors table) and stand-in frames that count their ForceUpdate and
-- UpdateTags calls. Each carries its unit as oUF does, in __unit, and no
-- .unit, which only UF.OnEnter sets (a frame never hovered has none).
-- UF:UpdateGroupPreview and UF.testGroups live in grouppreview.lua,
-- which isn't loaded; the tests stand them in.
load_core_helpers()
-- oUF as far as colors go: its color tables, the power type indexes sharing
-- their token's table (colors.power[0] is colors.power.MANA), and CreateColor,
-- which makes a color with the GetCurve oUF's gradient path calls.
local ouf_mana = CreateColor(0, 0, 1)
local ouf_methods = { GetCurve = function(self) return self.curve end }
addon_namespace('SaftUI-Unitframes').oUF = {
	CreateColor = function(_, r, g, b, a)
		local color = CreateColor(r, g, b, a)
		color.GetCurve = ouf_methods.GetCurve
		color.curve = { 'curve' }
		return color
	end,
	colors = {
		class = { MAGE = CreateColor(1, 1, 1) },
		reaction = { [2] = CreateColor(1, 0, 0) },
		power = { MANA = ouf_mana, [0] = ouf_mana },
		disconnected = CreateColor(1, 1, 1),
		tapped = CreateColor(1, 1, 1),
		roles = {},
		runes = {},
	},
}
load_saftui('SaftUI-Unitframes/unitframes.lua')

local st = SaftUI
local UF = st:GetModule('Unitframes')
local profile_colors = st.config.profile.colors

local function rgb(c)
	local r, g, b = c:GetRGB()
	return string.format('%.2f,%.2f,%.2f', r, g, b)
end

-- A unit exists unless a test lists it here.
local missing_units = {}
UnitExists = function(unit) return not missing_units[unit] end

local function make_frame(additional_enabled, unit)
	local frame = { tags = 0, __unit = unit or 'player' }
	for _, name in ipairs({ 'Health', 'Power', 'AdditionalPower', 'ClassPower' }) do
		local element = { updates = 0 }
		function element:ForceUpdate() self.updates = self.updates + 1 end
		frame[name] = element
	end
	function frame:IsElementEnabled(name)
		return name ~= 'AdditionalPower' or additional_enabled
	end
	function frame:UpdateTags() self.tags = self.tags + 1 end
	return frame
end

-- The real methods, which a test replaces and reset() puts back.
local real_update_config, real_apply_config = UF.UpdateConfig, UF.ApplyConfig

local a, b
local function reset()
	UF.UpdateConfig, UF.ApplyConfig = real_update_config, real_apply_config
	missing_units = {}
	a, b = make_frame(false, 'player'), make_frame(true, 'boss1')
	UF.units = { player = a, boss = { [1] = b } }
	UF.groups = {}
	UF.testGroups = nil
	UF.UpdateGroupPreview = function() end
end
reset()

local function total_updates()
	local n = 0
	for _, f in ipairs({ a, b }) do
		n = n + f.Health.updates + f.Power.updates + f.AdditionalPower.updates + f.ClassPower.updates + f.tags
	end
	return n
end

test('UpdateColors puts the profile status colors on oUF', function()
	profile_colors.status.disconnected = CreateColor(0.2, 0.3, 0.4)
	profile_colors.status.tapped = CreateColor(0.5, 0.6, 0.7)
	UF:UpdateColors()
	eq(rgb(UF.oUF.colors.disconnected), '0.20,0.30,0.40', 'disconnected')
	eq(rgb(UF.oUF.colors.tapped), '0.50,0.60,0.70', 'tapped')
end)

test('a class color change recolors every unit frame lightly', function()
	reset()
	local function fail() error('a color change must not rebuild the frames') end
	UF.UpdateConfig, UF.ApplyConfig = fail, fail
	profile_colors.class.MAGE = CreateColor(0.1, 0.2, 0.3)
	UF:OnColorsChanged('class')
	eq(rgb(UF.oUF.colors.class.MAGE), '0.10,0.20,0.30', 'oUF mage color')
	for _, f in ipairs({ a, b }) do
		eq(f.Health.updates, 1, 'health updated')
		eq(f.Power.updates, 1, 'power updated')
		eq(f.tags, 1, 'tags updated')
	end
	eq(a.AdditionalPower.updates + b.AdditionalPower.updates, 0, 'additional power is not a class-colored bar')
	eq(a.ClassPower.updates, 0, 'nor is class power')
end)

test('a power color change updates the power bars, the additional power where enabled, and class power', function()
	reset()
	UF:OnColorsChanged('power')
	eq(a.Power.updates, 1, 'power updated')
	eq(a.Health.updates + a.tags, 0, 'no health, no tags')
	eq(a.AdditionalPower.updates, 0, 'disabled additional power left alone')
	eq(b.AdditionalPower.updates, 1, 'enabled additional power updated')
	eq(a.ClassPower.updates, 1, 'class power updated (it sets its color only on a visibility check)')
end)

test('a frame whose unit does not exist is skipped, the others still update', function()
	reset()
	missing_units = { boss1 = true }
	local c = make_frame(false, 'party1')
	UF.units.party1 = c
	UF.UpdateGroupPreview = function() end
	UF:OnColorsChanged('class')
	missing_units = {}
	eq(b.Health.updates + b.tags, 0, 'the absent boss frame is left alone')
	eq(a.Health.updates, 1, 'player updated')
	eq(c.Health.updates, 1, 'party frame updated')
end)

test('the test previews are drawn again', function()
	reset()
	local drawn = {}
	UF.testGroups = { party = true }
	UF.UpdateGroupPreview = function(_, group) drawn[#drawn + 1] = group end
	UF:OnColorsChanged('class')
	eq(#drawn, 1, 'one preview')
	eq(drawn[1], 'party', 'the party preview')
	UF:OnColorsChanged('status')
	eq(#drawn, 2, 'a status color redraws it: its offline members wear Disconnected')
	UF:OnColorsChanged('threat')
	eq(#drawn, 2, 'a threat color does not')
end)

test('a change to colors unit frames do not use recolors nothing', function()
	reset()
	for _, group in ipairs({ 'button', 'item_quality', 'renown' }) do
		UF:OnColorsChanged(group)
	end
	eq(total_updates(), 0, 'nothing force-updated')
end)

test('a threat color change recolors no unit frame: only the plates take it (nameplates/threat.lua)', function()
	reset()
	local colored = 0
	local original = UF.UpdateColors
	UF.UpdateColors = function() colored = colored + 1 end
	UF:OnColorsChanged('threat')
	UF.UpdateColors = original
	eq(total_updates(), 0, 'nothing force-updated')
	eq(colored, 1, "oUF's colors still copied")
end)

test('before unit frames are enabled a change does nothing', function()
	reset()
	UF.units = nil
	local called = 0
	local original = UF.UpdateColors
	UF.UpdateColors = function() called = called + 1 end
	UF:OnColorsChanged('class')
	UF.UpdateColors = original
	eq(called, 0, 'UpdateColors not called')
end)

local function snapshot(t)
	local out = {}
	for k, v in pairs(t) do out[k] = v end
	return out
end

test('the whole pass merges class, reaction, power and status in place: oUF keeps its tables, methods and aliases', function()
	reset()
	local oc = UF.oUF.colors
	profile_colors.power.MANA = CreateColor(0.31, 0.32, 0.33)
	profile_colors.reaction[2] = CreateColor(0.41, 0.42, 0.43)
	profile_colors.class.MAGE = CreateColor(0.51, 0.52, 0.53)
	profile_colors.status.disconnected = CreateColor(0.61, 0.62, 0.63)
	local mana, reaction2, mage, disconnected = oc.power.MANA, oc.reaction[2], oc.class.MAGE, oc.disconnected
	local tables = { oc.power, oc.reaction, oc.class }
	UF:UpdateColors()
	check(oc.power.MANA == mana and oc.reaction[2] == reaction2 and oc.class.MAGE == mage and oc.disconnected == disconnected,
		"oUF's own color tables were replaced")
	check(oc.power == tables[1] and oc.reaction == tables[2] and oc.class == tables[3], "oUF's groups were replaced")
	check(oc.power[0] == oc.power.MANA, "the power type index is no longer Mana's table")
	eq(rgb(oc.power[0]), '0.31,0.32,0.33', 'so it follows the pick')
	eq(rgb(oc.reaction[2]), '0.41,0.42,0.43')
	eq(rgb(oc.class.MAGE), '0.51,0.52,0.53')
	eq(rgb(oc.disconnected), '0.61,0.62,0.63')
	for _, group in ipairs({ 'power', 'reaction', 'class' }) do
		for key, color in pairs(profile_colors[group]) do
			check(oc[group][key] ~= color, group .. '.' .. tostring(key) .. ": a profile table became oUF's")
		end
	end
end)

test('a pass with every color already in oUF makes no table', function()
	reset()
	UF:UpdateColors()   -- any copy a key oUF lacked needs is made here
	collectgarbage(); collectgarbage()
	collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, 200 do UF:UpdateColors() end
	local grown = collectgarbage('count') - before
	collectgarbage('restart')
	check(grown < 8, 'a whole pass allocated: ' .. grown .. ' KB over 200 passes')
	local snap = snapshot(UF.oUF.colors.power)
	UF:UpdateColors('power', 'MANA')
	for k, v in pairs(snap) do check(UF.oUF.colors.power[k] == v, 'a by-key pass replaced ' .. tostring(k)) end
end)

test('a color oUF lacks is made by oUF, so its elements can call its methods: a copy, never the profile table', function()
	reset()
	for _, key in ipairs({ 'POWER_TYPE_STEAM', 'POWER_TYPE_PYRITE', 'ALTPOWER' }) do
		local mine = CreateColor(0.2, 0.4, 0.6)
		profile_colors.power[key] = mine
		UF.oUF.colors.power[key] = nil
		UF:UpdateColors()
		local made = UF.oUF.colors.power[key]
		check(made ~= mine, key .. ': the profile table became oUF\'s')
		eq(type(made.GetCurve), 'function', key .. ': a gradient can ask it for its curve')
		eq(rgb(made), '0.20,0.40,0.60', key .. ': with the profile\'s values')
		-- the by-key path the same
		UF.oUF.colors.power[key] = nil
		UF:UpdateColors('power', key)
		check(UF.oUF.colors.power[key] ~= mine and UF.oUF.colors.power[key].GetCurve, key .. ': by key')
		profile_colors.power[key] = nil
		UF.oUF.colors.power[key] = nil
	end
end)

test('a color oUF lacks is copied in, so a later profile switch cannot write into the old profile', function()
	reset()
	local old = CreateColor(0.1, 0.2, 0.3)
	profile_colors.class.ZZZ = old
	UF:UpdateColors()
	check(UF.oUF.colors.class.ZZZ ~= old, 'the whole pass aliased the profile color')
	eq(rgb(UF.oUF.colors.class.ZZZ), '0.10,0.20,0.30')
	-- the switch: another profile's value for the same key
	profile_colors.class.ZZZ = CreateColor(0.7, 0.8, 0.9)
	UF:UpdateColors()
	eq(rgb(old), '0.10,0.20,0.30', 'the old profile keeps its color')
	eq(rgb(UF.oUF.colors.class.ZZZ), '0.70,0.80,0.90', 'oUF follows the new one')
	-- the by-key path
	UF.oUF.colors.class.ZZZ = nil
	local third = CreateColor(0.4, 0.5, 0.6)
	profile_colors.class.ZZZ = third
	UF:UpdateColors('class', 'ZZZ')
	check(UF.oUF.colors.class.ZZZ ~= third, 'the key pass aliased the profile color')
	profile_colors.class.ZZZ = nil
	UF.oUF.colors.class.ZZZ = nil
end)
