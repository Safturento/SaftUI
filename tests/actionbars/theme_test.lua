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

-- A fresh world, on Forever unless it names retail.
local function fresh(client)
	if client then
		T.client(client)
	else
		reset_world()
		load_core_helpers()
	end
	st = SaftUI
	drawn = T.watch()
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

test("under Blizzard a 45px action button's icon sits inside the action inset", function()
	fresh()
	st.config.profile.theme.name = 'blizzard'
	local b = bar(button('ThemeTestBlizzInset'))
	eq(st:ThemeInset('theme', 'theme', 'action'), 3, "Blizzard's action inset")
	eq(T.offset(b.icon, 'TOPLEFT'), '3.00,-3.00', 'the icon sits 3px in from the corner')
	-- TOPRIGHT x_off -3 on 45px: the right-aligned text has 42 - 3 room, which is
	-- the inside width at inset 3 (Thick's 2 would give 40).
	eq(b.HotKey:GetWidth(), 39, "the hotkey's width is TextWidth's at inset 3")
	eq(#take_errors(), 0, 'no errors')
end)

test("under Blizzard an equipped item shows Blizzard's equipped border in the green, through a recolor", function()
	fresh()
	st.config.profile.theme.name = 'blizzard'
	local worn, other = bar(button('ThemeTestBlizzWorn', true), button('ThemeTestBlizzOther', false))
	local function border(b)
		local own = st.ThemeArt.Get(b.backdrop).own
		if not (own and own:IsShown()) then return 'off' end
		return tostring(own:GetAtlas()) .. ' ' .. T.text(own:GetVertexColor())
	end
	local GREEN = 'UI-HUD-ActionBar-IconFrame-Border ' .. green() .. ',1.00'
	eq(border(worn), GREEN, "an equipped item: Blizzard's equipped border, in the green")
	eq(border(other), 'off', 'another: none')
	eq(T.over(worn.backdrop), 'Ring=UI-HUD-ActionBar-IconFrame', 'the ring stays')

	-- The Border color picker dragged: a recolor on every move.
	for move = 1, 3 do
		st.config.profile.templates.blizzard.bordercolor = { 0.1 * move, 0.5, 0.5, 1 }
		st:RecolorThemed()
		st:ColorsChanged('theme')
		eq(border(worn), GREEN, 'move ' .. move .. ': the equipped item stays green')
		eq(border(other), 'off', 'move ' .. move .. ': the other stays bare')
	end

	-- A switch away and back (every button is styled again, which draws it again).
	switch('thick')
	eq(T.edge_rgb(worn.backdrop), green(), 'under Thick: the green line')
	eq(border(worn), 'off', 'and no Blizzard border')
	switch('blizzard')
	eq(border(worn), GREEN, 'back under Blizzard: green again')

	-- Taken off: the border goes.
	worn.equipped = false
	LAB.callbacks:Fire('OnButtonUpdate', worn)
	eq(border(worn), 'off', 'taken off: no border')
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
	eq(drawn(worn), 'theme,theme,action', 'still drawn with the Theme and Background, as an action button')
	eq(drawn(worn.backdrop), nil, 'and not drawn again: the border is put back without a redraw')
	st:RecolorThemed()
	eq(T.edge(worn.backdrop), thin, 'and a recolor leaves it so')
	worn.equipped = true
	LAB.callbacks:Fire('OnButtonUpdate', worn)
	st:RecolorThemed()
	eq(T.edge_rgb(worn.backdrop), green(), 'put on again: green, through a recolor')
	eq(#take_errors(), 0, 'no errors')
end)

-- Where a region draws among its button's regions, as one number: the layer,
-- then the sublevel.
local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
local function depth(region)
	local layer, sublevel = region:GetDrawLayer()
	return LAYERS[layer] * 100 + (sublevel or 0)
end

test("under Blizzard an action button's hover, pushed, checked and flash are Blizzard's atlases over the ring", function()
	for _, case in ipairs({ { 'forever', 'ADD' }, { 'retail', 'BLEND' } }) do
		local client, checkedBlend = case[1], case[2]
		fresh(client)
		st.config.profile.theme.name = 'blizzard'
		local b = bar(button('ThemeTestState' .. client))
		local where = client .. ': '
		local hover, pushed, checked = b:GetHighlightTexture(), b:GetPushedTexture(), b:GetCheckedTexture()
		eq(hover:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', where .. "hover is Blizzard's")
		eq(pushed:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Down', where .. "pushed is Blizzard's")
		eq(checked:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', where .. "checked is Blizzard's")
		eq(b.Flash:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Flash', where .. "flash is Blizzard's")
		eq(checked:GetBlendMode(), checkedBlend, where .. 'checked blends as the template does')
		for name, region in pairs({ hover = hover, pushed = pushed, checked = checked, flash = b.Flash }) do
			eq(T.text(region:GetVertexColor()), '1.00,1.00,1.00,1.00', where .. name .. ' has no tint')
		end

		-- Over the ring's footprint, the whole button, not the icon inside it.
		for name, region in pairs({ hover = hover, pushed = pushed, checked = checked, flash = b.Flash }) do
			eq(T.around(region, b), '0,0,0,0', where .. name .. ' covers the button')
		end

		-- The hover is the button's highlight, which the client shows only in
		-- the HIGHLIGHT layer, under the mouse: moved out of it, it shows all
		-- the time. That layer is over the ring and the icon, and the
		-- template's texts are in a frame over the button (TextOverlayContainer,
		-- level 500), so in game it still draws under them.
		eq(select(1, hover:GetDrawLayer()), 'HIGHLIGHT', where .. 'hover shows only under the mouse')

		-- Above the ring and the own-color piece, under the texts.
		local ring = st.ThemeArt.Get(b.backdrop).over.Ring
		eq(ring:GetParent(), b, where .. "the ring is a texture of the button's own")
		for name, region in pairs({ pushed = pushed, checked = checked }) do
			check(depth(region) >= depth(ring) + 1, where .. name .. ' draws over the ring')
			check(depth(region) >= LAYERS.ARTWORK * 100 - 1, where .. name .. ' draws over the icon')
			for _, text in ipairs({ b.HotKey, b.Count, b.Name }) do
				check(depth(region) < depth(text), where .. name .. ' draws under the texts')
			end
		end
		check(depth(b.Flash) > depth(ring), where .. 'the flash draws over the ring')
		for _, text in ipairs({ b.HotKey, b.Count, b.Name }) do
			check(depth(b.Flash) < depth(text), where .. 'the flash draws under the texts')
		end

		-- Under Thick: SaftUI's flat textures over the icon, exactly as before.
		switch('thick')
		local colors = st.config.profile.colors.button
		eq(hover:GetAtlas(), nil, 'Thick: hover is no atlas')
		eq(hover:GetTexture(), st.BLANK_TEX, 'Thick: hover is the flat texture')
		eq(T.text(hover:GetVertexColor()), T.text(colors.blue:GetRGB()) .. ',1.00', 'Thick: hover is blue')
		eq(T.text(pushed:GetVertexColor()), '0.00,0.00,0.00,0.10', 'Thick: pushed is the dark tint')
		eq(T.text(checked:GetVertexColor()), '1.00,1.00,1.00,0.30', 'Thick: checked is the white tint')
		eq(checked:GetBlendMode(), 'ADD', 'Thick: checked is additive')
		eq(b.Flash:GetAtlas(), nil, 'Thick: the flash is no atlas')
		eq(T.text(select(4, b.Flash:GetVertexColor())), '1.00', 'Thick: the flash')
		for name, region in pairs({ hover = hover, pushed = pushed, checked = checked, flash = b.Flash }) do
			eq(T.around(region, b.icon), '0,0,0,0', 'Thick: ' .. name .. ' covers the icon')
		end
		eq(select(1, hover:GetDrawLayer()), 'HIGHLIGHT', 'Thick: hover shows only under the mouse, as it did')
		eq(select(1, pushed:GetDrawLayer()), 'OVERLAY', 'Thick: pushed too')
		eq(select(1, checked:GetDrawLayer()), 'OVERLAY', 'Thick: checked too')

		-- And back.
		switch('blizzard')
		eq(hover:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', where .. 'back under Blizzard: hover')
		eq(select(1, hover:GetDrawLayer()), 'HIGHLIGHT', where .. 'back under Blizzard: hover only under the mouse')
		eq(checked:GetBlendMode(), checkedBlend, where .. 'checked blend again')
		eq(b.Flash:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Flash', where .. 'the flash again')
		eq(T.around(pushed, b), '0,0,0,0', where .. 'pushed covers the button again')
		eq(#take_errors(), 0, where .. 'no errors')
	end
end)
