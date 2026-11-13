-- '/sui debug' (Config/config.lua's slash handler): turns SaftUI's debug prints
-- (st:Debug) on and off, says which in chat, and saves the choice account-wide
-- (SaftUI_DB.global.debug) so a reload in the middle of a run keeps it:
--   - off by default, and a command of another case or with spaces still works;
--   - the print is what flips, and st:Debug prints only while it's on;
--   - the state is read back at login (Config:InitializeAceConfig), from the
--     saved variables, and turning it off clears it.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (core/config_helpers.lua)
-- and api.lua's st:Print and st:Debug, with LibStringFormat-1.0.

local function fresh(saved)
	reset_world()
	SaftUI_DB = saved
	load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
	load_saftui('SaftUI-Core/Libraries/LibBase64-1.0/LibBase64-1.0.lua')
	load_saftui('SaftUI-Core/Libraries/LibCompress/LibCompress.lua')
	load_saftui('SaftUI-Core/Libraries/Ace3/AceSerializer-3.0/AceSerializer-3.0.lua')
	load_test_file('core/config_helpers.lua')
	load_string_format() -- st:Debug colours its label with it
	return SaftUI
end

-- The lines printed while fn runs.
local function printed_by(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		table.insert(lines, table.concat(parts, ' '))
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

test('/sui debug flips the debug prints, says the new state and saves it', function()
	local st = fresh()
	eq(st.DEBUG, false, 'off by default')
	eq(st.config.global.debug, nil, 'nothing saved')

	local lines = printed_by(function() SlashCmdList.SAFTUI('debug') end)
	eq(st.DEBUG, true, 'on')
	eq(#lines, 1, 'one line printed')
	check(lines[1] and lines[1]:find('Debug prints on', 1, true), 'saying on: ' .. tostring(lines[1]))
	eq(st.config.global.debug, true, 'saved account-wide')

	lines = printed_by(function() SlashCmdList.SAFTUI('  Debug ') end)
	eq(st.DEBUG, false, 'off again, whatever the case and spaces')
	check(lines[1] and lines[1]:find('Debug prints off', 1, true), 'saying off: ' .. tostring(lines[1]))
	eq(st.config.global.debug, nil, 'and the save cleared')
end)

test('st:Debug prints only while debug is on', function()
	local st = fresh()
	eq(#printed_by(function() st:Debug('Loot', 'a line') end), 0, 'off: nothing')
	SlashCmdList.SAFTUI('debug')
	local lines = printed_by(function() st:Debug('Loot', 'a line') end)
	eq(#lines, 1, 'on: one line')
	check(lines[1]:find('Loot', 1, true) and lines[1]:find('a line', 1, true), 'naming its module')
end)

test('the choice survives a reload: it is read back at login', function()
	local st = fresh()
	SlashCmdList.SAFTUI('debug')
	local saved = SaftUI_DB
	check(saved and saved.global and saved.global.debug == true, 'the saved variables hold it')

	st = fresh(saved)
	eq(st.DEBUG, true, 'on after a reload')
	SlashCmdList.SAFTUI('debug')
	st = fresh(SaftUI_DB)
	eq(st.DEBUG, false, 'and off once turned off')
end)
