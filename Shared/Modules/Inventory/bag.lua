local st = SaftUI
local INV = st:GetModule('Inventory')

function INV:InitializeBagFooter(container)
    local goldstring = CreateFrame('frame', nil, container.footer)
    goldstring:EnableMouse(true)
    goldstring:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
    goldstring:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
    goldstring:SetWidth(120)

    goldstring.text = goldstring:CreateFontString(nil, 'OVERLAY')
    goldstring.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
    goldstring.text:SetPoint('RIGHT', goldstring, 'RIGHT', -10, 0)
    goldstring.text:SetJustifyH('RIGHT')

    goldstring:SetScript('OnEnter', function() INV:DisplayServerGold() end)
    goldstring:SetScript('OnLeave', st.HideGameTooltip)

    container.footer.gold = goldstring
    self:UpdateGold()
end

function INV:UpdateGold()
	local money = GetMoney()
	self.containers.bag.footer.gold.text:SetText(st.StringFormat:GoldFormat(money))
	st.config.realm.summary[st.my_name].gold = money
end

function INV:DisplayServerGold()
	GameTooltip:SetOwner(self.containers.bag, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', self.containers.bag, 'TOPLEFT', -10, 0)

	GameTooltip:ClearLines()
	-- List server wide gold
	GameTooltip:AddLine('Gold on ' .. st.my_realm)
	local totalGold = 0
	for toonName, summary in pairs(st.config.realm.summary) do
        if summary.gold then
            GameTooltip:AddDoubleLine(toonName, st.StringFormat:GoldFormat(summary.gold), 1,1,1)
            totalGold = totalGold + summary.gold
        end
	end
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Total', st.StringFormat:GoldFormat(totalGold))

	--GameTooltip:AddLine(' ')
	--GameTooltip:AddDoubleLine('Vendor profit', st.StringFormat:GoldFormat(self:GetAutoVendorProfit()))

	GameTooltip:Show()
end