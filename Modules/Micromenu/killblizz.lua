local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"GuildMicroButton",
	"LFDMicroButton",
	"EJMicroButton",
	"CollectionsMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton",
	"StoreMicroButton",
}

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
    hooksecurefunc("MainMenuMicroButton_ShowAlert", function() HelpTip:HideAllSystem("MicroButtons") end)

    self:HideBagSlots()
    self:HideMicroMenu()

    if st.retail then
        MinimapCluster.BorderTop:Hide()
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
    GameTimeFrame:Hide()
end

function MicroMenu:HideMicroMenu()
    for _,buttonName in pairs(MICRO_BUTTONS) do
        if _G[buttonName] then
            _G[buttonName]:SetParent(st.hidden_frame)
        end
    end

    --This breaks dungeon finder icon, need to find what event needs to stay registered
    --MicroButtonAndBagsBar:SetParent(st.hidden_frame)
    --MicroButtonAndBagsBar:UnregisterAllEvents()
end

function MicroMenu:HideBagSlots()
    for _,buttonName in pairs(BAG_BUTTONS) do
        if _G[buttonName] then
            _G[buttonName]:SetParent(st.hidden_frame)
        end
    end
end