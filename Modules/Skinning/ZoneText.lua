local st = SaftUI
local SK = st:GetModule('Skinning')
local ZT = SK:NewModule('ZoneText')

local colors = {
    lfr    = '68de57',
    normal = 'ffeac2',
    heroic = '5794de',
    mythic = 'a357de',
}

function ZT:SetZoneDifficultyText()
    local name, instanceType, difficultyID, difficultyName,
    maxPlayers, dynamicDifficulty, isDynamic, instanceID,
    instanceGroupSize, LfgDungeonID = GetInstanceInfo()

    local name, groupType, isHeroic, isChallengeMode, displayHeroic,
    displayMythic, toggleDifficultyID, isLFR, minPlayers,
    _ = GetDifficultyInfo(difficultyID)

    if maxPlayers  == 0 or GetZoneText() == ZoneTextFrame.zoneText then
        self.DifficultyTextString:SetText("")
        return
    end

    local color
    if displayMythic then
        color = colors.mythic
    elseif isHeroic or displayHeroic then
        color = colors.heroic
    elseif isLFR then
        color = colors.lfr
    else
        color = colors.normal
    end

    self.DifficultyTextString:SetText(st.StringFormat:ColorString(difficultyName, color))
end

function ZT:OnEvent(frame, event, ...)
    local zoneTextColor = { ZoneTextString:GetTextColor() }
    ZoneTextFrame.LeftFlourish.backdrop:SetBackdropColor(unpack(zoneTextColor))
    ZoneTextFrame.RightFlourish.backdrop:SetBackdropColor(unpack(zoneTextColor))

    self:SetZoneDifficultyText()
end

function ZT:OnInitialize()
    ZoneTextFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    ZT:HookScript(ZoneTextFrame, 'OnEvent')
    ZoneTextFrame:SetPoint('TOP', 0, -300)

    ZoneTextString:SetFontObject(st:GetFont('title'))
    PVPInfoTextString:SetFontObject(st:GetFont('subtitle'))
    SubZoneTextString:SetFontObject(st:GetFont('subtitle'))
    PVPArenaTextString:SetFontObject(st:GetFont('subtitle'))
    self.DifficultyTextString = st:CreateFontString(SubZoneTextFrame, 'subtitle', 'test')
    self.DifficultyTextString:SetPoint('TOP', SubZoneTextString, 'BOTTOM', 0, -7)

    ZoneFadeInDuration = 1;
    ZoneHoldDuration = 2;
    ZoneFadeOutDuration = 2;

    FadingFrame_SetFadeInTime(ZoneTextFrame, ZoneFadeInDuration)
    FadingFrame_SetHoldTime(ZoneTextFrame, ZoneHoldDuration)
    FadingFrame_SetFadeOutTime(ZoneTextFrame, ZoneFadeOutDuration)

    FadingFrame_SetFadeInTime(SubZoneTextFrame, ZoneFadeInDuration);
	FadingFrame_SetHoldTime(SubZoneTextFrame, ZoneHoldDuration);
	FadingFrame_SetFadeOutTime(SubZoneTextFrame, ZoneFadeOutDuration);

    for _,side in pairs({'Left', 'Right'}) do
        local flourish = st:CreateFrame('Frame', nil, ZoneTextFrame)
        flourish:SetSize(100, 2)
        st:SetBackdrop(flourish, 'thin')
        ZoneTextString:SetWidth(0)
        if side == 'Left' then
            flourish:SetPoint('RIGHT', ZoneTextString, 'LEFT', -20, 0)
        else
            flourish:SetPoint('LEFT', ZoneTextString, 'RIGHT', 20, 0)
        end
        ZoneTextFrame[side .. 'Flourish'] = flourish
    end
end