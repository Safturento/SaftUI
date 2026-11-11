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

	The tables, st.ThemeArt.KINDS and st.ThemeArt.ART:
	  KINDS[kind]  each kind of frame (st.THEME_KINDS) under Blizzard: its inset
	               on each client, the art it's drawn in (a name in ART), its
	               fill (one of the theme's colors) and whether it's a 1px line.
	  ART[name]    each piece of art: the tooltip border and the metal, the
	               action and item buttons', the aura's, the close button's, and
	               each control's (CONTROLS), which st.ThemeArt.Control reads.
	A value that differs by client is ByClient(forever, live); the accessors
	give this client's. An art name that starts with Interface\ is a file;
	every other is an atlas, and is marked Atlas() where the tables name it, so
	st:ThemeAtlases can list them all (the tests check each exists on both
	clients).
]]

local ThemeArt = {}
st.ThemeArt = ThemeArt

------------------------------------
--- Building the tables ------------
------------------------------------

-- Every atlas the tables name, marked as they're built.
local ATLASES = {}

local function Atlas(name)
	ATLASES[name] = true
	return name
end

-- Edit Mode's two kits of selection art. A mover's atlases are formats of the
-- kit (%s), so each is marked for both.
local MOVER_KITS = {
	highlight = 'editmode-actionbar-highlight', -- Blizzard's blue outline, on every frame
	selected = 'editmode-actionbar-selected',   -- the yellow one, on the frame being moved
}

local function Kit(format)
	for _, kit in pairs(MOVER_KITS) do Atlas(format:format(kit)) end
	return format
end

-- Holy power's runes are a format of the point (%d), one atlas for each of the
-- count points.
local function Runes(format, count)
	for point = 1, count do Atlas(format:format(point)) end
	return format
end

local PER_CLIENT = {}

-- A value that differs by client.
local function ByClient(forever, live)
	return setmetatable({ forever = forever, live = live }, PER_CLIENT)
end

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

------------------------------------
--- The kinds ----------------------
------------------------------------

-- Each kind of frame under Blizzard (the spec's "Each kind under Blizzard"):
--   inset  how far its art reaches in from the drawn frame's edge on its
--          sides: where content starts to stay uncovered. These are starting
--          values, the same on both clients until they're measured in game:
--          the tooltip border's corners are 7px, with Blizzard's fill starting
--          4px inside them (3); a window's background starts 2px in; the
--          action and item rings have no layout to measure them by (3); an
--          aura has no border; a small frame is one line; and the rest draw
--          nothing, a control placing its own content.
--   art    the name in ART of the art it's drawn in; none draws no art.
--   fill   the theme's color its backdrop is filled with: windowcolor for a
--          window, backdropcolor for the rest; none, no fill (the action and
--          item buttons' art behind the icon fills them).
--   line   a 1px line in the theme's Border around the fill: Thin's drawing,
--          in Blizzard's colors, for the few small frames with no art.
-- header, close and control are clear: a strip is a row on its window's
-- background, and the close button and each control show art of their own.
ThemeArt.KINDS = {
	window = { inset = ByClient(2, 2), art = 'metal', fill = 'windowcolor' },
	panel = { inset = ByClient(3, 3), art = 'tooltip', fill = 'backdropcolor' },
	bar = { inset = ByClient(3, 3), art = 'tooltip', fill = 'backdropcolor' },
	tooltip = { inset = ByClient(3, 3), art = 'tooltip', fill = 'backdropcolor' },
	action = { inset = ByClient(3, 3), art = 'action' },
	slot = { inset = ByClient(3, 3), art = 'slot' },
	aura = { inset = ByClient(0, 0), art = 'aura' },
	small = { inset = ByClient(1, 1), fill = 'backdropcolor', line = true },
	header = { inset = ByClient(0, 0) },
	close = { inset = ByClient(0, 0) },
	control = { inset = ByClient(0, 0) },
}

------------------------------------
--- The art ------------------------
------------------------------------

-- A border is Blizzard's nine-slice pieces, by their names, laid out as
-- Blizzard's nine-slice code lays them: each corner at the drawn frame's own corner,
-- offset by its x and y; the top and bottom edges between their corners, tiled
-- across; the side edges between theirs, tiled down. Every piece is in the
-- art's layer.
ThemeArt.ART = {
	-- The tooltip border (NineSliceLayouts.TooltipDefaultLayout), on panels,
	-- bars and tooltips. Its art is white, and a frame's own border color tints
	-- it. Blizzard's fill (Tooltip-NineSlice-Center) isn't drawn: the fill is
	-- the drawn frame's backdrop, in the theme's Background.
	tooltip = {
		layer = 'BORDER',
		TopLeftCorner = { atlas = Atlas('Tooltip-NineSlice-CornerTopLeft') },
		TopRightCorner = { atlas = Atlas('Tooltip-NineSlice-CornerTopRight') },
		BottomLeftCorner = { atlas = Atlas('Tooltip-NineSlice-CornerBottomLeft') },
		BottomRightCorner = { atlas = Atlas('Tooltip-NineSlice-CornerBottomRight') },
		TopEdge = { atlas = Atlas('_Tooltip-NineSlice-EdgeTop') },
		BottomEdge = { atlas = Atlas('_Tooltip-NineSlice-EdgeBottom') },
		LeftEdge = { atlas = Atlas('!Tooltip-NineSlice-EdgeLeft') },
		RightEdge = { atlas = Atlas('!Tooltip-NineSlice-EdgeRight') },
	},

	-- The character frame's metal (NineSliceLayouts.ButtonFrameTemplateNoPortrait,
	-- Forever's after its Camelot offsets), on windows, without the portrait
	-- socket. Texel snapping is off, as Blizzard's disableSharpening has it. The
	-- top edge is the title bar, titleHeight down from the drawn frame's top;
	-- the close button sits in the top right corner's socket.
	metal = {
		layer = 'OVERLAY',
		snap = false,
		titleHeight = ByClient(20, 21),
		TopLeftCorner = { atlas = Atlas('UI-Frame-Metal-CornerTopLeft'), x = -8, y = 16 },
		TopRightCorner = { atlas = Atlas('UI-Frame-Metal-CornerTopRight'), x = ByClient(2, 4), y = 16 },
		BottomLeftCorner = { atlas = Atlas('UI-Frame-Metal-CornerBottomLeft'), x = -8, y = ByClient(-8, -3) },
		BottomRightCorner = { atlas = Atlas('UI-Frame-Metal-CornerBottomRight'), x = ByClient(2, 4), y = ByClient(-8, -3) },
		TopEdge = { atlas = Atlas('_UI-Frame-Metal-EdgeTop') },
		BottomEdge = { atlas = Atlas('_UI-Frame-Metal-EdgeBottom') },
		LeftEdge = { atlas = Atlas('!UI-Frame-Metal-EdgeLeft') },
		RightEdge = { atlas = Atlas('!UI-Frame-Metal-EdgeRight') },
	},

	-- The action button (ActionButtonTemplate): the art behind the icon, which
	-- fills the button, by its piece's key (BEHIND); the ring over the icon's
	-- edge; the equipped border, shown in a frame's own border color; and the
	-- state art, where SaftUI makes the state textures, over the ring's
	-- footprint. The checked art is additive on Forever and plain on retail, the
	-- one line the two templates differ by.
	action = {
		behind = {
			SlotBackground = Atlas('UI-HUD-ActionBar-IconFrame-Background'),
			SlotArt = Atlas('UI-HUD-ActionBar-IconFrame-Slot'),
		},
		ring = Atlas('UI-HUD-ActionBar-IconFrame'),
		border = Atlas('UI-HUD-ActionBar-IconFrame-Border'),
		states = {
			hover = Atlas('UI-HUD-ActionBar-IconFrame-Mouseover'),
			pushed = Atlas('UI-HUD-ActionBar-IconFrame-Down'),
			checked = Atlas('UI-HUD-ActionBar-IconFrame-Mouseover'),
			checkedBlend = ByClient('ADD', 'BLEND'),
			flash = Atlas('UI-HUD-ActionBar-IconFrame-Flash'),
		},
	},

	-- The item button (ItemButtonTemplate), on bag slots: the empty slot behind
	-- the icon; the ring over its edge, which Blizzard draws ringSize on a
	-- buttonSize button, centred ringY low; the quality frame, shown in a
	-- frame's own border color; and the pushed and highlight art.
	slot = {
		behind = { SlotArt = Atlas('bags-item-slot64') },
		ring = [[Interface\Buttons\UI-Quickslot2]],
		ringSize = 64, buttonSize = 37, ringY = -1,
		border = [[Interface\Common\WhiteIconFrame]],
		states = {
			pushed = [[Interface\Buttons\UI-Quickslot-Depress]],
			highlight = [[Interface\Buttons\ButtonHilight-Square]],
			highlightBlend = 'ADD',
		},
	},

	-- An aura is bare, as Blizzard draws a buff. A frame's own border color
	-- shows the item button's quality frame, in that color.
	aura = {
		border = [[Interface\Common\WhiteIconFrame]],
	},

	-- Blizzard's red close button (UIPanelCloseButton): its four textures, its
	-- size, and on a window its spot from TOPRIGHT of the window's drawn frame.
	close = {
		size = ByClient(28, 24),
		x = ByClient(0, 1),
		y = ByClient(3, 0),
		normal = Atlas('RedButton-Exit'),
		pushed = Atlas('RedButton-exit-pressed'),
		highlight = Atlas('RedButton-Highlight'),
		highlightBlend = 'ADD',
		disabled = Atlas('RedButton-Exit-Disabled'),
	},

	-- The controls. Each is drawn inside its own rect, by the control's own code.

	-- SaftUI's buttons, as Blizzard's panel button (UIPanelButtonNoTooltipTemplate):
	-- Left, Middle and Right from one file at these texture coordinates (left,
	-- right, top, bottom), swapped to down on a mouse down and to disabled while
	-- disabled; each end endShare of the button's height wide (12 on Blizzard's
	-- 22); and the additive highlight (UIPanelButtonHighlightTexture).
	button = {
		up = [[Interface\Buttons\UI-Panel-Button-Up]],
		down = [[Interface\Buttons\UI-Panel-Button-Down]],
		disabled = [[Interface\Buttons\UI-Panel-Button-Disabled]],
		left = { 0, 0.09375, 0, 0.6875 },
		middle = { 0.09375, 0.53125, 0, 0.6875 },
		right = { 0.53125, 0.625, 0, 0.6875 },
		endShare = 12 / 22,
		highlight = [[Interface\Buttons\UI-Panel-Button-Highlight]],
		highlightCoords = { 0, 0.625, 0, 0.6875 },
		highlightBlend = 'ADD',
	},

	-- Every check box, as the Settings panel's (MinimalCheckboxArtTemplate): the
	-- box, the check while checked, the check while checked and disabled, and
	-- the highlight, the box's own art again, additive. The box is 26 of the
	-- art's 30 wide and 25 of its 29 tall, with 2 clear all round, so the art
	-- drawn 1px outside SaftUI's 12px check box shows its box at 12.
	checkbox = {
		normal = Atlas('checkbox-minimal'),
		checked = Atlas('checkmark-minimal'),
		disabledChecked = Atlas('checkmark-minimal-disabled'),
		highlight = Atlas('checkbox-minimal'),
		highlightBlend = 'ADD',
	},

	-- A radio group's buttons, as Blizzard's top tabs (PanelTabButtonTemplate):
	-- the picked one and the others, each a left end, a middle tiled across and
	-- a right end.
	tab = {
		picked = {
			left = Atlas('uiframe-activetab-left'),
			middle = Atlas('_uiframe-activetab-center'),
			right = Atlas('uiframe-activetab-right'),
		},
		other = {
			left = Atlas('uiframe-tab-left'),
			middle = Atlas('_uiframe-tab-center'),
			right = Atlas('uiframe-tab-right'),
		},
	},

	-- The dropdown (WowStyle1DropdownTemplate): the holder behind its text, the
	-- arrow in each state, and its list's background at listAlpha
	-- (MenuStyle1Mixin).
	dropdown = {
		text = Atlas('common-dropdown-textholder'),
		arrow = {
			normal = Atlas('common-dropdown-a-button'),
			hover = Atlas('common-dropdown-a-button-hover'),
			pressed = Atlas('common-dropdown-a-button-pressed'),
			open = Atlas('common-dropdown-a-button-open'),
			disabled = Atlas('common-dropdown-a-button-disabled'),
		},
		list = Atlas('common-dropdown-bg'),
		listAlpha = 0.925,
	},

	-- The slider (MinimalSliderTemplate): the track's ends and its middle,
	-- tiled across, and the thumb.
	slider = {
		left = Atlas('Minimal_SliderBar_Left'),
		middle = Atlas('_Minimal_SliderBar_Middle'),
		right = Atlas('Minimal_SliderBar_Right'),
		thumb = Atlas('Minimal_SliderBar_Button'),
	},

	-- A text box (InputBoxTemplate).
	input = {
		left = Atlas('auctionhouse-ui-inputfield-left'),
		middle = Atlas('auctionhouse-ui-inputfield-middle'),
		right = Atlas('auctionhouse-ui-inputfield-right'),
	},

	-- The search box (SearchBoxTemplate), with its magnifying glass.
	search = {
		left = Atlas('common-search-border-left'),
		middle = Atlas('common-search-border-middle'),
		right = Atlas('common-search-border-right'),
		icon = Atlas('common-search-magnifyingglass'),
	},

	-- A color swatch (ColorSwatchTemplate): plain squares, centred, at the
	-- template's sizes: white (HIGHLIGHT_FONT_COLOR), black inside it
	-- (BLACK_FONT_COLOR), and the color inside that.
	swatch = {
		size = 16,
		white = 14, whiteColor = { 1, 1, 1, 1 },
		black = 12, blackColor = { 0, 0, 0, 1 },
		color = 10,
	},

	-- The key binding button (KeyBindingFrameBindingButtonTemplate, on
	-- UIMenuButtonStretchTemplate): nine pieces of one file at these texture
	-- coordinates, the corners cornerWidth by cornerHeight, swapped to down while
	-- pressed; the additive highlight; and select while it waits for a key.
	binding = {
		up = [[Interface\Buttons\UI-Silver-Button-Up]],
		down = [[Interface\Buttons\UI-Silver-Button-Down]],
		cornerWidth = 12, cornerHeight = 6,
		pieces = {
			TopLeft = { 0, 0.09375, 0, 0.1875 },
			TopMiddle = { 0.09375, 0.53125, 0, 0.1875 },
			TopRight = { 0.53125, 0.625, 0, 0.1875 },
			MiddleLeft = { 0, 0.09375, 0.1875, 0.625 },
			MiddleMiddle = { 0.09375, 0.53125, 0.1875, 0.625 },
			MiddleRight = { 0.53125, 0.625, 0.1875, 0.625 },
			BottomLeft = { 0, 0.09375, 0.625, 0.8125 },
			BottomMiddle = { 0.09375, 0.53125, 0.625, 0.8125 },
			BottomRight = { 0.53125, 0.625, 0.625, 0.8125 },
		},
		highlight = [[Interface\Buttons\UI-Silver-Button-Highlight]],
		highlightCoords = { 0, 1, 0.03, 0.7175 },
		highlightBlend = 'ADD',
		select = [[Interface\Buttons\UI-Silver-Button-Select]],
		selectBlend = 'ADD',
	},

	-- The up and down nudges, as MinimalScrollBar's steppers.
	nudge = {
		up = {
			normal = Atlas('minimal-scrollbar-arrow-top'),
			hover = Atlas('minimal-scrollbar-arrow-top-over'),
			pressed = Atlas('minimal-scrollbar-arrow-top-down'),
		},
		down = {
			normal = Atlas('minimal-scrollbar-arrow-bottom'),
			hover = Atlas('minimal-scrollbar-arrow-bottom-over'),
			pressed = Atlas('minimal-scrollbar-arrow-bottom-down'),
		},
	},

	-- The Settings panel's tabs (MinimalTabTemplate): the picked one and the
	-- others, each a left end, a middle and a right end.
	optionstab = {
		picked = {
			left = Atlas('Options_Tab_Active_Left'),
			middle = Atlas('Options_Tab_Active_Middle'),
			right = Atlas('Options_Tab_Active_Right'),
		},
		other = {
			left = Atlas('Options_Tab_Left'),
			middle = Atlas('Options_Tab_Middle'),
			right = Atlas('Options_Tab_Right'),
		},
	},

	-- The Settings panel's category list: the open page, and one under the mouse.
	optionslist = {
		picked = Atlas('Options_List_Active'),
		hover = Atlas('Options_List_Hover'),
	},

	-- Blizzard's micro buttons' own art, given back by name: the pushed
	-- background, the alert border, and the highlight Blizzard's code sets,
	-- named from the button's textureName (a format of it, %s, so it isn't
	-- among st:ThemeAtlases).
	micro = {
		pushedBackground = Atlas('UI-HUD-MicroMenu-ButtonBG-Down'),
		flashBorder = Atlas('UI-HUD-MicroMenu-Highlightalert'),
		highlight = 'UI-HUD-MicroMenu-%s-Mouseover',
		highlightBlend = 'BLEND',
	},

	-- Edit Mode's selection (EditModeSystemSelectionLayout), drawn on a mover's
	-- outline: the highlight kit on every mover, the selected kit on the one
	-- being moved. Each atlas is a format of the kit (%s). The corners are one
	-- atlas, mirrored as Blizzard's nine-slice code mirrors it, 8px outside
	-- the frame; the fill runs from the top left corner's inner point to the
	-- bottom right's, each 8px back out, so it covers the frame.
	mover = {
		kits = MOVER_KITS,
		layer = 'BORDER',
		TopLeftCorner = { atlas = Kit('%s-NineSlice-Corner'), mirror = true, x = -8, y = 8 },
		TopRightCorner = { atlas = Kit('%s-NineSlice-Corner'), mirror = true, x = 8, y = 8 },
		BottomLeftCorner = { atlas = Kit('%s-NineSlice-Corner'), mirror = true, x = -8, y = -8 },
		BottomRightCorner = { atlas = Kit('%s-NineSlice-Corner'), mirror = true, x = 8, y = -8 },
		TopEdge = { atlas = Kit('_%s-NineSlice-EdgeTop') },
		BottomEdge = { atlas = Kit('_%s-NineSlice-EdgeBottom') },
		LeftEdge = { atlas = Kit('!%s-NineSlice-EdgeLeft') },
		RightEdge = { atlas = Kit('!%s-NineSlice-EdgeRight') },
		Center = { atlas = Kit('%s-NineSlice-Center'), x = -8, y = 8, x1 = 8, y1 = -8 },
	},

	-- Class power points, as Blizzard_UnitFrame's class resource bars draw
	-- them, by oUF's power type: each point's empty art and its filled art.
	-- Combo points differ by class, and a rogue's charged point is blue. Holy
	-- power has a rune of its own for each point (a format of the point, %d,
	-- 1 to runes). Forever has only combo points; every atlas is on both
	-- clients.
	classpower = {
		COMBO_POINTS = {
			byClass = {
				ROGUE = { empty = Atlas('uf-roguecp-bg'), filled = Atlas('uf-roguecp-icon-red'), charged = Atlas('uf-roguecp-icon-blue') },
				DRUID = { empty = Atlas('UF-DruidCP-BG-Active'), filled = Atlas('UF-DruidCP-Icon') },
			},
		},
		HOLY_POWER = { empty = Runes('uf-holypower-rune%d', 5), filled = Runes('uf-holypower-rune%d-active', 5), runes = 5 },
		SOUL_SHARDS = { empty = Atlas('UF-SoulShard-Holder'), filled = Atlas('UF-SoulShard-Icon') },
		CHI = { empty = Atlas('uf-chi-bg'), filled = Atlas('uf-chi-icon') },
		ARCANE_CHARGES = { empty = Atlas('UF-Arcane-BG'), filled = Atlas('UF-Arcane-Icon') },
		ESSENCE = { empty = Atlas('UF-Essence-BG'), filled = Atlas('UF-Essence-Icon') },
	},
}

-- The names in ART that are controls (st.ThemeArt.Control).
local CONTROLS = {
	button = true, checkbox = true, tab = true, dropdown = true, slider = true,
	input = true, search = true, swatch = true, binding = true, nudge = true,
	optionstab = true, optionslist = true, micro = true, mover = true, classpower = true,
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

-- How far the metal's title bar reaches down from a window's drawn frame's
-- top, on this client.
function ThemeArt.TitleHeight()
	return ForClient(ThemeArt.ART.metal.titleHeight)
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

-- Puts Blizzard's state art (name, an atlas or a file from State) on texture,
-- one of a button's state textures of SaftUI's (the hover, pushed or checked
-- texture; the flash too): over the button's whole footprint, white, with no
-- tint, blending as blend says (the button's own call sets the highlight's),
-- and drawn in layer: the state layer above the ring when it's nil, the layer
-- it has when it's false (the flash), or the layer named (the hover:
-- HOVER_LAYER). A flat state texture is put back by its own code (StyleButton
-- in the action bars' skin, st:SkinActionButton, the totem skin), not here.
function ThemeArt.StyleState(texture, name, button, blend, layer)
	if name:find([[Interface\]], 1, true) == 1 then
		texture:SetTexture(name)
		texture:SetTexCoord(0, 1, 0, 1)
	else
		texture:SetAtlas(name)
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

-- Every atlas the Blizzard theme's tables name, as { [name] = true }: the
-- controls' too, a mover's for both kits and holy power's for each rune, but
-- no file. The tests check each exists on both clients.
function st:ThemeAtlases()
	local names = {}
	for name in pairs(ATLASES) do names[name] = true end
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
-- drawn frame, a button's ring on the button of SaftUI's it sits behind, or
-- else on a frame of SaftUI's over the drawn frame (Holder). They're kept
-- here, never in a field on a frame (.agents/taint.md), and placed by anchors
-- and offsets: no size is read back from the game.

-- drawn frame -> its art, { pieces, over, own } (ThemeArt.Get).
local drawnArt = setmetatable({}, { __mode = 'k' })

-- drawn frame -> the frame of SaftUI's its over pieces are on (Holder).
local holders = setmetatable({}, { __mode = 'k' })

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
-- at sublevel, showing name (a file, or else an atlas at its own size), white
-- and shown.
local function Piece(set, parent, key, name, layer, sublevel)
	local piece = set[key]
	if not piece then
		piece = parent:CreateTexture(nil, layer)
		set[key] = piece
	end
	piece:SetDrawLayer(layer, sublevel or 0)
	if name:find([[Interface\]], 1, true) == 1 then
		piece:SetTexture(name)
	else
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

-- A border (the tooltip's or the metal) on frame: its corners, then its edges
-- between them, in its layer. Pixel snapping is off where the border says so,
-- with the texel snapping bias at 0, as Blizzard's nine-slice code turns
-- sharpening off; for any other border it's on, the game's default, so a piece
-- once drawn as the metal doesn't keep it off. The bias stays: Blizzard's code
-- never sets it back, and nothing gives its default.
local function LayBorder(art, frame, border)
	local function Lay(key)
		local piece = Piece(art.pieces, frame, key, border[key].atlas, border.layer)
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
		piece:SetPoint(edge.point, art.pieces[edge.first], edge.to)
		piece:SetPoint(edge.to, art.pieces[edge.last], edge.point)
		piece:SetHorizTile(edge.across)
		piece:SetVertTile(not edge.across)
	end
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
-- level with the own-color piece, so it covers the ring's whole footprint,
-- over the icon and under the texts,
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
-- icon, filling frame, and the ring over the icon's edge, covering frame. The
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

-- Hides every piece of frame's art: for a frame drawn in another look, or None.
function ThemeArt.Clear(frame)
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
	for _, key in ipairs(BEHIND) do
		if art.pieces[key] then art.pieces[key]:SetAlpha(look.alpha) end
	end
	-- The theme's colors are back: a frame's own border color is off.
	if art.own then art.own:Hide() end
end

-- Puts a frame's own border color on a Blizzard look drawn on frame as kind
-- (st:SetBorderColor): a border's pieces are tinted; a button's or an aura's
-- own-color piece (its equipped or quality border, white art) is shown in the
-- color, over the icon's edge, on host as the ring is (Paint); a small frame's
-- line takes it. No color puts the theme's back: white pieces, the own-color
-- piece hidden, the line in the Border. A kind that draws nothing (a control,
-- a strip) is left alone. Moves nothing.
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
	if style.TopLeftCorner then
		for _, piece in pairs(art.pieces) do
			if r then piece:SetVertexColor(r, g, b, a) else piece:SetVertexColor(1, 1, 1, 1) end
		end
	elseif style.border then
		if not r then
			if art.own then art.own:Hide() end
			return
		end
		local own = Piece(art, host or Holder(frame), 'own', style.border, RING_LAYER, OWN_SUBLEVEL)
		own:ClearAllPoints()
		own:SetAllPoints(frame)
		own:SetVertexColor(r, g, b, a)
	end
end

-- Draws a Blizzard look (st:ResolveTheme) on frame as kind: a backdrop that
-- fills it the kind's inset in (a window's from under its title bar), with no
-- edge but a small frame's line, and the kind's art; the frame's other pieces
-- are hidden. A kind that draws nothing is cleared. Then colors it. host is
-- the button of SaftUI's frame sits behind, whose ring is a texture of its own
-- (LayButton), or nil.
function ThemeArt.Paint(frame, look, kind, host)
	local blizzard = Kind(kind)
	ThemeArt.Clear(frame)
	if not Draws(blizzard) then
		if frame.SetBackdrop then frame:SetBackdrop(nil) end
		return
	end

	if frame.SetBackdrop then
		local inset = look.inset
		frame:SetBackdrop({
			bgFile = st.BLANK_TEX,
			edgeFile = blizzard.line and st.BLANK_TEX or nil,
			edgeSize = 1,
			tile = false, tileSize = 0,
			insets = { left = inset, right = inset, top = ThemeArt.Top(kind), bottom = inset },
		})
	end

	local art = blizzard.art and ForClient(ThemeArt.ART[blizzard.art])
	if art and art.TopLeftCorner then
		LayBorder(Art(frame), frame, art)
	elseif art and art.ring then
		LayButton(Art(frame), frame, art, host)
	end
	ThemeArt.Color(frame, look, kind)
end
