local st = SaftUI
local INV = st:GetModule('Inventory')

-- The data behind the bag views (config `view`: 'onebag', 'multibag', 'compact'
-- or 'rows'): the category order every view shares, what a bag is, and the
-- ordered sections each view lays out. Nothing here draws. Compact keeps
-- INV:GetSortedInventory.

local VIEWS = { onebag = true, multibag = true, compact = true, rows = true }

-- The views in the order the title bar's buttons and /sui's View select list
-- them, and how each is worded there.
INV.viewIds = { 'onebag', 'multibag', 'compact', 'rows' }
INV.viewLabels = { onebag = 'One bag', multibag = 'Multi bag', compact = 'Compact', rows = 'Rows' }

-- The view a window's settings name; Compact for anything else.
function INV:GetView(id)
	local view = self.config[id] and self.config[id].view
	return VIEWS[view] and view or 'compact'
end

-- The view a window is laid out in. It follows its settings (INV:ApplyView),
-- except while a switch made in combat waits for the end of combat.
function INV:GetLaidOutView(container)
	return container.view or self:GetView(container.id)
end

-- How many slots a line of a window's view holds: a Compact column's perrow,
-- or the whole width of Compact's columns (perrow * maxColumns) in the other
-- views, so a window is as wide in every view.
function INV:LineSlots(id, view)
	local config = self.config[id]
	if view == 'compact' then return config.perrow end
	return config.perrow * config.maxColumns
end

-- The name of the category frame a section is laid out in: Rows' categories
-- and the Currencies section have the window's category frames of their name;
-- One bag's and Multi bag's sections have frames of their own, 'view:<key>'.
function INV:SectionFrameName(section)
	if section.kind == 'category' or section.kind == 'currencies' then return section.key end
	return 'view:' .. section.key
end

-- The order categories run in, as a number: a key's place in the category
-- list (INV:GetCategoryList), where a 'Set: ...' key is the sets entry's
-- place. Any other key (a deleted category still on screen) runs just before
-- Miscellaneous, and Empty Slots after the list. Keys that share a rank
-- (sets, unknown keys) go by key; see CategoryBefore.
function INV:CategoryRank(key)
	local list = self:GetCategoryList()
	if key == self.EMPTY_SLOTS_CATEGORY then return #list + 1 end
	return self:CategoryPlace(key) or (list.byId[self.MISC_CATEGORY].place - 0.5)
end

-- Whether category a comes before category b: by rank, then by name.
function INV:CategoryBefore(a, b)
	local rankA, rankB = self:CategoryRank(a), self:CategoryRank(b)
	if rankA ~= rankB then return rankA < rankB end
	return a < b
end

-- Sorts item infos in place: by category order, then SaftUI's item sort within
-- a category. Free slot infos go last. categoryOf (info -> category name) is
-- for a caller that has the categories already.
function INV:SortByPriority(items, categoryOf)
	local categories, ranks = {}, {}
	for _, info in ipairs(items) do
		local category = info.empty and self.EMPTY_SLOTS_CATEGORY
			or categoryOf and categoryOf[info] or self:GetItemCategory(info)
		categories[info] = category
		if not ranks[category] then ranks[category] = self:CategoryRank(category) end
	end
	table.sort(items, function(a, b)
		local categoryA, categoryB = categories[a], categories[b]
		if categoryA ~= categoryB then
			if ranks[categoryA] ~= ranks[categoryB] then return ranks[categoryA] < ranks[categoryB] end
			return categoryA < categoryB
		end
		return self.CompareItems(a, b)
	end)
	return items
end

-- The name of a bank tab where the client gives one (retail's bank tabs are
-- named by the player), by its bag ID.
local function GetTabName(bagID)
	if not (C_Bank and C_Bank.FetchPurchasedBankTabData and Enum.BankType) then return end
	for _, bankType in pairs(Enum.BankType) do
		for _, tab in ipairs(C_Bank.FetchPurchasedBankTabData(bankType) or {}) do
			if tab.ID == bagID and tab.name and tab.name ~= '' then return tab.name end
		end
	end
end

-- Where a bag ID is in a list of bag IDs, or nil.
local function IndexOf(list, value)
	for i, v in ipairs(list or {}) do
		if v == value then return i end
	end
end

-- Whether a bag is special: a reagent bag, or one that holds only some kinds
-- of item (a bag family, like a herb bag's). The backpack never is, nor a
-- bank tab, except on Forever, where the bank's tabs after the first (the
-- base bank) are bag slots and their bags can be herb bags.
function INV:IsSpecialBag(bagID)
	if bagID == Enum.BagIndex.Backpack or IndexOf(self.bagIds.warband, bagID) then return false end
	local bankTab = IndexOf(self.bagIds.bank, bagID)
	if bankTab and (not st.forever or bankTab == 1) then return false end
	if self:IsReagentBag(bagID) then return true end
	local _, family = C_Container.GetContainerNumFreeSlots(bagID)
	return (family or 0) ~= 0
end

-- What a bag is: its id, name, number of slots, free slots, and whether it is a
-- special bag (INV:IsSpecialBag).
function INV:GetBagInfo(bagID)
	local total = C_Container.GetContainerNumSlots(bagID)
	local free = C_Container.GetContainerNumFreeSlots(bagID)
	local bankTab = IndexOf(self.bagIds.bank, bagID)
	local warbandTab = IndexOf(self.bagIds.warband, bagID)

	-- The client never answers nil (its name isn't nilable): '' is no name.
	local name = C_Container.GetBagName(bagID)
	if name == '' then name = nil end
	name = name or GetTabName(bagID)
	if not name then
		if bagID == Enum.BagIndex.Backpack then
			name = BAG_NAME_BACKPACK or 'Backpack'
		elseif bankTab then
			name = 'Bank tab ' .. bankTab
		elseif warbandTab then
			name = 'Warband tab ' .. warbandTab
		elseif self:IsReagentBag(bagID) then
			name = 'Reagent bag'
		else
			name = 'Bag ' .. bagID
		end
	end

	return { id = bagID, name = name, total = total, free = free or 0, special = self:IsSpecialBag(bagID) }
end

-- The frames One bag's or Multi bag's sections of a window are laid out in, by
-- name, each with `slots`, how many slots its bags have, and `untitled` (One
-- bag's main grid). A section's items and free slots can't outnumber its
-- bags' slots, so that many buttons always hold it. Read from the bags alone,
-- with no item read, for INV:EnsureSlotPools; grouped as GetViewSections
-- groups the bags.
function INV:GetSectionPools(id, view)
	local pools = {}
	for _, bagID in pairs(self.containers[id].bag_ids) do
		local slots = C_Container.GetContainerNumSlots(bagID)
		if slots > 0 then
			local main = view == 'onebag' and not self:IsSpecialBag(bagID)
			local name = self:SectionFrameName({ key = main and 'main' or 'bag' .. bagID, kind = main and 'main' or 'bag' })
			local pool = pools[name] or { slots = 0, untitled = main }
			pool.slots = pool.slots + slots
			pools[name] = pool
		end
	end
	return pools
end

-- The item subtype of the bag in a bag slot of the player's ("Reagent Bag",
-- "Herb Bag", "Quiver": localized by the client), or nil when any step of
-- finding it gives nothing.
local function BagTypeName(bagID)
	local toInventoryID = C_Container.ContainerIDToInventoryID
	local invID = toInventoryID and toInventoryID(bagID)
	local itemID = invID and GetInventoryItemID('player', invID)
	local itemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not (itemID and itemInfoInstant) then return end
	local subtype = select(3, itemInfoInstant(itemID))
	if type(subtype) == 'string' and subtype ~= '' then return subtype end
end

-- A bag's section title: its name, a special bag's type after it in grey (so
-- a bag named "Shipwright's Satchel" says it is a reagent bag), and how full
-- it is. The type is left out when the name already says it.
local function BagTitle(info)
	local typeName = info.special and BagTypeName(info.id)
	local named = ''
	if typeName and typeName ~= info.name then
		local r, g, b = st.config.profile.colors.text.grey:GetRGB()
		named = (' |cff%02x%02x%02x\194\183 %s|r'):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), typeName)
	end
	return ('%s%s (%d / %d)'):format(info.name, named, info.total - info.free, info.total)
end

-- The items of some bag records, in bag order.
local function ItemsOf(bags)
	local items = {}
	for _, bag in ipairs(bags) do
		for _, item in ipairs(bag.items) do tinsert(items, item) end
	end
	return items
end

-- A section of a bag window: its items in priority order, then its empty slots
-- (empties). In combat, no more of them than its frame has buttons (FitSlots).
local function BagSection(self, id, key, title, kind, bags, categoryOf, empties)
	local section = { key = key, title = title, items = self:SortByPriority(ItemsOf(bags), categoryOf), kind = kind }
	local name = self:SectionFrameName(section)
	self:FitSlots(id, name, 0, section.items)
	for _, info in ipairs(self:FitSlots(id, name, #section.items, empties)) do tinsert(section.items, info) end
	return section
end

-- The sections of a window in a view, in the order they are laid out, and how
-- many item slots there are and how many of those are still loading. A section
-- is { key, title, items, kind }: kind is 'main', 'bag', 'category' or
-- 'currencies', and title is false for no heading. Reads the same items as
-- INV:GetSortedInventory, with the window's stackItems and Empty slots
-- settings. The view is 'onebag', 'multibag' or 'rows'; Compact has no sections.
-- Rows leaves out the categories hidden in the profile (their Show in, INV:IsCategoryHidden),
-- as Compact does; One bag and Multi bag show every item.
function INV:GetViewSections(id, view)
	local container = self.containers[id]
	local mode = self:GetEmptySlotMode(id)
	local sections = {}
	local infos = {}
	for _, bagID in pairs(container.bag_ids) do infos[bagID] = self:GetBagInfo(bagID) end

	local bags, numItems, numLoading, categoryOf
	if view == 'rows' then
		bags, numItems, numLoading, categoryOf = self:ReadBags(id, function(bagID)
			return self:IsReagentBag(bagID) and 'reagent' or 'bag'
		end)
		local byCategory = {}
		for _, item in ipairs(ItemsOf(bags)) do
			local category = categoryOf[item]
			byCategory[category] = byCategory[category] or {}
			tinsert(byCategory[category], item)
		end
		local order = {}
		for category in pairs(byCategory) do
			if not self:IsCategoryHidden(id, category) then tinsert(order, category) end
		end
		table.sort(order, function(a, b) return self:CategoryBefore(a, b) end)
		for _, category in ipairs(order) do
			local items = byCategory[category]
			table.sort(items, self.CompareItems)
			local title = ('%s (%d)'):format(self:CategoryName(category), #items)
			local fitted = self:FitSlots(id, category, 0, items)
			-- A category with no frame yet (made in combat) waits for the end of it.
			if #fitted > 0 then
				tinsert(sections, { key = category, title = title, items = fitted, kind = 'category' })
			end
		end
		local empties = not self:IsCategoryHidden(id, self.EMPTY_SLOTS_CATEGORY)
			and self:FitSlots(id, self.EMPTY_SLOTS_CATEGORY, 0, self:GetEmptySlotsByKind(id, bags, mode))
		if empties and #empties > 0 then
			local shown = 0
			for _, info in ipairs(empties) do shown = shown + (info.count or 1) end
			tinsert(sections, {
				key = self.EMPTY_SLOTS_CATEGORY,
				title = ('%s (%d)'):format(self.EMPTY_SLOTS_CATEGORY, shown),
				items = empties,
				kind = 'category',
			})
		end
	else
		-- One bag merges stacks within the main group or a special bag; Multi bag
		-- within a bag.
		bags, numItems, numLoading, categoryOf = self:ReadBags(id, function(bagID)
			if view == 'onebag' and not infos[bagID].special then return 'main' end
			return tostring(bagID)
		end)
		-- A bag that isn't there (an empty bag slot) has no section.
		local present = {}
		for _, bag in ipairs(bags) do
			if infos[bag.id].total > 0 then tinsert(present, bag) end
		end
		if view == 'onebag' then
			local normal, special = {}, {}
			for _, bag in ipairs(present) do
				tinsert(infos[bag.id].special and special or normal, bag)
			end
			-- Grouped is one free slot per kind of bag: in the combined bank, one
			-- for the bank and one for the warband bank.
			tinsert(sections, BagSection(self, id, 'main', false, 'main', normal, categoryOf,
				self:GetEmptySlotsByKind(id, normal, mode)))
			for _, bag in ipairs(special) do
				tinsert(sections, BagSection(self, id, 'bag' .. bag.id, BagTitle(infos[bag.id]), 'bag', { bag }, categoryOf,
					self:GetEmptySlots(id, { bag }, mode)))
			end
		else
			for _, bag in ipairs(present) do
				tinsert(sections, BagSection(self, id, 'bag' .. bag.id, BagTitle(infos[bag.id]), 'bag', { bag }, categoryOf,
					self:GetEmptySlots(id, { bag }, mode)))
			end
		end
	end

	-- Only the bag window has currencies, once its category is made.
	if id == 'bag' and container.categories and container.categories.Currencies then
		tinsert(sections, { key = 'Currencies', title = 'Currencies', items = {}, kind = 'currencies' })
	end

	return sections, numItems, numLoading
end
