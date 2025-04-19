local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:ShowRenownTooltip(button)

    GameTooltip_ShowProgressBar(GameTooltip, 0, 0, 0, "")
    GameTooltip_ClearProgressBars(GameTooltip)

    --GameTooltip:SetOwner(button, 'ANCHOR_BOTTOMRIGHT')
    GameTooltip:SetOwner(button, "ANCHOR_NONE");
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -7)
    GameTooltip_AddNormalLine(GameTooltip, "Renown")
    GameTooltip_AddProgressBar(GameTooltip, 0, 2500, 1200, "Council of Dornogal (Rank 7)")
    GameTooltip:SetMinimumWidth(300)
    GameTooltip:Show()
end

function MicroMenu:HideGameTooltip()
    GameTooltip:Hide()
end

function MicroMenu:SkinExpansionButton()
    if not ExpansionLandingPageMinimapButton then return end

    local button = ExpansionLandingPageMinimapButton
    st:SetBackdrop(button, 'thick')
    self:SecureHook(button, 'UpdateIcon', 'UpdateExpansionLandingPageButton')
    button:SetScript('OnEnter', st.dummy)
    button:SetScript('OnLeave', st.dummy)
    --MicroMenu:HookScript(button, 'OnEnter', 'ShowRenownTooltip')
    --MicroMenu:HookScript(button, 'OnLeave', 'HideGameTooltip')
    return button
end

function MicroMenu:UpdateExpansionLandingPageButton()
    local button = ExpansionLandingPageMinimapButton
    button:SetSize(28, 28)
    button:SetHitRectInsets(0, 0, 0, 0)

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
