local st = SaftUI
local EM = st.EditModeFrames
local History = EM.History

-- Edit mode's side of the history (history.lua): the 'position' kind (what a
-- mover's stored position is, how it is put back), recording a drag, a nudge or
-- a Reset as a step, and Reset itself. A position changed in /sui is not edit
-- mode's move and is not recorded (a later part tracks settings).

local TOLERANCE = 1e-4

-- A copy of a stored position, deep, and a plain table: no metatable, so a copy
-- stored in the profile is not tied to AceDB's defaults. A field the profile
-- only has through its defaults (read by index, not by pairs) is copied too, so
-- nothing is lost between what read saw and what write stores. A frame object
-- (a table with a metatable) is kept as it is.
local FIELDS = { 'point', 'frame', 'rel_point', 'x_off', 'y_off' }

local function Copy(value)
	local copy = {}
	for k, v in pairs(value) do
		if type(v) == 'table' and getmetatable(v) == nil then copy[k] = Copy(v) else copy[k] = v end
	end
	return copy
end

function EM.CopyPosition(position)
	if type(position) ~= 'table' then return position end
	local copy = Copy(position)
	for _, field in ipairs(FIELDS) do
		if copy[field] == nil and position[field] ~= nil then copy[field] = position[field] end
	end
	return copy
end

-- The frame a position anchors to, by name: nothing, 'UIParent' and UIParent
-- are the screen.
local function FrameKey(frame)
	if frame == nil or frame == UIParent or frame == 'UIParent' then return 'UIParent' end
	if type(frame) == 'table' and frame.GetName then return frame:GetName() or frame end
	return frame
end

local function Offset(v) return tonumber(v) or 0 end

-- Whether two positions are the same place: the point, the point on the frame
-- (a missing one is the point), the frame, and the offsets as numbers (a string
-- and a number alike, and noise under 1e-4 is no change).
function EM.SamePosition(a, b)
	if a == nil or b == nil then return a == b end
	if a.point ~= b.point then return false end
	if (a.rel_point or a.point) ~= (b.rel_point or b.point) then return false end
	if FrameKey(a.frame) ~= FrameKey(b.frame) then return false end
	return math.abs(Offset(a.x_off) - Offset(b.x_off)) <= TOLERANCE
		and math.abs(Offset(a.y_off) - Offset(b.y_off)) <= TOLERANCE
end

-- A copy of what the mover has saved. A mover that makes up a position while
-- none is saved (the totem bar, the objective tracker) gives def.getSavedPosition,
-- which is nil then, so the history puts "nothing saved" back instead of saving
-- the position it made up. Others read getPosition.
function EM.SavedPosition(mover)
	local def = mover.def
	local get = def.getSavedPosition or def.getPosition
	return EM.CopyPosition(get())
end

-- A number as one decimal at most, never -0.
local function Number(v)
	v = math.floor(v * 10 + 0.5) / 10
	if v == 0 then return '0' end
	return tostring(v)
end

-- 'Moved Player', 'Nudged Player by 3, 0' (the net offsets) or 'Reset Player'.
function EM.MoveLabel(kind, name, old, new)
	if kind == 'nudge' then
		return ('Nudged %s by %s, %s'):format(name,
			Number(Offset(new.x_off) - Offset(old.x_off)), Number(Offset(new.y_off) - Offset(old.y_off)))
	elseif kind == 'reset' then
		return 'Reset ' .. name
	end
	return 'Moved ' .. name
end

------------------------------------------------------------------- the kind

-- The movers a jump has placed and not yet announced.
local announce = { list = {}, seen = {} }

History:RegisterKind('position', {
	read = function(key)
		local mover = EM.movers[key]
		return mover and EM.SavedPosition(mover)
	end,
	write = function(key, value)
		local mover = EM.movers[key]
		if mover then mover.def.setPosition(EM.CopyPosition(value)) end
	end,
	-- After a step's writes: each frame is placed (apply goes through
	-- st:SafeReposition, as a drag's commit does), then edit mode's event, which
	-- the bar and the Coordinates label follow.
	finish = function(keys)
		local movers = {}
		for _, key in ipairs(keys) do
			local mover = EM.movers[key]
			if mover then
				movers[#movers + 1] = mover
				xpcall(mover.def.apply, geterrorhandler())
			end
		end
		for _, mover in ipairs(movers) do
			if History.batching then
				-- In a jump: placed now, told once at the end (flush).
				if not announce.seen[mover] then
					announce.seen[mover] = true
					announce.list[#announce.list + 1] = mover
				end
			else
				EM:Fire('PositionChanged', mover)
			end
		end
	end,
	flush = function()
		local list = announce.list
		announce.list, announce.seen = {}, {}
		for _, mover in ipairs(list) do EM:Fire('PositionChanged', mover) end
	end,
	same = EM.SamePosition,
	-- The anchor a restored position names must still be one the frame can take
	-- (the frame it anchored to may have been anchored to it since).
	check = function(key, value)
		local mover = EM.movers[key]
		if not mover or type(value) ~= 'table' then return true end
		local frame = value.frame
		if frame == nil or frame == UIParent or frame == 'UIParent' then return true end
		local ok, why = st:ValidateAnchor(mover.def.frame, frame)
		if ok then return true end
		st:Print(why)
		return false, why
	end,
	name = function(key)
		local mover = EM.movers[key]
		return mover and EM.MoverName(mover) or key
	end,
	missing = function(key) return EM.movers[key] == nil end,
})

----------------------------------------------------------------- recording

-- Records a move already made: kind 'move' (a drag), 'nudge' or 'reset'; before
-- is the position copied before it. A nudge's label is a function of its first
-- change, so a run of nudges merged into one reads its net offset.
function EM:RecordMove(mover, kind, before, shownBefore)
	local def = mover.def
	local key = mover.key
	local after = EM.SavedPosition(mover)
	local label
	if kind == 'nudge' then
		label = function(step)
			local change = step.changes[1]
			local m = EM.movers[key]
			return EM.MoveLabel('nudge', m and EM.MoverName(m) or key, change.old or change.from, change.new)
		end
	else
		label = EM.MoveLabel(kind, EM.MoverName(mover), before, after)
	end
	return History:Push({
		kind = kind, target = key, label = label,
		changes = { { kind = 'position', where = key, old = before, new = after, from = shownBefore } },
	})
end

-------------------------------------------------------------------- reset

-- Whether the mover can go back to its default place, and if not, why. With
-- quiet (the options kit's icon check, on every render) it answers true or
-- false and makes no table and no text.
function EM:CanReset(mover, quiet)
	if not mover then return false, 'Select a frame first.' end
	local def = mover.def
	local default = self:PeekDefaultPosition(mover)
	if not default then
		if quiet then return false end
		return false, def.noDefaultReason or (EM.MoverName(mover) .. ' has no default place.')
	end
	if EM.SamePosition(def.getPosition(), default) then
		if quiet then return false end
		return false, EM.MoverName(mover) .. ' is already in its default place.'
	end
	if InCombatLockdown() then
		if quiet then return false end
		return false, "Can't reset in combat."
	end
	-- The default may anchor to a frame that is anchored to this one since; the
	-- same check Undo and Redo make before they put an anchor back.
	local anchor = default.frame
	if anchor ~= nil and anchor ~= UIParent and anchor ~= 'UIParent' then
		local valid, why = st:ValidateAnchor(def.frame, anchor)
		if not valid then
			if quiet then return false end
			return false, ("%s can't go back to its default place: %s."):format(EM.MoverName(mover), why)
		end
	end
	return true
end

-- Puts the mover's frame in its default place, as a step of its own that can be
-- undone. The stored position is a copy, never the defaults table.
function EM:Reset(mover)
	local ok, why = self:CanReset(mover)
	if not ok then return false, why end
	local def = mover.def
	local before = EM.SavedPosition(mover)
	def.setPosition(self:GetDefaultPosition(mover))
	xpcall(def.apply, geterrorhandler())
	self:Fire('PositionChanged', mover)
	self:RecordMove(mover, 'reset', before)
	return true, 'Reset ' .. EM.MoverName(mover)
end

-- Leaving edit mode ends a run of nudges.
EM:On('Disabled', function() History:CloseRun() end)
