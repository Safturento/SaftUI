local st = SaftUI
local INV = st:NewModule('Inventory')

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

	if not INV.config.filters.categories[id] then
		INV.config.filters.categories[id] = {}
	end

	local filterButton = st:CreateCheckButton(nil, container.header)
    container.header.filterButton = filterButton
    filterButton:SetPoint('TOPRIGHT', -30, -5)
    filterButton:SetSize(40, 20)

    filterButton.text:SetAllPoints(filterButton)
    filterButton:SetFont('pixel')
    filterButton:SetText('Edit')
    filterButton:SetScript('OnClick', function()
        INV:UpdateContainer(id)
        for categoryName, category in pairs(container.categories) do
            category.filterCheckbox:SetShown(filterButton:GetChecked())
            category.filterCheckbox:SetChecked(INV.config.filters.categories[id][categoryName])
        end
    end)
    container.filterButton = filterButton

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
		local reagentButton = st:CreateButton('ReagentBankButton', container, 'Reagents')
		reagentButton:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
		reagentButton:SetScript('OnClick', function()
			if not self.containers.reagent then
				self:InitializeReagentBank()
			else
				ToggleFrame(self.containers.reagent)
			end
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

function INV:SearchMatches(query, info)
	query = query:lower()
	return info.name:lower():find(query)
		or (info.equipSlot and info.equipSlot:lower() == query)
end

function INV:UpdateSearchFilter(editbox, is_user_input)
	local query = editbox:GetText()
	for _,container in pairs(self.containers) do
		if container:IsShown() then
			for _,category in pairs(container.categories) do
				for _,slot in pairs(category.slots) do
					if slot:IsShown() then
						if self:SearchMatches(query, slot.info) then
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

function INV:UpdateContainer(id)
	local container = self.containers[id]
	if not container:IsShown() then return end
	local sortedInventory = self:GetSortedInventory(id)

	for name, items in pairs(sortedInventory) do
		self:UpdateCategory(id, name, items)
	end

	self:UpdateCurrencyCategory(container.filterButton:GetChecked())

	self:FlushCategories(container, sortedInventory)

	self:UpdateContainerHeight(id)

	local empty, total = self:GetNumContainerSlots(container)
	container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
end

function INV:UpdateContainerHeight(id)
	local container = self.containers[id]
	local height = container.header:GetHeight() + container.footer:GetHeight() + self.config.padding * 2

	if container.search then
		container.search:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
		height = height + container.search:GetHeight()
	end

	local totalRows = 0
	for _,category in pairs(container.categories) do
		if category:IsShown() then
			totalRows = totalRows + category.numRows + 1
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
	for categoryName, category in pairs(container.categories) do
		if not container.filterButton:GetChecked() and INV.config.filters.categories[id][categoryName] then
			INV:FlushCategory(category)
		end

		if category and category:IsShown() then

			category:ClearAllPoints()

			local newCount = (rowCount + category.numRows + 1)
			if (breakPoint and newCount >= breakPoint) or newCount > self.config[container.id].maxRows then
				category:SetPoint('TOPLEFT', firstOfColumn, 'TOPRIGHT', self.config.padding, 0)
				firstOfColumn = category
				numColumns = numColumns + 1
				currentColumnHeight = 0
				rowCount = 0
			elseif prev then
				category:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -self.config.categoryspacing)
			else
				category:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
			end

			rowCount = rowCount + category.numRows + 1
			currentColumnHeight = currentColumnHeight + category:GetHeight() + self.config.categoryspacing
			tallestColumnHeight = math.max(tallestColumnHeight, currentColumnHeight)

			if not firstOfColumn then firstOfColumn = category end

			prev = category
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
	
	for _, category in pairs(container.categories) do
		category:SetWidth(inner_width)
	end
	if container.search then
		container.search:SetWidth(inner_width)
		st:SkinEditBox(container.search, self.config.template, self.config.fonts.titles)
	end

	st:SetBackdrop(container, self.config.template)
end

local lastUpdate = 0
local interval = .01


local barrier = createBarrier(1)

function INV:UpdateHandler(_, elapsed)


	if self.NEED_UPDATE and not self.IS_UPDATING then
		self.IS_UPDATING = true
		self.NEED_UPDATE = false
		self:UpdateGold()
		self:UpdateContainer('bag')
		if self.containers.bank then
			self:UpdateContainer('bank')
		end

		if self.containers.reagent then
			self:UpdateContainer('reagent')
		end
		self.IS_UPDATING = false
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
	self:UpdateContainer('bank')
	self.containers.bank:Show()
end

function INV:CloseBank()
	self.containers.bank:Hide()
end

function INV:OnInitialize()
	self.config = st.config.profile.inventory
	if self.config.enable == false then return end

	if not self.config.filters then
		self.config.filters = {}
	end

	if not self.config.filters.categories then
        self.config.filters.categories = {}
    end

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
	slotToggle:SetScript('OnClick', function() bagSlotContainer:SetShown(not bagSlotContainer:IsShown())  end)
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
	self:UpdateContainer('bag')

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