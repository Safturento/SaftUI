-- The saved loot feed. Entries are kept per character (AceDB's char namespace,
-- which a profile switch does not touch) so the feed survives /reload and
-- logout. The saved copy is plain data holding only what a feed line and its
-- tooltip read; session-only fields (time, test, restored, saved) are left out.
--
-- st.config.char.loot = { feed = { entries, newest first }, drops = { [key] = true } }
-- `drops` is for the roll results (recorded drops) and is not touched here.

local st = SaftUI
local LT = st.Loot

local MAX_HISTORY = 500

-- How far in the past a restored entry's session clock is put, so it is not
-- fresh. Scrolling or hovering it still sets time to now, like any entry.
local STALE_AGE = 24 * 3600

-- Every field a feed line (UpdateFeed), the filters and the tooltip read.
local SAVED_FIELDS = {
	'name', 'gold', 'icon', 'link', 'count', 'rightText', 'notSelf',
	'type', 'itemSubType', 'craftQuality', 'when',
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
		if type(saved) == 'table' and saved.name and saved.type then
			local info = {}
			for _, key in ipairs(SAVED_FIELDS) do info[key] = saved[key] end
			info.progress = saved.progress
			info.saved = saved
			info.restored = true
			info.time = now - STALE_AGE
			tinsert(stack, info)
		end
	end
end

-- Inserts a not-fresh entry by its `when` (newest first), without merging, and
-- saves it. For things that happened while the addon wasn't watching.
function LT:InsertRestoredEntry(info)
	info.restored = true
	info.test = nil
	info.when = info.when or time()
	info.time = GetTime() - STALE_AGE

	local stack = self:GetAllItems()
	local index = 1
	while stack[index] and (stack[index].when or 0) >= info.when do index = index + 1 end
	if index > MAX_HISTORY then return end

	tinsert(stack, index, info)
	while #stack > MAX_HISTORY do tremove(stack) end

	self:SaveFeedEntry(info)
	if self.feed then self:UpdateFeed() end
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
