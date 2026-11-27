-- SaftUI's tracker's own colors (SaftUI-Tracker/colors.lua, the Colors tab in
-- options.lua, rows.lua's and window.lua's readers), on both clients: every
-- part follows its Global settings > Colors color (or Blizzard's progress
-- blue) until one is picked; a pick paints at once with nothing made, set or
-- measured; a part picked no longer follows Text, one not picked still does;
-- the reset follows again; Completed, Failed and Color by difficulty still win
-- over the title's and objectives' colors; a profile's own colors.
local RW = load_test_file('tracker/rows_world.lua')
local Q = RW.Q

local function colors(st) return st.config.profile.colors end

-- Color by difficulty (on by default) off, so the titles take the title color.
local function log(TR)
	TR.config.quests.difficulty = false
	stub.real_zone_text = 'A'
	Q.set({
		Q.header('A'),
		Q.quest(1, { title = 'Wolves', objectives = { { text = '1/8 Wolves', type = 'monster' }, { text = 'Bar', type = 'progressbar' } }, percent = 40 }),
		Q.quest(2, { complete = true }),
		Q.quest(3, { failed = true }),
		Q.header('B'),
		Q.quest(4, { title = 'Boars' }),
	}, { 1, 2, 3, 4 })
end

local function fill(TR)
	local v = stub.state(RW.quest(TR, 1).parts[2].bar.fill).vertex_color
	return ('%.2f %.2f %.2f'):format(v[1], v[2], v[3])
end

local function tab(TR) return TR:GetConfigTable().args.colors end

RW.both('by default every part follows: Text > Normal, Text > Muted, and the bar in Blizzard\'s blue', function(st, TR)
	log(TR)
	TR:Refresh()
	local normal, muted = RW.rgb(colors(st).text.normal), RW.rgb(colors(st).text.muted)
	eq(RW.color(TR.header.title), normal, 'the header')
	eq(RW.color(RW.zone(TR, 'A').title), normal, 'the current zone')
	eq(RW.color(RW.zone(TR, 'B').title), muted, 'another zone')
	eq(RW.color(RW.quest(TR, 1).title), normal, 'a quest title')
	eq(RW.color(RW.quest(TR, 1).parts[1].fs), normal, 'an objective')
	eq(fill(TR), '0.26 0.42 1.00', 'the bar')
	local args = tab(TR).args
	for _, part in ipairs(TR.COLOR_PARTS) do
		check(not args[part.key].default.differs(), part.key .. ' shows no reset')
		local r, g, b = args[part.key].get()
		local fr, fg, fb = args[part.key].default.value()
		eq(('%.2f %.2f %.2f'):format(r, g, b), ('%.2f %.2f %.2f'):format(fr, fg, fb), part.key .. ' reads as what it follows')
	end
end)

RW.both('a pick paints its part at once, with no frame, text or measure; reset follows again', function(st, TR)
	log(TR)
	TR:Refresh()
	local args = tab(TR).args
	local measured = RW.quest(TR, 1).title.measuredStamp
	local counter = RW.counter()
	args.header.set(nil, 0.1, 0.1, 0.1)
	args.current_zone.set(nil, 0.2, 0.2, 0.2)
	args.zone.set(nil, 0.3, 0.3, 0.3)
	args.title.set(nil, 0.4, 0.4, 0.4)
	args.objective.set(nil, 0.5, 0.5, 0.5)
	args.bar.set(nil, 0.6, 0.6, 0.6)
	eq(RW.color(TR.header.title), '0.10 0.10 0.10', 'the header')
	eq(RW.color(RW.zone(TR, 'A').title), '0.20 0.20 0.20', 'the current zone')
	eq(RW.color(RW.zone(TR, 'B').title), '0.30 0.30 0.30', 'another zone')
	eq(RW.color(RW.quest(TR, 1).title), '0.40 0.40 0.40', 'a quest title')
	eq(RW.color(RW.quest(TR, 4).title), '0.40 0.40 0.40', "another zone's quest title")
	eq(RW.color(RW.quest(TR, 1).parts[1].fs), '0.50 0.50 0.50', 'an objective')
	eq(fill(TR), '0.60 0.60 0.60', 'the bar')
	eq(counter.frames, 0, 'no frame')
	eq(counter.texts, 0, 'no text set')
	eq(RW.quest(TR, 1).title.measuredStamp, measured, 'nothing measured')
	counter.stop()
	eq(RW.color(RW.quest(TR, 2).title), RW.rgb(colors(st).objectives.completed), 'a ready quest keeps Completed')
	eq(RW.color(RW.quest(TR, 3).title), RW.rgb(colors(st).objectives.failed), 'a failed one keeps Failed')
	eq(RW.color(RW.zone(TR, 'A').count), RW.rgb(colors(st).text.muted), 'the count stays Text > Muted')
	check(args.title.default.differs(), 'a picked part shows its reset')
	eq(st.config.profile.tracker.colors.title.r, 0.4, 'saved in tracker.colors')
	-- A Text change reaches only the parts nobody picked.
	args.objective.default.reset()
	colors(st).text.normal:SetRGB(0.9, 0.8, 0.7)
	TR:OnColorsChanged('text')
	eq(RW.color(RW.quest(TR, 1).parts[1].fs), '0.90 0.80 0.70', 'a reset objective follows Text > Normal again')
	eq(RW.color(RW.quest(TR, 1).title), '0.40 0.40 0.40', 'a picked title keeps its own')
	check(not args.objective.default.differs(), 'and the reset part shows no reset')
	eq(st.config.profile.tracker.colors.objective, nil, 'its saved color is gone')
	-- A later draw reads the picks too.
	TR:Refresh()
	eq(RW.color(RW.quest(TR, 1).title), '0.40 0.40 0.40', 'a later draw')
	args.bar.default.reset()
	eq(fill(TR), '0.26 0.42 1.00', "the bar back in Blizzard's blue")
end)

RW.both('Color by difficulty wins over a picked title color; off, the pick shows', function(st, TR)
	stub.real_zone_text = 'A'
	Q.set({ Q.header('A'), Q.quest(1, { title = 'Hard', difficulty = Enum.RelativeContentDifficulty.Difficult }) }, { 1 })
	TR.config.quests.difficulty = true
	TR:Refresh()
	tab(TR).args.title.set(nil, 0.4, 0.4, 0.4)
	eq(RW.color(RW.quest(TR, 1).title), RW.rgb(GetDifficultyColor(Enum.RelativeContentDifficulty.Difficult)), 'the difficulty color')
	TR.config.quests.difficulty = false
	TR:UpdateConfig()
	eq(RW.color(RW.quest(TR, 1).title), '0.40 0.40 0.40', 'difficulty off: the picked color')
end)

RW.both('a timer line under a minute stays Failed, above it the Objectives part', function(st, TR)
	eq(select(2, TR.TimerLine(30)), 'failed', 'under a minute: failed')
	eq(select(2, TR.TimerLine(300)), 'normal', 'the model says normal, painted as an objective')
end)
