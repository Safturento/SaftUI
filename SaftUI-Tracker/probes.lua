local st = SaftUI
local TR = st.Tracker

--[[
	How SaftUI's tracker knows a section it doesn't draw has content (design: "How
	SaftUI knows a section has content"). Two signals, both reads only:

	  1. A probe per section on the game's own data (TR.Probes), each reading the
	     API Blizzard's module reads, guarded by presence: a missing namespace or
	     function (a client without it) answers no, a secret value answers no.
	  2. Blizzard's own module state, read after each layout of a module
	     (TR:WatchModules, blizzard.lua, hooks each module's Update): content in
	     state NotShown, ShownPartially or ShownFully, or hasContents. It catches
	     what the probes don't name (the Maw's buffs without a scenario, the
	     scenario's bonus steps, a module a later patch adds) and costs nothing
	     the probes' events don't. The module state alone isn't enough: Blizzard's
	     quests can fill its height, and a module after them is then Skipped
	     whatever it holds, which is why the probes exist.

	A probe pass (TR:ProbePass) reads both for every section and notes what has
	content. It runs on the next frame after any of the probe events or a module's
	layout, at most one a frame (TR:RunProbes asks for it), and again when a hold
	ends. A section counts as needed from the moment it has content until
	TR.HOLD seconds without any, so a zone widget that flickers at an area's edge
	doesn't swap the trackers back and forth (TR.Probes.Held).

	TR.SectionHandsOver(key) is the P4 seam: the one function that says whether a
	section hands over. As designed, every section does; where P4 finds a section
	always filled on Forever, it returns `not st.forever` for it.
]]

-- The sections SaftUI doesn't draw yet, in the design's order: key, the name
-- the Now line gives, Blizzard's module, and the probe (a name in TR.Probes).
-- The two quest modules aren't here: SaftUI draws what they hold, and never
-- reads them.
TR.SECTIONS = {
	{ key = 'scenario', name = 'Scenario', module = 'ScenarioObjectiveTracker', probe = 'Scenario' },
	{ key = 'widgets', name = 'Zone widgets', module = 'UIWidgetObjectiveTracker', probe = 'Widgets' },
	{ key = 'bonus', name = 'Bonus objectives', module = 'BonusObjectiveTracker', probe = 'Bonus' },
	{ key = 'world', name = 'World quests', module = 'WorldQuestObjectiveTracker', probe = 'WorldQuests' },
	{ key = 'achievements', name = 'Achievements', module = 'AchievementObjectiveTracker', probe = 'Achievements' },
	{ key = 'professions', name = 'Professions', module = 'ProfessionsRecipeTracker', probe = 'Professions' },
	{ key = 'activities', name = 'Monthly activities', module = 'MonthlyActivitiesObjectiveTracker', probe = 'Activities' },
	{ key = 'endeavors', name = 'Endeavors', module = 'InitiativeTasksObjectiveTracker', probe = 'Endeavors' },
	{ key = 'collections', name = 'Collection tracking', module = 'AdventureObjectiveTracker', probe = 'Collections' },
}

-- Seconds a section stays needed after it last had content.
TR.HOLD = 2

-- The events a probe pass runs after (the ones Blizzard's modules listen to, the
-- two the design lists for the quests' watch list and the zone among them), each
-- registered only where the client has it. The design's list, with the two
-- `..._TRACKED_UPDATED` events the monthly activities' and endeavors' modules
-- also listen to (Blizzard_MonthlyActivitiesObjectiveTracker.lua and
-- Blizzard_InitiativeTasksObjectiveTracker.lua, both branches): a tracked task's
-- progress, which can complete it.
TR.PROBE_EVENT_LIST = {
	'SCENARIO_UPDATE', 'SCENARIO_CRITERIA_UPDATE', 'SCENARIO_COMPLETED', 'CHALLENGE_MODE_START',
	'CHALLENGE_MODE_COMPLETED', 'CHALLENGE_MODE_RESET', 'CONTENT_TRACKING_UPDATE',
	'TRACKED_ACHIEVEMENT_LIST_CHANGED', 'TRACKED_ACHIEVEMENT_UPDATE', 'ACHIEVEMENT_EARNED',
	'TRACKED_RECIPE_UPDATE', 'PERKS_ACTIVITIES_TRACKED_LIST_CHANGED', 'PERKS_ACTIVITIES_TRACKED_UPDATED',
	'PERKS_ACTIVITY_COMPLETED', 'INITIATIVE_TASKS_TRACKED_LIST_CHANGED', 'INITIATIVE_TASKS_TRACKED_UPDATED',
	'NEIGHBORHOOD_INITIATIVE_UPDATED', 'QUEST_LOG_UPDATE', 'QUEST_WATCH_LIST_CHANGED',
	'ZONE_CHANGED_NEW_AREA', 'PLAYER_ENTERING_WORLD',
}
TR.PROBE_EVENTS = {}
for _, event in ipairs(TR.PROBE_EVENT_LIST) do TR.PROBE_EVENTS[event] = true end

-- P4 (sections): whether a section hands over. True for every section in
-- TR.SECTIONS and every module nobody knows. If a section turns out always
-- filled on Forever (in the open world), it returns `not st.forever` for that key.
function TR.SectionHandsOver(key)
	return true
end

------------------------------------------------------------------ the probes

local Probes = {}
TR.Probes = Probes

local function Plain(value)
	return value ~= nil and not issecretvalue(value)
end

-- A function of a namespace table, or nil: a client without the namespace or the
-- function answers no.
local function Api(namespace, name)
	local table_ = namespace and _G[namespace]
	local fn = type(table_) == 'table' and table_[name]
	return type(fn) == 'function' and fn or nil
end

local function Global(name)
	local fn = _G[name]
	return type(fn) == 'function' and fn or nil
end

-- A plain, non-empty list.
local function HasAny(list)
	return type(list) == 'table' and not issecretvalue(list) and next(list) ~= nil
end

-- Whether a task quest (GetTasksTable) is one Blizzard's bonus objectives module
-- (world false) or world quests module (world true) lays out: not watched, a world
-- quest or not as asked, in its area (isInArea) with a number of objectives
-- (Blizzard_BonusObjectiveTracker.lua AddQuest: `numObjectives and isInArea`).
-- nil for an API missing, so a probe answers no.
local function TaskShows(questID, world)
	local isWorldQuest, watchType = Api('C_QuestLog', 'IsWorldQuest'), Api('C_QuestLog', 'GetQuestWatchType')
	local taskInfo = Global('GetTaskInfo')
	if not (isWorldQuest and watchType and taskInfo and Plain(questID)) then return false end
	local isWorld = isWorldQuest(questID)
	if not Plain(isWorld) or (isWorld == true) ~= world then return false end
	if watchType(questID) ~= nil then return false end
	local inArea, _, objectives = taskInfo(questID)
	return Plain(inArea) and inArea == true and Plain(objectives) and type(objectives) == 'number'
end

local function AnyTask(world)
	local tasks = Global('GetTasksTable')
	if not tasks then return false end
	local list = tasks()
	if type(list) ~= 'table' then return false end
	for _, questID in ipairs(list) do
		if TaskShows(questID, world) then return true end
	end
	return false
end

-- Scenarios, dungeons, delves, proving grounds, the Maw's: the number of stages
-- above 0, Blizzard's own test (`isInScenario = numStages > 0`). A Mythic+ run is
-- a scenario too; an active challenge mode counts as well.
function Probes.Scenario()
	local info = Api('C_Scenario', 'GetInfo')
	if info then
		local _, _, stages = info()
		if Plain(stages) and type(stages) == 'number' and stages > 0 then return true end
	end
	local active = Api('C_ChallengeMode', 'IsChallengeModeActive')
	if active then
		local isActive = active()
		if Plain(isActive) and isActive == true then return true end
	end
	return false
end

-- Zone widgets: the objective tracker's widget container shows any.
function Probes.Widgets()
	local container = _G.ObjectiveTrackerUIWidgetContainer
	if not (container and type(container.GetNumWidgetsShowing) == 'function') then return false end
	local count = container:GetNumWidgetsShowing()
	return Plain(count) and type(count) == 'number' and count > 0
end

-- Bonus objectives: a task of the area that isn't a world quest or watched.
function Probes.Bonus()
	return AnyTask(false)
end

-- World quests: one watched (tracked), or one of the area not watched.
function Probes.WorldQuests()
	local watches = Api('C_QuestLog', 'GetNumWorldQuestWatches')
	if watches then
		local count = watches()
		if Plain(count) and type(count) == 'number' and count > 0 then return true end
	end
	return AnyTask(true)
end

-- Achievements: a tracked one not earned by me (GetAchievementInfo's 13th return,
-- Blizzard's own filter).
function Probes.Achievements()
	local tracked, info = Api('C_ContentTracking', 'GetTrackedIDs'), Global('GetAchievementInfo')
	local kinds = _G.Enum and _G.Enum.ContentTrackingType
	if not (tracked and info and kinds and Plain(kinds.Achievement)) then return false end
	local ids = tracked(kinds.Achievement)
	if type(ids) ~= 'table' then return false end
	for _, id in ipairs(ids) do
		if Plain(id) then
			local earned = select(13, info(id))
			if Plain(earned) and not earned then return true end
		end
	end
	return false
end

-- Professions: tracked recipes, or tracked recrafts.
function Probes.Professions()
	local recipes = Api('C_TradeSkillUI', 'GetRecipesTracked')
	if not recipes then return false end
	return HasAny(recipes(false)) or HasAny(recipes(true))
end

-- A tracked list's task (activity, endeavor) that isn't completed: `trackedIDs`
-- of the list, each looked up for its info.
local function AnyUncompleted(tracked, info)
	if not (tracked and info) then return false end
	local list = tracked()
	local ids = type(list) == 'table' and list.trackedIDs
	if type(ids) ~= 'table' then return false end
	for _, id in ipairs(ids) do
		if Plain(id) then
			local entry = info(id)
			if type(entry) == 'table' and Plain(entry.completed) and not entry.completed then return true end
		end
	end
	return false
end

-- Monthly activities (the Traveler's Log).
function Probes.Activities()
	return AnyUncompleted(Api('C_PerksActivities', 'GetTrackedPerksActivities'), Api('C_PerksActivities', 'GetPerksActivityInfo'))
end

-- Endeavors (neighborhood initiative tasks).
function Probes.Endeavors()
	return AnyUncompleted(Api('C_NeighborhoodInitiative', 'GetTrackedInitiativeTasks'), Api('C_NeighborhoodInitiative', 'GetInitiativeTaskInfo'))
end

-- Collection tracking: any tracked content of a type but achievements
-- (appearances, mounts, decor).
function Probes.Collections()
	local tracked = Api('C_ContentTracking', 'GetTrackedIDs')
	local kinds = _G.Enum and _G.Enum.ContentTrackingType
	if not (tracked and type(kinds) == 'table') then return false end
	for _, kind in pairs(kinds) do
		if Plain(kind) and kind ~= kinds.Achievement and HasAny(tracked(kind)) then return true end
	end
	return false
end

-- Whether a module's state and hasContents (read after its layout) say it has
-- content: NotShown (objectives, no room), ShownPartially or ShownFully, or
-- hasContents. Skipped and NoObjectives don't.
function TR.ModuleHasContent(state, hasContents)
	if Plain(hasContents) and hasContents then return true end
	if not (Plain(state) and type(state) == 'number') then return false end
	local states = _G.ObjectiveTrackerModuleState
	local first = type(states) == 'table' and states.NotShown or 3
	return state >= first
end

-- Whether a section is needed: it has content now (seen), or had some less than
-- TR.HOLD seconds ago (lastSeen, a time; nil for never).
function Probes.Held(seen, lastSeen, now)
	if seen then return true end
	return lastSeen ~= nil and now - lastSeen < TR.HOLD
end

------------------------------------------------------------------ the pass

-- Made with the tracker: what each section last had (seen), when it last had
-- content (last), and what a module's layout last said (content, by section key
-- or by an unknown module's name).
function TR:BuildProbes()
	self.sectionSeen, self.sectionLast, self.moduleContent = {}, {}, {}
	self.moduleKeys = setmetatable({}, { __mode = 'k' })
	self.unknownKeys = {}
	self.unknownSaid = {}
end

-- A module's layout finished (its Update ran, which set state and hasContents):
-- what it says is kept and a probe pass asked for. Runs inside Blizzard's layout
-- from the post-hook, so it only reads and writes SaftUI's own tables.
function TR:ModuleUpdated(module, key)
	key = key or self.moduleKeys[module]
	if not key then return end
	local has = TR.ModuleHasContent(module.state, module.hasContents)
	self.moduleContent[key] = has
	if self.unknownKeys[key] == nil and not self.sectionByKey[key] then
		self.unknownKeys[key] = true
	end
	if has and self.unknownKeys[key] and not self.unknownSaid[key] then
		self.unknownSaid[key] = true
		st:Print(("Blizzard's tracker has a section SaftUI doesn't know (%s); Blizzard's tracker shows while it has content."):format(key))
	end
	self:RunProbes()
end

TR.sectionByKey = {}
for _, section in ipairs(TR.SECTIONS) do TR.sectionByKey[section.key] = section end

-- Asks for a probe pass on the next frame: any number of asks in a frame make one
-- pass (one timer, one function), so a burst of events and module layouts reads
-- the game's data once.
local function PassTimer()
	TR.probePending = false
	TR:ProbePass()
end

function TR:RunProbes()
	if not self.built or not self.blizzardFrame or self.probePending then return end
	self.probePending = true
	C_Timer.After(0, PassTimer)
end

-- The pass: every section's probe and module signal, in the table's order, then
-- the unknown modules'. The handover follows. A section held but without content
-- now asks for the pass again when its hold ends.
function TR:ProbePass()
	if not self.built or not self.blizzardFrame then return end
	local now = GetTime()
	self:WatchModules()
	local seen, last = self.sectionSeen, self.sectionLast
	local handHover = TR.SectionHandsOver
	for _, section in ipairs(TR.SECTIONS) do
		local key, has = section.key, false
		if handHover(key) then
			local probe = TR.Probes[section.probe]
			if probe then
				local ok, result = xpcall(probe, geterrorhandler())
				has = ok and result == true
			end
			has = has or self.moduleContent[key] == true
		end
		seen[key] = has
		if has then last[key] = now end
	end
	for key in pairs(self.unknownKeys) do
		local has = handHover(key) and self.moduleContent[key] == true
		seen[key] = has
		if has then last[key] = now end
	end
	-- The hold's end needs a pass of its own: nothing else may happen then.
	local soonest
	for key, lastSeen in pairs(last) do
		if not seen[key] then
			local left = TR.HOLD - (now - lastSeen)
			if left > 0 and (not soonest or left < soonest) then soonest = left end
		end
	end
	if soonest then
		local due = now + soonest
		if not self.retryAt or self.retryAt > due or self.retryAt <= now then
			self.retryAt = due
			C_Timer.After(soonest + 0.05, function()
				if self.retryAt and self.retryAt <= GetTime() then self.retryAt = nil end
				self:RunProbes()
			end)
		end
	end
	self:UpdateHandover()
end

-- The sections needed now, as keys: the table's order, then the unknown modules
-- by name. A section with content counts; one without keeps counting for
-- TR.HOLD seconds.
function TR:NeededSections()
	local needed = {}
	if not self.sectionSeen then return needed end
	local now = GetTime()
	for _, section in ipairs(TR.SECTIONS) do
		local key = section.key
		if TR.Probes.Held(self.sectionSeen[key], self.sectionLast[key], now) then needed[#needed + 1] = key end
	end
	local unknown = {}
	for key in pairs(self.unknownKeys) do
		if TR.Probes.Held(self.sectionSeen[key], self.sectionLast[key], now) then unknown[#unknown + 1] = key end
	end
	table.sort(unknown)
	for _, key in ipairs(unknown) do needed[#needed + 1] = key end
	return needed
end
