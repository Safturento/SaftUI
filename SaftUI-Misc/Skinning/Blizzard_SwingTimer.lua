local st = SaftUI
local SK = st:GetModule('Skinning')
local ST = SK:NewModule('Blizzard_SwingTimer')

--[[
	Skins the swing timer bars Blizzard ships on WoW Forever (Blizzard_SwingTimer).
	Retail has no such addon, so nothing here runs unless the frames exist.

	The bars are Edit Mode system frames, so nothing is moved, resized, reparented or
	given new fields, and Blizzard's methods are only ever followed with hooksecurefunc.
	State lives in the local `skinned` table. The only new frame is a SaftUI-owned
	backdrop parented to the bar's StatusBar, so it shares the StatusBar's alpha (Blizzard
	dims that alpha while out of range) and visibility.

	Restyled:
	  - Background / Border art: hidden (Blizzard only touches their alpha, never their
	    visibility; a Show hook keeps them hidden regardless).
	  - StatusBar: flat texture, tinted per swing type. Blizzard sets the atlas fill once
	    in InitializeBarPresentation; a hook re-applies ours if it is ever set again.
	  - Pip: flat 2px line at the fill's leading edge. Blizzard anchors it to the fill
	    texture and shows/hides it on swing start/end; only its texture and size change.
	  - TypeLabel / TimeLabel: SaftUI font. Blizzard keeps recoloring them (red when out
	    of range), so their color is left alone.
	  - TypeLabelShadow: hidden.
]]

local issecretvalue = issecretvalue or function() return false end

-- Frame globals created by Blizzard_SwingTimer, with the fill color for each swing type.
local BARS = {
	{ name = 'SwingTimerMainHandFrame', color = { 0.85, 0.65, 0.20 } },
	{ name = 'SwingTimerOffHandFrame',  color = { 0.35, 0.60, 0.85 } },
	{ name = 'SwingTimerRangedFrame',   color = { 0.40, 0.75, 0.35 } },
}

local PIP_WIDTH = 2

local skinned = setmetatable({}, { __mode = 'k' })

local function KeepHidden(region)
	if not region then return end
	region:Hide()
	hooksecurefunc(region, 'Show', function(self) self:Hide() end)
end

local function SkinFill(statusBar, color)
	local function Apply()
		statusBar:SetStatusBarTexture(st.BLANK_TEX)
		statusBar:SetStatusBarColor(color[1], color[2], color[3])
	end

	local applying
	hooksecurefunc(statusBar, 'SetStatusBarTexture', function(_, texture)
		if applying or texture == st.BLANK_TEX then return end
		applying = true
		Apply()
		applying = false
	end)

	Apply()
end

local function SkinPip(statusBar)
	local pip = statusBar.Pip
	if not pip then return end

	pip:SetTexture(st.BLANK_TEX)
	pip:SetVertexColor(1, 1, 1, 1)
	pip:SetWidth(PIP_WIDTH)

	-- Match the fill's height; it is only known once the bar has been laid out.
	local function UpdateHeight()
		local height = statusBar:GetHeight()
		if type(height) ~= 'number' or issecretvalue(height) or height <= 0 then return end
		pip:SetHeight(height)
	end

	statusBar:HookScript('OnSizeChanged', UpdateHeight)
	UpdateHeight()
end

local function SkinBackdrop(statusBar)
	local config = st.config.profile.skinning
	local template = config.template
	if template == nil or template == 'none' or template == '' then return end

	local templateConfig = st.config.profile.templates[template]
	if not templateConfig then return end

	local offset = templateConfig.thick and 2 or 1

	local holder = st:CreateFrame('Frame', nil, statusBar)
	holder:SetFrameLevel(max(0, statusBar:GetFrameLevel() - 1))
	holder:SetPoint('TOPLEFT', statusBar, 'TOPLEFT', -offset, offset)
	holder:SetPoint('BOTTOMRIGHT', statusBar, 'BOTTOMRIGHT', offset, -offset)
	st:SetTemplate(holder, template)
end

local function SkinBar(bar, color)
	if not bar or skinned[bar] then return end

	local statusBar = bar.StatusBar
	if not statusBar then return end
	skinned[bar] = true

	local font = st:GetFont(st.config.profile.skinning.font)

	KeepHidden(bar.Background)
	KeepHidden(bar.Border)
	KeepHidden(statusBar.TypeLabelShadow)

	SkinFill(statusBar, color)
	SkinPip(statusBar)
	SkinBackdrop(statusBar)

	if statusBar.TypeLabel then statusBar.TypeLabel:SetFontObject(font) end
	if statusBar.TimeLabel then statusBar.TimeLabel:SetFontObject(font) end
end

function ST:SkinFrames()
	for _, info in ipairs(BARS) do
		SkinBar(_G[info.name], info.color)
	end
end

function ST:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_SwingTimer' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SkinFrames()
end

function ST:OnEnable()
	if _G.SwingTimerMainHandFrame then
		self:SkinFrames()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
