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

-- Blizzard's own talent glow (the art its talent buttons use for a node that
-- can be bought: added light, pulsing in and out over 0.72 seconds), on the
-- glow frame's own texture and animation, never written onto a Blizzard frame.
-- Blizzard picks the atlas by the button's art set (square, circle, choice,
-- apex...), so the button's own `Glow` texture is read for its atlas name
-- (a read only; the circle's is the fallback) and the texture takes that
-- atlas's size, centred on the button, as Blizzard's does. Made only for a
-- glow that shows (nine in ten of the ~80 buttons never do).
local GLOW_ATLAS = 'talents-node-circle-greenglow'
-- Added light, as the game draws this art. A glow, not an interaction state
-- (the states scan, S3, forbids a literal ADD blend for those).
local GLOW_BLEND = 'ADD'

local function GlowAtlas(button)
	local own = button.Glow
	local name = type(own) == 'table' and own.GetAtlas and own:GetAtlas()
	return type(name) == 'string' and name ~= '' and name or GLOW_ATLAS
end

local function GlowArt(frame, atlas)
	local texture = frame.glowTexture
	if not texture then
		texture = frame:CreateTexture(nil, 'OVERLAY')
		texture:SetBlendMode(GLOW_BLEND)
		texture:SetPoint('CENTER', frame, 'CENTER')
		frame.glowTexture = texture
		if frame.CreateAnimationGroup then
			local group = frame:CreateAnimationGroup()
			group:SetLooping('REPEAT')
			local up = group:CreateAnimation('Alpha')
			up:SetTarget(texture)
			up:SetFromAlpha(0)
			up:SetToAlpha(1)
			up:SetDuration(0.36)
			up:SetOrder(1)
			up:SetSmoothing('OUT')
			local down = group:CreateAnimation('Alpha')
			down:SetTarget(texture)
			down:SetFromAlpha(1)
			down:SetToAlpha(0)
			down:SetDuration(0.36)
			down:SetOrder(2)
			down:SetSmoothing('IN')
			frame.glowAnim = group
		end
	end
	if frame.glowAtlas ~= atlas then
		frame.glowAtlas = atlas
		texture:SetAtlas(atlas, true)
	end
	return texture
end

-- The waiting node's highlight in the panel's theme: under Blizzard a glow,
-- under Thick and Thin the border.
local function SetGlowLook(rec, blizzard)
	local frame = rec.glow
	local on = blizzard and frame:IsShown()
	for _, texture in ipairs(frame.edges) do texture:SetShown(not blizzard) end
	if on then
		GlowArt(frame, GlowAtlas(rec.button)):Show()
		if frame.glowAnim and not frame.glowAnim:IsPlaying() then frame.glowAnim:Play() end
	elseif frame.glowTexture then
		if frame.glowAnim then frame.glowAnim:Stop() end
		frame.glowTexture:Hide()
	end
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
	catcher:SetScript('OnEnter', function()
		TP:ShowCatcherTip(rec)
		TP:HoverFace(rec.nodeID, true)
	end)
	catcher:SetScript('OnLeave', function()
		if GameTooltip:IsOwned(catcher) then GameTooltip:Hide() end
		if TP.refusal and TP.refusal.nodeID == rec.nodeID then TP.refusal = nil end
		TP:HoverFace(rec.nodeID, false)
	end)
	rec.catcher = catcher
	records[button] = rec
	return rec
end

------------------------------------------------------------------ pure parts

-- The catcher's tooltip: the node's name, a line a planned rank, then either
-- that every rank is planned or what a click does, and, after a refused click,
-- the refusal's reason as the last line (the tooltip paints it Danger).
function TP.CatcherLines(plan, nodeID, node, refusal)
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
	if refusal then lines[#lines + 1] = refusal end
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
	-- while planning the simulated state is the dim (the faces), so this one is off
	local dimOn = self.config and self.config.dim and plan and #plan.steps > 0 and not self.planning
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
	self:PaintTotal()
	self:QueueFaces()
end

-- The talent faces' module (Blizzard_TalentFaces.lua), when it is there.
local function Faces() return st:GetModule('TalentFaces', true) end

-- The faces draw again: the plan or planning changed what they show.
function TP:QueueFaces()
	local faces = Faces()
	if faces then faces:Queue() end
end

function TP:HoverFace(nodeID, on)
	local faces = Faces()
	if faces and faces.Hover then faces:Hover(nodeID, on) end
end

-- What a node's face shows while planning: the simulated state and the planned rank,
-- or nil (not planning, or a node the tree's shape doesn't know: it shows its real
-- state). The rank is nil too where Blizzard's rule shows no number.
function TP:PlanDisplay(nodeID)
	local view = self.planning and self.view
	local shape = view and view.sim and view.tree.shape
	local node = shape and nodeID and view.sim.nodes[nodeID]
	if not node then return nil end
	-- Blizzard's rule for the number (a rank above 0 or a node that can be taken) is the
	-- face's; the tree's own rule, no number for a one rank node, is the source's
	local planned = node.rank
	if shape.hideSingle and shape.nodes[nodeID].maxRanks == 1 and not TP.Sim.ShowCount(shape, nodeID, node.rank, node.state) then
		planned = nil
	end
	return { state = node.state, planned = planned }
end

-- The window's top left while planning: the planned points, then each tree's.
function TP.TotalLines(shape, sim)
	local lines = { ('Planned: %d points'):format(sim.spent.total or 0) }
	local parts = {}
	for _, g in ipairs(shape.groups or {}) do
		parts[#parts + 1] = ('%s %d'):format(g.name, sim.spent[g.id] or 0)
	end
	if #parts > 0 then lines[2] = table.concat(parts, ' · ') end
	return lines
end

function TP:PaintTotal()
	local view = self.view
	local on = self.planning and view and view.sim and true or false
	if not on then
		if self.total then self.total:Hide() end
		return
	end
	if not self.total then
		self.total = st:CreateFontString(Layer(), st.config.profile.skinning.font)
		self.total:SetJustifyH('LEFT')
		self.total:SetPoint('TOPLEFT', self:TalentsFrame(), 'TOPLEFT', 12, -10)
	end
	self.total:SetText(table.concat(TP.TotalLines(view.tree.shape, view.sim), '\n'))
	self.total:SetTextColor(st:Color('text', 'normal'):GetRGB())
	self.total:Show()
end

function TP:PaintOverlays()
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	local ar, ag, ab = st:Color('accent'):GetRGB()
	local panels = st.config.profile.panels
	local blizzard = st:IsBlizzardLook(panels and panels.theme)
	for _, rec in pairs(records) do
		PaintEdges(rec.light, nr, ng, nb)
		PaintEdges(rec.glow, ar, ag, ab)
		SetGlowLook(rec, blizzard)
	end
end

-- Everything off: the panel went away. Planning ends with it.
function TP:HideOverlays()
	self.lit = nil
	self.planning = false
	self.refusal = nil
	for _, rec in pairs(records) do HideAll(rec) end
	self:PaintPlanButton()
	self:PaintTotal()
	self:QueueFaces()
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
	self.refusal = nil
	self:PaintPlanButton()
	self:QueueFaces()
	if self.panel and self.panel:IsShown() then self:Refresh() end
end

function TP:ShowCatcherTip(rec)
	local node = self.view and self.view.tree.nodes[rec.nodeID]
	if not node then return end
	local refusal = self.refusal and self.refusal.nodeID == rec.nodeID and self.refusal.reason or nil
	local lines = TP.CatcherLines(S.Active(self:ViewedGroup()), rec.nodeID, node, refusal)
	GameTooltip:SetOwner(rec.catcher, 'ANCHOR_RIGHT')
	GameTooltip:SetText(lines[1], 1, 1, 1, 1, true)
	for i = 2, #lines do
		if refusal and i == #lines then
			local r, g, b = st:Color('text', 'danger'):GetRGB()
			GameTooltip:AddLine(lines[i], r, g, b, true)
		else
			GameTooltip:AddLine(lines[i], 0.8, 0.8, 0.8, true)
		end
	end
	GameTooltip:Show()
end

------------------------------------------------------------------ planning

-- A planning click on a node: left adds its next rank (after the selected row,
-- when there is one), right removes its last. Both ask the tree's rules first
-- (TP.Sim.CanAdd, CanRemove): a click they refuse changes nothing and gives
-- 'refused', the reason, which the catcher's tooltip then shows.
-- 'added' | 'removed' | 'maxed' | 'refused', reason | nil.
function TP:PlanClick(nodeID, mouse)
	local view = self.view
	local node = view and nodeID and view.tree.nodes[nodeID]
	if not node then return nil end
	local group = self:ViewedGroup()
	local plan = S.Active(group)
	local shape = view.tree.shape
	local steps = plan and plan.steps or {}
	local result
	self.refusal = nil
	if mouse == 'RightButton' then
		if not (plan and M.PlannedRanks(plan, nodeID) > 0) then return nil end
		local ok, reason = TP.Sim.CanRemove(shape, steps, nodeID)
		if not ok then
			self.refusal = { nodeID = nodeID, reason = reason }
			return 'refused', reason
		end
		local removed = M.RemoveLastOf(plan, nodeID) -- the step CanRemove judged: the node's last
		if self.selected and self.selected >= removed then
			self.selected = self.selected > removed and self.selected - 1 or nil
		end
		result = 'removed'
	elseif mouse == 'LeftButton' then
		if plan and M.PlannedRanks(plan, nodeID) >= node.maxRanks then return 'maxed' end
		local ok, reason = TP.Sim.CanAdd(shape, steps, nodeID, plan and self.selected or nil)
		if not ok then
			self.refusal = { nodeID = nodeID, reason = reason }
			return 'refused', reason
		end
		plan = plan or S.New('New plan', group)
		local index = M.AddStep(plan, nodeID, self.selected)
		if self.selected then self.selected = index end
		result = 'added'
	else
		return nil
	end
	self:Refresh()
	return result
end
