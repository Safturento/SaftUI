local st = SaftUI
local SK = st:GetModule('Skinning')

-- Restyles the guide window of the RestedXP Guides addon (a third-party addon,
-- not Blizzard's) in SaftUI's chat look: the chat panel template, the chat font
-- and fine divider lines. Its pieces are kept in side tables keyed by RestedXP's
-- frames. Scripts are only ever hooked, never replaced.
local RX = SK:NewModule('RestedXP')

local TITLE_SIZE_BONUS = 3
local DIVIDER_ALPHA = 0.5

local panels = {}                                   -- SaftUI panels made by MakePanel
local dividers = {}                                 -- divider textures
local fontState = setmetatable({}, { __mode = 'k' }) -- [fontString] = { kind = , size = }
local backdropCleared = setmetatable({}, { __mode = 'k' })
local applyingFont = false                          -- our own SetFont isn't re-handled

-- The chat's panel template and font name; SaftUI's defaults when chat has no config.
function RX:GetStyle()
	local chat = st.config.profile.chat
	return (chat and chat.template) or 'thicktransparent', (chat and chat.font) or 'normal'
end

-- Applies SaftUI's face and outline at the size RestedXP asked for.
local function ApplyFont(fs)
	local state = fontState[fs]
	if not state.size then return end

	local _, fontName = RX:GetStyle()
	if state.kind == 'title' then fontName = 'title' end
	local fontObject = st:GetFont(fontName)
	if not fontObject then return end

	local face, _, outline = fontObject:GetFont()
	local size = state.size + (state.kind == 'title' and TITLE_SIZE_BONUS or 0)

	applyingFont = true
	fs:SetFont(face, size, outline)
	applyingFont = false
end

-- RestedXP's text keeps the size it asks for (its "Guide font size" setting) but
-- takes SaftUI's face and outline. kind is 'text' or 'title'. A FontString with
-- no font yet is styled on RestedXP's first SetFont.
local function HookFont(fs, kind)
	if fontState[fs] then return end
	fontState[fs] = { kind = kind, size = select(2, fs:GetFont()) }

	hooksecurefunc(fs, 'SetFont', function(self, _, size)
		if applyingFont then return end
		fontState[self].size = size
		ApplyFont(self)
	end)
	hooksecurefunc(fs, 'SetFontObject', function(self)
		if applyingFont then return end
		fontState[self].size = select(2, self:GetFont())
		ApplyFont(self)
	end)

	ApplyFont(fs)
end

-- RestedXP sets its backdrops on every theme refresh; keep them off.
local function NoBackdrop(frame)
	if backdropCleared[frame] then return end
	backdropCleared[frame] = true

	frame:ClearBackdrop()
	hooksecurefunc(frame, 'SetBackdrop', function(self) self:ClearBackdrop() end)
end

local function ColorDivider(tex)
	local template = st.config.profile.templates[(RX:GetStyle())] or st.config.profile.templates.thicktransparent
	if not template then return end
	local r, g, b = unpack(template.bordercolor)
	tex:SetColorTexture(r, g, b, DIVIDER_ALPHA)
end

-- A 1 pixel line on frame; the caller anchors it.
local function MakeDivider(frame)
	local tex = frame:CreateTexture(nil, 'OVERLAY')
	PixelUtil.SetHeight(tex, 1)
	ColorDivider(tex)
	tinsert(dividers, tex)
	return tex
end

local function MakePanel(parent)
	local panel = st:CreateFrame('Frame', nil, parent)
	st:SetBackdrop(panel, (RX:GetStyle()))
	tinsert(panels, panel)
	return panel
end

local function HideBanner(frames)
	for _, tex in ipairs({ frames.GuideName.bg, frames.GuideName.icon, frames.GuideName.classIcon, frames.Footer.bg }) do
		tex:Hide()
	end
end

-- Re-hides RestedXP's banner art; it only ever re-textures it (never Shows it),
-- so this is a safety net. NoBackdrop's hooks keep the backdrops off.
function RX:SkinChrome()
	if self.frames then HideBanner(self.frames) end
end

function RX:Setup()
	if self.frames then return end
	local rxp = RXPFrame
	if not rxp then return end

	local frames = {
		RXPFrame = rxp, GuideName = rxp.GuideName, Footer = rxp.Footer, BottomFrame = rxp.BottomFrame,
		ScrollFrame = rxp.ScrollFrame, ScrollChild = rxp.ScrollChild, CurrentStepFrame = rxp.CurrentStepFrame,
	}
	-- a table with a nil value has no entry for it, so check by name
	for _, key in ipairs({ 'GuideName', 'Footer', 'BottomFrame', 'ScrollFrame', 'ScrollChild', 'CurrentStepFrame' }) do
		if not frames[key] then return end
	end
	local guideName, footer = frames.GuideName, frames.Footer
	if not (guideName.text and guideName.bg and guideName.icon and guideName.classIcon
		and footer.text and footer.bg) then return end
	self.frames = frames

	NoBackdrop(frames.BottomFrame)
	NoBackdrop(guideName)
	NoBackdrop(footer)
	HideBanner(frames)

	-- One panel behind the guide name, the steps and the footer, with its backdrop
	-- just above RestedXP's own (a child of it, so it also hides with RXPFrame).
	local panel = MakePanel(rxp)
	panel:SetFrameLevel(rxp:GetFrameLevel() + 1)
	panel:SetPoint('TOPLEFT', guideName, 'TOPLEFT')
	panel:SetPoint('BOTTOMRIGHT', footer, 'BOTTOMRIGHT')
	panel:SetShown(guideName:IsShown())
	-- RestedXP's v2 window hides GuideName (not RXPFrame) to retire this one.
	guideName:HookScript('OnShow', function() panel:Show() end)
	guideName:HookScript('OnHide', function() panel:Hide() end)

	local titleLine = MakeDivider(panel)
	titleLine:SetPoint('TOPLEFT', guideName, 'BOTTOMLEFT')
	titleLine:SetPoint('TOPRIGHT', guideName, 'BOTTOMRIGHT')
	local footerLine = MakeDivider(panel)
	footerLine:SetPoint('BOTTOMLEFT', footer, 'TOPLEFT')
	footerLine:SetPoint('BOTTOMRIGHT', footer, 'TOPRIGHT')

	-- RestedXP anchors these once, at load, around its logo and banner.
	guideName.text:SetPoint('LEFT', guideName, 'LEFT', 4, 0)
	guideName.text:SetPoint('RIGHT', guideName, 'RIGHT', -4, 0)
	frames.ScrollFrame:SetPoint('TOPLEFT', guideName, 'BOTTOMLEFT', 5, 0)

	HookFont(guideName.text, 'title')
	HookFont(footer.text, 'text')

	self:SecureHook(rxp, 'UpdateVisuals', 'SkinChrome')
end

function RX:ADDON_LOADED(_, name)
	if name ~= 'RXPGuides' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

-- A profile change, or SaftUI-Chat's config changing: re-applies the style.
function RX:UpdateConfig()
	local template = self:GetStyle()
	for _, panel in ipairs(panels) do
		st:SetBackdrop(panel, template)
	end
	for fs in pairs(fontState) do
		ApplyFont(fs)
	end
	for _, tex in ipairs(dividers) do
		ColorDivider(tex)
	end
end

function RX:OnEnable()
	-- Chat's template and font are this window's too.
	local chat = st:GetModule('Chat', true)
	if chat and chat.UpdateConfig then
		self:SecureHook(chat, 'UpdateConfig', 'UpdateConfig')
	end

	if C_AddOns.IsAddOnLoaded('RXPGuides') and RXPFrame then
		self:Setup()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
