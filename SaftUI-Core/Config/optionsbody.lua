local st = SaftUI
local W = st.OptionsWidgets

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
	  body:Draw(sections)  -> height   option rows, each with its widget
	  body:DrawResults(sections, onPick) -> height
	                                   search results: a button per row,
	                                   onPick(row) on a click
	  body:Release()                   everything drawn goes back to its pool
	  body.cells                       the drawn rows, in order:
	                                   { row, frame, widget, label, height, y }

	sections are the model's ({ title, note, rows }, OM.BuildView). Rows no
	widget draws are left out, and so are sections left empty; the height is
	0 when nothing is drawn. Sections are laid out by OB.LayoutSections, their
	rows by OB.LayoutRows, both pure: a row is small (a quarter of the line;
	two make a half), normal (a half) or wide (the whole line), by row.size.
	A toggle's check box and a color's swatch sit just after their label's
	text; a small input's box is OB.SMALL_INPUT_WIDTH wide. A position block
	has no label (its section is titled Position), is as tall as the widget
	plus 12, and shows the row's desc when the mouse is anywhere on it.

	The window's fonts live here too (OB.Font, OB.UpdateFonts), with the small
	pieces both use (OB.Text, OB.Line, the pools), as this file loads first.

	Every frame and texture here is SaftUI's. GameTooltip shows a row's desc
	through its public API.
]]

local OB = {}
st.OptionsBody = OB

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local tremove = table.remove

------------------------------------------------------------------ the mockup's numbers

local ROW_HEIGHT = 34
local LABEL_GAP = 10
local COLUMN_GAP = 40
local QUARTER_GAP = 24 -- between the two quarters of a half
local SMALL_INPUT_WIDTH = 60
local WIDTH = 774 -- the window's body: two columns of 367 with a gap of 40

-- Sections (OB.LayoutSections).
local BODY_TOP, BODY_BOTTOM = 4, 24
local SECTION_PAD, SECTION_MARGIN = 16, 14
local TITLE_HEIGHT, TITLE_GAP = 15, 6
local NOTE_HEIGHT, NOTE_GAP = 13, 4
local CONTINUE_GAP = 4 -- an untitled section after another: a continuation

OB.ROW_HEIGHT, OB.LABEL_GAP, OB.COLUMN_GAP, OB.WIDTH = ROW_HEIGHT, LABEL_GAP, COLUMN_GAP, WIDTH
OB.QUARTER_GAP, OB.SMALL_INPUT_WIDTH = QUARTER_GAP, SMALL_INPUT_WIDTH
OB.TOP = BODY_TOP + SECTION_PAD -- where the first section's rows start

OB.LINE = { 0.18, 0.18, 0.18, 1 } -- #2e2e2e: the lines between parts

local function Colors() return st.config.profile.colors end
local function Normal() return Colors().text.normal:GetRGB() end
local function Grey() return Colors().text.grey:GetRGB() end
local function Blue() return Colors().button.blue:GetRGB() end

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
	fontObjects[key]:SetFont(st.LSM:Fetch('font', config.font_name), size, config.font_outline)
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

------------------------------------------------------------------ the pure layout

-- Places rows on lines of four quarters (two halves). A small row takes the
-- next quarter, a normal row the next whole half (it skips a lone quarter's
-- other half), a wide row a line of its own. A line is as tall as its
-- tallest row (heightOf(row), ROW_HEIGHT without it). sizeOf(row) gives a
-- row's size (row.size without it; no size is normal). Returns { {row,
-- col = 1|2|'full', quarter = 1|2|nil (smalls only), y} } and the height of
-- them all.
function OB.LayoutRows(rows, heightOf, sizeOf)
	local placed, y, cursor, lineHeight = {}, 0, 0, 0 -- cursor: quarters used in the line
	local function NextLine()
		y, cursor, lineHeight = y + lineHeight, 0, 0
	end
	for _, row in ipairs(rows) do
		local height = heightOf and heightOf(row) or ROW_HEIGHT
		local size = (sizeOf and sizeOf(row) or row.size) or 'normal'
		if size == 'wide' then
			if cursor > 0 then NextLine() end
			placed[#placed + 1] = { row = row, col = 'full', y = y }
			lineHeight = height
			NextLine()
		else
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
-- placed} } and the body's height. Sections after the first are separated by
-- a line; an untitled one (rows that follow a nested group) gets none, so it
-- reads as a continuation of the one above.
function OB.LayoutSections(sections, heightOf, sizeOf)
	local laid, y = {}, BODY_TOP
	for i, section in ipairs(sections) do
		local entry = { section = section }
		if i == 1 then
			y = y + SECTION_PAD
		elseif section.title then
			y = y + SECTION_MARGIN
			entry.lineY = y
			y = y + 1 + SECTION_PAD
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
		local placed, height = OB.LayoutRows(section.rows, heightOf, sizeOf)
		entry.placed = placed
		y = y + height
		laid[#laid + 1] = entry
	end
	return laid, y + BODY_BOTTOM
end

------------------------------------------------------------------ rows

local function ShowTip(frame)
	local row = frame.row
	if not (row and row.desc and row.desc ~= '') then return end
	GameTooltip:SetOwner(frame, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(row.name, 1, 1, 1)
	GameTooltip:AddLine(row.desc, nil, nil, nil, true)
	GameTooltip:Show()
end

local function HideTip(frame)
	if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
end

-- A row's place in its cell: the label on the left, the control on the
-- right, except a toggle's check box and a color's swatch, which follow the
-- end of the label's text. A description is text across the row, and a
-- button stands alone.
local function PlaceRow(cell, x, y, width)
	local frame, widget, label, row = cell.frame, cell.widget, cell.label, cell.row
	frame:SetPoint('TOPLEFT', frame:GetParent(), 'TOPLEFT', x, -y)
	frame:SetSize(width, cell.height)
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
	else
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Grey()) else label:SetTextColor(Normal()) end
		label:Show()
		if row.type == 'toggle' or row.type == 'color' then
			label:SetWidth(max(1, min(label:GetStringWidth(), width - widget:GetWidth() - LABEL_GAP)))
			label:SetPoint('LEFT', frame, 'LEFT', 0, 0)
			widget:SetPoint('LEFT', label, 'RIGHT', LABEL_GAP, 0)
			return
		end
		label:SetWidth(max(1, width - widget:GetWidth() - LABEL_GAP))
		if cell.height > ROW_HEIGHT then
			label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -floor((ROW_HEIGHT - 16) / 2))
			widget:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, -6)
		else
			label:SetPoint('LEFT', frame, 'LEFT', 0, 0)
			widget:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
		end
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

function OB.New(content, root, onChanged, width)
	local body = setmetatable({
		content = content, root = root, onChanged = onChanged,
		width = width or WIDTH, cells = {},
	}, Body)
	body.columnWidth = (body.width - COLUMN_GAP) / 2
	body.quarterWidth = (body.columnWidth - QUARTER_GAP) / 2

	body.pools = {
		row = Pool(function()
			local frame = CreateFrame('Frame', nil, content)
			frame:EnableMouse(true)
			frame.label = Text(frame, 'label')
			frame:SetScript('OnEnter', ShowTip)
			frame:SetScript('OnLeave', HideTip)
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

function Body:SetRoot(root)
	self.root = root
end

-- A drawn row of the page: its frame and widget, and its height.
function Body:RowCell(row)
	if not W.WIDTH[row.type] then return nil end -- not a type the widgets draw
	local frame = Acquire(self.pools.row)
	frame.row = row
	local widget = W.Create(frame, row.type)
	widget:Bind(self.root, row, self.onChanged)
	if row.type == 'input' then -- a reused box is sized again: small or not
		widget.width = row.size == 'small' and SMALL_INPUT_WIDTH or W.WIDTH.input
		widget.frame:SetWidth(widget.width)
	end
	local cell = { row = row, frame = frame, widget = widget, label = frame.label, height = ROW_HEIGHT, place = PlaceRow }
	if row.type == 'description' then
		widget:SetWidth(self.width)
		cell.height = max(ROW_HEIGHT, ceil(widget:GetHeight()) + 12)
	elseif row.type == 'multiselect' then
		cell.height = max(ROW_HEIGHT, ceil(widget:GetHeight()) + 12)
	elseif row.type == 'position' then
		cell.height = ceil(widget:GetHeight()) + 12
		widget.onTip = function(on)
			if on then ShowTip(frame) else HideTip(frame) end
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
	local cell = { row = row, frame = button, label = button.text, height = ROW_HEIGHT, place = PlaceResult }
	self.cells[#self.cells + 1] = cell
	return cell
end

-- Draws sections of rows with makeCell (rows it draws nothing for are left
-- out, and so are sections left empty). sizeOf(row) overrides the rows'
-- sizes in the layout. Returns the height drawn.
function Body:DrawSections(sections, makeCell, sizeOf)
	local byRow, kept = {}, {}
	for _, section in ipairs(sections) do
		local rows = {}
		for _, row in ipairs(section.rows) do
			local cell = makeCell(row)
			if cell then
				byRow[row] = cell
				rows[#rows + 1] = row
			end
		end
		if #rows > 0 then kept[#kept + 1] = { title = section.title, note = section.note, rows = rows } end
	end
	local laid, height = OB.LayoutSections(kept, function(row) return byRow[row].height end, sizeOf)
	local pools, content = self.pools, self.content
	for _, entry in ipairs(laid) do
		if entry.lineY then
			local line = Acquire(pools.line)
			line:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.lineY)
			line:SetSize(self.width, 1)
		end
		if entry.titleY then
			local title = Acquire(pools.title)
			title:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.titleY)
			title:SetText(entry.section.title)
		end
		if entry.noteY then
			local note = Acquire(pools.note)
			note:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.noteY)
			note:SetText(entry.section.note)
		end
		for _, p in ipairs(entry.placed) do
			local cell = byRow[p.row]
			cell.y = entry.rowsY + p.y
			local x, cellWidth = 0, self.width
			if p.col ~= 'full' then
				x = p.col == 2 and (self.columnWidth + COLUMN_GAP) or 0
				cellWidth = self.columnWidth
				if p.quarter then
					x = x + (p.quarter - 1) * (self.quarterWidth + QUARTER_GAP)
					cellWidth = self.quarterWidth
				end
			end
			cell.place(cell, x, cell.y, cellWidth)
		end
	end
	return #kept > 0 and height or 0
end

function Body:Draw(sections)
	return self:DrawSections(sections, function(row) return self:RowCell(row) end)
end

function Body:DrawResults(sections, onPick)
	-- A result is a half, whatever size its setting is.
	return self:DrawSections(sections, function(row) return self:ResultCell(row, onPick) end,
		function() return 'normal' end)
end

function Body:Release()
	for _, cell in ipairs(self.cells) do
		if cell.widget then cell.widget:Release() end
	end
	wipe(self.cells)
	for _, key in ipairs({ 'row', 'result', 'title', 'note', 'line' }) do ReleaseAll(self.pools[key]) end
end
