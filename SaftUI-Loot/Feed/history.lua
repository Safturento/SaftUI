-- The saved loot feed. Entries are kept per character (AceDB's char namespace,
-- which a profile switch does not touch) so the feed survives /reload and
-- logout. The saved copy is plain data holding only what a feed line and its
-- tooltip read; session-only fields (time, test, restored, saved) are left out.
--
-- st.config.char.loot = { feed = { entries, newest first }, drops = { [key] = true } }
-- `drops` is for the roll results (recorded drops, Feed/rolls.lua) and is not
-- touched here.

local st = SaftUI
local LT = st.Loot

-- The feed's cap, shared with feed.lua (which loads after this file).
LT.MAX_HISTORY = 500
local MAX_HISTORY = LT.MAX_HISTORY

-- How far in the past a restored entry's session clock is put, so it is not
-- fresh. Scrolling or hovering it still sets time to now, like any entry.
local STALE_AGE = 24 * 3600

-- Every field a feed line (UpdateFeed), the filters and the tooltip read.
-- Roll results also keep `rolls`, copied by CopyRolls.
local SAVED_FIELDS = {
	'name', 'gold', 'icon', 'link', 'count', 'rightText', 'notSelf',
	'type', 'itemSubType', 'craftQuality', 'when', 'looted',
}

-- A roll result's summary (LT:SummarizeDrop) and each player's line in it, by
-- the type each field must have.
local ROLLS_FIELDS = { allPassed = 'boolean', winner = 'number', leader = 'number', tied = 'boolean' }
local ROLL_LINE_FIELDS = {
	name = 'string', class = 'string', state = 'number', roll = 'number',
	isSelf = 'boolean', isWinner = 'boolean',
}

-- Read through this each time: st.config does not exist at file load.
function LT:GetHistoryStore()
	local store = st.config.char.loot
	if not store then
		store = {}
		st.config.char.loot = store
	end
	store.feed = store.feed or {}
	store.drops = store.drops or {}
	return store
end

local function IsPlain(v)
	local t = type(v)
	return (t == 'string' or t == 'number' or t == 'boolean') and not issecretvalue(v)
end

-- A copy of the fields of `src` named in `fields`, or nil if one has the wrong
-- type or is secret.
local function CopyTyped(src, fields)
	local copy = {}
	for key, kind in pairs(fields) do
		local v = src[key]
		if v ~= nil then
			if issecretvalue(v) or type(v) ~= kind then return end
			copy[key] = v
		end
	end
	return copy
end

-- A copy of a roll summary, field by field, or nil if anything in it isn't
-- the plain data the tooltip reads.
local function CopyRolls(r)
	if type(r) ~= 'table' then return end
	local rolls = CopyTyped(r, ROLLS_FIELDS)
	if not rolls then return end

	local list = {}
	if r.list ~= nil then
		if type(r.list) ~= 'table' then return end
		for i, line in ipairs(r.list) do
			local copy = type(line) == 'table' and CopyTyped(line, ROLL_LINE_FIELDS)
			if not copy then return end
			list[i] = copy
		end
	end
	rolls.list = list
	return rolls
end

-- A plain-data copy of the saved fields, or nil if any value is secret or not
-- plain data (the entry is then simply not saved).
local function CopyEntry(info)
	local copy = {}
	for _, key in ipairs(SAVED_FIELDS) do
		local v = info[key]
		if v ~= nil then
			if not IsPlain(v) then return end
			copy[key] = v
		end
	end

	local p = info.progress
	if p ~= nil then
		if type(p) ~= 'table' then return end
		local progress = {}
		for _, key in ipairs({ 'max', 'value', 'r', 'g', 'b' }) do
			local v = p[key]
			if type(v) ~= 'number' or issecretvalue(v) then return end
			progress[key] = v
		end
		copy.progress = progress
	end

	if info.rolls ~= nil then
		copy.rolls = CopyRolls(info.rolls)
		if not copy.rolls then return end
	end

	return copy
end

-- Writes the entry's saved copy. A new live entry goes to the front; a restored
-- one goes in by its `when`. An entry already saved is updated in place (a
-- merge). Test entries and entries holding a secret value are never saved.
function LT:SaveFeedEntry(info)
	if info.test then return end

	local copy = CopyEntry(info)
	if not copy then return end

	if info.saved then
		wipe(info.saved)
		for k, v in pairs(copy) do info.saved[k] = v end
		return
	end

	local list = self:GetHistoryStore().feed
	local index = 1
	if info.restored then
		local when = info.when or 0
		while list[index] and (list[index].when or 0) >= when do index = index + 1 end
	end
	tinsert(list, index, copy)
	info.saved = copy

	while #list > MAX_HISTORY do tremove(list) end
end

-- Once at load, before the feed's first draw: fills the feed from the store.
-- Every entry is marked restored and put well past its fade time.
function LT:RestoreFeed()
	if self.feedRestored then return end
	self.feedRestored = true

	local stack = self:GetAllItems()
	local now = GetTime()
	for _, saved in ipairs(self:GetHistoryStore().feed) do
		-- Only plain values are copied (a hand-edited save could hold anything);
		-- an entry left without a name or type is skipped.
		local info = {}
		if type(saved) == 'table' then
			for _, key in ipairs(SAVED_FIELDS) do
				if IsPlain(saved[key]) then info[key] = saved[key] end
			end
		end
		if info.name and info.type then
			-- Older or hand-edited saves can hold the wrong shapes; drop what would
			-- error later (the progress bar's min/max, sorting by `when`).
			if type(info.when) ~= 'number' then info.when = nil end
			local progress = saved.progress
			local valid = type(progress) == 'table'
			if valid then
				for _, key in ipairs({ 'max', 'value', 'r', 'g', 'b' }) do
					if type(progress[key]) ~= 'number' then valid = false end
				end
			end
			if valid then
				info.progress = progress
			end
			-- LT:AddRollLines checks each part of it as it reads.
			if type(saved.rolls) == 'table' then
				info.rolls = saved.rolls
			end
			info.saved = saved
			info.restored = true
			info.time = now - STALE_AGE
			tinsert(stack, info)
		end
	end
end

-- Inserts a not-fresh entry by its `when` (newest first), without merging, and
-- saves it. For things that happened while the addon wasn't watching. Returns
-- false, inserting nothing, when the entry is older than everything in a full
-- feed.
function LT:InsertRestoredEntry(info)
	info.restored = true
	info.test = nil
	info.when = info.when or time()
	info.time = GetTime() - STALE_AGE

	local stack = self:GetAllItems()
	local index = 1
	while stack[index] and (stack[index].when or 0) >= info.when do index = index + 1 end
	if index > MAX_HISTORY then return false end

	tinsert(stack, index, info)
	while #stack > MAX_HISTORY do tremove(stack) end

	self:SaveFeedEntry(info)
	if self.feed then self:UpdateFeed() end
	return true
end

-- Empties the saved feed and the feed on screen. The recorded drops stay, so
-- cleared results don't come back at the next load.
function LT:ClearFeedHistory()
	wipe(self:GetHistoryStore().feed)
	wipe(self:GetAllItems())
	if self.feed then self:RemoveTestFeedEntries() end
end

local function Plural(n, unit)
	return ('%d %s%s ago'):format(n, unit, n == 1 and '' or 's')
end

function LT:FormatAgo(when)
	if type(when) ~= 'number' then return '' end
	local diff = max(0, time() - when)
	if diff < 60 then return 'just now' end
	if diff < 3600 then return Plural(floor(diff / 60), 'minute') end
	if diff < 86400 then return Plural(floor(diff / 3600), 'hour') end
	return Plural(floor(diff / 86400), 'day')
end
