local st = SaftUI
local Util = st:GetModule('Utilities')

Util.TooltipCache = {}

function Util:ScanItemLink(itemLink)
    if self.TooltipCache[itemLink] then
        return self.TooltipCache[itemLink]
    end

    local data = C_TooltipInfo.GetHyperlink(itemLink)
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
    self.TooltipCache[itemLink] = text
    return text
end

function Util:ScanBagItem(bagId, slotId)
    return self:ScanItemLink(C_Container.GetContainerItemLink(bagId, slotId))
end

function Util:ScanEquipmentSlotItem(equipSlotId)
    return self:ScanItemLink(GetInventoryItemLink('player', equipSlotId))
end