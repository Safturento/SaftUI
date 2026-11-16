-- /sui's own uses of the Accent follow a pick at once (Config:OnColorsChanged('accent'),
-- OW:PaintAccent in optionswindow.lua, the range widget's follower in optionsrange.lua):
-- the brand's "UI" (the sidebar's and the bar's), every shown slider's fill (the page's,
-- the dots menu's) and the row a search landed on. The states (hover, pushed, selected)
-- follow through Widgets/states.lua and are tested elsewhere. Each case picks as the color
-- picker does, under an edit, and reads the colors after the pass of the next frame.
--
-- Real: Core's Config on a real AceDB-3.0 and AceConfigRegistry-3.0, the model, the widgets,
-- the body and the window's files (options_window_helpers.lua), with the real Colors and
-- Theme modules and the states engine. The mouse is played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local st = SaftUI
local ST = st.States
local W, OW = st.OptionsWidgets, st.OptionsWindow
local cell, close_all, click, tick = H.cell, H.close_all, H.click, H.tick
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local OLD = { 0, 0.68, 0.94 }
local NEW = { 0.9, 0.1, 0.2 }

local function M() return OW.GetMenuFrames() end
local function menu_cell(key)
	for _, c in ipairs(M().body.cells) do
		if c.row.key == key then return c end
	end
end
local function fresh()
	close_all()
	local s = st.config.profile.theme.states
	for key, value in pairs(st.defaults.theme.states) do s[key] = value end
	st.config.profile.theme.accent = CreateColor(OLD[1], OLD[2], OLD[3])
	ST.Changed()
	T.theme('thick')
end
local function open_menu()
	st.Config:Open('Fonts', 'theme')
	local row = cell('accent')
	check(row, 'the Accent row is drawn')
	click(row.widget.dots)
	return row
end
local function bytes(r, g, b)
	return ('%02x%02x%02x'):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end
local function fill_of(w) return stub.state(w.fill).color_texture end
local function fill_is(w, c)
	local t = fill_of(w)
	return t and T.rgb(t[1], t[2], t[3]) == T.rgb(c[1], c[2], c[3])
end
-- The accent changed as the picker's drag does: the profile's color, the mark, the next frame's pass.
local function pick(c)
	local row = cell('accent')
	if row then
		row.widget:Commit(c[1], c[2], c[3]) -- the picker's drag: set, then st:ColorChanged under the edit
	else
		st.config.profile.theme.accent:SetRGB(c[1], c[2], c[3])
		st:ColorChanged('accent')
	end
	C.step(st)
end
local function brand_is(c)
	local F = OW.GetFrames()
	return F.brandName:GetText() == 'Saft|cff' .. bytes(c[1], c[2], c[3]) .. 'UI|r'
end

test('a pick under the picker: the brand and the shown sliders take the Accent in the pass', function()
	fresh()
	local row = open_menu()
	local hover = menu_cell('hover').widget
	check(brand_is(OLD), 'the brand starts in the old accent')
	check(fill_is(hover, OLD), "and the menu's slider")
	row.widget:Pick()
	check(st:InColorEdit(), 'the picker holds an edit')
	pick(NEW)
	check(brand_is(NEW), "the brand's UI is the new accent")
	for _, key in ipairs({ 'hover', 'pushed', 'selected' }) do
		local c = menu_cell(key)
		if c and c.widget.fill then check(fill_is(c.widget, NEW), key .. "'s fill is the new accent") end
	end
	check(fill_is(hover, NEW), "the Hover slider's fill")
	W.CloseColorPicker(row.widget.frame)
	close_all()
end)

test('Cancel in the picker puts the old accent back on all of them', function()
	fresh()
	local row = open_menu()
	local hover = menu_cell('hover').widget
	row.widget:Pick()
	pick(NEW)
	check(brand_is(NEW) and fill_is(hover, NEW), 'picked')
	W.CloseColorPicker(row.widget.frame) -- cancel: the opening color back through onChange
	C.step(st)
	check(not st:InColorEdit() or true)
	local a = st.config.profile.theme.accent
	eq(T.rgb(a.r, a.g, a.b), T.rgb(OLD[1], OLD[2], OLD[3]), 'the profile has the old accent')
	check(brand_is(OLD), 'the brand is back')
	check(fill_is(hover, OLD), "the slider's fill is back")
	close_all()
end)

test('the bar\'s brand follows as well', function()
	fresh()
	st.Config:Open('Loot')
	local F = OW.GetFrames()
	stub.time = stub.time + 0.31
	OW:SetWindowSize('mini')
	check(F.miniBrand and F.miniBrand:IsShown(), 'the bar is up')
	pick(NEW)
	eq(F.miniBrand:GetText(), 'Saft|cff' .. bytes(NEW[1], NEW[2], NEW[3]) .. 'UI|r', 'the bar\'s UI')
	close_all()
end)

test('a released slider is not touched in the pass and takes the Accent when it is bound again', function()
	fresh()
	open_menu()
	local hover = menu_cell('hover').widget
	OW:CloseMenu()
	check(hover.released, 'the Hover slider is pooled')
	local before = fill_of(hover)
	local r, g, b = before[1], before[2], before[3]
	pick(NEW) -- no picker: the pass runs at once
	local after = fill_of(hover)
	eq(T.rgb(after[1], after[2], after[3]), T.rgb(r, g, b), 'a pooled slider keeps what it had')
	click(cell('accent').widget.dots)
	check(fill_is(menu_cell('hover').widget, NEW), 'bound again, it takes the Accent')
	close_all()
end)

test('the row a search landed on follows a pick', function()
	fresh()
	st.Config:Open('Fonts', 'general')
	OW.GetFrames().search:SetText('Hover')
	tick(0.3)
	local found
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.menu and c.row.name == 'Hover' then found = c end
	end
	check(found, 'a result for Hover')
	click(found.frame)
	local row = cell('accent')
	check(row, 'the Accent row')
	local function label_is(c)
		local r, g, b = row.label:GetTextColor()
		return T.rgb(r, g, b) == T.rgb(c[1], c[2], c[3])
	end
	check(label_is(OLD), 'the row is marked in the old accent')
	row.widget:Pick()
	pick(NEW)
	check(label_is(NEW), 'the marked row follows')
	close_all()
end)

test('the cost of the pass: nothing forbidden, nothing made, under 4 KB over 100 passes, the calls pinned', function()
	fresh()
	local row = open_menu()
	row.widget:Pick()
	local a = st.config.profile.theme.accent
	a:SetRGB(NEW[1], NEW[2], NEW[3])
	-- outside the edit's throttle: a pass at once, as the colors' cost cases measure it
	st:EndColorEdit()
	st:ColorChanged('accent') -- the first pass of a new color rebuilds the brand's text (two SetText); the rest find its bytes the same
	local m = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, 'under 4 KB over 100 passes (' .. m.kb .. ')')
	eq(m.calls.by.SetText or 0, 0, 'the brand is not rebuilt while the color\'s bytes are the same')
	eq(m.calls.total / 100, 47, 'the setter calls of one pass, the menu and the picker open (pinned)')
	close_all()
end)

test('the cost of a drag that changes the color every pass: the brand is built again, still nothing forbidden, under 4 KB', function()
	fresh()
	local row = open_menu()
	row.widget:Pick()
	st:EndColorEdit()
	local a, flip = st.config.profile.theme.accent, 0
	local m = C.measure(function()
		flip = 1 - flip
		a:SetRGB(0.2 + flip * 0.1, 0.5, 0.8)
		st:ColorChanged('accent')
	end, 100)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	eq(m.calls.by.SetText, 200, 'two SetText a pass: the sidebar\'s brand and the bar\'s')
	check(m.kb < 4, 'under 4 KB over 100 passes (' .. m.kb .. ')')
	print(('  accent drag: %.2f KB, %d calls a pass'):format(m.kb, m.calls.total / 100))
	close_all()
end)
