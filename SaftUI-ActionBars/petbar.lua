local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The pet bar, in place of Blizzard's PetActionBar: SaftUI_PetBar, holding ten
	of SaftUI's secure buttons (buttons.lua), SaftUI_PetBarButton1..10, one per
	pet action slot. LibActionButton 168 has no pet button type, so they work
	the way Blizzard's pet buttons do (Blizzard_ActionBar PetActionBar.lua and
	.xml, forever and live; the two differ only in how Update is split up):
	  - Left click, and a key bound to BONUSACTIONBUTTON<n> (bindings.lua): the
	    secure template's 'pet' type, CastPetAction(slot), which Blizzard's
	    button and binding call too.
	  - Right click toggles the action's autocast, as Blizzard's does. Blizzard
	    calls TogglePetAutocast from its secure click handler. SaftUI's buttons
	    use the secure /petautocasttoggle <name> macro command instead (type2
	    'macro'), as Ion's and GW2_UI's do, so it works whether addon code may
	    call TogglePetAutocast or not. The names are set out of combat for the
	    actions that can autocast, and right click does nothing on the others,
	    as on Blizzard's bar. A pet summoned or swapped in combat gets its names
	    when combat ends; until then right click toggles by the old pet's names.
	  - A click does nothing without a pet (Blizzard's binding checks
	    PetHasActionBar first, so a key never calls CastPetAction for nothing),
	    or with the pickup modifier held (Shift by default), so that can start a
	    drag. A secure snippet the header runs before each click checks both.
	  - Drag pet actions off, on and between buttons out of combat
	    (PickupPetAction), as on Blizzard's bar. As on SaftUI's other bars,
	    Blizzard's Lock Action Bars setting isn't followed.
	  - Drawn from GetPetActionInfo on Blizzard's pet bar events: icon (a token
	    names a global texture, as for Attack and Follow), checked while active,
	    the attack action flashing while the pet attacks, the autocast corners
	    (can autocast) and ants (autocasting) of the template's AutoCastOverlay,
	    the cooldown, dimmed while unusable (GetPetActionSlotUsable) and red out
	    of range, checked every 0.2s while shown as Blizzard does. All of it
	    only draws, so it runs in combat too.
	  - Empty slots are see-through, and show while a pet action is dragged
	    (PET_BAR_SHOWGRID / PET_BAR_HIDEGRID).

	Shown only with a pet out, '[pet,nooverridebar,novehicleui,nopossessbar]
	show; hide', written as hide conditions (AB.HIDE_CONDITIONS, bars.lua) so
	the Visibility setting still applies, and also hidden in pet battles. While
	possessing (mind control), the possessed unit's actions are on bar 1, so the
	pet bar hides, as Blizzard's does. Keybind mode doesn't show it without a
	pet: it would be ten empty buttons.

	Blizzard's own pet bar is off screen (hideblizzard.lua): blocked, or
	concealed after a /reload with a pet out, when it's on screen at load. The
	conceal turns off the mouse on PetActionBar.actionButtons (its ten
	PetActionButtons, ActionBarMixin:ActionBar_OnLoad) and its events are off,
	so it stays invisible and can't be clicked, and SaftUI's override bindings
	take its keys.
]]

local NUM_SLOTS = NUM_PET_ACTION_SLOTS or 10

-- How long the range tint waits between checks, as Blizzard's pet bar does.
local RANGE_TIME = 0.2

-- Restricted code the header runs before each click on a button. Returning
-- false stops the click. UnitExists and IsModifiedClick are in the restricted
-- environment (RestrictedEnvironment.lua, the same on forever and live).
local PRE_CLICK = [[
	if not UnitExists('pet') then
		return false
	end
	if button ~= 'Keybind' and IsModifiedClick('PICKUPACTION') then
		return false
	end
]]

AB.HIDE_CONDITIONS.pet = '[petbattle][nopet][vehicleui][overridebar][possessbar]'

local IsSet = AB.IsSet

local bar -- AB.bars.pet, once made

------------------------------------
--- Buttons ------------------------
------------------------------------

local PetButton = {}

function PetButton:Refresh()
	local slot = self.index
	local _, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(slot)
	if IsSet(isToken) and not issecretvalue(texture) then
		texture = _G[texture]
	end
	self.hasAction = issecretvalue(texture) or texture ~= nil
	self.icon:SetTexture(texture)
	self.icon:SetShown(self.hasAction)

	self:SetChecked(IsSet(isActive))
	self.flashing = IsSet(isActive) and IsSet(IsPetAttackAction(slot))
	self.AutoCastOverlay:SetShown(IsSet(autoCastAllowed))
	self.AutoCastOverlay:ShowAutoCastEnabled(IsSet(autoCastEnabled))

	self:RefreshTint()
	self:SetCooldownTimes(GetPetActionCooldown(slot))
	self:UpdateGrid()
end

-- Dimmed while unusable, red out of range.
function PetButton:RefreshTint()
	if not self.hasAction then return end
	local slot = self.index
	local _, _, _, _, _, _, _, checksRange, inRange = GetPetActionInfo(slot)
	local outOfRange = IsSet(checksRange) and not issecretvalue(inRange) and not inRange
	self:SetTint(IsSet(GetPetActionSlotUsable(slot)), outOfRange)
end

-- The attack flash, as LibActionButton's: the red Flash tint (skin.lua) on and
-- off every ATTACK_BUTTON_FLASH_TIME while the pet attacks.
function PetButton:UpdateFlash(elapsed)
	if not self.flashing then
		self.Flash:Hide()
		return
	end
	self.flashTime = (self.flashTime or 0) - elapsed
	if self.flashTime <= 0 then
		self.flashTime = ATTACK_BUTTON_FLASH_TIME or 0.4
		self.Flash:SetShown(not self.Flash:IsShown())
	end
end

function PetButton:SetTooltip()
	return GameTooltip:SetPetAction(self.index)
end

local function RefreshAll()
	for _, button in ipairs(bar.buttons) do
		button:Refresh()
	end
end

-- Out of combat (InCombatLockdown is checked): PickupPetAction lifts the slot's
-- action, or swaps it with the one on the cursor.
local function OnDragStart(self)
	if InCombatLockdown() then return end
	self:SetChecked(false)
	PickupPetAction(self.index)
	RefreshAll()
end

local function OnReceiveDrag(self)
	if InCombatLockdown() or GetCursorInfo() ~= 'petaction' then return end
	self:SetChecked(false)
	PickupPetAction(self.index)
	RefreshAll()
end

-- The right click of each button: /petautocasttoggle with the action's name if
-- it can autocast, nothing otherwise. Attributes are protected, so out of
-- combat only: from AB:UpdateBar, and from the events below after combat.
local function UpdateActions()
	for _, button in ipairs(bar.buttons) do
		local name, _, isToken, _, autoCastAllowed = GetPetActionInfo(button.index)
		local macro
		if IsSet(autoCastAllowed) and not IsSet(isToken) and not issecretvalue(name) and name then
			macro = '/petautocasttoggle ' .. name
		end
		if button:GetAttribute('*macrotext2') ~= macro then
			button:SetAttribute('*type2', macro and 'macro' or ATTRIBUTE_NOOP)
			button:SetAttribute('*macrotext2', macro)
		end
	end
end

local function QueueActions()
	if st:QueueAfterCombat('actionbars_pet_actions', QueueActions) then return end
	UpdateActions()
end

------------------------------------
--- Events -------------------------
------------------------------------

-- Blizzard's pet bar events (PetActionBarMixin:OnLoad, forever and live), and
-- what each one redraws: 'all' the buttons, 'actions' the buttons and their
-- right clicks (the actions in the slots may have changed), the 'cooldown's
-- or the 'grid'. SPELLS_CHANGED is ElvUI's addition, for a pet learning a spell.
local EVENTS = {
	PLAYER_ENTERING_WORLD = 'actions',
	PET_BAR_UPDATE = 'actions',
	PET_UI_UPDATE = 'actions',
	UNIT_PET = 'actions',
	UPDATE_VEHICLE_ACTIONBAR = 'actions',
	SPELLS_CHANGED = 'actions',
	PLAYER_CONTROL_LOST = 'all',
	PLAYER_CONTROL_GAINED = 'all',
	PLAYER_FARSIGHT_FOCUS_CHANGED = 'all',
	PET_BAR_UPDATE_USABLE = 'all',
	PLAYER_TARGET_CHANGED = 'all',
	PLAYER_MOUNT_DISPLAY_CHANGED = 'all',
	UNIT_FLAGS = 'all',
	UNIT_AURA = 'all',
	PET_BAR_UPDATE_COOLDOWN = 'cooldown',
	PET_BAR_SHOWGRID = 'grid',
	PET_BAR_HIDEGRID = 'grid',
}
-- The unit events, for the one unit Blizzard's bar follows each for.
local EVENT_UNITS = {
	UNIT_PET = 'player',
	UNIT_FLAGS = 'pet',
	UNIT_AURA = 'pet',
}

local function OnEvent(_, event)
	local what = EVENTS[event]
	if what == 'cooldown' then
		for _, button in ipairs(bar.buttons) do
			button:SetCooldownTimes(GetPetActionCooldown(button.index))
		end
	elseif what == 'grid' then
		local shown = event == 'PET_BAR_SHOWGRID'
		for _, button in ipairs(bar.buttons) do
			button.grid = shown
			button:UpdateGrid()
		end
	else
		RefreshAll()
		if what == 'actions' then
			QueueActions()
		end
	end
end

------------------------------------
--- The bar ------------------------
------------------------------------

-- Once, out of combat (AB:CreateBar).
local function CreateButtons(header)
	bar = header
	for i = 1, NUM_SLOTS do
		local button = AB:CreateSecureButton(bar, i, PetButton)
		button:SetAttribute('type', 'pet')
		button:SetAttribute('action', i)
		button:SetAttribute('*type2', ATTRIBUTE_NOOP)
		button:RegisterForDrag('LeftButton', 'RightButton')
		button:SetScript('OnDragStart', OnDragStart)
		button:SetScript('OnReceiveDrag', OnReceiveDrag)
		bar:WrapScript(button, 'OnClick', PRE_CLICK)
		bar.buttons[i] = button
	end

	-- The range tint and the attack flash, while the bar is shown. A plain
	-- child of the header: it isn't protected, and its OnUpdate only runs
	-- while the bar is visible.
	local ticker = CreateFrame('Frame', nil, bar)
	local sinceRange = 0
	ticker:SetScript('OnUpdate', function(_, elapsed)
		sinceRange = sinceRange + elapsed
		local checkRange = sinceRange >= RANGE_TIME
		if checkRange then
			sinceRange = 0
		end
		for _, button in ipairs(bar.buttons) do
			if checkRange then
				button:RefreshTint()
			end
			button:UpdateFlash(elapsed)
		end
	end)

	local events = CreateFrame('Frame')
	for event in pairs(EVENTS) do
		if EVENT_UNITS[event] then
			events:RegisterUnitEvent(event, EVENT_UNITS[event])
		else
			events:RegisterEvent(event)
		end
	end
	events:SetScript('OnEvent', OnEvent)
end

AB.barTypes.pet = {
	CreateButtons = CreateButtons,
	UpdateActions = UpdateActions,
	texts = { hotkey = true },
}
