local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinExpansionButton()
    local button = ExpansionLandingPageMinimapButton
    st:SetBackdrop(button, 'thick')
    self:SecureHook(button, 'UpdateIcon', 'UpdateExpansionLandingPageButton')
    return button
end

function MicroMenu:UpdateExpansionLandingPageButton()
    local button = ExpansionLandingPageMinimapButton
    button:SetSize(28, 28)
    button:SetHitRectInsets(0, 0, 0, 0)
    button:SetScript('OnEnter', function() end)

    local hover = button:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture(st.BLANK_TEX)
    hover:SetVertexColor(unpack(st.config.profile.colors.button.hover))
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover)

    local pushed = button:GetPushedTexture()
    st:InsetTexture(pushed, 0.2)
    pushed:SetAllPoints()

    local normal = button:GetNormalTexture()
    st:InsetTexture(normal, 0.2)
    normal:SetAllPoints()
end
