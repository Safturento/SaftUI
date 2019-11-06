local ADDON_NAME, st = ...
local MP = st:GetModule('Maps')

local ICON_SIZE = 22


function MP:UpdateMinimap()
	st:SetBackdrop(Minimap, self.config.minimap.template)
	Minimap:SetSize(self.config.minimap.size, self.config.minimap.size)
	Minimap:ClearAllPoints()
	Minimap:SetPoint(st:UnpackPoint(self.config.minimap.position))
end

function MP:ADDON_LOADED(event, addon)
	if addon == "Blizzard_TimeManager" then
		st:Kill(TimeManagerClockButton)
	elseif addon == "Blizzard_FeedbackUI" then
		st:Kill(FeedbackUIButton)
	end
end

function MP:SkinTrackingIcon()
	local track = MiniMapTracking
	track.button = MiniMapTrackingButton
	track.icon = MiniMapTrackingIcon

	local name = track:GetName()

	track.button:SetPushedTexture(nil)
	track.button:SetHighlightTexture(nil)
	track.button:SetDisabledTexture(nil)
	track.button:SetAllPoints(track)

	track.icon:SetAllPoints(track)
	track.icon:SetDrawLayer('OVERLAY')
	track.icon:SetParent(track.button)
	track.button:HookScript('Onclick', function() track.icon:SetAllPoints() end)

	track:SetSize(ICON_SIZE, ICON_SIZE)
	track.button:SetSize(ICON_SIZE, ICON_SIZE)
	st:SetTemplate(track, 'thin')

	track:ClearAllPoints()
	track:SetPoint('TOPLEFT', Minimap, 5, -5)

	for _,region in pairs({track.button:GetRegions()}) do
		if region:GetObjectType() == 'Texture' then
			local texture = region:GetTexture()
			if not texture then return end

			if texture:find('Background') or texture:find('Border') or texture:find('AlphaMask') then
					region:SetTexture(nil)
			else
				-- region:ClearAllPoints()
				-- region:SetInside(track.button)
				-- region:SetTexCoord(unpack(S.iconcoords))
				-- region:SetDrawLayer('OVERLAY')
				-- track.button:SetTemplate("TS")
			end
		end
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

	MP:SkinTrackingIcon()

	self:RegisterEvent('ADDON_LOADED')
	self:UpdateMinimap()
end