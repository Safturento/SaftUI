local st = SaftUI

--Creates a dragable header for a frame
st.headers = {}
local closeButtons = setmetatable({}, { __mode = 'k' }) -- the buttons st:CreateCloseButton made
local closeOf = setmetatable({}, { __mode = 'k' }) -- frame -> its button (nothing is written onto the frame: it may be Blizzard's)
local closeDraws = setmetatable({}, { __mode = 'k' }) -- button -> its Draw (st:CreateCloseButton)
local windowOf = setmetatable({}, { __mode = 'k' }) -- button -> the window whose header it sits in (st:CreateHeader)
local inSocket = setmetatable({}, { __mode = 'k' }) -- button -> whether it sits in its window's metal socket
local headerOf = setmetatable({}, { __mode = 'k' }) -- window -> the header st:CreateHeader made it; only a key
local windowOfHeader = setmetatable({}, { __mode = 'k' }) -- header -> its window
local inTitleBar = setmetatable({}, { __mode = 'k' }) -- window -> whether its header sits in its metal's title bar

-- The close button st:CreateCloseButton made for frame, or nil.
function st:GetCloseButton(frame)
	return closeOf[frame]
end

-- Whether frame's close button (st:CreateCloseButton) sits in the socket of
-- the metal frame drew, rather than in its header: frame is a window
-- (st:CreateHeader made it a header) drawn in Blizzard's metal (st:DrawnKind
-- window, st:DrawnTheme blizzard), and SaftUI's theme gives close buttons
-- Blizzard's look. Under SaftUI's Thick or Thin the button stays in the header
-- whatever the window's own Theme: close buttons follow SaftUI's theme, as
-- header strips do.
function st:CloseButtonInSocket(frame)
	local button = closeOf[frame]
	return button ~= nil and inSocket[button] == true
end

-- Whether a window's close button belongs in its metal's socket now, and its
-- header in the metal's title bar.
local function WantsSocket(window)
	return st:IsBlizzardLook('theme', 'theme') and st:DrawnKind(window) == 'window'
		and st:DrawnTheme(window) == 'blizzard'
end

-- Whether frame's header (st:CreateHeader) sits in the title bar of the metal
-- frame drew, as Blizzard's own windows put their title there, rather than
-- at frame's top: when its close button would sit in the metal's socket
-- (st:CloseButtonInSocket), with or without one. Its title, the buttons its
-- window put in it and the close button are then all on the title bar, and
-- the window's content, placed under the header, starts right under it.
function st:HeaderInTitleBar(frame)
	return inTitleBar[frame] == true
end

-- How much of frame's height its header (st:CreateHeader) takes at its top:
-- the header's height, or none while it sits in the metal's title bar above
-- frame (st:HeaderInTitleBar). A window sized around its content counts this
-- rather than the header's height (the bags' SizeWindow).
function st:HeaderRoom(frame)
	local header = headerOf[frame]
	if not header or st:HeaderInTitleBar(frame) then return 0 end
	return header:GetHeight()
end

-- A header in the title bar is the bar's strip (st.ThemeArt.TitleStrip) and
-- its buttons are that less TITLE_BAR_CLEAR, so 2px of the strip shows above
-- and below them; a header in its window is the profile's Title bar height and
-- its buttons that less 8.
local TITLE_BAR_CLEAR = 4

-- How tall a button in frame's header is: the header's height less 8, or in
-- the metal's title bar (st:HeaderInTitleBar) the strip's less 4. An even
-- strip and an even clearance keep a button centred on it on whole pixels.
function st:HeaderButtonSize(frame)
	local header = headerOf[frame]
	local height = header and header:GetHeight() or st.config.profile.headers.height
	return height - (st:HeaderInTitleBar(frame) and TITLE_BAR_CLEAR or 8)
end

-- How far in from frame's right edge its close button reaches while it sits
-- in the metal's socket (st:CloseButtonInSocket): Blizzard's close button's
-- size (st.ThemeArt.Close), less how far out from the drawn frame's right
-- edge the socket puts it and how far that edge sits outside frame (the
-- inset frame was drawn at). The header's own buttons stop short of it.
function st:SocketReach(frame)
	local close = st.ThemeArt.Close()
	return close.size - close.x - (st:DrawnInset(frame) or 0)
end

-- Puts a window's header in the metal's title bar, or back at the window's
-- top, when that changed (WantsSocket), and sizes it: in the title bar the
-- strip, its bottom on the window's top and as wide as the window; in the
-- window the profile's height. Every window is drawn behind (st:SetBackdrop),
-- so its metal's title bar is above it, its bottom on the window's top
-- (theme.lua's Placement). A header whose window placed it itself (a skinned
-- Blizzard panel's) keeps its points while it stays in the window.
local function PlaceHeader(header)
	local window = windowOfHeader[header]
	local bar = window ~= nil and WantsSocket(window) == true
	if bar ~= st:HeaderInTitleBar(window) then
		header:ClearAllPoints()
		if bar then
			header:SetPoint('BOTTOMLEFT', window, 'TOPLEFT')
			header:SetPoint('BOTTOMRIGHT', window, 'TOPRIGHT')
		else
			header:SetPoint('TOPLEFT')
			header:SetPoint('TOPRIGHT')
		end
		inTitleBar[window] = bar
	end
	header:SetHeight(bar and st.ThemeArt.TitleStrip() or st.config.profile.headers.height)
end

-- Puts a close button that sits in a window's header in the metal's socket,
-- at Blizzard's spot from TOPRIGHT of the window's drawn frame
-- (st.ThemeArt.Close), or back at the header's right, when that changed. A
-- button in no header (the /sui window's, an item tooltip's) stays where its
-- caller put it.
local function PlaceCloseButton(button)
	local window = windowOf[button]
	if not window then return end
	local socket = WantsSocket(window) == true
	if socket == inSocket[button] then return end
	button:ClearAllPoints()
	if socket then
		local close = st.ThemeArt.Close()
		button:SetPoint('TOPRIGHT', st:DrawnFrame(window), 'TOPRIGHT', close.x, close.y)
	else
		button:SetPoint('RIGHT', headerOf[window], 'RIGHT', -st.CLOSE_INSET, 0)
	end
	inSocket[button] = socket
end

-- Gives frame's close button (st:CreateCloseButton) SaftUI's theme's look, and
-- on a window puts it in the metal's socket or back in the header
-- (st:CloseButtonInSocket). Every recolor and redraw does this for every close
-- button (st:KeepOwnColors), a profile switch among them. A module that draws
-- its window again with a Theme of its own (the bags' Theme) calls it after.
function st:UpdateCloseButton(frame)
	local button = closeOf[frame]
	if button then closeDraws[button](button) end
end

local headerTitles = {} -- header -> the title st:CreateHeader put on it

-- The frame can be dragged by its header, and is kept inside the screen edge
-- margin (st:KeepInScreenMargin), which waits for the end of combat on a
-- protected frame (a bag window can be one: it holds Blizzard's item buttons).
-- The header is a strip along frame's top, or under the Blizzard theme the
-- strip of the metal's title bar above it (st:HeaderInTitleBar): what frame
-- places under the header starts right under the title bar.
function st:CreateHeader(frame, title, close_button)
	frame:SetMovable(true)
	st:KeepInScreenMargin(frame)
	local frameName = frame:GetName()
	local header = st:CreateFrame('Button', frameName and frameName ..'_Header' or '', frame)
	header:SetFrameLevel(frame:GetFrameLevel()+2)
	st:SetTemplate(header, 'theme', 'theme', 'header') -- SaftUI's theme, whatever the window's

	header:SetPoint('TOPLEFT')
	header:SetPoint('TOPRIGHT')

	header:EnableMouse(true)
	header:SetScript('OnMouseDown', function() frame:StartMoving() end)
	header:SetScript('OnMouseUp', function()
		frame:StopMovingOrSizing()
-- 		frame:ClearAllPoints()
		-- We reposition the frame using a corner point to the nearest pixel to ensure pixel perfectness
-- 		print(frame:GetLeft(), frame:GetTop())
-- 		frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', frame:GetLeft(), frame:GetTop())
	end)

	if title then
		if type(title) == 'string' then
			frame.title = header:CreateFontString(nil, 'OVERLAY')
			frame.title:SetFontObject(GameFontWhiteSmall)
			frame.title:SetText(title)
		else
			frame.title = title
		end

		frame.title:SetFontObject(st:GetFont(st.config.profile.headers.font))
		frame.title:SetParent(header)
		frame.title:ClearAllPoints()
		frame.title:SetPoint('CENTER', header)
		frame.title:SetJustifyH('CENTER')
		headerTitles[header] = frame.title
	end

	headerOf[frame], windowOfHeader[header] = header, frame
	-- Every recolor and redraw (a theme switch, a profile switch) puts it in
	-- the metal's title bar or back, as the close button goes into the socket
	-- or back, close button or none. Only its place: the profile update that
	-- follows a redraw runs st:UpdateHeader, which the bags size their title
	-- bar's buttons after.
	st:KeepOwnColors(header, PlaceHeader)

	-- A button from st:CreateCloseButton is taken without being asked.
	if not close_button and closeOf[frame] then close_button = closeOf[frame] end
	if close_button then frame.close_button = close_button end
	if frame.close_button and closeButtons[frame.close_button] then
		-- SaftUI's own button already has its look; it sits in the header, or
		-- in the socket of the metal frame wears (st:CloseButtonInSocket).
		local button = frame.close_button
		button:ClearAllPoints()
		button:SetFrameLevel(header:GetFrameLevel()+4)
		button:SetPoint('RIGHT', header, 'RIGHT', -st.CLOSE_INSET, 0)
		windowOf[button], inSocket[button] = frame, false
		closeDraws[button](button)
	elseif frame.close_button then
		-- A button that isn't SaftUI's (Blizzard's) keeps the look it has always had.
		st:StripTextures(frame.close_button)
		st:SetBackdrop(frame.close_button, 'theme', 'theme', 'close')
		frame.close_button.backdrop:SetAllPoints()
		frame.close_button:ClearAllPoints()
		frame.close_button:SetFrameLevel(header:GetFrameLevel()+4)
		frame.close_button:SetPoint('TOPRIGHT', header, -st.CLOSE_INSET, 0)
		frame.close_button:SetSize(unpack(st.CLOSE_BUTTON_SIZE))
	end

	frame.header = header
	table.insert(st.headers, header)
	st:UpdateHeader(header)
	return header
end

-- Applies the profile's header height and font to a header made by
-- st:CreateHeader, and puts it in its window's metal title bar or back at the
-- window's top (st:HeaderInTitleBar; in the title bar it's the bar's strip,
-- whatever the profile's height). With no header, updates every header and
-- footer. A profile change and the General and Fonts tabs of Global Settings
-- call it, and a module that draws its window again with a Theme of its own
-- (the bags' Theme) calls it after, as it does st:UpdateCloseButton. Every
-- recolor and redraw puts each header in its place (PlaceHeader) on its own.
function st:UpdateHeader(header)
	if not header then
		for _, h in ipairs(self.headers) do
			self:UpdateHeader(h)
		end
		for _, footer in ipairs(self.footers) do
			footer:SetHeight(st.config.profile.headers.height)
		end
		return
	end

	PlaceHeader(header)
	local title = headerTitles[header]
	if title then
		title:SetFontObject(st:GetFont(st.config.profile.headers.font))
	end
end

st.footers = {}
function st:CreateFooter(frame)
	local footer = st:CreateFrame('Frame', nil, frame)
	footer:SetPoint('BOTTOMLEFT')
	footer:SetPoint('BOTTOMRIGHT')
	footer:SetHeight(st.config.profile.headers.height)
	st:SetTemplate(footer, 'theme', 'theme', 'header')
	frame.footer = footer
	table.insert(st.footers, footer)
end

-- Blizzard's close button's textures (st.ThemeArt.Close), made the first time
-- a close button takes Blizzard's look and kept as its state textures: button
-- -> { normal, pushed, highlight, disabled }. Under SaftUI's own look they
-- show nothing.
local closeArt = setmetatable({}, { __mode = 'k' })

local CLOSE_STATES = {
	{ key = 'normal', set = 'SetNormalTexture', layer = 'ARTWORK' },
	{ key = 'pushed', set = 'SetPushedTexture', layer = 'ARTWORK' },
	{ key = 'highlight', set = 'SetHighlightTexture', layer = 'HIGHLIGHT' },
	{ key = 'disabled', set = 'SetDisabledTexture', layer = 'ARTWORK' },
}

local function CloseArt(button)
	local art = closeArt[button]
	if not art then
		art = {}
		for _, state in ipairs(CLOSE_STATES) do
			local texture = button:CreateTexture(nil, state.layer)
			texture:SetAllPoints(button)
			button[state.set](button, texture)
			art[state.key] = texture
		end
		closeArt[button] = art
	end
	return art
end

-- The close button: 24x24, the field color with a 1px edge border (and a dark
-- line outside it) and a grey pixel X. Hovering turns the border and X red
-- over a faint red fill, and while pressed the X sits 1px lower. A click hides
-- frame. st:GetCloseButton(frame) finds it again (nothing is written onto frame).
--
-- Its look follows SaftUI's theme, as the close kind always has. Under
-- Blizzard it is Blizzard's red close button (UIPanelCloseButton): its four
-- textures at the client's size (st.ThemeArt.Close), with its own backdrop,
-- dark line and X hidden. Every recolor and redraw switches it
-- (st:KeepOwnColors), and on a window moves it into the metal's socket or
-- back (st:UpdateCloseButton).
function st:CreateCloseButton(frame)
	local close = st:CreateFrame('Button', nil, frame)
	closeButtons[close] = true
	close:SetPoint('TOPRIGHT', 0, 0)
	close:SetSize(unpack(self.CLOSE_X_BUTTON_SIZE))
	local backdrop = { bgFile = self.BLANK_TEX, edgeFile = self.BLANK_TEX, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } }
	close:SetBackdrop(backdrop)

	-- The dark line outside the border.
	local outline = st:CreateFrame('Frame', nil, close)
	outline:SetPoint('TOPLEFT', close, 'TOPLEFT', -1, 1)
	outline:SetPoint('BOTTOMRIGHT', close, 'BOTTOMRIGHT', 1, -1)
	outline:SetFrameLevel(max(0, close:GetFrameLevel() - 1))
	outline:SetBackdrop({ edgeFile = self.BLANK_TEX, edgeSize = 1 })
	outline:SetBackdropBorderColor(unpack(self.BOX_COLORS.alt))
	close.outline = outline

	local x = close:CreateTexture(nil, 'OVERLAY')
	x:SetTexture(self.textures.close)
	x:SetTexCoord(unpack(self.CLOSE_X_COORDS))
	x:SetSize(10, 10)
	x:SetPoint('CENTER', 0, 0)
	close.icon = x

	-- Whether it wears Blizzard's look, whose own textures show the hover and
	-- the press.
	local blizzard = false

	local function Look(hover)
		if blizzard then return end
		local colors = self.config.profile.colors
		if hover then
			close:SetBackdropColor(0.5, 0.1, 0.1, 0.4)
			close:SetBackdropBorderColor(colors.text.red:GetRGB())
			x:SetVertexColor(colors.text.red:GetRGB())
		else
			close:SetBackdropColor(unpack(self.BOX_COLORS.field))
			close:SetBackdropBorderColor(unpack(self.BOX_COLORS.edge))
			x:SetVertexColor(colors.text.grey:GetRGB())
		end
	end
	Look(false)

	close:SetScript('OnEnter', function() Look(true) end)
	close:SetScript('OnLeave', function()
		Look(false)
		x:SetPoint('CENTER', 0, 0)
	end)
	close:SetScript('OnMouseDown', function() x:SetPoint('CENTER', 0, -1) end)
	close:SetScript('OnMouseUp', function() x:SetPoint('CENTER', 0, 0) end)
	close:SetScript('OnClick', function() frame:Hide() end)

	-- Switches between its own look and Blizzard's when SaftUI's theme
	-- changed between them, then places it (PlaceCloseButton).
	local function Draw()
		local want = st:IsBlizzardLook('theme', 'theme')
		if want ~= blizzard then
			blizzard = want
			if want then
				local look = st.ThemeArt.Close()
				local art = CloseArt(close)
				for _, state in ipairs(CLOSE_STATES) do
					art[state.key]:SetAtlas(look[state.key])
				end
				art.highlight:SetBlendMode(look.highlightBlend)
				close:SetBackdrop(nil)
				outline:Hide()
				x:Hide()
				close:SetSize(look.size, look.size)
			else
				for _, texture in pairs(closeArt[close]) do texture:SetTexture(nil) end
				close:SetBackdrop(backdrop)
				outline:Show()
				x:Show()
				x:SetPoint('CENTER', 0, 0)
				close:SetSize(unpack(st.CLOSE_X_BUTTON_SIZE))
				Look(false)
			end
		end
		PlaceCloseButton(close)
	end
	closeDraws[close] = Draw
	st:KeepOwnColors(close, Draw)
	Draw()

	closeOf[frame] = close
	return close
end

local ATLAS_COORDS = {
	['left-arrow']  		= { 0.00, 0.25, 0.00, 0.50 },
	['right-arrow'] 		= { 0.25, 0.50, 0.00, 0.50 },
	['up-arrow'] 			= { 0.50, 0.75, 0.00, 0.50 },
	['down-arrow'] 			= { 0.75, 1.00, 0.00, 0.50 },
	['left-arrow-thick']  	= { 0.00, 0.25, 0.50, 1.00 },
	['right-arrow-thick'] 	= { 0.25, 0.50, 0.50, 1.00 },
	['up-arrow-thick'] 		= { 0.50, 0.75, 0.50, 1.00 },
	['down-arrow-thick'] 	= { 0.75, 1.00, 0.50, 1.00 },
}

function st:SetTexture(texture, key)
	texture:SetTexture(st.textures.atlas)
	texture:SetTexCoord(unpack(ATLAS_COORDS[key]))
end

function st:CreateArrowButton(parent, direction)
	local ARROW_SIZE = 16
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(ARROW_SIZE, ARROW_SIZE)

	local normalTexture = button:CreateTexture()
	normalTexture:SetTexture(st.textures.atlas)
	normalTexture:SetDrawLayer('OVERLAY', 0)
	normalTexture:SetAllPoints()
	st:SetTexture(normalTexture, direction..'-arrow')
	button:SetNormalTexture(normalTexture)

	local hoverTexture = button:CreateTexture()
	hoverTexture:SetTexture(st.textures.atlas)
	hoverTexture:SetBlendMode('DISABLE')
	hoverTexture:SetVertexColor(1, 0, 0, 1)
	hoverTexture:SetAllPoints()
	st:SetTexture(hoverTexture, direction..'-arrow-thick')
	button:SetHighlightTexture(hoverTexture)

	return button
end

function st:CreateArrowCluster(parent)

	local cluster = CreateFrame('Frame', nil, parent)

	local left = st:CreateArrowButton(cluster, 'left')
	left:SetPoint('LEFT')
	cluster.left = left

	local right = st:CreateArrowButton(cluster, 'right')
	right:SetPoint('RIGHT')
	cluster.right = right

	local up = st:CreateArrowButton(cluster, 'up')
	up:SetPoint('TOP')
	cluster.up = up

	local down = st:CreateArrowButton(cluster, 'down')
	down:SetPoint('BOTTOM')
	cluster.down = down

	cluster:SetSize(48, 48)

	return cluster

end

-- A backdrop anchored to a region with a secret size (e.g. some icons in combat)
-- gets a secret width, and BackdropTemplateMixin's texcoord math errors on it.
-- Skip until the size is readable; OnSizeChanged runs again when it changes.
local function SafeSetupTextureCoordinates(self)
	local width, height = self:GetSize()
	if issecretvalue(width) or issecretvalue(height) then return end
	return BackdropTemplateMixin.SetupTextureCoordinates(self)
end

function st:CreateFrame(frameType, frameName, parentFrame, templates, id)
	local templateString = "BackdropTemplate"
	if templates then templateString = templateString .. "," .. templates end
	local frame = CreateFrame(frameType, frameName, parentFrame, templateString, id)
	frame.SetupTextureCoordinates = SafeSetupTextureCoordinates
	return frame
end

function st:CreatePanel(name, width, height)
	local panel = st:CreateFrame('Frame', 'SaftUI_Panel_'..name:gsub(' ', '_'), UIParent)
	local panels = st.config.profile.panels
	st:SetBackdrop(panel, panels.theme, panels.background, 'window')
	self:CreateHeader(panel, name, self:CreateCloseButton(panel))
	if width then st:SetWidth(panel, width) end
	if height then st:SetHeight(panel, height) end

	function panel:CreateArrowButton(...)
		return st:CreateArrowButton(self, ...)
	end

	return panel
end

function st:CreateFontString(parent, font, text)
	local fontString = parent:CreateFontString(nil, 'OVERLAY')
	fontString:SetFontObject(st:GetFont(font or 'pixel'))
	if text then fontString:SetText(text) end
	return fontString
end