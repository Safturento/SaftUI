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

	Combat (.agents/taint.md). A click handler of ours is addon code, so a
	Blizzard UI function it calls runs tainted: opening the map or the quest
	log (QuestMapFrame_OpenToQuestDetails, QuestUtil.OpenQuestDetails), sharing
	(QuestUtil.ShareQuest) and abandoning with its confirmation
	(QuestMapQuestOptions_AbandonQuest) are never called in combat: a left click
	focuses the quest instead, and the menu makes those entries disabled with
	"Out of combat only" (each also checks again when clicked, for a combat that
	began after the menu opened). What stays allowed in combat: the game's own
	quest calls, which have no Lua of Blizzard's and no restriction in the
	generated documentation (C_SuperTrack.SetSuperTrackedQuestID,
	C_QuestLog.AddQuestWatch and RemoveQuestWatch, ShowQuestComplete,
	RemoveAutoQuestPopUp); Blizzard's two read-only helpers (QuestUtil.
	CanRemoveQuestWatch, which only reads C_PlayerInfo.IsPlayerNPERestricted;
	and the chat link's ChatFrameUtil.TryInsertQuestLinkForQuestID, which puts
	text in the edit box, as every addon's shift click does). That the game
	allows them in combat is an in-game check.

	TR.ShowOnMapAllowed() is the one function that holds whether a left click
	may open the map (experiment P5): the click, the menu, the tooltip's hint
	and the Left click setting's values all read it, so a failed experiment
	changes one constant, TR.SHOW_ON_MAP.
]]

TR.SHOW_ON_MAP = true

function TR.ShowOnMapAllowed()
	return TR.SHOW_ON_MAP and type(QuestMapFrame_OpenToQuestDetails) == 'function' or false
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

-- The last line of a quest's tooltip, naming the clicks.
function TR.ClickHint(leftClick, allowed)
	if leftClick == 'map' and allowed then
		return 'Click: show on map (focus in combat). Shift-click: stop tracking. Right-click: more.'
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
		C_QuestLog.RemoveQuestWatch(id)
	elseif action == 'track' then
		C_QuestLog.AddQuestWatch(id)
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

local OUT_OF_COMBAT = 'Out of combat only'

-- The menu's entries for a quest, in Blizzard's order (the tracker's own menu
-- on both clients): { { kind = 'title' | 'button', text, enabled, tip,
-- onClick } }. state = { combat } (the game's answer when omitted). The
-- entries that run Blizzard's UI Lua are disabled in combat with a tip
-- (ruling 19), and refuse to run if combat began after the menu opened.
-- Blizzard's Share in chat, a gamepad entry, is left out: this tracker has no
-- gamepad mode. A secret title is the title as it is.
function TR.MenuEntries(quest, state)
	local combat = state and state.combat
	if combat == nil then combat = InCombatLockdown() and true or false end
	local id = quest.id
	local entries = {}

	local function Add(text, onClick, runsBlizzardUI)
		local entry = { kind = 'button', text = text, enabled = true, onClick = onClick }
		if runsBlizzardUI then
			if combat then entry.enabled, entry.tip = false, OUT_OF_COMBAT end
			entry.onClick = function()
				if InCombatLockdown() then return end
				onClick()
			end
		end
		entries[#entries + 1] = entry
	end

	entries[1] = { kind = 'title', text = quest.title }

	local focused = type(C_SuperTrack) == 'table' and type(C_SuperTrack.GetSuperTrackedQuestID) == 'function'
		and C_SuperTrack.GetSuperTrackedQuestID() == id
	if focused then
		Add(Str('STOP_SUPER_TRACK_QUEST', 'Stop focusing'), function() C_SuperTrack.SetSuperTrackedQuestID(0) end)
	else
		Add(Str('SUPER_TRACK_QUEST', 'Focus'), function() C_SuperTrack.SetSuperTrackedQuestID(id) end)
	end

	if type(QuestUtil) == 'table' and type(QuestUtil.OpenQuestDetails) == 'function' then
		-- Blizzard's own read of whether the details show is not made in combat.
		local showing = not combat and type(QuestUtil.IsShowingQuestDetails) == 'function'
			and QuestUtil.IsShowingQuestDetails(id)
		Add(showing and Str('OBJECTIVES_HIDE_VIEW_IN_QUESTLOG', 'Hide quest details')
			or Str('OBJECTIVES_VIEW_IN_QUESTLOG', 'Open quest details'),
			function() QuestUtil.OpenQuestDetails(id) end, true)
	end

	if TR.ShowOnMapAllowed() then
		Add(Str('OBJECTIVES_SHOW_QUEST_MAP', 'Show on map'), function() QuestMapFrame_OpenToQuestDetails(id) end, true)
	end

	if quest.tracked then
		local can = Call(QuestUtil, 'CanRemoveQuestWatch')
		if can == nil or can then
			Add(Str('OBJECTIVES_STOP_TRACKING', 'Stop tracking'), function() C_QuestLog.RemoveQuestWatch(id) end)
		end
	else
		-- A current-zone quest that isn't tracked (ruling 9): the quest log's own
		-- menu words (TRACK_QUEST).
		Add(Str('TRACK_QUEST', 'Track quest'), function() C_QuestLog.AddQuestWatch(id) end)
	end

	if type(QuestUtil) == 'table' and type(QuestUtil.ShareQuest) == 'function'
		and C_QuestLog.IsPushableQuest(id) and IsInGroup() then
		Add(Str('SHARE_QUEST', 'Share quest'), function() QuestUtil.ShareQuest(id) end, true)
	end

	if type(QuestMapQuestOptions_AbandonQuest) == 'function' then
		Add(Str('ABANDON_QUEST_ABBREV', 'Abandon'), function() QuestMapQuestOptions_AbandonQuest(id) end, true)
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
				if entry.enabled == false then element:SetEnabled(false) end
				if entry.tip and type(element.SetTooltip) == 'function' then
					local tip = entry.tip
					element:SetTooltip(function(tooltip) tooltip:SetText(tip) end)
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
	if type(IsInGroup) == 'function' and IsInGroup() and type(GameTooltip.SetQuestPartyProgress) == 'function' then
		-- Its title omitted: the link above is the title.
		GameTooltip:SetQuestPartyProgress(quest.id, true)
	end
	local r, g, b = st.config.profile.colors.text.grey:GetRGB()
	GameTooltip:AddLine(TR.ClickHint(TR.LeftClick(), TR.ShowOnMapAllowed()), r, g, b, true)
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
	GameTooltip:SetText(focused and Str('STOP_SUPER_TRACK_QUEST', 'Stop focusing') or Str('SUPER_TRACK_QUEST', 'Focus'), 1, 1, 1)
	GameTooltip:Show()
end
