local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:SetSlotPosition(slot, categoryFrame, container)
	local slotID = slot.id

	slot:ClearAllPoints()
	if slot.id == 1 then
		slot:SetPoint('TOPLEFT', categoryFrame, 0, -(self.config.categoryTitleHeight + self.config.buttonspacing))
	elseif slot.id % self.config[container.id].perrow == 1 then
		slot:SetPoint('TOP', categoryFrame.slots[slot.id-self.config[container.id].perrow], 'BOTTOM', 0, -self.config.buttonspacing)
	else
		slot:SetPoint('LEFT', categoryFrame.slots[slot.id-1], 'RIGHT', self.config.buttonspacing, 0)
	end
end

function INV:AssignSlot(container, slot, slotInfo)
	self:ClearSlot(slot)
	slot:SetParent(container.bags[slotInfo.bagID])
	slot:SetID(slotInfo.slotID)
	slot.info = slotInfo

	-- self.SlotMap[tostring(slotInfo.bagID) .. tostring(slotInfo.slotID)] = slot

	if (slot.info.class == 'Armor' or slot.info.class == 'Weapon') then
		slot.itemLevel:SetFormattedText('%s',slot.info.ilvl)
		slot.itemLevelBG:Show()
	else
		slot.itemLevel:SetText('')
		slot.itemLevelBG:Hide()
	end

	if not slot.info.locked and slot.info.quality then
		if slot.info.quality > -1 then
			local c = ITEM_QUALITY_COLORS[slot.info.quality]
			slot.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
		else
			slot.backdrop:SetBackdropBorderColor(0, 0, 0)
		end
	end

	if C_NewItems.IsNewItem(slotInfo.bagID, slotInfo.slotID) then
		slot.backdrop.outer_shadow:SetBackdropBorderColor(1, 1, 1, 1)
		slot.backdrop.outer_shadow:Show()
	else
		slot.backdrop.outer_shadow:Hide()
	end

	self:SetSlotCooldown(slot)

	SetItemCraftingQualityOverlay(slot, slot.info.link)

	SetItemButtonTexture(slot, slot.info.texture)
	SetItemButtonDesaturated(slot, slot.info.locked, 0.5, 0.5, 0.5)

	SetItemButtonCount(slot, slot.info.count)
	slot.CountBG:SetShown(slot.info.count > 1)

	slot:Show()
end

if StackSplitOkayButton_OnClick then
	hooksecurefunc('StackSplitOkayButton_OnClick', function()
		local bag_id, slot_id = INV:GetFirstEmptySlot(StackSplitFrame.owner.container.id)
		if bag_id and slot_id then
			C_Container.PickupContainerItem(bag_id, slot_id)
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

function INV:ShouldAutoVendor(itemID)
    return INV.config.autoVendorFilter and INV.config.autoVendorFilter[itemID]
end

local function CreateSlotDropdown()
    INV.SlotDropDown = CreateFrame("Frame", "SaftUI_SlotOptionsMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(INV.SlotDropDown, 200)
    UIDropDownMenu_SetText(INV.SlotDropDown, "Options")
    UIDropDownMenu_Initialize(INV.SlotDropDown, function(dropdown, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Auto Vendor"
        info.checked = function(self)
            return INV.config.autoVendorFilter and INV.SelectedSlot.info and INV.config.autoVendorFilter[INV.SelectedSlot.info.itemID]
        end
        info.func = function(dropdown, arg1, arg2, checked)
            if not INV.SelectedSlot then return end

            if not INV.config.autoVendorFilter then INV.config.autoVendorFilter = {} end
            INV.config.autoVendorFilter[INV.SelectedSlot.info.itemID] = not checked
            INV:QueueUpdate()
        end
        UIDropDownMenu_AddButton(info)
    end)
end

local function OpenSlotOptions(slot, button, down)
    INV.SelectedSlot = slot
    if not INV.SlotDropDown then CreateSlotDropdown() end

    if IsControlKeyDown() and button == 'RightButton' then
        ToggleDropDownMenu(1, nil, INV.SlotDropDown, "cursor",5, -5)
    end
end

function INV:CreateSlot(container, category_name)
	local categoryFrame = container.categories[category_name]
	local slotID = #categoryFrame.slots + 1
	local slot, slot_name

	--if not (container.id == 'reagent') then
		assert(categoryFrame, 'Category "'..category_name..'" does not exist')

		local bagName = container:GetName()
		slot_name = bagName..'_'..(gsub(category_name, '(%A)', ''))..'_Slot'..slotID
		slot = CreateFrame('ItemButton', slot_name, categoryFrame, 'ContainerFrameItemButtonTemplate')
		if not slot.icon then st:Error(slot_name.." is missing an icon") end
		slot.Count = _G[slot:GetName() .. "Count"]
		slot.Count:SetDrawLayer('OVERLAY', 99)

		slot.CountBG = slot:CreateTexture(nil, 'OVERLAY')
		slot.CountBG:SetPoint('BOTTOMRIGHT', slot.icon)
		slot.CountBG:SetPoint('TOPLEFT', slot.Count, -2, 1)
		slot.CountBG:SetTexture(st.BLANK_TEX)
		slot.CountBG:SetAlpha(0.6)
		slot.CountBG:SetVertexColor(0,0,0)

		slot.icon = _G[slot:GetName() .. "IconTexture"]
		slot.border = _G[slot:GetName() .. "NormalTexture"]
		slot.border:SetTexture('')
		slot.cooldown = _G[slot:GetName() .. "Cooldown"]
		
		slot.container = container
		slot.id = slotID
		slot.type = container.id
		slot.tainted = InCombatLockdown()
		
		slot.GetInventorySlot = ButtonInventorySlot

		slot.UpdateTooltip = UpdateTooltip
		slot:SetScript('OnEnter', UpdateTooltip)
		slot:HookScript('OnClick', OpenSlotOptions)

		self:SetSlotPosition(slot, categoryFrame, container)
	--end
	
	slot:SetSize(self.config.buttonwidth, self.config.buttonheight)
	
	slot.cooldown = _G[slot_name .. "Cooldown"]

	st:Kill(slot.BattlepayItemTexture)

	st:SkinIcon(slot.icon, nil, slot)

	slot.Count:ClearAllPoints()
	slot.Count:SetPoint('BOTTOMRIGHT', -4, 4)

	slot.cooldown:SetAllPoints(slot)

	itemLevel = slot:CreateFontString(nil, 'OVERLAY')
	itemLevel:SetFontObject(st:GetFont(self.config.fonts.icons))
	itemLevel:SetPoint('BOTTOMRIGHT', slot.Count)
	slot.itemLevel = itemLevel

	itemLevelBG = slot:CreateTexture(nil, 'OVERLAY')
	itemLevelBG:SetPoint('BOTTOMRIGHT', slot.icon)
	itemLevelBG:SetPoint('TOPLEFT', itemLevel, -2, 1)
	itemLevelBG:SetTexture(st.BLANK_TEX)
	itemLevelBG:SetAlpha(0.8)
	itemLevelBG:SetVertexColor(0,0,0)
	slot.itemLevelBG = itemLevelBG


	st:SkinActionButton(slot, {
		template = self.config.template,
		font = self.config.fonts.icons
	})
	slot:SetNormalTexture("")
	slot:SetPushedTexture("")
	slot:Hide()

	-- tinsert(self.AllSlots, slot)
	-- container.slots[slotID] = slot
	categoryFrame.slots[slotID] = slot

	if slot.tainted then
		st:Error(slot:GetName() .. ' is tainted, will break if used in combat')
	end

	return slot
end

function INV:SetSlotCooldown(slot)
	local start, duration, enable = C_Container.GetContainerItemCooldown(slot.info.bagID, slot.info.slotID)
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
		    if slot.info and slot.info.bagID and slot.info.slotID and ( C_Container.GetContainerItemInfo(slot.info.bagID, slot.info.slotID) ) then
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
