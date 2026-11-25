local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	Item groups: a named set of item IDs a rule can ask about ("Item group is
	Fish"). The IDs are data, generated from the game's tables by
	tools/item-groups.cjs into itemgroups_data.lua, so the lists are a build
	step's output and no rule has to carry them.

	  IG.Groups()   -> { { id, label }, ... }   the groups the rule editor offers
	  IG.Label(id)  -> label | nil              nil for an id no group has, or
	                                            a value that isn't a string
	  IG.Set(id)    -> { [itemID] = true }      this client's set, or an empty
	                                            table when it has none

	INV.ItemGroupsData is { forever = { fish = { [itemID] = true } }, retail =
	{ ... } } and is read at call time, not at load: it may be missing (the
	file isn't loaded yet, or a test sets it later), and a group with no data
	on this client is empty, never an error. Forever's data is for Forever's
	items; a retail client gets its own set, or nothing.
]]
local IG = {}
INV.ItemGroups = IG

local GROUPS = {
	{ id = 'fish', label = 'Fish' },
}

function IG.Groups()
	return GROUPS
end

function IG.Label(id)
	if type(id) ~= 'string' then return nil end
	for _, group in ipairs(GROUPS) do
		if group.id == id then return group.label end
	end
end

function IG.Set(id)
	local data = INV.ItemGroupsData
	local client = type(data) == 'table' and data[st.forever and 'forever' or 'retail']
	local set = type(client) == 'table' and type(id) == 'string' and client[id]
	if type(set) == 'table' then return set end
	-- A new table each time, so a caller that wrote to one couldn't fill every empty group.
	return {}
end
