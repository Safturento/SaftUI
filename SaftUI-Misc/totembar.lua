local st = SaftUI
local TB = st:NewModule('TotemBar')

--[[
	/sui options to hide WoW Forever's totem bar, MultiCastActionBarFrame
	(Blizzard_ActionBar/Shared/MultiCastActionBarFrame.xml), and to size and space its
	buttons. Blizzard_ActionBar loads it only for the camelot, wrath and cata game types, so
	retail has no totem bar: nothing here runs there and the /sui section doesn't appear.

	What Blizzard does with the bar:
	  - Shows and hides it in TotemActionBarMixin:UpdateShownState, through the bar's
	    Edit Mode SetShown override. It's shown while a totem slot has spells
	    (numActiveSlots, counted on PLAYER_ENTERING_WORLD and UPDATE_MULTI_CAST_ACTIONBAR)
	    or Edit Mode's Totem Bar checkbox is on, and only while no vehicle or override bar
	    replaces the main action bar (the ActionBarController.MainActionBarStateOverridden
	    callback). That callback runs on every action bar page, bonus bar and vehicle
	    change, so Blizzard re-shows the bar often.
	  - Places it through Blizzard's Edit Mode. It isn't a managed frame. In its default
	    position it's the last of the bottom action bars (Camelot EditModeUtil's
	    GetBottomActionBars), and EditModeManagerFrame:UpdateBottomActionBarPositions
	    re-anchors it above the bars stacked on MainActionBar. That also runs in combat:
	    on each action bar's combat visibility update, when the pet, stance or possess
	    bar or the vehicle leave button shows or hides, and when the XP bars change.
	  - Its buttons are secure action buttons (ActionBarButtonTemplate, and
	    SecureFrameTemplate for the summon and recall buttons), so the bar is
	    protected. Addon code can't show, hide, reparent or move it in combat.

	Hiding parents the bar to a hidden SaftUI frame, out of combat. Blizzard keeps
	showing, hiding and placing the bar as before. Its show and hide calls only change
	the bar's own shown flag, and under a hidden parent the bar never becomes visible.
	So it never flashes, and its buttons' OnShow/OnHide scripts don't run. Nothing of
	Blizzard's reparents this bar (Blizzard's Edit Mode only reparents managed frames
	and the cast bar), so it stays under the hidden frame. Turning the option off puts
	the bar back under its old parent and leaves the shown flag alone. It shows again
	only if Blizzard wants it shown, e.g. not on a character with no totems.

	A state driver (RegisterStateDriver(bar, 'visibility', 'hide')) would have hidden it
	by calling the bar's Hide every 0.2s. After each of Blizzard's re-shows the bar would
	be on screen until the next tick. Turning the option off would also need a Show,
	which overrides Blizzard's own rules for when the bar shows.

	On a shaman SaftUI also moves the bar in its own edit mode, from a holder of SaftUI's
	(totemposition.lua), and on every class it sizes and spaces the bar's buttons
	(totemlayout.lua).

	SaftUI writes nothing onto the bar or any Blizzard table, except that hooksecurefunc
	replaces the two methods it hooks on the bar (ClearAllPoints and SetPoint) with its own
	secure wrappers. Blizzard's Edit Mode can write the bar's UIParent anchor into its own
	layout after a snap break (totemposition.lua); that's Blizzard's code, and no SaftUI
	frame is in it. SaftUI's calls on the bar are GetParent, GetFrameLevel, GetPoint,
	GetRect, GetEffectiveScale, IsShown, IsVisible, SetParent, SetFrameLevel, and SetSize,
	ClearAllPoints, SetPoint and EnableMouse through the plain widget methods
	(st:SetSizeDirect and the like; the bar's Edit Mode overrides are SetScale, SetPoint,
	ClearAllPoints, SetShown and Hide), and HookScript for its OnShow. It reads, never
	writes, the bar's systemInfo (its Edit Mode layout entry).

	The bar's files load in the TOC's order: this one (the module, hiding the bar, its
	setup and a profile change, and TB.PostHook and TB.S, which the others share), then
	totemlayout.lua (the buttons' size and spacing), totemposition.lua (the holder and
	the edit mode mover), totemoptions.lua (the /sui page), totemskin.lua (SaftUI's look
	for the bar's buttons and its flyout) and totemtimers.lua (the totem timers above its
	element buttons). The flyout's choices follow the button size (totemskin.lua), and the
	timers follow the slot buttons' width.
]]

-- TB.S: what the totem bar's files share with each other and nothing else; not an API.
-- They load in the TOC's order, this file first. S.laidOutOn, which totemlayout.lua
-- writes and totemposition.lua reads, is always read and written as S.laidOutOn, never
-- kept in a local. A function a later file needs (S.BarSize) is set here by the file
-- that has it, and the later file takes it as a local of its own at its top.
TB.S = {}

-- hooksecurefunc on one of Blizzard's global functions, if this client has it. On TB
-- for totemlayout.lua, totemskin.lua and totemtimers.lua too.
function TB.PostHook(name, hook)
	if type(_G[name]) == 'function' then
		hooksecurefunc(name, hook)
	end
end

-- Puts the bar under the hidden frame, or back under the parent it had, as the
-- profile says. The bar is protected, so in combat this waits for the end of combat
-- and then reads the profile again.
function TB:Apply()
	local bar, hider = self.bar, self.hider
	if not bar then return end
	if st:QueueAfterCombat('totembar', function() self:Apply() end) then return end

	-- Only reparent when it doesn't change whether the bar is on screen. If it did,
	-- the secure buttons' OnHide/OnShow would run from SaftUI's call chain and can
	-- leave tainted state in Blizzard's shared action button code (an
	-- ADDON_ACTION_BLOCKED later, e.g. entering a vehicle in combat). At login the bar
	-- is still hidden, so a reload always applies the setting cleanly.
	if self.config.hide then
		if bar:GetParent() ~= hider then
			if bar:IsVisible() then
				st:Print('The totem bar will be hidden after a /reload.')
				return
			end
			self.oldParent, self.oldLevel = bar:GetParent(), bar:GetFrameLevel()
			bar:SetParent(hider)
		end
	elseif bar:GetParent() == hider then
		if bar:IsShown() then
			st:Print('The totem bar will show again after a /reload.')
			return
		end
		bar:SetParent(self.oldParent or UIParent)
		-- SetParent can renumber the bar's frame level, so put back the one it had.
		if self.oldLevel then bar:SetFrameLevel(self.oldLevel) end
	end
end

-- A profile change. The holder's place is the edit mode's (EM:UpdateConfig runs the
-- mover's apply after this), but a profile with no position keeps the holder's spot
-- before the buttons are laid out, so they stay on the holder.
function TB:UpdateConfig()
	self:KeepPlacement()
	self:Apply()
	self:ApplyButtonLayout()
	self:ApplySkin()
	self:ApplyTimerLayout()
	self:QueueCapture()
end

function TB:Setup()
	if self.bar then return end
	local bar = _G.MultiCastActionBarFrame
	if not bar then return end
	self.bar = bar

	-- Never shown. While the bar is under it, it's protected too, and nothing moves it.
	self.hider = CreateFrame('Frame', nil, UIParent)
	self.hider:Hide()

	-- Only a shaman has totems; on other classes nothing moves the bar (see
	-- totemposition.lua). Made before the layout, which lays the buttons out on it and
	-- sizes it.
	if st.my_class == 'SHAMAN' then
		self.holder = CreateFrame('Frame', st.name .. 'TotemBarHolder', UIParent)
	end

	-- Blizzard first counts the totem slots on PLAYER_ENTERING_WORLD, so at login the
	-- bar is still hidden here and reparenting it runs none of its scripts.
	self:Apply()

	self:SetupSkinAndTimers()
	self:SetupButtonLayout()
	self:SetupPosition()
end

-- The timers above the element buttons (totemtimers.lua) and SaftUI's look for the
-- bar's buttons and its flyout (totemskin.lua). The timers are SaftUI's own frames,
-- anchored to the slot buttons but never moving them, so they're made straight away,
-- in combat too: a /reload mid-fight still shows how long the totems have left. The
-- skin anchors regions of the secure buttons, so after a /reload in combat it waits
-- for the end of combat. The two sets of hooks touch separate things, so their order
-- doesn't matter.
function TB:SetupSkinAndTimers()
	self:SetupTimers()
	if st:QueueAfterCombat('totembar_setup', function() self:SetupSkin() end) then return end
	self:SetupSkin()
end

function TB:OnEnable()
	st:BindModuleConfig(self, 'totembar')
	if _G.MultiCastActionBarFrame then
		self:Setup()
	elseif st.forever then
		st:OnBlizzardAddon('Blizzard_ActionBar', function() self:Setup() end)
	end
end
