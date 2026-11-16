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

------------------------------------------------------------------ shared by the states and danger kinds

-- Places piece by its top left, x across and y down from parent's.
local function Put(piece, parent, x, y)
	piece:ClearAllPoints()
	piece:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, -y)
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

-- Under Blizzard the controls wear Blizzard's art, which draws no derived
-- state, so the pieces are drawn as Thick, with a note.
local function SharedLook() return W.BlizzardLook() and 'thick' or 'theme' end
local function SharedNote(blizzard)
	if blizzard then return "Shown as Thick: Blizzard's art draws its own." end
end

local function PaintCaptionsMuted(captions)
	local mr, mg, mb = st:Color('text', 'muted'):GetRGB()
	for i = 1, #captions do captions[i]:SetTextColor(mr, mg, mb) end
end

------------------------------------------------------------------ the states kind

--[[
	Six tiles of the states the Accent makes, each a kit button ("Okay", 46 by 20)
	held in one state with st:SetState (it takes no mouse): Rest, Hover, Pushed,
	Selected, Selected + hover and Disabled. Paint derives the picked color
	(ST.Derive, with the profile's derivation settings unless spec.settings
	gives others) into the kind's own table and paints each button from it
	(st:PaintStates(button, derived)), so the strip is the states of the color
	being edited, in the frame of the change. W.PaintStates(pieces, r, g, b,
	settings) is that paint on its own, for a row that shows the strip with
	settings that are not the saved ones (the Accent row's menu); the kind's
	Build and Layout place it on any frame.
]]
local STATE_TILE, STATE_BUTTON_WIDTH, STATE_BUTTON_HEIGHT, STATE_BUTTON_X = 58, 46, 20, 6
local STATE_TILE_GAP = 4
local STATE_NAMES = { 'Rest', 'Hover', 'Pushed', 'Selected', 'Sel+hov', 'Disabled' }
local STATE_HELD = {
	{}, { hover = true }, { pushed = true }, { selected = true }, { selected = true, hover = true }, { disabled = true },
}
local STATE_KEYS = { 'hover', 'pushed', 'selected', 'disabled' }

local states = {}
states.note = SharedNote

-- Each button in its state (st:SetState). Hiding a button (the picker closing)
-- clears hover and pushed, so they are held again whenever the kind is laid
-- out. Only a state that differs is set.
local function HoldStates(pieces)
	for i, b in ipairs(pieces.buttons) do
		local held = STATE_HELD[i]
		for _, key in ipairs(STATE_KEYS) do
			local on = held[key] and true or false
			if st:GetState(b, key) ~= on then st:SetState(b, key, on) end
		end
	end
end

function states.Build(area)
	local look = SharedLook()
	local pieces = { area = area, look = look, tile = STATE_TILE, derived = st.States.NewDerived(), tiles = {}, captions = {}, buttons = {} }
	for i, name in ipairs(STATE_NAMES) do
		local tile, caption = NewTile(area, STATE_TILE, look, name)
		pieces.tiles[i], pieces.captions[i] = tile, caption
		local b = W.Button(tile, 'Okay')
		b:SetSize(STATE_BUTTON_WIDTH, STATE_BUTTON_HEIGHT)
		b:EnableMouse(false)
		Put(b, tile, STATE_BUTTON_X, floor((PV.TILE_HEIGHT - STATE_BUTTON_HEIGHT) / 2))
		pieces.buttons[i] = b
	end
	HoldStates(pieces)
	return pieces
end

-- The tile is 58 wide across the picker's 370 (or 402), and narrower across a strip that has
-- less room (the Accent menu's row under a panel: 348), 4 apart at the least.
local function StateTile(width)
	return math.min(STATE_TILE, floor((width - 5 * STATE_TILE_GAP) / 6))
end

-- Runs every time the strip is shown: hiding it clears every held state, not only hover and
-- pushed (the helper's OnHide, and the kit button's own Paint on hide), so the states are held
-- again here.
function states.Layout(pieces, width)
	local look = SharedLook()
	HoldStates(pieces)
	if pieces.look ~= look then
		pieces.look = look
		for _, tile in ipairs(pieces.tiles) do st:SetTemplate(tile, look, 'solid', 'panel') end
	end
	local size = StateTile(width)
	if pieces.tile ~= size then
		pieces.tile = size
		for i, tile in ipairs(pieces.tiles) do
			tile:SetSize(size, PV.TILE_HEIGHT)
			pieces.captions[i]:SetWidth(size)
			Put(pieces.buttons[i], tile, floor((size - STATE_BUTTON_WIDTH) / 2), floor((PV.TILE_HEIGHT - STATE_BUTTON_HEIGHT) / 2))
		end
	end
	for i, tile in ipairs(pieces.tiles) do
		Put(tile, pieces.area, TileX(i, 6, width, size), 0)
	end
end

-- The strip's paint with the Accent r, g, b under settings (the profile's when
-- nil). Colors only: one derivation into the strip's own table, six
-- st:PaintStates and the captions. With no r the strip is painted from the
-- cache, the saved Accent and settings (the Accent menu's row: nothing is
-- derived, and a pass paints the same).
function W.PaintStates(pieces, r, g, b, settings)
	local ST = st.States
	if r == nil then
		for _, button in ipairs(pieces.buttons) do st:PaintStates(button) end
	else
		ST.Derive(r, g, b, settings or ST.Settings(), pieces.derived)
		for _, button in ipairs(pieces.buttons) do st:PaintStates(button, pieces.derived) end
	end
	PaintCaptionsMuted(pieces.captions)
end

function states.Paint(pieces, r, g, b, _, spec)
	W.PaintStates(pieces, r, g, b, spec and spec.settings)
end

kinds.states = states

------------------------------------------------------------------ the danger kind

--[[
	Two tiles 118 wide, the first at the strip's left edge and the second at its
	right: an action button's flash at 0.4 ("Flash") and an unbought bank
	slot's tint at 0.3 ("Locked slot"), in the picked color times its opacity.
	Under Blizzard the flash is Blizzard's art, so the tiles are drawn as
	Thick, with the note.
]]
local DANGER_NAMES = { 'Flash', 'Locked slot' }
local FLASH_ALPHA, LOCKED_ALPHA = 0.4, 0.3 -- ActionBars' skin.lua; Bags' bank.lua
local FLASH_SIZE, LOCKED_SIZE = 30, 20 -- the mockup's: the flash button, the bank slot

local danger = {}
danger.note = SharedNote

function danger.Build(area)
	local look = SharedLook()
	local pieces = { area = area, look = look, tiles = {}, captions = {}, slots = {}, veils = {} }
	for i, name in ipairs(DANGER_NAMES) do
		pieces.tiles[i], pieces.captions[i] = NewTile(area, PV.TILE_WIDTH, look, name)
		local slot = st:CreateFrame('Frame', nil, pieces.tiles[i])
		slot:SetSize(i == 1 and FLASH_SIZE or LOCKED_SIZE, i == 1 and FLASH_SIZE or LOCKED_SIZE)
		st:SetBackdrop(slot, look, 'solid', 'slot')
		slot:EnableMouse(false)
		local veil = slot:CreateTexture(nil, 'OVERLAY')
		veil:SetAllPoints(slot)
		veil:SetColorTexture(0, 0, 0, 0)
		pieces.slots[i], pieces.veils[i] = slot, veil
	end
	return pieces
end

function danger.Layout(pieces, width)
	local look = SharedLook()
	if pieces.look ~= look then
		pieces.look = look
		for _, tile in ipairs(pieces.tiles) do st:SetTemplate(tile, look, 'solid', 'panel') end
		for _, slot in ipairs(pieces.slots) do st:SetBackdrop(slot, look, 'solid', 'slot') end
	end
	for i, tile in ipairs(pieces.tiles) do
		Put(tile, pieces.area, TileX(i, 2, width, PV.TILE_WIDTH), 0)
		-- from the constants, never a size read back from the game
		local size = i == 1 and FLASH_SIZE or LOCKED_SIZE
		Put(pieces.slots[i], tile, floor((PV.TILE_WIDTH - size) / 2), floor((PV.TILE_HEIGHT - size) / 2))
	end
end

function danger.Paint(pieces, r, g, b, a)
	pieces.veils[1]:SetColorTexture(r, g, b, a * FLASH_ALPHA)
	pieces.veils[2]:SetColorTexture(r, g, b, a * LOCKED_ALPHA)
	local nr, ng, nb = st:Color('text', 'normal'):GetRGB()
	for i = 1, #pieces.captions do pieces.captions[i]:SetTextColor(nr, ng, nb) end
end

kinds.danger = danger

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
local PointLook = SharedLook

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

------------------------------------------------------------------ the statepreview row

--[[
	The Accent menu's row (Media/states.lua's ST.MenuGroup, optionsmenu.lua): the states kind's
	strip as a row of its own, a bare type with no label and no reset, 370 wide where there is
	room (the menu's body gives it what a panel leaves: 348 under Thick and Thin, and the strip's
	tiles are narrower then). Each widget builds its own strip with the kind's Build, so a pooled
	widget has its pieces already.

	It takes no mouse. It is laid out (the states held again) every time it is shown, bound or
	given a width: hiding clears every held state. It is painted from the profile, the cache
	(W.PaintStates with no color: the saved Accent and settings, nothing derived): the buttons
	in the tiles are state frames that follow the Accent as every other, so a pass paints them
	with the settings the menu has just saved; it follows Text for its captions. Under Blizzard
	the strip is Thick and the row says so under it, the states kind's note, in Text > Muted.
]]
local STRIP_WIDTH, NOTE_ROOM = 370, 18
local stripOf = setmetatable({}, { __mode = 'k' }) -- row frame -> its widget, for the Text follower

local function LayStrip(w)
	local blizzard = W.BlizzardLook()
	local note = states.note(blizzard)
	w.note:SetText(note or '')
	w.note:SetShown(note ~= nil)
	local height = PV.HEIGHT + (note and NOTE_ROOM or 0)
	if w.frame:GetHeight() ~= height then w.frame:SetHeight(height) end
	states.Layout(w.pieces, w.stripWidth)
end

local function PaintMuted(frame)
	local w = stripOf[frame]
	if not w then return end
	PaintCaptionsMuted(w.pieces.captions)
	w.note:SetTextColor(st:Color('text', 'muted'):GetRGB())
end

W.Define('statepreview', {
	bare = true,
	width = STRIP_WIDTH,
	build = function(w)
		local frame = CreateFrame('Frame', nil, UIParent)
		frame:SetSize(STRIP_WIDTH, PV.HEIGHT)
		w.frame = frame
		w.stripWidth = STRIP_WIDTH
		w.pieces = states.Build(frame)
		w.note = TextFont(Kit.NewText(frame, 'LEFT'))
		w.note:SetWordWrap(false)
		w.note:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -(PV.HEIGHT + 2))
		w.note:Hide()
		stripOf[frame] = w
		st:FollowColor(frame, 'text', nil, PaintMuted)
		-- shown again after a release: the states held again, whoever shows it
		frame:SetScript('OnShow', function()
			LayStrip(w)
			W.PaintStates(w.pieces)
		end)
	end,
	methods = {
		-- The look before the row, and the row's width: the strip for it.
		Bind = function(self, root, row, onChanged)
			LayStrip(self)
			return Kit.Base.Bind(self, root, row, onChanged)
		end,

		Refresh = function(self)
			LayStrip(self)
			W.PaintStates(self.pieces)
			PaintMuted(self.frame)
		end,

		-- The body's width for a bare row.
		SetWidth = function(self, width)
			self.stripWidth = width
			self.frame:SetWidth(width)
			self.note:SetWidth(width)
			LayStrip(self)
		end,

		OnRelease = function(self)
			self.stripWidth = STRIP_WIDTH
		end,
	},
})
