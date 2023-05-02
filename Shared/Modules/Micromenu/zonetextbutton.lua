local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinZoneTextButton()
    local button = MinimapCluster.ZoneTextButton
    button.text = MinimapZoneText
    button.width = 200
    return button
end
