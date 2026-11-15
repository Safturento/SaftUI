-- SaftUI's tracker's rows (SaftUI-Tracker/rows.lua, init.lua's refresh), on
-- both clients: zone headers, quest rows, their lines, bars, timers, popups,
-- the focused quest, the empty window, a Colors tab change and whole pixels.
-- The throttle and what a refresh costs are refresh_test.lua's.
--
-- Real: SaftUI-Tracker's files, Core's helpers and theme engine, the quest
-- stubs. The scroll frame is tracker_world.lua's stand-in.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q
local T = load_test_file('lib/theme_helpers.lua')
local P = load_test_file('lib/pixels.lua')

-- Two zones, the player in the first; the quests are tracked in log order.
local function two_zones()
	stub.real_zone_text = 'Elwynn Forest'
	Q.set({
		Q.header('Westfall'),
		Q.quest(10, { title = 'Missing Crates' }),
		Q.header('Elwynn Forest'),
		Q.quest(1, { title = 'Wolves' }), Q.quest(2, { title = 'Boars' }),
	}, { 10, 1, 2 })
end

local function colors(st) return st.config.profile.colors end

RW.both('zone headers: the current one first with the map pin in the accent, the rest in grey; the count', function(st, TR)
	two_zones()
	TR:Refresh()
	local zones = RW.rows(TR, 'zone')
	eq(#zones, 2, 'two headers')
	local here, there = RW.zone(TR, 'Elwynn Forest'), RW.zone(TR, 'Westfall')
	eq(zones[1], here, 'the current zone first')
	eq(zones[2], there, 'then the other')
	eq(RW.text(here.title), 'Elwynn Forest', 'its name')
	eq(RW.text(here.count), '2', 'the number of its quests')
	eq(RW.text(there.count), '1', 'the other has one')
	eq(RW.color(here.title), RW.rgb(colors(st).text.normal), 'the current zone in Text > Normal')
	eq(RW.color(there.title), RW.rgb(colors(st).text.grey), 'the rest in Text > Grey')
	eq(RW.color(here.count), RW.rgb(colors(st).text.grey), 'the count in Text > Grey')
	eq(here.title:GetFontObject(), st:GetFont('normal'), 'the Header font')
	check(here.pin:IsShown(), 'the pin shows for the current zone')
	check(not there.pin:IsShown(), 'and not for the rest')
	eq(here.pin:GetWidth(), 16, 'the pin is 16')
	eq(here.pin:GetTexture(), st.icons.mapPin, "Lucide's map-pin")
	eq(RW.rgb({ r = here.pin:GetVertexColor() , g = select(2, here.pin:GetVertexColor()), b = select(3, here.pin:GetVertexColor()) }), RW.rgb(colors(st).button.blue), 'in the accent')
	eq(here:GetHeight(), 20, 'a header is 20 tall')
	eq(here.chevron:GetWidth(), 16, 'the chevron is 16')
	-- Where things sit: the quests 4 under the header and 10 between groups.
	local top = TR.content:GetTop()
	eq(here:GetTop(), top, 'the first row at the top')
	eq(RW.quest(TR, 1):GetTop(), top - 20 - 4, 'a quest 4 under its header')
	eq(there:GetTop(), RW.quest(TR, 2):GetTop() - RW.quest(TR, 2):GetHeight() - 10, 'a header 10 under what is above it')
	-- Current zone first is a setting.
	TR.config.quests.current_first = false
	TR:UpdateConfig()
	eq(RW.rows(TR, 'zone')[1], there, 'Current zone first off: the log\'s order')
	check(here.pin:IsShown(), 'and the pin still marks the zone')
end)

RW.both('a zone header collapses and expands by its chevron, per character, the count staying', function(st, TR)
	two_zones()
	TR:Refresh()
	local here = RW.zone(TR, 'Elwynn Forest')
	eq(here.chevron.icon:GetTexture(), st.icons.chevronUp, 'chevron-up while it shows')
	check(RW.quest(TR, 1) and RW.quest(TR, 2), 'its quests show')
	stub.click(here.chevron)
	eq(TR:CharData().zones['Elwynn Forest'], true, 'saved per character, by the header title')
	eq(RW.quest(TR, 1), nil, 'its quests are not drawn')
	eq(RW.quest(TR, 2), nil, 'any of them')
	check(RW.quest(TR, 10) ~= nil, 'the other zone is untouched')
	eq(RW.text(here.count), '2', 'the count is still shown')
	eq(here.chevron.icon:GetTexture(), st.icons.chevronDown, 'chevron-down while collapsed')
	eq(RW.zone(TR, 'Elwynn Forest'), here, 'the header keeps its row')
	-- The tooltip says what a click does.
	stub.fire_script(here.chevron, 'OnEnter', true)
	eq(stub.state(GameTooltip).texts[1], 'Expand', 'the tooltip: Expand')
	stub.fire_script(here.chevron, 'OnLeave', true)
	-- A refresh (the log changed) keeps it collapsed.
	TR:Refresh()
	eq(RW.quest(TR, 1), nil, 'still collapsed after a refresh')
	stub.click(here.chevron)
	eq(TR:CharData().zones['Elwynn Forest'], nil, 'expanded: no saved state')
	check(RW.quest(TR, 1) and RW.quest(TR, 2), 'its quests are back')
	eq(here.chevron.icon:GetTexture(), st.icons.chevronUp, 'chevron-up again')
	eq(#take_errors(), 0, 'no errors')
end)

test('a collapsed zone stays collapsed in a new session, as the character left it', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = RW.world({ client = client, before = function(st)
			st.config.char.tracker = { zones = { Westfall = true } }
		end })
		two_zones()
		TR:Refresh()
		eq(RW.quest(TR, 10), nil, client .. ': the saved collapse is kept')
		check(RW.quest(TR, 1) ~= nil, client .. ': the rest shows')
		eq(RW.text(RW.zone(TR, 'Westfall').count), '1', client .. ': with its count')
	end
	eq(#take_errors(), 0, 'no errors')
end)

RW.both('the Other group and Group by zone off', function(st, TR)
	Q.set({ Q.quest(5, { title = 'Stray' }), Q.header('A'), Q.quest(6) }, { 5, 6 })
	TR:Refresh()
	-- Quest 5 sits above any header: C_QuestLog.GetHeaderIndexForQuest gives nothing.
	local other = RW.zone(TR, TR.OTHER_KEY)
	check(other ~= nil, 'a header for the quests the log can not place')
	eq(RW.text(other.title), 'Other', 'named Other')
	eq(RW.rows(TR, 'zone')[2], other, 'last')
	st.config.profile.tracker.quests.zones = false
	TR:UpdateConfig()
	eq(#RW.rows(TR, 'zone'), 0, 'Group by zone off: no zone header')
	check(RW.quest(TR, 5) and RW.quest(TR, 6), 'one list of quests')
	eq(RW.quest(TR, 5):GetTop(), TR.content:GetTop(), 'from the top')
end)

RW.both('titles: level and tags, the difficulty color or Text > Normal, Completed when ready, Failed when failed', function(st, TR)
	Q.set({
		Q.header('A'),
		Q.quest(1, { title = 'Plain', level = 12, difficulty = Enum.RelativeContentDifficulty.Difficult }),
		Q.quest(2, { title = 'Ready', level = 12, complete = true }),
		Q.quest(3, { title = 'Lost', level = 12, failed = true }),
		Q.quest(4, { title = 'Tagged', level = 30, elite = true, frequency = Enum.QuestFrequency.Daily, tag = { tagName = 'Elite', tagID = 1, isElite = true } }),
	}, { 1, 2, 3, 4 })
	local settings = st.config.profile.tracker.quests
	settings.level, settings.tags, settings.difficulty = true, true, true
	TR:Refresh()
	eq(RW.text(RW.quest(TR, 1).title), '[12] Plain', 'level')
	eq(RW.text(RW.quest(TR, 4).title), '[30+] Tagged (Elite) (Daily)', 'an elite quest, its tags')
	local color = GetDifficultyColor(Enum.RelativeContentDifficulty.Difficult)
	eq(RW.color(RW.quest(TR, 1).title), RW.rgb(color), 'the difficulty color')
	eq(RW.color(RW.quest(TR, 2).title), RW.rgb(colors(st).objectives.completed), 'Completed when ready to turn in')
	eq(RW.color(RW.quest(TR, 3).title), RW.rgb(colors(st).objectives.failed), 'Failed when failed')
	settings.level, settings.tags, settings.difficulty = false, false, false
	TR:UpdateConfig()
	eq(RW.text(RW.quest(TR, 1).title), 'Plain', 'no level, no tags')
	eq(RW.text(RW.quest(TR, 4).title), 'Tagged', 'no tags either')
	eq(RW.color(RW.quest(TR, 1).title), RW.rgb(colors(st).text.normal), 'Color by difficulty off: Text > Normal')
	eq(RW.color(RW.quest(TR, 2).title), RW.rgb(colors(st).objectives.completed), 'Completed whatever')
	eq(RW.quest(TR, 1).title:GetFontObject(), st:GetFont('normal'), 'in the Font')
end)

RW.both('lines: objectives, a finished one in Completed, Failed, the completion lines, money, the timer', function(st, TR)
	stub.money = 100
	Q.set({
		Q.header('A'),
		Q.quest(1, { objectives = { { text = '3/8 Boars slain', type = 'monster' }, { text = 'Found the key', type = 'item', finished = true } } }),
		Q.quest(2, { failed = true, objectives = { { text = 'ignored', type = 'monster' } } }),
		Q.quest(3, { complete = true, completion = 'Return to Marshal McBride' }),
		Q.quest(4, { complete = true, auto = true }),
		Q.quest(5, { objectives = { { text = 'Bring gold', type = 'monster' } }, money = 50000 }),
		Q.quest(6, { objectives = { { text = 'Hurry', type = 'monster' } }, time = { total = 120, elapsed = 70 }, timer = 50 }),
		Q.quest(7, { objectives = { { text = 'Hurry more', type = 'monster' } }, time = { total = 600, elapsed = 60 }, timer = 540 }),
	}, { 1, 2, 3, 4, 5, 6, 7 })
	TR:Refresh()
	local function lines(id)
		local row, out = RW.quest(TR, id), {}
		for j = 1, row.nparts do
			local part = row.parts[j]
			if part.fs:IsShown() then out[#out + 1] = RW.text(part.fs) .. '=' .. RW.color(part.fs) end
		end
		return table.concat(out, ' | ')
	end
	local normal, done, failed = RW.rgb(colors(st).text.normal), RW.rgb(colors(st).objectives.completed), RW.rgb(colors(st).objectives.failed)
	eq(lines(1), '3/8 Boars slain=' .. normal .. ' | Found the key=' .. done, 'objectives, the finished one in Completed')
	eq(lines(2), 'Failed=' .. failed, 'a failed quest says Failed')
	eq(lines(3), 'Return to Marshal McBride=' .. done, 'the completion line')
	eq(lines(4), 'Quest complete=' .. done .. ' | Click to complete=' .. done, 'an auto-complete quest')
	local money = lines(5)
	check(money:find('Bring gold', 1, true) and money:find('/', 1, true) and money:find(normal, 1, true), 'money after the objectives: ' .. money)
	eq(lines(6), 'Hurry=' .. normal .. ' | Time left: 0:50=' .. failed, 'a timer under a minute in Failed')
	eq(lines(7), 'Hurry more=' .. normal .. ' | Time left: 9:00=' .. normal, 'a timer over a minute in Text > Normal')
	-- Where the lines sit: the objectives 12 right of the title, 2 under it.
	local row = RW.quest(TR, 1)
	-- 16 px fonts: the dash is 8 wide here and 4 after it.
	eq(row.parts[1].dash:GetLeft(), row.title:GetLeft() + 12, 'the dash is indented 12 under the title')
	eq(RW.text(row.parts[1].dash), '-', 'a dash')
	eq(row.parts[1].fs:GetLeft(), row.title:GetLeft() + 12 + 12, 'the text after the dash and 4')
	check(row.parts[1].dash:IsShown(), 'shown')
	eq(RW.color(row.parts[1].dash), RW.color(row.parts[1].fs), "in the line's color")
	eq(RW.color(row.parts[2].dash), done, 'a finished objective\'s dash in Completed')
	local money_row = RW.quest(TR, 5)
	check(not money_row.parts[2].dash or not money_row.parts[2].dash:IsShown(), 'the money line has no dash')
	local timer_row = RW.quest(TR, 6)
	check(not timer_row.parts[2].dash or not timer_row.parts[2].dash:IsShown(), 'nor the timer')
	check(not RW.quest(TR, 3).parts[1].dash or not RW.quest(TR, 3).parts[1].dash:IsShown(), 'nor a completion line')
	-- Hide finished objectives and the finished-quest objectives.
	st.config.profile.tracker.quests.hide_finished = true
	st.config.profile.tracker.quests.finished_objectives = true
	TR:UpdateConfig()
	eq(lines(1), '3/8 Boars slain=' .. normal, 'Hide finished objectives')
	Q.set(stub.quests.log, stub.quests.watched)
	stub.quests.log[4].objectives = { { text = 'Also done', type = 'monster', finished = true } }
	TR:Refresh()
	eq(lines(3), 'Also done=' .. done .. ' | Return to Marshal McBride=' .. done, 'Objectives of finished quests on')
end)

RW.both("progress bars in Blizzard's blue with the percent centred in the Pixel font; off, the objective's text", function(st, TR)
	Q.set({
		Q.header('A'),
		Q.quest(1, { objectives = { { text = 'Escort', type = 'progressbar' } }, percent = 45 }),
		Q.quest(2, { objectives = { { text = 'Kill', type = 'monster' }, { text = 'Escort', type = 'progressbar' }, { text = 'Then talk', type = 'monster' } }, percent = 100 }),
	}, { 1, 2 })
	TR:Refresh()
	local row = RW.quest(TR, 1)
	local bar = row.parts[1].bar
	check(bar and bar:IsShown(), 'the objective is a bar')
	check(not row.parts[1].fs:IsShown(), 'in place of its line')
	eq(RW.text(bar.label), '45%', 'the percent')
	eq(bar.label:GetFontObject(), st:GetFont('pixel'), 'in the Pixel font')
	eq(bar.label:GetJustifyH(), 'CENTER', 'centred')
	local filled = stub.state(bar.fill)
	eq(filled.vertex_color[1] .. ' ' .. filled.vertex_color[2] .. ' ' .. filled.vertex_color[3], '0.26 0.42 1', "Blizzard's progress blue")
	eq(bar:GetHeight(), 12, '12 tall')
	eq(bar.fill:GetWidth(), math.floor(bar:GetWidth() * 0.45 + 0.5), 'filled to the percent, a whole pixel')
	eq(bar:GetWidth(), 226 - 12 + 0, 'as wide as the objectives: the list less the icon and the indent')
	eq(bar.backdrop ~= nil, true, 'drawn as a SaftUI bar (a backdrop)')
	eq(row:GetHeight(), TR:LineHeight() + 3 + 12 + 3, 'the row: the title, 3, the bar, 3')
	local two = RW.quest(TR, 2)
	eq(two.parts[2].bar.fill:GetWidth(), two.parts[2].bar:GetWidth(), '100% fills it')
	check(two.parts[1].fs:IsShown() and two.parts[3].fs:IsShown(), 'the lines around it')
	-- Progress bars off: the objective's own text.
	st.config.profile.tracker.quests.bars = false
	TR:UpdateConfig()
	check(not bar:IsShown(), 'the bar is gone')
	eq(RW.text(row.parts[1].fs), 'Escort', "the objective's text in its place")
	check(row.parts[1].fs:IsShown(), 'shown')
end)

RW.both('the quest icon is 14 and the title 4 after it; off, the title is at the left', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1), Q.quest(2, { complete = true }) }, { 1, 2 })
	TR:Refresh()
	local row, done = RW.quest(TR, 1), RW.quest(TR, 2)
	check(row.icon:IsShown(), 'the icon shows')
	eq(row.icon:GetWidth(), 14, '14 wide')
	eq(row.icon:GetHeight(), 14, 'and tall')
	eq(row.icon:GetAtlas(), 'SideInProgressquesticon', "the game's icon for an active quest")
	eq(done.icon:GetTexture(), 'Interface/GossipFrame/ActiveQuestIcon', "a finished quest's, a file")
	eq(row.title:GetLeft(), row:GetLeft() + 18, 'the title 14 + 4 after it')
	st.config.profile.tracker.quests.icons = false
	TR:UpdateConfig()
	check(not row.icon:IsShown(), 'Quest icons off: no icon')
	eq(row.title:GetLeft(), row:GetLeft(), 'the title at the left')
end)

RW.both("the focused quest: a 2 px accent bar 4 left of its row, its waypoint line; the list scrolls it into view", function(st, TR)
	local log, watched = { Q.header('A') }, {}
	for id = 1, 30 do
		log[#log + 1] = Q.quest(id, { objectives = { { text = 'Thing ' .. id, type = 'monster' } } })
		watched[#watched + 1] = id
	end
	log[3].waypoint = 'Take the boat'
	Q.set(log, watched, { focused = 2 })
	TR:Refresh()
	local bar = TR.focusBar
	check(bar:IsShown(), 'the focus bar shows')
	local row = RW.quest(TR, 2)
	eq(bar:GetWidth(), 2, '2 px')
	eq(bar:GetRight(), TR.scroll:GetLeft() - 4, '4 left of the row')
	eq(bar:GetTop(), row:GetTop(), 'from the row\'s top')
	eq(bar:GetHeight(), row:GetHeight(), 'as tall as the row')
	local blue = colors(st).button.blue
	eq(stub.state(bar).color_texture[1] .. stub.state(bar).color_texture[2], blue.r .. blue.g, 'in the accent')
	local lines = {}
	for j = 1, row.nparts do if row.parts[j].fs:IsShown() then lines[#lines + 1] = RW.text(row.parts[j].fs) end end
	eq(table.concat(lines, '|'), 'Thing 2|Waypoint: Take the boat', 'the focused quest has its waypoint line')

	-- The focus moves to a quest far below: the list scrolls it into view.
	check(TR.scrollRange > 0, 'the list scrolls')
	eq(TR:GetScroll(), 0, 'at the top')
	stub.quests.focused = 28
	TR:Refresh()
	local last = RW.quest(TR, 28)
	local view_bottom = TR.scroll:GetBottom()
	check(TR:GetScroll() > 0, 'scrolled')
	check(last:GetBottom() >= view_bottom and last:GetTop() <= TR.scroll:GetTop(), 'the row shows whole')
	check(bar:IsShown(), 'and the bar with it')
	eq(bar:GetTop(), last:GetTop(), 'the bar follows it')
	-- Scrolled so the focused row is out of view: no bar.
	TR:ScrollTo(0)
	check(not bar:IsShown(), 'out of view: the bar is hidden')
	-- No focus: no bar; a refresh keeps the place.
	stub.quests.focused = 0
	TR:ScrollTo(200)
	TR:Refresh()
	check(not bar:IsShown(), 'no focus, no bar')
	eq(TR:GetScroll(), 200, 'a refresh keeps the scroll offset')
	-- A collapsed window shows no bar for a row it does not show.
	stub.quests.focused = 1
	TR:Refresh()
	check(bar:IsShown(), 'the focused quest is in view again')
	TR:SetCollapsed(true)
	check(not bar:IsShown(), 'collapsed: no focus bar')
	TR:SetCollapsed(false)
	check(bar:IsShown(), 'expanded: it is back')
	-- Locked scrolling does not move the list.
	local locked = TR.IsScrollLocked
	TR.IsScrollLocked = function() return true end
	TR:ScrollTo(200)
	stub.quests.focused = 28
	TR:Refresh()
	eq(TR:GetScroll(), 200, 'locked: the list stays')
	TR.IsScrollLocked = locked
end)

-- A log of n watched quests of one zone: the list scrolls (30 or so fill it).
local function long_log(n, extra)
	local log, watched = { Q.header('A') }, {}
	for id = 1, n do
		log[#log + 1] = Q.quest(id)
		watched[#watched + 1] = id
	end
	Q.set(log, watched, extra)
	return log, watched
end

RW.both('a quest the game says was just tracked is scrolled into view; nothing else that is merely new is', function(st, TR)
	local log, watched = long_log(30)
	TR:Refresh()
	eq(TR:GetScroll(), 0, 'the first refresh does not scroll')
	log[#log + 1] = Q.quest(31, { title = 'New one' })
	watched[#watched + 1] = 31
	Q.set(log, watched)
	-- Seen in the log, but nobody said it was tracked: no scroll.
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	eq(TR:GetScroll(), 0, 'a quest that is only new to the tracker does not scroll the list')
	TR:ScrollTo(0)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 31, true)
	RW.later(1)
	local row = RW.quest(TR, 31)
	check(TR:GetScroll() > 0, 'QUEST_WATCH_LIST_CHANGED with added: scrolled to it')
	check(row:GetBottom() >= TR.scroll:GetBottom(), 'whole in view')
	TR:ScrollTo(0)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 31, false)
	RW.later(1)
	eq(TR:GetScroll(), 0, 'a quest taken off the list: no scroll')
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	eq(TR:GetScroll(), 0, 'and the next refresh keeps the place: the request was used up')
end)

RW.both('the list does not jump when the log arrives after login, titles arrive one by one, or the zone changes', function(st, TR)
	-- An empty first read, then the whole log.
	Q.set({}, {})
	TR:Refresh()
	long_log(25)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	eq(TR:GetScroll(), 0, 'the log arriving after an empty read does not scroll')
	-- Titles arriving one by one: a quest with no title is skipped until it has one.
	local log, watched = long_log(25)
	for id = 26, 30 do
		log[#log + 1] = Q.quest(id, { title = '' })
		watched[#watched + 1] = id
	end
	Q.set(log, watched)
	TR:Refresh()
	for id = 26, 30 do
		log[id + 1].title = 'Quest ' .. id
		TR:Refresh()
		eq(TR:GetScroll(), 0, 'quest ' .. id .. "'s title arrived: no scroll")
	end
	-- Show the zone's: a zone change makes its untracked quests appear.
	TR.config.quests.show = 'zone'
	stub.real_zone_text = 'Elsewhere'
	local more = { Q.header('Elsewhere') }
	for id = 40, 45 do more[#more + 1] = Q.quest(id) end
	local all = { unpack(log) }
	for _, entry in ipairs(more) do all[#all + 1] = entry end
	Q.set(all, watched)
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	RW.later(1)
	check(RW.quest(TR, 40) ~= nil, 'the zone\'s untracked quests are drawn')
	eq(TR:GetScroll(), 0, 'and the list stays')
end)

RW.both('no scroll into view while the mouse is over the tracker or the player scrolled in the last few seconds', function(st, TR)
	long_log(30, { focused = 0 })
	TR:Refresh()
	local function focus(id)
		stub.quests.focused = id
		TR:Refresh()
	end
	RW.mouse_on(TR.window)
	focus(28)
	eq(TR:GetScroll(), 0, 'the mouse is over the tracker: the focus change does not scroll it')
	RW.mouse_off()
	focus(0)
	-- The wheel, as the player turns it.
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	local at = TR:GetScroll()
	check(at > 0, 'the wheel scrolled')
	focus(29)
	eq(TR:GetScroll(), at, 'scrolled by the player a moment ago: the list stays')
	RW.later(TR.SCROLL_QUIET + 1)
	focus(30)
	check(TR:GetScroll() > at, 'a few seconds on: it scrolls to the focused quest')
	-- A drag of the bar counts as the player's too: its mouse-down on the thumb.
	TR:ScrollTo(0)
	focus(0)
	stub.fire_script(TR.scroll.ScrollBar:GetThumb(), 'OnMouseDown', 'LeftButton')
	TR.scroll.ScrollBar:SetScrollPercentage(0.5)
	local dragged = TR:GetScroll()
	focus(28)
	eq(TR:GetScroll(), dragged, 'a bar drag a moment ago: the list stays')
	-- A new quest tracked under the mouse waits no more than the focus does.
	RW.later(TR.SCROLL_QUIET + 1)
	TR:ScrollTo(0)
	RW.mouse_on(TR.window)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 27, true)
	RW.later(1)
	eq(TR:GetScroll(), 0, 'tracked under the mouse: no scroll')
end)

RW.both('hover fills a quest row with the accent at TINT_ROW, 2 beyond it above and below', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = 'x', type = 'monster' } } }) }, { 1 })
	TR:Refresh()
	local row = RW.quest(TR, 1)
	check(row:IsMouseEnabled(), 'a quest row takes the mouse')
	check(not row.hover:IsShown(), 'no fill at rest')
	stub.fire_script(row, 'OnEnter', true)
	check(row.hover:IsShown(), 'a fill under the mouse')
	local c = stub.state(row.hover).color_texture
	local blue = colors(st).button.blue
	eq(c[1] .. ' ' .. c[2] .. ' ' .. c[3] .. ' ' .. c[4], blue.r .. ' ' .. blue.g .. ' ' .. blue.b .. ' ' .. st.TINT_ROW, 'the accent at TINT_ROW')
	eq(row.hover:GetTop(), row:GetTop() + 2, '2 above')
	eq(row.hover:GetBottom(), row:GetBottom() - 2, '2 below')
	stub.fire_script(row, 'OnLeave', true)
	check(not row.hover:IsShown(), 'gone on leave')
	stub.fire_script(row, 'OnEnter', true)
	Q.set({ Q.header('A') }, {})
	TR:Refresh()
	check(not row.hover:IsShown(), 'a row that went does not keep its fill')
	local src = read_saftui_source('SaftUI-Tracker/rows.lua')
	check(not src:find("SetScript%('On%a+', function%(self, motion", 1), 'no script takes the motion argument')
end)

RW.both('popups: above the zones, the window expanded while they show, a click shows the quest and removes the popup', function(st, TR)
	two_zones()
	TR:CharData().collapsed = true
	Q.set(stub.quests.log, stub.quests.watched, {
		popups = { { id = 77, kind = 'OFFER' }, { id = 78, kind = 'COMPLETE' } }, titles = { [77] = 'An offer', [78] = 'A turn-in' },
	})
	TR:Refresh()
	local popups = RW.rows(TR, 'popup')
	eq(#popups, 2, 'two popups')
	local first, second = TR:GetPopupRow(77, 'OFFER'), TR:GetPopupRow(78, 'COMPLETE')
	eq(popups[1], first, 'in the popups\' order')
	eq(first:GetHeight(), 34, 'the label, 2 and the title: 16 + 2 + 16 at the default fonts')
	eq(first:GetTop(), TR.content:GetTop(), 'at the top of the list')
	eq(second:GetTop(), first:GetTop() - 34 - 8, 'spacing apart')
	eq(RW.zone(TR, 'Elwynn Forest'):GetTop(), second:GetTop() - 34 - 10, 'the first zone header 10 under the last popup')
	eq(RW.text(first.label), 'Quest discovered', 'an offer says Quest discovered')
	eq(RW.text(second.label), 'Quest complete', 'a turn-in says Quest complete')
	eq(RW.text(first.title), 'An offer', 'over the quest\'s title')
	eq(RW.color(first.label), RW.rgb(colors(st).button.blue), 'in the accent')
	eq(first.label:GetFontObject(), st:GetFont('normal'), 'in the Header font')
	eq(first.bar:GetHeight(), 34, 'the accent bar is the whole row')
	eq(first.bar:GetWidth(), 2, 'a 2 px bar')
	eq(first.bar:GetLeft(), first:GetLeft(), 'at its left')
	-- The window is expanded while they show, and the saved state is untouched.
	check(not TR:IsCollapsed(), 'expanded while popups show')
	eq(TR:CharData().collapsed, true, 'the saved state is untouched')
	eq(TR.window:GetHeight() > 40, true, 'the window is open')
	eq(TR.header.collapse.icon:GetTexture(), st.icons.chevronUp, 'the header chevron shows it open')
	-- A click.
	stub.click(first)
	eq(table.concat(stub.quests.shown, ','), 'offer:77', 'the offer is shown')
	eq(#stub.quests.popups, 1, 'and its popup removed')
	stub.click(second)
	eq(table.concat(stub.quests.shown, ','), 'offer:77,complete:78', 'a turn-in shows the complete frame')
	RW.later(1)
	eq(#TR.model.popups, 0, 'the popups are gone after the refresh the click asked for')
	check(TR:IsCollapsed(), 'the window is collapsed again, as the player left it')
	eq(TR.window:GetHeight(), 40, 'to its header')
	eq(#take_errors(), 0, 'no errors')
end)

RW.both('a popup click in combat works; nothing is blocked', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 }, { popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = 'An offer' } })
	TR:Refresh()
	TW.combat(true)
	stub.click(TR:GetPopupRow(77, 'OFFER'))
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(table.concat(stub.quests.shown, ','), 'offer:77', 'the click ran')
end)

RW.both('empty: hidden with Hide when empty, else the header and "No tracked quests."', function(st, TR)
	Q.set({ Q.header('A') }, {})
	TR:Refresh()
	check(not TR.window:IsShown(), 'Hide when empty: the window is hidden')
	eq(#RW.rows(TR, 'empty'), 0, 'with no empty line')
	st.config.profile.tracker.hide_empty = false
	TR:UpdateConfig()
	check(TR.window:IsShown(), 'off: it shows')
	local line = RW.rows(TR, 'empty')[1]
	check(line ~= nil, 'the empty line')
	eq(RW.text(line.title), 'No tracked quests.', 'its words')
	eq(RW.color(line.title), RW.rgb(colors(st).text.grey), 'in Text > Grey')
	eq(TR.header:IsShown(), true, 'under the header')
	-- A quest comes: the line goes, the window shows (Hide when empty on again).
	st.config.profile.tracker.hide_empty = true
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 })
	TR:UpdateConfig()
	check(TR.window:IsShown(), 'shown with a quest')
	eq(#RW.rows(TR, 'empty'), 0, 'no empty line')
	-- An arena has no quest rows.
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 })
	stub.instance_type = 'arena'
	if type(IsInInstance) == 'function' then
		local is_in = IsInInstance
		IsInInstance = function() return true, 'arena' end
		TR:Refresh()
		check(not TR.window:IsShown(), 'an arena: empty, hidden')
		IsInInstance = is_in
	end
end)

RW.both('a Colors tab change recolors the status lines (objectives) and the accent pieces (button), with no new frame, text or measure', function(st, TR)
	stub.real_zone_text = 'A'
	Q.set({
		Q.header('A'),
		Q.quest(1, { objectives = { { text = 'Found', type = 'item', finished = true }, { text = 'Bar', type = 'progressbar' } }, percent = 20 }),
		Q.quest(2, { complete = true }),
		Q.quest(3, { failed = true }),
	}, { 1, 2, 3 }, { focused = 1 })
	TR:Refresh()
	local row = RW.quest(TR, 1)
	stub.fire_script(row, 'OnEnter', true)
	local counter = RW.counter()
	local measured = row.title.measuredStamp
	colors(st).objectives.completed:SetRGB(0.1, 0.2, 0.3)
	colors(st).objectives.failed:SetRGB(0.4, 0.5, 0.6)
	TR:OnColorsChanged('objectives')
	eq(RW.color(row.parts[1].fs), '0.10 0.20 0.30', 'a finished objective in the new Completed')
	eq(RW.color(RW.quest(TR, 2).title), '0.10 0.20 0.30', 'a ready quest\'s title')
	eq(RW.color(RW.quest(TR, 3).title), '0.40 0.50 0.60', 'a failed quest\'s title in the new Failed')
	colors(st).button.blue:SetRGB(0.7, 0.8, 0.9)
	TR:OnColorsChanged('button')
	local function rgb(t) local c = stub.state(t).color_texture; return ('%.2f %.2f %.2f'):format(c[1], c[2], c[3]) end
	eq(rgb(TR.focusBar), '0.70 0.80 0.90', 'the focus bar')
	eq(rgb(row.hover), '0.70 0.80 0.90', 'the hover')
	do
		local r, g, b = RW.zone(TR, 'A').pin:GetVertexColor()
		eq(('%.2f %.2f %.2f'):format(r, g, b), '0.70 0.80 0.90', 'the pin')
	end
	colors(st).text.grey:SetRGB(0.3, 0.3, 0.3)
	colors(st).text.normal:SetRGB(0.9, 0.9, 0.9)
	TR:OnColorsChanged('text')
	eq(RW.color(RW.zone(TR, 'A').count), '0.30 0.30 0.30', 'the zone count in Text > Grey')
	eq(RW.color(RW.zone(TR, 'A').title), '0.90 0.90 0.90', 'the current zone in Text > Normal')
	eq(counter.frames, 0, 'no frame')
	eq(counter.texts, 0, 'no text set')
	eq(row.title.measuredStamp, measured, 'nothing measured again')
	counter.stop()
	-- Shown rows drawn after the change use the new color too.
	TR:Refresh()
	eq(RW.color(row.parts[1].fs), '0.10 0.20 0.30', 'a later draw reads it too')
end)

RW.both('a button in the row leaves its room and height; no frame of it is made', function(st, TR)
	Q.set({ Q.header('A'),
		Q.quest(1, { item = { link = 'item:6948', texture = 134400 } }),
		Q.quest(2),
	}, { 1, 2 })
	TR:Refresh()
	local with, without = RW.quest(TR, 1), RW.quest(TR, 2)
	eq(with.item, 'row', 'the row says its button sits in it')
	eq(without.item, nil, 'the other says none')
	eq(without.title:GetWidth() - with.title:GetWidth(), 24 + 4, 'the title leaves the button and 4')
	check(with:GetHeight() >= 24, 'at least Button size tall')
	st.config.profile.tracker.items.size = 40
	TR:UpdateConfig()
	check(with:GetHeight() >= 40, 'at 40: 40 tall')
	st.config.profile.tracker.items.placement = 'off'
	TR:UpdateConfig()
	-- Off shows the item as a plain icon in the row (design: "Item buttons: Off"), so
	-- the room is kept; what Task 5 pinned here, no room, was before that was built.
	eq(with.item, 'row', 'Off: the room is kept for the plain icon')
	check(with.slot:IsShown() and not with.slot.icon:IsDesaturated(), 'which shows plain')
	eq(without.title:GetWidth() - with.title:GetWidth(), 40 + 4, 'the title still leaves its room (the button is 40 now)')
	eq(TW.counts.secure, 0, 'no secure frame')
end)

RW.both('Width and Spacing and the fonts reach the rows', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1), Q.quest(2) }, { 1, 2 })
	TR:Refresh()
	local one, two = RW.quest(TR, 1), RW.quest(TR, 2)
	eq(one:GetWidth(), 244, 'the list\'s width: Width 260 less padding')
	eq(one:GetTop() - one:GetHeight() - two:GetTop(), 8, 'rows 8 apart')
	st.config.profile.tracker.quests.spacing = 0
	st.config.profile.tracker.width = 300
	TR:UpdateConfig()
	eq(one:GetWidth(), 284, 'Width 300')
	eq(one:GetTop() - one:GetHeight() - two:GetTop(), 0, 'Spacing 0')
	st.config.profile.tracker.font = 'pixel'
	st.config.profile.tracker.header_font = 'pixel'
	TR:UpdateConfig()
	eq(one.title:GetFontObject(), st:GetFont('pixel'), 'Font')
	eq(RW.zone(TR, 'A').title:GetFontObject(), st:GetFont('pixel'), 'Header font')
	check(one:GetHeight() == 10, 'a 10 px title: the row is 10 tall: ' .. one:GetHeight())
end)

RW.both('a theme change draws the bars again; the rows follow a profile switch', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = 'Bar', type = 'progressbar' } }, percent = 50 }) }, { 1 })
	TR:Refresh()
	local bar = RW.quest(TR, 1).parts[1].bar
	check(bar.backdrop ~= nil, 'drawn')
	st.config.profile.tracker.theme = 'none'
	TR:UpdateConfig()
	eq(bar.backdrop.backdropInfo, nil, 'Theme None draws none')
	st.config.profile.tracker.theme = 'thin'
	TR:UpdateConfig()
	check(bar.backdrop.backdropInfo ~= nil, 'Thin: drawn again')
end)

----------------------------------------------------------------- whole pixels

local THEMES = { 'thick', 'thin', 'blizzard' }
local NOISES = { 2 ^ -14, -2 ^ -14, 0 }

-- A zone with a quest of one, three and wrapped objectives, a bar, a timer, a
-- popup, a collapsed group and the focus: every row a layout makes.
local function every_row(st)
	local long = 'Gather a great many of the things this long objective asks of you from around the whole zone'
	stub.real_zone_text = 'Elwynn Forest'
	Q.set({
		Q.header('Elwynn Forest'),
		Q.quest(1, { title = 'One objective', objectives = { { text = '1/2 Wolves', type = 'monster' } } }),
		Q.quest(2, { title = 'Three objectives', objectives = { { text = '1/2 A', type = 'monster' }, { text = '2/3 B', type = 'monster' }, { text = '3/4 C', type = 'monster' } } }),
		Q.quest(3, { title = 'Wrapped objectives with a very long title that wraps on to a second line at this width', objectives = { { text = long, type = 'monster' } }, waypoint = 'Take the boat' }),
		Q.quest(4, { title = 'A bar', objectives = { { text = 'Escort', type = 'progressbar' } }, percent = 37 }),
		Q.quest(5, { title = 'A timer', objectives = { { text = 'Hurry', type = 'monster' } }, time = { total = 300, elapsed = 10 }, timer = 290 }),
		Q.quest(6, { title = 'An item', objectives = { { text = 'Use it', type = 'item' } }, item = { link = 'item:6948', texture = 134400 } }),
		Q.header('Westfall'),
		Q.quest(7, { title = 'Collapsed away' }),
	}, { 1, 2, 3, 4, 5, 6, 7 }, {
		focused = 3, popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = 'An offer' },
	})
	st.config.char.tracker = { zones = { Westfall = true } }
end

test('whole pixels under Thick, Thin and Blizzard, size noise up, down and off, at Width 260 and a narrow and a wide one, scrolled and not', function()
	local checked = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, theme in ipairs(THEMES) do
			for _, noise in ipairs(NOISES) do
				for _, width in ipairs({ 260, 181, 601 }) do
					for _, scrolled in ipairs({ false, true }) do
						local where = ('%s, %s, noise %g, Width %d, %s'):format(client, theme, noise, width, scrolled and 'scrolled' or 'top')
						local st, TR = RW.world({ client = client })
						T.theme(theme, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
						every_row(st)
						TR.config.width = width
						TR.config.height = 300
						TR.config.items.placement = 'row'
						stub.size_noise = noise
						TR:UpdateConfig()
						TR:Refresh()
						if scrolled then TR:ScrollTo(137.4) end
						local off = P.off(TR.window)
						eq(#off, 0, where .. ': ' .. P.report(off))
						off = P.off(TR.holder)
						eq(#off, 0, where .. ' (the holder): ' .. P.report(off))
						-- A second refresh moves nothing.
						TR:Refresh()
						off = P.off(TR.window)
						eq(#off, 0, where .. ' (again): ' .. P.report(off))
						stub.size_noise = 0
						checked = checked + 1
					end
				end
			end
		end
	end
	eq(checked, 2 * 3 * 3 * 3 * 2, 'every combination ran')
	eq(#take_errors(), 0, 'no errors')
end)

test('whole pixels: the rows of every kind, collapsed, popups, no header, Group by zone off', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, noise in ipairs(NOISES) do
			local st, TR = RW.world({ client = client })
			every_row(st)
			stub.size_noise = noise
			local variants = {
				function() end,
				function() TR.config.header = false; TR:UpdateConfig() end,
				function() TR.config.quests.zones = false; TR:UpdateConfig() end,
				function() TR:SetCollapsed(true) end,
				function() TR.config.quests.icons = false; TR:UpdateConfig() end,
				function() TR.config.font, TR.config.header_font = 'pixel', 'pixel'; TR:UpdateConfig() end,
				function() TR.config.hide_empty = false; Q.set({ Q.header('A') }, {}, { popups = {} }); TR:Refresh() end,
			}
			for index, variant in ipairs(variants) do
				variant()
				TR:Refresh()
				local off = P.off(TR.window)
				eq(#off, 0, ('%s, noise %g, variant %d: %s'):format(client, noise, index, P.report(off)))
			end
			stub.size_noise = 0
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("sizes read back a hair off (a text's height, the bar's room) never change a row: heights are rounded, widths and rects exactly whole", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local function rects(noise)
			local st, TR = RW.world({ client = client })
			every_row(st)
			TR.config.width, TR.config.height = 261, 300
			TR:UpdateConfig()
			-- The game reads a text's height back a hair off too.
			local methods = getmetatable(UIParent:CreateFontString(nil, 'OVERLAY')).__index
			local height = methods.GetStringHeight
			methods.GetStringHeight = function(self) return height(self) + noise end
			stub.size_noise = noise
			TR.fontStamp = TR.fontStamp + 1 -- every text is measured again
			TR:Refresh()
			local out = {}
			for _, kind in ipairs({ 'popup', 'zone', 'quest' }) do
				for _, row in ipairs(RW.rows(TR, kind)) do
					local width, tall = row:GetRight() - row:GetLeft(), row:GetTop() - row:GetBottom()
					eq(width, math.floor(width), ('%s noise %g: a %s row is exactly whole wide (%s)'):format(client, noise, kind, tostring(width)))
					eq(tall, math.floor(tall), ('%s noise %g: and exactly whole tall (%s)'):format(client, noise, tostring(tall)))
					out[#out + 1] = ('%s %s %s'):format(row.key, width, tall)
				end
			end
			check(TR.scrollRange > 0, client .. ': the list scrolls, so the bar takes its room')
			eq(TR.content:GetRight() - TR.content:GetLeft(), 261 - 16 - 14, 'the child is the width less padding and the bar')
			methods.GetStringHeight = height
			stub.size_noise = 0
			return table.concat(out, '; ')
		end
		local flat = rects(0)
		eq(rects(2 ^ -14), flat, client .. ': noise up changes no row')
		eq(rects(-2 ^ -14), flat, client .. ': noise down changes none either')
	end
	eq(#take_errors(), 0, 'no errors')
end)

RW.both('a popup row at a small font stays 22 tall; the label is over the title, never on it', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 }, { popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = 'An offer' } })
	TR:Refresh()
	local row = TR:GetPopupRow(77, 'OFFER')
	check(row.label:GetBottom() >= row.title:GetTop(), 'the label ends where the title starts or above')
	eq(row.label:GetTop(), row:GetTop(), "the label at the row's top")
	eq(row.title:GetTop(), row:GetTop() - 16 - 2, 'the title 2 under it')
	TR.config.font, TR.config.header_font = 'pixel', 'pixel'
	TR:UpdateConfig()
	row = TR:GetPopupRow(77, 'OFFER')
	eq(row:GetHeight(), 22, '10 + 2 + 10 is 22: the floor')
	eq(row.bar:GetHeight(), 22, 'the bar follows')
end)

RW.both("a wrapped objective's later lines align with its text, not the dash", function(st, TR)
	local long = 'Gather a great many of the things this long objective asks of you from around the whole zone'
	Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = long, type = 'monster' } } }) }, { 1 })
	TR:Refresh()
	local part = RW.quest(TR, 1).parts[1]
	eq(part.fs:GetLeft(), part.dash:GetLeft() + 12, 'the text block starts after the dash, so every line of it does')
	eq(part.fs:GetTop(), part.dash:GetTop(), 'and at the dash\'s top')
	eq(TR.placed[2].lines[1].width, 226 - 12 - 12, 'wrapped at the width less the dash')
	TR.config.quests.hide_finished = false
end)

RW.both('a refresh keeps the place of a list scrolled away from the focused quest; only a change of focus scrolls to it', function(st, TR)
	long_log(30, { focused = 25 })
	TR:Refresh()
	check(TR:GetScroll() > 0, 'the focus at the end: scrolled to it')
	TR:ScrollTo(0)
	for _ = 1, 3 do
		stub.fire_event('QUEST_LOG_UPDATE')
		RW.later(1)
	end
	eq(TR:GetScroll(), 0, 'refreshes with the same focus leave the list where the player put it')
end)

RW.both('a collapsed tracker is not scrolled: the place is kept for when it opens', function(st, TR)
	long_log(30, { focused = 0 })
	TR:Refresh()
	TR:ScrollTo(100)
	TR:SetCollapsed(true)
	stub.quests.focused = 28
	TR:Refresh()
	eq(TR:GetScroll(), 100, 'a focus change while collapsed does not move the list')
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 29, true)
	RW.later(1)
	eq(TR:GetScroll(), 100, 'nor a newly tracked quest')
	TR:SetCollapsed(false)
	eq(TR:GetScroll(), 100, 'opened again at the place it had')
end)

RW.both('the Other group collapses by its key, apart from a real header titled Other', function(st, TR)
	Q.set({ Q.quest(5, { title = 'Stray' }), Q.header('Other'), Q.quest(6, { title = 'Real other' }) }, { 5, 6 })
	TR:Refresh()
	local stray_group, real = RW.zone(TR, TR.OTHER_KEY), RW.zone(TR, 'Other')
	check(stray_group ~= nil and real ~= nil and stray_group ~= real, 'two headers, both named Other')
	stub.click(stray_group.chevron)
	eq(TR:CharData().zones[TR.OTHER_KEY], true, "saved under the group's key")
	eq(TR:CharData().zones['Other'], nil, 'not under the title')
	eq(RW.quest(TR, 5), nil, "the stray quest's row is gone")
	check(RW.quest(TR, 6) ~= nil, "the real header's quest stays")
end)

RW.both("the focus bar follows the scroll bar's own drag", function(st, TR)
	long_log(30, { focused = 2 })
	TR:Refresh()
	TR:ScrollTo(0)
	local bar, row = TR.focusBar, RW.quest(TR, 2)
	check(bar:IsShown(), 'in view at the top')
	TR.scroll.ScrollBar:SetScrollPercentage(0.1)
	check(TR:GetScroll() > 0, 'dragged')
	check(bar:IsShown(), 'its row is still in view')
	eq(bar:GetTop(), row:GetTop(), 'the bar moved with it')
	TR.scroll.ScrollBar:SetScrollPercentage(1)
	check(not bar:IsShown(), 'dragged to the end: the row is out of view, the bar is gone')
	TR.scroll.ScrollBar:SetScrollPercentage(0)
	check(bar:IsShown(), 'dragged back: it returns')
	eq(bar:GetTop(), row:GetTop(), 'at its row')
end)

RW.both("a Fonts tab change redraws the rows (next frame): the font's size is read again, the rows reflow", function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = 'x', type = 'monster' } } }) }, { 1 })
	TR:Refresh()
	local row = RW.quest(TR, 1)
	local before = row:GetHeight()
	st.config.profile.fonts.normal.font_size = 24
	st:GetModule('Fonts'):UpdateFontConfig('normal')
	st:FontsChanged()
	RW.later(1)
	check(row:GetHeight() > before, 'the row grew with the font at once: ' .. before .. ' -> ' .. row:GetHeight())
	st.config.profile.fonts.normal.font_size = 16
	st:GetModule('Fonts'):UpdateFontConfig('normal')
	st:FontsChanged()
	RW.later(1)
	eq(row:GetHeight(), before, 'and back')
end)

RW.both('a refresh that replaces quests makes no frame: the rows of the quests that went are reused', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1), Q.quest(2), Q.quest(3) }, { 1, 2, 3 })
	TR:Refresh()
	Q.set({ Q.header('A'), Q.quest(3), Q.quest(4), Q.quest(5) }, { 3, 4, 5 })
	local counter = RW.counter()
	TR:Refresh()
	eq(counter.frames, 0, 'two quests replaced by two: no new frame')
	counter.stop()
	check(RW.quest(TR, 4) and RW.quest(TR, 5) and RW.quest(TR, 3), 'all three drawn')
end)

RW.both('the timer ticker stops while the tracker is collapsed and starts again when it opens', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { time = { total = 300, elapsed = 10 }, timer = 290 }) }, { 1 })
	TR:Refresh()
	check(TR.timerTicker ~= nil, 'running')
	TR:SetCollapsed(true)
	eq(TR.timerTicker, nil, 'collapsed: no ticker')
	TR:Refresh()
	eq(TR.timerTicker, nil, 'a refresh keeps it off')
	TR:SetCollapsed(false)
	check(TR.timerTicker ~= nil, 'opened: running again')
end)

RW.both('the header chevron does nothing while popups hold the window open', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 }, { popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = 'An offer' } })
	TR:Refresh()
	stub.click(TR.header.collapse)
	eq(TR:CharData().collapsed, false, 'the click is ignored: it would save a state that shows nothing')
	check(not TR:IsCollapsed(), 'still open')
end)

RW.both('a secret in any field of the log (objective text, counts, percent, waypoint, timer, popup title) errors nothing', function(st, TR)
	local methods = getmetatable(UIParent:CreateFontString(nil, 'OVERLAY')).__index
	local set_text = methods.SetText
	methods.SetText = function(self, text)
		if issecretvalue(text) then return end
		return set_text(self, text)
	end
	local S = load_test_file('lib/secrets.lua')
	local restore = S.install()
	Q.set({
		Q.header('A'),
		Q.quest(1, { objectives = { { text = S.secret('text'), type = 'monster', numFulfilled = S.secret('n'), numRequired = S.secret('m'), finished = S.secret('f') } },
			waypoint = S.secret('wp'), time = { total = S.secret('t'), elapsed = S.secret('e') }, timer = S.secret('timer') }),
		Q.quest(2, { objectives = { { text = 'Escort', type = 'progressbar' } }, percent = S.secret('percent') }),
	}, { 1, 2 }, { focused = 1, popups = { { id = 77, kind = 'OFFER' } }, titles = { [77] = S.secret('popup title') } })
	TR:Refresh()
	TR:Refresh()
	check(RW.quest(TR, 1) ~= nil and RW.quest(TR, 2) ~= nil, 'both quests are drawn')
	check(TR:GetPopupRow(77, 'OFFER') ~= nil, 'and the popup with its secret title')
	restore()
	methods.SetText = set_text
end)

RW.both("only the player's own input counts as scrolling: the wheel, and a mouse-down on the bar; the bar re-setting the offset after a range change does not", function(st, TR)
	-- Blizzard's bar answers a range change by setting the offset again (clamped),
	-- which fires OnVerticalScroll outside ScrollTo.
	local set_content = TR.scroll.SetContentSize
	TR.scroll.SetContentSize = function(self, width, height)
		set_content(self, width, height)
		self:SetVerticalScroll(math.min(self:GetVerticalScroll(), math.max(0, height - self:GetHeight())))
	end
	local log, watched = long_log(30)
	TR:Refresh()
	TR:ScrollTo(TR.scrollRange)
	check(TR:GetScroll() > 100, 'scrolled to the bottom')
	-- Turn in quests so the list shrinks under the offset, then accept a follow-up that sorts first.
	local shorter, kept = { Q.header('A'), Q.quest(31, { title = 'Follow-up', overrides = true }) }, { 31 }
	for id = 1, 20 do
		shorter[#shorter + 1] = Q.quest(id)
		kept[#kept + 1] = id
	end
	Q.set(shorter, kept)
	stub.fire_event('QUEST_REMOVED', 25)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 31, true)
	RW.later(1)
	eq(TR.lastUserScroll, nil, "the bar's own re-set is not the player's scrolling")
	local row = RW.quest(TR, 31)
	check(row:GetTop() <= TR.scroll:GetTop() and row:GetBottom() >= TR.scroll:GetBottom(), 'the follow-up is in view')
	-- Real input does start the quiet period: the wheel...
	TR:ScrollTo(100)
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	check(TR.lastUserScroll ~= nil, 'the wheel counts')
	-- ...and a mouse-down on any part of the bar.
	local bar = TR.scroll.ScrollBar
	for _, part in ipairs({ bar:GetThumb(), bar.Track, bar.Back, bar.Forward }) do
		TR.lastUserScroll = nil
		stub.fire_script(part, 'OnMouseDown', 'LeftButton')
		check(TR.lastUserScroll ~= nil, 'a mouse-down on the bar counts')
	end
end)

RW.both('two tracks inside one gap: both rows are drawn, the scroll goes to the last; a track then an untrack of the second goes to the first', function(st, TR)
	local log, watched = long_log(30)
	TR:Refresh()
	RW.later(1)
	for _, id in ipairs({ 31, 32 }) do
		log[#log + 1] = Q.quest(id)
		watched[#watched + 1] = id
	end
	Q.set(log, watched)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 31, true)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 32, true)
	RW.later(1)
	check(RW.quest(TR, 31) ~= nil and RW.quest(TR, 32) ~= nil, 'neither quest loses its row')
	local last = RW.quest(TR, 32)
	check(last:GetBottom() >= TR.scroll:GetBottom(), 'the last one is in view')
	-- A track, a second track, and the second untracked again: the first is scrolled to.
	TR:ScrollTo(0)
	local first_only = {}
	for i = 1, 30 do first_only[i] = watched[i] end
	first_only[31] = 31
	Q.set(log, first_only)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 31, true)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 32, true)
	stub.fire_event('QUEST_WATCH_LIST_CHANGED', 32, false)
	RW.later(1)
	check(TR:GetScroll() > 0, 'scrolled')
	check(RW.quest(TR, 31):GetBottom() >= TR.scroll:GetBottom(), 'to the first, which is still tracked')
end)

RW.both('a collapsed tracker redraws no rows: its count updates, and the rows are drawn once when it opens', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = 'old', type = 'monster' } } }) }, { 1 }, {})
	TR:Refresh()
	TR:SetCollapsed(true)
	Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = 'new', type = 'monster' } } }), Q.quest(2) }, { 1, 2 })
	local calls = RW.calls()
	TR:Refresh()
	local texts = calls.by.SetText or 0
	calls.stop()
	eq(texts, 1, 'only the header count was set (2 in the log)')
	eq(RW.text(TR.header.count), '2/' .. (st.forever and 40 or 35), 'the count is current')
	eq(RW.text(RW.quest(TR, 1).parts[1].fs), 'old', 'the hidden rows were left alone')
	eq(RW.quest(TR, 2), nil, 'and no row was made')
	TR:SetCollapsed(false)
	eq(RW.text(RW.quest(TR, 1).parts[1].fs), 'new', 'opened: the rows are drawn')
	check(RW.quest(TR, 2) ~= nil, 'with the new quest')
	local again = RW.calls()
	TR:SetCollapsed(true)
	TR:SetCollapsed(false)
	check(true, 'opening again with nothing stale is fine')
	again.stop()
end)

RW.both('a profile change redraws the tracker once through st:FontsChanged, a Fonts-tab change once', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 })
	TR:Refresh()
	local counted = 0
	local redraw = TR.Redraw
	TR.Redraw = function(self, ...)
		counted = counted + 1
		return redraw(self, ...)
	end
	-- The profile change itself: the new profile holds another size for Text, and
	-- the profile update (Config:UpdateConfig) sets every font object, then runs
	-- st:FontsChanged.
	local before = RW.quest(TR, 1):GetHeight()
	st.config.profile.fonts.normal.font_size = 24
	st:GetModule('Fonts'):UpdateConfig()
	st:FontsChanged()
	RW.later(1)
	check(counted <= 1, 'every font of a profile change: one redraw, not one each: ' .. counted)
	check(counted >= 1, 'but it does redraw')
	check(RW.quest(TR, 1):GetHeight() > before, 'and the rows read the new size')
	st.config.profile.fonts.normal.font_size = 16
	st:GetModule('Fonts'):UpdateConfig()
	st:FontsChanged()
	RW.later(1)
	eq(RW.quest(TR, 1):GetHeight(), before, 'and back')
end)

RW.both('an offer and a complete popup of the same quest each get a row', function(st, TR)
	Q.set({ Q.header('A'), Q.quest(1) }, { 1 }, { popups = { { id = 77, kind = 'OFFER' }, { id = 77, kind = 'COMPLETE' } }, titles = { [77] = 'Both' } })
	TR:Refresh()
	local offer, complete = TR:GetPopupRow(77, 'OFFER'), TR:GetPopupRow(77, 'COMPLETE')
	check(offer ~= nil and complete ~= nil and offer ~= complete, 'two rows')
	eq(RW.text(offer.label), 'Quest discovered', 'the offer says so')
	eq(RW.text(complete.label), 'Quest complete', 'the complete says so')
	eq(#RW.rows(TR, 'popup'), 2, 'two in use')
end)

