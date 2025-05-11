local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:UpdateCombinedBankWarbandMoney()
    local container = self:GetContainer('combinedbank')
    if not container then return end
    local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    container.footer.gold.text:SetText(st.StringFormat:GoldFormat(warbandGold))
end

function INV:MoveCombinedBankBagSlots()
	local BagSlots = {}
	for i=1,7 do
		BagSlots[i] = BankSlotsFrame['Bag'..i]
		BagSlots[i].IconBorder:SetAlpha(0)
	end

	local bagSlotContainer = st:CreateFrame('frame', 'CombinedBankBagSlotFrame', self.containers.combinedbank)
	bagSlotContainer:SetSize(
		self.config.buttonwidth * 7 + self.config.buttonspacing * 6 + self.config.padding * 2,
		self.config.buttonheight + self.config.padding * 2)
	st:SetBackdrop(bagSlotContainer, 'thick')

	bagSlotContainer:SetPoint('BOTTOMLEFT', self.containers.bank, 'TOPLEFT', 0, self.config.buttonspacing)
	for i,slot in pairs(BagSlots) do
		slot:SetParent(bagSlotContainer)
		slot:ClearAllPoints()
		st:SkinIcon(slot.icon, nil, slot)
		st:SkinActionButton(slot, st.config.profile.buttons)
		st:SetBackdrop(slot, 'thick')
		slot:SetNormalTexture("")
		slot:SetSize(self.config.buttonwidth, self.config.buttonheight)
		if i == 1 then
			slot:SetPoint('BOTTOMLEFT', bagSlotContainer, 'BOTTOMLEFT', self.config.padding, self.config.padding)
		else
			slot:SetPoint('BOTTOMLEFT', BagSlots[i-1], 'BOTTOMRIGHT', self.config.buttonspacing, 0)
		end
	end

	(self.containers.combinedbank).bagSlotContainer = bagSlotContainer
end

function INV:InitializeBankCategorySelection()
	local selector = st:CreateRadioGroup('SaftUIBankCategorySelector', self.containers.combinedbank, {
		buttonHeight = 20,
		buttonWidth = 100,
		buttonSpacing = 6,
		template = self.config.template,
		items = {
			{
				label = 'Bank',
				onClick = function(self) BankFrame_ShowPanel('BankSlotsFrame') end,
			},
			{
				label = 'Reagent',
				onClick = function(self)
					BankFrame_ShowPanel('ReagentBankFrame') end,
			},
			{
				label = 'Warband',
				onClick = function(self) BankFrame_ShowPanel('AccountBankPanel') end,
			},
		}
	})

	selector:SetPoint('BOTTOMLEFT', self.containers.combinedbank, 'TOPLEFT', 0, 10)
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
	AccountBankPanel.CloseAllBankPopups()

	if self:GetContainer('bag').footer.depositButton then
		self:GetContainer('bag').footer.depositButton:Hide()
	end
end

function UpdateContainerSlots(container)
	local empty, total
	local text = ''
	empty, total = INV:GetNumContainerSlots(INV.bankIds.bank)
	text = text .. ('%d/%d '):format(total - empty, total)

	empty, total = INV:GetNumContainerSlots(INV.bankIds.reagent)
	text = text .. st.StringFormat:ColorString(
			(('%d/%d '):format(total - empty, total)),
			unpack(st.config.profile.colors.text.green)
	)

	empty, total = INV:GetNumContainerSlots(INV.bankIds.warband)
	text = text .. st.StringFormat:ColorString(
			(('%d/%d'):format(total - empty, total)),
			unpack(st.config.profile.colors.text.cyan)
	)

	container.footer.slots:SetText(text)
end

function INV:InitializeCombinedBank()
    local container = self:CreateContainer('combinedbank', BANK, true)
	container.UpdateContainerSlots = UpdateContainerSlots
    self:MoveCombinedBankBagSlots()

	local depositButton = self:SkinReagentDepositButton(container)
	depositButton:ClearAllPoints()
	depositButton:SetPoint('BOTTOM', container.footer, 0, 7)

	self:CreateGoldString(container)
	self:UpdateCombinedBankWarbandMoney()
	self:InitializeWithdrawButton(container)
	self:InitializeBankCategorySelection()

	self:InitializeDepositButton()
end