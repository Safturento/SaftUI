local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The kit's standalone controls (st.OptionsWidgets, optionswidgets.lua):
	controls that belong to no option row, for the options window's own parts
	and the edit mode bar. They take the look the rows' controls have, under
	Thick, Thin and Blizzard (optionslook.lua):
	  - W.Button, W.IconButton and W.IconLink (with W.SetCompact, W.SetOn,
	    W.SetEnabled, W.LookControl) and the tooltip they show (W.ShowTip);
	  - W.SelectFace, a dropdown's face with its caret (W.LookSelectFace);
	  - W.NumberBox, an edit box of whole numbers with a nudge pair
	    (W.LookNumberBox), and the pair itself (Kit.NudgePair and
	    Kit.LookNudges), which the Position block's X and Y boxes use too.

	A control keeps its state in fields: on (W.SetOn), disabled
	(W.SetEnabled) and onClick, which every click runs unless it is disabled.
	Never SetScript('OnClick') on a control of this file: it drops the
	disabled guard. W.IconButton and W.IconLink take no click argument; set
	control.onClick.
	A disabled control keeps the mouse, so its tooltip shows (an icon with no
	label must say why it does nothing); it is drawn at alpha 0.4, with no
	hover look. Its look is painted by one function (Paint) from those
	fields and the look it wears (kit art, optionslook.lua), so an order of
	calls can't leave it wrong.

	The scripts the controls set take (self) only: the game gives OnEnter
	and OnLeave a second argument, motion, which a function with an optional
	second parameter would take for its own.

	This file loads after optionsitem.lua and before optionsposition.lua,
	which takes the nudge pair from the kit, and before optionsbody.lua, so
	its text is Kit.NewText's (the field font), not the body's.
]]

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil

local Box, Edge, DropdownStates = W.Box, W.Edge, W.DropdownStates
local LookButton, LookDropdown = W.LookButton, W.LookDropdown
local FIELD_HEIGHT, EDGE, BG = Kit.FIELD_HEIGHT, Kit.EDGE, Kit.BG
local Colors, NewText = Kit.Colors, Kit.NewText
local arts, Art, Changes, Piece, HidePieces = Kit.arts, Kit.Art, Kit.Changes, Kit.Piece, Kit.HidePieces
local ShowBox, LookInput = Kit.ShowBox, Kit.LookInput
local Caret = Kit.Caret

local BUTTON_HEIGHT, MIN_WIDTH, PAD = 26, 80, 28
local ICON, ICON_GAP = 16, 6
local DISABLED_ALPHA = 0.4
local NUDGE_WIDTH, NUDGE_BOX, CHEVRON = 14, 22, 12

------------------------------------------------------------------ the tooltip

-- Shows a tooltip over owner: title in white, then each line in Text >
-- Normal, or Text > Red for a line given as { text = ..., red = true }
-- (design decision 8). anchor is ANCHOR_BOTTOM unless given.
function W.ShowTip(owner, title, lines, anchor)
	GameTooltip:SetOwner(owner, anchor or 'ANCHOR_BOTTOM')
	GameTooltip:ClearLines()
	GameTooltip:AddLine(title, 1, 1, 1)
	for _, line in ipairs(lines or {}) do
		local text, color = line, Colors().text.normal
		if type(line) == 'table' then
			text = line.text
			if line.red then color = Colors().text.red end
		end
		local r, g, b = color:GetRGB()
		GameTooltip:AddLine(text, r, g, b, true)
	end
	GameTooltip:Show()
end

-- Hides it, if owner owns it.
function W.HideTip(owner)
	if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

-- The control's own tooltip: its tip(control) -> title, lines.
local function ShowOwnTip(control)
	if control.tip then
		local title, lines = control.tip(control)
		W.ShowTip(control, title, lines)
	end
end

------------------------------------------------------------------ state and look

-- Whether control wears Blizzard's art now (the look put on last).
local function Blizzard(control)
	return (arts[control] and arts[control].blizzard) or false
end

-- Paints control from its state: alpha; under Thick and Thin the edge (accent
-- when on, or under the mouse while enabled); the icon (accent when on, or
-- for a link, or a button with hoverIcon, under the mouse while enabled, else
-- grey); under Blizzard a text
-- button's label (accent when on).
local function Paint(control)
	local blizzard = Blizzard(control)
	local on, disabled, hovered = control.on, control.disabled, control.hovered and not control.disabled
	control:SetAlpha(disabled and DISABLED_ALPHA or 1)
	if control.boxed and not blizzard then
		Edge(control, on or hovered)
	end
	if control.icon then
		local lit = on or ((control.link or control.hoverIcon) and hovered)
		local color = lit and st:Color('accent') or Colors().text.grey
		control.icon:SetVertexColor(color:GetRGB())
	end
	-- A label's colour is written only to light it (a button with no icon
	-- showing) and to take the light off, putting back what it was: a caller's
	-- own colour and the font object's survive.
	if control.label then
		local textOnly = not (control.icon and (control.compact or control.iconWithLabel))
		local lit = (blizzard and on and textOnly) and true or false
		if lit then
			if not control.labelLit then control.labelWas = { control.text:GetTextColor() } end
			control.text:SetTextColor(st:Color('accent'):GetRGB())
		elseif control.labelLit then
			control.text:SetTextColor(unpack(control.labelWas))
		end
		control.labelLit = lit
	end
end

-- The scripts every control shares: hover, its tooltip, and the click.
local function Wire(control)
	control:EnableMouse(true)
	control:SetScript('OnEnter', function(self)
		self.hovered = true
		Paint(self)
		ShowOwnTip(self)
	end)
	control:SetScript('OnLeave', function(self)
		self.hovered = false
		Paint(self)
		W.HideTip(self)
	end)
	control:SetScript('OnClick', function(self)
		if self.disabled then return end
		if self.onClick then self.onClick(self) end
	end)
	control:HookScript('OnHide', function(self)
		self.hovered = false
		Paint(self)
	end)
end

-- Sets control.on: lit while on. See Paint.
function W.SetOn(control, on)
	control.on = on and true or false
	Paint(control)
end

-- Sets control.disabled, and what follows from it: alpha 0.4, no hover look,
-- a click that runs nothing. The control keeps the mouse, so its tooltip
-- shows. A number box's edit box also drops focus and takes no text.
function W.SetEnabled(control, enabled)
	control.disabled = not enabled
	if control.edit then
		if control.disabled then control.edit:ClearFocus() end
	end
	Paint(control)
	Kit.PaintFace(control) -- a Blizzard dropdown face shows disabled at once; nothing for any other control
end

-- Puts on the look of a W.Button or W.IconButton, when it changed: Box in the
-- window's fill, or Blizzard's panel button (W.LookButton); then its on and
-- disabled again, which the look's change undid. An icon is drawn in
-- OVERLAY, over the panel art. A link has no box and no art.
function W.LookControl(control, blizzard)
	if control.boxed then LookButton(control, blizzard, BG) end
	Paint(control)
end

------------------------------------------------------------------ buttons

local function NewIcon(button, path, size)
	local icon = button:CreateTexture(nil, 'OVERLAY')
	icon:SetTexture(path)
	icon:SetSize(size or ICON, size or ICON)
	icon:SetVertexColor(Colors().text.grey:GetRGB())
	return icon
end

-- The label's width, whole pixels up (as the window's buttons always sized it).
local function LabelWidth(button)
	return ceil(button.text:GetStringWidth())
end

-- Places the label for the mode, 1 lower while pressed; the size is Layout's
-- alone, so a press never resizes a button a caller sized (the sidebar's).
local function PlaceLabel(button, pressed)
	local text, icon = button.text, button.icon
	local y = pressed and -1 or 0
	if button.compact and icon then return end
	text:ClearAllPoints()
	if icon and button.iconWithLabel then
		text:SetPoint('LEFT', icon, 'RIGHT', ICON_GAP, y)
	else
		text:SetPoint('CENTER', button, 'CENTER', 0, y)
	end
end

-- Lays out button for its mode: the label alone, the icon before the label
-- (iconWithLabel), or the icon alone (compact). Returns its width.
local function Layout(button)
	local text, icon = button.text, button.icon
	local width
	if button.compact and icon then
		width = BUTTON_HEIGHT
		text:Hide()
		icon:ClearAllPoints()
		icon:SetPoint('CENTER', button, 'CENTER', 0, 0)
		icon:Show()
	elseif icon and button.iconWithLabel then
		local label = LabelWidth(button)
		width = max(MIN_WIDTH, ICON + ICON_GAP + label + PAD)
		local left = floor((width - (ICON + ICON_GAP + label)) / 2)
		icon:ClearAllPoints()
		icon:SetPoint('LEFT', button, 'LEFT', left, 0)
		icon:Show()
		text:Show()
		text:SetJustifyH('LEFT')
	else
		width = max(MIN_WIDTH, LabelWidth(button) + PAD)
		if icon then icon:Hide() end
		text:Show()
		text:SetJustifyH('CENTER')
	end
	PlaceLabel(button, false)
	button:SetSize(width, BUTTON_HEIGHT)
	return width
end

-- A button: the window's fill, a 1px border (accent under the mouse, or when
-- on) and the dark line outside it; under Blizzard Blizzard's panel button
-- (W.LookControl). 26 tall, 80 wide at least, its label in the field font,
-- centred, 1 lower while pressed. onClick runs on a click (button.onClick).
-- opts, optional: icon, a texture path, drawn 16 before the label (6 apart,
-- the pair centred) when iconWithLabel, and alone while the button is compact
-- (W.SetCompact); tip, function(button) -> title, lines, shown on the mouse.
function W.Button(parent, label, onClick, opts)
	opts = opts or {}
	local button = Box(st:CreateFrame('Button', nil, parent), BG)
	button.boxed, button.label, button.onClick, button.tip = true, label, onClick, opts.tip
	button.iconWithLabel = opts.iconWithLabel and true or false
	button.text = NewText(button, 'CENTER')
	button.text:SetWordWrap(false)
	button.text:SetText(label)
	if opts.icon then button.icon = NewIcon(button, opts.icon) end
	Wire(button)
	button:HookScript('OnMouseDown', function(self)
		if not self.disabled then PlaceLabel(self, true) end
	end)
	button:HookScript('OnMouseUp', function(self) PlaceLabel(self, false) end)
	Layout(button)
	Paint(button)
	return button
end

-- A square button with only its icon, in Text > Grey: 26 square with a 16
-- icon in the middle (its edges at 5 and 21), or size square with an iconSize
-- icon (the window's header arrows: 24 and 20). Both are whole numbers and
-- (size - iconSize) / 2 is whole, so the icon's edges are. The icon sits 1
-- lower while the button is pressed (never the size). Set button.onClick for
-- what a click does. tip, function(button) -> title, lines, is required: an
-- icon says nothing.
function W.IconButton(parent, icon, tip, size, iconSize, extra)
	if not tip then error('W.IconButton needs its tooltip') end
	if extra ~= nil or type(tip) ~= 'function' or (size ~= nil and type(size) ~= 'number') or (iconSize ~= nil and type(iconSize) ~= 'number') then
		error('W.IconButton(parent, icon, tip, size, iconSize) takes no click: set button.onClick')
	end
	size, iconSize = size or BUTTON_HEIGHT, iconSize or ICON
	if size ~= floor(size) or iconSize ~= floor(iconSize) or (size - iconSize) % 2 ~= 0 or iconSize > size then
		error('W.IconButton: (size - iconSize) / 2 must be whole, so the icon sits on whole pixels')
	end
	local button = Box(st:CreateFrame('Button', nil, parent), BG)
	button.boxed, button.tip = true, tip
	button:SetSize(size, size)
	button.icon = NewIcon(button, icon, iconSize)
	button.icon:SetPoint('CENTER', button, 'CENTER', 0, 0)
	Wire(button)
	button:HookScript('OnMouseDown', function(self)
		if not self.disabled then self.icon:SetPoint('CENTER', self, 'CENTER', 0, -1) end
	end)
	button:HookScript('OnMouseUp', function(self) self.icon:SetPoint('CENTER', self, 'CENTER', 0, 0) end)
	Paint(button)
	return button
end

-- An icon with no box, on a frame size square that takes the mouse: Text >
-- Grey at rest and accent under the mouse. tip is required. Set
-- link.onClick for what a click does.
function W.IconLink(parent, icon, size, tip, extra)
	if not tip then error('W.IconLink needs its tooltip') end
	if extra ~= nil or type(tip) ~= 'function' then
		error('W.IconLink(parent, icon, size, tip) takes no click: set link.onClick')
	end
	local link = st:CreateFrame('Button', nil, parent)
	link.link, link.tip = true, tip
	link:SetSize(size, size)
	link.icon = link:CreateTexture(nil, 'OVERLAY')
	link.icon:SetTexture(icon)
	link.icon:SetAllPoints(link)
	link.icon:SetVertexColor(Colors().text.grey:GetRGB())
	Wire(link)
	Paint(link)
	return link
end

-- A W.Button with an icon shows only the icon, 26 square, while compact (it
-- needs opts.tip), and its label otherwise. Returns its width.
function W.SetCompact(button, compact)
	compact = compact and true or false
	if compact and button.icon and not button.tip then
		error("W.SetCompact needs the button's tooltip")
	end
	button.compact = compact
	return Layout(button)
end

------------------------------------------------------------------ the select face

-- A FIELD_HEIGHT tall dropdown face of width: Box, button.text 8 in from the
-- left and 22 from the right, and Kit.Caret at the right; its edge lights
-- under the mouse. onClick(face) opens whatever it opens. Hiding it closes a
-- list it owns. Under Blizzard W.LookSelectFace puts the Settings dropdown on.
function W.SelectFace(parent, width, onClick)
	local face = Box(st:CreateFrame('Button', nil, parent))
	face.boxed, face.onClick = true, onClick
	face:SetSize(width, FIELD_HEIGHT)
	face.text = NewText(face, 'LEFT')
	face.text:SetWordWrap(false)
	face.text:SetPoint('LEFT', face, 'LEFT', 8, 0)
	face.text:SetPoint('RIGHT', face, 'RIGHT', -22, 0)
	face.caret = Caret(face)
	Wire(face)
	face:HookScript('OnHide', function(self)
		if W.ListOwner() == self then W.CloseList() end
	end)
	DropdownStates(face, function() return face.disabled end)
	Paint(face)
	return face
end

function W.LookSelectFace(face, blizzard)
	LookDropdown(face, blizzard, false)
	Paint(face)
end

------------------------------------------------------------------ the nudge pair

-- A nudge's stepper art under Blizzard, in its state: pressed, under the
-- mouse, else normal.
local function PaintNudge(button)
	local art = arts[button]
	if not (art and art.blizzard) then return end
	local state = art.down and 'pressed' or art.over and 'hover' or 'normal'
	art.pieces.Arrow:SetAtlas(art.arrows[state])
end

-- One half of the nudge pair: a 14x11 button (a clickable region of the
-- pair's box) with its chevron, button.arrow: Lucide's, 12x12, Text > Grey
-- and Text > Normal under the mouse while enabled. Both halves' arrows sit 1
-- above their half's top (a middle 5 down it), whole pixels: 5.5 from the
-- divider's middle either side. owner.disabled stops it, and owner:Tip(on) shows
-- and hides the owner's tooltip.
local function NudgeButton(owner, parent, up, onClick)
	local button = st:CreateFrame('Button', nil, parent)
	button:SetSize(NUDGE_WIDTH, NUDGE_BOX / 2)
	local arrow = button:CreateTexture(nil, 'OVERLAY')
	arrow:SetTexture(up and st.icons.chevronUp or st.icons.chevronDown)
	arrow:SetSize(CHEVRON, CHEVRON)
	arrow:SetPoint('TOP', button, 'TOP', 0, 1)
	arrow:SetVertexColor(Colors().text.grey:GetRGB())
	button.arrow = arrow
	button:SetScript('OnClick', function()
		if owner.disabled then return end
		onClick()
	end)
	button:SetScript('OnEnter', function(self)
		if not owner.disabled then self.arrow:SetVertexColor(Colors().text.normal:GetRGB()) end
		owner:Tip(true)
	end)
	button:SetScript('OnLeave', function(self)
		self.arrow:SetVertexColor(Colors().text.grey:GetRGB())
		owner:Tip(false)
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
-- the two buttons over its halves. Returns pair, up, down.
function Kit.NudgePair(owner, parent, onUp, onDown)
	local pair = Box(st:CreateFrame('Frame', nil, parent))
	pair:SetSize(NUDGE_WIDTH, NUDGE_BOX)
	local divider = pair:CreateTexture(nil, 'ARTWORK')
	divider:SetColorTexture(unpack(EDGE))
	divider:SetSize(NUDGE_WIDTH - 2, 1)
	divider:SetPoint('TOPLEFT', pair, 'TOPLEFT', 1, -(NUDGE_BOX / 2 - 1))
	local up = NudgeButton(owner, pair, true, onUp)
	up:SetPoint('TOPLEFT', pair, 'TOPLEFT', 0, 0)
	local down = NudgeButton(owner, pair, false, onDown)
	down:SetPoint('BOTTOMLEFT', pair, 'BOTTOMLEFT', 0, 0)
	pair.divider, pair.up, pair.down = divider, up, down
	return pair, up, down
end

-- The pairs' look, when it changed: their box, divider and chevrons, or
-- MinimalScrollBar's steppers (st.ThemeArt.Control('nudge')), each filling
-- its half of the pair.
function Kit.LookNudges(pairs_, blizzard)
	local look
	for _, pair in ipairs(pairs_) do
		if Changes(Art(pair), blizzard) then
			ShowBox(pair, not blizzard)
			pair.divider:SetShown(not blizzard)
			look = look or (blizzard and st.ThemeArt.Control('nudge'))
			for _, button in ipairs({ pair.up, pair.down }) do
				local art = Art(button)
				art.blizzard = blizzard
				button.arrow:SetShown(not blizzard)
				if blizzard then
					local piece = Piece(art, button, 'Arrow', 'ARTWORK')
					piece:ClearAllPoints()
					piece:SetAllPoints(button)
					art.arrows = button == pair.up and look.up or look.down
					PaintNudge(button)
				else
					HidePieces(art)
				end
			end
		end
	end
end

------------------------------------------------------------------ the number box

-- A box of whole numbers: an edit box with centred text in the field font
-- and a nudge pair over its right edge by 1, width wide in all.
-- opts = { width = 54, min, max, step, get = function() -> number,
-- set = function(number), tip = function(box) -> title, lines }.
-- Enter commits the number rounded to a whole one and clamped, and drops
-- focus; text that is not a number puts the old value back, and so do Esc
-- and losing focus. The arrows set(clamp(get() +/- step)).
function W.NumberBox(parent, opts)
	local width = opts.width or 54
	local step = opts.step or 1
	local box = st:CreateFrame('Frame', nil, parent)
	box:SetSize(width, NUDGE_BOX)
	box.tip = opts.tip

	local function Clamp(n)
		if opts.min then n = max(opts.min, n) end
		if opts.max then n = min(opts.max, n) end
		return n
	end

	local edit = Box(st:CreateFrame('EditBox', nil, box))
	edit:SetSize(width - NUDGE_WIDTH + 1, NUDGE_BOX)
	edit:SetPoint('TOPLEFT', box, 'TOPLEFT', 0, 0)
	edit:SetFontObject(W.GetFont())
	edit:SetJustifyH('CENTER')
	edit:SetTextInsets(2, 2, 0, 0)
	edit:SetAutoFocus(false)
	box.edit = edit

	function box:Refresh()
		edit:SetText(tostring(tonumber(opts.get()) or 0))
	end
	function box:Tip(on)
		if on then ShowOwnTip(self) else W.HideTip(self) end
	end

	edit:SetScript('OnEnter', function(self)
		if not (box.disabled or self:HasFocus()) then Edge(self, true) end
		box:Tip(true)
	end)
	edit:SetScript('OnLeave', function(self)
		if not self:HasFocus() then Edge(self, false) end
		box:Tip(false)
	end)
	edit:SetScript('OnEnterPressed', function(self)
		if box.disabled then return end
		local n = tonumber(strtrim(self:GetText()))
		if n and n == n and n ~= math.huge and n ~= -math.huge then
			opts.set(Clamp(floor(n + 0.5)))
		end
		box:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEscapePressed', function(self)
		box:Refresh()
		self:ClearFocus()
	end)
	edit:SetScript('OnEditFocusGained', function(self)
		if box.disabled then return self:ClearFocus() end
		Edge(self, true)
	end)
	edit:SetScript('OnEditFocusLost', function(self)
		Edge(self, false)
		box:Refresh()
	end)

	local function Nudge(direction)
		return function() opts.set(Clamp((tonumber(opts.get()) or 0) + direction * step)) end
	end
	local pair = Kit.NudgePair(box, box, Nudge(1), Nudge(-1))
	pair:SetPoint('TOPLEFT', edit, 'TOPRIGHT', -1, 0)
	box.pair = pair

	box:Refresh()
	return box
end

-- The look of a number box, when it changed: its edit box Box or the input
-- art, and its nudges' look.
function W.LookNumberBox(box, blizzard)
	LookInput(box.edit, blizzard, NUDGE_BOX)
	Kit.LookNudges({ box.pair }, blizzard)
end
