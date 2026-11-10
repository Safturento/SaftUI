local st = SaftUI
local SK = st:GetModule('Skinning')
local ST = SK:NewModule('Blizzard_SwingTimer')

--[[
	Skins the swing timer bars Blizzard ships on WoW Forever (Blizzard_SwingTimer).
	Retail has no such addon, so nothing here runs unless the frames exist.

	The bars are Edit Mode system frames. This file only restyles them: their size and
	position are owned by Blizzard_SwingTimerPosition.lua, nothing here gives them new
	fields, and Blizzard's methods are only ever followed with hooksecurefunc.
	State lives in the local `skinned` and `backdrops` tables. The only new frame is a
	SaftUI-owned backdrop parented to the bar's StatusBar, so it shares the StatusBar's
	alpha (Blizzard dims that alpha while out of range) and visibility. It's drawn as a bar
	in the Skinning page's Theme and Background, the theme's border outside the StatusBar.

	Restyled:
	  - Background / Border art: hidden (Blizzard only touches their alpha, never their
	    visibility; a Show hook keeps them hidden regardless).
	  - StatusBar: flat texture, tinted per swing type. Blizzard sets the atlas fill once
	    in InitializeBarPresentation; a hook re-applies ours if it is ever set again.
	  - Pip: flat 2px line at the fill's leading edge. Blizzard anchors it to the fill
	    texture and shows/hides it on swing start/end; only its texture and size change.
	  - TypeLabel / TimeLabel: SaftUI font. Blizzard keeps recoloring them (red when out
	    of range), so their color is left alone.
	  - TypeLabelShadow: hidden. Whether TypeLabel / TimeLabel show, and the bar's
	    opacity, are /sui settings applied by Blizzard_SwingTimerPosition.lua.
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
local backdrops = setmetatable({}, { __mode = 'k' }) -- StatusBar -> SaftUI's backdrop behind it

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

-- The backdrop, and the labels' font, from the Skinning page. st:SetBackdropIn makes
-- the backdrop the first time (none while the theme is None), one level under the
-- StatusBar, and keeps it the theme's border outside it.
local function StyleBar(statusBar)
	local config = st.config.profile.skinning
	st:SetBackdropIn(backdrops, statusBar, config.theme, config.background, 'bar')

	local font = st:GetFont(config.font)
	if statusBar.TypeLabel then statusBar.TypeLabel:SetFontObject(font) end
	if statusBar.TimeLabel then statusBar.TimeLabel:SetFontObject(font) end
end

local function SkinBar(bar, color)
	if not bar or skinned[bar] then return end

	local statusBar = bar.StatusBar
	if not statusBar then return end
	skinned[bar] = true

	KeepHidden(bar.Background)
	KeepHidden(bar.Border)
	KeepHidden(statusBar.TypeLabelShadow)

	SkinFill(statusBar, color)
	SkinPip(statusBar)
	StyleBar(statusBar)
end

function ST:SkinFrames()
	for _, info in ipairs(BARS) do
		SkinBar(_G[info.name], info.color)
	end
end

-- A profile change, or the Skinning page: every skinned bar takes its Theme,
-- Background and font. Only SaftUI's backdrop and the labels' fonts are touched.
function ST:UpdateConfig()
	for bar in pairs(skinned) do
		StyleBar(bar.StatusBar)
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
