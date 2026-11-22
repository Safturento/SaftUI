local st = SaftUI
local TP = st:GetModule('TalentPlan')
local M, S = TP.Model, TP.Store

--[[
	The talent plan's overlays on Blizzard's talent tree: a light for the node a
	panel row points at, a glow on the waiting step's node, a dim on the nodes
	the plan doesn't use, and, while planning, a catcher that takes the clicks
	on every node so a planning click adds or removes a step and never reaches
	Blizzard's button.

	Taint (.agents/taint.md rules 1, 2, 3 and 6): nothing is written onto a
	Blizzard frame and nothing of Blizzard's is hooked here. Every overlay is
	a frame of SaftUI's, a child of one layer frame that is a child of
	TalentsFrame, anchored over a button with SetAllPoints (SaftUI's frame
	anchored to Blizzard's, not the other way round, and none of them
	protected). The talent buttons are plain buttons, not secure. The reads are
	TalentsFrame:EnumerateAllTalentButtons(), button:GetNodeID() and
	button:GetFrameLevel(); they run from TP:Refresh, which a timer starts after
	'TalentFrameBase.ButtonsUpdated', never inside Blizzard's call. The map from
	a node to its button is made on every draw: Blizzard's pool hands a button
	another node when the tree redraws, so nothing is kept across a draw but the
	records, keyed by button in a weak table. A click on a catcher calls
	TP:PlanClick, which only changes the plan; it never calls Blizzard's
	OnClick, a trait purchase or a config call.
]]

-- records[button] = { button, nodeID, light, glow, dim, catcher }, weak by button
local records = setmetatable({}, { __mode = 'k' })
TP.overlays = records

local LINE = 2
local LEVEL = { DIM = 4, GLOW = 5, LIGHT = 6, CATCHER = 10 }

local function Edges(frame)
	local list = {}
	local function edge(p1, p2, w, h)
		local texture = frame:CreateTexture(nil, 'OVERLAY')
		texture:SetPoint(p1, frame, p1)
		texture:SetPoint(p2, frame, p2)
		if w then texture:SetWidth(w) end
		if h then texture:SetHeight(h) end
		list[#list + 1] = texture
	end
	edge('TOPLEFT', 'TOPRIGHT', nil, LINE)
	edge('BOTTOMLEFT', 'BOTTOMRIGHT', nil, LINE)
	edge('TOPLEFT', 'BOTTOMLEFT', LINE, nil)
	edge('TOPRIGHT', 'BOTTOMRIGHT', LINE, nil)
	frame.edges = list
end

local function Layer()
	if TP.layer then return TP.layer end
	TP.layer = st:CreateFrame('Frame', nil, TP:TalentsFrame())
	TP.layer:SetAllPoints(TP:TalentsFrame())
	TP.layer:EnableMouse(false)
	return TP.layer
end

local function NewPart(layer, button)
	local part = CreateFrame('Frame', nil, layer)
	part:SetAllPoints(button)
	part:EnableMouse(false)
	part:Hide()
	return part
end

local function Record(button)
	local rec = records[button]
	if rec then return rec end
	local layer = Layer()
	rec = { button = button }
	rec.dim = NewPart(layer, button)
	rec.dim.texture = rec.dim:CreateTexture(nil, 'OVERLAY')
	rec.dim.texture:SetAllPoints(rec.dim)
	rec.dim.texture:SetColorTexture(0, 0, 0, 0.6)
	rec.glow = NewPart(layer, button)
	Edges(rec.glow)
	rec.light = NewPart(layer, button)
	Edges(rec.light)

	local catcher = CreateFrame('Button', nil, layer)
	catcher:SetAllPoints(button)
	catcher:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	catcher:EnableMouse(false)
	catcher:Hide()
	catcher:SetScript('OnClick', function(_, mouse)
		TP:PlanClick(rec.nodeID, mouse)
		if GameTooltip:IsOwned(catcher) then TP:ShowCatcherTip(rec) end
	end)
	catcher:SetScript('OnEnter', function() TP:ShowCatcherTip(rec) end)
	catcher:SetScript('OnLeave', function()
		if GameTooltip:IsOwned(catcher) then GameTooltip:Hide() end
	end)
	rec.catcher = catcher
	records[button] = rec
	return rec
end

------------------------------------------------------------------ pure parts

-- The catcher's tooltip: the node's name, a line a planned rank, then either
-- that every rank is planned or what a click does.
function TP.CatcherLines(plan, nodeID, node)
	local lines = { node.name }
	local steps = plan and M.StepsOf(plan, nodeID) or {}
	for _, step in ipairs(steps) do
		lines[#lines + 1] = ('Rank %d at level %d'):format(step.rank, step.level)
	end
	if #steps >= node.maxRanks then
		lines[#lines + 1] = ('All %d ranks are planned.'):format(node.maxRanks)
	else
		lines[#lines + 1] = 'Click: add the next rank. Right-click: remove the last one.'
	end
	return lines
end

------------------------------------------------------------------ drawing

local function PaintEdges(frame, r, g, b)
	for _, texture in ipairs(frame.edges) do texture:SetColorTexture(r, g, b, 1) end
end

local function Place(rec)
	local level = rec.button:GetFrameLevel()
	rec.dim:SetFrameLevel(level + LEVEL.DIM)
	rec.glow:SetFrameLevel(level + LEVEL.GLOW)
	rec.light:SetFrameLevel(level + LEVEL.LIGHT)
	rec.catcher:SetFrameLevel(level + LEVEL.CATCHER)
end

local function SetCatcher(rec, on)
	if on then
		rec.catcher:Show()
		rec.catcher:EnableMouse(true)
	else
		rec.catcher:EnableMouse(false)
		rec.catcher:Hide()
		if GameTooltip:IsOwned(rec.catcher) then GameTooltip:Hide() end
	end
end

local function HideAll(rec)
	rec.dim:Hide()
	rec.glow:Hide()
	rec.light:Hide()
	SetCatcher(rec, false)
end

-- Light, glow, dim and catcher for every button of the tree, from the view.
function TP:DrawOverlays(view)
	if not view then
		self:HideOverlays()
		return
	end
	local talents = self:TalentsFrame()
	local plan, nodes = view.plan, view.tree.nodes
	local waiting = view.rows and view.summary.waiting and view.rows[view.summary.waiting]
	local dimOn = self.config and self.config.dim and plan and #plan.steps > 0
	local live = {}
	for button in talents:EnumerateAllTalentButtons() do
		local rec = Record(button)
		live[rec] = true
		rec.nodeID = button:GetNodeID()
		Place(rec)
		if nodes[rec.nodeID] then
			rec.dim:SetShown(dimOn and M.PlannedRanks(plan, rec.nodeID) == 0 or false)
			rec.glow:SetShown(waiting ~= nil and waiting.nodeID == rec.nodeID)
			rec.light:SetShown(self.lit ~= nil and self.lit == rec.nodeID)
		else
			rec.dim:Hide()
			rec.glow:Hide()
			rec.light:Hide()
		end
		-- every button, planned or not, so a planning click never buys a talent
		-- (a node the plan can't hold, a choice node, does nothing on a click)
		SetCatcher(rec, self.planning and true or false)
	end
	for _, rec in pairs(records) do
		if not live[rec] then
			rec.nodeID = nil -- a released pool button names no node (Light skips it)
			HideAll(rec)
		end
	end
	self:PaintOverlays()
end

function TP:PaintOverlays()
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	local ar, ag, ab = st:Color('accent'):GetRGB()
	for _, rec in pairs(records) do
		PaintEdges(rec.light, nr, ng, nb)
		PaintEdges(rec.glow, ar, ag, ab)
	end
end

-- Everything off: the panel went away. Planning ends with it.
function TP:HideOverlays()
	self.lit = nil
	self.planning = false
	for _, rec in pairs(records) do HideAll(rec) end
	self:PaintPlanButton()
end

function TP:Light(nodeID)
	self.lit = nodeID
	for _, rec in pairs(records) do
		rec.light:SetShown(nodeID ~= nil and rec.nodeID == nodeID and self.view ~= nil)
	end
end

function TP:SetPlanning(on)
	on = on and true or false
	if on == (self.planning or false) then return end
	self.planning = on
	self:PaintPlanButton()
	if self.panel and self.panel:IsShown() then self:Refresh() end
end

function TP:ShowCatcherTip(rec)
	local node = self.view and self.view.tree.nodes[rec.nodeID]
	if not node then return end
	local lines = TP.CatcherLines(S.Active(self:ViewedGroup()), rec.nodeID, node)
	GameTooltip:SetOwner(rec.catcher, 'ANCHOR_RIGHT')
	GameTooltip:SetText(lines[1], 1, 1, 1, 1, true)
	for i = 2, #lines do GameTooltip:AddLine(lines[i], 0.8, 0.8, 0.8, true) end
	GameTooltip:Show()
end

------------------------------------------------------------------ planning

-- A planning click on a node: left adds its next rank (after the selected row,
-- when there is one), right removes its last. 'added' | 'removed' | 'maxed' | nil.
function TP:PlanClick(nodeID, mouse)
	local view = self.view
	local node = view and nodeID and view.tree.nodes[nodeID]
	if not node then return nil end
	local group = self:ViewedGroup()
	local plan = S.Active(group)
	local result
	if mouse == 'RightButton' then
		local removed = plan and M.RemoveLastOf(plan, nodeID)
		if not removed then return nil end
		if self.selected and self.selected >= removed then
			self.selected = self.selected > removed and self.selected - 1 or nil
		end
		result = 'removed'
	elseif mouse == 'LeftButton' then
		plan = plan or S.New('New plan', group)
		if M.PlannedRanks(plan, nodeID) >= node.maxRanks then return 'maxed' end
		local index = M.AddStep(plan, nodeID, self.selected)
		if self.selected then self.selected = index end
		result = 'added'
	else
		return nil
	end
	self:Refresh()
	return result
end
