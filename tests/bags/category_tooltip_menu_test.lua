-- "Why is this here": the tooltip lines an item in SaftUI's bag windows gets
-- (INV:CategoryTooltipLines, INV:AddCategoryTooltipLines, INV:HookSlotTooltips)
-- and the Ctrl + right click slot menu (INV:SlotMenuEntries, INV:OpenSlotMenu):
-- Edit this category, Add to category..., Auto Vendor and Protected. Also
-- Util:ScanItemLink's guard against a tooltip that never arrived.
--
-- Real: bags/container_helpers.lua's views world (bag_world.lua's stubbed bags
-- under the module's real files, slot.lua among them), the options window and
-- SaftUI-Bags' options.lua, ruleeditor.lua and categoriestab.lua (for Edit this
-- category), and Core's tooltipscanner.lua. Made by hand, because the stubs
-- have no Blizzard menu or tooltip data processing: MenuUtil (it records the
-- generator's elements, which the test then clicks), TooltipDataProcessor (it
-- keeps the post-call), and ContainerFrameItemButton_OnEnter (it shows the
-- item on GameTooltip as Blizzard's does).
local H = load_test_file('bags/container_helpers.lua')

local st, INV, B, OW, R

local SELL, SETS, MISC = 'Grays/Auto Vendor', 'Equipment sets', 'Miscellaneous'

local function world()
	INV, B = H.views_world('forever', function() load_test_file('core/config_helpers.lua') end)
	st = SaftUI
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_saftui('SaftUI-Core/Config/optionswindow.lua')
	load_saftui('SaftUI-Bags/options.lua')
	load_saftui('SaftUI-Bags/ruleeditor.lua')
	load_saftui('SaftUI-Bags/categoriestab.lua')
	OW, R = st.OptionsWindow, INV.Rules
	INV.UpdateGold = function() end
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	_G.ContainerFrameItemButton_OnEnter = function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip:SetBagItem(self.info.bagID, self.info.slotID)
	end
	Enum.TooltipDataType = nil
	_G.TooltipDataProcessor = nil
	_G.MenuUtil = nil
	B.bag(0, 20, 'Backpack')
	B.put(0, 1, B.item(101, 'Tonic', 'Consumable', 30))
	B.put(0, 2, B.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0 }))
	B.put(0, 3, B.item(301, 'Plank', 'Trade Goods', 15))
	B.put(0, 5, B.item(503, 'Common Bit', 'Miscellaneous', 1))
	B.put(0, 6, B.item(601, 'Healing Mace', 'Weapon', 50, { set = 'Heal' }))
	INV.config.stackItems = false
	INV.config.bag.view = 'compact'
	INV.config.bag.emptySlots = 'off'
	local container = H.window('bag')
	H.search(container)
	INV:RegisterMovers()
	INV:UpdateContainer('bag', true)
	take_errors()
	return container
end

-- The slot showing an item, and its info.
local function slot_of(container, itemID)
	for _, category in pairs(container.categories) do
		for _, slot in pairs(category.slots) do
			if slot.info and slot.info.itemID == itemID then return slot end
		end
	end
	error('no slot for item ' .. itemID)
end

local function strip(text) return (text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')) end

local function plain(lines)
	local out = {}
	for i, line in ipairs(lines) do out[i] = strip(line.text) end
	return out
end

local function tooltip_texts()
	local state = stub.state(GameTooltip)
	local out = {}
	for i = 1, state.lines or 0 do out[i] = strip(state.texts[i]) end
	return out
end

local function ids_of(entries)
	local out = {}
	for i, entry in ipairs(entries) do out[i] = entry.text end
	return out
end

local function entry_named(entries, text)
	for _, entry in ipairs(entries) do
		if entry.text == text then return entry end
	end
	error('no entry ' .. text)
end

------------------------------------------------------------------ tooltip lines

test('tooltip lines: the category, its place and the block that caught it; a nested block names its groups', function()
	local container = world()
	-- Consumables catches the tonic by a block of its rule.
	local lines = INV:CategoryTooltipLines(slot_of(container, 101).info)
	eq(#lines, 2, 'two lines')
	local place = INV:CategoryPlace('Consumables')
	eq(plain(lines)[1], 'Category: Consumables (' .. INV.Ordinal(place) .. ')', 'the category and its place')
	local entry = INV:GetCategoryList().byId.Consumables
	local _, why = INV:GetItemCategory(slot_of(container, 101).info)
	eq(plain(lines)[2], 'Caught by: ' .. R.Describe(entry.rule, why.path), 'the block that caught it')
	local blue, grey, yellow = st.config.profile.colors.text.blue, st.config.profile.colors.text.grey,
		st.config.profile.colors.text.yellow
	local r, g, b = blue:GetRGB()
	check(lines[1].r == r and lines[1].g == g and lines[1].b == b, 'line 1 is blue')
	check(lines[1].text:find(('|cff%02x%02x%02x'):format(grey.r * 255 + 0.5, grey.g * 255 + 0.5, grey.b * 255 + 0.5), 1, true),
		'its place is grey')
	check(lines[2].text:find(('|cff%02x%02x%02x'):format(yellow.r * 255 + 0.5, yellow.g * 255 + 0.5, yellow.b * 255 + 0.5), 1, true),
		'"Caught by: " is yellow')

	-- A block inside groups names them.
	local id = INV:AddUserCategory()
	INV:SetCategoryRule(id, { op = 'or', items = {
		{ block = 'nameis', text = 'nothing' },
		{ op = 'and', items = { { block = 'name', text = 'plank' } } },
	} })
	INV:MoveCategory(id, 1)
	INV:UpdateContainer('bag', true)
	local info = slot_of(container, 301).info
	eq(info.category, id, 'the plank is in the new category, first in the list')
	lines = INV:CategoryTooltipLines(info)
	eq(plain(lines)[1], 'Category: New category (1st)', 'first place')
	local deciding = select(2, INV:GetItemCategory(info))
	eq(plain(lines)[2], 'Caught by: ' .. R.Describe(INV:GetCategoryList().byId[id].rule, deciding.path), 'the nested block')
	check(plain(lines)[2]:find('(in AND #2)', 1, true), 'names its group')
	eq(#take_errors(), 0, 'no errors')
end)

test('the place is written 1st, 2nd, 3rd, 4th, 11th to 13th, 21st, 22nd, 101st, 111th', function()
	world()
	local want = { [1] = '1st', [2] = '2nd', [3] = '3rd', [4] = '4th', [10] = '10th', [11] = '11th', [12] = '12th',
		[13] = '13th', [21] = '21st', [22] = '22nd', [23] = '23rd', [101] = '101st', [111] = '111th', [112] = '112th' }
	for n, text in pairs(want) do eq(INV.Ordinal(n), text, tostring(n)) end
end)

test('pinned, set and Miscellaneous items say so', function()
	local container = world()
	INV:PinItem(101, 'Quest')
	INV:UpdateContainer('bag', true)
	local lines = plain(INV:CategoryTooltipLines(slot_of(container, 101).info))
	eq(lines[1], 'Category: ' .. INV:CategoryName('Quest') .. ' (' .. INV.Ordinal(INV:CategoryPlace('Quest')) .. ')', 'pinned category')
	eq(lines[2], 'Caught by: pinned to this category', 'pinned')

	lines = plain(INV:CategoryTooltipLines(slot_of(container, 601).info))
	eq(lines[1], 'Category: Set: Heal (' .. INV.Ordinal(INV:CategoryPlace(SETS)) .. ')', "an equipment set is named by its set, in the sets entry's place")
	eq(lines[2], 'Caught by: an equipment set', 'set')

	lines = plain(INV:CategoryTooltipLines(slot_of(container, 503).info))
	eq(lines[1], 'Category: Miscellaneous (' .. INV.Ordinal(#INV:GetCategoryList()) .. ')', 'Miscellaneous is last')
	eq(lines[2], 'Caught by: no category above it', 'misc')
	eq(#take_errors(), 0, 'no errors')
end)

test('no lines for a free slot, an item still loading, or an info with no category', function()
	world()
	eq(#INV:CategoryTooltipLines({ empty = true, category = 'Consumables', categoryWhy = { kind = 'misc' } }), 0, 'free slot')
	eq(#INV:CategoryTooltipLines({ loading = true }), 0, 'loading')
	eq(#INV:CategoryTooltipLines({ itemID = 5 }), 0, 'no category')
	eq(#INV:CategoryTooltipLines(nil), 0, 'no info')
	eq(#take_errors(), 0, 'no errors')
end)

test('the post-call adds lines only to GameTooltip owned by a SaftUI slot', function()
	local container = world()
	local callbacks = {}
	Enum.TooltipDataType = { Item = 0 }
	_G.TooltipDataProcessor = {
		AddTooltipPostCall = function(kind, fn) callbacks[#callbacks + 1] = { kind = kind, fn = fn } end,
	}
	eq(INV:HookSlotTooltips(), true, 'hooked')
	INV:HookSlotTooltips()
	eq(#callbacks, 1, 'once, however often it is asked')
	eq(callbacks[1].kind, Enum.TooltipDataType.Item, 'for items')
	local post = callbacks[1].fn

	local slot = slot_of(container, 101)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(slot, 'ANCHOR_RIGHT')
	GameTooltip:SetText('Tonic')
	post(GameTooltip, {})
	eq(#tooltip_texts(), 3, 'two lines added under the first')
	eq(tooltip_texts()[2], plain(INV:CategoryTooltipLines(slot.info))[1], 'the category line')

	-- Owned by something else: nothing.
	local other = CreateFrame('Frame', nil, UIParent)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(other, 'ANCHOR_RIGHT')
	GameTooltip:SetText('Tonic')
	post(GameTooltip, {})
	eq(#tooltip_texts(), 1, "a frame that isn't a SaftUI slot")

	-- Another tooltip, even owned by a slot: nothing.
	local second = CreateFrame('GameTooltip', 'SaftUITestOtherTooltip', UIParent, 'GameTooltipTemplate')
	second:SetOwner(slot, 'ANCHOR_RIGHT')
	second:SetText('Tonic')
	post(second, {})
	eq(stub.state(second).lines, 1, 'a tooltip that is not GameTooltip')

	-- A free slot: nothing.
	local free = slot_of(container, 101)
	local was = free.info
	free.info = { empty = true, bagID = 0, slotID = 9 }
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(free, 'ANCHOR_RIGHT')
	GameTooltip:SetText('Empty bag slot')
	post(GameTooltip, {})
	eq(#tooltip_texts(), 1, 'a free slot')
	free.info = was
	eq(#take_errors(), 0, 'no errors')
end)

test('without TooltipDataProcessor nothing is hooked, and the slot adds the lines itself on hover', function()
	local container = world()
	eq(INV:HookSlotTooltips(), false, 'nothing to hook')
	local slot = slot_of(container, 101)
	slot.UpdateTooltip(slot)
	local texts = tooltip_texts()
	eq(#texts, 3, 'the item and the two lines')
	eq(texts[2], plain(INV:CategoryTooltipLines(slot.info))[1], 'the category line')

	-- With the post-call hooked, the slot leaves it to the post-call.
	Enum.TooltipDataType = { Item = 0 }
	_G.TooltipDataProcessor = { AddTooltipPostCall = function() end }
	eq(INV:HookSlotTooltips(), true, 'hooked')
	slot.UpdateTooltip(slot)
	eq(#tooltip_texts(), 1, 'no lines added by the slot')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the slot menu

test('the slot menu: Edit this category, Add to category... with every category that is on, in order, and the current pin checked, Auto Vendor and Protected', function()
	local container = world()
	local info = slot_of(container, 101).info
	local entries = INV:SlotMenuEntries(info)
	eq(table.concat(ids_of(entries), '|'), 'Edit this category|Add to category…|Auto Vendor|Protected', 'in order')
	eq(entries[1].kind, 'button', 'a button')
	eq(entries[2].kind, 'submenu', 'a submenu')
	eq(entries[3].kind, 'checkbox', 'a checkbox')
	eq(entries[4].kind, 'checkbox', 'a checkbox')

	local sub = entries[2].entries
	local want = { 'None (follow the rules)' }
	for _, entry in ipairs(INV:GetCategoryList()) do
		if entry.enabled and entry.kind ~= 'sets' then want[#want + 1] = entry.name end
	end
	eq(table.concat(ids_of(sub), '|'), table.concat(want, '|'), 'None, then every category that is on but Equipment sets')
	for _, entry in ipairs(sub) do eq(entry.kind, 'radio', entry.text .. ' is a radio') end
	check(not table.concat(ids_of(sub), '|'):find(SETS, 1, true), 'no Equipment sets')
	eq(sub[1].checked(), true, 'None is checked for an item with no pin')

	-- A category turned off is left out; the pin is checked.
	INV:SetCategoryEnabled('Weapons', false)
	INV:PinItem(101, 'Quest')
	sub = INV:SlotMenuEntries(info)[2].entries
	check(not table.concat(ids_of(sub), '|'):find('Weapons', 1, true), 'Weapons is off, so not offered')
	eq(entry_named(sub, INV:CategoryName('Quest')).checked(), true, 'the pinned category is checked')
	eq(sub[1].checked(), false, 'None is not')
	eq(entry_named(sub, 'Consumables').checked(), false, 'another is not')
	eq(#take_errors(), 0, 'no errors')
end)

test('Add to category... pins, moves and unpins; Auto Vendor and Protected clear each other', function()
	local container = world()
	local info = slot_of(container, 101).info
	local function entries() return INV:SlotMenuEntries(info) end
	local function sub(text) return entry_named(entries()[2].entries, text) end

	sub('Quest').onClick()
	eq(INV:GetPin(101), 'Quest', 'pinned')
	sub('Trade Goods').onClick()
	eq(INV:GetPin(101), 'Trade Goods', 'moved')
	sub('None (follow the rules)').onClick()
	eq(INV:GetPin(101), nil, 'unpinned')

	local function box(text) return entry_named(entries(), text) end
	box('Auto Vendor').onClick()
	eq(INV:GetPin(101), SELL, 'Auto Vendor pins it to Grays/Auto Vendor')
	eq(box('Auto Vendor').checked(), true, 'checked')
	box('Protected').onClick()
	eq(INV:IsProtected(101), true, 'Protected')
	eq(box('Auto Vendor').checked(), false, 'Auto Vendor is cleared')
	eq(INV:GetPin(101), nil, 'with its pin')
	box('Auto Vendor').onClick()
	eq(box('Auto Vendor').checked(), true, 'Auto Vendor again')
	eq(box('Protected').checked(), false, 'Protected is cleared')
	box('Auto Vendor').onClick()
	eq(INV:GetPin(101), nil, 'unchecked, unpinned')
	eq(#take_errors(), 0, 'no errors')
end)

test("Edit this category opens the tab at the item's category", function()
	local container = world()
	local entries = INV:SlotMenuEntries(slot_of(container, 101).info)
	entries[1].onClick()
	check(OW:IsShown(), '/sui opens')
	eq(OW:GetState().page, 'Inventory', 'on Bags')
	eq(OW:GetState().tab, 'categories', 'on the Categories tab')
	eq(INV.categoryEditor.selected, 'Consumables', "with the item's category selected")
	st.Config:Close()
	-- An item in an equipment set selects the sets entry.
	INV:SlotMenuEntries(slot_of(container, 601).info)[1].onClick()
	eq(INV.categoryEditor.selected, SETS, 'a set item selects the sets entry')
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

-- A Blizzard menu's root description, as far as the slot menu uses it: it
-- records what the generator makes, and a submenu's own elements.
local function menu_stand_in()
	local opened = {}
	local function description(list)
		local d = {}
		local function add(kind, text, a, b)
			local child = { kind = kind, text = text, elements = {} }
			if kind == 'button' then child.onClick = a else child.checked, child.onClick = a, b end
			list[#list + 1] = child
			return description(child.elements), child
		end
		function d:CreateButton(text, callback) local sub, child = add('button', text, callback); return sub, child end
		function d:CreateCheckbox(text, isSelected, setSelected) local sub = add('checkbox', text, isSelected, setSelected); return sub end
		function d:CreateRadio(text, isSelected, setSelected) local sub = add('radio', text, isSelected, setSelected); return sub end
		return d
	end
	_G.MenuUtil = {
		CreateContextMenu = function(owner, generator)
			local root = { owner = owner, list = {} }
			generator(owner, description(root.list))
			opened[#opened + 1] = root
		end,
	}
	return opened
end

test('the slot menu opens with Blizzard\'s MenuUtil on Ctrl + right click, and a free slot opens nothing', function()
	local container = world()
	local opened = menu_stand_in()
	local slot = slot_of(container, 101)

	stub.fire_script(slot, 'OnClick', 'RightButton')
	eq(#opened, 0, 'a plain right click opens nothing')
	stub.ctrl_down = true
	stub.fire_script(slot, 'OnClick', 'LeftButton')
	eq(#opened, 0, 'a Ctrl + left click opens nothing')
	stub.fire_script(slot, 'OnClick', 'RightButton')
	stub.ctrl_down = false
	eq(#opened, 1, 'Ctrl + right click opens it')
	eq(opened[1].owner, slot, 'at the slot')
	local texts = {}
	for i, e in ipairs(opened[1].list) do texts[i] = e.text end
	eq(table.concat(texts, '|'), 'Edit this category|Add to category…|Auto Vendor|Protected', 'with the four entries')
	local submenu = opened[1].list[2]
	eq(submenu.elements[1].text, 'None (follow the rules)', 'None first in the submenu')
	eq(submenu.elements[1].kind, 'radio', 'a radio')
	eq(opened[1].list[3].kind, 'checkbox', 'Auto Vendor is a checkbox')

	-- The elements do what the entries do.
	for _, e in ipairs(submenu.elements) do
		if e.text == 'Quest' then e.onClick() end
	end
	eq(INV:GetPin(101), 'Quest', 'a radio pins')
	opened[1].list[3].onClick()
	eq(INV:GetPin(101), SELL, 'Auto Vendor marks')
	eq(opened[1].list[3].checked(), true, 'and reads checked')

	local free = { info = { empty = true, bagID = 0, slotID = 9 } }
	INV:OpenSlotMenu(free)
	eq(#opened, 1, 'a free slot opens nothing')
	eq(#take_errors(), 0, 'no errors')
end)

test('without MenuUtil the slot menu does nothing and does not error', function()
	local container = world()
	local slot = slot_of(container, 101)
	stub.ctrl_down = true
	stub.fire_script(slot, 'OnClick', 'RightButton')
	stub.ctrl_down = false
	eq(#take_errors(), 0, 'no errors')
end)

test('pinning from the menu in combat, to a category made since login, makes no frame or slot', function()
	local container = world()
	local late = INV:AddUserCategory()
	local slot = slot_of(container, 101)
	local entries = INV:SlotMenuEntries(slot.info)
	stub.in_combat = true
	local made = H.frames_made()
	entry_named(entries[2].entries, INV:CategoryName(late)).onClick()
	INV:UpdateContainer('bag', true)
	eq(H.frames_made(), made, 'no frame or slot made in combat')
	eq(INV:GetPin(101), late, 'pinned')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	INV:UpdateContainer('bag', true)
	eq(slot_of(container, 101).info.category, late, 'the item shows there on the next update')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the scanner

test('Util:ScanItemLink survives a tooltip that never arrived, and does not cache it', function()
	world()
	local Util = st:GetModule('Utilities')
	local reply
	_G.C_TooltipInfo = { GetHyperlink = function() return reply end }
	Util.TooltipCache = {}
	reply = nil
	eq(Util:ScanItemLink('item:1'), '', 'no data')
	reply = {}
	eq(Util:ScanItemLink('item:1'), '', 'data with no lines')
	reply = { lines = { { leftText = 'Hello', rightText = 'World' } } }
	eq(Util:ScanItemLink('item:1'), ' Hello World', 'the text once it arrives (nothing was cached)')
	_G.C_TooltipInfo = nil
	eq(#take_errors(), 0, 'no errors')
end)
