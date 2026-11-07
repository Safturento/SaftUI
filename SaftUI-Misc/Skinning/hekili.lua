local st = SaftUI
local SK = st:GetModule('Skinning')

local HK = SK:NewModule('Hekili')

local skinnedButtons = {} -- every button given a backdrop, for UpdateConfig

function HK:SkinIcon(_, dispID, id)
	local button = Hekili.DisplayPool[dispID] and Hekili.DisplayPool[dispID].Buttons[ id ]
	if not button then return end

	if not button.skinned then
		st:SetBackdrop(button, SK.config.template)

		-- Make sure the backdrop always stay below the icons..
		button.backdrop:SetFrameStrata('LOW')
		
		button.skinned = true
		tinsert(skinnedButtons, button)
	end

	st:SkinIcon(button.Icon, nil, button)
end

-- A profile change: re-applies the profile's skinning template.
function HK:UpdateConfig()
	for _, button in ipairs(skinnedButtons) do
		st:SetBackdrop(button, SK.config.template)
	end
end

function HK:OnEnable()
	if not Hekili then return end
	self:SecureHook(Hekili, 'CreateButton', 'SkinIcon')
end