-- The action bars' cooldown numbers (SaftUI-ActionBars): the Cooldown item's
-- Show box on the Action Bars page's All bars, and each bar's font and place
-- for them in its Cooldown item's menu (textoptions.lua).
--   - All bars' box is Blizzard's "Show Numbers for Cooldowns" (the
--     countdownForCooldowns setting), read and set as it is: nothing goes in
--     the profile, a change in Blizzard's options shows in it, a change made
--     with it fires the CVAR_UPDATE the bars follow, and in combat it waits
--     for the end of combat.
--   - By default the numbers look as they did: SaftUI's Pixel Med font object
--     on buttons of 36px and up and Pixel below, in the middle of the button.
--     A profile saved before the options existed gets those defaults.
--   - A bar's Cooldown menu (on the pet and stance bars too, not on the extra
--     buttons) sets their font, size and outline and their place at once,
--     shows what's drawn until they're set, and holds through
--     LibActionButton's button update, a restyle, a theme switch and a
--     profile switch, back to the defaults too. Each setting's reset there
--     (its share's: follow All bars again) puts back All bars' unset font,
--     size and outline and its place; on All bars each one's own reset
--     unsets it again. There's no Reset button.
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
--     AB.built stays false and AB:UpdateBindings does nothing; the box's
--     case sets it by hand, since the page is drawn only for built bars.
-- The shell's st.Config stands in for Core's Config module (tests/lib/shell.lua):
-- the box's case counts its Refresh, the call that redraws an open /sui.
-- A profile switch is Config:UpdateConfig's steps for the action bars: the
-- module bound to the new profile, then AB:UpdateConfig, which waits for the
-- bars to be built, so AB:UpdateBar on the bar here, as it runs it for each.
local T = load_test_file('lib/theme_helpers.lua')

local CVAR = 'countdownForCooldowns'

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
	AB:ConvertProfile()
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

test("All bars' Cooldown box is Blizzard's Show Numbers for Cooldowns, not a profile setting", function()
	fresh()
	bar('bar1', button('CooldownTestToggle'))
	AB.built = true -- see the top
	local all = AB:GetConfigTable().args.all
	local option = all.args.text.args.countdown
	eq(option.type, 'item', 'a menu item, its box the setting')
	eq(option.name, 'Cooldown', 'named Cooldown')
	eq(option.menuTitle, 'Cooldown numbers', 'its menu titled Cooldown numbers')
	check(option.desc:find('Show Numbers for Cooldowns', 1, true), "its tooltip names Blizzard's option")
	check(all.args.look.order < all.args.text.order, 'in Text, after Look (Theme and Background)')

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
		local countdown = AB:GetBarConfig(id).text.countdown
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

	AB:SetSetting('bar1', 'size', 30)
	AB:UpdateBar('bar1')
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'buttons made 30px: Pixel, so they fit')
	AB:SetSetting('bar1', 'size', st.LARGE_COUNTDOWN_SIZE)
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

test("a bar's Cooldown menu sets the numbers' font, size, outline and place at once, and they hold", function()
	fresh()
	local b = bar('bar1', button('CooldownTestOptions'))
	local numbers = b.cooldown:GetCountdownFontString()
	local names = { [b] = 'button' }
	local pixelMed = st.config.profile.fonts.pixel_med
	local OUTLINE = pixelMed.font_outline

	local item = AB:GetBarOptions('bar1', 1).args.text.args.countdown
	eq(item.type, 'item', 'a Cooldown item')
	eq(item.get, false, 'with no Show box on a bar')
	check(type(item.desc) == 'string' and item.desc:find('All bars', 1, true), 'whose tooltip says All bars shows them')
	local group = item.menu
	eq(group.name, 'Cooldown numbers', 'its menu is Cooldown numbers')
	eq(group.args.show, nil, 'no Show of its own')
	eq(group.args.position.type, 'position', 'a Position block')
	eq(group.args.position.target, nil, 'with no TO part')
	eq(group.args.reset, nil, 'no Reset button: each setting has its own')
	-- A menu option's info is { 'menu', key } (Core's OM.MenuRoot).
	local function get(key) return group.get({ 'menu', key }) end
	local function set(key, value) group.set({ 'menu', key }, value) end

	-- Until set, the options show what's drawn.
	eq(get('font') .. ',' .. get('size') .. ',' .. get('outline'),
		pixelMed.font_name .. ',' .. pixelMed.font_size .. ',' .. OUTLINE, "Font, Size and Outline show Pixel Med's")

	set('size', 14)
	eq(AB.config.bar1.text.countdown.size, 14, 'Size writes text.countdown.size')
	eq(numbers:GetFontObject(), st:GetFont(AB:CountdownValue(AB:GetBarConfig('bar1'))), "the object is the value's typeface")
	eq(stub.state(numbers).font, nil, 'and no SetFont was called on the numbers')
	eq(font(numbers), path(pixelMed.font_name) .. ',14,' .. OUTLINE, 'the numbers take it at once, in the same face and outline')
	eq(get('size'), 14, 'Size shows it')
	eq(get('font'), pixelMed.font_name, 'Font still shows the face drawn')
	eq(AB.config.bar1.text.countdown.font, nil, 'which is still not set')

	set('font', 'Friz Quadrata TT')
	set('outline', 'NONE')
	eq(font(numbers), path('Friz Quadrata TT') .. ',14,', 'Font and Outline: another face, no outline')
	eq(numbers:GetFontObject(), st:GetFont(AB:CountdownValue(AB:GetBarConfig('bar1'))), "the object is the value's typeface")
	eq(stub.state(numbers).font, nil, 'and still no SetFont')
	eq(get('font') .. ',' .. get('outline'), 'Friz Quadrata TT,NONE', 'shown in their rows')

	local position = group.args.position
	local at = { 'menu', 'position' }
	position.set(at, 'point', 'BOTTOMRIGHT')
	position.set(at, 'rel_point', 'BOTTOMRIGHT')
	position.set(at, 'x_off', -2)
	position.set(at, 'y_off', 2)
	eq(position.get(at, 'point'), 'BOTTOMRIGHT', 'Position reads text.countdown.point')
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

	-- Each setting's reset on a bar is its share's: Bar 1 follows All bars
	-- again, whose numbers ship with no font, size or outline, in the middle.
	for _, key in ipairs({ 'font', 'size', 'outline', 'position' }) do
		eq(AB:IsOwn('bar1', 'countdown.' .. key), true, key .. ' is the bar\'s own')
		group.args[key].share.reset({ 'menu', key })
		eq(AB:IsOwn('bar1', 'countdown.' .. key), false, key .. ': reset, it follows All bars')
	end
	local countdown = AB:GetBarConfig('bar1').text.countdown
	eq(tostring(countdown.font) .. ',' .. tostring(countdown.size) .. ',' .. tostring(countdown.outline),
		'nil,nil,nil', 'the font, size and outline are unset')
	eq(('%s %s %s,%s'):format(countdown.point, countdown.rel_point, countdown.x_off, countdown.y_off),
		'CENTER CENTER 0,0', 'and the place is the default')
	eq(numbers:GetFontObject(), st:GetFont(AB:CountdownValue(AB:GetBarConfig('bar1'))), 'the numbers are on the default value again, at once')
	eq(AB:CountdownValue(AB:GetBarConfig('bar1')), 'pixel_med', 'which is Pixel Med, a shared font')
	eq(numbers:GetFontObject(), st:GetFont('pixel_med'), 'the numbers are on Pixel Med again, at once')
	eq(stub.state(numbers).font, nil, 'by the font object alone')
	eq(font(numbers), font(st:GetFont('pixel_med')), "drawn in its font")
	eq(T.anchor(numbers, names), 'CENTER button CENTER 0.00,0.00', 'in the middle')
	eq(get('font') .. ',' .. get('size') .. ',' .. get('outline'),
		pixelMed.font_name .. ',' .. pixelMed.font_size .. ',' .. OUTLINE, "the rows show Pixel Med's again")
	AB:SetSetting('bar1', 'size', 30)
	AB:UpdateBar('bar1')
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'and the font follows the button size again: Pixel at 30px')
	eq(font(numbers), font(st:GetFont('pixel')), "drawn in Pixel's font")

	-- All bars' Cooldown menu: a size there reaches Bar 1, which follows, and
	-- its own reset unsets it again.
	local allGroup = AB:GetAllBarsOptions(0).args.text.args.countdown.menu
	local allSize = allGroup.args.size
	allGroup.set({ 'menu', 'size' }, 13)
	eq(select(2, numbers:GetFont()), 13, "All bars' size reaches the bar at once")
	eq(allSize.default.differs({ 'menu', 'size' }), true, 'set: it differs from its default, unset')
	allSize.default.reset({ 'menu', 'size' })
	eq(AB:GetSetting('all', 'countdown.size'), nil, 'its reset unsets it')
	eq(numbers:GetFontObject(), st:GetFont('pixel'), 'and the bar is back on Pixel at 30px')
	eq(font(numbers), font(st:GetFont('pixel')), "drawn in Pixel's font")
	eq(#take_errors(), 0, 'no errors')
end)

test("the numbers' value: the shared font by size while nothing is set, else the typeface of what is drawn", function()
	fresh()
	local config = AB:GetBarConfig('bar1')
	eq(config.size, 45, 'bar 1 ships 45px buttons')
	eq(AB:CountdownValue(config), 'pixel_med', '45px: Large numbers')
	eq(AB:CountdownValue({ size = 30, text = {} }), 'pixel', '30px, no countdown settings: Small text')
	eq(AB:CountdownValue({ size = 36, text = { countdown = {} } }), 'pixel_med', 'the least size for Large numbers')
	eq(AB:CountdownValue({ size = 35, text = { countdown = {} } }), 'pixel', 'one under it')
	local value = AB:CountdownValue({ size = 30, text = { countdown = { size = 14 } } })
	eq(type(value), 'table', 'a size alone makes a typeface')
	eq(value.font_size, 14, 'at that size')
	eq(value.font_name, st.config.profile.fonts.pixel.font_name, "in the default font's face")
	eq(value.font_outline, st.config.profile.fonts.pixel.font_outline, "and its outline")
	eq(AB:CountdownValue({ size = 30, text = { countdown = { font = 'Colus' } } }).font_name, 'Colus', 'a font alone: that face')
	eq(AB:CountdownValue({ size = 30, text = { countdown = { outline = 'NONE' } } }).font_outline, 'NONE', 'an outline alone')
	eq(AB:CountdownValue({ size = 30, text = { countdown = { font = 'pixel' } } }), 'pixel', "a shared font's key stays the key")
	eq(#take_errors(), 0, 'no errors')
end)

test('a hotkey switched Small text, then Colus, then Small text follows each with no SetFont (G2)', function()
	fresh()
	local b = bar('bar1', button('CooldownTestHotkey'))
	local function drawn()
		local config = AB:GetBarConfig('bar1').text.hotkey
		return st:GetFont(st:FaceFont(config.font, config.size, config.outline))
	end
	local function set(font)
		AB:SetSetting('bar1', 'hotkey.font', font)
		AB:UpdateBar('bar1')
	end
	set('pixel')
	eq(b.HotKey:GetFontObject(), st:GetFont('pixel'), "Small text: the shared font's object")
	eq(b.labConfig.text.hotkey.value, 'pixel', "the config's value is the key")
	eq(b.HotKey:GetHeight(), select(2, st:FontValues('pixel')), "the one-line height is the shared font's size")
	set('Colus')
	eq(b.HotKey:GetFontObject(), drawn(), 'Colus: a typeface object')
	check(b.HotKey:GetFontObject() ~= st:GetFont('pixel'), 'not the shared one')
	eq(b.labConfig.text.hotkey.font.font, path('Colus'), "the library's own face is Colus too")
	set('pixel')
	eq(b.HotKey:GetFontObject(), st:GetFont('pixel'), 'Small text again, with no reload')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		eq(stub.state(b[key]).font, nil, key .. ': no SetFont, ever')
	end
	-- No forced shadow: what a font string has (here set by hand, as a font object's would give) stays.
	b.HotKey:SetShadowOffset(2, -2)
	AB:UpdateBar('bar1')
	eq(T.text(b.HotKey:GetShadowOffset()), '2.00,-2.00', "the style doesn't set the shadow to 0, 0")
	eq(#take_errors(), 0, 'no errors')
end)

test("SaftUI's own buttons (the pet and stance bars) draw their texts with st:ApplyFont, and again when the setting changes", function()
	fresh()
	local header = CreateFrame('Frame', 'CooldownTestSecureBar', UIParent)
	header.id = 'pet'
	-- The stubs have no ActionButtonTemplate: a secure button with the template's
	-- regions made by hand.
	local real = CreateFrame
	function CreateFrame(kind, name, parent, template, id)
		local frame = real(kind, name, parent, 'SecureActionButtonTemplate', id)
		frame.icon = frame:CreateTexture(nil, 'BACKGROUND')
		frame.IconMask = frame:CreateMaskTexture()
		frame.Flash = frame:CreateTexture(nil, 'ARTWORK')
		frame.cooldown = real('Cooldown', nil, frame)
		for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do frame[key] = frame:CreateFontString(nil, 'OVERLAY') end
		return frame
	end
	GetCVarBool = GetCVarBool or function(name) return stub.cvars[name] == '1' end
	local ok, pet = pcall(AB.CreateSecureButton, AB, header, 1, { Refresh = function() end, SetTooltip = function() end })
	CreateFrame = real
	check(ok, tostring(pet))
	local function set(font)
		AB:SetSetting('pet', 'hotkey.font', font)
		pet:UpdateConfig(AB:GetButtonConfig('pet', 1))
	end
	set('pixel')
	eq(pet.HotKey:GetFontObject(), st:GetFont('pixel'), 'Small text')
	set('Colus')
	check(pet.HotKey:GetFontObject() ~= st:GetFont('pixel'), 'Colus: a typeface object')
	eq(select(2, pet.HotKey:GetFont()), AB:GetBarConfig('pet').text.hotkey.size, 'at the setting\'s size')
	set('pixel')
	eq(pet.HotKey:GetFontObject(), st:GetFont('pixel'), 'Small text again')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		eq(stub.state(pet[key]).font, nil, key .. ': no SetFont')
	end
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

test('the pet and stance bars have the Cooldown item too, the extra buttons none', function()
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
