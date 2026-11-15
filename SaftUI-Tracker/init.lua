local st = SaftUI
local TR = st:NewModule('Tracker')
st.Tracker = TR

--[[
	SaftUI's own objective tracker. While the switch (tracker.enable, General)
	is off, this addon makes no frame, hook, event, mover
	or binding change, and Blizzard's tracker, its skin and its mover behave as
	they do without it.

	The switch is read once, at login (TR:IsOn): turning it on or off in /sui
	asks for a reload, and nothing is built or torn down before it.
]]

TR.NEAREST_COMMAND = 'CLICK SaftUITrackerNearestItem:LeftButton'

-- Other quest tracker addons SaftUI stands down for, in the order they're
-- named to the user: addon is the folder C_AddOns.IsAddOnLoaded knows it by,
-- label the name shown.
TR.TRACKER_ADDONS = {
	{ addon = '!KalielsTracker', label = "Kaliel's Tracker" },
	{ addon = 'EQObjectiveTracker', label = 'EQ Objective Tracker' },
	{ addon = 'KaLiQuest', label = 'KaLi Quest' },
	{ addon = 'AuraQuestor', label = 'Aura Questor' },
	{ addon = 'ForeverQuestTracker', label = 'ForeverQuestTracker' },
}

-- The name of the first of TR.TRACKER_ADDONS that's loaded, or nil for none.
function TR:TrackerAddon()
	for _, entry in ipairs(TR.TRACKER_ADDONS) do
		if C_AddOns.IsAddOnLoaded(entry.addon) then return entry.label end
	end
end

-- The switch's value in the profile, whatever the session decided.
local function ProfileEnable()
	local config = st.config.profile and st.config.profile.tracker
	return config and config.enable and true or false
end

-- Whether SaftUI's tracker is on for this session: the switch on and no other
-- tracker addon loaded. It answers once, on the first call, and the same all
-- session: Misc's objective tracker code may ask before TR:OnEnable runs.
function TR:IsOn()
	if self.latched == nil then
		self.sessionEnable = ProfileEnable()
		self.latched = self.sessionEnable and not self:TrackerAddon() or false
	end
	return self.latched
end

function TR:OnEnable()
	st:BindModuleConfig(self, 'tracker')
	if not self:IsOn() then return end
	self:Build()
end

-- Makes the tracker, once. Each part of it adds its builder here.
function TR:Build()
	if self.built then return end
	self.built = true
	self:BuildWindow()
	self:BuildRows()
	self:BuildItems()
	self:BuildNearest()
	self:RegisterEvents()
	-- The sections' probes (probes.lua) and the handover's state, which a /reload
	-- always starts from own: SaftUI's tracker shows, Blizzard's is concealed.
	self.handoverState = 'own'
	self:BuildProbes()
	-- Blizzard's tracker goes off screen (blizzard.lua), once the window is there
	-- for the y it hides at; its modules' layouts are watched.
	self:SetupBlizzard()
	-- The first probe pass, on the next frame.
	self:RunProbes()
	-- The fading and hiding rules from the start, so a window a rule hides never
	-- shows for a frame.
	self:ApplyVisibility()
	-- The first refresh, on the next frame like any other.
	self:MarkDirty('BUILD')
end

-- A shared font or a font setting changed (st:FontsChanged: the Fonts tab, a
-- profile update): the rows reflow at once. A profile change marks it once; the
-- marks fold into one refresh through the throttle.
function TR:OnFontsChanged()
	if TR.model then TR:MarkDirty('FONTS') end
end

-- The switch was just saved from /sui and the player is being asked about a
-- reload there: that value is already said, so a later profile or theme
-- change must not say it again.
function TR:SwitchSaved(value)
	self:IsOn()
	self.config.enable = value
	if value == self.sessionEnable then
		self.warned = nil
	else
		self.warned = value
	end
end

-- A profile change, or a theme change (Config:UpdateConfig runs it on both).
-- The switch is read once, so a profile whose switch differs from the
-- session's says so in chat, once per value: a theme change must not repeat it.
function TR:UpdateConfig()
	local enable = ProfileEnable()
	self:IsOn() -- latches the session's value, should nothing have asked yet
	if enable == self.sessionEnable then
		self.warned = nil
	elseif enable ~= self.warned then
		self.warned = enable
		local addon = self:TrackerAddon()
		if addon then
			st:Print(("SaftUI's tracker stands down for %s, so this changes nothing until that addon is off."):format(addon))
		else
			st:Print("SaftUI's tracker changes after a reload.")
		end
	end
	if not self.built then return end
	self:ApplyHolder()
	self:DrawWindow()
	self:DrawRowsLook()
	-- The holder or the window may have moved: Blizzard's tracker goes where
	-- it is meant to be (concealed, or at the handover's place), no write if
	-- it's there already.
	self:PlaceBlizzard(self.blizzardWhere)
	-- The nearest button's holder: its size and spot (in combat, waiting for its
	-- end); the button itself follows in the refresh below.
	self:PlaceNearest()
	-- A new mode (a setting, a profile switch) is handled here, whether or not a
	-- refresh follows.
	self:UpdateHandover()
	-- The fade and the hide rules follow the settings (the Visibility tab).
	self:ApplyVisibility()
	-- Each part of the tracker adds its own update below. The rows are read and
	-- drawn again once a first refresh has run (the build's own is on its way).
	if self.model then self:Refresh() end
end

-- A theme recolor or a change of a profile color: what each part of the tracker
-- colors itself is put back. The one entry point of the module (a second
-- definition in another file would silently replace this one): each part adds
-- its own call here. Runs while the switch is off too (st:ColorsChanged calls
-- every module), so each part does nothing until it exists.
function TR:OnColorsChanged(group)
	if not self.built then return end
	self:ColorWindow()
	self:ColorRows(group)
	self:ColorItems()
	self:ColorNearest()
end

-- What the tracker keeps per character, in st.config.char.tracker: each zone
-- group's collapsed state, and the whole tracker's.
function TR:CharData()
	local char = st.config.char
	local data = char.tracker
	if type(data) ~= 'table' then
		data = {}
		char.tracker = data
	end
	if type(data.zones) ~= 'table' then data.zones = {} end
	if data.collapsed == nil then data.collapsed = false end
	return data
end

-- A setting's own reset, for an option's `default` field. group is nil for
-- General's keys, else 'quests', 'items', 'visibility' or 'blizzard'. It
-- compares against st.defaults.tracker; reset writes a copy of the default,
-- and both the reset and the change after it run TR:UpdateConfig.
local function DeepEqual(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
	for key, value in pairs(a) do
		if not DeepEqual(value, b[key]) then return false end
	end
	for key in pairs(b) do
		if a[key] == nil then return false end
	end
	return true
end

local function DeepCopy(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for key, item in pairs(value) do copy[key] = DeepCopy(item) end
	return copy
end

function TR.SettingDefault(group, key)
	local function Config()
		local config = st.config.profile.tracker
		return group and config[group] or config
	end
	local function Default()
		local defaults = st.defaults.tracker
		if group then return defaults[group][key] end
		return defaults[key]
	end
	return {
		differs = function() return not DeepEqual(Config()[key], Default()) end,
		reset = function()
			Config()[key] = DeepCopy(Default())
			TR:UpdateConfig()
		end,
		value = function() return Default() end,
	}
end

------------------------------------------------------------------ events and the refresh

-- The game's events that mark the quest list dirty (design: "Events and the
-- refresh"). PLAYER_MONEY is registered only while a quest needs more money
-- than the player has (TR:UpdateMoneyEvent), UNIT_QUEST_LOG_CHANGED for the
-- player only; BAG_UPDATE_COOLDOWN is for the item buttons' cooldowns, which
-- Task 8 gives TR:RefreshCooldowns (it refreshes nothing else).
TR.EVENTS = {
	'QUEST_LOG_UPDATE', 'QUEST_WATCH_LIST_CHANGED', 'QUEST_WATCH_UPDATE', 'QUEST_ACCEPTED',
	'QUEST_REMOVED', 'QUEST_TURNED_IN', 'QUEST_AUTOCOMPLETE', 'QUEST_POI_UPDATE',
	'QUEST_LOG_CRITERIA_UPDATE', 'UNIT_QUEST_LOG_CHANGED', 'SUPER_TRACKING_CHANGED',
	'SUPER_TRACKING_PATH_UPDATED', 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA',
	'PLAYER_ENTERING_WORLD', 'PLAYER_LEVEL_UP', 'PLAYER_MONEY', 'BAG_UPDATE_DELAYED',
	'BAG_UPDATE_COOLDOWN', 'PLAYER_REGEN_ENABLED', 'PLAYER_REGEN_DISABLED',
	-- Not in the design's first list (settled 2026-11-14): QUEST_DETAIL, in whose
	-- handler Blizzard adds the offer popup of a quest-starting item before it
	-- closes the quest frame, and QUEST_DATA_LOAD_RESULT, when a quest's data
	-- the log was missing (its title, a popup's) arrives.
	'QUEST_DETAIL', 'QUEST_DATA_LOAD_RESULT',
}
-- The events the fading and hiding rules wait for (visibility.lua): a boss fight's
-- start and end and a Mythic+ key's start, end and reset. They apply the rules and
-- mark nothing dirty. An event a client doesn't have is left out like the others.
TR.VISIBILITY_EVENTS = {
	'ENCOUNTER_START', 'ENCOUNTER_END', 'CHALLENGE_MODE_START', 'CHALLENGE_MODE_COMPLETED', 'CHALLENGE_MODE_RESET',
}
TR.VISIBILITY_EVENT_SET = {}
for _, event in ipairs(TR.VISIBILITY_EVENTS) do TR.VISIBILITY_EVENT_SET[event] = true end
TR.UNIT_EVENTS = { UNIT_QUEST_LOG_CHANGED = 'player' }
-- The set of the above, for the events the probes share.
TR.EVENT_SET = {}
for _, event in ipairs(TR.EVENTS) do TR.EVENT_SET[event] = true end
TR.CONDITIONAL_EVENTS = { PLAYER_MONEY = true }

-- The events come many times a second while killing: the list refreshes at most
-- this often (seconds).
TR.REFRESH_GAP = 0.1

-- The module's one event frame. Only called by TR:Build, so with the switch off
-- no event is registered.
function TR:RegisterEvents()
	local frame = CreateFrame('Frame')
	frame:SetScript('OnEvent', function(_, event, ...) TR:OnEvent(event, ...) end)
	for _, event in ipairs(TR.EVENTS) do
		local unit = TR.UNIT_EVENTS[event]
		if unit then
			frame:RegisterUnitEvent(event, unit)
		elseif not TR.CONDITIONAL_EVENTS[event]
			and not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event)) then
			-- (an event a client doesn't have is left out, not an error)
			frame:RegisterEvent(event)
		end
	end
	-- The probe events (probes.lua) the list above doesn't have: they ask for a probe
	-- pass and mark nothing dirty.
	for _, event in ipairs(TR.PROBE_EVENT_LIST or {}) do
		if not TR.EVENT_SET[event]
			and not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event)) then
			frame:RegisterEvent(event)
		end
	end
	for _, event in ipairs(TR.VISIBILITY_EVENTS) do
		if not (TR.PROBE_EVENTS and TR.PROBE_EVENTS[event]) and not TR.EVENT_SET[event]
			and not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event)) then
			frame:RegisterEvent(event)
		end
	end
	self.eventFrame = frame
end

function TR:OnEvent(event, ...)
	-- A boss fight or a key: the fading and hiding rules (visibility.lua).
	if TR.VISIBILITY_EVENT_SET[event] then
		self:OnVisibilityEvent(event)
		-- (the Mythic+ events are the probes' too)
		if not (TR.PROBE_EVENTS and TR.PROBE_EVENTS[event]) then return end
	end
	-- The probes' events (probes.lua): a pass on the next frame. One that only the
	-- probes listen to marks nothing dirty.
	if TR.PROBE_EVENTS and TR.PROBE_EVENTS[event] then
		self:RunProbes()
		if not TR.EVENT_SET[event] then return end
	end
	-- The game says a quest was just tracked: its row is scrolled into view
	-- once it's drawn, whatever refresh that is. A quest merely new to the
	-- tracker (the log arriving after login, a title that came late, a zone's
	-- untracked quests) is not that.
	if event == 'QUEST_WATCH_LIST_CHANGED' then
		local questID, added = ...
		self:NoteTracked(questID, added)
	elseif event == 'QUEST_DATA_LOAD_RESULT' then
		-- Fires for every quest the game loads (retail's world map loads many):
		-- only one the tracker shows, a popup's, or one waiting for its data
		-- is worth a refresh.
		local questID = ...
		if self.knownIds and not self.knownIds[questID] then return end
	end
	if event == 'BAG_UPDATE_COOLDOWN' then
		self:OnCooldownEvent()
		return
	end
	-- Combat starting or ending changes what the list may do (the scroll lock),
	-- which the refresh that follows draws; the buttons themselves are the queued
	-- pass's and the refresh's. In the game lockdown begins only after this
	-- event's handlers, so a refresh already waiting runs now, the last moment
	-- the buttons can still be set (the harness starts lockdown first).
	if event == 'PLAYER_REGEN_DISABLED' then
		-- The game's word for combat, until the next event: lockdown begins after
		-- this one's handlers (the fading rules read it, visibility.lua).
		self.combatNow = true
		local flushed = false
		if self.pending then
			self.pending = false
			self:Refresh()
			flushed = true
		end
		-- A probe pass waiting runs now too, while SaftUI's secure buttons can still
		-- be hidden for a handover that is needed (the pass's timer finds it done).
		if self.probePending then
			self.probePending = false
			self:ProbePass()
			flushed = true
		end
		self:ApplyVisibility()
		if flushed then
			-- Nothing runs after lockdown begins unless asked: the next frame draws what
			-- combat changes (the dimming, the scroll lock's tooltip and bar).
			C_Timer.After(0, function() self:RefreshItems() end)
			return -- (a refresh run here has read everything this event would mark; with only a probe pass run, the items pass above draws the rest)
		end
	elseif event == 'PLAYER_REGEN_ENABLED' then
		self.combatNow = false
		self:UpdateScrollLock()
		self:ApplyVisibility()
	elseif event == 'PLAYER_ENTERING_WORLD' then
		-- A loading screen: what the fight and combat events said is stale, the game's
		-- own answers stand (an instance, a key, a fight in progress after a /reload).
		self.combatNow, self.encounterNow = nil, nil
		self:ApplyVisibility()
	end
	self:MarkDirty(event)
end

-- BAG_UPDATE_COOLDOWN comes with every global cooldown in a fight. It only draws
-- (no refresh), and through a gap of its own, the refresh's length: the first one
-- after a quiet gap draws at once, those inside it are one draw when the gap ends.
function TR:OnCooldownEvent()
	if not self.built or self.cooldownPending then return end
	local wait = self.lastCooldown and (TR.REFRESH_GAP - (GetTime() - self.lastCooldown)) or 0
	if wait > 0 then
		self.cooldownPending = true
		self.cooldownDraw = self.cooldownDraw or function()
			self.cooldownPending = false
			self:DrawCooldowns()
		end
		C_Timer.After(wait, self.cooldownDraw)
		return
	end
	self:DrawCooldowns()
end

function TR:DrawCooldowns()
	self.lastCooldown = GetTime()
	self:RefreshCooldowns()
	self:RefreshNearestCooldown()
end

-- The quests the game just said were tracked, in order, each waiting for its row
-- to be drawn; an untrack takes its quest off. Two tracks inside one throttle
-- gap both keep their rows (the rows come from the model), and the scroll goes
-- to the last one still wanted.
function TR:NoteTracked(questID, added)
	if type(questID) ~= 'number' then return end
	local list = self.trackedQuests
	if not list then
		list = {}
		self.trackedQuests = list
	end
	for index = #list, 1, -1 do
		if list[index].id == questID then table.remove(list, index) end
	end
	if added == true then list[#list + 1] = { id = questID, at = GetTime() } end
end

-- PLAYER_MONEY, while a quest needs more money than the player has.
function TR:UpdateMoneyEvent(model)
	local needed = false
	for _, quest in ipairs(model.quests) do
		if quest.money then
			needed = true
			break
		end
	end
	if needed ~= (self.moneyEvent or false) then
		self.moneyEvent = needed
		if needed then
			self.eventFrame:RegisterEvent('PLAYER_MONEY')
		else
			self.eventFrame:UnregisterEvent('PLAYER_MONEY')
		end
	end
end

-- Something changed: the list is read and drawn again, once, however many marks
-- come before it. Every kind of mark goes through one throttle (the
-- controller's ruling of 2026-11-14): the first one after a quiet gap refreshes
-- on the next frame (C_Timer.After(0)), so a single change shows at once; one
-- within TR.REFRESH_GAP of the last refresh waits for the end of that gap, and
-- every mark that comes while a refresh is pending is folded into it, never
-- pushing it back. A steady stream refreshes at most ten times a second and is
-- never starved. Nothing runs before the tracker is built.
function TR:MarkDirty(event)
	if not self.built or self.pending then return end
	local delay = 0
	if self.lastRefresh then
		delay = math.max(0, TR.REFRESH_GAP - (GetTime() - self.lastRefresh))
	end
	self.pending = true
	C_Timer.After(delay, function()
		-- (a refresh that already ran for this mark, at the start of combat, left
		-- nothing pending)
		if not self.pending then return end
		self.pending = false
		self:Refresh()
	end)
end

-- Reads the quest log into the model and draws it: the model, the groups, the
-- entries, the layout, the rows, then each later stage where its file defines
-- it (the item buttons, the handover, the visibility; the probes run on their own events).
function TR:Refresh()
	if not self.built then return end
	self.lastRefresh = GetTime()
	local model = TR.Model.Read(self.config.quests.show)
	self.model = model
	local known = self.knownIds
	if not known then
		known = {}
		self.knownIds = known
	end
	for id in pairs(known) do known[id] = nil end
	for _, quest in ipairs(model.quests) do known[quest.id] = true end
	for _, popup in ipairs(model.popups) do known[popup.id] = true end
	for id in pairs(model.waiting) do known[id] = true end
	self:UpdateMoneyEvent(model)
	self:UpdateHeader(model)
	self:Redraw()
end

-- The width the rows are laid out at: the window's, less padding, and the scroll
-- bar's room while the list scrolls.
function TR:RowsWidth(room)
	return TR.Layout.ChildWidth(math.floor(self.config.width + 0.5), room)
end

-- Everything after the read, from the model already read: the groups, entries,
-- layout and rows, the window's height and scroll. What a click on a zone
-- header runs, and what a refresh ends with.
function TR:Redraw()
	if not self.built then return end
	if not self.model then return self:Refresh() end
	local model, config = self.model, self.config
	local Layout = TR.Layout
	self:CheckFonts()

	local groups = TR.Groups.Build(model.quests, config.quests, model.zoneNames, self:CharData().zones)
	local empty = #model.quests == 0 and #model.popups == 0
	self:SetPopups(#model.popups > 0)
	self:SetEmpty(empty)
	-- A collapsed tracker shows only its header (the count, set by the refresh):
	-- its rows are drawn once when it opens.
	if self:IsCollapsed() then
		self.rowsStale = true
		-- Opening scrolls to nothing the tracker was told while it was closed.
		self.lastFocused = model.focused
		self.trackedQuests = nil
		self:SetContentHeight(self.contentHeight or 0)
		self:RunStages()
		return
	end
	self.rowsStale = false
	local entries = self:BuildEntries(model, groups)

	-- The list's width depends on whether it scrolls (the bar's room), which
	-- depends on its height: laid out at the last width, and again at the other
	-- when that was wrong.
	local metrics = self.metrics
	metrics.spacing = math.floor(config.quests.spacing + 0.5)
	metrics.icons = self:ShowsIcons()
	metrics.itemSize = config.items.size
	metrics.dash = self:DashWidth()
	metrics.zone = self:ZoneHeight()
	local header, collapsed, max = config.header and true or false, self:IsCollapsed(), self:MaxHeight()
	local room = self.barRoom or 0
	local placed, height
	for _ = 1, 2 do
		metrics.width = self:RowsWidth(room)
		placed, height = Layout.Rows(entries, metrics, self.measureText, self.placed)
		local headerHeight = self:HeaderHeight()
		local windowHeight = Layout.WindowHeight(height, { header = header, collapsed = collapsed, max = max, headerHeight = headerHeight })
		local scrolls = not collapsed and height > Layout.ViewHeight(windowHeight, header, headerHeight)
		local needed = scrolls and math.floor(st:ScrollBarRoom(self.scroll) + 0.5) or 0
		if needed == room then break end
		room = needed
	end
	self.barRoom = room
	self.rowWidth = metrics.width

	self:DrawRows(entries, placed)
	self:SetContentHeight(height)
	self:KeepInView(entries, placed)

	self:RunStages()
end

-- The stages of the later tasks, each once its file defines it (the item
-- buttons, the handover, the visibility). The probes run on their own events and
-- after a module's layout (TR:RunProbes), not on every refresh; the handover
-- reads what they found, and follows what a refresh changes (the item buttons to
-- show, the column's width, the window).
function TR:RunStages()
	self:RefreshItems()
	self:RefreshNearest()
	if self.UpdateHandover then self:UpdateHandover() end
	if self.ApplyVisibility then self:ApplyVisibility() end
end

-- How long a request to scroll a quest into view waits for its row, and how long
-- after the player's own scrolling the list is left alone (seconds).
TR.TRACK_WAIT = 5
TR.SCROLL_QUIET = 3

-- The list keeps the player's place across a refresh, except that the focused
-- quest (when the focus changed) or a quest the game just said was tracked
-- (QUEST_WATCH_LIST_CHANGED with added) is scrolled into view, out of combat or
-- while scrolling isn't locked, never while the mouse is over the tracker or
-- within TR.SCROLL_QUIET of the player's own scrolling, and never while the
-- window is collapsed.
function TR:KeepInView(entries, placed)
	local model = self.model
	local now = GetTime()
	local target
	local tracked = self.trackedQuests
	if tracked then
		for index = #tracked, 1, -1 do
			if now - tracked[index].at > TR.TRACK_WAIT then table.remove(tracked, index) end
		end
		if #tracked > 0 then target = tracked[#tracked].id end
	end
	if model.focused ~= self.lastFocused then
		self.lastFocused = model.focused
		if model.focused then target = model.focused end
	end
	if not target or self:IsCollapsed() or self:IsScrollLocked() then return end
	for index, entry in ipairs(entries) do
		if entry.quest and entry.quest.id == target then
			-- Drawn: the requests are used, whether or not the list may move now.
			if tracked and target == (tracked[#tracked] and tracked[#tracked].id) then
				for index = #tracked, 1, -1 do tracked[index] = nil end
			end
			if self:IsHovered() or (self.lastUserScroll and now - self.lastUserScroll < TR.SCROLL_QUIET) then return end
			local p = placed[index]
			self:ScrollTo(TR.Layout.IntoView(self:GetScroll(), p.y, p.height, self:ViewHeight(), self.scrollRange or 0))
			return
		end
	end
end
