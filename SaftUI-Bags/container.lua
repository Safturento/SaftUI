local st = SaftUI
local INV = st:GetModule('Inventory')


-- The title bar's view buttons: the gap left visible between two neighbouring
-- borders (see INV:ViewButtonGaps), and how far in from the header's right
-- edge the close button sits (st:CreateHeader), or the view buttons while the
-- close button is in the metal's socket (st:CloseButtonInSocket).
local VISIBLE_GAP, CLOSE_INSET = 3, 10

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

	self:CreateViewButtons(container)

	local filterButton = st:CreateCheckButton(nil, container.header)
    container.header.filterButton = filterButton
    -- Hidden, but anchored clear of the view buttons.
    self:SpaceViewButtons(container)
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

-- The loading bar and the footer's count of used slots.
local function ShowSlotCounts(self, container, numItems, numLoading)
	container:SetLoading(numItems - numLoading, numItems)

	if container.UpdateContainerSlots then
		container:UpdateContainerSlots()
	else
		local empty, total = self:GetNumContainerSlots(container.bag_ids)
			container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
	end
end

function INV:UpdateContainer(id, updateLayout)
	local container = self.containers[id]
	if not container and container:IsShown() then return end
	self:EnsureSlotPools(id)

	-- One bag, Multi bag and Rows lay their sections out on every update.
	local view = self:GetLaidOutView(container)
	if view ~= 'compact' then
		local sections, numItems, numLoading = self:GetViewSections(id, view)
		self:LayoutSections(container, sections)
		ShowSlotCounts(self, container, numItems, numLoading)
		return
	end

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

	ShowSlotCounts(self, container, numItems, numLoading)
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

-- How much of a window's content, contentHeight tall, its scroll frame shows:
-- all of it and the padding under it, up to maxRows rows, past which it scrolls.
local function VisibleHeight(self, id, contentHeight)
	local config = self.config
	return min(contentHeight + config.padding,
		config[id].maxRows * (self:GetButtonHeight() + config.buttonspacing) - config.buttonspacing)
end

-- Sizes a window around its scroll frame, contentWidth wide and visibleHeight
-- tall over contentHeight of content: the header, the search box under it, the
-- footer and the padding, at least 200 tall. Every view sizes its window here,
-- so a window is the same size for the same content in every view.
local function SizeWindow(self, container, contentWidth, contentHeight, visibleHeight)
	local config = self.config
	local height = container.header:GetHeight() + container.footer:GetHeight() + config.padding * 2
	if container.search then
		container.search:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', config.padding, -config.padding)
		height = height + container.search:GetHeight()
	end

	container.scrollFrame:SetSize(contentWidth, visibleHeight)
	container.scrollFrame:SetContentSize(contentWidth, contentHeight)

	container:SetHeight(max(200, height + container.scrollFrame:GetHeight()))
	-- A window that scrolls has its scroll bar just outside the scroll frame
	-- (st:ScrollBarRoom), which the window leaves room for, with the padding
	-- after it as on the left. One that doesn't has no bar (it hides itself).
	local barRoom = contentHeight > visibleHeight and st:ScrollBarRoom(container.scrollFrame) or 0
	-- Wide enough for the title between the view buttons and the left edge.
	container:SetWidth(max(container.scrollFrame:GetWidth() + barRoom + config.padding * 2, self:HeaderMinWidth(container)))
	self:SyncAnchorSize(container.id)
end

function INV:UpdateContainerLayout(id)
	local container = self.containers[id]
	local view = self:GetLaidOutView(container)
	if view ~= 'compact' then
		self:LayoutSections(container, (self:GetViewSections(id, view)))
		return
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
    local visibleHeight = VisibleHeight(self, id, tallestColumn:GetHeight())

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

	SizeWindow(self, container, scrollFrameWidth, tallestColumn:GetHeight(), visibleHeight)
end

--[[
	One bag, Multi bag and Rows lay a window out in sections (INV:GetViewSections),
	each a category frame as wide as Compact's columns together (INV:LineSlots;
	UpdateCategory and UpdateCurrencyCategory size it), stacked top to bottom in
	the scroll child, spacing apart. Each frame is anchored to the scroll child
	at its own offset, never to the frame above it (as Compact's columns are,
	see INV:UpdateConfig). Rows uses the window's category frames, and the
	Currencies section the bag window's Currencies; One bag's and Multi bag's
	sections have frames of their own ('view:<key>', made by
	INV:CreateCategory). The window's other category frames, and Compact's
	columns, are hidden. The window is the line's width, sized as Compact sizes
	it (VisibleHeight, SizeWindow); while it is open it doesn't shrink
	(container.heldSize), and the items close up within their sections. Closing
	the window or switching views releases it (INV:ReleaseLayout).
]]
function INV:LayoutSections(container, sections)
	local id = container.id
	local spacing = self.config.buttonspacing
	local lineSlots = self:LineSlots(id, self:GetLaidOutView(container))
	local lineWidth = (self:GetButtonWidth() + spacing) * lineSlots - spacing
	local child = container.scrollFrame.ScrollChild

	local inSections, y = {}, 0
	for _, section in ipairs(sections) do
		local name = self:SectionFrameName(section)
		if section.kind == 'currencies' then
			-- Shown or hidden by its own setting (filters.categories.bag.Currencies).
			self:UpdateCurrencyCategory(container.filterButton:GetChecked(), lineSlots)
		else
			self:UpdateCategory(id, name, section.items, section.title, lineSlots)
		end
		local frame = container.categories[name]
		if frame then
			inSections[frame] = true
			if frame:IsShown() then
				frame:ClearAllPoints()
				frame:SetPoint('TOPLEFT', child, 'TOPLEFT', 0, -y)
				y = y + frame:GetHeight() + spacing
			end
		end
	end
	for _, frame in pairs(container.categories) do
		if not inSections[frame] then self:FlushCategory(frame) end
	end
	for _, column in pairs(container.columns) do column:Hide() end

	local contentHeight = max(0, y - spacing)
	local visibleHeight = VisibleHeight(self, id, contentHeight)
	if container:IsShown() then
		local held = container.heldSize
		if held and held.height then visibleHeight = max(visibleHeight, held.height) end
		container.heldSize = { height = visibleHeight }
	else
		container.heldSize = nil
	end

	SizeWindow(self, container, lineWidth, contentHeight, visibleHeight)
end

-- Every window whose view was switched in combat (see INV:ApplyView).
local function ApplyPendingViews()
	for id, container in pairs(INV.containers) do
		if INV:GetLaidOutView(container) ~= INV:GetView(id) then INV:ApplyView(id) end
	end
end

--[[
	Lays a window out in the view its settings name (config[id].view), after a
	switch: every slot it has made is anchored again for that view's line
	(INV:LineSlots), Compact's columns come back for Compact, and the window is
	laid out afresh, its held layout and size released. Slots are Blizzard's item
	buttons and the category frames hold them, so in combat nothing is touched:
	the switch waits for the end of combat (one pending run, for every window
	switched in the fight), and until then the window's updates keep the view it
	is laid out in. The bag window's search is applied again afterwards: the
	new view's slots kept the alpha of the search they last saw.
]]
function INV:ApplyView(id)
	if st:QueueAfterCombat('InventoryView', ApplyPendingViews) then return end
	local container = self.containers[id]
	if not container then return end

	local view = self:GetView(id)
	container.view = view
	self:ReleaseLayout(container)
	local lineSlots = self:LineSlots(id, view)
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			self:SetSlotPosition(slot, category, container, lineSlots)
		end
	end
	if view == 'compact' then
		for _, column in ipairs(container.columns) do column:Show() end
	end
	self:UpdateContainer(id, true)
	local search = self.containers.bag and self.containers.bag.search
	if search then self:UpdateSearchFilter(search) end
end

------------------------------------------------------------------ the view buttons

--[[
	Each window's title bar has a small square button per view (INV.viewIds),
	left of the close button in the order One bag, Multi bag, Compact, Rows
	(container.viewButtons, by view). Their icons are plain colored textures,
	the same on both clients: a square, four squares, a dot grid and lines,
	drawn on a 12 by 12 grid (GLYPHS: x, y, width, height of each piece) whose
	unit is a whole number of pixels, so the pieces stay sharp at any title bar
	height. The button for the window's view is lit with Buttons -> Blue, kept
	with st:KeepOwnColors so a theme recolor and redraw don't take it away.
	The buttons are SaftUI's own plain buttons, so lighting one is fine in
	combat; the layout is what waits (INV:SetView, INV:ApplyView).
]]
local GLYPHS = {
	onebag = { { 0, 0, 12, 12 } },
	multibag = { { 0, 0, 5, 5 }, { 7, 0, 5, 5 }, { 0, 7, 5, 5 }, { 7, 7, 5, 5 } },
	compact = {
		{ 0, 0, 2, 2 }, { 5, 0, 2, 2 }, { 10, 0, 2, 2 },
		{ 0, 5, 2, 2 }, { 5, 5, 2, 2 }, { 10, 5, 2, 2 },
		{ 0, 10, 2, 2 }, { 5, 10, 2, 2 }, { 10, 10, 2, 2 },
	},
	rows = { { 0, 1, 12, 2 }, { 0, 5, 12, 2 }, { 0, 9, 12, 2 } },
}

-- The lit button's border: Buttons -> Blue.
local function ColorLit(button)
	st:SetBorderColor(button.backdrop, st.config.profile.colors.button.blue:GetRGB())
end

-- A button's glyph is drawn in Colors -> Text -> Normal.
local function ColorGlyph(button)
	for _, piece in ipairs(button.glyph) do
		piece:SetColorTexture(st.config.profile.colors.text.normal:GetRGB())
	end
end

-- A button is the title bar's height less 8 square, and its glyph is drawn at
-- the largest whole pixel unit that fits inside with room to spare.
local function SizeViewButton(button)
	local size = button:GetParent():GetHeight() - 8
	button:SetSize(size, size)
	local unit = max(1, floor((size - 8) / 12))
	for i, piece in ipairs(button.glyph) do
		local x, y, w, h = unpack(GLYPHS[button.view][i])
		piece:ClearAllPoints()
		piece:SetPoint('TOPLEFT', button, 'CENTER', (x - 6) * unit, (6 - y) * unit)
		piece:SetSize(w * unit, h * unit)
	end
end

function INV:SizeViewButtons(container)
	for _, button in pairs(container.viewButtons or {}) do SizeViewButton(button) end
end

-- The distance between the view buttons' frames, and between the first of them
-- and the close button: each button draws its border the theme's inset outside
-- itself (2 Thick, 1 Thin) and the close button a 1px outline outside itself,
-- so the frames are that far apart plus VISIBLE_GAP of clear room between the
-- borders, in every theme.
function INV:ViewButtonGaps()
	local inset = st:ThemeInset('theme', 'theme', 'small')
	return 2 * inset + VISIBLE_GAP, inset + 1 + VISIBLE_GAP
end

-- Puts the view buttons (and the Edit check button before them) the
-- INV:ViewButtonGaps apart, lined up from the close button, or from the
-- header's right edge, CLOSE_INSET in, while the close button sits in the
-- metal's socket above the header (st:CloseButtonInSocket). A theme switch
-- changes the inset and the socket, so INV:UpdateConfig(id) runs it again.
function INV:SpaceViewButtons(container)
	local close = st:GetCloseButton(container)
	if not (container.viewButtons and close) then return end
	local buttonGap, closeGap = self:ViewButtonGaps()
	local right, side, gap = close, 'LEFT', closeGap
	if st:CloseButtonInSocket(container) then
		right, side, gap = container.header, 'RIGHT', CLOSE_INSET
	end
	for i = #self.viewIds, 1, -1 do
		local button = container.viewButtons[self.viewIds[i]]
		button:ClearAllPoints()
		button:SetPoint('RIGHT', right, side, -gap, 0)
		right, side, gap = button, 'LEFT', buttonGap
	end
	local filterButton = container.header and container.header.filterButton
	if filterButton then
		filterButton:ClearAllPoints()
		filterButton:SetPoint('RIGHT', container.viewButtons[self.viewIds[1]], 'LEFT', -closeGap, 0)
	end
end

function INV:CreateViewButtons(container)
	local header = container.header
	container.viewButtons = {}
	for i = #self.viewIds, 1, -1 do
		local view = self.viewIds[i]
		local button = st:CreateButton(nil, header, nil, 'theme', 'theme')
		button:SetFrameLevel(header:GetFrameLevel() + 4)
		button.view, button.viewLit, button.glyph = view, false, {}
		for p = 1, #GLYPHS[view] do
			button.glyph[p] = button:CreateTexture(nil, 'OVERLAY')
		end
		ColorGlyph(button)
		SizeViewButton(button)

		button:SetScript('OnClick', function() INV:SetView(container.id, view) end)
		button:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOP')
			GameTooltip:SetText(INV.viewLabels[view])
			GameTooltip:Show()
		end)
		button:SetScript('OnLeave', st.HideGameTooltip)

		container.viewButtons[view] = button
	end
	self:SpaceViewButtons(container)
	self:UpdateViewButtons(container.id)
end

-- Lights the window's view's button and puts the others back to the theme's
-- border, when that changed (a button that kept its look isn't drawn again).
function INV:UpdateViewButtons(id)
	local container = self.containers[id]
	if not (container and container.viewButtons) then return end
	local current = self:GetView(id)
	for view, button in pairs(container.viewButtons) do
		local on = view == current
		if on ~= button.viewLit then
			button.viewLit = on
			if on then
				ColorLit(button)
				st:KeepOwnColors(button, ColorLit)
			else
				st:KeepOwnColors(button, nil)
				st:SetBackdrop(button, 'theme', 'theme', 'small')
			end
		end
	end
end

-- A color the view buttons are drawn in changed (st:ColorsChanged's group):
-- Buttons -> Blue lights the lit buttons, Text -> Normal draws every glyph.
function INV:ColorViewButtons(group)
	for _, container in pairs(self.containers) do
		for _, button in pairs(container.viewButtons or {}) do
			if group == 'button' and button.viewLit then ColorLit(button) end
			if group == 'text' then ColorGlyph(button) end
		end
	end
end

-- Switches a window's view: saves it, lights its button, shows it in an open
-- /sui's View select (st.Config:Refresh) and lays the window out
-- (INV:ApplyView, which waits for the end of combat). The window's own view
-- does nothing: the layout is only touched for a reason.
function INV:SetView(id, view)
	if not self.viewLabels[view] or self:GetView(id) == view then return end
	self.config[id].view = view
	self:UpdateViewButtons(id)
	st.Config:Refresh()
	self:ApplyView(id)
end

-- The title bar's height follows Global Settings (st:UpdateHeader), and so
-- do the buttons in it.
hooksecurefunc(st, 'UpdateHeader', function()
	for _, container in pairs(INV.containers or {}) do INV:SizeViewButtons(container) end
end)

-- The narrowest a window can be with its title between the view buttons and
-- the window's left edge: the title is centered, so the room the buttons and
-- the close button take on the right is also kept clear on the left. While
-- the close button sits in the metal's socket above the header, it and its
-- gap take none (INV:SpaceViewButtons).
function INV:HeaderMinWidth(container)
	local close = st:GetCloseButton(container)
	if not (container.viewButtons and close and container.title) then return 0 end
	local count = #self.viewIds
	local size = container.header:GetHeight() - 8
	local buttonGap, closeGap = self:ViewButtonGaps()
	local extent = CLOSE_INSET + count * size + (count - 1) * buttonGap
	if not st:CloseButtonInSocket(container) then
		extent = extent + close:GetWidth() + closeGap
	end
	return 2 * (extent + closeGap) + container.title:GetStringWidth()
end
