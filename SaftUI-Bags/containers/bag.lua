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
		if slot.info and not slot.info.empty then
			C_NewItems.RemoveNewItem(slot.info.bagID, slot.info.slotID)
		end
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

-- Re-apply SaftUI styling on top of Blizzard's BaseBagSlotButtonMixin:UpdateTextures.
local function RestyleBagSlot(slot)
	slot:GetNormalTexture():SetAlpha(0)
	if slot.SlotHighlightTexture then slot.SlotHighlightTexture:SetAlpha(0) end

	-- GetHighlightTexture/GetPushedTexture are SaftUI's hover/pushed textures from
	-- SkinActionButton; Blizzard overwrites their atlas, size, anchors and blending.
	local hover = slot:GetHighlightTexture()
	hover:SetTexture(st.BLANK_TEX)
	hover:SetVertexColor(st.config.profile.colors.button.blue:GetRGB())
	hover:SetBlendMode('ADD')
	hover:SetAlpha(1)
	hover:ClearAllPoints()
	hover:SetAllPoints(slot.icon)

	local pushed = slot:GetPushedTexture()
	pushed:SetTexture(st.BLANK_TEX)
	pushed:SetVertexColor(0, 0, 0, .1)
	pushed:ClearAllPoints()
	pushed:SetAllPoints(slot.icon)
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

	-- Forever has a keyring bag button on the bags bar
	if KeyRingButton and C_ActionBar.ShouldShowKeyring and C_ActionBar.ShouldShowKeyring() then
		tinsert(BagSlots, KeyRingButton)
	end

	-- The slots get reparented into our container below; hide what's left of
	-- Blizzard's bags bar (border art and the dividers it draws between slots).
	-- Alpha rather than Kill, since BagsBar is an Edit Mode system frame.
	if BagsBar then
		BagsBar:SetAlpha(0)
	end

	local bagSlotContainer = st:CreateFrame('frame', 'BagSlotFrame', self.containers.bag)
	bagSlotContainer:Hide()
	bagSlotContainer:SetSize(
		self:GetButtonWidth() * #BagSlots + self.config.buttonspacing * (#BagSlots - 1) + self.config.padding * 2,
		self:GetButtonHeight() + self.config.padding * 2)
	st:SetBackdrop(bagSlotContainer, 'theme', 'solid', 'panel')
	bagSlotContainer:SetPoint('BOTTOMLEFT', self.containers.bag, 'TOPLEFT', 0, self.config.buttonspacing)

	bagSlotContainer.slots = BagSlots
	self:CreateSlotToggle(self.containers.bag, bagSlotContainer, 'BagSlotToggle')


	for _,slot in pairs(BagSlots) do
		slot.IconBorder:SetAlpha(0)
		slot:SetParent(bagSlotContainer)
		slot:SetSize(self:GetButtonWidth(), self:GetButtonHeight())
		-- Blizzard's button: the Blizzard theme makes none of its art on it.
		st:MarkForeign(slot)
		st:SkinActionButton(slot, st.config.profile.buttons, 'slot')

		st:Kill(slot.AnimIcon)

		-- Blizzard's UpdateTextures runs on load and on every bag change, re-applying
		-- its frame atlas to the normal texture and its atlases to our hover/pushed
		-- textures. Undo that after every call, and once now for the initial state.
		if slot.UpdateTextures then
			self:SecureHook(slot, 'UpdateTextures', RestyleBagSlot)
		end
		RestyleBagSlot(slot)

		-- With the bar collapsed Blizzard hides the slots; ours should always show.
		if slot.SetBarExpanded then
			self:SecureHook(slot, 'SetBarExpanded', function(slot, isExpanded)
				if not isExpanded then slot:Show() end
			end)
		end
	end

	self.containers.bag.bagSlotContainer = bagSlotContainer

	self:MovePlayerBagSlots()
	self:RegisterEvent('BAG_SLOT_FLAGS_UPDATED', 'MovePlayerBagSlots')

	-- BagsBar:Layout re-anchors every bag slot back onto Blizzard's bar (on load,
	-- Edit Mode changes and bar expand/collapse), so move them back after it.
	if BagsBar and BagsBar.Layout then
		self:SecureHook(BagsBar, 'Layout', 'MovePlayerBagSlots')
	end

	-- The expand/collapse layout doesn't go through that hook. BagsBar registered
	-- its original Layout as an EventRegistry callback at load, before the hook
	-- existed, and MainMenuBarBagManager fires it whenever an item goes on or off
	-- the cursor (the bar expands while you hold one). Put the slots back on that
	-- event too: now, and again next frame, since the registry runs callbacks in
	-- no set order and Blizzard's may come after ours.
	if EventRegistry then
		EventRegistry:RegisterCallback('MainMenuBarManager.OnExpandChanged', function()
			INV:MovePlayerBagSlots()
			C_Timer.After(0, function() INV:MovePlayerBagSlots() end)
		end, self)
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

	-- The second count is the reagent bag. Leave it out when there is none
	-- equipped instead of showing a useless 0/0.
	empty, total = INV:GetNumContainerSlots({
        Enum.BagIndex.ReagentBag,
    })
	if total > 0 then
		text = text .. st.StringFormat:ColorString(
				(('%d/%d '):format(total - empty, total)),
				st.config.profile.colors.text.green:GetRGB()
		)
	end

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
