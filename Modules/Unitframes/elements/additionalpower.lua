local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Update(unitframe, event, unit, powerType)
	if(unitframe.unit ~= unit) then return end
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

	return additionalPower
end

local function UpdateConfig(unitframe)
    local additionalPower = unitframe.AdditionalPower
    local config = additionalPower.config

    UF:UpdateElement(additionalPower)

	additionalPower.Override       = config.manaAsPrimary and Update or nil
	additionalPower.colorPower     = config.colorPower
	additionalPower.colorClass     = config.colorClass
	additionalPower.colorCustom    = config.colorCustom
	additionalPower.customColor    = config.customColor
end

UF:RegisterElement('AdditionalPower', Constructor, UpdateConfig)