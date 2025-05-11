local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:SkinReagentDepositButton(container)
    local depositButton = ReagentBankFrame.DespositButton
    depositButton:SetSize(200, 16)
    depositButton:SetParent(container)
    depositButton:ClearAllPoints()
    depositButton:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
    st:SkinButton(depositButton)

    return depositButton
end

function INV:InitializeReagentBank()
    if self.containers.reagent then return end

    local container = self:CreateContainer('reagent', 'Reagents', true)
    self:SkinReagentDepositButton(container)

    container:SetParent(self.containers.bank)
    BankFrame:UnregisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    self:UpdateContainer('reagent')
end