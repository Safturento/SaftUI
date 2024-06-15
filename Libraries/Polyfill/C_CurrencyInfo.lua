C_CurrencyInfo.GetCurrencyListSize = C_CurrencyInfo.GetCurrencyListSize or GetCurrencyListSize
C_CurrencyInfo.GetCurrencyIDFromLink = C_CurrencyInfo.GetCurrencyIDFromLink or
    function(link)
        return select(2, link:match("(\124c%x%x%x%x%x%x%x%x\124Hcurrency:(%d+):%d+%D*)"))
    end

C_CurrencyInfo.GetCurrencyListInfo = C_CurrencyInfo.GetCurrencyListInfo or
    function(index)
        local name, isHeader, isHeaderExpanded, isTypeUnused, isShowInBackpack, quantity, iconFileID, maxQuantity, canEarnPerWeek, quantityEarnedThisWeek, unknown, itemID = GetCurrencyListInfo(index)

        return {
            name = name,
            description = nil,
            isHeader = isHeader,
            isHeaderExpanded = isHeaderExpanded,
            isTypeUnused = isTypeUnused,
            isShowInBackpack = isShowInBackpack,
            quantity = quantity,
            trackedQuantity = 0, -- What is this?
            iconFileID = iconFileID,
            maxQuantity = maxQuantity,
            canEarnPerWeek = canEarnPerWeek,
            quantityEarnedThisWeek = quantityEarnedThisWeek,
            isTradeable = false,
            quality = 1,
            maxWeeklyQuantity = maxWeeklyQuantity,
            totalEarned = 0,
            discovered = true,
            useTotalEarnedForMaxQty = 0,
        }
    end

