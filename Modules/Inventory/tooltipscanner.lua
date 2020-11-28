local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeTooltipScanner()
    self.cache = {}

    self.tip = CreateFrame('GameTooltip', 'SaftUI_ScanningTooltip', UIParent, 'SharedTooltipTemplate')
    self.tip:SetOwner( WorldFrame, "ANCHOR_NONE" );
    self.tip:AddFontStrings(
        self.tip:CreateFontString("$parentTextLeft", nil, "GameTooltipText"),
        self.tip:CreateFontString("$parentTextRight", nil, "GameTooltipText")
    );
end

function enumerateTextRegions(...)
    local text = ""
    for i = 1, select("#", ...) do
        local region = select(i, ...)
        if region and region:GetObjectType() == "FontString" then
            local regionText = region:GetText()
            if regionText then
                text = text .. regionText .. " "
            end
        end
    end
    return text
end

function INV:ScanBagItem(bagID, slotID)
    self.tip:ClearLines()
    --local clink = GetContainerItemLink(bagID, slotID)
    --if self.cache[clink] then return self.cache[clink] end

    hasCooldown, repairCost = self.tip:SetBagItem(bagID, slotID);
    local text = enumerateTextRegions(self.tip:GetRegions())
    --self.cache[clink] = text
    return text
end