local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Update(unitframe, event, unit, powerType)
	if(unitframe.__unit ~= unit) then return end
	local additionalPower = unitframe.AdditionalPower

	if(additionalPower.PreUpdate) then
		additionalPower:PreUpdate(unit)
	end

	--TODO: Override powertype to maelstrom for ele/enh shamans in ghost wolf

	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	additionalPower:SetMinMaxValues(0, max)
	additionalPower:SetValue(cur)

	additionalPower.cur = cur
	additionalPower.max = max

	if(additionalPower.PostUpdate) then
		additionalPower:PostUpdate(cur, max)
	end
end

local function PostUpdateColor(power, color, r, g, b)
	if color then
		r, g, b = color:GetRGB()
	end
	if r and g and b then
		UF.SetPowerBackgroundColor(power, r, g, b)
	end
end

local function PostUpdate(additionalPower, curr, max)
	additionalPower.text:SetText(curr)
end

local function PostVisibility(additionalPower, enabled)
	additionalPower.text:SetShown(enabled)
end

local function Constructor(self)
    local additionalPower = UF:AddStatusBarElement(self, 'AdditionalPower')
    UF:AddText(self, additionalPower)
	additionalPower.PostVisibility = PostVisibility
	additionalPower.PostUpdate = PostUpdate
	if st.retail then
		additionalPower.PostUpdateColor = PostUpdateColor
	end

	return additionalPower
end

local function UpdateConfig(unitframe)
    local additionalPower = unitframe.AdditionalPower
    local config = additionalPower.config

	additionalPower:SetStatusBarTexture(st.BLANK_TEX)
	additionalPower.bg:SetTexture(st.BLANK_TEX)

	if unitframe.config.additionalpower
			and unitframe.config.additionalpower.enable
			and unitframe.config.additionalpower.manaAsPrimary
			and UnitPowerMax('player', 0) > 0 then
    	UF:UpdateElement(additionalPower, unitframe.Power:GetConfig())
	else
		UF:UpdateElement(additionalPower)
	end

	--additionalPower.Override       = config.manaAsPrimary and Update or nil
	additionalPower.colorPower     = config.colorPower
	additionalPower.colorClass     = config.colorClass
	additionalPower.colorCustom    = config.colorCustom
	additionalPower.customColor    = config.customColor
end

if st.retail then
	UF:RegisterElement('AdditionalPower', Constructor, UpdateConfig)
end