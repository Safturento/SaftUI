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

local Box, Edge, HoverStates, BlizzardLook = W.Box, W.Edge, W.HoverStates, W.BlizzardLook
local FIELD_HEIGHT, Base, builders, define = Kit.FIELD_HEIGHT, Kit.Base, Kit.builders, Kit.define
local BG, FIELD_FONT_SIZE, SetFieldFont = Kit.BG, Kit.FIELD_FONT_SIZE, Kit.SetFieldFont
local NewText, Art, Changes, Piece, HidePieces = Kit.NewText, Kit.Art, Kit.Changes, Kit.Piece, Kit.HidePieces
local ShowBox, LookInput, CheckBox = Kit.ShowBox, Kit.LookInput, Kit.CheckBox
local LookCheckBox, SetCheck = Kit.LookCheckBox, Kit.SetCheck
local CountLines = Kit.CountLines

------------------------------------------------------------------ toggle

builders.toggle = function(w)
	local box = CheckBox(UIParent, 18)
	w.frame = box
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
	HoverStates(edit)
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

	A color with a menu (SaftUI's field, read raw, as an item's: menu, a group, and
	menuTitle; the Accent's) has a slot at the field's right, Lucide's
	ellipsis-vertical (Kit.NewSlot, w.dots), Kit.FONT_SLOT_GAP after the field (4,
	8 under Blizzard) and 16 wide, so the control is 190 wide (194 under Blizzard)
	like a font row, where a color without one is 170. Its tooltip is the menu's title
	and " states" ("Accent states") and how the states are made from the Accent. A click opens the
	menu (w:OpenMenu, w:ToggleMenu: the item's, optionsmenu.lua), which
	holds the option's menu group; the slot takes no mouse while the row is disabled.
	The swatch, the code and the reset are as without a menu; the slot sits outside the
	field's own frame, at its right, and the widget places the field that much left of the
	row's right edge (w.room).

	A color with a toggle (SaftUI's field, OM.ToggleState: get, set, offText,
	desc) is one control for "use this color" and the color: a check box at the
	field's left, CHECK_SIZE square on its line, the kit's (Blizzard's art under
	Blizzard), and the swatch and code after it, TOGGLE_LEAD further in. Ticked,
	the field is as without a toggle. Unticked, the swatch and the code give
	way to offText in Text > Muted, from where the swatch began, and a click on
	the field ticks the box and opens no picker. The box takes its own click and
	shows its own tooltip, which says what unticked means.
]]
local SWATCH_WIDTH = 40
local CODE_GAP = 8 -- the code after the swatch's line (Blizzard: its white square)
local EDGE_WIDTH = 1 -- Box's edge, which the swatch sits inside under Thick and Thin
local BLIZZARD_INSET = 3 -- the swatch in from the Blizzard face's edge
local CHECKER = 4 -- a checker square
local CHECK_SIZE, CHECK_X = 18, 4 -- a toggle's box, in from the field's left
local TOGGLE_LEAD = 30 -- the swatch and code pushed right by the box (its art under Blizzard is 25 wide)
-- The checker's greys (the mockup's #5a5a5a and #8a8a8a).
local CHECKER_DARK, CHECKER_LIGHT = { 0.353, 0.353, 0.353, 1 }, { 0.541, 0.541, 0.541, 1 }
Kit.CHECKER, Kit.CHECKER_DARK, Kit.CHECKER_LIGHT = CHECKER, CHECKER_DARK, CHECKER_LIGHT -- the color picker's checker is the same

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
	local lead = w.lead or 0 -- the box's room, when the field has a toggle
	w.white:SetShown(blizzard)
	w.line:SetShown(not blizzard)
	if blizzard then
		local swatch = st.ThemeArt.Control('swatch')
		local height = FIELD_HEIGHT - 2 * BLIZZARD_INSET
		w.startX = BLIZZARD_INSET + lead
		Place(w.line, button, w.startX + SWATCH_WIDTH, EDGE_WIDTH, 1, FIELD_HEIGHT - 2 * EDGE_WIDTH) -- hidden, but kept with the rest
		w.white:SetColorTexture(unpack(swatch.whiteColor))
		Place(w.white, button, w.startX, BLIZZARD_INSET, SWATCH_WIDTH, height)
		w.inner:SetColorTexture(unpack(swatch.blackColor))
		PlaceSwatch(w, w.startX + 1, BLIZZARD_INSET + 1, SWATCH_WIDTH - 2, height - 2,
			w.startX + SWATCH_WIDTH + CODE_GAP)
	else
		local height = FIELD_HEIGHT - 2 * EDGE_WIDTH
		w.startX = EDGE_WIDTH + lead
		w.inner:SetColorTexture(0, 0, 0, 1)
		Place(w.line, button, w.startX + SWATCH_WIDTH, EDGE_WIDTH, 1, height)
		PlaceSwatch(w, w.startX, EDGE_WIDTH, SWATCH_WIDTH, height, w.startX + SWATCH_WIDTH + 1 + CODE_GAP)
	end
end

-- The field's look, when it changed: Box and the swatch inside its edge; or
-- the Settings dropdown's face round it (its art outset as a select's) and
-- Blizzard's swatch inside it.
local function LookColor(w, blizzard)
	local button = w.frame
	w.blizzardLook = blizzard
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

-- A toggle's box, made the first time a field has one: the kit's check box
-- (Blizzard's art under Blizzard) on the field, with its own click and tooltip.
local function MakeCheck(w)
	local box = CheckBox(w.frame, CHECK_SIZE)
	box:SetScript('OnClick', function()
		if w.disabled or not w.row or not w.toggle then return end
		w:CommitToggle(not w.toggle.on)
	end)
	-- What unticked means: the option's own words, else what the field shows.
	box:HookScript('OnEnter', function(self)
		local state = w.toggle
		if w.disabled or not w.row or not state then return end
		local line = state.desc or ('Unticked, the field shows ' .. state.offText .. '.')
		W.ShowTip(self, w.row.name, { line }, 'ANCHOR_TOPLEFT')
	end)
	box:HookScript('OnLeave', function(self) W.HideTip(self) end)
	Kit.Track(w, box)
	return box
end

-- The box for state (OM.ToggleState's, nil: the field has no toggle) put on
-- the field in blizzard's look: shown and ticked, or hidden.
local function LookToggle(w, state, blizzard)
	if not state then
		if w.check then
			w.check:Hide()
			w.check:EnableMouse(false)
		end
		return
	end
	if not w.check then w.check = MakeCheck(w) end
	local box = w.check
	LookCheckBox(box, blizzard, FIELD_HEIGHT, 'LEFT')
	if blizzard then
		-- The mouse over all of Blizzard's art, as an item's box has it
		-- (optionsitem.lua), so a click on its edge never reaches the field.
		local width, height = W.CheckArtSize(FIELD_HEIGHT)
		local top = floor((height - CHECK_SIZE) / 2)
		box:SetHitRectInsets(0, -(width - CHECK_SIZE), -top, -(height - CHECK_SIZE - top))
	end
	box:ClearAllPoints()
	box:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', CHECK_X, -floor((FIELD_HEIGHT - CHECK_SIZE) / 2))
	box:Show()
	box:EnableMouse(not w.disabled)
	SetCheck(box, state.on, w.disabled)
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
	-- Under Blizzard the face follows the mouse as a select's does.
	W.DropdownStates(button, function() return w.disabled end)
	-- A field with a toggle that's off ticks it, and opens no picker.
	button:SetScript('OnClick', function()
		if w.disabled then return end
		if w.toggle and not w.toggle.on then
			w:CommitToggle(true)
		else
			w:Pick()
		end
	end)
	-- Box's look until the first look change (LookColor).
	PlaceParts(w, false)
	-- the states last, after the scripts: the code's color is the field's own (Refresh); the helper
	-- keeps it and turns it dark only where the dark reads better (textKeep)
	HoverStates(button, { text = w.text, textKeep = true })
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

-- The menu's slot, made the first time a row has a menu: outside the field, at its right.
local function MakeSlot(w)
	local dots = Kit.NewSlot(w.frame, st.icons.ellipsisVertical)
	dots.onClick = function() w:ToggleMenu() end
	dots.tip = function()
		-- how many settings in the menu differ, as an item's dots say (Kit.DotsTip)
		local counted, lines = Kit.DotsTip(w)
		if counted then return counted, lines end
		local title = w.row and OM.Member(w.root, w.row, 'menuTitle')
		if type(title) ~= 'string' or title == '' then title = w.row and w.row.name or '' end
		return title .. ' states', { 'How hover, pushed, selected and disabled are made from the Accent.' }
	end
	w.dots = dots
	return dots
end

define('color', {
	Bind = function(self, root, row, onChanged)
		-- A picker open for this field's last row is over: it cancels while the
		-- field still has that row to put the opening color back on.
		W.CloseColorPicker(self.frame)
		local blizzard = BlizzardLook()
		LookColor(self, blizzard)
		-- A row with a menu has its slot (the item's: optionsitem.lua) and a control as wide as both.
		local option = type(row) == 'table' and row.option or nil
		local hasMenu = type(option) == 'table' and type(option.menu) == 'table'
		if hasMenu then
			if not self.dots then MakeSlot(self) end
			self.dots.blizzard = blizzard
			Kit.PaintSlot(self.dots, false)
			local gap = Kit.FONT_SLOT_GAP[blizzard and 'blizzard' or 'theme']
			self.dots:ClearAllPoints()
			self.dots:SetPoint('LEFT', self.frame, 'RIGHT', gap, 0)
			self.room = gap + self.dots:GetWidth()
		else
			self.room = 0
		end
		if self.dots then self.dots:SetShown(hasMenu) end
		self.width = W.WIDTH.color + self.room
		return Base.Bind(self, root, row, onChanged)
	end,

	-- The field at the row's right edge, less the slot's room.
	SetPoint = function(self, point, relative, relPoint, x, y)
		if self.room and self.room > 0 and (point == 'RIGHT' or point == 'TOPRIGHT' or point == 'BOTTOMRIGHT') then
			x = (x or 0) - self.room
		end
		self.frame:SetPoint(point, relative, relPoint, x, y)
	end,

	-- The option's menu (a group), what OW:OpenMenu draws; nil without one or while disabled.
	Menu = function(self)
		local option = self.row and self.row.option
		if self.disabled or type(option) ~= 'table' or type(option.menu) ~= 'table' then return nil end
		return option.menu
	end,

	OpenMenu = function(self)
		local OW = st.OptionsWindow
		if not (OW and OW.OpenMenu) then return false end
		return OW:OpenMenu(self)
	end,

	-- The slot's click: the menu, or closed when it's this row's.
	ToggleMenu = function(self)
		if self.disabled or not self.row then return end
		local OW = st.OptionsWindow
		if OW and OW.IsMenuShown and OW:IsMenuShown(self) then
			OW:CloseMenu()
		else
			self:OpenMenu()
		end
	end,

	Refresh = function(self)
		-- The slot's dots rest brighter while any menu row differs from its default: the item's rule
		-- and code (OM.MenuOffers), with the same tooltip.
		if self.dots and self.dots:IsShown() then
			self.menuOffers, self.menuOwned, self.menuPage = OM.MenuOffers(self.root, self.row)
			local lit = self.menuOffers > 0
			if (self.dots.lit or false) ~= lit then
				self.dots.lit = lit or nil
				Kit.PaintSlot(self.dots, not self.dots.blizzard and st:GetState(self.dots, 'hover') and true or false)
			end
		end
		local r, g, b, a = self:Value()
		self.r, self.g, self.b, self.a = r or 0, g or 0, b or 0, a or 1
		self.hasAlpha = OM.Member(self.root, self.row, 'hasAlpha') and true or false
		local state = OM.ToggleState(self.root, self.row)
		self.toggle = state
		local off = state ~= nil and not state.on
		self.lead = state and TOGGLE_LEAD or 0
		local blizzard = self.blizzardLook or false
		PlaceParts(self, blizzard)
		LookToggle(self, state, blizzard)
		local shown = self.hasAlpha and self.a or 1
		self.swatch:SetColorTexture(self.r, self.g, self.b, shown)
		self.swatch:SetShown(not off)
		self.inner:SetShown(not off)
		self.line:SetShown(not off and not blizzard)
		self.white:SetShown(not off and blizzard)
		ShowChecker(self, not off and Percent(self.a, self.hasAlpha) < 100)
		if off then
			-- The word where the swatch began.
			self.text:ClearAllPoints()
			self.text:SetPoint('LEFT', self.frame, 'LEFT', self.startX, 0)
			self.text:SetPoint('RIGHT', self.frame, 'RIGHT', -CODE_GAP, 0)
			self.text:SetText(state.offText)
			self.text:SetTextColor(st:Color('text', 'muted'):GetRGB())
		else
			self.text:SetText(HexText(self.r, self.g, self.b, self.a, self.hasAlpha))
			self.text:SetTextColor(st:Color('text', 'normal'):GetRGB())
		end
	end,

	-- The toggle's box was clicked (or the field, while it's off): sets it
	-- through the option's toggle.set and tells the window as a change does.
	-- Turning it off closes a picker open for the field first.
	CommitToggle = function(self, value)
		if self.disabled or not self.row then return end
		local root, row = self.root, self.row
		if not value then W.CloseColorPicker(self.frame) end
		local ok = OM.ToggleSet(root, row, value)
		if self.root == root and self.row == row then self:Refresh() end
		if self.onChanged then self.onChanged(ok ~= false, nil, nil, self) end
	end,

	-- The field is released (the window drew another page, closed, a menu or
	-- dialog closed): a picker open for it cancels now, while it is still bound.
	OnRelease = function(self)
		W.CloseColorPicker(self.frame)
		if self.check and GameTooltip then W.HideTip(self.check) end
		if self.dots then
			if GameTooltip then W.HideTip(self.dots) end
			self.dots.lit, self.menuOffers, self.menuOwned, self.menuPage = nil, nil, nil, nil
			Kit.PaintSlot(self.dots, false)
		end
	end,

	-- Opens SaftUI's picker (optionscolorpicker.lua) on the current color. Each
	-- change it makes is set; Cancel puts the color it opened with back, through
	-- the same change. The picker never calls onChange as it opens. Nothing is
	-- written unless the field is still on the row it opened for and the setting
	-- still holds what the field last showed: a setting that changed under the
	-- picker (a profile switch, a reset arrow) closes it, writing nothing, so
	-- an old profile's color never lands in the new one. What the old profile
	-- holds then is whatever the picker last set there (nothing hooks a switch
	-- to put its opening color back).
	Pick = function(self)
		if self.disabled or not self.row then return end
		if self.toggle and not self.toggle.on then return end -- off: no color to pick
		local root, row = self.root, self.row
		local hasAlpha = self.hasAlpha
		local function Current()
			if self.root ~= root or self.row ~= row then return false end
			local state = OM.ToggleState(root, row)
			if state and not state.on then return false end -- turned off under the picker (a reset)
			local r, g, b, a = self:Value()
			return (r or 0) == self.r and (g or 0) == self.g and (b or 0) == self.b and (not hasAlpha or (a or 1) == self.a)
		end
		W.OpenColorPicker(self.frame, {
			r = self.r, g = self.g, b = self.b, a = self.a,
			hasAlpha = hasAlpha,
			-- The option's preview (SaftUI's own field, read raw: never inherited) and the
			-- row's name, which the picker's preview kind reads (optionspreview.lua).
			preview = row.option.preview, name = row.name,
			stale = function() return not Current() end,
			onChange = function(nr, ng, nb, na)
				if not Current() then
					W.CloseColorPicker(self.frame)
					return
				end
				if nr == self.r and ng == self.g and nb == self.b and (not hasAlpha or na == self.a) then return end
				self:Commit(nr, ng, nb, na)
			end,
		})
	end,

	OnDisabled = function(self, disabled)
		self.frame:EnableMouse(not disabled)
		if self.check then
			self.check:EnableMouse(not disabled)
			SetCheck(self.check, self.check:GetChecked(), disabled)
		end
		-- the slot takes no mouse while disabled either
		if self.dots then
			self.dots.disabled = disabled
			self.dots:EnableMouse(not disabled)
		end
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
	-- The button covers the row's whole mouse area bar its empty sides (it has
	-- no label), so it shows the row's tooltip itself (w:Tip, set by the body).
	button:HookScript('OnEnter', function() w:Tip(true) end)
	button:HookScript('OnLeave', function() w:Tip(false) end)
	-- held: the label one line down (the Layer is the helper's, from its own hook)
	button:SetScript('OnMouseDown', function() w.text:SetPoint('CENTER', button, 'CENTER', 0, -1) end)
	button:SetScript('OnMouseUp', function() w.text:SetPoint('CENTER', button, 'CENTER', 0, 0) end)
	button:SetScript('OnClick', function() w:Run() end)
	HoverStates(button, { text = w.text, textKeep = true })
end

-- The execute button's look, when it changed: the window's own (Box), or
-- under Blizzard Blizzard's panel button (st:ShowPanelButton), -Disabled
-- while the widget is (the window dims it and stops its mouse; its button
-- stays enabled).
local function LookExecute(w, blizzard)
	if (w.blizzard or false) == blizzard then return end
	w.blizzard = blizzard
	local button = w.frame
	button.blizzard = blizzard -- what W.WearsBlizzard reads
	if blizzard then
		button:SetBackdrop(nil)
		button.outline:Hide()
	else
		Box(button, BG)
		button.outline:Show()
	end
	w.showsDisabled = w.showsDisabled or function() return w.disabled end
	st:ShowPanelButton(button, blizzard, nil, w.showsDisabled)
	st:RestyleStates(button)
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
			border = st:ThemeInset('theme', 'theme', 'action', self.frame)
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
		self.text:SetTextColor(st:Color('text', 'normal'):GetRGB())
		local justify = OM.Member(self.root, self.row, 'justifyH')
		self.text:SetJustifyH(JUSTIFY_H[justify] and justify or 'LEFT')
		self:ShowImage()
		self:Fit()
	end,

	OnRelease = function(self)
		self.fillHeight = nil
	end,
})
