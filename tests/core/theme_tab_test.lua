-- The Theme tab of Global Settings (SaftUI-Core/Media/theme.lua): Theme, the
-- chosen theme's three colors, Transparent background, Opacity and Reset. A
-- color or the opacity recolors every drawn frame (st:RecolorThemed); the
-- theme and the toggle also move borders, so they run st:ThemeChanged
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
		check(type(r.v.desc) == 'string' and r.v.desc ~= '', r.v.name .. ' has a desc')
		eq(r.v.width, nil, r.v.name .. ' has no Ace width')
	end
	eq(table.concat(names, ','), 'Theme,Border,Outer border,Background,Transparent background,Opacity,Reset')
	eq(table.concat(types, ','), 'select,color,color,color,toggle,range,execute')

	local theme, opacity, reset = rows[1].v, rows[6].v, rows[7].v
	eq(theme.values.thick, 'Thick'); eq(theme.values.thin, 'Thin')
	eq(theme.values.none, nil, 'None is a module override, not a theme to choose')
	check(opacity.isPercent, 'Opacity shows as a percent')
	eq(opacity.min, 0); eq(opacity.max, 1)
	check(reset.confirm, 'Reset asks first')
	for i = 2, 4 do
		eq(rows[i].v.hasAlpha, nil, rows[i].v.name .. ' has no opacity slider')
	end
end)

test('Outer border shows only for Thick', function()
	st.config.profile.theme.name = 'thick'
	check(Row('outer'), 'shown for Thick')
	st.config.profile.theme.name = 'thin'
	eq(Row('outer'), nil, 'hidden for Thin')
	st.config.profile.theme.name = 'thick'
end)

test('Opacity is disabled while Transparent background is off', function()
	st.config.profile.theme.transparent = false
	local root, row = Row('opacity')
	check(OM.IsDisabled(root, row), 'disabled when off')
	st.config.profile.theme.transparent = true
	root, row = Row('opacity')
	check(not OM.IsDisabled(root, row), 'enabled when on')
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
	Set('opacity', 0.5)
	for _, r in ipairs(restore) do r() end
	eq(table.concat(log, ','), 'RecolorThemed,RecolorThemed')
	eq(st.config.profile.theme.opacity, 0.5)
end)

test('a theme or toggle switch runs ThemeChanged: redraw, then UpdateConfig, then ColorsChanged(theme)', function()
	local log, restore = {}, {}
	restore[1] = Spy(st, 'RedrawThemed', log)
	restore[2] = Spy(st.Config, 'UpdateConfig', log)
	local real = st.ColorsChanged
	st.ColorsChanged = function(_, group) log[#log + 1] = 'ColorsChanged(' .. group .. ')'; return real(st, group) end
	local recolor = Spy(st, 'RecolorThemed', log)

	Set('theme', 'thin')
	eq(table.concat(log, ','), 'RedrawThemed,UpdateConfig,ColorsChanged(theme)', 'a theme switch')
	eq(st.config.profile.theme.name, 'thin')

	log = {}
	restore[1](); restore[2]()
	restore[1] = Spy(st, 'RedrawThemed', log)
	restore[2] = Spy(st.Config, 'UpdateConfig', log)
	Set('transparent', false)
	eq(table.concat(log, ','), 'RedrawThemed,UpdateConfig,ColorsChanged(theme)', 'the toggle')
	eq(st.config.profile.theme.transparent, false)

	recolor(); restore[1](); restore[2](); st.ColorsChanged = real
	Set('transparent', true)
	Set('theme', 'thick')
end)

test('in combat a theme change waits for its end, once', function()
	local log, restore = {}, {}
	restore[1] = Spy(st, 'RedrawThemed', log)
	restore[2] = Spy(st, 'RecolorThemed', log)
	stub.in_combat = true
	Set('theme', 'thin')
	Set('transparent', false)
	Set('border', 0.3, 0.3, 0.3)
	Set('opacity', 0.4)
	eq(#log, 0, 'nothing drawn in combat')
	eq(st.config.profile.theme.name, 'thin', 'but the setting is stored')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	table.sort(log)
	eq(table.concat(log, ','), 'RecolorThemed,RedrawThemed', 'one redraw and one recolor')
	for _, r in ipairs(restore) do r() end
	Set('transparent', true)
	Set('theme', 'thick')
	eq(#take_errors(), 0, 'no errors')
end)

test('Reset restores the chosen theme and the transparency', function()
	Set('theme', 'thin')
	Set('border', 0.9, 0.9, 0.9)
	Set('transparent', false)
	Set('opacity', 0.2)
	Set('theme', 'thick')
	Set('border', 0.9, 0.9, 0.9)
	Set('outer', 0.5, 0.5, 0.5)
	Set('background', 0.9, 0.9, 0.9)
	local root, row = Row('reset')
	eq(OM.Confirm(root, row), "Reset the Thick theme to SaftUI's defaults?")
	OM.Set(root, row)
	local d, p = st.defaults.templates.thick, st.config.profile.templates.thick
	for _, key in ipairs({ 'bordercolor', 'altbordercolor', 'backdropcolor' }) do
		eq(table.concat(p[key], ','), table.concat(d[key], ','), 'Thick ' .. key)
	end
	eq(st.config.profile.theme.transparent, st.defaults.theme.transparent)
	eq(st.config.profile.theme.opacity, st.defaults.theme.opacity)
	eq(st.config.profile.theme.name, 'thick', 'the theme itself stays')
	eq(Rgb(st.config.profile.templates.thin.bordercolor), '0.9,0.9,0.9', "Thin's colors are not touched")

	Set('theme', 'thin')
	root, row = Row('reset')
	eq(OM.Confirm(root, row), "Reset the Thin theme to SaftUI's defaults?")
	Set('theme', 'thick')
end)

test('after a profile switch the rows reach the new profile', function()
	local first = st.config:GetCurrentProfile()
	Set('theme', 'thin')
	Set('border', 0.11, 0.12, 0.13)
	Set('opacity', 0.33)
	st.config:SetProfile('ThemeTabTwo')
	eq(Get('theme'), 'thick', "the new profile's theme")
	eq(Rgb({ Get('border') }), Rgb(st.defaults.templates.thick.bordercolor), "the new profile's Thick border")
	eq(Get('opacity'), st.defaults.theme.opacity)

	Set('theme', 'thin')
	Set('border', 0.21, 0.22, 0.23)
	eq(Rgb(st.config.profile.templates.thin.bordercolor), '0.21,0.22,0.23', 'a set reaches the new profile')

	st.config:SetProfile(first)
	eq(Get('theme'), 'thin')
	eq(Rgb({ Get('border') }), '0.11,0.12,0.13', "the first profile's are as they were")
	eq(Get('opacity'), 0.33)
end)
