local st = SaftUI
local SK = st:GetModule('Skinning')

SK.FrameSkins.MicroMenu = function()
    CharacterMicroButton:ClearAllPoints()
    CharacterMicroButton:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 20 -20)

    QueueStatusButton:ClearAllPoints()
    QueueStatusButton:SetPoint('TOPLEFT', MainMenuMicroButton, 'TOPRIGHT', 20, -5)
    QueueStatusButton:SetSize(20, 20)
    QueueStatusButton.Eye:SetSize(20, 20)

    QueueStatusFrame:ClearAllPoints()
    QueueStatusFrame:SetPoint('TOPRIGHT', QueueStatusButton, 'BOTTOMRIGHT', 0, -20)

    st:Kill(MainMenuBarBackpackButton)
    st:Kill(CharacterBag0Slot)
    st:Kill(CharacterBag1Slot)
    st:Kill(CharacterBag2Slot)
    st:Kill(CharacterBag3Slot)
    st:Kill(BagBarExpandToggle)
st:Kill(CharacterReagentBag0Slot)
end