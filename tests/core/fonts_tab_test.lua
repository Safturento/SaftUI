-- The Fonts tab of Global settings (SaftUI-Core/Media/fonts.lua): the line at
-- its top, a section per shared font in FN.FONTS order with its job as the
-- note, each font's Typeface, Size, Outline, Shadow offset X and Y and Line
-- spacing (which its font object takes at once) with a reset by each row, and
-- the Kinds of text section last, which says which font window titles, button
-- text and check box labels use. Also /sui's own titles, which take Heading's
-- face and outline (SaftUI-Core/Config/optionsbody.lua's FONTS). Every row
-- reads and writes the profile at call time, so a profile switch reaches the
-- new profile.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua: the
-- Fonts module, enabled, so the fonts have their font objects), the options
-- model the window reads rows with (optionsmodel.lua), the widget files and the
-- body (optionsbody.lua, for /sui's own font objects), and panels.lua's
-- header on a panel from st:CreatePanel.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local OM, OB, W = st.OptionsModel, st.OptionsBody, st.OptionsWidgets

local INTRO = "SaftUI's shared fonts. Font rows throughout SaftUI choose from these, and a change here changes every text that uses the font, at once. A Font row can take a typeface of its own instead, with its size and outline in its dots."
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

local function path(name) return st.LSM:Fetch('font', name) end

local function Sections() return OM.BuildView(st.Config:GetOptionsTable(), 'Fonts', { tab = 'fonts' }).sections end

-- A module that counts what st:FontsChanged tells it.
local changes = 0
local Probe = st:NewModule('FontsTabProbe')
local sawSize -- Small text's object size as the last FontsChanged saw it
function Probe:OnFontsChanged()
	changes = changes + 1
	sawSize = select(2, st:GetFont('pixel'):GetFont())
end

local panel = st:CreatePanel('Fonts test', 200, 100)

test('the tab: the line at the top, the six fonts in FN.FONTS order with their jobs as notes, Kinds of text last', function()
	local sections = Sections()
	local titles = {}
	for i, section in ipairs(sections) do titles[i] = section.title or '' end
	eq(table.concat(titles, '|'), '|Text|Small text|Large numbers|Heading|Huge title|Subtitle|Kinds of text')
	local intro = sections[1].rows
	eq(#intro, 1, 'the line is one row')
	eq(intro[1].type, 'description')
	eq(intro[1].name, INTRO, "the spec's line")
	for i, entry in ipairs(FN.FONTS) do
		eq(sections[i + 1].note, entry.job .. '.', entry.key .. "'s job is its note, as a sentence")
	end
	eq(sections[8].note, KINDS_NOTE, "Kinds of text keeps its note until a later task")
	local tab = Tab()
	eq(tab.args.intro.order, 0, 'the line is first')
	eq(tab.args.kinds.order, #FN.FONTS + 1, 'Kinds of text is last')
end)

test("each font's rows: Typeface, Size, Outline, Shadow offset X, Shadow offset Y, Line spacing; no Name", function()
	local count = 0
	for i, entry in ipairs(FN.FONTS) do
		local fontKey = entry.key
		count = count + 1
		local group = Tab().args[fontKey]
		check(group ~= nil, fontKey .. ' has a section')
		eq(group.name, entry.name, fontKey .. ' is named from code')
		eq(group.order, i, fontKey .. ' is in FN.FONTS order')
		eq(group.inline, true, fontKey .. ' is a section, not a tab')
		eq(group.desc, entry.job .. '.', fontKey .. "'s job is its note, as a sentence")
		local keys, names = {}, {}
		for j, r in ipairs(ByOrder(group.args)) do keys[j] = r.key; names[j] = r.v.name end
		eq(table.concat(keys, ','), 'font_name,font_size,font_outline,shadow_x,shadow_y,spacing', fontKey)
		eq(table.concat(names, ','), 'Typeface,Size,Outline,Shadow offset X,Shadow offset Y,Line spacing', fontKey)
		local args = group.args
		eq(args.font_name.type, 'select')
		eq(args.font_name.dialogControl, 'LSM30_Font', 'every face in its own face')
		eq(args.font_name.desc, 'The typeface of every text that uses this font.')
		eq(args.font_size.type, 'range')
		eq(args.font_outline.type, 'select')
		for _, key in ipairs({ 'font_size', 'font_outline', 'shadow_x', 'shadow_y', 'spacing' }) do
			local option = args[key]
			check(type(option.desc) == 'string' and #option.desc > 30, fontKey .. ' ' .. key .. ' has a desc')
			check(option.desc:find('every text that uses this font', 1, true), key .. ": the tab's desc says every text")
			eq(option.width, nil, key .. ' has no Ace width')
			-- A slider can't be small in SaftUI's window; it takes a half.
			eq(option.size, nil, key .. ' takes the normal size')
			eq(type(option.default), 'table', fontKey .. ' ' .. key .. ' resets by itself')
		end
		eq(args.font_size.min .. '/' .. args.font_size.max .. '/' .. args.font_size.step, '1/100/1', 'size range')
		eq(args.shadow_x.min .. '/' .. args.shadow_x.max .. '/' .. args.shadow_x.step, '-5/5/1', 'shadow X range')
		eq(args.shadow_y.min .. '/' .. args.shadow_y.max .. '/' .. args.shadow_y.step, '-5/5/1', 'shadow Y range')
		eq(args.spacing.min .. '/' .. args.spacing.max .. '/' .. args.spacing.step, '0/20/1', 'spacing range')
	end
	eq(count, 6, 'the six shared fonts')
end)

test('FN.FIELDS and FN.FieldOptions: five options at orders 2 to 6, a subset on request, descs by subject, reads and writes by field name', function()
	eq(table.concat(FN.FIELDS, ','), 'font_size,font_outline,shadow_x,shadow_y,spacing')
	local log = {}
	local function read(field) log[#log + 1] = 'read ' .. field; return field end
	local function write(field, value) log[#log + 1] = 'write ' .. field .. '=' .. tostring(value) end
	local shared = FN.FieldOptions(read, write, 'shared')
	local ORDERS = { font_size = 2, font_outline = 3, shadow_x = 4, shadow_y = 5, spacing = 6 }
	local NAMES = { font_size = 'Size', font_outline = 'Outline', shadow_x = 'Shadow offset X', shadow_y = 'Shadow offset Y', spacing = 'Line spacing' }
	for field, order in pairs(ORDERS) do
		eq(shared[field].order, order, field .. ' order')
		eq(shared[field].name, NAMES[field], field .. ' name')
		eq(shared[field].default, nil, field .. ': FieldOptions gives no reset (the tab adds it, the menu has none)')
	end
	for field in pairs(shared) do check(ORDERS[field], 'no option but the five: ' .. field) end
	eq(shared.font_size.type, 'range')
	eq(shared.font_size.min .. '/' .. shared.font_size.max .. '/' .. shared.font_size.step, '1/100/1')
	eq(shared.shadow_x.min .. '/' .. shared.shadow_x.max, '-5/5')
	eq(shared.shadow_y.min .. '/' .. shared.shadow_y.max, '-5/5')
	eq(shared.spacing.min .. '/' .. shared.spacing.max, '0/20')
	eq(shared.font_outline.type, 'select')
	eq(shared.font_outline.values, FN.outlines)
	eq(table.concat(shared.font_outline.sorting, ','), 'NONE,OUTLINE,THICKOUTLINE,MONOCHROME,MONOCHROMEOUTLINE,MONOCHROMETHICKOUTLINE', 'in the list order')

	eq(shared.shadow_y.get({ 'x' }), 'shadow_y', 'get reads by field name')
	shared.shadow_x.set({ 'x' }, 3)
	shared.font_size.set({ 'x' }, 20)
	eq(table.concat(log, ';'), 'read shadow_y;write shadow_x=3;write font_size=20')

	local text = FN.FieldOptions(read, write, 'text')
	eq(text.font_size.desc, 'How big this text is.')
	eq(text.font_outline.desc, 'The outline around its letters.')
	eq(text.shadow_x.desc, 'How far right of the letters its shadow falls, in pixels; below 0, to the left.')
	eq(text.shadow_y.desc, 'How far above the letters its shadow falls, in pixels; below 0, below them.')
	eq(text.spacing.desc, 'The gap between its lines, in pixels, when it runs to more than one line.')
	check(shared.font_size.desc ~= text.font_size.desc, 'the tab and the menu word their descs apart')

	local some = FN.FieldOptions(read, write, 'text', { 'font_size', 'font_outline' })
	local n = 0
	for field in pairs(some) do n = n + 1 end
	eq(n, 2, 'fields leaves out the rest')
	eq(some.font_size.order, 2, 'and keeps the orders')
	eq(some.font_outline.order, 3)
	eq(#take_errors(), 0, 'no errors')
end)

test('FN.FontSettingDefault: differs is any value but the default (a table always does); reset writes the default and runs FontsChanged', function()
	local value
	local function read(info) return value end
	local function write(info, v) value = v end
	local default = FN.FontSettingDefault(read, write, 'pixel')
	value = 'pixel'
	eq(default.differs({}), false, 'the default itself')
	value = 'normal'
	eq(default.differs({}), true, 'another shared font')
	value = { font_name = 'Colus', font_size = 15 }
	eq(default.differs({}), true, 'a typeface')
	value = nil
	eq(default.differs({}), true, 'nil, a value that names nothing')
	eq(default.text, 'Small text', 'the default in words')
	value = 'normal'
	changes = 0
	default.reset({})
	eq(value, 'pixel', 'reset wrote the default')
	eq(changes, 1, 'and ran FontsChanged once')
	check(FN.FontSettingDefault(read, write, 'normal').text == 'Text', 'a shared font by name')
	check(FN.FontSettingDefault(read, write, { font_name = 'Colus', font_size = 15, font_outline = 'OUTLINE' }).text == 'Colus 15, outline', 'a typeface by its label')
	eq(#take_errors(), 0, 'no errors')
end)

test('FN.FieldValue and FN.WithField: one field of a look, X and Y as the shadow\'s two numbers; a copy with one field changed', function()
	local look = { font_name = 'Colus', font_size = 15, font_outline = 'OUTLINE', shadow_offset = { 1, -2 }, spacing = 4 }
	eq(FN.FieldValue(look, 'font_name'), 'Colus')
	eq(FN.FieldValue(look, 'font_size'), 15)
	eq(FN.FieldValue(look, 'shadow_x'), 1)
	eq(FN.FieldValue(look, 'shadow_y'), -2)
	eq(FN.FieldValue(look, 'spacing'), 4)
	local copy = FN.WithField(look, 'shadow_y', 3)
	eq(copy.shadow_offset[1] .. ',' .. copy.shadow_offset[2], '1,3', 'the one axis changed')
	eq(look.shadow_offset[2], -2, 'the original is untouched')
	check(copy.shadow_offset ~= look.shadow_offset, 'the shadow is a copy too')
	eq(FN.WithField(look, 'font_size', 20).font_size, 20)
	eq(FN.WithField(look, 'font_size', 20).font_name, 'Colus', 'the rest is carried')
	eq(FN.WithField(look, 'shadow_x', 0).shadow_offset[1], 0)
	eq(look.font_size, 15, 'the original is untouched')
	eq(table.concat(FN.OUTLINE_ORDER, ','), 'NONE,OUTLINE,THICKOUTLINE,MONOCHROME,MONOCHROMEOUTLINE,MONOCHROMETHICKOUTLINE')
end)

test('the outline names in sentence case, in the list order None ... Monochrome thick outline', function()
	eq(FN.outlines.NONE, 'None')
	eq(FN.outlines.OUTLINE, 'Outline')
	eq(FN.outlines.THICKOUTLINE, 'Thick outline')
	eq(FN.outlines.MONOCHROME, 'Monochrome')
	eq(FN.outlines.MONOCHROMEOUTLINE, 'Monochrome outline')
	eq(FN.outlines.MONOCHROMETHICKOUTLINE, 'Monochrome thick outline')
	local root, row = Row('pixel', 'font_outline')
	local names = {}
	for i, entry in ipairs(OM.Values(root, row)) do names[i] = entry.name end
	eq(table.concat(names, ','), 'None,Outline,Thick outline,Monochrome,Monochrome outline,Monochrome thick outline', "the row lists them in the list's order")
end)

-- A value that differs from each font's default, per field, and what it is
-- written as.
local OTHER = { font_name = 'Righteous', font_size = 13, font_outline = 'NONE', shadow_x = 1, shadow_y = 1, spacing = 5 }
local function Default(fontKey, field) return FN.FieldValue(st.defaults.fonts[fontKey], field) end
local function Saved(fontKey, field) return FN.FieldValue(st.config.profile.fonts[fontKey], field) end

test("every row resets by itself while it differs from st.defaults.fonts, putting the default on its object at once", function()
	for _, entry in ipairs(FN.FONTS) do
		for _, field in ipairs({ 'font_name', 'font_size', 'font_outline', 'shadow_x', 'shadow_y', 'spacing' }) do
			local fontKey = entry.key
			local label = fontKey .. '.' .. field
			local root, row = Row(fontKey, field)
			eq(OM.DefaultState(root, row).differs, false, label .. ' at its default')
			Set(fontKey, field, OTHER[field])
			root, row = Row(fontKey, field)
			local state = OM.DefaultState(root, row)
			eq(state.differs, true, label .. ' differs once changed')
			eq(state.value[1], Default(fontKey, field), label .. ' names its default')
			changes = 0
			eq(OM.DefaultReset(root, row), true, label .. ' resets')
			eq(changes, 1, label .. ': the reset ran FontsChanged once')
			eq(Saved(fontKey, field), Default(fontKey, field), label .. ' is back in the profile')
			eq(OM.DefaultState(root, row).differs, false, label .. ' no longer differs')
			local path_, size, flags = st:GetFont(fontKey):GetFont()
			eq(select(2, st:GetFont(fontKey):GetFont()), st.defaults.fonts[fontKey].font_size, label .. ': the object has the default size')
			eq(path_, path(st.defaults.fonts[fontKey].font_name), label .. ': and face')
			eq(flags, st.OutlineFlag(st.defaults.fonts[fontKey].font_outline), label .. ': and outline')
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("a reset names its default: the size as a number, an outline by its label; X differs while Y does not", function()
	Set('pixel', 'shadow_x', 2)
	local root, row = Row('pixel', 'shadow_x')
	eq(OM.DefaultState(root, row).differs, true, 'X differs')
	local _, yrow = Row('pixel', 'shadow_y')
	eq(OM.DefaultState(root, yrow).differs, false, 'Y does not')
	Set('pixel', 'font_size', 12)
	root, row = Row('pixel', 'font_size')
	eq(OM.DefaultState(root, row).value[1], 10, "Small text's default size, as 'Size goes back to its default: 10.'")
	Set('pixel', 'font_outline', 'NONE')
	root, row = Row('pixel', 'font_outline')
	local state = OM.DefaultState(root, row)
	eq(state.value[1], 'MONOCHROMEOUTLINE')
	local label
	for _, entry in ipairs(OM.Values(root, row)) do
		if entry.key == state.value[1] then label = entry.name end
	end
	eq(label, 'Monochrome outline', 'which the tooltip writes by the row\'s list')
	for _, field in ipairs({ 'shadow_x', 'font_size', 'font_outline' }) do
		local r, rw = Row('pixel', field)
		OM.DefaultReset(r, rw)
	end
	eq(Saved('pixel', 'shadow_x'), 0)
	eq(Saved('pixel', 'font_size'), 10)
	eq(#take_errors(), 0, 'no errors')
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

test("Kinds of text: Window titles, Button text, Check box labels, each with its reset; Button text's desc names the bag slot bars and the bank's bag slots", function()
	local section = Tab().args.kinds
	eq(section.type, 'group')
	eq(section.inline, true, 'a section, not a tab')
	eq(section.name, 'Kinds of text')
	eq(section.desc, KINDS_NOTE, 'its note')
	eq(Sections()[8].title, 'Kinds of text', 'last on the tab')

	local rows = {}
	for i, r in ipairs(ByOrder(section.args)) do rows[i] = r.key .. '=' .. r.v.name end
	eq(table.concat(rows, ','), 'window_titles=Window titles,button_text=Button text,checkbox_labels=Check box labels')
	for key, option in pairs(section.args) do
		eq(option.type, 'font', key)
		check(type(option.desc) == 'string' and #option.desc > 30, key .. ' has a desc')
		eq(option.width, nil, key .. ' has no Ace width')
		eq(option.size, nil, key .. ' takes the normal size')
		eq(type(option.default), 'table', key .. ' resets by itself')
		eq(option.values, nil, key .. ' lists no values: the font row builds its own list')
		-- Its list: the shared fonts by name, from code, in FN.FONTS order.
		local entries = W.FontEntries(nil, false)
		local keys = {}
		for i, entry in ipairs(FN.FONTS) do
			local e = entries[i + 1]
			eq(e.key, entry.key, key .. ' lists ' .. entry.key .. ' in FN.FONTS order')
			eq(e.label, FN:Font(entry.key).name, key .. ' by its name, from code')
			keys[i] = e.key
		end
		eq(#keys, 6, key .. ' lists every shared font')
	end
	check(section.args.window_titles.desc:find("gold and free%-slot"), "Window titles' tooltip names the bags' gold and free-slot text")
	check(section.args.button_text.desc:find('totem bar', 1, true), "Button text's tooltip names the totem bar")
	check(section.args.button_text.desc:find('bag slot bars', 1, true), "and the bag slot bars")
	check(section.args.button_text.desc:find("bank's bag slots", 1, true), "and the bank's bag slots")
	check(section.args.checkbox_labels.desc:find('check box', 1, true), "Check box labels' tooltip names check boxes")

	-- Each resets to its default: Text, Small text, Text.
	local DEFAULTS = { window_titles = { 'headers', 'normal', 'Text' }, button_text = { 'buttons', 'pixel', 'Small text' },
		checkbox_labels = { 'panels', 'normal', 'Text' } }
	for key, case in pairs(DEFAULTS) do
		local profileKey, default, label = unpack(case)
		local root, row = Row('kinds', key)
		eq(OM.DefaultState(root, row).differs, false, key .. ' at its default')
		Set('kinds', key, 'subtitle')
		root, row = Row('kinds', key)
		local state = OM.DefaultState(root, row)
		eq(state.differs, true, key .. ' differs')
		eq(state.text, label, key .. ' names its default in words')
		changes = 0
		eq(OM.DefaultReset(root, row), true, key .. ' resets')
		eq(changes, 1, key .. ': FontsChanged once')
		eq(st.config.profile[profileKey].font, default, key .. ' is back in the profile')
		eq(OM.DefaultState(root, row).differs, false, key .. ' no longer differs')
	end
	check(panel.title:GetFontObject() == st:GetFont('normal'), "Window titles' reset reaches the title at once")
	eq(#take_errors(), 0, 'no errors')
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
		if key ~= 'kinds' and key ~= 'intro' then count = count + 1 end
	end
	eq(count, 6, 'six sections')
	for key, option in pairs(tab.args.kinds.args) do
		check(option.faceOnly ~= true, key .. ' is not face only')
	end
	for _, entry in ipairs(W.FontEntries(nil, false)) do
		check(entry.key ~= 'pixel_huge' and entry.key ~= 'normal_med', "the font list does not list the dropped font " .. tostring(entry.key))
	end
	FN:UpdateFontConfig()
	eq(FN.font_objects.pixel_huge, nil, 'and no object')
	eq(#take_errors(), 0, 'no errors')
	fonts.pixel_huge = nil
	fonts.normal.name = nil
end)

------------------------------------------------------------------ /sui's own titles

test("/sui's titles take Heading's face and outline at their own sizes; tabs, labels and the small line Text's", function()
	local SIZES = { title = 34, brand = 26, section = 15, group = 13, caption = 11, mini = 18 }
	for key, size in pairs(SIZES) do
		local p, s, f = OB.Font(key):GetFont()
		eq(p, path('Colus'), key .. ': Heading\'s face')
		eq(s, size, key .. ': its own size')
		eq(f, 'OUTLINE', key .. ': Heading\'s outline')
	end
	for key, size in pairs({ tab = 17, label = 16, small = 13, note = 15 }) do
		local p, s, f = OB.Font(key):GetFont()
		eq(p, path('AgencyFB Bold'), key .. ": Text's face")
		eq(s, size, key .. ': its own size')
		eq(f, 'OUTLINE', key .. ": Text's outline")
	end
	local p, s, f = W.GetFont():GetFont()
	eq(p, path('AgencyFB Bold'), "the field font is Text's face")
	eq(s, 15, 'at 15')
	eq(f, 'OUTLINE')
	eq(#take_errors(), 0, 'no errors')
end)

test("Heading's face changed on the tab reaches /sui's titles at once; its size doesn't, nor does Huge title", function()
	Set('heading', 'font_name', 'Bebas Neue')
	for key, size in pairs({ title = 34, brand = 26, section = 15, group = 13, caption = 11, mini = 18 }) do
		local p, s = OB.Font(key):GetFont()
		eq(p, path('Bebas Neue'), key .. ': the new face, at once')
		eq(s, size, key .. ': at its own size')
	end
	eq(select(1, OB.Font('label'):GetFont()), path('AgencyFB Bold'), "a label keeps Text's face")
	Set('heading', 'font_outline', 'THICKOUTLINE')
	eq(select(3, OB.Font('section'):GetFont()), 'THICKOUTLINE', "Heading's outline reaches them too")
	Set('heading', 'font_size', 24)
	eq(select(2, OB.Font('section'):GetFont()), 15, "Heading's size leaves the section title as it is")
	eq(select(2, OB.Font('title'):GetFont()), 34, 'and the page title')
	Set('title', 'font_name', 'Righteous')
	eq(select(1, OB.Font('title'):GetFont()), path('Bebas Neue'), "Huge title's face is no longer /sui's")
	Set('title', 'font_name', 'Colus')

	-- Text's face reaches the field font and the labels, as before.
	Set('normal', 'font_name', 'Righteous')
	eq(select(1, W.GetFont():GetFont()), path('Righteous'), 'the field font follows Text')
	eq(select(1, OB.Font('label'):GetFont()), path('Righteous'), 'and a label')
	eq(select(2, W.GetFont():GetFont()), 15, 'at 15')
	Set('normal', 'font_size', 20)
	eq(select(2, W.GetFont():GetFont()), 15, "Text's size leaves the field font at 15")

	for _, field in ipairs({ 'font_name', 'font_outline', 'font_size' }) do
		local r, rw = Row('heading', field)
		OM.DefaultReset(r, rw)
	end
	for _, field in ipairs({ 'font_name', 'font_size' }) do
		local r, rw = Row('normal', field)
		OM.DefaultReset(r, rw)
	end
	eq(select(1, OB.Font('title'):GetFont()), path('Colus'), 'back to Colus')
	eq(#take_errors(), 0, 'no errors')
end)

test("a profile switch redraws /sui's titles from the new profile's Heading", function()
	local first = st.config:GetCurrentProfile()
	Set('heading', 'font_name', 'Bebas Neue')
	st.config:SetProfile('FontsTestThree')
	eq(select(1, OB.Font('title'):GetFont()), path('Colus'), "the new profile's Heading")
	st.config:SetProfile(first)
	eq(select(1, OB.Font('title'):GetFont()), path('Bebas Neue'), "and the first profile's again")
	local r, rw = Row('heading', 'font_name')
	OM.DefaultReset(r, rw)
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ what a row shows and writes

test("a raw partial saved table and a malformed one read as they are drawn; only what differs has a reset", function()
	local fonts = st.config.profile.fonts
	local function State(field)
		local root, row = Row('pixel', field)
		return OM.Get(root, row), OM.DefaultState(root, row).differs
	end
	fonts.pixel = { font_name = 'Bebas Neue' }
	local size, sizeDiffers = State('font_size')
	local face, faceDiffers = State('font_name')
	eq(size, 10, 'the size reads the default')
	eq(sizeDiffers, false, 'and has no reset')
	eq(face, 'Bebas Neue')
	eq(faceDiffers, true, 'the face does')
	eq(State('font_outline'), 'MONOCHROMEOUTLINE')
	eq(State('shadow_x'), 0)
	eq(State('spacing'), 4)

	fonts.pixel = { font_size = 500, font_outline = 'BOLD', shadow_offset = 3, spacing = '4' }
	local size2, differs2 = State('font_size')
	eq(size2, 100, 'a size of 500 reads the clamp')
	eq(differs2, true, 'and differs')
	eq(State('font_outline'), 'MONOCHROMEOUTLINE', 'an unknown outline reads the default')
	eq(State('shadow_x') .. ',' .. State('shadow_y'), '0,0', 'a shadow that is a number reads 0, 0')
	eq(State('spacing'), 4, 'a spacing that is a string reads the default')

	-- A set on the malformed shadow rebuilds it from what is drawn, and errors nowhere.
	Set('pixel', 'shadow_x', 1)
	eq(table.concat(fonts.pixel.shadow_offset, ','), '1,0', 'X saved with Y as drawn')
	eq(Shadow('pixel'), '1,0', 'and on the object')
	-- Put the profile's Small text back as AceDB filled it.
	local d = st.defaults.fonts.pixel
	fonts.pixel = { font_name = d.font_name, font_size = d.font_size, font_outline = d.font_outline,
		shadow_offset = { d.shadow_offset[1], d.shadow_offset[2] }, spacing = d.spacing }
	FN:UpdateFontConfig('pixel')
	eq(Saved('pixel', 'font_size'), 10, 'the profile is back to the default')
	eq(#take_errors(), 0, 'no errors')
end)

test("a set applies the font's object before st:FontsChanged runs, so a module sees the new look", function()
	Set('pixel', 'font_size', 12)
	eq(sawSize, 12, 'FontsChanged saw the object at 12')
	local root, row = Row('pixel', 'font_size')
	OM.DefaultReset(root, row)
	eq(sawSize, 10, 'and a reset the same')
	eq(#take_errors(), 0, 'no errors')
end)
