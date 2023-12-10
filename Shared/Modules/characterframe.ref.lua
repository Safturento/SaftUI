local st = SaftUI

local CharacterFrame = st:GetModule('Skinning'):NewModule('CharacterFrame')

local CHARACTER_SLOTS = {
	[INVSLOT_HEAD] = 'Head',
	[INVSLOT_NECK] = 'Neck',
	[INVSLOT_SHOULDER] = 'Shoulder',
	[INVSLOT_BODY] = 'Shirt',
	[INVSLOT_CHEST] = 'Chest',
	[INVSLOT_WAIST] = 'Waist',
	[INVSLOT_LEGS] = 'Legs',
	[INVSLOT_FEET] = 'Feet',
	[INVSLOT_WRIST] = 'Wrist',
	[INVSLOT_HAND] = 'Hands',
	[INVSLOT_FINGER1] = 'Finger0',
	[INVSLOT_FINGER2] = 'Finger1',
	[INVSLOT_TRINKET1] = 'Trinket0',
	[INVSLOT_TRINKET2] = 'Trinket1',
	[INVSLOT_BACK] = 'Back',
	[INVSLOT_MAINHAND] = 'MainHand',
	[INVSLOT_OFFHAND] = 'SecondaryHand',
	[INVSLOT_TABARD] = 'Tabard',
}

local equipSlots = {}

local function SkinSlot(ID, slotName)
	local equipSlot = _G[format('Character%sSlot', slotName)]
	if not equipSlot then return end

	equipSlot.ID = ID
	equipSlot.slotName = slotName
	equipSlot.icon = _G[equipSlot:GetName()..'IconTexture']
	equipSlots[slotName] = equipSlot

	equipSlot.itemLevel = equipSlot:CreateFontString(nil, 'OVERLAY')
	equipSlot.itemLevel:SetPoint("BOTTOMLEFT", 2, 3)
	equipSlot:SetSize(36, 36)


	equipSlot.durability = equipSlot:CreateFontString(nil, 'OVERLAY')
	equipSlot.durability:SetPoint('TOPLEFT', 0, 1)

	--local anchor, parent, anchorTo, xoff, yoff = equipSlot:GetPoint()
	--equipSlot:ClearAllPoints()
	--equipSlot:SetPoint(anchor, parent, anchorTo, 0, -7)

	st:StripTextures(equipSlot)
	st:SkinActionButton(equipSlot)
end

function CharacterFrame:SkinEquipSlots()
	st.map(CHARACTER_SLOTS, SkinSlot)
end

local upgradeQualities = {
	Adventurer = 1,
	Veteran = 2,
	Champion = 3,
	Hero = 4,
	Myth = 5,
}


function CharacterFrame:UpdateEquipSlot(equipSlot)
	if not equipSlot.ID then return end

	local itemLink = GetInventoryItemLink('player', equipSlot.ID)

	if not itemLink then
		st:SetBackdrop(equipSlot, st.config.profile.buttons.template)
	else
		local name, link, quality, ilvl = GetItemInfo(itemLink)
		local durability, maxDurability = GetInventoryItemDurability(equipSlot.ID)

		if quality then
			local c = ITEM_QUALITY_COLORS[quality]
			equipSlot.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
		else
			st:SetBackdrop(equipSlot, st.config.profile.buttons.template)
		end

		local itemLocation = ItemLocation:CreateFromEquipmentSlot(equipSlot.ID)
		local upgradable = C_ItemUpgrade.CanUpgradeItem(itemLocation);
		if upgradable then
			print(itemLink, upgradable)
			local quality, level, maxLevel = tooltipText:match("Upgrade Level: (%w+) (%d)/(%d)")
			slot.isProfessionItem = true
			slot.alwaysShowProfessionsQuality = true
			SetItemCraftingQualityOverlayOverride(slot, upgradeQualities[quality])
		end

		local font = st:GetFont(st.config.profile.buttons.font)

		equipSlot.itemLevel:SetFontObject(font)
		equipSlot.itemLevel:SetText(ilvl)

		equipSlot.durability:SetFontObject(font)
		if durability and not durability == maxDurability then
			durability = math.floor(100*durability/maxDurability)
			equipSlot.durability:SetText(durability..'%')
			local color = {1, 1, 1}

			if durability == 0 then
				color = st.config.profile.colors.text.red
			elseif durability <= 20 then
				color = st.config.profile.colors.text.orange
			elseif durability <= 50 then
				color = st.config.profile.colors.text.yellow
			end

			equipSlot.durability:SetTextColor(unpack(color))
		else
			equipSlot.durability:SetText('')
		end
	end
end

function CharacterFrame:OnInitialize()
	self:SkinEquipSlots()
	self:SecureHook('PaperDollItemSlotButton_Update', 'UpdateEquipSlot')
end