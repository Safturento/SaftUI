-- SaftUI-Misc/movable.lua makes Blizzard's windows movable. A window of a
-- load-on-demand addon (TransmogFrame, in Blizzard_Transmog on both clients,
-- checked in Blizzard's source) is made movable when its addon loads, and the
-- module prints nothing about a window that isn't there yet.
--
-- Real: movable.lua and Core's st:EnableMoving. Blizzard's windows are plain
-- frames here.
load_saftui('SaftUI-Misc/movable.lua')

local st = SaftUI
local MV = st:GetModule('Movable')

local function window(name)
	return CreateFrame('Frame', name, UIParent)
end

-- Runs fn with print recorded, and gives back what it printed.
local function printed_by(fn)
	local real, lines = print, {}
	print = function(...) lines[#lines + 1] = table.concat({ ... }, ' ') end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

local settings, addons, transmog

test('windows there at login are movable, and the load-on-demand one waits without a print', function()
	settings, addons = window('SettingsPanel'), window('AddonList')
	local lines = printed_by(function() MV:Enable() end)
	eq(#take_errors(), 0, 'no errors')
	check(settings:IsMovable() and addons:IsMovable(), 'SettingsPanel and AddonList are movable')
	check(_G.TransmogFrame == nil, 'TransmogFrame is not there yet')
	eq(#lines, 0, 'nothing printed')
end)

test("TransmogFrame is movable once Blizzard_Transmog loads, and another addon's load does nothing", function()
	stub.fire_event('ADDON_LOADED', 'Blizzard_SomethingElse')
	eq(#take_errors(), 0, 'no errors')
	transmog = window('TransmogFrame')
	stub.fire_event('ADDON_LOADED', 'Blizzard_SomethingElse')
	check(not transmog:IsMovable(), "another addon's load leaves it")
	local lines = printed_by(function() stub.fire_event('ADDON_LOADED', 'Blizzard_Transmog') end)
	eq(#take_errors(), 0, 'no errors')
	check(transmog:IsMovable(), 'movable when Blizzard_Transmog loads')
	eq(#lines, 0, 'nothing printed')
end)

test('Blizzard_Transmog loading again does not make it movable twice', function()
	local real, calls = st.EnableMoving, 0
	st.EnableMoving = function(...) calls = calls + 1; return real(...) end
	stub.fire_event('ADDON_LOADED', 'Blizzard_Transmog')
	st.EnableMoving = real
	eq(calls, 0, 'EnableMoving not called again')
	eq(#take_errors(), 0, 'no errors')
end)
