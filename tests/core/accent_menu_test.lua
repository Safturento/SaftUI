-- The Accent row's dots menu (Media/states.lua's ST.MenuGroup, the color widget's slot in
-- optionstypes.lua, optionsmenu.lua's colorEdit, optionspreview.lua's statepreview row):
-- how the interaction states are made from the Accent, live as you drag, each setting with
-- its reset.
--
-- Real: Core's Config on a real AceDB-3.0 and AceConfigRegistry-3.0, the model, the widgets,
-- the body and the window's files (options_window_helpers.lua), with the real Colors and
-- Theme modules and the states engine. The mouse is played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')
local st = SaftUI
local ST = st.States
local OM, W, OB, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local cell, close_all, click, tick = H.cell, H.close_all, H.click, H.tick
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function M() return OW.GetMenuFrames() end
local function states() return st.config.profile.theme.states end
local function menu_cell(key)
	for _, c in ipairs(M().body.cells) do
		if c.row.key == key then return c end
	end
end
local function open_menu()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	check(row, 'the Accent row is drawn')
	click(row.widget.dots)
	return row
end

local function fresh()
	close_all()
	local s = states()
	for key, value in pairs(st.defaults.theme.states) do s[key] = value end
	st.config.profile.theme.accent = CreateColor(0, 0.68, 0.94)
	ST.Changed()
	T.theme('thick')
end

local function rows()
	local out = {}
	for _, c in ipairs(M().body.cells) do out[#out + 1] = c.row.key end
	return table.concat(out, ',')
end


-- Counts the passes of the accent group (a follower of its own), from now on.
local counter = {}
local passes = 0
local function count_passes()
	passes = 0
	st:FollowColor(counter, 'accent', nil, function() passes = passes + 1 end)
end

local function nav_look()
	for _, child in ipairs({ OW.GetFrames().navContent:GetChildren() }) do
		local look = st:StateLook(child)
		if look and look.bar and look.bar.shown then return look end
	end
end

-- The Accent row's strip: its six buttons' looks.
local function strip()
	return menu_cell('preview').widget.pieces
end

local function reset_icon(c) return c.frame.defaultReset end

------------------------------------------------------------------ the row

test('the Accent row has its swatch, its reset and the dots; a color row without a menu is as before (170)', function()
	fresh()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	eq(row.widget.width, 190, 'the control: the field and the slot')
	eq(row.widget.frame:GetWidth(), 170, 'the field itself is as wide as ever')
	local dots = row.widget.dots
	check(dots and dots:IsShown(), 'the dots')
	eq(dots:GetWidth(), 16, 'a 16 wide slot')
	eq(dots.icon:GetTexture(), st.icons.ellipsisVertical, 'Lucide ellipsis-vertical')
	local point, rel, relPoint, x = dots:GetPoint()
	eq(point .. relPoint .. x, 'LEFTRIGHT4', "4 after the field's right (the font row's gap)")
	eq(dots:GetLeft() - row.widget.frame:GetRight(), 4, 'the slot is after the field')
	eq(row.frame:GetRight() - dots:GetRight(), 0, "the slot ends at the row's right edge")
	eq(row.widget.frame:GetLeft(), row.frame:GetRight() - 190, 'the field starts 190 from it')
	-- the swatch and its reset are unchanged
	eq(T.rgb(unpack(stub.state(row.widget.swatch).color_texture)), '0.00,0.68,0.94')
	row.widget:Commit(0.9, 0.1, 0.2)
	check(reset_icon(cell('accent')) and reset_icon(cell('accent')):IsShown(), 'its own reset shows while it differs')
	eq(reset_icon(cell('accent')):GetRight() <= row.widget.frame:GetLeft(), true, 'by the field, not the slot')
	stub.click(reset_icon(cell('accent')))
	-- a color row without a menu: a Colors page one
	st.Config:Open('Fonts', 'colors')
	local other
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.type == 'color' then other = c break end
	end
	check(other, 'a color row on the Colors page')
	eq(other.widget.width, 170, 'a color row without a menu is 170')
	check(not (other.widget.dots and other.widget.dots:IsShown()), 'with no slot shown (a pooled widget may have made one)')
	eq(other.frame:GetRight() - other.widget.frame:GetRight(), 0, 'at the row\'s right edge, as before')
	-- under Blizzard the gap is 8 (the font row's)
	T.theme('blizzard')
	st.Config:Open('Fonts', 'theme')
	eq(cell('accent').widget.width, 194, 'Blizzard: 194, as a font row')
	T.theme('thick')
	close_all()
end)

test('the dots open the menu, or close it when it is this row\'s; its tooltip', function()
	fresh()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	click(row.widget.dots)
	check(OW:IsMenuShown(row.widget), 'opened')
	click(row.widget.dots)
	check(not OW:IsMenuShown(), 'closed by a second click')
	stub.fire_script(row.widget.dots, 'OnEnter', true)
	eq(GameTooltip:GetOwner(), row.widget.dots, 'the tooltip is the dots\'')
	check(GameTooltip:IsShown(), 'shown')
	stub.fire_script(row.widget.dots, 'OnLeave', true)
	-- a disabled row: no mouse on the slot
	row.widget:SetDisabled(true)
	eq(row.widget.dots:IsMouseEnabled(), false, 'a disabled row: the slot takes no mouse')
	eq(OW:OpenMenu(row.widget), false, 'and no menu')
	row.widget:SetDisabled(false)
	eq(row.widget.dots:IsMouseEnabled(), true)
	close_all()
end)

------------------------------------------------------------------ the menu

test('the menu: its title, the preview, then Derivation, Strengths, Tones, Hue shift, in order, with their descs', function()
	fresh()
	open_menu()
	eq(M().title:GetText(), 'Accent')
	eq(M().frame:GetWidth(), 400)
	eq(rows(), 'preview,mode,hover,pushed,selected,fade,disabled,step,shift,direction,chroma')
	local view = OM.BuildView(M().root, OM.MENU_KEY)
	local titles = {}
	for _, section in ipairs(view.sections) do titles[#titles + 1] = tostring(section.title) end
	eq(table.concat(titles, '|'), 'nil|Strengths|Tones|Hue shift', 'the sections')
	local names = {}
	for _, c in ipairs(M().body.cells) do names[#names + 1] = c.row.name end
	eq(table.concat(names, ','), 'States,Derivation,Hover,Pushed,Selected fill,Selected fade,Disabled,Lightness step,Hue shift,Direction,Chroma change')
	local descs = {
		mode = 'How hover, pushed and selected are made from the Accent. Layers lays the Accent itself over a widget. Tones uses a lighter tone of it under the mouse and a darker one while held. Hue-shifted tones also turn the lighter tone toward warm and the darker toward cool, as a painter shades.',
		hover = 'How strongly a widget under the mouse is tinted: its body, never only its edge.',
		pushed = "How strongly a widget is tinted while it's held down.",
		selected = "How strongly the fill of a selected, checked or current widget starts, at its left. Its edge, bar or underline is always the full Accent.",
		fade = 'How far across a selected widget its fill fades to nothing: at 100% it fades over the whole width.',
		disabled = 'How see-through a disabled widget is: at 40% it shows at 40%.',
		step = 'How much lighter the hover tone and how much darker the pushed tone are than the Accent, in OKLCH lightness (0 to 1).',
		shift = "How far the tones' hue turns, in degrees, toward warm (yellow) or cool (violet blue). It never turns past it.",
		direction = 'Which way the hue turns: warm light turns the lighter tone toward yellow and the darker toward blue; cool light the reverse.',
		chroma = "How much less colorful the lighter tone is, and how much more the darker, as a share of the Accent's.",
	}
	for key, desc in pairs(descs) do
		eq(menu_cell(key).row.option.desc, desc, key .. "'s desc")
	end
	-- the ranges and steps, each as the spec's table
	local function range_of(key)
		local o = menu_cell(key).row.option
		return o.min .. '-' .. o.max .. '/' .. o.step .. (o.isPercent and '%' or '')
	end
	eq(range_of('hover'), '0-0.6/0.01%'); eq(range_of('pushed'), '0-0.8/0.01%'); eq(range_of('selected'), '0-0.6/0.01%')
	eq(range_of('fade'), '0.1-1/0.01%'); eq(range_of('disabled'), '0.1-0.9/0.01%')
	eq(range_of('step'), '0.02-0.2/0.01'); eq(range_of('shift'), '0-60/1'); eq(range_of('chroma'), '0-0.3/0.01%')
	-- the values shown are the defaults
	eq(menu_cell('hover').widget.edit:GetText(), '16%')
	eq(menu_cell('step').widget.edit:GetText(), '0.08')
	eq(menu_cell('shift').widget.edit:GetText(), '20')
	eq(menu_cell('mode').widget.text:GetText(), 'Tones')
	eq(menu_cell('direction').widget.text:GetText(), 'Warm light, cool shadow')
	close_all()
end)

test('the preview row: the states strip at the menu\'s width, painted from the profile, no mouse, no reset', function()
	fresh()
	open_menu()
	local c = menu_cell('preview')
	eq(c.widget.stripWidth, 348, 'a panel leaves 348')
	local p = strip()
	-- six tiles across it, narrower than the picker's 58 (4 apart at least), whole pixels
	local lefts = {}
	for i, tile in ipairs(p.tiles) do lefts[i] = tile:GetLeft() - c.widget.frame:GetLeft() end
	eq(p.tile, 54)
	eq(lefts[1], 0); eq(lefts[6] + 54, 348, 'the last at the right')
	for i = 2, 6 do check(lefts[i] - lefts[i - 1] >= 54 + 4 - 1, 'tile ' .. i .. ' is apart from the last') end
	local held = {}
	for i, b in ipairs(p.buttons) do
		held[i] = (st:GetState(b, 'hover') and 'h' or '') .. (st:GetState(b, 'pushed') and 'p' or '') ..
			(st:GetState(b, 'selected') and 's' or '') .. (st:GetState(b, 'disabled') and 'd' or '') .. '-'
		eq(b:IsMouseEnabled(), false, 'button ' .. i .. ' takes no mouse')
	end
	eq(table.concat(held), '-h-p-s-hs-d-', 'each held in its state')
	local look = st:StateLook(p.buttons[2])
	check(SL.near(look.layer, '5bc6ff'), 'the hover tile is the lighter tone')
	eq(look.layer.a, 0.16)
	eq(c.row.option.noReset, 'a picture of the states, not a setting')
	check(not reset_icon(c) or not reset_icon(c):IsShown(), 'no reset on it')
	eq(c.frame:GetHeight() > 60, true, 'a row of its own')
	close_all()
end)

test('M1: the strip is laid out every time it is shown: hiding clears all four held states', function()
	fresh()
	open_menu()
	local p = strip()
	-- the menu closes and opens again: the pooled row's strip has its states held
	OW:CloseMenu()
	for _, b in ipairs(p.buttons) do
		eq(st:GetState(b, 'selected') and 1 or 0, 0, 'hiding the strip cleared its states (the kit button\'s own Paint)')
	end
	click(cell('accent').widget.dots)
	local q = strip()
	local held = {}
	for i, b in ipairs(q.buttons) do
		held[i] = (st:GetState(b, 'hover') and 'h' or '') .. (st:GetState(b, 'pushed') and 'p' or '') ..
			(st:GetState(b, 'selected') and 's' or '') .. (st:GetState(b, 'disabled') and 'd' or '') .. '-'
	end
	eq(table.concat(held), '-h-p-s-hs-d-', 'held again after a show')
	-- shown again by anything but a bind: the frame's OnShow lays it out
	local w = menu_cell('preview').widget
	w.frame:Hide()
	for _, b in ipairs(q.buttons) do st:SetState(b, 'selected', false) end
	w.frame:Show()
	eq(st:GetState(q.buttons[4], 'selected'), true, 'a Show alone holds the states again')
	close_all()
end)

test('a settings table that is not the saved one is undone by a pass, so the menu saves its settings as they move', function()
	fresh()
	open_menu()
	menu_cell('hover').widget:Commit(0.5)
	eq(states().hover, 0.5, 'saved at once')
	local look = st:StateLook(strip().buttons[2])
	eq(look.layer.a, 0.5, 'the strip shows it')
	st:ColorChanged('accent')
	look = st:StateLook(strip().buttons[2])
	eq(look.layer.a, 0.5, 'and a pass keeps it: the profile is what every state reads')
	close_all()
end)

------------------------------------------------------------------ by mode

test('by mode: Layers dims Tones and Hue shift with their reasons; Tones dims Hue shift; a dimmed row keeps its value', function()
	fresh()
	open_menu()
	local function dim() -- which rows are dimmed
		local out = {}
		for _, c in ipairs(M().body.cells) do
			if c.row.disabled then out[#out + 1] = c.row.key end
		end
		return table.concat(out, ',')
	end
	eq(dim(), 'shift,direction,chroma', 'Tones: Hue shift is dimmed')
	for _, key in ipairs({ 'shift', 'direction', 'chroma' }) do
		eq(menu_cell(key).row.disabledDesc, 'Only for Hue-shifted tones.', key)
	end
	menu_cell('mode').widget:Commit('layers')
	eq(dim(), 'step,shift,direction,chroma', 'Layers: Tones and Hue shift')
	eq(menu_cell('step').row.disabledDesc, 'Only for Tones and Hue-shifted tones.')
	eq(menu_cell('shift').row.disabledDesc, 'Only for Hue-shifted tones.')
	eq(menu_cell('step').widget.disabled, true)
	menu_cell('mode').widget:Commit('hue')
	eq(dim(), '', 'Hue-shifted tones: none')
	-- a value kept while dimmed, and no reset on a dimmed row
	menu_cell('shift').widget:Commit(45)
	menu_cell('mode').widget:Commit('tones')
	eq(dim(), 'shift,direction,chroma')
	eq(states().shift, 45, 'the dimmed row keeps its value')
	eq(menu_cell('shift').widget.edit:GetText(), '45')
	check(not reset_icon(menu_cell('shift')) or not reset_icon(menu_cell('shift')):IsShown(), 'no reset icon on a dimmed row, though it differs')
	menu_cell('mode').widget:Commit('hue')
	check(reset_icon(menu_cell('shift')) and reset_icon(menu_cell('shift')):IsShown(), 'and it is back once the mode uses it')
	-- the menu's height does not change with the mode
	local h = M().frame:GetHeight()
	menu_cell('mode').widget:Commit('layers')
	eq(M().frame:GetHeight(), h, 'dimmed, not hidden: the menu does not jump')
	close_all()
end)

test('the derivation mode is the one every state reads', function()
	fresh()
	open_menu()
	menu_cell('mode').widget:Commit('layers')
	eq(ST.Current().mode, 'layers')
	local look = st:StateLook(strip().buttons[2])
	check(SL.near(look.layer, '00adf0') or SL.near(look.layer, '00adf0'), 'Layers lays the Accent itself')
	menu_cell('mode').widget:Commit('hue')
	eq(ST.Current().mode, 'hue')
	check(not SL.near(st:StateLook(strip().buttons[2]).layer, '5bc6ff'), 'Hue-shifted turns the tone')
	close_all()
end)

------------------------------------------------------------------ resets

test('every setting has a reset once it differs, and the reset puts the default back and passes the accent', function()
	fresh()
	open_menu()
	local defaults = st.defaults.theme.states
	local plan = {
		{ 'mode', 'layers' }, { 'hover', 0.30 }, { 'pushed', 0.5 }, { 'selected', 0.1 }, { 'fade', 0.4 },
		{ 'disabled', 0.7 }, { 'step', 0.12 }, { 'shift', 30 }, { 'direction', 'cool' }, { 'chroma', 0.2 },
	}
	for _, item in ipairs(plan) do
		local key, value = item[1], item[2]
		if key ~= 'mode' then menu_cell('mode').widget:Commit('hue') end -- so every row is live
		local c = menu_cell(key)
		check(not reset_icon(c) or not reset_icon(c):IsShown(), key .. ': no reset at its default')
		c.widget:Commit(value)
		c = menu_cell(key)
		local icon = reset_icon(c)
		check(icon and icon:IsShown(), key .. ': the reset shows once it differs')
		C.step(st)
		count_passes()
		local serial = ST.serial
		stub.click(icon)
		eq(states()[key], defaults[key], key .. ': the default is back')
		check(ST.serial > serial, key .. ': the cache is stale (ST.serial up)')
		C.step(st)
		eq(passes, 1, key .. ': one accent pass')
		c = menu_cell(key)
		check(not reset_icon(c) or not reset_icon(c):IsShown(), key .. ': the icon is gone')
		menu_cell('mode').widget:Commit('tones')
	end
	close_all()
end)

test('Hover to 30%: the reset shows, a click puts 16% back: 0.16, ST.serial up, one accent pass', function()
	fresh()
	open_menu()
	menu_cell('hover').widget:Commit(0.3)
	eq(ST.Current().h, 0.3)
	local icon = reset_icon(menu_cell('hover'))
	check(icon and icon:IsShown(), 'the reset icon shows')
	C.step(st)
	count_passes()
	local serial = ST.serial
	stub.click(icon)
	eq(states().hover, 0.16)
	eq(ST.serial, serial + 1)
	C.step(st)
	eq(passes, 1, 'one pass')
	eq(ST.Current().h, 0.16)
	close_all()
end)

------------------------------------------------------------------ live

test('a set reaches every state frame: Selected fade to 100% sets each shown fill to right 1; the page behind follows', function()
	fresh()
	open_menu()
	local before = nav_look()
	check(before and before.fill.shown, 'the open page is selected, with a fill')
	check(math.abs(before.fill.right - 1 / 0.7) < 1e-6, 'right 1 / 0.7 at the default')
	menu_cell('fade').widget:Commit(1)
	local look = nav_look()
	eq(look.fill.right, 1, "the sidebar's selected fill")
	local seen = 0
	for _, b in ipairs(strip().buttons) do
		local l = st:StateLook(b)
		if l.fill and l.fill.shown then
			seen = seen + 1
			eq(l.fill.right, 1, 'the strip: a shown fill')
		end
	end
	eq(seen, 2, 'two of the strip\'s tiles are selected')
	local underlined = 0
	for _, child in ipairs({ OW.GetFrames().main:GetChildren() }) do
		local tab = st:StateLook(child)
		if tab and tab.shape == 'tab' and tab.fill and tab.fill.shown then
			underlined = underlined + 1
			eq(tab.fill.right, 1, "the active tab's fill")
		end
	end
	check(underlined >= 1, 'a tab is lit')
	-- Disabled: the strip's disabled tile and the page's dimmed composite follow it
	menu_cell('disabled').widget:Commit(0.7)
	eq(strip().buttons[6]:GetAlpha(), 0.7, 'the strip\'s Disabled tile')
	close_all()
end)

test('a drag in the menu is one pass a frame, and the whole pass at close (Review Focus 5)', function()
	fresh()
	open_menu()
	check(st:InColorEdit(), 'the menu began a color edit as it opened')
	count_passes()
	local w = menu_cell('hover').widget
	stub.fire_script(w.slider, 'OnMouseDown')
	for i = 1, 20 do w.slider:SetValue(0.2 + i * 0.01) end
	eq(passes, 0, 'twenty changes: no pass yet')
	eq(states().hover, 0.4, 'but the profile has the last value')
	C.step(st)
	eq(passes, 1, 'one pass on the frame, for all twenty')
	C.step(st)
	eq(passes, 1, 'and none after')
	stub.fire_script(w.slider, 'OnMouseUp')
	for i = 1, 5 do w.slider:SetValue(0.4 + i * 0.01) end
	OW:CloseMenu()
	check(not st:InColorEdit(), 'closing ends the edit')
	check(passes >= 2, 'the whole pass ran at the close')
	local n = passes
	C.step(st)
	eq(passes, n, 'nothing left due')
	close_all()
end)

test('L2: the edit is counted: the picker and the menu each hold it, in either order, and it ends when the last lets go', function()
	fresh()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	-- picker first, then the menu, then the picker closes first: the throttle stays until the menu closes
	row.widget:Pick()
	check(st:InColorEdit(), "the picker's edit")
	row.widget:OpenMenu()
	check(OW:IsMenuShown(), 'the menu opens over it')
	W.CloseColorPicker(row.widget.frame)
	check(st:InColorEdit(), 'the picker let go: the menu still holds it')
	count_passes()
	local hover = menu_cell('hover').widget
	stub.fire_script(hover.slider, 'OnMouseDown')
	for i = 1, 5 do hover.slider:SetValue(0.2 + i * 0.01) end
	eq(passes, 0, 'changes still wait for the frame')
	C.step(st)
	eq(passes, 1, 'one pass for the five')
	stub.fire_script(hover.slider, 'OnMouseUp')
	OW:CloseMenu()
	check(not st:InColorEdit(), 'ended when the last (the menu) let go')
	-- the reverse: the menu first, the picker, the menu closes first
	row = cell('accent')
	row.widget:OpenMenu()
	check(st:InColorEdit(), 'the menu holds it')
	row.widget:Pick()
	OW:CloseMenu()
	check(st:InColorEdit(), 'the menu let go: the picker still holds it')
	W.CloseColorPicker(row.widget.frame)
	check(not st:InColorEdit(), "ended with the picker's")
	-- the picker alone, and the menu alone
	row.widget:Pick()
	check(st:InColorEdit()); W.CloseColorPicker(row.widget.frame); check(not st:InColorEdit())
	click(cell('accent').widget.dots)
	check(st:InColorEdit()); OW:CloseMenu(); check(not st:InColorEdit())
	close_all()
end)

test('the cost of a held slider: one accent pass a frame, nothing forbidden, under 4 KB per 100 passes; the call count is pinned', function()
	fresh()
	open_menu()
	local w = menu_cell('hover').widget
	-- a pass outside an edit (it runs at once), as the colors' cost cases measure it
	st:EndColorEdit()
	st.config.profile.theme.states.hover = 0.2
	ST.serial = ST.serial + 1
	local m = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, 'under 4 KB over 100 passes (' .. m.kb .. ')')
	eq(m.calls.total / 100, 23, 'the setter calls of one pass with the menu open (pinned)')
	st:BeginColorEdit()
	close_all()
end)

------------------------------------------------------------------ search

test('search finds Hover, Lightness step and the rest on the Accent row', function()
	fresh()
	local root = st.Config:GetOptionsTable()
	local function find(text)
		local out = {}
		for _, r in ipairs(OM.Search(root, text)) do
			if r.menu and r.pageKey == 'Fonts' then out[#out + 1] = r.name .. '@' .. r.path[#r.path] .. ':' .. tostring(r.sectionTitle) end
		end
		return table.concat(out, ',')
	end
	eq(find('hover'), 'Hover@accent:Accent', 'Hover')
	eq(find('lightness'), 'Lightness step@accent:Accent')
	eq(find('pushed'), 'Pushed@accent:Accent')
	eq(find('selected'), 'Selected fill@accent:Accent,Selected fade@accent:Accent')
	eq(find('chroma'), 'Chroma change@accent:Accent')
	check(not find('accent'):find('States', 1, true), 'the picture is no setting: the item\'s name lists the rows, not it')
	check(find('accent'):find('Derivation@accent', 1, true), "the row's name lists every setting under it")
	-- a result opens the page and the menu
	st.Config:Open('Fonts', 'general')
	OW.GetFrames().search:SetText('Hover')
	tick(0.3)
	local found
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.menu and c.row.name == 'Hover' then found = c end
	end
	check(found, 'a result for Hover')
	click(found.frame)
	check(OW:IsMenuShown(cell('accent').widget), "and the Accent's menu opens")
	close_all()
end)

test('the reset walk covers the menu (R.check_page on Global settings)', function()
	fresh()
	local R = load_test_file('lib/reset_walk.lua')
	local root = st.Config:GetOptionsTable()
	local menu = root.Fonts.args.theme.args.accent.menu
	local hover = menu.args.strengths.args.hover
	local saved = hover.saved
	hover.saved = nil
	local problems = R.problems(root, 'Fonts', { allow = { ['Fonts.theme.theme'] = { 'fonts.version' } } })
	local named
	for _, problem in ipairs(problems) do
		if problem:find('accent.menu.strengths.hover', 1, true) then named = problem end
	end
	check(named, 'a menu row with no reset is a problem, named by its path in the menu')
	hover.saved = saved
	local ok = R.problems(root, 'Fonts', { allow = { ['Fonts.theme.theme'] = { 'fonts.version' } } })
	local bad
	for _, problem in ipairs(ok) do
		if problem:find('accent', 1, true) then bad = problem end
	end
	eq(bad, nil, 'every row of the menu has a reset that round-trips')
end)

------------------------------------------------------------------ Blizzard and pixels

test('under Blizzard the slot is white under the mouse and the menu draws on the panel art', function()
	fresh()
	T.theme('blizzard')
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	local dots = row.widget.dots
	eq(dots.blizzard, true)
	stub.fire_script(dots, 'OnEnter', true)
	eq(T.rgb(dots.icon:GetVertexColor()), '1.00,1.00,1.00', 'white under the mouse')
	stub.fire_script(dots, 'OnLeave', true)
	check(T.rgb(dots.icon:GetVertexColor()) ~= '1.00,1.00,1.00', 'and not at rest')
	click(dots)
	check(OW:IsMenuShown(row.widget))
	eq(M().frame.GetBackdropColor ~= nil, true)
	local note = menu_cell('preview').widget.note
	check(note:IsShown(), 'the strip says why it is Thick')
	eq(note:GetText(), "Shown as Thick: Blizzard's art draws its own.")
	for _, tile in ipairs(strip().tiles) do eq(st:DrawnTheme(tile), 'thick', 'Thick tiles under Blizzard') end
	T.theme('thick')
	close_all()
end)

test('whole pixels: the row and the menu under Thick, Thin and Blizzard', function()
	local P = load_test_file('lib/pixels.lua')
	fresh()
	SL.each_look(function(look)
		st.Config:Open('Fonts', 'theme')
		local row = cell('accent')
		eq(#P.off(row.frame), 0, look .. ': the row ' .. P.report(P.off(row.frame)))
		click(row.widget.dots)
		check(OW:IsMenuShown(row.widget), look .. ': open')
		local off = P.off(M().frame)
		eq(#off, 0, look .. ': the menu ' .. P.report(off))
		OW:CloseMenu()
	end)
	close_all()
end)

------------------------------------------------------------------ the box labels' text pick

test('box labels take the readable-text pick: gold at Hover 60%; a caller\'s own color and the font object survive', function()
	fresh()
	st.config.profile.theme.accent = CreateColor(0.9, 0.78, 0.29)
	states().hover = 0.6
	ST.Changed()
	local parent = CreateFrame('Frame', nil, UIParent)
	local b = W.Button(parent, 'Go', function() end)
	b:SetSize(80, 26)
	stub.fire_script(b, 'OnEnter', true)
	eq(T.rgb(b.text:GetTextColor()), '0.07,0.07,0.07', 'the dark text over the pale hover tone')
	stub.fire_script(b, 'OnLeave', true)
	local n = st:Color('text', 'normal')
	eq(T.rgb(b.text:GetTextColor()), T.rgb(n.r, n.g, n.b), 'its own color back (the font object\'s Text > Normal)')
	-- a caller's own color survives a hover at the defaults
	states().hover = 0.16
	ST.Changed()
	b.text:SetTextColor(0.2, 0.8, 0.3)
	stub.fire_script(b, 'OnEnter', true)
	eq(T.rgb(b.text:GetTextColor()), '0.20,0.80,0.30', 'a caller\'s own color is kept under the mouse')
	stub.fire_script(b, 'OnLeave', true)
	eq(T.rgb(b.text:GetTextColor()), '0.20,0.80,0.30')
	-- a field (the color field's code) and a face (a select's) as well
	st.Config:Open('Fonts', 'theme')
	states().hover = 0.6
	ST.Changed()
	local field = cell('accent').widget
	stub.fire_script(field.frame, 'OnEnter', true)
	eq(T.rgb(field.text:GetTextColor()), '0.07,0.07,0.07', 'a color field\'s code')
	stub.fire_script(field.frame, 'OnLeave', true)
	check(T.rgb(field.text:GetTextColor()) ~= '0.07,0.07,0.07', 'and back')
	close_all()
end)

------------------------------------------------------------------ composite widgets follow the Disabled slider

test('composite widgets follow the Disabled slider: range, font row, position block, item, multiselect, and a dimmed menu row', function()
	fresh()
	open_menu()
	-- a dimmed row of the open menu (Hue shift under Tones): a range, a select
	local shift = menu_cell('shift').widget
	eq(shift.frame:GetAlpha(), 0.4, 'dimmed to the Disabled setting')
	states().disabled = 0.7
	ST.Changed()
	C.step(st)
	eq(shift.frame:GetAlpha(), 0.7, 'a range follows the slider with no redraw')
	eq(menu_cell('direction').widget.frame:GetAlpha(), 0.7, 'a select too')
	-- every composite type
	states().disabled = 0.4
	ST.Changed()
	C.step(st)
	local parent = CreateFrame('Frame', nil, UIParent)
	local made = {}
	for _, kind in ipairs({ 'range', 'font', 'position', 'item', 'multiselect' }) do
		local w = W.Create(parent, kind)
		w:SetDisabled(true)
		made[kind] = w
		eq(w.frame:GetAlpha(), 0.4, kind .. ': dimmed')
	end
	states().disabled = 0.65
	ST.Changed()
	C.step(st)
	for kind, w in pairs(made) do eq(w.frame:GetAlpha(), 0.65, kind .. ': follows the slider with no redraw') end
	for kind, w in pairs(made) do
		w:SetDisabled(false)
		eq(w.frame:GetAlpha(), 1, kind .. ': enabled again: full')
	end
	for _, w in pairs(made) do w:Release() end
	close_all()
end)

test('L4: every caption of the strip fits its tile at 54 and at 58 wide', function()
	fresh()
	open_menu()
	local p = strip()
	local kind = W.PreviewKinds().states
	for _, width in ipairs({ 348, 370, 402 }) do
		kind.Layout(p, width)
		for i, caption in ipairs(p.captions) do
			local need = caption:GetUnboundedStringWidth()
			check(need <= p.tiles[i]:GetWidth(), ('%s needs %s of a %s tile at %d'):format(caption:GetText(), need, p.tiles[i]:GetWidth(), width))
		end
	end
	kind.Layout(p, 348)
	close_all()
end)

scaled_test('L6: the menu at the scales: its rows, the strip and the slot are laid out the same, the strip inside the menu', function()
	fresh()
	open_menu()
	eq(rows(), 'preview,mode,hover,pushed,selected,fade,disabled,step,shift,direction,chroma')
	local widget = menu_cell('preview').widget
	local frame = widget.frame
	for i, tile in ipairs(strip().tiles) do
		check(tile:GetLeft() >= frame:GetLeft() - 0.001 and tile:GetRight() <= frame:GetRight() + 0.001, 'tile ' .. i .. ' inside the strip')
	end
	check(M().frame:GetBottom() <= cell('accent').frame:GetBottom() + 1000, 'a menu')
	close_all()
end)

test('L1: the Accent dots rest brighter and say how many settings differ while any menu row differs', function()
	fresh()
	st.Config:Open('Fonts', 'theme')
	local dots = cell('accent').widget.dots
	check(not dots.lit, 'at the defaults: Muted')
	click(dots)
	menu_cell('hover').widget:Commit(0.3)
	menu_cell('pushed').widget:Commit(0.5)
	OW:CloseMenu()
	dots = cell('accent').widget.dots
	check(dots.lit, 'a menu row differs: lit')
	local r, g, b = dots.icon:GetVertexColor()
	local n = st:Color('text', 'normal')
	eq(T.rgb(r, g, b), T.rgb(n.r, n.g, n.b), 'at rest in Text > Normal, as the part rows')
	stub.fire_script(dots, 'OnEnter', true)
	eq(GameTooltip:GetOwner(), dots)
	stub.fire_script(dots, 'OnLeave', true)
	eq(select(2, st.OptionsWidgets.Kit.DotsTip(cell('accent').widget))[1], '2 settings here differ from their defaults.')
	click(dots)
	stub.click(reset_icon(menu_cell('hover')))
	stub.click(reset_icon(menu_cell('pushed')))
	OW:CloseMenu()
	check(not cell('accent').widget.dots.lit, 'back to Muted once none differs')
	close_all()
end)

test('L3: when neither above nor below the dots has room the menu is beside them, not over its own row', function()
	fresh()
	open_menu()
	local height = M().frame:GetHeight()
	OW:CloseMenu()
	check(height > 600, 'a tall menu')
	-- a 960-unit UI, the row mid-screen
	local function at(top, bottom) return table.concat({ OW.MenuPlace({ left = 800, right = 816, top = top, bottom = bottom }, 400, height, 1707, 960) }, ',') end
	eq(at(500, 476), 'TOPLEFT,TOPRIGHT,4,0', 'mid-screen: beside, to the right')
	eq(at(300, 276), 'TOPLEFT,TOPRIGHT,4,0', 'lower: beside')
	eq(at(940, 916), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'near the top there is room below: below')
	close_all()
end)

test('L5: searching "tones" or "states" finds the Accent row and opens the menu', function()
	fresh()
	local root = st.Config:GetOptionsTable()
	local function find(text)
		local out = {}
		for _, r in ipairs(OM.Search(root, text)) do
			if r.menu and r.pageKey == 'Fonts' then out[#out + 1] = r.name .. '@' .. r.path[#r.path] end
		end
		return table.concat(out, ',')
	end
	eq(find('tones'), 'Lightness step@accent', 'a menu section title is searched')
	eq(find('states'), 'States@accent', 'the strip is found by its own name only')
	for _, word in ipairs({ 'tones', 'states' }) do
		st.Config:Open('Fonts', 'general')
		OW.GetFrames().search:SetText(word)
		tick(0.3)
		local found
		for _, c in ipairs(OW.GetDrawnRows()) do
			if c.row.menu and c.row.path[#c.row.path] == 'accent' then found = c end
		end
		check(found, word .. ': a result on the Accent row')
		click(found.frame)
		check(OW:IsMenuShown(cell('accent').widget), word .. ': the menu opens')
		OW:CloseMenu()
	end
	close_all()
end)

test('L6: the note under the strip under Blizzard takes 18 units: the menu rows start under it', function()
	fresh()
	open_menu()
	local top = menu_cell('preview').widget.frame
	eq(top:GetHeight(), 64, 'Thick: the strip alone')
	OW:CloseMenu()
	T.theme('blizzard')
	open_menu()
	local w = menu_cell('preview').widget
	eq(w.frame:GetHeight(), 64 + 18, 'Blizzard: the note adds 18')
	check(w.note:GetBottom() >= w.frame:GetBottom() - 0.001, 'the note is inside its row')
	check(menu_cell('mode').frame:GetTop() <= w.frame:GetBottom() + 0.001, 'Derivation starts under the strip row')
	T.theme('thick')
	close_all()
end)

------------------------------------------------------------------ fix round 2

test('M1: a label that went dark once shows Text > Normal in the same pass: three changes in a row, its reset, a profile switch', function()
	fresh()
	st.config.profile.theme.accent = CreateColor(0.9, 0.78, 0.29)
	states().hover = 0.6
	ST.Changed()
	local b = W.Button(CreateFrame('Frame', nil, UIParent), 'Go', function() end)
	b:SetSize(80, 26)
	stub.fire_script(b, 'OnEnter', true)
	eq(T.rgb(b.text:GetTextColor()), '0.07,0.07,0.07', 'dark')
	stub.fire_script(b, 'OnLeave', true)
	local normal = st.config.profile.colors.text.normal
	for _, c in ipairs({ { 0.3, 0.9, 0.3 }, { 0.9, 0.3, 0.3 }, { 0.3, 0.3, 0.9 } }) do
		normal:SetRGB(c[1], c[2], c[3])
		st:ColorChanged('text', 'normal')
		eq(T.rgb(b.text:GetTextColor()), T.rgb(c[1], c[2], c[3]), 'after the pass: that color')
	end
	-- Text > Normal's own reset
	local default = st.defaults.colors.text.normal
	normal:SetRGB(default.r, default.g, default.b)
	st:ColorChanged('text', 'normal')
	eq(T.rgb(b.text:GetTextColor()), T.rgb(default.r, default.g, default.b), 'its reset')
	-- a profile switch (a whole pass of Text)
	normal:SetRGB(0.5, 0.6, 0.7)
	st:ColorsChanged('text')
	eq(T.rgb(b.text:GetTextColor()), '0.50,0.60,0.70', 'a whole pass of Text')
end)
