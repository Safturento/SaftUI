local ADDON_NAME, st = ...
local MP = st:GetModule('Maps')

function MP:UpdateMinimap()
	st:SetBackdrop(Minimap, self.config.minimap.template)
	Minimap:SetSize(self.config.minimap.size, self.config.minimap.size)
	Minimap:ClearAllPoints()
	Minimap:SetPoint(st:UnpackPoint(self.config.minimap.position))
	st:RegisterMover(Minimap, function(self)
		local pos = MP.config.minimap.position
		local point, frame, rel_point, x_off, y_off = self:GetPoint()
		pos.point = point
		pos.frame = frame
		pos.rel_point = rel_point
		pos.x_off = x_off
		pos.y_off = y_off
	end)
end

function MP:ADDON_LOADED(event, addon)
	if addon == "Blizzard_TimeManager" then
		st:Kill(TimeManagerClockButton)
	elseif addon == "Blizzard_FeedbackUI" then
		st:Kill(FeedbackUIButton)
	end
end

function MP:InitializeMinimap()
	-- Kill blizzard stuff
	for _,frame in pairs({
		MinimapBorder,
		MinimapBorderTop,
		MinimapZoomIn,
		MinimapZoomOut,
		MiniMapVoiceChatFrame,
		MinimapZoneTextButton,
		GameTimeFrame,
	}) do frame:Hide() end

	for _,frame in pairs({
		MinimapCluster,
		MiniMapWorldMapButton,
	}) do st:Kill(frame) end

	_G['MinimapNorthTag']:SetTexture(nil)
	
	Minimap:SetMaskTexture(st.BLANK_TEX)
	function GetMinimapShape() return "SQUARE" end
	Minimap:SetParent(UIParent)
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript('OnMouseWheel', function(self, delta)
		if delta > 0 then
			MinimapZoomIn:Click()
		else
			MinimapZoomOut:Click()
		end
	end)

	-- Skin Mail Icon
	local mail = MiniMapMailFrame
	mail:ClearAllPoints()
	mail:SetPoint('TOPRIGHT', Minimap, 'TOPRIGHT', -5, -2)
	mail:SetSize(16, 16)
	MiniMapMailIcon:SetAllPoints(mail)
	MiniMapMailIcon:SetTexture(st.textures.mail)
	MiniMapMailBorder:SetTexture(nil)
	
	-- Skin Tracking Icon
	st:SetBackdrop(MiniMapTrackingFrame, 'thin')
	MiniMapTrackingBorder:Hide()
	st:SkinIcon(MiniMapTrackingIcon, nil, MiniMapTrackingFrame)
	MiniMapTrackingFrame:SetSize(20, 20)
	MiniMapTrackingFrame:ClearAllPoints()
	MiniMapTrackingFrame:SetPoint('TOPLEFT', Minimap, 5, -5)
	MiniMapTrackingFrame:SetFrameLevel(Minimap:GetFrameLevel()+5)

	self:RegisterEvent('ADDON_LOADED')
	self:UpdateMinimap()
end