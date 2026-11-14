-- SaftUI's own config windows follow the theme's Background, and Global
-- settings > Theme > Options windows turns that off (SaftUI-Core/theme.lua
-- takes the draw call's Background 'options'; Media/theme.lua has the row).
--   - the /sui window (and its small bar), its sidebar's fill, its small
--     dialogs and the confirm dialog, edit mode's docked bar and floating
--     window, and the History list are drawn with 'options': see-through at
--     the theme's opacity by default, solid when the setting says Solid;
--   - what opens over content stays solid in both cases: the search panel,
--     SaftUI's color picker, a select's list, edit mode's picker list;
--   - a change of the setting, of the theme's opacity, or of the theme repaints
--     every open window at once.
--
-- Real: the /sui window's world (core/options_window_helpers.lua), edit mode's
-- files and the bar's, a real AceDB profile. The Theme tab's row is read and
-- set through the options model, as the window does.
local T = load_test_file('lib/theme_helpers.lua')

local H, st, EM, W, OW, OM, drawn

local function fresh()
	reset_world()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, W, OW, OM = st.EditModeFrames, st.OptionsWidgets, st.OptionsWindow, st.OptionsModel
	drawn = T.watch() -- before edit mode is enabled: its picker list is drawn then
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	return st
end

local function alpha(f) return T.text(select(4, f:GetBackdropColor())) end

-- The Theme tab's row for key, and its value as the window reads it.
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

-- Opens every config window and returns them by name as { frame, 'drawn' string,
-- the frame its fill is on }.
local function open_all()
	st.Config:Open()
	local F = OW.GetFrames()
	OW:OpenDialog('Dialog', { type = 'group', name = 'Group', args = { note = { type = 'description', name = 'A note.' } } })
	W.Confirm('Sure?', function() end)
	local bar, window, history = EM:GetBar(), EM:GetBarWindow(), EM:GetHistoryList()
	return {
		{ 'the /sui window', F.window, 'theme,options,window', F.window },
		{ 'the small dialog', OW.GetDialogFrames().frame, 'theme,options,panel', OW.GetDialogFrames().frame },
		{ 'the confirm dialog', W.GetDialogFrames().skin, 'theme,options,panel', W.GetDialogFrames().skin },
		{ "edit mode's bar", bar, 'theme,options,panel', bar.backdrop },
		{ "edit mode's floating window", window, 'theme,options,panel', window.backdrop },
		{ 'the History list', history, 'theme,options,panel', history.backdrop },
	}
end

local function check_alphas(windows, want, where)
	for _, w in ipairs(windows) do
		eq(alpha(w[4]), want, where .. ': ' .. w[1])
	end
end

------------------------------------------------------------------ the setting

test('Global settings > Theme has Options windows: the kit\'s Background choices, saved with the theme, Use SaftUI\'s theme by default', function()
	fresh()
	eq(st.defaults.theme.optionsbackground, 'theme', 'the default')
	eq(st.config.profile.theme.optionsbackground, 'theme', 'in the profile, with the theme')
	local root, row = Row('optionsbackground')
	check(row ~= nil, 'a row')
	eq(row.option.name, 'Options windows')
	eq(row.option.type, 'select')
	local values = {}
	for i, key in ipairs(row.option.sorting) do values[i] = key .. '=' .. row.option.values[key] end
	eq(table.concat(values, ';'), "theme=Use SaftUI's theme;solid=Solid;transparent=Transparent", "the generator's choices, in its order")
	eq(Get('optionsbackground'), 'theme')
	check(not OM.DefaultState(root, row).differs, 'no reset while it is the default')

	Set('optionsbackground', 'solid')
	eq(st.config.profile.theme.optionsbackground, 'solid', 'saved in the theme table')
	local state = OM.DefaultState(root, row)
	check(state.differs, 'the reset shows once it differs')
	check(OM.DefaultReset(root, row), 'and runs')
	eq(Get('optionsbackground'), 'theme', 'the default is back')
end)

------------------------------------------------------------------ the windows

test('the config windows are see-through by the theme\'s Background, and solid when Options windows says Solid', function()
	fresh()
	local windows = open_all()
	for _, w in ipairs(windows) do
		eq(drawn(w[2]), w[3], w[1] .. ': drawn with the options Background')
	end
	check_alphas(windows, '0.90', 'by default, at the theme\'s opacity')

	Set('optionsbackground', 'solid')
	check_alphas(windows, '1.00', 'Solid, with no reopening')
	Set('optionsbackground', 'theme')
	check_alphas(windows, '0.90', 'back')
end)

test('the small bar of /sui is a panel on the same Background', function()
	fresh()
	st.Config:Open()
	local F = OW.GetFrames()
	OW:SetWindowSize('half')
	OW:SetWindowSize('mini')
	eq(OW:GetWindowSize(), 'mini')
	eq(drawn(F.window), 'theme,options,panel')
	eq(alpha(F.window), '0.90')
	Set('optionsbackground', 'solid')
	eq(alpha(F.window), '1.00')
end)

test('a change of the theme\'s opacity or of the theme repaints every window; Solid ignores the opacity', function()
	fresh()
	local windows = open_all()
	local F = OW.GetFrames()
	local r, g, b = Get('background')
	Set('background', r, g, b, 0.5)
	check_alphas(windows, '0.50', 'opacity 50%')
	eq(T.text(stub.state(F.sideFill).color_texture[4]), '0.50', "the sidebar's fill follows too")
	Set('optionsbackground', 'solid')
	check_alphas(windows, '1.00', 'Solid')
	eq(T.text(stub.state(F.sideFill).color_texture[4]), '1.00', "the sidebar's fill")
	Set('background', r, g, b, 0.3)
	check_alphas(windows, '1.00', 'still Solid at another opacity')
	T.theme('thin')
	check_alphas(windows, '1.00', 'a theme switch keeps Solid')
	Set('optionsbackground', 'theme')
	check_alphas(windows, '0.30', 'and the theme\'s opacity returns')
end)

test('the sidebar\'s fill is see-through with the window', function()
	fresh()
	st.Config:Open()
	local F = OW.GetFrames()
	eq(T.text(stub.state(F.sideFill).color_texture[4]), '0.90')
	Set('optionsbackground', 'solid')
	eq(T.text(stub.state(F.sideFill).color_texture[4]), '1.00')
end)

test('under Blizzard the window fill follows the setting too, its art is its own', function()
	fresh()
	T.theme('blizzard')
	local windows = open_all()
	local fill = st.config.profile.templates.blizzard.windowcolor[4]
	eq(alpha(windows[1][4]), T.text(fill * 0.9), 'the metal window: its fill at the theme\'s opacity')
	Set('optionsbackground', 'solid')
	eq(alpha(windows[1][4]), T.text(fill), 'Solid: its fill whole')
	eq(drawn(windows[1][2]), 'theme,options,window', 'still the window kind, so still the metal')
end)

test('a transparent choice is see-through at the theme\'s opacity even while the theme is solid', function()
	fresh()
	local windows = open_all()
	local r, g, b = Get('background')
	Set('background', r, g, b, 1)
	check_alphas(windows, '1.00', 'a solid theme')
	Set('optionsbackground', 'transparent')
	check_alphas(windows, T.text(st.defaults.theme.opacity), 'Transparent: the shipped opacity')
end)

------------------------------------------------------------------ what opens over content

test('the search panel, the color picker, a select\'s list and edit mode\'s picker list stay solid in both cases', function()
	fresh()
	st.Config:Open()
	local F = OW.GetFrames()
	W.OpenColorPicker(F.window, { r = 1, g = 0, b = 0, a = 1, hasAlpha = true, onChange = function() end })
	local picker = W.GetColorPickerFrames().frame
	local owner = CreateFrame('Button', nil, UIParent)
	owner:SetSize(100, 24)
	owner:SetPoint('CENTER')
	W.OpenList(owner, { { key = 'a', label = 'A' }, { key = 'b', label = 'B' } }, 'a', function() end)
	local list = W.GetListFrames().frame
	EM:Fire('Enabled') -- styles the picker list
	local pickerList = EM.GetPickerState().list

	for _, setting in ipairs({ 'theme', 'solid' }) do
		Set('optionsbackground', setting)
		eq(drawn(F.searchPop), 'theme,solid,panel', setting .. ': the search panel is a solid panel')
		eq(alpha(F.searchPop), '1.00', setting .. ': the search panel')
		eq(drawn(picker), 'theme,solid,panel', setting .. ': the color picker is a solid panel')
		eq(alpha(picker), '1.00', setting .. ': the color picker')
		eq(alpha(list), '1.00', setting .. ': a select\'s list')
		eq(drawn(pickerList), 'theme,solid,tooltip', setting .. ': the picker list')
		eq(alpha(pickerList.backdrop), '1.00', setting .. ': edit mode\'s picker list')
	end
end)
