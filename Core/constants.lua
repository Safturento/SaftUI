local st = SaftUI
local ADDON_NAME = ...

st.DEBUG = false
st.GAME_VERSION = select(4, GetBuildInfo())

st.name = ADDON_NAME
st.retail = st.GAME_VERSION >= 70000

st.my_name = select(1, UnitName('player'))
st.my_class = select(2, UnitClass('player'))
st.my_race = select(2, UnitRace('player'))
st.my_faction = UnitFactionGroup('player')
st.my_realm = GetRealmName()

st.screenWidth, st.screenHeight = GetPhysicalScreenSize()
st.scale = 768/st.screenHeight
st.mult = 1

st.CLOSE_BUTTON_SIZE = {20, 10}
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

local MEDIA_PATH = format('Interface\\AddOns\\%s\\Media\\', st.name)

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
	atlas = st:TexturePath('SaftUIAtlas.blp')
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
