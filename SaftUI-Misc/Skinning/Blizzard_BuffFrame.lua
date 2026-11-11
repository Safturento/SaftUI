local st = SaftUI
local SK = st:GetModule('Skinning')
local BF = SK:NewModule('Blizzard_BuffFrame')

--[[
	Skins the player aura buttons in BuffFrame, DebuffFrame and the frames built on the
	same templates (external defensives, the consolidated buffs tooltip, the deadly
	debuff warning).

	These are Edit Mode system frames. This file only touches the buttons' visual regions:
	it never moves, reparents or adds fields to the frames, and Blizzard's methods are only
	ever followed with hooksecurefunc. BuffFrame's and DebuffFrame's position and button
	layout (icon size included) are SaftUI's, in Blizzard_BuffFramePosition.lua. The
	backdrop and borders here hang off the button's Icon, so they follow that layout. The
	backdrop is a frame of SaftUI's, kept in a table here, drawn as an aura in the Skinning
	page's Theme and Background. Every button is created up front in AuraFrame_OnLoad, so
	they can all be skinned once on enable.

	The duration and stack count text of BuffFrame's and DebuffFrame's own buttons follow
	that file's Text settings: font, size, outline and anchor (see AuraTextStyle). All
	other aura buttons keep the skinning font and Blizzard's anchors.

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
local backdrops = setmetatable({}, { __mode = 'k' }) -- button's Icon -> SaftUI's backdrop behind it
local borderUpdaters = {} -- button -> re-applies its border color
local durationAnchorers = {} -- button -> re-applies its duration text's anchor
local atlasColors = {}
local noneColor

-- Read at use time, so a profile change takes effect.
local function SkinningFont()
	return st:GetFont(st.config.profile.skinning.font)
end

-- The Skinning page's Theme and Background, read at use time.
local function SkinningLook()
	local config = st.config.profile.skinning
	return config.theme, config.background
end

-- Draws the backdrop behind a button's icon. It's made the first time: a frame of
-- SaftUI's, a child of the button one level under it, so under the icon, and laid over
-- the icon until st:SetBackdropIn places it the theme's border outside it. Under None it
-- stays there bare, so the debuff border's fallback (SkinBorders) still has its place.
local function DrawBackdrop(button)
	local icon = button.Icon
	if not backdrops[icon] then
		local backdrop = st:CreateFrame('Frame', nil, button)
		backdrop:SetFrameLevel(max(0, button:GetFrameLevel() - 1))
		backdrop:SetAllPoints(icon)
		backdrops[icon] = backdrop
	end
	local theme, background = SkinningLook()
	st:SetBackdropIn(backdrops, icon, theme, background, 'aura')
end

-- The Auras module's style for a button's 'duration' or 'count' text: its font object,
-- then its anchor relative to the icon (text point, icon point, x, y). Only BuffFrame's
-- and DebuffFrame's own buttons have one; for any other aura button (external
-- defensives, the consolidated buffs tooltip, the deadly debuff) this is nil. Read at
-- use time, so settings and profile changes take effect.
local function AuraTextStyle(button, kind)
	local auras = st:GetModule('Auras', true)
	if auras and auras.GetTextStyle then
		return auras:GetTextStyle(button, kind)
	end
end

-- Anchors a duration or count text where the Auras settings say. False if the button
-- has no Auras style.
local function AnchorAuraText(text, button, kind)
	local font, point, relativePoint, x, y = AuraTextStyle(button, kind)
	if not font then return false end
	text:ClearAllPoints()
	text:SetPoint(point, button.Icon, relativePoint, x, y)
	return true
end

local function DurationFont(button)
	return AuraTextStyle(button, 'duration') or SkinningFont()
end

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
	local backdrop = backdrops[button.Icon]

	if button.TempEnchantBorder and button.TempEnchantBorder:IsShown() then
		st:SetBorderColor(backdrop, unpack(TEMP_ENCHANT_COLOR))
	elseif button.DebuffBorder and button.DebuffBorder:IsShown() and debuffColor then
		st:SetBorderColor(backdrop, debuffColor:GetRGB())
	else
		st:SetBorderColor(backdrop)
	end
end

local function SkinBorders(button)
	local debuffColor

	local function Update()
		UpdateBorderColor(button, debuffColor)
	end
	borderUpdaters[button] = Update

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
		border:SetAllPoints(backdrops[button.Icon])
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

local function SkinDuration(button)
	local duration = button.Duration
	if not duration then return end

	duration:SetFontObject(DurationFont(button))
	-- Edit Mode and some locales swap the duration font while updating
	hooksecurefunc(duration, 'SetFontObject', function(self, fontObject)
		local current = DurationFont(button)
		if fontObject ~= current then self:SetFontObject(current) end
	end)

	-- Blizzard's grid layout re-anchors the duration flush against the icon (and zhTW's
	-- OnUpdate re-anchors it every frame). Put it where the Auras settings say, or else
	-- push it past the backdrop.
	local anchoring
	local function Anchor(point, relativeTo, relativePoint)
		if anchoring then return end
		anchoring = true
		if not AnchorAuraText(duration, button, 'duration') and relativeTo == button.Icon then
			local offset = DURATION_OFFSETS[point]
			if offset then
				-- Past the backdrop's border, whose width follows the theme
				local gap = st:ThemeInset(SkinningLook()) + 1
				duration:SetPoint(point, relativeTo, relativePoint, offset[1] * gap, offset[2] * gap)
			end
		end
		anchoring = false
	end
	hooksecurefunc(duration, 'SetPoint', function(_, point, relativeTo, relativePoint)
		Anchor(point, relativeTo, relativePoint)
	end)

	-- Re-applies the anchor from the duration's current point, e.g. after a backdrop or
	-- settings change.
	durationAnchorers[button] = function()
		local point, relativeTo, relativePoint = duration:GetPoint(1)
		if issecretvalue(point) or issecretvalue(relativeTo) or issecretvalue(relativePoint) then
			point, relativeTo, relativePoint = nil, nil, nil
		end
		Anchor(point, relativeTo, relativePoint)
	end
	durationAnchorers[button]()
end

-- The stack count: the Auras settings, or else the icon's bottom-right corner. Blizzard
-- only ever sets its text and shows or hides it, so it's styled here once, and again
-- when settings change (BF:UpdateText).
local function StyleCount(button)
	local count = button.Count
	if not count then return end
	count:SetFontObject(AuraTextStyle(button, 'count') or SkinningFont())
	if not AnchorAuraText(count, button, 'count') then
		count:ClearAllPoints()
		count:SetPoint('BOTTOMRIGHT', button.Icon, 'BOTTOMRIGHT', 0, 1)
	end
end

local function SkinAuraButton(button)
	if not button or skinned[button] or button.isAuraAnchor or not button.Icon then return end
	skinned[button] = true

	local config = st.config.profile.skinning
	local font = st:GetFont(config.font)

	st:SkinIcon(button.Icon)
	DrawBackdrop(button)

	SkinBorders(button)
	SkinDuration(button)
	StyleCount(button)

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

-- Re-applies every skinned button's duration and count text (font and anchor). The
-- Auras module calls this when its text settings change. Only font strings are
-- touched, the same as the hooks above, which already run in combat.
function BF:UpdateText()
	for button in pairs(skinned) do
		if button.Duration then
			button.Duration:SetFontObject(DurationFont(button))
			if durationAnchorers[button] then durationAnchorers[button]() end
		end
		StyleCount(button)
	end
end

-- A profile change: every skinned button gets the profile's skinning Theme,
-- Background and font, and the profile's Auras text settings. Only regions and
-- SaftUI's own backdrops are touched, the same as the hooks above, which already
-- run in combat.
function BF:UpdateConfig()
	local config = st.config.profile.skinning
	local font = st:GetFont(config.font)

	for button in pairs(skinned) do
		DrawBackdrop(button)
		-- Drawing reset the border to the theme's color
		if borderUpdaters[button] then borderUpdaters[button]() end

		if button.Symbol then
			button.Symbol:SetFontObject(font)
		end
	end

	-- The duration's backdrop gap follows the theme's border
	self:UpdateText()
end

-- After a theme recolor (st:RecolorThemed gave every backdrop the theme's border):
-- the debuff type and weapon enchant borders go back on. Skinning passes it on.
function BF:OnColorsChanged(group)
	if group ~= 'theme' then return end
	for _, update in pairs(borderUpdaters) do
		update()
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
