local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:UpdateWarbandMoney()
    local container = self:GetContainer('warband')
    local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    container.footer.gold.text:SetText(st.StringFormat:GoldFormat(warbandGold))
end

function INV:InitializeWarbandBank()
    if self:GetContainer('warband') then return end

    local container = INV:CreateContainer('warband', 'Warband', true)
    container:SetParent(self.containers.bank)
    self:UpdateContainer('warband')

    local goldString = CreateFrame('frame', nil, container.footer)
    goldString:EnableMouse(true)
    goldString:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
    goldString:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
    goldString:SetWidth(120)

    goldString.text = goldString:CreateFontString(nil, 'OVERLAY')
    goldString.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
    goldString.text:SetPoint('RIGHT', goldString, 'RIGHT', -10, 0)
    goldString.text:SetJustifyH('RIGHT')

    goldString:SetScript('OnEnter', function() INV:DisplayServerGold() end)
    goldString:SetScript('OnLeave', st.HideGameTooltip)

    container.footer.gold = goldString
    INV:UpdateWarbandMoney()

    self:SecureHook(AccountBankPanel.MoneyFrame, 'Refresh', 'UpdateWarbandMoney')
end