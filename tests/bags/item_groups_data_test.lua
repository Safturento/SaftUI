-- The generated item group data (SaftUI-Bags/itemgroups_data.lua, written by
-- tools/item-groups.cjs from a wowf build): it loads, its sets hold only item
-- IDs set to true, and spot checks of the Fish group pass on Forever (a raw
-- fish in; a trophy fish and a cooked fish out). bags/bag_world.lua loads the
-- real file before itemgroups.lua.
local W = load_test_file('bags/bag_world.lua')

test('the data file loads, and every set is item IDs set to true', function()
	local INV = W.fresh('forever')
	local data = INV.ItemGroupsData
	check(type(data) == 'table', 'INV.ItemGroupsData is set')
	check(type(data.forever) == 'table' and type(data.forever.fish) == 'table', 'it has forever.fish')
	local n = 0
	for client, groups in pairs(data) do
		for group, set in pairs(groups) do
			for id, value in pairs(set) do
				check(type(id) == 'number' and id == math.floor(id) and id > 0, client .. '.' .. group .. ': key ' .. tostring(id) .. ' is an item ID')
				eq(value, true, client .. '.' .. group .. ': ' .. tostring(id) .. ' is true')
				if client == 'forever' and group == 'fish' then n = n + 1 end
			end
		end
	end
	check(n > 0, 'forever.fish holds items')
end)

test('Fish on Forever: a raw fish in, a trophy fish and a cooked fish out', function()
	local INV = W.fresh('forever')
	local fish = INV.ItemGroups.Set('fish')
	eq(fish[6303], true, 'Raw Slitherskin Mackerel (6303) is a fish')
	eq(fish[13757], true, 'Lightning Eel (13757, added by the overrides) is a fish')
	eq(fish[6292], nil, '10 Pound Mud Snapper (6292, a trophy) is not')
	eq(fish[13935], nil, 'Baked Salmon (13935, cooked) is not')
	eq(fish[5468], nil, 'Soft Frenzy Flesh (5468, removed by the overrides) is not')
end)

test('retail has no fish', function()
	local INV = W.fresh('retail')
	eq(next(INV.ItemGroups.Set('fish')), nil, 'the retail set is empty')
end)
