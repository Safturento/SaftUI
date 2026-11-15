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

	-- Looks like the item level on SaftUI's bag slots: the Skinning font, white,
	-- on a dark backing. The font and backing are SaftUI's own; only they are
	-- added to Blizzard's button.
	local itemLevel = button:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(itemLevel, st.config.profile.skinning.font)
	itemLevel:SetTextColor(st:Color('text', 'strong'):GetRGB())
	itemLevel:SetDrawLayer('OVERLAY', 7)
	itemLevel:SetPoint('BOTTOMRIGHT', -3, 3)

	local itemLevelBG = button:CreateTexture(nil, 'OVERLAY')
	itemLevelBG:SetDrawLayer('OVERLAY', 6)
	itemLevelBG:SetPoint('BOTTOMRIGHT', button, -1, 1)
	itemLevelBG:SetPoint('TOPLEFT', itemLevel, -2, 1)
	itemLevelBG:SetTexture(st.BLANK_TEX)
	itemLevelBG:SetAlpha(0.8)
	itemLevelBG:SetVertexColor(0, 0, 0)
	itemLevelBG:Hide()

	-- The upgrade tier icon, its level text and the crafting quality pip. Util's helpers
	-- write fields onto the frame they are given and run Blizzard's overlay functions
	-- on it, so they are given this frame of SaftUI's, a child over the whole slot that
	-- takes no mouse (a plain frame doesn't), never the secure slot button.
	local overlay = CreateFrame('Frame', nil, button)
	overlay:SetAllPoints(button)

	slots[button] = {
		overlay = overlay,
		itemLevel = itemLevel,
		itemLevelBG = itemLevelBG,
		gems = CF:CreateSlotGems(button, SLOT_POSITIONS[slotId]),
	}
end

function CF:UpdateEquipSlot(button)
	local slot = slots[button]
	if not slot then return end

	local itemLink = GetInventoryItemLink('player', button:GetID())

	if itemLink then
		local level = C_Item.GetDetailedItemLevelInfo(itemLink)
		slot.itemLevel:SetText(level or '')
		slot.itemLevelBG:SetShown(level ~= nil)
		Util:SetItemQuality(slot.overlay, itemLink)
	else
		slot.itemLevel:SetText('')
		slot.itemLevelBG:Hide()
		Util:ClearItemQuality(slot.overlay)
	end

	self:UpdateSlotGems(slot.gems, itemLink)
end

-- A profile change or the Skinning page's font: the item level text takes the
-- profile's Skinning font again.
function CF:UpdateConfig()
	for _, slot in pairs(slots) do
		st:ApplyFont(slot.itemLevel, st.config.profile.skinning.font)
		-- A font object can reset an explicit colour, and the profile's Text > Strong may differ.
		slot.itemLevel:SetTextColor(st:Color('text', 'strong'):GetRGB())
	end
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
