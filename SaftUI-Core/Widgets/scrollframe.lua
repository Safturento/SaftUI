local st = SaftUI

-- Where Blizzard's ScrollFrameTemplate puts its scroll bar, from the scroll
-- frame's right edge, and how wide the bar is, when the bar's own anchors can't
-- be read (SCROLL_FRAME_SCROLL_BAR_OFFSET_LEFT, MinimalScrollBar's width).
local BAR_OFFSET, BAR_WIDTH = 6, 8

-- How far past a scroll frame's right edge its scroll bar reaches: the room a
-- window around the frame needs on the right for the bar to sit inside it.
-- Read from the bar's real anchor and width.
function st:ScrollBarRoom(scrollFrame)
    local bar = scrollFrame.ScrollBar
    if not bar then return 0 end
    local offset = BAR_OFFSET
    for i = 1, bar:GetNumPoints() do
        local point, relativeTo, _, x = bar:GetPoint(i)
        if point == 'TOPLEFT' and relativeTo == scrollFrame then offset = x or offset end
    end
    local width = bar:GetWidth()
    return offset + (width and width > 0 and width or BAR_WIDTH)
end

function st:CreateScrollFrame(parent, content)
    local scrollFrame = CreateFrame('ScrollFrame', nil, parent, 'ScrollFrameTemplate')
    scrollFrame:SetSize(500, 500)

    st:SkinScrollBar(scrollFrame.ScrollBar)
    -- The template leaves the bar showing when there is nothing to scroll; it
    -- hides itself instead, so a window that fits has no bar hanging off it.
    if scrollFrame.ScrollBar.SetHideIfUnscrollable then
        scrollFrame.ScrollBar:SetHideIfUnscrollable(true)
    end

    content = content or st:CreateFrame('Frame', nil, scrollFrame)
    content:SetParent(scrollFrame)
    scrollFrame:SetScrollChild(content)
    scrollFrame.ScrollChild = content

    -- A ScrollFrame keeps its own picture of the scroll child's size and only refreshes
    -- it when told to. Without this, content resized after the frame was shown (the bags'
    -- first open after a reload) stays drawn at its old 0x0 size, i.e. not at all.
    scrollFrame.SetContentSize = function(self, width, height)
        content:SetSize(width, height)
        self:UpdateScrollChildRect()
    end

    return scrollFrame
end
