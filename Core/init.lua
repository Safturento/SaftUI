local ADDON_NAME, st = ...

SLASH_RELOADUI1 = '/rl'
SlashCmdList.RELOADUI = _G.ReloadUI

SaftUI = LibStub('AceAddon-3.0'):NewAddon(
	st, ADDON_NAME, 'AceEvent-3.0', 'AceHook-3.0')

st.StringFormat = LibStub('LibStringFormat-1.0')

function SaftUI:OnInitialize()
	-- SetCVar("useUiScale", 1)
	-- SetCVar("uiScale", 768/string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)"))

	self.config = LibStub('AceDB-3.0'):New('SaftUI_DB', {
		char = {},
		realm = {},
		class = {}, 
		race = {},
		faction = {},
		factionrealm = {},
		global = {},
		profile = self.defaults,
	})

	self.config.RegisterCallback(self, 'OnProfileChanged', 'UpdateConfig')
	self.config.RegisterCallback(self, 'OnProfileCopied', 'UpdateConfig')
	self.config.RegisterCallback(self, 'OnProfileReset', 'UpdateConfig')
end

function SaftUI:UpdateConfig()
	for name, module in pairs(self.modules) do
		if module.UpdateConfig then
			module:UpdateConfig()
		end
	end
end

SLASH_SAFTUI1 = '/saftui'
SLASH_SAFTUI2 = '/sui'
SLASH_SAFTUI3 = '/stui'

SlashCmdList.SAFTUI = function(msg)
	if not st.config_initialized then
		st.CF:InitializeConfigGUI()
	end

	LibStub('AceConfigDialog-3.0'):Open(ADDON_NAME)
end