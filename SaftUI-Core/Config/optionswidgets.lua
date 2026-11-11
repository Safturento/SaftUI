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

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format, tconcat, tinsert, tremove = string.format, table.concat, table.insert, table.remove

W.WIDTH = {
	toggle = 18, range = 168, select = 170, multiselect = 170, input = 170,
	color = 22, execute = 80, keybinding = 170, description = 400,
	position = 0, -- the block's width follows its parts (widget:GetWidth())
}
local TRACK_WIDTH, VALUE_WIDTH, GAP = 116, 46, 6
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
	fieldFont:SetFont(st.LSM:Fetch('font', config.font_name), FIELD_FONT_SIZE, config.font_outline)
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
	    choices fit (the select's section); the compact ones have none;
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
-- moves button.faceLeft or button.faceRight calls it again.
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

------------------------------------------------------------------ numbers

-- Strips float drift (0.1 * 3 is 0.30000000000000004).
local function Tidy(value)
	return tonumber(format('%.10g', value))
end

-- value on min's grid of step (no grid for a step of 0).
local function Snap(value, minimum, step)
	if step and step > 0 then
		value = floor((value - minimum) / step + 0.5) * step + minimum
	end
	return Tidy(value)
end

-- A number as the value box shows it: 0.065, 12, 33.5.
local function Shown(value, percent)
	if percent then value = value * 100 end
	return tostring(tonumber(format('%.6g', value)))
end

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

------------------------------------------------------------------ range

local KNOB_WIDTH, KNOB_HEIGHT = 6, 14

-- The range's look, when it changed: its flat track and knob, or Blizzard's
-- minimal slider (st.ThemeArt.Control('slider')): the track's ends and
-- middle at their atlas's height across the slider's middle, and the thumb
-- at its atlas's size, under which the slider centres it. Its value box is
-- a text box (LookInput).
local function LookRange(w, blizzard)
	local art = Art(w.slider)
	if Changes(art, blizzard) then
		for _, texture in ipairs(w.flat) do texture:SetShown(not blizzard) end
		local knob = w.slider:GetThumbTexture()
		if blizzard then
			local look = st.ThemeArt.Control('slider')
			local _, height = AtlasSize(look.middle)
			LayThree(art, w.slider, look, 'BACKGROUND', height or FIELD_HEIGHT, '')
			knob:SetAtlas(look.thumb)
			local width, thumbHeight = AtlasSize(look.thumb)
			if width then knob:SetSize(width, thumbHeight) end
			knob:SetVertexColor(1, 1, 1, 1)
		else
			HidePieces(art)
			knob:SetTexture(st.BLANK_TEX)
			knob:SetTexCoord(0, 1, 0, 1)
			knob:SetSize(KNOB_WIDTH, KNOB_HEIGHT)
			knob:SetVertexColor(Colors().text.normal:GetRGB())
		end
	end
	-- The slider between the arrows (Blizzard), else across the whole 116.
	local look = blizzard and st.ThemeArt.Control('slider')
	w.slider:ClearAllPoints()
	if blizzard then
		local backWidth, backHeight = AtlasSize(look.back)
		local forwardWidth, forwardHeight = AtlasSize(look.forward)
		local left = (backWidth or 0) + look.arrowGap
		local width = TRACK_WIDTH - left - look.arrowGap - (forwardWidth or 0)
		w.slider:SetPoint('LEFT', w.frame, 'LEFT', left, 0)
		w.slider:SetSize(width, FIELD_HEIGHT)
		for _, arrow in ipairs({ { w.backArrow, look.back, 0 }, { w.forwardArrow, look.forward, left + width + look.arrowGap } }) do
			local button, atlas, x = arrow[1], arrow[2], arrow[3]
			local aw, ah = AtlasSize(atlas)
			button:SetSize(aw or 0, ah or 0)
			button:ClearAllPoints()
			-- Each arrow's top is centred in the row, rounded down on whole pixels.
			button:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', x, -floor((FIELD_HEIGHT - (ah or 0)) / 2))
			button.texture:SetAtlas(atlas)
		end
	else
		w.slider:SetPoint('LEFT', w.frame, 'LEFT', 0, 0)
		w.slider:SetSize(TRACK_WIDTH, FIELD_HEIGHT)
	end
	w.backArrow:SetShown(blizzard)
	w.forwardArrow:SetShown(blizzard)
	LookInput(w.edit, blizzard, FIELD_HEIGHT)
end

builders.range = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(TRACK_WIDTH + GAP + VALUE_WIDTH, FIELD_HEIGHT)
	w.frame = frame

	local slider = CreateFrame('Slider', nil, frame)
	slider:SetOrientation('HORIZONTAL')
	slider:SetSize(TRACK_WIDTH, FIELD_HEIGHT)
	slider:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	slider:EnableMouse(true)
	slider:SetObeyStepOnDrag(true)
	w.slider = slider

	-- The track is the slider's own textures, under the knob by draw layer. A
	-- child frame put under it by frame level drew over it in game once the
	-- widget was reparented (that moves children back above their parent).
	-- A box's look: the dark line outside, the edge, the field inside it.
	local outline = slider:CreateTexture(nil, 'BACKGROUND')
	outline:SetColorTexture(unpack(ALT))
	outline:SetPoint('LEFT', slider, 'LEFT', -1, 0)
	outline:SetSize(TRACK_WIDTH + 2, 8)
	local track = slider:CreateTexture(nil, 'BORDER', nil, 0)
	track:SetColorTexture(unpack(EDGE))
	track:SetPoint('LEFT', slider, 'LEFT', 0, 0)
	track:SetSize(TRACK_WIDTH, 6)
	w.track = track
	local inside = slider:CreateTexture(nil, 'BORDER', nil, 1)
	inside:SetColorTexture(unpack(FIELD))
	inside:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	inside:SetPoint('BOTTOMRIGHT', track, 'BOTTOMRIGHT', -1, 1)
	local fill = slider:CreateTexture(nil, 'ARTWORK')
	fill:SetColorTexture(Colors().button.blue:GetRGB())
	fill:SetPoint('TOPLEFT', track, 'TOPLEFT', 1, -1)
	fill:SetPoint('BOTTOMLEFT', track, 'BOTTOMLEFT', 1, 1)
	fill:SetWidth(1)
	w.fill = fill

	-- The flat track, hidden under Blizzard (LookRange).
	w.flat = { outline, track, inside, fill }

	slider:SetThumbTexture(st.BLANK_TEX)
	local knob = slider:GetThumbTexture()
	knob:SetDrawLayer('OVERLAY')
	knob:SetSize(KNOB_WIDTH, KNOB_HEIGHT)
	knob:SetVertexColor(Colors().text.normal:GetRGB())

	-- The end arrows, hidden until Blizzard's look (LookRange): each a button
	-- of the frame's with its art as a texture, in colour while it can step
	-- and desaturated while it can't (RangeArrows).
	for key, direction in pairs({ backArrow = -1, forwardArrow = 1 }) do
		local arrow = CreateFrame('Button', nil, frame)
		arrow.texture = arrow:CreateTexture(nil, 'ARTWORK')
		arrow.texture:SetAllPoints(arrow)
		arrow:Hide()
		arrow:SetScript('OnClick', function() w:StepBy(direction) end)
		w[key] = arrow
	end

	local edit = Box(st:CreateFrame('EditBox', nil, frame))
	edit:SetSize(VALUE_WIDTH, FIELD_HEIGHT)
	edit:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('CENTER')
	edit:SetTextInsets(2, 2, 0, 0)
	edit:SetAutoFocus(false)
	w.edit = edit

	slider:SetScript('OnValueChanged', function(_, value)
		if w.updating or not w.row or w.disabled then return end
		-- A click on the track moves the slider before OnMouseDown runs, so a
		-- held button already means a drag: the window mustn't re-render (and
		-- take this slider away) until it's let go.
		if IsMouseButtonDown('LeftButton') then w.dragging = true end
		w:Dragged(value)
	end)
	slider:SetScript('OnMouseDown', function() w.dragging = true end)
	slider:SetScript('OnMouseUp', function()
		local changed = w.dirty
		w.dragging, w.dirty = nil, nil
		if changed and w.onChanged then w.onChanged(true) end
	end)

	edit:SetScript('OnEnterPressed', function(self)
		if not w.row then return end
		local text = self:GetText():gsub('%%', ''):gsub('^%s+', ''):gsub('%s+$', '')
		local number = tonumber(text)
		if number then w:Typed(number) else w:Refresh() end
		self:ClearFocus()
	end)
	edit:SetScript('OnEscapePressed', function(self)
		w:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self)
		Edge(self, true)
		self:HighlightText(0, -1)
	end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		w:Refresh()
	end)
end

-- Enables the end arrows: each while there's room to step that way from the
-- shown value (the value, else the slider's low end) and the range isn't
-- disabled; a disabled one is desaturated.
local function RangeArrows(w)
	if not w.softMin then return end
	local shown = w.value or w.softMin
	local back = not w.disabled and shown > w.softMin
	local forward = not w.disabled and shown < w.softMax
	w.backArrow:SetEnabled(back)
	w.forwardArrow:SetEnabled(forward)
	w.backArrow.texture:SetDesaturated(not back)
	w.forwardArrow.texture:SetDesaturated(not forward)
end

define('range', {
	Bind = function(self, ...)
		LookRange(self, BlizzardLook())
		return Base.Bind(self, ...)
	end,

	-- The slider's ends (softMin and softMax, else min and max, as
	-- AceConfigDialog gives them), and the hard limits typed numbers get cut to.
	Limits = function(self)
		local root, row = self.root, self.row
		local min_, max_ = OM.Member(root, row, 'min'), OM.Member(root, row, 'max')
		local softMin, softMax = OM.Member(root, row, 'softMin'), OM.Member(root, row, 'softMax')
		local step, bigStep = OM.Member(root, row, 'step'), OM.Member(root, row, 'bigStep')
		self.softMin, self.softMax = softMin or min_ or 0, softMax or max_ or 100
		self.hardMin = min_ or (not softMin and 0 or nil)
		self.hardMax = max_ or (not softMax and 100 or nil)
		self.step, self.dragStep = step or 0, bigStep or step or 0
		self.percent = OM.Member(root, row, 'isPercent') and true or false
	end,

	-- The hard limits, as AceConfigDialog's ActivateSlider cuts a value.
	Cut = function(self, value)
		if self.hardMin then value = max(value, self.hardMin) end
		if self.hardMax then value = min(value, self.hardMax) end
		return value
	end,

	-- The slider moved by the user: snapped to bigStep (or step) while
	-- dragging.
	Dragged = function(self, value)
		value = self:Cut(Snap(value, self.softMin, self.dragStep))
		if value == self.value then return end
		if self.dragging then self.dirty = true end
		self:Commit(value)
	end,

	-- An arrow's click: a step back (-1) or forward (1) from the shown value,
	-- by step, else bigStep, else a hundredth of the span, snapped on
	-- softMin's grid of that step, held to the slider's ends, then cut to min
	-- and max. It commits as a drag does, and only a changed value.
	StepBy = function(self, direction)
		if not self.row or self.disabled then return end
		local by = self.step > 0 and self.step or self.dragStep > 0 and self.dragStep or (self.softMax - self.softMin) / 100
		if by <= 0 then return end
		local value = Snap((self.value or self.softMin) + direction * by, self.softMin, by)
		value = self:Cut(max(self.softMin, min(self.softMax, value)))
		if value == self.value then return end
		self:Commit(value)
	end,

	-- A number typed in the box: cut to the slider's ends first, then snapped
	-- to step and cut to min and max.
	Typed = function(self, number)
		if self.percent then number = number / 100 end
		number = max(self.softMin, min(self.softMax, number))
		number = self:Cut(Snap(number, self.hardMin or self.softMin, self.step))
		self:Commit(number)
	end,

	Refresh = function(self)
		self:Limits()
		local value = self:Value()
		self.value = type(value) == 'number' and value or nil
		local shown = self.value or self.softMin
		self.updating = true
		self.slider:SetMinMaxValues(self.softMin, self.softMax)
		-- Always set (AceGUI's SetSliderValues does): a pooled slider keeps its last row's step.
		self.slider:SetValueStep(self.dragStep)
		self.slider:SetValue(max(self.softMin, min(self.softMax, shown)))
		self.updating = false
		local span = self.softMax - self.softMin
		local fraction = span > 0 and max(0, min(1, (shown - self.softMin) / span)) or 0
		self.fill:SetWidth(max(1, (TRACK_WIDTH - 2) * fraction))
		self.edit:SetText(self.value and (Shown(self.value, self.percent) .. (self.percent and '%' or '')) or '')
		RangeArrows(self)
	end,

	OnDisabled = function(self, disabled)
		RangeArrows(self)
		self.slider:EnableMouse(not disabled)
		self.edit:EnableMouse(not disabled)
		if disabled then self.edit:ClearFocus() end
	end,
})

------------------------------------------------------------------ select

-- A box that shows its choice and opens the list. The caret is four rows of
-- pixels, 7, 5, 3 and 1 wide, each placed by its left edge on a whole pixel
-- around one centre: placed by their centre, the odd widths would start half a
-- pixel off and blur. Returns the rows (hidden under Blizzard, LookDropdown).
local function Caret(parent)
	local carets = {}
	for i, width in ipairs({ 7, 5, 3, 1 }) do
		local t = parent:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Colors().text.grey:GetRGB())
		t:SetSize(width, 1)
		t:SetPoint('TOPLEFT', parent, 'RIGHT', -12 - floor(width / 2), 3 - i)
		carets[i] = t
	end
	return carets
end

-- Whether a select's row is a font list (LibSharedMedia's LSM30_Font):
-- name -> file, each name drawn in the file's face.
local function IsFontList(row)
	return row.option.dialogControl == 'LSM30_Font'
end

-- The entries for a row's values: { {key, label, font} }. A font list is
-- labeled by the name and drawn in the file's face.
local function ListEntries(root, row)
	local fontMode = IsFontList(row)
	local entries = {}
	for i, value in ipairs(OM.Values(root, row)) do
		if fontMode then
			entries[i] = { key = value.key, label = tostring(value.key), font = value.name }
		else
			entries[i] = { key = value.key, label = tostring(value.name) }
		end
	end
	return entries, fontMode
end

--[[
	Under Blizzard a select whose choices fit has Blizzard's steppers
	(DropdownWithSteppersTemplate): back over its left end and next over its
	right, the face between them (button.faceLeft and faceRight, the steppers
	and their gaps), so the select keeps its 170. A click on one picks the
	previous or next choice in the list's order, as a pick from the list does
	(Commit); one with no choice that way (an end, or a disabled select) is
	disabled, so nothing wraps. The choices fit when the longest's label, in
	the face's font, is at most W.StepperRoom() wide; else the face spans the
	whole select and there are none. That's read at each bind, so they come
	and go as the choices change. A font list never has them: measuring its
	names, each in its own face, would load every font file there is, at
	every render. Nor does an action select (Steppable): one with no value to
	step from (get = false or no get, as AceDBOptions' Copy From and Delete),
	whose next would pick its first choice and run the action in one click,
	or one that confirms, which would ask at every step. Under Thick and Thin
	there are none.
]]

-- Where a stepper's icon sits from its top left (WowStyle2IconButtonTemplate).
local STEPPER_ICON_X, STEPPER_ICON_Y = 4, -3

-- The stepped face's room for its text: the select less the steppers and
-- their gaps, less the text's inset at each side.
function W.StepperRoom()
	local look = st.ThemeArt.Control('dropdown')
	local steps = look.stepper
	return W.WIDTH.select - (steps.width + steps.backGap) - (steps.width + steps.nextGap) - 2 * look.textInset
end

-- A stepper's art in its state, as the face's (PaintFace): disabled, held
-- down under the mouse (pressedhover), under the mouse, held down off it,
-- else normal. Its icon is the disabled one while disabled, and sits
-- pressedOffset further while an enabled one is held down. Nothing until its
-- select first wears the steppers (PlaceStepper).
local function PaintStepper(stepper)
	local art = arts[stepper]
	local look = art.look
	if not look then return end
	local steps, enabled = look.stepper, stepper:IsEnabled()
	local state = 'normal'
	if not enabled then
		state = 'disabled'
	elseif art.down and art.over then
		state = 'pressedhover'
	elseif art.over then
		state = 'hover'
	elseif art.down then
		state = 'pressed'
	end
	art.pieces.Background:SetAtlas(steps.background[state])
	local icon = art.pieces.Icon
	if art.direction < 0 then
		icon:SetAtlas(enabled and steps.back or steps.backDisabled)
	else
		icon:SetAtlas(enabled and steps.next or steps.nextDisabled)
	end
	local x, y = STEPPER_ICON_X, STEPPER_ICON_Y
	if enabled and art.down then x, y = x + look.pressedOffset[1], y + look.pressedOffset[2] end
	icon:ClearAllPoints()
	icon:SetPoint('TOPLEFT', stepper, 'TOPLEFT', x, y)
end

-- One of a select's steppers, back (direction -1) or next (1): a button of
-- the select's own, hidden until it wears them, with the button art round it
-- (Background) and its arrow (Icon). Its state follows the mouse. The game
-- sends a disabled button no OnEnter or OnLeave, so a stepper enabled again
-- reads whether the mouse is on it now.
local function Stepper(w, button, direction)
	local stepper = CreateFrame('Button', nil, button)
	stepper:Hide()
	local art = Art(stepper)
	art.direction = direction
	art.pieces.Background = stepper:CreateTexture(nil, 'BACKGROUND')
	art.pieces.Icon = stepper:CreateTexture(nil, 'ARTWORK')
	local function State(field, value)
		return function(self)
			art[field] = value
			PaintStepper(self)
		end
	end
	stepper:SetScript('OnEnter', State('over', true))
	stepper:SetScript('OnLeave', State('over', false))
	stepper:SetScript('OnMouseDown', State('down', true))
	stepper:SetScript('OnMouseUp', State('down', false))
	stepper:SetScript('OnDisable', State('down', false))
	stepper:SetScript('OnEnable', function(self)
		art.over = self:IsMouseOver()
		PaintStepper(self)
	end)
	-- A pooled select hidden mid-press or under the mouse starts afresh.
	stepper:SetScript('OnHide', function()
		art.over, art.down = false, false
	end)
	stepper:SetScript('OnClick', function() w:Step(direction) end)
	return stepper
end

-- A stepper over side ('LEFT' or 'RIGHT') of button, in look (the dropdown's
-- art): as tall as the button, its art outset round it as the face's is.
local function PlaceStepper(stepper, button, side, look)
	local steps, art = look.stepper, Art(stepper)
	art.look = look
	stepper:SetSize(steps.width, button:GetHeight())
	stepper:ClearAllPoints()
	stepper:SetPoint(side, button, side, 0, 0)
	local background = art.pieces.Background
	background:ClearAllPoints()
	background:SetPoint('TOPLEFT', stepper, 'TOPLEFT', -look.outset, look.outset)
	background:SetPoint('BOTTOMRIGHT', stepper, 'BOTTOMRIGHT', look.outset, -look.outset)
	art.pieces.Icon:SetSize(steps.icon, steps.icon)
end

-- While the steppers show: each enabled when there's a choice to step to
-- that way and the select isn't disabled, and painted. entries are the
-- choices when the caller has them (StepTargets).
local function EnableSteppers(w, entries)
	if not w.stepped then return end
	local back, nextKey
	if not w.disabled then back, nextKey = w:StepTargets(entries) end
	w.back:SetEnabled(back ~= nil)
	w.next:SetEnabled(nextKey ~= nil)
	PaintStepper(w.back)
	PaintStepper(w.next)
end

-- Whether a select may have steppers: not a font list, and not an action:
-- it shows a value to step from (a get that isn't false) and sets it with
-- no confirm.
local function Steppable(w)
	return not IsFontList(w.row) and OM.Has(w.root, w.row, 'get') and not OM.Has(w.root, w.row, 'confirm')
end

-- The select's look: under Blizzard the steppers either side of the face
-- when it may have them (Steppable) and its choices fit (StepsFit), the
-- face between them, else the face across it all; then its dropdown's
-- (LookDropdown). Only the face takes the mouse for the list, as only it
-- lights. The choices are read once, for the fit and the steppers' states;
-- not at all for a select that may have none.
local function LookSelect(w, blizzard)
	local button = w.frame
	local look = blizzard and st.ThemeArt.Control('dropdown')
	local entries = blizzard and Steppable(w) and ListEntries(w.root, w.row) or nil
	w.stepped = entries ~= nil and w:StepsFit(entries)
	if w.stepped then
		local steps = look.stepper
		button.faceLeft, button.faceRight = steps.width + steps.backGap, steps.width + steps.nextGap
		PlaceStepper(w.back, button, 'LEFT', look)
		PlaceStepper(w.next, button, 'RIGHT', look)
	else
		button.faceLeft, button.faceRight = 0, 0
	end
	w.back:SetShown(w.stepped)
	w.next:SetShown(w.stepped)
	button:SetHitRectInsets(button.faceLeft, button.faceRight, 0, 0)
	LookDropdown(button, blizzard)
	EnableSteppers(w, entries)
end

builders.select = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.select, FIELD_HEIGHT)
	w.frame = button
	w.text = NewText(button, 'LEFT')
	w.text:SetPoint('LEFT', button, 'LEFT', 8, 0)
	w.text:SetPoint('RIGHT', button, 'RIGHT', -22, 0)
	button.text = w.text
	button.caret = Caret(button)
	HoverEdge(button, function() return w.disabled end)
	button:SetScript('OnClick', function() w:Open() end)
	button:SetScript('OnHide', function()
		if W.ListOwner() == button then W.CloseList() end
	end)
	DropdownStates(button, function() return w.disabled end)
	w.back = Stepper(w, button, -1)
	w.next = Stepper(w, button, 1)
	-- The choices' labels are measured on this (StepsFit), never shown.
	w.measure = NewText(button, 'LEFT')
	w.measure:SetWordWrap(false)
	w.measure:Hide()
end

define('select', {
	-- The look after the row: whether the steppers fit reads its choices.
	-- Until then they're left be (Refresh and OnDisabled skip them), so
	-- the choices are read once for them (LookSelect).
	Bind = function(self, ...)
		self.stepped = false
		Base.Bind(self, ...)
		LookSelect(self, BlizzardLook())
		return self
	end,

	-- Whether every choice's label (entries, else the row's now) fits the
	-- stepped face (W.StepperRoom), measured in the face's font. True with
	-- no choices; never for a font list, whose names aren't measured.
	StepsFit = function(self, entries)
		if IsFontList(self.row) then return false end
		local room, measure = W.StepperRoom(), self.measure
		SetFieldFont(measure)
		for _, entry in ipairs(entries or ListEntries(self.root, self.row)) do
			measure:SetText(entry.label)
			if ceil(measure:GetUnboundedStringWidth()) > room then return false end
		end
		return true
	end,

	-- The keys a step back and a step forward pick, in the list's order
	-- (entries, else the row's now); nil past an end. A value not among the
	-- choices has none back, and the first next.
	StepTargets = function(self, entries)
		if not self.row then return nil, nil end
		local value = self:Value()
		entries = entries or ListEntries(self.root, self.row)
		for i, entry in ipairs(entries) do
			if entry.key == value then
				local back, forward = entries[i - 1], entries[i + 1]
				return back and back.key, forward and forward.key
			end
		end
		return nil, entries[1] and entries[1].key
	end,

	-- Picks the choice a step back (-1) or forward (1), as a pick from the
	-- list does. Nothing past an end, while disabled, or without steppers.
	Step = function(self, direction)
		if self.disabled or not self.stepped then return end
		local back, forward = self:StepTargets()
		local key
		if direction < 0 then key = back else key = forward end
		if key ~= nil then self:Commit(key) end
	end,

	-- Only the chosen key's label is resolved here; the list is built when it opens.
	Refresh = function(self)
		self.value = self:Value()
		local values = OM.Member(self.root, self.row, 'values')
		local fontMode = IsFontList(self.row)
		local label, font = '', nil
		if type(values) == 'table' and self.value ~= nil and values[self.value] ~= nil then
			if fontMode then
				label, font = tostring(self.value), values[self.value]
			else
				label = tostring(values[self.value])
			end
		end
		if fontMode and font then
			SetFieldFont(self.text, font, FIELD_FONT_SIZE, '')
		else
			SetFieldFont(self.text)
		end
		self.text:SetText(label)
		EnableSteppers(self)
	end,

	-- The list is built from the values as they are now: a function can
	-- depend on other settings.
	Open = function(self)
		if self.disabled or not self.row then return end
		local entries, fontMode = ListEntries(self.root, self.row)
		W.OpenList(self.frame, entries, self:Value(), function(key) self:Commit(key) end, fontMode)
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		PaintFace(self.frame)
		EnableSteppers(self)
	end,

	OnRelease = function(self)
		self.stepped = false
		if W.ListOwner() == self.frame then W.CloseList() end
	end,
})

------------------------------------------------------------------ multiselect

local MULTI_ROW = 22
-- Under Blizzard the box is a line at the multiselect's edge, so its rows sit
-- this far in from it on the left and right, as their boxes are above and below.
local MULTI_INSET = 2

builders.multiselect = function(w)
	local frame = st:CreateFrame('Frame', nil, UIParent) -- no box under Thick and Thin
	frame:SetSize(W.WIDTH.multiselect, MULTI_ROW)
	w.frame = frame
	w.rows = {}
end

-- A row's look: its box's (LookCheckBox), and under Blizzard the box's
-- highlight drawn over it, a texture of the box's own in its OVERLAY layer
-- (row.hover), which the row's OnEnter shows and OnLeave hides: the box takes
-- no mouse, so its own HIGHLIGHT layer never shows, and a texture of the
-- row's would lie under the box's art (a frame's regions draw under its
-- children). Under Thick and Thin the row lights the box's edge instead.
-- Under Blizzard the row's box and label sit MULTI_INSET in, clear of the
-- multiselect's line.
local function LookRow(row, blizzard)
	LookCheckBox(row.box, blizzard, MULTI_ROW, 'LEFT')
	row.blizzard = blizzard
	if blizzard and not row.hover then
		row.hover = row.box:CreateTexture(nil, 'OVERLAY', nil, 1)
	end
	if row.hover then
		if blizzard then
			PlaceCheckArt(row.box, row.hover)
			row.hover:SetAtlas(row.box.look.highlight)
			row.hover:SetBlendMode(row.box.look.highlightBlend)
		end
		row.hover:Hide()
	end
	local inset = blizzard and MULTI_INSET or 0
	row.box:SetPoint('LEFT', row, 'LEFT', inset, 0)
	row.label:SetPoint('RIGHT', row, 'RIGHT', -inset, 0)
end

local function MultiRow(w, i)
	local row = w.rows[i]
	if row then return row end
	row = CreateFrame('Button', nil, w.frame)
	row:SetHeight(MULTI_ROW)
	row:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', 0, -(i - 1) * MULTI_ROW)
	row:SetPoint('TOPRIGHT', w.frame, 'TOPRIGHT', 0, -(i - 1) * MULTI_ROW)
	row.box = CheckBox(row, 18)
	row.box:SetPoint('LEFT', row, 'LEFT', 0, 0)
	row.box:EnableMouse(false)
	row.label = NewText(row, 'LEFT')
	row.label:SetPoint('LEFT', row.box, 'RIGHT', 8, 0)
	row.label:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
	LookRow(row, w.blizzard or false)
	row:SetScript('OnEnter', function(self)
		Edge(self.box, true)
		if self.blizzard then self.hover:Show() end
	end)
	row:SetScript('OnLeave', function(self)
		Edge(self.box, false)
		if self.hover then self.hover:Hide() end
	end)
	row:SetScript('OnClick', function(self)
		if w.disabled or self.key == nil then return end
		w:Commit(self.key, not self.checked)
	end)
	w.rows[i] = row
	return row
end

define('multiselect', {
	Bind = function(self, ...)
		self.blizzard = BlizzardLook()
		LookLine(self.frame, self.blizzard)
		for _, row in ipairs(self.rows) do LookRow(row, self.blizzard) end
		return Base.Bind(self, ...)
	end,

	OnDisabled = function(self, disabled)
		for _, row in ipairs(self.rows) do SetCheck(row.box, row.checked, disabled) end
	end,

	Refresh = function(self)
		local values = OM.Values(self.root, self.row)
		for i, value in ipairs(values) do
			local row = MultiRow(self, i)
			row.key = value.key
			row.checked = self:Value(value.key) and true or false
			SetCheck(row.box, row.checked, self.disabled)
			row.label:SetText(tostring(value.name))
			row:Show()
		end
		for i = #values + 1, #self.rows do
			self.rows[i].key = nil
			self.rows[i]:Hide()
		end
		self.frame:SetHeight(max(MULTI_ROW, #values * MULTI_ROW))
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

------------------------------------------------------------------ keybinding

local IGNORED_KEYS = {
	BUTTON1 = true, BUTTON2 = true, UNKNOWN = true,
	LSHIFT = true, LCTRL = true, LALT = true, RSHIFT = true, RCTRL = true, RALT = true,
}
local MOUSE_BUTTONS = { MiddleButton = 'BUTTON3', Button4 = 'BUTTON4', Button5 = 'BUTTON5' }

-- The binding button's nine pieces (UIMenuButtonStretchTemplate's): its
-- corners, the edges between them and the middle.
local BINDING_PIECES = {
	'TopLeft', 'TopMiddle', 'TopRight', 'MiddleLeft', 'MiddleMiddle', 'MiddleRight',
	'BottomLeft', 'BottomMiddle', 'BottomRight',
}

-- The binding button's state: its pieces -Down while pressed, else -Up, and
-- the select piece while it waits for a key.
local function PaintBinding(w)
	local art = arts[w.frame]
	if not (art and art.blizzard) then return end
	local file = art.down and art.look.down or art.look.up
	for _, key in ipairs(BINDING_PIECES) do
		art.pieces[key]:SetTexture(file)
		art.pieces[key]:SetTexCoord(unpack(art.look.pieces[key]))
	end
	art.pieces.Select:SetShown(w.waiting and true or false)
end

-- The keybinding's look, when it changed: Box, or Blizzard's binding button
-- (KeyBindingFrameBindingButtonTemplate, st.ThemeArt.Control('binding')):
-- nine pieces of one file filling the button, its corners cornerWidth by
-- cornerHeight; the highlight under the mouse; and the select piece while it
-- waits for a key.
local function LookBinding(w, blizzard)
	local button = w.frame
	local art = Art(button)
	if not Changes(art, blizzard) then return end
	ShowBox(button, not blizzard)
	if not blizzard then
		HidePieces(art)
		return
	end
	local look = st.ThemeArt.Control('binding')
	art.look = look
	local p = {}
	for _, key in ipairs(BINDING_PIECES) do
		p[key] = Piece(art, button, key, 'BACKGROUND')
		p[key]:ClearAllPoints()
	end
	for key, point in pairs({ TopLeft = 'TOPLEFT', TopRight = 'TOPRIGHT', BottomLeft = 'BOTTOMLEFT', BottomRight = 'BOTTOMRIGHT' }) do
		p[key]:SetPoint(point, button, point)
		p[key]:SetSize(look.cornerWidth, look.cornerHeight)
	end
	local function Between(key, from, fromPoint, to, toPoint)
		p[key]:SetPoint('TOPLEFT', p[from], fromPoint)
		p[key]:SetPoint('BOTTOMRIGHT', p[to], toPoint)
	end
	Between('TopMiddle', 'TopLeft', 'TOPRIGHT', 'TopRight', 'BOTTOMLEFT')
	Between('BottomMiddle', 'BottomLeft', 'TOPRIGHT', 'BottomRight', 'BOTTOMLEFT')
	Between('MiddleLeft', 'TopLeft', 'BOTTOMLEFT', 'BottomLeft', 'TOPRIGHT')
	Between('MiddleRight', 'TopRight', 'BOTTOMLEFT', 'BottomRight', 'TOPRIGHT')
	Between('MiddleMiddle', 'TopLeft', 'BOTTOMRIGHT', 'BottomRight', 'TOPLEFT')
	-- In the HIGHLIGHT layer, which the game shows only under the mouse.
	local highlight = Piece(art, button, 'Highlight', 'HIGHLIGHT')
	highlight:SetTexture(look.highlight)
	highlight:SetTexCoord(unpack(look.highlightCoords))
	highlight:SetBlendMode(look.highlightBlend)
	highlight:SetAllPoints(button)
	local waiting = Piece(art, button, 'Select', 'ARTWORK')
	waiting:SetTexture(look.select)
	waiting:SetBlendMode(look.selectBlend)
	waiting:SetAllPoints(button)
	PaintBinding(w)
end

builders.keybinding = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.keybinding, FIELD_HEIGHT)
	w.frame = button
	w.text = NewText(button, 'CENTER')
	w.text:SetAllPoints()
	HoverEdge(button, function() return w.disabled or w.waiting end)

	-- A press while waiting is the new key. Esc clears the binding.
	local function Press(key)
		if not w.waiting then return end
		if key ~= 'ESCAPE' then
			if IGNORED_KEYS[key] then return end
			if IsShiftKeyDown() then key = 'SHIFT-' .. key end
			if IsControlKeyDown() then key = 'CTRL-' .. key end
			if IsAltKeyDown() then key = 'ALT-' .. key end
		else
			key = ''
		end
		w:StopWaiting()
		w:Commit(key)
	end
	button:SetScript('OnKeyDown', function(self, key)
		if not InCombatLockdown() then self:SetPropagateKeyboardInput(not w.waiting) end
		Press(key)
	end)
	button:SetScript('OnMouseWheel', function(_, delta)
		Press(delta >= 0 and 'MOUSEWHEELUP' or 'MOUSEWHEELDOWN')
	end)
	button:SetScript('OnMouseDown', function(_, mouseButton)
		if mouseButton == 'LeftButton' or mouseButton == 'RightButton' then return end
		Press(MOUSE_BUTTONS[mouseButton] or mouseButton)
	end)
	button:SetScript('OnClick', function(_, mouseButton)
		if w.disabled then return end
		if mouseButton ~= nil and mouseButton ~= 'LeftButton' then return end
		if w.waiting then w:StopWaiting() else w:StartWaiting() end
	end)
	button:SetScript('OnHide', function() w:StopWaiting() end)
	-- Under Blizzard its pieces are -Down while pressed.
	local art = Art(button)
	button:HookScript('OnMouseDown', function()
		art.down = true
		PaintBinding(w)
	end)
	button:HookScript('OnMouseUp', function()
		art.down = false
		PaintBinding(w)
	end)
	button:HookScript('OnHide', function() art.down = false end)
end

define('keybinding', {
	Bind = function(self, ...)
		LookBinding(self, BlizzardLook())
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		local key = self:Value()
		self.value = key
		self.text:SetFontObject(W.GetFont())
		if self.waiting then
			self.text:SetText('Press a key')
			self.text:SetTextColor(Colors().text.blue:GetRGB())
		elseif key and key ~= '' then
			self.text:SetText(key)
			self.text:SetTextColor(Colors().text.normal:GetRGB())
		else
			self.text:SetText('Not bound')
			self.text:SetTextColor(Colors().text.grey:GetRGB())
		end
	end,

	StartWaiting = function(self)
		self.waiting = true
		self.frame:EnableKeyboard(true)
		self.frame:EnableMouseWheel(true)
		Edge(self.frame, true)
		PaintBinding(self)
		self:Refresh()
	end,

	StopWaiting = function(self)
		if not self.waiting then return end
		self.waiting = nil
		self.frame:EnableKeyboard(false)
		self.frame:EnableMouseWheel(false)
		Edge(self.frame, false)
		PaintBinding(self)
		if self.row then self:Refresh() end
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		if disabled then self:StopWaiting() end
	end,

	OnRelease = function(self)
		self:StopWaiting()
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

------------------------------------------------------------------ position

-- The Position block: THIS [dots] TO [target] AT ITS [dots] OFFSET [X over Y],
-- each part a caption over a 48 tall band, 12 apart. One block per option
-- (type 'position'); its get/set/validate take the part first: 'point',
-- 'rel_point', 'x_off', 'y_off', 'frame', 'relative_to'.
local POINTS = { 'TOPLEFT', 'TOP', 'TOPRIGHT', 'LEFT', 'CENTER', 'RIGHT', 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT' }
local POS_GAP, POS_BAND, POS_CAPTION_HEIGHT, POS_CAPTION_GAP = 12, 48, 13, 4
local POS_BAND_TOP = POS_CAPTION_HEIGHT + POS_CAPTION_GAP
local POS_DOT_CELL, POS_DOT_MARGIN = 14, 3
local POS_BOX, POS_NUDGE, POS_AXIS, POS_AXIS_GAP = 22, 14, 12, 8
local POS_NAME_WIDTH, POS_SELECT_WIDTH, POS_NAME_HEIGHT = 120, 140, 24
-- The nudge box overlaps the edit box's right edge by 1: one shared seam.
local POS_OFFSET_WIDTH = POS_AXIS + POS_AXIS_GAP + 46 + POS_NUDGE - 1
local DOT_GREY = { 0.333, 0.333, 0.333 }

-- The dot's look: 4x4 grey, or 8x8 blue when it is the picked one; the text
-- color while the mouse is on it.
local function PaintDot(dot)
	local r, g, b
	if dot.hovered then
		r, g, b = Colors().text.normal:GetRGB()
	elseif dot.picked then
		r, g, b = Colors().button.blue:GetRGB()
	else
		r, g, b = unpack(DOT_GREY)
	end
	local size = dot.picked and 8 or 4
	dot.dot:SetSize(size, size)
	dot.dot:SetColorTexture(r, g, b)
end

-- A 48x48 square of nine dot buttons; onPick(point) on a click.
local function DotSquare(w, parent, onPick)
	local square = Box(st:CreateFrame('Frame', nil, parent))
	square:SetSize(POS_BAND, POS_BAND)
	square.dots = {}
	for i, point in ipairs(POINTS) do
		local button = st:CreateFrame('Button', nil, square)
		button:SetSize(POS_DOT_CELL, POS_DOT_CELL)
		local col, line = (i - 1) % 3, floor((i - 1) / 3)
		button:SetPoint('TOPLEFT', square, 'TOPLEFT', POS_DOT_MARGIN + col * POS_DOT_CELL, -(POS_DOT_MARGIN + line * POS_DOT_CELL))
		button.dot = button:CreateTexture(nil, 'OVERLAY')
		button.dot:SetPoint('CENTER', button, 'CENTER', 0, 0)
		button.point = point
		button:SetScript('OnClick', function()
			if w.disabled then return end
			onPick(point)
		end)
		button:SetScript('OnEnter', function(self)
			if not w.disabled then self.hovered = true; PaintDot(self) end
			w:Tip(true)
		end)
		button:SetScript('OnLeave', function(self)
			self.hovered = false
			PaintDot(self)
			w:Tip(false)
		end)
		PaintDot(button)
		square.dots[i] = button
	end
	return square
end

-- A nudge's stepper art under Blizzard, in its state: pressed, under the
-- mouse, else normal.
local function PaintNudge(button)
	local art = arts[button]
	if not (art and art.blizzard) then return end
	local state = art.down and 'pressed' or art.over and 'hover' or 'normal'
	art.pieces.Arrow:SetAtlas(art.arrows[state])
end

-- One half of the nudge pair: a 14x11 button (a clickable region of the
-- pair's box) with a three-row arrow, 2/4/6 wide, in whole pixels. Up sits in
-- the box's rows 1-9 (the arrow in rows 4-6, from the button's TOP); down in rows
-- 11-20 (rows 3-5 of its button, from its TOP).
local function NudgeButton(w, parent, up, onClick)
	local button = st:CreateFrame('Button', nil, parent)
	button:SetSize(POS_NUDGE, POS_BOX / 2)
	button.arrows = {}
	for i = 1, 3 do
		local t = button:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Colors().text.grey:GetRGB())
		t:SetSize(up and (2 * i) or (8 - 2 * i), 1)
		t:SetPoint('TOP', button, 'TOP', 0, -((up and 3 or 2) + i))
		button.arrows[i] = t
	end
	button:SetScript('OnClick', function()
		if w.disabled then return end
		onClick()
	end)
	button:SetScript('OnEnter', function(self)
		if not w.disabled then
			for _, t in ipairs(self.arrows) do t:SetColorTexture(Colors().text.normal:GetRGB()) end
		end
		w:Tip(true)
	end)
	button:SetScript('OnLeave', function(self)
		for _, t in ipairs(self.arrows) do t:SetColorTexture(Colors().text.grey:GetRGB()) end
		w:Tip(false)
	end)
	-- Under Blizzard its stepper art follows the mouse (PaintNudge).
	local art = Art(button)
	local function Hook(script, field, value)
		button:HookScript(script, function(self)
			art[field] = value
			PaintNudge(self)
		end)
	end
	Hook('OnEnter', 'over', true)
	Hook('OnLeave', 'over', false)
	Hook('OnMouseDown', 'down', true)
	Hook('OnMouseUp', 'down', false)
	button:HookScript('OnHide', function()
		art.over, art.down = false, false
	end)
	return button
end

-- The nudge pair: one 14x22 box with a 1px divider between up and down, and
-- the two buttons over its halves.
local function NudgePair(w, parent, onUp, onDown)
	local pair = Box(st:CreateFrame('Frame', nil, parent))
	pair:SetSize(POS_NUDGE, POS_BOX)
	local divider = pair:CreateTexture(nil, 'ARTWORK')
	divider:SetColorTexture(unpack(EDGE))
	divider:SetSize(POS_NUDGE - 2, 1)
	divider:SetPoint('TOPLEFT', pair, 'TOPLEFT', 1, -(POS_BOX / 2 - 1))
	local up = NudgeButton(w, pair, true, onUp)
	up:SetPoint('TOPLEFT', pair, 'TOPLEFT', 0, 0)
	local down = NudgeButton(w, pair, false, onDown)
	down:SetPoint('BOTTOMLEFT', pair, 'BOTTOMLEFT', 0, 0)
	pair.divider, pair.up, pair.down = divider, up, down
	return pair, up, down
end

-- The nudge pairs' look, when it changed: their box, divider and arrows, or
-- MinimalScrollBar's steppers (st.ThemeArt.Control('nudge')), each filling
-- its half of the pair.
local function LookNudges(w, blizzard)
	local look
	for _, pair in ipairs(w.nudgePairs) do
		if Changes(Art(pair), blizzard) then
			ShowBox(pair, not blizzard)
			pair.divider:SetShown(not blizzard)
			look = look or (blizzard and st.ThemeArt.Control('nudge'))
			for _, button in ipairs({ pair.up, pair.down }) do
				local art = Art(button)
				art.blizzard = blizzard
				for _, row in ipairs(button.arrows) do row:SetShown(not blizzard) end
				if blizzard then
					local arrow = Piece(art, button, 'Arrow', 'ARTWORK')
					arrow:ClearAllPoints()
					arrow:SetAllPoints(button)
					art.arrows = button == pair.up and look.up or look.down
					PaintNudge(button)
				else
					HidePieces(art)
				end
			end
		end
	end
end

-- An edit box of the block. onEnter(text) runs on Enter, after focus is dropped.
local function PositionEdit(w, parent, justify, onEnter)
	local edit = Box(st:CreateFrame('EditBox', nil, parent))
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH(justify)
	edit:SetTextInsets(justify == 'CENTER' and 2 or 8, justify == 'CENTER' and 2 or 8, 0, 0)
	edit:SetAutoFocus(false)
	edit:SetScript('OnEnter', function(self)
		if not (w.disabled or self:HasFocus()) then Edge(self, true) end
		w:Tip(true)
	end)
	edit:SetScript('OnLeave', function(self)
		if not self:HasFocus() then Edge(self, false) end
		w:Tip(false)
	end)
	edit:SetScript('OnEnterPressed', function(self)
		if not w.row or w.disabled then return end
		local text = self:GetText()
		self:ClearFocus()
		onEnter(text)
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
	return edit
end

builders.position = function(w)
	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetHeight(POS_BAND_TOP + POS_BAND)
	w.frame = frame

	local function PickDot(part) return function(point) w:Commit(part, point) end end
	w.thisSquare = DotSquare(w, frame, PickDot('point'))
	w.atSquare = DotSquare(w, frame, PickDot('rel_point'))
	w.this, w.at = w.thisSquare.dots, w.atSquare.dots

	w.name = PositionEdit(w, frame, 'LEFT', function(text) w:Commit('frame', strtrim(text)) end)

	w.select = Box(st:CreateFrame('Button', nil, frame))
	w.select:SetSize(POS_SELECT_WIDTH, POS_BOX)
	w.select.text = NewText(w.select, 'LEFT')
	w.select.text:SetPoint('LEFT', w.select, 'LEFT', 8, 0)
	w.select.text:SetPoint('RIGHT', w.select, 'RIGHT', -22, 0)
	w.select.caret = Caret(w.select)
	w.select:SetScript('OnClick', function() w:Open() end)
	w.select:SetScript('OnEnter', function(self)
		if not w.disabled then Edge(self, true) end
		w:Tip(true)
	end)
	w.select:SetScript('OnLeave', function(self) Edge(self, false); w:Tip(false) end)
	w.select:SetScript('OnHide', function(self)
		if W.ListOwner() == self then W.CloseList() end
	end)
	DropdownStates(w.select, function() return w.disabled end)

	-- X and Y: label, box, then the nudge pair, overlapping the box's right edge by 1.
	local function Axis(label, part, errName)
		local axis = NewText(frame, 'LEFT')
		axis:SetText(label)
		axis:SetWidth(POS_AXIS)
		local box = PositionEdit(w, frame, 'CENTER', function(text)
			local number = tonumber(strtrim(text))
			if not number then
				w:Refresh()
				if w.onChanged then w.onChanged(false, errName .. ' must be a number') end
				return
			end
			w:Commit(part, number)
		end)
		box:SetSize(46, POS_BOX)
		local pair, up, down = NudgePair(w, frame, function() w:Nudge(part, 1) end, function() w:Nudge(part, -1) end)
		pair:SetPoint('TOPLEFT', box, 'TOPRIGHT', -1, 0)
		w.nudgePairs[#w.nudgePairs + 1] = pair
		return axis, box, up, down
	end
	w.nudgePairs = {}
	w.xLabel, w.x, w.xUp, w.xDown = Axis('X', 'x_off', 'X')
	w.yLabel, w.y, w.yUp, w.yDown = Axis('Y', 'y_off', 'Y')

	-- Captions: shown ones are in w.captions, left to right.
	w.captionFor = {}
	for _, key in ipairs({ 'this', 'to', 'at', 'offset' }) do
		local fs = frame:CreateFontString(nil, 'OVERLAY')
		fs:SetFontObject(st.OptionsBody.Font('caption'))
		fs:SetJustifyH('CENTER')
		fs:SetWordWrap(false)
		fs:SetHeight(POS_CAPTION_HEIGHT)
		w.captionFor[key] = fs
	end
	w.captionFor.this:SetText('THIS')
	w.captionFor.to:SetText('TO')
	w.captionFor.at:SetText('AT ITS')
	w.captionFor.offset:SetText('OFFSET')
	w.captions = {}
end

define('position', {
	-- Its parts' looks: the dots a line (no Blizzard equivalent), the name,
	-- X and Y boxes text boxes, the dropdown Blizzard's, the nudges steppers.
	Bind = function(self, ...)
		local blizzard = BlizzardLook()
		LookLine(self.thisSquare, blizzard)
		LookLine(self.atSquare, blizzard)
		LookInput(self.name, blizzard, POS_NAME_HEIGHT)
		LookInput(self.x, blizzard, POS_BOX)
		LookInput(self.y, blizzard, POS_BOX)
		LookDropdown(self.select, blizzard, true)
		LookNudges(self, blizzard)
		return Base.Bind(self, ...)
	end,

	-- A block's parts are laid out for the row's target; nothing of a previous
	-- bind is left (the dropdown, the name box, the TO caption, the widths).
	Refresh = function(self)
		local root, row = self.root, self.row
		local target = OM.Member(root, row, 'target')
		if target ~= 'name' and target ~= 'select' then target = nil end
		self.target = target

		local point, relPoint = self:Value('point'), self:Value('rel_point')
		for i, dot in ipairs(self.this) do
			dot.hovered, dot.picked = false, POINTS[i] == point
			PaintDot(dot)
		end
		for i, dot in ipairs(self.at) do
			dot.hovered, dot.picked = false, POINTS[i] == relPoint
			PaintDot(dot)
		end
		self.x:SetText(tostring(tonumber(self:Value('x_off')) or 0))
		self.y:SetText(tostring(tonumber(self:Value('y_off')) or 0))

		-- The TO part.
		local showName = target == 'name'
		local toWidth = 0
		if target == 'name' then
			toWidth = POS_NAME_WIDTH
		elseif target == 'select' then
			toWidth = POS_SELECT_WIDTH
			local key = self:Value('relative_to')
			local values = OM.Member(root, row, 'values')
			local label = ''
			if type(values) == 'table' and key ~= nil and values[key] ~= nil then label = tostring(values[key]) end
			SetFieldFont(self.select.text)
			self.select.text:SetText(label)
			showName = key ~= nil and key == OM.Member(root, row, 'nameKey')
		end
		self.select:SetShown(target == 'select')
		if showName then self.name:SetText(tostring(self:Value('frame') or '')) end
		self.name:SetShown(showName)
		self.name:SetSize(target == 'select' and POS_SELECT_WIDTH or POS_NAME_WIDTH,
			target == 'select' and POS_BOX or POS_NAME_HEIGHT)

		-- Left to right, 12 apart.
		local frame, x = self.frame, 0
		local captions = {}
		local function Part(key, width)
			local fs = self.captionFor[key]
			fs:ClearAllPoints()
			fs:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, 0)
			fs:SetWidth(width)
			fs:SetTextColor(Colors().text.grey:GetRGB())
			fs:Show()
			captions[#captions + 1] = fs
			local at = x
			x = x + width + POS_GAP
			return at
		end
		local band = -POS_BAND_TOP
		self.thisSquare:ClearAllPoints()
		self.thisSquare:SetPoint('TOPLEFT', frame, 'TOPLEFT', Part('this', POS_BAND), band)
		if target then
			local at = Part('to', toWidth)
			self.select:ClearAllPoints()
			self.name:ClearAllPoints()
			if target == 'select' then
				self.select:SetPoint('TOPLEFT', frame, 'TOPLEFT', at, band)
				self.name:SetPoint('TOPLEFT', frame, 'TOPLEFT', at, band - POS_BOX - 4)
			else
				self.name:SetPoint('TOPLEFT', frame, 'TOPLEFT', at, band - (POS_BAND - POS_NAME_HEIGHT) / 2)
			end
		else
			self.captionFor.to:Hide()
		end
		self.atSquare:ClearAllPoints()
		self.atSquare:SetPoint('TOPLEFT', frame, 'TOPLEFT', Part('at', POS_BAND), band)
		local offsetAt = Part('offset', POS_OFFSET_WIDTH)
		for i, axis in ipairs({ { self.xLabel, self.x }, { self.yLabel, self.y } }) do
			local y = band - (i - 1) * (POS_BOX + 4)
			axis[1]:ClearAllPoints()
			axis[1]:SetPoint('TOPLEFT', frame, 'TOPLEFT', offsetAt, y - 3)
			axis[2]:ClearAllPoints()
			axis[2]:SetPoint('TOPLEFT', frame, 'TOPLEFT', offsetAt + POS_AXIS + POS_AXIS_GAP, y)
			SetFieldFont(axis[1])
			axis[1]:SetTextColor(Colors().text.normal:GetRGB())
		end
		wipe(self.captions)
		for i, fs in ipairs(captions) do self.captions[i] = fs end
		self.width = x - POS_GAP
		frame:SetWidth(self.width)
	end,

	Nudge = function(self, part, direction)
		if self.disabled or not self.row then return end
		local stored = tonumber(self:Value(part)) or 0
		self:Commit(part, stored + direction * (IsShiftKeyDown() and 10 or 1))
	end,

	-- The window shows the row's desc over the whole block (set by the body).
	Tip = function(self, on)
		if self.onTip then self.onTip(on) end
	end,

	Open = function(self)
		if self.disabled or not self.row or self.target ~= 'select' then return end
		local entries, fontMode = ListEntries(self.root, self.row)
		W.OpenList(self.select, entries, self:Value('relative_to'), function(key) self:Commit('relative_to', key) end, fontMode)
	end,

	OnDisabled = function(self, disabled)
		for _, square in ipairs({ self.thisSquare, self.atSquare }) do
			for _, dot in ipairs(square.dots) do dot:EnableMouse(not disabled) end
		end
		for _, control in ipairs({ self.select, self.xUp, self.xDown, self.yUp, self.yDown }) do
			control:EnableMouse(not disabled)
		end
		PaintFace(self.select)
		for _, edit in ipairs({ self.name, self.x, self.y }) do
			edit:EnableMouse(not disabled)
			if disabled then edit:ClearFocus() end
		end
	end,

	OnRelease = function(self)
		self.onTip = nil
		if W.ListOwner() == self.select then W.CloseList() end
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

-- The types above, which W.Define can't replace.
local BUILT_IN = {}
for rowType in pairs(builders) do BUILT_IN[rowType] = true end

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
