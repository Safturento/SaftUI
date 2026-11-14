-- How wide the section views (One bag, Multi bag and Rows) make a window
-- (layout.lua's INV:LayoutSections and INV:SectionLineSlots): as many slots
-- as the widest section shows, from perrow (one Compact column) up to
-- perrow * maxColumns, held while the window is open (it widens at once, and
-- narrows again only after a close or a view switch), Compact unchanged, and
-- every frame and slot on whole pixels. The same world as
-- views_layout_test.lua.
local H = load_test_file('bags/container_helpers.lua')
local P = load_test_file('lib/pixels.lua')

local INV, W
local bw, bh, sp, padding

-- The bag window in view, perrow 4 and maxColumns 3 (a line of at most 12),
-- laid out with the bag's items given by counts: how many items of each class
-- go in the backpack, one section (Rows) per class. Free slots aren't shown.
local CLASSES = { Consumable = 'Consumable', Weapon = 'Weapon', ['Trade Goods'] = 'Trade Goods', Armor = 'Armor' }
local function fill(counts)
	for slot = 1, 40 do W.bags[0].items[slot] = nil end
	local slot, id = 0, 500
	for _, class in ipairs({ 'Consumable', 'Weapon', 'Trade Goods', 'Armor' }) do
		for i = 1, counts[class] or 0 do
			slot, id = slot + 1, id + 1
			W.put(0, slot, W.item(id, class .. ' ' .. i, CLASSES[class], 100 - i))
		end
	end
end

local function world(view, counts, setup)
	INV, W = H.views_world('forever')
	bw, bh, sp = INV:GetButtonWidth(), INV:GetButtonHeight(), INV.config.buttonspacing
	padding = INV.config.padding
	W.bag(0, 40, 'Backpack')
	fill(counts)
	INV.config.stackItems = false
	INV.config.bag.view = view
	INV.config.bag.emptySlots = 'off'
	INV.config.bag.perrow = 4
	INV.config.bag.maxColumns = 3
	if setup then setup() end
	local container = H.window('bag')
	INV:UpdateContainer('bag', true)
	return container
end

local function line(n) return n * (bw + sp) - sp end

-- The window as wide as n slots and the padding (or its header, if that is wider).
local function window_width(c, n)
	return math.max(line(n) + padding * 2, INV:HeaderMinWidth(c))
end

local function update(c)
	INV:UpdateContainer('bag', true)
end

local function switch(view)
	INV.config.bag.view = view
	INV:ApplyView('bag')
end

local SPARSE = { Consumable = 3, Weapon = 2, ['Trade Goods'] = 2, Armor = 5 }

test('rows: sections of 3, 2, 2 and 5 items make a line of 5 slots', function()
	local c = world('rows', SPARSE)
	eq(INV:LineSlots('bag', 'rows'), 12, 'the most a line holds is perrow * maxColumns')
	for _, name in ipairs({ 'Consumables', 'Weapons', 'Trade Goods', 'Armor' }) do
		local frame = c.categories[name]
		check(frame:IsShown(), name .. ' shown')
		eq(frame:GetWidth(), line(5), name .. ': a frame of the line, five slots')
	end
	eq(c.scrollFrame:GetWidth(), line(5), 'the scroll frame is the line')
	eq(c:GetWidth(), window_width(c, 5), 'and the window the line and its padding')
	local armor = c.categories.Armor
	eq(armor.slots[5]:GetTop(), armor.slots[1]:GetTop(), 'the fifth armor is on the first line')
	eq(armor.slots[5]:GetRight(), armor:GetRight(), 'at the right edge of the line')
	eq(armor.numRows, 1, 'five armors, one line')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: a section of 30 items caps the line at perrow * maxColumns', function()
	local c = world('rows', { Consumable = 30, Weapon = 2 })
	eq(c.categories.Weapons:GetWidth(), line(12), 'a line of twelve')
	eq(c.categories.Consumables:GetWidth(), line(12), 'for every section')
	eq(c.categories.Consumables.numRows, 3, 'thirty consumables wrap at twelve: three lines')
	eq(c:GetWidth(), window_width(c, 12), 'the window')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: one item is a line of perrow, the floor', function()
	local c = world('rows', { Weapon = 1 })
	eq(c.categories.Weapons:GetWidth(), line(4), 'one Compact column wide')
	eq(c:GetWidth(), window_width(c, 4), 'the window is as wide as one column')
	local none = world('rows', {})
	eq(none:GetWidth(), window_width(none, 4), 'no items: the same')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: Compact is as wide as it was, by its columns', function()
	local c = world('compact', SPARSE)
	eq(INV:LineSlots('bag', 'compact'), 4, "Compact's line is perrow")
	local used = 0
	for _, column in ipairs(c.columns) do if #column.categories > 0 then used = used + 1 end end
	eq(c.scrollFrame:GetWidth(), used * (c.columns[1]:GetWidth() + sp) - sp, 'only the columns in use')
	eq(#take_errors(), 0, 'no errors')
end)

test('the window holds its width while open, widens at once, and releases it on a switch or a close', function()
	local c = world('rows', { Consumable = 9, Weapon = 2 })
	eq(c.categories.Weapons:GetWidth(), line(9), 'nine consumables: a line of nine')
	local width = c:GetWidth()

	-- Items leave while open: the window keeps its width, the items close up.
	for slot = 1, 8 do W.bags[0].items[slot] = nil end
	update(c)
	eq(c.categories.Consumables:GetWidth(), line(9), 'the frames keep the line')
	eq(c.scrollFrame:GetWidth(), line(9), 'the scroll frame too')
	eq(c:GetWidth(), width, 'the window did not narrow')
	eq(c.categories.Weapons.slots[2]:GetTop(), c.categories.Weapons.slots[1]:GetTop(), 'the items stay on their line')

	-- A section that needs more widens it at once.
	for i = 1, 11 do W.put(0, 20 + i, W.item(700 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
	update(c)
	eq(c.categories['Trade Goods']:GetWidth(), line(11), 'eleven trade goods: a line of eleven')
	eq(c.categories.Weapons:GetWidth(), line(11), 'every section')
	eq(c:GetWidth(), window_width(c, 11), 'the window')

	-- They go again: held at eleven.
	for i = 1, 11 do W.bags[0].items[20 + i] = nil end
	update(c)
	eq(c:GetWidth(), window_width(c, 11), 'held')

	-- Closed and opened again (OnHide releases the layout): afresh.
	c:Hide()
	INV:ReleaseLayout(c)
	c:Show()
	update(c)
	eq(c.scrollFrame:GetWidth(), line(4), 'reopened, as narrow as the items need: the floor')
	eq(c.categories.Weapons:GetWidth(), line(4), 'and the frames')

	-- A view switch releases it too.
	for i = 1, 11 do W.put(0, 20 + i, W.item(700 + i, 'Bolt ' .. i, 'Trade Goods', 10)) end
	update(c)
	eq(c.scrollFrame:GetWidth(), line(11), 'wide again')
	for i = 1, 11 do W.bags[0].items[20 + i] = nil end
	switch('compact')
	switch('rows')
	eq(c.scrollFrame:GetWidth(), line(4), 'after a switch away and back, released')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows: slots follow the line when it changes', function()
	local c = world('rows', { Weapon = 5 })
	local weapons = c.categories.Weapons
	eq(weapons.slots[5]:GetTop(), weapons.slots[1]:GetTop(), 'five weapons on one line of five')
	for i = 1, 8 do W.put(0, 10 + i, W.item(800 + i, 'Cuirass ' .. i, 'Armor', 10)) end
	update(c)
	eq(weapons:GetWidth(), line(8), 'a line of eight')
	eq(weapons.slots[8]:GetTop(), weapons.slots[1]:GetTop(), 'a slot made in the pool sits on the first line at eight')
	eq(c.categories.Armor.slots[8]:GetTop(), c.categories.Armor.slots[1]:GetTop(), 'eight armors, one line')
	for i = 1, 20 do W.put(0, 20 + i, W.item(900 + i, 'Plate ' .. i, 'Armor', 10)) end
	update(c)
	eq(weapons:GetWidth(), line(12), 'capped at twelve')
	eq(c.categories.Armor.slots[13]:GetTop(), c.categories.Armor.slots[1]:GetBottom() - sp, 'the thirteenth armor starts the second line')
	eq(c.categories.Armor.slots[13]:GetLeft(), c.categories.Armor.slots[1]:GetLeft(), 'at the left')
	eq(#take_errors(), 0, 'no errors')
end)

test('multi bag: the line is the widest bag, one bag section each', function()
	local c = world('multibag', { Consumable = 7 }, function()
		W.bag(1, 16, 'Bag')
		W.put(1, 1, W.item(201, 'Axe', 'Weapon', 70))
		W.put(1, 2, W.item(202, 'Sword', 'Weapon', 50))
	end)
	eq(c.categories['view:bag0']:GetWidth(), line(7), 'the backpack holds seven: a line of seven')
	eq(c.categories['view:bag1']:GetWidth(), line(7), 'the bag with two is as wide')
	eq(c:GetWidth(), window_width(c, 7), 'the window')
	eq(#take_errors(), 0, 'no errors')
end)

test('one bag: the main grid sets the line, and every slot shown fills the full width', function()
	local c = world('onebag', { Consumable = 6 })
	eq(c.categories['view:main']:GetWidth(), line(6), 'six items: a line of six')
	eq(c:GetWidth(), window_width(c, 6), 'the window')

	local full = world('onebag', { Consumable = 6 }, function() INV.config.bag.emptySlots = 'all' end)
	local main = full.categories['view:main']
	eq(main:GetWidth(), line(12), 'a grid of every slot (forty) needs the full width')
	eq(full:GetWidth(), window_width(full, 12), 'the window is as wide as it was')
	eq(#take_errors(), 0, 'no errors')
end)

test('rows with Grouped empty slots: the Empty Slots section counts its buttons, not its free slots', function()
	local c = world('rows', { Weapon = 2 }, function() INV.config.bag.emptySlots = 'grouped' end)
	local empties = c.categories['Empty Slots']
	check(empties and empties:IsShown(), 'the Empty Slots section shows')
	eq(empties:GetWidth(), line(4), 'one grouped button: the floor')
	eq(#take_errors(), 0, 'no errors')
end)

test('the sections and slots sit on whole pixels, and the window is a whole width, at a narrow width', function()
	for _, view in ipairs({ 'rows', 'onebag', 'multibag' }) do
		local c = world(view, SPARSE)
		eq(P.report(P.off(c.scrollFrame.ScrollChild)), P.report({}), view .. ': every section and slot on a whole pixel')
		eq(c:GetWidth() % 1, 0, view .. ': a whole width')
	end
	eq(#take_errors(), 0, 'no errors')
end)
