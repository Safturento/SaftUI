-- Roll results in the loot feed. C_LootHistory keeps the group-loot drops of
-- the session: who chose what, their rolls, and the winner. When a drop's roll
-- ends, it gets one feed entry (type 'Rolls') naming the winner, and hovering
-- the entry lists everyone's rolls (LT:AddRollLines). The winner's own loot
-- message is folded into that entry rather than making a second one, whichever
-- of the two arrives first.
--
-- Recorded drops: st.config.char.loot.drops is a saved set of the drops that
-- already have an entry, so a reload never adds one twice. At load, keys whose
-- encounter is in Blizzard's history but whose drop isn't are dropped (a later
-- drop could reuse them), and a drop that ended while the addon wasn't
-- watching (a roll that ended during a reload) is added then, as history
-- rather than a fresh line.
--
-- Nothing secret is kept or compared: every value read from C_LootHistory goes
-- through the Plain* checks first.

local st = SaftUI
local LT = st.Loot

-- C_LootHistory's drops are read in loothistory.lua, which loads first.
local STATE = LT.ROLL_STATE
local history = LT.loothistory
local DropKey, HasEnded, SomeoneRolled = history.DropKey, history.HasEnded, history.SomeoneRolled
local EstimateWhen, Summarize, RecordedDrops = history.EstimateWhen, history.Summarize, history.RecordedDrops

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
	{ label = 'Need', color = 'need', states = { [STATE.NeedMainSpec] = true, [STATE.NeedOffSpec] = true } },
	{ label = 'Transmog', color = 'transmog', states = { [STATE.Transmog] = true } },
	{ label = 'Greed', color = 'greed', states = { [STATE.Greed] = true } },
}

local openRolls = {} -- results still waiting for the winner's loot message
local pending = {}   -- ended drops waiting for their item's data
local pendingKeys = {}
local declinedKeys = {} -- found at load with no room in the feed; retried next load
-- The entry each drop recorded this session went into, by its key, so later
-- updates to the drop (a roll number arriving after the winner) reach it.
local entryByKey = setmetatable({}, { __mode = 'v' })

------------------------------------
---- Tooltip lines -----------------
------------------------------------

local function Colored(text, key)
	return st.StringFormat:ColorString(text, st:Color('loot', key):GetRGB())
end

local function ClassColored(name, class)
	-- The profile's class colors (the Colors tab's), else Blizzard's.
	local color = type(class) == 'string'
		and (st.config.profile.colors.class[class] or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
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
		tooltip:AddLine(ALL_PASSED, st:Color('loot', 'pass'):GetRGB())
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
					tooltip:AddLine(choice.label, st:Color('loot', choice.color):GetRGB())
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
				if line == winner then r, g, b = st:Color('text', 'success'):GetRGB() end
				tooltip:AddDoubleLine('  ' .. name, roll and tostring(roll) or '', 1, 1, 1, r, g, b)
			end
		end
	end

	local passed = NameList(list, STATE.Pass)
	if passed then
		tooltip:AddLine(Colored('Pass: ', 'pass') .. passed, 1, 1, 1, true)
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
	if rolls.allPassed then return Colored(ALL_PASSED, 'pass') end
	local winner = Winner(rolls)
	return winner and ClassColored(winner.name, winner.class) or ''
end

-- A roll result's feed entry, or nil while the item's data isn't cached.
-- `allowUncached` builds it anyway, named by the link's own coloured text.
-- Test mode builds its sample through this too.
function LT:BuildRollEntry(link, rolls, allowUncached)
	local name, _, quality, _, _, itemType, itemSubType, _, _, texture = C_Item.GetItemInfo(link)
	local plain
	if name then
		-- The plain name and quality are kept: the line colors the name as it
		-- draws (LT.FeedItemName), so a changed Item quality color reaches it.
		plain = name
		if quality then name = LT.FeedItemName({ plain = plain, quality = quality }) end
	elseif allowUncached then
		name = link
		_, itemType, itemSubType, _, texture = C_Item.GetItemInfoInstant(link)
	else
		return
	end

	return {
		name = name,
		plain = plain,
		quality = plain and quality or nil,
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
	a, b = st.PlainString(a), st.PlainString(b)
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
	looter = st.PlainString(looter)
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
		link = st.PlainString(drop.itemHyperlink),
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
	itemID = st.PlainNumber(itemID)
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
	local link, looter = st.PlainString(match.link), match.player
	if not link or (looter ~= nil and not st.PlainString(looter)) then return false end

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
	encounterID, lootListKey = st.PlainNumber(encounterID), st.PlainNumber(lootListKey)
	if encounterID and lootListKey then
		RecordDrop(encounterID, C_LootHistory.GetSortedInfoForDrop(encounterID, lootListKey), false)
	end
	RefreshRollBars()
end

-- An encounter's drops changed (new drops came in): the same per-drop handling,
-- so nothing depends on a drop update arriving for each one.
function LT:OnLootHistoryUpdateEncounter(event, encounterID)
	encounterID = st.PlainNumber(encounterID)
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

-- Once at load. Forgets the recorded keys Blizzard's history no longer has,
-- then adds every drop that ended and isn't recorded yet, oldest first, as
-- history.
local function CatchUp()
	local live, liveEncounters, drops = {}, {}, {}
	for _, encounter in ipairs(C_LootHistory.GetAllEncounterInfos() or {}) do
		local encounterID = type(encounter) == 'table' and st.PlainNumber(encounter.encounterID)
		if encounterID then
			for _, drop in ipairs(C_LootHistory.GetSortedDropsForEncounter(encounterID) or {}) do
				local key = type(drop) == 'table' and DropKey(encounterID, drop)
				if key then
					live[key] = true
					liveEncounters[tostring(encounterID)] = true
					tinsert(drops, { encounterID = encounterID, drop = drop, start = st.PlainNumber(drop.startTime) or 0 })
				end
			end
		end
	end

	-- The history may be only partly filled when it's read at load, so a key
	-- goes only when its encounter is there (with its drops) and its drop isn't.
	-- Keys of encounters that aren't there are kept: forgetting them would
	-- record those drops again once their encounter comes in. With no encounter
	-- there at all (an empty history), nothing is pruned.
	local recorded = RecordedDrops()
	if next(liveEncounters) then
		for key in pairs(recorded) do
			local encounter = type(key) == 'string' and key:match('^(%-?%d+):')
			if encounter and liveEncounters[encounter] and not live[key] then
				recorded[key] = nil
			end
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
