local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinAddonCompartmentFrame()
    st:SkinButton(AddonCompartmentFrame)

    --TODO: Figure out how to get text to stop changing font objects
    --self:SecureHook(AddonCompartmentFrame, 'UpdateDisplay', function()
    --    print('skinning AddonCompartmentFrame')
    --    st:SkinButton(AddonCompartmentFrame)
    --end)

    return AddonCompartmentFrame
end