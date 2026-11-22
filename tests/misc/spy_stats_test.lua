-- The Spy skin's Statistics window (SaftUI-Misc/Skinning/addons/spy_stats.lua):
--   - the window wears a SaftUI panel with a line under the title, Spy's art faded;
--   - the close button is the x icon with states;
--   - the Refresh button is a SaftUI box with hover and press, Blizzard's parts faded;
--   - the list's lines show the hover through the states;
--   - the sort headers are faded, the filter box is drawn;
--   - nothing is written onto a Spy frame (the fixture's frames are locked), a Spy with
--     no Statistics window (opts.noStats) or a renamed piece (opts.renamed) is skipped.
local SpyFix = load_test_file('misc/fixtures/spy_world.lua')
local T = load_test_file('lib/theme_helpers.lua')

local st, SK, SP

local function world(opts)
	opts = opts or {}
	st = T.client('forever')
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/spy.lua')
	load_saftui('SaftUI-Misc/Skinning/addons/spy_stats.lua')
	SK = st:GetModule('Skinning')
	SP = SK:GetModule('Spy')
end

-- Spy loaded first, then the skin set up.
local function skinned(opts)
	world()
	SpyFix.make(opts)
	SK:Enable()
	eq(#take_errors(), 0, 'no error while skinning')
end

local function panel_of(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.SetBackdrop and not SpyFix.is_spy(child) then return child end
	end
end

test('stats_panel_and_header', function()
	skinned()
	local frame = SpyStatsFrame
	check(panel_of(frame), 'the window wears a SaftUI panel')
	eq(SpyStatsFrame_Header:GetAlpha(), 0, 'the dialog header texture is faded')
	eq(frame.StatsFrame:GetAlpha(), 0, 'Spy\'s backdrop frame is faded')
	eq(SpyStatsTabFrameTabContentFrame.ContentFrame:GetAlpha(), 0, 'and the content\'s')
	eq(SpyStatsFilterBox.FilterBox:GetAlpha(), 0, 'and the filter box\'s')
	local lines = 0
	for _, region in ipairs({ panel_of(frame):GetRegions() }) do
		if region.GetObjectType and region:GetObjectType() == 'Texture' and region:GetNumPoints() == 2 then lines = lines + 1 end
	end
	check(lines >= 1, 'a line under the title')
	local face = st:FontValues(st.config.profile.headers.font)
	eq((SpyStatsFrame_Title:GetFont()), face, 'the title is in the title font')
	local text = st:FontValues(st.config.profile.skinning.font)
	eq((SpyStatsPlayersNameSort:GetFontString():GetFont()), text, 'a sort header is in the Skinning font')
	eq(SpyStatsFrame_Title:GetText(), 'Statistics', 'the title text is Spy\'s')
end)

test('stats_close_icon', function()
	skinned()
	local close = SpyStatsFrameTopCloseButton
	eq(close:GetNormalTexture():GetTexture(), st.icons.x, 'normal is the x')
	eq(close:GetPushedTexture():GetTexture(), st.icons.x, 'pushed is the x')
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	local r, g, b = close:GetNormalTexture():GetVertexColor()
	check(r == mr and g == mg and b == mb, 'tinted muted')
	check(st:GetState(close, 'hover') ~= nil, 'it has states')
	eq(close:GetHighlightTexture():GetTexture(), st.BLANK_TEX, 'the hover is SaftUI\'s flat highlight (the game shows it under the mouse)')
end)

test('stats_buttons_boxed_with_states', function()
	skinned()
	local button = SpyStatsRefreshButton
	local box = panel_of(button)
	check(box, 'a SaftUI box in the button')
	for _, key in ipairs({ 'Left', 'Middle', 'Right' }) do eq(button[key]:GetAlpha(), 0, key .. ' faded') end
	eq(button:GetHighlightTexture():GetTexture(), st.BLANK_TEX, 'the highlight is SaftUI\'s flat one')
	eq(st:DrawnKind(box), 'control', 'drawn as a control')
	check(st:GetState(box, 'hover') == false, 'hover is off at rest')
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	check(st:GetState(box, 'pushed'), 'pushed while held')
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	check(not st:GetState(box, 'pushed'), 'and released')
	stub.fire_script(button, 'OnMouseDown', 'RightButton')
	check(not st:GetState(box, 'pushed'), 'a right press does not push')
	st.config.profile.skinning.theme = 'thin'
	SK:UpdateConfig()
	eq(st:DrawnTheme(box), 'thin', 'a theme change redraws the box')
	eq(#take_errors(), 0, 'no error reported')
end)

test('stats_refresh_locked_highlight_shows_hover', function()
	skinned()
	local button = SpyStatsRefreshButton
	local piece = button:GetHighlightTexture()
	check(piece:GetAlpha() > 0, 'the highlight is not faded')
	local function look() return table.concat({ piece:GetVertexColor() }, ',') .. '|' .. piece:GetAlpha() end
	local rest = look()
	button:LockHighlight() -- Spy's blink: no OnEnter
	check(stub.state(button).highlight_locked, 'the game shows the locked highlight')
	st:SetState(button, 'hover', true)
	local r, g, b, a = piece:GetVertexColor()
	check(not (r == 1 and g == 1 and b == 1) and a > 0, 'which wears the states\' hover tint: ' .. look())
	eq(look(), rest, 'the same whatever the state: the game decides when it shows')
	button:UnlockHighlight()
end)

test('stats_check_buttons_drawn_without_fields', function()
	skinned()
	for _, key in ipairs({ 'Kos', 'Realm', 'WinsLoses', 'Reason' }) do
		local cb = _G['SpyStats' .. key .. 'Checkbox']
		local box = panel_of(cb)
		check(box, key .. ': a SaftUI box')
		eq(st:DrawnKind(box), 'control', key .. ': a control')
		eq(cb:GetCheckedTexture():GetTexture(), st.BLANK_TEX, key .. ': a flat checked texture')
		check(st:GetState(cb, 'selected') == false, key .. ': unchecked at rest')
		cb:SetChecked(true)
		check(st:GetState(cb, 'selected'), key .. ': checking it selects')
		cb:SetChecked(false)
		check(not st:GetState(cb, 'selected'), key .. ': and unchecking')
		st:SetState(cb, 'hover', true)
		check(st:GetState(cb, 'hover'), key .. ': hover')
	end
	eq(#take_errors(), 0, 'no error reported')
end)

test('stats_fonts_refresh_check_filter', function()
	skinned()
	local face = (st:FontValues(st.config.profile.skinning.font))
	eq((SpyStatsRefreshButton:GetFontString():GetFont()), face, 'the Refresh label')
	eq((SpyStatsKosCheckboxText:GetFont()), face, 'a check label')
	eq((SpyStatsFilterBox:GetFont()), face, 'the filter box')
	eq(select(2, SpyStatsFilterBox:GetFont()), 12, 'at Spy\'s size')
end)

test('stats_lines_hover_states', function()
	skinned()
	for i = 1, 34 do
		local line = _G['SpyStatsPlayerHistoryFrameListFrameLine' .. i]
		eq(line:GetHighlightTexture():GetTexture(), st.BLANK_TEX, 'line ' .. i .. ' has the flat highlight')
		check(st:GetState(line, 'hover') == false, 'line ' .. i .. ' has states')
	end
	local line = SpyStatsPlayerHistoryFrameListFrameLine3
	local piece = line:GetHighlightTexture()
	local function look() return table.concat({ piece:GetVertexColor() }, ',') .. '|' .. piece:GetAlpha() end
	local rest = look()
	st:SetState(line, 'hover', true)
	check(st:GetState(line, 'hover'), 'the states take a hover')
	local r, g, b, a = piece:GetVertexColor()
	check(not (r == 1 and g == 1 and b == 1) and a > 0 and a < 1, 'the hover piece wears the Accent\'s hover tint: ' .. look())
	st:SetState(line, 'hover', false)
	eq(look(), rest, 'the piece is pre-colored: the game shows it under the mouse')
	eq((SpyStatsPlayerHistoryFrameListFrameLine3Name:GetFont()), (st:FontValues(st.config.profile.skinning.font)),
		'the line\'s texts are in the Skinning font')
end)

test('stats_filter_box_is_drawn_without_fields', function()
	skinned()
	local box = SpyStatsFilterBox
	local backdrop = panel_of(box)
	check(backdrop, 'a SaftUI backdrop on the filter box')
	eq(st:DrawnKind(backdrop), 'control', 'a control')
	stub.fire_script(box, 'OnEditFocusGained')
	check(st:GetState(backdrop, 'focus'), 'a border in the Accent while it has focus')
	stub.fire_script(box, 'OnEditFocusLost')
	check(not st:GetState(backdrop, 'focus'), 'and not after')
end)

test('stats_missing_children_ok', function()
	skinned({ noStats = true })
	check(SpyStatsFrame == nil, 'no stats window')
	skinned({ renamed = true })
	check(panel_of(SpyStatsFrame), 'the window is still drawn without its tabs')
	check(panel_of(SpyStatsFrame.StatsFrame) == nil, 'and nothing else invented')
end)

test('stats_writes_no_fields_and_survives_updates', function()
	skinned()
	SK:UpdateConfig()
	st:ColorsChanged('text')
	eq(#take_errors(), 0, 'no error reported')
end)
