local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local function LayoutBar()
    MicroMenu:UpdateButtons()
end

-- Blizzard re-anchors the queue eye to its own UI, which pulls it out of the
-- bar. Each post-hook below puts it back in its slot; UpdateButtons places it
-- with the widget API's own methods.
-- - Live: MicroMenu:Layout anchors it to the micro menu, through
--   QueueStatusButton:UpdatePosition.
-- - Forever: it's an Edit Mode system, and Edit Mode anchors it to the
--   minimap through UpdateDefaultAnchor (from ApplySystemAnchor). The
--   minimap's scale callback calls the original UpdateDefaultAnchor, which
--   EventRegistry kept at load, so MinimapCluster:SetEditModeScale, which
--   fires that callback, is hooked too.
local function KeepInBar(button)
    if button.UpdatePosition then
        hooksecurefunc(button, 'UpdatePosition', LayoutBar)
    end
    if button.UpdateDefaultAnchor then
        hooksecurefunc(button, 'UpdateDefaultAnchor', LayoutBar)
        hooksecurefunc(MinimapCluster, 'SetEditModeScale', LayoutBar)
    end
end

function MicroMenu:SkinQueueButton()

    local button = st.retail and QueueStatusButton or MiniMapLFGFrame
    button:SetHitRectInsets(0,0, 0, 0)

    if st.retail then
        button.Eye:Hide()
    else
        MiniMapLFGFrame:SetParent(Minimap)
        MiniMapLFGFrameIcon:Hide()
        MiniMapLFGFrameBorder:Hide()
    end

    --Setup a static eye texture
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetAtlas("groupfinder-eye-single", true)
    st:InsetTexture(icon, 0.2)
    button:SetNormalTexture(icon)

    local hover = button:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture(st.BLANK_TEX)
    hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover)

    if st.retail then
        KeepInBar(button)
    end

    return button
end


