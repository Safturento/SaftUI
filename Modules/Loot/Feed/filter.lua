local st = SaftUI
local LT = st:GetModule('Loot')

LT.FilterTypes = {
    Loot = {
        text = 'Loot',

    },
    Skill = { text = 'Skill ups' },
    Gold = { text = 'Gold' },
    Self = { text = 'Self Only' },
    Honor = { text = 'Honor' },
    Currency = { text = 'Currency' },
    Reputation = { text = 'Reputation' },
}

local function checkButton(key, override)
    return st.tablemerge({
        isNotRadio = true,
        keepShownOnClick = true,
        checked = function() return LT.config.feed.filters[key] end,
        func = function(self, arg1, arg2, checked)
            LT.config.feed.filters[key] = checked
            LT:UpdateFeed()
        end
	}, st.tablemerge(LT.FilterTypes[key], override))
end

local filterMenuList = {
    {
        text = "Feed Filter",
        isTitle = true,
        notCheckable = true
    },
    checkButton('Currency'),
	checkButton('Gold'),
    checkButton('Honor'),
    checkButton('Reputation'),
    checkButton('Skill'),
    checkButton('Loot'),
    checkButton('Self'),
}

local function OpenSlotOptions(filterButton, mouseButton, down)
    EasyMenu(filterMenuList, LT.filterDropdown, filterButton, -8, 0)
end

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


function LT:InitializeFilterDropdown()
	local filterButton = st:CreateButton(self.feed:GetName()..'FilterButton', self.feed, 'F', 'thick')
	filterButton:SetSize(20, 20)
	self.feed.filterButton = filterButton
	filterButton:HookScript('OnClick', OpenSlotOptions)

    if not self.config.feed then
        self.config.feed = { filters = {} }
    end

	local filterDropdown = CreateFrame("Frame", "SaftUI_LootFeedFilterMenu", UIParent, "UIDropDownMenuTemplate")
    filterDropdown.point = 'BOTTOMRIGHT'
    filterDropdown.relativePoint = 'BOTTOMLEFT'
    --UIDropDownMenu_SetWidth(filterDropdown, 200)
    --UIDropDownMenu_Initialize(filterDropdown, InitializeDropdown, "MENU")
	self.filterDropdown = filterDropdown
end
