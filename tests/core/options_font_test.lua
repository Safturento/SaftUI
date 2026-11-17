-- The font row, SaftUI's own option type 'font' (SaftUI-Core/Config/
-- optionsfont.lua): a select face drawn in the face it names and one 16 by 24
-- slot, the link to the shared font's section of Global settings > Fonts
-- (OW:Reveal) or, for a typeface, the dots of its own menu (Size, Outline,
-- Shadow offset X and Y, Line spacing); its list (W.FontEntries and W.OpenList: SaftUI's fonts, then
-- every typeface, each in its own face), picking, the face-only variant, the
-- reset's words, shares and search; and generators.font.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua: the
-- Fonts module, enabled, so the shared fonts have their objects), the model,
-- the widgets, the body and the window's files, as options_window_helpers.lua
-- loads them. The pages are synthetic: font rows on bodies made with OB.New,
-- and, for the link, a module whose page holds a font row and an item with a
-- menu, opened in the real window beside the real Fonts page. The mouse is
-- played by firing the frames' scripts, OnEnter and OnLeave with true as the
-- game passes them.
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local OM, W, OB, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local FN = st:GetModule('Fonts')
local generators = st.Config.generators

------------------------------------------------------------------ the synthetic page

local vals, sets -- the saved values by key; every value a set saved, in order

local function fresh()
	vals, sets = {}, {}
end
fresh()

-- A font row saved under its key in vals. opts is generators.font's.
local function FontRow(key, order, opts, extra)
	local option = generators.font(order, key .. '.', opts)
	option.name = extra and extra.name or key
	option.get = function() return vals[key] end
	option.set = function(_, value)
		vals[key] = value
		sets[#sets + 1] = value
	end
	for k, v in pairs(extra or {}) do
		if k ~= 'name' then option[k] = v end
	end
	return option
end

local function Page(args)
	return { page = { type = 'group', name = 'Page', args = args } }
end

-- A body 774 wide on a content frame at the screen's top left, the page drawn,
-- its cells by key.
local function draw(root, onChanged)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 600)
	local body = OB.New(content, root, onChanged, 774)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- GameTooltip, as a stand-in that notes the lines it's given.
local function watch_tooltip()
	local tip = { lines = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame, anchor) tip.owner, tip.anchor = frame, anchor end,
		ClearLines = function() tip.lines = {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		AddDoubleLine = function(_, left) tip.lines[#tip.lines + 1] = left end,
		Show = function() tip.shown = true end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner, tip.shown = nil, false end,
	}
	return tip, function() _G.GameTooltip = saved end
end

-- fn(tip) under look, with GameTooltip watched; the look, the cursor, the
-- tooltip and the list put back after.
local function in_look(look, fn)
	st.config.profile.theme.name = look
	local tip, restore = watch_tooltip()
	local ok, err = pcall(fn, tip)
	W.CloseList()
	restore()
	st.config.profile.theme.name = 'thick'
	stub.cursor_x, stub.cursor_y = 0, 0
	if not ok then error(err, 0) end
end

local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function text_rgb(fs) return rgb(fs:GetTextColor()) end
local function blue() return rgb(st.config.profile.theme.accent:GetRGB()) end
local function path(name) return st.LSM:Fetch('font', name) end
local function face_of(fs) local p, size, flags = fs:GetFont(); return p, size, flags end

-- A drawn font row's widget: key's value set to value first.
local function row_widget(key, value, opts, extra)
	fresh()
	vals[key] = value
	local _, by, content = draw(Page({ [key] = FontRow(key, 1, opts, extra) }))
	return by[key].widget, by[key], content
end

local function open(w)
	stub.click(w.face)
	return W.GetListFrames()
end

local function entry_row(list, key)
	for _, row in ipairs(list.rows) do
		if row.entry and row.entry.key == key then return row end
	end
end

------------------------------------------------------------------ generators.font

test('generators.font: type font, named Font, its desc and order; opts.faceOnly and opts.fields become faceOnly and fontFields', function()
	local plain = generators.font(3, 'The font.')
	eq(plain.type, 'font')
	eq(plain.name, 'Font')
	eq(plain.desc, 'The font.')
	eq(plain.order, 3)
	eq(plain.faceOnly, nil, 'a row is not face only by default')
	eq(plain.fontFields, nil, 'and names no fields: every one')
	eq(plain.values, nil, 'no list of values: the row builds its own')
	eq(plain.sorting, nil)
	local fields = { 'font_size', 'font_outline' }
	local option = generators.font(4, 'D', { faceOnly = true, fields = fields })
	eq(option.faceOnly, true)
	check(option.fontFields == fields, 'fontFields is opts.fields')
	eq(option.type, 'font')
	check(OM and W.WIDTH.font == 190, 'W.WIDTH.font is 190')
	eq(W.Kit.FONT_SLOT_GAP.theme, 4)
	eq(W.Kit.FONT_SLOT_GAP.blizzard, 8)
	check(st.config.profile ~= nil)
end)

------------------------------------------------------------------ the row

test("the row under Thick, Thin and Blizzard: label, the 170 x 24 face, the 16 x 24 slot at the cell's right edge, 4 apart (8 under Blizzard)", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			local blizzard = look == 'blizzard'
			local w, cell = row_widget('header', 'heading')
			local where = look .. ': '
			eq(w:GetWidth(), blizzard and 194 or 190, where .. 'the widget is 190 wide, 194 under Blizzard')
			eq(w.frame:GetWidth(), w:GetWidth(), where .. "its frame is that wide")
			eq(w.frame:GetHeight(), 24, where .. 'a field tall')
			eq(w.face:GetWidth(), 170, where .. 'the face is a select wide')
			eq(w.face:GetHeight(), 24, where .. 'and a field tall')
			eq(w.dots:GetWidth(), 16, where .. 'the slot is 16 wide')
			eq(w.dots:GetHeight(), 24, where .. 'and 24 tall')
			eq(w.dots:GetRight(), w.frame:GetRight(), where .. "the slot is at the cell's right edge")
			eq(w.dots:GetLeft() - w.face:GetRight(), blizzard and 8 or 4, where .. 'the face ends a gap before the slot')
			eq(w.face:GetLeft(), w.frame:GetLeft(), where .. 'the face at the widget\'s left')
			eq(cell.frame:GetRight() - w.frame:GetRight(), 0, where .. "the widget is at the cell's right")
			check(cell.label:GetWidth() + w:GetWidth() <= cell.frame:GetWidth(), where .. 'the label leaves it room')
			local left = w.face:GetLeft()
			vals.header = { font_name = 'Homespun', font_size = 10 }
			w:Refresh()
			check(w.dots:IsShown(), where .. 'a typeface puts the dots in the slot')
			eq(w.face:GetLeft(), left, where .. 'the face does not move when the slot changes')
			eq(w.dots:GetRight(), w.frame:GetRight(), where .. 'and the slot keeps its room')
		end)
	end
end)

test('a shared font picked: the face reads its name in its face at 15, the slot shows the link', function()
	in_look('thick', function()
		local w = row_widget('header', 'heading')
		eq(w.value, 'heading')
		eq(w.kind, 'shared')
		eq(w.face.text:GetText(), 'Heading')
		local p, size, flags = face_of(w.face.text)
		eq(p, path('Colus'), "in Heading's face")
		eq(size, 15)
		eq(flags, '', 'no outline')
		eq(w.dots.icon:GetTexture(), st.icons.link, 'the link')
		check(w.dots:IsShown(), 'shown')
		w = row_widget('header', 'pixel_med')
		eq(w.face.text:GetText(), 'Large numbers')
		eq(face_of(w.face.text), (st:FontValues('pixel_med')), "in Large numbers' face")
		-- Nothing saved (or a value that names nothing): Text, in Text's face.
		for _, value in ipairs({ false, 'nonsense' }) do
			w = row_widget('header', value or nil)
			eq(w.face.text:GetText(), 'Text', 'a value that names nothing reads Text')
			eq(face_of(w.face.text), (st:FontValues('normal')), "in Text's face")
			eq(w.kind, 'shared')
			eq(w.dots.icon:GetTexture(), st.icons.link)
			check(w.dots:IsShown())
		end
		eq(#sets, 0, 'reading writes nothing')
	end)
end)

test('a typeface picked: the face reads its face in that face; the slot holds the dots', function()
	in_look('thick', function()
		local w = row_widget('header', { font_name = 'Homespun', font_size = 10, font_outline = 'NONE' })
		eq(w.kind, 'typeface')
		eq(w.face.text:GetText(), 'Homespun')
		local p, size = face_of(w.face.text)
		eq(p, path('Homespun'))
		eq(size, 15, 'at 15, whatever the text\'s own size')
		check(w.dots:IsShown(), 'the slot holds the dots')
		-- A partial table reads as Text's with the table over it.
		w = row_widget('header', { font_name = 'Bebas Neue' })
		eq(w.face.text:GetText(), 'Bebas Neue')
		eq(w.kind, 'typeface')
	end)
end)

------------------------------------------------------------------ the list

test('the list: SaftUI fonts, the six in order each in its face, Typefaces, then every LibSharedMedia face in its order, each in its face', function()
	in_look('thick', function()
		local w = row_widget('header', nil)
		local entries, selected = W.FontEntries(nil, false)
		eq(selected, 'normal', 'a nil value selects Text')
		eq(entries[1].caption, true)
		eq(entries[1].label, 'SaftUI fonts')
		local labels = { 'Text', 'Small text', 'Large numbers', 'Heading', 'Huge title', 'Subtitle' }
		for i, entry in ipairs(FN.FONTS) do
			local e = entries[i + 1]
			eq(e.key, entry.key, 'entry ' .. (i + 1) .. ' is ' .. entry.key)
			eq(e.label, labels[i])
			eq(e.font, (st:FontValues(entry.key)), 'in its own face')
			check(not e.caption)
		end
		eq(entries[8].caption, true)
		eq(entries[8].label, 'Typefaces')
		local names = st.LSM:List('font')
		check(#names >= 12, 'LibSharedMedia lists the faces')
		eq(#entries, 8 + #names)
		for i, name in ipairs(names) do
			local e = entries[8 + i]
			eq(e.key, 'face:' .. name)
			eq(e.label, name)
			eq(e.font, st.LSM:Fetch('font', name))
		end

		-- Drawn: Text is picked, the caption above it in view.
		local list = open(w)
		local group = OB.Font('group')
		eq(list.rows[1].text:GetText(), 'SaftUI fonts')
		eq(face_of(list.rows[1].text), (group:GetFont()), "the caption in the group font's face")
		eq(list.rows[1].text:GetFontObject(), group)
		eq(text_rgb(list.rows[1].text), rgb(st.config.profile.colors.text.muted:GetRGB()), 'in Text > Muted')
		for i = 2, 7 do
			local row = list.rows[i]
			eq(row.text:GetText(), labels[i - 1])
			local p, size, flags = face_of(row.text)
			eq(p, (st:FontValues(FN.FONTS[i - 1].key)), labels[i - 1] .. ' is drawn in its face')
			eq(size, 15, 'at 15')
			eq(flags, '', 'with no outline')
		end
		eq(list.rows[8].text:GetText(), 'Typefaces')
		eq(face_of(list.rows[8].text), (group:GetFont()), 'the second caption too')
		for i = 9, 12 do
			eq(face_of(list.rows[i].text), st.LSM:Fetch('font', names[i - 8]), names[i - 8] .. ' in its own face')
		end
		W.CloseList()

		-- The pooled caption rows keep the group font after a face was drawn in them.
		vals.header = { font_name = names[#names] }
		w:Refresh()
		list = open(w)
		local pick = entry_row(list, 'face:' .. names[#names])
		check(pick ~= nil and pick:IsShown(), 'the picked face is in view')
		eq(list.offset, #list.entries - 12, 'the list is scrolled as far as it goes for a face at its end')
		W.CloseList()
		-- A face under the Typefaces caption: the caption is in view with it.
		vals.header = { font_name = names[6] }
		w:Refresh()
		list = open(w)
		eq(list.offset, 7, 'the Typefaces caption is the top row')
		eq(list.rows[1].text:GetText(), 'Typefaces')
		W.CloseList()
		-- A face further down than the rows reach from its caption: it is the top row.
		vals.header = { font_name = names[14] }
		w:Refresh()
		list = open(w)
		eq(list.offset, math.min(#list.entries - 12, 8 + 14 - 1), 'the list opens on it')
		check(entry_row(list, 'face:' .. names[14]):IsShown(), 'in view')
		W.CloseList()
		vals.header = { font_name = names[#names] }
		w:Refresh()
		vals.header = nil
		w:Refresh()
		list = open(w)
		eq(list.rows[1].text:GetText(), 'SaftUI fonts')
		eq(list.rows[1].text:GetFontObject(), group, 'the caption keeps the group font object')
		eq(face_of(list.rows[1].text), (group:GetFont()), "and its face, though a face was drawn in the row before")
		local gp, gsize = group:GetFont()
		local _, size = face_of(list.rows[1].text)
		eq(size, gsize, 'and its size')
		eq(gp, face_of(list.rows[8].text))
	end)
end)

test('the picked entry is a selected row (a bar and the fade, its text Normal): the shared font, or the typeface by its face', function()
	in_look('thick', function()
		local w = row_widget('header', 'heading')
		local list = open(w)
		local normal = rgb(st.config.profile.colors.text.normal:GetRGB())
		check(st:GetState(entry_row(list, 'heading'), 'selected'), 'Heading is the picked one')
		check(st:StateLook(entry_row(list, 'heading')).bar.shown, 'with the bar')
		eq(text_rgb(entry_row(list, 'heading').text), normal, 'its text is Normal, no longer blue')
		check(not st:GetState(entry_row(list, 'subtitle'), 'selected'), 'Subtitle is not')
		eq(text_rgb(entry_row(list, 'subtitle').text), normal, 'Subtitle is Normal')
		W.CloseList()
		local names = st.LSM:List('font')
		w = row_widget('header', { font_name = names[3], font_size = 20 })
		list = open(w)
		eq(list.selected, 'face:' .. names[3])
		check(st:GetState(entry_row(list, 'face:' .. names[3]), 'selected'), 'the typeface is the picked one')
		eq(text_rgb(entry_row(list, 'face:' .. names[4]).text), normal, 'the next face is not')
		for i = 1, 7 do
			local row = list.rows[i]
			if row.entry and row.entry.key and row.entry.key ~= list.selected then eq(text_rgb(row.text) ~= blue(), true) end
		end
		W.CloseList()
	end)
end)

------------------------------------------------------------------ picking

test('picking: a shared font saves its key; a typeface a fresh table filled from what showed; a face swap keeps the options', function()
	in_look('thick', function()
		local w = row_widget('header', 'heading')
		local list = open(w)
		stub.click(entry_row(list, 'subtitle'))
		eq(sets[1], 'subtitle', 'a shared font saves its key')
		eq(W.ListOwner(), nil, 'and the list closes')
		eq(w.value, 'subtitle', 'the row follows')

		vals.header = 'heading'
		w:Refresh()
		sets = {}
		w:Pick('face:Bebas Neue')
		local t = sets[1]
		eq(type(t), 'table')
		eq(t.font_name, 'Bebas Neue')
		eq(t.font_size, 15)
		eq(t.font_outline, 'OUTLINE')
		eq(t.shadow_offset[1] .. ',' .. t.shadow_offset[2], '0,0')
		eq(t.spacing, 4)
		eq(w.kind, 'typeface')
		check(w.dots:IsShown(), 'the slot holds the dots')

		-- A face swap keeps the other fields, in a new table; the first is untouched.
		t.font_size, t.font_outline, t.spacing = 22, 'THICKOUTLINE', 9
		w:Pick('face:Homespun')
		local u = sets[2]
		check(u ~= t, 'a new table')
		eq(t.font_name, 'Bebas Neue', 'the first is unchanged')
		eq(u.font_name, 'Homespun')
		eq(u.font_size, 22)
		eq(u.font_outline, 'THICKOUTLINE')
		eq(u.spacing, 9)
		eq(u.shadow_offset[1] .. ',' .. u.shadow_offset[2], '0,0')

		w:Pick('pixel')
		eq(sets[3], 'pixel', 'back to a shared font: its key')
		eq(w.kind, 'shared')
		check(w.dots:IsShown(), 'the link is back')
		eq(#sets, 3)

		-- From a value that names nothing: Text's look under the new face.
		vals.header = nil
		w:Refresh()
		w:Pick('face:Colus')
		eq(sets[4].font_name, 'Colus')
		eq(sets[4].font_size, st.defaults.fonts.normal.font_size, "Text's size")
	end)
end)

test('a dropped key shows its old face and writes nothing until a pick', function()
	in_look('thick', function()
		local w = row_widget('header', 'pixel_huge')
		eq(w.kind, 'typeface', 'a dropped key is a typeface')
		eq(w.face.text:GetText(), 'Homespun', 'the face it looked like')
		eq(face_of(w.face.text), path('Homespun'))
		check(w.dots:IsShown(), 'the slot holds the dots')
		eq(#sets, 0, 'reading and drawing wrote nothing')
		local list = open(w)
		eq(list.selected, 'face:Homespun', "its old face's entry is the picked one")
		W.CloseList()
		eq(#sets, 0, 'opening the list wrote nothing')
		w:Pick('face:Colus')
		local t = sets[1]
		eq(t.font_name, 'Colus')
		eq(t.font_size, 32, 'the dropped font\'s old size is kept')
		eq(t.font_outline, 'MONOCHROMEOUTLINE', 'and its outline')
		w = row_widget('header', 'normal_med')
		eq(w.face.text:GetText(), 'AgencyFB Bold')
	end)
end)

test('a typeface LibSharedMedia does not list (Review Focus 1)', function()
	in_look('thick', function()
		local w = row_widget('header', { font_name = 'Gone', font_size = 12 })
		eq(w.kind, 'typeface')
		eq(w.face.text:GetText(), 'Gone', 'the saved name is read')
		eq(face_of(w.face.text), (W.GetFont():GetFont()), 'in the field font')
		check(w.dots:IsShown(), 'the dots show for a typeface')
		local list = open(w)
		eq(list.selected, 'face:Gone')
		for _, row in ipairs(list.rows) do
			if row.entry and row.entry.key then eq(text_rgb(row.text) ~= blue(), true, 'no entry is blue: ' .. row.entry.key) end
		end
		local row = list.rows[9]
		local key = row.entry.key
		stub.click(row)
		local t = sets[1]
		eq(t.font_name, key:sub(6), 'picking another face works')
		eq(t.font_size, 12, 'and keeps the size')
	end)
end)

------------------------------------------------------------------ the link

test('the link: its tooltip', function()
	in_look('thick', function(tip)
		local w = row_widget('header', 'heading')
		stub.fire_script(w.dots, 'OnEnter', true)
		check(tip.shown, 'it shows a tooltip')
		eq(tip.owner, w.dots)
		eq(tip.lines[1], 'Heading', "the font's name")
		eq(tip.lines[2], 'A shared font. Its typeface, size and outline are set on Global settings > Fonts, and change every text that uses it.')
		eq(tip.lines[3], 'Click to go there.')
		eq(#tip.lines, 3)
		eq(rgb(w.dots.icon:GetVertexColor()), rgb(st:StateColor('edgeHover')), 'the icon is the lighter tone under the mouse')
		stub.fire_script(w.dots, 'OnLeave', true)
		check(not tip.shown, 'and goes when the mouse leaves')
		eq(rgb(w.dots.icon:GetVertexColor()), rgb(st.config.profile.colors.text.muted:GetRGB()), 'back to Text > Muted')
		-- Text for a value that names nothing.
		w = row_widget('header', nil)
		stub.fire_script(w.dots, 'OnEnter', true)
		eq(tip.lines[1], 'Text')
	end)
end)

local ROWS = st:NewModule('FontLinkRows')
function ROWS:GetConfigTable()
	return {
		name = 'Font link rows', type = 'group', category = 'Frames',
		args = {
			texts = { order = 1, type = 'group', name = 'Texts', args = {
				header = FontRow('header', 1, nil, { name = 'Header font' }),
				hotkey = {
					order = 2, type = 'item', name = 'Hotkey', desc = 'The key.', size = 'small',
					get = function() return true end, set = function() end,
					menu = { type = 'group', name = 'Hotkey', args = {
						face = FontRow('face', 1, { faceOnly = true }, { name = 'Face' }),
					} },
				},
			} },
		},
	}
end

local function cell_at(path_)
	for _, c in ipairs(OW.GetDrawnRows()) do
		local p = c.row.path
		if p and #p == #path_ then
			local same = true
			for i = 1, #p do if p[i] ~= path_[i] then same = false end end
			if same then return c end
		end
	end
end

test("the link's click: Global settings > Fonts at that font with its Typeface label lit, closing an open item menu", function()
	in_look('thick', function()
		fresh()
		vals.header = 'heading'
		st.Config:Open('FontLinkRows', 'texts')
		local w = H.cell('header').widget
		local before = OW.GetRenderCount()
		-- Open the item's menu, then click the link of its face-only row, as the
		-- game delivers it (the menu's catcher takes a click outside it).
		stub.click(H.cell('hotkey').widget.dots)
		check(OW:IsMenuShown(), 'the item menu is open')
		vals.face = 'pixel'
		OW:Render()
		local menuRow
		for _, c in ipairs(OW.GetMenuFrames().body.cells) do
			if c.row.key == 'face' then menuRow = c end
		end
		check(menuRow ~= nil and menuRow.widget.dots:IsShown(), "the menu's face-only row shows its link")
		stub.click(menuRow.widget.dots)
		check(not OW:IsMenuShown(), 'the click closed the menu')
		eq(text_rgb(cell_at({ 'Fonts', 'fonts', 'pixel', 'font_name' }).label), blue(), "Small text's Typeface label is lit")
		st.Config:Close(); H.close_all()
		st.Config:Open('FontLinkRows', 'texts')
		w = H.cell('header').widget
		before = OW.GetRenderCount()
		stub.click(w.dots)
		local state = OW:GetState()
		eq(state.page, 'Fonts', 'Global settings')
		eq(state.tab, 'fonts', 'the Fonts tab')
		check(OW.GetRenderCount() > before, 'the window rendered')
		local lit = cell_at({ 'Fonts', 'fonts', 'heading', 'font_name' })
		check(lit ~= nil, "Heading's Typeface row is drawn")
		eq(text_rgb(lit.label), blue(), 'its label is lit')
		check(OW.S.scrollOffset <= lit.sectionY, "the font's section title is in view, not clipped at the top")
		local other = cell_at({ 'Fonts', 'fonts', 'normal', 'font_name' })
		if other then check(text_rgb(other.label) ~= blue(), "Text's is not") end
		st.Config:Close()
		H.close_all()
		-- OW:Reveal itself, for a font Text reads.
		st.Config:Open('FontLinkRows', 'texts')
		OW:Reveal({ 'Fonts', 'fonts', 'pixel', 'font_name' })
		eq(OW:GetState().page, 'Fonts')
		lit = cell_at({ 'Fonts', 'fonts', 'pixel', 'font_name' })
		check(lit ~= nil)
		eq(text_rgb(lit.label), blue())
		H.close_all()
	end)
end)

test('a row whose value names nothing links to Text; a typeface has no link', function()
	in_look('thick', function()
		fresh()
		st.Config:Open('FontLinkRows', 'texts')
		stub.click(H.cell('header').widget.dots)
		eq(OW:GetState().page, 'Fonts')
		local lit = cell_at({ 'Fonts', 'fonts', 'normal', 'font_name' })
		check(lit ~= nil)
		eq(text_rgb(lit.label), blue(), "Text's Typeface label is lit")
		H.close_all()
	end)
end)

------------------------------------------------------------------ disabled

test('a disabled row: neither the face nor the slot takes a click', function()
	in_look('thick', function()
		local w = row_widget('header', 'heading', nil, { disabled = function() return true end })
		check(w.disabled, 'the row is disabled')
		check(not w.face:IsMouseEnabled(), 'the face takes no mouse')
		check(not w.dots:IsMouseEnabled(), 'nor does the slot')
		stub.click_unchecked(w.face)
		eq(W.ListOwner(), nil, 'a click on the face opens no list')
		w:Open()
		eq(W.ListOwner(), nil, 'nor does Open')
		local saved, calls = OW.Reveal, 0
		OW.Reveal = function() calls = calls + 1 end
		stub.click_unchecked(w.dots)
		eq(calls, 0, 'a click on the slot goes nowhere')
		check(w.face:GetAlpha() == 1, 'the face is not dimmed twice')
		w:SetDisabled(false)
		stub.click(w.dots)
		eq(calls, 1, 'enabled, the same click reveals')
		OW.Reveal = saved
		w:SetDisabled(true)
		w:Pick('pixel')
		eq(#sets, 0, 'and a pick saves nothing')
		-- Enabled again: both take the mouse.
		w:SetDisabled(false)
		check(w.face:IsMouseEnabled() and w.dots:IsMouseEnabled(), 'enabled again')
		stub.click(w.face)
		check(W.ListOwner() == w.face, 'the list opens')
		W.CloseList()
	end)
end)

------------------------------------------------------------------ the face-only variant

test('faceOnly: the same list; a typeface saves its face name, a shared font its key and shows the link; never a dots icon', function()
	in_look('thick', function()
		local w = row_widget('face', 'Homespun', { faceOnly = true })
		eq(w.kind, 'typeface')
		eq(w.face.text:GetText(), 'Homespun')
		eq(face_of(w.face.text), path('Homespun'))
		check(not w.dots:IsShown(), 'a face leaves the slot empty')
		local list = open(w)
		eq(list.selected, 'face:Homespun')
		local entries = W.FontEntries('Homespun', true)
		eq(#list.entries, #entries, 'the same list')
		eq(list.entries[1].label, 'SaftUI fonts')
		eq(list.entries[2].key, 'normal')
		W.CloseList()
		w:Pick('face:Colus')
		eq(sets[1], 'Colus', 'a face name')
		eq(w.kind, 'typeface')
		w:Pick('heading')
		eq(sets[2], 'heading', 'a shared font: its key')
		eq(w.kind, 'shared')
		eq(w.face.text:GetText(), 'Heading')
		check(w.dots:IsShown(), 'with the link')
		eq(w.dots.icon:GetTexture(), st.icons.link, 'never the dots')
		eq(select(2, W.FontEntries('heading', true)), 'heading')
		eq(select(2, W.FontEntries('Colus', true)), 'face:Colus')
		eq(select(2, W.FontEntries(nil, true)), 'normal')
		eq(select(2, W.FontEntries('', true)), 'normal')
		-- The same widget on a row that is not face only reads a string it does not know as Text.
		eq(select(2, W.FontEntries('Colus', false)), 'normal')
		eq(select(2, W.FontEntries('pixel_huge', false)), 'face:Homespun')
		eq(select(2, W.FontEntries({ font_name = 'Colus' }, false)), 'face:Colus')
	end)
end)

------------------------------------------------------------------ resets, shares and search

test("a default's reset names the default by FontLabel: 'Header font goes back to its default: Heading.'", function()
	in_look('thick', function(tip)
		fresh()
		vals.header = 'pixel'
		local default = { differs = function() return vals.header ~= 'heading' end, reset = function() vals.header = 'heading' end, value = function() return 'heading' end }
		local root = Page({ header = FontRow('header', 1, nil, { name = 'Header font', default = default }) })
		local _, by = draw(root)
		local frame = by.header.frame
		check(frame.defaultReset and frame.defaultReset:IsShown(), 'the reset icon shows while it differs')
		stub.fire_script(frame.defaultReset, 'OnEnter', true)
		local found = false
		for _, line in ipairs(tip.lines) do
			if line == 'Header font goes back to its default: Heading.' then found = true end
		end
		check(found, 'its tooltip: ' .. table.concat(tip.lines, ' | '))
		for _, line in ipairs(tip.lines) do check(not line:find('Interface', 1, true) and not line:find('\\', 1, true), 'no file path: ' .. line) end
		stub.fire_script(frame.defaultReset, 'OnLeave', true)

		-- A face-only default names the face.
		local faceDefault = { differs = function() return true end, reset = function() end, value = function() return 'Homespun' end }
		_, by = draw(Page({ face = FontRow('face', 1, { faceOnly = true }, { name = 'Face', default = faceDefault }) }))
		stub.fire_script(by.face.frame.defaultReset, 'OnEnter', true)
		found = false
		for _, line in ipairs(tip.lines) do
			if line == 'Face goes back to its default: Homespun.' then found = true end
		end
		check(found, 'a face-only default names its face: ' .. table.concat(tip.lines, ' | '))
		-- A shared font's key by value, no text given.
		local keyDefault = { differs = function() return true end, reset = function() end, value = function() return 'pixel_med' end }
		_, by = draw(Page({ header = FontRow('header', 1, nil, { name = 'Header font', default = keyDefault }) }))
		stub.fire_script(by.header.frame.defaultReset, 'OnEnter', true)
		found = false
		for _, line in ipairs(tip.lines) do
			if line == 'Header font goes back to its default: Large numbers.' then found = true end
		end
		check(found, 'a key by value names the font: ' .. table.concat(tip.lines, ' | '))
	end)
end)

test('a share on the row: the own mark, the diff icon and Apply to draw as on a select', function()
	in_look('thick', function()
		fresh()
		local own = true
		local function common(share)
			share.source = 'All bars'
			share.shared = function() return 'Heading' end
			share.targets = function() return { { key = 'bar2', label = 'Bar 2' } } end
			share.applyAll = function() end
			share.apply = function() end
			return share
		end
		local member = common({ page = 'Bar 3', own = function() return own end, reset = function() end })
		local source = common({ differs = function() return { { name = 'Bar 3', value = 'Small text' } } end })
		local _, by = draw(Page({
			a = FontRow('a', 1, nil, { name = 'Member font', share = member }),
			b = FontRow('b', 2, nil, { name = 'Source font', share = source }),
		}))
		local parts = by.a.frame.share
		check(parts ~= nil and parts.mark:IsShown(), 'the own mark')
		eq(text_rgb(by.a.label), rgb(st:Color('accent'):GetRGB()), 'the label is the accent')
		local src = by.b.frame.share
		check(src ~= nil and src.diff:IsShown(), 'the diff icon on the source row')
		check(by.a.widget.frame:GetLeft() + by.a.widget:GetWidth() <= by.a.frame:GetRight() + 0.01, 'the control is inside its cell')
		-- Hovering shows the line with Apply to.
		stub.fire_script(by.b.frame, 'OnEnter', true)
		check(src.line:IsShown(), 'the hover line shows: Apply to')
		stub.fire_script(by.b.frame, 'OnLeave', true)
	end)
end)

test('search finds a font row by its name', function()
	fresh()
	local root = Page({ header = FontRow('header', 1, nil, { name = 'Header font' }), other = { type = 'toggle', name = 'Other', desc = 'x', order = 2, get = function() return true end, set = function() end } })
	local found = {}
	for _, r in ipairs(OM.Search(root, 'header')) do found[#found + 1] = r.path[#r.path] end
	eq(table.concat(found, ','), 'header', 'found by its name')
	eq(#OM.Search(root, 'nonsense name'), 0)
end)

------------------------------------------------------------------ whole pixels

test('whole pixels under Thick, Thin and Blizzard, size noise up, down and off', function()
	local HAIR = 2 ^ -14
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			in_look(look, function()
				stub.size_noise = noise
				for _, value in ipairs({ 'heading', { font_name = 'Homespun', font_size = 10 } }) do
					fresh()
					vals.header = value
					local body, by, content = draw(Page({ header = FontRow('header', 1, nil, { name = 'Header font' }) }))
					local off = P.off(content)
					eq(#off, 0, look .. ', noise ' .. noise .. ': ' .. P.report(off))
					body:Release()
				end
				stub.size_noise = 0
			end)
		end
	end
	stub.size_noise = 0
end)

------------------------------------------------------------------ fix round 1

test('a list opened on any shared font shows SaftUI fonts and the fonts above the pick', function()
	in_look('thick', function()
		for _, key in ipairs({ 'heading', 'title', 'subtitle', 'normal' }) do
			local w = row_widget('header', key)
			local list = open(w)
			eq(list.offset, 0, key .. ': the list opens at the top')
			eq(list.rows[1].text:GetText(), 'SaftUI fonts', key .. ': the caption is in view')
			W.CloseList()
		end
		-- The first typeface shows the Typefaces caption over it.
		local names = st.LSM:List('font')
		local w = row_widget('header', { font_name = names[1] })
		local list = open(w)
		eq(list.rows[1].text:GetText(), 'Typefaces')
		W.CloseList()
	end)
end)

test('a face registered after a list was opened is in the next one', function()
	in_look('thick', function()
		local w = row_widget('header', 'heading')
		local before = #W.FontEntries('heading', false)
		st.LSM:Register('font', 'Late face', path('Colus'))
		local entries = W.FontEntries('heading', false)
		eq(#entries, before + 1)
		local found
		for _, e in ipairs(entries) do if e.key == 'face:Late face' then found = e end end
		check(found ~= nil and found.font == path('Colus'), 'the late face is listed in its own face')
		local list = open(w)
		local n = 0
		for _, e in ipairs(list.entries) do if e.key == 'face:Late face' then n = n + 1 end end
		eq(n, 1, 'and in the list the row opens')
		W.CloseList()
	end)
end)

test('under Blizzard the link lights white and a disabled row shows the disabled dropdown art', function()
	in_look('blizzard', function(tip)
		local w = row_widget('header', 'heading')
		stub.fire_script(w.dots, 'OnEnter', true)
		eq(rgb(w.dots.icon:GetVertexColor()), rgb(1, 1, 1), 'white under the mouse')
		stub.fire_script(w.dots, 'OnLeave', true)
		w = row_widget('header', 'heading', nil, { disabled = function() return true end })
		eq(w.face.disabled, true)
		check(w.face:GetAlpha() == 1, 'no second dimming')
		local found = false
		for _, region in ipairs({ w.face:GetRegions() }) do
			if region.GetAtlas and region:GetAtlas() == 'common-dropdown-c-button-disabled' then found = true end
		end
		check(found, 'the face wears the disabled art')
	end)
end)

test('a malformed table on the row reads as Text and a pick writes a valid table', function()
	in_look('thick', function()
		for _, bad in ipairs({ { font_name = 5 }, { font_size = '12' }, {} }) do
			local w = row_widget('header', bad)
			eq(w.kind, 'typeface')
			eq(w.face.text:GetText(), st.defaults.fonts.normal.font_name, "the face reads Text's")
			w:Pick('face:Colus')
			local t = sets[1]
			eq(t.font_name, 'Colus')
			eq(type(t.font_size), 'number')
			eq(t.font_outline, st.defaults.fonts.normal.font_outline)
		end
	end)
end)

test('the link from a small dialog closes the dialog first', function()
	in_look('thick', function()
		fresh()
		st.Config:Open('FontLinkRows', 'texts')
		OW:OpenDialog('Fonts here', { type = 'group', name = 'Dialog', args = { header = FontRow('header', 1, nil, { name = 'Header font' }) } })
		check(OW:IsDialogShown(), 'the dialog is open')
		OW:Reveal({ 'Fonts', 'fonts', 'heading', 'font_name' })
		check(not OW:IsDialogShown(), 'Reveal closed it')
		eq(OW:GetState().page, 'Fonts')
		H.close_all()
	end)
end)

test('OW:Reveal from the bar grows the window to half before revealing', function()
	in_look('thick', function()
		st.Config:Open('FontLinkRows', 'texts')
		OW:SetWindowSize('half')
		OW:SetWindowSize('mini')
		eq(OW:GetWindowSize(), 'mini')
		OW:Reveal({ 'Fonts', 'fonts', 'heading', 'font_name' })
		eq(OW:GetWindowSize(), 'half')
		eq(OW:GetState().page, 'Fonts')
		H.close_all()
	end)
end)

------------------------------------------------------------------ the dots and their menu

local DOTS = st:NewModule('FontDotsRows')
local hideHeader, failHeader
function DOTS:GetConfigTable()
	return {
		name = 'Font dots rows', type = 'group', category = 'Frames',
		args = {
			texts = { order = 1, type = 'group', name = 'Texts', args = {
				header = FontRow('header', 1, nil, { name = 'Header font', hidden = function() return hideHeader end,
					validate = function() if failHeader then return 'Not that one.' end return true end }),
				tip = FontRow('tip', 2, { fields = { 'font_size', 'font_outline' } }, { name = 'Tooltip font' }),
				chat = FontRow('chat', 3, { fields = { 'font_size', 'font_outline', 'shadow_x', 'shadow_y' } }, { name = 'Chat font' }),
				hotkey = {
					order = 4, type = 'item', name = 'Hotkey', desc = 'The key.', size = 'small',
					get = function() return true end, set = function() end,
					menu = { type = 'group', name = 'Hotkey', args = {
						face = FontRow('face', 1, { faceOnly = true }, { name = 'Face' }),
					} },
				},
			} },
			other = { order = 2, type = 'group', name = 'Other', args = {
				plain = { type = 'toggle', name = 'Plain', desc = 'Plain.', get = function() return true end, set = function() end },
			} },
		},
	}
end

local PICK = st:NewModule('FontDotsPick')
function PICK:GetConfigTable()
	local function unit(name, key)
		return {
			name = name, type = 'group', childGroups = 'tab',
			args = { text = { order = 1, type = 'group', name = 'Text', args = {
				[key] = FontRow(key, 1, nil, { name = 'Font' }),
			} } },
		}
	end
	return {
		name = 'Font dots pick', type = 'group', category = 'Frames', childGroups = 'select',
		args = { a = unit('Unit A', 'fa'), b = unit('Unit B', 'fb') },
	}
end

local COLUS = { font_name = 'Colus', font_size = 15, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
local function colus()
	return { font_name = 'Colus', font_size = 15, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 4 }
end

local function open_dots()
	fresh()
	hideHeader, failHeader = nil, nil
	vals.header, vals.tip, vals.chat = colus(), colus(), colus()
	st.Config:Open('FontDotsRows', 'texts')
end
local function dots_of(key) return H.cell(key).widget.dots end
local function mcell(key)
	for _, c in ipairs(OW.GetMenuFrames().body.cells) do
		if c.row.key == key then return c end
	end
end
local function mkeys()
	local keys = {}
	for _, c in ipairs(OW.GetMenuFrames().body.cells) do keys[#keys + 1] = c.row.key end
	return keys
end
local function close_dots()
	st.Config:Close()
	H.close_all()
	stub.in_combat = nil
end

test('a typeface picked: the dots in the slot, grey, lit under the mouse (white under Blizzard); the tooltip names the face and the row', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function(tip)
			local w = row_widget('header', { font_name = 'Colus', font_size = 15 }, nil, { name = 'Header font' })
			eq(w.kind, 'typeface')
			check(w.dots:IsShown(), look .. ': the dots show')
			eq(w.dots.icon:GetTexture(), st.icons.ellipsisVertical, 'the ellipsis, not the link')
			eq(w.dots:GetWidth() .. 'x' .. w.dots:GetHeight(), '16x24')
			eq(rgb(w.dots.icon:GetVertexColor()), rgb(st.config.profile.colors.text.muted:GetRGB()), 'Text > Muted')
			stub.fire_script(w.dots, 'OnEnter', true)
			eq(rgb(w.dots.icon:GetVertexColor()), look == 'blizzard' and rgb(1, 1, 1) or rgb(st:StateColor('edgeHover')), 'lit under the mouse')
			eq(tip.owner, w.dots)
			eq(tip.lines[1], 'Size, outline, shadow and line spacing for Colus')
			eq(#tip.lines, 1, 'the title alone')
			stub.fire_script(w.dots, 'OnLeave', true)
			check(not tip.shown, 'and the tip goes')
			-- Back to a shared font: the link, with its own tooltip.
			w = row_widget('header', 'heading')
			eq(w.dots.icon:GetTexture(), st.icons.link)
		end)
	end
end)

test("the dots open the menu 'Header font: Colus': Size, Outline, Shadow offset X, Shadow offset Y, Line spacing, with the tab's ranges; a second click closes it", function()
	in_look('thick', function()
		open_dots()
		stub.click(dots_of('header'))
		check(OW:IsMenuShown(), 'the dots open it')
		check(OW:IsMenuShown(H.cell('header').widget), "it's the header row's")
		eq(OW.GetMenuFrames().title:GetText(), 'Header font: Colus')
		eq(table.concat(mkeys(), ','), 'font_size,font_outline,shadow_x,shadow_y,spacing')
		local names = {}
		for _, k in ipairs(mkeys()) do names[#names + 1] = mcell(k).row.name end
		eq(table.concat(names, ','), 'Size,Outline,Shadow offset X,Shadow offset Y,Line spacing')
		local menu = OW.GetMenuFrames().body.root.menu.args
		eq(menu.font_size.min .. '-' .. menu.font_size.max, '1-100')
		eq(menu.shadow_x.min .. '-' .. menu.shadow_x.max, '-5-5')
		eq(menu.shadow_y.min .. '-' .. menu.shadow_y.max, '-5-5')
		eq(menu.spacing.min .. '-' .. menu.spacing.max, '0-20')
		eq(menu.font_outline.sorting[1], 'NONE')
		eq(mcell('font_size').widget.edit:GetText(), '15', "the typeface's own size")
		local p, rel = OW.GetMenuFrames().frame:GetPoint(1)
		eq(rel, dots_of('header'), 'hung from the dots')
		stub.click(dots_of('header'))
		check(not OW:IsMenuShown(), 'a second click closes it')
		close_dots()
	end)
end)

test('fontFields: the tooltip row lists Size and Outline only, the chat row Size, Outline and both shadows', function()
	in_look('thick', function()
		open_dots()
		stub.click(dots_of('tip'))
		eq(table.concat(mkeys(), ','), 'font_size,font_outline')
		eq(OW.GetMenuFrames().title:GetText(), 'Tooltip font: Colus')
		stub.click(dots_of('chat'))
		eq(table.concat(mkeys(), ','), 'font_size,font_outline,shadow_x,shadow_y')
		close_dots()
	end)
end)

test("a menu change calls the row's set with a new table, the saved one unchanged; the page and the menu draw again", function()
	in_look('thick', function()
		open_dots()
		local saved = vals.header
		stub.click(dots_of('header'))
		local renders = OW.GetRenderCount()
		mcell('font_size').widget:Commit(22)
		eq(#sets, 1, 'one set')
		check(sets[1] ~= saved, 'a new table')
		eq(sets[1].font_size, 22)
		eq(sets[1].font_name, 'Colus')
		eq(saved.font_size, 15, 'the saved table is not edited')
		check(vals.header == sets[1], 'the row now holds the new one')
		check(OW.GetRenderCount() > renders, 'the page drew again')
		check(OW:IsMenuShown(), 'the menu is still open')
		eq(mcell('font_size').widget.edit:GetText(), '22', 'and shows the value')
		-- A shadow: a new offset table too.
		local before = vals.header
		mcell('shadow_y').widget:Commit(-2)
		eq(#sets, 2)
		eq(vals.header.shadow_offset[2], -2)
		eq(vals.header.shadow_offset[1], 0)
		check(vals.header.shadow_offset ~= before.shadow_offset, 'the offset is a new table')
		eq(before.shadow_offset[2], 0, 'the old one is not edited')
		mcell('font_outline').widget:Commit('OUTLINE')
		eq(vals.header.font_outline, 'OUTLINE')
		eq(vals.header.font_size, 22, 'the other fields stay')
		mcell('spacing').widget:Commit(7)
		eq(vals.header.spacing, 7)
		-- The row's own face is the same.
		eq(H.cell('header').widget.face.text:GetText(), 'Colus')
		close_dots()
	end)
end)

test('the value changing under an open menu (Review Focus 4)', function()
	in_look('thick', function()
		open_dots()
		take_errors()
		stub.click(dots_of('header'))
		local old = H.cell('header').widget:Menu()
		-- The row's reset (back to a shared font): the menu closes.
		vals.header = 'heading'
		OW:Render()
		check(not OW:IsMenuShown(), 'a shared font closes it')
		-- The old menu's rows write nothing now.
		local count = #sets
		old.args.font_size.set(nil, 30)
		eq(#sets, count, 'a stale menu writes nothing')
		eq(vals.header, 'heading')
		-- Another typeface replaces the table: the menu follows its face.
		vals.header = colus()
		OW:Render()
		stub.click(dots_of('header'))
		vals.header = { font_name = 'Bebas Neue', font_size = 9, font_outline = 'NONE', shadow_offset = { 1, 1 }, spacing = 2 }
		OW:Render()
		check(OW:IsMenuShown(), 'it follows')
		eq(OW.GetMenuFrames().title:GetText(), 'Header font: Bebas Neue')
		eq(mcell('font_size').widget.edit:GetText(), '9')
		-- Written through the new table, not the old.
		mcell('font_size').widget:Commit(11)
		eq(vals.header.font_name, 'Bebas Neue')
		eq(vals.header.font_size, 11)
		-- A profile switch: the other profile's value (a typeface) is followed, a shared one closes.
		vals.header = colus()
		OW:Render()
		eq(OW.GetMenuFrames().title:GetText(), 'Header font: Colus')
		vals.header = 'pixel'
		OW:Render()
		check(not OW:IsMenuShown(), 'a profile with a shared font closes it')
		-- The cell gone.
		vals.header = colus()
		OW:Render()
		stub.click(dots_of('header'))
		hideHeader = true
		OW:Render()
		check(not OW:IsMenuShown(), 'the row gone closes it')
		eq(#take_errors(), 0, 'no error on the way')
		close_dots()
	end)
end)

test('a drag across the range (Review Focus 5)', function()
	in_look('thick', function()
		open_dots()
		vals.header = { font_name = 'Colus', font_size = 15 }
		OW:Render()
		st:GetFont(vals.header) -- the object the row's reader made when it drew
		-- The row's set, as its module's: the look gets its object.
		local option = H.cell('header').row.option
		local plain = option.set
		option.set = function(info, value)
			plain(info, value)
			st:GetFont(value)
		end
		stub.click(dots_of('header'))
		local made, real = 0, CreateFont
		CreateFont = function(...) made = made + 1; return real(...) end
		local ok, err = pcall(function()
			local slider = mcell('font_size').widget
			stub.mouse_buttons.LeftButton = true
			slider.dragging = true
			local count = #sets
			for size = 16, 40 do
				slider:Commit(size)
				eq(#sets, count + 1, 'one set for size ' .. size)
				count = #sets
				slider = mcell('font_size').widget
				slider.dragging = true
			end
			eq(made, 25, 'a typeface object per size going up (16 to 40)')
			made = 0
			for size = 39, 15, -1 do
				slider:Commit(size)
				eq(#sets, count + 1)
				count = #sets
				slider = mcell('font_size').widget
				slider.dragging = true
			end
			eq(made, 0, 'none coming back')
			stub.mouse_buttons.LeftButton = nil
			slider.dragging = nil
		end)
		CreateFont = real
		stub.mouse_buttons.LeftButton = nil
		if not ok then error(err, 0) end
		close_dots()
	end)
end)

test('under Thick, Thin and Blizzard with a share on the row: the menu draws, follows its row, and closes on Esc, a click outside and navigation', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			open_dots()
			local share = {
				page = 'Bar 3', own = function() return true end, reset = function() end,
				source = 'All bars', shared = function() return 'Heading' end,
				targets = function() return { { key = 'bar2', label = 'Bar 2' } } end,
				applyAll = function() end, apply = function() end,
			}
			-- The share rides on the row the page draws: set it on the live option.
			local row = H.cell('header').row.option
			row.share = share
			OW:Render()
			local m = OW.GetMenuFrames()
			stub.click(dots_of('header'))
			check(OW:IsMenuShown(), look .. ': open')
			eq(#mkeys(), 5, 'five rows drawn')
			check(m.frame:GetHeight() > 100, 'with a height')
			-- Follows the row across a render and a tab back.
			OW:Render()
			check(OW:IsMenuShown() and select(2, m.frame:GetPoint(1)) == dots_of('header'), 'still hung from its dots')
			-- Esc.
			stub.fire_script(m.keys, 'OnKeyDown', 'ESCAPE')
			check(not OW:IsMenuShown(), 'Esc closes it')
			-- A click outside.
			stub.click(dots_of('header'))
			stub.fire_script(m.catcher, 'OnMouseDown', 'LeftButton')
			check(not OW:IsMenuShown(), 'a click outside closes it')
			-- Navigation.
			stub.click(dots_of('header'))
			OW:Navigate('FontDotsRows', { tab = 'other' })
			check(not OW:IsMenuShown(), 'a tab closes it')
			OW:Navigate('FontDotsRows', { tab = 'texts' })
			stub.click(dots_of('header'))
			OW:Navigate('Fonts')
			check(not OW:IsMenuShown(), 'a page closes it')
			close_dots()
		end)
	end
end)

test("a disabled row's dots take no mouse; in combat the menu does not open", function()
	in_look('thick', function()
		local w = row_widget('header', colus(), nil, { disabled = function() return true end })
		check(not w.dots:IsMouseEnabled(), 'a disabled row: no mouse on the dots')
		stub.click_unchecked(w.dots)
		check(not OW:IsMenuShown(), 'a click opens nothing')
		eq(OW:OpenMenu(w), false, 'OpenMenu refuses a disabled row')
		w:SetDisabled(false)
		check(w.dots:IsMouseEnabled(), 'enabled again')
		stub.in_combat = true
		eq(OW:OpenMenu(w), false, 'in combat')
		check(not OW:IsMenuShown())
		stub.in_combat = nil
		-- A row with no menu: a shared font.
		local shared = row_widget('header', 'heading')
		eq(shared:Menu(), nil, 'a shared font has no menu')
		eq(OW:OpenMenu(shared), false)
		-- A faceOnly row's typeface has none either.
		local face = row_widget('face', 'Colus', { faceOnly = true })
		eq(face:Menu(), nil)
		eq(OW:OpenMenu(face), false)
	end)
end)

test("search finds no row of a dots menu ('Size' matches only real Size rows)", function()
	fresh()
	vals.header = colus()
	local root = Page({
		header = FontRow('header', 1, nil, { name = 'Header font' }),
		size = { order = 2, type = 'range', name = 'Size', min = 1, max = 9, step = 1, desc = 'x', get = function() return 3 end, set = function() end },
	})
	local found = {}
	for _, r in ipairs(OM.Search(root, 'Size')) do found[#found + 1] = r.path[#r.path] end
	eq(table.concat(found, ','), 'size', 'only the real Size row')
	eq(#OM.Search(root, 'Shadow offset'), 0, 'no shadow row of a dots menu')
end)

test('a faceOnly row never shows dots, so no menu opens inside an item menu', function()
	in_look('thick', function()
		open_dots()
		vals.face = 'Colus'
		stub.click(H.cell('hotkey').widget.dots)
		check(OW:IsMenuShown(), "the item's menu is open")
		OW:Render()
		local c = mcell('face')
		check(c ~= nil and not c.widget.dots:IsShown(), 'its face-only typeface has no dots')
		eq(c.widget:Menu(), nil)
		close_dots()
	end)
end)

------------------------------------------------------------------ fix round 1

test("the dots' tooltip lists only what the row's menu shows", function()
	in_look('thick', function(tip)
		local function title(opts)
			local w = row_widget('header', colus(), opts)
			stub.fire_script(w.dots, 'OnEnter', true)
			local text = tip.lines[1]
			stub.fire_script(w.dots, 'OnLeave', true)
			return text
		end
		eq(title(nil), 'Size, outline, shadow and line spacing for Colus')
		eq(title({ fields = { 'font_size', 'font_outline', 'shadow_x', 'shadow_y' } }), 'Size, outline and shadow for Colus')
		eq(title({ fields = { 'font_size', 'font_outline' } }), 'Size and outline for Colus')
		eq(title({ fields = { 'font_size' } }), 'Size for Colus')
	end)
end)

local function three_rows()
	open_dots()
	vals.header = colus()
	vals.tip = { font_name = 'Homespun', font_size = 9, font_outline = 'THICKOUTLINE', shadow_offset = { 3, 3 }, spacing = 9 }
	vals.chat = { font_name = 'Bebas Neue', font_size = 30, font_outline = 'MONOCHROME', shadow_offset = { -2, -2 }, spacing = 1 }
	OW:Render()
end

local function menu_get(field)
	return OW.GetMenuFrames().body.root.menu.args[field].get()
end

test('a render under a busy menu: a held slider keeps reading and writing its own row (I1)', function()
	in_look('thick', function()
		three_rows()
		stub.click(dots_of('header'))
		local tip, chat = vals.tip, vals.chat
		local slider = mcell('font_size').widget
		stub.mouse_buttons.LeftButton = true
		slider.dragging = true
		slider:Commit(16)
		eq(vals.header.font_size, 16)
		for _ = 1, 3 do OW:Render() end
		slider = mcell('font_size').widget
		slider.dragging = true
		slider:Commit(17)
		eq(vals.header.font_size, 17, 'the next step lands on the header row')
		eq(menu_get('font_outline'), 'NONE', "the menu reads the header's outline, not another row's")
		eq(menu_get('shadow_x'), 0)
		check(vals.tip == tip and vals.chat == chat, 'no other row was written')
		stub.mouse_buttons.LeftButton = nil
		slider.dragging = nil
		close_dots()
	end)
end)

test('a render under a busy menu: a typed box keeps its row (I1)', function()
	in_look('thick', function()
		three_rows()
		stub.click(dots_of('header'))
		local box = mcell('font_size').widget.edit
		box:SetFocus()
		OW:Render()
		OW:Render()
		box:SetText('33')
		stub.fire_script(box, 'OnEnterPressed')
		eq(vals.header.font_size, 33, 'Enter lands on the header row')
		eq(vals.tip.font_size, 9)
		eq(vals.chat.font_size, 30)
		box:ClearFocus()
		close_dots()
	end)
end)

test('the unit picker changing with the menu open never writes the other unit (I1)', function()
	in_look('thick', function()
		fresh()
		vals.fa, vals.fb = colus(), { font_name = 'Homespun', font_size = 8 }
		st.Config:Open('FontDotsPick', 'a', 'text')
		stub.click(H.cell('fa').widget.dots)
		check(OW:IsMenuShown(), 'open on unit a')
		local held = H.cell('fa').widget:Menu()
		local b = vals.fb
		st.Config:Open('FontDotsPick', 'b', 'text')
		check(not OW:IsMenuShown(), 'the pick closed it')
		held.args.font_size.set(nil, 50)
		check(vals.fb == b, "unit b's value is untouched")
		eq(vals.fa.font_size, 15, "and so is a's: a closed menu's rows write nothing now")
		close_dots()
	end)
end)

test('the value turned shared or replaced under a busy menu: no write of the old table (m1)', function()
	in_look('thick', function()
		three_rows()
		stub.click(dots_of('header'))
		local box = mcell('font_size').widget.edit
		box:SetFocus()
		-- Busy: the render leaves its rows. The value became a shared font.
		vals.header = 'heading'
		OW:Render()
		check(OW:IsMenuShown() == false, 'a shared font closes it even while busy')
		box:ClearFocus()
		-- Direct: the menu's own write with the value changed and no render.
		vals.header = colus()
		OW:Render()
		stub.click(dots_of('header'))
		local count = #sets
		local menu = OW.GetMenuFrames().body.root.menu.args
		vals.header = 'pixel'
		menu.font_size.set(nil, 40)
		eq(#sets, count, 'no set for a value that is no longer a typeface')
		eq(vals.header, 'pixel')
		-- Replaced by another typeface: the write is a copy of that one.
		vals.header = { font_name = 'Bebas Neue', font_size = 9, font_outline = 'OUTLINE', shadow_offset = { 1, 2 }, spacing = 3 }
		local other = vals.header
		menu.font_size.set(nil, 41)
		eq(#sets, count + 1)
		eq(vals.header.font_name, 'Bebas Neue', "a copy of the table that is there now, not the one the menu was built from")
		eq(vals.header.font_outline, 'OUTLINE')
		eq(vals.header.shadow_offset[2], 2)
		eq(vals.header.font_size, 41)
		check(vals.header ~= other and other.font_size == 9, 'a new table')
		close_dots()
	end)
end)

test("FollowMenu closes at once, though busy, when its cell is gone or its widget has no menu (m2)", function()
	in_look('thick', function()
		three_rows()
		take_errors()
		-- Its cell gone while a list opened from the menu is open.
		stub.click(dots_of('header'))
		local outline = mcell('font_outline').widget
		stub.click(outline.face or outline.frame)
		hideHeader = true
		OW:Render()
		check(not OW:IsMenuShown(), 'the menu closed')
		eq(W.ListOwner(), nil, 'and its list with it')
		hideHeader = nil
		OW:Render()
		-- A box typed in, and the value shared.
		stub.click(dots_of('header'))
		local box = mcell('font_size').widget.edit
		box:SetFocus()
		vals.header = 'heading'
		OW:Render()
		check(not OW:IsMenuShown(), 'a shared font closes it, busy as it is')
		box:ClearFocus()
		eq(#take_errors(), 0)
		close_dots()
	end)
end)

test('a row disabled under an open menu closes the menu (m3)', function()
	in_look('thick', function()
		three_rows()
		stub.click(dots_of('header'))
		local row = H.cell('header').row.option
		row.disabled = function() return true end
		OW:Render()
		check(not OW:IsMenuShown(), 'the menu closed')
		row.disabled = nil
		close_dots()
	end)
end)

test('the typeface menu sits on whole pixels under Thick, Thin and Blizzard (m7)', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 0, 2 ^ -14, -2 ^ -14 }) do
			in_look(look, function()
				stub.size_noise = noise
				three_rows()
				stub.click(dots_of('header'))
				local off = P.off(OW.GetMenuFrames().frame)
				eq(#off, 0, look .. ', noise ' .. noise .. ': ' .. P.report(off))
				close_dots()
				stub.size_noise = 0
			end)
		end
	end
	stub.size_noise = 0
end)

test("a page row's failed validate is not honoured from the dots menu: nothing saved, no message (n1)", function()
	in_look('thick', function()
		three_rows()
		stub.click(dots_of('header'))
		local menu = OW.GetMenuFrames().body.root.menu.args
		local before, count = vals.header, #sets
		failHeader = true
		menu.font_size.set(nil, 40)
		eq(#sets, count, 'a refused value is not saved')
		eq(vals.header, before, 'the value is as it was')
		failHeader = nil
		menu.font_size.set(nil, 41)
		eq(vals.header.font_size, 41, 'with the validate passing the same write saves')
		eq(#take_errors(), 0, 'no errors')
		close_dots()
	end)
end)

test("the menu's read with no live widget gives Text's values (n2)", function()
	fresh()
	vals.header = colus()
	local body, by = draw(Page({ header = FontRow('header', 1, nil, { name = 'Header font' }) }))
	local group = by.header.widget:Menu()
	eq(group.args.font_size.get(), 15, 'with its row there: the typeface')
	body:Release()
	local text = st:FontFields('normal')
	eq(group.args.font_size.get(), text.font_size, "the body gone: Text's size, not nil")
	eq(group.args.font_outline.get(), text.font_outline, "and Text's outline")
	eq(group.args.shadow_x.get(), text.shadow_offset[1], "and Text's shadow")
	eq(group.args.spacing.get(), text.spacing, "and Text's spacing")
	eq(#take_errors(), 0, 'no errors')
end)

test('a refused face is tried again when a font row picks a face and when its list opens', function()
	in_look('thick', function()
		st.LSM:Register('font', 'Row retry face', 'Interface\\AddOns\\SomeAddon\\rowretry.ttf')
		local late, text = path('Row retry face'), path(st.defaults.fonts.normal.font_name)
		local look = { font_name = 'Row retry face', font_size = 12 }
		stub.refused_fonts[late] = true
		eq((st:FontValues(look)), text, 'refused: Text')
		stub.refused_fonts[late] = nil
		local w = row_widget('face', 'Homespun', {})
		w:Pick('face:Row retry face')
		eq((st:FontValues(look)), late, 'a pick asks again: it draws in its own face')

		st.LSM:Register('font', 'Row retry two', 'Interface\\AddOns\\SomeAddon\\rowretry2.ttf')
		local two = path('Row retry two')
		local look2 = { font_name = 'Row retry two', font_size = 12 }
		stub.refused_fonts[two] = true
		eq((st:FontValues(look2)), text, 'another face refused')
		stub.refused_fonts[two] = nil
		open(w)
		eq((st:FontValues(look2)), two, 'opening the list asks again')
		W.CloseList()
	end)
end)

------------------------------------------------------------------ a menu left anchored to a released widget

-- A font row's dots menu anchors the menu's frame to the row's dots, and the
-- frame keeps that anchor after the menu closes. The row's widget goes back to
-- its pool when the page changes; a later item menu draws a face-only font row
-- before it anchors itself again, and gets that very widget, so the row is
-- placed in a cell that hangs from the menu frame, which hangs from the
-- widget's own dots: a loop, which the game refuses.
local STALE = st:NewModule('FontStaleRows')
function STALE:GetConfigTable()
	return {
		name = 'Font stale rows', type = 'group', category = 'Frames',
		args = {
			texts = { order = 1, type = 'group', name = 'Texts', args = {
				header = FontRow('header', 1, nil, { name = 'Header font' }),
				tip = FontRow('tip', 2, nil, { name = 'Tooltip font' }),
				chat = FontRow('chat', 3, nil, { name = 'Chat font' }),
			} },
			other = { order = 2, type = 'group', name = 'Other', args = {
				hotkey = {
					order = 1, type = 'item', name = 'Hotkey', desc = 'The key.', size = 'small',
					get = function() return true end, set = function() end,
					menu = { type = 'group', name = 'Hotkey', args = {
						face = FontRow('face', 1, { faceOnly = true }, { name = 'Face' }),
					} },
				},
			} },
		},
	}
end

test("a font row's dots menu, the page changed, then an item menu with a face-only font row: the row is placed, no loop of anchors (bug 2)", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			fresh()
			vals.header, vals.tip, vals.chat = colus(), colus(), colus()
			vals.face = 'Homespun'
			st.Config:Open('FontStaleRows', 'texts')
			-- The last row's widget is the one the pool hands out first.
			local chat = H.cell('chat').widget
			stub.click(chat.dots)
			check(OW:IsMenuShown(), look .. ': the typeface menu is open')
			OW:Navigate('FontStaleRows', { tab = 'other' })
			check(not OW:IsMenuShown(), 'the page change closed it')
			stub.click(H.cell('hotkey').widget.dots)
			check(OW:IsMenuShown(), look .. ": the item's menu opens")
			local c = mcell('face')
			check(c ~= nil and c.widget.type == 'font', 'with its face-only font row')
			eq(c.widget.faceOnly, true)
			close_dots()
		end)
	end
end)

------------------------------------------------------------------ long names in the list

local LONG_NAMES = { 'AR CrystalzcuheiGBK Demibold', 'AR ZhongkaiGBK Medium (Combat)' }

-- What keeps an entry on its own row: its text never wraps, and what it draws
-- (a face taller than the row) is cut at the row, so it can't reach the rows
-- beside it. A font string wraps unless told not to; the stubs lay out one line
-- either way, so the setting is what is read, and the clip frame's place.
local function check_rows_hold(list, where)
	local shown = 0
	for i, row in ipairs(list.rows) do
		if row:IsShown() then
			shown = shown + 1
			local label = where .. ', row ' .. i
			eq(row.text:CanWordWrap(), false, label .. ': the text never wraps')
			check(row.clip ~= nil and row.clip:DoesClipChildren(), label .. ': a frame cuts what the text draws at the row')
			if row.clip then
				eq(row.clip:GetParent(), row, label .. ': the clip is the row\'s')
				eq(row.text:GetParent(), row.clip, label .. ': the text is a region of the clip frame, with no frame between')
				eq(row.view, nil)
				eq(row.clip:GetNumPoints(), 2, label .. ': the clip is anchored by two corners')
				for p = 1, 2 do
					local _, relative = row.clip:GetPoint(p)
					eq(relative, row, label .. ': both on the row')
				end
			end
		end
	end
	check(shown > 0, where .. ': rows are shown')
end

test('a font list with names too wide for it: every entry is one line, cut at its row, under Thick, Thin and Blizzard (bug 1)', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			for _, name in ipairs(LONG_NAMES) do st.LSM:Register('font', name, 'Fonts\\ARIALN.TTF') end
			local w = row_widget('header', 'Text')
			local list = open(w)
			-- Scroll to the long names: they sort among the typefaces.
			local found = {}
			for i, entry in ipairs(list.entries) do
				for _, name in ipairs(LONG_NAMES) do
					if entry.label == name then found[name] = i end
				end
			end
			for _, name in ipairs(LONG_NAMES) do check(found[name] ~= nil, look .. ': ' .. name .. ' is listed') end
			check_rows_hold(list, look .. ' top')
			stub.fire_script(list.frame, 'OnMouseWheel', -1)
			list.offset = found[LONG_NAMES[1]] - 1
			stub.fire_script(list.frame, 'OnMouseWheel', 0)
			check_rows_hold(list, look .. ' at the long names')
			local off = P.off(list.frame)
			eq(#off, 0, look .. ': whole pixels ' .. P.report(off))
			W.CloseList()
		end)
	end
end)

test('a plain select list with a long label is one line cut at its row too', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			fresh()
			vals.pick = 'a'
			local pick = {
				order = 1, type = 'select', name = 'Pick', desc = 'Pick one.',
				values = { a = 'Short', b = 'A label far too long for a list a hundred and seventy wide' },
				get = function() return vals.pick end, set = function(_, v) vals.pick = v end,
			}
			local _, by = draw(Page({ pick = pick }))
			stub.click(by.pick.widget.frame)
			local list = W.GetListFrames()
			check_rows_hold(list, look .. ' select')
			W.CloseList()
		end)
	end
end)

test('a list row whose text is cut shows the full name in a tooltip, and only then (M4)', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function(tip)
			for _, name in ipairs(LONG_NAMES) do st.LSM:Register('font', name, 'Fonts\\ARIALN.TTF') end
			local w = row_widget('header', 'Text')
			local list = open(w)
			local function row_of(label)
				for i = 1, #list.entries do
					if list.entries[i].label == label then
						list.offset = math.max(0, math.min(#list.entries - 12, i - 1))
						stub.fire_script(list.frame, 'OnMouseWheel', 0)
						for _, row in ipairs(list.rows) do
							if row:IsShown() and row.entry == list.entries[i] then return row end
						end
					end
				end
			end
			local long = row_of(LONG_NAMES[1]) -- the rows are shared: the next scroll refills this one
			check(long, look .. ': the long name is in a row')
			stub.fire_script(long, 'OnEnter', true)
			check(tip.shown and tip.owner == long, look .. ': a cut name has a tooltip')
			eq(tip.lines[1], LONG_NAMES[1], 'the full name')
			stub.fire_script(long, 'OnLeave', true)
			check(not tip.shown, look .. ': it goes when the mouse leaves')
			local short = row_of('Text')
			check(short, look .. ': a short name is in a row')
			stub.fire_script(short, 'OnEnter', true)
			check(not tip.shown, look .. ': a name that fits has none')
			stub.fire_script(short, 'OnLeave', true)
			-- A caption has none either.
			stub.fire_script(list.rows[1], 'OnEnter', true)
			check(not tip.shown, 'a caption has none')
			-- It does not outlive the list.
			long = row_of(LONG_NAMES[1])
			stub.fire_script(long, 'OnEnter', true)
			check(tip.shown, 'shown again')
			W.CloseList()
			check(not tip.shown, 'closing the list takes it down')
		end)
	end
end)

test("the select face that shows a typeface cuts what it draws at the face (M6)", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			local w = row_widget('header', { font_name = 'Colus', font_size = 15 }, nil, { name = 'Header font' })
			local face = w.face
			check(face.clip ~= nil and face.clip:DoesClipChildren(), look .. ': a clip frame')
			eq(face.text:GetParent(), face.clip, 'the text is on it')
			eq(face.text:CanWordWrap(), false, 'one line')
			for p = 1, 2 do
				local _, relative = face.clip:GetPoint(p)
				eq(relative, face, 'the clip lies on the face')
			end
		end)
	end
end)

------------------------------------------------------------------ each ClearAllPoints of the menu (M8)

test("the menu's frame has no points once it hides, whatever draws next (M8: OnHide's clear)", function()
	in_look('thick', function()
		open_dots()
		stub.click(dots_of('header'))
		check(OW.GetMenuFrames().frame:GetNumPoints() > 0, 'anchored while open')
		OW:CloseMenu()
		eq(OW.GetMenuFrames().frame:GetNumPoints(), 0, 'off its dots when it hides')
		close_dots()
	end)
end)

test("the menu's frame is off any old anchor when its rows are drawn (M8: Draw's clear)", function()
	in_look('thick', function()
		open_dots()
		stub.click(dots_of('header'))
		local M = OW.GetMenuFrames()
		OW:CloseMenu()
		-- A stale anchor, as Anchor leaves it on a pooled widget's dots (a TOPLEFT one would be replaced by
		-- Draw's own provisional point, hiding a missing clear).
		M.frame:SetPoint('TOPRIGHT', dots_of('tip'), 'BOTTOMRIGHT', 0, -4)
		local points, strays
		local body = M.body
		local draw = body.Draw
		body.Draw = function(self, ...)
			-- only the screen's provisional point (Draw's, for the rows' measuring), never the old anchor
			points, strays = M.frame:GetNumPoints(), 0
			for i = 1, points do
				local _, relative = M.frame:GetPoint(i)
				if relative ~= UIParent then strays = strays + 1 end
			end
			return draw(self, ...)
		end
		stub.click(dots_of('chat'))
		body.Draw = draw
		eq(points, 1, 'one point on the frame when the rows are drawn')
		eq(strays, 0, 'and it is the screen')
		close_dots()
	end)
end)

test("a scroll of the list takes a cut name's tooltip down, and the tooltip anchors to the right of its row (M-a, M-b)", function()
	in_look('thick', function(tip)
		for _, name in ipairs(LONG_NAMES) do st.LSM:Register('font', name, 'Fonts\\ARIALN.TTF') end
		local list = open(row_widget('header', 'Text'))
		local at
		for i, entry in ipairs(list.entries) do
			if entry.label == LONG_NAMES[1] then at = i end
		end
		list.offset = math.max(0, math.min(#list.entries - 12, at - 1))
		stub.fire_script(list.frame, 'OnMouseWheel', 0)
		local row
		for _, r in ipairs(list.rows) do
			if r:IsShown() and r.entry == list.entries[at] then row = r end
		end
		stub.fire_script(row, 'OnEnter', true)
		check(tip.shown, 'shown')
		eq(tip.anchor, 'ANCHOR_RIGHT', 'beside the list, not over its rows')
		stub.fire_script(list.frame, 'OnMouseWheel', 1)
		check(not tip.shown, 'a scroll takes it down: the row holds another entry now')
		W.CloseList()
	end)
end)

test('the plain select face is one line and cut at the box too (M-c)', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			fresh()
			vals.pick = 'a'
			local _, by = draw(Page({ pick = {
				order = 1, type = 'select', name = 'Pick', desc = 'Pick one.', values = { a = 'A label far too long for the face' },
				get = function() return vals.pick end, set = function() end,
			} }))
			local w = by.pick.widget
			eq(w.text:CanWordWrap(), false, look .. ': one line')
			check(w.frame.clip ~= nil and w.frame.clip:DoesClipChildren(), look .. ': cut at the box')
			eq(w.text:GetParent(), w.frame.clip)
		end)
	end
end)
