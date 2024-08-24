local st = SaftUI
local UF = st:GetModule('Unitframes')

local function PostUpdateClassPower(classPower, cur, max, hasMaxChanged, powerType)
	if not max then classPower:Hide() return end
	local width = (classPower:GetWidth() - (classPower.config.spacing * (max - 1))) / max
	for i = 1, max do
		st:SetWidth(classPower[i], width)
		if classPower.config.show_empty then
			classPower[i]:Show()
		end
	end
end

local function Constructor(unitframe)
	if not (unitframe.unit == 'player') then return end

	local classPower = UF:AddElement('Frame', unitframe, 'ClassPower')
	for i = 1, 10 do
		classPower[i] =  CreateFrame('StatusBar', nil, classPower)
	end

	classPower.PostUpdate = PostUpdateClassPower
	return classPower
end

local function UpdateConfig(unitframe)
    local classPower = unitframe.ClassPower
    UF:UpdateElement(classPower)

	st:SetBackdrop(classPower, 'none')
	
	local prev
	for i=1, 10 do
		local point = classPower[i]
		st:SetBackdrop(point, classPower.config.template)
		
		point:SetStatusBarTexture(st.BLANK_TEX)
		point:ClearAllPoints()
		if prev then
			point:SetPoint('LEFT', prev, 'RIGHT', classPower.config.spacing, 0)
		else
			point:SetPoint('LEFT')
		end
		point:SetHeight(classPower.config.height)
		prev = point
	end
end

local function ValidUnit(unit)
	return unit == 'player'
end

UF:RegisterElement('ClassPower', Constructor, UpdateConfig, ValidUnit)
