local st = SaftUI

function st:CreateScrollFrame(parent, content)
    local scrollFrame = CreateFrame('ScrollFrame', nil, parent, 'ScrollFrameTemplate')
    scrollFrame:SetSize(500, 500)

    st:SkinScrollBar(scrollFrame.ScrollBar)

    content = content or st:CreateFrame('Frame', nil, scrollFrame)
    content:SetParent(scrollFrame)
    scrollFrame:SetScrollChild(content)
    scrollFrame.ScrollChild = content

    scrollFrame.SetContentSize = function(self, width, height) content:SetSize(width, height) end

    return scrollFrame
end
