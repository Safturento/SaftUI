local st = SaftUI
local SK = st:GetModule('Skinning')

SK.FrameSkins.DropDown = function()
    print('Skin Dropdown')
    for i = 1, UIDROPDOWNMENU_MAXLEVELS do
        local backdrop = _G['DropDownList'..i..'MenuBackdrop']

        st:StripTextures(backdrop)
    end
end