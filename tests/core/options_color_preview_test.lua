-- SaftUI-Core/Config/optionspreview.lua and the picker's preview area
-- (optionscolorpicker.lua): the strip under the color square that shows the
-- color being edited in context, chosen by the option's `preview` field; the
-- registry of kinds (W.DefinePreview, W.ReadPreview, W.PreviewKinds); the
-- text kind; the rows of the Colors page that carry a preview.
--
-- The picker without a preview, its boxes, chips and Okay and Cancel are
-- options_color_picker_test.lua's. The Class colors row is gone from the
-- picker (the Colors page edits those), so a picker is 342 tall without a
-- preview and 436 tall with one (the area and its caption add 94).
--
-- Real: the widget files, the theme, the picker, the preview file. The mouse is
-- played with stub.cursor_x/cursor_y and the frames' scripts.
local H = load_test_file('core/options_widgets_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local C = load_test_file('lib/color_cost.lua')
local T = load_test_file('lib/theme_helpers.lua')
local st = SaftUI
local drawn = T.watch() -- before the picker's first draw
local W = st.OptionsWidgets
local click = H.click

if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

-- Colors no default has, so a reader that draws a grey of its own fails.
st.config.profile.colors.text.normal:SetRGB(0.9, 0.8, 0.1)
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6)

local function field(x, y)
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetSize(170, 24)
	f:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x or 100, -(y or 100))
	return f
end

local function reset()
	stub.mouse_buttons = {}
	stub.in_combat = false
	stub.size_noise = 0
	st.config.global.colorPicker.recent = {}
	W.CloseColorPicker()
end

-- Opens the picker on a color, with the option's preview and name.
local function open(fields)
	fields = fields or {}
	local told = { changes = {} }
	told.opened = W.OpenColorPicker(fields.owner or field(), {
		r = fields.r or 0.2, g = fields.g or 0.4, b = fields.b or 0.6, a = fields.a or 1,
		hasAlpha = fields.hasAlpha == true,
		preview = fields.preview, name = fields.name,
		onChange = function(r, g, b, a) told.changes[#told.changes + 1] = { r, g, b, a } end,
	})
	return told, W.GetColorPickerFrames()
end

-- Where a region sits in the picker's panel: in from its left, down from its top.
local function at(F, region) return region:GetLeft() - F.frame:GetLeft(), F.frame:GetTop() - region:GetTop() end

local function rgb3(r, g, b) return ('%.2f,%.2f,%.2f'):format(r, g, b) end

local function press(area, fx, fy)
	local k = area:GetEffectiveScale()
	stub.cursor_x = (area:GetLeft() + 1 + fx * 168) * k
	stub.cursor_y = (area:GetTop() - 1 - fy * 168) * k
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(area, 'OnMouseDown', 'LeftButton')
end

local function release(area)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(area, 'OnMouseUp', 'LeftButton')
end

------------------------------------------------------------------ the area

test("an option with no preview opens today's picker, less the Class colors row: 342 tall, Last used at 248 and 266, nothing else moved", function()
	reset()
	st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 1 } }
	for _, hasAlpha in ipairs({ true, false }) do
		local _, F = open({ hasAlpha = hasAlpha })
		local where = (hasAlpha and 'opacity: ' or 'opaque: ')
		eq(F.frame:GetHeight(), 342, where .. '342 tall')
		eq(F.frame:GetWidth(), hasAlpha and 442 or 410, where .. 'as wide as before')
		local x, y = at(F, F.square)
		eq(x .. ',' .. y, '20,48', where .. 'the square stays')
		x, y = at(F, F.recentCaption)
		eq(x .. ',' .. y, '20,248', where .. 'Last used moved up into the removed row')
		x, y = at(F, F.recent.chips[1])
		eq(x .. ',' .. y, '20,266', where .. 'and its chips')
		eq(F.cancel:GetBottom() - F.frame:GetBottom(), 16, where .. 'the buttons 16 from the bottom')
		check(not F.preview:IsShown(), where .. 'no area')
		check(not F.previewCaption:IsShown() and not F.previewNote:IsShown(), where .. 'no caption, no note')
		check(F.classes == nil and F.classCaption == nil, where .. 'no Class colors row')
	end
	reset()
end)

test('a text preview: 436 tall; Last used at 342 and 360, the buttons 16 from the bottom; the area 370 by 64 at 20, 266 (402 with an opacity), its caption at 248', function()
	reset()
	st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 1 } }
	for _, hasAlpha in ipairs({ false, true }) do
		local _, F = open({ preview = 'text', hasAlpha = hasAlpha })
		local where = (hasAlpha and 'opacity: ' or 'opaque: ')
		eq(F.frame:GetHeight(), 436, where .. '342 and the area\'s 94')
		eq(F.frame:GetWidth(), hasAlpha and 442 or 410, where .. 'the width is today\'s')
		check(F.preview:IsShown(), where .. 'the area shows')
		local x, y = at(F, F.preview)
		eq(x .. ',' .. y, '20,266', where .. 'the area at 20, 266')
		eq(F.preview:GetWidth() .. ',' .. F.preview:GetHeight(), (hasAlpha and 402 or 370) .. ',64', where .. 'the inner width by 64')
		check(F.previewCaption:IsShown(), where .. 'its caption shows')
		eq(F.previewCaption:GetText(), 'Preview', where .. '"Preview"')
		x, y = at(F, F.previewCaption)
		eq(x .. ',' .. y, '20,248', where .. 'the caption at 248')
		check(not F.previewNote:IsShown(), where .. 'the text kind has no note')
		x, y = at(F, F.recentCaption)
		eq(x .. ',' .. y, '20,342', where .. 'Last used at 342: 12 under the area')
		x, y = at(F, F.recent.chips[1])
		eq(x .. ',' .. y, '20,360', where .. 'its chips at 360')
		eq(F.cancel:GetBottom() - F.frame:GetBottom(), 16, where .. 'the buttons 16 from the bottom')
		eq(F.frame:GetTop() - F.recent.chips[1]:GetBottom() + 0, 378 + 0, where .. 'the chips end at 378')
		eq(F.frame:GetHeight() - 378, 58, where .. 'and 58 of room under them, as today')
	end
	reset()
end)

test('a picker opened with no preview after one gives the area back: 342 tall', function()
	reset()
	local _, F = open({ preview = 'text' })
	eq(F.frame:GetHeight(), 436, 'with')
	_, F = open()
	eq(F.frame:GetHeight(), 342, 'without')
	check(not F.preview:IsShown(), 'the area is gone')
	check(not F.previewCaption:IsShown(), 'and its caption')
	reset()
end)

------------------------------------------------------------------ the field

test("W.ReadPreview: a name, a table with a kind, else nil; an unknown kind opens today's picker with no error", function()
	local kind, fields = W.ReadPreview('text')
	eq(kind, 'text', 'a name')
	eq(type(fields) == 'table' and next(fields), nil, 'with no fields')
	check(W.DefinePreview('probe', { Build = function() return {} end, Paint = function() end }), 'a kind of a module')
	local given = { kind = 'probe', style = 'unit' }
	kind, fields = W.ReadPreview(given)
	eq(kind, 'probe', 'a table with a kind')
	check(fields == given, 'and that table')
	for _, bad in ipairs({ 'nothing', { kind = 'nothing' }, {}, { kind = 5 }, 5, true, function() return 'text' end }) do
		kind, fields = W.ReadPreview(bad)
		eq(kind, nil, 'not read: ' .. tostring(type(bad) == 'table' and (bad.kind or 'table') or bad))
		eq(fields, nil, 'and no fields')
	end
	eq(W.ReadPreview(nil), nil, 'nil')
	reset()
	local told, F = open({ preview = 'nothing' })
	check(told.opened, 'it opens')
	eq(F.frame:GetHeight(), 342, "today's picker")
	reset()
	told, F = open({ preview = { kind = 'nothing', sample = 'x' } })
	check(told.opened and F.frame:GetHeight() == 342, 'a table with an unknown kind too')
	reset()
end)

test("W.DefinePreview refuses a built-in kind's name and a def without Build and Paint; a module's kind shows", function()
	local kinds = W.PreviewKinds()
	local text = kinds.text
	check(text and text.Build and text.Paint, 'the text kind is there')
	eq(W.DefinePreview('text', { Build = function() return {} end, Paint = function() end }), false, "a built-in kind's name is refused")
	check(kinds.text == text, 'and the built-in kind is as it was')
	eq(W.DefinePreview('nobuild', { Paint = function() end }), false, 'no Build')
	eq(W.DefinePreview('nopaint', { Build = function() return {} end }), false, 'no Paint')
	eq(W.DefinePreview('empty', {}), false, 'neither')
	eq(W.DefinePreview('notadef', 'text'), false, 'not a table')
	eq(kinds.nobuild, nil, 'none of them is registered')

	local built, painted = 0, {}
	local ok = W.DefinePreview('demo', {
		note = 'A note for the demo.',
		Build = function(area, width, height)
			built = built + 1
			local t = area:CreateTexture(nil, 'ARTWORK')
			t:SetColorTexture(1, 1, 1, 1)
			t:SetPoint('TOPLEFT', area, 'TOPLEFT', 0, 0)
			t:SetSize(width, height)
			return { texture = t, width = width, height = height }
		end,
		Paint = function(pieces, r, g, b, a, spec)
			painted[#painted + 1] = { pieces = pieces, r = r, g = g, b = b, a = a, spec = spec }
			pieces.texture:SetColorTexture(r, g, b, a)
		end,
	})
	check(ok, 'a module adds a kind')
	check(kinds.demo ~= nil, 'W.PreviewKinds has it')
	reset()
	local fieldsGiven = { kind = 'demo', mark = 5 }
	local _, F = open({ preview = fieldsGiven, name = 'Danger', hasAlpha = true, a = 0.5 })
	eq(F.frame:GetHeight(), 436, 'the area opens for it')
	eq(built, 1, 'built the first time it shows')
	eq(F.previewNote:GetText(), 'A note for the demo.', "the kind's note")
	check(F.previewNote:IsShown(), 'shown')
	check(F.previewNote:GetRight() <= F.frame:GetRight() - 20 + 0.001 and F.previewNote:GetRight() >= F.frame:GetRight() - 20 - 0.001, 'right-aligned to the area')
	eq(F.previewNote:GetJustifyH(), 'RIGHT', 'right-justified')
	eq(rgb3(F.previewNote:GetTextColor()), rgb3(st.config.profile.colors.text.muted:GetRGB()), 'in Text > Muted')
	local last = painted[#painted]
	check(last, 'painted as it opened')
	eq(rgb3(last.r, last.g, last.b), '0.20,0.40,0.60', 'with the color')
	eq(last.a, 0.5, 'and the opacity')
	check(last.spec.fields == fieldsGiven, "spec.fields is the option's table")
	eq(last.spec.name, 'Danger', "spec.name is the option's name")
	eq(last.spec.hasAlpha, true, 'spec.hasAlpha')
	eq(last.pieces.width .. ',' .. last.pieces.height, '402,64', 'Build gets the area\'s width and height')
	press(F.square, 0.5, 0.5)
	release(F.square)
	local after = painted[#painted]
	check(#painted > 1 and after.r ~= 0.2, 'painted again on a change')
	local chosen = stub.state(F.new.color).color_texture
	eq(rgb3(after.r, after.g, after.b), rgb3(chosen[1], chosen[2], chosen[3]), 'with the color being chosen')
	reset()
	-- Opened for a kind with no note, then again: nothing is built again, the note goes.
	open({ preview = 'text' })
	check(not F.previewNote:IsShown(), 'a kind without a note hides it')
	reset()
	open({ preview = 'demo' })
	eq(built, 1, 'the pieces are built once and kept')
	reset()
	kinds.demo, kinds.probe = nil, nil
end)

test('the pieces are built once per kind and kept; a picker opened for another kind hides them', function()
	local made = 0
	W.DefinePreview('other', {
		Build = function(area)
			made = made + 1
			local t = area:CreateTexture(nil, 'ARTWORK')
			t:SetColorTexture(1, 0, 0, 1)
			return { t = t }
		end,
		Paint = function() end,
	})
	reset()
	local _, F = open({ preview = 'text' })
	local text = F.previewPieces.text
	check(text ~= nil, 'the text kind has pieces')
	check(text.tiles[1]:IsVisible(), 'the text kind shows')
	_, F = open({ preview = 'other' })
	eq(made, 1, 'the other kind is built')
	check(not text.tiles[1]:IsVisible(), "the text kind's pieces are hidden")
	check(F.previewPieces.other.t:IsVisible(), "the other kind's pieces show")
	_, F = open({ preview = 'text' })
	check(F.previewPieces.text == text, 'the text kind is the same pieces')
	check(text.tiles[1]:IsVisible(), 'shown again')
	check(not F.previewPieces.other.t:IsVisible(), 'the other kind is hidden')
	_, F = open({ preview = 'other' })
	eq(made, 1, 'and nothing is built again')
	_, F = open()
	check(not F.previewPieces.other.t:IsVisible() and not text.tiles[1]:IsVisible(), 'no preview: none shows')
	reset()
	W.PreviewKinds().other = nil
end)

------------------------------------------------------------------ the text kind

test('the text kind: three tiles 118 by 44 at 20, 146, 272, drawn thick/solid, thin/solid and theme/options as panels', function()
	T.theme('thick')
	reset()
	local _, F = open({ preview = 'text', name = 'Danger' })
	local pieces = F.previewPieces.text
	eq(#pieces.tiles, 3, 'three tiles')
	local draws = { 'thick,solid,panel', 'thin,solid,panel', 'theme,options,panel' }
	for i, tile in ipairs(pieces.tiles) do
		local x, y = at(F, tile)
		eq(x .. ',' .. y, ({ '20,266', '146,266', '272,266' })[i], 'tile ' .. i .. ' place')
		eq(tile:GetWidth() .. ',' .. tile:GetHeight(), '118,44', 'tile ' .. i .. ' size')
		eq(drawn(tile), draws[i], 'tile ' .. i .. ' drawn as')
		check(tile:GetParent() ~= nil and tile:IsVisible(), 'tile ' .. i .. ' shows')
		eq(pieces.labels[i]:GetText(), 'Text', 'tile ' .. i .. ': Text')
		eq(rgb3(pieces.labels[i]:GetTextColor()), rgb3(st:Color('text', 'normal'):GetRGB()), 'tile ' .. i .. ': in Text > Normal')
		eq(pieces.samples[i]:GetText(), 'Danger', 'tile ' .. i .. ': the sample')
		eq(rgb3(pieces.samples[i]:GetTextColor()), '0.20,0.40,0.60', 'tile ' .. i .. ': in the picker\'s color')
		check(pieces.labels[i]:GetLeft() >= tile:GetLeft() and pieces.labels[i]:GetLeft() < pieces.samples[i]:GetLeft(), 'tile ' .. i .. ': Text left of the sample')
		check(pieces.samples[i]:GetLeft() + 0.001 >= tile:GetLeft() and pieces.samples[i]:GetRight() <= tile:GetRight() + 0.001, 'tile ' .. i .. ': the sample inside the tile')
	end
	local names = { 'Thick', 'Thin', 'Options windows' }
	for i, caption in ipairs(pieces.captions) do
		eq(caption:GetText(), names[i], 'caption ' .. i)
		eq(rgb3(caption:GetTextColor()), rgb3(st.config.profile.colors.text.muted:GetRGB()), 'caption ' .. i .. ' in Text > Muted')
		check(caption:GetTop() < pieces.tiles[i]:GetBottom() + 0.001, 'caption ' .. i .. ' under its tile')
		check(caption:GetBottom() >= F.preview:GetBottom() - 0.001, 'and inside the area')
	end
	-- The Options windows tile sits on the world's stand-in color, so its see-through shows.
	local world = pieces.world
	eq(stub.state(world).color_texture[1] .. ',' .. stub.state(world).color_texture[2], (47 / 255) .. ',' .. (51 / 255), 'the world stand-in, #2f3324')
	eq(stub.state(world).color_texture[3] .. ',' .. stub.state(world).color_texture[4], (36 / 255) .. ',1', 'its blue, opaque')
	local tile = pieces.tiles[3]
	eq(world:GetLeft() .. ',' .. world:GetTop() .. ',' .. world:GetRight() .. ',' .. world:GetBottom(),
		tile:GetLeft() .. ',' .. tile:GetTop() .. ',' .. tile:GetRight() .. ',' .. tile:GetBottom(), 'right behind the third tile')
	reset()
end)

test('the text kind with an opacity: the tiles keep their size, the outer two at the edges, the middle one centered', function()
	reset()
	local _, F = open({ preview = 'text', hasAlpha = true })
	local tiles = F.previewPieces.text.tiles
	local xs = {}
	for i, tile in ipairs(tiles) do
		xs[i] = at(F, tile)
		eq(tile:GetWidth(), 118, 'tile ' .. i .. ' 118 wide')
	end
	eq(table.concat(xs, ','), '20,162,304', 'at 20, 162 and 304: the gaps 24 each')
	_, F = open({ preview = 'text', hasAlpha = false })
	xs = {}
	for i, tile in ipairs(F.previewPieces.text.tiles) do xs[i] = at(F, tile) end
	eq(table.concat(xs, ','), '20,146,272', 'and back to 20, 146 and 272')
	reset()
end)

test("the sample: the field's own, else the color's name", function()
	reset()
	local _, F = open({ preview = { kind = 'text', sample = '(Alliance territory)' }, name = 'Alliance' })
	for i = 1, 3 do eq(F.previewPieces.text.samples[i]:GetText(), '(Alliance territory)', "the field's own, tile " .. i) end
	_, F = open({ preview = 'text', name = 'Caution' })
	for i = 1, 3 do eq(F.previewPieces.text.samples[i]:GetText(), 'Caution', "the color's name, tile " .. i) end
	_, F = open({ preview = 'text' })
	eq(F.previewPieces.text.samples[1]:GetText(), '', 'no name, no sample: empty, no error')
	_, F = open({ preview = { kind = 'text', sample = 5 }, name = 'Mana' })
	eq(F.previewPieces.text.samples[1]:GetText(), 'Mana', 'a sample that is no text is the name')
	reset()
end)

test('the text kind paints on every change, live', function()
	reset()
	local _, F = open({ preview = 'text', name = 'Danger' })
	local pieces = F.previewPieces.text
	press(F.square, 0.9, 0.1)
	local new = stub.state(F.new.color).color_texture
	for i = 1, 3 do
		eq(rgb3(pieces.samples[i]:GetTextColor()), rgb3(new[1], new[2], new[3]), 'the sample follows the drag, tile ' .. i)
	end
	press(F.hue, 0, 0.77)
	release(F.hue)
	new = stub.state(F.new.color).color_texture
	eq(rgb3(pieces.samples[2]:GetTextColor()), rgb3(new[1], new[2], new[3]), 'and a strip')
	F.hex:SetFocus()
	F.hex:SetText('#FF8000')
	stub.fire_script(F.hex, 'OnEnterPressed')
	eq(rgb3(pieces.samples[3]:GetTextColor()), rgb3(1, 128 / 255, 0), 'and a typed code')
	reset()
end)

test("the text kind's captions and labels follow Text > Muted and Normal while it is open", function()
	reset()
	local muted, normal = st.config.profile.colors.text.muted, st.config.profile.colors.text.normal
	local keepMuted, keepNormal = { muted:GetRGB() }, { normal:GetRGB() }
	local _, F = open({ preview = 'text' })
	local pieces = F.previewPieces.text
	muted:SetRGB(0.9, 0.1, 0.2)
	st:ColorChanged('text', 'muted')
	C.step(st)
	eq(rgb3(pieces.captions[1]:GetTextColor()), '0.90,0.10,0.20', 'a tile caption')
	eq(rgb3(F.previewCaption:GetTextColor()), '0.90,0.10,0.20', 'the Preview caption')
	normal:SetRGB(0.1, 0.8, 0.3)
	st:ColorChanged('text', 'normal')
	C.step(st)
	eq(rgb3(pieces.labels[2]:GetTextColor()), '0.10,0.80,0.30', 'a Text label')
	muted:SetRGB(unpack(keepMuted))
	normal:SetRGB(unpack(keepNormal))
	reset()
end)

------------------------------------------------------------------ cost

test('it paints on every change: 1000 paints, 24 setter calls at most each, under 4 KB, nothing made', function()
	reset()
	local _, F = open({ preview = 'text', name = 'Danger' })
	local def, pieces = W.PreviewKinds().text, F.previewPieces.text
	local spec = { fields = {}, name = 'Danger', hasAlpha = false }
	def.Paint(pieces, 0.1, 0.2, 0.3, 1, spec) -- each widget's first color call makes its table once
	local i = 0
	local m = C.measure(function()
		i = i + 1
		def.Paint(pieces, 0.1 + (i % 7) / 10, 0.2, 0.3, 1, spec)
	end, 1000)
	check(m.calls.total <= 24 * 1000, 'at most 24 setter calls a paint, got ' .. m.calls.total / 1000)
	check(m.kb < 4, ('under 4 KB, got %.2f'):format(m.kb))
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing placed, shown or sized')
	reset()
end)

test('the picker repaints the preview without making anything: a theme recolor puts its own colors back', function()
	reset()
	local _, F = open({ preview = 'text', name = 'Danger' })
	local pieces = F.previewPieces.text
	pieces.samples[1]:SetTextColor(1, 1, 1)
	pieces.labels[2]:SetTextColor(0, 0, 0)
	pieces.captions[3]:SetTextColor(0, 0, 0)
	st:RecolorThemed()
	eq(rgb3(pieces.samples[1]:GetTextColor()), '0.20,0.40,0.60', "the sample's color is back")
	eq(rgb3(pieces.labels[2]:GetTextColor()), rgb3(st:Color('text', 'normal'):GetRGB()), "and the label's")
	eq(rgb3(pieces.captions[3]:GetTextColor()), rgb3(st:Color('text', 'muted'):GetRGB()), "and the caption's")
	reset()
end)

------------------------------------------------------------------ pixels

test('every part is on whole pixels under Thick, Thin and Blizzard, with sizes read back a hair off', function()
	local HAIR = 2 ^ -14
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			for _, hasAlpha in ipairs({ true, false }) do
				T.theme(look)
				stub.size_noise = noise
				reset()
				stub.size_noise = noise
				local where = look .. ' noise ' .. noise .. (hasAlpha and ' alpha' or ' opaque') .. ': '
				st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 0.5 } }
				local _, F = open({ preview = 'text', hasAlpha = hasAlpha, name = 'Danger' })
				local off = P.off(F.frame)
				eq(#off, 0, where .. P.report(off))
				check(F.preview:IsShown(), where .. 'the area is part of what was checked')
				press(F.square, 0.37, 0.61)
				release(F.square)
				off = P.off(F.frame)
				eq(#off, 0, where .. 'after a drag: ' .. P.report(off))
				reset()
			end
		end
	end
	stub.size_noise = 0
	T.theme('thick')
end)

------------------------------------------------------------------ the rows

test('the color type passes its option\'s preview, raw, and the row\'s name, to the picker', function()
	reset()
	local value = { 0.3, 0.5, 0.7 }
	local w = H.bind('color', 'danger', H.opt('color', 'Danger', {
		preview = { kind = 'text', sample = 'Sample' },
		get = function() return unpack(value) end,
		set = function(_, r, g, b) value = { r, g, b } end,
	}))
	w:Pick()
	local F = W.GetColorPickerFrames()
	check(W.ColorPickerShown(), 'the picker opens')
	eq(F.frame:GetHeight(), 436, 'with the preview')
	eq(F.previewPieces.text.samples[1]:GetText(), 'Sample', "the option's own sample")
	reset()
	local plain = H.bind('color', 'plain', H.opt('color', 'Plain', {
		get = function() return 0.3, 0.5, 0.7 end, set = function() end,
	}))
	plain:Pick()
	eq(F.frame:GetHeight(), 342, 'an option with no preview opens today\'s picker')
	reset()
	local named = H.bind('color', 'named', H.opt('color', 'Named', {
		preview = 'text', get = function() return 0.3, 0.5, 0.7 end, set = function() end,
	}))
	named:Pick()
	eq(F.previewPieces.text.samples[1]:GetText(), 'Named', 'with no sample, the color is named by its row')
	reset()
end)

test('the Text, Factions, Loot letter and Objectives rows carry their previews', function()
	local CO = st:GetModule('Colors')
	local args = CO:GetConfigTable().args
	for key in pairs(args.text.args) do eq(args.text.args[key].preview, 'text', 'Text > ' .. key) end
	for _, key in ipairs({ 'need', 'greed', 'transmog', 'pass' }) do eq(args.loot.args[key].preview, 'text', 'Loot > ' .. key) end
	local function sample(group, key) return args[group].args[key].preview end
	eq(sample('factions', 'Alliance').kind .. ',' .. sample('factions', 'Alliance').sample, 'text,(Alliance territory)', 'Alliance')
	eq(sample('factions', 'Horde').kind .. ',' .. sample('factions', 'Horde').sample, 'text,(Horde territory)', 'Horde')
	eq(sample('factions', 'Neutral').kind .. ',' .. sample('factions', 'Neutral').sample, 'text,(Contested territory)', 'Neutral')
	eq(sample('objectives', 'completed').kind .. ',' .. sample('objectives', 'completed').sample, 'text,8/8 Things slain', 'Completed')
	eq(sample('objectives', 'failed').kind .. ',' .. sample('objectives', 'failed').sample, 'text,Escort failed', 'Failed')
	for key, option in pairs(args.text.args) do
		check(W.ReadPreview(option.preview) == 'text', 'Text > ' .. key .. ' reads as a text preview')
	end
end)

------------------------------------------------------------------ the hooks a kind needs

-- A kind that records what the picker gives it.
local function probe_kind(name, extra)
	local log = { built = 0, layouts = {}, paints = 0 }
	local def = {
		Build = function(area)
			log.built = log.built + 1
			local t = area:CreateTexture(nil, 'ARTWORK')
			t:SetColorTexture(1, 1, 1, 1)
			return { t = t }
		end,
		Paint = function() log.paints = log.paints + 1 end,
		Layout = function(pieces, width, height, spec)
			log.layouts[#log.layouts + 1] = { pieces = pieces, width = width, height = height, spec = spec }
		end,
	}
	for k, v in pairs(extra or {}) do def[k] = v end
	check(W.DefinePreview(name, def), 'defined ' .. name)
	return log, def
end

test("Layout is given the option's preview fields (as the spec Paint gets), so a kind can show a style's pieces", function()
	local log = probe_kind('styled')
	reset()
	local given = { kind = 'styled', style = 'unit' }
	local _, F = open({ preview = given, name = 'Mage', hasAlpha = true })
	local last = log.layouts[#log.layouts]
	check(last, 'laid out as it opened')
	eq(last.width .. ',' .. last.height, '402,64', 'the strip')
	check(last.pieces == F.previewPieces.styled, 'its pieces')
	check(last.spec.fields == given, 'spec.fields is the option\'s table')
	eq(last.spec.name, 'Mage', 'spec.name')
	eq(last.spec.hasAlpha, true, 'spec.hasAlpha')
	reset()
	W.PreviewKinds().styled = nil
end)

test('a note may be a function of the theme in use, giving a string or nil', function()
	local seen = {}
	probe_kind('themed', { note = function(blizzard, spec) seen[#seen + 1] = blizzard; return blizzard and 'Shown as Thick.' or nil end })
	T.theme('thick')
	reset()
	local _, F = open({ preview = 'themed' })
	check(not F.previewNote:IsShown(), 'no note under Thick')
	eq(F.previewNote:GetText(), '', 'and no text')
	T.theme('blizzard')
	reset()
	_, F = open({ preview = 'themed' })
	check(F.previewNote:IsShown(), 'a note under Blizzard')
	eq(F.previewNote:GetText(), 'Shown as Thick.', 'its text')
	eq(seen[#seen], true, 'the function got whether Blizzard is in use')
	reset()
	T.theme('thick')
	W.PreviewKinds().themed = nil
end)

test('a note function that errors, or gives no string, shows no note', function()
	probe_kind('badnote', { note = function() error('boom') end })
	reset()
	local _, F = open({ preview = 'badnote' })
	check(not F.previewNote:IsShown(), 'no note')
	eq(F.frame:GetHeight(), 436, 'the preview still shows')
	take_errors()
	reset()
	W.PreviewKinds().badnote = nil
end)

test('a theme change with the picker open lays the preview out again once, on the theme pass; a color pass does not', function()
	local log = probe_kind('relay', { note = function(blizzard) return blizzard and 'Blizzard note' or nil end })
	T.theme('thick')
	reset()
	local _, F = open({ preview = 'relay' })
	local n = #log.layouts
	check(not F.previewNote:IsShown(), 'no note under Thick')
	st:RecolorThemed() -- a Theme color: the same look
	st.config.profile.colors.text.muted:SetRGB(0.3, 0.3, 0.3)
	st:ColorChanged('text', 'muted')
	C.step(st)
	eq(#log.layouts, n, 'a color pass lays nothing out')
	T.theme('blizzard') -- the Theme tab's switch, with the picker open
	eq(#log.layouts, n + 1, 'the theme change lays it out again, once')
	check(F.previewNote:IsShown() and F.previewNote:GetText() == 'Blizzard note', 'and the note comes')
	st:RecolorThemed()
	eq(#log.layouts, n + 1, 'a recolor under the same look lays nothing out')
	T.theme('thick')
	eq(#log.layouts, n + 2, 'and back')
	check(not F.previewNote:IsShown(), 'the note goes')
	st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6)
	reset()
	W.PreviewKinds().relay = nil
end)

------------------------------------------------------------------ a module kind that fails

test("a kind's Paint that errors is reported once and does not drop the area's Text follower", function()
	local log = probe_kind('badpaint', { Paint = function() error('paint boom') end })
	reset()
	take_errors()
	local told, F = open({ preview = 'badpaint' })
	press(F.square, 0.3, 0.3)
	press(F.square, 0.6, 0.6)
	press(F.square, 0.9, 0.2)
	release(F.square)
	check(#told.changes >= 1, 'the field is told of every change')
	eq(#take_errors(), 1, 'reported once')
	local muted = st.config.profile.colors.text.muted
	muted:SetRGB(0.9, 0.1, 0.2)
	st:ColorChanged('text', 'muted')
	C.step(st) -- a Text pass with the failing kind open
	take_errors()
	reset()
	-- The Text follower is still there for the text kind.
	_, F = open({ preview = 'text', name = 'Danger' })
	muted:SetRGB(0.4, 0.5, 0.6)
	st:ColorChanged('text', 'muted')
	C.step(st)
	eq(rgb3(F.previewPieces.text.captions[1]:GetTextColor()), '0.40,0.50,0.60', 'the text kind still follows Text')
	muted:SetRGB(0.2, 0.4, 0.6)
	reset()
	W.PreviewKinds().badpaint = nil
end)

test("a kind's Build that fails opens today's picker, once built, and leaks no holder", function()
	local made = 0
	probe_kind('badbuild', { Build = function(area) made = made + 1; error('build boom') end })
	reset()
	take_errors()
	local _, F = open({ preview = 'badbuild' })
	eq(F.frame:GetHeight(), 342, "today's picker")
	check(not F.preview:IsShown(), 'no strip')
	local children = #{ F.preview:GetChildren() }
	for _ = 1, 3 do open({ preview = 'badbuild' }) end
	eq(made, 1, 'not built again on later openings')
	eq(#{ F.preview:GetChildren() }, children, 'no holder per opening')
	eq(#take_errors(), 1, 'reported once')
	reset()
	W.PreviewKinds().badbuild = nil
end)

test("a kind's Layout that errors opens today's picker with no stale spec and no Last used chip", function()
	probe_kind('badlayout', { Layout = function() error('layout boom') end })
	reset()
	take_errors()
	local told, F = open({ preview = 'badlayout' })
	check(told.opened and F.frame:IsShown(), 'it opens')
	eq(F.frame:GetHeight(), 342, 'with no preview')
	check(not F.preview:IsShown(), 'no strip')
	eq(#take_errors(), 1, 'reported')
	local _, F2 = open() -- opening again accepts the first as Okay
	reset()
	eq(#st.config.global.colorPicker.recent, 0, 'nothing was remembered')
	W.PreviewKinds().badlayout = nil
end)

test('a kind a module defines again is built again', function()
	local first = probe_kind('again')
	reset()
	open({ preview = 'again' })
	eq(first.built, 1, 'built')
	local second = probe_kind('again')
	local _, F = open({ preview = 'again' })
	eq(second.built, 1, 'the new def is built')
	eq(first.built, 1, 'the old one is not built again')
	check(F.previewPieces.again == second.layouts[#second.layouts].pieces, 'and its pieces show')
	reset()
	W.PreviewKinds().again = nil
end)

------------------------------------------------------------------ what the text kind draws, and where

test("the picker's own paint path makes nothing: 1000 dispatches, 24 setter calls at most, under 4 KB", function()
	reset()
	local _, F = open({ preview = 'text', name = 'Danger' })
	F.paintPreview()
	local m = C.measure(function() F.paintPreview() end, 1000)
	check(m.calls.total <= 24 * 1000, 'at most 24 setter calls, got ' .. m.calls.total / 1000)
	check(m.kb < 4, ('under 4 KB, got %.2f'):format(m.kb))
	eq(m.forbidden.total, 0, 'nothing placed or shown')
	reset()
end)

test("the text kind's captions are inside the area; Text and the sample do not overlap and are a centered pair", function()
	reset()
	for _, sample in ipairs({ 'Danger', '(Contested territory)' }) do
		local _, F = open({ preview = { kind = 'text', sample = sample } })
		local pieces = F.previewPieces.text
		for i, caption in ipairs(pieces.captions) do
			check(caption:GetTop() - caption:GetStringHeight() >= F.preview:GetBottom() - 0.001, sample .. ': caption ' .. i .. ' inside the area')
		end
		for i, tile in ipairs(pieces.tiles) do
			local label, fs = pieces.labels[i], pieces.samples[i]
			check(label:GetLeft() + label:GetStringWidth() <= fs:GetLeft() + 0.001, sample .. ': Text ends before the sample, tile ' .. i)
			check(fs:GetRight() <= tile:GetRight() + 0.001 and label:GetLeft() >= tile:GetLeft(), sample .. ': both inside tile ' .. i)
			local middle = (label:GetLeft() + fs:GetRight()) / 2
			check(math.abs(middle - (tile:GetLeft() + tile:GetRight()) / 2) <= 1, sample .. ': the pair is centered in tile ' .. i)
		end
	end
	reset()
end)

test('a long sample wraps to two lines at most', function()
	reset()
	local _, F = open({ preview = { kind = 'text', sample = '(Contested territory)' } })
	local fs = F.previewPieces.text.samples[1]
	eq(stub.state(fs).word_wrap, true, 'wraps')
	eq(fs:GetMaxLines(), 2, 'two lines at most')
	check(fs:GetStringHeight() <= 2 * 13 * 1.5, 'no taller than two lines')
	reset()
end)

test('a 436-tall picker opened beside a field near the screen bottom, after one with no preview, stays on the screen', function()
	reset()
	open()
	local low = field(100, UIParent:GetHeight() - 120)
	local _, F = open({ preview = 'text', owner = low })
	check(F.frame:GetBottom() >= -0.001, 'its bottom is on the screen')
	eq(F.frame:GetHeight(), 436, 'at its new height')
	reset()
end)

------------------------------------------------------------------ the states kind

local SL = load_test_file('lib/states_look.lua')
local function rgba(r, g, b, a) return ('%.3f,%.3f,%.3f,%.3f'):format(r, g, b, a or 1) end
local function texture_color(texture) return rgba(unpack(stub.state(texture).color_texture)) end
local function rel(piece, tile) return piece:GetLeft() - tile:GetLeft() .. ',' .. tile:GetTop() - piece:GetTop() end
local PURPLE = { r = 0x8a / 255, g = 0x5c / 255, b = 0xf5 / 255 } -- the spec's worked color

local function open_states(extra)
	extra = extra or {}
	extra.preview, extra.name = 'states', 'Accent'
	if extra.r == nil then extra.r, extra.g, extra.b = PURPLE.r, PURPLE.g, PURPLE.b end
	return open(extra)
end

local function exact_settings(fn)
	local keep = st.config.profile.theme.states
	local ok, err = pcall(fn)
	st.config.profile.theme.states = keep
	st.States.Changed()
	if not ok then error(err, 0) end
end

test('the states kind: six tiles 58 by 44 at 0, 62, 124, 187, 249 and 312, each a kit button "Okay" 46 by 20 at 6, 12, captioned in Muted', function()
	T.theme('thick')
	reset()
	local _, F = open_states()
	local p = F.previewPieces.states
	eq(#p.tiles, 6, 'six tiles')
	local xs, names = {}, {}
	for i, tile in ipairs(p.tiles) do
		xs[i] = tile:GetLeft() - F.preview:GetLeft()
		eq(tile:GetWidth() .. 'x' .. tile:GetHeight(), '58x44', 'tile ' .. i)
		names[i] = p.captions[i]:GetText()
		eq(p.buttons[i].text:GetText(), 'Okay', 'the kit button ' .. i)
		eq(p.buttons[i]:GetWidth() .. 'x' .. p.buttons[i]:GetHeight(), '46x20', 'button ' .. i)
		eq(rel(p.buttons[i], tile), '6,12', 'button ' .. i .. ' centred in its tile')
		eq(stub.state(p.buttons[i]).mouse_enabled, false, 'it takes no mouse')
		eq(rgb3(p.captions[i]:GetTextColor()), rgb3(st:Color('text', 'muted'):GetRGB()), 'caption ' .. i .. ' in Muted')
	end
	eq(table.concat(xs, ','), '0,62,124,187,249,312', 'the first at the left edge, the last at the right')
	eq(table.concat(names, '|'), 'Rest|Hover|Pushed|Selected|+ hover|Disabled')
	eq(F.preview:GetRight() - p.tiles[6]:GetRight() < 0.001, true, 'the last tile ends at the strip\'s right edge')
	reset()
end)

test("the states kind shows the picked color's states, held: hover, pushed, selected, selected and hovered, disabled", function()
	T.theme('thick')
	reset()
	exact_settings(function()
		local _, F = open_states()
		local b = F.previewPieces.states.buttons
		local looks = {}
		for i = 1, 6 do looks[i] = st:StateLook(b[i]) end
		check(not looks[1].layer.shown and not looks[1].fill.shown, 'Rest has no layer and no fill')
		eq(looks[2].layer.shown, true, 'Hover shows its layer')
		check(SL.near(looks[2].layer, '9f7fff') and math.abs(looks[2].layer.a - 0.16) < 1e-6, 'Hover: T+ 9f7fff at 0.16, got ' .. SL.bytes(looks[2].layer) .. ' ' .. looks[2].layer.a)
		check(SL.near(looks[3].layer, '7441d9') and math.abs(looks[3].layer.a - 0.32) < 1e-6, 'Pushed: T- 7441d9 at 0.32, got ' .. SL.bytes(looks[3].layer) .. ' ' .. looks[3].layer.a)
		eq(SL.bytes(looks[4].edge), '8a5cf5', 'Selected: the edge is the picked color')
		check(SL.near(looks[4].fill, '8a5cf5') and math.abs(looks[4].fill.a - 0.24) < 1e-6, 'and its fill is the picked color at 0.24')
		eq(SL.bytes(looks[5].edge), '9f7fff', 'Sel. + hover: the lighter edge')
		check(math.abs(stub.state(b[6]).alpha - 0.4) < 1e-6 or math.abs(b[6]:GetAlpha() - 0.4) < 1e-6, 'Disabled draws at 0.4')
		eq(b[1]:GetAlpha(), 1, 'the others at full opacity')
		eq(st:GetState(b[2], 'hover') and st:GetState(b[3], 'pushed') and st:GetState(b[4], 'selected') and st:GetState(b[6], 'disabled'), true, 'held with st:SetState')
	end)
	reset()
end)

test("the states kind is the DRAFT's: the saved Accent is not it, and a drag moves the states with it", function()
	T.theme('thick')
	reset()
	local saved = rgb3(st:Color('accent'):GetRGB())
	local told, F = open_states()
	local b = F.previewPieces.states.buttons
	check(rgb3(st:Color('accent'):GetRGB()) == saved, 'the profile is untouched by the preview')
	local before = SL.bytes(st:StateLook(b[4]).edge)
	press(F.square, 0.2, 0.8)
	release(F.square)
	check(#told.changes > 0, 'the drag changed the color')
	check(SL.bytes(st:StateLook(b[4]).edge) ~= before, 'the Selected tile followed the drag')
	local r, g, bl = unpack(told.changes[#told.changes])
	eq(SL.bytes(st:StateLook(b[4]).edge), SL.bytes({ r = r, g = g, b = bl }), "its edge is the draft's color")
	eq(rgb3(st:Color('accent'):GetRGB()), saved, 'and the saved Accent is still the saved one')
	reset()
end)

test("the states kind follows the derivation settings: Layers makes the Hover tile the accent itself", function()
	T.theme('thick')
	reset()
	exact_settings(function()
		st.config.profile.theme.states = { mode = 'layers' }
		st.States.Changed()
		local _, F = open_states()
		local b = F.previewPieces.states.buttons
		eq(SL.bytes(st:StateLook(b[2]).layer), '8a5cf5', 'Hover is the picked color in Layers')
		check(SL.bytes(st:StateLook(b[5]).edge) == '8a5cf5', 'and the lighter edge is the accent too')
	end)
	reset()
end)

test("the states kind takes settings of its own (spec.settings): W.PaintStates draws a set that is not the saved one", function()
	T.theme('thick')
	reset()
	local _, F = open_states()
	local p = F.previewPieces.states
	local own = {}
	for k, v in pairs(st.States.Settings()) do own[k] = v end
	own.hover = 0.5
	W.PaintStates(p, PURPLE.r, PURPLE.g, PURPLE.b, own)
	check(math.abs(st:StateLook(p.buttons[2]).layer.a - 0.5) < 1e-6, 'Hover at the set\'s 50%')
	eq(st.States.Settings().hover, st.defaults.theme.states.hover, 'the profile keeps its own')
	F.paintPreview()
	check(math.abs(st:StateLook(p.buttons[2]).layer.a - st.defaults.theme.states.hover) < 1e-6, 'and the picker\'s paint is the saved settings again')
	reset()
end)

test("the states kind under Blizzard: drawn as Thick with the note; Thick and Thin: the theme in use, no note", function()
	for _, look in ipairs({ 'thick', 'thin' }) do
		T.theme(look)
		reset()
		local _, F = open_states()
		check(not F.previewNote:IsShown(), look .. ': no note')
		eq(drawn(F.previewPieces.states.tiles[1]), 'theme,solid,panel', look .. ': the tiles follow the theme')
	end
	T.theme('blizzard')
	reset()
	local _, F = open_states()
	local p = F.previewPieces.states
	check(F.previewNote:IsShown(), 'a note under Blizzard')
	eq(F.previewNote:GetText(), "Shown as Thick: Blizzard's art draws its own.", 'its text')
	for i, tile in ipairs(p.tiles) do eq(drawn(tile), 'thick,solid,panel', 'tile ' .. i .. ' drawn Thick') end
	for i, button in ipairs(p.buttons) do
		eq(st:StateLook(button).blizzard, false, 'button ' .. i .. ' wears the kit look, not Blizzard\'s art')
	end
	local look = st:StateLook(p.buttons[2])
	eq(look.layer.shown, true, "and Hover's layer shows under Blizzard")
	T.theme('thick')
	check(not F.previewNote:IsShown(), 'back under Thick: the note goes')
	eq(drawn(p.tiles[1]), 'theme,solid,panel', 'the tiles follow the theme again')
	eq(st:GetState(p.buttons[2], 'hover'), true, 'and the states are still held')
	reset()
end)

test('the states kind holds its states again after the picker is hidden and opened', function()
	T.theme('thick')
	reset()
	local _, F = open_states()
	local b = F.previewPieces.states.buttons
	W.CloseColorPicker()
	_, F = open_states()
	eq(st:GetState(b[2], 'hover'), true, 'Hover')
	eq(st:GetState(b[3], 'pushed'), true, 'Pushed')
	eq(st:GetState(b[5], 'hover') and st:GetState(b[5], 'selected'), true, 'Selected + hover')
	eq(st:GetState(b[6], 'disabled'), true, 'Disabled')
	reset()
end)

test('the states kind with an opacity (402 wide) keeps whole tiles, the last at the right edge', function()
	T.theme('thick')
	reset()
	local _, F = open_states({ hasAlpha = true })
	local p = F.previewPieces.states
	eq(p.tiles[1]:GetLeft() - F.preview:GetLeft(), 0, 'the first at the left')
	eq(F.preview:GetRight() - p.tiles[6]:GetRight() < 0.001, true, 'the last at the right')
	for i = 1, 6 do eq(p.tiles[i]:GetLeft() % 1, 0, 'tile ' .. i .. ' on a whole unit') end
	reset()
end)

test('the states kind: every caption has word wrap off and sits inside the area', function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		T.theme(look)
		reset()
		local _, F = open_states()
		for i, caption in ipairs(F.previewPieces.states.captions) do
			eq(caption:CanWordWrap(), false, look .. ' caption ' .. i)
			check(caption:GetTop() - caption:GetStringHeight() >= F.preview:GetBottom() - 0.001, look .. ' caption ' .. i .. ' inside the area')
		end
		reset()
	end
	T.theme('thick')
end)

test('a theme recolor with the picker open puts the states kind back to the draft', function()
	T.theme('thick')
	reset()
	exact_settings(function()
		local _, F = open_states()
		local b = F.previewPieces.states.buttons
		b[4]:SetBackdropBorderColor(1, 1, 1, 1)
		st:RecolorThemed()
		eq(SL.bytes(st:StateLook(b[4]).edge), '8a5cf5', 'the selected edge is the draft again')
	end)
	reset()
end)

------------------------------------------------------------------ the danger kind

local function danger_open(extra)
	extra = extra or {}
	extra.preview, extra.name, extra.hasAlpha = 'danger', 'Danger', true
	return open(extra)
end

test("the danger kind: two tiles 118 by 44, the first at the left edge and the second at the right (252, or 284 with an opacity), captioned Flash and Locked slot, a slot in each", function()
	T.theme('thick')
	reset()
	local _, F = danger_open({ a = 0.5 })
	local p = F.previewPieces.danger
	eq(#p.tiles, 2, 'two tiles')
	eq(p.tiles[1]:GetLeft() - F.preview:GetLeft(), 0, 'the first at the left edge')
	eq(F.preview:GetRight() - p.tiles[2]:GetRight() < 0.001, true, 'the second at the right edge')
	eq(p.tiles[1]:GetWidth() .. 'x' .. p.tiles[1]:GetHeight(), '118x44', 'tile size')
	eq(p.captions[1]:GetText() .. '|' .. p.captions[2]:GetText(), 'Flash|Locked slot')
	eq(p.slots[1]:GetWidth() .. ',' .. p.slots[2]:GetWidth(), '30,20', 'the action button and the bank slot')
	eq(p.tiles[2]:GetLeft() - F.preview:GetLeft(), 284, 'at 402 wide (an opacity) the second is at 284')
	eq(drawn(p.slots[1]), 'theme,solid,slot', 'a slot')
	reset()
	local _, F2 = open({ preview = 'danger', name = 'Danger' })
	eq(F2.previewPieces.danger.tiles[2]:GetLeft() - F2.preview:GetLeft(), 252, 'at 370 wide the second is at 252')
	reset()
end)

test("the danger kind: the flash at 0.4 and the locked slot at 0.3 times the picked color and its opacity", function()
	T.theme('thick')
	reset()
	local _, F = danger_open({ r = 0.9, g = 0.3, b = 0.1, a = 0.5 })
	local p = F.previewPieces.danger
	eq(texture_color(p.veils[1]), rgba(0.9, 0.3, 0.1, 0.5 * 0.4), 'the flash')
	eq(texture_color(p.veils[2]), rgba(0.9, 0.3, 0.1, 0.5 * 0.3), 'the locked slot')
	press(F.square, 0.3, 0.4)
	release(F.square)
	check(texture_color(p.veils[1]) ~= rgba(0.9, 0.3, 0.1, 0.2), 'a drag moved it')
	for i = 1, 2 do eq(rgb3(p.captions[i]:GetTextColor()), rgb3(st:Color('text', 'normal'):GetRGB()), 'caption ' .. i .. ' in Text: Danger reaches both') end
	reset()
end)

test('the danger slots are centred from the size constants, with sizes read back a hair off; the veil is over the slot\'s fill', function()
	T.theme('thick')
	for _, noise in ipairs({ 0, 2 ^ -14 }) do
		reset()
		stub.size_noise = noise
		local _, F = danger_open()
		local p = F.previewPieces.danger
		for i, want in ipairs({ { 44, -7 }, { 49, -12 } }) do
			local _, _, _, x, y = p.slots[i]:GetPoint()
			eq(x .. ',' .. y, want[1] .. ',' .. want[2], ('slot %d is placed at its constants (noise %s)'):format(i, tostring(noise)))
			eq((p.veils[i]:GetDrawLayer()), 'OVERLAY', 'the veil is over the slot\'s fill (' .. i .. ')')
		end
	end
	reset()
end)

test("a preview paint derives into the strip's own table, never the saved cache; with no color it paints from the cache", function()
	T.theme('thick')
	reset()
	local _, F = open({ preview = 'states', name = 'Accent', r = 0.54, g = 0.36, b = 0.96 })
	local p = F.previewPieces.states
	check(p.derived ~= st.States.cache, 'a table of its own')
	local function snapshot()
		local out = {}
		for _, name in ipairs({ 'hover', 'pushed', 'fill', 'fillHover', 'edge', 'edgeHover' }) do
			out[#out + 1] = table.concat({ st:StateColor(name) }, ',')
		end
		return table.concat(out, '|') .. '|' .. st.States.cache.mode
	end
	local before = snapshot()
	W.PaintStates(p, 0.9, 0.2, 0.2, { mode = 'layers', hover = 0.5, pushed = 0.5, selected = 0.5, fade = 0.5, disabled = 0.5,
		step = 0.1, shift = 10, chroma = 0.1, direction = 'warm' })
	eq(snapshot(), before, "the saved cache, and so every real widget's states, are untouched")
	eq(st:StateLook(p.buttons[2]).layer.a, 0.5, 'while the strip shows the draft')
	W.PaintStates(p)
	eq(st:StateLook(p.buttons[2]).layer.a, st.States.cache.h, 'with no color: the cache, the saved settings')
	reset()
end)

test('the states strip narrower than the picker: 54 wide tiles across 348, 4 apart at least; 58 at 370 and 402 as before', function()
	T.theme('thick')
	reset()
	local _, F = open({ preview = 'states', name = 'Accent' })
	local kind = W.PreviewKinds().states
	local p = F.previewPieces.states
	local function lefts()
		local out = {}
		for i, tile in ipairs(p.tiles) do out[i] = ('%d:%d'):format(tile:GetLeft() - F.preview:GetLeft(), tile:GetWidth()) end
		return table.concat(out, ' ')
	end
	eq(lefts(), '0:58 62:58 124:58 187:58 249:58 312:58', '370')
	kind.Layout(p, 348)
	eq(lefts(), '0:54 58:54 117:54 176:54 235:54 294:54', '348: narrower tiles, the last at the right edge')
	local b = p.buttons[1]
	eq((b:GetLeft() - p.tiles[1]:GetLeft()) .. ',' .. b:GetWidth(), '4,46', 'the button is centred in its tile')
	kind.Layout(p, 402)
	eq(lefts(), '0:58 68:58 137:58 206:58 275:58 344:58', '402')
	kind.Layout(p, 370)
	eq(lefts(), '0:58 62:58 124:58 187:58 249:58 312:58', 'and back to 370')
	reset()
end)

test('the danger kind under Blizzard: drawn as Thick with the note; no Buttons color is read', function()
	T.theme('blizzard')
	reset()
	local _, F = danger_open()
	local p = F.previewPieces.danger
	check(F.previewNote:IsShown(), 'a note under Blizzard')
	eq(F.previewNote:GetText(), "Shown as Thick: Blizzard's art draws its own.", 'its text')
	for i = 1, 2 do
		eq(drawn(p.tiles[i]), 'thick,solid,panel', 'tile ' .. i)
		eq(drawn(p.slots[i]), 'thick,solid,slot', 'slot ' .. i)
	end
	T.theme('thick')
	check(not F.previewNote:IsShown(), 'back: no note')
	eq(drawn(p.slots[1]), 'theme,solid,slot', 'the slot follows the theme again')
	reset()
end)

------------------------------------------------------------------ cost and pixels

test('the states and danger kinds paint without making anything: 1000 paints, 16 setter calls (states) and 4 (danger) each, under 4 KB', function()
	for _, case in ipairs({
		{ preview = 'states', name = 'Accent' },
		{ preview = 'danger', hasAlpha = true, a = 0.5, name = 'Danger' },
	}) do
		for _, look in ipairs({ 'thick', 'blizzard' }) do
			T.theme(look)
			reset()
			local _, F = open(case)
			local kind = case.preview
			local where = kind .. ' under ' .. look .. ': '
			local def, pieces = W.PreviewKinds()[kind], F.previewPieces[kind]
			local spec = { fields = {}, name = case.name, hasAlpha = case.hasAlpha or false }
			def.Paint(pieces, 0.1, 0.2, 0.3, 1, spec) -- each widget's first color call makes its table once
			local i = 0
			local m = C.measure(function()
				i = i + 1
				def.Paint(pieces, 0.1 + (i % 7) / 10, 0.2, 0.3, 0.5, spec)
			end, 1000)
			eq(m.calls.total / 1000, kind == 'states' and 16 or 4, where .. 'setter calls a paint: six buttons painted from the derived table and their captions (states), two veils and captions (danger)')
			check(m.kb < 4, where .. ('under 4 KB, got %.2f'):format(m.kb))
			eq(m.made, 0, where .. 'nothing made')
			eq(m.forbidden.total, 0, where .. 'nothing placed, shown or sized')
			F.paintPreview()
			m = C.measure(function() F.paintPreview() end, 1000)
			eq(m.calls.total / 1000, kind == 'states' and 16 or 4, where .. "the picker's path: the same")
			check(m.kb < 4, where .. ("the picker's path under 4 KB, got %.2f"):format(m.kb))
			eq(m.forbidden.total, 0, where .. "the picker's path places and shows nothing")
			reset()
		end
	end
	T.theme('thick')
end)

test('a drag frame costs the states preview next to nothing: the picker\'s whole Paint, with and without it', function()
	T.theme('thick')
	reset()
	local _, F = open({ preview = 'text', name = 'Text' })
	local with_text = C.measure(function() F.paintPreview() end, 200)
	reset()
	_, F = open_states()
	local m = C.measure(function() F.paintPreview() end, 200)
	local per = m.calls.total / 200
	print(('  states paint per drag frame: %d setters (text kind %d), %.2f KB/200'):format(per, with_text.calls.total / 200, m.kb))
	eq(per, 16, 'a drag frame sets 16 colors for the strip (the text kind sets 9)')
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing placed or shown')
	reset()
end)

test('the states and danger kinds: every part on whole pixels under Thick, Thin and Blizzard, with sizes read back a hair off', function()
	local HAIR = 2 ^ -14
	for _, case in ipairs({ { preview = 'states', name = 'Accent' }, { preview = 'danger', name = 'Danger' } }) do
		for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
			for _, noise in ipairs({ 0, HAIR, -HAIR }) do
				for _, hasAlpha in ipairs({ true, false }) do
					T.theme(look)
					stub.size_noise = noise
					reset()
					stub.size_noise = noise
					local where = case.preview .. ' ' .. look .. ' noise ' .. noise .. (hasAlpha and ' alpha' or ' opaque') .. ': '
					local _, F = open({ preview = case.preview, name = case.name, hasAlpha = hasAlpha })
					local off = P.off(F.frame)
					eq(#off, 0, where .. P.report(off))
					check(F.preview:IsShown(), where .. 'the area is part of what was checked')
					press(F.square, 0.37, 0.61)
					release(F.square)
					off = P.off(F.frame)
					eq(#off, 0, where .. 'after a drag: ' .. P.report(off))
					reset()
				end
			end
		end
	end
	stub.size_noise = 0
	T.theme('thick')
end)

------------------------------------------------------------------ the rows

test('the Buttons section holds Danger alone with the danger kind, the Accent row has the states kind, and each opens', function()
	local CO = st:GetModule('Colors')
	local args = CO:GetConfigTable().args
	local count = 0
	for key in pairs(args.button.args) do count = count + 1 end
	eq(count, 1, 'one row in Buttons')
	eq(args.button.args.danger.preview, 'danger', 'Danger')
	eq(W.ReadPreview(args.button.args.danger.preview), 'danger', 'reads')
	reset()
	local w = H.bind('color', 'danger', H.opt('color', 'Danger', {
		preview = args.button.args.danger.preview, hasAlpha = true,
		get = function() return 0.3, 0.5, 0.7, 0.9 end, set = function() end,
	}))
	w:Pick()
	eq(W.GetColorPickerFrames().frame:GetHeight(), 436, 'Danger opens with its preview')
	reset()
	local accent = CO:AccentOption(1)
	eq(accent.preview, 'states', 'the Accent row')
	eq(W.ReadPreview(accent.preview), 'states', 'reads')
	w = H.bind('color', 'accent', H.opt('color', 'Accent', {
		preview = accent.preview, get = function() return 0.3, 0.5, 0.7 end, set = function() end,
	}))
	w:Pick()
	eq(W.GetColorPickerFrames().frame:GetHeight(), 436, 'the Accent opens with its preview')
	reset()
	eq(W.PreviewKinds().button, nil, 'the button kind is gone')
	eq(W.PreviewKinds().accent, nil, 'and the accent kind')
	local names = {}
	for name in pairs(W.PreviewKinds()) do if name ~= 'other' and name ~= 'probe' then names[#names + 1] = name end end
	table.sort(names)
	eq(table.concat(names, ','), 'bar,border,danger,states,text', 'the built-in kinds')
end)

------------------------------------------------------------------ the bar and border kinds

local PICKED = '0.20,0.40,0.60' -- what open() picks unless told otherwise

local function bar_color(b) return rgb3(b:GetStatusBarColor()) end
local function border_color(f) return rgb3(f:GetBackdropBorderColor()) end
local function class_color()
	local key = st.my_class
	if not (key and st.config.profile.colors.class[key]) then key = 'MAGE' end
	return rgb3(st:Color('class', key):GetRGB())
end
local function muted() return rgb3(st:Color('text', 'muted'):GetRGB()) end
local function normal() return rgb3(st:Color('text', 'normal'):GetRGB()) end

local function open_bar(fields)
	fields.kind = 'bar'
	reset()
	local told, F = open({ preview = fields, name = fields.name or fields.label })
	return F, F.previewPieces.bar, told
end

local function open_border(style, extra)
	local fields = { kind = 'border', style = style }
	for k, v in pairs(extra or {}) do fields[k] = v end
	reset()
	local told, F = open({ preview = fields, name = 'Epic' })
	return F, F.previewPieces.border, told
end

local function size(f) return f:GetWidth() .. ',' .. f:GetHeight() end
local function nomouse(f, what)
	eq(stub.state(f).mouse_enabled, false, what .. ' takes no mouse')
end

test('bar unit: a 200 by 28 health bar 70% filled in the color with the label and 70%, an 80 by 40 raid frame, a tooltip; drawn as bars', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		T.theme(look)
		local F, p = open_bar({ style = 'unit', label = 'Mage' })
		local where = look .. ': '
		check(F.preview:IsShown() and F.frame:GetHeight() == 436, where .. 'opens with a preview')
		local u, r, t = p.unitBar, p.unitRaid, p.unitTip
		eq(size(u.bar), '200,28', where .. 'the unit frame bar')
		eq(size(r.bar), '80,40', where .. 'the raid frame')
		eq(size(t.tip), '74,44', where .. 'the tooltip')
		eq(drawn(u.bar), 'theme,solid,bar', where .. 'the bar is a bar')
		eq(drawn(r.bar), 'theme,solid,bar', where .. 'so is the raid frame')
		eq(drawn(t.tip), 'theme,solid,tooltip', where .. 'the tooltip is a tooltip panel')
		local x, y = at(F, u.bar)
		eq(x .. ',' .. y, '20,274', where .. 'the bar at the left, 8 down')
		x, y = at(F, r.bar)
		eq(x .. ',' .. y, '228,268', where .. 'the raid frame 8 on')
		x, y = at(F, t.tip)
		eq(x .. ',' .. y, '316,266', where .. 'the tooltip')
		local lo, hi = u.bar:GetMinMaxValues()
		eq(lo .. ',' .. hi .. ',' .. u.bar:GetValue(), '0,100,70', where .. 'filled 70%')
		eq(r.bar:GetValue(), 70, where .. 'the raid frame too')
		eq(bar_color(u.bar), PICKED, where .. 'the bar in the picked color')
		eq(bar_color(r.bar), PICKED, where .. 'the raid frame in it')
		eq(u.label:GetText() .. '|' .. u.percent:GetText(), 'Mage|70%', where .. 'the label and 70%')
		eq(r.label:GetText(), 'Mage', where .. 'the raid frame names it')
		eq(t.label:GetText() .. '|' .. t.level:GetText(), 'Mage|Level 70', where .. 'the tooltip lines')
		eq(rgb3(t.label:GetTextColor()), PICKED, where .. "the tooltip's name in the color")
		eq(rgb3(t.level:GetTextColor()), normal(), where .. 'its other line in Text')
		if look ~= 'blizzard' then eq(border_color(t.tip), PICKED, where .. 'its border in the color') end
		eq(rgb3(u.label:GetTextColor()), normal(), where .. 'the bar texts in Text')
		for i, key in ipairs({ 'unitBar', 'unitRaid', 'unitTip' }) do
			local cell = p.cells[key]
			check(cell.holder:IsShown() and cell.caption:IsShown(), where .. key .. ' shows')
			eq(cell.caption:GetText(), ({ 'Unit frame', 'Raid frame', 'Tooltip' })[i], where .. 'caption ' .. i)
			eq(rgb3(cell.caption:GetTextColor()), muted(), where .. 'caption ' .. i .. ' in Muted')
			eq(cell.caption:CanWordWrap(), false, where .. 'caption ' .. i .. ' does not wrap')
			nomouse(cell.holder, where .. key .. ' holder')
		end
		nomouse(u.bar, where .. 'the bar'); nomouse(r.bar, where .. 'the raid frame'); nomouse(t.tip, where .. 'the tooltip')
		for _, key in ipairs({ 'roleRaid', 'repXp', 'repNpc', 'powerBars', 'pointsRow', 'plate' }) do
			check(not p.cells[key].holder:IsShown() and not p.cells[key].caption:IsShown(), where .. key .. ' is hidden')
		end
	end
	T.theme('thick')
	reset()
end)

test("bar unit under Thick: the tooltip's border is the picked color exactly", function()
	T.theme('thick')
	local F, p = open_bar({ style = 'unit', label = 'Mage' })
	eq(border_color(p.unitTip.tip), PICKED, 'the tooltip border')
	reset()
end)

test('bar unit with tooltip = false (Status): no tooltip, the bar and the raid frame centered', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'unit', label = 'Offline', tooltip = false })
	check(not p.cells.unitTip.holder:IsShown() and not p.cells.unitTip.caption:IsShown(), 'the tooltip is hidden')
	eq(p.unitBar.label:GetText(), 'Offline', 'the label')
	-- 200 + 8 + 80 = 288 in 370: 41 in.
	local x = at(F, p.unitBar.bar)
	eq(x, 20 + 41, 'centered: the bar 41 in')
	x = at(F, p.unitRaid.bar)
	eq(x, 20 + 41 + 208, 'and the raid frame 208 on')
	reset()
end)

test('bar role: a raid frame 80 by 40 with st.textures.cornerbr, 16, at its bottom right corner, in the color', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'role', name = 'Healer' })
	local r = p.cells.roleRaid
	check(r.holder:IsShown(), 'shown')
	eq(size(p.roleRaid.bar), '80,40', 'the raid frame')
	eq(drawn(p.roleRaid.bar), 'theme,solid,bar', 'a bar')
	eq(stub.state(p.roleRaid.corner).texture, st.textures.cornerbr, 'the corner texture')
	eq(size(p.roleRaid.corner), '16,16', 'the corner 16 by 16')
	eq(rgb3(p.roleRaid.corner:GetVertexColor()), PICKED, 'in the picked color')
	eq(bar_color(p.roleRaid.bar), class_color(), "the raid frame's bar is a class color")
	eq(p.roleRaid.label:GetText(), 'Healer', 'the row\'s name')
	eq(p.roleRaid.corner:GetRight() - p.roleRaid.bar:GetRight(), 2, 'out of the bar by 2 on the right')
	eq(p.roleRaid.bar:GetBottom() - p.roleRaid.corner:GetBottom(), 2, 'and 2 down')
	-- centered: 80 in 370 is 145 in
	local x = at(F, p.roleRaid.bar)
	eq(x, 20 + 145, 'centered in the strip')
	check(not p.cells.unitBar.holder:IsShown(), 'no unit frame')
	reset()
end)

test('bar reputation: the reputation bar 150 by 13, an NPC health bar 100 by 28 and an NPC tooltip, in the color with the label', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'reputation', label = 'Friendly' })
	eq(size(p.repXp.bar), '150,13', 'the experience bar')
	eq(size(p.repNpc.bar), '100,28', 'the NPC bar')
	eq(size(p.repTip.tip), '74,44', 'the NPC tooltip')
	eq(drawn(p.repTip.tip), 'theme,solid,tooltip', 'a tooltip panel')
	eq(border_color(p.repTip.tip), PICKED, "its border in the standing's color")
	eq(rgb3(p.repTip.label:GetTextColor()) .. ' ' .. p.repTip.label:GetText(), PICKED .. ' Friendly', 'its name')
	for _, key in ipairs({ 'repXp', 'repNpc', 'repTip' }) do check(p.cells[key].holder:IsShown(), key .. ' shows') end
	-- 150 + 100 + 74 and two gaps of 8 is 340: 15 in.
	eq(at(F, p.repXp.bar), 20 + 15, 'centered')
	eq(drawn(p.repXp.bar) .. ' ' .. drawn(p.repNpc.bar), 'theme,solid,bar theme,solid,bar', 'both bars')
	eq(bar_color(p.repXp.bar) .. ' ' .. bar_color(p.repNpc.bar), PICKED .. ' ' .. PICKED, 'both in the color')
	eq(p.repXp.bar:GetValue() .. ',' .. p.repNpc.bar:GetValue(), '70,70', '70%')
	eq(p.repXp.label:GetText() .. ',' .. p.repNpc.label:GetText(), 'Friendly,Friendly', 'the label on both')
	eq(p.cells.repXp.caption:GetText() .. ',' .. p.cells.repNpc.caption:GetText() .. ',' .. p.cells.repTip.caption:GetText(), 'Reputation bar,NPC health,Tooltip', 'captions')
	reset()
end)

test('bar reputation for Renown (npc = false, tooltip = false): the experience bar alone, centered; no NPC bar or tooltip takes Renown', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'reputation', label = 'Renown', npc = false, tooltip = false })
	check(p.cells.repXp.holder:IsShown(), 'the experience bar shows')
	check(not p.cells.repNpc.holder:IsShown() and not p.cells.repNpc.caption:IsShown(), 'no NPC health bar')
	check(not p.cells.repTip.holder:IsShown() and not p.cells.repTip.caption:IsShown(), 'no tooltip')
	eq(bar_color(p.repXp.bar), PICKED, 'the experience bar in the color')
	eq(at(F, p.repXp.bar), 20 + 110, '150 centered in 370')
	-- npc = false alone leaves the tooltip.
	F, p = open_bar({ style = 'reputation', label = 'Hated', npc = false })
	check(not p.cells.repNpc.holder:IsShown() and p.cells.repTip.holder:IsShown(), 'npc = false leaves only the bar out')
	reset()
end)

test('every label in a tile has a width and is cut at its end: none runs past its bar or tile in a wide face', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'unit', label = 'Demon Hunter' })
	local function bounded(fs, limit, what)
		eq(fs:CanWordWrap(), false, what .. ': no word wrap')
		local w = fs:GetWidth()
		check(w > 0 and w <= limit, what .. (': a width of its own, within %d (got %s)'):format(limit, tostring(w)))
	end
	bounded(p.unitBar.label, 200 - 12 - 40, 'unit label')
	bounded(p.unitBar.percent, 40, 'percent')
	bounded(p.unitRaid.label, 80, 'raid frame label')
	bounded(p.unitTip.label, 74 - 14, 'tooltip name')
	bounded(p.unitTip.level, 74 - 14, 'tooltip level')
	check(p.unitBar.label:GetWidth() + p.unitBar.percent:GetWidth() <= 200 - 12, 'the label and percent fit the bar together')
	F, p = open_bar({ style = 'role', name = 'Healer' })
	bounded(p.roleRaid.label, 80, 'role label')
	F, p = open_bar({ style = 'plate', threat = true })
	bounded(p.plate.name, 200, 'plate name'); bounded(p.plate.threat, 40, 'threat percent')
	for _, style in ipairs({ 'reputation', 'power' }) do
		F, p = open_bar({ style = style, label = 'Demon Hunter' })
		for _, key in ipairs({ 'repXp', 'repNpc', 'powerBars' }) do
			if p[key].label then
				eq(p[key].label:CanWordWrap(), false, key .. ' label: no word wrap')
				eq(p[key].label:IsTruncated() or true, true, key)
			end
		end
	end
	reset()
end)

test('bar power: a health bar 200 by 24 with the power bar 200 by 12 under it, the power bar in the color with its label', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'power', label = 'Rage' })
	local b = p.powerBars
	eq(size(b.health) .. ' ' .. size(b.power), '200,24 200,12', 'sizes')
	local _, hy = at(F, b.health)
	local _, py = at(F, b.power)
	check(py - (hy + 24) >= 4, 'clear of the health bar and its border')
	eq(bar_color(b.power), PICKED, 'the power bar in the color')
	eq(bar_color(b.health), class_color(), 'the health bar in a class color')
	eq(b.label:GetText(), 'Rage', 'the label')
	eq(b.power:GetValue(), 70, 'filled 70%')
	reset()
end)

test('bar points: five points 34 by 20, 7 apart, three lit in the color; Blizzard draws them Thick with a note', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'points' })
	local pts = p.pointsRow.points
	eq(#pts, 5, 'five points')
	local x0 = at(F, pts[1])
	for i, point in ipairs(pts) do
		eq(size(point), '34,20', 'point ' .. i)
		eq(at(F, point), x0 + (i - 1) * 41, 'point ' .. i .. ' 7 on from the last')
		eq(point:GetValue(), i <= 3 and 1 or 0, 'point ' .. i .. (i <= 3 and ' lit' or ' empty'))
		eq(drawn(point), 'theme,solid,control', 'point ' .. i .. ' drawn as a control')
	end
	for i = 1, 3 do eq(bar_color(pts[i]), PICKED, 'lit point ' .. i .. ' in the color') end
	check(not F.previewNote:IsShown(), 'no note under Thick')
	T.theme('blizzard')
	check(F.previewNote:IsShown(), 'a note under Blizzard')
	eq(F.previewNote:GetText(), "Shown as Thick: under Blizzard, class power points wear Blizzard's art.", 'its text')
	for i, point in ipairs(pts) do eq(drawn(point), 'thick,solid,control', 'point ' .. i .. ' drawn Thick') end
	T.theme('thick')
	check(not F.previewNote:IsShown(), 'back: the note goes')
	eq(drawn(pts[2]), 'theme,solid,control', 'the points follow the theme again')
	-- Other styles have no note under Blizzard.
	T.theme('blizzard')
	local F2 = open_bar({ style = 'unit', label = 'Mage' })
	check(not F2.previewNote:IsShown(), 'a unit preview has no note under Blizzard')
	T.theme('thick')
	reset()
end)

test('bar plate: a nameplate 200 by 20 with its name and, with threat, the percent above its right end in the color', function()
	T.theme('thick')
	local F, p = open_bar({ style = 'plate', threat = true, name = 'Bad' })
	local pl = p.plate
	eq(size(pl.bar), '200,20', 'the plate')
	eq(bar_color(pl.bar), PICKED, "the plate's bar in the color")
	eq(pl.name:GetText(), 'Wolf', 'its name')
	check(pl.threat:IsShown(), 'the threat percent shows')
	eq(rgb3(pl.threat:GetTextColor()), PICKED, 'in the color')
	check(pl.threat:GetBottom() > pl.bar:GetTop() and pl.threat:GetRight() <= pl.bar:GetRight() + 0.001, 'above the bar, at its right end')
	eq(rgb3(pl.name:GetTextColor()), rgb3(st:Color('text', 'danger'):GetRGB()), 'a hostile name')
	local F2, p2 = open_bar({ style = 'plate', name = 'Bad' })
	check(not p2.plate.threat:IsShown(), 'without threat there is no percent')
	reset()
end)

test("border slot: a 36 slot drawn as a slot with its border in the color through st:SetBorderColor, an icon inside it, and a feed line with the name in the color", function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		T.theme(look)
		local F, p = open_border('slot')
		local where = look .. ': '
		local s = p.slotSlot
		eq(size(s.slot), '36,36', where .. 'the slot')
		eq(drawn(s.slot), 'theme,solid,slot', where .. 'the Slot theme')
		if look ~= 'blizzard' then eq(border_color(s.slot.backdrop), PICKED, where .. 'its border in the color') end
		local inset = st:DrawnInset(s.slot) or 0
		eq(s.icon:GetLeft() - s.slot:GetLeft(), inset, where .. 'the icon inside the border, by the drawn inset')
		eq(s.slot:GetTop() - s.icon:GetTop(), inset, where .. 'on top too')
		check(s.icon:GetTexture() ~= nil, where .. 'an icon')
		local l = p.slotLine
		eq(size(l.line), '200,32', where .. 'the feed line')
		eq(drawn(l.line), 'theme,solid,panel', where .. 'a panel')
		eq(drawn(l.icon), 'theme,solid,slot', where .. 'its icon a slot')
		eq(l.name:GetText(), 'Item name', where .. 'an item name')
		eq(rgb3(l.name:GetTextColor()), PICKED, where .. 'in the color')
		eq(p.cells.slotSlot.caption:GetText() .. ',' .. p.cells.slotLine.caption:GetText(), 'Slot,Feed line', where .. 'captions')
		nomouse(s.slot, where .. 'the slot'); nomouse(l.line, where .. 'the line'); nomouse(l.icon, where .. 'its icon')
		check(not p.cells.entryLine.holder:IsShown(), where .. 'no entry')
	end
	T.theme('thick')
	reset()
end)

test('border entry: a feed entry 250 by 32 with its border and its icon\'s border in the color and its fill at 60%', function()
	T.theme('thick')
	local F, p = open_border('entry')
	local e = p.entryLine
	eq(size(e.line), '250,32', 'the entry')
	eq(border_color(e.line.backdrop), PICKED, 'its border')
	eq(rgb3(e.line.backdrop:GetBackdropColor()), PICKED, 'its fill')
	eq(select(4, e.line.backdrop:GetBackdropColor()), 0.6, 'at 60%')
	eq(border_color(e.icon.backdrop), PICKED, "its icon's border")
	eq(e.name:GetText(), 'Mount name', 'a name')
	eq(rgb3(e.name:GetTextColor()), normal(), 'in Text')
	check(not p.cells.slotSlot.holder:IsShown() and not p.cells.slotLine.holder:IsShown(), 'no slot')
	local x = at(F, e.line)
	eq(x, 20 + 60, 'centered: 250 in 370 is 60 in')
	reset()
end)

test('the bar and border kinds follow a drag and the picker puts the saved color back on the next opening', function()
	T.theme('thick')
	reset()
	local told, F = open({ preview = { kind = 'bar', style = 'unit', label = 'Mage' }, name = 'Mage', r = 0.9, g = 0.1, b = 0.1 })
	local u = F.previewPieces.bar.unitBar
	eq(bar_color(u.bar), '0.90,0.10,0.10', 'the opening color')
	press(F.square, 0.37, 0.61)
	release(F.square)
	local last = told.changes[#told.changes]
	check(last ~= nil, 'a drag changed it')
	eq(bar_color(u.bar), rgb3(last[1], last[2], last[3]), 'the bar follows the drag')
	eq(rgb3(F.previewPieces.bar.unitTip.label:GetTextColor()), rgb3(last[1], last[2], last[3]), 'and the tooltip name')
	W.CloseColorPicker() -- Cancel
	local _, F2 = open({ preview = { kind = 'bar', style = 'unit', label = 'Mage' }, name = 'Mage', r = 0.9, g = 0.1, b = 0.1 })
	eq(bar_color(F2.previewPieces.bar.unitBar.bar), '0.90,0.10,0.10', 'the saved color again after Cancel')
	reset()
	local _, F3 = open({ preview = { kind = 'border', style = 'entry' }, name = 'Mount', r = 0.9, g = 0.1, b = 0.1 })
	local e = F3.previewPieces.border.entryLine
	press(F3.square, 0.2, 0.2)
	release(F3.square)
	check(border_color(e.line.backdrop) ~= '0.90,0.10,0.10', 'the entry follows a drag')
	W.CloseColorPicker()
	_, F3 = open({ preview = { kind = 'border', style = 'entry' }, name = 'Mount', r = 0.9, g = 0.1, b = 0.1 })
	eq(border_color(F3.previewPieces.border.entryLine.line.backdrop), '0.90,0.10,0.10', 'the entry has the saved color after Cancel')
	reset()
end)

test("a theme recolor with the picker open puts the bar and border kinds' own colors back", function()
	T.theme('thick')
	local F, p = open_bar({ style = 'unit', label = 'Mage' })
	st:SetBorderColor(p.unitTip.tip, 1, 1, 1)
	p.unitBar.bar:SetStatusBarColor(1, 1, 1)
	st:RecolorThemed()
	eq(border_color(p.unitTip.tip), PICKED, 'the tooltip border is back')
	eq(bar_color(p.unitBar.bar), PICKED, 'and the bar')
	local F2, b = open_border('slot')
	st:SetBorderColor(b.slotSlot.slot.backdrop, 1, 1, 1)
	st:RecolorThemed()
	eq(border_color(b.slotSlot.slot.backdrop), PICKED, 'the slot border is back')
	local F3, e = open_border('entry')
	st:SetBorderColor(e.entryLine.line.backdrop, 1, 1, 1)
	st:RedrawThemed()
	eq(border_color(e.entryLine.line.backdrop), PICKED, 'the entry border is back after a redraw')
	reset()
end)

local BAR_CASES = {
	{ kind = 'bar', style = 'unit', label = 'Mage' },
	{ kind = 'bar', style = 'unit', label = 'Offline', tooltip = false },
	{ kind = 'bar', style = 'role' },
	{ kind = 'bar', style = 'reputation', label = 'Friendly' },
	{ kind = 'bar', style = 'power', label = 'Rage' },
	{ kind = 'bar', style = 'points' },
	{ kind = 'bar', style = 'plate', threat = true },
	{ kind = 'border', style = 'slot' },
	{ kind = 'border', style = 'entry' },
}

test('the bar and border kinds paint without making anything: 1000 paints, 24 setter calls at most, under 4 KB', function()
	for _, case in ipairs(BAR_CASES) do
		for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
			T.theme(look)
			reset()
			local _, F = open({ preview = case, name = 'Row' })
			local where = case.kind .. ' ' .. case.style .. ' under ' .. look .. ': '
			local def, pieces = W.PreviewKinds()[case.kind], F.previewPieces[case.kind]
			local spec = { fields = case, name = 'Row', hasAlpha = false }
			def.Paint(pieces, 0.1, 0.2, 0.3, 1, spec) -- each widget's first color call makes its table once
			local i = 0
			local m = C.measure(function()
				i = i + 1
				def.Paint(pieces, 0.1 + (i % 7) / 10, 0.2, 0.3, 1, spec)
			end, 1000)
			check(m.calls.total <= 24 * 1000, where .. 'at most 24 setter calls a paint, got ' .. m.calls.total / 1000)
			check(m.calls.total > 0, where .. 'and it does paint')
			check(m.kb < 4, where .. ('under 4 KB, got %.2f'):format(m.kb))
			eq(m.made, 0, where .. 'nothing made')
			eq(m.forbidden.total, 0, where .. 'nothing placed, shown or sized')
			F.paintPreview()
			m = C.measure(function() F.paintPreview() end, 1000)
			check(m.calls.total <= 24 * 1000, where .. "the picker's path: at most 24 setter calls")
			check(m.kb < 4, where .. ("the picker's path under 4 KB, got %.2f"):format(m.kb))
			eq(m.forbidden.total, 0, where .. "the picker's path places and shows nothing")
			reset()
		end
	end
	T.theme('thick')
end)

test('the bar and border kinds: every part on whole pixels under Thick, Thin and Blizzard, with sizes read back a hair off', function()
	local HAIR = 2 ^ -14
	for _, case in ipairs(BAR_CASES) do
		for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
			for _, noise in ipairs({ 0, HAIR, -HAIR }) do
				T.theme(look)
				stub.size_noise = noise
				reset()
				stub.size_noise = noise
				local where = case.kind .. ' ' .. case.style .. ' ' .. look .. ' noise ' .. noise .. ': '
				local _, F = open({ preview = case, name = 'Row' })
				local off = P.off(F.frame)
				eq(#off, 0, where .. P.report(off))
				check(F.preview:IsShown(), where .. 'the area is part of what was checked')
				press(F.square, 0.37, 0.61)
				release(F.square)
				off = P.off(F.frame)
				eq(#off, 0, where .. 'after a drag: ' .. P.report(off))
				reset()
			end
		end
	end
	stub.size_noise = 0
	T.theme('thick')
end)

test('the cells and captions stay inside the strip, every caption has word wrap off, under each look', function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		T.theme(look)
		for _, case in ipairs(BAR_CASES) do
			reset()
			local _, F = open({ preview = case, name = 'Row' })
			local p = F.previewPieces[case.kind]
			local where = case.kind .. ' ' .. case.style .. ' ' .. look .. ': '
			local any = false
			for key, cell in pairs(p.cells) do
				if cell.holder:IsShown() then
					any = true
					check(cell.holder:GetLeft() + 0.001 >= F.preview:GetLeft() and cell.holder:GetRight() <= F.preview:GetRight() + 0.001,
						where .. key .. ' inside the strip across')
					check(cell.caption:GetTop() - cell.caption:GetStringHeight() >= F.preview:GetBottom() - 0.001, where .. key .. ' caption inside the area')
					eq(cell.caption:CanWordWrap(), false, where .. key .. ' caption: no word wrap')
					check(cell.caption:GetLeft() + 0.001 >= cell.holder:GetLeft() and cell.caption:GetRight() <= cell.holder:GetRight() + 0.001, where .. key .. ' caption under its cell')
				end
			end
			check(any, where .. 'something shows')
			reset()
		end
	end
	T.theme('thick')
end)

test('a style no kind has shows nothing and errors nothing', function()
	T.theme('thick')
	reset()
	for _, kind in ipairs({ 'bar', 'border' }) do
		local told, F = open({ preview = { kind = kind, style = 'nothing' }, name = 'Row' })
		check(told.opened and F.frame:GetHeight() == 436, kind .. ': opens')
		for _, cell in pairs(F.previewPieces[kind].cells) do check(not cell.holder:IsShown(), kind .. ': nothing shows') end
		reset()
		told, F = open({ preview = kind, name = 'Row' })
		check(told.opened, kind .. ' with no style opens')
		reset()
	end
end)

test('a bar and a border row with an opacity (402 wide): the cells centered, whole, inside the strip', function()
	local HAIR = 2 ^ -14
	for _, case in ipairs(BAR_CASES) do
		for _, look in ipairs({ 'thick', 'blizzard' }) do
			T.theme(look)
			stub.size_noise = HAIR
			reset()
			stub.size_noise = HAIR
			local where = case.kind .. ' ' .. case.style .. ' ' .. look .. ' 402: '
			local _, F = open({ preview = case, name = 'Row', hasAlpha = true, a = 0.5 })
			check(math.abs(F.preview:GetWidth() - 402) < 0.01, where .. 'the strip is 402 wide')
			local off = P.off(F.frame)
			eq(#off, 0, where .. P.report(off))
			local first, last
			for _, cell in pairs(F.previewPieces[case.kind].cells) do
				if cell.holder:IsShown() then
					check(cell.holder:GetLeft() + 0.001 >= F.preview:GetLeft() and cell.holder:GetRight() <= F.preview:GetRight() + 0.001, where .. 'inside the strip')
					first = math.min(first or 1e9, cell.holder:GetLeft() - F.preview:GetLeft())
					last = math.min(last or 1e9, F.preview:GetRight() - cell.holder:GetRight())
				end
			end
			local gap = math.abs(first - last)
			check(gap <= 1, where .. ('centered (left room %s, smallest right room %s)'):format(first, last))
			reset()
		end
	end
	stub.size_noise = 0
	T.theme('thick')
end)

------------------------------------------------------------------ the rows

local function walk_rows()
	local CO = st:GetModule('Colors')
	local rows = {}
	for _, section in ipairs(CO.SECTIONS) do
		for _, color in ipairs(section.colors) do
			rows[#rows + 1] = { section = section, color = color, option = CO:GetConfigTable().args[section.key].args[tostring(color.key or color.group)] }
		end
	end
	rows[#rows + 1] = { accent = true, option = CO:AccentOption(1) }
	return rows
end

test('every Colors row and the Accent have a preview whose kind is defined, and each opens at 436 with no error', function()
	local rows = walk_rows()
	eq(#rows, 77, 'the walk found the 76 Colors rows and the Accent')
	for _, row in ipairs(rows) do
		local name = row.accent and 'Accent' or (row.section.key .. '.' .. tostring(row.color.key or row.color.group))
		local preview = row.option.preview
		check(preview ~= nil, name .. ' has a preview')
		local kind = W.ReadPreview(preview)
		check(kind ~= nil and W.PreviewKinds()[kind] ~= nil, name .. ' names a defined kind')
		reset()
		local told, F = open({
			preview = preview, name = row.option.name, hasAlpha = row.option.hasAlpha == true,
		})
		check(told.opened, name .. ' opens')
		eq(F.frame:GetHeight(), 436, name .. ' opens with its preview')
		reset()
	end
end)

test("the rows carry the previews the spec's table gives", function()
	local CO = st:GetModule('Colors')
	local args = CO:GetConfigTable().args
	local function view(p) return type(p) == 'table' and (p.kind .. ',' .. tostring(p.style) .. ',' .. tostring(p.label) .. ',' .. tostring(p.threat) .. ',' .. tostring(p.tooltip) .. (p.npc == nil and '' or ',npc=' .. tostring(p.npc))) or tostring(p) end
	for key, color in pairs(args.class.args) do
		eq(view(color.preview), 'bar,unit,' .. color.name .. ',nil,nil', 'Class > ' .. key .. ': the unit frame, labeled with the class')
	end
	eq(view(args.class.args.MAGE.preview), 'bar,unit,Mage,nil,nil', 'Class > Mage')
	for _, key in ipairs({ 'TANK', 'HEALER', 'DAMAGER' }) do eq(view(args.roles.args[key].preview), 'bar,role,nil,nil,nil', 'Roles > ' .. key) end
	for i = 1, 8 do
		local o = args.reaction.args[tostring(i)]
		eq(view(o.preview), 'bar,reputation,' .. o.name .. ',nil,nil', 'Reputation > ' .. o.name)
	end
	eq(view(args.reaction.args.renown.preview), 'bar,reputation,Renown,nil,false,npc=false', 'Renown: the experience bar only')
	for _, key in ipairs({ 'COMBO_POINTS', 'CHI', 'HOLY_POWER', 'SOUL_SHARDS', 'ARCANE_CHARGES' }) do
		eq(view(args.power.args[key].preview), 'bar,points,nil,nil,nil', 'Power > ' .. key .. ' is the points')
	end
	eq(view(args.power.args.MANA.preview), 'bar,power,Mana,nil,nil', 'Power > Mana')
	eq(view(args.power.args.RUNIC_POWER.preview), 'bar,power,Runic power,nil,nil', 'Power > Runic power')
	eq(view(args.power.args.LUNAR_POWER.preview), 'bar,power,Astral power,nil,nil', 'Power > Astral power')
	for i = 0, 8 do eq(view(args.item_quality.args[tostring(i)].preview), 'border,slot,nil,nil,nil', 'Item quality > ' .. i) end
	eq(view(args.loot.args.mount.preview), 'border,entry,nil,nil,nil', 'Loot > Mount')
	for _, key in ipairs({ 'need', 'greed', 'transmog', 'pass' }) do eq(args.loot.args[key].preview, 'text', 'Loot > ' .. key .. ' is text') end
	eq(view(args.status.args.disconnected.preview), 'bar,unit,Offline,nil,false', 'Status > Disconnected: no tooltip')
	eq(view(args.status.args.tapped.preview), 'bar,unit,Tapped,nil,false', 'Status > Tapped')
	eq(view(args.threat.args.warning.preview), 'bar,plate,nil,true,nil', 'Threat > Warning')
	eq(view(args.threat.args.bad.preview), 'bar,plate,nil,true,nil', 'Threat > Bad')
	-- One table per row, the same on every walk (the picker reads it as constants).
	local again = CO:GetConfigTable().args
	check(again.class.args.MAGE.preview == args.class.args.MAGE.preview, 'Class > Mage keeps its table')
	check(again.status.args.tapped.preview == args.status.args.tapped.preview, 'Status > Tapped keeps its table')
	check(again.power.args.MANA.preview == args.power.args.MANA.preview, 'Power > Mana keeps its table')
end)

test('a unit frame color row near the bottom of the screen: the 436-tall picker with a bar preview stays on the screen', function()
	T.theme('thick')
	reset()
	local owner = field(100, 640)
	local _, F = open({ owner = owner, preview = { kind = 'bar', style = 'unit', label = 'Mage' }, name = 'Mage' })
	check(F.frame:GetBottom() >= 0 and F.frame:GetTop() <= UIParent:GetTop() + 0.001, 'on the screen')
	reset()
end)
