-- SaftUI-Misc/experience.lua: the XP bar's frame levels (backdrop below the
-- rested part below the fill) and the Experience and Rested color options.
-- Migrated from the xpsim harness. The config is Core's real defaults, and
-- the frames come from Core's real helpers (st:SetBackdrop and the rest).
load_core_helpers()
-- Blizzard's minimap, which the bar's default position anchors to (the profile
-- has Core's real defaults).
CreateFrame('Frame', 'Minimap', UIParent)
for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
	load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua') -- EditMode/load.xml's order; the bar registers a mover
end
load_saftui('SaftUI-Misc/experience.lua')

local st = SaftUI
local XP = st:GetModule('Experience')
XP:Enable()
local exp = XP.bars.experience
local profile = st.config.profile

test('frame levels: backdrop 3, rested 4, fill 5', function()
	eq(exp.backdrop:GetFrameLevel(), 3, 'backdrop at 3')
	eq(exp.rested:GetFrameLevel(), 4, 'rested at 4')
	eq(exp:GetFrameLevel(), 5, 'xp bar at 5')
	check(exp.backdrop:GetFrameLevel() < exp.rested:GetFrameLevel() and exp.rested:GetFrameLevel() < exp:GetFrameLevel(), 'backdrop < rested < fill')
end)

test('the levels hold on a second UpdateConfig, and the rested alpha comes from config', function()
	XP:UpdateConfig()
	check(exp.backdrop:GetFrameLevel() == 3 and exp.rested:GetFrameLevel() == 4 and exp:GetFrameLevel() == 5, 'levels hold on a second UpdateConfig')
	eq(exp.rested:GetAlpha(), 0.4, 'rested alpha from config')
end)

local args = XP:GetConfigTable().args.general.args

test('the Experience and Rested colors are color options that read the profile', function()
	check(args.normal_color.type == 'color' and args.rested_color.type == 'color', 'two color options')
	local r, g, b = args.rested_color.get()
	check(r == .3 and g == .6 and b == .8, 'rested get')
end)

test('setting the rested color writes the profile and recolors the fill at once', function()
	stub.rested_xp = 300
	XP:Update()
	args.rested_color.set(nil, 1, 0, 0)
	check(profile.colors.experience.rested.r == 1, 'rested set writes the profile')
	local r, g = exp:GetStatusBarColor()
	check(r == 1 and g == 0, 'rested fill recolored at once (rested xp present)')
end)

test('without rested experience the normal color is used', function()
	args.normal_color.set(nil, 0, 1, 0)
	stub.rested_xp = nil
	XP:Update()
	local r, g = exp:GetStatusBarColor()
	check(r == 0 and g == 1, 'normal color used without rest')
end)
