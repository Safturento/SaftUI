local ADDON_NAME, st = ...

SLASH_RELOADUI1 = '/rl'
SlashCmdList.RELOADUI = _G.ReloadUI

SaftUI = LibStub('AceAddon-3.0'):NewAddon(
	st, ADDON_NAME, 'AceEvent-3.0', 'AceHook-3.0')

local ACD = LibStub('AceConfigDialog-3.0')
st.StringFormat = LibStub('LibStringFormat-1.0')

function SaftUI:OnInitialize()
	-- SetCVar("useUiScale", 1)
	-- SetCVar("uiScale", st.ui_scale)

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

	if not st.config.realm.summary then st.config.realm.summary = {} end
	if not st.config.realm.summary[st.my_name] then st.config.realm.summary[st.my_name] = {} end

	self.config.RegisterCallback(self, 'OnProfileChanged', 'UpdateConfig')
	self.config.RegisterCallback(self, 'OnProfileCopied', 'UpdateConfig')
	self.config.RegisterCallback(self, 'OnProfileReset', 'UpdateConfig')

	self:RegisterEvent('TIME_PLAYED_MSG')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	RequestTimePlayed()

	total_time = 0
	for realm, realm_config in pairs(SaftUI_DB.realm) do
		if realm_config.summary then
			for character, summary in pairs(realm_config.summary) do
				total_time = total_time + (summary.time_played or 0)
			end
		end
	end
	-- print('You have played for a total of ' .. SecondsToTime(total_time) .. ' across your characters.')
end

function SaftUI:TIME_PLAYED_MSG(event, total, level)
	st.config.realm.summary[st.my_name]['time_played'] = total
	st.config.realm.summary[st.my_name]['time_played_level'] = level
end

function SaftUI:UpdateConfig()
	for name, module in pairs(self.modules) do
		if module.UpdateConfig then
			module:UpdateConfig()
		end
	end
end

local config_queued = false
function  SaftUI:PLAYER_REGEN_ENABLED()
	if config_queued then
		config_queued = false
		SlashCmdList.SAFTUI()
	end
end

function SaftUI:PLAYER_REGEN_DISABLED()
	if ACD.OpenFrames[ADDON_NAME] then
		st:Print('Config closed for combat, and will reopen after.')
		config_queued = true
		ACD:Close(ADDON_NAME)
	end
end

SLASH_SAFTUI1 = '/saftui'
SLASH_SAFTUI2 = '/sui'
SLASH_SAFTUI3 = '/stui'

SlashCmdList.SAFTUI = function(msg)
	if not st.config_initialized then
		st.CF:InitializeConfigGUI()
	end

	if InCombatLockdown() then
		st:Print('Config will open after combat')
		config_queued = true
	else
		ACD:Open(ADDON_NAME)
	end
end