local ADDON_NAME, st = ...
local SK = st:GetModule('Skinning')

SK.AddonSkins.VanasKoS = function()
	local kos = LibStub("AceAddon-3.0"):GetAddon("VanasKoS")
	warn_frame = kos:GetModule('WarnFrame')
	
	local config = st.config.profile.addon_skins.vanaskos
	
	warn_frame.db.profile.WarnFrameBorder = true
	VanasKoS_WarnFrame:SetBackdrop(nil)
	st:SetBackdrop(VanasKoS_WarnFrame, config.template)
end