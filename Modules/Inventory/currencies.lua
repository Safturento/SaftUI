local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:ShowCurrencyTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_BOTTOMLEFT", 0, 0);
    GameTooltip:SetCurrencyToken(slot.elementData.currencyIndex)

    if slot.elementData.isAccountTransferable then
		local transferPercentage = slot.elementData.transferPercentage;
		local percentageLost = transferPercentage and (100 - transferPercentage) or 0;
		if percentageLost > 0 then
			GameTooltip_AddNormalLine(GameTooltip, CURRENCY_TRANSFER_LOSS:format(math.ceil(percentageLost)));
		end
	end

    local canTransfer, failureReason = self:IsCurrencyTransferable(slot);

    if canTransfer then
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        GameTooltip_AddInstructionLine(GameTooltip, "<Click to transfer>");
    elseif failureReason then
        GameTooltip_AddBlankLineToTooltip(GameTooltip);
        GameTooltip_AddErrorLine(GameTooltip, failureReason)
    end

    GameTooltip:Show()
end

function INV:HideCurrencyTooltip(slot)
    GameTooltip:Hide()
end

function INV.GetCurrencySlotPool(category)
    return CreateObjectPool(
        function() return INV.CreateCurrencySlot(category) end,
        function(_, slot) slot:Hide() end
    )
end

local poolSize = 0
function INV.CreateCurrencySlot(category)
    poolSize = poolSize + 1
    local slotName = 'SaftUI_Bag_Currencies_Slot'..poolSize
    local slot = CreateFrame(st.retail and 'ItemButton' or 'CheckButton', slotName, category, 'TokenEntryTemplate')
    slot.NormalTexture = _G[slotName..'NormalTexture']
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
        INV.config.filters.currencies[slot.elementData.id] = self:GetChecked() or nil
    end)

    if slot.NormalTexture then slot.NormalTexture:SetTexture('') end

    slot:SetSize(INV.config.buttonwidth, INV.config.buttonheight)

    st:SkinIcon(slot.icon, nil, slot)
    st:SkinActionButton(slot, {
		template = INV.config.template,
		font = INV.config.fonts.icons
	})
	slot:SetNormalTexture("")
	slot:SetPushedTexture("")
    slot.Content.WatchedCurrencyCheck:ClearAllPoints()

    slot.category = category
    slot.container = category:GetParent()
    slot:SetScript('OnClick', st.dummy)
    slot:SetScript('OnEnter', st.dummy)
    slot:SetScript('OnLeave', st.dummy)
    INV:HookScript(slot, 'OnClick', 'CurrencyOnClick')
    INV:HookScript(slot, 'OnEnter', 'ShowCurrencyTooltip')
    INV:HookScript(slot, 'OnLeave', 'HideCurrencyTooltip')

    return slot
end

local function shouldShow(info, editMode)
    if info.isHeader then return end
    if not editMode and info.quantity == 0 then return end

    if INV.config.filters.currencies[info.id]
        and not editMode then return end

    return true
end

local DISABLED_ERROR_MESSAGE = {
	[Enum.AccountCurrencyTransferResult.MaxQuantity] = CURRENCY_TRANSFER_DISABLED_MAX_QUANTITY,
	[Enum.AccountCurrencyTransferResult.NoValidSourceCharacter] = CURRENCY_TRANSFER_DISABLED_NO_VALID_SOURCES,
	[Enum.AccountCurrencyTransferResult.CannotUseCurrency] = CURRENCY_TRANSFER_DISABLED_UNMET_REQUIREMENTS,
};

function INV:IsCurrencyTransferable(slot)
    if not  C_CurrencyInfo.IsAccountCharacterCurrencyDataReady then return end
    if not slot.elementData.isAccountTransferable then return end

    if not C_CurrencyInfo.IsAccountCharacterCurrencyDataReady() then
        return false, RETRIEVING_DATA
    end

    local canTransfer, failureReason = C_CurrencyInfo.CanTransferCurrency(slot.elementData.currencyID);
    return canTransfer, failureReason and DISABLED_ERROR_MESSAGE[failureReason]
end

function INV:GetCurrencies(editMode)
    local items = {}
    for i=1, C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(i)
        if info then
            info.link = C_CurrencyInfo.GetCurrencyListLink(i)
            if info.link then
                info.id = C_CurrencyInfo.GetCurrencyIDFromLink(info.link)
                info.currencyIndex = i
                if shouldShow(info, editMode) then
                    tinsert(items, info)
                end
            end
        end
    end
    return items
end

function INV:InitializeCurrencyCategory()
    if not C_CurrencyInfo.RequestCurrencyDataForAccountCharacters then return end
    C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
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
            slot.filterCheckbox:SetChecked(INV.config.filters.currencies[slot.elementData.id])
        end
    end)

    category.filterButton = filterButton

    category.container.transferMenu = CurrencyTransferMenu
end

function INV:CurrencyOnClick(slot)
    if IsModifiedClick("CHATLINK") then
        HandleModifiedItemClick(C_CurrencyInfo.GetCurrencyListLink(self.currencyIndex));
        return
    end

    if not INV:IsCurrencyTransferable(slot) then return end

    local shouldHide = CurrencyTransferMenu.currencyInfo and CurrencyTransferMenu.currencyInfo.currencyID == slot.elementData.currencyID
    CurrencyTransferMenu:Hide()

    if shouldHide then return end

    CurrencyTransferMenu:SetCurrency(slot.elementData.currencyID)
    CurrencyTransferMenu:TriggerEvent(
            CurrencyTransferMenuMixin.Event.CurrencyTransferRequested, slot.elementData.currencyID);
    CurrencyTransferMenu:ClearAllPoints()
    CurrencyTransferMenu:SetPoint('TOPRIGHT', slot.container, 'TOPLEFT', -7, 0)
    CurrencyTransferMenu:Show()
end

function INV:UpdateCurrencyCategory(forceShow)
    --C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
    local category = self.containers.bag.categories.Currencies
    if not category then return end

    category:SetShown(forceShow or not INV.config.filters.categories.bag.Currencies)
    --TODO: We can definitely be smarter about updating but this is fine for now
    category.slotPool:ReleaseAll()

    local currencyItems = self:GetCurrencies(category.filterButton:GetChecked())
    local prev
    local prevRow = category.header
    for i, currencyData in pairs(currencyItems) do
        local slot = category.slotPool:Acquire()
        slot.elementData = currencyData
        slot.currencyIndex = currencyData.currencyIndex

        slot.icon:SetTexture(currencyData.iconFileID)

        slot.Count:SetText(currencyData.quantity)
        if currencyData.isAccountTransferable or currencyData.isAccountWide then
            slot.Count:SetTextColor(unpack(st.config.profile.colors.text.cyan))
        else
            slot.Count:SetTextColor(unpack(st.config.profile.colors.text.white))
        end

        slot:ClearAllPoints()
        slot:Show()

        local quality = C_CurrencyInfo.GetBasicCurrencyInfo(slot.elementData.id).quality
        if quality > -1 then
            local c = ITEM_QUALITY_COLORS[quality]
            slot.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
        else
            slot.backdrop:SetBackdropBorderColor(0, 0, 0)
        end

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