-- How SaftUI's tracker knows a section it doesn't draw has content
-- (SaftUI-Tracker/probes.lua, TR:WatchModules in blizzard.lua; design: "How
-- SaftUI knows a section has content"):
--   - TR.SECTIONS, in the design's order, with Blizzard's module for each;
--   - one probe per section on the game's own data, each yes and no on its API
--     and no with the API missing (a client without it);
--   - the module signal: a post-hook on each module's own Update, read through
--     the fixture's OT.run_update (Blizzard's own call), asking for a probe pass
--     on the next frame; a Skipped module with content found by its probe; an
--     unknown module with content handing over, named once a session in chat;
--   - the 2 second hold (stub.time), at most one pass a frame, and
--     TR.SectionHandsOver (P4) holding one section back.
-- On both clients. Real: SaftUI-Tracker's files over the section stubs
-- (tests/wow/quests.lua) and Blizzard's tracker from the Misc fixture.
local RW = load_test_file('tracker/rows_world.lua')
local TW = RW.TW

local ACHIEVEMENT = 2 -- Enum.ContentTrackingType.Achievement

local function printed(fn)
	local real, lines = print, {}
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

local function world(client)
	local st, TR = RW.world({ client = client, blizzard = true, screen = { 1000, 600 } })
	return st, TR, TW.OT
end

local function keys(TR) return table.concat(TR:NeededSections(), ',') end

local function both(name, fn)
	for _, client in ipairs({ 'forever', 'retail' }) do
		test(name .. ' [' .. client .. ']', function()
			local st, TR, OT = world(client)
			fn(st, TR, OT, client)
			eq(#take_errors(), 0, client .. ': no error reported')
		end)
	end
end

------------------------------------------------------------------ the table

test('TR.SECTIONS: the design\'s nine, in order, each with its Blizzard module', function()
	local _, TR = world('forever')
	local expected = {
		{ 'scenario', 'Scenario', 'ScenarioObjectiveTracker' },
		{ 'widgets', 'Zone widgets', 'UIWidgetObjectiveTracker' },
		{ 'bonus', 'Bonus objectives', 'BonusObjectiveTracker' },
		{ 'world', 'World quests', 'WorldQuestObjectiveTracker' },
		{ 'achievements', 'Achievements', 'AchievementObjectiveTracker' },
		{ 'professions', 'Professions', 'ProfessionsRecipeTracker' },
		{ 'activities', 'Monthly activities', 'MonthlyActivitiesObjectiveTracker' },
		{ 'endeavors', 'Endeavors', 'InitiativeTasksObjectiveTracker' },
		{ 'collections', 'Collection tracking', 'AdventureObjectiveTracker' },
	}
	eq(#TR.SECTIONS, #expected, 'nine sections')
	for i, row in ipairs(expected) do
		local section = TR.SECTIONS[i]
		eq(section.key .. '|' .. section.name .. '|' .. section.module, table.concat(row, '|'), 'section ' .. i)
	end
	eq(TR.HOLD, 2, 'the hold is 2 seconds')
	for _, section in ipairs(TR.SECTIONS) do
		check(section.module ~= 'QuestObjectiveTracker' and section.module ~= 'CampaignQuestObjectiveTracker', 'the two quest modules are never read')
		eq(TR.SectionHandsOver(section.key), true, section.key .. ' hands over (P4 as designed)')
	end
	eq(TR.SectionHandsOver('SomeNewObjectiveTracker'), true, 'and so does a module nobody knows')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the probes

-- Each probe: set the data so it says yes, check, clear it, check no; then take
-- its API away (the namespace, then the function) and check no again.
both('every probe says yes on its data, no without it, and no with its API missing', function(st, TR)
	local P = TR.Probes
	local probes = stub.probes
	local cases = {
		{
			name = 'Scenario', apis = { 'C_Scenario', 'C_ChallengeMode' },
			yes = function() probes.scenario = { stages = 3, stage = 1 } end,
			no = function() probes.scenario = { stages = 0 } probes.challenge = false end,
			missing = 'C_Scenario',
		},
		{
			name = 'Widgets',
			yes = function() TW.OT.set_widgets(2) end,
			no = function() TW.OT.set_widgets(0) end,
			missing = 'ObjectiveTrackerUIWidgetContainer',
		},
		{
			name = 'Bonus',
			yes = function()
				probes.tasks = { 11 }
				probes.task_info = { [11] = { inArea = true, objectives = 2 } }
			end,
			no = function() probes.tasks = {} end,
			missing = 'GetTasksTable',
		},
		{
			name = 'WorldQuests',
			yes = function() probes.world_watches = 1 end,
			no = function() probes.world_watches = 0 end,
			missing = 'C_QuestLog.GetNumWorldQuestWatches',
		},
		{
			name = 'Achievements',
			yes = function()
				probes.tracked = { [ACHIEVEMENT] = { 500 } }
				probes.achievements = { [500] = { earned = false } }
			end,
			no = function() probes.tracked = {} end,
			missing = 'C_ContentTracking',
		},
		{
			name = 'Professions',
			yes = function() probes.recipes = { normal = { 7 }, recraft = {} } end,
			no = function() probes.recipes = {} end,
			missing = 'C_TradeSkillUI',
		},
		{
			name = 'Activities',
			yes = function() probes.perks = { ids = { 3 }, info = { [3] = { completed = false } } } end,
			no = function() probes.perks = {} end,
			missing = 'C_PerksActivities',
		},
		{
			name = 'Endeavors',
			yes = function() probes.initiative = { ids = { 4 }, info = { [4] = { completed = false } } } end,
			no = function() probes.initiative = {} end,
			missing = 'C_NeighborhoodInitiative',
		},
		{
			name = 'Collections',
			yes = function() probes.tracked = { [1] = { 9 } } end,
			no = function() probes.tracked = {} end,
			missing = 'C_ContentTracking',
		},
	}
	for _, case in ipairs(cases) do
		local probe = P[case.name]
		check(type(probe) == 'function', case.name .. ' is a probe')
		case.no()
		eq(probe(), false, case.name .. ': no without its data')
		case.yes()
		eq(probe(), true, case.name .. ': yes with it')
		-- The API missing (a client that lacks it) answers no, never an error.
		local first, rest = case.missing:match('^([%w_]+)%.?([%w_]*)$')
		local holder = _G[first]
		if rest ~= '' then
			local saved = holder[rest]
			holder[rest] = nil
			eq(probe(), false, case.name .. ': no with ' .. case.missing .. ' missing')
			holder[rest] = saved
		else
			_G[first] = nil
			eq(probe(), false, case.name .. ': no with ' .. case.missing .. ' missing')
			_G[first] = holder
		end
		eq(probe(), true, case.name .. ': yes again once it is back')
		case.no()
	end
end)

both('the probes follow the design\'s table in detail', function(st, TR)
	local P, probes = TR.Probes, stub.probes
	-- Scenario: the stage count above 0, or an active challenge mode.
	probes.scenario = { stages = 0 }
	eq(P.Scenario(), false, 'no stages: no scenario')
	probes.challenge = true
	eq(P.Scenario(), true, 'a challenge mode that is active: a Mythic+ scenario')
	probes.challenge = false

	-- Bonus: a task that is not a world quest or watched, in its area, with a number of objectives.
	probes.tasks = { 21, 22, 23 }
	probes.task_info = { [21] = { inArea = false, objectives = 1 }, [22] = { inArea = true, objectives = nil }, [23] = { inArea = true, objectives = 0 } }
	eq(P.Bonus(), true, 'in the area with a number of objectives (0 counts: Blizzard tests numObjectives for nil only)')
	probes.task_info[23] = { inArea = true }
	eq(P.Bonus(), false, 'a task out of its area, or with no objectives number: no')
	probes.task_info[21] = { inArea = true, objectives = 1 }
	probes.world = { [21] = true }
	eq(P.Bonus(), false, 'a world quest is the world quests\' not a bonus objective')
	probes.world = {}
	probes.watched_tasks = { [21] = true }
	eq(P.Bonus(), false, 'and a watched one is the quest module\'s')
	probes.watched_tasks = {}
	eq(P.Bonus(), true, 'neither: yes')

	-- World quests: a watched world quest, or an area world quest not watched.
	probes.tasks, probes.world_watches = { 21 }, 0
	probes.world = { [21] = true }
	eq(P.WorldQuests(), true, 'a world quest of the area: yes')
	probes.task_info[21] = { inArea = false, objectives = 1 }
	eq(P.WorldQuests(), false, 'out of its area: no')
	probes.world_watches = 2
	eq(P.WorldQuests(), true, 'a tracked world quest: yes')
	probes.world_watches, probes.tasks, probes.world = 0, {}, {}

	-- Achievements: a tracked one not yet earned by me.
	probes.tracked = { [ACHIEVEMENT] = { 5, 6 } }
	probes.achievements = { [5] = { earned = true }, [6] = { earned = true } }
	eq(P.Achievements(), false, 'every tracked one earned: no')
	probes.achievements[6].earned = false
	eq(P.Achievements(), true, 'one not earned: yes')
	probes.tracked = { [ACHIEVEMENT] = {} }
	eq(P.Achievements(), false, 'none tracked: no')
	-- Collection tracking: any type but achievements.
	probes.tracked = { [ACHIEVEMENT] = { 5 } }
	eq(P.Collections(), false, 'a tracked achievement is not a collection')
	for _, kind in ipairs({ 0, 1, 3 }) do
		probes.tracked = { [kind] = { 77 } }
		eq(P.Collections(), true, 'type ' .. kind .. ' (appearance, mount, decor): yes')
	end
	probes.tracked = {}

	-- Professions: tracked recipes, regular or recrafts.
	probes.recipes = { normal = {}, recraft = { 8 } }
	eq(P.Professions(), true, 'a recraft recipe: yes')
	probes.recipes = { normal = {}, recraft = {} }
	eq(P.Professions(), false, 'none: no')

	-- Activities and endeavors: tracked and not completed.
	probes.perks = { ids = { 3 }, info = { [3] = { completed = true } } }
	eq(P.Activities(), false, 'a completed activity: no')
	probes.perks = { ids = { 3 }, info = {} }
	eq(P.Activities(), false, 'one the game has no info for: no')
	probes.perks.info[3] = { completed = false }
	eq(P.Activities(), true, 'not completed: yes')
	probes.initiative = { ids = { 4 }, info = { [4] = { completed = true } } }
	eq(P.Endeavors(), false, 'a completed endeavor: no')
	probes.initiative.info[4].completed = false
	eq(P.Endeavors(), true, 'not completed: yes')
end)

both('a secret value from a probe\'s API is no, never an error', function(st, TR)
	local S = load_test_file('lib/secrets.lua')
	S.install()
	local P = TR.Probes
	stub.probes.scenario = { stages = S.secret('stages') }
	eq(P.Scenario(), false, 'a secret stage count: no')
	stub.probes.scenario = nil
	TW.OT.set_widgets(S.secret('widgets'))
	eq(P.Widgets(), false, 'a secret widget count: no')
end)

------------------------------------------------------------------ the module signal

test('TR.ModuleHasContent: NotShown, ShownPartially and ShownFully, or hasContents', function()
	local _, TR = world('forever')
	local E = ObjectiveTrackerModuleState
	eq(E.Skipped .. E.ShownFully, '15', 'the enum is 1 to 5')
	local cases = {
		{ E.Skipped, false, false }, { E.NoObjectives, false, false }, { E.NotShown, false, true },
		{ E.ShownPartially, false, true }, { E.ShownFully, false, true },
		{ E.Skipped, true, true }, { E.NoObjectives, true, true }, { E.NotShown, true, true },
	}
	for _, case in ipairs(cases) do
		eq(TR.ModuleHasContent(case[1], case[2]), case[3], 'state ' .. case[1] .. ', hasContents ' .. tostring(case[2]))
	end
	eq(TR.ModuleHasContent(nil, nil), false, 'nothing read: no')
	eq(#take_errors(), 0, 'no errors')
end)

both('Blizzard\'s own Update of a module is hooked: it asks for a pass on the next frame and the section counts', function(st, TR, OT)
	eq(keys(TR), '', 'nothing needed at first')
	local passes = 0
	local pass = TR.ProbePass
	TR.ProbePass = function(...) passes = passes + 1 return pass(...) end
	OT.run_update('ScenarioObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	eq(passes, 0, 'nothing runs inside Blizzard\'s call')
	RW.later(0.1)
	check(passes >= 1, 'a pass ran on the next frame')
	eq(keys(TR), 'scenario', 'the scenario module with content: Scenario')
	-- The widgets module counts the same way, in order.
	OT.run_update('UIWidgetObjectiveTracker', ObjectiveTrackerModuleState.NotShown, false)
	RW.later(0.1)
	eq(keys(TR), 'scenario,widgets', 'NotShown counts, in the table\'s order')
	-- An empty module doesn't, and after the hold the section drops.
	OT.run_update('ScenarioObjectiveTracker', ObjectiveTrackerModuleState.NoObjectives, false)
	RW.later(0.1)
	eq(keys(TR), 'scenario,widgets', 'still held for 2 seconds')
	RW.later(TR.HOLD + 0.1)
	eq(keys(TR), 'widgets', 'the scenario dropped after the hold')
	-- The quest modules are never read.
	OT.run_update('QuestObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	OT.run_update('CampaignQuestObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	RW.later(0.1)
	eq(keys(TR), 'widgets', 'the two quest modules change nothing')
	eq(table.concat(OT.stray, ','), '', 'SaftUI called none of the modules\' state-writing methods')
end)

both('a module hooked once, however often SaftUI sets up', function(st, TR, OT)
	local update = OT.modules.ScenarioObjectiveTracker.Update
	TR:WatchModules()
	TR:WatchModules()
	check(OT.modules.ScenarioObjectiveTracker.Update == update, 'a second WatchModules hooks nothing again')
	local count = 0
	local pass = TR.ProbePass
	TR.ProbePass = function(...) count = count + 1 return pass(...) end
	OT.run_update('AchievementObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	RW.later(0.1)
	eq(count, 1, 'one pass for one Update: the hook is not stacked')
end)

both('a module Skipped for room but with content is found by its probe', function(st, TR, OT)
	-- Blizzard's quests fill its height: the achievements module is Skipped whatever it holds.
	OT.run_update('AchievementObjectiveTracker', ObjectiveTrackerModuleState.Skipped, false)
	RW.later(0.1)
	eq(keys(TR), '', 'its state says nothing')
	stub.probes.tracked = { [ACHIEVEMENT] = { 500 } }
	stub.probes.achievements = { [500] = { earned = false } }
	stub.fire_event('TRACKED_ACHIEVEMENT_LIST_CHANGED')
	RW.later(0.1)
	eq(keys(TR), 'achievements', 'the probe finds it')
end)

both('an unknown module with content hands over, and says so once a session', function(st, TR, OT)
	local lines = printed(function()
		OT.add_module('FuturePatchObjectiveTracker')
		OT.run_update('FuturePatchObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
		-- Nothing hooks it yet: a pass finds it (the next event, or any module's layout).
		stub.fire_event('ZONE_CHANGED_NEW_AREA')
		RW.later(0.1)
		-- Hooked now: each later layout asks for a pass, and the line is not said again.
		for _ = 1, 3 do
			OT.run_update('FuturePatchObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
			RW.later(0.1)
		end
		TR:ProbePass()
		RW.later(1)
	end)
	eq(keys(TR), 'FuturePatchObjectiveTracker', 'it counts, by its own name')
	local said = 0
	for _, line in ipairs(lines) do
		if line:find("Blizzard's tracker has a section SaftUI doesn't know (FuturePatchObjectiveTracker); Blizzard's tracker shows while it has content.", 1, true) then said = said + 1 end
	end
	eq(said, 1, 'one chat line, once')
	eq(TR:HandoverText(), "Showing Blizzard's tracker for: FuturePatchObjectiveTracker.", 'the Now line names it')
	-- An unknown module without content says nothing.
	local lines2 = printed(function()
		OT.add_module('QuietObjectiveTracker')
		OT.run_update('QuietObjectiveTracker', ObjectiveTrackerModuleState.NoObjectives, false)
		RW.later(0.1)
	end)
	eq(#lines2, 0, 'nothing said for an empty one')
end)

both('TR.SectionHandsOver false for one key keeps it from handing over (the P4 seam)', function(st, TR, OT)
	local hands = TR.SectionHandsOver
	TR.SectionHandsOver = function(key) return key ~= 'widgets' end
	OT.set_widgets(3)
	OT.run_update('UIWidgetObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	stub.probes.scenario = { stages = 2 }
	stub.fire_event('SCENARIO_UPDATE')
	RW.later(0.1)
	eq(keys(TR), 'scenario', 'zone widgets stay out, the scenario hands over')
	TR.SectionHandsOver = hands
end)

------------------------------------------------------------------ the hold and the passes

test('TR.Probes.Held: counts from the moment it has content until 2 s without any', function()
	local _, TR = world('forever')
	local Held = TR.Probes.Held
	eq(Held(true, nil, 10), true, 'content now: needed')
	eq(Held(true, 3, 10), true, 'content now, whenever it was last seen')
	eq(Held(false, nil, 10), false, 'never seen: not needed')
	eq(Held(false, 10, 10), true, 'just lost: still needed')
	eq(Held(false, 10, 11.99), true, '1.99 s without: still needed')
	eq(Held(false, 10, 12), false, '2 s without: not needed')
	eq(Held(false, 10, 30), false, 'long after: not')
	eq(#take_errors(), 0, 'no errors')
end)

both('a widget that flickers at an area\'s edge holds the section for 2 seconds', function(st, TR, OT)
	OT.set_widgets(1)
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.1)
	eq(keys(TR), 'widgets', 'widgets showing: needed')
	OT.set_widgets(0)
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.1)
	eq(keys(TR), 'widgets', 'gone: held')
	OT.set_widgets(1)
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(1.5)
	OT.set_widgets(0)
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(1.9)
	eq(keys(TR), 'widgets', 'the hold counts from the last time it had content, not the first')
	RW.later(0.2)
	eq(keys(TR), '', 'and ends 2 s after it: with no event, a timer asked for the pass')
end)

both('at most one pass a frame, however many events and module updates', function(st, TR, OT)
	local evaluations = 0
	local scenario = TR.Probes.Scenario
	TR.Probes.Scenario = function() evaluations = evaluations + 1 return scenario() end
	for _ = 1, 10 do
		stub.fire_event('SCENARIO_UPDATE')
		stub.fire_event('QUEST_LOG_UPDATE')
		OT.run_update('BonusObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
		TR:RunProbes()
	end
	eq(evaluations, 0, 'nothing is read inside the frame itself')
	RW.later(0.1)
	eq(evaluations, 1, 'one pass on the next frame')
	RW.later(0.1)
	eq(evaluations, 1, 'and none after it with nothing asked')
	stub.fire_event('SCENARIO_UPDATE')
	RW.later(0.1)
	eq(evaluations, 2, 'a later event is a later pass')
	TR.Probes.Scenario = scenario
end)

both('every event of the design\'s list asks for a pass', function(st, TR)
	local events = {
		'SCENARIO_UPDATE', 'SCENARIO_CRITERIA_UPDATE', 'SCENARIO_COMPLETED', 'CHALLENGE_MODE_START',
		'CHALLENGE_MODE_COMPLETED', 'CHALLENGE_MODE_RESET', 'CONTENT_TRACKING_UPDATE',
		'TRACKED_ACHIEVEMENT_LIST_CHANGED', 'TRACKED_ACHIEVEMENT_UPDATE', 'ACHIEVEMENT_EARNED',
		'TRACKED_RECIPE_UPDATE', 'PERKS_ACTIVITIES_TRACKED_LIST_CHANGED', 'PERKS_ACTIVITY_COMPLETED',
		'INITIATIVE_TASKS_TRACKED_LIST_CHANGED', 'NEIGHBORHOOD_INITIATIVE_UPDATED', 'QUEST_LOG_UPDATE',
		'QUEST_WATCH_LIST_CHANGED', 'ZONE_CHANGED_NEW_AREA', 'PLAYER_ENTERING_WORLD',
	}
	for _, event in ipairs(events) do
		RW.later(1)
		local passes = 0
		local pass = TR.ProbePass
		TR.ProbePass = function(...) passes = passes + 1 return pass(...) end
		stub.fire_event(event)
		RW.later(1)
		TR.ProbePass = pass
		check(passes >= 1, event .. ' asks for a pass')
	end
end)

test('with the switch off no probe, hook or event exists', function()
	local st, TR = TW.world({ on = false, blizzard = true })
	local OT = TW.OT
	local update = OT.modules.ScenarioObjectiveTracker.Update
	stub.probes.scenario = { stages = 3 }
	stub.fire_event('SCENARIO_UPDATE')
	stub.run_timers()
	check(OT.modules.ScenarioObjectiveTracker.Update == update, 'no module hooked')
	eq(TW.counts.events, 0, 'no event registered')
	eq(TW.counts.hooks, 0, 'no hook')
	check(TR.handoverState == nil, 'no handover state')
	eq(#take_errors(), 0, 'no errors')
end)


------------------------------------------------------------------ fix round 1

both('an error in the module hook is reported once and Blizzard\'s layout goes on; the next layout still asks for a pass', function(st, TR, OT)
	local real = TR.ModuleUpdated
	local fail = true
	TR.ModuleUpdated = function(...)
		if fail then fail = false error('boom in the hook') end
		return real(...)
	end
	local ok = pcall(OT.run_update, 'ScenarioObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	check(ok, 'Blizzard\'s call returned: the error did not escape the hook')
	local errors = take_errors()
	eq(#errors, 1, 'one error reported')
	check(errors[1]:find('boom in the hook', 1, true), 'the hook\'s own')
	OT.run_update('ScenarioObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
	RW.later(0.1)
	eq(keys(TR), 'scenario', 'the next layout asked for a pass')
	TR.ModuleUpdated = real
end)

both('TR.SectionHandsOver false for an unknown module keeps it from handing over too', function(st, TR, OT)
	local hands = TR.SectionHandsOver
	TR.SectionHandsOver = function(key) return key ~= 'HeldBackObjectiveTracker' end
	printed(function()
		OT.add_module('HeldBackObjectiveTracker')
		OT.run_update('HeldBackObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
		stub.fire_event('ZONE_CHANGED_NEW_AREA')
		RW.later(0.1)
		OT.run_update('HeldBackObjectiveTracker', ObjectiveTrackerModuleState.ShownFully, true)
		RW.later(0.1)
	end)
	eq(keys(TR), '', 'it never counts')
	TR.SectionHandsOver = hands
end)

both('Achievements: Blizzard\'s own filter, wasEarnedByMe, not completed; and not while the arena shows only its own', function(st, TR)
	local P, probes = TR.Probes, stub.probes
	probes.tracked = { [ACHIEVEMENT] = { 9 } }
	probes.achievements = { [9] = { completed = true, earned = false } }
	eq(P.Achievements(), true, 'completed account-wide by another character, not earned by me: Blizzard lists it')
	probes.achievements = { [9] = { completed = true, earned = true } }
	eq(P.Achievements(), false, 'earned by me: no')
	probes.achievements = { [9] = { earned = false } }
	stub.instance = { type = 'arena' }
	eq(P.Achievements(), false, 'in an arena Blizzard shows only arena achievements: SaftUI does not ask for the tracker for one it may not draw')
	stub.instance = nil
	eq(P.Achievements(), true, 'outside it: yes')
end)

both('Collections: Blizzard\'s gate and its types, as its module lays them out', function(st, TR)
	local P, probes = TR.Probes, stub.probes
	probes.tracked = { [0] = { 5 }, [1] = { 6 }, [3] = { 7 } }
	eq(P.Collections(), true, 'tracked, enabled')
	probes.collections_enabled = false
	eq(P.Collections(), false, 'content tracking off: Blizzard draws nothing')
	probes.collections_enabled = true
	probes.collectable_types = { 1 }
	probes.tracked = { [0] = { 5 } }
	eq(P.Collections(), false, 'a type the game does not collect: no')
	probes.tracked = { [1] = { 6 } }
	eq(P.Collections(), true, 'one it does: yes')
	local gate = C_ContentTracking.GetCollectableSourceTrackingEnabled
	C_ContentTracking.GetCollectableSourceTrackingEnabled = nil
	eq(P.Collections(), false, 'without the gate\'s API: no')
	C_ContentTracking.GetCollectableSourceTrackingEnabled = gate
end)

both('two sections held at once: the earlier one drops on time, with no event', function(st, TR, OT)
	-- Both have content at T; the widgets go at once, the scenario is seen again at T + 1.5.
	OT.set_widgets(1)
	stub.probes.scenario = { stages = 2 }
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.1)
	OT.set_widgets(0)
	RW.later(1.4)
	stub.fire_event('SCENARIO_UPDATE')
	RW.later(0.1)
	stub.probes.scenario = { stages = 0 }
	stub.fire_event('SCENARIO_UPDATE')
	RW.later(0.1)
	eq(keys(TR), 'scenario,widgets', 'both held at T + 1.7')
	RW.later(0.5)
	eq(keys(TR), 'scenario', 'T + 2.2: the widgets (lost first) dropped when their hold ended, by the retry alone: ' .. keys(TR))
	RW.later(1.5)
	eq(keys(TR), '', 'then the scenario, 2 s after it last had content')
end)

both('three sections held at once: each drops on its own retry, the soonest first, not at the last one\'s end', function(st, TR, OT)
	-- Lost at T (the widgets), T + 0.5 (the scenario) and T + 1.0 (the achievements):
	-- each pass is an event of the same kind and nothing else happens after T + 1.1,
	-- so only the hold's retry timer can run the pass that drops one. A retry that
	-- fires with two sections still held must set the next one for the soonest
	-- (the scenario's, T + 2.5), not the latest (T + 3.0).
	local probes = stub.probes
	OT.set_widgets(1)
	probes.scenario = { stages = 2 }
	probes.tracked = { [ACHIEVEMENT] = { 500 } }
	probes.achievements = { [500] = { earned = false } }
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.1) -- T: all three have content
	OT.set_widgets(0)
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.5) -- T + 0.5: the widgets are gone, last seen at T
	probes.scenario = { stages = 0 }
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.5) -- T + 1.0: the scenario is gone, last seen at T + 0.5
	probes.tracked = {}
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(0.1) -- T + 1.1: the achievements are gone, last seen at T + 1.0
	eq(keys(TR), 'scenario,widgets,achievements', 'T + 1.1: all three held')
	-- (what a section is held for is worked out from the clock, so the sections
	-- themselves drop whenever a pass is not run; what the handover does is decided
	-- only in a pass: so count the passes)
	local passes = 0
	local pass = TR.ProbePass
	TR.ProbePass = function(...) passes = passes + 1 return pass(...) end
	RW.later(1.1) -- T + 2.2: the widgets' hold ended at T + 2.0 (retry at T + 2.05)
	eq(keys(TR), 'scenario,achievements', 'T + 2.2: the widgets dropped')
	eq(passes, 1, 'by a pass of their own, with no event: the retry')
	RW.later(0.4) -- T + 2.6: the scenario's ended at T + 2.5, the achievements' is T + 3.0
	eq(keys(TR), 'achievements', 'T + 2.6: the scenario dropped')
	eq(passes, 2, 'by a pass of its own, at the soonest hold\'s end, not at the achievements\' (T + 3.0): ' .. passes)
	RW.later(0.5) -- T + 3.1
	eq(keys(TR), '', 'T + 3.1: then the achievements')
	eq(passes, 3, 'by a third')
	TR.ProbePass = pass
end)

both('a probe pass waiting when combat starts runs at once, as a refresh does, and its timer runs no second one', function(st, TR)
	RW.later(1)
	local runs = 0
	local scenario = TR.Probes.Scenario
	TR.Probes.Scenario = function() runs = runs + 1 return scenario() end
	stub.probes.scenario = { stages = 2 }
	stub.fire_event('SCENARIO_UPDATE')
	eq(TR.probePending, true, 'the pass is asked for, on the next frame')
	eq(runs, 0, 'and has not run')
	-- (the game runs the handlers out of lockdown, which begins after them)
	stub.fire_event('PLAYER_REGEN_DISABLED')
	eq(TR.probePending, false, 'combat starting runs it')
	eq(runs, 1, 'once')
	eq(TR.handoverState, 'blizzard', 'with what the game allows out of lockdown: SaftUI\'s hides and Blizzard\'s shows in its place')
	RW.later(1)
	eq(runs, 1, 'its timer finds nothing to run')
	TR.Probes.Scenario = scenario
end)

both('a probe that errors is reported once, and counts as no after that', function(st, TR)
	local real = TR.Probes.Bonus
	TR.Probes.Bonus = function() error('the API changed') end
	for _ = 1, 5 do
		stub.fire_event('QUEST_LOG_UPDATE')
		RW.later(0.2)
	end
	local errors = take_errors()
	eq(#errors, 1, 'one error for five passes')
	check(errors[1]:find('the API changed', 1, true), 'the probe\'s')
	eq(keys(TR), '', 'a no')
	TR.Probes.Bonus = real
end)

both('probe passes are throttled with the list: one per TR.REFRESH_GAP however many events', function(st, TR)
	RW.later(1)
	local evaluations = 0
	local scenario = TR.Probes.Scenario
	TR.Probes.Scenario = function() evaluations = evaluations + 1 return scenario() end
	for _ = 1, 30 do
		stub.fire_event('SCENARIO_UPDATE')
		RW.later(0.01)
	end
	check(evaluations <= 4, 'thirty events over 0.3 s: at most four passes, not thirty: ' .. evaluations)
	check(evaluations >= 2, 'but the stream is not starved: ' .. evaluations)
	TR.Probes.Scenario = scenario
end)

both('a pass allocates nothing of SaftUI\'s: its tables are reused', function(st, TR, OT)
	local needed = TR:NeededSections()
	stub.fire_event('SCENARIO_UPDATE')
	RW.later(0.2)
	check(TR:NeededSections() == needed, 'the needed list is the same table')
end)

both('a probe-only event marks the list dirty no more than it needs: no refresh', function(st, TR)
	RW.later(1)
	local refreshes = 0
	local refresh = TR.Refresh
	TR.Refresh = function(...) refreshes = refreshes + 1 return refresh(...) end
	stub.fire_event('SCENARIO_CRITERIA_UPDATE')
	RW.later(1)
	eq(refreshes, 0, 'no refresh for an event only the probes listen to')
	TR.Refresh = refresh
end)

both('modules with no name get keys of their own', function(st, TR, OT)
	printed(function()
		OT.add_module(nil)
		OT.add_module(nil)
		local list = OT.tracker.modules
		OT.run_update(list[#list - 1], ObjectiveTrackerModuleState.ShownFully, true)
		OT.run_update(list[#list], ObjectiveTrackerModuleState.NoObjectives, false)
		stub.fire_event('ZONE_CHANGED_NEW_AREA')
		RW.later(0.1)
		OT.run_update(list[#list - 1], ObjectiveTrackerModuleState.ShownFully, true)
		OT.run_update(list[#list], ObjectiveTrackerModuleState.NoObjectives, false)
		RW.later(0.2)
	end)
	eq(#TR:NeededSections(), 1, 'the one with content counts, and the empty one does not clear it')
end)
