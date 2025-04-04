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

CF.SLOT_POSITIONS = {
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

local function shortStat(stat)
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
	equipSlot.icon = _G[format('Character%sSlotIconTexture', slotName)]

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

	CF:AddEquipSlotGems(equipSlot)

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

	CharacterHeadSlot:ClearAllPoints()
	CharacterHeadSlot:SetPoint('TOPLEFT', CharacterFrame.header, 'BOTTOMLEFT', 9, -9)

	CharacterModelScene:ClearAllPoints()
	CharacterModelScene:SetPoint('TOPLEFT', CharacterHeadSlot, 'TOPRIGHT', 9, 0)

	CharacterHandsSlot:ClearAllPoints()
	CharacterHandsSlot:SetPoint('TOPRIGHT', CharacterFrame.header, 'BOTTOMRIGHT', -9, -9)

	CharacterSecondaryHandSlot:ClearAllPoints()
	if st.retail then
		CharacterSecondaryHandSlot:SetPoint('BOTTOMLEFT', CharacterFrame, 'BOTTOM', 3, 7)
	else
		CharacterSecondaryHandSlot:SetPoint('BOTTOM', CharacterFrame, 'BOTTOM', 0, 7)
	end

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
		local name, link, quality = C_Item.GetItemInfo(itemLink)
		local ilvl = C_Item.GetDetailedItemLevelInfo(itemLink)
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
	for slotName, equipSlot in pairs(equipSlots) do
		self:QueueReforgeTextUpdate(equipSlot)
		self:UpdateEquipSlotGems(equipSlot)
	end
end

function CF:SkinStatFrame()
	if not CharacterStatsPane then return end

	CharacterStatsPane:SetParent(PaperDollFrame)
	CharacterStatsPane:ClearAllPoints()
	CharacterStatsPane:SetWidth(180)
	CharacterStatsPane:SetPoint('TOPLEFT', CharacterFrame, 'TOPRIGHT', 7, 0)
	st:SetBackdrop(CharacterStatsPane, 'thicktransparent')

	if CharacterStatsPane.ScrollBar then
		self:SkinClassicStatFrame()
	else
		self:SkinRetailStatFrame()
	end

	local statsButton = st:CreateButton(nil, PaperDollFrame, 'stats')
	statsButton:SetPoint("BOTTOMRIGHT", CharacterFrame, -7, 7)
	statsButton:SetSize(70, 20)
	self:HookScript(statsButton, 'OnClick', 'ToggleStatsFrame')
end

function CF:SkinClassicStatFrame()

	CharacterStatsPane:SetHeight(CharacterFrame:GetHeight())

	st:SkinScrollBar(CharacterStatsPane.ScrollBar)
	CharacterStatsPane.ScrollBar:ClearAllPoints()
	CharacterStatsPane.ScrollBar:SetPoint('TOPLEFT', CharacterStatsPane, 'TOPRIGHT', 7, 1)
	CharacterStatsPane.ScrollBar:SetPoint('BOTTOMLEFT', CharacterStatsPane, 'BOTTOMRIGHT', 7, -1)
	CharacterStatsPane.ScrollBox:ClearAllPoints()
	CharacterStatsPane.ScrollBox:SetPoint('TOPLEFT', 0, 0)
	CharacterStatsPane.ScrollBox:SetHeight(CharacterFrame:GetHeight())
	CharacterStatsPane.ScrollBox:SetPadding(10)

	for i = 1, 7 do
		local categoryFrame = _G['CharacterStatsPaneCategory'..i]
		st:StripTextures(categoryFrame)
		categoryFrame.NameText:SetFontObject(st:GetFont('normal_med'))
		categoryFrame.NameText:SetHeight(26)
		local toolbar = _G[categoryFrame:GetName() .. 'Toolbar']
		toolbar:SetHeight(categoryFrame.NameText:GetHeight())
		toolbar:ClearAllPoints()
		toolbar:SetPoint('TOPLEFT')
		toolbar:SetPoint('RIGHT')
	end

	self:SecureHook('PaperDollFrame_UpdateStatCategory', 'UpdateClassicStatCategory')
	self:SecureHook('PaperDollFrame_ExpandStatCategory', 'UpdateClassicStatCategory')
	self:SecureHook('PaperDollFrame_CollapseStatCategory', 'UpdateClassicStatCategory')
end

function CF:UpdateClassicStatCategory(categoryFrame)
	local i = 1
	local statFrame = _G[categoryFrame:GetName().."Stat"..i];
	while statFrame do
		if i == 1 then
			statFrame:ClearAllPoints(statFrame)
			statFrame:SetPoint('TOPLEFT' ,_G[categoryFrame:GetName() .. 'Toolbar'], 'BOTTOMLEFT', 10, -13)
			statFrame:SetPoint('RIGHT' , categoryFrame, 'RIGHT', 0, 0)
		end

		statFrame.Label:SetFontObject(st:GetFont('normal'))
		statFrame.Label:SetTextColor(unpack(st.config.profile.colors.text.yellow))
		statFrame.Value:SetFontObject(st:GetFont('normal'))
		statFrame:SetHeight(20)

		i = i + 1
		statFrame = _G[categoryFrame:GetName().."Stat"..i];
	end
end

function CF:SkinRetailStatFrame()
	CharacterStatsPane:SetHeight(330)
	st:StripTextures(CharacterStatsPane)
	for _, categoryFrame in pairs({
		CharacterStatsPane.ItemLevelCategory,
		CharacterStatsPane.AttributesCategory,
		CharacterStatsPane.EnhancementsCategory
	}) do
		categoryFrame.Background:SetTexture()
		categoryFrame.Title:SetFontObject(st:GetFont('normal_med'))
	end

	CharacterStatsPane.ItemLevelFrame.Value:SetFontObject(st:GetFont('normal_med'))

	self:SecureHook('PaperDollFrame_SetLabelAndText', 'UpdateRetailStatFrame')
end

function CF:UpdateRetailStatFrame(statFrame, label, text, isPercentage, numericValue)
	statFrame:SetHeight(20)
	if statFrame.Label then statFrame.Label:SetFontObject(st:GetFont('normal')) end
	if statFrame.Value then statFrame.Value:SetFontObject(st:GetFont('normal')) end
end

function CF:ToggleStatsFrame()
	ToggleFrame(CharacterStatsPane)
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
		scrollList:SetFrameStrata('HIGH')
		scrollList:Hide()

		self.TitleSelectDropdown = scrollList
	end

	self.TitleSelectDropdown:SetData(getTitleDataProvider(), true)

	ToggleFrame(self.TitleSelectDropdown)
end

function CF:CreateTitleSelector()
	local button = st:CreateButton('CharacterFrameTitleSelectButton', PaperDollFrame)
	button:SetFrameLevel(CharacterFrame_Header:GetFrameLevel() + 2)
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
	if CharacterFrame_Collapse then
		CharacterFrame_Collapse()
		CharacterFrame_Collapse = st.dummy
		CharacterFrame_Expand = st.dummy
	elseif CharacterFrame.Collapse then
		CharacterFrame:Collapse()
		CharacterFrame.Collapse = st.dummy
		CharacterFrame.Expand = st.dummy
		CharacterFrame.UpdateSize = st.dummy
	end

	if CharacterFrameExpandButton then
		st:Kill(CharacterFrameExpandButton)
	end

	self:SizeCharacterFrame()

	self:SkinEquipSlots()
	self:CreateTitleSelector()
    self:SkinStatFrame()

	self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', 'UpdateEquipSlotEnhancements');
	self:RegisterEvent('SPELLS_CHANGED', 'UpdateEquipSlotEnhancements');
	self:RegisterEvent('ITEM_DATA_LOAD_RESULT', 'HandleScanEvent');

	self:SecureHook('PaperDollFrame_UpdateSidebarTabs', 'SkinSidebarTabs')
	self:SecureHook('PaperDollFrame_SetSidebar', 'PositionSidebarTab')

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