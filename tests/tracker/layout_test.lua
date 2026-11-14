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
