local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets

--[[
	The body of SaftUI's options window, and of its small dialogs: sections of
	rows drawn into a content frame. The window (optionswindow.lua) and
	OW:OpenDialog each make one.

	  local body = OB.New(content, root, onChanged, width)
	      content     the frame the rows are drawn in (a scroll child)
	      root        the option tree the rows' widgets read and set
	      onChanged   the widgets' onChanged(ok, err, isDragging)
	      width       the content's width (OB.WIDTH, the window's, when nil)
	  body:SetRoot(root)               a new tree (a profile change rebuilt it)
	  body:Draw(sections, fillHeight) -> height
	                                   option rows, each with its widget;
	                                   fillHeight is the view's height, which
	                                   fill rows stretch the drawn height to
	                                   (body.filled: one was drawn)
	  body:DrawResults(sections, onPick) -> height
	                                   search results: a button per row,
	                                   onPick(row) on a click
	  body:Release()                   everything drawn goes back to its pool
	  body:Refresh(except)             every drawn widget but except shows its
	                                   row again in place (a drag, below)
	  body.cells                       the drawn rows, in order:
	                                   { row, frame, widget, label, height, y,
	                                     x, body }
	  body.shareTitles                 the section titles drawn with a
	                                   shareable block's marks (optionsshare.lua)

	sections are the model's ({ title, note, rows }, OM.BuildView). Rows no
	widget draws are left out, and so are sections left empty; the height is
	0 when nothing is drawn. Sections are laid out by OB.LayoutSections, their
	rows by OB.LayoutRows, both pure: a row is small (a quarter of the line;
	two make a half), normal (a half) or wide (the whole line), by row.size.

	Two sets of metrics (OB.FLAT, OB.PANELED; body.metrics), chosen by the look
	at each Draw: under Blizzard rows are 34 tall in two columns 40 apart with
	nothing behind them, a 1px OB.LINE between the halves of a line and the
	quarters of a half. Under Thick and Thin rows are 38 tall, each section
	with rows sits on a panel (black at 28%) the body wide, every row 14 in
	from its slot's edges (Body:SlotRect is the slot, Body:CellRect the cell),
	with a hairline (white at 7%) at the top of each line but the first of a
	panel and as dividers between columns (a last line with a row in the left
	half only has its divider too). No line between sections. Rows that follow
	an inline group join the panel above, one panel. A fill row is bare, the
	whole line, and ends a panel; the section's other lines have theirs.
	Buttons with an align (row.align, the model's) that follow each other
	are a line of buttons instead, side by side at their own widths, 12
	apart, with no dividers: centred ones on a line of their own, in its
	middle, and right ones at the line's right end, on the line of a wide
	row just before them (whose cell then ends 24 before the buttons, so its
	label and control take the rest), else on a line of their own, all
	inside the padding.
	A toggle's check box and a color's bar sit at their cell's right edge,
	the label taking the rest; a small input's box is 60 wide. A position block
	has no label (its section is titled Position), is as tall as the widget
	plus 12, and shows the row's desc when the mouse is anywhere on it. A
	bare row (a type W.Define marks bare; its option sets size = 'wide') has
	no label either: its widget is given its cell's width (the body's less the
	padding; SetWidth, when it has one) before its height is read, and sits
	at the cell's top left, 6 down, in a cell as tall as the widget plus 12.
	Its row takes no mouse, so the widget's own parts get it. A titled bare
	row (W.Define's titled) shows its name as a label 6 down, with its desc
	as the name's tooltip, and its widget 28 down, in a cell as tall as the
	widget plus 34. A fill row (W.Define's fill, a bare type) takes the
	height the view has left once the other rows are laid out (fillHeight
	less the drawn height), so the drawn height is the view's and the page
	has nothing to scroll; never
	less than its type's minHeight, and the widget is told its height with
	SetHeight. Without fillHeight (a dialog, search results) it's minHeight.
	A description with SaftUI's fill set is a fill row too, its minHeight
	the height it would have without: its text sits in the middle of it.

	Shareable options (SaftUI's share field) are drawn by optionsshare.lua,
	which loads right after this file and hooks in at three places: PlaceRow
	ends with OB.PlaceShare(cell) (cell.body is the body), the row frame's
	OnEnter and a position block's parts call OB.ShareEnter(frame), and
	DrawSections calls OB.PlaceShareTitle(body, entry, title) for a section
	with a shareRow (the model's) once its block is placed. A world that
	draws no window may load this file without it, so each is called only
	when it's there. The metrics' markX and markShift place the own mark, and
	OB.OWN_TEXT and OB.DIFF_COLOR are its colors; OB.PlaceLabel puts a label
	where PlaceRow does, x in.

	The window's fonts live here too (OB.Font, OB.UpdateFonts), with the small
	pieces both use (OB.Text, OB.Line, the pools, the scroll bar: OB.ScrollBar,
	OB.ScrollTo, and under Blizzard its companion, OB.Companion), as this file
	loads first.

	Every frame and texture here is SaftUI's. GameTooltip shows a row's desc
	through its public API, and while the row is disabled its disabledDesc
	(why) under it.
]]

local OB = {}
st.OptionsBody = OB

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local tremove = table.remove

------------------------------------------------------------------ the mockup's numbers

local ROW_HEIGHT = 34
local LABEL_GAP = 10
local STOP_GAP = 24 -- a wide row ends this far before the buttons at its line's right end
local BUTTON_GAP = 12 -- between the buttons of a line (W.Confirm's Yes and No are 12 apart)
local SMALL_INPUT_WIDTH = 60
local WIDTH = 774 -- the window's body: under Blizzard two columns of 367 with a gap of 40; under Thick and Thin two of 387

-- Sections (OB.LayoutSections).
local BODY_TOP, BODY_BOTTOM = 4, 24
local SECTION_PAD, SECTION_MARGIN = 16, 14
local TITLE_HEIGHT, TITLE_GAP = 15, 6
local NOTE_HEIGHT, NOTE_GAP = 13, 4
local CONTINUE_GAP = 4 -- an untitled section after another: a continuation

OB.ROW_HEIGHT, OB.LABEL_GAP, OB.WIDTH = ROW_HEIGHT, LABEL_GAP, WIDTH

-- The two sets of metrics a body lays out with (chosen at each draw, by look):
-- FLAT is Blizzard's, rows 34 tall in two columns 40 apart (quarters 24 apart)
-- with nothing behind them; PANELED is Thick's and Thin's, rows 38 tall on a
-- panel per section, padded 14 either side, the columns and quarters flush
-- (a faint line divides them). A shared setting's own mark (optionsshare.lua)
-- sits markX in from its slot's left (under PANELED inside the padding), and
-- what it marks moves markShift right (under FLAT, to make room inside the
-- cell: the body's scroll frame clips left of the content).
OB.FLAT = { rowHeight = 34, pad = 0, columnGap = 40, quarterGap = 24, panels = false, markX = 0, markShift = 6 }
OB.PANELED = { rowHeight = 38, pad = 14, columnGap = 0, quarterGap = 0, panels = true, markX = 5, markShift = 0 }
OB.PANEL_FILL = { 0, 0, 0, 0.28 } -- a section's panel: black at 28%
OB.HAIRLINE = { 1, 1, 1, 0.07 } -- the lines between rows and between columns: white at 7%
OB.TOP = BODY_TOP + SECTION_PAD -- where the first section's rows start
OB.TITLE_HEIGHT = TITLE_HEIGHT -- a section title's line

-- A shared setting's marks (optionsshare.lua): an own row's label (the
-- mockup's light blue), and the diff icon (its orange).
OB.OWN_TEXT = { 0.56, 0.85, 1 }
OB.DIFF_COLOR = { 0.88, 0.63, 0.25 }

-- A row's label line: its text sits in a band this tall.
local LABEL_HEIGHT = 16
OB.LABEL_HEIGHT = LABEL_HEIGHT

OB.LINE = { 0.18, 0.18, 0.18, 1 } -- #2e2e2e: the lines between parts

local Colors = OM.Colors
local function Normal() return Colors().text.normal:GetRGB() end
local function Grey() return Colors().text.grey:GetRGB() end
local function Blue() return Colors().button.blue:GetRGB() end
OB.Colors, OB.Normal, OB.Grey, OB.Blue = Colors, Normal, Grey, Blue -- the window's files take them

------------------------------------------------------------------ fonts

-- The window's own font objects: the profile's title (Colus) and normal
-- (Agency FB) faces and outlines, at the window's sizes. 'field' is the
-- widgets' (15).
local FONTS = {
	title = { 'title', 34 }, brand = { 'title', 26 }, section = { 'title', 15 }, group = { 'title', 13 },
	caption = { 'title', 11 }, tab = { 'normal', 17 }, label = { 'normal', 16 }, small = { 'normal', 13 },
}
local fontObjects = {}

local function ApplyFont(key)
	local face, size = FONTS[key][1], FONTS[key][2]
	local config = st.config.profile.fonts[face]
	fontObjects[key]:SetFont(st.LSM:Fetch('font', config.font_name), size, st.OutlineFlag(config.font_outline))
	fontObjects[key]:SetTextColor(Normal())
end

function OB.Font(key)
	if key == 'field' then return W.GetFont() end
	if not fontObjects[key] then
		local name = 'SaftUI_Options' .. key:gsub('^%l', string.upper) .. 'Font'
		fontObjects[key] = _G[name] or CreateFont(name)
		ApplyFont(key)
	end
	return fontObjects[key]
end

-- The profile's faces again (a profile change), the widgets' too.
function OB.UpdateFonts()
	for key in pairs(fontObjects) do ApplyFont(key) end
	W.UpdateFonts()
end

------------------------------------------------------------------ small pieces

function OB.Text(parent, font, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(OB.Font(font))
	fs:SetJustifyH(justify or 'LEFT')
	fs:SetWordWrap(false)
	return fs
end

function OB.Line(parent)
	local line = parent:CreateTexture(nil, 'ARTWORK')
	line:SetColorTexture(unpack(OB.LINE))
	return line
end

-- Pools of frames, font strings or textures, handed out per render.
function OB.Pool(make) return { make = make, free = {}, used = {} } end

function OB.Acquire(pool)
	local object = tremove(pool.free) or pool.make()
	pool.used[#pool.used + 1] = object
	object:ClearAllPoints()
	object:Show()
	return object
end

function OB.ReleaseAll(pool)
	for i = #pool.used, 1, -1 do
		local object = pool.used[i]
		pool.used[i] = nil
		object:Hide()
		object:ClearAllPoints()
		pool.free[#pool.free + 1] = object
	end
end

local Text, Line, Pool, Acquire, ReleaseAll = OB.Text, OB.Line, OB.Pool, OB.Acquire, OB.ReleaseAll

------------------------------------------------------------------ scrolling

-- A scroll bar: 3 wide, 10 to the right of what it scrolls; a turn of the
-- mouse wheel moves two rows. Under Blizzard Blizzard's minimal scroll bar
-- (W.BlizzardBar), OB.BLIZZARD_GAP to the right of what it scrolls unless
-- the caller gives its own gap.
OB.BAR_WIDTH, OB.BAR_GAP = 3, 10
OB.BLIZZARD_GAP = 12
OB.SCROLL_STEP = ROW_HEIGHT * 2

-- A scroll bar's texture -> { bar = its W.BlizzardBar, flat = whether the
-- texture shows under Thick and Thin }.
local companions = setmetatable({}, { __mode = 'k' })

-- The window's scroll bar: a 3px bar in the boxes' edge color, hidden until
-- OB.ScrollTo shows it, with its companion, Blizzard's minimal scroll bar
-- (W.BlizzardBar(parent, onScroll, opts)), which OB.ScrollTo shows in its
-- place under Blizzard. onScroll(offset) is the caller's own scroll, which
-- the companion's thumb, arrows (opts.step a click) and track ask an offset
-- of; opts.narrow is a narrow bar. opts.flat == false draws no 3px bar under
-- Thick and Thin (the sidebar's, which has none there).
function OB.ScrollBar(parent, onScroll, opts)
	opts = opts or {}
	local bar = parent:CreateTexture(nil, 'OVERLAY')
	bar:SetColorTexture(unpack(st.BOX_COLORS.edge))
	bar:SetWidth(OB.BAR_WIDTH)
	bar:Hide()
	companions[bar] = { bar = W.BlizzardBar(parent, onScroll, opts), flat = opts.flat ~= false }
	return bar
end

-- The W.BlizzardBar made with an OB.ScrollBar's texture.
function OB.Companion(bar)
	local companion = companions[bar]
	return companion and companion.bar
end

-- Scrolls frame (a scroll frame) to offset, within the height of what it
-- holds, in whole units. Its bar shows only when there is something to
-- scroll, gap (OB.BAR_GAP when nil) to the right of the scroll child, as
-- tall as the share of it in view and as far down as the offset. Under
-- Blizzard the bar's companion shows in its place, from the scroll frame's
-- top to its bottom, gap (OB.BLIZZARD_GAP when nil) to the right of the
-- scroll child. Returns the offset it took.
function OB.ScrollTo(frame, bar, offset, height, gap)
	local view = frame:GetHeight() or 0
	local range = max(0, height - view)
	offset = max(0, min(range, floor(offset + 0.5)))
	frame:SetVerticalScroll(offset)
	local child = frame:GetScrollChild()
	local width = child and child:GetWidth() or frame:GetWidth()
	local companion = companions[bar]
	local blizzard = companion and W.BlizzardLook()
	if companion and not blizzard then companion.bar:Hide() end
	if blizzard then
		bar:Hide()
		companion.bar:Set(frame, width + (gap or OB.BLIZZARD_GAP), 0, floor(view + 0.5), view, height, offset)
	elseif range > 0 and view > 0 and (not companion or companion.flat) then
		local size = max(20, floor(view * view / height))
		bar:SetHeight(size)
		bar:ClearAllPoints()
		bar:SetPoint('TOPLEFT', frame, 'TOPLEFT', width + (gap or OB.BAR_GAP), -floor((view - size) * offset / range))
		bar:Show()
	else
		bar:Hide()
	end
	return offset
end

------------------------------------------------------------------ the pure layout

-- Whether buttons aligned right can share a wide row's line: any wide row
-- but a description or a bare row, which are drawn across the whole line.
-- A position row would share it, but never comes before them: the model
-- gives it a section of its own.
local function SharesLine(row)
	local custom = W.CUSTOM[row.type]
	return row.type ~= 'description' and not (custom and custom.bare)
end

-- Places rows on lines of four quarters (two halves). A small row takes the
-- next quarter, a normal row the next whole half (it skips a lone quarter's
-- other half), a wide row a line of its own. Buttons with an align that
-- follow each other are a group, a line of buttons (OB.ButtonRow places
-- them): a 'center' group takes a line of its own; a 'right' group takes the
-- line of the wide row just before it, if that row can share it, else a line
-- of its own. A group must fit its line: it never wraps, and buttons wider
-- than the line run past its edges. A line is as tall as its tallest row
-- (heightOf(row), ROW_HEIGHT without it). sizeOf(row) gives a row's size
-- (row.size without it; no size is normal), alignOf(row) its align
-- (row.align without it).
-- Returns { {row, col = 1|2|'full', quarter = 1|2|nil (smalls only), y} }
-- and the height of them all; a button's entry is {row, col = 'buttons',
-- group, index (its place in the group), y}, a group { align, rows }, and a
-- wide row's entry has buttons = the group on its line, if any.
function OB.LayoutRows(rows, heightOf, sizeOf, alignOf)
	local placed, y, cursor, lineHeight = {}, 0, 0, 0 -- cursor: quarters used in the line
	local wide, group -- the wide row just placed, as { entry, height }; the group being placed
	local function NextLine()
		y, cursor, lineHeight = y + lineHeight, 0, 0
	end
	for _, row in ipairs(rows) do
		local height = heightOf and heightOf(row) or ROW_HEIGHT
		local size = (sizeOf and sizeOf(row) or row.size) or 'normal'
		local align
		if alignOf then align = alignOf(row) else align = row.align end
		if align then
			if not (group and group.align == align) then
				group = { align = align, rows = {} }
				if align == 'right' and wide and SharesLine(wide.entry.row) then
					-- Back onto the wide row's line, at its right end.
					y, lineHeight = wide.entry.y, wide.height
					wide.entry.buttons = group
				elseif cursor > 0 then
					NextLine()
				end
			end
			group.rows[#group.rows + 1] = row
			placed[#placed + 1] = { row = row, col = 'buttons', group = group, index = #group.rows, y = y }
			lineHeight = max(lineHeight, height)
			cursor = 4 -- the line is the buttons'
			wide = nil
		elseif size == 'wide' then
			if cursor > 0 then NextLine() end
			local entry = { row = row, col = 'full', y = y }
			placed[#placed + 1] = entry
			lineHeight = height
			NextLine()
			wide, group = { entry = entry, height = height }, nil
		else
			wide, group = nil, nil
			if size == 'normal' and cursor % 2 == 1 then cursor = cursor + 1 end
			if cursor >= 4 then NextLine() end
			local col = cursor < 2 and 1 or 2
			placed[#placed + 1] = {
				row = row, col = col, y = y, quarter = size == 'small' and (cursor % 2 + 1) or nil,
			}
			lineHeight = max(lineHeight, height)
			cursor = cursor + (size == 'small' and 1 or 2)
		end
	end
	if cursor > 0 then NextLine() end
	return placed, y
end

-- Places sections down the body: { {section, lineY, titleY, noteY, rowsY,
-- rowsHeight, joins, placed} } and the body's height. The space for a line
-- between sections after the first is kept (lineY) though none is drawn any
-- more; an untitled one (rows that follow a nested group) keeps none, so it
-- reads as a continuation of the one above: CONTINUE_GAP below it, or with
-- panels (the fifth argument) none at all, and joins = true, for it to share
-- the panel above. heightOf, sizeOf and alignOf are OB.LayoutRows'.
function OB.LayoutSections(sections, heightOf, sizeOf, alignOf, panels)
	local laid, y = {}, BODY_TOP
	for i, section in ipairs(sections) do
		local entry = { section = section }
		if i == 1 then
			y = y + SECTION_PAD
		elseif section.title then
			y = y + SECTION_MARGIN
			entry.lineY = y
			y = y + 1 + SECTION_PAD
		elseif panels and not section.note then
			entry.joins = true
		else
			y = y + CONTINUE_GAP
		end
		if section.title then
			entry.titleY = y
			y = y + TITLE_HEIGHT + TITLE_GAP
		end
		if section.note then
			entry.noteY = y - 2
			y = y + NOTE_HEIGHT + NOTE_GAP
		end
		entry.rowsY = y
		local placed, height = OB.LayoutRows(section.rows, heightOf, sizeOf, alignOf)
		entry.placed = placed
		entry.rowsHeight = height
		y = y + height
		laid[#laid + 1] = entry
	end
	return laid, y + BODY_BOTTOM
end

-- The vertical lines between the cells of a section's lines (placed, as
-- OB.LayoutRows gives it): one between the halves of a line with a row in
-- each, and one between the quarters of a half with two small rows. A
-- divider is as tall as its line (heightOf as for OB.LayoutRows), so the
-- dividers of lines that follow each other join up. A wide row's line and a
-- line of buttons have none. With extendLast, the section's last line has
-- one too when it holds only a row in the left half, so the divider runs to
-- the bottom beside the empty half. Returns { {at = 'half' | 'quarter', col =
-- 1|2 (quarters), y, height} }.
function OB.Dividers(placed, heightOf, extendLast)
	local lines, order, lastY = {}, {}, nil
	for _, p in ipairs(placed) do
		lastY = max(lastY or p.y, p.y)
		if p.col == 1 or p.col == 2 then
			local line = lines[p.y]
			if not line then
				line = { y = p.y, height = 0, halves = {}, smalls = { 0, 0 } }
				lines[p.y] = line
				order[#order + 1] = line
			end
			line.height = max(line.height, heightOf and heightOf(p.row) or ROW_HEIGHT)
			line.halves[p.col] = true
			if p.quarter then line.smalls[p.col] = line.smalls[p.col] + 1 end
		end
	end
	local dividers = {}
	for _, line in ipairs(order) do
		if line.halves[1] and (line.halves[2] or (extendLast and line.y == lastY)) then
			dividers[#dividers + 1] = { at = 'half', y = line.y, height = line.height }
		end
		for col = 1, 2 do
			if line.smalls[col] == 2 then
				dividers[#dividers + 1] = { at = 'quarter', col = col, y = line.y, height = line.height }
			end
		end
	end
	return dividers
end

-- The lines between a section's rows (placed, as OB.LayoutRows gives it): the
-- top of every line but the first, ascending.
function OB.Hairlines(placed)
	local seen, tops = {}, {}
	for _, p in ipairs(placed) do
		if not seen[p.y] then
			seen[p.y] = true
			tops[#tops + 1] = p.y
		end
	end
	table.sort(tops)
	tremove(tops, 1)
	return tops
end

-- Where a line of buttons goes (widths, each button's, in order): side by
-- side, BUTTON_GAP apart, the last flush with the line's right edge
-- (align 'right') or the whole row in the line's middle ('center'), on
-- whole units (whole widths in a width of whole units). Returns each
-- button's x and the row's left edge.
function OB.ButtonRow(widths, align, width)
	local total = 0
	for i, w in ipairs(widths) do total = total + w + (i > 1 and BUTTON_GAP or 0) end
	local x = align == 'right' and width - total or floor((width - total) / 2)
	local xs, left = {}, x
	for i, w in ipairs(widths) do
		xs[i] = x
		x = x + w + BUTTON_GAP
	end
	return xs, left
end

------------------------------------------------------------------ rows

-- A row's tooltip: its name, its desc, and while it's disabled why
-- (row.disabledDesc, the model's), in Text > Red. Of frame's row, owned by
-- owner (the frame itself when nil: an execute button owns its own).
local function ShowTip(frame, owner)
	local row = frame.row
	if not row then return end
	local desc = row.desc ~= '' and row.desc or nil
	local why = row.disabledDesc ~= '' and row.disabledDesc or nil
	if not (desc or why) then return end
	GameTooltip:SetOwner(owner or frame, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(row.name, 1, 1, 1)
	if desc then GameTooltip:AddLine(desc, nil, nil, nil, true) end
	if why then
		local r, g, b = Colors().text.red:GetRGB()
		GameTooltip:AddLine(why, r, g, b, true)
	end
	GameTooltip:Show()
end

local function HideTip(frame, owner)
	if GameTooltip:IsOwned(owner or frame) then GameTooltip:Hide() end
end
OB.ShowTip, OB.HideTip = ShowTip, HideTip -- the window's footer control shows its widgets' tips with them

-- A custom type W.Define marked bare: no label, the widget across the line.
local function IsBare(rowType)
	local custom = W.CUSTOM[rowType]
	return custom ~= nil and custom.bare
end

-- A bare type marked titled too: its name over the widget.
local function IsTitled(rowType)
	local custom = W.CUSTOM[rowType]
	return custom ~= nil and custom.bare and custom.titled
end

-- A bare type marked fill: its row stretches down the view. Its least height, or nil.
local function FillMin(rowType)
	local custom = W.CUSTOM[rowType]
	return custom ~= nil and custom.fill and custom.minHeight or nil
end

-- Where a titled bare row's widget starts: its name 6 down, 16 high, and 6 under it.
local BARE_TITLE = 28

-- A titled bare row's name takes the mouse through a frame over it (the
-- row takes none), which shows the row's desc.
local function TitleTip(frame)
	local tip = frame.titleTip
	if not tip then
		tip = CreateFrame('Frame', nil, frame)
		tip:EnableMouse(true)
		tip:SetScript('OnEnter', function(self) ShowTip(self:GetParent()) end)
		tip:SetScript('OnLeave', function(self) HideTip(self:GetParent()) end)
		frame.titleTip = tip
	end
	return tip
end

-- Where a row's label sits, x in from its cell's left: across the row's
-- middle, or in a tall row (a multiselect's) across its first rowHeight.
-- optionsshare.lua moves it (a mark's shift) and puts it back with this.
function OB.PlaceLabel(cell, x)
	local label, frame = cell.label, cell.frame
	label:ClearAllPoints()
	if cell.height > cell.rowHeight then
		label:SetPoint('TOPLEFT', frame, 'TOPLEFT', x or 0, -floor((cell.rowHeight - LABEL_HEIGHT) / 2))
	else
		label:SetPoint('LEFT', frame, 'LEFT', x or 0, 0)
	end
end

-- A row's place in its cell: the label on the left, the control on the
-- right. A description is text across the row, and a button stands alone.
-- Then a shareable row's marks (OB.PlaceShare, optionsshare.lua, which a
-- world that draws no window may not load).
local function PlaceRow(cell, x, y, width)
	local frame, widget, label, row = cell.frame, cell.widget, cell.label, cell.row
	frame:SetPoint('TOPLEFT', frame:GetParent(), 'TOPLEFT', x, -y)
	frame:SetSize(width, cell.height)
	cell.x = x
	label:ClearAllPoints()
	if row.type == 'description' then
		label:Hide()
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -6)
	elseif row.type == 'execute' then
		label:Hide()
		widget:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	elseif row.type == 'position' then
		label:Hide()
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -6)
	elseif IsTitled(row.type) then
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Grey()) else label:SetTextColor(Normal()) end
		label:SetWidth(width)
		label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -6)
		label:Show()
		local tip = TitleTip(frame)
		tip:ClearAllPoints()
		tip:SetPoint('TOPLEFT', label, 'TOPLEFT', 0, 0)
		tip:SetSize(max(1, ceil(label:GetUnboundedStringWidth())), 16)
		tip:Show()
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -BARE_TITLE)
	elseif IsBare(row.type) then
		label:Hide()
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -6)
	else
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Grey()) else label:SetTextColor(Normal()) end
		label:Show()
		label:SetWidth(max(1, width - widget:GetWidth() - LABEL_GAP))
		OB.PlaceLabel(cell, 0)
		if cell.height > cell.rowHeight then
			widget:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, -6)
		else
			widget:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
		end
	end
	if OB.PlaceShare then OB.PlaceShare(cell) end
end

local function PlaceResult(cell, x, y, width)
	cell.frame:SetPoint('TOPLEFT', cell.frame:GetParent(), 'TOPLEFT', x, -y)
	cell.frame:SetSize(width, cell.height)
	cell.label:SetWidth(width - 16)
end

------------------------------------------------------------------ the body

local Body = {}
Body.__index = Body

function OB.New(content, root, onChanged, width)
	local body = setmetatable({
		content = content, root = root, onChanged = onChanged,
		width = width or WIDTH, cells = {},
		shareTitles = {}, -- the section titles drawn with a shareable block's marks (optionsshare.lua)
	}, Body)
	body:UseMetrics()

	body.pools = {
		row = Pool(function()
			local frame = CreateFrame('Frame', nil, content)
			frame.label = Text(frame, 'label')
			-- Wrapped: the game passes these scripts a second argument (motion),
			-- which ShowTip and HideTip would take for the tooltip's owner. A
			-- shareable row's hover line shows too (optionsshare.lua).
			frame:SetScript('OnEnter', function(self)
				ShowTip(self)
				if OB.ShareEnter then OB.ShareEnter(self) end
			end)
			frame:SetScript('OnLeave', function(self) HideTip(self) end)
			return frame
		end),
		result = Pool(function()
			local button = CreateFrame('Button', nil, content)
			button.hover = button:CreateTexture(nil, 'BACKGROUND')
			button.hover:SetAllPoints(button)
			button.hover:Hide()
			button.text = Text(button, 'label')
			button.text:SetPoint('LEFT', button, 'LEFT', 8, 0)
			button:SetScript('OnEnter', function(self)
				local r, g, b = Blue()
				self.hover:SetColorTexture(r, g, b, 0.25)
				self.hover:Show()
			end)
			button:SetScript('OnLeave', function(self) self.hover:Hide() end)
			button:SetScript('OnClick', function(self)
				if self.onPick then self.onPick(self.row) end
			end)
			return button
		end),
		line = Pool(function() return Line(content) end),
		panel = Pool(function()
			local panel = content:CreateTexture(nil, 'BACKGROUND')
			panel:SetColorTexture(unpack(OB.PANEL_FILL))
			return panel
		end),
		hairline = Pool(function()
			local hairline = content:CreateTexture(nil, 'BORDER')
			hairline:SetColorTexture(unpack(OB.HAIRLINE))
			return hairline
		end),
		title = Pool(function()
			local title = Text(content, 'section')
			title:SetTextColor(Grey())
			title:SetWidth(body.width)
			return title
		end),
		note = Pool(function()
			local note = Text(content, 'small')
			note:SetTextColor(Grey())
			note:SetWidth(body.width)
			return note
		end),
	}
	return body
end

-- The metrics for the look now drawn (OB.FLAT under Blizzard, else OB.PANELED),
-- and the widths that follow them. Whole units only: SaftUI's scale makes a
-- unit a pixel, and a 1px border on a frame that starts or ends between two
-- pixels blurs. Halves round down, and the second of each pair sits flush with
-- the outer edge (SlotRect), so an odd remainder widens the gap by a pixel
-- (a 367 column's quarters are 171 and 171, 25 apart; a 387 column's, under
-- panels, are 193 and 193 with a gap of 1 at 193, where the divider sits).
function Body:UseMetrics()
	local metrics = W.BlizzardLook() and OB.FLAT or OB.PANELED
	self.metrics = metrics
	self.columnWidth = floor((self.width - metrics.columnGap) / 2)
	self.quarterWidth = floor((self.columnWidth - metrics.quarterGap) / 2)
end

-- Where a column's slot goes: its x in the content and its width, for a column
-- ('full', 1 or 2) and, in a half, a quarter (1 or 2, or nil for the whole
-- half). The second column and the second quarter sit flush with their right
-- edge, so every edge is a whole unit.
function Body:SlotRect(col, quarter)
	if col == 'full' then return 0, self.width end
	local x = col == 2 and (self.width - self.columnWidth) or 0
	if not quarter then return x, self.columnWidth end
	if quarter == 2 then x = x + self.columnWidth - self.quarterWidth end
	return x, self.quarterWidth
end

-- Where a cell goes: its slot, inset by the metrics' padding on each side
-- ('full' too). Under OB.FLAT that is the slot.
function Body:CellRect(col, quarter)
	local x, width = self:SlotRect(col, quarter)
	local pad = self.metrics.pad
	return x + pad, width - 2 * pad
end

function Body:SetRoot(root)
	self.root = root
end

-- A drawn row of the page: its frame and widget, and its height.
function Body:RowCell(row)
	if not W.WIDTH[row.type] then return nil end -- not a type the widgets draw
	local frame = Acquire(self.pools.row)
	frame.row = row
	-- Set as each row is acquired: a pooled frame may last have been a bare row's.
	local bare = IsBare(row.type)
	frame:EnableMouse(not bare)
	if frame.titleTip then frame.titleTip:Hide() end -- a titled bare row's (PlaceRow)
	local widget = W.Create(frame, row.type)
	widget:Bind(self.root, row, self.onChanged)
	if row.type == 'input' then -- a reused box is sized again: small or not
		widget.width = row.size == 'small' and SMALL_INPUT_WIDTH or W.WIDTH.input
		widget.frame:SetWidth(widget.width)
	end
	local rowHeight, inside = self.metrics.rowHeight, self.width - 2 * self.metrics.pad
	local cell = {
		row = row, frame = frame, widget = widget, label = frame.label, height = rowHeight, rowHeight = rowHeight,
		place = PlaceRow, align = row.align, body = self,
	}
	if row.type == 'description' then
		-- With fill (SaftUI's), a fill row at its own height at least: what it
		-- shows sits in the middle of the height it's given (its SetHeight).
		-- A fill row is the whole line; any other is inside the padding.
		local fill = OM.Member(self.root, row, 'fill')
		widget:SetWidth(fill and self.width or inside)
		cell.height = max(rowHeight, ceil(widget:GetHeight()) + 12)
		if fill then cell.fill, cell.pad = true, 12 end
	elseif row.type == 'multiselect' then
		cell.height = max(rowHeight, ceil(widget:GetHeight()) + 12)
	elseif row.type == 'position' then
		cell.height = ceil(widget:GetHeight()) + 12
		-- A shareable block's parts bring its title's hover line too.
		widget.onTip = function(on)
			if on then
				ShowTip(frame)
				if OB.ShareEnter then OB.ShareEnter(frame) end
			else
				HideTip(frame)
			end
		end
	elseif row.type == 'execute' then
		-- A button has no label for the mouse to rest on, so it shows the
		-- row's tooltip itself, as the position block does, owned by the
		-- button so it opens over the button, not the row's corner.
		widget.onTip = function(on)
			if on then ShowTip(frame, widget.frame) else HideTip(frame, widget.frame) end
		end
	elseif bare then
		-- The width first: a bare widget's height can follow it.
		local least = FillMin(row.type)
		if widget.SetWidth then widget:SetWidth(least and self.width or inside) end
		local pad = IsTitled(row.type) and BARE_TITLE + 6 or 12
		if least then
			-- Its least for now: DrawSections gives it what the view leaves.
			cell.fill, cell.pad, cell.height = true, pad, ceil(least) + pad
		else
			cell.height = ceil(widget:GetHeight()) + pad
		end
	end
	self.cells[#self.cells + 1] = cell
	return cell
end

-- A search result: a button with the row's name.
function Body:ResultCell(row, onPick)
	local button = Acquire(self.pools.result)
	button.row, button.onPick = row, onPick
	button.text:SetText(row.name)
	local cell = {
		row = row, frame = button, label = button.text, height = self.metrics.rowHeight, rowHeight = self.metrics.rowHeight,
		place = PlaceResult,
	}
	self.cells[#self.cells + 1] = cell
	return cell
end

-- Draws sections of rows with makeCell (rows it draws nothing for are left
-- out, and so are sections left empty), with OB.Dividers' lines between
-- their cells. sizeOf(row) overrides the rows' sizes in the layout. A cell's
-- align (an option row's; a search result has none) lines its button up
-- with the others of its group (OB.ButtonRow, at the button's width). Fill
-- rows share what fillHeight (the view's height) leaves, in whole units, the
-- first taking any remainder. Returns the height drawn.
function Body:DrawSections(sections, makeCell, sizeOf, fillHeight)
	local byRow, kept, fills = {}, {}, {}
	for _, section in ipairs(sections) do
		local rows = {}
		for _, row in ipairs(section.rows) do
			local cell = makeCell(row)
			if cell then
				byRow[row] = cell
				rows[#rows + 1] = row
				if cell.fill then fills[#fills + 1] = cell end
			end
		end
		if #rows > 0 then
			kept[#kept + 1] = { title = section.title, note = section.note, rows = rows, shareRow = section.shareRow }
		end
	end
	local function heightOf(row) return byRow[row].height end
	local function alignOf(row) return byRow[row].align end
	local laid, height = OB.LayoutSections(kept, heightOf, sizeOf, alignOf, self.metrics.panels)
	local extra = fillHeight and #fills > 0 and floor(fillHeight - height) or 0
	if extra > 0 then
		local share = floor(extra / #fills)
		for i, cell in ipairs(fills) do
			cell.height = cell.height + share + (i == 1 and extra - share * #fills or 0)
		end
		laid, height = OB.LayoutSections(kept, heightOf, sizeOf, alignOf, self.metrics.panels)
	end
	-- A group of buttons' x, by its buttons' widths: { xs, left }, once a draw.
	local buttonsAt = {}
	local function ButtonsAt(group)
		if not buttonsAt[group] then
			local widths = {}
			for i, row in ipairs(group.rows) do widths[i] = byRow[row].widget:GetWidth() end
			-- Inside the padding: the line of buttons lies in the cell, then moves by it.
			local pad = self.metrics.pad
			local xs, left = OB.ButtonRow(widths, group.align, self.width - 2 * pad)
			for i in ipairs(xs) do xs[i] = xs[i] + pad end
			buttonsAt[group] = { xs = xs, left = left + pad }
		end
		return buttonsAt[group]
	end
	for _, cell in ipairs(fills) do
		if cell.widget.SetHeight then cell.widget:SetHeight(cell.height - cell.pad) end
	end
	self.filled = #fills > 0
	local pools, content, metrics = self.pools, self.content, self.metrics
	-- No line between sections: the panels part them (and Blizzard never drew
	-- one); the gap for it stays (entry.lineY). Under panels a panel covers each
	-- run of lines that hold no fill cell, across the sections that join one
	-- another; a hairline is at the top of each line in a run but its first.
	-- A line with a fill cell is bare: that row is the whole line, and ends a run.
	local hairlineAt = {} -- the y (in the content) of each hairline
	if metrics.panels then
		local run, runs = nil, {}
		for _, entry in ipairs(laid) do
			if not entry.joins then run = nil end
			local fillAt, tops = {}, {}
			for _, p in ipairs(entry.placed) do
				if fillAt[p.y] == nil then
					fillAt[p.y] = false
					tops[#tops + 1] = p.y
				end
				if byRow[p.row].fill then fillAt[p.y] = true end
			end
			table.sort(tops)
			for i, y in ipairs(tops) do
				local top = entry.rowsY + y
				local bottom = entry.rowsY + (tops[i + 1] or entry.rowsHeight)
				if fillAt[y] then
					run = nil
				elseif run then
					run.height = bottom - run.top
					hairlineAt[top] = true
					local hairline = Acquire(pools.hairline)
					hairline:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -top)
					hairline:SetSize(self.width, 1)
				else
					run = { top = top, height = bottom - top }
					runs[#runs + 1] = run
				end
			end
		end
		for _, each in ipairs(runs) do
			local panel = Acquire(pools.panel)
			panel:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -each.top)
			panel:SetSize(self.width, each.height)
		end
	end
	for _, entry in ipairs(laid) do
		local title
		if entry.titleY then
			title = Acquire(pools.title)
			title:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.titleY)
			title:SetText(entry.section.title)
			title:SetTextColor(Grey()) -- a pooled title may last have been marked
		end
		if entry.noteY then
			local note = Acquire(pools.note)
			note:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.noteY)
			note:SetText(entry.section.note)
		end
		for _, p in ipairs(entry.placed) do
			local cell = byRow[p.row]
			cell.y = entry.rowsY + p.y
			local x, cellWidth
			if p.col == 'buttons' then
				x, cellWidth = ButtonsAt(p.group).xs[p.index], cell.widget:GetWidth()
			elseif cell.fill then
				x, cellWidth = self:SlotRect(p.col, p.quarter) -- the whole line, padding or not
			else
				x, cellWidth = self:CellRect(p.col, p.quarter)
				-- A wide row with buttons at its line's right end stops short of them.
				if p.buttons then cellWidth = max(1, ButtonsAt(p.buttons).left - STOP_GAP - x) end
			end
			cell.place(cell, x, cell.y, cellWidth)
		end
		-- Under panels the last line's divider runs through a lone left half too.
		for _, d in ipairs(OB.Dividers(entry.placed, heightOf, metrics.panels)) do
			local x
			-- In the middle of the gap the line divides; with no gap, on the
			-- boundary. The slots', not the padded cells'.
			if d.at == 'half' then
				x = self.width / 2
			else
				x = self:SlotRect(d.col) + self.columnWidth / 2
			end
			-- Under panels a divider is as faint as a hairline, and part of them;
			-- it starts under the hairline at the top of its line, which has the
			-- pixel already.
			local top, lineHeight = entry.rowsY + d.y, d.height
			if hairlineAt[top] then top, lineHeight = top + 1, lineHeight - 1 end
			local line = Acquire(metrics.panels and pools.hairline or pools.line)
			line:SetPoint('TOPLEFT', content, 'TOPLEFT', floor(x), -top)
			line:SetSize(1, lineHeight)
		end
		-- A shareable position block's marks on its title, once the block is placed.
		if title and entry.section.shareRow and OB.PlaceShareTitle then
			OB.PlaceShareTitle(self, entry, title)
		end
	end
	return #kept > 0 and height or 0
end

function Body:Draw(sections, fillHeight)
	self:UseMetrics()
	return self:DrawSections(sections, function(row) return self:RowCell(row) end, nil, fillHeight)
end

function Body:DrawResults(sections, onPick)
	self:UseMetrics()
	-- A result is a half, whatever size its setting is.
	return self:DrawSections(sections, function(row) return self:ResultCell(row, onPick) end,
		function() return 'normal' end)
end

-- While a slider is dragged the window can't draw the page again (that would
-- take the slider out from under the mouse), so the other rows follow the
-- drag in place: each widget but except (the dragged one, whose own commit
-- has refreshed it) reads its value again, a description its image too, and
-- whether it's disabled, which greys its label as the next Draw would.
-- Nothing is released or laid out again: rows that would show, hide or
-- change height wait for the Draw after the drag.
function Body:Refresh(except)
	for _, cell in ipairs(self.cells) do
		local widget = cell.widget
		if widget and widget ~= except then
			local disabled = OM.IsDisabled(self.root, cell.row)
			if disabled ~= widget:IsDisabled() then
				widget:SetDisabled(disabled)
				if cell.label:IsShown() then
					if disabled then
						cell.label:SetTextColor(Grey())
					elseif cell.ownLabel then -- an own row's (OB.PlaceShare)
						cell.label:SetTextColor(unpack(OB.OWN_TEXT))
					else
						cell.label:SetTextColor(Normal())
					end
				end
			end
			widget:Refresh()
		end
	end
end

function Body:Release()
	for _, cell in ipairs(self.cells) do
		if cell.widget then cell.widget:Release() end
	end
	wipe(self.cells)
	wipe(self.shareTitles)
	self.filled = false
	-- Every pool, optionsshare.lua's title hovers among them.
	for _, pool in pairs(self.pools) do ReleaseAll(pool) end
end
