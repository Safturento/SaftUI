local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's Position block, type 'position' (st.OptionsWidgets,
	optionswidgets.lua). The last of the type files in Config/load.xml, so
	it ends by noting the built-in types (below).
]]

local floor = math.floor

local Box, Edge, BlizzardLook, DropdownStates = W.Box, W.Edge, W.BlizzardLook, W.DropdownStates
local LookDropdown = W.LookDropdown
local Base, builders, define, BUILT_IN = Kit.Base, Kit.builders, Kit.define, Kit.BUILT_IN
local SetFieldFont, NewText = Kit.SetFieldFont, Kit.NewText
local LookInput, LookLine, PaintFace = Kit.LookInput, Kit.LookLine, Kit.PaintFace
local Caret, ListEntries = Kit.Caret, Kit.ListEntries

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

-- The dot's look: 4x4 grey, or 8x8 in the accent when it is the picked one; the text
-- color while the mouse is on it.
local function PaintDot(dot)
	local r, g, b
	if dot.hovered then
		r, g, b = st:Color('text', 'normal'):GetRGB()
	elseif dot.picked then
		r, g, b = st:Color('accent'):GetRGB()
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
		local pair, up, down = Kit.NudgePair(w, frame, function() w:Nudge(part, 1) end, function() w:Nudge(part, -1) end)
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
		Kit.LookNudges(self.nudgePairs, blizzard)
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
			fs:SetTextColor(st:Color('text', 'muted'):GetRGB())
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
			axis[1]:SetTextColor(st:Color('text', 'normal'):GetRGB())
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
		W.OpenList(self.select, ListEntries(self.root, self.row), self:Value('relative_to'), function(key) self:Commit('relative_to', key) end)
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

------------------------------------------------------------------ the built-in types

-- This is the last type file in Config/load.xml: every built-in type has its
-- builder now, so these are the types W.Define (optionswidgets.lua) can't
-- replace. A new type's file loads before this one.
for rowType in pairs(builders) do BUILT_IN[rowType] = true end
