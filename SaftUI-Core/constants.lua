local st = SaftUI
local ADDON_NAME = ...

st.DEBUG = false
st.GAME_VERSION = select(4, GetBuildInfo())

st.name = "SaftUI"
st.forever = st.GAME_VERSION == 16001
-- Forever runs on the mainline client, so it counts as retail
st.retail = st.GAME_VERSION >= 110000 or st.forever

st.my_name = select(1, UnitName('player'))
st.my_class = select(2, UnitClass('player'))
st.my_race = select(2, UnitRace('player'))
st.my_faction = UnitFactionGroup('player')
st.my_realm = GetRealmName()

st.screenWidth, st.screenHeight = GetPhysicalScreenSize()
st.scale = 768/st.screenHeight
st.mult = 1

st.CLOSE_BUTTON_SIZE = {20, 10} -- a Blizzard close button handed to st:CreateHeader
st.CLOSE_X_BUTTON_SIZE = {24, 24} -- SaftUI's own (st:CreateCloseButton)
-- The options window's box colors, shared by its widgets and the close button.
st.BOX_COLORS = {
	field = { 0.078, 0.078, 0.078, 1 },
	edge = { 0.3, 0.3, 0.3, 1 },
	alt = { 0.1, 0.1, 0.1, 1 },
	bg = { 0.12, 0.12, 0.12, 1 },
}
-- The close X's part of close.tga: a power-of-two canvas (like the other textures), with the X in the middle 10x10.
st.CLOSE_X_COORDS = {3/16, 13/16, 3/16, 13/16}
st.ICON_COORDS = {.08, .92, .08, .92}
st.BLANK_TEX = [[Interface\BUTTONS\WHITE8X8]]
st.TAB_HEIGHT = 20
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
	mail = st:TexturePath('mail.tga'),
	mailSquare = st:TexturePath('mail-square.tga'),
	glow = st:TexturePath('glowTex.tga'),
	eyeClosed = st:TexturePath('eye-hidden.tga'),
	eyeOpen = st:TexturePath('eye-visible.tga'),
	atlas = st:TexturePath('SaftUIAtlas.blp'),
	close = st:TexturePath('close.tga'), -- the close button's X: white, 16x16 with the 10x10 X at 3,3 (see CLOSE_X_COORDS)
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

st.INVERSE_ANCHORS = {
	['LEFT'] = 'RIGHT',
	['RIGHT'] = 'LEFT',
	['TOP'] = 'BOTTOM',
	['BOTTOM'] = 'TOP',
	['TOPLEFT'] = 'BOTTOMRIGHT',
	['BOTTOMRIGHT'] = 'TOPLEFT',
	['TOPRIGHT'] = 'BOTTOMLEFT',
	['BOTTOMLEFT'] = 'TOPRIGHT',
}

st.HiddenFrame = CreateFrame('frame')
st.HiddenFrame:SetPoint('BOTTOM', UIParent, 'TOP', 0, 9000)
st.HiddenFrame:Hide()
