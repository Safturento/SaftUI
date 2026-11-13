local st = SaftUI
local LT = st.Loot

-- The drops C_LootHistory keeps, read into plain summaries (LT:SummarizeDrop,
-- LT:GetOpenDrops) and the saved set of recorded drops. rolls.lua takes the
-- functions it uses from `LT.loothistory`.

-- Enum.EncounterLootDropRollState, with the values from Forever's API docs in
-- case the enum isn't there.
local STATE_ENUM = Enum and Enum.EncounterLootDropRollState or {}
local STATE = {
	NeedMainSpec = STATE_ENUM.NeedMainSpec or 0,
	NeedOffSpec = STATE_ENUM.NeedOffSpec or 1,
	Transmog = STATE_ENUM.Transmog or 2,
	Greed = STATE_ENUM.Greed or 3,
	NoRoll = STATE_ENUM.NoRoll or 4,
	Pass = STATE_ENUM.Pass or 5,
}
LT.ROLL_STATE = STATE

------------------------------------
---- Plain values ------------------
------------------------------------

local function IsTrue(v)
	return not issecretvalue(v) and v == true
end

-- rollinfo.lua (the live choices on the roll bars) takes these from here, and
-- does nothing until this file has loaded.
LT.PlainNumber, LT.PlainString = st.PlainNumber, st.PlainString

------------------------------------
---- Drops -------------------------
------------------------------------

-- A drop's index in its encounter. Forever's EncounterLootDropInfo calls it
-- lootListKey; retail's still calls it lootListID.
local function DropIndex(drop)
	return st.PlainNumber(drop.lootListKey) or st.PlainNumber(drop.lootListID)
end

-- A link's "item:..." part, or the whole link when it has none.
local function ItemString(link)
	return link:match('|H(item:[^|]*)|h') or link
end
LT.ItemString = ItemString

-- encounterID:lootListKey:item string, or nil when any part isn't plain. The
-- item string stands in for the whole link: a link built while the item wasn't
-- cached can differ in its name or colour from the same drop's link later, and
-- the whole link would then record the drop twice.
local function DropKey(encounterID, drop)
	encounterID = st.PlainNumber(encounterID)
	local index = DropIndex(drop)
	local link = st.PlainString(drop.itemHyperlink)
	if encounterID and index and link then
		return encounterID .. ':' .. index .. ':' .. ItemString(link)
	end
end

-- A drop is still being rolled while it has neither a winner nor all passed.
local function HasEnded(drop)
	return IsTrue(drop.allPassed) or type(drop.winner) == 'table'
end

-- Someone made a choice (passing counts). Master-looted, personal-loot and
-- auto-assigned drops have no choices, so they get no roll result.
local function SomeoneRolled(drop)
	if type(drop.rollInfos) ~= 'table' then return false end
	for _, info in ipairs(drop.rollInfos) do
		local state = st.PlainNumber(info.state)
		if state and state ~= STATE.NoRoll then return true end
	end
	return false
end

-- Whether two of the game's roll infos are the same player.
local function SamePlayer(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return false end
	local guidA, guidB = st.PlainString(a.playerGUID), st.PlainString(b.playerGUID)
	if guidA and guidB then return guidA == guidB end
	local nameA = st.PlainString(a.playerName)
	return nameA ~= nil and nameA == st.PlainString(b.playerName)
end

-- When the roll of a drop the addon didn't see end started, as a real time,
-- and when it could have ended at the latest (nil when unknown). The history's
-- clock, a drop's startTime and its duration all count milliseconds.
local function EstimateWhen(drop)
	local now = time()
	local historyNow = C_LootHistory.GetLootHistoryTime and st.PlainNumber(C_LootHistory.GetLootHistoryTime())
	local start = st.PlainNumber(drop.startTime)
	if not (historyNow and start) then return now end

	local when = now - max(0, floor((historyNow - start) / 1000))
	local duration = st.PlainNumber(drop.duration)
	local ends = duration and duration > 0 and when + floor(duration / 1000) or nil
	return when, ends
end

-- A plain-data copy of a drop's rolls. `ended` trims it for keeping: an ended
-- drop's tooltip shows no "Waiting on:", leader or tie, and an all-passed one
-- only "All passed", so those parts are left out of what's saved.
local function Summarize(drop, ended)
	local rolls = { list = {} }
	if IsTrue(drop.allPassed) then
		rolls.allPassed = true
		if ended then return rolls end
	end

	local list = rolls.list
	local winner, leader = drop.winner, drop.currentLeader
	if type(drop.rollInfos) == 'table' then
		for _, info in ipairs(drop.rollInfos) do
			local name, state = st.PlainString(info.playerName), st.PlainNumber(info.state)
			if name and state and not (ended and state == STATE.NoRoll) then
				local line = {
					name = name,
					class = st.PlainString(info.playerClass),
					state = state,
					roll = st.PlainNumber(info.roll),
					isSelf = IsTrue(info.isSelf) or nil,
				}
				tinsert(list, line)
				if not rolls.winner and (IsTrue(info.isWinner) or SamePlayer(info, winner)) then
					line.isWinner = true
					rolls.winner = #list
				end
				if not ended and not rolls.leader and SamePlayer(info, leader) then
					rolls.leader = #list
				end
			end
		end
	end

	if not ended then rolls.tied = IsTrue(drop.isTied) or nil end
	return rolls
end

-- The full summary, for a roll still open: every player, with who leads.
function LT:SummarizeDrop(dropInfo)
	if type(dropInfo) ~= 'table' then return end
	return Summarize(dropInfo, false)
end

-- Whether a roll time that began at `start` and lasts `duration` has run out,
-- by the history's clock (`now`). All three count milliseconds; the test is
-- the one Blizzard's Loot Rolls window uses for its timer. False when any of
-- them isn't plain or the duration isn't positive.
local function RollTimeOver(now, start, duration)
	start, duration = st.PlainNumber(start), st.PlainNumber(duration)
	if not (now and start and duration and duration > 0) then return false end
	return now - start > duration
end

-- Every drop still being rolled, oldest first, as { id, encounterID, index,
-- link, start, playerState } with plain values only (playerState is your own
-- choice on it, nil when not plain). rollinfo.lua matches the roll bars to
-- these. A boss's drops all start together, so ties go by encounter and index
-- to keep the order the same from one call to the next. Encounters and drops
-- whose roll time has run out are skipped: that keeps a drop that never got a
-- result from taking a later roll of the same item, and the scan short.
function LT:GetOpenDrops()
	local open = {}
	if not C_LootHistory then return open end
	local now = C_LootHistory.GetLootHistoryTime and st.PlainNumber(C_LootHistory.GetLootHistoryTime())
	for _, encounter in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
		local encounterID = type(encounter) == 'table'
			and not RollTimeOver(now, encounter.startTime, encounter.duration)
			and st.PlainNumber(encounter.encounterID)
		if encounterID then
			for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}) do
				local index = type(drop) == 'table' and not HasEnded(drop)
					and not RollTimeOver(now, drop.startTime, drop.duration)
					and DropIndex(drop)
				local link = index and st.PlainString(drop.itemHyperlink)
				if link then
					tinsert(open, {
						id = encounterID .. ':' .. index,
						encounterID = encounterID,
						index = index,
						link = link,
						start = st.PlainNumber(drop.startTime) or 0,
						playerState = st.PlainNumber(drop.playerRollState),
					})
				end
			end
		end
	end
	table.sort(open, function(a, b)
		if a.start ~= b.start then return a.start < b.start end
		if a.encounterID ~= b.encounterID then return a.encounterID < b.encounterID end
		return a.index < b.index
	end)
	return open
end

local function RecordedDrops()
	local store = LT:GetHistoryStore()
	if type(store.drops) ~= 'table' then store.drops = {} end
	return store.drops
end


LT.loothistory = {
	DropKey = DropKey,
	HasEnded = HasEnded,
	SomeoneRolled = SomeoneRolled,
	EstimateWhen = EstimateWhen,
	Summarize = Summarize,
	RecordedDrops = RecordedDrops,
}
