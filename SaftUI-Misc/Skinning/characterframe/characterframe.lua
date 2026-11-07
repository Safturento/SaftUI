-- The character frame keeps Blizzard's own look. This module only adds item
-- information on top of it: per-slot item level, the upgrade-track indicator,
-- gems, and the equipped/average item level text. Quality colour comes from
-- Blizzard's own IconBorder, which PaperDollItemSlotButton_Update already sets.
local st = SaftUI

local SK =  st:GetModule('Skinning')
local Util = st:GetModule('Utilities')
local CF = SK:NewModule('CharacterFrame')

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
	[INVSLOT_RANGED] = 'Ranged',
}

-- Which side of the slot its gems are laid out on.
local SLOT_POSITIONS = {
	[INVSLOT_HEAD] = 'LEFT',
	[INVSLOT_NECK] = 'LEFT',
	[INVSLOT_SHOULDER] = 'LEFT',
	[INVSLOT_BODY] = 'LEFT',
	[INVSLOT_CHEST] = 'LEFT',
	[INVSLOT_WAIST] = 'RIGHT',
	[INVSLOT_LEGS] = 'RIGHT',
	[INVSLOT_FEET] = 'RIGHT',
	[INVSLOT_WRIST] = 'LEFT',
	[INVSLOT_HAND] = 'RIGHT',
	[INVSLOT_FINGER1] = 'RIGHT',
	[INVSLOT_FINGER2] = 'RIGHT',
	[INVSLOT_TRINKET1] = 'RIGHT',
	[INVSLOT_TRINKET2] = 'RIGHT',
	[INVSLOT_BACK] = 'LEFT',
	[INVSLOT_MAINHAND] = 'BOTTOM',
	[INVSLOT_OFFHAND] = 'BOTTOM',
	[INVSLOT_TABARD] = 'LEFT',
	[INVSLOT_RANGED] = 'BOTTOM',
}

-- Our per-slot additions, keyed by Blizzard's slot button. Kept in a private
-- table so nothing is written onto Blizzard's frames.
local slots = {}

local function SetupSlot(slotId, slotName)
	local button = _G[format('Character%sSlot', slotName)]
	if not button then return end

	local itemLevel = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmall')
	itemLevel:SetDrawLayer('OVERLAY', 7)
	itemLevel:SetPoint('BOTTOMRIGHT', -2, 2)

	slots[button] = {
		itemLevel = itemLevel,
		gems = CF:CreateSlotGems(button, SLOT_POSITIONS[slotId]),
	}
end

function CF:UpdateEquipSlot(button)
	local slot = slots[button]
	if not slot then return end

	local itemLink = GetInventoryItemLink('player', button:GetID())

	if itemLink then
		slot.itemLevel:SetText(C_Item.GetDetailedItemLevelInfo(itemLink) or '')
		Util:SetItemQuality(button, itemLink)
	else
		slot.itemLevel:SetText('')
		Util:ClearItemQuality(button)
	end

	self:UpdateSlotGems(slot.gems, itemLink)
end

function CF:UpdateAllEquipSlots()
	for button in pairs(slots) do
		self:UpdateEquipSlot(button)
	end
end

-- Blizzard's item level stat reads as a single number; show equipped and average.
function CF:UpdateItemLevelText(statFrame, unit)
	if unit ~= 'player' or not statFrame.Value then return end

	local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
	statFrame.Value:SetFormattedText('Eq: %d   Avg: %d', avgItemLevelEquipped, avgItemLevel)
end

function CF:OnEnable()
	st.map(CHARACTER_SLOTS, SetupSlot)

	self:SecureHook('PaperDollItemSlotButton_Update', 'UpdateEquipSlot')
	self:SecureHook('PaperDollFrame_SetItemLevel', 'UpdateItemLevelText')

	-- Gem data can arrive after the slot button's own update has run.
	self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateAllEquipSlots')
	self:RegisterEvent('SPELLS_CHANGED', 'UpdateAllEquipSlots')

	self:UpdateAllEquipSlots()
end
