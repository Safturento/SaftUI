local ADDON_NAME, st = ...
local LT = st:NewModule('Loot', 'AceHook-3.0', 'AceEvent-3.0')
st.Loot = LT
LT.DEBUG = false

function st.Loot:OnInitialize()
	self.config = st.config.profile.loot

	-- self:InitializeLootFrame()
	self:InitializeLootFeed()
end