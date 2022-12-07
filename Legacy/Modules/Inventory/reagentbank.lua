local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeReagentBank()
    local container = INV:CreateContainer('reagent', 'Reagents')
    container:SetParent(self.containers.bank)
    self:UpdateContainerItems('reagent')
    --self:GetSortedInventory('reagent')
end