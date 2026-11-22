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
	for _, call in ipairs(SpyFix.geometry_calls) do
		check(call.from_spy == true, call.method .. ' on the window or a row came from Spy, not the skin')
	end
end)

test('the Skinning page has the toggle, on by default', function()
	world()
	enable()
	eq(st.config.profile.skinning.spy, true, 'default on')
	local args = SK:GetConfigTable().args.general.args
	check(args.spy and args.spy.type == 'toggle' and args.spy.order > args.color_picker.order, 'a toggle after the color picker')
end)

-- Every call the skin made on Spy's window or a row's geometry (the window is
-- secure): none but Spy's own may be there.
local function skin_geometry()
	local bad = {}
	for _, call in ipairs(SpyFix.geometry_calls) do
		if not call.from_spy then bad[#bad + 1] = call.method end
	end
	return bad
end

-- Spies on st:SetBackdropIn: the (frame, theme, background, kind) each call drew.
local function watch_draws()
	local real, calls = st.SetBackdropIn, {}
	st.SetBackdropIn = function(self, backdrops, frame, theme, background, kind)
		calls[#calls + 1] = { frame = frame, theme = theme, background = background, kind = kind }
		return real(self, backdrops, frame, theme, background, kind)
	end
	return calls
end

local function draws_of(calls, frame)
	local out = {}
	for _, call in ipairs(calls) do
		if call.frame == frame then out[#out + 1] = call end
	end
	return out
end

test('a theme change draws the panel again, in the new theme', function()
	world()
	SpyFix.make()
	enable()
	local panel = panel_of(Spy.MainWindow)
	local calls = watch_draws()
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	eq(panel_of(Spy.MainWindow), panel, 'the same panel, drawn again')
	local drawn = draws_of(calls, Spy.MainWindow)
	check(#drawn >= 1, 'the window panel was drawn again')
	eq(drawn[#drawn].theme, 'thin', 'in the theme the page now has')
	eq(drawn[#drawn].kind, 'panel', 'as a panel')
	eq(#take_errors(), 0, 'no error reported')
end)

test('a row border is redrawn as a control, not a panel', function()
	world()
	SpyFix.make()
	enable()
	local bar = Spy.MainWindow.Rows[1].StatusBar
	local calls = watch_draws()
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	local drawn = draws_of(calls, bar)
	check(#drawn >= 1, 'the row border was drawn again')
	eq(drawn[#drawn].kind, 'control', 'still a control')
	eq(drawn[#drawn].theme, 'thin', 'in the new theme')
end)

---------------------------------------------------------------- the Nearby window

test('main panel covers the title bar and the rows', function()
	world()
	SpyFix.make()
	enable()
	local window = Spy.MainWindow
	local panel = panel_of(window)
	check(panel, 'a panel')
	local points = {}
	for i = 1, panel:GetNumPoints() do
		local point, rel, relpoint = panel:GetPoint(i)
		points[point] = { rel, relpoint }
	end
	eq(points.TOPLEFT[1], window.TitleBar, 'from the title bar')
	eq(points.BOTTOMRIGHT[1], window, 'to the window bottom')
	eq(window.Background:GetAlpha(), 0, 'Spy\'s own background hidden')
end)

test('the title bar backdrop is cleared', function()
	world()
	SpyFix.make()
	enable()
	check(Spy.MainWindow.TitleBar.backdropInfo == nil, 'no backdrop on the title bar')
end)

test('Spy putting its borders back is undone', function()
	world()
	SpyFix.make({ border = 'forever' })
	enable()
	Spy:ApplyBorderStyle()
	local window = Spy.MainWindow
	check(window.ForeverBorder, 'Spy made its gold border')
	check(not window.ForeverBorder:IsShown(), 'the window\'s gold border is hidden again')
	check(window.TitleBar.backdropInfo == nil, 'the title bar has no backdrop again')
	Spy.db.profile.WindowBorder = 'classic'
	Spy:ApplyBorderStyle()
	check(window.TitleBar.backdropInfo == nil, 'nor with the classic border')
	Spy:ManageBarsDisplayed()
	check(window.TitleBar.backdropInfo == nil, 'nor after the rows are managed')
	eq(#take_errors(), 0, 'no error reported')
end)

local ICONS = { CloseButton = 'x', LeftButton = 'chevronLeft', RightButton = 'chevronRight', ClearButton = 'eraser',
	StatsButton = 'chartNoAxesColumn' }

test('the buttons wear SaftUI icons in Text > Muted', function()
	world()
	SpyFix.make()
	enable()
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	for key, icon in pairs(ICONS) do
		local button = Spy.MainWindow[key]
		eq(button:GetNormalTexture():GetTexture(), st.icons[icon], key .. ' normal')
		eq(button:GetPushedTexture():GetTexture(), st.icons[icon], key .. ' pushed')
		local r, g, b = button:GetNormalTexture():GetVertexColor()
		check(r == mr and g == mg and b == mb, key .. ' tinted muted')
	end
	local count = Spy.MainWindow.CountButton
	eq(count:GetAlpha(), 0, 'the count button is left at alpha 0')
	eq(count:GetNormalTexture():GetTexture(), [[Interface\AddOns\Spy\Textures\button-crosshairs.tga]], 'and untouched')
	local grip = Spy.MainWindow.DragBottomRight
	eq(grip:GetNormalTexture():GetTexture(), st.textures.cornerbr, 'the grips wear SaftUI\'s corner')
end)

test('button hover goes through the states', function()
	world()
	SpyFix.make({ noWindow = true })
	local added = {}
	enable()
	local real = st.AddStates
	st.AddStates = function(self, frame, shape, opts)
		added[frame] = shape
		return real(self, frame, shape, opts)
	end
	stub.fire_event('ADDON_LOADED', 'Spy')
	Spy:CreateMainWindow()
	for key in pairs(ICONS) do
		eq(added[Spy.MainWindow[key]], 'icon', key .. ' has states')
	end
	eq(#take_errors(), 0, 'no error reported')
end)

test('rows are flat with a border and keep Spy\'s color', function()
	world()
	SpyFix.make()
	enable()
	local row = Spy.MainWindow.Rows[1]
	eq(row.StatusBar:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, 'the flat texture')
	check(panel_of(row.StatusBar), 'a border drawn on the bar')
	RAID_CLASS_COLORS = RAID_CLASS_COLORS or {}
	RAID_CLASS_COLORS.MAGE = RAID_CLASS_COLORS.MAGE or { r = 0.25, g = 0.78, b = 0.92 }
	Spy:SetBar(1, 'Name', 'Mage', 100, 'class', 'MAGE')
	local r, g, b = row.StatusBar:GetStatusBarColor()
	local c = RAID_CLASS_COLORS.MAGE
	check(r == c.r and g == c.g and b == c.b, 'the bar keeps the class color Spy gave it')
	Spy:UpdateBarTextures()
	eq(row.StatusBar:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, 'flat again after Spy\'s UpdateBarTextures')
	Spy:SetBarTextures('Other')
	eq(row.StatusBar:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, 'and after SetBarTextures')
	eq(#take_errors(), 0, 'no error reported')
end)

test('a late row is skinned', function()
	world()
	SpyFix.make()
	enable()
	Spy:CreateRow(11)
	local row = Spy.MainWindow.Rows[11]
	eq(row.StatusBar:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, 'flat')
	check(panel_of(row.StatusBar), 'bordered')
	eq(#take_errors(), 0, 'no error reported')
end)

test('row fonts keep the size Spy asks for', function()
	world()
	SpyFix.make()
	enable()
	local row = Spy.MainWindow.Rows[1]
	Spy:SetFontSize(row.LeftText, 13)
	local face, size, flags = row.LeftText:GetFont()
	local want_face, _, want_flags = st:FontValues(st.config.profile.skinning.font)
	eq(face, want_face, 'SaftUI\'s face')
	eq(size, 13, 'Spy\'s size')
	eq(flags, want_flags, 'SaftUI\'s outline')
	local title_face = st:FontValues(st.config.profile.headers.font)
	eq(({ Spy.MainWindow.Title:GetFont() })[1], title_face, 'the title is in the title font')
	eq(({ Spy.MainWindow.Title:GetFont() })[2], 12, 'at Spy\'s size')
end)

test('the class icon is cropped', function()
	world()
	SpyFix.make()
	enable()
	local row = Spy.MainWindow.Rows[1]
	local trim = st.config.profile.misc.icon_trim
	local l, _, _, _, r = row.ClassIcon:GetTexCoord()
	eq(l, trim, 'the left edge is trimmed')
	eq(r, 1 - trim, 'the right edge is trimmed')
	row.ClassIcon:SetTexCoord(0, 1, 0, 1) -- Spy's own full reset (its class atlas)
	eq((row.ClassIcon:GetTexCoord()), trim, 'put back after Spy resets it')
end)

test('Spy in combat: the skin touches no geometry', function()
	world()
	SpyFix.make()
	enable()
	SpyFix.geometry_calls = {}
	stub.in_combat = true
	Spy.ListAmountDisplayed = 3
	Spy:ManageBarsDisplayed()
	Spy:ResizeMainWindow()
	Spy:SetBar(1, 'Name', 'Mage', 100, 'class', 'MAGE')
	Spy:ApplyBorderStyle()
	Spy:CreateRow(12)
	eq(#take_errors(), 0, 'no error reported')
	eq(table.concat(skin_geometry(), ','), '', 'no geometry call from anywhere but Spy')
	for _, call in ipairs(SpyFix.geometry_calls) do
		check(call.from_spy == true, call.method .. ' on the window or a row came from Spy')
	end
	stub.in_combat = false
end)
