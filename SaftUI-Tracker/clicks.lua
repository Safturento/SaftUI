local st = SaftUI
local TR = st.Tracker
local L = TR.LAYOUT

--[[
	What a click on a quest row does, the right-click menu and the row's
	tooltip. After Blizzard's own tracker's block click and menu
	(Blizzard_QuestObjectiveTracker.lua, QuestObjectiveTrackerMixin:
	OnBlockHeaderClick, the same on both clients): the chat link, the shift
	click, a complete auto-complete quest, Show on map, the menu with Blizzard's
	entries and strings but the gamepad's Share in chat. Everything here is
	called from the rows' scripts (rows.lua), built with the rows, so with the
	switch off none of it runs.

	Combat (.agents/taint.md, rule 14). A click handler of ours is addon code, so
	a Blizzard UI function it calls runs tainted: opening the map or the quest
	log (QuestMapFrame_OpenToQuestDetails, QuestUtil.OpenQuestDetails) and
	abandoning with its confirmation (QuestMapQuestOptions_AbandonQuest) are
	never called in combat: a left click focuses the quest instead, and the menu
	makes those entries disabled with "Out of combat only" (polled, so a menu
	open when combat starts greys out; each also checks again when clicked).
	Watch changes (C_QuestLog.AddQuestWatch and RemoveQuestWatch) are the same:
	the game fires QUEST_WATCH_LIST_CHANGED, a SynchronousEvent, inside the call,
	so Blizzard's concealed tracker, the quest map and the super track frame run
	their handlers in our tainted call chain (the tracker's MarkDirty is what
	rule 5 forbids from our code). They are out of combat only too: a Shift click
	in combat does nothing and says "Out of combat only"; Track quest and Stop
	tracking are disabled. What stays allowed in combat: focus
	(C_SuperTrack.SetSuperTrackedQuestID: SUPER_TRACKING_CHANGED is not
	synchronous), ShowQuestComplete and RemoveAutoQuestPopUp (the game's own
	functions, no Lua of Blizzard's), Share (two C calls) and Blizzard's two
	read-only helpers (QuestUtil.CanRemoveQuestWatch, which only reads
	C_PlayerInfo.IsPlayerNPERestricted, and the chat link's ChatFrameUtil.
	TryInsertQuestLinkForQuestID, which puts text in the edit box, as every
	addon's shift click does). That the game allows them in combat is an
	in-game check.

	The seams (plan: Experiment seams), each one function so an experiment's
	failure changes one constant: TR.ShowOnMapAllowed() (P5: may a left click
	open the map; read by the click, the menu, the tooltip's hint and the Left
	click setting's values), TR.QuestDetailsAllowed() and TR.AbandonAllowed()
	(P5 too: the same lasting-taint question for the details panel and the
	abandon confirmation; the menu entry goes when its constant is false) and
	TR.WatchChangeAllowed() (P6: does a watch change from our click leave lasting
	taint out of combat, and is it blocked in combat; today `not
	InCombatLockdown()`).
]]

TR.SHOW_ON_MAP = true
TR.QUEST_DETAILS = true
TR.ABANDON = true

local function OutOfCombat() return not InCombatLockdown() end

function TR.ShowOnMapAllowed()
	return TR.SHOW_ON_MAP and type(QuestMapFrame_OpenToQuestDetails) == 'function' or false
end

-- Whether the menu may offer Open quest details, and Abandon (P5, as Show on
-- map: the details panel and the abandon confirmation are Blizzard's UI Lua run
-- from our call, which may leave lasting taint).
function TR.QuestDetailsAllowed()
	return TR.QUEST_DETAILS and type(QuestUtil) == 'table' and type(QuestUtil.OpenQuestDetails) == 'function' or false
end

function TR.AbandonAllowed()
	return TR.ABANDON and type(QuestMapQuestOptions_AbandonQuest) == 'function' or false
end

-- Whether a click or menu entry may change the watch list now (P6): the game
-- runs Blizzard's tracker, map and super track handlers inside the call.
function TR.WatchChangeAllowed()
	return not InCombatLockdown()
end

-- The one place a quest is tracked or untracked: false for a change not made,
-- with the reason said in the game's error line (UIErrorsFrame, red, as
-- Blizzard's own refusal of a 26th watch). The limit's words are Blizzard's
-- (OBJECTIVES_WATCH_TOO_MANY, QuestMapQuestOptions_TrackQuest).
local OUT_OF_COMBAT = 'Out of combat only'

local function Say(text)
	if type(UIErrorsFrame) == 'table' and type(UIErrorsFrame.AddMessage) == 'function' then
		UIErrorsFrame:AddMessage(text, 1, 0.1, 0.1, 1)
	end
end

function TR.SetWatched(questID, on)
	if not TR.WatchChangeAllowed() then
		Say(OUT_OF_COMBAT)
		return false
	end
	if on then
		local limit = type(Constants) == 'table' and Constants.QuestWatchConsts and Constants.QuestWatchConsts.MAX_QUEST_WATCHES
		if limit and C_QuestLog.GetNumQuestWatches() >= limit then
			Say(type(OBJECTIVES_WATCH_TOO_MANY) == 'string' and OBJECTIVES_WATCH_TOO_MANY or "You can't track any more quests.")
			return false
		end
		C_QuestLog.AddQuestWatch(questID)
	else
		C_QuestLog.RemoveQuestWatch(questID)
	end
	return true
end

-- The Left click setting's choices: Show on map only while it is allowed.
function TR.LeftClickValues()
	local values = { focus = 'Focus' }
	if TR.ShowOnMapAllowed() then values.map = 'Show on map' end
	return values
end

-- The setting as it acts: 'map' or 'focus'. A saved 'map' reads as focus while
-- Show on map isn't allowed (the saved value is left as it is).
function TR.LeftClick()
	local value = TR.config.quests.left_click
	if value == 'map' and TR.ShowOnMapAllowed() then return 'map' end
	return 'focus'
end

-- The Left click row's own reset: its default as it acts (Focus where Show on
-- map isn't allowed, so the row shows no reset icon for a saved map that reads
-- as focus), writing the saved default when it resets.
function TR.LeftClickDefault()
	local base = TR.SettingDefault('quests', 'left_click')
	local function Acts(value)
		if value == 'map' and not TR.ShowOnMapAllowed() then return 'focus' end
		return value
	end
	return {
		differs = function() return TR.LeftClick() ~= Acts(base.value()) end,
		reset = base.reset,
		value = function() return Acts(base.value()) end,
	}
end

-- The last line of a quest's tooltip, naming the clicks. shift says what a
-- Shift-click does to this quest: 'untrack' (the default), 'track' (an
-- untracked zone quest) or 'none' (the new player experience forbids it).
function TR.ClickHint(leftClick, allowed, shift)
	if leftClick == 'map' and allowed then
		local text = 'Click: show on map (focus in combat).'
		if shift == 'track' then
			text = text .. ' Shift-click: track.'
		elseif shift ~= 'none' then
			text = text .. ' Shift-click: stop tracking.'
		end
		return text .. ' Right-click: more.'
	end
	return 'Click: focus.'
end

------------------------------------------------------------------ the click

-- What a click does, from the quest, the mouse button and the state, which the
-- click reads (OnQuestClick): { chat (a chat box took the quest's link),
-- modified (the Shift of QUESTWATCHTOGGLE), canUntrack (QuestUtil.
-- CanRemoveQuestWatch; nil is yes), combat, leftClick ('map' or 'focus') }.
-- Blizzard's order: the link first, then the menu for the right button, then
-- the modified click, a complete auto-complete quest, and the left click.
-- 'link' | 'untrack' | 'track' | 'complete' | 'map' | 'focus' | 'menu', or nil
-- for a click that does nothing (a quest the game won't let be untracked).
function TR.ClickAction(quest, button, state)
	if state.chat then return 'link' end
	if button == 'RightButton' then return 'menu' end
	if state.modified then
		-- An untracked quest (a zone's, with Show set to it) is tracked, ruling 9.
		if not quest.tracked then return 'track' end
		if state.canUntrack == false then return nil end
		return 'untrack'
	end
	if quest.auto and quest.complete then return 'complete' end
	if state.leftClick == 'map' and not state.combat and TR.ShowOnMapAllowed() then return 'map' end
	return 'focus'
end

-- The focus: the quest, or none (0) when it already is.
function TR:ToggleFocus(questID)
	if type(C_SuperTrack) ~= 'table' or type(C_SuperTrack.SetSuperTrackedQuestID) ~= 'function' then return end
	if C_SuperTrack.GetSuperTrackedQuestID() == questID then
		C_SuperTrack.SetSuperTrackedQuestID(0)
	else
		C_SuperTrack.SetSuperTrackedQuestID(questID)
	end
end

-- namespace[name](...) where the client has it, else nothing.
local function Call(namespace, name, ...)
	local fn = type(namespace) == 'table' and namespace[name] or nil
	if type(fn) == 'function' then return fn(...) end
end

-- A click on a quest row (its OnClick: left or right button up). Not the
-- player's scrolling: nothing here touches the scroll.
function TR:OnQuestClick(row, button)
	local quest = row and row.quest
	if not quest then return end
	local id = quest.id
	local state = { combat = InCombatLockdown() and true or false, leftClick = TR.LeftClick() }
	-- Blizzard's own first step, on either button: the quest's link into an open
	-- chat box (its Shift, CHATLINK, is checked inside).
	state.chat = ChatFrameUtil and Call(ChatFrameUtil, 'TryInsertQuestLinkForQuestID', id) and true or false
	if not state.chat and button ~= 'RightButton' then
		state.modified = Call(_G, 'IsModifiedClick', 'QUESTWATCHTOGGLE') and true or false
		if state.modified and quest.tracked and QuestUtil then
			local can = Call(QuestUtil, 'CanRemoveQuestWatch')
			if can ~= nil then state.canUntrack = can and true or false end
		end
	end
	local action = TR.ClickAction(quest, button, state)
	if action == 'untrack' then
		TR.SetWatched(id, false)
	elseif action == 'track' then
		TR.SetWatched(id, true)
	elseif action == 'complete' then
		-- Blizzard's order: the popup goes, then the turn-in opens (both the game's
		-- own functions, as the popups' click uses).
		Call(_G, 'RemoveAutoQuestPopUp', id)
		Call(_G, 'ShowQuestComplete', id)
		self:MarkDirty('POPUP')
	elseif action == 'map' then
		QuestMapFrame_OpenToQuestDetails(id)
	elseif action == 'focus' then
		if type(C_SuperTrack) == 'table' and type(C_SuperTrack.SetSuperTrackedQuestID) == 'function' then
			C_SuperTrack.SetSuperTrackedQuestID(id)
		end
	elseif action == 'menu' then
		self:OpenMenu(row)
	end
end

------------------------------------------------------------------ the menu

-- A string of the game's, or plain words where this client lacks it.
local function Str(name, fallback)
	local value = _G[name]
	if type(value) == 'string' and value ~= '' then return value end
	return fallback
end

-- The menu's entries for a quest, in Blizzard's order (the tracker's own menu
-- on both clients): { { kind = 'title' | 'button', text, enabled, tip, poll,
-- onClick } }. state = { combat } (the game's answer when omitted). An entry
-- that runs Blizzard's UI Lua or changes the watch list has a `poll` function
-- (true while it may run): enabled and tip are its answer now, with the tip
-- "Out of combat only" (ruling 19), and the menu polls it, so a menu open when
-- combat starts greys out; the click checks again. Blizzard's Share in chat, a
-- gamepad entry, is left out: this tracker has no gamepad mode. A secret title
-- is the title as it is.
function TR.MenuEntries(quest, state)
	local combat = state and state.combat
	if combat == nil then combat = InCombatLockdown() and true or false end
	local id = quest.id
	local entries = {}

	local function Add(text, onClick, poll)
		local entry = { kind = 'button', text = text, enabled = true, onClick = onClick }
		if poll then
			entry.poll = poll
			entry.enabled = not combat and poll() or false
			if combat or not entry.enabled then entry.enabled, entry.tip = false, OUT_OF_COMBAT end
			entry.onClick = function()
				if not poll() then return end
				onClick()
			end
		end
		entries[#entries + 1] = entry
	end

	entries[1] = { kind = 'title', text = quest.title }

	local focused = type(C_SuperTrack) == 'table' and type(C_SuperTrack.GetSuperTrackedQuestID) == 'function'
		and C_SuperTrack.GetSuperTrackedQuestID() == id
	if focused then
		Add(Str('STOP_SUPER_TRACK_QUEST', 'Remove Focus'), function() C_SuperTrack.SetSuperTrackedQuestID(0) end)
	else
		Add(Str('SUPER_TRACK_QUEST', 'Focus'), function() C_SuperTrack.SetSuperTrackedQuestID(id) end)
	end

	if TR.QuestDetailsAllowed() then
		-- Blizzard's own read of whether the details show is not made in combat.
		local showing = not combat and type(QuestUtil.IsShowingQuestDetails) == 'function'
			and QuestUtil.IsShowingQuestDetails(id)
		Add(showing and Str('OBJECTIVES_HIDE_VIEW_IN_QUESTLOG', 'Close Quest Details')
			or Str('OBJECTIVES_VIEW_IN_QUESTLOG', 'Open Quest Details'),
			function() QuestUtil.OpenQuestDetails(id) end, OutOfCombat)
	end

	if TR.ShowOnMapAllowed() then
		Add(Str('OBJECTIVES_SHOW_QUEST_MAP', 'Open Quest Map'), function() QuestMapFrame_OpenToQuestDetails(id) end, OutOfCombat)
	end

	if quest.tracked then
		local can = Call(QuestUtil, 'CanRemoveQuestWatch')
		if can == nil or can then
			Add(Str('OBJECTIVES_STOP_TRACKING', 'Untrack'), function() TR.SetWatched(id, false) end, TR.WatchChangeAllowed)
		end
	else
		-- A current-zone quest that isn't tracked (ruling 9): the quest log's own
		-- menu words (TRACK_QUEST).
		Add(Str('TRACK_QUEST', 'Track Quest'), function() TR.SetWatched(id, true) end, TR.WatchChangeAllowed)
	end

	-- Two C calls and nothing written (QuestUtil.ShareQuest), so allowed in combat.
	if type(QuestUtil) == 'table' and type(QuestUtil.ShareQuest) == 'function'
		and type(C_QuestLog.IsPushableQuest) == 'function' and C_QuestLog.IsPushableQuest(id)
		and type(IsInGroup) == 'function' and IsInGroup() then
		Add(Str('SHARE_QUEST', 'Share Quest'), function() QuestUtil.ShareQuest(id) end)
	end

	if TR.AbandonAllowed() then
		Add(Str('ABANDON_QUEST_ABBREV', 'Abandon'), function() QuestMapQuestOptions_AbandonQuest(id) end, OutOfCombat)
	end
	return entries
end

-- Opens the menu on a quest row with Blizzard's MenuUtil (both clients have
-- it), as the bags' slot menu does. Nothing opens for a row with no quest or
-- without MenuUtil.
function TR:OpenMenu(row)
	local quest = row and row.quest
	if not quest or type(MenuUtil) ~= 'table' or type(MenuUtil.CreateContextMenu) ~= 'function' then return end
	local entries = TR.MenuEntries(quest, { combat = InCombatLockdown() and true or false })
	MenuUtil.CreateContextMenu(row, function(_, root)
		for _, entry in ipairs(entries) do
			if entry.kind == 'title' then
				root:CreateTitle(entry.text)
			else
				local element = root:CreateButton(entry.text, entry.onClick)
				local poll = entry.poll
				if poll then
					-- Polled by the menu (Blizzard's SetEnabled takes a function), so it
					-- follows combat starting or ending while the menu is open.
					element:SetEnabled(poll)
					if type(element.SetTooltip) == 'function' then
						element:SetTooltip(function(tooltip)
							if not poll() then tooltip:SetText(OUT_OF_COMBAT) end
						end)
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------ tooltips

-- The tooltip's place: its top right 8 left of the row's top left, which is the
-- window's left edge (ruling 30; Blizzard's tracker puts its own the same way,
-- TOPRIGHT of the block at its TOPLEFT).
local function PlaceTooltip(owner, row)
	GameTooltip:SetOwner(owner, 'ANCHOR_NONE')
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', row, 'TOPLEFT', -L.PAD, 0)
end

-- A quest row's tooltip, with Tooltips on: the game's own quest tooltip (the
-- quest's link) with the party's progress when grouped, then what the clicks do,
-- in Text > Grey. Blizzard's tracker shows only the party's progress, and only
-- while grouped; the link is SaftUI's addition (design: Tooltips).
function TR:ShowRowTooltip(row)
	local quest = row and row.quest
	if not quest or not self.config.quests.tooltips then return end
	PlaceTooltip(row, row)
	local link = type(GetQuestLink) == 'function' and GetQuestLink(quest.id) or nil
	if link then
		GameTooltip:SetHyperlink(link)
	else
		GameTooltip:SetText(quest.title)
	end
	-- The party's progress, appended after the link (a tooltip data accessor,
	-- AppendInfo(getterName, ...), on both clients: SetQuestPartyProgress, like
	-- SetHyperlink, starts the tooltip over, and hides it with no data). Where the
	-- game lacks AppendInfo the line is left out.
	if type(IsInGroup) == 'function' and IsInGroup() and type(GameTooltip.AppendInfo) == 'function' then
		GameTooltip:AppendInfo('GetQuestPartyProgress', quest.id, true)
	end
	local shift = 'untrack'
	if not quest.tracked then
		shift = 'track'
	elseif Call(QuestUtil, 'CanRemoveQuestWatch') == false then
		shift = 'none'
	end
	local r, g, b = st.config.profile.colors.text.grey:GetRGB()
	GameTooltip:AddLine(TR.ClickHint(TR.LeftClick(), TR.ShowOnMapAllowed(), shift), r, g, b, true)
	GameTooltip:Show()
end

function TR:HideRowTooltip(row)
	if GameTooltip:IsOwned(row) then GameTooltip:Hide() end
end

-- The quest icon's tooltip: what its click does (an icon-only control has one).
function TR:ShowIconTooltip(button, row)
	if not row.quest then return end
	PlaceTooltip(button, row)
	local focused = type(C_SuperTrack) == 'table' and C_SuperTrack.GetSuperTrackedQuestID() == row.quest.id
	GameTooltip:SetText(focused and Str('STOP_SUPER_TRACK_QUEST', 'Remove Focus') or Str('SUPER_TRACK_QUEST', 'Focus'), 1, 1, 1)
	GameTooltip:Show()
end
