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
	rows in two columns by OB.LayoutRows, both pure.

	The window's fonts live here too (OB.Font, OB.UpdateFonts), with the small
	pieces both use (OB.Text, OB.Line, the pools), as this file loads first.

	Every frame and texture here is SaftUI's. GameTooltip shows a row's desc
	through its public API.
]]

local OB = {}
st.OptionsBody = OB

local floor, max, ceil = math.floor, math.max, math.ceil
local tremove = table.remove

------------------------------------------------------------------ the mockup's numbers

local ROW_HEIGHT = 34
local LABEL_GAP = 10
local COLUMN_GAP = 40
local WIDTH = 774 -- the window's body: two columns of 367 with a gap of 40

-- Sections (OB.LayoutSections).
local BODY_TOP, BODY_BOTTOM = 4, 24
local SECTION_PAD, SECTION_MARGIN = 16, 14
local TITLE_HEIGHT, TITLE_GAP = 15, 6
local NOTE_HEIGHT, NOTE_GAP = 13, 4
local CONTINUE_GAP = 4 -- an untitled section after another: a continuation

OB.ROW_HEIGHT, OB.LABEL_GAP, OB.COLUMN_GAP, OB.WIDTH = ROW_HEIGHT, LABEL_GAP, COLUMN_GAP, WIDTH
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
	tab = { 'normal', 17 }, label = { 'normal', 16 }, small = { 'normal', 13 },
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

-- Places rows in two columns: a normal row takes the next column (1, then 2),
-- a full row a line of its own. A line is as tall as its tallest row
-- (heightOf(row), ROW_HEIGHT without it). Returns { {row, col = 1|2|'full',
-- y} } and the height of them all.
function OB.LayoutRows(rows, heightOf)
	local placed, y, col, lineHeight = {}, 0, 1, 0
	local function NextLine()
		y, col, lineHeight = y + lineHeight, 1, 0
	end
	for _, row in ipairs(rows) do
		local height = heightOf and heightOf(row) or ROW_HEIGHT
		if row.width == 'full' then
			if col == 2 then NextLine() end
			placed[#placed + 1] = { row = row, col = 'full', y = y }
			lineHeight = height
			NextLine()
		else
			placed[#placed + 1] = { row = row, col = col, y = y }
			lineHeight = max(lineHeight, height)
			if col == 1 then col = 2 else NextLine() end
		end
	end
	if col == 2 then NextLine() end
	return placed, y
end

-- Places sections down the body: { {section, lineY, titleY, noteY, rowsY,
-- placed} } and the body's height. Sections after the first are separated by
-- a line; an untitled one (rows that follow a nested group) gets none, so it
-- reads as a continuation of the one above.
function OB.LayoutSections(sections, heightOf)
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
		local placed, height = OB.LayoutRows(section.rows, heightOf)
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
-- right. A description is text across the row, and a button stands alone.
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
	else
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Grey()) else label:SetTextColor(Normal()) end
		label:SetWidth(max(1, width - widget:GetWidth() - LABEL_GAP))
		label:Show()
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
	local cell = { row = row, frame = frame, widget = widget, label = frame.label, height = ROW_HEIGHT, place = PlaceRow }
	if row.type == 'description' then
		widget:SetWidth(self.width)
		cell.height = max(ROW_HEIGHT, ceil(widget:GetHeight()) + 12)
	elseif row.type == 'multiselect' then
		cell.height = max(ROW_HEIGHT, ceil(widget:GetHeight()) + 12)
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
-- out, and so are sections left empty). Returns the height drawn.
function Body:DrawSections(sections, makeCell)
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
	local laid, height = OB.LayoutSections(kept, function(row) return byRow[row].height end)
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
			cell.place(cell, p.col == 2 and (self.columnWidth + COLUMN_GAP) or 0, cell.y,
				p.col == 'full' and self.width or self.columnWidth)
		end
	end
	return #kept > 0 and height or 0
end

function Body:Draw(sections)
	return self:DrawSections(sections, function(row) return self:RowCell(row) end)
end

function Body:DrawResults(sections, onPick)
	return self:DrawSections(sections, function(row) return self:ResultCell(row, onPick) end)
end

function Body:Release()
	for _, cell in ipairs(self.cells) do
		if cell.widget then cell.widget:Release() end
	end
	wipe(self.cells)
	for _, key in ipairs({ 'row', 'result', 'title', 'note', 'line' }) do ReleaseAll(self.pools[key]) end
end
