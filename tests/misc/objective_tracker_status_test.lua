-- The objective tracker skin's status colors (SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua):
--   - a finished objective's line (Blizzard hands it OBJECTIVE_TRACKER_COLOR.Complete)
--     in the Completed color, a failed one (.Failed) in Failed, the rest
--     in Blizzard's normal color, as before;
--   - Blizzard's hover behaviour kept: a failed line still brightens under
--     the mouse (Blizzard's FailedHighlight) and comes back to SaftUI's color,
--     a normal line brightens and comes back, a completed line (which Blizzard
--     never highlights) stays;
--   - a pooled line handed out again with another state wearing that state's color;
--   - a color changed on the page reaching the lines at once, and
--     Skinning -> Objective tracker off, or the Blizzard theme, putting
--     Blizzard's colors back;
--   - only the lines' texts restyled (the dashes, titles and bars keep their colors);
--   - the colors live on Global settings > Colors > Objectives
--     (profile.colors.objectives), read by OT:StatusColor; a profile saved with
--     the skin's old status_colors keeps them, converted once (OTP:MoveStatusColors);
--   - the page: no color section, a description row that names where they went;
--   - styled in combat with stub.blocked empty, and no Blizzard field written.
-- On both clients.
--
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and
-- Skinning/blizzard/Blizzard_ObjectiveTracker.lua (and, for the page,
-- Blizzard_ObjectiveTrackerPosition.lua), Core's helpers and the theme
-- engine. Blizzard's tracker is fixtures/objective_tracker.lua.
local T = load_test_file('lib/theme_helpers.lua')

local st, OT, SK, skin, OTP, profile

local function world(client, opts)
	opts = opts or {}
	st = T.client(client)
	T.watch()
	if opts.page then load_editmode() end
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.setup then opts.setup(profile) end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua')
	SK = st:GetModule('Skinning')
	skin = SK:GetModule('Blizzard_ObjectiveTracker')
	OT = load_test_file('misc/fixtures/objective_tracker.lua')
	OT.build()
	if opts.page then
		load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua')
		OTP = st:GetModule('ObjectiveTracker')
		OTP:Enable()
	end
	SK:Enable()
end

local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(table.concat(OT.stray, ','), '', "SaftUI ran none of the tracker's state-writing methods")
end

local function quest_module() return OT.modules.QuestObjectiveTracker end
local function rgb(fs) return T.rgb(fs:GetTextColor()) end
local function hex(c) return T.rgb(c.r or c[1], c.g or c[2], c.b or c[3]) end

-- One quest: a normal objective, a finished one and a failed one.
local MIXED = { { id = 1, title = 'Mixed', objectives = {
	'Kill 0/8 boars', { 'Collect 5/5 tusks', 'Complete' }, { 'Escort the guard', 'Failed' },
} } }
local function mixed() return OT.layout(quest_module(), MIXED)[1] end

local COMPLETED_DEFAULT = T.rgb(0.251, 0.753, 0.251)
local FAILED_DEFAULT = T.rgb(220 / 255, 100 / 255, 100 / 255)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': a finished line in Completed, a failed one in Failed, the rest as before', function()
		world(client)
		local block = mixed()
		eq(rgb(block.usedLines[1].Text), hex(OT.NORMAL), 'an unfinished objective in the normal color')
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, "a finished one in Completed's default, the game's green dimmed")
		eq(rgb(block.usedLines[3].Text), FAILED_DEFAULT, "a failed one in Failed's default, the kit's red")
		eq(rgb(block.usedLines[2].Dash), rgb(block.usedLines[1].Dash), 'the dashes keep their color')
		eq(rgb(block.HeaderText), hex(OT.HEADER), 'and so does the title')
		eq(block.usedLines[2].Text.colorStyle, OT.COLORS.Complete, "Blizzard's own record of the line's state is untouched")
		clean()
	end)

	test(client .. ': the hover Blizzard gives a line is kept', function()
		world(client)
		local block = mixed()
		OT.hover(block, true)
		eq(rgb(block.usedLines[1].Text), T.rgb(1, 1, 1), "an unfinished line brightens, Blizzard's own")
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, 'a finished line, which Blizzard never highlights, stays')
		eq(rgb(block.usedLines[3].Text), T.rgb(1, 0.1, 0.1), "a failed line shows Blizzard's brighter red while hovered")
		OT.hover(block, false)
		eq(rgb(block.usedLines[1].Text), hex(OT.NORMAL), 'an unfinished line comes back')
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, 'a finished line the same')
		eq(rgb(block.usedLines[3].Text), FAILED_DEFAULT, "a failed line comes back to SaftUI's Failed")
		clean()
	end)

	test(client .. ': a line handed out again wears its new state', function()
		world(client)
		local block = mixed()
		OT.layout(quest_module(), { { id = 1, title = 'Mixed', objectives = {
			{ 'Kill 8/8 boars', 'Complete' }, 'Collect 0/5 tusks', { 'Escort the guard', 'Failed' },
		} } })
		eq(rgb(block.usedLines[1].Text), COMPLETED_DEFAULT, 'finished now')
		eq(rgb(block.usedLines[2].Text), hex(OT.NORMAL), "unfinished again: Blizzard's color, not a stale Completed")
		eq(rgb(block.usedLines[3].Text), FAILED_DEFAULT, 'still failed')
		clean()
	end)

	test(client .. ": a pooled line coloured, then the skin off, then handed out again with the same state: Blizzard's", function()
		world(client)
		local block = mixed()
		-- The line is freed (a quest with fewer objectives), then the skin goes off
		-- while it is pooled.
		OT.layout(quest_module(), { { id = 1, title = 'Mixed', objectives = { 'Kill 0/8 boars' } } })
		profile.skinning.objective_tracker = false
		skin:UpdateConfig()
		OT.layout(quest_module(), MIXED)
		eq(rgb(block.usedLines[2].Text), hex(OT.COLORS.Complete), "Blizzard's Complete, not a stale Completed")
		eq(rgb(block.usedLines[3].Text), hex(OT.COLORS.Failed), "Blizzard's Failed")
		clean()
	end)

	test(client .. ': a color changed on the page reaches the lines at once; its default comes back', function()
		world(client)
		local block = mixed()
		profile.colors.objectives.completed:SetRGB(0.1, 0.2, 0.9)
		profile.colors.objectives.failed:SetRGB(1, 0, 1)
		skin:UpdateConfig()
		eq(rgb(block.usedLines[2].Text), T.rgb(0.1, 0.2, 0.9), 'Completed')
		eq(rgb(block.usedLines[3].Text), T.rgb(1, 0, 1), 'Failed')
		eq(rgb(block.usedLines[1].Text), hex(OT.NORMAL), 'the rest unchanged')
		clean()
	end)

	test(client .. ": off, or under the Blizzard theme, Blizzard's colors are back; on again, ours", function()
		world(client)
		local block = mixed()
		profile.skinning.objective_tracker = false
		skin:UpdateConfig()
		eq(rgb(block.usedLines[2].Text), hex(OT.COLORS.Complete), "off: Blizzard's Complete")
		eq(rgb(block.usedLines[3].Text), hex(OT.COLORS.Failed), "off: Blizzard's Failed")
		profile.skinning.objective_tracker = true
		skin:UpdateConfig()
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, 'on again')
		T.theme('blizzard', function() SK:UpdateConfig(); st:ColorsChanged('theme') end)
		eq(rgb(block.usedLines[2].Text), hex(OT.COLORS.Complete), "Blizzard theme: Blizzard's Complete")
		eq(rgb(block.usedLines[3].Text), hex(OT.COLORS.Failed), "Blizzard theme: Blizzard's Failed")
		-- A line Blizzard lays out under its look is left as Blizzard's.
		block = OT.layout(quest_module(), MIXED)[1]
		eq(rgb(block.usedLines[2].Text), hex(OT.COLORS.Complete), 'laid out under Blizzard: left alone')
		T.theme('thick', function() SK:UpdateConfig(); st:ColorsChanged('theme') end)
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, 'back to Thick: ours')
		eq(rgb(block.usedLines[3].Text), FAILED_DEFAULT, 'back to Thick: ours')
		clean()
	end)

	test(client .. ': in combat the lines are colored with nothing blocked', function()
		world(client)
		stub.in_combat, stub.blocked = true, {}
		local block = mixed()
		OT.hover(block, true)
		OT.hover(block, false)
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, 'Completed in combat')
		eq(rgb(block.usedLines[3].Text), FAILED_DEFAULT, 'Failed in combat')
		eq(#stub.blocked, 0, 'nothing blocked')
		stub.in_combat = false
		clean()
	end)
end

test("Blizzard's color table missing leaves every line as Blizzard colored it", function()
	world('forever')
	local real = _G.OBJECTIVE_TRACKER_COLOR
	_G.OBJECTIVE_TRACKER_COLOR = nil
	local block = mixed()
	_G.OBJECTIVE_TRACKER_COLOR = real
	check(#take_errors() == 0, 'no error')
	eq(rgb(block.usedLines[2].Text), hex(OT.COLORS.Complete), "no state known: Blizzard's color")
end)

test('the page: no Objective colors section; a description row names Global settings > Colors > Objectives', function()
	world('forever', { page = true })
	load_test_file('lib/options_walk.lua')
	local general = OTP:GetConfigTable().args.general
	local row = general.args.colors
	eq(row.type, 'description', 'the colors row is a description')
	eq(row.name, 'Finished and failed objectives take Global settings > Colors > Objectives.', 'it says where they went')
	eq(row.args, nil, 'no Completed or Failed color here')
	check(general.args.position.order > row.order, 'Position stays last')
	check(general.args.font and general.args.header_font, 'the fonts stay')
	clean()
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	local function completed() return profile.colors.objectives.completed end
	local function failed() return profile.colors.objectives.failed end

	test(client .. ': a profile with the old colors keeps them on the Colors tab, once, slots AceDB dropped filled from the old defaults', function()
		world(client, { page = true, setup = function(p)
			p.objectivetracker.status_colors = { completed = { [2] = 0.9 } }
		end })
		eq(T.rgb(completed():GetRGB()), T.rgb(0.251, 0.9, 0.251), 'Completed keeps its saved slot, the rest from the old default')
		eq(T.rgb(failed():GetRGB()), FAILED_DEFAULT, 'Failed at its default')
		eq(profile.objectivetracker.status_colors, nil, 'status_colors gone')
		eq(profile.objectivetracker.colorsMoved, true, 'marked')
		completed():SetRGB(0.3, 0.3, 0.3)
		OTP:UpdateConfig()
		eq(T.rgb(completed():GetRGB()), T.rgb(0.3, 0.3, 0.3), 'a Colors tab change stays through UpdateConfig')
		clean()
	end)

	test(client .. ': a color the skin was set to before the move reaches the lines once converted', function()
		world(client, { page = true, setup = function(p)
			p.objectivetracker.status_colors = { failed = { [1] = 1, [2] = 0, [3] = 1 } }
		end })
		local block = mixed()
		eq(rgb(block.usedLines[3].Text), T.rgb(1, 0, 1), 'Failed on the lines')
		eq(rgb(block.usedLines[2].Text), COMPLETED_DEFAULT, 'Completed at its default')
		clean()
	end)

	test(client .. ': a profile switched to in combat converts before the next layout, with stub.blocked empty', function()
		world(client, { page = true })
		local block = mixed()
		stub.in_combat, stub.blocked = true, {}
		-- A profile switched to (its own tables, saved before the move), in combat.
		profile.objectivetracker.status_colors = { failed = { [3] = 0.5 } }
		profile.objectivetracker.colorsMoved = nil
		OTP:UpdateConfig()
		eq(T.rgb(profile.colors.objectives.failed:GetRGB()), T.rgb(220 / 255, 100 / 255, 0.5), 'converted by the switch')
		eq(profile.objectivetracker.status_colors, nil, 'status_colors gone')
		eq(profile.objectivetracker.colorsMoved, true, 'marked')
		eq(rgb(block.usedLines[3].Text), T.rgb(220 / 255, 100 / 255, 0.5), 'and on the lines')
		eq(#stub.blocked, 0, 'nothing blocked')
		stub.in_combat = false
		clean()
	end)

	test(client .. ': a profile with nothing saved gets only the marker', function()
		world(client, { page = true })
		eq(profile.objectivetracker.colorsMoved, true, 'marked')
		eq(profile.objectivetracker.status_colors, nil, 'nothing made')
		eq(T.rgb(completed():GetRGB()), COMPLETED_DEFAULT, 'Completed at its default')
		eq(T.rgb(failed():GetRGB()), FAILED_DEFAULT, 'Failed at its default')
		clean()
	end)

	test(client .. ": a Colors tab change recolors the skin's lines at once (st:ColorsChanged('objectives'))", function()
		world(client)
		local block = mixed()
		local fresh = 0
		local real = st.SetBackdropIn
		st.SetBackdropIn = function(...) fresh = fresh + 1; return real(...) end
		completed():SetRGB(0.1, 0.2, 0.9)
		st:ColorsChanged('objectives')
		st.SetBackdropIn = real
		eq(fresh, 0, 'the lines only, no restyle')
		eq(rgb(block.usedLines[2].Text), T.rgb(0.1, 0.2, 0.9), 'Completed on the lines')
		eq(rgb(block.usedLines[3].Text), FAILED_DEFAULT, 'Failed unchanged')
		clean()
	end)
end
