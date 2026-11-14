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

-- Whether the step starts where the top step left off: each change of it that
-- the top also made begins at the top's current new. A value changed from
-- outside between two nudges (a /sui edit) ends the run.
function History.Continues(top, step)
	for _, change in ipairs(step.changes or {}) do
		local place = PlaceOf(change)
		for _, have in ipairs(top.changes) do
			if PlaceOf(have) == place and not Same(have, have.new, change.old) then return false end
		end
	end
	return true
end

-- The grouping rule, the one place it lives: the top step is an open run of
-- nudges, the new step is a nudge of the same mover, nothing has been undone,
-- and the new nudge comes within MERGE_GAP of the run's last.
function History.Merges(top, step, now)
	return top ~= nil
		and History.Continues(top, step)
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

-- Drops the steps past the limit: the oldest applied ones first (what has to
-- go is the oldest history), then, if the redo steps alone are still over,
-- the newest redo steps. The steps that stay are one unbroken chain, so every
-- redo that is left still starts from the state the frames are in. True when
-- it dropped any.
local function Trim()
	local extra = #steps - History.limit
	if extra <= 0 then return false end
	local applied = math.min(extra, position)
	for _ = 1, applied do table.remove(steps, 1) end
	position = position - applied
	for _ = 1, extra - applied do steps[#steps] = nil end
	return true
end

-- The limit, a whole number from LIMIT_MIN to LIMIT_MAX. Lowering it is lazy:
-- nothing is dropped until the next step is recorded (Push trims then: the
-- oldest applied steps first), so a slider dragged down and back, or a typo,
-- loses nothing. Raising it takes effect at once. NaN and anything that is
-- not a number (typed text included) is rejected: the limit stays.
function History:SetLimit(n)
	n = tonumber(n)
	if n == nil or n ~= n then return end
	if n == math.huge then n = History.LIMIT_MAX elseif n == -math.huge then n = History.LIMIT_MIN end
	n = math.floor(n + 0.5)
	History.limit = math.min(math.max(n, History.LIMIT_MIN), History.LIMIT_MAX)
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
				if have.kind == change.kind and PlaceOf(have) == PlaceOf(change) then found = have break end
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

-- The value a step puts in a change when it is undone (old) or redone (new).
-- Explicit, not `a and b or c`: false and nil are values.
local function Target(change, wantNew)
	if wantNew then return change.new end
	return change.old
end

local function Report(err)
	geterrorhandler()(err)
	return err
end

-- Runs each kind's finish once with the wheres it was given, through xpcall.
local function Finish(byKind, order)
	for _, kind in ipairs(order) do
		local finish = Handler(kind).finish
		if finish then xpcall(finish, geterrorhandler(), byKind[kind]) end
	end
end

-- Writes each change's value (old when undoing, new when redoing) and runs each
-- kind's finish once. Changes whose thing is gone are skipped; their names are
-- returned. A write that errors (reported to the error handler) rolls the step
-- back: what was written is written back and placed again, and the failed
-- change's name and the error are the second and third results; the history
-- and the frames then agree that the step was not applied.
local function WriteStep(step, undoing)
	local skipped, written = {}, {}
	local count = #step.changes
	for n = 1, count do
		local change = step.changes[undoing and count - n + 1 or n]
		if Missing(change) then
			skipped[#skipped + 1] = NameOf(change)
		else
			local ok, err = xpcall(Handler(change.kind).write, Report, change.where, Target(change, not undoing))
			if not ok then
				local byKind, order = {}, {}
				for i = #written, 1, -1 do
					local back = written[i]
					xpcall(Handler(back.kind).write, Report, back.where, Target(back, undoing))
					if not byKind[back.kind] then
						byKind[back.kind] = {}
						order[#order + 1] = back.kind
					end
					table.insert(byKind[back.kind], back.where)
				end
				Finish(byKind, order)
				return nil, NameOf(change), err
			end
			written[#written + 1] = change
		end
	end
	local byKind, order = {}, {}
	for _, change in ipairs(written) do
		if not byKind[change.kind] then
			byKind[change.kind] = {}
			order[#order + 1] = change.kind
		end
		table.insert(byKind[change.kind], change.where)
	end
	Finish(byKind, order)
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
			if not Same(change, now, Target(change, expectNew)) then return change end
		end
	end
end

-- The first refusal among the checks of the values it is about to write.
local function Refusal(step, writeNew)
	for _, change in ipairs(step.changes) do
		local check = Handler(change.kind).check
		if check and not Missing(change) then
			local ok, why = check(change.where, Target(change, writeNew))
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
	local skipped, failed = WriteStep(step, undoing)
	if not skipped then
		Changed()
		return false, failed .. " couldn't be " .. (undoing and 'undone' or 'redone') .. '; the step was put back.'
	end
	position = undoing and position - 1 or position + 1
	Changed()
	return true, Skipped(skipped)
end

function History:Undo() return Step(true) end
function History:Redo() return Step(false) end

-- Undoes or redoes one step at a time until Position() is n (0 is before every
-- step). Stops at the first refusal.
function History:JumpTo(n)
	if type(n) ~= 'number' or n ~= n or n < 0 or n > #steps or n ~= math.floor(n) then
		return false, 'No such step.'
	end
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
	local skipped, failed = WriteStep(step, true)
	if not skipped then return false, failed .. " couldn't be reverted; the step was put back." end
	self:CloseRun()
	self:Push({
		kind = 'revert', label = 'Reverted: ' .. tostring(History.Label(step)),
		target = step.target, changes = changes,
	})
	return true
end
