local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	Keybinds. Each SaftUI button takes the keys of its Blizzard counterpart's
	binding command (AB:GetBindingCommand; init.lua has the table): ACTIONBUTTON1-12
	for bar 1, MULTIACTIONBAR1BUTTON1-12 for bar 2, and so on. The binds stay
	Blizzard's. The user's saved keys, Blizzard's Key Bindings menu and SaftUI's
	hover binding all read and write those commands. SaftUI only lays override
	bindings over them while it's loaded. Override bindings aren't saved, and
	SaftUI never binds a key to anything but a Blizzard command, so disabling
	SaftUI-ActionBars and reloading gives every key back to Blizzard's bars.

	AB:UpdateBindings goes through every bar in AB.bars, the pet bar
	(BONUSACTIONBUTTON1-10) and the stance bar (SHAPESHIFTBUTTON1-10) too:
	  - Each key of a button's command (GetBindingKey, the saved binds) clicks the
	    button: SetOverrideBindingClick with the 'Keybind' mouse button, as
	    Bartender4 binds. LibActionButton's OnClick wrap takes a 'Keybind' click
	    as a key press, not a pickup click, so a bind with the pickup modifier
	    (Shift by default) still casts on key down. A flyout action opens
	    LibActionButton's flyout from the SaftUI button. The pet and stance
	    buttons (buttons.lua) do what a left click does.
	  - The keys of a disabled bar, of a bar that isn't available (the stance
	    bar of a class without forms) and of the buttons a bar doesn't show click
	    SaftUI_ActionBarNoop, a button that does nothing. Released instead, they'd
	    go back to Blizzard's commands, which click Blizzard's hidden buttons.
	    The pet bar's keys stay on its buttons without a pet, as a pet can come
	    in combat, when binds can't change; its buttons do nothing then.
	  - In a pet battle, bar 1's keys are released. Blizzard's ACTIONBUTTON
	    commands drive the pet battle's abilities (ActionButtonDown ->
	    CheckPetActionButtonEvent -> PetBattleFrame_ButtonDown), and bar 1 hides.
	    They come back when it ends. PET_BATTLE_OPENING_START and PET_BATTLE_CLOSE
	    are the events Blizzard's ActionBarController follows.
	It clears SaftUI's overrides (ClearOverrideBindings on one SaftUI frame) and
	sets them again, only when the result differs from what's applied, so its
	own changes can't loop back through UPDATE_BINDINGS.

	It runs:
	  - when the bars are built
	  - on UPDATE_BINDINGS, when any bind changes (Blizzard's menu, hover binding,
	    a binding set loaded)
	  - from AB:UpdateBar, when a bar is turned on or off, a profile switches or
	    the class's forms change (stancebar.lua)
	  - on the pet battle events
	Binding calls are blocked in combat, so in combat it waits for the end of
	combat. Until then a newly bound key does what it does in Blizzard's UI.

	Hotkey text: each button's LibActionButton keyBoundTarget is its command
	(skin.lua). LibActionButton shows that command's key and refreshes it on
	UPDATE_BINDINGS, and skin.lua shortens it.

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
]]

-- Bars whose keys go back to Blizzard's commands in a pet battle.
local PET_BATTLE_BARS = { bar1 = true }

-- The frame that owns SaftUI's override bindings.
local owner = CreateFrame('Frame')

-- The click target of keys that should do nothing. It has no scripts.
local NOOP = 'SaftUI_ActionBarNoop'
CreateFrame('Button', NOOP, UIParent):Hide()

local applied     -- the override bindings set now, as one string
local inPetBattle -- nil until the first update reads it

local function SortedBarIds(bars)
	local ids = {}
	for id in pairs(bars) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

-- Every override binding SaftUI should have now, as a list of { key, button
-- name }, and the same as one string to compare.
local function WantedBindings(self)
	local bindings, parts = {}, {}
	for _, id in ipairs(SortedBarIds(self.bars)) do
		if not (inPetBattle and PET_BATTLE_BARS[id]) then
			local bar = self.bars[id]
			local config = self.config[id]
			local numShown = (config and config.enable and self:IsBarAvailable(id)) and self:GetNumButtons(id) or 0
			for i, button in ipairs(bar.buttons) do
				local command = self:GetBindingCommand(id, i)
				local target = i <= numShown and button:GetName() or NOOP
				if command then
					for _, key in ipairs({ GetBindingKey(command) }) do
						if key ~= '' then
							bindings[#bindings + 1] = { key, target }
							parts[#parts + 1] = key .. '=' .. target
						end
					end
				end
			end
		end
	end
	return bindings, table.concat(parts, '\n')
end

-- Points every key of the bars' Blizzard commands at SaftUI's buttons (see the
-- top of this file). In combat this waits for the end of combat.
function AB:UpdateBindings()
	if not self.built then return end
	if st:QueueAfterCombat('actionbars_bindings', function() self:UpdateBindings() end) then return end

	if inPetBattle == nil then
		inPetBattle = C_PetBattles.IsInBattle() and true or false
	end

	local bindings, signature = WantedBindings(self)
	if signature == applied then return end

	ClearOverrideBindings(owner)
	for _, binding in ipairs(bindings) do
		local key, target = binding[1], binding[2]
		if target == NOOP then
			SetOverrideBindingClick(owner, false, key, NOOP)
		else
			SetOverrideBindingClick(owner, false, key, target, 'Keybind')
		end
	end
	applied = signature
end

function AB:PET_BATTLE_OPENING_START()
	inPetBattle = true
	self:UpdateBindings()
end

-- The battle is over. Kept from the events rather than read from
-- C_PetBattles.IsInBattle(), which may not have caught up when this fires.
function AB:PET_BATTLE_CLOSE()
	inPetBattle = false
	self:UpdateBindings()
end

------------------------------------
--- Hover binding -------------------
------------------------------------

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
	GameTooltip:AddLine('Press a key to bind it. Right-click clears.', 0.7, 0.7, 0.7)
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
	ShowTooltip()
end

local function CreateBinder()
	binder = CreateFrame('Frame', nil, UIParent)
	binder:SetFrameStrata('DIALOG')
	binder:EnableMouse(true)
	binder:EnableMouseWheel(true)
	binder:Hide()

	binder.highlight = binder:CreateTexture(nil, 'OVERLAY')
	binder.highlight:SetTexture(st.BLANK_TEX)
	binder.highlight:SetAllPoints()

	-- The button's OnLeave (LibActionButton's) hides the tooltip once the binder
	-- takes the mouse, so the binder shows it again.
	binder:SetScript('OnEnter', ShowTooltip)
	binder:SetScript('OnLeave', function(self)
		self.button = nil
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

	mode.done = st:CreateButton(nil, mode, 'Done')
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
	local r, g, b = st.config.profile.colors.button.blue:GetRGB()
	binder.highlight:SetVertexColor(r, g, b, 0.4)

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

st.Config:AddCommand('kb', 'Keybind mode', function() AB:ToggleKeybindMode() end)

------------------------------------
--- Setup ---------------------------
------------------------------------

-- Once, when the bars are built (AB:Build).
function AB:SetupBindings()
	self:RegisterEvent('UPDATE_BINDINGS', 'UpdateBindings')
	self:RegisterEvent('PET_BATTLE_OPENING_START')
	self:RegisterEvent('PET_BATTLE_CLOSE')

	-- Edit mode's movers cover the bars, so the two modes don't run together.
	st.EditModeFrames:On('Enabled', function() self:StopKeybindMode() end)

	-- Blizzard's Quick Keybind Mode only reaches Blizzard's hidden buttons, so
	-- when it opens, point to SaftUI's. A post-hook that only prints
	-- (.agents/taint.md rule 2). Blizzard_QuickKeybind isn't load on demand,
	-- so its frame exists by now.
	if QuickKeybindFrame then
		QuickKeybindFrame:HookScript('OnShow', function()
			st:Print("SaftUI's action bars bind by hovering in /sui kb.")
		end)
	end

	self:UpdateBindings()
end
