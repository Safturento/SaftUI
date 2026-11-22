local st = SaftUI
local TP = st:GetModule('TalentPlan')
local M, S = TP.Model, TP.Store

--[[
	The talent plan's panel: a SaftUI frame parented to Blizzard's TalentsFrame
	(so it hides with the Talents tab) and hung beside PlayerSpellsFrame by two
	anchor points, on the side with more room. Nothing is written onto a
	Blizzard frame (.agents/taint.md rule 1): the panel and every part of it
	are SaftUI's, and TP:Dock only reads the window's rect.

	From the top: the title strip (the collapse arrow, "Leveling plan", the plan
	select button, the count), the rows in a scroll frame, the off plan line, and
	the footer (Plan, Import, Phases and the dots menu). Collapsed, only the
	title strip is left, holding the waiting step. TP.panel.rows[i] = { frame,
	kind, index } is the pooled row of step i, for the drag (Task 8);
	TP.selected is the step the new steps go after, or nil (Task 7).
]]

local L = { WIDTH = 250, GAP = 2, ROW_HEIGHT = 20 }
TP.Layout = L

local PAD = 4 -- the room round the rows and between the strips' parts
local ICON = 16
local CHECK = 12
local CHECK_ART = [[Interface\RaidFrame\ReadyCheck-Ready]]
local OFF_LINE = 16 -- the room the off plan line keeps above the footer

------------------------------------------------------------------ pure parts

-- Which side of the window the panel takes: the one with more room, RIGHT on a
-- tie. The rooms are measured from the same screen edges, so the panel's own
-- width cancels out of the comparison.
function L.Side(left, right, screenWidth, width)
	return left > screenWidth - right and 'LEFT' or 'RIGHT'
end

-- Where the scroll frame is set so row index's top sits a third of the view
-- down, in whole units and never past either end.
function L.ScrollOffset(index, rowHeight, viewHeight, contentHeight)
	local offset = (index - 1) * rowHeight - math.floor(viewHeight / 3)
	local most = math.max(0, contentHeight - viewHeight)
	return math.floor(math.min(math.max(offset, 0), most))
end

-- '27 Improved Ghost Wolf R2': the level, the talent and its rank when it has
-- more than one.
function TP.StepLabel(row, node)
	if not node then return 'Missing talent' end
	local label = ('%d %s'):format(row.level, node.name)
	if node.maxRanks > 1 then label = label .. (' R%d'):format(row.rank) end
	return label
end

-- What the collapsed strip says.
function TP.StripText(view)
	local rows, summary = view and view.rows, view and view.summary
	if not rows or #rows == 0 then return 'No plan' end
	local nodes = view.tree and view.tree.nodes or {}
	if summary.waiting then
		local row = rows[summary.waiting]
		return TP.StepLabel(row, nodes[row.nodeID])
	end
	if summary.total > 0 and summary.learned == summary.total then return 'Plan complete' end
	for _, row in ipairs(rows) do
		if row.state == 'upcoming' or row.state == 'pending' then
			return ('Next: %s'):format(TP.StepLabel(row, nodes[row.nodeID]))
		end
	end
	return 'No plan'
end

------------------------------------------------------------------ small parts

local function Muted() return st:Color('text', 'muted'):GetRGB() end

local function ShowTip(owner, text)
	GameTooltip:SetOwner(owner, 'ANCHOR_TOPRIGHT')
	GameTooltip:SetText(text, 1, 1, 1, 1, true)
	GameTooltip:Show()
end

local function HideTip(owner)
	if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

local function Dialogs() return st.OptionsWidgets end

-- The strip's collapse arrow: a 16 square button with its glyph in the states'
-- hands, like the tracker's chevrons.
local function NewArrow(parent)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(ICON, ICON)
	local icon = button:CreateTexture(nil, 'OVERLAY')
	icon:SetSize(ICON, ICON)
	icon:SetPoint('CENTER')
	button.icon = icon
	button:SetScript('OnClick', function() TP:SetCollapsed(not S.Char().collapsed) end)
	button:SetScript('OnEnter', function(self)
		ShowTip(self, S.Char().collapsed and 'Expand' or 'Collapse')
	end)
	button:SetScript('OnLeave', function(self) HideTip(self) end)
	-- after the SetScripts: the helper hooks the scripts as they are now
	st:AddStates(button, 'glyph', { glyph = icon, glyphRest = Muted })
	st:PaintStates(button)
	return button
end

local function RowTip(row)
	if row.state == 'missing' then
		return "This talent isn't in your class's tree any more. Right-click to delete the step."
	end
	if row.waiting and row.block then return row.block end
	if row.state == 'pending' then return 'Staged. Press Apply in the talent window to learn it.' end
end

local function NewRow(content, index)
	local row = CreateFrame('Button', nil, content)
	row:SetHeight(L.ROW_HEIGHT)
	local y = -(index - 1) * L.ROW_HEIGHT
	row:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, y)
	row:SetPoint('TOPRIGHT', content, 'TOPRIGHT', 0, y)
	row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

	row.level = st:CreateFontString(row, 'normal')
	row.level:SetPoint('LEFT', row, 'LEFT', PAD, 0)
	row.icon = row:CreateTexture(nil, 'ARTWORK')
	row.icon:SetSize(ICON, ICON)
	row.icon:SetPoint('LEFT', row.level, 'RIGHT', PAD, 0)
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	row.check = row:CreateTexture(nil, 'OVERLAY')
	row.check:SetTexture(CHECK_ART)
	row.check:SetSize(CHECK, CHECK)
	row.check:SetPoint('RIGHT', row, 'RIGHT', -PAD, 0)
	row.tag = st:CreateFontString(row, 'normal')
	row.tag:SetJustifyH('RIGHT')
	row.name = st:CreateFontString(row, 'normal')
	row.name:SetJustifyH('LEFT')
	row.name:SetWordWrap(false)
	row.name:SetPoint('LEFT', row.icon, 'RIGHT', PAD, 0)
	row.name:SetPoint('RIGHT', row.tag, 'LEFT', -PAD, 0)

	row:SetScript('OnClick', function(self, button)
		if button == 'RightButton' then
			TP:OpenRowMenu(self)
		elseif TP.selected == self.index then
			TP:Select(nil)
		else
			TP:Select(self.index)
		end
	end)
	row:SetScript('OnEnter', function(self)
		TP:Light(self.nodeID)
		local tip = RowTip(self)
		if tip then ShowTip(self, tip) end
	end)
	row:SetScript('OnLeave', function(self)
		TP:Light(nil)
		HideTip(self)
	end)
	-- after the SetScripts: the helper hooks the scripts as they are now
	st:AddStates(row, 'row')
	return row
end

-- One step in a row: the level, the icon, the name, and on the right the rank
-- or the state's tag, or a check once learned.
local function FillRow(row, step, node)
	row.index, row.state, row.nodeID, row.block, row.waiting = step.index, step.state, step.nodeID, step.block, step.waiting
	row.level:SetText(('%2d'):format(step.level))
	st:SetState(row, 'selected', step.waiting and true or false)
	row.check:SetShown(step.state == 'learned')
	row.tag:ClearAllPoints()
	if step.state == 'learned' then
		row.tag:SetPoint('RIGHT', row.check, 'LEFT', -2, 0)
	else
		row.tag:SetPoint('RIGHT', row, 'RIGHT', -PAD, 0)
	end
	local tag = ''
	if not node then
		row.icon:SetTexture(nil)
		row.name:SetText(TP.StepLabel(step, nil))
	else
		row.icon:SetTexture(node.icon)
		row.name:SetText(node.name)
		if step.state == 'pending' then
			tag = 'pending'
		elseif step.waiting and step.block then
			tag = 'blocked'
		elseif node.maxRanks > 1 then
			tag = ('R%d'):format(step.rank)
		end
	end
	row.tag:SetText(tag)
end

------------------------------------------------------------------ building

function TP:BuildPanel()
	if self.panel then return self.panel end
	local talents = self:TalentsFrame()
	local config = st.config.profile
	local panel = st:CreateFrame('Frame', 'SaftUI_TalentPlan', talents)
	panel:SetWidth(L.WIDTH)
	panel:SetClampedToScreen(true)
	st:SetBackdrop(panel, config.panels.theme, config.panels.background, 'window')
	panel.rows = {}
	self.panel = panel

	-- the title strip
	local title = st:CreateFrame('Frame', nil, panel)
	title:SetPoint('TOPLEFT')
	title:SetPoint('TOPRIGHT')
	title:SetHeight(config.headers.height)
	st:SetTemplate(title, 'theme', 'theme', 'header')
	panel.title = title

	panel.arrow = NewArrow(title)
	panel.arrow:SetPoint('LEFT', title, 'LEFT', PAD + 2, 0)
	panel.heading = st:CreateFontString(title, 'heading', 'Leveling plan')
	panel.heading:SetPoint('LEFT', panel.arrow, 'RIGHT', PAD, 0)
	panel.count = st:CreateFontString(title, 'pixel')
	panel.count:SetJustifyH('RIGHT')
	panel.count:SetPoint('RIGHT', title, 'RIGHT', -PAD - 2, 0)
	panel.select = st:CreateButton(nil, title, 'No plan', 'theme', 'theme', 'pixel')
	panel.select:SetHeight(config.headers.height - 8)
	panel.select:SetPoint('LEFT', panel.heading, 'RIGHT', PAD * 2, 0)
	panel.select:SetPoint('RIGHT', panel.count, 'LEFT', -PAD, 0)
	panel.select:SetScript('OnClick', function(self) TP:OpenPlanMenu(self) end)
	panel.strip = st:CreateFontString(title, 'normal')
	panel.strip:SetJustifyH('LEFT')
	panel.strip:SetWordWrap(false)
	panel.strip:SetPoint('LEFT', panel.arrow, 'RIGHT', PAD, 0)
	panel.strip:SetPoint('RIGHT', title, 'RIGHT', -PAD - 2, 0)
	panel.strip:Hide()

	panel.hint = st:CreateFontString(panel, 'pixel', "Click talents in the order you'll take them")
	panel.hint:SetJustifyH('LEFT')
	panel.hint:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', PAD + 2, -PAD)
	panel.hint:Hide()

	-- the footer and the line above it
	st:CreateFooter(panel)
	local footer = panel.footer
	local function FooterButton(text, anchor)
		local button = st:CreateButton(nil, footer, text, 'theme', 'theme', 'pixel')
		button:SetSize(56, config.headers.height - 8)
		if anchor then button:SetPoint('LEFT', anchor, 'RIGHT', PAD, 0) else button:SetPoint('LEFT', footer, 'LEFT', PAD, 0) end
		return button
	end
	panel.planButton = FooterButton('Plan')
	panel.importButton = FooterButton('Import', panel.planButton)
	panel.phasesButton = FooterButton('Phases', panel.importButton)
	panel.dots = st:CreateButton(nil, footer, nil, 'theme', 'theme')
	panel.dots:SetSize(24, config.headers.height - 8)
	panel.dots:SetPoint('RIGHT', footer, 'RIGHT', -PAD, 0)
	panel.dots.icon = panel.dots:CreateTexture(nil, 'OVERLAY')
	panel.dots.icon:SetTexture(st.icons.ellipsis)
	panel.dots.icon:SetSize(ICON, ICON)
	panel.dots.icon:SetPoint('CENTER')
	panel.planButton:SetScript('OnClick', function() TP:OnPlanButton() end)
	panel.importButton:SetScript('OnClick', function() TP:OpenImport() end)
	panel.dots:SetScript('OnClick', function(self) TP:OpenDotsMenu(self) end)

	panel.off = st:CreateFontString(panel, 'pixel')
	panel.off:SetJustifyH('LEFT')
	panel.off:SetPoint('BOTTOMLEFT', footer, 'TOPLEFT', PAD + 2, 2)
	panel.off:Hide()

	-- the rows
	local scroll = st:CreateScrollFrame(panel)
	panel.scroll = scroll
	panel.content = scroll.ScrollChild
	panel.contentWidth = L.WIDTH - PAD * 2 - st:ScrollBarRoom(scroll)

	panel.empty = st:CreateFontString(panel, 'normal',
		"No leveling plan for this spec tab. Import a guide's talent order, or press Plan and click talents in the order you'll take them.")
	panel.empty:SetJustifyH('LEFT')
	panel.empty:SetJustifyV('TOP')
	panel.empty:SetWordWrap(true)
	panel.empty:SetWidth(L.WIDTH - PAD * 4)
	panel.empty:Hide()

	-- the selected row's line: the place the new steps go
	panel.line = panel.content:CreateTexture(nil, 'OVERLAY')
	panel.line:SetHeight(2)
	panel.line:Hide()

	return panel
end

------------------------------------------------------------------ docking

-- Takes the side of the window with more room and hangs the panel there. The
-- window's rect in UIParent's units, read only.
function TP:Dock()
	local panel, window = self.panel, _G.PlayerSpellsFrame
	if not panel or not window then return end
	local left, right = window:GetLeft(), window:GetRight()
	if not (left and right) then return end
	local k = window:GetEffectiveScale() / UIParent:GetEffectiveScale()
	self.side = L.Side(left * k, right * k, UIParent:GetWidth(), L.WIDTH)
	self:Place()
end

function TP:IsCollapsed()
	return S.Char().collapsed and true or false
end

-- The panel's two anchor points (one, and the title's height, while collapsed)
-- and the arrow that faces the way the panel would move.
function TP:Place()
	local panel, window = self.panel, _G.PlayerSpellsFrame
	local right = (self.side or 'RIGHT') == 'RIGHT'
	local x = right and L.GAP or -L.GAP
	local top, bottom, near = right and 'TOPLEFT' or 'TOPRIGHT', right and 'BOTTOMLEFT' or 'BOTTOMRIGHT', right and 'TOPRIGHT' or 'TOPLEFT'
	panel:ClearAllPoints()
	panel:SetPoint(top, window, near, x, 0)
	if self:IsCollapsed() then
		panel:SetHeight(st.config.profile.headers.height)
	else
		panel:SetPoint(bottom, window, right and 'BOTTOMRIGHT' or 'BOTTOMLEFT', x, 0)
	end
	local points = right == not self:IsCollapsed()
	panel.arrow.icon:SetTexture(points and st.icons.chevronRight or st.icons.chevronLeft)
end

------------------------------------------------------------------ drawing

-- The title and the body, in the collapsed or the open layout.
function TP:ApplyCollapsed()
	local panel = self.panel
	local collapsed = self:IsCollapsed()
	for _, part in ipairs({ panel.heading, panel.select, panel.count }) do part:SetShown(not collapsed) end
	panel.strip:SetShown(collapsed)
	panel.footer:SetShown(not collapsed)
	panel.scroll:SetShown(not collapsed)
	if collapsed then
		panel.off:Hide()
		panel.hint:Hide()
		panel.empty:Hide()
		panel.line:Hide()
	end
	if self.view then panel.strip:SetText(TP.StripText(self.view)) end
	if self.side then self:Place() end
end

function TP:SetCollapsed(on)
	S.Char().collapsed = on and true or false
	if self.panel then
		self:ApplyCollapsed()
		if not on then self:Refresh() end
	end
end

local function Row(panel, index)
	local entry = panel.rows[index]
	if not entry then
		entry = { frame = NewRow(panel.content, index), kind = 'step', index = index }
		panel.rows[index] = entry
	end
	return entry
end

-- Everything the view says. Colors are set last, by PaintColors.
function TP:DrawPanel(view)
	local panel, config = self.panel, st.config.profile
	local plan, rows = view.plan, view.rows
	if plan ~= self.selectedPlan then
		self.selected, self.selectedPlan = nil, plan
	end
	if self.selected and (not plan or self.selected > #plan.steps) then self.selected = nil end

	panel.title:SetHeight(config.headers.height)
	panel.select.text:SetText(plan and plan.name or 'No plan')
	panel.count:SetText(view.summary and ('%d/%d'):format(view.summary.learned, view.summary.total) or '')
	panel.strip:SetText(TP.StripText(view))

	local top = config.headers.height + PAD
	panel.hint:SetShown(self.planning and not self:IsCollapsed() and true or false)
	if self.planning then top = top + panel.hint:GetStringHeight() + PAD end
	panel.scroll:ClearAllPoints()
	panel.scroll:SetPoint('TOPLEFT', panel, 'TOPLEFT', PAD, -top)
	panel.scroll:SetPoint('BOTTOMRIGHT', panel, 'BOTTOMRIGHT', -(PAD + st:ScrollBarRoom(panel.scroll)), config.headers.height + OFF_LINE)
	panel.empty:ClearAllPoints()
	panel.empty:SetPoint('TOPLEFT', panel, 'TOPLEFT', PAD * 2, -top - PAD)

	local count = rows and #rows or 0
	for i = 1, count do
		local entry = Row(panel, i)
		FillRow(entry.frame, rows[i], view.tree.nodes[rows[i].nodeID])
		entry.frame:Show()
	end
	for i = count + 1, #panel.rows do panel.rows[i].frame:Hide() end
	panel.scroll:SetContentSize(panel.contentWidth, math.max(1, count * L.ROW_HEIGHT))
	panel.empty:SetShown(not plan and not self:IsCollapsed())

	local off = plan and M.OffPlan(plan, view.tree.nodes) or 0
	panel.off:SetText(off == 1 and '1 point off plan' or ('%d points off plan'):format(off))
	panel.off:SetShown(off > 0 and not self:IsCollapsed())

	self:PlaceSelection()
	self:ApplyCollapsed()
	self:PaintColors()
end

function TP:PlaceSelection()
	local panel = self.panel
	local entry = self.selected and panel.rows[self.selected]
	if not entry or self:IsCollapsed() then
		panel.line:Hide()
		return
	end
	panel.line:ClearAllPoints()
	panel.line:SetPoint('BOTTOMLEFT', entry.frame, 'BOTTOMLEFT', 0, -1)
	panel.line:SetPoint('BOTTOMRIGHT', entry.frame, 'BOTTOMRIGHT', 0, -1)
	panel.line:Show()
end

-- Muted, danger and accent texts and the selection's line, put back from the
-- colors page (a draw runs it last; OnColorsChanged runs it alone).
function TP:PaintColors()
	local panel = self.panel
	if not panel then return end
	local muted, danger, normal = st:Color('text', 'muted'), st:Color('text', 'danger'), st:Color('text', 'normal')
	for _, entry in ipairs(panel.rows) do
		local row = entry.frame
		local color = row.state == 'learned' and muted or row.state == 'missing' and danger or normal
		row.name:SetTextColor(color:GetRGB())
		row.level:SetTextColor((row.state == 'learned' and muted or normal):GetRGB())
		row.tag:SetTextColor(muted:GetRGB())
	end
	panel.count:SetTextColor(muted:GetRGB())
	panel.off:SetTextColor(muted:GetRGB())
	panel.hint:SetTextColor(muted:GetRGB())
	panel.empty:SetTextColor(muted:GetRGB())
	panel.strip:SetTextColor(normal:GetRGB())
	panel.line:SetColorTexture(st:Color('accent'):GetRGB())
	panel.arrow.icon:SetVertexColor(muted:GetRGB())
end

function TP:OnColorsChanged(group)
	if group == 'text' or group == 'accent' or group == 'theme' then
		self:PaintColors()
		self:PaintOverlays()
	end
end

function TP:ScrollToWaiting()
	local view, scroll = self.view, self.panel and self.panel.scroll
	if not (view and scroll and view.summary and view.summary.waiting) then return end
	scroll:SetVerticalScroll(L.ScrollOffset(view.summary.waiting, L.ROW_HEIGHT, scroll:GetHeight(), #view.rows * L.ROW_HEIGHT))
end

------------------------------------------------------------------ actions

-- A click on a row: the step the new steps go after, or none.
function TP:Select(index)
	self.selected = index
	self:PlaceSelection()
end

function TP:RemoveStep(index)
	local plan = self.view and self.view.plan
	if not plan then return end
	M.RemoveStep(plan, index)
	if self.selected == index then
		self.selected = nil
	elseif self.selected and self.selected > index then
		self.selected = self.selected - 1
	end
	self:Refresh()
end

function TP:OpenRowMenu(row)
	if not MenuUtil then return end
	local index = row.index
	MenuUtil.CreateContextMenu(row, function(owner, root)
		root:CreateButton('Remove step', function() TP:RemoveStep(index) end)
	end)
end

function TP:OpenPlanMenu(button)
	if not MenuUtil then return end
	local group = self:ViewedGroup()
	MenuUtil.CreateContextMenu(button, function(owner, root)
		local active = S.Active(group)
		for _, plan in ipairs(S.List()) do
			root:CreateRadio(plan.name, function() return plan == active end, function()
				S.SetActive(group, plan.id)
				TP:Refresh()
			end)
		end
		root:CreateDivider()
		root:CreateButton('New plan', function()
			S.New('New plan', group)
			TP:Refresh()
		end)
	end)
end

function TP:OpenDotsMenu(button)
	local plan = self.view and self.view.plan
	if not (MenuUtil and plan) then return end
	local group = self:ViewedGroup()
	MenuUtil.CreateContextMenu(button, function(owner, root)
		root:CreateButton('Rename', function()
			Dialogs().Prompt('Rename the plan', plan.name, function(text)
				local ok, why = S.Rename(plan, text)
				if not ok then
					st:Print(why == 'empty' and 'A plan needs a name.' or 'There is already a plan with that name.')
				end
				TP:Refresh()
			end, { accept = 'Rename', cancel = 'Cancel' })
		end)
		root:CreateButton('Duplicate', function()
			S.Duplicate(plan, group)
			TP:Refresh()
		end)
		root:CreateButton('Delete plan', function()
			Dialogs().Confirm(('Delete the plan "%s"? This can\'t be undone.'):format(plan.name), function()
				S.Delete(plan)
				TP:Refresh()
			end)
		end)
		root:CreateButton('Clear steps', function()
			Dialogs().Confirm(('Clear every step of "%s"?'):format(plan.name), function()
				plan.steps, plan.phases = {}, {}
				TP:Refresh()
			end)
		end)
	end)
end

-- Plan: planning mode on or off (the first planning click makes a plan when
-- the tab has none).
function TP:OnPlanButton()
	self:SetPlanning(not self.planning)
end

function TP:PaintPlanButton()
	if self.panel then st:SetButtonPressed(self.panel.planButton, self.planning) end
end
