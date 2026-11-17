local st = SaftUI

--[[
	The Blizzard theme's art: how each kind of frame and each control looks
	under it, on each client. The art is Blizzard's own, named as Blizzard's UI
	code and the clients' atlas tables name it (the design is
	docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md). SaftUI
	places it itself, on frames of its own, from these tables: it never runs
	Blizzard's nine-slice code, whose layouts are for Blizzard's windows and
	which writes onto the frame it draws on (.agents/taint.md).

	theme.lua resolves a look (st:ResolveTheme), reads a Blizzard look's inset
	here, and hands a Blizzard look here to be drawn (Drawing, at the end).
	Everything is read at call time, through ThemeArt.Client(), as the client
	decides some values.

	The tables, st.ThemeArt.KINDS and st.ThemeArt.ART (in themeart_data.lua):
	  KINDS[kind]  each kind of frame (st.THEME_KINDS) under Blizzard: its inset
	               on each client, the art it's drawn in (a name in ART), its
	               fill (one of the theme's colors), whether it's a 1px line,
	               and for a kind in the box how far the box reaches outside.
	  ART[name]    each piece of art: the box (the one border of panels,
	               bars, tooltips and unit frames, drawn over the frame it
	               borders: ThemeArt.BoxFrame) and the metal, the
	               unit frame's bronze box (cut from Blizzard's unit frame art
	               by texture coordinates, ThemeArt.Cut), the action and item
	               buttons', the aura's, the close button's, and each
	               control's (CONTROLS), which st.ThemeArt.Control reads;
	               the party and raid group border is one of those, a cut
	               drawn by ThemeArt.PaintCut.
	A value that differs by client is ByClient(forever, live); the accessors
	give this client's. An art name that starts with Interface\ is a file;
	every other is an atlas, and is marked Atlas() where the tables name it, so
	st:ThemeAtlases can list them all with the clients that have each (the tests
	check each exists on those clients).
]]

-- themeart_data.lua loads first: it makes st.ThemeArt, with the tables and
-- what builds them (ATLASES, and the metatable of a ByClient value).
local ThemeArt = st.ThemeArt
local ATLASES, PER_CLIENT = ThemeArt.ATLASES, ThemeArt.PER_CLIENT

------------------------------------
--- The client ---------------------
------------------------------------

-- 'forever' on WoW Forever, 'live' on retail: Blizzard's names for the two
-- branches of its UI code. Read at call time.
function ThemeArt.Client()
	return st.forever and 'forever' or 'live'
end

-- value as this client has it: a ByClient read for the client, and a table
-- copied with each ByClient in it read, so the tables can't be changed
-- through what the accessors give.
local function ForClient(value)
	if type(value) ~= 'table' then return value end
	if getmetatable(value) == PER_CLIENT then return ForClient(value[ThemeArt.Client()]) end
	local copy = {}
	for key, v in pairs(value) do copy[key] = ForClient(v) end
	return copy
end

-- The names in ART that are controls (st.ThemeArt.Control).
local CONTROLS = {
	button = true, checkbox = true, tab = true, dropdown = true, slider = true,
	input = true, search = true, swatch = true, binding = true, nudge = true, scrollbar = true,
	optionstab = true, optionslist = true, micro = true, mover = true, classpower = true,
	groupborder = true, unitbars = true, optionswindow = true, resizegrip = true,
	nameplatetarget = true, sizebutton = true,
}

------------------------------------
--- Reading the tables -------------
------------------------------------

local function Kind(kind)
	local look = ThemeArt.KINDS[kind]
	if not look then error(tostring(kind) .. ' is not a kind of frame', 3) end
	return look
end

-- How far a kind's art reaches in from the drawn frame's edge under Blizzard,
-- on this client.
function ThemeArt.Inset(kind)
	return ForClient(Kind(kind).inset)
end

-- How far a kind's box reaches outside the frame it borders under Blizzard,
-- on this client; 0 for a kind not drawn in the box. Only the art reads it:
-- what's placed by a kind's inset doesn't move.
function ThemeArt.Reach(kind)
	return ForClient(Kind(kind).reach) or 0
end

-- A length of the art in whole pixels of frame (UIParent with none): the
-- length times k, rounded, in frame's own units. Nothing stays nothing and
-- anything else is at least one pixel, so a one-unit inset is always its line.
-- At k = 1 it is the length itself. The art's own sizes (a piece's atlas) are
-- not rounded: they scale with k, as the art does (call 21).
function ThemeArt.Whole(value, frame, pixel)
	if value == 0 then return 0 end
	pixel = pixel or st:DrawPixelSize(frame or UIParent)
	if not pixel then return value end
	-- The count is trimmed to 1e-4 before it rounds, as the line weight's is
	-- (UIScale.LineWeight), so a half a pixel that arrives a float short still
	-- rounds up, and a one-unit inset is always one line. Not trimmed as a
	-- length: like a line, it is exactly that many pixels.
	local count = math.floor(math.floor(value / pixel * 10000 + 0.5) / 10000 + 0.5)
	return math.max(1, count) * pixel
end

-- ThemeArt.Inset and ThemeArt.Top in whole pixels of frame.
function ThemeArt.WholeInset(kind, frame, pixel)
	return ThemeArt.Whole(ThemeArt.Inset(kind), frame, pixel)
end

function ThemeArt.WholeTop(kind, frame, pixel)
	return ThemeArt.Whole(ThemeArt.Top(kind), frame, pixel)
end

-- How far the metal's title bar reaches down from a window's drawn frame's
-- top, on this client.
function ThemeArt.TitleHeight()
	return ForClient(ThemeArt.ART.metal.titleHeight)
end

-- How tall the strip of the metal's title bar a window's header sits in is,
-- its bottom on the window's top, on this client (the metal's titleStrip).
function ThemeArt.TitleStrip()
	return ForClient(ThemeArt.ART.metal.titleStrip)
end

-- How far the metal's art reaches above its drawn frame's top on this client:
-- its top corners sit that far up (their y), and the top edge between them,
-- as Blizzard's nine-slice layout puts them. Its top rows are the frame's rim
-- and shadow. What sits above a window clears the metal by this.
function ThemeArt.MetalAbove()
	local metal = ThemeArt.ART.metal
	return math.max(ForClient(metal.TopLeftCorner.y), ForClient(metal.TopRightCorner.y))
end

-- How far the metal's art reaches past its drawn frame on this client: left,
-- right, top and bottom, each as far as the corners on that side sit out (the
-- top is MetalAbove). What keeps a window on screen keeps this on it too.
function ThemeArt.MetalReach()
	local metal = ThemeArt.ART.metal
	local function x(key) return ForClient(metal[key].x) end
	local function y(key) return ForClient(metal[key].y) end
	return math.max(-x('TopLeftCorner'), -x('BottomLeftCorner')),
		math.max(x('TopRightCorner'), x('BottomRightCorner')),
		ThemeArt.MetalAbove(),
		math.max(-y('BottomLeftCorner'), -y('BottomRightCorner'))
end

-- How far a kind's art reaches down from the drawn frame's top under
-- Blizzard, on this client: for art with a title bar (a window's metal) the
-- title bar, which a backdrop reaches that far above its window; for the rest
-- the kind's inset, as on its other sides.
function ThemeArt.Top(kind)
	local look = Kind(kind)
	local art = ThemeArt.ART[look.art]
	return ForClient(art and art.titleHeight or look.inset)
end

-- Blizzard's close button on this client: { size, x, y, normal, pushed,
-- highlight, highlightBlend, disabled }.
function ThemeArt.Close()
	return ForClient(ThemeArt.ART.close)
end

-- A kind's button state art on this client, where SaftUI makes the state
-- textures: { hover, pushed, checked, checkedBlend, flash } for an action
-- button, { pushed, highlight, highlightBlend } for a slot; nil for a kind
-- with none.
function ThemeArt.State(kind)
	local art = ThemeArt.ART[Kind(kind).art]
	return art and art.states and ForClient(art.states) or nil
end

-- Cuts an over-the-icon texture of an art (the ART table: a ring, an own-color
-- piece or a state texture) to the button's part of it, by coordinates, when
-- the art says it hangs past the button (the action button's, artWidth x
-- artHeight from TOPLEFT on a templateButton button): the left
-- templateButton/artWidth and templateButton/artHeight of its height. An art
-- with none (a slot's, an aura's, no art) is left as it is. The texture fills
-- its frame (SetAllPoints) and is never sized, so this reads no size and holds
-- in combat. Call it after the atlas is set, which keeps the coordinates a
-- texture had unless told to reset them.
function ThemeArt.CutOver(texture, art)
	if art and art.artWidth then
		texture:SetTexCoord(0, art.templateButton / art.artWidth, 0, art.templateButton / art.artHeight)
	end
end

-- Puts Blizzard's state art (name, an atlas or a file from State) on texture,
-- one of a button's state textures of SaftUI's (the hover, pushed or checked
-- texture; the flash too): over the whole button, cut to the button's part
-- when kind's art hangs past it (the action button's: CutOver), white, with no tint, blending as blend says (the button's own
-- call sets the highlight's), and drawn in layer: the state layer above the
-- ring when it's nil, the layer it has when it's false (the flash), or the
-- layer named (the hover: HOVER_LAYER). kind is the kind the button is drawn
-- as ('action' for an action button; nil is the whole button). A flat state
-- texture is put back by its own code (StyleButton in the action bars' skin,
-- st:SkinActionButton, the totem skin), not here.
function ThemeArt.StyleState(texture, name, button, blend, layer, kind)
	if name:find([[Interface\]], 1, true) == 1 then
		texture:SetTexture(name)
		texture:SetTexCoord(0, 1, 0, 1)
	else
		-- The flat look's Selected fade left coordinates on the checked
		-- texture (StyleGame, Widgets/states.lua), and SetAtlas keeps the
		-- coordinates a texture has unless told to reset them: reset them, and
		-- set the whole atlas after, so it holds whichever the client honours.
		texture:SetAtlas(name, false, nil, true)
		texture:SetTexCoord(0, 1, 0, 1)
	end
	if layer == nil then
		texture:SetDrawLayer(ThemeArt.STATE_LAYER, ThemeArt.STATE_SUBLEVEL)
	elseif layer then
		texture:SetDrawLayer(layer, 0)
	end
	texture:SetVertexColor(1, 1, 1, 1)
	if blend then texture:SetBlendMode(blend) end
	texture:ClearAllPoints()
	texture:SetAllPoints(button)
	local blizzard = kind and ThemeArt.KINDS[kind]
	ThemeArt.CutOver(texture, blizzard and blizzard.art and ThemeArt.ART[blizzard.art])
end

-- A control's art on this client (CONTROLS; the fields are ART[name]'s).
function ThemeArt.Control(name)
	if not CONTROLS[name] then error(tostring(name) .. ' is not a control', 2) end
	return ForClient(ThemeArt.ART[name])
end

-- A class power point's empty and filled atlases: the point is index of the
-- player's row, class the player's, charged a rogue's charged combo point.
-- nil for a power type, class or point with no art (death knight runes).
function ThemeArt.ClassPower(powerType, index, class, charged)
	local art = ThemeArt.ART.classpower[powerType]
	if art and art.byClass then art = art.byClass[class] end
	if not art then return nil end
	if art.runes then
		if not index or index < 1 or index > art.runes then return nil end
		return art.empty:format(index), art.filled:format(index)
	end
	return art.empty, charged and art.charged or art.filled
end

-- Every atlas the Blizzard theme's tables name, as { [name] = true | 'forever'
-- | 'live' }: true for one both clients have, the client for one only that
-- client has. The controls' too, a mover's for both kits and holy power's for
-- each rune, but no file. The tests check each exists on the clients it's for.
function st:ThemeAtlases()
	local names = {}
	for name, clients in pairs(ATLASES) do names[name] = clients end
	return names
end

------------------------------------
--- Drawing ------------------------
------------------------------------

-- theme.lua hands a Blizzard look here: ThemeArt.Paint draws it, ThemeArt.Color
-- recolors it, and ThemeArt.Clear hides the art of a frame drawn in another
-- look. A drawn frame is the frame a look is drawn on: a backdrop behind its
-- owner (st:SetBackdrop, st:SetBackdropIn), or the frame itself
-- (st:SetTemplate). Its pieces are textures made once, then shown, hidden and
-- re-pointed by later draws. Each is a texture on a frame of SaftUI's: the
-- drawn frame, a button's ring on the button of SaftUI's it sits behind, the
-- box's pieces on the box frame over the frame it borders (BoxFrame), or
-- else on a frame of SaftUI's over the drawn frame (Holder). They're kept
-- here, never in a field on a frame (.agents/taint.md), and placed by anchors
-- and offsets: no size is read back from the game.

-- drawn frame -> its art, { pieces, over, own } (ThemeArt.Get).
local drawnArt = setmetatable({}, { __mode = 'k' })

-- drawn frame -> the frame of SaftUI's its over pieces are on (Holder).
local holders = setmetatable({}, { __mode = 'k' })

-- drawn frame -> the frame of SaftUI's its box is on (ThemeArt.BoxFrame); and
-- each box frame, as a key, so ThemeArt.LevelAbove leaves them out.
local boxFrames = setmetatable({}, { __mode = 'k' })
local isBoxFrame = setmetatable({}, { __mode = 'k' })

-- The pieces behind a button's icon, bottom first: the keys of its art's behind.
local BEHIND = { 'SlotBackground', 'SlotArt' }

-- A border's corners, each at the drawn frame's own corner, offset by its x and y.
local CORNERS = {
	TopLeftCorner = 'TOPLEFT', TopRightCorner = 'TOPRIGHT',
	BottomLeftCorner = 'BOTTOMLEFT', BottomRightCorner = 'BOTTOMRIGHT',
}

-- A border's edges, as Blizzard's nine-slice code lays them: point at the first
-- corner's to, and to at the last corner's point. The top and bottom tile
-- across, the sides down.
local EDGES = {
	TopEdge = { point = 'TOPLEFT', to = 'TOPRIGHT', first = 'TopLeftCorner', last = 'TopRightCorner', across = true },
	BottomEdge = { point = 'BOTTOMLEFT', to = 'BOTTOMRIGHT', first = 'BottomLeftCorner', last = 'BottomRightCorner', across = true },
	LeftEdge = { point = 'TOPLEFT', to = 'BOTTOMLEFT', first = 'TopLeftCorner', last = 'BottomLeftCorner', across = false },
	RightEdge = { point = 'TOPRIGHT', to = 'BOTTOMRIGHT', first = 'TopRightCorner', last = 'BottomRightCorner', across = false },
}

-- A drawn frame's art (Get), made the first time.
local function Art(frame)
	local art = drawnArt[frame]
	if not art then
		art = { pieces = {}, over = {} }
		drawnArt[frame] = art
	end
	return art
end

-- set's piece by key: a texture on parent, made the first time, now in layer
-- at sublevel, showing name (a file, or else an atlas at its own size; with
-- no name, what it shows is its caller's: a cut's piece), white and shown.
local function Piece(set, parent, key, name, layer, sublevel)
	local piece = set[key]
	if not piece then
		piece = parent:CreateTexture(nil, layer)
		set[key] = piece
	end
	piece:SetDrawLayer(layer, sublevel or 0)
	if name and name:find([[Interface\]], 1, true) == 1 then
		piece:SetTexture(name)
	elseif name then
		piece:SetAtlas(name, true)
	end
	piece:SetVertexColor(1, 1, 1, 1)
	piece:Show()
	return piece
end

-- The frame of SaftUI's a drawn frame's over pieces are on when no button of
-- SaftUI's takes them (ThemeArt.Paint's host): made the first time as the
-- drawn frame's child, over all of it, so it shows and hides with it. It sits
-- one level above the frame the art is for, the drawn frame or the frame it
-- sits behind (its parent), whichever is higher, so the pieces lie over that
-- frame's icon, and over its texts too. A level can be secret (the parent may
-- be Blizzard's): a secret parent's is left out, and with the frame's own
-- secret the holder stays where it was made, one level over it.
local function Holder(frame)
	local holder = holders[frame]
	if not holder then
		holder = CreateFrame('Frame', nil, frame)
		holder:SetAllPoints(frame)
		holders[frame] = holder
	end
	local level = frame:GetFrameLevel()
	if issecretvalue(level) then return holder end
	local parent = frame:GetParent()
	local parentLevel = parent and parent:GetFrameLevel()
	if parentLevel and not issecretvalue(parentLevel) then level = math.max(level, parentLevel) end
	holder:SetFrameLevel(level + 1)
	return holder
end

-- A border's or a cut's piece -> the frame it was last laid on (BorderPiece),
-- kept here so a redraw reads nothing back from the game.
local laidOn = setmetatable({}, { __mode = 'k' })

-- A border's or a cut's piece, by key, on frame: Piece, and moved to frame
-- when it was laid before on another frame of SaftUI's (a drawn frame first
-- drawn as a window, its metal on itself, then in the box, on its box frame,
-- or back). Only these: a ring or an own-color piece is never moved.
local function BorderPiece(pieces, frame, key, name, layer)
	local made = pieces[key] == nil
	local piece = Piece(pieces, frame, key, name, layer)
	if not made and laidOn[piece] ~= frame then piece:SetParent(frame) end
	laidOn[piece] = frame
	return piece
end

-- A border (the metal or a kit) on frame, its textures kept in
-- pieces by key: its corners, then its edges between them, then its Center
-- when it has one, in its layer. Pixel snapping is off where the border says so,
-- with the texel snapping bias at 0, as Blizzard's nine-slice code turns
-- sharpening off; for any other border it's on, the game's default, so a piece
-- once drawn as the metal doesn't keep it off. The bias stays: Blizzard's code
-- never sets it back, and nothing gives its default.
local function LayBorder(pieces, frame, border)
	local function Lay(key)
		local piece = BorderPiece(pieces, frame, key, border[key].atlas, border.layer)
		piece:ClearAllPoints()
		if border.snap == false then piece:SetTexelSnappingBias(0) end
		piece:SetSnapToPixelGrid(border.snap ~= false)
		return piece
	end
	for key, point in pairs(CORNERS) do
		local piece = Lay(key)
		piece:SetPoint(point, frame, point, border[key].x or 0, border[key].y or 0)
		piece:SetHorizTile(false)
		piece:SetVertTile(false)
	end
	for key, edge in pairs(EDGES) do
		local piece = Lay(key)
		piece:SetPoint(edge.point, pieces[edge.first], edge.to)
		piece:SetPoint(edge.to, pieces[edge.last], edge.point)
		piece:SetHorizTile(edge.across)
		piece:SetVertTile(not edge.across)
	end
	if border.Center then
		-- Blizzard's NineSlice default: from the top left corner's inner point to
		-- the bottom right's.
		local piece = Lay('Center')
		piece:SetPoint('TOPLEFT', pieces.TopLeftCorner, 'BOTTOMRIGHT')
		piece:SetPoint('BOTTOMRIGHT', pieces.BottomRightCorner, 'TOPLEFT')
		piece:SetHorizTile(false)
		piece:SetVertTile(false)
	end
end

-- Lays border (a border table as Control gives it) on frame: the tooltip
-- border's way, and its Center too when it has one. The textures are frame's,
-- kept by key in the caller's pieces (not in Get's art, which a redraw clears).
-- Shown and white; HidePieces hides them.
function ThemeArt.LayBorder(pieces, frame, border)
	LayBorder(pieces, frame, border)
end

-- Hides every texture in pieces (what LayBorder laid).
function ThemeArt.HidePieces(pieces)
	for _, piece in pairs(pieces) do piece:Hide() end
end

-- Whether a piece of art is a cut (LayCut) rather than a border.
local function IsCut(art)
	return art.pieces ~= nil and art.size ~= nil
end

-- One coordinate of a cut: n pixels into an atlas size pixels long, whose
-- member runs from from to to in its file.
local function CutCoord(from, to, n, size)
	return from + (to - from) * n / size
end

-- Cuts rect, { x0, x1, y0, y1 } in atlas's own pixels with exclusive ends,
-- out of atlas onto texture and shows it: the atlas's file, at the texture
-- coordinates of rect within the atlas's member there, both from
-- C_Texture.GetAtlasInfo (its file and its left, right, top and bottom
-- coordinates; on Forever the Camelot member's). Never from a size read back
-- from a frame. Where the texture sits and how big it is are its caller's.
-- Returns true; or false, hiding the texture, when the atlas gives no file
-- (AtlasInfo's file can be nil), no texture coordinates or size to cut by,
-- or this client hasn't got it.
function ThemeArt.Cut(texture, atlas, rect)
	local info = C_Texture.GetAtlasInfo(atlas)
	local left, right = info and info.leftTexCoord, info and info.rightTexCoord
	local top, bottom = info and info.topTexCoord, info and info.bottomTexCoord
	if not (info and info.file and left and right and top and bottom and info.width and info.height) then
		texture:Hide()
		return false
	end
	texture:SetTexture(info.file)
	texture:SetTexCoord(
		CutCoord(left, right, rect[1], info.width), CutCoord(left, right, rect[2], info.width),
		CutCoord(top, bottom, rect[3], info.height), CutCoord(top, bottom, rect[4], info.height))
	texture:Show()
	return true
end

-- A cut (Forever's box, the unit frame's bronze box, the group border) on
-- frame, its textures kept in pieces by key: each piece
-- cut from its atlas (ThemeArt.Cut, which hides one it can't cut), the
-- corners size by size at frame's own corners, the edges between
-- them, size thick and stretched, every piece in the cut's layer. Pixel
-- snapping is on, the game's default, so a piece once drawn as the metal
-- doesn't keep it off.
local function LayCut(pieces, frame, cut)
	local size = cut.size
	local function Lay(key)
		local piece = BorderPiece(pieces, frame, key, nil, cut.layer)
		piece:ClearAllPoints()
		piece:SetSnapToPixelGrid(true)
		piece:SetHorizTile(false)
		piece:SetVertTile(false)
		ThemeArt.Cut(piece, cut.pieces[key].atlas, cut.pieces[key].rect)
		return piece
	end
	for key, point in pairs(CORNERS) do
		local piece = Lay(key)
		piece:SetPoint(point, frame, point, 0, 0)
		piece:SetSize(size, size)
	end
	for key, edge in pairs(EDGES) do
		local piece = Lay(key)
		piece:SetPoint(edge.point, pieces[edge.first], edge.to)
		piece:SetPoint(edge.to, pieces[edge.last], edge.point)
		if edge.across then piece:SetHeight(size) else piece:SetWidth(size) end
	end
end

-- Lays this client's box (ART.box) on frame's own bounds, its textures
-- frame's, kept by key in the caller's pieces: Forever's a cut (LayCut),
-- retail's the minimap button kit (LayBorder). With centre the box's centre
-- too, as a Center piece between the corners (Forever's cut from the header
-- button's centre, retail's the kit's Center); without it a Center laid
-- before is hidden. Shown and white; HidePieces hides them. The micro menu's
-- boxes lay it on frames of their own; ThemeArt.Paint lays it on a drawn
-- frame's box frame.
function ThemeArt.LayBox(pieces, frame, centre)
	local box = ForClient(ThemeArt.ART.box)
	if IsCut(box) then
		LayCut(pieces, frame, box)
		if centre then
			local piece = BorderPiece(pieces, frame, 'Center', nil, box.layer)
			piece:ClearAllPoints()
			piece:SetSnapToPixelGrid(true)
			piece:SetHorizTile(false)
			piece:SetVertTile(false)
			ThemeArt.Cut(piece, box.pieces.TopLeftCorner.atlas, box.centre)
			piece:SetPoint('TOPLEFT', pieces.TopLeftCorner, 'BOTTOMRIGHT')
			piece:SetPoint('BOTTOMRIGHT', pieces.BottomRightCorner, 'TOPLEFT')
			return
		end
	else
		if not centre then box.Center = nil end
		LayBorder(pieces, frame, box)
		if centre then return end
	end
	if pieces.Center then pieces.Center:Hide() end
end

-- One more than the highest frame level among target and its direct children
-- (target:GetChildren()), the box frames left out: where a box goes to lie
-- over the frame it borders and over its child bars, buttons and texts. A
-- level can be secret (target or a child may be Blizzard's): a child's
-- secret level is left out, and with target's own secret it is nil, and the
-- caller leaves the level as it is.
function ThemeArt.LevelAbove(target)
	local level = target:GetFrameLevel()
	if issecretvalue(level) then return nil end
	for _, child in ipairs({ target:GetChildren() }) do
		if not isBoxFrame[child] then
			local childLevel = child:GetFrameLevel()
			if not issecretvalue(childLevel) and childLevel > level then level = childLevel end
		end
	end
	return level + 1
end

-- The frame of SaftUI's a drawn frame's box is on: made the first time as the
-- drawn frame's child, so it shows and hides with it, and kept here. Its
-- place and level are ThemeArt.Paint's (over the frame the box borders,
-- ThemeArt.LevelAbove); ThemeArt.Clear hides it.
function ThemeArt.BoxFrame(frame)
	local box = boxFrames[frame]
	if not box then
		box = CreateFrame('Frame', nil, frame)
		boxFrames[frame] = box
		isBoxFrame[box] = true
	end
	return box
end

-- Where a ring on a button of SaftUI's draws among the button's own regions:
-- over the icon, which Blizzard's action and item button templates put in
-- BACKGROUND and BORDER, and under their font strings, the lowest of which is
-- the item button's count, in ARTWORK at 0. As a region of the button it's
-- under every child frame too (the cooldown, the glows, the action button's
-- hotkey and count).
local RING_LAYER, RING_SUBLEVEL = 'ARTWORK', -2

-- A frame's own border color's piece (the white icon border, the action
-- button's equipped border) draws just over the ring and still under the
-- texts.
local OWN_SUBLEVEL = -1

-- Where a button's state art draws (pushed, checked: StyleState; the hover
-- has its own, HOVER_LAYER): the same layer as the ring and just over it,
-- level with the own-color piece, so it covers the ring's footprint, the
-- whole button, over the icon and under the texts,
-- which Blizzard's action and item button templates put in OVERLAY (the item
-- button's count, its name) or in a frame over the button (the action
-- button's hotkey and count, at level 500). Blizzard's own ring is its normal
-- texture, ARTWORK 0, and the state art is drawn over it.
ThemeArt.STATE_LAYER, ThemeArt.STATE_SUBLEVEL = 'ARTWORK', -1

-- Where a button's hover draws, in every look: HIGHLIGHT, where
-- SetHighlightTexture puts it. The client shows that layer only under the
-- mouse, so a hover moved out of it shows all the time (2026-11-11: every
-- slot and action button washed blue). It draws over the button's own
-- regions, the count of an item button too, as Blizzard's own highlight does;
-- an action button's texts are in a frame over the button, so they stay over it.
ThemeArt.HOVER_LAYER = 'HIGHLIGHT'

-- A button's art on frame (the action or item button's): the art behind its
-- icon, filling frame, and the ring over the icon's edge, covering frame (an
-- action button's ring cut to the button's part of Blizzard's 46 x 45 art:
-- CutOver). The
-- ring is a texture of host's, the button of SaftUI's frame sits behind, or
-- with no host on frame's holder. A ring Blizzard draws ringSize on a
-- buttonSize button, centred ringY low, is cut to the button's part, so it fits
-- a button of any size.
local function LayButton(art, frame, button, host)
	for sublevel, key in ipairs(BEHIND) do
		local name = button.behind[key]
		if name then
			local piece = Piece(art.pieces, frame, key, name, 'BACKGROUND', sublevel)
			piece:ClearAllPoints()
			piece:SetAllPoints(frame)
		end
	end
	local ring
	if host then
		ring = Piece(art.over, host, 'Ring', button.ring, RING_LAYER, RING_SUBLEVEL)
	else
		ring = Piece(art.over, Holder(frame), 'Ring', button.ring, RING_LAYER, RING_SUBLEVEL)
	end
	ring:ClearAllPoints()
	ring:SetAllPoints(frame)
	ThemeArt.CutOver(ring, button)
	if button.ringSize then
		local size, half, y = button.ringSize, button.buttonSize / 2, button.ringY
		ring:SetTexCoord((size / 2 - half) / size, (size / 2 + half) / size,
			(size / 2 - half + y) / size, (size / 2 + half + y) / size)
	end
end

-- Whether a kind draws anything under Blizzard. header, close and control
-- don't: they're cleared, and each control shows art of its own.
local function Draws(look)
	return look.art or look.fill or look.line
end

-- A drawn frame's art: { pieces = { [key] = texture } on the drawn frame,
-- over = { [key] = texture } over the icon's edge (on the button, or the
-- drawn frame's holder), own = texture|nil, the
-- piece a frame's own border color shows }; nil for a frame never drawn under
-- Blizzard.
function ThemeArt.Get(frame)
	return drawnArt[frame]
end

-- Hides every piece of frame's art, and its box frame: for a frame drawn in
-- another look, or None.
function ThemeArt.Clear(frame)
	local box = boxFrames[frame]
	if box then box:Hide() end
	local art = drawnArt[frame]
	if not art then return end
	for _, set in ipairs({ art.pieces, art.over }) do
		for _, piece in pairs(set) do piece:Hide() end
	end
	if art.own then art.own:Hide() end
end

-- Puts a Blizzard look's colors and alpha on frame, drawn as kind: the fill
-- in the kind's color at the look's alpha (clear for a kind with none), a
-- small frame's line in the Border, the art behind a button's icon at the
-- look's alpha, and every piece white, which takes a frame's own color off.
-- Moves nothing.
function ThemeArt.Color(frame, look, kind)
	local blizzard = Kind(kind)
	if not Draws(blizzard) then return end
	local colors = look.colors
	if blizzard.fill then
		local r, g, b, a = unpack(colors[blizzard.fill])
		frame:SetBackdropColor(r, g, b, a * look.alpha)
	else
		frame:SetBackdropColor(0, 0, 0, 0)
	end
	if blizzard.line then
		frame:SetBackdropBorderColor(unpack(colors.bordercolor))
	end

	local art = drawnArt[frame]
	if not art then return end
	for _, set in ipairs({ art.pieces, art.over }) do
		for _, piece in pairs(set) do piece:SetVertexColor(1, 1, 1, 1) end
	end
	-- The box shows plain bronze again (SetBorder desaturated it for a colour).
	-- Only when it is: a recolor makes no call it didn't (theme_scale_test m1).
	if art.desaturated then
		art.desaturated = false
		for _, piece in pairs(art.pieces) do piece:SetDesaturated(false) end
	end
	for _, key in ipairs(BEHIND) do
		if art.pieces[key] then art.pieces[key]:SetAlpha(look.alpha) end
	end
	-- The theme's colors are back: a frame's own border color is off.
	if art.own then art.own:Hide() end
end

-- Puts a frame's own border color on a Blizzard look drawn on frame as kind
-- (st:SetBorderColor): a border's or a cut's pieces are tinted (the box's too,
-- desaturated, so the colour shows as itself); a button's or
-- an aura's own-color piece (its equipped or quality border, white art) is
-- shown in the color, over the icon's edge, on host as the ring is (Paint); a
-- small frame's line takes it. No color puts the theme's back: white pieces,
-- the own-color piece hidden, the line in the Border. A kind that draws
-- nothing (a control, a strip) or only a fill (a member) is left alone. Moves
-- nothing.
function ThemeArt.SetBorder(frame, look, kind, host, r, g, b, a)
	local blizzard = Kind(kind)
	if not Draws(blizzard) then return end
	a = a or 1

	if blizzard.line then
		if r then
			frame:SetBackdropBorderColor(r, g, b, a)
		else
			frame:SetBackdropBorderColor(unpack(look.colors.bordercolor))
		end
		return
	end

	local art = Art(frame)
	-- The raw table: the pieces and border aren't per client, and this runs on
	-- every bag slot update.
	local style = blizzard.art and ThemeArt.ART[blizzard.art]
	if not style then return end
	if blizzard.art == 'box' or style.TopLeftCorner or IsCut(style) then
		-- The box's bronze would tint muddy, so a colour goes on it grey: the
		-- colour shows as itself. No colour is the bronze.
		local grey = blizzard.art == 'box' and r ~= nil
		local change = blizzard.art == 'box' and (art.desaturated or false) ~= grey
		if change then art.desaturated = grey end
		for _, piece in pairs(art.pieces) do
			if change then piece:SetDesaturated(grey) end
			if r then piece:SetVertexColor(r, g, b, a) else piece:SetVertexColor(1, 1, 1, 1) end
		end
	elseif style.border then
		if not r then
			if art.own then art.own:Hide() end
			return
		end
		local own = art.own
		if own and art.ownStyle == style.border and art.ownHost == host then
			-- Already textured and placed for this art: only its color (a pass
			-- recolors every border it holds, and places nothing). A frame with no
			-- host keeps its holder above it, as every call did: Holder raises it.
			if not host then Holder(frame) end
			own:SetVertexColor(r, g, b, a)
			own:Show()
			return
		end
		own = Piece(art, host or Holder(frame), 'own', style.border, RING_LAYER, OWN_SUBLEVEL)
		art.ownStyle, art.ownHost = style.border, host
		st:SnapRegion(own)
		own:ClearAllPoints()
		own:SetAllPoints(frame)
		ThemeArt.CutOver(own, style)
		own:SetVertexColor(r, g, b, a)
	end
end

-- Lays and shows the cut ART[name] (the group border) on frame, a frame of
-- SaftUI's that is only that art, not a backdrop: its pieces at frame's
-- corners and along its edges (LayCut), white, kept as frame's art
-- (ThemeArt.Get). No fill, no kind and no colors: ThemeArt.Clear hides them.
-- Moves only the pieces.
function ThemeArt.PaintCut(frame, name)
	local cut = ThemeArt.ART[name]
	if not (cut and IsCut(cut)) then error(tostring(name) .. ' is not a cut', 2) end
	LayCut(Art(frame).pieces, frame, ForClient(cut))
end

-- Draws a Blizzard look (st:ResolveTheme) on frame as kind: a backdrop that
-- fills it the kind's inset in (a window's from under its title bar), with no
-- edge but a small frame's line (one line of frame's), and the kind's art; the
-- frame's other pieces are hidden. The inset is whole pixels of frame's own,
-- the record theme.lua just made (st:DrawnInset), and the top is the kind's
-- top in whole pixels. A kind that draws nothing is cleared. Then colors it. host is
-- the button of SaftUI's frame sits behind, whose ring is a texture of its own
-- (LayButton), or nil.
--
-- A kind in the box (ART.box) has it laid on frame's box frame (BoxFrame),
-- over the frame it borders: over, the frame a backdrop sits behind, with its
-- outer edge the kind's reach outside over (in whole pixels of over), or with
-- no over frame itself, the box on its own bounds. The box frame is one level
-- above that frame and its children (LevelAbove), where it was made when that
-- frame's level is secret.
function ThemeArt.Paint(frame, look, kind, host, pixel, over)
	local blizzard = Kind(kind)
	ThemeArt.Clear(frame)
	if not Draws(blizzard) then
		if frame.SetBackdrop then frame:SetBackdrop(nil) end
		return
	end

	if frame.SetBackdrop then
		local inset = st:DrawnInset(frame) or look.inset
		frame:SetBackdrop({
			bgFile = st.BLANK_TEX,
			edgeFile = blizzard.line and st.BLANK_TEX or nil,
			edgeSize = pixel and st.lineWeight * pixel or st.line,
			tile = false, tileSize = 0,
			insets = { left = inset, right = inset, top = ThemeArt.WholeTop(kind, frame, pixel), bottom = inset },
		})
	end

	-- The box is read for the client by LayBox; any other art here.
	local art = blizzard.art and blizzard.art ~= 'box' and ForClient(ThemeArt.ART[blizzard.art])
	if blizzard.art == 'box' then
		local target = over or frame
		local reach = over and ThemeArt.Whole(ThemeArt.Reach(kind), over, pixel) or 0
		local box = ThemeArt.BoxFrame(frame)
		box:ClearAllPoints()
		box:SetPoint('TOPLEFT', target, 'TOPLEFT', -reach, reach)
		box:SetPoint('BOTTOMRIGHT', target, 'BOTTOMRIGHT', reach, -reach)
		local level = ThemeArt.LevelAbove(target)
		if level then box:SetFrameLevel(level) end
		box:Show()
		ThemeArt.LayBox(Art(frame).pieces, box, false)
	elseif art and art.TopLeftCorner then
		LayBorder(Art(frame).pieces, frame, art)
	elseif art and IsCut(art) then
		LayCut(Art(frame).pieces, frame, art)
	elseif art and art.ring then
		LayButton(Art(frame), frame, art, host)
	end
	ThemeArt.Color(frame, look, kind)
end
