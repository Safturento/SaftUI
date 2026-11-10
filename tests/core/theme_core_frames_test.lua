-- Core's own frames with the theme engine (SaftUI-Core/theme.lua): every draw
-- call in Core names a kind and a Theme and Background, and the frames follow
-- SaftUI's theme:
--   - window headers, footers and a close button that isn't SaftUI's
--     (panels.lua), and st:CreatePanel's panel, from panels.theme;
--   - the /sui window and its dialog (Config/optionswindow.lua), and the
--     border of Icon zoom's preview (a description's image,
--     Config/optionswidgets.lua);
--   - the buttons.theme / panels.theme defaults (Config/defaults.lua);
--   - the wrappers st:SkinActionButton and st:SkinEditBox (skinning.lua) and
--     Core's widgets (Widgets/button.lua, statusbar.lua, radiogroup.lua),
--     which still draw an old template name from a caller not yet moved to
--     themes exactly as before;
--   - edit mode's movers, which keep their own colors through a recolor;
--   - the Theme and Background option builders (Config/widgets.lua).
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 with Core's helpers and
-- edit mode (config_helpers.lua), the options model, widgets, body and window,
-- and Widgets/statusbar.lua and radiogroup.lua. Each case starts from a fresh
-- world, since cases change the profile's theme. The kind a frame was drawn
-- with changes nothing under Thick and Thin, so the draw calls are watched:
-- st:SetTemplate and st:SetBackdrop are wrapped to note their arguments, and
-- still draw.

local OM, W, OW

-- A fresh world, with Core's draw calls watched: draws[frame] is the theme,
-- background and kind frame was last drawn with.
local draws
local function fresh()
	reset_world()
	load_test_file('core/config_helpers.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_saftui('SaftUI-Core/Config/optionswindow.lua')
	load_saftui('SaftUI-Core/Widgets/statusbar.lua')
	load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
	local st = SaftUI
	OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow

	draws = setmetatable({}, { __mode = 'k' })
	for _, name in ipairs({ 'SetTemplate', 'SetBackdrop' }) do
		local real = st[name]
		st[name] = function(self, frame, theme, background, kind)
			draws[frame] = { theme, background, kind }
			return real(self, frame, theme, background, kind)
		end
	end
	return st
end

-- How frame was last drawn: 'theme,background,kind' ('nil' for what wasn't
-- passed), or nil if it wasn't.
local function drawn(frame)
	local d = draws[frame]
	if not d then return nil end
	return ('%s,%s,%s'):format(tostring(d[1]), tostring(d[2]), tostring(d[3]))
end

-- Numbers as text, rounded so float drift doesn't decide a check.
local function text(...)
	local out = {}
	for i = 1, select('#', ...) do out[i] = string.format('%.2f', (select(i, ...))) end
	return table.concat(out, ',')
end

local function fill(f) return text(f:GetBackdropColor()) end
local function edge(f) return text(f:GetBackdropBorderColor()) end
local function inset(f) return f.backdropInfo and f.backdropInfo.insets.left end
local function alpha(f) return text(select(4, f:GetBackdropColor())) end

-- The x and y of one of a frame's points, as text.
local function offset(f, point)
	for i = 1, f:GetNumPoints() do
		local p, _, _, x, y = f:GetPoint(i)
		if p == point then return text(x, y) end
	end
end

local function frame(st, frameType, name)
	local f = st:CreateFrame(frameType or 'Frame', name, UIParent)
	f:SetSize(100, 50)
	f:SetPoint('CENTER')
	return f
end

-- Switches SaftUI's theme and redraws, as the Theme tab does.
local function switch(st, name)
	st.config.profile.theme.name = name
	st:RedrawThemed()
end

local THICK_EDGE, THIN_EDGE = '0.30,0.30,0.30,1.00', '0.00,0.00,0.00,1.00'

------------------------------------------------------------------ panels

test("window headers and footers follow SaftUI's theme, not their window's", function()
	local st = fresh()
	local panel = frame(st, 'Frame', 'ThemeTestPanel')
	st:SetBackdrop(panel, 'thin', 'solid', 'panel')
	st:CreateHeader(panel, 'Title')
	st:CreateFooter(panel)
	eq(drawn(panel.header), 'theme,theme,header', 'the header is drawn as a header strip')
	eq(drawn(panel.footer), 'theme,theme,header', 'the footer too')
	eq(fill(panel.header), '0.30,0.30,0.30,0.40', "the header: the theme's (Thick's) border color at 0.4, not Thin's")
	eq(fill(panel.footer), '0.30,0.30,0.30,0.40', 'the footer too')

	-- A close button that isn't SaftUI's (Blizzard's) gets the close look.
	local other = frame(st, 'Frame', 'ThemeTestBlizzardWindow')
	local close = CreateFrame('Button', nil, other)
	st:CreateHeader(other, 'Other', close)
	eq(drawn(close), 'theme,theme,close', "a button that isn't SaftUI's is drawn as the close button")
	eq(fill(close.backdrop), '0.50,0.10,0.10,0.40', "the close button's red")

	-- st:CreatePanel: panels.theme and panels.background, as a window.
	local p = st:CreatePanel('Theme test', 200, 100)
	eq(drawn(p), 'theme,theme,panel', "a panel is drawn with panels.theme and panels.background, as a window")
	eq(fill(p.backdrop), '0.12,0.12,0.12,0.90', "SaftUI's theme: Thick's background at the opacity")
	eq(offset(p.backdrop, 'TOPLEFT'), '-2.00,2.00', "Thick's 2px out")

	switch(st, 'thin')
	eq(fill(panel.header), '0.00,0.00,0.00,0.40', "after a switch to Thin: Thin's border color at 0.4")
	eq(fill(panel.footer), '0.00,0.00,0.00,0.40', 'the footer too')
	eq(offset(p.backdrop, 'TOPLEFT'), '-1.00,1.00', "the panel moves to Thin's 1px")
	eq(edge(p.backdrop), THIN_EDGE, "the panel takes Thin's border")
end)

------------------------------------------------------------------ /sui

test("the /sui window takes the theme's border and stays solid", function()
	local st = fresh()
	st.Config:Open()
	local window = OW.GetFrames().window
	OW:OpenDialog('Dialog', {
		type = 'group', name = 'Group',
		args = { note = { type = 'description', name = 'A note.' } },
	})
	local dialog = OW.GetDialogFrames().frame

	for name, f in pairs({ window = window, dialog = dialog }) do
		eq(drawn(f), 'theme,solid,panel', name .. ": SaftUI's theme, Solid, as a window")
		eq(edge(f), THICK_EDGE, name .. ": Thick's border")
		eq(alpha(f), '1.00', name .. ': solid, though the theme is transparent')
		eq(inset(f), 2, name .. ": Thick's 2px border")
	end

	switch(st, 'thin')
	for name, f in pairs({ window = window, dialog = dialog }) do
		eq(inset(f), 1, name .. ": after a switch to Thin, Thin's 1px border")
		eq(edge(f), THIN_EDGE, name .. ": Thin's border color")
		eq(alpha(f), '1.00', name .. ': still solid')
	end
	st.Config:Close()
end)

-- The model's row for option key in a one-page tree, and the tree.
local function make(key, option)
	local root = { page = { type = 'group', name = 'Page', args = { [key] = option } } }
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
	error('no row ' .. key)
end

local function drawnRow(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

test("Icon zoom's preview has a border in SaftUI's theme, and a description without an image shows none", function()
	local st = fresh()
	st.Config:Open('Fonts', 'general')
	local preview = drawnRow('icon_preview').widget
	local image = preview.image
	local backdrop = image.backdrop
	check(backdrop ~= nil and backdrop:IsShown(), 'the preview has a backdrop')
	eq(drawn(image), 'theme,theme,action', "drawn in SaftUI's theme, as an action button's icon")
	eq(edge(backdrop), THICK_EDGE, "Thick's border")
	eq(fill(backdrop), '0.12,0.12,0.12,0.90', "Thick's background at the opacity")
	eq(offset(backdrop, 'TOPLEFT'), '-2.00,2.00', "Thick's 2px outside the icon")
	eq(offset(backdrop, 'BOTTOMRIGHT'), '2.00,-2.00', "Thick's 2px outside the icon (bottom right)")

	-- A recolor and a redraw reach it.
	st.config.profile.templates.thick.bordercolor = { 1, 0, 0, 1 }
	st:RecolorThemed()
	eq(edge(backdrop), '1.00,0.00,0.00,1.00', 'a recolor gives it the new border color')
	switch(st, 'thin')
	eq(offset(backdrop, 'TOPLEFT'), '-1.00,1.00', "a switch to Thin moves it to Thin's 1px")
	eq(edge(backdrop), THIN_EDGE, "with Thin's border color")
	st.Config:Close()

	-- The pooled descriptions, the preview's among them, bound to a row with
	-- no image: none shows a border.
	local root, row = make('words', { type = 'description', name = 'Just words.' })
	local widgets, reused = {}, false
	for _ = 1, W.Pooled('description') do
		local w = W.Create(UIParent, 'description')
		w:Bind(root, row)
		widgets[#widgets + 1] = w
		if w == preview then reused = true end
	end
	check(reused, "the preview's widget came back from the pool")
	local fresh_one = W.Create(UIParent, 'description')
	fresh_one:Bind(root, row)
	widgets[#widgets + 1] = fresh_one
	for i, w in ipairs(widgets) do
		check(not w.image:IsShown(), 'description ' .. i .. ': no image')
		check(not (w.image.backdrop and w.image.backdrop:IsVisible()), 'description ' .. i .. ': no border')
	end

	-- Given an image again, the border is back.
	root, row = make('pic', { type = 'description', name = 'x', image = 'Interface\\Icons\\Spell_Nature_Lightning' })
	preview:Bind(root, row)
	check(preview.image.backdrop:IsVisible(), 'an image brings its border back')
	for _, w in ipairs(widgets) do w:Release() end
end)

------------------------------------------------------------------ defaults

test('Core defaults: buttons and panels follow the theme', function()
	local st = fresh()
	local old = st:ResolveLegacyTemplate('thicktransparent')
	for _, key in ipairs({ 'buttons', 'panels' }) do
		local defaults = st.defaults[key]
		eq(defaults.theme, 'theme', key .. ".theme: Use SaftUI's theme")
		eq(defaults.background, 'theme', key .. ".background: Use SaftUI's theme")
		eq(defaults.template, nil, key .. ': no template key')
		local look = st:ResolveTheme(defaults.theme, defaults.background)
		check(look.name == old.name and look.inset == old.inset and look.alpha == old.alpha and look.colors == old.colors,
			key .. ": today's thicktransparent look")
	end
end)

------------------------------------------------------------------ edit mode

test('a mover keeps its color through a recolor', function()
	local st = fresh()
	local EM = st.EditModeFrames
	local position = { point = 'CENTER', x_off = 0, y_off = 0 }
	local function register(key)
		return st:RegisterMover(key, {
			frame = frame(st),
			getPosition = function() return position end,
			setPosition = function(pos) position = pos end,
			apply = function() end,
		})
	end
	local plain, picked = register('theme_plain'), register('theme_picked')
	EM:Select(picked)
	eq(drawn(plain.overlay), 'theme,solid,small', "the overlay: SaftUI's theme, Solid")
	local blue = text(st.config.profile.colors.button.blue:GetRGB())

	local function check_colors(when)
		local b = plain.overlay.backdrop
		eq(fill(b), '0.00,0.00,0.00,0.30', when .. ': a mover keeps its see-through fill')
		eq(edge(b), '1.00,1.00,1.00,1.00', when .. ': and its white line')
		b = picked.overlay.backdrop
		eq(fill(b), blue .. ',0.15', when .. ': the selected mover keeps its blue tint')
		eq(edge(b), blue .. ',1.00', when .. ': and its blue line')
	end
	check_colors('drawn')

	st.config.profile.templates.thick.backdropcolor = { 0.5, 0.5, 0.5, 1 }
	st.config.profile.templates.thick.bordercolor = { 1, 0, 0, 1 }
	st:RecolorThemed()
	check_colors('after a recolor')
	eq(text(plain.overlay.backdrop.altborder.LEFT:GetVertexColor()), '0.10,0.10,0.10,1.00', "the dark lines stay Thick's outer border color")

	EM:Select(nil)
	st:RecolorThemed()
	eq(edge(picked.overlay.backdrop), '1.00,1.00,1.00,1.00', 'a mover no longer selected takes the white line')
end)

------------------------------------------------------------------ wrappers

test('st:SkinActionButton draws config.theme and config.background, and an old config.template as before', function()
	local st = fresh()
	local function button(name)
		local b = frame(st, 'Button', name)
		b:SetSize(36, 36)
		return b
	end

	local a = button('ThemeTestAction')
	st:SkinActionButton(a, { theme = 'thin', background = 'transparent' })
	eq(drawn(a), 'thin,transparent,action', 'Theme and Background, as an action button')
	eq(offset(a.backdrop, 'TOPLEFT'), '-1.00,1.00', "Thin's 1px out")
	eq(fill(a.backdrop), '0.20,0.20,0.20,0.90', "Thin's background at the opacity")

	local s = button('ThemeTestSlot')
	st:SkinActionButton(s, { theme = 'theme', background = 'theme' }, 'slot')
	eq(drawn(s), 'theme,theme,slot', 'a kind passed in is drawn')

	local d = button('ThemeTestDefault')
	st:SkinActionButton(d)
	eq(drawn(d), 'theme,theme,action', "no config: the profile's buttons.theme and buttons.background")

	-- A config not yet moved to themes: the old name, with no kind, as before.
	local l = button('ThemeTestLegacy')
	st:SkinActionButton(l, { template = 'thin' })
	eq(drawn(l), 'thin,nil,nil', 'an old config.template draws with no kind')
	eq(l.backdrop.template, 'thin', 'backdrop.template is the old name, as before')
	eq(fill(l.backdrop), '0.20,0.20,0.20,1.00', "thin as it always drew: Thin's background, solid")
	local n = button('ThemeTestNone')
	st:SkinActionButton(n, {})
	eq(drawn(n), nil, 'no theme or template draws nothing, as before')

	-- trueSize still fills the button with its backdrop.
	local t = button('ThemeTestTrueSize')
	st:SkinActionButton(t, { theme = 'theme', background = 'theme', trueSize = true })
	eq(offset(t.backdrop, 'TOPLEFT'), '0.00,0.00', 'trueSize: the backdrop fills the button')
	switch(st, 'thin')
	eq(offset(t.backdrop, 'TOPLEFT'), '0.00,0.00', 'and a redraw leaves it there')
	eq(offset(a.backdrop, 'TOPLEFT'), '-1.00,1.00', 'a Thin override stays Thin')
	eq(offset(s.backdrop, 'TOPLEFT'), '-1.00,1.00', "the theme's slot moves to Thin's 1px")
end)

test('st:SkinEditBox and st:StyleEditBox take a Theme and Background, and an old template name with its font as before', function()
	local st = fresh()
	local e = frame(st, 'EditBox', 'ThemeTestEdit')
	st:SkinEditBox(e, 'thin', 'solid')
	eq(drawn(e), 'thin,solid,small', 'Theme and Background')
	eq(edge(e.backdrop), THIN_EDGE, "Thin's border")
	e:SetFocus()
	eq(edge(e.backdrop), '1.00,1.00,1.00,1.00', 'white while it has focus')
	e:ClearFocus()
	eq(edge(e.backdrop), THIN_EDGE, "Thin's border again when it loses focus")
	eq(drawn(e), 'thin,solid,small', 'drawn again with the same Theme and Background')

	-- Styled again (a profile change): losing focus brings back the new look.
	st:StyleEditBox(e, 'theme', 'transparent')
	eq(drawn(e), 'theme,transparent,small', 'StyleEditBox draws the new Theme and Background')
	e:SetFocus()
	e:ClearFocus()
	eq(drawn(e), 'theme,transparent,small', 'and losing focus keeps them')
	eq(edge(e.backdrop), THICK_EDGE, "the theme's (Thick's) border")

	local d = frame(st, 'EditBox', 'ThemeTestEditDefault')
	st:SkinEditBox(d)
	eq(drawn(d), 'theme,solid,small', "no theme: Use SaftUI's theme and Solid (it drew thick)")

	-- A caller not yet moved to themes: (editbox, template, font).
	local o = frame(st, 'EditBox', 'ThemeTestEditOld')
	local words = o:CreateFontString(nil, 'OVERLAY') -- the box's text, its first region
	st:SkinEditBox(o, 'thintransparent', 'pixel')
	eq(drawn(o), 'thintransparent,nil,nil', 'an old name draws with no kind')
	eq(o.backdrop.template, 'thintransparent', 'as before')
	check(words:GetFontObject() == st:GetFont('pixel'), 'the third argument is still its font')
	o:SetFocus()
	o:ClearFocus()
	eq(drawn(o), 'thintransparent,nil,nil', 'losing focus draws the old name again')
	st:StyleEditBox(o, 'thick', 'normal')
	eq(drawn(o), 'thick,nil,nil', "StyleEditBox's old form too")
	eq(alpha(o.backdrop), '1.00', 'thick as it always drew: solid')
	check(words:GetFontObject() == st:GetFont('normal'), 'with its font')
end)

------------------------------------------------------------------ widgets

test("Core's buttons and status bars draw with a kind; an old template name from a caller not yet moved draws as before", function()
	local st = fresh()
	local b = st:CreateButton('ThemeTestButton', UIParent, 'x')
	eq(drawn(b), 'theme,solid,small', "no theme: Use SaftUI's theme and Solid (it was thick)")
	eq(alpha(b.backdrop), '1.00', 'solid')
	eq(edge(b.backdrop), THICK_EDGE, "the theme's (Thick's) border")
	local t = st:CreateButton(nil, UIParent, 'x', 'thin', 'transparent')
	eq(drawn(t), 'thin,transparent,small', 'Theme and Background')
	local o = st:CreateButton(nil, UIParent, 'x', 'thicktransparent')
	eq(drawn(o), 'thicktransparent,nil,nil', 'an old name draws with no kind')
	eq(o.backdrop.template, 'thicktransparent', 'as before')
	local n = st:CreateButton(nil, UIParent, 'x', 'none')
	eq(n.backdrop, nil, 'none: no backdrop, as before')
	local s = frame(st, 'Button')
	st:SkinButton(s, 'theme', 'theme')
	eq(drawn(s), 'theme,theme,small', 'SkinButton takes a Theme and Background')

	local bar = st:CreateStatusBar(nil, UIParent, 'x')
	eq(drawn(bar), 'theme,solid,bar', "a status bar: Use SaftUI's theme and Solid, as a bar")
	local tbar = st:CreateStatusBar(nil, UIParent, 'x', 'thin', 'solid')
	eq(drawn(tbar), 'thin,solid,bar', 'a status bar with a Theme and Background')
	local obar = st:CreateStatusBar(nil, UIParent, 'x', 'thick')
	eq(drawn(obar), 'thick,nil,nil', 'a status bar with an old name: no kind, as before')

	-- A switch moves what follows the theme and leaves the old names as they drew.
	switch(st, 'thin')
	eq(offset(b.backdrop, 'TOPLEFT'), '-1.00,1.00', "the button moves to Thin's 1px")
	eq(offset(bar.backdrop, 'TOPLEFT'), '-1.00,1.00', 'the status bar too')
	eq(inset(o.backdrop), 2, 'thicktransparent still draws Thick')
	eq(inset(obar.backdrop), 2, 'thick still draws Thick')
end)

test('a radio group draws its buttons with options.theme and options.background, or an old options.template as before', function()
	local st = fresh()
	local function group(name, options)
		options.buttonHeight, options.buttonWidth, options.buttonSpacing = 20, 50, 2
		options.items = { { label = 'A' }, { label = 'B' } }
		return st:CreateRadioGroup(name, UIParent, options)
	end
	local blue = text(st.config.profile.colors.button.blue:GetRGB()) .. ',1.00'

	local g = group('ThemeTestRadio', { theme = 'thin', background = 'solid' })
	eq(g.backdrop, nil, 'the group itself draws nothing, as before')
	eq(drawn(g.buttons[1]), 'theme,solid,small', "its buttons start in SaftUI's theme, Solid (they were thick)")
	stub.fire_script(g.buttons[2], 'OnClick', 'LeftButton', false)
	eq(drawn(g.buttons[1]), 'thin,solid,small', 'a click draws the buttons with the Theme and Background')
	eq(edge(g.buttons[2].backdrop), blue, 'and the clicked one blue')

	local o = group('ThemeTestRadioOld', { template = 'thintransparent' })
	stub.fire_script(o.buttons[1], 'OnClick', 'LeftButton', false)
	eq(drawn(o.buttons[2]), 'thintransparent,nil,nil', 'an old options.template draws with no kind, as before')
	eq(edge(o.buttons[1].backdrop), blue, 'and the clicked one blue')
end)

------------------------------------------------------------------ option builders

test('the theme and background builders: names, values in order, descs', function()
	local st = fresh()
	local generators = st.Config.generators

	local function listed(option)
		local root, row = make('look', option)
		local out = {}
		for _, entry in ipairs(OM.Values(root, row)) do
			out[#out + 1] = entry.key .. '=' .. entry.name
		end
		return table.concat(out, ';')
	end

	local theme = generators.theme(3, 'The bags and bank windows.')
	eq(theme.type, 'select', 'Theme is a select')
	eq(theme.name, 'Theme', 'named Theme')
	eq(theme.order, 3, 'its order')
	eq(theme.width, nil, 'no Ace width')
	eq(listed(theme), "theme=Use SaftUI's theme;thick=Thick;thin=Thin;none=None", 'its values, in order')
	eq(theme.desc, "The bags and bank windows. Use SaftUI's theme follows Global Settings → Theme; None draws no border or background.",
		"the caller's desc, then what the choices do")

	local background = generators.background(4)
	eq(background.type, 'select', 'Background is a select')
	eq(background.name, 'Background', 'named Background')
	eq(background.order, 4, 'its order')
	eq(background.width, nil, 'no Ace width')
	eq(listed(background), "theme=Use SaftUI's theme;solid=Solid;transparent=Transparent", 'its values, in order')
	eq(background.desc, "Solid, or see-through by Global Settings → Theme's Opacity. Use SaftUI's theme follows its Transparent background.",
		'its desc by default')
	eq(generators.background(4, 'Own words.').desc, 'Own words.', "a caller's desc instead")

	-- Each option has its own tables, so a page changing one changes no other.
	check(generators.theme(1, 'x').values ~= theme.values, 'fresh values each time')
end)
