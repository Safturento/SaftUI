local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:ToggleBags()
	if IsOptionFrameOpen() then return end

	if self.containers.bag:IsShown() then
		self:HideBags()
	else
		self:ShowBags()
	end
end

function INV:ShowBags()
	if C_CurrencyInfo.IsAccountCharacterCurrencyDataReady and not (C_CurrencyInfo.IsAccountCharacterCurrencyDataReady()) then
		C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
	end
	self.containers.bag:Show()
	self:QueueUpdate()
	self:UpdateCooldowns()
	self:MovePlayerBagSlots()
end

function INV:HideBags()
	self.containers.bag:Hide()
	if not self.containers.bag.slots then return end
	for _,slot in pairs(self.containers.bag.slots) do
		C_NewItems.RemoveNewItem(slot.info.bagID, slot.info.slotID)
	end
	if self.containers.bank and self.containers.bank:IsShown() then
		self.containers.bank:Hide()
		HideUIPanel(BankFrame);
		C_Bank.CloseBankFrame();
	end
	if CurrencyTransferMenu and CurrencyTransferMenu:IsShown() then CurrencyTransferMenu:Hide() end
end


function INV:MovePlayerBagSlots()
	local bagSlotContainer = self.containers.bag.bagSlotContainer
	local BagSlots = bagSlotContainer.slots

	local prev
	for _, slot in pairs(BagSlots) do
		slot:ClearAllPoints()
		if prev then
			slot:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', self.config.buttonspacing, 0)
		else
			slot:SetPoint('BOTTOMLEFT', bagSlotContainer, 'BOTTOMLEFT', self.config.padding, self.config.padding)
		end
		prev = slot
	end
end

function INV:InitializePlayerBagSlots()
	local BagSlots = {}
	for i=0,3 do
		local slot = _G['CharacterBag'..i..'Slot']
		slot.icon = _G['CharacterBag'..i..'SlotIconTexture']
		tinsert(BagSlots, slot)
	end

	if st.retail then
		CharacterReagentBag0Slot.icon = CharacterReagentBag0SlotIconTexture
		tinsert(BagSlots, CharacterReagentBag0Slot)
	end
	local bagSlotContainer = st:CreateFrame('frame', 'BagSlotFrame', self.containers.bag)
	bagSlotContainer:Hide()
	bagSlotContainer:SetSize(
		self.config.buttonwidth * #BagSlots + self.config.buttonspacing * (#BagSlots - 1) + self.config.padding * 2,
		self.config.buttonheight + self.config.padding * 2)
	st:SetBackdrop(bagSlotContainer, 'thick')
	bagSlotContainer:SetPoint('BOTTOMLEFT', self.containers.bag, 'TOPLEFT', 0, self.config.buttonspacing)

	bagSlotContainer.slots = BagSlots
	local slotToggle = st:CreateButton('BagSlotToggle', self.containers.bag.header, 'Bag Slots', 'none')
	slotToggle:SetPoint('LEFT', 8, 0)
	slotToggle:SetSize(64, st.config.profile.headers.height - 8)
	slotToggle:SetScript('OnClick', function() bagSlotContainer:SetShown(not bagSlotContainer:IsShown()) end)
	self.containers.bag.header.slotToggle = slotToggle

	for _,slot in pairs(BagSlots) do
		slot.IconBorder:SetAlpha(0)
		slot:SetParent(bagSlotContainer)
		st:SkinIcon(slot.icon, nil, slot)
		st:SkinActionButton(slot, st.config.profile.buttons)
		st:SetBackdrop(slot, 'thick')
		slot:SetNormalTexture("")
		slot:SetSize(self.config.buttonwidth, self.config.buttonheight)
	end

	self.containers.bag.bagSlotContainer = bagSlotContainer

	self:MovePlayerBagSlots()
	self:RegisterEvent('BAG_SLOT_FLAGS_UPDATED', 'MovePlayerBagSlots')
	if st.retail then
		self:SecureHook(CharacterReagentBag0Slot, 'SetBarExpanded', 'MovePlayerBagSlots')
		self:SecureHook(MainMenuBarBagManager, 'OnExpandBarChanged', 'MovePlayerBagSlots')
	end
end

local function UpdateContainerSlots(container)
	local empty, total
	local text = ''
	empty, total = INV:GetNumContainerSlots({ 0, 1, 2, 3, 4})
	text = text .. ('%d/%d '):format(total - empty, total)

	empty, total = INV:GetNumContainerSlots({ 5 })
	text = text .. st.StringFormat:ColorString(
			(('%d/%d '):format(total - empty, total)),
			unpack(st.config.profile.colors.text.green)
	)

	container.footer.slots:SetText(text)
end

function INV:InitializePlayerBags()
	local container = self:CreateContainer('bag', INVTYPE_BAG)
	container:Hide()

	self:InitializePlayerBagSlots()
	self:InitializeAllCategories('bag')
	container.UpdateContainerSlots = UpdateContainerSlots

	self:SecureHook('OpenAllBags', 'ShowBags')
	self:SecureHook('CloseAllBags', 'HideBags')
	self:SecureHook('ToggleBag', 'ToggleBags')
	self:SecureHook('ToggleAllBags', 'ToggleBags')
	self:SecureHook('ToggleBackpack', 'ToggleBags')
end
