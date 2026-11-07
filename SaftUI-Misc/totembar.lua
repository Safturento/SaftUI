local st = SaftUI
local TB = st:NewModule('TotemBar')

--[[
	A /sui option to hide WoW Forever's totem bar, MultiCastActionBarFrame
	(Blizzard_ActionBar/Shared/MultiCastActionBarFrame.xml). Blizzard_ActionBar loads it
	only for the camelot, wrath and cata game types, so retail has no totem bar: nothing
	here runs there and the /sui section doesn't appear.

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

	Position stays Blizzard's: the bar is moved in Blizzard's Edit Mode, after ticking
	Totem Bar in its settings. Once moved there, Blizzard's bottom bar layout leaves it
	where it was put. SaftUI can't own its position the way it owns the swing timer
	bars. In Blizzard's default position Blizzard re-anchors it in combat (see above),
	and a protected bar can't be put back until combat ends, so it would jump back to
	Blizzard's spot mid-fight.

	Nothing is written onto the bar or any Blizzard table. The only calls on the bar are
	GetParent, GetFrameLevel, SetParent and SetFrameLevel, all plain widget methods (the
	bar's Edit Mode overrides are SetScale, SetPoint, ClearAllPoints, SetShown and Hide).
]]

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

-- A profile change.
function TB:UpdateConfig()
	self:Apply()
end

function TB:Setup()
	if self.bar then return end
	local bar = _G.MultiCastActionBarFrame
	if not bar then return end
	self.bar = bar

	-- Never shown. While the bar is under it, it's protected too, and nothing moves it.
	self.hider = CreateFrame('Frame', nil, UIParent)
	self.hider:Hide()

	-- Blizzard first counts the totem slots on PLAYER_ENTERING_WORLD, so at login the
	-- bar is still hidden here and reparenting it runs none of its scripts.
	self:Apply()
end

function TB:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_ActionBar' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

function TB:OnEnable()
	st:BindModuleConfig(self, 'totembar')
	if _G.MultiCastActionBarFrame then
		self:Setup()
	elseif st.forever then
		self:RegisterEvent('ADDON_LOADED')
	end
end

-- The Totem Bar section in the /sui tree. Absent until the bar exists, so never shown
-- on retail. The bar has no SaftUI mover (see the top of this file), so the section
-- says where to move it instead.
function TB:GetConfigTable()
	if not self.bar then return end

	local hide = st.Config.generators.toggle(1, 'Hide totem bar', 'full')
	hide.desc = "Hides Blizzard's totem bar. Turning this off shows it again whenever Blizzard would show it. If the bar is on screen when you change this, it applies after a /reload."

	return {
		name = 'Totem Bar',
		type = 'group',
		get = function(info) return self.config[info[#info]] end,
		set = function(info, value)
			self.config[info[#info]] = value
			self:Apply()
		end,
		args = {
			hide = hide,
			move_note = {
				order = 2,
				type = 'description',
				name = ("To move the totem bar, open Blizzard's Edit Mode, tick %s in its settings and drag the bar. "
					.. "SaftUI doesn't move it: Blizzard re-places the bar during combat, and because its buttons "
					.. "are secure, SaftUI couldn't put it back until combat ends."):format(_G.HUD_EDIT_MODE_TOTEM_ACTION_BAR_LABEL or 'Totem Bar'),
			},
		},
	}
end
