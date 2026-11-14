-- The unit frame profile on /sui (SaftUI-Unitframes/config/profiles.lua and
-- config/config.lua, nameplates/options.lua): the Unit dropdown's line (Unit,
-- Copy from, Profile, Manage: each unit's pickerControl; the nameplate pages'
-- hold Profile and Manage only) as the real window draws it, the footer
-- holding none, the Unit frame profiles dialog Manage opens, and the line
-- following New, Rename and Delete made in the dialog; the Unit dropdown without
-- Profile as a pick; a search finding the control; the old Unitframes >
-- profile path; the line at half, wrapped, on whole pixels.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the options model, widgets, body and window, the unit
-- frames' defaults (filled as AceDB fills them, so a profile is made by
-- reading it), config/profiles.lua, config/groupoptions.lua, config/config.lua
-- and nameplates/options.lua (the nameplate pages config.lua builds).
--
-- Stand-ins, for unitframes.lua (it needs oUF), as profiles_test.lua has them:
--   * UF:UpdateConfig counts its calls, and reads the profile's player
--     config as the real one reads every unit's (which makes a new profile,
--     as AceDB does).
--   * What its OnEnable makes, as far as UF:GetConfigTable reads it: a player
--     frame (UF.units), no groups or elements, UF:GetMoverFrame.
-- The prompts (New, Rename) and the confirm (Delete) are SaftUI's own
-- (st.OptionsWidgets Prompt and Confirm), answered as a user does.
load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_options_window()
load_saftui('SaftUI-Unitframes/config/position.lua') -- config/load.xml's order: first
load_saftui('SaftUI-Unitframes/config/default.lua')
load_saftui('SaftUI-Unitframes/config/units/party.lua') -- a group's page too
apply_defaults()

local OW, W = st.OptionsWindow, st.OptionsWidgets
local UF = st:NewModule('Unitframes')
local updates = 0
function UF:UpdateConfig()
	updates = updates + 1
	local _ = self:GetProfileConfig().player
end
UF.testGroups = {}
UF.units, UF.groups, UF.holders, UF.elements = { player = CreateFrame('Frame', nil, UIParent) }, { party = CreateFrame('Frame', nil, UIParent) }, { party = CreateFrame('Frame', nil, UIParent) }, {}
UF.unit_strings, UF.group_strings = { player = 'Player' }, { party = 'Party' }
function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end

load_saftui('SaftUI-Unitframes/config/profiles.lua')
load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
load_saftui('SaftUI-Unitframes/config/config.lua')
load_saftui('SaftUI-Unitframes/nameplates/options.lua')

-- Two profiles to start with: reading one makes it, from the defaults.
local P = st.config.profile.unitframes
P.profiles.SaftUI.player.width = 111
P.profiles.Healer.player.width = 222

local click, tick = stub.click, tick_options_window
local function frames() return OW.GetFrames() end

-- The line's Profile dropdown and Manage, as drawn last (Copy from is first).
local function footer()
	local widgets = frames().pickerWidgets
	return widgets[#widgets - 1], widgets[#widgets]
end

-- The labels an open select list shows, in order.
local function listed()
	local out = {}
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() then out[#out + 1] = row.text:GetText() end
	end
	return table.concat(out, ',')
end

-- Picks the open list's row labelled text.
local function pick(text)
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() and row.text:GetText() == text then return click(row) end
	end
	error('no list row ' .. text)
end

-- The profiles the line's dropdown lists, its list opened and closed again.
local function footer_list()
	click(footer().frame)
	local names = listed()
	W.CloseList()
	return names
end

-- The dialog's drawn rows: their keys in order, and one by key.
local function dialog_keys()
	local out = {}
	for i, c in ipairs(OW.GetDialogFrames().body.cells) do out[i] = c.row.key end
	return table.concat(out, ',')
end
local function dialog_cell(key)
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

-- The page's drawn row with key.
local function page_cell(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

-- Picks unit's name in the Unit dropdown.
local function pick_unit(name)
	click(frames().picker.frame)
	pick(name)
end

local function type_and_enter(text)
	local box = W.PromptBox()
	box:SetText(text)
	stub.fire_script(box, 'OnEnterPressed')
end

local function close_all()
	OW:CloseDialog()
	st.Config:Close()
	P.config_profile = 'SaftUI'
end

test("the unit frame profile is on the Unit dropdown's line: Unit, Copy from, Profile, Manage; the footer holds none", function()
	local config = UF:GetConfigTable()
	eq(config.footer, nil, 'no footer on the page group')
	eq(config.args.profile, nil, 'no Profile group among the units')
	local args = config.args.player.pickerControl.args
	eq(args.copy.order .. ',' .. args.profile.order .. ',' .. args.manage.order, '1,10,11', 'in order')
	eq(args.profile.type .. ',' .. args.profile.name .. ',' .. tostring(args.profile.size), 'select,Profile,nil', 'a dropdown named Profile, with no line of its own')
	eq(args.profile.desc, UF.GenerateProfileConfigGroup().args.current.desc, "the dropdown is the dialog's own")
	local control = UF.GenerateProfileControl()
	eq(control.profile.order .. ',' .. control.manage.order, '10,11', 'UF.GenerateProfileControl')

	st.Config:Open('Unitframes', 'player', 'general')
	local F = OW.GetFrames()
	eq(#F.footerWidgets, 0, 'no footer control')
	local types = {}
	for i, w in ipairs(F.pickerWidgets) do types[i] = w.type end
	eq(table.concat(types, ','), 'execute,select,execute', 'Copy from, the profile, Manage')
	eq(F.pickerLabels[1]:GetText(), 'Profile', "the select's name, drawn before it")
	check(not F.footerControl:IsShown(), 'nothing in the footer')
	eq(OW:GetState().pick, 'player', 'the page opens on Player')
	click(F.picker.frame)
	local units = listed()
	W.CloseList()
	check(not units:find('Profile', 1, true), 'the Unit dropdown lists no Profile: ' .. units)
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the line's dropdown lists the profiles and switches, and the page draws again, on every unit's page", function()
	st.Config:Open('Unitframes')
	local f = frames()
	local dropdown, manage = footer()
	eq(dropdown.text:GetText(), 'SaftUI', 'the profile in use')
	eq(manage.text:GetText(), 'Manage', 'and Manage')
	local label = f.pickerLabels[1]
	eq(f.pickerWidgets[1].frame:GetLeft(), f.picker.frame:GetRight() + 12, 'Copy from 12 after the Unit dropdown')
	eq(label:GetLeft(), f.pickerWidgets[1].frame:GetRight() + 12, 'Profile 12 after Copy from')
	check(dropdown.frame:GetLeft() > label:GetRight(), 'the dropdown after its name')
	eq(manage.frame:GetLeft(), dropdown.frame:GetRight() + 12, 'Manage 12 after it')
	eq(page_cell('width').widget.frame:GetText(), '111', "the page shows the profile's settings")

	click(dropdown.frame)
	eq(listed(), 'Healer,SaftUI', 'it lists the profiles')
	local before = updates
	pick('Healer')
	eq(P.config_profile, 'Healer', 'picking one switches to it')
	eq(updates, before + 1, 'the unit frames updated')
	tick()
	eq((footer()).text:GetText(), 'Healer', 'the dropdown shows the new one')
	eq(page_cell('width').widget.frame:GetText(), '222', "and the page the new profile's settings")

	OW:Navigate('Fonts')
	eq(#f.pickerWidgets, 0, 'none on Global settings')
	OW:Navigate('Unitframes')
	eq(#f.pickerWidgets, 3, 'back on Unitframes')
	pick_unit('Enemy nameplates')
	eq(#f.pickerWidgets, 2, 'Profile and Manage on a nameplate page')
	pick_unit('Player')
	eq(#f.pickerWidgets, 3, 'and all three back on Player')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("a switch on the line keeps the unit and tab you are on", function()
	for _, case in ipairs({ { 'party', 'general' }, { 'nameplate', 'general' } }) do
		st.Config:Open('Unitframes', case[1], case[2])
		click((footer()).frame)
		pick('Healer')
		tick()
		local state = OW:GetState()
		eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/' .. case[1] .. '/' .. case[2], case[1] .. ': still there after the switch')
		eq((footer()).text:GetText(), 'Healer', case[1] .. ': showing the new profile')
		close_all()
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('Manage opens Unit frame profiles: the profile, then New, Copy, Rename, Delete, Export and Import, then Close', function()
	st.Config:Open('Unitframes')
	click(select(2, footer()).frame)
	check(OW:IsDialogShown(), 'the dialog')
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Unit frame profiles', 'its title')
	eq(dialog_keys(), 'current,new,copy,rename,delete,export,import,close', 'the profile, the six actions, Close')
	local current = dialog_cell('current')
	eq(current.label:GetText(), 'Profile', 'the profile, labelled')
	eq(current.widget.text:GetText(), 'SaftUI', 'showing the one in use')
	for _, key in ipairs({ 'new', 'copy', 'rename', 'delete', 'export', 'import' }) do
		local c = dialog_cell(key)
		eq(c.widget.type, 'execute', key .. ' is a button')
		eq(c.row.size, 'small', key .. ' is small: two to a half line')
		check(c.y > current.y, key .. ' under the profile')
	end
	eq(dialog_cell('new').y, dialog_cell('delete').y, 'New, Copy, Rename and Delete on one line')
	eq(dialog_cell('export').y, dialog_cell('import').y, 'Export and Import on the next')
	check(dialog_cell('close').y > dialog_cell('import').y, 'Close last')
	-- Under Thick the lines of buttons have no panel: the profile's ends over
	-- them, 24 above New's line; Export's line is 12 under New's, as far as the
	-- buttons were apart on the panel; Close, the closing line, sits 24 under
	-- Export's, as the dialog ends 24 under Close.
	local function panels()
		local out = {}
		for _, p in ipairs(d.body.pools.panel.used) do
			if p:IsShown() then
				local _, _, _, _, py = p:GetPoint(1)
				out[#out + 1] = -py .. '+' .. p:GetHeight()
			end
		end
		return table.concat(out, ' ')
	end
	eq(panels(), current.y .. '+38', "one panel, the profile's")
	eq(dialog_cell('new').y, current.y + 38 + 24, "New's line 24 under the panel")
	eq(dialog_cell('new').height, dialog_cell('new').widget:GetHeight(), 'as tall as its buttons')
	eq(dialog_cell('export').y, dialog_cell('new').y + dialog_cell('new').height + 12, "Export's line 12 under New's")
	eq(dialog_cell('close').y, dialog_cell('import').y + dialog_cell('import').height + 24, "Close 24 under Export's line")
	eq(dialog_cell('close').frame:GetBottom() - d.frame:GetBottom(), 24, 'the dialog ends 24 under Close')
	-- Buttons that share a line each fill their quarter, 12 apart, an even row
	-- across the 520 body; Export and Import under the first two at their
	-- width. Close keeps its own width, in the middle.
	local function row(keys)
		local out = {}
		for _, key in ipairs(keys) do
			local c = dialog_cell(key)
			out[#out + 1] = (select(4, c.frame:GetPoint(1))) .. '+' .. c.widget.frame:GetWidth()
		end
		return table.concat(out, ' ')
	end
	eq(row({ 'new', 'copy', 'rename', 'delete' }), '0+121 133+121 266+121 399+121', 'New to Delete: edge to edge, 12 apart')
	eq(row({ 'export', 'import' }), '0+121 133+121', 'Export and Import under New and Copy')
	eq(row({ 'close' }), (520 - 80) / 2 .. '+80', 'Close: its own 80, in the middle')

	-- The dialog's dropdown switches too, and the footer follows.
	click(current.widget.frame)
	eq(listed(), 'Healer,SaftUI', 'it lists the profiles')
	pick('Healer')
	eq(P.config_profile, 'Healer', 'switched from the dialog')
	tick()
	eq((footer()).text:GetText(), 'Healer', "the footer's dropdown follows")
	eq(dialog_cell('current').widget.text:GetText(), 'Healer', "and the dialog's")

	click(dialog_cell('close').widget.frame)
	check(not OW:IsDialogShown(), 'Close closes it')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the footer's dropdown and the dialog's follow New, Rename and Delete made in the dialog", function()
	st.Config:Open('Unitframes')
	click(select(2, footer()).frame)

	-- New.
	click(dialog_cell('new').widget.frame)
	eq(W.ConfirmText(), 'Enter a name for your new profile', 'New asks for a name')
	type_and_enter('Tank')
	eq(P.config_profile, 'Tank', 'made and switched to')
	tick()
	eq((footer()).text:GetText(), 'Tank', "the footer's dropdown shows it")
	eq(footer_list(), 'Healer,SaftUI,Tank', 'and lists it')
	eq(dialog_cell('current').widget.text:GetText(), 'Tank', "the dialog's dropdown shows it too")

	-- Rename.
	click(dialog_cell('rename').widget.frame)
	type_and_enter('Tanky')
	eq(P.config_profile, 'Tanky', 'renamed')
	tick()
	eq((footer()).text:GetText(), 'Tanky', "the footer's dropdown follows the rename")
	eq(footer_list(), 'Healer,SaftUI,Tanky', 'its list too')
	eq(dialog_cell('current').widget.text:GetText(), 'Tanky', "and the dialog's")

	-- Delete, after asking.
	click(dialog_cell('delete').widget.frame)
	eq(W.ConfirmText(), 'Are you sure you wish to delete this profile?', 'Delete asks')
	click(W.GetDialogFrames().yes)
	check(rawget(P.profiles, 'Tanky') == nil and P.config_profile ~= 'Tanky', 'deleted, and another in use')
	tick()
	eq((footer()).text:GetText(), P.config_profile, "the footer's dropdown shows the one in use now")
	eq(footer_list(), 'Healer,SaftUI', 'and lists the deleted one no more')
	eq(dialog_cell('current').widget.text:GetText(), P.config_profile, "the dialog's follows")
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

-- The drawn search results named name, with each one's pick (the second step of its path).
local function found(name)
	local out = {}
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.name == name then out[#out + 1] = c end
	end
	return out
end

test("a search for the unit frame profile lists it once, not once per unit: by its words, and by its names", function()
	st.Config:Open('Fonts')
	local f = frames()
	for _, case in ipairs({
		{ 'unit frame profile', 1, 1 }, { 'unit frame', 1, 1 }, { 'profile', 1, 1 }, { 'manage', 0, 1 },
	}) do
		f.search:SetText(case[1])
		tick(0.3)
		local what = '"' .. case[1] .. '"'
		eq(#found('Profile'), case[2], what .. ': the Profile dropdown once')
		eq(#found('Manage'), case[3], what .. ': Manage once')
	end
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("a unit frame profile result keeps the unit and tab you are on, and from another page opens Unitframes", function()
	st.Config:Open('Unitframes', 'party', 'general') -- no element tabs in this world
	local f = frames()
	f.search:SetText('unit frame profile')
	tick(0.3)
	check(OW:GetState().search ~= '', 'searching')
	click(found('Manage')[1].frame)
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/party/general', 'the unit and tab as they were (not Player)')
	eq(#f.pickerWidgets, 3, "with the line's control")
	st.Config:Open('Fonts')
	f.search:SetText('unit frame profile')
	tick(0.3)
	click(found('Profile')[1].frame)
	state = OW:GetState()
	eq(state.page, 'Unitframes', 'from another page it opens the unit frames page')
	check(state.pick ~= nil and #f.pickerWidgets >= 2, 'on a pick with the control')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('the old Unitframes > profile path opens the Unitframes page on its first unit, the profile on its line', function()
	st.Config:Open('Unitframes', 'profile')
	local state = OW:GetState()
	eq(state.page .. '/' .. tostring(state.pick), 'Unitframes/player', 'the page, on Player')
	eq(#frames().pickerWidgets, 3, 'the line has it')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("a SaftUI (AceDB) profile switch with Unitframes open: the line's dropdown follows the new profile's unit frame profile", function()
	P.config_profile = 'Healer'
	st.Config:Open('Unitframes')
	eq((footer()).text:GetText(), 'Healer', "the first profile's unit frame profile")
	local first = st.config:GetCurrentProfile()
	st.config:SetProfile('FooterTestTwo')
	tick()
	eq(st.config.profile.unitframes.config_profile, 'SaftUI', "the new profile's own")
	eq((footer()).text:GetText(), 'SaftUI', "the line's dropdown shows it")
	st.config:SetProfile(first)
	tick()
	eq(st.config.profile.unitframes.config_profile, 'Healer', 'the first profile again')
	eq((footer()).text:GetText(), 'Healer', 'and the dropdown follows back')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("a SaftUI (AceDB) profile switch with Manage's dialog open: the dialog follows too", function()
	P.config_profile = 'Healer'
	st.Config:Open('Unitframes')
	click(select(2, footer()).frame)
	eq(dialog_cell('current').widget.text:GetText(), 'Healer', 'the dialog shows the profile in use')
	local first = st.config:GetCurrentProfile()
	st.config:SetProfile('FooterTestThree')
	tick()
	check(OW:IsDialogShown(), 'still open')
	eq(dialog_cell('current').widget.text:GetText(), 'SaftUI', "the dialog shows the new profile's")
	eq((footer()).text:GetText(), 'SaftUI', 'and the footer')
	st.config:SetProfile(first)
	tick()
	eq(dialog_cell('current').widget.text:GetText(), 'Healer', 'back with the first')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('Copy from in the real window: a button right of the Unit dropdown, on every tab; none on a nameplate page; a search opens the unit', function()
	local opened
	local real = UF.OpenCopyTable
	function UF:OpenCopyTable(unit) opened = unit end
	st.Config:Open('Unitframes', 'player', 'general')
	local f = frames()
	eq(#f.pickerWidgets, 3, 'Copy from, Profile and Manage on the line')
	local button = f.pickerWidgets[1]
	eq(button.text:GetText(), 'Copy from', 'Copy from')
	eq(button.frame:GetLeft(), f.picker.frame:GetRight() + 12, 'right of the Unit dropdown')
	click(button.frame)
	eq(opened, 'player', 'it opens the dialog for the picked unit')
	eq(page_cell('copy'), nil, 'not in General any more')
	OW:Navigate('Unitframes', { pick = 'nameplate' })
	eq(OW:GetState().pick, 'nameplate', 'on Enemy nameplates')
	eq(#f.pickerWidgets, 2, 'Profile and Manage on a nameplate page')
	eq(f.pickerWidgets[1].type .. ',' .. f.pickerWidgets[2].type, 'select,execute', 'and no Copy from')

	-- A search for it opens the unit's page.
	f.search:SetText('copy from')
	tick(0.3)
	local result
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.name == 'Copy from' and not result then result = c end
	end
	check(result ~= nil, 'found')
	click(result.frame)
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick, 'Unitframes/player', "the unit's page")
	eq(#f.pickerWidgets, 3, 'with Copy from beside its picker')
	UF.OpenCopyTable = real
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the Unit dropdown's line (Unit, Copy from, Profile, Manage) on the real page, on whole pixels: one line at full, two at half, the body under it", function()
	local P = load_test_file('lib/pixels.lua')
	local HAIR = 2 ^ -14
	local function line(f)
		local out = {}
		for _, w in ipairs(f.pickerWidgets) do out[#out + 1] = w.type end
		return table.concat(out, ',')
	end
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		st.config.profile.theme.name = look
		local halfBody = look == 'blizzard' and 368 or 388
		for _, noise in ipairs({ HAIR, -HAIR, 0 }) do
			stub.size_noise = noise
			for _, case in ipairs({ { 'player', 'general', 'execute,select,execute' }, { 'party', 'general', 'execute,select,execute' },
				{ 'nameplate', 'general', 'select,execute' } }) do
				local unit, tab, types = case[1], case[2], case[3]
				local where = look .. ' ' .. unit .. ' noise ' .. noise
				st.Config:Open('Unitframes', unit, tab)
				local f = OW.GetFrames()
				for _, size in ipairs({ 'full', 'half' }) do
					if size == 'half' then OW:SetWindowSize('half') end
					local tag = where .. ' ' .. size
					eq(line(f), types, tag .. ': the line')
					eq(#f.footerWidgets, 0, tag .. ': the footer holds none')
					local off = P.off(f.main)
					eq(#off, 0, tag .. ': whole pixels: ' .. P.report(off))
					local select = f.pickerWidgets[unit == 'nameplate' and 1 or 2]
					local drop = f.picker.frame:GetTop() - select.frame:GetTop()
					eq(drop, size == 'full' and 0 or 32, tag .. ': Profile on the first line at full, the second at half')
					local lowest = f.picker.frame:GetBottom()
					for _, w in ipairs(f.pickerWidgets) do
						check(w.frame:GetBottom() <= f.picker.frame:GetBottom() + 1, tag .. ': no piece above the picker')
						lowest = math.min(lowest, w.frame:GetBottom() + (w.frame:GetHeight() > 24 and 1 or 0))
					end
					eq(f.body:GetTop(), lowest, tag .. ": the body's top under the last line")
					local right = f.main:GetLeft() + 28 + (size == 'half' and halfBody or 774)
					for _, w in ipairs(f.pickerWidgets) do
						check(w.frame:GetRight() <= right, tag .. ': no piece past the body\'s width')
					end
				end
				-- Half with the sidebar collapsed: the same line, the footer's tools clear of it.
				OW:SetWindowSize('half')
				OW:SetSidebarShown(false)
				eq(line(f), types, where .. ' collapsed: the line')
				eq(#f.footerWidgets, 0, where .. ' collapsed: the footer holds none')
				local off = P.off(f.main)
				eq(#off, 0, where .. ' collapsed: whole pixels: ' .. P.report(off))
				OW:SetSidebarShown(true)
				OW:SetWindowSize('full')
				st.Config:Close()
			end
		end
	end
	stub.size_noise = 0
	st.config.profile.theme.name = 'thick'
	local errs = take_errors()
	eq(#errs, 0, 'no errors: ' .. tostring(errs[1]))
end)
