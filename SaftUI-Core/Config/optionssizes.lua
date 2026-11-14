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
	      for a size the screen can't hold (OW.Fits, Ruling 4) and for no
	      change. Takes 'full' and 'half' for now. Saves size = 'half' (nil for
	      full) through S.SaveWindow, sets S.size, notes the row at the top of
	      the view (S.keepRow: OW.FirstInView, OW.OffsetFor put it back after the
	      rows have flowed again) and draws the window again once (OW:Render),
	      keeping its page, tab, pick and search. The corner is never touched:
	      the window is anchored by it, so only its left edge moves.
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
	(W.LookControl). Shrink shows at full, grow at half; shrink stays hidden at
	half until the bar exists (Ruling 5), though its place is kept, so grow sits
	where it will.
]]

local OW = st.OptionsWindow
local S = OW.S

local floor = math.floor

-- From optionswindow.lua.
local F, SaveWindow = S.F, S.SaveWindow
local CLOSE_RIGHT = S.CLOSE_RIGHT

local ARROW_GAP = 6 -- between the arrows, and between them and the close X
local ARROW_ICON = 20 -- a chevron 10 tall, drawn at twice its glyph
local GAP_TO_HEADER = 18 -- the drag strip stops this far short of the leftmost arrow
local GAP_TO_TITLE = 8 -- and the title's room this far

------------------------------------------------------------------ where the arrows are

-- Under Thick and Thin: how far in from the window's right edge the leftmost
-- arrow's left edge is at size: the close X's 16 in and its width, then each
-- arrow and the gap before it. At half the shrink arrow's place is counted
-- though it's hidden (Ruling 5), so the header and the title leave room for
-- the bar's arrow too.
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
	if size and not OW.Fits(S.layout, size, S.sidebar) then
		lines[#lines + 1] = { text = size == 'full' and 'The screen is too narrow for the full window.'
			or 'The screen is too narrow for this size.', red = true }
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
	if S.size == 'mini' then
		return WithReasons('Grow to half', 'The page in one column.', 'half')
	end
	return WithReasons('Grow to full', 'The page in two columns.', 'full')
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
-- size it goes to fits the screen. Run by every render, and by the picker
-- when it is shown or hidden.
function S.UpdateWindowButtons()
	if not F.shrink then return end
	local picker = S.ColorPickerShown()
	local function Enabled(step)
		local target = OW.NextSize(S.size, step)
		return target ~= nil and not picker and OW.Fits(S.layout, target, S.sidebar)
	end
	W.SetEnabled(F.shrink, Enabled(1))
	W.SetEnabled(F.grow, Enabled(-1))
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
	F.shrink:SetShown(S.size == 'full')
	F.grow:SetShown(S.size ~= 'full')
	W.LookControl(F.shrink, S.blizzard)
	W.LookControl(F.grow, S.blizzard)
	S.UpdateWindowButtons()
end

------------------------------------------------------------------ changing size

function OW:GetWindowSize()
	return S.size
end

function OW:SetWindowSize(size)
	if InCombatLockdown() or S.ColorPickerShown() then return false end
	if (size ~= 'full' and size ~= 'half') or size == S.size then return false end
	if not OW.Fits(S.layout, size, S.sidebar) then return false end
	SaveWindow({ size = size == 'half' and 'half' or S.UNSET })
	S.size = size
	if self:IsShown() then
		S.keepRow = { OW.FirstInView(OW.GetDrawnRows(), S.scrollOffset) }
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
