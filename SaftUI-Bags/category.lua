local st = SaftUI
local INV = st:GetModule('Inventory')

INV.CATEGORY_SLOT_POOL = 10
INV.EMPTY_SLOTS_CATEGORY = 'Empty Slots'

-- Whether a bag ID is the reagent bag. Guarded because the enum entry only
-- exists on clients that have a reagent bag.
function INV:IsReagentBag(bagID)
	return Enum.BagIndex ~= nil and Enum.BagIndex.ReagentBag ~= nil and bagID == Enum.BagIndex.ReagentBag
end

-- peek: a read only to show the bags, which counts no tooltip try (ScanBagItem).
function INV:GetInventoryItemInfo(bagID, slotID, containerId, peek)
	local item = C_Container.GetContainerItemInfo(bagID, slotID)
	if item then
		local tooltipText, tooltipRaw, tooltipReady, tooltipMissing = self:ScanBagItem(bagID, slotID, peek)
		if not tooltipReady then return { loading = true, tooltip = true } end
		local name, _, quality, _, reqLevel, class, subclass, _, equipSlot, texture, vendorPrice,
			itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = C_Item.GetItemInfo(item.hyperlink)
		local equipLoc = equipSlot
		local itemLevel = C_Item.GetDetailedItemLevelInfo(item.hyperlink)
		if not name then
			local itemString = select(3, strfind(item.hyperlink, "|H(.+)|h"))
			local itemType, itemId = string.split(':', itemString)

			if itemType == "keystone" then
				--StaticPopup_Show("EXTRACT_LINK_DIALOG", nil, nil, item.hyperlink)
				--\124cnIQ4:\124Hkeystone:180653:504:11:162:10:9:0:0\124h[Keystone: Darkflame Cleft (11)]\124h\124r

				local keyLevel = select(4, string.split(':', itemString))

				name = item.itemName
				class = 'Key'
				itemClassID = (Enum.ItemClass and Enum.ItemClass.Key) or 13
				vendorPrice = 0
				texture = item.iconFileID
				item.stackCount = tonumber(keyLevel)
				quality = 4

			elseif itemType == 'battlepet' then
				--petlink = string.format("%s|Hbattlepet:%s:%s:%s:%s:%s:%s|h[%s]|h|r", ITEM_QUALITY_COLORS[quality].hex, speciesID, level, quality, health, power, speed, name)
				--speciesID, level, quality, health, power, speed, name =  string.split(':', itemString)
				local petLevel =  select(3, string.split(':', itemString))

				name = item.itemName
				class='Battle Pet'
				itemClassID = (Enum.ItemClass and Enum.ItemClass.Battlepet) or 17
				item.stackCount = tonumber(petLevel)
				vendorPrice = 0
				quality = item.quality
				texture = item.iconFileID
			end
		end

		if name then
			local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)

			return {
				name = name,
				nameLower = strlower(name),
				nameStripped = strlower(string.unmagic(name)),
				ilvl = itemLevel,
				reqLevel = reqLevel,
				isWarbound = (C_Item.IsBoundToAccountUntilEquip and C_Item.IsBoundToAccountUntilEquip(itemLocation) and not C_Item.IsBound(itemLocation))
						or string.matchnocase(tooltipText, "Warbound"),
				--bindType == Enum.ItemBind.ToBnetAccount
				--		  or bindType == Enum.ItemBind.ToWoWAccount
				--		  or bindType == Enum.ItemBind.ToBnetAccountUntilEquipped,
				isBoE = (not item.isBound) and (bindType == Enum.ItemBind.OnUse
						or bindType == Enum.ItemBind.OnEquip),
				isSoulbound = item.isBound,
				count = item.stackCount,
				--upgradeInfo = upgradeInfo,
				itemID = item.itemID,
				stackPrice = vendorPrice * item.stackCount,
				link = item.hyperlink,
				quality = quality or 0,
				class = class,
				subclass = subclass,
				maxStack = C_Item.GetItemMaxStackSize(itemLocation) or 1,
				equipSlot = _G[equipSlot],
				equipLoc = equipLoc,
				classID = itemClassID,
				subclassID = itemSubClassID,
				bindType = bindType,
				isCraftingReagent = isCraftingReagent,
				expacID = expacID,
				vendorPrice = vendorPrice,
				texture = texture or item.iconFileId,
				locked = item.locked,
				container = containerId,
				bagID = bagID,
				slotID = slotID,
				tooltipText = tooltipText,
				tooltipLower = strlower(tooltipRaw),
				tooltipStripped = strlower(tooltipText),
				-- Filed without its tooltip, which never arrived (ScanBagItem).
				tooltipMissing = tooltipMissing or nil,
				sortString = (itemLevel or 0) .. name .. (quality or 0) .. (class or '') .. (subclass or '') .. (reqLevel or 0) .. (item.stackCount or 0) .. (item.itemID or 0),
			}
		else
			return {
				loading = true
			}
		end
	end
end


local function sortCategory(a,b) return a.sortString > b.sortString end
INV.CompareItems = sortCategory

-- The info for a free bag slot. It carries the fields the readers of slot.info
-- use (vendor price, name, tooltip text) as harmless blanks, and `empty` so
-- code that cares can tell it from an item. `count` is only set on a grouped
-- slot, where it is how many free slots of that kind there are.
local function GetEmptySlotInfo(bagID, slotID, containerId)
	return {
		empty = true,
		name = '',
		tooltipText = '',
		sortString = '',
		vendorPrice = 0,
		stackPrice = 0,
		container = containerId,
		bagID = bagID,
		slotID = slotID,
	}
end

-- A window's Empty slots setting, 'grouped' or 'all'; nil for 'off' (and for a
-- window with no such setting).
function INV:GetEmptySlotMode(id)
	local config = self.config[id]
	local mode = config and config.emptySlots
	if mode == 'grouped' or mode == 'all' then return mode end
end

-- In combat: once combat ends, makes the slot buttons that are missing
-- (EnsureSlotPools) and updates the windows again (one pending run). Returns
-- true then; out of combat it does nothing and returns false.
function INV:QueueSlotTopUp()
	return st:QueueAfterCombat('InventorySlotPool', function()
		INV:EnsureSlotPools()
		INV:QueueUpdate(true)
	end)
end

-- In combat no slot button can be made (see CreateSlot), so a category frame
-- (by name) shows no more of infos than it has buttons left after its
-- numItems slots, none before the frame is made, and the rest once combat
-- ends (QueueSlotTopUp). Compact's Empty Slots goes through it, and every
-- view's sections: their free slots, and the items of Rows' categories and of
-- One bag's and Multi bag's sections. Trims infos in place and returns it.
function INV:FitSlots(id, name, numItems, infos)
	if not InCombatLockdown() then return infos end
	local frame = self.containers[id].categories[name]
	local room = max(0, (frame and #frame.slots or 0) - numItems)
	if #infos > room then
		for i = #infos, room + 1, -1 do infos[i] = nil end
		self:QueueSlotTopUp()
	end
	return infos
end

-- Gives a window's category frame of that name at least `slots` buttons,
-- making the frame first if it isn't (hidden until a layout shows it, with
-- its title, which places its first button: INV:SetSlotPosition). Out of
-- combat; in combat it queues the top-up instead and returns true.
local function FillPool(self, container, name, slots, title)
	local frame = container.categories[name]
	if frame and #frame.slots >= slots then return end
	if self:QueueSlotTopUp() then return true end
	if not frame then
		self:UpdateCategory(container.id, name, {}, title)
		frame = container.categories[name]
		frame:Hide()
	end
	for _ = #frame.slots + 1, slots do self:CreateSlot(container, name) end
end

--[[
	Makes the slot buttons a window's view needs (every window's, with no id),
	before a fight can need them. Buttons made in combat are flagged as broken
	(see CreateSlot), so this happens out of combat, on every bag update, even
	with the window closed, so a bigger bag being equipped is covered too. In
	combat it queues itself for the end of combat (QueueSlotTopUp).
	  - Compact and Rows: the Empty Slots category, whenever the window's
	    Empty slots setting shows free slots. The category itself, with
	    UpdateCategory's spare buttons (enough for 'grouped', one slot per
	    kind of bag), before any free slot needs it: the bag window's is made
	    at login (InitializeAllCategories), the bank windows' here. With 'all'
	    (Every slot), a button for every bag slot, since a fight can free any
	    number of them. The other categories have UpdateCategory's spare
	    buttons, as Compact always has.
	  - One bag and Multi bag: each section's frame, with a button for every
	    slot of its bags (INV:GetSectionPools), so a fight's loot never needs
	    one, however much of it lands in one section.
]]
function INV:EnsureSlotPools(id)
	if not id then
		for windowId in pairs(self.containers) do self:EnsureSlotPools(windowId) end
		return
	end
	local container = self.containers[id]
	if not container then return end
	local view = self:GetLaidOutView(container)

	if view == 'onebag' or view == 'multibag' then
		for name, pool in pairs(self:GetSectionPools(id, view)) do
			local title
			if pool.untitled then title = false end
			if FillPool(self, container, name, pool.slots, title) then return end
		end
		return
	end

	local mode = self:GetEmptySlotMode(id)
	if not mode then return end
	local total = 0
	if mode == 'all' then
		for _, bagID in pairs(container.bag_ids) do
			total = total + C_Container.GetContainerNumSlots(bagID)
		end
	end
	FillPool(self, container, self.EMPTY_SLOTS_CATEGORY, total)
end

-- Reads a window's bags once, for GetSortedInventory and the views. Returns:
--   bags: one record per bag ID, in the window's bag order: `id`, `items` (the
--     item infos in slot order, after stacks are merged) and `free` (the free
--     slot IDs, in order);
--   numItems, numLoading;
--   categoryOf: item info -> its category key (INV:GetItemCategory), also
--     on the info as `category`, with `categoryWhy`.
-- groupOf(bagID) names the group a bag merges stacks in (when stackItems is
-- on): the same item in two groups stays two slots. A stack merges into the
-- first slot of its item in the group, which stays where it was. noMerge
-- reads every stack as its own item, whatever stackItems says (auto vendor
-- sells slot by slot). peek is a read only to show the bags (the Categories
-- tab's): an item waiting for its tooltip counts no try and queues no retry,
-- which the bag updates' own reads do.
function INV:ReadBags(id, groupOf, noMerge, peek)
	local container = self.containers[id]
	if not container then
		st:Error('container with id ', id, 'not found')
	end

	local bags, categoryOf = {}, {}
	local merged = {}
	local merge = self.config.stackItems and not noMerge
	local numItems, numLoading = 0, 0
	for _, bagID in pairs(container.bag_ids) do
		local group = groupOf(bagID)
		local bag = { id = bagID, items = {}, free = {} }
		tinsert(bags, bag)
		for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
			local item = self:GetInventoryItemInfo(bagID, slotID, id, peek)
			if item then
				numItems = numItems + 1
				if item.loading then
					numLoading = numLoading + 1
					if item.tooltip and not peek then self:QueueTooltipRetry() end
				else
					local mergeKey = tostring(item.itemID) .. ':' .. group
					if merge and merged[mergeKey] and item.maxStack > 1 then
						merged[mergeKey].count = merged[mergeKey].count + item.count
					else
						categoryOf[item], item.categoryWhy = self:GetItemCategory(item)
						-- For the slot's junk coin (INV:IsAutoVendorItem), so it needn't
						-- categorize again; categoryWhy says why it is there.
						item.category = categoryOf[item]
						tinsert(bag.items, item)
						if merge and item.maxStack > 1 then
							merged[mergeKey] = item
						end
					end
				end
			else
				tinsert(bag.free, slotID)
			end
		end
	end
	return bags, numItems, numLoading, categoryOf
end

-- The empty slot infos for a list of bag records (see ReadBags), by mode:
-- 'all' is one per free slot, in order; 'grouped' is one pointing at the first
-- free slot, with `count` the number of free slots, or none if there are none.
-- The grouped slot prefers a free slot in a bag that takes any item over one in
-- a special bag (a herb bag's takes only herbs), so an item dropped on it lands.
function INV:GetEmptySlots(id, bags, mode)
	local empties = {}
	if mode ~= 'all' and mode ~= 'grouped' then return empties end
	local first, plain, count = nil, nil, 0
	for _, bag in ipairs(bags) do
		local special -- asked once a bag (a game call), and only for the first free slot of it
		for _, slotID in ipairs(bag.free) do
			count = count + 1
			if mode == 'all' then
				tinsert(empties, GetEmptySlotInfo(bag.id, slotID, id))
			else
				first = first or { bag.id, slotID }
				if not plain then
					if special == nil then special = self:IsSpecialBag(bag.id) end
					if not special then plain = { bag.id, slotID } end
				end
			end
		end
	end
	local point = plain or first
	if point then
		local info = GetEmptySlotInfo(point[1], point[2], id)
		info.count = count
		empties[1] = info
	end
	return empties
end

-- The kind of bag a free slot is in, for the views that don't show bags apart
-- (Compact and Rows): 2 for the reagent bag, and in the combined bank for the
-- warband bank; 1 for the rest.
local function EmptySlotKind(INV, id, bagID)
	if INV:IsReagentBag(bagID) then return 2 end
	if id == 'combinedbank' then
		for _, warbandID in ipairs(INV.bagIds.warband or {}) do
			if warbandID == bagID then return 2 end
		end
	end
	return 1
end

-- The empty slot infos of every kind of bag, the first kind's first.
function INV:GetEmptySlotsByKind(id, bags, mode)
	local kinds = { {}, {} }
	for _, bag in ipairs(bags) do
		tinsert(kinds[EmptySlotKind(self, id, bag.id)], bag)
	end
	local empties = self:GetEmptySlots(id, kinds[1], mode)
	for _, info in ipairs(self:GetEmptySlots(id, kinds[2], mode)) do tinsert(empties, info) end
	return empties
end

-- The group a bag merges stacks in for Compact and Rows (ReadBags' groupOf):
-- the reagent bag is its own kind of bag, so the same item in it and in a
-- normal bag stays two slots when stacks are merged. Auto vendor
-- (INV:GetVendorItems) and the Categories tab read the bags with it too.
function INV:StackGroup(bagID)
	return self:IsReagentBag(bagID) and 'reagent' or 'bag'
end

function INV:GetSortedInventory(id)
	local bags, numItems, numLoading, categoryOf = self:ReadBags(id, function(bagID) return self:StackGroup(bagID) end)

	local inventory = {}
	for _, bag in ipairs(bags) do
		for _, item in ipairs(bag.items) do
			local categoryName = categoryOf[item]
			if not inventory[categoryName] then inventory[categoryName] = {} end
			tinsert(inventory[categoryName], item)
		end
	end

	-- Normal bags first, then the reagent bag. This category isn't sorted below,
	-- so it keeps that order. Grouped is one slot per kind of bag, pointing at
	-- its first free slot, so an item dropped on it lands there.
	local mode = self:GetEmptySlotMode(id)
	if mode then
		-- In combat no button can be made, so show only as many as exist; the
		-- queued pool top-up asks for a full update when combat ends.
		local empties = self:FitSlots(id, self.EMPTY_SLOTS_CATEGORY, 0, self:GetEmptySlotsByKind(id, bags, mode))
		if #empties > 0 then inventory[self.EMPTY_SLOTS_CATEGORY] = empties end
	end

	for categoryName,categoryItems in pairs(inventory) do
		if #categoryItems > 1 and categoryName ~= self.EMPTY_SLOTS_CATEGORY then
			table.sort(categoryItems, sortCategory)
		end
	end

	-- In combat a category with no frame (made since the fight began) or no
	-- button left shows no more than it has buttons, so nothing is made in
	-- combat; the queued top-up asks for a full update when it ends.
	if InCombatLockdown() then
		for categoryName, categoryItems in pairs(inventory) do
			if categoryName ~= self.EMPTY_SLOTS_CATEGORY then
				self:FitSlots(id, categoryName, 0, categoryItems)
				if #categoryItems == 0 then inventory[categoryName] = nil end
			end
		end
	end

	return inventory, numItems, numLoading
end

-- The Edit view's checkbox of a category as the profile says: checked when
-- hidden (a set the Equipment sets entry hides in this window is checked, and
-- its click puts that back: see CreateCategory).
function INV:UpdateFilterCheckbox(checkbox, windowId, categoryName)
	checkbox:SetChecked(self:IsCategoryHidden(windowId, categoryName))
end

function INV:CreateCategory(id, categoryName, slotPoolFunc)
	local container = self.containers[id]

	local categoryFrame = CreateFrame('frame', container:GetName() .. '_' .. categoryName, container.scrollFrame.ScrollChild)
	categoryFrame.container = container
	categoryFrame.name = categoryName
	categoryFrame:SetWidth(container:GetWidth() - self.config.padding * 2)
	categoryFrame.slots = {}
	if slotPoolFunc then
		categoryFrame.slotPool = slotPoolFunc(categoryFrame)
	else
		categoryFrame.slotPool = CreateObjectPool(
			function() return INV:CreateSlot(container, categoryName) end,
			function(_, slot) INV:ClearSlot(slot) end
		)
	end

	local header = CreateFrame('Button', nil, categoryFrame)
	header:SetHeight(self.config.categoryTitleHeight)
	header:SetPoint('TOPLEFT', categoryFrame)
	header:SetPoint('TOPRIGHT', categoryFrame)

	header.text = header:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(header.text, st.config.profile.inventory.fonts.titles)
	header.text:SetPoint('BOTTOMLEFT', 2, 2)
	header.text:SetText(self:CategoryName(categoryName))
	categoryFrame.header = header

	local filterCheckbox = st:CreateCheckButton(nil, categoryFrame)
    filterCheckbox:Hide()
    filterCheckbox:SetSize(8, 8)
    filterCheckbox:SetPoint('BOTTOM', header, 'BOTTOM', 0, 4)
    filterCheckbox:SetPoint('LEFT', header.text, 'RIGHT', 8, 0)
	-- A set the Equipment sets entry hides in this window can't be shown by its
	-- own flag, so its box does nothing: a click puts the check back, and a
	-- hover says why. The box stays enabled: a disabled button gets no OnEnter
	-- without SetMotionScriptsWhileDisabled, and SaftUI's check box has its
	-- template's disabled-checked texture stripped, so it might draw no check.
	filterCheckbox:HookScript('OnClick', function(self)
		if INV:IsSetHiddenBySetsEntry(id, categoryName) then
			INV:UpdateFilterCheckbox(self, id, categoryName)
			return
		end
		INV:SetCategoryHidden(id, categoryName, self:GetChecked())
		INV:UpdateContainerLayout(id)
	end)
	categoryFrame.filterCheckbox = filterCheckbox
	filterCheckbox:HookScript('OnEnter', function(self)
		if not INV:IsSetHiddenBySetsEntry(id, categoryName) then return end
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetText(string.format("Hidden in this window by the %s category's Show in (/sui > Bags > Categories).",
			INV:CategoryName(INV.SETS_ENTRY)), nil, nil, nil, nil, true)
		GameTooltip:Show()
	end)
	filterCheckbox:HookScript('OnLeave', function(self)
		if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
	INV:UpdateFilterCheckbox(filterCheckbox, id, categoryName)

	container.categories[categoryName] = categoryFrame

	return categoryFrame
end

-- Sets a title on its font string, cut short with dots inside `room` wide so
-- the scroll frame doesn't cut it mid-glyph: the name gives way, the count in
-- parentheses at its end stays. again says the font string was fitted before
-- (its wrap and width are set): only the text is set, as a color pass may.
local function FitTitle(text, title, room, again)
	if not again then
		text:SetWordWrap(false)
		text:SetWidth(0)
	end
	text:SetText(title)
	if text:GetUnboundedStringWidth() <= room then return end
	local head, tail = title:match('^(.-)( %(.-%))$')
	if not head then head, tail = title, '' end
	local cut = #head
	while cut > 0 do
		cut = cut - 1
		-- Not in the middle of a character, nor of a color escape.
		while cut > 0 and head:byte(cut + 1) and head:byte(cut + 1) >= 128 and head:byte(cut + 1) < 192 do cut = cut - 1 end
		local piece = head:sub(1, cut):gsub('|c%x*$', ''):gsub('|$', '')
		local opened = select(2, piece:gsub('|c%x%x%x%x%x%x%x%x', ''))
		local closed = select(2, piece:gsub('|r', ''))
		text:SetText(piece .. (opened > closed and '|r' or '') .. '...' .. tail)
		if text:GetUnboundedStringWidth() <= room then return end
	end
	text:SetText('...' .. tail)
end
INV.FitTitle = FitTitle -- INV:ApplyFonts fits a title again when the Title font changes

-- Fills a category frame with its items (made if it isn't), shows it and sizes
-- it. title is its header's text: by default its name and how many it holds
-- ("Armor (3)"), and false for none, the header hidden and taking no height.
-- lineSlots is how many slots a line holds, by default the window's line now
-- (INV:SlotLine). A frame whose slots are anchored for another line has them
-- anchored again, out of combat.
function INV:UpdateCategory(id, categoryName, categoryItems, title, lineSlots)
	local container = self.containers[id]
	lineSlots = lineSlots or self:SlotLine(container)

	local categoryFrame = container.categories[categoryName] or self:CreateCategory(id, categoryName)
	categoryFrame:Show()
	-- Set before any slot is made: INV:SetSlotPosition puts the first slot of
	-- an untitled frame at its top.
	categoryFrame.untitled = title == false
	categoryFrame.header:SetShown(title ~= false)

	-- Hide any visible icons that are no longer in use
	for i = #categoryItems + 1, #categoryFrame.slots do
		if categoryFrame.slots[i].info then self:ClearSlot(categoryFrame.slots[i]) end
	end

	-- A grouped empty slot stands for several free slots, so count those.
	local numShown = #categoryItems
	if categoryName == self.EMPTY_SLOTS_CATEGORY then
		numShown = 0
		for _, item in pairs(categoryItems) do numShown = numShown + (item.count or 1) end
	end
	local titleText = title or title == nil and ("%s (%d)"):format(self:CategoryName(categoryName), numShown)

	for i, item in pairs(categoryItems) do
		local slot = categoryFrame.slots[i] or self:CreateSlot(container, categoryName)
		self:AssignSlot(container, slot, item)
	end

	-- Ensure that there's always a decent slot pool created to avoid
	-- tainting in combat
	if not InCombatLockdown() then
		for i = #categoryFrame.slots - #categoryItems + 1 , INV.CATEGORY_SLOT_POOL do
			self:CreateSlot(container, categoryName)
		end
	end

	if categoryFrame.slotLine ~= lineSlots and not InCombatLockdown() then
		for _, slot in ipairs(categoryFrame.slots) do
			self:SetSlotPosition(slot, categoryFrame, container, lineSlots)
		end
		categoryFrame.slotLine = lineSlots
	end

	-- In combat the slots stay where they are, so the frame is as wide as the
	-- line they are anchored at: rows and width agree with them.
	lineSlots = categoryFrame.slotLine or lineSlots
	local spacing = self.config.buttonspacing
	local numRows = math.ceil(#categoryItems / lineSlots)
	categoryFrame.numRows = numRows
	local rowsHeight = (self:GetButtonHeight() + spacing) * numRows
	if title == false then
		categoryFrame:SetHeight(max(0, rowsHeight - spacing))
	else
		categoryFrame:SetHeight(rowsHeight + self.config.categoryTitleHeight)
	end
	local width = (self:GetButtonWidth() + spacing) * lineSlots - spacing
	categoryFrame:SetWidth(width)
	if titleText then
		-- Every view cuts a title to its column, Compact's too: Heading (Colus) is
		-- wider than Text was, so a long name would run into the next column's.
		local room = width - 2 - (categoryFrame.filterCheckbox and categoryFrame.filterCheckbox:IsShown() and 16 or 0)
		FitTitle(categoryFrame.header.text, titleText, room)
		-- What was fitted, for INV:ApplyFonts.
		categoryFrame.titleText, categoryFrame.titleRoom = titleText, room
	else
		categoryFrame.titleText, categoryFrame.titleRoom = nil, nil
	end
end

function INV:FlushCategory(category)
	for _,slot in pairs(category.slots) do
		if slot.info then self:ClearSlot(slot) end
	end
	category:Hide()
end

function INV:FlushCategories(container, sorted_inv)
	-- If a category was emptied it wouldn't be in the above loop.
	-- This finds those categories and hides them properly

	for categoryName,category in pairs(container.categories) do
		if not (sorted_inv[categoryName] or categoryName == 'Bags' or categoryName == 'Currencies') then
			INV:FlushCategory(category)
		end
	end
end

-- Makes a window's category frames, out of combat: one per list category
-- (INV:GetCategoryList; the sets entry's 'Set: ...' frames are made when an
-- item first needs one), and the bag window's Empty Slots and Currencies.
function INV:InitializeAllCategories(containerName)
	for _, entry in ipairs(self:GetCategoryList()) do
		if entry.kind ~= 'sets' then
			self:CreateCategory(containerName, entry.id)
			self:UpdateCategory(containerName, entry.id, {})
		end
	end
	if containerName == 'bag' then
		-- Made now, out of combat, with its slot pool, even while the setting is
		-- off: it is flushed like any empty category until it has slots.
		self:CreateCategory(containerName, self.EMPTY_SLOTS_CATEGORY)
		self:UpdateCategory(containerName, self.EMPTY_SLOTS_CATEGORY, {})
		self:InitializeCurrencyCategory()
	end
end