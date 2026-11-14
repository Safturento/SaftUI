local st = SaftUI
local EM = st.EditModeFrames

--[[
	Where the docked edit mode bar sits (bar.lua is the bar and its layout).

	  EM:PlaceBar() -> x       puts the bar against the top edge: TOPLEFT at x
	                           from UIParent's left, whole, in the middle of the
	                           top edge unless a place is saved, and never
	                           outside the screen edge margin
	  EM:BarRect() -> rect     { left, right, bottom, top } in UIParent's units
	                           (from its bottom left) of what the bar covers:
	                           the frame and the line its backdrop draws round
	                           it (the theme's inset), flush with the screen's
	                           top; nil while it is floating, hidden or not built
	  EM:BarCoverHeight()      how far down from the screen's top the bar's
	                           rect reaches, 0 with no rect (what only needs a
	                           height reads this)
	  EM:SetupBarDock()        called once by EM:GetBar, when the frame exists

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

local placedX, placedWidth -- where the bar was last put, and how wide

-- The bar's x from the left of the screen as it is placed now.
function EM:PlaceBar()
	local frame = self:GetBar()
	local width = Whole(frame:GetWidth())
	local x = Inside(Middle(width), width)
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

function EM:SetupBarDock() end
