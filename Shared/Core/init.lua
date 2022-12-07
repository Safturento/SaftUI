local ADDON_NAME, st = ...

SLASH_RELOADUI1 = '/rl'
SlashCmdList.RELOADUI = _G.ReloadUI

SaftUI = LibStub('AceAddon-3.0'):NewAddon(
	st, ADDON_NAME, 'AceEvent-3.0', 'AceHook-3.0')

SaftUI.StringFormat = LibStub('LibStringFormat-1.0')

function SaftUI:OnInitialize()
	SetCVar('autoLootDefault', 1)
	SetCVar('chatStyle', 'classic')
	SetCVar('whisperMode', 'inline')
	--UIParent:SetScale(st.scale)
	--self:Print('Goal: 0.6499997615814')
	--self:Print('GetScreenHeight', GetScreenHeight())
	--self:Print('GetScreenHeight/Goal', GetScreenHeight()/0.6499997615814)
	--self:Print('uiScale:', GetCVar('uiScale'))
	--self:Print('st.scale', st.scale)
	--self:Print('768/GetScreenHeight', 768/GetScreenHeight())
	--self:Print('768/floor(GetScreenHeight)', 768/floor(GetScreenHeight()))
	--self:Print('768/ceil(GetScreenHeight)', 768/ceil(GetScreenHeight()))

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

	if not self.config.realm.summary then self.config.realm.summary = {} end
	if not self.config.realm.summary[self.my_name] then self.config.realm.summary[self.my_name] = {} end

	self.config.RegisterCallback(self, 'OnProfileChanged', 'UpdateConfig')
	self.config.RegisterCallback(self, 'OnProfileCopied', 'UpdateConfig')
	self.config.RegisterCallback(self, 'OnProfileReset', 'UpdateConfig')

	self:RegisterEvent('TIME_PLAYED_MSG')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	RequestTimePlayed()

	total_time = 0
	for _, realm_config in pairs(SaftUI_DB.realm) do
		if realm_config.summary then
			for _, summary in pairs(realm_config.summary) do
				total_time = total_time + (summary.time_played or 0)
			end
		end
	end
	-- print('You have played for a total of ' .. SecondsToTime(total_time) .. ' across your characters.')
end

function SaftUI:TIME_PLAYED_MSG(event, total, level)
	self.config.realm.summary[self.my_name]['time_played'] = total
	self.config.realm.summary[self.my_name]['time_played_level'] = level
end

function SaftUI:UpdateConfig()
	for name, module in pairs(self.modules) do
		if module.UpdateConfig then
			module:UpdateConfig()
		end
	end
end

local config_queued = false
function SaftUI:PLAYER_REGEN_ENABLED()
	if config_queued then
		config_queued = false
		SlashCmdList.SAFTUI()
	end
end

function SaftUI:PLAYER_REGEN_DISABLED()
	if st.CF:IsOpen() then
		st:Print('Config closed for combat, and will reopen after.')
		st.CF:CloseConfigGui()
		config_queued = true
	end
end