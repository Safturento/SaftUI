local st = SaftUI
local INV = st:GetModule('Inventory')
local Util = st:GetModule('Utilities')

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

--[[
	slot.info is an item's info table (INV:GetInventoryItemInfo) or, for a free
	bag slot shown in the Empty Slots category, a stub with `empty = true`, the
	bagID/slotID to put an item in, `count` (the free slots a grouped slot
	stands for, nil for a single one) and blank name, tooltipText, vendorPrice
	and stackPrice. It has no icon, quality, class, link or itemID, so anything
	reading slot.info that does more than the above must check info.empty first.
]]

-- Makes a slot look like an empty one: no icon, level, cooldown, quality
-- colour or desaturation, and a count only for a grouped slot.
function INV:AssignEmptySlot(slot, info)
	slot.itemLevel:SetText('')
	slot.itemLevelBG:Hide()
	Util:ClearItemQuality(slot)

	local template = st.config.profile.templates[self.config.template]
	if template and template.border then
		slot.backdrop:SetBackdropBorderColor(unpack(template.bordercolor))
	else
		slot.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
	end

	slot.cooldown:Hide()
	SetItemButtonTextureVertexColor(slot, 1, 1, 1)
	-- Hide the icon outright: SetItemButtonTexture(nil) would show Blizzard's
	-- empty slot art (the template's background atlas).
	slot.icon:Hide()
	SetItemButtonDesaturated(slot, false)

	-- Item buttons hide a count of 1 (minDisplayCount); a free slot count of 1
	-- is worth showing.
	slot.minDisplayCount = info.count and 0 or nil
	SetItemButtonCount(slot, info.count)
	slot.CountBG:SetShown(info.count ~= nil)
end

function INV:AssignSlot(container, slot, slotInfo)
	self:ClearSlot(slot)
	slot:SetParent(container.bags[slotInfo.bagID])
	slot:SetID(slotInfo.slotID)
	slot.info = slotInfo

	slot.reagentMarker:SetShown(self:IsReagentBag(slotInfo.bagID))

	if slotInfo.empty then
		self:AssignEmptySlot(slot, slotInfo)
		slot:Show()
		return
	end

	if (slot.info.class == 'Armor' or slot.info.class == 'Weapon') then
		if slot.info.isWarbound then
			slot.itemLevel:SetTextColor(st.config.profile.colors.text.cyan:GetRGB())
		elseif slot.info.isBoE then
			slot.itemLevel:SetTextColor(st.config.profile.colors.text.green:GetRGB())
		else
			slot.itemLevel:SetTextColor(st.config.profile.colors.text.white:GetRGB())
		end

		slot.itemLevel:SetFormattedText('%s',slot.info.ilvl)
		slot.itemLevelBG:Show()

		if st.retail then
			Util:SetItemUpgradeQualityForBagSlot(slot, slotInfo.bagID, slotInfo.slotID, slot.icon)
            if slot.ProfessionQualityOverlay then
                slot.ProfessionQualityOverlay:ClearAllPoints()
                slot.ProfessionQualityOverlay:SetPoint('TOPLEFT', slot.icon, 'TOPLEFT', 0, 0)
            end
		end
	else
		if st.retail then
			SetItemCraftingQualityOverlay(slot, slot.info.link)
			if slot.ProfessionQualityOverlay then
                slot.ProfessionQualityOverlay:ClearAllPoints()
                slot.ProfessionQualityOverlay:SetPoint('TOPLEFT', slot.icon, 'TOPLEFT', 0, 0)
            end
		end
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

	self:SetSlotCooldown(slot)

	--SetItemCraftingQualityOverlay(slot, slot.info.link)

	SetItemButtonTexture(slot, slot.info.texture)
	SetItemButtonDesaturated(slot, slot.info.locked, 0.5, 0.5, 0.5)

	SetItemButtonCount(slot, slot.info.count)
	slot.CountBG:SetShown(slot.info.count > 1)

	slot:Show()
end

local stackSplitButtonClick = StackSplitOkayButton_OnClick and 'StackSplitOkayButton_OnClick' or 'StackSplitFrameOkay_Click'

hooksecurefunc(stackSplitButtonClick, function()
	local bag_id, slot_id = INV:GetFirstEmptySlot(StackSplitFrame.owner.container.id)
	if bag_id and slot_id then
		C_Container.PickupContainerItem(bag_id, slot_id)
	end
end)

local function UpdateTooltip(self)
	local info = self.info
	if not info then return end

	-- Blizzard's tooltip code looks the item up in the bag, and there is none.
	if info.empty then
		-- Same placement as an item's tooltip.
		if ContainerFrameItemButton_CalculateItemTooltipAnchors then
			GameTooltip:SetOwner(self, 'ANCHOR_NONE')
			ContainerFrameItemButton_CalculateItemTooltipAnchors(self, GameTooltip)
		else
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		end
		GameTooltip:SetText(INV:IsReagentBag(info.bagID) and 'Empty reagent bag slot' or 'Empty bag slot')
		if info.count then
			GameTooltip:AddLine(('%d free'):format(info.count), 1, 1, 1)
		end
		GameTooltip:Show()
		return
	end

	if self.info.bagID == -1 then
		BankFrameItemButton_OnEnter(self)
	else
		ContainerFrameItemButton_OnEnter(self)
	end
end

function INV:ShouldAutoVendor(itemID)
    return INV.config.autoVendorFilter and INV.config.autoVendorFilter[itemID]
end

function INV:IsProtected(itemID)
    return INV.config.protectFilter and INV.config.protectFilter[itemID]
end

local menuItems = {
    autoVendor = {
        text = 'Auto Vendor',
        isChecked = function()
            return INV.config.autoVendorFilter
                and INV.SelectedSlot.info
                and INV.config.autoVendorFilter[INV.SelectedSlot.info.itemID]
        end,
        setChecked = function(key, menuInputData, menu)
            if not INV.SelectedSlot then return end

            if not INV.config.autoVendorFilter then
                INV.config.autoVendorFilter = {}
            end
            local itemID = INV.SelectedSlot.info.itemID
            INV.config.autoVendorFilter[itemID] = not INV.config.autoVendorFilter[itemID]
            INV:QueueUpdate()
       end,
    },
    protect = {
        text = 'Protected',
        isChecked = function() return INV.config.protectFilter
            and INV.SelectedSlot.info
            and INV.config.protectFilter[INV.SelectedSlot.info.itemID] end,
        setChecked = function(key, menuInputData, menu)
            if not INV.SelectedSlot then return end

            if not INV.config.protectFilter then
                INV.config.protectFilter = {}
            end
            local itemID = INV.SelectedSlot.info.itemID
            INV.config.protectFilter[itemID] = not INV.config.protectFilter[itemID]
            INV:QueueUpdate()
        end,
    }
}

local function isChecked(key)
    return menuItems[key].isChecked()
end

local function setChecked(key, menuInputData, menu)
   menuItems[key].setChecked(key, menuInputData, menu)
   menu:Close()
end

local function CreateSlotDropdown()
    if INV.SlotDropDown then return end

    INV.SlotDropDown = st:CreateCheckboxDropdown("SaftUISlotOptionsMenu", UIParent, {
        autoVendor = { text = 'Auto Vendor'},
        protect = { text = 'Protected'}
    }, isChecked, setChecked)
end

local function OpenSlotOptions(slot, button, down)
    -- A free slot has no item to mark.
    if slot.info and slot.info.empty then return end
    INV.SelectedSlot = slot
    if not INV.SlotDropDown then CreateSlotDropdown() end

    if IsControlKeyDown() and button == 'RightButton' then
        INV.SlotDropDown:Open()
--         ToggleDropDownMenu(1, nil, INV.SlotDropDown, "cursor",5, -5)
    end
end

function INV:CreateSlot(container, categoryName)
	local categoryFrame = container.categories[categoryName]
	local slotID = #categoryFrame.slots + 1
	local slot, slotName

    assert(categoryFrame, 'Category "'..categoryName..'" does not exist')

    local bagName = container:GetName()
    slotName = bagName..'_'..(gsub(categoryName, '(%A)', ''))..'_Slot'..slotID
    slot = CreateFrame(st.retail and 'ItemButton' or 'CheckButton', slotName, categoryFrame, 'ContainerFrameItemButtonTemplate')
    if not slot.icon then st:Error(slotName.." is missing an icon") end

    if slot.IconOverlay then
        slot.IconOverlay:ClearAllPoints()
        slot.IconOverlay:SetAllPoints(slot.icon)
    end

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

	slot:SetSize(self:GetButtonWidth(), self:GetButtonHeight())
	
	slot.cooldown = _G[slotName .. "Cooldown"]

	st:Kill(slot.BattlepayItemTexture)

	st:SkinIcon(slot.icon, nil, slot)

	slot.Count:ClearAllPoints()
	slot.Count:SetPoint('BOTTOMRIGHT', -4, 4)

	slot.cooldown:SetAllPoints(slot)

	local itemLevel = slot:CreateFontString(nil, 'OVERLAY')
	itemLevel:SetFontObject(st:GetFont(self.config.fonts.icons))
	itemLevel:SetPoint('BOTTOMRIGHT', slot.Count, -1, 0)
	slot.itemLevel = itemLevel

	local itemLevelBG = slot:CreateTexture(nil, 'OVERLAY')
	itemLevelBG:SetPoint('BOTTOMRIGHT', slot.icon)
	itemLevelBG:SetPoint('TOPLEFT', itemLevel, -2, 1)
	itemLevelBG:SetTexture(st.BLANK_TEX)
	itemLevelBG:SetAlpha(0.8)
	itemLevelBG:SetVertexColor(0,0,0)
	slot.itemLevelBG = itemLevelBG

	-- A green wedge in the icon's top right marks an item in the reagent bag
	-- (and a free slot of it). The corner texture fills the bottom right, so it
	-- is flipped upside down. The top right is clear of the count and item
	-- level (bottom right) and the crafting quality pip (top left).
	local reagentMarker = slot:CreateTexture(nil, 'OVERLAY', nil, 6)
	reagentMarker:SetTexture(st.textures.cornerbr)
	reagentMarker:SetTexCoord(0, 1, 1, 0)
	reagentMarker:SetPoint('TOPRIGHT', slot.icon, 'TOPRIGHT', 0, 0)
	reagentMarker:SetSize(st:RoundToPixel(14), st:RoundToPixel(14))
	reagentMarker:SetVertexColor(st.config.profile.colors.text.green:GetRGB())
	reagentMarker:Hide()
	slot.reagentMarker = reagentMarker

	st:SkinActionButton(slot, {
		template = self.config.template,
		font = self.config.fonts.icons,
		trueSize = true
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

-- Applies the profile's slot size, spot, template and fonts to a slot made by
-- INV:CreateSlot. Runs on profile changes; skinning a slot again is safe.
function INV:StyleSlot(slot, categoryFrame, container)
	self:SetSlotPosition(slot, categoryFrame, container)
	slot:SetSize(self:GetButtonWidth(), self:GetButtonHeight())
	slot.itemLevel:SetFontObject(st:GetFont(self.config.fonts.icons))
	slot.reagentMarker:SetVertexColor(st.config.profile.colors.text.green:GetRGB())

	st:SkinActionButton(slot, {
		template = self.config.template,
		font = self.config.fonts.icons,
		trueSize = true
	})
	slot:SetNormalTexture("")
	slot:SetPushedTexture("")
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
	if slot.reagentMarker then slot.reagentMarker:Hide() end
	slot.minDisplayCount = nil
	if slot.Reset then slot:Reset() end
	if slot.info then
		-- self.SlotMap[tostring(slot.info.bagID) .. tostring(slot.info.slotID)] = nil
		slot.info = nil
	end
	slot:SetEnabled(true)
end
