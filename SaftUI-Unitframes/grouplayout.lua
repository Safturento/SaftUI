local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The layout math of a group header (Blizzard's SecureGroupHeaderTemplate):
	where it puts its buttons and how big it makes itself. The party and raid
	headers (groups.lua) are given their attributes from it, their test mode
	previews (grouppreview.lua) are laid out with it, and so are the boss and
	arena frames, which are plain unit frames laid out the same way
	(UF:PlaceUnitFrame and UF:PlaceHolder, unitframes.lua). Nothing here
	makes, places or reads a frame.
]]

-- The header's 'point' and 'columnAnchorPoint' values SaftUI offers: one
-- frame or column grows away from the previous one's opposite side.
local GROWTH_POINTS = { TOP = true, BOTTOM = true, LEFT = true, RIGHT = true }

-- A copy of getRelativePointAnchor in Blizzard's SecureGroupHeaders.lua (it's
-- local there): the opposite point, and which way along each axis a point
-- grows.
local function GetRelativePointAnchor(point)
	point = point:upper()
	if point == 'TOP' then
		return 'BOTTOM', 0, -1
	elseif point == 'BOTTOM' then
		return 'TOP', 0, 1
	elseif point == 'LEFT' then
		return 'RIGHT', 1, 0
	elseif point == 'RIGHT' then
		return 'LEFT', -1, 0
	elseif point == 'TOPLEFT' then
		return 'BOTTOMRIGHT', 1, -1
	elseif point == 'TOPRIGHT' then
		return 'BOTTOMLEFT', -1, -1
	elseif point == 'BOTTOMLEFT' then
		return 'TOPRIGHT', 1, 1
	elseif point == 'BOTTOMRIGHT' then
		return 'TOPLEFT', -1, 1
	else
		return 'CENTER', 0, 0
	end
end

-- The group's layout config as header attribute values. config.growthDirection
-- is the header's 'point' and config.initialAnchor its 'columnAnchorPoint'.
-- The header adds xOffset/yOffset as they are, so they're signed here to make
-- spacing a gap whichever way the frames grow (unsigned, frames growing down
-- or left overlapped).
function UF.GetGroupLayout(config)
	local point = GROWTH_POINTS[config.growthDirection] and config.growthDirection or 'TOP'
	local _, xMult, yMult = GetRelativePointAnchor(point)
	local spacing = tonumber(config.spacing) or 0
	return {
		point = point,
		xOffset = spacing * xMult,
		yOffset = spacing * yMult,
		unitsPerColumn = math.max(1, tonumber(config.unitsPerColumn) or 5),
		maxColumns = math.max(1, tonumber(config.maxColumns) or 1),
		columnSpacing = tonumber(config.columnSpacing) or 0,
		columnAnchorPoint = GROWTH_POINTS[config.initialAnchor] and config.initialAnchor or 'LEFT',
		width = tonumber(config.width) or 0,
		height = tonumber(config.height) or 0,
	}
end

-- The layout of a unit's frames, from its config: party and raid's as
-- UF.GetGroupLayout reads it, boss's always one column holding every boss
-- frame, growing the way growthDirection says, spacing apart. Boss has no
-- column options, so a column key an old profile saved on it is ignored.
function UF.GetUnitGroupLayout(unit, config)
	local layout = UF.GetGroupLayout(config)
	if unit == 'boss' then
		layout.unitsPerColumn = math.huge
		layout.maxColumns = 1
		layout.columnSpacing = 0
		layout.columnAnchorPoint = 'LEFT'
	end
	return layout
end

-- The size the header gives itself for count members (the same sums as
-- configureChildren in SecureGroupHeaders.lua), its column length and column
-- count, and how many of the count it shows (maxColumns can cut it short).
function UF.GetGroupLayoutSize(layout, count)
	count = math.max(1, count)
	local _, xMult, yMult = GetRelativePointAnchor(layout.point)
	local unitsPerColumn, numColumns = layout.unitsPerColumn, 1
	if count > unitsPerColumn then
		numColumns = math.min(math.ceil(count / unitsPerColumn), layout.maxColumns)
	else
		unitsPerColumn = count
	end

	local w, h = layout.width, layout.height
	local width = math.abs(xMult) * (unitsPerColumn - 1) * w + (unitsPerColumn - 1) * (layout.xOffset * xMult) + w
	local height = math.abs(yMult) * (unitsPerColumn - 1) * h + (unitsPerColumn - 1) * (layout.yOffset * yMult) + h
	if numColumns > 1 then
		local _, colX, colY = GetRelativePointAnchor(layout.columnAnchorPoint)
		width = width + (numColumns - 1) * math.abs(colX) * (width + layout.columnSpacing)
		height = height + (numColumns - 1) * math.abs(colY) * (height + layout.columnSpacing)
	end
	return width, height, unitsPerColumn, numColumns, math.min(count, unitsPerColumn * numColumns)
end

-- The points that put frames[index] where configureChildren in
-- SecureGroupHeaders.lua puts a header's index-th button inside the header:
-- a list of { point, relativeTo, relativePoint, x, y }, relativeTo being the
-- container or an earlier frame of frames. Party and raid previews use it,
-- and so do boss and arena frames (UF:PlaceUnitFrame), which are plain unit
-- frames laid out the same way. unitsPerColumn and numColumns come from
-- UF.GetGroupLayoutSize. Returns nil for an index past unitsPerColumn *
-- numColumns: a header doesn't show those, so they have no place.
function UF.GroupAnchor(index, frames, container, layout, unitsPerColumn, numColumns)
	if index > unitsPerColumn * numColumns then return nil end
	local point = layout.point
	local relativePoint, xOffsetMult, yOffsetMult = GetRelativePointAnchor(point)
	local xMultiplier, yMultiplier = math.abs(xOffsetMult), math.abs(yOffsetMult)

	local columnAnchorPoint, columnRelPoint, colxMulti, colyMulti
	if numColumns > 1 then
		columnAnchorPoint = layout.columnAnchorPoint
		columnRelPoint, colxMulti, colyMulti = GetRelativePointAnchor(columnAnchorPoint)
	end

	local columnUnitCount = (index - 1) % unitsPerColumn + 1
	if index == 1 then
		local anchors = { { point, container, point, 0, 0 } }
		if columnAnchorPoint then
			anchors[2] = { columnAnchorPoint, container, columnAnchorPoint, 0, 0 }
		end
		return anchors
	elseif columnUnitCount == 1 then
		return { { columnAnchorPoint, frames[index - unitsPerColumn], columnRelPoint,
			colxMulti * layout.columnSpacing, colyMulti * layout.columnSpacing } }
	end
	return { { point, frames[index - 1], relativePoint,
		xMultiplier * layout.xOffset, yMultiplier * layout.yOffset } }
end
