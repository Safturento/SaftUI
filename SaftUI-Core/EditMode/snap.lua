local st = SaftUI
local EM = st.EditModeFrames

-- Snapping while a frame is dragged (EM:StartDrag / EM:UpdateDrag in
-- mover.lua). The drag's edges and center are pulled onto the nearest line
-- within reach, where the lines are the grid's and/or other movers' edges and
-- centers. It only corrects the drag's x/y offsets, in whole physical pixels
-- like any drag, and never touches the frame's anchor.

local SNAP_REACH = 8 -- UIParent units (physical pixels at SaftUI's scale)
EM.SNAP_REACH = SNAP_REACH

-- The correction to add to the drag so the closest edge lands on the closest
-- line within reach: line - edge for the smallest |line - edge|. A tie goes to
-- the earlier edge. 0 when no line is in reach.
function EM.SnapAxis(edges, lines, reach)
	local best, bestDist = 0, nil
	for _, edge in ipairs(edges) do
		for _, line in ipairs(lines) do
			local dist = math.abs(line - edge)
			if dist <= reach and (not bestDist or dist < bestDist) then
				best, bestDist = line - edge, dist
			end
		end
	end
	return best
end

-- The snap correction (sx, sy) for a frame dragged by (dx, dy). rect0 is
-- { left, right, bottom, top } where the frame was when the drag began, and
-- everything is in UIParent units. The edges tried are the dragged left,
-- center and right, and bottom, center and top.
function EM.SnapDrag(rect0, dx, dy, xLines, yLines, reach)
	local midX = (rect0.left + rect0.right) / 2
	local midY = (rect0.bottom + rect0.top) / 2
	local sx = EM.SnapAxis({ rect0.left + dx, midX + dx, rect0.right + dx }, xLines, reach)
	local sy = EM.SnapAxis({ rect0.bottom + dy, midY + dy, rect0.top + dy }, yLines, reach)
	return sx, sy
end

-- The new offset for a drag: the start offset plus the cursor delta d and the
-- snap correction s, both in UIParent units. ratio converts them to the
-- dragged frame's own units (UIParent scale / frame scale). Not rounded; the
-- caller rounds to a physical pixel.
function EM.SnappedOffset(x0, d, s, ratio)
	return x0 + (d + s) * ratio
end

-- A rect's left, right, bottom and top in UIParent units, or nil if the frame
-- has no position yet, any edge or scale is a secret value (a Blizzard frame,
-- like the Minimap, can report those), or UIParent's scale is 0.
local function GetRectInUI(f)
	local l, r, b, t = f:GetLeft(), f:GetRight(), f:GetBottom(), f:GetTop()
	local scale, uiScale = f:GetEffectiveScale(), UIParent:GetEffectiveScale()
	if not (l and r and b and t and scale and uiScale) or uiScale == 0 then return end
	if issecretvalue(l) or issecretvalue(r) or issecretvalue(b) or issecretvalue(t)
			or issecretvalue(scale) or issecretvalue(uiScale) then
		return
	end
	local k = scale / uiScale
	return l * k, r * k, b * k, t * k
end
EM.GetRectInUI = GetRectInUI

-- How far outside its rect an overlay draws its line. The overlay has a thick
-- SaftUI backdrop, which st:SetBackdrop places 2px outside the frame, and that
-- is also where a thick-bordered SaftUI frame's own border line sits. Snapping
-- measures this line, so the borders you see land on the grid lines and on
-- each other.
EM.OUTLINE_OUTSET = 2

-- A mover's outline (the line its overlay draws) in UIParent units, or nil.
-- Overlays are UIParent's children with no scale of their own, so the outset
-- is already in UIParent units.
function EM.GetOutlineRect(mover)
	local l, r, b, t = GetRectInUI(mover.overlay)
	if not l then return end
	local o = EM.OUTLINE_OUTSET
	return l - o, r + o, b - o, t + o
end

-- The vertical lines (xLines) and horizontal lines (yLines) the dragged mover
-- can snap to, in UIParent units. Computed once per drag.
--   Snap to grid:   the grid's lines across the screen.
--   Snap to frames: the screen's center lines, and the left/middle/right and
--                   bottom/middle/top of every other shown mover's outline
--                   that is on screen. Frames that move with the dragged one (anchored to
--                   it, or its children) are left out: they shift as it
--                   moves, so snapping to them would jitter.
function EM:GetSnapLines(mover)
	local settings = self:GetSettings()
	local xLines, yLines = {}, {}
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	local cx, cy = self:GetGridCenter()

	if settings.snap_grid then
		for _, p in ipairs(EM.GridLinePositions(cx, 0, width, settings.grid_size)) do
			xLines[#xLines + 1] = p
		end
		for _, p in ipairs(EM.GridLinePositions(cy, 0, height, settings.grid_size)) do
			yLines[#yLines + 1] = p
		end
	end

	if settings.snap_frames then
		xLines[#xLines + 1] = cx
		yLines[#yLines + 1] = cy
		for _, other in pairs(self.movers) do
			if other ~= mover and other.overlay:IsShown()
					and not st:MovesWith(other.def.frame, mover.def.frame) then
				local l, r, b, t = EM.GetOutlineRect(other)
				if l and r > 0 and l < width and t > 0 and b < height then
					xLines[#xLines + 1] = l
					xLines[#xLines + 1] = (l + r) / 2
					xLines[#xLines + 1] = r
					yLines[#yLines + 1] = b
					yLines[#yLines + 1] = (b + t) / 2
					yLines[#yLines + 1] = t
				end
			end
		end
	end

	return xLines, yLines
end
