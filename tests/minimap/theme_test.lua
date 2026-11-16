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
	-- Each setup calls its registration (deleting a call would leave a frame with no mover), and the keys are the real ones.
	local function Calls(path, setup, call)
		local body = read_saftui_source(path):match('function ' .. setup .. '%(%).-\nend')
		check(body and body:find(call, 1, true), setup .. ' calls ' .. call)
	end
	Calls('SaftUI-Minimap/minimap.lua', 'MM:OnEnable', 'self:RegisterMinimapMover()')
	Calls('SaftUI-Minimap/micromenu.lua', 'MicroMenu:OnEnable', 'self:RegisterMicroMenuMover()')
	local registerMover, keys = st.RegisterConfigMover, {}
	function st:RegisterConfigMover(frame, opts) keys[#keys + 1] = opts.key; return registerMover(self, frame, opts) end
	MM:RegisterMinimapMover()
	MicroMenu:RegisterMicroMenuMover()
	st.RegisterConfigMover = registerMover
	eq(keys[1], 'minimap', "the minimap mover's key")
	eq(keys[2], 'micromenu', "the micro menu mover's key")
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

------------------------------------ the derived states

-- Every state is derived from the Accent (the states helper, Core's
-- Widgets/states.lua): a micro button's highlight is T+ at 0.16 over a white
-- texture set once, its pushed background the Fill (the fade, at 0.24), a bar
-- item's Layer T+ and T-, and the tracking, queue and expansion buttons'
-- highlight T+ at 0.16, BLEND. The Buttons colors reach none of them.
local function hover_text() return T.text(st:StateColor('hover')) end

test("a micro button's flat highlight is T+ at 0.16 and its pushed background the Fill, both over white textures", function()
	local MicroMenu = st:GetModule('MicroMenu')
	local button
	for _, child in ipairs({ _G.MicroMenu:GetChildren() }) do
		if child.layoutIndex == 1 then button = child end
	end
	check(button ~= nil, 'the micro button the case above made')
	local function look(name)
		profile.theme.name = name
		st:RedrawThemed()
		MicroMenu:UpdateButtons()
	end
	look('blizzard'); look('thick')
	local highlight = button:GetHighlightTexture()
	eq(T.text(highlight:GetVertexColor()), hover_text(), 'the highlight is T+ at 0.16')
	eq(highlight:GetTexture(), st.BLANK_TEX, 'a white texture')
	eq(highlight:GetBlendMode(), 'BLEND')
	eq(T.text(button.PushedBackground:GetVertexColor()), T.text(st:StateColor('fill')), 'the pushed background is the Fill')
	eq(button.PushedBackground:GetTexture(), st.textures.stateFade, 'the fade')
	eq(button.PushedBackground:GetBlendMode(), 'BLEND')
	-- the Buttons colors are not read
	profile.colors.button.hover:SetRGB(0.9, 0.2, 0.6)
	look('blizzard'); look('thick')
	eq(T.text(highlight:GetVertexColor()), hover_text(), 'Buttons > Hover is not the highlight')
	-- Blizzard re-applies its art on the highlight; the hooked swap puts the white texture back
	button:SetHighlightAtlas('UI-HUD-MicroMenu-Questlog-Mouseover', 'BLEND')
	eq(highlight:GetAtlas(), nil, 'after an atlas swap: no atlas')
	eq(highlight:GetTexture(), st.BLANK_TEX)
	eq(T.text(highlight:GetVertexColor()), hover_text())
end)

test("a micro button whose window is open: the Fill's edge on the panel, off again when it closes", function()
	local MicroMenu = st:GetModule('MicroMenu')
	local button, panel
	for _, child in ipairs({ _G.MicroMenu:GetChildren() }) do
		if child.layoutIndex == 1 then button = child end
	end
	for _, child in ipairs({ button:GetChildren() }) do
		if child ~= button.NotificationOverlay then panel = child end
	end
	profile.theme.name = 'thick'
	st:RedrawThemed()
	local rest = T.edge(panel)
	local accent_edge = T.text(st:StateColor('edge')) -- (r, g, b, 1)
	-- Blizzard's SetPushed: the state, then the highlight (SaftUI's post-hook follows)
	button:SetButtonState('PUSHED', true)
	button:SetHighlightAtlas('UI-HUD-MicroMenu-Questlog-Mouseover', 'BLEND')
	eq(st:GetState(button, 'selected'), true, 'selected while its window is open')
	eq(T.edge(panel), accent_edge, "the panel's edge is the Accent")
	button:SetButtonState('NORMAL')
	button:SetHighlightAtlas('UI-HUD-MicroMenu-Questlog-Mouseover', 'BLEND')
	eq(st:GetState(button, 'selected'), false, 'off when it closes')
	eq(T.edge(panel), rest, "the panel's own edge is back")
	-- under Blizzard: nothing of SaftUI's
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	MicroMenu:UpdateButtons()
	button:SetButtonState('PUSHED', true)
	button:SetHighlightAtlas('UI-HUD-MicroMenu-Questlog-Mouseover', 'BLEND')
	eq(button.PushedBackground:GetAtlas(), 'UI-HUD-MicroMenu-ButtonBG-Down', "Blizzard's pushed art")
	eq(button:GetHighlightTexture():GetAtlas(), 'UI-HUD-MicroMenu-Questlog-Mouseover', "Blizzard's highlight")
	eq(T.text(button.PushedBackground:GetVertexColor()), '1.00,1.00,1.00,1.00', 'untinted')
	button:SetButtonState('NORMAL')
	profile.theme.name = 'thick'
	st:RedrawThemed()
	MicroMenu:UpdateButtons()
end)

test("a bar item's Layer is T+ for hover and T- for pushed, 40% when disabled", function()
	local MicroMenu = st:GetModule('MicroMenu')
	local item = CreateFrame('Button', nil, UIParent)
	item:SetSize(60, 20)
	MicroMenu:SkinBarButton(item)
	stub.fire_script(item, 'OnEnter')
	local look = st:StateLook(item)
	eq(T.text(look.layer.r, look.layer.g, look.layer.b, look.layer.a), hover_text(), 'hover')
	stub.fire_script(item, 'OnMouseDown', 'LeftButton')
	look = st:StateLook(item)
	eq(T.text(look.layer.r, look.layer.g, look.layer.b, look.layer.a), T.text(st:StateColor('pushed')), 'pushed')
	stub.fire_script(item, 'OnMouseUp', 'LeftButton')
	stub.fire_script(item, 'OnLeave')
	item:Disable()
	eq(st:StateLook(item).alpha, 0.4, 'disabled: 40%')
	item:Enable()
	eq(st:StateLook(item).alpha, 1)
end)

test("the tracking, queue and expansion buttons' highlights are T+ at 0.16, BLEND", function()
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
	MicroMenu:SkinTrackingButton()
	MicroMenu:SkinQueueButton()
	MicroMenu:UpdateExpansionLandingPageButton()
	for name, b in pairs({ tracking = tracking, queue = _G.QueueStatusButton, expansion = _G.ExpansionLandingPageMinimapButton }) do
		local h = b:GetHighlightTexture()
		eq(T.text(h:GetVertexColor()), hover_text(), name .. ': T+ at 0.16')
		eq(h:GetBlendMode(), 'BLEND', name .. ': blend set')
	end
	_G.MinimapCluster, _G.QueueStatusButton, _G.ExpansionLandingPageMinimapButton = keep_cluster, keep_queue, keep_expansion
end)
