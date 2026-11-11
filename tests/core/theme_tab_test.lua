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
		local desc = type(r.v.desc) == 'function' and r.v.desc() or r.v.desc
		check(type(desc) == 'string' and desc ~= '', r.v.name .. ' has a desc')
		eq(r.v.width, nil, r.v.name .. ' has no Ace width')
	end
	eq(table.concat(names, ','), 'Theme,Border,Outer border,Window background,Background,Transparent background,Opacity,Reset')
	eq(table.concat(types, ','), 'select,color,color,color,color,toggle,range,execute')

	local theme, opacity, reset = rows[1].v, rows[7].v, rows[8].v
	eq(theme.values.thick, 'Thick'); eq(theme.values.thin, 'Thin')
	eq(theme.values.blizzard, 'Blizzard')
	eq(theme.values.none, nil, 'None is a module override, not a theme to choose')
	check(opacity.isPercent, 'Opacity shows as a percent')
	eq(opacity.min, 0); eq(opacity.max, 1)
	check(reset.confirm, 'Reset asks first')
	for i = 2, 5 do
		eq(rows[i].v.hasAlpha, nil, rows[i].v.name .. ' has no opacity slider')
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

test("Reset under Blizzard restores Blizzard's colors, windowcolor among them, and the transparency", function()
	Set('theme', 'blizzard')
	for _, key in ipairs({ 'border', 'windowcolor', 'background' }) do Set(key, 0.9, 0.9, 0.9) end
	Set('transparent', false)
	Set('opacity', 0.2)
	local root, row = Row('reset')
	eq(OM.Confirm(root, row), "Reset the Blizzard theme to SaftUI's defaults?")
	OM.Set(root, row)
	local d, p = st.defaults.templates.blizzard, st.config.profile.templates.blizzard
	for _, key in ipairs({ 'bordercolor', 'altbordercolor', 'backdropcolor', 'windowcolor' }) do
		eq(table.concat(p[key], ','), table.concat(d[key], ','), 'Blizzard ' .. key)
	end
	eq(st.config.profile.theme.transparent, st.defaults.theme.transparent)
	eq(st.config.profile.theme.opacity, st.defaults.theme.opacity)
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
	Set('transparent', false)
	eq(table.concat(log, ','), 'UpdateConfig,RedrawThemed,module,ColorsChanged(theme)', 'the toggle')
	eq(st.config.profile.theme.transparent, false)

	recolor(); restore[1](); restore[2](); st.ColorsChanged = real
	probe.UpdateConfig = nil
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
		local root, row = Row('reset')
		eq(OM.Confirm(root, row), "Reset the Thick theme to SaftUI's defaults?", "Reset names Thick")
		OM.Set(root, row)
		eq(Rgb(thick.bordercolor), Rgb(st.defaults.templates.thick.bordercolor), "Reset puts back Thick's")
	end)
	check(ok, 'the rows raise nothing: ' .. tostring(err))
	eq(#take_errors(), 0, 'and report nothing')
	eq(theme.name, 'later', 'the saved name stays until the user picks a theme')
	Set('theme', 'thin')
	eq(theme.name, 'thin', 'picking one saves it')
	Set('theme', 'thick')
end)
