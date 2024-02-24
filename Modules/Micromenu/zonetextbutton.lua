local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinZoneTextButton()
    local button = st.retail and MinimapCluster.ZoneTextButton or MinimapZoneTextButton
    st:SkinButton(button)
    button.text = MinimapZoneText
    button.width = 200
    return button
end
