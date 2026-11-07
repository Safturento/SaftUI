local st = SaftUI
local INV = st:GetModule('Inventory')

-- Forever's bank is built from bank tabs that hold bags: tab 1 is the base bank
-- and each later tab is a bag slot, its bag kept in the Characterbanktab
-- container. Blizzard's BankFrame creates its bag slot buttons from a pool only
-- while it is shown, and SaftUI keeps it hidden, so this bar uses its own
-- buttons. Retail's bank tabs aren't bags and it has no FetchMaxNumBankTabs,
-- so it gets no bar.

local BANK_BAG_SLOT_EVENTS = {
	'BANK_TABS_CHANGED',
	'PLAYERBANKSLOTS_CHANGED',
	'BAG_CONTAINER_UPDATE',
	'ITEM_LOCK_CHANGED',
	'PLAYER_MONEY',
	'PLAYER_REGEN_DISABLED',
	'PLAYER_REGEN_ENABLED',
}

local function GetBankBagLocation(tab)
	return ItemLocation:CreateFromBagAndSlot(Enum.BagIndex.Characterbanktab, tab)
end

-- Same tooltip as Blizzard's BankItemButtonBagMixin:OnEnter
local function BankBagSlot_OnEnter(slot)
	GameTooltip:SetOwner(slot, 'ANCHOR_RIGHT')
	if not slot.purchased then
		GameTooltip:SetText(BANK_BAG_PURCHASE or 'Purchasable Bag Slot')
	elseif not GameTooltip:SetBagItem(Enum.BagIndex.Characterbanktab, slot.tab) then
		GameTooltip:SetText(BANK_BAG or 'Bag Slot')
	end
	GameTooltip:Show()
end

-- Clicking, dragging or dropping on a bought slot picks up or places its bag,
-- the same container call Blizzard's bank bag buttons make.
local function BankBagSlot_Pickup(slot)
	if not slot.purchased then return end
	C_Container.PickupContainerItem(Enum.BagIndex.Characterbanktab, slot.tab)
end

local function CreateBankBagSlot(bar, tab)
	local slot = CreateFrame('Button', bar:GetName() .. 'Slot' .. tab, bar)
	slot:SetSize(INV.config.buttonwidth, INV.config.buttonheight)
	slot.tab = tab

	slot.icon = slot:CreateTexture(nil, 'ARTWORK')
	slot.icon:SetAllPoints()

	-- Tints a slot that hasn't been bought yet
	slot.locked = slot:CreateTexture(nil, 'OVERLAY')
	slot.locked:SetTexture(st.BLANK_TEX)
	slot.locked:SetVertexColor(st.config.profile.colors.button.red:GetRGB())
	slot.locked:SetAlpha(0.3)
	slot.locked:SetAllPoints()

	st:SkinActionButton(slot, st.config.profile.buttons)

	slot:RegisterForClicks('LeftButtonUp')
	slot:RegisterForDrag('LeftButton')
	slot:SetScript('OnClick', BankBagSlot_Pickup)
	slot:SetScript('OnDragStart', BankBagSlot_Pickup)
	slot:SetScript('OnReceiveDrag', BankBagSlot_Pickup)
	slot:SetScript('OnEnter', BankBagSlot_OnEnter)
	slot:SetScript('OnLeave', st.HideGameTooltip)

	return slot
end

local function BankBagPurchase_OnEnter(button)
	GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
	GameTooltip:SetText('Purchase bag slot')

	local tabData = C_Bank.FetchNextPurchasableBankTabData(Enum.BankType.Character)
	local cost = tabData and tabData.tabCost
	if cost and not issecretvalue(cost) then
		GameTooltip:AddDoubleLine('Cost', st.StringFormat:GoldFormat(cost), 1, 1, 1, 1, 1, 1)
	end

	if InCombatLockdown() then
		GameTooltip:AddLine("Can't buy bank slots in combat.", st.config.profile.colors.text.red:GetRGB())
	end
	GameTooltip:Show()
end

local function CreateBankBagPurchaseButton(bar)
	-- BankPanelPurchaseButtonScriptTemplate is Blizzard's script-only template for
	-- addon bank tab purchase buttons. Its OnClick opens the CONFIRM_BUY_BANK_TAB
	-- popup for the overrideBankType attribute, and accepting that popup calls
	-- C_Bank.PurchaseBankTab, so the purchase stays on Blizzard's own path.
	local button = CreateFrame('Button', bar:GetName() .. 'PurchaseButton', bar, 'BankPanelPurchaseButtonScriptTemplate')
	button:SetAttribute('overrideBankType', Enum.BankType.Character)
	button:SetSize(INV.config.buttonwidth, INV.config.buttonheight)

	button.text = st:CreateFontString(button, 'pixel', 'Buy')
	button.text:SetAllPoints()
	st:SkinButton(button, st.config.profile.buttons.template)

	button:SetScript('OnEnter', BankBagPurchase_OnEnter)
	button:SetScript('OnLeave', st.HideGameTooltip)

	return button
end

function INV:UpdateBankBagSlots(bar)
	local bankType = Enum.BankType.Character
	local maxTabs = C_Bank.FetchMaxNumBankTabs(bankType)
	local numPurchased = C_Bank.FetchNumPurchasedBankTabs(bankType)
	if not maxTabs or issecretvalue(maxTabs) or not numPurchased or issecretvalue(numPurchased) then return end

	local purchasedTabs = C_Bank.FetchPurchasedBankTabData(bankType) or {}
	local spacing, padding = self.config.buttonspacing, self.config.padding

	local numButtons = 0
	local prev
	local function Place(button)
		button:ClearAllPoints()
		if prev then
			button:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', spacing, 0)
		else
			button:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', padding, padding)
		end
		button:Show()
		prev = button
		numButtons = numButtons + 1
	end

	-- Tab 1 is the base bank, so the bag slots are tabs 2 and up
	for tab = 2, maxTabs do
		local slot = bar.slots[tab]
		if not slot then
			slot = CreateBankBagSlot(bar, tab)
			bar.slots[tab] = slot
		end

		-- Blizzard treats a tab as bought when the purchased data has an entry for it
		slot.purchased = purchasedTabs[tab] ~= nil

		local location = GetBankBagLocation(tab)
		local hasBag = slot.purchased and C_Item.DoesItemExist(location)
		slot.icon:SetTexture(hasBag and C_Item.GetItemIcon(location) or nil)
		slot.icon:SetDesaturated(hasBag and C_Item.IsLocked(location) or false)
		slot.locked:SetShown(not slot.purchased)

		Place(slot)
	end

	for tab, slot in pairs(bar.slots) do
		if tab > maxTabs then slot:Hide() end
	end

	-- Blizzard shows its purchase button until every tab is bought
	local purchase = bar.purchaseButton
	if numPurchased < maxTabs then
		Place(purchase)
		purchase:SetEnabled(not InCombatLockdown())

		local tabData = C_Bank.FetchNextPurchasableBankTabData(bankType)
		local canAfford = tabData and tabData.canAfford
		local tooExpensive = canAfford ~= nil and not issecretvalue(canAfford) and not canAfford
		purchase.text:SetTextColor(st.config.profile.colors.text[tooExpensive and 'red' or 'white']:GetRGB())
	else
		purchase:Hide()
	end

	numButtons = max(numButtons, 1)
	bar:SetSize(
		self.config.buttonwidth * numButtons + spacing * (numButtons - 1) + padding * 2,
		self.config.buttonheight + padding * 2)
end

function INV:InitializeBankBagSlots(container)
	if not (C_Bank and C_Bank.FetchMaxNumBankTabs) then return end

	local bar = st:CreateFrame('frame', container:GetName() .. 'BagSlotFrame', container)
	bar:Hide()
	st:SetBackdrop(bar, 'thick')
	bar:SetPoint('BOTTOMLEFT', container, 'TOPLEFT', 0, self.config.buttonspacing)
	bar.slots = {}
	bar.purchaseButton = CreateBankBagPurchaseButton(bar)

	-- Only listen while the bar is visible; it hides along with the bank
	bar:SetScript('OnShow', function(bar)
		for _, event in ipairs(BANK_BAG_SLOT_EVENTS) do
			bar:RegisterEvent(event)
		end
		INV:UpdateBankBagSlots(bar)
	end)
	bar:SetScript('OnHide', bar.UnregisterAllEvents)
	bar:SetScript('OnEvent', function(bar) INV:UpdateBankBagSlots(bar) end)

	local slotToggle = st:CreateButton(nil, container.header, 'Bag Slots', 'none')
	slotToggle:SetPoint('LEFT', 8, 0)
	slotToggle:SetSize(64, st.config.profile.headers.height - 8)
	slotToggle:SetScript('OnClick', function() bar:SetShown(not bar:IsShown()) end)
	container.header.slotToggle = slotToggle

	container.bagSlotContainer = bar
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
    local container = self:CreateContainer('bank', BANK, true)
    self:InitializeBankBagSlots(container)
end