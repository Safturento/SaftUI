local st = SaftUI
local SK = st:GetModule('Skinning')
local BF = SK:NewModule('Blizzard_BuffFrame')

--[[
	Skins the player aura buttons in BuffFrame, DebuffFrame and the frames built on the
	same templates (external defensives, the consolidated buffs tooltip, the deadly
	debuff warning).

	These are Edit Mode system frames, so only the buttons' visual regions are touched:
	the frames themselves are never moved, reparented or given new fields, and Blizzard's
	methods are only ever followed with hooksecurefunc. Every button is created up front
	in AuraFrame_OnLoad, so they can all be skinned once on enable.

	Aura data isn't read here. Debuff borders take their color from the atlas Blizzard
	assigns to the button's DebuffBorder for its dispel type. If that atlas ever comes
	through as a secret value, Blizzard's border art is shown behind the icon instead.
]]

local issecretvalue = issecretvalue or function() return false end

local TEMP_ENCHANT_COLOR = { 0.6, 0.2, 0.9 }

-- Points Blizzard anchors the duration text by, mapped to the direction that moves the
-- text away from the icon so it clears our backdrop.
local DURATION_OFFSETS = {
	TOP = { 0, -1 },
	BOTTOM = { 0, 1 },
	LEFT = { 1, 0 },
	RIGHT = { -1, 0 },
}

local skinned = {}
local atlasColors = {}
local noneColor

local function BuildAtlasColors()
	local displayInfo = AuraUtil and AuraUtil.GetDebuffDisplayInfoTable and AuraUtil.GetDebuffDisplayInfoTable() or {}
	for _, info in pairs(displayInfo) do
		if info.color then
			if info.basicAtlas then atlasColors[info.basicAtlas] = info.color end
			if info.dispelAtlas then atlasColors[info.dispelAtlas] = info.color end
		end
	end
	noneColor = displayInfo.None and displayInfo.None.color or DEBUFF_TYPE_NONE_COLOR
end

local function UpdateBorderColor(button, debuffColor)
	local backdrop = button.Icon.backdrop

	if button.TempEnchantBorder and button.TempEnchantBorder:IsShown() then
		backdrop:SetBackdropBorderColor(unpack(TEMP_ENCHANT_COLOR))
	elseif button.DebuffBorder and button.DebuffBorder:IsShown() and debuffColor then
		backdrop:SetBackdropBorderColor(debuffColor:GetRGB())
	else
		local config = st.config.profile.templates[backdrop.template]
		if config.border then
			backdrop:SetBackdropBorderColor(unpack(config.bordercolor))
		else
			backdrop:SetBackdropBorderColor(0, 0, 0, 0)
		end
	end
end

local function SkinBorders(button)
	local debuffColor

	local function Update()
		UpdateBorderColor(button, debuffColor)
	end

	if button.TempEnchantBorder then
		button.TempEnchantBorder:SetAlpha(0)
		hooksecurefunc(button.TempEnchantBorder, 'Show', Update)
		hooksecurefunc(button.TempEnchantBorder, 'Hide', Update)
	end

	local border = button.DebuffBorder
	if border then
		-- Only visible as a fallback (see note at top): a fill behind the icon that
		-- covers our backdrop, so its edge reads as the border.
		border:SetAlpha(0)
		border:ClearAllPoints()
		border:SetAllPoints(button.Icon.backdrop)
		border:SetDrawLayer('BACKGROUND', -1)

		hooksecurefunc(border, 'SetAtlas', function(self, atlas)
			if issecretvalue(atlas) then
				debuffColor = nil
				self:SetAlpha(1)
			else
				debuffColor = atlasColors[atlas] or noneColor
				self:SetAlpha(0)
			end
			Update()
		end)
		hooksecurefunc(border, 'Show', Update)
		hooksecurefunc(border, 'Hide', Update)
	end

	Update()
end

local function SkinDuration(button, font)
	local duration = button.Duration
	if not duration then return end

	duration:SetFontObject(font)
	-- Edit Mode and some locales swap the duration font while updating
	hooksecurefunc(duration, 'SetFontObject', function(self, fontObject)
		if fontObject ~= font then self:SetFontObject(font) end
	end)

	-- The grid layout re-anchors the duration flush against the icon; push it past the backdrop
	local gap = (button.Icon.thick and 2 or 1) + 1
	local anchoring
	hooksecurefunc(duration, 'SetPoint', function(self, point, relativeTo, relativePoint)
		if anchoring or relativeTo ~= button.Icon then return end
		local offset = DURATION_OFFSETS[point]
		if not offset then return end

		anchoring = true
		self:SetPoint(point, relativeTo, relativePoint, offset[1] * gap, offset[2] * gap)
		anchoring = false
	end)

	local point, relativeTo, relativePoint = duration:GetPoint(1)
	if point and not issecretvalue(point) then
		duration:SetPoint(point, relativeTo, relativePoint)
	end
end

local function SkinAuraButton(button)
	if not button or skinned[button] or button.isAuraAnchor or not button.Icon then return end
	skinned[button] = true

	local config = st.config.profile.skinning
	local font = st:GetFont(config.font)

	st:SkinIcon(button.Icon)
	st:SetBackdrop(button.Icon, config.template)

	SkinBorders(button)
	SkinDuration(button, font)

	if button.Count then
		button.Count:SetFontObject(font)
		button.Count:ClearAllPoints()
		button.Count:SetPoint('BOTTOMRIGHT', button.Icon, 'BOTTOMRIGHT', 0, 1)
	end

	if button.Symbol then
		button.Symbol:SetFontObject(font)
	end
end

local function SkinAuraFrame(frame)
	if not frame or not frame.auraFrames then return end
	for _, button in ipairs(frame.auraFrames) do
		SkinAuraButton(button)
	end
end

function BF:SkinFrames()
	if self.skinned then return end
	self.skinned = true

	BuildAtlasColors()

	SkinAuraFrame(BuffFrame)
	SkinAuraFrame(DebuffFrame)
	SkinAuraFrame(ExternalDefensivesFrame)

	-- The consolidation button keeps Blizzard's art (its icon uses custom tex coords),
	-- but the auras listed in its tooltip are regular aura buttons.
	local consolidated = BuffFrame.ConsolidatedBuffs
	if consolidated and consolidated.Tooltip then
		SkinAuraFrame(consolidated.Tooltip.Auras)
	end

	if DeadlyDebuffFrame then
		SkinAuraButton(DeadlyDebuffFrame.Debuff)
	end
end

function BF:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_BuffFrame' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SkinFrames()
end

function BF:OnEnable()
	if not st.retail then return end

	if BuffFrame and BuffFrame.auraFrames then
		self:SkinFrames()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
