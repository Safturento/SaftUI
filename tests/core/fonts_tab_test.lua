-- The Fonts tab of Global settings (SaftUI-Core/Media/fonts.lua): each font's
-- Shadow offset X, Shadow offset Y and Line spacing, which its font object
-- takes at once, and the Kinds of text section, which says which font window
-- titles, button text and check box labels use. Every row reads and writes the
-- profile at call time, so a profile switch reaches the new profile.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua: the
-- Fonts module, enabled, so the fonts have their font objects), the options
-- model the window reads rows with (optionsmodel.lua), and panels.lua's
-- header on a panel from st:CreatePanel.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local OM = st.OptionsModel

local KINDS_NOTE = 'Window titles change at once. The rest is read when SaftUI builds its frames: reload (Reload UI, bottom right) to see a change everywhere.'

local FN = st:GetModule('Fonts')

local function Tab() return st.Config:GetOptionsTable().Fonts.args.fonts end

local function ByOrder(t)
	local out = {}
	for key, v in pairs(t) do out[#out + 1] = { key = key, v = v } end
	table.sort(out, function(a, b) return a.v.order < b.v.order end)
	return out
end

-- The model's row for key in a section of the Fonts tab (a font's key, or
-- 'kinds' for Kinds of text), and the tree it's in.
local function Row(section, key)
	local root = st.Config:GetOptionsTable()
	for _, s in ipairs(OM.BuildView(root, 'Fonts', { tab = 'fonts' }).sections) do
		for _, row in ipairs(s.rows) do
			if row.key == key and row.path[#row.path - 1] == section then return root, row end
		end
	end
	error('no row ' .. section .. '.' .. key)
end

local function Get(section, key) local root, row = Row(section, key); return OM.Get(root, row) end
local function Set(section, key, value) local root, row = Row(section, key); return OM.Set(root, row, value) end

local function Shadow(fontKey)
	local x, y = st:GetFont(fontKey):GetShadowOffset()
	return x .. ',' .. y
end

local panel = st:CreatePanel('Fonts test', 200, 100)

test("every font has Shadow offset X, Shadow offset Y and Line spacing after its face, size and outline", function()
	local count = 0
	for i, entry in ipairs(FN.FONTS) do
		local fontKey = entry.key
		count = count + 1
		local group = Tab().args[fontKey]
		eq(group.name, entry.name, fontKey .. ' is named from code')
		eq(group.order, i + 1, fontKey .. ' is in FN.FONTS order, after Kinds of text')
		check(group ~= nil, fontKey .. ' has a section')
		local keys = {}
		for i, r in ipairs(ByOrder(group.args)) do keys[i] = r.key end
		eq(table.concat(keys, ','), 'font_name,font_size,font_outline,shadow_x,shadow_y,spacing', fontKey)
		local args = group.args
		eq(args.shadow_x.name .. ',' .. args.shadow_y.name .. ',' .. args.spacing.name,
			'Shadow offset X,Shadow offset Y,Line spacing', fontKey)
		for _, key in ipairs({ 'shadow_x', 'shadow_y', 'spacing' }) do
			local option = args[key]
			eq(option.type, 'range', fontKey .. ' ' .. key)
			check(type(option.desc) == 'string' and #option.desc > 30, fontKey .. ' ' .. key .. ' has a desc')
			eq(option.width, nil, key .. ' has no Ace width')
			-- A slider can't be small in SaftUI's window; it takes a half.
			eq(option.size, nil, key .. ' takes the normal size')
		end
		eq(args.shadow_x.min .. '/' .. args.shadow_x.max .. '/' .. args.shadow_x.step, '-5/5/1', 'shadow X range')
		eq(args.shadow_y.min .. '/' .. args.shadow_y.max .. '/' .. args.shadow_y.step, '-5/5/1', 'shadow Y range')
		eq(args.spacing.min .. '/' .. args.spacing.max .. '/' .. args.spacing.step, '0/20/1', 'spacing range')
	end
	eq(count, 6, 'the six shared fonts')
end)

test("Shadow offset X and Y read and write the font's shadow_offset, and its font object takes them at once", function()
	eq(Get('pixel', 'shadow_x'), 0, 'X from the profile')
	eq(Get('pixel', 'shadow_y'), 0, 'Y from the profile')
	eq(Shadow('pixel'), '0,0')

	Set('pixel', 'shadow_x', 2)
	eq(st.config.profile.fonts.pixel.shadow_offset[1], 2, 'X is the first number')
	eq(st.config.profile.fonts.pixel.shadow_offset[2], 0, 'Y is left alone')
	eq(Shadow('pixel'), '2,0', 'the font object, at once')

	Set('pixel', 'shadow_y', -1)
	eq(st.config.profile.fonts.pixel.shadow_offset[2], -1, 'Y is the second number')
	eq(Shadow('pixel'), '2,-1')
	eq(Get('pixel', 'shadow_x') .. ',' .. Get('pixel', 'shadow_y'), '2,-1', 'both read back')

	eq(Shadow('pixel_med'), '0,0', "another font's object is untouched")
	eq(st.config.profile.fonts.pixel_med.shadow_offset[1], 0, "and so is its profile")
	eq(st.defaults.fonts.pixel.shadow_offset[1], 0, 'the defaults are untouched')

	Set('pixel', 'shadow_x', 0)
	Set('pixel', 'shadow_y', 0)
end)

-- In game a font's shadow or line spacing changing doesn't measure the texts
-- using it again: a shadow pushed right cut their last letters off until a
-- reload. A size change does, so after setting them the size goes up by one and
-- straight back (/suishadowlive in game, 2026-11-10: that row kept every word).
test('a shadow or line spacing change nudges the font size up and back, so its texts are measured again', function()
	for _, key in ipairs({ 'shadow_x', 'shadow_y', 'spacing' }) do
		local font = st:GetFont('pixel')
		local size = st.config.profile.fonts.pixel.font_size
		local sizes = {}
		local real = font.SetFont
		font.SetFont = function(self, path, s, flags)
			sizes[#sizes + 1] = s
			return real(self, path, s, flags)
		end
		Set('pixel', key, 1)
		font.SetFont = real
		eq(sizes[#sizes - 1], size + 1, key .. ': up by one')
		eq(sizes[#sizes], size, key .. ': and back')
		eq(select(2, font:GetFont()), size, key .. ': the size ends where the profile has it')
		Set('pixel', key, 0)
	end
end)

test("every font's shadow is opaque black, so a shadow offset shows", function()
	for _, entry in ipairs(FN.FONTS) do
		local fontKey = entry.key
		local r, g, b, a = st:GetFont(fontKey):GetShadowColor()
		eq(table.concat({ r, g, b, a }, ','), '0,0,0,1', fontKey)
	end
end)

test("Line spacing reads and writes the font's spacing, and its font object takes it at once", function()
	eq(Get('normal', 'spacing'), 4, 'the default')
	eq(st:GetFont('normal'):GetSpacing(), 4)
	Set('normal', 'spacing', 7)
	eq(st.config.profile.fonts.normal.spacing, 7, 'the profile')
	eq(st:GetFont('normal'):GetSpacing(), 7, 'the font object, at once')
	Set('normal', 'spacing', 4)
end)

test('Kinds of text comes first: a font select each for window titles, button text and check box labels', function()
	local section = Tab().args.kinds
	eq(section.type, 'group')
	eq(section.inline, true, 'a section, not a tab')
	eq(section.name, 'Kinds of text')
	eq(section.desc, KINDS_NOTE, 'its note')
	local sections = OM.BuildView(st.Config:GetOptionsTable(), 'Fonts', { tab = 'fonts' }).sections
	eq(sections[1].title, 'Kinds of text', 'first on the tab')

	local rows = {}
	for i, r in ipairs(ByOrder(section.args)) do rows[i] = r.key .. '=' .. r.v.name end
	eq(table.concat(rows, ','), 'window_titles=Window titles,button_text=Button text,checkbox_labels=Check box labels')
	for key, option in pairs(section.args) do
		eq(option.type, 'select', key)
		check(type(option.desc) == 'string' and #option.desc > 30, key .. ' has a desc')
		eq(option.width, nil, key .. ' has no Ace width')
		eq(option.size, nil, key .. ' takes the normal size')
		local values = type(option.values) == 'function' and option.values() or option.values
		local n = 0
		for fontKey, name in pairs(values) do
			n = n + 1
			eq(name, FN:Font(fontKey).name, key .. ' lists ' .. fontKey .. ' by its name, from code')
		end
		eq(n, 6, key .. ' lists every shared font')
		local sorting = {}
		for i, entry in ipairs(FN.FONTS) do sorting[i] = entry.key end
		eq(table.concat(option.sorting, ','), table.concat(sorting, ','), key .. ' lists them in FN.FONTS order')
	end
	check(section.args.window_titles.desc:find("gold and free%-slot"), "Window titles' tooltip names the bags' gold and free-slot text")
	check(section.args.button_text.desc:find('totem bar', 1, true), "Button text's tooltip names the totem bar")
	check(section.args.checkbox_labels.desc:find('check box', 1, true), "Check box labels' tooltip names check boxes")
end)

test('each kind of text reads and writes its profile font; window titles change at once', function()
	eq(Get('kinds', 'window_titles'), 'normal', 'headers.font')
	eq(Get('kinds', 'button_text'), 'pixel', 'buttons.font')
	eq(Get('kinds', 'checkbox_labels'), 'normal', 'panels.font')
	check(panel.title:GetFontObject() == st:GetFont('normal'), 'a window title in the normal font')

	Set('kinds', 'window_titles', 'pixel')
	eq(st.config.profile.headers.font, 'pixel', 'the profile')
	check(panel.title:GetFontObject() == st:GetFont('pixel'), 'the window title, at once')

	Set('kinds', 'button_text', 'pixel_med')
	eq(st.config.profile.buttons.font, 'pixel_med')
	Set('kinds', 'checkbox_labels', 'subtitle')
	eq(st.config.profile.panels.font, 'subtitle')
	eq(Get('kinds', 'button_text') .. ',' .. Get('kinds', 'checkbox_labels'), 'pixel_med,subtitle', 'both read back')

	Set('kinds', 'window_titles', 'normal')
	Set('kinds', 'button_text', 'pixel')
	Set('kinds', 'checkbox_labels', 'normal')
	check(panel.title:GetFontObject() == st:GetFont('normal'), 'and back')
end)

test('after a profile switch, the rows reach the new profile, and the font objects and titles take its values', function()
	local first = st.config:GetCurrentProfile()
	Set('pixel', 'shadow_x', 2)
	Set('pixel', 'shadow_y', -1)
	Set('pixel', 'spacing', 7)
	Set('kinds', 'window_titles', 'pixel')
	Set('kinds', 'button_text', 'normal')

	st.config:SetProfile('FontsTestTwo')
	eq(Get('pixel', 'shadow_x') .. ',' .. Get('pixel', 'shadow_y'), '0,0', "the new profile's shadow")
	eq(Get('pixel', 'spacing'), 4, "the new profile's spacing")
	eq(Get('kinds', 'window_titles') .. ',' .. Get('kinds', 'button_text'), 'normal,pixel', "the new profile's fonts")
	eq(Shadow('pixel'), '0,0', 'the font object takes the new profile')
	eq(st:GetFont('pixel'):GetSpacing(), 4)
	check(panel.title:GetFontObject() == st:GetFont('normal'), 'so does the window title')

	Set('pixel', 'shadow_x', 3)
	eq(st.config.profile.fonts.pixel.shadow_offset[1], 3, 'a set reaches the new profile')
	eq(Shadow('pixel'), '3,0')

	st.config:SetProfile(first)
	eq(Get('pixel', 'shadow_x') .. ',' .. Get('pixel', 'shadow_y'), '2,-1', "the first profile's values are as they were")
	eq(Get('pixel', 'spacing'), 7)
	eq(Shadow('pixel'), '2,-1', 'and the font object takes them again')
	eq(st:GetFont('pixel'):GetSpacing(), 7)
	check(panel.title:GetFontObject() == st:GetFont('pixel'), 'and the window title')

	Set('pixel', 'shadow_x', 0)
	Set('pixel', 'shadow_y', 0)
	Set('pixel', 'spacing', 4)
	Set('kinds', 'window_titles', 'normal')
	Set('kinds', 'button_text', 'pixel')
	eq(#take_errors(), 0, 'no errors')
end)

test("the outline values name None as None, and spell Monochrome Thick Outline", function()
	local values = Tab().args.pixel.args.font_outline.values
	eq(values.NONE, 'None')
	eq(values.MONOCHROMETHICKOUTLINE, 'Monochrome Thick Outline')
end)

test("a font saved with the outline NONE reaches SetFont with no flags", function()
	local font = st:GetFont('pixel')
	local saved = st.config.profile.fonts.pixel.font_outline
	local flags = {}
	local real = font.SetFont
	font.SetFont = function(self, path, s, f)
		flags[#flags + 1] = f
		return real(self, path, s, f)
	end
	st.config.profile.fonts.pixel.font_outline = 'NONE'
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	font.SetFont = real
	st.config.profile.fonts.pixel.font_outline = saved
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	check(#flags > 0, 'SetFont ran')
	for i, f in ipairs(flags) do eq(f, '', 'SetFont call ' .. i) end
end)

-- A module that counts what st:FontsChanged tells it.
local changes = 0
local Probe = st:NewModule('FontsTabProbe')
function Probe:OnFontsChanged() changes = changes + 1 end

test('every set on the Fonts tab runs st:FontsChanged once: a shared font row, Shadow offset, each Kinds of text row', function()
	local cases = {
		{ 'pixel', 'font_size', 11, 10 },
		{ 'pixel', 'font_name', 'Colus', 'Homespun' },
		{ 'pixel', 'font_outline', 'NONE', 'MONOCHROMEOUTLINE' },
		{ 'pixel', 'shadow_x', 1, 0 },
		{ 'pixel', 'shadow_y', 1, 0 },
		{ 'pixel', 'spacing', 5, 4 },
		{ 'kinds', 'window_titles', 'pixel', 'normal' },
		{ 'kinds', 'button_text', 'normal', 'pixel' },
		{ 'kinds', 'checkbox_labels', 'pixel', 'normal' },
	}
	for _, case in ipairs(cases) do
		local section, key, value, back = unpack(case)
		changes = 0
		Set(section, key, value)
		eq(changes, 1, section .. '.' .. key .. ' ran FontsChanged once')
		changes = 0
		Set(section, key, back)
		eq(changes, 1, section .. '.' .. key .. ' back: once')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile with a saved fonts.pixel_huge and a saved name: no section for it, names from code, nothing errors', function()
	local fonts = st.config.profile.fonts
	fonts.pixel_huge = { font_size = 40 }
	fonts.normal.name = 'Mine'
	local tab = Tab()
	check(tab.args.pixel_huge == nil, 'no section for the dropped font')
	eq(tab.args.normal.name, 'Text', 'the section is named from code, not from the saved name')
	local count = 0
	for key, v in pairs(tab.args) do
		if key ~= 'kinds' then count = count + 1 end
	end
	eq(count, 6, 'six sections')
	for key, option in pairs(tab.args.kinds.args) do
		local values = type(option.values) == 'function' and option.values() or option.values
		eq(values.pixel_huge, nil, key .. " does not list the dropped font")
	end
	FN:UpdateFontConfig()
	eq(FN.font_objects.pixel_huge, nil, 'and no object')
	eq(#take_errors(), 0, 'no errors')
	fonts.pixel_huge = nil
	fonts.normal.name = nil
end)
