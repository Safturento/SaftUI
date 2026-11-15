-- The action bars' hotkey, stack count and macro name ship the shared font Small
-- text (the key 'pixel') instead of a copy of its face, size and outline, so a
-- Fonts tab change to Small text reaches them. What this pins:
--   - an untouched profile draws what it drew: Homespun 10, monochrome outline,
--     no shadow (Small text's own shadow is 0, 0), on bars 1 to 8 (what
--     LibActionButton is given and what StyleButton puts on the texts) and on
--     the pet and stance bars; and a Small text change reaches them;
--   - the one-time step (AB:ConvertFonts, marked actionbars.fontsVersion) keeps a
--     saved text's look: a size or outline saved without a face (AceDB keeps only
--     what differs from the old default, so the face is not saved) becomes the
--     old copy's face as a typeface; a saved face stays; a profile converted to
--     All bars before is read through its own flags, and a bar that owned only a
--     size owns the face too; every shape on real partial tables, in a profile
--     saved before All bars, in one saved after, and again after a switch, a
--     copy or a reset;
--   - Size and Outline hide while Small text is shown, the resets name "Small
--     text", All bars' diff icon and Apply to tell the truth, and the cooldown
--     numbers are untouched.
--
-- Real: the action bars' files but hideblizzard.lua and keybindmode.lua, in TOC
-- order, over the LibActionButton stand-in the other action bar tests use.
local T = load_test_file('lib/theme_helpers.lua')

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

-- A fresh world. saved is the action bars' part of a profile saved earlier,
-- what AceDB keeps: only what differs from the OLD defaults (face Homespun,
-- size 10, outline monochrome outline). convert false leaves it unconverted.
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
	stub.cvars.countdownForCooldowns = '1'
	if convert ~= false then AB:ConvertProfile() end
end

local function button(name)
	local b = CreateFrame('CheckButton', name, UIParent)
	b.icon = b:CreateTexture(nil, 'BACKGROUND')
	b.Flash = b:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		b[key] = b:CreateFontString(nil, 'OVERLAY')
		b[key]:SetFontObject(GameFontNormal)
	end
	b.cooldown = CreateFrame('Cooldown', nil, b)
	function b:UpdateConfig(config)
		self.labConfig = config
		for key, kind in pairs({ HotKey = 'hotkey', Count = 'count', Name = 'macro' }) do
			local text = config.text[kind]
			self[key]:SetFont(text.font.font, text.font.size, text.font.flags or '')
		end
	end
	AB:SkinButton(b)
	return b
end

local function bar(id, ...)
	local frame = CreateFrame('Frame', AB:GetBarFrameName(id), UIParent)
	frame.id = id
	frame.buttons = { ... }
	AB.bars[id] = frame
	AB:UpdateBar(id)
	return ...
end

local function switch_profile(profile)
	st.config.profile = profile
	apply_defaults()
	st:BindModuleConfig(AB, 'actionbars')
	AB:UpdateConfig()
end

local KINDS = { 'hotkey', 'count', 'macro' }

-- What a bar's text draws: 'path,size,flags,shadowX,shadowY,spacing' of its
-- effective setting, the one look StyleButton and LibActionButton are given.
local function look(id, kind)
	local text = AB:GetBarConfig(id).text[kind]
	local path, size, flags, x, y, spacing = st:FontValues(st:FaceFont(text.font, text.size, text.outline))
	return table.concat({ path, size, flags, x, y, spacing }, ',')
end

-- The look the old default drew: the copy of Small text.
local OLD = table.concat({ 'Homespun', 10, 'MONOCHROMEOUTLINE', 0, 0, 4 }, ',')
local function old_look()
	local path = st.LSM:Fetch('font', 'Homespun')
	return table.concat({ path, 10, 'MONOCHROMEOUTLINE', 0, 0, 4 }, ',')
end
local function face_look(name, size, outline)
	local path, s, flags, x, y, spacing = st:FontValues({ font_name = name, font_size = size, font_outline = outline })
	return table.concat({ path, s, flags, x, y, spacing }, ',')
end

test('a new profile: every text is the shared font Small text, drawing exactly what the copy drew', function()
	fresh()
	for _, id in ipairs(AB.BAR_IDS) do
		for _, kind in ipairs(KINDS) do
			if AB:HasSetting(id, kind .. '.font') then
				eq(AB:GetBarConfig(id).text[kind].font, 'pixel', id .. ' ' .. kind .. ' ships Small text')
				eq(look(id, kind), old_look(), id .. ' ' .. kind .. ': the same face, size, outline, no shadow, spacing')
			end
		end
	end
	eq(AB.config.fontsVersion, 1, 'converted (the marker)')
	eq(st.defaults.actionbars.all.text.hotkey.font, 'pixel', "All bars' shipped font is the key")
	eq(OLD, 'Homespun,10,MONOCHROMEOUTLINE,0,0,4', 'what the copy was')
	eq(select(4, st:FontValues('pixel')) .. ',' .. select(5, st:FontValues('pixel')), '0,0', "Small text's own shadow is 0, 0: nothing to resolve")
	eq(#take_errors(), 0, 'no errors')
end)

test("a button on a new profile has Small text on its texts, no shadow, and the library is given Small text's look", function()
	fresh()
	local b = bar('bar1', button('TextFontDefaultButton'))
	b.Name:SetShadowOffset(1, -1) -- the template's macro name starts with a shadow
	AB:UpdateBar('bar1')
	for key, kind in pairs({ HotKey = 'hotkey', Count = 'count', Name = 'macro' }) do
		check(b[key]:GetFontObject() == st:GetFont('pixel'), key .. ' is Small text')
		eq(T.text(b[key]:GetShadowOffset()), '0.00,0.00', key .. ': no shadow, the macro name too')
		eq(b.labConfig.text[kind].value, 'pixel', "the library's config holds the key")
		local f = b.labConfig.text[kind].font
		eq(table.concat({ f.font, f.size, f.flags }, ','), table.concat({ st:FontValues('pixel') }, ',', 1, 3), "and Small text's path, size and flags")
	end
	-- A Small text change reaches them, one restyle once the frame has run.
	st.config.profile.fonts.pixel.font_size = 14
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	st:FontsChanged()
	stub.run_timers()
	eq(select(2, b.HotKey:GetFont()), 14, 'a Small text size change reaches the hotkey')
	eq(select(2, b.Count:GetFont()), 14, 'the count')
	eq(select(2, b.Name:GetFont()), 14, 'and the macro name, on the library as well as the object')
	eq(#take_errors(), 0, 'no errors')
end)

test('the pet and stance bars: the hotkey is Small text, as before', function()
	fresh()
	for _, id in ipairs({ 'pet', 'stance' }) do
		eq(AB:GetBarConfig(id).text.hotkey.font, 'pixel', id)
		eq(look(id, 'hotkey'), old_look(), id .. ' draws the old look')
	end
end)

-- Saved shapes: what AceDB leaves of a customised text when the OLD defaults
-- applied. A key not listed was at its default.
local SHAPES = {
	{ 'only a size', { size = 14 }, { 'Homespun', 14, 'MONOCHROMEOUTLINE' } },
	{ 'only an outline', { outline = 'OUTLINE' }, { 'Homespun', 10, 'OUTLINE' } },
	{ 'a size and an outline', { size = 12, outline = 'NONE' }, { 'Homespun', 12, 'NONE' } },
	{ 'only a face', { font = 'Colus' }, { 'Colus', 10, 'MONOCHROMEOUTLINE' } },
	{ 'a face and a size', { font = 'Colus', size = 16 }, { 'Colus', 16, 'MONOCHROMEOUTLINE' } },
	{ 'a face, a size and an outline', { font = 'Colus', size = 16, outline = 'THICKOUTLINE' }, { 'Colus', 16, 'THICKOUTLINE' } },
	{ 'a face and an outline', { font = 'Colus', outline = 'OUTLINE' }, { 'Colus', 10, 'OUTLINE' } },
	{ 'nothing', {}, { 'Homespun', 10, 'MONOCHROMEOUTLINE' } },
}

for _, shape in ipairs(SHAPES) do
	local name, saved, spec = unpack(shape)
	local function want() return face_look(unpack(spec)) end
	test('a profile saved before All bars, a text with ' .. name .. ' keeps what it drew; the others follow Small text', function()
		fresh({ bar1 = { text = { hotkey = saved, count = saved, macro = saved } },
			bar3 = { text = { hotkey = saved } }, pet = { text = { hotkey = saved } } }, false)
		AB:ConvertProfile()
		for _, kind in ipairs(KINDS) do eq(look('bar1', kind), want(), 'bar1 ' .. kind) end
		eq(look('bar3', 'hotkey'), want(), 'bar3 hotkey, saved the same way')
		eq(look('pet', 'hotkey'), want(), 'the pet bar')
		eq(look('bar2', 'hotkey'), old_look(), 'bar2, untouched, draws the old look')
		-- Bar 1 gave All bars its values; bar 2, untouched, owns what differs from them.
		eq(AB:GetBarConfig('bar2').text.hotkey.font, 'pixel', 'bar2 is on Small text, owning it where All bars is not')
		eq(AB.config.fontsVersion, 1, 'marked')
		eq(AB.config.version, 1, 'and converted to All bars')
		eq(#take_errors(), 0, 'no errors')
	end)

	test('a profile saved after All bars, All bars\' text with ' .. name .. ' keeps what it drew', function()
		fresh({ version = 1, all = { text = { hotkey = saved, count = saved, macro = saved } } }, false)
		AB:ConvertProfile()
		for _, id in ipairs({ 'bar1', 'bar5', 'stance' }) do
			eq(look(id, 'hotkey'), want(), id .. ' hotkey follows All bars')
		end
		eq(look('bar2', 'macro'), want(), 'macro name too')
		eq(AB.config.fontsVersion, 1, 'marked')
		eq(#take_errors(), 0, 'no errors')
	end)

	test('a profile saved after All bars, a bar that owns its text with ' .. name .. ' keeps what it drew', function()
		local own = {}
		for _, field in ipairs({ 'font', 'size', 'outline' }) do
			if saved[field] ~= nil then own['hotkey.' .. field] = true end
		end
		fresh({ version = 1, bar2 = { own = own, text = { hotkey = saved } } }, false)
		AB:ConvertProfile()
		eq(look('bar2', 'hotkey'), want(), 'bar2 draws what it owned')
		eq(look('bar3', 'hotkey'), old_look(), 'bar3, following All bars, draws the old look')
		eq(AB:GetBarConfig('bar3').text.hotkey.font, 'pixel', 'on Small text')
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('a bar that owned only a size, in a profile saved after All bars, owns the face too and the rest follow Small text', function()
	fresh({ version = 1, bar2 = { own = { ['hotkey.size'] = true }, text = { hotkey = { size = 14 } } } }, false)
	AB:ConvertProfile()
	eq(AB:IsOwn('bar2', 'hotkey.font'), true, 'bar2 owns the face now')
	eq(AB:GetBarConfig('bar2').text.hotkey.font, 'Homespun', "it's the old copy's")
	eq(look('bar2', 'hotkey'), face_look('Homespun', 14, 'MONOCHROMEOUTLINE'), 'drawn as before')
	eq(AB:IsOwn('bar3', 'hotkey.font'), false, 'bar3 owns nothing')
	eq(AB:GetBarConfig('bar3').text.hotkey.font, 'pixel', 'and is on Small text')
	eq(#take_errors(), 0, 'no errors')
end)

test('a bar that owns a size its stale stored values do not matter: a size saved on a bar that does not own it is ignored', function()
	fresh({ version = 1, bar2 = { text = { hotkey = { size = 14 } } } }, false)
	AB:ConvertProfile()
	eq(AB:IsOwn('bar2', 'hotkey.font'), false, 'a stored size no one reads makes nothing own')
	eq(look('bar2', 'hotkey'), old_look(), 'bar2 still draws what All bars does')
end)

test('a bar that owns a shared font (picked in the Font row before) keeps it, whatever size All bars has', function()
	fresh({ version = 1, all = { text = { hotkey = { size = 14 } } }, bar2 = { own = { ['hotkey.font'] = true }, text = { hotkey = { font = 'heading' } } } }, false)
	AB:ConvertProfile()
	eq(AB:GetBarConfig('bar2').text.hotkey.font, 'heading', 'Heading stays')
	eq(AB:GetBarConfig('bar1').text.hotkey.font, 'Homespun', 'a bar that follows All bars: its size 14 on the old face')
	eq(look('bar1', 'hotkey'), face_look('Homespun', 14, 'MONOCHROMEOUTLINE'), 'as it drew')
end)

test('the step runs once: a text set after it is not converted again, and not a countdown', function()
	fresh({ bar1 = { text = { hotkey = { size = 14 }, countdown = { size = 20 } } } }, false)
	AB:ConvertProfile()
	eq(AB:GetBarConfig('bar1').text.hotkey.font, 'Homespun', 'converted')
	eq(AB.config.all.text.countdown.font, nil, 'the cooldown numbers have no font to convert')
	eq(AB.config.all.text.countdown.size, 20, 'and keep their size')
	-- The player then picks Small text and leaves a custom size: not converted again.
	AB:SetSetting('all', 'hotkey.font', 'pixel')
	AB:SetSetting('all', 'hotkey.size', 17)
	AB:ConvertProfile()
	eq(AB:GetBarConfig('bar1').text.hotkey.font, 'pixel', 'Small text stays picked')
	eq(AB.config.fontsVersion, 1, 'the marker holds')
	-- Nothing but the text tables changed.
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile switched to, copied or reset is converted: its texts keep what they drew', function()
	fresh()
	AB.built = true
	function AB:UpdateBindings() end
	switch_profile({ actionbars = { bar1 = { text = { hotkey = { size = 14 } } } } })
	eq(AB.config.fontsVersion, 1, 'switched to: marked')
	eq(look('bar1', 'hotkey'), face_look('Homespun', 14, 'MONOCHROMEOUTLINE'), 'and its size kept')
	-- A copy carries the marker: not converted twice (a size saved with a picked Small text stays).
	AB:SetSetting('all', 'hotkey.font', 'pixel')
	AB:SetSetting('all', 'hotkey.size', 21)
	switch_profile(st.config.profile)
	eq(AB:GetBarConfig('bar1').text.hotkey.font, 'pixel', 'a converted profile is not converted again')
	-- A reset profile has defaults and no marker, and converts to nothing.
	switch_profile({})
	eq(AB.config.fontsVersion, 1, 'reset: marked')
	eq(look('bar1', 'hotkey'), old_look(), 'and on Small text')
	eq(#take_errors(), 0, 'no errors')
end)

test('the conversion also runs when a Fonts tab change reaches a profile switched to (OnFontsChanged runs before UpdateConfig)', function()
	fresh()
	AB.built = true
	st.config.profile = { actionbars = { bar1 = { text = { hotkey = { size = 14 } } } } }
	apply_defaults()
	st:BindModuleConfig(AB, 'actionbars')
	AB:OnFontsChanged()
	eq(AB.config.fontsVersion, 1, 'converted before anything is drawn')
	eq(AB:GetBarConfig('bar1').text.hotkey.font, 'Homespun', 'the face is the old copy')
end)

test('Size and Outline hide while Small text shows and show on a converted text, the resets name Small text, the diff icon tells the truth', function()
	fresh({ version = 1, all = { text = { hotkey = { size = 14 } } } }, false)
	AB:ConvertProfile()
	-- Every bar follows All bars: Homespun 14, a face.
	local all = AB:GetTextItem('all', 'hotkey', 1)
	eq(all.menu.args.size.hidden(), false, "All bars' Size shows: its font is a face")
	eq(all.menu.args.font.default.differs(), true, 'and the font differs from the default')
	eq(all.menu.args.font.default.text(), 'Small text', "the reset names Small text")
	local share = AB:ShareFor('all', 'hotkey.font')
	eq(share.shared(), 'Homespun', "the diff icon's All bars value")
	AB:SetSetting('all', 'hotkey.font', 'pixel')
	eq(all.menu.args.size.hidden(), true, 'Size hides on Small text, since no bar owns one')
	eq(all.menu.args.outline.hidden(), true, 'and Outline')
	eq(all.menu.args.font.default.differs(), false, 'and the font is at its default')
	eq(share.shared(), 'Small text', 'by its name')

	fresh()
	local item = AB:GetTextItem('bar3', 'macro', 1)
	eq(item.menu.args.size.hidden(), true, "a new profile's Size is hidden")
	eq(item.menu.args.outline.hidden(), true, "and Outline")
	for _, kind in ipairs(KINDS) do
		eq(AB:GetTextItem('all', kind, 1).menu.args.font.default.differs(), false, kind .. ': no reset showing on All bars')
	end
	AB:SetSetting('all', 'hotkey.font', 'Colus')
	local font = AB:GetTextItem('all', 'hotkey', 1).menu.args.font
	eq(font.default.differs(), true, 'a face differs')
	font.default.reset()
	eq(AB:GetSetting('all', 'hotkey.font'), 'pixel', "the reset writes Small text")
	eq(AB:ValueText('hotkey.font', 'pixel'), 'Small text', 'in words')
	-- Apply to with the default: a bar made to follow, its own font cleared.
	AB:SetSetting('bar6', 'hotkey.font', 'heading')
	AB:ApplyTo('all', 'hotkey.font', { 'bar6' })
	eq(AB:IsOwn('bar6', 'hotkey.font'), false, 'Apply to from All bars makes a bar follow')
	eq(AB:GetBarConfig('bar6').text.hotkey.font, 'pixel', 'on Small text')
	eq(#take_errors(), 0, 'no errors')
end)

test('the cooldown numbers are untouched: no default font, Large numbers on big buttons and Small text on small ones', function()
	fresh()
	eq(AB.config.all.text.countdown.font, nil, 'no font shipped')
	eq(AB:CountdownValue({ size = 45, text = { countdown = {} } }), 'pixel_med', 'Large numbers on a 45 button')
	eq(AB:CountdownValue({ size = 30, text = { countdown = {} } }), 'pixel', 'Small text on a 30 button')
end)

test('the source: the shipped texts name the key, and the library is not touched', function()
	local code = select(1, load_test_file('lib/source_lex.lua').Lex(read_saftui_source('SaftUI-ActionBars/config.lua')))
	check(code:find("font = 'pixel'", 1, true), "Text() ships font = 'pixel'")
	check(not code:find('font = pixel.font_name', 1, true), 'no copy of the face')
end)

-- A bar that owned its font where the owned font was the old default face: AceDB
-- never saved it, so it reads Small text now beside the size it owned or follows.
test('a bar that owned the old default face (unsaved) and its own size keeps what it drew', function()
	fresh({ version = 1, all = { text = { hotkey = { font = 'Colus' } } },
		bar2 = { own = { ['hotkey.font'] = true, ['hotkey.size'] = true }, text = { hotkey = { size = 14 } } } }, false)
	AB:ConvertProfile()
	eq(look('bar2', 'hotkey'), face_look('Homespun', 14, 'MONOCHROMEOUTLINE'), 'bar2 draws Homespun 14')
	eq(look('bar3', 'hotkey'), face_look('Colus', 10, 'MONOCHROMEOUTLINE'), 'bar3 follows All bars')
	eq(AB:IsOwn('bar2', 'hotkey.font'), true, 'bar2 still owns the font')
end)

test("a bar that owned the old default face (unsaved) and followed All bars' size keeps what it drew", function()
	fresh({ version = 1, all = { text = { hotkey = { font = 'Colus', size = 14 } } },
		bar2 = { own = { ['hotkey.font'] = true }, text = { hotkey = {} } } }, false)
	AB:ConvertProfile()
	eq(look('bar2', 'hotkey'), face_look('Homespun', 14, 'MONOCHROMEOUTLINE'), 'bar2 draws Homespun 14')
end)

test('a bar that owned the old default face and only an outline keeps what it drew', function()
	fresh({ version = 1, all = { text = { hotkey = { font = 'Colus' } } },
		bar2 = { own = { ['hotkey.font'] = true, ['hotkey.outline'] = true }, text = { hotkey = { outline = 'OUTLINE' } } } }, false)
	AB:ConvertProfile()
	eq(look('bar2', 'hotkey'), face_look('Homespun', 10, 'OUTLINE'), 'bar2 draws Homespun with an outline')
end)

test('a bar that owns only an outline, following All bars Small text, owns the face too', function()
	fresh({ version = 1, bar2 = { own = { ['hotkey.outline'] = true }, text = { hotkey = { outline = 'THICKOUTLINE' } } } }, false)
	AB:ConvertProfile()
	eq(look('bar2', 'hotkey'), face_look('Homespun', 10, 'THICKOUTLINE'), 'bar2')
	eq(look('bar3', 'hotkey'), old_look(), 'bar3 is on Small text')
end)

test('a bar that owns a typeface keeps it, and a reset flag with stale values follows All bars', function()
	fresh({ version = 1, all = { text = { hotkey = { size = 14 } } },
		bar2 = { own = { ['hotkey.font'] = true }, text = { hotkey = { font = 'Colus' } } },
		bar3 = { own = { ['hotkey.font'] = false, ['hotkey.size'] = false }, text = { hotkey = { font = 'Colus', size = 20 } } } }, false)
	AB:ConvertProfile()
	eq(look('bar2', 'hotkey'), face_look('Colus', 14, 'MONOCHROMEOUTLINE'), "bar2 keeps Colus at All bars' size")
	eq(look('bar3', 'hotkey'), look('bar1', 'hotkey'), 'bar3 follows All bars')
	eq(AB:IsOwn('bar3', 'hotkey.font'), false, 'and still does')
end)

test('the cooldown numbers: a bar that owns a size or font alone is not touched by the step', function()
	fresh({ version = 1, bar2 = { own = { ['countdown.size'] = true }, text = { countdown = { size = 22 } } } }, false)
	AB:ConvertProfile()
	eq(AB.config.bar2.text.countdown.font, nil, 'no font written')
	eq(AB:IsOwn('bar2', 'countdown.font'), false, 'none owned')
	eq(AB:GetBarConfig('bar2').text.countdown.size, 22, 'its size stays')
end)

test('a drawn button on a converted profile: bar 2 owning the old face and a size draws it, library and object', function()
	fresh({ version = 1, bar2 = { own = { ['hotkey.size'] = true }, text = { hotkey = { size = 14 } } } }, false)
	AB:ConvertProfile()
	local b = bar('bar2', button('TextFontShapeButton'))
	eq(select(2, b.HotKey:GetFont()), 14, 'the hotkey draws 14')
	eq(b.labConfig.text.hotkey.font.size, 14, 'and the library is given 14')
	eq(b.HotKey:GetFontObject(), st:FontObject({ font_name = 'Homespun', font_size = 14, font_outline = 'MONOCHROMEOUTLINE' }), 'on the typeface object')
end)
