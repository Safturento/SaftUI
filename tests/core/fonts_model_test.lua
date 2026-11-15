-- The shared fonts and the value of a font setting (SaftUI-Core/Media/fonts.lua):
-- the six shared fonts in FN.FONTS, the two dropped ones in FN.DROPPED, the
-- helpers that read a setting's two shapes (a shared font's key, or a typeface
-- table: st:FontFields, st:GetFont, st:FontObject, st:ApplyFont, st:FontValues,
-- st:FontLabel, st:IsSharedFont, st:FaceFont), what keeps a text following a
-- font (st:FollowFont, st:FontsChanged), the preload of SaftUI's faces and
-- Heading's one-time face step.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua: the
-- Fonts module enabled, LibSharedMedia, Core's real defaults), so a profile
-- switch, copy or reset runs the real Config:UpdateConfig.

load_test_file('core/config_helpers.lua')
local st = SaftUI

local FN = st:GetModule('Fonts')
local fonts = function() return st.config.profile.fonts end

local function path(name) return st.LSM:Fetch('font', name) end

-- Every value of a call in a list, to compare with eq.
local function list(...) return { n = select('#', ...), ... } end
local function eqlist(actual, expected, message)
	eq(actual.n, #expected, message .. ' (how many)')
	for i = 1, #expected do eq(actual[i], expected[i], message .. ' #' .. i) end
end

local KEYS = { 'normal', 'pixel', 'pixel_med', 'heading', 'title', 'subtitle' }
local NAMES = { 'Text', 'Small text', 'Large numbers', 'Heading', 'Huge title', 'Subtitle' }

test('six shared fonts in order, named in code, objects named by key; a saved name is ignored', function()
	eq(#FN.FONTS, 6, 'six shared fonts')
	for i, key in ipairs(KEYS) do
		eq(FN.FONTS[i].key, key, 'key ' .. i)
		eq(FN.FONTS[i].name, NAMES[i], 'name ' .. i)
		eq(type(FN.FONTS[i].job), 'string', 'a job for ' .. key)
		eq(FN:Font(key), FN.FONTS[i], 'FN:Font finds ' .. key)
		eq(st:GetFont(key):GetName(), 'SaftUI_' .. key .. 'Font', 'object named by key: ' .. key)
		eq(st:GetFont(key), FN.font_objects[key], key .. ' is in FN.font_objects')
	end
	eq(FN:Font('pixel_huge'), nil, 'a dropped key is no shared font')
	eq(FN:Font('nope'), nil, 'nor is an unknown one')
	eq(FN:Font(nil), nil, 'nor nil')

	fonts().normal.name = 'Mine'
	eq(st:FontLabel('normal'), 'Text', 'a saved name is ignored')
	fonts().normal.name = nil

	eq(st.defaults.fonts.pixel_huge, nil, 'Pixel Huge is gone from the defaults')
	eq(st.defaults.fonts.normal_med, nil, 'and Normal Med')
	for _, key in ipairs(KEYS) do
		eq(st.defaults.fonts[key].name, nil, 'no name in the default of ' .. key)
	end
end)

test('Heading ships as Colus 15, Outline, shadow 0, 0, line spacing 4', function()
	local heading = st:GetFont('heading')
	eqlist(list(heading:GetFont()), { path('Colus'), 15, 'OUTLINE' }, 'its font')
	eqlist(list(heading:GetShadowOffset()), { 0, 0 }, 'its shadow')
	eq(heading:GetSpacing(), 4, 'its line spacing')
end)

test('strings: a shared key is its object, a dropped key its old look, anything else nil', function()
	eq(st:GetFont('pixel'), FN.font_objects.pixel, 'a shared key is its object')
	eqlist(list(st:GetFont('pixel_huge'):GetFont()), { path('Homespun'), 32, 'MONOCHROMEOUTLINE' }, 'Pixel Huge')
	eqlist(list(st:GetFont('normal_med'):GetFont()), { path('AgencyFB Bold'), 24, 'OUTLINE' }, 'Normal Med')
	eq(st:GetFont('nope'), nil, 'an unknown key')
	eq(st:GetFont(nil), nil, 'nil')
	eq(st:GetFont(12), nil, 'a number')
end)

test("a dropped key with saved edits: its old look with the profile's fields over it; nothing written", function()
	fonts().pixel_huge = { font_size = 40 }
	local fields = st:FontFields('pixel_huge')
	eq(fields.font_size, 40, "the profile's size")
	eq(fields.font_name, 'Homespun', 'the old face')
	eq(select(2, st:GetFont('pixel_huge'):GetFont()), 40, 'drawn at 40')
	local key = next(fonts().pixel_huge)
	eq(key, 'font_size', 'the saved table has only what was saved')
	eq(next(fonts().pixel_huge, key), nil, 'and only that')
	check(pcall(FN.UpdateFontConfig, FN), 'updating every font errors on nothing')
	eq(FN.font_objects.pixel_huge, nil, 'and makes no object for it')
	eq(#take_errors(), 0, 'no errors')
	fonts().pixel_huge = nil
end)

test('a typeface table: one object per look, white, made once and never changed', function()
	local a = st:GetFont({ font_name = 'Colus', font_size = 15 })
	local b = st:GetFont({ font_name = 'Colus', font_size = 15, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 })
	eq(a, b, 'the same look written out in full is the same object')
	eq(select(2, a:GetFont()), 15, 'at 15')
	eqlist(list(a:GetTextColor()), { 1, 1, 1, 1 }, 'white')
	local c = st:GetFont({ font_name = 'Colus', font_size = 16 })
	check(c ~= a, 'another look, another object')
	eq(select(2, a:GetFont()), 15, 'the first is still 15')
	check(a:GetName():match('^SaftUI_Typeface%d+Font$'), 'named for its number: ' .. tostring(a:GetName()))
	eq(st:GetFont('pixel_huge'), st:GetFont('pixel_huge'), 'a dropped key is one object too')
	check(st:GetFont('pixel_huge') ~= st:GetFont('pixel'), 'and not its shared font')
	-- Another shadow, another spacing, another outline: each a look.
	local base = { font_name = 'Colus', font_size = 15 }
	for _, change in ipairs({ { 'font_outline', 'NONE' }, { 'shadow_offset', { 1, 0 } }, { 'shadow_offset', { 0, 1 } },
		{ 'spacing', 9 }, { 'font_name', 'Homespun' } }) do
		local look = { font_name = 'Colus', font_size = 15 }
		look[change[1]] = change[2]
		check(st:GetFont(look) ~= st:GetFont(base), change[1] .. ' ' .. tostring(change[2]) .. ' makes another look')
	end
	eq(#take_errors(), 0, 'no errors')
end)

-- Every SetFont call on an object, as { size, flags }, while fn runs.
local function SetFontCalls(object, fn)
	local calls, real = {}, object.SetFont
	object.SetFont = function(self, p, size, flags)
		calls[#calls + 1] = { p, size, flags }
		return real(self, p, size, flags)
	end
	fn()
	object.SetFont = real
	return calls
end

test('the size nudge, one up and straight back, on a shared update; a new typeface is set once', function()
	local calls = SetFontCalls(FN.font_objects.pixel, function() FN:UpdateFontConfig('pixel') end)
	check(#calls >= 3, 'SetFont ran for the face, then twice more')
	local n = #calls
	eq(calls[n - 1][2], 11, 'one up (Small text is 10)')
	eq(calls[n][2], 10, 'and straight back')
	eq(calls[n][1], path('Homespun'), 'in its face')
	eq(calls[n][3], 'MONOCHROMEOUTLINE', 'and outline')

	-- A typeface's object is made inside st:GetFont: watch CreateFont.
	local made, real = nil, CreateFont
	local sizes = {}
	CreateFont = function(name)
		local font = real(name)
		made = font
		local inner = font.SetFont
		font.SetFont = function(self, p, size, flags)
			sizes[#sizes + 1] = size
			return inner(self, p, size, flags)
		end
		return font
	end
	local object = st:GetFont({ font_name = 'Colus', font_size = 31 })
	CreateFont = real
	eq(object, made, 'the object was made by CreateFont')
	-- No bounce for a new object: nothing is on it to measure again (M10).
	eq(sizes[#sizes], 31, 'a new typeface is set once, at its size')
	check(sizes[#sizes - 1] ~= 32, 'and does not go one up')
	eq(select(2, object:GetFont()), 31, 'and stays at its size')
	eqlist(list(object:GetShadowColor()), { 0, 0, 0, 1 }, 'with an opaque black shadow')
end)

test('a malformed typeface (Review Focus 2)', function()
	local function size(t) return st:FontFields(t).font_size end
	eq(size({ font_name = 'Colus', font_size = '12' }), 16, "a string size reads as Text's default")
	eq(size({ font_size = 0 }), 1, 'a size under 1 is 1')
	eq(size({ font_size = 400 }), 100, 'a size over 100 is 100')
	eqlist(list(unpack(st:FontFields({ shadow_offset = 3 }).shadow_offset)), { 0, 0 }, 'a shadow that is no table')
	eqlist(list(unpack(st:FontFields({ shadow_offset = { 9, -9 } }).shadow_offset)), { 5, -5 }, 'a shadow clamped')
	eqlist(list(unpack(st:FontFields({ shadow_offset = { 'a', 2 } }).shadow_offset)), { 0, 2 }, 'a shadow with a non-number on one axis: the other axis is kept')
	eqlist(list(unpack(st:FontFields({ shadow_offset = { 2 } }).shadow_offset)), { 2, 0 }, 'a shadow with only X')
	eqlist(list(unpack(st:FontFields({ shadow_offset = { [2] = -1 } }).shadow_offset)), { 0, -1 }, 'a shadow with only Y')
	eq(size({ font_size = 0 / 0 }), 16, 'a NaN size is no number')
	eq(st:FontFields({ font_outline = 'BOLD' }).font_outline, 'OUTLINE', 'an outline that is no key')
	eq(st:FontFields({ font_name = '' }).font_name, 'AgencyFB Bold', 'an empty face')
	eq(st:FontFields({ font_name = 7 }).font_name, 'AgencyFB Bold', 'a face that is no string')
	eq(st:FontFields({ spacing = 99 }).spacing, 20, 'spacing clamped')
	eq(st:FontFields({ spacing = -3 }).spacing, 0, 'spacing under 0')

	local one = st:GetFont({ font_name = 'Colus', font_size = '12' })
	eq(one, st:GetFont({ font_name = 'Colus', font_size = 16 }), 'one object per resulting look')
	eq(st:GetFont({ font_size = 0 }), st:GetFont({ font_size = 1 }), 'a clamped size is the clamped look')
	eq(st:GetFont({ font_size = 400 }), st:GetFont({ font_size = 100 }), 'also at the top')
	eq(st:GetFont({ shadow_offset = 3 }), st:GetFont({ shadow_offset = { 0, 0 } }), 'a shadow that is no table is 0, 0')
	eq(st:GetFont({ font_outline = 'BOLD' }), st:GetFont({ font_outline = 'OUTLINE' }), 'an outline that is no key')
	eq(#take_errors(), 0, 'no errors')

	local fresh = st:FontFields({ font_size = 20 })
	fresh.font_size = 1
	eq(st:FontFields({ font_size = 20 }).font_size, 20, 'every call returns a fresh table')
	eq(fonts().normal.font_size, 16, 'and the profile is not written')
end)

test('a face LibSharedMedia does not list (Review Focus 1)', function()
	local default = st.LSM:Fetch('font', st.LSM:GetDefault('font'))
	eqlist(list(st:FontValues({ font_name = 'Gone' })), { default, 16, 'OUTLINE', 0, 0, 4 }, 'it draws in the default face')
	eq(st:FontLabel({ font_name = 'Gone', font_size = 12 }), 'Gone 12, outline', 'and is named as saved')
	local object = st:GetFont({ font_name = 'Gone', font_size = 12 })
	eq(object:GetFont(), default, 'its object draws in the default face')
	eq(#take_errors(), 0, 'no errors')
end)

test('FontValues, FontLabel, IsSharedFont, FaceFont', function()
	eqlist(list(st:FontValues('normal')), { path('AgencyFB Bold'), 16, 'OUTLINE', 0, 0, 4 }, 'Text')
	eqlist(list(st:FontValues('pixel')), { path('Homespun'), 10, 'MONOCHROMEOUTLINE', 0, 0, 4 }, 'Small text')
	eqlist(list(st:FontValues({ font_name = 'Homespun', font_size = 10, font_outline = 'NONE' })),
		{ path('Homespun'), 10, '', 0, 0, 4 }, 'a typeface with no outline has no flags')
	eqlist(list(st:FontValues({ font_name = 'Colus', shadow_offset = { 2, -1 }, spacing = 7 })),
		{ path('Colus'), 16, 'OUTLINE', 2, -1, 7 }, 'a typeface with a shadow and spacing')

	eq(st:FontLabel('heading'), 'Heading')
	eq(st:FontLabel({ font_name = 'Colus', font_size = 15 }), 'Colus 15, outline')
	eq(st:FontLabel({ font_name = 'Homespun', font_size = 10, font_outline = 'NONE' }), 'Homespun 10')
	eq(st:FontLabel('pixel_huge'), 'Homespun 32, monochrome outline')
	eq(st:FontLabel('normal_med'), 'AgencyFB Bold 24, outline')
	eq(st:FontLabel(nil), 'Text')
	eq(st:FontLabel('nope'), 'Text')
	eq(st:FontLabel(12), 'Text')

	eq(st:IsSharedFont('pixel'), true)
	eq(st:IsSharedFont('pixel_huge'), false)
	eq(st:IsSharedFont({}), false)
	eq(st:IsSharedFont(nil), false)

	eq(st:FaceFont('pixel', 9, 'NONE'), 'pixel')
	local face = st:FaceFont('Colus', 12, 'OUTLINE')
	eq(type(face), 'table')
	eq(face.font_name, 'Colus')
	eq(face.font_size, 12)
	eq(face.font_outline, 'OUTLINE')
	eq(face.shadow_offset, nil, 'no shadow of its own')
	eq(st:GetFont(face):GetFont(), path('Colus'), 'and it draws')
end)

test('ApplyFont draws Text for nil, an unknown key and a number, and never errors', function()
	local fs = CreateFrame('Frame'):CreateFontString()
	st:ApplyFont(fs, 'pixel')
	eq(fs:GetFontObject(), st:GetFont('pixel'), 'a shared font')
	st:ApplyFont(fs, nil)
	eq(fs:GetFontObject(), st:GetFont('normal'), 'nil is Text')
	st:ApplyFont(fs, 'pixel')
	st:ApplyFont(fs, 'nope')
	eq(fs:GetFontObject(), st:GetFont('normal'), 'an unknown key is Text')
	st:ApplyFont(fs, 'pixel')
	st:ApplyFont(fs, 12)
	eq(fs:GetFontObject(), st:GetFont('normal'), 'a number is Text')
	st:ApplyFont(fs, { font_name = 'Colus', font_size = 15 })
	eq(fs:GetFontObject(), st:GetFont({ font_name = 'Colus', font_size = 15 }), 'a typeface')
	st:ApplyFont(fs, 'pixel_huge')
	eq(fs:GetFontObject(), st:GetFont('pixel_huge'), 'a dropped key')
	eq(st:FontObject('nope'), st:GetFont('normal'), 'FontObject falls back to Text')
	eq(st:FontObject('pixel'), st:GetFont('pixel'), 'and gives the shared font')
	eq(#take_errors(), 0, 'no errors')
end)

-- Ruling 2: no nil guard. A font object is what SetFontObject takes (the
-- game's SetFontObject refuses nil on both clients), so with no Text object a
-- value that names nothing errors where a guard would hide a broken load.
test('ApplyFont is exactly SetFontObject(FontObject(value)): with no Text object it errors, as the game does', function()
	local fs = CreateFrame('Frame'):CreateFontString()
	local real = FN.font_objects.normal
	FN.font_objects.normal = nil
	local ok = pcall(st.ApplyFont, st, fs, nil)
	local okShared = pcall(st.ApplyFont, st, fs, 'pixel')
	FN.font_objects.normal = real
	eq(ok, false, 'nil with no Text object errors')
	eq(okShared, true, 'a shared font still applies')
	eq(fs:GetFontObject(), st:GetFont('pixel'), 'and is the object set')
	eq(#take_errors(), 0, 'no errors')
end)

test('a shadow of -0 is the look of 0: one object, not two', function()
	local negative = 0 * -1
	eq(tostring(negative), '-0', 'the probe is a negative zero')
	local a = st:GetFont({ font_name = 'Colus', font_size = 15, shadow_offset = { negative, negative } })
	local b = st:GetFont({ font_name = 'Colus', font_size = 15, shadow_offset = { 0, 0 } })
	eq(a, b, '-0, -0 and 0, 0 make one object')
	local x, y = a:GetShadowOffset()
	eq(tostring(x) .. ',' .. tostring(y), '0,0', 'the offset the object holds')
	local _, _, _, sx, sy = st:FontValues({ font_name = 'Colus', shadow_offset = { negative, negative } })
	eq(tostring(sx) .. ',' .. tostring(sy), '0,0', 'FontValues gives 0, 0 too')
	eq(#take_errors(), 0, 'no errors')
end)

test('FollowFont applies at once and again on RefollowFonts, reading the getter then; nil forgets; a region kept twice keeps the last', function()
	local fs = CreateFrame('Frame'):CreateFontString()
	local value = 'pixel'
	st:FollowFont(fs, function() return value end)
	eq(fs:GetFontObject(), st:GetFont('pixel'), 'applied at once')
	value = 'title'
	eq(fs:GetFontObject(), st:GetFont('pixel'), 'not until told')
	st:RefollowFonts()
	eq(fs:GetFontObject(), st:GetFont('title'), 'it reads the getter then')

	st:FollowFont(fs, nil)
	value = 'pixel'
	st:RefollowFonts()
	eq(fs:GetFontObject(), st:GetFont('title'), 'a nil getter forgets the region')

	local other = 'subtitle'
	st:FollowFont(fs, function() return value end)
	st:FollowFont(fs, function() return other end)
	eq(fs:GetFontObject(), st:GetFont('subtitle'), 'the last getter applied')
	value = 'pixel'
	st:RefollowFonts()
	eq(fs:GetFontObject(), st:GetFont('subtitle'), 'and is the one kept')

	-- A getter that errors is reported, and the others still follow.
	local bad = CreateFrame('Frame'):CreateFontString()
	local good = CreateFrame('Frame'):CreateFontString()
	local fail = false
	st:FollowFont(bad, function() if fail then error('boom') end return 'pixel' end)
	st:FollowFont(good, function() return 'heading' end)
	fail = true
	good:SetFontObject(st:GetFont('normal'))
	st:RefollowFonts()
	eq(good:GetFontObject(), st:GetFont('heading'), 'one that errors does not stop the rest')
	eq(#take_errors(), 1, 'and is reported once')
	st:FollowFont(bad, nil)
	st:FollowFont(good, nil)
	st:FollowFont(fs, nil)
end)

test("FontsChanged: the followers first, then every module's OnFontsChanged; one that errors is reported and the rest still run", function()
	local log = {}
	local fs = CreateFrame('Frame'):CreateFontString()
	st:FollowFont(fs, function() log[#log + 1] = 'follower'; return 'pixel' end)
	log = {}
	local A = st:NewModule('FontsProbeA')
	function A:OnFontsChanged() log[#log + 1] = 'A' end
	local B = st:NewModule('FontsProbeB')
	function B:OnFontsChanged() log[#log + 1] = 'B'; error('probe failed') end
	local C = st:NewModule('FontsProbeC')
	function C:OnFontsChanged() log[#log + 1] = 'C' end

	st:FontsChanged()
	eq(log[1], 'follower', 'the followers first')
	local seen = {}
	for i = 2, #log do seen[log[i]] = true end
	check(seen.A and seen.B and seen.C, 'every module ran, the one that errors too: ' .. table.concat(log, ','))
	eq(#take_errors(), 1, 'the error is reported once')

	st:FollowFont(fs, nil)
	A.OnFontsChanged, B.OnFontsChanged, C.OnFontsChanged = nil, nil, nil
end)

test('a profile switch runs FontsChanged after the fonts step, with the new profile in place', function()
	local first = st.config:GetCurrentProfile()
	fonts().pixel.spacing = 9
	FN:UpdateFontConfig('pixel')
	local seen
	local P = st:NewModule('FontsProbeSwitch')
	function P:OnFontsChanged()
		seen = { profile = st.config:GetCurrentProfile(), spacing = st:GetFont('pixel'):GetSpacing(), setting = fonts().pixel.spacing }
	end
	st.config:SetProfile('FontsModelSwitch')
	check(seen ~= nil, 'FontsChanged ran')
	eq(seen.profile, 'FontsModelSwitch', 'with the new profile in place')
	eq(seen.spacing, 4, "and the objects already on its values")
	eq(seen.setting, 4, "and the profile's own setting")
	seen = nil
	st.config:SetProfile(first)
	eq(seen.spacing, 9, 'back again, the first profile'..'s spacing')
	fonts().pixel.spacing = 4
	FN:UpdateFontConfig('pixel')
	P.OnFontsChanged = nil
	eq(#take_errors(), 0, 'no errors')
end)

-- A profile as it was before this change: no marker.
local function Unmarked(face)
	fonts().version = nil
	fonts().title.font_name = face
end

test("Heading's face: Huge title on another face gives it to Heading once, and the profile is marked", function()
	local first = st.config:GetCurrentProfile()
	Unmarked('Bebas Neue')
	FN:UpdateConfig()
	eq(fonts().heading.font_name, 'Bebas Neue', 'Heading took the face')
	eq(fonts().version, 1, 'and the profile is marked')
	eq(select(1, st:GetFont('heading'):GetFont()), path('Bebas Neue'), 'and its object draws it')
	eq(fonts().title.font_name, 'Bebas Neue', "Huge title keeps its own")
	eq(fonts().heading.font_size, 15, 'only the face moved')

	fonts().title.font_name = 'Righteous'
	FN:UpdateConfig()
	eq(fonts().heading.font_name, 'Bebas Neue', 'a second run leaves it')
	eq(FN:ConvertHeadingFace(), false, 'and says it did nothing')

	-- Back to the defaults for the next cases.
	fonts().title.font_name = 'Colus'
	fonts().heading.font_name = 'Colus'
	FN:UpdateConfig()
	eq(first, st.config:GetCurrentProfile())
end)

test("Heading's face: Huge title at Colus, or Heading already set, leaves Heading; marked either way", function()
	Unmarked('Colus')
	eq(FN:ConvertHeadingFace(), true, 'it ran')
	eq(fonts().heading.font_name, 'Colus', 'Colus: Heading stays Colus')
	eq(fonts().version, 1, 'and is marked')

	Unmarked('Bebas Neue')
	fonts().heading.font_name = 'Righteous'
	eq(FN:ConvertHeadingFace(), true, 'it ran')
	eq(fonts().heading.font_name, 'Righteous', 'a Heading face already set stays')
	eq(fonts().version, 1, 'and is marked')

	fonts().title.font_name = 'Colus'
	fonts().heading.font_name = 'Colus'
	FN:UpdateConfig()
end)

test('a profile switched to, copied or reset takes the step on its first load; a reset profile is marked again', function()
	local first = st.config:GetCurrentProfile()

	-- A profile from before this change: a face on Huge title, no marker.
	st.config:SetProfile('FontsModelSource')
	Unmarked('Bebas Neue')
	st.config:SetProfile('FontsModelCopy')
	eq(fonts().version, 1, 'a profile made new is marked when it loads')
	st.config:CopyProfile('FontsModelSource')
	eq(fonts().heading.font_name, 'Bebas Neue', 'a copy takes the step')
	eq(fonts().version, 1, 'and is marked')

	-- Switching to the unmarked source takes it too.
	st.config:SetProfile(first)
	st.config:SetProfile('FontsModelSource')
	eq(fonts().heading.font_name, 'Bebas Neue', 'a switch to an unmarked profile takes the step')
	eq(fonts().version, 1, 'and marks it')

	-- A reset profile is unmarked and marked again.
	st.config:ResetProfile()
	eq(fonts().version, 1, 'a reset profile is marked again')
	eq(fonts().heading.font_name, 'Colus', 'with its defaults')
	eq(fonts().title.font_name, 'Colus')

	st.config:SetProfile(first)
	eq(#take_errors(), 0, 'no errors')
end)

test('AceDB keeps a typeface table under a string default across a profile switch and back, with no keys added', function()
	local first = st.config:GetCurrentProfile()
	st.config.profile.headers.font = { font_name = 'Colus', font_size = 15 }
	st.config:SetProfile('FontsModelAce')
	eq(st.config.profile.headers.font, 'normal', 'the other profile has the default')
	st.config:SetProfile(first)
	local font = st.config.profile.headers.font
	eq(type(font), 'table', 'the table is kept')
	local keys = {}
	for k in pairs(font) do keys[#keys + 1] = k end
	table.sort(keys)
	eq(table.concat(keys, ','), 'font_name,font_size', 'with no keys added')
	st.config.profile.headers.font = 'normal'
end)

test('every face SaftUI registers is preloaded on a font object of its own at load', function()
	eq(#st.SAFTUI_FACES, 15, 'fifteen faces')
	eq(st.SAFTUI_FACES[1], 'envypn', 'in registration order')
	local seen = {}
	for _, name in ipairs(st.SAFTUI_FACES) do
		local object = FN.preloaded[name]
		check(object ~= nil, name .. ' has a font object')
		eq((object:GetFont()), path(name), name .. ' is set on it')
		check(not seen[object], name .. ' has an object of its own')
		seen[object] = true
		check(object:GetName():match('^SaftUI_Preload%d+Font$'), 'named for the preload: ' .. tostring(object:GetName()))
	end
end)

test("a table's missing fields read Text's default and an unknown value reads the profile's Text", function()
	fonts().normal.font_size = 20
	eq(st:FontFields({ font_name = 'Colus' }).font_size, 16, "a typeface's missing size is Text's default, not the profile's Text")
	eq(select(2, st:FontValues(nil)), 20, "nil reads the profile's Text")
	eq(select(2, st:FontValues('nope')), 20, "an unknown key too")
	eq(select(2, st:FontValues({ font_name = 'Colus' })), 16, 'a typeface table again')
	fonts().normal.font_size = 16
end)

test('UpdateFontConfig for a key that is no shared font makes no object', function()
	FN:UpdateFontConfig('pixel_huge')
	FN:UpdateFontConfig('nope')
	eq(FN.font_objects.pixel_huge, nil, 'no object for a dropped key')
	eq(FN.font_objects.nope, nil, 'or an unknown one')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Heading step moves the face only, not the outline', function()
	fonts().title.font_outline = 'NONE'
	Unmarked('Bebas Neue')
	FN:ConvertHeadingFace()
	eq(fonts().heading.font_name, 'Bebas Neue', 'the face moved')
	eq(fonts().heading.font_outline, 'OUTLINE', "Huge title's outline did not")
	fonts().title.font_outline = 'OUTLINE'
	fonts().title.font_name = 'Colus'
	fonts().heading.font_name = 'Colus'
	FN:UpdateConfig()
end)

test('the login path takes the Heading step: FN:OnEnable converts an unmarked profile and marks it', function()
	Unmarked('Bebas Neue')
	FN:OnEnable()
	eq(fonts().heading.font_name, 'Bebas Neue', 'Heading took the face')
	eq(fonts().version, 1, 'and the profile is marked')
	eq(st:GetFont('heading'):GetFont(), path('Bebas Neue'), 'and its object draws it')
	fonts().title.font_name = 'Colus'
	fonts().heading.font_name = 'Colus'
	FN:UpdateConfig()
end)

test('an error in the Heading step at login is reported and the objects are still set', function()
	local real = FN.ConvertHeadingFace
	FN.ConvertHeadingFace = function() error('step failed') end
	fonts().pixel.spacing = 9
	FN:OnEnable()
	FN.ConvertHeadingFace = real
	eq(st:GetFont('pixel'):GetSpacing(), 9, 'UpdateFontConfig still ran')
	eq(#take_errors(), 1, 'and the error was reported')
	fonts().pixel.spacing = 4
	FN:UpdateFontConfig('pixel')
end)

test('an error in the Heading step on a profile change is reported and the objects are still set', function()
	local real = FN.ConvertHeadingFace
	FN.ConvertHeadingFace = function() error('step failed') end
	fonts().pixel.spacing = 9
	FN:UpdateConfig()
	FN.ConvertHeadingFace = real
	eq(st:GetFont('pixel'):GetSpacing(), 9, 'UpdateFontConfig still ran')
	eq(#take_errors(), 1, 'and the error was reported')
	fonts().pixel.spacing = 4
	FN:UpdateFontConfig('pixel')
end)

test('a face registered after a typeface was asked for is picked up the next time the look is asked for', function()
	local look = { font_name = 'LateFace', font_size = 14 }
	local before = st:GetFont(look)
	eq(before:GetFont(), st.LSM:Fetch('font', st.LSM:GetDefault('font')), 'unlisted: the default face')
	st.LSM:Register('font', 'LateFace', [[Interface\AddOns\Late\late.ttf]])
	local after = st:GetFont(look)
	check(after ~= before, 'another object now')
	eq(after:GetFont(), [[Interface\AddOns\Late\late.ttf]], 'in the new face')
	eq(st:GetFont(look), after, 'and that one is kept')
end)

test('FollowFont: a getter that errors on its first apply is not kept; UnfollowFont forgets', function()
	local fs = CreateFrame('Frame'):CreateFontString()
	check(not pcall(st.FollowFont, st, fs, function() error('first apply') end), 'the error comes out of FollowFont')
	st:RefollowFonts()
	eq(#take_errors(), 0, 'and the region is not followed')
	local value = 'pixel'
	st:FollowFont(fs, function() return value end)
	st:UnfollowFont(fs)
	value = 'title'
	st:RefollowFonts()
	eq(fs:GetFontObject(), st:GetFont('pixel'), 'a forgotten region stays as it was')
end)

test('a followed region nothing else holds is let go', function()
	local calls = 0
	do
		-- A plain table, not a stub widget (the stubs keep every widget they make).
		local region = { SetFontObject = function() end }
		st:FollowFont(region, function() calls = calls + 1; return 'pixel' end)
	end
	calls = 0
	collectgarbage()
	collectgarbage()
	st:RefollowFonts()
	eq(calls, 0, 'a region nothing else holds is not applied again')
end)

-- Memory the reader helpers allocate: the shared-key path and a typeface already
-- seen allocate nothing (the readers call them on hot paths: tooltips, unit
-- frame updates).
local function Allocated(fn)
	collectgarbage()
	collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, 2000 do fn() end
	local after = collectgarbage('count')
	collectgarbage('restart')
	return after - before
end

test('the value helpers allocate nothing on a shared key, or on a typeface already seen', function()
	local face = { font_name = 'Colus', font_size = 15 }
	st:GetFont(face)
	st:GetFont('pixel_huge')
	local fs = CreateFrame('Frame'):CreateFontString()
	local cases = {
		{ 'st:GetFont(key)', function() return st:GetFont('pixel') end },
		{ 'st:FontObject(key)', function() return st:FontObject('pixel') end },
		{ 'st:FontValues(key)', function() return st:FontValues('pixel') end },
		{ 'st:FontValues(nil)', function() return st:FontValues(nil) end },
		{ 'st:GetFont(table)', function() return st:GetFont(face) end },
		{ 'st:FontValues(table)', function() return st:FontValues(face) end },
		{ 'st:GetFont(dropped key)', function() return st:GetFont('pixel_huge') end },
		{ 'st:FontValues(dropped key)', function() return st:FontValues('pixel_huge') end },
		{ 'st:FontLabel(key)', function() return st:FontLabel('pixel') end },
		{ 'st:IsSharedFont', function() return st:IsSharedFont('pixel') end },
		-- The hot path of every reader: a text put on a font (a unit frame's
		-- update, a tooltip line) allocates nothing either.
		{ 'st:ApplyFont(key)', function() return st:ApplyFont(fs, 'pixel') end },
		{ 'st:ApplyFont(nil)', function() return st:ApplyFont(fs, nil) end },
		{ 'st:ApplyFont(table)', function() return st:ApplyFont(fs, face) end },
		{ 'st:ApplyFont(dropped key)', function() return st:ApplyFont(fs, 'pixel_huge') end },
	}
	for _, case in ipairs(cases) do
		local kb = Allocated(case[2])
		check(kb < 4, case[1] .. ' allocates nothing: ' .. kb .. ' KB over 2000 calls')
	end
end)

test('a Size drag makes one typeface object per whole size, and the same one again when it comes back', function()
	local made = {}
	for size = 20, 60 do made[size] = st:GetFont({ font_name = 'Colus', font_size = size }) end
	for size = 60, 20, -1 do eq(st:GetFont({ font_name = 'Colus', font_size = size }), made[size], 'size ' .. size .. ' again') end
	eq(st:GetFont({ font_name = 'Colus', font_size = 30.7 }), made[30], 'a size between is the whole size below')
end)

test('a listed face whose file fails to load: the typeface object falls back to Text\'s face, keeping the size and outline', function()
	local real = FN.SetObject
	local calls = 0
	FN.SetObject = function(self, object, fields)
		calls = calls + 1
		if fields.font_name == 'Broken face' then error('Couldn\'t load the font file') end
		return real(self, object, fields)
	end
	local ok, object = pcall(st.GetFont, st, { font_name = 'Broken face', font_size = 21, font_outline = 'THICKOUTLINE' })
	FN.SetObject = real
	check(ok, 'nothing errors')
	check(object ~= nil, 'an object is made')
	local p, size, flags = object:GetFont()
	eq(p, path(st.defaults.fonts.normal.font_name), "in Text's face")
	eq(size, 21, 'at the size asked')
	eq(flags, 'THICKOUTLINE', 'with the outline asked')
end)

for _, mode in ipairs({ true, 'error', 'silent' }) do
	test('a face the game refuses (SetFont ' .. (mode == 'error' and 'raises' or mode == 'silent' and 'says nothing' or 'returns false') .. '): every reader and the typeface object get Text\'s face, tested once per file', function()
		local face_name = 'Refused face ' .. tostring(mode)
		st.LSM:Register('font', face_name, 'Interface\\AddOns\\SaftUI-Core\\Media\\Fonts\\refused' .. tostring(mode) .. '.ttf')
		local colus = path(face_name)
		local text = path('AgencyFB Bold')
		stub.refused_fonts[colus] = mode
		local look = { font_name = face_name, font_size = 19, font_outline = 'OUTLINE' }
		local p, size, flags = st:FontValues(look)
		eq(p, text, "st:FontValues gives Text's face")
		eq(size, 19, 'at the size asked')
		eq(flags, 'OUTLINE', 'and the outline asked')
		local object = st:GetFont(look)
		local face, osize = object:GetFont()
		eq(face, text, "the typeface object is in Text's face")
		eq(osize, 19, 'at the size asked')
		-- Cached by path: the answer is not asked again once the game would take
		-- the file (a file does not appear during a session).
		stub.refused_fonts[colus] = nil
		eq((st:FontValues(look)), text, 'the answer is kept per path')
		-- A face it takes is unaffected, and builds nothing once known.
		eq((st:FontValues({ font_name = 'Homespun' })), path('Homespun'), 'another face is its own')
		collectgarbage(); collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, 2000 do st:FontValues(look); st:FontValues('normal') end
		local grown = collectgarbage('count') - before
		collectgarbage('restart')
		eq(grown, 0, 'no garbage once a face is known')
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('a refusal is not kept past st:FontsChanged: a face refused once and accepted after it draws in its own face, with one probe between', function()
	st.LSM:Register('font', 'Late face', 'Interface\\AddOns\\SaftUI-Core\\Media\\Fonts\\late.ttf')
	local late, text = path('Late face'), path('AgencyFB Bold')
	local asked, state = 0, { [late] = true }
	local real = stub.refused_fonts
	stub.refused_fonts = setmetatable({}, { __index = function(_, k) if k == late then asked = asked + 1 end return state[k] end })
	local look = { font_name = 'Late face', font_size = 14 }
	eq((st:FontValues(look)), text, 'refused: Text')
	local object = st:GetFont(look)
	eq((object:GetFont()), text, 'and the typeface object')
	for _ = 1, 100 do st:FontValues(look) end
	eq(asked, 1, 'one probe between two st:FontsChanged, however often it is asked')
	-- The game takes the file now.
	state[late] = nil
	eq((st:FontValues(look)), text, 'still Text until something changes')
	st:FontsChanged()
	eq((st:FontValues(look)), late, 'after st:FontsChanged it is asked again and draws in its own face')
	eq((st:GetFont(look):GetFont()), late, 'a typeface object made for it takes the face too')
	asked = 0
	state[late] = true -- a positive answer is kept
	st:FontsChanged()
	eq((st:FontValues(look)), late, 'a face known to load is not asked again')
	eq(asked, 0, 'no probe')
	stub.refused_fonts = real
	eq(#take_errors(), 0, 'no errors')
end)

test("SaftUI's own preloaded faces count as loading with no probe", function()
	local colus = path('Colus')
	local asked, real = 0, stub.refused_fonts
	stub.refused_fonts = setmetatable({}, { __index = function(_, k) if k == colus then asked = asked + 1 end return k == colus or nil end })
	eq((st:FontValues({ font_name = 'Colus' })), colus, 'a preloaded face, though the game would refuse it')
	eq(asked, 0, 'no probe')
	stub.refused_fonts = real
end)

------------------------------------------------------------------ what a probe is judged against, and the fallback face

-- Text on face `name` (registered, SaftUI does not preload it), the objects set.
local function text_on(name)
	fonts().normal.font_name = name
	FN:UpdateFontConfig('normal')
	st:FontsChanged()
end
local function text_back()
	fonts().normal.font_name = nil
	FN:UpdateFontConfig('normal')
	st:FontsChanged()
end

test("Text on a face SaftUI does not preload: a typeface in that same face draws in it (the probe is judged against a SaftUI face, not Text's)", function()
	st.LSM:Register('font', 'Friz probe', 'Interface\\AddOns\\SomeAddon\\friz.ttf')
	text_on('Friz probe')
	local look = { font_name = 'Friz probe', font_size = 13 }
	eq((st:FontValues(look)), path('Friz probe'), 'a value reader draws it')
	eq((st:GetFont(look):GetFont()), path('Friz probe'), 'and so does the typeface object')
	eq((st:GetFont('normal'):GetFont()), path('Friz probe'), 'Text itself is in it')
	text_back()
	eq(#take_errors(), 0, 'no errors')
end)

test("Text's own face raising on SetFont: no reader raises, a typeface in another face draws, and what is refused draws in SaftUI's default Text face", function()
	st.LSM:Register('font', 'Raising text', 'Interface\\AddOns\\SomeAddon\\raising.ttf')
	st.LSM:Register('font', 'Other probe', 'Interface\\AddOns\\SomeAddon\\other.ttf')
	stub.refused_fonts[path('Raising text')] = 'error'
	local ok, err = pcall(text_on, 'Raising text')
	check(ok, 'putting Text on it raises nothing: ' .. tostring(err))
	local ok2, p = pcall(st.FontValues, st, { font_name = 'Other probe', font_size = 12 })
	check(ok2, 'a reader does not raise: ' .. tostring(p))
	eq(p, path('Other probe'), 'a typeface in another face draws in it')
	eq((st:FontValues('normal')), path(st.defaults.fonts.normal.font_name), "Text on a refused face draws in SaftUI's default Text face")
	eq((st:GetFont('normal'):GetFont()), path(st.defaults.fonts.normal.font_name), 'its object too')
	eq((st:FontValues({ font_name = 'Raising text', font_size = 9 })), path(st.defaults.fonts.normal.font_name), 'a typeface in the refused face the same')
	stub.refused_fonts[path('Raising text')] = nil
	text_back()
	eq(#take_errors(), 0, 'no errors')
end)

test("both fallbacks draw in the same face: the profile's Text when it loads", function()
	st.LSM:Register('font', 'Alt text', 'Interface\\AddOns\\SomeAddon\\alt.ttf')
	st.LSM:Register('font', 'Refused same', 'Interface\\AddOns\\SomeAddon\\same.ttf')
	text_on('Alt text')
	stub.refused_fonts[path('Refused same')] = true
	local look = { font_name = 'Refused same', font_size = 15 }
	eq((st:FontValues(look)), path('Alt text'), "a value reader: the profile's Text")
	eq((st:GetFont(look):GetFont()), path('Alt text'), 'the typeface object: the same face')
	stub.refused_fonts[path('Refused same')] = nil
	text_back()
	eq(#take_errors(), 0, 'no errors')
end)

test('a refused face is retried by st:RetryFonts, which st:FontsChanged runs', function()
	st.LSM:Register('font', 'Retry face', 'Interface\\AddOns\\SomeAddon\\retry.ttf')
	stub.refused_fonts[path('Retry face')] = true
	local look = { font_name = 'Retry face', font_size = 12 }
	eq((st:FontValues(look)), path(st.defaults.fonts.normal.font_name), 'refused: Text')
	stub.refused_fonts[path('Retry face')] = nil
	eq((st:FontValues(look)), path(st.defaults.fonts.normal.font_name), 'the refusal is kept')
	st:RetryFonts()
	eq((st:FontValues(look)), path('Retry face'), 'asked again after st:RetryFonts')
end)

test('a shared font on a face the game refuses draws in Text\'s face, whether SetFont says false, raises or says nothing; the other shared fonts are still set', function()
	for _, mode in ipairs({ true, 'error', 'silent' }) do
		local name = 'Refused shared ' .. tostring(mode)
		st.LSM:Register('font', name, 'Interface\\AddOns\\SomeAddon\\shared' .. tostring(mode) .. '.ttf')
		stub.refused_fonts[path(name)] = mode
		fonts().pixel.font_name = name
		fonts().heading.font_name = name
		local ok, err = pcall(FN.UpdateFontConfig, FN)
		check(ok, tostring(mode) .. ': nothing raises: ' .. tostring(err))
		for _, key in ipairs({ 'pixel', 'heading' }) do
			eq((st:GetFont(key):GetFont()), path(st.defaults.fonts.normal.font_name), tostring(mode) .. ': ' .. key .. " in Text's face")
		end
		check(st:GetFont('subtitle'):GetFont() ~= nil, tostring(mode) .. ': a later shared font is still set')
		stub.refused_fonts[path(name)] = nil
		fonts().pixel.font_name, fonts().heading.font_name = nil, nil
		FN:UpdateFontConfig()
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a typeface look made for the first time sets its face once, at its size; a font object already in use is bounced (M10)', function()
	-- The bounce (size + 1 and back) makes texts already on an object measure
	-- again; a new object has none. The load probe (st:FontLoads) runs on its own
	-- object, and once per file.
	local sizes, made = {}, {}
	local real = CreateFont
	CreateFont = function(name)
		local object = real(name)
		made[#made + 1] = object
		local setFont = object.SetFont
		object.SetFont = function(self, file, size, flags)
			sizes[#sizes + 1] = name .. ':' .. size
			return setFont(self, file, size, flags)
		end
		return object
	end
	local look = { font_name = 'Colus', font_size = 31, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
	st:GetFont(look)
	CreateFont = real
	local mine = {}
	for _, entry in ipairs(sizes) do
		if entry:find('^SaftUI_Typeface') then mine[#mine + 1] = entry end
	end
	eq(#mine, 1, 'one SetFont for the new object: ' .. table.concat(mine, ' '))
	-- A shared font's object is set again in use, so it bounces as it did.
	local bounced = {}
	local object = st:GetFont('normal')
	local setFont = object.SetFont
	object.SetFont = function(self, file, size, flags)
		bounced[#bounced + 1] = size
		return setFont(self, file, size, flags)
	end
	FN:UpdateFontConfig('normal')
	object.SetFont = setFont
	eq(#bounced, 3, 'size, size + 1, size')
end)
