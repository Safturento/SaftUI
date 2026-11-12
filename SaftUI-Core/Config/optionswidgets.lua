local st = SaftUI
local OM = st.OptionsModel

--[[
	The widgets SaftUI's options window draws its rows with. Each is a control
	only: the window draws the label and the row around it.

	  local widget = W.Create(parent, row.type)       -- from a pool, one per type
	  widget:Bind(root, row, onChanged)               -- reads the value, shows it
	  widget:SetPoint(...)                            -- widget.frame is the frame
	  widget:GetWidth()                               -- the control's fixed width
	  widget:SetDisabled(true)
	  widget:Release()                                -- back to the pool

	Bind reads the row's value with OM.Get. A change the user makes goes the
	way AceConfigDialog's does: OM.Validate (a failure calls
	onChanged(false, message) and sets nothing), then OM.Confirm (a text asks
	with W.Confirm first), then OM.Set. After that onChanged(ok, err) runs, ok
	false when the set errored. The window re-renders from it. While a slider
	is being dragged, onChanged gets a third argument, true, and a fourth,
	the widget, so the window can refresh the other rows and leave the
	slider be; one more onChanged(true) comes when the mouse is let go, so
	the window doesn't rebuild the slider under the user's mouse.

	Types: toggle, range, select, multiselect, input, color, execute,
	keybinding, description, position. Widths: toggle 18, range 168 (a 116 track, a gap
	of 6 and a 46 value box), select, multiselect, input and keybinding 170,
	color 22. An execute button is as wide as its name needs (80 at least),
	and a description is as wide as the window sets it (400 until it does). A
	position block is as wide as its parts (200, 332 with a name target, 352
	with a select target) and 65 high; its get/set/validate take the part first (point,
	rel_point, x_off, y_off, frame, relative_to), so a change is
	Commit(part, value). The window sets widget.onTip, which the block calls
	as the mouse enters and leaves any of its parts. A multiselect's and a description's height follow what they hold
	(widget.frame:GetHeight()); the others are 18, 22, 24 or 26 high.

	Left out: input's multiline (one line), select's radio style (a dropdown,
	as the spec says). A description's fontSize is small (the default), medium
	or large. Its image is read as AceConfigDialog reads it: image a texture
	path or fileID, or a function giving that with a width and height;
	imageWidth and imageHeight otherwise (32 each by default); imageCoords 4
	or 8 numbers, or a function giving them, else the whole texture. The image
	sits at the description's left with the text to its right, and the height
	covers both. It has a border in SaftUI's theme, as an icon SaftUI skins
	does. Refresh reads them all again (the window refreshes the other
	rows while a slider is dragged, so a preview can follow it).

	Other files add types of their own with W.Define (custom types, at the
	end), each with its own pool. W.CUSTOM marks them, and the body draws a
	bare one's row with no label, across the line. W.OpenCheckList opens
	the select list's frames as a list of check boxes.
]]

local W = {}
st.OptionsWidgets = W

-- W.Kit: the names the widget files share with each other and nothing else.
-- They load in Config/load.xml's order, this file first. Each ends by setting
-- here what a later file takes from it, and starts by taking what it needs as
-- locals of its own. A name W exports (W.Box, W.LookDropdown, ...) is taken
-- from W instead.
local Kit = {}
W.Kit = Kit

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format, tinsert, tremove = string.format, table.insert, table.remove

W.WIDTH = {
	toggle = 18, range = 168, select = 170, multiselect = 170, input = 170,
	color = 22, execute = 80, keybinding = 170, description = 400,
	position = 0, -- the block's width follows its parts (widget:GetWidth())
}
local FIELD_HEIGHT = 24
local LIST_ROW_HEIGHT, LIST_MAX_ROWS = 22, 12
local LIST_WHEEL_ROWS = 3 -- a turn of the wheel over the list, or over its scroll bar
-- Above the options window (FULLSCREEN_DIALOG, like edit mode's outlines), so
-- the list and the confirm dialog show over it and catch the clicks around them.
local LIST_STRATA = 'TOOLTIP'

------------------------------------------------------------------ look

-- The mockup's colors (the thick template's, and the field fill).
local FIELD, EDGE, ALT, BG = st.BOX_COLORS.field, st.BOX_COLORS.edge, st.BOX_COLORS.alt, st.BOX_COLORS.bg

local function Colors()
	return st.config.profile.colors
end

-- The window's font for fields and lists: the profile's normal face, at 15.
local fieldFont
local FIELD_FONT_SIZE = 15
function W.GetFont()
	if not fieldFont then
		fieldFont = _G.SaftUI_OptionsFieldFont or CreateFont('SaftUI_OptionsFieldFont')
		W.UpdateFonts()
	end
	return fieldFont
end

-- Applies the profile's face and outline to the font (a profile change).
function W.UpdateFonts()
	if not fieldFont then return end
	local config = st.config.profile.fonts.normal
	fieldFont:SetFont(st.LSM:Fetch('font', config.font_name), FIELD_FONT_SIZE, st.OutlineFlag(config.font_outline))
	fieldFont:SetTextColor(Colors().text.normal:GetRGB())
end

-- Gives fs the field font, or path at size with flags (each defaulting to the
-- field font's). Always set outright: in game SetFontObject doesn't undo an
-- earlier SetFont, so a pooled font string would keep a font list's face or a
-- large description's size. A profile change re-renders, which sets it again.
local function SetFieldFont(fs, path, size, flags)
	local font = W.GetFont()
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
	  - a color: Blizzard's swatch. A keybinding: Blizzard's binding button,
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
	Blizzard too); only what it borrows from here follows the theme: the list
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

-- For the options window's tabs (optionswindow.lua).
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

-- The confirm dialog's frame in its look, when it changed: Box with fill, or
-- drawn as the options window is (SaftUI's theme, Solid, a panel) by a frame
-- of SaftUI's just under it, the skin, a child of holder (the frame's
-- catcher) so it shows with it. Returns the skin (nil until the first
-- Blizzard look). The select list has its own (LookList).
local function LookWindow(frame, holder, blizzard, fill)
	local art = Art(frame)
	if Changes(art, blizzard) then
		ShowBox(frame, not blizzard, fill)
		if blizzard and not art.skin then
			art.skin = st:CreateFrame('Frame', nil, holder)
			art.skin:SetAllPoints(frame)
		end
		if art.skin then art.skin:SetShown(blizzard) end
	end
	if blizzard then
		art.skin:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
		st:SetTemplate(art.skin, 'theme', 'solid', 'panel')
	end
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
-- further when pressed.
local function PlaceText(button, art, pressed)
	local look, text = art.look, button.text
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

------------------------------------------------------------------ the confirm dialog

-- Lines a text takes in a box avail wide: each line of the text (split on \n)
-- measured on its own, an empty one counting as a line. measure is a font
-- string that doesn't wrap and isn't shown (text decides a height, as a
-- wrapped font string only knows its own once it has been laid out).
local function CountLines(measure, text, avail)
	local lines, from = 0, 1
	avail = max(1, avail)
	while from do
		local newline = text:find('\n', from, true)
		measure:SetText(text:sub(from, (newline or #text + 1) - 1))
		lines = lines + max(1, ceil(measure:GetStringWidth() / avail))
		from = newline and newline + 1
	end
	return lines
end

local dialog

local function CloseConfirmFrames()
	if dialog then
		dialog.box:ClearFocus()
		dialog.box:Hide()
		dialog.prompt = nil
		dialog.catcher:Hide()
	end
end

-- Esc and clicks outside are No. Not for a frame that already closed. A
-- prompt's Yes hands its box's text on.
local function Answer(yes)
	if not (dialog and dialog.catcher:IsShown()) then return end
	local onYes, onNo = dialog.onYes, dialog.onNo
	local typed = dialog.prompt and dialog.box:GetText() or nil
	dialog.onYes, dialog.onNo = nil, nil
	CloseConfirmFrames()
	if yes then
		if onYes then onYes(typed) end
	elseif onNo then
		onNo()
	end
end

local function MakeDialogButton(parent, text, yes)
	local button = Box(st:CreateFrame('Button', nil, parent))
	button:SetSize(80, 24)
	button.text = NewText(button, 'CENTER')
	button.text:SetAllPoints()
	button.text:SetText(text)
	HoverEdge(button, function() return false end)
	button:SetScript('OnClick', function() Answer(yes) end)
	return button
end

local function BuildDialog()
	-- A full-screen catcher keeps clicks from reaching the window under the dialog.
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata(LIST_STRATA)
	catcher:SetFrameLevel(100)
	catcher:EnableMouse(true)
	catcher:Hide()

	local frame = Box(st:CreateFrame('Frame', nil, catcher), BG)
	frame:SetFrameLevel(110)
	frame:SetWidth(320)
	frame:EnableMouse(true)
	-- The thick template's second border.
	frame.outline:SetBackdropBorderColor(unpack(ALT))

	local text = NewText(frame, 'CENTER')
	text:SetWordWrap(true)
	text:SetWidth(290)
	text:SetPoint('TOP', frame, 'TOP', 0, -16)

	-- A prompt's edit box, below the text (OpenDialog places it).
	local box = Box(st:CreateFrame('EditBox', nil, frame))
	box:SetSize(290, FIELD_HEIGHT)
	box:SetFontObject(W.GetFont())
	box:SetJustifyH('LEFT')
	box:SetTextInsets(8, 8, 0, 0)
	box:SetAutoFocus(false)
	box:SetFrameLevel(frame:GetFrameLevel() + 1)
	box:Hide()
	box:SetScript('OnEnterPressed', function() Answer(true) end)
	box:SetScript('OnEscapePressed', function() Answer(false) end)
	box:SetScript('OnEditFocusGained', function(self) Edge(self, true) end)
	box:SetScript('OnEditFocusLost', function(self) Edge(self, false) end)

	-- Text measured on one line decides the height (CountLines).
	local measure = NewText(frame, 'LEFT')
	measure:SetWordWrap(false)
	measure:Hide()

	local yes = MakeDialogButton(frame, 'Yes', true)
	yes:SetPoint('BOTTOMRIGHT', frame, 'BOTTOM', -6, 14)
	local no = MakeDialogButton(frame, 'No', false)
	no:SetPoint('BOTTOMLEFT', frame, 'BOTTOM', 6, 14)

	catcher:SetScript('OnMouseDown', function() Answer(false) end)
	catcher:SetScript('OnKeyDown', function(self, key)
		local consumed = key == 'ESCAPE' or key == 'ENTER'
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(not consumed) end
		if key == 'ESCAPE' then Answer(false) elseif key == 'ENTER' then Answer(true) end
	end)
	catcher:SetScript('OnShow', function(self) self:EnableKeyboard(true) end)
	catcher:SetScript('OnHide', function(self) self:EnableKeyboard(false) end)

	dialog = { catcher = catcher, frame = frame, text = text, measure = measure, yes = yes, no = no, box = box }
end

-- The frame the confirm dialog centers on (the options window sets it).
function W.SetDialogAnchor(frame)
	W.dialogAnchor = frame
end

-- The dialog in SaftUI's theme now: Box, or under Blizzard drawn as the
-- options window is, with Blizzard's panel buttons and a text box.
local function LookDialog()
	local blizzard = BlizzardLook()
	dialog.skin = LookWindow(dialog.frame, dialog.catcher, blizzard, BG)
	LookButton(dialog.yes, blizzard)
	LookButton(dialog.no, blizzard)
	LookInput(dialog.box, blizzard, FIELD_HEIGHT)
end

-- One modal at a time, for Confirm and Prompt: the dialog is built once, and
-- opening either answers an open one No first. Sets the text, the buttons and
-- the height, and shows the dialog (a prompt's box is placed and shown here).
local function OpenDialog(text, onYes, onNo, prompt, yesLabel, noLabel)
	if not dialog then BuildDialog() end
	if dialog.catcher:IsShown() then Answer(false) end
	LookDialog()
	dialog.onYes, dialog.onNo = onYes, onNo
	dialog.prompt = prompt and true or nil
	text = tostring(text)
	dialog.text:SetText(text)
	local lines = CountLines(dialog.measure, text, 270)
	local lineHeight = floor(FIELD_FONT_SIZE * 1.3)
	dialog.text:SetHeight(lines * lineHeight)
	local height = 16 + lines * lineHeight + 16 + 24 + 14
	if prompt then
		height = height + FIELD_HEIGHT + 10
		dialog.box:ClearAllPoints()
		dialog.box:SetPoint('TOP', dialog.frame, 'TOP', 0, -(16 + lines * lineHeight + 10))
		dialog.box:Show()
	else
		dialog.box:Hide()
	end
	dialog.frame:SetHeight(height)
	dialog.yes.text:SetText(yesLabel)
	dialog.yes:ClearAllPoints()
	if noLabel then
		dialog.yes:SetPoint('BOTTOMRIGHT', dialog.frame, 'BOTTOM', -6, 14)
		dialog.no.text:SetText(noLabel)
		dialog.no:Show()
	else
		dialog.yes:SetPoint('BOTTOM', dialog.frame, 'BOTTOM', 0, 14)
		dialog.no:Hide()
	end
	dialog.frame:ClearAllPoints()
	dialog.frame:SetPoint('CENTER', W.dialogAnchor or UIParent, 'CENTER', 0, 0)
	dialog.catcher:Show()
end

-- Asks text with Yes and No buttons, centered over the window. onYes runs on
-- Yes; onNo (optional) on No, Esc or a click outside. Enter is Yes. A dialog
-- that is already up is answered No first.
function W.Confirm(text, onYes, onNo)
	OpenDialog(text, onYes, onNo, false, 'Yes', 'No')
end

-- Asks text with a one-line edit box under it, filled with initial (or empty),
-- focused and all selected. Enter or the accept button calls onAccept(text)
-- and closes; Esc, the cancel button and a click outside call opts.onCancel
-- (optional). opts.accept and opts.cancel label the buttons (Yes and No);
-- opts.cancel == false leaves only the accept button; opts.maxLetters caps
-- the box (0, the default, is no cap). The same dialog as Confirm.
function W.Prompt(text, initial, onAccept, opts)
	opts = opts or {}
	local cancel = opts.cancel
	if cancel == nil then cancel = 'No' end
	OpenDialog(text, onAccept, opts.onCancel, true, opts.accept or 'Yes', cancel or nil)
	dialog.box:SetMaxLetters(opts.maxLetters or 0)
	dialog.box:SetText(initial or '')
	dialog.box:SetFocus()
	dialog.box:HighlightText()
end

-- Answers an open confirm dialog No (the options window closing).
function W.CancelConfirm()
	Answer(false)
end

-- The open confirm or prompt dialog's text, or nil.
function W.ConfirmText()
	if dialog and dialog.catcher:IsShown() then return dialog.text:GetText() end
end

-- The open prompt's edit box, or nil (a confirm has none).
function W.PromptBox()
	if dialog and dialog.catcher:IsShown() and dialog.prompt then return dialog.box end
end

------------------------------------------------------------------ Blizzard's scroll bar

--[[
	Blizzard's minimal scroll bar (MinimalScrollBar's art, st.ThemeArt.
	Control('scrollbar')), on frames of SaftUI's own: a column of the up
	arrow, the track with its thumb, and the down arrow. It shows a scroll the
	caller keeps: what the user does asks onScroll(offset) for an offset,
	unclamped, and the caller clamps it and places the bar again (Set).
	  a thumb drag     the offset the drag started at, plus the cursor's
	                   travel times the range over the room the thumb has (the
	                   track less the thumb), read on the column's OnUpdate
	                   while the thumb is held
	  an arrow click   opts.step up or down
	  a track click    a view up or down, above or below the thumb
	  a turn of the    opts.wheel (opts.step when nil) up or down, anywhere
	  mouse wheel      on the column, which takes the mouse and the wheel
	                   all down its length (so a click between a narrow
	                   arrow and the track never reaches what lies under it)

	  local bar = W.BlizzardBar(parent, onScroll, opts)   opts { narrow, step, wheel }
	  bar:Set(anchor, x, y, length, view, total, offset)
	        the track's left x right of anchor's left, the column's top (the
	        up arrow's) y below anchor's top, length tall with the arrows.
	        Shown only while total > view: the thumb max(minThumb,
	        floor(track * view / total)) tall, as far down the track as offset
	        is through total - view. view, total, offset and the step are in
	        the caller's units: pixels, or a list's rows.
	  bar:Hide()
	  bar.width        the track's width
	  bar.frame, bar.track, bar.thumb, bar.up, bar.down   for tests
	  W.ScrollBarHeld() whether a bar's thumb is held now, its button down:
	                   the options window waits to render until it's let go

	A wide bar's arrows are 17x11, from 4 left of the 8 wide track, which
	starts 19 in from the column's ends; a narrow one's (the sidebar's, a
	dialog's, a list's) 8x5 over the track, 9 in. The thumb and the arrows
	show MinimalScrollBar's art under the mouse and while pressed.
]]
local BlizzardBar = {}
BlizzardBar.__index = BlizzardBar

-- The column's level over its parent's: over what it scrolls, which the
-- select list's bar lies across.
local BAR_LEVEL = 2

-- The bar whose thumb is held, or nil.
local heldBar

-- set's top and bottom (atlases, at their own size) and its middle between
-- them, textures of frame's: { top, middle, bottom }. The middle is tiled
-- down where its atlas tiles.
local function BarColumn(frame, set)
	local pieces = {}
	for _, key in ipairs({ 'top', 'middle', 'bottom' }) do
		local texture = frame:CreateTexture(nil, 'ARTWORK')
		texture:SetAtlas(set[key])
		pieces[key] = texture
	end
	for _, key in ipairs({ 'top', 'bottom' }) do
		local width, height = AtlasSize(set[key])
		pieces[key]:SetSize(width or frame:GetWidth(), height or frame:GetWidth())
	end
	pieces.top:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
	pieces.bottom:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
	pieces.middle:SetPoint('TOPLEFT', pieces.top, 'BOTTOMLEFT', 0, 0)
	pieces.middle:SetPoint('BOTTOMRIGHT', pieces.bottom, 'TOPRIGHT', 0, 0)
	local info = C_Texture.GetAtlasInfo(set.middle)
	pieces.middle:SetVertTile(info and info.tilesVertically or false)
	return pieces
end

-- The thumb's art in its state: held, under the mouse, else normal.
local function PaintThumb(bar)
	local set = bar.look.thumb[bar.held and 'down' or bar.thumbOver and 'over' or 'normal']
	for key, texture in pairs(bar.thumbPieces) do texture:SetAtlas(set[key]) end
end

-- An arrow of the column: art's normal, hover and pressed atlases (the
-- nudges', st.ThemeArt.Control('scrollbar').up or .down), filling it.
local function BarArrow(bar, art)
	local button = CreateFrame('Button', nil, bar.frame)
	button:SetSize(bar.arrowWidth, bar.arrowHeight)
	button:EnableMouse(true)
	local texture = button:CreateTexture(nil, 'BACKGROUND')
	texture:SetAllPoints(button)
	local over, down = false, false
	local function Paint() texture:SetAtlas(art[down and 'pressed' or over and 'hover' or 'normal']) end
	button:SetScript('OnEnter', function() over = true; Paint() end)
	button:SetScript('OnLeave', function() over = false; Paint() end)
	button:SetScript('OnMouseDown', function() down = true; Paint() end)
	button:SetScript('OnMouseUp', function() down = false; Paint() end)
	button:SetScript('OnHide', function() over, down = false, false; Paint() end)
	Paint()
	return button
end

function W.BlizzardBar(parent, onScroll, opts)
	opts = opts or {}
	local look = st.ThemeArt.Control('scrollbar')
	local arrow = opts.narrow and look.narrowArrow or look.arrow
	local bar = setmetatable({
		parent = parent, onScroll = onScroll, step = opts.step or 1, wheel = opts.wheel or opts.step or 1,
		look = look, width = look.width,
		arrowWidth = arrow[1], arrowHeight = arrow[2],
		arrowLeft = floor((arrow[1] - look.width) / 2), -- how far left of the track the arrows start
		inset = opts.narrow and look.narrowInset or look.inset,
		view = 0, total = 0, offset = 0, trackLength = 0, thumbLength = 0,
		held = false, thumbOver = false,
	}, BlizzardBar)

	local frame = CreateFrame('Frame', nil, parent)
	frame:SetWidth(arrow[1])
	frame:EnableMouse(true)
	frame:EnableMouseWheel(true)
	frame:SetScript('OnMouseWheel', function(_, delta) bar:Scroll(bar.offset - delta * bar.wheel) end)
	frame:Hide()
	bar.frame = frame
	bar.onUpdate = function() bar:Drag() end

	-- The track: a click on it, beside the thumb, moves a view toward the click.
	local track = CreateFrame('Frame', nil, frame)
	track:SetWidth(look.width)
	track:EnableMouse(true)
	BarColumn(track, look.track)
	track:SetScript('OnMouseDown', function(_, button)
		if button ~= 'LeftButton' then return end
		local _, y = GetCursorPosition()
		y = y / track:GetEffectiveScale()
		if y > bar.thumb:GetTop() then
			bar:Scroll(bar.offset - bar.view)
		elseif y < bar.thumb:GetBottom() then
			bar:Scroll(bar.offset + bar.view)
		end
	end)
	bar.track = track

	-- The thumb, dragged with the left button. It takes the mouse 4 past its
	-- edges, as MinimalScrollBar's does, so the narrow thumb is easy to catch.
	local thumb = CreateFrame('Button', nil, track)
	thumb:SetWidth(look.width)
	thumb:EnableMouse(true)
	thumb:SetHitRectInsets(-4, -4, -4, -4)
	bar.thumbPieces = BarColumn(thumb, look.thumb.normal)
	thumb:SetScript('OnEnter', function()
		bar.thumbOver = true
		PaintThumb(bar)
	end)
	thumb:SetScript('OnLeave', function()
		bar.thumbOver = false
		PaintThumb(bar)
	end)
	thumb:SetScript('OnMouseDown', function(_, button)
		if button == 'LeftButton' then bar:StartDrag() end
	end)
	thumb:SetScript('OnMouseUp', function(_, button)
		if button == 'LeftButton' then bar:StopDrag() end
	end)
	thumb:SetScript('OnHide', function()
		bar.thumbOver = false
		bar:StopDrag()
	end)
	bar.thumb = thumb

	bar.up = BarArrow(bar, look.up)
	bar.up:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
	bar.up:SetScript('OnClick', function() bar:Scroll(bar.offset - bar.step) end)
	bar.down = BarArrow(bar, look.down)
	bar.down:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
	bar.down:SetScript('OnClick', function() bar:Scroll(bar.offset + bar.step) end)
	return bar
end

-- Asks the caller for offset.
function BlizzardBar:Scroll(offset)
	if self.onScroll then self.onScroll(offset) end
end

-- The thumb held: the drag reads the cursor on the column's OnUpdate.
-- asked is the offset last asked for (none yet: the one it started at).
function BlizzardBar:StartDrag()
	if heldBar and heldBar ~= self then heldBar:StopDrag() end
	local _, y = GetCursorPosition()
	self.held, self.dragFrom, self.dragY = true, self.offset, y / self.frame:GetEffectiveScale()
	self.asked = self.offset
	heldBar = self
	self.frame:SetScript('OnUpdate', self.onUpdate)
	PaintThumb(self)
end

function BlizzardBar:StopDrag()
	if self.held then
		self.held = false
		self.frame:SetScript('OnUpdate', nil)
	end
	if heldBar == self then heldBar = nil end
	PaintThumb(self)
end

-- The offset the cursor's travel since the press asks for, asked only when
-- it changed: a still cursor asks nothing (a font list draws its rows on
-- each ask). A drag whose mouse up never came (the button let go over
-- another frame that was then hidden) ends when the button is found up.
function BlizzardBar:Drag()
	if not IsMouseButtonDown('LeftButton') then return self:StopDrag() end
	local room = self.trackLength - self.thumbLength
	if room <= 0 then return end
	local _, y = GetCursorPosition()
	y = y / self.frame:GetEffectiveScale()
	local offset = self.dragFrom + (self.dragY - y) * (self.total - self.view) / room
	if offset == self.asked then return end
	self.asked = offset
	self:Scroll(offset)
end

-- Whether a bar's thumb is held: one whose button is found up (its mouse
-- up never came) is let go, so a lost mouse up never holds the window's
-- renders off.
function W.ScrollBarHeld()
	if heldBar and not IsMouseButtonDown('LeftButton') then heldBar:StopDrag() end
	return heldBar ~= nil
end

function BlizzardBar:Set(anchor, x, y, length, view, total, offset)
	self.view, self.total = view or 0, total or 0
	local range = self.total - self.view
	local trackLength = (length or 0) - 2 * self.inset
	if range <= 0 or self.view <= 0 or trackLength < 1 then return self:Hide() end
	self.offset = max(0, min(range, offset or 0))
	local frame = self.frame
	local level = self.parent:GetFrameLevel() + BAR_LEVEL
	if frame:GetFrameLevel() ~= level then
		frame:SetFrameLevel(level)
		self.track:SetFrameLevel(level + 1)
		self.thumb:SetFrameLevel(level + 2)
		self.up:SetFrameLevel(level + 1)
		self.down:SetFrameLevel(level + 1)
	end
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchor, 'TOPLEFT', x - self.arrowLeft, -y)
	frame:SetHeight(length)
	self.track:ClearAllPoints()
	self.track:SetPoint('TOPLEFT', frame, 'TOPLEFT', self.arrowLeft, -self.inset)
	self.track:SetHeight(trackLength)
	local thumb = min(trackLength, max(self.look.minThumb, floor(trackLength * self.view / self.total)))
	self.trackLength, self.thumbLength = trackLength, thumb
	self.thumb:SetHeight(thumb)
	self.thumb:ClearAllPoints()
	self.thumb:SetPoint('TOPLEFT', self.track, 'TOPLEFT', 0, -floor((trackLength - thumb) * self.offset / range))
	frame:Show()
end

function BlizzardBar:Hide()
	self.frame:Hide()
end

------------------------------------------------------------------ the select list

-- One list shared by every select: a column of up to 12 rows over a scrollable
-- list of entries, closed by a choice, a click outside or Esc.
local list

-- Where the rows sit in from the list's edges (left, top, right, bottom)
-- under Thick and Thin: inside Box's edge. Under Blizzard the dropdown's
-- listInsets.
local LIST_INSETS = { 1, 1, 1, 1 }

-- The check list's (below): a row laid out for the list that's open, and a
-- click on a check list's row.
local LayCheckRow, ToggleCheck

local function ListFill()
	local entries, offset = list.entries, list.offset
	for i, row in ipairs(list.rows) do
		local entry = entries[offset + i]
		if entry then
			row.entry = entry
			if list.fontMode then
				SetFieldFont(row.text, entry.font, FIELD_FONT_SIZE, '')
			else
				SetFieldFont(row.text)
			end
			row.text:SetText(entry.label)
			if entry.key == list.selected then
				row.text:SetTextColor(Colors().text.blue:GetRGB())
			else
				row.text:SetTextColor(Colors().text.normal:GetRGB())
			end
			LayCheckRow(row, entry)
			row:Show()
		else
			row.entry = nil
			row:Hide()
		end
	end
	-- The scroll bar, shown when there's more than the rows show: under
	-- Blizzard Blizzard's narrow one, inside the list on its right beside
	-- the rows' top and bottom (in rows); else the 3px bar.
	local total, shown = #entries, min(#entries, LIST_MAX_ROWS)
	local blizzardBar = list.blizzardBar
	if list.blizzard then
		list.bar:Hide()
		blizzardBar:Set(list.frame, list.frame:GetWidth() - list.insets[3] - blizzardBar.width, list.insets[2],
			shown * LIST_ROW_HEIGHT, shown, total, offset)
	elseif total > shown then
		blizzardBar:Hide()
		local track = shown * LIST_ROW_HEIGHT
		list.bar:SetHeight(max(10, track * shown / total))
		list.bar:ClearAllPoints()
		list.bar:SetPoint('TOPRIGHT', list.frame, 'TOPRIGHT', -2, -list.insets[2] - (track - list.bar:GetHeight()) * offset / (total - shown))
		list.bar:Show()
	else
		blizzardBar:Hide()
		list.bar:Hide()
	end
end

-- The list scrolled to offset (in rows), within its entries: what its
-- Blizzard scroll bar's arrows, track and thumb ask for.
local function ScrollList(offset)
	if not list.entries then return end
	list.offset = max(0, min(#list.entries - LIST_MAX_ROWS, floor(offset + 0.5)))
	ListFill()
end

-- The list's owner's dropdown face is open while the list shows.
function W.CloseList()
	if list then
		local owner = list.owner
		list.owner, list.onPick, list.entries = nil, nil, nil
		list.isChecked, list.onToggle = nil, nil
		list.catcher:Hide()
		if owner then PaintFace(owner) end
	end
end

-- Row i of the list, list.insets in from the list's sides and top.
local function PlaceListRow(row, i)
	local insets = list.insets
	local y = -insets[2] - (i - 1) * LIST_ROW_HEIGHT
	row:ClearAllPoints()
	row:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', insets[1], y)
	row:SetPoint('TOPRIGHT', list.frame, 'TOPRIGHT', -insets[3], y)
end

-- The list in SaftUI's theme now, when it changed. Box, the rows inside its
-- edge (LIST_INSETS), a row under the mouse lit blue at 0.25. Or under
-- Blizzard the Settings menu's (st.ThemeArt.Control('dropdown')): no Box;
-- c-bg, the menu's own border and shadow, on list.skin, a plain frame of
-- SaftUI's just under the list (the theme draws nothing on it, so there's no
-- second border), at listOutsets round the list; the rows listInsets in; a
-- row under the mouse on rowHover. list.blizzard is the look, for a check
-- list's boxes (LayCheckRow); list.insets where the rows sit (OpenList,
-- ListFill).
local function LookList()
	local blizzard = BlizzardLook()
	list.blizzard = blizzard
	if not Changes(Art(list.frame), blizzard) then return end
	ShowBox(list.frame, not blizzard, BG)
	local look = blizzard and st.ThemeArt.Control('dropdown')
	if blizzard and not list.skin then
		list.skin = CreateFrame('Frame', nil, list.catcher)
		list.skin:SetAllPoints(list.frame)
		list.menu = list.skin:CreateTexture(nil, 'BACKGROUND')
	end
	if list.skin then list.skin:SetShown(blizzard) end
	if blizzard then
		local outsets = look.listOutsets
		list.skin:SetFrameLevel(max(0, list.frame:GetFrameLevel() - 1))
		list.menu:SetAtlas(look.list)
		list.menu:ClearAllPoints()
		list.menu:SetPoint('TOPLEFT', list.frame, 'TOPLEFT', outsets[1], outsets[2])
		list.menu:SetPoint('BOTTOMRIGHT', list.frame, 'BOTTOMRIGHT', outsets[3], outsets[4])
	end
	list.insets = blizzard and look.listInsets or LIST_INSETS
	for i, row in ipairs(list.rows) do
		PlaceListRow(row, i)
		if blizzard then
			row.hover:SetAtlas(look.rowHover)
			row.hover:SetAlpha(1)
		else
			row.hover:SetColorTexture(Colors().button.blue:GetRGB())
			row.hover:SetAlpha(0.25)
		end
	end
end

local function BuildList()
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata(LIST_STRATA)
	catcher:SetFrameLevel(50)
	catcher:EnableMouse(true)
	catcher:Hide()

	local frame = Box(st:CreateFrame('Frame', nil, catcher), BG)
	frame:SetFrameLevel(60)
	frame:EnableMouse(true)
	frame:EnableMouseWheel(true)

	local bar = frame:CreateTexture(nil, 'OVERLAY')
	bar:SetColorTexture(unpack(EDGE))
	bar:SetWidth(3)
	bar:Hide()

	list = { catcher = catcher, frame = frame, bar = bar, rows = {}, offset = 0, insets = LIST_INSETS }
	list.blizzardBar = W.BlizzardBar(frame, ScrollList, { narrow = true, step = 1, wheel = LIST_WHEEL_ROWS })

	for i = 1, LIST_MAX_ROWS do
		local row = CreateFrame('Button', nil, frame)
		row:SetHeight(LIST_ROW_HEIGHT)
		PlaceListRow(row, i)
		row:SetFrameLevel(frame:GetFrameLevel() + 1)
		row.hover = row:CreateTexture(nil, 'BACKGROUND')
		row.hover:SetAllPoints()
		row.hover:SetColorTexture(Colors().button.blue:GetRGB())
		row.hover:SetAlpha(0.25)
		row.hover:Hide()
		row.text = NewText(row, 'LEFT')
		row.text:SetPoint('LEFT', row, 'LEFT', 8, 0)
		row.text:SetPoint('RIGHT', row, 'RIGHT', -10, 0)
		row:SetScript('OnEnter', function(self) self.hover:Show() end)
		row:SetScript('OnLeave', function(self) self.hover:Hide() end)
		row:SetScript('OnClick', function(self)
			if list.onToggle then return ToggleCheck(self) end
			local entry, onPick = self.entry, list.onPick
			W.CloseList()
			if entry and onPick then onPick(entry.key) end
		end)
		list.rows[i] = row
	end

	frame:SetScript('OnMouseWheel', function(_, delta)
		local over = #list.entries - LIST_MAX_ROWS
		if over <= 0 then return end
		list.offset = max(0, min(over, list.offset - delta * LIST_WHEEL_ROWS))
		ListFill()
	end)
	catcher:SetScript('OnMouseDown', W.CloseList)
	catcher:SetScript('OnKeyDown', function(self, key)
		-- Esc closes the list; every other key goes on to the game.
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(key ~= 'ESCAPE') end
		if key == 'ESCAPE' then W.CloseList() end
	end)
	catcher:SetScript('OnShow', function(self) self:EnableKeyboard(true) end)
	catcher:SetScript('OnHide', function(self) self:EnableKeyboard(false) end)
end

-- Opens the list under owner (a frame; above it when there's no room below).
-- entries: { {key, label, font = path} }, the selected key shows blue, and
-- onPick(key) runs on a choice. fontMode draws each label in its own face
-- (entry.font). An empty list doesn't open.
function W.OpenList(owner, entries, selected, onPick, fontMode)
	if not list then BuildList() end
	W.CloseList()
	if #entries == 0 then return end
	list.owner, list.entries, list.selected, list.onPick, list.fontMode = owner, entries, selected, onPick, fontMode
	LookList()

	local rows = min(#entries, LIST_MAX_ROWS)
	local height = rows * LIST_ROW_HEIGHT + list.insets[2] + list.insets[4]
	list.frame:SetSize(max(owner:GetWidth(), W.WIDTH.select), height)
	list.frame:SetScale(owner:GetEffectiveScale() / UIParent:GetEffectiveScale())
	list.frame:ClearAllPoints()
	local bottom = owner:GetBottom()
	if bottom and bottom - height * list.frame:GetScale() < 0 then
		list.frame:SetPoint('BOTTOMLEFT', owner, 'TOPLEFT', 0, 2)
	else
		list.frame:SetPoint('TOPLEFT', owner, 'BOTTOMLEFT', 0, -2)
	end

	list.offset = 0
	for i, entry in ipairs(entries) do
		if entry.key == selected then
			list.offset = max(0, min(#entries - LIST_MAX_ROWS, i - 1))
			break
		end
	end
	ListFill()
	list.catcher:Show()
	PaintFace(owner)
end

-- The list's frames { catcher, frame, rows, skin, menu, insets, ... } (nil
-- until first opened; skin and menu, c-bg, from the first Blizzard look), and
-- the confirm dialog's { catcher, frame, text, yes, no, box, skin } (nil
-- until first asked; skin is what draws it as the window is under Blizzard).
-- For tests.
function W.GetListFrames() return list end
function W.GetDialogFrames() return dialog end

-- The frame the open list belongs to, or nil.
function W.ListOwner()
	return list and list.catcher:IsShown() and list.owner or nil
end

------------------------------------------------------------------ the base widget

local Base = {}
Base.__index = Base

local pools = {} -- rowType -> { widget }
local builders = {} -- rowType -> function(widget): makes widget.frame

function Base:GetWidth() return self.width end
function Base:GetHeight() return self.frame:GetHeight() end
function Base:SetPoint(...) self.frame:SetPoint(...) end

function Base:IsDisabled() return self.disabled end

function Base:SetDisabled(disabled)
	self.disabled = disabled and true or false
	self.frame:SetAlpha(self.disabled and 0.4 or 1)
	if self.OnDisabled then self:OnDisabled(self.disabled) end
end

-- Reads the row's value and shows it. Each type's Refresh does the showing.
function Base:Bind(root, row, onChanged)
	self.root, self.row, self.onChanged = root, row, onChanged
	self:SetDisabled(row.disabled)
	self:Refresh()
	return self
end

function Base:Value(...)
	return OM.Get(self.root, self.row, ...)
end

-- A change from the user: validate, then confirm, then set, then tell the
-- window. A failed validation puts the shown value back (an input keeps its text).
function Base:Commit(...)
	local root, row = self.root, self.row
	if not row or self.disabled then return end
	local args, n = { ... }, select('#', ...)
	local function Apply()
		if self.root ~= root or self.row ~= row then return end -- released meanwhile
		local ok = OM.Set(root, row, unpack(args, 1, n))
		self:Refresh()
		if self.onChanged then self.onChanged(ok ~= false, nil, self.dragging, self) end
	end
	local valid, err = OM.Validate(root, row, ...)
	if not valid then
		if self.type == 'input' then
			-- AceConfigDialog keeps what was typed beside the error. The box may
			-- have been reset when Enter dropped its focus, so put the text back.
			self.frame:SetText(tostring((...)))
		else
			self:Refresh()
		end
		if self.onChanged then self.onChanged(false, err) end
		return
	end
	local text = OM.Confirm(root, row, ...)
	if text then
		W.Confirm(text, Apply, function()
			if self.root == root and self.row == row then self:Refresh() end
		end)
	else
		Apply()
	end
end

function Base:Release()
	if self.released then return end
	self.released = true
	if self.OnRelease then self:OnRelease() end
	self.root, self.row, self.onChanged = nil, nil, nil
	self.dragging = nil
	self.frame:Hide()
	self.frame:ClearAllPoints()
	self.frame:SetParent(nil)
	self.frame:SetAlpha(1)
	self.disabled = false
	tinsert(self.pool, self)
end

-- The widget for rowType, from the pool when one was released.
function W.Create(parent, rowType)
	local build = builders[rowType]
	if not build then error(format('SaftUI options: no widget for type %q', tostring(rowType)), 2) end
	pools[rowType] = pools[rowType] or {}
	local widget = tremove(pools[rowType])
	if not widget then
		-- Its pool is the one it was built for: a custom type defined again
		-- starts a new one (W.Define).
		widget = setmetatable({ type = rowType, width = W.WIDTH[rowType], pool = pools[rowType] }, Base)
		build(widget)
	end
	widget.released = false
	widget.frame:SetParent(parent)
	widget.frame:SetFrameLevel(parent:GetFrameLevel() + 1)
	widget.frame:Show()
	return widget
end

-- How many widgets of a type sit in the pool.
function W.Pooled(rowType)
	return pools[rowType] and #pools[rowType] or 0
end

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

------------------------------------------------------------------ toggle

builders.toggle = function(w)
	local box = CheckBox(UIParent, 18)
	w.frame = box
	HoverEdge(box, function() return w.disabled end)
	box:SetScript('OnClick', function()
		if w.disabled then return end
		w:Commit(not w.value)
	end)
end

-- Each type's methods are copied onto its widgets as they're built. A
-- Refresh that comes after a release (a hidden edit box losing focus) does
-- nothing.
local function define(rowType, methods)
	local build = builders[rowType]
	builders[rowType] = function(w)
		for name, fn in pairs(methods) do w[name] = fn end
		if methods.Refresh then
			local refresh = methods.Refresh
			w.Refresh = function(self, ...)
				if self.row then return refresh(self, ...) end
			end
		end
		build(w)
	end
end

define('toggle', {
	Bind = function(self, ...)
		LookCheckBox(self.frame, BlizzardLook(), 34, 'RIGHT') -- 34: the body's row height (OB.ROW_HEIGHT, loaded after this file)
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		self.value = self:Value() and true or false
		SetCheck(self.frame, self.value, self.disabled)
	end,

	OnDisabled = function(self, disabled)
		SetCheck(self.frame, self.frame:GetChecked(), disabled)
	end,
})

------------------------------------------------------------------ input

builders.input = function(w)
	local edit = Box(st:CreateFrame('EditBox', nil, UIParent))
	edit:SetSize(W.WIDTH.input, FIELD_HEIGHT)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('LEFT')
	edit:SetTextInsets(8, 8, 0, 0)
	edit:SetAutoFocus(false)
	w.frame = edit
	HoverEdge(edit, function() return w.disabled or edit:HasFocus() end)
	edit:SetScript('OnEnterPressed', function(self)
		if not w.row then return end
		local text = self:GetText()
		self:ClearFocus()
		w:Commit(text)
	end)
	edit:SetScript('OnEscapePressed', function(self)
		w:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self) Edge(self, true) end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		w:Refresh()
	end)
end

define('input', {
	-- A small input is narrower (the window sets its width after binding);
	-- the art spans whatever width the box has.
	Bind = function(self, ...)
		LookInput(self.frame, BlizzardLook(), FIELD_HEIGHT)
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		local value = self:Value()
		self.value = value
		self.frame:SetText(value == nil and '' or tostring(value))
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		if disabled then self.frame:ClearFocus() end
	end,
})

------------------------------------------------------------------ color

-- ColorPickerFrame is Blizzard's: used only through its public API, and no
-- Lua field is written onto it. The forever branch's picker is the mainline
-- one, where opacity is the alpha (1 is solid). Two C methods move it above the
-- options window, as AceGUI's color picker does (AceGUIWidget-ColorPicker.lua):
-- SetFrameStrata('FULLSCREEN_DIALOG') and SetFrameLevel(swatch level + 10).
-- Its own strata is DIALOG, under the window (FULLSCREEN_DIALOG), where it
-- opens behind it and its GLOBAL_MOUSE_DOWN cancel takes the next click.
local function OpenPicker(info, swatch)
	-- Forever and retail both have SetupColorPickerAndShow. Without it the swatch
	-- does nothing: the older way means writing fields onto Blizzard's frame.
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetFrameStrata('FULLSCREEN_DIALOG')
		ColorPickerFrame:SetFrameLevel(swatch:GetFrameLevel() + 10)
		ColorPickerFrame:SetupColorPickerAndShow(info)
	end
end

-- The black line and the color inside the swatch's border, in from its edges.
local SWATCH_INNER, SWATCH_COLOR = 1, 2

builders.color = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.color, W.WIDTH.color)
	w.frame = button
	-- The black 1px line inside the border, then the color.
	w.inner = button:CreateTexture(nil, 'ARTWORK')
	w.inner:SetColorTexture(0, 0, 0, 1)
	Inset(w.inner, button, SWATCH_INNER)
	w.swatch = button:CreateTexture(nil, 'OVERLAY')
	Inset(w.swatch, button, SWATCH_COLOR)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnClick', function() w:Pick() end)
end

-- The swatch's look, when it changed: Box, the black line and the color, or
-- Blizzard's swatch (ColorSwatchTemplate, st.ThemeArt.Control('swatch')): a
-- white square, a black one inside it and the color inside that, at the
-- template's sizes, centred in the swatch's own square.
local function LookColor(w, blizzard)
	local button = w.frame
	local art = Art(button)
	if not Changes(art, blizzard) then return end
	ShowBox(button, not blizzard)
	if blizzard then
		local look = st.ThemeArt.Control('swatch')
		local function Centred(size) return floor((W.WIDTH.color - size) / 2) end
		local white = Piece(art, button, 'White', 'BACKGROUND')
		white:SetColorTexture(unpack(look.whiteColor))
		Inset(white, button, Centred(look.white))
		w.inner:SetColorTexture(unpack(look.blackColor))
		Inset(w.inner, button, Centred(look.black))
		Inset(w.swatch, button, Centred(look.color))
	else
		HidePieces(art)
		w.inner:SetColorTexture(0, 0, 0, 1)
		Inset(w.inner, button, SWATCH_INNER)
		Inset(w.swatch, button, SWATCH_COLOR)
	end
end

define('color', {
	Bind = function(self, ...)
		LookColor(self, BlizzardLook())
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		local r, g, b, a = self:Value()
		self.r, self.g, self.b, self.a = r or 0, g or 0, b or 0, a or 1
		self.hasAlpha = OM.Member(self.root, self.row, 'hasAlpha') and true or false
		self.swatch:SetColorTexture(self.r, self.g, self.b, self.hasAlpha and self.a or 1)
	end,

	-- Opens the picker on the current color. Each change it makes is set;
	-- Cancel puts the color it opened with back. The picker calls swatchFunc
	-- once as it opens, with the same color, which isn't a change.
	Pick = function(self)
		if self.disabled or not self.row then return end
		local root, row = self.root, self.row
		local r, g, b, a = self.r, self.g, self.b, self.a
		local hasAlpha = self.hasAlpha
		local function Current()
			local nr, ng, nb = ColorPickerFrame:GetColorRGB()
			local na = hasAlpha and ColorPickerFrame:GetColorAlpha() or 1
			return nr, ng, nb, na
		end
		local opening = true
		local function Changed(nr, ng, nb, na)
			-- The picker calls swatchFunc while it opens (with whatever alpha it
			-- held before), before it is the user's.
			if opening or self.root ~= root or self.row ~= row then return end
			if nr == self.r and ng == self.g and nb == self.b and (not hasAlpha or na == self.a) then return end
			self:Commit(nr, ng, nb, na)
		end
		OpenPicker({
			r = r, g = g, b = b,
			opacity = hasAlpha and a or nil,
			hasOpacity = hasAlpha,
			swatchFunc = function() Changed(Current()) end,
			opacityFunc = function() Changed(Current()) end,
			cancelFunc = function(previous)
				previous = previous or { r = r, g = g, b = b, a = a }
				Changed(previous.r, previous.g, previous.b, hasAlpha and previous.a or 1)
			end,
		}, self.frame)
		opening = false
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
	end,
})

------------------------------------------------------------------ execute

builders.execute = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent), BG)
	button:SetHeight(26)
	w.frame = button
	w.text = NewText(button, 'CENTER')
	w.text:SetPoint('CENTER', button, 'CENTER', 0, 0)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnMouseDown', function() w.text:SetPoint('CENTER', button, 'CENTER', 0, -1) end)
	button:SetScript('OnMouseUp', function() w.text:SetPoint('CENTER', button, 'CENTER', 0, 0) end)
	button:SetScript('OnClick', function() w:Run() end)
end

-- The execute button's look, when it changed: the window's own (Box), or
-- under Blizzard Blizzard's panel button (st:ShowPanelButton), -Disabled
-- while the widget is (the window dims it and stops its mouse; its button
-- stays enabled).
local function LookExecute(w, blizzard)
	if (w.blizzard or false) == blizzard then return end
	w.blizzard = blizzard
	local button = w.frame
	if blizzard then
		button:SetBackdrop(nil)
		button.outline:Hide()
	else
		Box(button, BG)
		button.outline:Show()
	end
	w.showsDisabled = w.showsDisabled or function() return w.disabled end
	st:ShowPanelButton(button, blizzard, nil, w.showsDisabled)
end

define('execute', {
	Bind = function(self, ...)
		LookExecute(self, BlizzardLook())
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		self.text:SetText(self.row.name or '')
		self.width = max(W.WIDTH.execute, ceil(self.text:GetStringWidth()) + 28)
		self.frame:SetWidth(self.width)
	end,

	-- Confirm, then call the option's func.
	Run = function(self)
		if self.disabled or not self.row then return end
		local root, row = self.root, self.row
		local function Go()
			if self.root ~= root or self.row ~= row then return end
			local ok = OM.Set(root, row)
			if self.onChanged then self.onChanged(ok ~= false) end
		end
		local text = OM.Confirm(root, row)
		if text then W.Confirm(text, Go) else Go() end
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		if self.blizzard then st:ShowPanelButton(self.frame, true, nil, self.showsDisabled) end
	end,
})

------------------------------------------------------------------ description

builders.description = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(W.WIDTH.description, 18)
	w.frame = frame
	w.image = frame:CreateTexture(nil, 'ARTWORK')
	w.image:Hide()
	-- The image's border, in SaftUI's theme like an action button's icon (Icon
	-- zoom's preview is one). It shows only with an image (ShowImage), and lies
	-- outside the image, which Fit places the border's width in from the row's
	-- corner: the row's edge is the scroll area's, which cuts what lies past it.
	st:SetBackdrop(w.image, 'theme', 'theme', 'action')
	w.image.backdrop:Hide()
	w.text = NewText(frame, 'LEFT')
	w.text:SetWordWrap(true)
	w.measure = NewText(frame, 'LEFT')
	w.measure:SetWordWrap(false)
	w.measure:Hide()
end

local DESCRIPTION_SIZES = { small = FIELD_FONT_SIZE, medium = FIELD_FONT_SIZE + 2, large = FIELD_FONT_SIZE + 5 }
local IMAGE_SIZE, IMAGE_GAP = 32, 8 -- AceGUI's label image is 32 square without a size

define('description', {
	GetWidth = function(self) return self.frame:GetWidth() end,

	-- The window sizes a description to its row. The height follows the text,
	-- and the image when there is one.
	SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self:Fit()
	end,

	-- The text takes what the image and its border leave of the width. Beside
	-- an image taller than it, it sits in the image's middle, as AceGUI's label
	-- puts it. The border's width is the theme's now: a theme picked on the
	-- Theme tab reaches the row when it is drawn again.
	Fit = function(self)
		local imageWidth, imageHeight = 0, 0
		if self.image:IsShown() then
			local border = st:ThemeInset('theme', 'theme', 'action')
			self.image:ClearAllPoints()
			self.image:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', border, -border)
			imageWidth = self.image:GetWidth() + 2 * border
			imageHeight = self.image:GetHeight() + 2 * border
		end
		local textLeft = imageWidth > 0 and imageWidth + IMAGE_GAP or 0
		local lineHeight = floor((self.size or FIELD_FONT_SIZE) * 1.3)
		local lines = CountLines(self.measure, self.fullText or '', self.frame:GetWidth() - textLeft - 10)
		local textHeight = lines * lineHeight
		local textTop = imageHeight > textHeight and floor((imageHeight - textHeight) / 2) or 0
		self.text:ClearAllPoints()
		self.text:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', textLeft, -textTop)
		self.text:SetPoint('TOPRIGHT', self.frame, 'TOPRIGHT', 0, -textTop)
		self.text:SetHeight(textHeight)
		self.frame:SetHeight(max(textHeight, imageHeight))
	end,

	-- AceConfigDialog's description image: image (a path or fileID, or a
	-- function giving one with its width and height), imageWidth and
	-- imageHeight, and imageCoords (4 or 8 numbers in a table, or a function
	-- giving one). Anything but a path or fileID draws no image.
	ShowImage = function(self)
		local root, row = self.root, self.row
		local image, width, height = OM.Member(root, row, 'image')
		if type(image) ~= 'string' and type(image) ~= 'number' then
			self.image:Hide()
			self.image.backdrop:Hide()
			return
		end
		if not width then width = OM.Member(root, row, 'imageWidth') end
		if not height then height = OM.Member(root, row, 'imageHeight') end
		self.image:SetTexture(image)
		self.image:SetSize(type(width) == 'number' and width or IMAGE_SIZE, type(height) == 'number' and height or IMAGE_SIZE)
		-- As AceGUI's label: any other count of numbers shows the whole texture,
		-- which also undoes a pooled widget's last crop.
		local coords = OM.Member(root, row, 'imageCoords')
		if type(coords) == 'table' and (#coords == 4 or #coords == 8) then
			self.image:SetTexCoord(unpack(coords))
		else
			self.image:SetTexCoord(0, 1, 0, 1)
		end
		self.image:Show()
		self.image.backdrop:Show()
	end,

	Refresh = function(self)
		local text = self.row.name
		if type(text) ~= 'string' then text = '' end
		-- fontSize: small (the default), medium or large.
		local size = DESCRIPTION_SIZES[OM.Member(self.root, self.row, 'fontSize')] or FIELD_FONT_SIZE
		self.size = size
		for _, fs in ipairs({ self.text, self.measure }) do
			SetFieldFont(fs, nil, size)
		end
		self.fullText = text
		self.text:SetText(text)
		self.text:SetTextColor(Colors().text.normal:GetRGB())
		self:ShowImage()
		self:Fit()
	end,
})

------------------------------------------------------------------ custom types

-- The types other files define (the bags' Categories tab): W.CUSTOM[rowType]
-- is { bare = true | false, titled = true | false, fill = true | false,
-- minHeight = n | nil } for each. The body draws a bare type's row with no
-- label, the widget across the whole line, and a titled bare type's with its
-- name above the widget; a fill type's row takes the height the body's view
-- has left, minHeight at least (optionsbody.lua).
W.CUSTOM = {}

-- The built-in types, which W.Define can't replace. The last type file,
-- optionsposition.lua, fills it once every built-in type has its builder.
local BUILT_IN = {}

-- W.Define(rowType, { width = n, bare = bool, titled = bool, fill = bool,
-- minHeight = n, build = function(w) end, methods = { Refresh = ...,
-- OnRelease = ..., ... } }) makes a widget type.
-- titled is for a bare type only: its row shows its name over the widget.
-- fill is for a bare type only too: its row stretches down to the bottom of
-- the body's view, so a page of it has nothing to scroll (the Categories tab,
-- whose list and editor scroll on their own); the body gives the widget its
-- height with w:SetHeight(h), never less than minHeight (34 when nil).
-- build makes w.frame, and whatever else the type keeps, once per widget.
-- The methods are copied onto each widget as define copies a built-in
-- type's, so Bind, Refresh (nothing after a release), Commit, SetDisabled
-- (OnDisabled) and Release (OnRelease) work as for the built-in types.
-- width is W.WIDTH[rowType] and the widget's GetWidth (0 when nil). A custom
-- type may be defined again (its file loaded again): widgets are then built
-- from the new definition, in a new pool, so the old ones never come back.
-- Redefining a built-in type is an error.
function W.Define(rowType, spec)
	if BUILT_IN[rowType] then
		error(format('SaftUI options: %q is a built-in widget type', tostring(rowType)), 2)
	end
	if type(rowType) ~= 'string' or type(spec) ~= 'table' or type(spec.build) ~= 'function' then
		error(format('SaftUI options: W.Define(%q) needs a type name and a build function', tostring(rowType)), 2)
	end
	builders[rowType] = spec.build
	define(rowType, spec.methods or {})
	pools[rowType] = {}
	W.WIDTH[rowType] = spec.width or 0
	local fill = (spec.bare and spec.fill) and true or false
	W.CUSTOM[rowType] = {
		bare = spec.bare and true or false,
		titled = (spec.bare and spec.titled) and true or false,
		fill = fill,
		minHeight = fill and (spec.minHeight or 34) or nil,
	}
end

------------------------------------------------------------------ the check list

-- A row of the open list: a check list's has a check box at its left, marked
-- by isChecked(key), and its label after it; a select's has no box and its
-- label 8 in, as BuildList made it. Rows are shared by both, so each fill
-- lays them out for the list that's open. Under Blizzard (list.blizzard,
-- LookList) the box is the Settings panel's check box, as every check box.
function LayCheckRow(row, entry)
	local checking = list.isChecked ~= nil
	if checking and not row.box then
		row.box = CheckBox(row, 18)
		row.box:SetPoint('LEFT', row, 'LEFT', 6, 0)
		row.box:EnableMouse(false)
	end
	if row.box then
		row.box:SetShown(checking)
		if checking then
			LookCheckBox(row.box, list.blizzard or false, LIST_ROW_HEIGHT, 'LEFT')
			SetCheck(row.box, list.isChecked(entry.key))
		end
	end
	if (row.checking or false) ~= checking then
		row.checking = checking
		row.text:ClearAllPoints()
		if checking then
			row.text:SetPoint('LEFT', row.box, 'RIGHT', 8, 0)
		else
			row.text:SetPoint('LEFT', row, 'LEFT', 8, 0)
		end
		row.text:SetPoint('RIGHT', row, 'RIGHT', -10, 0)
	end
end

-- A click on a check list's row: onToggle(key), then the marks again while
-- the list is still this one (onToggle may close it, or open another).
function ToggleCheck(row)
	local entry, onToggle = row.entry, list.onToggle
	if not entry then return end
	onToggle(entry.key)
	if list.onToggle == onToggle and list.catcher:IsShown() then ListFill() end
end

-- Opens the select list's frames under owner as a check list: entries are
-- { {key, label} }, each row a check box marked by isChecked(key). A click on
-- a row calls onToggle(key) and draws the marks again, leaving the list
-- open. A click outside, Esc and W.CloseList close it, and W.ListOwner()
-- reports owner while it's open, so the options window waits to re-render.
-- An empty list doesn't open.
function W.OpenCheckList(owner, entries, isChecked, onToggle)
	W.OpenList(owner, entries, nil, nil)
	if W.ListOwner() ~= owner then return end
	list.isChecked, list.onToggle = isChecked, onToggle
	ListFill()
end

------------------------------------------------------------------ for the later widget files

Kit.FIELD_HEIGHT, Kit.EDGE, Kit.ALT, Kit.FIELD, Kit.Colors = FIELD_HEIGHT, EDGE, ALT, FIELD, Colors
Kit.FIELD_FONT_SIZE, Kit.SetFieldFont, Kit.NewText, Kit.arts = FIELD_FONT_SIZE, SetFieldFont, NewText, arts
Kit.Art, Kit.Changes, Kit.Piece, Kit.HidePieces, Kit.LayThree = Art, Changes, Piece, HidePieces, LayThree
Kit.ShowBox, Kit.LookInput, Kit.LookLine, Kit.PaintFace = ShowBox, LookInput, LookLine, PaintFace
Kit.Base, Kit.builders, Kit.CheckBox, Kit.PlaceCheckArt = Base, builders, CheckBox, PlaceCheckArt
Kit.LookCheckBox, Kit.SetCheck, Kit.define, Kit.BUILT_IN = LookCheckBox, SetCheck, define, BUILT_IN
