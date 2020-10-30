local AddonName, st = ...

st.LSM = LibStub('LibSharedMedia-3.0')
local media_path = format('Interface\\AddOns\\%s\\Media\\', AddonName)

st.LSM:Register('background',	'SaftUI Blank', 		[[Interface\BUTTONS\WHITE8X8]])

st.LSM:Register('border',		'SaftUI Glow Border',	media_path..'Textures\\glowTex.tga')
st.LSM:Register('border',		'SaftUI Solid Border',  media_path..'Textures\\borderTex.tga')

st.LSM:Register('font', 		'Semplice',				media_path .. 'Fonts\\Semplice_Reg.ttf')
st.LSM:Register('font', 		'Charles Wright Bold',  media_path .. 'Fonts\\CharlesWright-Bold.ttf')
st.LSM:Register('font', 		'AgencyFB',				media_path .. 'Fonts\\AgencyFB.ttf')
st.LSM:Register('font', 		'AgencyFB Bold',		media_path .. 'Fonts\\AgencyFB_Bold.ttf')
st.LSM:Register('font', 		'Homespun',				media_path .. 'Fonts\\homespun.ttf')
st.LSM:Register('font', 		'Visitor',				media_path .. 'Fonts\\visitor1.ttf')
st.LSM:Register('font', 		'Righteous',			media_path .. 'Fonts\\Righteous-Regular.ttf')
st.LSM:Register('font', 		'Righteous',			media_path .. 'Fonts\\Righteous-Regular.ttf')
st.LSM:Register('font', 		'FiraCode',			    media_path .. 'Fonts\\FiraCode\\FiraCode-Regular.ttf')
st.LSM:Register('font', 		'FiraCode Medium',	    media_path .. 'Fonts\\FiraCode\\FiraCode-Medium.ttf')
st.LSM:Register('font', 		'FiraCode Bold',	    media_path .. 'Fonts\\FiraCode\\FiraCode-Bold.ttf')

st.LSM:Register('statusbar',	'SaftUI Gloss', 		media_path..'Textures\\normTex.tga')
st.LSM:Register('statusbar',	'SaftUI Flat', 			[[Interface\BUTTONS\WHITE8X8]])



--atlas.lua
