-- The action bars' Theme and Background (SaftUI-ActionBars): one pair for
-- every action button, following SaftUI's theme by default:
--   - the default looks exactly as the old template name drew;
--   - the buttons are drawn with it as action buttons: the backdrop fills the
--     button, with the icon inside its border, and a new theme's inset
--     reaches the icon when the bars are styled again;
--   - an equipped item's green border survives a theme recolor (a drag of
--     the Border color picker recolors on every move) and a theme switch.
--
-- Real: SaftUI-ActionBars' config.lua, init.lua and skin.lua over Core's
-- helpers (load_core_helpers). Each case starts from a fresh world, since
-- cases change the theme. Made by hand:
--   - LibActionButton-1.0, as far as skin.lua uses it when it loads
--     (fixtures/libactionbutton.lua);
--   - the buttons, as LibActionButton makes them from Blizzard's
--     ActionButtonTemplate, which the stubs don't have: check buttons with the
--     regions skin.lua styles (the icon, hotkey, count and macro texts, the
--     flash, and the cooldown with its countdown text) and the two methods of
--     LibActionButton's it calls on them, UpdateConfig and IsEquipped;
--   - a bar, as AB:CreateBar makes one, as far as AB:StyleBar reads it: its
--     buttons.
-- A theme switch is st:ThemeChanged's steps: st:RedrawThemed, the action
-- bars' UpdateConfig, which styles every bar again (AB:StyleBar, through
-- AB:UpdateBar; the bars themselves are secure headers the stubs can't make),
-- then st:ColorsChanged('theme').
local T = load_test_file('lib/theme_helpers.lua')

local st, AB, LAB, drawn

local function fresh()
	reset_world()
	load_core_helpers()
	st = SaftUI
	drawn = T.watch_draws(st)
	LAB = load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	apply_defaults()
	load_saftui('SaftUI-ActionBars/init.lua')
	load_saftui('SaftUI-ActionBars/skin.lua')
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
end

-- An action button as LibActionButton makes one, skinned by AB:SkinButton.
-- equipped is what LibActionButton's IsEquipped says; set button.equipped to
-- change it.
local function button(name, equipped)
	local b = CreateFrame('CheckButton', name, UIParent)
	b:SetSize(45, 45)
	b:SetPoint('CENTER')
	b.icon = b:CreateTexture(nil, 'BACKGROUND')
	b.Flash = b:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		b[key] = b:CreateFontString(nil, 'OVERLAY')
		b[key]:SetFontObject(GameFontNormal)
	end
	b.cooldown = CreateFrame('Frame', nil, b)
	local countdown = b.cooldown:CreateFontString(nil, 'OVERLAY')
	function b.cooldown:GetCountdownFontString() return countdown end
	b.equipped = equipped
	function b:UpdateConfig(config) self.labConfig = config end
	function b:IsEquipped() return self.equipped end
	AB:SkinButton(b)
	return b
end

-- Bar 1 with the given buttons, styled from the profile.
local function bar(...)
	AB.bars.bar1 = { buttons = { ... } }
	AB:StyleBar('bar1')
	return ...
end

-- A theme switch, as st:ThemeChanged runs it (see the top).
local function switch(name)
	st.config.profile.theme.name = name
	st:RedrawThemed()
	AB:StyleBar('bar1')
	st:ColorsChanged('theme')
end

local function green()
	return T.text(st.config.profile.colors.button.green:GetRGB())
end

test('the action bar default looks as it did', function()
	fresh()
	local config = st.config.profile.actionbars
	eq(config.template, nil, 'no template key')
	eq(config.theme, 'theme', "Theme follows SaftUI's theme")
	eq(config.background, 'theme', "Background follows SaftUI's theme")
	-- The template name it had before themes (themes' base, 7ec1df8).
	local new, was = st:ResolveTheme(config.theme, config.background), st:ResolveLegacyTemplate('thicktransparent')
	eq(new.name, was.name, 'the name thicktransparent drew')
	eq(new.inset, was.inset, 'the inset thicktransparent drew')
	eq(T.text(new.alpha), T.text(was.alpha), 'the alpha thicktransparent drew')
end)

test('the buttons are drawn with the action bars\' Theme and Background, the icon inside the border', function()
	fresh()
	local b = bar(button('ThemeTestAction1'))
	eq(drawn(b), 'theme,theme,action', "Use SaftUI's theme, as an action button")
	eq(T.around(b.backdrop, b), '0,0,0,0', 'the backdrop fills the button')
	eq(T.around(b.backdrop, b.icon), '-2,2,2,-2', "Thick's 2px around the icon")
	eq(T.text(select(4, b.backdrop:GetBackdropColor())), '0.90', "see-through at SaftUI's opacity")

	switch('thin')
	eq(T.around(b.backdrop, b), '0,0,0,0', 'after a switch to Thin: the backdrop still fills the button')
	eq(T.around(b.backdrop, b.icon), '-1,1,1,-1', "Thin's 1px around the icon")
	eq(T.inset(b.backdrop), 1, "drawn with Thin's one line")

	-- An override: the buttons Thick and Solid while SaftUI's theme is Thin.
	AB.config.theme, AB.config.background = 'thick', 'solid'
	AB:StyleBar('bar1')
	eq(drawn(b), 'thick,solid,action', 'the Theme and Background set')
	eq(T.around(b.backdrop, b.icon), '-2,2,2,-2', "Thick's 2px")
	eq(T.text(select(4, b.backdrop:GetBackdropColor())), '1.00', 'solid')

	AB.config.theme = 'none'
	AB:StyleBar('bar1')
	eq(T.inset(b.backdrop), nil, 'None: no border or background')
	eq(T.around(b.icon, b), '0,0,0,0', 'the icon fills the button')
	eq(#take_errors(), 0, 'no errors')
end)

test('the equipped border survives a recolor', function()
	fresh()
	local worn, other = bar(button('ThemeTestWorn', true), button('ThemeTestOther', false))
	eq(T.edge_rgb(worn.backdrop), green(), 'an equipped item: the green border')
	local thick = st.config.profile.templates.thick
	eq(T.edge(other.backdrop), T.text(unpack(thick.bordercolor)), "another: the theme's border")

	-- The Border color picker dragged: a new border color, then a recolor, on every move.
	for move = 1, 3 do
		thick.bordercolor = { 0.1 * move, 0.5, 0.5, 1 }
		st:RecolorThemed()
		eq(T.edge_rgb(worn.backdrop), green(), 'move ' .. move .. ': the equipped item stays green')
		eq(T.edge(other.backdrop), T.text(unpack(thick.bordercolor)), 'move ' .. move .. ": the other takes the theme's new border")
	end

	switch('thin')
	eq(T.edge_rgb(worn.backdrop), green(), 'a switch to Thin: still green')
	eq(T.edge(other.backdrop), T.text(unpack(st.config.profile.templates.thin.bordercolor)), "the other takes Thin's border")

	-- Taken off: LibActionButton updates the button, and its border is the theme's,
	-- through a recolor too.
	worn.equipped = false
	LAB.callbacks:Fire('OnButtonUpdate', worn)
	local thin = T.text(unpack(st.config.profile.templates.thin.bordercolor))
	eq(T.edge(worn.backdrop), thin, "taken off: the theme's border")
	eq(drawn(worn.backdrop), 'theme,theme,action', 'drawn again with the Theme and Background, as an action button')
	st:RecolorThemed()
	eq(T.edge(worn.backdrop), thin, 'and a recolor leaves it so')
	worn.equipped = true
	LAB.callbacks:Fire('OnButtonUpdate', worn)
	st:RecolorThemed()
	eq(T.edge_rgb(worn.backdrop), green(), 'put on again: green, through a recolor')
	eq(#take_errors(), 0, 'no errors')
end)
