local st = SaftUI
local UF = st:GetModule('Unitframes')

local function UpdateConfig(unitframe)
    local auraWatch = unitframe.AuraWatch
    UF:UpdateElement(auraWatch)

    for i, icon in pairs(auraWatch.icons) do
        icon.spellID = auraWatch.config.spells[i].spellId
        UpdateConfig(unitframe)
--         icon:ClearAllPoints()
--         icon:SetPoint(st:UnpackPoint(auraWatch.config.positions[i]))
--         icon:SetSize(auraWatch.config.width, auraWatch.config.height)
    end
end

local function Constructor(unitframe)
    local function createIcons(element)
        element.icons = {}
--         for i, position in pairs(element.config.icons) do
--            element.icons[i] = UF:AddIcon(unitframe, element, 'icon'..i)
--         end
    end

    local auraWatch = UF:AddElement('Frame', unitframe, 'AuraWatch', function(unitframe, element)
        createIcons(element)

    end)

    if not auraWatch.config.enable then return end

    return auraWatch
end

-- UF:RegisterElement('AuraWatch', Constructor, UpdateConfig, GetConfigTable)