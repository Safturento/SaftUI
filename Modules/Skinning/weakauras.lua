local st = SaftUI
local SK = st:GetModule('Skinning')

local WA = SK:NewModule('WeakAuras')

function WA:SkinIcon(parent, region, data)
	if not region.skinned then
		st:SetBackdrop(region, SK.config.template)

		-- Make sure the backdrop always stay below the icons..
		region.backdrop:SetFrameStrata('LOW')
		
		region.skinned = true
	end

	local icon = region.icon
	st:SkinIcon(icon, nil, region)
end

function WA:OnInitialize()
	if not WeakAurasPrivate then return end
	self:SecureHook(WeakAurasPrivate.regionTypes.icon, 'modify', 'SkinIcon')
end