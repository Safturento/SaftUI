local st = SaftUI
local Util = st:GetModule('Utilities')

local upgradeQualities = {
	Adventurer = 1,
	Veteran = 2,
	Champion = 3,
	Hero = 4,
	Myth = 5,
}

function Util:SetItemQualityLevelText(equipSlot, level, maxLevel)
    if not equipSlot.qualityText then
        equipSlot.qualityText = equipSlot:CreateFontString(nil, 'OVERLAY')
        equipSlot.qualityText:SetFontObject(st:GetFont('pixel'))
        equipSlot.qualityText:SetPoint('TOPRIGHT', equipSlot, 2, 0)
        equipSlot.qualityText:SetDrawLayer("OVERLAY", 7);

        local textbg = equipSlot:CreateTexture(nil, 'OVERLAY')
        textbg:SetDrawLayer('OVERLAY', -8)
        textbg:SetPoint('TOPRIGHT', equipSlot)
        textbg:SetPoint('BOTTOMLEFT', equipSlot.qualityText, -2, -1)
        textbg:SetTexture(st.BLANK_TEX)
        textbg:SetAlpha(0.8)
        textbg:SetVertexColor(0,0,0)
        equipSlot.qualityText.bg = textbg
    end

    if level and maxLevel and level ~= maxLevel then
        equipSlot.qualityText:SetText(("%d/%d"):format(level, maxLevel))
    else
        equipSlot.qualityText:SetText('')
    end
end

function Util:SetItemUpgradeQuality(equipSlot, itemLink)
    if not st.retail then return end
    local quality, level, maxLevel = Util:ScanItemLink(itemLink):match("Upgrade Level: (%w+) (%d)/(%d)")
    if quality then
        equipSlot.isProfessionItem = true
        equipSlot.alwaysShowProfessionsQuality = true
        SetItemCraftingQualityOverlayOverride(equipSlot, upgradeQualities[quality])
        self:SetItemQualityLevelText(equipSlot, level, maxLevel)
    end
end

function Util:SetItemUpgradeQualityForBagSlot(equipSlot, bagId, slotId)
    Util:SetItemUpgradeQuality(
        equipSlot,
        C_Container.GetContainerItemLink(bagId, slotId)
    )
end

function Util:SetItemUpgradeQualityForEquipmentSlot(equipSlot, equipSlotId)
    Util:SetItemUpgradeQuality(
        equipSlot,
        GetInventoryItemLink('player', equipSlotId)
    )
end