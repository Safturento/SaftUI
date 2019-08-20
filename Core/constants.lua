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

st.ICON_COORDS = {.08, .92, .08, .92}
st.BLANK_TEX = [[Interface\BUTTONS\WHITE8X8]]
st.BACKDROP = {
	bgFile = st.BLANK_TEX, 
	edgeFile = st.BLANK_TEX,
	tile = false, tileSize = 0, edgeSize = 1, 
	insets = { left = 1, right = 1, top = 1, bottom = 1}
}


st.HiddenFrame = CreateFrame('frame')
st.HiddenFrame:Hide()
