local st = SaftUI
local SK = st:GetModule('Skinning')
local CP = SK:NewModule('Blizzard_ColorPicker')

--[[
	Skins Blizzard's color picker (ColorPickerFrame, in Blizzard_ColorPickerFrame)
	in SaftUI's look, while Skinning -> Color picker is on and the Skinning page's
	Theme isn't Blizzard. Under the Blizzard theme, or with the toggle off, the
	picker keeps Blizzard's look: every piece below is put back as Blizzard's
	template had it, and a theme switch or the toggle goes between the two live
	(Skinning's UpdateConfig; the colors follow st:ColorsChanged).

	What changes (names are the parentKeys of Blizzard's XML, the same on Forever
	and retail, checked 2026-11-13 against the forever and live branches of
	Gethe/wow-ui-source):
	  - ColorPickerFrame: SaftUI's panel behind it (st:SetBackdropIn, kind panel,
	    a child one level under it, so it follows the frame's size, which
	    Blizzard's OnShow changes with the alpha slider), and .Border (the
	    NineSlice dialog frame, DialogBorderTemplate) faded.
	  - .Header (DialogHeaderTemplate): its LeftBG, RightBG and CenterBG metal
	    faded, its .Text in the Skinning font.
	  - .Footer.OkayButton and .Footer.CancelButton (UIPanelButtonTemplate): the
	    button's Left, Middle and Right art and its highlight texture faded, a
	    box of SaftUI's (kind control) drawn inside it, a hover of SaftUI's in
	    the HIGHLIGHT layer, and the text in the Skinning font (the button's
	    three state fonts).
	  - .Content.HexBox (InputBoxInstructionsTemplate): its Left, Middle and Right
	    border art faded, SaftUI's backdrop (kind control) behind it with the
	    white border while it has focus, as st:SkinEditBox draws a box, and its
	    text, its Instructions and the "#" (.Hash) in the Skinning font.

	Left as Blizzard's: the wheel and the sliders (.Content.ColorPicker and its
	textures), the swatches and the alpha checkerboard (.Content.ColorSwatchCurrent,
	.ColorSwatchOriginal, .AlphaBackground), the drag bar, and Forever's gamepad
	pieces (FrameGlow and the jump hints, which are hidden unless a gamepad is on).

	Taint (.agents/taint.md). The picker isn't a secure frame, but other addons
	drive it (swatchFunc, cancelFunc, opacityFunc, hasOpacity ...), so it is only
	looked at: nothing is written onto it or its children (SaftUI's pieces are
	kept here, in weak tables keyed by Blizzard's frames, or are frames and
	textures SaftUI made), no script is set or replaced, and no function of
	Blizzard's runs from here. The only hooks are two post-hooks on the hex box
	(HookScript OnEditFocusGained and OnEditFocusLost) that color SaftUI's own
	backdrop. Blizzard's frames get widget calls only: alpha on regions whose
	alpha Blizzard never sets (the NineSlice border, the header metal, the
	buttons' Left, Middle and Right, the highlight texture, the hex box's
	border), and fonts, set to SaftUI's font object and put back by the named
	Blizzard font (never from GetFontObject, rule 10). Every step is nil-guarded
	so a region a client lacks skips its step.

	Timing: Blizzard_ColorPickerFrame has no LoadOnDemand in either client's TOC
	(it loads at login, before SaftUI), so the picker normally exists when
	SaftUI's modules enable; if it doesn't, the skin waits for the addon
	(st:OnBlizzardAddon). It is skinned once (installed), and styled again only
	on a profile, theme or toggle change.
]]

-- The font each text had in Blizzard's templates, by the named font (put back
-- by name, never from GetFontObject: .agents/taint.md rule 10).
local BLIZZARD_FONTS = {
	title = 'GameFontNormal',         -- DialogHeaderTemplate's Text
	hash = 'GameFontNormalLarge',     -- HexBox.Hash
	instructions = 'GameFontDisableSmall', -- InputBoxInstructionsTemplate's Instructions
	hex = 'GameFontHighlightSmall',   -- the box's own text (InputBoxInstructionsTemplate's FontString)
	normal = 'GameFontNormalOutline', -- UIPanelButtonNoTooltipTemplate's NormalFont
	highlight = 'GameFontHighlightOutline',
	disabled = 'GameFontDisable',
}

local HEADER_ART = { 'LeftBG', 'RightBG', 'CenterBG' }
local BUTTON_ART = { 'Left', 'Middle', 'Right' }
local BOX_ART = { 'Left', 'Middle', 'Right' } -- InputBoxVisualTemplate's border
local BUTTON_INSET = 1 -- the box inside the button, so the two buttons, which touch, don't share a line

-- What SaftUI made or styled, keyed by Blizzard's frames (weak keys).
local weak = { __mode = 'k' }
local panels = setmetatable({}, weak)    -- ColorPickerFrame -> its panel (st:SetBackdropIn)
local buttons = setmetatable({}, weak)   -- button -> { box, hover }
local boxes = setmetatable({}, weak)     -- HexBox -> its backdrop (st:SetBackdropIn)
local hooked = setmetatable({}, weak)    -- HexBox -> true once its focus hooks are on
local styled = setmetatable({}, weak)    -- ColorPickerFrame -> true once SaftUI has changed anything on it

local installed = false

local function Profile() return st.config.profile end

local function Look()
	local config = Profile().skinning
	return config.theme, config.background
end

-- Whether the picker wears SaftUI's look now: the toggle on and the Skinning
-- page's look not Blizzard's.
local function Active()
	local config = Profile().skinning
	return config.color_picker and not st:IsBlizzardLook(config.theme, config.background) or false
end
function CP:IsActive() return Active() end

local function Apply(fn, ...) xpcall(fn, geterrorhandler(), ...) end

-- The font a text of kind wears: SaftUI's (the Skinning font) while active,
-- else Blizzard's named font.
local function FontFor(kind, active)
	if active then return st:GetFont(Profile().skinning.font) end
	return _G[BLIZZARD_FONTS[kind]]
end

-- SaftUI's font on a font string or edit box (anything with SetFontObject), or
-- Blizzard's named font back.
local function PutFont(target, kind, active)
	local font = FontFor(kind, active)
	if target and target.SetFontObject and font then target:SetFontObject(font) end
end

local function FadeAll(parent, keys, active)
	for _, key in ipairs(keys) do
		local region = parent[key]
		if region and region.SetAlpha then region:SetAlpha(active and 0 or 1) end
	end
end

local function HoverColor()
	return Profile().colors.button.normal:GetRGB()
end

------------------------------------------------------------------ the pieces

local function StylePanel(frame, active)
	local theme, background = Look()
	st:SetBackdropIn(panels, frame, active and theme or 'none', background, 'panel')
	if panels[frame] then panels[frame]:SetShown(active) end
	if frame.Border and frame.Border.SetAlpha then frame.Border:SetAlpha(active and 0 or 1) end
end

local function StyleHeader(frame, active)
	local header = frame.Header
	if not header then return end
	FadeAll(header, HEADER_ART, active)
	PutFont(header.Text, 'title', active)
end

local function StyleButton(button, active)
	if not button then return end
	local entry = buttons[button]
	if not entry then
		if not active then return end
		local box = st:CreateFrame('Frame', nil, button)
		local level = button:GetFrameLevel()
		if not issecretvalue(level) then box:SetFrameLevel(math.max(0, level - 1)) end
		st:SetInside(box, BUTTON_INSET)
		-- In the HIGHLIGHT layer, which the game shows only under the mouse.
		local hover = button:CreateTexture(nil, st.ThemeArt.HOVER_LAYER)
		hover:SetTexture(st.BLANK_TEX)
		hover:SetAllPoints(box)
		entry = { box = box, hover = hover }
		buttons[button] = entry
	end

	local theme, background = Look()
	st:SetTemplate(entry.box, active and theme or 'none', background, 'control')
	entry.box:SetShown(active)
	entry.hover:SetShown(active)
	entry.hover:SetVertexColor(HoverColor())

	FadeAll(button, BUTTON_ART, active)
	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	if highlight then highlight:SetAlpha(active and 0 or 1) end
	-- The text's font in each state, which the game puts on the text as the
	-- button changes state.
	if button.SetNormalFontObject then
		button:SetNormalFontObject(FontFor('normal', active))
		button:SetHighlightFontObject(FontFor('highlight', active))
		button:SetDisabledFontObject(FontFor('disabled', active))
	end
end

-- The white border a focused box shows, kept through a theme recolor.
local function ColorFocus(box)
	local backdrop = boxes[box]
	if backdrop and Active() and box:HasFocus() then
		st:SetBorderColor(backdrop, 1, 1, 1, 1)
	end
end

local function HookBox(box)
	if hooked[box] or not box.HookScript then return end
	hooked[box] = true
	box:HookScript('OnEditFocusGained', ColorFocus)
	box:HookScript('OnEditFocusLost', function(self)
		local backdrop = boxes[self]
		if backdrop then st:SetBorderColor(backdrop) end
	end)
	st:KeepOwnColors(box, ColorFocus)
end

local function StyleHexBox(frame, active)
	local content = frame.Content
	local box = content and content.HexBox
	if not box then return end
	if not boxes[box] and not active then return end
	local theme, background = Look()
	st:SetBackdropIn(boxes, box, active and theme or 'none', background, 'control')
	if boxes[box] then boxes[box]:SetShown(active) end
	if active then HookBox(box) end
	FadeAll(box, BOX_ART, active)
	PutFont(box, 'hex', active)
	PutFont(box.Instructions, 'instructions', active)
	PutFont(box.Hash, 'hash', active)
	if active then ColorFocus(box) end
end

------------------------------------------------------------------ all of it

-- Puts the look on the picker, or Blizzard's back (only once SaftUI has styled
-- it: with the toggle off at load, or under the Blizzard theme, it is never
-- touched). Widget calls only on a frame that isn't protected.
function CP:StyleAll()
	local frame = _G.ColorPickerFrame
	if not frame then return end
	local active = Active()
	if not active and not styled[frame] then return end
	if InCombatLockdown() and frame:IsProtected() then
		st:QueueAfterCombat('colorpicker', function() CP:StyleAll() end)
		return
	end
	styled[frame] = true
	Apply(StylePanel, frame, active)
	Apply(StyleHeader, frame, active)
	local footer = frame.Footer
	if footer then
		Apply(StyleButton, footer.OkayButton, active)
		Apply(StyleButton, footer.CancelButton, active)
	end
	Apply(StyleHexBox, frame, active)
end

-- Skins the picker once, then styles it.
function CP:Install()
	if installed or not _G.ColorPickerFrame then return end
	installed = true
	self:StyleAll()
end

-- A profile change, the Skinning page's Theme, Background, font or Color
-- picker: on, the picker takes the look; off or under the Blizzard theme,
-- Blizzard's look goes back on, at once.
function CP:UpdateConfig()
	if installed then
		self:StyleAll()
	elseif Profile().skinning.color_picker then
		self:Install()
	end
end

-- A theme recolor or a color change: the buttons' hover takes the color again
-- (the theme engine redraws the panel, the boxes and the hex box's backdrop).
function CP:OnColorsChanged()
	for _, entry in pairs(buttons) do entry.hover:SetVertexColor(HoverColor()) end
end

-- Off (Skinning -> Color picker), nothing is hooked or touched until it's turned on.
function CP:OnEnable()
	if not Profile().skinning.color_picker then return end
	if _G.ColorPickerFrame then
		self:Install()
	elseif C_AddOns.DoesAddOnExist('Blizzard_ColorPickerFrame') then
		st:OnBlizzardAddon('Blizzard_ColorPickerFrame', function() self:Install() end)
	end
end
