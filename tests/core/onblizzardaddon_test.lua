-- st:OnBlizzardAddon (SaftUI-Core/api.lua): runs a function at once if a
-- Blizzard addon is loaded, otherwise once when that addon's ADDON_LOADED
-- fires. One shared event frame, made on the first wait; it stays registered
-- only while a wait is left.
--
-- Real: Core's helpers (api.lua). The event frame is found by wrapping
-- CreateFrame around the first wait.
load_core_helpers()
local st = SaftUI

local made = {}
local createFrame = CreateFrame
CreateFrame = function(...)
	local frame = createFrame(...)
	made[#made + 1] = frame
	return frame
end

local function registered()
	local count = 0
	for _, frame in ipairs(made) do
		if stub.state(frame).events.ADDON_LOADED then count = count + 1 end
	end
	return count
end

local function reset()
	stub.loaded_addons = {}
	take_errors()
end

test('an addon that is loaded already: fn runs at once, nothing is registered', function()
	reset()
	stub.loaded_addons.Blizzard_One = true
	local before = registered()
	local ran = 0
	st:OnBlizzardAddon('Blizzard_One', function() ran = ran + 1 end)
	eq(ran, 1, 'ran at once')
	eq(registered(), before, 'no event registered')
	stub.fire_event('ADDON_LOADED', 'Blizzard_One')
	eq(ran, 1, 'and not again')
end)

test('an addon not loaded: fn runs once on its event, not on another addon\'s', function()
	reset()
	local ran = 0
	st:OnBlizzardAddon('Blizzard_Two', function() ran = ran + 1 end)
	eq(ran, 0, 'not yet')
	eq(registered(), 1, 'one frame hears ADDON_LOADED')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Other')
	eq(ran, 0, 'another addon loading does nothing')
	eq(registered(), 1, 'the wait is still on')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Two')
	eq(ran, 1, 'ran when it loaded')
	eq(registered(), 0, 'nothing registered once no wait is left')
end)

test('fn runs once even if the event fires twice for the name', function()
	reset()
	local ran = 0
	st:OnBlizzardAddon('Blizzard_Three', function() ran = ran + 1 end)
	stub.fire_event('ADDON_LOADED', 'Blizzard_Three')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Three')
	eq(ran, 1, 'once')
end)

test('two waits on one addon both run, in the order they were made', function()
	reset()
	local order = {}
	st:OnBlizzardAddon('Blizzard_Four', function() order[#order + 1] = 'a' end)
	st:OnBlizzardAddon('Blizzard_Four', function() order[#order + 1] = 'b' end)
	stub.fire_event('ADDON_LOADED', 'Blizzard_Four')
	eq(table.concat(order, ','), 'a,b', 'both, in order')
end)

test('waits on two addons: the frame stays registered until the last is done', function()
	reset()
	local ran = {}
	st:OnBlizzardAddon('Blizzard_Five', function() ran.five = true end)
	st:OnBlizzardAddon('Blizzard_Six', function() ran.six = true end)
	stub.fire_event('ADDON_LOADED', 'Blizzard_Five')
	check(ran.five and not ran.six, 'only the first ran')
	eq(registered(), 1, 'still registered for the second')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Six')
	check(ran.six, 'the second ran')
	eq(registered(), 0, 'unregistered')
	st:OnBlizzardAddon('Blizzard_Seven', function() ran.seven = true end)
	eq(registered(), 1, 'a later wait registers it again')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Seven')
	check(ran.seven, 'and it runs')
	eq(registered(), 0, 'and unregisters')
end)

test('the event for an addon nobody waits on does nothing', function()
	reset()
	stub.fire_event('ADDON_LOADED', 'NobodyWaits')
	eq(#take_errors(), 0, 'no error')
	eq(registered(), 0, 'nothing registered')
end)

test('an error in one waiting fn is reported and the others still run', function()
	reset()
	local ran = {}
	st:OnBlizzardAddon('Blizzard_Eight', function() ran.a = true end)
	st:OnBlizzardAddon('Blizzard_Eight', function() error('boom', 0) end)
	st:OnBlizzardAddon('Blizzard_Eight', function() ran.c = true end)
	stub.fire_event('ADDON_LOADED', 'Blizzard_Eight')
	check(ran.a and ran.c, 'the others ran')
	local errors = take_errors()
	eq(#errors, 1, 'one error reported to the error handler')
	check(tostring(errors[1]):find('boom'), 'the error is the one raised')
	eq(registered(), 0, 'the frame is not left registered')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Eight')
	check(#take_errors() == 0, 'the failed fn does not run again')
end)

test('a waiting fn can wait again, on another addon or on the same one', function()
	reset()
	local log = {}
	st:OnBlizzardAddon('Blizzard_Nine', function()
		log[#log + 1] = 'nine'
		st:OnBlizzardAddon('Blizzard_Ten', function() log[#log + 1] = 'ten' end)
		-- Loaded by now (the game says so during its own ADDON_LOADED): at once.
		st:OnBlizzardAddon('Blizzard_Nine', function() log[#log + 1] = 'nine again' end)
	end)
	stub.loaded_addons.Blizzard_Nine = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_Nine')
	eq(table.concat(log, ','), 'nine,nine again', 'the same addon, loaded: at once, once')
	eq(registered(), 1, 'the new wait on the other addon is kept')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Ten')
	eq(table.concat(log, ','), 'nine,nine again,ten', 'and runs when it loads')
	eq(registered(), 0, 'nothing left')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Nine')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Ten')
	eq(#log, 3, 'nothing ran twice')
end)

test('a waiting fn that waits again on its own addon before it is loaded is kept, not lost', function()
	reset()
	local ran = 0
	st:OnBlizzardAddon('Blizzard_Eleven', function()
		ran = ran + 1
		if ran == 1 then
			st:OnBlizzardAddon('Blizzard_Eleven', function() ran = ran + 10 end)
		end
	end)
	stub.fire_event('ADDON_LOADED', 'Blizzard_Eleven')
	eq(ran, 1, 'the first ran')
	eq(registered(), 1, 'the new wait is registered')
	stub.fire_event('ADDON_LOADED', 'Blizzard_Eleven')
	eq(ran, 11, 'the new wait ran on the next event, once')
	eq(registered(), 0, 'done')
end)

test('one event frame serves every wait', function()
	reset()
	local frames = #made
	st:OnBlizzardAddon('Blizzard_A', function() end)
	st:OnBlizzardAddon('Blizzard_B', function() end)
	st:OnBlizzardAddon('Blizzard_C', function() end)
	eq(#made, frames, 'no frame made after the first wait')
	stub.fire_event('ADDON_LOADED', 'Blizzard_A')
	stub.fire_event('ADDON_LOADED', 'Blizzard_B')
	stub.fire_event('ADDON_LOADED', 'Blizzard_C')
	eq(#made, frames, 'nor after the waits are done')
end)
