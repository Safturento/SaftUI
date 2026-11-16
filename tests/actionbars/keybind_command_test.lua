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

-- The binder marks the button being bound: it is selected (the Accent edge and
-- the fade), not hovered (the interaction states' call 11).
test("keybind mode's highlight is the selected look over the button it marks", function()
	local SL = load_test_file('lib/states_look.lua')
	local AB = st:GetModule('ActionBars')
	local mark = CreateFrame('Button', nil, UIParent)
	mark:SetSize(40, 40)
	mark:SetPoint('CENTER')
	function mark:HasAction() return true end
	AB.built, AB.bars = true, { bar1 = { buttons = { mark } } }
	function AB:GetBindingCommand() return 'ACTIONBUTTON1' end
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
	check(binder, 'the binder is made')
	eq(st:GetState(binder, 'selected'), false, 'not selected until it marks a button')
	check(binder.highlight == nil, 'no hand-drawn highlight texture')
	stub.fire_script(mark, 'OnEnter')
	eq(binder:IsShown(), true, 'it shows over the button')
	eq(st:GetState(binder, 'selected'), true, 'selected while it marks one')
	eq(st:GetState(binder, 'hover'), false, 'not hovered')
	local look = st:StateLook(binder)
	eq(look.fill.shown, true, 'the fade shows')
	eq(look.fill.texture, st.textures.stateFade)
	eq(SL.rgb(look.fill), '0.90,0.20,0.40', 'the Fill is the Accent')
	eq(string.format('%.2f', look.fill.a), '0.24', 'at its strength')
	eq(SL.rgb(look.edge), '0.90,0.20,0.40', 'the edge is the Accent')
	eq(look.blizzard, false)
	-- under Blizzard the binder is still SaftUI's own look: it marks a button there too
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	eq(st:StateLook(binder).fill.shown, true, 'its look is its own under Blizzard')
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	-- leaving the button
	binder:GetScript('OnLeave')(binder)
	eq(st:GetState(binder, 'selected'), false, 'not selected once it leaves')
	eq(st:StateLook(binder).fill.shown, false, 'the fade goes')
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	AB:StopKeybindMode()
end)

-- The hint line under the key list reads Text > Muted when the tooltip shows,
-- not a grey of its own: a Muted that is not the default shows in it.
test("keybind mode's hint line is Muted, read when the tooltip shows", function()
	local AB = st:GetModule('ActionBars')
	AB.built, AB.bars = true, {}
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	AB.SetForceShown = function() end
	AB:StartKeybindMode()
	local binder
	for i = 1, 40 do
		local name, value = debug.getupvalue(AB.StartKeybindMode, i)
		if not name then break end
		if name == 'binder' then binder = value end
	end
	check(binder, 'the binder is made')
	binder.button = CreateFrame('Frame', nil, UIParent)
	local muted = st.config.profile.colors.text.muted
	local function hint()
		GameTooltip:ClearLines()
		binder:GetScript('OnEnter')(binder)
		local c = stub.state(GameTooltip).colors[3]
		return c and string.format('%.2f,%.2f,%.2f', c[1], c[2], c[3])
	end
	local realKey = _G.GetBindingKey
	_G.GetBindingKey = function() end -- the button has no command
	muted:SetRGB(0.2, 0.4, 0.6)
	eq(hint(), '0.20,0.40,0.60', 'Muted at a value that is not the default')
	muted:SetRGB(0.8, 0.1, 0.3)
	eq(hint(), '0.80,0.10,0.30', 'a changed Muted reaches the next show')
	_G.GetBindingKey = realKey
	AB:StopKeybindMode()
end)
