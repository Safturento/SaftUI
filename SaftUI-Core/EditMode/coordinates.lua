local st = SaftUI
local EM = st.EditModeFrames

--[[
	Coordinates: while the bar's Coordinates is on, the selected mover's position
	shows as a small label outside its outline, at the corner (or edge middle, or
	centre) the mover is anchored by: "Top left of the screen: 120, -330", or
	"Bottom to top of Bar 2: 0, 3" when its anchor is another mover's frame. During
	a drag it follows the drag's live offsets, for the dragged mover whether it is
	selected or not. It shows the stored position (as /sui's Position does), not
	where a margin-clamped frame shows.

	  EM.CoordinatesText(position, nameOf) -> string   the words, from a stored
	                           position ({ point, frame, rel_point, x_off, y_off });
	                           nameOf(ref) names the frame the position is
	                           anchored to, or gives nil
	  EM.MoverNameOf(ref) -> string | nil               the name of the mover
	                           whose frame is ref (an object or a global name)
	  EM.CoordinatesSpot(point, rect, width, height, screenWidth, screenTop, avoid) -> x, y
	                           the label's bottom left in UIParent units, whole;
	                           avoid (optional) is a rect { left, right, bottom }
	                           the label stays out of, as it stays under the
	                           screen's top (EM:BarRect, the docked bar's)
	  EM:UpdateCoordinates()                            shows, places or hides it
	  EM.coordinates                                    the label's frame (.text)

	It hides while Coordinates is off, with nothing selected or dragged, outside
	edit mode, in combat (as the bar does), and when the outline's rect can't be
	read (EM.GetOutlineRect gives nil, as for the Minimap's secret edges).

	While shown the label has an OnUpdate that looks again every 0.1 s (every
	frame in a drag), since /sui's Position block changes a position without any
	event; hidden, it has none.
]]

EM.COORD_GAP = 2

local LEVEL = 9600 -- over every mover (they climb to 9000), the bar and its floating window (9500), under the History list (9700)
local floor = math.floor

local function Round(v) return floor(v + 0.5) end

------------------------------------------------------------------ the words

local POINTS = {
	TOPLEFT = 'Top left', TOP = 'Top', TOPRIGHT = 'Top right',
	LEFT = 'Left', CENTER = 'Center', RIGHT = 'Right',
	BOTTOMLEFT = 'Bottom left', BOTTOM = 'Bottom', BOTTOMRIGHT = 'Bottom right',
}

local function Words(point)
	return POINTS[point] or tostring(point)
end

-- A number as one decimal at most, never -0.
local function Number(v)
	v = tonumber(v) or 0
	v = floor(v * 10 + 0.5) / 10
	if v == 0 then return '0' end
	return tostring(v)
end

function EM.CoordinatesText(position, nameOf)
	local point = position.point or 'CENTER'
	local rel_point = position.rel_point or point
	local ref = position.frame
	local parent
	if ref == nil or ref == 'UIParent' or ref == UIParent then
		parent = 'the screen'
	else
		parent = nameOf and nameOf(ref)
		if not parent then
			parent = type(ref) == 'string' and ref or (ref.GetName and ref:GetName()) or '?'
		end
	end
	local corner = Words(point)
	if rel_point ~= point then
		corner = corner .. ' to ' .. Words(rel_point):lower()
	end
	return ('%s of %s: %s, %s'):format(corner, parent, Number(position.x_off), Number(position.y_off))
end

-- The name of the mover whose frame is ref.
function EM.MoverNameOf(ref)
	local frame = st:ResolveFrame(ref)
	if not frame then return nil end
	for _, mover in pairs(EM.movers) do
		if mover.def.frame == frame then return EM.MoverName(mover) end
	end
	return nil
end

------------------------------------------------------------------ where it sits

-- Outside the outline at the mover's own point: a LEFT point lines the label's
-- left up with the outline's, a RIGHT point its right, and the rest centre it (a
-- plain LEFT or RIGHT puts it beside, COORD_GAP out); a TOP point puts it
-- COORD_GAP above, a BOTTOM point below, the rest centre it. Where that leaves
-- the screen (or goes under the bar: where avoid, the bar's rect, is over its
-- width the top is its bottom) the axis flips inside the outline, COORD_GAP in; a
-- centred axis can't flip. Whatever is left is clamped into the screen and
-- made whole.
function EM.CoordinatesSpot(point, rect, width, height, screenWidth, screenTop, avoid)
	local gap = EM.COORD_GAP
	local left, right, bottom, top = rect.left, rect.right, rect.bottom, rect.top
	local x, y, flipX, flipY

	if point == 'LEFT' then
		x, flipX = left - gap - width, left + gap
	elseif point == 'RIGHT' then
		x, flipX = right + gap, right - gap - width
	elseif point:find('LEFT', 1, true) then
		x, flipX = left, left + gap
	elseif point:find('RIGHT', 1, true) then
		x, flipX = right - width, right - gap - width
	else
		x = (left + right) / 2 - width / 2
	end
	if flipX and (x < 0 or x + width > screenWidth) then x = flipX end
	x = math.max(0, math.min(Round(x), Round(screenWidth - width)))

	-- Under the bar's rect while the label is across any of its width.
	if avoid and x < avoid.right and x + width > avoid.left then screenTop = math.min(screenTop, avoid.bottom) end

	if point:find('TOP', 1, true) then
		y, flipY = top + gap, top - gap - height
	elseif point:find('BOTTOM', 1, true) then
		y, flipY = bottom - gap - height, bottom + gap
	else
		y = (bottom + top) / 2 - height / 2
	end
	if flipY and (y < 0 or y + height > screenTop) then y = flipY end

	y = math.max(0, math.min(Round(y), Round(screenTop - height)))
	return x, y
end

------------------------------------------------------------------ the label

local frame

local function GetFrame()
	if frame then return frame end
	frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(LEVEL)
	frame:EnableMouse(false)
	frame.text = frame:CreateFontString(nil, 'OVERLAY')
	frame.text:SetFontObject(st:GetFont('pixel'))
	frame.text:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
	frame:Hide()
	-- The screen's size or scale changes where the label can sit.
	frame:RegisterEvent('UI_SCALE_CHANGED')
	frame:RegisterEvent('DISPLAY_SIZE_CHANGED')
	frame:SetScript('OnEvent', function() EM:UpdateCoordinates() end)
	EM.coordinates = frame
	return frame
end

local dragging -- the mover being dragged, if any

-- While the label is shown it looks again every TICK seconds (every frame during
-- a drag), because a position changed in /sui (the Position block's setters, a
-- reset), a resize or a new screen size tells edit mode nothing. It fires no
-- event: PositionChanged is for edit mode's own moves (the config refresh and the
-- history listen to it). A hidden label has no OnUpdate, so it costs nothing.
local TICK = 0.1
local since = 0

local function Tick(_, elapsed)
	if not dragging then
		since = since + (elapsed or 0)
		if since < TICK then return end
	end
	since = 0
	EM:UpdateCoordinates()
end

-- The position to name: the stored one, with a drag's live offsets.
local function PositionOf(mover)
	local pos = mover.def.getPosition()
	if not pos then return nil end
	local drag = mover.drag
	return {
		point = pos.point, rel_point = pos.rel_point, frame = pos.frame,
		x_off = drag and drag.x or pos.x_off, y_off = drag and drag.y or pos.y_off,
	}
end

function EM:UpdateCoordinates()
	local f = GetFrame()
	local mover = dragging or self.selected
	if not (self.active and self:GetSettings().coordinates and mover) or InCombatLockdown() then
		f:Hide()
		f:SetScript('OnUpdate', nil)
		return
	end
	local pos = PositionOf(mover)
	local l, r, b, t = EM.GetOutlineRect(mover)
	if not (pos and l) then
		f:Hide()
		f:SetScript('OnUpdate', nil)
		return
	end
	f.text:SetTextColor(st:Color('accent'):GetRGB())
	f.text:SetText(EM.CoordinatesText(pos, EM.MoverNameOf))
	-- Whole pixels up, as the kit sizes a label (optionscontrols.lua's LabelWidth:
	-- ceil of GetStringWidth), so the text is never cut.
	local width = math.max(1, math.ceil(f.text:GetStringWidth()))
	local height = math.max(1, math.ceil(f.text:GetStringHeight()))
	f:SetSize(width, height)
	local x, y = EM.CoordinatesSpot(pos.point or 'CENTER', { left = l, right = r, bottom = b, top = t },
		width, height, UIParent:GetWidth(), UIParent:GetHeight(), self:BarRect())
	f:ClearAllPoints()
	f:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, y)
	f:Show()
	if not f:GetScript('OnUpdate') then
		since = 0
		f:SetScript('OnUpdate', Tick)
	end
end

local function Update() EM:UpdateCoordinates() end

EM:On('Enabled', Update)
EM:On('Disabled', Update)
EM:On('Selected', Update)
EM:On('SettingsChanged', Update)
-- A color pass: the label, when it shows, takes the Accent (nothing else of it is a color).
EM:On('ColorsChanged', function(group)
	if group == 'accent' and frame and frame:IsShown() then
		frame.text:SetTextColor(st:Color('accent'):GetRGB())
	end
end)
EM:On('PositionChanged', Update)
EM:On('BarModeChanged', Update) -- the bar docked, detached, hidden or moved: what it covers at the top changed

-- A drag moves the frame every frame: Tick follows it without the throttle (the
-- drag's own OnUpdate, on the overlay, has run by then or runs next frame).
EM:On('DragStarted', function(mover)
	dragging = mover
	Update()
end)

EM:On('DragStopped', function(mover)
	if dragging == mover then dragging = nil end
	Update()
end)
