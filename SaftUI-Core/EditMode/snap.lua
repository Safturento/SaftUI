local st = SaftUI
local EM = st.EditModeFrames

-- Snapping while a frame is dragged (EM:StartDrag / EM:UpdateDrag in
-- mover.lua). The drag's edges and center are pulled onto the nearest line
-- within reach, where the lines are the grid's and/or other movers' edges and
-- centers. It only corrects the drag's x/y offsets, in whole physical pixels
-- like any drag, and never touches the frame's anchor.

local SNAP_REACH = 8 -- UIParent units (physical pixels at SaftUI's scale)
EM.SNAP_REACH = SNAP_REACH

-- How near a mover must be to the dragged one to be a snap target: the gap
-- between its outline and the dragged outline at most this, on each axis (0
-- when they overlap on it). Far movers' lines made a drag snap to things the
-- player couldn't relate to, since with dozens of movers some line is always
-- in reach; near ones still line up tops or sides across a gap of a few frames,
-- and 400 keeps SaftUI's own default player and target frames (311 apart across
-- the screen's center, tops level) lining up.
local SNAP_NEAR = 400 -- UIParent units
EM.SNAP_NEAR = SNAP_NEAR

-- The correction to add to the drag so the closest edge lands on the closest
-- line within reach: line - edge for the smallest |line - edge|. A tie goes to
-- the earlier edge. 0 when no line is in reach. Also returns which line it was
-- (its index in lines) and the edge's value, nil when none is in reach.
-- edges is { low, middle, high }. kinds (by line index, optional) says which
-- lines are the grid's ('grid'): a grid line is lined up by the frame's visible
-- border, so only the low and high edges try it (the middle is invisible), and
-- the high edge's border is the pixel before it, so it lands one pixel past the
-- line: the border pixel [line, line + pixel) is the grid line's own.
function EM.SnapAxis(edges, lines, reach, kinds, pixel)
	local best, bestDist, bestIndex, bestEdge = 0, nil, nil, nil
	for e, edge in ipairs(edges) do
		for i, line in ipairs(lines) do
			local skip = false
			if kinds and kinds[i] == 'grid' then
				if e == 2 then skip = true end
				if e == 3 then line = line + (pixel or 0) end
			end
			local dist = math.abs(line - edge)
			if not skip and dist <= reach and (not bestDist or dist < bestDist) then
				best, bestDist, bestIndex, bestEdge = line - edge, dist, i, edge
			end
		end
	end
	return best, bestIndex, bestEdge
end

-- The snap correction (sx, sy) for a frame dragged by (dx, dy). rect0 is
-- { left, right, bottom, top } where the frame was when the drag began, and
-- everything is in UIParent units. The edges tried are the dragged left,
-- center and right, and bottom, center and top. Also returns, for each axis,
-- the line it snapped to as { index = its place in the lines, line = its value }
-- (nil when that axis isn't snapped). xKinds and yKinds are SnapAxis's kinds
-- (NearLines' sources do: a source that is 'grid' is a grid line); pixel is a
-- physical pixel in UIParent units (default SaftUI's).
function EM.SnapDrag(rect0, dx, dy, xLines, yLines, reach, xKinds, yKinds, pixel)
	pixel = pixel or st:GetPixelSize(UIParent) or 1
	local midX = (rect0.left + rect0.right) / 2
	local midY = (rect0.bottom + rect0.top) / 2
	local sx, xi = EM.SnapAxis({ rect0.left + dx, midX + dx, rect0.right + dx }, xLines, reach, xKinds, pixel)
	local sy, yi = EM.SnapAxis({ rect0.bottom + dy, midY + dy, rect0.top + dy }, yLines, reach, yKinds, pixel)
	return sx, sy, xi and { index = xi, line = xLines[xi] }, yi and { index = yi, line = yLines[yi] }
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

-- How far outside its rect an overlay draws its line: SaftUI's theme's border
-- (2px under Thick, 1px under Thin). The overlay has a backdrop in SaftUI's
-- theme, which st:SetBackdrop places that far outside the frame, and that is
-- also where a SaftUI frame's own border line sits. Snapping measures this
-- line, so the borders you see land on the grid lines and on each other.
function EM.OutlineOutset()
	return st:ThemeInset('theme', 'solid', 'small')
end

-- A mover's outline (the line its overlay draws) in UIParent units, or nil.
-- Overlays are UIParent's children with no scale of their own, so the outset
-- is already in UIParent units.
function EM.GetOutlineRect(mover)
	local l, r, b, t = GetRectInUI(mover.overlay)
	if not l then return end
	local o = EM.OutlineOutset()
	return l - o, r + o, b - o, t + o
end

-- The lines a drag can snap to, in UIParent units, and the shown movers' outlines
-- they come from. Computed once per drag; EM.NearLines picks from them.
--   Snap to grid:   the grid's lines across the screen.
--   Snap to frames: the screen's center lines, and every other shown mover's
--                   outline that is on screen. Frames that move with the dragged
--                   one (anchored to it, or its children) are left out: they
--                   shift as it moves, so snapping to them would jitter.
-- Returns xLines and yLines (the grid's and the screen's center, which are
-- offered wherever the drag is), targets, a list of { left, right, bottom,
-- top }, and xKinds and yKinds, what each fixed line is: 'grid' or 'center'.
function EM:GetSnapTargets(mover)
	local settings = self:GetSettings()
	local xLines, yLines, targets, xKinds, yKinds = {}, {}, {}, {}, {}
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	local cx, cy = self:GetGridCenter()

	if settings.snap_grid then
		for _, p in ipairs(EM.GridLinePositions(cx, 0, width, settings.grid_size)) do
			xLines[#xLines + 1] = p
			xKinds[#xLines] = 'grid'
		end
		for _, p in ipairs(EM.GridLinePositions(cy, 0, height, settings.grid_size)) do
			yLines[#yLines + 1] = p
			yKinds[#yLines] = 'grid'
		end
	end

	if settings.snap_frames then
		xLines[#xLines + 1] = cx
		xKinds[#xLines] = 'center'
		yLines[#yLines + 1] = cy
		yKinds[#yLines] = 'center'
		for _, other in pairs(self.movers) do
			if other ~= mover and other.overlay:IsShown()
					and not st:MovesWith(other.def.frame, mover.def.frame) then
				local l, r, b, t = EM.GetOutlineRect(other)
				if l and r > 0 and l < width and t > 0 and b < height then
					targets[#targets + 1] = { left = l, right = r, bottom = b, top = t }
				end
			end
		end
	end

	return xLines, yLines, targets, xKinds, yKinds
end

-- Every line a drag could ever snap to: the fixed ones and each target's
-- left/middle/right and bottom/middle/top. Nothing in the game calls it (a drag
-- asks for GetSnapTargets and NearLines); the tests do, to see what could ever
-- be offered.
function EM:GetSnapLines(mover)
	local xLines, yLines, targets = self:GetSnapTargets(mover)
	for _, t in ipairs(targets) do
		xLines[#xLines + 1] = t.left
		xLines[#xLines + 1] = (t.left + t.right) / 2
		xLines[#xLines + 1] = t.right
		yLines[#yLines + 1] = t.bottom
		yLines[#yLines + 1] = (t.bottom + t.top) / 2
		yLines[#yLines + 1] = t.top
	end
	return xLines, yLines
end

-- The lines a drag is offered where it is: the fixed ones, and the edges and
-- center of each target mover that is near, meaning the gap between its outline
-- and the dragged outline (rect0 moved by dx, dy) is at most EM.SNAP_NEAR on
-- both axes. A mover across the screen is no target: its edges line up with the
-- drag's somewhere, and a drag that snaps to something the player can't relate
-- to is a drag that snaps to nothing. drag is mover.drag: rect0, xLines and
-- yLines (the fixed ones), xKinds, yKinds and targets.
-- Returns xLines and yLines, and xSources and ySources, each line's origin by
-- index: 'grid', 'center' or the target's rect.
local function Push(lines, sources, source, a, b, c)
	local n = #lines
	lines[n + 1], lines[n + 2], lines[n + 3] = a, b, c
	sources[n + 1], sources[n + 2], sources[n + 3] = source, source, source
end

function EM.NearLines(drag, dx, dy, near)
	near = near or SNAP_NEAR
	local rect0 = drag.rect0
	local l, r = rect0.left + dx, rect0.right + dx
	local b, t = rect0.bottom + dy, rect0.top + dy
	local xLines, yLines, xSources, ySources = {}, {}, {}, {}
	for i, v in ipairs(drag.xLines) do xLines[i], xSources[i] = v, drag.xKinds[i] end
	for i, v in ipairs(drag.yLines) do yLines[i], ySources[i] = v, drag.yKinds[i] end
	for _, o in ipairs(drag.targets) do
		if o.left - r <= near and l - o.right <= near
				and o.bottom - t <= near and b - o.top <= near then
			Push(xLines, xSources, o, o.left, (o.left + o.right) / 2, o.right)
			Push(yLines, ySources, o, o.bottom, (o.bottom + o.top) / 2, o.top)
		end
	end
	return xLines, yLines, xSources, ySources
end

------------------------------------------------------------------ guides

-- While a drag is snapped to a line from Snap to frames (a mover's edge or
-- middle, or the screen's center), a 1 physical pixel line in the accent
-- (the accent, as the grid's center lines) shows what it snapped to: along
-- the snapped line, from the far edge of the dragged outline to the far edge of
-- the target's (the screen's whole height or width for the center line). One
-- for each axis. Snap to grid draws none, the grid is on screen. They are
-- textures of a frame of this file's above the movers and under the bar, taking
-- no mouse, and not movers, so never targets.
local guideFrame, guides

local function GetGuides()
	if not guideFrame then
		guideFrame = st:CreateFrame('Frame', nil, UIParent)
		guideFrame:SetAllPoints(UIParent)
		guideFrame:SetFrameStrata('FULLSCREEN_DIALOG')
		guideFrame:SetFrameLevel(9100) -- over the movers' overlays (9000 at most, picker.lua), under the bar (EM.BAR.LEVEL, 9500)
		guideFrame:EnableMouse(false)
		guideFrame:Hide()
		guides = { x = guideFrame:CreateTexture(nil, 'OVERLAY'), y = guideFrame:CreateTexture(nil, 'OVERLAY') }
		EM.guideFrame, EM.snapGuides = guideFrame, guides
	end
	return guides
end

-- Hides both guides.
function EM:HideSnapGuides()
	if not guideFrame then return end
	guides.x:Hide()
	guides.y:Hide()
	guideFrame:Hide()
end

-- Shows the guides for a drag that ended up with its outline at rect (UIParent
-- units, where the drag put it), snapped to xHit and yHit (SnapDrag's, nil for
-- an axis not snapped) out of xSources and ySources (NearLines'). An axis whose
-- line the outline no longer lies on (the screen edge margin pulled it off) or
-- whose source is the grid shows none; none at all hides the frame.
function EM:UpdateSnapGuides(rect, xHit, yHit, xSources, ySources)
	if not rect or InCombatLockdown() then return self:HideSnapGuides() end
	local g = GetGuides()
	local pixel = st:GetPixelSize(guideFrame) or 1
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	local cr, cg, cb = st:Color('accent'):GetRGB()
	local any = false

	local function On(hit, sources, low, high)
		-- the edge the line was offered for is the one now on it
		local source = hit and sources[hit.index]
		if not source or source == 'grid' then return end
		local mid = (low + high) / 2
		local on = false
		for _, edge in ipairs({ low, mid, high }) do
			if math.abs(edge - hit.line) <= pixel then on = true end
		end
		if not on then return end
		return source
	end

	-- A line that is a target's right or top is lined up by the border's pixel
	-- before it (the grid's convention: a pixel [v, v + pixel) is the line's).
	local function IsHigh(hit, source, highKey)
		return source ~= 'center' and hit.line == source[highKey]
	end

	local function Place(texture, vertical, line, from, to, high)
		local at = math.max(st:RoundToPixel(line, UIParent) - (high and pixel or 0), 0)
		texture:ClearAllPoints()
		texture:SetColorTexture(cr, cg, cb, 1)
		if vertical then
			at = math.min(at, width - pixel)
			texture:SetPoint('BOTTOMLEFT', guideFrame, 'BOTTOMLEFT', at, from)
			texture:SetSize(pixel, math.max(to - from, pixel))
		else
			at = math.min(at, height - pixel)
			texture:SetPoint('BOTTOMLEFT', guideFrame, 'BOTTOMLEFT', from, at)
			texture:SetSize(math.max(to - from, pixel), pixel)
		end
		texture:Show()
		any = true
	end

	g.x:Hide()
	g.y:Hide()
	local source = On(xHit, xSources, rect.left, rect.right)
	if source == 'center' then
		Place(g.x, true, xHit.line, 0, height)
	elseif source then
		Place(g.x, true, xHit.line, math.min(rect.bottom, source.bottom), math.max(rect.top, source.top),
			IsHigh(xHit, source, 'right'))
	end
	source = On(yHit, ySources, rect.bottom, rect.top)
	if source == 'center' then
		Place(g.y, false, yHit.line, 0, width)
	elseif source then
		Place(g.y, false, yHit.line, math.min(rect.left, source.left), math.max(rect.right, source.right),
			IsHigh(yHit, source, 'top'))
	end
	guideFrame:SetShown(any)
end

EM:On('DragStopped', function() EM:HideSnapGuides() end)
