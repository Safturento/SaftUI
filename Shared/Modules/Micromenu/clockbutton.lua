local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local function Update(self)
    self.text:SetText(GameTime_GetTime())
end

function MicroMenu:KillBlizzard_TimeManager()
    local frame = CreateFrame('frame')
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript('OnEvent', function(self, event, addon)
        if event == 'ADDON_LOADED' and addon == 'Blizzard_TimeManager' then
            st:Kill(TimeManagerClockButton)
            self:UnregisterAllEvents()
        end
    end)
end

function MicroMenu:SkinTimeManagerClockButton()
    self:KillBlizzard_TimeManager()

    local button = st:CreateButton('ClockButton', UIParent)
    button.width = 60

    button:SetScript('OnUpdate', Update)
    button:SetScript('OnClick', function()
        if IsShiftKeyDown() then
            TimeManager_Toggle();
            st:EnableMoving(TimeManagerFrame)
            TimeManagerFrame:ClearAllPoints()
            TimeManagerFrame:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -4)
        else
            GameTimeFrame_OnClick()
        end
    end)
    return button
end
