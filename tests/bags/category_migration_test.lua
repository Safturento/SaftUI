-- Old profiles keep their categories (SaftUI-Bags/categories.lua's
-- INV:MigrateCategories, and Show in): a profile saved before the category
-- list sees exactly today's categories. Its hide flags become each category's
-- Show in, its Auto Vendor list becomes pins to Grays/Auto Vendor, and its
-- Protected list carries over. Show in hides a category in Compact and Rows,
-- stays with a renamed one, is what the Edit view's checkbox reads and writes,
-- and a profile switch, copy or reset (real AceDB) re-reads the categories,
-- edits and pins and migrates an old profile. Selling stays as guarded as
-- ever: a migrated mark never sells a Cosmetic item or an equipment-set item.
-- bags/bag_world.lua's bags under bags/container_helpers.lua's views world.
local H = load_test_file('bags/container_helpers.lua')

local INV, W

local SELL = 'Grays/Auto Vendor'

-- The backpack: a tonic, an axe, a plank, a rock, a gray cloth (quality 0), a
-- common bit (a Miscellaneous class) and a gray cosmetic. Every item sells
-- for 10 a unit. view is the bag window's view; setup runs before the window
-- is made, as a profile loaded before the bags are.
local function world(view, setup)
	INV, W = H.views_world('forever')
	load_saftui('SaftUI-Bags/autovendor.lua')
	W.bag(0, 30, 'Backpack')
	W.put(0, 1, W.item(101, 'Tonic', 'Consumable', 30))
	W.put(0, 2, W.item(201, 'Axe', 'Weapon', 70))
	W.put(0, 3, W.item(301, 'Plank', 'Trade Goods', 15))
	W.put(0, 4, W.item(150, 'Rock', 'Quest', 5))
	W.put(0, 5, W.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0 }))
	W.put(0, 6, W.item(503, 'Common Bit', 'Miscellaneous', 1, { quality = 1 }))
	INV.config.stackItems = false
	INV.config.bag.view = view or 'compact'
	INV.config.bag.emptySlots = 'off'
	if setup then setup() end
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

local function update() INV:UpdateContainer('bag', true) end

local function same(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for k, v in pairs(a) do if not same(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end

local global_eq = eq
local function eq(actual, expected, message)
	if type(actual) == 'table' and type(expected) == 'table' then
		return check(same(actual, expected), message .. ': tables differ')
	end
	return global_eq(actual, expected, message)
end

-- The names of the items a category frame shows, sorted.
local function shown(container, key)
	local frame = container.categories[key]
	local out = {}
	if frame and frame:IsShown() then
		for _, slot in ipairs(frame.slots) do
			if slot:IsShown() and slot.info and not slot.info.empty then out[#out + 1] = slot.info.name end
		end
	end
	table.sort(out)
	return table.concat(out, ',')
end

local function category_of(name)
	local bags = INV:ReadBags('bag', function() return 'bag' end)
	for _, bag in ipairs(bags) do
		for _, item in ipairs(bag.items) do
			if item.name == name then return item.category end
		end
	end
end

local function sold()
	local items = INV:GetVendorItems()
	local out = {}
	for _, info in ipairs(items) do out[#out + 1] = info.name end
	table.sort(out)
	return table.concat(out, ',')
end

-- What an old profile has, as the old version saved it: no categories key.
local function old(filters, autoVendor, protected)
	INV:EnsureConfigTables()
	INV.config.categories = nil
	INV.config.categoryPins = nil
	INV.config.filters.categories.bag = filters.bag or {}
	INV.config.filters.categories.bank = filters.bank or {}
	INV.config.filters.categories.warband = filters.warband or {}
	INV.config.filters.categories.combinedbank = filters.combinedbank or {}
	INV.config.autoVendorFilter = autoVendor
	INV.config.protectFilter = protected or {}
	INV:EnsureConfigTables()
end

-- What INV:OnEnable and INV:UpdateConfig() do: migrate, then drop the cache.
local function migrate()
	local ran = INV:MigrateCategories()
	INV:CategoriesChanged()
	return ran
end

local function ids()
	local out = {}
	for i, entry in ipairs(INV:GetCategoryList()) do out[i] = entry.id end
	return out
end

local function default_ids()
	local out = {}
	for i, def in ipairs(INV.CategoryDefaults.Build()) do out[i] = def.id end
	return out
end

local function count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

------------------------------------------------------------------ migration

test("an old profile sees today's categories in today's order", function()
	local c = world('compact', function()
		old({}, nil)
	end)
	eq(INV.config.categories.version, nil, 'not migrated yet')
	migrate()
	eq(INV.config.categories.version, 1, 'migrated')
	eq(ids(), default_ids(), 'the shipped list in the shipped order')
	eq(count(INV.config.categories.edits), 0, 'no edits')
	eq(count(INV.config.categories.custom), 0, 'none of its own')
	eq(count(INV.config.categories.deleted), 0, 'none deleted')
	eq(INV.config.categories.order, nil, 'no saved order')
	update()
	eq(category_of('Tonic'), 'Consumables', 'a consumable')
	eq(category_of('Axe'), 'Weapons', 'a weapon')
	eq(category_of('Plank'), 'Trade Goods', 'a trade good')
	eq(category_of('Gray Cloth'), SELL, 'a gray')
	eq(category_of('Common Bit'), 'Miscellaneous', 'the rest')
	eq(shown(c, 'Consumables'), 'Tonic', 'and in the frame')
	eq(#take_errors(), 0, 'no errors')
end)

test('hide flags become Show in, per window; Empty Slots, Currencies and Set: flags stay where they were', function()
	world('compact', function()
		old({
			bag = { Weapons = true, ['Empty Slots'] = true, Currencies = true, ['Set: Tank'] = true, Hidden = true },
			bank = { ['Trade Goods'] = true },
			warband = { Weapons = true, Miscellaneous = true },
			combinedbank = { Consumables = true, ['Equipment sets'] = true },
		}, nil)
	end)
	migrate()
	local byId = INV:GetCategoryList().byId
	eq(byId.Weapons.hide, { bag = true, warband = true }, 'Weapons: Bags and Warband bank off')
	eq(byId['Trade Goods'].hide, { bank = true }, 'Trade Goods: Bank off')
	eq(byId.Consumables.hide, { combinedbank = true }, 'Consumables: Combined bank off')
	eq(byId.Miscellaneous.hide, { warband = true }, 'Miscellaneous too')
	eq(byId['Equipment sets'].hide, { combinedbank = true }, 'and the sets entry')
	eq(byId.Armor.hide, {}, 'every other category shown everywhere')
	local flags = INV.config.filters.categories
	eq(flags.bag, { ['Empty Slots'] = true, Currencies = true, ['Set: Tank'] = true, Hidden = true },
		'the bag window keeps the flags that are not list categories')
	eq(flags.bank, {}, 'the list names are gone from the bank')
	eq(flags.warband, {}, 'and the warband bank')
	eq(flags.combinedbank, {}, 'and the combined bank')
	eq(INV:IsCategoryHidden('bag', 'Weapons'), true, 'Weapons hidden in Bags')
	eq(INV:IsCategoryHidden('bank', 'Weapons'), false, 'not in Bank')
	eq(INV:IsCategoryHidden('warband', 'Weapons'), true, 'hidden in Warband bank')
	eq(INV:IsCategoryHidden('bag', 'Empty Slots'), true, 'Empty Slots reads its flag')
	eq(INV:IsCategoryHidden('bag', 'Currencies'), true, 'so does Currencies')
	eq(INV:IsCategoryHidden('bag', 'Set: Tank'), true, 'and an old Set: flag')
	eq(INV:IsCategoryHidden('bag', 'Set: Heal'), false, 'another set is shown')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Auto Vendor list becomes pins to Grays/Auto Vendor; an item on both stays Protected and loses its pin; the list is gone', function()
	world('compact', function()
		old({}, { [101] = true, [503] = true, [999] = true }, { [503] = true })
	end)
	update()
	migrate()
	local pins = INV.config.categoryPins
	eq(pins[101], SELL, 'a marked item is pinned to Grays/Auto Vendor')
	eq(pins[999], SELL, 'so is one that is not in the bags')
	eq(pins[503], nil, 'an item on both lists loses its pin')
	eq(INV:IsProtected(503), true, 'and stays Protected')
	eq(INV.config.autoVendorFilter, nil, 'the list is gone')
	eq(INV:IsAutoVendorMarked(101), true, 'it reads as marked')
	update()
	eq(category_of('Tonic'), SELL, 'the marked tonic is in Grays/Auto Vendor')
	eq(sold(), 'Gray Cloth,Tonic', 'it sells, and the Protected common bit does not')
	eq(#take_errors(), 0, 'no errors')
end)

test('a migrated mark never sells a Cosmetic item or an equipment-set item, and Protected stays Protected', function()
	world('compact', function()
		W.put(0, 7, W.item(601, 'Fancy Hat', 'Armor', 1, { quality = 3 }))
		W.put(0, 8, W.item(602, 'Set Sword', 'Weapon', 40, { quality = 3, set = 'Tank' }))
		old({}, { [601] = true, [602] = true, [101] = true })
	end)
	migrate()
	update()
	eq(INV:GetPin(601), SELL, 'the cosmetic is pinned')
	eq(INV:GetPin(602), SELL, 'and the set item')
	-- The hat is Cosmetic (armor subclass 5): by ID.
	for _, bag in ipairs(INV:ReadBags('bag', function() return 'bag' end)) do
		for _, info in ipairs(bag.items) do
			if info.itemID == 601 then
				info.classID, info.subclassID = 4, 5
				eq(INV:IsAutoVendorItem(info, SELL), false, 'a Cosmetic item is not sold')
			elseif info.itemID == 602 then
				eq(INV:IsAutoVendorItem(info, SELL), false, 'an equipment-set item is not sold')
			elseif info.itemID == 101 then
				eq(INV:IsAutoVendorItem(info, SELL), true, 'the tonic is (the test means something)')
			end
		end
	end
	local names = sold()
	check(not names:find('Set Sword', 1, true), 'the set sword is not in the vendor list')
	check(names:find('Tonic', 1, true), 'the tonic is')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Protected list carries over unchanged', function()
	world('compact', function()
		old({}, nil, { [503] = true, [77] = true, [12] = true })
	end)
	local protected = INV.config.protectFilter
	migrate()
	check(INV.config.protectFilter == protected, 'the same table')
	eq(INV.config.protectFilter, { [503] = true, [77] = true, [12] = true }, 'the same items')
	eq(INV:IsProtected(77), true, 'protected')
	eq(INV:IsProtected(101), false, 'and the rest are not')
end)

test('the migration runs once', function()
	world('compact', function()
		old({ bag = { Weapons = true } }, { [101] = true })
	end)
	eq(migrate(), true, 'the first run migrates')
	eq(INV:IsCategoryHidden('bag', 'Weapons'), true, 'hidden')
	-- The user changes things, and an old key shows up again (a stale import).
	INV:SetCategoryHidden('bag', 'Weapons', false)
	INV:UnpinItem(101)
	INV.config.filters.categories.bag.Weapons = true
	INV.config.autoVendorFilter = { [101] = true }
	eq(migrate(), false, 'the second run does nothing')
	eq(INV:GetPin(101), nil, 'the unpinned item stays unpinned')
	eq(INV.config.autoVendorFilter, { [101] = true }, 'the list is not touched')
	eq(INV.config.filters.categories.bag.Weapons, true, 'nor the flag')
	eq(INV:GetCategoryList().byId.Weapons.hide, {}, 'Show in is as the user left it')
end)

------------------------------------------------------------------ Show in

test('Show in hides a category in Compact and Rows, not in One bag or Multi bag; a hidden category still catches its items', function()
	for _, view in ipairs({ 'compact', 'rows' }) do
		local c = world(view)
		INV:SetCategoryHidden('bag', 'Weapons', true)
		update()
		check(not (c.categories.Weapons and c.categories.Weapons:IsShown()), view .. ': Weapons hidden')
		eq(category_of('Axe'), 'Weapons', view .. ': the axe is still a weapon, not Miscellaneous')
		eq(shown(c, 'Miscellaneous'), 'Common Bit', view .. ': Miscellaneous holds only its own')
		eq(shown(c, 'Consumables'), 'Tonic', view .. ': the others are shown')
		for _, section in ipairs(INV:GetViewSections('bag', 'rows')) do
			if view == 'rows' then check(section.key ~= 'Weapons', 'no Weapons section in Rows') end
		end
		-- Show in is per window: the bank still shows Weapons.
		eq(INV:IsCategoryHidden('bank', 'Weapons'), false, view .. ': the bank shows it')
	end
	for _, view in ipairs({ 'onebag', 'multibag' }) do
		local c = world(view)
		INV:SetCategoryHidden('bag', 'Weapons', true)
		update()
		local names = {}
		for _, section in ipairs(INV:GetViewSections('bag', view)) do
			for _, info in ipairs(section.items) do names[#names + 1] = info.name end
		end
		check(table.concat(names, ','):find('Axe', 1, true), view .. ': still shows the axe')
	end
	INV:SetCategoryHidden('bag', 'Weapons', false)
	eq(INV:IsCategoryHidden('bag', 'Weapons'), false, 'shown again')
	eq(INV:CategoryStore().edits.Weapons, nil, 'and the edit is gone: Show in as shipped is no edit')
	eq(#take_errors(), 0, 'no errors')
end)

test('Show in on one of your categories is kept in it', function()
	world('compact')
	local id = INV:AddUserCategory()
	INV:SetCategoryHidden('bank', id, true)
	eq(INV:CategoryStore().custom[id].hide, { bank = true }, 'stored in the category')
	eq(INV:IsCategoryHidden('bank', id), true, 'hidden in the bank')
	eq(INV:IsCategoryHidden('bag', id), false, 'not in the bags')
	INV:SetCategoryHidden('bank', id, false)
	eq(INV:CategoryStore().custom[id].hide, {}, 'and cleared')
end)

test('renaming a category keeps its Show in', function()
	local c = world('compact')
	INV:SetCategoryHidden('bag', 'Weapons', true)
	INV:RenameCategory('Weapons', 'Blades')
	eq(INV:CategoryName('Weapons'), 'Blades', 'renamed')
	eq(INV:IsCategoryHidden('bag', 'Weapons'), true, 'still hidden in Bags')
	eq(INV:CategoryStore().edits.Weapons, { name = 'Blades', hide = { bag = true } }, 'name and Show in in one edit')
	update()
	check(not (c.categories.Weapons and c.categories.Weapons:IsShown()), 'and still hidden in the window')
	eq(#take_errors(), 0, 'no errors')
end)

test("the Edit view's checkbox reads and writes Show in", function()
	local c = world('compact', function()
		-- A profile with Weapons off in Bags, as the migration leaves one.
		INV:CategoryStore().edits.Weapons = { hide = { bag = true } }
		INV:CategoriesChanged()
	end)
	local box = c.categories.Weapons.filterCheckbox
	eq(box:GetChecked() and true or false, true, 'made checked: Weapons is off in Bags')
	eq(c.categories.Armor.filterCheckbox:GetChecked() and true or false, false, 'another one is not')
	-- The Edit button's loop reads Show in too.
	INV:SetCategoryHidden('bag', 'Armor', true)
	INV:ShowFilterCheckboxes(c, true)
	eq(c.categories.Armor.filterCheckbox:GetChecked() and true or false, true, 'the Edit button refreshes it from Show in')
	check(c.categories.Armor.filterCheckbox:IsShown(), 'and shows it')
	INV:ShowFilterCheckboxes(c, false)
	check(not c.categories.Armor.filterCheckbox:IsShown(), 'and hides it')
	-- A click writes Show in.
	local weapons = c.categories.Weapons.filterCheckbox
	weapons:SetChecked(false)
	stub.fire_script(weapons, 'OnClick')
	eq(INV:IsCategoryHidden('bag', 'Weapons'), false, 'unchecked: shown in Bags')
	eq(INV:CategoryStore().edits.Weapons, nil, 'the edit is gone')
	check(not INV.config.filters.categories.bag.Weapons, 'and no old flag was written')
	weapons:SetChecked(true)
	stub.fire_script(weapons, 'OnClick')
	eq(INV:CategoryStore().edits.Weapons, { hide = { bag = true } }, 'checked: off in Bags, as an edit')
	check(not INV.config.filters.categories.bag.Weapons, 'no old flag')
	-- A pseudo key keeps its flag.
	local currencies = c.categories['Empty Slots']
	if currencies and currencies.filterCheckbox then
		currencies.filterCheckbox:SetChecked(true)
		stub.fire_script(currencies.filterCheckbox, 'OnClick')
		eq(INV.config.filters.categories.bag['Empty Slots'], true, 'Empty Slots writes its flag')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("Equipment sets' Show in hides every Set: category; an old Set: flag still hides its set", function()
	local c = world('rows', function()
		W.put(0, 7, W.item(701, 'Tank Helm', 'Armor', 50, { quality = 3, set = 'Tank' }))
		W.put(0, 8, W.item(702, 'Heal Helm', 'Armor', 50, { quality = 3, set = 'Heal' }))
	end)
	local function sections()
		local out = {}
		for _, section in ipairs(INV:GetViewSections('bag', 'rows')) do out[#out + 1] = section.key end
		return table.concat(out, ',')
	end
	check(sections():find('Set: Tank', 1, true) and sections():find('Set: Heal', 1, true), 'both sets show (the test means something)')
	INV:SetCategoryHidden('bag', 'Equipment sets', true)
	eq(INV:IsCategoryHidden('bag', 'Set: Tank'), true, 'Tank hidden by the sets entry')
	eq(INV:IsCategoryHidden('bag', 'Set: Heal'), true, 'Heal too')
	eq(INV:IsCategoryHidden('bank', 'Set: Heal'), false, 'not in the bank')
	check(not sections():find('Set: ', 1, true), 'no set section in Rows')
	INV:SetCategoryHidden('bag', 'Equipment sets', false)
	-- An old per-set flag.
	INV.config.filters.categories.bag['Set: Tank'] = true
	eq(INV:IsCategoryHidden('bag', 'Set: Tank'), true, 'the old flag hides Tank')
	eq(INV:IsCategoryHidden('bag', 'Set: Heal'), false, 'and only Tank')
	check(not sections():find('Set: Tank', 1, true) and sections():find('Set: Heal', 1, true), 'Rows: Heal shows, Tank does not')
	-- Writing a set's flag (the Edit view's checkbox) keeps writing the old flag.
	INV:SetCategoryHidden('bag', 'Set: Heal', true)
	eq(INV.config.filters.categories.bag['Set: Heal'], true, 'a set flag is written where it was')
	INV:SetCategoryHidden('bag', 'Set: Heal', false)
	eq(INV.config.filters.categories.bag['Set: Heal'], nil, 'and cleared')
	eq(INV:CategoryStore().edits['Equipment sets'], nil, "the sets entry's Show in is untouched")
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------ profile changes

-- A real AceDB world over the bags: Core's real config.lua on AceDB-3.0 (as
-- tests/core/config_helpers.lua sets it up for the options tests), the bag
-- world's modules under it, and the profile the bags read the AceDB
-- database's. A profile switch, copy or reset runs Config:UpdateConfig, which
-- re-points every bound module and calls INV:UpdateConfig().
local function acedb_world(saved)
	local st
	INV, W = H.views_world('forever', function()
		SaftUI_DB = saved
		load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
		load_saftui('SaftUI-Core/Libraries/LibBase64-1.0/LibBase64-1.0.lua')
		load_saftui('SaftUI-Core/Libraries/LibCompress/LibCompress.lua')
		load_saftui('SaftUI-Core/Libraries/Ace3/AceSerializer-3.0/AceSerializer-3.0.lua')
		load_test_file('core/config_helpers.lua')
	end)
	st = SaftUI
	load_saftui('SaftUI-Bags/autovendor.lua')
	W.bag(0, 30, 'Backpack')
	W.put(0, 1, W.item(101, 'Tonic', 'Consumable', 30))
	W.put(0, 2, W.item(201, 'Axe', 'Weapon', 70))
	W.put(0, 3, W.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0 }))
	INV.config.stackItems = false
	INV.config.bag.emptySlots = 'off'
	local container = H.window('bag')
	INV:EnsureConfigTables()
	migrate()
	INV:UpdateContainer('bag', true)
	return st, container
end

-- A profile the old version saved: a hidden Weapons in Bags and a marked tonic.
local function old_profile()
	return { inventory = {
		filters = { categories = { bag = { Weapons = true }, bank = {} }, currencies = {} },
		autoVendorFilter = { [101] = true },
		protectFilter = { [201] = true },
	} }
end

test('a profile switch, copy and reset re-read the categories, edits and pins, and migrate an old profile', function()
	local st, c = acedb_world({ profiles = { Old = old_profile(), Old2 = old_profile() } })
	local first = st.config:GetCurrentProfile()
	eq(INV.config, st.config.profile.inventory, 'the bags read the database profile')
	-- The profile the player has: renamed, a pin, one hidden.
	INV:RenameCategory('Weapons', 'Blades')
	INV:PinItem(502, 'Trade Goods')
	INV:SetCategoryHidden('bag', 'Consumables', true)
	update()
	eq(category_of('Gray Cloth'), 'Trade Goods', 'the pin applies')
	eq(INV:CategoryName('Weapons'), 'Blades', 'and the name')
	take_errors()

	-- Switch to a profile saved before categories.
	st.config:SetProfile('Old')
	eq(INV.config, st.config.profile.inventory, 'the module reads the new profile')
	eq(INV.config.categories.version, 1, 'it was migrated on the switch')
	eq(INV.config.autoVendorFilter, nil, 'its Auto Vendor list is gone')
	eq(INV:GetPin(101), SELL, 'now a pin')
	eq(INV:GetPin(502), nil, "the other profile's pin is not read")
	eq(INV:CategoryName('Weapons'), 'Weapons', "the other profile's name is not read")
	eq(INV:IsCategoryHidden('bag', 'Weapons'), true, 'its hide flag is Show in')
	eq(INV:IsCategoryHidden('bag', 'Consumables'), false, "the other profile's Show in is not read")
	eq(INV:IsProtected(201), true, 'its Protected list is there')
	eq(INV:GetCategoryList().byId.Weapons.hide, { bag = true }, 'the list is the new profile, at once')
	eq(INV:GetItemCategory({ itemID = 101, name = 'Tonic', classID = 0, subclassID = 0, quality = 1 }), SELL,
		'an item the new profile pinned is there on the next read')
	eq(category_of('Tonic'), SELL, 'and in the bags')
	update()
	eq(shown(c, 'Consumables'), '', 'the tonic left Consumables')
	eq(shown(c, SELL), 'Gray Cloth,Tonic', 'for Grays/Auto Vendor')
	check(not (c.categories.Weapons and c.categories.Weapons:IsShown()), 'and Weapons is hidden by Show in')
	eq(#take_errors(), 0, 'no errors')

	-- Back: the first profile's own edits and pins are read again.
	st.config:SetProfile(first)
	eq(INV:CategoryName('Weapons'), 'Blades', "the first profile's rename is back")
	eq(INV:GetPin(502), 'Trade Goods', 'and its pin')
	eq(INV:GetPin(101), nil, "and the old profile's is gone")
	eq(INV:IsCategoryHidden('bag', 'Consumables'), true, 'and its Show in')
	eq(category_of('Gray Cloth'), 'Trade Goods', 'in the bags')
	eq(#take_errors(), 0, 'no errors')

	-- Copy a profile saved before categories into the current one.
	st.config:CopyProfile('Old2')
	eq(INV.config, st.config.profile.inventory, 'still the current profile')
	eq(INV.config.categories.version, 1, 'a copied old profile is migrated')
	eq(INV:GetPin(101), SELL, 'its Auto Vendor list is pins')
	eq(INV:GetPin(502), nil, "the copied-over profile's pin is gone")
	eq(INV:CategoryName('Weapons'), 'Weapons', 'and its rename')
	eq(INV:IsCategoryHidden('bag', 'Weapons'), true, "the copy's hide flag is Show in")
	eq(INV:IsProtected(201), true, 'and its Protected list')
	eq(category_of('Tonic'), SELL, 'in the bags')
	eq(#take_errors(), 0, 'no errors')

	-- Reset: the shipped categories, no edits, no pins.
	INV:RenameCategory('Armor', 'Mail')
	INV:PinItem(502, 'Trade Goods')
	st.config:ResetProfile()
	eq(INV.config, st.config.profile.inventory, 'the module reads the reset profile')
	eq(INV.config.categories.version, 1, 'a reset profile is migrated (nothing to do) so a later edit is not')
	eq(INV:CategoryName('Armor'), 'Armor', 'the rename is gone')
	eq(INV:GetPin(502), nil, 'the pin is gone')
	eq(INV:GetPin(101), nil, 'and the copied mark')
	eq(INV:IsCategoryHidden('bag', 'Weapons'), false, 'Show in is as shipped')
	eq(ids(), default_ids(), 'the shipped list')
	eq(category_of('Tonic'), 'Consumables', 'in the bags')
	eq(category_of('Gray Cloth'), SELL, 'a gray is a gray again')
	eq(#take_errors(), 0, 'no errors')
end)
