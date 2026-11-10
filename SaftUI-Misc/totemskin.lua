local st = SaftUI
local TB = st:GetModule('TotemBar')

--[[
	SaftUI's look for WoW Forever's totem bar (totembar.lua says what the bar is and how
	Blizzard shows and places it). Every button looks like SaftUI's action bar buttons: a
	flat backdrop in the profile's button template, the icon cropped square, flat hover,
	pushed and checked, and the profile's button font on the keybind.
	SaftUI-ActionBars/skin.lua is the visual reference, but Misc only needs Core, so
	nothing here calls into ActionBars. The buttons' size is the bar's setting, and
	totembar.lua sizes them, out of combat. The skin holds at any size: the backdrop fills
	the button and the icon is inset from the button's edges by the template's border.

	What's skinned:
	  - The summon and recall buttons, with the template's own border.
	  - The element buttons. Each is two of Blizzard's buttons stacked: a slot button
	    (MultiCastSlotButton1-4), whose GetID() is its totem slot and which is what
	    shows when no totem is set, and on top of it an action button
	    (MultiCastActionButton1-12, four per summon page), the secure button with the
	    spell and the keybind. The backdrop belongs to the slot button, with its border
	    in the element's colour (TB:GetElementColor), so the elements stay apart once
	    Blizzard's coloured art is gone. An element with no totem set shows as an empty
	    dark button with that border. The action buttons get the cropped icon, inside
	    that border, and everything else. All 12 are skinned up front, since changing
	    the summon page swaps which four show, in combat too.
	  - The flyout that opens above a button to choose its totem (or the summon
	    button's page): a SaftUI panel behind its column of choices, and each choice
	    skinned like a button. The first choice of an element's flyout ("none", it
	    clears the slot) is an empty button in the element's colour. Blizzard makes the
	    choices (MultiCastFlyoutButton<n>) the first time a flyout needs them, 24px for
	    its 30px buttons. They're sized to the bar's buttons less the panel's padding on
	    each side, so the panel is as wide as the button the flyout opens from.
	  - The flyout's open and close arrows: SaftUI's flat arrow, in the element's colour
	    (the text colour for the summon button's), drawn thicker under the mouse.

	Nothing is written onto Blizzard's frames or tables (.agents/taint.md rule 1), so
	st:SetBackdrop, st:SkinActionButton and st:SkinIcon can't be used here: all three
	store fields on what they're given. SaftUI's pieces (backdrop frames, textures) live
	in the skins table below, keyed by Blizzard's frame, and Blizzard's own regions only
	get widget calls. Blizzard's art is faded out with SetAlpha(0), which holds because
	Blizzard only shows, hides or re-sets the tex coords of those regions. The state
	textures are swapped for SaftUI's instead (SetHighlightTexture and the like), as
	Blizzard's attack flash sets the checked texture's alpha.

	Blizzard redraws parts of the bar, so post-hooks (hooksecurefunc) put the skin back:
	  - MultiCastSlotButton_Update gives a slot button its slot (its ID) each time the
	    bar updates, and the bar re-orders the elements when a slot is learned: the
	    border takes the colour of whichever element the button now holds.
	  - MultiCastFlyoutFrame_LoadSlotSpells and _LoadPageSpells make any new choices and
	    set every shown choice's icon and tex coords, on each opening: the choices are
	    sized, new ones skinned, the icons cropped again, the "none" choice's icon hidden,
	    and the panel anchored to the column again (it's as long as the number of
	    choices). Both set the flyout's height from the shown choices' heights first, so
	    sizing the choices corrects that height (SizeChoices).
	  - MultiCastFlyoutFrame_ToggleFlyout opens the flyout on a button: the "none"
	    choice and the close arrow take that button's element colour.
	  - MultiCastFlyoutFrameOpenButton_Show moves the open arrow to a hovered button: it
	    takes that button's element colour.
	Everything else Blizzard re-sets on its updates (the element rings', empty slot art's
	and flyout art's tex coords, the icons' textures, the keybind's text and anchor) is
	either faded out for good or left as Blizzard has it. None of these hooks makes a
	protected call, so they work in combat: the flyout, its choices and its arrows have
	no secure template, no secure children and no secure frame anchored to them (a
	protected frame's restrictions spread to its parents and to the frames it's
	anchored to, not to its children), and the rest only touches SaftUI's own frames
	and Blizzard's regions. The slot buttons, on the other hand, are protected that
	way: the recall button is anchored to the last shown one and they chain left to
	right, so they're never moved or resized here (totembar.lua lays them out, out of
	combat). The flyout's choices are sized here, in combat too.

	The flyout's layout leaves room for the totem timers: the panel is anchored to the
	flyout's first and last shown choices, not to the flyout's edges, and the arrows'
	art to the top of their button. So when the flyout and the open arrow are made
	taller and the column of choices is moved up, the panel and the arrows follow.
]]

-- SaftUI's pieces of each skinned frame: Blizzard's frame -> { backdrop, hover, pushed,
-- checked, panel, arrow, ..., style }. style(frame, skin, template) re-applies the
-- profile to them. Kept here, so nothing is written onto Blizzard's frames.
local skins = setmetatable({}, { __mode = 'k' })

-- True once TB:SetupSkin has run, with the hooks in place.
local skinned = false

-- Blizzard's art on the buttons, besides their state textures: the action button
-- template's slot art and equipped border, and the totem bar's element rings. Blizzard
-- only shows and hides these, or re-sets their tex coords, so fading them holds.
local BUTTON_ART = { 'SlotBackground', 'SlotArt', 'Border', 'overlayTex' }

-- The action button template's regions over the icon, put over the cropped icon
-- (Blizzard sizes them for its own art).
local OVER_ICON = {
	'Flash', 'NewActionTexture', 'SpellHighlightTexture',
	'cooldown', 'chargeCooldown', 'lossOfControlCooldown',
	'AutoCastOverlay',
}

-- The button texts, in the profile's button font. Blizzard keeps placing the keybind
-- and setting its text and colour.
local TEXTS = { 'HotKey', 'Count', 'Name' }

-- The gap between the flyout's panel and its column of choices. Small enough that, with
-- a thick template, the panel's border sits just above the element button's border
-- below it rather than over it, and the panel is as wide as the element button.
local PANEL_PADDING = 3

-- The size st:CreateArrowButton draws SaftUI's arrows at.
local ARROW_SIZE = 16

-- From this button size up, cooldown numbers are in the larger pixel font, as on SaftUI's
-- action bars (SaftUI-ActionBars/skin.lua's LARGE_COUNTDOWN_SIZE).
local LARGE_COUNTDOWN_SIZE = 36

------------------------------------
--- Element colours -----------------
------------------------------------

-- Blizzard's totem slot globals (Blizzard_FrameXMLBase's Constants.lua) -> the element's
-- key in the profile's colors. Read the first time a colour is asked for, as retail has
-- no totem bar and nothing here runs there.
local ELEMENT_GLOBALS = {
	EARTH_TOTEM_SLOT = 'earth',
	FIRE_TOTEM_SLOT = 'fire',
	WATER_TOTEM_SLOT = 'water',
	AIR_TOTEM_SLOT = 'air',
}
local elementKeys

-- The colour of the element in a totem slot (a slot button's GetID()), from the profile:
-- r, g, b, or nil for a slot that isn't one of the four. A hidden slot button has slot 0.
function TB:GetElementColor(slot)
	if not elementKeys then
		elementKeys = {}
		for global, key in pairs(ELEMENT_GLOBALS) do
			local index = _G[global]
			if index then elementKeys[index] = key end
		end
	end
	local key = slot and elementKeys[slot]
	local color = key and self.config.colors and self.config.colors[key]
	if not color then return end
	return color[1], color[2], color[3]
end

-- The totem slot a flyout or open arrow is for, from the button it's on, worked out the
-- way Blizzard does (_ComputeMultiCastSlot). nil for the summon button's page flyout.
local function ButtonSlot(kind, parent)
	if kind ~= 'slot' or not parent then return end
	return math.fmod(parent:GetID() - 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4) + 1
end

------------------------------------
--- Helpers -------------------------
------------------------------------

local function Fade(region)
	if region then region:SetAlpha(0) end
end

-- Crops an icon square, as st:SkinIcon does on a square button, without storing
-- anything on it.
local function CropIcon(icon)
	local trim = st.config.profile.misc.icon_trim
	icon:SetTexCoord(trim, 1 - trim, trim, 1 - trim)
end

-- The flyout's "none" choice, which clears the slot. Blizzard gives it spellId 0.
local function IsNoneChoice(button)
	local spellId = button.spellId
	return not issecretvalue(spellId) and spellId == 0
end

-- Puts an element colour on the border of a skin's backdrop, or with no colour gives it
-- the template's own border back (only when it had a colour, as that rebuilds the
-- backdrop).
local function SetBorderColor(skin, r, g, b)
	if r then
		skin.backdrop:SetBackdropBorderColor(r, g, b)
		skin.tinted = true
	elseif skin.tinted then
		st:SetTemplate(skin.backdrop, skin.template)
		skin.tinted = false
	end
end

-- A backdrop of SaftUI's behind a button, filling it.
local function CreateBackdrop(button)
	local backdrop = st:CreateFrame('Frame', nil, button)
	backdrop:SetFrameLevel(math.max(0, button:GetFrameLevel() - 1))
	backdrop:SetAllPoints(button)
	return backdrop
end

-- One of SaftUI's flat state textures, made on the button, over its icon.
local function CreateStateTexture(button)
	local texture = button:CreateTexture(nil, 'OVERLAY')
	texture:SetTexture(st.BLANK_TEX)
	texture:SetAllPoints(button.icon)
	return texture
end

-- hooksecurefunc on one of Blizzard's global functions, if this client has it. On TB
-- for totemtimers.lua too.
function TB.PostHook(name, hook)
	if type(_G[name]) == 'function' then
		hooksecurefunc(name, hook)
	end
end
local PostHook = TB.PostHook

------------------------------------
--- Styles --------------------------
------------------------------------

-- Places and colours a skinned button's pieces from the profile. Safe to run again: it
-- makes nothing new.
local function StyleButton(button, skin, template)
	local colors = st.config.profile.colors

	if skin.backdrop then
		st:SetTemplate(skin.backdrop, template)
		skin.template = template
		skin.tinted = false
	end

	local icon = button.icon
	icon:ClearAllPoints()
	st:SetInside(icon, st:ThemeInset(template))
	CropIcon(icon)

	skin.hover:SetVertexColor(colors.button.blue:GetRGB())
	skin.pushed:SetVertexColor(0, 0, 0, 0.1)
	if skin.checked then
		skin.checked:SetVertexColor(1, 1, 1, 0.3)
	end
	if button.Flash then
		local r, g, b = colors.button.red:GetRGB()
		button.Flash:SetColorTexture(r, g, b, 0.4)
	end

	-- SaftUI's pixel fonts are drawn without a shadow.
	local font = st:GetFont(st.config.profile.buttons.font)
	if font then
		for _, key in ipairs(TEXTS) do
			local text = button[key]
			if text then
				text:SetFontObject(font)
				text:SetShadowOffset(0, 0)
			end
		end
	end

	-- Cooldown numbers in the pixel font, larger on large buttons, as on SaftUI's action
	-- bars. A new button size styles the buttons again (TB:ApplyButtonLayout).
	local countdownFont = st:GetFont(TB.config.button_size >= LARGE_COUNTDOWN_SIZE and 'pixel_med' or 'pixel')
	if countdownFont and button.cooldown and button.cooldown.GetCountdownFontString then
		button.cooldown:GetCountdownFontString():SetFontObject(countdownFont)
	end
end

-- A slot button's border in its element's colour, from the slot Blizzard last gave it.
local function ColorSlotButton(button)
	local skin = skins[button]
	if skin then
		SetBorderColor(skin, TB:GetElementColor(button:GetID()))
	end
end

local function StyleSlotButton(button, skin, template)
	st:SetTemplate(skin.backdrop, template)
	skin.template = template
	skin.tinted = false
	ColorSlotButton(button)
end

local function StyleFlyout(flyout, skin, template)
	st:SetTemplate(skin.panel, template)
end

-- An arrow in the colour of the element in slot, or the text colour for none (the
-- summon button's). Remembered, so a profile change can colour it again.
local function ColorArrow(button, slot)
	local skin = skins[button]
	if not skin then return end
	skin.slot = slot
	local r, g, b = TB:GetElementColor(slot)
	if not r then
		r, g, b = st.config.profile.colors.text.normal:GetRGB()
	end
	skin.arrow:SetVertexColor(r, g, b)
	skin.hover:SetVertexColor(r, g, b)
end

-- Puts the arrow's art at the top of its button, centred. Both arrows are centred on the
-- bar's button they open from (the open arrow over it, the close arrow at the top of the
-- flyout above it), so with an odd button size that centre is half a pixel off the grid.
-- SaftUI's art is an even ARROW_SIZE, so it goes half a pixel right there, to keep its
-- edges on whole pixels. Again on a new button size, which styles the skin again.
local function PlaceArrowArt(button, skin)
	local pixel = st:GetPixelSize(button)
	local x = 0
	if pixel and math.floor(TB.config.button_size / pixel + 0.5) % 2 == 1 then
		x = pixel / 2
	end
	for _, region in ipairs({ skin.arrow, skin.hover }) do
		region:ClearAllPoints()
		region:SetPoint('TOP', button, 'TOP', x, 0)
	end
end

local function StyleArrow(button, skin)
	ColorArrow(button, skin.slot)
	PlaceArrowArt(button, skin)
end

------------------------------------
--- Skins ---------------------------
------------------------------------

-- Skins one of Blizzard's buttons with an icon, once: fades Blizzard's art, takes the
-- action button template's round mask off the icon, puts the template's regions over
-- the icon, and gives it SaftUI's hover and pushed textures, a backdrop of its own if
-- withBackdrop, and a checked texture if withChecked. The flyout's choices get none:
-- they're CheckButtons, so a click toggles them checked, but Blizzard gives them no
-- checked look. StyleButton places and colours the pieces.
local function SkinButton(button, withBackdrop, withChecked)
	local skin = { style = StyleButton }
	skins[button] = skin
	local icon = button.icon

	Fade(button:GetNormalTexture())
	Fade(button:GetPushedTexture())
	Fade(button:GetHighlightTexture())
	if button.GetCheckedTexture then
		Fade(button:GetCheckedTexture())
	end
	for _, key in ipairs(BUTTON_ART) do
		Fade(button[key])
	end

	if icon.GetNumMaskTextures then
		for i = icon:GetNumMaskTextures(), 1, -1 do
			icon:RemoveMaskTexture(icon:GetMaskTexture(i))
		end
	end
	for _, key in ipairs(OVER_ICON) do
		local region = button[key]
		if region then
			region:ClearAllPoints()
			region:SetAllPoints(icon)
		end
	end

	if withBackdrop then
		skin.backdrop = CreateBackdrop(button)
	end

	skin.hover = CreateStateTexture(button)
	button:SetHighlightTexture(skin.hover, 'ADD')

	skin.pushed = CreateStateTexture(button)
	button:SetPushedTexture(skin.pushed)

	if withChecked then
		skin.checked = CreateStateTexture(button)
		button:SetCheckedTexture(skin.checked)
		skin.checked:SetBlendMode('ADD')
	end

	return skin
end

-- The slot button under an element's action buttons holds the element's backdrop. The
-- action button on top takes the mouse, so the slot button needs no hover of its own.
local function SkinSlotButton(button)
	local skin = { style = StyleSlotButton }
	skins[button] = skin
	Fade(button.background)
	Fade(button.overlayTex)
	Fade(button:GetHighlightTexture())
	skin.backdrop = CreateBackdrop(button)
end

-- The flyout's own art is faded, and a SaftUI panel goes behind its column of choices,
-- under their backdrops. It's anchored to the choices on each opening.
local function SkinFlyout(flyout)
	local skin = { style = StyleFlyout }
	skins[flyout] = skin
	Fade(flyout.top)
	Fade(flyout.middle)
	skin.panel = st:CreateFrame('Frame', nil, flyout)
	skin.panel:SetFrameLevel(math.max(0, flyout:GetFrameLevel() - 1))
	skin.panel:Hide()
end

-- The open ('up') or close ('down') arrow: SaftUI's arrow at the top of the button, and
-- its thick version under the mouse.
local function SkinArrow(button, direction)
	local skin = { style = StyleArrow }
	skins[button] = skin
	Fade(button:GetNormalTexture())
	Fade(button:GetHighlightTexture())

	skin.arrow = button:CreateTexture(nil, 'ARTWORK')
	skin.hover = button:CreateTexture(nil, 'HIGHLIGHT')
	for region, key in pairs({ [skin.arrow] = direction .. '-arrow', [skin.hover] = direction .. '-arrow-thick' }) do
		st:SetTexture(region, key)
		region:SetSize(ARROW_SIZE, ARROW_SIZE)
	end
	PlaceArrowArt(button, skin)
	button:SetHighlightTexture(skin.hover, 'BLEND')
end

------------------------------------
--- Flyout --------------------------
------------------------------------

-- Sizes the flyout's choices to the bar's buttons less the panel's padding, straight
-- after Blizzard loaded them. Blizzard has just set the flyout's height from the shown
-- choices' heights as they were (24 for one it made just now), so the height is corrected
-- by how much those choices grow, keeping Blizzard's own gaps and padding. That has to
-- happen before MultiCastFlyoutFrame_ToggleFlyout returns, as the timers grow the flyout
-- from its height then (totemtimers.lua). So the choices aren't sized anywhere else: a
-- flyout that's open while the button size changes keeps its old choices until it next
-- opens.
local function SizeChoices()
	local flyout = MultiCastFlyoutFrame
	local buttons = flyout and flyout.buttons
	if not buttons then return end
	local height = flyout:GetHeight()
	if issecretvalue(height) then return end

	local size = TB.config.button_size - 2 * PANEL_PADDING
	local grow = 0
	for _, button in ipairs(buttons) do
		if button:IsShown() then
			grow = grow + size - button:GetHeight()
		end
		button:SetSize(size, size)
	end
	if grow ~= 0 then
		flyout:SetHeight(height + grow)
	end
end

-- After Blizzard loads the flyout's choices (MultiCastFlyoutFrame_LoadSlotSpells or
-- _LoadPageSpells): skins any new ones, crops the icons Blizzard just set (it resets
-- their tex coords), hides the "none" choice's icon, and anchors the panel to the shown
-- choices. The first choice is at the bottom of the column. Changes nothing when the
-- load didn't, so it's safe after a load that found no spells.
local function UpdateFlyoutButtons()
	local flyout = MultiCastFlyoutFrame
	local flyoutSkin = flyout and skins[flyout]
	local buttons = flyout and flyout.buttons
	if not (flyoutSkin and buttons) then return end

	local first, last
	for _, button in ipairs(buttons) do
		if not skins[button] then
			StyleButton(button, SkinButton(button, true, false), st.config.profile.buttons.template)
		end
		if button:IsShown() then
			local none = IsNoneChoice(button)
			button.icon:SetAlpha(none and 0 or 1)
			if not none then CropIcon(button.icon) end
			first = first or button
			last = button
		end
	end

	local panel = flyoutSkin.panel
	panel:ClearAllPoints()
	if first then
		panel:SetPoint('BOTTOMLEFT', first, 'BOTTOMLEFT', -PANEL_PADDING, -PANEL_PADDING)
		panel:SetPoint('TOPRIGHT', last, 'TOPRIGHT', PANEL_PADDING, PANEL_PADDING)
	end
	panel:SetShown(first ~= nil)
end

-- Colours the open flyout for the button it opened on: the "none" choice and the close
-- arrow in that element's colour, every other choice with the template's border. A
-- summon page flyout has no "none" choice. Reads which button the flyout is open on
-- from Blizzard's flyout, which only takes it once the choices loaded.
local function ColorFlyout()
	local flyout = MultiCastFlyoutFrame
	if not (flyout and flyout:IsShown()) then return end
	local slot = ButtonSlot(flyout.type, flyout.parent)
	for _, button in ipairs(flyout.buttons or {}) do
		local skin = skins[button]
		if skin then
			if button:IsShown() and IsNoneChoice(button) then
				SetBorderColor(skin, TB:GetElementColor(slot))
			else
				SetBorderColor(skin)
			end
		end
	end
	ColorArrow(MultiCastFlyoutFrameCloseButton, slot)
end

------------------------------------
--- Setup ---------------------------
------------------------------------

-- Skins the bar's buttons, its flyout and the flyout's arrows, and hooks Blizzard's
-- redraws (see the top of this file). Once, out of combat, as some of these calls on
-- secure buttons may be blocked then: TB:SetupSkinAndTimers runs it, waiting for the end
-- of combat after a /reload in combat.
function TB:SetupSkin()
	if skinned then return end
	skinned = true

	-- The summon and recall buttons also draw Blizzard's ring around the icon
	-- ($parentHighlight, always shown).
	for _, name in ipairs({ 'MultiCastSummonSpellButton', 'MultiCastRecallSpellButton' }) do
		local button = _G[name]
		if button then
			SkinButton(button, true, true)
			Fade(_G[name .. 'Highlight'])
		end
	end

	local perPage = NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4
	for i = 1, perPage do
		local button = _G['MultiCastSlotButton' .. i]
		if button then SkinSlotButton(button) end
	end
	for i = 1, (NUM_MULTI_CAST_PAGES or 3) * perPage do
		local button = _G['MultiCastActionButton' .. i]
		if button then SkinButton(button, false, true) end
	end

	if MultiCastFlyoutFrame then SkinFlyout(MultiCastFlyoutFrame) end
	if MultiCastFlyoutFrameOpenButton then SkinArrow(MultiCastFlyoutFrameOpenButton, 'up') end
	if MultiCastFlyoutFrameCloseButton then SkinArrow(MultiCastFlyoutFrameCloseButton, 'down') end

	local function OnLoadChoices()
		SizeChoices()
		UpdateFlyoutButtons()
	end
	PostHook('MultiCastSlotButton_Update', ColorSlotButton)
	PostHook('MultiCastFlyoutFrame_LoadSlotSpells', OnLoadChoices)
	PostHook('MultiCastFlyoutFrame_LoadPageSpells', OnLoadChoices)
	PostHook('MultiCastFlyoutFrame_ToggleFlyout', ColorFlyout)
	PostHook('MultiCastFlyoutFrameOpenButton_Show', function(button, kind, parent)
		ColorArrow(button, ButtonSlot(kind, parent))
	end)

	-- Choices a flyout already made (e.g. one opened in combat before this ran). They're
	-- sized at the flyout's next opening (SizeChoices).
	UpdateFlyoutButtons()
	self:ApplySkin()
end

-- Re-applies the profile's button template, font and element colours to everything
-- skinned, for a profile change. Waits for the end of combat, with the rest of the
-- totem bar's profile change (TB:Apply).
function TB:ApplySkin()
	if not skinned then return end
	if st:QueueAfterCombat('totemskin_apply', function() self:ApplySkin() end) then return end

	local template = st.config.profile.buttons.template
	for frame, skin in pairs(skins) do
		skin.style(frame, skin, template)
	end
	ColorFlyout()
end
