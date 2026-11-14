--[[
	The quest log's API, for SaftUI-Tracker's tests. Loaded at the end of
	game.lua. A fresh `stub.quests` is the game's quest log:

	  stub.quests = {
	    log = { entry, ... },   -- the quest log, top to bottom, headers among the quests
	    watched = { questID, ... }, -- the watch list, in the order tracked
	    focused = 0,            -- the super tracked (focused) quest, 0 for none
	    popups = { { id, kind } }, -- auto quest pop-ups; kind 'OFFER' or 'COMPLETE'
	    max = nil,              -- the most quests the log holds: nil is the client's own (Forever 40, retail 35)
	    titles = { [id] = title }, -- titles the quest cache has for quests not in the log (an offered quest's)
	  }
	  stub.money  -- GetMoney(), in copper
	  stub.real_zone_text -- GetRealZoneText()

	A header entry is { header = true, title, campaignID }. A quest entry is
	  { id, title, level, difficulty, frequency, task, bounty, hidden, auto,
	    campaignID, classification, overrides, calling, disabled, complete,
	    failed, ready, completion, objectives = { { text, type, finished,
	    numFulfilled, numRequired } }, percent, sequenced, money, time =
	    { total, elapsed }, timer, tag = { tagName, tagID, isElite }, elite,
	    item = { link, texture, charges, showWhenComplete, cooldown = { start,
	    duration, enable }, range }, inArea, distance = { sq, onContinent },
	    waypoint, pushable }
	where every field may be left out (the API gives what the game gives for a
	quest with none: false, 0 or nothing) and any value may be a secret value
	(tests/lib/secrets.lua): the stubs hand it on as it is and never compare or
	do arithmetic on one (the game would error). Two fields are the tests' own
	and stand for what the API works out: `difficulty` is the
	Enum.RelativeContentDifficulty that C_PlayerInfo.GetContentDifficultyQuestForPlayer
	gives (Fair by default), and `scaled`, if set, is QuestInfo.difficultyLevel
	(the level the player is shown, `level` by default).

	Where each function comes from. C_QuestLog's are in
	Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua, read on both
	branches of Gethe/wow-ui-source (`forever` and `live`) on 2026-11-14: the
	names, arguments, return shapes, Nilable and MayReturnNothing marks, and
	QuestInfo, QuestTagInfo, QuestObjectiveInfo and QuestTimerInfo. The two
	branches differ only in C_QuestLog.IsEliteQuest and C_QuestLog.GetQuestTimers
	(a list of QuestTimerInfo, { questID, questTimer }), which are Forever's
	alone, so stub.apply_client() drops them on retail (and in
	C_QuestLog.GetTrivialRange and a `range` field, which nothing here uses). Enum.QuestClassification (QuestInfoSharedDocumentation.lua),
	Enum.QuestFrequency (QuestLogDocumentation.lua),
	Constants.QuestWatchConsts.MAX_QUEST_WATCHES (QuestConstantsDocumentation.lua)
	and C_PlayerInfo, C_SuperTrack and C_Minimap's functions are from their
	own documentation files, the same on both. The old globals
	(GetQuestLogSpecialItemInfo and the rest) aren't in the generated
	documentation: their shapes are what Blizzard's own tracker
	(Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua,
	Blizzard_FrameXMLUtil/Mainline/QuestUtils.lua) and the Warcraft wiki have.
	GetDifficultyColor and QuestDifficultyColors are Blizzard_FrameXMLUtil/Mainline/DifficultyUtil.lua
	and Blizzard_FrameXMLBase/Constants.lua; GetMoneyString is
	Blizzard_SharedXML/FormattingUtil.lua.

	Every argument is checked as in game: a questID or index that isn't a
	number errors with the call's Usage line.

	Not modelled: quest POIs, the quest cache, task quests apart from the flag
	(GetNumWorldQuestWatches is 0, IsWorldQuest follows the classification),
	the watch types (a world quest's watch). A header entry's `collapsed` is
	only its QuestInfo.isCollapsed: GetInfo and GetNumQuestLogEntries return
	every entry, a collapsed header's quests included, as Blizzard's own
	quest log reads them (QuestLogQuests_ShouldShowQuestButton hides them by
	info.header.isCollapsed); that this is what the game does is read from
	source, not yet confirmed in game.

	The log's size: C_QuestLog.GetMaxNumQuestsCanAccept is on both clients.
	Forever's QuestConstantsDocumentation.lua has
	QuestLogConstsMainlineCamelot.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT = 40 (the
	stub's Constants has it on Forever only); retail's has no constant and the
	stub says 35, the figure its log has had (not in the documentation).
]]

stub.quests = { log = {}, watched = {}, focused = 0, popups = {}, titles = {} }
stub.money = 0
stub.real_zone_text = ''

-- Enum.QuestClassification: QuestInfoSharedDocumentation.lua, both clients.
-- Enum.QuestFrequency: QuestLogDocumentation.lua. Enum.RelativeContentDifficulty:
-- QuestConstantsDocumentation.lua. Enum.UIMapType is here only where
-- blizzard.lua hasn't made it yet (it replaces this table's when it loads).
Enum = Enum or {}
Enum.QuestClassification = {
	Important = 0, Legendary = 1, Campaign = 2, Calling = 3, Meta = 4, Recurring = 5,
	Questline = 6, Normal = 7, BonusObjective = 8, Threat = 9, WorldQuest = 10,
}
Enum.QuestFrequency = { Default = 0, Daily = 1, Weekly = 2, ResetByScheduler = 3 }
Enum.RelativeContentDifficulty = { Trivial = 0, Easy = 1, Fair = 2, Difficult = 3, Impossible = 4 }
Enum.UIMapType = Enum.UIMapType
	or { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 }

Constants = Constants or {}
Constants.QuestWatchConsts = { MAX_QUEST_WATCHES = 25 }
-- Forever's only (QuestConstantsDocumentation.lua); stub.apply_client() drops it on retail.
Constants.QuestLogConstsMainlineCamelot = { MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT = 40 }

-- Blizzard's global strings the tracker reads (English).
DAILY = 'Daily'
WEEKLY = 'Weekly'
FAILED = 'Failed'
QUEST_WATCH_QUEST_READY = 'Ready for turn-in'
QUEST_WATCH_QUEST_COMPLETE = 'Quest complete'
QUEST_WATCH_CLICK_TO_COMPLETE = 'Click to complete'

-- Blizzard_FrameXMLBase/Constants.lua (forever branch).
QuestDifficultyColors = {
	impossible = { r = 1.00, g = 0.10, b = 0.10, font = 'QuestDifficulty_Impossible' },
	verydifficult = { r = 1.00, g = 0.50, b = 0.25, font = 'QuestDifficulty_VeryDifficult' },
	difficult = { r = 1.00, g = 0.82, b = 0.00, font = 'QuestDifficulty_Difficult' },
	standard = { r = 0.25, g = 0.75, b = 0.25, font = 'QuestDifficulty_Standard' },
	trivial = { r = 0.50, g = 0.50, b = 0.50, font = 'QuestDifficulty_Trivial' },
	header = { r = 0.70, g = 0.70, b = 0.70, font = 'QuestDifficulty_Header' },
	disabled = { r = 0.498, g = 0.498, b = 0.498, font = 'QuestDifficulty_Impossible' },
}
QuestDifficultyHighlightColors = {
	impossible = { r = 1.00, g = 0.40, b = 0.40, font = 'QuestDifficulty_Impossible' },
	verydifficult = { r = 1.00, g = 0.75, b = 0.44, font = 'QuestDifficulty_VeryDifficult' },
	difficult = { r = 1.00, g = 1.00, b = 0.10, font = 'QuestDifficulty_Difficult' },
	standard = { r = 0.43, g = 0.93, b = 0.43, font = 'QuestDifficulty_Standard' },
	trivial = { r = 0.70, g = 0.70, b = 0.70, font = 'QuestDifficulty_Trivial' },
	header = { r = 1.00, g = 1.00, b = 1.00, font = 'QuestDifficulty_Header' },
	disabled = { r = 0.60, g = 0.60, b = 0.60, font = 'QuestDifficulty_Impossible' },
}

C_QuestLog = C_QuestLog or {}
C_PlayerInfo = C_PlayerInfo or {}
C_SuperTrack = C_SuperTrack or {}
C_Minimap = C_Minimap or {}
QuestUtil = QuestUtil or {}

do
	local Q = C_QuestLog
	-- The defaults a quest gets, kept here so a test taking an enum away to
	-- play a client without it doesn't break the stubs.
	local DEFAULT_FREQUENCY, NORMAL_CLASSIFICATION = Enum.QuestFrequency.Default, Enum.QuestClassification.Normal
	local FAIR, WORLD_QUEST = Enum.RelativeContentDifficulty.Fair, Enum.QuestClassification.WorldQuest

	-- A value or a default: false for a missing boolean, as the game's
	-- structures never leave one nil. A secret is not nil, so it goes on.
	local function bool(value)
		if value == nil then return false end
		return value
	end

	-- The checks of the game's argument parser: a number where a number is
	-- expected, else the call's Usage error, raised at the caller's caller.
	local function number_arg(value, usage, level)
		if type(value) ~= 'number' then error('Usage: ' .. usage, level or 3) end
		return value
	end

	-- The quest (not a header) with this ID, and its log index.
	local function find_quest(questID)
		for index, entry in ipairs(stub.quests.log) do
			if not entry.header and entry.id == questID then return entry, index end
		end
	end

	local function quest_arg(questID, usage)
		number_arg(questID, usage, 4)
		return (find_quest(questID))
	end

	local function fire(event, ...)
		if stub.fire_event then stub.fire_event(event, ...) end
	end

	local function watch_index(questID)
		for i, id in ipairs(stub.quests.watched) do
			if id == questID then return i end
		end
	end

	function Q.GetNumQuestWatches() return #stub.quests.watched end

	function Q.GetQuestIDForQuestWatchIndex(questWatchIndex)
		number_arg(questWatchIndex, 'local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(questWatchIndex)')
		return stub.quests.watched[questWatchIndex]
	end

	function Q.GetLogIndexForQuestID(questID)
		number_arg(questID, 'local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)')
		local _, index = find_quest(questID)
		return index
	end

	-- QuestInfo, a new table each call. A header has questID 0 and level 0.
	function Q.GetInfo(questLogIndex)
		number_arg(questLogIndex, 'local info = C_QuestLog.GetInfo(questLogIndex)')
		local entry = stub.quests.log[questLogIndex]
		if not entry then return nil end
		local header = entry.header == true
		local level = entry.level
		if level == nil then level = 0 end
		local scaled = entry.scaled
		if scaled == nil then scaled = level end
		local frequency = entry.frequency
		if frequency == nil then frequency = DEFAULT_FREQUENCY end
		local classification = entry.classification
		if classification == nil then classification = NORMAL_CLASSIFICATION end
		return {
			title = entry.title,
			questLogIndex = questLogIndex,
			questID = header and 0 or entry.id,
			campaignID = entry.campaignID,
			level = header and 0 or level,
			difficultyLevel = header and 0 or scaled,
			suggestedGroup = 0,
			frequency = frequency,
			isHeader = header,
			useMinimalHeader = false,
			sortAsNormalQuest = false,
			isCollapsed = header and entry.collapsed == true or false,
			startEvent = false,
			isTask = bool(entry.task),
			isBounty = bool(entry.bounty),
			isStory = false,
			isScaling = false,
			isOnMap = false,
			hasLocalPOI = false,
			isHidden = bool(entry.hidden),
			isAutoComplete = bool(entry.auto),
			overridesSortOrder = bool(entry.overrides),
			readyForTranslation = true,
			isInternalOnly = false,
			isAbandonOnDisable = false,
			headerSortKey = nil,
			questClassification = classification,
		}
	end

	-- The log index of the header the quest sits under: the nearest header
	-- above it. Nothing for a quest above every header or not in the log.
	function Q.GetHeaderIndexForQuest(questID)
		number_arg(questID, 'local index = C_QuestLog.GetHeaderIndexForQuest(questID)')
		local _, index = find_quest(questID)
		if not index then return nil end
		for i = index - 1, 1, -1 do
			if stub.quests.log[i].header then return i end
		end
	end

	-- MayReturnNothing: nothing for a quest that isn't in the log, else a new
	-- list of QuestObjectiveInfo (empty for a quest with no objectives).
	function Q.GetQuestObjectives(questID)
		local entry = quest_arg(questID, 'local objectives = C_QuestLog.GetQuestObjectives(questID)')
		if not entry then return end
		local list = {}
		for i, objective in ipairs(entry.objectives or {}) do
			list[i] = {
				text = objective.text, type = objective.type, finished = bool(objective.finished),
				numFulfilled = objective.numFulfilled or 0, numRequired = objective.numRequired or 0,
				objectiveType = objective.objectiveType,
			}
		end
		return list
	end

	function Q.IsComplete(questID)
		local entry = quest_arg(questID, 'local isComplete = C_QuestLog.IsComplete(questID)')
		return bool(entry and entry.complete)
	end
	function Q.IsFailed(questID)
		local entry = quest_arg(questID, 'local isFailed = C_QuestLog.IsFailed(questID)')
		return bool(entry and entry.failed)
	end
	-- The result is Nilable in the documentation; the game gives a boolean.
	function Q.ReadyForTurnIn(questID)
		local entry = quest_arg(questID, 'local readyForTurnIn = C_QuestLog.ReadyForTurnIn(questID)')
		return bool(entry and entry.ready)
	end

	-- questID is Nilable (the selected quest then; none is selected here, so 0).
	function Q.GetRequiredMoney(questID)
		if questID ~= nil then number_arg(questID, 'local requiredMoney = C_QuestLog.GetRequiredMoney([questID])') end
		local entry = questID ~= nil and find_quest(questID)
		return entry and entry.money or 0
	end

	-- MayReturnNothing: totalTime, elapsedTime, in seconds.
	function Q.GetTimeAllowed(questID)
		local entry = quest_arg(questID, 'local totalTime, elapsedTime = C_QuestLog.GetTimeAllowed(questID)')
		local time = entry and entry.time
		if not time then return end
		return time.total, time.elapsed
	end

	-- QuestTagInfo or nil (Nilable), a new table each call.
	function Q.GetQuestTagInfo(questID)
		local entry = quest_arg(questID, 'local info = C_QuestLog.GetQuestTagInfo(questID)')
		local tag = entry and entry.tag
		if not tag then return nil end
		return { tagName = tag.tagName, tagID = tag.tagID or 0, isElite = tag.isElite }
	end

	function Q.IsQuestDisabledForSession(questID)
		local entry = quest_arg(questID, 'local isDisabled = C_QuestLog.IsQuestDisabledForSession(questID)')
		return bool(entry and entry.disabled)
	end
	function Q.IsQuestCalling(questID)
		local entry = quest_arg(questID, 'local isCalling = C_QuestLog.IsQuestCalling(questID)')
		return bool(entry and entry.calling)
	end

	-- MayReturnNothing: distanceSq, onContinent.
	function Q.GetDistanceSqToQuest(questID)
		local entry = quest_arg(questID, 'local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)')
		local distance = entry and entry.distance
		if not distance then return end
		return distance.sq, bool(distance.onContinent)
	end

	-- MayReturnNothing.
	function Q.GetNextWaypointText(questID)
		local entry = quest_arg(questID, 'local waypointText = C_QuestLog.GetNextWaypointText(questID)')
		if not entry or entry.waypoint == nil then return end
		return entry.waypoint
	end

	-- numShownEntries (every entry: no header is collapsed here), numQuests
	-- (the quests that aren't task quests).
	function Q.GetNumQuestLogEntries()
		local quests = 0
		for _, entry in ipairs(stub.quests.log) do
			if not entry.header and not entry.task then quests = quests + 1 end
		end
		return #stub.quests.log, quests
	end

	function Q.GetMaxNumQuestsCanAccept()
		return stub.quests.max or (stub.interface == 16001 and 40 or 35)
	end

	-- Nilable; from the quest cache, so any quest the cache has: one in the
	-- log, or one in stub.quests.titles (an offered quest, not in the log
	-- yet). Headers' titles can't be found this way.
	function Q.GetTitleForQuestID(questID)
		local entry = quest_arg(questID, 'local title = C_QuestLog.GetTitleForQuestID(questID)')
		if entry then return entry.title end
		return stub.quests.titles[questID]
	end

	-- QuestLogDocumentation.lua: whether the quest is a bounty or a task quest.
	function Q.IsQuestBounty(questID)
		local entry = quest_arg(questID, 'local isBounty = C_QuestLog.IsQuestBounty(questID)')
		return bool(entry and entry.bounty)
	end
	function Q.IsQuestTask(questID)
		local entry = quest_arg(questID, 'local isTask = C_QuestLog.IsQuestTask(questID)')
		return bool(entry and entry.task)
	end

	function Q.IsPushableQuest(questID)
		local entry = quest_arg(questID, 'local isPushable = C_QuestLog.IsPushableQuest(questID)')
		return bool(entry and entry.pushable)
	end

	-- wasWatched: true when the quest is on the watch list afterwards; false
	-- for a quest not in the log or with the list full (the game's 25). The
	-- list changing fires QUEST_WATCH_LIST_CHANGED(questID, added).
	function Q.AddQuestWatch(questID)
		local entry = quest_arg(questID, 'local wasWatched = C_QuestLog.AddQuestWatch(questID)')
		if not entry then return false end
		if watch_index(questID) then return true end
		if #stub.quests.watched >= Constants.QuestWatchConsts.MAX_QUEST_WATCHES then return false end
		table.insert(stub.quests.watched, questID)
		fire('QUEST_WATCH_LIST_CHANGED', questID, true)
		return true
	end

	-- wasRemoved: true when the quest was on the list.
	function Q.RemoveQuestWatch(questID)
		number_arg(questID, 'local wasRemoved = C_QuestLog.RemoveQuestWatch(questID)')
		local index = watch_index(questID)
		if not index then return false end
		table.remove(stub.quests.watched, index)
		fire('QUEST_WATCH_LIST_CHANGED', questID, false)
		return true
	end

	-- World quest watches aren't modelled.
	function Q.GetNumWorldQuestWatches() return 0 end

	-- Blizzard decides this from the quest's tag; here the classification.
	function Q.IsWorldQuest(questID)
		local entry = quest_arg(questID, 'local isWorldQuest = C_QuestLog.IsWorldQuest(questID)')
		return entry ~= nil and entry.classification == WORLD_QUEST
	end

	-- Forever only (its documentation has them, retail's doesn't).
	function Q.IsEliteQuest(questID)
		local entry = quest_arg(questID, 'local isEliteQuest = C_QuestLog.IsEliteQuest(questID)')
		return bool(entry and entry.elite)
	end
	-- QuestTimerInfo: { questID, questTimer } for each timed quest, in log
	-- order; the time left, in seconds.
	function Q.GetQuestTimers()
		local timers = {}
		for _, entry in ipairs(stub.quests.log) do
			if not entry.header and entry.timer ~= nil then
				timers[#timers + 1] = { questID = entry.id, questTimer = entry.timer }
			end
		end
		return timers
	end

	-- PlayerInfoDocumentation.lua: an Enum.RelativeContentDifficulty.
	function C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID)
		local entry = quest_arg(questID, 'local difficulty = C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID)')
		local difficulty = entry and entry.difficulty
		if difficulty == nil then difficulty = FAIR end
		return difficulty
	end

	-- SuperTrackManagerDocumentation.lua. The result is Nilable; the game
	-- gives 0 for none, and so does stub.quests.focused.
	function C_SuperTrack.GetSuperTrackedQuestID() return stub.quests.focused end
	function C_SuperTrack.SetSuperTrackedQuestID(questID)
		number_arg(questID, 'C_SuperTrack.SetSuperTrackedQuestID(questID)')
		if stub.quests.focused == questID then return end
		stub.quests.focused = questID
		fire('SUPER_TRACKING_CHANGED')
	end

	-- MinimapDocumentation.lua.
	function C_Minimap.IsInsideQuestBlob(questID)
		local entry = quest_arg(questID, 'local isInside = C_Minimap.IsInsideQuestBlob(questID)')
		return bool(entry and entry.inArea)
	end

	-- QuestUtils.lua: the icon of an active quest, as an (asset, isAtlas)
	-- pair. Only the plain cases (a finished quest's gossip icon, a side
	-- quest in progress); campaign, recurring, legendary and the rest aren't
	-- modelled.
	function QuestUtil.GetQuestIconActiveForQuestID(questID, isComplete)
		number_arg(questID, 'local asset, isAtlas = QuestUtil.GetQuestIconActiveForQuestID(questID, isComplete, ...)')
		if isComplete == nil then isComplete = Q.IsComplete(questID) end
		if isComplete then return 'Interface/GossipFrame/ActiveQuestIcon', false end
		return 'SideInProgressquesticon', true
	end
	-- Blizzard's own (QuestUtils.lua, Mainline), over the old global below.
	function QuestUtil.QuestShowsItemByIndex(questLogIndex, isQuestComplete)
		if not questLogIndex then return false end
		local _, item, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
		return item and (not isQuestComplete or showItemWhenComplete)
	end

	-- The old globals, by quest log index: nothing for a header or an index
	-- with no quest, and for a quest with no item.
	local function item_of(questLogIndex, usage)
		number_arg(questLogIndex, usage)
		local entry = stub.quests.log[questLogIndex]
		return entry and not entry.header and entry.item or nil
	end

	-- link, item (the icon's texture), charges, showItemWhenComplete.
	function GetQuestLogSpecialItemInfo(questLogIndex)
		local item = item_of(questLogIndex, 'local link, item, charges, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)')
		if not item then return end
		return item.link, item.texture, item.charges or 0, bool(item.showWhenComplete)
	end
	-- start, duration, enable (the cooldown's).
	function GetQuestLogSpecialItemCooldown(questLogIndex)
		local item = item_of(questLogIndex, 'local start, duration, enable = GetQuestLogSpecialItemCooldown(questLogIndex)')
		if not item then return end
		local cooldown = item.cooldown or {}
		return cooldown.start or 0, cooldown.duration or 0, cooldown.enable == nil and 1 or cooldown.enable
	end
	-- 1 in range, 0 out of range, nil for an item with no range.
	function IsQuestLogSpecialItemInRange(questLogIndex)
		local item = item_of(questLogIndex, 'local inRange = IsQuestLogSpecialItemInRange(questLogIndex)')
		return item and item.range or nil
	end

	-- The text of a finished quest's completion, or nil.
	function GetQuestLogCompletionText(questLogIndex)
		number_arg(questLogIndex, 'local text = GetQuestLogCompletionText(questLogIndex)')
		local entry = stub.quests.log[questLogIndex]
		return entry and not entry.header and entry.completion or nil
	end
	function GetQuestProgressBarPercent(questID)
		local entry = quest_arg(questID, 'local percent = GetQuestProgressBarPercent(questID)')
		return entry and entry.percent or 0
	end
	function IsQuestSequenced(questID)
		local entry = quest_arg(questID, 'local isSequenced = IsQuestSequenced(questID)')
		return bool(entry and entry.sequenced)
	end
	function GetNumAutoQuestPopUps() return #stub.quests.popups end
	-- questID, popUpType ('OFFER' or 'COMPLETE'); nothing past the last.
	function GetAutoQuestPopUp(index)
		number_arg(index, 'local questID, popUpType = GetAutoQuestPopUp(index)')
		local popup = stub.quests.popups[index]
		if not popup then return end
		return popup.id, popup.kind
	end
	-- The chat link of a quest in the log, nil for one that isn't.
	function GetQuestLink(questID)
		local entry = quest_arg(questID, 'local link = GetQuestLink(questID)')
		if not entry or (issecretvalue and issecretvalue(entry.title)) then return nil end
		return ('|cffffff00|Hquest:%d:%d|h[%s]|h|r'):format(questID, tonumber(entry.level) or 0, tostring(entry.title))
	end

	function GetMoney() return stub.money end
	-- Blizzard_SharedXML/FormattingUtil.lua: the gold, silver and copper
	-- amounts, each with its icon, left out when 0 (copper only when nothing
	-- else shows), separated by a space.
	function GetMoneyString(money)
		number_arg(money, 'local text = GetMoneyString(money [, separateThousands, checkGoldThreshold, showZeroAsGold, color])')
		local gold = math.floor(money / 10000)
		local silver = math.floor((money - gold * 10000) / 100)
		local copper = math.floor(money % 100)
		local parts = {}
		if gold > 0 then parts[#parts + 1] = gold .. '|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t' end
		if silver > 0 then parts[#parts + 1] = silver .. '|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:2:0|t' end
		if copper > 0 or #parts == 0 then parts[#parts + 1] = copper .. '|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:2:0|t' end
		return table.concat(parts, ' ')
	end

	-- Two colors: the plain one and its highlight (DifficultyUtil.lua). The
	-- tables are the game's own, shared.
	function GetDifficultyColor(difficulty)
		local names = { [0] = 'trivial', 'standard', 'difficult', 'verydifficult', 'impossible' }
		local name = names[difficulty] or 'difficult'
		return QuestDifficultyColors[name], QuestDifficultyHighlightColors[name]
	end

	function GetRealZoneText() return stub.real_zone_text end
end
