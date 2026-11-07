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

-- /sui subcommands that other SaftUI addons add, e.g. SaftUI-ActionBars' 'kb'.
-- Each also gets a button in the /sui window's top row, after Edit mode, in
-- the order they were added. Add them at file load or in OnEnable.
local commands = {}

-- '/sui <command>' runs func, and so does a button labelled label in /sui.
-- command is matched lowercase.
function Config:AddCommand(command, label, func)
	commands[#commands + 1] = { command = command:lower(), label = label, func = func }
end

local function FindCommand(command)
	for _, entry in ipairs(commands) do
		if entry.command == command then return entry end
	end
end

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
		local command = strtrim(msg or ''):lower()
		if command == 'edit' then
			st.EditModeFrames:Toggle()
			return
		end
		local entry = FindCommand(command)
		if entry then
			entry.func()
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

-- A sub-section is a non-inline group (a sidebar entry or a tab).
local function IsSection(option)
	return type(option) == 'table' and option.type == 'group' and not option.inline
end

local function HasSections(group)
	if type(group.args) ~= 'table' then return false end
	for _, child in pairs(group.args) do
		if IsSection(child) then return true end
	end
	return false
end

-- A frame's size and its position belong together: a section with both a
-- `general` and a `position` subgroup gets the position shown as a box at the
-- end of General instead of as its own tab or sidebar entry. Its own get/set
-- travel with it, and edit mode's configPath (ending at `general`) still works.
local function MergePositionIntoGeneral(group)
	if type(group) ~= 'table' or type(group.args) ~= 'table' then return end
	local general, position = group.args.general, group.args.position
	if IsSection(general) and type(position) == 'table' and position.type == 'group'
			and type(general.args) == 'table' and not general.args.position then
		position.inline = true
		position.order = 1000
		general.args.position = position
		group.args.position = nil
	end
	for _, child in pairs(group.args) do
		if IsSection(child) then MergePositionIntoGeneral(child) end
	end
end

-- The innermost sections (e.g. a frame's General and Position) show as tabs in
-- their parent's page instead of another sidebar level. A group whose sections
-- have no sections of their own gets childGroups = 'tab', unless it already
-- chose a layout. The first tab (lowest order) is selected by default.
local function UseTabsForInnermostSections(group)
	if type(group) ~= 'table' or type(group.args) ~= 'table' then return end
	local innermost = true
	for _, child in pairs(group.args) do
		if IsSection(child) then
			if HasSections(child) then innermost = false end
			UseTabsForInnermostSections(child)
		end
	end
	if innermost and HasSections(group) and group.childGroups == nil then
		group.childGroups = 'tab'
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
				edit_mode = {
					name = 'Edit mode',
					type = 'execute',
					order = 1,
					func = function()
						st.EditModeFrames:Toggle()
					end,
				},
			}
		},
		profile = profile
	}
	for i, entry in ipairs(commands) do
		options.topmenu.args['command_' .. entry.command] = {
			name = entry.label,
			type = 'execute',
			order = 1 + i,
			func = function() entry.func() end,
		}
	end
    for name, module in pairs(st.modules) do
		if module.GetConfigTable then
			options[name] = module:GetConfigTable()
			MergePositionIntoGeneral(options[name])
			UseTabsForInnermostSections(options[name])
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

	-- Movers can be anchored to each other; clear them all before anything is
	-- placed, so no order of placing them passes through an anchor loop.
	local editMode = st.EditModeFrames
	Safely(function() editMode:ClearPositions() end)

	-- Shared Core config first: modules copy font files out of the font objects
	-- (e.g. chat), and lay out around header heights (e.g. bags).
	local fonts = st:GetModule('Fonts', true)
	UpdateModule(fonts)
	Safely(function() st:UpdateHeader() end)

	-- Edit mode last, so every mover ends at the new profile's position.
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
		st:Print('Profile changed in combat. Frames that are locked in combat (unit frames, action bars, bags, and anything anchored to them) finish updating when combat ends.')
	end
end