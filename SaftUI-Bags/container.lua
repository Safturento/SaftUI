local st = SaftUI
local INV = st:GetModule('Inventory')


function INV:GetContainer(containerName)
	return self.containers[containerName]
end

function INV:CreateContainer(id, name, isBankContainer)
	local container = CreateFrame('frame', st.name ..name, UIParent)
	container.id = id
	container:SetFrameStrata('HIGH')
	self.containers[id] = container

	container.scrollFrame = st:CreateScrollFrame(container)
	container.scrollFrame:SetScript('OnMouseWheel', function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * INV.config.scrollSpeed * (INV.config.buttonheight + INV.config.buttonspacing))

        newScroll = max(0, min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

	st:CreateCloseButton(container)
	st:CreateHeader(container, name)
	self:InitializeFooter(container)
	if id == 'bag' then
		self:InitializeSearch(container)
	end

    if container.search then
        container.scrollFrame:SetPoint('TOPLEFT', container.search, 'BOTTOMLEFT', 0, -self.config.padding)
    else
        container.scrollFrame:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
    end

	container.slots = {}
	container.categories = {}
	container.columns = {}
	container.bag_ids = self.bagIds[id]

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
		local bag = CreateFrame('frame', 'SaftUI_Bag'..bag_id, container.scrollFrame.ScrollChild)
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
		info.tooltipText:lower():find(queryString)
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
	if st.retail then
        self:UpdateWarbandMoney()
        self:UpdateCombinedBankWarbandMoney()
    end
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

local function getShortestColumn(columns)
    local shortest = columns[1]
    local minHeight = shortest:GetHeight()

    for i=2, #columns do
        local height = columns[i]:GetHeight()
        if height < shortest:GetHeight() then
            shortest = columns[i]
        end
    end

    return shortest
end

local function getTallestColumn(columns)
    local tallest = columns[1]
    local maxHeight = tallest:GetHeight()

    for i=2, #columns do
        local height = columns[i]:GetHeight()
        if height > tallest:GetHeight() then
            tallest = columns[i]
        end
    end

    return tallest
end

local function getNumUsedColumns(columns)
    for i=2, #columns do
        if columns[i]:GetHeight() == 0 then
            return i-1
        end
    end

    return #columns
end

function INV:UpdateContainerLayout(id)
	local container = self.containers[id]
	local height = container.header:GetHeight() + container.footer:GetHeight() + self.config.padding * 2

	if container.search then
		container.search:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
		height = height + container.search:GetHeight()
	end

	local totalRows = 0
	for _, category in pairs(container.categories) do
		if category:IsShown() then
			totalRows = totalRows + category.numRows + 1
		end
	end

    local columns = container.columns
    local containerConfig = self.config[container.id]

    local maxHeight = self.config.buttonheight * containerConfig.maxRows
                    + self.config.buttonspacing * (containerConfig.maxRows - 1)

    local maxWidth = self.config.buttonheight * containerConfig.maxColumns
                    + self.config.buttonspacing * (containerConfig.maxColumns - 1)

     for _, column in pairs(container.columns) do
         column:SetHeight(0)
         column.categories = {}
     end

    local prev
    local sorted = {}

    for _, category in pairs(container.categories) do
        tinsert(sorted, category)
    end
    table.sort(sorted, function(a,b) return a:GetHeight() > b:GetHeight() end)

    for _, category in pairs(sorted) do
        if not container.filterButton:GetChecked() and INV.config.filters.categories[id][category.name] then
            INV:FlushCategory(category)
        end

        if category and category:IsShown() then
            category:ClearAllPoints()

            local column = getShortestColumn(container.columns)
            category:ClearAllPoints()
            if #column.categories == 0 then
                category:SetPoint('TOPLEFT', column, 'TOPLEFT', 0, 0)
            else
                category:SetPoint('TOPLEFT', column.categories[#column.categories], 'BOTTOMLEFT', 0, -self.config.buttonspacing)
            end

            tinsert(column.categories, category)
            column:SetHeight(column:GetHeight() + category:GetHeight() + self.config.buttonspacing)
        end
    end

     for _, column in pairs(container.columns) do
         column:SetHeight(column:GetHeight() - self.config.buttonspacing)
     end

    local numUsedColumns = getNumUsedColumns(container.columns)
    local tallestColumn = getTallestColumn(container.columns)
    local scrollFrameWidth = numUsedColumns * (container.columns[1]:GetWidth() + self.config.buttonspacing) - self.config.buttonspacing


    container.scrollFrame:SetSize(
        scrollFrameWidth,
        min(tallestColumn:GetHeight() + self.config.padding, containerConfig.maxRows * (self.config.buttonheight + self.config.buttonspacing) - self.config.buttonspacing)
    )
    container.scrollFrame:SetContentSize(scrollFrameWidth, tallestColumn:GetHeight())

	container:SetHeight(max(200, height + container.scrollFrame:GetHeight()))
	container:SetWidth(container.scrollFrame:GetWidth() + self.config.padding * 2)
end
