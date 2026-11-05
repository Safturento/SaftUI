local st = SaftUI
local INV = st:GetModule('Inventory')

local CloseBankFrame = C_Bank and C_Bank.CloseBankFrame or CloseBankFrame

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
	self:QueueUpdate(true)
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
		CloseBankFrame();
	end

	if self.containers.combinedbank and self.containers.combinedbank:IsShown() then
		self.containers.combinedbank:Hide()
		HideUIPanel(BankFrame);
		CloseBankFrame();
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

local settingsMenuItems = {
    mergeStacks = {
        text = 'Merge Stacks',
        isChecked = function()
            return INV.config.stackItems
        end,
        setChecked = function(key, menuInputData, menu)
            INV.config.stackItems = not INV.config.stackItems
            INV:QueueUpdate()
       end,
    },
}

local function isChecked(key)
    return settingsMenuItems[key].isChecked()
end

local function setChecked(key, menuInputData, menu)
   settingsMenuItems[key].setChecked(key, menuInputData, menu)
   menu:Close()
end

function INV:OpenSettingsDropdown()
	if not INV.SettingsDropdown then
		INV.SettingsDropdown = st:CreateCheckboxDropdown("SaftUIBagsSettingsMenu", UIParent, {
			mergeStacks = { text = 'Merge Stacks'},
		}, isChecked, setChecked)
	end

	INV.SettingsDropdown:Open()
end

function INV:InitializePlayerBagSlots()

	st:Kill(MainMenuBarBackpackButton)
	st:Kill(BagBarExpandToggle)

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


	local settingsButton = st:CreateButton('BagSettingsButton', self.containers.bag.header, 'Settings', 'none')
	settingsButton:SetPoint('LEFT',slotToggle, 'RIGHT', 8, 0)
	settingsButton:SetSize(64, st.config.profile.headers.height - 8)
	settingsButton:SetScript('OnClick', function()
		INV:OpenSettingsDropdown()
	end)

	self.containers.bag.header.settingsButton = settingsButton

	for _,slot in pairs(BagSlots) do
		slot.IconBorder:SetAlpha(0)
		slot:SetParent(bagSlotContainer)
		st:SkinActionButton(slot, st.config.profile.buttons)

		st:Kill(slot.AnimIcon)

		st:Kill(slot.SlotHighlightTexture)
		st:Kill(slot:GetPushedTexture())
		st:Kill(slot:GetHighlightTexture())
		if slot.UpdateTextures then
			self:SecureHook(slot, 'UpdateTextures', function(self)
				self:GetNormalTexture():Hide()
				self:GetPushedTexture():Hide()
				self:GetHighlightTexture():Hide()
				self.SlotHighlightTexture:Hide()
			end)
		end

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
	empty, total = INV:GetNumContainerSlots({
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
     })
	text = text .. ('%d/%d '):format(total - empty, total)

	empty, total = INV:GetNumContainerSlots({
        Enum.BagIndex.ReagentBag,
    })
	text = text .. st.StringFormat:ColorString(
			(('%d/%d '):format(total - empty, total)),
			st.config.profile.colors.text.green:GetRGB()
	)

	container.footer.slots:SetText(text)
end

function INV:InitializePlayerBags()
	local container = self:CreateContainer('bag', INVTYPE_BAG)
	container:Hide()

	self:InitializePlayerBagSlots()
	self:InitializeAllCategories('bag')
	container.UpdateContainerSlots = UpdateContainerSlots

    if st.retail then
    	self:SecureHook('OpenAllBags', 'ShowBags')
    	self:SecureHook('CloseAllBags', 'HideBags')
    	self:SecureHook('ToggleBag', 'ToggleBags')
    	self:SecureHook('ToggleAllBags', 'ToggleBags')
    else
        ContainerFrame1:ClearAllPoints()
        ContainerFrame1:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 100, 100)
    end

	self:SecureHook('ToggleBackpack', 'ToggleBags')
end
