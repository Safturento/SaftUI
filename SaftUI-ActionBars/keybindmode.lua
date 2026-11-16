local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	Hover binding (/sui kb, or Keybind mode in /sui). Blizzard's Quick Keybind
	Mode can't take SaftUI's buttons. It finds the hovered button through its
	own buttons' OnEnter (QuickKeybindButtonTemplate), which calls
	QuickKeybindFrame:SetSelected(button.commandName, button). Doing that from
	SaftUI would write QuickKeybindFrame.mouseOverButton and KeybindListener's
	state from SaftUI's code (.agents/taint.md rules 1 and 3). So SaftUI has its
	own mode, out of combat only:
	  - Hover a SaftUI button and press a key, a mouse button (middle, 4, 5...)
	    or the mouse wheel, with any modifiers. The key becomes the first key of
	    the button's Blizzard command, as in Blizzard's Quick Keybind Mode: the
	    command's old first key is unbound and its second key stays. Then
	    SaveBindings(GetCurrentBindingSet()), so it shows in Blizzard's menu.
	  - If Blizzard refuses the bind, the old keys go back and SaftUI says so.
	    Blizzard's Quick Keybind Mode reports the same for the mouse wheel.
	  - Right-click clears all of the button's keys.
	  - Escape, Done or entering combat leaves the mode.
	Empty buttons show while it's on, as Blizzard shows its grid. So do bars that
	their Visibility setting keeps hidden out of combat or faded
	(AB:SetForceShown, bars.lua); they go back when the mode ends. The pet bar
	still shows only with a pet out, and the stance bar only for a class with
	forms: without, they'd be rows of empty buttons.
	The hovered-button binder and the mode's panel are made on first use.
	bindings.lua's AB:SetupBindings stops the mode when edit mode turns on.
]]


local mode   -- the mode's panel, made on first use
local binder -- the overlay over the hovered button, made with the panel

-- SaftUI's buttons: button -> its Blizzard command, and the buttons whose
-- OnEnter is hooked already. Tables of SaftUI's own, so nothing new goes onto
-- the buttons.
local buttonCommands = setmetatable({}, { __mode = 'k' })
local hooked = setmetatable({}, { __mode = 'k' })

-- Empty buttons the mode made visible.
local shownEmpty = {}

local function IsActive()
	return mode and mode:IsShown()
end

local function KeysText(command)
	local keys = {}
	for _, key in ipairs({ GetBindingKey(command) }) do
		keys[#keys + 1] = GetBindingText(key)
	end
	if #keys == 0 then
		return NOT_BOUND or 'Not bound'
	end
	return table.concat(keys, ', ')
end

local function ShowTooltip()
	local button = binder.button
	if not button or GameTooltip:IsForbidden() then return end
	local command = buttonCommands[button]
	GameTooltip:SetOwner(binder, 'ANCHOR_TOP')
	GameTooltip:AddLine(GetBindingName(command), 1, 1, 1)
	GameTooltip:AddLine(KeysText(command), 1, 0.82, 0)
	GameTooltip:AddLine('Press a key to bind it. Right-click clears.', st:Color('text', 'muted'):GetRGB())
	GameTooltip:Show()
end

local function HideTooltip()
	if not GameTooltip:IsForbidden() and GameTooltip:IsOwned(binder) then
		GameTooltip:Hide()
	end
end

local function SaveKeys()
	SaveBindings(GetCurrentBindingSet())
end

-- Makes key the first key of command, the way Blizzard's Quick Keybind Mode
-- does (KeybindListener:ProcessInput): the old first key is unbound, the second
-- key stays, and the key leaves whatever it was bound to before.
local function Bind(command, key)
	if InCombatLockdown() then return end
	local key1, key2 = GetBindingKey(command)
	if key == key1 then return end
	local previous = GetBindingAction(key)
	local name = GetBindingName(command)

	if key1 then SetBinding(key1, nil) end
	if key2 then SetBinding(key2, nil) end
	if SetBinding(key, command) then
		if key2 and key2 ~= key then
			SetBinding(key2, command)
		end
		SaveKeys()
		if previous and previous ~= '' and previous ~= command then
			st:Print(('%s bound to %s (was %s).'):format(GetBindingText(key), name, GetBindingName(previous)))
		else
			st:Print(('%s bound to %s.'):format(GetBindingText(key), name))
		end
	else
		if key1 then SetBinding(key1, command) end
		if key2 then SetBinding(key2, command) end
		st:Print(("Can't bind %s to %s."):format(GetBindingText(key), name))
	end
end

local function ClearKeys(command)
	if InCombatLockdown() then return end
	local keys = { GetBindingKey(command) }
	if #keys == 0 then return end
	for _, key in ipairs(keys) do
		SetBinding(key, nil)
	end
	SaveKeys()
	st:Print(('%s unbound.'):format(GetBindingName(command)))
end

-- A key, mouse button or wheel direction as a binding key with the modifiers
-- held ('SHIFT-1', 'CTRL-BUTTON4'), or nil for a modifier on its own and for
-- left and right click. Blizzard's KeybindListener uses the same helpers
-- (Blizzard_SharedXML/BindingUtil.lua, which only read).
local function BindingKey(input)
	local key = GetConvertedKeyOrButton(input)
	if IsKeyPressIgnoredForBinding(key) then return end
	return CreateKeyChordStringUsingMetaKeyState(key)
end

local function OnInput(input)
	local button = binder.button
	local key = button and BindingKey(input)
	if not key then return end
	Bind(buttonCommands[button], key)
	ShowTooltip()
end

local function Propagate(frame, propagate)
	if not InCombatLockdown() then
		frame:SetPropagateKeyboardInput(propagate)
	end
end

-- The panel takes every key while the mode is on, as Blizzard's Quick Keybind
-- frame does. Typing in an edit box and screenshots pass through.
local function OnKeyDown(self, key)
	if GetCurrentKeyBoardFocus() or GetBindingFromClick(key) == 'SCREENSHOT' then
		Propagate(self, true)
		return
	end
	Propagate(self, false)
	if key == 'ESCAPE' then
		AB:StopKeybindMode()
	else
		OnInput(key)
	end
end

-- A post-hook on SaftUI's own buttons. The binder goes over the hovered button
-- and takes the mouse, so a click binds or clears instead of casting.
local function OnButtonEnter(button)
	if not IsActive() or InCombatLockdown() or not buttonCommands[button] then return end
	binder.button = button
	binder:ClearAllPoints()
	binder:SetAllPoints(button)
	binder:Show()
	-- It marks the button being bound: selected (the accent edge and the fade).
	st:SetState(binder, 'selected', true)
	ShowTooltip()
end

local function CreateBinder()
	binder = st:CreateFrame('Frame', nil, UIParent)
	binder:SetFrameStrata('DIALOG')
	binder:EnableMouse(true)
	binder:EnableMouseWheel(true)
	binder:Hide()

	-- The binder is a state frame of SaftUI's, selected while it marks a button:
	-- a box with the theme's edge, which the helper colors with the Accent, and
	-- the Fill over the icon. It wears the Thin look in every theme, its body
	-- clear (it marks a button, it doesn't cover it), and its look is its own
	-- under Blizzard too. It has no mouse states (wire = false).
	st:SetTemplate(binder, 'thin', 'transparent', 'action')
	binder:SetBackdropColor(0, 0, 0, 0)
	st:AddStates(binder, 'box', { edge = 'theme', wire = false, blizzard = function() return false end })

	-- The button's OnLeave (LibActionButton's) hides the tooltip once the binder
	-- takes the mouse, so the binder shows it again.
	binder:SetScript('OnEnter', ShowTooltip)
	binder:SetScript('OnLeave', function(self)
		self.button = nil
		st:SetState(self, 'selected', false)
		self:ClearAllPoints()
		self:Hide()
		HideTooltip()
	end)
	binder:SetScript('OnMouseDown', function(self, mouseButton)
		if mouseButton == 'RightButton' then
			if self.button then
				ClearKeys(buttonCommands[self.button])
				ShowTooltip()
			end
		else
			OnInput(mouseButton)
		end
	end)
	binder:SetScript('OnMouseWheel', function(self, delta)
		OnInput(delta > 0 and 'MOUSEWHEELUP' or 'MOUSEWHEELDOWN')
	end)
end

local function CreateMode()
	mode = st:CreateFrame('Frame', 'SaftUI_KeybindMode', UIParent)
	mode:SetFrameStrata('DIALOG')
	mode:SetSize(360, 76)
	mode:SetPoint('TOP', UIParent, 'TOP', 0, -120)
	mode:EnableKeyboard(true)
	mode:Hide()

	mode.title = st:CreateFontString(mode, 'pixel', 'Keybind mode')
	mode.title:SetPoint('TOP', mode, 'TOP', 0, -10)

	mode.text = st:CreateFontString(mode, 'pixel',
		'Hover an action button and press a key to bind it.\nRight-click a button to clear its keys. Escape leaves.')
	mode.text:SetPoint('TOP', mode.title, 'BOTTOM', 0, -6)
	mode.text:SetWidth(340)

	mode.done = st:CreateButton(nil, mode, 'Done', 'theme', 'solid')
	mode.done:SetSize(60, 16)
	mode.done:SetPoint('BOTTOM', mode, 'BOTTOM', 0, 8)
	mode.done:SetScript('OnClick', function() AB:StopKeybindMode() end)

	mode:SetScript('OnKeyDown', OnKeyDown)
	-- PLAYER_REGEN_DISABLED, registered while the mode is on. It fires just
	-- before combat lockdown starts.
	mode:SetScript('OnEvent', function()
		AB:StopKeybindMode('Keybind mode closed: entering combat.')
	end)

	CreateBinder()
end

function AB:StartKeybindMode()
	if IsActive() or not self.built then return end
	if InCombatLockdown() then
		st:Print("Can't bind keys in combat.")
		return
	end
	if not mode then CreateMode() end

	-- Edit mode's movers would cover the bars. /sui closes as Blizzard's
	-- settings do for its mode, a frame later, as this can run from its button.
	st.EditModeFrames:Deactivate()
	if st.Config:GetWindow() then
		C_Timer.After(0, function()
			st.Config:Close()
		end)
	end

	local panels = st.config.profile.panels
	st:SetTemplate(mode, panels.theme, panels.background, 'panel')
	-- a theme recolor while the mode was off gave the binder its body back
	binder:SetBackdropColor(0, 0, 0, 0)
	-- Bars shown only in combat, or faded, show so they can be hovered. Out of
	-- combat, checked above.
	self:SetForceShown(true)

	for id, bar in pairs(self.bars) do
		for i, button in ipairs(bar.buttons) do
			buttonCommands[button] = self:GetBindingCommand(id, i)
			if not hooked[button] then
				hooked[button] = true
				button:HookScript('OnEnter', OnButtonEnter)
			end
			if button:IsShown() and not button:HasAction() then
				button:SetAlpha(1)
				shownEmpty[button] = true
			end
		end
	end

	mode:RegisterEvent('PLAYER_REGEN_DISABLED')
	mode:Show()
	st:Print('Keybind mode on: hover a button and press a key. Right-click clears, Escape leaves.')
end

-- message is what to print, 'Keybind mode off.' by default.
function AB:StopKeybindMode(message)
	if not IsActive() then return end
	mode:UnregisterEvent('PLAYER_REGEN_DISABLED')
	mode:Hide()
	binder.button = nil
	st:SetState(binder, 'selected', false)
	binder:ClearAllPoints()
	binder:Hide()
	HideTooltip()

	-- Empty buttons go back to hidden, as LibActionButton keeps them without a grid.
	for button in pairs(shownEmpty) do
		if not button:HasAction() and not button.config.showGrid then
			button:SetAlpha(0)
		end
	end
	wipe(shownEmpty)

	-- Bars go back to their Visibility setting. On PLAYER_REGEN_DISABLED this
	-- still runs before combat lockdown starts; if lockdown is on, the state
	-- drivers wait for the end of combat (AB:UpdateVisibility).
	self:SetForceShown(false)
	st:Print(message or 'Keybind mode off.')
end

function AB:ToggleKeybindMode()
	if IsActive() then
		self:StopKeybindMode()
	else
		self:StartKeybindMode()
	end
end

st.Config:AddCommand('kb', 'Keybind mode', function() AB:ToggleKeybindMode() end, st.icons.keyboard)
