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
	  INV:CategoriesChanged()    drops the list and the compiled rules, and updates
	  INV:GetItemCategory(info)  -> key, why
	  INV:IsAutoVendorItem(info, key)
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
	self:QueueUpdate(true)
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

-- Never sold, whatever an item's pin or category says.
local NEVER_SOLD_TEXT = { 'fishing', 'blizzard account bound' }

--[[
	Whether auto vendor sells an item: it is in the category that sells
	(Grays/Auto Vendor), turned on, has a vendor price, and isn't protected.
	Whatever its pin or that category's rule says, an item is never sold when
	it is in an equipment set, Cosmetic, or its tooltip says "Fishing" or
	"Blizzard Account Bound" (selling can't be undone). The slot's junk coin and
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
	if IC.SubclassName(info.classID, info.subclassID) == 'Cosmetic' then return false end
	local tooltip = info.tooltipStripped
	if type(tooltip) == 'string' then
		for _, text in ipairs(NEVER_SOLD_TEXT) do
			if strfind(tooltip, text, 1, true) then return false end
		end
	end
	if EquipmentSet(info) then return false end
	return true
end
