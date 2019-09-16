local ADDON_NAME, st = ...
local MP = st:NewModule('Maps', 'AceHook-3.0', 'AceEvent-3.0')

function MP:OnInitialize()
	self.config = st.config.profile.maps
	self:InitializeMinimap()
end