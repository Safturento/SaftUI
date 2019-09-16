local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')


local function SkinButton(self)
	st.SkinActionButton(self, st.config.profile.skinning.addons.dominos)
end

local function UpdateAllButtons()
	for i = 1, 60 do
		if _G["DominosActionButton"..i] then
			SkinButton(_G["DominosActionButton"..i])
		end
	end
	
	for i = 1, 12 do
		SkinButton(_G["ActionButton"..i])
		SkinButton(_G["MultiBarBottomLeftButton"..i])
		SkinButton(_G["MultiBarBottomRightButton"..i])
		SkinButton(_G["MultiBarLeftButton"..i])
		SkinButton(_G["MultiBarRightButton"..i])
	end
end

SK.AddonSkins.Dominos = function()
	hooksecurefunc('ActionButton_Update', SkinButton)
	-- UpdateAllButtons()
end