local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(unitframe)
	local name = unitframe.TextOverlay:CreateFontString(nil, 'OVERLAY')

	unitframe.Name = name
	return name
end

local function UpdateConfig(unitframe)
	unitframe.Name.config = unitframe.config.name
	if unitframe.config.name.enable == false then
		unitframe.Name:Hide()
		return
	else
		unitframe.Name:Show()
	end

	unitframe.Name:SetFontObject(st:GetFont(unitframe.config.name.font))
	unitframe.Name:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(unitframe.config.name.position)
	unitframe.Name:SetPoint(anchor, unitframe, rel_anchor, x_off, y_off)

	unitframe:Tag(unitframe.Name, '[st:name]')
end

UF:RegisterElement('Name', Constructor, UpdateConfig)