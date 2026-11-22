local st = SaftUI
local TP = st:NewModule('TalentPlan')

--[[
	The talent plan: a saved order of talent picks per class, shown beside the
	talent window. This file is the module and its wiring to Blizzard's talent
	window; the pure rules are in model.lua, the saved plans in store.lua, the
	reader of the talent tree in data.lua and the docked panel in panel.lua.
	WoW Forever only (the plan's levels and the talent window it sits beside
	are Forever's), so it does nothing on retail.

	Taint (.agents/taint.md rules 1 to 4): nothing is written onto a Blizzard
	frame. SetupBlizzard installs post-hooks only, each running in xpcall and
	each only asking for a later pass:
	  HookScript OnShow and OnHide on TalentsFrame, OnHide and OnMouseUp on
	  PlayerSpellsFrame, hooksecurefunc on TalentsFrame's SetTab and on
	  PlayerSpellsFrame's SetInspecting and ClearInspectUnit, and two
	  EventRegistry callbacks ('TalentFrameBase.ButtonsUpdated' and
	  'TalentFrameBase.ConfigUpdated').
	The reads are IsShown, GetTab, IsInspecting, and GetLeft, GetRight and
	GetEffectiveScale for the dock. The window is made movable by
	SaftUI-Misc/movable.lua (st:EnableMoving, whose OnMouseUp hook re-anchors
	the window), which the TOC loads before this folder and whose module is
	enabled first (AceAddon enables modules in the order they were made), so
	its hooks are installed first; the re-dock waits a frame besides.

	TP:Refresh is the one place that reads (D.Read) and draws. TP.view is its
	last result, { tree, plan, rows, summary }, for the overlays and the drag.
]]

local function guarded(fn)
	return function() xpcall(fn, geterrorhandler()) end
end

function TP:OnEnable()
	st:BindModuleConfig(self, 'talentplan')
	if not st.forever then return end
	st:OnBlizzardAddon('Blizzard_PlayerSpells', function() self:SetupBlizzard() end)
end

function TP:UpdateConfig()
	if self.hooked then self:QueueRefresh() end
end

function TP:TalentsFrame()
	local window = _G.PlayerSpellsFrame
	return window and window.TalentsFrame
end

-- The spec tab shown (the spec group), read from Blizzard's talent frame.
function TP:ViewedGroup()
	return self:TalentsFrame():GetTab()
end

function TP:ShouldShow()
	local window = _G.PlayerSpellsFrame
	local talents = window and window.TalentsFrame
	if not talents or not (self.config and self.config.enable) then return false end
	return window:IsShown() and talents:IsShown() and not window:IsInspecting()
end

-- Runs once, when Blizzard_PlayerSpells is there.
function TP:SetupBlizzard()
	if self.hooked then return end
	local window = _G.PlayerSpellsFrame
	local talents = window and window.TalentsFrame
	if not talents then return end
	self.hooked = true

	local refresh = guarded(function() TP:QueueRefresh() end)
	talents:HookScript('OnShow', guarded(function() TP:OnTalentsShow() end))
	talents:HookScript('OnHide', guarded(function() TP:HidePanel() end))
	window:HookScript('OnHide', guarded(function() TP:HidePanel() end))
	window:HookScript('OnMouseUp', guarded(function() TP:QueueDock() end))
	hooksecurefunc(talents, 'SetTab', refresh)
	hooksecurefunc(window, 'SetInspecting', refresh)
	hooksecurefunc(window, 'ClearInspectUnit', refresh)
	EventRegistry:RegisterCallback('TalentFrameBase.ButtonsUpdated', refresh, self)
	EventRegistry:RegisterCallback('TalentFrameBase.ConfigUpdated', refresh, self)

	if talents:IsShown() and window:IsShown() then self:OnTalentsShow() end
end

-- The Talents tab came up: dock at once, again on the next frame (the panel
-- layout moves the window after OnShow), draw, and scroll to the waiting step
-- on this show only.
function TP:OnTalentsShow()
	self.fresh = true
	if self:ShouldShow() then
		self:BuildPanel()
		self:Dock()
	end
	self:QueueDock()
	self:QueueRefresh()
end

function TP:QueueRefresh()
	if self.refreshQueued then return end
	self.refreshQueued = true
	C_Timer.After(0, function()
		self.refreshQueued = false
		xpcall(function() self:Refresh() end, geterrorhandler())
	end)
end

function TP:QueueDock()
	if self.dockQueued then return end
	self.dockQueued = true
	C_Timer.After(0, function()
		self.dockQueued = false
		xpcall(function() self:Dock() end, geterrorhandler())
	end)
end

local EVENTS = { 'PLAYER_LEVEL_UP', 'TRAIT_CONFIG_UPDATED', 'TRAIT_NODE_CHANGED' }

-- The events the panel hears, only while it shows.
function TP:Listen(on)
	if on == (self.listening or false) then return end
	self.listening = on
	if not self.eventFrame then
		self.eventFrame = CreateFrame('Frame')
		self.eventFrame:SetScript('OnEvent', function() TP:QueueRefresh() end)
	end
	for _, event in ipairs(EVENTS) do
		if on then self.eventFrame:RegisterEvent(event) else self.eventFrame:UnregisterEvent(event) end
	end
end

function TP:HidePanel()
	self:Listen(false)
	self.view = nil
	self:HideOverlays()
	if self.panel then self.panel:Hide() end
end

-- Reads the talent tree and draws. The one place that does either.
function TP:Refresh()
	if not self:ShouldShow() then
		self.view = nil
		self:HidePanel()
		return
	end
	local group = self:ViewedGroup()
	local tree = TP.Data.Read(group)
	if not tree then
		self.view = nil
		self:HidePanel()
		return
	end
	local panel = self:BuildPanel()
	if not panel:IsShown() then
		panel:Show()
		self:Dock()
	end
	self:Listen(true)

	local plan = TP.Store.Active(group)
	local rows, summary
	if plan then rows, summary = TP.Model.States(plan, tree.nodes, tree.level) end
	self.view = { tree = tree, plan = plan, rows = rows, summary = summary }
	self:DrawPanel(self.view)
	self:DrawOverlays(self.view)
	if self.fresh then
		self.fresh = false
		self:ScrollToWaiting()
	end
end
