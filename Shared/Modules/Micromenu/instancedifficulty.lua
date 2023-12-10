local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

function MicroMenu:SkinInstanceDifficulty()

    local button = CreateFrame('Button', 'SaftUI_DungeonDifficulty', UIParent)

    st:SetBackdrop(button, 'thick')

    button.Text = st:CreateFontString(button, 'pixel', '10')
    button.Text:SetPoint('BOTTOM', 2, 2)
    button.Text:SetJustifyH('CENTER')

    button.Icon = button:CreateTexture(nil, 'ARTWORK')
    button.Icon:SetPoint('TOP', 0, -4)
    button.Icon:SetAtlas('ui-hud-minimap-guildbanner-heroic-large', true)
    button.Icon:SetSize(14, 14)

    button.Bg = button:CreateTexture(nil, 'BACKGROUND')
    button.Bg:SetTexture(st.BLANK_TEX)
    button.Bg:SetAllPoints()
    button.Bg:SetVertexColor(0.66, 0.40, 0.72)

    st:Hide(MinimapCluster.InstanceDifficulty)
    self:SecureHook(MinimapCluster.InstanceDifficulty, 'Update', 'UpdateDungeonDifficulty')

    return button
end

function MicroMenu:UpdateDungeonDifficulty()
    MinimapCluster.InstanceDifficulty:Hide()
    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty,
        isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
	local name, groupType, isHeroic, isChallengeMode, displayHeroic,
        displayMythic, toggleDifficultyID = GetDifficultyInfo(difficultyID)

    local button = SaftUI_DungeonDifficulty
    button:SetShown(difficultyID ~= 0)

    local text = groupType == 'raid' and instanceGroupSize or ''

    button.Bg:SetAtlas('ui-hud-minimap-guildbanner-background-top', true)
    st:InsetTexture(button.Bg, .2)

    if displayMythic then
        button.Bg:SetVertexColor(unpack(st.config.profile.colors.item_quality[4]))
        button.Icon:SetAtlas('ui-hud-minimap-guildbanner-mythic-large', true)
        text = 'M' .. text
    elseif (isHeroic or displayHeroic) then
        button.Bg:SetVertexColor(unpack(st.config.profile.colors.item_quality[3]))
        button.Icon:SetAtlas('ui-hud-minimap-guildbanner-heroic-large', true)
        text = 'H' .. text
    else
        button.Bg:SetVertexColor(unpack(st.config.profile.colors.item_quality[1]))
        button.Icon:SetTexture('')
    end



    if isDynamic then text = "~" + text end

    button.Text:SetText(text)
end