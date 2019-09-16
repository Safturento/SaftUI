local ADDON_NAME, st = ...
local LT = st:NewModule('Loot', 'AceHook-3.0', 'AceEvent-3.0')


LT.DEBUG = false

function LT:OnInitialize()
	self.config = st.config.profile.loot

	LT:InitializeRollFrame()
end