local AddonName, st = ...

st.LSM = LibStub('LibSharedMedia-3.0')

st.LSM:Register('background',	'SaftUI Blank', 		[[Interface\BUTTONS\WHITE8X8]])

st.LSM:Register('border',		'SaftUI Glow Border',	st:TexturePath('glowTex.tga'))
st.LSM:Register('border',		'SaftUI Solid Border',  st:TexturePath('borderTex.tga'))

st.LSM:Register('statusbar',	'SaftUI Gloss', 		st:TexturePath('normTex.tga'))
st.LSM:Register('statusbar',	'SaftUI Flat', 			[[Interface\BUTTONS\WHITE8X8]])

st.LSM:Register('font', 		'Semplice',				st:FontPath('Semplice_Reg.ttf'))
st.LSM:Register('font', 		'Charles Wright Bold',  st:FontPath('CharlesWright-Bold.ttf'))
st.LSM:Register('font', 		'AgencyFB',				st:FontPath('AgencyFB.ttf'))
st.LSM:Register('font', 		'AgencyFB Bold',		st:FontPath('AgencyFB_Bold.ttf'))
st.LSM:Register('font', 		'Homespun',				st:FontPath('homespun.ttf'))
st.LSM:Register('font', 		'Visitor',				st:FontPath('visitor1.ttf'))
st.LSM:Register('font', 		'Righteous',			st:FontPath('Righteous-Regular.ttf'))
st.LSM:Register('font', 		'Righteous',			st:FontPath('Righteous-Regular.ttf'))
st.LSM:Register('font', 		'FiraCode',			    st:FontPath('FiraCode\\FiraCode-Regular.ttf'))
st.LSM:Register('font', 		'FiraCode Medium',	    st:FontPath('FiraCode\\FiraCode-Medium.ttf'))
st.LSM:Register('font', 		'FiraCode Bold',	    st:FontPath('FiraCode\\FiraCode-Bold.ttf'))