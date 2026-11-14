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

------------------------------------------------------------------ the rows

-- The whole-pixel clamp of a scroll offset.
local function Clamp(offset, range)
	return math.min(math.max(offset, 0), range)
end

-- Where each row goes in the list (the scroll child), from the top, in whole
-- pixels, and how tall the list is. Pure: the heights of wrapped texts come
-- from measure, which the tracker answers from the real font strings.
--
-- entries are { kind = 'popup' | 'zone' | 'quest' | 'empty', first, lines,
-- item = 'row' | nil }: first is a quest's title (or the empty line's text),
-- lines a quest's lines, each { text } or { kind = 'bar' } (model.lua's lines
-- are this shape); item says a quest's button sits in its row.
-- metrics is { width, spacing, icons, itemSize, dash }: width the scroll child's,
-- dash the room an objective's dash takes before its text (nil for none).
-- measure(text, width, font, entry, slot) -> height gives a text's height
-- wrapped at width; font is 'text' (titles, objectives, the empty line); slot
-- is 'title', 'label' (a popup's) or the line's index (the last two are for a caller that measures
-- the font string of that text).
--
-- Each placed entry is { y, height, titleWidth, lineWidth, titleHeight,
-- lines = { { y, height, x, width } } }, y from the list's top and a line's x
-- (where its text starts, from the title's left) and y from the
-- row's; a popup also has labelHeight. A popup entry has its label and its
-- title (first): the row is the two and 2 between them, at least POPUP tall.
-- Gaps (Ruling 18): a zone header is 10 under what's above it, a row
-- 4 under a zone header, and rows spacing apart (popups too). Title width is
-- the child width, less ICON + ICON_GAP with icons, less itemSize + 4 with the
-- button in the row; line width is the title width less INDENT (Ruling 11). A
-- bar takes 3 above and 3 below and no line gap of its own. out, when given,
-- is a table of an earlier call to fill again, so a refresh makes none.
function Layout.Rows(entries, metrics, measure, out)
	local placed = out or {}
	for index = #entries + 1, #placed do placed[index] = nil end
	local width, spacing = metrics.width, metrics.spacing
	local y, previous = 0, nil
	for index, entry in ipairs(entries) do
		local kind = entry.kind
		if previous == nil then
			-- the first row: no gap
		elseif kind == 'zone' then
			y = y + L.ZONE_ABOVE
		elseif previous == 'zone' then
			y = y + L.ZONE_BELOW
		else
			y = y + spacing
		end
		local row = placed[index]
		if not row then
			row = { lines = {} }
			placed[index] = row
		end
		local lines = row.lines
		local used = 0
		row.y = y
		row.titleHeight = 0
		if kind == 'zone' then
			row.height = L.ZONE
			row.titleWidth = width - L.CHEVRON - L.ZONE_TITLE_GAP
			row.lineWidth = row.titleWidth
		elseif kind == 'popup' then
			-- The label over the title, 2 apart; 22 is the least (two small fonts).
			row.titleWidth = width - L.POPUP_BAR - L.FOCUS_GAP
			row.lineWidth = row.titleWidth
			row.labelHeight = measure(entry.label, row.titleWidth, 'header', entry, 'label')
			row.titleHeight = measure(entry.first, row.titleWidth, 'text', entry, 'title')
			row.height = math.max(L.POPUP, row.labelHeight + L.LINE_GAP + row.titleHeight)
		elseif kind == 'empty' then
			row.titleWidth = width
			row.lineWidth = width
			row.titleHeight = measure(entry.first, width, 'text', entry, 'title')
			row.height = row.titleHeight
		else
			local titleWidth = width
			if metrics.icons then titleWidth = titleWidth - L.ICON - L.ICON_GAP end
			if entry.item == 'row' then titleWidth = titleWidth - metrics.itemSize - L.ITEM_GAP end
			local lineWidth = titleWidth - L.INDENT
			row.titleWidth, row.lineWidth = titleWidth, lineWidth
			local titleHeight = measure(entry.first, titleWidth, 'text', entry, 'title')
			row.titleHeight = titleHeight
			local cursor, afterBar = titleHeight, false
			for j, line in ipairs(entry.lines or {}) do
				local part = lines[j]
				if not part then
					part = {}
					lines[j] = part
				end
				-- An objective's text starts after its dash (metrics.dash); other lines
				-- start at the indent.
				local dash = line.kind == 'objective' and metrics.dash or 0
				part.x, part.width = L.INDENT + dash, lineWidth - dash
				if line.kind == 'bar' then
					part.x, part.width = L.INDENT, lineWidth
					cursor = cursor + L.BAR_GAP
					part.y, part.height = cursor, L.BAR
					cursor = cursor + L.BAR + L.BAR_GAP
					afterBar = true
				else
					if not afterBar then cursor = cursor + L.LINE_GAP end
					part.y = cursor
					part.height = measure(line.text, part.width, 'text', entry, j)
					cursor = cursor + part.height
					afterBar = false
				end
				used = j
			end
			row.height = cursor
			if entry.item == 'row' and metrics.itemSize > cursor then row.height = metrics.itemSize end
		end
		for j = used + 1, #lines do lines[j] = nil end
		y = y + row.height
		previous = kind
	end
	return placed, y
end

-- The scroll offset that shows the row at top (height tall) whole in a view
-- of view pixels, or the offset it has when it's in view already; a row
-- taller than the view is shown from its top. Clamped to 0 and range.
function Layout.IntoView(offset, top, height, view, range)
	if height >= view or top < offset then
		offset = top
	elseif top + height > offset + view then
		offset = top + height - view
	end
	return Clamp(offset, range)
end
