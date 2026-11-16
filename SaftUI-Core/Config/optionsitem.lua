local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's menu item, type 'item' (st.OptionsWidgets,
	optionswidgets.lua; the option's fields are in optionsmodel.lua's
	header): a small part's one row, a Show box, its name and three dots
	that open a menu of its settings (optionsmenu.lua). The body draws its
	row (optionsbody.lua's PlaceRow, its item branch): it gives the widget
	the cell's width and draws the name, labelX in.

	  w.frame   spans the cell and takes no mouse (the row under it shows
	            the tooltip and the hover line)
	  w.box     its Show box: the 18 check box (Kit.CheckBox) at the cell's
	            left, shown when the row has a get (OM.Has: get = false
	            stops an inherited one); a click commits not its value.
	            Under Blizzard the Settings check box, drawn at the check
	            list's row size (W.CheckArtSize(22), 23 x 22, from the box's
	            top left), the box taking the mouse over the art
	  w.dots    a 16 x 24 button at the cell's right edge, Lucide's
	            ellipsis-vertical (st.icons.ellipsisVertical) at 16x16 on it,
	            Text > Muted; under the mouse the accent, or white under
	            Blizzard. A click opens the menu, or closes it when it's this
	            item's. Shown only when the option has a menu (a table):
	            w.hasMenu, which the body reads to end the label at the
	            cell's right edge instead
	  w.labelX  where the body starts the name: 26 with a box (its 18 and a
	            gap of 8), or with none when the option sets reserveBox
	            (SaftUI's field: the box's room kept empty, so its name
	            lines up with its neighbours'), else 0
	  w.value   the Show box's value (nil without one)
	A part row is an item whose option has a summary (SaftUI's field,
	optionsmodel.lua): function(info) -> text, tip. The widget then also has
	  w.summary     a font string (the window's field font, Text > Muted,
	                right-aligned) holding the text, and w.summaryHit the frame
	                over it that takes the mouse and shows the tip; the body
	                places both (optionsshare.lua's OB.PlaceSummary), hiding them
	                when there is no text, no room, or the hover line takes their
	                place. w.isPart, w.summaryText and w.summaryTip hold what the
	                last Refresh read.
	  w:RowClick(button)  a left click on the row, not on its box, dots, reset
	                icon, diff icon or line: opens the menu (the body's row frame
	                runs it from its OnMouseUp, as the summary's frame does)
	Its dots rest in Text > Normal (not Muted) while any row of its menu would
	offer its reset (OM.MenuOffers: its settings that differ from their defaults,
	or on a member page are the page's own), with a tooltip saying how many; and
	are drawn in the accent while its menu is open (Kit.MarkSlot, which the menu
	calls).
	The box and the dots are centred on the widget's frame, which the body
	makes as tall as the row.
	  w:OpenMenu()       st.OptionsWindow:OpenMenu(w): true when it opened
	  w:SetWidth(width)  the cell's (the body's PlaceRow)
	  w:ShiftBox(x)      the box x right of the cell's left: the body moves
	                     it under the own mark (markShift) with the label
	A disabled item's box and dots take no mouse.
	The dots are a slot (Kit.NewSlot, Kit.PaintSlot, below), which the font
	row (optionsfont.lua) uses too, for its link, so the two look alike.
]]

local BlizzardLook = W.BlizzardLook
local Base, builders, define = Kit.Base, Kit.builders, Kit.define
local CheckBox, LookCheckBox, SetCheck = Kit.CheckBox, Kit.LookCheckBox, Kit.SetCheck

local BOX_SIZE = 18
local BOX_ROW = 22 -- the Blizzard check box's art is drawn for a row this tall (the check list's)
local LABEL_X = 26 -- the name after the box: its 18 and 8
local DOTS_WIDTH, DOTS_HEIGHT, DOTS_ICON = 16, 24, 16

-- A slot's color: Text > Muted, or under the mouse the lighter tone of the accent
-- (white under Blizzard, as its Settings panel lights what's under the mouse). The
-- slot is the item's dots and the font row's link: one look, so they change together.
-- A slot is a glyph state frame (its icon): the tone is the helper's, hover set here.
-- At rest a part row's dots are Text > Normal while button.lit (its menu offers a
-- reset), and the accent while button.open (its menu is open).
local function SlotRest(button)
	if button and button.open then
		local r, g, b = st:StateColor('edge')
		return r, g, b
	end
	if button and button.lit then return st:Color('text', 'normal'):GetRGB() end
	return st:Color('text', 'muted'):GetRGB()
end
local function PaintSlot(button, over)
	over = over and true or false
	if button.blizzard then
		if over then button.icon:SetVertexColor(1, 1, 1) else button.icon:SetVertexColor(SlotRest(button)) end
		if st:GetState(button, 'hover') then st:SetState(button, 'hover', false) end
	else
		if st:GetState(button, 'hover') ~= over then st:SetState(button, 'hover', over) end
		if not over then button.icon:SetVertexColor(SlotRest(button)) end
	end
end

-- The slot drawn open (its menu is) or not, whatever the mouse is doing.
local function MarkSlot(button, open)
	button.open = open and true or nil
	PaintSlot(button, not button.blizzard and st:GetState(button, 'hover') and true or false)
end

-- The item's dots: its slot's look.
local function PaintDots(w, over)
	PaintSlot(w.dots, over)
end

-- A slot: a 16 x 24 button for parent holding a 16 x 16 icon (a texture path)
-- in its middle, in Text > Muted. It reads button.onClick (the click), button.tip
-- (function(button) -> title, lines, shown with W.ShowTip under the mouse)
-- and button.blizzard (the look PaintSlot reads), and does nothing while
-- button.disabled. Its scripts take (self) only: the game gives OnEnter and
-- OnLeave a second argument (motion). The caller places it and says when it
-- is disabled or shown.
local function NewSlot(parent, icon)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(DOTS_WIDTH, DOTS_HEIGHT)
	button:EnableMouse(true)
	button.icon = button:CreateTexture(nil, 'ARTWORK')
	button.icon:SetSize(DOTS_ICON, DOTS_ICON)
	button.icon:SetPoint('CENTER', button, 'CENTER', 0, 0)
	button.icon:SetTexture(icon)
	st:AddStates(button, 'glyph', { glyph = button.icon, glyphRest = SlotRest, blizzard = function(b) return b.blizzard == true end, wire = false })
	PaintSlot(button, false)
	button:SetScript('OnEnter', function(self)
		PaintSlot(self, true)
		if self.tip and not self.disabled then
			local title, lines = self.tip(self)
			if title then W.ShowTip(self, title, lines) end
		end
	end)
	button:SetScript('OnLeave', function(self)
		PaintSlot(self, false)
		if self.tip then W.HideTip(self) end
	end)
	button:SetScript('OnClick', function(self)
		if self.disabled then return end
		if self.onClick then self.onClick(self) end
	end)
	return button
end

builders.item = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(1, DOTS_HEIGHT)
	frame:EnableMouse(false)
	w.frame = frame

	local box = CheckBox(frame, BOX_SIZE)
	box:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	Kit.Track(w, box)
	box:SetScript('OnClick', function()
		if w.disabled or not (w.row and w.hasBox) then return end
		w:Commit(not w.value)
	end)
	w.box = box

	local dots = NewSlot(frame, st.icons.ellipsisVertical)
	dots:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	dots.onClick = function() w:ToggleMenu() end
	dots.tip = function() return w:DotsTip() end
	w.dots = dots

	-- A part row's summary and the frame over it that shows its tip (the body
	-- places them: OB.PlaceSummary). Made for every item, hidden on the rest.
	local OB = st.OptionsBody
	local summary = OB.Text(frame, 'field', 'RIGHT')
	summary:Hide()
	w.summary = summary
	local hit = CreateFrame('Frame', nil, frame)
	hit:SetHeight(DOTS_HEIGHT)
	hit:EnableMouse(true)
	hit:Hide()
	hit:SetScript('OnEnter', function(self)
		if w.summaryTip and not w.disabled then W.ShowTip(self, w.summaryTip, nil, 'ANCHOR_TOPLEFT') end
	end)
	hit:SetScript('OnLeave', function(self) W.HideTip(self) end)
	hit:SetScript('OnMouseUp', function(_, button) w:RowClick(button) end)
	w.summaryHit = hit

	-- A part row is lit from wherever the mouse enters it: its box, dots and summary
	-- take the mouse, so the row frame's own OnEnter doesn't fire.
	for _, part in ipairs({ box, dots, hit }) do
		part:HookScript('OnEnter', function()
			local row = frame:GetParent()
			if row and row.partRow == w then OB.RowHover(row) end
		end)
	end
end

-- The sentence a part row's dots say: how many settings in its menu offer a reset.
local function DotsTip(w)
	local count, owned, page = w.menuOffers or 0, w.menuOwned or 0, w.menuPage
	if count == 0 then return nil end
	local OB = st.OptionsBody
	local owner = page and OB.Possessive(page) or 'the page\'s'
	if owned == count then
		if count == 1 then return w.row.name, { ('1 setting here is %s own.'):format(owner) } end
		return w.row.name, { ('%d settings here are %s own.'):format(count, owner) }
	elseif owned == 0 then
		if count == 1 then return w.row.name, { '1 setting here differs from its default.' } end
		return w.row.name, { ('%d settings here differ from their defaults.'):format(count) }
	end
	return w.row.name, { ('%d settings here differ from their defaults or are %s own.'):format(count, owner) }
end

define('item', {
	-- The box's look (the window's, or Blizzard's Settings check box at the
	-- check list's row size), and under Blizzard its mouse over the art.
	Bind = function(self, ...)
		local blizzard = BlizzardLook()
		self.blizzard = blizzard
		self.dots.blizzard = blizzard
		st:RestyleStates(self.dots) -- the record's Blizzard rule reads dots.blizzard
		LookCheckBox(self.box, blizzard, BOX_ROW, 'LEFT')
		if blizzard then
			local width, height = W.CheckArtSize(BOX_ROW)
			local top = math.floor((height - BOX_SIZE) / 2)
			self.box:SetHitRectInsets(0, -(width - BOX_SIZE), -top, -(height - BOX_SIZE - top))
		end
		PaintDots(self, false)
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		self.hasBox = OM.Has(self.root, self.row, 'get')
		-- An item with no box whose option says reserveBox (SaftUI's field,
		-- read raw) keeps the box's room, so its name lines up with the
		-- names of the items with boxes beside it.
		local keepsRoom = self.hasBox or (self.row.option and self.row.option.reserveBox == true)
		self.labelX = keepsRoom and LABEL_X or 0
		self.hasMenu = type(self.row.option and self.row.option.menu) == 'table'
		self.dots:SetShown(self.hasMenu)
		self.box:SetShown(self.hasBox)
		if self.hasBox then
			self.value = self:Value() and true or false
			SetCheck(self.box, self.value, self.disabled)
		else
			self.value = nil
		end
		self:ReadPart()
	end,

	-- A part row (its option has a summary): its summary's text and tip, and how
	-- many rows of its menu offer a reset, which colors its dots. Anything else
	-- has none of them.
	ReadPart = function(self)
		local option = self.row.option
		local dots = self.dots
		self.isPart = type(option.summary) == 'function'
		self.summaryText, self.summaryTip = nil, nil
		self.menuOffers, self.menuOwned, self.menuPage = 0, 0, nil
		if self.isPart then
			local ok, text, tip = xpcall(function() return OM.Member(self.root, self.row, 'summary') end, geterrorhandler())
			if ok and type(text) == 'string' and text ~= '' then
				self.summaryText = text
				if type(tip) == 'string' and tip ~= '' then self.summaryTip = tip end
			end
			self.menuOffers, self.menuOwned, self.menuPage = OM.MenuOffers(self.root, self.row)
		end
		local lit = self.menuOffers > 0
		if (dots.lit or false) ~= lit then
			dots.lit = lit or nil
			PaintSlot(dots, not dots.blizzard and st:GetState(dots, 'hover') and true or false)
		end
	end,

	DotsTip = DotsTip,

	-- A left click on the row: its menu, but not when the mouse is on one of the
	-- row's own controls (its box, dots, reset icon, diff icon or the hover line's
	-- pieces), which take theirs.
	RowClick = function(self, button)
		if button ~= 'LeftButton' or self.disabled or not self.isPart or not self.hasMenu then return end
		local function Over(frame) return frame ~= nil and frame:IsVisible() and frame:IsMouseOver() end
		if Over(self.box) or Over(self.dots) then return end
		local row = self.frame:GetParent()
		-- Pressed on the row, let go elsewhere: nothing.
		if not (row and row:IsMouseOver()) then return end
		if Over(row.defaultReset) then return end
		local parts = row.share
		if parts and (Over(parts.diff) or Over(parts.ownText) or Over(parts.reset) or Over(parts.all) or Over(parts.multiple)) then
			return
		end
		self:OpenMenu()
	end,

	SetWidth = function(self, width)
		self.width = width
		self.frame:SetWidth(width)
	end,

	ShiftBox = function(self, x)
		self.box:ClearAllPoints()
		self.box:SetPoint('LEFT', self.frame, 'LEFT', x, 0)
	end,

	OpenMenu = function(self)
		local OW = st.OptionsWindow
		if not (OW and OW.OpenMenu) then return false end
		return OW:OpenMenu(self)
	end,

	-- The dots' click: the menu, or closed when it's this item's.
	ToggleMenu = function(self)
		if self.disabled or not self.row then return end
		local OW = st.OptionsWindow
		if OW and OW.IsMenuShown and OW:IsMenuShown(self) then
			OW:CloseMenu()
		else
			self:OpenMenu()
		end
	end,

	OnDisabled = function(self, disabled)
		self.box:EnableMouse(not disabled)
		self.dots:EnableMouse(not disabled)
		SetCheck(self.box, self.box:GetChecked(), disabled)
	end,

	OnRelease = function(self)
		self.width, self.value, self.hasBox, self.hasMenu, self.labelX = W.WIDTH.item, nil, nil, nil, nil
		self.isPart, self.summaryText, self.summaryTip, self.menuOffers, self.menuOwned, self.menuPage = nil, nil, nil, nil, nil, nil
		self.dots.lit, self.dots.open = nil, nil
		self.summary:Hide()
		self.summaryHit:Hide()
		self:ShiftBox(0)
		PaintDots(self, false)
	end,
})

Kit.NewSlot, Kit.PaintSlot, Kit.MarkSlot, Kit.DotsTip = NewSlot, PaintSlot, MarkSlot, DotsTip
