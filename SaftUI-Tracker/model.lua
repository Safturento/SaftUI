local st = SaftUI
local TR = st.Tracker

--[[
	The tracker's data: the quest log read into a plain table (the model) that
	the rest of the tracker draws from, and the text a quest row says. Pure
	over the game's API: no frame, no timer, no event, no setting read at file
	scope. The same API gives the same model.

	Every API is guarded by presence (a missing function makes its part of the
	quest absent, never an error). A value is tested with the Plain helpers
	(which are the issecretvalue test) before any comparison or arithmetic: a
	secret one counts as missing. The exceptions are a quest's title and the
	title of a popup, which a secret one goes on as it is (SetText takes it),
	and which then has no level or tags.

	The model:
	  { quests, popups, counts = { inLog, max, watched, watchMax }, zoneNames,
	    focused, arena }
	  quests    in the game's order (callings, overridesSortOrder, the watch
	            list's order), then, with Show on the current zone's, the log's
	            quests under the current zone's header that aren't tracked, in
	            log order, each with tracked = false and no watchIndex
	  popups    { { id, kind = 'OFFER' | 'COMPLETE', title } ... }
	  focused   the focused (super tracked) quest's ID, nil for none
	  arena     in an arena, where quests and popups are empty
	A quest is { id, logIndex, watchIndex | nil, tracked, title, headerTitle |
	nil, campaign | nil, level | nil, elite, tags, difficultyColor | nil, complete,
	failed, ready, auto, completionText | nil, objectives, sequenced, money |
	nil, timeLeft | nil, readAt | nil, item | nil, calling, overrides, waypoint |
	nil }; see Read.
]]

local Model = {}
TR.Model = Model

local Plain, PlainNumber, PlainString = st.Plain, st.PlainNumber, st.PlainString

-- A flag the API gives as a boolean: true only for a plain true.
local function Flag(value)
	return Plain(value) == true
end

-- A plain string with something in it, or nil.
local function Text(value)
	value = PlainString(value)
	if value ~= nil and value ~= '' then return value end
end

local function Exists(table, name)
	return type(table) == 'table' and type(table[name]) == 'function'
end

------------------------------------------------------------------ the zone

-- The names the current zone goes by, best first: the zone map's (the player's
-- best map climbed out of a cave, building or dungeon floor to the zone, and
-- stopping at an Orphan map or a dungeon's own, which is the map the quests
-- of an instance are filed under), then GetRealZoneText(), then GetZoneText().
-- Plain strings only, each once.
function Model.ZoneNames()
	local names, seen = {}, {}
	local function Add(name)
		name = Text(name)
		if name and not seen[name] then
			seen[name] = true
			names[#names + 1] = name
		end
	end
	local types = type(Enum) == 'table' and Enum.UIMapType
	if types and Exists(C_Map, 'GetBestMapForUnit') and Exists(C_Map, 'GetMapInfo') then
		local mapID = PlainNumber(C_Map.GetBestMapForUnit('player'))
		for _ = 1, 20 do -- a map tree is a few deep; the bound only guards a loop
			if not mapID then break end
			local info = C_Map.GetMapInfo(mapID)
			local mapType = type(info) == 'table' and PlainNumber(info.mapType)
			if not mapType then break end
			if mapType == types.Zone or mapType == types.Orphan or mapType == types.Dungeon then
				Add(info.name)
				break
			end
			if mapType ~= types.Micro then break end -- a continent or above: no zone
			mapID = PlainNumber(info.parentMapID)
		end
	end
	if type(GetRealZoneText) == 'function' then Add(GetRealZoneText()) end
	if type(GetZoneText) == 'function' then Add(GetZoneText()) end
	return names
end

------------------------------------------------------------------ the display rule

-- Whether a quest (a C_QuestLog.GetInfo table) is drawn: not a task quest, not
-- a bounty (Blizzard's own test, `isBounty and not isComplete`, reads a global
-- that doesn't exist, so it never shows one: ruling 10), not disabled for the
-- session, not hidden. A campaign quest is drawn.
function Model.Shown(info)
	if type(info) ~= 'table' then return false end
	if Flag(info.isTask) or Flag(info.isBounty) or Flag(info.isHidden) then return false end
	local questID = PlainNumber(info.questID)
	if questID and Exists(C_QuestLog, 'IsQuestDisabledForSession') and Flag(C_QuestLog.IsQuestDisabledForSession(questID)) then
		return false
	end
	return true
end

-- Whether quest a goes before quest b in the game's order: callings first,
-- then those that override the sort order, then the watch list's order, and
-- last the quests that aren't on it, in log order.
function Model.Compare(a, b)
	local aCalling, bCalling = a.calling and true or false, b.calling and true or false
	if aCalling ~= bCalling then return aCalling end
	local aOver, bOver = a.overrides and true or false, b.overrides and true or false
	if aOver ~= bOver then return aOver end
	if a.watchIndex and b.watchIndex then return a.watchIndex < b.watchIndex end
	if (a.watchIndex ~= nil) ~= (b.watchIndex ~= nil) then return a.watchIndex ~= nil end
	return (a.logIndex or 0) < (b.logIndex or 0)
end

-- A quest that's done: complete, or ready to turn in.
function Model.Finished(quest)
	return quest.complete == true or quest.ready == true
end

------------------------------------------------------------------ reading

-- The Daily or Weekly tag of a QuestInfo's frequency, nil for neither.
local function FrequencyTag(frequency)
	frequency = PlainNumber(frequency)
	local enum = type(Enum) == 'table' and Enum.QuestFrequency
	if not (frequency and enum) then return nil end
	if frequency == enum.Daily then return type(DAILY) == 'string' and DAILY or nil end
	if frequency == enum.Weekly then return type(WEEKLY) == 'string' and WEEKLY or nil end
end

-- A quest's tags: its tag's name (Elite, Dungeon, ...), then Daily or Weekly.
-- Plain strings, without brackets.
local function ReadTags(questID, info, tagInfo)
	local tags = {}
	local name = type(tagInfo) == 'table' and Text(tagInfo.tagName)
	if name then tags[#tags + 1] = name end
	local frequency = FrequencyTag(info.frequency)
	if frequency then tags[#tags + 1] = frequency end
	return tags
end

-- Forever answers IsEliteQuest; retail has no such call and its tag says.
local function ReadElite(questID, tagInfo)
	if Exists(C_QuestLog, 'IsEliteQuest') then return Flag(C_QuestLog.IsEliteQuest(questID)) end
	return type(tagInfo) == 'table' and Flag(tagInfo.isElite)
end

-- The quest's difficulty color as { r, g, b } of plain numbers, or nil.
local function ReadDifficultyColor(questID)
	if not (Exists(C_PlayerInfo, 'GetContentDifficultyQuestForPlayer') and type(GetDifficultyColor) == 'function') then return nil end
	local difficulty = PlainNumber(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID))
	if not difficulty then return nil end
	local color = GetDifficultyColor(difficulty)
	if type(color) ~= 'table' then return nil end
	local r, g, b = PlainNumber(color.r), PlainNumber(color.g), PlainNumber(color.b)
	if r and g and b then return { r = r, g = g, b = b } end
end

-- The objectives, as { text, type, finished, numFulfilled, numRequired,
-- percent } of plain values (a secret one is nil). percent is the quest's
-- progress bar percent, on a progressbar objective.
local function ReadObjectives(questID)
	local list = {}
	if not Exists(C_QuestLog, 'GetQuestObjectives') then return list end
	local objectives = C_QuestLog.GetQuestObjectives(questID)
	if type(objectives) ~= 'table' then return list end
	for i = 1, #objectives do
		local o = objectives[i]
		if type(o) == 'table' then
			local entry = {
				text = Text(o.text), type = PlainString(o.type), finished = Flag(o.finished),
				numFulfilled = PlainNumber(o.numFulfilled), numRequired = PlainNumber(o.numRequired),
			}
			if entry.type == 'progressbar' and type(GetQuestProgressBarPercent) == 'function' then
				entry.percent = PlainNumber(GetQuestProgressBarPercent(questID))
			end
			list[#list + 1] = entry
		end
	end
	return list
end

-- { have, need } while the quest needs more money than the player has.
local function ReadMoney(questID)
	if not (Exists(C_QuestLog, 'GetRequiredMoney') and type(GetMoney) == 'function') then return nil end
	local need, have = PlainNumber(C_QuestLog.GetRequiredMoney(questID)), PlainNumber(GetMoney())
	if need and have and need > have then return { have = have, need = need } end
end

-- The seconds left on a timed quest. Forever's GetQuestTimers gives them
-- (QuestTimerInfo, the time left); retail's GetTimeAllowed gives the total and
-- the time elapsed (ruling 12). timers is Forever's list, read once.
local function ReadTimeLeft(questID, timers)
	if timers then
		for i = 1, #timers do
			local timer = timers[i]
			if type(timer) == 'table' and PlainNumber(timer.questID) == questID then
				return PlainNumber(timer.questTimer)
			end
		end
		return nil
	end
	if not Exists(C_QuestLog, 'GetTimeAllowed') then return nil end
	local total, elapsed = C_QuestLog.GetTimeAllowed(questID)
	total, elapsed = PlainNumber(total), PlainNumber(elapsed)
	if total and elapsed and elapsed < total then return total - elapsed end
end

-- The quest's item as { link, texture, charges, showWhenComplete, cooldown =
-- { start, duration, enable } | nil, range = 0 | 1 | nil }, or nil where the
-- quest shows none: Blizzard's rule (QuestUtil.QuestShowsItemByIndex), an
-- item, and, once the quest is complete, only one that shows when complete.
local function ReadItem(logIndex, finished)
	if type(GetQuestLogSpecialItemInfo) ~= 'function' then return nil end
	local link, texture, charges, showWhenComplete = GetQuestLogSpecialItemInfo(logIndex)
	texture = Plain(texture)
	if texture == nil or texture == false then return nil end
	showWhenComplete = Flag(showWhenComplete)
	if finished and not showWhenComplete then return nil end
	local item = { link = PlainString(link), texture = texture, charges = PlainNumber(charges), showWhenComplete = showWhenComplete }
	if type(GetQuestLogSpecialItemCooldown) == 'function' then
		local start, duration, enable = GetQuestLogSpecialItemCooldown(logIndex)
		start, duration, enable = PlainNumber(start), PlainNumber(duration), PlainNumber(enable)
		if start and duration then item.cooldown = { start = start, duration = duration, enable = enable } end
	end
	if type(IsQuestLogSpecialItemInRange) == 'function' then
		item.range = PlainNumber(IsQuestLogSpecialItemInRange(logIndex))
	end
	return item
end

-- The header a quest sits under: its title (a plain, non-empty string, else
-- nil) and its campaign ID. Headers are read once each.
local function ReadHeader(questID, headers)
	if not Exists(C_QuestLog, 'GetHeaderIndexForQuest') or not Exists(C_QuestLog, 'GetInfo') then return nil end
	local index = PlainNumber(C_QuestLog.GetHeaderIndexForQuest(questID))
	if not index then return nil end
	local header = headers[index]
	if header == nil then
		header = false
		local info = C_QuestLog.GetInfo(index)
		if type(info) == 'table' and Flag(info.isHeader) then
			local title = Text(info.title)
			if title then
				local campaign = PlainNumber(info.campaignID)
				header = { title = title, campaign = campaign and campaign > 0 and campaign or nil }
			end
		end
		headers[index] = header
	end
	if header then return header.title, header.campaign end
end

-- One quest's entry, or nil where the log has nothing to show for it (it's not
-- in the log, has no info or no title yet, or isn't drawn).
local function ReadQuest(questID, watchIndex, context)
	if not (Exists(C_QuestLog, 'GetLogIndexForQuestID') and Exists(C_QuestLog, 'GetInfo')) then return nil end
	local logIndex = PlainNumber(C_QuestLog.GetLogIndexForQuestID(questID))
	if not logIndex then return nil end
	local info = C_QuestLog.GetInfo(logIndex)
	if type(info) ~= 'table' or Flag(info.isHeader) then return nil end
	-- A title is shown as it is, secret or not; one the log hasn't got yet
	-- (nothing, or an empty string) skips the quest until a later read has it.
	local title = info.title
	if not issecretvalue(title) and (type(title) ~= 'string' or title == '') then
		-- Its data isn't loaded yet: QUEST_DATA_LOAD_RESULT for it is worth a refresh.
		context.waiting[questID] = true
		return nil
	end
	if not Model.Shown(info) then return nil end

	local tagInfo = Exists(C_QuestLog, 'GetQuestTagInfo') and C_QuestLog.GetQuestTagInfo(questID) or nil
	local level = PlainNumber(info.difficultyLevel)
	if not level or level <= 0 then level = PlainNumber(info.level) end
	if level and level <= 0 then level = nil end

	local complete = Exists(C_QuestLog, 'IsComplete') and Flag(C_QuestLog.IsComplete(questID))
	local ready = Exists(C_QuestLog, 'ReadyForTurnIn') and Flag(C_QuestLog.ReadyForTurnIn(questID))
	local finished = complete or ready
	local headerTitle, campaign = ReadHeader(questID, context.headers)

	local quest = {
		id = questID, logIndex = logIndex, watchIndex = watchIndex, tracked = watchIndex ~= nil,
		title = title, headerTitle = headerTitle, campaign = campaign,
		level = level, elite = ReadElite(questID, tagInfo), tags = ReadTags(questID, info, tagInfo),
		difficultyColor = ReadDifficultyColor(questID),
		complete = complete, failed = Exists(C_QuestLog, 'IsFailed') and Flag(C_QuestLog.IsFailed(questID)),
		ready = ready, auto = Flag(info.isAutoComplete),
		objectives = ReadObjectives(questID),
		sequenced = type(IsQuestSequenced) == 'function' and Flag(IsQuestSequenced(questID)),
		money = ReadMoney(questID), timeLeft = ReadTimeLeft(questID, context.timers),
		item = ReadItem(logIndex, finished),
		calling = Exists(C_QuestLog, 'IsQuestCalling') and Flag(C_QuestLog.IsQuestCalling(questID)),
		overrides = Flag(info.overridesSortOrder),
	}
	if quest.timeLeft and type(GetTime) == 'function' then quest.readAt = GetTime() end
	if complete and type(GetQuestLogCompletionText) == 'function' then
		quest.completionText = Text(GetQuestLogCompletionText(logIndex))
	end
	-- (No area and no distance: only the nearest button's choice uses them, and it
	-- reads them fresh for the quests it chooses among, nearest.lua `Candidates`.)
	if context.focused == questID and Exists(C_QuestLog, 'GetNextWaypointText') then
		quest.waypoint = Text(C_QuestLog.GetNextWaypointText(questID))
	end
	return quest
end

-- The auto quest pop-ups that are up, unless the splash screen is.
local function ReadPopups(waiting)
	local popups = {}
	if type(GetNumAutoQuestPopUps) ~= 'function' or type(GetAutoQuestPopUp) ~= 'function' then return popups end
	if type(SplashFrame) == 'table' and Exists(SplashFrame, 'IsShown') and Flag(SplashFrame:IsShown()) then return popups end
	for i = 1, PlainNumber(GetNumAutoQuestPopUps()) or 0 do
		local questID, kind = GetAutoQuestPopUp(i)
		questID, kind = PlainNumber(questID), PlainString(kind)
		if questID and (kind == 'OFFER' or kind == 'COMPLETE') then
			-- Blizzard's own filter (QuestObjectiveTracker's ShouldDisplayAutoQuest):
			-- not a bounty, not a task, not disabled for the session.
			local hidden = (Exists(C_QuestLog, 'IsQuestBounty') and Flag(C_QuestLog.IsQuestBounty(questID)))
				or (Exists(C_QuestLog, 'IsQuestTask') and Flag(C_QuestLog.IsQuestTask(questID)))
				or (Exists(C_QuestLog, 'IsQuestDisabledForSession') and Flag(C_QuestLog.IsQuestDisabledForSession(questID)))
			-- The title is the quest cache's: an offered quest has one before it is in
			-- the log. None yet (nothing or empty) drops the popup.
			local title = not hidden and Exists(C_QuestLog, 'GetTitleForQuestID') and C_QuestLog.GetTitleForQuestID(questID) or nil
			if title and (issecretvalue(title) or (type(title) == 'string' and title ~= '')) then
				popups[#popups + 1] = { id = questID, kind = kind, title = title }
			elseif not hidden then
				waiting[questID] = true
			end
		end
	end
	return popups
end

-- The most quests the log holds, read from the game and never assumed: the
-- client's C_QuestLog.GetMaxNumQuestsCanAccept() where it gives one, else
-- Forever's constant (Constants.QuestLogConstsMainlineCamelot, 40 on the
-- owner's client), else TR.FALLBACK_MAX_QUESTS. The item button pool and every
-- "of N quests" use this, not a number of their own.
TR.FALLBACK_MAX_QUESTS = 35
function TR.MaxQuests()
	if Exists(C_QuestLog, 'GetMaxNumQuestsCanAccept') then
		local max = PlainNumber(C_QuestLog.GetMaxNumQuestsCanAccept())
		if max and max > 0 then return max end
	end
	local consts = type(Constants) == 'table' and Constants.QuestLogConstsMainlineCamelot
	local max = type(consts) == 'table' and PlainNumber(consts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT)
	if max and max > 0 then return max end
	return TR.FALLBACK_MAX_QUESTS
end

-- The model. show is the Show setting: 'tracked' (the default: the game's
-- watch list) or 'zone' (that, and every other quest of the current zone's
-- header, untracked).
function Model.Read(show)
	local model = {
		quests = {}, popups = {}, counts = {}, zoneNames = Model.ZoneNames(), arena = false,
		waiting = {}, -- questIDs skipped for want of a title, a set
	}
	local counts = model.counts
	if Exists(C_QuestLog, 'GetNumQuestLogEntries') then
		local _, inLog = C_QuestLog.GetNumQuestLogEntries()
		counts.inLog = PlainNumber(inLog)
	end
	counts.max = TR.MaxQuests()
	if Exists(C_QuestLog, 'GetNumQuestWatches') then counts.watched = PlainNumber(C_QuestLog.GetNumQuestWatches()) end
	local consts = type(Constants) == 'table' and Constants.QuestWatchConsts
	counts.watchMax = consts and PlainNumber(consts.MAX_QUEST_WATCHES) or nil

	if Exists(C_SuperTrack, 'GetSuperTrackedQuestID') then
		local focused = PlainNumber(C_SuperTrack.GetSuperTrackedQuestID())
		if focused and focused ~= 0 then model.focused = focused end
	end

	-- No quests in an arena, as Blizzard's quest module.
	if type(IsInInstance) == 'function' then
		local _, instanceType = IsInInstance()
		model.arena = PlainString(instanceType) == 'arena'
	end
	if model.arena then return model end

	model.popups = ReadPopups(model.waiting)

	local context = { headers = {}, focused = model.focused, waiting = model.waiting }
	if Exists(C_QuestLog, 'GetQuestTimers') then
		local timers = C_QuestLog.GetQuestTimers()
		context.timers = type(timers) == 'table' and timers or {}
	end

	local quests, seen = {}, {}
	if Exists(C_QuestLog, 'GetNumQuestWatches') and Exists(C_QuestLog, 'GetQuestIDForQuestWatchIndex') then
		for i = 1, PlainNumber(C_QuestLog.GetNumQuestWatches()) or 0 do
			local questID = PlainNumber(C_QuestLog.GetQuestIDForQuestWatchIndex(i))
			if questID and not seen[questID] then
				seen[questID] = true
				local quest = ReadQuest(questID, i, context)
				if quest then quests[#quests + 1] = quest end
			end
		end
	end
	table.sort(quests, Model.Compare)

	-- The current zone's other quests, untracked, after the tracked, in log
	-- order. Their header is what says they're the zone's.
	if show == 'zone' and TR.Groups and Exists(C_QuestLog, 'GetNumQuestLogEntries') and Exists(C_QuestLog, 'GetInfo') then
		local entries = C_QuestLog.GetNumQuestLogEntries()
		for index = 1, PlainNumber(entries) or 0 do
			local info = C_QuestLog.GetInfo(index)
			local questID = type(info) == 'table' and not Flag(info.isHeader) and PlainNumber(info.questID)
			if questID and not seen[questID] then
				seen[questID] = true
				-- The header says whether it's the zone's, before the quest is read.
				local headerTitle = ReadHeader(questID, context.headers)
				if headerTitle and TR.Groups.IsCurrent(headerTitle, model.zoneNames) then
					local quest = ReadQuest(questID, nil, context)
					if quest then quests[#quests + 1] = quest end
				end
			end
		end
	end
	model.quests = quests
	return model
end

------------------------------------------------------------------ text

-- "4:32", or "1:04:32" from an hour up. Whole seconds, counted down: a negative
-- time is 0:00.
function TR.TimeText(seconds)
	seconds = PlainNumber(seconds)
	if not seconds then return '' end
	seconds = math.max(0, math.floor(seconds))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then return ('%d:%02d:%02d'):format(hours, minutes, seconds % 60) end
	return ('%d:%02d'):format(minutes, seconds % 60)
end

-- A quest's title as drawn: "[12] " before it with Level on ("[12+] " for an
-- elite quest, Forever's own form), the tags after it with Tags on, each in
-- brackets: "(Elite) (Daily)" (ruling 13). A secret title is the title as it is,
-- with no level and no tags: it can't be joined to anything.
function TR.TitleText(quest, settings)
	local title = quest.title
	if issecretvalue(title) then return title end
	title = tostring(title)
	if settings.level and quest.level then
		title = ('[%d%s] %s'):format(quest.level, quest.elite and '+' or '', title)
	end
	if settings.tags and quest.tags and #quest.tags > 0 then
		local parts = {}
		for i, tag in ipairs(quest.tags) do parts[i] = '(' .. tag .. ')' end
		title = title .. ' ' .. table.concat(parts, ' ')
	end
	return title
end

-- The timer line's text and color state for the seconds left: "Time left: 4:32",
-- in 'failed' under a minute. The ticker that counts a shown timer down says it
-- through this too.
function TR.TimerLine(left)
	return 'Time left: ' .. TR.TimeText(left), left < 60 and 'failed' or 'normal'
end

local function Line(kind, text, state, value)
	return { kind = kind, text = text, state = state, value = value }
end

-- The lines of a quest's row, in order (ruling 11), each { kind, text, state,
-- value }. state is the color to draw it in: 'normal' (Text > Normal),
-- 'completed' or 'failed'. kind:
--   objective  an objective's text                       (state: finished or not)
--   bar        a progressbar objective's bar, in place of its line with Progress
--              bars on; text is its percent, value the percent
--   failed     "Failed", alone, for a failed quest
--   completion the completion text, else "Ready for turn-in", for a finished quest
--   complete, click   "Quest complete" and "Click to complete", for a finished
--              auto-complete quest
--   money      "<have> / <need>", value the need
--   timer      "Time left: 4:32", value the seconds left now (state 'failed'
--              under a minute)
--   waypoint   "Waypoint: <text>", for the focused quest
-- A finished quest shows its objectives only with Objectives of finished quests
-- on, all in 'completed'. Otherwise the objectives come in order, a finished one
-- in 'completed' (left out with Hide finished objectives), a sequenced quest's
-- ending at its first unfinished one. Money and the timer are for a quest that
-- isn't finished. now is GetTime() at the draw: the timer counts down from the
-- read (quest.readAt), so the same quest says less each second.
function TR.QuestLines(quest, settings, now)
	local lines = {}
	local finished = Model.Finished(quest)
	local objectives = quest.objectives or {}

	if finished then
		if settings.finished_objectives then
			for _, o in ipairs(objectives) do
				if o.text then lines[#lines + 1] = Line('objective', o.text, 'completed') end
			end
		end
		if quest.auto then
			lines[#lines + 1] = Line('complete', QUEST_WATCH_QUEST_COMPLETE, 'completed')
			lines[#lines + 1] = Line('click', QUEST_WATCH_CLICK_TO_COMPLETE, 'completed')
		else
			lines[#lines + 1] = Line('completion', quest.completionText or QUEST_WATCH_QUEST_READY, 'completed')
		end
	elseif quest.failed then
		lines[#lines + 1] = Line('failed', FAILED or 'Failed', 'failed')
	else
		for _, o in ipairs(objectives) do
			if o.finished then
				if not settings.hide_finished and o.text then lines[#lines + 1] = Line('objective', o.text, 'completed') end
			else
				if o.type == 'progressbar' and settings.bars and o.percent then
					lines[#lines + 1] = Line('bar', ('%d%%'):format(math.floor(o.percent + 0.5)), 'normal', o.percent)
				elseif o.text then
					lines[#lines + 1] = Line('objective', o.text, 'normal')
				end
				if quest.sequenced then break end
			end
		end
		if quest.money and type(GetMoneyString) == 'function' then
			lines[#lines + 1] = Line('money', GetMoneyString(quest.money.have) .. ' / ' .. GetMoneyString(quest.money.need), 'normal', quest.money.need)
		end
		if settings.timers and quest.timeLeft then
			local left = quest.timeLeft
			if now and quest.readAt then left = left - (now - quest.readAt) end
			if left > 0 then
				local text, state = TR.TimerLine(left)
				lines[#lines + 1] = Line('timer', text, state, left)
			end
		end
	end
	if settings.waypoint and quest.waypoint then
		lines[#lines + 1] = Line('waypoint', ('Waypoint: %s'):format(quest.waypoint), 'normal')
	end
	return lines
end
