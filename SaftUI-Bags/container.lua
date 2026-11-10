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
        local newScroll = current - (delta * INV.config.scrollSpeed * (INV:GetButtonHeight() + INV.config.buttonspacing))

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
        -- Showing or hiding the hidden categories re-packs the window.
        INV:ReleaseLayout(container)
        INV:UpdateContainer(id, true)
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

	-- The next time it opens, the window is packed afresh.
	container:HookScript('OnHide', function() INV:ReleaseLayout(container) end)

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

	local loadingBar = st:CreateStatusBar(container:GetName().."LoadingBar", loadingOverlay, '-/-', 'theme', 'solid')
	loadingBar:SetPoint('CENTER')
	loadingBar:SetSize(300, 30)
	loadingBar:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())
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
	elseif container.id == 'bank' and self:HasWarbandBank() then
		-- Neither client has a reagent bank anymore, so the separate bank only
		-- needs the way into the warband window.
		local warbandButton = st:CreateButton('WarbandBankButton', container, 'Warband Bank', 'theme', 'solid')
		warbandButton:SetPoint('BOTTOMRIGHT', container.footer, -6, 6)
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
	st:SkinEditBox(search, 'theme', 'theme')
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
	-- A free slot has nothing to match: it only stays lit with no search.
	if info.empty then return queryString == '' end

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
						-- The reagent wedge isn't faded with the item button.
						local alpha = self:SearchMatches(query, slot.info) and 1 or 0.1
						slot:SetAlpha(alpha)
						slot.reagentMarker:SetAlpha(alpha)
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
		local color = summary.class
			and (st.config.profile.colors.class[summary.class] or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[summary.class]))
			or { r = 1, g = 1, b = 1 }
		GameTooltip:AddDoubleLine(toonName, summary.gold and st.StringFormat:GoldFormat(summary.gold) or "??", color.r, color.g, color.b)
		totalGold = totalGold + (summary.gold or 0)
	end


	if self:HasWarbandBank() then
		local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
		totalGold = totalGold + warbandGold
		GameTooltip:AddLine(' ')
		GameTooltip:AddDoubleLine("Warband bank", st.StringFormat:GoldFormat(warbandGold))
	end

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

function INV:UpdateContainer(id, updateLayout)
	local container = self.containers[id]
	if not container and container:IsShown() then return end
	if id == 'bag' then self:EnsureEmptySlotPool() end
	local sortedInventory, numItems, numLoading = self:GetSortedInventory(id)

	for name, items in pairs(sortedInventory) do
		self:UpdateCategory(id, name, items)
	end

	self:UpdateCurrencyCategory(container.filterButton:GetChecked())

	self:FlushCategories(container, sortedInventory)

	-- A layout is only held once every item is in it (see HoldLayout).
	container.loadingItems = numLoading > 0

	-- Items whose data is still loading (cold item cache after a reload) are left
	-- out until GET_ITEM_INFO_RECEIVED fires, and those updates don't request a
	-- layout. Keep relaying out until loading finishes so they actually appear.
	if updateLayout or container.layoutPending then
		self:UpdateContainerLayout(id)
	end
	container.layoutPending = numLoading > 0

	container:SetLoading(numItems - numLoading, numItems)

	if container.UpdateContainerSlots then
		container:UpdateContainerSlots()
	else
		local empty, total = self:GetNumContainerSlots(container.bag_ids)
			container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
	end
end

-- The shortest column and its index.
local function getShortestColumn(columns)
    local shortest, index = columns[1], 1

    for i=2, #columns do
        if columns[i]:GetHeight() < shortest:GetHeight() then
            shortest, index = columns[i], i
        end
    end

    return shortest, index
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

-- Columns up to the last one holding a category. While a layout is held (see
-- below), a column in the middle can empty out and the ones after it still count.
local function getNumUsedColumns(columns)
    for i = #columns, 1, -1 do
        if #columns[i].categories > 0 then
            return i
        end
    end

    return 1
end

-- Puts a category at the bottom of a column. The column's height counts the
-- spacing after each category; UpdateContainerLayout takes the last one off.
local function addToColumn(column, category, spacing)
    category:ClearAllPoints()
    if #column.categories == 0 then
        category:SetPoint('TOPLEFT', column, 'TOPLEFT', 0, 0)
    else
        category:SetPoint('TOPLEFT', column.categories[#column.categories], 'BOTTOMLEFT', 0, -spacing)
    end

    tinsert(column.categories, category)
    column:SetHeight(column:GetHeight() + category:GetHeight() + spacing)
end

-- A category the player hid (the Edit view's checkboxes) is hidden outside that view.
function INV:FlushIfFiltered(container, category)
	if not container.filterButton:GetChecked() and self.config.filters.categories[container.id][category.name] then
		self:FlushCategory(category)
	end
end

-- How many partial arrangements packColumns tries before it settles for the
-- best it has found. Bags have few enough categories that it rarely gets close.
local PACK_BUDGET = 10000
local EPSILON = 0.01

--[[
	Splits weights (sorted heaviest first) over k columns so the heaviest column
	is as light as possible, and returns each weight's column. Biggest first into
	the lightest column gives the starting answer, usually within a row of the
	best. A depth-first search then looks for a lighter one: each weight tries
	each column that would stay under the best so far, columns holding the same
	load are tried once, and it stops at the lower bound (the heaviest weight, or
	an even split) or after PACK_BUDGET steps.
]]
local function packColumns(weights, k)
	local n = #weights
	local loads, assign, bestAssign = {}, {}, {}
	for j = 1, k do loads[j] = 0 end

	for i = 1, n do
		local lightest = 1
		for j = 2, k do
			if loads[j] < loads[lightest] then lightest = j end
		end
		loads[lightest] = loads[lightest] + weights[i]
		bestAssign[i] = lightest
	end

	local best, total = 0, 0
	for j = 1, k do
		best = max(best, loads[j])
		total = total + loads[j]
		loads[j] = 0
	end
	local lowerBound = max(weights[1] or 0, total / k)

	local steps = 0
	local function search(i, heaviest)
		if best <= lowerBound + EPSILON or steps >= PACK_BUDGET then return end
		if i > n then
			best = heaviest
			for x = 1, n do bestAssign[x] = assign[x] end
			return
		end
		steps = steps + 1
		local tried = {}
		for j = 1, k do
			local load = loads[j]
			local newLoad = load + weights[i]
			if not tried[load] and newLoad < best - EPSILON then
				tried[load] = true
				loads[j] = newLoad
				assign[i] = j
				search(i + 1, max(heaviest, newLoad))
				loads[j] = load
			end
		end
	end
	search(1, 0)

	return bestAssign
end

-- Biggest first, then by name, so equal categories always land the same way.
local function heaviestFirst(a, b)
	local ha, hb = a:GetHeight(), b:GetHeight()
	if ha ~= hb then return ha > hb end
	return a.name < b.name
end

-- Packs the categories afresh into the shortest window the columns allow
-- (packColumns). A column's order doesn't change its height, so each one runs
-- smallest first when inverted, biggest first otherwise, and by name on a tie.
function INV:CompactCategories(container)
	local spacing = self.config.buttonspacing
	local columns = container.columns

	local shown = {}
	for _, category in pairs(container.categories) do
		self:FlushIfFiltered(container, category)
		if category:IsShown() then tinsert(shown, category) end
	end
	table.sort(shown, heaviestFirst)

	local weights = {}
	for i, category in ipairs(shown) do
		weights[i] = category:GetHeight() + spacing
	end
	local assign = packColumns(weights, #columns)

	local inverted = self.config.inverted
	for j, column in ipairs(columns) do
		local list = {}
		for i, category in ipairs(shown) do
			if assign[i] == j then tinsert(list, category) end
		end
		table.sort(list, function(a, b)
			local ha, hb = a:GetHeight(), b:GetHeight()
			if ha ~= hb then
				if inverted then return ha < hb end
				return ha > hb
			end
			return a.name < b.name
		end)
		for _, category in ipairs(list) do
			addToColumn(column, category, spacing)
		end
	end
end

--[[
	While a window is open its categories keep the columns and order they were
	packed into when it opened, and the window doesn't shrink, so selling or
	moving items never sends a category to another column or slides the window's
	contents. Inside a category the items still close up, and a category below
	one that shrinks still moves up. The held layout is dropped when the window
	closes, or for a deliberate re-arrangement: a settings change (UpdateConfig)
	or toggling the Edit view. Until a window's items have loaded (a cold item
	cache after a reload) it is packed afresh on every layout, so the held
	layout is a whole one.
]]

-- Records the columns' categories, by name, as the held layout.
function INV:HoldLayout(container)
	local layout = {}
	for i, column in ipairs(container.columns) do
		layout[i] = {}
		for _, category in ipairs(column.categories) do
			tinsert(layout[i], category.name)
		end
	end
	container.heldLayout = layout
end

function INV:ReleaseLayout(container)
	container.heldLayout = nil
	container.heldSize = nil
end

-- Lays the categories out in the held layout. One that has emptied is skipped,
-- and comes back in its place if it fills again. One that wasn't there when the
-- window opened goes at the bottom of the shortest column, and is held there.
function INV:PlaceHeldCategories(container)
	local spacing = self.config.buttonspacing
	local layout = container.heldLayout
	local placed = {}

	for i, column in ipairs(container.columns) do
		layout[i] = layout[i] or {}
		for _, name in ipairs(layout[i]) do
			placed[name] = true
			local category = container.categories[name]
			if category then
				self:FlushIfFiltered(container, category)
				if category:IsShown() then addToColumn(column, category, spacing) end
			end
		end
	end

	local new = {}
	for name, category in pairs(container.categories) do
		if not placed[name] then
			self:FlushIfFiltered(container, category)
			if category:IsShown() then tinsert(new, category) end
		end
	end
	table.sort(new, function(a, b) return a.name < b.name end)
	for _, category in ipairs(new) do
		local column, index = getShortestColumn(container.columns)
		addToColumn(column, category, spacing)
		tinsert(layout[index], category.name)
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
	for _, category in pairs(container.categories) do
		if category:IsShown() then
			totalRows = totalRows + category.numRows + 1
		end
	end

    local columns = container.columns
    local containerConfig = self.config[container.id]

    local maxHeight = self:GetButtonHeight() * containerConfig.maxRows
                    + self.config.buttonspacing * (containerConfig.maxRows - 1)

    local maxWidth = self:GetButtonHeight() * containerConfig.maxColumns
                    + self.config.buttonspacing * (containerConfig.maxColumns - 1)

	for _, column in pairs(container.columns) do
		column:SetHeight(0)
		column.categories = {}
	end

	if container.heldLayout then
		self:PlaceHeldCategories(container)
	else
		self:CompactCategories(container)
		if not container.loadingItems then self:HoldLayout(container) end
	end

	-- The spacing after each column's last category
	for _, column in pairs(container.columns) do
		if #column.categories > 0 then
			column:SetHeight(column:GetHeight() - self.config.buttonspacing)
		end
	end

    local numUsedColumns = getNumUsedColumns(container.columns)
    local tallestColumn = getTallestColumn(container.columns)
    local visibleHeight = min(tallestColumn:GetHeight() + self.config.padding, containerConfig.maxRows * (self:GetButtonHeight() + self.config.buttonspacing) - self.config.buttonspacing)

	-- A held layout's window keeps the size it had, and grows if it must.
	if container.heldLayout then
		local held = container.heldSize
		if held then
			numUsedColumns = max(numUsedColumns, held.columns)
			visibleHeight = max(visibleHeight, held.height)
		end
		container.heldSize = { columns = numUsedColumns, height = visibleHeight }
	end

    local scrollFrameWidth = numUsedColumns * (container.columns[1]:GetWidth() + self.config.buttonspacing) - self.config.buttonspacing

    container.scrollFrame:SetSize(scrollFrameWidth, visibleHeight)
    container.scrollFrame:SetContentSize(scrollFrameWidth, tallestColumn:GetHeight())

	container:SetHeight(max(200, height + container.scrollFrame:GetHeight()))
	container:SetWidth(container.scrollFrame:GetWidth() + self.config.padding * 2)
	self:SyncAnchorSize(id)
end
