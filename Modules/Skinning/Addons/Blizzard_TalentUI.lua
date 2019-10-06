local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------


SK.AddonSkins.Blizzard_TalentUI = function()
	SK:SkinBlizzardPanel(TalentFrame, {fix_padding = true})
end