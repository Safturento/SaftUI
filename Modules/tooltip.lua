local st = SaftUI
local TT = st:NewModule('Tooltip', 'AceHook-3.0', 'AceEvent-3.0')

function TT:UpdateGameTooltipPosition()
	local INV = st:GetModule('Inventory')
	local LT = st:GetModule('Loot')

	if GameTooltip:GetAnchorType() == 'ANCHOR_NONE' then
		GameTooltip:ClearAllPoints()
		
		if INV and INV.containers.bag:IsShown() then
			GameTooltip:SetPoint('BOTTOMRIGHT', INV.containers.bag, 'BOTTOMLEFT', -10, 0)
		elseif LT and LT.feed.items[1]:IsShown() then
			GameTooltip:SetPoint('BOTTOMRIGHT', LT.feed, 'BOTTOMLEFT', -10, 0)
		else
			GameTooltip:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -20, 20)
		end
	end
end


function TT:UpdateTooltipDisplay(tooltip)
	local font,size,outline = st:GetFont(self.config.font):GetFont()

	tooltip:SetBackdrop(nil)
	st:SetBackdrop(tooltip, self.config.template)

	if IsModifierKeyDown() and tooltip:GetItem() then
		self:AddItemInfo(tooltip)
	end

	local name = tooltip:GetName()
	
	for i=1, tooltip:NumLines() do
		local left = _G[format('%sTextLeft%d', name, i)]
		if left then
			left:SetFont(font,size,outline)
		end

		local right = _G[format('%sTextRight%d', name, i)]
		if right then
			right:SetFont(font,size,outline)
		end
	end
end

function TT:GameTooltip_OnTooltipSetUnit(tooltip)	
	self:UpdateTooltipDisplay(tooltip)

	local c
	if (select(1, UnitName('mouseover')) == nil) and UnitPlayerControlled('mouseover') then
		c = RAID_CLASS_COLORS[st.my_class]
	elseif UnitPlayerControlled('mouseover') then
		c = RAID_CLASS_COLORS[select(2, UnitClass('mouseover'))]
	else
		c = FACTION_BAR_COLORS[UnitReaction('player', 'mouseover')]
	end

	if c then
		_G[tooltip:GetName()..'TextLeft1']:SetTextColor(c.r, c.g, c.b)
		tooltip.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
		GameTooltipStatusBar.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
	end
end



function TT:GameTooltip_OnTooltipSetItem()
	self:UpdateTooltipDisplay(GameTooltip)
end

function TT:GameTooltip_ShowCompareItem()
	for i=1, 2 do 
		local tt = _G['ShoppingTooltip'..i]
		if tt:IsShown() then
			self:UpdateTooltipDisplay(tt)
			-- local point, frame, relative, x, y = tt:GetPoint(2)
			-- tt:ClearAllPoints()
			-- tt:SetPoint('TOP'..point, frame, 'TOP'..relative, point == 'RIGHT' and -7 or 7, 0)
		end
	end
end

function TT:AddItemInfo(self)
	local itemName, item_link = self:GetItem()
	if not item_link then return end

	local _, _, _, _, _, item_type, item_subtype, _, _, _, _, item_type_id, item_subtype_id, bind_type, expac_id, item_set_id = GetItemInfo(item_link) 

	local item_id = select(2, strsplit(":", string.match(item_link, "item[%-?%d:]+")))

	self:AddDoubleLine('Item ID', item_id)
	self:AddDoubleLine('Item Type', ('%s (%s)'):format(item_type, item_type_id))
	self:AddDoubleLine('Item Sub Type', ('%s (%s)'):format(item_subtype, item_subtype_id))
	self:AddDoubleLine('Expansion ID', expac_id)
	self:AddDoubleLine('Item Set ID', item_set_id)
end

function TT:OnEnable()
	self.config = st.config.profile.tooltip
	
	GameTooltipStatusBar:SetStatusBarTexture(st.BLANK_TEX)
	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint('BOTTOMLEFT', GameTooltip, 'TOPLEFT', 0, 7)
	GameTooltipStatusBar:SetPoint('BOTTOMRIGHT', GameTooltip, 'TOPRIGHT', 0, 7)


	st:SetBackdrop(GameTooltipStatusBar, self.config.template)
	self:SecureHook('GameTooltip_SetDefaultAnchor', 'UpdateGameTooltipPosition')
	self:SecureHookScript(GameTooltip, 'OnTooltipSetSpell', 'UpdateTooltipDisplay')
	self:SecureHookScript(GameTooltip, 'OnTooltipSetItem', 'GameTooltip_OnTooltipSetItem')
	self:SecureHookScript(GameTooltip, 'OnTooltipSetUnit', 'GameTooltip_OnTooltipSetUnit')
	self:SecureHook('GameTooltip_ShowCompareItem')

	self.AllTooltips = {
		GameTooltip,
		ItemRefTooltip,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		ItemRefShoppingTooltip3,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ShoppingTooltip3,
		WorldMapTooltip,
	}
	for _,tooltip in pairs(self.AllTooltips) do
		st:SetTemplate(tooltip)
		st:SetBackdrop(tooltip, self.config.template)
		self:HookScript(tooltip, 'OnShow', 'UpdateTooltipDisplay')
	end

	
	local font = st:GetFont(self.config.font)
	for i=1, 2 do
		local name = 'DropDownList'..i
		local dropdown = _G[name]
		_G[name..'MenuBackdrop']:SetBackdrop(nil)

		st:SetTemplate(dropdown, self.config.template)
	end
end