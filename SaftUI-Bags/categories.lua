local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The category list the bags use: the default categories
	(categorydefaults.lua) with the profile's edits, the user's own categories,
	the saved order and the pins; and how an item gets its category.

	Profile keys, under INV.config, read at call time (no AceDB defaults;
	INV:EnsureConfigTables makes them):
	  categories = {
	    version,            set once by the migration
	    order   = nil | { id, ... },
	    edits   = { [defaultId] = { name?, enabled?, hide?, rule? } },
	    custom  = { [customId] = { name, enabled, hide, rule } },
	    deleted = { [defaultId] = true },
	    nextId  = 1,
	  }
	  categoryPins = { [itemID] = id }

	A key is a list id, or 'Set: <set name>' for an equipment set; 'Empty
	Slots' and 'Currencies' are keys outside the list. Category frames, ranks,
	held layouts and hide flags go by key, and a default's id is the name it
	shipped with, so a rename changes only what headers show.

	  INV:CategoryStore()        -> the categories table, its sub-tables made
	  INV:GetCategoryList()      -> the entries in order, with list.byId[id]:
	                                { id, name, enabled, hide, rule, kind ('sets' |
	                                'rule' | 'misc'), default, sells, edited, place }
	  INV:GetDefaultCategory(id) -> the shipped entry (categorydefaults.lua)
	  INV:CategoryName(key), INV:CategoryPlace(key)
	  INV:CategoriesChanged()    drops the list and the compiled rules, makes the
	                             new categories' frames and updates
	  INV:GetItemCategory(info)  -> key, why
	  INV:IsAutoVendorItem(info, key)

	The write side (below) normalizes every edit against the shipped default:
	a field equal to it is removed, an empty edit is removed. Entries of the
	list alias the shipped rule and the store's own hide and rule tables, so a
	setter writes a new table (a copy) and never changes one in place. Every
	write that changes something ends in INV:CategoriesChanged().
	  INV:AddUserCategory() -> id        INV:RenameCategory(id, name) -> ok
	  INV:SetCategoryEnabled(id, on)     INV:SetCategoryRule(id, rule)
	  INV:MoveCategory(id, place)        INV:RemoveCategory(id)
	  INV:RestoreCategory(id)            INV:GetDeletedDefaults()
	  INV:ResetCategory(id)              INV:ResetAllCategories()
	  INV:GetPin(itemID)                 INV:PinItem(itemID, id)
	  INV:UnpinItem(itemID)              INV:GetPinnedItems(id)
	  INV:IsProtected(itemID)            INV:SetProtected(itemID, on)
	  INV:IsAutoVendorMarked(itemID)     INV:SetAutoVendorMark(itemID, on)
	  INV:EnsureCategoryFrames()
	  INV:MigrateCategories()    an old profile's hide flags and Auto Vendor list
	  INV:IsCategoryHidden(windowId, key)
	  INV:SetCategoryHidden(windowId, key, hidden)    (Show in, below)
]]

INV.SELL_CATEGORY = 'Grays/Auto Vendor'
INV.SETS_ENTRY = 'Equipment sets'
INV.MISC_CATEGORY = 'Miscellaneous'

local R = INV.Rules
local IC = INV.ItemClasses
local strfind = string.find

-- The store's sub-tables.
local STORE_TABLES = { 'edits', 'custom', 'deleted' }

-- Can't be deleted.
local KEPT = { [INV.SELL_CATEGORY] = true, [INV.SETS_ENTRY] = true, [INV.MISC_CATEGORY] = true }

-- The list and its compiled rules, for one store: dropped by
-- INV:CategoriesChanged, and built again for another profile's store (a
-- profile switch, copy or reset gives the bags a new one) at once.
local list, listStore
local compiled = {}

function INV:CategoryStore()
	local store = self.config.categories
	if type(store) ~= 'table' then
		store = {}
		self.config.categories = store
	end
	for _, key in ipairs(STORE_TABLES) do
		if type(store[key]) ~= 'table' then store[key] = {} end
	end
	if type(store.nextId) ~= 'number' then store.nextId = 1 end
	return store
end

function INV:GetDefaultCategory(id)
	for _, def in ipairs(self.CategoryDefaults.Build()) do
		if def.id == id then return def end
	end
end

-- A default as the profile has it: its edit's fields over the shipped ones.
local function DefaultEntry(def, edit)
	local entry = {
		id = def.id, name = def.name, enabled = def.enabled, hide = {}, rule = def.rule,
		kind = def.kind, default = true, sells = def.sells, edited = false,
	}
	if type(edit) == 'table' then
		entry.edited = next(edit) ~= nil
		if type(edit.name) == 'string' and edit.name ~= '' then entry.name = edit.name end
		if type(edit.enabled) == 'boolean' then entry.enabled = edit.enabled end
		if type(edit.hide) == 'table' then entry.hide = edit.hide end
		-- A rule that isn't a table is kept: it matches nothing.
		if def.kind == 'rule' and edit.rule ~= nil then entry.rule = edit.rule end
	end
	-- Miscellaneous catches whatever is left: always on.
	if def.kind == 'misc' then entry.enabled = true end
	return entry
end

local function CustomEntry(id, custom)
	return {
		id = id,
		name = type(custom.name) == 'string' and custom.name ~= '' and custom.name or id,
		enabled = custom.enabled ~= false,
		hide = type(custom.hide) == 'table' and custom.hide or {},
		rule = custom.rule,
		kind = 'rule', default = false, sells = false, edited = false,
	}
end

-- 'custom:<n>' by n.
local function CustomBefore(a, b)
	local na, nb = tonumber(a:match('^custom:(%d+)$')), tonumber(b:match('^custom:(%d+)$'))
	if na and nb and na ~= nb then return na < nb end
	return a < b
end

local function IndexOf(ids, id)
	for i, v in ipairs(ids) do
		if v == id then return i end
	end
end

--[[
	The saved order, else the default order, keeping each id once if it
	exists: a default that isn't deleted (Grays/Auto Vendor, Equipment sets and
	Miscellaneous can't be), or a category in custom. A default missing from
	the order (new in this version, or just restored) goes after the nearest
	default before it in the default order that is in the list, else first.
	The user's categories always come with an order (a create writes it); one
	missing from it goes last, before Miscellaneous. Miscellaneous is always
	last.
]]
function INV:GetCategoryList()
	local store = self:CategoryStore()
	if list and listStore == store then return list end
	compiled = {}
	local defaults = self.CategoryDefaults.Build()
	local defaultById = {}
	for _, def in ipairs(defaults) do defaultById[def.id] = def end

	local function exists(id)
		if defaultById[id] then return KEPT[id] or not store.deleted[id] end
		return type(id) == 'string' and type(store.custom[id]) == 'table'
	end

	local ids, seen = {}, {}
	local function add(id, at)
		seen[id] = true
		table.insert(ids, at or #ids + 1, id)
	end

	local order = store.order
	if type(order) ~= 'table' then
		order = {}
		for i, def in ipairs(defaults) do order[i] = def.id end
	end
	for _, id in ipairs(order) do
		if id ~= self.MISC_CATEGORY and not seen[id] and exists(id) then add(id) end
	end
	for i, def in ipairs(defaults) do
		if def.id ~= self.MISC_CATEGORY and not seen[def.id] and exists(def.id) then
			local at = 1
			for j = i - 1, 1, -1 do
				if seen[defaults[j].id] then
					at = IndexOf(ids, defaults[j].id) + 1
					break
				end
			end
			add(def.id, at)
		end
	end
	local missing = {}
	for id, custom in pairs(store.custom) do
		if not seen[id] and type(id) == 'string' and type(custom) == 'table' then missing[#missing + 1] = id end
	end
	table.sort(missing, CustomBefore)
	for _, id in ipairs(missing) do add(id) end
	add(self.MISC_CATEGORY)

	local built = { byId = {} }
	for place, id in ipairs(ids) do
		local def = defaultById[id]
		local entry = def and DefaultEntry(def, store.edits[id]) or CustomEntry(id, store.custom[id])
		entry.place = place
		built[place] = entry
		built.byId[id] = entry
	end
	list, listStore = built, store
	return list
end

-- A list id's name; any other key is its own name.
function INV:CategoryName(key)
	local entry = self:GetCategoryList().byId[key]
	return entry and entry.name or key
end

-- A list id's place in the list, and the sets entry's for a 'Set: ...' key;
-- nil for any other key.
function INV:CategoryPlace(key)
	local byId = self:GetCategoryList().byId
	local entry = byId[key]
	if not entry and type(key) == 'string' and key:sub(1, 5) == 'Set: ' then entry = byId[self.SETS_ENTRY] end
	return entry and entry.place
end

-- The profile's categories changed (an edit, a pin's category made or
-- deleted): reads them again and updates the bags.
function INV:CategoriesChanged()
	list = nil
	compiled = {}
	self:EnsureCategoryFrames()
	self:QueueUpdate(true)
end

--[[
	Gives every list category but the sets entry a frame in every window made
	so far (a window that isn't made gets them from InitializeAllCategories),
	as InitializeAllCategories makes them, so no frame or slot button is made
	in combat for an item that lands in a category made since. In combat it
	queues itself for the end of it, and asks for an update then.
]]
function INV:EnsureCategoryFrames()
	if st:QueueAfterCombat('InventoryCategoryFrames', function()
		INV:EnsureCategoryFrames()
		INV:QueueUpdate(true)
	end) then return end
	local entries = self:GetCategoryList()
	for id, container in pairs(self.containers) do
		-- A window that is made: it has its frames and a scroll frame.
		if type(container) == 'table' and container.categories and container.scrollFrame
			and type(container.GetName) == 'function' then
			for _, entry in ipairs(entries) do
				if entry.kind ~= 'sets' and not container.categories[entry.id] then
					self:CreateCategory(id, entry.id)
					self:UpdateCategory(id, entry.id, {})
					container.categories[entry.id]:Hide()
				end
			end
		end
	end
end

local function Compiled(entry)
	local fn = compiled[entry.id]
	if not fn then
		fn = R.Compile(entry.rule)
		compiled[entry.id] = fn
	end
	return fn
end

-- The first equipment set the client puts a bag slot's item in, or nil.
local function EquipmentSet(info)
	if not (C_Container and C_Container.GetContainerItemEquipmentSetInfo) then return end
	if info.bagID == nil or info.slotID == nil then return end
	local isItemInSet, itemSetList = C_Container.GetContainerItemEquipmentSetInfo(info.bagID, info.slotID)
	if isItemInSet and type(itemSetList) == 'string' then
		return (strsplit(',', itemSetList))
	end
end

--[[
	An item's category key, and why it is there:
	  - a pin (categoryPins) to a list category that exists, is on and isn't
	    the sets entry: { kind = 'pin' };
	  - else the list in order, skipping the categories that are off:
	      the sets entry: 'Set: <first set>' for armor and weapons the client
	        puts in an equipment set, { kind = 'set' };
	      a rule that matches: { kind = 'rule', path = <its deciding node's path> };
	      Miscellaneous, last and always on: { kind = 'misc' }.
]]
function INV:GetItemCategory(info)
	local categories = self:GetCategoryList()
	local pins = self.config.categoryPins
	local pinned = type(pins) == 'table' and info.itemID ~= nil and pins[info.itemID]
	if pinned ~= nil then
		local entry = categories.byId[pinned]
		if entry and entry.enabled and entry.kind ~= 'sets' then return entry.id, { kind = 'pin' } end
	end
	for _, entry in ipairs(categories) do
		if entry.enabled then
			if entry.kind == 'misc' then
				return entry.id, { kind = 'misc' }
			elseif entry.kind == 'sets' then
				local set = IC.IsGear(info) and EquipmentSet(info)
				if set then return 'Set: ' .. set, { kind = 'set' } end
			else
				local matched, path = Compiled(entry)(info)
				if matched then return entry.id, { kind = 'rule', path = path } end
			end
		end
	end
end

-- Never sold, whatever an item's pin or category says: Cosmetic (Armor,
-- subclass 5, on both clients), and these words in its tooltip.
local COSMETIC_CLASS, COSMETIC_SUBCLASS = 4, 5
local NEVER_SOLD_TEXT = { 'fishing', 'blizzard account bound' }

--[[
	Whether auto vendor sells an item: it is in the category that sells
	(Grays/Auto Vendor), turned on, has a vendor price, and isn't protected.
	Whatever its pin or that category's rule says, an item is never sold when
	it is in an equipment set, Cosmetic (armor subclass 5 on both clients, by
	ID, so a client in another language is covered), its tooltip says
	"Fishing" or "Blizzard Account Bound", or its tooltip never arrived, so
	those words can't be read (selling can't be undone). The slot's junk coin and
	INV:GetVendorItems both ask this, so they never disagree. key is the item's
	category, when the caller has it already; else info.category (set by
	INV:ReadBags), else INV:GetItemCategory.
]]
function INV:IsAutoVendorItem(info, key)
	if not info or info.empty or not (info.vendorPrice and info.vendorPrice > 0) then return false end
	if self:IsProtected(info.itemID) then return false end
	key = key or info.category or self:GetItemCategory(info)
	local entry = self:GetCategoryList().byId[key]
	if not (entry and entry.sells and entry.enabled) then return false end
	if info.tooltipMissing then return false end
	if info.classID == COSMETIC_CLASS and info.subclassID == COSMETIC_SUBCLASS then return false end
	local tooltip = info.tooltipStripped
	if type(tooltip) == 'string' then
		for _, text in ipairs(NEVER_SOLD_TEXT) do
			if strfind(tooltip, text, 1, true) then return false end
		end
	end
	if EquipmentSet(info) then return false end
	return true
end

--------------------------------------------------------------------- writing

-- A deep copy of a rule: its tables only, so the profile never shares one with
-- a caller, with the shipped default, or with another category.
local function CopyTree(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = CopyTree(v) end
	return copy
end

local function SameTree(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for k, v in pairs(a) do
		if not SameTree(v, b[k]) then return false end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

-- The entry of a list id, or nil.
local function Entry(self, id)
	return type(id) == 'string' and self:GetCategoryList().byId[id] or nil
end

-- A default's edit table, made if it has none. Only fields that differ from
-- the default stay in it: Normalize removes an edit left empty.
local function EditOf(store, id)
	local edit = store.edits[id]
	if type(edit) ~= 'table' then
		edit = {}
		store.edits[id] = edit
	end
	return edit
end

local function Normalize(store, id)
	local edit = store.edits[id]
	if type(edit) == 'table' and next(edit) == nil then store.edits[id] = nil end
end

-- Writes one field of a list category: a default's as an edit (the field
-- removed when it equals the shipped value), a category of yours in custom.
-- Returns whether it changed.
local function SetField(self, id, field, value)
	local store = self:CategoryStore()
	local def = self:GetDefaultCategory(id)
	if def then
		local shipped = def[field]
		local edit = EditOf(store, id)
		local current = edit[field]
		if SameTree(value, shipped) then value = nil end
		if SameTree(current, value) then
			Normalize(store, id)
			return false
		end
		edit[field] = value
		Normalize(store, id)
	else
		local custom = store.custom[id]
		if SameTree(custom[field], value) then return false end
		custom[field] = value
	end
	return true
end

-- The order the list has now, as ids.
local function CurrentOrder(self)
	local out = {}
	for i, entry in ipairs(self:GetCategoryList()) do out[i] = entry.id end
	return out
end

local function RemovePinsTo(self, wanted)
	local pins = self.config.categoryPins
	if type(pins) ~= 'table' then return end
	for itemID, id in pairs(pins) do
		if wanted(id) then pins[itemID] = nil end
	end
end

local function ListIdsWithout(order, id)
	local out = {}
	for _, v in ipairs(order) do
		if v ~= id then out[#out + 1] = v end
	end
	return out
end

-- A new category of yours, "New category" (or "New category 2", ...), on, shown
-- in every window, catching nothing, just above Miscellaneous. Returns its id.
function INV:AddUserCategory()
	local store = self:CategoryStore()
	local taken = {}
	for _, entry in ipairs(self:GetCategoryList()) do taken[entry.name:lower()] = true end
	local name, n = 'New category', 1
	while taken[name:lower()] do
		n = n + 1
		name = 'New category ' .. n
	end
	local id = 'custom:' .. store.nextId
	store.nextId = store.nextId + 1
	store.custom[id] = { name = name, enabled = true, hide = {}, rule = { op = 'and', items = {} } }
	local order = ListIdsWithout(CurrentOrder(self), self.MISC_CATEGORY)
	order[#order + 1] = id
	order[#order + 1] = self.MISC_CATEGORY
	store.order = order
	self:CategoriesChanged()
	return id
end

-- Renames a list category. The name is trimmed; an empty one is refused. Its id
-- (so its frame, place, held layout, Show in and pins) stays.
function INV:RenameCategory(id, name)
	if type(name) ~= 'string' or not Entry(self, id) then return false end
	name = name:match('^%s*(.-)%s*$')
	if name == '' then return false end
	if SetField(self, id, 'name', name) then self:CategoriesChanged() end
	return true
end

-- On or off. Miscellaneous can't be turned off.
function INV:SetCategoryEnabled(id, on)
	local entry = Entry(self, id)
	if not entry or entry.kind == 'misc' or type(on) ~= 'boolean' then return false end
	if SetField(self, id, 'enabled', on) then self:CategoriesChanged() end
	return true
end

-- Sets a rule (stored as a copy). Not for the sets entry or Miscellaneous.
function INV:SetCategoryRule(id, rule)
	local entry = Entry(self, id)
	if not entry or entry.kind ~= 'rule' or type(rule) ~= 'table' then return false end
	if SetField(self, id, 'rule', CopyTree(rule)) then self:CategoriesChanged() end
	return true
end

-- Moves a category to a place in the list, 1 to #list - 1: Miscellaneous
-- can't move and nothing goes below it. Writes the whole order.
function INV:MoveCategory(id, place)
	local entry = Entry(self, id)
	if not entry or entry.kind == 'misc' or type(place) ~= 'number' then return false end
	local last = #self:GetCategoryList() - 1
	place = math.max(1, math.min(last, math.floor(place)))
	local order = ListIdsWithout(CurrentOrder(self), id)
	order = ListIdsWithout(order, self.MISC_CATEGORY)
	table.insert(order, place, id)
	order[#order + 1] = self.MISC_CATEGORY
	self:CategoryStore().order = order
	self:CategoriesChanged()
	return true
end

-- Removes a category of yours, or sends a default to deleted (its edits
-- cleared), and removes the pins to it. Not Miscellaneous, Grays/Auto Vendor
-- or Equipment sets.
function INV:RemoveCategory(id)
	local entry = Entry(self, id)
	if not entry or KEPT[id] then return false end
	local store = self:CategoryStore()
	if entry.default then
		store.deleted[id] = true
		store.edits[id] = nil
	else
		store.custom[id] = nil
	end
	-- A restored default goes back to its default place, not its old one.
	if type(store.order) == 'table' then store.order = ListIdsWithout(store.order, id) end
	RemovePinsTo(self, function(pinned) return pinned == id end)
	self:CategoriesChanged()
	return true
end

-- Brings a deleted default back at its default place, as shipped.
function INV:RestoreCategory(id)
	local store = self:CategoryStore()
	if type(id) ~= 'string' or not store.deleted[id] or not self:GetDefaultCategory(id) then return false end
	store.deleted[id] = nil
	store.edits[id] = nil
	self:CategoriesChanged()
	return true
end

-- The deleted defaults, as shipped, in the default order.
function INV:GetDeletedDefaults()
	local store = self:CategoryStore()
	local out = {}
	for _, def in ipairs(self.CategoryDefaults.Build()) do
		if store.deleted[def.id] and not KEPT[def.id] then out[#out + 1] = DefaultEntry(def) end
	end
	return out
end

-- Clears a default's edit: its name, on or off, Show in and rule. Its pins
-- stay.
function INV:ResetCategory(id)
	local entry = Entry(self, id)
	if not entry or not entry.default then return false end
	local store = self:CategoryStore()
	if store.edits[id] ~= nil then
		store.edits[id] = nil
		self:CategoriesChanged()
	end
	return true
end

-- Everything as shipped: order, edits, your categories and the deleted
-- defaults cleared, and the pins to your categories removed. Other pins and
-- Protected stay. (nextId stays, so an id is never used twice.)
function INV:ResetAllCategories()
	local store = self:CategoryStore()
	store.order = nil
	store.edits, store.custom, store.deleted = {}, {}, {}
	RemovePinsTo(self, function(pinned) return type(pinned) == 'string' and pinned:find('^custom:') ~= nil end)
	self:CategoriesChanged()
end

------------------------------------------------------------------ pins, marks

local function Pins(self)
	if type(self.config.categoryPins) ~= 'table' then self.config.categoryPins = {} end
	return self.config.categoryPins
end

local function Protect(self, itemID, on)
	if type(self.config.protectFilter) ~= 'table' then self.config.protectFilter = {} end
	self.config.protectFilter[itemID] = on and true or nil
end

-- The id an item is pinned to, or nil.
function INV:GetPin(itemID)
	local pins = self.config.categoryPins
	if type(pins) ~= 'table' or itemID == nil then return nil end
	return pins[itemID]
end

-- Pins an item to a list category (one per item; the sets entry takes none).
-- Pinning to Grays/Auto Vendor clears Protected.
function INV:PinItem(itemID, id)
	local entry = Entry(self, id)
	if itemID == nil or not entry or entry.kind == 'sets' then return false end
	Pins(self)[itemID] = id
	if id == self.SELL_CATEGORY then Protect(self, itemID, false) end
	self:CategoriesChanged()
	return true
end

function INV:UnpinItem(itemID)
	local pins = self.config.categoryPins
	if type(pins) ~= 'table' or itemID == nil or pins[itemID] == nil then return false end
	pins[itemID] = nil
	self:CategoriesChanged()
	return true
end

-- The items pinned to a category, by item ID ascending.
function INV:GetPinnedItems(id)
	local out = {}
	for itemID, pinned in pairs(self.config.categoryPins or {}) do
		if pinned == id then out[#out + 1] = itemID end
	end
	table.sort(out)
	return out
end

function INV:IsProtected(itemID)
	local filter = self.config.protectFilter
	return type(filter) == 'table' and itemID ~= nil and filter[itemID] and true or false
end

-- Protecting an item clears its pin to Grays/Auto Vendor.
function INV:SetProtected(itemID, on)
	if itemID == nil then return false end
	on = on and true or false
	Protect(self, itemID, on)
	if on and self:GetPin(itemID) == self.SELL_CATEGORY then Pins(self)[itemID] = nil end
	self:CategoriesChanged()
	return true
end

function INV:IsAutoVendorMarked(itemID)
	return self:GetPin(itemID) == self.SELL_CATEGORY
end

-- Marking pins an item to Grays/Auto Vendor (which clears Protected); unmarking
-- unpins it from there, and leaves a pin to another category alone.
function INV:SetAutoVendorMark(itemID, on)
	if itemID == nil then return false end
	if on then return self:PinItem(itemID, self.SELL_CATEGORY) end
	if self:IsAutoVendorMarked(itemID) then return self:UnpinItem(itemID) end
	return false
end

------------------------------------------------------------------- old profiles

local MIGRATED_WINDOWS = { 'bag', 'bank', 'warband', 'combinedbank' }

--[[
	A profile saved before the category list (no categories.version) sees
	today's categories: every hide flag filters.categories[window][name] that
	names a default category becomes that default's hide[window] (its Show in)
	and is removed from the flags ('Empty Slots', 'Currencies' and 'Set: ...'
	stay there); every item on autoVendorFilter is pinned to Grays/Auto Vendor,
	unless it is Protected (it stays Protected, with no pin), and the list is
	removed. The Protected list is untouched. Runs once (it sets version), writes
	the store as it is (no setter, so no frame is made here), and returns whether
	it ran; the caller then calls INV:CategoriesChanged().
]]
function INV:MigrateCategories()
	local store = self:CategoryStore()
	if store.version then return false end
	local flags = type(self.config.filters) == 'table' and self.config.filters.categories
	if type(flags) == 'table' then
		for _, window in ipairs(MIGRATED_WINDOWS) do
			local byName = flags[window]
			if type(byName) == 'table' then
				for _, def in ipairs(self.CategoryDefaults.Build()) do
					if byName[def.id] then
						local edit = EditOf(store, def.id)
						if type(edit.hide) ~= 'table' then edit.hide = {} end
						edit.hide[window] = true
						byName[def.id] = nil
					end
				end
			end
		end
	end
	local marked = self.config.autoVendorFilter
	if type(marked) == 'table' then
		local pins = Pins(self)
		for itemID, on in pairs(marked) do
			if on and not self:IsProtected(itemID) and pins[itemID] == nil then
				pins[itemID] = self.SELL_CATEGORY
			end
		end
	end
	self.config.autoVendorFilter = nil
	store.version = 1
	return true
end

------------------------------------------------------------------------ Show in

local function IsSetKey(key)
	return type(key) == 'string' and key:sub(1, 5) == 'Set: '
end

-- The old per-window flag of a key: Empty Slots, Currencies, a 'Set: ...' key,
-- or any key that isn't a list category.
local function Flags(self, windowId)
	local filters = self.config.filters
	local flags = type(filters) == 'table' and filters.categories
	return type(flags) == 'table' and flags[windowId] or nil
end

--[[
	Whether a window leaves a category out (its Show in is off):
	  - a list id: its hide[windowId];
	  - a 'Set: ...' key: the sets entry's hide[windowId], or its old flag;
	  - any other key (Empty Slots, Currencies): its flag in
	    filters.categories[windowId].
]]
function INV:IsCategoryHidden(windowId, key)
	local byId = self:GetCategoryList().byId
	local entry = byId[key]
	if entry then return entry.hide[windowId] and true or false end
	if IsSetKey(key) then
		local sets = byId[self.SETS_ENTRY]
		if sets and sets.hide[windowId] then return true end
	end
	local flags = Flags(self, windowId)
	return flags ~= nil and flags[key] and true or false
end

--[[
	Turns a category's Show in off (hidden) or on for a window. A list id is an
	edit like any other (a default's hide equal to the shipped one, none, is no
	edit; a copy is written, never the table an entry holds); every other key,
	'Set: ...' included, writes its flag in filters.categories[windowId], where
	the Edit view's checkbox of a set has always put it.
]]
function INV:SetCategoryHidden(windowId, key, hidden)
	if windowId == nil or key == nil then return false end
	hidden = hidden and true or false
	local entry = Entry(self, key)
	if entry then
		local hide = {}
		for window, off in pairs(entry.hide) do hide[window] = off end
		hide[windowId] = hidden or nil
		if next(hide) == nil and entry.default then hide = nil end
		if SetField(self, key, 'hide', hide) then self:CategoriesChanged() end
		return true
	end
	if type(self.config.filters) ~= 'table' then self.config.filters = {} end
	local filters = self.config.filters
	if type(filters.categories) ~= 'table' then filters.categories = {} end
	if type(filters.categories[windowId]) ~= 'table' then filters.categories[windowId] = {} end
	filters.categories[windowId][key] = hidden or nil
	return true
end
