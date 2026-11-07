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

	-- No settings changes in combat: they can touch protected frames and taint.
	self:RegisterEvent('PLAYER_REGEN_DISABLED')

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
	if InCombatLockdown() then
		st:Print("Can't open SaftUI options in combat.")
		return
	end
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

-- Entering combat closes /sui. PLAYER_REGEN_DISABLED fires just before the
-- lockdown starts, so the window's release still runs out of combat.
function Config:PLAYER_REGEN_DISABLED()
	if window then
		AceConfigDialog:Close(st.name)
		st:Print('SaftUI options closed: entering combat.')
	end
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

-- Points module.config at st.config.profile[key] and remembers the key, so a
-- profile change can re-point it (see Config:UpdateConfig).
function st:BindModuleConfig(module, key)
	module.configKey = key
	module.config = st.config.profile[key]
	return module.config
end

-- Runs fn, reporting an error instead of raising it, so one failing update
-- doesn't stop the rest of a profile change.
local function Safely(fn)
	xpcall(fn, geterrorhandler())
end

local function UpdateModule(module)
	if module and module.UpdateConfig then
		Safely(function() module:UpdateConfig() end)
	end
end

-- Runs on every profile change, copy or reset.
function Config:UpdateConfig()
	-- On a profile change AceDB switches to the new profile's tables and strips
	-- defaults from the old ones, so cached module.config references go stale
	-- (nil fields). Re-point every bound module before any of them updates.
	for _, module in pairs(st.modules) do
		if module.configKey then
			module.config = st.config.profile[module.configKey]
		end
	end

	-- Shared Core config first: modules copy font files out of the font objects
	-- (e.g. chat), and lay out around header heights (e.g. bags).
	local fonts = st:GetModule('Fonts', true)
	UpdateModule(fonts)
	Safely(function() st:UpdateHeader() end)

	-- Edit mode last, so every mover ends at the new profile's position.
	local editMode = st.EditModeFrames
	for name, module in pairs(st.modules) do
		-- Config is a module too; calling itself here recursed until the stack
		-- overflowed on every profile change, copy or reset.
		if module ~= self and module ~= fonts and module ~= editMode then
			UpdateModule(module)
		end
	end
	UpdateModule(editMode)

	-- An open /sui window's option table was built for the old profile (some
	-- getters and setters, and values read while building it). Rebuild it;
	-- re-registering it redraws the window and keeps the selected section.
	if window then
		AceConfig:RegisterOptionsTable(st.name, {
			name = st.name,
			type = 'group',
			args = self:GetOptionsTable(),
		})
	end
	self:Refresh()

	if InCombatLockdown() then
		st:Print('Profile changed in combat. Unit frames, action bars, bags and the micro menu finish updating when combat ends.')
	end
end