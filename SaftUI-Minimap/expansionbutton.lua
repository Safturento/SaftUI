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
    self:SecureHook(button, 'UpdateIcon', 'UpdateExpansionLandingPageButton')
    -- Blizzard's tooltip stays off this button. Its scripts aren't replaced
    -- (that would leave an addon function as Blizzard's OnEnter/OnLeave):
    -- Blizzard's OnEnter runs, then this post-hook hides the tooltip it opened,
    -- before it's drawn. Blizzard's OnLeave only hides the tooltip.
    button:HookScript('OnEnter', function(self)
        if GameTooltip:IsOwned(self) then
            GameTooltip:Hide()
        end
    end)
    --MicroMenu:HookScript(button, 'OnEnter', 'ShowRenownTooltip')
    --MicroMenu:HookScript(button, 'OnLeave', 'HideGameTooltip')
    return button
end

local hover -- SaftUI's flat highlight, made once

-- After Blizzard's UpdateIcon, which swaps the button's atlases, sizes it from
-- them and (SetLandingPageIconOffset) re-anchors it to its parent, which is
-- the bar's container.
function MicroMenu:UpdateExpansionLandingPageButton()
    local button = ExpansionLandingPageMinimapButton
    button:SetHitRectInsets(0, 0, 0, 0)

    -- SetLandingPageIconFromAtlases puts an atlas on the highlight, which is
    -- this texture once it's set, so the flat color goes back every time
    if not hover then
        hover = button:CreateTexture(nil, 'OVERLAY')
    end
    hover:SetTexture(st.BLANK_TEX)
    hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
    hover:ClearAllPoints()
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover)

    local pushed = button:GetPushedTexture()
    st:InsetTexture(pushed, 0.2)
    pushed:SetAllPoints()

    local normal = button:GetNormalTexture()
    st:InsetTexture(normal, 0.2)
    normal:SetAllPoints()

    -- Back into its slot in the bar, at the bar's size
    self:UpdateButtons()
end
