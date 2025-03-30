local st = SaftUI

SaftUIScrollListItemMixin = {}

function SaftUIScrollListItemMixin:Init()
	self.button = st:CreateButton(nil, self, '', 'thick')
    self.button:SetAllPoints()
end

local function UpdateScrollListHeight(scrollList)
    local itemHeight = scrollList.itemHeight or 20
    local itemSpacing = scrollList.itemSpacing or 0
    scrollList.ScrollView:SetElementExtent(itemHeight)
    --scrollList.ScrollView:SetSpacing(itemSpacing)

    local numItems = scrollList.numItems or 10
    scrollList:SetHeight((itemHeight  + itemSpacing) * numItems)
end

function st:CreateScrollList(name, parent, updateFunc, initFunc)
    local scrollList = CreateFrame('Frame', name, parent, 'WowScrollBoxList')
    scrollList.ScrollBar = CreateFrame("EventFrame", nil, scrollList, "MinimalScrollBar")
    scrollList.ScrollBar:SetPoint("TOPLEFT", scrollList, "TOPRIGHT", 10, 0)
    scrollList.ScrollBar:SetPoint("BOTTOMLEFT", scrollList, "BOTTOMRIGHT", 10, 0)

    scrollList.ScrollView = CreateScrollBoxListLinearView()

    scrollList.SetData = function(self, dataProvider, retainScrollPosition)
        self.ScrollView:SetDataProvider(dataProvider, retainScrollPosition)
    end

    scrollList.SetItemSpacing = function(self, spacing)
        self.ScrollView:SetPadding(3, 3, 3, 3, spacing)
        self.itemSpacing = spacing
        UpdateScrollListHeight(self)
    end

    scrollList.SetItemHeight = function(self, height)
        self.itemHeight = height
        UpdateScrollListHeight(self)
    end

    scrollList.SetNumItems = function(self, numItems)
        self.numItems = numItems
        UpdateScrollListHeight(self)
    end

    scrollList.ScrollView:SetElementInitializer('SaftUIScrollListItemTemplate', function(item, data)
        if not item.isInitialized then
            item:Init()
            if initFunc then initFunc(item) end
            item.isInitialized = true
        end

        updateFunc(item, data)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(
            scrollList,
            scrollList.ScrollBar,
            scrollList.ScrollView)

    return scrollList
end