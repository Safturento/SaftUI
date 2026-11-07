local st = SaftUI
local MM = st:NewModule('Minimap')

-- Re-anchors the cluster's indicator frame (mail, crafting orders) to the
-- minimap. It used to hang off the cluster's hidden BorderTop, which sat on the
-- minimap only while the cluster was pinned to it; now the cluster stays put.
function MM:MiniMapIndicatorFrame_UpdatePosition()
    MinimapCluster.IndicatorFrame:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -1, -1);
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
        if GarrisonMinimap_ShowCovenantCallingsNotification then
            self:SecureHook('GarrisonMinimap_ShowCovenantCallingsNotification')
        end
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

    -- Forever's day/night indicator is pinned to Blizzard's minimap container,
    -- so it floats once our minimap is moved. Nothing re-shows it after load.
    if MinimapCluster.DielFrame then
        MinimapCluster.DielFrame:Hide()
    end

    -- Blizzard's Edit Mode box for the cluster no longer controls our minimap,
    -- so keep it hidden. HookScript only; nothing is written onto the frame.
    if MinimapCluster.Selection then
        MinimapCluster.Selection:HookScript('OnShow', function(selection)
            selection:Hide()
        end)
    end

    -- Take the minimap out of Blizzard's cluster so Blizzard's Edit Mode no
    -- longer moves it. Parenting resets strata/level, so restore them.
    local strata, level = Minimap:GetFrameStrata(), Minimap:GetFrameLevel()
    Minimap:SetParent(UIParent)
    Minimap:SetFrameStrata(strata)
    Minimap:SetFrameLevel(level)

	MM:UpdateConfig()

    st:RegisterMover('minimap', {
        frame = Minimap,
        label = 'Minimap',
        getPosition = function() return self.config.position end,
        setPosition = function(pos) self.config.position = pos end,
        apply = function() MM:UpdateConfig() end,
        options = function() return MM:GetMoverOptions() end,
    })
end