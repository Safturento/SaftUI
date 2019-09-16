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

	st:SetTemplate(tooltip)
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

function TT:OnEnable()
	self.config = st.config.profile.tooltip
	GameTooltip._SetHeight = GameTooltip.SetHeight
	GameTooltip.SetHeight = st.dummy
	GameTooltipStatusBar:SetStatusBarTexture(st.BLANK_TEX)
	st:SetBackdrop(GameTooltipStatusBar, self.config.template)
	self:SecureHook('GameTooltip_SetDefaultAnchor', 'UpdateGameTooltipPosition')
	self:SecureHookScript(GameTooltip, 'OnTooltipSetSpell', 'UpdateTooltipDisplay')
	-- self:SecureHookScript(GameTooltip, 'OnTooltipCleared', 'UpdateTooltipDisplay')
	self:SecureHookScript(GameTooltip, 'OnTooltipSetItem', 'UpdateTooltipDisplay')
	self:SecureHookScript(GameTooltip, 'OnTooltipSetUnit', 'UpdateTooltipDisplay')

	self.AllTooltips = {
		GameTooltip,
		ItemRefTooltip,
		ItemRefShoppingTooltip1,
		ItemRefShoppingTooltip2,
		ItemRefShoppingTooltip3,
		ShoppingTooltip1,
		ShoppingTooltip2,
		ShoppingTooltip3,
		-- WorldMapTooltip,
		WorldMapTooltip,
		WorldMapCompareTooltip1,
		WorldMapCompareTooltip2,
		WorldMapCompareTooltip3,
	}
	for _,tooltip in pairs(self.AllTooltips) do
		st:SetTemplate(tooltip)
		st:SetBackdrop(tooltip, self.config.template)
		if not self.hooked then
			self:HookScript(tooltip, 'OnShow', 'UpdateTooltipDisplay')
			self.hooked = true
		end
	end
end