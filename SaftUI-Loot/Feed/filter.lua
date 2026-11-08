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

local function isChecked(key)
    return LT.config.feed.filters[key]
end

local function setChecked(key, menuInputData, menu)
    LT.config.feed.filters[key] = not LT.config.feed.filters[key]
    LT:UpdateFeed()
end

function LT:OpenSlotOptions(filterButton, mouseButton, down)
    self.filterDropdown:Open()
end

function LT:InitializeFilterDropdown()
	local filterButton = st:CreateButton(self.feed:GetName()..'FilterButton', self.feed, 'F', 'thick')
	filterButton:SetSize(20, 20)
	self.feed.filterButton = filterButton
	self:HookScript(filterButton, 'OnClick', 'OpenSlotOptions')

    if not self.config.feed then
        self.config.feed = { filters = {} }
    end

	local entries = {
		Loot = { text = 'Loot' },
		Skill = { text = 'Skill ups' },
		Gold = { text = 'Gold' },
		Self = { text = 'Self Only' },
		Honor = { text = 'Honor' },
		Currency = { text = 'Currency' },
		Experience = { text = 'Experience' },
		Reputation = { text = 'Reputation' },
		Rolls = { text = 'Rolls' },
	}
	self.filterDropdown = st:CreateCheckboxDropdown(
	    "SaftUILootFilterDropdownMenu", filterButton, entries, isChecked, setChecked)
end
