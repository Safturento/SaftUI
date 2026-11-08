-- Roll results in the loot feed. C_LootHistory keeps the group-loot drops of
-- the session: who chose what, their rolls, and the winner. When a drop's roll
-- ends, it gets one feed entry (type 'Rolls') naming the winner, and hovering
-- the entry lists everyone's rolls (LT:AddRollLines). The winner's own loot
-- message is folded into that entry rather than making a second one, whichever
-- of the two arrives first.
--
-- Recorded drops: st.config.char.loot.drops is a saved set of the drops that
-- already have an entry, so a reload never adds one twice. At load, keys no
-- longer in Blizzard's history are dropped (a later drop could reuse them),
-- and a drop that ended while the addon wasn't watching (a roll that ended
-- during a reload) is added then, as history rather than a fresh line.
--
-- Nothing secret is kept or compared: every value read from C_LootHistory goes
-- through the Plain* checks first.

local st = SaftUI
local LT = st.Loot

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

-- How far apart (in seconds) a roll's end and the winner's loot message can
-- be and still fold into one entry. The server hands the item over as the roll
-- ends, so the two normally arrive within a second of each other, in either
-- order. Ten seconds leaves room for lag without catching a separate, later
-- loot of the same item.
local FOLD_WINDOW = 10

local ALL_PASSED = 'All passed'
local CHECK = '|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t'

-- The choices in the tooltip, in the game's order of precedence, each in its
-- roll button's colour (roll.lua). Passes get one line of names after these.
local CHOICES = {
	{ label = 'Need', color = 'white', states = { [STATE.NeedMainSpec] = true, [STATE.NeedOffSpec] = true } },
	{ label = 'Transmog', color = 'purple', states = { [STATE.Transmog] = true } },
	{ label = 'Greed', color = 'yellow', states = { [STATE.Greed] = true } },
}

local openRolls = {} -- results still waiting for the winner's loot message
local pending = {}   -- ended drops waiting for their item's data
local pendingKeys = {}
local declinedKeys = {} -- found at load with no room in the feed; retried next load
-- The entry each drop recorded this session went into, by its key, so later
-- updates to the drop (a roll number arriving after the winner) reach it.
local entryByKey = setmetatable({}, { __mode = 'v' })

------------------------------------
---- Plain values ------------------
------------------------------------

local function PlainNumber(v)
	if not issecretvalue(v) and type(v) == 'number' then return v end
end

local function PlainString(v)
	if not issecretvalue(v) and type(v) == 'string' then return v end
end

local function IsTrue(v)
	return not issecretvalue(v) and v == true
end

-- rollinfo.lua (the live choices on the roll bars) checks what it reads the same way.
LT.PlainNumber, LT.PlainString = PlainNumber, PlainString

------------------------------------
---- Drops -------------------------
------------------------------------

-- A drop's index in its encounter. Forever's EncounterLootDropInfo calls it
-- lootListKey; retail's still calls it lootListID.
local function DropIndex(drop)
	return PlainNumber(drop.lootListKey) or PlainNumber(drop.lootListID)
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
	encounterID = PlainNumber(encounterID)
	local index = DropIndex(drop)
	local link = PlainString(drop.itemHyperlink)
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
		local state = PlainNumber(info.state)
		if state and state ~= STATE.NoRoll then return true end
	end
	return false
end

-- Whether two of the game's roll infos are the same player.
local function SamePlayer(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return false end
	local guidA, guidB = PlainString(a.playerGUID), PlainString(b.playerGUID)
	if guidA and guidB then return guidA == guidB end
	local nameA = PlainString(a.playerName)
	return nameA ~= nil and nameA == PlainString(b.playerName)
end

-- When the roll of a drop the addon didn't see end started, as a real time,
-- and when it could have ended at the latest (nil when unknown). The history's
-- clock, a drop's startTime and its duration all count milliseconds.
local function EstimateWhen(drop)
	local now = time()
	local historyNow = C_LootHistory.GetLootHistoryTime and PlainNumber(C_LootHistory.GetLootHistoryTime())
	local start = PlainNumber(drop.startTime)
	if not (historyNow and start) then return now end

	local when = now - max(0, floor((historyNow - start) / 1000))
	local duration = PlainNumber(drop.duration)
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
			local name, state = PlainString(info.playerName), PlainNumber(info.state)
			if name and state and not (ended and state == STATE.NoRoll) then
				local line = {
					name = name,
					class = PlainString(info.playerClass),
					state = state,
					roll = PlainNumber(info.roll),
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
	start, duration = PlainNumber(start), PlainNumber(duration)
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
	local now = C_LootHistory.GetLootHistoryTime and PlainNumber(C_LootHistory.GetLootHistoryTime())
	for _, encounter in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
		local encounterID = type(encounter) == 'table'
			and not RollTimeOver(now, encounter.startTime, encounter.duration)
			and PlainNumber(encounter.encounterID)
		if encounterID then
			for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}) do
				local index = type(drop) == 'table' and not HasEnded(drop)
					and not RollTimeOver(now, drop.startTime, drop.duration)
					and DropIndex(drop)
				local link = index and PlainString(drop.itemHyperlink)
				if link then
					tinsert(open, {
						id = encounterID .. ':' .. index,
						encounterID = encounterID,
						index = index,
						link = link,
						start = PlainNumber(drop.startTime) or 0,
						playerState = PlainNumber(drop.playerRollState),
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

------------------------------------
---- Tooltip lines -----------------
------------------------------------

local function TextRGB(key)
	return st.config.profile.colors.text[key]:GetRGB()
end

local function Colored(text, key)
	return st.StringFormat:ColorString(text, TextRGB(key))
end

local function ClassColored(name, class)
	local color = type(class) == 'string' and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if color then return st.StringFormat:ColorString(name, color.r, color.g, color.b) end
	return name
end

-- Blizzard's strings where the client has them.
local function OffSpec(name)
	local fmt = LOOT_HISTORY_OFF_SPEC_FMT
	if type(fmt) ~= 'string' or not fmt:find('%%s') then fmt = '%s (off spec)' end
	return fmt:format(name)
end

local function WaitingOnPrefix()
	local text = type(LOOT_HISTORY_WAITING_ON) == 'string' and LOOT_HISTORY_WAITING_ON or 'Waiting on:'
	return (text:gsub('%s*$', ' '))
end

-- As Blizzard's Loot Rolls window words the leader: its current-winner text
-- with the leader's name, or its tie text in place of the name.
local function CurrentLeader(tied, leader)
	local fmt = LOOT_HISTORY_CURRENT_WINNER
	if type(fmt) ~= 'string' or not fmt:find('%%s') then fmt = 'Leading: %s (%d)' end
	local name = ClassColored(leader.name, leader.class)
	if tied then
		name = type(LOOT_HISTORY_ROLL_TIE) == 'string' and LOOT_HISTORY_ROLL_TIE or 'Tie'
	end
	return fmt:format(name, leader.roll)
end

local function Delimiter()
	return type(LOOT_HISTORY_PLAYER_DELIMITER) == 'string' and LOOT_HISTORY_PLAYER_DELIMITER or ', '
end

local function IsLine(line)
	return type(line) == 'table' and type(line.name) == 'string' and type(line.state) == 'number'
end

-- The class-coloured names of everyone in one state, or nil if nobody is.
local function NameList(list, state)
	local names
	for _, line in ipairs(list) do
		if IsLine(line) and line.state == state then
			local name = ClassColored(line.name, line.class)
			names = names and (names .. Delimiter() .. name) or name
		end
	end
	return names
end

-- Appends a drop's rolls to a tooltip, with what Blizzard's Loot Rolls window
-- shows: each choice with its players and their rolls ("(off spec)" on an off
-- spec need), the winner checked, or "All passed". `live` (a roll still open)
-- adds who it's waiting on and who leads. Saved summaries can be hand-edited,
-- so every part is type-checked before use.
function LT:AddRollLines(tooltip, rolls, live)
	if type(rolls) ~= 'table' then return end
	tooltip:AddLine(' ')

	if rolls.allPassed then
		tooltip:AddLine(ALL_PASSED, TextRGB('red'))
		return
	end

	local list = type(rolls.list) == 'table' and rolls.list or {}
	local winner = list[rolls.winner]
	if not IsLine(winner) then winner = nil end
	local winnerRoll = winner and type(winner.roll) == 'number' and winner.roll

	for _, choice in ipairs(CHOICES) do
		local header
		for _, line in ipairs(list) do
			if IsLine(line) and choice.states[line.state] then
				if not header then
					tooltip:AddLine(choice.label, TextRGB(choice.color))
					header = true
				end

				local name = ClassColored(line.name, line.class)
				if line.state == STATE.NeedOffSpec then name = OffSpec(name) end
				if line == winner then name = name .. ' ' .. CHECK end

				-- A higher roll than the winner's on the same choice is one the game
				-- didn't count (a player who already won a copy). Blizzard hides those.
				local roll = type(line.roll) == 'number' and line.roll or nil
				if roll and winnerRoll and line ~= winner and line.state == winner.state and roll > winnerRoll then
					roll = nil
				end

				local r, g, b = 1, 1, 1
				if line == winner then r, g, b = TextRGB('green') end
				tooltip:AddDoubleLine('  ' .. name, roll and tostring(roll) or '', 1, 1, 1, r, g, b)
			end
		end
	end

	local passed = NameList(list, STATE.Pass)
	if passed then
		tooltip:AddLine(Colored('Pass: ', 'red') .. passed, 1, 1, 1, true)
	end

	if live and not winner then
		local nr, ng, nb = 1, .82, 0
		if NORMAL_FONT_COLOR then nr, ng, nb = NORMAL_FONT_COLOR:GetRGB() end

		local waiting = NameList(list, STATE.NoRoll)
		if waiting then
			tooltip:AddLine(WaitingOnPrefix() .. waiting, nr, ng, nb, true)
		end

		local leader = list[rolls.leader]
		if IsLine(leader) and type(leader.roll) == 'number' then
			tooltip:AddLine(CurrentLeader(rolls.tied, leader), nr, ng, nb)
		end
	end
end

------------------------------------
---- Feed entries ------------------
------------------------------------

local function Winner(rolls)
	local list = type(rolls) == 'table' and rolls.list
	local winner = type(list) == 'table' and list[rolls.winner]
	if IsLine(winner) then return winner end
end

-- The feed line's right side: the winner, class-coloured, or "All passed".
local function ResultText(rolls)
	if rolls.allPassed then return Colored(ALL_PASSED, 'red') end
	local winner = Winner(rolls)
	return winner and ClassColored(winner.name, winner.class) or ''
end

-- A roll result's feed entry, or nil while the item's data isn't cached.
-- `allowUncached` builds it anyway, named by the link's own coloured text.
-- Test mode builds its sample through this too.
function LT:BuildRollEntry(link, rolls, allowUncached)
	local name, _, quality, _, _, itemType, itemSubType, _, _, texture = C_Item.GetItemInfo(link)
	if name then
		local color = quality and st.config.profile.colors.item_quality[quality]
		if color then name = st.StringFormat:ColorString(name, color:GetRGB()) end
	elseif allowUncached then
		name = link
		_, itemType, itemSubType, _, texture = C_Item.GetItemInfoInstant(link)
	else
		return
	end

	return {
		name = name,
		icon = texture,
		link = link,
		type = 'Rolls',
		rightText = ResultText(rolls),
		rolls = rolls,
		itemType = itemType,
		itemSubType = itemSubType,
	}
end

local function ItemID(link)
	local id = link:match('item:(%d+)')
	return id and tonumber(id)
end
LT.ItemID = ItemID

-- Whether two links are the same item. The loot history's link and a chat
-- message's can differ in their trailing context fields, so the item ID
-- decides when the links aren't identical.
local function SameItem(a, b)
	a, b = PlainString(a), PlainString(b)
	if not (a and b) then return false end
	if a == b then return true end
	local id = ItemID(a)
	return id ~= nil and id == ItemID(b)
end

local function ShortName(name)
	return Ambiguate and Ambiguate(name, 'short') or name
end

-- Whether a loot message's looter is a roll's winner. Your own messages ("You
-- receive loot") have no looter and match a winner who is you; other players
-- match by name with the realm stripped on both sides.
local function IsLooterWinner(looter, winner)
	if not winner then return false end
	if looter == nil then return winner.isSelf == true end
	looter = PlainString(looter)
	return looter ~= nil and ShortName(looter) == ShortName(winner.name)
end

local function InFeed(info)
	for _, entry in ipairs(LT:GetAllItems()) do
		if entry == info then return true end
	end
	return false
end

-- The winner's loot message already in the feed (it came before the roll's
-- end): a Loot entry for the same item and player with a real time between
-- `from` and `to`. Takes the oldest such entry, the nearest to the roll.
local function FindLootEntry(link, winner, from, to)
	local found
	for _, info in ipairs(LT:GetAllItems()) do
		if info.type == 'Loot' and not info.test
			and type(info.when) == 'number' and info.when >= from and info.when <= to
			and SameItem(info.link, link) and IsLooterWinner(info.notSelf, winner) then
			found = info
		end
	end
	return found
end

-- Turns the winner's loot entry into the roll result where it stands, keeping
-- its count, looter and time.
local function FoldIntoLootEntry(entry, rolls)
	entry.type = 'Rolls'
	entry.rolls = rolls
	entry.rightText = ResultText(rolls)
	entry.looted = true
	LT:SaveFeedEntry(entry)
	LT:UpdateFeed()
end

local function OpenForLoot(info)
	tinsert(openRolls, { info = info, deadline = GetTime() + FOLD_WINDOW })
end

-- Adds a recorded drop to the feed: folded into the winner's loot message if
-- that came first, else as a new entry (live) or as history (found at load).
-- Returns 'added', 'uncached' (the item's data isn't in yet) or 'declined' (a
-- drop found at load that's older than everything in a full feed).
local function AddRollResult(result, allowUncached)
	local info = LT:BuildRollEntry(result.link, result.rolls, allowUncached)
	if not info then return 'uncached' end

	-- A live result's loot message comes within the window either side of now.
	-- One found at load could have come any time from the roll's start to its
	-- end (or to now, when the end isn't known).
	local from, to = result.when - FOLD_WINDOW, result.when + FOLD_WINDOW
	if result.restored then to = result.ends and result.ends + FOLD_WINDOW or time() end

	local winner = Winner(result.rolls)
	local loot = winner and FindLootEntry(result.link, winner, from, to)
	if loot then
		FoldIntoLootEntry(loot, result.rolls)
		info = loot
	elseif result.restored then
		info.when = result.when
		if not LT:InsertRestoredEntry(info) then return 'declined' end
		if winner then OpenForLoot(info) end
	else
		LT:LootFeedPush(info)
		if winner then OpenForLoot(info) end
	end
	entryByKey[result.key] = info
	return 'added'
end

-- A drop already recorded changed again: its entry takes the new rolls.
local function RefreshResult(key, drop)
	local info = entryByKey[key]
	if not info then return end
	info.rolls = Summarize(drop, true)
	local rightText = ResultText(info.rolls)
	local changed = rightText ~= info.rightText
	info.rightText = rightText
	LT:SaveFeedEntry(info)
	if changed then LT:UpdateFeed() end
end

-- Records a drop whose roll has ended, once. `restored`: found at load, so it
-- ended while the addon wasn't watching and goes in as history.
local function RecordDrop(encounterID, drop, restored)
	if type(drop) ~= 'table' then return end
	local key = DropKey(encounterID, drop)
	if not key then return end
	local recorded = RecordedDrops()

	if not HasEnded(drop) then
		-- A drop still being rolled has no result yet, so a key already in the
		-- set belongs to an older drop with the same encounter, slot and item. The
		-- same goes for a key declined at load.
		recorded[key] = nil
		declinedKeys[key] = nil
		return
	end
	if recorded[key] then
		RefreshResult(key, drop)
		return
	end
	if pendingKeys[key] or declinedKeys[key] or not SomeoneRolled(drop) then return end

	local result = {
		key = key,
		link = PlainString(drop.itemHyperlink),
		rolls = Summarize(drop, true),
		when = time(),
		restored = restored,
	}
	if restored then result.when, result.ends = EstimateWhen(drop) end

	local outcome = AddRollResult(result)
	if outcome == 'added' then recorded[key] = true end
	-- Declined: left unrecorded, so it can go in at a later load once the feed
	-- has room (after Clear history, say), but not as a fresh line this session.
	if outcome == 'declined' then declinedKeys[key] = true end
	if outcome ~= 'uncached' then return end

	-- The item isn't cached yet (say, a drop you weren't eligible for). The
	-- key is recorded once the entry is in, so a reload before then adds it at
	-- load instead.
	pendingKeys[key] = true
	tinsert(pending, result)
	if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(result.link) end
	LT:RegisterEvent('GET_ITEM_INFO_RECEIVED', 'OnRollItemInfo')
end

-- Item data came in: adds the pending results it completes. When the data for
-- a pending item came but the item still isn't known, it goes in by its link.
function LT:OnRollItemInfo(event, itemID)
	itemID = PlainNumber(itemID)
	local i = 1
	while pending[i] do
		local result = pending[i]
		local outcome = AddRollResult(result, itemID ~= nil and itemID == ItemID(result.link))
		if outcome ~= 'uncached' then
			tremove(pending, i)
			pendingKeys[result.key] = nil
			if outcome == 'added' then RecordedDrops()[result.key] = true end
			if outcome == 'declined' then declinedKeys[result.key] = true end
		else
			i = i + 1
		end
	end
	if not pending[1] then self:UnregisterEvent('GET_ITEM_INFO_RECEIVED') end
end

-- Called by LootFeedAddItem before it pushes an item. True when the message is
-- the winner's loot for a roll result already in the feed (the roll ended
-- first): that entry takes the message's count and looter instead.
function LT:AbsorbLootMessage(match)
	if self.pushingTest or not openRolls[1] then return false end
	local link, looter = PlainString(match.link), match.player
	if not link or (looter ~= nil and not PlainString(looter)) then return false end

	local now = GetTime()
	local i = 1
	while openRolls[i] do
		local open = openRolls[i]
		local info = open.info
		if now > open.deadline then
			tremove(openRolls, i)
		elseif SameItem(info.link, link) and IsLooterWinner(looter, Winner(info.rolls)) then
			tremove(openRolls, i)
			-- Clear history can have taken the entry away; then the message
			-- looks for another result, or is pushed as usual.
			if InFeed(info) then
				info.looted = true
				info.count = match.count
				info.notSelf = looter
				-- The loot itself is new, even for a result added at load, so the
				-- entry shows as a fresh line again.
				info.time = now
				self:SaveFeedEntry(info)
				self:UpdateFeed()
				return true
			end
		else
			i = i + 1
		end
	end
	return false
end

------------------------------------
---- Events ------------------------
------------------------------------

-- The roll bars show live choices from the same history, where they do.
local function RefreshRollBars()
	if LT.UpdateRollBars then LT:UpdateRollBars() end
end

function LT:OnLootHistoryUpdateDrop(event, encounterID, lootListKey)
	encounterID, lootListKey = PlainNumber(encounterID), PlainNumber(lootListKey)
	if encounterID and lootListKey then
		RecordDrop(encounterID, C_LootHistory.GetSortedInfoForDrop(encounterID, lootListKey), false)
	end
	RefreshRollBars()
end

-- An encounter's drops changed (new drops came in): the same per-drop handling,
-- so nothing depends on a drop update arriving for each one.
function LT:OnLootHistoryUpdateEncounter(event, encounterID)
	encounterID = PlainNumber(encounterID)
	if encounterID then
		for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}) do
			RecordDrop(encounterID, drop, false)
		end
	end
	RefreshRollBars()
end

-- Blizzard's history is gone, so every recorded or declined key is free to be reused.
function LT:OnLootHistoryClear()
	wipe(RecordedDrops())
	wipe(declinedKeys)
	RefreshRollBars()
end

-- Once at load. Keeps only the recorded keys still in Blizzard's history, then
-- adds every drop that ended and isn't recorded yet, oldest first, as history.
local function CatchUp()
	local live, drops = {}, {}
	for _, encounter in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
		local encounterID = type(encounter) == 'table' and PlainNumber(encounter.encounterID)
		if encounterID then
			for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}) do
				local key = type(drop) == 'table' and DropKey(encounterID, drop)
				if key then
					live[key] = true
					tinsert(drops, { encounterID = encounterID, drop = drop, start = PlainNumber(drop.startTime) or 0 })
				end
			end
		end
	end

	-- An empty history at load may only be one that isn't filled yet; pruning
	-- against it would forget every recorded drop and record them all again.
	local recorded = RecordedDrops()
	if next(live) then
		for key in pairs(recorded) do
			if not live[key] then recorded[key] = nil end
		end
	end

	-- Oldest first, so of two results for the same item and player, the older
	-- folds into the older loot message.
	table.sort(drops, function(a, b) return a.start < b.start end)
	for _, entry in ipairs(drops) do
		RecordDrop(entry.encounterID, entry.drop, true)
	end
end

-- Called at the end of InitializeLootFeed, once the feed and its restored
-- entries exist.
function LT:InitializeRollResults()
	if self.rollResultsReady or not C_LootHistory then return end
	self.rollResultsReady = true

	self:RegisterEvent('LOOT_HISTORY_UPDATE_DROP', 'OnLootHistoryUpdateDrop')
	self:RegisterEvent('LOOT_HISTORY_UPDATE_ENCOUNTER', 'OnLootHistoryUpdateEncounter')
	self:RegisterEvent('LOOT_HISTORY_CLEAR_HISTORY', 'OnLootHistoryClear')
	CatchUp()
end
