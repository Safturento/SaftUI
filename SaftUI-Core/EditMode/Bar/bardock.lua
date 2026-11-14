local st = SaftUI
local EM = st.EditModeFrames

--[[
	Where the docked edit mode bar sits (bar.lua is the bar and its layout).

	  EM:PlaceBar() -> x       puts the bar against the top edge: TOPLEFT at x
	                           from UIParent's left, whole, in the middle of the
	                           top edge unless a place is saved, and never
	                           outside the screen edge margin
	  EM:SetBarX(x)            slides it: saves x (nil: back to the middle) and
	                           places it
	  EM:BarRect() -> rect     { left, right, bottom, top } in UIParent's units
	                           (from its bottom left) of what the bar covers:
	                           the frame and the line its backdrop draws round
	                           it (the theme's inset), flush with the screen's
	                           top; nil while it is floating, hidden or not built
	  EM:BarCoverHeight()      how far down from the screen's top the bar's
	                           rect reaches, 0 with no rect (what only needs a
	                           height reads this)
	  EM:SetupBarDock()        called once by EM:GetBar, when the frame exists

	Sliding. The bar takes the mouse and is dragged by its blank parts (its
	controls take their own: a drag that starts on one slides nothing). A drag
	moves it by how far the cursor has moved, along the top only, kept inside the
	screen margin, on whole pixels, from an OnUpdate that runs only while the
	drag does. It ends on OnDragStop, when OnUpdate finds the left button up (a
	mouse-up that was missed) and when the bar hides (combat, Exit); each saves
	the place it reached as st.config.global.editModeBar.dockX, whole, from
	UIParent's left (the account's, not the profile's; the floating window's
	place is x and y beside it). With none saved, or one that is not a number,
	the bar is in the middle and follows the screen. A saved place the screen no
	longer has is kept as it is and the bar is put inside the margin without
	rewriting it. No drag starts while a mover is dragged (the bar has let go
	of the mouse then, bar.lua). A double click on the bar's blank part (two
	left mouse-ups 0.3 s apart at most, neither the end of a drag) returns it to
	the middle and clears the saved place; it has no tooltip.

	'BarModeChanged' fires (no arguments) whenever what the bar covers changes,
	as it does when the bar detaches or docks: /sui and the Coordinates label
	keep clear of EM:BarRect.
]]

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

local function Whole(value) return floor(value + 0.5) end

------------------------------------------------------------------ the place

-- The profile-independent saved table: st.config.global.editModeBar.
local function Saved()
	local saved = st.config and st.config.global and st.config.global.editModeBar
	return type(saved) == 'table' and saved or nil
end

-- The x of the bar's left from UIParent's left in the middle of the top edge.
local function Middle(width)
	return floor((Whole(UIParent:GetWidth()) - width) / 2)
end

-- x moved inside the screen edge margin (st:GetScreenMargin; the left wins
-- where the bar is wider than the room), whole.
local function Inside(x, width)
	local left, right = st:GetScreenMargin(EM.bar)
	return max(min(x, floor(UIParent:GetWidth() - right - width)), ceil(left))
end

-- The saved x, whole, or nothing when none is saved or it is not a number.
local function SavedX()
	local saved = Saved()
	local x = saved and saved.dockX
	if type(x) == 'number' and x == x and math.abs(x) < 1e6 then return Whole(x) end
end

local placedX, placedWidth -- where the bar was last put, and how wide
local sliding -- { cursor, x, now } while the bar is dragged: the cursor and x it began at, and x now

-- The bar's x from the left of the screen as it is placed now.
function EM:PlaceBar()
	local frame = self:GetBar()
	local width = Whole(frame:GetWidth())
	local x = Inside(sliding and sliding.now or SavedX() or Middle(width), width)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x, 0)
	if x ~= placedX or width ~= placedWidth then
		placedX, placedWidth = x, width
		self:Fire('BarModeChanged')
	end
	return x
end

------------------------------------------------------------------ what it covers

function EM:BarRect()
	local bar = self.bar
	if not (bar and bar:IsShown()) or self:IsBarWindowed() or not placedX then return nil end
	local inset = st:ThemeInset('theme', 'theme', 'panel')
	local height = Whole(UIParent:GetHeight())
	return {
		left = placedX - inset, right = placedX + placedWidth + inset,
		bottom = height - EM.BAR.HEIGHT - inset, top = height,
	}
end

function EM:BarCoverHeight()
	local rect = self:BarRect()
	return rect and (rect.top - rect.bottom) or 0
end

------------------------------------------------------------------ sliding

local DOUBLE_CLICK = 0.3

local function CursorX() return (GetCursorPosition()) / UIParent:GetEffectiveScale() end

-- Saves x as the bar's place (nil: none, the middle) and places the bar.
function EM:SetBarX(x)
	local global = st.config.global
	if type(global.editModeBar) ~= 'table' then global.editModeBar = {} end
	global.editModeBar.dockX = x
	return self:PlaceBar()
end

local slid = false -- the press in progress was a drag, so its mouse-up is not a click
local lastUp -- when the last left mouse-up that was a click happened

local function EndSlide()
	if not sliding then return end
	local x = sliding.now
	sliding = nil
	EM.bar:SetScript('OnUpdate', nil)
	EM:SetBarX(x)
end

local moverDragging = false -- a mover is being dragged: no slide starts

-- The drag, each frame: the bar goes where the cursor's travel puts it.
local function Follow()
	if not sliding then return end
	if not IsMouseButtonDown('LeftButton') then return EndSlide() end
	local width = Whole(EM.bar:GetWidth())
	sliding.now = Inside(Whole(sliding.x + CursorX() - sliding.cursor), width)
	EM:PlaceBar()
end

local function StartSlide()
	local bar = EM.bar
	if sliding or moverDragging or InCombatLockdown() or EM:IsBarWindowed() then return end
	slid = true
	sliding = { cursor = CursorX(), x = placedX or 0, now = placedX or 0 }
	bar:SetScript('OnUpdate', Follow)
end

function EM:SetupBarDock()
	local bar = self.bar
	bar:RegisterForDrag('LeftButton')
	bar:SetScript('OnDragStart', StartSlide)
	bar:SetScript('OnDragStop', EndSlide)
	bar:HookScript('OnHide', EndSlide)
	bar:SetScript('OnMouseDown', function() slid = false end)
	bar:SetScript('OnMouseUp', function(_, button)
		if button ~= 'LeftButton' then return end
		if slid then
			slid, lastUp = false, nil
			return
		end
		local now = GetTime()
		if lastUp and now - lastUp <= DOUBLE_CLICK then
			lastUp = nil
			EM:SetBarX(nil)
		else
			lastUp = now
		end
	end)
	-- The margin changes where it can sit.
	hooksecurefunc(st, 'UpdateScreenMargin', function()
		if bar:IsShown() and not EM:IsBarWindowed() then EM:PlaceBar() end
	end)
end

EM:On('DragStarted', function() moverDragging = true end)
EM:On('DragStopped', function() moverDragging = false end)
EM:On('Disabled', function() moverDragging = false end)
