local st = SaftUI
local W = st.OptionsWidgets

--[[
	Blizzard's minimal scroll bar on SaftUI's own frames, W.BlizzardBar
	(st.OptionsWidgets, optionswidgets.lua), for the options window's body,
	its sidebar and dialogs, and the select list.
]]

local floor, max, min = math.floor, math.max, math.min

local AtlasSize = W.AtlasSize

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
