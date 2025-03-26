local st = SaftUI
local SK = st:GetModule('Skinning')
local WR = SK:NewModule('Blizzard_WeeklyRewards')

function WR:ADDON_LOADED(event, addon)
    -- Don't blackout the vault rewards remotely.. why is this even a thing?
    if not WeeklyRewardsFrame then return end
    WeeklyRewardsFrame.ShouldShowOverlay = function() return false end
end

function WR:OnInitialize()
    WR:RegisterEvent("ADDON_LOADED")
end
