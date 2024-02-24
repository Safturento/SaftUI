local st = SaftUI
local INV = st:GetModule('Inventory')

local vendorHandler = CreateFrame('frame')

function INV:GetVendorItems()
	local items = {}
	local profit = 0

	for _,categoryName in pairs(INV.AUTO_VENDOR_CATEGORIES) do
		local category = self.containers.bag.categories[categoryName]
		for _,slot in pairs(category.slots) do
			local info = slot and slot.info
			if info and info.vendorPrice > 0 then
				tinsert(items, info)
				profit = profit + info.stackPrice
			end
		end
	end

	return items, profit
end

function INV:AutoVendor()
	--[[ To get around blizzard's throttling, We keep doing this
	 	on repeat every	2 seconds until all of the items are sold  ]]
	vendorHandler:SetScript('OnUpdate', function(self, elapsed)
		self.timeLeft = (self.timeLeft or 0) - elapsed
		if self.timeLeft > 0 then return end
		self.timeLeft = 2

		local items = INV:GetVendorItems()
		if #items == 0 or not MerchantFrame:IsShown() then
			self:SetScript('OnUpdate', nil)
			return
		end

		for _,item in pairs(items) do
			C_Container.UseContainerItem(item.bagID, item.slotID)
		end
	end)
end

function INV:VendorCategory(categoryKey)
	local category = self.containers.bag.categories[categoryKey]
	if not category.vendorHandler then
		category.vendorHandler = CreateFrame('frame')
	end
    if category then

        vendorHandler.profit = 0
        vendorHandler.firstLoop = true

        vendorHandler:SetScript('OnUpdate', function(self, elapsed)

            self.timeLeft = (self.timeLeft or 0) - elapsed
            if self.timeLeft > 0 then return end
            self.timeLeft = 2

            ids = {}
            for _,item in pairs(category.slots) do
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
                C_Container.UseContainerItem(item.bagID, item.slotID)
            end
        end)

        for _,item in pairs(INV.containers.bag.categories[categoryKey].slots) do
            if item.info then
                vendorHandler.profit = vendorHandler.profit + item.info.vendorPrice
            end
        end
    end
end

function INV:HandleMerchant()
	-- Vendor greys and other selected items
	if UnitAffectingCombat('player') then
		st:Print('Cannot vendor in combat, reopen after leaving combat.')
		return
	else
		if self.config.autovendor then
			INV:AutoVendor()
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
		for slotID=1, C_Container.GetContainerNumSlots(bagID) do
			local link = C_Container.GetContainerItemLink(bagID, slotID)
			if link and select(11, GetItemInfo(link)) then
				local _,_,quality,_,_,_,_,_,_,_,price = GetItemInfo(link)
				local itemInfo = C_Container.GetContainerItemInfo(bagID, slotID)
				local stackPrice = price * itemInfo.stackCount

				if quality == 0 and stackPrice > 0 then
					profit = profit + stackPrice
				end
			end
		end
	end

	return profit
end