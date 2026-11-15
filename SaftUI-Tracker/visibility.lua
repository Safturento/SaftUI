local st = SaftUI
local TR = st.Tracker

--[[
	Fading and hiding SaftUI's tracker (design: "Fading and hiding"). Six
	triggers, each with a choice of what the tracker does while it applies:

	  combat     In combat           Show, Fade, Hide   InCombatLockdown (and the events)
	  nocombat   Out of combat       Show, Fade, Hide   the rest of the time
	  mouseoff   Mouse off           Show, Fade         the mouse isn't over the tracker
	  instance   In instances        Show, Fade, Hide   IsInInstance
	  boss       Boss fights         Show, Fade, Hide   ENCOUNTER_START to ENCOUNTER_END
	  mythic     Mythic+             Show, Fade, Hide   C_ChallengeMode.IsChallengeModeActive

	The strongest of the triggers that apply wins (Hide over Fade over Show), and
	Show fully under the mouse then turns a Fade into Show (never a Hide: a hidden
	window can't be hovered). Defaults are Show everywhere.

	TR.Visibility is the pure half: Applies reads the game, Resolve turns what
	applies, the settings and the mouse into what each part does, Driver builds the
	item layer's state driver from the settings. TR:ApplyVisibility is the applier:
	the one place that decides whether the tracker shows. It runs after every
	refresh (TR:RunStages), on the game's events (init.lua), on a change of the
	mouse while a rule needs it, and on a change of a setting.

	What each part does (every cell is in the report of Task 12, and in
	.agents/taint.md rule 17):
	  - the window: Fade is its alpha, Hide is Hide, in combat too (it is a plain
	    frame). It is placed by TR:ApplyWindowShown with the handover and an empty
	    list, so there is one answer to "shown?" and no flicker. A window faded to 0
	    takes no mouse (its rows, header, chevrons, wheel: SetRowMouse), or a click
	    meant for the world would land on it; hovering is the geometry's
	    (IsMouseOver), which needs no mouse. A new row made while faded takes none.
	  - the panel (Background under the mouse only) is the window's backdrop frame's
	    alpha; the text stays.
	  - the item buttons, with Hide quest items with the tracker off: untouched,
	    full alpha, shown, usable whatever the window does; a hidden window keeps
	    being laid out, so out of combat they are assigned and placed by its rows
	    as usual (in combat they stay put and dim as always). On: Fade is their alpha, never
	    under BUTTON_MIN_ALPHA (a button at 0 still takes clicks and EnableMouse is
	    blocked on a secure button in combat), Hide is the layer's state driver in
	    combat (In combat, Out of combat and Boss fights, which a macro condition can
	    say) and Hide directly, out of combat, for In instances, Mythic+ and Boss
	    fights (a loading screen, a key's start; boss1 may not exist). A hide that
	    must happen in combat waits for its end, queued as 'tracker_items'.
	  - the nearest button: never. Its driver frame carries the pet battle's
	    condition alone (TR.NearestDriver).
	  - Blizzard's tracker during a handover: Hide conceals it (TR:PlaceBlizzard
	    reads TR.visHidden), Fade holds its alpha with the C SetAlpha, put back
	    after Blizzard's own (a post-hook on its SetAlpha). Hover is read from the
	    holder (in place) or the beside spot's numbers.

	Fades take TR.FADE_TIME from faded to full, alpha only, by one OnUpdate that
	runs only while an alpha is moving or the mouse needs watching (TR.fader).
]]

TR.FADE_TIME = 0.2

local Visibility = {}
TR.Visibility = Visibility

-- The triggers, in the order the tab lists them.
Visibility.TRIGGERS = { 'combat', 'nocombat', 'mouseoff', 'instance', 'boss', 'mythic' }

local RANK = { show = 0, fade = 1, hide = 2 }

-- What the item layer's state driver can say, in its order: a macro condition
-- for the trigger's Hide. Boss fights is the nearest it can get (boss1 exists).
local DRIVER_PARTS = {
	{ key = 'combat', condition = '[combat] hide' },
	{ key = 'nocombat', condition = '[nocombat] hide' },
	{ key = 'boss', condition = '[@boss1,exists] hide' },
}

-- The triggers whose Hide can't be (only) the driver's: they start out of combat
-- (a loading screen, a key's start), or the condition is only close (boss1).
local DIRECT = { instance = true, mythic = true, boss = true }

local Plain = st.Plain

local function Clamp(value, low, high)
	if value < low then return low end
	if value > high then return high end
	return value
end

-- A trigger's choice, 'show' for anything unknown; Mouse off can't hide (the
-- window couldn't be hovered back), so a saved Hide is a Fade.
local function Choice(settings, key)
	local choice = settings[key]
	if choice ~= 'fade' and choice ~= 'hide' then return 'show' end
	if key == 'mouseoff' and choice == 'hide' then return 'fade' end
	return choice
end

------------------------------------------------------------------ the pure parts

-- The item layer's visibility driver for the settings: the pet battle always,
-- then In combat, Out of combat and Boss fights when they are Hide and Hide quest
-- items with the tracker is on, then show. The nearest button's is
-- TR.NearestDriver(), never this.
local driverKey, driverText
function Visibility.Driver(settings)
	-- Cached by the four settings it reads: it runs on every refresh.
	local items = settings.items and true or false
	local key = ('%s|%s|%s|%s'):format(tostring(items), tostring(settings.combat), tostring(settings.nocombat), tostring(settings.boss))
	if key == driverKey and TR.PET_BATTLE_HIDE == driverText.pet then return driverText.text end
	local parts = { TR.PET_BATTLE_HIDE }
	if items then
		for _, part in ipairs(DRIVER_PARTS) do
			if settings[part.key] == 'hide' then parts[#parts + 1] = part.condition end
		end
	end
	parts[#parts + 1] = 'show'
	driverKey, driverText = key, { pet = TR.PET_BATTLE_HIDE, text = table.concat(parts, '; ') }
	return driverText.text
end

-- Which triggers apply now: { combat, nocombat, mouseoff, instance, boss, mythic }.
-- Reads InCombatLockdown (or the combat events' word: lockdown begins after
-- PLAYER_REGEN_DISABLED's handlers and ends before PLAYER_REGEN_ENABLED's),
-- TR:IsTrackerHovered (or the `hovered` it is given), IsInInstance,
-- C_InstanceEncounter.IsEncounterInProgress (the global shim where the namespace is
-- missing; the encounter events' word while one is known: the game may still say a
-- fight is on inside ENCOUNTER_END) and C_ChallengeMode.IsChallengeModeActive, each only
-- where the client has it. Mythic+ and the encounter call may be missing: those
-- triggers then never apply.
function Visibility.Applies(hovered, out)
	local applies = out or {}
	local combat = TR.combatNow
	if combat == nil then combat = InCombatLockdown() end
	applies.combat = combat and true or false
	applies.nocombat = not applies.combat
	if hovered == nil then hovered = TR:IsTrackerHovered() end
	applies.mouseoff = not hovered

	local instance = false
	if type(IsInInstance) == 'function' then
		local inside = Plain(IsInInstance())
		instance = inside == true or inside == 1
	end
	applies.instance = instance

	local boss = TR.encounterNow
	if boss == nil then
		-- The namespaced function where it exists; the global is Blizzard's deprecated
		-- shim over it (gone with the CVar loadDeprecationFallbacks, and at the next
		-- expansion), read only where the namespace is missing.
		local ask
		if type(C_InstanceEncounter) == 'table' and type(C_InstanceEncounter.IsEncounterInProgress) == 'function' then
			ask = C_InstanceEncounter.IsEncounterInProgress
		elseif type(IsEncounterInProgress) == 'function' then
			ask = IsEncounterInProgress
		end
		if ask then
			local going = Plain(ask())
			boss = going == true or going == 1
		end
	end
	applies.boss = boss and true or false

	local mythic = false
	if type(C_ChallengeMode) == 'table' and type(C_ChallengeMode.IsChallengeModeActive) == 'function' then
		mythic = Plain(C_ChallengeMode.IsChallengeModeActive()) == true
	end
	applies.mythic = mythic
	return applies
end

-- Whether the client has Mythic+ (the tab shows its row only then).
function Visibility.HasMythic()
	return type(C_ChallengeMode) == 'table' and type(C_ChallengeMode.IsChallengeModeActive) == 'function'
end

-- What each part does, from what applies, the settings and whether the mouse is
-- over the tracker (pure; `out` is a table to fill again, so a call allocates
-- nothing):
--   window            'show', 'fade' or 'hide'
--   base              the same before Show fully under the mouse (so the mouse is
--                     watched while a hovered tracker would fade away from it)
--   alpha             the window's alpha: the faded opacity while it fades, else 1
--   items             the same for the item buttons: with Hide quest items off
--                     always 'show'
--   itemAlpha         1, or max(fade_alpha, BUTTON_MIN_ALPHA) while they fade
--                     (Ruling 31: never invisible while clickable)
--   hideItemsDirectly the buttons hide by Hide, out of combat, and not by the
--                     driver alone: the hide is In instances, Mythic+ or Boss
--                     fights
--   background        the panel shows (Background under the mouse only: while
--                     hovered)
function Visibility.Resolve(applies, settings, hovered, out)
	local result = out or {}
	local window, direct = 'show', false
	for _, key in ipairs(Visibility.TRIGGERS) do
		if applies[key] then
			local choice = Choice(settings, key)
			if RANK[choice] > RANK[window] then window = choice end
			if choice == 'hide' and DIRECT[key] then direct = true end
		end
	end
	-- Show fully under the mouse: a Fade is a Show then. A Hide stays.
	result.base = window
	if window == 'fade' and settings.hover and hovered then window = 'show' end

	local faded = Clamp(st.PlainNumber(settings.fade_alpha) or 0.3, 0, 1)
	result.window = window
	result.alpha = window == 'fade' and faded or 1
	if settings.items then
		result.items = window
		result.itemAlpha = window == 'fade' and math.max(faded, TR.BUTTON_MIN_ALPHA) or 1
		result.hideItemsDirectly = window == 'hide' and direct
	else
		result.items, result.itemAlpha, result.hideItemsDirectly = 'show', 1, false
	end
	result.background = not settings.background_hover or (hovered and true or false)
	return result
end

------------------------------------------------------------------ the applier

-- The mouse of every frame of the window that takes it, off while the window is
-- faded out (alpha 0): a click goes through to the world. Hovering is geometry
-- (IsMouseOver), which needs no mouse. EnableMouse is not protected on any of
-- these (none is secure, none is a parent or anchor of a secure frame).
-- Only a frame this turned off is turned on again: one that never took the mouse
-- (the empty-list row) never gets it.
local mouseOff, wheelOff = setmetatable({}, { __mode = 'k' }), setmetatable({}, { __mode = 'k' })

local function SetFrameMouse(frame, on)
	if not frame then return end
	if on then
		if mouseOff[frame] then
			mouseOff[frame] = nil
			frame:EnableMouse(true)
		end
		return
	end
	if frame:IsMouseEnabled() then
		mouseOff[frame] = true
		frame:EnableMouse(false)
	end
	if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
end

-- The same for a frame's wheel.
local function SetFrameWheel(frame, on)
	if not frame then return end
	if on then
		if wheelOff[frame] then
			wheelOff[frame] = nil
			frame:EnableMouseWheel(true)
		end
	elseif frame:IsMouseWheelEnabled() then
		wheelOff[frame] = true
		frame:EnableMouseWheel(false)
	end
end

-- One row's mouse takers: the row, a quest row's slot and icon button, a zone
-- row's chevron.
function TR:SetRowMouse(row, on)
	SetFrameMouse(row, on)
	SetFrameMouse(row.slot, on)
	SetFrameMouse(row.iconButton, on)
	SetFrameMouse(row.chevron, on)
end

-- The window's mouse on or off: its rows, the header and its chevron, the scroll
-- lock's strip, and the wheel (which the camera zooms with when the cursor is over
-- the window, the list scrolls or not).
function TR:SetInput(on)
	local off = not on
	if self.inputOff == off then return end
	self.inputOff = off
	if self.pools then
		for _, pool in pairs(self.pools) do
			for _, row in ipairs(pool.rows) do self:SetRowMouse(row, on) end
		end
	end
	local header = self.header
	if header then
		SetFrameMouse(header, on)
		SetFrameMouse(header.collapse, on)
	end
	if self.window then SetFrameMouse(self.window.barLock, on) end
	-- The scroll bar's own parts (the template's track and thumb take the mouse, its
	-- steppers are buttons, the bar the wheel): plain frames of SaftUI's scroll frame.
	local bar = self.scroll and self.scroll.ScrollBar
	if bar then
		SetFrameMouse(bar.Track, on)
		SetFrameMouse(bar.Back, on)
		SetFrameMouse(bar.Forward, on)
		SetFrameMouse(bar.GetThumb and bar:GetThumb(), on)
		SetFrameWheel(bar, on)
	end
	self:UpdateWheel()
end

-- The fade's own frame: its OnUpdate is set only while an alpha is moving or the
-- mouse is watched, so nothing runs while nothing changes.
local function Fx(self)
	local fx = self.fx
	if not fx then
		fx = { window = 1, items = 1, bg = 1, tWindow = 1, tItems = 1, tBg = 1 }
		self.fx = fx
	end
	return fx
end

-- One alpha a step of `step` toward its target; returns whether it moved.
local function Approach(fx, key, target, step)
	local value = fx[key]
	if value == target then return false end
	if value < target then
		value = math.min(value + step, target)
	else
		value = math.max(value - step, target)
	end
	fx[key] = value
	return true
end

-- The fade's alphas, drawn: the window, the panel, the item buttons and
-- Blizzard's tracker, each only where it differs from what it shows.
function TR:DrawFade()
	local fx = self.fx
	local window = self.window
	if not (fx and window) then return end
	if self.windowAlpha ~= fx.window then
		self.windowAlpha = fx.window
		window:SetAlpha(fx.window)
	end
	self:DrawBackground()
	if self.itemFade ~= fx.items then
		self.itemFade = fx.items
		self:RefreshItemAlpha()
	end
	self:SyncBlizzardAlpha()
end

-- The panel: the window's backdrop frame, by alpha (the theme draws on it and on
-- frames under it, so one alpha covers every look). The text stays.
function TR:DrawBackground()
	local fx = self.fx
	local backdrop = self.window and self.window.backdrop
	if not (fx and backdrop) then return end
	if self.backgroundAlpha ~= fx.bg or backdrop:GetAlpha() ~= fx.bg then
		self.backgroundAlpha = fx.bg
		backdrop:SetAlpha(fx.bg)
	end
end

-- One step of the fade, and the mouse. Allocates nothing.
function TR:StepFade(elapsed)
	local fx = self.fx
	if not fx then return end
	if self.hoverWatch then
		local hovered = self:IsTrackerHovered() and true or false
		if hovered ~= self.hoverSeen then
			self:ApplyVisibility()
		end
	end
	local step = elapsed / TR.FADE_TIME
	local moved = Approach(fx, 'window', fx.tWindow, step)
	moved = Approach(fx, 'items', fx.tItems, step) or moved
	moved = Approach(fx, 'bg', fx.tBg, step) or moved
	if moved then self:DrawFade() end
	self.fading = fx.window ~= fx.tWindow or fx.items ~= fx.tItems or fx.bg ~= fx.tBg
	if not (self.fading or self.hoverWatch) then self:UpdateFader() end
end

local function OnFadeUpdate(_, elapsed)
	TR:StepFade(elapsed)
end

-- The OnUpdate runs while an alpha moves or the mouse is watched.
function TR:UpdateFader()
	local fader = self.fader
	if not fader then
		fader = CreateFrame('Frame', nil, UIParent)
		self.fader = fader
	end
	local needed = self.fading or self.hoverWatch
	if needed then
		if not fader:GetScript('OnUpdate') then fader:SetScript('OnUpdate', OnFadeUpdate) end
	elseif fader:GetScript('OnUpdate') then
		fader:SetScript('OnUpdate', nil)
	end
end

-- Decides what the tracker does now and does it. Every part is told by the
-- resolver's answer: the window (shown or hidden, its alpha), the panel, the
-- item buttons (their alpha, their layer's driver, their direct hide), Blizzard's
-- tracker during a handover (TR:PlaceBlizzard, TR:SyncBlizzardAlpha), and the
-- mouse. Nothing here is a secure call in combat: the driver and the direct hide
-- wait for the end of it. Runs with the switch on only (the tracker is built).
function TR:ApplyVisibility()
	if not self.built or not self.window then return end
	local settings = self.config.visibility
	local hovered = self:IsTrackerHovered() and true or false
	self.hoverSeen = hovered
	self.applies = Visibility.Applies(hovered, self.applies)
	local result = Visibility.Resolve(self.applies, settings, hovered, self.visibility)
	self.visibility = result
	local fx = Fx(self)

	-- Shown or hidden: one answer, with the handover's and the empty list's
	-- (ApplyWindowShown), and Blizzard's tracker follows (PlaceBlizzard), after the
	-- alphas below are settled so it is placed once, with the alpha it will wear.
	local hidden = result.window == 'hide'
	local hiddenChanged = (self.visHidden or false) ~= hidden
	self.visHidden = hidden

	-- The alphas move toward their targets; one that isn't seen (a window hidden
	-- with nothing else wearing it, a window that just came back) is put there at
	-- once. Blizzard's tracker in SaftUI's place wears the window's alpha while the
	-- window is hidden by the handover, so that one fades.
	local worn = self.window:IsShown() or ((self.handoverState or 'own') ~= 'own' and not hidden)
	local snap = not self.fxPlaced or hiddenChanged or not worn
	fx.tWindow, fx.tItems, fx.tBg = result.alpha, result.itemAlpha, result.background and 1 or 0
	if snap then
		fx.window, fx.items, fx.bg = fx.tWindow, fx.tItems, fx.tBg
		self.fxPlaced = true
	end
	if hiddenChanged then
		self:ApplyWindowShown()
		self:PlaceBlizzard(self.blizzardWhere)
	end
	if snap then self:DrawFade() end
	self.fading = fx.window ~= fx.tWindow or fx.items ~= fx.tItems or fx.bg ~= fx.tBg

	-- A window faded out takes no mouse; one that comes back takes it at once, so a
	-- click can land while it fades in.
	self:SetInput(not (result.window == 'fade' and result.alpha <= 0))

	-- The quest item buttons: hidden directly (out of combat, queued in it) and the
	-- layer's driver (set out of combat, queued in it).
	if (self.itemsHidden or false) ~= result.hideItemsDirectly then
		self.itemsHidden = result.hideItemsDirectly
		self:RefreshItems()
	end
	self:ApplyItemDriver()

	-- The mouse is watched while a rule needs it: Mouse off, a panel under the mouse
	-- only, or a fade the mouse lifts.
	-- Nothing is hovered, or revealed to be, while the window is hidden by a trigger.
	self.hoverWatch = (not hidden) and (settings.mouseoff ~= 'show' or settings.background_hover == true
		or (settings.hover and result.base == 'fade')) or false
	self:UpdateFader()
end

-- The game said something a trigger depends on: ENCOUNTER_START and ENCOUNTER_END
-- (the fight's word is kept until the world loads again), the Mythic+ events (the
-- state is read, and again on the next frame, since the game may settle after them).
function TR:OnVisibilityEvent(event)
	if event == 'ENCOUNTER_START' then
		self.encounterNow = true
	elseif event == 'ENCOUNTER_END' then
		self.encounterNow = false
	end
	self:ApplyVisibility()
	if event:find('^CHALLENGE_MODE') then
		C_Timer.After(0, function() self:ApplyVisibility() end)
	end
end
