-- SaftUI-Core/Config/optionsnav.lua and the wiring in config.lua: Config:Open
-- and GetWindow, the sidebar (commands, Global settings, Profiles, the
-- categories), the pages and tabs Open selects, the picker's label, and the
-- list and dialog sitting above the window. The last case pins /sui under
-- Thick and Thin against Blizzard; its count includes the Keybinds command the
-- sidebar case adds with AddCommand, which every window after it draws.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow
local frames, click, close_all, keys, cell = H.frames, H.click, H.close_all, H.keys, H.cell
local drawn, theme, size_of, rgba = H.drawn, H.theme, H.size_of, H.rgba

------------------------------------------------------------------ opening, the sidebar and the wiring

test('Config:Open shows the window; GetWindow is truthy only while it is open', function()
	eq(st.Config:GetWindow(), nil, 'nothing before it opens')
	st.Config:Open()
	check(OW:IsShown(), 'shown')
	check(st.Config:GetWindow() ~= nil, 'GetWindow while open')
	eq(st.Config:GetWindow(), frames().window, 'it is the window frame')
	st.Config:Close()
	check(not OW:IsShown(), 'Close hides it')
	eq(st.Config:GetWindow(), nil, 'GetWindow nil once closed')

	-- The close X (st:CreateCloseButton) and the footer's Close do the same.
	st.Config:Open()
	click(st:GetCloseButton(frames().window))
	eq(st.Config:GetWindow(), nil, 'the X closes it')
	st.Config:Open()
	click(frames().closeButton)
	eq(st.Config:GetWindow(), nil, 'Close closes it')
end)

test('the sidebar: commands, Global settings, Profiles, then the categories in order', function()
	local ran = 0
	st.Config:AddCommand('kb', 'Keybinds', function() ran = ran + 1 end)
	st.Config:Open()
	eq(keys(frames().actions, 'label'), 'Edit mode,Keybinds', 'Edit mode, then each AddCommand')
	click(frames().actions[2])
	eq(ran, 1, 'a command button runs its func')

	local names = {}
	for i, item in ipairs(frames().nav) do names[i] = item.group and ('[' .. item.group .. ']') or item.name end
	eq(table.concat(names, ','), 'Global settings,Profiles,[Frames],Bags,Chat,Unitframes,[Combat],Auras,[Info],Loot,[Other],Zeta',
		'drawn in order')
	check(st.Config:GetOptionsTable().topmenu == nil, 'no topmenu group any more')
	eq(type(st.Config:GetCommands()), 'table', 'the commands, for the sidebar')
	eq(st.Config:GetCommands()[1].label, 'Keybinds', 'as added')

	-- Clicking an entry opens its page.
	for _, item in ipairs(frames().nav) do
		if item.key == 'Loot' then click(item) end
	end
	eq(OW:GetState().page, 'Loot', 'clicked page')
	eq(frames().title:GetText(), 'Loot', 'its title')
	close_all()
end)

test("a real module's category: Experience is under Info", function()
	CreateFrame('Frame', 'Minimap', UIParent)
	-- Misc's defaults (the bar's among them): AceDB filled the profile from every
	-- default at login, as Misc's config.lua loads before SaftUI:OnEnable makes it.
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/experience.lua')
	st:GetModule('Experience'):Enable()
	local root = st.Config:GetOptionsTable()
	local found = false
	for _, page in ipairs(OM.Pages(root)) do
		if page.key == 'Experience' then
			found = true
			eq(page.category, 'Info', 'Experience is Info')
		end
	end
	check(found, 'Experience has a page')
end)

test('Global settings has General, Fonts, Colors, Theme and Edit mode tabs, and the sidebar has no Edit mode page', function()
	local root = st.Config:GetOptionsTable()
	eq(root.EditMode, nil, 'no EditMode page in the tree')
	for _, page in ipairs(OM.Pages(root)) do
		check(page.key ~= 'EditMode', 'no EditMode page')
	end
	-- Zeta is the only page left in Other here; with none, there is no heading.
	for _, entry in ipairs(OW.SidebarEntries(OM.Pages({ Fonts = root.Fonts, profile = root.profile }))) do
		check(entry.group ~= 'Other', 'no Other heading when nothing is uncategorized')
	end

	local view = OM.BuildView(root, 'Fonts')
	eq(view.title, 'Global settings', 'the page')
	eq(keys(view.tabs), 'general,fonts,colors,theme,editmode', 'General, Fonts, Colors, Theme, then Edit mode')
	eq(keys(view.tabs, 'name'), 'General,Fonts,Colors,Theme,Edit mode', 'tab names')
	eq(view.tab, 'general', 'General is the tab the page opens on')
	eq(root.Colors, nil, 'no Colors page in the tree')
	eq(root.General, nil, 'no General page in the tree')
	eq(root.Fonts.order, 1, 'the page keeps its place')
	eq(root.Fonts.desc, "Settings used across SaftUI: icon zoom and window title bars, fonts, colors, themes, and edit mode's grid and snapping.")

	view = OM.BuildView(root, 'Fonts', { tab = 'editmode' })
	eq(view.tab, 'editmode', 'Edit mode selected')
	eq(#view.subtabs, 0, 'its settings are a section of the tab, not another tab row')
	local grid
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'grid' then grid = r end
		end
	end
	check(grid ~= nil, 'Show grid is a row')
	local before = st.EditModeFrames:GetSettings().grid
	eq(OM.Get(root, grid), before, 'reads the setting')
	OM.Set(root, grid, not before)
	eq(st.EditModeFrames:GetSettings().grid, not before, 'setting it changes the edit mode settings')
	OM.Set(root, grid, before)

	-- The Fonts tab still reads the font settings.
	view = OM.BuildView(root, 'Fonts', { tab = 'fonts' })
	local size
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'font_size' and not size then size = r end
		end
	end
	check(size ~= nil, 'a font size row')
	check(type(OM.Get(root, size)) == 'number', 'reads a number')
end)

test("Icon zoom's box shows the profile's fraction as a percent, and a typed percent stores the fraction", function()
	st.Config:Open('Fonts', 'general')
	eq(OW:GetState().tab, 'general', 'the General tab')
	eq(drawn(), 'icon_trim,icon_preview,header_height,clamp_inset', "the tab's rows, Icon zoom's preview after it")
	local w = cell('icon_trim').widget
	eq(w.edit:GetText(), '6.5%', 'the default 0.065 shows as 6.5%')
	w.edit:SetText('10')
	stub.fire_script(w.edit, 'OnEnterPressed')
	eq(st.config.profile.misc.icon_trim, 0.1, 'typed 10 stores 0.1')
	eq(cell('icon_trim').widget.edit:GetText(), '10%', 'and shows 10%')
	w = cell('icon_trim').widget
	w.edit:SetText('35%')
	stub.fire_script(w.edit, 'OnEnterPressed')
	eq(st.config.profile.misc.icon_trim, 0.2, 'past the top, 20%')
	st.config.profile.misc.icon_trim = 0.065
	close_all()
end)

test("Open({'Unitframes','player','general'}) selects the page, the picker value and the tab", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local state = OW:GetState()
	eq(state.page, 'Unitframes', 'page')
	eq(state.pick, 'player', 'picker')
	eq(state.tab, 'general', 'tab')
	eq(frames().picker.text:GetText(), 'Player', 'the picker shows the unit')
	eq(keys(frames().tabs, 'key'), 'general,power', 'the element tabs')
	check(frames().tabs[1].active and not frames().tabs[2].active, 'General is the active tab')
	eq(drawn(), 'copy,enable,width', "the unit's Copy from, then General's rows")

	-- Another path, with the window already open.
	st.Config:Open('Unitframes', 'target', 'power')
	state = OW:GetState()
	eq(state.pick .. '/' .. state.tab, 'target/power', 'target, Power')
	eq(drawn(), 'copy,enable,height,size', "Power's rows")

	-- Picker values: the units only (the profile is the page's footer control).
	eq(keys(OM.BuildView(OW:GetRoot(), 'Unitframes').picker.values), 'player,target', 'picker entries')
	close_all()
end)

test("the picker is labelled with the page's pickerLabel, else its name", function()
	local function label()
		st.Config:Open('Unitframes', 'player')
		local drawnLabel = frames().pickerLabel:GetText()
		eq(OM.BuildView(OW:GetRoot(), 'Unitframes').picker.name, drawnLabel, 'the view and the window agree')
		close_all()
		return drawnLabel
	end
	eq(label(), 'Unitframes', 'no pickerLabel: the page name')
	ufPickerLabel = 'Unit'
	st.Config:Refresh()
	eq(label(), 'Unit', 'pickerLabel set: the label')
	ufPickerLabel = nil
end)

test("Open({'Inventory','bag','text'}) selects the tab and the second row's tab", function()
	st.Config:Open('Inventory', 'bag', 'text')
	local state = OW:GetState()
	eq(state.page .. '/' .. state.tab .. '/' .. state.subtab, 'Inventory/bag/text', 'tab and subtab')
	eq(state.pick, nil, 'no picker')
	eq(keys(frames().tabs, 'key'), 'general,bag', 'the first row')
	eq(keys(frames().subtabs, 'key'), 'general,text', 'the second row')
	check(frames().subtabs[2].active, 'Text is active')
	check(frames().subLine:IsShown(), "the second row's line")
	check(not frames().picker.frame:IsShown(), 'no picker drawn')
	eq(drawn(), 'count', "Text's row")
	click(frames().subtabs[1])
	eq(drawn(), 'size', 'a subtab click')
	click(frames().tabs[1])
	eq(OW:GetState().tab, 'general', 'a tab click')
	eq(#frames().subtabs, 0, 'General has no second row')
	check(not frames().subLine:IsShown(), 'nor its line')
	close_all()
end)

test('the select list and the confirm dialog sit above the window', function()
	st.Config:Open('Unitframes', 'player', 'general')
	eq(frames().window:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'the window, like the old AceGUI one')
	click(frames().picker.frame)
	eq(W.GetListFrames().catcher:GetFrameStrata(), 'TOOLTIP', 'the list above it')
	W.CloseList()
	W.Confirm('Sure?', function() end)
	eq(W.GetDialogFrames().catcher:GetFrameStrata(), 'TOOLTIP', 'the dialog above it')
	st.Config:Close()
	eq(W.ConfirmText(), nil, 'closing the window answers the dialog No')
	close_all()
end)

------------------------------------------------------------------ under the Blizzard theme

test('under Thick and Thin /sui is unchanged', function()
	-- A page with a row of every type, on two tabs so the tabs draw.
	local store = {
		toggle = true, range = 3, select = 'a', input = 'text', color = { 1, 0, 0, 1 }, keybinding = 'K',
		multiselect = { a = true },
		position = { point = 'TOP', rel_point = 'TOP', x_off = 1, y_off = 2, frame = 'UIParent' },
	}
	local EVERY = st:NewModule('EveryType')
	function EVERY:GetConfigTable()
		local function o(t, order, fields)
			local option = { type = t, name = 'A ' .. t, order = order }
			for k, v in pairs(fields or {}) do option[k] = v end
			return option
		end
		return {
			name = 'Every type', type = 'group', category = 'Info', childGroups = 'tab',
			args = {
				one = {
					order = 1, name = 'One', type = 'group',
					get = function(info, part)
						local v = store[info[#info]]
						if info[#info] == 'position' or info[#info] == 'multiselect' then return v[part] end
						if type(v) == 'table' then return unpack(v) end
						return v
					end,
					set = function() end,
					args = {
						toggle = o('toggle', 1),
						small = o('toggle', 2, { size = 'small' }),
						range = o('range', 3, { min = 0, max = 10, step = 1 }),
						select = o('select', 4, { values = { a = 'A', b = 'B' } }),
						multiselect = o('multiselect', 5, { values = { a = 'A', b = 'B' } }),
						input = o('input', 6),
						smallinput = o('input', 7, { size = 'small', get = function() return 'x' end }),
						color = o('color', 8),
						execute = o('execute', 9, { func = function() end }),
						keybinding = o('keybinding', 10),
						description = o('description', 11),
						position = o('position', 12, { target = 'name' }),
					},
				},
				two = { order = 2, name = 'Two', type = 'group', args = {
					on = { type = 'toggle', name = 'On', get = function() return true end, set = function() end },
				} },
			},
		}
	end

	-- What /sui draws: each cell's rect, each widget's frame size, the colors
	-- of every box shown in it (Box: fill, edge and the dark line), and the
	-- window's own boxes and buttons and tabs. sizesOnly leaves the colors out.
	local function whole(v) return v == math.floor(v) end
	local function drawn(sizesOnly)
		local out = {}
		local function add(s) out[#out + 1] = s end
		local function rect(name, frame)
			local l, t, r, b = frame:GetLeft(), frame:GetTop(), frame:GetRight(), frame:GetBottom()
			for _, v in ipairs({ l, t, r, b }) do check(whole(v), name .. ' on whole pixels') end
			add(name .. ' ' .. size_of(frame))
		end
		local function boxes(frame, name)
			if not frame:IsShown() or sizesOnly then return end
			if frame.backdropInfo then
				add(name .. ' fill ' .. rgba(frame:GetBackdropColor()) .. ' edge ' .. rgba(frame:GetBackdropBorderColor()))
			end
			for i, child in ipairs({ frame:GetChildren() }) do boxes(child, name .. '.' .. i) end
		end
		for _, cell in ipairs(OW.GetDrawnRows()) do
			local key = cell.row.key
			local _, _, _, x, y = cell.frame:GetPoint(1)
			check(whole(x) and whole(y), key .. ': its cell on whole pixels')
			add(key .. ' cell ' .. x .. ',' .. y .. ' ' .. size_of(cell.frame))
			rect(key .. ' widget', cell.widget.frame)
			boxes(cell.widget.frame, key)
		end
		local f = frames()
		for _, name in ipairs({ 'search', 'reloadButton', 'closeButton' }) do
			rect(name, f[name])
			boxes(f[name], name)
		end
		for i, button in ipairs(f.actions) do
			rect('action ' .. i, button)
			boxes(button, 'action ' .. i)
		end
		for i, tab in ipairs(f.tabs) do
			rect('tab ' .. i, tab)
			if not sizesOnly then add('tab ' .. i .. ' underline ' .. tostring(tab.underline:IsShown())) end
		end
		check(#OW.GetDrawnRows() >= 12, 'a row of every type')
		return table.concat(out, '\n')
	end

	theme('thick')
	st.Config:Open('EveryType')
	local thick = drawn()
	local sizes = drawn(true)
	theme('blizzard')
	-- Blizzard keeps the flat layout (rows 34 tall, no padding, a gap of 40
	-- between the columns); Thick and Thin lay rows out 38 tall on panels, so
	-- the cells' rects differ and the widgets' stay. The flat layout is pinned
	-- by a literal, as /sui drew it before the panels: every cell and widget.
	local flat = drawn(true)
	check(flat ~= sizes, 'Blizzard: the cells are laid out flat')
	local GOLDEN_BLIZZARD = table.concat({
		'toggle cell 0,-20 367x34',
		'toggle widget 18x18',
		'small cell 407,-20 171x34',
		'small widget 18x18',
		'range cell 0,-54 367x34',
		'range widget 168x24',
		'select cell 407,-54 367x34',
		'select widget 170x24',
		'multiselect cell 0,-88 367x56',
		'multiselect widget 170x44',
		'input cell 407,-88 367x34',
		'input widget 170x24',
		'smallinput cell 0,-144 171x34',
		'smallinput widget 60x24',
		'color cell 407,-144 367x34',
		'color widget 170x24',
		'execute cell 0,-178 367x34',
		'execute widget 96x26',
		'keybinding cell 407,-178 367x34',
		'keybinding widget 170x24',
		'description cell 0,-212 774x34',
		'description widget 774x19',
		'position cell 0,-298 774x77',
		'position widget 331x65',
		'search 182x24',
		'reloadButton 96x26',
		'closeButton 80x26',
		'action 1 88x24',
		'action 2 88x24',
		'tab 1 30x24',
		'tab 2 30x24',
	}, '\n')
	eq(flat, GOLDEN_BLIZZARD, 'Blizzard: every cell and widget as it was drawn before the panels')
	for line in sizes:gmatch('[^\n]+') do
		-- The description wraps to its cell: 746 inside the padding, 774 flat.
		if line:find(' widget ', 1, true) and not line:find('^description widget') then
			check(flat:find(line, 1, true), 'Blizzard: every widget keeps its rect: ' .. line)
		end
	end
	theme('thin')
	eq(drawn(), thick, 'Thin: as under Thick before Blizzard')
	theme('thick')
	eq(drawn(), thick, 'Thick again: as before Blizzard')
	theme('blizzard')
	eq(drawn(true), flat, 'Blizzard again: as before')
	theme('thick')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
