local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinQueueButton()

    local button = QueueStatusButton
    button:SetHitRectInsets(0,0, 0, 0)
    st:SetBackdrop(button, 'thick')

    button.Eye:Hide()

    --Setup a static eye texture
    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetAtlas("groupfinder-eye-single", true)
    st:SetTexCoord(icon, 0.2)
    button:SetNormalTexture(icon)

    local hover = button:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture(st.BLANK_TEX)
    hover:SetVertexColor(unpack(st.config.profile.colors.button.hover))
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover)

    return button
end


