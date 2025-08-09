local st = SaftUI
local INV = st:GetModule('Inventory')


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
end