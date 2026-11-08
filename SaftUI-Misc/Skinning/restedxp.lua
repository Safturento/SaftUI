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
local highlights = {}                               -- hover highlight textures of the step frames
local skinnedSteps = setmetatable({}, { __mode = 'k' })
local scrollTrack                                   -- the scroll bar's track texture

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

local function GreyRGB()
	return st.config.profile.colors.text.grey:GetRGB()
end

local function ColorHighlight(tex)
	tex:SetColorTexture(unpack(st.config.profile.templates.highlight.backdropcolor))
end

-- The thumb is RestedXP's, re-textured by it on every UpdateScrollBar.
local function ColorThumb(bar)
	local thumb = bar:GetThumbTexture()
	if thumb then thumb:SetVertexColor(GreyRGB()) end
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

-- One step frame: flat, a hover highlight, SaftUI's font, a line above it.
local function SkinStep(frame, isFirst)
	if skinnedSteps[frame] then return end
	skinnedSteps[frame] = true

	NoBackdrop(frame)

	-- RestedXP's OnEnter/OnLeave (set anew on every guide load) call
	-- SetBackdropColor, which is what we follow.
	local highlight = frame:CreateTexture(nil, 'BACKGROUND')
	highlight:SetAllPoints(frame)
	ColorHighlight(highlight)
	highlight:Hide()
	tinsert(highlights, highlight)
	hooksecurefunc(frame, 'SetBackdropColor', function(self)
		highlight:SetShown(self:IsMouseOver())
	end)

	HookFont(frame.text, 'text')
	HookFont(frame.number.text, 'text')
	frame.number.text:SetTextColor(GreyRGB())

	-- The first step sits under the title line already. The line is a region
	-- of its step, so it fades with a hidden one.
	if not isFirst then
		local line = MakeDivider(frame)
		line:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 1)
		line:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', 0, 1)
	end
end

-- Skins every step frame RestedXP has made so far; pooled frames keep their skin.
function RX:SkinList()
	local pool = self.frames and self.frames.ScrollChild.framePool
	if not pool then return end
	for i, frame in ipairs(pool) do
		if frame.text and frame.number and frame.number.text then
			SkinStep(frame, i == 1)
		end
	end
end

-- RestedXP's default scroll bar, flattened to a thin thumb on a dark track.
function RX:SkinScrollBar()
	local scrollFrame = self.frames and self.frames.ScrollFrame
	local bar = scrollFrame and scrollFrame.ScrollBar
	if not bar then return end

	for _, button in ipairs({ bar.ScrollUpButton, bar.ScrollDownButton }) do
		button:SetAlpha(0)
		button:EnableMouse(false)
	end

	if not scrollTrack then
		scrollTrack = bar:CreateTexture(nil, 'BACKGROUND')
		scrollTrack:SetPoint('TOP')
		scrollTrack:SetPoint('BOTTOM')
		scrollTrack:SetWidth(4)
		scrollTrack:SetColorTexture(0, 0, 0, 0.5)
	end

	bar:SetThumbTexture(st.BLANK_TEX)
	local thumb = bar:GetThumbTexture()
	thumb:SetSize(4, 32)
	ColorThumb(bar)

	for _, region in ipairs({ bar:GetRegions() }) do
		if region ~= thumb and region ~= scrollTrack then region:Hide() end
	end

	bar:ClearAllPoints()
	bar:SetPoint('TOPLEFT', scrollFrame, 'TOPRIGHT', 6, 0)
	bar:SetPoint('BOTTOMLEFT', scrollFrame, 'BOTTOMRIGHT', 6, 0)
	bar:SetWidth(8)
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

	self:SkinList()
	self:SecureHook(frames.BottomFrame, 'UpdateFrame', 'SkinList')
	self:SkinScrollBar()
	self:SecureHook(rxp, 'UpdateScrollBar', 'SkinScrollBar')
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
	for _, tex in ipairs(highlights) do
		ColorHighlight(tex)
	end
	local bar = self.frames and self.frames.ScrollFrame.ScrollBar
	if bar then ColorThumb(bar) end
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
