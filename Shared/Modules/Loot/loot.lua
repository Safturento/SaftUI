local st = SaftUI
local LT = st:NewModule('Loot', 'AceHook-3.0', 'AceEvent-3.0')
st.Loot = LT
LT.DEBUG = false

function LT:OnInitialize()
	self.config = st.config.profile.loot

	LOOTFRAME_AUTOLOOT_RATE = 0.1
	LOOTFRAME_AUTOLOOT_DELAY = 0.1
	AlertFrame:SetAlertsEnabled(false, "")
	AlertFrame.SetAlertsEnabled = st.dummy
	BossBanner:UnregisterEvent("ENCOUNTER_LOOT_RECEIVED")

-- 	self:InitializeLootFrame()
	self:InitializeLootFeed()

	if self.DEBUG then
		self:InitializeTestMode()
	end
end