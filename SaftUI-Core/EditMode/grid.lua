local st = SaftUI
local EM = st.EditModeFrames

-- The alignment grid drawn behind the UI while edit mode is on. Two center
-- lines (UIParent's center) run vertically and horizontally, and the other
-- lines repeat outward from them every Grid size, so the center lines are
-- always grid lines. Snapping (snap.lua) uses the same lines through
-- EM.GridLinePositions and EM:GetGridCenter, so what's drawn is what snaps.

local CENTER_ALPHA = 0.9
local LINE_COLOR = { 1, 1, 1, 0.12 }

local gridFrame
local pool = {} -- line textures, reused between redraws

-- Every center + k*size (k any integer) from low to high, ascending. A size
-- under 1 would never end, so it gives just the center.
function EM.GridLinePositions(center, low, high, size)
	if size < 1 then return { center } end
	local positions = {}
	for k = math.ceil((low - center) / size), math.floor((high - center) / size) do
		positions[#positions + 1] = center + k * size
	end
	return positions
end

-- The grid's center in UIParent units, on a whole physical pixel. The drawn
-- center lines and the snap lines both come from here.
function EM:GetGridCenter()
	return st:RoundToPixel(UIParent:GetWidth() / 2, UIParent),
		st:RoundToPixel(UIParent:GetHeight() / 2, UIParent)
end

local Draw

local function GetGridFrame()
	if not gridFrame then
		gridFrame = st:CreateFrame('Frame', nil, UIParent)
		gridFrame:SetAllPoints(UIParent)
		gridFrame:SetFrameStrata('BACKGROUND') -- behind every frame, so they stay readable
		gridFrame:EnableMouse(false)
		-- The screen events can fire before UIParent has its new size, so the
		-- grid also redraws when its own size (UIParent's) changes.
		gridFrame:SetScript('OnSizeChanged', function()
			if gridFrame:IsShown() then Draw() end
		end)
		gridFrame:Hide()
		EM.gridFrame = gridFrame
	end
	return gridFrame
end

-- The next line texture from the pool, made on first use. Lines are handed out
-- by index, and DrawGrid hides the ones left over.
local function GetLine(index)
	local line = pool[index]
	if not line then
		line = gridFrame:CreateTexture(nil, 'BACKGROUND')
		pool[index] = line
	end
	line:ClearAllPoints()
	return line
end

function Draw()
	local settings = EM:GetSettings()
	local pixel = st:GetPixelSize(gridFrame) or 1
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	local cx, cy = EM:GetGridCenter()
	local size = settings.grid_size

	local blue = st.config.profile.colors.button.blue
	local centerR, centerG, centerB = blue:GetRGB()

	local used = 0
	local function Place(line, isCenter)
		if isCenter then
			line:SetColorTexture(centerR, centerG, centerB, CENTER_ALPHA)
		else
			line:SetColorTexture(unpack(LINE_COLOR))
		end
		line:Show()
	end

	-- Vertical lines run the full height, placed from the left edge. Each
	-- position is rounded to a physical pixel on its own, so a Grid size that
	-- isn't a whole number of pixels doesn't blur. The last line is kept on
	-- screen, not one pixel past the edge.
	for _, p in ipairs(EM.GridLinePositions(cx, 0, width, size)) do
		local x = math.min(st:RoundToPixel(p, UIParent), width - pixel)
		used = used + 1
		local line = GetLine(used)
		line:SetPoint('TOPLEFT', gridFrame, 'TOPLEFT', x, 0)
		line:SetPoint('BOTTOMLEFT', gridFrame, 'BOTTOMLEFT', x, 0)
		line:SetWidth(pixel)
		Place(line, p == cx)
	end

	-- Horizontal lines run the full width, placed from the bottom edge.
	for _, p in ipairs(EM.GridLinePositions(cy, 0, height, size)) do
		local y = math.min(st:RoundToPixel(p, UIParent), height - pixel)
		used = used + 1
		local line = GetLine(used)
		line:SetPoint('BOTTOMLEFT', gridFrame, 'BOTTOMLEFT', 0, y)
		line:SetPoint('BOTTOMRIGHT', gridFrame, 'BOTTOMRIGHT', 0, y)
		line:SetHeight(pixel)
		Place(line, p == cy)
	end

	for i = used + 1, #pool do
		pool[i]:Hide()
	end
end

-- Shows the grid while edit mode is on and Grid is enabled, redrawing it so it
-- follows Grid size and the screen's size and scale. Hides it otherwise.
function EM:UpdateGrid()
	local f = GetGridFrame()
	if self.active and self:GetSettings().grid then
		Draw()
		f:Show()
	else
		f:Hide()
	end
end

EM:On('Enabled', function() EM:UpdateGrid() end)
EM:On('Disabled', function() EM:UpdateGrid() end)
