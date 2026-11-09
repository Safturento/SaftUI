-- The held category layout of SaftUI-Bags/container.lua (INV:UpdateContainerLayout
-- with INV:HoldLayout / PlaceHeldCategories / ReleaseLayout): while a window
-- is open its categories keep their columns and order. Migrated from the
-- bagsim harness. bags/container_helpers.lua loads the real files.
local H = load_test_file('bags/container_helpers.lua')
H.fresh()
local INV = H.INV
local cat, where, same, layout, set_rows = H.cat, H.where, H.same, H.layout, H.set_rows

local c, opened, openW, openH

test('first layout packs afresh and holds it', function()
	c = H.container({ cat('Consumable', 1), cat('Trade Goods', 4), cat('Armor', 2), cat('Junk', 3), cat('Quest', 1) })
	layout(c)
	check(c.heldLayout ~= nil, 'held after the first layout')
	opened = where(c)
	openW, openH = c.scrollFrame:GetWidth(), c.scrollFrame:GetHeight()
end)

test('selling changes heights, and the held layout keeps every category in place', function()
	set_rows(c.categories['Trade Goods'], 1)
	set_rows(c.categories['Junk'], 1)
	local fresh = H.container({ cat('Consumable', 1), cat('Trade Goods', 1), cat('Armor', 2), cat('Junk', 1), cat('Quest', 1) })
	layout(fresh)
	layout(c)
	check(not same(where(fresh), opened), 'a fresh pack would rearrange (the test means something)')
	check(same(where(c), opened), 'held: every category in its column and place')
	check(c.scrollFrame:GetHeight() == openH and c.scrollFrame:GetWidth() == openW,
		'window keeps its size, ' .. c.scrollFrame:GetHeight() .. ' vs ' .. openH)
end)

test('a category that sells out is skipped and the rest keep their columns', function()
	c.categories['Junk']:Hide()
	layout(c)
	local now = where(c)
	check(now['Junk'] == nil, 'sold-out category gone')
	local moved = false
	for k, v in pairs(now) do if opened[k]:sub(1, 1) ~= v:sub(1, 1) then moved = true end end
	check(not moved, 'no category changed column')
	check(c.scrollFrame:GetWidth() == openW, 'width kept')
end)

test('it fills again and is back in its place', function()
	c.categories['Junk']:Show()
	layout(c)
	check(where(c)['Junk'] == opened['Junk'], 'refilled category back in place')
end)

local hw

test('a new category goes to the bottom of the shortest column, then is held there', function()
	local herb = cat('Herbs', 1)
	herb:SetParent(c)
	c.categories['Herbs'] = herb
	layout(c)
	hw = where(c)['Herbs']
	local shortestBefore = hw and tonumber(hw:sub(1, 1))
	check(hw ~= nil and tonumber(hw:sub(3)) == #c.columns[shortestBefore].categories, 'new category at the bottom of a column')
	for k, v in pairs(opened) do check(where(c)[k] == v, 'new category moved nothing: ' .. k) end
	set_rows(c.categories['Consumable'], 9)
	layout(c)
	check(where(c)['Herbs'] == hw, 'new category held in its column')
end)

test('the window grows when it has to and does not shrink back while open', function()
	check(c.scrollFrame:GetHeight() >= openH, 'height never below the opened size')
	local grown = c.scrollFrame:GetHeight()
	set_rows(c.categories['Consumable'], 1)
	layout(c)
	check(c.scrollFrame:GetHeight() == grown, 'and does not shrink back while open')
end)

test('closing releases, and the next layout packs afresh', function()
	-- distinct heights: ties pack in table order
	for i, name in ipairs({ 'Armor', 'Consumable', 'Junk', 'Quest', 'Trade Goods', 'Herbs' }) do set_rows(c.categories[name], i + 1) end
	INV:ReleaseLayout(c)
	layout(c)
	check(c.heldLayout ~= nil, 'held again after re-opening')
	local repacked = H.container({}) -- compare with a fresh pack of the same categories
	for name, category in pairs(c.categories) do
		if category:IsShown() then
			local copy = cat(name, category.numRows)
			copy:SetHeight(category:GetHeight())
			copy:SetParent(repacked)
			repacked.categories[name] = copy
		end
	end
	layout(repacked)
	check(same(where(c), where(repacked)), 'reopened window is packed afresh')
end)

test('items still loading are packed afresh each time, and held once loaded', function()
	local l = H.container({ cat('A', 1), cat('B', 3), cat('C', 2) })
	l.loadingItems = true
	layout(l)
	check(l.heldLayout == nil, 'not held while items load')
	l.loadingItems = false
	layout(l)
	check(l.heldLayout ~= nil, 'held once loaded')
end)

test('a category hidden in the Edit view is hidden outside it, held or not', function()
	local f = H.container({ cat('A', 1), cat('B', 3), cat('Hidden', 2) })
	INV.config.filters.categories.bag.Hidden = true
	layout(f)
	check(not f.categories.Hidden:IsShown() and where(f).Hidden == nil, 'filtered category hidden on a fresh pack')
	f.categories.Hidden:Show()
	layout(f)
	check(not f.categories.Hidden:IsShown(), 'and on a held layout')
	INV.config.filters.categories.bag.Hidden = nil
end)

test('a column in the middle empties and later columns still count toward the width', function()
	local m = H.container({ cat('A', 5), cat('B', 1), cat('C', 1), cat('D', 1) })
	layout(m)
	local w0 = m.scrollFrame:GetWidth()
	for _, col in ipairs(m.columns) do
		if #col.categories > 0 and col ~= m.columns[#m.columns] then
			for _, category in ipairs(col.categories) do category:Hide() end
			break
		end
	end
	layout(m)
	check(m.scrollFrame:GetWidth() == w0, 'width kept when a middle column empties, ' .. tostring(m.scrollFrame:GetWidth()) .. ' vs ' .. w0)
end)
