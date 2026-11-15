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

------------------------------------------------------------------ the built-in kinds

-- Last: the kinds above are the built-in ones. Tasks that add a kind add it here
-- before this loop.
for name in pairs(kinds) do builtin[name] = true end
