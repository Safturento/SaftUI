local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:
InitializeTooltipScanner()
    self.cache = {}

    self.tip = CreateFrame('GameTooltip', 'SaftUI_ScanningTooltip', UIParent, 'GameTooltipTemplate')
    self.tip:SetOwner( WorldFrame, "ANCHOR_NONE" );
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

    self.tip:SetBagItem(bagID, slotID)
    local text = enumerateTextRegions(self.tip:GetRegions())
    self.cache[clink] = text
    return text
end