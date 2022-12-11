local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu', 'AceHook-3.0', 'AceEvent-3.0')
MicroMenu.Buttons = {}

function MicroMenu:AddButton(button)
    tinsert(self.Buttons, button)
end

function MicroMenu:UpdateButtons()
    local prev
    for _,button in pairs(self.Buttons) do
        button:SetSize(28, 28)
        button:ClearAllPoints()
        if prev then
            button:SetPoint('TOPLEFT', prev, 'TOPRIGHT', 8, 0)
        else
            button:SetPoint('TOPLEFT', UIParent, st.CLAMP_INSET, -st.CLAMP_INSET)
        end
        prev = button
    end

end

function MicroMenu:OnInitialize()
    self:KillBlizz()
    self:AddButton(self:SkinExpansionButton())
    self:AddButton(self:SkinQueueButton())

    self:UpdateButtons()
end
