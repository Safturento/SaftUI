-- The Spy skin (SaftUI-Misc/Skinning/addons/spy.lua), its toggle and setup:
--   - it installs when Spy loads after SaftUI (ADDON_LOADED 'Spy') and when Spy is
--     already loaded, and the main window gets a SaftUI panel;
--   - Skinning -> Spy off, or a Blizzard Theme, leaves Spy alone: no panel, no hook;
--   - a piece Spy's version lacks (opts.renamed) is skipped with no error;
--   - nothing is written onto a Spy frame: every frame of the fixture is locked
--     (lib/locked_widget.lua), so a field or a replaced script fails.
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and addons/spy.lua, Core's
-- helpers and the theme engine. Spy is fixtures/spy_world.lua.
local SpyFix = load_test_file('misc/fixtures/spy_world.lua')
local T = load_test_file('lib/theme_helpers.lua')

local st, SK, SP

-- A fresh world with Skinning's files and Spy's skin module loaded. Spy itself is
-- made by the case (SpyFix.make), and the modules enabled by enable(), before or
-- after it as the case needs: the game enables SaftUI's modules at login, Spy
-- loads before (already loaded) or after (ADDON_LOADED).
local function world(opts)
	opts = opts or {}
	st = T.client('forever')
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	if opts.theme then st.config.profile.skinning.theme = opts.theme end
	if opts.off then st.config.profile.skinning.spy = false end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/spy.lua')
	SK = st:GetModule('Skinning')
	SP = SK:GetModule('Spy')
end

local function enable()
	SK:Enable() -- and its submodules, Spy's skin among them
end

-- The SaftUI backdrop frame behind frame: a child of it that Spy didn't make.
local function panel_of(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.SetBackdrop and not SpyFix.is_spy(child) then return child end
	end
end

test('installs when Spy loads after SaftUI', function()
	world()
	enable()
	SpyFix.make()
	check(panel_of(Spy.MainWindow) == nil, 'nothing drawn before Spy has loaded')
	stub.fire_event('ADDON_LOADED', 'Spy')
	check(panel_of(Spy.MainWindow), 'the main window wears a SaftUI panel')
end)

test('ignores another addon loading', function()
	world()
	enable()
	SpyFix.make()
	stub.fire_event('ADDON_LOADED', 'SomethingElse')
	check(panel_of(Spy.MainWindow) == nil, 'not Spy: nothing drawn')
end)

test('installs when Spy is already loaded', function()
	world()
	SpyFix.make()
	enable()
	check(panel_of(Spy.MainWindow), 'the main window wears a SaftUI panel')
end)

test('a window Spy makes after the skin is set up is skinned', function()
	world()
	enable()
	SpyFix.make({ noWindow = true })
	stub.fire_event('ADDON_LOADED', 'Spy')
	Spy:CreateMainWindow()
	check(panel_of(Spy.MainWindow), 'the window made later wears a panel')
end)

test('toggle off leaves Spy alone', function()
	world({ off = true })
	SpyFix.make()
	local create = Spy.CreateMainWindow
	local kos = Spy.CreateKoSButton
	enable()
	stub.fire_event('ADDON_LOADED', 'Spy')
	check(panel_of(Spy.MainWindow) == nil, 'no panel')
	check(Spy.CreateMainWindow == create and Spy.CreateKoSButton == kos, 'no hook on Spy')
end)

test('a Blizzard Theme leaves Spy alone', function()
	world({ theme = 'blizzard' })
	SpyFix.make()
	local create = Spy.CreateMainWindow
	enable()
	stub.fire_event('ADDON_LOADED', 'Spy')
	check(panel_of(Spy.MainWindow) == nil, 'no panel')
	check(Spy.CreateMainWindow == create, 'no hook on Spy')
end)

test('missing pieces do not error', function()
	world()
	SpyFix.make({ renamed = true, noStats = true })
	enable()
	stub.fire_event('ADDON_LOADED', 'Spy')
	eq(#take_errors(), 0, 'no error reported')
	check(panel_of(Spy.MainWindow), 'what exists is still skinned')

	world()
	SpyFix.make({ noWindow = true, noStats = true })
	Spy.CreateMainWindow, Spy.CreateKoSButton = nil, nil -- a Spy without the two functions
	enable()
	eq(#take_errors(), 0, 'no hook target, no error')

	world()
	enable()
	stub.fire_event('ADDON_LOADED', 'Spy') -- Spy's global is not there at all
	eq(#take_errors(), 0, 'no Spy, no error')
end)

test('writes no fields onto Spy', function()
	world()
	enable()
	SpyFix.make({ noWindow = true }) -- every Spy frame is locked: a field or a SetScript from the skin raises
	stub.fire_event('ADDON_LOADED', 'Spy')
	Spy:CreateMainWindow()
	Spy:CreateKoSButton()
	Spy:CreateRow(11)
	Spy:ApplyBorderStyle()
	SK:UpdateConfig()
	eq(#take_errors(), 0, 'no error reported')
end)

test('the Skinning page has the toggle, on by default', function()
	world()
	enable()
	eq(st.config.profile.skinning.spy, true, 'default on')
	local args = SK:GetConfigTable().args.general.args
	check(args.spy and args.spy.type == 'toggle' and args.spy.order > args.color_picker.order, 'a toggle after the color picker')
end)

test('a theme change draws the panel again', function()
	world()
	SpyFix.make()
	enable()
	local panel = panel_of(Spy.MainWindow)
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	eq(panel_of(Spy.MainWindow), panel, 'the same panel, drawn again')
	eq(#take_errors(), 0, 'no error reported')
end)
