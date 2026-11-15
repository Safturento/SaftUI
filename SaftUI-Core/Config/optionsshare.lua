local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

--[[
	Shareable options drawn (the share field, optionsmodel.lua): the own mark,
	the diff icon and its tooltip, the hover line under a label with Reset
	and Apply to: All | Multiple, and a position block's marks on its
	section's title; and a setting's own reset (the default field: the same
	reset icon by its control, OB.PlaceDefault, at the end of this file). The
	body (optionsbody.lua) calls in: PlaceRow ends with OB.PlaceDefault(cell)
	then OB.PlaceShare(cell), its Refresh runs OB.PlaceDefault again, the row
	frame's OnEnter (and a position block's parts) runs OB.ShareEnter(frame),
	and DrawSections OB.PlaceShareTitle(body, entry, title) for a section
	with a shareRow. Nothing here names what is shared: every name and text
	comes from the option's share or default.

	What each piece draws, from OM.ShareState (rows of a type
	OB.SHARE_KINDS marks 'row': toggle, range, select, input, color, item, font; a
	position row, 'mark', gets the mark alone, its title carrying the rest):
	  - the mark (state.marked): a 2px line in the accent (Theme > Accent), 6 in from the
	    row's top and bottom, the metrics' markX in from its slot's left
	    (under Thick and Thin inside the panel's padding), and what it marks
	    (the label, the position block, the title) moves the metrics'
	    markShift right (under Blizzard 6, inside the cell). A marked row's
	    label is the accent at OB.OWN_STRENGTH while the row isn't disabled (cell.ownLabel, so
	    the body's Refresh keeps it once the row is enabled mid-drag).
	  - the diff icon (state.differs): st.icons.diff, 16x16, Text > Muted at OB.DIFF_STRENGTH, 4
	    after the label's text (its string width, at most the label's
	    width; the label leaves the icon its room), on a frame that takes
	    the mouse. Its tooltip: the row's name, '<source>: <shared>' (not
	    for an item), then a line per page that differs in two columns, the
	    page on the left and its value on the right in the accent.
	  - the hover line (state.offers, on a row that isn't disabled): the
	    small font under the label. On a member page Own (its tooltip: the
	    name and '<source>: <shared>'), the reset icon (st.icons.rotateCcw,
	    14x14, Text > Muted, lit in the accent under the mouse; its tooltip says what it
	    drops), then '· Apply to: All
	    | Multiple'; on the source page 'Apply to: All | Multiple'. The links
	    are frames that take the mouse (the accent, white under it), the
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
	    The share's noun names the members in them ("every page", "which
	    pages"), and its pageText is the page as a sentence reads it ("the
	    Third"; TIPS).
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
	  - a section title (a position block's): the accent at OB.OWN_STRENGTH when marked (and
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
	font = 'row',
}

local LINE_HEIGHT = 14 -- the hover line: the small font (13)
local LINE_LEVEL = 4 -- the line over its row frame, above every part of the control
local MARK_WIDTH, MARK_INSET = 2, 6
local DIFF_SIZE, DIFF_GAP = 16, 4
local RESET_SIZE, RESET_GAP = 14, 6
local WORD_GAP = 4 -- between the line's words and links
local TITLE_GAP = 8 -- a title's line after its text or icon

local function Muted() return st:Color('text', 'muted'):GetRGB() end

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

-- The reset icon, which a shared row's hover line (Reset) and a setting's
-- own reset (OB.PlaceDefault) both draw: a 14x14 button holding Lucide's
-- rotate-ccw (st.icons.rotateCcw), Text > Muted at rest, lit in the accent
-- (the accent) under the mouse; each read as it's painted, so a color
-- change shows on its next place or hover. tip(self) shows its tooltip; a
-- click hides that, then runs onClick(self).
local function ResetAtRest(button) button.icon:SetVertexColor(Muted()) end
local function ResetIcon(parent, tip, onClick)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(RESET_SIZE, RESET_SIZE)
	button:EnableMouse(true)
	button.icon = button:CreateTexture(nil, 'ARTWORK')
	button.icon:SetAllPoints(button)
	button.icon:SetTexture(st.icons.rotateCcw)
	ResetAtRest(button)
	button:SetScript('OnEnter', function(self)
		tip(self)
		self.icon:SetVertexColor(st:Color('accent'):GetRGB())
	end)
	button:SetScript('OnLeave', function(self)
		Untip(self)
		ResetAtRest(self)
	end)
	button:SetScript('OnClick', function(self)
		Untip(self)
		onClick(self)
	end)
	return button
end
OB.ResetIcon = ResetIcon -- the Categories list's order icon draws the same one

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
-- the right in the accent, as the mockup's two columns.
local function DiffTip(host, owner)
	local state, name = host.shareState, host.shareCell.row.name
	GameTooltip:SetOwner(owner, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(name, 1, 1, 1)
	if not state.item then GameTooltip:AddLine(SourceLine(state), Muted()) end
	for _, entry in ipairs(state.differs) do
		GameTooltip:AddDoubleLine(entry.name, entry.value, nil, nil, nil, st:Color('accent'):GetRGB())
	end
	GameTooltip:Show()
end

-- text with its first letter a capital, to start a sentence: the only change
-- Core makes to a name it's given (a pageText's 'the').
local function Sentence(text)
	return (text:gsub('^%l', string.upper))
end

-- The page as a sentence reads it: the share's pageText (its article, if
-- its names take one, is the module's to give), else its name; nil for none.
local function PageText(state)
	return state.pageText or state.page
end

-- What each link's tooltip says (name: SettingName's; parts, the line's
-- pieces). Every name comes from the share; no possessive is built from the
-- source's or the page's name but Reset's, through Possessive. With the
-- share's noun, what a member is ({ 'page', 'pages' }), All and Multiple name
-- the members ('Every page that keeps...', 'Pick which pages...'); without it,
-- the wording as before ('Everything', 'Pick which'). A line too
-- long for its room drops Own (FillLine: parts.ownDropped), and Reset's
-- tooltip then carries Own's '<source>: <shared>'.
local TIPS = {
	ownText = function(state, name) return name, SourceLine(state) end,
	reset = function(state, name, parts)
		local page = PageText(state)
		local dropped = page and (Sentence(Possessive(page)) .. ' own value is dropped.') or 'Its own value is dropped.'
		return 'Reset', format('%s follows %s again. %s', name, state.source, dropped),
			parts and parts.ownDropped and SourceLine(state) or nil
	end,
	all = function(state, name)
		local noun = state.noun
		if state.member then
			return 'Apply to: All', format('%s takes %s from %s, and %s keeps its own any more.', state.source, name,
				PageText(state) or 'this page', noun and ('no ' .. noun[1]) or 'nothing')
		end
		return 'Apply to: All', format('%s that keeps its own %s follows %s again.',
			noun and ('Every ' .. noun[1]) or 'Everything', name, state.source)
	end,
	multiple = function(state, name)
		local which = state.noun and ('Pick which ' .. state.noun[2]) or 'Pick which'
		if state.member then
			return 'Apply to: Multiple', format('%s take %s from %s as their own.', which, name, PageText(state) or 'this page')
		end
		return 'Apply to: Multiple', format('%s follow %s again for %s.', which, state.source, name)
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
		if self.text and self.lit then self.text:SetTextColor(st:Color('text', 'strong'):GetRGB()) end
	end)
	piece:SetScript('OnLeave', function(self)
		Untip(self)
		if self.text and self.lit then self.text:SetTextColor(OB.Accent()) end
	end)
	return piece
end

-- A link of the line: its text in the accent, white under the mouse.
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

	parts.reset = ResetIcon(line, function(self)
		local state = host.shareState
		Tip(self, TIPS.reset(state, SettingName(state, host.shareCell.row.name), host.share))
	end, function() ActNow(host, 'reset') end)
	parts.reset:SetFrameLevel(line:GetFrameLevel() + 1)

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
	parts.ownText.text:SetTextColor(st:ColorRGBA('accent', nil, OB.OWN_STRENGTH))
	ResetAtRest(parts.reset)
	for _, link in ipairs({ parts.all, parts.multiple }) do
		link.text:SetTextColor(OB.Accent())
		link:SetWidth(TextWidth(link.text))
	end
	parts.sep:SetTextColor(Muted())
	parts.pipe:SetTextColor(Muted())
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

-- The diff icon DIFF_GAP after the label's text, or its end when the text is
-- cut.
local function PlaceDiff(cell, parts)
	local label = cell.label
	parts.diff:ClearAllPoints()
	parts.diff:SetPoint('LEFT', label, 'LEFT', min(TextWidth(label), floor(label:GetWidth())) + DIFF_GAP, 0)
end

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
		mark:SetColorTexture(st:Color('accent'):GetRGB())
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
		-- The accent while it isn't disabled; Refresh brings it back once enabled.
		cell.ownLabel = true
		if not row.disabled then cell.label:SetTextColor(st:ColorRGBA('accent', nil, OB.OWN_STRENGTH)) end
	end
	if not isRow then return end

	-- The label moves under the mark and leaves the diff icon its room
	-- (cell.shareCut, which a setting's own reset keeps off it too).
	local label = cell.label
	cell.shareCut = shift + (diffs and DIFF_SIZE + DIFF_GAP or 0)
	label:SetWidth(max(1, label:GetWidth() - cell.shareCut))
	OB.PlaceLabel(cell, shift)
	frame.shareShift = shift
	if diffs then
		parts.diff.icon:SetVertexColor(st:ColorRGBA('text', 'muted', OB.DIFF_STRENGTH))
		PlaceDiff(cell, parts)
		parts.diff:Show()
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

-- Mid-drag (the body's Refresh), once a setting's own reset came or went and
-- moved the label's end and the line's (OB.PlaceDefault): the diff icon
-- after the label again, and the hover line, shown or not, cut again at its
-- lineEnd, as PlaceShare would draw them now.
function OB.FollowShare(cell)
	local frame = cell.frame
	local parts = frame.share
	if not (parts and frame.shareCell == cell) then return end
	if parts.diff:IsShown() then PlaceDiff(cell, parts) end
	if frame.shareOffers then
		FillLine(parts, frame.shareState, (cell.lineEnd or frame:GetWidth()) - (cell.labelX or 0) - (frame.shareShift or 0))
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
		title:SetTextColor(st:ColorRGBA('accent', nil, OB.OWN_STRENGTH))
		title:ClearAllPoints()
		title:SetPoint('TOPLEFT', content, 'TOPLEFT', shift, -entry.titleY)
	end
	local x = shift + min(TextWidth(title), floor(title:GetWidth()))
	if #state.differs > 0 then
		local diff = parts.diff
		diff.icon:SetVertexColor(st:ColorRGBA('text', 'muted', OB.DIFF_STRENGTH))
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

------------------------------------------------------------------ a setting's own reset

local DEFAULT_GAP = 6 -- the icon's right edge this far left of what the control draws
local LABEL_ROOM = 4 -- the label (and a hover line) end at least this far before the icon
local TITLE_BAND = 16 -- a titled bare row's title line, 6 down its cell
local BLOCK_LINE = 24 -- a position block's first line (its dropdowns), 6 down its cell
-- Rows with no value of their own to reset: the field is left alone on them.
local NO_DEFAULT = { execute = true, description = true }

-- How far left region draws (in its own units): itself, and every part of
-- it shown, its regions and its children's, down the tree. Under Blizzard a
-- control's art reaches past its frame (a dropdown's glow, the check box's
-- art), and the icon keeps clear of it.
local DrawnLeft
-- The regions or children as varargs, so no table is made per region.
local function DrawnLeftOf(left, ...)
	for i = 1, select('#', ...) do left = DrawnLeft(select(i, ...), left) end
	return left
end
DrawnLeft = function(region, left)
	if not region:IsShown() then return left end
	local l = region:GetLeft()
	if l and (not left or l < left) then left = l end
	if region.GetRegions then
		left = DrawnLeftOf(left, region:GetRegions())
		left = DrawnLeftOf(left, region:GetChildren())
	end
	return left
end

-- The default in words, for the icon's tooltip: the field's text, or its
-- value named by the row's type (a color's hex, with its opacity when the
-- row hasAlpha, as its field writes it; on or off; a select's label; a percent
-- range as a percent; a string or a number as it is), or nil.
local function DefaultText(body, row, state)
	if state.text then return state.text end
	local value = state.value
	if not (value and value.n > 0) then return nil end
	local first = value[1]
	if row.type == 'color' then
		local hasAlpha = OM.Member(body.root, row, 'hasAlpha') and true or false
		return W.HexText(value[1] or 0, value[2] or 0, value[3] or 0, value[4] or 1, hasAlpha)
	elseif row.type == 'toggle' or row.type == 'item' then
		return first and 'on' or 'off'
	elseif row.type == 'font' then
		-- A font row's default is a shared font's key (named, never as a file
		-- path), a typeface table or, on a face-only row, a face's name.
		if row.option.faceOnly and type(first) == 'string' and not st:IsSharedFont(first) then return first end
		return st:FontLabel(first)
	elseif row.type == 'select' and row.option.dialogControl == 'LSM30_Font' then
		return tostring(first) -- a font list is labeled by its names (name -> file)
	elseif row.type == 'select' then
		for _, entry in ipairs(OM.Values(body.root, row)) do
			if entry.key == first then return tostring(entry.name) end
		end
	elseif row.type == 'range' and type(first) == 'number' and OM.Member(body.root, row, 'isPercent') then
		return floor(first * 100 + 0.5) .. '%'
	elseif row.type == 'multiselect' then
		-- The ticked values' labels in the list's order, or none.
		local names = {}
		if type(first) == 'table' then
			for _, entry in ipairs(OM.Values(body.root, row)) do
				if first[entry.key] then names[#names + 1] = tostring(entry.name) end
			end
		end
		return #names > 0 and table.concat(names, ', ') or 'none'
	elseif row.type == 'input' then
		if first == nil or first == '' then return 'empty' end
	elseif row.type == 'keybinding' then
		if first == nil or first == '' then return 'Not bound' end
		return GetBindingText and GetBindingText(first) or tostring(first)
	elseif row.type == 'position' and type(first) == 'table' then
		local EM = st.EditModeFrames
		if not (EM and EM.CoordinatesText) then return nil end
		if row.option.target == 'select' then
			-- A unit frame part is anchored to an element of its unit frame, to a
			-- frame by name, or to the unit frame: say which.
			local at = {}
			for k, v in pairs(first) do at[k] = v end
			local parent
			if first.element then
				parent = tostring(first.element)
			elseif not first.frame then
				parent = 'the unit frame'
			end
			if parent then
				at.frame = '\0anchor'
				return EM.CoordinatesText(at, function() return parent end)
			end
		end
		return EM.CoordinatesText(first, EM.MoverNameOf)
	end
	if type(first) == 'string' or type(first) == 'number' then return tostring(first) end
end

-- The default in words for a row and its state (OM.DefaultState), for the tests.
function OB.DefaultWords(root, row, state)
	return DefaultText({ root = root }, row, state)
end

-- The icon's tooltip: Reset, then what it does and the default.
local function DefaultTip(owner, cell)
	if not cell then return end
	local row = cell.row
	local name = row.type == 'item' and (Possessive(row.name) .. ' Show') or row.name
	local text = DefaultText(cell.body, row, OM.DefaultState(cell.body.root, row) or {})
	Tip(owner, 'Reset', text and format('%s goes back to its default: %s.', name, text)
		or format('%s goes back to its default.', name))
end

--[[
	A setting's own reset (its option's reset source, optionsdefault.lua's
	OM.DefaultSource: a hand default field, a mover's Position, or a default
	derived from where the row is saved): the reset icon (ResetIcon, the hover
	line's piece and look) just left of the row's control, only while the value
	differs from its default (OM.DefaultDiffers, nothing else asked) and the row
	isn't disabled; its tooltip says what it does and names the default; a
	click runs the reset (OM.DefaultReset, no confirm), then the body's
	onChanged(true), which draws the page again, or onChanged(false, message)
	for a reset a validation refused. The body's PlaceRow calls this before
	OB.PlaceShare, and its Refresh again mid-drag, so the icon follows a
	dragged value.
	  - where: its right edge DEFAULT_GAP left of what the control draws
	    (DrawnLeft: under Blizzard its art, a dropdown's glow included),
	    centred on the row (on its first band for a taller row, a
	    multiselect's); an item's right against its dots, with no gap (their
	    button has room round its glyph, so the label gives up only the
	    icon and LABEL_ROOM), or DEFAULT_GAP left of the cell's right edge
	    without them; a position block, which has no label, has it after the
	    block on its first line.
	  - the label, and the hover line (cell.lineEnd), end LABEL_ROOM before it.
	  - a row whose share has own (a member page: its hover line's Reset
	    acts on it) never shows it: one reset per row, the share's. A
	    source page's row, whose line has no Reset, does.
	  - a titled custom type (W.Define's titled: the bags' rule) has it 6 after
	    its title's text, on the title's line, the title and its hover frame
	    cut to leave it room; any other custom type, an execute and a
	    description (no value) leave it alone.
	The icon is the row frame's (frame.defaultReset, made the first time a
	row needs one, hidden on every row that doesn't); frame.defaultCell is
	the cell it acts on.
]]
function OB.PlaceDefault(cell)
	local frame, body, row, widget = cell.frame, cell.body, cell.row, cell.widget
	if frame.defaultReset then frame.defaultReset:Hide() end
	frame.defaultCell = nil
	-- The label and the hover line end as the row drew them (PlaceRow's
	-- cell.labelWidth and ownLineEnd), the label less a share's room
	-- (cell.shareCut): what an icon took is given back while none shows.
	local label, cut = cell.label, cell.shareCut or 0
	if cell.labelWidth then label:SetWidth(max(1, cell.labelWidth - cut)) end
	-- A titled row's hover frame over its title is as wide as the whole title
	-- again (the icon cuts it below).
	local tip = frame.titleTip
	if tip and tip:IsShown() then tip:SetWidth(max(1, ceil(label:GetUnboundedStringWidth()))) end
	cell.lineEnd = cell.ownLineEnd
	if not (body and widget) or NO_DEFAULT[row.type] then return end
	-- A custom type (W.Define) has no control to put it by, except a titled
	-- bare row, whose title takes it.
	local custom = W.CUSTOM[row.type]
	if custom and not custom.titled then return end
	local share = row.option.share
	if type(share) == 'table' and share.own ~= nil then return end
	if widget:IsDisabled() then return end
	-- Whether it differs, and nothing else (no words, no value): asked for
	-- every row on every render. Without optionsdefault.lua, as before.
	local differs
	if OM.DefaultDiffers then
		differs = OM.DefaultDiffers(body.root, row)
	else
		local state = OM.DefaultState(body.root, row)
		differs = state and state.differs
	end
	if not differs then return end

	local icon = frame.defaultReset
	if not icon then
		icon = ResetIcon(frame, function(self) DefaultTip(self, frame.defaultCell) end, function()
			local at = frame.defaultCell
			if not at then return end
			local ok, message = OM.DefaultReset(at.body.root, at.row)
			if not at.body.onChanged then return end
			-- A reset that failed (a validation) says why on the status line, as a failed set does.
			if ok == false and message then at.body.onChanged(false, message) else at.body.onChanged(true) end
		end)
		frame.defaultReset = icon
	end
	frame.defaultCell = cell
	ResetAtRest(icon)
	icon:ClearAllPoints()
	icon:Show()
	if custom then
		-- A titled bare row: 6 after its title's text, centred on the title's
		-- band, the title cut to leave it room.
		local left = min(max(1, ceil(label:GetUnboundedStringWidth())) + DEFAULT_GAP, frame:GetWidth() - RESET_SIZE)
		icon:SetPoint('TOPLEFT', frame, 'TOPLEFT', left, -(6 + floor((TITLE_BAND - RESET_SIZE) / 2)))
		if cell.labelWidth then label:SetWidth(max(1, min(cell.labelWidth, left - LABEL_ROOM))) end
		-- The hover frame over the title must not cover the icon: it is cut as the title is.
		if tip and tip:IsShown() then tip:SetWidth(max(1, min(ceil(label:GetUnboundedStringWidth()), label:GetWidth()))) end
		return
	end
	if row.type == 'position' then
		icon:SetPoint('TOPLEFT', frame, 'TOPLEFT', ceil(widget:GetWidth()) + DEFAULT_GAP,
			-(6 + floor((BLOCK_LINE - RESET_SIZE) / 2)))
		return
	end
	local x0, right = frame:GetLeft(), nil
	if row.type == 'item' and widget.hasMenu then
		-- Right against the dots, whose button has room either side of its
		-- glyph: the label gives up only the icon and LABEL_ROOM.
		local dots = widget.dots:GetLeft()
		right = dots and x0 and floor(dots - x0 + 0.5) or (frame:GetWidth() - widget.dots:GetWidth())
	elseif row.type == 'item' then
		right = frame:GetWidth() - DEFAULT_GAP
	else
		local drawn = DrawnLeft(widget.frame)
		right = (drawn and x0 and floor(drawn - x0) or (frame:GetWidth() - widget:GetWidth())) - DEFAULT_GAP
	end
	if cell.height > cell.rowHeight then
		icon:SetPoint('RIGHT', frame, 'TOPLEFT', right, -floor(cell.rowHeight / 2))
	else
		icon:SetPoint('RIGHT', frame, 'LEFT', right, 0)
	end
	local stop = right - RESET_SIZE - LABEL_ROOM
	if cell.labelWidth then label:SetWidth(max(1, min(cell.labelWidth, stop - (cell.labelX or 0)) - cut)) end
	cell.lineEnd = min(cell.ownLineEnd or frame:GetWidth(), stop)
end
