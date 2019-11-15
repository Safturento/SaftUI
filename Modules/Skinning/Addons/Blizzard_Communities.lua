local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

SK.AddonSkins.Blizzard_Communities = function()
	SK:SkinBlizzardPanel(CommunitiesFrame)

	st:Kill(CommunitiesFrame.PortraitOverlay)

	-- st.SkinActionButton(CommunitiesFrame.MaximizeMinimizeFrame.MinimizeButton)
	-- st.SkinActionButton(CommunitiesFrame.MaximizeMinimizeFrame.MinimizeButton)
	
	CommunitiesFrameCommunitiesList.InsetFrame:SetBackdrop(nil)
	st:StripTextures(CommunitiesFrameCommunitiesList.InsetFrame)
	st:StripTextures(CommunitiesFrameCommunitiesList.FilligreeOverlay)
	st:StripTextures(CommunitiesFrameCommunitiesListListScrollFrame)
end