local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's keybinding widget (st.OptionsWidgets,
	optionswidgets.lua): a button that takes the next key pressed.
]]

local Box, Edge, HoverEdge, BlizzardLook = W.Box, W.Edge, W.HoverEdge, W.BlizzardLook
local FIELD_HEIGHT, Base, builders, define = Kit.FIELD_HEIGHT, Kit.Base, Kit.builders, Kit.define
local Colors, NewText, arts, Art, Changes = Kit.Colors, Kit.NewText, Kit.arts, Kit.Art, Kit.Changes
local Piece, HidePieces, ShowBox = Kit.Piece, Kit.HidePieces, Kit.ShowBox

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
			self.text:SetTextColor(st:Color('accent'):GetRGB())
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
