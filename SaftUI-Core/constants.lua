local st = SaftUI
local ADDON_NAME = ...

st.DEBUG = false
st.GAME_VERSION = select(4, GetBuildInfo())

st.name = "SaftUI"
st.forever = st.GAME_VERSION == 16001

st.my_name = select(1, UnitName('player'))
st.my_class = select(2, UnitClass('player'))
st.my_realm = GetRealmName()

st.screenWidth, st.screenHeight = GetPhysicalScreenSize()
st.scale = 768/st.screenHeight

st.CLOSE_BUTTON_SIZE = {20, 10} -- a Blizzard close button handed to st:CreateHeader
st.CLOSE_X_BUTTON_SIZE = {24, 24} -- SaftUI's own (st:CreateCloseButton)
-- Blizzard's extra action and zone ability buttons at scale 1
-- (ExtraActionButtonTemplate, ZoneAbilityFrameSpellButtonTemplate).
st.BLIZZARD_SIZE = 52
-- From this button (or icon) size up, cooldown numbers are in the larger pixel
-- font (Pixel Med, 18px by default); smaller ones get Pixel (10px), so the
-- numbers fit inside a 28px button.
st.LARGE_COUNTDOWN_SIZE = 36
-- How far in from a header's right edge SaftUI's close button sits
-- (st:CreateHeader), which the bags count in a window's least width
-- (INV:HeaderMinWidth, SaftUI-Bags/header.lua). In the metal's socket it reaches
-- st:SocketReach in instead.
st.CLOSE_INSET = 10
-- The options window's box colors, shared by its widgets and the close button.
st.BOX_COLORS = {
	field = { 0.078, 0.078, 0.078, 1 },
	edge = { 0.3, 0.3, 0.3, 1 },
	alt = { 0.1, 0.1, 0.1, 1 },
	bg = { 0.12, 0.12, 0.12, 1 },
}
-- The two strengths of an accent tint, by what it means. A hovered or selected
-- row in a list is tinted at TINT_ROW, everywhere. TINT_OBJECT is only for a
-- selected object's fill (a selected mover in the edit mode).
st.TINT_ROW = 0.25
st.TINT_OBJECT = 0.15
st.BLANK_TEX = [[Interface\BUTTONS\WHITE8X8]]
st.BACKDROP = {
	bgFile = st.BLANK_TEX, 
	edgeFile = st.BLANK_TEX,
	tile = false, tileSize = 0, edgeSize = 1, 
	insets = { left = 1, right = 1, top = 1, bottom = 1}
}
st.CLAMP_INSET = 20

local MEDIA_PATH = format('Interface\\AddOns\\%s\\Media\\', ADDON_NAME)

function st:TexturePath(fileName)
    return MEDIA_PATH .. 'Textures\\' .. fileName
end

function st:FontPath(fileName)
    return MEDIA_PATH .. 'Fonts\\' .. fileName
end

st.textures = {
	cornerbr = st:TexturePath('cornerarrowbottomright.tga'),
	mailSquare = st:TexturePath('mail-square.tga'),
	eyeClosed = st:TexturePath('eye-hidden.tga'),
	eyeOpen = st:TexturePath('eye-visible.tga'),
	atlas = st:TexturePath('SaftUIAtlas.blp'),
	filter = st:TexturePath('funnel.tga'), -- a funnel: white, a 24x24 drawing centred on 32x32 (the bags' currency Filter button)
}

-- Lucide's icons (lucide.dev, ISC; see Media/Textures/LUCIDE-LICENSE.txt), by
-- name: white on transparent, so a caller tints them with SetVertexColor. Each
-- is 32x32 (made by tools/lucide-to-tga.cjs, which says how to add one), Lucide's
-- 24 grid with the glyph in its middle half: draw one at twice the glyph's size
-- (20 for a 10 px X, 16 for an 8 px wide chevron). No texture coordinates.
st.icons = {
	x = st:TexturePath('lucide-x.tga'),
	chevronDown = st:TexturePath('lucide-chevron-down.tga'),
	chevronUp = st:TexturePath('lucide-chevron-up.tga'),
	rotateCcw = st:TexturePath('lucide-rotate-ccw.tga'),
	diff = st:TexturePath('lucide-diff.tga'),
	ellipsis = st:TexturePath('lucide-ellipsis.tga'),
	ellipsisVertical = st:TexturePath('lucide-ellipsis-vertical.tga'),
	settings = st:TexturePath('lucide-settings.tga'),
	funnel = st:TexturePath('lucide-filter.tga'), -- Lucide 0.460.0 names the funnel `filter` (the bags' own hand-drawn one is st.textures.filter)
	arrowDownToLine = st:TexturePath('lucide-arrow-down-to-line.tga'),
}

st.FRAME_ANCHORS = {
	['TOPLEFT'] = 'Top Left',
	['TOPRIGHT'] = 'Top Right',
	['TOP'] = 'Top',
	['BOTTOM'] = 'Bottom',
	['BOTTOMLEFT'] = 'Bottom Left',
	['BOTTOMRIGHT'] = 'Bottom Right',
	['LEFT'] = 'Left',
	['RIGHT'] = 'Right',
	['CENTER'] = 'Center',
}

st.HiddenFrame = CreateFrame('frame')
st.HiddenFrame:SetPoint('BOTTOM', UIParent, 'TOP', 0, 9000)
st.HiddenFrame:Hide()
