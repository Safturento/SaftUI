local st = SaftUI
local SK = st:GetModule('Skinning')

local WA = SK:NewModule('WeakAuras')

local skinnedRegions = {} -- every region given a backdrop, for UpdateConfig

function WA:SkinIcon(parent, region, data)
	if not region.skinned then
		st:SetBackdrop(region, SK.config.theme, SK.config.background, 'aura')
		region.backdrop:SetFrameLevel(region:GetFrameLevel()-4)

		-- Make sure the backdrop always stay below the icons..
		region.backdrop:SetFrameStrata('LOW')
		
		region.skinned = true
		tinsert(skinnedRegions, region)
	end

	local icon = region.icon
	st:SkinIcon(icon, nil, region)
end

-- A profile change: re-applies the profile's skinning Theme and Background.
function WA:UpdateConfig()
	for _, region in ipairs(skinnedRegions) do
		st:SetBackdrop(region, SK.config.theme, SK.config.background, 'aura')
	end
end

function WA:OnEnable()
	if not WeakAurasPrivate then return end
	self:SecureHook(WeakAurasPrivate.regionTypes.icon, 'modify', 'SkinIcon')
end