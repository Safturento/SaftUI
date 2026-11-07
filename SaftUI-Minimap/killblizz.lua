local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local BAG_BUTTONS = {
    "MainMenuBarBackpackButton",
    "CharacterBag0Slot",
    "CharacterBag1Slot",
    "CharacterBag2Slot",
    "CharacterBag3Slot",
    "CharacterReagentBag0Slot",
    "BagBarExpandToggle",
}

function MicroMenu:KillBlizz()
    -- Don't hide Blizzard's micro button alerts from addon code: HideAllSystem
    -- runs their close callback here, which taints the alert globals that the
    -- spellbook reads on show, and that blocks the action bar update after it
    -- in combat (ADDON_ACTION_BLOCKED on MultiBar*:SetFrameStrata/SetShown).

    --self:HideBagSlots()
    -- Blizzard's micro menu isn't hidden; microbuttons.lua restyles it into SaftUI's bar.

    if st.retail then
        if MinimapCluster.BorderTop then
            MinimapCluster.BorderTop:Hide()
        end
    else
        st:Kill(MiniMapWorldMapButton)
        st:Kill(MinimapBorderTop)
        --st:Kill(MinimapBackdrop)
    end
    
    local disable = CreateFrame('frame')
    disable:RegisterEvent('ADDON_LOADED')
    disable:SetScript('OnEvent', function(self, event, addon)
        if addon == 'Blizzard_TimeManager' then
            hooksecurefunc('TimeManagerClockButton_OnLoad', function(self)
                self:Hide()
            end)
        end
        self:UnregisterAllEvents()
    end)
    st:Kill(TimeManagerClockButton)
    GameTimeFrame:Hide()
end

function MicroMenu:HideBagSlots()
    for _,buttonName in pairs(BAG_BUTTONS) do
        if _G[buttonName] then
            _G[buttonName]:SetParent(st.HiddenFrame)
        end
    end
end