local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	We can override the altPower functionality to force the main power bar
	to stay as mana for shaman/druid/priest with additionalPower. This will
	be used in conjunction the additional power overridden to show mana
	when both config.additionalpower.enable and config.additionalpower.manaAsPrimary
	are set as true
]]
local function GetDisplayPower(element)
	local unit = element.__owner.unit

	if unit == 'player' then
		return Enum.PowerType.Mana, 0
	end
end

local function PostUpdatePower(power, unit, current, min, max)
	if power.text then
		if current == max and power.config.text.hide_full then
			power.text:SetText('')
		else
			power.text:SetFormattedText(current < 10000 and current or st.StringFormat:ShortFormat(current, 1))
		end
	end

	if max == 0 then
		power:SetMinMaxValues(0, 1)
		power:SetValue(1)
	end

	power:SetStatusBarTexture(st.BLANK_TEX)
	power.bg:SetTexture(st.BLANK_TEX)
end


local function Constructor(unitframe)
    local power = UF:AddStatusBarElement(unitframe, 'Power')
    UF:AddText(unitframe, power)
	power.GetDisplayPower = GetDisplayPower
	power.PostUpdate = PostUpdatePower

	return power
end

local function UpdateConfig(unitframe)
    local power = unitframe.Power

    UF:UpdateElement(power)

	-- Toggle forcing main power as mana for shaman/druid/priest in specs with additionalPower
	power.displayAltPower = unitframe.config.additionalpower
                        and unitframe.config.additionalpower.enable
                        and unitframe.config.additionalpower.manaAsPrimary

    local config = power.config
	power.colorTapping		= config.colorTapping
	power.colorDisconnected	= config.colorDisconnected
	power.colorPower		= config.colorPower
	power.colorClass		= config.colorClass
	power.colorClassNPC		= config.colorClassNPC
	power.colorClassPet		= config.colorClassPet
	power.colorReaction		= config.colorReaction
	power.colorSmooth		= config.colorSmooth
	power.colorCustom		= config.colorCustom
	power.customColor 		= config.customColor
end

UF:RegisterElement('Power', Constructor, UpdateConfig)