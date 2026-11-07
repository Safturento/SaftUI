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
-- Also ends test mode. Neither is protected, but in combat one becomes
-- protected if a protected frame (e.g. a unit frame) is anchored to it or to
-- something hanging off it; then its update waits for the end of combat.
function LT:UpdateConfig()
	-- Test mode is never part of a profile; a profile change ends it.
	self:SetTestRolls(false)
	self:SetTestFeed(false)

	if self.rollAnchor then
		self:UpdateGroupLootConfig() -- waits by itself (roll.lua)
	end
	if self.feed then
		-- UpdateLootFeedConfig sizes and places the feed and its lines, and
		-- UpdateFeed needs the lines the new profile's max_items adds.
		st:SafeReposition(self.feed, 'lootfeed', function()
			self:UpdateLootFeedConfig()
			-- The new filters give a different list, so start back at the top.
			self.feed.offset = 0
			self.feed.reset_button:Hide()
			self:UpdateFeed()
		end)
	end
end