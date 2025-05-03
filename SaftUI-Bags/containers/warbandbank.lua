local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeDepositButton()
    local container = self:GetContainer('bag')
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
end

function INV:InitializeWithdrawButton()
    local container = self:GetContainer('warband')
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

    self:InitializeDepositButton()
    self:InitializeWithdrawButton()
end