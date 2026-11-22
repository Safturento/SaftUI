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

test('a theme change draws the panel again, in the new theme', function()
	world()
	SpyFix.make()
	enable()
	local panel = panel_of(Spy.MainWindow)
	local before = st:DrawnTheme(panel)
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	eq(panel_of(Spy.MainWindow), panel, 'the same panel, drawn again')
	eq(st:DrawnTheme(panel), 'thin', 'drawn in the theme the page now has')
	check(before ~= 'thin', 'which it was not before')
	eq(st:DrawnKind(panel), 'panel', 'as a panel')
	eq(#take_errors(), 0, 'no error reported')
end)

test('a row border is redrawn as a control, not a panel', function()
	world()
	SpyFix.make()
	enable()
	local bar = Spy.MainWindow.Rows[1].StatusBar
	local border = panel_of(bar)
	eq(st:DrawnKind(border), 'control', 'a control to begin with')
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	eq(st:DrawnKind(border), 'control', 'still a control')
	eq(st:DrawnTheme(border), 'thin', 'in the new theme')
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
	for _, call in ipairs(SpyFix.geometry_calls) do
		check(call.from_spy == true, call.method .. ' on the window or a row came from Spy')
	end
	stub.in_combat = false
end)

test('the Skinning font applies live', function()
	world()
	SpyFix.make()
	enable()
	local row = Spy.MainWindow.Rows[1]
	local before = row.LeftText:GetFont()
	st.config.profile.skinning.font = 'heading'
	SK:UpdateConfig()
	local want = st:FontValues('heading')
	eq(row.LeftText:GetFont(), want, 'the row text wears the new face')
	check(before ~= want, 'which it did not before')
	eq(#take_errors(), 0, 'no error reported')
end)

test('SaftUI\'s face keeps the other alphabets of Spy\'s font family', function()
	world()
	SpyFix.make()
	enable()
	local row = Spy.MainWindow.Rows[1]
	Spy:SetFontSize(row.LeftText, 13)
	eq(({ row.LeftText:GetFont() })[1], (st:FontValues(st.config.profile.skinning.font)), 'roman: SaftUI\'s face')
	eq(({ row.LeftText:GetFont() })[2], 13, 'at Spy\'s size')
	local russian = row.LeftText:GetFontObject():GetFontObjectForAlphabet('russian')
	eq((russian:GetFont()), [[Fonts\FRIZQT___CYR.TTF]], 'Cyrillic keeps its file')
	eq(select(2, russian:GetFont()), 13, 'at the same size')
	st.config.profile.skinning.font = 'pixel'
	SK:UpdateConfig()
	local again = row.LeftText:GetFontObject():GetFontObjectForAlphabet('russian')
	eq((again:GetFont()), [[Fonts\FRIZQT___CYR.TTF]], 'and after the face changes')
end)

test('without CreateFontFamily the face is set with SetFont', function()
	world()
	SpyFix.make({ noFamily = true })
	enable()
	local row = Spy.MainWindow.Rows[1]
	Spy:SetFontSize(row.LeftText, 13)
	eq(({ row.LeftText:GetFont() })[1], (st:FontValues(st.config.profile.skinning.font)), 'SaftUI\'s face')
	eq(({ row.LeftText:GetFont() })[2], 13, 'Spy\'s size')
	eq(#take_errors(), 0, 'no error reported')
end)

test('the resize grips are glyphs drawn by the states', function()
	world()
	SpyFix.make({ noWindow = true })
	local shapes = {}
	enable()
	local real = st.AddStates
	st.AddStates = function(self, frame, shape, opts)
		shapes[frame] = shape
		return real(self, frame, shape, opts)
	end
	stub.fire_event('ADDON_LOADED', 'Spy')
	Spy:CreateMainWindow()
	for _, key in ipairs({ 'DragBottomRight', 'DragBottomLeft', 'DragTopRight', 'DragTopLeft' }) do
		eq(shapes[Spy.MainWindow[key]], 'glyph', key)
	end
	eq(#take_errors(), 0, 'no error reported')
end)

test('InvertSpy: the panel runs from the window top to the title bar, the line above it', function()
	world()
	SpyFix.make({ invert = true })
	enable()
	local window = Spy.MainWindow
	local panel = panel_of(window)
	local points = {}
	for i = 1, panel:GetNumPoints() do
		local point, rel, relpoint, x, y = panel:GetPoint(i)
		points[point] = { rel, relpoint, x, y }
	end
	eq(points.TOPLEFT[1], window, 'from the window\'s top')
	eq(points.TOPLEFT[4], -34, 'where Spy\'s rows and inverted background start, 34 down')
	eq(points.BOTTOMRIGHT[1], window.TitleBar, 'to the title bar\'s bottom')
	local line
	for _, region in ipairs({ panel:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:GetNumPoints() > 0 then
			local point, rel, relpoint = region:GetPoint(1)
			if rel == window.TitleBar then line = { point, relpoint } end
		end
	end
	check(line, 'a divider anchored to the title bar')
	eq(line[1], 'BOTTOMLEFT', 'above the title bar')
	eq(line[2], 'TOPLEFT', 'on its top edge')
	eq(#take_errors(), 0, 'no error reported')
end)

test('a class atlas set after Spy\'s coordinates keeps the crop', function()
	world()
	SpyFix.make()
	enable()
	Spy:SetBar(1, 'Name', 'Mage', 100, 'class', 'MAGE')
	eq((Spy.MainWindow.Rows[1].ClassIcon:GetTexCoord()), st.config.profile.misc.icon_trim, 'cropped after SetAtlas reset it')
end)

test('a font call that errors does not leave the hook off', function()
	world()
	SpyFix.make({ noFamily = true })
	enable()
	local row = Spy.MainWindow.Rows[1]
	local face = st:FontValues(st.config.profile.skinning.font)
	stub.refused_fonts[face] = 'error'
	-- Spy's own SetFont is on another file and works; the skin's, on SaftUI's face, raises
	local ok = pcall(row.LeftText.SetFont, row.LeftText, [[Fonts\FRIZQT__.TTF]], 15, '')
	check(not ok, 'the skin\'s own font call raised')
	stub.refused_fonts[face] = nil
	row.LeftText:SetFont([[Fonts\FRIZQT__.TTF]], 14, '')
	eq(({ row.LeftText:GetFont() })[1], face, 'the hook still puts SaftUI\'s face on the next size')
	eq(({ row.LeftText:GetFont() })[2], 14, 'at that size')
end)

test('a toggled InvertSpy without a reload leaves the panel on the real bar', function()
	world()
	SpyFix.make()
	enable()
	local window = Spy.MainWindow
	local panel = panel_of(window)
	Spy.db.profile.InvertSpy = true -- the option only writes the db; the bar is where it was made
	Spy:ManageBarsDisplayed()
	local points = {}
	for i = 1, panel:GetNumPoints() do
		local point, rel = panel:GetPoint(i)
		points[point] = rel
	end
	eq(points.TOPLEFT, window.TitleBar, 'still from the title bar at the top')
	eq(points.BOTTOMRIGHT, window, 'to the window bottom')
end)

test('refresh callbacks: OnConfig and OnColors run after the skin\'s own redraw, with (group, key)', function()
	world()
	SpyFix.make()
	enable()
	local seen = {}
	SP.lib.OnConfig(function() seen[#seen + 1] = 'config' end)
	SP.lib.OnColors(function(group, key) seen[#seen + 1] = 'colors:' .. tostring(group) .. ':' .. tostring(key) end)
	SP:UpdateConfig()
	SP:OnColorsChanged('text', 'danger')
	eq(table.concat(seen, ','), 'config,colors:text:danger')
	eq(#take_errors(), 0, 'no error reported')
end)

test('refresh callbacks: one that errors is reported and the others still run', function()
	world()
	SpyFix.make()
	enable()
	local ran = {}
	SP.lib.OnConfig(function() error('config boom', 0) end)
	SP.lib.OnConfig(function() ran.config = true end)
	SP.lib.OnColors(function() error('colors boom', 0) end)
	SP.lib.OnColors(function() ran.colors = true end)
	SP:UpdateConfig()
	SP:OnColorsChanged('text')
	check(ran.config and ran.colors, 'the callbacks after the failing ones ran')
	local errors = take_errors()
	eq(#errors, 2, 'each failure was handed to the error handler')
	check(errors[1]:find('config boom', 1, true) and errors[2]:find('colors boom', 1, true), 'naming them')
end)

test('refresh callbacks: nothing runs while the skin is not installed', function()
	world({ off = true })
	SpyFix.make()
	enable()
	local ran = false
	SP.lib.OnConfig(function() ran = true end)
	SP.lib.OnColors(function() ran = true end)
	SP:UpdateConfig()
	SP:OnColorsChanged()
	check(not ran, 'not installed: no callback')
end)
