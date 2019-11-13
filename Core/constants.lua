local ADDON_NAME, st = ...

st.DEBUG = false
st.GAME_VERSION = select(4, GetBuildInfo())

st.is_classic = st.GAME_VERSION < 70000
st.is_retail = not st.is_classic

st.my_name = select(1, UnitName('player'))
st.my_class = select(2, UnitClass('player'))
st.my_race = select(2, UnitRace('player'))
st.my_faction = UnitFactionGroup('player')
st.my_realm = GetRealmName()
st.ui_scale = 768/GetScreenHeight()

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

st.MEDIA_PATH = format('Interface\\AddOns\\%s\\Media\\Textures\\', ADDON_NAME)
st.textures = {
	cornerbr = st.MEDIA_PATH..'cornerarrowbottomright.tga',
	mail = st.MEDIA_PATH..'mail.tga',
	glow = st.MEDIA_PATH..'glowTex.tga',
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

st.hidden_frame = CreateFrame('frame')
st.hidden_frame:Hide()
