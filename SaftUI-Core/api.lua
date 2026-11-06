local st = SaftUI

function st:GetConfig(configUnit)
	return st.config.profile[configUnit]
end

function st:UnpackPoint(config)
	return config.point, config.frame, config.rel_point or config.point, config.x_off or 0, config.y_off or 0
end

-- Size of one physical pixel in frame's (or UIParent's) coordinate space, or nil if unknown.
function st:GetPixelSize(frame)
	local physicalHeight = select(2, GetPhysicalScreenSize())
	local scale = (frame or UIParent):GetEffectiveScale()
	if not physicalHeight or physicalHeight == 0 or not scale or scale == 0 then
		return nil
	end
	return (768 / physicalHeight) / scale
end

-- Rounds a value (in frame's coordinate space) to the nearest physical pixel.
function st:RoundToPixel(value, frame)
	local pixel = st:GetPixelSize(frame)
	if not pixel then
		return value
	end
	local pixels = math.floor(math.abs(value) / pixel + 0.5)
	if pixels == 0 then return 0 end -- avoid -0

	-- Pixel sizes like 0.99999995 leave float noise (25px -> 24.999998); trim it
	-- so stored offsets stay clean. 1e-4 is far below a pixel at any UI scale.
	local result = math.floor(pixels * pixel * 10000 + 0.5) / 10000
	return value < 0 and -result or result
end

-- Resolves a global frame name or frame object to a frame, or nil.
function st:ResolveFrame(ref)
	if type(ref) == 'string' then
		return _G[ref]
	elseif type(ref) == 'table' and ref.GetObjectType then
		return ref
	end
	return nil
end

local function AnchorReaches(from, target, visited)
	if from == target then
		return true
	end
	if visited[from] then
		return false
	end
	visited[from] = true
	if not from.GetNumPoints then
		return false
	end
	for i = 1, from:GetNumPoints() do
		local _, relativeTo = from:GetPoint(i)
		if relativeTo and not issecretvalue(relativeTo) and type(relativeTo) == 'table'
				and AnchorReaches(relativeTo, target, visited) then
			return true
		end
	end
	return false
end

-- Returns true if anchoring frame to relative is valid, else false and an error message.
function st:ValidateAnchor(frame, relative)
	local relativeFrame = st:ResolveFrame(relative)
	if not relativeFrame then
		return false, "Frame doesn't exist"
	end
	if relativeFrame == frame then
		return false, "Can't anchor a frame to itself"
	end
	if AnchorReaches(relativeFrame, frame, {}) then
		return false, "Anchor would create a loop"
	end
	local parent = relativeFrame.GetParent and relativeFrame:GetParent()
	while parent do
		if parent == frame then
			return false, "Anchor would create a loop"
		end
		parent = parent.GetParent and parent:GetParent()
	end
	return true
end

function st:SetHeight(frame, height)
	frame:SetHeight(height)
end

function st:SetWidth(frame, width)
	frame:SetWidth(width)
end

function st:SetSize(frame, width, height)
	frame:SetSize(width, height or width)
end

function st:RegisterEditMode(frame, name, defaultPosition)
    if not st.EditMode then return end

	if not st.config.profile.edit_mode[name] then
		st.config.profile.edit_mode[name] = {}
	end

	if defaultPosition then
		local anchorFrame = type(defaultPosition.frame) == 'string' and _G[defaultPosition.frame] or defaultPosition.frame
		frame:ClearAllPoints()
		frame:SetPoint(st:UnpackPoint(defaultPosition))
		st.EditMode:RegisterFrame(frame, name, st.config.profile.edit_mode[name],
				anchorFrame or UIParent, defaultPosition.point, true)
	else
		st.EditMode:RegisterFrame(frame, name, st.config.profile.edit_mode[name], nil, nil, true)
	end

    return true
end

function st:CalculateSpacing(frame, anchorFrame, spacing)
	return (spacing or 0) + (frame.thick and 2 or frame.thick == false and 1 or 0) + (anchorFrame and anchorFrame.thick and 2 or 0)
end

function st:SetInside(frame, inset)
	inset = inset or 0

	frame:SetPoint('TOPLEFT', inset, -inset)
	frame:SetPoint('BOTTOMRIGHT', -inset, inset)
end

function st:InsetTexture(texture, inset)
	inset = inset or 0
	texture:SetTexCoord(inset, 1-inset, inset, 1-inset)
end

function st:SnapTop(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', anchorFrame, 'TOP', 0, -yOffset)
end


function st:SnapTopLeft(frame, anchorFrame, xOffset, yOffset)
	xOffset = st:CalculateSpacing(frame, anchorFrame, xOffset)
	if yOffset then
		yOffset = st:CalculateSpacing(frame, anchorFrame,yOffset)
	end
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', xOffset, -(yOffset or xOffset))
end

function st:SnapBottomLeft(frame, anchorFrame, xOffset, yOffset)
	xOffset = st:CalculateSpacing(frame, anchorFrame, xOffset)
	if yOffset then
		yOffset = st:CalculateSpacing(frame, anchorFrame,yOffset)
	end
	frame:ClearAllPoints()
	frame:SetPoint('BOTTOMLEFT', anchorFrame, 'BOTTOMLEFT', xOffset, -(yOffset or xOffset))
end

function st:SnapTopRight(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0, -yOffset)
end

function st:SnapTopAcross(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', 0, -yOffset)
	frame:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0, -yOffset)
end

function st:SnapBelow(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', anchorFrame, 'BOTTOM', 0, -yOffset)
end

function st:SnapBelowLeft(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'BOTTOMLEFT', 0, -yOffset)
end

function st:SnapBelowRight(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'BOTTOMRIGHT', 0, -yOffset)
end

function st:SnapBelowAcross(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)

	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'BOTTOMRIGHT', 0, -yOffset)
	frame:SetPoint('TOPLEFT', anchorFrame, 'BOTTOMLEFT', 0, -yOffset)
end

function st:SnapTopRightOf(frame, anchorFrame, spacing)
	local xOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPRIGHT', xOffset, 0)
end

function st:SnapBottomRightOf(frame, anchorFrame, spacing)
	local xOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('BOTTOMLEFT', anchorFrame, 'BOTTOMRIGHT', xOffset, 0)
end

local title = "|cff00adefSaftUI|r"

function st:Print(...)
	print(('[%s]: '):format(title), ...)
end

function st:Error(...)
	print(('[%s |cFFFF0000Error|r]: '):format(title), ...)
end

function st:Debug(module, ...)
	if not self.DEBUG then return end

	debug = st.StringFormat:ColorString(
			'DEBUG', st.config.profile.colors.text.red:GetRGB())
	st:Print(('<%s:%s>'):format(debug, module), ...)
end

function st:Kill(frame)
	if not frame then return end
	if frame.UnregisterAllEvents then
		frame:UnregisterAllEvents()
		frame:SetParent(st.HiddenFrame)
	end
	st:StripTextures(frame)

	if frame.SetAlpha then frame:SetAlpha(0) end

	frame._Show = frame.Show
	frame.Show = frame.Hide

	frame._SetAtlas = frame.SetAtlas
	frame.SetAtlas = frame.Hide

	frame:Hide()
end

function st:Hide(frame, reparent)
   frame:ClearAllPoints()
   frame:SetPoint('BOTTOM', HiddenFrame)

   if reparent then frame:SetParent(st.HiddenFrame) end
end

function st:EnableMoving(frame)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:HookScript('OnMouseDown', function(self) self:StartMoving() end)
	frame:HookScript('OnMouseUp', function(self)
		self:StopMovingOrSizing()
		local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint()
		self:ClearAllPoints()
		self:SetPoint(point, relativeTo, relativePoint, math.floor(offsetX), math.floor(offsetY))
	end)
end