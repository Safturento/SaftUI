local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local function Constructor(self)
	local name = self.TextOverlay:CreateFontString(nil, 'OVERLAY')

	self.Name = name
	return name
end

local function UpdateConfig(self)
	if self.config.name.enable == false then
		self.Name:Hide()
		return
	else
		self.Name:Show()
	end

	self.Name:SetFontObject(st:GetFont(self.config.name.font))
	self.Name:ClearAllPoints()
	local anchor, rel_anchor, x_off, y_off = unpack(self.config.name.position)
	self.Name:SetPoint(anchor, self, rel_anchor, x_off, y_off)

	self:Tag(self.Name, '[st:name]')
end

local function GetConfigTable(self)

end

UF:RegisterElement('Name', Constructor, UpdateConfig, GetConfigTable)