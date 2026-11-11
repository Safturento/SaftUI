
local st = SaftUI
local TT = st:NewModule('Tooltip')

-- The SaftUI backdrop frame of each skinned Blizzard frame (the tooltips, the
-- status bar, the dropdown lists). Kept here, not on the frames (rule 1 in
-- .agents/taint.md).
local backdrops = setmetatable({}, { __mode = 'k' })

-- A tooltip showing a unit -> the class or reaction color its border and the
-- status bar's took (GameTooltip_OnTooltipSetUnit), until it shows again.
local unitColors = setmetatable({}, { __mode = 'k' })

-- Draws the Tooltip page's Theme and Background on one of Blizzard's frames, as
-- kind: 'tooltip' for the tooltips and dropdown lists, 'bar' for the status bar.
local function SkinBackdrop(frame, kind)
	return st:SetBackdropIn(backdrops, frame, TT.config.theme, TT.config.background, kind)
end

-- A unit tooltip's border, and the status bar's, in the unit's color.
local function ColorUnitBorders(tooltip, c)
	local backdrop = backdrops[tooltip]
	if backdrop then st:SetBorderColor(backdrop, c.r, c.g, c.b) end
	backdrop = backdrops[GameTooltipStatusBar]
	if backdrop then st:SetBorderColor(backdrop, c.r, c.g, c.b) end
end

function TT:UpdateTooltipDisplay(tooltip)
	-- Drawn again, so in the theme's border until the unit hook colors it.
	unitColors[tooltip] = nil
	SkinBackdrop(tooltip, 'tooltip')
	--tooltip.NineSlice:Hide()

	if IsModifierKeyDown() and tooltip.GetItem and tooltip:GetItem() then
		self:AddItemInfo(tooltip)
	end

	self:UpdateTooltipFonts(tooltip)
end

-- SaftUI's font on every line. The tooltip makes its line font strings as it
-- first needs them, in Blizzard's font, so lines added after OnShow (an addon's
-- AddLine followed by Show, like the loot roll lines) are styled again from the
-- post-hook on Show.
-- Show runs often (every tooltip refresh), so only touch lines not in the font yet.
local function StyleLine(line, font, size, outline)
	if not line then return end
	local current, currentSize, currentOutline = line:GetFont()
	if current ~= font or currentSize ~= size or currentOutline ~= outline then
		line:SetFont(font, size, outline)
	end
end

function TT:UpdateTooltipFonts(tooltip)
	local font,size,outline = st:GetFont(self.config.font):GetFont()
	local name = tooltip:GetName()

	for i=1, tooltip:NumLines() do
		StyleLine(_G[format('%sTextLeft%d', name, i)], font, size, outline)
		StyleLine(_G[format('%sTextRight%d', name, i)], font, size, outline)
	end
end

-- A unit's class or reaction can be a secret value (a world-cursor unit on
-- Forever), and SaftUI's color tables can't be indexed with one. A secret class
-- takes Blizzard's own class color (C_ClassColor.GetClassColor takes a secret,
-- and its color goes straight into the setters), as oUF's health bar does; a
-- secret reaction leaves the tooltip uncolored.
local function ClassColor(class)
	if issecretvalue(class) then
		return C_ClassColor and C_ClassColor.GetClassColor(class)
	end
	return st.config.profile.colors.class[class]
end

local function ReactionColor(reaction)
	if issecretvalue(reaction) then return end
	return st.config.profile.colors.reaction[reaction]
end

function TT:GameTooltip_OnTooltipSetUnit(tooltip)
	--self:UpdateTooltipDisplay(tooltip)

	local c
	if (select(1, UnitName('mouseover')) == nil) and UnitPlayerControlled('mouseover') then
		c = ClassColor(st.my_class)
	elseif UnitPlayerControlled('mouseover') then
		c = ClassColor(select(2, UnitClass('mouseover')))
	else
		c = ReactionColor(UnitReaction('player', 'mouseover'))
	end

	if c then
		_G[tooltip:GetName()..'TextLeft1']:SetTextColor(c.r, c.g, c.b)
		ColorUnitBorders(tooltip, c)
	end
	unitColors[tooltip] = c
end

-- After a theme recolor (st:RecolorThemed gave every backdrop the theme's
-- border): a unit tooltip that's still showing takes its unit's color back.
function TT:OnColorsChanged(group)
	if group ~= 'theme' then return end
	for tooltip, c in pairs(unitColors) do
		if tooltip:IsShown() then ColorUnitBorders(tooltip, c) end
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

	local _, _, _, _, _, item_type, item_subtype, _, _, _, _, item_type_id, item_subtype_id, bind_type, expac_id, item_set_id = C_Item.GetItemInfo(item_link)

	if not item_type then return end
	local item_id = select(2, strsplit(":", string.match(item_link, "item[%-?%d:]+")))
	self:AddDoubleLine('Item ID', item_id)
	self:AddDoubleLine('Item Type', ('%s (%s)'):format(item_type, item_type_id or '??'))
	self:AddDoubleLine('Item Sub Type', ('%s (%s)'):format(item_subtype, item_subtype_id or '??'))
	self:AddDoubleLine('Expansion ID', expac_id)
	self:AddDoubleLine('Item Set ID', item_set_id)
end

-- A profile change: re-applies the theme to every skinned tooltip, the
-- status bar and the dropdown lists, and the default tooltip's position
-- (tooltipposition.lua). Fonts are applied each time a tooltip shows
-- (UpdateTooltipDisplay), so they follow the profile already.
function TT:UpdateConfig()
	if not self.AllTooltips then return end -- not enabled

	self:ApplyTooltipHolder()

	SkinBackdrop(GameTooltipStatusBar, 'bar')
	for _, tooltip in pairs(self.AllTooltips) do
		SkinBackdrop(tooltip, 'tooltip')
	end
	for i = 1, 2 do
		local dropdown = _G['DropDownList'..i]
		if dropdown then
			SkinBackdrop(dropdown, 'tooltip')
		end
	end
end

function TT:OnEnable()
	st:BindModuleConfig(self, 'tooltip')

	GameTooltipStatusBar:SetStatusBarTexture(st.BLANK_TEX)
	GameTooltipStatusBar:ClearAllPoints()
	GameTooltipStatusBar:SetPoint('BOTTOMLEFT', GameTooltip, 'TOPLEFT', 0, 7)
	GameTooltipStatusBar:SetPoint('BOTTOMRIGHT', GameTooltip, 'TOPRIGHT', 0, 7)

	SkinBackdrop(GameTooltipStatusBar, 'bar')
	self:SetupTooltipPosition()
	--self:SecureHookScript(GameTooltip, 'OnTooltipSetSpell', 'UpdateTooltipDisplay')
	--self:SecureHook(GameTooltip, 'GetItem', 'GameTooltip_OnTooltipSetItem')
	self:SecureHook(GameTooltip, 'GetUnit', 'GameTooltip_OnTooltipSetUnit')
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
		SkinBackdrop(tooltip, 'tooltip')
		tooltip.NineSlice:SetAlpha(0)
		if tooltip.CloseButton then
			tooltip.CloseButton:Hide()
			st:CreateCloseButton(tooltip)
		end
	end


	-- A post-hook (rule 2 in .agents/taint.md): AceHook's plain HookScript
	-- replaces Blizzard's OnShow handler with an addon closure. This only ever
	-- hooked GameTooltip (the first in the list above), so that stays the case.
	if not self:IsHooked(GameTooltip, 'OnShow') then
		self:SecureHookScript(GameTooltip, 'OnShow', 'UpdateTooltipDisplay')
	end
	-- Also a post-hook (AceHook's SecureHook is hooksecurefunc): Show again after
	-- lines are added restyles the new ones.
	if not self:IsHooked(GameTooltip, 'Show') then
		self:SecureHook(GameTooltip, 'Show', 'UpdateTooltipFonts')
	end

	for i=1, 2 do
		local name = 'DropDownList'..i
		local dropdown = _G[name]
		SkinBackdrop(dropdown, 'tooltip')
	end
end