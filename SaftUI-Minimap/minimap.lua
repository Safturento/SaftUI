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
    st:BindModuleConfig(self, 'minimap')
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

    -- Forever's player coordinates hang 18px under the minimap, across SaftUI's
    -- experience bar. Nothing re-shows them after load, and hidden they stop
    -- their OnUpdate. They have no OnHide.
    local container = MinimapCluster.MinimapContainer
    if container and container.PlayerCoords then
        container.PlayerCoords:Hide()
    end

    -- Blizzard's Edit Mode box for the cluster no longer controls our minimap,
    -- so keep it hidden. HookScript only; nothing is written onto the frame.
    if MinimapCluster.Selection then
        MinimapCluster.Selection:HookScript('OnShow', function(selection)
            selection:Hide()
        end)
    end

    -- MinimapCluster is a ResizeLayoutFrame: it grows to cover its children, and
    -- the zone text, tracking and mail buttons now sit in SaftUI's bar across the
    -- top of the screen, so the cluster spans it too. Blizzard gives it
    -- enableMouse, so it ate every click in that strip. Nothing needs the cluster
    -- itself to take the mouse (its Edit Mode box is a separate frame, hidden
    -- above); its buttons keep their own. EnableMouse is the widget method, not an
    -- Edit Mode override, and nothing is written onto the frame. Out of combat,
    -- in case the cluster counts as protected.
    local function ClusterClickThrough()
        MinimapCluster:EnableMouse(false)
    end
    if not st:QueueAfterCombat('minimap_cluster_mouse', ClusterClickThrough) then
        ClusterClickThrough()
    end

    -- Take the minimap out of Blizzard's cluster so Blizzard's Edit Mode no
    -- longer moves it. Parenting resets strata/level, so restore them.
    local strata, level = Minimap:GetFrameStrata(), Minimap:GetFrameLevel()
    Minimap:SetParent(UIParent)
    Minimap:SetFrameStrata(strata)
    Minimap:SetFrameLevel(level)

	MM:UpdateConfig()

    -- Minimap is Blizzard's, moved with no SaftUI holder, so SaftUI doesn't clamp
    -- it: only edit mode drags and nudges keep it inside the screen edge margin.
    st:RegisterMover('minimap', {
        frame = Minimap,
        blizzardFrame = true,
        label = 'Minimap',
        getPosition = function() return self.config.position end,
        setPosition = function(pos) self.config.position = pos end,
        apply = function() MM:UpdateConfig() end,
        configPath = { 'Minimap', 'general' },
    })
end