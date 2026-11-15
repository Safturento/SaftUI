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
	-- What GetWidth, GetHeight and GetSize add to a size that isn't 0, to play
	-- the game's read-back: it hands a size back from its layout in single
	-- precision, a hair off the size it was given (26.000002 for a button set
	-- to 26, 559.99994 for a view of 560). 0, an exact size, unless a test
	-- sets it (2 ^ -14 is about the game's hair); where frames are placed
	-- doesn't change.
	size_noise = 0,
	in_combat = false, -- InCombatLockdown
	-- The calls the game blocked on a protected frame in combat (widgets.lua,
	-- "Protected frames in combat"), in order: { widget, method name }. The
	-- game fires ADDON_ACTION_BLOCKED for each.
	blocked = {},
	-- What a secure action button (SecureActionButtonTemplate, widgets.lua) did
	-- when it was clicked: { button, type, item, macrotext, mouse, down }, in
	-- order; and whether the game acts on the press ("cast on key down", the
	-- ActionButtonUseKeyDown setting, on by default) or on the release.
	secure_clicks = {},
	cast_on_key_down = true,
	cursor_x = 0, -- GetCursorPosition, in screen units (UIParent's units times its scale)
	cursor_y = 0,
	time = 0, -- GetTime, in seconds
	-- C_Timer.After's pending callbacks, { due, fn } in the order made.
	-- stub.run_timers() runs the ones due by stub.time.
	timers = {},
	-- The game's frame (tick) number. stub.run_timers() starts a new frame
	-- before it runs the timers due, as C_Timer.After(0) callbacks run on the
	-- next frame. Only what the game allows once per tick reads it (a
	-- nameplate's click area, below).
	tick = 0,
	epoch = 1800000000, -- time(), in seconds since 1970
	shift_down = false, -- IsShiftKeyDown
	ctrl_down = false, -- IsControlKeyDown
	alt_down = false, -- IsAltKeyDown
	mouse_buttons = {}, -- IsMouseButtonDown: a set, e.g. stub.mouse_buttons.LeftButton = true
	-- What the cursor holds, for GetCursorInfo: nil for nothing, or an item
	-- picked up from a bag, { id, link }. ClearCursor drops it.
	cursor_item = nil,
	loaded_addons = {}, -- C_AddOns.IsAddOnLoaded: a set, e.g. stub.loaded_addons.RXPGuides = true
	-- C_AddOns.DoesAddOnExist: a set of the addons the client has, loaded or not
	-- (a loaded one exists too), e.g. stub.installed_addons.Blizzard_SwingTimer = true
	installed_addons = {},
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
	--     'sanctuary', 'arena', 'combat'; '' for none, as the game gives: the
	--     API marks it not nilable), isSubZonePvP and factionName. A test can
	--     make it nil, as when the API returns nothing at all (MayReturnNothing);
	--   instance: nil outside an instance, else { name, type ('party', 'raid',
	--     'pvp', 'arena', 'scenario'), difficulty_id, difficulty_name,
	--     max_players };
	--   zone_text, subzone_text: GetZoneText and GetSubZoneText.
	maps = {},
	player_map = nil,
	pvp = { type = '', subzone = false, faction = nil },
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
-- 'item', itemID, itemLink while the cursor holds an item; nothing otherwise.
function GetCursorInfo()
	local item = stub.cursor_item
	if item then return 'item', item[1], item[2] end
end
function ClearCursor() stub.cursor_item = nil end
function GetTime() return stub.time end
-- C_Timer.After keeps its callback until stub.run_timers() runs it, once
-- stub.time has reached its delay. Nothing runs by itself.
C_Timer = {
	After = function(delay, fn)
		if type(delay) ~= 'number' or type(fn) ~= 'function' then
			error('Usage: C_Timer.After(seconds, callback)', 2)
		end
		table.insert(stub.timers, { due = stub.time + delay, fn = fn })
	end,
	-- A ticker runs fn every `seconds` (the game's, from the time it's made),
	-- once at the most per stub.run_timers(), until its Cancel. Returns the
	-- ticker object, with Cancel and IsCancelled.
	NewTicker = function(seconds, fn, iterations)
		if type(seconds) ~= 'number' or type(fn) ~= 'function' then
			error('Usage: C_Timer.NewTicker(seconds, callback [, iterations])', 2)
		end
		local timer = { due = stub.time + seconds, fn = fn, interval = seconds, left = iterations }
		local ticker = { Cancel = function(self) timer.cancelled = true end, IsCancelled = function() return timer.cancelled == true end }
		timer.object = ticker
		table.insert(stub.timers, timer)
		return ticker
	end,
}
-- Starts the game's next frame (stub.tick), then runs, in the order they were
-- made, the timers due by stub.time (callbacks they make that are due run
-- too). Returns how many ran.
function stub.run_timers()
	stub.tick = stub.tick + 1
	local ran = 0
	local i = 1
	while i <= #stub.timers do
		local timer = stub.timers[i]
		if timer.cancelled then
			table.remove(stub.timers, i)
		elseif timer.due <= stub.time then
			table.remove(stub.timers, i)
			ran = ran + 1
			if timer.interval then
				-- A ticker goes on from now (once per call, however late), unless it
				-- has run its iterations.
				if timer.left then timer.left = timer.left - 1 end
				if not timer.left or timer.left > 0 then
					timer.due = stub.time + timer.interval
					table.insert(stub.timers, timer)
				end
			end
			timer.fn(timer.object)
		else
			i = i + 1
		end
	end
	return ran
end
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
	-- True for an addon the client has, whether or not it is loaded.
	DoesAddOnExist = function(name)
		if type(name) ~= 'string' and type(name) ~= 'number' then
			error('Usage: C_AddOns.DoesAddOnExist(name)', 2)
		end
		return stub.installed_addons[name] == true or stub.loaded_addons[name] == true
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
-- Each class token's English name and class ID, from wago.tools' ChrClasses
-- at 12.1.5.70783 (Forever 1.60.1.70888 has the nine classic classes, with
-- the same names and IDs).
local CLASSES = {
	WARRIOR = { 'Warrior', 1 }, PALADIN = { 'Paladin', 2 }, HUNTER = { 'Hunter', 3 }, ROGUE = { 'Rogue', 4 },
	PRIEST = { 'Priest', 5 }, DEATHKNIGHT = { 'Death Knight', 6 }, SHAMAN = { 'Shaman', 7 }, MAGE = { 'Mage', 8 },
	WARLOCK = { 'Warlock', 9 }, MONK = { 'Monk', 10 }, DRUID = { 'Druid', 11 }, DEMONHUNTER = { 'Demon Hunter', 12 },
	EVOKER = { 'Evoker', 13 },
}
function UnitClass(unit)
	-- The player's class is stub.class's (see the end of this file).
	if unit == 'player' then
		local info = CLASSES[stub.class] or error(('UnitClass: stub.class %s is not a class token'):format(tostring(stub.class)), 2)
		return info[1], stub.class, info[2]
	end
	-- Another unit's class token stands for its name too.
	local other = OtherUnit(unit)
	if other then return other.class, other.class end
end
-- The classes the client has: stub.class_ids, their class IDs. Forever has the
-- nine classic classes, whose IDs are not 1 to 9 (Druid is 11), the default; a
-- test of retail sets all thirteen. GetClassInfo(classID) takes an ID, as the
-- game's does, and gives nothing for one the client lacks; GetNumClasses is how
-- many classes there are, not the highest ID. C_SpecializationInfo.GetAllClassIDs
-- (Forever's, in its SpecializationInfoDocumentation) lists the IDs; retail has
-- none, so a test of retail removes it.
stub.class_ids = { 1, 2, 3, 4, 5, 7, 8, 9, 11 }
function GetNumClasses() return #stub.class_ids end
function GetClassInfo(classID)
	local has = false
	for _, id in ipairs(stub.class_ids) do has = has or id == classID end
	if not has then return end
	for token, info in pairs(CLASSES) do
		if info[2] == classID then return info[1], token, classID end
	end
end
C_SpecializationInfo = C_SpecializationInfo or {}
function C_SpecializationInfo.GetAllClassIDs()
	local out = {}
	for i, id in ipairs(stub.class_ids) do out[i] = id end
	return out
end
function UnitRace(unit)
	if unit == 'player' then return 'Human', 'Human', 1 end
end
-- GetGuildInfo(unit) (an old global, not in the generated API documentation):
-- the guild's name, its rank name and rank index. A stub.units unit's is its
-- guild field (nil: no guild, which gives nil as the game does); a test can
-- make it a secret value. The player has none unless stub.player_guild.
function GetGuildInfo(unit)
	local guild
	if unit == 'player' then
		guild = stub.player_guild
	else
		local other = OtherUnit(unit)
		guild = other and other.guild
	end
	if guild ~= nil then return guild, 'Member', 1 end
end
-- Blizzard's global string for the tooltip's level line (GlobalStrings).
TOOLTIP_UNIT_LEVEL = 'Level %s'
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
-- IsEncounterInProgress() -> inProgress: a global function every boss mod calls,
-- true from ENCOUNTER_START to ENCOUNTER_END (stub.encounter). It is on both
-- clients (warcraft.wiki.gg, API IsEncounterInProgress); it is not in the
-- generated API documentation on either branch of Gethe/wow-ui-source (checked
-- in the Instance, EncounterJournal, Unit and Frame documentation, 2026-11-14),
-- so the signature is the wiki's, not Blizzard's source.
stub.encounter = false
function IsEncounterInProgress() return stub.encounter == true end
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

-- Text the game builds from values an addon may hold but not read (secret
-- values, .agents/clients.md): C_StringUtil.WrapString and AbbreviateNumbers
-- take a secret from an addon (SecretArguments AllowedWhenTainted in their
-- documentation on both clients) and give back a secret string. The stubs
-- can't make one, so for a value the global issecretvalue calls secret they
-- give a table holding what they were handed, which a test can read.
--
-- C_StringUtil.WrapString(infix, prefix, suffix) (StringUtilDocumentation.lua):
-- prefix .. infix .. suffix, or '' when infix is '' (its documentation: "joined
-- to 'infix' iif 'infix' is not an empty string"). A nil prefix or suffix is ''.
-- A secret infix gives { wrapped = infix, prefix = prefix, suffix = suffix }.
C_StringUtil = C_StringUtil or {}
function C_StringUtil.WrapString(infix, prefix, suffix)
	if issecretvalue and issecretvalue(infix) then
		return { wrapped = infix, prefix = prefix, suffix = suffix }
	end
	if type(infix) ~= 'string' and type(infix) ~= 'number' then
		error('Usage: C_StringUtil.WrapString(infix [, prefix, suffix])', 2)
	end
	if infix == '' then return '' end
	return (prefix or '') .. infix .. (suffix or '')
end
-- AbbreviateNumbers(number, options) (LocalizationDocumentation.lua; the
-- breakpoint fields in LocalizationSharedDocumentation.lua): at the first of
-- options.breakpointData's breakpoints (largest first) the number reaches, the
-- number divided by significandDivisor and rounded down, then divided by
-- fractionDivisor, and the abbreviation after it (the global string of that
-- name, or the abbreviation itself when abbreviationIsGlobal is false). Its
-- documentation's example: a breakpoint at 1,000 dividing by 100 then 10 makes
-- 1234 '1.2k'. Below every breakpoint, the number as it is. The number is
-- written as Lua's tostring writes it (1.0 as 1); that the client writes it
-- the same, and rounds down rather than to nearest, is for checking in game.
-- A secret number gives { abbreviated = number, options = options }. With no
-- breakpointData the game uses its own for the client's language, which its
-- Lua doesn't hold, so that errors here rather than guess.
function AbbreviateNumbers(number, options)
	if issecretvalue and issecretvalue(number) then
		return { abbreviated = number, options = options }
	end
	if type(number) ~= 'number' then error('Usage: AbbreviateNumbers(number [, options])', 2) end
	local breakpoints = options and options.breakpointData
	if not breakpoints then
		error("AbbreviateNumbers without options.breakpointData is not stubbed: the game's own breakpoints aren't in its Lua", 2)
	end
	for _, b in ipairs(breakpoints) do
		if number >= b.breakpoint then
			local abbreviation = b.abbreviation
			if b.abbreviationIsGlobal ~= false then abbreviation = _G[abbreviation] end
			return tostring(math.floor(number / b.significandDivisor) / b.fractionDivisor) .. abbreviation
		end
	end
	return tostring(number)
end
-- UnitIsDead(unit) (UnitDocumentation.lua): the player's is stub.dead, another
-- unit's its stub.units dead; false for a unit that isn't there, as the game
-- gives.
function UnitIsDead(unit)
	if unit == 'player' then return stub.dead == true end
	local other = OtherUnit(unit)
	return other ~= nil and other.dead == true
end

-- The player's class and spellbooks.
--   class: UnitClass('player')'s token, which also gives its name and ID.
--   known_spells, known_pet_spells: the spell IDs C_SpellBook.IsSpellKnown
--     calls known in the player's spellbook and the pet's, as sets, e.g.
--     stub.known_spells[370] = true. A pet's spells are known only while it's
--     out, so a test of no pet leaves known_pet_spells empty.
stub.class = 'WARRIOR'
stub.known_spells = {}
stub.known_pet_spells = {}

-- C_SpellBook.IsSpellKnown(spellID[, spellBank]) (SpellBookDocumentation.lua,
-- the same on both clients): spellID a number, spellBank an
-- Enum.SpellBookSpellBank (Player, the default, or Pet). Its answer is a plain
-- boolean, never secret. A spellID that isn't a number, or a bank that isn't
-- one, errors as the game's argument check does.
C_SpellBook = C_SpellBook or {}
function C_SpellBook.IsSpellKnown(spellID, spellBank)
	if type(spellID) ~= 'number' then
		error('Usage: local isKnown = C_SpellBook.IsSpellKnown(spellID [, spellBank])', 2)
	end
	if spellBank == nil or spellBank == 0 then return stub.known_spells[spellID] == true end
	if spellBank == 1 then return stub.known_pet_spells[spellID] == true end
	error('Usage: local isKnown = C_SpellBook.IsSpellKnown(spellID [, spellBank])', 2)
end

-- Nameplates: C_NamePlate (NamePlateDocumentation.lua, the same on both
-- clients), the unit API oUF's nameplate driver reads, and stub controls that
-- play the game's part.
--
-- The game makes the plate frames itself (NamePlate1, NamePlate2, ..., on the
-- WorldFrame, placed and sized by the client) and reuses them: a plate one
-- unit leaves is handed to another. On every add Blizzard's
-- NamePlateDriverFrame gives the plate a UnitFrame from its pool, and on the
-- remove takes it back (NamePlateBaseMixin:AcquireUnitFrame and
-- ReleaseUnitFrame, Blizzard_NamePlateBase.lua, both clients: the plate's
-- UnitFrame field is set, then nil). Blizzard's driver registered for the
-- events when the UI loaded, before any addon's frame, so it acquires before
-- an addon hears of the add and releases before an addon hears of the remove;
-- the unit's plate is found until every frame has heard of the remove.
--
--   stub.nameplate_size: { width, height }, the size C_NamePlate.SetNamePlateSize
--     last set (every plate takes it), nil until one is set.
--   stub.nameplate_target: the unit token whose plate is the target's
--     (C_NamePlate.GetNamePlateForUnit('target')), nil for none.
--   stub.add_nameplate(unit, opts) -> plate: the game shows unit ('nameplateN')
--     on a plate and fires NAME_PLATE_UNIT_ADDED. The plate is a new one,
--     numbered after the last, unless opts.plate = n hands it NamePlate<n>
--     again (which must be free). Every plate is anchor restricted
--     (stub.restrict_anchors, widgets.lua): SaftUI's code can't measure it or
--     anything anchored to it. opts.forbidden makes it a forbidden plate,
--     which C_NamePlate gives addon code only when it asks for forbidden ones
--     (it can't: Blizzard's own driver passes issecure()); whether the game
--     fires NAME_PLATE_UNIT_ADDED to addons for a forbidden plate isn't known,
--     so the stub fires it, the stricter case. opts.widgets_only and
--     opts.game_object are UnitNameplateShowsWidgetsOnly's and
--     UnitIsGameObject's answers for the unit (a capture bar, a quest object).
--     Each add hands the plate a new pooled Blizzard UnitFrame (a Button) with
--     its CastBarsContainer, WidgetContainer (hidden) and SoftTargetFrame
--     children, set with rawset as Blizzard's pool and template do. Blizzard
--     runs the UnitFrame's UpdateWidgetsOnlyMode before addons hear of the
--     add (OnUnitSet, Blizzard_NamePlateUnitFrame.lua, both clients): the
--     WidgetContainer's points cleared, then its BOTTOM on the UnitFrame's
--     BOTTOM for a widget-only unit, else its TOP on the CastBarsContainer's
--     BOTTOM; then its UpdateHitTestArea (below). OnUnitSet also registers
--     the UnitFrame with CVarCallbackRegistry (blizzard.lua) for the friendly
--     NPC plates setting (UpdateWidgetsOnlyMode again) and for showing only
--     the names of friendly players (UpdateShowOnlyName, which runs
--     UpdateHitTestArea when the plate's show-only-name state changes; here
--     every change counts as one, the stricter case). The remove unregisters
--     them (OnUnitCleared). The callbacks stay registered on a UnitFrame oUF
--     has blocked: oUF's UnregisterAllEvents drops its events, not these.
--   stub.set_nameplate_widgets_only(unit, value): the unit's plate starts or
--     stops showing only widgets without a new add, and Blizzard runs its
--     UpdateWidgetsOnlyMode again, as it does when the game's friendly NPC
--     plates setting changes.
--   stub.remove_nameplate(unit): the game takes the unit's plate away:
--     Blizzard's driver takes its UnitFrame back (hidden, its points cleared,
--     as a frame pool resets one), NAME_PLATE_UNIT_REMOVED fires, and the
--     plate hides and is free.
--   stub.set_nameplate_size_secure(width, height): sets the size even in
--     combat, as Blizzard's untainted code can (NamePlateDriverFrame's
--     UpdateNamePlateSize, blizzard.lua).
--   stub.apply_nameplate_frame_options(plate): Blizzard's
--     NamePlateBaseMixin:ApplyFrameOptions on a plate showing a unit, which
--     NamePlateDriverFrame:UpdateNamePlateOptions runs on every plate
--     (blizzard.lua): its UnitFrame's ApplyFrameOptions, of which only the
--     UpdateHitTestArea is mimicked.
--
-- A plate's click area, its hit-test points (FrameAPINamePlateDocumentation.lua,
-- the same on both clients): ClearAllHitTestPoints(), SetAllHitTestPoints(region),
-- SetHitTestPoints(anchors), GetHitTestPoints() and CanChangeHitTestPoints().
-- GetHitTestPoints gives the anchors as AnchorBinding tables ({ point,
-- relativeTo, relativePoint, offsetX, offsetY }); SetAllHitTestPoints(region)
-- is taken to set two, TOPLEFT and BOTTOMRIGHT on region's, "to fully
-- encompass" it (the documentation's words; the anchors it makes aren't
-- documented). The three setters are guarded (RequiresCanChangeHitTestPoints,
-- failure mode Error): "Updates are normally blocked for tainted code during
-- combat, except on the tick a unit is first assigned or when untainted code
-- updates hit-test points on the same tick." So out of combat addon code may
-- always change them; in combat only on the tick (stub.tick) the plate got
-- its unit or Blizzard's code changed them, and otherwise a setter errors.
-- Blizzard's UpdateHitTestArea (Blizzard_NamePlateUnitFrame.lua, both
-- clients) is untainted, so it works in combat and frees the tick: it clears
-- the points on a widget-only plate, else sets Blizzard's own area, two
-- anchors round its health bar and name, here relative to the UnitFrame
-- (which stands in for both).
--   stub.on_nameplate_frame: nil, or a function the stub calls with each
--     Blizzard frame it makes for the plates (a plate, and each pooled
--     UnitFrame with its WidgetContainer and SoftTargetFrame) once it is set
--     up, so a test can lock them as Blizzard's (lib/locked_widget.lua).
-- Not mimicked: script nameplates, the personal resource display, plates the
-- game makes before an add (NAME_PLATE_CREATED), FORBIDDEN_NAME_PLATE_UNIT_ADDED
-- and its remove, a plate's place on screen (each sits at the WorldFrame's
-- centre), and units other than nameplateN and the target.
stub.nameplate_size = nil
stub.nameplate_target = nil
stub.on_nameplate_frame = nil

do
	-- by number: { frame, unit, forbidden, widgets_only, game_object,
	-- hit_points (the click area's anchors), free_tick (the tick addon code may
	-- change them in combat) }
	local plates = {}
	local byUnit = {}  -- the plate showing each unit token

	-- The plate record for a unit token: 'target' is stub.nameplate_target's.
	local function record_for(unit)
		unit = unit:lower()
		if unit == 'target' then
			unit = stub.nameplate_target
			if not unit then return nil end
		end
		return byUnit[unit]
	end

	local function made(frame)
		if stub.on_nameplate_frame then stub.on_nameplate_frame(frame) end
	end

	local function anchor(point, relativeTo, offsetX, offsetY)
		return { point = point, relativeTo = relativeTo, relativePoint = point, offsetX = offsetX, offsetY = offsetY }
	end

	-- Blizzard's NamePlateUnitFrameMixin:UpdateHitTestArea, untainted: no
	-- points on a widget-only plate, else Blizzard's area round its UnitFrame.
	local function blizzard_hit_test(record)
		local unitFrame = rawget(record.frame, 'UnitFrame')
		if record.widgets_only then
			record.hit_points = {}
		else
			record.hit_points = { anchor('TOPLEFT', unitFrame, -10, 10), anchor('BOTTOMRIGHT', unitFrame, 10, -10) }
		end
		record.free_tick = stub.tick
	end

	-- Blizzard's NamePlateUnitFrameMixin:UpdateWidgetsOnlyMode, for the
	-- WidgetContainer of the UnitFrame a plate has, then its click area.
	local function widgets_only_mode(record)
		local unitFrame = rawget(record.frame, 'UnitFrame')
		local widgets = rawget(unitFrame, 'WidgetContainer')
		widgets:ClearAllPoints()
		if record.widgets_only then
			widgets:SetPoint('BOTTOM', unitFrame, 'BOTTOM')
		else
			widgets:SetPoint('TOP', rawget(unitFrame, 'CastBarsContainer'), 'BOTTOM')
		end
		blizzard_hit_test(record)
	end

	-- The click area's methods, on a plate the game makes.
	local function hit_test_methods(frame, record)
		local function guard(method)
			if InCombatLockdown() and record.free_tick ~= stub.tick then
				error(('%s: this nameplate does not permit changes to its hit-test points (CanChangeHitTestPoints)'):format(method), 3)
			end
		end
		rawset(frame, 'CanChangeHitTestPoints', function()
			return not InCombatLockdown() or record.free_tick == stub.tick
		end)
		rawset(frame, 'ClearAllHitTestPoints', function()
			guard('ClearAllHitTestPoints')
			record.hit_points = {}
		end)
		rawset(frame, 'SetAllHitTestPoints', function(_, region)
			guard('SetAllHitTestPoints')
			if type(region) ~= 'table' then error('Usage: nameplate:SetAllHitTestPoints(relativeTo)', 2) end
			record.hit_points = { anchor('TOPLEFT', region, 0, 0), anchor('BOTTOMRIGHT', region, 0, 0) }
		end)
		rawset(frame, 'SetHitTestPoints', function(_, anchors)
			guard('SetHitTestPoints')
			if type(anchors) ~= 'table' then error('Usage: nameplate:SetHitTestPoints(anchors)', 2) end
			record.hit_points = {}
			for i, a in ipairs(anchors) do
				record.hit_points[i] = anchor(a.point, a.relativeTo, a.offsetX or 0, a.offsetY or 0)
				record.hit_points[i].relativePoint = a.relativePoint or a.point
			end
		end)
		rawset(frame, 'GetHitTestPoints', function()
			local copy = {}
			for i, a in ipairs(record.hit_points or {}) do
				copy[i] = { point = a.point, relativeTo = a.relativeTo, relativePoint = a.relativePoint, offsetX = a.offsetX, offsetY = a.offsetY }
			end
			return copy
		end)
	end

	-- The CVarCallbackRegistry callbacks Blizzard's UnitFrame registers in
	-- OnUnitSet, by setting name (NamePlateConstants, blizzard.lua): the ones
	-- that change its click area.
	local function unit_frame_callbacks(record)
		return {
			[NamePlateConstants.SHOW_FRIENDLY_NPCS_CVAR] = function() widgets_only_mode(record) end,
			[NamePlateConstants.SHOW_ONLY_NAME_FOR_FRIENDLY_PLAYER_UNITS_CVAR] = function() blizzard_hit_test(record) end,
		}
	end

	local function set_size(width, height)
		stub.nameplate_size = { width, height }
		for _, plate in pairs(plates) do plate.frame:SetSize(width, height) end
	end

	C_NamePlate = {}
	-- C_NamePlate.GetNamePlateForUnit(unitToken[, includeForbidden]): the
	-- plate showing the unit, nil for none (the documentation marks it not
	-- nilable, but the game gives nil for a unit with no plate, which addons
	-- and oUF check). A forbidden plate only with includeForbidden.
	function C_NamePlate.GetNamePlateForUnit(unit, includeForbidden)
		if type(unit) ~= 'string' then
			error('Usage: local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken [, includeForbidden])', 2)
		end
		local record = record_for(unit)
		if not record or (record.forbidden and not includeForbidden) then return nil end
		return record.frame
	end
	-- C_NamePlate.GetNamePlates(): the plates showing a unit, by plate number;
	-- forbidden ones only with includeForbidden, as Blizzard's driver passes it.
	function C_NamePlate.GetNamePlates(includeForbidden)
		local list = {}
		for n = 1, #plates do
			local record = plates[n]
			if record.unit and (includeForbidden or not record.forbidden) then
				list[#list + 1] = record.frame
			end
		end
		return list
	end
	-- C_NamePlate.SetNamePlateSize(width, height): one size for every plate.
	-- The documentation marks it HasRestrictions: in combat addon code is
	-- refused (noted in stub.blocked as { C_NamePlate, 'SetNamePlateSize' },
	-- as a protected frame's calls are).
	function C_NamePlate.SetNamePlateSize(width, height)
		if type(width) ~= 'number' or type(height) ~= 'number' then
			error('Usage: C_NamePlate.SetNamePlateSize(width, height)', 2)
		end
		if InCombatLockdown() then
			stub.blocked[#stub.blocked + 1] = { C_NamePlate, 'SetNamePlateSize' }
			return
		end
		set_size(width, height)
	end

	-- UnitNameplateShowsWidgetsOnly(unit) and UnitIsGameObject(unit)
	-- (UnitDocumentation.lua): plain booleans, from the add's opts; false for a
	-- unit with no plate.
	function UnitNameplateShowsWidgetsOnly(unit)
		if type(unit) ~= 'string' then error('Usage: UnitNameplateShowsWidgetsOnly(unit)', 2) end
		local record = record_for(unit)
		return record ~= nil and record.widgets_only == true
	end
	function UnitIsGameObject(unit)
		local record = type(unit) == 'string' and record_for(unit) or nil
		return record ~= nil and record.game_object == true
	end

	function stub.set_nameplate_size_secure(width, height)
		set_size(width, height)
	end

	function stub.add_nameplate(unit, opts)
		opts = opts or {}
		assert(type(unit) == 'string' and unit:match('^nameplate%d+$'), 'add_nameplate: a nameplateN unit, got ' .. tostring(unit))
		assert(not byUnit[unit], 'add_nameplate: ' .. unit .. ' already has a plate')
		local n = opts.plate or #plates + 1
		local record = plates[n]
		if record then
			assert(not record.unit, ('add_nameplate: NamePlate%d shows %s'):format(n, tostring(record.unit)))
		else
			assert(n == #plates + 1, 'add_nameplate: the game numbers its plates in order')
			local frame = CreateFrame('Frame', 'NamePlate' .. n, WorldFrame)
			frame:SetPoint('CENTER', WorldFrame, 'CENTER')
			-- Anchor restricted, as the game's plates are (widgets.lua):
			-- SaftUI can't measure the plate or anything anchored to it.
			stub.restrict_anchors(frame)
			if stub.nameplate_size then frame:SetSize(stub.nameplate_size[1], stub.nameplate_size[2]) end
			frame:Hide()
			record = { frame = frame, hit_points = {} }
			hit_test_methods(frame, record)
			plates[n] = record
			made(frame)
		end
		record.unit = unit
		record.forbidden = opts.forbidden == true
		record.widgets_only = opts.widgets_only == true
		record.game_object = opts.game_object == true
		-- The tick the unit is assigned on: addon code may change the click
		-- area then, in combat too.
		record.free_tick = stub.tick
		byUnit[unit] = record

		-- Blizzard's driver: a UnitFrame from its pool, on the plate.
		local plate = record.frame
		local unitFrame = CreateFrame('Button', nil, plate)
		unitFrame:SetAllPoints(plate)
		local castBars = CreateFrame('Frame', nil, unitFrame)
		castBars:SetPoint('TOP', unitFrame, 'BOTTOM')
		local widgets = CreateFrame('Frame', nil, unitFrame)
		widgets:Hide()
		local softTarget = CreateFrame('Frame', nil, unitFrame)
		rawset(unitFrame, 'CastBarsContainer', castBars)
		rawset(unitFrame, 'WidgetContainer', widgets)
		rawset(unitFrame, 'SoftTargetFrame', softTarget)
		rawset(plate, 'UnitFrame', unitFrame)
		-- OnUnitSet: the setting callbacks (none where a test took the
		-- registry or the constants away), then UpdateWidgetsOnlyMode.
		record.callbacks = (CVarCallbackRegistry and NamePlateConstants) and unit_frame_callbacks(record) or {}
		for cvar, callback in pairs(record.callbacks) do
			CVarCallbackRegistry:RegisterCallback(cvar, callback, unitFrame)
		end
		widgets_only_mode(record)
		made(unitFrame)
		made(castBars)
		made(widgets)
		made(softTarget)

		plate:Show()
		stub.fire_event('NAME_PLATE_UNIT_ADDED', unit)
		return plate
	end

	function stub.apply_nameplate_frame_options(plate)
		for _, record in pairs(plates) do
			if record.frame == plate and record.unit then blizzard_hit_test(record) end
		end
	end

	function stub.remove_nameplate(unit)
		local record = byUnit[unit]
		assert(record, 'remove_nameplate: ' .. tostring(unit) .. ' has no plate')
		local plate = record.frame
		-- Blizzard's driver clears the unit (OnUnitCleared: the setting
		-- callbacks go) and gives the UnitFrame back to its pool.
		local unitFrame = rawget(plate, 'UnitFrame')
		for cvar in pairs(record.callbacks) do
			if CVarCallbackRegistry then CVarCallbackRegistry:UnregisterCallback(cvar, unitFrame) end
		end
		record.callbacks = nil
		rawset(plate, 'UnitFrame', nil)
		unitFrame:Hide()
		unitFrame:ClearAllPoints()

		stub.fire_event('NAME_PLATE_UNIT_REMOVED', unit)
		plate:Hide()
		byUnit[unit] = nil
		record.unit, record.forbidden, record.widgets_only, record.game_object = nil, nil, nil, nil
	end

	function stub.set_nameplate_widgets_only(unit, value)
		local record = byUnit[unit]
		assert(record, 'set_nameplate_widgets_only: ' .. tostring(unit) .. ' has no plate')
		record.widgets_only = value == true
		widgets_only_mode(record)
	end
end

-- UnitIsFriend(unit, otherUnit) and UnitCanAttack(unit, otherUnit)
-- (UnitDocumentation.lua, the same on both clients: two unit tokens, a plain
-- boolean back): between the player and a stub.units unit, either way round,
-- its friend and attackable fields (false where unset). A test can put a
-- secret value (tests/lib/secrets.lua) in either, as restricted content could
-- hand one. A unit that isn't there gives false, as the game does for a unit
-- that doesn't exist; no other pair is stubbed, so it errors rather than guess.
do
	local function between(name, field)
		return function(unit, otherUnit)
			if type(unit) ~= 'string' or type(otherUnit) ~= 'string' then
				error(('Usage: local result = %s(unit, target)'):format(name), 2)
			end
			local other = (otherUnit == 'player' and OtherUnit(unit)) or (unit == 'player' and OtherUnit(otherUnit))
			if other then
				local value = other[field]
				if value == nil then return false end
				return value
			end
			if not (OtherUnit(unit) or unit == 'player') or not (OtherUnit(otherUnit) or otherUnit == 'player') then return false end
			error(('%s(%s, %s) is not stubbed: only a stub.units unit and the player'):format(name, unit, otherUnit), 2)
		end
	end
	UnitIsFriend = between('UnitIsFriend', 'friend')
	UnitCanAttack = between('UnitCanAttack', 'attackable')
end

-- C_CVar (CVarDocumentation.lua, the same on both clients): the game's
-- settings, by name, each a string.
--
--   stub.cvars: name -> value, a string. A name not there is a setting this
--     client doesn't have. The defaults are only the two friendly plate
--     settings, off (the game's defaults as far as we know them; the source
--     doesn't say, so this is inferred). Every other setting a test needs, it
--     adds itself (the scale and simplified plate settings, the nameplate
--     tests' own).
--   C_CVar.GetCVar(name): stub.cvars[name], or nil for a setting the client
--     lacks (the documentation marks its return Nilable).
--   C_CVar.GetCVarBool(name): the setting as a boolean, nil for a setting the
--     client lacks (Nilable too). Any value but '0' is true, as Blizzard's own
--     cached reads take it (CvarUtil.lua, CVarCallbackRegistry:GetCVarValueBool);
--     the tests set only '0' and '1'.
--   C_CVar.SetCVar(name, value): sets the string and returns true. An unknown
--     name returns false (RequiresValidAndPublicCVar). The game protects some
--     nameplate settings in combat (the documentation's RequiresNonSecureCVar,
--     and addons setting friendly plates in combat get blocked), so in combat
--     the stub refuses every setting, the strict side: noted in stub.blocked as
--     { C_CVar, name }, it returns false and changes nothing. A nil value
--     (the documentation allows one) errors: what the game makes of it isn't
--     known, and SaftUI never passes one. A changed value fires CVAR_UPDATE
--     (name, value) before it returns: ConsoleDocumentation.lua marks the
--     event SynchronousEvent on both clients. Whether the game fires it for a
--     value set to what it already was isn't known; here it doesn't.
--   stub.set_cvar_secure(name, value): sets a setting the client has even in
--     combat, as Blizzard's untainted code can (its key binding for friendly
--     plates), firing CVAR_UPDATE for a change as C_CVar.SetCVar does.
stub.cvars = {
	nameplateShowFriendlyPlayers = '0',
	nameplateShowFriendlyNpcs = '0',
}

local function set_cvar(name, value)
	value = tostring(value)
	local changed = stub.cvars[name] ~= value
	stub.cvars[name] = value
	if changed then stub.fire_event('CVAR_UPDATE', name, value) end
end

C_CVar = {}
function C_CVar.GetCVar(name)
	if type(name) ~= 'string' then error('Usage: local value = C_CVar.GetCVar(name)', 2) end
	return stub.cvars[name]
end
function C_CVar.GetCVarBool(name)
	if type(name) ~= 'string' then error('Usage: local value = C_CVar.GetCVarBool(name)', 2) end
	local value = stub.cvars[name]
	if value == nil then return nil end
	return value ~= '0'
end
function C_CVar.SetCVar(name, value)
	if type(name) ~= 'string' then error('Usage: local success = C_CVar.SetCVar(name [, value])', 2) end
	if value == nil then error('C_CVar.SetCVar: a nil value is not stubbed', 2) end
	if stub.cvars[name] == nil then return false end
	if InCombatLockdown() then
		stub.blocked[#stub.blocked + 1] = { C_CVar, name }
		return false
	end
	set_cvar(name, value)
	return true
end
function stub.set_cvar_secure(name, value)
	assert(stub.cvars[name] ~= nil, 'set_cvar_secure: this client has no setting ' .. tostring(name))
	set_cvar(name, value)
end

-- Key bindings. The old globals are not in the generated API documentation
-- (Blizzard_APIDocumentationGenerated); their shapes are how Blizzard's own key
-- binding settings call them (Blizzard_Settings_Shared/Blizzard_Keybindings.lua,
-- read on both branches of Gethe/wow-ui-source on 2026-11-14, the same on both):
--   GetBindingKey(command [, nil, context]) -> key1, key2, ...: the keys bound to
--     the command, nothing for none.
--   SetBinding(key, command [, context]) -> boolean: binds the key to the command
--     (taking it from whatever it was bound to); a nil command unbinds the key
--     (SetBinding(key, nil, context)). false when the game refuses the key.
--   SaveBindings(set), GetCurrentBindingSet(): `SaveBindings(GetCurrentBindingSet())`
--     is the line Blizzard's own code runs after a change (Blizzard_Keybindings.lua
--     line 144; Blizzard_ClickBindingUI.lua line 400): the set is 1 (account) or 2
--     (character).
-- In combat the game blocks SetBinding and SaveBindings (.agents/taint.md rule 6),
-- so the stubs refuse both: noted in stub.blocked as { SetBinding, key } and
-- { SaveBindings, set }, changing nothing. The game fires UPDATE_BINDINGS after a
-- binding changes; the stubs don't, a test fires it itself.
--   stub.bindings        key -> command
--   stub.binding_set     what GetCurrentBindingSet returns (1)
--   stub.saved_bindings  the sets SaveBindings was given, in order
--   stub.rejected_keys   a set of keys SetBinding refuses (returns false)
stub.bindings = {}
stub.binding_set = 1
stub.saved_bindings = {}
stub.rejected_keys = {}

function GetBindingKey(command)
	if type(command) ~= 'string' then error('Usage: key1, key2 = GetBindingKey(command)', 2) end
	local keys = {}
	for key, bound in pairs(stub.bindings) do
		if bound == command then keys[#keys + 1] = key end
	end
	table.sort(keys)
	return unpack(keys)
end

function SetBinding(key, command)
	if type(key) ~= 'string' then error('Usage: success = SetBinding(key [, command])', 2) end
	if InCombatLockdown() then
		stub.blocked[#stub.blocked + 1] = { SetBinding, key }
		return false
	end
	if command ~= nil and stub.rejected_keys[key] then return false end
	stub.bindings[key] = command
	return true
end

function GetCurrentBindingSet() return stub.binding_set end

-- GetBindingAction(key) -> the command the key is bound to, '' for none;
-- GetBindingText(key) -> the key as the player reads it (the stubs give the key
-- itself); GetBindingName(command) -> the command's name in Key Bindings
-- (stub.binding_names[command], else the command). The shapes are how
-- SaftUI-ActionBars/keybindmode.lua and Blizzard's Keybindings.lua use them.
stub.binding_names = {}
function GetBindingAction(key)
	if type(key) ~= 'string' then error('Usage: action = GetBindingAction(key)', 2) end
	return stub.bindings[key] or ''
end
function GetBindingText(key) return key end
function GetBindingName(command) return stub.binding_names[command] or command end

function SaveBindings(set)
	if set ~= 1 and set ~= 2 then error('Usage: SaveBindings(bindingSet)', 2) end
	if InCombatLockdown() then
		stub.blocked[#stub.blocked + 1] = { SaveBindings, set }
		return
	end
	stub.saved_bindings[#stub.saved_bindings + 1] = set
end

-- The quest icon's questions about a unit (the same on both clients: a unit
-- token in, a plain boolean back, its documentation marks it not nilable):
-- C_QuestLog.UnitIsRelatedToActiveQuest(unit) (QuestLogDocumentation.lua),
-- whether one of the player's active quests is about the unit, and
-- UnitIsQuestBoss(unit) (UnitDocumentation.lua). A stub.units unit's quest and
-- quest_boss fields (false where unset), which a test can make a secret value
-- (tests/lib/secrets.lua), as restricted content could hand one; false for the
-- player and for a unit that isn't there. A unit that isn't a string errors,
-- as the game's argument check does.
C_QuestLog = C_QuestLog or {}
do
	local function ask(usage, field)
		return function(unit)
			if type(unit) ~= 'string' then error('Usage: ' .. usage, 2) end
			local other = OtherUnit(unit)
			if not other or other[field] == nil then return false end
			return other[field]
		end
	end
	C_QuestLog.UnitIsRelatedToActiveQuest = ask('local isRelatedToActiveQuest = C_QuestLog.UnitIsRelatedToActiveQuest(unit)', 'quest')
	UnitIsQuestBoss = ask('local result = UnitIsQuestBoss(unit)', 'quest_boss')
end

-- Threat, groups and roles, for the nameplates' threat tint
-- (SaftUI-Unitframes/nameplates/threat.lua). The functions are in both
-- clients' UnitDocumentation.lua and SecretPredicateAPIDocumentation.lua,
-- unless a comment says otherwise; IsInGroup, IsInRaid and
-- GetNumGroupMembers are the game's long-standing globals, which the
-- generated documentation doesn't list.
--
--   stub.threat: mob token -> { [unit token] = entry }, each unit on that
--     mob's threat list. An entry is the unit's status (0-3, as
--     UnitThreatSituation gives it: 0 lower threat than the tank, 1 higher
--     but not tanking, 2 tanking with someone else higher, 3 tanking
--     securely), or { status = n, percent = p, isTanking = t } to give its
--     scaled percent and UnitDetailedThreatSituation's isTanking. Not given,
--     the percent is 100 for a unit tanking (status 2 or 3) and 0 otherwise,
--     and isTanking is status 2 or 3. A test can put a secret value
--     (tests/lib/secrets.lua) in any of them, as restricted content hands
--     one: the threat values (UnitDetailedThreatSituation's, which are
--     SecretWhenUnitThreatValuesRestricted) can be secret while the state
--     (UnitThreatSituation's, SecretWhenUnitThreatStateRestricted) isn't.
--   stub.secret_threat: mob token -> true (every unit's threat state with that
--     mob is secret) or a set of unit tokens (only theirs is), for
--     C_Secrets.ShouldUnitThreatStateBeSecret. The game's threat functions
--     give secret values then; here they give what stub.threat holds, so a
--     test of a secret state puts the secret there too where it matters.
--   stub.group: nil while the player is on their own; else { raid = true or
--     nil, members = { unit tokens } }: a party's members besides the player
--     ('party1'..'party4'), or a raid's members, the player's own raid token
--     among them, as the game numbers a raid ('raid1'..'raid40').
--   stub.role: UnitGroupRolesAssigned('player'): 'TANK', 'HEALER', 'DAMAGER'
--     or 'NONE' (nil reads as 'NONE'). Another unit's is its stub.units role.
--   stub.tank_aura: unit token -> true for a unit with an aura that makes it
--     a tank (UnitHasEffectivelyTankAura, Forever only).
--   UnitAffectingCombat(unit): a plain boolean (no secret annotation on
--     either client). The player's is stub.in_combat. Another unit's is its
--     stub.units combat field where a test sets one (a secret value too),
--     else whether it has a threat list in stub.threat with anyone on it: a
--     mob has a threat list only while it's in combat.
--   stub.apply_client(): drops the globals stub.interface's client doesn't
--     have (CLIENT_ONLY below), as T.client (tests/lib/theme_helpers.lua)
--     does after setting the interface. A world whose interface a test sets
--     by hand calls it too, if the code it runs looks a global up.
stub.threat = {}
stub.secret_threat = {}
stub.group = nil
stub.role = nil
stub.tank_aura = {}

do
	-- The unit's entry on mob's threat list: status, percent and isTanking,
	-- or nil when it isn't on the list.
	local function threat_entry(fn, unit, mob)
		if type(unit) ~= 'string' or type(mob) ~= 'string' then
			error(('Usage: %s(unit, mobGUID): only the form with a mob is stubbed'):format(fn), 3)
		end
		local list = stub.threat[mob]
		local entry = list and list[unit]
		if entry == nil then return nil end
		if type(entry) == 'table' then return entry.status, entry.percent, entry.isTanking end
		return entry, nil, nil
	end

	-- UnitThreatSituation(unit, mob): the unit's status on the mob's threat
	-- list, nil when it isn't on it (its result is Nilable).
	function UnitThreatSituation(unit, mob)
		return (threat_entry('UnitThreatSituation', unit, mob))
	end

	-- UnitDetailedThreatSituation(unit, mob): isTanking, status,
	-- scaledPercentage, rawPercentage, rawThreat; nothing when the unit isn't
	-- on the list (MayReturnNothing). isTanking is status 2 or 3 unless the
	-- entry gives one. A secret status gives itself as isTanking and as the
	-- percent where none is given, since nothing can be worked out from it.
	-- rawPercentage is the scaled percent here and rawThreat 0: SaftUI reads
	-- neither.
	function UnitDetailedThreatSituation(unit, mob)
		local status, percent, isTanking = threat_entry('UnitDetailedThreatSituation', unit, mob)
		if status == nil then return end
		local tanking
		if issecretvalue and issecretvalue(status) then
			tanking = status
			if percent == nil then percent = status end
		else
			tanking = status == 2 or status == 3
			if percent == nil then percent = tanking and 100 or 0 end
		end
		if isTanking ~= nil then tanking = isTanking end
		return tanking, status, percent, percent, 0
	end

	function UnitAffectingCombat(unit)
		if type(unit) ~= 'string' then error('Usage: local result = UnitAffectingCombat(unit)', 2) end
		if unit == 'player' then return stub.in_combat end
		local other = OtherUnit(unit)
		if other and other.combat ~= nil then return other.combat end
		local list = stub.threat[unit]
		return list ~= nil and next(list) ~= nil
	end

	C_Secrets = C_Secrets or {}
	-- C_Secrets.ShouldUnitThreatStateBeSecret(unit[, mobUnit]): "true if
	-- queries for unit threat status will produce secret values". A plain
	-- boolean.
	function C_Secrets.ShouldUnitThreatStateBeSecret(unit, mob)
		if type(unit) ~= 'string' then
			error('Usage: local isUnitThreatSecret = C_Secrets.ShouldUnitThreatStateBeSecret(unit [, mobUnit])', 2)
		end
		local secret = mob and stub.secret_threat[mob]
		if secret == true then return true end
		return type(secret) == 'table' and secret[unit] == true
	end

	-- C_Secrets.ShouldAurasBeSecret(): "true if queries for aura data will
	-- generally produce secret values". In game it's false out of combat and
	-- true in combat (.agents/clients.md), so here it's InCombatLockdown().
	function C_Secrets.ShouldAurasBeSecret() return InCombatLockdown() == true end

	-- IsInGroup([groupType]) and IsInRaid([groupType]): plain booleans from
	-- stub.group. The group type (home or instance group) isn't modelled.
	function IsInGroup() return stub.group ~= nil end
	function IsInRaid() return stub.group ~= nil and stub.group.raid == true end
	-- GetNumGroupMembers(): the group's size, the player counted: 0 on their
	-- own, a party's members and the player, a raid's members (the player is
	-- one of them).
	function GetNumGroupMembers()
		local group = stub.group
		if not group then return 0 end
		local members = #(group.members or {})
		return group.raid and members or members + 1
	end

	-- UnitGroupRolesAssigned(unit): the role the unit was given in the group
	-- ('TANK', 'HEALER', 'DAMAGER'), 'NONE' without one, and for a unit that
	-- isn't there. A test can make a role secret, as restricted content can
	-- (SecretWhenUnitIdentityRestricted).
	function UnitGroupRolesAssigned(unit)
		unit = unit or 'player'
		if unit == 'player' then return stub.role or 'NONE' end
		local other = OtherUnit(unit)
		return other and other.role or 'NONE'
	end

	-- UnitHasEffectivelyTankAura(unit): whether the unit has an aura that
	-- makes it a tank (a tanking stance or form). Only Forever has it: its
	-- UnitDocumentation.lua lists it and retail's doesn't, so a retail world
	-- has no such global (stub.apply_client), and one that still has it,
	-- its interface set by hand, errors on a call as a missing global does.
	function UnitHasEffectivelyTankAura(unit)
		if stub.interface ~= 16001 then
			error("attempt to call global 'UnitHasEffectivelyTankAura' (a nil value): retail has no such function", 2)
		end
		local aura = stub.tank_aura[unit]
		if aura == nil then return false end
		return aura
	end

	-- The globals only one client has, by name: the interface that has it.
	local CLIENT_ONLY = { UnitHasEffectivelyTankAura = 16001 }
	-- The members of a namespace table only one client has: { table, name,
	-- interface }. C_QuestLog's two are in Forever's QuestLogDocumentation.lua
	-- and not in retail's (tests/wow/quests.lua adds them).
	Constants = Constants or {}
	local CLIENT_ONLY_MEMBERS = {
		{ Constants, 'QuestLogConstsMainlineCamelot', 16001 },
		{ C_QuestLog, 'IsEliteQuest', 16001 },
		{ C_QuestLog, 'GetQuestTimers', 16001 },
	}
	function stub.apply_client()
		for name, interface in pairs(CLIENT_ONLY) do
			if stub.interface ~= interface then _G[name] = nil end
		end
		for _, member in ipairs(CLIENT_ONLY_MEMBERS) do
			if stub.interface ~= member[3] then member[1][member[2]] = nil end
		end
	end

	-- UnitExists(unit): true for the player and the stub.units units, false
	-- for a unit that isn't there.
	function UnitExists(unit)
		return unit == 'player' or OtherUnit(unit) ~= nil
	end
end

-- The quest log's API (SaftUI-Tracker's tests): stub.quests, C_QuestLog's
-- functions and the old quest globals.
load_test_file('wow/quests.lua')
