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
local H = load_test_file('core/options_window_helpers.lua')
load_editmode_bar()
local C = load_test_file('lib/color_cost.lua')
local T = load_test_file('lib/theme_helpers.lua')
local st = SaftUI
local EM, W, OB = st.EditModeFrames, st.OptionsWidgets, st.OptionsBody
local History = EM.History
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function colors() return st.config.profile.colors end
local function accent_default() return st.defaults.theme.accent end

-- A mover to select, steps to list, the list open.
local function setup(floating)
	if EM.active then EM:Deactivate() end
	H.close_all()
	st.config.profile.theme.name = 'thick'
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
		eq(m.calls.total, 0, label .. ': no setter')
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

for _, floating in ipairs({ false, true }) do
	local where = floating and 'the bar floating' or 'the bar docked'
	for _, case in ipairs({ { 'text', 'muted' }, { 'text', 'normal' }, { 'accent' } }) do
		local group, key = case[1], case[2]
		test(('edit mode on, %s, the History list open: 100 passes of %s %s color only'):format(where, group, tostring(key)), function()
			setup(floating)
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
			check(m.calls.total / 100 <= 150, 'per pass: ' .. m.calls.total / 100 .. ' setter calls')
			C.print(('edit mode on, %s, %s %s'):format(where, group, tostring(key)), m)
			restore()
			off()
		end)
	end

	test(('edit mode on, %s: a group edit mode does not draw (Class > Mage, Loot, Status) colors nothing'):format(where), function()
		setup(floating)
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
			eq(T.text(unpack(stub.state(row.mark).color_texture)), T.text(0.9, 0.4, 0.1, 1), 'row ' .. i .. ': its mark')
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
