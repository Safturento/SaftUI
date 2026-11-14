local st = SaftUI
local EM = st.EditModeFrames

-- The history of what edit mode and its bulk actions change: the store behind
-- the bar's Undo, Redo, Reset and History (EM.History). It knows nothing of
-- positions: each kind of thing a step changes is a handler (RegisterKind) that
-- reads, writes and compares it, and moves.lua registers edit mode's own, the
-- 'position' kind. A later part adds a kind for /sui's settings the same way.
--
-- A step is one action: { kind = 'move' | 'nudge' | 'reset' | 'bulk' | 'revert',
-- label = string | function(step) -> string, time, target = <mover key> | nil,
-- changes = { { kind = <handler name>, where, old, new }, ... }, open, last }.
-- Steps are kept oldest first; steps 1 to Position() are applied, the rest can
-- be redone until a new step is pushed (no branching).
--
-- The rule that groups nudges into one step lives in History.Merges and
-- History.MERGE_GAP, here and nowhere else.

local History = {}
EM.History = History

History.MERGE_GAP = 1 -- seconds: a nudge within this of the run's last joins the run
History.LIMIT_MIN, History.LIMIT_MAX = 1, 1000
History.limit = 50

local TOLERANCE = 1e-4 -- numbers closer than this are one number

local steps = {}
local position = 0
local handlers = {}
local watching -- the config object whose profile callbacks we listen to

-- The game's clock, through one place so tests can drive it.
local function Now() return GetTime() end

------------------------------------------------------------------ equality

-- Deep equality. A number and a string of the same number are equal (within
-- 1e-4: the profile stores some offsets as strings), nil equals only nil.
function History.Same(a, b)
	if a == nil or b == nil then return a == b end
	local ta, tb = type(a), type(b)
	if ta == 'table' and tb == 'table' then
		for k, v in pairs(a) do
			if not History.Same(v, b[k]) then return false end
		end
		for k in pairs(b) do
			if a[k] == nil then return false end
		end
		return true
	end
	if (ta == 'number' or ta == 'string') and (tb == 'number' or tb == 'string') then
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then return math.abs(na - nb) <= TOLERANCE end
	end
	return a == b
end

------------------------------------------------------------------- kinds

-- handler = { read(where) -> value, write(where, value), finish(wheres)?,
-- same(a, b)?, place(where)?, check(where, value) -> ok, why ?, name(where),
-- missing(where) -> boolean ? }. read gives a copy of what is stored now; write
-- stores a copy, through the setter a player's change uses; finish runs once
-- after a step's writes with the wheres of this kind; missing says the thing
-- is gone (a module turned off): its part of a step is skipped and reported.
function History:RegisterKind(name, handler)
	handlers[name] = handler
end

local function Handler(kind)
	return assert(handlers[kind], 'History: no kind ' .. tostring(kind))
end

local function Same(change, a, b)
	return (Handler(change.kind).same or History.Same)(a, b)
end

local function PlaceOf(change)
	local h = Handler(change.kind)
	if h.place then return h.place(change.where) end
	return change.kind .. ':' .. tostring(change.where)
end

local function NameOf(change)
	return Handler(change.kind).name(change.where)
end

local function Missing(change)
	local missing = Handler(change.kind).missing
	return missing ~= nil and missing(change.where) == true
end

-- The places a step touches, as { [place] = true }.
function History.Places(step)
	local places = {}
	for _, change in ipairs(step.changes) do places[PlaceOf(change)] = true end
	return places
end

local function Touches(step, places)
	for _, change in ipairs(step.changes) do
		if places[PlaceOf(change)] then return true end
	end
	return false
end

function History.Label(step)
	local label = step.label
	if type(label) == 'function' then return label(step) end
	return label
end

------------------------------------------------------------------ reading

function History:Steps() return steps end
function History:Position() return position end
function History:CanUndo() return position > 0 end
function History:CanRedo() return position < #steps end

-- The grouping rule, the one place it lives: the top step is an open run of
-- nudges, the new step is a nudge of the same mover, nothing has been undone,
-- and the new nudge comes within MERGE_GAP of the run's last.
function History.Merges(top, step, now)
	return top ~= nil
		and top.open == true
		and top.kind == 'nudge' and step.kind == 'nudge'
		and top.target == step.target
		and position == #steps
		and now - top.last <= History.MERGE_GAP
end

function History:CloseRun()
	local top = steps[#steps]
	if top then top.open = nil end
end

----------------------------------------------------------------- changing

local function Changed() EM:Fire('HistoryChanged') end

-- Drops the oldest steps past the limit. True when it dropped any.
local function Trim()
	local extra = #steps - History.limit
	if extra <= 0 then return false end
	for _ = 1, extra do table.remove(steps, 1) end
	position = math.max(position - extra, 0)
	return true
end

-- The limit, a whole number from LIMIT_MIN to LIMIT_MAX. Lowering it drops the
-- oldest steps at once.
function History:SetLimit(n)
	n = tonumber(n) or History.limit
	n = math.floor(n + 0.5)
	History.limit = math.min(math.max(n, History.LIMIT_MIN), History.LIMIT_MAX)
	if Trim() then Changed() end
end

function History:Clear()
	steps = {}
	position = 0
	Changed()
end

-- The profile is another set of movers and settings: a step of the old one
-- must never be applied to the new one. Listens to AceDB's own callbacks where
-- the config has them (the shell's plain profile has none).
local function Watch()
	local config = st.config
	if watching == config then return end
	watching = config
	if type(config) ~= 'table' or type(config.RegisterCallback) ~= 'function' then return end
	local function clear() History:Clear() end
	for _, event in ipairs({ 'OnProfileChanged', 'OnProfileCopied', 'OnProfileReset' }) do
		config.RegisterCallback(History, event, clear)
	end
end

-- Records an action already made. Drops the changes with no net change and
-- records nothing when none is left. Joins the top step by History.Merges
-- (keeping the top's old, taking the step's new; a run that came back to its
-- start is removed), else appends it after discarding the redo steps. Returns
-- the step recorded or merged into, or nil.
function History:Push(step)
	Watch()
	local changes = {}
	for _, change in ipairs(step.changes) do
		if not Same(change, change.old, change.new) then changes[#changes + 1] = change end
	end
	if #changes == 0 then return nil end
	step.changes = changes
	local now = Now()
	step.time = step.time or now

	local top = steps[#steps]
	if History.Merges(top, step, now) then
		for _, change in ipairs(changes) do
			local found
			for _, have in ipairs(top.changes) do
				if have.kind == change.kind and have.where == change.where then found = have break end
			end
			if found then
				found.new = change.new
			else
				top.changes[#top.changes + 1] = change
			end
		end
		top.last = now
		-- Back to where the run began: no step.
		local net = {}
		for _, change in ipairs(top.changes) do
			if not Same(change, change.old, change.new) then net[#net + 1] = change end
		end
		top.changes = net
		if #net == 0 then
			steps[#steps] = nil
			position = #steps
			Changed()
			return nil
		end
		Changed()
		return top
	end

	for i = #steps, position + 1, -1 do steps[i] = nil end
	self:CloseRun()
	step.last = step.time
	step.open = step.kind == 'nudge' or nil
	steps[#steps + 1] = step
	position = #steps
	Trim()
	Changed()
	return step
end

------------------------------------------------------------ undo and redo

-- Writes each change's value (old or new, by direction) and runs each kind's
-- finish once, through xpcall. Changes whose thing is gone are skipped; their
-- names are returned.
local function WriteStep(step, undoing)
	local skipped = {}
	local count = #step.changes
	local byKind, order = {}, {}
	for n = 1, count do
		local change = step.changes[undoing and count - n + 1 or n]
		if Missing(change) then
			skipped[#skipped + 1] = NameOf(change)
		else
			Handler(change.kind).write(change.where, undoing and change.old or change.new)
			if not byKind[change.kind] then
				byKind[change.kind] = {}
				order[#order + 1] = change.kind
			end
			table.insert(byKind[change.kind], change.where)
		end
	end
	for _, kind in ipairs(order) do
		local finish = Handler(kind).finish
		if finish then xpcall(finish, geterrorhandler(), byKind[kind]) end
	end
	return skipped
end

-- Removes the steps at the given indices (a set); the position follows.
local function Drop(set)
	local kept, newPosition = {}, 0
	for i, step in ipairs(steps) do
		if not set[i] then
			kept[#kept + 1] = step
			if i <= position then newPosition = newPosition + 1 end
		end
	end
	steps = kept
	position = newPosition
end

-- The index set of step s and every older step that touches one of its places.
local function WithOlder(s)
	local set, places = { [s] = true }, History.Places(steps[s])
	for i = 1, s - 1 do
		if Touches(steps[i], places) then set[i] = true end
	end
	return set
end

-- The first change whose current value is not the one the step expects
-- (nothing is changed), or nil. A missing thing can't be read: it is skipped.
local function StaleChange(step, expectNew)
	for _, change in ipairs(step.changes) do
		if not Missing(change) then
			local now = Handler(change.kind).read(change.where)
			if not Same(change, now, expectNew and change.new or change.old) then return change end
		end
	end
end

-- The first refusal among the checks of the values it is about to write.
local function Refusal(step, writeNew)
	for _, change in ipairs(step.changes) do
		local check = Handler(change.kind).check
		if check and not Missing(change) then
			local ok, why = check(change.where, writeNew and change.new or change.old)
			if not ok then return why or (NameOf(change) .. ' can\'t be put back.') end
		end
	end
end

local function Skipped(skipped)
	if #skipped == 0 then return nil end
	return table.concat(skipped, ', ') .. " isn't there now; skipped."
end

local function Step(undoing)
	local verb = undoing and 'undo' or 'redo'
	if InCombatLockdown() then return false, "Can't " .. verb .. ' in combat.' end
	local s = undoing and position or position + 1
	local step = steps[s]
	if not step then return false, 'Nothing to ' .. verb .. '.' end
	History:CloseRun()
	-- What the step undoes is what it left (new); what it redoes is what it
	-- started from (old).
	local stale = StaleChange(step, undoing)
	if stale then
		local name = NameOf(stale)
		Drop(WithOlder(s))
		Changed()
		return false, name .. ' was changed since; its earlier steps are dropped.'
	end
	local why = Refusal(step, not undoing)
	if why then
		Drop({ [s] = true })
		Changed()
		return false, why
	end
	local skipped = WriteStep(step, undoing)
	position = undoing and position - 1 or position + 1
	Changed()
	return true, Skipped(skipped)
end

function History:Undo() return Step(true) end
function History:Redo() return Step(false) end

-- Undoes or redoes one step at a time until Position() is n (0 is before every
-- step). Stops at the first refusal.
function History:JumpTo(n)
	if type(n) ~= 'number' or n < 0 or n > #steps then return false, 'No such step.' end
	while position ~= n do
		local ok, message = Step(position > n)
		if not ok then return false, message end
	end
	return true
end

------------------------------------------------------------------- revert

-- Whether step i can be undone on its own, and if not, why (nil for a step that
-- isn't applied: it shows no control).
function History:CanRevert(i)
	local step = steps[i]
	if not step or i > position then return false, nil end
	if step.kind == 'bulk' then
		return false, "A copy can't be reverted on its own: go back to this point instead."
	end
	local places = History.Places(step)
	for j = i + 1, position do
		if Touches(steps[j], places) then
			return false, 'Changed again later: go back to this point instead.'
		end
	end
	for _, change in ipairs(step.changes) do
		if Missing(change) then return false, NameOf(change) .. " isn't there now." end
	end
	local stale = StaleChange(step, true)
	if stale then return false, NameOf(stale) .. ' was changed since.' end
	return true
end

-- Puts step i's old values back as a new step of its own.
function History:Revert(i)
	if InCombatLockdown() then return false, "Can't revert in combat." end
	local ok, why = self:CanRevert(i)
	if not ok then return false, why end
	local step = steps[i]
	why = Refusal(step, false)
	if why then return false, why end
	local changes = {}
	for _, change in ipairs(step.changes) do
		changes[#changes + 1] = {
			kind = change.kind, where = change.where,
			old = Handler(change.kind).read(change.where), new = change.old,
		}
	end
	WriteStep(step, true)
	self:CloseRun()
	self:Push({
		kind = 'revert', label = 'Reverted: ' .. tostring(History.Label(step)),
		target = step.target, changes = changes,
	})
	return true
end
