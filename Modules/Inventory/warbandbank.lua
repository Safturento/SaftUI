local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeWarbandBank()
    if self.containers.warband then return end

    local container = INV:CreateContainer('warband', 'Warband')
    container:SetParent(self.containers.bank)
    self:UpdateContainer('warband')
end