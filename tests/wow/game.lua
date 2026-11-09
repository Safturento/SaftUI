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
	loaded_addons = {}, -- C_AddOns.IsAddOnLoaded: a set, e.g. stub.loaded_addons.RXPGuides = true
	-- The player's experience: GetMaxPlayerLevel, UnitLevel('player'), UnitXP,
	-- UnitXPMax and GetXPExhaustion (rested experience; nil for none).
	max_level = 80,
	level = 20,
	xp = 450,
	xp_max = 1000,
	rested_xp = nil,
}

-- Only the interface number means anything here.
function GetBuildInfo()
	return '0.0.0', '0', 'Jan 1 2026', stub.interface
end

function GetLocale() return 'enUS' end
function GetPhysicalScreenSize() return stub.screen_width, stub.screen_height end
function InCombatLockdown() return stub.in_combat end
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

function GetCurrentKeyBoardFocus() return nil end -- no edit box has focus

-- The player: a human warrior named Tester on Testrealm. Other units don't
-- exist, so they give nil, as the game does for a unit that isn't there.
function UnitName(unit)
	if unit == 'player' then return 'Tester', nil end
end
function UnitClass(unit)
	if unit == 'player' then return 'Warrior', 'WARRIOR', 1 end
end
function UnitRace(unit)
	if unit == 'player' then return 'Human', 'Human', 1 end
end
function UnitFactionGroup(unit)
	if unit == 'player' then return 'Alliance', 'Alliance' end
end
function GetRealmName() return 'Testrealm' end

-- Experience. The player's level is stub.level; other units don't exist.
function GetMaxPlayerLevel() return stub.max_level end
function UnitLevel(unit)
	if unit == 'player' then return stub.level end
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
