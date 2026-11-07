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
	AceConfigRegistry:NotifyChange(st.name)
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

	-- Keep an open /sui window in sync with drags and nudges.
	st.EditModeFrames:On('PositionChanged', function() self:Refresh() end)

    _G.SLASH_SAFTUI1 = '/sui'
    _G.SLASH_SAFTUI2 = '/saftui'
    _G.SlashCmdList.SAFTUI = function(msg)
		if strtrim(msg or ''):lower() == 'edit' then
			st.EditModeFrames:Toggle()
			return
		end
		self:Open()
    end
end

local window -- the open /sui window, or nil

-- Opens the /sui window, or reuses it if it's open, and selects the group at
-- the given path of option keys (e.g. 'Minimap', 'general') in its tree. The
-- window keeps the size and spot the user last gave it.
function Config:Open(...)
	AceConfig:RegisterOptionsTable(st.name, {
		name = st.name,
		type = 'group',
		args = self:GetOptionsTable(),
	})
	-- SaftUI-styled window, registered as AceConfigDialog's frame for st.name
	-- so NotifyChange refreshes it and Escape closes it.
	window = st.AceSkin:CreateWindow(st.name, st.name, function()
		window = nil
		st.EditModeFrames:UpdateFooter()
	end)
	if select('#', ...) > 0 then
		AceConfigDialog:SelectGroup(st.name, ...)
	end
	AceConfigDialog:Open(st.name)
	st.EditModeFrames:UpdateFooter()
end

function Config:GetWindow()
	return window
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
				edit_mode = {
					name = 'Edit mode',
					type = 'execute',
					func = function()
						st.EditModeFrames:Toggle()
					end,
				},
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