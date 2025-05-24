local st = SaftUI

local AceConfig = LibStub("AceConfig-3.0")
local AceDB = LibStub('AceDB-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local AceDBOptions = LibStub('AceDBOptions-3.0')
local AceSerializer = LibStub('AceSerializer-3.0')
local LibCompress = LibStub('LibCompress')
local LibBase64 = LibStub('LibBase64-1.0')
local Config = st:NewModule('Config')

st.Config = Config

function Config:Refresh()
	AceConfigRegistry:NotifyChange(ADDON_NAME)
end

function Config:Export(data)
	return LibBase64.Encode(
		LibCompress:Compress(
	AceSerializer:Serialize(data)))
end

function Config:Import(string)
	return AceSerializer:Deserialize(
				 LibCompress:Decompress(
						 LibBase64:Decode(data)))
end

function Config:InitializeAceConfig()
    st.config = AceDB:New('SaftUI_DB', {
		char = {},
		realm = {},
		class = {},
		race = {},
		faction = {},
		factionrealm = {},
		global = {},
		profile = st.defaults,
	})

    self.db = st.config
    self.db.RegisterCallback(self, 'OnProfileChanged', 'UpdateConfig')
	self.db.RegisterCallback(self, 'OnProfileCopied', 'UpdateConfig')
	self.db.RegisterCallback(self, 'OnProfileReset', 'UpdateConfig')

    --AceConfig:RegisterOptionsTable(st.name, options)
    --AceConfigDialog:AddToBlizOptions(st.name, st.name)

    _G.SLASH_SAFTUI1 = '/sui'
    _G.SLASH_SAFTUI2 = '/saftui'
    _G.SlashCmdList.SAFTUI = function()
		AceConfig:RegisterOptionsTable(st.name, {
			name = st.names,
			type='group',
			args = self:GetOptionsTable(),
		})
        AceConfigDialog:Open(st.name)
    end
end

function Config:GetOptionsTable()
	local profile = AceDBOptions:GetOptionsTable(st.config)
	profile.order = -999
	local options = {
		topmenu = {
			name = '',
			inline = true,
			type = 'group',
			order = 0,
			args = {
				--toggle_movers = {
				--	name = 'Toggle Positioning',
				--	type = 'execute',
				--	func = function()
				--		--st:ToggleMovers()
				--	end
				--}
			}
		},
		profile = profile
	}
    for name, module in pairs(st.modules) do
		if module.GetConfigTable then
			options[name] = module:GetConfigTable()
		end
	end

    return options
end

function Config:UpdateConfig()
	for name, module in pairs(st.modules) do
		if module.UpdateConfig then
			module:UpdateConfig()
		end
	end
end