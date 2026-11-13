local st = SaftUI
local INV = st:GetModule('Inventory')

-- The Deposit and Withdraw buttons: 100 by 16, left of a window's gold
-- (container.footer.gold), each toggling Blizzard's popup for the warband
-- bank's gold, popup (BANK_MONEY_DEPOSIT or BANK_MONEY_WITHDRAW), and
-- closing the other one, otherPopup, first.
local function MoneyButton(name, container, label, popup, otherPopup)
    local button = st:CreateButton(name, container, label, 'theme', 'solid')
    button:SetPoint('BOTTOMRIGHT', container.footer.gold, 'BOTTOMLEFT', 0, 7)
    button:SetSize(100, 16)
    button:SetFrameLevel(90)
    button:SetScript('OnClick', function()
        StaticPopup_Hide(otherPopup);

        local alreadyShown = StaticPopup_Visible(popup);
        if alreadyShown then
            StaticPopup_Hide(popup);
            return;
        end

        StaticPopup_Show(popup, nil, nil, { bankType = 2 });
    end)
    return button
end

function INV:InitializeDepositButton(container)
    container = container or self:GetContainer('bag')
    local depositButton = MoneyButton('GoldDepositButton', container, 'Deposit', "BANK_MONEY_DEPOSIT", "BANK_MONEY_WITHDRAW")
    container.footer.depositButton = depositButton
    return depositButton
end

function INV:InitializeWithdrawButton(container)
    container = container or self:GetContainer('warband')
    local withdrawButton = MoneyButton('GoldWithdrawButton', container, 'Withdraw', "BANK_MONEY_WITHDRAW", "BANK_MONEY_DEPOSIT")
    container.footer.withdrawButton = withdrawButton
    return withdrawButton
end

-- The bag window's Deposit button, where it has one (made with the warband
-- bank or the combined bank), shows while a bank window is open.
function INV:SetDepositButtonShown(shown)
    local depositButton = self:GetContainer('bag').footer.depositButton
    if depositButton then
        if shown then depositButton:Show() else depositButton:Hide() end
    end
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

    -- Blizzard's bank panel has no AccountBankPanel on retail 12.0; the account
    -- balance changes announce themselves with ACCOUNT_MONEY.
    self:RegisterEvent('ACCOUNT_MONEY', 'UpdateWarbandMoney')

    self:InitializeDepositButton()
    self:InitializeWithdrawButton()
end