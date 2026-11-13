local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's toggle, input, color, execute and description
	widgets (st.OptionsWidgets, optionswidgets.lua): each type's builder and
	the methods define (optionswidgets.lua) copies onto its widgets.
]]

local floor, max, ceil = math.floor, math.max, math.ceil

local Box, Edge, HoverEdge, BlizzardLook = W.Box, W.Edge, W.HoverEdge, W.BlizzardLook
local FIELD_HEIGHT, Base, builders, define = Kit.FIELD_HEIGHT, Kit.Base, Kit.builders, Kit.define
local BG, Colors, FIELD_FONT_SIZE, SetFieldFont = Kit.BG, Kit.Colors, Kit.FIELD_FONT_SIZE, Kit.SetFieldFont
local NewText, Art, Changes, Piece, HidePieces = Kit.NewText, Kit.Art, Kit.Changes, Kit.Piece, Kit.HidePieces
local ShowBox, Inset, LookInput, CheckBox = Kit.ShowBox, Kit.Inset, Kit.LookInput, Kit.CheckBox
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
