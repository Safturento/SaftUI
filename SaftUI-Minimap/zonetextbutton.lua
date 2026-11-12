local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinZoneTextButton()
    local button = MinimapCluster.ZoneTextButton

    self:SkinBarButton(button)
    -- Under Blizzard it stands on Blizzard's header button (MicroMenu:AddButton)
    return button, { width = 200, text = MinimapZoneText, art = 'header' }
end
