-- SaftUI's tracker's clicks, right-click menu and tooltips
-- (SaftUI-Tracker/clicks.lua, with the row and icon scripts of rows.lua), on
-- both clients: a click on a quest row, the shift click, the chat link, a
-- complete auto-complete quest, Show on map out of combat and focus in it, the
-- icon, Blizzard's menu entries in Blizzard's order with Blizzard's strings,
-- what the menu does in combat, the experiment P5's seam, the row tooltip and a
-- zone header's click.
--
-- Real: SaftUI-Tracker's files, Core's helpers and theme engine, the quest
-- stubs (tests/wow/quests.lua records each Blizzard function a click or menu
-- entry runs in stub.quest_calls). Made by hand, as the bags' slot menu test
-- does (tests/bags/category_tooltip_menu_test.lua): MenuUtil, which records
-- the generator's elements (title, buttons, each button's SetEnabled and
-- SetTooltip) so the test reads them and clicks them.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q

-- The game's menu: MenuUtil.CreateContextMenu(owner, generator) calls the
-- generator with a root description; every element is kept in order.
-- opened[i] = { owner, list = { { kind, text, onClick, enabled, tooltip } } }.
local function menu_stand_in()
	local opened = {}
	local function element(list, kind, text, onClick)
		local item = { kind = kind, text = text, onClick = onClick, enabled = true }
		list[#list + 1] = item
		-- Blizzard's SetEnabled takes a boolean or a function the menu polls.
		function item:SetEnabled(enabled) self.enabled = enabled end
		function item:SetTooltip(fn) self.tooltip = fn end
		return item
	end
	_G.MenuUtil = {
		CreateContextMenu = function(owner, generator)
			local root = { owner = owner, list = {} }
			local description = {}
			function description:CreateTitle(text) return element(root.list, 'title', text) end
			function description:CreateButton(text, onClick) return element(root.list, 'button', text, onClick) end
			generator(owner, description)
			opened[#opened + 1] = root
			return root
		end,
	}
	return opened
end

-- Whether a menu element is enabled now: its value, or what its polled function says.
local function enabled(item)
	if type(item.enabled) == 'function' then return item.enabled() and true or false end
	return item.enabled
end

-- What a menu element's tooltip callback writes on a tooltip.
local function tip_of(item)
	if not item.tooltip then return nil end
	local shown
	item.tooltip({ SetText = function(_, text) shown = text end, AddLine = function(_, text) shown = shown or text end }, item)
	return shown
end

local function texts(list)
	local out = {}
	for i, item in ipairs(list) do out[i] = tostring(item.text) end
	return table.concat(out, '|')
end

local function entry(list, text)
	for _, item in ipairs(list) do
		if item.text == text then return item end
	end
end

-- The calls the game saw since the last read, joined; the list is emptied.
local function calls()
	local out = table.concat(stub.quest_calls, ' ')
	stub.quest_calls = {}
	return out
end

local function has(haystack, needle) return haystack:find(needle, 1, true) ~= nil end

-- Two quests tracked in one zone, the player there; the quest log's player state
-- is the stub's default (not grouped, not in combat, nothing focused).
local function zone()
	stub.real_zone_text = 'Elwynn Forest'
	Q.set({
		Q.header('Elwynn Forest'),
		Q.quest(1, { title = 'Wolves' }),
		Q.quest(2, { title = 'Boars', pushable = true }),
	}, { 1, 2 })
	stub.quest_calls = {}
end

local function click(row, button)
	stub.click(row, button or 'LeftButton')
end

RW.both('the stubs the clicks use: the tooltip methods behave as the game\'s accessors', function(st, TR)
	zone()
	GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	GameTooltip:SetQuestLogSpecialItem(2)
	eq(stub.state(GameTooltip).texts[1], 'quest item 2', 'SetQuestLogSpecialItem')
	check(not pcall(GameTooltip.SetQuestLogSpecialItem, GameTooltip, 'x'), 'a bad argument errors')
	GameTooltip:SetHyperlink('|Hquest:1|h[x]|h')
	GameTooltip:SetQuestPartyProgress(1, true)
	eq(stub.state(GameTooltip).lines, 1, 'SetQuestPartyProgress starts the tooltip over, as every accessor does, omitTitle or not')
	eq(stub.state(GameTooltip).texts[1], 'party 1', 'with the party line')
	GameTooltip:SetHyperlink('|Hquest:1|h[x]|h')
	GameTooltip:AppendInfo('GetQuestPartyProgress', 1, true)
	eq(stub.state(GameTooltip).lines, 2, 'AppendInfo adds to it')
	stub.party_progress = false
	GameTooltip:Show()
	GameTooltip:AppendInfo('GetQuestPartyProgress', 1, true)
	eq(stub.state(GameTooltip).lines, 2, 'with no party data it adds nothing')
	check(GameTooltip:IsShown(), 'and hides nothing')
	GameTooltip:SetQuestPartyProgress(1)
	check(not GameTooltip:IsShown(), 'SetQuestPartyProgress with no data hides the tooltip')
	stub.party_progress = nil
	GameTooltip:AddLine('x', 0.5, 0.25, 0.75)
	eq(stub.state(GameTooltip).colors[stub.state(GameTooltip).lines][3], 0.75, 'AddLine keeps its color')
	GameTooltip:SetText('y')
	eq(next(stub.state(GameTooltip).colors), nil, 'SetText starts the colors over')
	UIErrorsFrame:AddMessage('boo', 1, 0.1, 0.1, 1)
	eq(stub.ui_errors[1][1], 'boo', 'the error line is recorded')
end)

------------------------------------------------------------------ the clicks

RW.both('a chat box open: the shift click puts the quest link in it and does nothing else', function(st, TR)
	zone()
	TR:Refresh()
	stub.chat_open = true
	stub.modified.CHATLINK = true
	stub.modified.QUESTWATCHTOGGLE = true -- the same Shift: the link wins
	local row = RW.quest(TR, 1)
	click(row)
	eq(#stub.chat_inserted, 1, 'the link went into the chat box')
	check(stub.chat_inserted[1]:find('Wolves', 1, true), 'the quest\'s own')
	local seen = calls()
	check(not has(seen, 'RemoveQuestWatch') and not has(seen, 'QuestMapFrame_OpenToQuestDetails'), 'nothing else ran: ' .. seen)
	eq(#stub.quests.watched, 2, 'still tracked')
	eq(stub.quests.focused, 0, 'not focused')
	local opened = menu_stand_in()
	click(row, 'RightButton')
	eq(#opened, 0, 'a right click with the box open inserts the link too, and opens no menu')
	eq(#stub.chat_inserted, 2, 'the link again')
	-- The box open but no modifier: Blizzard's call refuses, the click goes on.
	stub.modified.CHATLINK = false
	stub.modified.QUESTWATCHTOGGLE = false
	calls()
	click(row)
	eq(#stub.chat_inserted, 2, 'no modifier: nothing inserted')
	check(has(calls(), 'QuestMapFrame_OpenToQuestDetails:1'), 'the click goes on to open the map')
end)

RW.both('shift-click stops tracking where QuestUtil.CanRemoveQuestWatch allows it; an untracked zone quest is tracked', function(st, TR)
	zone()
	TR:Refresh()
	stub.modified.QUESTWATCHTOGGLE = true
	click(RW.quest(TR, 1))
	local seen = calls()
	check(has(seen, 'QuestUtil.CanRemoveQuestWatch') and has(seen, 'IsModifiedClick:QUESTWATCHTOGGLE'), 'asked as Blizzard does: ' .. seen)
	eq(table.concat(stub.quests.watched, ','), '2', 'quest 1 is no longer watched')
	check(not has(seen, 'QuestMapFrame_OpenToQuestDetails'), 'the map did not open')
	-- The new player experience forbids it: nothing happens.
	stub.npe_restricted = true
	click(RW.quest(TR, 2))
	eq(table.concat(stub.quests.watched, ','), '2', 'NPE restricted: still tracked')
	check(not has(calls(), 'QuestMapFrame_OpenToQuestDetails'), 'and no map either')
	stub.npe_restricted = false
	-- The current zone's untracked quest, with Show on Tracked and the current zone's (ruling 9).
	TR.config.quests.show = 'zone'
	TR:UpdateConfig()
	stub.run_timers()
	local row = RW.quest(TR, 1)
	check(row ~= nil, 'the untracked zone quest is drawn')
	click(row)
	eq(table.concat(stub.quests.watched, ','), '2,1', 'shift-click tracks it')
	RW.later(1) -- the list changed: the row's quest is tracked now
	-- In combat a watch change runs Blizzard's tracker, map and super track
	-- handlers inside our call (QUEST_WATCH_LIST_CHANGED is synchronous): it is not made, and
	-- the error line says why.
	stub.in_combat = true
	stub.ui_errors = {}
	click(RW.quest(TR, 1))
	eq(table.concat(stub.quests.watched, ','), '2,1', 'in combat a Shift-click changes nothing')
	eq(#stub.ui_errors, 1, 'and says so')
	eq(stub.ui_errors[1][1], 'Out of combat only', 'in the error line')
	stub.in_combat = false
	-- The seam: P6 failing is one function.
	TR.WatchChangeAllowed = function() return false end
	click(RW.quest(TR, 1))
	eq(table.concat(stub.quests.watched, ','), '2,1', 'WatchChangeAllowed false: nothing changes out of combat either')
end)

RW.both('tracking a 26th quest says so, as Blizzard\'s own refusal does', function(st, TR)
	stub.real_zone_text = 'A'
	local log, watched = { Q.header('A') }, {}
	for id = 1, 26 do
		log[#log + 1] = Q.quest(id)
		if id <= 25 then watched[#watched + 1] = id end
	end
	Q.set(log, watched)
	TR.config.quests.show = 'zone'
	TR:Refresh()
	stub.modified.QUESTWATCHTOGGLE = true
	stub.ui_errors = {}
	click(RW.quest(TR, 26))
	eq(#stub.quests.watched, 25, 'the 26th is not tracked')
	eq(stub.ui_errors[1] and stub.ui_errors[1][1], OBJECTIVES_WATCH_TOO_MANY, "with the game's words")
	eq(stub.ui_errors[1][2] .. ' ' .. stub.ui_errors[1][3], '1 0.1', 'in red')
	-- Through the menu too.
	local opened = menu_stand_in()
	stub.modified.QUESTWATCHTOGGLE = false
	click(RW.quest(TR, 26), 'RightButton')
	stub.ui_errors = {}
	entry(opened[1].list, TRACK_QUEST).onClick()
	eq(#stub.quests.watched, 25, 'Track Quest does not either')
	eq(#stub.ui_errors, 1, 'and says so')
end)

RW.both('left on a complete auto-complete quest: ShowQuestComplete and its popup removed, in combat too', function(st, TR)
	stub.real_zone_text = 'Elwynn Forest'
	Q.set({ Q.header('Elwynn Forest'), Q.quest(7, { title = 'Done', auto = true, complete = true }), Q.quest(8, { title = 'Open', auto = true }) },
		{ 7, 8 }, { popups = { { id = 7, kind = 'COMPLETE' } }, titles = {} })
	TR:Refresh()
	stub.quest_calls = {}
	click(RW.quest(TR, 7))
	local seen = calls()
	eq(seen, 'ChatFrameUtil.TryInsertQuestLinkForQuestID:7 IsModifiedClick:QUESTWATCHTOGGLE RemoveAutoQuestPopUp:7 ShowQuestComplete:7',
		"the popup removed, then the turn-in shown, as Blizzard's click does")
	eq(#stub.quests.popups, 0, 'the popup is gone')
	check(TR:GetPopupRow(7, 'COMPLETE') ~= nil, 'its row is still drawn until the refresh the click asked for')
	RW.later(1)
	eq(TR:GetPopupRow(7, 'COMPLETE'), nil, 'which then removes it')
	eq(stub.quests.shown[#stub.quests.shown], 'complete:7', 'the quest frame was asked for')
	-- An auto-complete quest not complete yet is an ordinary click.
	click(RW.quest(TR, 8))
	check(has(calls(), 'QuestMapFrame_OpenToQuestDetails:8'), 'an unfinished one opens the map')
	-- In combat the same two game calls (no Blizzard Lua in them).
	stub.in_combat = true
	stub.quests.popups = { { id = 7, kind = 'COMPLETE' } }
	click(RW.quest(TR, 7))
	seen = calls()
	check(has(seen, 'ShowQuestComplete:7') and has(seen, 'RemoveAutoQuestPopUp:7'), 'in combat too: ' .. seen)
	eq(#stub.blocked, 0, 'nothing blocked')
	stub.in_combat = false
end)

RW.both('left: Show on map out of combat, focus in combat; Left click Focus: focus always; the icon toggles focus; a click is not scrolling', function(st, TR)
	zone()
	TR:Refresh()
	local row = RW.quest(TR, 1)
	click(row)
	eq(calls(), 'ChatFrameUtil.TryInsertQuestLinkForQuestID:1 IsModifiedClick:QUESTWATCHTOGGLE QuestMapFrame_OpenToQuestDetails:1',
		'Blizzard\'s order: the chat link, the modified click, then the map')
	eq(stub.quests.focused, 0, 'out of combat the map opens and the focus is left')
	stub.in_combat = true
	click(row)
	local seen = calls()
	check(not has(seen, 'QuestMapFrame_OpenToQuestDetails'), 'in combat the map is not opened: ' .. seen)
	eq(stub.quests.focused, 1, 'it focuses the quest instead')
	stub.in_combat = false
	-- Left click: Focus.
	stub.quests.focused = 0
	TR.config.quests.left_click = 'focus'
	click(RW.quest(TR, 2))
	eq(stub.quests.focused, 2, 'Focus focuses out of combat')
	check(not has(calls(), 'QuestMapFrame_OpenToQuestDetails'), 'and opens no map')
	click(RW.quest(TR, 2))
	eq(stub.quests.focused, 2, 'a second click on the focused quest keeps it focused (only the icon toggles)')
	-- The icon: focuses, and stops focusing when it is.
	local icon = RW.quest(TR, 1).iconButton
	check(icon ~= nil and icon:IsShown(), 'a quest row has an icon button, shown')
	local clicks = stub.state(RW.quest(TR, 1)).click_buttons
	eq(table.concat(clicks, ','), 'LeftButtonUp,RightButtonUp', 'the row takes both mouse buttons')
	click(icon)
	eq(stub.quests.focused, 1, 'the icon focuses the quest')
	click(icon)
	eq(stub.quests.focused, 0, 'and again stops focusing it')
	stub.in_combat = true
	click(icon)
	eq(stub.quests.focused, 1, 'in combat too: a game call, no Blizzard Lua')
	eq(#stub.blocked, 0, 'nothing blocked')
	stub.in_combat = false
	-- None of this is the player scrolling.
	eq(TR.lastUserScroll, nil, 'a click is not the wheel or the bar')
	-- The icon: tooltip says what it does.
	stub.fire_script(icon, 'OnEnter', true)
	eq(stub.state(GameTooltip).texts[1], STOP_SUPER_TRACK_QUEST, 'the icon of the focused quest offers to stop focusing')
	stub.fire_script(icon, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'and hides the tooltip')
end)

RW.both('a click on a row in a long, scrolled list leaves the scroll alone; tracking from the menu scrolls only by the existing rule', function(st, TR)
	local log, watched = { Q.header('A') }, {}
	for id = 1, 30 do
		log[#log + 1] = Q.quest(id, { title = 'Quest ' .. id, objectives = { { text = 'A thing', type = 'monster', numFulfilled = 0, numRequired = 3 } } })
		watched[#watched + 1] = id
	end
	stub.real_zone_text = 'A'
	Q.set(log, watched)
	TR:Refresh()
	check((TR.scrollRange or 0) > 0, 'the list scrolls')
	TR:ScrollTo(100)
	local before = TR:GetScroll()
	local row
	for _, candidate in ipairs(RW.rows(TR, 'quest')) do
		if candidate:GetTop() <= TR.scroll:GetTop() and candidate:GetBottom() >= TR.scroll:GetBottom() then row = candidate break end
	end
	check(row ~= nil, 'a row in view')
	RW.mouse_on(row)
	TR.config.quests.left_click = 'focus'
	click(row)
	stub.run_timers()
	RW.later(1)
	eq(TR:GetScroll(), before, 'the click did not move the list (the mouse is on the tracker)')
	eq(TR.lastUserScroll, nil, 'and was not counted as scrolling')
	-- Focusing from the menu while the mouse is off the tracker scrolls the quest in, by the one rule.
	RW.mouse_off()
	stub.quests.focused = 30
	stub.fire_event('SUPER_TRACKING_CHANGED')
	RW.later(1)
	check(TR:GetScroll() ~= before, 'a focus change elsewhere scrolls it into view')
end)

------------------------------------------------------------------ the menu

RW.both('the menu: Blizzard\'s entries and strings in order; Share only shareable in a group; no Share in chat', function(st, TR)
	zone()
	TR:Refresh()
	local opened = menu_stand_in()
	local row = RW.quest(TR, 2)
	click(row, 'RightButton')
	eq(#opened, 1, 'a right click opens the menu')
	eq(opened[1].owner, row, 'on the row')
	eq(texts(opened[1].list), table.concat({ 'Boars', SUPER_TRACK_QUEST, OBJECTIVES_VIEW_IN_QUESTLOG, OBJECTIVES_SHOW_QUEST_MAP, OBJECTIVES_STOP_TRACKING, ABANDON_QUEST_ABBREV }, '|'),
		'the title, Focus, details, Show on map, Stop tracking and Abandon; no Share while on one\'s own')
	eq(opened[1].list[1].kind, 'title', 'the title is a title')
	-- Alone: no Share. Grouped but not pushable: none. Grouped and pushable: it is, before Abandon.
	stub.group = {}
	click(RW.quest(TR, 1), 'RightButton')
	eq(entry(opened[2].list, SHARE_QUEST), nil, 'a quest that can\'t be shared has no Share even in a group')
	click(row, 'RightButton')
	eq(texts(opened[3].list), table.concat({ 'Boars', SUPER_TRACK_QUEST, OBJECTIVES_VIEW_IN_QUESTLOG, OBJECTIVES_SHOW_QUEST_MAP, OBJECTIVES_STOP_TRACKING, SHARE_QUEST, ABANDON_QUEST_ABBREV }, '|'),
		'Share, in a group, before Abandon')
	check(not texts(opened[3].list):find('chat', 1, true), 'no Share in chat')
	-- Every entry does what Blizzard\'s does.
	stub.quest_calls = {}
	local list = opened[3].list
	entry(list, SUPER_TRACK_QUEST).onClick()
	eq(stub.quests.focused, 2, 'Focus focuses')
	entry(list, OBJECTIVES_VIEW_IN_QUESTLOG).onClick()
	entry(list, OBJECTIVES_SHOW_QUEST_MAP).onClick()
	entry(list, SHARE_QUEST).onClick()
	entry(list, ABANDON_QUEST_ABBREV).onClick()
	eq(calls(), 'QuestUtil.OpenQuestDetails:2 QuestMapFrame_OpenToQuestDetails:2 QuestUtil.ShareQuest:2 QuestMapQuestOptions_AbandonQuest:2',
		'details, the map, Share and Abandon, with Blizzard\'s functions')
	entry(list, OBJECTIVES_STOP_TRACKING).onClick()
	eq(table.concat(stub.quests.watched, ','), '1', 'Stop tracking untracks')
	-- The toggled texts: Remove Focus while it is focused, Close Quest Details while they show.
	RW.later(1) -- quest 2 is untracked now, quest 1 is tracked
	stub.quests.focused, stub.quests.details = 1, 1
	click(RW.quest(TR, 1), 'RightButton')
	local last = opened[#opened].list
	check(entry(last, STOP_SUPER_TRACK_QUEST) ~= nil and entry(last, SUPER_TRACK_QUEST) == nil, 'the focused quest offers Stop focusing')
	check(entry(last, OBJECTIVES_HIDE_VIEW_IN_QUESTLOG) ~= nil and entry(last, OBJECTIVES_VIEW_IN_QUESTLOG) == nil, 'and Hide quest details while they show')
	entry(last, STOP_SUPER_TRACK_QUEST).onClick()
	eq(stub.quests.focused, 0, 'Stop focusing sets the focus to 0')
	-- The new player experience: no Stop tracking.
	stub.npe_restricted = true
	click(RW.quest(TR, 1), 'RightButton')
	eq(entry(opened[#opened].list, OBJECTIVES_STOP_TRACKING), nil, 'no Stop tracking in the new player experience')
end)

RW.both('an untracked zone quest\'s menu offers Track quest in place of Stop tracking, and it tracks', function(st, TR)
	zone()
	TR.config.quests.show = 'zone'
	stub.quests.watched = { 2 }
	TR:Refresh()
	local opened = menu_stand_in()
	local row = RW.quest(TR, 1)
	check(row ~= nil, 'the untracked quest is drawn')
	click(row, 'RightButton')
	local list = opened[1].list
	check(entry(list, OBJECTIVES_STOP_TRACKING) == nil, 'no Stop tracking')
	check(entry(list, TRACK_QUEST) ~= nil, 'Track quest in its place')
	local at
	for i, item in ipairs(list) do if item.text == TRACK_QUEST then at = i end end
	eq(list[at - 1].text, OBJECTIVES_SHOW_QUEST_MAP, 'where Stop tracking sits, after Show on map')
	entry(list, TRACK_QUEST).onClick()
	eq(table.concat(stub.quests.watched, ','), '2,1', 'it tracks')
	-- A client without the string gets the plain words.
	local saved = _G.TRACK_QUEST
	_G.TRACK_QUEST = nil
	local entries = TR.MenuEntries({ id = 1, title = 'Wolves', tracked = false }, { combat = false })
	_G.TRACK_QUEST = saved
	local names = {}
	for i, e in ipairs(entries) do names[i] = e.text end
	check(table.concat(names, '|'):find('Track Quest', 1, true), 'Track Quest where the client lacks the string')
end)

RW.both('in combat details, Show on map, Abandon and the watch changes are disabled with "Out of combat only"; Focus and Share work', function(st, TR)
	zone()
	TR:Refresh()
	stub.group = {}
	local opened = menu_stand_in()
	stub.in_combat = true
	stub.quest_calls = {}
	click(RW.quest(TR, 2), 'RightButton')
	-- No Blizzard Lua in combat: not even the menu's read of it (the details toggle's text).
	check(not has(calls(), 'IsShowingQuestDetails'), 'the details frame is not asked in combat')
	local list = opened[1].list
	for _, text in ipairs({ OBJECTIVES_VIEW_IN_QUESTLOG, OBJECTIVES_SHOW_QUEST_MAP, OBJECTIVES_STOP_TRACKING, ABANDON_QUEST_ABBREV }) do
		local item = entry(list, text)
		eq(enabled(item), false, text .. ' is disabled in combat')
		eq(tip_of(item), 'Out of combat only', text .. ' says why')
	end
	for _, text in ipairs({ SUPER_TRACK_QUEST, SHARE_QUEST }) do
		eq(enabled(entry(list, text)), true, text .. ' stays enabled')
		eq(tip_of(entry(list, text)), nil, 'with no tip')
	end
	entry(list, SUPER_TRACK_QUEST).onClick()
	eq(stub.quests.focused, 2, 'Focus works in combat')
	stub.quest_calls = {}
	entry(list, SHARE_QUEST).onClick()
	eq(calls(), 'QuestUtil.ShareQuest:2', 'Share works in combat: two C calls and nothing written')
	-- The disabled ones refuse to run when clicked anyway.
	entry(list, OBJECTIVES_STOP_TRACKING).onClick()
	eq(table.concat(stub.quests.watched, ','), '1,2', 'Untrack does nothing in combat')
	for _, text in ipairs({ OBJECTIVES_VIEW_IN_QUESTLOG, OBJECTIVES_SHOW_QUEST_MAP, ABANDON_QUEST_ABBREV }) do entry(list, text).onClick() end
	eq(calls(), '', 'nor does any of the Blizzard UI Lua')
	stub.in_combat = false
end)

RW.both('a menu open when combat starts greys out, and comes back when it ends', function(st, TR)
	zone()
	TR:Refresh()
	local opened = menu_stand_in()
	click(RW.quest(TR, 2), 'RightButton')
	local list = opened[1].list
	local gated = { OBJECTIVES_VIEW_IN_QUESTLOG, OBJECTIVES_SHOW_QUEST_MAP, OBJECTIVES_STOP_TRACKING, ABANDON_QUEST_ABBREV }
	for _, text in ipairs(gated) do
		eq(enabled(entry(list, text)), true, text .. ' is enabled out of combat')
		eq(tip_of(entry(list, text)), nil, 'with no tip')
	end
	stub.in_combat = true
	for _, text in ipairs(gated) do
		eq(enabled(entry(list, text)), false, text .. ' is greyed out once combat starts')
		eq(tip_of(entry(list, text)), 'Out of combat only', 'and says why')
	end
	stub.quest_calls = {}
	for _, text in ipairs(gated) do entry(list, text).onClick() end
	eq(calls(), '', 'clicking them runs nothing')
	eq(table.concat(stub.quests.watched, ','), '1,2', 'and untracks nothing')
	stub.in_combat = false
	eq(enabled(entry(list, ABANDON_QUEST_ABBREV)), true, 'enabled again when combat ends')
end)

RW.both('each Blizzard UI entry and the watch changes sit behind one seam: a failed in-game check changes one constant', function(st, TR)
	zone()
	TR:Refresh()
	local opened = menu_stand_in()
	TR.QUEST_DETAILS = false
	click(RW.quest(TR, 1), 'RightButton')
	check(entry(opened[1].list, OBJECTIVES_VIEW_IN_QUESTLOG) == nil, 'QUEST_DETAILS false: no Open Quest Details')
	check(entry(opened[1].list, ABANDON_QUEST_ABBREV) ~= nil and entry(opened[1].list, OBJECTIVES_SHOW_QUEST_MAP) ~= nil, 'the others stay')
	TR.QUEST_DETAILS, TR.ABANDON = true, false
	click(RW.quest(TR, 1), 'RightButton')
	check(entry(opened[2].list, ABANDON_QUEST_ABBREV) == nil, 'ABANDON false: no Abandon')
	check(entry(opened[2].list, OBJECTIVES_VIEW_IN_QUESTLOG) ~= nil, 'the details come back')
	TR.ABANDON = true
	local saved = _G.QuestMapQuestOptions_AbandonQuest
	_G.QuestMapQuestOptions_AbandonQuest = nil
	check(not TR.AbandonAllowed(), 'a client without the function: not allowed either')
	_G.QuestMapQuestOptions_AbandonQuest = saved
	TR.WatchChangeAllowed = function() return false end
	click(RW.quest(TR, 1), 'RightButton')
	eq(enabled(entry(opened[3].list, OBJECTIVES_STOP_TRACKING)), false, 'WatchChangeAllowed false: the menu\'s Untrack is disabled out of combat')
	local entries = TR.MenuEntries({ id = 1, title = 'Wolves', tracked = true }, { combat = false })
	local stop
	for _, e in ipairs(entries) do if e.text == OBJECTIVES_STOP_TRACKING then stop = e end end
	eq(stop.enabled, false, 'WatchChangeAllowed false: Untrack is disabled out of combat')
	eq(stop.tip, 'Out of combat only', 'with the tip')
end)

RW.both('P5 failed (TR.SHOW_ON_MAP = false): Left click offers Focus only, a saved map reads as focus, the menu drops it, the hint says "Click: focus."', function(st, TR)
	zone()
	check(TR.ShowOnMapAllowed(), 'allowed as designed')
	eq(TR.LeftClickValues().map, 'Show on map', 'Left click offers Show on map')
	eq(TR.LeftClickValues().focus, 'Focus', 'and Focus')
	TR.SHOW_ON_MAP = false
	check(not TR.ShowOnMapAllowed(), 'the one constant')
	check(TR.LeftClickValues().map == nil and TR.LeftClickValues().focus == 'Focus', 'Left click offers Focus only')
	eq(TR.config.quests.left_click, 'map', 'the saved value is still map')
	eq(TR.LeftClick(), 'focus', 'and reads as focus')
	TR:Refresh()
	click(RW.quest(TR, 1))
	check(not has(calls(), 'QuestMapFrame_OpenToQuestDetails'), 'a click never opens the map')
	eq(stub.quests.focused, 1, 'it focuses')
	local opened = menu_stand_in()
	click(RW.quest(TR, 1), 'RightButton')
	check(entry(opened[1].list, OBJECTIVES_SHOW_QUEST_MAP) == nil, 'the menu has no Show on map')
	eq(TR.ClickHint('map', TR.ShowOnMapAllowed()), 'Click: focus.', 'the hint')
	eq(TR.ClickHint('map', true, 'track'), 'Click: show on map (focus in combat). Shift-click: track. Right-click: more.', 'Shift tracks an untracked quest')
	eq(TR.ClickHint('map', true, 'none'), 'Click: show on map (focus in combat). Right-click: more.', 'and does nothing where the game forbids untracking')
	stub.fire_script(RW.quest(TR, 1), 'OnEnter', true)
	local s = stub.state(GameTooltip)
	eq(s.texts[s.lines], 'Click: focus.', 'on the tooltip')
	-- The seam also follows the game's function.
	TR.SHOW_ON_MAP = true
	local saved = _G.QuestMapFrame_OpenToQuestDetails
	_G.QuestMapFrame_OpenToQuestDetails = nil
	check(not TR.ShowOnMapAllowed(), 'a client without the function: not allowed either')
	_G.QuestMapFrame_OpenToQuestDetails = saved
	check(TR.ShowOnMapAllowed(), 'and back')
end)

test('ClickAction is a pure function of the quest, the button and the state', function()
	local st, TR = TW.world({ on = true })
	local tracked, loose = { id = 1, tracked = true }, { id = 2, tracked = false }
	local auto = { id = 3, tracked = true, auto = true, complete = true }
	local function act(quest, button, state)
		state.leftClick = state.leftClick or 'map'
		return TR.ClickAction(quest, button, state)
	end
	eq(act(tracked, 'LeftButton', { chat = true, modified = true }), 'link', 'the chat link beats everything')
	eq(act(tracked, 'RightButton', { chat = true }), 'link', 'on either button')
	eq(act(tracked, 'RightButton', {}), 'menu', 'right: the menu')
	eq(act(tracked, 'RightButton', { modified = true }), 'menu', 'a modified right click is the menu')
	eq(act(tracked, 'LeftButton', { modified = true }), 'untrack', 'shift: untrack a tracked quest')
	eq(act(tracked, 'LeftButton', { modified = true, canUntrack = false }), nil, 'unless the game forbids it: nothing')
	eq(act(loose, 'LeftButton', { modified = true }), 'track', 'an untracked quest is tracked')
	eq(act(loose, 'LeftButton', { modified = true, canUntrack = false }), 'track', 'whatever the new player experience says')
	eq(act(auto, 'LeftButton', {}), 'complete', 'left on a complete auto-complete quest')
	eq(act(auto, 'LeftButton', { combat = true }), 'complete', 'in combat too')
	eq(act(tracked, 'LeftButton', {}), 'map', 'left: the map')
	eq(act(tracked, 'LeftButton', { combat = true }), 'focus', 'in combat: focus')
	eq(act(tracked, 'LeftButton', { leftClick = 'focus' }), 'focus', 'Left click Focus')
	TR.SHOW_ON_MAP = false
	eq(act(tracked, 'LeftButton', {}), 'focus', 'P5 failed: focus')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the tooltip

RW.both('the tooltip: the quest link, party progress when grouped, the click hint; Tooltips off shows none; OnEnter fired with true', function(st, TR)
	zone()
	TR:Refresh()
	local row = RW.quest(TR, 1)
	stub.fire_script(row, 'OnEnter', true)
	local s = stub.state(GameTooltip)
	check(GameTooltip:IsOwned(row), 'the row owns the tooltip')
	eq(s.anchor, 'ANCHOR_NONE', 'at ANCHOR_NONE')
	local point, relative, relPoint, x, y = GameTooltip:GetPoint(1)
	eq(point .. ' ' .. relPoint .. ' ' .. x .. ' ' .. y, 'TOPRIGHT TOPLEFT -8 0', 'its top right 8 left of the row\'s top left (ruling 30)')
	eq(relative, row, 'of the row')
	eq(s.texts[1], GetQuestLink(1), 'the quest link')
	eq(s.lines, 2, 'not grouped: no party progress, so the link and the hint')
	eq(s.texts[2], 'Click: show on map (focus in combat). Shift-click: stop tracking. Right-click: more.', 'the hint')
	local grey = st.config.profile.colors.text.grey
	local r, g, b = grey:GetRGB()
	eq(('%.2f %.2f %.2f'):format(unpack(s.colors[2])), ('%.2f %.2f %.2f'):format(r, g, b), 'in Text > Grey')
	check(GameTooltip:IsShown(), 'shown')
	stub.fire_script(row, 'OnLeave', true)
	check(not GameTooltip:IsOwned(row) or not GameTooltip:IsShown(), 'hidden when the mouse leaves')
	-- Grouped: the party's progress after the link, before the hint.
	stub.group = {}
	stub.fire_script(row, 'OnEnter', true)
	s = stub.state(GameTooltip)
	eq(s.lines, 3, 'grouped: the link, the party, the hint')
	eq(s.texts[1], GetQuestLink(1), 'the link is still first')
	eq(s.texts[2], 'party 1', 'the party progress comes second')
	eq(s.texts[3], TR.ClickHint('map', true), 'then the hint')
	stub.fire_script(row, 'OnLeave', true)
	-- A party with no progress on the quest: the game adds nothing and hides nothing.
	stub.party_progress = false
	stub.fire_script(row, 'OnEnter', true)
	s = stub.state(GameTooltip)
	eq(s.lines, 2, 'no party data: the link and the hint')
	check(GameTooltip:IsShown(), 'still shown')
	stub.party_progress = nil
	stub.fire_script(row, 'OnLeave', true)
	-- Shift-click's words follow the quest.
	TR.config.quests.show = 'zone'
	stub.quests.watched = { 2 }
	TR:Refresh()
	stub.fire_script(RW.quest(TR, 1), 'OnEnter', true)
	s = stub.state(GameTooltip)
	eq(s.texts[s.lines], 'Click: show on map (focus in combat). Shift-click: track. Right-click: more.', 'an untracked zone quest: Shift-click tracks')
	stub.fire_script(RW.quest(TR, 1), 'OnLeave', true)
	stub.npe_restricted = true
	stub.fire_script(RW.quest(TR, 2), 'OnEnter', true)
	s = stub.state(GameTooltip)
	eq(s.texts[s.lines], 'Click: show on map (focus in combat). Right-click: more.', 'new player experience: no Shift-click')
	stub.fire_script(RW.quest(TR, 2), 'OnLeave', true)
	stub.npe_restricted = false
	TR.config.quests.show = 'tracked'
	stub.quests.watched = { 1, 2 }
	TR:Refresh()
	row = RW.quest(TR, 1)
	-- Left click Focus: the short hint.
	TR.config.quests.left_click = 'focus'
	stub.fire_script(row, 'OnEnter', true)
	s = stub.state(GameTooltip)
	eq(s.texts[s.lines], 'Click: focus.', 'Left click Focus: the hint says so')
	stub.fire_script(row, 'OnLeave', true)
	-- Where the game has no AppendInfo, the party line is left out.
	local methods = getmetatable(GameTooltip).__index
	local append = methods.AppendInfo
	methods.AppendInfo = nil
	stub.fire_script(row, 'OnEnter', true)
	eq(stub.state(GameTooltip).lines, 2, 'no party line without AppendInfo')
	stub.fire_script(row, 'OnLeave', true)
	methods.AppendInfo = append
	-- Tooltips off.
	TR.config.quests.tooltips = false
	GameTooltip:Hide()
	GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	stub.fire_script(row, 'OnEnter', true)
	check(not GameTooltip:IsOwned(row), 'Tooltips off: the row takes no tooltip')
	check(row.hover:IsShown(), 'but the hover still shows')
end)

RW.both('a secret title: the tooltip, the menu and the clicks pass it through', function(st, TR)
	-- The stubs' font strings take only strings, where the game's take a secret.
	local methods = getmetatable(UIParent:CreateFontString(nil, 'OVERLAY')).__index
	local set_text = methods.SetText
	methods.SetText = function(self, text)
		if issecretvalue(text) then return end
		return set_text(self, text)
	end
	local S = load_test_file('lib/secrets.lua')
	local restore = S.install()
	local secret = S.secret('title')
	stub.real_zone_text = 'A'
	Q.set({ Q.header('A'), Q.quest(1, { title = secret }) }, { 1 })
	TR:Refresh()
	local row = RW.quest(TR, 1)
	check(row ~= nil, 'the row is drawn')
	local opened = menu_stand_in()
	stub.fire_script(row, 'OnEnter', true)
	stub.fire_script(row, 'OnLeave', true)
	click(row, 'RightButton')
	eq(opened[1].list[1].text, secret, 'the menu\'s title is the secret value itself')
	click(row)
	restore()
	methods.SetText = set_text
end)

RW.both('with Quest icons off the icon button is hidden and takes no click: the row takes it', function(st, TR)
	zone()
	TR.config.quests.icons = false
	TR:Refresh()
	local row = RW.quest(TR, 1)
	check(not row.iconButton:IsShown(), 'no icon button over the title')
	eq(stub.click(row.iconButton), false, 'a click there is the row\'s, not the icon\'s')
	check(stub.quests.focused == 0, 'nothing was focused')
	TR.config.quests.icons = true
	TR:Refresh()
	check(row.iconButton:IsShown(), 'with them on it shows')
	local open = menu_stand_in()
	stub.click(row, 'RightButton')
	eq(#open, 1, 'the row takes the right button')
end)

------------------------------------------------------------------ nothing to open

RW.both('a zone header\'s right click does nothing; without MenuUtil nothing opens and nothing errors', function(st, TR)
	zone()
	TR:Refresh()
	local opened = menu_stand_in()
	local header = RW.zone(TR, 'Elwynn Forest')
	click(header, 'RightButton')
	eq(#opened, 0, 'a right click on a zone header opens nothing')
	eq(calls(), '', 'and calls nothing')
	check(RW.quest(TR, 1) ~= nil, 'it did not collapse')
	click(header, 'LeftButton')
	eq(TR:CharData().zones['Elwynn Forest'], true, 'a left click collapses it')
	check(RW.quest(TR, 1) == nil, 'and its quests go')
	click(header, 'LeftButton')
	check(RW.quest(TR, 1) ~= nil, 'and expands it again')
	-- No MenuUtil.
	_G.MenuUtil = nil
	click(RW.quest(TR, 1), 'RightButton')
	_G.MenuUtil = {}
	click(RW.quest(TR, 1), 'RightButton')
	_G.MenuUtil = nil
	TR:OpenMenu(RW.quest(TR, 1))
	TR:OpenMenu({})
	eq(#take_errors(), 0, 'no errors')
end)

test('the switch off: nothing of clicks.lua runs; no frame, hook, event or script is made for it', function()
	local st, TR = TW.world({ on = false })
	eq(TW.counts.frames, 0, 'no frame')
	eq(TW.counts.hooks, 0, 'no hook')
	eq(TW.counts.events, 0, 'no event')
	eq(TW.counts.scripts, 0, 'no script')
	check(type(TR.ClickAction) == 'function', 'the pure functions exist')
	eq(TR.pools, nil, 'but no row')
	TR:OnQuestClick({}, 'LeftButton')
	TR:ShowRowTooltip({})
	eq(#take_errors(), 0, 'and calling them with nothing built errors nothing')
end)
