local st = SaftUI
local SK = st:GetModule('Skinning')

-- Restyles the guide window of the RestedXP Guides addon (a third-party addon,
-- not Blizzard's) in SaftUI's chat look: the chat panel template, the chat font
-- and fine divider lines. Its pieces are kept in side tables keyed by RestedXP's
-- frames. Scripts are only ever hooked, never replaced.
--
-- What it relies on RestedXP doing:
-- - Its v2 window hides the v1 frames itself, so the skin stands down with them
--   (the guide panel shows and hides with GuideName).
-- - It re-anchors CurrentStepFrame on every step advance, every mouse-up on the
--   window, at login and on an orientation change, so SaftUI's gap between the
--   two panels comes from a post-hook on CurrentStepFrame's SetPoint.
-- - It SetScripts each list step's OnEnter/OnLeave anew on every guide load, so
--   the hover highlight follows their SetBackdropColor calls, not a script hook.
local RX = SK:NewModule('RestedXP')

local TITLE_SIZE_BONUS = 3
local DIVIDER_ALPHA = 0.5
local STEPS_GAP = 7 -- added to RestedXP's offset of the current steps, away from the window

local panels = {}                                   -- SaftUI panels made by MakePanel
local dividers = {}                                 -- divider textures
local fontState = setmetatable({}, { __mode = 'k' }) -- [fontString] = { kind = , size = }
local backdropCleared = setmetatable({}, { __mode = 'k' })
local applyingFont = false                          -- our own SetFont isn't re-handled
local highlights = {}                               -- hover highlight textures of the step frames
local skinnedSteps = setmetatable({}, { __mode = 'k' })   -- [list step frame] = true once skinned
local stepLines = setmetatable({}, { __mode = 'k' })      -- [list step frame] = the line above it (none on step 1)
local skinnedCurrent = setmetatable({}, { __mode = 'k' }) -- [pooled current step frame] = the line above it; set once skinned
local tipPanels = setmetatable({}, { __mode = 'k' })       -- [pooled current step frame] = its panel, made the first time it is a tip
local stepsPanel                                    -- the panel behind the current steps
local scrollTrack                                   -- the scroll bar's track texture
local gappingSteps = false                          -- our own SetPoint on CurrentStepFrame isn't re-handled

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

-- RestedXP sets its backdrops on every theme refresh; keep them off. A frame
-- without Blizzard's Backdrop mixin has none to clear.
local function NoBackdrop(frame)
	if backdropCleared[frame] or not (frame.ClearBackdrop and frame.SetBackdrop) then return end
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

-- RestedXP hides a step by fading it out (alpha 0) or hiding it.
local function IsVisible(frame)
	return frame:IsShown() and frame:GetAlpha() > 0
end

-- Whether the cursor's OnEnter/OnLeave belong to frame. IsMouseOver is only a
-- rectangle test: RestedXP's menu opens at the cursor, over the step, and the
-- step's OnLeave then fires with the cursor still inside it.
local function IsHovered(frame)
	if frame.IsMouseMotionFocus then return frame:IsMouseMotionFocus() end
	return frame:IsMouseOver()
end

-- One step frame: flat, a hover highlight, SaftUI's font, a line above it.
local function SkinStep(frame, isFirst)
	if skinnedSteps[frame] then return end
	skinnedSteps[frame] = true

	NoBackdrop(frame)

	-- RestedXP's OnEnter/OnLeave (set anew on every guide load) call
	-- SetBackdropColor, which is what we follow.
	if frame.SetBackdropColor then
		local highlight = frame:CreateTexture(nil, 'BACKGROUND')
		highlight:SetAllPoints(frame)
		ColorHighlight(highlight)
		highlight:Hide()
		tinsert(highlights, highlight)
		hooksecurefunc(frame, 'SetBackdropColor', function(self)
			highlight:SetShown(IsHovered(self))
		end)
	end

	HookFont(frame.text, 'text')
	HookFont(frame.number.text, 'text')
	frame.number.text:SetTextColor(GreyRGB())

	-- The first step sits under the title line already. The line is a region
	-- of its step, so it fades with a hidden one.
	if not isFirst then
		local line = MakeDivider(frame)
		line:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 1)
		line:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', 0, 1)
		stepLines[frame] = line
	end
end

-- Skins every step frame RestedXP has made so far; pooled frames keep their skin.
-- A step's line shows only below a visible step, so the first visible one sits
-- right under the title line however many are hidden above it.
function RX:SkinList()
	local pool = self.frames and self.frames.ScrollChild.framePool
	if not pool then return end
	local above = false -- a visible step above this one
	for i, frame in ipairs(pool) do
		if frame.text and frame.number and frame.number.text then
			SkinStep(frame, i == 1)
			if stepLines[frame] then stepLines[frame]:SetShown(above) end
			above = above or IsVisible(frame)
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

-- Tips are anchored to the screen; every other current step is stacked in
-- CurrentStepFrame.
local function IsTip(frame)
	local _, rel = frame:GetPoint(1)
	return rel == UIParent or (frame.step and frame.step.tip and true) or false
end

-- A current step frame: flat, SaftUI's font, grey title at the right, a line above it.
local function SkinCurrentStep(frame)
	if skinnedCurrent[frame] then return end

	NoBackdrop(frame)
	NoBackdrop(frame.number)

	local title = frame.number.text
	HookFont(title, 'text')
	title:SetTextColor(GreyRGB())
	title:ClearAllPoints()
	title:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -5, -1)
	title:SetJustifyH('RIGHT')

	local line = MakeDivider(frame)
	line:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 2)
	line:SetPoint('BOTTOMRIGHT', frame, 'TOPRIGHT', 0, 2)
	skinnedCurrent[frame] = line
end

-- Skins the current steps (and the pooled frames RestedXP made since the last
-- pass), and gives each frame the look of the role it has now. A stacked step's
-- line shows only below a visible stacked step, and the panel only behind at
-- least one: RestedXP keeps a hidden step 1px tall, and starts the frame 25px
-- tall before its first step.
function RX:SkinCurrentSteps()
	local current = self.frames and self.frames.CurrentStepFrame
	local pool = current and current.framePool
	if not pool then return end

	local above = false -- a visible stacked step above this one
	for _, frame in ipairs(pool) do
		if frame.number and frame.number.text and frame.elements then
			SkinCurrentStep(frame)
			for _, element in ipairs(frame.elements) do
				if element.text then HookFont(element.text, 'text') end
			end

			local tip = IsTip(frame)
			local visible = not tip and IsVisible(frame)
			skinnedCurrent[frame]:SetShown(visible and above)
			above = above or visible
			if tip and not tipPanels[frame] then
				local panel = MakePanel(frame)
				panel:SetAllPoints(frame)
				tipPanels[frame] = panel
			end
			if tipPanels[frame] then tipPanels[frame]:SetShown(tip) end
		end
	end

	if stepsPanel then stepsPanel:SetShown(above) end
end

-- RestedXP hangs the current steps just above the guide name or, in its bottom
-- orientation, just below the window (GuideWindow.lua SetStepFrameAnchor). Each
-- of those points goes STEPS_GAP further from the window, so the steps panel's
-- border and the guide panel's don't touch. [point] = { frame, relative point, dy }.
local STEPS_POINTS = {
	BOTTOMLEFT = { 'GuideName', 'TOPLEFT', STEPS_GAP },
	BOTTOMRIGHT = { 'GuideName', 'TOPRIGHT', STEPS_GAP },
	TOPLEFT = { 'RXPFrame', 'BOTTOMLEFT', -STEPS_GAP },
	TOPRIGHT = { 'RXPFrame', 'BOTTOMRIGHT', -STEPS_GAP },
}

local function GapStepsPoint(current, point)
	if gappingSteps then return end
	for i = 1, current:GetNumPoints() do
		local p, rel, relPoint, x, y = current:GetPoint(i)
		if p == point then
			local gap = STEPS_POINTS[p]
			if gap and rel == RX.frames[gap[1]] and relPoint == gap[2] then
				gappingSteps = true
				current:SetPoint(p, rel, relPoint, x, y + gap[3])
				gappingSteps = false
			end
			return
		end
	end
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
	-- AceHook errors on a missing target, so a RestedXP that renamed one is left alone.
	if type(rxp.UpdateVisuals) ~= 'function' or type(rxp.UpdateScrollBar) ~= 'function'
		or type(frames.BottomFrame.UpdateFrame) ~= 'function'
		or type(frames.CurrentStepFrame.UpdateText) ~= 'function' then return end
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
	-- RestedXP hides the list for a window too short for it (28px), where this
	-- line would cross the title.
	local footerLine = MakeDivider(panel)
	footerLine:SetPoint('BOTTOMLEFT', footer, 'TOPLEFT')
	footerLine:SetPoint('BOTTOMRIGHT', footer, 'TOPRIGHT')
	footerLine:SetShown(frames.BottomFrame:IsShown())
	frames.BottomFrame:HookScript('OnShow', function() footerLine:Show() end)
	frames.BottomFrame:HookScript('OnHide', function() footerLine:Hide() end)

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

	-- Gap the current steps' anchors now and each time RestedXP re-anchors them.
	-- A hook on RXPFrame.SetStepFrameAnchor would miss the window's mouse-up,
	-- which calls RestedXP's local copy of it.
	local current = frames.CurrentStepFrame
	hooksecurefunc(current, 'SetPoint', GapStepsPoint)
	local points = {}
	for i = 1, current:GetNumPoints() do points[i] = (current:GetPoint(i)) end
	for _, point in ipairs(points) do GapStepsPoint(current, point) end
	stepsPanel = MakePanel(current)
	stepsPanel:SetAllPoints(current)

	self:SkinCurrentSteps()
	self:SecureHook(current, 'UpdateText', 'SkinCurrentSteps')
end

function RX:ADDON_LOADED(_, name)
	if name ~= 'RXPGuides' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

-- A profile change, or SaftUI-Chat's look changing: re-applies the style.
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
	-- Chat's template and font are this window's too. Its options apply them
	-- with ApplyAppearance, and its UpdateConfig (a profile change) ends in it.
	local chat = st:GetModule('Chat', true)
	if chat and type(chat.ApplyAppearance) == 'function' then
		self:SecureHook(chat, 'ApplyAppearance', 'UpdateConfig')
	end

	if C_AddOns.IsAddOnLoaded('RXPGuides') and RXPFrame then
		self:Setup()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
