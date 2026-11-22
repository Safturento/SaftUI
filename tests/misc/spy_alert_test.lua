-- The Spy skin's alert popup (SaftUI-Misc/Skinning/addons/spy_alert.lua): the panel, its
-- border following each alert's color, the cleared backdrop, the icon and the fonts.
-- World setup as in spy_skin_test.lua, which covers the toggle and setup:
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
	load_saftui('SaftUI-Misc/Skinning/addons/spy_alert.lua')
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


local function rgb(frame)
	local r, g, b, a = frame:GetBackdropBorderColor()
	return { r, g, b, a }
end

local function same(c, want, what)
	check(c[1] == want.r and c[2] == want.g and c[3] == want.b, what)
end

test('alert_panel_drawn', function()
	world()
	SpyFix.make()
	enable()
	local alert = Spy.AlertWindow
	local panel = panel_of(alert)
	check(panel, 'the alert wears a SaftUI panel')
	eq(st:DrawnKind(panel), 'panel', 'as a panel')
	check(alert.backdropInfo == nil, 'Spy\'s backdrop is cleared')
	eq(#take_errors(), 0, 'no error reported')
end)

test('alert_border_follows_each_alert', function()
	world()
	SpyFix.make()
	enable()
	local panel = panel_of(Spy.AlertWindow)
	local colors = Spy.Colors.table.Alert
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	same(rgb(panel), colors['KOS Border'], 'the panel border is the KoS color')
	Spy:ShowAlert('other', 'Al', nil, 'There')
	same(rgb(panel), colors['Other Border'], 'then the next alert\'s color')
	check(Spy.AlertWindow.backdropInfo == nil, 'the backdrop stays cleared')
	-- a redraw (a theme change) keeps the color
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	same(rgb(panel), colors['Other Border'], 'and a redraw keeps it')
	eq(#take_errors(), 0, 'no error reported')
end)

test('alert_border_not_the_apply_border_style_white', function()
	world()
	SpyFix.make()
	enable()
	local panel = panel_of(Spy.AlertWindow)
	Spy:ShowAlert('kosguild', 'Bob', nil, 'Here')
	Spy:ApplyBorderStyle() -- classic puts a white border on the alert
	same(rgb(panel), Spy.Colors.table.Alert['KOS Guild Border'], 'the alert color stays')
end)

test('alert_backdrop_stays_cleared_after_apply_border_style', function()
	world()
	SpyFix.make({ border = 'forever' })
	enable()
	local alert = Spy.AlertWindow
	Spy:ApplyBorderStyle()
	check(alert.backdropInfo == nil, 'cleared after the forever style')
	check(alert.ForeverBorder == nil or not alert.ForeverBorder:IsShown(), 'no gold border')
	Spy.db.profile.WindowBorder = 'classic'
	Spy:ApplyBorderStyle()
	check(alert.backdropInfo == nil, 'cleared after the classic style')
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	check(alert.backdropInfo == nil, 'and after an alert')
	eq(#take_errors(), 0, 'no error reported')
end)

test('alert_icon_framed', function()
	world()
	SpyFix.make()
	enable()
	local icon = Spy.AlertWindow.Icon
	local frame = panel_of(icon)
	check(frame, 'the icon has a SaftUI frame')
	eq(st:DrawnTheme(frame), 'thin', 'a thin border')
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	check(icon.backdropInfo and icon.backdropInfo.bgFile, 'Spy\'s icon is kept')
	st.config.profile.skinning.theme = 'thick'
	SK:UpdateConfig()
	eq(st:DrawnTheme(frame), 'thin', 'still thin after a theme change')
end)

test('alert_icon_cropped', function()
	world()
	stub.backdrop_pieces = true
	SpyFix.make()
	enable()
	local icon = Spy.AlertWindow.Icon
	-- The game's backdrop makes the Center itself, as a field; the locked fixture frame only lets Spy write it.
	rawset(icon, 'Center', icon:CreateTexture(nil, 'BACKGROUND'))
	local trim = st.config.profile.misc.icon_trim
	check(trim > 0, 'the default trim crops')
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	check(icon.Center, 'the icon backdrop has its art')
	eq((icon.Center:GetTexCoord()), trim, 'cropped after Spy sets the icon')
	icon.Center:SetTexCoord(0, 1, 0, 1) -- the backdrop's own reset
	eq((icon.Center:GetTexCoord()), trim, 'cropped again after a reset')
	stub.backdrop_pieces = false
	eq(#take_errors(), 0, 'no error reported')
end)

test('alert_fonts', function()
	world()
	SpyFix.make()
	enable()
	local alert = Spy.AlertWindow
	Spy:SetFontSize(alert.Name, 15)
	Spy:SetFontSize(alert.Location, 11)
	local text_face = st:FontValues(st.config.profile.skinning.font)
	local title_face = st:FontValues(st.config.profile.headers.font)
	eq(({ alert.Title:GetFont() })[1], title_face, 'the title is in the title font')
	eq(({ alert.Title:GetFont() })[2], 12, 'at Spy\'s size')
	eq(({ alert.Name:GetFont() })[1], text_face, 'the name in the Skinning font')
	eq(({ alert.Name:GetFont() })[2], 15, 'at Spy\'s size')
	eq(({ alert.Location:GetFont() })[1], text_face, 'the location in the Skinning font')
	eq(({ alert.Location:GetFont() })[2], 11, 'at Spy\'s size')
end)

test('alert_missing_pieces_do_not_error', function()
	world()
	SpyFix.make({ renamed = true })
	enable()
	check(panel_of(Spy.AlertWindow), 'an alert without an Icon still wears a panel')
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	eq(#take_errors(), 0, 'no error reported')

	world()
	SpyFix.make({ noAlert = true })
	enable()
	Spy:ApplyBorderStyle()
	eq(#take_errors(), 0, 'no alert at all: no error')

	world()
	SpyFix.make()
	Spy.ShowAlert, Spy.Colors.RegisterBorder = nil, nil
	enable()
	eq(#take_errors(), 0, 'no hook target: no error')
	check(panel_of(Spy.AlertWindow), 'the panel is still drawn')
end)

test('alert_nothing_written_on_spy_frames', function()
	world()
	SpyFix.make({ noWindow = true })
	enable()
	stub.fire_event('ADDON_LOADED', 'Spy')
	Spy:CreateMainWindow()
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	Spy:ApplyBorderStyle()
	SK:UpdateConfig()
	eq(#take_errors(), 0, 'every Spy frame is locked: no field written, no script replaced')
end)

test('alert_border_recolored_by_the_config_registry', function()
	world()
	SpyFix.make()
	enable()
	local panel = panel_of(Spy.AlertWindow)
	local colors = Spy.Colors.table.Alert
	Spy:ShowAlert('kos', 'Bob', nil, 'Here')
	panel:SetBackdropBorderColor(0.1, 0.2, 0.3, 1)
	SP:UpdateConfig() -- the registered callback puts the alert's color back
	same(rgb(panel), colors['KOS Border'], 'the border is the alert color again')
	eq(#take_errors(), 0, 'no error reported')
end)
