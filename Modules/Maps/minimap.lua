local st = SaftUI
local MP = st:GetModule('Maps')

function MP:MiniMapIndicatorFrame_UpdatePosition()
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetAllPoints(Minimap)
    MinimapCluster.IndicatorFrame:SetPoint("TOPRIGHT", MinimapCluster.BorderTop, "TOPLEFT", -1, -1);
end

function MP:GarrisonMinimap_ShowCovenantCallingsNotification(ExpansionLandingPageMinimapButton)
    if not ExpansionLandingPageMinimapButton then return end
    ExpansionLandingPageMinimapButton.AlertText:SetText(COVENANT_CALLINGS_AVAILABLE);
	ExpansionLandingPageMinimapButton.MinimapAlertAnim:Stop();
	ExpansionLandingPageMinimapButton.MinimapLoopPulseAnim:Stop();
end

function MP:InitializeMinimap()
    MinimapCompassTexture:Hide()
    Minimap:SetMaskTexture(st.BLANK_TEX)
	function GetMinimapShape() return "SQUARE" end
    st:SetBackdrop(Minimap, self.config.minimap.template)

    Minimap:SetSize(self.config.minimap.size, self.config.minimap.size)

    if st.retail then
        self:SecureHook('MiniMapIndicatorFrame_UpdatePosition')
        self:SecureHook(MinimapCluster, 'SetHeaderUnderneath', 'MiniMapIndicatorFrame_UpdatePosition')
        self:SecureHook('GarrisonMinimap_ShowCovenantCallingsNotification')
        Minimap:SetArchBlobRingScalar(0)
        Minimap:SetQuestBlobRingScalar(0)
    else
        MiniMapLFGFrame:ClearAllPoints()
        MiniMapLFGFrame:SetPoint("BOTTOMLEFT", Minimap, 'BOTTOMLEFT', 10, 10)
        st:Kill(MinimapBorder)
        st:Kill(MinimapZoomIn)
        st:Kill(MinimapZoomOut)
    end
	Minimap:ClearAllPoints()
	Minimap:SetPoint(st:UnpackPoint(self.config.minimap.position))

end

