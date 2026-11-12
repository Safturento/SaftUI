-- The swing timer skin (SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua) waits for
-- Blizzard_SwingTimer only on a client that has that addon: Forever does,
-- retail has none (checked in Blizzard's source, both clients), so there
-- nothing may be registered for ADDON_LOADED.
--
-- Real: Misc's config.lua, Skinning/skinning.lua and the skin module;
-- SkinFrames is counted rather than run (the bars' drawing is
-- tests/misc/theme_test.lua's).
load_core_helpers()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_saftui('SaftUI-Misc/Skinning/skinning.lua')
load_saftui('SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua')

local st = SaftUI
local SK = st:GetModule('Skinning')
local ST = SK:GetModule('Blizzard_SwingTimer')

local skins = 0
function ST:SkinFrames() skins = skins + 1 end

-- OnEnable again, as a fresh start (the shell enables a module once).
local function enable()
	skins = 0
	ST:UnregisterEvent('ADDON_LOADED')
	ST:OnEnable()
	eq(#take_errors(), 0, 'no errors')
end

test('a client with no Blizzard_SwingTimer registers nothing', function()
	stub.installed_addons.Blizzard_SwingTimer = nil
	enable()
	stub.fire_event('ADDON_LOADED', 'Blizzard_SwingTimer')
	stub.fire_event('ADDON_LOADED', 'SomeOtherAddon')
	eq(skins, 0, 'no ADDON_LOADED reaches the module')
end)

test('Blizzard_SwingTimer not loaded yet: the bars are skinned when it loads', function()
	stub.installed_addons.Blizzard_SwingTimer = true
	enable()
	eq(skins, 0, 'nothing to skin yet')
	stub.fire_event('ADDON_LOADED', 'SomeOtherAddon')
	eq(skins, 0, "another addon's load skins nothing")
	stub.fire_event('ADDON_LOADED', 'Blizzard_SwingTimer')
	eq(skins, 1, 'skinned when Blizzard_SwingTimer loads')
	stub.fire_event('ADDON_LOADED', 'Blizzard_SwingTimer')
	eq(skins, 1, 'and the wait is over')
end)

test('the bars already there are skinned at once', function()
	stub.installed_addons.Blizzard_SwingTimer = true
	local bar = CreateFrame('Frame', 'SwingTimerMainHandFrame', UIParent)
	enable()
	eq(skins, 1, 'skinned on enable')
	stub.fire_event('ADDON_LOADED', 'Blizzard_SwingTimer')
	eq(skins, 1, 'and nothing is waited for')
	_G.SwingTimerMainHandFrame = nil
end)
