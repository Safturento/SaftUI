local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- The badge SkinInstanceDifficulty made, and the item quality its color is (1, 3
-- or 4: normal, Heroic, Mythic), kept so a color pass can color it again.
local badge, badgeQuality

-- The badge's color, the item quality the difficulty names (Colors > Item
-- quality). Color only, so it is the whole of what a color pass does here, and
-- UpdateDungeonDifficulty calls it too.
function MicroMenu:ColorDifficulty()
    if not (badge and badgeQuality) then return end
    badge.Bg:SetVertexColor(st.config.profile.colors.item_quality[badgeQuality]:GetRGB())
end

function MicroMenu:SkinInstanceDifficulty()
    -- Forever has no instance difficulty frame
    if not MinimapCluster.InstanceDifficulty then return end

    -- No backdrop of its own: the bar draws every item's panel
    local button = CreateFrame('Button', 'SaftUI_DungeonDifficulty', UIParent)

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
    badge = button

    -- Blizzard's difficulty frame is hidden for good; its Update post-hook
    -- fills in SaftUI's button. It has no OnShow or OnHide script, so hiding
    -- it runs no Blizzard code, and the OnShow post-hook hides it again if
    -- anything shows it.
    local blizzard = MinimapCluster.InstanceDifficulty
    blizzard:Hide()
    blizzard:HookScript('OnShow', blizzard.Hide)
    self:SecureHook(blizzard, 'Update', 'UpdateDungeonDifficulty')

    return button
end

function MicroMenu:UpdateDungeonDifficulty()
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
        badgeQuality = 4
        button.Icon:SetAtlas('ui-hud-minimap-guildbanner-mythic-large', true)
        text = 'M' .. text
    elseif (isHeroic or displayHeroic) then
        badgeQuality = 3
        button.Icon:SetAtlas('ui-hud-minimap-guildbanner-heroic-large', true)
        text = 'H' .. text
    else
        badgeQuality = 1
        button.Icon:SetTexture('')
    end
    self:ColorDifficulty()



    if isDynamic then text = "~" .. text end

    button.Text:SetText(text)
end