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

local title = select(2, GetAddOnInfo(ADDON_NAME))

function st:Print(...)
	print(('[%s]'):format(title), ...)
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