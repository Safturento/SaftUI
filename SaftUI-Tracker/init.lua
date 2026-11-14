local st = SaftUI
local TR = st:NewModule('Tracker')
st.Tracker = TR

--[[
	SaftUI's own objective tracker. While the switch (tracker.enable, General)
	is off, which is its default, this addon makes no frame, hook, event, mover
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
	self:RegisterEvents()
	-- The first refresh, on the next frame like any other.
	self:MarkDirty('BUILD')
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
}
TR.UNIT_EVENTS = { UNIT_QUEST_LOG_CHANGED = 'player' }
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
		elseif not TR.CONDITIONAL_EVENTS[event] then
			frame:RegisterEvent(event)
		end
	end
	self.eventFrame = frame
end

function TR:OnEvent(event, ...)
	-- The game says a quest was just tracked: its row is scrolled into view
	-- once it's drawn, whatever refresh that is. A quest merely new to the
	-- tracker (the log arriving after login, a title that came late, a zone's
	-- untracked quests) is not that.
	if event == 'QUEST_WATCH_LIST_CHANGED' then
		local questID, added = ...
		if added == true and type(questID) == 'number' then
			self.trackedQuest, self.trackedAt = questID, GetTime()
		end
	end
	if event == 'BAG_UPDATE_COOLDOWN' then
		if self.RefreshCooldowns then self:RefreshCooldowns() end
		return
	end
	self:MarkDirty(event)
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
		self.pending = false
		self:Refresh()
	end)
end

-- Reads the quest log into the model and draws it: the model, the groups, the
-- entries, the layout, the rows, then each later stage where its file defines
-- it (the item buttons, the probes, the handover, the visibility).
function TR:Refresh()
	if not self.built then return end
	self.lastRefresh = GetTime()
	local model = TR.Model.Read(self.config.quests.show)
	self.model = model
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
	local entries = self:BuildEntries(model, groups)

	-- The list's width depends on whether it scrolls (the bar's room), which
	-- depends on its height: laid out at the last width, and again at the other
	-- when that was wrong.
	local metrics = self.metrics
	metrics.spacing = math.floor(config.quests.spacing + 0.5)
	metrics.icons = self:ShowsIcons()
	metrics.itemSize = config.items.size
	metrics.dash = self:DashWidth()
	local header, collapsed, max = config.header and true or false, self:IsCollapsed(), self:MaxHeight()
	local room = self.barRoom or 0
	local placed, height
	for _ = 1, 2 do
		metrics.width = self:RowsWidth(room)
		placed, height = Layout.Rows(entries, metrics, self.measureText, self.placed)
		local windowHeight = Layout.WindowHeight(height, { header = header, collapsed = collapsed, max = max })
		local scrolls = not collapsed and height > Layout.ViewHeight(windowHeight, header)
		local needed = scrolls and math.floor(st:ScrollBarRoom(self.scroll) + 0.5) or 0
		if needed == room then break end
		room = needed
	end
	self.barRoom = room
	self.rowWidth = metrics.width

	self:DrawRows(entries, placed)
	self:SetContentHeight(height)
	self:KeepInView(entries, placed)

	-- The stages of the later tasks, each once its file defines it.
	if self.RefreshItems then self:RefreshItems() end
	if self.RunProbes then self:RunProbes() end
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
	if self.trackedQuest then
		if now - self.trackedAt > TR.TRACK_WAIT then
			self.trackedQuest = nil
		else
			target = self.trackedQuest
		end
	end
	if model.focused ~= self.lastFocused then
		self.lastFocused = model.focused
		if model.focused then target = model.focused end
	end
	if not target or self:IsCollapsed() or self:IsScrollLocked() then return end
	for index, entry in ipairs(entries) do
		if entry.quest and entry.quest.id == target then
			-- Drawn: the request is used, whether or not the list may move now.
			if target == self.trackedQuest then self.trackedQuest = nil end
			if self:IsHovered() or (self.lastUserScroll and now - self.lastUserScroll < TR.SCROLL_QUIET) then return end
			local p = placed[index]
			self:ScrollTo(TR.Layout.IntoView(self:GetScroll(), p.y, p.height, self:ViewHeight(), self.scrollRange or 0))
			return
		end
	end
end
