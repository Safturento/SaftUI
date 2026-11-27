local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- Whether the clock shows local time or the realm's is Blizzard's own setting,
-- the one its time manager's Use Local Time box sets: the game keeps it, so the
-- choice lasts across sessions and matches Blizzard's clock, tooltip and alarm.
local USE_LOCAL = 'timeMgrUseLocalTime'

-- The choice made in combat, set once the fight ends (SaftUI changes a game
-- setting out of combat only, .agents/taint.md), nil when none waits.
local pending

-- True while the clock shows local time
function MicroMenu:ClockIsLocal()
    if pending ~= nil then return pending end
    return C_CVar.GetCVarBool(USE_LOCAL) == true
end

-- The clock's text: local or realm time, by the choice
function MicroMenu:ClockText()
    if self:ClockIsLocal() then
        return (GameTime_GetLocalTime())
    end
    return (GameTime_GetGameTime())
end

-- Shows local time (true) or the realm's (false). With Blizzard's time manager
-- loaded, its own toggle sets the setting, so its cached copy (which the alarm
-- reads) and its Use Local Time box agree; before that, the setting alone, which
-- the time manager reads when it loads.
function MicroMenu:SetClockLocal(isLocal)
    isLocal = isLocal and true or false
    if InCombatLockdown() then
        pending = isLocal
        st:QueueAfterCombat('ClockTime', function()
            local choice = pending
            pending = nil
            if choice ~= nil then MicroMenu:SetClockLocal(choice) end
        end)
        return
    end
    pending = nil
    if isLocal == (C_CVar.GetCVarBool(USE_LOCAL) == true) then return end

    if TimeManager_ToggleLocalTime then
        TimeManager_ToggleLocalTime()
        -- Blizzard's own box does this after its toggle: the alarm is checked
        -- against the other time now
        if TimeManager_StartCheckingAlarm then TimeManager_StartCheckingAlarm() end
        if TimeManagerLocalTimeCheck then TimeManagerLocalTimeCheck:SetChecked(isLocal) end
    else
        C_CVar.SetCVar(USE_LOCAL, isLocal and '1' or '0')
    end
end

function MicroMenu:ToggleClockTime()
    self:SetClockLocal(not self:ClockIsLocal())
end

-- What a left click opens. Blizzard's calendar button is GameTimeFrame (hidden
-- by KillBlizz); on both clients its click is the mixin's OnClick (the old
-- global GameTimeFrame_OnClick is gone), which also opens a pending invite.
local function OpenCalendar()
    if GameTimeFrame and GameTimeFrame.OnClick then
        GameTimeFrame:OnClick()
    elseif ToggleCalendar then
        ToggleCalendar()
    end
end

local function OpenTimeManager(button)
    if not TimeManager_Toggle then
        -- Blizzard_TimeManager is load on demand
        if not (TimeManager_LoadUI and TimeManager_LoadUI()) then return end
    end
    TimeManager_Toggle()
    st:EnableMoving(TimeManagerFrame)
    TimeManagerFrame:ClearAllPoints()
    TimeManagerFrame:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -4)
end

function MicroMenu:OnClockClick(button, mouseButton)
    if mouseButton == 'RightButton' then
        self:ToggleClockTime()
        if GameTooltip:IsOwned(button) then self:ShowClockTooltip(button) end
    elseif IsShiftKeyDown() then
        OpenTimeManager(button)
    else
        OpenCalendar()
    end
end

function MicroMenu:ShowClockTooltip(button)
    GameTooltip:SetOwner(button, 'ANCHOR_NONE')
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint('TOPLEFT', button, 'BOTTOMLEFT', 0, -8)
    GameTooltip:ClearLines()
    local isLocal = self:ClockIsLocal()
    GameTooltip:AddLine(isLocal and 'Local time' or 'Realm time', 1, 1, 1)
    GameTooltip:AddDoubleLine('Realm time', (GameTime_GetGameTime(true)), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine('Local time', (GameTime_GetLocalTime(true)), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddLine(' ')
    GameTooltip:AddLine('Click: calendar', 0.7, 0.7, 0.7)
    GameTooltip:AddLine('Right-click: show ' .. (isLocal and 'realm' or 'local') .. ' time', 0.7, 0.7, 0.7)
    GameTooltip:AddLine('Shift-click: alarm and stopwatch', 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function Update(self)
    self.text:SetText(MicroMenu:ClockText())
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
    st:OnBlizzardAddon('Blizzard_TimeManager', HideBlizzardClock)
end

function MicroMenu:SkinTimeManagerClockButton()
    self:KillBlizzard_TimeManager()

    -- No backdrop of its own: the bar draws every item's panel
    local button = st:CreateButton('ClockButton', UIParent, nil, 'none', 'theme', 'pixel')

    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:SetScript('OnUpdate', Update)
    button:SetScript('OnClick', function(frame, mouseButton) MicroMenu:OnClockClick(frame, mouseButton) end)
    button:HookScript('OnEnter', function(frame) MicroMenu:ShowClockTooltip(frame) end)
    button:HookScript('OnLeave', function(frame)
        if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
    end)
    return button, { width = 60, text = button.text }
end
