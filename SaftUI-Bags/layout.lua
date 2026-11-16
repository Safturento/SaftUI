local st = SaftUI
local INV = st:GetModule('Inventory')

-- How a window is laid out (INV:UpdateContainer runs it): Compact packs the
-- categories into columns and holds them there while the window is open, One
-- bag, Multi bag and Rows stack their sections, every view sizes the window
-- here, and a view switch lays the window out again (INV:ApplyView).

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

-- The Edit view's checkboxes (Show in, off when checked), shown or hidden, and
-- set from what the profile says.
function INV:ShowFilterCheckboxes(container, shown)
	for categoryName, category in pairs(container.categories) do
		category.filterCheckbox:SetShown(shown)
		self:UpdateFilterCheckbox(category.filterCheckbox, container.id, categoryName)
	end
end

-- A category the player hid (Show in, in the Edit view's checkboxes) is hidden outside that view.
function INV:FlushIfFiltered(container, category)
	if not container.filterButton:GetChecked() and self:IsCategoryHidden(container.id, category.name) then
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
	container.sectionLine = nil
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
-- footer and the padding, at least 200 tall. Under the Blizzard theme the
-- header sits in the metal's title bar above the window, which then holds none
-- of it (st:HeaderRoom). Every view sizes its window here, so a window is the
-- same size for the same content in every view.
local function SizeWindow(self, container, contentWidth, contentHeight, visibleHeight)
	local config = self.config
	local height = st:HeaderRoom(container) + container.footer:GetHeight() + config.padding * 2
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

-- The bag window's currencies as UpdateCurrencyCategory lays them out, or nil
-- when its Currencies section isn't shown.
local function ShownCurrencies(self, container)
	local category = container.categories.Currencies
	if not (category and (container.filterButton:GetChecked() or not self.config.filters.categories.bag.Currencies)) then return end
	return self:GetCurrencies(category.filterButton:GetChecked())
end

-- How many slots wide a window's line is: the widest of its sections (a
-- section's items, a grouped free slot being one button; the Currencies
-- section's currencies, `currencies` being ShownCurrencies), and wide enough
-- to use the room the header's least width gives (whole slots), but never
-- under perrow, one Compact column, nor over perrow * maxColumns.
function INV:SectionLineSlots(container, sections, currencies)
	local id = container.id
	local most = 0
	for _, section in ipairs(sections) do
		local need = section.kind == 'currencies' and currencies and #currencies or #section.items
		most = max(most, need)
	end
	local slot = self:GetButtonWidth() + self.config.buttonspacing
	local room = math.floor((math.ceil(self:HeaderMinWidth(container)) - self.config.padding * 2 + self.config.buttonspacing) / slot)
	return min(max(most, room, self.config[id].perrow), self:LineSlots(id, 'rows'))
end

--[[
	One bag, Multi bag and Rows lay a window out in sections (INV:GetViewSections),
	each a category frame as wide as the window's line, stacked top to bottom in
	the scroll child, spacing apart. The line is as many slots as the widest
	section shows (INV:SectionLineSlots), from perrow (one Compact column) up to
	perrow * maxColumns (INV:LineSlots), so a window with few items is narrow.
	UpdateCategory and UpdateCurrencyCategory size a frame to the line. Each
	frame is anchored to the scroll child at its own offset, never to the frame
	above it (as Compact's columns are, see INV:UpdateConfig). Rows uses the
	window's category frames, and the Currencies section the bag window's
	Currencies; One bag's and Multi bag's sections have frames of their own
	('view:<key>', made by INV:CreateCategory). The window's other category
	frames, and Compact's columns, are hidden. The window is sized as Compact
	sizes it (VisibleHeight, SizeWindow); while it is open it doesn't shrink,
	in height or in line (container.heldSize), and the items close up within
	their sections; it widens at once when a section needs more. Closing the
	window or switching views releases it (INV:ReleaseLayout). In combat
	no slot is moved (Blizzard's buttons): each frame is sized by the line its
	slots are anchored at (category.slotLine), the window is as wide as the
	widest, and a layout after combat brings the line to the rule.
]]
function INV:LayoutSections(container, sections)
	local id = container.id
	local spacing = self.config.buttonspacing
	local currencies
	for _, section in ipairs(sections) do
		if section.kind == 'currencies' then currencies = ShownCurrencies(self, container) end
	end
	local want = self:SectionLineSlots(container, sections, currencies)
	local held = container:IsShown() and container.heldSize
	if held and held.lineSlots then want = max(want, held.lineSlots) end
	local lineSlots = want
	if InCombatLockdown() then
		-- Each frame's slots stay anchored at their own line (UpdateCategory
		-- sizes it by that), so the window is as wide as the widest of them.
		lineSlots = 0
		local disagree
		for _, section in ipairs(sections) do
			local frame = container.categories[self:SectionFrameName(section)]
			if frame and frame.slotLine then
				lineSlots = max(lineSlots, frame.slotLine)
			end
		end
		if lineSlots == 0 then lineSlots = container.sectionLine or self:LineSlots(id, self:GetLaidOutView(container)) end
		for _, section in ipairs(sections) do
			local frame = container.categories[self:SectionFrameName(section)]
			if frame and frame.slotLine and frame.slotLine ~= lineSlots then disagree = true end
		end
		-- Laid out again out of combat, to the line the rule gives.
		if want ~= lineSlots or disagree then
			st:QueueAfterCombat('InventoryLine', function() INV:QueueUpdate(true) end)
		end
	end
	container.sectionLine = lineSlots
	local lineWidth = (self:GetButtonWidth() + spacing) * lineSlots - spacing
	local child = container.scrollFrame.ScrollChild

	local inSections, y = {}, 0
	for _, section in ipairs(sections) do
		local name = self:SectionFrameName(section)
		if section.kind == 'currencies' then
			-- Shown or hidden by its own setting (filters.categories.bag.Currencies).
			self:UpdateCurrencyCategory(container.filterButton:GetChecked(), lineSlots, currencies)
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
		if held and held.height then visibleHeight = max(visibleHeight, held.height) end
		-- A line widened in combat isn't held: it follows the rule after combat.
		container.heldSize = { height = visibleHeight, lineSlots = not InCombatLockdown() and lineSlots or held and held.lineSlots or nil }
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
		category.slotLine = lineSlots
	end
	if view == 'compact' then
		for _, column in ipairs(container.columns) do column:Show() end
	end
	self:UpdateContainer(id, true, true)
	local search = self.containers.bag and self.containers.bag.search
	if search then self:UpdateSearchFilter(search) end
end
