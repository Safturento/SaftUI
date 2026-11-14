local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody
local Kit = W.Kit
local History = EM.History
local Guard = EM.BarGuard

--[[
	The History list (barchanges.lua's History button opens it): the steps of
	edit mode's history, newest first, in a panel under the button.
	  EM.HISTORY = { WIDTH, PAD, ROW, ROWS, LEVEL, WHEEL }   the numbers
	  EM:GetHistoryList()      the frame, built on first use
	  EM:ToggleHistoryList(), EM:ShowHistoryList(), EM:HideHistoryList(),
	  EM:IsHistoryListShown()
	  EM:PlaceHistoryList()    anchors it: docked, its top right 6 under the
	                           History button's bottom right; floating, its top
	                           left 8 right of the window's top right, or its
	                           top right 8 left of the window's top left with no
	                           room (barwindow.lua; it closes when the bar docks
	                           or detaches)
	  EM:RefreshHistoryList()  rows, scroll bar and foot from the history again
	  EM.Ago(seconds)          'now' under 5, then '<n>s ago', '<n>m ago',
	                           '<n>h ago'

	The frame is in FULLSCREEN_DIALOG at level LEVEL, over the bar, drawn as a
	panel in the theme and kept inside the screen margin (st:KeepInScreenMargin).
	It is WIDTH wide, PAD in on every side: the title "History" (group font,
	Text > Grey), up to ROWS rows (ROW tall, a hairline between), and the foot,
	"Keep the last" with a number box for the history's length and "steps (up to
	1000)". Whole pixels throughout: every part is placed by its top left from
	the list's, a text is ceil(its width) wide, and the list's height is the sum
	of whole parts.

	A row is a step (index 1 to #steps) or, last, "Before these changes" (index
	0). Its parts, left to right: a 2px accent mark when it is the current step
	(History:Position()), the label (the field font; Text > Grey while the step is
	undone), a detail in the small font and Text > Grey ('undone', '<n>
	settings' for a bulk step, else how long ago), and a revert, a 14 square
	rotate-ccw link shown for an applied step whose History:CanRevert says
	something (true, or the reason it can't) and enabled only on true. A row under
	the mouse is filled at 25% accent (the dropdown list's rowHover art under
	Blizzard); a click on it goes to that point (EM:JumpToStep). It never reads a
	change's old (the first move of a mover that has no saved position has none):
	the label comes from History.Label.

	More than ROWS entries scroll: the wheel moves WHEEL rows, and OB.ScrollBar's
	narrow bar (Blizzard's minimal bar under that theme) is at the right, in the
	PAD. A tick of the list's own clock (once a second while it shows) keeps the
	'<n>s ago' current.

	It closes on Esc (a key catcher of its own, a child of the list, so it takes
	the key before /sui's and edit mode's; other keys go on to the game), on the
	History button again, when edit mode turns off and when combat starts. Clicks,
	reverts and the length box do nothing in combat (EM.BarGuard).
]]

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

EM.HISTORY = { WIDTH = 300, PAD = 12, ROW = 26, ROWS = 12, LEVEL = 9700, WHEEL = 3 }
local HL = EM.HISTORY

local MARK = 2            -- the current step's mark
local TEXT_X = 10         -- a row's label, in from its left
local REVERT = 14         -- the revert link
local EDGE_GAP = 6        -- the revert, in from the row's right
local DETAIL_GAP = 6      -- between the label, the detail and the revert
local TITLE_GAP = 8       -- under the title
local FOOT_GAP = 8        -- over the foot
local FOOT_HEIGHT = 26    -- the foot's line (its box is 22 tall in it)
local FOOT_BOX = 54       -- the length box's width
local FOOT_SPACE = 6      -- between the foot's parts
local BAR_X = 4           -- the flat scroll bar, right of the rows (in the PAD)
local BLIZZARD_BAR_X = 2  -- the track of Blizzard's, right of the rows

local list
local ROW_WIDTH = HL.WIDTH - 2 * HL.PAD

------------------------------------------------------------------ small things

-- How long ago: 'now' under 5 seconds, then whole seconds, minutes and hours.
function EM.Ago(seconds)
	if seconds < 5 then return 'now' end
	if seconds < 60 then return ('%ds ago'):format(floor(seconds)) end
	if seconds < 3600 then return ('%dm ago'):format(floor(seconds / 60)) end
	return ('%dh ago'):format(floor(seconds / 3600))
end

-- A text's whole width: the full width of what it says, not what a narrow
-- font string cuts it to.
local function Width(text)
	local full = text.GetUnboundedStringWidth and text:GetUnboundedStringWidth() or text:GetStringWidth()
	return ceil(full)
end

-- The top of a text centred in a band height tall, on a whole pixel.
local function Centre(text, height)
	return -floor((height - ceil(text:GetStringHeight())) / 2)
end

-- Puts a text at x from owner's left, centred in a band of height, width wide.
local function PlaceText(text, owner, x, top, height, width)
	text:SetWidth(width)
	text:SetHeight(ceil(text:GetStringHeight()))
	text:ClearAllPoints()
	text:SetPoint('TOPLEFT', owner, 'TOPLEFT', x, top + Centre(text, height))
end

------------------------------------------------------------------ the rows

local function PaintHover(row)
	row.hover:SetShown(row.hovered == true)
end

local function RowTip(row)
	local step = History:Steps()[row.index]
	if step then
		return tostring(History.Label(step)),
			{ 'Goes back to just after this step; the steps after it stay until you make a new change.' }
	end
	return EM.HISTORY_START,
		{ 'Goes back to before your first change here; the steps after it stay until you make a new change.' }
end

local function NewRow(i)
	local row = CreateFrame('Button', nil, list)
	row:SetSize(ROW_WIDTH, HL.ROW)
	row:EnableMouse(true)
	row.index = 0

	row.hover = row:CreateTexture(nil, 'BACKGROUND')
	row.hover:SetAllPoints(row)
	row.hover:Hide()

	row.mark = row:CreateTexture(nil, 'OVERLAY')
	row.mark:SetSize(MARK, HL.ROW - 1)
	row.mark:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, 0)
	row.mark:Hide()

	row.line = row:CreateTexture(nil, 'ARTWORK')
	row.line:SetHeight(1)
	row.line:SetPoint('BOTTOMLEFT', row, 'BOTTOMLEFT', 0, 0)
	row.line:SetPoint('BOTTOMRIGHT', row, 'BOTTOMRIGHT', 0, 0)

	row.label = OB.Text(row, 'field', 'LEFT')
	row.detail = OB.Text(row, 'small', 'LEFT')

	row.revert = W.IconLink(row, st.icons.rotateCcw, REVERT, function(link)
		if link.disabled then
			return 'Revert', { { text = link.why or "This can't be reverted.", red = true } }
		end
		return 'Revert', { 'Puts this change back on its own, as a new step. The ones after it stay.' }
	end)
	row.revert.row = row
	row.revert:SetPoint('TOPLEFT', row, 'TOPLEFT', ROW_WIDTH - EDGE_GAP - REVERT, -floor((HL.ROW - REVERT) / 2))
	row.revert.onClick = Guard(function(link) EM:RevertStep(link.row.index, link) end)

	row:SetScript('OnEnter', function(self)
		self.hovered = true
		PaintHover(self)
		local title, lines = RowTip(self)
		self.tipTitle = title
		W.ShowTip(self, title, lines)
	end)
	row:SetScript('OnLeave', function(self)
		self.hovered = false
		PaintHover(self)
		W.HideTip(self)
	end)
	row:SetScript('OnHide', function(self)
		self.hovered = false
		PaintHover(self)
	end)
	row:SetScript('OnClick', Guard(function(self) EM:JumpToStep(self.index, self) end))
	return row
end

------------------------------------------------------------------ the look

-- The list's colours and art for the theme in use: its rows' hover and marks,
-- the hairlines, the texts, the number box and the reverts.
local function LookList()
	local blizzard = W.BlizzardLook()
	list.blizzard = blizzard
	local look = blizzard and st.ThemeArt.Control('dropdown')
	list.title:SetTextColor(OB.Grey())
	list.foot1:SetTextColor(OB.Grey())
	list.foot2:SetTextColor(OB.Grey())
	W.LookNumberBox(list.box, blizzard)
	for _, row in ipairs(list.rows) do
		if blizzard then
			row.hover:SetAtlas(look.rowHover)
			row.hover:SetAlpha(1)
		else
			row.hover:SetColorTexture(OB.Blue())
			row.hover:SetAlpha(0.25)
		end
		row.mark:SetColorTexture(OB.Blue())
		row.line:SetColorTexture(unpack(OB.HAIRLINE))
		row.detail:SetTextColor(OB.Grey())
		W.LookControl(row.revert, blizzard)
	end
end

------------------------------------------------------------------ refreshing

-- The scroll bar for rows of total entries, shown shown at a time, from offset,
-- along the rows (top, in the list's y).
local function PlaceScrollBar(top, shown, total)
	local track = shown * HL.ROW
	local companion = OB.Companion(list.bar)
	if total > shown then
		if list.blizzard then
			list.bar:Hide()
			companion:Set(list, HL.WIDTH - HL.PAD + BLIZZARD_BAR_X, top, track, shown, total, list.offset)
		else
			companion:Hide()
			local size = max(10, floor(track * shown / total))
			list.bar:SetHeight(size)
			list.bar:ClearAllPoints()
			list.bar:SetPoint('TOPLEFT', list, 'TOPLEFT', HL.WIDTH - HL.PAD + BAR_X,
				-(top + floor((track - size) * list.offset / (total - shown))))
			list.bar:Show()
		end
	else
		companion:Hide()
		list.bar:Hide()
	end
end

-- A row from the step at its index (nil: the start), laid out for what it says.
local function FillRow(row, index, position, now)
	local step = History:Steps()[index]
	row.index = index
	local undone = index > position
	row.label:SetText(step and tostring(History.Label(step)) or EM.HISTORY_START)
	row.label:SetTextColor((undone and OB.Grey or OB.Normal)())
	local detail = ''
	if step then
		if undone then
			detail = 'undone'
		elseif step.kind == 'bulk' then
			detail = ('%d setting%s'):format(#step.changes, #step.changes == 1 and '' or 's')
		else
			detail = EM.Ago(now - (step.time or now))
		end
	end
	row.detail:SetText(detail)
	row.mark:SetShown(index == position)
	-- A tooltip showing under the mouse follows what the row now says.
	if row.hovered and GameTooltip:IsShown() and GameTooltip:IsOwned(row) then
		local title, lines = RowTip(row)
		if title ~= row.tipTitle then
			row.tipTitle = title
			W.ShowTip(row, title, lines)
		end
	end

	local revertX = ROW_WIDTH - EDGE_GAP - REVERT
	local detailWidth = Width(row.detail)
	local detailX = revertX - DETAIL_GAP - detailWidth
	PlaceText(row.detail, row, detailX, 0, HL.ROW, detailWidth)
	PlaceText(row.label, row, TEXT_X, 0, HL.ROW, max(0, detailX - DETAIL_GAP - TEXT_X))

	local ok, why = false, nil
	if step then ok, why = History:CanRevert(index) end
	row.revert:SetShown(ok or why ~= nil)
	row.revert.why = why
	W.SetEnabled(row.revert, ok)
end

-- The rows, the scroll bar, the foot and the list's height from the history.
function EM:RefreshHistoryList()
	if not list then return end
	local steps, position = History:Steps(), History:Position()
	local total = #steps + 1
	local shown = min(total, HL.ROWS)
	list.offset = max(0, min(total - shown, list.offset))
	local now = GetTime()

	local titleHeight = ceil(list.title:GetStringHeight())
	local top = HL.PAD + titleHeight + TITLE_GAP
	for i, row in ipairs(list.rows) do
		if i <= shown then
			FillRow(row, total - (list.offset + i), position, now)
			row:ClearAllPoints()
			row:SetPoint('TOPLEFT', list, 'TOPLEFT', HL.PAD, -(top + (i - 1) * HL.ROW))
			row.line:SetShown(i < shown)
			row:Show()
		else
			row:Hide()
		end
	end
	PlaceScrollBar(top, shown, total)

	local footTop = top + shown * HL.ROW + FOOT_GAP
	local x1 = HL.PAD
	local width1 = Width(list.foot1)
	PlaceText(list.foot1, list, x1, -footTop, FOOT_HEIGHT, width1)
	local boxX = x1 + width1 + FOOT_SPACE
	list.box:ClearAllPoints()
	list.box:SetPoint('TOPLEFT', list, 'TOPLEFT', boxX, -(footTop + floor((FOOT_HEIGHT - 22) / 2)))
	local x2 = boxX + FOOT_BOX + FOOT_SPACE
	PlaceText(list.foot2, list, x2, -footTop, FOOT_HEIGHT,
		max(0, min(Width(list.foot2), HL.WIDTH - HL.PAD - x2)))
	list.box:Refresh()

	list:SetSize(HL.WIDTH, footTop + FOOT_HEIGHT + HL.PAD)
end

------------------------------------------------------------------ the frame

local function ButtonRefresh()
	local control = EM:BarControl('history')
	if control then control:Refresh() end
end

local function Build()
	list = st:CreateFrame('Frame', nil, UIParent)
	EM.historyList = list
	list:SetFrameStrata('FULLSCREEN_DIALOG')
	list:SetFrameLevel(HL.LEVEL)
	list:SetSize(HL.WIDTH, 100)
	list:EnableMouse(true)
	list:EnableMouseWheel(true)
	list:Hide()
	st:SetBackdrop(list, 'theme', 'theme', 'panel')
	st:KeepInScreenMargin(list)
	list.offset = 0

	list.title = OB.Text(list, 'group', 'LEFT')
	list.title:SetText('History')
	list.title:SetWidth(ROW_WIDTH)
	list.title:SetPoint('TOPLEFT', list, 'TOPLEFT', HL.PAD, -HL.PAD)

	list.rows = {}
	list.bar = OB.ScrollBar(list, function(offset) list.set(offset) end, { narrow = true, step = 1, wheel = HL.WHEEL })
	for i = 1, HL.ROWS do list.rows[i] = NewRow(i) end

	list.foot1 = OB.Text(list, 'small', 'LEFT')
	list.foot1:SetText('Keep the last')
	list.foot2 = OB.Text(list, 'small', 'LEFT')
	list.foot2:SetText('steps (up to 1000)')
	list.box = W.NumberBox(list, {
		width = FOOT_BOX, min = EM.MIN_HISTORY, max = EM.MAX_HISTORY, step = 10,
		get = function() return History.limit end,
		set = Guard(function(n) EM:SetSetting('history_limit', n) end),
		tip = function()
			return 'Keep the last', { 'How many changes edit mode remembers, from 1 to 1000. Past that, the oldest are forgotten.' }
		end,
	})

	-- The scroll bar's callback and the wheel: whole rows.
	function list.set(offset)
		list.offset = floor(offset + 0.5)
		EM:RefreshHistoryList()
	end
	list:SetScript('OnMouseWheel', function(self, delta)
		list.set(self.offset - delta * HL.WHEEL)
	end)

	-- Esc: a catcher of its own, a child of the list.
	list.keys = CreateFrame('Frame', nil, list)
	list.keys:Hide()
	Kit.CatchKeys(list.keys, { ESCAPE = true }, function(key)
		if key == 'ESCAPE' then EM:HideHistoryList() end
	end)

	-- Combat ends it, as it ends edit mode.
	list:RegisterEvent('PLAYER_REGEN_DISABLED')
	list:SetScript('OnEvent', function(self) self:Hide() end)

	-- The ages tick over once a second while it shows.
	local waited = 0
	list:SetScript('OnUpdate', function(_, elapsed)
		waited = waited + elapsed
		if waited >= 1 then
			waited = 0
			EM:RefreshHistoryList()
		end
	end)
	list:SetScript('OnShow', function(self)
		self.keys:Show()
		LookList()
		EM:RefreshHistoryList()
		ButtonRefresh()
	end)
	list:SetScript('OnHide', function(self)
		self.keys:Hide()
		ButtonRefresh()
	end)

	LookList()
	return list
end

function EM:GetHistoryList()
	return list or Build()
end

function EM:IsHistoryListShown()
	return list ~= nil and list:IsShown()
end

local WINDOW_GAP = 8 -- beside the floating window

-- Docked: its top right 6 under the History button's bottom right. Floating:
-- its top left 8 right of the window's top right, or, where there is no room
-- on that side (inside the screen edge margin), its top right 8 left of the
-- window's top left; the game's clamp keeps the rest of it on the screen.
function EM:PlaceHistoryList()
	local control = EM:BarControl('history')
	if not (list and control) then return end
	list:ClearAllPoints()
	if EM:IsBarFloating() and EM.barWindow then
		local window = EM.barWindow
		local _, marginRight = st:GetScreenMargin(list)
		local right = window:GetRight()
		if right and right + WINDOW_GAP + HL.WIDTH > UIParent:GetRight() - marginRight then
			list:SetPoint('TOPRIGHT', window, 'TOPLEFT', -WINDOW_GAP, 0)
		else
			list:SetPoint('TOPLEFT', window, 'TOPRIGHT', WINDOW_GAP, 0)
		end
		return
	end
	list:SetPoint('TOPRIGHT', control.frame, 'BOTTOMRIGHT', 0, -6)
end

function EM:ShowHistoryList()
	EM:GetHistoryList()
	EM:PlaceHistoryList()
	list.offset = 0
	list:Show()
end

function EM:HideHistoryList()
	if list then list:Hide() end
end

function EM:ToggleHistoryList()
	if EM:IsHistoryListShown() then EM:HideHistoryList() else EM:ShowHistoryList() end
end

------------------------------------------------------------------ events

EM:On('HistoryChanged', function()
	if EM:IsHistoryListShown() then EM:RefreshHistoryList() end
end)
EM:On('SettingsChanged', function()
	if EM:IsHistoryListShown() then EM:RefreshHistoryList() end
end)
EM:On('ColorsChanged', function()
	if list then
		LookList()
		if list:IsShown() then EM:RefreshHistoryList() end
	end
end)
EM:On('Disabled', function() EM:HideHistoryList() end)
EM:On('BarLaid', function()
	if EM:IsHistoryListShown() then EM:PlaceHistoryList() end
end)
