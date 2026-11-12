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
    local text = string.unmagic(st.TooltipLinesText(data.lines))
    self.TooltipCache[itemLink] = text
    return text
end
