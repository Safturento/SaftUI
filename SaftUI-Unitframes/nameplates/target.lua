local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The target's border on its nameplate: a bright line round the current
	target's health bar, so it stands out among the plates. Under Thick and Thin
	it's a white line (the border st:SetBorderColor colours); under the Blizzard
	theme it's Blizzard's own target art (the control 'nameplatetarget',
	SaftUI-Core/themeart.lua), drawn round the bar on a frame of SaftUI's.

	The target's plate is found by its frame (C_NamePlate.GetNamePlateForUnit),
	never by UnitIsUnit, which the game may answer with a secret value for a
	unit on a plate.
]]

-- The border's colour on the target under Thick and Thin.
local WHITE = { 1, 1, 1, 1 }

-- The frame a plate's border is drawn on: the health bar's while the bar is
-- drawn, else the plate frame's while that is drawn, else nil (both None).
function UF.PlateBorderFrame(frame)
	if frame.Health and st:DrawnTheme(frame.Health) then
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

-- The frame holding a plate's target art: a child of the plate's frame, two
-- levels over the health bar so the art lies over the bar and its box. Made
-- once, with its one texture (frame.texture), and kept by the plate's frame.
local arts = setmetatable({}, { __mode = 'k' })

function UF:PlateTargetArt(frame)
	local art = arts[frame]
	if art then return art end
	art = CreateFrame('Frame', nil, frame)
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

local function KeepBorder(drawnFrame)
	st:KeepOwnColors(drawnFrame, function(f)
		local plate = borderOwners[f]
		if plate then UF:UpdatePlateTarget(plate) end
	end)
end

-- Draws or clears the target's border on one plate, by the border frame's
-- drawn theme: Blizzard shows the art round the bar and leaves the box its
-- own colour; Thick and Thin colour their line white on the target and the
-- theme's own on the others; None draws nothing.
function UF:UpdatePlateTarget(frame)
	local art = self:PlateTargetArt(frame)
	local border = UF.PlateBorderFrame(frame)

	-- A border no longer the plate's (the bar's drawn theme changed to None, or
	-- back) must not keep the white.
	for _, candidate in ipairs({ frame.Health and st:DrawnFrame(frame.Health), st:DrawnFrame(frame) }) do
		if candidate then
			borderOwners[candidate] = frame
			KeepBorder(candidate)
			if candidate ~= border then st:SetBorderColor(candidate) end
		end
	end

	local source = (frame.Health and st:DrawnTheme(frame.Health)) and frame.Health or frame
	local theme = border and st:DrawnTheme(source)
	if not theme then
		art:Hide()
		return
	end

	local target = self:IsPlateTarget(frame)
	if theme == 'blizzard' then
		st:SetBorderColor(border)
		if target then
			local control = st.ThemeArt.Control('nameplatetarget')
			local texture = art.texture
			local left, top, right, bottom = unpack(control.offsets)
			texture:SetAtlas(control.atlas)
			texture:SetVertexColor(1, 1, 1, 1)
			texture:ClearAllPoints()
			texture:SetPoint('TOPLEFT', frame.Health, 'TOPLEFT', left, top)
			texture:SetPoint('BOTTOMRIGHT', frame.Health, 'BOTTOMRIGHT', right, bottom)
			art:Show()
		else
			art:Hide()
		end
	else
		if target then
			st:SetBorderColor(border, unpack(WHITE))
		else
			st:SetBorderColor(border)
		end
		art:Hide()
	end
end

UF:RegisterPlateCallback('added', function(frame) UF:UpdatePlateTarget(frame) end)
UF:RegisterPlateCallback('updated', function(frame) UF:UpdatePlateTarget(frame) end)

-- The target changed: every plate is checked again.
local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_TARGET_CHANGED')
events:SetScript('OnEvent', function()
	UF:ForEachPlate(function(frame) UF:UpdatePlateTarget(frame) end)
end)
