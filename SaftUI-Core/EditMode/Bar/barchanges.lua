local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody
local History = EM.History

--[[
	The edit mode bar's changes group (bar.lua) and its status line:
	  changes (right, 80, section 'changes')  Undo, Redo, History, Reset
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
	'Redid: <label>', 'Went back to: <label>' or 'Reverted: <label>', or the
	refusal's message (a step that couldn't be written is put back and the
	buttons' states don't change). When the step's mover isn't showing (the
	filter, Show disabled and Show hidden) or its outline is off the screen,
	' Its mover is hidden by Show or the filter.' follows. The selection never
	changes. Each returns ok and the text posted.

	The status line, EM:SetBarStatus(text): one line of small, Text > Grey text
	in the bar's flexible gap, right-aligned STATUS_GAP short of the first right
	group's divider (EM:BarGap), cut to the room. It takes no mouse. It clears
	after EM.STATUS_SECONDS, when a new status replaces it (each with its own
	clock) and when edit mode turns off.
]]

local floor, ceil, min = math.floor, math.ceil, math.min

EM.STATUS_SECONDS = 6
EM.HISTORY_START = 'Before these changes' -- the History list's last row, and what going back to it is called
local STATUS_GAP = 12 -- the text's right end this far short of the divider
local ICON = 26
local HIDDEN = ' Its mover is hidden by Show or the filter.'

local Guard = EM.BarGuard

------------------------------------------------------------------ the status line

local statusToken = 0 -- each status has its own clock: only the newest clears

local function ClearStatus()
	local text = EM.statusText
	if text then
		text:SetText('')
		text:Hide()
	end
end

-- Puts the text in the gap: right-aligned, as wide as it is (a whole number)
-- or the room if that is less, from its top left on whole pixels.
local function PlaceStatus()
	local text = EM.statusText
	if not text then return end
	local message = text:GetText() or ''
	local left, right = EM:BarGap()
	local room = right - STATUS_GAP - left
	if message == '' or room <= 0 then
		text:Hide()
		return
	end
	local full = text.GetUnboundedStringWidth and text:GetUnboundedStringWidth() or text:GetStringWidth()
	local width = min(ceil(full), room)
	text:SetWidth(width)
	local height = ceil(text:GetStringHeight())
	text:SetHeight(height)
	text:ClearAllPoints()
	text:SetPoint('TOPLEFT', EM:GetBar(), 'TOPLEFT', right - STATUS_GAP - width, -floor((EM.BAR.HEIGHT - height) / 2))
	text:Show()
end

local function StatusText()
	if EM.statusText then return EM.statusText end
	local text = OB.Text(EM:GetBar(), 'small', 'RIGHT')
	text:SetTextColor(OB.Grey())
	text:Hide()
	EM.statusText = text
	return text
end

-- Says text in the bar's status line; nil or '' clears it.
function EM:SetBarStatus(message)
	statusToken = statusToken + 1
	if message == nil or message == '' then
		ClearStatus()
		return
	end
	StatusText():SetText(message)
	PlaceStatus()
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
EM:On('ColorsChanged', function()
	if EM.statusText then EM.statusText:SetTextColor(OB.Grey()) end
end)

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

-- Runs call, then posts verb and the step's label (read before: the call can
-- drop the step), or the refusal's message. A message with a success is a
-- skipped part ("<name> isn't there now; skipped.") and goes on the end.
local function Run(call, verb, step, label)
	local target = step and step.target
	if step and label == nil then label = History.Label(step) end
	local ok, message = call()
	local text
	if ok then
		text = verb .. ': ' .. tostring(label)
		if message then text = text .. ' ' .. message end
		if MoverHidden(target) then text = text .. HIDDEN end
	else
		text = message or "Couldn't do that."
	end
	EM:SetBarStatus(text)
	return ok, text
end

function EM:UndoStep()
	return Run(function() return History:Undo() end, 'Undid', History:Steps()[History:Position()])
end

function EM:RedoStep()
	return Run(function() return History:Redo() end, 'Redid', History:Steps()[History:Position() + 1])
end

-- Goes to just after step n (0: before every step). The current point is left
-- alone, silently.
function EM:JumpToStep(n)
	if n == History:Position() then return true end
	local step = History:Steps()[n]
	return Run(function() return History:JumpTo(n) end, 'Went back to', step, step == nil and EM.HISTORY_START or nil)
end

function EM:RevertStep(i)
	return Run(function() return History:Revert(i) end, 'Reverted', History:Steps()[i])
end

------------------------------------------------------------------ the controls

-- The name of the mover a step moved, or nil.
local function StepMover(step)
	local mover = step.target and EM.movers[step.target]
	return mover and EM.MoverName(mover) or nil
end

local function Retip(button)
	if GameTooltip:IsOwned(button) then
		local title, lines = button.tip(button)
		W.ShowTip(button, title, lines)
	end
end

local function Undo(bar)
	local button = W.IconButton(bar, st.icons.undo2, function()
		if not History:CanUndo() then return 'Undo', { { text = 'Nothing to undo.', red = true } } end
		local step = History:Steps()[History:Position()]
		local name = StepMover(step)
		return 'Undo', { name and ('Puts %s back where it was before.'):format(name)
			or ('Undoes %s.'):format(tostring(History.Label(step))) }
	end)
	button.onClick = Guard(function() EM:UndoStep() end)
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
		if not History:CanRedo() then return 'Redo', { { text = 'Nothing to redo.', red = true } } end
		local step = History:Steps()[History:Position() + 1]
		local name = StepMover(step)
		return 'Redo', { name and ('Moves %s again.'):format(name)
			or ('Redoes %s.'):format(tostring(History.Label(step))) }
	end)
	button.onClick = Guard(function() EM:RedoStep() end)
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
		if not ok then return 'Reset', { { text = why, red = true } } end
		return 'Reset', { ('%s goes back to its default place.'):format(EM.MoverName(mover)) }
	end)
	button.onClick = Guard(function()
		local _, message = EM:Reset(EM.selected)
		EM:SetBarStatus(message)
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
	key = 'changes', order = 80, side = 'right', section = 'changes',
	controls = function(bar) return { Undo(bar), Redo(bar), HistoryButton(bar), Reset(bar) } end,
})
