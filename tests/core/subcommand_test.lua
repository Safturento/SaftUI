-- Config:AddSubcommand (Config/config.lua): '/sui <word> <the rest>' runs the function added for the word with the
-- rest of the line (trimmed, lowercase), with no button in /sui; a command that takes words after it (the unit
-- frames' '/sui uf restore'). A word with nothing added falls through to the commands and to /sui itself.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (core/config_helpers.lua).

local function fresh()
	reset_world()
	SaftUI_DB = nil
	load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
	load_saftui('SaftUI-Core/Libraries/LibBase64-1.0/LibBase64-1.0.lua')
	load_saftui('SaftUI-Core/Libraries/LibCompress/LibCompress.lua')
	load_saftui('SaftUI-Core/Libraries/Ace3/AceSerializer-3.0/AceSerializer-3.0.lua')
	load_test_file('core/config_helpers.lua')
	load_string_format()
	return SaftUI
end

test("a subcommand gets the rest of the line, trimmed and lowercase, and has no sidebar button", function()
	local st = fresh()
	local got = {}
	st.Config:AddSubcommand('Uf', function(rest) got[#got + 1] = rest end)
	SlashCmdList.SAFTUI('uf restore Confirm ')
	SlashCmdList.SAFTUI('  UF   share')
	SlashCmdList.SAFTUI('uf')
	eq(table.concat(got, '|'), 'restore confirm|share|', 'the rest, once for each line')
	eq(#st.Config:GetCommands(), 0, 'no button')
end)

test('a word with no subcommand falls through to the commands', function()
	local st = fresh()
	local ran = 0
	st.Config:AddCommand('kb', 'Key bindings', function() ran = ran + 1 end)
	st.Config:AddSubcommand('uf', function() end)
	SlashCmdList.SAFTUI('kb')
	eq(ran, 1, 'the command still runs')
end)
