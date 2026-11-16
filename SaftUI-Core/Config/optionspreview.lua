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
		caption:SetWordWrap(false) -- a wide Text face cuts a caption at its end, never onto a second line
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
	label:SetWordWrap(false) -- as the text kind's captions
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
	  Rest     a scroll bar thumb at rest (Normal)
	  Hover    the button's highlight held by LockHighlight (Hover at 0.4,
	           st.HOVER_TINT); a thumb under the mouse (Hover)
	  Pressed  the button pushed by SetButtonState('PUSHED', true) (Pushed); a
	           pressed thumb (Pushed)
	  Checked  a check box, checked (Checked)
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
	normal = { true },
	hover = { [2] = true },
	pushed = { [3] = true },
	checked = { [4] = true },
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

-- The second button shows held under the mouse, the third pressed: the helpers' states
-- (st:SetState), not game textures. Hiding a button (the picker closing) clears them, so
-- they are held again whenever the kind is laid out.
local function HoldStates(pieces)
	st:SetState(pieces.buttons[2], 'hover', true)
	st:SetState(pieces.buttons[3], 'pushed', true)
end

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
	HoldStates(pieces)

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
	HoldStates(pieces)
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
	local left = floor((width - (5 * tw + 4 * gap)) / 2) -- spare units split either side
	for i, tile in ipairs(pieces.tiles) do
		tile:SetSize(tw, PV.TILE_HEIGHT)
		Put(tile, pieces.area, left + (i - 1) * (tw + gap), 0)
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
	-- st:SkinButton keeps no highlight or pushed texture any more: the buttons' states are
	-- drawn by the helpers (Task 9 replaces this kind), so these two follow only an old one
	if buttons[2].hover then buttons[2].hover:SetVertexColor(Shade('button', 'hover', st.HOVER_TINT, key, r, g, b, a)) end
	if buttons[3].pushed then buttons[3].pushed:SetVertexColor(Shade('button', 'pushed', 1, key, r, g, b, a)) end
	pieces.checked:SetVertexColor(Shade('button', 'checked', 1, key, r, g, b, a))
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
	the edit mode grid's centre lines (a selected mover wears Blizzard's art
	there, not the accent). Tile captions are in Muted. Four tiles 88 wide,
	the first at the strip's left edge and the last at its right.
]]
local ACCENT_TILE = 88
local ACCENT_NAMES = { 'Field edge', 'Check box', 'Slider', 'Sidebar row' }
local ACCENT_ALT_NAMES = { 'Link', 'Picked entry', 'Own mark', 'Grid centre' }
-- The slider's track is shorter than the range's (116); the knob and the own mark are the kit's.
local TRACK_WIDTH = 64
local GRID_CENTER_ALPHA, GRID_LINE = 0.9, { 1, 1, 1, 0.12 } -- EditMode/grid.lua's CENTER_ALPHA and LINE_COLOR (copies: it exports none)

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
	pieces.knob = Texture(tiles[3], 'OVERLAY', 0, Kit.KNOB_WIDTH, Kit.KNOB_HEIGHT, sx + 1 + floor((TRACK_WIDTH - 2) / 2) - Kit.KNOB_WIDTH / 2, 15)

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
	pieces.mark = Texture(alt[3], 'ARTWORK', 0, st.OptionsBody.MARK_WIDTH, 22, 10, 11)
	pieces.markLabel = AccentText(alt[3], 'Changed')
	pieces.markLabel:SetPoint('LEFT', alt[3], 'LEFT', 20, 0)
	-- Edit mode's grid: faint lines and the two centre lines in the accent (the
	-- accent under every theme; a selected mover wears Blizzard's art instead).
	local cx, cy = floor(ACCENT_TILE / 2), floor(PV.TILE_HEIGHT / 2)
	for _, x in ipairs({ cx - 22, cx + 22 }) do
		Texture(alt[4], 'ARTWORK', 0, 1, PV.TILE_HEIGHT - 8, x, 4):SetColorTexture(unpack(GRID_LINE))
	end
	pieces.gridV = Texture(alt[4], 'ARTWORK', 1, 1, PV.TILE_HEIGHT - 8, cx, 4)
	pieces.gridH = Texture(alt[4], 'ARTWORK', 1, ACCENT_TILE - 8, 1, 4, cy)
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
		pieces.gridV:SetColorTexture(r, g, b, GRID_CENTER_ALPHA)
		pieces.gridH:SetColorTexture(r, g, b, GRID_CENTER_ALPHA)
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

------------------------------------------------------------------ the bar and border kinds

--[[
	Cells of the pieces a color reaches, drawn by the engine as the UI draws
	them, filled to 70% where there is a fill. A cell is a holder (the cell's
	width by TILE_HEIGHT, nothing drawn on it) with its caption under it in
	Text > Muted; a style shows its cells side by side, 8 apart, centered in the
	strip, and hides the rest. Cells are built once for every style of the kind,
	laid out and shown by Layout (spec.fields.style), and painted by Paint for
	the style shown only.

	bar (fields: style, label, threat, tooltip, npc):
	  unit        a unit frame's health bar 200 by 28 (label at its left, 70% at its
	              right), a raid frame 80 by 40 (the label), a unit tooltip 74 by 44
	              with the label as its name and its border in the color; tooltip =
	              false leaves the tooltip out (Status colors only color health);
	  role        a raid frame 80 by 40 with the role corner (st.textures.cornerbr,
	              16, at the bar's bottom right corner, 2 out, as the Roles default);
	  reputation  the experience bar's reputation bar (150 by 13), an NPC's
	              health bar (100 by 28) and an NPC's tooltip (74 by 44, its name
	              and border in the color), each with the label; npc = false
	              leaves the health bar out and tooltip = false the tooltip (Renown:
	              only the experience bar and the feed's renown line take it, and
	              the feed line is not drawn);
	  power       a health bar 200 by 24 with the power bar 200 by 12 under it, the
	              power bar in the color and the label on it;
	  points      five class power points 34 by 20, 7 apart, three lit; under
	              Blizzard they wear Blizzard's art (no color), so they are drawn as
	              Thick, with a note;
	  plate       a nameplate 200 by 20 with its name; with threat, the percent
	              above its right end in the color (the bar is in it too).
	border (fields: style):
	  slot        a bag slot 36 by 36 (the Slot theme's, an icon inside its
	              border) with its border in the color, and a loot feed line 200 by
	              32 with the item's name in the color;
	  entry       a loot feed entry 250 by 32: its border, its fill at 60% and its
	              icon's border in the color (a fresh mount's).
	The picker's color is the whole of what is edited (none of these colors has
	an opacity): the rest of a cell is the profile's. Bars are st:CreateStatusBar
	(kind bar); a unit frame's own bar is drawn as a unit frame and wears
	Blizzard's tinted fill art, which is Unitframes' and not drawn here. Nothing
	here takes the mouse.
]]
local BAR_FILL = 70 -- every bar is filled to 70%
local GAP_X = 8 -- between cells
local ROLE_SIZE, ROLE_OFFSET = 16, 2 -- the Roles default (config/default.lua)
local FEED_HEIGHT = 32 -- the loot feed's entry (Loot's item_height)
local SLOT_SIZE = 36
local POINT_WIDTH, POINT_HEIGHT, POINT_GAP, POINTS, LIT_POINTS = 34, 20, 7, 5, 3 -- classpower's default spacing
local TOOLTIP_PAD = 7
local STAND_IN_ICON = [[Interface\Icons\INV_Misc_QuestionMark]]

local function Bare(frame) frame:EnableMouse(false); return frame end

-- The class color the unit frames in styles that show another color are in.
local function ClassColor()
	local key = st.my_class
	if not (key and st.config.profile.colors.class[key]) then key = 'MAGE' end
	return st:Color('class', key):GetRGB()
end

-- The label a style shows: the field's, else the option's name.
local function LabelOf(spec)
	local label = spec.fields.label
	if type(label) ~= 'string' then label = spec.name end
	if type(label) ~= 'string' then label = '' end
	return label
end

-- A status bar of SaftUI's, filled to 70%, its own text blank.
local function NewBar(parent, width, height, max)
	local bar = st:CreateStatusBar(nil, parent, '', 'theme', 'solid')
	bar:SetSize(width, height)
	bar:SetMinMaxValues(0, max or 100)
	bar:SetValue(max and 0 or BAR_FILL)
	bar:EnableMouse(false)
	bar.text:SetWordWrap(false) -- its label is cut at its end, never wrapped
	return bar
end

-- A text on bar in the unit frames' own face, at point of it, width wide
-- (every label has one, so a wide face cuts it at its end and never runs it
-- past its bar) and justified to the side it sits on.
local function BarText(bar, point, x, text, width)
	local fs = st:CreateFontString(bar, 'pixel', text)
	fs:SetPoint(point, bar, point, x, 0)
	fs:SetWidth(width)
	fs:SetWordWrap(false)
	fs:SetJustifyH(point)
	return fs
end

-- A unit tooltip 74 by 44 (a tooltip panel) with a name line, whose room is the
-- panel less its padding (cut at its end), and a level line.
local function NewTip(cell, p)
	p.tip = Bare(st:CreateFrame('Frame', nil, cell.holder))
	p.tip:SetSize(74, PV.TILE_HEIGHT)
	st:SetTemplate(p.tip, 'theme', 'solid', 'tooltip')
	Put(p.tip, cell.holder, 0, 0)
	p.label = TextFont(Kit.NewText(p.tip, 'LEFT'))
	p.label:SetPoint('TOPLEFT', p.tip, 'TOPLEFT', TOOLTIP_PAD, -5)
	p.label:SetWidth(74 - 2 * TOOLTIP_PAD)
	p.label:SetWordWrap(false)
	p.level = TextFont(Kit.NewText(p.tip, 'LEFT'))
	p.level:SetPoint('TOPLEFT', p.tip, 'TOPLEFT', TOOLTIP_PAD, -22)
	p.level:SetWidth(74 - 2 * TOOLTIP_PAD)
	p.level:SetWordWrap(false)
	p.level:SetText('Level 70')
end

-- A cell: the holder, with its caption under it. The caption is on the area
-- (it hides with the cell in Layout), centered under the cell.
local function NewCell(pieces, key, width, caption, optional)
	local holder = Bare(st:CreateFrame('Frame', nil, pieces.area))
	holder:SetSize(width, PV.TILE_HEIGHT)
	local label = TextFont(Kit.NewText(pieces.area, 'CENTER'))
	label:SetPoint('TOP', holder, 'BOTTOM', 0, -PV.CAPTION_GAP)
	label:SetWidth(width)
	label:SetWordWrap(false) -- as every tile caption
	label:SetText(caption)
	holder:Hide()
	label:Hide()
	local cell = { holder = holder, caption = label, width = width, optional = optional }
	pieces.cells[key] = cell
	pieces[key] = {}
	return cell, pieces[key]
end

-- Shows the cells of a style, side by side 8 apart and centered in width, and
-- hides the others. The active list is what Paint walks.
local function LayoutCells(pieces, width, order, fields)
	for _, cell in pairs(pieces.cells) do
		cell.holder:Hide()
		cell.caption:Hide()
	end
	local active = pieces.active
	for i = #active, 1, -1 do active[i] = nil end
	local total = 0
	for _, key in ipairs(order or {}) do
		local cell = pieces.cells[key]
		if not (cell.optional and fields and fields[cell.optional] == false) then
			active[#active + 1] = cell
			total = total + cell.width
		end
	end
	if #active == 0 then return end
	total = total + GAP_X * (#active - 1)
	local x = floor((width - total) / 2)
	for _, cell in ipairs(active) do
		Put(cell.holder, pieces.area, x, 0)
		cell.holder:Show()
		cell.caption:Show()
		x = x + cell.width + GAP_X
	end
end

local function PaintCaptions(pieces)
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	for _, cell in ipairs(pieces.active) do cell.caption:SetTextColor(mr, mg, mb) end
end

-- The Thick a piece wears under Blizzard when Blizzard's art draws no color of
-- its own for it, else the theme in use.
local PointLook = ButtonLook

------------------------------------------------------------------ the bar kind

local bar = {}

-- Style -> the cells it shows, in order.
local BAR_STYLES = {
	unit = { 'unitBar', 'unitRaid', 'unitTip' },
	role = { 'roleRaid' },
	reputation = { 'repXp', 'repNpc', 'repTip' },
	power = { 'powerBars' },
	points = { 'pointsRow' },
	plate = { 'plate' },
}

bar.note = function(blizzard, spec)
	if blizzard and spec.fields.style == 'points' then
		return "Shown as Thick: under Blizzard, class power points wear Blizzard's art."
	end
end

function bar.Build(area)
	local pieces = { area = area, cells = {}, active = {} }

	-- unit: the health bar with its label and percent, the raid frame, the tooltip.
	local cell, p = NewCell(pieces, 'unitBar', 200, 'Unit frame')
	p.bar = NewBar(cell.holder, 200, 28)
	Put(p.bar, cell.holder, 0, 8)
	p.label = BarText(p.bar, 'LEFT', 6, nil, 140)
	p.percent = BarText(p.bar, 'RIGHT', -6, '70%', 40)

	cell, p = NewCell(pieces, 'unitRaid', 80, 'Raid frame')
	p.bar = NewBar(cell.holder, 80, 40)
	Put(p.bar, cell.holder, 0, 2)
	p.label = BarText(p.bar, 'CENTER', 0, nil, 72)

	cell, p = NewCell(pieces, 'unitTip', 74, 'Tooltip', 'tooltip')
	NewTip(cell, p)

	-- role: a raid frame with the role corner.
	cell, p = NewCell(pieces, 'roleRaid', 80, 'Raid frame')
	p.bar = NewBar(cell.holder, 80, 40)
	Put(p.bar, cell.holder, 0, 2)
	p.label = BarText(p.bar, 'CENTER', 0, nil, 72)
	p.corner = p.bar:CreateTexture(nil, 'OVERLAY')
	p.corner:SetTexture(st.textures.cornerbr)
	p.corner:SetSize(ROLE_SIZE, ROLE_SIZE)
	p.corner:SetPoint('BOTTOMRIGHT', p.bar, 'BOTTOMRIGHT', ROLE_OFFSET, -ROLE_OFFSET)

	-- reputation: the experience bar's reputation bar and an NPC's health bar.
	cell, p = NewCell(pieces, 'repXp', 150, 'Reputation bar')
	p.bar = NewBar(cell.holder, 150, 13)
	Put(p.bar, cell.holder, 0, floor((PV.TILE_HEIGHT - 13) / 2))
	p.label = p.bar.text
	cell, p = NewCell(pieces, 'repNpc', 100, 'NPC health', 'npc')
	p.bar = NewBar(cell.holder, 100, 28)
	Put(p.bar, cell.holder, 0, 8)
	p.label = p.bar.text
	-- An NPC's tooltip takes the standing's color too (SaftUI-Misc's tooltip.lua).
	cell, p = NewCell(pieces, 'repTip', 74, 'Tooltip', 'tooltip')
	NewTip(cell, p)

	-- power: the health bar and the power bar under it.
	cell, p = NewCell(pieces, 'powerBars', 200, 'Health and power')
	p.health = NewBar(cell.holder, 200, 24)
	Put(p.health, cell.holder, 0, 2)
	p.power = NewBar(cell.holder, 200, 12)
	Put(p.power, cell.holder, 0, 30)
	p.label = p.power.text

	-- points: five class power points, three lit.
	local row = POINTS * POINT_WIDTH + (POINTS - 1) * POINT_GAP
	cell, p = NewCell(pieces, 'pointsRow', row, 'Class power')
	p.look = PointLook()
	p.points = {}
	for i = 1, POINTS do
		local point = NewBar(cell.holder, POINT_WIDTH, POINT_HEIGHT, 1)
		st:SetBackdrop(point, p.look, 'solid', 'control')
		point:SetValue(i <= LIT_POINTS and 1 or 0)
		Put(point, cell.holder, (i - 1) * (POINT_WIDTH + POINT_GAP), 12)
		p.points[i] = point
	end

	-- plate: a nameplate and the threat text above its right end.
	cell, p = NewCell(pieces, 'plate', 200, 'Nameplate')
	p.bar = NewBar(cell.holder, 200, 20)
	Put(p.bar, cell.holder, 0, 20)
	p.name = BarText(p.bar, 'LEFT', 6, 'Wolf', 150)
	p.threat = st:CreateFontString(cell.holder, 'pixel', '85%')
	p.threat:SetPoint('BOTTOMRIGHT', p.bar, 'TOPRIGHT', 0, 6) -- the nameplate's default (threat.position)
	p.threat:SetWidth(40)
	p.threat:SetWordWrap(false)
	p.threat:SetJustifyH('RIGHT')
	return pieces
end

function bar.Layout(pieces, width, _, spec)
	local fields = spec.fields
	local style = fields.style
	pieces.style = BAR_STYLES[style] and style or nil
	LayoutCells(pieces, width, BAR_STYLES[style], fields)
	local label = LabelOf(spec)
	pieces.unitBar.label:SetText(label)
	pieces.unitRaid.label:SetText(label)
	pieces.unitTip.label:SetText(label)
	pieces.roleRaid.label:SetText(label)
	pieces.repXp.label:SetText(label)
	pieces.repNpc.label:SetText(label)
	pieces.repTip.label:SetText(label)
	pieces.powerBars.label:SetText(label)
	local points = pieces.pointsRow
	local look = PointLook()
	if points.look ~= look then
		points.look = look
		for _, point in ipairs(points.points) do st:SetBackdrop(point, look, 'solid', 'control') end
	end
	pieces.plate.threat:SetShown(fields.threat and true or false)
end

local PAINT = {}

function PAINT.unit(p, r, g, b)
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	p.unitBar.bar:SetStatusBarColor(r, g, b)
	p.unitBar.label:SetTextColor(nr, ng, nb)
	p.unitBar.percent:SetTextColor(nr, ng, nb)
	p.unitRaid.bar:SetStatusBarColor(r, g, b)
	p.unitRaid.label:SetTextColor(nr, ng, nb)
	local tip = p.unitTip
	tip.label:SetTextColor(r, g, b)
	tip.level:SetTextColor(nr, ng, nb)
	st:SetBorderColor(tip.tip, r, g, b)
end

function PAINT.role(p, r, g, b)
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	local raid = p.roleRaid
	raid.bar:SetStatusBarColor(ClassColor())
	raid.label:SetTextColor(nr, ng, nb)
	raid.corner:SetVertexColor(r, g, b)
end

function PAINT.reputation(p, r, g, b)
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	local tip = p.repTip
	tip.label:SetTextColor(r, g, b)
	tip.level:SetTextColor(nr, ng, nb)
	st:SetBorderColor(tip.tip, r, g, b)
	p.repXp.bar:SetStatusBarColor(r, g, b)
	p.repXp.label:SetTextColor(nr, ng, nb)
	p.repNpc.bar:SetStatusBarColor(r, g, b)
	p.repNpc.label:SetTextColor(nr, ng, nb)
end

function PAINT.power(p, r, g, b)
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	local bars = p.powerBars
	bars.health:SetStatusBarColor(ClassColor())
	bars.power:SetStatusBarColor(r, g, b)
	bars.label:SetTextColor(nr, ng, nb)
end

function PAINT.points(p, r, g, b)
	local points = p.pointsRow.points
	for i = 1, LIT_POINTS do points[i]:SetStatusBarColor(r, g, b) end
end

function PAINT.plate(p, r, g, b)
	local plate = p.plate
	plate.bar:SetStatusBarColor(r, g, b)
	plate.name:SetTextColor(st:Color('text', 'danger'):GetRGB())
	plate.threat:SetTextColor(r, g, b)
end

function bar.Paint(pieces, r, g, b)
	local paint = pieces.style and PAINT[pieces.style]
	if not paint then return end
	PaintCaptions(pieces)
	paint(pieces, r, g, b)
end

kinds.bar = bar

------------------------------------------------------------------ the border kind

local border = {}

local BORDER_STYLES = {
	slot = { 'slotSlot', 'slotLine' },
	entry = { 'entryLine' },
}

-- A loot feed line (a panel with its icon, a slot, at its left and a name),
-- as Loot's feed draws an entry.
local function NewFeedLine(cell, p, width, text)
	p.line = Bare(st:CreateFrame('Frame', nil, cell.holder))
	p.line:SetSize(width, FEED_HEIGHT)
	st:SetBackdrop(p.line, 'theme', 'solid', 'panel')
	Put(p.line, cell.holder, 0, floor((PV.TILE_HEIGHT - FEED_HEIGHT) / 2))
	p.icon = Bare(st:CreateFrame('Frame', nil, p.line))
	p.icon:SetSize(FEED_HEIGHT, FEED_HEIGHT)
	st:SetBackdrop(p.icon, 'theme', 'solid', 'slot')
	p.icon:SetPoint('LEFT', p.line, 'LEFT', 0, 0)
	local texture = p.icon:CreateTexture(nil, 'ARTWORK')
	texture:SetTexture(STAND_IN_ICON)
	st:SkinIcon(texture, nil, p.icon) -- fills its frame, trimmed as the profile trims icons
	p.name = TextFont(Kit.NewText(p.line, 'LEFT'))
	p.name:SetPoint('LEFT', p.icon, 'RIGHT', 10, 0)
	p.name:SetPoint('RIGHT', p.line, 'RIGHT', -10, 0)
	p.name:SetWordWrap(false)
	p.name:SetText(text)
end

function border.Build(area)
	local pieces = { area = area, cells = {}, active = {} }

	local cell, p = NewCell(pieces, 'slotSlot', SLOT_SIZE, 'Slot')
	p.slot = Bare(st:CreateFrame('Frame', nil, cell.holder))
	p.slot:SetSize(SLOT_SIZE, SLOT_SIZE)
	st:SetBackdrop(p.slot, 'theme', 'solid', 'slot')
	if p.slot.backdrop then -- as a bag slot's (trueSize): the border inside, the icon inside it
		p.slot.backdrop:ClearAllPoints()
		p.slot.backdrop:SetAllPoints(p.slot)
	end
	Put(p.slot, cell.holder, 0, floor((PV.TILE_HEIGHT - SLOT_SIZE) / 2))
	p.icon = p.slot:CreateTexture(nil, 'ARTWORK')
	p.icon:SetTexture(STAND_IN_ICON)
	st:SkinIcon(p.icon)

	cell, p = NewCell(pieces, 'slotLine', 200, 'Feed line')
	NewFeedLine(cell, p, 200, 'Item name')

	cell, p = NewCell(pieces, 'entryLine', 250, 'Feed entry')
	NewFeedLine(cell, p, 250, 'Mount name')
	return pieces
end

function border.Layout(pieces, width, _, spec)
	local style = spec.fields.style
	pieces.style = BORDER_STYLES[style] and style or nil
	LayoutCells(pieces, width, BORDER_STYLES[style])
	-- The icon sits inside the slot's border, which is as wide as the theme in use draws it.
	local slot = pieces.slotSlot
	slot.icon:ClearAllPoints()
	st:SetInside(slot.icon, st:DrawnInset(slot.slot) or 0)
end

local PAINT_BORDER = {}

function PAINT_BORDER.slot(p, r, g, b)
	local slot = p.slotSlot.slot
	if slot.backdrop then st:SetBorderColor(slot.backdrop, r, g, b) end
	p.slotLine.name:SetTextColor(r, g, b)
end

function PAINT_BORDER.entry(p, r, g, b)
	local entry = p.entryLine
	-- A mount's entry in its color (Loot's ColorMount): border and fill at 60%, and its icon's border.
	if entry.line.backdrop then
		st:SetBorderColor(entry.line.backdrop, r, g, b, 1)
		entry.line.backdrop:SetBackdropColor(r, g, b, 0.6)
	end
	if entry.icon.backdrop then st:SetBorderColor(entry.icon.backdrop, r, g, b, 1) end
	entry.name:SetTextColor(st:Color('text', 'normal'):GetRGB())
end

function border.Paint(pieces, r, g, b)
	local paint = pieces.style and PAINT_BORDER[pieces.style]
	if not paint then return end
	PaintCaptions(pieces)
	paint(pieces, r, g, b)
end

kinds.border = border

------------------------------------------------------------------ the built-in kinds

-- Last: the kinds above are the built-in ones. Tasks that add a kind add it here
-- before this loop.
for name in pairs(kinds) do builtin[name] = true end
