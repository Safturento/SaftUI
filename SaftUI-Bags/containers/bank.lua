local st = SaftUI
local INV = st:GetModule('Inventory')


function INV:MoveBankBagSlots()
	local BagSlots = {}
	for i=1,7 do
		BagSlots[i] = BankSlotsFrame['Bag'..i]
		BagSlots[i].IconBorder:SetAlpha(0)
	end

	local bagSlotContainer = st:CreateFrame('frame', 'BankBagSlotFrame', self.containers.bank)
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
	self.containers.bank.bagSlotContainer = bagSlotContainer
end

function INV:OpenBank()
	if not self.containers.bank then
		self:InitializeBank()
	end
	self.containers.bank:Show()
	self:ShowBags()
	self:UpdateVisibleContainers()
	if self:GetContainer('bag').footer.depositButton then
		self:GetContainer('bag').footer.depositButton:Show()
	end
end

function INV:CloseBank()
	self.containers.bank:Hide()
	self:HideBags()

	if AccountBankPanel then
        AccountBankPanel.CloseAllBankPopups()
    end

	if self:GetContainer('bag').footer.depositButton then
		self:GetContainer('bag').footer.depositButton:Hide()
	end
end

function INV:InitializeBank()
    self:CreateContainer('bank', BANK, true)
    self:MoveBankBagSlots()
end