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

-- The binder's highlight over the hovered button is the accent at 40%.
test("keybind mode's highlight is the accent, at an accent that is not the default", function()
	local AB = st:GetModule('ActionBars')
	AB.built, AB.bars = true, {}
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	AB.SetForceShown = function() end
	st.config.profile.theme.accent:SetRGB(0.9, 0.2, 0.4)
	AB:StartKeybindMode()
	local binder
	for i = 1, 40 do
		local name, value = debug.getupvalue(AB.StartKeybindMode, i)
		if not name then break end
		if name == 'binder' then binder = value end
	end
	check(binder and binder.highlight, 'the binder is made')
	local r, g, b, a = binder.highlight:GetVertexColor()
	eq(string.format('%.2f,%.2f,%.2f,%.2f', r, g, b, a), '0.90,0.20,0.40,0.40', 'the accent at 40%')
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	AB:StopKeybindMode()
end)
