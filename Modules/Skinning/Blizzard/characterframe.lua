local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

local CHARACTER_SLOTS = {
	[0] = 'Ammo',
	[1] = 'Head',
	[2] = 'Neck',
	[3] = 'Shoulder',
	[4] = 'Shirt',
	[5] = 'Chest',
	[6] = 'Waist',
	[7] = 'Legs',
	[8] = 'Feet',
	[9] = 'Wrist',
	[10] = 'Hands',
	[11] = 'Finger0',
	[12] = 'Finger1',
	[13] = 'Trinket0',
	[14] = 'Trinket1',
	[15] = 'Back',
	[16] = 'MainHand',
	[17] = 'SecondaryHand',
	[18] = 'Ranged',
	[19] = 'Tabard',
}


local equip_slots = {}

local function SkinEquipSlots()

	for ID,slot_name in pairs(CHARACTER_SLOTS) do
		local equip_slot = _G[format('Character%sSlot', slot_name)]
		equip_slot.ID = ID
		equip_slot.slot_name = slot_name
		equip_slot.icon = _G[equip_slot:GetName()..'IconTexture']
		equip_slots[ID] = equip_slot

		equip_slot.item_level = equip_slot:CreateFontString(nil, 'OVERLAY')

		st:StripTextures(equip_slot)
		
		equip_slot.durability = equip_slot:CreateFontString(nil, 'OVERLAY')
		equip_slot.durability:SetPoint('TOPLEFT', 0, 1)

		local anchor, parent, anchorTo, xoff, yoff = equip_slot:GetPoint()
		equip_slot:ClearAllPoints()
		equip_slot:SetPoint(anchor, parent, anchorTo, 0, -7)
		
		st.SkinActionButton(equip_slot)
	end

	CharacterHeadSlot:ClearAllPoints()
	CharacterHeadSlot:SetPoint('TOPLEFT', CharacterFrame.header, 'BOTTOMLEFT', 10, -10)

	CharacterHandsSlot:ClearAllPoints()
	CharacterHandsSlot:SetPoint('TOPRIGHT', CharacterFrame.header, 'BOTTOMRIGHT', -10, -10)

	CharacterMainHandSlot:ClearAllPoints()
	CharacterMainHandSlot:SetPoint('BOTTOMLEFT', CharacterFrame.backdrop, 'BOTTOMLEFT', 94, 10)

	CharacterSecondaryHandSlot:ClearAllPoints()
	CharacterSecondaryHandSlot:SetPoint('TOPLEFT', CharacterMainHandSlot, 'TOPRIGHT', 7, 0)

	CharacterRangedSlot:ClearAllPoints()
	CharacterRangedSlot:SetPoint('TOPLEFT', CharacterSecondaryHandSlot, 'TOPRIGHT', 7, 0)
	
	CharacterAmmoSlot:ClearAllPoints()
	CharacterAmmoSlot:SetPoint('LEFT', CharacterRangedSlot, 'RIGHT', 7, 0)

end

local function UpdateEquipSlot(equip_slot)
	if not equip_slot.ID then return	end

	local item_link = GetInventoryItemLink('player', equip_slot.ID)

	if not item_link then
		st:SetBackdrop(equip_slot, st.config.profile.buttons.template)
	else
		local name, link, quality, ilvl = GetItemInfo(item_link)
		local durability, max_durability = GetInventoryItemDurability(equip_slot.ID)

		if quality then
			local c = ITEM_QUALITY_COLORS[quality]
			equip_slot.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
		else
			st:SetBackdrop(equip_slot, st.config.profile.buttons.template)
		end

		local font = st:GetFont(st.config.profile.buttons.font)

		equip_slot.item_level:SetFontObject(font)
		equip_slot.item_level:SetText(ilvl)

		equip_slot.durability:SetFontObject(font)
		if durability then
			durability = math.floor(100*durability/max_durability)
			equip_slot.durability:SetText(durability..'%')
			local color = {1, 1, 1}

			if durability == 0 then
				color = st.config.profile.colors.text.red
			elseif durability <= 20 then
				color = st.config.profile.colors.text.orange
			elseif durability <= 50 then
				color = st.config.profile.colors.text.yellow
			end
				
			equip_slot.durability:SetTextColor(unpack(color))
		else
			equip_slot.durability:SetText('')
		end
	end
end

SK.FrameSkins.CharacterFrame = function()
	local config = st.config.profile.panels
	
	for _,frame in pairs({
		CharacterFramePortrait,
		CharacterModelFrameRotateLeftButton,
		CharacterModelFrameRotateRightButton
	}) do st:Kill(frame) end
	
	for _,frame in pairs({
		PaperDollFrame,
		ReputationFrame,
		SkillFrame
	}) do st:StripTextures(frame) end
	
	SK:SkinBlizzardPanel(CharacterFrame, CharacterNameText)
	SK:SkinBlizzardPanel(TalentFrame)

	SkinEquipSlots()

	hooksecurefunc('PaperDollItemSlotButton_Update', UpdateEquipSlot)
end