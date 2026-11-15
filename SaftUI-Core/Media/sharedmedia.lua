local AddonName, st = ...

st.LSM = LibStub('LibSharedMedia-3.0')

st.LSM:Register('background',	'SaftUI Blank', 		[[Interface\BUTTONS\WHITE8X8]])

st.LSM:Register('border',		'SaftUI Glow Border',	st:TexturePath('glowTex.tga'))
st.LSM:Register('border',		'SaftUI Solid Border',  st:TexturePath('borderTex.tga'))

st.LSM:Register('statusbar',	'SaftUI Gloss', 		st:TexturePath('normTex.tga'))
st.LSM:Register('statusbar',	'SaftUI Flat', 			[[Interface\BUTTONS\WHITE8X8]])

-- SaftUI's own faces, in registration order: st.SAFTUI_FACES lists them for the
-- preload (fonts.lua sets each on a font object at load, so a first pick in
-- the game draws).
st.SAFTUI_FACES = {}
local function Face(name, file)
	st.LSM:Register('font', name, file)
	st.SAFTUI_FACES[#st.SAFTUI_FACES + 1] = name
end

Face('envypn', st:FontPath('envypn.ttf'))
Face('Semplice', st:FontPath('Semplice_Reg.ttf'))
Face('Colus', st:FontPath('Colus-Regular.otf'))
Face('Rainy Hearts', st:FontPath('rainyhearts.ttf'))
Face('VCR OSD Mono', st:FontPath('VCR_OSD_MONO_1.001.ttf'))
Face('Charles Wright Bold', st:FontPath('CharlesWright-Bold.ttf'))
Face('AgencyFB', st:FontPath('AgencyFB.ttf'))
Face('AgencyFB Bold', st:FontPath('AgencyFB_Bold.ttf'))
Face('Homespun', st:FontPath('homespun.ttf'))
Face('Visitor', st:FontPath('visitor1.ttf'))
Face('Righteous', st:FontPath('Righteous-Regular.ttf'))
Face('Bebas Neue', st:FontPath('BebasNeue-Regular.ttf'))
Face('FiraCode', st:FontPath('FiraCode\\FiraCode-Regular.ttf'))
Face('FiraCode Medium', st:FontPath('FiraCode\\FiraCode-Medium.ttf'))
Face('FiraCode Bold', st:FontPath('FiraCode\\FiraCode-Bold.ttf'))

function st:GetStatusBarTexture(texture_name)
	return texture_name and self.LSM:Fetch('statusbar', texture_name) or st.BLANK_TEX
end