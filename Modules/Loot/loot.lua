local st = SaftUI
local LT = st:NewModule('Loot')
st.Loot = LT
LT.DEBUG = false

function LT:OnInitialize()
	self.config = st.config.profile.loot

	LOOTFRAME_AUTOLOOT_RATE = 0.1
	LOOTFRAME_AUTOLOOT_DELAY = 0.1
	AlertFrame:SetAlertsEnabled(false, "")
	AlertFrame.SetAlertsEnabled = st.dummy
	if BossBanner then
		BossBanner:UnregisterEvent("ENCOUNTER_LOOT_RECEIVED")
	end

-- 	self:InitializeLootFrame()
	self:InitializeRollFrame()
	self:InitializeLootFeed()

	if self.DEBUG then
		self:InitializeTestMode()
	end
end