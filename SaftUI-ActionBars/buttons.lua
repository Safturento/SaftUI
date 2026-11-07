local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	SaftUI's own secure buttons, for the bars LibActionButton has no button for:
	the pet bar (petbar.lua) and the stance bar (stancebar.lua). LibActionButton
	168 has no pet type (its PetAction type is commented out), and a stance is a
	shapeshift form slot, not an action slot.

	Each button is a CheckButton made from the templates LibActionButton uses
	(ActionButtonTemplate, SecureActionButtonTemplate), on SaftUI's bar header.
	It has the same regions, and skin.lua styles it the same way. The secure
	template does the clicking, from attributes the bar sets out of combat
	('pet' or 'spell'). Everything here only draws: icon, checked, the usable
	and range tints, cooldown, hotkey and tooltip. Drawing isn't protected, so
	it runs in combat too.

	Clicks are registered both down and up, and the secure template acts on the
	press or the release as Blizzard's "cast on key down" setting says, as
	LibActionButton's buttons do. A key bound by bindings.lua clicks with the
	'Keybind' mouse button: the template looks up 'type-Keybind', then falls back
	to the plain 'type' attribute, so a key does what a left click does.

	The rest of SaftUI-ActionBars calls these on any bar's button:
	  - UpdateConfig(config) from skin.lua's StyleBar, with GetButtonConfig's
	    table. Its text, hideElements, keyBoundTarget and showGrid are applied
	    the way LibActionButton applies them (UpdateTextElement, UpdateHotkeys,
	    UpdateGrid in its source).
	  - HasAction() and config.showGrid, for keybind mode's empty buttons
	    (bindings.lua).
	A button with nothing on it is see-through (alpha 0), as LibActionButton's
	empty buttons are without a grid. The bar sets button.grid while something
	is dragged, to show them.

	Each bar's buttons get its own methods on top (AB:CreateSecureButton):
	Refresh() draws the button from the game, SetTooltip() fills GameTooltip.

	Secret values (.agents/clients.md): Blizzard's pet and stance APIs may give
	back secret values on Midnight. AB.IsSet treats a secret flag as false, and
	SetCooldownTimes passes secret times straight to the cooldown.
]]

-- Every button made here.
local buttons = {}

-- True only for a known true value. A secret one counts as false.
function AB.IsSet(value)
	return not issecretvalue(value) and value and true or false
end

------------------------------------
--- Shared methods -----------------
------------------------------------

local Button = {}

-- LibActionButton's UpdateTextElement: one text's font, place and color.
local function ApplyText(region, text)
	region:SetFont(text.font.font or STANDARD_TEXT_FONT, text.font.size, text.font.flags or '')
	region:SetJustifyH(text.justifyH)
	region:ClearAllPoints()
	region:SetPoint(text.position.anchor, region:GetParent(), text.position.relAnchor or text.position.anchor,
		text.position.offsetX or 0, text.position.offsetY or 0)
	region:SetVertexColor(unpack(text.color))
end

-- The button's settings, from GetButtonConfig (skin.lua). Kept as button.config,
-- as LibActionButton keeps its own.
function Button:UpdateConfig(config)
	self.config = config
	ApplyText(self.HotKey, config.text.hotkey)
	ApplyText(self.Count, config.text.count)
	ApplyText(self.Name, config.text.macro)
	self.Name:SetShown(not config.hideElements.macro)
	self.cooldown:SetHideCountdownNumbers(not GetCVarBool('countdownForCooldowns'))
	self:UpdateHotkey()
	self:Refresh()
end

-- The first key of the button's Blizzard command, as LibActionButton shows it.
-- skin.lua's hook on HotKey:SetText shortens it.
function Button:UpdateHotkey()
	local command = self.config.keyBoundTarget
	local key = command and GetBindingKey(command)
	if not key or key == '' or self.config.hideElements.hotkey then
		self.HotKey:SetText(RANGE_INDICATOR)
		self.HotKey:Hide()
	else
		self.HotKey:SetText(key)
		self.HotKey:Show()
	end
end

function Button:HasAction()
	return self.hasAction or false
end

-- Shown while it has something, or while a grid shows empty buttons.
function Button:UpdateGrid()
	self:SetAlpha((self.hasAction or self.grid or self.config.showGrid) and 1 or 0)
end

-- The icon's tint: red out of range, dimmed while it can't be used, as
-- LibActionButton colors SaftUI's other buttons (outOfRangeColoring 'button').
function Button:SetTint(usable, outOfRange)
	if outOfRange then
		self.icon:SetVertexColor(unpack(self.config.colors.range))
	elseif usable then
		self.icon:SetVertexColor(1, 1, 1)
	else
		self.icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

-- Blizzard's CooldownFrame_Set, which compares the times, so a secret time
-- would error in it. Secret times go to the cooldown as they are.
function Button:SetCooldownTimes(start, duration, enable)
	local cooldown = self.cooldown
	if issecretvalue(start) or issecretvalue(duration) or issecretvalue(enable) then
		cooldown:SetCooldown(start, duration)
	elseif enable and enable ~= 0 and start and duration and start > 0 and duration > 0 then
		cooldown:SetCooldown(start, duration)
	else
		cooldown:Clear()
	end
end

------------------------------------
--- Scripts ------------------------
------------------------------------

-- LibActionButton's tooltip: Blizzard's default anchor with the "Enhanced
-- tooltips" setting, else to the right. UpdateTooltip refreshes it while shown.
local function OnEnter(self)
	if GameTooltip:IsForbidden() then return end
	if GetCVar('UberTooltips') == '1' then
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
	else
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
	end
	if self:SetTooltip() then
		self.UpdateTooltip = OnEnter
	else
		self.UpdateTooltip = nil
	end
end

local function OnLeave(self)
	if not GameTooltip:IsForbidden() and GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end

-- A CheckButton checks or unchecks itself on every click. Put it back to what
-- the game says.
local function PostClick(self)
	self:Refresh()
end

------------------------------------
--- Making them --------------------
------------------------------------

-- Makes button i of bar (a header made by AB:CreateBar), named after the bar,
-- with the bar's methods (Refresh, SetTooltip and any of its own) on top of the
-- shared ones. Out of combat only. Fields go onto the button, which is
-- SaftUI's (.agents/taint.md rule 1).
function AB:CreateSecureButton(bar, i, methods)
	local button = CreateFrame('CheckButton', bar:GetName() .. 'Button' .. i, bar,
		'ActionButtonTemplate, SecureActionButtonTemplate')
	-- Over the template's mixin: its HasAction is always false.
	for key, fn in pairs(Button) do
		button[key] = fn
	end
	for key, fn in pairs(methods) do
		button[key] = fn
	end
	button.index = i

	button:RegisterForClicks('AnyDown', 'AnyUp')
	button:SetScript('OnEnter', OnEnter)
	button:SetScript('OnLeave', OnLeave)
	button:SetScript('PostClick', PostClick)
	-- The template's flyout handler; these buttons have no flyout.
	button:SetScript('OnAttributeChanged', nil)

	-- Square icons, as LibActionButton's hideElements.border gives the others.
	button.icon:RemoveMaskTexture(button.IconMask)

	button:UpdateConfig(self:GetButtonConfig(bar.id, i))
	self:SkinButton(button)
	buttons[button] = true
	return button
end

-- Bindings changed: the hotkey text. The "Show Numbers for Cooldowns" setting
-- changed: the cooldown numbers. LibActionButton follows the same two events.
local events = CreateFrame('Frame')
events:RegisterEvent('UPDATE_BINDINGS')
events:RegisterEvent('CVAR_UPDATE')
events:SetScript('OnEvent', function(_, event, name)
	for button in pairs(buttons) do
		if event == 'UPDATE_BINDINGS' then
			button:UpdateHotkey()
		elseif name == 'countdownForCooldowns' then
			button.cooldown:SetHideCountdownNumbers(not GetCVarBool('countdownForCooldowns'))
		end
	end
end)
