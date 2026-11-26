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
	-- the faces (Blizzard_TalentFaces.lua) show the plan's simulated state while planning
	local faces = st:GetModule('TalentFaces', true)
	if faces then faces:SetPlanSource(function(nodeID) return TP:PlanDisplay(nodeID) end) end
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

local EVENTS = { 'PLAYER_LEVEL_UP', 'TRAIT_CONFIG_UPDATED', 'TRAIT_NODE_CHANGED', 'TRAIT_NODE_CHANGED_PARTIAL' }

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
	if self.expandButton then self.expandButton:Hide() end
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
	if self:IsCollapsed() then
		panel:Hide() -- the header button stands in for it
		self:Dock()
	elseif not panel:IsShown() then
		panel:Show()
		self:Dock()
	end
	self:Listen(true)

	local plan = TP.Store.Active(group)
	local rows, summary
	if plan then rows, summary = TP.Model.States(plan, tree.nodes, tree.level) end
	-- the plan played against the tree's rules (simulate.lua), for the faces, the clicks and the panel
	local sim = TP.Sim.Run(tree.shape, plan and plan.steps or {})
	self.view = { tree = tree, plan = plan, rows = rows, summary = summary, sim = sim }
	self:DrawPanel(self.view)
	self:DrawOverlays(self.view)
	if self.fresh then
		self.fresh = false
		self:ScrollToWaiting()
	end
end

-- '/sui tp check': the plan's rules against the game, over the real ranks of the
-- viewed (or the active) spec: the nodes where they disagree, or that they agree.
-- The owner's check of the gate scope (see the talent faces spec, open questions).
function TP:RunCheck()
	if not st.forever then
		st:Print('The talent plan is for WoW Forever only.')
		return
	end
	local group = self.hooked and self:TalentsFrame() and self:TalentsFrame().GetTab and self:ViewedGroup()
		or C_SpecializationInfo.GetActiveSpecGroup()
	local tree = TP.Data.Read(group)
	if not tree or not tree.configID then
		st:Print('No talent tree to check.')
		return
	end
	local bad = TP.Sim.Check(tree.shape, tree.real)
	if #bad == 0 then
		st:Print("The plan's rules agree with the game.")
		return
	end
	st:Print('A character below max level may see extra lines: the game also holds nodes back for level, which the rules do not model.')
	for _, d in ipairs(bad) do
		local node = tree.shape.nodes[d.nodeID]
		st:Print(('%s (%d): the game says %s %s, the rules say %s.'):format(node.name or 'a node', d.nodeID,
			d.field == 'gated' and 'available' or 'edges met', tostring(d.game), tostring(d.sim)))
	end
end

if st.Config and st.Config.AddSubcommand then
	st.Config:AddSubcommand('tp', function(rest)
		if (rest or ''):lower() == 'check' then
			TP:RunCheck()
		else
			st:Print('/sui tp check compares the talent plan\'s rules with the game\'s.')
		end
	end)
end

--[[
	The plan's Allocate (the dots menu): stages the plan's next points in the
	talent window, in the plan's order, as if each were clicked there, and never
	applies them: Blizzard's Apply Changes learns them. Each point is
	C_Traits.PurchaseRank on the active config, the one trait writer the plan
	calls (.agents/taint.md rule 23), out of combat only, on the active spec's
	tab only. The talent window hears TRAIT_NODE_CHANGED and draws them itself.
	It stops at the first point the game refuses: no point left, or a step the
	tree doesn't allow yet. 'combat' | 'inactive' | 'noplan' | count, stoppedAt.
]]
function TP:Allocate()
	if InCombatLockdown() then
		st:Print("Talents can't change in combat.")
		return 'combat'
	end
	local group = self:ViewedGroup()
	local plan = group and self.Store.Active(group)
	if not (plan and #plan.steps > 0) then return 'noplan' end
	if C_SpecializationInfo.GetActiveSpecGroup() ~= group then
		st:Print('Switch to this spec to allocate its points.')
		return 'inactive'
	end
	-- the config the window shows and applies: Camelot's is the spec group's
	-- combat config (its SetTab), as data.lua reads it
	local talents = self:TalentsFrame()
	local configID = talents and talents.GetConfigID and talents:GetConfigID()
		or C_SpecializationInfo.GetCombatConfigIDForSpecGroup(group) or C_ClassTalents.GetActiveConfigID()
	if not configID then
		st:Print("The talent window isn't ready yet.")
		return 'inactive'
	end
	-- while Apply's cast runs, or when the talents can't change here, the game's
	-- own buttons don't buy either
	if (talents and talents.IsCommitInProgress and talents:IsCommitInProgress())
		or (C_ClassTalents.CanEditTalents and not C_ClassTalents.CanEditTalents()) then
		st:Print("Talents can't change right now.")
		return 'locked'
	end
	local want, count, stopped = {}, 0, nil
	for i, nodeID in ipairs(plan.steps) do
		want[nodeID] = (want[nodeID] or 0) + 1
		local info = C_Traits.GetNodeInfo(configID, nodeID)
		if info and self.Data.StagedRank(info) < want[nodeID] then
			if not C_Traits.PurchaseRank(configID, nodeID) then
				stopped = i
				break
			end
			count = count + 1
		end
	end
	-- why it stopped: out of points, or the next step isn't allowed yet
	local why
	if stopped then
		local currency = C_Traits.GetTreeCurrencyInfo and self.view and self.view.tree
			and C_Traits.GetTreeCurrencyInfo(configID, self.view.tree.treeID, false)
		local left = currency and currency[1] and currency[1].quantity
		local node = self.view and self.view.tree and self.view.tree.nodes[plan.steps[stopped]]
		if left == 0 then
			why = 'No points left.'
		elseif node then
			why = ('%s (level %d) can\'t be taken yet.'):format(node.name, self.Model.Level(stopped))
		end
	end
	if count == 0 then
		st:Print(stopped and ('No points allocated. ' .. (why or '')) or 'Every step of the plan is allocated.')
	else
		st:Print(('Allocated %d %s. Press Apply Changes to learn %s.'):format(count,
			count == 1 and 'point' or 'points', count == 1 and 'it' or 'them')
			.. (stopped and why and why ~= 'No points left.' and (' Stopped: ' .. why) or ''))
	end
	self:QueueRefresh()
	return count, stopped
end
