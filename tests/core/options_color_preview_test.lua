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
