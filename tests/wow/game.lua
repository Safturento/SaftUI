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
	-- The calls the game blocked on a protected frame in combat (widgets.lua,
	-- "Protected frames in combat"), in order: { widget, method name }. The
	-- game fires ADDON_ACTION_BLOCKED for each.
	blocked = {},
	cursor_x = 0, -- GetCursorPosition, in screen units (UIParent's units times its scale)
	cursor_y = 0,
	time = 0, -- GetTime, in seconds
	-- C_Timer.After's pending callbacks, { due, fn } in the order made.
	-- stub.run_timers() runs the ones due by stub.time.
	timers = {},
	epoch = 1800000000, -- time(), in seconds since 1970
	shift_down = false, -- IsShiftKeyDown
	ctrl_down = false, -- IsControlKeyDown
	alt_down = false, -- IsAltKeyDown
	mouse_buttons = {}, -- IsMouseButtonDown: a set, e.g. stub.mouse_buttons.LeftButton = true
	-- What the cursor holds, for GetCursorInfo: nil for nothing, or an item
	-- picked up from a bag, { id, link }. ClearCursor drops it.
	cursor_item = nil,
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
}
-- Runs, in the order they were made, the timers due by stub.time (callbacks
-- they make that are due run too). Returns how many ran.
function stub.run_timers()
	local ran = 0
	local i = 1
	while i <= #stub.timers do
		local timer = stub.timers[i]
		if timer.due <= stub.time then
			table.remove(stub.timers, i)
			ran = ran + 1
			timer.fn()
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
--     again (which must be free). opts.forbidden makes it a forbidden plate,
--     which C_NamePlate gives addon code only when it asks for forbidden ones
--     (it can't: Blizzard's own driver passes issecure()); whether the game
--     fires NAME_PLATE_UNIT_ADDED to addons for a forbidden plate isn't known,
--     so the stub fires it, the stricter case. opts.widgets_only and
--     opts.game_object are UnitNameplateShowsWidgetsOnly's and
--     UnitIsGameObject's answers for the unit (a capture bar, a quest object).
--     Each add hands the plate a new pooled Blizzard UnitFrame (a Button) with
--     its WidgetContainer (hidden) and SoftTargetFrame children, set with
--     rawset as Blizzard's pool and template do.
--   stub.remove_nameplate(unit): the game takes the unit's plate away:
--     Blizzard's driver takes its UnitFrame back (hidden, its points cleared,
--     as a frame pool resets one), NAME_PLATE_UNIT_REMOVED fires, and the
--     plate hides and is free.
--   stub.set_nameplate_size_secure(width, height): sets the size even in
--     combat, as Blizzard's untainted code can (NamePlateDriverFrame's
--     UpdateNamePlateSize, blizzard.lua).
--   stub.on_nameplate_frame: nil, or a function the stub calls with each
--     Blizzard frame it makes for the plates (a plate, and each pooled
--     UnitFrame with its WidgetContainer and SoftTargetFrame) once it is set
--     up, so a test can lock them as Blizzard's (misc/fixtures/locked_widget.lua).
-- Not mimicked: script nameplates, the personal resource display, plates the
-- game makes before an add (NAME_PLATE_CREATED), FORBIDDEN_NAME_PLATE_UNIT_ADDED
-- and its remove, a plate's place on screen (each sits at the WorldFrame's
-- centre), and units other than nameplateN and the target.
stub.nameplate_size = nil
stub.nameplate_target = nil
stub.on_nameplate_frame = nil

do
	local plates = {}  -- by number: { frame, unit, forbidden, widgets_only, game_object }
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
			if stub.nameplate_size then frame:SetSize(stub.nameplate_size[1], stub.nameplate_size[2]) end
			frame:Hide()
			record = { frame = frame }
			plates[n] = record
			made(frame)
		end
		record.unit = unit
		record.forbidden = opts.forbidden == true
		record.widgets_only = opts.widgets_only == true
		record.game_object = opts.game_object == true
		byUnit[unit] = record

		-- Blizzard's driver: a UnitFrame from its pool, on the plate.
		local plate = record.frame
		local unitFrame = CreateFrame('Button', nil, plate)
		unitFrame:SetAllPoints(plate)
		local widgets = CreateFrame('Frame', nil, unitFrame)
		widgets:Hide()
		local softTarget = CreateFrame('Frame', nil, unitFrame)
		rawset(unitFrame, 'WidgetContainer', widgets)
		rawset(unitFrame, 'SoftTargetFrame', softTarget)
		rawset(plate, 'UnitFrame', unitFrame)
		made(unitFrame)
		made(widgets)
		made(softTarget)

		plate:Show()
		stub.fire_event('NAME_PLATE_UNIT_ADDED', unit)
		return plate
	end

	function stub.remove_nameplate(unit)
		local record = byUnit[unit]
		assert(record, 'remove_nameplate: ' .. tostring(unit) .. ' has no plate')
		local plate = record.frame
		-- Blizzard's driver gives the UnitFrame back to its pool.
		local unitFrame = rawget(plate, 'UnitFrame')
		rawset(plate, 'UnitFrame', nil)
		unitFrame:Hide()
		unitFrame:ClearAllPoints()

		stub.fire_event('NAME_PLATE_UNIT_REMOVED', unit)
		plate:Hide()
		byUnit[unit] = nil
		record.unit, record.forbidden, record.widgets_only, record.game_object = nil, nil, nil, nil
	end
end

-- C_CVar (CVarDocumentation.lua, the same on both clients): the game's
-- settings, by name, each a string.
--
--   stub.cvars: name -> value, a string. A name not there is a setting this
--     client doesn't have. The defaults are the nameplate settings SaftUI
--     changes, at the game's defaults as far as we know them (friendly plates
--     off; the source doesn't say, so this is inferred).
--   C_CVar.GetCVar(name): stub.cvars[name], or nil for a setting the client
--     lacks (the documentation marks its return Nilable).
--   C_CVar.SetCVar(name, value): sets the string and returns true. An unknown
--     name returns false (RequiresValidAndPublicCVar). The game protects some
--     nameplate settings in combat (the documentation's RequiresNonSecureCVar,
--     and addons setting friendly plates in combat get blocked), so in combat
--     the stub refuses every setting, the strict side: noted in stub.blocked as
--     { C_CVar, name }, it returns false and changes nothing. A nil value
--     (the documentation allows one) errors: what the game makes of it isn't
--     known, and SaftUI never passes one.
stub.cvars = {
	nameplateShowFriendlyPlayers = '0',
	nameplateShowFriendlyNpcs = '0',
}

C_CVar = {}
function C_CVar.GetCVar(name)
	if type(name) ~= 'string' then error('Usage: local value = C_CVar.GetCVar(name)', 2) end
	return stub.cvars[name]
end
function C_CVar.SetCVar(name, value)
	if type(name) ~= 'string' then error('Usage: local success = C_CVar.SetCVar(name [, value])', 2) end
	if value == nil then error('C_CVar.SetCVar: a nil value is not stubbed', 2) end
	if stub.cvars[name] == nil then return false end
	if InCombatLockdown() then
		stub.blocked[#stub.blocked + 1] = { C_CVar, name }
		return false
	end
	stub.cvars[name] = tostring(value)
	return true
end
