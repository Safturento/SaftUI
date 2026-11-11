local st = SaftUI
local INV = st:NewModule('Inventory')

-- Every bank tab the client defines, in order. The tab count differs per client
-- (Forever defines nine character tabs, the base bank plus one per bank bag
-- slot, where retail defines six), so read it from the enum instead of listing it.
local function GetBankTabBagIds(prefix)
	local bagIds = {}
	local index = 1
	while Enum.BagIndex[prefix .. index] do
		tinsert(bagIds, Enum.BagIndex[prefix .. index])
		index = index + 1
	end
	return bagIds
end

local BAG_IDS
if st.retail then
	local characterTabs = GetBankTabBagIds('CharacterBankTab_')
	local accountTabs = GetBankTabBagIds('AccountBankTab_')

	local combinedTabs = {}
	for _, bagId in ipairs(characterTabs) do tinsert(combinedTabs, bagId) end
	for _, bagId in ipairs(accountTabs) do tinsert(combinedTabs, bagId) end

	BAG_IDS = {
		['bag'] = {
            Enum.BagIndex.Backpack,
            Enum.BagIndex.Bag_1,
            Enum.BagIndex.Bag_2,
            Enum.BagIndex.Bag_3,
            Enum.BagIndex.Bag_4,
            Enum.BagIndex.ReagentBag,
         },
		['bank'] = characterTabs,
		['warband'] = accountTabs,
		['combinedbank'] = combinedTabs,
	}
else
	BAG_IDS = {
		['bag'] = { 0, 1, 2, 3, 4 },
		['bank'] = { -1, 5, 6, 7, 8, 9, 10, 11 }
	}
end

INV.bagIds = BAG_IDS

-- Whether this client has a warband bank worth showing: retail only (Forever
-- defines the account tabs and Enum.BankType.Account but has no warband bank
-- UI here) and with warband tabs to hold items.
function INV:HasWarbandBank()
	return st.retail and not st.forever and self.bagIds.warband ~= nil and #self.bagIds.warband > 0
end

INV.containers = {}
INV.OnUseItems = {}

-- Item buttons are not square: 60 wide by 50 tall by default, with the icon
-- cropped to fit (st:SkinIcon). One setting, iconsize, is the height, and the
-- width keeps the 6:5 shape so the crop stays right at any size. The bag slot
-- bars use the same size. Both are rounded to whole screen pixels.
local BUTTON_ASPECT = 6 / 5

function INV:GetButtonHeight()
	local size = tonumber(self.config.iconsize) or 50
	return st:RoundToPixel(max(size, 1))
end

function INV:GetButtonWidth()
	local size = tonumber(self.config.iconsize) or 50
	return st:RoundToPixel(max(size, 1) * BUTTON_ASPECT)
end

function INV:SelectBankCategory(clickedHeader)
	local selectedContainer = clickedHeader:GetParent()
    if selectedContainer.id == 'warband' then
		BankFrame.BankPanel:SetBankType(Enum.BankType.Character)
	elseif selectedContainer.id == 'bank' then
        BankFrame.BankPanel:SetBankType(Enum.BankType.Account)
	end

    for containerName, container in pairs(self.containers) do
        if containerName == selectedContainer.id then
            if container.backdrop then
                container.backdrop:SetBackdropBorderColor(st.config.profile.colors.button.blue:GetRGB())
            end
        else
            st:SetBackdrop(container, self.config.theme, self.config.background, 'panel')
        end
    end
end

-- The filter tables bag updates index, and the category store and pins
-- (categories.lua), which a new or reset profile doesn't have yet. Plain
-- table writes, so it's safe in combat.
function INV:EnsureConfigTables()
	local filters = self.config.filters or {}
	self.config.filters = filters
	filters.categories = filters.categories or {}
	filters.currencies = filters.currencies or {}
	for id in pairs(self.containers) do
		filters.categories[id] = filters.categories[id] or {}
	end
	self:CategoryStore()
	if type(self.config.categoryPins) ~= 'table' then self.config.categoryPins = {} end
end

-- Applies a changed icon size or spacing: re-lays out every window, restyles
-- the item and currency slots, resizes both bag slot bars (UpdateConfig does
-- all of that), then resizes the edit mode outlines, including windows that
-- aren't made yet.
function INV:ApplyButtonSize()
	self:UpdateConfig()
	for _, id in ipairs(self.windowIds) do
		if self.anchors[id] then
			self:SyncAnchorSize(id)
		end
	end
end

--[[
	With an id: applies the profile to that container (position, columns,
	widths, search box, backdrop). Also runs when a container is made.

	With no id, a profile change: makes sure the profile has the filter tables,
	then re-applies every container, the slots and category headers they've
	made, and the bag slot bars, and lays the bags out again. Bag slots are
	Blizzard item buttons, so in combat that restyle waits until combat ends.
]]
function INV:UpdateConfig(id)
	if not id then
		if not self.containers.bag then return end -- not enabled
		self:EnsureConfigTables()
		-- A profile saved before the category list is migrated, before anything
		-- reads its categories. Table writes only, so safe in combat.
		self:MigrateCategories()
		-- Saved positions of an older shape, and a bank layout the new profile
		-- uses, before anything is placed. Windows not made yet only have their
		-- anchor to resize; the made ones resize in UpdateConfig(id).
		self:MigratePositions()
		self:RegisterMovers()
		for _, anchorId in ipairs(self.windowIds) do
			if self.anchors[anchorId] and not self.containers[anchorId] then
				self:SyncAnchorSize(anchorId)
			end
		end
		if st:QueueAfterCombat('Inventory', function() INV:UpdateConfig() end) then return end

		for containerId, container in pairs(self.containers) do
			self:UpdateConfig(containerId)
			self:StyleContainerContents(container)
			-- A closed window is laid out when it next updates (UpdateContainer).
			container.layoutPending = true
		end
		self:StyleCurrencySlots()
		self:UpdateBagSlotBars()
		-- The profile's categories, edits and pins, read again: the frames of
		-- its own categories, and an update that lays the bags out.
		self:CategoriesChanged()
		return
	end

	local container = self.containers[id]
	-- New settings re-pack the window (container.lua, HoldLayout), in the view
	-- they name. Out of combat (the profile update waits for its end), so the
	-- slots restyled after this are anchored for that view's line.
	self:ReleaseLayout(container)
	container.view = self:GetView(id)
	self:UpdateViewButtons(id) -- a profile switch changes the view
	self:SpaceViewButtons(container) -- and a theme switch the border's width

	-- The window is anchored to its mover's anchor frame (see movers.lua).
	self:ApplyPosition(id)

	if container.search then
		container.scrollFrame:SetPoint('TOPLEFT', container.search, 'BOTTOMLEFT', 0, -self.config.padding)
	else
		container.scrollFrame:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
	end

	-- Column frames are kept for reuse. container.columns holds the profile's
	-- maxColumns of them (the layout uses every one in it); the rest hide.
	container.columnFrames = container.columnFrames or {}
	wipe(container.columns)
    for i=1, self.config[id].maxColumns do
        local column = container.columnFrames[i]
        if not column then
            column = st:CreateFrame('Frame', container:GetName() .. 'Column'..i, container.scrollFrame)
            container.columnFrames[i] = column
        end
        column:Show()

        local columnWidth = (self:GetButtonWidth() + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing
        column:SetWidth(columnWidth)
        -- Each column at its own offset on the scroll child, never chained to
        -- the one before it: while a layout is held, a column whose categories
        -- sold out has no height, and in game a column anchored to it lost its
        -- place, taking every category after it out of sight.
        column:ClearAllPoints()
        column:SetPoint('TOPLEFT', container.scrollFrame.ScrollChild, 'TOPLEFT', (i - 1) * (columnWidth + self.config.buttonspacing), 0)
        container.columns[i] = column
    end
    for i = self.config[id].maxColumns + 1, #container.columnFrames do
        container.columnFrames[i]:Hide()
    end

	local inner_width = (self:GetButtonWidth() + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing

	container:SetWidth(self.config.padding * 2 + inner_width)
	container:SetHeight(200)

	for _, category in pairs(container.categories) do
		category:SetWidth(inner_width)
	end
	if container.search then
		container.search:SetWidth(inner_width)
		st:StyleEditBox(container.search, self.config.theme, self.config.background, self.config.fonts.titles)
	end

	st:SetBackdrop(container, self.config.theme, self.config.background, 'panel')
	self:SyncAnchorSize(id)

	-- A window placed relative to this one (typed in its Position) can only
	-- resolve the name now that it exists.
	for _, otherId in ipairs(self.windowIds) do
		local position = otherId ~= id and self.anchors[otherId] and self.config[otherId].position
		if position and position.frame == container:GetName() then
			self:ApplyPosition(otherId)
		end
	end
end

-- Re-applies the profile to the category headers and item slots a container
-- has made.
function INV:StyleContainerContents(container)
	local titleFont = st:GetFont(self.config.fonts.titles)
	for _, category in pairs(container.categories) do
		category.header:SetHeight(self.config.categoryTitleHeight)
		category.header.text:SetFontObject(titleFont)
		for _, slot in pairs(category.slots) do
			self:StyleSlot(slot, category, container)
		end
	end
end

-- Re-sizes the bag slot bars to the profile's button size, spacing and
-- padding: the bags' bar (Blizzard's bag slots) and the bank's own.
function INV:UpdateBagSlotBars()
	local width, height = self:GetButtonWidth(), self:GetButtonHeight()
	local spacing, padding = self.config.buttonspacing, self.config.padding

	local bag = self.containers.bag
	local bar = bag and bag.bagSlotContainer
	if bar then
		local numSlots = #bar.slots
		bar:SetSize(width * numSlots + spacing * (numSlots - 1) + padding * 2, height + padding * 2)
		bar:ClearAllPoints()
		bar:SetPoint('BOTTOMLEFT', bag, 'TOPLEFT', 0, spacing)
		for _, slot in pairs(bar.slots) do
			slot:SetSize(width, height)
		end
		self:MovePlayerBagSlots()
	end

	for _, id in ipairs({ 'bank', 'combinedbank' }) do
		local container = self.containers[id]
		local bankBar = container and container.bagSlotContainer
		if bankBar then
			bankBar:ClearAllPoints()
			bankBar:SetPoint('BOTTOMLEFT', container, 'TOPLEFT', 0, spacing)
			for _, slot in pairs(bankBar.slots) do
				slot:SetSize(width, height)
			end
			bankBar.purchaseButton:SetSize(width, height)
			if bankBar:IsShown() then
				self:UpdateBankBagSlots(bankBar)
			end
		end
	end
end

function INV:UpdateVisibleContainers(updateLayout)
	for containerName, container in pairs(self.containers) do
		if container:IsShown() then
			self:UpdateContainer(containerName, updateLayout)
		end
	end
	self:UpdateSearchFilter(self.containers.bag.search, false)
end

function INV:UpdateHandler(_, elapsed)
	if self.IS_UPDATING or not self.NEED_UPDATE then return end

	self.IS_UPDATING = true
	self.NEED_UPDATE = false
	local updateLayout = self.UPDATE_LAYOUT
	self.UPDATE_LAYOUT = false
	-- An error here must not leave IS_UPDATING set, or the bags would never update
	-- again this session. Report it and carry on.
	xpcall(function()
		self:UpdateGold()
		-- Even with the bags closed, so the slot buttons the views need are made
		-- out of combat. In combat this queues the top-up for afterwards.
		self:EnsureSlotPools()
		self:UpdateVisibleContainers(updateLayout)
	end, geterrorhandler())
	self.IS_UPDATING = false
	-- An open Categories tab in /sui shows counts and Caught now from the bags:
	-- it is drawn again on the next frame, or once a drag in it ends
	-- (categoriestab.lua).
	if self.categoriesTabShown then st.Config:Refresh() end
end

function INV:QueueUpdate(updateLayout)
	self.NEED_UPDATE = true
	if updateLayout then
		self.UPDATE_LAYOUT = true
	end
end

-- The bank layout (combined, or the separate bank) is read from the profile
-- each time the bank opens, so a profile change applies from the next visit.
-- Closing goes to whichever layout was opened.
function INV:BANKFRAME_OPENED()
	if st.retail and self.config.combinedBank then
		self.openedBankLayout = 'combined'
		self:OpenCombinedBank()
	else
		self.openedBankLayout = 'separate'
		self:OpenBank()
	end
end

function INV:BANKFRAME_CLOSED()
	local opened = self.openedBankLayout
	self.openedBankLayout = nil
	if opened == 'combined' then
		self:CloseCombinedBank()
	elseif opened == 'separate' then
		self:CloseBank()
	end
end

function INV:OnEnable()
	st:BindModuleConfig(self, 'inventory')
	if self.config.enable == false then return end

	self:EnsureConfigTables()
	self:MigrateCategories()
	self:CategoriesChanged()
	self:MigratePositions()

	self:InitializeTooltipScanner()
	self:InitializePlayerBags()
	self:RegisterMovers()

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

	-- Make sure the slots are all created immediately intead of on first open
	-- We do this to avoid tainting all of the slots when the bag is first opened
	-- while in combat
	self:UpdateContainer('bag')

	self:RegisterEvent('PLAYER_MONEY', 'UpdateGold')
	self:RegisterEvent('MERCHANT_SHOW', 'HandleMerchant')

	self:RegisterEvent('BAG_UPDATE', 'QueueUpdate')
	self:RegisterEvent('BAG_UPDATE_DELAYED', 'QueueUpdate')
	self:RegisterEvent('BAG_CONTAINER_UPDATE', 'QueueUpdate')
	self:RegisterEvent('BAG_NEW_ITEMS_UPDATED', 'QueueUpdate')
	self:RegisterEvent('ITEM_LOCK_CHANGED', 'QueueUpdate')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'QueueUpdate')
	self:RegisterEvent('GET_ITEM_INFO_RECEIVED', 'QueueUpdate')

	self:RegisterEvent('BANKFRAME_OPENED')
	self:RegisterEvent('BANKFRAME_CLOSED')

	self.updater = CreateFrame('frame')
	self:HookScript(self.updater, 'OnUpdate', 'UpdateHandler')
end