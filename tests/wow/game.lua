--[[
	The game's API that isn't about widgets (widgets.lua has those), and
	`stub`, the test controls for the stubbed world.

	Tests set stub's fields to put the game in a state, and the API below
	reports them. widgets.lua adds its helpers to the same table (stub.state,
	stub.fire_event, stub.fire_script).
]]

stub = {
	-- GetBuildInfo's interface number. 16001 is WoW Forever, the client the
	-- user plays. constants.lua reads it when the shell loads, so a test of
	-- another client sets it and loads constants.lua again.
	interface = 16001,
	-- GetPhysicalScreenSize, in physical pixels. UIParent's size follows it
	-- (and UIParent's scale), as in game.
	screen_width = 1920,
	screen_height = 1080,
	in_combat = false, -- InCombatLockdown
	cursor_x = 0, -- GetCursorPosition, in screen units (UIParent's units times its scale)
	cursor_y = 0,
	time = 0, -- GetTime, in seconds
	epoch = 1800000000, -- time(), in seconds since 1970
	shift_down = false, -- IsShiftKeyDown
	ctrl_down = false, -- IsControlKeyDown
	alt_down = false, -- IsAltKeyDown
	mouse_buttons = {}, -- IsMouseButtonDown: a set, e.g. stub.mouse_buttons.LeftButton = true
	loaded_addons = {}, -- C_AddOns.IsAddOnLoaded: a set, e.g. stub.loaded_addons.RXPGuides = true
	-- The player's experience: GetMaxPlayerLevel, UnitLevel('player'), UnitXP,
	-- UnitXPMax and GetXPExhaustion (rested experience; nil for none).
	max_level = 80,
	level = 20,
	xp = 450,
	xp_max = 1000,
	rested_xp = nil,
	-- Units other than the player, by unit token (e.g. stub.units.target), for
	-- the unit API below. Each is a table of:
	--   name, level, class (the class token, e.g. 'MAGE'), classification
	--   ('normal', 'rare', 'rareelite', 'elite', 'worldboss', ...; 'normal'
	--   if nil), reaction (UnitReaction between it and the player, 1 hated to
	--   8 exalted), player (true for a player character), controlled (true
	--   for a unit a player controls, e.g. a pet; players count without it)
	--   and party_ai (true for a party follower, UnitInPartyIsAI).
	-- A unit not listed doesn't exist, so the API gives nil for it.
	units = {},
	-- Where the player is, for the map and zone API below (C_Map, C_PvP,
	-- IsInInstance, GetInstanceInfo, GetDifficultyInfo, GetZoneText):
	--   maps: the game's maps by uiMapID, each { name, mapType (an
	--     Enum.UIMapType), parentMapID, levels = { min, max } (a map without
	--     them gives the game's 0s), area = { left, top, right, bottom }: where
	--     it sits on its parent map, in the parent's 0-1 coordinates (a map
	--     without one is never found by position) };
	--   player_map: C_Map.GetBestMapForUnit('player'); nil for none, as during
	--     a loading screen;
	--   pvp: C_PvP.GetZonePVPInfo's pvpType ('friendly', 'hostile', 'contested',
	--     'sanctuary', 'arena', 'combat'; nil for none), isSubZonePvP and
	--     factionName;
	--   instance: nil outside an instance, else { name, type ('party', 'raid',
	--     'pvp', 'arena', 'scenario'), difficulty_id, difficulty_name,
	--     max_players };
	--   zone_text, subzone_text: GetZoneText and GetSubZoneText.
	maps = {},
	player_map = nil,
	pvp = { type = nil, subzone = false, faction = nil },
	instance = nil,
	zone_text = '',
	subzone_text = '',
}

-- Only the interface number means anything here.
function GetBuildInfo()
	return '0.0.0', '0', 'Jan 1 2026', stub.interface
end

function GetLocale() return 'enUS' end
function GetPhysicalScreenSize() return stub.screen_width, stub.screen_height end
function InCombatLockdown() return stub.in_combat end
function IsMouseButtonDown(button) return stub.mouse_buttons[button or 'LeftButton'] == true end
function GetCursorPosition() return stub.cursor_x, stub.cursor_y end
function GetTime() return stub.time end
-- WoW's time(): the clock, as seconds since 1970. Only the no-argument form
-- exists here; the table form (a date to seconds) errors until a test needs it.
function time(date)
	if date ~= nil then error('time(table) is not stubbed', 2) end
	return stub.epoch
end
function IsShiftKeyDown() return stub.shift_down end
function IsControlKeyDown() return stub.ctrl_down end
function IsAltKeyDown() return stub.alt_down end
function IsModifierKeyDown() return (stub.shift_down or stub.ctrl_down or stub.alt_down) and true or false end
-- Returns loaded and finished loading, which are the same here.
C_AddOns = {
	IsAddOnLoaded = function(name)
		if type(name) ~= 'string' and type(name) ~= 'number' then
			error('Usage: C_AddOns.IsAddOnLoaded(name)', 2)
		end
		local loaded = stub.loaded_addons[name] == true
		return loaded, loaded
	end,
}

-- GetCurrentKeyBoardFocus (the edit box that has focus) is in widgets.lua, with EditBox:SetFocus.

-- The player: a human warrior named Tester on Testrealm. Other units are
-- stub.units'; one not there doesn't exist, so it gives nil, as the game does
-- for a unit that isn't there.
local function OtherUnit(unit) return unit ~= 'player' and stub.units[unit] or nil end
function UnitName(unit)
	if unit == 'player' then return 'Tester', nil end
	local other = OtherUnit(unit)
	if other then return other.name, nil end
end
function UnitClass(unit)
	if unit == 'player' then return 'Warrior', 'WARRIOR', 1 end
	-- Another unit's class token stands for its name too.
	local other = OtherUnit(unit)
	if other then return other.class, other.class end
end
function UnitRace(unit)
	if unit == 'player' then return 'Human', 'Human', 1 end
end
function UnitFactionGroup(unit)
	if unit == 'player' then return 'Alliance', 'Alliance' end
end
function GetRealmName() return 'Testrealm' end
-- The region the client is on: 1 is the US, the first in the game's list
-- (US, KR, EU, TW, CN). AceDB-3.0 reads both when it loads.
function GetCurrentRegion() return 1 end
function GetCurrentRegionName() return 'US' end

-- Experience. The player's level is stub.level, another unit's its stub.units level.
function GetMaxPlayerLevel() return stub.max_level end
function UnitLevel(unit)
	if unit == 'player' then return stub.level end
	local other = OtherUnit(unit)
	if other then return other.level end
end
-- The highest level there is: GetMaxPlayerLevel's.
function GetMaxLevelForLatestExpansion() return stub.max_level end
function UnitClassification(unit)
	if unit == 'player' then return 'normal' end
	local other = OtherUnit(unit)
	if other then return other.classification or 'normal' end
end
function UnitIsPlayer(unit)
	if unit == 'player' then return true end
	local other = OtherUnit(unit)
	return other and other.player and true or false
end
function UnitPlayerControlled(unit)
	if unit == 'player' then return true end
	local other = OtherUnit(unit)
	return other and (other.player or other.controlled) and true or false
end
function UnitInPartyIsAI(unit)
	local other = OtherUnit(unit)
	return other and other.party_ai and true or false
end
-- Between a stub.units unit and the player (either way round): its reaction.
-- No other pair is stubbed, so it errors rather than guess the game's answer.
function UnitReaction(unit, otherUnit)
	local other = (otherUnit == 'player' and OtherUnit(unit)) or (unit == 'player' and OtherUnit(otherUnit))
	if other then return other.reaction end
	if not (OtherUnit(unit) or unit == 'player') or not (OtherUnit(otherUnit) or otherUnit == 'player') then return nil end
	error(('UnitReaction(%s, %s) is not stubbed: only a stub.units unit and the player'):format(tostring(unit), tostring(otherUnit)), 2)
end
function UnitXP(unit)
	if unit == 'player' then return stub.xp end
end
function UnitXPMax(unit)
	if unit == 'player' then return stub.xp_max end
end
function GetXPExhaustion() return stub.rested_xp end

-- Reputation: no faction is watched.
C_Reputation = {
	GetWatchedFactionData = function() return nil end,
}

-- Maps (MapDocumentation.lua), from stub.maps. Each call gives a new
-- UiMapDetails table, as the game's does. A map ID that isn't a number errors.
local function check_map_id(uiMapID, fn)
	if type(uiMapID) ~= 'number' then error(('Usage: C_Map.%s(uiMapID)'):format(fn), 3) end
end
local function map_details(uiMapID)
	local m = stub.maps[uiMapID]
	if not m then return nil end
	return { mapID = uiMapID, name = m.name, mapType = m.mapType, parentMapID = m.parentMapID or 0, flags = 0 }
end
C_Map = {
	-- Only the player is stubbed (the game also answers for party members).
	GetBestMapForUnit = function(unit)
		if type(unit) ~= 'string' then error('Usage: C_Map.GetBestMapForUnit(unitToken)', 2) end
		if unit == 'player' then return stub.player_map end
	end,
	GetMapInfo = function(uiMapID)
		check_map_id(uiMapID, 'GetMapInfo')
		return map_details(uiMapID)
	end,
	-- playerMinLevel, playerMaxLevel, petMinLevel, petMaxLevel: 0s for a map
	-- the game has no levels for. No pet levels are stubbed.
	GetMapLevels = function(uiMapID)
		check_map_id(uiMapID, 'GetMapLevels')
		local m = stub.maps[uiMapID]
		local levels = m and m.levels
		if levels then return levels[1], levels[2], 0, 0 end
		return 0, 0, 0, 0
	end,
	-- The child map of uiMapID whose area holds (x, y), in uiMapID's 0-1
	-- coordinates; else uiMapID itself.
	GetMapInfoAtPosition = function(uiMapID, x, y)
		check_map_id(uiMapID, 'GetMapInfoAtPosition')
		if type(x) ~= 'number' or type(y) ~= 'number' then
			error('Usage: C_Map.GetMapInfoAtPosition(uiMapID, x, y)', 2)
		end
		for id, m in pairs(stub.maps) do
			local a = m.area
			if m.parentMapID == uiMapID and a and x >= a[1] and x <= a[3] and y >= a[2] and y <= a[4] then
				return map_details(id)
			end
		end
		return map_details(uiMapID)
	end,
}

-- The PvP status where the player stands (PvpInfoDocumentation.lua): pvpType,
-- isSubZonePvP and factionName, from stub.pvp.
C_PvP = {
	GetZonePVPInfo = function()
		return stub.pvp.type, stub.pvp.subzone == true, stub.pvp.faction
	end,
}

-- Instances (InstanceDocumentation.lua), from stub.instance.
function IsInInstance()
	local instance = stub.instance
	return instance ~= nil, instance and instance.type or 'none'
end
-- name, instanceType, difficultyID, difficultyName, maxPlayers,
-- dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, lfgDungeonID.
-- Outside an instance the game names the continent and gives 0s; here the
-- name is the zone's.
function GetInstanceInfo()
	local i = stub.instance
	if not i then return stub.zone_text, 'none', 0, '', 0, 0, false, 0, 0, nil end
	local maxPlayers = i.max_players or 5
	return i.name, i.type, i.difficulty_id or 1, i.difficulty_name or 'Normal', maxPlayers, 0, false, 0, maxPlayers, nil
end
-- name, groupType, isHeroic, isChallengeMode, displayHeroic, displayMythic,
-- toggleDifficultyID, isLFR, minPlayers, maxPlayers: for the instance's own
-- difficulty only, as a plain (not heroic, mythic or LFR) one. Nothing for
-- any other ID.
function GetDifficultyInfo(difficultyID)
	local i = stub.instance
	if i and difficultyID == (i.difficulty_id or 1) then
		return i.difficulty_name or 'Normal', i.type, false, false, false, false, nil, false, 1, i.max_players or 5
	end
end
function GetZoneText() return stub.zone_text end
function GetSubZoneText() return stub.subzone_text end

-- The game shows an error passed to its handler and carries on. The default
-- handler here hands it to the harness (report_error), which fails the
-- running case unless the test takes it with take_errors().
local errorHandler = function(message) report_error(message) end

function geterrorhandler() return errorHandler end

function seterrorhandler(handler)
	if type(handler) ~= 'function' then error('Usage: seterrorhandler(errfunc)', 2) end
	errorHandler = handler
end

local function pack(...)
	return { n = select('#', ...), ... }
end

-- Post-hooks tbl[name] (or the global name): the original runs, then hook
-- with the same arguments, and the original's results are returned. Like the
-- game, the wrapper is stored in tbl itself, so hooking a frame's method puts
-- a field on that frame.
function hooksecurefunc(tbl, name, hook)
	if type(tbl) == 'string' then
		tbl, name, hook = _G, tbl, name
	end
	local original = tbl[name]
	if type(original) ~= 'function' or type(hook) ~= 'function' then
		error(('hooksecurefunc(): %s is not a function, or no hook was given'):format(tostring(name)), 2)
	end
	rawset(tbl, name, function(...)
		local results = pack(original(...))
		hook(...)
		return unpack(results, 1, results.n)
	end)
end

StaticPopupDialogs = {}
SlashCmdList = {}
