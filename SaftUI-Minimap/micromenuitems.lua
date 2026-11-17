local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- The look SaftUI gives a Blizzard button on the bar (SkinBarButton, which the
-- zone text and the addon compartment take too), and two of the bar's items:
-- the mail icon and the tracking button. The other items have files of their
-- own; micromenu.lua's OnEnable adds them all to the bar.

-- st:SkinButton's look for a Blizzard button: SaftUI's font, Blizzard's art
-- faded out, and the state helper's states (a 'box': the Layer under the mouse
-- and pressed, and the dimmed Alpha while disabled). st:SkinButton itself stores
-- its textures on the button as fields, so it's only for SaftUI's own buttons.
-- The bar draws the backdrop.
local skinned = setmetatable({}, { __mode = 'k' })

-- SaftUI's flat highlight on a Blizzard button, made once: white, BLEND (a
-- highlight handed no blend mode is additive), over the whole button, in the
-- state helper's hands as the hover piece (the game shows it under the mouse;
-- the helper only colors it). Blizzard's own pushed art, where the button has
-- some, is left as it is.
function MicroMenu.SkinHighlight(button)
    local hover = button:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture(st.BLANK_TEX)
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover, 'BLEND')
    -- the bar's items draw their flat look under every theme
    st:AddStates(button, 'icon', { pieces = { hover = hover }, blizzard = function() return false end })
    return hover
end

-- The bar's text font (MicroMenu:TextFont) on a skinned button's label.
-- Font objects only, so in combat too.
local function SetButtonFont(button, font)
    if button.SetNormalFontObject then
        button:SetNormalFontObject(font)
        button:SetHighlightFontObject(font)
        button:SetDisabledFontObject(font)
    end
end

-- For micromenu.lua: every skinned button takes the font again.
MicroMenu.S.ApplyButtonFonts = function(font)
    for button in pairs(skinned) do SetButtonFont(button, font) end
end

function MicroMenu:SkinBarButton(button)
    if skinned[button] then return end
    skinned[button] = true

    SetButtonFont(button, self:TextFont())
    if button.SetPushedTextOffset then
        button:SetPushedTextOffset(0, 0)
    end

    for _, region in pairs({ button:GetRegions() }) do
        if region:GetObjectType() == 'Texture' then
            region:SetAlpha(0)
        end
    end
    button:SetNormalTexture('')

    -- Hover and pressed tint the body (the Layer, under the label); disabled dims
    -- the button. The helper hooks the mouse; Enable and Disable are followed by
    -- post-hooks on the scripts, which only set the state (an alpha).
    st:AddStates(button, 'box', { edge = false, blizzard = function() return false end })
    button:HookScript('OnDisable', function(self) st:SetState(self, 'disabled', true) end)
    button:HookScript('OnEnable', function(self) st:SetState(self, 'disabled', false) end)
    if button.IsEnabled and not button:IsEnabled() then st:SetState(button, 'disabled', true) end
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

        MicroMenu.SkinHighlight(trackingButton)
    end

    -- Under Blizzard it stands on the same box as every item (micromenuart.lua's
    -- UpdateArt), and keeps its own magnifier on it. Live has no magnifier of
    -- SaftUI's: Blizzard's own icon shows.
    return button, { icon = icon }
end
