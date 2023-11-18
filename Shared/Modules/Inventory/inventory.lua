local st = SaftUI
local INV = st:NewModule('Inventory', 'AceHook-3.0', 'AceEvent-3.0')

local BACKPACK_IDS = {0, 1, 2, 3, 4}
local BANK_IDS = {-1, 5, 6, 7, 8, 9, 10, 11}

local BAG_IDS = {
	['bag'] = {0, 1, 2, 3, 4, 5},
	['bank'] = {-1, 6, 7, 8, 9, 10, 11, 12},
	['reagent'] = {-3}
}

INV.containers = {}
INV.OnUseItems = {}

function INV:CreateContainer(id, name)
	local container = CreateFrame('frame', st.name ..name, UIParent)
	container.id = id
	container:SetFrameStrata('HIGH')
	self.containers[id] = container

	st:CreateCloseButton(container)
	st:CreateHeader(container, name)
	self:InitializeFooter(container)
	self:InitializeSearch(container)

	container.slots = {}
	container.categories = {}
	container.bag_ids = BAG_IDS[id]

	container.bags = {}
	for _, bag_id in pairs(container.bag_ids) do
		local bag = CreateFrame('frame', 'SaftUI_Bag'..bag_id, container)
		bag:SetID(bag_id)
		container.bags[bag_id] = bag
	end

	self:UpdateConfig(id)
	return container
end

function INV:InitializeFooter(container)
	st:CreateFooter(container)

	local slottext = container.footer:CreateFontString(nil, 'OVERLAY')
	slottext:SetFontObject(st:GetFont(st.config.profile.headers.font))
	slottext:SetPoint('LEFT', 10, 0)
	slottext:SetText('#/# Slots Used')
	slottext:SetJustifyH('LEFT')
	container.footer.slots = slottext

	if container.id == 'bag' then
		local goldstring = CreateFrame('frame', nil, container.footer)
		goldstring:EnableMouse(true)
		goldstring:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
		goldstring:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
		goldstring:SetWidth(120)

		goldstring.text = goldstring:CreateFontString(nil, 'OVERLAY')
		goldstring.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
		goldstring.text:SetPoint('RIGHT', goldstring, 'RIGHT', -10, 0)
		goldstring.text:SetJustifyH('RIGHT')

		goldstring:SetScript('OnEnter', function() INV:DisplayServerGold() end)
		goldstring:SetScript('OnLeave', st.HideGameTooltip)

		container.footer.gold = goldstring
		self:UpdateGold()
	elseif container.id == 'bank' then
		local reagentButton = st:CreateButton('ReagentBankButton', container, 'Reagents', 'highlight')

		reagentButton:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
		reagentButton:SetScript('OnClick', function()
			self:InitializeReagentBank()
		end)
		reagentButton:SetSize(100, 16)
		reagentButton:SetFrameLevel(90)

	elseif container.id == 'reagent' then
		local deposit = ReagentBankFrame.DespositButton
		deposit:SetSize(200, 16)
		deposit:SetParent(container)
		deposit:ClearAllPoints()
		deposit:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
		st:SkinActionButton(deposit)
	end
end

function INV:InitializeSearch(container)
	local search = st.Widgets:EditBox(container:GetName()..'Search',  container.footer, 'SearchBoxTemplate')
	st:SkinEditBox(search, 'thicktransparent')
	search:SetHeight(20)
	self:HookScript(search, 'OnTextChanged', 'UpdateSearchFilter')
	container.search = search
end

function INV:UpdateSearchFilter(editbox, is_user_input)
	local query = editbox:GetText():lower()
	for _,container in pairs(self.containers) do
		if container:IsShown() then
			for _,category in pairs(container.categories) do
				for _,slot in pairs(category.slots) do
					if slot:IsShown() then
						if slot.info.name:lower():find(query) then
							slot:SetAlpha(1)
						else
							slot:SetAlpha(0.1)
						end
					end
				end
			end
		end
	end
end

function INV:UpdateGold()
	local money = GetMoney()
	self.containers.bag.footer.gold.text:SetText(st.StringFormat:GoldFormat(money))
	st.config.realm.summary[st.my_name].gold = money
end

function INV:DisplayServerGold()
	GameTooltip:SetOwner(self.containers.bag, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', self.containers.bag, 'TOPLEFT', -10, 0)
	
	GameTooltip:ClearLines()	
	-- List server wide gold
	GameTooltip:AddLine('Gold on ' .. st.my_realm)
	local totalGold = 0
	for toonName, summary in pairs(st.config.realm.summary) do 
		GameTooltip:AddDoubleLine(toonName, summary.gold and st.StringFormat:GoldFormat(summary.gold) or "??", 1,1,1)
		totalGold = totalGold + (summary.gold or 0)
	end
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Total', st.StringFormat:GoldFormat(totalGold))

	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Vendor profit', st.StringFormat:GoldFormat(select(2, self:GetVendorItems())))
	
	GameTooltip:Show()
end

function INV:GetNumContainerSlots(container)
	local empty, total = 0, 0
	for _,bagID in pairs(container.bag_ids) do
		empty = empty + C_Container.GetContainerNumFreeSlots(bagID)
		total = total + C_Container.GetContainerNumSlots(bagID)
	end

	return empty, total
end

function INV:UpdateContainerItems(id)
	local container = self.containers[id]
	if not container:IsShown() then return end
	local sorted_inv = self:GetSortedInventory(id)

	for cat_name, cat_items in pairs(sorted_inv) do
		self:UpdateCategory(id, cat_name, cat_items)
	end

	self:FlushCategories(container, sorted_inv)

	self:UpdateContainerHeight(container)

	local empty, total = self:GetNumContainerSlots(container)
	container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
end

function INV:UpdateContainerHeight(container)
	local height = container.header:GetHeight() + container.footer:GetHeight() + self.config.padding * 2

	if container.search then
		container.search:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
		height = height + container.search:GetHeight()
	end

	local totalRows = 0
	for _,categoryFrame in pairs(container.categories) do
		if categoryFrame:IsShown() then
			totalRows = totalRows + categoryFrame.numRows + 1
		end
	end
	local breakPoint
	if totalRows > self.config[container.id].maxRows then
		 breakPoint = math.ceil(totalRows / 2) + 2
	end

	local prev = container.search
	local firstOfColumn
	local rowCount = 0
	local tallestColumnHeight = 0
	local currentColumnHeight = 0
	local numColumns = 1
	for _,category_frame in pairs(container.categories) do
		if category_frame and category_frame:IsShown() then

			category_frame:ClearAllPoints()

			local newCount = (rowCount + category_frame.numRows + 1)
			if (breakPoint and newCount >= breakPoint) or newCount > self.config[container.id].maxRows then
				category_frame:SetPoint('TOPLEFT', firstOfColumn, 'TOPRIGHT', self.config.padding, 0)
				firstOfColumn = category_frame
				numColumns = numColumns + 1
				currentColumnHeight = 0
				rowCount = 0
			elseif prev then
				category_frame:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -self.config.categoryspacing)
			else
				category_frame:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
			end

			rowCount = rowCount + category_frame.numRows + 1
			currentColumnHeight = currentColumnHeight + category_frame:GetHeight() + self.config.categoryspacing
			tallestColumnHeight = math.max(tallestColumnHeight, currentColumnHeight)

			if not firstOfColumn then firstOfColumn = category_frame end

			prev = category_frame
		end
	end

	container:SetHeight(height + tallestColumnHeight)
	container:SetWidth(numColumns * prev:GetWidth() + (numColumns + 1) * self.config.padding)
end

function INV:UpdateConfig(id)
	local container = self.containers[id]
	
	container:ClearAllPoints()
	container:SetPoint(unpack(self.config[id].position))

	local inner_width = (self.config.buttonwidth + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing

	container:SetWidth(self.config.padding * 2 + inner_width)
	container:SetHeight(200)
	
	for cat, category_frame in pairs(container.categories) do
		category_frame:SetWidth(inner_width)
	end
	if container.search then
		container.search:SetWidth(inner_width)
		st:SkinEditBox(container.search, self.config.template, self.config.fonts.titles)
	end

	st:SetBackdrop(container, self.config.template)
end

local lastUpdate = 0
local interval = .01

function INV:UpdateHandler(elapsed)
	-- Don't let the bags spam update, just wait
	local time = GetTime()
	if time - lastUpdate < interval then return end

	lastUpdate = time

	if self.NEED_UPDATE and not self.BLOCK_UPDATE then
		self.NEED_UPDATE = false
		self:UpdateGold()
		self:UpdateContainerItems('bag')
		if self.containers.bank then
			self:UpdateContainerItems('bank')
		end

		if self.containers.reagent then
			self:UpdateContainerItems('reagent')
		end
	end
end

function INV:QueueUpdate()
	self.NEED_UPDATE = true
end

function INV:ToggleBags()
	if INV.containers.bag:IsShown() then
		INV:HideBags()
	else
		INV:ShowBags()
	end
end

function INV:ShowBags()
	INV.containers.bag:Show()
	INV:QueueUpdate()
	INV:UpdateCooldowns()
	INV:MovePlayerBagSlots()
end

function INV:HideBags() 
	INV.containers.bag:Hide()
	for _,slot in pairs(INV.containers.bag.slots) do
		C_NewItems.RemoveNewItem(slot.info.bagID, slot.info.slotID)
	end
	if INV.containers.bank and INV.containers.bank:IsShown() then
		INV.containers.bank:Hide()
		BankFrame:Hide()
	end
end

function INV:DisableBlizzardBank()
	BankFrame:ClearAllPoints()
	BankFrame:SetPoint('BOTTOMRIGHT', UIParent, 'TOPLEFT', -100, 100)
	BankFrame.SetPoint = function() end
end

function INV:OpenBank()
	if not self.containers.bank then
		self:CreateContainer('bank', BANK)
		self:MoveBankBagSlots()
		self:DisableBlizzardBank()
		-- self:SecureHook('ContainerFrameItemButton_OnEnter', 'SetBankItemTooltip')
	end
	self:UpdateContainerItems('bank')
	self.containers.bank:Show()
end

function INV:CloseBank()
	self.containers.bank:Hide()
end

function INV:OnInitialize()
	self.config = st.config.profile.inventory
	if self.config.enable == false then return end

	self:CreateContainer('bag', INVTYPE_BAG)
	self:InitializePlayerBagSlots()
	self.containers.bag:Hide()
	self:InitializeAllCategories('bag')
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

	CharacterReagentBag0Slot.icon = CharacterReagentBag0SlotIconTexture
	tinsert(BagSlots, CharacterReagentBag0Slot)

	local bagSlotContainer = st:CreateFrame('frame', 'BagSlotFrame', self.containers.bag)
	bagSlotContainer:SetSize(
		self.config.buttonwidth * #BagSlots + self.config.buttonspacing * (#BagSlots - 1) + self.config.padding * 2,
		self.config.buttonheight + self.config.padding * 2)
	st:SetBackdrop(bagSlotContainer, 'thick')
	bagSlotContainer:SetPoint('BOTTOMLEFT', self.containers.bag, 'TOPLEFT', 0, self.config.buttonspacing)

	bagSlotContainer.slots = BagSlots

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
	self:SecureHook(CharacterReagentBag0Slot, 'SetBarExpanded', 'MovePlayerBagSlots')
	self:SecureHook(MainMenuBarBagManager, 'OnExpandBarChanged', 'MovePlayerBagSlots')
end

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

function INV:ADDON_LOADED(event, addon)
	if addon == 'ItemRackOptions' then
		self:SecureHook(ItemRackOpt, 'SaveSet', 'UpdateItemRackCategories')
		self:SecureHook(ItemRackOpt, 'DeleteSet', 'UpdateItemRackCategories')
	end
end

function INV:OnEnable()
	ToggleBackpack		= INV.ToggleBags
	ToggleBag 			= INV.ToggleBags
	ToggleAllBags 		= INV.ToggleBags
	OpenAllBags 		= INV.ShowBags
	OpenBackpack 		= INV.ShowBags
	OpenBag 			= INV.ShowBags
	CloseAllBags 		= INV.HideBags
	CloseBackpack 		= INV.HideBags
	CloseBag			= INV.HideBags

	self:InitializeTooltipScanner()

	if ItemRack then
	self:UpdateItemRackCategories()
	end

	self:RegisterEvent("ADDON_LOADED", "ADDON_LOADED")

	-- Make sure the slots are all created immediately intead of on first open
	-- We do this to avoid tainting all of the slots when the bag is first opened
	-- while in combat
	self:UpdateContainerItems('bag')

	self:RegisterEvent('PLAYER_MONEY', 'UpdateGold')
	self:RegisterEvent('MERCHANT_SHOW', 'HandleMerchant')

	self:RegisterEvent('BAG_UPDATE', 'QueueUpdate')
	self:RegisterEvent('ITEM_LOCK_CHANGED', 'QueueUpdate')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'QueueUpdate')

	self:RegisterEvent('BANKFRAME_OPENED', 'OpenBank')
	self:RegisterEvent('BANKFRAME_CLOSED', 'CloseBank')

	self.updater = CreateFrame('frame')
	self:HookScript(self.updater, 'OnUpdate', 'UpdateHandler')
end