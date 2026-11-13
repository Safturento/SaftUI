-- A unit frame's first update, and its bars' colour flags:
--   - a group header's unit button is updated once, from oUF's init callback
--     (UF.InitUnit), after oUF has enabled its elements; a single unit is
--     left to OnEnable's UF:ApplyConfig;
--   - UF:OnEnable registers UF.InitUnit before it spawns anything;
--   - a group button still gets oUF's range fade, with its config's alphas,
--     and its aura areas follow their config, which oUF's aura Enable would
--     otherwise have turned on after it;
--   - health's and power's colorTapping and colorReaction go through oUF's
--     setters once oUF has enabled the bar (forced, so UNIT_FACTION is
--     registered or dropped to match), and are plain fields before that.
--
-- Real: Core's helpers and profile defaults, every unit's defaults, filled the
-- way AceDB fills them; unitframes.lua (UF.ConstructUnit, UF.InitUnit,
-- UF:UpdateUnitFrame); the group files (grouplayout.lua, groups.lua,
-- blizzardraid.lua, grouppreview.lua); config/profiles.lua
-- (UF:GetProfileConfig) and config/config.lua; constructors.lua, updaters.lua
-- and tags.lua; the files elements/elements.xml lists; LibStringFormat-1.0,
-- which init.lua makes st.StringFormat.
--
-- Stand-in: oUF (tests/unitframes/fixtures/ouf.lua, which says what the real
-- one does beyond it), made before unitframes.lua loads, with SaftUI's style
-- and UF.InitUnit registered as UF:OnEnable registers them.
local fixture = load_test_file('unitframes/fixtures/ouf.lua')

load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'arena', 'party', 'raid10', 'raid40' }) do
	load_saftui('SaftUI-Unitframes/config/units/' .. unit .. '.lua')
end
apply_defaults()
local ouf = fixture.new()
addon_namespace('SaftUI-Unitframes').oUF = ouf
load_saftui('SaftUI-Unitframes/unitframes.lua')
load_saftui('SaftUI-Unitframes/grouplayout.lua')
load_saftui('SaftUI-Unitframes/groups.lua')
load_saftui('SaftUI-Unitframes/blizzardraid.lua')
load_saftui('SaftUI-Unitframes/grouppreview.lua')
load_saftui('SaftUI-Unitframes/config/profiles.lua')
load_saftui('SaftUI-Unitframes/config/config.lua')
load_saftui('SaftUI-Unitframes/constructors.lua')
load_saftui('SaftUI-Unitframes/updaters.lua')
load_saftui('SaftUI-Unitframes/aurafilters.lua') -- the aura groups' filters (UF.AuraFilter), as the TOC loads it after updaters
load_saftui('SaftUI-Unitframes/tags.lua')
for _, file in ipairs({ 'name', 'auras', 'aurawatch', 'power', 'additionalpower', 'health', 'castbar', 'portrait', 'classpower', 'indicators' }) do
	load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
end
load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')

local st = SaftUI
st.StringFormat = LibStub('LibStringFormat-1.0')
local UF = st:GetModule('Unitframes')
local P = UF:GetProfileConfig()

-- What UF:OnEnable sets up before it spawns, as far as these frames need it.
ouf:RegisterInitCallback(UF.InitUnit)
ouf:RegisterStyle('SaftUI', UF.ConstructUnit)
ouf:SetActiveStyle('SaftUI')
UF.units = {}
UF.allUnits = {}
UF:UpdateColors()

-- Runs fn with UF:UpdateUnitFrame watched: returns, for each call, the frame
-- and what it was then: whether oUF had made its active elements (init) and
-- enabled its health bar (health), and its unit.
local function watch_updates(fn)
	local seen = {}
	local real = UF.UpdateUnitFrame
	UF.UpdateUnitFrame = function(self, frame, ...)
		seen[#seen + 1] = {
			frame = frame,
			init = ouf.IsInitialized(frame),
			health = frame:IsElementEnabled('Health'),
			unit = frame.__unit,
		}
		return real(self, frame, ...)
	end
	local ok, err = pcall(fn)
	UF.UpdateUnitFrame = real
	assert(ok, err)
	return seen
end

-- A party header, as far as oUF and UF.ConstructUnit read its attributes:
-- showParty, from which oUF guesses its buttons' unit, and base_unit.
local header = CreateFrame('Frame', 'SaftUI_Party', UIParent)
header:SetAttribute('showParty', true)
header:SetAttribute('base_unit', 'party')

local count = 0
local function party_button()
	count = count + 1
	return ouf:SpawnGroupButton(header, 'party' .. count, 'SaftUI_PartyUnitButton' .. count)
end

test('a party button is updated once, after oUF has made its active elements', function()
	local seen = watch_updates(party_button)
	eq(#seen, 1, 'once')
	local first = seen[1] or {}
	eq(first.init, true, 'after init')
	eq(first.health, true, 'with its health bar enabled')
	eq(first.unit, 'party', "the unit oUF guessed from the header's attributes")
	eq(first.frame and first.frame.__unit, 'party1', 'its own unit arrives through its unit attribute')
end)

test('a party button made in combat is updated again once combat ends, and sized then', function()
	local reference = party_button()
	check(reference:GetWidth() > 0, 'a button made out of combat is sized')
	local button
	stub.in_combat = true
	local seen = watch_updates(function() button = party_button() end)
	eq(#seen, 1, 'updated at once, in combat')
	check(button:GetWidth() ~= reference:GetWidth(), 'but not sized: a unit frame is secure')
	stub.in_combat = false
	seen = watch_updates(function() stub.fire_event('PLAYER_REGEN_ENABLED') end)
	eq(#seen, 1, 'updated again when combat ends')
	eq(seen[1] and seen[1].frame, button, 'that button')
	eq(button:GetWidth(), reference:GetWidth(), 'sized then')
	eq(button:GetHeight(), reference:GetHeight(), 'height too')
end)

test('OnEnable registers UF.InitUnit before it spawns anything', function()
	local body = read_saftui_source('SaftUI-Unitframes/unitframes.lua'):match('function UF:OnEnable%(%)(.-)\nend')
	local registered = body:find('RegisterInitCallback(UF.InitUnit)', 1, true)
	check(registered and registered < body:find('Spawn', 1, true), 'registered first')
end)

test('a single unit is not updated by the init callback: OnEnable places it', function()
	local seen = watch_updates(function() ouf:Spawn('player', 'SaftUI_Player') end)
	eq(#seen, 0, 'no update')
	stub.in_combat = true
	seen = watch_updates(function() ouf:Spawn('pettarget', 'SaftUI_PetTarget') end)
	stub.in_combat = false
	eq(#seen, 0, 'nor one spawned in combat')
	seen = watch_updates(function() stub.fire_event('PLAYER_REGEN_ENABLED') end)
	eq(#seen, 0, 'nor after combat')
end)

test("the stand-in's EnableElement errors before init, as oUF's does", function()
	local early = fixture.new()
	early:RegisterStyle('Early', function(self)
		self.Health = CreateFrame('StatusBar', nil, self)
		self:EnableElement('Health')
	end)
	local ok, err = pcall(early.Spawn, early, 'player', 'EarlyPlayer')
	eq(ok, false, 'the spawn errors')
	check(tostring(err):find('attempt to index') and tostring(err):find('a nil value'), 'attempt to index a nil value: ' .. tostring(err))
end)

test('a party button gets oUF\'s range fade, with its config\'s alphas', function()
	local button = party_button()
	eq(button:IsElementEnabled('Range'), true, 'enabled at init')
	eq(button.Range.insideAlpha, P.party.range_alpha.inside, 'inside')
	eq(button.Range.outsideAlpha, P.party.range_alpha.outside, 'outside')
end)

test("a party button's aura areas follow their config after oUF turns them on", function()
	local enable = P.party.buffs.enable
	P.party.buffs.enable = false
	local ok, button = pcall(party_button)
	P.party.buffs.enable = enable
	assert(ok, button)
	eq(button:IsElementEnabled('Auras'), true, 'the aura element is enabled')
	eq(button.Buffs.enabled, false, 'buffs off, as configured')
	eq(button.Debuffs.enabled, P.party.debuffs.enable and true or false, 'debuffs as configured')
end)

-- Replaces a bar's two setters with ones that note their calls.
local function spy_setters(bar)
	local got = {}
	bar.SetColorTapping = function(_, state, forced) got[#got + 1] = { 'tapping', state, forced } end
	bar.SetColorReaction = function(_, state, forced) got[#got + 1] = { 'reaction', state, forced } end
	return got
end

local function same_calls(got, expected, what)
	eq(#got, #expected, what .. ': number of calls')
	for i, call in ipairs(expected) do
		local g = got[i] or {}
		eq(g[1], call[1], what .. ' call ' .. i)
		eq(g[2], call[2], what .. ' call ' .. i .. ' state')
		eq(g[3], call[3], what .. ' call ' .. i .. ' forced')
	end
end

test("health and power colour flags go through oUF's setters once enabled, so their events register", function()
	local frame = ouf:Spawn('target', 'SaftUI_Target')

	local got = spy_setters(frame.Health)
	UF.elements.Health.UpdateConfig(frame, 'Health')
	same_calls(got, {
		{ 'tapping', P.target.health.colorTapping, true },
		{ 'reaction', P.target.health.colorReaction, true },
	}, 'health')

	got = spy_setters(frame.Power)
	UF.elements.Power.UpdateConfig(frame, 'Power')
	same_calls(got, {
		{ 'tapping', P.target.power.colorTapping, true },
		{ 'reaction', P.target.power.colorReaction, true },
	}, 'power')
end)

test('a unit frame registers UNIT_FACTION from its first update, and drops it with both flags off', function()
	local frame = ouf:Spawn('focus', 'SaftUI_Focus')
	-- oUF enabled the bars before any config was applied: no flag was on then.
	eq(frame:IsEventRegistered('UNIT_FACTION'), false, 'not at spawn')
	check(P.focus.health.colorTapping or P.focus.health.colorReaction, "focus's health has a faction flag on by default")
	UF:UpdateUnitFrame(frame)
	eq(frame:IsEventRegistered('UNIT_FACTION'), true, 'registered by the update')

	local health, power = P.focus.health, P.focus.power
	local ht, hr, pt, pr = health.colorTapping, health.colorReaction, power.colorTapping, power.colorReaction
	health.colorTapping, health.colorReaction, power.colorTapping, power.colorReaction = false, false, false, false
	local ok, err = pcall(UF.UpdateUnitFrame, UF, frame)
	health.colorTapping, health.colorReaction, power.colorTapping, power.colorReaction = ht, hr, pt, pr
	assert(ok, err)
	eq(frame:IsEventRegistered('UNIT_FACTION'), false, 'dropped with every flag off')
	eq(frame.Health.colorTapping, false, 'the flag itself follows')
end)

test("a party button's bars register UNIT_FACTION, though oUF enabled them before its first update", function()
	local button = party_button()
	eq(button:IsEventRegistered('UNIT_FACTION'),
		(P.party.health.colorTapping or P.party.health.colorReaction or P.party.power.colorTapping or P.party.power.colorReaction) and true or false,
		'as the config has it')
	eq(button.Health.colorReaction, P.party.health.colorReaction, 'the flag is set')
end)

test('before oUF enables a bar, the flags are plain fields', function()
	local early = fixture.new()
	local health, power
	early:RegisterStyle('Early', function(self, unit)
		UF.ConstructUnit(self, unit)
		UF.elements.Health.UpdateConfig(self, 'Health')
		UF.elements.Power.UpdateConfig(self, 'Power')
		health, power = {}, {}
		for _, key in ipairs({ 'colorTapping', 'colorReaction' }) do
			health[key], power[key] = self.Health[key], self.Power[key]
		end
		check(self.Health.SetColorTapping == nil, 'no setter before oUF enables the bar')
	end)
	early:Spawn('pet', 'EarlyPet')
	eq(health.colorTapping, P.pet.health.colorTapping, 'health tapping')
	eq(health.colorReaction, P.pet.health.colorReaction, 'health reaction')
	eq(power.colorTapping, P.pet.power.colorTapping, 'power tapping')
	eq(power.colorReaction, P.pet.power.colorReaction, 'power reaction')
end)
