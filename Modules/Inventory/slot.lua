local ADDON_NAME, st = ...
local INV = st:GetModule('Inventory')

function INV:SetSlotPosition(slot, category_frame, container)
	local slotID = slot.id

	slot:ClearAllPoints()
	if slot.id == 1 then
		slot:SetPoint('TOPLEFT', category_frame, 0, -(INV.CATEGORY_TITLE_HEIGHT+self.config.buttonspacing))
	elseif slot.id % self.config[container.id].perrow == 1 then
		slot:SetPoint('TOP', category_frame.slots[slot.id-self.config[container.id].perrow], 'BOTTOM', 0, -self.config.buttonspacing)
	else
		slot:SetPoint('LEFT', category_frame.slots[slot.id-1], 'RIGHT', self.config.buttonspacing, 0)
	end
end

function INV:AssignSlot(container, slot, slotInfo)
	self:ClearSlot(slot)
	slot:SetParent(container.bags[slotInfo.bagID])
	slot:SetID(slotInfo.slotID)
	slot.info = slotInfo

	-- self.SlotMap[tostring(slotInfo.bagID) .. tostring(slotInfo.slotID)] = slot

	if (slot.info.class == 'Armor' or slot.info.class == 'Weapon') then
		slot.item_level:SetFormattedText('%s',slot.info.ilvl)
	else
		slot.item_level:SetText('')
	end

	if not slot.info.locked and slot.info.quality then
		if slot.info.quality > -1 then
			local c = ITEM_QUALITY_COLORS[slot.info.quality]
			slot.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
		else
			slot.backdrop:SetBackdropBorderColor(0, 0, 0)
		end
	end

	self:SetSlotCooldown(slot)

	SetItemButtonTexture(slot, slot.info.texture)
	SetItemButtonCount(slot, slot.info.count)
	SetItemButtonDesaturated(slot, slot.info.locked, 0.5, 0.5, 0.5)

	slot:Show()
end

if StackSplitFrameOkay_Click then
	hooksecurefunc('StackSplitFrameOkay_Click', function()
		local bag_id, slot_id = INV:GetFirstEmptySlot(StackSplitFrame.owner.container.id)
		if bag_id and slot_id then
			PickupContainerItem(bag_id, slot_id)
		end
	end)
end

local function UpdateTooltip(self)
	if self.info.bagID == -1 then
		BankFrameItemButton_OnEnter(self)
	else
		ContainerFrameItemButton_OnEnter(self)
	end
end

function INV:CreateSlot(container, category_name)
	local category_frame = container.categories[category_name]
	local slotID = #category_frame.slots + 1
	local slot, slot_name

	if not (container.id == 'reagent') then
		assert(category_frame, 'Category "'..category_name..'" does not exist')

		local bagName = container:GetName()
		slot_name = bagName..'_'..(gsub(category_name, '(%A)', ''))..'_Slot'..slotID
		slot = CreateFrame('ItemButton', slot_name, category_frame, 'ContainerFrameItemButtonTemplate')
		if not slot.icon then print(slot_name) end
		slot.Count = _G[slot:GetName() .. "Count"]
		slot.icon = _G[slot:GetName() .. "IconTexture"]
		slot.border = _G[slot:GetName() .. "NormalTexture"]
		slot.cooldown = _G[slot:GetName() .. "Cooldown"]
		
		slot.container = container
		slot.id = slotID
		slot.type = container.id
		slot.tainted = InCombatLockdown()
		
		slot.GetInventorySlot = ButtonInventorySlot

		slot.UpdateTooltip = UpdateTooltip
		slot:SetScript('OnEnter', UpdateTooltip)

		self:SetSlotPosition(slot, category_frame, container)
	end
	
	slot:SetSize(self.config.buttonwidth, self.config.buttonheight)
	
	slot.cooldown = _G[slot_name .. "Cooldown"]

	st:Kill(slot.BattlepayItemTexture)

	st:SkinIcon(slot.icon, nil, slot)

	slot.Count:ClearAllPoints()
	slot.Count:SetPoint('BOTTOMRIGHT', -2, 4)

	slot.cooldown:SetAllPoints(slot)

	item_level = slot:CreateFontString(nil, 'OVERLAY')
	item_level:SetFontObject(st:GetFont('pixel'))
	item_level:SetPoint('BOTTOMRIGHT', slot.Count)
	slot.item_level = item_level

	st.SkinActionButton(slot, {
		template = self.config.template,
		font = self.config.fonts.icons
	})
	slot:SetNormalTexture("")
	slot:SetPushedTexture("")
	slot:Hide()

	-- tinsert(self.AllSlots, slot)
	-- container.slots[slotID] = slot
	category_frame.slots[slotID] = slot

	if slot.tainted then
		print(slot:GetName() .. ' is tainted, will break if used in combat')
	end

	return slot
end

function INV:SetSlotCooldown(slot)
	local start, duration, enable = GetContainerItemCooldown(slot.info.bagID, slot.info.slotID)
	 CooldownFrame_Set(slot.cooldown, start, duration, enable)
	 slot.cooldown:SetScale(1)
    if ( duration > 0 and enable == 0 ) then
        SetItemButtonTextureVertexColor(slot, 0.4, 0.4, 0.4)
    else
        SetItemButtonTextureVertexColor(slot, 1, 1, 1)
    end
end

--Update cooldown spirals on usable items
function INV:UpdateCooldowns()
	for _,category in pairs(self.containers.bag.categories) do
		for _,slot in pairs(category.slots) do
		    if slot.info and slot.info.bagID and slot.info.slotID and ( GetContainerItemInfo(slot.info.bagID, slot.info.slotID) ) then
			    INV:SetSlotCooldown(slot)
	        elseif slot.cooldown then
	            slot.cooldown:Hide()
	        end
	    end
    end
end

function INV:ClearSlot(slot)
	slot:Hide()
	if slot.info then
		-- self.SlotMap[tostring(slot.info.bagID) .. tostring(slot.info.slotID)] = nil
		slot.info = nil
	end
	slot:SetEnabled(true)
end
