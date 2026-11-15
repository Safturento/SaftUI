local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- The look SaftUI gives a Blizzard button on the bar (SkinBarButton, which the
-- zone text and the addon compartment take too), and two of the bar's items:
-- the mail icon and the tracking button. The other items have files of their
-- own; micromenu.lua's OnEnable adds them all to the bar.

-- st:SkinButton's look for a Blizzard button: SaftUI's font, Blizzard's art
-- faded out, and flat hover, pushed and disabled textures. st:SkinButton
-- itself stores those (and a backdrop) on the button as fields, so it's only
-- for SaftUI's own buttons. The bar draws the backdrop.
local skinned = setmetatable({}, { __mode = 'k' })
function MicroMenu:SkinBarButton(button)
    if skinned[button] then return end
    skinned[button] = true

    local font = st:GetFont('pixel')
    if button.SetNormalFontObject then
        button:SetNormalFontObject(font)
        button:SetHighlightFontObject(font)
        button:SetDisabledFontObject(font)
        button:SetPushedTextOffset(0, 0)
    end

    for _, region in pairs({ button:GetRegions() }) do
        if region:GetObjectType() == 'Texture' then
            region:SetAlpha(0)
        end
    end
    button:SetNormalTexture('')

    local hover = button:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture(st.BLANK_TEX)
    hover:SetVertexColor(st:ColorRGBA('button', 'normal'))
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover)

    local pushed = button:CreateTexture(nil, 'OVERLAY')
    pushed:SetTexture(st.BLANK_TEX)
    pushed:SetVertexColor(st:ColorRGBA('button', 'pushed'))
    pushed:SetAllPoints(button)
    button:SetPushedTexture(pushed)

    local disabled = button:CreateTexture(nil, 'OVERLAY')
    disabled:SetTexture(st.BLANK_TEX)
    disabled:SetVertexColor(0, 0, 0, .4)
    disabled:SetAllPoints(button)
    button:SetDisabledTexture(disabled)
end

function MicroMenu:SkinMailIcon()

    local button = MinimapCluster.IndicatorFrame.MailFrame

    MiniMapMailIcon:SetTexture(st.textures.mailSquare)
    MiniMapMailIcon:SetAllPoints(button)

    return button
end

function MicroMenu:SkinTrackingButton()
    local button = MinimapCluster.TrackingFrame or MinimapCluster.Tracking
    button.Button:SetAllPoints()

    for _,texture in pairs({
        button.Button:GetNormalTexture(),
        button.Button:GetPushedTexture(),
        button.Button:GetHighlightTexture()
    }) do
        texture:ClearAllPoints()
        texture:SetPoint("CENTER")
        texture:SetSize(16, 16)
    end

    -- Forever draws the icon as a single atlas with a gold ring baked in, and
    -- re-applies it on every button state change. Hide it and its hover copy,
    -- and draw a plain magnifier instead.
    local trackingButton = button.Button
    local icon
    if trackingButton.StateTexture then
        trackingButton.StateTexture:SetAlpha(0)
        trackingButton.AddTexture:SetAlpha(0)
        hooksecurefunc(trackingButton, 'OnButtonStateChanged', function(self)
            self.AddTexture:Hide()
        end)

        icon = trackingButton:CreateTexture(nil, 'ARTWORK')
        icon:SetTexture([[Interface\Minimap\Tracking\None]])
        icon:SetPoint('CENTER')
        icon:SetSize(16, 16)

        local hover = trackingButton:CreateTexture(nil, 'OVERLAY')
        hover:SetTexture(st.BLANK_TEX)
        hover:SetVertexColor(st:ColorRGBA('button', 'hover'))
        hover:SetAllPoints(trackingButton)
        trackingButton:SetHighlightTexture(hover)
    end

    -- Under Blizzard it stands on Blizzard's tracking button (micromenuart.lua's UpdateArt).
    -- Forever's has the magnifier drawn in, so SaftUI's hides there. Live
    -- has no magnifier of SaftUI's: Blizzard's own icon shows on its box.
    return button, { art = 'tracking', icon = icon }
end
