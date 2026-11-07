local st = SaftUI

function st:CreateScrollFrame(parent, content)
    local scrollFrame = CreateFrame('ScrollFrame', nil, parent, 'ScrollFrameTemplate')
    scrollFrame:SetSize(500, 500)

    st:SkinScrollBar(scrollFrame.ScrollBar)

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
