local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeReagentBank()
    if self.containers.reagent then return end

    local container = INV:CreateContainer('reagent', 'Reagents', true)
    local deposit = ReagentBankFrame.DespositButton
    deposit:SetSize(200, 16)
    deposit:SetParent(container)
    deposit:ClearAllPoints()
    deposit:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
    st:SkinActionButton(deposit)

    container:SetParent(self.containers.bank)
    BankFrame:UnregisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    self:UpdateContainer('reagent')
end