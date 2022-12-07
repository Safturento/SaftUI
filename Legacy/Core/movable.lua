for _,frame_name in ipairs({
	'InterfaceOptionsFrame',
}) do
	local frame = _G[frame_name]
	frame:SetMovable(true)
	frame:HookScript('OnMouseDown', function(self)
		self:StartMoving()
	end)
	frame:HookScript('OnMouseUp', function(self)
		self:StopMovingOrSizing()
	end)
end