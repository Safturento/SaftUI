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
	    Blizzard's OnShow changes with the alpha slider), reaching up over the
	    header's band so the drag bar leaves no invisible strip above it, and
	    .Border (the NineSlice dialog frame, DialogBorderTemplate) faded. Its
	    frames are kept on whole pixels by the game (SetRoundLayoutToNearestPixel),
	    since the centered picker is 331 or 388 wide and its edges can sit on
	    half pixels.
	  - .Header (DialogHeaderTemplate): its LeftBG, RightBG and CenterBG metal
	    faded, its .Text in the font kit dialogs' titles wear (Window titles),
	    centered in a strip of that height at the top of the panel (its anchor
	    is put back by a restore).
	  - .Footer.OkayButton and .Footer.CancelButton (UIPanelButtonTemplate): the
	    button's Left, Middle and Right art and its highlight texture faded, a
	    box of SaftUI's (kind control) drawn inside it whose edge turns the
	    accent blue under the mouse, as the kit's buttons do, and the text in
	    the Skinning font (the button's three state fonts). The label stays
	    Blizzard's, uncovered.
	  - .Content.HexBox (InputBoxInstructionsTemplate): its Left, Middle and Right
	    border art faded, SaftUI's backdrop (kind control) behind it with the
	    white border while it has focus, as st:SkinEditBox draws a box, and its
	    text, its Instructions and the "#" (.Hash) in the Skinning font (the
	    last two keeping the grey Blizzard's XML gives them).

	Left as Blizzard's: the wheel and the sliders (.Content.ColorPicker and its
	textures), the swatches and the alpha checkerboard (.Content.ColorSwatchCurrent,
	.ColorSwatchOriginal, .AlphaBackground), the drag bar, and Forever's gamepad
	pieces (FrameGlow and the jump hints, which are hidden unless a gamepad is on).

	Taint (.agents/taint.md). The picker isn't a secure frame, but other addons
	drive it (swatchFunc, cancelFunc, opacityFunc, hasOpacity ...), so it is only
	looked at: nothing is written onto it or its children (SaftUI's pieces are
	kept here, in weak tables keyed by Blizzard's frames, or are frames and
	textures SaftUI made), no script is set or replaced, and no function of
	Blizzard's runs from here. The only hooks are HookScript post-hooks on the
	hex box (OnEditFocusGained, OnEditFocusLost) and on Okay and Cancel
	(OnEnter, OnLeave) that color SaftUI's own boxes, writing nothing onto
	Blizzard's. Blizzard's frames get widget calls only: alpha on regions whose
	alpha Blizzard never sets (the NineSlice border, the header metal, the
	buttons' Left, Middle and Right, the highlight texture, the hex box's
	border), and fonts and colors, set to SaftUI's and put back from what was
	read before the first restyle (a font only if it is a named global Font,
	else Blizzard's named font: rule 10), kept in a weak table of SaftUI's. Every step is nil-guarded
	so a region a client lacks skips its step.

	Timing: Blizzard_ColorPickerFrame has no LoadOnDemand in either client's TOC
	(it loads at login, before SaftUI), so the picker normally exists when
	SaftUI's modules enable; if it doesn't, the skin waits for the addon
	(st:OnBlizzardAddon). It is skinned once (installed), and styled again only
	on a profile, theme or toggle change.
]]

-- Blizzard's font for each text, by its named font: the fallback for a font
-- that can't be put back from what was read (.agents/taint.md rule 10). The
-- buttons' are UIPanelButtonNoTooltipTemplate's (SecureUIPanelTemplates.xml).
local BLIZZARD_FONTS = {
	title = 'GameFontNormal',              -- DialogHeaderTemplate's Text
	hash = 'GameFontNormalLarge',          -- HexBox.Hash
	instructions = 'GameFontDisableSmall', -- InputBoxInstructionsTemplate's Instructions
	hex = 'GameFontHighlightSmall',        -- the box's own text
	normal = 'GameFontNormal',             -- the buttons' NormalFont
	highlight = 'GameFontHighlight',
	disabled = 'GameFontDisable',
}
local BUTTON_FONTS = {
	normal = { 'GetNormalFontObject', 'SetNormalFontObject' },
	highlight = { 'GetHighlightFontObject', 'SetHighlightFontObject' },
	disabled = { 'GetDisabledFontObject', 'SetDisabledFontObject' },
}

local HEADER_ART = { 'LeftBG', 'RightBG', 'CenterBG' }
local BUTTON_ART = { 'Left', 'Middle', 'Right' }
local BOX_ART = { 'Left', 'Middle', 'Right' } -- InputBoxVisualTemplate's border
local BUTTON_INSET = 1 -- the box inside the button, so the two buttons, which touch, don't share a line

-- What SaftUI made or styled, keyed by Blizzard's frames (weak keys).
local weak = { __mode = 'k' }
local panels = setmetatable({}, weak)    -- ColorPickerFrame -> its panel (st:SetBackdropIn)
local buttons = setmetatable({}, weak)   -- button -> { box }
local boxes = setmetatable({}, weak)     -- HexBox -> its backdrop (st:SetBackdropIn)
local hooked = setmetatable({}, weak)    -- HexBox or button -> true once its hooks are on
local hovered = setmetatable({}, weak)   -- button -> true while the mouse is over it
local styled = setmetatable({}, weak)    -- ColorPickerFrame -> true once SaftUI has changed anything on it
-- What Blizzard had before the first restyle, read then and put back by a
-- restore: a text's font and color, a button's three state fonts, the title's
-- first anchor.
local saved = setmetatable({}, weak)

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

-- A font object read from Blizzard, if it is a named global Font (the only
-- kind safe to set again: rule 10), else nil.
local function Named(font)
	local name = font and font.GetName and font:GetName()
	if name and _G[name] == font then return font end
end

-- The font Blizzard had on a text of kind: what was read before the first
-- restyle, or its named font.
local function Original(target, kind)
	local entry = saved[target]
	return entry and entry.font or _G[BLIZZARD_FONTS[kind]]
end

local function TitleFont() return st:GetFont(Profile().headers.font) end
local function SkinFont() return st:GetFont(Profile().skinning.font) end

-- SaftUI's font on a font string or edit box (anything with SetFontObject), or
-- what Blizzard had back. keepColor keeps the color it shows through the
-- change (the "#" and the placeholder are colored by Blizzard's XML, which the
-- font's own color would replace); a restore puts back the color read.
local function PutFont(target, kind, active, keepColor)
	if not target or not target.SetFontObject then return end
	if active then
		if not saved[target] then
			local entry = { font = Named(target.GetFontObject and target:GetFontObject()) }
			local r, g, b, a = target:GetTextColor()
			if r and not issecretvalue(r) then entry.color = { r, g, b, a } end
			saved[target] = entry
		end
		local font = kind == 'title' and TitleFont() or SkinFont()
		if font then target:SetFontObject(font) end
		local color = saved[target].color
		if keepColor and color then target:SetTextColor(unpack(color)) end
	elseif saved[target] then
		local font = Original(target, kind)
		if font then target:SetFontObject(font) end
		local color = saved[target].color
		if color then target:SetTextColor(unpack(color)) end
	end
end

local function FadeAll(parent, keys, active)
	for _, key in ipairs(keys) do
		local region = parent[key]
		if region and region.SetAlpha then region:SetAlpha(active and 0 or 1) end
	end
end

-- Has the game keep SaftUI's frame on whole pixels in screen space: the
-- picker is centered and 331 or 388 wide, so its edges, and everything
-- anchored to them, can sit on half pixels (.agents/architecture.md, "Half
-- pixels from centred anchors"). Only SaftUI's own frames and textures, and
-- nothing of Blizzard's is moved.
local function Round(region)
	if not region then return end
	if region.SetRoundLayoutToNearestPixel then region:SetRoundLayoutToNearestPixel(true) end
	if region.GetRegions then
		for _, part in ipairs({ region:GetRegions() }) do Round(part) end
		for _, kid in ipairs({ region:GetChildren() }) do Round(kid) end
	end
end

------------------------------------------------------------------ the pieces

local function StylePanel(frame, active)
	local theme, background = Look()
	st:SetBackdropIn(panels, frame, active and theme or 'none', background, 'panel')
	local panel = panels[frame]
	if panel then
		panel:SetShown(active)
		if active then
			-- Over the header's band too (the drag bar covers it, so no invisible strip
			-- is left above the panel): Blizzard's Header sits `rise` above the
			-- frame's top. Anchored here, so a redraw leaves it where it is.
			local rise = 0
			local header = frame.Header
			if header and header.GetPoint then
				local point, relativeTo, _, _, y = header:GetPoint(1)
				if point == 'TOP' and relativeTo == frame and y and not issecretvalue(y) then rise = y end
			end
			local inset = st:ThemeInset(theme, background, 'panel')
			panel:ClearAllPoints()
			panel:SetPoint('TOPLEFT', frame, 'TOPLEFT', -inset, rise + inset)
			panel:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', inset, -inset)
			Round(panel)
		end
	end
	if frame.Border and frame.Border.SetAlpha then frame.Border:SetAlpha(active and 0 or 1) end
end

-- The title in the font kit dialogs titles wear (Window titles), centered in
-- a strip of the Window titles height at the top of the panel, which is
-- where a kit dialog's title sits. Blizzard's anchor is put back by a restore.
local function StyleTitle(header, active)
	local text = header.Text
	if not text then return end
	PutFont(text, 'title', active)
	if not text.GetPoint then return end
	if active then
		if not saved[text] then return end
		if not saved[text].point then
			local point, relativeTo, relativePoint, x, y = text:GetPoint(1)
			saved[text].point = { point, relativeTo, relativePoint, x, y }
		end
		text:ClearAllPoints()
		text:SetPoint('CENTER', header, 'TOP', 0, -Profile().headers.height / 2)
	elseif saved[text] and saved[text].point then
		text:ClearAllPoints()
		text:SetPoint(unpack(saved[text].point))
	end
end

local function StyleHeader(frame, active)
	local header = frame.Header
	if not header then return end
	FadeAll(header, HEADER_ART, active)
	StyleTitle(header, active)
end

-- The kit's hover: the box's edge turns the accent blue under the mouse.
local function ColorHover(button)
	local entry = buttons[button]
	if not entry or not Active() then return end
	if hovered[button] then
		st:SetBorderColor(entry.box, Profile().colors.button.blue:GetRGB())
	else
		st:SetBorderColor(entry.box)
	end
end

local function HookButton(button)
	if hooked[button] or not button.HookScript then return end
	hooked[button] = true
	-- Post-hooks that only color SaftUI's own box. The game passes a second
	-- argument (motion) to OnEnter and OnLeave, which they don't use.
	button:HookScript('OnEnter', function(self) hovered[self] = true; ColorHover(self) end)
	button:HookScript('OnLeave', function(self) hovered[self] = nil; ColorHover(self) end)
	st:KeepOwnColors(button, ColorHover)
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
		entry = { box = box }
		buttons[button] = entry
		-- The three state fonts Blizzard's template gave it, read once.
		local fonts = {}
		for state, methods in pairs(BUTTON_FONTS) do
			if button[methods[1]] then fonts[state] = Named(button[methods[1]](button)) end
		end
		saved[button] = fonts
	end

	local theme, background = Look()
	st:SetTemplate(entry.box, active and theme or 'none', background, 'control')
	entry.box:SetShown(active)
	if active then
		Round(entry.box)
		HookButton(button)
	end
	hovered[button] = hovered[button] and active or nil
	if active then ColorHover(button) end

	FadeAll(button, BUTTON_ART, active)
	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	if highlight then highlight:SetAlpha(active and 0 or 1) end
	-- The text's font in each state, which the game puts on the text as the
	-- button changes state.
	for state, methods in pairs(BUTTON_FONTS) do
		if button[methods[2]] then
			local font = active and SkinFont() or saved[button][state] or _G[BLIZZARD_FONTS[state]]
			if font then button[methods[2]](button, font) end
		end
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
	if boxes[box] then
		boxes[box]:SetShown(active)
		if active then Round(boxes[box]) end
	end
	if active then HookBox(box) end
	FadeAll(box, BOX_ART, active)
	PutFont(box, 'hex', active)
	PutFont(box.Instructions, 'instructions', active, true)
	PutFont(box.Hash, 'hash', active, true)
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
-- Blizzard's look goes back on, at once. (The title follows Window titles'
-- font on the next of these, not the moment it changes.)
function CP:UpdateConfig()
	if installed then
		self:StyleAll()
	elseif Profile().skinning.color_picker then
		self:Install()
	end
end

-- A theme recolor or a color change: the buttons' hover edge takes the color
-- again (the theme engine redraws the rest).
function CP:OnColorsChanged()
	for button in pairs(buttons) do ColorHover(button) end
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
