local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu', 'AceHook-3.0', 'AceEvent-3.0')
MicroMenu.Buttons = {}

local BUTTON_SIZE = 25

function MicroMenu:AddButton(button)
    tinsert(self.Buttons, button)
end

function MicroMenu:UpdateButtons()
    local prev
    for _,button in pairs(self.Buttons) do
        if button:IsShown() then
            button:SetParent(self.Container)
            button:SetSize(button.width or BUTTON_SIZE, BUTTON_SIZE)

            button:ClearAllPoints()
            if prev then
                button:SetPoint('TOPLEFT', prev, 'TOPRIGHT', 8, 0)
            else
                button:SetPoint('TOPLEFT', self.Container)
            end

            prev = button
        end
    end

end

function MicroMenu:SkinMailIcon()
    local button = MinimapCluster.IndicatorFrame.MailFrame
    st:SetBackdrop(button, 'thick')

    MiniMapMailFrame_UpdatePosition = function()  end

    MiniMapMailIcon:SetTexture(st.textures.mailSquare)
    MiniMapMailIcon:SetAllPoints(button)

    return button
end

function MicroMenu:OnInitialize()
    self.Container = CreateFrame('Frame', 'SaftUI_MicroMenu', UIParent)
    self.Container:SetPoint('TOPLEFT', UIParent, st.CLAMP_INSET, -st.CLAMP_INSET)
    self.Container:SetSize(1,1)
    -- No-op to ignore Layout calls for buttons like mail icon
    self.Container.Layout = function() end

    self:KillBlizz()
    self:AddButton(self:CreateLatencyButton())
    self:AddButton(self:CreateFramerateButton())
    self:AddButton(self:SkinExpansionButton())
    self:AddButton(self:SkinMailIcon())
    self:AddButton(self:SkinInstanceDifficulty())
    self:AddButton(self:SkinQueueButton())

    for _,button in pairs(self.Buttons) do
        self:HookScript(button, 'OnShow', 'UpdateButtons')
        self:HookScript(button, 'OnHide', 'UpdateButtons')
    end

    self:UpdateButtons()
end
