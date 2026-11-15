-- SaftUI-Minimap with SaftUI's themes (SaftUI-Core/theme.lua):
--   - the minimap's default looks as its old template name did;
--   - the Minimap page offers Theme and Background, not Template;
--   - the minimap's panel is drawn as a panel in its Theme and Background, the
--     theme's border outside the map, moved to a new theme's border by the
--     profile update that follows a theme switch, and None draws none;
--   - each micro menu item's panel is a control in SaftUI's theme (a small
--     frame under Thick and Thin), and an item added with Theme None has none.
--     Its Blizzard art is blizzard_look_test.lua's.
--
-- Real: SaftUI-Minimap's minimap.lua, config.lua, micromenu.lua,
-- micromenuart.lua, micromenuitems.lua, micromenuoptions.lua and
-- microbuttons.lua, Core's helpers and the theme engine.
load_core_helpers()
load_editmode()
load_options_widgets()
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
-- Blizzard's minimap: SaftUI sizes and places it, and draws its panel behind it.
CreateFrame('Frame', 'Minimap', UIParent)
load_saftui('SaftUI-Minimap/minimap.lua')
load_saftui('SaftUI-Minimap/config.lua')
apply_defaults()
load_saftui('SaftUI-Minimap/micromenu.lua')
load_saftui('SaftUI-Minimap/micromenuart.lua')
load_saftui('SaftUI-Minimap/micromenuitems.lua')
load_saftui('SaftUI-Minimap/micromenuoptions.lua')
load_saftui('SaftUI-Minimap/microbuttons.lua')

local st = SaftUI
local MM = st:GetModule('Minimap')
st:BindModuleConfig(MM, 'minimap')
local profile = st.config.profile

test('minimap defaults look as they did', function()
	T.check_default(profile.minimap, 'thick', 'minimap') -- base commit 7ec1df8
end)

test('every value row of the Minimap and Micro menu pages has a reset', function()
	local MicroMenu = st:GetModule('MicroMenu')
	st:BindModuleConfig(MicroMenu, 'micromenu')
	MicroMenu.Container = CreateFrame('Frame', nil, UIParent)
	MicroMenu.Container:SetSize(100, 30)
	MicroMenu.Container:SetPoint('CENTER')
	Minimap:SetSize(100, 100)
	Minimap:SetPoint('CENTER')
	local update, updateMicro = MM.UpdateConfig, MicroMenu.UpdateConfig
	function MM:UpdateConfig() end -- the rows' own sets still run; what they apply is not under test
	function MicroMenu:UpdateConfig() end
	st:RegisterConfigMover(Minimap, {
		key = 'minimap', blizzardFrame = true, label = 'Minimap', config = function() return MM.config end,
		apply = function() end, configPath = { 'Minimap', 'general' }, module = 'Minimap',
		defaults = function() return st.defaults.minimap end,
	})
	st:RegisterConfigMover(MicroMenu.Container, {
		key = 'micromenu', label = 'Micro Menu', config = function() return MicroMenu.config end,
		apply = function() end, configPath = { 'MicroMenu', 'general' }, module = 'Minimap',
		defaults = function() return st.defaults.micromenu end,
	})
	local R = load_test_file('lib/reset_walk.lua')
	local ok, err = pcall(function()
		R.check_page({ Minimap = MM:GetConfigTable() }, 'Minimap')
		R.check_page({ MicroMenu = MicroMenu:GetConfigTable() }, 'MicroMenu')
	end)
	MM.UpdateConfig, MicroMenu.UpdateConfig = update, updateMicro
	if not ok then error(err, 0) end

	-- A reset applies on screen: Size's goes through the page's set, which resizes the minimap.
	local root = { Minimap = MM:GetConfigTable() }
	local row = { option = root.Minimap.args.general.args.size, path = { 'Minimap', 'general', 'size' }, type = 'range', key = 'size' }
	profile.minimap.size = 300
	MM:UpdateConfig()
	eq(Minimap:GetWidth(), 300, 'the minimap is 300 wide')
	check(st.OptionsModel.DefaultReset(root, row), 'the reset ran')
	eq(profile.minimap.size, st.defaults.minimap.size, 'Size is back at its default')
	eq(Minimap:GetWidth(), st.defaults.minimap.size, 'and the minimap is resized')
end)

test('each page offers Theme and Background, not Template', function()
	local updates = 0
	local update = MM.UpdateConfig
	function MM:UpdateConfig() updates = updates + 1 end -- counted; run for real below
	T.check_no_old_names(MM:GetConfigTable(), 'Minimap')
	local MicroMenu = st:GetModule('MicroMenu')
	MicroMenu.Container = CreateFrame('Frame', nil, UIParent) -- SaftUI's, made by OnEnable
	eq(MicroMenu:GetConfigTable().name, 'Micro menu', 'sentence case, as the sidebar shows it')
	T.check_no_old_names(MicroMenu:GetConfigTable(), 'Micro menu')
	T.check_theme_page({
		group = MM:GetConfigTable().args.general, where = 'Minimap', config = profile.minimap, path = 'minimap',
		reads = { { 'theme', 'theme' }, { 'background', 'solid' } },
		writes = { { 'theme', 'thin' }, { 'background', 'transparent' } },
	})
	eq(updates, 2, 'each applies at once')
	MM.UpdateConfig = update
	profile.minimap.theme, profile.minimap.background = 'theme', 'solid'
end)

-- The SaftUI panel behind the minimap: the minimap's child with a backdrop drawn.
local function panel()
	for _, child in ipairs({ Minimap:GetChildren() }) do
		if drawn(child) then return child end
	end
end

test("the minimap's panel is a panel in its Theme and Background, the theme's border outside the map", function()
	MM:UpdateConfig()
	local backdrop = panel()
	check(backdrop ~= nil, 'the minimap has a panel')
	eq(drawn(backdrop), 'theme,solid,panel', "the minimap's Theme and Background, as a panel")
	eq(T.inset(backdrop), 2, "Thick's border")
	eq(T.offset(backdrop, 'TOPLEFT'), '-2.00,2.00', '2px outside the map')
	eq(select(4, backdrop:GetBackdropColor()), 1, 'Solid')

	-- A switch to Thin, as st:ThemeChanged runs it: every drawn frame redrawn,
	-- then every module's profile update.
	profile.theme.name = 'thin'
	st:RedrawThemed()
	MM:UpdateConfig()
	eq(T.inset(backdrop), 1, "Thin's border")
	eq(T.offset(backdrop, 'TOPLEFT'), '-1.00,1.00', '1px outside the map')
	profile.theme.name = 'thick'
	st:RedrawThemed()
	MM:UpdateConfig()

	profile.minimap.theme = 'none'
	MM:UpdateConfig()
	eq(backdrop.backdropInfo, nil, 'None draws none')
	profile.minimap.theme = 'theme'
	MM:UpdateConfig()
	eq(T.inset(backdrop), 2, 'and back')
end)

test("a micro menu item's panel is a control in SaftUI's theme, a small frame under Thick, and Theme None has none", function()
	local MicroMenu = st:GetModule('MicroMenu')
	MicroMenu.Container = CreateFrame('Frame', nil, UIParent) -- made by OnEnable
	MicroMenu.Container:SetPoint('TOPLEFT')
	local plain = CreateFrame('Button', nil, UIParent)
	local bare = CreateFrame('Button', nil, UIParent)
	MicroMenu:AddButton(plain)
	MicroMenu:AddButton(bare, { theme = 'none' })
	MicroMenu:UpdateButtons()

	local backdrop
	for _, child in ipairs({ plain:GetChildren() }) do
		if drawn(child) then backdrop = child end
	end
	check(backdrop ~= nil, 'the item has a panel')
	eq(drawn(backdrop), 'theme,theme,control', "SaftUI's theme, as a control: a small frame under Thick")
	eq(T.inset(backdrop), 2, "Thick's border")
	eq(T.offset(backdrop, 'TOPLEFT'), '-2.00,2.00', '2px outside the item')
	eq(select(4, backdrop:GetBackdropColor()), 0.9, "SaftUI's transparent background")
	eq(#{ bare:GetChildren() }, 0, 'an item with Theme None has no panel')
end)

------------------------------------ Blizzard's micro buttons

-- A micro button as Blizzard's MainMenuBarMicroButton template builds it (its
-- XML in Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.xml), as far as
-- microbuttons.lua reads it, hung on a MicroMenu frame: the template's regions
-- in its layers, a normal, pushed and highlight texture, the notification
-- overlay, and textureName. The stub has no SetHighlightAtlas (Button's, which
-- Blizzard's LoadMicroButtonTextures calls), so it's given here as it works:
-- the highlight's atlas and blend mode. The button is locked, so a field the
-- skin writes onto it fails.
local locked = load_test_file('lib/locked_widget.lua')

local function micro_button(index, textureName)
	local menu = _G.MicroMenu
	if not menu then
		menu = CreateFrame('Frame', 'MicroMenu', UIParent)
		function menu:Layout() end -- Blizzard's layout, which the skin hooks
	end
	local button = CreateFrame('Button', nil, menu)
	button.layoutIndex, button.textureName = index, textureName
	button.Background = button:CreateTexture(nil, 'BACKGROUND')
	button.Background:SetAtlas('UI-HUD-MicroMenu-ButtonBG-Up', true)
	button.Background:SetPoint('CENTER')
	button.PushedBackground = button:CreateTexture(nil, 'BACKGROUND')
	button.PushedBackground:SetAtlas('UI-HUD-MicroMenu-ButtonBG-Down', true)
	button.PushedBackground:SetPoint('CENTER')
	button.PushedBackground:Hide()
	button.FlashBorder = button:CreateTexture(nil, 'OVERLAY')
	button.FlashBorder:SetAtlas('UI-HUD-MicroMenu-Highlightalert')
	button.FlashBorder:SetAllPoints(button)
	button.FlashBorder:Hide()
	button.Shadow = button:CreateTexture(nil, 'BORDER')
	button.PushedShadow = button:CreateTexture(nil, 'OVERLAY')
	button.MainMenuBarPerformanceBar = button:CreateTexture(nil, 'ARTWORK')
	button.Emblem = button:CreateTexture(nil, 'ARTWORK')
	button.HighlightEmblem = button:CreateTexture(nil, 'ARTWORK')
	button.NotificationOverlay = CreateFrame('Frame', nil, button)
	button.NotificationOverlay:CreateTexture(nil, 'OVERLAY')
	button:SetNormalTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetPushedTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetHighlightTexture(button:CreateTexture(nil, 'HIGHLIGHT'))
	button.SetHighlightAtlas = function(self, atlas, blend)
		local highlight = self:GetHighlightTexture()
		highlight:SetAtlas(atlas)
		highlight:SetBlendMode(blend or 'BLEND')
	end
	return locked(button, 'Blizzard micro button')
end

test("under Blizzard a micro button shows Blizzard's own art, and today's look again under Thick", function()
	local MicroMenu = st:GetModule('MicroMenu')
	MicroMenu.Container = MicroMenu.Container or CreateFrame('Frame', nil, UIParent)
	MicroMenu.Container:SetPoint('TOPLEFT')
	profile.theme.name = 'thick'
	st:RedrawThemed()
	local button = micro_button(1, 'Questlog')
	profile.colors.text.caution:SetRGB(0.7, 0.7, 0.2) -- not the default, so a flat alert in a color of its own fails
	MicroMenu:SkinBlizzardMicroMenu()
	local panel
	for _, child in ipairs({ button:GetChildren() }) do
		if child ~= button.NotificationOverlay then panel = child end
	end
	check(panel ~= nil, 'the button has a panel of SaftUI')
	local function fades()
		return ('%d,%d,%d,%d'):format(button.Background:GetAlpha(), button.Shadow:GetAlpha(),
			button.PushedShadow:GetAlpha(), button.MainMenuBarPerformanceBar:GetAlpha())
	end

	-- Today's look under Thick: Blizzard's art faded, a flat pushed fill and
	-- alert, the tint on the highlight, and the panel a small frame.
	eq(drawn(button), 'theme,theme,control', "the panel is a control, SaftUI's theme")
	eq(T.inset(panel), 2, 'Thick: drawn as a small frame, its border 2px')
	eq(fades(), '0,0,0,0', 'Thick: Blizzard background, shadows and performance bar faded')
	eq(button.PushedBackground:GetAtlas(), nil, 'Thick: the pushed background is a flat color')
	eq(button.FlashBorder:GetAtlas(), nil, 'Thick: the alert is a flat color')
	do
		local c = stub.state(button.FlashBorder).color_texture or {}
		eq(T.text(c[1] or -1, c[2] or -1, c[3] or -1), T.text(0.7, 0.7, 0.2), "Thick: the flat alert is Text > Caution")
	end
	eq(select(1, button.FlashBorder:GetDrawLayer()), 'BACKGROUND', 'Thick: behind the icon')
	eq(button:GetHighlightTexture():GetAtlas(), nil, "Thick: the highlight isn't Blizzard's atlas")

	-- A switch, as Config:UpdateConfig runs it: every drawn frame redrawn, then
	-- the bar laid out again.
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	MicroMenu:UpdateButtons()
	eq(fades(), '1,1,1,1', "Blizzard: the background, shadows and performance bar show again")
	eq(button.PushedBackground:GetAtlas(), 'UI-HUD-MicroMenu-ButtonBG-Down', "the pushed background is Blizzard's")
	-- Every piece of Blizzard's art is the icons' size, centered on the button,
	-- so none overlaps the next button.
	for name, region in pairs({ Background = button.Background, Shadow = button.Shadow,
			PushedShadow = button.PushedShadow, PushedBackground = button.PushedBackground,
			highlight = button:GetHighlightTexture() }) do
		eq(T.text(region:GetSize()), '22.00,28.00', name .. ' is the size of the icons')
		local point, rel = region:GetPoint(1)
		eq(point .. ',' .. tostring(rel == button) .. ',' .. region:GetNumPoints() .. ',' .. T.offset(region, 'CENTER'),
			'CENTER,true,1,0.00,0.00', name .. ' is centered on the button')
	end
	eq(button.FlashBorder:GetAtlas(), 'UI-HUD-MicroMenu-Highlightalert', "the alert is Blizzard's")
	eq(select(1, button.FlashBorder:GetDrawLayer()), 'OVERLAY', "in Blizzard's layer")
	eq(button:GetHighlightTexture():GetAtlas(), 'UI-HUD-MicroMenu-Questlog-Mouseover', "the highlight is the button's own mouseover art")
	eq(button:GetHighlightTexture():GetBlendMode(), 'BLEND', 'blended')
	eq(T.art(panel) .. T.over(panel), '', 'no art of SaftUI on the button')
	eq(panel.backdropInfo, nil, 'and no fill or line')

	-- Blizzard re-applies its art; the hooked swap leaves the highlight alone.
	button:SetHighlightAtlas('UI-HUD-MicroMenu-Questlog-Mouseover', 'BLEND')
	eq(button:GetHighlightTexture():GetAtlas(), 'UI-HUD-MicroMenu-Questlog-Mouseover', "an atlas swap keeps Blizzard's highlight")
	eq(button:GetHighlightTexture():GetBlendMode(), 'BLEND', 'and its blend')

	profile.theme.name = 'thick'
	st:RedrawThemed()
	MicroMenu:UpdateButtons()
	eq(fades(), '0,0,0,0', "Thick again: Blizzard's art faded")
	eq(button.PushedBackground:GetAtlas(), nil, 'the flat pushed fill is back')
	eq(button.FlashBorder:GetAtlas(), nil, 'and the flat alert')
	eq(select(1, button.FlashBorder:GetDrawLayer()), 'BACKGROUND', 'behind the icon')
	eq(button:GetHighlightTexture():GetAtlas(), nil, 'and the tint on the highlight')
	eq(button:GetHighlightTexture():GetNumPoints(), 2, 'the highlight covers the button again')
	eq(T.inset(panel), 2, 'the panel is a small frame again')
end)

------------------------------------ the Buttons colors' opacity

-- Every Buttons reader here draws its color at its own strength times the
-- color's opacity (st:ColorRGBA('button', key, strength)): a micro button's
-- highlight at 0.4 and its pushed fill at 0.6 (the flat looks), a bar item's
-- highlight and pushed fill, the tracking, queue and expansion buttons'
-- highlights, each at 1. The colors are not the defaults, so a reader that
-- draws the shipped color fails, and the opacity is 100% (its own strength)
-- and then 50% (half).
local BUTTON_COLOR = { normal = { 0.2, 0.7, 0.4 }, hover = { 0.9, 0.2, 0.6 }, pushed = { 0.5, 0.8, 0.1 } }
local function paint_buttons(a)
	for key, rgb in pairs(BUTTON_COLOR) do
		local c = profile.colors.button[key]
		c:SetRGB(unpack(rgb)); c.a = a
	end
end
local function want(key, strength, a) return T.text(BUTTON_COLOR[key][1], BUTTON_COLOR[key][2], BUTTON_COLOR[key][3], strength * a) end
local function filled(texture)
	local c = stub.state(texture).color_texture or { -1, -1, -1, -1 }
	return T.text(c[1], c[2], c[3], c[4])
end

test("a micro button's flat highlight is Hover at 0.4 and its pushed fill Pushed at 0.6, times the opacity", function()
	local MicroMenu = st:GetModule('MicroMenu')
	local button
	for _, child in ipairs({ _G.MicroMenu:GetChildren() }) do
		if child.layoutIndex == 1 then button = child end
	end
	check(button ~= nil, 'the micro button the case above made')
	-- The pushed fill is made when the look changes (StyleArt), the highlight at every layout.
	local function look(name)
		profile.theme.name = name
		st:RedrawThemed()
		MicroMenu:UpdateButtons()
	end
	for _, a in ipairs({ 1, 0.5 }) do
		paint_buttons(a)
		look('blizzard'); look('thick')
		eq(filled(button:GetHighlightTexture()), want('hover', 0.4, a), 'the highlight at ' .. a * 100 .. '%')
		eq(filled(button.PushedBackground), want('pushed', 0.6, a), 'the pushed fill at ' .. a * 100 .. '%')
	end
	paint_buttons(1)
	look('blizzard'); look('thick')
	eq(filled(button:GetHighlightTexture()), '0.90,0.20,0.60,0.40', 'back at 100%: Hover at 0.4, as before')
	eq(filled(button.PushedBackground), '0.50,0.80,0.10,0.60', 'and Pushed at 0.6')
end)

test("a bar item's highlight is Normal and its pushed fill Pushed, each at 1 times the opacity", function()
	local MicroMenu = st:GetModule('MicroMenu')
	for _, a in ipairs({ 1, 0.5 }) do
		paint_buttons(a)
		local item = CreateFrame('Button', nil, UIParent)
		MicroMenu:SkinBarButton(item)
		eq(T.text(item:GetHighlightTexture():GetVertexColor()), want('normal', 1, a), 'the highlight at ' .. a * 100 .. '%')
		eq(T.text(item:GetPushedTexture():GetVertexColor()), want('pushed', 1, a), 'the pushed fill at ' .. a * 100 .. '%')
	end
	paint_buttons(1)
end)

test("the tracking, queue and expansion buttons' highlights are Hover at 1 times the opacity", function()
	local MicroMenu = st:GetModule('MicroMenu')
	load_saftui('SaftUI-Minimap/queuebutton.lua')
	load_saftui('SaftUI-Minimap/expansionbutton.lua')
	local function texture_button()
		local b = CreateFrame('Button', nil, UIParent)
		for _, set in ipairs({ 'SetNormalTexture', 'SetPushedTexture', 'SetHighlightTexture' }) do b[set](b, b:CreateTexture()) end
		return b
	end
	local keep_cluster, keep_queue, keep_expansion = _G.MinimapCluster, _G.QueueStatusButton, _G.ExpansionLandingPageMinimapButton
	local tracking = texture_button()
	tracking.StateTexture, tracking.AddTexture = tracking:CreateTexture(), tracking:CreateTexture()
	tracking.OnButtonStateChanged = function() end
	_G.MinimapCluster = { TrackingFrame = { Button = tracking }, SetEditModeScale = function() end }
	_G.QueueStatusButton = texture_button()
	_G.QueueStatusButton.Eye = CreateFrame('Frame', nil, UIParent)
	_G.ExpansionLandingPageMinimapButton = texture_button()
	for _, a in ipairs({ 1, 0.5 }) do
		paint_buttons(a)
		MicroMenu:SkinTrackingButton()
		eq(T.text(tracking:GetHighlightTexture():GetVertexColor()), want('hover', 1, a), 'the tracking button at ' .. a * 100 .. '%')
		MicroMenu:SkinQueueButton()
		eq(T.text(_G.QueueStatusButton:GetHighlightTexture():GetVertexColor()), want('hover', 1, a), 'the queue button at ' .. a * 100 .. '%')
		MicroMenu:UpdateExpansionLandingPageButton()
		eq(T.text(_G.ExpansionLandingPageMinimapButton:GetHighlightTexture():GetVertexColor()), want('hover', 1, a), 'the expansion button at ' .. a * 100 .. '%')
	end
	paint_buttons(1)
	_G.MinimapCluster, _G.QueueStatusButton, _G.ExpansionLandingPageMinimapButton = keep_cluster, keep_queue, keep_expansion
end)
