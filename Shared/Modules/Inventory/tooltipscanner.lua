local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:
InitializeTooltipScanner()
    self.cache = {}

    self.tip = CreateFrame('GameTooltip', 'SaftUI_ScanningTooltip', UIParent, 'GameTooltipTemplate')
    self.tip:SetOwner(UIParent, "ANCHOR_RIGHT", 1000, 1000);
    self.tip:Hide()
    self.tip:AddFontStrings(
        self.tip:CreateFontString("SaftUI_ScanningTooltipTextLeft1", nil, "GameTooltipText"),
        self.tip:CreateFontString("SaftUI_ScanningTooltipTextRight1", nil, "GameTooltipText"),
        self.tip:CreateFontString("SaftUI_ScanningTooltipTextLeft2", nil, "GameTooltipText"),
        self.tip:CreateFontString("SaftUI_ScanningTooltipTextRight2", nil, "GameTooltipText"),
        self.tip:CreateFontString("SaftUI_ScanningTooltipTextLeft3", nil, "GameTooltipText"),
        self.tip:CreateFontString("SaftUI_ScanningTooltipTextRight3", nil, "GameTooltipText")
    );
end

function enumerateTextRegions(...)
    local text = ""
    for i = 1, select("#", ...) do
        local region = select(i, ...)
        if region and region:GetObjectType() == "FontString" then
            local regionText = region:GetText()
            if regionText then
                text = text .. st.StringFormat:ColorString(regionText, region:GetTextColor()) .."\n"
            end
        end
    end
    return text
end

function INV:ScanBagItem(bagID, slotID)
    self.tip:ClearLines()


    local clink = C_Container.GetContainerItemLink(bagID, slotID)
    if self.cache[clink] and string.len(self.cache[clink]) then return self.cache[clink] end

    local itemID = C_Container.GetContainerItemID(bagID, slotID)
    if not itemID then return end

    if not C_Item.IsItemDataCachedByID(itemID) then
        C_Item.RequestLoadItemDataByID(itemID)
    end

    local text
    if string.matchnocase(clink, 'battlepet') then
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("BOTTOMLEFT", UIParent, 'TOPRIGHT', 100, 100)
        self.tip:SetBagItem(bagID, slotID)
        GameTooltip:Hide()
        BattlePetTooltip:Hide()
        text = enumerateTextRegions(self.tip:GetRegions())
    else
        self.tip:SetBagItem(bagID, slotID)
        text = enumerateTextRegions(self.tip:GetRegions())
    end

    self.cache[clink] = text
    return text

end

--\124cff0070dd\124Hbattlepet:1040:25:3:1725:260:260:0000000000000000:40521\124h[Imperial Silkworm]\124h\124r