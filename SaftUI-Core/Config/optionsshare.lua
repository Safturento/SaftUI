local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

--[[
	Shareable options drawn (the share field, optionsmodel.lua): the own mark,
	the diff icon and its tooltip, the hover line under a label with Reset
	and Apply to: All | Multiple, and a position block's marks on its
	section's title. The body (optionsbody.lua) calls in: PlaceRow ends with
	OB.PlaceShare(cell), the row frame's OnEnter (and a position block's
	parts) with OB.ShareEnter(frame), and DrawSections with
	OB.PlaceShareTitle(body, entry, title) for a section with a shareRow.
	Nothing here names what is shared: every name and text comes from the
	option's share.

	What each piece draws, from OM.ShareState (rows of a type
	OB.SHARE_KINDS marks 'row': toggle, range, select, input, color; a
	position row, 'mark', gets the mark alone, its title carrying the rest):
	  - the mark (state.marked): a 2px line in Button > Blue, 6 in from the
	    row's top and bottom, the metrics' markX in from its slot's left
	    (under Thick and Thin inside the panel's padding), and what it marks
	    (the label, the position block, the title) moves the metrics'
	    markShift right (under Blizzard 6, inside the cell). An own row's
	    label is OB.OWN_TEXT while the row isn't disabled.
	  - the diff icon (state.differs): st.icons.diff, 16x16, OB.DIFF_COLOR, 4
	    after the label's text (its string width, at most the label's
	    width; the label leaves the icon its room), on a frame that takes
	    the mouse. Its tooltip: the row's name, '<source>: <shared>' (not
	    for an item), then '<name>: <value>' for each page that differs.
	  - the hover line (state.offers, on a row that isn't disabled): the
	    small font under the label. On a member page Own (its tooltip: the
	    name and '<source>: <shared>'), the reset icon (st.icons.rotateCcw,
	    14x14, blue; its tooltip says what it drops), then '· Apply to: All
	    | Multiple'; on the source page 'Apply to: All | Multiple'. The links
	    are frames that take the mouse (Text > Blue, white under it), one
	    level over the row frame. Reset runs OM.ShareCall(root, row,
	    'reset'), All 'applyAll', Multiple opens W.OpenApplyList with
	    OM.ShareTargets, whose Apply runs 'apply'; each then calls the
	    body's onChanged(true), which draws the page again.
	  - showing it: OB.ShareEnter shows the line on an offering row, the
	    label lifted so it and the line are centred in the row; a line that
	    would end past the body's width ends at it. The line's OnUpdate (it
	    runs only while the line shows) hides it and puts the label back once
	    neither the row frame nor the line is under the mouse (IsMouseOver)
	    and the Apply list it opened is closed. A row that offers nothing
	    never moves.
	  - a section title (a position block's): OB.OWN_TEXT when marked (and
	    markShift right), the diff icon after its text, the hover line
	    inline 8 after the text (or the icon). It shows while the mouse is
	    on the title's line (a pooled frame over it), the block's row frame
	    or the line, and acts on the block's option.
	Under Blizzard the pieces, colors and icons are the same (Blizzard's
	Settings panel has nothing to draw them with), placed by OB.FLAT's markX
	and markShift.

	The pieces live on the row frame as frame.share = { mark, diff, line,
	ownText, reset, all, multiple, sep, pipe } (made the first time a row
	draws one, hidden on every row they don't apply to), a title's on its
	hover frame; body.shareTitles lists the drawn titles in section order as
	{ section, title, hover, parts }. Every script is wrapped (the game
	passes OnEnter and OnLeave a second argument).
]]

local floor, ceil, max, min, format = math.floor, math.ceil, math.max, math.min, string.format

-- What a row of each type carries: 'row', every piece; 'mark', the mark alone.
OB.SHARE_KINDS = { toggle = 'row', range = 'row', select = 'row', input = 'row', color = 'row', position = 'mark' }

local LINE_HEIGHT = 14 -- the hover line: the small font (13)
local MARK_WIDTH, MARK_INSET = 2, 6
local DIFF_SIZE, DIFF_GAP = 16, 4
local RESET_SIZE, RESET_GAP = 14, 6
local WORD_GAP = 4 -- between the line's words and links
local TITLE_GAP = 8 -- a title's line after its text or icon

local Colors = OB.Colors
local function Grey() return Colors().text.grey:GetRGB() end
local function LinkBlue() return Colors().text.blue:GetRGB() end

------------------------------------------------------------------ tooltips

-- A tooltip owned by owner: title in white, then each line (wrapped).
local function Tip(owner, title, ...)
	GameTooltip:SetOwner(owner, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(title, 1, 1, 1)
	for i = 1, select('#', ...) do
		local line = select(i, ...)
		if line then GameTooltip:AddLine(line, nil, nil, nil, true) end
	end
	GameTooltip:Show()
end

local function Untip(owner)
	if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

-- '<source>: <shared>', the source's value.
local function SourceLine(state)
	return state.source .. ': ' .. (state.shared or '')
end

-- What each link's tooltip says. Every name comes from the share.
local function DiffTip(host, owner)
	local state, name = host.shareState, host.shareCell.row.name
	GameTooltip:SetOwner(owner, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(name, 1, 1, 1)
	if not state.item then GameTooltip:AddLine(SourceLine(state), Grey()) end
	for _, entry in ipairs(state.differs) do GameTooltip:AddLine(entry.name .. ': ' .. entry.value) end
	GameTooltip:Show()
end

local TIPS = {
	ownText = function(state, name) return name, SourceLine(state) end,
	reset = function(state, name)
		local dropped = state.page and (state.page .. "'s own value is dropped.") or 'Its own value is dropped.'
		return 'Reset', format('%s follows %s again. %s', name, state.source, dropped)
	end,
	all = function(state, name)
		if state.member then
			return 'Apply to: All', format("%s takes %s's %s, and nothing keeps its own any more.", state.source, state.page or 'this', name)
		end
		return 'Apply to: All', format('Everything that keeps its own %s follows %s again.', name, state.source)
	end,
	multiple = function(state, name)
		if state.member then
			return 'Apply to: Multiple', format("Pick which take %s's %s as their own.", state.page or 'this', name)
		end
		return 'Apply to: Multiple', format("Pick which follow %s's %s again.", state.source, name)
	end,
}

------------------------------------------------------------------ the pieces

local ShowLine, HideLine -- below

-- A row's action, then the body's onChanged(true), which draws the page again.
local function Act(host, action, ...)
	local cell = host.shareCell
	local body = cell.body
	OM.ShareCall(body.root, cell.row, action, ...)
	if body.onChanged then body.onChanged(true) end
end

-- A frame on the line that takes the mouse and shows its tooltip (TIPS[key]),
-- one level over host.
local function Piece(host, line, key, frameType)
	local piece = CreateFrame(frameType or 'Frame', nil, line)
	piece:SetFrameLevel(host:GetFrameLevel() + 1)
	piece:EnableMouse(true)
	piece:SetHeight(LINE_HEIGHT)
	piece:SetScript('OnEnter', function(self)
		Tip(self, TIPS[key](host.shareState, host.shareCell.row.name))
		if self.text and self.lit then self.text:SetTextColor(1, 1, 1) end
		if self.icon then self.icon:SetVertexColor(1, 1, 1) end
	end)
	piece:SetScript('OnLeave', function(self)
		Untip(self)
		if self.text and self.lit then self.text:SetTextColor(LinkBlue()) end
		if self.icon then self.icon:SetVertexColor(Colors().button.blue:GetRGB()) end
	end)
	return piece
end

-- A link of the line: its text in Text > Blue, white under the mouse.
local function Link(host, line, key, label, onClick)
	local link = Piece(host, line, key, 'Button')
	link.text = OB.Text(link, 'small')
	link.text:SetPoint('LEFT', link, 'LEFT', 0, 0)
	link.text:SetText(label)
	link.lit = true
	link:SetScript('OnClick', function(self)
		Untip(self)
		onClick(self)
	end)
	return link
end

local function HideParts(parts)
	if parts.mark then parts.mark:Hide() end
	parts.diff:Hide()
	parts.line:Hide()
end

-- The pieces on host (a row frame, or a title's hover frame), made the first
-- time, hidden: { mark (a row's), diff, line and its parts }. host.shareCell is the
-- cell whose row they act on, host.shareState its OM.ShareState.
local function MakeParts(host, withMark)
	local parts = {}
	if withMark then parts.mark = host:CreateTexture(nil, 'ARTWORK') end

	local diff = CreateFrame('Frame', nil, host)
	diff:SetFrameLevel(host:GetFrameLevel() + 1)
	diff:SetSize(DIFF_SIZE, DIFF_SIZE)
	diff:EnableMouse(true)
	diff.icon = diff:CreateTexture(nil, 'ARTWORK')
	diff.icon:SetAllPoints(diff)
	diff.icon:SetTexture(st.icons.diff)
	diff:SetScript('OnEnter', function(self)
		DiffTip(host, self)
		OB.ShareEnter(host) -- reached without crossing the row: its line too
	end)
	diff:SetScript('OnLeave', function(self) Untip(self) end)
	parts.diff = diff

	local line = CreateFrame('Frame', nil, host)
	line:SetHeight(LINE_HEIGHT)
	line:SetFrameLevel(host:GetFrameLevel() + 1)
	line:Hide()
	-- The watcher: only while the line shows.
	line:SetScript('OnUpdate', function(self)
		if W.ListOwner() == parts.multiple or self:IsMouseOver() then return end
		for _, area in ipairs(host.shareWatch) do
			if area:IsMouseOver() then return end
		end
		HideLine(host)
	end)
	parts.line = line

	parts.ownText = Piece(host, line, 'ownText')
	parts.ownText.text = OB.Text(parts.ownText, 'small')
	parts.ownText.text:SetPoint('LEFT', parts.ownText, 'LEFT', 0, 0)
	parts.ownText.text:SetText('Own')

	parts.reset = Piece(host, line, 'reset', 'Button')
	parts.reset:SetWidth(RESET_SIZE)
	parts.reset.icon = parts.reset:CreateTexture(nil, 'ARTWORK')
	parts.reset.icon:SetAllPoints(parts.reset)
	parts.reset.icon:SetTexture(st.icons.rotateCcw)
	parts.reset:SetScript('OnClick', function(self)
		Untip(self)
		Act(host, 'reset')
	end)

	parts.sep = OB.Text(line, 'small')
	parts.all = Link(host, line, 'all', 'All', function() Act(host, 'applyAll') end)
	parts.pipe = OB.Text(line, 'small')
	parts.pipe:SetText('|')
	parts.multiple = Link(host, line, 'multiple', 'Multiple', function(self)
		local cell = host.shareCell
		W.OpenApplyList(self, OM.ShareTargets(cell.body.root, cell.row), function(keys)
			Act(host, 'apply', keys)
		end)
	end)

	HideParts(parts)
	host.share = parts
	return parts
end

-- A font string's width in whole units.
local function TextWidth(fs)
	return ceil(fs:GetUnboundedStringWidth())
end

-- Lays the line's pieces out for state, left to right, and returns its width.
local function FillLine(parts, state)
	local line, x = parts.line, 0
	local function Put(region, width)
		region:ClearAllPoints()
		region:SetPoint('LEFT', line, 'LEFT', x, 0)
		region:Show()
		x = x + width
	end
	parts.ownText.text:SetTextColor(unpack(OB.OWN_TEXT))
	parts.reset.icon:SetVertexColor(Colors().button.blue:GetRGB())
	for _, link in ipairs({ parts.all, parts.multiple }) do
		link.text:SetTextColor(LinkBlue())
		link:SetWidth(TextWidth(link.text))
	end
	parts.sep:SetTextColor(Grey())
	parts.pipe:SetTextColor(Grey())
	if state.member then
		local ownWidth = TextWidth(parts.ownText.text)
		parts.ownText:SetWidth(ownWidth)
		Put(parts.ownText, ownWidth + RESET_GAP)
		Put(parts.reset, RESET_SIZE + RESET_GAP)
		parts.sep:SetText('· Apply to:')
	else
		parts.ownText:Hide()
		parts.reset:Hide()
		parts.sep:SetText('Apply to:')
	end
	Put(parts.sep, TextWidth(parts.sep) + WORD_GAP)
	Put(parts.all, parts.all:GetWidth() + WORD_GAP)
	Put(parts.pipe, TextWidth(parts.pipe) + WORD_GAP)
	Put(parts.multiple, parts.multiple:GetWidth())
	line:SetWidth(x)
	return x
end

------------------------------------------------------------------ showing the line

-- Where a lifted label's top sits: it and the line centred in the row's band.
local function LiftTop(cell)
	return floor((cell.rowHeight - OB.LABEL_HEIGHT - LINE_HEIGHT) / 2)
end

-- Shows host's line (a row frame's lifts its label).
function ShowLine(host)
	local parts = host.share
	if not (parts and host.shareOffers) then return end
	parts.line:Show()
	if host.shareLifts then
		local cell = host.shareCell
		cell.label:ClearAllPoints()
		cell.label:SetPoint('TOPLEFT', host, 'TOPLEFT', host.shareShift, -LiftTop(cell))
	end
end

-- Hides host's line and puts a row's label back.
function HideLine(host)
	host.share.line:Hide()
	if host.shareLifts then OB.PlaceLabel(host.shareCell, host.shareShift) end
end

-- The row frame's OnEnter (and a position block's parts): shows the line of
-- an offering row, or of the block's title.
function OB.ShareEnter(frame)
	ShowLine(frame.shareTitle or frame)
end

-- x so a line width wide that starts at left (in the content) ends no
-- further right than the body's width.
local function KeepInBody(body, left, width)
	return min(left, body.width - width)
end

------------------------------------------------------------------ a row

-- A placed row's marks (the end of the body's PlaceRow). Everything a pooled
-- frame drew for its last row is taken off first.
function OB.PlaceShare(cell)
	local frame, body = cell.frame, cell.body
	frame.shareTitle, frame.shareOffers, frame.shareState, frame.shareLifts = nil, false, nil, nil
	cell.ownLabel = nil
	if frame.share then HideParts(frame.share) end
	local kind = OB.SHARE_KINDS[cell.row.type]
	if not (kind and body) then return end
	local state = OM.ShareState(body.root, cell.row)
	if not state then return end
	local row, metrics = cell.row, body.metrics
	local isRow = kind == 'row'
	local diffs = isRow and #state.differs > 0
	local offers = isRow and state.offers and not row.disabled
	if not (state.marked or diffs or offers) then return end

	local parts = frame.share or MakeParts(frame, true)
	frame.shareCell, frame.shareState, frame.shareWatch = cell, state, { frame }
	local shift = state.marked and metrics.markShift or 0
	if state.marked then
		local mark = parts.mark
		mark:SetColorTexture(Colors().button.blue:GetRGB())
		mark:ClearAllPoints()
		mark:SetPoint('TOPLEFT', frame, 'TOPLEFT', metrics.markX - metrics.pad, -MARK_INSET)
		mark:SetSize(MARK_WIDTH, max(1, cell.height - 2 * MARK_INSET))
		mark:Show()
		if not isRow then
			-- A position block moves under its mark.
			cell.widget.frame:ClearAllPoints()
			cell.widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', shift, -6)
			return
		end
		if not row.disabled then
			cell.label:SetTextColor(unpack(OB.OWN_TEXT))
			cell.ownLabel = true
		end
	end
	if not isRow then return end

	-- The label moves under the mark and leaves the diff icon its room.
	local label = cell.label
	label:SetWidth(max(1, label:GetWidth() - shift - (diffs and DIFF_SIZE + DIFF_GAP or 0)))
	OB.PlaceLabel(cell, shift)
	frame.shareShift = shift
	if diffs then
		local diff = parts.diff
		diff.icon:SetVertexColor(unpack(OB.DIFF_COLOR))
		diff:ClearAllPoints()
		diff:SetPoint('LEFT', label, 'LEFT', min(TextWidth(label), floor(label:GetWidth())) + DIFF_GAP, 0)
		diff:Show()
	end
	if offers then
		frame.shareOffers, frame.shareLifts = true, true
		local width = FillLine(parts, state)
		local left = KeepInBody(body, cell.x + shift, width) - cell.x
		parts.line:ClearAllPoints()
		parts.line:SetPoint('TOPLEFT', frame, 'TOPLEFT', left, -(LiftTop(cell) + OB.LABEL_HEIGHT))
	end
end

------------------------------------------------------------------ a section title

-- The pooled frames over the titles' lines, a pool of the body's own (its
-- Release releases every pool).
local function HoverPool(body)
	local pool = body.pools.shareHover
	if not pool then
		pool = OB.Pool(function()
			local hover = CreateFrame('Frame', nil, body.content)
			hover:EnableMouse(true)
			hover:SetScript('OnEnter', function(self) ShowLine(self) end)
			return hover
		end)
		body.pools.shareHover = pool
	end
	return pool
end

-- A shareable position block's marks on its section's title (entry, as
-- OB.LayoutSections gives it): called once the block's row is placed.
function OB.PlaceShareTitle(body, entry, title)
	local row = entry.section.shareRow
	local cell
	for _, each in ipairs(body.cells) do
		if each.row == row then cell = each; break end
	end
	if not cell then return end
	local state = OM.ShareState(body.root, row)
	if not state then return end
	local metrics, content = body.metrics, body.content

	local hover = OB.Acquire(HoverPool(body))
	hover:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -entry.titleY)
	hover:SetSize(body.width, OB.TITLE_HEIGHT)
	local parts = hover.share or MakeParts(hover, false)
	HideParts(parts)
	hover.shareCell, hover.shareState, hover.shareWatch = cell, state, { hover, cell.frame }
	hover.shareOffers = state.offers and not row.disabled
	cell.frame.shareTitle = hover

	local shift = state.marked and metrics.markShift or 0
	if state.marked then
		title:SetTextColor(unpack(OB.OWN_TEXT))
		title:ClearAllPoints()
		title:SetPoint('TOPLEFT', content, 'TOPLEFT', shift, -entry.titleY)
	end
	local x = shift + min(TextWidth(title), floor(title:GetWidth()))
	if #state.differs > 0 then
		local diff = parts.diff
		diff.icon:SetVertexColor(unpack(OB.DIFF_COLOR))
		diff:ClearAllPoints()
		diff:SetPoint('TOPLEFT', hover, 'TOPLEFT', x + DIFF_GAP, -floor((OB.TITLE_HEIGHT - DIFF_SIZE) / 2))
		diff:Show()
		x = x + DIFF_GAP + DIFF_SIZE
	end
	if hover.shareOffers then
		local width = FillLine(parts, state)
		parts.line:ClearAllPoints()
		parts.line:SetPoint('TOPLEFT', hover, 'TOPLEFT', KeepInBody(body, x + TITLE_GAP, width),
			-floor((OB.TITLE_HEIGHT - LINE_HEIGHT) / 2))
	end
	body.shareTitles[#body.shareTitles + 1] = { section = entry.section, title = title, hover = hover, parts = parts }
end
