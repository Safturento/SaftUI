local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

SK.AddonSkins.VanasKoS = function()
	local kos = LibStub("AceAddon-3.0"):GetAddon("VanasKoS")
	warn_frame = kos:GetModule('WarnFrame')
	
	local config = st.config.profile.addon_skins.vanaskos
	
	warn_frame.db.profile.WarnFrameBorder = true
	VanasKoS_WarnFrame:SetBackdropBorderColor(0, 0, 0, 0)
	st:SetBackdrop(VanasKoS_WarnFrame, config.template)
	-- VanasKoS_FontKos:SetFont(st:GetFont(config.font))
end