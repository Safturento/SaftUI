-- SaftUI-ActionBars/keybindmode.lua registers /sui kb with Config:AddCommand
-- and the keyboard icon, which the collapsed /sui footer shows for it. Real:
-- Core's Config (config_helpers.lua) and the file itself.
load_test_file('core/config_helpers.lua')
local st = SaftUI
st:NewModule('ActionBars')

test('Keybind mode is the command kb, with the keyboard icon', function()
	load_saftui('SaftUI-ActionBars/keybindmode.lua')
	local commands = st.Config:GetCommands()
	eq(commands[#commands].command, 'kb')
	eq(commands[#commands].label, 'Keybind mode')
	eq(commands[#commands].icon, st.icons.keyboard, "the footer's icon")
end)
