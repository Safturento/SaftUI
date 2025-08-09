local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:UpdateCombinedBankWarbandMoney()
    local container = self:GetContainer('combinedbank')
    if not container then return end
    local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
    container.footer.gold.text:SetText(st.StringFormat:GoldFormat(warbandGold))
end

function INV:SkinReagentDepositButton(container)
    local depositButton = BankPanel.AutoDepositFrame.DepositButton
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
		onClick = function(button) BankFrame.BankPanel:SetBankType(button.config.bankType) end,
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
				bankType = Enum.BankType.Character,
			},
			{
				label = 'Warband',
				bagType = 'warband',
				bankType = Enum.BankType.Account,
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