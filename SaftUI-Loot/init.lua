local st = SaftUI
local LT = st:NewModule('Loot')
st.Loot = LT
LT.DEBUG = false

function LT:OnEnable()
	st:BindModuleConfig(self, 'loot')

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
end

-- A profile change: re-applies the rolls' and feed's size, spacing, template,
-- font and position, and re-filters the feed with the new profile's filters.
-- Safe in combat: neither touches a protected frame.
function LT:UpdateConfig()
	if self.rollAnchor then
		self:UpdateGroupLootConfig()
	end
	if self.feed then
		self:UpdateLootFeedConfig()
		-- The new filters give a different list, so start back at the top.
		self.feed.offset = 0
		self.feed.reset_button:Hide()
		self:UpdateFeed()
	end
end