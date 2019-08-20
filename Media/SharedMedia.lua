local AddonName = ...

local LSM = LibStub('LibSharedMedia-3.0')
local media_path = format('Interface\\AddOns\\%s\\Media\\', AddonName)

LSM:Register('background',	'SaftUI Blank', 		[[Interface\BUTTONS\WHITE8X8]])
LSM:Register('border',		'SaftUI Glow Border',	media_path..'Textures\\glowTex.tga')
LSM:Register('border',		'SaftUI Solid Border',	media_path..'Textures\\borderTex.tga')

LSM:Register('font', 		'Semplice',				media_path .. 'Fonts\\Semplice_Reg.ttf')
LSM:Register('font', 		'AgencyFB',				media_path .. 'Fonts\\AgencyFB.ttf')
LSM:Register('font', 		'AgencyFB Bold',		media_path .. 'Fonts\\AgencyFB_Bold.ttf')
LSM:Register('font', 		'Homepsun',				media_path .. 'Fonts\\homespun.ttf')
LSM:Register('font', 		'Visitor',				media_path .. 'Fonts\\visitor1.ttf')

LSM:Register('statusbar',	'SaftUI Gloss', 		media_path..'Textures\\normTex.tga')
LSM:Register('statusbar',	'SaftUI Flat', 			[[Interface\BUTTONS\WHITE8X8]])
