--[[
	The quest log's API, for SaftUI-Tracker's tests. Loaded at the end of
	game.lua. A fresh `stub.quests` is the game's quest log:

	  stub.quests = {
	    log = { entry, ... },   -- the quest log, top to bottom, headers among the quests
	    watched = { questID, ... }, -- the watch list, in the order tracked
	    focused = 0,            -- the super tracked (focused) quest, 0 for none
	    popups = { { id, kind } }, -- auto quest pop-ups; kind 'OFFER' or 'COMPLETE'
	    max = nil,              -- the most quests the log holds: nil is the client's own (Forever 40, retail 35)
	    shown = nil,            -- what ShowQuestOffer and ShowQuestComplete were asked, 'offer:<id>' / 'complete:<id>', in order
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
-- What Blizzard's tracker's sections read, for SaftUI-Tracker's section probes
-- (the stubs are at the end of this file):
--   stub.probes = {
--     scenario = { name, stage, stages, flags, xp, money, type, texture, id }, -- C_Scenario.GetInfo; stages 0 is no scenario
--     challenge = false,       -- C_ChallengeMode.IsChallengeModeActive()
--     tasks = { questID, ... }, -- GetTasksTable(), the area's task quests in order
--     task_info = { [questID] = { inArea, onMap, objectives, name, asObjective } }, -- GetTaskInfo
--     watched_tasks = { [questID] = true }, -- a task quest on the watch list
--     world = { [questID] = true }, -- the task quests that are world quests (C_QuestLog.IsWorldQuest)
--     world_watches = 0,       -- C_QuestLog.GetNumWorldQuestWatches()
--     tracked = { [Enum.ContentTrackingType] = { id, ... } }, -- C_ContentTracking.GetTrackedIDs
--     achievements = { [id] = { earned = bool } }, -- GetAchievementInfo's 13th return
--     recipes = { normal = { id }, recraft = { id } }, -- C_TradeSkillUI.GetRecipesTracked(isRecraft)
--     perks = { ids = {}, info = { [id] = { completed } } },     -- C_PerksActivities
--     initiative = { ids = {}, info = { [id] = { completed } } }, -- C_NeighborhoodInitiative
--   }
-- A namespace or function a test sets to nil plays a client without it.
stub.probes = { watched_tasks = {}, world = {}, world_watches = 0, task_info = {}, tasks = {}, tracked = {}, achievements = {} }
-- What the clicks and the menu of SaftUI's tracker ask of the game (see "The
-- clicks" below): the calls of the Blizzard functions they run, in order, each
-- 'Name:arg,arg'; which modified clicks are held (stub.modified.QUESTWATCHTOGGLE
-- and .CHATLINK, Shift by default in the game); whether a chat edit box is open
-- (stub.chat_open) and what was put into it (stub.chat_inserted, links); whether
-- the player is in the new player experience (stub.npe_restricted, which keeps a
-- quest from being untracked).
stub.quest_calls = {}
stub.modified = {}
stub.chat_open = false
stub.chat_inserted = {}
stub.npe_restricted = false
-- The game's red error line (UIErrorsFrame:AddMessage), the messages in order as
-- { text, r, g, b }.
stub.ui_errors = {}
UIErrorsFrame = { AddMessage = function(_, text, r, g, b) table.insert(stub.ui_errors, { text, r, g, b }) end }
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
-- QuestWatchType: QuestLogDocumentation.lua, both branches.
Enum.QuestWatchType = { Automatic = 0, Manual = 1 }
-- ContentTrackingType: ContentTrackingTypesDocumentation.lua, both branches.
Enum.ContentTrackingType = { Appearance = 0, Mount = 1, Achievement = 2, Decor = 3 }
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
-- The quest menu's (Blizzard_QuestObjectiveTracker.lua names them; TRACK_QUEST is
-- the quest log's own menu's, Mainline/QuestMapFrame.lua), with the game's own
-- English: wago.tools GlobalStrings at Forever 1.60.1.70888 and retail
-- 12.1.5.70783, the same on both. OBJECTIVES_WATCH_TOO_MANY is what Blizzard's
-- QuestMapQuestOptions_TrackQuest shows (UIErrorsFrame) for a 26th watch.
SUPER_TRACK_QUEST = 'Focus'
STOP_SUPER_TRACK_QUEST = 'Remove Focus'
OBJECTIVES_VIEW_IN_QUESTLOG = 'Open Quest Details'
OBJECTIVES_HIDE_VIEW_IN_QUESTLOG = 'Close Quest Details'
OBJECTIVES_SHOW_QUEST_MAP = 'Open Quest Map'
OBJECTIVES_STOP_TRACKING = 'Untrack'
SHARE_QUEST = 'Share Quest'
ABANDON_QUEST_ABBREV = 'Abandon'
TRACK_QUEST = 'Track Quest'
OBJECTIVES_WATCH_TOO_MANY = "You can't track any more quests."

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
	-- One call of a Blizzard function a click or a menu entry runs, put in
	-- stub.quest_calls as 'Name:arg,arg' (a test reads what was and wasn't called).
	local function record(name, ...)
		local args = { ... }
		for i = 1, select('#', ...) do args[i] = tostring(args[i]) end
		table.insert(stub.quest_calls, name .. ':' .. table.concat(args, ','))
	end
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

	-- A world quest's watch is the probes' (stub.probes.world_watches, below); no
	-- quest of the log is a world quest watch.
	function Q.GetNumWorldQuestWatches() return stub.probes.world_watches end

	-- watchType: Enum.QuestWatchType (Automatic 0, Manual 1, QuestLogDocumentation.lua,
	-- both branches), nil for a quest that isn't on the watch list.
	function Q.GetQuestWatchType(questID)
		number_arg(questID, 'local watchType = C_QuestLog.GetQuestWatchType(questID)')
		if watch_index(questID) or stub.probes.watched_tasks[questID] then return Enum.QuestWatchType.Manual end
		return nil
	end

	-- Blizzard decides this from the quest's tag; here the classification.
	function Q.IsWorldQuest(questID)
		local entry = quest_arg(questID, 'local isWorldQuest = C_QuestLog.IsWorldQuest(questID)')
		-- (a task quest of the area is in no log: the probes' stub.probes.world says)
		return (entry ~= nil and entry.classification == WORLD_QUEST) or stub.probes.world[questID] == true
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
	-- The offer and turn-in frames a popup's click opens (Blizzard's functions,
	-- which open the quest frame through the game's own events) and the
	-- removal of the popup: only recorded, in stub.quests.shown, each as
	-- 'offer:<id>' or 'complete:<id>'; RemoveAutoQuestPopUp drops the popup.
	function ShowQuestOffer(questID)
		number_arg(questID, 'ShowQuestOffer(questID)')
		record('ShowQuestOffer', questID)
		stub.quests.shown = stub.quests.shown or {}
		table.insert(stub.quests.shown, 'offer:' .. questID)
	end
	function ShowQuestComplete(questID)
		number_arg(questID, 'ShowQuestComplete(questID)')
		record('ShowQuestComplete', questID)
		stub.quests.shown = stub.quests.shown or {}
		table.insert(stub.quests.shown, 'complete:' .. questID)
	end
	function RemoveAutoQuestPopUp(questID)
		number_arg(questID, 'RemoveAutoQuestPopUp(questID)')
		record('RemoveAutoQuestPopUp', questID)
		for index, popup in ipairs(stub.quests.popups) do
			if popup.id == questID then table.remove(stub.quests.popups, index) break end
		end
	end
	-- The chat link of a quest in the log, nil for one that isn't.
	function GetQuestLink(questID)
		local entry = quest_arg(questID, 'local link = GetQuestLink(questID)')
		if not entry or (issecretvalue and issecretvalue(entry.title)) then return nil end
		return ('|cffffff00|Hquest:%d:%d|h[%s]|h|r'):format(questID, tonumber(entry.level) or 0, tostring(entry.title))
	end

	------------------------------------------------------------------ the clicks

	--[[
		What a click on a quest row and the right-click menu ask of the game
		(SaftUI-Tracker/clicks.lua), after Blizzard's own tracker's block click and
		menu (Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua:
		QuestObjectiveTrackerMixin:OnBlockHeaderClick, the same on both branches
		of Gethe/wow-ui-source, read 2026-11-14), each function recording its call
		in stub.quest_calls. These are Blizzard's Lua or old globals, not in the
		generated documentation; their names and arguments are Blizzard's own
		callers':
		  ChatFrameUtil.TryInsertQuestLinkForQuestID(questID) (Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua:
		    IsModifiedClick('CHATLINK'), then ChatFrameUtil.InsertLink of
		    GetQuestLink: true when a chat edit box took the link)
		  IsModifiedClick(action) -> boolean (an old global; Blizzard's callers pass
		    'QUESTWATCHTOGGLE' and 'CHATLINK')
		  QuestUtil.CanRemoveQuestWatch() (Mainline/QuestUtils.lua: false while
		    C_PlayerInfo.IsPlayerNPERestricted())
		  QuestUtil.IsShowingQuestDetails(questID), QuestUtil.OpenQuestDetails(questID),
		    QuestUtil.ShareQuest(questID) (the same file; they use the quest log's
		    popup details frame and QuestLogPushQuest)
		  QuestMapFrame_OpenToQuestDetails(questID) and
		    QuestMapQuestOptions_AbandonQuest(questID) (Mainline/QuestMapFrame.lua:
		    the map's quest log, and the abandon confirmation)
		C_PlayerInfo.IsPlayerNPERestricted() is in PlayerInfoDocumentation.lua.
		The menu's strings are the game's own English, from wago.tools'
		GlobalStrings at Forever 1.60.1.70888 and retail 12.1.5.70783 (the same
		on both; all nine names exist on both): a test reads them through the
		globals, never as literals.
	]]

	function C_PlayerInfo.IsPlayerNPERestricted() return stub.npe_restricted == true end

	function IsModifiedClick(action)
		record('IsModifiedClick', action)
		return stub.modified[action] == true
	end
	ChatFrameUtil = ChatFrameUtil or {}
	function ChatFrameUtil.TryInsertQuestLinkForQuestID(questID)
		record('ChatFrameUtil.TryInsertQuestLinkForQuestID', questID)
		local link = GetQuestLink(questID)
		if stub.modified.CHATLINK == true and link and stub.chat_open then
			table.insert(stub.chat_inserted, link)
			return true
		end
		return false
	end
	function QuestUtil.CanRemoveQuestWatch()
		record('QuestUtil.CanRemoveQuestWatch')
		return not C_PlayerInfo.IsPlayerNPERestricted()
	end
	-- stub.quests.details is the quest the popup details frame shows.
	function QuestUtil.IsShowingQuestDetails(questID)
		record('QuestUtil.IsShowingQuestDetails', questID)
		return stub.quests.details == questID
	end
	function QuestUtil.OpenQuestDetails(questID)
		record('QuestUtil.OpenQuestDetails', questID)
		stub.quests.details = questID
	end
	function QuestUtil.ShareQuest(questID) record('QuestUtil.ShareQuest', questID) end
	function QuestMapFrame_OpenToQuestDetails(questID) record('QuestMapFrame_OpenToQuestDetails', questID) end
	function QuestMapQuestOptions_AbandonQuest(questID) record('QuestMapQuestOptions_AbandonQuest', questID) end

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

------------------------------------------------------------------ the sections' data

--[[
	What Blizzard's own tracker modules read to decide they have content, for the
	section probes (SaftUI-Tracker/probes.lua). Their signatures, from the
	generated API documentation (Blizzard_APIDocumentationGenerated, read on both
	branches of Gethe/wow-ui-source, `forever` and `live`, 2026-11-14: the same on
	both, so no client drops one) unless the comment says where else:
	  C_ContentTracking.GetTrackedIDs(trackableType) -> entryIDs
	    (ContentTrackingDocumentation.lua; ContentTrackingType in
	    ContentTrackingTypesDocumentation.lua)
	  C_TradeSkillUI.GetRecipesTracked(isRecraft) -> recipeIDs
	    (TradeSkillUIDocumentation.lua)
	  C_PerksActivities.GetTrackedPerksActivities() -> { trackedIDs } and
	    GetPerksActivityInfo(perksActivityID) -> info or nil (PerksActivitiesDocumentation.lua)
	  C_NeighborhoodInitiative.GetTrackedInitiativeTasks() -> { trackedIDs } and
	    GetInitiativeTaskInfo(initiativeTaskID) -> info or nil (NeighborhoodInitiativeDocumentation.lua)
	  C_ChallengeMode.IsChallengeModeActive() -> bool (ChallengeModeInfoDocumentation.lua)
	Not in the generated documentation, so from Blizzard's own callers
	(Blizzard_ObjectiveTracker, the same on both branches):
	  C_Scenario.GetInfo() -> scenarioName, currentStage, numStages, flags, _, _, _,
	    xp, money, scenarioType, _, textureKit, scenarioID
	    (Blizzard_ScenarioObjectiveTracker.lua:183; outside a scenario numStages is
	    0, the module's own `isInScenario = numStages > 0`)
	  GetTasksTable() -> a list of questIDs, GetTaskInfo(questID) -> isInArea,
	    isOnMap, numObjectives, taskName, displayAsObjective
	    (Blizzard_BonusObjectiveTracker.lua:428 and 464)
	  GetAchievementInfo(achievementID) -> id, name, points, completed, month, day,
	    year, description, flags, icon, rewardText, isGuild, wasEarnedByMe,
	    earnedBy (the 13th is the one the achievements module tests,
	    Blizzard_AchievementObjectiveTracker.lua:103)
	Every argument is checked as in game: a wrong type raises the call's Usage line.
]]

do
	local function arg(value, kind, usage)
		if type(value) ~= kind then error('Usage: ' .. usage, 3) end
		return value
	end

	C_Scenario = C_Scenario or {}
	function C_Scenario.GetInfo()
		local s = stub.probes.scenario or {}
		return s.name or '', s.stage or 0, s.stages or 0, s.flags or 0, nil, nil, nil, s.xp or 0, s.money or 0,
			s.type or 0, nil, s.texture, s.id or 0
	end

	C_ChallengeMode = C_ChallengeMode or {}
	function C_ChallengeMode.IsChallengeModeActive() return stub.probes.challenge == true end

	function GetTasksTable()
		local list = {}
		for i, questID in ipairs(stub.probes.tasks) do list[i] = questID end
		return list
	end
	function GetTaskInfo(questID)
		arg(questID, 'number', 'isInArea, isOnMap, numObjectives, taskName, displayAsObjective = GetTaskInfo(questID)')
		local info = stub.probes.task_info[questID]
		if not info then return false, false, nil, nil, false end
		return info.inArea == true, info.onMap == true, info.objectives, info.name, info.asObjective == true
	end

	C_ContentTracking = C_ContentTracking or {}
	function C_ContentTracking.GetTrackedIDs(trackableType)
		arg(trackableType, 'number', 'local entryIDs = C_ContentTracking.GetTrackedIDs(trackableType)')
		local ids = {}
		for i, id in ipairs(stub.probes.tracked[trackableType] or {}) do ids[i] = id end
		return ids
	end

	function GetAchievementInfo(achievementID)
		arg(achievementID, 'number', 'id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID)')
		local info = stub.probes.achievements[achievementID] or {}
		return achievementID, 'Achievement ' .. achievementID, 10, info.earned == true, nil, nil, nil, '', 0, 0, '', false,
			info.earned == true, nil
	end

	C_TradeSkillUI = C_TradeSkillUI or {}
	function C_TradeSkillUI.GetRecipesTracked(isRecraft)
		arg(isRecraft, 'boolean', 'local recipeIDs = C_TradeSkillUI.GetRecipesTracked(isRecraft)')
		local ids = {}
		local recipes = stub.probes.recipes or {}
		for i, id in ipairs((isRecraft and recipes.recraft or recipes.normal) or {}) do ids[i] = id end
		return ids
	end

	local function tracked(source) -- { ids, info }: a copy of the ids
		local ids = {}
		for i, id in ipairs((source and source.ids) or {}) do ids[i] = id end
		return { trackedIDs = ids }
	end
	C_PerksActivities = C_PerksActivities or {}
	function C_PerksActivities.GetTrackedPerksActivities() return tracked(stub.probes.perks) end
	function C_PerksActivities.GetPerksActivityInfo(perksActivityID)
		arg(perksActivityID, 'number', 'local info = C_PerksActivities.GetPerksActivityInfo(perksActivityID)')
		local info = stub.probes.perks and stub.probes.perks.info and stub.probes.perks.info[perksActivityID]
		if not info then return nil end
		return { ID = perksActivityID, activityName = 'Activity ' .. perksActivityID, completed = info.completed == true, requirementsList = {} }
	end

	C_NeighborhoodInitiative = C_NeighborhoodInitiative or {}
	function C_NeighborhoodInitiative.GetTrackedInitiativeTasks() return tracked(stub.probes.initiative) end
	function C_NeighborhoodInitiative.GetInitiativeTaskInfo(initiativeTaskID)
		arg(initiativeTaskID, 'number', 'local info = C_NeighborhoodInitiative.GetInitiativeTaskInfo(initiativeTaskID)')
		local info = stub.probes.initiative and stub.probes.initiative.info and stub.probes.initiative.info[initiativeTaskID]
		if not info then return nil end
		return { ID = initiativeTaskID, taskName = 'Task ' .. initiativeTaskID, completed = info.completed == true, requirementsList = {} }
	end
end
