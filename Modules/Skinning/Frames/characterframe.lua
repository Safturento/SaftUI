local st = SaftUI
local SK = st:GetModule('Skinning')

local CHARACTER_SLOTS = {
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
	[19] = 'Tabard',
}


local equip_slots = {}

local function SkinSlot(_, slot_name)
	local equip_slot = _G[format('Character%sSlot', slot_name)]
	if not equip_slot then return end

	equip_slot.ID = ID
	equip_slot.slot_name = slot_name
	equip_slot.icon = _G[equip_slot:GetName()..'IconTexture']
	equip_slots[ID] = equip_slot

	equip_slot.item_level = equip_slot:CreateFontString(nil, 'OVERLAY')
	equip_slot:SetSize(36, 36)

	st:StripTextures(equip_slot)

	equip_slot.durability = equip_slot:CreateFontString(nil, 'OVERLAY')
	equip_slot.durability:SetPoint('TOPLEFT', 0, 1)

	local anchor, parent, anchorTo, xoff, yoff = equip_slot:GetPoint()
	equip_slot:ClearAllPoints()
	equip_slot:SetPoint(anchor, parent, anchorTo, 0, -7)

	st:SkinActionButton(equip_slot)
end

local function SkinEquipSlots()

	st.map(CHARACTER_SLOTS, SkinSlot)

	CharacterHeadSlot:ClearAllPoints()
	CharacterHeadSlot:SetPoint('TOPLEFT', CharacterFrame.header, 'BOTTOMLEFT', 10, -10)

	CharacterHandsSlot:ClearAllPoints()
	CharacterHandsSlot:SetPoint('TOPRIGHT', CharacterFrame.header, 'BOTTOMRIGHT', -10, -10)

	CharacterMainHandSlot:ClearAllPoints()
	CharacterMainHandSlot:SetPoint('TOPLEFT', CharacterWristSlot, 'BOTTOMRIGHT', 54, -7)

	CharacterSecondaryHandSlot:ClearAllPoints()
	CharacterSecondaryHandSlot:SetPoint('TOPLEFT', CharacterMainHandSlot, 'TOPRIGHT', 7, 0)
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

local stats = {
	{
		name = 'Primary',
		items = {
			{
				name = 'Stamina',
				parent = CharacterStatFrame3
			},
			{
				name = 'Strength',
				parent = CharacterStatFrame1
			},
			{
				name = 'Agility',
				parent = CharacterStatFrame2
			},
			{
				name = 'Intellect',
				parent = CharacterStatFrame4
			},
			{
				name = 'Spirit',
				parent = CharacterStatFrame5
			},
		},

	},
	melee = {
		{
			name = 'Hit Rating',
			parent = CharacterAttackFrame,
		},
		{
			name = 'Attack Power',
			parent = CharacterAttackPowerFrame,
		}
	},
	ranged = {

	},
	spell = {

	},
	resistances = {
		
	},
	defensive = {
		{
			name = 'Armor',
			parent = CharacterStatFrame6
		},
		{
			name = 'Block',
			text = function() return GetShieldBlock() end
		},
		{
			name = 'Parry',
			text = function() return GetParryChance() end
		}
	},
}

local function UpdateStatsScroll()
	
end

local function SkinStatFrame()
	st:Kill(CharacterAttributesFrame)
	st:Kill(CharacterResistanceFrame)

	CharacterStatsFrame = CreateFrame('ScrollFrame', 'CharacterStatsFrame', PaperDollFrame, 'FauxScrollFrameTemplate')
	CharacterStatsFrame:SetScript('OnVerticalScroll', UpdateStatsScroll)
	CharacterStatsFrame:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 7, 0)
	CharacterStatsFrame:SetPoint('BOTTOMRIGHT', CharacterTrinket0Slot, 'BOTTOMLEFT', -7, 0)
	CharacterStatsFrame:SetFrameLevel(CharacterModelFrame:GetFrameLevel()+4)
	CharacterStatsFrame.offset = 0

	CharacterStatsFrame.rows = {}
	local prev
	for i=1, 12 do
		local row = CreateFrame('frame', nil, CharacterStatsFrame)
		st:SetBackdrop(row, st.config.profile.panels.template)
		row.outer_shadow:Hide()

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

local function SetCharacterFrameTitle()
	--local c = RAID_CLASS_COLORS[st.my_class]
	--local text = st.StringFormat:ColorString(UnitLevel('player'), c.r, c.g, c.b) .. ' ' .. (UnitPVPName('player') or UnitName('player'))
	--local guild, title, rank = GetGuildInfo("player")
	--if guild then
	--	text = text .. ' <'.. guild .. '>'
	--end
	--
	--CharacterNameText:SetText(text)
end


SK.FrameSkins.CharacterFrame = function()
	local config = st.config.profile.panels
	
	for _,frame in pairs({
		CharacterFramePortrait,
		CharacterModelFrameRotateLeftButton,
		CharacterModelFrameRotateRightButton,
		CharacterLevelText,
		CharacterGuildText,
	}) do st:Kill(frame) end

	for _,frame in pairs({
		PaperDollFrame,
		ReputationFrame,
		SkillFrame,
		CharacterFrame.NineSlice
	}) do st:StripTextures(frame) end
	--
	SK:SkinBlizzardPanel(CharacterFrame, {fix_padding = true, title = CharacterNameText})
	--
	--CharacterModelFrame:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 7, 0)
	--CharacterModelFrame:SetPoint('BOTTOMRIGHT', CharacterTrinket0Slot, 'BOTTOMLEFT', -7, 0)
	--
	--SkinEquipSlots()
	---- SkinStatFrame()
	--
	--PaperDollFrame:HookScript('OnEvent', SetCharacterFrameTitle)
	--CharacterFrame:HookScript('OnEvent', SetCharacterFrameTitle)
	--CharacterFrame:HookScript('OnShow', SetCharacterFrameTitle)
	--hooksecurefunc('PaperDollItemSlotButton_Update', UpdateEquipSlot)

end