-- How SaftUI-Bags/container.lua packs categories into columns
-- (INV:CompactCategories and packColumns, through INV:UpdateContainerLayout):
-- the shortest window the columns allow, the order inside a column, a stable
-- arrangement, and the time it takes. Migrated from the bagsim harness.
-- bags/container_helpers.lua loads the real files.
local H = load_test_file('bags/container_helpers.lua')
H.fresh()
local INV = H.INV
local cat, where, same, layout = H.cat, H.where, H.same, H.layout
local max, min = math.max, math.min

local spacing = INV.config.buttonspacing
local function height_of(rows) return rows * H.row() + INV.config.categoryTitleHeight end

-- Shortest possible tallest column, by trying every arrangement.
local function bruteBest(heights, k)
	local n, best = #heights, math.huge
	local loads = {}
	for j = 1, k do loads[j] = 0 end
	local function go(i)
		if i > n then
			local m = 0
			for j = 1, k do if loads[j] > 0 then m = max(m, loads[j] - spacing) end end
			best = min(best, m)
			return
		end
		for j = 1, k do
			loads[j] = loads[j] + heights[i] + spacing
			go(i + 1)
			loads[j] = loads[j] - heights[i] - spacing
		end
	end
	go(1)
	return best
end

local function tallest(c)
	local m = 0
	for _, col in ipairs(c.columns) do m = max(m, col:GetHeight()) end
	return m
end

local function containerWith(k, rowsList, names)
	local cats = {}
	for i, rows in ipairs(rowsList) do table.insert(cats, cat(names and names[i] or ('C' .. i), rows)) end
	return H.container(cats, k)
end

local function heights_of(rows)
	local heights = {}
	for i, r in ipairs(rows) do heights[i] = height_of(r) end
	return heights
end

test('the tallest column is optimal against brute force, in many random bags', function()
	math.randomseed(7)
	local worse = 0
	for trial = 1, 300 do
		local k = ({ 2, 3, 3, 3, 4 })[math.random(5)]
		local n = math.random(1, 9)
		local rows = {}
		for i = 1, n do rows[i] = math.random(1, 8) end
		local c = containerWith(k, rows)
		layout(c)
		local want = bruteBest(heights_of(rows), k)
		if math.abs(tallest(c) - want) > 0.01 then
			worse = worse + 1
			print('  worse: k=' .. k .. ' rows=' .. table.concat(rows, ',') .. ' got ' .. tallest(c) .. ' best ' .. want)
		end
	end
	check(worse == 0, 'tallest column optimal in 300 random bags (' .. worse .. ' not)')
end)

test('it beats the old greedy where it matters: 3 columns, rows 3,3,2,2,2', function()
	local c = containerWith(3, { 3, 3, 2, 2, 2 })
	layout(c)
	check(math.abs(tallest(c) - bruteBest(heights_of({ 3, 3, 2, 2, 2 }), 3)) < 0.01, 'example optimal: ' .. tallest(c))
end)

test('within a column: smallest first when inverted, by name on a tie', function()
	local names = { 'Zeta', 'Big', 'Alpha', 'Mid', 'Beta', 'Large' }
	local c = containerWith(2, { 1, 4, 1, 2, 1, 3 }, names)
	layout(c)
	local ordered = true
	for _, col in ipairs(c.columns) do
		for p = 2, #col.categories do
			local a, b = col.categories[p - 1], col.categories[p]
			if a:GetHeight() > b:GetHeight() or (a:GetHeight() == b:GetHeight() and a.name > b.name) then ordered = false end
		end
	end
	check(ordered, 'columns run smallest first, then by name')
	INV.config.inverted = false
	local d = containerWith(2, { 1, 4, 1, 2, 1, 3 }, names)
	layout(d)
	local desc = true
	for _, col in ipairs(d.columns) do
		for p = 2, #col.categories do
			if col.categories[p - 1]:GetHeight() < col.categories[p]:GetHeight() then desc = false end
		end
	end
	check(desc, 'not inverted: biggest first')
	INV.config.inverted = true
end)

test('the same categories in any table order give the same arrangement', function()
	local names = { 'Armor', 'Weapon', 'Consumable', 'Trade Goods', 'Quest', 'Junk', 'Recipe', 'Gem' }
	local rows = { 2, 2, 1, 3, 1, 1, 2, 1 }
	local first
	local stable = true
	for trial = 1, 20 do
		local order = {}
		for i = 1, #names do order[i] = i end
		for i = #order, 2, -1 do local j = math.random(i); order[i], order[j] = order[j], order[i] end
		local cats = {}
		for _, i in ipairs(order) do table.insert(cats, cat(names[i], rows[i])) end
		local c = H.container(cats)
		layout(c)
		local w = where(c)
		if not first then first = w elseif not same(first, w) then stable = false end
	end
	check(stable, 'arrangement independent of table order')
end)

test('fewer categories than columns use the first columns, none skipped', function()
	local c = containerWith(3, { 2, 1 })
	layout(c)
	check(#c.columns[1].categories == 1 and #c.columns[2].categories == 1 and #c.columns[3].categories == 0, 'two categories in columns 1 and 2')
	-- two columns of 200, with the spacing between them
	check(c.scrollFrame:GetWidth() == 2 * (200 + spacing) - spacing, 'two columns wide')
end)

test('many categories finish quickly and are never worse than biggest-first', function()
	local slowest = 0
	for trial = 1, 40 do
		local k = ({ 3, 5 })[trial % 2 + 1]
		local rows = {}
		for i = 1, math.random(15, 30) do rows[i] = math.random(1, 12) end
		local c = containerWith(k, rows)
		local t0 = debugprofilestop()
		layout(c)
		slowest = max(slowest, (debugprofilestop() - t0) / 1000)
		-- biggest-first greedy for comparison
		local hs = {}
		for i, r in ipairs(rows) do hs[i] = height_of(r) + spacing end
		table.sort(hs, function(a, b) return a > b end)
		local loads = {}
		for j = 1, k do loads[j] = 0 end
		for _, h in ipairs(hs) do
			local l = 1
			for j = 2, k do if loads[j] < loads[l] then l = j end end
			loads[l] = loads[l] + h
		end
		local g = 0
		for j = 1, k do g = max(g, loads[j]) end
		check(tallest(c) <= g - spacing + 0.01, 'never worse than biggest-first (trial ' .. trial .. ')')
	end
	print(string.format('  slowest layout: %.1f ms', slowest * 1000))
	check(slowest < 0.05, 'every layout under 50 ms')
end)
