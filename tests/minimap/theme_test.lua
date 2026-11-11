-- SaftUI-Minimap with SaftUI's themes (SaftUI-Core/theme.lua):
--   - the minimap's default looks as its old template name did;
--   - the Minimap page offers Theme and Background, not Template;
--   - the minimap's panel is drawn as a panel in its Theme and Background, the
--     theme's border outside the map, moved to a new theme's border by the
--     profile update that follows a theme switch, and None draws none;
--   - each micro menu item's panel is a small frame in SaftUI's theme, and an
--     item added with Theme None has none.
--
-- Real: SaftUI-Minimap's minimap.lua, config.lua, micromenu.lua and
-- microbuttons.lua, Core's helpers and the theme engine.
load_core_helpers()
load_test_file('core/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
-- Blizzard's minimap: SaftUI sizes and places it, and draws its panel behind it.
CreateFrame('Frame', 'Minimap', UIParent)
load_saftui('SaftUI-Minimap/minimap.lua')
load_saftui('SaftUI-Minimap/config.lua')
apply_defaults()
load_saftui('SaftUI-Minimap/micromenu.lua')
load_saftui('SaftUI-Minimap/microbuttons.lua')

local st = SaftUI
local MM = st:GetModule('Minimap')
st:BindModuleConfig(MM, 'minimap')
local profile = st.config.profile

test('minimap defaults look as they did', function()
	T.check_default(profile.minimap, 'thick', 'minimap') -- base commit 7ec1df8
end)

test('each page offers Theme and Background, not Template', function()
	local updates = 0
	local update = MM.UpdateConfig
	function MM:UpdateConfig() updates = updates + 1 end -- counted; run for real below
	T.check_no_old_names(MM:GetConfigTable(), 'Minimap')
	local MicroMenu = st:GetModule('MicroMenu')
	MicroMenu.Container = CreateFrame('Frame', nil, UIParent) -- SaftUI's, made by OnEnable
	T.check_no_old_names(MicroMenu:GetConfigTable(), 'Micro Menu')
	local general = MM:GetConfigTable().args.general
	T.check_options(general, 'Minimap')
	eq(general.get({ 'theme' }), 'theme', 'Theme reads minimap.theme')
	eq(general.get({ 'background' }), 'solid', 'Background reads minimap.background')
	general.set({ 'theme' }, 'thin')
	general.set({ 'background' }, 'transparent')
	eq(profile.minimap.theme, 'thin', 'Theme writes minimap.theme')
	eq(profile.minimap.background, 'transparent', 'Background writes minimap.background')
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

test("a micro menu item's panel is a small frame in SaftUI's theme, and Theme None has none", function()
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
	eq(drawn(backdrop), 'theme,theme,small', "SaftUI's theme, as a small frame")
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
local locked = load_test_file('misc/fixtures/locked_widget.lua')

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
	eq(select(1, button.FlashBorder:GetDrawLayer()), 'BACKGROUND', 'Thick: behind the icon')
	eq(button:GetHighlightTexture():GetAtlas(), nil, "Thick: the highlight isn't Blizzard's atlas")

	-- A switch, as Config:UpdateConfig runs it: every drawn frame redrawn, then
	-- the bar laid out again.
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	MicroMenu:UpdateButtons()
	eq(fades(), '1,1,1,1', "Blizzard: the background, shadows and performance bar show again")
	eq(button.PushedBackground:GetAtlas(), 'UI-HUD-MicroMenu-ButtonBG-Down', "the pushed background is Blizzard's")
	eq(T.offset(button.PushedBackground, 'CENTER'), '0.00,0.00', "at Blizzard's anchor, centered")
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
	eq(T.inset(panel), 2, 'the panel is a small frame again')
end)
