local ADDON_NAME, st = ...
local INV = st:GetModule('Inventory')

function INV:HandleMerchant()

	-- Vendor greys and other selected items
	if UnitAffectingCombat('player') then
		print('Cannot vendor in combat, reopen after leaving combat.')
		return
	else
		if self.config.autovendor then
			local profit = 0
			for _,bagID in pairs(self.containers.bag.bag_ids) do
				for slotID=1, GetContainerNumSlots(bagID) do
					local link = GetContainerItemLink(bagID, slotID)
					if link and select(11, GetItemInfo(link)) then
						local _,_,quality,_,_,_,_,_,_,_,price = GetItemInfo(link)
						local count = select(2, GetContainerItemInfo(bagID, slotID))
						local stackPrice = price*count

						if quality == 0 and stackPrice > 0 then
							UseContainerItem(bagID, slotID)
							PickupMerchantItem()

							profit = profit + stackPrice
						end
					end
				end
			end

			if profit > 0 then
				print('Total gold gained from vendoring greys: ' .. st.StringFormat:GoldFormat(profit))
			end
		end
	end

	-- Auto repair gear
	if self.config.autorepair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()

		repairAllCost, canRepair = GetRepairAllCost()

		if canRepair and repairAllCost > 0 and repairAllCost < GetMoney() then
			RepairAllItems()
			print('Repaired all items for ' .. st.StringFormat:GoldFormat(repairAllCost))
		elseif repairAllCost > 0 then
			print('Insufficient funds for gear repair.')
		end

	end
end

function INV:GetAutoVendorProfit()
	local profit = 0
	for _,bagID in pairs(self.containers.bag.bag_ids) do
		for slotID=1, GetContainerNumSlots(bagID) do
			local link = GetContainerItemLink(bagID, slotID)
			if link and select(11, GetItemInfo(link)) then
				local _,_,quality,_,_,_,_,_,_,_,price = GetItemInfo(link)
				local count = select(2, GetContainerItemInfo(bagID, slotID))
				local stackPrice = price*count

				if quality == 0 and stackPrice > 0 then
					profit = profit + stackPrice
				end
			end
		end
	end
	
	return profit
end

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