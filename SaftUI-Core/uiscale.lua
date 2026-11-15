local st = SaftUI

-- The scale model: how big SaftUI draws, from the screen and the player's
-- choice, and the tokens every drawn line is measured in.
--
-- The model works in `k`: how many physical pixels one design pixel (a pixel
-- of a 1440p screen) takes. At k 1 a UIParent unit is a pixel, as SaftUI has
-- always drawn it. `st.pixel` is one pixel in UIParent's units (1 / k),
-- `st.lineWeight` how many pixels a line is (a whole number, 1 below k 1.5),
-- and `st.line` a line in UIParent's units. They are read back from UIParent
-- (UIScale:SetTokens), so they are what is drawn.
local UIScale = {}
st.UIScale = UIScale

UIScale.DESIGN_HEIGHT = 1440
UIScale.SNAP = 72 -- pixels either side of a whole multiple of 1440 (5%)
UIScale.FLOOR = 0.75 -- the automatic part's least
UIScale.SIZE = { min = 0.70, max = 1.50, step = 0.05 }
UIScale.MODES = { 'auto', 'pixel', 'game' } -- the Scale select's order
UIScale.DEFAULT = { mode = 'auto', size = 1 }

-- Until the first SetTokens: a unit is a pixel and a line is one.
st.pixel, st.lineWeight, st.line = 1, 1, 1

local floor, abs, max, min = math.floor, math.abs, math.max, math.min

local function IsMode(mode)
	for _, known in ipairs(UIScale.MODES) do
		if known == mode then return true end
	end
	return false
end

-- A number rounded to 1e-4, which is far below a pixel at any scale and takes
-- the float noise off a scale read back (3840 x 2160 measures 1.4999999999999998).
local function Trim(value)
	return floor(value * 10000 + 0.5) / 10000
end

-- The screen in physical pixels, { width, height }, or nil when the game
-- doesn't say. The one place the model reads the screen (the E1 and E2 seam).
function UIScale.ReadScreen()
	local width, height = GetPhysicalScreenSize()
	if type(width) ~= 'number' or type(height) ~= 'number' or width <= 0 or height <= 0 then
		return nil
	end
	return { width = width, height = height }
end

-- A saved choice as { mode, size }: a fresh table, whatever it was. Nothing
-- that isn't a choice is an error, and nothing is written to the table given.
function UIScale.Normalize(choice)
	local mode, size = UIScale.DEFAULT.mode, UIScale.DEFAULT.size
	if type(choice) == 'table' then
		if IsMode(choice.mode) then mode = choice.mode end
		if type(choice.size) == 'number' and choice.size == choice.size then size = choice.size end
	end
	return { mode = mode, size = size }
end

-- How many pixels a line is at k: k rounded to the whole pixel, from 1 up.
function UIScale.LineWeight(k)
	return max(1, floor(Trim(k) + 0.5))
end

-- The size's top for a screen: the largest step at or under 150% and under
-- what keeps the UI as tall as 768 units (H / (auto * 768)).
local function SizeMax(height, auto)
	local limit = min(UIScale.SIZE.max, height / (auto * 768))
	local size = UIScale.SIZE
	local steps = floor((limit - size.min) / size.step + 1e-9)
	return max(size.min, floor((size.min + steps * size.step) * 100 + 0.5) / 100)
end

-- What a choice makes of a screen: { mode, auto, size, k, uiScale, pixel,
-- lineWeight, line, width, height, unitsWide, unitsTall, sizeMax }. nil with
-- no screen, or in 'game' without a positive gameScale (the game's own UI
-- scale). Pure: it reads nothing and writes nothing.
function UIScale.Resolve(choice, screen, gameScale)
	if type(screen) ~= 'table' or type(screen.height) ~= 'number' or screen.height <= 0
		or type(screen.width) ~= 'number' or screen.width <= 0 then
		return nil
	end
	local picked = UIScale.Normalize(choice)
	local mode = picked.mode
	if mode == 'game' and not (type(gameScale) == 'number' and gameScale > 0) then
		return nil
	end
	local height, width = screen.height, screen.width

	-- Near a whole multiple of 1440 high the screen snaps to it, so a screen a
	-- few pixels off 1440 still draws at exactly 1.
	local n = floor(height / UIScale.DESIGN_HEIGHT + 0.5)
	local auto = (n >= 1 and abs(height - n * UIScale.DESIGN_HEIGHT) <= UIScale.SNAP) and n
		or height / UIScale.DESIGN_HEIGHT
	auto = max(auto, UIScale.FLOOR)

	local sizeMax = SizeMax(height, auto)
	local step = UIScale.SIZE.step
	local size = UIScale.SIZE.min + floor((picked.size - UIScale.SIZE.min) / step + 0.5) * step
	size = floor(size * 100 + 0.5) / 100
	size = max(UIScale.SIZE.min, min(size, sizeMax))

	local k, uiScale
	if mode == 'pixel' then
		k = 1
		uiScale = (768 / height) * k
	elseif mode == 'game' then
		k = gameScale * height / 768
		uiScale = gameScale
	else
		k = auto * size
		uiScale = (768 / height) * k
	end

	local pixel = 1 / k
	local lineWeight = UIScale.LineWeight(k)
	local unitsTall = 768 / uiScale
	return {
		mode = mode,
		auto = auto,
		size = size,
		k = k,
		uiScale = uiScale,
		pixel = pixel,
		lineWeight = lineWeight,
		line = lineWeight * pixel,
		width = width,
		height = height,
		unitsWide = width * unitsTall / height,
		unitsTall = unitsTall,
		sizeMax = sizeMax,
	}
end

-- Reads the tokens back from UIParent, so they are what is drawn (never what
-- was chosen: a set can wait for combat). Left as they are with no screen.
function UIScale:SetTokens()
	local pixel = st:GetPixelSize(UIParent)
	if not pixel then return st.pixel, st.lineWeight, st.line end
	st.pixel = pixel
	st.lineWeight = UIScale.LineWeight(1 / pixel)
	st.line = st.lineWeight * pixel
	return st.pixel, st.lineWeight, st.line
end

-- Sets UIParent's scale and the tokens, once, at login: pixel for pixel, as
-- SaftUI has always drawn. Nothing with no screen.
function UIScale:Start()
	local resolved = UIScale.Resolve({ mode = 'pixel' }, UIScale.ReadScreen())
	if not resolved then return end
	UIParent:SetScale(resolved.uiScale)
	UIScale:SetTokens()
end
