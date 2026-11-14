local st = SaftUI
local LT = st:GetModule('Loot')

-- Roll results show while the Rolls filter is on, Self Only or not: seeing who
-- won what is their point. With Rolls off, a result the winner's loot message
-- was folded into still shows wherever that loot would (the Loot filter, and
-- Self Only for someone else's), so turning Rolls off never hides an item you
-- looted.
function LT:ShouldAddItem(item)
	local filters = self.config.feed.filters
	local kind = item.type
	if kind == 'Rolls' then
		if filters.Rolls then return true end
		if not item.looted then return false end
		kind = 'Loot'
	end

	if filters.Self == true and item.notSelf then return end

	return filters[kind]
end

local cachedFilter = {}
function LT:GetFilteredItems(useCache)
	if useCache then return cachedFilter end

	local items = {}
	for _, item in pairs(self:GetAllItems()) do
		if self:ShouldAddItem(item) then
			tinsert(items, item)
		end
	end

	cachedFilter = items
	return items
end

-- The filter menu's entries, top to bottom: Self Only first, as it narrows
-- whatever the kinds show, then the kinds. Each is a key of config.feed.filters.
local FILTER_ENTRIES = {
	{ key = 'Self', label = 'Self Only' },
	{ key = 'Loot', label = 'Loot' },
	{ key = 'Rolls', label = 'Rolls' },
	{ key = 'Gold', label = 'Gold' },
	{ key = 'Currency', label = 'Currency' },
	{ key = 'Skill', label = 'Skill ups' },
	{ key = 'Experience', label = 'Experience' },
	{ key = 'Reputation', label = 'Reputation' },
	{ key = 'Honor', label = 'Honor' },
}
LT.FILTER_ENTRIES = FILTER_ENTRIES

local function isChecked(key)
	return LT.config.feed.filters[key]
end

-- A click on a row: the filter flips and the feed is drawn again at once. The
-- list stays open, as the kit's check list does.
local function toggle(key)
	local filters = LT.config.feed.filters
	filters[key] = not filters[key]
	LT:UpdateFeed()
end

-- Opens SaftUI's own check list (the options kit's W.OpenCheckList, Core's) at the
-- filter button's side: on the far side of the button from the feed, in the
-- button's row, so it covers neither the feed nor the jump button.
function LT:OpenSlotOptions()
	local feed, W = self.feed, st.OptionsWidgets
	local anchor, button = feed.filterMenuAnchor, feed.filterButton
	if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
	anchor:SetSize(W.WIDTH.select, button:GetHeight())
	anchor:ClearAllPoints()
	if feed.buttonsOnLeft then
		anchor:SetPoint('BOTTOMRIGHT', button, 'BOTTOMLEFT', -self.config.feed.spacing, 0)
	else
		anchor:SetPoint('BOTTOMLEFT', button, 'BOTTOMRIGHT', self.config.feed.spacing, 0)
	end
	W.OpenCheckList(anchor, FILTER_ENTRIES, isChecked, toggle)
end

function LT:InitializeFilterDropdown()
	local filterButton = self:CreateFeedIconButton(self.feed:GetName()..'FilterButton', st.icons.funnel,
		'Filter the loot feed', 'Choose which kinds of entry the feed shows.')
	self.feed.filterButton = filterButton
	self.feed.filterMenuAnchor = CreateFrame('Frame', nil, self.feed)
	self:HookScript(filterButton, 'OnClick', 'OpenSlotOptions')
end
