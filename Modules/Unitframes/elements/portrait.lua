local st = SaftUI
local UF = st:GetModule('Unitframes')


local function Constructor(self)
	return UF:AddElement('PlayerModel', self, 'Portrait')
end

UF:RegisterElement('Portrait', Constructor)