local st = SaftUI
local INV = st:GetModule('Inventory')

local function vendorLegacy(self, elapsed)
	self.timeLeft = (self.timeLeft or 0) - elapsed
	if self.timeLeft > 0 then return end
	self.timeLeft = 2

	ids = {}
	for _,item in pairs(INV.containers.bag.categories[INV.categoryNames.LEGACY_ARMOR_WEAPONS].slots) do
		if item.info then
			tinsert(ids, { bagID = item.info.bagID, slotID = item.info.slotID })
		end
	end
	self.ids = ids

	if #self.ids == 0 or not MerchantFrame:IsShown() then
		self:SetScript('OnUpdate', nil)
		return
	end

	for _,item in pairs(ids) do
		UseContainerItem(item.bagID, item.slotID)
	end
end

function INV:HandleMerchant()
	-- Vendor greys and other selected items
	if UnitAffectingCombat('player') then
		st:Print('Cannot vendor in combat, reopen after leaving combat.')
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

							profit = profit + stackPrice
						end
					end
				end
			end
			--UnitLevel('player') == MAX_PLAYER_LEVEL and
			if  self.containers.bag.categories[self.categoryNames.LEGACY_ARMOR_WEAPONS] then
				local handler = CreateFrame('frame')
				handler.profit = 0
				handler.firstLoop = true
				handler:SetScript('OnUpdate', vendorLegacy)

				for _,item in pairs(INV.containers.bag.categories[INV.categoryNames.LEGACY_ARMOR_WEAPONS].slots) do
					if item.info then
						profit = profit + item.info.vendorPrice
					end
				end
			end

			if profit > 0 then st:Print('Total gold gained from vendoring greys: ' .. st.StringFormat:GoldFormat(profit))
			end
		end
	end

	-- Auto repair gear
	if self.config.autorepair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()

		repairAllCost, canRepair = GetRepairAllCost()

		if canRepair and repairAllCost > 0 and repairAllCost < GetMoney() then
			RepairAllItems()
			st:Print('Repaired all items for ' .. st.StringFormat:GoldFormat(repairAllCost))
		elseif repairAllCost > 0 then
			st:Print('Insufficient funds for gear repair.')
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