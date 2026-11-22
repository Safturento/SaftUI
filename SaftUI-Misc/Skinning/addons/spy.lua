local st = SaftUI
local SK = st:GetModule('Skinning')

-- Restyles the Spy addon (Spy Forever: a third-party addon, not Blizzard's) in
-- SaftUI's look: its Nearby window, the alert popup, the Statistics window and
-- the Kill on Sight button, in the Skinning page's Theme, Background and font.
-- Its pieces are kept in side tables keyed by Spy's frames; nothing is written
-- onto a Spy frame but its post-hooks, and a script is only ever hooked, never replaced.
--
-- What it relies on Spy doing (names checked against Spy 1.3.8-forever28):
-- - Spy loads by ADDON_LOADED 'Spy'. SpyStatsFrame exists at its load,
--   Spy.MainWindow and Spy.AlertWindow after Spy:CreateMainWindow, and
--   Spy.KoSButton after Spy:CreateKoSButton, so the skin hooks both functions
--   and skins what they made.
-- - Spy_MainWindow and its rows (Spy_MainWindow_Bar<n>) are secure: the window
--   is protected in combat. The skin never moves, sizes, shows, hides or
--   reparents either; only SaftUI's own panels, which are children of them,
--   are placed.
-- - Every piece is type-checked first. One a Spy version lacks keeps Spy's look.
--
-- The skin is installed only if, when it is set up, Skinning -> Spy is on and
-- the Skinning page's Theme isn't Blizzard. Turning it off or on takes a reload.
-- The Theme, Background and font changing after that apply live.
local SP = SK:NewModule('Spy')

local weak = { __mode = 'k' }
local panels = setmetatable({}, weak) -- Spy's frame -> its SaftUI backdrop frame (st:SetBackdropIn)
local kinds = setmetatable({}, weak)  -- Spy's frame -> { kind =, background = } its backdrop is drawn with
local placers = setmetatable({}, weak) -- Spy's frame -> function(frame) that anchors its backdrop where the skin wants it
local fontState = setmetatable({}, weak) -- Spy's font string -> { kind = 'text' | 'title', size = } (what Spy asked for)
local tinted = setmetatable({}, weak)  -- texture -> true: drawn in Text > Muted
local dividers = setmetatable({}, weak) -- SaftUI's divider textures
local dividerOf = setmetatable({}, weak) -- SaftUI's panel -> its divider (a key only)
local grips = setmetatable({}, weak)   -- Spy's resize grips the skin drew
local inverted = setmetatable({}, weak) -- Spy's window -> whether its panel was placed for InvertSpy
local skinnedRows = setmetatable({}, weak) -- Spy's row -> true once skinned
local applyingFont = false             -- the skin's own SetFont isn't taken for Spy's

local installed = false

local function Spy() return _G.Spy end

-- The Skinning page's Theme, Background and font name.
function SP:GetStyle()
	local config = st.config.profile.skinning
	return config.theme, config.background, config.font
end

-- Whether the skin is wanted now: the toggle on and the Theme not Blizzard.
function SP:IsWanted()
	local config = st.config.profile.skinning
	return config.spy and not st:IsBlizzardLook(config.theme, config.background) or false
end

-- A SaftUI backdrop frame behind frame (a child of it one level under it), in kind
-- (panel by default) and the page's Theme, and the page's Background unless one is
-- given. The kind and background are kept, so a redraw draws it as it was.
local function Draw(frame)
	local theme, pageBackground = SP:GetStyle()
	local entry = kinds[frame]
	local backdrop = st:SetBackdropIn(panels, frame, theme, entry.background or pageBackground, entry.kind)
	-- A redraw puts the backdrop around its frame again; where the skin wants it, it is moved back.
	local place = placers[frame]
	if backdrop and place then place(frame) end
	return backdrop
end

local function Panel(frame, kind, background)
	kinds[frame] = { kind = kind or 'panel', background = background }
	return Draw(frame)
end

local function MutedRGB()
	return st:Color('text', 'muted'):GetRGB()
end

-- A texture in Text > Muted, and again when the colors change.
local function Tint(texture)
	if not (texture and texture.SetVertexColor) then return end
	tinted[texture] = true
	texture:SetVertexColor(MutedRGB())
end

-- A one pixel line on frame in the theme's border color; the caller anchors it.
local function ColorDivider(tex)
	local theme, background = SP:GetStyle()
	local look = st:ResolveTheme(theme, background) or st:ResolveTheme()
	local r, g, b = unpack(look.colors.bordercolor)
	tex:SetColorTexture(r, g, b, 0.5)
end

local function MakeDivider(frame)
	local tex = frame:CreateTexture(nil, 'OVERLAY')
	PixelUtil.SetHeight(tex, 1)
	ColorDivider(tex)
	dividers[tex] = true
	return tex
end

-- Spy puts each text on a font family that switches file per alphabet (Spy Forever's
-- Fonts.lua: Russian and CJK names have no glyphs in one roman file), so a bare SetFont
-- with SaftUI's face would draw them as squares. The skin builds a family of its own: the
-- roman member is SaftUI's face and outline, the other alphabets keep the files of the
-- font object Spy set, all at Spy's size. One family per face, size, outline and files.
local ALPHABETS = { 'korean', 'simplifiedchinese', 'traditionalchinese', 'russian' }
local families, familyCount = {}, 0

local function Family(fs, face, size, outline)
	if not CreateFontFamily then return end
	local object = fs.GetFontObject and fs:GetFontObject()
	if not (object and object.GetFontObjectForAlphabet) then return end
	local key, members = face .. '|' .. size .. '|' .. outline, { { alphabet = 'roman', file = face, height = size, flags = outline } }
	for _, alphabet in ipairs(ALPHABETS) do
		local alternate = object:GetFontObjectForAlphabet(alphabet)
		local file = alternate and alternate:GetFont()
		if file then
			members[#members + 1] = { alphabet = alphabet, file = file, height = size, flags = outline }
			key = key .. '|' .. alphabet .. '=' .. file
		end
	end
	if #members == 1 then return end -- no other alphabet to keep: a plain SetFont does as well
	if families[key] == nil then
		familyCount = familyCount + 1
		local ok, family = pcall(CreateFontFamily, 'SaftUISpyFont' .. familyCount, members)
		families[key] = ok and family or false
	end
	return families[key] or nil
end

-- Spy asks for a size with SetFontObject (Spy:ApplyFont's family) or SetFont: the
-- skin keeps that size and puts SaftUI's face and outline on it. kind 'title' is the
-- Window titles font, 'text' the Skinning page's.
local function ApplyFont(fs)
	local state = fontState[fs]
	if not state or not state.size then return end
	local _, _, fontName = SP:GetStyle()
	if state.kind == 'title' then fontName = st.config.profile.headers.font end
	local face, _, outline = st:FontValues(fontName)
	outline = outline or ''
	applyingFont = true
	local ok, err = pcall(function()
		local family = Family(fs, face, state.size, outline)
		if family and fs.SetFontObject then
			-- A font object brings its own color: Spy's is put back.
			local r, g, b, a = fs:GetTextColor()
			fs:SetFontObject(family)
			if r then fs:SetTextColor(r, g, b, a) end
		else
			fs:SetFont(face, state.size, outline)
		end
	end)
	applyingFont = false
	-- Reported, not raised: this runs inside Spy's own call, which carries on.
	if not ok then geterrorhandler()(err) end
end

local function HookFont(fs, kind)
	if not (fs and fs.GetFont) or fontState[fs] then return end
	fontState[fs] = { kind = kind, size = select(2, fs:GetFont()) }
	hooksecurefunc(fs, 'SetFont', function(self, _, size)
		if applyingFont then return end
		fontState[self].size = size
		ApplyFont(self)
	end)
	if fs.SetFontObject then
		hooksecurefunc(fs, 'SetFontObject', function(self)
			if applyingFont then return end
			fontState[self].size = select(2, self:GetFont())
			ApplyFont(self)
		end)
	end
	ApplyFont(fs)
end

local GRIP_FLIPS = {
	DragBottomRight = { 0, 1, 0, 1 }, DragBottomLeft = { 1, 0, 0, 1 },
	DragTopRight = { 0, 1, 1, 0 }, DragTopLeft = { 1, 0, 1, 0 },
}

local BUTTON_ICONS = {
	CloseButton = 'x', LeftButton = 'chevronLeft', RightButton = 'chevronRight',
	ClearButton = 'eraser', StatsButton = 'chartNoAxesColumn',
}

-- An icon button: Spy's normal and pushed art replaced by the icon in Text > Muted, its
-- highlight by SaftUI's flat one, and the hover drawn by the states.
local function SkinIconButton(button, icon)
	if type(button) ~= 'table' or not button.SetNormalTexture or not icon then return end
	button:SetNormalTexture(icon)
	button:SetPushedTexture(icon)
	button:SetHighlightTexture(st.BLANK_TEX, 'BLEND')
	Tint(button:GetNormalTexture())
	Tint(button:GetPushedTexture())
	-- Only the hover is a state piece: a pressed icon button shows its own pushed art, which
	-- the helper would make a flat square if it adopted it.
	st:AddStates(button, 'icon', { pieces = { hover = button:GetHighlightTexture() } })
end

-- A resize grip: SaftUI's corner arrow, flipped to its corner, as st:EnableResizing draws
-- SaftUI's own: a 'glyph', its three textures one picture in Text > Muted at rest and the
-- helper's tones under the mouse and held.
local function SkinGrip(grip, flip)
	if type(grip) ~= 'table' or not grip.SetNormalTexture then return end
	grip:SetNormalTexture(st.textures.cornerbr)
	grip:SetPushedTexture(st.textures.cornerbr)
	grip:SetHighlightTexture(st.textures.cornerbr)
	local normal, pushed, highlight = grip:GetNormalTexture(), grip:GetPushedTexture(), grip:GetHighlightTexture()
	highlight:SetBlendMode('BLEND')
	for _, tex in ipairs({ normal, pushed, highlight }) do tex:SetTexCoord(unpack(flip)) end
	st:AddStates(grip, 'glyph', {
		glyph = { normal, pushed, highlight },
		glyphRest = MutedRGB,
	})
	st:PaintStates(grip)
	grips[grip] = true
end

-- A row: a flat bar with a thin border (Spy keeps the bar's color), SaftUI's face
-- on both texts at the sizes Spy asks for, the class icon cropped. The row itself,
-- which is secure, is never touched: only its children.
function SP:SkinRow(row)
	if type(row) ~= 'table' or skinnedRows[row] then return end
	local bar = row.StatusBar
	if type(bar) ~= 'table' then return end
	skinnedRows[row] = true
	if bar.SetStatusBarTexture then bar:SetStatusBarTexture(st.BLANK_TEX) end
	Panel(bar, 'control', 'none')
	HookFont(row.LeftText, 'text')
	HookFont(row.RightText, 'text')
	local icon = row.ClassIcon
	if icon then
		st:SkinIcon(icon)
		-- Spy sets the class atlas after its coordinates, which resets them: the crop again.
		if icon.SetAtlas then
			hooksecurefunc(icon, 'SetAtlas', function(self) st:SkinIcon(self) end)
		end
	end
end

-- Puts SaftUI's bar texture back on every row (Spy sets its own on its texture option
-- and a profile change).
function SP:FlatRows()
	local window = Spy() and Spy().MainWindow
	if type(window) ~= 'table' or type(window.Rows) ~= 'table' then return end
	for _, row in pairs(window.Rows) do
		local bar = type(row) == 'table' and row.StatusBar
		if bar and bar.SetStatusBarTexture then bar:SetStatusBarTexture(st.BLANK_TEX) end
	end
end

-- Whether Spy anchored its title bar at the window's bottom (its InvertSpy option, read
-- when the window was made: a toggle takes a reload), from where the bar actually is.
local function IsInverted(bar)
	local point = type(bar) == 'table' and bar.GetPoint and bar:GetPoint(1)
	return point == 'BOTTOMLEFT' or point == 'BOTTOMRIGHT'
end

-- What Spy puts back on every ApplyBorderStyle and ManageBarsDisplayed: its title bar's
-- backdrop, its gold ForeverBorder on the window and the title bar, its own background.
function SP:RestyleMain()
	local window = Spy() and Spy().MainWindow
	if type(window) ~= 'table' then return end
	local bar = window.TitleBar
	if type(bar) == 'table' then
		if bar.SetBackdrop then bar:SetBackdrop(nil) end
		if bar.ForeverBorder then bar.ForeverBorder:Hide() end
	end
	if window.ForeverBorder then window.ForeverBorder:Hide() end
	if window.Background and window.Background.SetAlpha then window.Background:SetAlpha(0) end
	-- The Invert option moved the title bar: the panel goes where it is now.
	if placers[window] and panels[window] and inverted[window] ~= IsInverted(bar) then placers[window](window) end
end

-- Draws what each of Spy's windows is made of. Tasks that follow fill these; each
-- one is called only when its target exists, and an error in one doesn't stop the
-- others.
function SP:SkinMain()
	local window = Spy() and Spy().MainWindow
	if type(window) ~= 'table' then return end

	-- One panel from the title bar to the window's bottom, which follows the last shown row
	-- (inverted, the title bar is at the bottom and the panel runs from the window's top to
	-- it), and a line between the title bar and the rows.
	local bar = window.TitleBar
	if type(bar) == 'table' then
		placers[window] = function(w)
			local panel = panels[w]
			local invert = IsInverted(bar)
			inverted[w] = invert
			panel:ClearAllPoints()
			local line = dividerOf[panel]
			if line then line:ClearAllPoints() end
			if invert then
				-- The rows start 34 down, where Spy's own inverted Background does.
				local _, _, _, x, y = w.Background and w.Background:GetPoint(1)
				panel:SetPoint('TOPLEFT', w, 'TOPLEFT', x or 0, y or -34)
				panel:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
				if line then
					line:SetPoint('BOTTOMLEFT', bar, 'TOPLEFT', 0, 0)
					line:SetPoint('BOTTOMRIGHT', bar, 'TOPRIGHT', 0, 0)
				end
			else
				panel:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
				panel:SetPoint('BOTTOMRIGHT', w, 'BOTTOMRIGHT', 0, 0)
				if line then
					line:SetPoint('TOPLEFT', bar, 'BOTTOMLEFT', 0, 0)
					line:SetPoint('TOPRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
				end
			end
		end
	end
	local panel = Panel(window)
	if panel and type(bar) == 'table' and not dividerOf[panel] then
		dividerOf[panel] = MakeDivider(panel)
		placers[window](window)
	end
	SP:RestyleMain()

	HookFont(window.Title, 'title')
	HookFont(window.CountFrame and window.CountFrame.Text, 'title')
	for key, icon in pairs(BUTTON_ICONS) do SkinIconButton(window[key], st.icons[icon]) end
	for key, flip in pairs(GRIP_FLIPS) do SkinGrip(window[key], flip) end
	if type(window.Rows) == 'table' then
		for _, row in pairs(window.Rows) do SP:SkinRow(row) end
	end
end

-- The skin's shared pieces, for the files that skin Spy's other windows
-- (spy_alert.lua, spy_stats.lua, spy_kos.lua, loaded after this one). They
-- define SP:SkinAlert, SP:SkinStats and SP:SkinKoS; Setup looks those up when
-- it runs, after every file has loaded.
local configCallbacks, colorCallbacks = {}, {}

SP.lib = {
	-- The other files' refresh callbacks: SP:UpdateConfig and SP:OnColorsChanged run
	-- them, each on its own, so one that errors does not stop the rest.
	OnConfig = function(fn) configCallbacks[#configCallbacks + 1] = fn end,
	OnColors = function(fn) colorCallbacks[#colorCallbacks + 1] = fn end,
	weak = weak,
	panels = panels,
	placers = placers,
	Draw = Draw,
	Panel = Panel,
	MutedRGB = MutedRGB,
	Tint = Tint,
	MakeDivider = MakeDivider,
	HookFont = HookFont,
	SkinIconButton = SkinIconButton,
}

function SP:SkinAlert() end
function SP:SkinStats() end
function SP:SkinKoS() end

local function Run(fn)
	xpcall(fn, geterrorhandler(), SP)
end

-- Installs the skin once Spy and its pieces exist, and hooks the two functions that
-- make the windows later.
function SP:Setup()
	if installed or not self:IsWanted() then return end
	local spy = Spy()
	if type(spy) ~= 'table' then return end
	installed = true

	Run(self.SkinStats)
	Run(self.SkinMain)
	Run(self.SkinAlert)
	Run(self.SkinKoS)

	if type(spy.CreateMainWindow) == 'function' then
		hooksecurefunc(spy, 'CreateMainWindow', function()
			Run(SP.SkinMain)
			Run(SP.SkinAlert)
		end)
	end
	for _, name in ipairs({ 'ApplyBorderStyle', 'ManageBarsDisplayed' }) do
		if type(spy[name]) == 'function' then
			hooksecurefunc(spy, name, function() Run(SP.RestyleMain) end)
		end
	end
	for _, name in ipairs({ 'UpdateBarTextures', 'SetBarTextures' }) do
		if type(spy[name]) == 'function' then
			hooksecurefunc(spy, name, function() Run(SP.FlatRows) end)
		end
	end
	if type(spy.SetupBar) == 'function' then
		hooksecurefunc(spy, 'SetupBar', function(_, row) Run(function() SP:SkinRow(row) end) end)
	end
	if type(spy.CreateRow) == 'function' then
		hooksecurefunc(spy, 'CreateRow', function(_, num)
			Run(function()
				local window = Spy() and Spy().MainWindow
				SP:SkinRow(type(window) == 'table' and type(window.Rows) == 'table' and window.Rows[num])
			end)
		end)
	end
	if type(spy.CreateKoSButton) == 'function' then
		hooksecurefunc(spy, 'CreateKoSButton', function() Run(SP.SkinKoS) end)
	end
end

function SP:ADDON_LOADED(_, name)
	if name ~= 'Spy' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

-- A profile change, or the Skinning page's Theme, Background or font: draws the
-- panels again.
function SP:UpdateConfig()
	if not installed then return end
	for frame in pairs(panels) do
		if kinds[frame] then Draw(frame) end
	end
	for tex in pairs(dividers) do ColorDivider(tex) end
	for fs in pairs(fontState) do ApplyFont(fs) end
	for _, fn in ipairs(configCallbacks) do xpcall(fn, geterrorhandler()) end
end

-- A shared font or a font setting changed (st:FontsChanged): the Skinning font on
-- Spy's texts again.
function SP:OnFontsChanged()
	if not installed then return end
	for fs in pairs(fontState) do ApplyFont(fs) end
end

-- A color changed (st:ColorsChanged): what is colored from the theme or the text
-- colors, colored again.
function SP:OnColorsChanged(group, key)
	if not installed then return end
	for tex in pairs(tinted) do tex:SetVertexColor(MutedRGB()) end
	for grip in pairs(grips) do st:PaintStates(grip) end
	for tex in pairs(dividers) do ColorDivider(tex) end
	for _, fn in ipairs(colorCallbacks) do xpcall(fn, geterrorhandler(), group, key) end
end

-- Off (Skinning -> Spy), or under the Blizzard theme, nothing is hooked or touched.
function SP:OnEnable()
	if not self:IsWanted() then return end
	if C_AddOns.IsAddOnLoaded('Spy') and Spy() then
		self:Setup()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
