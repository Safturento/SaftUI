local ADDON_NAME, st = ...

function st:GetConfig(configUnit)
	return st.config.profile[configUnit]
end

function st:UnpackPoint(config)
	return config.point, config.frame, config.rel_point or config.point, st:Scale(config.x_off or 0), st:Scale(config.y_off or 0)
end

function st:Scale(num) return st.mult * floor(num/st.mult + 0.5) end

function st:SetHeight(frame, height) 
	frame:SetHeight(st:Scale(height))
end

function st:SetWidth(frame, width)
	frame:SetWidth(st:Scale(width))
end

function st:SetSize(frame, width, height)
	frame:SetSize(st:Scale(width), st:Scale(height))
end

local function calculateSpacing(frame, anchorFrame, spacing)
	return (spacing or 0) + (frame.thick and 2 or frame.thick == false and 1 or 0) + (anchorFrame.thick and 2 or 0)
end

function st:SnapTop(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', anchorFrame, 'TOP', 0, -yOffset)
end

function st:SnapTopLeft(frame, anchorFrame, spacing)
	local offset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', offset, -offset)
end

function st:SnapTopRight(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0, -yOffset)
end

function st:SnapTopAcross(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', 0, -yOffset)
	frame:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0, -yOffset)
end

function st:SnapBelow(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', anchorFrame, 'BOTTOM', 0, -yOffset)
end

function st:SnapBelowLeft(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'BOTTOMLEFT', 0, -yOffset)
end

function st:SnapBelowRight(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'BOTTOMRIGHT', 0, -yOffset)
end

function st:SnapBelowAcross(frame, anchorFrame, spacing)
	local yOffset = calculateSpacing(frame, anchorFrame, spacing)

	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'BOTTOMRIGHT', 0, -yOffset)
	frame:SetPoint('TOPLEFT', anchorFrame, 'BOTTOMLEFT', 0, -yOffset)
end

function st:SnapTopRightOf(frame, anchorFrame, spacing)
	local xOffset = calculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPRIGHT', xOffset, 0)
end

local title = select(2, GetAddOnInfo(ADDON_NAME))

function st:Print(...)
	print(('[%s]'):format(title), ...)
end

function st:Error(...)
	print(('[%s |cFFFF0000Error|r]'):format(title), ...)
end

function st:Debug(module, ...)
	if not self.DEBUG then return end

	debug = st.StringFormat:ColorString('DEBUG', unpack(st.config.profile.colors.text.red))
	st:Print(('<%s:%s>'):format(debug, module), ...)
end

function st:Kill(frame)
	if frame.UnregisterAllEvents then
		frame:UnregisterAllEvents()
		frame:SetParent(st.HiddenFrame)
	end
	frame._Show = frame.Show
	frame.Show = frame.Hide
	
	frame:Hide()
end

function st:EnableMoving(frame)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:HookScript('OnMouseDown', function(frame) frame:StartMoving() end)
	frame:HookScript('OnMouseUp', function(frame) frame:StopMovingOrSizing() end)
end