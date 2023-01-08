local st = SaftUI
local INV = st:NewModule('Inventory', 'AceHook-3.0', 'AceEvent-3.0')

INV.BAG_IDS = {
	['bag'] = {0, 1, 2, 3, 4},
	['bank'] = {-1, 5, 6, 7, 8, 9, 10, 11},
	['reagent'] = {-3}
}

function INV:OnInitialize()
	INV.containers = {}


	self.config = st.config.profile.inventory
	if self.config.enable == false then return end

    --self:CreateContainer('bag', INVTYPE_BAG, INV.InitializeBagFooter)
end
