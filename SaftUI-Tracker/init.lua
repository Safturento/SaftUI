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
		st:Print("SaftUI's tracker changes after a reload.")
	end
	if not self.built then return end
	-- Each part of the tracker adds its own update below.
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
