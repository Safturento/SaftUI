local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu')
MicroMenu.Buttons = {}

local BUTTON_SIZE = 25
local BUTTON_SPACING = 8
-- Shared with microbuttons.lua, which lays Blizzard's micro buttons out under the bar
MicroMenu.BUTTON_SIZE = BUTTON_SIZE
MicroMenu.BUTTON_SPACING = BUTTON_SPACING

function MicroMenu:AddButton(button)
    if button then
        tinsert(self.Buttons, button)
    end
end

function MicroMenu:UpdateButtons()
    local prev
    local width = 0
    for _,button in pairs(self.Buttons) do
        if button:IsShown() then
            width = width + (button.width or BUTTON_SIZE) + (prev and BUTTON_SPACING or 0)
            button:SetParent(self.Container)
            button:SetSize(button.width or BUTTON_SIZE, BUTTON_SIZE)

            if button.text then
                button.text:SetFontObject(st:GetFont('pixel'))
                button.text:SetJustifyH('CENTER')
                -- Clear Blizzard's anchors (the zone text is LEFT-anchored with a
                -- fixed width) so the text spans the button and centers properly
                button.text:ClearAllPoints()
                button.text:SetPoint('LEFT', button, 'LEFT', 4, 0)
                button.text:SetPoint('RIGHT', button, 'RIGHT', -4, 0)
            end

            st:SetBackdrop(button, 'thicktransparent')

            button:ClearAllPoints()
            if prev then
                button:SetPoint('TOPLEFT', prev, 'TOPRIGHT', BUTTON_SPACING, 0)
            else
                button:SetPoint('TOPLEFT', self.Container)
            end

            prev = button
        end
    end

    -- Blizzard's micro buttons span the bar's width in a row under it
    self.barWidth = width
    self:UpdateBlizzardButtons()
end

function MicroMenu:SkinMailIcon()

    local button = st.retail and MinimapCluster.IndicatorFrame.MailFrame or MiniMapMailFrame

    st:Kill(MiniMapMailBorder)

    MiniMapMailFrame_UpdatePosition = function() end

    MiniMapMailIcon:SetTexture(st.textures.mailSquare)
    MiniMapMailIcon:SetAllPoints(button)

    return button
end

function MicroMenu:SkinTrackingButton()
    if st.retail then
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
        if trackingButton.StateTexture then
            trackingButton.StateTexture:SetAlpha(0)
            trackingButton.AddTexture:SetAlpha(0)
            hooksecurefunc(trackingButton, 'OnButtonStateChanged', function(self)
                self.AddTexture:Hide()
            end)

            local icon = trackingButton:CreateTexture(nil, 'ARTWORK')
            icon:SetTexture([[Interface\Minimap\Tracking\None]])
            icon:SetPoint('CENTER')
            icon:SetSize(16, 16)
            trackingButton.SaftIcon = icon

            local hover = trackingButton:CreateTexture(nil, 'OVERLAY')
            hover:SetTexture(st.BLANK_TEX)
            hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
            hover:SetAllPoints(trackingButton)
            trackingButton:SetHighlightTexture(hover)
        end

        return button
    else
        local button = MiniMapTracking
        MiniMapTrackingButton:SetAllPoints(button)
        st:Kill(MiniMapTrackingButtonBorder)
        st:Kill(MiniMapTrackingBackground)
        MiniMapTrackingIcon:ClearAllPoints()
        MiniMapTrackingIcon:SetAllPoints(button)

        local hover = MiniMapTrackingButton:CreateTexture(nil, 'OVERLAY')
        hover:SetTexture(st.BLANK_TEX)
        hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
        hover:SetAllPoints(MiniMapTrackingButton)
        MiniMapTrackingButton:SetHighlightTexture(hover)

        return button
    end
end

function MicroMenu:OnEnable()
    st:BindModuleConfig(self, 'micromenu')
    self.Container = CreateFrame('Frame', 'SaftUI_MicroMenu', UIParent)
    self.Container:SetPoint('TOPLEFT', UIParent, st.CLAMP_INSET, -st.CLAMP_INSET)
    self.Container:SetSize(1,1)
    -- No-op to ignore Layout calls for buttons like mail icon
    self.Container.Layout = function() end

    self:KillBlizz()
    self:SkinBlizzardMicroMenu()
    self:AddButton(self:SkinZoneTextButton())
    self:AddButton(self:SkinTimeManagerClockButton())
    self:AddButton(self:CreateLatencyButton())
    self:AddButton(self:CreateFramerateButton())
    self:AddButton(self:SkinAddonCompartmentFrame())
    self:AddButton(self:SkinTrackingButton())
    self:AddButton(self:SkinExpansionButton())
    self:AddButton(self:SkinMailIcon())
    self:AddButton(self:SkinInstanceDifficulty())
    self:AddButton(self:SkinQueueButton())

    for _,button in pairs(self.Buttons) do
        self:HookScript(button, 'OnShow', 'UpdateButtons')
        self:HookScript(button, 'OnHide', 'UpdateButtons')
    end

    self:UpdateButtons()
    self:SetupMinimapButtons()
end
