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
	     totem bar, the extra action button, the zone ability) stays where Blizzard
	     put it before.

	The bars' own events are switched off too, as oUF does for the frames it
	replaces (UnregisterAllEvents, a C call). They only drive the bars' looks:
	grid and strata on drag, the pet bar's buttons, the vehicle leave button's
	showing. With them off, Blizzard's code doesn't call protected methods on those
	bars at all, and the pet bar and vehicle leave button keep still in Blizzard's
	bottom stack. Two bars keep their events, as Bartender4 leaves them:
	  - MainActionBar: on PLAYER_ENTERING_WORLD it registers Blizzard's gamepad and
	    keyboard switch handlers, which also show and hide the micro menu and the
	    bags bar.
	  - OverrideActionBar: in a skinned vehicle Blizzard's ACTIONBUTTON binds click
	    its buttons (GetActionButtonForID), which it keeps up to date.

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
	{ name = 'OverrideActionBar', events = false },
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

-- The widget's own C method, so no Lua replacement on the frame runs.
local function DisableMouse(frame)
	if frame and frame.EnableMouse then
		getmetatable(frame).__index.EnableMouse(frame, false)
	end
end

local function Conceal(frame)
	getmetatable(frame).__index.SetAlpha(frame, 0)
	DisableMouse(frame)

	if type(frame.actionButtons) == 'table' then
		for _, button in ipairs(frame.actionButtons) do
			DisableMouse(button)
		end
	end

	local pageNumber = frame.ActionBarPageNumber
	if pageNumber then
		DisableMouse(pageNumber.UpButton)
		DisableMouse(pageNumber.DownButton)
	end

	if frame.Selection then
		frame.Selection:HookScript('OnShow', function(selection)
			selection:Hide()
		end)
	end
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
