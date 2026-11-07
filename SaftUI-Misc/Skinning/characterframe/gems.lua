local st = SaftUI
local CF = st:GetModule('Skinning'):GetModule('CharacterFrame')

function CF:ShowGemTooltip(gemSlot)
	if gemSlot.itemId then
		local _, itemLink = C_Item.GetItemInfo(gemSlot.itemId)
		if not itemLink then return end
		GameTooltip:SetOwner(gemSlot, 'ANCHOR_NONE')
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint('TOPLEFT', gemSlot, 'BOTTOMLEFT', 0, -7)
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end
end

function CF:CreateSlotGems(equipSlot, position)
	local gems = CreateFrame('frame', nil, equipSlot)
	for i=1, 4 do
		local gemSlot = st:CreateFrame('frame', nil, gems)
		gems[i] = gemSlot
		st:SetBackdrop(gemSlot, 'thick')
		gemSlot:SetSize(20, 20)
		gemSlot:Hide()

		gemSlot.icon = gemSlot:CreateTexture(nil, 'OVERLAY')
		st:SkinIcon(gemSlot.icon)
		gemSlot.icon:SetAllPoints()

        self:HookScript(gemSlot, 'OnEnter', 'ShowGemTooltip')
		st:HookScript(gemSlot, 'OnLeave', 'HideGameTooltip')

		if i == 1 then
			if position == 'LEFT' then
				gemSlot:SetPoint('TOPLEFT', equipSlot, 'TOPRIGHT', 7, 0)
			elseif position == 'RIGHT' then
				gemSlot:SetPoint('TOPRIGHT', equipSlot, 'TOPLEFT', -7, 0)
			elseif position == 'BOTTOM' then
				gemSlot:SetPoint('BOTTOMLEFT', equipSlot, 'TOPLEFT', 0, 7)
			end
		else
			if position == 'LEFT' then
				gemSlot:SetPoint('TOPLEFT', gems[i-1], 'TOPRIGHT', 7, 0)
			elseif position == 'RIGHT' then
				gemSlot:SetPoint('TOPRIGHT', gems[i-1], 'TOPLEFT', -7, 0)
			elseif position == 'BOTTOM' then
				gemSlot:SetPoint('BOTTOMLEFT', gems[i-1], 'TOPLEFT', 0, 7)
			end
		end
	end

	return gems
end

function CF:UpdateSlotGems(gems, itemLink)
	if not itemLink then gems:Hide() return end
	gems:Show()
	for i=1, 4 do
		local _, gemLink = C_Item.GetItemGem(itemLink, i)
		local gemButton = gems[i]
		if gemLink then
			local itemId = C_Item.GetItemIDForItemInfo(gemLink)
			gemButton:Show()
			gemButton.itemId = itemId
			gemButton.icon:SetTexture(C_Item.GetItemIconByID(itemId))
		else
			gemButton:Hide()
		end
	end
end
