local st = SaftUI
local Util = st:GetModule('Utilities')

Util.TooltipCache = {}

function Util:ScanItemLink(itemLink)
    if not C_TooltipInfo then return "" end

    if self.TooltipCache[itemLink] then
        return self.TooltipCache[itemLink]
    end

    local data = C_TooltipInfo.GetHyperlink(itemLink)
    -- The tooltip may not have arrived (an item filed after its tooltip never
    -- came): no text, and nothing cached, so a later scan can fill it in.
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
    self.TooltipCache[itemLink] = text
    return text
end

function Util:ScanBagItem(bagId, slotId)
    return self:ScanItemLink(C_Container.GetContainerItemLink(bagId, slotId))
end

function Util:ScanEquipmentSlotItem(equipSlotId)
    return self:ScanItemLink(GetInventoryItemLink('player', equipSlotId))
end