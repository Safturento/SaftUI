local st = SaftUI
local INV = st:NewModule('Inventory')

local BAG_IDS
if st.retail then
	BAG_IDS = {
		['bag'] = { 0, 1, 2, 3, 4, 5 },
		['bank'] = { -1, 6, 7, 8, 9, 10, 11, 12 },
		['reagent'] = { -3 },
		['warband'] = { 13, 14, 15, 16, 17 },
		['combinedbank'] = { -3, -1, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
	}
else
	BAG_IDS = {
		['bag'] = { 0, 1, 2, 3, 4 },
		['bank'] = { -1, 5, 6, 7, 8, 9, 10, 11 },
		['reagent'] = { -3 }
	}
end

INV.bagIds = BAG_IDS

INV.containers = {}
INV.OnUseItems = {}

function INV:SelectBankCategory(clickedHeader)
	local selectedContainer = clickedHeader:GetParent()
	if selectedContainer.id == 'reagent' then
		BankFrame_ShowPanel(ReagentBankFrame)
	elseif selectedContainer.id == 'warband' then
		BankFrame_ShowPanel('AccountBankPanel')
	elseif selectedContainer.id == 'bank' then
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
	filterButton:Hide()
    container.filterButton = filterButton

	container.bags = {}
	for _, bag_id in pairs(container.bag_ids) do
		local bag = CreateFrame('frame', 'SaftUI_Bag'..bag_id, container)
		bag:SetID(bag_id)
		container.bags[bag_id] = bag
	end

	self:InitializeLoadingOverlay(container)

	if isBankContainer and id ~= 'combinedbank' then
		 self:HookScript(container.header, 'OnClick', 'SelectBankCategory')
	end

	self:UpdateConfig(id)
	return container
end

function INV:InitializeLoadingOverlay(container)
	local loadingOverlay = st:CreateFrame('frame', container:GetName().."LoadingOverlay", container)
	loadingOverlay:SetBackdrop(st.BACKDROP)
	loadingOverlay:SetBackdropColor(0, 0, 0, .7)
	loadingOverlay:SetAllPoints()
	loadingOverlay:SetFrameStrata('HIGH')
	loadingOverlay:SetFrameLevel(50)

	local loadingBar = st:CreateStatusBar(container:GetName().."LoadingBar", loadingOverlay, '-/-')
	loadingBar:SetPoint('CENTER')
	loadingBar:SetSize(300, 30)
	loadingBar:SetStatusBarColor(unpack(st.config.profile.colors.button.blue))
	loadingOverlay.loadingBar = loadingBar

	container.loadingOverlay = loadingOverlay
	container.SetLoading = function(self, current, max)
		if current == max then
			loadingOverlay:Hide()
			return
		end
		loadingOverlay:Show()
		loadingBar:SetMinMaxValues(0, max)
		loadingBar:SetValue(current)
		loadingBar.text:SetFormattedText('%d / %d', current, max)
	end
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
		local gold = CreateFrame('frame', nil, container.footer)
		gold:EnableMouse(true)
		gold:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
		gold:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
		gold:SetWidth(120)

		gold.text = gold:CreateFontString(nil, 'OVERLAY')
		gold.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
		gold.text:SetPoint('RIGHT', gold, 'RIGHT', -10, 0)
		gold.text:SetJustifyH('RIGHT')

		gold:SetScript('OnEnter', function(self) INV:DisplayServerGold() end)
		gold:SetScript('OnLeave', st.HideGameTooltip)

		container.footer.gold = gold
		self:UpdateGold()
	elseif container.id == 'bank' and st.retail then
		local reagentButton = st:CreateButton('ReagentBankButton', container, 'Reagents')
		reagentButton:SetPoint('BOTTOMRIGHT', container.footer, -6, 6)
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
	end
end

function INV:CreateGoldString(container)
    local goldString = CreateFrame('frame', nil, container.footer)
    goldString:EnableMouse(true)
    goldString:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
    goldString:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
    goldString:SetWidth(120)

    goldString.text = goldString:CreateFontString(nil, 'OVERLAY')
    goldString.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
    goldString.text:SetPoint('RIGHT', goldString, 'RIGHT', -10, 0)
    goldString.text:SetJustifyH('RIGHT')

    goldString:SetScript('OnEnter', function() INV:DisplayServerGold() end)
    goldString:SetScript('OnLeave', st.HideGameTooltip)

	container.footer.gold = goldString

    return goldString
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

	for _, check in pairs({
		queryTags.showBoE and info.isBoE,
		queryTags.showSoulbound and info.isSoulbound and not info.isWarbound,
		queryTags.showWarbound and info.isWarbound,
		info.name:lower():find(queryString),
		(info.equipSlot and info.equipSlot:lower() == queryString),
		(info.class == 'Armor') and queryString:lower():find(info.subclass),
	}) do if check then return true end end
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
	self:UpdateWarbandMoney()
	self:UpdateCombinedBankWarbandMoney()
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

function INV:GetNumContainerSlots(bagIds)
	local empty, total = 0, 0
	for _,bagID in pairs(bagIds) do
		empty = empty + C_Container.GetContainerNumFreeSlots(bagID)
		total = total + C_Container.GetContainerNumSlots(bagID)
	end

	return empty, total
end

function INV:UpdateContainer(id)
	local container = self.containers[id]
	if not container and container:IsShown() then return end
	local sortedInventory, numItems, numLoading = self:GetSortedInventory(id)

	for name, items in pairs(sortedInventory) do
		self:UpdateCategory(id, name, items)
	end

	self:UpdateCurrencyCategory(container.filterButton:GetChecked())

	self:FlushCategories(container, sortedInventory)

	self:UpdateContainerLayout(id)

	container:SetLoading(numItems - numLoading, numItems)

	if container.UpdateContainerSlots then
		container:UpdateContainerSlots()
	else
		local empty, total = self:GetNumContainerSlots(container.bag_ids)
			container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
	end
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
	if not id then
		for containerId, _ in pairs(self.containers) do
			self:UpdateConfig(containerId)
		end
	end

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

function INV:ADDON_LOADED(event, addon)
	if addon == 'ItemRackOptions' then
		self:SecureHook(ItemRackOpt, 'SaveSet', 'UpdateItemRackCategories')
		self:SecureHook(ItemRackOpt, 'DeleteSet', 'UpdateItemRackCategories')
	end
end

function INV:OnEnable()
	self.config = st.config.profile.inventory
	if self.config.enable == false then return end

	if not self.config.filters then
		self.config.filters = {}
	end

	if not self.config.filters.categories then
        self.config.filters.categories = {}
    end

	self:InitializeTooltipScanner()
	self:InitializePlayerBags()

	--ToggleBackpack		= INV.ToggleBags
	--ToggleBag 			= INV.ToggleBags
	--ToggleAllBags 		= INV.ToggleBags
	--OpenAllBags 		= INV.ShowBags
	--OpenBackpack 		= INV.ShowBags
	--OpenBag 			= INV.ShowBags
	--CloseAllBags 		= INV.HideBags
	--CloseBackpack 		= INV.HideBags
	--CloseBag			= INV.HideBags

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


	if ItemRack then
		self:UpdateItemRackCategories()
	end

	-- Make sure the slots are all created immediately intead of on first open
	-- We do this to avoid tainting all of the slots when the bag is first opened
	-- while in combat
	self:UpdateContainer('bag')

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent('PLAYER_MONEY', 'UpdateGold')
	self:RegisterEvent('MERCHANT_SHOW', 'HandleMerchant')

	self:RegisterEvent('BAG_UPDATE', 'QueueUpdate')
	self:RegisterEvent('BAG_UPDATE_DELAYED', 'QueueUpdate')
	self:RegisterEvent('BAG_CONTAINER_UPDATE', 'QueueUpdate')
	self:RegisterEvent('BAG_NEW_ITEMS_UPDATED', 'QueueUpdate')
	self:RegisterEvent('ITEM_LOCK_CHANGED', 'QueueUpdate')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'QueueUpdate')
	self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED', 'QueueUpdate')
	self:RegisterEvent('GET_ITEM_INFO_RECEIVED', 'QueueUpdate')

	if self.config.combinedBank then
		self:RegisterEvent('BANKFRAME_OPENED', 'OpenCombinedBank')
		self:RegisterEvent('BANKFRAME_CLOSED', 'CloseCombinedBank')
	else
		self:RegisterEvent('BANKFRAME_OPENED', 'OpenBank')
		self:RegisterEvent('BANKFRAME_CLOSED', 'CloseBank')
	end

	self.updater = CreateFrame('frame')
	self:HookScript(self.updater, 'OnUpdate', 'UpdateHandler')
end