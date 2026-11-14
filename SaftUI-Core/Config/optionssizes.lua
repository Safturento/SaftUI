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

	The size buttons (F.shrink, F.grow): W.IconButton the close X's size, with
	a 16 Lucide icon in Text > Grey and the accent under the mouse (shrink
	wears minimize-2, grow maximize-2), each with its tooltip in the mockup's
	words and, while it is disabled, the reason in red (the color picker is
	open; the screen is too narrow). Shrink is at the left of the pair and
	grow at the right, beside the close X: [shrink][grow][X] at half and
	[shrink][X] at full (no empty slot), so the spot beside the close X is
	shrink at full and grow at half, and a click there toggles full and half.
	Under Thick and Thin they are 6 apart, right to left from the close X,
	top-aligned with it; under Blizzard on the title bar left of the metal's
	socket, centred on the close button, wearing Blizzard's own expand
	(grow) and condense (shrink) art (S.LookSizeButton, st.ThemeArt.Control(
	'sizebutton'), MaximizeMinimizeButtonFrameTemplate's atlases: normal,
	pushed and disabled, and the additive highlight) where the client has it,
	which is both clients today; on a client without it, in Blizzard's panel
	button (W.LookControl) with the Lucide icon. Shrink shows at full and half,
	grow at half; at the bar neither does.

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
local Draggable = S.Draggable
local Text, Grey = OB.Text, S.Grey

local MINI_GAP = 8 -- between the bar's parts
local MINI_LEFT = 12 -- the name, in from the bar's left

local ARROW_GAP = 6 -- between the arrows, and between them and the close X
local SIZE_ICON = 16 -- minimize-2 and maximize-2: a square glyph 12 across, drawn at 16 on the 24 button (whole 4 px margins)
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

------------------------------------------------------------------ Blizzard's art

-- The expand and condense art this client has (st.ThemeArt.Control('sizebutton')),
-- or nil where it has none: a client without it keeps the Lucide icon on Blizzard's
-- panel button (plan Ruling 17). Read at call time, as the client decides it.
local function HasAtlases(set)
	return set and C_Texture.GetAtlasInfo(set.normal) and C_Texture.GetAtlasInfo(set.pushed) and C_Texture.GetAtlasInfo(set.disabled)
end

local function SizeArt()
	local art = st.ThemeArt.Control('sizebutton')
	-- Every atlas, so a client lacking the pressed or disabled one or the
	-- highlight never draws a blank face in that state.
	if art and HasAtlases(art.grow) and HasAtlases(art.shrink) and C_Texture.GetAtlasInfo(art.highlight) then
		return art
	end
end

-- button -> its art: { face, glow, set, shown, down }. Textures of SaftUI's
-- own on SaftUI's own button, made the first time it wears the art: nothing of
-- Blizzard's template (its scripts, its frame) is instantiated.
local sizeArts = setmetatable({}, { __mode = 'k' })

-- Puts the art for the button's state on its face: pushed while the mouse is
-- down on an enabled button, disabled while it is disabled (and then no
-- highlight under the mouse), normal otherwise.
local function PaintSizeArt(button)
	local art = sizeArts[button]
	if not art or not art.shown then return end
	local set = art.set
	local atlas = set.normal
	if button.disabled then
		atlas = set.disabled
	elseif art.down then
		atlas = set.pushed
	end
	art.face:SetAtlas(atlas)
	art.glow:SetShown(not button.disabled)
end

local function MakeSizeArt(button)
	local art = {}
	-- ARTWORK, over the Box (a backdrop) and under the icon (OVERLAY), which is
	-- hidden while the art shows.
	art.face = button:CreateTexture(nil, 'ARTWORK')
	-- In the HIGHLIGHT layer, which the game shows only under the mouse.
	art.glow = button:CreateTexture(nil, 'HIGHLIGHT')
	sizeArts[button] = art
	button:HookScript('OnMouseDown', function(self)
		if not self.disabled then
			art.down = true
			PaintSizeArt(self)
		end
	end)
	button:HookScript('OnMouseUp', function(self)
		art.down = false
		PaintSizeArt(self)
	end)
	button:HookScript('OnHide', function(self)
		art.down = false
		PaintSizeArt(self)
	end)
	return art
end

-- The arrow's look: under Blizzard, where the client has the art, Blizzard's
-- expand (kind 'grow') or condense ('shrink') button drawn at the art's size,
-- centred on the button's square, its Box and icon hidden, its disabled art
-- while button.disabled; otherwise the Box and the Lucide icon (under
-- Blizzard on Blizzard's panel button, W.LookControl). The tooltip, the guard,
-- the disabled alpha and hoverIcon are the button's own and don't change.
function S.LookSizeButton(button, kind)
	local look = S.blizzard and SizeArt() or nil
	local art = sizeArts[button]
	if look then
		-- LookControl keeps the Box and panel button's state in step; the
		-- panel button it shows is hidden again under the art.
		W.LookControl(button, true)
		st:ShowPanelButton(button, false)
		art = art or MakeSizeArt(button)
		art.set, art.shown = look[kind], true
		for _, key in ipairs({ 'face', 'glow' }) do
			art[key]:ClearAllPoints()
			art[key]:SetSize(look.size, look.size)
			art[key]:SetPoint('CENTER', button, 'CENTER', 0, 0)
			art[key]:Show()
		end
		art.glow:SetAtlas(look.highlight)
		art.glow:SetBlendMode(look.highlightBlend)
		button.icon:Hide()
	else
		if art and art.shown then
			art.shown, art.down = false, false
			art.face:Hide()
			art.glow:Hide()
		end
		W.LookControl(button, S.blizzard)
		if S.blizzard then st:ShowPanelButton(button, true) end
		button.icon:Show()
	end
	PaintSizeArt(button)
end

------------------------------------------------------------------ the buttons

function S.BuildSizeButtons(window)
	local size = st.CLOSE_X_BUTTON_SIZE[1]
	F.shrink = W.IconButton(window, st.icons.minimize2, ShrinkTip, size, SIZE_ICON)
	F.shrink.onClick, F.shrink.hoverIcon = function() OW:Shrink() end, true
	F.grow = W.IconButton(window, st.icons.maximize2, GrowTip, size, SIZE_ICON)
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
		-- The bar and the way back from it to half are always allowed: half is
		-- the floor a screen that is too narrow falls back to (Ruling 4), as
		-- OW:Open does.
		return target ~= nil and not picker and (target == 'mini' or S.size == 'mini' or OW.Fits(S.layout, target, S.sidebar))
	end
	W.SetEnabled(F.shrink, Enabled(1))
	W.SetEnabled(F.grow, Enabled(-1))
	W.SetEnabled(F.miniGrow, Enabled(-1))
	for _, button in ipairs({ F.shrink, F.grow, F.miniGrow }) do PaintSizeArt(button) end
	if F.sideToggle then W.SetEnabled(F.sideToggle, S.SideToggleEnabled()) end
end

-- The arrows beside the close X (placed first by Relayout), in the look,
-- and which of them shows at the size.
function S.PlaceSizeButtons()
	local width = st.CLOSE_X_BUTTON_SIZE[1]
	-- Under Blizzard centred on the close button (28 tall on Forever, 24 on retail).
	local drop = S.blizzard and floor((st.ThemeArt.Close().size - width) / 2) or 0
	-- Grow sits beside the close X at half; at full shrink does, so the spot
	-- beside the X toggles full and half, and at half shrink is left of grow.
	F.grow:ClearAllPoints()
	F.grow:SetPoint('TOPRIGHT', F.close, 'TOPLEFT', -ARROW_GAP, -drop)
	F.shrink:ClearAllPoints()
	if S.size == 'half' then
		F.shrink:SetPoint('TOPRIGHT', F.grow, 'TOPLEFT', -ARROW_GAP, 0)
	else
		F.shrink:SetPoint('TOPRIGHT', F.close, 'TOPLEFT', -ARROW_GAP, -drop)
	end
	F.shrink:SetShown(S.size ~= 'mini')
	F.grow:SetShown(S.size == 'half')
	-- At the bar grow is the bar's own, 8 left of the close X, centred on the 42.
	F.miniGrow:ClearAllPoints()
	F.miniGrow:SetPoint('TOPRIGHT', F.mini, 'TOPRIGHT', -(MINI_PAD + MINI_GAP + floor(F.close:GetWidth() + 0.5)),
		-floor((OW.MINI_HEIGHT - width) / 2))
	S.LookSizeButton(F.shrink, 'shrink')
	S.LookSizeButton(F.grow, 'grow')
	S.LookSizeButton(F.miniGrow, 'grow')
	S.UpdateWindowButtons()
end

------------------------------------------------------------------ changing size

function OW:GetWindowSize()
	return S.size
end

-- What shrinking to the bar and the sidebar's toggle (optionsnav.lua) close:
-- an item's menu, the small dialog, a
-- dropdown's list, the keyboard in a box of the window's and the status line.
-- (A color picker can't be open: the guard refuses first. A confirm can't be
-- either: its catcher takes the click. A drag in the Categories list ends
-- with the page's widgets, which the bar's render releases.)
function S.CloseOverlays()
	OW:CloseMenu()
	OW:CloseDialog()
	W.CloseList()
	local focus = GetCurrentKeyBoardFocus()
	if focus and S.Inside(focus, F.window) then focus:ClearFocus() end
	S.ClosePop() -- the collapsed footer's search panel
	OW:SetStatus(nil)
	S.StopResize()
end

function OW:SetWindowSize(size)
	if InCombatLockdown() or S.ColorPickerShown() then return false end
	if size == S.size then return false end
	-- One step at a time: the bar is taken only from half.
	if size ~= OW.NextSize(S.size, 1) and size ~= OW.NextSize(S.size, -1) then return false end
	if size ~= 'mini' and S.size ~= 'mini' and not OW.Fits(S.layout, size, S.sidebar) then return false end
	local before = S.size
	if size == 'mini' then S.CloseOverlays() end
	-- A box of the window's keeps the keyboard no longer: the render rebinds its
	-- pooled box to another row, which would be typed into. Leaving a box puts
	-- back the value it was drawn with (as Esc does), so what was typed and not
	-- entered is lost.
	local focus = GetCurrentKeyBoardFocus()
	if focus and S.Inside(focus, F.window) then focus:ClearFocus() end
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
	Draggable(names) -- the window moves and its corner is saved, as the bar's
	names.dragged = false
	names:SetScript('OnMouseDown', function(self) self.dragged = false end)
	names:HookScript('OnDragStart', function(self) self.dragged = true end)
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

	F.miniGrow = W.IconButton(mini, st.icons.maximize2, MiniGrowTip, st.CLOSE_X_BUTTON_SIZE[1], SIZE_ICON)
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
	-- ceil, though widths are rounded elsewhere: a text's own width rounded down
	-- would cut its last letter to an ellipsis (as the tab row does).
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
