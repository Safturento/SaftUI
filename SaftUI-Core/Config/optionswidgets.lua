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

-- The confirm dialog's frames { catcher, frame, text, yes, no, box, skin }
-- (nil until first asked; skin is what draws it as the window is under
-- Blizzard). For tests.
function W.GetDialogFrames() return dialog end

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

------------------------------------------------------------------ for the later widget files

Kit.FIELD_HEIGHT, Kit.LIST_STRATA, Kit.EDGE, Kit.ALT, Kit.FIELD = FIELD_HEIGHT, LIST_STRATA, EDGE, ALT, FIELD
Kit.BG, Kit.Colors, Kit.FIELD_FONT_SIZE, Kit.SetFieldFont = BG, Colors, FIELD_FONT_SIZE, SetFieldFont
Kit.NewText, Kit.arts, Kit.Art, Kit.Changes, Kit.Piece = NewText, arts, Art, Changes, Piece
Kit.HidePieces, Kit.LayThree, Kit.ShowBox, Kit.Inset = HidePieces, LayThree, ShowBox, Inset
Kit.LookInput, Kit.LookLine, Kit.PaintFace, Kit.CountLines = LookInput, LookLine, PaintFace, CountLines
Kit.Base, Kit.builders, Kit.CheckBox, Kit.PlaceCheckArt = Base, builders, CheckBox, PlaceCheckArt
Kit.LookCheckBox, Kit.SetCheck, Kit.define, Kit.BUILT_IN = LookCheckBox, SetCheck, define, BUILT_IN
