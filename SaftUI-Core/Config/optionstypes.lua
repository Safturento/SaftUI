local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's toggle, input, color, execute and description
	widgets (st.OptionsWidgets, optionswidgets.lua): each type's builder and
	the methods define (optionswidgets.lua) copies onto its widgets.
]]

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format = string.format

local Box, Edge, HoverEdge, BlizzardLook = W.Box, W.Edge, W.HoverEdge, W.BlizzardLook
local FIELD_HEIGHT, Base, builders, define = Kit.FIELD_HEIGHT, Kit.Base, Kit.builders, Kit.define
local BG, Colors, FIELD_FONT_SIZE, SetFieldFont = Kit.BG, Kit.Colors, Kit.FIELD_FONT_SIZE, Kit.SetFieldFont
local NewText, Art, Changes, Piece, HidePieces = Kit.NewText, Kit.Art, Kit.Changes, Kit.Piece, Kit.HidePieces
local ShowBox, LookInput, CheckBox = Kit.ShowBox, Kit.LookInput, Kit.CheckBox
local LookCheckBox, SetCheck = Kit.LookCheckBox, Kit.SetCheck
local CountLines = Kit.CountLines

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

define('toggle', {
	Bind = function(self, ...)
		LookCheckBox(self.frame, BlizzardLook(), 34, 'RIGHT') -- 34: the body's row height (OB.ROW_HEIGHT, loaded after this file)
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		self.value = self:Value() and true or false
		SetCheck(self.frame, self.value, self.disabled)
	end,

	-- A disabled box takes no mouse, as every other disabled control but a
	-- multiselect: the row under it then gets the hover and shows its
	-- tooltip, which says why (optionsbody.lua). Bind sets it again for a
	-- pooled box.
	OnDisabled = function(self, disabled)
		SetCheck(self.frame, self.frame:GetChecked(), disabled)
		self.frame:EnableMouse(not disabled)
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

--[[
	A color is a field as wide and as tall as a dropdown (W.WIDTH.color is the
	select's), drawn as an input is (Box: the field's fill and edge): a swatch
	at its left, SWATCH_WIDTH wide and the field's inner height (a black line
	round the color, the mockup's), the field's edge as a 1px line after it,
	then the code in the field font and the normal text color, CODE_GAP after
	that line (the field's usual text inset), left-aligned. The code is
	ordinary field text, the same color on every color. A see-through color
	(an opacity under 100%) is drawn over a checker of two greys, so its
	opacity shows; a solid one over none.
	Under Blizzard the field is the Settings dropdown's face (outset round it,
	following the mouse and the disabled state as a select's, with no hover
	arrow: no list opens), as it opens the picker as a dropdown opens its list,
	and an input's art would ask to be typed in. The swatch inside it is
	Blizzard's (ColorSwatchTemplate, st.ThemeArt.Control('swatch'): a white
	square, a black one a pixel in, the color a pixel in again, in the
	template's own white and black), BLIZZARD_INSET in from the face's edge,
	clear of its border and round corners; the white square parts it from the
	code, so there's no line.
]]
local SWATCH_WIDTH = 40
local CODE_GAP = 8 -- the code after the swatch's line (Blizzard: its white square)
local EDGE_WIDTH = 1 -- Box's edge, which the swatch sits inside under Thick and Thin
local BLIZZARD_INSET = 3 -- the swatch in from the Blizzard face's edge
local CHECKER = 4 -- a checker square
-- The checker's greys (the mockup's #5a5a5a and #8a8a8a).
local CHECKER_DARK, CHECKER_LIGHT = { 0.353, 0.353, 0.353, 1 }, { 0.541, 0.541, 0.541, 1 }

-- region at x, y in from button's top left, width x height, on whole pixels.
local function Place(region, button, x, y, width, height)
	region:ClearAllPoints()
	region:SetPoint('TOPLEFT', button, 'TOPLEFT', x, -y)
	region:SetSize(width, height)
end

-- The swatch and the code where the look puts them: the swatch's black line
-- at x, y, width x height, the color (and the checker, w.area) a pixel in
-- from it, the code codeX in to CODE_GAP from the field's right.
local function PlaceSwatch(w, x, y, width, height, codeX)
	local button = w.frame
	Place(w.inner, button, x, y, width, height)
	w.area = { x = x + 1, y = y + 1, width = width - 2, height = height - 2 }
	Place(w.swatch, button, w.area.x, w.area.y, w.area.width, w.area.height)
	w.text:ClearAllPoints()
	w.text:SetPoint('LEFT', button, 'LEFT', codeX, 0)
	w.text:SetPoint('RIGHT', button, 'RIGHT', -CODE_GAP, 0)
end

-- The swatch's parts for a look (see the top): under Thick and Thin inside
-- Box's edge, the edge's line after it; under Blizzard the white square
-- BLIZZARD_INSET in from the face, the black one and the color inside it.
local function PlaceParts(w, blizzard)
	local button = w.frame
	w.white:SetShown(blizzard)
	w.line:SetShown(not blizzard)
	if blizzard then
		local swatch = st.ThemeArt.Control('swatch')
		local height = FIELD_HEIGHT - 2 * BLIZZARD_INSET
		w.white:SetColorTexture(unpack(swatch.whiteColor))
		Place(w.white, button, BLIZZARD_INSET, BLIZZARD_INSET, SWATCH_WIDTH, height)
		w.inner:SetColorTexture(unpack(swatch.blackColor))
		PlaceSwatch(w, BLIZZARD_INSET + 1, BLIZZARD_INSET + 1, SWATCH_WIDTH - 2, height - 2,
			BLIZZARD_INSET + SWATCH_WIDTH + CODE_GAP)
	else
		local height = FIELD_HEIGHT - 2 * EDGE_WIDTH
		w.inner:SetColorTexture(0, 0, 0, 1)
		Place(w.line, button, EDGE_WIDTH + SWATCH_WIDTH, EDGE_WIDTH, 1, height)
		PlaceSwatch(w, EDGE_WIDTH, EDGE_WIDTH, SWATCH_WIDTH, height, EDGE_WIDTH + SWATCH_WIDTH + 1 + CODE_GAP)
	end
end

-- The field's look, when it changed: Box and the swatch inside its edge; or
-- the Settings dropdown's face round it (its art outset as a select's) and
-- Blizzard's swatch inside it.
local function LookColor(w, blizzard)
	local button = w.frame
	local art = Art(button)
	if not Changes(art, blizzard) then return end
	ShowBox(button, not blizzard)
	if blizzard then
		local look = st.ThemeArt.Control('dropdown')
		art.look = look
		local face = Piece(art, button, 'Face', 'BACKGROUND')
		face:ClearAllPoints()
		face:SetPoint('TOPLEFT', button, 'TOPLEFT', -look.outset, look.outset)
		face:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', look.outset, -look.outset)
	else
		HidePieces(art)
	end
	PlaceParts(w, blizzard)
	Kit.PaintFace(button)
end

builders.color = function(w)
	local button = Box(st:CreateFrame('Button', nil, UIParent))
	button:SetSize(W.WIDTH.color, FIELD_HEIGHT)
	w.frame = button
	-- Under Blizzard, the swatch's white square (PlaceParts shows it).
	w.white = button:CreateTexture(nil, 'BORDER')
	w.white:Hide()
	-- The swatch's black line, then the checker (a dark grey and the light
	-- squares on it, made as a see-through color first needs them: w.checker),
	-- then the color; the code (OVERLAY) over them all.
	w.inner = button:CreateTexture(nil, 'ARTWORK')
	w.checkerBack = button:CreateTexture(nil, 'ARTWORK', nil, 1)
	w.checkerBack:SetColorTexture(unpack(CHECKER_DARK))
	w.checkerBack.checker = true
	w.checkerBack:Hide()
	w.checker = {}
	w.swatch = button:CreateTexture(nil, 'ARTWORK', nil, 3)
	-- The field's edge as a line between the swatch and the code.
	w.line = button:CreateTexture(nil, 'ARTWORK')
	w.line:SetColorTexture(unpack(Kit.EDGE))
	w.text = NewText(button, 'LEFT')
	w.text:SetWordWrap(false)
	HoverEdge(button, function() return w.disabled end)
	-- Under Blizzard the face follows the mouse as a select's does.
	W.DropdownStates(button, function() return w.disabled end)
	button:SetScript('OnClick', function() w:Pick() end)
	-- Box's look until the first look change (LookColor).
	PlaceParts(w, false)
end

-- The checker under a see-through color (shown), else none: the dark grey
-- across the color's area (w.area) and a light square every other CHECKER
-- from its top left, the last column and row cut at its edges.
local function ShowChecker(w, shown)
	local area, n = w.area, 0
	w.checkerBack:SetShown(shown)
	if shown then
		Place(w.checkerBack, w.frame, area.x, area.y, area.width, area.height)
		for row = 0, ceil(area.height / CHECKER) - 1 do
			for col = 0, ceil(area.width / CHECKER) - 1 do
				if (row + col) % 2 == 0 then
					n = n + 1
					local square = w.checker[n]
					if not square then
						square = w.frame:CreateTexture(nil, 'ARTWORK', nil, 2)
						square:SetColorTexture(unpack(CHECKER_LIGHT))
						square.checker = true
						w.checker[n] = square
					end
					local x, y = col * CHECKER, row * CHECKER
					Place(square, w.frame, area.x + x, area.y + y,
						min(CHECKER, area.width - x), min(CHECKER, area.height - y))
					square:Show()
				end
			end
		end
	end
	for i = n + 1, #w.checker do w.checker[i]:Hide() end
end

-- An opacity's whole percent (100 without hasAlpha), as the code writes it.
local function Percent(a, hasAlpha)
	return hasAlpha and floor(a * 100 + 0.5) or 100
end

-- '#RRGGBB' in capitals, each channel rounded to a whole 0-255; with an
-- opacity under 100% (hasAlpha only) '#RRGGBB · 60%', whole percent.
local function HexText(r, g, b, a, hasAlpha)
	local function byte(v) return max(0, min(255, floor(v * 255 + 0.5))) end
	local text = format('#%02X%02X%02X', byte(r), byte(g), byte(b))
	local percent = Percent(a, hasAlpha)
	if percent < 100 then text = text .. ' \194\183 ' .. percent .. '%' end
	return text
end
W.HexText = HexText -- a color's code as its field writes it: a setting's reset names its default with it (optionsshare.lua)

define('color', {
	Bind = function(self, ...)
		LookColor(self, BlizzardLook())
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		local r, g, b, a = self:Value()
		self.r, self.g, self.b, self.a = r or 0, g or 0, b or 0, a or 1
		self.hasAlpha = OM.Member(self.root, self.row, 'hasAlpha') and true or false
		local shown = self.hasAlpha and self.a or 1
		self.swatch:SetColorTexture(self.r, self.g, self.b, shown)
		ShowChecker(self, Percent(self.a, self.hasAlpha) < 100)
		self.text:SetText(HexText(self.r, self.g, self.b, self.a, self.hasAlpha))
		self.text:SetTextColor(Colors().text.normal:GetRGB())
	end,

	-- Opens SaftUI's picker (optionscolorpicker.lua) on the current color. Each
	-- change it makes is set; Cancel puts the color it opened with back, through
	-- the same change. The picker never calls onChange as it opens, and a field
	-- that changed row under it (the window drew another page) ignores it.
	Pick = function(self)
		if self.disabled or not self.row then return end
		local root, row = self.root, self.row
		local hasAlpha = self.hasAlpha
		W.OpenColorPicker(self.frame, {
			r = self.r, g = self.g, b = self.b, a = self.a,
			hasAlpha = hasAlpha,
			onChange = function(nr, ng, nb, na)
				if self.root ~= root or self.row ~= row then return end
				if nr == self.r and ng == self.g and nb == self.b and (not hasAlpha or na == self.a) then return end
				self:Commit(nr, ng, nb, na)
			end,
		})
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		Kit.PaintFace(self.frame)
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
	-- The button covers the row's whole mouse area bar its empty sides (it has
	-- no label), so it shows the row's tooltip itself (w:Tip, set by the
	-- body). Hooked after HoverEdge's scripts, so the edge is unchanged.
	button:HookScript('OnEnter', function() w:Tip(true) end)
	button:HookScript('OnLeave', function() w:Tip(false) end)
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

	-- As wide as its name needs (80 at least), or as its slot when the body
	-- gave it one (SetWidth).
	Refresh = function(self)
		self.text:SetText(self.row.name or '')
		self.width = self.slotWidth or max(W.WIDTH.execute, ceil(self.text:GetStringWidth()) + 28)
		self.frame:SetWidth(self.width)
	end,

	-- width wide, whatever its name: its slot, in a floating line of buttons
	-- that share it (optionsbody.lua). Kept through a Refresh until released.
	SetWidth = function(self, width)
		self.slotWidth = width
		self:Refresh()
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

	-- The window shows the row's tooltip for the button (set by the body).
	-- A disabled button takes no mouse, so the row under it shows the tip,
	-- with the why.
	Tip = function(self, on)
		if self.onTip then self.onTip(on) end
	end,

	OnRelease = function(self)
		self.onTip, self.slotWidth = nil, nil
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
-- justifyH, SaftUI's own member: how the text sits across the row.
local JUSTIFY_H = { LEFT = true, CENTER = true, RIGHT = true }

define('description', {
	GetWidth = function(self) return self.frame:GetWidth() end,

	-- The window sizes a description to its row. The height follows the text,
	-- and the image when there is one.
	SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self:Fit()
	end,

	-- A fill row's height (the body's, optionsbody.lua: a description with
	-- fill set): the description is that tall, what it shows in the middle.
	SetHeight = function(self, height)
		self.fillHeight = height
		self:Fit()
	end,

	-- The text takes what the image and its border leave of the width. Beside
	-- an image taller than it, it sits in the image's middle, as AceGUI's label
	-- puts it. The border's width is the theme's now: a theme picked on the
	-- Theme tab reaches the row when it is drawn again. Told a taller height
	-- (SetHeight), both sit in the middle of it.
	Fit = function(self)
		local imageWidth, imageHeight, border = 0, 0, 0
		if self.image:IsShown() then
			border = st:ThemeInset('theme', 'theme', 'action')
			imageWidth = self.image:GetWidth() + 2 * border
			imageHeight = self.image:GetHeight() + 2 * border
		end
		local textLeft = imageWidth > 0 and imageWidth + IMAGE_GAP or 0
		local lineHeight = floor((self.size or FIELD_FONT_SIZE) * 1.3)
		local lines = CountLines(self.measure, self.fullText or '', self.frame:GetWidth() - textLeft - 10)
		local textHeight = lines * lineHeight
		local height = max(textHeight, imageHeight)
		local top = 0
		if self.fillHeight and self.fillHeight > height then
			top = floor((self.fillHeight - height) / 2)
			height = self.fillHeight
		end
		if imageWidth > 0 then
			self.image:ClearAllPoints()
			self.image:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', border, -(top + border))
		end
		local textTop = top + (imageHeight > textHeight and floor((imageHeight - textHeight) / 2) or 0)
		self.text:ClearAllPoints()
		self.text:SetPoint('TOPLEFT', self.frame, 'TOPLEFT', textLeft, -textTop)
		self.text:SetPoint('TOPRIGHT', self.frame, 'TOPRIGHT', 0, -textTop)
		self.text:SetHeight(textHeight)
		self.frame:SetHeight(height)
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
		local justify = OM.Member(self.root, self.row, 'justifyH')
		self.text:SetJustifyH(JUSTIFY_H[justify] and justify or 'LEFT')
		self:ShowImage()
		self:Fit()
	end,

	OnRelease = function(self)
		self.fillHeight = nil
	end,
})
