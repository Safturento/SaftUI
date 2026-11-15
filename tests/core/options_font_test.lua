-- The font row, SaftUI's own option type 'font' (SaftUI-Core/Config/
-- optionsfont.lua): a select face drawn in the face it names and one 16 by 24
-- slot, the link to the shared font's section of Global settings > Fonts
-- (OW:Reveal); its list (W.FontEntries and W.OpenList: SaftUI's fonts, then
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
		SetOwner = function(_, frame) tip.owner = frame end,
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
local function blue() return rgb(st.config.profile.colors.text.blue:GetRGB()) end
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
			check(not w.dots:IsShown(), where .. 'a typeface leaves the slot empty')
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

test('a typeface picked: the face reads its face in that face; the slot is empty', function()
	in_look('thick', function()
		local w = row_widget('header', { font_name = 'Homespun', font_size = 10, font_outline = 'NONE' })
		eq(w.kind, 'typeface')
		eq(w.face.text:GetText(), 'Homespun')
		local p, size = face_of(w.face.text)
		eq(p, path('Homespun'))
		eq(size, 15, 'at 15, whatever the text\'s own size')
		check(not w.dots:IsShown(), 'the slot is empty until the dots')
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
		eq(text_rgb(list.rows[1].text), rgb(st.config.profile.colors.text.grey:GetRGB()), 'in Text > Grey')
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

test('the picked entry is blue: the shared font, or the typeface by its face', function()
	in_look('thick', function()
		local w = row_widget('header', 'heading')
		local list = open(w)
		local normal = rgb(st.config.profile.colors.text.normal:GetRGB())
		eq(text_rgb(entry_row(list, 'heading').text), blue(), 'Heading is blue')
		eq(text_rgb(entry_row(list, 'subtitle').text), normal, 'Subtitle is not')
		W.CloseList()
		local names = st.LSM:List('font')
		w = row_widget('header', { font_name = names[3], font_size = 20 })
		list = open(w)
		eq(list.selected, 'face:' .. names[3])
		eq(text_rgb(entry_row(list, 'face:' .. names[3]).text), blue(), 'the typeface is blue')
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
		check(not w.dots:IsShown(), 'the slot is empty')

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
		check(not w.dots:IsShown(), 'the slot is empty')
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
		check(not w.dots:IsShown())
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
		eq(rgb(w.dots.icon:GetVertexColor()), blue(), 'the icon is lit under the mouse')
		stub.fire_script(w.dots, 'OnLeave', true)
		check(not tip.shown, 'and goes when the mouse leaves')
		eq(rgb(w.dots.icon:GetVertexColor()), rgb(st.config.profile.colors.text.grey:GetRGB()), 'back to Text > Grey')
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
		local default = FN.FontSettingDefault(function() return vals.header end, function(_, v) vals.header = v end, 'heading')
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
		eq(text_rgb(by.a.label), rgb(unpack(OB.OWN_TEXT)), 'the label is light blue')
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
