local st = SaftUI
local LT = st:NewModule('Loot', 'AceHook-3.0', 'AceEvent-3.0')
st.Loot = LT
LT.DEBUG = false

function st.Loot:OnInitialize()
	self.config = st.config.profile.loot

	AlertFrame:SetAlertsEnabled(false, "")
	AlertFrame.SetAlertsEnabled = st.dummy
	BossBanner:UnregisterEvent("ENCOUNTER_LOOT_RECEIVED")

	self:InitializeLootFrame()
	self:InitializeLootFeed()
end