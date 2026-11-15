-- SaftUI-Misc's readers of font settings on the one rule (st:ApplyFont,
-- st:FollowFont, st:FontValues, st:FontObject; a Fonts tab change, a profile
-- update or an option runs st:FontsChanged):
--   - the totem bar's texts and timers follow Button text, and their shadow is no
--     longer forced off: a Small text change reaches them at once; Button text set
--     on the Fonts tab reaches them and the bag slot bars' texts at once;
--   - the buff and debuff timers on a shared font follow it; on a face they keep
--     their own size and outline;
--   - the tooltip's lines take the face, size and outline of st:FontValues, a
--     typeface's too, with no allocation on the per-Show path;
--   - RestedXP's texts and timers take chat's face and outline at RestedXP's own
--     sizes, again on a Fonts tab change;
--   - the color picker's title takes Window titles' font at once, and Blizzard's
--     again with the skin off;
--   - every reader draws Text for a value that names nothing, with no error.
--
-- Real: SaftUI-Misc's config.lua, tooltip.lua, totembar.lua, totemlayout.lua,
-- totemskin.lua, totemtimers.lua, Skinning/skinning.lua,
-- Blizzard_BuffFramePosition.lua, Blizzard_ColorPicker.lua and
-- addons/restedxp.lua, Core's helpers (the font helpers, st:FontsChanged,
-- st:SkinActionButton) and SaftUI-Chat's defaults.
-- Stand-ins: Blizzard's totem slot buttons, summon and action buttons (built as
-- far as the skin reads them, as theme_test.lua builds them), the GameTooltip's
-- first text lines, RestedXP's world (fixtures/restedxp_world.lua), the color
-- picker (fixtures/color_picker.lua).
local T = load_test_file('lib/theme_helpers.lua')

local function eqfont(fs, face, size, flags, message)
	local f, s, o = fs:GetFont()
	eq(f, face, message .. ': face')
	eq(s, size, message .. ': size')
	eq(o, flags, message .. ': outline')
end

local function path(st, name) return st.LSM:Fetch('font', name) end

------------------------------------------------------------------ the tooltip

test("the tooltip's lines take Text's face, size and outline from st:FontValues; a typeface's too", function()
	local st = T.client('forever')
	local tip = CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	local left, right = tip:CreateFontString('GameTooltipTextLeft1', 'ARTWORK'), tip:CreateFontString('GameTooltipTextRight1', 'ARTWORK')
	left:SetFontObject(GameFontNormal)
	right:SetFontObject(GameFontNormal)
	stub.state(tip).lines = 1
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/tooltip.lua')
	local TT = st:GetModule('Tooltip')
	st:BindModuleConfig(TT, 'tooltip')

	TT:UpdateTooltipFonts(tip)
	eq(TT.config.font, 'normal', 'the tooltip follows Text')
	eqfont(left, path(st, 'AgencyFB Bold'), 16, 'OUTLINE', "Text's look on the left")
	eqfont(right, path(st, 'AgencyFB Bold'), 16, 'OUTLINE', 'and the right')

	TT.config.font = { font_name = 'Colus', font_size = 11, font_outline = 'NONE', shadow_offset = { 1, 1 }, spacing = 9 }
	TT:UpdateTooltipFonts(tip)
	eqfont(left, path(st, 'Colus'), 11, '', "a typeface's face, size and outline")
	eqfont(right, path(st, 'Colus'), 11, '', 'on the right too')

	TT.config.font = 'gone'
	TT:UpdateTooltipFonts(tip)
	eqfont(left, path(st, 'AgencyFB Bold'), 16, 'OUTLINE', 'a value that names nothing draws Text')

	-- The per-Show path: no allocation once a line is in the font, for a shared
	-- font or a typeface.
	for _, value in ipairs({ 'normal', { font_name = 'Colus', font_size = 11 } }) do
		TT.config.font = value
		TT:UpdateTooltipFonts(tip)
		collectgarbage()
		collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, 2000 do TT:UpdateTooltipFonts(tip) end
		local grown = collectgarbage('count') - before
		collectgarbage('restart')
		eq(grown, 0, 'no garbage over 2000 Shows (' .. (type(value) == 'table' and 'a typeface' or value) .. ')')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("a face whose file fails to load draws in Text's face on the tooltip's lines, set once", function()
	local st = T.client('forever')
	local tip = CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	local left = tip:CreateFontString('GameTooltipTextLeft1', 'ARTWORK')
	left:SetFontObject(GameFontNormal)
	stub.state(tip).lines = 1
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/tooltip.lua')
	local TT = st:GetModule('Tooltip')
	st:BindModuleConfig(TT, 'tooltip')
	stub.refused_fonts[path(st, 'Colus')] = true -- the game refuses the file
	local sets = 0
	local method = getmetatable(left).__index.SetFont
	rawset(left, 'SetFont', function(self, ...) sets = sets + 1; return method(self, ...) end)
	TT.config.font = { font_name = 'Colus', font_size = 11, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
	TT:UpdateTooltipFonts(tip)
	eqfont(left, path(st, 'AgencyFB Bold'), 11, '', "Text's face at the typeface's size and outline")
	eq(sets, 1, 'set once')
	for _ = 1, 50 do TT:UpdateTooltipFonts(tip) end
	eq(sets, 1, 'and not again on every Show')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the totem bar

local function totem_world()
	local st = T.client('forever')
	load_editmode()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/totembar.lua')
	load_saftui('SaftUI-Misc/totemlayout.lua')
	load_saftui('SaftUI-Misc/totemposition.lua')
	load_saftui('SaftUI-Misc/totemoptions.lua')
	load_saftui('SaftUI-Misc/totemskin.lua')
	load_saftui('SaftUI-Misc/totemtimers.lua')
	-- Blizzard's totem API, which the stubs lack: no totem is out.
	GetTotemDuration = function() end
	FIRE_TOTEM_SLOT, EARTH_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT = 1, 2, 3, 4
	local slots = {}
	for i = 1, 4 do
		local button = CreateFrame('Button', 'MultiCastSlotButton' .. i, UIParent)
		button:SetID(i)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.background = button:CreateTexture(nil, 'BACKGROUND')
		button.overlayTex = button:CreateTexture(nil, 'OVERLAY')
		slots[i] = button
	end
	local function totem_button(name)
		local button = CreateFrame('CheckButton', name, UIParent)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.icon = button:CreateTexture(nil, 'BACKGROUND')
		button.Flash = button:CreateTexture(nil, 'ARTWORK', nil, 1)
		button.Count = button:CreateFontString(nil, 'ARTWORK')
		button.HotKey = button:CreateFontString(nil, 'OVERLAY')
		button.Name = button:CreateFontString(nil, 'OVERLAY')
		return button
	end
	local summon = totem_button('MultiCastSummonSpellButton')
	local TB = st:GetModule('TotemBar')
	st:BindModuleConfig(TB, 'totembar')
	TB:SetupSkin()
	return st, TB, summon, slots
end

test('a Small text change reaches the totem texts and timers at once, with their shadow no longer forced off', function()
	local st, TB, summon = totem_world()
	local profile = st.config.profile
	eq(profile.buttons.font, 'pixel', 'Button text starts as Small text')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		check(summon[key]:GetFontObject() == st:GetFont('pixel'), key .. ' starts in Small text')
	end

	-- The skin used to force each text's shadow to 0, 0 on every restyle. It no
	-- longer touches a shadow: a shadow set on a text stays through a restyle and
	-- a font change (the text's look is its font's).
	profile.fonts.pixel.font_size = 14
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do summon[key]:SetShadowOffset(3, -3) end
	TB:ApplySkin()
	st:FontsChanged()
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		local fs = summon[key]
		check(fs:GetFontObject() == st:GetFont('pixel'), key .. ' still follows Small text')
		eq(select(2, st:GetFont('pixel'):GetFont()), 14, 'Small text is at its new size, which the text reads through its object')
		local x, y = fs:GetShadowOffset()
		eq(x .. ',' .. y, '3,-3', key .. ': its shadow is no longer forced off')
	end
	profile.fonts.pixel.font_size = nil
	st:GetModule('Fonts'):UpdateFontConfig('pixel')

	-- The timers: made with the bar, in Button text's font, laid out again.
	local slot = _G.MultiCastSlotButton1
	TB.config.timer_bar_height = 12
	TB:SetupTimers()
	-- The timer's text: a font string two frames down (the timer's frame, then the
	-- cover over its bar).
	local function find(frame, depth)
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == 'FontString' then return region end
		end
		if depth > 0 then
			for _, child in ipairs({ frame:GetChildren() }) do
				local found = find(child, depth - 1)
				if found then return found end
			end
		end
	end
	local timer = find(slot, 3)
	check(timer ~= nil, 'a timer text was made on a slot button')
	check(timer:GetFontObject() == st:GetFont('pixel'), 'the timer text starts in Button text')
	profile.buttons.font = 'pixel_med'
	st:FontsChanged()
	check(timer:GetFontObject() == st:GetFont('pixel_med'), 'Button text reaches the timer text at once')
	-- The text on the bar decides how tall the bar is: Large numbers (18) lay it
	-- out taller than Small text (10).
	TB.config.timer_bar, TB.config.timer_text, TB.config.timer_text_position = true, true, 'on'
	local function tallest()
		local tall = 0
		for _, child in ipairs({ slot:GetChildren() }) do
			for _, grandchild in ipairs({ child:GetChildren() }) do tall = math.max(tall, grandchild:GetHeight()) end
		end
		return tall
	end
	st:FontsChanged()
	local large = tallest()
	profile.buttons.font = 'pixel'
	st:FontsChanged()
	check(large > tallest(), 'a taller font lays the timers out taller: ' .. large .. ' against ' .. tallest())
	profile.buttons.font = 'pixel_med'
	local face = { font_name = 'Colus', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
	profile.buttons.font = face
	st:FontsChanged()
	check(timer:GetFontObject() == st:FontObject(face), "a typeface in Button text reaches the timer text, and the buttons' texts")
	check(summon.Count:GetFontObject() == st:FontObject(face), 'the count too')
	profile.buttons.font = 'pixel'
	st:FontsChanged()
	eq(#take_errors(), 0, 'no errors')
end)

test("Button text set to Text on the Fonts tab reaches the totem texts and the bag slot bars' texts at once", function()
	local st, TB, summon = totem_world()
	-- A bag slot bar's slot, skinned as the bags skin it: no config, so Core's own
	-- button settings (containers/bag.lua and bank.lua pass nil).
	local slot = CreateFrame('Button', 'FontReadersBagSlot', UIParent)
	slot.Count = slot:CreateFontString(nil, 'ARTWORK')
	st:SkinActionButton(slot, nil, 'slot')
	check(slot.Count:GetFontObject() == st:GetFont('pixel'), 'a bag slot starts in Small text')

	st.config.profile.buttons.font = 'normal' -- the Fonts tab's Button text row
	st:FontsChanged()
	check(slot.Count:GetFontObject() == st:GetFont('normal'), "the bag slot bar's text takes Text at once")
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		check(summon[key]:GetFontObject() == st:GetFont('normal'), 'the totem ' .. key .. ' takes Text at once')
	end
	for _, value in ipairs({ 'gone', 17, false }) do
		st.config.profile.buttons.font = value
		st:FontsChanged()
		check(slot.Count:GetFontObject() == st:GetFont('normal'), 'a bag slot text: Text for ' .. tostring(value))
		check(summon.Count:GetFontObject() == st:GetFont('normal'), 'a totem text: Text for ' .. tostring(value))
	end
	st.config.profile.buttons.font = 'pixel'
	st:FontsChanged()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the buff and debuff timers

test('the buff and debuff timers on a shared font follow it; on a face they keep their size and outline', function()
	local st = T.client('forever')
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua')
	local AP = st:GetModule('Auras')
	st:BindModuleConfig(AP, 'auras')
	local config = st.config.profile.auras

	-- The shipped setting is a face with its own size and outline: Homespun 10.
	local duration = AP:GetFont('buffs', 'duration')
	eqfont(duration, path(st, 'Homespun'), 10, 'MONOCHROMEOUTLINE', 'a face keeps its own size and outline')
	local x, y = duration:GetShadowOffset()
	eq(x .. ',' .. y, '0,0', 'with no shadow')

	config.buffs.duration.size, config.buffs.duration.outline = 14, 'OUTLINE'
	st:FontsChanged()
	eqfont(duration, path(st, 'Homespun'), 14, 'OUTLINE', 'a face takes its size and outline from the setting, again on a font change')

	-- A shared font in the face's place (Task 8 lists them): Text's whole look.
	config.buffs.duration.font = 'normal'
	st.config.profile.fonts.normal.shadow_offset = { 1, -1 }
	st:GetModule('Fonts'):UpdateFontConfig('normal')
	st:FontsChanged()
	eqfont(duration, path(st, 'AgencyFB Bold'), 16, 'OUTLINE', 'a shared font gives its face, size and outline, not the setting\'s')
	x, y = duration:GetShadowOffset()
	eq(x .. ',' .. y, '1,-1', "and its shadow")
	st.config.profile.fonts.normal.font_size = 21
	st:GetModule('Fonts'):UpdateFontConfig('normal')
	st:FontsChanged()
	eqfont(duration, path(st, 'AgencyFB Bold'), 21, 'OUTLINE', "Text's size, at once")

	config.buffs.duration.font = 'gone'
	st:FontsChanged()
	eqfont(duration, st.LSM:Fetch('font', 'gone'), 14, 'OUTLINE', 'a name that is no shared font reads as a face: with the setting\'s size and outline')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ RestedXP

local H = load_test_file('misc/restedxp_helpers.lua')
local RXP = H.RXP

local function rxp_world()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	local RX = H.get_rx()
	assert(pcall(RX.OnEnable, RX))
	return R, RX
end

test("RestedXP's texts take chat's face and outline at RestedXP's sizes, again on a Fonts tab change", function()
	local R, RX = rxp_world()
	local st = SaftUI
	local chat = st.config.profile.chat
	eqfont(R.Footer.text, path(st, 'AgencyFB Bold'), 9, 'OUTLINE', "the footer in chat's face at RestedXP's size")

	chat.font = 'pixel'
	st:FontsChanged()
	eqfont(R.Footer.text, path(st, 'Homespun'), 9, 'MONOCHROMEOUTLINE', 'a Fonts tab or chat change reaches it at once: Small text')

	chat.font = { font_name = 'Colus', font_size = 30, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
	st:FontsChanged()
	eqfont(R.Footer.text, path(st, 'Colus'), 9, '', "a typeface: its face and outline, RestedXP's size (not 30)")

	chat.font = 'normal'
	st.config.profile.fonts.normal.font_outline = 'THICKOUTLINE'
	st:GetModule('Fonts'):UpdateFontConfig('normal')
	st:FontsChanged()
	eqfont(R.Footer.text, path(st, 'AgencyFB Bold'), 9, 'THICKOUTLINE', "Text's outline, from the Fonts tab, at once")

	-- The title keeps its own font until Task 7.
	local title_face = R.GuideName.text:GetFont()
	eq(title_face, path(st, 'Colus'), 'the title keeps Huge title')

	-- A face the game refuses to load draws in Text's face.
	st.LSM:Register('font', 'Refused RXP face', 'Interface\\AddOns\\SaftUI-Core\\Media\\Fonts\\refused-rxp.ttf')
	stub.refused_fonts[path(st, 'Refused RXP face')] = true
	chat.font = { font_name = 'Refused RXP face', font_size = 30, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
	st:FontsChanged()
	eqfont(R.Footer.text, path(st, 'AgencyFB Bold'), 9, '', "a face that fails to load: Text's face at RestedXP's size")
	stub.refused_fonts[path(st, 'Refused RXP face')] = nil

	chat.font = 'gone'
	st:FontsChanged()
	eqfont(R.Footer.text, path(st, 'AgencyFB Bold'), 9, 'THICKOUTLINE', 'a value that names nothing draws Text')
	eq(#take_errors(), 0, 'no errors')
	eq(RX ~= nil, true)
end)

------------------------------------------------------------------ the color picker

local function picker_world(client, off)
	local st = T.client(client)
	_G.ColorPickerFrame = nil
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	local profile = st.config.profile
	if off then profile.skinning.color_picker = false end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua')
	local SK = st:GetModule('Skinning')
	local CP = load_test_file('misc/fixtures/color_picker.lua')
	CP.build({ forever = client == 'forever' })
	SK:Enable()
	return st, SK, CP, profile
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": the color picker's title takes Window titles' font at once, and Blizzard's again with the skin off", function()
		local st, SK, CP, profile = picker_world(client)
		local title = CP.frame.Header.Text
		check(title:GetFontObject() == st:GetFont('normal'), 'the title starts in Window titles')

		profile.headers.font = 'subtitle'
		st:FontsChanged()
		check(title:GetFontObject() == st:GetFont('subtitle'), 'a shared font: at once')
		local face = { font_name = 'Colus', font_size = 12, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
		profile.headers.font = face
		st:FontsChanged()
		check(title:GetFontObject() == st:FontObject(face), "a typeface's own object: at once")

		-- The Skinning font reaches the picker's other texts the same way.
		profile.skinning.font = 'pixel_med'
		st:FontsChanged()
		check(CP.frame.Content.HexBox:GetFontObject() == st:GetFont('pixel_med'), "the hex box takes the Skinning font at once")
		check(CP.frame.Footer.OkayButton:GetNormalFontObject() == st:GetFont('pixel_med'), "and the buttons'")

		-- Skin off: Blizzard's font is put back, and a font change leaves it.
		profile.skinning.color_picker = false
		SK:UpdateConfig()
		check(title:GetFontObject() == GameFontNormal, "the skin off: the title is Blizzard's")
		profile.headers.font = 'pixel'
		st:FontsChanged()
		check(title:GetFontObject() == GameFontNormal, "and a Window titles change leaves it Blizzard's")
		eq(#take_errors(), 0, 'no errors')
		eq(table.concat(CP.stray, ','), '', 'no Blizzard function run from SaftUI')
	end)
end

------------------------------------------------------------------ a value that names nothing

test('the color picker draws Text for a value that names nothing, with no error (the other readers: the tooltip, chat, RestedXP, the buff timers and the totem texts above and in their own files; the skins in characterframe_test, cooldown_viewer_test, objective_tracker_skin_test and theme_test)', function()
	local st, SK, CP, profile = picker_world('forever')
	for _, value in ipairs({ 'gone', 17, false }) do
		profile.headers.font, profile.skinning.font = value, value
		st:FontsChanged()
		check(CP.frame.Header.Text:GetFontObject() == st:GetFont('normal'), 'the picker title: ' .. tostring(value))
		check(CP.frame.Content.HexBox:GetFontObject() == st:GetFont('normal'), 'the hex box: ' .. tostring(value))
		eq(#take_errors(), 0, 'no errors for ' .. tostring(value))
	end
	-- An empty typeface reads as Text's look, as a typeface object of its own.
	profile.headers.font = {}
	st:FontsChanged()
	local face, size, flags = CP.frame.Header.Text:GetFontObject():GetFont()
	local text_face, text_size, text_flags = st:GetFont('normal'):GetFont()
	eq(face .. size .. flags, text_face .. text_size .. text_flags, 'an empty typeface draws as Text')
	eq(#take_errors(), 0, 'no errors for an empty typeface')
	profile.headers.font, profile.skinning.font = 'normal', 'normal'
	eq(SK ~= nil, true)
end)

test('a font change with the color picker skin never installed does not install or restyle it', function()
	local st, SK, CP, profile = picker_world('forever', true) -- the toggle off at login: not installed
	local title = CP.frame.Header.Text
	profile.skinning.color_picker = true -- on in the profile, but nothing installs it until UpdateConfig
	st:FontsChanged()
	check(title:GetFontObject() == GameFontNormal, "the title is still Blizzard's: nothing restyled")
	eq(#take_errors(), 0, 'no errors')
	eq(SK ~= nil and CP ~= nil, true)
end)
