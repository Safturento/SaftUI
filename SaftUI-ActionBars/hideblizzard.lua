local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	Takes Blizzard's action bars off screen, for as long as SaftUI-ActionBars is
	enabled. Disabling the addon and reloading gives them back untouched: nothing
	here is saved, and nothing is written onto a Blizzard frame or table.

	The bars (Blizzard_ActionBar and Blizzard_OverrideActionBar, forever and live):
	  - MainActionBar (MainMenuBar before 11.2.7), with its art: BorderArt, the
	    EndCaps gryphons, the page number and arrows, and the vehicle leave button
	    (MainMenuBarVehicleLeaveButton, a child of the main bar).
	  - MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft and
	    MultiBar5-7.
	  - StanceBar, PetActionBar and PossessActionBar.
	  - OverrideActionBar, the skinned vehicle bar.
	The totem bar (MultiCastActionBarFrame) is left alone: SaftUI-Misc/totembar.lua
	owns it. The status tracking bars are SaftUI-Misc/experience.lua's.

	Each bar is hidden one of two ways, as .agents/taint.md rules 4 and 8 allow:

	  1. Blocked, with SetRolesets('alwaysBlocked'), when it isn't on screen. Every
	     bar but the main bar is created hidden (hidden="true" in its XML), and this
	     file runs while SaftUI-ActionBars loads, before Blizzard first shows them
	     (the multibars on SETTINGS_LOADED, the stance bar after
	     PLAYER_ENTERING_WORLD, the pet bar on its pet events). The client then
	     never draws the bar or anything in it, whatever Blizzard's own Show and
	     Hide calls do. It's one C call that writes nothing onto the frame.
	     Blizzard keeps running its bars as before: it shows and hides them, pages
	     them, and its binding commands still click its (hidden) buttons, so binds
	     keep working until SaftUI maps them.

	  2. Concealed, when it's on screen. The main bar is always on screen at load:
	     MainActionBar isn't hidden in its XML. So is the pet bar on a /reload
	     with a pet out: PetActionBarMixin:OnLoad shows it when PetHasActionBar().
	     Blocking a shown bar would hide it from SaftUI's call chain and run its
	     buttons' OnHide tainted. For the main bar that's
	     ActionBarActionButtonMixin:OnHide on twelve secure buttons, which writes
	     their needsUpdate fields and entries of Blizzard's range and usable check
	     tables. The buttons read those again whenever Blizzard pages them, in
	     combat too, just before SetAttribute('pressAndHoldAction') (UpdateAction):
	     the shape of an ADDON_ACTION_BLOCKED on a stance change in combat. So the
	     bar stays shown and is made invisible and click-through instead, all with
	     C methods that run no scripts:
	       - SetAlpha(0) on the bar. Its children (buttons, art, page arrows, proc
	         alerts) inherit it. Blizzard's Edit Mode never sets an action bar's
	         alpha, and nothing else in Blizzard_ActionBar does.
	       - EnableMouse(false) on the bar, its buttons (actionButtons, which
	         ActionBarMixin:ActionBar_OnLoad fills for every bar: the main bar's
	         ActionButton1-12, the pet bar's PetActionButton1-10) and its page
	         arrows, so nothing invisible catches the mouse. Nothing in
	         Blizzard_ActionBar or Blizzard_EditMode turns their mouse back on.
	     The pet bar's events are off too (below), so it no longer follows the pet.
	     What Blizzard still calls on it (the spellbook's PetActionBar:Update when
	     a pet spell is hovered) only shows, hides or redraws it, which keeps its
	     alpha and mouse. SaftUI's override bindings take its keys (bindings.lua),
	     so it stays invisible, can't be clicked and does nothing.
	       - Its Edit Mode box (Selection) ignores its parent's alpha
	         (ignoreParentAlpha in EditModeSystemTemplates.xml), so it's kept
	         hidden instead, with taint.md rule 5's HookScript. Blizzard's Edit
	         Mode then doesn't offer the bar.
	     A bar that was concealed stays concealed. It goes on taking its place in
	     Blizzard's bottom bar stack, so whatever Blizzard stacks above it (the
	     totem bar, the extra abilities container) stays where Blizzard put it
	     before. The extra action button and the zone ability inside that
	     container are anchored to SaftUI's holders instead (extras.lua).

	The bars' own events are switched off too, as oUF does for the frames it
	replaces (UnregisterAllEvents, a C call). They only drive the bars' looks:
	grid and strata on drag, the pet bar's buttons, the vehicle leave button's
	showing (SaftUI's own leave button is in extras.lua). With them off,
	Blizzard's code doesn't call protected methods on those bars at all, and the
	pet bar and vehicle leave button keep still in Blizzard's bottom stack. Only
	MainActionBar keeps its events, as Bartender4 leaves them: on
	PLAYER_ENTERING_WORLD it registers Blizzard's gamepad and keyboard switch
	handlers, which also show and hide the micro menu and the bags bar.

	OverrideActionBar's events are off too, for the micro menu. In a skinned
	vehicle or override bar, Blizzard moves its micro menu into the override
	bar: OverrideActionBarMixin:UpdateMicroButtons
	(Blizzard_OverrideActionBar/OverrideActionBar.lua, the same on forever and
	live) calls MicroMenu:OverrideMicroMenuPosition(self, ...), which reparents
	MicroMenu to the bar (Blizzard_MicroMenu/Shared/MicroMenuContainer.lua).
	SaftUI-Minimap keeps Blizzard's micro buttons parented to MicroMenu
	(microbuttons.lua), and the client draws nothing inside a blocked frame, so
	every micro button would vanish from SaftUI's micro menu bar for the ride.
	UpdateMicroButtons only moves the menu while ActionBarController's state is
	LE_ACTIONBAR_STATE_OVERRIDE. It's called from three places:
	  - the bar's UNIT_ENTERED_VEHICLE handler (UpdateSkin, in a vehicle).
	    Gone with the bar's events.
	  - the bar's OnShow. The roleset system hides a blocked frame
	    (SetRolesets "gates visibility", IsRolesetFiltered "hidden because of
	    its rolesets", SimpleFrameAPIDocumentation.lua), so Blizzard's Show
	    doesn't bring it on screen and OnShow doesn't run. That's the same
	    rule that makes blocking a visible frame run its OnHide (taint.md rule
	    8). Not yet confirmed in game.
	  - ActionBarController_UpdateAll's own UpdateSkin call, which runs while
	    the state is still LE_ACTIONBAR_STATE_MAIN (ActionBarController.lua),
	    so it never moves the menu.
	So the menu stays in MicroMenuContainer. Nothing SaftUI needs is lost with
	the events. ActionBarController's own events still drive the bar:
	UpdateSkin pages its buttons, and ValidateActionBarTransition shows and
	hides it. Setup registers the bar's two XP events again, which only redraw
	its XP bar. The bar's ACTIONBUTTON keys are SaftUI's in every state but a
	pet battle (bindings.lua), and Blizzard drops the override bar for a pet
	battle (PET_BATTLE_OPENING_START in ActionBarController.lua). Bar 1 pages
	to the vehicle and override bars itself ([vehicleui], [overridebar],
	bars.lua). The bar's pitch buttons and its vehicle health, power and XP
	bars don't show while it's blocked (docs/followups.md).
	Putting the menu back with a post-hook isn't safe: reparenting MicroMenu
	shows the micro buttons, which runs their OnShow
	(MainMenuBarMicroButtonMixin) in SaftUI's call chain (taint.md rule 4).

	Out of combat only: blocking and EnableMouse are protected on these frames.
	This runs while SaftUI-ActionBars loads, which is before combat lockdown
	applies. If lockdown is on anyway, it all waits for the end of combat, and a
	bar Blizzard has shown by then is concealed instead of blocked.
]]

local BLIZZARD_BARS = {
	{ name = 'MainActionBar', events = false },
	{ name = 'MainMenuBar', events = false },
	{ name = 'MultiBarBottomLeft', events = true },
	{ name = 'MultiBarBottomRight', events = true },
	{ name = 'MultiBarRight', events = true },
	{ name = 'MultiBarLeft', events = true },
	{ name = 'MultiBar5', events = true },
	{ name = 'MultiBar6', events = true },
	{ name = 'MultiBar7', events = true },
	{ name = 'StanceBar', events = true },
	{ name = 'PetActionBar', events = true },
	{ name = 'PossessActionBar', events = true },
	{ name = 'MainMenuBarVehicleLeaveButton', events = true },
	{ name = 'OverrideActionBar', events = true },
}

-- The Blizzard addons that create those bars.
local BLIZZARD_ADDONS = { 'Blizzard_ActionBar', 'Blizzard_OverrideActionBar' }

-- Bars already taken off screen: frame -> 'blocked' or 'concealed'. A table of
-- SaftUI's own, so nothing is written onto the frames. MainMenuBar can be the
-- same frame as MainActionBar.
local handled = {}
AB.blizzardBars = handled

-- True only for a plain false. A secret IsVisible counts as on screen, so a bar
-- is never blocked on a guess.
local function IsKnownFalse(value)
	return not issecretvalue(value) and not value
end

-- Makes a Blizzard frame click-through with the widget's own C method, so no
-- Lua replacement on the frame runs and nothing is written onto it. Protected
-- on a protected frame: out of combat only. extras.lua uses it too.
function AB:DisableMouse(frame)
	if frame and frame.EnableMouse then
		getmetatable(frame).__index.EnableMouse(frame, false)
	end
end

-- Keeps a Blizzard Edit Mode system's box (its Selection) hidden, so Blizzard's
-- Edit Mode doesn't offer the frame. A HookScript, as .agents/taint.md rule 5
-- has it; nothing is written onto the frame. extras.lua uses it too.
function AB:HideEditModeSelection(frame)
	local selection = frame and frame.Selection
	if selection then
		selection:HookScript('OnShow', function(box)
			box:Hide()
		end)
	end
end

local function Conceal(frame)
	getmetatable(frame).__index.SetAlpha(frame, 0)
	AB:DisableMouse(frame)

	if type(frame.actionButtons) == 'table' then
		for _, button in ipairs(frame.actionButtons) do
			AB:DisableMouse(button)
		end
	end

	local pageNumber = frame.ActionBarPageNumber
	if pageNumber then
		AB:DisableMouse(pageNumber.UpButton)
		AB:DisableMouse(pageNumber.DownButton)
	end

	AB:HideEditModeSelection(frame)
end

local function HideBar(info)
	local frame = _G[info.name]
	if not frame or handled[frame] then return end

	if frame.SetRolesets and IsKnownFalse(frame:IsVisible()) then
		frame:SetRolesets('alwaysBlocked')
		handled[frame] = 'blocked'
	else
		Conceal(frame)
		handled[frame] = 'concealed'
	end

	if info.events then
		frame:UnregisterAllEvents()
	end
end

function AB:HideBlizzard()
	if st:QueueAfterCombat('actionbars_hideblizzard', function() self:HideBlizzard() end) then return end
	for _, info in ipairs(BLIZZARD_BARS) do
		HideBar(info)
	end
end

-- Now, while SaftUI-ActionBars loads (see the top of this file).
AB:HideBlizzard()

-- Blizzard's addons load before SaftUI's, so their bars exist by now. If one
-- hasn't loaded yet, its bars are taken off screen as it loads, when they're
-- still hidden.
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded

local function AllLoaded()
	for _, addon in ipairs(BLIZZARD_ADDONS) do
		if not IsAddOnLoaded(addon) then return false end
	end
	return true
end

if not AllLoaded() then
	local loader = CreateFrame('Frame')
	loader:RegisterEvent('ADDON_LOADED')
	loader:SetScript('OnEvent', function(self, event, loaded)
		for _, addon in ipairs(BLIZZARD_ADDONS) do
			if loaded == addon then
				AB:HideBlizzard()
			end
		end
		if AllLoaded() then
			self:UnregisterEvent('ADDON_LOADED')
		end
	end)
end
