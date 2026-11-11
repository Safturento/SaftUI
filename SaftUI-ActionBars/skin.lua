local st = SaftUI
local AB = st:GetModule('ActionBars')
local LAB = LibStub('LibActionButton-1.0')

--[[
	SaftUI's look for the action buttons. The buttons are SaftUI's own: LibActionButton
	makes them for SaftUI's bars from Blizzard's ActionButtonTemplate, so their
	regions and children belong to SaftUI too (.agents/taint.md rule 1). The pet
	and stance bars' buttons (buttons.lua) are made from the same templates and
	take the same config table (GetButtonConfig), so everything here applies to
	them too.

	  - The button's size is its whole footprint. Its backdrop, drawn with the
	    action bars' Theme and Background as an action button, fills it, and the
	    icon, cooldowns and state textures sit inside the backdrop's border (2px
	    for Thick, 1px for Thin, none for None). Bars then fit on a
	    size + spacing grid, and the hotkey, count and macro text stay on the button.
	  - The icon is cropped square (st:SkinIcon). LibActionButton drops its round
	    mask itself with hideElements.border.
	  - Hover, pushed and checked are flat textures of SaftUI's, in place of the
	    template's atlases. The template's own art is faded out for good:
	    LibActionButton only shows, hides or sizes those regions, never changes
	    their alpha.
	  - The attack flash is a flat red tint over the icon.
	  - An equipped item gets a green border on the backdrop, in place of the
	    template's green glow (hideElements.equipped). It goes back on after a
	    theme recolor or redraw (AB:OnColorsChanged).
	  - A pet action's autocast corners and ants (the template's AutoCastOverlay)
	    sit over the icon.
	  - Cooldown swipes, charges, loss of control and the out-of-range and unusable
	    tints are LibActionButton's own. Cooldown numbers follow Blizzard's "Show
	    Numbers for Cooldowns" setting (the countdownForCooldowns CVar), in SaftUI's
	    pixel font: Pixel Med on buttons of 36px and up, Pixel below that, so the
	    numbers fit on small buttons.
	  - Hotkeys are shortened ("SHIFT-MOUSEWHEELUP" -> "SMU").
	  - Text. The hotkey, stack count and macro name follow the bar's Text
	    settings (font, size, outline, show, and where each is anchored), set
	    through LibActionButton's text config. The hotkey and macro name are one
	    line, as tall as their font and cut to the room the anchor leaves inside
	    the button's border (TextWidth), so they stay on the button at any size.
	    The count is as wide as its number and right-aligned by default, so it
	    grows over the icon, not off the button.

	LibActionButton puts some of this back on every update of a button (it anchors
	the cooldown over the whole button), so its OnButtonUpdate callback re-applies
	those parts.
]]

-- SaftUI's pieces of each skinned button: button -> { hover, pushed, checked,
-- theme, background, equipped }. Kept here so no key on the button can clash
-- with LibActionButton's or the template's.
local skins = {}

-- The template's art (ActionButtonTemplate, the same keys on forever and live).
local TEMPLATE_ART = {
	'NormalTexture', 'PushedTexture', 'HighlightTexture', 'CheckedTexture',
	'SlotBackground', 'SlotArt',
}

-- The template's regions that cover the icon, anchored to it (the template sizes
-- them for a 45px button).
local OVER_ICON = {
	'Flash', 'NewActionTexture', 'SpellHighlightTexture',
	'cooldown', 'chargeCooldown', 'lossOfControlCooldown',
	'AutoCastOverlay',
}

-- Buttons at least this big get the bigger cooldown numbers (Pixel Med, 18px by
-- default). Smaller ones get Pixel (10px), so the numbers fit inside a 28px
-- button.
local LARGE_COUNTDOWN_SIZE = 36

------------------------------------
--- Hotkeys -------------------------
------------------------------------

local MODIFIERS = {
	{ 'SHIFT', 'S' },
	{ 'CTRL', 'C' },
	{ 'ALT', 'A' },
	{ 'META', 'M' },
}

local KEYS = {
	MOUSEWHEELUP = 'MU',
	MOUSEWHEELDOWN = 'MD',
	NUMPADDECIMAL = 'N.',
	NUMPADDIVIDE = 'N/',
	NUMPADMINUS = 'N-',
	NUMPADMULTIPLY = 'N*',
	NUMPADPLUS = 'N+',
	PAGEUP = 'PU',
	PAGEDOWN = 'PD',
	SPACE = 'SpB',
	INSERT = 'Ins',
	HOME = 'Hm',
	END = 'End',
	DELETE = 'Del',
	BACKSPACE = 'BS',
	CAPSLOCK = 'Cap',
	ESCAPE = 'Esc',
	ENTER = 'Ent',
	TAB = 'Tab',
}

-- A binding key in a few characters: the modifiers as single letters, then the
-- key. Mouse buttons become M3-M5 and numpad keys N0-N9. Shortening a short key
-- gives it back unchanged.
local function ShortKey(key)
	local prefix = ''
	local found = true
	while found do
		found = false
		for _, modifier in ipairs(MODIFIERS) do
			local rest = key:match('^' .. modifier[1] .. '%-(.+)$')
			if rest then
				prefix = prefix .. modifier[2]
				key = rest
				found = true
			end
		end
	end
	local short = KEYS[key] or (key:gsub('^BUTTON(%d+)$', 'M%1'):gsub('^NUMPAD(%d)$', 'N%1'))
	return prefix .. short
end

-- A post-hook on the hotkey's SetText. LibActionButton writes the full key name.
local function ShortenHotkey(hotkey, text)
	if issecretvalue(text) or type(text) ~= 'string' then return end
	local short = ShortKey(text)
	if short ~= text then
		hotkey:SetText(short)
	end
end

------------------------------------
--- LibActionButton config ----------
------------------------------------

local function Justify(point)
	if point:find('LEFT') then
		return 'LEFT'
	elseif point:find('RIGHT') then
		return 'RIGHT'
	end
	return 'CENTER'
end

-- SaftUI's outline names, as font flags. 'NONE' is no flags.
local function OutlineFlags(outline)
	if not outline or outline == 'NONE' then
		return ''
	end
	return outline
end

-- A text offset in whole pixels, so the pixel fonts stay sharp. The buttons are
-- at UIParent's scale.
local function Offset(value)
	return st:RoundToPixel(tonumber(value) or 0)
end

-- One of a bar's text settings in LibActionButton's shape.
local function TextConfig(text)
	return {
		font = {
			font = st.LSM:Fetch('font', text.font),
			size = text.size,
			flags = OutlineFlags(text.outline),
		},
		color = { 1, 1, 1 },
		position = {
			anchor = text.point,
			relAnchor = text.rel_point,
			offsetX = Offset(text.x_off),
			offsetY = Offset(text.y_off),
		},
		justifyH = Justify(text.point),
	}
end

-- Where a point of the button sits across it: 0 at the left edge, size at the
-- right.
local function PointX(point, size)
	if point:find('LEFT') then
		return 0
	elseif point:find('RIGHT') then
		return size
	end
	return size / 2
end

-- The widest a one-line text can be and stay inside the button's border, from
-- where it's anchored: a left-aligned text has the room to its right, a
-- right-aligned one the room to its left, a centred one twice the room to the
-- nearer side. A text anchored outside the button gets the button's inside
-- width, as it's been put there on purpose.
local function TextWidth(text, size, inset)
	local inside = size - 2 * inset
	local x = PointX(text.rel_point or text.point, size) + Offset(text.x_off)
	local width
	if text.point:find('LEFT') then
		width = size - inset - x
	elseif text.point:find('RIGHT') then
		width = x - inset
	else
		width = 2 * math.min(x - inset, size - inset - x)
	end
	if width <= 0 then
		return inside
	end
	return math.min(width, inside)
end

-- The LibActionButton config of button i on bar id, from the profile. The pet
-- and stance buttons take it too (buttons.lua), and use its text, hideElements,
-- keyBoundTarget, showGrid, colors and tooltip settings.
--   - keyBoundTarget is the Blizzard binding command whose keys the button takes,
--     so its hotkey text shows those keys.
--   - actionButtonUI registers the button with the client like Blizzard's own
--     action buttons (C_ActionBar.RegisterActionUIButton), as Bartender4 does for
--     its action bars. Every LibActionButton button here is a plain action button.
--   - cooldownCount is left unset: the numbers follow the countdownForCooldowns CVar.
--   - Flyouts open upwards from rows and to the left from columns.
function AB:GetButtonConfig(id, i)
	local config = self.config[id]
	local text = config.text
	return {
		outOfRangeColoring = 'button',
		tooltip = 'enabled',
		showGrid = false,
		colors = {
			range = { 0.8, 0.1, 0.1 },
			mana = { 0.5, 0.5, 1.0 },
		},
		hideElements = {
			macro = not text.macro.show,
			hotkey = not text.hotkey.show,
			equipped = true,
			border = true,
			borderIfEmpty = true,
		},
		keyBoundTarget = self:GetBindingCommand(id, i),
		actionButtonUI = true,
		flyoutDirection = (config.perrow == 1 and config.buttons > 1) and 'LEFT' or 'UP',
		text = {
			hotkey = TextConfig(text.hotkey),
			count = TextConfig(text.count),
			macro = TextConfig(text.macro),
		},
	}
end

------------------------------------
--- Skin ----------------------------
------------------------------------

-- Makes SaftUI's pieces on a new button and fades out the template's art. Once
-- per button; AB:StyleButton colors and places them.
function AB:SkinButton(button)
	if skins[button] then return end
	local skin = {}
	skins[button] = skin

	for _, key in ipairs(TEMPLATE_ART) do
		if button[key] then
			button[key]:SetAlpha(0)
		end
	end

	skin.hover = button:CreateTexture(nil, 'OVERLAY')
	skin.hover:SetTexture(st.BLANK_TEX)
	button:SetHighlightTexture(skin.hover, 'ADD')

	skin.pushed = button:CreateTexture(nil, 'OVERLAY')
	skin.pushed:SetTexture(st.BLANK_TEX)
	button:SetPushedTexture(skin.pushed)

	skin.checked = button:CreateTexture(nil, 'OVERLAY')
	skin.checked:SetTexture(st.BLANK_TEX)
	button:SetCheckedTexture(skin.checked)
	skin.checked:SetBlendMode('ADD')

	hooksecurefunc(button.HotKey, 'SetText', ShortenHotkey)
	ShortenHotkey(button.HotKey, button.HotKey:GetText())
end

-- Blizzard's state art for a button drawn with theme and background (see
-- st.ThemeArt.State), or nil when it isn't drawn in Blizzard's art.
function AB:BlizzardState(theme, background)
	local look = st:ResolveTheme(theme, background, 'action')
	if look and look.name == 'blizzard' then
		return st.ThemeArt.State('action')
	end
end

-- Applies the action bars' Theme and Background and the bar's size to a
-- skinned button. Safe to run again: it makes nothing new.
function AB:StyleButton(button, config, theme, background)
	local skin = skins[button]
	if not skin then return end
	local colors = st.config.profile.colors

	st:SetBackdrop(button, theme, background, 'action')
	if button.backdrop then
		button.backdrop:ClearAllPoints()
		button.backdrop:SetAllPoints(button)
	end
	skin.theme, skin.background = theme, background
	skin.equipped = nil -- the backdrop's border was just reset

	local inset = st:ThemeInset(theme, background, 'action')
	local icon = button.icon
	icon:ClearAllPoints()
	st:SetInside(icon, inset)
	st:SkinIcon(icon)

	for _, key in ipairs(OVER_ICON) do
		local region = button[key]
		if region then
			region:ClearAllPoints()
			region:SetAllPoints(icon)
		end
	end

	-- Hover, pushed, checked and the flash: under Blizzard its own art over the
	-- ring's footprint, the whole button, with no tint; otherwise SaftUI's flat
	-- textures over the icon.
	local state = self:BlizzardState(theme, background)
	if state then
		local ThemeArt = st.ThemeArt
		-- The hover stays in its layer, where the client shows it only under
		-- the mouse (HOVER_LAYER).
		ThemeArt.StyleState(skin.hover, state.hover, button, nil, ThemeArt.HOVER_LAYER)
		ThemeArt.StyleState(skin.pushed, state.pushed, button)
		ThemeArt.StyleState(skin.checked, state.checked, button, state.checkedBlend)
		-- The flash keeps the template's layer, over the state art.
		ThemeArt.StyleState(button.Flash, state.flash, button, nil, false)
	else
		for _, region in ipairs({ skin.hover, skin.pushed, skin.checked }) do
			region:SetTexture(st.BLANK_TEX)
			region:SetTexCoord(0, 1, 0, 1)
			region:SetDrawLayer('OVERLAY', 0)
			region:ClearAllPoints()
			region:SetAllPoints(icon)
		end
		-- Shown only under the mouse in this layer; moved out, all the time.
		skin.hover:SetDrawLayer(st.ThemeArt.HOVER_LAYER, 0)
		skin.hover:SetVertexColor(colors.button.blue:GetRGB())
		skin.pushed:SetVertexColor(0, 0, 0, 0.1)
		skin.checked:SetVertexColor(1, 1, 1, 0.3)
		skin.checked:SetBlendMode('ADD')
		local r, g, b = colors.button.red:GetRGB()
		button.Flash:SetColorTexture(r, g, b, 0.4)
	end

	-- LibActionButton set the fonts, anchors and the hotkey's and macro name's
	-- showing from the bar's text settings (GetButtonConfig). SaftUI's pixel fonts
	-- are drawn without a shadow. The hotkey and macro name are one line, as tall
	-- as their font, and cut to the room inside the border (see the top of this
	-- file). LibActionButton never shows or hides the count, so its setting is
	-- applied here.
	local size = st:RoundToPixel(config.size, button)
	for _, text in ipairs({ button.HotKey, button.Count, button.Name }) do
		text:SetShadowOffset(0, 0)
	end
	for region, text in pairs({ [button.HotKey] = config.text.hotkey, [button.Name] = config.text.macro }) do
		region:SetWordWrap(false)
		region:SetWidth(TextWidth(text, size, inset))
		region:SetHeight(text.size)
	end
	button.Count:SetShown(config.text.count.show)

	local countdownFont = st:GetFont(config.size >= LARGE_COUNTDOWN_SIZE and 'pixel_med' or 'pixel')
	if countdownFont then
		button.cooldown:GetCountdownFontString():SetFontObject(countdownFont)
	end

	self:UpdateEquippedBorder(button)
end

-- Every button of bar id, re-configured and re-styled from the profile. Protected
-- (LibActionButton sets attributes), so out of combat only.
function AB:StyleBar(id)
	local bar = self.bars[id]
	if not bar then return end
	local config = self.config[id]
	local theme, background = self.config.theme, self.config.background
	for i, button in ipairs(bar.buttons) do
		button:UpdateConfig(self:GetButtonConfig(id, i))
		self:StyleButton(button, config, theme, background)
	end
end

-- An equipped item's border.
local function ColorEquipped(backdrop)
	st:SetBorderColor(backdrop, st.config.profile.colors.button.green:GetRGB())
end

-- A green border while the button holds an equipped item, the theme's border
-- otherwise. Only touches the backdrop when that changes. The pet and stance
-- buttons never hold an item, and have no IsEquipped.
function AB:UpdateEquippedBorder(button)
	local skin = skins[button]
	local backdrop = button.backdrop
	if not (skin and backdrop) then return end

	local equipped = button.IsEquipped and button:IsEquipped()
	if issecretvalue(equipped) then equipped = false end
	equipped = equipped and true or false
	if equipped == skin.equipped then return end
	skin.equipped = equipped

	if equipped then
		ColorEquipped(backdrop)
	else
		st:SetBorderColor(backdrop)
	end
end

-- A theme recolor or redraw put the theme's border back on every button
-- (group 'theme'): the equipped ones get their green again.
function AB:OnColorsChanged(group)
	if group ~= 'theme' then return end
	for button, skin in pairs(skins) do
		if skin.equipped and button.backdrop then
			ColorEquipped(button.backdrop)
		end
	end
end

-- LibActionButton's OnButtonUpdate fires at the end of every update of every
-- LibActionButton button, other addons' too. It anchors the cooldown over the
-- whole button each time (hideElements.border), so it's put back over the icon.
-- The cooldown isn't protected, so this is safe in combat, as LibActionButton's
-- own re-anchoring is.
function AB:OnLABButtonUpdate(event, button)
	if not skins[button] then return end
	button.cooldown:ClearAllPoints()
	button.cooldown:SetAllPoints(button.icon)
	self:UpdateEquippedBorder(button)
end

LAB.RegisterCallback(AB, 'OnButtonUpdate', 'OnLABButtonUpdate')
