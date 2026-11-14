local st = SaftUI
local TR = st.Tracker

--[[
	The window's layout constants and math (design: "Layout (exact values)"),
	pure: no frame, no event, no API call. Every length is a whole pixel. The
	constants a later task draws with (zone headers, rows, popups, item
	buttons, the column) are listed here from the start so the numbers live in
	one place.
]]

TR.LAYOUT = {
	PAD = 8, HEADER = 24, HEADER_GAP = 6, COUNT_GAP = 6, CHEVRON = 16, LINE_ALPHA = 0.5,
	ZONE = 20, ZONE_ABOVE = 10, ZONE_BELOW = 4, ZONE_TITLE_GAP = 2, ICON = 14, ICON_GAP = 4,
	INDENT = 12, LINE_GAP = 2, BAR = 12, BAR_GAP = 3, POPUP = 22, POPUP_BAR = 2,
	FOCUS_BAR = 2, FOCUS_GAP = 4, HOVER_PAD = 2, WHEEL = 40, BAR_LINGER = 0.3,
	ITEM_GAP = 4, COLUMN_GAP = 4, COLUMN_STACK = 2, BESIDE_GAP = 12, BLIZZARD_OFF = 100,
}
local L = TR.LAYOUT

local Layout = {}
TR.Layout = Layout

-- What the header takes at the top of the window: its height and the gap after.
local function HeaderRoom(header)
	return header and L.HEADER + L.HEADER_GAP or 0
end

-- The window's height for content (the rows' height): padding, the header and
-- its gap while it shows, the content, padding, at most opts.max. opts is
-- { header, collapsed, max }. Collapsed it is the padding and the header only
-- (40); with no header there is no whole-tracker collapse, so the flag is
-- ignored (Ruling 15).
function Layout.WindowHeight(content, opts)
	local header = opts.header and true or false
	if opts.collapsed and header then return 2 * L.PAD + L.HEADER end
	local height = 2 * L.PAD + HeaderRoom(header) + (content or 0)
	if opts.max and height > opts.max then return opts.max end
	return height
end

-- The scroll view's height inside a window of windowHeight; never negative.
function Layout.ViewHeight(windowHeight, header)
	return math.max(0, windowHeight - 2 * L.PAD - HeaderRoom(header and true or false))
end

-- The scroll child's width (and the scroll frame's): the window's less padding
-- on both sides and the scroll bar's room.
function Layout.ChildWidth(width, barRoom)
	return width - 2 * L.PAD - (barRoom or 0)
end

-- How far the list scrolls: the content past the view.
function Layout.ScrollRange(content, view)
	return math.max(0, content - view)
end

-- The offset after a wheel notch (delta 1 is up, -1 down, as the game gives
-- it): WHEEL a notch, clamped to 0 and range.
function Layout.Wheel(offset, delta, range)
	return math.min(math.max(offset - delta * L.WHEEL, 0), range)
end
