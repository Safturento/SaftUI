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
	OB.SHARE_KINDS marks 'row': toggle, range, select, input, color, item; a
	position row, 'mark', gets the mark alone, its title carrying the rest):
	  - the mark (state.marked): a 2px line in Button > Blue, 6 in from the
	    row's top and bottom, the metrics' markX in from its slot's left
	    (under Thick and Thin inside the panel's padding), and what it marks
	    (the label, the position block, the title) moves the metrics'
	    markShift right (under Blizzard 6, inside the cell). A marked row's
	    label is OB.OWN_TEXT while the row isn't disabled (cell.ownLabel, so
	    the body's Refresh keeps it once the row is enabled mid-drag).
	  - the diff icon (state.differs): st.icons.diff, 16x16, OB.DIFF_COLOR, 4
	    after the label's text (its string width, at most the label's
	    width; the label leaves the icon its room), on a frame that takes
	    the mouse. Its tooltip: the row's name, '<source>: <shared>' (not
	    for an item), then a line per page that differs in two columns, the
	    page on the left and its value on the right in OB.OWN_TEXT.
	  - the hover line (state.offers, on a row that isn't disabled): the
	    small font under the label. On a member page Own (its tooltip: the
	    name and '<source>: <shared>'), the reset icon (st.icons.rotateCcw,
	    14x14, blue; its tooltip says what it drops), then '· Apply to: All
	    | Multiple'; on the source page 'Apply to: All | Multiple'. The links
	    are frames that take the mouse (Text > Blue, white under it), the
	    line 4 levels over the row frame and they one over the line, so they
	    are above every part of the control. Reset runs OM.ShareCall(root,
	    row, 'reset'), All 'applyAll', Multiple opens W.OpenApplyList with
	    OM.ShareTargets, whose Apply runs 'apply' on the row it was opened
	    for; each then calls the body's onChanged(true), which draws the
	    page again. The list closes when the line's row is drawn again or
	    hidden (released). An item's (state.item) tooltips name its Show,
	    which is what they act on. No tooltip builds "s's": a possessive
	    after a final s is just an apostrophe (Possessive), and All and
	    Multiple say "from <page>" and "follow <source> again for <name>".
	  - showing it: OB.ShareEnter shows the line on an offering row, the
	    label lifted so it and the line are centred in the row; the row
	    frame's OnEnter calls it, and so does each mouse-enabled part of the
	    row's control (hooked once per pooled part, finding the row when it
	    runs), so a row entered through its control shows its line too. The
	    line starts under the label and ends no further right than its
	    cell's right edge. When the whole line doesn't fit there it drops
	    Own (the mark and the label still say it; Reset's tooltip gains
	    Own's '<source>: <shared>' line), then the words before All ('·
	    Apply to:'; All's and Multiple's tooltips are titled with them),
	    leaving the reset icon and All | Multiple. Still longer, it is cut
	    there (it clips its pieces, and a piece past the cut takes no mouse
	    there). A title's line has no room and is always whole. The line's OnUpdate
	    (it runs only while the line shows) hides it and puts the label back
	    once the body's view (the content's parent) isn't under the mouse,
	    or neither the row frame nor the line is (IsMouseOver), unless the
	    Apply list it opened is open. A row that offers nothing never moves.
	  - a section title (a position block's): OB.OWN_TEXT when marked (and
	    markShift right), the diff icon after its text, the hover line
	    inline 8 after the text (or the icon). It shows while the mouse is
	    on the title's line (a pooled frame over it), the block's row frame
	    or the line, and acts on the block's option. It reuses the block's
	    row's state (OM.ShareState once a row a draw).
	Under Blizzard the pieces, colors and icons are the same (Blizzard's
	Settings panel has nothing to draw them with), placed by OB.FLAT's markX
	and markShift.

	A row's label sits cell.labelX in from its cell's left (0 when nil; an
	item's after its Show box): OB.PlaceLabel, the lift, putting it back and
	the line's left all add it, so a type whose label doesn't start at the
	cell's left can still be 'row' in OB.SHARE_KINDS. A row's line is cut at
	cell.lineEnd (from the cell's left; nil: the cell's right edge): an
	item's ends where its label does, 6 before its dots, so it never covers
	them. An item is 'row'; it moves its own Show box under its mark
	(optionsbody.lua's PlaceRow).

	The pieces live on the row frame as frame.share = { mark, diff, line,
	ownText, reset, all, multiple, sep, pipe } (made the first time a row
	draws one, hidden on every row they don't apply to), a title's on its
	hover frame; body.shareTitles lists the drawn titles in section order as
	{ section, title, hover, parts }. Every script is wrapped (the game
	passes OnEnter and OnLeave a second argument).
]]

local floor, ceil, max, min, format = math.floor, math.ceil, math.max, math.min, string.format

-- What a row of each type carries: 'row', every piece; 'mark', the mark alone.
OB.SHARE_KINDS = {
	toggle = 'row', range = 'row', select = 'row', input = 'row', color = 'row', position = 'mark',
	item = 'row', -- its name is its label, after its Show box (labelX); its line acts on its Show
}

local LINE_HEIGHT = 14 -- the hover line: the small font (13)
local LINE_LEVEL = 4 -- the line over its row frame, above every part of the control
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

-- name's possessive: just an apostrophe after a final s, so none reads "s's".
local function Possessive(name)
	return name .. (name:find('[sS]$') and "'" or "'s")
end

-- What the line's tooltips call the setting: the row's name, or an item's
-- Show, which is what its line acts on.
local function SettingName(state, name)
	return state.item and (Possessive(name) .. ' Show') or name
end

-- '<source>: <shared>', the source's value.
local function SourceLine(state)
	return state.source .. ': ' .. (state.shared or '')
end

-- The diff icon's tooltip: the name, the source's value (not for an item),
-- then a line per page that differs, the page on the left and its value on
-- the right in light blue, as the mockup's two columns.
local function DiffTip(host, owner)
	local state, name = host.shareState, host.shareCell.row.name
	GameTooltip:SetOwner(owner, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(name, 1, 1, 1)
	if not state.item then GameTooltip:AddLine(SourceLine(state), Grey()) end
	for _, entry in ipairs(state.differs) do
		GameTooltip:AddDoubleLine(entry.name, entry.value, nil, nil, nil, unpack(OB.OWN_TEXT))
	end
	GameTooltip:Show()
end

-- What each link's tooltip says (name: SettingName's; parts, the line's
-- pieces). Every name comes from the share; no possessive is built from the
-- source's or the page's name but Reset's, through Possessive. A line too
-- long for its room drops Own (FillLine: parts.ownDropped), and Reset's
-- tooltip then carries Own's '<source>: <shared>'.
local TIPS = {
	ownText = function(state, name) return name, SourceLine(state) end,
	reset = function(state, name, parts)
		local dropped = state.page and (Possessive(state.page) .. ' own value is dropped.') or 'Its own value is dropped.'
		return 'Reset', format('%s follows %s again. %s', name, state.source, dropped),
			parts and parts.ownDropped and SourceLine(state) or nil
	end,
	all = function(state, name)
		if state.member then
			return 'Apply to: All', format('%s takes %s from %s, and nothing keeps its own any more.', state.source, name, state.page or 'this page')
		end
		return 'Apply to: All', format('Everything that keeps its own %s follows %s again.', name, state.source)
	end,
	multiple = function(state, name)
		if state.member then
			return 'Apply to: Multiple', format('Pick which take %s from %s as their own.', name, state.page or 'this page')
		end
		return 'Apply to: Multiple', format('Pick which follow %s again for %s.', state.source, name)
	end,
}

------------------------------------------------------------------ the pieces

local ShowLine, HideLine -- below

-- A share's action on row (of root, drawn by body), then the body's
-- onChanged(true), which draws the page again.
local function Act(body, root, row, action, ...)
	OM.ShareCall(root, row, action, ...)
	if body.onChanged then body.onChanged(true) end
end

-- An action on the row host shows now (Reset, All: their links show only
-- while it does).
local function ActNow(host, action)
	local cell = host.shareCell
	Act(cell.body, cell.body.root, cell.row, action)
end

-- A frame on the line that takes the mouse and shows its tooltip (TIPS[key]),
-- one level over the line.
local function Piece(host, line, key, frameType)
	local piece = CreateFrame(frameType or 'Frame', nil, line)
	piece:SetFrameLevel(line:GetFrameLevel() + 1)
	piece:EnableMouse(true)
	piece:SetHeight(LINE_HEIGHT)
	piece:SetScript('OnEnter', function(self)
		local state = host.shareState
		Tip(self, TIPS[key](state, SettingName(state, host.shareCell.row.name), host.share))
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

-- Hides the pieces, closing the Apply list the line opened (its row is drawn
-- again: the list was for the row the frame held).
local function HideParts(parts)
	if W.ListOwner() == parts.multiple then W.CloseList() end
	if parts.mark then parts.mark:Hide() end
	parts.diff:Hide()
	parts.line:Hide()
end

-- The view the body's rows are seen through: the content's parent (the
-- window's and the dialog's scroll frame), or nil.
local function ViewOf(host)
	local cell = host.shareCell
	return cell and cell.body and cell.body.content:GetParent()
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
	line:SetFrameLevel(host:GetFrameLevel() + LINE_LEVEL)
	line:Hide()
	-- The watcher: only while the line shows. The Apply list it opened keeps
	-- it; off the body's view (a row partly scrolled out) it goes.
	line:SetScript('OnUpdate', function(self)
		if W.ListOwner() == parts.multiple then return end
		local view = ViewOf(host)
		if view and not view:IsMouseOver() then return HideLine(host) end
		if self:IsMouseOver() then return end
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
		ActNow(host, 'reset')
	end)

	parts.sep = OB.Text(line, 'small')
	parts.all = Link(host, line, 'all', 'All', function() ActNow(host, 'applyAll') end)
	parts.pipe = OB.Text(line, 'small')
	parts.pipe:SetText('|')
	-- Its Apply acts on the row the list was opened for, whatever the pooled
	-- frame holds by then.
	parts.multiple = Link(host, line, 'multiple', 'Multiple', function(self)
		local cell = host.shareCell
		local body, root, row = cell.body, cell.body.root, cell.row
		W.OpenApplyList(self, OM.ShareTargets(root, row), function(keys)
			Act(body, root, row, 'apply', keys)
		end)
	end)
	-- Its row released or hidden: the list goes with it.
	parts.multiple:SetScript('OnHide', function(self)
		if W.ListOwner() == self then W.CloseList() end
	end)

	HideParts(parts)
	host.share = parts
	return parts
end

-- A font string's width in whole units.
local function TextWidth(fs)
	return ceil(fs:GetUnboundedStringWidth())
end

-- Lays the line's pieces out for state, left to right. With room, a line
-- wider than it is cut there: it clips what runs past, a piece wholly past
-- the cut is hidden, and one across it takes no mouse past it. Returns the
-- line's width.
local function FillLine(parts, state, room)
	local line, x = parts.line, 0
	local function Put(region, width, gap)
		region:ClearAllPoints()
		region:SetPoint('LEFT', line, 'LEFT', x, 0)
		region:Show()
		if region:IsObjectType('Frame') then -- a piece; the words are clipped with the line
			if room and x >= room then
				region:Hide()
			else
				region:SetHitRectInsets(0, room and max(0, x + width - room) or 0, 0, 0)
			end
		end
		x = x + width + (gap or 0)
	end
	parts.ownText.text:SetTextColor(unpack(OB.OWN_TEXT))
	parts.reset.icon:SetVertexColor(Colors().button.blue:GetRGB())
	for _, link in ipairs({ parts.all, parts.multiple }) do
		link.text:SetTextColor(LinkBlue())
		link:SetWidth(TextWidth(link.text))
	end
	parts.sep:SetTextColor(Grey())
	parts.pipe:SetTextColor(Grey())
	-- Too long for its room: Own goes first (the mark and the label say it;
	-- Reset's tooltip takes its line), then the words before All (their
	-- links' tooltips say them). The cut below is the last resort.
	local member = state.member
	parts.sep:SetText(member and '· Apply to:' or 'Apply to:')
	local ownWidth, sepWidth = TextWidth(parts.ownText.text), TextWidth(parts.sep)
	local links = parts.all:GetWidth() + WORD_GAP + TextWidth(parts.pipe) + WORD_GAP + parts.multiple:GetWidth()
	local withOwn, withWords = member, true
	local function Width()
		return (withOwn and ownWidth + RESET_GAP or 0) + (member and RESET_SIZE + RESET_GAP or 0)
			+ (withWords and sepWidth + WORD_GAP or 0) + links
	end
	if room and withOwn and Width() > room then withOwn = false end
	if room and Width() > room then withWords = false end
	parts.ownDropped = member and not withOwn
	if withOwn then
		parts.ownText:SetWidth(ownWidth)
		Put(parts.ownText, ownWidth, RESET_GAP)
	else
		parts.ownText:Hide()
	end
	if member then Put(parts.reset, RESET_SIZE, RESET_GAP) else parts.reset:Hide() end
	if withWords then Put(parts.sep, sepWidth, WORD_GAP) else parts.sep:Hide() end
	Put(parts.all, parts.all:GetWidth(), WORD_GAP)
	Put(parts.pipe, TextWidth(parts.pipe), WORD_GAP)
	Put(parts.multiple, parts.multiple:GetWidth())
	local cut = room ~= nil and x > room
	line:SetClipsChildren(cut)
	local width = cut and max(1, floor(room)) or x
	line:SetWidth(width)
	return width
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
		cell.label:SetPoint('TOPLEFT', host, 'TOPLEFT', (cell.labelX or 0) + host.shareShift, -LiftTop(cell))
	end
end

-- Hides host's line and puts a row's label back.
function HideLine(host)
	host.share.line:Hide()
	if host.shareLifts then OB.PlaceLabel(host.shareCell, host.shareShift) end
end

-- The row frame's OnEnter (and a position block's parts, and a control's):
-- shows the line of an offering row, or of the block's title.
function OB.ShareEnter(frame)
	ShowLine(frame.shareTitle or frame)
end

-- x so a line width wide that starts at left (in the content) ends no
-- further right than the body's width.
local function KeepInBody(body, left, width)
	return min(left, body.width - width)
end

-- The control's hover is its row's: each mouse-enabled part of it (region
-- and what's under it) gets a hook once (the widgets are pooled), which finds
-- the row frame when it runs: the first frame up from the part that a
-- PlaceShare has been through (shareOffers is set on each), so a control
-- drawn on a plain row since shows nothing. A part enabled later is hooked
-- the next time an offering row draws it.
local function HookControl(region)
	if region:IsMouseEnabled() and not region.shareHooked then
		region.shareHooked = true
		region:HookScript('OnEnter', function(self)
			local host = self:GetParent()
			while host and host.shareOffers == nil do host = host:GetParent() end
			if host then OB.ShareEnter(host) end
		end)
	end
	for _, child in ipairs({ region:GetChildren() }) do HookControl(child) end
end

------------------------------------------------------------------ a row

-- A placed row's marks (the end of the body's PlaceRow). Everything a pooled
-- frame drew for its last row is taken off first. The state is kept on the
-- frame (frame.shareState) as soon as it's read, for the section title's
-- marks (OB.PlaceShareTitle) to reuse.
function OB.PlaceShare(cell)
	local frame, body = cell.frame, cell.body
	frame.shareTitle, frame.shareOffers, frame.shareState, frame.shareLifts = nil, false, nil, nil
	cell.ownLabel = nil
	if frame.share then HideParts(frame.share) end
	local kind = OB.SHARE_KINDS[cell.row.type]
	if not (kind and body) then return end
	local state = OM.ShareState(body.root, cell.row)
	frame.shareCell, frame.shareState = cell, state
	if not state then return end
	local row, metrics = cell.row, body.metrics
	local isRow = kind == 'row'
	local diffs = isRow and #state.differs > 0
	local offers = isRow and state.offers and not row.disabled
	if not (state.marked or diffs or offers) then return end

	local parts = frame.share or MakeParts(frame, true)
	frame.shareWatch = { frame }
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
		-- Light blue while it isn't disabled; Refresh brings it back once enabled.
		cell.ownLabel = true
		if not row.disabled then cell.label:SetTextColor(unpack(OB.OWN_TEXT)) end
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
		-- Under the label, and cut at the cell's right edge (or its lineEnd):
		-- never in the next cell, nor over an item's dots.
		local left = (cell.labelX or 0) + shift
		FillLine(parts, state, (cell.lineEnd or frame:GetWidth()) - left)
		parts.line:ClearAllPoints()
		parts.line:SetPoint('TOPLEFT', frame, 'TOPLEFT', left, -(LiftTop(cell) + OB.LABEL_HEIGHT))
		HookControl(cell.widget.frame)
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
-- OB.LayoutSections gives it): called once the block's row is placed, whose
-- state (PlaceShare's, on its frame) it reuses.
function OB.PlaceShareTitle(body, entry, title)
	local row = entry.section.shareRow
	local cell
	for _, each in ipairs(body.cells) do
		if each.row == row then cell = each; break end
	end
	if not (cell and cell.frame.shareCell == cell) then return end
	local state = cell.frame.shareState
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
