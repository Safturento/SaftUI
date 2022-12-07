local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:GetFirstEmptySlot(id)
	local container = self.containers[id]

	for _,bag_id in pairs(container.bag_ids) do
		for slot_id=1, GetContainerNumSlots(bag_id) do
			if not GetContainerItemID(bag_id, slot_id) then
				return bag_id, slot_id
			end
		end
	end
end