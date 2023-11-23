local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeTooltipScanner()
    self.cache = {}
end

function INV:ScanBagItem(bagID, slotID)
    local itemLink = C_Container.GetContainerItemLink(bagID, slotID)

    if self.cache[itemLink] then
        return self.cache[itemLink]
    end

    local data = C_TooltipInfo.GetBagItem(bagID, slotID)
    local text = ""
    for _,lines in pairs(data.lines) do
        if lines.leftText then
            text = text .. " " .. lines.leftText
        end
        if lines.rightText then
            text = text .. " " .. lines.rightText
        end
    end
    text = string.unmagic(text)
    self.cache[itemLink] = text
    return text
end