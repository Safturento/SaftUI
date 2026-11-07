local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local function Update(self)
    self.text:SetText(GameTime_GetTime())
end

-- Blizzard's clock is hidden with Hide() and kept hidden by a post-hook, since
-- Blizzard shows it again when an alarm fires. It has no OnShow or OnHide
-- script, so no Blizzard code runs from either call. Not st:Kill: that
-- replaces the frame's Show, which Blizzard's alarm code then calls.
local function HideBlizzardClock()
    local clock = TimeManagerClockButton
    clock:Hide()
    clock:HookScript('OnShow', clock.Hide)
end

function MicroMenu:KillBlizzard_TimeManager()
    if TimeManagerClockButton then
        HideBlizzardClock()
        return
    end

    -- Blizzard_TimeManager is load on demand
    local frame = CreateFrame('frame')
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript('OnEvent', function(self, event, addon)
        if addon == 'Blizzard_TimeManager' then
            self:UnregisterAllEvents()
            HideBlizzardClock()
        end
    end)
end

function MicroMenu:SkinTimeManagerClockButton()
    self:KillBlizzard_TimeManager()

    -- No backdrop of its own: the bar draws every item's panel
    local button = st:CreateButton('ClockButton', UIParent, nil, 'none')

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
    return button, { width = 60, text = button.text }
end
