local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets

--[[
	The body of SaftUI's options window, and of its small dialogs: sections of
	rows drawn into a content frame. The window (optionswindow.lua) and
	OW:OpenDialog each make one.

	  local body = OB.New(content, root, onChanged, width, opts)
	      content     the frame the rows are drawn in (a scroll child, or a
	                  plain frame: an item's menu's)
	      root        the option tree the rows' widgets read and set
	      onChanged   the widgets' onChanged(ok, err, isDragging)
	      width       the content's width (OB.WIDTH, the window's, when nil)
	      opts        nil, or { oneColumn = true }: every row of the body is
	                  laid out as wide, one to a line (an item's menu,
	                  optionsmenu.lua); body.oneColumn
	  body:SetRoot(root)               a new tree (a profile change rebuilt it)
	  body:SetWidth(width, half)       the body's width, and whether it is the
	                                   window's half (body.half): every row is
	                                   read one size larger (OB.HalfSize), so
	                                   the page is one column. Takes effect at
	                                   the next Draw; cancels an open color
	                                   picker of the body when it changes
	  body:Draw(sections, fillHeight) -> height
	                                   option rows, each with its widget;
	                                   fillHeight is the view's height, which
	                                   fill rows stretch the drawn height to
	                                   (body.filled: one was drawn); the
	                                   height ends OB.BOTTOM (24) under the
	                                   last row
	  body:DrawResults(sections, onPick) -> height
	                                   search results: a button per row,
	                                   onPick(row) on a click
	  body:Release()                   everything drawn goes back to its pool
	  body:Refresh(except)             every drawn widget but except shows its
	                                   row again in place (a drag, below)
	  body.cells                       the drawn rows, in order:
	                                   { row, frame, widget, label, height, y,
	                                     x, body, labelX, lineEnd }; labelX
	                                   (nil: 0) is how far in the label
	                                   starts, for a row type whose label
	                                   comes after something of its own (the
	                                   widget's labelX, read once it's bound:
	                                   an item's), lineEnd (nil: the cell's
	                                   width) where its hover line must end
	                                   (optionsshare.lua), from the cell's left
	  widget.rowBody                   every drawn widget's body, the one its
	                                   row is drawn in (cleared when it's
	                                   released; not widget.body, which the
	                                   bags' Categories tab keeps its editor's
	                                   own body in)
	  body.shareTitles                 the section titles drawn with a
	                                   shareable block's marks (optionsshare.lua)
	  body.endsFloating                the last drawn line is a line of
	                                   buttons off the panel (under panels):
	                                   what holds the body ends OB.FLOAT_GAP
	                                   under it, as far as it is under the
	                                   rows (an item's menu)

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
	whole line, and ends a panel; the section's other lines have theirs. A
	line of execute rows alone, wherever it is in its section (so also one
	that continues a section after an inline group), floats off the panel
	instead, on the body's own fill, as tall as its buttons, each in its
	slot off the padding (a centred group across the body, a right one
	ending at its right edge, a lone small one at its quarter's left, in
	line with the panel's edge; buttons that share the line in its halves
	or quarters each fill their slot, the slots 12 apart, so they're an
	even row across the body and the line under them lines up:
	Body:ButtonSlotRect), with no panel, hairline or divider. The gaps: a
	panel ends OB.FLOAT_GAP (24, the body's bottom margin) above it, and the
	rows after it start a panel of their own as far under it, so a line of
	buttons between two runs of rows has the same space above and below;
	lines of buttons after each other are 12 apart (as their buttons were on
	a panel), but the section's last line, its closing buttons, sits 24
	under whatever is above it, midway between the rows and the bottom; a
	section that starts with one sits 6 down, where its buttons would on a
	panel (24 when it joins the panel above). A button beside a row stays on
	the panel with it. Blizzard's layout has no panels, so nothing floats
	there.
	Buttons with an align (row.align, the model's) that follow each other
	are a line of buttons instead, side by side at their own widths, 12
	apart, with no dividers: centred ones on a line of their own, in its
	middle, and right ones at the line's right end, on the line of a wide
	row just before them, one wide of its own (row.size: not one a sizeOf
	made wide, a half body's or an item menu's), whose cell then ends 24 before the buttons, so its
	label and control take the rest), else on a line of their own, all
	inside the padding.
	A toggle's check box and a color's field sit at their cell's right edge,
	the label taking the rest; a small input's box is 60 wide. An item
	(optionsitem.lua) is given its cell's width and spans it, as tall as the
	row (its box and dots centred on it), its Show box at the cell's left
	and its dots at the right; its label starts its labelX in (26 after a
	box, else 0), centred on the row, and ends 6 before the dots, and so
	does its hover line (lineEnd; an item with no menu has no dots, and
	both end at the cell's right edge); its label is Muted while its Show is
	off or it's disabled (OB.LabelColor, which a drag's Refresh reads too,
	so a row a drag enables stays Muted while its Show is off). Under its own mark the box
	moves markShift right with the label (under Blizzard 6). A position block
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
	which loads right after this file, and so is a setting's own reset (its
	default field: OB.PlaceDefault, which PlaceRow runs before
	OB.PlaceShare, and Refresh again for a row with one, so the icon follows
	a drag, then OB.FollowShare, so the row's label, diff icon and hover line
	follow the icon). The share hooks in at three places: PlaceRow
	ends with OB.PlaceShare(cell) (cell.body is the body), the row frame's
	OnEnter and a position block's parts call OB.ShareEnter(frame), and
	DrawSections calls OB.PlaceShareTitle(body, entry, title) for a section
	with a shareRow (the model's) once its block is placed. A world that
	draws no window may load this file without it, so each is called only
	when it's there. An item is 'row' in OB.SHARE_KINDS: its name is its
	label. The metrics' markX and markShift place the own mark, and
	OB.OWN_STRENGTH (the accent's strength on its labels and titles) and
	OB.DIFF_STRENGTH (Text > Muted's strength on the diff icon) are its colors; OB.PlaceLabel puts a label
	where PlaceRow does, cell.labelX plus x in (PlaceRow's label is labelX
	narrower too).

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
local ITEM_GAP = 6 -- an item's label (and its hover line) ends this far before its dots
local WIDTH = 774 -- the window's body: under Blizzard two columns of 367 with a gap of 40; under Thick and Thin two of 387

-- Sections (OB.LayoutSections).
local BODY_TOP, BODY_BOTTOM = 4, 24
local SECTION_PAD, SECTION_MARGIN = 16, 14
local TITLE_HEIGHT, TITLE_GAP = 15, 6
local NOTE_HEIGHT, NOTE_GAP = 15, 4
local CONTINUE_GAP = 4 -- an untitled section after another: a continuation
-- A section's closing buttons under its panel: as far as the body's (and a
-- dialog's) bottom margin is under them, so they sit midway between the rows
-- and the bottom.
local FLOAT_GAP = BODY_BOTTOM
-- A section that starts with a line of buttons: they sit where they would on
-- a panel (a 38 row's 26 button, 6 down), with no panel above to stand off from.
local LEAD_GAP = TITLE_GAP
-- Between two lines of buttons off the panel: as far apart as the buttons of
-- two lines on it were (38 rows, 26 buttons), and as the buttons of a line.
local FLOAT_LINE_GAP = BUTTON_GAP

OB.ROW_HEIGHT, OB.LABEL_GAP, OB.WIDTH = ROW_HEIGHT, LABEL_GAP, WIDTH

-- The whole units that hold a height read back from the game (GetHeight):
-- the next whole unit up, but a hair either side of a whole number is that
-- number. The game hands a size back from its layout in single precision, a
-- hair off the size it was given (26.000002 for a button set to 26), and a
-- plain ceil made a 26 button's line of buttons 27 tall: the button sat
-- half a unit down it, and a dialog holding it came out an odd height.
-- SaftUI's scale makes a unit a pixel, so a 1px border half a unit off blurs.
local READ_BACK = 0.01 -- far over the game's hair, far under a unit
local function WholeHeight(height)
	return ceil(height - READ_BACK)
end
OB.WholeHeight = WholeHeight
OB.FLOAT_GAP = FLOAT_GAP
OB.BOTTOM = BODY_BOTTOM -- the body's bottom margin, in the height Draw returns (a dialog leaves it off)

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

-- A shared setting's marks (optionsshare.lua): an own row's label and a
-- title, which are the accent at OB.OWN_STRENGTH (an own mark was a lighter
-- blue than the accent before; at 1 it is the accent itself), and the diff
-- icon, which is Text > Muted at OB.DIFF_STRENGTH (it was orange before; at 1
-- it is Muted itself).
OB.OWN_STRENGTH = 1
OB.DIFF_STRENGTH = 1

-- A row's label line: its text sits in a band this tall.
local LABEL_HEIGHT = 16
OB.LABEL_HEIGHT = LABEL_HEIGHT

OB.LINE = { 0.18, 0.18, 0.18, 1 } -- #2e2e2e: the lines between parts

local function Normal() return st:Color('text', 'normal'):GetRGB() end
local function Muted() return st:Color('text', 'muted'):GetRGB() end
local function Accent() return st:Color('accent'):GetRGB() end
OB.Normal, OB.Muted, OB.Accent = Normal, Muted, Accent -- the window's files take them

------------------------------------------------------------------ fonts

-- The window's own font objects: Heading's face and outline for the titles
-- ('heading') and Text's for the rest ('normal'), each at the window's own
-- size. Heading's size is not read: the window lays out its header and its
-- section title lines around these numbers. 'field' is the widgets' (15).
local FONTS = {
	title = { 'heading', 34 }, brand = { 'heading', 26 }, section = { 'heading', 15 }, group = { 'heading', 13 },
	caption = { 'heading', 11 }, tab = { 'normal', 17 }, label = { 'normal', 16 }, small = { 'normal', 13 },
	note = { 'normal', 15 }, -- a section's note; small stays the hover line's 13
	mini = { 'heading', 18 }, -- the name on the options window's bar
}
local fontObjects = {}

local function ApplyFont(key)
	local face, size = FONTS[key][1], FONTS[key][2]
	local path, _, flags = st:FontValues(face)
	fontObjects[key]:SetFont(path, size, flags)
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
-- What there is to scroll is counted in whole units too: the game hands a
-- view's height back from its layout in single precision, a hair off the
-- whole height it was laid out to (559.99994 for 560), so content exactly
-- as tall as its view (a dialog sized to its rows, a page whose fill rows
-- take the view's height) would otherwise read as a sliver to scroll and
-- show an idle bar as tall as the view.
function OB.ScrollTo(frame, bar, offset, height, gap)
	local view = frame:GetHeight() or 0
	local range = max(0, floor(height - view + 0.5))
	offset = max(0, min(range, floor(offset + 0.5)))
	frame:SetVerticalScroll(offset)
	local child = frame:GetScrollChild()
	local width = child and child:GetWidth() or frame:GetWidth()
	local companion = companions[bar]
	local blizzard = companion and W.BlizzardLook()
	if companion and not blizzard then companion.bar:Hide() end
	if blizzard then
		bar:Hide()
		-- Its view in whole units as well (what's held less the range), so it
		-- shows by the same rule.
		companion.bar:Set(frame, width + (gap or OB.BLIZZARD_GAP), 0, floor(view + 0.5), height - range, height, offset)
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
				-- Only a row wide of its own: one a sizeOf made wide (a half
				-- body's) keeps the buttons on a line of their own, so its
				-- control isn't cut.
				if align == 'right' and wide and wide.own and SharesLine(wide.entry.row) then
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
			wide, group = { entry = entry, height = height, own = row.size == 'wide' }, nil
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

-- A section's lines float off its panel wherever every row on one gives a
-- height off the panel (floatOf(row); nil: it can't): a line of buttons,
-- anywhere in the section. Its lines are laid down again from the top. A
-- floating line's entries are marked floats and given floatHeight, its
-- tallest row's, as the line is; it sits FLOAT_GAP under a line on the panel,
-- FLOAT_LINE_GAP under another floating line, and at the section's start
-- LEAD_GAP down (FLOAT_GAP when the section joins the panel above,
-- entry.joins). The section's last line, its closing buttons, sits FLOAT_GAP
-- under a floating line too: as far under what's above it as the bottom
-- margin is under it. A line on the panel after a floating one starts
-- FLOAT_GAP under it, so a line of buttons between two runs of panel has the
-- same gap above and below. entry.endsFloating: the section's last line
-- floats. A floating line's buttons that share it in slots (two or more in
-- its halves or quarters, not a group with an align) are marked slotted:
-- each takes its whole slot (Body:ButtonSlotRect). A line of buttons right
-- under a description, but for the section's closing line, doesn't float:
-- it's the description's, and stays on the panel with it.
-- Returns the rows' height (height itself when no line floats).
local function Float(entry, placed, height, floatOf)
	local lines, byY, any = {}, {}, false
	for _, p in ipairs(placed) do
		local line = byY[p.y]
		if not line then
			line = { y = p.y, entries = {}, floats = true, floatHeight = 0 }
			byY[p.y] = line
			lines[#lines + 1] = line
		end
		line.entries[#line.entries + 1] = p
		local h = floatOf(p.row)
		if h then line.floatHeight = max(line.floatHeight, h) else line.floats = false end
	end
	table.sort(lines, function(a, b) return a.y < b.y end)
	-- A line of buttons right under a description, mid-section, is that
	-- description's (the Profiles page's Reset Profile under the text that
	-- explains it): it stays on the panel with it. The section's closing
	-- line still floats: those buttons are the section's (the bags'
	-- Miscellaneous editor's Reset under its note).
	for i = 2, #lines - 1 do
		for _, p in ipairs(lines[i - 1].entries) do
			if p.row.type == 'description' then lines[i].floats = false end
		end
	end
	for _, line in ipairs(lines) do any = any or line.floats end
	if not any then return height end
	local y, above = 0, nil -- above: 'panel' or 'float', the line before
	for i, line in ipairs(lines) do
		if line.floats then
			if above == 'panel' then
				y = y + FLOAT_GAP
			elseif above == 'float' then
				y = y + (i == #lines and FLOAT_GAP or FLOAT_LINE_GAP)
			else
				y = y + (entry.joins and FLOAT_GAP or LEAD_GAP)
			end
			local inSlots = 0
			for _, p in ipairs(line.entries) do
				if p.col == 1 or p.col == 2 then inSlots = inSlots + 1 end
			end
			for _, p in ipairs(line.entries) do
				p.y, p.floats, p.floatHeight = y, true, line.floatHeight
				p.slotted = inSlots > 1 and (p.col == 1 or p.col == 2) or nil
			end
			y = y + line.floatHeight
			above = 'float'
		else
			if above == 'float' then y = y + FLOAT_GAP end
			for _, p in ipairs(line.entries) do p.y = y end
			-- As tall on the panel as it was laid out.
			y = y + (lines[i + 1] and lines[i + 1].y or height) - line.y
			above = 'panel'
		end
	end
	entry.endsFloating = above == 'float'
	return y
end

-- Places sections down the body: { {section, lineY, titleY, noteY, rowsY,
-- rowsHeight, joins, placed, endsFloating} } and the body's
-- height (BODY_BOTTOM, OB.BOTTOM, under the last rows). The space for a line
-- between sections after the first is kept (lineY) though none is drawn any
-- more; an untitled one (rows that follow a nested group) keeps none, so it
-- reads as a continuation of the one above: CONTINUE_GAP below it, or with
-- panels (the fifth argument) none at all, and joins = true, for it to share
-- the panel above. With panels and floatOf (the sixth, see Float) a
-- section's lines of rows that float (lines of buttons) sit off its panel,
-- FLOAT_GAP from it; a continuation after a section that ends with one has
-- no panel to join, so it starts its own FLOAT_GAP under the line. heightOf,
-- sizeOf and alignOf are OB.LayoutRows'. noteHeightOf(section) (the seventh)
-- is the height of a section's note, NOTE_HEIGHT without it: a note that
-- wraps (a narrow body's) is as tall as its lines.
function OB.LayoutSections(sections, heightOf, sizeOf, alignOf, panels, floatOf, noteHeightOf)
	local laid, y = {}, BODY_TOP
	for i, section in ipairs(sections) do
		local entry = { section = section }
		local after = laid[#laid] -- the section above
		if i == 1 then
			y = y + SECTION_PAD
		elseif section.title then
			y = y + SECTION_MARGIN
			entry.lineY = y
			y = y + 1 + SECTION_PAD
		elseif panels and after.endsFloating then
			y = y + FLOAT_GAP
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
			y = y + (noteHeightOf and noteHeightOf(section) or NOTE_HEIGHT) + NOTE_GAP
		end
		entry.rowsY = y
		local placed, height = OB.LayoutRows(section.rows, heightOf, sizeOf, alignOf)
		if panels and floatOf then height = Float(entry, placed, height, floatOf) end
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

-- OB.Dividers of each run of a section's lines on the panel (parts: lists of
-- placed entries, a floating line between each), all together: each run's
-- last line is a last line, extended with extendLast.
function OB.DividersOf(parts, heightOf, extendLast)
	local all = {}
	for _, part in ipairs(parts) do
		for _, d in ipairs(OB.Dividers(part, heightOf, extendLast)) do all[#all + 1] = d end
	end
	return all
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
-- (row.disabledDesc, the model's), in Text > Danger. Of frame's row, owned by
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
		local r, g, b = st:Color('text', 'danger'):GetRGB()
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

-- Where a row's label sits, cell.labelX (0 when nil: a row type whose label
-- comes after something of its own sets it) plus x in from its cell's left:
-- across the row's middle, or in a tall row (a multiselect's) across its
-- first rowHeight. optionsshare.lua moves it (a mark's shift) and puts it
-- back with this.
function OB.PlaceLabel(cell, x)
	local label, frame = cell.label, cell.frame
	x = (cell.labelX or 0) + (x or 0)
	label:ClearAllPoints()
	if cell.height > cell.rowHeight then
		label:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -floor((cell.rowHeight - LABEL_HEIGHT) / 2))
	else
		label:SetPoint('LEFT', frame, 'LEFT', x, 0)
	end
end

-- A row's label color (r, g, b, a): Muted while it's disabled; an own row's
-- accent at OB.OWN_STRENGTH (cell.ownLabel, optionsshare.lua); an item's Muted
-- while its Show is off (widget.value false); else the text color. PlaceRow
-- and a drag's Refresh both read it.
function OB.LabelColor(cell, disabled)
	if disabled then return Muted() end
	if cell.ownLabel then return st:ColorRGBA('accent', nil, OB.OWN_STRENGTH) end
	if cell.row.type == 'item' and cell.widget and cell.widget.value == false then return Muted() end
	return Normal()
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
		-- In the middle of the row, by its top: half the room above it, rounded
		-- down, so a button shorter than its line by an odd amount stays on
		-- whole units (a floating line is its tallest button's height).
		local room = cell.height - WholeHeight(widget:GetHeight())
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -floor(room / 2))
	elseif row.type == 'position' then
		label:Hide()
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -6)
	elseif IsTitled(row.type) then
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Muted()) else label:SetTextColor(Normal()) end
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
	elseif row.type == 'item' then
		-- The widget spans the cell: its box at the left, its dots at the right.
		widget:SetWidth(width)
		widget.frame:SetHeight(cell.height)
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
		label:SetText(row.name)
		label:SetTextColor(OB.LabelColor(cell, row.disabled))
		label:Show()
		-- After the box (cell.labelX), ending short of the dots (an item with
		-- no menu has none: at the cell's right edge); the hover line too.
		local stop = widget.hasMenu and width - widget.dots:GetWidth() - ITEM_GAP or width
		label:SetWidth(max(1, stop - (cell.labelX or 0)))
		cell.lineEnd = stop
		OB.PlaceLabel(cell, 0)
	else
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Muted()) else label:SetTextColor(Normal()) end
		label:Show()
		label:SetWidth(max(1, width - (cell.labelX or 0) - widget:GetWidth() - LABEL_GAP))
		OB.PlaceLabel(cell, 0)
		if cell.height > cell.rowHeight then
			widget:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, -6)
		else
			widget:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
		end
	end
	-- The label's and the hover line's own ends: a setting's own reset cuts
	-- them while its icon shows and gives them back when it goes, mid-drag
	-- too (OB.PlaceDefault).
	cell.labelWidth = label:IsShown() and label:GetWidth() or nil
	cell.ownLineEnd = cell.lineEnd
	-- A setting's own reset by its control (its default), then a shareable
	-- row's marks: optionsshare.lua.
	if OB.PlaceDefault then OB.PlaceDefault(cell) end
	if OB.PlaceShare then OB.PlaceShare(cell) end
	-- An item's box moves under its own mark with the label (markShift).
	if row.type == 'item' then
		local state = frame.shareState
		widget:ShiftBox(state and state.marked and cell.body and cell.body.metrics.markShift or 0)
	end
end

local function PlaceResult(cell, x, y, width)
	cell.frame:SetPoint('TOPLEFT', cell.frame:GetParent(), 'TOPLEFT', x, -y)
	cell.frame:SetSize(width, cell.height)
	cell.label:SetWidth(width - 16)
end

------------------------------------------------------------------ the body

local Body = {}
Body.__index = Body

function OB.New(content, root, onChanged, width, opts)
	local body = setmetatable({
		content = content, root = root, onChanged = onChanged,
		width = width or WIDTH, cells = {},
		oneColumn = opts and opts.oneColumn and true or nil, -- every row wide (an item's menu)
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
				self.hover:SetColorTexture(st:ColorRGBA('accent', nil, st.TINT_ROW))
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
			title:SetTextColor(Muted())
			title:SetWidth(body.width)
			return title
		end),
		note = Pool(function()
			local note = Text(content, 'note')
			note:SetWordWrap(true) -- one that doesn't fit the body wraps (Body:NoteHeight)
			note:SetJustifyV('TOP')
			note:SetTextColor(Muted())
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
	-- At half the two columns are the quarters of the body at its full width:
	-- only the gap a quarter has between them (OB.PANELED's 0, OB.FLAT's 24).
	self.columnWidth = floor((self.width - (self.half and metrics.quarterGap or metrics.columnGap)) / 2)
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

-- Where a floating button that shares its line takes its slot (slotted,
-- OB.LayoutSections): the line's halves and quarters as SlotRect lays them
-- out, but BUTTON_GAP (12) apart, as two lines of buttons are, so the
-- buttons of a line are an even row across the body and those of the line
-- under them line up with them. Whole units as SlotRect: halves and quarters
-- round down, the second of each pair flush with the outer edge (a 520
-- dialog's quarters are 121 wide, at 0, 133, 266 and 399).
function Body:ButtonSlotRect(col, quarter)
	local half = floor((self.width - BUTTON_GAP) / 2)
	local x = col == 2 and (self.width - half) or 0
	if not quarter then return x, half end
	local width = floor((half - BUTTON_GAP) / 2)
	if quarter == 2 then x = x + half - width end
	return x, width
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

-- The body's width, and whether it is the window's half (body.half: every row
-- is read one size larger, OB.HalfSize, so the page is one column). It takes
-- effect at the next Draw, which the caller makes after releasing the body;
-- the pooled titles and notes, used or free, take the width now. A color
-- picker open from a row of this body is cancelled first when either changes
-- (a draw at another width would rebind its field under it).
function Body:SetWidth(width, half)
	half = half and true or false
	if width ~= self.width or half ~= (self.half or false) then
		if W.CloseColorPicker then W.CloseColorPicker(self.content) end
	end
	self.width, self.half = width, half
	for _, pool in ipairs({ self.pools.title, self.pools.note }) do
		for _, list in ipairs({ pool.used, pool.free }) do
			for _, fs in ipairs(list) do fs:SetWidth(width) end
		end
	end
end

-- A section's note's height: NOTE_HEIGHT, a line, when it fits the body's
-- width on one, else the height of its lines wrapped to that width, in whole
-- units (never less than a line). Measured on a font string of its own, the
-- notes' font, so what a note drawn later takes is what the layout held for it.
function Body:NoteHeight(section)
	local measure = self.measure
	if not measure then
		measure = Text(self.content, 'note')
		measure:SetWordWrap(true)
		measure:SetJustifyV('TOP')
		measure:Hide()
		self.measure = measure
	end
	measure:SetWidth(self.width)
	measure:SetText(section.note)
	if ceil(measure:GetUnboundedStringWidth()) <= self.width then return NOTE_HEIGHT end
	return max(NOTE_HEIGHT, WholeHeight(measure:GetStringHeight()))
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
	widget.rowBody = self -- cleared by its Release
	if row.type == 'input' then -- a reused box is sized again: small or not
		widget.width = row.size == 'small' and SMALL_INPUT_WIDTH or W.WIDTH.input
		widget.frame:SetWidth(widget.width)
	end
	local rowHeight, inside = self.metrics.rowHeight, self.width - 2 * self.metrics.pad
	local cell = {
		row = row, frame = frame, widget = widget, label = frame.label, height = rowHeight, rowHeight = rowHeight,
		place = PlaceRow, align = row.align, body = self,
		labelX = widget.labelX, -- an item's: its label after its box
	}
	if row.type == 'description' then
		-- With fill (SaftUI's), a fill row at its own height at least: what it
		-- shows sits in the middle of the height it's given (its SetHeight).
		-- A fill row is the whole line; any other is inside the padding.
		local fill = OM.Member(self.root, row, 'fill')
		widget:SetWidth(fill and self.width or inside)
		cell.height = max(rowHeight, WholeHeight(widget:GetHeight()) + 12)
		if fill then cell.fill, cell.pad = true, 12 end
	elseif row.type == 'multiselect' then
		cell.height = max(rowHeight, WholeHeight(widget:GetHeight()) + 12)
	elseif row.type == 'position' then
		cell.height = WholeHeight(widget:GetHeight()) + 12
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
			cell.height = WholeHeight(widget:GetHeight()) + pad
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
	-- Under panels a section's closing line of buttons floats under its panel
	-- (OB.LayoutSections): an execute row's button, at its own height in whole
	-- units (WholeHeight: the game reads a 26 button back a hair over 26). A
	-- search result never does.
	local function floatOf(row)
		local cell = byRow[row]
		if cell.widget and row.type == 'execute' then return WholeHeight(cell.widget:GetHeight()) end
	end
	local panels = self.metrics.panels
	local function noteHeightOf(section) return self:NoteHeight(section) end
	local laid, height = OB.LayoutSections(kept, heightOf, sizeOf, alignOf, panels, floatOf, noteHeightOf)
	local extra = fillHeight and #fills > 0 and floor(fillHeight - height) or 0
	if extra > 0 then
		local share = floor(extra / #fills)
		for i, cell in ipairs(fills) do
			cell.height = cell.height + share + (i == 1 and extra - share * #fills or 0)
		end
		laid, height = OB.LayoutSections(kept, heightOf, sizeOf, alignOf, panels, floatOf, noteHeightOf)
	end
	-- A group of buttons' x, by its buttons' widths: { xs, left }, once a draw.
	-- A floating group lies across the body's whole width, off the panel.
	local buttonsAt = {}
	local function ButtonsAt(group, floats)
		if not buttonsAt[group] then
			local widths = {}
			for i, row in ipairs(group.rows) do widths[i] = byRow[row].widget:GetWidth() end
			-- Inside the padding: the line of buttons lies in the cell, then moves by it.
			local pad = floats and 0 or self.metrics.pad
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
	self.endsFloating = laid[#laid] ~= nil and laid[#laid].endsFloating or false
	local pools, content, metrics = self.pools, self.content, self.metrics
	-- No line between sections: the panels part them (and Blizzard never drew
	-- one); the gap for it stays (entry.lineY). Under panels a panel covers each
	-- run of lines that hold no fill cell, across the sections that join one
	-- another; a hairline is at the top of each line in a run but its first.
	-- A line with a fill cell is bare: that row is the whole line, and ends a run.
	-- A floating line of buttons is off the panel: a run ends above it, and the
	-- lines after it start one of their own.
	local hairlineAt = {} -- the y (in the content) of each hairline
	if metrics.panels then
		local run, runs = nil, {}
		for _, entry in ipairs(laid) do
			if not entry.joins then run = nil end
			-- The lines on the panel, by their tops: each as tall as its
			-- tallest row, and whether it holds a fill cell.
			local lines, tops = {}, {}
			for _, p in ipairs(entry.placed) do
				if not p.floats then
					local line = lines[p.y]
					if not line then
						line = { height = 0, fill = false }
						lines[p.y] = line
						tops[#tops + 1] = p.y
					end
					line.height = max(line.height, heightOf(p.row))
					if byRow[p.row].fill then line.fill = true end
				end
			end
			table.sort(tops)
			for _, y in ipairs(tops) do
				local top = entry.rowsY + y
				local bottom = top + lines[y].height
				if lines[y].fill then
					run = nil
				elseif run and run.top + run.height == top then
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
			title:SetTextColor(Muted()) -- a pooled title may last have been marked
		end
		if entry.noteY then
			local note = Acquire(pools.note)
			note:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.noteY)
			note:SetText(entry.section.note)
			note:SetTextColor(Muted()) -- a pooled note takes a changed Muted at the next draw
		end
		-- The rows on the panel, in runs a floating line parts.
		local onPanel, parts = nil, {}
		for _, p in ipairs(entry.placed) do
			local cell = byRow[p.row]
			cell.y = entry.rowsY + p.y
			-- Where its section's title starts, for the first row of a titled
			-- section (a reveal scrolls the title into view too).
			cell.sectionY = (entry.titleY and p.y == entry.placed[1].y) and entry.titleY or nil
			if p.floats then
				cell.height = p.floatHeight -- as tall as its line's buttons, which fill it
				onPanel = nil
			else
				if not onPanel then
					onPanel = {}
					parts[#parts + 1] = onPanel
				end
				onPanel[#onPanel + 1] = p
			end
			local x, cellWidth
			if p.col == 'buttons' then
				x, cellWidth = ButtonsAt(p.group, p.floats).xs[p.index], cell.widget:GetWidth()
			elseif p.slotted then
				-- A floating button sharing its line: its whole slot, 12 from the next.
				x, cellWidth = self:ButtonSlotRect(p.col, p.quarter)
				cell.widget:SetWidth(cellWidth)
			elseif cell.fill or p.floats then
				-- The whole line, padding or not; a floating button its slot, off the panel.
				x, cellWidth = self:SlotRect(p.col, p.quarter)
			else
				x, cellWidth = self:CellRect(p.col, p.quarter)
				-- A wide row with buttons at its line's right end stops short of them.
				if p.buttons then cellWidth = max(1, ButtonsAt(p.buttons).left - STOP_GAP - x) end
			end
			cell.place(cell, x, cell.y, cellWidth)
		end
		-- Under panels a run's last line's divider runs through a lone left half
		-- too (the panel's last: a floating line has none).
		for _, d in ipairs(OB.DividersOf(parts, heightOf, metrics.panels)) do
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

-- A oneColumn body's rows are all wide.
local function Wide() return 'wide' end

-- A row's size at half: one larger. A quarter takes half of the narrow body,
-- a half the whole line, and a wide row stays.
function OB.HalfSize(row)
	if row.size == 'small' then return 'normal' end
	return 'wide'
end

function Body:Draw(sections, fillHeight)
	self:UseMetrics()
	local sizeOf = self.oneColumn and Wide or self.half and OB.HalfSize or nil
	return self:DrawSections(sections, function(row) return self:RowCell(row) end, sizeOf, fillHeight)
end

local function Half() return 'normal' end

function Body:DrawResults(sections, onPick)
	self:UseMetrics()
	-- A result is a half, whatever size its setting is; at half the body is
	-- narrower than a half row's name, so one to a line.
	return self:DrawSections(sections, function(row) return self:ResultCell(row, onPick) end,
		self.half and Wide or Half)
end

-- While a slider is dragged the window can't draw the page again (that would
-- take the slider out from under the mouse), so the other rows follow the
-- drag in place: each widget but except (the dragged one, whose own commit
-- has refreshed it) reads its value again, a description its image too, and
-- whether it's disabled, which colors its label as the next Draw would
-- (OB.LabelColor; an item's also when its Show changed). Nothing is
-- released or laid out again: rows that would show, hide or change height
-- wait for the Draw after the drag.
function Body:Refresh(except)
	for _, cell in ipairs(self.cells) do
		local widget = cell.widget
		if widget and widget ~= except then
			local disabled = OM.IsDisabled(self.root, cell.row)
			local flipped, was = disabled ~= widget:IsDisabled(), widget.value
			if flipped then widget:SetDisabled(disabled) end
			widget:Refresh()
			if (flipped or (cell.row.type == 'item' and widget.value ~= was)) and cell.label:IsShown() then
				cell.label:SetTextColor(OB.LabelColor(cell, disabled))
			end
		end
		-- A setting's own reset follows the drag (the dragged row's too), and
		-- the row's diff icon and hover line follow the room it takes or gives.
		-- (every row with a value: PlaceDefault asks whether it differs by its
		-- source, a hand default's, a mover's or a derived one, and leaves the
		-- rest alone.)
		if widget and OB.PlaceDefault then
			OB.PlaceDefault(cell)
			if OB.FollowShare then OB.FollowShare(cell) end
		end
	end
end

function Body:Release()
	for _, cell in ipairs(self.cells) do
		if cell.widget then cell.widget:Release() end
	end
	wipe(self.cells)
	wipe(self.shareTitles)
	self.filled, self.endsFloating = false, false
	-- Every pool, optionsshare.lua's title hovers among them.
	for _, pool in pairs(self.pools) do ReleaseAll(pool) end
end
