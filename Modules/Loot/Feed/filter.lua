local st = SaftUI
local LT = st:GetModule('Loot')

function LT:ShouldAddItem(item)

	if self.config.feed.filters.Self == true and item.notSelf then return end

    return self.config.feed.filters[item.type]
end

local cachedFilter = {}
function LT:GetFilteredItems(useCache)
	--if useCache then return cachedFilter end

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
	}
	self.filterDropdown = st:CreateCheckboxDropdown("LootFilterDropdownMenu", filterButton, entries, isChecked, setChecked)
end
