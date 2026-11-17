local st = SaftUI

--[[
	The Blizzard theme's art tables, st.ThemeArt.KINDS and st.ThemeArt.ART, with
	the helpers that build them. themeart.lua explains them and reads them; this
	file loads first, makes st.ThemeArt, and leaves the two tables and the two
	pieces of build state themeart.lua reads (ThemeArt.ATLASES, the atlases the
	tables name, and ThemeArt.PER_CLIENT, the metatable of a ByClient value) on it.
]]

local ThemeArt = {}
st.ThemeArt = ThemeArt

------------------------------------
--- Building the tables ------------
------------------------------------

-- Every atlas the tables name, marked as they're built: true for one both
-- clients have, or the client ('forever' or 'live') for one only that client
-- has, which only that client's art names.
local ATLASES = {}

local function Atlas(name, client)
	ATLASES[name] = client or true
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

ThemeArt.ATLASES = ATLASES
ThemeArt.PER_CLIENT = PER_CLIENT


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
--          aura has no border; a small frame is one line; a unit frame's
--          bronze box is 2, its pieces' outer 2px being the dark outline and
--          the rim; a party or raid member is a bare fill; and the rest draw
--          nothing, a control placing its own content. A kind drawn in the box
--          keeps the inset it had, so nothing placed by it moves (the box's
--          art sits outside the frame and over it, by reach).
--   art    the name in ART of the art it's drawn in; none draws no art.
--   reach  for a kind drawn in the box (ART.box): how far the box's outer
--          edge sits outside the frame it borders, on every side (4, a
--          starting value). Only the art reads it.
--   fill   the theme's color its backdrop is filled with: windowcolor for a
--          window, backdropcolor for the rest; none, no fill (the action and
--          item buttons' art behind the icon fills them).
--   line   a 1px line in the theme's Border around the fill: Thin's drawing,
--          in Blizzard's colors, for the few small frames with no art.
-- header, close and control are clear: a strip is a row on its window's
-- background, and the close button and each control show art of their own.
ThemeArt.KINDS = {
	window = { inset = ByClient(2, 2), art = 'metal', fill = 'windowcolor' },
	panel = { inset = ByClient(3, 3), art = 'box', reach = ByClient(4, 4), fill = 'backdropcolor' },
	bar = { inset = ByClient(3, 3), art = 'box', reach = ByClient(4, 4), fill = 'backdropcolor' },
	tooltip = { inset = ByClient(3, 3), art = 'box', reach = ByClient(4, 4), fill = 'backdropcolor' },
	action = { inset = ByClient(3, 3), art = 'action' },
	slot = { inset = ByClient(3, 3), art = 'slot' },
	aura = { inset = ByClient(0, 0), art = 'aura' },
	small = { inset = ByClient(1, 1), fill = 'backdropcolor', line = true },
	header = { inset = ByClient(0, 0) },
	close = { inset = ByClient(0, 0) },
	control = { inset = ByClient(0, 0) },
	unitframe = { inset = ByClient(2, 2), art = 'box', reach = ByClient(4, 4), fill = 'backdropcolor' },
	member = { inset = ByClient(0, 0), fill = 'backdropcolor' },
}

------------------------------------
--- The art ------------------------
------------------------------------

-- MinimalScrollBar's up and down arrows (its steppers), each normal, under
-- the mouse (hover) and pressed: the nudges' and the scroll bar's.
local MINIMAL_ARROWS = {
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
}

-- A border is Blizzard's nine-slice pieces, by their names, laid out as
-- Blizzard's nine-slice code lays them: each corner at the drawn frame's own corner,
-- offset by its x and y; the top and bottom edges between their corners, tiled
-- across; the side edges between theirs, tiled down. Every piece is in the
-- art's layer.
--
-- A cut is a border's eight pieces cut out of larger art by texture
-- coordinates (ThemeArt.Cut), for art Blizzard draws whole: pieces, by the
-- same keys, each { atlas, rect }, rect being { x0, x1, y0, y1 } in the
-- atlas's own pixels, ends exclusive; laid out by size (LayCut): each corner
-- size by size at the drawn frame's own corner, the edges between them, size
-- thick and stretched, every piece in the art's layer.

-- Blizzard's player and target frames (Blizzard_UnitFrame), which the unit
-- frame's box is cut from.
local UF_PLAYER = Atlas('UI-HUD-UnitFrame-Player-PortraitOn')
local UF_TARGET = Atlas('UI-HUD-UnitFrame-Target-PortraitOn')

-- Blizzard's raid group border, which the group border is cut from.
local GROUP_BORDER = Atlas('options_frame_child')

-- Blizzard's UniqueCornersLayout with the ui-hud-minimap-button kit, as retail's
-- minimap header draws it (Blizzard_Minimap/Mainline/Minimap.xml, BorderTop):
-- the corners are different sizes, so each edge runs between its own two.
local MINIMAP_BUTTON_KIT = {
	layer = 'BACKGROUND',
	TopLeftCorner = { atlas = Atlas('ui-hud-minimap-button-NineSlice-CornerTopLeft') },
	TopRightCorner = { atlas = Atlas('ui-hud-minimap-button-NineSlice-CornerTopRight') },
	BottomLeftCorner = { atlas = Atlas('ui-hud-minimap-button-NineSlice-CornerBottomLeft') },
	BottomRightCorner = { atlas = Atlas('ui-hud-minimap-button-NineSlice-CornerBottomRight') },
	TopEdge = { atlas = Atlas('_ui-hud-minimap-button-NineSlice-EdgeTop') },
	BottomEdge = { atlas = Atlas('_ui-hud-minimap-button-NineSlice-EdgeBottom') },
	LeftEdge = { atlas = Atlas('!ui-hud-minimap-button-NineSlice-EdgeLeft') },
	RightEdge = { atlas = Atlas('!ui-hud-minimap-button-NineSlice-EdgeRight') },
	Center = { atlas = Atlas('ui-hud-minimap-button-NineSlice-Center') },
}

-- Forever's minimap header button (Camelot's member, 152 x 23), which the box
-- is cut from on Forever.
local HEADER_BUTTON = Atlas('ui-hud-minimap-header-button', 'forever')

ThemeArt.ART = {
	-- The box, the Blizzard theme's one border (the round 3 design,
	-- docs/superpowers/specs/2026-11-17-saftui-blizzard-theme-one-border-design.md),
	-- on panels, bars, tooltips and unit frames: drawn by ThemeArt.Paint on a
	-- frame of SaftUI's over the frame it borders (ThemeArt.BoxFrame), its
	-- outer edge the kind's reach outside it, and laid by ThemeArt.LayBox.
	-- Forever's is a cut of the minimap header button: 6px corners and the
	-- edges between them, stretched; its rows from the top are a soft outline,
	-- the bronze rim, then an inner shadow into a translucent dark centre.
	-- centre is that centre's rectangle, drawn only where LayBox is asked for
	-- it (the micro menu's boxes); elsewhere the fill is the drawn frame's
	-- backdrop, in the theme's Background. Retail has no header button, and
	-- draws the same box as the ui-hud-minimap-button kit, its own drawing of
	-- it, its Center likewise only where asked. Starting rectangles, measured
	-- on the decoded art, to be tuned in game. A frame's own border color
	-- tints the pieces.
	box = ByClient({
		layer = 'BORDER',
		size = 6,
		pieces = {
			TopLeftCorner = { atlas = HEADER_BUTTON, rect = { 0, 6, 0, 6 } },
			TopRightCorner = { atlas = HEADER_BUTTON, rect = { 146, 152, 0, 6 } },
			BottomLeftCorner = { atlas = HEADER_BUTTON, rect = { 0, 6, 17, 23 } },
			BottomRightCorner = { atlas = HEADER_BUTTON, rect = { 146, 152, 17, 23 } },
			TopEdge = { atlas = HEADER_BUTTON, rect = { 6, 146, 0, 6 } },
			BottomEdge = { atlas = HEADER_BUTTON, rect = { 6, 146, 17, 23 } },
			LeftEdge = { atlas = HEADER_BUTTON, rect = { 0, 6, 6, 17 } },
			RightEdge = { atlas = HEADER_BUTTON, rect = { 146, 152, 6, 17 } },
		},
		centre = { 6, 146, 6, 17 },
	}, MINIMAP_BUTTON_KIT),

	-- The character frame's metal (NineSliceLayouts.ButtonFrameTemplateNoPortrait,
	-- Forever's after its Camelot offsets), on windows, without the portrait
	-- socket. Texel snapping is off, as Blizzard's disableSharpening has it. The
	-- top edge is the title bar, titleHeight down from the drawn frame's top;
	-- the close button sits in the top right corner's socket.
	--
	-- titleStrip is the part of the title bar a window's header sits in under
	-- Blizzard (panels.lua, st:HeaderInTitleBar): titleStrip tall, its bottom
	-- on the title bar's bottom, the window's top. It's Blizzard's own title
	-- strip, the TitleContainer its windows put their title in: 20 tall from 1
	-- below the frame's top (DefaultPanelBaseTemplate, SharedUIPanelTemplates.xml,
	-- the same on both branches), which on retail ends on the title bar's
	-- bottom, 21 down. Forever's title bar is 20 and the strip all of it: in
	-- the user's screenshot of a bag window (2026-11-11) its dark band runs
	-- from about 1 to 18 below the drawn frame's top and its lip from 19, so
	-- the strip is centred on the band. Even on both clients, so what's
	-- centred on it sits on whole pixels.
	metal = {
		layer = 'OVERLAY',
		snap = false,
		titleHeight = ByClient(20, 21),
		titleStrip = 20,
		TopLeftCorner = { atlas = Atlas('UI-Frame-Metal-CornerTopLeft'), x = -8, y = 16 },
		TopRightCorner = { atlas = Atlas('UI-Frame-Metal-CornerTopRight'), x = ByClient(2, 4), y = 16 },
		BottomLeftCorner = { atlas = Atlas('UI-Frame-Metal-CornerBottomLeft'), x = -8, y = ByClient(-8, -3) },
		BottomRightCorner = { atlas = Atlas('UI-Frame-Metal-CornerBottomRight'), x = ByClient(2, 4), y = ByClient(-8, -3) },
		TopEdge = { atlas = Atlas('_UI-Frame-Metal-EdgeTop') },
		BottomEdge = { atlas = Atlas('_UI-Frame-Metal-EdgeBottom') },
		LeftEdge = { atlas = Atlas('!UI-Frame-Metal-EdgeLeft') },
		RightEdge = { atlas = Atlas('!UI-Frame-Metal-EdgeRight') },
	},

	-- The unit frame's bronze box, a cut, on unit frames and their bars.
	-- Blizzard's player and target frames are each one shaped texture at a
	-- fixed size, the portrait ring and bar wells drawn in, which can't wrap a
	-- frame of any other size; their square ends can. The left corners and
	-- edge are cut from the target frame's left end, the right ones from the
	-- player frame's right end, and the top and bottom edges are a 1px column
	-- of the player frame's top and bottom, stretched across. Each
	-- rectangle puts the art's dark outline on a piece's outer pixel and its
	-- rim (bronze on Forever's Camelot members, grey on retail's) on the next
	-- one in, on every side: starting values, measured on the decoded art, to
	-- be tuned in game. Retail's art is its own drawing, so its rectangles are
	-- its own. A frame's own border color tints the pieces. The fill is the
	-- drawn frame's backdrop, in the theme's Background.
	unitframe = {
		layer = 'BORDER',
		size = 8,
		pieces = ByClient({
			TopLeftCorner = { atlas = UF_TARGET, rect = { 2, 10, 8, 16 } },
			BottomLeftCorner = { atlas = UF_TARGET, rect = { 2, 10, 48, 56 } },
			LeftEdge = { atlas = UF_TARGET, rect = { 2, 10, 30, 40 } },
			TopRightCorner = { atlas = UF_PLAYER, rect = { 187, 195, 11, 19 } },
			BottomRightCorner = { atlas = UF_PLAYER, rect = { 187, 195, 51, 59 } },
			RightEdge = { atlas = UF_PLAYER, rect = { 187, 195, 34, 42 } },
			TopEdge = { atlas = UF_PLAYER, rect = { 120, 121, 11, 19 } },
			BottomEdge = { atlas = UF_PLAYER, rect = { 120, 121, 51, 59 } },
		}, {
			TopLeftCorner = { atlas = UF_TARGET, rect = { 1, 9, 21, 29 } },
			BottomLeftCorner = { atlas = UF_TARGET, rect = { 1, 9, 48, 56 } },
			LeftEdge = { atlas = UF_TARGET, rect = { 1, 9, 30, 40 } },
			TopRightCorner = { atlas = UF_PLAYER, rect = { 186, 194, 24, 32 } },
			BottomRightCorner = { atlas = UF_PLAYER, rect = { 186, 194, 51, 59 } },
			RightEdge = { atlas = UF_PLAYER, rect = { 186, 194, 34, 42 } },
			TopEdge = { atlas = UF_PLAYER, rect = { 120, 121, 24, 32 } },
			BottomEdge = { atlas = UF_PLAYER, rect = { 120, 121, 51, 59 } },
		}),
	},

	-- The party and raid group border, a cut, around each group header's
	-- members (SaftUI-Unitframes/groups.lua, UF:GroupBorder), read as a control
	-- and drawn with ThemeArt.PaintCut on a frame of SaftUI's that is only
	-- the border. Blizzard's raid frames draw it around each group with Edit
	-- Mode's Display Border on (CompactRaidGroupTemplate's borderFrame), the
	-- whole atlas stretched; cut at 6px it stays crisp at any size: a 2-3px
	-- rim with rounded corners (bronze on Forever's Camelot member, which has
	-- a faint dark middle; retail's middle is clear). No middle is drawn: the
	-- members draw over the pieces' inner part. offsets put the border from
	-- the group's top left (left x, top y) to its bottom right (right x, bottom
	-- y), as CompactRaidGroup_UpdateBorder puts it around its first and last
	-- member. The same rectangles on both clients.
	groupborder = {
		layer = 'BORDER',
		size = 6,
		offsets = { -2, 2, 2, -3 },
		pieces = {
			TopLeftCorner = { atlas = GROUP_BORDER, rect = { 0, 6, 0, 6 } },
			TopRightCorner = { atlas = GROUP_BORDER, rect = { 22, 28, 0, 6 } },
			BottomLeftCorner = { atlas = GROUP_BORDER, rect = { 0, 6, 20, 26 } },
			BottomRightCorner = { atlas = GROUP_BORDER, rect = { 22, 28, 20, 26 } },
			TopEdge = { atlas = GROUP_BORDER, rect = { 6, 22, 0, 6 } },
			BottomEdge = { atlas = GROUP_BORDER, rect = { 6, 22, 20, 26 } },
			LeftEdge = { atlas = GROUP_BORDER, rect = { 0, 6, 6, 20 } },
			RightEdge = { atlas = GROUP_BORDER, rect = { 22, 28, 6, 20 } },
		},
	},

	-- The unit frames' bar fills (SaftUI-Unitframes/updaters.lua,
	-- UF.BlizzardFill), by bar: the raid frames' health and resource bars'
	-- fill art and the background behind it, and how each tiles, as
	-- CompactUnitFrame.xml's wrap modes tile them. The same atlases on both
	-- clients. The fills are neutral grey, so a bar's color tints them.
	unitbars = {
		health = { fill = Atlas('RaidFrame-Hp-Fill'), bg = Atlas('raidframe-hp-bg-white'), tileH = true, tileV = true },
		power = { fill = Atlas('_RaidFrame-Resource-Fill'), bg = Atlas('_RaidFrame-Resource-Background'), tileH = true, tileV = false },
	},

	-- The action button (ActionButtonTemplate): the art behind the icon, which
	-- fills the button, by its piece's key (BEHIND); the ring over the icon's
	-- edge; the equipped border, shown in a frame's own border color; and the
	-- state art, where SaftUI makes the state textures. Every piece over the
	-- icon (the ring, the border, hover, pushed, checked, the flash) is, in
	-- the template (Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml),
	-- artWidth x artHeight (46 x 45) anchored TOPLEFT on a templateButton
	-- (45 x 45) button, so its last column hangs past the button's right edge.
	-- SaftUI draws it filling the button and cut to the button's part by
	-- texture coordinates, the left templateButton/artWidth of it and
	-- templateButton/artHeight of its height (ThemeArt.CutOver), as the slot's
	-- ring is cut by ringSize; so it keeps Blizzard's scale at any size and no
	-- size is read from a frame. The pieces behind the icon are setAllPoints,
	-- the button exactly. The checked art is additive on Forever and plain on
	-- retail, the one line the two templates differ by.
	action = {
		artWidth = 46, artHeight = 45, templateButton = 45,
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

	-- /sui's size arrows, as Blizzard's expand and condense buttons
	-- (MaximizeMinimizeButtonFrameTemplate, Blizzard_SharedXML/Mainline/
	-- SharedUIPanelTemplates.xml, the same on both branches: the frame is 24
	-- square, set by its Size on retail and by its OnLoad on Forever, its two
	-- buttons setAllPoints, so each atlas is stretched to it): a button's
	-- normal, pushed and disabled art, and the additive RedButton-Highlight
	-- both share. grow takes the expand art (the Maximize button) and shrink
	-- the condense art (the Minimize button). Both clients have every atlas
	-- under these names (Forever's are the 32 square Camelot members, retail's
	-- 18x19), so both are marked for both; a client without them would be
	-- marked Atlas(name, client) and keep the Lucide chevrons.
	sizebutton = {
		size = 24,
		grow = {
			normal = Atlas('RedButton-Expand'),
			pushed = Atlas('RedButton-Expand-Pressed'),
			disabled = Atlas('RedButton-Expand-Disabled'),
		},
		shrink = {
			normal = Atlas('RedButton-Condense'),
			pushed = Atlas('RedButton-Condense-Pressed'),
			disabled = Atlas('RedButton-Condense-disabled'),
		},
		highlight = Atlas('RedButton-Highlight'),
		highlightBlend = 'ADD',
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

	-- The Settings dropdown (WowStyle2DropdownTemplate): one face in each
	-- state, outset round the button (its glow; compactOutset on a dropdown
	-- with no room for 7), the arrow hanging under it while the mouse is over,
	-- its text inset from the face's sides and pressedOffset while it's held
	-- down. Its list (MenuStyle2Mixin): c-bg, its border and shadow, at
	-- listOutsets round the list (TOPLEFT x, y, BOTTOMRIGHT x, y), the rows
	-- listInsets in from it (left, top, right, bottom), a row under the mouse
	-- on rowHover. Its steppers (DropdownWithSteppersTemplate's, on
	-- WowStyle2IconButtonTemplate's art): each width wide, back backGap left of
	-- the face and next nextGap right of it, a background in each state and
	-- the back or next icon (its disabled one while disabled), icon square.
	dropdown = {
		face = {
			normal = Atlas('common-dropdown-c-button'),
			hover = Atlas('common-dropdown-c-button-hover-1'),
			pressed = Atlas('common-dropdown-c-button-pressed-1'),
			pressedhover = Atlas('common-dropdown-c-button-pressedhover-1'),
			open = Atlas('common-dropdown-c-button-open'),
			disabled = Atlas('common-dropdown-c-button-disabled'),
		},
		hoverArrow = Atlas('common-dropdown-c-button-hover-arrow'),
		outset = 7, compactOutset = 4,
		textInset = 13, pressedOffset = { 2, -1 },
		list = Atlas('common-dropdown-c-bg'),
		listOutsets = { -17, 12, 17, -22 },
		listInsets = { 3, 6, 3, 7 },
		rowHover = Atlas('common-dropdown-customize-mouseover'),
		stepper = {
			width = 26, backGap = 5, nextGap = 4,
			background = {
				normal = Atlas('common-dropdown-c-button'),
				hover = Atlas('common-dropdown-c-button-hover-2'),
				pressed = Atlas('common-dropdown-c-button-pressed-2'),
				pressedhover = Atlas('common-dropdown-c-button-pressedhover-2'),
				disabled = Atlas('common-dropdown-c-button-disabled'),
			},
			back = Atlas('common-dropdown-icon-back'), backDisabled = Atlas('common-dropdown-icon-back-disabled'),
			next = Atlas('common-dropdown-icon-next'), nextDisabled = Atlas('common-dropdown-icon-next-disabled'),
			icon = 17,
		},
	},

	-- The slider (MinimalSliderWithSteppersTemplate): the track's ends and its
	-- middle, tiled across, the thumb, and the end arrows (back and forward),
	-- each arrowGap from the track.
	slider = {
		left = Atlas('Minimal_SliderBar_Left'),
		middle = Atlas('_Minimal_SliderBar_Middle'),
		right = Atlas('Minimal_SliderBar_Right'),
		thumb = Atlas('Minimal_SliderBar_Button'),
		back = Atlas('Minimal_SliderBar_Button_Left'),
		forward = Atlas('Minimal_SliderBar_Button_Right'),
		arrowGap = 4,
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

	-- A color swatch (ColorSwatchTemplate): a white square (HIGHLIGHT_FONT_COLOR),
	-- a black one inside it (BLACK_FONT_COLOR), and the color inside that. Only
	-- the two colors are kept: SaftUI draws them as the color field's swatch.
	swatch = {
		whiteColor = { 1, 1, 1, 1 },
		blackColor = { 0, 0, 0, 1 },
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
	nudge = { up = MINIMAL_ARROWS.up, down = MINIMAL_ARROWS.down },

	-- The scroll bar (MinimalScrollBar): the track's top and bottom ends and
	-- its middle, tiled down; the thumb's (its small thumb's) top, middle and
	-- bottom in each state, under the mouse (over) and held (down); and the
	-- up and down arrows, the nudges' own. The track is width wide; a wide
	-- bar's arrows are arrow (width, height) and the track starts inset in
	-- from the column's ends, a narrow bar's (the sidebar's, a dialog's, a
	-- list's) narrowArrow and narrowInset. The thumb is never shorter than
	-- minThumb (MinimalScrollBar's minThumbExtent).
	scrollbar = {
		track = {
			top = Atlas('minimal-scrollbar-track-top'),
			middle = Atlas('!minimal-scrollbar-track-middle'),
			bottom = Atlas('minimal-scrollbar-track-bottom'),
		},
		thumb = {
			normal = {
				top = Atlas('minimal-scrollbar-small-thumb-top'),
				middle = Atlas('minimal-scrollbar-small-thumb-middle'),
				bottom = Atlas('minimal-scrollbar-small-thumb-bottom'),
			},
			over = {
				top = Atlas('minimal-scrollbar-small-thumb-top-over'),
				middle = Atlas('minimal-scrollbar-small-thumb-middle-over'),
				bottom = Atlas('minimal-scrollbar-small-thumb-bottom-over'),
			},
			down = {
				top = Atlas('minimal-scrollbar-small-thumb-top-down'),
				middle = Atlas('minimal-scrollbar-small-thumb-middle-down'),
				bottom = Atlas('minimal-scrollbar-small-thumb-bottom-down'),
			},
		},
		up = MINIMAL_ARROWS.up, down = MINIMAL_ARROWS.down,
		width = 8, arrow = { 17, 11 }, narrowArrow = { 8, 5 },
		inset = 19, narrowInset = 9, minThumb = 23,
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
		-- A page's name: gold, white when it's open or under the mouse
		-- (the Settings panel's NORMAL_FONT_COLOR and HIGHLIGHT_FONT_COLOR).
		text = { normal = { 1, 0.82, 0 }, picked = { 1, 1, 1 } },
	},

	-- The Settings panel's inner frame (SettingsFrameTemplate): one bitmap,
	-- width wide at its own size, with its dark edge, its bronze rim and the
	-- line between the category list and the settings drawn in, at divider
	-- across. /sui stretches it over its sidebar and main column and puts the
	-- sidebar's right edge on that line (OptionsWindow.SidebarWidth).
	optionswindow = {
		inner = Atlas('Options_InnerFrame'),
		width = 886,
		divider = 199,
		-- The category list's group banners, in turn (the Settings panel's
		-- SettingsCategoryListHeaderTemplate), the line under the tab rows,
		-- and a group header's height and label place.
		banners = { Atlas('Options_CategoryHeader_1'), Atlas('Options_CategoryHeader_2'), Atlas('Options_CategoryHeader_3') },
		rule = Atlas('Options_HorizontalDivider'),
		groupHeight = 30,
		groupLabel = { x = 20, y = -1 },
	},

	-- /sui's resize grip, as Blizzard's (PanelResizeButtonTemplate,
	-- Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml, the same on both
	-- clients): size square, its normal, highlight and pushed files, the
	-- highlight additive (a HighlightTexture's default).
	resizegrip = {
		normal = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]],
		highlight = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]],
		pushed = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]],
		highlightBlend = 'ADD',
		size = 16,
	},

	-- The current target's nameplate border (SaftUI-Unitframes/nameplates/
	-- target.lua): Blizzard's selected-plate art, drawn round the health bar.
	-- offsets are how far its TOPLEFT and BOTTOMRIGHT sit from the bar's
	-- (left, top, right, bottom), Blizzard's anchors summed: the plate's
	-- bgTexture round the bar at (-2, 3) and (6, -6)
	-- (Blizzard_NamePlateUnitFrame.lua), and the selected border round that,
	-- Camelot's SELECTED_BORDER_OFFSETS on Forever and retail's own. Starting
	-- values, to check in game.
	nameplatetarget = ByClient({
		atlas = Atlas('UI-HUD-CoolDownManager-Selected-yellow', 'forever'),
		offsets = { -5, 5, 6, -4 },
		layer = 'OVERLAY',
	}, {
		atlas = Atlas('UI-HUD-Nameplates-Selected', 'live'),
		offsets = { -3, 4, 3, -3 },
		layer = 'OVERLAY',
	}),

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

	-- The micro menu bar's art under Blizzard (Control('microbar')). Forever
	-- draws Camelot's: the action bar's frame as the strip under the micro
	-- buttons, with its icon background inside it, and each box (the header,
	-- the addon indicator square, the tracking button) as one atlas. Retail has
	-- no strip, and draws each box as the ui-hud-minimap-button kit, as its
	-- minimap header does. pad and backgroundInset are how far the strip and its
	-- background reach outside the buttons and in from the strip.
	microbar = ByClient({
		strip = { frame = Atlas('UI-HUD-ActionBar-Frame'), background = Atlas('UI-HUD-ActionBar-IconFrame-Background'), pad = 4, backgroundInset = 2 },
		header = { atlas = Atlas('ui-hud-minimap-header-button', 'forever'), height = 23 },
		square = { atlas = Atlas('ui-hud-minimap-addon-indicator', 'forever'), width = 23, height = 22 },
		-- icon: the art has the item's icon drawn in.
		tracking = { atlas = Atlas('ui-hud-minimap-tracking-button', 'forever'), width = 23, height = 23, icon = true },
	}, {
		strip = false,
		header = { kit = MINIMAP_BUTTON_KIT },
		square = { kit = MINIMAP_BUTTON_KIT },
		tracking = { kit = MINIMAP_BUTTON_KIT },
	}),

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
