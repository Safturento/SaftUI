local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeTooltipScanner()
    self.cache = {}
end

function INV:ScanBagItem(bagID, slotID)
    if not C_TooltipInfo then return "" end
    local itemLink = C_Container.GetContainerItemLink(bagID, slotID)
    if not itemLink then return "" end

    if self.cache[itemLink] then
        return self.cache[itemLink]
    end

    -- GetBagItem can return nothing (e.g. data not ready yet); don't cache that.
    local data = C_TooltipInfo.GetBagItem(bagID, slotID)
    if not (data and data.lines) then return "" end
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