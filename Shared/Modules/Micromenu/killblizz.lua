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
end

function MicroMenu:HideMicroMenu()
    for _,buttonName in pairs(MICRO_BUTTONS) do
        _G[buttonName]:SetParent(st.hidden_frame)
    end

    MicroButtonAndBagsBar:SetParent(st.hidden_frame)
    MicroButtonAndBagsBar:UnregisterAllEvents()
end

function MicroMenu:HideBagSlots()
    for _,buttonName in pairs(BAG_BUTTONS) do
        _G[buttonName]:SetParent(st.hidden_frame)
    end
end