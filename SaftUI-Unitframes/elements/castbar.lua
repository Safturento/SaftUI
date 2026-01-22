local st = SaftUI
local UF = st:GetModule('Unitframes')

local function PostCastStart(castbar, unit)
	if issecretvalue(castbar.notInterruptible) then
		--castbar:SetColorFill(C_CurveUtil.EvaluateColorFromBoolean(
		--	castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal):GetRGB()
		--)
	else
		if castbar.notInterruptible then
			castbar:SetColorFill(unpack(castbar.config.colors.nointerrupt))
		else
			castbar:SetColorFill(unpack(castbar.config.colors.normal))
		end
	end

	if castbar.Icon.texture:GetTexture() == [[Interface\ICONS\INV_Misc_QuestionMark]] then
		local name, _, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = CastingInfo(unit)
		local icon = select(10, C_Item.GetItemInfo(name))

		if icon then
			castbar.Icon.texture:SetTexture(icon)
		end
	end
end

local function Constructor(unitframe)
    local castbar = UF:AddStatusBarElement(unitframe, 'Castbar')
    UF:AddText(unitframe, castbar, 'Text', castbar)
    UF:AddText(unitframe, castbar, 'Time', castbar)
    UF:AddIcon(unitframe, castbar, 'Icon')


	castbar.colors = {
		normal = CreateColor(unpack(castbar.config.colors.normal)),
		notInterruptible = CreateColor(unpack(castbar.config.colors.nointerrupt))
	}
	castbar.PostCastStart = PostCastStart
	castbar.PostChannelStart = PostCastStart

	return castbar
end

UF:RegisterElement('Castbar', Constructor)