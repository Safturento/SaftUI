local st = SaftUI
local SK = st:GetModule('Skinning')

local HK = SK:NewModule('Hekili')

function HK:SkinIcon(_, dispID, id)
	local button = Hekili.DisplayPool[dispID] and Hekili.DisplayPool[dispID].Buttons[ id ]
	if not button then return end

	if not button.skinned then
		st:SetBackdrop(button, SK.config.template)

		-- Make sure the backdrop always stay below the icons..
		button.backdrop:SetFrameStrata('LOW')
		
		button.skinned = true
	end

	st:SkinIcon(button.Icon, nil, button)
end

function HK:OnInitialize()
	if not Hekili then return end
	self:SecureHook(Hekili, 'CreateButton', 'SkinIcon')
end