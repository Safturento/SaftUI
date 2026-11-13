-- The action bars' shared settings (SaftUI-ActionBars/shared.lua): All bars'
-- values, each bar's own flags, the one effective config every reader takes
-- (AB:GetBarConfig), the setters and "Apply to", and the one-time conversion
-- of a profile saved before All bars existed.
--
-- Real: the action bars' files but hideblizzard.lua and keybindmode.lua, in TOC
-- order (cooldown_numbers_test.lua has the rest of the setup: LibActionButton
-- and the buttons made by hand, the bars as plain frames).
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
	'SaftUI-ActionBars/options.lua',
}

local st, AB, LAB

-- A fresh world with Blizzard's setting on. saved is the action bars' part of
-- a profile saved earlier (AceDB keeps only what differs from the defaults).
local function fresh(saved, convert)
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
	function LAB:GetSpellFlyoutFrame() end -- what bars.lua asks of the library when a bar fades
	if convert ~= false then AB:ConvertProfile() end
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

-- A profile switch: the module bound to the new profile (Config:UpdateConfig's
-- step), then AB:UpdateConfig.
local function switch_profile(profile)
	st.config.profile = profile
	apply_defaults()
	st:BindModuleConfig(AB, 'actionbars')
	AB:UpdateConfig()
end

local function dump(value)
	if type(value) ~= 'table' then return tostring(value) end
	local keys = {}
	for key in pairs(value) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local out = {}
	for _, key in ipairs(keys) do out[#out + 1] = tostring(key) .. '=' .. dump(value[key]) end
	return '{' .. table.concat(out, ',') .. '}'
end

local PARTS = { 'point', 'rel_point', 'x_off', 'y_off' }

-- What a bar shows for every key it has, read by read(id, key): a position as its
-- four parts in one string, Buttons and Buttons per row clamped to 1..n.
local function shows(id, read)
	local n = (id == 'pet' or id == 'stance') and 10 or 12
	local out = {}
	for _, key in ipairs(AB.SHARED_KEYS) do
		if AB:HasSetting(id, key) then
			local value
			if key:match('%.position$') then
				local parts = {}
				for i, part in ipairs(PARTS) do parts[i] = tostring(read(id, key, part)) end
				value = table.concat(parts, '/')
			else
				value = read(id, key)
				if key == 'buttons' or key == 'perrow' then value = st.Clamp(value, 1, n) end
			end
			out[key] = value
		end
	end
	return out
end

-- Today's: the bar's own stored (or default) values.
local function before(id)
	return shows(id, function(bar, key, part)
		local config = AB.config[bar]
		local kind, field = key:match('^(%a+)%.(%a+)$')
		if kind then return config.text[kind][part or field] end
		return config[key]
	end)
end

-- Through the effective config.
local function after(id)
	local config = AB:GetBarConfig(id)
	return shows(id, function(_, key, part)
		local kind, field = key:match('^(%a+)%.(%a+)$')
		if kind then return config.text[kind][part or field] end
		return config[key]
	end)
end

test('a new profile: every bar follows All bars but the shipped own settings', function()
	fresh()
	for _, id in ipairs(AB.BAR_IDS) do
		for _, key in ipairs(AB.SHARED_KEYS) do
			local shipped = (key == 'perrow' and id:match('^bar[4-8]$')) or (key == 'size' and (id == 'pet' or id == 'stance'))
			eq(AB:IsOwn(id, key), shipped and true or false, id .. ' ' .. key)
		end
	end
	eq(AB.config.version, 1, 'the marker, inside actionbars')
	eq(table.concat(AB:OwnersOf('perrow'), ','), 'bar4,bar5,bar6,bar7,bar8', 'Buttons per row is owned by bars 4-8')
	eq(table.concat(AB:OwnersOf('size'), ','), 'pet,stance', 'Button size by the pet and stance bars')
	local all = AB.config.all
	eq(all.buttons .. all.perrow .. all.size .. all.spacing .. all.visibility .. all.fade_alpha, '1212453always0.3', "All bars' defaults are Bar 1's")
	eq(all.text.hotkey.point, 'TOPRIGHT', "and its texts'")
	eq(AB.config.bar4.perrow, 1, "a bar keeps today's defaults")
	eq(AB.config.pet.size, 30, "the pet bar's too")
	eq(#take_errors(), 0, 'no errors')
end)

test('the keys, in order, and which bars have them', function()
	fresh()
	eq(table.concat(AB.SHARED_KEYS, ','),
		'buttons,perrow,size,spacing,visibility,fade_alpha,'
		.. 'hotkey.show,hotkey.font,hotkey.size,hotkey.outline,hotkey.position,'
		.. 'count.show,count.font,count.size,count.outline,count.position,'
		.. 'macro.show,macro.font,macro.size,macro.outline,macro.position,'
		.. 'countdown.font,countdown.size,countdown.outline,countdown.position', 'the keys')
	eq(AB.CONFIG_VERSION, 1, 'version')
	eq(table.concat(AB.TEXT_KINDS, ','), 'hotkey,count,macro,countdown', 'text kinds')
	eq(table.concat(AB.POSITION_PARTS, ','), 'point,rel_point,x_off,y_off', 'position parts')
	eq(AB:HasSetting('pet', 'hotkey.size'), true, 'the pet bar has a hotkey')
	eq(AB:HasSetting('pet', 'macro.show'), false, 'and no macro name')
	eq(AB:HasSetting('stance', 'count.position'), false, 'nor a stack count')
	eq(AB:HasSetting('all', 'macro.show'), true, 'All bars has every key')
	eq(AB:IsOwn('all', 'size'), false, 'All bars owns nothing')
end)

test('a profile saved before the update looks exactly as it did, and owns only where it differs from Bar 1', function()
	local saved = {
		bar1 = { size = 36, spacing = 2, text = { hotkey = { size = 12, point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 2 }, countdown = { size = 14 } } },
		bar2 = { perrow = 6, visibility = 'mouseover', fade_alpha = 0.5 },
		bar3 = { size = 36, spacing = 2, text = { hotkey = { size = 12, point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 2 }, countdown = { size = 14 } } },
		bar4 = { buttons = 6, perrow = 12 },
		bar6 = { enable = true, text = { macro = { show = false } } },
		pet = { size = 24, text = { count = { size = 20 } } },
		stance = { buttons = 12, perrow = 3 },
	}
	fresh(saved, false)
	local was = {}
	for _, id in ipairs(AB.BAR_IDS) do was[id] = before(id) end
	AB:ConvertProfile()
	for _, id in ipairs(AB.BAR_IDS) do eq(dump(after(id)), dump(was[id]), id .. ': shows what it did') end
	eq(table.concat(AB:OwnersOf('size'), ','), 'bar2,bar4,bar5,bar6,bar7,bar8,pet,stance',
		'Bar 1 is 36: every bar left at 45, and the pet (24) and stance (30) bars, own their size; Bar 3 follows')
	eq(AB:IsOwn('bar4', 'perrow'), false, "12 per row on 6 buttons shows what All bars' 12 does there: the shipped flag is cleared")
	eq(AB:IsOwn('bar3', 'hotkey.position') or AB:IsOwn('bar3', 'countdown.size'), false, 'Bar 3, set like Bar 1, owns nothing')
	eq(AB:IsOwn('stance', 'buttons'), false, '12 saved on a 10-button bar shows 10, as All bars does there')
	eq(AB:IsOwn('pet', 'count.size'), false, "the pet bar's unused stack count is never owned")
	eq(AB:GetSetting('all', 'size'), 36, "All bars took Bar 1's size")
	eq(AB:GetSetting('all', 'hotkey.position', 'x_off'), 2, "and its text place")
	eq(AB:IsOwn('bar6', 'macro.show'), true, 'a hidden macro name on one bar is its own')
	eq(AB:IsOwn('bar2', 'perrow'), true, 'a bar of 6 per row owns it')
	eq(#take_errors(), 0, 'no errors')
end)

test('the conversion runs once per profile, and again for one switched to, copied or reset', function()
	local saved = { bar2 = { size = 30 } }
	fresh(saved, false)
	AB:ConvertProfile()
	local converted = dump(st.config.profile.actionbars)
	AB:ConvertProfile()
	eq(dump(st.config.profile.actionbars), converted, 'twice: unchanged the second time')

	AB:SetSetting('bar2', 'size', 33)
	AB:ConvertProfile()
	eq(AB:GetSetting('bar2', 'size'), 33, "a bar's own value changed after is kept by a third call (the marker)")

	-- A profile never converted, bound and updated.
	AB.built = true
	switch_profile({ actionbars = { bar3 = { size = 20 } } })
	eq(AB.config.version, 1, 'switched to: converted')
	eq(AB:GetSetting('all', 'size'), 45, "All bars: Bar 1's")
	eq(AB:IsOwn('bar3', 'size'), true, 'Bar 3 owns the 20')
	eq(AB:GetSetting('bar3', 'size'), 20, 'and shows it')

	switch_profile({})
	eq(AB.config.version, 1, 'a reset profile: converted')
	local owners = {}
	for _, key in ipairs(AB.SHARED_KEYS) do
		for _, id in ipairs(AB:OwnersOf(key)) do owners[#owners + 1] = id .. ':' .. key end
	end
	eq(table.concat(owners, ','), 'bar4:perrow,bar5:perrow,bar6:perrow,bar7:perrow,bar8:perrow,pet:size,stance:size', 'exactly the shipped flags')
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile switched to in combat is converted at once, and the bars wait for the end of combat', function()
	fresh()
	local b = button('SharedCombatButton')
	bar('bar2', b)
	AB.built = true
	function AB:UpdateBindings() end -- the keys' own test is elsewhere; they need the game's binding API
	eq(b:GetWidth(), 45, 'laid out at 45')
	stub.in_combat = true
	switch_profile({ actionbars = { bar2 = { size = 30 } } })
	eq(AB.config.version, 1, 'converted at once')
	eq(AB:IsOwn('bar2', 'size'), true, 'with the bar owning its size')
	eq(b:GetWidth(), 45, 'the buttons still 45 wide')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(b:GetWidth(), 30, 'and 30 wide when combat ends')
	eq(table.concat(take_errors(), '\n'), '', 'no errors')
end)

test('setting, resetting and applying', function()
	fresh()
	AB:SetSetting('all', 'size', 36)
	eq(AB:GetBarConfig('bar3').size, 36, 'a bar following All bars shows its value')
	eq(AB:GetBarConfig('pet').size, 30, 'the pet bar owns its size')
	eq(AB:IsOwn('bar3', 'size'), false, 'setting All bars owns nothing')

	AB:SetSetting('bar3', 'size', 40)
	eq(AB:IsOwn('bar3', 'size'), true, 'a change on a bar makes it its own')
	eq(AB:GetBarConfig('bar3').size, 40, 'shown')
	eq(AB:GetSetting('all', 'size'), 36, 'All bars unchanged')
	AB:ResetSetting('bar3', 'size')
	eq(AB:IsOwn('bar3', 'size'), false, 'Reset: follows')
	eq(AB:GetBarConfig('bar3').size, 36, "All bars' value")
	eq(AB.config.bar3.size, 40, 'its own is still stored')

	AB:ResetSetting('pet', 'size')
	eq(st.config.profile.actionbars.pet.own.size, false, 'a shipped flag is cleared to false, not nil')
	eq(AB:GetBarConfig('pet').size, 36, 'the pet bar follows')

	AB.config.bar2.text.hotkey.x_off = 7
	AB:SetSetting('all', 'hotkey.position', -3, 'x_off')
	AB:SetSetting('bar2', 'hotkey.position', 'TOPLEFT', 'point')
	eq(AB:GetSetting('bar2', 'hotkey.position', 'x_off'), -3, "the first own position copies All bars' parts in")
	eq(AB:GetSetting('bar2', 'hotkey.position', 'point'), 'TOPLEFT', 'then writes the part')
	eq(AB:GetSetting('bar2', 'hotkey.position', 'rel_point'), 'TOPRIGHT', 'the other parts are All bars\'')
	eq(AB:GetSetting('all', 'hotkey.position', 'point'), 'TOPRIGHT', 'All bars unchanged')
	eq(AB:IsOwn('bar2', 'hotkey.position'), true, 'owned')

	AB:SetSetting('bar5', 'perrow', 1)
	AB:ApplyToAll('bar5', 'perrow')
	eq(AB:GetSetting('all', 'perrow'), 1, "Apply to All: All bars takes the bar's value")
	eq(#AB:OwnersOf('perrow'), 0, 'and nobody owns it (bars 4-8 cleared)')
	eq(AB:GetBarConfig('bar1').perrow, 1, 'every bar follows it')
	eq(st.config.profile.actionbars.bar4.own.perrow, false, 'cleared flags are false')

	AB:ApplyToAll('bar2', 'hotkey.position')
	eq(AB:GetSetting('all', 'hotkey.position', 'point') .. AB:GetSetting('all', 'hotkey.position', 'x_off'), 'TOPLEFT-3', 'a position goes whole')
	eq(AB:IsOwn('bar2', 'hotkey.position'), false, 'and the bar follows again')

	AB:SetSetting('bar3', 'size', 40)
	AB:ApplyTo('bar3', 'size', { 'bar5', 'pet' })
	eq(AB:IsOwn('bar5', 'size') and AB:IsOwn('pet', 'size'), true, 'Apply to Multiple: both own')
	eq(AB:GetBarConfig('bar5').size .. ',' .. AB:GetBarConfig('pet').size, '40,40', 'a copy of the value')
	AB:SetSetting('bar3', 'size', 36)
	AB:ApplyTo('bar3', 'size', { 'bar5', 'pet' })
	eq(AB:IsOwn('bar5', 'size') or AB:IsOwn('pet', 'size'), false, "a value equal to All bars': they follow")

	AB:ApplyTo('all', 'perrow', { 'bar4' })
	eq(AB:IsOwn('bar4', 'perrow'), false, 'from All bars: the target follows')
	AB:SetSetting('bar4', 'perrow', 3)
	AB:SetSetting('bar5', 'perrow', 3)
	AB:ApplyTo('all', 'perrow', { 'bar4' })
	eq(AB:IsOwn('bar4', 'perrow') or false, false, 'bar4 follows')
	eq(AB:IsOwn('bar5', 'perrow'), true, 'bar5 still owns')
	eq(table.concat(AB:OwnersOf('perrow'), ','), 'bar5', 'OwnersOf')
	AB:ApplyToAll('all', 'perrow')
	eq(#AB:OwnersOf('perrow'), 0, 'Apply to All from All bars: nobody owns it')

	local pet = dump(AB.config.pet.text.count)
	AB:SetSetting('bar1', 'count.size', 21)
	AB:ApplyTo('bar1', 'count.size', { 'pet' })
	eq(dump(AB.config.pet.text.count), pet, 'a key the pet bar lacks: it is unchanged')
	eq(AB:IsOwn('pet', 'count.size'), false, 'and not owned')
	eq(#take_errors(), 0, 'no errors')
end)

test("the pet and stance bars show at most 10, whatever All bars' Buttons says", function()
	fresh()
	for _, id in ipairs({ 'pet', 'stance' }) do
		AB.bars[id] = { buttons = {} }
		for i = 1, 10 do AB.bars[id].buttons[i] = {} end
	end
	AB.barTypes.stance.GetNumSlots = function() return 10 end
	eq(AB:GetSetting('all', 'buttons'), 12, "All bars' Buttons is 12")
	eq(AB:GetNumButtons('pet'), 10, 'the pet bar following it shows 10')
	AB:SetSetting('bar1', 'buttons', 12)
	AB:ApplyToAll('bar1', 'buttons')
	eq(AB:GetNumButtons('pet') .. ',' .. AB:GetNumButtons('stance'), '10,10', 'Apply to All from a 12-button bar: still 10')
	eq(AB:HasSetting('pet', 'macro.show'), false, 'no macro name')
	eq(AB:HasSetting('pet', 'hotkey.size'), true, 'a hotkey')
	eq(#take_errors(), 0, 'no errors')
end)

test('every reader takes the effective config', function()
	fresh()
	eq(AB:GetButtonConfig('bar4', 1).flyoutDirection, 'LEFT', 'bar4 owns 1 per row: flyouts go left')
	AB:ResetSetting('bar4', 'perrow')
	eq(AB:GetButtonConfig('bar4', 1).flyoutDirection, 'UP', 'following All bars rows: up')

	local b2 = button('SharedReader2')
	bar('bar2', b2)
	AB:SetSetting('all', 'size', 36)
	AB:UpdateBar('bar2')
	eq(b2:GetWidth(), 36, 'bar2 follows All bars size: 36 wide')

	AB:SetSetting('bar2', 'visibility', 'mouseover')
	AB:SetSetting('all', 'fade_alpha', 0.5)
	AB:UpdateBar('bar2')
	eq(AB.bars.bar2:GetAlpha(), 0.5, "a faded bar takes All bars' opacity")
	AB:SetSetting('bar2', 'visibility', 'always')
	AB:UpdateBar('bar2')
	eq(AB.bars.bar2:GetAlpha(), 1, 'shown always: not faded')
	AB:SetSetting('all', 'fade_alpha', 0.7)
	AB:SetSetting('bar2', 'visibility', 'mouseover')
	AB:UpdateBar('bar2')
	eq(AB.bars.bar2:GetAlpha(), 0.7, 'faded again: All bars\' new opacity')
	eq(AB:GetVisibilityDriver('bar2'):find('show', 1, true) ~= nil, true, 'the visibility driver reads it too')
	AB:SetSetting('bar2', 'visibility', 'combat')
	eq(AB:GetVisibilityDriver('bar2'), '[petbattle][vehicleui][overridebar] hide; [combat] show; hide', 'combat only')

	AB:SetSetting('all', 'hotkey.size', 14)
	eq(AB:GetButtonConfig('bar1', 1).text.hotkey.font.size, 14, "bar1's hotkey takes All bars' size")
	local cfg = AB:GetBarConfig('bar3')
	eq(AB:GetButtonConfig('bar3', 1, cfg).text.hotkey.font.size, 14, 'a resolved config can be passed')
	eq(#take_errors(), 0, 'no errors')
end)

test('the countdown Reset: on All bars the shared values, on a bar its own only where All bars differs', function()
	fresh()
	AB:SetSetting('all', 'countdown.size', 14)
	AB:SetSetting('bar3', 'countdown.font', 'Friz Quadrata TT')
	AB:ResetCountdown('bar3')
	eq(AB:IsOwn('bar3', 'countdown.size'), true, "All bars' size is set, so the bar's unset one is its own")
	eq(AB:GetBarConfig('bar3').text.countdown.size, nil, 'unset')
	eq(AB:IsOwn('bar3', 'countdown.font'), false, "All bars has no font: followed")
	eq(AB:IsOwn('bar3', 'countdown.position'), false, 'the place is the default: followed')
	eq(AB:GetBarConfig('bar3').text.countdown.font, nil, 'no font')
	AB:ResetCountdown('all')
	eq(AB:GetSetting('all', 'countdown.size'), nil, "All bars' size unset")
	eq(AB:GetBarConfig('bar3').text.countdown.size, nil, 'bar3 keeps its own (nil) size')
	eq(AB:IsOwn('bar3', 'countdown.size'), true, 'still owned')
	eq(AB:GetSetting('all', 'countdown.position', 'point'), 'CENTER', "All bars' place is the middle")
	AB:SetSetting('all', 'countdown.position', 4, 'x_off')
	AB:ResetCountdown('bar2')
	eq(AB:IsOwn('bar2', 'countdown.position'), true, "All bars' place isn't the default: the bar owns the default place")
	eq(AB:GetSetting('bar2', 'countdown.position', 'x_off'), 0, 'in the middle')
	eq(#take_errors(), 0, 'no errors')
end)
