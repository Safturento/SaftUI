local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	SaftUI's own color picker (st.OptionsWidgets, optionswidgets.lua), which
	the color type opens in place of Blizzard's picker
	(optionstypes.lua), and the color maths it runs on.

	  W.OpenColorPicker(owner, spec) -> boolean
	      spec = { r, g, b, a, hasAlpha, onChange = function(r, g, b, a),
	      onCancel = function(), preview, name }. preview is the option's
	      own field (a preview kind's name or a table, optionspreview.lua) and
	      name the option's: with a kind the file knows, a strip under the
	      square shows the color in context and the picker is 94 taller. owner is the frame it opens beside (the
	      field's): its top left 8 right of the owner's top right, or left of
	      the owner's left, and up, when it would leave the screen. false in
	      combat. Opening it while it is open for another field accepts the
	      first one (as Okay) and opens for the second.
	  W.CloseColorPicker(within) cancels an open picker: with within (a
	      frame), only when its owner is inside it. The window, its small
	      dialog and its item menu call it as they close, before they release
	      the widget the picker changes, so the restore reaches it.
	  W.ColorPickerShown() -> boolean: what the window's keys, its renders
	      and the menu's click-away ask.
	  W.WatchColorPicker(fn) calls fn() each time the picker is shown or
	      hidden, after it has: the window's size buttons follow it.
	  W.GetColorPickerFrames() -> the frames, for tests.
	  W.ColorMath: the pure maths (below), for tests too.

	What it draws (all in the kit's own parts, the panel as the kit's dialogs
	are drawn): a 170 square for shade (saturation across, brightness up) of
	the current hue, a 16 wide strip for hue and, with hasAlpha, another for
	opacity (the color over a checker, solid at the top), their captions; a
	column 152 wide with the color it opened with at the left (a click on it
	goes back to it), a chevron-right, and the color being chosen at the right
	(no words on them; each has a tooltip), the
	red, green and blue boxes (0 to 255), the opacity box (a percent, hasAlpha
	only) and the hex box; the preview, when the option has one (a caption
	"Preview" at 248, its note at the right, and the area at 266, 64 tall,
	the panel's inner width: W.PREVIEW, optionspreview.lua; it is repainted
	by Paint on each change, by st:KeepOwnColors after a theme recolor and by
	a follower of Text); Last used (up to 12, newest first, account-wide in
	st.config.global.colorPicker.recent; at 248, or 342 under a preview), and
	Okay and Cancel. The Colors page edits the class colors, so the picker has
	no row of them.
	The square and the strips are gradient textures (Texture:SetGradient with
	CreateColor), on both clients.

	It holds hue, saturation and brightness as its own state and derives red,
	green and blue from them; a typed red, green, blue or hex sets them back
	(RGBToHSV keeps the hue while the color is grey or black, so the thumb and
	the hue strip don't jump). Red, green and blue are kept as they were given
	until the square or a strip moves them, so a color the picker opened with
	is handed back exactly, never a hair off it.

	Every change is live: onChange runs as the square, a strip, a box or a chip
	changes the color. Okay closes it and remembers the color; Cancel, Esc, the
	window closing and combat put the opening color back through onChange,
	then call onCancel, and remember nothing. A click outside does nothing.
	Its top strip, from the title down to above the square (F.drag), moves it:
	the panel is kept on the screen by the margin, the drop is rounded to whole
	units, and it stays there while it is open; closing it forgets the place
	(opening puts it by its field again). A drag is no click outside, Okay or
	Cancel, and changes no color.
	A box takes its value on Enter or when it loses the keyboard (a value out
	of range is held in it; text that isn't a number puts the old value back),
	and Tab moves through the boxes in order (Shift-Tab back).

	Whole pixels: every size is a whole number, every part placed by its top
	left, the thumbs by a rounded step; no size read back from the game is
	used to place anything (it carries a hair of float noise).

	The scripts take (self) only where a second parameter would be the game's
	motion argument (OnEnter and OnLeave). A drag in the square or a strip
	follows the mouse with OnUpdate while the button is down, reading the
	cursor through the frame's effective scale; it stops on mouse up, on hide
	and when the button is up whichever way (let go outside).
]]

local floor, max, min = math.floor, math.max, math.min
local format = string.format

local Box, Edge, BlizzardLook = W.Box, W.Edge, W.BlizzardLook
local HoverStates = W.HoverStates
local NewText, SetFieldFont, LookInput = Kit.NewText, Kit.SetFieldFont, Kit.LookInput

------------------------------------------------------------------ the maths

local M = {}
W.ColorMath = M

local RECENT_MAX = 12

local function Round(x) return floor(x + 0.5) end

function M.Clamp(value, low, high) return max(low, min(high, value)) end
local Clamp = M.Clamp

-- A channel 0 to 1 as a whole 0 to 255.
function M.ToByte(value) return Clamp(Round(value * 255), 0, 255) end
local ToByte = M.ToByte

-- Hue (0 to 1, 1 the same as 0), saturation and brightness (0 to 1) as red,
-- green and blue.
function M.HSVToRGB(h, s, v)
	h = (h % 1) * 6
	local sector = floor(h)
	local fraction = h - sector
	local p, q, t = v * (1 - s), v * (1 - s * fraction), v * (1 - s * (1 - fraction))
	if sector == 0 then return v, t, p end
	if sector == 1 then return q, v, p end
	if sector == 2 then return p, v, t end
	if sector == 3 then return p, q, v end
	if sector == 4 then return t, p, v end
	return v, p, q
end

-- Red, green and blue as hue, saturation and brightness. A grey or a black has
-- no hue of its own: it keeps hue (the one the picker holds; 0 when none is
-- given), so a shade dragged through a corner leaves the hue where it was.
function M.RGBToHSV(r, g, b, hue)
	local high, low = max(r, g, b), min(r, g, b)
	local delta = high - low
	local s = high == 0 and 0 or delta / high
	if delta == 0 then return hue or 0, s, high end
	local h
	if high == r then
		h = ((g - b) / delta) % 6
	elseif high == g then
		h = (b - r) / delta + 2
	else
		h = (r - g) / delta + 4
	end
	return h / 6, s, high
end

-- '#RRGGBB' in capitals, or '#RRGGBBAA' when an opacity is given. Each channel
-- is held in 0 to 1 and rounded to a whole byte.
function M.FormatHex(r, g, b, a)
	local text = format('#%02X%02X%02X', ToByte(r), ToByte(g), ToByte(b))
	if a ~= nil then text = text .. format('%02X', ToByte(a)) end
	return text
end

-- r, g, b (and a, for eight digits, the last pair) from text: six or eight hex
-- digits, with or without a leading # and spaces round them. nil for anything
-- else.
function M.ParseHex(text)
	if type(text) ~= 'string' then return nil end
	text = text:gsub('%s', '')
	text = text:gsub('^#', '')
	if (#text ~= 6 and #text ~= 8) or text:find('%X') then return nil end
	local function byte(i) return tonumber(text:sub(i, i + 1), 16) / 255 end
	return byte(1), byte(3), byte(5), #text == 8 and byte(7) or nil
end

-- A whole number from what was typed (a % sign allowed), held in low to high;
-- nil when it is no number.
function M.ParseNumber(text, low, high)
	if type(text) ~= 'string' then return nil end
	local n = tonumber((text:gsub('[%s%%]', '')))
	if not n or n ~= n or n == math.huge or n == -math.huge then return nil end
	return Clamp(Round(n), low, high)
end

-- A color's identity in the Last used list: its code and its whole percent.
local function KeyOf(r, g, b, a)
	return format('%02X%02X%02X%d', ToByte(r), ToByte(g), ToByte(b), Round(a * 100))
end

-- list with the color put first: a new list (the one given is not changed),
-- without any earlier entry for the same color, cut to limit.
function M.Remember(list, r, g, b, a, limit)
	local key = KeyOf(r, g, b, a)
	local out = { { r = r, g = g, b = b, a = a } }
	for _, entry in ipairs(list) do
		if #out >= limit then break end
		if KeyOf(entry.r, entry.g, entry.b, entry.a) ~= key then out[#out + 1] = entry end
	end
	return out
end

local OPEN_GAP = 8 -- between the owner and the picker

-- Where a picker width x height goes by its owner (anchor = { left, right,
-- top, bottom }, in screen units from the screen's bottom left): the top left
-- corner's x and y from that corner, whole numbers. Right of the owner, 8
-- apart, at its top; left of it when that would pass the screen's right (less
-- margin, { left, right, top, bottom }, none when nil); up until its bottom
-- is on the screen, and down from its top.
function M.Place(anchor, width, height, screenWidth, screenHeight, margin)
	margin = margin or { left = 0, right = 0, top = 0, bottom = 0 }
	local x = anchor.right + OPEN_GAP
	if x + width > screenWidth - margin.right then x = anchor.left - OPEN_GAP - width end
	x = max(margin.left, min(x, screenWidth - margin.right - width))
	local y = min(anchor.top, screenHeight - margin.top)
	y = max(y, height + margin.bottom)
	return Round(x), Round(y)
end

------------------------------------------------------------------ sizes

local PAD = 20
local BODY_Y = 48 -- the square's top, under the title
local DRAG_HEIGHT = 40 -- the title strip that moves the panel, ending above the square
local SQUARE, STRIP_WIDTH, GAP = 170, 16, 16
local INNER = SQUARE - 2 -- inside the 1px edge of the square and the strips
local COLUMN = 152 -- two equal, even blocks of 64 with a gap of 24 between them
local BLOCK_WIDTH, BLOCK_HEIGHT, BLOCK_GAP = 64, 26, 24
local ARROW = 16 -- the chevron in the gap, 4 either side (the size the bags' next-category button draws it)
local BOX_WIDTH, BOX_HEIGHT = 84, 22
local ROW_FIRST, ROW_PITCH = 34, 28 -- the first number row, in from the column's top; between rows
local CAPTION_SIZE = 13
local CHIP, CHIP_GAP = 18, 4
local RECENT_CAPTION_Y, RECENT_Y = 248, 266 -- Last used; 94 further down (W.PREVIEW.ROOM) with a preview
local HEIGHT = 342
local LEVEL = 500 -- over the window (100), the small dialog (300) and an item's menu (410)
local THUMB, BAR_WIDTH, BAR_HEIGHT = 10, 22, 6 -- the square's thumb; a strip's
local CHECKER, CHECKER_DARK, CHECKER_LIGHT = Kit.CHECKER, Kit.CHECKER_DARK, Kit.CHECKER_LIGHT -- the color field's own (optionstypes.lua)

------------------------------------------------------------------ state

local frame, keys -- the panel and its key catcher, made on first use
local F = {} -- the parts, for the layout and for tests
local spec -- the open picker's: set while it is open
local S = {} -- the color: h, s, v; r, g, b; a
local tipOwner -- the chip the tooltip shows for

local function Shown() return frame ~= nil and frame:IsShown() end
function W.ColorPickerShown() return Shown() end

-- Who is told when the picker is shown or hidden (W.WatchColorPicker).
local watchers = {}
function W.WatchColorPicker(fn) watchers[#watchers + 1] = fn end
local function Tell()
	for _, fn in ipairs(watchers) do xpcall(fn, geterrorhandler()) end
end
function W.GetColorPickerFrames() return F end

-- Whether frame is inside parent (or is it).
local function Inside(child, parent)
	while child do
		if child == parent then return true end
		child = child:GetParent()
	end
	return false
end

------------------------------------------------------------------ pieces

-- A ring frame width x height round its parent's thumb place: a white 1px
-- line with a black one outside it, which the mouse passes through.
local function Ring(parent, width, height)
	local ring = st:CreateFrame('Frame', nil, parent)
	ring:SetSize(width, height)
	ring:SetFrameLevel(parent:GetFrameLevel() + 3)
	ring:SetBackdrop({ edgeFile = st.BLANK_TEX, edgeSize = 1 })
	ring:SetBackdropBorderColor(1, 1, 1, 1)
	local outline = st:CreateFrame('Frame', nil, ring)
	outline:SetPoint('TOPLEFT', ring, 'TOPLEFT', -1, 1)
	outline:SetPoint('BOTTOMRIGHT', ring, 'BOTTOMRIGHT', 1, -1)
	outline:SetBackdrop({ edgeFile = st.BLANK_TEX, edgeSize = 1 })
	outline:SetBackdropBorderColor(0, 0, 0, 1)
	return ring
end

-- region at x, y in from owner's top left, width x height.
local function Place(region, owner, x, y, width, height)
	region:ClearAllPoints()
	region:SetPoint('TOPLEFT', owner, 'TOPLEFT', x, -y)
	if width then region:SetSize(width, height) end
end

-- A checker of two greys under a see-through color, width x height at x, y in
-- from owner's top left, its squares cell wide (the last column and row cut at
-- the edge): the dark grey across it and a light square every other one.
-- Made the first time it is shown.
local function ShowChecker(owner, shown, x, y, width, height, cell)
	local checker = owner.checker
	if not checker then
		if not shown then return end
		checker = { squares = {} }
		checker.back = owner:CreateTexture(nil, 'ARTWORK', nil, 1)
		checker.back:SetColorTexture(unpack(CHECKER_DARK))
		Place(checker.back, owner, x, y, width, height)
		local n = 0
		for row = 0, math.ceil(height / cell) - 1 do
			for col = 0, math.ceil(width / cell) - 1 do
				if (row + col) % 2 == 0 then
					n = n + 1
					local square = owner:CreateTexture(nil, 'ARTWORK', nil, 2)
					square:SetColorTexture(unpack(CHECKER_LIGHT))
					Place(square, owner, x + col * cell, y + row * cell,
						min(cell, width - col * cell), min(cell, height - row * cell))
					checker.squares[n] = square
				end
			end
		end
		owner.checker = checker
	end
	checker.back:SetShown(shown)
	for _, square in ipairs(checker.squares) do square:SetShown(shown) end
end

-- A button swatch width x height: a black field with a 1px edge and the color
-- a pixel in, over a checker while it is see-through. swatch:Paint(r, g, b, a).
local function NewSwatch(parent, width, height)
	local swatch = Box(st:CreateFrame('Button', nil, parent), { 0, 0, 0, 1 })
	swatch:SetSize(width, height)
	swatch.color = swatch:CreateTexture(nil, 'ARTWORK', nil, 3) -- over the hover Layer (-8): a swatch shows its color exactly, never tinted
	Place(swatch.color, swatch, 1, 1, width - 2, height - 2)
	function swatch:Paint(r, g, b, a)
		self.color:SetColorTexture(r, g, b, a)
		ShowChecker(self, a < 1, 1, 1, width - 2, height - 2, CHECKER)
	end
	return swatch
end

------------------------------------------------------------------ the color

-- The state painted: the square's hue, the thumbs, the opacity strip's color,
-- the chosen block, and the boxes (not the one being typed in).
local function ShowBoxes()
	for _, edit in ipairs(F.edits) do
		if not edit:HasFocus() then edit:SetText(edit.show()) end
	end
end

-- The open picker's preview kind painted with the color being chosen (the
-- field's kind def, its pieces, the opacity as shown): on every change, as
-- the picker opens, and when something took the preview's own colors off its
-- frames (a theme recolor or redraw: st:KeepOwnColors) or Text changed (a
-- follower). Sets colors only (optionspreview.lua).
local function PaintKind()
	local kind = spec and spec.kind
	local pieces = kind and F.previewPieces[kind]
	if pieces and not spec.failed then spec.def.Paint(pieces, S.r, S.g, S.b, spec.hasAlpha and S.a or 1, spec.paint) end
end

-- PaintKind, guarded: a kind of a module that errors is reported once for this
-- opening and not painted again, and stops neither the field being told nor
-- the area's Text follower (which a follower that errors would lose).
-- xpcall with no arguments makes no closure.
local function PaintPreview()
	if not (spec and spec.kind) or spec.failed then return end
	if not xpcall(PaintKind, geterrorhandler()) and spec then spec.failed = true end
end

-- The kind's note and its Layout for the strip's inner width, guarded, run
-- when the picker lays out and when the theme's look changes under it; false
-- when the kind's Layout errors. Defined with Layout, below.
local PlaceKind

-- The theme pass of the preview (st:KeepOwnColors, which runs after a
-- recolor or a redraw of the theme): paints again, and lays the kind out again
-- when the look flipped between Blizzard's and SaftUI's (a boolean compare, so
-- a drag of a Theme color stays colors only).
local function PreviewOwnColors()
	if not (spec and spec.kind) then return end
	if spec.blizzard ~= (BlizzardLook() and true or false) then
		if PlaceKind(spec.kind) == false then spec.failed = true end
	end
	PaintPreview()
end

local function Paint()
	if not frame then return end
	local hr, hg, hb = M.HSVToRGB(S.h, 1, 1)
	F.base:SetColorTexture(hr, hg, hb, 1)
	local x, y = Round(S.s * INNER), Round((1 - S.v) * INNER)
	Place(F.squareThumb, F.square, 1 + x - THUMB / 2, y + 1 - THUMB / 2)
	Place(F.hueThumb, F.hue, -(BAR_WIDTH - STRIP_WIDTH) / 2, Round(S.h * INNER) + 1 - BAR_HEIGHT / 2)
	local alpha = spec and spec.hasAlpha
	if alpha then
		F.alphaFill:SetGradient('VERTICAL', CreateColor(S.r, S.g, S.b, 0), CreateColor(S.r, S.g, S.b, 1))
		Place(F.alphaThumb, F.alpha, -(BAR_WIDTH - STRIP_WIDTH) / 2, Round((1 - S.a) * INNER) + 1 - BAR_HEIGHT / 2)
	end
	local shown = alpha and S.a or 1
	F.new:Paint(S.r, S.g, S.b, shown)
	ShowBoxes()
	-- Last: a kind of a module that errors must not stop the field being told.
	PaintPreview()
end

-- The color has changed: show it, and tell the field.
local function Changed()
	Paint()
	if spec and spec.onChange then xpcall(spec.onChange, geterrorhandler(), S.r, S.g, S.b, spec.hasAlpha and S.a or 1) end
end

local function SetHSV(h, s, v)
	if h == S.h and s == S.s and v == S.v then return end
	S.h, S.s, S.v = h, s, v
	S.r, S.g, S.b = M.HSVToRGB(h, s, v)
	Changed()
end

-- Red, green and blue (and the opacity, when given) set outright; the hue is
-- kept while the color is grey or black.
local function SetRGBA(r, g, b, a)
	a = a == nil and S.a or a
	if r == S.r and g == S.g and b == S.b and a == S.a then return end
	S.r, S.g, S.b, S.a = r, g, b, a
	S.h, S.s, S.v = M.RGBToHSV(r, g, b, S.h)
	Changed()
end

local function SetOpacity(a)
	if a == S.a then return end
	S.a = a
	Changed()
end

------------------------------------------------------------------ closing

local function ClearBoxFocus()
	for _, edit in ipairs(F.edits) do edit:ClearFocus() end
end

local function RememberColor(r, g, b, a)
	local global = st.config and st.config.global
	if not global then return end
	global.colorPicker = global.colorPicker or {}
	global.colorPicker.recent = M.Remember(global.colorPicker.recent or {}, r, g, b, a, RECENT_MAX)
end

-- Okay: a box still being typed in takes its text first; then the color is
-- remembered and the picker closes. Nothing is called: the field has the
-- color already.
local Cancel
local function Okay()
	if not spec then return end
	ClearBoxFocus()
	-- The setting changed under it (a profile switch): nothing is recorded or written.
	if spec.stale and spec.stale() then return Cancel() end
	local done = spec
	RememberColor(S.r, S.g, S.b, done.hasAlpha and S.a or 1)
	spec = nil
	frame:Hide()
	st:EndColorEdit() -- after the hide: the OnHide that runs Cancel finds no spec
end

-- Cancel (and Esc, the window closing, combat): the opening color back through
-- onChange, then onCancel.
function Cancel()
	local done = spec
	if not done then return end
	spec = nil
	ClearBoxFocus()
	frame:Hide()
	if done.onChange then xpcall(done.onChange, geterrorhandler(), done.r, done.g, done.b, done.hasAlpha and done.a or 1) end
	if done.onCancel then xpcall(done.onCancel, geterrorhandler()) end
	st:EndColorEdit() -- after the restore and onCancel: its whole passes cover them
end

function W.CloseColorPicker(within)
	if not spec then return end
	if within and not Inside(spec.owner, within) then return end
	Cancel()
end

------------------------------------------------------------------ dragging

-- Where the cursor is in area's 168 square, as fractions 0 to 1 from its
-- top left, read through its effective scale.
local function Fractions(area)
	local x, y = GetCursorPosition()
	local scale = area:GetEffectiveScale()
	local left, top = area:GetLeft(), area:GetTop()
	if not (left and top and scale and scale > 0) then return end
	return Clamp((x / scale - left - 1) / INNER, 0, 1), Clamp((top - y / scale - 1) / INNER, 0, 1)
end

-- Makes area follow the mouse while the left button is down: apply(fx, fy).
local function Draggable(area, apply)
	local function Follow(self)
		if not IsMouseButtonDown('LeftButton') then
			self:SetScript('OnUpdate', nil)
			return
		end
		local fx, fy = Fractions(self)
		if fx then apply(fx, fy) end
	end
	local function Stop(self) self:SetScript('OnUpdate', nil) end
	area:EnableMouse(true)
	area:SetScript('OnMouseDown', function(self, button)
		if button ~= 'LeftButton' or not spec then return end
		ClearBoxFocus() -- a box's typed text is taken first, so it can't override the drag later
		self:SetScript('OnUpdate', Follow)
		local fx, fy = Fractions(self)
		if fx then apply(fx, fy) end
	end)
	area:SetScript('OnMouseUp', Stop)
	area:HookScript('OnHide', Stop)
end

------------------------------------------------------------------ moving it

local movingPanel = false -- the title strip is moving the panel

-- Stops the move the title strip started. Dropped, the panel is placed again
-- by its top left on whole units (the game leaves a dragged frame on a
-- fraction).
local function StopMove(drop)
	if not movingPanel then return end
	movingPanel = false
	F.drag:SetScript('OnUpdate', nil)
	frame:StopMovingOrSizing()
	local left, top = frame:GetLeft(), frame:GetTop()
	if drop and left and top then
		local k = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', Round(left * k), Round(top * k))
	end
end

-- The top strip of the panel moves it, from the title down to above the
-- square, so no control's own drag or click is in its way. Where it is dropped
-- it stays while it is open; opening it puts it by its field again
-- (PlaceBeside), so nothing is saved.
local function BuildDragStrip()
	local strip = st:CreateFrame('Frame', nil, frame)
	strip:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
	strip:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
	strip:SetHeight(DRAG_HEIGHT)
	strip:EnableMouse(true)
	strip:SetScript('OnMouseDown', function(_, button)
		if button ~= 'LeftButton' or not spec or movingPanel then return end
		movingPanel = true
		frame:StartMoving()
		-- A mouse up that never reaches the strip (let go where it no longer is)
		-- ends the move too.
		strip:SetScript('OnUpdate', function()
			if not IsMouseButtonDown('LeftButton') then StopMove(true) end
		end)
	end)
	strip:SetScript('OnMouseUp', function() StopMove(true) end)
	F.drag = strip
end

------------------------------------------------------------------ boxes

-- The boxes in order, each { label, show() -> text, take(text) -> whether
-- the text was understood }. Opacity only with hasAlpha.
local function BoxSpecs()
	local function channel(name, key)
		return {
			label = name,
			show = function() return tostring(ToByte(S[key])) end,
			take = function(text)
				local n = M.ParseNumber(text, 0, 255)
				if not n then return false end
				if n ~= ToByte(S[key]) then
					local c = { r = S.r, g = S.g, b = S.b }
					c[key] = n / 255
					SetRGBA(c.r, c.g, c.b)
				end
				return true
			end,
		}
	end
	local list = { channel('Red', 'r'), channel('Green', 'g'), channel('Blue', 'b') }
	list[4] = {
		label = 'Opacity', alpha = true,
		show = function() return Round(S.a * 100) .. '%' end,
		take = function(text)
			local n = M.ParseNumber(text, 0, 100)
			if not n then return false end
			if n ~= Round(S.a * 100) then SetOpacity(n / 100) end
			return true
		end,
	}
	list[5] = {
		label = 'Hex',
		show = function() return M.FormatHex(S.r, S.g, S.b) end,
		take = function(text)
			local r, g, b, a = M.ParseHex(text)
			if not r then return false end
			if a and not (spec and spec.hasAlpha) then return false end
			local same = ToByte(r) == ToByte(S.r) and ToByte(g) == ToByte(S.g) and ToByte(b) == ToByte(S.b)
				and (a == nil or ToByte(a) == ToByte(S.a))
			if not same then SetRGBA(r, g, b, a) end
			return true
		end,
	}
	return list
end

local function Commit(edit)
	if not spec then return end
	edit.take(edit:GetText())
end

local function NewBox(parent, entry)
	local edit = Box(st:CreateFrame('EditBox', nil, parent))
	edit:SetSize(BOX_WIDTH, BOX_HEIGHT)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('CENTER')
	edit:SetTextInsets(2, 2, 0, 0)
	edit:SetAutoFocus(false)
	edit.show, edit.take, edit.alpha = entry.show, entry.take, entry.alpha
	edit.label = NewText(parent, 'LEFT')
	edit.label:SetText(entry.label)
	edit:SetScript('OnEnterPressed', function(self)
		Commit(self)
		self:SetText(self.show())
		self:ClearFocus()
	end)
	edit:SetScript('OnEscapePressed', function(self)
		self:SetText(self.show())
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self)
		Edge(self, true)
		self:HighlightText()
	end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		Commit(self)
		if spec then self:SetText(self.show()) end
	end)
	edit:SetScript('OnTabPressed', function(self)
		local order = F.order
		for i, other in ipairs(order) do
			if other == self then
				local step = IsShiftKeyDown() and -1 or 1
				local target = order[(i - 1 + step) % #order + 1]
				target:SetFocus()
				return
			end
		end
	end)
	HoverStates(edit) -- after the scripts: hover tints, focus lights the edge (Edge above)
	return edit
end

------------------------------------------------------------------ chips

local function Chip(row, i)
	local chip = row.chips[i]
	if not chip then
		chip = NewSwatch(frame, CHIP, CHIP)
		chip:SetScript('OnEnter', function(self)
			tipOwner = self
			if self.tip then W.ShowTip(self, self.tip(self), nil, 'ANCHOR_TOP') end
		end)
		chip:SetScript('OnLeave', function(self) W.HideTip(self) end)
		chip:SetScript('OnClick', function(self)
			if self.pick then self.pick(self) end
		end)
		HoverStates(chip) -- a box: the hover tints its color (once in the chip's life)
		row.chips[i] = chip
	end
	Place(chip, frame, PAD + (i - 1) * (CHIP + CHIP_GAP), row.y, CHIP, CHIP)
	return chip
end

-- The picker's own Text colors: its captions (the preview's too) and the
-- chevron in Muted, the number boxes' labels in Normal. A follower of Text
-- (st:FollowColor in Build) while it is open, and the color part of Look.
local function PaintText()
	if not spec then return end
	local r, g, b = st:Color('text', 'muted'):GetRGB()
	for _, caption in ipairs(F.captions) do caption:SetTextColor(r, g, b) end
	F.arrow:SetVertexColor(r, g, b)
	r, g, b = st:Color('text', 'normal'):GetRGB()
	for _, edit in ipairs(F.edits) do edit.label:SetTextColor(r, g, b) end
end

local function RecentList()
	local global = st.config and st.config.global
	return global and global.colorPicker and global.colorPicker.recent or {}
end

local function FillRecentChips()
	local row, n = F.recent, 0
	for _, entry in ipairs(RecentList()) do
		if n >= RECENT_MAX then break end
		n = n + 1
		local chip = Chip(row, n)
		local alpha = spec and spec.hasAlpha
		chip:Paint(entry.r, entry.g, entry.b, alpha and entry.a or 1)
		chip.tip = function()
			local text = M.FormatHex(entry.r, entry.g, entry.b)
			local percent = Round(entry.a * 100)
			if alpha and percent < 100 then text = text .. ' \194\183 ' .. percent .. '%' end
			return text
		end
		chip.pick = function() SetRGBA(entry.r, entry.g, entry.b, alpha and entry.a or nil) end
		chip:Show()
	end
	for i = n + 1, #row.chips do row.chips[i]:Hide() end
end

------------------------------------------------------------------ building

local function Caption(text, justify)
	local fs = NewText(frame, justify)
	SetFieldFont(fs, nil, CAPTION_SIZE)
	fs:SetText(text)
	F.captions[#F.captions + 1] = fs
	return fs
end

local function BuildSquare()
	local square = Box(st:CreateFrame('Frame', nil, frame), { 0, 0, 0, 1 })
	square:SetSize(SQUARE, SQUARE)
	local function Layer(sublevel)
		local texture = square:CreateTexture(nil, 'ARTWORK', nil, sublevel)
		Place(texture, square, 1, 1, INNER, INNER)
		return texture
	end
	F.base = Layer(0)
	-- White to clear across, clear to black down.
	local white = Layer(1)
	white:SetColorTexture(1, 1, 1, 1)
	white:SetGradient('HORIZONTAL', CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, 0))
	local black = Layer(2)
	black:SetColorTexture(0, 0, 0, 1)
	black:SetGradient('VERTICAL', CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 0))
	F.white, F.black = white, black
	F.squareThumb = Ring(square, THUMB, THUMB)
	Draggable(square, function(fx, fy) SetHSV(S.h, fx, 1 - fy) end)
	F.square = square
end

local function BuildHue()
	local hue = Box(st:CreateFrame('Frame', nil, frame), { 0, 0, 0, 1 })
	hue:SetSize(STRIP_WIDTH, SQUARE)
	-- Six segments red to red, each a gradient between its two ends' colors,
	-- their edges rounded to whole pixels.
	F.hueSegments = {}
	for i = 0, 5 do
		local top, bottom = Round(i * INNER / 6), Round((i + 1) * INNER / 6)
		local segment = hue:CreateTexture(nil, 'ARTWORK', nil, 0)
		Place(segment, hue, 1, 1 + top, STRIP_WIDTH - 2, bottom - top)
		segment:SetColorTexture(1, 1, 1, 1)
		local tr, tg, tb = M.HSVToRGB(i / 6, 1, 1)
		local br, bg, bb = M.HSVToRGB((i + 1) / 6, 1, 1)
		segment:SetGradient('VERTICAL', CreateColor(br, bg, bb, 1), CreateColor(tr, tg, tb, 1))
		F.hueSegments[#F.hueSegments + 1] = segment
	end
	F.hueThumb = Ring(hue, BAR_WIDTH, BAR_HEIGHT)
	Draggable(hue, function(_, fy) SetHSV(fy, S.s, S.v) end)
	F.hue = hue
end

local function BuildAlpha()
	local alpha = Box(st:CreateFrame('Frame', nil, frame), { 0, 0, 0, 1 })
	alpha:SetSize(STRIP_WIDTH, SQUARE)
	ShowChecker(alpha, true, 1, 1, STRIP_WIDTH - 2, INNER, CHECKER)
	F.alphaFill = alpha:CreateTexture(nil, 'ARTWORK', nil, 3)
	Place(F.alphaFill, alpha, 1, 1, STRIP_WIDTH - 2, INNER)
	F.alphaFill:SetColorTexture(1, 1, 1, 1)
	F.alphaThumb = Ring(alpha, BAR_WIDTH, BAR_HEIGHT)
	Draggable(alpha, function(_, fy) SetOpacity(1 - fy) end)
	F.alpha = alpha
end

-- The color it opened with (left), a chevron-right, the color being chosen
-- (right): no words on the colors, which a text can't be read on.
local function BuildBlocks()
	local function Tip(block, title, line)
		block:SetScript('OnEnter', function(self)
			tipOwner = self
			W.ShowTip(self, title, { line }, 'ANCHOR_TOP')
		end)
		block:SetScript('OnLeave', function(self) W.HideTip(self) end)
		HoverStates(block) -- after the scripts above
	end
	F.was = NewSwatch(frame, BLOCK_WIDTH, BLOCK_HEIGHT)
	F.new = NewSwatch(frame, BLOCK_WIDTH, BLOCK_HEIGHT)
	F.arrow = frame:CreateTexture(nil, 'OVERLAY')
	F.arrow:SetTexture(st.icons.chevronRight)
	F.arrow:SetSize(ARROW, ARROW)
	F.was:SetScript('OnClick', function()
		if spec then SetRGBA(spec.r, spec.g, spec.b, spec.hasAlpha and spec.a or S.a) end
	end)
	Tip(F.was, 'Current', 'The color it opened with. Click to go back to it.')
	Tip(F.new, 'New', 'The color being chosen.')
end

-- The preview's area, made once and hidden; each kind's pieces are built, in a
-- holder the size of the area, the first time the kind shows (PrepareKind).
local function BuildPreview()
	F.preview = st:CreateFrame('Frame', nil, frame)
	F.preview:Hide()
	F.previewHolders, F.previewPieces, F.previewDefs = {}, {}, {}
	F.paintPreview = PaintPreview -- for tests
	st:KeepOwnColors(F.preview, PreviewOwnColors)
	st:FollowColor(F.preview, 'text', nil, PaintPreview)
end

local function Build()
	F.captions, F.edits, F.order = {}, {}, {}
	frame = st:CreateFrame('Frame', nil, UIParent)
	F.frame = frame
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(LEVEL)
	frame:EnableMouse(true)
	frame:Hide()
	st:SetTemplate(frame, 'theme', 'solid', 'panel')
	frame:SetMovable(true)
	st:KeepInScreenMargin(frame)

	local OB = st.OptionsBody
	F.title = OB and OB.Text(frame, 'brand') or NewText(frame, 'LEFT')
	F.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', PAD, -16)
	F.title:SetText('Color')

	BuildDragStrip()
	BuildSquare()
	BuildHue()
	BuildAlpha()
	BuildBlocks()
	F.shadeCaption, F.hueCaption, F.alphaCaption = Caption('Shade', 'CENTER'), Caption('Hue', 'CENTER'), Caption('Opacity', 'CENTER')
	F.recentCaption = Caption('Last used', 'LEFT')
	F.previewCaption, F.previewNote = Caption('Preview', 'LEFT'), Caption('', 'RIGHT')
	F.shadeCaption:SetPoint('TOP', F.square, 'BOTTOM', 0, -4)
	F.hueCaption:SetPoint('TOP', F.hue, 'BOTTOM', 0, -4)
	F.alphaCaption:SetPoint('TOP', F.alpha, 'BOTTOM', 0, -4)
	F.recent = { y = RECENT_Y, chips = {} }
	BuildPreview()
	st:FollowColor(frame, 'text', nil, PaintText)

	for i, entry in ipairs(BoxSpecs()) do
		local edit = NewBox(frame, entry)
		F.edits[i] = edit
	end
	F.red, F.green, F.blue, F.opacity, F.hex = unpack(F.edits)

	F.okay = W.Button(frame, 'Okay', nil)
	F.cancel = W.Button(frame, 'Cancel', nil)
	F.okay.onClick = Okay
	F.cancel.onClick = Cancel
	F.cancel:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -PAD, 16)
	F.okay:SetPoint('RIGHT', F.cancel, 'LEFT', -8, 0)

	-- Esc, only while it is shown: cancels, unless a box has the keyboard (the
	-- box's own Esc puts its text back). Other keys go on to the game. Out of
	-- combat only (SetPropagateKeyboardInput is protected in it).
	keys = CreateFrame('Frame', nil, frame)
	F.keys = keys
	keys:Hide()
	keys:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		if GetCurrentKeyBoardFocus() then
			self:SetPropagateKeyboardInput(true)
			return
		end
		local escape = key == 'ESCAPE'
		self:SetPropagateKeyboardInput(not escape)
		if escape then Cancel() end
	end)

	frame:SetScript('OnShow', function()
		keys:Show()
		keys:EnableKeyboard(true)
		if not InCombatLockdown() then keys:SetPropagateKeyboardInput(true) end
		Tell()
	end)
	frame:SetScript('OnHide', function()
		StopMove(false)
		keys:EnableKeyboard(false)
		keys:Hide()
		if tipOwner then
			W.HideTip(tipOwner)
			tipOwner = nil
		end
		Cancel() -- hidden by anything else: the opening color goes back
		Tell()
	end)
	-- A field that went away under the picker (its window closed or drew
	-- again) takes it with it.
	frame:SetScript('OnUpdate', function()
		if spec and ((spec.owner and not spec.owner:IsVisible()) or (spec.stale and spec.stale())) then Cancel() end
	end)
	frame:RegisterEvent('PLAYER_REGEN_DISABLED')
	frame:SetScript('OnEvent', function() Cancel() end)
end

------------------------------------------------------------------ layout and look

-- Where the columns sit for hasAlpha: the hue strip, the opacity strip and the
-- number column from the left, and the panel's width.
local function Columns(hasAlpha)
	local hueX = PAD + SQUARE + GAP
	local alphaX = hueX + STRIP_WIDTH + GAP
	local columnX = (hasAlpha and alphaX or hueX) + STRIP_WIDTH + GAP
	return hueX, alphaX, columnX, columnX + COLUMN + PAD
end

-- The preview kind to show, built the first time (and again when a module
-- defined the kind anew), or nil when there is none or its Build fails.
local function PrepareKind(kind, def, hasAlpha)
	if not kind then return nil end
	if F.previewDefs[kind] ~= def then
		local old = F.previewHolders[kind]
		if old then old:Hide() end
		F.previewPieces[kind], F.previewDefs[kind] = nil, def
		local holder = st:CreateFrame('Frame', nil, F.preview)
		holder:SetPoint('TOPLEFT', F.preview, 'TOPLEFT', 0, 0)
		holder:SetPoint('BOTTOMRIGHT', F.preview, 'BOTTOMRIGHT', 0, 0)
		F.previewHolders[kind] = holder
		local _, _, _, width = Columns(hasAlpha)
		local ok, pieces = xpcall(def.Build, geterrorhandler(), holder, width - 2 * PAD, W.PREVIEW.HEIGHT)
		if ok and type(pieces) == 'table' then
			F.previewPieces[kind] = pieces
		else
			holder:Hide() -- a Build that failed is not tried again until the kind is defined anew
		end
	end
	return F.previewPieces[kind] and kind or nil
end

-- The panel for hasAlpha: wider by the opacity strip and its gap with it; with a
-- preview kind (spec.kind), taller by W.PREVIEW.ROOM, the strip and its caption
-- in the room between the square and Last used.
local function Layout(hasAlpha, kind)
	local hueX, alphaX, columnX, width = Columns(hasAlpha)
	local room = kind and W.PREVIEW.ROOM or 0
	frame:SetSize(width, HEIGHT + room)
	Place(F.square, frame, PAD, BODY_Y)
	Place(F.hue, frame, hueX, BODY_Y)
	Place(F.alpha, frame, alphaX, BODY_Y)
	F.alpha:SetShown(hasAlpha)
	F.alphaCaption:SetShown(hasAlpha)
	Place(F.was, frame, columnX, BODY_Y)
	Place(F.arrow, frame, columnX + BLOCK_WIDTH + (BLOCK_GAP - ARROW) / 2, BODY_Y + (BLOCK_HEIGHT - ARROW) / 2)
	Place(F.new, frame, columnX + COLUMN - BLOCK_WIDTH, BODY_Y)
	local row = 0
	for _, edit in ipairs(F.edits) do
		local shown = hasAlpha or not edit.alpha
		edit:SetShown(shown)
		edit.label:SetShown(shown)
		if shown then
			local y = BODY_Y + ROW_FIRST + row * ROW_PITCH
			Place(edit, frame, columnX + COLUMN - BOX_WIDTH, y)
			edit.label:ClearAllPoints()
			edit.label:SetPoint('LEFT', frame, 'TOPLEFT', columnX, -(y + BOX_HEIGHT / 2))
			row = row + 1
		end
	end
	F.order = {}
	for _, edit in ipairs(F.edits) do
		if hasAlpha or not edit.alpha then F.order[#F.order + 1] = edit end
	end
	F.recentCaption:ClearAllPoints()
	F.recentCaption:SetPoint('TOPLEFT', frame, 'TOPLEFT', PAD, -(RECENT_CAPTION_Y + room))
	F.recent.y = RECENT_Y + room
	F.preview:SetShown(kind ~= nil)
	F.previewCaption:SetShown(kind ~= nil)
	for name, holder in pairs(F.previewHolders) do holder:SetShown(name == kind) end
	F.previewNote:SetText('')
	F.previewNote:Hide()
	if kind then
		local PV = W.PREVIEW
		local inner = width - 2 * PAD
		Place(F.preview, frame, PAD, PV.Y, inner, PV.HEIGHT)
		Place(F.previewCaption, frame, PAD, PV.CAPTION_Y)
		F.previewNote:ClearAllPoints()
		F.previewNote:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -PAD, -PV.CAPTION_Y)
		spec.inner = inner
		return PlaceKind(kind)
	end
end

-- The kind's note and Layout (the pieces placed, or shown or hidden for the
-- option's style: Layout(pieces, width, height, spec) with spec as Paint gets
-- it). The note is a string, or a function(blizzard, spec) -> string | nil of
-- the theme in use. An error is reported; Layout's makes the picker open with
-- no preview.
function PlaceKind(kind)
	local def, PV = spec.def, W.PREVIEW
	local blizzard = BlizzardLook() and true or false
	spec.blizzard = blizzard
	local note = def.note
	if type(note) == 'function' then
		local ok, value = xpcall(note, geterrorhandler(), blizzard, spec.paint)
		note = ok and value or nil
	end
	if type(note) ~= 'string' then note = nil end
	F.previewNote:SetText(note or '')
	F.previewNote:SetShown(note ~= nil)
	-- The note takes the room right of "Preview" and no more: a wide Text font
	-- cuts it at the end rather than running over the caption.
	F.previewNote:SetWordWrap(false)
	F.previewNote:SetWidth(math.max(1, spec.inner - math.ceil(F.previewCaption:GetStringWidth()) - 8))
	if def.Layout then
		if not xpcall(def.Layout, geterrorhandler(), F.previewPieces[kind], spec.inner, PV.HEIGHT, spec.paint) then
			return false
		end
	end
end

-- The look the theme gives the controls now, and the captions' color.
local function Look()
	local blizzard = BlizzardLook()
	for _, edit in ipairs(F.edits) do LookInput(edit, blizzard, BOX_HEIGHT) end
	W.LookControl(F.okay, blizzard)
	W.LookControl(F.cancel, blizzard)
	PaintText()
end

-- The picker beside owner's field: its top left by M.Place, on whole units.
local function PlaceBeside(owner)
	local left, right, top, bottom = owner:GetLeft(), owner:GetRight(), owner:GetTop(), owner:GetBottom()
	frame:ClearAllPoints()
	if not (left and right and top and bottom) then
		frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		return
	end
	local k = owner:GetEffectiveScale() / UIParent:GetEffectiveScale()
	local margin = { st:GetScreenMargin(frame) }
	local x, y = M.Place({ left = left * k, right = right * k, top = top * k, bottom = bottom * k },
		frame:GetWidth(), frame:GetHeight(), UIParent:GetWidth(), UIParent:GetHeight(),
		{ left = margin[1] or 0, right = margin[2] or 0, top = margin[3] or 0, bottom = margin[4] or 0 })
	frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
end

------------------------------------------------------------------ opening

function W.OpenColorPicker(owner, options)
	if InCombatLockdown() then return false end
	if not frame then Build() end
	-- Open for another field: the first is accepted, as Okay.
	if spec then Okay() end
	local hasAlpha = options.hasAlpha and true or false
	spec = {
		owner = owner, hasAlpha = hasAlpha,
		r = options.r or 0, g = options.g or 0, b = options.b or 0, a = options.a or 1,
		onChange = options.onChange, onCancel = options.onCancel, stale = options.stale,
	}
	-- The option's preview (optionspreview.lua): a kind the kit knows, else none.
	local kind, fields = W.ReadPreview(options.preview)
	if kind then
		local def = W.PreviewKinds()[kind]
		spec.kind = PrepareKind(kind, def, hasAlpha)
		if spec.kind then
			spec.def = def
			spec.paint = { fields = fields, name = options.name, hasAlpha = hasAlpha }
		end
	end
	S.r, S.g, S.b, S.a = spec.r, spec.g, spec.b, hasAlpha and spec.a or 1
	S.h, S.s, S.v = M.RGBToHSV(S.r, S.g, S.b, 0)
	if Layout(hasAlpha, spec.kind) == false then
		-- The kind's Layout errored: today's picker, no preview.
		spec.kind, spec.def, spec.paint = nil, nil, nil
		Layout(hasAlpha, nil)
	end
	Look()
	FillRecentChips()
	F.was:Paint(spec.r, spec.g, spec.b, hasAlpha and spec.a or 1)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(LEVEL)
	PlaceBeside(owner)
	-- Last before it shows, so a failure above leaves no edit on: changes now
	-- pass once a frame, and closing runs each touched group's whole pass.
	st:BeginColorEdit()
	frame:Show()
	Paint()
	return true
end
