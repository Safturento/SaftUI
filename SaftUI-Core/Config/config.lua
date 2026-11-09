local st = SaftUI

local AceDB = LibStub('AceDB-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local AceDBOptions = LibStub('AceDBOptions-3.0')
local AceSerializer = LibStub('AceSerializer-3.0')
local LibCompress = LibStub('LibCompress')
local LibBase64 = LibStub('LibBase64-1.0')
local Config = st:NewModule('Config')

st.Config = Config

-- /sui subcommands that other SaftUI addons add, e.g. SaftUI-ActionBars' 'kb'.
-- Each also gets a button at the top of the /sui window's sidebar, after Edit
-- mode, in the order they were added. Add them at file load or in OnEnable.
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

-- The added commands, in order: { {command, label, func} }. The /sui window's
-- sidebar makes a button of each.
function Config:GetCommands()
	local list = {}
	for i, entry in ipairs(commands) do
		list[i] = { command = entry.command, label = entry.label, func = entry.func }
	end
	return list
end

function Config:Refresh()
	AceConfigRegistry:NotifyChange(st.name)
end

function Config:Export(data)
	return LibBase64.Encode(
		LibCompress:Compress(
	AceSerializer:Serialize(data)))
end

-- Export's text back to data. Returns true and the data, or false for text
-- that isn't an export. Decode errors on characters outside Base64, and
-- Decompress can error on bytes that aren't its own.
function Config:Import(text)
	local ok, compressed = pcall(LibBase64.Decode, text)
	if not ok then return false end
	local decompressed, serialized = pcall(LibCompress.Decompress, LibCompress, compressed)
	if not decompressed or type(serialized) ~= 'string' then return false end
	return AceSerializer:Deserialize(serialized)
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

-- Builds the /sui tree and registers it with AceConfigRegistry as st.name, so
-- Config:Refresh (NotifyChange) reaches the window as ConfigTableChange.
-- Returns the tree. Ace's validation is skipped: the window doesn't need it,
-- and it rejects the `category` field SaftUI's module tables carry.
function Config:RegisterOptions()
	local root = self:GetOptionsTable()
	AceConfigRegistry:RegisterOptionsTable(st.name, { name = st.name, type = 'group', args = root }, true)
	return root
end

-- Opens the /sui window (st.OptionsWindow, optionswindow.lua), or brings the
-- open one to the group at the given path of option keys (e.g. 'Unitframes',
-- 'player', 'general': its page, picker and tab). The tree is rebuilt each
-- time, so modules that built their options since show. The window opens
-- where the user last left it.
function Config:Open(...)
	if InCombatLockdown() then
		st:Print("Can't open SaftUI options in combat.")
		return
	end
	st.OptionsWindow:Open({ ... }, self:RegisterOptions())
end

function Config:Close()
	st.OptionsWindow:Close()
end

-- Entering combat closes /sui. PLAYER_REGEN_DISABLED fires just before the
-- lockdown starts, so the window still closes out of combat.
function Config:PLAYER_REGEN_DISABLED()
	if st.OptionsWindow:IsShown() then
		st.OptionsWindow:Close()
		st:Print('SaftUI options closed: entering combat.')
	end
end

-- The /sui window's frame while it's open, else nil.
function Config:GetWindow()
	local OW = st.OptionsWindow
	return OW and OW:IsShown() and OW:GetFrame() or nil
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

-- The /sui tree: one group per page, keyed by module name, plus AceDBOptions'
-- profiles. Edit mode and the AddCommand commands are the window's sidebar
-- buttons, not options.
function Config:GetOptionsTable()
	local profile = AceDBOptions:GetOptionsTable(st.config)
	profile.order = -999
	local options = {
		profile = profile
	}
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

	-- An open /sui window's tree was built for the old profile (some getters
	-- and setters, and values read while building it). Rebuild it; the window
	-- redraws it next frame and keeps the page, tab and picker. Its fonts take
	-- the new profile's faces. (optionswindow.lua loads after this file; tests
	-- that build the tree without the window run this too.)
	local OW = st.OptionsWindow
	if OW then
		if OW:IsShown() then OW:SetRoot(self:RegisterOptions()) end
		OW:UpdateFonts()
	end
	self:Refresh()

	if InCombatLockdown() then
		st:Print('Profile changed in combat. Frames that are locked in combat (unit frames, action bars, bags, and anything anchored to them) finish updating when combat ends.')
	end
end