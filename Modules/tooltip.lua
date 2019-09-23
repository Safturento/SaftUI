local st = SaftUI
local TT = st:NewModule('Tooltip', 'AceHook-3.0', 'AceEvent-3.0')

function TT:UpdateGameTooltipPosition()
	local INV = st:GetModule('Inventory')

	-- if GameTooltip:GetAnchorType() == 'ANCHOR_NONE' then
	-- 	GameTooltip:ClearAllPoints()
		
	-- 	if INV and INV.containers.bag:IsShown() then
	-- 		GameTooltip:SetPoint('BOTTOMRIGHT', INV.containers.bag, 'BOTTOMLEFT', -10, 0)
	-- 	else
	-- 		GameTooltip:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -10, 10)
	-- 	end
	-- end
end

function TT:UpdateTooltipDisplay(tooltip)
	local font,size,outline = st:GetFont(self.config.font):GetFont()

	tooltip:SetBackdrop(nil)
	st:SetBackdrop(tooltip, self.config.template)

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
			local point, frame, relative, x, y = tt:GetPoint()
			tt:ClearAllPoints()
			tt:SetPoint(point, frame, relative, point == 'TOPRIGHT' and -7 or 7, 0)
		end
	end
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
end