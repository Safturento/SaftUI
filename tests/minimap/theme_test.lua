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
