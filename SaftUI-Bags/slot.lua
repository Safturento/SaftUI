local st = SaftUI
local INV = st:GetModule('Inventory')
local Util = st:GetModule('Utilities')

-- Anchors a slot in its category frame, in lines of lineSlots slots (by
-- default the line of the view the window is laid out in, INV:LineSlots): the
-- first under the frame's title (at its top when it has none), the first of
-- each line under the one above, the rest after the one before.
function INV:SetSlotPosition(slot, categoryFrame, container, lineSlots)
	lineSlots = lineSlots or self:LineSlots(container.id, self:GetLaidOutView(container))
	local spacing = self.config.buttonspacing

	slot:ClearAllPoints()
	if slot.id == 1 then
		local top = categoryFrame.untitled and 0 or self.config.categoryTitleHeight + spacing
		slot:SetPoint('TOPLEFT', categoryFrame, 0, -top)
	elseif (slot.id - 1) % lineSlots == 0 then
		slot:SetPoint('TOP', categoryFrame.slots[slot.id - lineSlots], 'BOTTOM', 0, -spacing)
	else
		slot:SetPoint('LEFT', categoryFrame.slots[slot.id - 1], 'RIGHT', spacing, 0)
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
	self:SetSlotThemeBorder(slot)

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

-- The border color r, g, b for a quality (the profile's, see st:QualityColor):
-- black for quality -1 or a quality with no color. Item slots and currency
-- slots both use it.
function INV:QualityBorderColor(quality)
	local c = quality > -1 and st:QualityColor(quality)
	if c then return c.r, c.g, c.b end
	return 0, 0, 0
end

-- The border in the item's quality color. A locked slot, or one with no
-- quality, keeps the border it has. A slot drawn with None has none to color.
function INV:SetSlotQualityBorder(slot)
	if slot.backdrop and not slot.info.locked and slot.info.quality then
		st:SetBorderColor(slot.backdrop, self:QualityBorderColor(slot.info.quality))
	end
end

-- The border of a slot with no item's quality on it (a free slot, which may
-- have shown an item's): its Slot theme's border (under Blizzard none: the
-- white icon border is off), none for None.
function INV:SetSlotThemeBorder(slot)
	if not slot.backdrop then return end
	st:SetBorderColor(slot.backdrop)
end

-- Skins an item or currency slot (st:SkinActionButton) with the Slot theme and
-- background, as a slot, and the icon font. Its backdrop fills the slot and its
-- icon sits inside the border (trueSize); None has no backdrop, so the icon
-- fills the slot. Under Blizzard its pushed and highlight art are Blizzard's.
-- Safe to run again.
function INV:SkinSlot(slot)
	local theme, background = self.config.buttontheme, self.config.buttonbackground
	st:SkinActionButton(slot, {
		theme = theme,
		background = background,
		font = self.config.fonts.icons,
		trueSize = theme ~= 'none',
	}, 'slot')
	slot:SetNormalTexture("")
	-- Under Thick and Thin the pushed art is cleared; under Blizzard
	-- st:SkinActionButton gave it Blizzard's (Quickslot-Depress).
	if not st:IsBlizzardLook(theme, background) then
		slot:SetPushedTexture("")
	end
end

-- A quality color changed in the options, or a theme recolor or redraw put the
-- theme's border back on every slot (group 'theme'): redraw the borders of the
-- filled slots and the shown currencies.
function INV:OnColorsChanged(group)
	-- Buttons -> Blue lights the view buttons; Text -> Normal draws their icons.
	if group == 'button' or group == 'text' then self:ColorViewButtons(group) end
	if group ~= 'item_quality' and group ~= 'theme' then return end
	for _, container in pairs(self.containers) do
		for _, category in pairs(container.categories) do
			for _, slot in pairs(category.slots) do
				if slot.info and not slot.info.empty then
					self:SetSlotQualityBorder(slot)
				end
			end
		end
	end
	self:UpdateCurrencyBorders()
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

	self:SetSlotQualityBorder(slot)

	-- Blizzard's junk coin, on every item auto vendor will sell (see
	-- INV:IsAutoVendorItem), at a merchant or not. Showing a texture is safe in
	-- combat. The next update after the Protected or Auto Vendor mark changes
	-- redoes it.
	if slot.JunkIcon then slot.JunkIcon:SetShown(self:IsAutoVendorItem(slotInfo)) end

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

-- SaftUI's own item slots, by slot (weak): what INV:HookSlotTooltips checks a
-- tooltip's owner against. Filled by INV:CreateSlot. Nothing is written onto
-- a Blizzard frame to tell its slots apart.
INV.itemSlots = INV.itemSlots or setmetatable({}, { __mode = 'k' })

-- 1 -> '1st', 2 -> '2nd', 3 -> '3rd', 4 -> '4th', 11 to 13 -> '11th' to
-- '13th', 21 -> '21st'.
function INV.Ordinal(n)
	local lastTwo, last = n % 100, n % 10
	local suffix = 'th'
	if lastTwo < 11 or lastTwo > 13 then
		if last == 1 then suffix = 'st' elseif last == 2 then suffix = 'nd' elseif last == 3 then suffix = 'rd' end
	end
	return n .. suffix
end

-- '|cffrrggbb' for a profile color.
local function ColorEscape(c)
	local function byte(v) return math.floor(v * 255 + 0.5) end
	return ('|cff%02x%02x%02x'):format(byte(c.r), byte(c.g), byte(c.b))
end

--[[
	The "why is this here" lines for an item's tooltip, { { text, r, g, b }, ... }:
	  Category: <name> (<nth>)       the category in blue, its place in the list in grey;
	  Caught by: <what>              "Caught by: " in yellow, then the block of the
	                                 rule that caught it (INV.Rules.Describe), "pinned
	                                 to this category", "an equipment set" or "no
	                                 category above it".
	None for a free slot, an item still loading, or an info with no category.
	Reads info.category and info.categoryWhy, which INV:ReadBags sets.
]]
function INV:CategoryTooltipLines(info)
	if type(info) ~= 'table' or info.empty or info.loading or info.category == nil then return {} end
	local key = info.category
	local colors = st.config.profile.colors.text
	local name = tostring(self:CategoryName(key)):gsub('|', '||')
	local place = self:CategoryPlace(key)
	local first = 'Category: ' .. name
	if place then first = first .. ' ' .. ColorEscape(colors.grey) .. '(' .. self.Ordinal(place) .. ')|r' end
	local lines = { { text = first, r = colors.blue.r, g = colors.blue.g, b = colors.blue.b } }

	local why, words = info.categoryWhy, nil
	if why then
		if why.kind == 'pin' then
			words = 'pinned to this category'
		elseif why.kind == 'set' then
			words = 'an equipment set'
		elseif why.kind == 'misc' then
			words = 'no category above it'
		elseif why.kind == 'rule' then
			local entry = self:GetCategoryList().byId[key]
			words = entry and self.Rules.Describe(entry.rule, why.path)
			if words == '' then words = nil end
		end
	end
	if words then
		-- The words hold the user's typed text: a | in it is shown, not read as an escape.
		words = words:gsub('|', '||')
		lines[2] = { text = ColorEscape(colors.yellow) .. 'Caught by: |r' .. words, r = 1, g = 1, b = 1 }
	end
	return lines
end

function INV:AddCategoryTooltipLines(tooltip, info)
	for _, line in ipairs(self:CategoryTooltipLines(info)) do
		tooltip:AddLine(line.text, line.r, line.g, line.b)
	end
end

--[[
	Puts the lines on GameTooltip when it shows an item of one of SaftUI's own
	slots, from a TooltipDataProcessor post-call for items: only to GameTooltip,
	only while its owner is one of INV.itemSlots with an item, and nothing is
	written onto Blizzard's tooltip but the lines. Registers once. Returns
	whether it is registered; without TooltipDataProcessor (or its item type)
	it does nothing and returns false, and the slot's own UpdateTooltip adds
	the lines after Blizzard's item tooltip instead.
]]
function INV:HookSlotTooltips()
	if self.tooltipPostCall then return true end
	if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
			and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item) then
		return false
	end
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
		if tooltip ~= GameTooltip then return end
		local owner = tooltip:GetOwner()
		if not (owner and INV.itemSlots[owner]) then return end
		local info = owner.info
		if info and not info.empty then INV:AddCategoryTooltipLines(tooltip, info) end
	end)
	self.tooltipPostCall = true
	return true
end

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

	-- No TooltipDataProcessor on this client: the lines are added here.
	if not INV.tooltipPostCall then
		INV:AddCategoryTooltipLines(GameTooltip, info)
		GameTooltip:Show()
	end
end

--[[
	The slot menu for an item, as entries (INV:OpenSlotMenu turns them into
	Blizzard's menu): { kind = 'button' | 'checkbox' | 'radio' | 'submenu',
	text, checked = fn, onClick = fn, entries }.
	  Edit this category        /sui at the item's category;
	  Add to category...        a radio for None (follow the rules), then one for
	                            every category that is on but Equipment sets, in
	                            list order, the current pin checked;
	  Auto Vendor, Protected    checkboxes; each clears the other.
]]
function INV:SlotMenuEntries(info)
	local itemID = info.itemID
	local key = info.category
	if key == nil then key = self:GetItemCategory(info) end

	local pins = {
		{ kind = 'radio', text = 'None (follow the rules)',
			checked = function() return self:GetPin(itemID) == nil end,
			onClick = function() self:UnpinItem(itemID) end },
	}
	for _, entry in ipairs(self:GetCategoryList()) do
		if entry.enabled and entry.kind ~= 'sets' then
			local id = entry.id
			pins[#pins + 1] = { kind = 'radio', text = entry.name,
				checked = function() return self:GetPin(itemID) == id end,
				onClick = function() self:PinItem(itemID, id) end }
		end
	end

	return {
		{ kind = 'button', text = 'Edit this category', onClick = function() self:EditCategory(key) end },
		{ kind = 'submenu', text = 'Add to category…', entries = pins },
		{ kind = 'checkbox', text = 'Auto Vendor',
			checked = function() return self:IsAutoVendorMarked(itemID) end,
			onClick = function() self:SetAutoVendorMark(itemID, not self:IsAutoVendorMarked(itemID)) end },
		{ kind = 'checkbox', text = 'Protected',
			checked = function() return self:IsProtected(itemID) end,
			onClick = function() self:SetProtected(itemID, not self:IsProtected(itemID)) end },
	}
end

local function AddMenuEntry(parent, entry)
	if entry.kind == 'button' then
		parent:CreateButton(entry.text, entry.onClick)
	elseif entry.kind == 'checkbox' then
		parent:CreateCheckbox(entry.text, entry.checked, entry.onClick)
	elseif entry.kind == 'radio' then
		parent:CreateRadio(entry.text, entry.checked, entry.onClick)
	elseif entry.kind == 'submenu' then
		local sub = parent:CreateButton(entry.text)
		for _, child in ipairs(entry.entries) do AddMenuEntry(sub, child) end
	end
end

-- Opens the slot menu on a slot with Blizzard's MenuUtil (both clients have
-- it). A free slot has no item, so nothing opens; without MenuUtil nothing does.
function INV:OpenSlotMenu(slot)
	local info = slot.info
	if not info or info.empty or not MenuUtil or not MenuUtil.CreateContextMenu then return end
	local entries = self:SlotMenuEntries(info)
	MenuUtil.CreateContextMenu(slot, function(_, root)
		for _, entry in ipairs(entries) do AddMenuEntry(root, entry) end
	end)
end

local function OpenSlotOptions(slot, button)
	if IsControlKeyDown() and button == 'RightButton' then INV:OpenSlotMenu(slot) end
end

function INV:CreateSlot(container, categoryName)
	local categoryFrame = container.categories[categoryName]
	local slotID = #categoryFrame.slots + 1
	local slot, slotName

    assert(categoryFrame, 'Category "'..categoryName..'" does not exist')

    local bagName = container:GetName()
    -- Letters and digits: One bag's and Multi bag's frames differ by bag ID
    -- ('view:bag1', 'view:bag2'), and slot names must not repeat.
    slotName = bagName..'_'..(gsub(categoryName, '(%W)', ''))..'_Slot'..slotID
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
    self.itemSlots[slot] = true
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

	-- The template's junk coin (atlas bags-junkcoin, in both clients' templates),
	-- in the top left of the icon, inside the border, where Blizzard's is on its
	-- button. Shown by key; never written to the button.
	if slot.JunkIcon then
		slot.JunkIcon:ClearAllPoints()
		slot.JunkIcon:SetPoint('TOPLEFT', slot.icon, 'TOPLEFT', 1, 0)
		slot.JunkIcon:Hide()
	end

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

	self:SkinSlot(slot)
	slot:Hide()

	-- tinsert(self.AllSlots, slot)
	-- container.slots[slotID] = slot
	categoryFrame.slots[slotID] = slot

	if slot.tainted then
		st:Error(slot:GetName() .. ' is tainted, will break if used in combat')
	end

	return slot
end

-- Applies the profile's slot size, spot, Slot theme and fonts to a slot made by
-- INV:CreateSlot. Runs on profile changes; skinning a slot again is safe.
function INV:StyleSlot(slot, categoryFrame, container)
	self:SetSlotPosition(slot, categoryFrame, container)
	slot:SetSize(self:GetButtonWidth(), self:GetButtonHeight())
	slot.itemLevel:SetFontObject(st:GetFont(self.config.fonts.icons))
	slot.reagentMarker:SetVertexColor(st.config.profile.colors.text.green:GetRGB())
	self:SkinSlot(slot)
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
	if slot.JunkIcon then slot.JunkIcon:Hide() end
	slot.minDisplayCount = nil
	if slot.Reset then slot:Reset() end
	if slot.info then
		-- self.SlotMap[tostring(slot.info.bagID) .. tostring(slot.info.slotID)] = nil
		slot.info = nil
	end
	slot:SetEnabled(true)
end
