local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinZoneTextButton()
    local button = MinimapCluster.ZoneTextButton

    self:SkinBarButton(button)
    -- Under Blizzard it stands on the bar's box (micromenuart.lua)
    return button, { width = 200, text = MinimapZoneText }
end
