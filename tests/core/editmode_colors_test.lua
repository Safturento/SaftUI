-- Edit mode follows a color change by color alone (live colors, Task 2):
-- with edit mode off a pass costs nothing; with it on, the bar (docked or
-- floating), its Show filter, its status line, the docked bar's strip, the
-- History list, the Coordinates label, the grid's centre lines and a selected
-- mover repaint only the groups they draw, and only their colors: nothing
-- forbidden, nothing placed (no ClearAllPoints, SetPoint, Hide or SetScript),
-- no list refresh, nothing made, under 4 KB over 100 passes.
--
-- Real: the /sui window's world (core/options_window_helpers.lua), edit
-- mode's files and the bar's (load_editmode_bar), every module's real
-- OnColorsChanged (nothing is reduced to a stand-in), the cost helper.
local C = load_test_file('lib/color_cost.lua')
local T = load_test_file('lib/theme_helpers.lua')
local H, st, EM, W, OB, History

-- A fresh world: the /sui window's, edit mode's files and the bar's. Every case
-- builds its own (a stub never collects the widgets a case made).
local function build()
	reset_world()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, W, OB = st.EditModeFrames, st.OptionsWidgets, st.OptionsBody
	History = EM.History
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end
build()

local function colors() return st.config.profile.colors end
local function accent_default() return st.defaults.theme.accent end

-- A mover to select, steps to list, the list open.
local function setup(floating, theme)
	build()
	st.config.profile.theme.name = theme or 'thick'
	st:ThemeChanged()
	if not EM.movers.livecolors then
		local frame = CreateFrame('Frame', nil, UIParent)
		frame:SetSize(100, 50)
		frame:SetPoint('CENTER')
		local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
		st:RegisterConfigMover(frame, { key = 'livecolors', config = function() return config end, apply = function() end })
	end
	EM:GetSettings().coordinates = true
	EM:GetSettings().grid = true
	EM:Activate()
	EM:SetBarFloating(floating and true or false)
	History:Clear()
	History:Push({ kind = 'bulk', label = 'Copied A to B', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 5, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	History:Push({ kind = 'bulk', label = 'Copied B to C', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 7, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	History:Undo()
	EM:Select(EM.movers.livecolors)
	EM:ShowHistoryList()
	EM:SetBarStatus('Moved it', nil, false)
	-- Every widget colored once: a cold stub widget makes its table at its first color call.
	for _, g in ipairs({ { 'text', 'muted' }, { 'text', 'normal' }, { 'button', 'hover' }, { 'accent' } }) do st:ColorChanged(g[1], g[2]) end
	st:ColorChanged('theme')
end

local function off()
	if EM.active then EM:Deactivate() end
	H.close_all()
end

local function by(counts)
	local out = {}
	for k, v in pairs(counts) do out[#out + 1] = k .. '=' .. v end
	table.sort(out)
	return table.concat(out, ',')
end

-- One pass of a color, 100 times, its color moved each run.
local function cost(group, key)
	local flip = 0
	local function pass()
		flip = 1 - flip
		if group == 'accent' then
			st.config.profile.theme.accent:SetRGB(0.2 + flip * 0.1, 0.5, 0.8)
		elseif group == 'text' or group == 'button' then
			colors()[group][key]:SetRGB(0.4 + flip * 0.1, 0.5, 0.6)
		end
		st:ColorChanged(group, key)
	end
	return C.measure(pass, 100)
end

local function restore()
	local d = accent_default()
	st.config.profile.theme.accent:SetRGB(d.r, d.g, d.b)
	for _, key in ipairs({ 'muted', 'normal', 'danger' }) do
		local c = st.defaults.colors.text[key]
		colors().text[key]:SetRGB(c.r, c.g, c.b)
	end
	for _, key in ipairs({ 'normal', 'hover', 'pushed' }) do
		local c = st.defaults.colors.button[key]
		colors().button[key]:SetRGB(c.r, c.g, c.b)
	end
end

------------------------------------------------------------------ edit mode off

test('edit mode off: a pass of any group costs nothing (no call, no Hide, no SetScript, no garbage)', function()
	setup(false)
	off()
	for _, case in ipairs({ { 'text', 'muted' }, { 'button', 'hover' }, { 'accent' }, { 'class', 'MAGE' }, { 'text', 'danger' } }) do
		local m = cost(case[1], case[2])
		local label = case[1] .. ' ' .. tostring(case[2])
		if case[1] == 'accent' then
			-- The bar's kit controls are state frames (Widgets/states.lua): a selected one is colored by every
			-- pass of the Accent and a disabled one's alpha is set, hidden or not: one set of setters each, no more.
			local setters = 0
			for name, n in pairs(m.calls.by or {}) do
				if name == 'SetAlpha' or name == 'SetBackdropBorderColor' or name == 'SetTexCoord' or name == 'SetVertexColor' then setters = setters + n end
			end
			eq(setters, m.calls.total, label .. ': only the states helper\'s setters: ' .. by(m.calls.by or {}))
			eq(m.calls.total, 20 * 100, label .. ': exactly the measured 20 setters a pass (the bar\'s 4 selected and 4 disabled controls)')
		else
			eq(m.calls.total, 0, label .. ': no setter')
		end
		eq(m.forbidden.total, 0, label .. ': nothing forbidden: ' .. by(m.forbidden.by))
		eq(m.made, 0, label .. ': nothing made')
		check(m.kb < 4, label .. ': garbage ' .. m.kb .. ' KB')
	end
	restore()
end)

test('edit mode off, then on: what a pass skipped is drawn when it comes on', function()
	setup(false)
	off()
	st.config.profile.theme.accent:SetRGB(0.9, 0.4, 0.1)
	st:ColorChanged('accent')
	EM:Activate()
	local strip = EM.barStrip
	eq(T.text(unpack(stub.state(strip.line).color_texture)), T.text(0.9, 0.4, 0.1, 1), "the docked bar's strip is the Accent now")
	EM:Select(EM.movers.livecolors)
	local overlay = EM.movers.livecolors.overlay
	eq(T.edge(overlay.backdrop), T.text(0.9, 0.4, 0.1, 1), "the selected mover's border")
	off()
	restore()
end)

------------------------------------------------------------------ edit mode on

for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
for _, floating in ipairs({ false, true }) do
	local where = (floating and 'the bar floating' or 'the bar docked') .. ', ' .. theme
	for _, case in ipairs({ { 'text', 'muted' }, { 'text', 'normal' }, { 'accent' } }) do
		local group, key = case[1], case[2]
		test(('edit mode on, %s, the History list open: 100 passes of %s %s color only'):format(where, group, tostring(key)), function()
			setup(floating, theme)
			local refreshed, laid, placed = 0, 0, 0
			local realRefresh, realLay, realPlace, realList = EM.RefreshHistoryList, EM.LayoutBar, EM.PlaceBar, EM.RefreshBar
			EM.RefreshHistoryList = function(...) refreshed = refreshed + 1; return realRefresh(...) end
			EM.LayoutBar = function(...) laid = laid + 1; return realLay(...) end
			EM.PlaceBar = function(...) placed = placed + 1; return realPlace(...) end
			local m = cost(group, key)
			EM.RefreshHistoryList, EM.LayoutBar, EM.PlaceBar = realRefresh, realLay, realPlace
			eq(m.forbidden.total, 0, 'nothing forbidden: ' .. by(m.forbidden.by))
			eq(m.made, 0, 'nothing made')
			check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
			eq(refreshed + laid + placed, 0, 'no list refresh, no layout, no placing')
			check(m.calls.total > 0, 'it does color: ' .. m.calls.total)
			-- (the 150 was set before SetAlpha and SetTexCoord counted as setters, which the states'
			-- passes may call: the bound is still on the colors it pinned)
			local colored = m.calls.total - (m.calls.by.SetAlpha or 0) - (m.calls.by.SetTexCoord or 0)
			check(colored / 100 <= 150, 'per pass: ' .. colored / 100 .. ' setter calls')
			C.print(('edit mode on, %s, %s %s'):format(where, group, tostring(key)), m)
			restore()
			off()
		end)
	end

	test(('edit mode on, %s: a group edit mode does not draw (Class > Mage, Loot, Status) colors nothing'):format(where), function()
		setup(floating, theme)
		for _, case in ipairs({ { 'class', 'MAGE' }, { 'loot', 'rare' }, { 'status', 'tapped' }, { 'roles', 'TANK' }, { 'text', 'danger' }, { 'button', 'hover' } }) do
			local ok = pcall(function()
				local m = C.measure(function() st:ColorChanged(case[1], case[2]) end, 100)
				eq(m.calls.total, 0, case[1] .. ': no setter')
				eq(m.forbidden.total, 0, case[1] .. ': nothing forbidden')
				check(m.kb < 4, case[1] .. ': garbage ' .. m.kb)
			end)
			check(ok, case[1] .. ' ' .. tostring(case[2]) .. ': a real color')
		end
		off()
	end)
end
end

------------------------------------------------------------------ what follows

test('Accent: the strip, a selected mover, the grid, the Coordinates label and the bar follow; the list marks and hover too', function()
	setup(false)
	EM.coordinates:Show() -- (the stub's outline has no rect to place it by: it is shown by hand)
	st.config.profile.theme.accent:SetRGB(0.9, 0.4, 0.1)
	st:ColorChanged('accent')
	local want = T.text(0.9, 0.4, 0.1, 1)
	eq(T.text(unpack(stub.state(EM.barStrip.line).color_texture)), want, "the docked bar's strip")
	eq(T.edge(EM.movers.livecolors.overlay.backdrop), want, 'the selected mover')
	eq(T.text(EM.coordinates.text:GetTextColor()), T.text(0.9, 0.4, 0.1, 1), 'the Coordinates label')
	local list = EM.historyList
	for i, row in ipairs(list.rows) do
		if row:IsShown() then
			local bar = st:StateLook(row).bar
			if st:GetState(row, 'selected') then
				eq(T.text(bar.r, bar.g, bar.b, 1), T.text(0.9, 0.4, 0.1, 1), 'row ' .. i .. ': its bar')
			end
		end
	end
	restore()
	st:ColorChanged('accent')
	off()
end)

test('Text: the History list, the status line and the bar follow Muted and Normal; an undone row stays Muted', function()
	setup(false)
	colors().text.muted:SetRGB(0.2, 0.7, 0.3)
	colors().text.normal:SetRGB(0.8, 0.8, 0.2)
	st:ColorChanged('text', 'muted')
	st:ColorChanged('text', 'normal')
	local list = EM.historyList
	eq(T.text(list.title:GetTextColor()), T.text(0.2, 0.7, 0.3, 1), "the list's title: Muted")
	eq(T.text(EM.statusText:GetTextColor()), T.text(0.2, 0.7, 0.3, 1), 'the status line: Muted')
	local seen = 0
	for _, row in ipairs(list.rows) do
		if row:IsShown() and row.index then
			seen = seen + 1
			local undone = row.index > History:Position()
			eq(T.text(row.label:GetTextColor()), undone and T.text(0.2, 0.7, 0.3, 1) or T.text(0.8, 0.8, 0.2, 1),
				'row ' .. row.index .. (undone and ' (undone): Muted' or ': Normal'))
			eq(T.text(row.detail:GetTextColor()), T.text(0.2, 0.7, 0.3, 1), 'row ' .. row.index .. ' detail: Muted')
		end
	end
	check(seen >= 3, 'the rows were read: ' .. seen)
	restore()
	st:ColorChanged('text')
	off()
end)

test('a Theme pass looks again as before: the whole bar, the list and the movers', function()
	setup(false)
	local looked = 0
	local real = EM.RefreshBar
	EM.RefreshBar = function(...) looked = looked + 1; return real(...) end
	st:ColorChanged('theme')
	EM.RefreshBar = real
	eq(looked, 1, 'the bar looks again once')
	off()
end)

test('the bar looks again only for the groups it draws: Theme looks, Text (Normal, Muted) and the Accent recolor, no other group touches it', function()
	setup(false)
	local looks, recolors = 0, 0
	local realRefresh, realRecolor = EM.RefreshBar, EM.RecolorBar
	EM.RefreshBar = function(...) looks = looks + 1; return realRefresh(...) end
	EM.RecolorBar = function(...) recolors = recolors + 1; return realRecolor(...) end
	local function count(group, key)
		looks, recolors = 0, 0
		st:ColorChanged(group, key)
		return looks .. '/' .. recolors
	end
	eq(count('class', 'MAGE'), '0/0', 'Class > Mage: not touched')
	eq(count('accent'), '0/1', 'the Accent: recolored once')
	eq(count('text', 'muted'), '0/1', 'Text > Muted: once')
	eq(count('text', 'normal'), '0/1', 'Text > Normal: once')
	eq(count('text', 'danger'), '0/0', 'Text > Danger: not drawn by the bar')
	eq(count('button', 'hover'), '0/0', 'Buttons: the bar draws none')
	eq(count('theme'), '1/0', 'Theme: looks again')
	st:ColorsChanged('text')
	eq(looks .. '/' .. recolors, '1/1', 'a whole pass of Text recolors once')
	EM.RefreshBar, EM.RecolorBar = realRefresh, realRecolor
	off()
end)

------------------------------------------------------------------ what each part shows after a pass

local function muted_set(r, g, b) colors().text.muted:SetRGB(r, g, b) end
local function rgb3(...) return T.text(...) end

test('the Show filter hint, the number boxes\' arrows and the status line take Muted (docked)', function()
	setup(false)
	muted_set(0.2, 0.7, 0.3)
	st:ColorChanged('text', 'muted')
	local want = rgb3(0.2, 0.7, 0.3, 1)
	eq(rgb3(EM:BarControl('filter').frame.hint:GetTextColor()), want, "the filter's hint")
	eq(rgb3(EM:BarControl('gridSize').frame.pair.up.arrow:GetVertexColor()), want, "the Grid size's up arrow")
	eq(rgb3(EM:BarControl('gridSize').frame.pair.down.arrow:GetVertexColor()), want, "the Grid size's down arrow")
	eq(rgb3(EM.historyList.box.pair.up.arrow:GetVertexColor()), want, "the list box's up arrow")
	eq(rgb3(EM.statusText:GetTextColor()), want, 'the status line')
	off()
end)

test("the floating window's heading, captions and dock follow Text; the arrows rest Muted", function()
	setup(true)
	colors().text.normal:SetRGB(0.8, 0.8, 0.2)
	muted_set(0.2, 0.7, 0.3)
	st:ColorChanged('text', 'normal')
	st:ColorChanged('text', 'muted')
	local window = EM.barWindow
	eq(rgb3(window.heading:GetTextColor()), rgb3(0.8, 0.8, 0.2, 1), 'the heading: Normal')
	local seen = 0
	for _, caption in pairs(window.captions) do
		seen = seen + 1
		eq(rgb3(caption:GetTextColor()), rgb3(0.2, 0.7, 0.3, 1), 'a caption: Muted')
	end
	check(seen > 0, 'there are captions')
	eq(rgb3(window.dock.icon:GetVertexColor()), rgb3(0.2, 0.7, 0.3, 1), 'the dock icon: Muted')
	off()
end)

test("a hidden History row's label takes the color too (it is drawn by its index when it shows again)", function()
	setup(false)
	for i = 1, 8 do
		History:Push({ kind = 'bulk', label = 'Step ' .. i, changes = {
			{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = i, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	end
	EM:RefreshHistoryList()
	History:Clear()
	History:Push({ kind = 'bulk', label = 'Only', changes = {
		{ kind = 'position', where = 'player', old = { point = 'CENTER', x_off = 1, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	EM:RefreshHistoryList()
	colors().text.normal:SetRGB(0.8, 0.8, 0.2)
	muted_set(0.2, 0.7, 0.3)
	st:ColorChanged('text', 'normal')
	st:ColorChanged('text', 'muted')
	local hidden = 0
	for _, row in ipairs(EM.historyList.rows) do
		if not row:IsShown() and row.index then
			hidden = hidden + 1
			local undone = row.index > History:Position()
			eq(rgb3(row.label:GetTextColor()), undone and rgb3(0.2, 0.7, 0.3, 1) or rgb3(0.8, 0.8, 0.2, 1), 'hidden row ' .. row.index)
		end
	end
	check(hidden > 0, 'a hidden row had an index: ' .. hidden)
	off()
end)

test('what a pass skipped while edit mode was off: the status line and the number boxes\' arrows take the current Muted as it comes on', function()
	setup(false)
	off()
	muted_set(0.2, 0.7, 0.3)
	st:ColorChanged('text', 'muted')
	EM:Activate()
	local want = rgb3(0.2, 0.7, 0.3, 1)
	eq(rgb3(EM.statusText:GetTextColor()), want, 'the status line (Enabled)')
	eq(rgb3(EM:BarControl('gridSize').frame.pair.up.arrow:GetVertexColor()), want, "the bar's Grid size arrows")
	EM:ShowHistoryList()
	eq(rgb3(EM.historyList.box.pair.down.arrow:GetVertexColor()), want, "the History list box's arrows, as it opens")
	off()
end)

test("a click on a number box's arrow keeps the arrow's hover color while the mouse is on it (the Grid size box, and the History list's)", function()
	setup(false)
	-- the arrow is a glyph: the lighter tone of the accent under the mouse (the states helper's)
	local tr, tg, tb = st:StateColor('edgeHover')
	local normal = rgb3(tr, tg, tb) .. ',1.00'
	local box = EM:BarControl('gridSize').frame
	local arrow = box.pair.up
	stub.fire_script(arrow, 'OnEnter', true)
	eq(rgb3(arrow.arrow:GetVertexColor()), normal, 'hovered: Normal')
	stub.fire_script(arrow, 'OnClick', 'LeftButton')
	eq(rgb3(arrow.arrow:GetVertexColor()), normal, "after a click (the setting changed, the bar looked again): still Normal")
	stub.fire_script(arrow, 'OnLeave', true)
	-- The History list's box.
	local down = EM.historyList.box.pair.down
	stub.fire_script(down, 'OnEnter', true)
	stub.fire_script(down, 'OnClick', 'LeftButton')
	EM:RefreshHistoryList()
	eq(rgb3(down.arrow:GetVertexColor()), normal, "the History list's box: still Normal after its click and refresh")
	off()
end)
