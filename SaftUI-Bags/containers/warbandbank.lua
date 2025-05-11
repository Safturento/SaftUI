local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeDepositButton(container)
    container = container or self:GetContainer('bag')
    depositButton = st:CreateButton('GoldDepositButton', container, 'Deposit', 'thick')
    depositButton:SetPoint('BOTTOMRIGHT', container.footer.gold, 'BOTTOMLEFT', 0, 7)
    depositButton:SetSize(100, 16)
    depositButton:SetFrameLevel(90)
    depositButton:SetScript('OnClick', function()
        StaticPopup_Hide("BANK_MONEY_WITHDRAW");

        local alreadyShown = StaticPopup_Visible("BANK_MONEY_DEPOSIT");
        if alreadyShown then
            StaticPopup_Hide("BANK_MONEY_DEPOSIT");
            return;
        end

        local textArg1, textArg2 = nil, nil;
        StaticPopup_Show("BANK_MONEY_DEPOSIT", textArg1, textArg2, { bankType = 2 });
    end)
    container.footer.depositButton = depositButton
    return depositButton
end

function INV:InitializeWithdrawButton(container)
    container = container or self:GetContainer('warband')
    withdrawButton = st:CreateButton('GoldWithdrawButton', container, 'Withdraw', 'thick')
    withdrawButton:SetPoint('BOTTOMRIGHT',  container.footer.gold, 'BOTTOMLEFT', 0, 7)
    withdrawButton:SetSize(100, 16)
    withdrawButton:SetFrameLevel(90)
    withdrawButton:SetScript('OnClick', function()
        StaticPopup_Hide("BANK_MONEY_DEPOSIT");

        local alreadyShown = StaticPopup_Visible("BANK_MONEY_WITHDRAW");
        if alreadyShown then
            StaticPopup_Hide("BANK_MONEY_WITHDRAW");
            return;
        end

        StaticPopup_Show("BANK_MONEY_WITHDRAW", nil, nil, { bankType = 2 });
    end)

    container.footer.withdrawButton = withdrawButton
    return withdrawButton
end

function INV:UpdateWarbandMoney()
    local container = self:GetContainer('warband')
    if not container then return end
    local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    container.footer.gold.text:SetText(st.StringFormat:GoldFormat(warbandGold))
end

function INV:InitializeWarbandBank()
    if self:GetContainer('warband') then return end

    local container = INV:CreateContainer('warband', 'Warband', true)
    container:SetParent(self.containers.bank)
    self:UpdateContainer('warband')

    container.footer.gold = self:CreateGoldString(container)
    INV:UpdateWarbandMoney()

    self:SecureHook(AccountBankPanel.MoneyFrame, 'Refresh', 'UpdateWarbandMoney')

    self:InitializeDepositButton()
    self:InitializeWithdrawButton()
end