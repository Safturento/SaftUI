local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The target's border on its nameplate, and the hovered plate's: a coloured
	line round the current target's health bar, so it stands out among the
	plates, and another round the plate under the cursor, so it's clear which
	unit a click will target. Under Thick and Thin it's the border st:SetBorderColor
	colours, in the plate config's target_color (white by default) or
	hover_color; under the Blizzard theme it's Blizzard's own target art (the
	control 'nameplatetarget', SaftUI-Core/themeart_data.lua), drawn round the
	bar on a frame of SaftUI's, tinted by the same colours.

	The hovered target keeps the target's look: hovering it changes nothing a
	click would. Hover can be turned off (hover_highlight). Each plate reads
	its own config, Enemy or Friendly nameplates' (frame.base_unit).

	The target's and the hovered plate are found by their frames
	(C_NamePlate.GetNamePlateForUnit of 'target' and 'mouseover'), never by
	UnitIsUnit, which the game may answer with a secret value for a unit on a
	plate. UPDATE_MOUSEOVER_UNIT says when the cursor comes onto a unit, but
	nothing says when it leaves, so while a plate is hovered a ticker looks
	again every HOVER_POLL seconds, and stops once nothing is.
]]

-- The colours when a plate's config has none.
local WHITE = { r = 1, g = 1, b = 1 }
local HOVER = { r = 0.4, g = 0.7, b = 1 }

-- How often, in seconds, the hovered plate is looked up while one is.
local HOVER_POLL = 0.05

-- The config a plate's frame is drawn from (Enemy or Friendly nameplates'),
-- or nil before it has one.
local function PlateConfig(frame)
	local key = frame.base_unit
	return key and UF:GetProfileConfig()[key] or nil
end

-- r, g, b of a config colour, else of fallback.
local function RGB(color, fallback)
	color = type(color) == 'table' and color or fallback
	return color.r or 1, color.g or 1, color.b or 1
end

-- Whether a plate's health bar carries the border: drawn, and shown by its
-- config. A bar its config has off (a friend's name-only plate, nameplates.lua)
-- keeps the drawing it had before, since UF:UpdateElement stops at an element
-- that's off, so its drawn theme alone can't tell.
local function BarCarriesBorder(frame)
	return frame.Health ~= nil and UF:ElementWanted(frame.Health) and st:DrawnTheme(frame.Health) ~= nil
end

-- The frame a plate's border is drawn on: the health bar's while the bar is
-- drawn and shown, else the plate frame's while that is drawn, else nil (a
-- name-only plate: no bar, and the frame None).
function UF.PlateBorderFrame(frame)
	if BarCarriesBorder(frame) then
		return st:DrawnFrame(frame.Health)
	end
	if st:DrawnTheme(frame) then
		return st:DrawnFrame(frame)
	end
end

-- Whether a plate's frame is on the current target's plate. A frame is a
-- child of its plate, so the target's plate is its parent; no target, or a
-- target with no plate SaftUI can see (the game gives none for a forbidden
-- plate), is no plate.
function UF:IsPlateTarget(frame)
	local plate = C_NamePlate.GetNamePlateForUnit('target')
	return plate ~= nil and frame:GetParent() == plate
end

-- The plate under the cursor, as last looked up: C_NamePlate's frame, or nil.
local hovered

-- Whether a plate's frame is on the plate under the cursor.
function UF:IsPlateHovered(frame)
	return hovered ~= nil and frame:GetParent() == hovered
end

-- The frame holding a plate's target art: a child of the plate's frame, two
-- levels over the health bar so the art lies over the bar and its box. Made
-- once, with its one texture (frame.texture), and kept by the plate's frame.
local arts = setmetatable({}, { __mode = 'k' })

function UF:PlateTargetArt(frame)
	local art = arts[frame]
	if art then return art end
	art = CreateFrame('Frame', nil, frame)
	art:SetAllPoints(frame.Health or frame)
	art:SetFrameLevel((frame.Health or frame):GetFrameLevel() + 2)
	art.texture = art:CreateTexture(nil, st.ThemeArt.Control('nameplatetarget').layer)
	-- Placed to the pixel by the theme's own anchors, so the art isn't snapped.
	art.texture:SetSnapToPixelGrid(false)
	art.texture:SetTexelSnappingBias(0)
	art:Hide()
	arts[frame] = art
	return art
end

-- The plate each drawn frame we colour belongs to, so a theme recolour or
-- redraw (which takes the colour off) puts it back: see st:SetBorderColor.
local borderOwners = setmetatable({}, { __mode = 'k' })

-- What the theme engine runs on a drawn frame after a recolor or redraw: the
-- target check of the plate it belongs to. One function for every frame, so
-- keeping it again on each update assigns the same value and makes nothing.
local function RecolorBorder(drawnFrame)
	local plate = borderOwners[drawnFrame]
	if plate then UF:UpdatePlateTarget(plate) end
end

local candidates = {}

-- Draws or clears the target's border on one plate, by the border frame's
-- drawn theme: Blizzard shows the art round the bar (or round the frame, when
-- the frame carries the border) and leaves the box its own colour; Thick and
-- Thin colour their line white on the target and the theme's own on the
-- others; None, and a name-only plate, draw nothing.
function UF:UpdatePlateTarget(frame)
	local art = self:PlateTargetArt(frame)
	local border = UF.PlateBorderFrame(frame)

	-- A border no longer the plate's (the bar's drawn theme changed to None, or
	-- back) must not keep the white.
	candidates[1], candidates[2] = frame.Health and st:DrawnFrame(frame.Health), st:DrawnFrame(frame)
	for i = 1, 2 do
		local candidate = candidates[i]
		if candidate then
			borderOwners[candidate] = frame
			st:KeepOwnColors(candidate, RecolorBorder)
			if candidate ~= border then st:SetBorderColor(candidate) end
		end
	end

	-- What the border goes round: the bar, or the frame (BarCarriesBorder).
	local source = BarCarriesBorder(frame) and frame.Health or frame
	local theme = border and st:DrawnTheme(source)
	if not theme then
		art:Hide()
		return
	end

	-- The look: the target's, else the hovered plate's (while hover is on),
	-- else none.
	local config = PlateConfig(frame)
	local r, g, b
	if self:IsPlateTarget(frame) then
		r, g, b = RGB(config and config.target_color, WHITE)
	elseif self:IsPlateHovered(frame) and not (config and config.hover_highlight == false) then
		r, g, b = RGB(config and config.hover_color, HOVER)
	end

	if theme == 'blizzard' then
		st:SetBorderColor(border)
		if r then
			local control = st.ThemeArt.Control('nameplatetarget')
			local texture = art.texture
			local left, top, right, bottom = unpack(control.offsets)
			texture:SetAtlas(control.atlas)
			-- White keeps Blizzard's own art; another colour tints it, on its
			-- grey so the atlas's own hue (Forever's is yellow) doesn't mix in.
			texture:SetDesaturated(not (r == 1 and g == 1 and b == 1))
			texture:SetVertexColor(r, g, b, 1)
			texture:ClearAllPoints()
			texture:SetPoint('TOPLEFT', source, 'TOPLEFT', left, top)
			texture:SetPoint('BOTTOMRIGHT', source, 'BOTTOMRIGHT', right, bottom)
			art:Show()
		else
			art:Hide()
		end
	else
		if r then
			st:SetBorderColor(border, r, g, b, 1)
		else
			st:SetBorderColor(border)
		end
		art:Hide()
	end
end

UF:RegisterPlateCallback('added', function(frame) UF:UpdatePlateTarget(frame) end)
UF:RegisterPlateCallback('updated', function(frame) UF:UpdatePlateTarget(frame) end)

-- Redraws the plates on the two given plates (C_NamePlate's frames).
local function UpdatePlatesOn(one, two)
	UF:ForEachPlate(function(frame)
		local plate = frame:GetParent()
		if plate ~= nil and (plate == one or plate == two) then UF:UpdatePlateTarget(frame) end
	end)
end

-- Looks the hovered plate up again; when it changed, redraws the plate it
-- left and the one it's on. The ticker runs only while a plate is hovered.
-- Whether either nameplate page has Highlight on hover on: off on both, the
-- ticker never runs.
local function HoverWanted()
	local profile = UF:GetProfileConfig()
	for _, key in ipairs({ 'nameplate', 'friendlynameplate' }) do
		local config = profile[key]
		if config and config.hover_highlight ~= false then return true end
	end
	return false
end

local ticker
local function CheckHover()
	local plate = HoverWanted() and C_NamePlate.GetNamePlateForUnit('mouseover') or nil
	if plate ~= hovered then
		local old = hovered
		hovered = plate
		UpdatePlatesOn(old, plate)
	end
	if hovered and not ticker then
		ticker = C_Timer.NewTicker(HOVER_POLL, CheckHover)
	elseif not hovered and ticker then
		ticker:Cancel()
		ticker = nil
	end
end

-- The target changed: every plate is checked again. The cursor came onto a
-- unit: the hovered plate is looked up.
local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_TARGET_CHANGED')
events:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
events:SetScript('OnEvent', function(_, event)
	if event == 'UPDATE_MOUSEOVER_UNIT' then
		CheckHover()
	else
		UF:ForEachPlate(function(frame) UF:UpdatePlateTarget(frame) end)
	end
end)
