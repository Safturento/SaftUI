local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:ShowCurrencyTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_BOTTOMLEFT", 0, 0);
    GameTooltip:SetCurrencyToken(slot.info.index);
    GameTooltip:Show()
end

function INV:HideCurrencyTooltip(slot)
    GameTooltip:Hide()
end

function INV.GetCurrencySlotPool(parent)
    return CreateObjectPool(
        function() return INV.CreateCurrencySlot(parent) end,
        function(_, slot) slot:Hide() end
    )
end

function INV.CreateCurrencySlot(parent)
    local slot = CreateFrame('ItemButton', nil, parent)
    slot.Count:SetDrawLayer('OVERLAY', 7)
    slot.Count:Show()
    slot.Count:SetText('-')

    slot.CountBG = slot:CreateTexture(nil, 'OVERLAY')
    slot.CountBG:SetPoint('BOTTOMRIGHT', slot.icon)
    slot.CountBG:SetPoint('TOPLEFT', slot.Count, -2, 1)
    slot.CountBG:SetTexture(st.BLANK_TEX)
    slot.CountBG:SetAlpha(0.6)
    slot.CountBG:SetVertexColor(0,0,0)

    slot.filterCheckbox = st:CreateCheckButton(nil, slot)
    slot.filterCheckbox:Hide()
    --st:SetBackdrop(slot.filterCheckbox, 'thin')
    slot.filterCheckbox:SetSize(8, 8)
    slot.filterCheckbox:SetPoint('TOPRIGHT')
    slot.filterCheckbox:HookScript('OnClick', function(self)
        INV.config.filters.currencies[slot.info.id] = self:GetChecked() or nil
    end)

    slot.NormalTexture:SetTexture('')

    slot:SetSize(INV.config.buttonwidth, INV.config.buttonheight)

    st:SkinIcon(slot.icon, nil, slot)

    st:SkinActionButton(slot, {
		template = INV.config.template,
		font = INV.config.fonts.icons
	})
	slot:SetNormalTexture("")
	slot:SetPushedTexture("")

    slot.container = parent

    INV:HookScript(slot, 'OnEnter', 'ShowCurrencyTooltip')
    INV:HookScript(slot, 'OnLeave', 'HideCurrencyTooltip')

    return slot
end

local function shouldShow(info, editMode)
    if info.isHeader then return end
    if info.quantity == 0 then return end

    if INV.config.filters.currencies[info.id]
        and not editMode then return end

    return true
end

function INV:GetCurrencies(editMode)
    local items = {}
    for i=1, C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        info.link = C_CurrencyInfo.GetCurrencyListLink(i)
        if info.link then
            info.id = C_CurrencyInfo.GetCurrencyIDFromLink(info.link)
            info.index = i
            if shouldShow(info, editMode) then
                tinsert(items, info)
            end
        end
    end
    return items
end

function INV:InitializeCurrencyCategory()
    local category = self:CreateCategory('bag', 'Currencies', self.GetCurrencySlotPool)

    if not self.config.filters.currencies then
        self.config.filters.currencies = {}
    end

    local filterButton = st:CreateCheckButton(nil, category.header)
    category.header.filterButton = filterButton
    filterButton:SetPoint('TOPRIGHT')
    filterButton:SetSize(46, category.header:GetHeight())

    filterButton.text:SetAllPoints(filterButton)
    filterButton:SetFont('pixel')
    filterButton:SetText('Filter')

    filterButton:SetScript('OnClick', function()
        INV:UpdateContainer('bag')
        for slot in category.slotPool:EnumerateActive() do
            slot.filterCheckbox:SetShown(filterButton:GetChecked())
            slot.filterCheckbox:SetChecked(INV.config.filters.currencies[slot.info.id])
        end
    end)
    category.filterButton = filterButton
end

function INV:UpdateCurrencyCategory(forceShow)
    local category = self.containers.bag.categories.Currencies
    category:SetShown(forceShow or not INV.config.filters.categories.bag.Currencies)
    --TODO: We can definitely be smarter about updating but this is fine for now
    category.slotPool:ReleaseAll()

    local currencyItems = self:GetCurrencies(category.filterButton:GetChecked())
    local prev
    local prevRow = category.header
    for i, currency in pairs(currencyItems) do
        local slot = category.slotPool:Acquire()
        slot.icon:SetTexture(currency.iconFileID)
        slot.Count:SetText(currency.quantity)
        slot:ClearAllPoints()
        slot:Show()
        slot.info = currency

        if i % self.config.bag.perrow == 1 then
            slot:SetPoint('TOPLEFT', prevRow, 'BOTTOMLEFT', 0, -self.config.buttonspacing)
            prevRow = slot
        else
            slot:SetPoint('LEFT', prev, 'RIGHT', self.config.buttonspacing, 0)
        end
        prev = slot
    end

    category.numRows = math.ceil(#currencyItems/self.config.bag.perrow)
	category:SetHeight(
        (self.config.buttonheight + self.config.buttonspacing) * category.numRows + self.config.categoryTitleHeight
    )
end