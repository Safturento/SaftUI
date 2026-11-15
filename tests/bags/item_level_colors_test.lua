-- An item slot's item level and its reagent marker take the state colors: plain
-- gear's item level Text > Strong, Bind on Equip Success, Warbound Shared, and
-- the reagent wedge Success; and a changed color reaches the next update.
-- Every case runs with those three set to values that are not their defaults,
-- so a reader that drew a color of its own fails.
--
-- Real: container_helpers.lua's views world (the same as junkcoin_test.lua).
local H = load_test_file('bags/container_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')

local INV, W

local STRONG, SUCCESS, SHARED = { 0.2, 0.7, 0.6 }, { 0.1, 0.8, 0.3 }, { 0.4, 0.2, 0.9 }

local function world()
	INV, W = H.views_world('forever')
	local colors = SaftUI.config.profile.colors.text
	colors.strong:SetRGB(unpack(STRONG)); colors.success:SetRGB(unpack(SUCCESS)); colors.shared:SetRGB(unpack(SHARED))
	W.bag(0, 20, 'Backpack')
	W.put(0, 1, W.item(601, 'Plain Helm', 'Armor', 50))
	W.put(0, 2, W.item(602, 'Boe Helm', 'Armor', 51, { bindType = Enum.ItemBind.OnEquip }))
	W.put(0, 3, W.item(603, 'Warband Helm', 'Armor', 52, { accountUntilEquip = true }))
	INV.config.bag.view = 'compact'
	INV.config.bag.emptySlots = 'off'
	INV.config.stackItems = false
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

local function slot_of(container, name)
	for _, category in pairs(container.categories) do
		for _, slot in ipairs(category.slots) do
			if slot:IsShown() and slot.info and slot.info.name == name then return slot, category end
		end
	end
end

local function ink(slot) return T.rgb(slot.itemLevel:GetTextColor()) end

test('item levels: gear is Text > Strong, Bind on Equip Success, Warbound Shared, at odd values', function()
	local c = world()
	local plain, boe, warband = slot_of(c, 'Plain Helm'), slot_of(c, 'Boe Helm'), slot_of(c, 'Warband Helm')
	check(plain and boe and warband, 'each has a slot')
	if not (plain and boe and warband) then return end
	eq(ink(plain), T.rgb(unpack(STRONG)), 'plain gear: Strong')
	eq(ink(boe), T.rgb(unpack(SUCCESS)), 'Bind on Equip: Success')
	eq(ink(warband), T.rgb(unpack(SHARED)), 'Warbound: Shared')
	eq(#take_errors(), 0, 'no errors')
end)

test('a changed color is the next update: the slot takes it when it is assigned again', function()
	local c = world()
	SaftUI.config.profile.colors.text.strong:SetRGB(0.9, 0.1, 0.2)
	SaftUI:ColorChanged('text', 'strong')
	eq(ink(slot_of(c, 'Plain Helm')), T.rgb(0.9, 0.1, 0.2), 'at once, with no update')
	eq(ink(slot_of(c, 'Boe Helm')), T.rgb(unpack(SUCCESS)), 'Strong does not reach a Bind on Equip item level')
	SaftUI.config.profile.colors.text.strong:SetRGB(0.8, 0.2, 0.3)
	INV:UpdateContainer('bag', true)
	eq(ink(slot_of(c, 'Plain Helm')), T.rgb(0.8, 0.2, 0.3), 'Strong changed')
end)

test('the reagent wedge is Text > Success, at an odd value, when the slot is made and when it is styled again', function()
	local c = world()
	local slot, category = slot_of(c, 'Plain Helm')
	check(slot and slot.reagentMarker, 'a slot with its wedge')
	if not slot then return end
	eq(T.rgb(slot.reagentMarker:GetVertexColor()), T.rgb(unpack(SUCCESS)), 'as it was made')
	SaftUI.config.profile.colors.text.success:SetRGB(0.9, 0.5, 0.1)
	INV:StyleSlot(slot, category, c)
	eq(T.rgb(slot.reagentMarker:GetVertexColor()), T.rgb(0.9, 0.5, 0.1), 'after a style again')
	SaftUI.config.profile.colors.text.success:SetRGB(0.3, 0.6, 0.2)
	SaftUI:ColorChanged('text', 'success')
	eq(T.rgb(slot.reagentMarker:GetVertexColor()), T.rgb(0.3, 0.6, 0.2), 'and at once when the color changes')
end)
