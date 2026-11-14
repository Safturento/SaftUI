local st = SaftUI
local W = st.OptionsWidgets

--[[
	The sizes of SaftUI's options window (st.OptionsWindow, optionswindow.lua):
	the header's arrows that move between them and the change itself. It loads
	after optionsresize.lua (Config/load.xml); optionswindow.lua calls it
	through OW.S. The sizes' numbers are optionslayout.lua's.

	  OW:GetWindowSize() -> 'full' | 'half' | 'mini'
	  OW:SetWindowSize(size) -> boolean
	      false in combat, while SaftUI's color picker is open (the body's
	      width change would close it under the player's hand: the guard wins),
	      for a size that isn't one step from the size now (the bar is taken
	      only from half), for a size the screen can't hold (OW.Fits, Ruling 4;
	      the bar is always narrow enough) and for no change. Saves size =
	      'half' (nil for full; the bar saves half) through S.SaveWindow, sets
	      S.size, and between full and half notes the row at the top of the view
	      (S.keepRow: OW.FirstInView, OW.OffsetFor put it back after the rows
	      have flowed again; half and the bar share a layout, so S.scrollOffset
	      alone comes back), and draws the window again once (OW:Render),
	      keeping its page, tab, pick and search. The corner is never touched:
	      the window is anchored by it, so only its left edge moves. Shrinking to
	      the bar first closes what is open over the window: an item's menu, the
	      small dialog, a dropdown's list; takes the keyboard from a box of the
	      window's; and clears the status line.
	  OW:Grow(), OW:Shrink() -> boolean
	      a step of OW.NextSize; nothing for OW.SIZE_GUARD seconds after the
	      size last changed (S.sizedAt), so a double click can't go on to the
	      next size.

	The arrows (F.grow, F.shrink): W.IconButton the close X's size, with a 20
	chevron in Text > Grey and the accent under the mouse, each with its
	tooltip in the mockup's words and, while it is disabled, the reason in red
	(the color picker is open; the screen is too narrow). Grow points left
	and sits at the left of the pair, shrink points right at the right, beside
	the close X: under Thick and Thin 6 apart, right to left from the close X,
	top-aligned with it; under Blizzard on the title bar left of the metal's
	socket, centred on the close button, in Blizzard's panel button
	(W.LookControl). Shrink shows at full and half, grow at half; at the bar
	neither does.

	The bar (F.mini, a frame over the whole window, shown only at the bar;
	S.BuildMini, S.DrawMini): the window made 42 tall (OW.MINI_HEIGHT) and as
	wide as its parts (OW.MiniLayout), drawn as a panel, with its sidebar, main
	column, footer, grip, edge, inner frame and title bar hidden. Left to
	right: F.miniBrand, "SaftUI" (OW.BrandText: Saft in the text colour, UI in
	the accent) in the mini font; F.miniPage, the page's name in group, Text >
	Grey; F.miniTab, the tab's name in field, Text > Grey (empty for a page
	with one tab; for a search the page is Search and the tab the text in
	quotes); F.miniGrow, the grow arrow ("Grow to half"); F.close, moved in, 8
	from the right. F.miniNames is a button over the page's and the tab's names:
	a click grows to half, a drag moves the window (a drag is no click, as edit
	mode's movers tell them apart), its tooltip names the path. Dragging the bar
	elsewhere moves it too. A text too wide for the bar is cut by its font
	string's width (the tab first, then the page), never past the bar.
]]

local OW = st.OptionsWindow
local S = OW.S
local OB = st.OptionsBody

local floor, ceil, max = math.floor, math.ceil, math.max

-- From optionswindow.lua.
local F, SaveWindow = S.F, S.SaveWindow
local CLOSE_RIGHT, MINI_PAD = S.CLOSE_RIGHT, S.MINI_PAD
local Draggable, SavePosition = S.Draggable, S.SavePosition
local Text, Grey = OB.Text, S.Grey

local MINI_GAP = 8 -- between the bar's parts
local MINI_LEFT = 12 -- the name, in from the bar's left

local ARROW_GAP = 6 -- between the arrows, and between them and the close X
local ARROW_ICON = 20 -- a chevron 10 tall, drawn at twice its glyph
local GAP_TO_HEADER = 18 -- the drag strip stops this far short of the leftmost arrow
local GAP_TO_TITLE = 8 -- and the title's room this far

------------------------------------------------------------------ where the arrows are

-- Under Thick and Thin: how far in from the window's right edge the leftmost
-- arrow's left edge is at size: the close X's 16 in and its width, then each
-- arrow and the gap before it (shrink at full; shrink and grow at half).
function S.ArrowsLeft(size)
	local width = st.CLOSE_X_BUTTON_SIZE[1]
	local arrows = size == 'full' and 1 or 2
	return CLOSE_RIGHT + width + arrows * (ARROW_GAP + width)
end

S.ARROW_GAP_TO_HEADER, S.ARROW_GAP_TO_TITLE = GAP_TO_HEADER, GAP_TO_TITLE

------------------------------------------------------------------ the tooltips

-- The red lines that say why the arrow to size does nothing now.
local function Reasons(size)
	local lines = {}
	if S.ColorPickerShown() then
		lines[#lines + 1] = { text = 'Close the color picker first.', red = true }
	end
	if size == 'full' and not OW.Fits(S.layout, size, S.sidebar) then
		lines[#lines + 1] = { text = 'The screen is too narrow for the full window.', red = true }
	end
	return lines
end

local function WithReasons(title, line, size)
	local lines = { line }
	for _, reason in ipairs(Reasons(size)) do lines[#lines + 1] = reason end
	return title, lines
end

local function ShrinkTip()
	if S.size == 'full' then
		return WithReasons('Shrink to half', "The page in one column. The window's right edge stays.", 'half')
	end
	return WithReasons('Shrink to a bar', 'A small bar, to see the whole UI. It keeps the page.', 'mini')
end

local function GrowTip()
	return WithReasons('Grow to full', 'The page in two columns.', 'full')
end

-- The bar's grow arrow.
local function MiniGrowTip()
	return WithReasons('Grow to half', 'Back to the page as you left it.', 'half')
end

------------------------------------------------------------------ the buttons

function S.BuildSizeButtons(window)
	local size = st.CLOSE_X_BUTTON_SIZE[1]
	F.shrink = W.IconButton(window, st.icons.chevronRight, ShrinkTip, size, ARROW_ICON)
	F.shrink.onClick, F.shrink.hoverIcon = function() OW:Shrink() end, true
	F.grow = W.IconButton(window, st.icons.chevronLeft, GrowTip, size, ARROW_ICON)
	F.grow.onClick, F.grow.hoverIcon = function() OW:Grow() end, true
	F.shrink:Hide()
	F.grow:Hide()
	-- Over the title bar, as the close X is, so a click reaches them.
	F.shrink:SetFrameLevel(F.close:GetFrameLevel())
	F.grow:SetFrameLevel(F.close:GetFrameLevel())
end

-- Each arrow's enabled state: by SaftUI's color picker and by whether the
-- size it goes to fits the screen (the bar always does). Run by every render,
-- and by the picker when it is shown or hidden.
function S.UpdateWindowButtons()
	if not F.shrink then return end
	local picker = S.ColorPickerShown()
	local function Enabled(step)
		local target = OW.NextSize(S.size, step)
		return target ~= nil and not picker and (target == 'mini' or OW.Fits(S.layout, target, S.sidebar))
	end
	W.SetEnabled(F.shrink, Enabled(1))
	W.SetEnabled(F.grow, Enabled(-1))
	W.SetEnabled(F.miniGrow, Enabled(-1))
end

-- The arrows beside the close X (placed first by Relayout), in the look,
-- and which of them shows at the size.
function S.PlaceSizeButtons()
	local width = st.CLOSE_X_BUTTON_SIZE[1]
	-- Under Blizzard centred on the close button (28 tall on Forever, 24 on retail).
	local drop = S.blizzard and floor((st.ThemeArt.Close().size - width) / 2) or 0
	F.shrink:ClearAllPoints()
	F.shrink:SetPoint('TOPRIGHT', F.close, 'TOPLEFT', -ARROW_GAP, -drop)
	F.grow:ClearAllPoints()
	F.grow:SetPoint('TOPRIGHT', F.shrink, 'TOPLEFT', -ARROW_GAP, 0)
	F.shrink:SetShown(S.size ~= 'mini')
	F.grow:SetShown(S.size == 'half')
	-- At the bar grow is the bar's own, 8 left of the close X, centred on the 42.
	F.miniGrow:ClearAllPoints()
	F.miniGrow:SetPoint('TOPRIGHT', F.mini, 'TOPRIGHT', -(MINI_PAD + MINI_GAP + floor(F.close:GetWidth() + 0.5)),
		-floor((OW.MINI_HEIGHT - width) / 2))
	W.LookControl(F.shrink, S.blizzard)
	W.LookControl(F.grow, S.blizzard)
	W.LookControl(F.miniGrow, S.blizzard)
	S.UpdateWindowButtons()
end

------------------------------------------------------------------ changing size

function OW:GetWindowSize()
	return S.size
end

-- What shrinking to the bar closes: an item's menu, the small dialog, a
-- dropdown's list, the keyboard in a box of the window's and the status line.
-- (A color picker can't be open: the guard refuses first. A confirm can't be
-- either: its catcher takes the click. A drag in the Categories list ends
-- with the page's widgets, which the bar's render releases.)
local function CloseOverlays()
	OW:CloseMenu()
	OW:CloseDialog()
	W.CloseList()
	local focus = GetCurrentKeyBoardFocus()
	if focus and S.Inside(focus, F.window) then focus:ClearFocus() end
	OW:SetStatus(nil)
	S.StopResize()
end

function OW:SetWindowSize(size)
	if InCombatLockdown() or S.ColorPickerShown() then return false end
	if size == S.size then return false end
	-- One step at a time: the bar is taken only from half.
	if size ~= OW.NextSize(S.size, 1) and size ~= OW.NextSize(S.size, -1) then return false end
	if size ~= 'mini' and not OW.Fits(S.layout, size, S.sidebar) then return false end
	local before = S.size
	if size == 'mini' then CloseOverlays() end
	-- The bar saves half: it opens again as half.
	SaveWindow({ size = size == 'full' and S.UNSET or 'half' })
	S.size = size
	if self:IsShown() then
		-- Between full and half the rows flow again: the first in view stays so.
		-- Half and the bar share a layout, so the offset itself comes back.
		if before ~= 'mini' and size ~= 'mini' then
			S.keepRow = { OW.FirstInView(OW.GetDrawnRows(), S.scrollOffset) }
		end
		self:Render()
	end
	S.sizedAt = GetTime()
	return true
end

-- Whether a size button was used a moment ago (OW.SIZE_GUARD).
local function Guarded()
	return S.sizedAt ~= nil and GetTime() - S.sizedAt < OW.SIZE_GUARD
end

function OW:Grow()
	if Guarded() then return false end
	local size = OW.NextSize(S.size, -1)
	return size ~= nil and self:SetWindowSize(size)
end

function OW:Shrink()
	if Guarded() then return false end
	local size = OW.NextSize(S.size, 1)
	return size ~= nil and self:SetWindowSize(size)
end

------------------------------------------------------------------ the bar

-- The bar's parts (S.BuildMini; Relayout shows the frame at the bar and
-- places the window, S.DrawMini the texts and the width).
function S.BuildMini(window)
	-- Over the whole window, under the close X and over the window's other
	-- frames, which are hidden at the bar. It moves the window.
	local mini = CreateFrame('Frame', nil, window)
	mini:SetAllPoints(window)
	mini:Hide()
	Draggable(mini)
	F.mini = mini

	F.miniBrand = Text(mini, 'mini')
	F.miniPage = Text(mini, 'group')
	F.miniTab = Text(mini, 'field')
	F.miniPage:SetTextColor(Grey())
	F.miniTab:SetTextColor(Grey())

	-- Over the page's and the tab's names: a click grows the bar to half, a
	-- drag moves the window and is no click (as edit mode's movers: the game can
	-- send a click at the end of a drag).
	local names = CreateFrame('Button', nil, mini)
	names:EnableMouse(true)
	names:RegisterForClicks('LeftButtonUp')
	names:RegisterForDrag('LeftButton')
	names.dragged = false
	names:SetScript('OnMouseDown', function(self) self.dragged = false end)
	names:SetScript('OnDragStart', function(self)
		self.dragged = true
		F.window:StartMoving()
	end)
	names:SetScript('OnDragStop', function()
		F.window:StopMovingOrSizing()
		SavePosition()
	end)
	names:SetScript('OnClick', function(self)
		if self.dragged then return end
		OW:Grow()
	end)
	-- The game calls these with the mouse's motion too: they take only self.
	names:SetScript('OnEnter', function(self)
		W.ShowTip(self, S.miniPath or st.name, { 'Click to grow to half. Drag to move.' })
	end)
	names:SetScript('OnLeave', function(self) W.HideTip(self) end)
	F.miniNames = names

	F.miniGrow = W.IconButton(mini, st.icons.chevronLeft, MiniGrowTip, st.CLOSE_X_BUTTON_SIZE[1], ARROW_ICON)
	F.miniGrow.onClick, F.miniGrow.hoverIcon = function() OW:Grow() end, true
end

-- The bar's texts and width: the name, the page's name, the tab's name ('' for
-- none) and path (the tooltip's), laid out by OW.MiniLayout from their widths
-- and the buttons'. A text that doesn't fit is cut by its font string's width.
function S.DrawMini(page, tab, path)
	local function Whole(value) return floor(value + 0.5) end
	S.miniPath = path
	-- The name is measured plain: the game doesn't count a color code's width.
	F.miniBrand:SetText(st.name)
	local brand = ceil(F.miniBrand:GetUnboundedStringWidth())
	F.miniBrand:SetText(OW.BrandText())
	F.miniPage:SetText(page)
	F.miniTab:SetText(tab)
	local pageWidth, tabWidth = ceil(F.miniPage:GetUnboundedStringWidth()), ceil(F.miniTab:GetUnboundedStringWidth())
	local buttons = Whole(F.miniGrow:GetWidth()) + MINI_GAP + Whole(F.close:GetWidth())
	local pageShown, tabShown, width = OW.MiniLayout(brand, pageWidth, tabWidth, buttons)
	S.miniWidth = width
	F.window:SetSize(width, OW.MINI_HEIGHT)

	local x = MINI_LEFT
	F.miniBrand:ClearAllPoints()
	F.miniBrand:SetPoint('LEFT', F.mini, 'LEFT', x, 0)
	F.miniBrand:SetWidth(brand)
	x = x + brand + MINI_GAP
	local namesLeft = x
	F.miniPage:ClearAllPoints()
	F.miniPage:SetPoint('LEFT', F.mini, 'LEFT', x, 0)
	F.miniPage:SetShown(pageShown > 0)
	if pageShown > 0 then F.miniPage:SetWidth(pageShown) end
	x = x + pageShown
	F.miniTab:ClearAllPoints()
	F.miniTab:SetShown(tabShown > 0)
	if tabShown > 0 then
		x = x + MINI_GAP
		F.miniTab:SetPoint('LEFT', F.mini, 'LEFT', x, 0)
		F.miniTab:SetWidth(tabShown)
		x = x + tabShown
	end
	F.miniNames:ClearAllPoints()
	F.miniNames:SetPoint('TOPLEFT', F.mini, 'TOPLEFT', namesLeft, 0)
	F.miniNames:SetSize(max(1, x - namesLeft), OW.MINI_HEIGHT)
end
