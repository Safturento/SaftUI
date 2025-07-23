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
		buttonHeight = 30,
		buttonWidth = 140,
		buttonSpacing = 6,
		template = self.config.template,
		onClick = function(button) BankFrame_ShowPanel(button.config.panel) end,
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

			local r,g,b = unpack(st.config.profile.colors.button.grey)
			visibility:GetCheckedTexture():SetVertexColor(r, g, b, 1)
			visibility:GetCheckedTexture():SetTexture(st.textures.eyeOpen)
			unchecked:SetVertexColor(r, g, b, 0.3)
			unchecked:SetTexture(st.textures.eyeClosed)
		end,
		items = {
			{
				label = 'Bank',
				bagType = 'bank',
				panel = 'BankSlotsFrame',
			},
			{
				label = 'Reagent',
				bagType = 'reagent',
				panel = 'ReagentBankFrame',
			},
			{
				label = 'Warband',
				bagType = 'warband',
				panel = 'AccountBankPanel',
			},
		}
	})

	selector:SetPoint('BOTTOMLEFT', self.containers.combinedbank, 'TOPLEFT', 0, 10)
end

function INV:UpdateContainerBagIds(key, val)
	local container = self.containers.combinedbank
	if not container.filter then
		container.filter = {
			bank = true,
			reagent = true,
			warband = true,
		}
	end

	container.filter[key] = val

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
	AccountBankPanel.CloseAllBankPopups()

	if self:GetContainer('bag').footer.depositButton then
		self:GetContainer('bag').footer.depositButton:Hide()
	end
end

local function UpdateContainerSlots(container)
	local empty, total
	local text = ''
	empty, total = INV:GetNumContainerSlots(INV.bagIds.bank)
	text = text .. ('%d/%d '):format(total - empty, total)

	empty, total = INV:GetNumContainerSlots(INV.bagIds.reagent)
	text = text .. st.StringFormat:ColorString(
			(('%d/%d '):format(total - empty, total)),
			unpack(st.config.profile.colors.text.green)
	)

	empty, total = INV:GetNumContainerSlots(INV.bagIds.warband)
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

	if st.retail then
        self:CreateGoldString(container)
        self:UpdateCombinedBankWarbandMoney()
        self:InitializeWithdrawButton(container)
        self:InitializeBankCategorySelection()

        self:InitializeDepositButton()
    end

end