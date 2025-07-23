local st = SaftUI
local Util = st:GetModule('Utilities')

local upgradeQualities = {
	Adventurer = 1,
	Veteran = 2,
	Champion = 3,
	Hero = 4,
	Myth = 5,
}

function Util:SetItemQualityLevelText(equipSlot, level, maxLevel, anchor)
    anchor = anchor or equipSlot
    if not equipSlot.qualityText then
        equipSlot.qualityText = equipSlot:CreateFontString(nil, 'OVERLAY')
        equipSlot.qualityText:SetFontObject(st:GetFont('pixel'))
        equipSlot.qualityText:SetPoint('TOPRIGHT', anchor, 2, 0)
        equipSlot.qualityText:SetDrawLayer("OVERLAY", 7);

        local textbg = equipSlot:CreateTexture(nil, 'OVERLAY')
        textbg:SetDrawLayer('OVERLAY', -8)
        textbg:SetPoint('TOPRIGHT', anchor)
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

function Util:SetItemQuality(button, link, anchor)
    if not st.retail then return end
    ClearItemCraftingQualityOverlay(button)
    if not Util:SetItemUpgradeQuality(button, link, anchor) then
        SetItemCraftingQualityOverlay(button, link)
    end
end

function Util:ClearItemQuality(button)
    if not st.retail then return end
        ClearItemCraftingQualityOverlay(button)
        button.professionQualityOverlayOverride = nil
        if button.qualityText then
            button.qualityText:SetText('')
        end
end

function Util:SetItemUpgradeQuality(button, itemLink, anchor)
    if not st.retail then return end
    local quality, level, maxLevel = Util:ScanItemLink(itemLink):match("Upgrade Level: (%w+) (%d)/(%d)")
    button.alwaysShowProfessionsQuality = true

    if quality then
        button.isProfessionItem = true
        SetItemCraftingQualityOverlayOverride(button, upgradeQualities[quality])
        self:SetItemQualityLevelText(button, level, maxLevel, anchor)
        return true
    end

    return false
end

function Util:SetItemUpgradeQualityForBagSlot(button, bagId, slotId)
    Util:SetItemUpgradeQuality(
        button,
        C_Container.GetContainerItemLink(bagId, slotId)
    )
end

function Util:SetItemUpgradeQualityForEquipmentSlot(equipSlot, equipSlotId)
    Util:SetItemUpgradeQuality(
        equipSlot,
        GetInventoryItemLink('player', equipSlotId)
    )
end