-- UF:OnColorsChanged (unitframes.lua): a class, reputation, power or status
-- color change from the Colors tab recolors every unit frame at once, without
-- UpdateConfig or ApplyConfig. Loads the real unitframes.lua over a stand-in
-- oUF (its colors table) and stand-in frames that count their ForceUpdate and
-- UpdateTags calls. UF:UpdateGroupPreview and UF.testGroups live in groups.lua,
-- which isn't loaded; the tests stand them in.
load_core_helpers()
addon_namespace('SaftUI-Unitframes').oUF = {
	colors = {
		class = { MAGE = CreateColor(1, 1, 1) },
		reaction = {},
		power = {},
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

local function make_frame(additional_enabled)
	local frame = { tags = 0 }
	for _, name in ipairs({ 'Health', 'Power', 'AdditionalPower' }) do
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

local a, b
local function reset()
	a, b = make_frame(false), make_frame(true)
	UF.units = { player = a, boss = { [1] = b } }
	UF.groups = {}
	UF.testGroups = nil
	UF.UpdateGroupPreview = function() end
end
reset()

local function total_updates()
	local n = 0
	for _, f in ipairs({ a, b }) do
		n = n + f.Health.updates + f.Power.updates + f.AdditionalPower.updates + f.tags
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
	eq(a.AdditionalPower.updates, 0, 'disabled additional power left alone')
	eq(b.AdditionalPower.updates, 1, 'enabled additional power updated')
	UF.UpdateConfig, UF.ApplyConfig = nil, nil
end)

test('the test previews are drawn again', function()
	reset()
	local drawn = {}
	UF.testGroups = { party = true }
	UF.UpdateGroupPreview = function(_, group) drawn[#drawn + 1] = group end
	UF:OnColorsChanged('status')
	eq(#drawn, 1, 'one preview')
	eq(drawn[1], 'party', 'the party preview')
end)

test('a change to colors unit frames do not use recolors nothing', function()
	reset()
	for _, group in ipairs({ 'text', 'button', 'item_quality', 'renown' }) do
		UF:OnColorsChanged(group)
	end
	eq(total_updates(), 0, 'nothing force-updated')
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
