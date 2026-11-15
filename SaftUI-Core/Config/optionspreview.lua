local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The color picker's preview (st.OptionsWidgets; loads right after
	optionscolorpicker.lua, which draws the area and calls what is here): a
	strip under the picker's color square that shows the color being edited in
	context, built from SaftUI's own frames, drawn by the theme engine as they
	are drawn in the UI. Which kind of preview an option gets is its own
	choice: a `preview` field on the color option.

	  preview = 'text'                         a kind's name, or
	  preview = { kind = 'text', sample = '(Horde territory)' }
	                                           a table whose `kind` names it and
	                                           whose other fields are that kind's own.

	`preview` is SaftUI's own field on a color option, read raw from the row's
	option and never inherited (as `toggle` is); the color type's Pick hands it
	to W.OpenColorPicker as spec.preview, with the row's name as spec.name. A
	value that is neither a name nor a table with a string kind, and a name no
	kind has, show no preview and never error: the picker opens as it does for
	an option with none. There is no function form.

	  W.DefinePreview(name, def) -> boolean
	      def = { Build = fn(area, width, height) -> pieces,
	              Paint = fn(pieces, r, g, b, a, spec),
	              Layout = fn(pieces, width, height, spec) (optional),
	              note = string | fn(blizzard, spec) -> string | nil (optional) }.
	      false for a built-in kind's name, or a def without Build and Paint;
	      a module adds a kind of its own this way (and may define it again).
	      Build runs the first time the kind shows, with an area (a frame the size
	      of the preview strip: width x height, 370 by 64, or 402 with an opacity)
	      to draw its pieces in, and returns its pieces, which are kept: the area
	      is hidden while another kind shows. Paint runs as the picker opens
	      and on every change of the color, with the color being chosen (a is the
	      opacity, 1 without hasAlpha), and again when a recolor or a redraw of
	      the theme took the preview's own colors off its frames (st:KeepOwnColors)
	      and when Text changes (the picker follows Text); it reads every other
	      color through st:Color, and sets colors only (the cost of a pass: 24
	      setter calls at most, nothing made). spec = { fields = <the option's
	      preview table, or {}>, name = <the option's name>, hasAlpha = boolean },
	      one table for as long as the picker is open. Layout, when there is one,
	      places the pieces for a strip width x height and shows or hides them
	      for the option's style (spec.fields): Paint may not Show or Hide. It
	      runs whenever the picker opens (the width differs with an opacity) and
	      again, once, when the theme flips between Blizzard's look and SaftUI's
	      with the picker open (on the theme pass, never in a color pass). note is
	      shown at the right of the "Preview" caption, in Muted; a function gets
	      whether Blizzard's look is in use and the spec, and is called at each
	      layout. A Paint that errors is reported once per opening and not run
	      again in it; a Build or Layout that errors opens the picker with no
	      preview.
	  W.ReadPreview(value) -> name, fields | nil
	      'text' -> 'text', {}; { kind = 'bar', style = 'unit' } -> 'bar' and that
	      table; anything else, or a name no kind has, -> nil.
	  W.PreviewKinds() -> { [name] = def }, for tests.
	  W.PREVIEW: the numbers (below).

	The built-in kinds are recorded at the end of this file (as
	optionsposition.lua records the built-in types): W.DefinePreview refuses
	their names.

	The text kind: three tiles 118 by 44 (the first at the strip's left edge, the
	last at its right edge, the middle one between them), drawn with
	st:SetTemplate as panels: thick/solid, thin/solid and theme/options, the
	last on a strip of the stand-in for the game world (docs/design-system's
	`world`, #2f3324) so its see-through shows. Each has "Text" in Text > Normal
	beside the sample, in the color being chosen; its caption below it is in Text >
	Muted. The sample is the field's own `sample`, else the option's name. A long
	sample wraps to a second line; it never passes the tile.
]]

local floor = math.floor

------------------------------------------------------------------ the numbers

-- The strip under the square (the picker's placement A): the caption at
-- CAPTION_Y, the area at Y, HEIGHT tall, and the picker 94 taller (ROOM): the
-- caption's row, the area, and the 12 between it and Last used.
W.PREVIEW = {
	CAPTION_Y = 248, Y = 266, HEIGHT = 64, ROOM = 94,
	GAP = 8, TILE_HEIGHT = 44, CAPTION_GAP = 6, TILE_WIDTH = 118,
}
local PV = W.PREVIEW

local CAPTION_SIZE = 13 -- the picker's own captions'
local WORLD = { 47 / 255, 51 / 255, 36 / 255, 1 } -- #2f3324

------------------------------------------------------------------ the kinds

local kinds, builtin = {}, {}

function W.DefinePreview(name, def)
	if type(name) ~= 'string' or type(def) ~= 'table' or builtin[name] then return false end
	if type(def.Build) ~= 'function' or type(def.Paint) ~= 'function' then return false end
	kinds[name] = def
	return true
end

function W.ReadPreview(value)
	local name, fields
	if type(value) == 'string' then
		name, fields = value, {}
	elseif type(value) == 'table' and type(value.kind) == 'string' then
		name, fields = value.kind, value
	else
		return nil
	end
	if not kinds[name] then return nil end
	return name, fields
end

function W.PreviewKinds() return kinds end

------------------------------------------------------------------ the text kind

local TEXT_TILES = {
	{ theme = 'thick', background = 'solid', caption = 'Thick' },
	{ theme = 'thin', background = 'solid', caption = 'Thin' },
	{ theme = 'theme', background = 'options', caption = 'Options windows' },
}
local TILE_PAD, PAIR_GAP = 8, 8 -- the pair's room either side in a tile; between "Text" and the sample

local function TextFont(fs)
	Kit.SetFieldFont(fs, nil, CAPTION_SIZE)
	return fs
end

local text = {}

function text.Build(area)
	local pieces = { area = area, tiles = {}, labels = {}, samples = {}, captions = {}, shown = {} }
	local tileWidth = PV.TILE_WIDTH
	for i, entry in ipairs(TEXT_TILES) do
		local tile = st:CreateFrame('Frame', nil, area)
		tile:SetSize(tileWidth, PV.TILE_HEIGHT)
		st:SetTemplate(tile, entry.theme, entry.background, 'panel')
		pieces.tiles[i] = tile

		local label = TextFont(Kit.NewText(tile, 'LEFT'))
		label:SetText('Text')
		pieces.labels[i] = label

		local sample = TextFont(Kit.NewText(tile, 'LEFT'))
		sample:SetWordWrap(true)
		sample:SetMaxLines(2)
		pieces.samples[i] = sample

		local caption = TextFont(Kit.NewText(area, 'CENTER'))
		caption:SetPoint('TOP', tile, 'BOTTOM', 0, -PV.CAPTION_GAP)
		caption:SetWidth(tileWidth)
		caption:SetText(entry.caption)
		pieces.captions[i] = caption
	end
	-- The Options windows tile's see-through shows this, as the game would.
	local world = area:CreateTexture(nil, 'BACKGROUND')
	world:SetColorTexture(unpack(WORLD))
	world:SetPoint('TOPLEFT', pieces.tiles[3], 'TOPLEFT', 0, 0)
	world:SetPoint('BOTTOMRIGHT', pieces.tiles[3], 'BOTTOMRIGHT', 0, 0)
	pieces.world = world
	return pieces
end

-- The first tile at the strip's left, the last at its right, the middle one
-- between them (whole units: both are even).
-- The sample: the field's own, else the option's name.
local function SampleOf(spec)
	local sample = spec.fields.sample
	if type(sample) ~= 'string' then sample = spec.name end
	if type(sample) ~= 'string' then sample = '' end
	return sample
end

-- "Text" and the sample are a pair centered in each tile, a gap apart: the
-- sample as wide as it is, or the room that is left when it wraps to two lines.
function text.Layout(pieces, width, _, spec)
	local tileWidth = PV.TILE_WIDTH
	local x = { 0, floor((width - tileWidth) / 2), width - tileWidth }
	local sample = SampleOf(spec)
	local label, shown = pieces.labels[1], pieces.samples[1]
	local labelWidth = math.ceil(label:GetStringWidth())
	local room = tileWidth - 2 * TILE_PAD - labelWidth - PAIR_GAP
	-- Measured on one line with no width of its own, then wrapped again.
	shown:SetWordWrap(false)
	shown:SetWidth(0)
	shown:SetText(sample)
	local sampleWidth = math.min(room, math.ceil(shown:GetStringWidth()))
	shown:SetWordWrap(true)
	local start = floor((tileWidth - (labelWidth + PAIR_GAP + sampleWidth)) / 2)
	for i, tile in ipairs(pieces.tiles) do
		tile:ClearAllPoints()
		tile:SetPoint('TOPLEFT', pieces.area, 'TOPLEFT', x[i], 0)
		pieces.labels[i]:ClearAllPoints()
		pieces.labels[i]:SetPoint('LEFT', tile, 'LEFT', start, 0)
		local fs = pieces.samples[i]
		fs:ClearAllPoints()
		fs:SetPoint('LEFT', tile, 'LEFT', start + labelWidth + PAIR_GAP, 0)
		fs:SetWidth(sampleWidth)
		fs:SetText(sample)
		pieces.shown[i] = sample
	end
end

function text.Paint(pieces, r, g, b, _, spec)
	local sample = SampleOf(spec)
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	for i = 1, #pieces.tiles do
		pieces.labels[i]:SetTextColor(nr, ng, nb)
		local fs = pieces.samples[i]
		if pieces.shown[i] ~= sample then
			pieces.shown[i] = sample
			fs:SetText(sample)
		end
		fs:SetTextColor(r, g, b)
		pieces.captions[i]:SetTextColor(mr, mg, mb)
	end
end

kinds.text = text

------------------------------------------------------------------ shared by the button and accent kinds

-- Places piece by its top left, x across and y down from parent's.
local function Put(piece, parent, x, y)
	piece:ClearAllPoints()
	piece:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, -y)
end

-- A color of group, at a strength: the edited one when key is the one being
-- edited (the picker's color, a its opacity as shown), else the profile's.
local function Shade(group, key, factor, edited, r, g, b, a)
	if key == edited then return r, g, b, a * factor end
	return st:ColorRGBA(group, key, factor)
end

-- A tile: a panel frame width x TILE_HEIGHT with its caption under it.
local function NewTile(area, width, theme, caption)
	local tile = st:CreateFrame('Frame', nil, area)
	tile:SetSize(width, PV.TILE_HEIGHT)
	st:SetTemplate(tile, theme, 'solid', 'panel')
	local label = TextFont(Kit.NewText(area, 'CENTER'))
	label:SetPoint('TOP', tile, 'BOTTOM', 0, -PV.CAPTION_GAP)
	label:SetWidth(width)
	label:SetText(caption)
	return tile, label
end

-- N tiles of one width across a strip, the first at its left edge and the last
-- at its right: x(i) = floor((i - 1) * (width - tile) / (n - 1)).
local function TileX(i, n, width, tile)
	return floor((i - 1) * (width - tile) / (n - 1))
end

------------------------------------------------------------------ the button kind

--[[
	Five tiles of the states a Buttons color reaches, each piece the real one at
	its reader's strength times the opacity (docs/superpowers/specs/
	2026-11-15-saftui-live-colors-design.md, Part B):
	  Rest     a SaftUI button at rest; a scroll bar thumb at rest (Normal)
	  Hover    the button's highlight held by LockHighlight (Normal); a thumb
	           under the mouse (Hover)
	  Pressed  the button pushed by SetButtonState('PUSHED', true) (Pushed); a
	           pressed thumb (Pushed)
	  Checked  a check box, checked (Hover)
	  Flash    an action button's attack flash at 0.4 and an unbought bank
	           slot's tint at 0.3 (Danger)
	fields.key is the Buttons key edited: the pieces it reaches take the picked
	color and their captions are in Text, the rest are the profile's with their
	captions in Muted. Under Blizzard SaftUI's buttons wear Blizzard's art and
	draw no Buttons color, so the pieces are drawn as Thick, with a note. No
	piece takes the mouse (a held state stays held).
]]
local BUTTON_TILE = 74
local BUTTON_NAMES = { 'Rest', 'Hover', 'Pressed', 'Checked', 'Flash' }
-- The tiles each key reaches (their captions are in Text).
local BUTTON_REACHES = {
	normal = { true, true },
	hover = { [2] = true, [4] = true },
	pushed = { [3] = true },
	danger = { [5] = true },
}
local FLASH_ALPHA, LOCKED_ALPHA = 0.4, 0.3 -- ActionBars' skin.lua; Bags' bank.lua
-- The mockup's sizes (color-preview-v1.html): a thumb 6 by 28 and a button 20 tall, 8 from the
-- tile's edges; the check box 12; the flash button 30 and the bank slot 20.
local THUMB_WIDTH, THUMB_HEIGHT, BUTTON_HEIGHT, CHECK_SIZE, FLASH_SIZE, LOCKED_SIZE = 6, 28, 20, 12, 30, 20

local button = {}

button.note = function(blizzard)
	if blizzard then return "Shown as Thick: under Blizzard, SaftUI's buttons wear Blizzard's art." end
end

-- The theme the tiles and pieces are drawn in: the one in use, else Thick under Blizzard.
local function ButtonLook() return W.BlizzardLook() and 'thick' or 'theme' end

function button.Build(area)
	local look = ButtonLook()
	local pieces = { area = area, look = look, tiles = {}, captions = {}, buttons = {}, thumbs = {} }
	for i, name in ipairs(BUTTON_NAMES) do
		pieces.tiles[i], pieces.captions[i] = NewTile(area, BUTTON_TILE, look, name)
	end
	for i = 1, 3 do
		local tile = pieces.tiles[i]
		local b = st:CreateButton(nil, tile, 'Okay', look, 'solid')
		b:SetSize(BUTTON_TILE - 30, BUTTON_HEIGHT)
		b:EnableMouse(false)
		pieces.buttons[i] = b
		local thumb = st:CreateFrame('Frame', nil, tile)
		thumb:SetSize(THUMB_WIDTH, THUMB_HEIGHT)
		st:SetBackdrop(thumb, look, 'solid', 'control')
		thumb:EnableMouse(false)
		pieces.thumbs[i] = thumb
	end
	pieces.buttons[2]:LockHighlight()
	pieces.buttons[3]:SetButtonState('PUSHED', true)

	local check = st:CreateFrame('CheckButton', nil, pieces.tiles[4])
	st:SkinCheckButton(check, 'bare') -- no box of its own: drawn below, Thick under Blizzard
	check:SetSize(CHECK_SIZE, CHECK_SIZE)
	st:SetBackdrop(check, look, 'solid', 'control')
	check:SetChecked(true)
	check:EnableMouse(false)
	pieces.check, pieces.checked = check, check:GetCheckedTexture()
	pieces.checkLabel = TextFont(Kit.NewText(pieces.tiles[4], 'LEFT'))
	pieces.checkLabel:SetText('Bags')

	local function Slot(tile, size)
		local slot = st:CreateFrame('Frame', nil, tile)
		slot:SetSize(size, size)
		st:SetBackdrop(slot, look, 'solid', 'slot')
		local veil = slot:CreateTexture(nil, 'OVERLAY')
		veil:SetAllPoints(slot)
		veil:SetColorTexture(0, 0, 0, 0)
		return slot, veil
	end
	pieces.flashSlot, pieces.flash = Slot(pieces.tiles[5], FLASH_SIZE)
	pieces.lockedSlot, pieces.locked = Slot(pieces.tiles[5], LOCKED_SIZE)
	return pieces
end

function button.Layout(pieces, width)
	local look = ButtonLook()
	if pieces.look ~= look then
		pieces.look = look
		for _, tile in ipairs(pieces.tiles) do st:SetTemplate(tile, look, 'solid', 'panel') end
		for _, b in ipairs(pieces.buttons) do st:SkinButton(b, look, 'solid') end
		for _, thumb in ipairs(pieces.thumbs) do st:SetBackdrop(thumb, look, 'solid', 'control') end
		st:SetBackdrop(pieces.check, look, 'solid', 'control')
		st:SetBackdrop(pieces.flashSlot, look, 'solid', 'slot')
		st:SetBackdrop(pieces.lockedSlot, look, 'solid', 'slot')
	end
	-- Five tiles 8 apart (74 wide with an opacity, narrower in a strip without one).
	local tw = math.min(BUTTON_TILE, floor((width - 4 * PV.GAP) / 5))
	local gap = floor((width - 5 * tw) / 4)
	for i, tile in ipairs(pieces.tiles) do
		tile:SetSize(tw, PV.TILE_HEIGHT)
		Put(tile, pieces.area, (i - 1) * (tw + gap), 0)
		pieces.captions[i]:SetWidth(tw)
	end
	local thumbX = tw - 8 - THUMB_WIDTH
	for i = 1, 3 do
		local tile = pieces.tiles[i]
		pieces.buttons[i]:SetSize(thumbX - 16, BUTTON_HEIGHT)
		Put(pieces.buttons[i], tile, 8, floor((PV.TILE_HEIGHT - BUTTON_HEIGHT) / 2))
		Put(pieces.thumbs[i], tile, thumbX, floor((PV.TILE_HEIGHT - THUMB_HEIGHT) / 2))
	end
	local checkY = floor((PV.TILE_HEIGHT - CHECK_SIZE) / 2)
	Put(pieces.check, pieces.tiles[4], 14, checkY)
	pieces.checkLabel:ClearAllPoints()
	pieces.checkLabel:SetPoint('LEFT', pieces.tiles[4], 'LEFT', 14 + CHECK_SIZE + 6, 0)
	Put(pieces.flashSlot, pieces.tiles[5], 8, floor((PV.TILE_HEIGHT - FLASH_SIZE) / 2))
	Put(pieces.lockedSlot, pieces.tiles[5], 8 + FLASH_SIZE + 6, floor((PV.TILE_HEIGHT - LOCKED_SIZE) / 2))
end

function button.Paint(pieces, r, g, b, a, spec)
	local key = spec.fields.key
	local thumbs, buttons = pieces.thumbs, pieces.buttons
	thumbs[1].backdrop:SetBackdropColor(Shade('button', 'normal', 1, key, r, g, b, a))
	thumbs[2].backdrop:SetBackdropColor(Shade('button', 'hover', 1, key, r, g, b, a))
	thumbs[3].backdrop:SetBackdropColor(Shade('button', 'pushed', 1, key, r, g, b, a))
	buttons[2].hover:SetVertexColor(Shade('button', 'normal', 1, key, r, g, b, a))
	buttons[3].pushed:SetVertexColor(Shade('button', 'pushed', 1, key, r, g, b, a))
	pieces.checked:SetVertexColor(Shade('button', 'hover', 1, key, r, g, b, a))
	pieces.flash:SetColorTexture(Shade('button', 'danger', FLASH_ALPHA, key, r, g, b, a))
	pieces.locked:SetColorTexture(Shade('button', 'danger', LOCKED_ALPHA, key, r, g, b, a))
	local reaches = BUTTON_REACHES[key]
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	pieces.checkLabel:SetTextColor(nr, ng, nb)
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	for i = 1, #BUTTON_NAMES do
		if reaches and reaches[i] then
			pieces.captions[i]:SetTextColor(nr, ng, nb)
		else
			pieces.captions[i]:SetTextColor(mr, mg, mb)
		end
	end
end

kinds.button = button

------------------------------------------------------------------ the accent kind

--[[
	Four tiles of what the accent colors. Under SaftUI's looks, the kit's own
	controls: a field's edge as under the mouse (W.Box, W.Edge), a ticked
	Kit.CheckBox, a slider's track and fill (as optionsrange.lua draws them), a
	selected sidebar row (its 25% tint and 2 wide bar, as optionsnav.lua).
	Under Blizzard, where those controls wear Blizzard's art and draw no accent:
	a link, a picked list entry, an own mark (an option you changed) and a
	selected mover's edge. Tile captions are in Muted. Four tiles 88 wide,
	the first at the strip's left edge and the last at its right.
]]
local ACCENT_TILE = 88
local ACCENT_NAMES = { 'Field edge', 'Check box', 'Slider', 'Sidebar row' }
local ACCENT_ALT_NAMES = { 'Link', 'Picked entry', 'Own mark', 'Mover' }
local TRACK_WIDTH, KNOB_WIDTH, KNOB_HEIGHT = 64, 6, 14

local accent = {}

local function AccentText(tile, text)
	local fs = TextFont(Kit.NewText(tile, 'LEFT'))
	fs:SetText(text)
	return fs
end

local function Texture(tile, layer, sublevel, w, h, x, y)
	local t = tile:CreateTexture(nil, layer, nil, sublevel or 0)
	t:SetColorTexture(0, 0, 0, 0)
	t:SetSize(w, h)
	Put(t, tile, x, y)
	return t
end

function accent.Build(area)
	local pieces = { area = area, tiles = {}, captions = {}, altTiles = {}, altCaptions = {}, alt = false }
	for i = 1, 4 do
		pieces.tiles[i], pieces.captions[i] = NewTile(area, ACCENT_TILE, 'theme', ACCENT_NAMES[i])
		pieces.altTiles[i], pieces.altCaptions[i] = NewTile(area, ACCENT_TILE, 'theme', ACCENT_ALT_NAMES[i])
	end
	local tiles, alt = pieces.tiles, pieces.altTiles

	-- A field's edge, as under the mouse.
	local edge = W.Box(st:CreateFrame('Frame', nil, tiles[1]))
	edge:SetSize(60, 22)
	Put(edge, tiles[1], 14, 11)
	W.Edge(edge, true)
	pieces.edge = edge

	-- A ticked check box.
	local box = Kit.CheckBox(tiles[2], 18)
	box:EnableMouse(false)
	Put(box, tiles[2], floor((ACCENT_TILE - 18) / 2), 13)
	Kit.SetCheck(box, true)
	pieces.box = box

	-- A slider's track and fill (half way), and its knob.
	local sx = floor((ACCENT_TILE - TRACK_WIDTH) / 2)
	Texture(tiles[3], 'BACKGROUND', 0, TRACK_WIDTH + 2, 8, sx - 1, 18):SetColorTexture(unpack(Kit.ALT))
	Texture(tiles[3], 'BORDER', 0, TRACK_WIDTH, 6, sx, 19):SetColorTexture(unpack(Kit.EDGE))
	Texture(tiles[3], 'BORDER', 1, TRACK_WIDTH - 2, 4, sx + 1, 20):SetColorTexture(unpack(Kit.FIELD))
	pieces.fill = Texture(tiles[3], 'ARTWORK', 0, floor((TRACK_WIDTH - 2) / 2), 4, sx + 1, 20)
	pieces.knob = Texture(tiles[3], 'OVERLAY', 0, KNOB_WIDTH, KNOB_HEIGHT, sx + 1 + floor((TRACK_WIDTH - 2) / 2) - KNOB_WIDTH / 2, 15)

	-- A selected sidebar row: the tint over it and the bar at its left.
	pieces.rowTint = Texture(tiles[4], 'ARTWORK', 0, ACCENT_TILE - 12, 22, 6, 11)
	pieces.rowBar = Texture(tiles[4], 'ARTWORK', 1, 2, 22, 6, 11)
	pieces.rowText = AccentText(tiles[4], 'Page')
	pieces.rowText:SetPoint('LEFT', tiles[4], 'LEFT', 16, 0)

	-- Under Blizzard: a link.
	pieces.link = AccentText(alt[1], 'Link')
	pieces.link:SetPoint('CENTER', alt[1], 'CENTER', 0, 0)
	-- A picked list entry under another.
	pieces.option = AccentText(alt[2], 'Entry')
	pieces.option:SetPoint('TOPLEFT', alt[2], 'TOPLEFT', 14, -9)
	pieces.picked = AccentText(alt[2], 'Picked')
	pieces.picked:SetPoint('TOPLEFT', alt[2], 'TOPLEFT', 14, -24)
	-- An own mark: the mark at a changed option's left, and its label.
	pieces.mark = Texture(alt[3], 'ARTWORK', 0, 3, 22, 10, 11)
	pieces.markLabel = AccentText(alt[3], 'Changed')
	pieces.markLabel:SetPoint('LEFT', alt[3], 'LEFT', 20, 0)
	-- A selected mover: its edge and tint.
	local mover = st:CreateFrame('Frame', nil, alt[4])
	mover:SetSize(60, 26)
	Put(mover, alt[4], 14, 9)
	st:SetBackdrop(mover, 'thick', 'solid', 'small')
	pieces.mover = mover
	return pieces
end

function accent.Layout(pieces, width)
	local blizzard = W.BlizzardLook() and true or false
	pieces.alt = blizzard
	for i = 1, 4 do
		local x = TileX(i, 4, width, ACCENT_TILE)
		for _, set in ipairs({ { pieces.tiles, pieces.captions, not blizzard }, { pieces.altTiles, pieces.altCaptions, blizzard } }) do
			local tile, caption = set[1][i], set[2][i]
			Put(tile, pieces.area, x, 0)
			tile:SetShown(set[3])
			caption:SetShown(set[3])
		end
	end
end

function accent.Paint(pieces, r, g, b, a)
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	if pieces.alt then
		for i = 1, 4 do pieces.altCaptions[i]:SetTextColor(mr, mg, mb) end
		pieces.option:SetTextColor(nr, ng, nb)
		pieces.link:SetTextColor(r, g, b)
		pieces.picked:SetTextColor(r, g, b)
		pieces.mark:SetColorTexture(r, g, b, 1)
		pieces.markLabel:SetTextColor(r, g, b)
		pieces.mover.backdrop:SetBackdropColor(r, g, b, st.TINT_OBJECT)
		st:SetBorderColor(pieces.mover.backdrop, r, g, b, 1)
		return
	end
	for i = 1, 4 do pieces.captions[i]:SetTextColor(mr, mg, mb) end
	pieces.edge:SetBackdropBorderColor(r, g, b, 1)
	pieces.box.mark:SetColorTexture(r, g, b, 1)
	pieces.fill:SetColorTexture(r, g, b, 1)
	pieces.knob:SetColorTexture(nr, ng, nb, 1)
	pieces.rowTint:SetColorTexture(r, g, b, st.TINT_ROW)
	pieces.rowBar:SetColorTexture(r, g, b, 1)
	pieces.rowText:SetTextColor(nr, ng, nb)
end

kinds.accent = accent

------------------------------------------------------------------ the built-in kinds

-- Last: the kinds above are the built-in ones. Tasks that add a kind add it here
-- before this loop.
for name in pairs(kinds) do builtin[name] = true end
