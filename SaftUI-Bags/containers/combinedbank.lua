local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:UpdateCombinedBankWarbandMoney()
    local container = self:GetContainer('combinedbank')
    -- Forever's combined bank has no gold string
    if not (container and container.footer.gold) then return end
    local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    container.footer.gold.text:SetText(st.StringFormat:GoldFormat(warbandGold))
end

function INV:SkinReagentDepositButton(container)
    -- Forever's bank panel has no auto deposit (reagent) button
    local autoDeposit = BankPanel and BankPanel.AutoDepositFrame
    if not autoDeposit then return end

    local depositButton = autoDeposit.DepositButton
    depositButton:SetSize(200, 16)
    depositButton:SetParent(container)
    depositButton:ClearAllPoints()
    depositButton:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
    st:SkinButton(depositButton)

    return depositButton
end

function INV:InitializeBankCategorySelection()
	local selector = st:CreateRadioGroup('SaftUIBankCategorySelector', self.containers.combinedbank, {
		buttonHeight = 30,
		buttonWidth = 140,
		buttonSpacing = 6,
		template = self.config.template,
		onClick = function(button) BankFrame:SetTab(button.config.bankId) end,
		postCreate = function(button)
			local visibility = st:CreateCheckButton(button:GetName()..'VisibilityCheckbox', button)
			st:SetBackdrop(visibility, 'none')
			visibility:SetPoint('RIGHT', button, 'RIGHT', -6, 0)
			visibility:SetSize(16, 8)
			visibility:SetChecked(true)

			local unchecked = visibility:CreateTexture(nil, 'OVERLAY')
			unchecked:SetAllPoints(visibility)
			unchecked:Hide()
			visibility:SetScript('OnClick', function(self, clickedButton, down)
				if down then return end
				local checked = self:GetChecked()
				unchecked:SetShown(not checked)
				INV:UpdateContainerBagIds(button.config.bagType, checked)
			end)

			local r,g,b = st.config.profile.colors.button.grey:GetRGB()
			visibility:GetCheckedTexture():SetVertexColor(r, g, b, 1)
			visibility:GetCheckedTexture():SetTexture(st.textures.eyeOpen)
			unchecked:SetVertexColor(r, g, b, 0.3)
			unchecked:SetTexture(st.textures.eyeClosed)
		end,
		items = {
			{
				label = 'Bank',
				bagType = 'bank',
				bankType = Enum.BankType.Character,
				bankId = BankFrame.characterBankTabID,
			},
			{
				label = 'Warband',
				bagType = 'warband',
				bankType = Enum.BankType.Account,
				bankId = BankFrame.accountBankTabID,
			},
		}
	})


	selector:SetPoint('BOTTOMLEFT', self.containers.combinedbank, 'TOPLEFT', 0, 10)
end

function INV:UpdateContainerBagIds(bagType, filter)
	local container = self.containers.combinedbank
	if not container.filter then
		container.filter = {
			bank = true,
			warband = true,
		}
	end

	container.filter[bagType] = filter

	local bagIds = {}

	for bagId, enabled in pairs(container.filter) do
		if enabled then
			for _, bagId in pairs(self.bagIds[bagId]) do
				tinsert(bagIds, bagId)
			end
		end
	end

	container.bag_ids = bagIds
	INV:UpdateContainer('combinedbank')
end

function INV:OpenCombinedBank()
	if not self.containers.combinedbank then
		self:InitializeCombinedBank()
	end
	self.containers.combinedbank:Show()
	self:ShowBags()

	if self:GetContainer('bag').footer.depositButton then
		self:GetContainer('bag').footer.depositButton:Show()
	end
end

function INV:CloseCombinedBank()
	self.containers.combinedbank:Hide()
	self:HideBags()

	if self:GetContainer('bag').footer.depositButton then
		self:GetContainer('bag').footer.depositButton:Hide()
	end
end

local function UpdateContainerSlots(container)
	local empty, total
	local text = ''
	empty, total = INV:GetNumContainerSlots(INV.bagIds.bank)
	text = text .. ('%d/%d '):format(total - empty, total)

	-- The second count is the warband bank. Leave it out when it has no slots
	-- (no warband bank on this client, or no tabs bought) instead of showing a
	-- useless 0/0.
	empty, total = INV:GetNumContainerSlots(INV.bagIds.warband)
	if total > 0 then
		text = text .. st.StringFormat:ColorString(
				(('%d/%d'):format(total - empty, total)),
				st.config.profile.colors.text.cyan:GetRGB()
		)
	end

	container.footer.slots:SetText(text)
end

function INV:InitializeCombinedBank()
    local container = self:CreateContainer('combinedbank', BANK, true)
	container.UpdateContainerSlots = UpdateContainerSlots

	local depositButton = self:SkinReagentDepositButton(container)
	if depositButton then
		depositButton:ClearAllPoints()
		depositButton:SetPoint('BOTTOM', container.footer, 0, 7)
	end

	self:InitializeBankBagSlots(container)

	-- Retail only: the warband money controls (the bank's gold string, its Withdraw
	-- button and the bags' Deposit button) and the bank category selector. Forever
	-- has no separate bank and warband tabs worth switching between.
	if st.retail and not st.forever then
        self:CreateGoldString(container)
        self:UpdateCombinedBankWarbandMoney()
        self:InitializeWithdrawButton(container)
        self:InitializeBankCategorySelection()
        self:InitializeDepositButton()
    end
end