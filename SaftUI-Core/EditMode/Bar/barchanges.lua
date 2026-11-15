local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody
local History = EM.History

--[[
	The edit mode bar's changes group (bar.lua) and its status line:
	  changes (right, 80, row 1, section 'changes')  Undo, Redo, History, Reset
	Icon buttons (bargroups.lua's, EM.BarGuard on every click, so nothing in
	combat). Each tells why when it can't act, in red under its title, and each
	refreshes on HistoryChanged, Selected and PositionChanged:
	  undo     on while History:CanUndo(): "Puts <name> back where it was
	           before." for a step with a mover, else "Undoes <label>."
	  redo     "Moves <name> again." or "Redoes <label>."
	  history  on while the History list (historylist.lua) is open
	  reset    EM:CanReset(EM.selected) says whether it works and why not

	EM:UndoStep(), EM:RedoStep(), EM:JumpToStep(n) and EM:RevertStep(i) run the
	history's call and say what happened in the status line: 'Undid: <label>',
	'Redid: <label>', 'Went back to: <label>' ('Went to:' for a jump forward) or 'Reverted: <label>', or the
	refusal's message (a step that couldn't be written is put back and the
	buttons' states don't change). When the step's mover isn't showing (the
	filter, Show disabled and Show hidden) or its outline is off the screen,
	' Its mover is hidden by Show or the filter.' follows. The selection never
	changes. Each returns ok and the text posted.

	The status line, EM:SetBarStatus(message, owner, refusal). The docked bar is
	two rows with no spare width, so it has no line: the message is the tooltip
	under owner, the control that was pressed (under the bar when none is given;
	Text > Danger for a refusal), and EM.statusCut says so. In the floating window
	(barwindow.lua) it is a line of small, Text > Muted text under the Changes
	section instead, from the left and wrapped to the window's inside width,
	never cut. It takes no mouse. It clears after EM.STATUS_SECONDS, when a new
	status replaces it (each with its own clock) and when edit mode turns off.
]]

local min, max = math.min, math.max

EM.STATUS_SECONDS = 6
EM.HISTORY_START = 'Before these changes' -- the History list's last row, and what going back to it is called
local ICON = 26
local HIDDEN = ' Its mover is hidden by Show or the filter.' -- after a full stop

local Guard = EM.BarGuard

------------------------------------------------------------------ the status line

local statusToken = 0 -- each status has its own clock: only the newest clears

-- Whether the status tooltip (see EM:SetBarStatus) is showing. It is owned by
-- the bar, not by the control it is under, so no control's OnLeave or Retip
-- touches it: only its clock, a new status, Disabled and combat end it.
local statusTipShown = false
function EM:IsStatusTipShown() return statusTipShown and GameTooltip:IsShown() and GameTooltip:IsOwned(EM.bar) end

local function ClearStatus()
	local text = EM.statusText
	if text then
		text:SetText('')
		text:Hide()
	end
	if statusTipShown then
		W.HideTip(EM.bar)
		statusTipShown = false
	end
	EM.statusCut = false
	if EM:IsBarFloating() and EM.barWindow then EM:PlaceWindowStatus(nil) end
end

-- Puts the text where it shows: in the floating window under the Changes
-- section; on the docked bar nowhere (a tooltip shows the message, see
-- EM:SetBarStatus).
local function PlaceStatus()
	local text = EM.statusText
	if not text then return end
	local message = text:GetText() or ''
	-- In the floating window it is under the Changes section, wrapped to the
	-- window's inside width, so never cut (barwindow.lua).
	if EM:IsBarFloating() then
		EM.statusCut = false
		if message == '' then
			text:Hide()
			EM:PlaceWindowStatus(nil)
		else
			EM:PlaceWindowStatus(text)
		end
		return
	end
	text:Hide()
	EM.statusCut = message ~= ''
end

local function StatusText()
	if EM.statusText then return EM.statusText end
	local text = OB.Text(EM:GetBar(), 'small', 'RIGHT')
	text:SetTextColor(OB.Muted())
	text:Hide()
	EM.statusText = text
	return text
end

-- Says text in the bar's status line; nil or '' clears it. On the docked bar,
-- which has no line, the message is the GameTooltip owned by the bar (so no
-- control's OnLeave takes it), under owner, the control that was pressed (under
-- the bar with none), for EM.STATUS_SECONDS whatever the mouse does (Text > Danger for a
-- refusal), never in combat; EM.statusCut says the bar has no line for it.
function EM:SetBarStatus(message, owner, refusal)
	statusToken = statusToken + 1
	if message == nil or message == '' then
		ClearStatus()
		return
	end
	if statusTipShown then
		W.HideTip(EM.bar)
		statusTipShown = false
	end
	StatusText():SetText(message)
	PlaceStatus()
	local under = owner or (EM.bar and EM.bar:IsShown() and EM.bar) or nil
	if EM.statusCut and under and not InCombatLockdown() then
		GameTooltip:SetOwner(EM.bar, 'ANCHOR_NONE')
		GameTooltip:ClearLines()
		GameTooltip:AddLine(refusal and "It didn't work" or 'Done', 1, 1, 1)
		local r, g, b = st:Color('text', refusal and 'danger' or 'normal'):GetRGB()
		GameTooltip:AddLine(message, r, g, b, true)
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint('TOP', under, 'BOTTOM', 0, -4)
		GameTooltip:Show()
		statusTipShown = true
	end
	local mine = statusToken
	C_Timer.After(EM.STATUS_SECONDS, function()
		if mine == statusToken then ClearStatus() end
	end)
end

EM:On('BarLaid', PlaceStatus)
EM:On('Disabled', function()
	statusToken = statusToken + 1
	ClearStatus()
end)
local function ColorStatus()
	if EM.statusText then EM.statusText:SetTextColor(OB.Muted()) end
end
EM:On('ColorsChanged', function(group, key)
	if group == 'text' and (key == nil or key == 'muted') then ColorStatus() end
end)
EM:On('Enabled', ColorStatus) -- a pass is not passed on while edit mode is off

------------------------------------------------------------------ the steps

-- Whether the mover of key is not showing, or its outline is wholly off the
-- screen: the player can't see what moved.
local function MoverHidden(key)
	local mover = key ~= nil and EM.movers[key] or nil
	if not mover then return false end
	if not mover.overlay:IsShown() then return true end
	local l, r, b, t = EM.GetOutlineRect(mover)
	if not l then return false end
	return r <= 0 or l >= UIParent:GetWidth() or t <= 0 or b >= UIParent:GetHeight()
end

-- text with the note that a mover is hidden, after a full stop.
local function Hidden(text)
	if text:sub(-1) ~= '.' then text = text .. '.' end
	return text .. HIDDEN
end

-- Runs call, then posts verb and the step's label (read before: the call can
-- drop the step), or the refusal's message. A message with a success is a
-- skipped part ("<name> isn't there now; skipped.") and goes on the end.
local function Run(call, verb, step, label, owner)
	local target = step and step.target
	if step and label == nil then label = History.Label(step) end
	local ok, message = call()
	local text
	if ok then
		text = verb .. ': ' .. tostring(label)
		if message then text = text .. ' ' .. message end
		if MoverHidden(target) then text = Hidden(text) end
	else
		text = message or "Couldn't do that."
	end
	EM:SetBarStatus(text, owner, not ok)
	return ok, text
end

-- Each takes the control that was pressed, optionally: a message too long for
-- the status line is shown under it.
function EM:UndoStep(owner)
	return Run(function() return History:Undo() end, 'Undid', History:Steps()[History:Position()], nil, owner)
end

function EM:RedoStep(owner)
	return Run(function() return History:Redo() end, 'Redid', History:Steps()[History:Position() + 1], nil, owner)
end

-- The label of the point after step i (0: the start).
local function PointLabel(step)
	if step then return tostring(History.Label(step)) end
	return EM.HISTORY_START
end

-- Goes to just after step n (0: before every step). The current point is left
-- alone, silently. The note about a hidden mover is about the steps the jump
-- actually walked (read before, as the call can drop them), and a jump that
-- stops part way says so and where, with the refusal.
function EM:JumpToStep(n, owner)
	local steps, from = History:Steps(), History:Position()
	if n == from then return true end
	local walked = {}
	if type(n) == 'number' and n >= 0 and n <= #steps then
		for i = min(from, n) + 1, max(from, n) do walked[#walked + 1] = steps[i] end
	end
	local point = steps[n]
	local ok, message = History:JumpTo(n)
	local text
	local now = History:Position()
	local hidden = false
	for _, step in ipairs(walked) do
		if step.target and MoverHidden(step.target) then hidden = true end
	end
	if ok then
		text = (n > from and 'Went to: ' or 'Went back to: ') .. PointLabel(point)
	elseif now ~= from then
		text = 'Went back part way, to ' .. PointLabel(History:Steps()[now]) .. ': ' .. (message or "couldn't go on.")
	else
		text = message or "Couldn't do that."
	end
	if hidden and (ok or now ~= from) then text = Hidden(text) end
	EM:SetBarStatus(text, owner, not ok)
	return ok, text
end

function EM:RevertStep(i, owner)
	return Run(function() return History:Revert(i) end, 'Reverted', History:Steps()[i], nil, owner)
end

------------------------------------------------------------------ the controls

-- The name of the mover a step moved, or nil.
local function StepMover(step)
	local mover = step.target and EM.movers[step.target]
	return mover and EM.MoverName(mover) or nil
end

local function Retip(button)
	if GameTooltip:IsShown() and GameTooltip:IsOwned(button) then
		local title, lines = button.tip(button)
		W.ShowTip(button, title, lines)
	end
end

local function Undo(bar)
	local button = W.IconButton(bar, st.icons.undo2, function()
		if not History:CanUndo() then return 'Undo', { { text = 'Nothing to undo.', danger = true } } end
		local step = History:Steps()[History:Position()]
		local name = StepMover(step)
		return 'Undo', { name and ('Puts %s back where it was before.'):format(name)
			or ('Undoes %s.'):format(tostring(History.Label(step))) }
	end)
	button.onClick = Guard(function(self) EM:UndoStep(self) end)
	return {
		key = 'undo', frame = button,
		Lay = function() return ICON end,
		Refresh = function()
			W.SetEnabled(button, History:CanUndo())
			Retip(button)
		end,
	}
end

local function Redo(bar)
	local button = W.IconButton(bar, st.icons.redo2, function()
		if not History:CanRedo() then return 'Redo', { { text = 'Nothing to redo.', danger = true } } end
		local step = History:Steps()[History:Position() + 1]
		local name = StepMover(step)
		return 'Redo', { name and ('Moves %s again.'):format(name)
			or ('Redoes %s.'):format(tostring(History.Label(step))) }
	end)
	button.onClick = Guard(function(self) EM:RedoStep(self) end)
	return {
		key = 'redo', frame = button,
		Lay = function() return ICON end,
		Refresh = function()
			W.SetEnabled(button, History:CanRedo())
			Retip(button)
		end,
	}
end

local function HistoryButton(bar)
	local button = W.IconButton(bar, st.icons.history, function()
		return 'History', { 'Lists your changes, newest first: go back to any of them, or revert one on its own.' }
	end)
	button.onClick = Guard(function() EM:ToggleHistoryList() end)
	return {
		key = 'history', frame = button,
		Lay = function() return ICON end,
		Refresh = function() W.SetOn(button, EM:IsHistoryListShown()) end,
	}
end

local function Reset(bar)
	local button = W.IconButton(bar, st.icons.rotateCcw, function()
		local mover = EM.selected
		local ok, why = EM:CanReset(mover)
		if not ok then return 'Reset', { { text = why, danger = true } } end
		return 'Reset', { ('%s goes back to its default place.'):format(EM.MoverName(mover)) }
	end)
	button.onClick = Guard(function(self)
		local ok, message = EM:Reset(EM.selected)
		EM:SetBarStatus(message, self, not ok)
	end)
	return {
		key = 'reset', frame = button,
		Lay = function() return ICON end,
		Refresh = function()
			W.SetEnabled(button, (EM:CanReset(EM.selected)))
			Retip(button)
		end,
	}
end

local KEYS = { 'undo', 'redo', 'history', 'reset' }

local function RefreshChanges()
	for _, key in ipairs(KEYS) do
		local control = EM:BarControl(key)
		if control then control:Refresh() end
	end
end

for _, event in ipairs({ 'HistoryChanged', 'Selected', 'PositionChanged' }) do EM:On(event, RefreshChanges) end

------------------------------------------------------------------ the group

EM:AddBarGroup({
	key = 'changes', order = 80, side = 'right', row = 1, section = 'changes',
	dockKeys = { 'undo', 'redo', 'reset', 'history' }, -- the mockup's order; the floating window keeps undo, redo, history, reset,
	controls = function(bar) return { Undo(bar), Redo(bar), HistoryButton(bar), Reset(bar) } end,
})
