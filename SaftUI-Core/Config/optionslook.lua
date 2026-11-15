local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The look the options window's controls share (st.OptionsWidgets,
	optionswidgets.lua): the field font, Box and its blue edge, each
	control's Blizzard art under SaftUI's theme Blizzard, and the check box
	the toggle, the multiselect and the check list draw.
]]

local floor, max = math.floor, math.max

------------------------------------------------------------------ look

-- The mockup's colors (the thick template's, and the field fill).
local FIELD, EDGE, ALT, BG = st.BOX_COLORS.field, st.BOX_COLORS.edge, st.BOX_COLORS.alt, st.BOX_COLORS.bg

local Colors = st.OptionsModel.Colors

-- The window's font for fields and lists: Text's face and outline, at 15.
local fieldFont
local FIELD_FONT_SIZE = 15
function W.GetFont()
	if not fieldFont then
		fieldFont = _G.SaftUI_OptionsFieldFont or CreateFont('SaftUI_OptionsFieldFont')
		W.UpdateFonts()
	end
	return fieldFont
end

-- Applies Text's face and outline to the font (a font or profile change).
function W.UpdateFonts()
	if not fieldFont then return end
	local path, _, flags = st:FontValues('normal')
	fieldFont:SetFont(path, FIELD_FONT_SIZE, flags)
	fieldFont:SetTextColor(Colors().text.normal:GetRGB())
end

-- Gives fs the field font, or path at size with flags (each defaulting to the
-- field font's). object, optional, stands in for the field font: the font
-- object fs keeps and the face, size and flags the defaults come from (a
-- list's caption, drawn in the group font). Always set outright: in game
-- SetFontObject doesn't undo an earlier SetFont, so a pooled font string would
-- keep a font list's face or a large description's size. A profile change
-- re-renders, which sets it again.
local function SetFieldFont(fs, path, size, flags, object)
	local font = object or W.GetFont()
	local fieldPath, fieldSize, fieldFlags = font:GetFont()
	fs:SetFontObject(font)
	fs:SetFont(path or fieldPath, size or fieldSize, flags or fieldFlags)
end

local function NewText(parent, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(W.GetFont())
	fs:SetJustifyH(justify or 'LEFT')
	return fs
end

-- A box: the field fill and a 1px edge border, with the dark line outside it.
local function Box(frame, fill)
	frame:SetBackdrop({
		bgFile = st.BLANK_TEX, edgeFile = st.BLANK_TEX, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(unpack(fill or FIELD))
	frame:SetBackdropBorderColor(unpack(EDGE))
	if not frame.outline then
		local outline = st:CreateFrame('Frame', nil, frame)
		outline:SetPoint('TOPLEFT', frame, 'TOPLEFT', -1, 1)
		outline:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 1, -1)
		outline:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
		outline:SetBackdrop({ edgeFile = st.BLANK_TEX, edgeSize = 1 })
		outline:SetBackdropBorderColor(unpack(ALT))
		frame.outline = outline
	end
	return frame
end

-- The border color (the hover and focus look is blue).
local function Edge(frame, blue)
	if blue then
		frame:SetBackdropBorderColor(Colors().button.blue:GetRGB())
	else
		frame:SetBackdropBorderColor(unpack(EDGE))
	end
end

-- A box that is blue-bordered under the mouse.
local function HoverEdge(frame, isDisabled)
	frame:SetScript('OnEnter', function(self) if not isDisabled() then Edge(self, true) end end)
	frame:SetScript('OnLeave', function(self) Edge(self, false) end)
end

-- For the options window's own boxes and buttons (the search box, Reload UI).
W.Box, W.Edge, W.HoverEdge = Box, Edge, HoverEdge

------------------------------------------------------------------ Blizzard's art

--[[
	Under SaftUI's theme Blizzard each control wears Blizzard's Settings art in
	place of Box (st.ThemeArt.Control), read when the control is drawn or bound,
	so a theme change reaches it when the window renders again:
	  - a select and the position block's dropdown: the Settings dropdown
	    (WowStyle2), its face following the button (under the mouse,
	    pressed, its list open, disabled), its glow spilling 7 outside the
	    button (4 on the position block's, a compact one); the list on the
	    Settings menu's own border and background (c-bg), in place of Box. A
	    select has Blizzard's steppers either side of its face where its
	    choices fit (optionsselect.lua); the compact ones have none;
	  - a range: Blizzard's minimal slider. Its value box, an input, the
	    position block's boxes and W.Prompt's box: InputBoxTemplate's art;
	  - a color: the dropdown's face, with Blizzard's swatch inside it
	    (optionstypes.lua). A keybinding: Blizzard's binding button,
	    its select piece while it waits for a key;
	  - the position block's nudges: MinimalScrollBar's steppers;
	  - the execute button, W.Confirm's buttons and the window's own: Blizzard's
	    panel button (st:ShowPanelButton). The toggle, the multiselect's
	    rows and the check list's (W.OpenCheckList, the list's frames, so
	    drawn as the list is): the Settings check box.
	The multiselect's box and the position block's dots have no Blizzard
	equivalent: a 1px line in the Blizzard theme's Border around its
	Background, as the theme draws a small frame. Under Thick and Thin every
	control keeps Box, exactly as before. Every piece is a texture of SaftUI's
	on a frame of SaftUI's, drawn inside the control's own rect (but the
	dropdown's glow and its steppers', which reach no further, and the list's
	c-bg round the list), so no cell or widget moves or changes size. Each
	look is put on only when it changed.
	A custom type (W.Define) draws its own frames and keeps the look it gives
	them (the bags' Categories list and the rule editor's boxes keep Box under
	Blizzard too); only what it borrows from W follows the theme: the list
	and the check list, W.Confirm and W.Prompt, the built-in rows of a body of
	its own, and the dropdown's look (W.LookDropdown and W.DropdownStates,
	which the rule editor's fields take).
]]

-- Whether the controls wear Blizzard's art: under SaftUI's theme Blizzard.
local function BlizzardLook()
	return st:IsBlizzardLook('theme', 'theme')
end
W.BlizzardLook = BlizzardLook

-- frame -> its Blizzard art: { blizzard, pieces = { [key] = texture }, and
-- what its states need }, made the first time it's asked for. blizzard is
-- whether frame wears it now.
local arts = setmetatable({}, { __mode = 'k' })

local function Art(frame)
	local art = arts[frame]
	if not art then
		art = { pieces = {} }
		arts[frame] = art
	end
	return art
end

-- Records the look frame's art is for; false when it wears it already.
local function Changes(art, blizzard)
	if (art.blizzard or false) == blizzard then return false end
	art.blizzard = blizzard
	return true
end

-- art's piece key: a texture of parent's in layer (at sublevel), made the
-- first time, shown.
local function Piece(art, parent, key, layer, sublevel)
	local piece = art.pieces[key]
	if not piece then
		piece = parent:CreateTexture(nil, layer, nil, sublevel)
		art.pieces[key] = piece
	end
	piece:Show()
	return piece
end

local function HidePieces(art)
	for _, piece in pairs(art.pieces) do piece:Hide() end
end

-- An atlas's width and height, as the client has them; nil for none.
local function AtlasSize(atlas)
	local info = C_Texture.GetAtlasInfo(atlas)
	if info then return info.width, info.height end
end

-- Lays set's left end, middle and right end (atlases) across frame, art's
-- textures in layer, each height tall: the ends as wide as their atlas is at
-- that height, on whole pixels, and the middle between them. along is where
-- they lie: 'BOTTOM' along frame's bottom, '' across its middle, or nil from
-- its top to its bottom (height then the frame's own, which SaftUI set).
local function LayThree(art, frame, set, layer, height, along)
	local left = Piece(art, frame, 'Left', layer)
	local middle = Piece(art, frame, 'Middle', layer)
	local right = Piece(art, frame, 'Right', layer)
	middle:SetAtlas(set.middle)
	for side, piece in pairs({ LEFT = left, RIGHT = right }) do
		local atlas = side == 'LEFT' and set.left or set.right
		piece:SetAtlas(atlas)
		piece:ClearAllPoints()
		if along then
			piece:SetPoint(along .. side, frame, along .. side)
			piece:SetHeight(height)
		else
			piece:SetPoint('TOP' .. side, frame, 'TOP' .. side)
			piece:SetPoint('BOTTOM' .. side, frame, 'BOTTOM' .. side)
		end
		local width, atlasHeight = AtlasSize(atlas)
		piece:SetWidth(width and floor(width * height / atlasHeight + 0.5) or height)
	end
	middle:ClearAllPoints()
	middle:SetPoint('TOPLEFT', left, 'TOPRIGHT')
	middle:SetPoint('BOTTOMRIGHT', right, 'BOTTOMLEFT')
	local info = C_Texture.GetAtlasInfo(set.middle)
	middle:SetHorizTile(info and info.tilesHorizontally or false)
end

-- For the options window's tabs (optionsnav.lua).
W.AtlasSize = AtlasSize
function W.LayThree(frame, set, layer, height, along)
	LayThree(Art(frame), frame, set, layer, height, along)
end
function W.HideArt(frame)
	if arts[frame] then HidePieces(arts[frame]) end
end

-- Takes a box's own look off for Blizzard's art (shown false), or puts it
-- back: Box with fill (the field's by default) and the dark line outside.
local function ShowBox(frame, shown, fill)
	if shown then
		Box(frame, fill)
		frame.outline:Show()
	else
		frame:SetBackdrop(nil)
		frame.outline:Hide()
	end
end

-- texture inset in from frame's edges on every side, on whole pixels.
local function Inset(texture, frame, inset)
	texture:ClearAllPoints()
	texture:SetPoint('TOPLEFT', frame, 'TOPLEFT', inset, -inset)
	texture:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -inset, inset)
end

-- An edit box's look, when it changed: Box, or InputBoxTemplate's art
-- (st.ThemeArt.Control('input')) across it, its ends at their share of
-- height (the box's height, which SaftUI set).
local function LookInput(edit, blizzard, height)
	local art = Art(edit)
	if not Changes(art, blizzard) then return end
	ShowBox(edit, not blizzard)
	if blizzard then
		LayThree(art, edit, st.ThemeArt.Control('input'), 'BACKGROUND', height)
	else
		HidePieces(art)
	end
end

-- The search box's look (optionswindow.lua), when it changed: Box, or
-- SearchBoxTemplate's art (st.ThemeArt.Control('search')) across it, its ends
-- at their share of height, and the magnifying glass at its left. Returns
-- where its text starts under Blizzard, clear of the glass; nil under Thick
-- and Thin.
local SEARCH_GLASS, SEARCH_GLASS_LEFT, SEARCH_GLASS_GAP = 10, 6, 4
local SEARCH_GLASS_Y = -1 -- SearchBoxTemplate's glass sits 1 below the box's middle
function W.LookSearch(box, blizzard, height)
	local art = Art(box)
	if Changes(art, blizzard) then
		ShowBox(box, not blizzard)
		if blizzard then
			local look = st.ThemeArt.Control('search')
			LayThree(art, box, look, 'BACKGROUND', height)
			local glass = Piece(art, box, 'Glass', 'ARTWORK')
			glass:SetAtlas(look.icon)
			glass:ClearAllPoints()
			glass:SetPoint('LEFT', box, 'LEFT', SEARCH_GLASS_LEFT, SEARCH_GLASS_Y)
			glass:SetSize(SEARCH_GLASS, SEARCH_GLASS)
		else
			HidePieces(art)
		end
	end
	if blizzard then return SEARCH_GLASS_LEFT + SEARCH_GLASS + SEARCH_GLASS_GAP end
end

-- A button's look, when it changed: Box with fill, or Blizzard's panel button
-- (st:ShowPanelButton). W.Confirm's buttons, and the window's own.
local function LookButton(button, blizzard, fill)
	if not Changes(Art(button), blizzard) then return end
	ShowBox(button, not blizzard, fill)
	st:ShowPanelButton(button, blizzard)
end
W.LookButton = LookButton

-- The look of a box with no Blizzard equivalent (the multiselect's, the
-- position block's dots): Box (a frame that has none keeps none), or a 1px
-- line in the Blizzard theme's Border around its Background, as the theme
-- draws a small frame, in its colors now.
local LINE = { bgFile = st.BLANK_TEX, edgeFile = st.BLANK_TEX, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } }
local function LookLine(frame, blizzard)
	if Changes(Art(frame), blizzard) and not blizzard then
		if frame.outline then ShowBox(frame, true) else frame:SetBackdrop(nil) end
	end
	if blizzard then
		local look = st:ResolveTheme('theme', 'solid', 'small')
		local r, g, b, a = unpack(look.colors.backdropcolor)
		frame:SetBackdrop(LINE)
		frame:SetBackdropColor(r, g, b, a * look.alpha)
		frame:SetBackdropBorderColor(unpack(look.colors.bordercolor))
		if frame.outline then frame.outline:Hide() end
	end
end

-- The confirm dialog's frame in its look: drawn as the options window is
-- (SaftUI's theme, the options Background, a panel: see-through with the
-- theme's Background unless Options windows says Solid) by a frame of SaftUI's
-- just under it, the skin, a child of holder (the frame's catcher) so it shows
-- with it, in every theme; the frame's own box is off. Returns the skin. The
-- select list has its own (LookList), and stays solid.
local function LookWindow(frame, holder)
	local art = Art(frame)
	if not art.skin then
		art.skin = st:CreateFrame('Frame', nil, holder)
		art.skin:SetAllPoints(frame)
	end
	art.skin:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
	st:SetTemplate(art.skin, 'theme', 'options', 'panel')
	return art.skin
end

-- region's anchors, { { point, relativeTo, relativePoint, x, y } } as
-- region:GetPoint gives them, and putting them back.
local function SavePoints(region)
	local points = {}
	for i = 1, region:GetNumPoints() do points[i] = { region:GetPoint(i) } end
	return points
end

local function RestorePoints(region, points)
	region:ClearAllPoints()
	for _, point in ipairs(points) do region:SetPoint(unpack(point)) end
end

-- The Settings dropdown's face (st.ThemeArt.Control('dropdown')) on a
-- button: the face spans the button from button.faceLeft to button.faceRight
-- in from its sides (0 for none; the steppers' room), its art outset round
-- that (the glow; compactOutset on a compact one). The hover arrow (none on
-- a compact one) hangs under the face's middle, its left edge on a whole
-- pixel, at its atlas's size.
local function PlaceFace(button, art)
	local look = art.look
	local left, right = button.faceLeft or 0, button.faceRight or 0
	local outset = art.compact and look.compactOutset or look.outset
	local face = art.pieces.Face
	face:ClearAllPoints()
	face:SetPoint('TOPLEFT', button, 'TOPLEFT', left - outset, outset)
	face:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -right + outset, -outset)
	local arrow = art.pieces.HoverArrow
	if arrow then
		arrow:SetAtlas(look.hoverArrow)
		local width, height = AtlasSize(look.hoverArrow)
		if width then
			arrow:SetSize(width, height)
			arrow:ClearAllPoints()
			arrow:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', left + floor((button:GetWidth() - left - right - width) / 2), 0)
		end
	end
end

-- The text across the face, textInset in from its sides, pressedOffset
-- further when pressed. A face with no button.text (the color field's,
-- whose code its own widget places beside its swatch) has none to place.
local function PlaceText(button, art, pressed)
	local look, text = art.look, button.text
	if not text then return end
	local x, y = 0, 0
	if pressed then x, y = look.pressedOffset[1], look.pressedOffset[2] end
	text:ClearAllPoints()
	text:SetPoint('LEFT', button, 'LEFT', (button.faceLeft or 0) + look.textInset + x, y)
	text:SetPoint('RIGHT', button, 'RIGHT', -((button.faceRight or 0) + look.textInset) + x, y)
end

-- A dropdown's face in its button's state, under Blizzard: disabled; held
-- down under the mouse (pressedhover); under the mouse; held down off it;
-- its list open; else normal. The hover arrow shows while the mouse is over
-- an enabled one, and the text sits pressed in while an enabled one is held
-- down. Nothing for a frame that isn't a dropdown under Blizzard (a list's
-- owner can be any frame).
local function PaintFace(button)
	local art = arts[button]
	if not (art and art.blizzard and art.pieces.Face) then return end
	local disabled = art.isDisabled ~= nil and art.isDisabled()
	local state = 'normal'
	if disabled then
		state = 'disabled'
	elseif art.down and art.over then
		state = 'pressedhover'
	elseif art.over then
		state = 'hover'
	elseif art.down then
		state = 'pressed'
	elseif W.ListOwner() == button then
		state = 'open'
	end
	art.pieces.Face:SetAtlas(art.look.face[state])
	if art.pieces.HoverArrow then art.pieces.HoverArrow:SetShown(art.over and not disabled) end
	PlaceText(button, art, art.down and not disabled)
end

-- Keeps a dropdown's face following the mouse: hooked once its button's own
-- scripts are set. isDisabled() says whether its widget is disabled.
local function DropdownStates(button, isDisabled)
	local art = Art(button)
	art.isDisabled = isDisabled
	local function Hook(script, field, value)
		button:HookScript(script, function(self)
			art[field] = value
			PaintFace(self)
		end)
	end
	Hook('OnEnter', 'over', true)
	Hook('OnLeave', 'over', false)
	Hook('OnMouseDown', 'down', true)
	Hook('OnMouseUp', 'down', false)
	-- A pooled widget hidden mid-press or under the mouse starts afresh.
	button:HookScript('OnHide', function(self)
		art.over, art.down = false, false
		PaintFace(self)
	end)
end
W.DropdownStates = DropdownStates

-- A dropdown's look (button.caret its caret's rows, button.text its text):
-- Box, the caret and the text where the button's own code put it; or the
-- Settings dropdown's face (PlaceFace), the text centred on it. compact for a
-- dropdown with no room for the full glow or the hover arrow (the position
-- block's, the rule editor's). The look is put on when it changed; under
-- Blizzard the face is placed and painted on every call, so a caller that
-- moves button.faceLeft or button.faceRight calls it again. compact is the
-- button's for life: the HoverArrow piece is made (or left out for a compact
-- one) only when the look changes, so a button passes the same compact on
-- every call, and a pooled one is never reused the other way.
local function LookDropdown(button, blizzard, compact)
	local art = Art(button)
	art.compact = compact and true or false
	if Changes(art, blizzard) then
		local text = button.text
		ShowBox(button, not blizzard)
		for _, row in ipairs(button.caret) do row:SetShown(not blizzard) end
		if blizzard then
			art.ownText = { justify = text:GetJustifyH(), points = SavePoints(text) }
			text:SetJustifyH('CENTER')
			Piece(art, button, 'Face', 'BACKGROUND')
			if not compact then Piece(art, button, 'HoverArrow', 'OVERLAY') end
		else
			HidePieces(art)
			text:SetJustifyH(art.ownText.justify)
			RestorePoints(text, art.ownText.points)
		end
	end
	if blizzard then
		art.look = st.ThemeArt.Control('dropdown')
		PlaceFace(button, art)
		PaintFace(button)
	end
end
W.LookDropdown = LookDropdown

------------------------------------------------------------------ a check box (toggle, multiselect)

-- A box of size with a blue square inside when checked: box.mark.
local function CheckBox(parent, size)
	local box = Box(st:CreateFrame('CheckButton', nil, parent))
	box:SetSize(size, size)
	box.mark = box:CreateTexture(nil, 'OVERLAY')
	box.mark:SetPoint('TOPLEFT', box, 'TOPLEFT', 3, -3)
	box.mark:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', -3, 3)
	box.mark:SetColorTexture(Colors().button.blue:GetRGB())
	box.mark:Hide()
	return box
end

-- The size the Settings check box's art is drawn at in a row rowHeight tall:
-- the largest whole size up to Blizzard's 30 x 29, in proportion, that fits
-- the row.
function W.CheckArtSize(rowHeight)
	local height = math.min(29, rowHeight)
	return math.min(30, math.floor(height * 30 / 29 + 0.5)), height
end

-- Lays a texture of a check box over the art's rect: box.artSize wide and
-- tall, by whole pixels, on the box's right (the toggle) or left (a row),
-- floor((height - 18) / 2) above its top.
local function PlaceCheckArt(box, texture)
	local width, height = unpack(box.artSize)
	local top = math.floor((height - 18) / 2)
	texture:ClearAllPoints()
	texture:SetSize(width, height)
	if box.artAlign == 'RIGHT' then
		texture:SetPoint('TOPRIGHT', box, 'TOPRIGHT', 0, top)
	else
		texture:SetPoint('TOPLEFT', box, 'TOPLEFT', 0, top)
	end
end

-- Puts a check box's look on, when it changed: the window's own (Box and the
-- blue mark), or under Blizzard the Settings panel's check box
-- (st.ThemeArt.Control('checkbox'), box.look): box.art, its box, check and
-- highlight, made the first time, each W.CheckArtSize(rowHeight) in size,
-- on the box's right (align 'RIGHT', the toggle) or left ('LEFT', a row),
-- spilling past the 18 square. The toggle's hit rect grows to take the art
-- (the game widens or narrows where a frame takes the mouse), a row's box
-- takes no mouse.
local function LookCheckBox(box, blizzard, rowHeight, align)
	if (box.blizzard or false) == blizzard then return end
	box.blizzard = blizzard
	if blizzard then
		local look = st.ThemeArt.Control('checkbox')
		box.look = look
		if not box.art then
			box.art = {
				normal = box:CreateTexture(nil, 'ARTWORK'),
				check = box:CreateTexture(nil, 'OVERLAY'),
				highlight = box:CreateTexture(nil, 'HIGHLIGHT'), -- shown by the game under the mouse
			}
		end
		local width, height = W.CheckArtSize(rowHeight)
		box.artSize, box.artAlign = { width, height }, align
		for _, texture in pairs(box.art) do PlaceCheckArt(box, texture) end
		if align == 'RIGHT' then
			local top = math.floor((height - 18) / 2)
			box:SetHitRectInsets(-(width - 18), 0, -top, -(height - 18 - top))
		end
		box.art.normal:SetAtlas(look.normal)
		box.art.highlight:SetAtlas(look.highlight)
		box.art.highlight:SetBlendMode(look.highlightBlend)
		box.art.normal:Show()
		box.art.highlight:Show()
		box:SetBackdrop(nil)
		box.outline:Hide()
	else
		box:SetHitRectInsets(0, 0, 0, 0)
		Box(box)
		box.outline:Show()
		for _, texture in pairs(box.art) do texture:Hide() end
	end
end

local function SetCheck(box, checked, disabled)
	checked = checked and true or false
	box:SetChecked(checked)
	box.mark:SetShown(checked and not box.blizzard)
	if box.art then
		box.art.check:SetShown(checked and box.blizzard or false)
		if box.blizzard then
			box.art.check:SetAtlas(disabled and box.look.disabledChecked or box.look.checked)
		end
	end
end

------------------------------------------------------------------ for the later widget files

Kit.EDGE, Kit.ALT, Kit.FIELD, Kit.BG, Kit.Colors = EDGE, ALT, FIELD, BG, Colors
Kit.FIELD_FONT_SIZE, Kit.SetFieldFont, Kit.NewText, Kit.arts = FIELD_FONT_SIZE, SetFieldFont, NewText, arts
Kit.Art, Kit.Changes, Kit.Piece, Kit.HidePieces, Kit.LayThree = Art, Changes, Piece, HidePieces, LayThree
Kit.ShowBox, Kit.Inset, Kit.LookInput, Kit.LookLine = ShowBox, Inset, LookInput, LookLine
Kit.LookWindow, Kit.PaintFace, Kit.CheckBox = LookWindow, PaintFace, CheckBox
Kit.PlaceCheckArt, Kit.LookCheckBox, Kit.SetCheck = PlaceCheckArt, LookCheckBox, SetCheck
