local st = SaftUI
local TP = st:NewModule('TalentPlan')

--[[
	The talent plan: a saved order of talent picks per class, shown beside the
	talent window. This file is the module; the pure rules are in model.lua,
	the saved plans in store.lua. WoW Forever only (the plan's levels and the
	talent window it sits beside are Forever's), so it does nothing on retail.
]]

function TP:OnEnable()
	st:BindModuleConfig(self, 'talentplan')
	if not st.forever then return end
end
