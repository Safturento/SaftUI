local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeReagentBank()
    if self.containers.reagent then return end

    local container = INV:CreateContainer('reagent', 'Reagents', true)
    container:SetParent(self.containers.bank)
    BankFrame:UnregisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    self:UpdateContainer('reagent')
end