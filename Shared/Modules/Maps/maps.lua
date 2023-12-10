local st = SaftUI
local MP = st:NewModule('Maps')

function MP:OnInitialize()
	self.config = st.config.profile.maps
	self:InitializeWorldMap()
	self:InitializeMinimap()
end