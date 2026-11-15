-- The buffs' and debuffs' Duration and Stack count texts ship the shared font
-- Small text (the key 'pixel') instead of a copy of its face, size and outline,
-- so a Fonts tab change to Small text reaches them. What this pins:
--   - an untouched profile draws what it drew: Homespun 10, monochrome outline,
--     no shadow, and a Small text change reaches the timers at once;
--   - the one-time step (AP:ConvertFonts, marked auras.fontsVersion) keeps a
--     saved text's look: a size or outline saved without a face (AceDB keeps only
--     what differs from the old default) becomes the old copy's face as a
--     typeface, a saved face stays; each shape on real partial tables, for both
--     frames and both texts, and again after a switch, a copy or a reset;
--   - Size and Outline hide while Small text shows, and the Font row's reset
--     names Small text.
--
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and
-- Blizzard_BuffFramePosition.lua over Core's helpers and the options model.
local T = load_test_file('lib/theme_helpers.lua')

local st, AP

-- A fresh world. saved: the auras part of a profile saved earlier (what AceDB
-- keeps over the OLD defaults).
local function fresh(saved)
	st = T.client('forever')
	load_saftui('SaftUI-Misc/config.lua')
	if saved then st.config.profile.auras = saved end
	apply_defaults()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua')
	AP = st:GetModule('Auras')
	st:BindModuleConfig(AP, 'auras')
	return AP
end

local FRAMES, KINDS = { 'buffs', 'debuffs' }, { 'duration', 'count' }

-- What the timer font object draws, 'path,size,flags,shadow'.
local function drawn(key, kind)
	local object = AP:GetFont(key, kind)
	local path, size, flags = object:GetFont()
	local x, y = object:GetShadowOffset()
	return table.concat({ path, size, flags, x .. '/' .. y }, ',')
end

local function face(name, size, outline)
	return table.concat({ st.LSM:Fetch('font', name), size, outline == 'NONE' and '' or outline, '0/0' }, ',')
end

local OLD = function() return face('Homespun', 10, 'MONOCHROMEOUTLINE') end

test('a new profile: every text is the shared font Small text, drawing what the copy drew', function()
	fresh()
	AP:ConvertFonts()
	for _, key in ipairs(FRAMES) do
		for _, kind in ipairs(KINDS) do
			eq(st.config.profile.auras[key][kind].font, 'pixel', key .. ' ' .. kind .. ' ships Small text')
			eq(drawn(key, kind), OLD(), key .. ' ' .. kind .. ': the same face, size, outline, no shadow')
		end
	end
	eq(st.defaults.auras.buffs.duration.font, 'pixel', 'the default is the key')
	eq(AP.config.fontsVersion, 1, 'marked')
	-- A Small text change reaches them.
	st.config.profile.fonts.pixel.font_size = 13
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	st:FontsChanged()
	for _, key in ipairs(FRAMES) do
		for _, kind in ipairs(KINDS) do
			eq(select(2, AP:GetFont(key, kind):GetFont()), 13, key .. ' ' .. kind .. ' follows Small text at once')
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

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
	test('a profile saved before, a text with ' .. name .. ' keeps what it drew; the others follow Small text', function()
		fresh({ buffs = { duration = saved }, debuffs = { count = saved } })
		AP:ConvertFonts()
		eq(drawn('buffs', 'duration'), face(unpack(spec)), 'buffs duration')
		eq(drawn('debuffs', 'count'), face(unpack(spec)), 'debuffs count')
		eq(drawn('buffs', 'count'), OLD(), 'buffs count, untouched')
		eq(drawn('debuffs', 'duration'), OLD(), 'debuffs duration, untouched')
		eq(st.config.profile.auras.buffs.count.font, 'pixel', 'which follows Small text')
		eq(AP.config.fontsVersion, 1, 'marked')
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('the step runs once, and the text is then left alone', function()
	fresh({ buffs = { duration = { size = 14 } } })
	AP:ConvertFonts()
	eq(AP.config.buffs.duration.font, 'Homespun', 'converted')
	-- Small text picked later with a size kept: not converted again.
	AP.config.buffs.duration.font = 'pixel'
	AP:ConvertFonts()
	eq(AP.config.buffs.duration.font, 'pixel', 'Small text stays picked')
end)

test('a profile switched to is converted before its fonts are read; a copy is not converted twice; a reset converts to nothing', function()
	fresh()
	AP:ConvertFonts()
	-- A switch: Config:UpdateConfig points the module at the new profile, then st:FontsChanged runs
	-- AP:OnFontsChanged before AP:UpdateConfig.
	st.config.profile = { auras = { buffs = { count = { size = 18 } } } }
	apply_defaults()
	st:BindModuleConfig(AP, 'auras')
	st:FontsChanged()
	eq(AP.config.fontsVersion, 1, 'marked')
	eq(drawn('buffs', 'count'), face('Homespun', 18, 'MONOCHROMEOUTLINE'), 'its size kept')
	-- A profile carrying the marker is left alone.
	AP.config.buffs.count.font = 'pixel'
	AP:UpdateConfig()
	eq(AP.config.buffs.count.font, 'pixel', 'a converted profile (a copy) is not converted again')
	-- A reset has no marker and defaults.
	st.config.profile = {}
	apply_defaults()
	st:BindModuleConfig(AP, 'auras')
	AP:UpdateConfig()
	eq(AP.config.fontsVersion, 1, 'reset: marked')
	eq(drawn('buffs', 'count'), OLD(), 'and on Small text')
	eq(#take_errors(), 0, 'no errors')
end)

test('Size and Outline hide while Small text shows; the Font rows reset to Small text', function()
	fresh()
	AP:ConvertFonts()
	local real = { UpdateText = AP.UpdateText, GetGeometry = AP.GetGeometry }
	AP.holders = { buffs = CreateFrame('Frame', nil, UIParent), debuffs = CreateFrame('Frame', nil, UIParent) }
	AP.maxAuras = { buffs = 32, debuffs = 16 }
	function AP:GetGeometry() return { horizontal = true, grow = 'LEFT', wrap = 'DOWN' } end
	function AP:UpdateText() end
	local tree = AP:GetConfigTable()
	for _, key in ipairs(FRAMES) do
		for _, kind in ipairs(KINDS) do
			local group = tree.args[key].args.text.args[kind]
			eq(group.args.size.hidden(), true, key .. ' ' .. kind .. ': Size hides on Small text')
			eq(group.args.outline.hidden(), true, 'and Outline')
			check(group.args.font.default ~= nil, 'the Font row has a reset')
			eq(group.args.font.default.differs(), false, 'at its default it shows none')
			group.set({ 'font' }, 'Colus')
			eq(group.args.size.hidden(), false, 'a face shows Size')
			eq(group.args.font.default.differs(), true, 'and the reset')
			eq(group.args.font.default.text, 'Small text', 'which names Small text')
			group.args.font.default.reset()
			eq(AP.config[key][kind].font, 'pixel', 'and puts Small text back')
		end
	end
	for name, fn in pairs(real) do AP[name] = fn end
	eq(#take_errors(), 0, 'no errors')
end)

test('the source: the shipped texts name the key', function()
	local code = select(1, load_test_file('lib/source_lex.lua').Lex(read_saftui_source('SaftUI-Misc/config.lua')))
	check(not code:find('font = pixel.font_name', 1, true), 'no copy of the face in the defaults')
end)

test("the buffs' Size and Outline resets: differs, value and reset put the shipped 10 and monochrome outline back", function()
	fresh()
	AP:ConvertFonts()
	local real = { UpdateText = AP.UpdateText, GetGeometry = AP.GetGeometry }
	AP.holders = { buffs = CreateFrame('Frame', nil, UIParent), debuffs = CreateFrame('Frame', nil, UIParent) }
	AP.maxAuras = { buffs = 32, debuffs = 16 }
	function AP:GetGeometry() return { horizontal = true, grow = 'LEFT', wrap = 'DOWN' } end
	function AP:UpdateText() end
	local tree = AP:GetConfigTable()
	for _, key in ipairs(FRAMES) do
		for _, kind in ipairs(KINDS) do
			local group = tree.args[key].args.text.args[kind]
			local size, outline = group.args.size.default, group.args.outline.default
			eq(size.differs(), false, 'Size at its default')
			eq(outline.differs(), false, 'Outline at its default')
			group.set({ 'size' }, 14)
			group.set({ 'outline' }, 'OUTLINE')
			eq(size.differs(), true, key .. ' ' .. kind .. ': Size differs')
			eq(outline.differs(), true, 'Outline differs')
			eq(size.value(), 10, "Size's default value")
			eq(outline.value(), 'MONOCHROMEOUTLINE', "Outline's default value")
			size.reset()
			outline.reset()
			eq(AP.config[key][kind].size, 10, 'Size reset')
			eq(AP.config[key][kind].outline, 'MONOCHROMEOUTLINE', 'Outline reset')
		end
	end
	for name, fn in pairs(real) do AP[name] = fn end
	eq(#take_errors(), 0, 'no errors')
end)

test('AP:OnEnable converts the profile before anything is drawn', function()
	fresh({ buffs = { duration = { size = 14 } } })
	AP.config = nil
	AP:OnEnable()
	eq(AP.config.fontsVersion, 1, 'marked at login')
	eq(AP.config.buffs.duration.font, 'Homespun', 'the size-only text keeps its face')
	eq(select(2, AP:GetFont('buffs', 'duration'):GetFont()), 14, 'and its size, in the first draw')
end)
