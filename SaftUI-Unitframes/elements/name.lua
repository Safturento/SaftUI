local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(unitframe)
	local name = unitframe.TextOverlay:CreateFontString(nil, 'OVERLAY')
	name.unitframe = unitframe
	name.config = unitframe.config.name
	unitframe.Name = name
	return name
end

local function UpdateConfig(unitframe)
	unitframe.Name.config = unitframe.config.name
	--UF:UpdateElement(unitframe.Name, 'Name')

	if unitframe.config.name.enable == false then
		unitframe.Name:Hide()
		return
	else
		unitframe.Name:Show()
	end

	unitframe.Name:SetFontObject(st:GetFont(unitframe.config.name.font))
	UF:UpdateElementPosition(unitframe.Name)

	unitframe:Tag(unitframe.Name, unitframe.config.name.tag or '[st:name]')
end

UF:RegisterElement('Name', Constructor, UpdateConfig)