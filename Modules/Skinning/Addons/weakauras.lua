local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

local function SkinIcon(parent, region, data)
	if not region.skinned then
		st:SetBackdrop(region, st.config.profile.skinning.addons.weakauras.template)

		-- Make sure the backdrop always stay below the icons..
		region.backdrop:SetFrameStrata('LOW')
		
		st:SkinIcon(region.icon)
		region.skinned = true
	end
end

---------------------------------------------
-- INITIALIZE -------------------------------
---------------------------------------------

SK.AddonSkins.WeakAuras = function()
	hooksecurefunc(WeakAuras.regionTypes.icon, 'modify', SkinIcon)	
end