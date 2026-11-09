-- A stand-in for the RestedXP Guides addon's guide window (GuideWindow.lua), as
-- the SaftUI skin (SaftUI-Misc/Skinning/restedxp.lua) sees it, built by
-- RXP.make(). Anchors and calls mirror GuideWindow.lua:353-395
-- (SetStepFrameAnchor), 422, 473-474, 636-670 (ClearFrameData), 985-1195
-- (SetStep), 1230-1394 (UpdateText), 1402-1427, 1508-1510 and UpdateVisuals
-- (52-82). Every frame it builds is locked (locked_widget.lua): SetScript and
-- new fields written by anyone but RestedXP error. RestedXP's own field writes
-- go through rawset. Fields starting with '_' are the fixture's own state,
-- which tests may set.
--
-- This models RestedXP, not WoW: the widgets, backdrops and layout come from
-- the shared stubs in tests/wow/. Load it with
-- load_test_file('misc/fixtures/restedxp_world.lua') and call make() after
-- reset_world(), in the world the skin is loaded into.

local lock = load_test_file('misc/fixtures/locked_widget.lua')

local RXP = {}

-- The methods Blizzard's backdrop mixin copies onto a frame made with
-- BackdropTemplate, which the skin's NoBackdrop checks for.
RXP.BACKDROP_METHODS = { 'SetBackdrop', 'ClearBackdrop', 'SetBackdropColor', 'SetBackdropBorderColor' }

local rxp_frames = setmetatable({}, { __mode = 'k' })

-- True for a frame RestedXP made and locked, false for one SaftUI made.
function RXP.is_rxp(frame)
	return rxp_frames[frame] == true
end

local function lockRXP(frame)
	rxp_frames[frame] = true
	lock(frame, 'RestedXP')
end

-- RestedXP sets its own scripts. The game's SetScript, which a locked frame
-- no longer offers.
local function set_script(frame, script, fn)
	getmetatable(UIParent).__index.SetScript(frame, script, fn)
end

-- opts.footer_font = false leaves the footer's text without a font, as it is
-- before RestedXP's first SetFont.
function RXP.make(opts)
	opts = opts or {}
	local R = CreateFrame('Frame', 'RXPFrame', UIParent, 'BackdropTemplate')
	R:SetSize(400, 500)
	R:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	R:EnableMouse(true)
	local bottom = CreateFrame('Frame', 'RXPFrame_bottomFrame', R, 'BackdropTemplate')
	local guide = CreateFrame('Frame', 'RXPFrameGuideName', R, 'BackdropTemplate')
	local footer = CreateFrame('Frame', 'RXPFrameFooter', R, 'BackdropTemplate')
	local scroll = CreateFrame('ScrollFrame', 'RXPFrameScrollFrame', R)
	local current = CreateFrame('Frame', nil, R)
	local child = CreateFrame('Frame', 'RXPFrame_steps', bottom, 'BackdropTemplate')
	R.BottomFrame, R.GuideName, R.Footer = bottom, guide, footer
	R.CurrentStepFrame, R.ScrollFrame, R.ScrollChild = current, scroll, child
	R.backdrop = { edge = { edgeFile = 'edge' }, guideName = { bgFile = 'bg' }, bottom = { edgeFile = 'bottom' } }

	current.framePool = {}
	child.framePool = {}

	-- GuideWindow.lua:1402-1427, 1508-1510
	bottom:SetPoint('TOPLEFT', R, 3, -3)
	bottom:SetPoint('BOTTOMRIGHT', R, -3, 14)
	guide:SetPoint('BOTTOMLEFT', bottom, 'TOPLEFT', 0, -9)
	guide:SetPoint('BOTTOMRIGHT', bottom, 'TOPRIGHT', 0, -9)
	guide:SetHeight(35)
	guide:SetFrameLevel(6)
	guide.text = guide:CreateFontString(nil, 'OVERLAY')
	guide.text:SetPoint('LEFT', guide, 29, 0)
	guide.text:SetPoint('RIGHT', guide, 0, 0)
	guide.text:SetJustifyH('CENTER')
	guide.bg = guide:CreateTexture('RXPFrameGuideNameBG', 'BACKGROUND')
	guide.bg:SetPoint('TOPLEFT', 4, -2)
	guide.bg:SetPoint('BOTTOMRIGHT', -2, 4)
	guide.icon = guide:CreateTexture(nil, 'ARTWORK')
	guide.classIcon = guide:CreateTexture(nil, 'ARTWORK')
	footer:SetPoint('BOTTOMLEFT', R, 'BOTTOMLEFT', 3, 0)
	footer:SetPoint('BOTTOMRIGHT', R, 'BOTTOMRIGHT', -3, 0)
	footer:SetHeight(20)
	footer.text = footer:CreateFontString(nil, 'OVERLAY')
	footer.bg = footer:CreateTexture(nil, 'BACKGROUND')
	footer.cog = CreateFrame('Button', nil, footer)
	footer.icon = footer:CreateTexture(nil, 'ARTWORK')
	scroll:SetPoint('TOPLEFT', bottom, 5, -5)
	scroll:SetPoint('BOTTOMRIGHT', bottom, -20, 7)
	scroll:SetScrollChild(child)
	child:SetPoint('TOPLEFT', scroll, 0, 0)
	child:SetSize(300, 900)
	scroll.ScrollBar = CreateFrame('Slider', nil, scroll)
	scroll.ScrollBar:SetPoint('TOPLEFT', scroll, 'TOPRIGHT', 0, -18)
	-- UIPanelScrollFrameTemplate parts RestedXP re-textures (GuideWindow.lua:1512-1526)
	local bar = scroll.ScrollBar
	for _, name in ipairs({ 'ScrollUpButton', 'ScrollDownButton' }) do
		local b = CreateFrame('Button', nil, bar)
		for _, part in ipairs({ 'Normal', 'Highlight', 'Pushed', 'Disabled' }) do b[part] = b:CreateTexture(nil, 'ARTWORK') end
		bar[name] = b
		lockRXP(b)
	end
	bar.border = bar:CreateTexture(nil, 'BACKGROUND') -- stray region of the template
	bar:SetThumbTexture('rxp-knob')

	function R.UpdateScrollBar()
		for _, name in ipairs({ 'ScrollUpButton', 'ScrollDownButton' }) do
			for _, part in ipairs({ 'Normal', 'Highlight', 'Pushed', 'Disabled' }) do bar[name][part]:SetTexture('rxp-' .. name .. part) end
		end
		bar:SetThumbTexture('rxp-knob')
	end
	R.UpdateScrollBar()

	-- BottomFrame.UpdateFrame (GuideWindow.lua:2146-): hides steps by alpha
	bottom.hiddenSteps = {}
	function bottom.UpdateFrame()
		for i, f in ipairs(child.framePool) do
			f:SetAlpha(bottom.hiddenSteps[i] and 0 or 1)
		end
	end

	-- LoadGuide (GuideWindow.lua:2000-2135): pooled step frames, set up anew each
	-- load, each row 30 tall under the one before.
	function R.LoadGuide(n)
		for i = 1, n do
			local frame = child.framePool[i]
			if not frame then
				frame = CreateFrame('Frame', nil, child, 'BackdropTemplate')
				frame.text = frame:CreateFontString(nil, 'OVERLAY')
				frame.number = CreateFrame('Frame', nil, frame)
				frame.number.text = frame.number:CreateFontString(nil, 'OVERLAY')
				frame.number.text:SetTextColor(1, 0.82, 0)
				child.framePool[i] = frame
				frame.number.text:SetFont('GameFontFace', 8, '')
				frame:SetPoint('TOPLEFT', child, 0, -30 * (i - 1))
				frame:SetPoint('TOPRIGHT', child, 0, -30 * (i - 1))
				frame:SetHeight(30)
				frame:EnableMouse(true)
				lockRXP(frame); lockRXP(frame.number)
			end
			frame:Show()
			frame:SetAlpha(0.66)
			frame:ClearBackdrop()
			frame:SetBackdrop(R.backdrop.bottom)
			frame:SetBackdropColor(0, 0, 0, 0.7)
			set_script(frame, 'OnEnter', function(self) self:SetBackdropColor(0.3, 0.3, 0.3, 0.4) end)
			set_script(frame, 'OnLeave', function(self) self:SetBackdropColor(0, 0, 0, 0.7) end)
			frame.text:SetFont('GameFontFace', 9, '')
		end
		bottom.UpdateFrame()
	end

	-- The current steps (GuideWindow.lua:473-474, 985-1130, 1230-1394).
	current:SetPoint('BOTTOMLEFT', guide, 'TOPLEFT', 0, 2)
	current:SetPoint('BOTTOMRIGHT', guide, 'TOPRIGHT', 0, 2)
	current:SetHeight(25)

	-- SetStepFrameAnchor (GuideWindow.lua:353-395): ClearAllPoints and a fresh
	-- anchor, on every step advance (RXPGuides.lua:2202), every mouse-up on the
	-- window (a local call, GuideWindow.lua:422), at login (RXPGuides.lua:1715)
	-- and on an orientation change. It applies the orientation setting
	-- (R._setting, default 'top'), then flips when the stack would run off the
	-- screen; mode is the orientation it ends up in.
	local function SetTop()
		current:ClearAllPoints()
		current:SetPoint('BOTTOMLEFT', guide, 'TOPLEFT', 0, 2)
		current:SetPoint('BOTTOMRIGHT', guide, 'TOPRIGHT', 0, 2)
		rawset(current, 'anchor', 'TOP')
	end
	local function SetBottom()
		current:ClearAllPoints()
		current:SetPoint('TOPLEFT', R, 'BOTTOMLEFT', 3, 0)
		current:SetPoint('TOPRIGHT', R, 'BOTTOMRIGHT', -3, 0)
		rawset(current, 'anchor', 'BOTTOM')
	end
	local function SetStepFrameAnchor(mode)
		local setting = R._setting or 'top'
		if setting == 'top' then SetTop() else SetBottom() end
		if mode and mode ~= setting then
			if mode == 'top' then SetTop() else SetBottom() end
		end
	end
	R.SetStepFrameAnchor = SetStepFrameAnchor
	-- RXPFrame.OnMouseUp calls the local function, not the field.
	set_script(R, 'OnMouseUp', function() SetStepFrameAnchor(R._flipTo) end)

	R._steps = {}
	R._theme = {}
	function R.AddCurrentStep(step) table.insert(R._steps, step or {}) end
	function R.ClearCurrentSteps() R._steps = {} end
	-- SetStep then UpdateText, as RestedXP runs them on a step change. A step
	-- with hidden = true is one IsFrameShown rejects: alpha 0, 1px tall.
	function current.UpdateText()
		-- ClearFrameData (GuideWindow.lua:640-642), which SetStep always runs first
		for _, frame in ipairs(current.framePool) do frame:Hide() end
		current:Show()
		local c, anchor, total = 0, 0, 0
		for _, step in ipairs(R._steps) do
			c = c + 1
			local frame = current.framePool[c]
			if not frame then
				frame = CreateFrame('Frame', nil, current, 'BackdropTemplate')
				frame.elements = {}
				current.framePool[c] = frame
			end
			frame:Show() -- SetStep: step.active (GuideWindow.lua:1176)
			frame:ClearAllPoints()
			if step.tip then
				frame:SetPoint('BOTTOMLEFT', UIParent, 0, 0)
				frame:SetWidth(230)
				anchor = c - 1
			else
				if anchor < 1 then
					frame:SetPoint('TOPLEFT', current, 0, 0)
					frame:SetPoint('TOPRIGHT', current, 0, 0)
				else
					frame:SetPoint('TOPLEFT', current.framePool[anchor], 'BOTTOMLEFT', 0, -5)
					frame:SetPoint('TOPRIGHT', current.framePool[anchor], 'BOTTOMRIGHT', 0, -5)
				end
				anchor = c
			end
			if not frame.number then
				frame.number = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
				frame.number:SetPoint('TOPLEFT', frame, 7, 5)
				frame.number.text = frame.number:CreateFontString(nil, 'OVERLAY')
				frame.number.text:SetPoint('CENTER', frame.number, 2, 1)
				frame.number.text:SetJustifyH('CENTER')
				frame.number.text:SetTextColor(1, 0.82, 0)
				frame.number.text:SetFont('GameFontFace', 9, '')
				lockRXP(frame.number)
			end
			if frame.theme ~= R._theme then
				rawset(frame, 'theme', R._theme)
				frame:ClearBackdrop()
				frame:SetBackdrop(R.backdrop.edge)
				frame.number:ClearBackdrop()
				frame.number:SetBackdrop(R.backdrop.edge)
			end
			rawset(frame, 'step', step)
			local h = 0
			for j = 1, step.elements or 1 do
				local el = frame.elements[j]
				if not el then
					el = CreateFrame('Frame', nil, frame)
					el.button = CreateFrame('CheckButton', nil, el)
					el.text = el:CreateFontString(nil, 'OVERLAY')
					el.text:SetFont('GameFontFace', 11, '')
					el.icon = el:CreateFontString(nil, 'OVERLAY')
					el.icon:SetFont('GameFontFace', 9, '')
					frame.elements[j] = el
				end
				h = h + 12
			end
			-- UpdateText (GuideWindow.lua:1371-1388)
			local frameHeight
			if step.hidden then
				frame:SetAlpha(0)
				frameHeight = 1
			else
				frame:SetAlpha(1)
				frameHeight = h + 18
			end
			frame:SetHeight(frameHeight)
			if step.tip then frameHeight = -5 end
			if not rxp_frames[frame] then lockRXP(frame) end
			total = total + frameHeight + 5
		end
		current:SetHeight(total - 5)
	end

	-- The theme (re)application: RXPFrame:UpdateVisuals (GuideWindow.lua:52-82).
	function R:UpdateVisuals()
		bottom:ClearBackdrop()
		bottom:SetBackdrop(R.backdrop.edge)
		bottom:SetBackdropColor(0, 0, 0, 1)
		guide:ClearBackdrop()
		guide:SetBackdrop(R.backdrop.guideName)
		guide:SetBackdropColor(0, 0, 0, 1)
		footer:ClearBackdrop()
		footer:SetBackdrop(R.backdrop.guideName)
		footer:SetBackdropColor(0, 0, 0, 1)
		footer.bg:SetTexture('rxp-banner')
		guide.bg:SetTexture('rxp-banner')
		guide.icon:SetTexture('rxp_logo-64')
		guide.classIcon:SetTexture('class')
	end
	-- RestedXP's first look: backdrops set, text fonts given.
	R:UpdateVisuals()
	guide.text:SetFont('GameFontFace', 11, '')
	if opts.footer_font ~= false then footer.text:SetFont('GameFontFace', 9, '') end

	for _, f in ipairs({ R, bottom, guide, footer, scroll, current, child, footer.cog, scroll.ScrollBar }) do lockRXP(f) end
	return R
end

return RXP
