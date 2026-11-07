local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu')
MicroMenu.Buttons = {}

local BUTTON_SIZE = 25
local BUTTON_SPACING = 8
-- Shared with microbuttons.lua, which sizes Blizzard's micro buttons to the bar
MicroMenu.BUTTON_SIZE = BUTTON_SIZE

-- Items can set .width (default BUTTON_SIZE) and .barTemplate (the backdrop
-- template, default thicktransparent; 'none' for no backdrop).
function MicroMenu:AddButton(button)
    if button then
        tinsert(self.Buttons, button)
    end
end

function MicroMenu:UpdateButtons()
    local prev
    for _,button in pairs(self.Buttons) do
        if button:IsShown() then
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

            st:SetBackdrop(button, button.barTemplate or 'thicktransparent')

            button:ClearAllPoints()
            if prev then
                button:SetPoint('TOPLEFT', prev, 'TOPRIGHT', BUTTON_SPACING, 0)
            else
                button:SetPoint('TOPLEFT', self.Container)
            end

            prev = button
        end
    end

    -- Blizzard's micro buttons sit over their holders, laid out above
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

-- Places the bar from the profile and lays its buttons out again. Runs on every
-- profile change. Blizzard's micro buttons and bar pieces hang off the bar, so
-- in combat this waits until combat ends.
function MicroMenu:UpdateConfig()
    if not self.Container then return end
    if st:QueueAfterCombat('MicroMenu', function() MicroMenu:UpdateConfig() end) then return end

    self.Container:ClearAllPoints()
    self.Container:SetPoint(st:UnpackPoint(self.config.position))
    self:UpdateButtons()
end

function MicroMenu:OnEnable()
    st:BindModuleConfig(self, 'micromenu')
    self.Container = CreateFrame('Frame', 'SaftUI_MicroMenu', UIParent)
    self.Container:SetPoint(st:UnpackPoint(self.config.position))
    self.Container:SetSize(1,1)
    -- No-op to ignore Layout calls for buttons like mail icon
    self.Container.Layout = function() end

    self:KillBlizz()
    self:AddButton(self:SkinZoneTextButton())
    self:AddButton(self:SkinTimeManagerClockButton())
    self:AddButton(self:CreateLatencyButton())
    self:AddButton(self:CreateFramerateButton())
    -- Adds a holder per Blizzard micro button at this spot. The items before
    -- them don't come and go, so the micro buttons stay put while mail, the
    -- queue eye and the like appear after them.
    self:SkinBlizzardMicroMenu()
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
