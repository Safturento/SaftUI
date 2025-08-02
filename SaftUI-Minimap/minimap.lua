local st = SaftUI
local MM = st:NewModule('Minimap')

function MM:MiniMapIndicatorFrame_UpdatePosition()
    MinimapCluster.IndicatorFrame:SetPoint("TOPRIGHT", MinimapCluster.BorderTop, "TOPLEFT", -1, -1);
end

function MM:GarrisonMinimap_ShowCovenantCallingsNotification(ExpansionLandingPageMinimapButton)
    if not ExpansionLandingPageMinimapButton then return end
    ExpansionLandingPageMinimapButton.AlertText:SetText(COVENANT_CALLINGS_AVAILABLE);
	ExpansionLandingPageMinimapButton.MinimapAlertAnim:Stop();
	ExpansionLandingPageMinimapButton.MinimapLoopPulseAnim:Stop();
end

function MM:OnEnable()
    self.config = st.config.profile.minimap
    MinimapCompassTexture:Hide()
    Minimap:SetMaskTexture(st.BLANK_TEX)
    -- TODO: figure out how to stop cluster resizing
    -- st:SetBackdrop(MinimapCluster, 'thick')
	function GetMinimapShape() return "SQUARE" end

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

        hooksecurefunc('BuffFrame_UpdateAllBuffAnchors', function()
            BuffFrame:ClearAllPoints();
            BuffFrame:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -10, 0)
        end)

    end

    st:Kill(MinimapCluster.Selection)
    MinimapCluster:EnableMouse(false)

	MM:UpdateConfig()
end