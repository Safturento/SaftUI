-- The action bars' cooldown numbers (SaftUI-ActionBars): the Cooldown numbers
-- toggle on the Action Bars page, and each bar's font and place for them in
-- its Text tab.
--   - The toggle is Blizzard's "Show Numbers for Cooldowns" (the
--     countdownForCooldowns setting), read and set as it is: nothing goes in
--     the profile, a change in Blizzard's options shows in it, a change made
--     with it fires the CVAR_UPDATE the bars follow, and in combat it waits
--     for the end of combat.
--   - By default the numbers look as they did: SaftUI's Pixel Med font object
--     on buttons of 36px and up and Pixel below, in the middle of the button.
--     A profile saved before the options existed gets those defaults.
--   - The Text tab's Cooldown numbers (on the pet and stance bars too, not on
--     the extra buttons) set their font, size and outline and their place at
--     once, show what's drawn until they're set, and hold through
--     LibActionButton's button update, a restyle, a theme switch and a
--     profile switch, back to the defaults too. Its Reset unsets the font,
--     size and outline and puts the place back.
--   - A button styled with text settings that name no countdown (the leave
--     vehicle button's, extras.lua) gets a bar's defaults.
--   - An open /sui is told to draw again when the setting changes, and only
--     for that setting.
--
-- Real: SaftUI-ActionBars' files but hideblizzard.lua and keybindmode.lua, in
-- TOC order, over Core's helpers (load_core_helpers). Made by hand:
--   - LibActionButton-1.0, as far as the files use it when they load
--     (fixtures/libactionbutton.lua);
--   - the buttons, as LibActionButton (or buttons.lua) makes them from
--     Blizzard's ActionButtonTemplate, which the stubs don't have: check
--     buttons with the regions skin.lua styles, the template's cooldown a real
--     Cooldown, and LibActionButton's UpdateConfig;
--   - the bars, as AB:CreateBar makes them but plain frames, not secure
--     headers (SecureHandlerStateTemplate isn't stubbed), so AB:UpdateBar, what
--     every option of a bar runs, lays them out and styles them. The pet bar's
--     update also sets its buttons' secure actions (petbar.lua), which needs
--     buttons made by petbar.lua, so the pet bar is only styled (AB:StyleBar).
--     AB:Build isn't run (it needs LibActionButton's real buttons), so
--     AB.built stays false and AB:UpdateBindings does nothing; the toggle's
--     case sets it by hand, since the page is drawn only for built bars.
-- The shell's st.Config stands in for Core's Config module (tests/lib/shell.lua):
-- the toggle's case counts its Refresh, the call that redraws an open /sui.
-- A profile switch is Config:UpdateConfig's steps for the action bars: the
-- module bound to the new profile, then AB:UpdateConfig, which waits for the
-- bars to be built, so AB:UpdateBar on the bar here, as it runs it for each.
local T = load_test_file('lib/theme_helpers.lua')

local CVAR = 'countdownForCooldowns'

local FILES = {
	'SaftUI-ActionBars/init.lua',
	'SaftUI-ActionBars/skin.lua',
	'SaftUI-ActionBars/bars.lua',
	'SaftUI-ActionBars/buttons.lua',
	'SaftUI-ActionBars/petbar.lua',
	'SaftUI-ActionBars/stancebar.lua',
	'SaftUI-ActionBars/bindings.lua',
	'SaftUI-ActionBars/extras.lua',
	'SaftUI-ActionBars/options.lua',
}

local st, AB, LAB

-- A fresh world with Blizzard's setting on. saved is the action bars' part of
-- a profile saved earlier (AceDB keeps only what differs from the defaults).
local function fresh(saved)
	reset_world()
	load_core_helpers()
	st = SaftUI
	LAB = load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	if saved then st.config.profile.actionbars = saved end
	apply_defaults()
	for _, file in ipairs(FILES) do load_saftui(file) end
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	stub.cvars[CVAR] = '1'
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
	AB:SkinButton(b)
	return b
end

-- Bar id holding the buttons, then updated from the profile (see the top).
local function bar(id, ...)
	local frame = CreateFrame('Frame', AB:GetBarFrameName(id), UIParent)
	frame.id = id
	frame.buttons = { ... }
	AB.bars[id] = frame
	AB:UpdateBar(id)
	return ...
end

-- A profile switch (see the top) to profile, a profile's table.
local function switch_profile(profile)
	st.config.profile = profile
	apply_defaults()
	st:BindModuleConfig(AB, 'actionbars')
	AB:UpdateBar('bar1')
end

-- A font string's or font's font, as 'path,size,flags'.
local function font(region)
	return table.concat({ region:GetFont() }, ',')
end

local function path(name)
	return st.LSM:Fetch('font', name)
end

-- The whole of a table, as text, keys sorted.
local function dump(value)
	if type(value) ~= 'table' then return tostring(value) end
	local keys = {}
	for key in pairs(value) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local out = {}
	for _, key in ipairs(keys) do out[#out + 1] = tostring(key) .. '=' .. dump(value[key]) end
	return '{' .. table.concat(out, ',') .. '}'
end

test("Cooldown numbers is Blizzard's Show Numbers for Cooldowns, not a profile setting", function()
	fresh()
	bar('bar1', button('CooldownTestToggle'))
	AB.built = true -- see the top
	local args = AB:GetConfigTable().args
	local option = args.countdown
	eq(option.type, 'toggle', 'a toggle')
	eq(option.name, 'Cooldown numbers', 'named Cooldown numbers')
	check(option.desc:find('Show Numbers for Cooldowns', 1, true), "its tooltip names Blizzard's option")
	check(args.theme.order < option.order and args.background.order < option.order, 'after Theme and Background')

	eq(option.get(), true, 'checked while the setting is on')
	stub.cvars[CVAR] = '0'
	eq(option.get(), false, 'unchecked while it is off')

	-- LibActionButton (bars 1-8) and buttons.lua (the pet and stance bars)
	-- show or hide the numbers on CVAR_UPDATE, whoever changed the setting.
	local heard = {}
	local listener = CreateFrame('Frame')
	listener:RegisterEvent('CVAR_UPDATE')
	listener:SetScript('OnEvent', function(_, _, name, value) heard[#heard + 1] = name .. '=' .. value end)

	local before = dump(st.config.profile)
	option.set({ 'countdown' }, true)
	eq(stub.cvars[CVAR], '1', 'checked: the setting is on')
	eq(table.concat(heard, ','), CVAR .. '=1', 'and CVAR_UPDATE tells the bars, as a change in Blizzard\'s options does')
	option.set({ 'countdown' }, false)
	eq(stub.cvars[CVAR], '0', 'unchecked: off')
	eq(dump(st.config.profile), before, 'nothing is written to the profile')

	local refreshes = 0
	function st.Config:Refresh() refreshes = refreshes + 1 end
	stub.set_cvar_secure(CVAR, '1')
	eq(option.get(), true, "turned on in Blizzard's options: shown checked")
	eq(refreshes, 1, 'and an open /sui is told to draw again, once')
	stub.set_cvar_secure('nameplateShowFriendlyNpcs', '1')
	eq(refreshes, 1, 'another setting changing tells it nothing')

	stub.in_combat = true
	option.set({ 'countdown' }, false)
	eq(stub.cvars[CVAR], '1', 'unchecked in combat: not yet')
	eq(#stub.blocked, 0, 'nothing was tried in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(stub.cvars[CVAR], '0', 'set once combat ends')
	eq(#take_errors(), 0, 'no errors')
end)

test('by default the numbers look as they did: Pixel Med on buttons of 36px and up, Pixel below, in the middle', function()
	fresh()
	for _, id in ipairs(AB.BAR_IDS) do
		local countdown = AB.config[id].text.countdown
		eq(('%s %s %s,%s'):format(countdown.point, countdown.rel_point, countdown.x_off, countdown.y_off),
			'CENTER CENTER 0,0', id .. ': in the middle by default')
		eq(tostring(countdown.font) .. ',' .. tostring(countdown.size) .. ',' .. tostring(countdown.outline),
			'nil,nil,nil', id .. ': no font, size or outline of its own')
	end

	local b = bar('bar1', button('CooldownTestDefault'))
	local numbers = b.cooldown:GetCountdownFontString()
	local names = { [b] = 'button' }
	eq(numbers:GetFontObject(), st:GetFont('pixel_med'), "45px buttons: SaftUI's Pixel Med")
	eq(stub.state(numbers).font, nil, 'and no font of its own')
	eq(T.anchor(numbers, names), 'CENTER button CENTER 0.00,0.00', 'in the middle of the button')
	eq(numbers:GetNumPoints(), 1, 'by that one point')
	local cx, cy = b.cooldown:GetCenter()
	local bx, by = b:GetCenter()
	check(near(cx, bx) and near(cy, by), "which is the middle of the cooldown, where the game puts its numbers")

	-- The font object follows the Fonts tab at once, as it did.
	st.config.profile.fonts.pixel_med.font_size = 20
	st:GetModule('Fonts'):UpdateFontConfig('pixel_med')
	eq(select(2, numbers:GetFont()), 20, "a change to Pixel Med on the Fonts tab reaches them at once")

	AB.config.bar1.size = 30
	AB:UpdateBar('bar1')
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'buttons made 30px: Pixel, so they fit')
	AB.config.bar1.size = st.LARGE_COUNTDOWN_SIZE
	AB:UpdateBar('bar1')
	eq(numbers:GetFontObject(), st:GetFont('pixel_med'), 'made 36px: Pixel Med again')
	eq(stub.state(numbers).font, nil, 'still no font of its own')

	local pet = button('CooldownTestPet')
	AB.bars.pet = { id = 'pet', buttons = { pet } }
	AB:StyleBar('pet')
	local petNumbers = pet.cooldown:GetCountdownFontString()
	eq(petNumbers:GetFontObject(), st:GetFont('pixel'), "the pet bar's 30px buttons: Pixel")
	eq(T.anchor(petNumbers, { [pet] = 'button' }), 'CENTER button CENTER 0.00,0.00', 'in the middle')
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile saved before the cooldown number options gets their defaults', function()
	fresh({ bar1 = { size = 30, text = { hotkey = { size = 12 } } } })
	local text = AB.config.bar1.text
	eq(text.hotkey.size, 12, 'the saved hotkey size stays')
	eq(text.countdown.point .. ' ' .. text.countdown.rel_point, 'CENTER CENTER', 'the numbers get the default place')
	eq(text.countdown.size, nil, 'and no size of their own')

	local b = bar('bar1', button('CooldownTestSaved'))
	local numbers = b.cooldown:GetCountdownFontString()
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'its 30px buttons: Pixel, as before')
	eq(stub.state(numbers).font, nil, 'and no font of its own')
	eq(T.anchor(numbers, { [b] = 'button' }), 'CENTER button CENTER 0.00,0.00', 'in the middle')
	eq(#take_errors(), 0, 'no errors')
end)

test("the Text tab's Cooldown numbers set the numbers' font, size, outline and place at once, and they hold", function()
	fresh()
	local b = bar('bar1', button('CooldownTestOptions'))
	local numbers = b.cooldown:GetCountdownFontString()
	local names = { [b] = 'button' }
	local pixelMed = st.config.profile.fonts.pixel_med
	local OUTLINE = pixelMed.font_outline

	local group = AB:GetBarOptions('bar1', 1).args.text.args.countdown
	eq(group.name, 'Cooldown numbers', 'a Cooldown numbers section')
	check(type(group.desc) == 'string' and group.desc:find('Cooldown numbers', 1, true), 'whose note says the page toggle shows them')
	eq(group.args.show, nil, 'no Show of its own')
	eq(group.args.position.type, 'position', 'a Position block')
	eq(group.args.position.target, nil, 'with no TO part')
	local function get(key) return group.get({ key }) end
	local function set(key, value) group.set({ key }, value) end

	-- Until set, the options show what's drawn.
	eq(get('font') .. ',' .. get('size') .. ',' .. get('outline'),
		pixelMed.font_name .. ',' .. pixelMed.font_size .. ',' .. OUTLINE, "Font, Size and Outline show Pixel Med's")

	set('size', 14)
	eq(AB.config.bar1.text.countdown.size, 14, 'Size writes text.countdown.size')
	eq(font(numbers), path(pixelMed.font_name) .. ',14,' .. OUTLINE, 'the numbers take it at once, in the same face and outline')
	eq(get('size'), 14, 'Size shows it')
	eq(get('font'), pixelMed.font_name, 'Font still shows the face drawn')
	eq(AB.config.bar1.text.countdown.font, nil, 'which is still not set')

	set('font', 'Friz Quadrata TT')
	set('outline', 'NONE')
	eq(font(numbers), path('Friz Quadrata TT') .. ',14,', 'Font and Outline: another face, no outline')
	eq(get('font') .. ',' .. get('outline'), 'Friz Quadrata TT,NONE', 'shown in their rows')

	local position = group.args.position
	position.set({ 'position' }, 'point', 'BOTTOMRIGHT')
	position.set({ 'position' }, 'rel_point', 'BOTTOMRIGHT')
	position.set({ 'position' }, 'x_off', -2)
	position.set({ 'position' }, 'y_off', 2)
	eq(position.get({ 'position' }, 'point'), 'BOTTOMRIGHT', 'Position reads text.countdown.point')
	eq(T.anchor(numbers, names), 'BOTTOMRIGHT button BOTTOMRIGHT -2.00,2.00', 'moved at once')
	eq(numbers:GetNumPoints(), 1, 'by that one point')
	eq(numbers:GetJustifyH(), 'RIGHT', 'right-aligned, on a right-hand point')

	local function look() return font(numbers) .. ' ' .. T.anchor(numbers, names) end
	local mine = look()
	LAB.callbacks:Fire('OnButtonUpdate', b)
	eq(look(), mine, "LibActionButton's update of the button (a page change runs it) leaves them")
	AB:UpdateBar('bar1')
	eq(look(), mine, 'styled again: the same')
	T.theme('thin', function() AB:UpdateBar('bar1') end)
	eq(look(), mine, 'a theme switch: the same')

	local first = st.config.profile
	switch_profile({ actionbars = { bar1 = { text = { countdown = { size = 12, point = 'TOP', rel_point = 'TOP', y_off = -2 } } } } })
	eq(font(numbers), path(pixelMed.font_name) .. ',12,' .. OUTLINE, "another profile: its size, Pixel Med's face and outline")
	eq(T.anchor(numbers, names), 'TOP button TOP 0.00,-2.00', 'and its place')
	switch_profile({})
	eq(numbers:GetFontObject(), st:GetFont('pixel_med'), 'a profile that sets none: Pixel Med again')
	eq(font(numbers), font(st:GetFont('pixel_med')), "drawn in Pixel Med's font, not the last one set")
	eq(T.anchor(numbers, names), 'CENTER button CENTER 0.00,0.00', 'in the middle again')
	switch_profile(first)
	eq(look(), mine, "back to the first profile: its numbers again")

	-- Reset: the font, size and outline unset again and the place put back.
	local reset = group.args.reset
	eq(reset.type, 'execute', 'a Reset button')
	eq(reset.name, 'Reset', 'named Reset')
	check(group.args.outline.order < reset.order and reset.order < position.order, 'after Outline, before the Position block')
	eq(reset.confirm, true, 'which asks first')
	eq(reset.confirmText, "Reset Bar 1's cooldown numbers to SaftUI's defaults?", 'naming the bar')
	reset.func()
	local countdown = AB.config.bar1.text.countdown
	eq(tostring(countdown.font) .. ',' .. tostring(countdown.size) .. ',' .. tostring(countdown.outline),
		'nil,nil,nil', 'the font, size and outline are unset')
	eq(('%s %s %s,%s'):format(countdown.point, countdown.rel_point, countdown.x_off, countdown.y_off),
		'CENTER CENTER 0,0', 'and the place is the default')
	eq(numbers:GetFontObject(), st:GetFont('pixel_med'), 'the numbers are on Pixel Med again, at once')
	eq(font(numbers), font(st:GetFont('pixel_med')), "drawn in its font")
	eq(T.anchor(numbers, names), 'CENTER button CENTER 0.00,0.00', 'in the middle')
	eq(get('font') .. ',' .. get('size') .. ',' .. get('outline'),
		pixelMed.font_name .. ',' .. pixelMed.font_size .. ',' .. OUTLINE, "the rows show Pixel Med's again")
	AB.config.bar1.size = 30
	AB:UpdateBar('bar1')
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'and the font follows the button size again: Pixel at 30px')
	eq(font(numbers), font(st:GetFont('pixel')), "drawn in Pixel's font")
	eq(#take_errors(), 0, 'no errors')
end)

test("text settings with no countdown, as the leave vehicle button's, give a bar's defaults", function()
	fresh()
	-- extras.lua styles its leave vehicle button with text settings of its own
	-- (LEAVE_TEXT, a local there), which name no countdown: these are a copy.
	local NO_TEXT = { show = false, size = 10, point = 'CENTER', rel_point = 'CENTER', x_off = 0, y_off = 0 }
	local b = button('CooldownTestLeave')
	AB:StyleButton(b, { size = 30, text = { hotkey = NO_TEXT, count = NO_TEXT, macro = NO_TEXT } },
		AB.config.theme, AB.config.background)
	local numbers = b.cooldown:GetCountdownFontString()
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'Pixel, on a 30px button')
	eq(stub.state(numbers).font, nil, 'and no font of its own')
	eq(T.anchor(numbers, { [b] = 'button' }), 'CENTER button CENTER 0.00,0.00', 'in the middle')
	eq(#take_errors(), 0, 'no errors')
end)

test('the pet and stance bars have the Cooldown numbers section too, the extra buttons none', function()
	fresh()
	for _, id in ipairs({ 'pet', 'stance' }) do
		AB.bars[id] = { buttons = {} }
		for i = 1, 10 do AB.bars[id].buttons[i] = {} end
		local kinds = {}
		for kind in pairs(AB:GetBarOptions(id, 1).args.text.args) do kinds[#kinds + 1] = kind end
		table.sort(kinds)
		eq(table.concat(kinds, ','), 'countdown,hotkey', id .. ': the hotkey and the cooldown numbers')
	end
	for _, id in ipairs(AB.EXTRA_IDS) do
		eq(AB:GetExtraOptions(id, 1).args.text, nil, id .. ': no Text tab')
	end
	eq(#take_errors(), 0, 'no errors')
end)
