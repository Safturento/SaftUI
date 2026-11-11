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
--     Core's widgets (Widgets/button.lua, scrollbar.lua, statusbar.lua,
--     radiogroup.lua), which draw a Theme and Background as their kind;
--   - edit mode's movers, and Core's widgets that color their own backdrops
--     (a scroll bar thumb, a radio group's pick, a focused edit box), which
--     keep their colors through a recolor;
--   - the Theme and Background option builders (Config/widgets.lua), and no
--     desc with an arrow SaftUI's fonts may not draw.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 with Core's helpers and
-- edit mode (config_helpers.lua), the options model, widgets, body and window,
-- and Widgets/scrollbar.lua, statusbar.lua and radiogroup.lua, with a stand-in
-- for Blizzard's MinimalScrollBar (scrollBar below). Each case starts from a fresh
-- world, since cases change the profile's theme. The kind a frame was drawn
-- with changes nothing under Thick and Thin, so the draw calls are watched
-- (tests/lib/theme_helpers.lua's T.watch: they note their arguments, and still
-- draw).
local T = load_test_file('lib/theme_helpers.lua')
local text, fill, edge, inset, offset = T.text, T.fill, T.edge, T.inset, T.offset

local OM, W, OW

-- A fresh world, with Core's draw calls watched: drawn(frame) is the theme,
-- background and kind frame was last drawn with, as 'theme,background,kind'
-- ('nil' for what wasn't passed), or nil if it wasn't.
local drawn
local function fresh()
	reset_world()
	load_test_file('core/config_helpers.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_saftui('SaftUI-Core/Config/optionswindow.lua')
	load_saftui('SaftUI-Core/Widgets/scrollbar.lua')
	load_saftui('SaftUI-Core/Widgets/statusbar.lua')
	load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
	local st = SaftUI
	OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow
	drawn = T.watch()
	return st
end

local function alpha(f) return text(select(4, f:GetBackdropColor())) end

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

-- A profile switch, copy or reset is a theme change when the profiles' themes
-- differ (ruling R13): Config:UpdateConfig redraws every drawn frame before the
-- modules update, and ends with ColorsChanged('theme').
test('a profile switch to a profile with another theme redraws what was drawn once, with no reload, and back', function()
	local st = fresh()
	local EM = st.EditModeFrames
	-- Drawn once, when made: a window's panel and header strip, a Core button
	-- and the /sui window.
	local panel = frame(st, 'Frame', 'ThemeTestSwitchPanel')
	st:SetBackdrop(panel, 'theme', 'theme', 'panel')
	st:CreateHeader(panel, 'Title')
	local button = st:CreateButton('ThemeTestSwitchButton', UIParent, 'x')
	button:SetSize(80, 20)
	button:SetPoint('CENTER')
	st.Config:Open()
	local window = OW.GetFrames().window
	-- A mover colors its own line: the selected one blue.
	local position = { point = 'CENTER', x_off = 0, y_off = 0 }
	local mover = st:RegisterMover('theme_switch', {
		frame = frame(st),
		getPosition = function() return position end,
		setPosition = function(pos) position = pos end,
		apply = function() end,
	})
	EM:Select(mover)
	local blue = text(st.config.profile.colors.button.blue:GetRGB())

	local function looks(theme, edgeColor, header)
		local px = theme == 'thin' and 1 or 2
		local out = ('%d.00,%d.00'):format(-px, px)
		eq(inset(panel.backdrop), px, theme .. ": the panel's border")
		eq(offset(panel.backdrop, 'TOPLEFT'), out, theme .. ': the panel sits its border outside the window')
		eq(edge(panel.backdrop), edgeColor, theme .. ": the panel's border color")
		eq(fill(panel.header), header, theme .. ": the header strip, the theme's border color at 0.4")
		eq(inset(button.backdrop), px, theme .. ": the button's border")
		eq(offset(button.backdrop, 'TOPLEFT'), out, theme .. ': the button sits its border outside it')
		eq(edge(button.backdrop), edgeColor, theme .. ": the button's border color")
		eq(inset(window), px, theme .. ": the /sui window's border")
		eq(edge(window), edgeColor, theme .. ": the /sui window's border color")
		eq(alpha(window), '1.00', theme .. ': the /sui window stays solid')
		eq(inset(mover.overlay.backdrop), px, theme .. ": the mover's outline at the theme's border")
		eq(edge(mover.overlay.backdrop), blue .. ',1.00', theme .. ': the selected mover keeps its blue line')
		eq(fill(mover.overlay.backdrop), blue .. ',0.15', theme .. ': and its blue tint')
	end
	looks('thick', THICK_EDGE, '0.30,0.30,0.30,0.40')

	-- A profile saved with the Thin theme.
	local first = st.config:GetCurrentProfile()
	SaftUI_DB.profiles.ThemeTestThin = { theme = { name = 'thin' } }
	st.config:SetProfile('ThemeTestThin')
	looks('thin', THIN_EDGE, '0.00,0.00,0.00,0.40')

	st.config:SetProfile(first)
	looks('thick', THICK_EDGE, '0.30,0.30,0.30,0.40')

	-- A copy of the Thin profile into this one is a theme change too.
	st.config:CopyProfile('ThemeTestThin')
	looks('thin', THIN_EDGE, '0.00,0.00,0.00,0.40')
	-- And a reset, back to the default Thick.
	st.config:ResetProfile()
	looks('thick', THICK_EDGE, '0.30,0.30,0.30,0.40')

	EM:Select(nil)
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile switch in combat redraws once combat ends, once, with the colors after it', function()
	local st = fresh()
	local panel = frame(st, 'Frame', 'ThemeTestCombatPanel')
	st:SetBackdrop(panel, 'theme', 'theme', 'panel')
	local log = {}
	local redraw, colors = st.RedrawThemed, st.ColorsChanged
	st.RedrawThemed = function(...) log[#log + 1] = 'RedrawThemed'; return redraw(...) end
	st.ColorsChanged = function(self, group)
		if group == 'theme' then log[#log + 1] = 'ColorsChanged(theme)' end
		return colors(self, group)
	end

	local first = st.config:GetCurrentProfile()
	SaftUI_DB.profiles.ThemeTestThin = { theme = { name = 'thin' } }
	stub.in_combat = true
	st.config:SetProfile('ThemeTestThin')
	st.config:SetProfile(first)
	st.config:SetProfile('ThemeTestThin')
	eq(table.concat(log, ','), '', 'nothing redrawn in combat')
	eq(inset(panel.backdrop), 2, 'the panel keeps its border until then')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(table.concat(log, ','), 'RedrawThemed,ColorsChanged(theme)', 'one redraw after combat, then the colors')
	eq(inset(panel.backdrop), 1, "then the Thin profile's border")
	st.RedrawThemed, st.ColorsChanged = redraw, colors
	eq(#take_errors(), 0, 'no errors')
end)

-- The redraw and the colors after it are two steps, each run on its own: a
-- redraw that errors is reported, and modules still color what they color
-- themselves. In and out of combat alike.
test('a profile switch whose redraw errors still recolors after it, in and out of combat', function()
	local st = fresh()
	local log = {}
	local redraw, colors = st.RedrawThemed, st.ColorsChanged
	-- The real redraw, then an error after it.
	st.RedrawThemed = function(...)
		log[#log + 1] = 'RedrawThemed'
		redraw(...)
		error('the redraw failed')
	end
	st.ColorsChanged = function(self, group)
		if group == 'theme' then log[#log + 1] = 'ColorsChanged(theme)' end
		return colors(self, group)
	end
	local function reported(label)
		local errors = take_errors()
		eq(#errors, 1, label .. ": the redraw's error is reported")
		check(tostring(errors[1]):find('the redraw failed', 1, true) ~= nil, label .. ": it is the redraw's: " .. tostring(errors[1]))
	end

	local first = st.config:GetCurrentProfile()
	SaftUI_DB.profiles.ThemeTestThin = { theme = { name = 'thin' } }
	st.config:SetProfile('ThemeTestThin')
	eq(table.concat(log, ','), 'RedrawThemed,ColorsChanged(theme)', 'out of combat: the colors still go back on')
	reported('out of combat')

	for i = #log, 1, -1 do log[i] = nil end
	stub.in_combat = true
	st.config:SetProfile(first)
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(table.concat(log, ','), 'RedrawThemed,ColorsChanged(theme)', 'after combat: the colors still go back on')
	reported('after combat')
	st.RedrawThemed, st.ColorsChanged = redraw, colors
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
	-- The row's left and top are the scroll area's, which cuts what lies past
	-- them: the icon sits the border's width in from the row's corner, so the
	-- border starts on them, not outside.
	eq(offset(image, 'TOPLEFT'), '2.00,-2.00', "the icon Thick's 2px in from the row's corner")

	-- A recolor and a redraw reach it.
	st.config.profile.templates.thick.bordercolor = { 1, 0, 0, 1 }
	st:RecolorThemed()
	eq(edge(backdrop), '1.00,0.00,0.00,1.00', 'a recolor gives it the new border color')
	switch(st, 'thin')
	eq(offset(backdrop, 'TOPLEFT'), '-1.00,1.00', "a switch to Thin moves it to Thin's 1px")
	eq(edge(backdrop), THIN_EDGE, "with Thin's border color")
	-- The theme is picked on the Theme tab: back on General, the row is drawn
	-- again, its icon 1px in.
	st.Config:Close()
	st.Config:Open('Fonts', 'general')
	preview = drawnRow('icon_preview').widget
	eq(offset(preview.image, 'TOPLEFT'), '1.00,-1.00', "the icon Thin's 1px in from the row's corner")
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

test('st:SkinActionButton draws config.theme and config.background as its kind', function()
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

	-- A config with no Theme or Background follows SaftUI's theme; an old
	-- template key is nothing to it.
	local n = button('ThemeTestNoTheme')
	st:SkinActionButton(n, { template = 'thin' })
	eq(drawn(n), 'nil,nil,action', 'drawn as an action button, with nothing to override the theme')
	eq(inset(n.backdrop), 2, "SaftUI's theme: Thick")
	eq(fill(n.backdrop), '0.12,0.12,0.12,0.90', "and its background, at the opacity")
	local none = button('ThemeTestNone')
	st:SkinActionButton(none, { theme = 'none', background = 'theme' })
	eq(none.backdrop, nil, 'None: no backdrop')

	-- trueSize still fills the button with its backdrop.
	local t = button('ThemeTestTrueSize')
	st:SkinActionButton(t, { theme = 'theme', background = 'theme', trueSize = true })
	eq(offset(t.backdrop, 'TOPLEFT'), '0.00,0.00', 'trueSize: the backdrop fills the button')
	switch(st, 'thin')
	eq(offset(t.backdrop, 'TOPLEFT'), '0.00,0.00', 'and a redraw leaves it there')
	eq(offset(a.backdrop, 'TOPLEFT'), '-1.00,1.00', 'a Thin override stays Thin')
	eq(offset(s.backdrop, 'TOPLEFT'), '-1.00,1.00', "the theme's slot moves to Thin's 1px")
end)

test('st:SkinEditBox and st:StyleEditBox take a Theme, a Background and a font', function()
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
	local t = frame(st, 'EditBox', 'ThemeTestEditTheme')
	st:SkinEditBox(t, 'thin')
	eq(drawn(t), 'thin,solid,small', 'a Theme with no Background: Solid')

	-- The font is the fourth argument.
	local o = frame(st, 'EditBox', 'ThemeTestEditFont')
	local words = o:CreateFontString(nil, 'OVERLAY') -- the box's text, its first region
	st:SkinEditBox(o, 'thin', 'transparent', 'pixel')
	eq(drawn(o), 'thin,transparent,small', 'Theme and Background')
	check(words:GetFontObject() == st:GetFont('pixel'), 'and its font')
	st:StyleEditBox(o, 'thick', 'solid', 'normal')
	eq(drawn(o), 'thick,solid,small', 'StyleEditBox: the new Theme and Background')
	eq(alpha(o.backdrop), '1.00', 'solid')
	check(words:GetFontObject() == st:GetFont('normal'), 'with its font')

	-- A box drawn with None errors on nothing when it takes focus.
	local n = frame(st, 'EditBox', 'ThemeTestEditNone')
	st:SkinEditBox(n, 'none', 'theme')
	eq(n.backdrop, nil, 'None: no backdrop')
	n:SetFocus()
	n:ClearFocus()
	eq(#take_errors(), 0, 'focus and losing it raise no error')
end)

------------------------------------------------------------------ widgets

test("Core's buttons and status bars draw a Theme and Background as their kind", function()
	local st = fresh()
	local b = st:CreateButton('ThemeTestButton', UIParent, 'x')
	eq(drawn(b), 'theme,solid,small', "no theme: Use SaftUI's theme and Solid (it was thick)")
	eq(alpha(b.backdrop), '1.00', 'solid')
	eq(edge(b.backdrop), THICK_EDGE, "the theme's (Thick's) border")
	local t = st:CreateButton(nil, UIParent, 'x', 'thin', 'transparent')
	eq(drawn(t), 'thin,transparent,small', 'Theme and Background')
	local o = st:CreateButton(nil, UIParent, 'x', 'thin')
	eq(drawn(o), 'thin,solid,small', 'a Theme with no Background: Solid')
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
	eq(drawn(obar), 'thick,solid,bar', 'a status bar with a Theme and no Background: Solid')

	-- A switch moves what follows the theme and leaves an override as it is.
	switch(st, 'thin')
	eq(offset(b.backdrop, 'TOPLEFT'), '-1.00,1.00', "the button moves to Thin's 1px")
	eq(offset(bar.backdrop, 'TOPLEFT'), '-1.00,1.00', 'the status bar too')
	eq(inset(obar.backdrop), 2, 'a Thick status bar still draws Thick')
end)

test('a radio group draws its buttons with options.theme and options.background', function()
	local st = fresh()
	local function group(name, options)
		options.buttonHeight, options.buttonWidth, options.buttonSpacing = 20, 50, 2
		options.items = { { label = 'A' }, { label = 'B' } }
		return st:CreateRadioGroup(name, UIParent, options)
	end
	local blue = text(st.config.profile.colors.button.blue:GetRGB()) .. ',1.00'

	local g = group('ThemeTestRadio', { theme = 'thin', background = 'solid' })
	eq(g.backdrop, nil, 'the group itself draws nothing, as before')
	eq(drawn(g.buttons[1]), 'thin,solid,small', 'its buttons start with the Theme and Background, before any click')
	stub.fire_script(g.buttons[2], 'OnClick', 'LeftButton', false)
	eq(drawn(g.buttons[1]), 'thin,solid,small', 'a click draws the buttons with the Theme and Background')
	eq(edge(g.buttons[2].backdrop), blue, 'and the clicked one blue')

	local d = group('ThemeTestRadioDefault', {})
	eq(drawn(d.buttons[1]), 'theme,solid,small', "no Theme or Background: Use SaftUI's theme, Solid")
	stub.fire_script(d.buttons[1], 'OnClick', 'LeftButton', false)
	eq(drawn(d.buttons[2]), 'theme,solid,small', 'and the same after a click')
end)

-- Blizzard's MinimalScrollBar, as far as st:SkinNewScrollBar uses it: its
-- thumb, track and steppers (frames of its own in game too). In game it also
-- scrolls, sizes the thumb and steps; nothing here needs that.
local function scrollBar()
	local bar = CreateFrame('Frame', nil, UIParent)
	local parts = {}
	for _, key in ipairs({ 'thumb', 'track', 'forward', 'back' }) do
		parts[key] = CreateFrame('Button', nil, bar)
		parts[key]:SetSize(8, 20)
		parts[key]:SetPoint('CENTER')
	end
	function bar:GetThumb() return parts.thumb end
	function bar:GetTrack() return parts.track end
	function bar:GetForwardStepper() return parts.forward end
	function bar:GetBackStepper() return parts.back end
	return bar
end

test("Core widgets keep their own colors through a recolor: a scroll bar thumb's fill, a radio group's picked button, a focused edit box", function()
	local st = fresh()
	local colors = st.config.profile.colors.button
	local function rgb(f)
		local r, g, b = f:GetBackdropColor()
		return text(r, g, b)
	end
	local function color(c) return text(c:GetRGB()) end
	local thick = st.config.profile.templates.thick
	local shade = 0
	-- A new background and border for Thick, then a recolor, as the Theme tab's pickers do.
	local function recolor()
		shade = shade + 0.1
		thick.backdropcolor = { shade, 0.5, 0.5, 1 }
		thick.bordercolor = { 1, 0, shade, 1 }
		st:RecolorThemed()
	end

	-- The scroll bar thumb: normal, hover under the mouse, pushed while pressed.
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = bar:GetThumb()
	eq(drawn(thumb), 'theme,solid,small', "the thumb: SaftUI's theme, Solid")
	eq(rgb(thumb.backdrop), color(colors.normal), 'the thumb in the button color')
	recolor()
	eq(rgb(thumb.backdrop), color(colors.normal), 'after a recolor, still the button color')
	stub.fire_script(thumb, 'OnEnter')
	recolor()
	eq(rgb(thumb.backdrop), color(colors.hover), 'under the mouse, after a recolor: the hover color')
	stub.fire_script(thumb, 'OnMouseDown')
	recolor()
	eq(rgb(thumb.backdrop), color(colors.pushed), 'pressed, after a recolor: the pushed color')
	stub.fire_script(thumb, 'OnMouseUp')
	stub.fire_script(thumb, 'OnLeave')
	recolor()
	eq(rgb(thumb.backdrop), color(colors.normal), 'let go and left, after a recolor: the button color')

	-- A radio group's picked button keeps its blue border; the others take the theme's.
	local blue = text(colors.blue:GetRGB()) .. ',1.00'
	local g = st:CreateRadioGroup('ThemeTestRadioColors', UIParent, {
		buttonHeight = 20, buttonWidth = 50, buttonSpacing = 2, theme = 'theme', background = 'theme',
		items = { { label = 'A' }, { label = 'B' } },
	})
	stub.fire_script(g.buttons[2], 'OnClick', 'LeftButton', false)
	recolor()
	eq(edge(g.buttons[2].backdrop), blue, 'the picked button stays blue through a recolor')
	eq(edge(g.buttons[1].backdrop), text(unpack(thick.bordercolor)), "the other takes the theme's new border")
	stub.fire_script(g.buttons[1], 'OnClick', 'LeftButton', false)
	recolor()
	eq(edge(g.buttons[1].backdrop), blue, 'a new pick: blue through a recolor')
	eq(edge(g.buttons[2].backdrop), text(unpack(thick.bordercolor)), "the old pick takes the theme's border")

	-- A focused edit box keeps its white border, and takes the theme's once it loses focus.
	local e = frame(st, 'EditBox', 'ThemeTestEditColors')
	st:SkinEditBox(e, 'theme', 'theme')
	e:SetFocus()
	recolor()
	eq(edge(e.backdrop), '1.00,1.00,1.00,1.00', 'focused: white through a recolor')
	e:ClearFocus()
	recolor()
	eq(edge(e.backdrop), text(unpack(thick.bordercolor)), "unfocused: the theme's new border")

	-- A theme switch (st:ThemeChanged: a redraw, then OnColorsChanged('theme')) keeps them too.
	stub.fire_script(thumb, 'OnEnter')
	e:SetFocus()
	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()
	st:ColorsChanged('theme')
	eq(rgb(thumb.backdrop), color(colors.hover), 'a switch to Thin: the thumb keeps its hover color')
	eq(edge(g.buttons[1].backdrop), blue, 'the picked button stays blue')
	eq(edge(e.backdrop), '1.00,1.00,1.00,1.00', 'the focused edit box stays white')
	e:ClearFocus()
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
	eq(listed(theme), "theme=Use SaftUI's theme;thick=Thick;thin=Thin;blizzard=Blizzard;none=None", 'its values, in order')
	eq(theme.desc, "The bags and bank windows. Use SaftUI's theme follows Global Settings > Theme; None draws no border or background.",
		"the caller's desc, then what the choices do")

	local background = generators.background(4)
	eq(background.type, 'select', 'Background is a select')
	eq(background.name, 'Background', 'named Background')
	eq(background.order, 4, 'its order')
	eq(background.width, nil, 'no Ace width')
	eq(listed(background), "theme=Use SaftUI's theme;solid=Solid;transparent=Transparent", 'its values, in order')
	eq(background.desc, "Solid, or see-through by Global Settings > Theme's Opacity. Use SaftUI's theme follows its Transparent background.",
		'its desc by default')
	eq(generators.background(4, 'Own words.').desc, 'Own words.', "a caller's desc instead")

	-- Each option has its own tables, so a page changing one changes no other.
	check(generators.theme(1, 'x').values ~= theme.values, 'fresh values each time')
end)

test('no desc in /sui, nor the Theme and Background builders, has an arrow', function()
	local st = fresh()
	load_test_file('core/options_walk.lua')
	local ARROW = '\226\134\146' -- U+2192, which SaftUI's fonts may not have
	local found = {}
	local function look(where, desc)
		if type(desc) == 'string' and desc:find(ARROW, 1, true) then found[#found + 1] = where end
	end
	each_option({ type = 'group', args = st.Config:GetOptionsTable() }, function(option, path)
		if type(option) == 'table' then
			look(table.concat(path, '.'), option.desc)
			look(table.concat(path, '.') .. ' (name)', option.name)
		end
	end)
	local generators = st.Config.generators
	look('generators.theme', generators.theme(1).desc)
	look('generators.theme with a desc', generators.theme(1, 'x').desc)
	look('generators.background', generators.background(1).desc)
	eq(table.concat(found, '; '), '', 'no arrow anywhere')
	check(generators.theme(1).desc:find('Global Settings > Theme', 1, true) ~= nil, "Theme's desc says Global Settings > Theme")
	check(generators.background(1).desc:find('Global Settings > Theme', 1, true) ~= nil, "Background's desc says Global Settings > Theme")
end)
