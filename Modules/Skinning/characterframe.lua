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

local SHORT_STATS = {
	['Mastery'] = 'Ma',
	['Spirit'] = 'Sp',
	['Haste'] = 'Hs',
	['Crit'] = 'Cr',
}

function shortStat(stat)
	if SHORT_STATS[stat] then
		return stat:gsub(stat, SHORT_STATS[stat])
	end
	return stat
end


local equipSlots = {}

local function SkinSlot(ID, slotName)
	local equipSlot = _G[format('Character%sSlot', slotName)]
	if not equipSlot then return end

	equipSlot.ID = ID
	equipSlot.slotName = slotName
	if st.retail then
		equipSlot.icon = equipSlot:GetItemButtonIconTexture()
	else
		equipSlot.icon = _G[format('Character%sSlotIconTexture', slotName)]
	end
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

	equipSlot.reforgeText = st:CreateFontString(equipSlot.overlay, 'pixel')
	equipSlot.reforgeText:SetPoint('TOPLEFT', 1, -2)

	local reforgeTextBG = equipSlot.overlay:CreateTexture(nil, 'OVERLAY')
	reforgeTextBG:SetDrawLayer('OVERLAY', 7)
	reforgeTextBG:SetPoint('TOPLEFT', equipSlot)
	reforgeTextBG:SetPoint('BOTTOMRIGHT', equipSlot.reforgeText, -1, -1)
	reforgeTextBG:SetTexture(st.BLANK_TEX)
	reforgeTextBG:SetAlpha(0.6)
	reforgeTextBG:SetVertexColor(0,0,0)
	equipSlot.reforgeText.bg = reforgeTextBG

	equipSlot:SetSize(46, 46)

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
	self:SecureHook('PaperDollItemSlotButton_Update', 'UpdateEquipSlot')
	st.map(CHARACTER_SLOTS, SkinSlot)

	if not st.retail then
		CharacterHeadSlot:ClearAllPoints()
		CharacterHeadSlot:SetPoint('TOPLEFT', CharacterFrame.header, 'BOTTOMLEFT', 9, -9)

		CharacterModelScene:ClearAllPoints()
		CharacterModelScene:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 9, 0)

		CharacterHandsSlot:ClearAllPoints()
		CharacterHandsSlot:SetPoint('TOPRIGHT', CharacterFrame.header, 'BOTTOMRIGHT', -9, -9)
	end

	CharacterSecondaryHandSlot:ClearAllPoints()
	CharacterSecondaryHandSlot:SetPoint('BOTTOM', CharacterFrame, 'BOTTOM', 0, 7)

	CharacterMainHandSlot:ClearAllPoints()
	CharacterMainHandSlot:SetPoint('TOPRIGHT', CharacterSecondaryHandSlot, 'TOPLEFT', -7, 0)

	if CharacterRangedSlot then
		CharacterRangedSlot:ClearAllPoints()
		CharacterRangedSlot:SetPoint('TOPLEFT', CharacterSecondaryHandSlot, 'TOPRIGHT', 7, 0)
	end
end

function CF:UpdateEquipSlot(equipSlot)
	if not equipSlot.ID then return end

	local itemLink = GetInventoryItemLink('player', equipSlot.ID)

	if not itemLink then
		st:SetBackdrop(equipSlot, st.config.profile.buttons.template)
	else
		local name, link, quality = GetItemInfo(itemLink)
		local ilvl = GetDetailedItemLevelInfo(itemLink)
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

		local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
		CharacterFrame.ItemLevelText:SetText(('Eq: %d   Avg: %d'):format(avgItemLevelEquipped, avgItemLevel))

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

function CF:InitEquipSlotEnhancements()
	local overlay = st:CreateFrame('frame', 'CharacterFrameItemEnhancementOverlay', PaperDollItemsFrame)
	overlay:SetAllPoints()

	for id, slotName in pairs(CHARACTER_SLOTS) do
		local equipSlot = _G[format('Character%sSlot', slotName)]
		if not equipSlot then return end

		local position = SLOT_POSITIONS[id]

		--local reforgeText = st:CreateFontString(overlay, 'pixel', 'stat -> stat')
		--equipSlot.reforgeText = reforgeText
		--if position == 'LEFT' then
		--	reforgeText:SetPoint('BOTTOMLEFT', equipSlot, 'BOTTOMRIGHT', 7, 0)
		--elseif position == 'RIGHT' then
		--	reforgeText:SetPoint('BOTTOMRIGHT', equipSlot, 'BOTTOMLEFT', -7, 0)
		--elseif position == 'BOTTOM' then
		--	reforgeText:SetPoint('BOTTOM', equipSlot, 'TOP', 0, 7)
		--end


		local gems = {}
		for i=1, 4 do
			local gem = st:CreateFrame('frame', equipSlot:GetName()..'GemSlot'..i, equipSlot)
			gems[i] = gem
			st:SetBackdrop(gem, 'thick')
			gem:SetSize(20, 20)
			gem:Hide()

			gem.icon = gem:CreateTexture(nil, 'OVERLAY')
			st:SkinIcon(gem.icon)
			gem.icon:SetAllPoints()

			gem:SetScript('OnEnter', function(self)
				if self.itemId then
					local _, itemLink = GetItemInfo(self.itemId)
					GameTooltip:SetOwner(self, 'ANCHOR_NONE')
					GameTooltip:ClearAllPoints()
					GameTooltip:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -7)
					GameTooltip:SetHyperlink(itemLink)
					GameTooltip:Show()
				end
			end)

			gem:SetScript('OnLeave', function()
				GameTooltip:Hide()
			end)

			if i == 1 then
				if position == 'LEFT' then
					gem:SetPoint('TOPLEFT', equipSlot, 'TOPRIGHT', 7, 0)
				elseif position == 'RIGHT' then
					gem:SetPoint('TOPRIGHT', equipSlot, 'TOPLEFT', -7, 0)
				elseif position == 'BOTTOM' then
					gem:SetPoint('BOTTOMLEFT', equipSlot, 'TOPLEFT', 0, 7)
				end
			else
				if position == 'LEFT' then
					gem:SetPoint('TOPLEFT', gems[i-1], 'TOPRIGHT', 7, 0)
				elseif position == 'RIGHT' then
					gem:SetPoint('TOPRIGHT', gems[i-1], 'TOPLEFT', -7, 0)
				elseif position == 'BOTTOM' then
					gem:SetPoint('BOTTOMLEFT', gems[i-1], 'TOPLEFT', 0, 7)
				end
			end
		end

		equipSlot.gems = gems
	end
end

function CF:UpdateGems(equipSlot)
	local gems = { GetInventoryItemGems(equipSlot.ID) }
	for i=1, 4 do
		local gem = equipSlot.gems[i]
		if i <= #gems and gems[i] then
			gem:Show()
			gem.itemId = gems[i]
			gem.icon:SetTexture(GetItemIcon(gems[i]))
		else
			gem:Hide()
		end
	end
end



local ScanQueue = {}
function CF:QueueReforgeTextUpdate(equipSlot)
	local equipSlotId = equipSlot.ID
	if not GetInventoryItemID('player', equipSlotId) then return end
	local itemId = GetInventoryItemID('player', equipSlotId)
	ScanQueue[itemId] = equipSlot
	--print('queued for', CHARACTER_SLOTS[equipSlotId], itemId)
	C_Item.RequestLoadItemData(ItemLocation:CreateFromEquipmentSlot(equipSlotId))
	--print('requesting for', CHARACTER_SLOTS[equipSlotId], itemId)
end

function CF:HandleScanEvent(event, itemId)
	--print(itemId)
	if ScanQueue[itemId] then
		--print('scan finished for ', itemId)
		self:UpdateReforgeText(ScanQueue[itemId])
		ScanQueue[itemId] = false
	end
end

function CF:UpdateReforgeText(equipSlot)
	local itemLink = GetInventoryItemLink('player', equipSlot.ID)
	if itemLink then
		local data = st:ScanEquippedItem(equipSlot.ID)
		--print(itemLink, data.reforge and #data.reforge> 0 and data.to)
		if data.reforge and #data.reforge > 0 then
			local from, to = unpack(data.reforge)
			equipSlot.reforgeText:SetFormattedText("%s->%s", shortStat(from), shortStat(to))
		else
			equipSlot.reforgeText:SetText('')
		end
	else
		equipSlot.reforgeText:SetText('')
	end
end

function CF:UpdateEquipSlotEnhancements()
	--print('UpdateEquipSlotEnhancements')
	for id, slotName in pairs(CHARACTER_SLOTS) do
		local equipSlot = _G[format('Character%sSlot', slotName)]
		if not equipSlot then return end

		self:QueueReforgeTextUpdate(equipSlot)
		self:UpdateGems(equipSlot)
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

function CF:SkinSidebarTabs()
	PaperDollSidebarTabs:ClearAllPoints()
	PaperDollSidebarTabs:SetPoint('TOPLEFT', CharacterFrameInsetRight, 'TOPLEFT', 0, 0)

	st:Kill(PaperDollSidebarTabs.DecorRight)
	st:Kill(PaperDollSidebarTabs.DecorLeft)

	st:SetBackdrop(CharacterFrameInsetRight, 'thick')
	CharacterFrameInsetRight:ClearAllPoints()
	CharacterFrameInsetRight:SetPoint('TOPLEFT', CharacterHandsSlot, 'TOPRIGHT', 9, 0)
	CharacterFrameInsetRight:SetPoint('BOTTOMRIGHT', CharacterFrame, 'BOTTOMRIGHT', -7, 7)

	local prev
	for i = 1, #PAPERDOLL_SIDEBARS do
		local tab = _G['PaperDollSidebarTab'..i];
		tab.TabBg:SetTexture()
		tab.Hider:Hide();
		tab.Highlight:Hide();
		--tab.Icon:SetTexture()
		tab.Icon:SetAllPoints(tab)
		tab:ClearAllPoints()
		if prev then
			tab:SetPoint('LEFT', prev, 'RIGHT', 7, 0)
		else
			tab:SetPoint('TOPLEFT', PaperDollSidebarTabs, 'TOPLEFT', 0, 0)
		end
		tab:SetSize(60, 20)
		prev = tab
		st:SkinActionButton(tab)
	end

	self:PositionSidebarTab()
end

function CF:PositionSidebarTab(self, index)
	local width = 180
	local height = 345
	if CharacterStatsPane:IsShown() and not st.retail then
		CharacterStatsPane:ClearAllPoints()
		CharacterStatsPane:SetPoint('TOPLEFT', PaperDollSidebarTab1, 'BOTTOMLEFT', 0, -7)
		CharacterStatsPane:SetSize(width, height)
		st:SetBackdrop(CharacterStatsPane, 'thick')
		CharacterStatsPane.ScrollBox:ClearAllPoints()
		CharacterStatsPane.ScrollBox:SetPoint('TOPLEFT', CharacterStatsPane)
		CharacterStatsPane.ScrollBox:SetSize(width, height)
		st:SkinScrollBar(CharacterStatsPane.ScrollBar)
	elseif PaperDollFrame.TitleManagerPane:IsShown() then
		PaperDollFrame.TitleManagerPane:ClearAllPoints()
		PaperDollFrame.TitleManagerPane:SetPoint('TOPLEFT', PaperDollSidebarTab1, 'BOTTOMLEFT', 0, -7)
		PaperDollFrame.TitleManagerPane:SetSize(width, height)
		PaperDollFrame.TitleManagerPane.ScrollBox:ClearAllPoints()
		PaperDollFrame.TitleManagerPane.ScrollBox:SetPoint('TOPLEFT', PaperDollFrame.TitleManagerPane)
		PaperDollFrame.TitleManagerPane.ScrollBox:SetSize(width, height)
		PaperDollFrame.TitleManagerPane.ScrollBar:Hide()
	elseif PaperDollFrame.EquipmentManagerPane:IsShown() then
		PaperDollFrame.EquipmentManagerPane:ClearAllPoints()
		PaperDollFrame.EquipmentManagerPane:SetPoint('TOPLEFT', PaperDollSidebarTab1, 'BOTTOMLEFT', 0, -7)
		PaperDollFrame.EquipmentManagerPane:SetSize(width, height)
	end
end

local function setTitleItem(item, titleData)
	local currentTitle = GetCurrentTitle();
    item.button.text:SetText(titleData.title)
	item.button:SetEnabled(currentTitle ~= titleData.id)
	item.id = titleData.id
end

local function initTitleItem(item)
	item.button:SetScript('OnClick', function(self)
		SetCurrentTitle(item.id)
		CF.TitleSelectDropdown:Hide()
	end)
end

local function titleSort(a, b) return a.name < b.name; end

local function getTitleDataProvider()
	local dataProvider = CreateDataProvider();

	local titles = GetKnownTitles();
	table.sort(titles, titleSort);
	titles[1].name = PLAYER_TITLE_NONE;

	for _, title in ipairs(titles) do
		dataProvider:Insert({ id = title.id, title = title.name });
	end

	return dataProvider
end

function CF:ToggleTitleSelectDropdown()
	if not self.TitleSelectDropdown then
		local scrollList = st:CreateScrollList('CharacterFrameTitleSelectDropdown',
			self.TitleSelectButton, setTitleItem, initTitleItem)
		scrollList:SetPoint('TOP', CharacterFrame_Header, 'BOTTOM', 0, -6)
		scrollList:SetWidth(200)
		scrollList:SetItemHeight(20)
		scrollList:SetItemSpacing(7)
		scrollList:SetNumItems(10)
		scrollList:Hide()

		self.TitleSelectDropdown = scrollList
	end

	self.TitleSelectDropdown:SetData(getTitleDataProvider(), true)

	if self.TitleSelectDropdown:IsShown() then
		self.TitleSelectDropdown:Hide()
	else
		self.TitleSelectDropdown:Show()
	end
end

function CF:CreateTitleSelector()
	local button = st:CreateButton('CharacterFrameTitleSelectButton', CharacterFrame_Header)
	button:SetPoint('TOPLEFT', CharacterFrameTitleText, 'TOPRIGHT', 5, 0)
	button:SetSize(14, 14)
	self.TitleSelectButton = button

	self:HookScript(button, 'OnClick', 'ToggleTitleSelectDropdown')
end

function CF:SizeCharacterFrame()
	CharacterFrame:SetSize(430, 500)
end

function CF:OnInitialize()
    SK:SkinBlizzardPanel(CharacterFrame, {title = CharacterNameText})
	self:SkinEquipSlots()
	self:InitEquipSlotEnhancements()
	self:CreateTitleSelector()
    --self:SkinStatFrame()

	self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateEquipSlotEnhancements');
	self:RegisterEvent('SPELLS_CHANGED', 'UpdateEquipSlotEnhancements');
	self:RegisterEvent('ITEM_DATA_LOAD_RESULT', 'HandleScanEvent');

	self:SecureHook('PaperDollFrame_UpdateSidebarTabs', 'SkinSidebarTabs')
	self:SecureHook('PaperDollFrame_SetSidebar', 'PositionSidebarTab')

	CharacterFrame:SetSize(430, 500)
	if CharacterFrame_Expand then
		self:SecureHook('CharacterFrame_Collapse', 'SizeCharacterFrame')
		self:SecureHook('CharacterFrame_Expand', 'SizeCharacterFrame')
	else
		self:SecureHook(CharacterFrame, 'UpdateSize', 'SizeCharacterFrame')
		--self:SecureHook(CharacterFrame, 'Collapse', 'SizeCharacterFrame')
	end

	CharacterFrame.ItemLevelText = st:CreateFontString(PaperDollItemsFrame, 'normal', 'Eq: 000 \t Avg: 000')
	CharacterFrame.ItemLevelText:SetPoint('BOTTOMLEFT', CharacterFrame, 'BOTTOMLEFT', 7, 7)
	CharacterFrame.ItemLevelText:SetJustifyH('LEFT')

	if CharacterModelScene then
		st:StripTextures(CharacterModelScene)
		--st:SetBackdrop(CharacterModelScene, st.config.profile.panels.template)
		CharacterModelScene:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 7, 0)
		CharacterModelScene:SetPoint('TOPRIGHT', CharacterHandsSlot, 'TOPLEFT', -7, 0)
		CharacterModelScene:SetPoint('BOTTOM', CharacterMainHandSlot, 'TOP', 0, 7)
		st:Kill(CharacterModelScene.BackgroundTopLeft)
		st:Kill(CharacterModelScene.BackgroundTopRight)
		st:Kill(CharacterModelScene.BackgroundBotLeft)
		st:Kill(CharacterModelScene.BackgroundBotRight)
	end

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

	self:SkinSidebarTabs()
end