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
	            Text > Grey; under the mouse Text > Blue, or white under
	            Blizzard. A click opens the menu, or closes it when it's this
	            item's. Shown only when the option has a menu (a table):
	            w.hasMenu, which the body reads to end the label at the
	            cell's right edge instead
	  w.labelX  where the body starts the name: 26 with a box (its 18 and a
	            gap of 8), or with none when the option sets reserveBox
	            (SaftUI's field: the box's room kept empty, so its name
	            lines up with its neighbours'), else 0
	  w.value   the Show box's value (nil without one)
	The box and the dots are centred on the widget's frame, which the body
	makes as tall as the row.
	  w:OpenMenu()       st.OptionsWindow:OpenMenu(w): true when it opened
	  w:SetWidth(width)  the cell's (the body's PlaceRow)
	  w:ShiftBox(x)      the box x right of the cell's left: the body moves
	                     it under the own mark (markShift) with the label
	A disabled item's box and dots take no mouse.
]]

local BlizzardLook, HoverEdge = W.BlizzardLook, W.HoverEdge
local Base, builders, define = Kit.Base, Kit.builders, Kit.define
local Colors, CheckBox, LookCheckBox, SetCheck = Kit.Colors, Kit.CheckBox, Kit.LookCheckBox, Kit.SetCheck

local BOX_SIZE = 18
local BOX_ROW = 22 -- the Blizzard check box's art is drawn for a row this tall (the check list's)
local LABEL_X = 26 -- the name after the box: its 18 and 8
local DOTS_WIDTH, DOTS_HEIGHT, DOTS_ICON = 16, 24, 16

-- The dots' color: Text > Grey, or under the mouse Text > Blue (white under
-- Blizzard, as its Settings panel lights what's under the mouse).
local function PaintDots(w, over)
	local icon = w.dots.icon
	if not over then
		icon:SetVertexColor(Colors().text.grey:GetRGB())
	elseif w.blizzard then
		icon:SetVertexColor(1, 1, 1)
	else
		icon:SetVertexColor(Colors().text.blue:GetRGB())
	end
end

builders.item = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(1, DOTS_HEIGHT)
	frame:EnableMouse(false)
	w.frame = frame

	local box = CheckBox(frame, BOX_SIZE)
	box:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	HoverEdge(box, function() return w.disabled end)
	box:SetScript('OnClick', function()
		if w.disabled or not (w.row and w.hasBox) then return end
		w:Commit(not w.value)
	end)
	w.box = box

	local dots = CreateFrame('Button', nil, frame)
	dots:SetSize(DOTS_WIDTH, DOTS_HEIGHT)
	dots:EnableMouse(true)
	dots:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	dots.icon = dots:CreateTexture(nil, 'ARTWORK')
	dots.icon:SetSize(DOTS_ICON, DOTS_ICON)
	dots.icon:SetPoint('CENTER', dots, 'CENTER', 0, 0)
	dots.icon:SetTexture(st.icons.ellipsisVertical)
	-- Wrapped: the game passes OnEnter and OnLeave a second argument (motion).
	dots:SetScript('OnEnter', function() PaintDots(w, true) end)
	dots:SetScript('OnLeave', function() PaintDots(w, false) end)
	dots:SetScript('OnClick', function() w:ToggleMenu() end)
	w.dots = dots
end

define('item', {
	-- The box's look (the window's, or Blizzard's Settings check box at the
	-- check list's row size), and under Blizzard its mouse over the art.
	Bind = function(self, ...)
		local blizzard = BlizzardLook()
		self.blizzard = blizzard
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
		self:ShiftBox(0)
		PaintDots(self, false)
	end,
})
