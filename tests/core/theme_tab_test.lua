-- The Theme tab of Global settings (SaftUI-Core/Media/theme.lua): Theme and the
-- chosen theme's colors (Border, Outer border and Background; under Blizzard
-- Window background in place of Outer border), each with its own reset (the
-- options kit's default field: OM.DefaultState, OM.DefaultReset) in place of
-- the tab's old Reset. Background has an
-- opacity: its alpha is the profile's theme.transparent and theme.opacity
-- (100% is a solid background, anything under it see-through at that opacity),
-- which profiles saved before the merge already hold. A
-- color or the opacity recolors every drawn frame (st:RecolorThemed); the
-- theme and a switch between solid and see-through also move borders, so they run st:ThemeChanged
-- (redraw, then every module's UpdateConfig, then ColorsChanged('theme')).
-- Both wait for the end of combat, with one pending run. tests/core/
-- theme_test.lua checks the engine; this checks the tab's rows.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua, with
-- Media/theme.lua among Core's helpers) and the options model the window
-- reads rows with.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local OM = st.OptionsModel

local function Tab() return st.Config:GetOptionsTable().Fonts.args.theme end

local function ByOrder(t)
	local out = {}
	for key, v in pairs(t) do out[#out + 1] = { key = key, v = v } end
	table.sort(out, function(a, b) return a.v.order < b.v.order end)
	return out
end

-- The model's row for key, and the tree it's in. Hidden rows aren't in the view.
local function Row(key)
	local root = st.Config:GetOptionsTable()
	for _, section in ipairs(OM.BuildView(root, 'Fonts', { tab = 'theme' }).sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
end

local function Get(key) local root, row = Row(key); return OM.Get(root, row) end
local function Set(key, ...) local root, row = Row(key); return OM.Set(root, row, ...) end

-- The Background color's alpha written alone (its rgb as it is), and its rgb
-- written with the alpha it has. What the old toggle and slider did.
local function SetAlpha(a)
	local r, g, b = Get('background')
	Set('background', r, g, b, a)
end

local function Rgb(c) return table.concat({ c[1], c[2], c[3] }, ',') end

-- Counts calls to st[name] (or st.Config[name]) while running fn, and logs
-- them into log in call order.
local function Spy(owner, name, log, label)
	local real = owner[name]
	owner[name] = function(...)
		log[#log + 1] = label or name
		return real(...)
	end
	return function() owner[name] = real end
end

test('the Theme tab sits between Colors and Edit mode', function()
	local root = st.Config:GetOptionsTable()
	local view = OM.BuildView(root, 'Fonts')
	local keys = {}
	for i, tab in ipairs(view.tabs) do keys[i] = tab.key end
	eq(table.concat(keys, ','), 'general,fonts,colors,theme,editmode')
	eq(root.Fonts.args.theme.name, 'Theme')
	eq(root.Theme, nil, 'no Theme page in the tree')
	eq(root.Fonts.desc, "Settings used across SaftUI: icon zoom and window title bars, fonts, colors, themes, and edit mode's grid and snapping.")
end)

test('its rows, in order, with descs', function()
	local rows = ByOrder(Tab().args)
	local names, types = {}, {}
	for i, r in ipairs(rows) do
		names[i], types[i] = r.v.name, r.v.type
		local desc = type(r.v.desc) == 'function' and r.v.desc() or r.v.desc
		-- Window titles is a section: its Font row has the desc.
		if r.v.type ~= 'group' then check(type(desc) == 'string' and desc ~= '', r.v.name .. ' has a desc') end
		eq(r.v.width, nil, r.v.name .. ' has no Ace width')
	end
	eq(table.concat(names, ','), 'Theme,Border,Outer border,Window background,Background,Options windows,Window titles', 'no Reset row')
	eq(table.concat(types, ','), 'select,color,color,color,color,select,group')

	local theme = rows[1].v
	eq(theme.values.thick, 'Thick'); eq(theme.values.thin, 'Thin')
	eq(theme.values.blizzard, 'Blizzard')
	eq(theme.values.none, nil, 'None is a module override, not a theme to choose')
	eq(theme.default, nil, 'Theme itself has no reset')
	for i = 2, 5 do
		local d = rows[i].v.default
		check(type(d) == 'table' and d.differs and d.reset and d.value, rows[i].v.name .. ' has its own reset')
	end
	for i = 2, 4 do
		eq(rows[i].v.hasAlpha, nil, rows[i].v.name .. ' has no opacity slider')
	end
	check(rows[5].v.hasAlpha, 'Background has an opacity: its bar reads #RRGGBB · 85%')
	for _, r in ipairs(rows) do
		check(not (r.v.name == 'Transparent background' or r.v.name == 'Opacity'), 'no ' .. r.v.name .. ' row')
	end
end)

test('the Theme tab offers Thick, Thin and Blizzard, in that order', function()
	local theme = Tab().args.theme
	eq(table.concat(theme.sorting, ','), 'thick,thin,blizzard')
	eq(theme.values.thick .. theme.values.thin .. theme.values.blizzard, 'ThickThinBlizzard')
end)

test("under Blizzard, Window background shows and Outer border hides, and the color rows say what they color there", function()
	local function Descs()
		local _, border = Row('border')
		local _, back = Row('background')
		local _, window = Row('windowcolor')
		return border.desc, back.desc, window and window.desc
	end
	st.config.profile.theme.name = 'thick'
	eq(Row('windowcolor'), nil, 'hidden for Thick')
	local thickBorder, thickBack = Descs()
	st.config.profile.theme.name = 'thin'
	eq(Row('windowcolor'), nil, 'hidden for Thin')

	Set('theme', 'blizzard')
	check(Row('windowcolor'), 'shown for Blizzard')
	eq(Row('outer'), nil, 'Outer border hidden')
	check(Row('border') and Row('background'), 'Border and Background stay')
	local border, back, window = Descs()
	check(border ~= thickBorder, "Border's desc differs from Thick's")
	check(back ~= thickBack, "Background's desc differs from Thick's")
	check(window and window ~= back, "Window background has its own desc")

	local log, restore = {}, {}
	restore[1] = Spy(st, 'RecolorThemed', log)
	restore[2] = Spy(st.Config, 'UpdateConfig', log)
	local arr = st.config.profile.templates.blizzard.windowcolor
	local alpha = arr[4]
	Set('windowcolor', 0.2, 0.3, 0.4)
	for _, r in ipairs(restore) do r() end
	eq(table.concat(log, ','), 'RecolorThemed', 'recolors, no config update')
	check(st.config.profile.templates.blizzard.windowcolor == arr, 'the same array')
	eq(Rgb(arr), '0.2,0.3,0.4'); eq(arr[4], alpha, 'its alpha stays')
	eq(table.concat({ Get('windowcolor') }, ','), '0.2,0.3,0.4')
	Set('theme', 'thick')
end)

test('each theme keeps its own colors, Blizzard too', function()
	Set('theme', 'thick')
	Set('border', 0.61, 0.62, 0.63)
	Set('theme', 'blizzard')
	Set('border', 0.71, 0.72, 0.73)
	eq(Rgb(st.config.profile.templates.blizzard.bordercolor), '0.71,0.72,0.73')
	Set('theme', 'thick')
	eq(Rgb({ Get('border') }), '0.61,0.62,0.63', "Thick's is the one set")
	eq(Rgb(st.config.profile.templates.thick.bordercolor), '0.61,0.62,0.63')
	Set('theme', 'blizzard')
	eq(Rgb({ Get('border') }), '0.71,0.72,0.73', "and Blizzard's is its own")
	Set('theme', 'thick')
end)

-- A row's own reset through the model, as the window's icon runs it.
local function Differs(key) local root, row = Row(key); return OM.DefaultState(root, row).differs end
local function Reset(key) local root, row = Row(key); return OM.DefaultReset(root, row) end

test("under Blizzard each color's own reset restores Blizzard's, windowcolor among them; Background's the transparency too", function()
	Set('theme', 'blizzard')
	for _, key in ipairs({ 'border', 'windowcolor', 'background' }) do
		Reset(key) -- whatever the cases before left
		check(not Differs(key), key .. ': at its default')
		Set(key, 0.9, 0.9, 0.9)
		check(Differs(key), key .. ': differs once set')
	end
	SetAlpha(1)
	SetAlpha(0.2)
	local d, p = st.defaults.templates.blizzard, st.config.profile.templates.blizzard
	for key, stored in pairs({ border = 'bordercolor', windowcolor = 'windowcolor', background = 'backdropcolor' }) do
		eq(Reset(key), true, key .. ': its reset runs')
		eq(table.concat(p[stored], ','), table.concat(d[stored], ','), 'Blizzard ' .. stored)
		check(not Differs(key), key .. ': no longer differs')
	end
	eq(st.config.profile.theme.transparent, st.defaults.theme.transparent, "Background's reset: the transparency")
	eq(st.config.profile.theme.opacity, st.defaults.theme.opacity, 'and the opacity')
	eq(st.config.profile.theme.name, 'blizzard', 'the theme itself stays')
	Set('theme', 'thick')
end)

test('Outer border shows only for Thick', function()
	st.config.profile.theme.name = 'thick'
	check(Row('outer'), 'shown for Thick')
	st.config.profile.theme.name = 'thin'
	eq(Row('outer'), nil, 'hidden for Thin')
	st.config.profile.theme.name = 'thick'
end)

-- The Background color's alpha is what the old toggle and slider drew: a
-- profile with the toggle off is solid (100%), with it on at its Opacity.
test("Background's alpha reads the profile's old toggle and opacity, so a saved profile draws as it did", function()
	local theme = st.config.profile.theme
	theme.transparent, theme.opacity = false, 0.6
	local _, _, _, a = Get('background')
	eq(a, 1, 'toggle off: solid, whatever the saved opacity')
	eq(st:ResolveTheme().alpha, 1, 'and the engine draws it solid')

	theme.transparent = true
	_, _, _, a = Get('background')
	eq(a, 0.6, 'toggle on: its opacity')
	eq(st:ResolveTheme().alpha, 0.6, 'and the engine draws it at that')

	theme.transparent, theme.opacity = true, 0.9
	local r, g, b
	r, g, b, a = Get('background')
	eq(Rgb({ r, g, b }), Rgb(st.config.profile.templates[st:ResolveTheme().name].backdropcolor), 'its rgb is the theme backdrop color')
	eq(a, 0.9)
end)

test("a Background alpha under 100% sets the toggle on at that opacity; 100% sets it off and keeps the opacity", function()
	local theme = st.config.profile.theme
	theme.transparent, theme.opacity = false, 0.9
	local r, g, b = Get('background')
	Set('background', r, g, b, 0.55)
	eq(theme.transparent, true); eq(theme.opacity, 0.55)
	eq(st:ResolveTheme().alpha, 0.55)
	Set('background', r, g, b, 1)
	eq(theme.transparent, false, 'solid')
	eq(theme.opacity, 0.55, 'the opacity is kept for the profile that reads it')
	eq(st:ResolveTheme().alpha, 1)
	-- A set with no alpha (a caller that passes rgb only) leaves it alone.
	Set('background', 0.3, 0.3, 0.3)
	eq(theme.transparent, false); eq(theme.opacity, 0.55)
	theme.transparent, theme.opacity = true, 0.9
end)

test('Background shows its alpha in its hex text and writes the three color channels in place', function()
	Set('theme', 'thick')
	local arr = st.config.profile.templates.thick.backdropcolor
	local alpha = arr[4]
	Set('background', 0.1, 0.2, 0.3, 0.7)
	check(st.config.profile.templates.thick.backdropcolor == arr, 'the same array')
	eq(Rgb(arr), '0.1,0.2,0.3'); eq(arr[4], alpha, "the array's own alpha stays; the opacity is the theme's")
	st.config.profile.theme.transparent, st.config.profile.theme.opacity = true, 0.9
end)

test('each theme keeps its own colors', function()
	local thickBorder = Rgb(st.defaults.templates.thick.bordercolor)
	Set('theme', 'thick')
	Set('border', 0.1, 0.2, 0.3)
	Set('theme', 'thin')
	eq(Rgb(st.config.profile.templates.thin.bordercolor), Rgb(st.defaults.templates.thin.bordercolor), 'Thin untouched by the Thick edit')
	Set('border', 0.4, 0.5, 0.6)
	eq(table.concat({ Get('border') }, ','), '0.4,0.5,0.6', 'the row shows the chosen theme')
	Set('theme', 'thick')
	eq(table.concat({ Get('border') }, ','), '0.1,0.2,0.3', "Thick's is the one set")
	eq(Rgb(st.config.profile.templates.thin.bordercolor), '0.4,0.5,0.6')
	check(thickBorder ~= '0.1,0.2,0.3')
	eq(#st.config.profile.templates.thick.bordercolor, 4, 'the array keeps its alpha')
end)

test('Outer border and Background edit the chosen theme in place', function()
	Set('theme', 'thick')
	local arr = st.config.profile.templates.thick.altbordercolor
	Set('outer', 0.7, 0.8, 0.9)
	check(st.config.profile.templates.thick.altbordercolor == arr, 'the same array')
	eq(Rgb(arr), '0.7,0.8,0.9')
	local back = st.config.profile.templates.thick.backdropcolor
	local alpha = back[4]
	Set('background', 0.01, 0.02, 0.03)
	eq(Rgb(back), '0.01,0.02,0.03'); eq(back[4], alpha, 'its alpha stays')
end)

test('a color set recolors without a config update', function()
	local log, restore = {}, {}
	restore[1] = Spy(st, 'RecolorThemed', log)
	restore[2] = Spy(st.Config, 'UpdateConfig', log)
	Set('border', 0.2, 0.2, 0.2)
	SetAlpha(0.5)
	for _, r in ipairs(restore) do r() end
	eq(table.concat(log, ','), 'RecolorThemed,RecolorThemed')
	eq(st.config.profile.theme.opacity, 0.5)
end)

test('a theme or toggle switch runs ThemeChanged: the profile update, which redraws first, then updates the modules, then ColorsChanged(theme)', function()
	-- A module, so the log shows where the modules update.
	local probe = st:NewModule('ThemeTabProbe')
	local log, restore = {}, {}
	function probe:UpdateConfig() log[#log + 1] = 'module' end
	restore[1] = Spy(st, 'RedrawThemed', log)
	restore[2] = Spy(st.Config, 'UpdateConfig', log)
	local real = st.ColorsChanged
	st.ColorsChanged = function(_, group) log[#log + 1] = 'ColorsChanged(' .. group .. ')'; return real(st, group) end
	local recolor = Spy(st, 'RecolorThemed', log)

	-- st:ThemeChanged is Config:UpdateConfig, the profile update, which
	-- redraws once before any module lays itself out around the new border.
	Set('theme', 'thin')
	eq(table.concat(log, ','), 'UpdateConfig,RedrawThemed,module,ColorsChanged(theme)', 'a theme switch')
	eq(st.config.profile.theme.name, 'thin')

	for i = #log, 1, -1 do log[i] = nil end
	SetAlpha(1)
	eq(table.concat(log, ','), 'UpdateConfig,RedrawThemed,module,ColorsChanged(theme)', 'going solid, the old toggle')
	eq(st.config.profile.theme.transparent, false)

	for i = #log, 1, -1 do log[i] = nil end
	SetAlpha(0.8)
	eq(table.concat(log, ','), 'UpdateConfig,RedrawThemed,module,ColorsChanged(theme)', 'going see-through')
	eq(st.config.profile.theme.transparent, true)

	for i = #log, 1, -1 do log[i] = nil end
	SetAlpha(0.7)
	eq(table.concat(log, ','), 'RecolorThemed,ColorsChanged(theme)', 'a new opacity alone only recolors: no redraw, no module update')

	recolor(); restore[1](); restore[2](); st.ColorsChanged = real
	probe.UpdateConfig = nil
	SetAlpha(0.9)
	Set('theme', 'thick')
end)

test('in combat a theme change waits for its end, once', function()
	local log, restore = {}, {}
	restore[1] = Spy(st, 'RedrawThemed', log)
	restore[2] = Spy(st, 'RecolorThemed', log)
	stub.in_combat = true
	Set('theme', 'thin')
	SetAlpha(1)
	Set('border', 0.3, 0.3, 0.3)
	SetAlpha(0.4)
	eq(#log, 0, 'nothing drawn in combat')
	eq(st.config.profile.theme.name, 'thin', 'but the setting is stored')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	table.sort(log)
	eq(table.concat(log, ','), 'RecolorThemed,RedrawThemed', 'one redraw and one recolor')
	for _, r in ipairs(restore) do r() end
	SetAlpha(0.9)
	Set('theme', 'thick')
	eq(#take_errors(), 0, 'no errors')
end)

test("each color's own reset puts back the chosen theme's, recoloring as a set does; Background's opacity alone differs too, and a reset back to see-through redraws", function()
	Set('theme', 'thin')
	Set('border', 0.9, 0.9, 0.9)
	Set('theme', 'thick')
	Set('border', 0.9, 0.9, 0.9)
	Set('outer', 0.5, 0.5, 0.5)
	-- No control sets a theme color's alpha, but its reset puts it back too.
	st.config.profile.templates.thick.bordercolor[4] = 0.5
	local log, restore = {}, {}
	restore[1] = Spy(st, 'RecolorThemed', log)
	restore[2] = Spy(st.Config, 'UpdateConfig', log)
	Reset('border')
	Reset('outer')
	eq(table.concat(log, ','), 'RecolorThemed,RecolorThemed', 'each recolors, no config update')
	local d, p = st.defaults.templates.thick, st.config.profile.templates.thick
	for _, key in ipairs({ 'bordercolor', 'altbordercolor' }) do
		eq(table.concat(p[key], ','), table.concat(d[key], ','), 'Thick ' .. key)
	end
	eq(Rgb(st.config.profile.templates.thin.bordercolor), '0.9,0.9,0.9', "Thin's colors are not touched")

	-- Background: its color as it ships, its opacity changed: it differs.
	Reset('background') -- whatever the cases before left
	check(not Differs('background'), 'Background at its default')
	SetAlpha(0.5)
	check(Differs('background'), 'a new opacity alone differs')
	for i = #log, 1, -1 do log[i] = nil end
	Reset('background')
	eq(table.concat(log, ','), 'RecolorThemed', 'see-through to see-through: a recolor')
	eq(st.config.profile.theme.opacity, st.defaults.theme.opacity, 'the opacity back')
	SetAlpha(1)
	check(Differs('background'), 'solid differs from the see-through default')
	for i = #log, 1, -1 do log[i] = nil end
	Reset('background')
	eq(log[1], 'UpdateConfig', 'solid back to see-through: the profile update, which redraws')
	eq(st.config.profile.theme.transparent, st.defaults.theme.transparent)
	check(not Differs('background'), 'at its default again')
	local root, row = Row('background')
	local value = OM.DefaultState(root, row).value
	eq(value.n, 4, "its default's value: r, g, b and the alpha")
	eq(value[4], st.defaults.theme.opacity, 'the shipped opacity')
	for _, r in ipairs(restore) do r() end
	eq(st.config.profile.theme.name, 'thick', 'the theme itself stays')
end)

test('after a profile switch the rows reach the new profile', function()
	local first = st.config:GetCurrentProfile()
	Set('theme', 'thin')
	Set('border', 0.11, 0.12, 0.13)
	SetAlpha(0.33)
	st.config:SetProfile('ThemeTabTwo')
	eq(Get('theme'), 'thick', "the new profile's theme")
	eq(Rgb({ Get('border') }), Rgb(st.defaults.templates.thick.bordercolor), "the new profile's Thick border")
	eq(select(4, Get('background')), st.defaults.theme.opacity, "the new profile's alpha")

	Set('theme', 'thin')
	Set('border', 0.21, 0.22, 0.23)
	eq(Rgb(st.config.profile.templates.thin.bordercolor), '0.21,0.22,0.23', 'a set reaches the new profile')

	st.config:SetProfile(first)
	eq(Get('theme'), 'thin')
	eq(Rgb({ Get('border') }), '0.11,0.12,0.13', "the first profile's are as they were")
	eq(select(4, Get('background')), 0.33)
end)

-- A profile a later version saved can name a theme this one doesn't have
-- ('later' stands for one): the engine draws it as Thick
-- (tests/core/theme_test.lua), and the tab shows and edits Thick's rows.
test("a saved theme this version doesn't know shows as Thick, and its rows read, set and reset Thick's", function()
	local theme = st.config.profile.theme
	local thick = st.config.profile.templates.thick
	theme.name = 'later'
	local ok, err = pcall(function()
		eq(Get('theme'), 'thick', 'Theme shows Thick, what frames are drawn in')
		eq(Rgb({ Get('border') }), Rgb(thick.bordercolor), "Border reads Thick's")
		check(Row('outer') ~= nil, 'Outer border shows, as for Thick')
		Set('border', 0.31, 0.32, 0.33)
		eq(Rgb(thick.bordercolor), '0.31,0.32,0.33', "a Border set reaches Thick's")
		check(Differs('border'), "Border differs from Thick's default")
		Reset('border')
		eq(Rgb(thick.bordercolor), Rgb(st.defaults.templates.thick.bordercolor), "its reset puts back Thick's")
	end)
	check(ok, 'the rows raise nothing: ' .. tostring(err))
	eq(#take_errors(), 0, 'and report nothing')
	eq(theme.name, 'later', 'the saved name stays until the user picks a theme')
	Set('theme', 'thin')
	eq(theme.name, 'thin', 'picking one saves it')
	Set('theme', 'thick')
end)

local WINDOW_TITLES_DESC = "The titles of SaftUI's windows: the bags and bank, /sui's title bar under the Blizzard theme, and Blizzard's color picker while Skinning dresses it. Every theme uses it."

local function TitleRow() return st.Config:GetOptionsTable().Fonts.args.theme.args.window_titles end

test('Window titles: a section after Options windows with one Font row, saved in headers.font, reset to Text', function()
	local section = TitleRow()
	eq(section.type, 'group'); eq(section.inline, true, 'a section, not a tab')
	eq(section.name, 'Window titles'); eq(section.order, 7, 'after Options windows')
	local keys = {}
	for k in pairs(section.args) do keys[#keys + 1] = k end
	eq(table.concat(keys, ','), 'font', 'one row')
	local font = section.args.font
	eq(font.type, 'font'); eq(font.name, 'Font')
	eq(font.desc, WINDOW_TITLES_DESC)
	eq(font.faceOnly, nil, 'a typeface is allowed')

	-- Its row in the model, after Options windows.
	local root, row = Row('font')
	check(row, 'the model has the row')
	eq(row.path[#row.path - 1], 'window_titles')
	eq(OM.Get(root, row), 'normal', 'headers.font, Text by default')
	check(not Differs('font'), 'at its default')

	OM.Set(root, row, 'subtitle')
	eq(st.config.profile.headers.font, 'subtitle', 'saved where it always was')
	root, row = Row('font')
	local state = OM.DefaultState(root, row)
	eq(state.differs, true); eq(state.text, 'Text', 'the reset names Text')
	local face = { font_name = 'Homespun', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
	OM.Set(root, row, face)
	root, row = Row('font')
	eq(OM.DefaultState(root, row).differs, true, 'a typeface always differs')
	eq(OM.DefaultReset(root, row), true)
	eq(st.config.profile.headers.font, 'normal', 'back to Text')
	check(not Differs('font'), 'and no longer differs')
	eq(#take_errors(), 0)
end)

test('every theme reads the one Window titles setting', function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		Set('theme', name)
		local root, row = Row('font')
		OM.Set(root, row, 'pixel')
		eq(st.config.profile.headers.font, 'pixel', name)
		eq(Get('font'), 'pixel', name .. ': the same value')
		Reset('font')
	end
	Set('theme', 'thick')
end)

test('a Window titles set reaches every header title at once, running FontsChanged once', function()
	local panel = st:CreatePanel('Theme tab test', 200, 100)
	check(panel.title:GetFontObject() == st:GetFont('normal'), 'in Text to start with')
	local changes = 0
	local Probe = st:GetModule('ThemeTabProbe', true) or st:NewModule('ThemeTabProbe')
	function Probe:OnFontsChanged() changes = changes + 1 end
	local root, row = Row('font')
	OM.Set(root, row, 'subtitle')
	eq(changes, 1, 'FontsChanged once')
	check(panel.title:GetFontObject() == st:GetFont('subtitle'), 'a shared font, at once')
	local face = { font_name = 'Homespun', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
	OM.Set(root, row, face)
	check(panel.title:GetFontObject() == st:FontObject(face), 'a typeface, at once')
	changes = 0
	Reset('font')
	eq(changes, 1, 'its reset runs FontsChanged once')
	check(panel.title:GetFontObject() == st:GetFont('normal'), 'back in Text')
	eq(#take_errors(), 0)
end)
