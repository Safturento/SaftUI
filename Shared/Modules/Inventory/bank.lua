local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeBankFooter(container)
    local reagentButton = st:CreateButton('ReagentBankButton', container, 'Reagents', 'highlight')

    reagentButton:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
    reagentButton:SetScript('OnClick', function()
        self:InitializeReagentBank()
    end)
    reagentButton:SetSize(100, 16)
    reagentButton:SetFrameLevel(90)


    --local deposit = ReagentBankFrame.DespositButton
    --deposit:SetSize(200, 16)
    --deposit:SetParent(container)
    --deposit:ClearAllPoints()
    --st:SkinActionButton(deposit)
end