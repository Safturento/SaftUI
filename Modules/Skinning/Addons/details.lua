local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

local function SkinDetails()
	local window = DetailsPlayerDetailsWindow
	st:SetBackdrop(window, st.config.profile.panels.template)
	-- for index, actor in container:ListActors() do

	-- end
end

SK.AddonSkins.Details = function()
	-- _detalhes:InstallPDWSkin("SaftUI", SkinDetails)
end