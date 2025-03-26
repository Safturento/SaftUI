local st = SaftUI
local INV = st:NewModule('Inventory')

local BAG_IDS
if st.retail then
	BAG_IDS = {
		['bag'] = { 0, 1, 2, 3, 4, 5 },
		['bank'] = { -1, 6, 7, 8, 9, 10, 11, 12 },
		['reagent'] = { -3 },
		['warband'] = { 13, 14, 15, 16, 17 }
	}
else
	BAG_IDS = {
		['bag'] = { 0, 1, 2, 3, 4 },
		['bank'] = { -1, 5, 6, 7, 8, 9, 10, 11 },
		['reagent'] = { -3 }
	}
end

INV.containers = {}
INV.OnUseItems = {}

function INV:SelectBankCategory(clickedHeader)
	local selectedContainer = clickedHeader:GetParent()
    if selectedContainer.id == 'reagent' then
        BankFrame_ShowPanel(ReagentBankFrame)
    elseif selectedContainer.id == 'warband' then
        BankFrame_ShowPanel('AccountBankPanel')
    else
        BankFrame_ShowPanel('BankSlotsFrame')
    end

    for containerName, container in pairs(self.containers) do
        if containerName == selectedContainer.id then
            container.backdrop:SetBackdropBorderColor(unpack(st.config.profile.colors.button.blue))
        else
            st:SetBackdrop(container, self.config.template)
        end
    end
end


function INV:GetContainer(containerName)
	return self.containers[containerName]
end

function INV:CreateContainer(id, name, isBankContainer)
	local container = CreateFrame('frame', st.name ..name, UIParent)
	container.id = id
	container:SetFrameStrata('HIGH')
	self.containers[id] = container

	st:CreateCloseButton(container)
	st:CreateHeader(container, name)
	self:InitializeFooter(container)
	if id == 'bag' then
		self:InitializeSearch(container)
	end

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

	if isBankContainer then
		 self:HookScript(container.header, 'OnClick', 'SelectBankCategory')
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

		goldstring:SetScript('OnEnter', function(self) INV:DisplayServerGold() end)
		goldstring:SetScript('OnLeave', st.HideGameTooltip)

		container.footer.gold = goldstring
		self:UpdateGold()
	elseif container.id == 'bank' and st.retail then
		local reagentButton = st:CreateButton('ReagentBankButton', container, 'Reagents')
		reagentButton:SetPoint('BOTTOMRIGHT', container.footer, -3, 3)
		reagentButton:SetScript('OnClick', function()
			if not self.containers.reagent then
				self:InitializeReagentBank()
			else
				ToggleFrame(self.containers.reagent)
			end
		end)
		reagentButton:SetSize(80, 16)
		reagentButton:SetFrameLevel(90)

		local warbandButton = st:CreateButton('WarbandBankButton', container, 'Warband Bank')
		warbandButton:SetPoint('BOTTOMRIGHT', reagentButton, 'BOTTOMLEFT', -7, 0)
		warbandButton:SetScript('OnClick', function()
			if not self.containers.warband then
				self:InitializeWarbandBank()
			else
				ToggleFrame(self.containers.warband)
			end
		end)
		warbandButton:SetSize(100, 16)
		warbandButton:SetFrameLevel(90)

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
	local search = st:CreateEditBox(container:GetName()..'Search',  container.footer, 'SearchBoxTemplate')
	st:SkinEditBox(search, 'thicktransparent')
	search:SetHeight(20)
	self:HookScript(search, 'OnTextChanged', 'UpdateSearchFilter')
	container.search = search
end

function INV:ParseSearchQuery(queryString)
	local entries = { (";"):split(queryString) }
	local info = {}

	for _, entry in pairs(entries) do
		entry = entry:lower()
		if entry == "soulbound" then
			info.showSoulbound = true
		elseif entry == "warbound" then
			info.showWarbound = true
		elseif entry == "boe" then
			info.showBoE = true
		elseif entry == "useable" then
			info.showUsable = true
		end
	end

	return info
end

function INV:SearchMatches(queryString, info)
	local queryTags = INV:ParseSearchQuery(queryString)
	queryString = queryString:lower()

	local showBoE = queryTags.showBoE and info.isBoE
	local showSoulbound = queryTags.showSoulbound and info.isSoulbound and not info.isWarbound
	local showWarbound = queryTags.showWarbound and info.isWarbound

	return showSoulbound or showWarbound or showBoE
			or info.name:lower():find(queryString)
			or (info.equipSlot and info.equipSlot:lower() == queryString)
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
	self:GetContainer('bag').footer.gold.text:SetText(st.StringFormat:GoldFormat(money))
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
		local color = summary.class and RAID_CLASS_COLORS[summary.class] or { r = 1, g = 1, b = 1 }
		GameTooltip:AddDoubleLine(toonName, summary.gold and st.StringFormat:GoldFormat(summary.gold) or "??", color.r, color.g, color.b)
		totalGold = totalGold + (summary.gold or 0)
	end


	local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
	totalGold = totalGold + warbandGold
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine("Warband bank", st.StringFormat:GoldFormat(warbandGold))

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
	if not container and container:IsShown() then return end
	local sortedInventory = self:GetSortedInventory(id)

	for name, items in pairs(sortedInventory) do
		self:UpdateCategory(id, name, items)
	end

	self:UpdateCurrencyCategory(container.filterButton:GetChecked())

	self:FlushCategories(container, sortedInventory)

	self:UpdateContainerLayout(id)

	local empty, total = self:GetNumContainerSlots(container)
	container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
end

function INV:UpdateContainerLayout(id)
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
			if firstOfColumn and ((breakPoint and newCount >= breakPoint) or newCount > self.config[container.id].maxRows) then
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

	container:SetHeight(max(200, height + tallestColumnHeight))
	container:SetWidth(max(300, (prev and numColumns * prev:GetWidth() or 0) + (numColumns + 1) * self.config.padding))
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

function INV:UpdateVisibleContainers()
	for containerName, container in pairs(self.containers) do
		if container:IsShown() then
			self:UpdateContainer(containerName)
		end
	end
	self:UpdateSearchFilter(self.containers.bag.search, false)
end

function INV:UpdateHandler(_, elapsed)
	if self.IS_UPDATING or not self.NEED_UPDATE then return end

	self.IS_UPDATING = true
	self.NEED_UPDATE = false
	self:UpdateGold()
	self:UpdateVisibleContainers()
	self.IS_UPDATING = false
end

function INV:QueueUpdate()
	self.NEED_UPDATE = true
end

function INV:ToggleBags()
	if IsOptionFrameOpen() then return end

	if INV.containers.bag:IsShown() then
		INV:HideBags()
	else
		INV:ShowBags()
	end
end

function INV:ShowBags()
	if C_CurrencyInfo.IsAccountCharacterCurrencyDataReady and not (C_CurrencyInfo.IsAccountCharacterCurrencyDataReady()) then
		C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
	end
	INV.containers.bag:Show()
	INV:QueueUpdate()
	INV:UpdateCooldowns()
	INV:MovePlayerBagSlots()
end

function INV:HideBags()
	INV.containers.bag:Hide()
	if not INV.containers.bag.slots then return end
	for _,slot in pairs(INV.containers.bag.slots) do
		C_NewItems.RemoveNewItem(slot.info.bagID, slot.info.slotID)
	end
	if INV.containers.bank and INV.containers.bank:IsShown() then
		INV.containers.bank:Hide()
		HideUIPanel(BankFrame);
		C_Bank.CloseBankFrame();
	end
	if CurrencyTransferMenu and CurrencyTransferMenu:IsShown() then CurrencyTransferMenu:Hide() end
end

function INV:DisableBlizzardBank()
	BankFrame:ClearAllPoints()
	BankFrame:SetPoint('RIGHT', UIParent, 'LEFT', -100, 0)
	BankFrame.SetPoint = function() end
end

function INV:OpenBank()
	if not self.containers.bank then
		self:CreateContainer('bank', BANK, true)
		self:MoveBankBagSlots()
	end
	self.containers.bank:Show()
	self:ShowBags()
	self:UpdateVisibleContainers()
end

function INV:CloseBank()
	self.containers.bank:Hide()
	self:HideBags()
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
	if st.retail then
		self:SecureHook(CharacterReagentBag0Slot, 'SetBarExpanded', 'MovePlayerBagSlots')
		self:SecureHook(MainMenuBarBagManager, 'OnExpandBarChanged', 'MovePlayerBagSlots')
	end
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
	--ToggleBackpack		= INV.ToggleBags
	--ToggleBag 			= INV.ToggleBags
	--ToggleAllBags 		= INV.ToggleBags
	--OpenAllBags 		= INV.ShowBags
	--OpenBackpack 		= INV.ShowBags
	--OpenBag 			= INV.ShowBags
	--CloseAllBags 		= INV.HideBags
	--CloseBackpack 		= INV.HideBags
	--CloseBag			= INV.HideBags

	self:SecureHook('OpenAllBags', 'ShowBags')
	self:SecureHook('CloseAllBags', 'HideBags')
	self:SecureHook('ToggleBag', 'ToggleBags')
	self:SecureHook('ToggleAllBags', 'ToggleBags')
	self:SecureHook('ToggleBackpack', 'ToggleBags')

	for _,frame in pairs({ BankFrame, ContainerFrameCombinedBags }) do
		if frame then
			frame:UnregisterAllEvents()
			frame:SetScript('OnShow', nil)
			frame:SetScript('OnHide', nil)
			frame:SetParent(st.HiddenFrame)
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOM")
		end
	end

	if ContainerFrameCombinedBags then
		ContainerFrameCombinedBags:RegisterEvent('BAG_CONTAINER_UPDATE')
	end

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