local st = SaftUI
local INV = st:GetModule('Inventory')

-- How many reads of one link may find its tooltip not ready before the item
-- is read as having no text, and how long until ReadBags' retry.
INV.TOOLTIP_TRIES = 10
INV.TOOLTIP_RETRY = 0.5

function INV:InitializeTooltipScanner()
    self.cache = {}
    self.tooltipTries = {}
end

--[[
	An item's tooltip text: `text`, the lines joined as they always were and
	passed through string.unmagic, and `raw`, the same lines as the client gave
	them. Both are cached per link. `ready` is false while the tooltip hasn't
	arrived (C_TooltipInfo exists, the slot has a link, and GetBagItem gives no
	data or no lines); nothing is cached then. After INV.TOOLTIP_TRIES reads of
	one link that weren't ready it is true with '', and a fourth value,
	`missing`, true (the item's text never arrived, so auto vendor won't sell
	it), still uncached, so a later read can fill it in. With no C_TooltipInfo,
	or no link: '', '', true. peek reads without counting a try (a read only to
	show the bags, as the Categories tab's), so it never brings the give-up
	nearer.
]]
function INV:ScanBagItem(bagID, slotID, peek)
    if not C_TooltipInfo then return '', '', true end
    local itemLink = C_Container.GetContainerItemLink(bagID, slotID)
    if not itemLink then return '', '', true end

    local cached = self.cache[itemLink]
    if cached then return cached.text, cached.raw, true end

    -- GetBagItem can return nothing (e.g. data not ready yet); don't cache that.
    local data = C_TooltipInfo.GetBagItem(bagID, slotID)
    if not (data and data.lines) then
        local tries = self.tooltipTries[itemLink] or 0
        if tries >= self.TOOLTIP_TRIES then return '', '', true, true end
        if not peek then self.tooltipTries[itemLink] = tries + 1 end
        return '', '', false
    end
    local raw = ""
    for _,lines in pairs(data.lines) do
        if lines.leftText then
            raw = raw .. " " .. lines.leftText
        end
        if lines.rightText then
            raw = raw .. " " .. lines.rightText
        end
    end
    local text = string.unmagic(raw)
    self.cache[itemLink] = { text = text, raw = raw }
    self.tooltipTries[itemLink] = nil
    return text, raw, true
end

-- ReadBags met an item waiting for its tooltip: one update after
-- INV.TOOLTIP_RETRY, however many items wait.
function INV:QueueTooltipRetry()
    if self.tooltipRetryPending then return end
    self.tooltipRetryPending = true
    C_Timer.After(self.TOOLTIP_RETRY, function()
        INV.tooltipRetryPending = nil
        INV:QueueUpdate(true)
    end)
end
