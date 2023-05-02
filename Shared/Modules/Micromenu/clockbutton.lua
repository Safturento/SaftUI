local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local function Update(self)
    self.text:SetText(GameTime_GetTime())
end


function MicroMenu:SkinTimeManagerClockButton()
    local button = st:CreateButton('ClockButton', UIParent)
    button.width = 60

    button:SetScript('OnUpdate', Update)
    button:SetScript('OnClick', GameTimeFrame_OnClick)
    return button
    --EnableAddOn('Blizzard_TimeManager')
    --local button = TimeManagerClockButton
    --button.text = TimeManagerClockTicker
    --return button
end
