local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinZoneTextButton()
    local button = st.retail and MinimapCluster.ZoneTextButton or MinimapZoneTextButton

    self:SkinBarButton(button)
    return button, { width = 200, text = MinimapZoneText }
end
