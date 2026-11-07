local st = SaftUI
local AB = st:GetModule('ActionBars')
local LAB = LibStub('LibActionButton-1.0')

--[[
	SaftUI's look for the action buttons. The buttons are SaftUI's own: LibActionButton
	makes them for SaftUI's bars from Blizzard's ActionButtonTemplate, so their
	regions and children belong to SaftUI too (.agents/taint.md rule 1).

	  - The button's size is its whole footprint. The template's backdrop fills it,
	    and the icon, cooldowns and state textures sit inside the backdrop's border
	    (2px for thick templates, 1px for thin ones). Bars then fit on a
	    size + spacing grid, and the hotkey, count and macro text stay on the button.
	  - The icon is cropped square (st:SkinIcon). LibActionButton drops its round
	    mask itself with hideElements.border.
	  - Hover, pushed and checked are flat textures of SaftUI's, in place of the
	    template's atlases. The template's own art is faded out for good:
	    LibActionButton only shows, hides or sizes those regions, never changes
	    their alpha.
	  - The attack flash is a flat red tint over the icon.
	  - An equipped item gets a green border on the backdrop, in place of the
	    template's green glow (hideElements.equipped).
	  - Cooldown swipes, charges, loss of control and the out-of-range and unusable
	    tints are LibActionButton's own. Cooldown numbers follow Blizzard's "Show
	    Numbers for Cooldowns" setting (the countdownForCooldowns CVar), in SaftUI's
	    pixel font.
	  - Hotkeys are shortened ("SHIFT-MOUSEWHEELUP" -> "SMU").

	LibActionButton puts some of this back on every update of a button (it anchors
	the cooldown over the whole button), so its OnButtonUpdate callback re-applies
	those parts.
]]

-- SaftUI's pieces of each skinned button: button -> { hover, pushed, checked,
-- template, equipped }. Kept here so no key on the button can clash with
-- LibActionButton's or the template's.
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
}

-- The border a template draws inside the button.
local function TemplateInset(template)
	local config = template and st.config.profile.templates[template]
	if not config then return 0 end
	return config.thick and 2 or 1
end

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

-- One of a bar's text settings in LibActionButton's shape.
local function TextConfig(text)
	return {
		font = {
			font = st.LSM:Fetch('font', text.font),
			size = text.size,
			flags = text.outline,
		},
		color = { 1, 1, 1 },
		position = {
			anchor = text.point,
			relAnchor = text.rel_point,
			offsetX = text.x_off,
			offsetY = text.y_off,
		},
		justifyH = Justify(text.point),
	}
end

-- The LibActionButton config of button i on bar id, from the profile.
--   - keyBoundTarget is the Blizzard binding command whose keys the button takes,
--     so its hotkey text shows those keys.
--   - actionButtonUI registers the button with the client like Blizzard's own
--     action buttons (C_ActionBar.RegisterActionUIButton), as Bartender4 does for
--     its action bars. Every button here is a plain action button.
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

-- Applies the profile's template and the bar's size to a skinned button. Safe to
-- run again: it makes nothing new.
function AB:StyleButton(button, config, template)
	local skin = skins[button]
	if not skin then return end
	local colors = st.config.profile.colors

	st:SetBackdrop(button, template)
	if button.backdrop then
		button.backdrop:ClearAllPoints()
		button.backdrop:SetAllPoints(button)
	end
	skin.template = template
	skin.equipped = nil -- the backdrop's border was just reset

	local inset = TemplateInset(template)
	local icon = button.icon
	icon:ClearAllPoints()
	st:SetInside(icon, inset)
	st:SkinIcon(icon)

	for _, region in ipairs({ skin.hover, skin.pushed, skin.checked }) do
		region:ClearAllPoints()
		region:SetAllPoints(icon)
	end
	for _, key in ipairs(OVER_ICON) do
		local region = button[key]
		if region then
			region:ClearAllPoints()
			region:SetAllPoints(icon)
		end
	end

	skin.hover:SetVertexColor(colors.button.blue:GetRGB())
	skin.pushed:SetVertexColor(0, 0, 0, 0.1)
	skin.checked:SetVertexColor(1, 1, 1, 0.3)
	local r, g, b = colors.button.red:GetRGB()
	button.Flash:SetColorTexture(r, g, b, 0.4)

	-- LibActionButton set the fonts from the bar's text settings (GetButtonConfig).
	-- SaftUI's pixel fonts are drawn without a shadow, and the hotkey and macro name
	-- are cut to the inside of the border.
	local width = st:RoundToPixel(config.size, button) - 2 * inset
	for _, text in ipairs({ button.HotKey, button.Count, button.Name }) do
		text:SetShadowOffset(0, 0)
	end
	button.HotKey:SetWidth(width)
	button.Name:SetWidth(width)
	button.Count:SetShown(config.text.count.show)

	local countdownFont = st:GetFont('pixel_med')
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
	local template = self.config.template
	for i, button in ipairs(bar.buttons) do
		button:UpdateConfig(self:GetButtonConfig(id, i))
		self:StyleButton(button, config, template)
	end
end

-- A green border while the button holds an equipped item, the template's border
-- otherwise. Only touches the backdrop when that changes.
function AB:UpdateEquippedBorder(button)
	local skin = skins[button]
	local backdrop = button.backdrop
	if not (skin and backdrop) then return end

	local equipped = button:IsEquipped()
	if issecretvalue(equipped) then equipped = false end
	equipped = equipped and true or false
	if equipped == skin.equipped then return end
	skin.equipped = equipped

	if equipped then
		backdrop:SetBackdropBorderColor(st.config.profile.colors.button.green:GetRGB())
	else
		st:SetTemplate(backdrop, skin.template)
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
