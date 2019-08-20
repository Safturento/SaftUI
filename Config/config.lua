local ADDON_NAME, st = ...

function st:InitializeConfigGUI()
	local config = LibStub('AceConfig-3.0')
	local dialog = LibStub('AceConfigDialog-3.0')

	config:RegisterOptionsTable(ADDON_NAME, self.options)
	dialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME)
	
	self.options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(st.config)
	self.options.args.profiles.order = -1

	for name, options in pairs(self.options.args) do
		config:RegisterOptionsTable(ADDON_NAME..'_'..name, options)
		dialog:AddToBlizOptions(ADDON_NAME..'_'..name, options.name, ADDON_NAME)
	end
end

st.options = {
	type = 'group', 
	name = ADDON_NAME,
	args = {
		unitframes = {
			order = 1,
			type = 'group',
			name = 'Unitframes',
		},
	},
}
