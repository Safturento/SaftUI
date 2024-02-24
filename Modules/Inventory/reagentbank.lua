local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeReagentBank()
    local container = INV:CreateContainer('reagent', 'Reagents')
    container:SetParent(self.containers.bank)
    BankFrame:UnregisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    self:UpdateContainer('reagent')
end