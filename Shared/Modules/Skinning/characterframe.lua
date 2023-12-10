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
}

local equipSlots = {}

local function SkinSlot(ID, slotName)
	local equipSlot = _G[format('Character%sSlot', slotName)]
	if not equipSlot then return end

	equipSlot.ID = ID
	equipSlot.slotName = slotName
	equipSlot.icon = equipSlot:GetItemButtonIconTexture()
	equipSlots[slotName] = equipSlot

	equipSlot.IconBorder:SetAlpha(0)

	equipSlot.overlay = CreateFrame('frame', nil, equipSlot)
	equipSlot.overlay:SetAllPoints()
	equipSlot.overlay:SetFrameLevel(equipSlot:GetFrameLevel() + 1)

	equipSlot.itemLevel = equipSlot.overlay:CreateFontString(nil, 'OVERLAY')
	equipSlot.itemLevel:SetPoint('BOTTOMRIGHT', 1, 1)

	local itemLevelBG = equipSlot.overlay:CreateTexture(nil, 'OVERLAY')
	itemLevelBG:SetDrawLayer('OVERLAY', 7)
	itemLevelBG:SetPoint('BOTTOMRIGHT', equipSlot)
	itemLevelBG:SetPoint('TOPLEFT', equipSlot.itemLevel, -2, 1)
	itemLevelBG:SetTexture(st.BLANK_TEX)
	itemLevelBG:SetAlpha(0.8)
	itemLevelBG:SetVertexColor(0,0,0)
	equipSlot.itemLevel.bg = itemLevelBG

	equipSlot:SetSize(36, 36)

	st:SkinIcon(equipSlot.icon, nil, equipSlot)

	equipSlot.durability = equipSlot:CreateFontString(nil, 'OVERLAY')
	equipSlot.durability:SetPoint('TOPLEFT', 0, 1)

	if not (slotName == 'MainHand' or slotName == 'SecondaryHand') then
		local anchor, parent, anchorTo, xoff, yoff = equipSlot:GetPoint()
		equipSlot:ClearAllPoints()
		equipSlot:SetPoint(anchor, parent, anchorTo, 0, -7)
	end

	st:StripTextures(equipSlot)
	st:SkinActionButton(equipSlot)
end

function CF:SkinEquipSlots()
	--CharacterHeadSlot:ClearAllPoints()
	--CharacterHeadSlot:SetPoint('TOPLEFT', CharacterFrame.header, 'BOTTOMLEFT', 10, -10)
	--
	--CharacterHandsSlot:ClearAllPoints()
	--CharacterHandsSlot:SetPoint('TOPRIGHT', CharacterFrame.header, 'BOTTOMRIGHT', -10, -10)

	--CharacterMainHandSlot:ClearAllPoints()
	--CharacterMainHandSlot:SetPoint('TOPLEFT', CharacterWristSlot, 'BOTTOMRIGHT', 54, -7)
	--
	--CharacterSecondaryHandSlot:ClearAllPoints()
	--CharacterSecondaryHandSlot:SetPoint('TOPLEFT', CharacterMainHandSlot, 'TOPRIGHT', 7, 0)

	self:SecureHook('PaperDollItemSlotButton_Update', 'UpdateEquipSlot')
	st.map(CHARACTER_SLOTS, SkinSlot)
end

function CF:UpdateEquipSlot(equipSlot)
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

		local font = st:GetFont(st.config.profile.buttons.font)

		equipSlot.itemLevel:SetFontObject(font)
		equipSlot.itemLevel:SetText(ilvl)

		Util:SetItemUpgradeQualityForEquipmentSlot(equipSlot, equipSlot.ID)

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


function CF:SkinStatFrame()
	st:Kill(CharacterAttributesFrame)
	st:Kill(CharacterResistanceFrame)

	CharacterStatsFrame = CreateFrame('ScrollFrame', 'CharacterStatsFrame', PaperDollFrame, 'FauxScrollFrameTemplate')
	CharacterStatsFrame:SetScript('OnVerticalScroll', UpdateStatsScroll)
	CharacterStatsFrame:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 7, 0)
	CharacterStatsFrame:SetPoint('BOTTOMRIGHT', CharacterTrinket0Slot, 'BOTTOMLEFT', -7, 0)
	--CharacterStatsFrame:SetFrameLevel(CharacterModelFrame:GetFrameLevel()+4)
	CharacterStatsFrame.offset = 0

	CharacterStatsFrame.rows = {}
	local prev
	for i=1, 12 do
		local row = CreateFrame('frame', nil, CharacterStatsFrame)
		st:SetBackdrop(row, st.config.profile.panels.template)
		--row.outer_shadow:Hide()

		if prev then
			row:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -1)
		else
			row:SetPoint('TOPLEFT', CharacterStatsFrame)
		end
		row:SetPoint('RIGHT', CharacterStatsFrame)
		row:SetHeight(24)

		row.stat_name = row:CreateFontString(nil, 'OVERLAY')
		row.stat_name:SetPoint('LEFT', 10, 0)
		row.stat_name:SetFontObject(st:GetFont(st.config.profile.panels.font))
		row.stat_name:SetText('Stat'..i)

		row.stat_value = row:CreateFontString(nil, 'OVERLAY')
		row.stat_value:SetPoint('RIGHT', -10, 0)
		row.stat_value:SetFontObject(st:GetFont(st.config.profile.panels.font))
		row.stat_value:SetText(i*1000)

		prev = row
		CharacterStatsFrame.rows[i] = row
	end

	st:SetBackdrop(CharacterStatsFrame, st.config.profile.panels.template)
end

function CF:OnInitialize()
    SK:SkinBlizzardPanel(CharacterFrame, {title = CharacterNameText})
	self:SkinEquipSlots()
    --self:SkinStatFrame()

	st:StripTextures(CharacterModelScene)
	st:SetBackdrop(CharacterModelScene, st.config.profile.panels.template)

    for _,frame in pairs({
		CharacterFramePortrait,
		CharacterModelFrameRotateLeftButton,
		CharacterModelFrameRotateRightButton,
		CharacterLevelText,
		CharacterGuildText,
		PaperDollInnerBorderBottom,
		PaperDollInnerBorderBottom2
	}) do st:Kill(frame) end

	for _,frame in pairs({
		PaperDollFrame,
		ReputationFrame,
		SkillFrame,
		CharacterFrame.NineSlice
	}) do st:StripTextures(frame) end
end