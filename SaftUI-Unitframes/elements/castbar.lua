local st = SaftUI
local UF = st:GetModule('Unitframes')

local function GetColorFromBoolean(bool, trueColor, falseColor)
	local trueR, trueG, trueB, falseR, falseG, falseB;

	if trueColor.r then
		trueR = trueColor.r
		trueG = trueColor.g
		trueB = trueColor.b
	else
		trueR, trueG, trueB = unpack(trueColor)
	end

	if falseColor.r then
		falseR = falseColor.r
		falseG = falseColor.g
		falseB = falseColor.b
	else
		falseR, falseG, falseB = unpack(falseColor)
	end

	return
		C_CurveUtil.EvaluateColorValueFromBoolean(bool, trueR, falseR),
		C_CurveUtil.EvaluateColorValueFromBoolean(bool, trueG, falseG),
		C_CurveUtil.EvaluateColorValueFromBoolean(bool, trueB, falseB)
end

local function PostCastStart(castbar, unit)
	castbar:SetColorFill(castbar.config.colors.normal:GetRGB())
	if issecretvalue(castbar.notInterruptible) then
		castbar:SetStatusBarColor(GetColorFromBoolean(castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal))
		--castbar:SetColorFill(C_CurveUtil.EvaluateColorFromBoolean(
		--	castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal):GetRGBA()
		--)
	else
		if castbar.notInterruptible then
			castbar:SetColorFill(castbar.config.colors.nointerrupt:GetRGB())
		else
			castbar:SetColorFill(castbar.config.colors.normal:GetRGB())
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
		normal = CreateColor(castbar.config.colors.normal:GetRGB()),
		notInterruptible = CreateColor(castbar.config.colors.nointerrupt:GetRGB())
	}
	castbar.PostCastStart = PostCastStart
	castbar.PostChannelStart = PostCastStart

	return castbar
end

UF:RegisterElement('Castbar', Constructor)