-- The window's layout math (SaftUI-Tracker/layout.lua), pure: the window's
-- height from its contents, the scroll view's, the scroll child's width, the
-- scroll range and the wheel. No frame is made; the layout constants are the
-- spec's exact values (design: "Layout (exact values)").
--
-- Real: SaftUI-Tracker's files over the tracker world.
local TW = load_test_file('tracker/tracker_world.lua')

local function layout()
	local _, TR = TW.world({})
	return TR.Layout, TR.LAYOUT
end

test('the layout constants are the design values', function()
	local _, L = layout()
	local want = {
		PAD = 8, HEADER = 24, HEADER_GAP = 6, COUNT_GAP = 6, CHEVRON = 16, LINE_ALPHA = 0.5,
		ZONE = 20, ZONE_ABOVE = 10, ZONE_BELOW = 4, ZONE_TITLE_GAP = 2, ICON = 14, ICON_GAP = 4,
		INDENT = 12, LINE_GAP = 2, BAR = 12, BAR_GAP = 3, POPUP = 22, POPUP_BAR = 2,
		FOCUS_BAR = 2, FOCUS_GAP = 4, HOVER_PAD = 2, WHEEL = 40, BAR_LINGER = 0.3,
		ITEM_GAP = 4, COLUMN_GAP = 4, COLUMN_STACK = 2, BESIDE_GAP = 12, BLIZZARD_OFF = 100,
	}
	for key, value in pairs(want) do eq(L[key], value, key) end
	for key in pairs(L) do check(want[key] ~= nil, key .. ' is a constant the plan names') end
end)

test('WindowHeight: padding, the header and its gap while it shows, the content, padding, at most Max height', function()
	local Layout = layout()
	eq(Layout.WindowHeight(100, { header = true, max = 560 }), 146, 'header: 8 + 24 + 6 + 100 + 8')
	eq(Layout.WindowHeight(2000, { header = true, max = 560 }), 560, 'capped at Max height')
	eq(Layout.WindowHeight(100, { header = false, max = 560 }), 116, 'no header: 8 + 100 + 8')
	eq(Layout.WindowHeight(100, { header = true, collapsed = true, max = 560 }), 40, 'collapsed: 8, the header, 8')
	eq(Layout.WindowHeight(0, { header = true, max = 560 }), 46, 'empty')
	eq(Layout.WindowHeight(2000, { header = true, collapsed = true, max = 333 }), 40, 'collapsed whatever the content')
	eq(Layout.WindowHeight(100, { header = false, collapsed = true, max = 560 }), 116, 'no header, no whole-tracker collapse: the saved state is ignored')
	eq(Layout.WindowHeight(300, { header = true, max = 333 }), 333, 'just past the cap')
	eq(Layout.WindowHeight(285, { header = true, max = 333 }), 331, 'just under it')
end)

test('ViewHeight, ChildWidth, ScrollRange and Wheel', function()
	local Layout = layout()
	eq(Layout.ViewHeight(333, true), 287, 'the window less padding twice, the header and its gap')
	eq(Layout.ViewHeight(333, false), 317, 'no header')
	eq(Layout.ViewHeight(46, true), 0, 'an empty window has no view')
	eq(Layout.ViewHeight(40, true), 0, 'nor a collapsed one')
	eq(Layout.ViewHeight(10, true), 0, 'never negative')
	eq(Layout.ChildWidth(260, 14), 230, 'the width less padding twice and the bar room')
	eq(Layout.ChildWidth(260, 0), 244, 'no bar')
	eq(Layout.ScrollRange(2000, 287), 1713, 'content past the view')
	eq(Layout.ScrollRange(100, 287), 0, 'content that fits')
	eq(Layout.Wheel(0, -1, 300), 40, 'a notch down is 40')
	eq(Layout.Wheel(290, -1, 300), 300, 'clamped to the range')
	eq(Layout.Wheel(10, 1, 300), 0, 'a notch up, clamped at the top')
	eq(Layout.Wheel(100, 2, 300), 20, 'two notches up')
	eq(Layout.Wheel(0, -1, 0), 0, 'nothing to scroll')
	eq(Layout.Wheel(500, -1, 300), 300, 'an offset past the range comes back in')
end)

------------------------------------------------------------------ the rows

-- Every text is 12 tall, wherever it is, unless a case says: the measure the
-- layout asks, which the tracker answers from the real font strings.
local function measure_12() return 12 end

local function rows(entries, metrics, measure)
	local Layout = layout()
	return Layout.Rows(entries, metrics or { width = 244, spacing = 8, icons = false, itemSize = 24 }, measure or measure_12)
end

local function ys(placed)
	local parts = {}
	for i, p in ipairs(placed) do parts[i] = p.y .. ' ' .. p.height end
	return table.concat(parts, ', ')
end

test('Rows: zone, quest with two objectives, zone, quest; the zone takes 10 above, the quest 4 below it', function()
	local placed, height = rows({
		{ kind = 'zone' },
		{ kind = 'quest', first = 'a1', lines = { { text = 'x' }, { text = 'y' } } },
		{ kind = 'zone' },
		{ kind = 'quest', first = 'b1', lines = {} },
	})
	eq(ys(placed), '0 20, 24 40, 74 20, 98 12', 'y and height of each')
	eq(height, 110, 'the height is the end of the last row')
	eq(#placed, 4, 'one placed entry each')
	eq(placed[2].lines[1].y .. ' ' .. placed[2].lines[1].height, '14 12', 'the first objective 2 under the title')
	eq(placed[2].lines[2].y .. ' ' .. placed[2].lines[2].height, '28 12', 'the second 2 under the first')
	eq(placed[4].titleHeight, 12, 'the title height is kept')
end)

test('Rows: two quests in a zone are spacing apart; Spacing is the profile value', function()
	local entries = {
		{ kind = 'zone' },
		{ kind = 'quest', first = 'a1', lines = { { text = 'x' }, { text = 'y' } } },
		{ kind = 'quest', first = 'a2', lines = {} },
	}
	eq(ys(rows(entries)), '0 20, 24 40, 72 12', 'the second at 72')
	eq(ys(rows(entries, { width = 244, spacing = 0, icons = false, itemSize = 24 })), '0 20, 24 40, 64 12', 'Spacing 0')
	eq(ys(rows(entries, { width = 244, spacing = 20, icons = false, itemSize = 24 })), '0 20, 24 40, 84 12', 'Spacing 20')
end)

test('Rows: a bar after a title is 12 + 3 + 12 + 3 tall; a line after a bar has no gap of its own; a bar after a line has 3, not 2', function()
	local placed = rows({ { kind = 'quest', first = 'a', lines = { { kind = 'bar', text = '40%' } } } })
	eq(ys(placed), '0 30', 'title, 3, the bar, 3')
	eq(placed[1].lines[1].y .. ' ' .. placed[1].lines[1].height, '15 12', 'the bar sits 3 under the title and is 12 tall')

	placed = rows({ { kind = 'quest', first = 'a', lines = { { text = 'x' }, { kind = 'bar' }, { text = 'y' } } } })
	local lines = placed[1].lines
	eq(lines[1].y, 14, 'a line 2 under the title')
	eq(lines[2].y, 29, 'a bar 3 under the line')
	eq(lines[3].y, 44, 'a line right after the bar: its 3 below were the gap')
	eq(ys(placed), '0 56', 'and the row ends under it')
end)

test('Rows: width: the child width, less 18 with icons, less the button and 4 with one in the row; lines are indented 12 more', function()
	local placed = rows({
		{ kind = 'quest', first = 'a', lines = { { text = 'x' } } },
		{ kind = 'quest', first = 'b', lines = { { text = 'x' } }, item = 'row' },
	}, { width = 244, spacing = 8, icons = true, itemSize = 24 })
	eq(placed[1].titleWidth, 226, 'icons: 244 - 18')
	eq(placed[1].lineWidth, 214, 'the objectives 12 less')
	eq(placed[2].titleWidth, 198, 'a row button: 244 - 18 - 28')
	eq(placed[2].lineWidth, 186, 'and the objectives 12 less')
	placed = rows({ { kind = 'quest', first = 'a', lines = {}, item = 'row' } }, { width = 244, spacing = 8, icons = false, itemSize = 24 })
	eq(placed[1].titleWidth, 216, 'no icons, a button: 244 - 28')
end)

test('Rows: a row with a button is at least Button size tall; the measure gets the width each text is set to', function()
	local placed = rows({
		{ kind = 'quest', first = 'a', lines = {}, item = 'row' },
		{ kind = 'quest', first = 'b', lines = {} },
	}, { width = 244, spacing = 8, icons = false, itemSize = 40 })
	eq(ys(placed), '0 40, 48 12', 'a button makes the row 40; one without keeps the text height')
	local asked = {}
	local Layout = layout()
	Layout.Rows({ { kind = 'quest', first = 'T', lines = { { text = 'L' }, { kind = 'bar' } } } },
		{ width = 244, spacing = 8, icons = true, itemSize = 24 },
		function(text, width, font) asked[#asked + 1] = text .. width .. font; return 12 end)
	eq(table.concat(asked, ' '), 'T226text L214text', 'title then each line, with its width and font; a bar is not measured')
end)

test('Rows: a popup is its label, 2, its title tall but at least 22; then a zone is 10 under it, popups are spacing apart; the empty line is measured', function()
	local function popup() return { kind = 'popup', label = 'Quest discovered', first = 'An offer' } end
	-- Two 12 texts: 12 + 2 + 12 = 26.
	local placed, height = rows({ popup(), popup(), { kind = 'zone' }, { kind = 'quest', first = 'a', lines = {} } })
	eq(ys(placed), '0 26, 34 26, 70 20, 94 12', 'popup, spacing, popup, 10, zone, 4, quest')
	eq(placed[1].labelHeight, 12, 'the label height is kept')
	eq(placed[1].titleHeight, 12, 'and the title height')
	eq(height, 106)
	-- Small texts: the 22 is a floor.
	placed = rows({ popup() }, nil, function() return 10 end)
	eq(ys(placed), '0 22', '10 + 2 + 10 is 22')
	placed = rows({ popup() }, nil, function() return 4 end)
	eq(ys(placed), '0 22', 'never under 22')
	local asked = {}
	rows({ popup() }, nil, function(text, width, font, entry, slot) asked[#asked + 1] = text .. width .. font .. slot; return 12 end)
	eq(table.concat(asked, ' '), 'Quest discovered238headerlabel An offer238texttitle', 'the label in the header font, then the title, at the popup text width')
	placed, height = rows({ { kind = 'empty', first = 'No tracked quests.' } })
	eq(ys(placed), '0 12', 'the empty line is the measured text')
	eq(height, 12)
	placed, height = rows({})
	eq(#placed, 0, 'nothing placed')
	eq(height, 0, 'no height')
end)

test('Rows: pure, and a placed table handed back in is reused', function()
	local Layout = layout()
	local entries = { { kind = 'zone' }, { kind = 'quest', first = 'a', lines = { { text = 'x' }, { text = 'y' } } } }
	local metrics = { width = 244, spacing = 8, icons = false, itemSize = 24 }
	local placed = Layout.Rows(entries, metrics, measure_12)
	local again = Layout.Rows(entries, metrics, measure_12, placed)
	check(again == placed, 'the table given back in is the one returned')
	eq(ys(again), '0 20, 24 40')
	local shorter = Layout.Rows({ { kind = 'zone' } }, metrics, measure_12, placed)
	eq(#shorter, 1, 'no stale entries')
	local third = Layout.Rows({ { kind = 'zone' }, { kind = 'quest', first = 'a', lines = { { text = 'x' } } } }, metrics, measure_12, placed)
	eq(#third[2].lines, 1, 'no stale lines')
end)

test('IntoView: a row below the view scrolls to show it whole, one above to its top, one in view stays; clamped', function()
	local Layout = layout()
	eq(Layout.IntoView(0, 500, 40, 287, 1000), 253, 'a row below: its bottom at the view\'s bottom')
	eq(Layout.IntoView(400, 100, 40, 287, 1000), 100, 'a row above: its top at the view\'s top')
	eq(Layout.IntoView(100, 150, 40, 287, 1000), 100, 'a row in view: no move')
	eq(Layout.IntoView(0, 500, 40, 287, 200), 200, 'clamped to the range')
	eq(Layout.IntoView(300, 0, 40, 287, 1000), 0, 'the top row: 0')
	eq(Layout.IntoView(0, 100, 400, 287, 1000), 100, 'a row taller than the view: its top')
end)

test('Rows: an objective line has a dash before its text: the text is narrower by the dash (metrics.dash) and starts after it; other lines are not dashed', function()
	local Layout = layout()
	local asked = {}
	local placed = Layout.Rows({
		{ kind = 'quest', first = 'T', lines = { { kind = 'objective', text = 'O' }, { kind = 'timer', text = 'Time' }, { kind = 'bar' }, { kind = 'money', text = 'M' } } },
	}, { width = 244, spacing = 8, icons = true, itemSize = 24, dash = 10 }, function(text, width) asked[#asked + 1] = text .. width; return 12 end)
	eq(table.concat(asked, ' '), 'T226 O204 Time214 M214', 'the objective at the line width less the dash, the others as before')
	local lines = placed[1].lines
	eq(lines[1].x .. ' ' .. lines[1].width, '22 204', 'the objective text: indent 12 + dash 10, 204 wide')
	eq(lines[2].x .. ' ' .. lines[2].width, '12 214', 'a timer at the indent')
	eq(lines[3].x .. ' ' .. lines[3].width, '12 214', 'a bar at the indent, as wide as the objectives')
	eq(placed[1].lineWidth, 214, 'the line width is still the title width less the indent')
	asked = {}
	Layout.Rows({ { kind = 'quest', first = 'T', lines = { { kind = 'objective', text = 'O' } } } },
		{ width = 244, spacing = 8, icons = false, itemSize = 24 }, function(text, width) asked[#asked + 1] = text .. width; return 12 end)
	eq(table.concat(asked, ' '), 'T244 O232', 'no dash width given: none taken')
end)
