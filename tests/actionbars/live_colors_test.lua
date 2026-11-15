-- The action buttons follow the colors that reach them as they are picked
-- (live colors, SaftUI-ActionBars/skin.lua's AB:OnColorsChanged): Buttons >
-- Danger is the attack flash's tint, drawn only under SaftUI's flat look (Thick
-- and Thin; under Blizzard the flash is Blizzard's art), and the Accent is the
-- border of a button that holds an equipped item. A pass only colors a region
-- of SaftUI's own button, so it runs in combat on the secure buttons too.
--
-- The world is layout_test.lua's: the action bars' files but hideblizzard.lua
-- and keybindmode.lua, buttons as LibActionButton makes them, skinned by
-- AB:SkinButton and styled by AB:StyleButton. 12 bars of 12 buttons and the pet
-- and stance bars of 10 are 164 buttons.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')

local FILES = {
	'SaftUI-ActionBars/init.lua',
	'SaftUI-ActionBars/shared.lua',
	'SaftUI-ActionBars/skin.lua',
	'SaftUI-ActionBars/bars.lua',
	'SaftUI-ActionBars/buttons.lua',
	'SaftUI-ActionBars/petbar.lua',
	'SaftUI-ActionBars/stancebar.lua',
	'SaftUI-ActionBars/bindings.lua',
	'SaftUI-ActionBars/extras.lua',
	'SaftUI-ActionBars/textoptions.lua',
	'SaftUI-ActionBars/options.lua',
}

local st, AB, LAB

local function fresh()
	reset_world()
	load_core_helpers()
	st = SaftUI
	LAB = load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	apply_defaults()
	for _, file in ipairs(FILES) do load_saftui(file) end
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	stub.cvars.countdownForCooldowns = '1'
	function LAB:GetSpellFlyoutFrame() end
	AB:ConvertProfile()
end

-- A button as LibActionButton makes one, skinned by AB:SkinButton.
local function button(name)
	local b = CreateFrame('CheckButton', name, UIParent)
	b.icon = b:CreateTexture(nil, 'BACKGROUND')
	b.Flash = b:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		b[key] = b:CreateFontString(nil, 'OVERLAY')
		b[key]:SetFontObject(GameFontNormal)
	end
	b.cooldown = CreateFrame('Cooldown', nil, b)
	function b:UpdateConfig(config) self.labConfig = config end
	function b:IsEquipped() return self.equipped end
	AB:SkinButton(b)
	return b
end

-- The 164 buttons, styled in theme (a button's skin is made once, then styled).
local function world(theme)
	fresh()
	local config = AB:GetBarConfig('bar1')
	local buttons = {}
	for i = 1, 164 do
		local b = button('LiveColorsButton' .. i)
		AB:StyleButton(b, config, theme, 'solid')
		buttons[i] = b
	end
	return buttons, config
end

local function flash(b)
	local c = stub.state(b.Flash).color_texture
	return c and T.rgb(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4]) or 'none'
end

local DANGER = { 0.9, 0.2, 0.3 }

test("Buttons > Danger: every button's flash once under Thick and Thin (164 SetColorTexture), none under Blizzard", function()
	for _, theme in ipairs({ 'thick', 'thin' }) do
		local buttons = world(theme)
		st.config.profile.colors.button.danger:SetRGB(unpack(DANGER))
		local m = C.measure(function() st:ColorChanged('button', 'danger') end)
		eq(m.calls.by.SetColorTexture, 164, theme .. ': the flash of every button')
		eq(m.forbidden.total, 0, theme .. ': nothing forbidden')
		eq(m.made, 0, theme .. ': nothing made')
		for _, i in ipairs({ 1, 80, 164 }) do
			eq(flash(buttons[i]), T.rgb(unpack(DANGER)) .. ' 0.40', theme .. ': at 0.4 in Danger')
		end
		-- The whole group's pass reaches it too, and another key of the group does not.
		st.config.profile.colors.button.danger:SetRGB(0.2, 0.9, 0.3)
		m = C.measure(function() st:ColorChanged('button', 'hover') end)
		eq(m.calls.by.SetColorTexture, nil, theme .. ': Hover is not the flash')
		st:ColorsChanged('button')
		eq(flash(buttons[7]), T.rgb(0.2, 0.9, 0.3) .. ' 0.40', theme .. ': a whole pass')
	end

	local buttons = world('blizzard')
	local m = C.measure(function() st:ColorChanged('button', 'danger') end)
	eq(m.calls.by.SetColorTexture, nil, "Blizzard: the flash is Blizzard's art, not colored")
	eq(m.forbidden.total, 0)
	eq(flash(buttons[1]), 'none')
end)

test("a button's flash stays what it is across a restyle that changes the look", function()
	local buttons, config = world('thick')
	st.config.profile.colors.button.danger:SetRGB(unpack(DANGER))
	AB:StyleButton(buttons[1], config, 'blizzard', 'solid')
	st:ColorChanged('button', 'danger')
	check(flash(buttons[1]) ~= T.rgb(unpack(DANGER)) .. ' 0.40', 'under Blizzard it is not tinted')
	AB:StyleButton(buttons[1], config, 'thin', 'solid')
	eq(flash(buttons[1]), T.rgb(unpack(DANGER)) .. ' 0.40', 'under Thin again it is')
end)

local function border(b)
	return T.rgb(b.backdrop:GetBackdropBorderColor())
end

test('the Accent: the equipped buttons borders only', function()
	local buttons = world('thick')
	for i = 1, 164, 4 do
		buttons[i].equipped = true
		AB:UpdateEquippedBorder(buttons[i])
	end
	local plain = border(buttons[2])
	st.config.profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	local m = C.measure(function() st:ColorChanged('accent') end)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	eq(m.calls.by.SetBackdropBorderColor, 41, 'the 41 equipped buttons, no others')
	eq(border(buttons[1]), T.rgb(0.3, 0.9, 0.6), 'an equipped button takes the Accent')
	eq(border(buttons[2]), plain, 'another keeps the theme border')
	eq(m.calls.by.SetColorTexture, nil, 'the flash is not touched')
end)

test('in combat the same calls, and none forbidden on a secure button (Review Focus 4)', function()
	local buttons = world('thick')
	for i = 1, 164, 4 do
		buttons[i].equipped = true
		AB:UpdateEquippedBorder(buttons[i])
	end
	st.config.profile.colors.button.danger:SetRGB(unpack(DANGER))
	st.config.profile.theme.accent:SetRGB(0.8, 0.4, 0.1)
	stub.in_combat = true
	local m = C.measure(function() st:ColorChanged('button', 'danger') end, 100)
	eq(m.calls.by.SetColorTexture, 16400, 'the same 164 a pass')
	eq(m.forbidden.total, 0, 'nothing forbidden in combat')
	eq(m.made, 0)
	check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
	C.print('action bars, danger', m)
	local a = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(a.forbidden.total, 0, 'the Accent in combat')
	check(a.kb < 4, 'garbage over 100 Accent passes: ' .. a.kb .. ' KB')
	C.print('action bars, accent', a)
	stub.in_combat = false
	eq(#stub.blocked, 0, 'nothing blocked')
end)
