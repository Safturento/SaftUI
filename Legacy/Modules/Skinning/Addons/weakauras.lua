local st = SaftUI
local SK = st:GetModule('Skinning')

local function SkinIcon(parent, region, data)
	if not region.skinned then
		st:SetBackdrop(region, SK.config.template)

		-- Make sure the backdrop always stay below the icons..
		region.backdrop:SetFrameStrata('LOW')
		
		region.skinned = true
	end

	st:SkinIcon(region.icon, nil, region)
end

SK.AddonSkins.WeakAuras = function()
	hooksecurefunc(WeakAuras.regionTypes.icon, 'modify', SkinIcon)	
end