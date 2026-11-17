local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The unit frame profiles: layouts kept inside the SaftUI profile, in
	st.config.profile.unitframes.profiles, config_profile naming the one every
	unit frame uses (UF:GetProfileConfig). In /sui they're the Unitframes
	Unit dropdown's line (UF.GenerateProfileControl: UF:GetConfigTable in
	config.lua and UF.SetUpPlatePage in nameplates/options.lua put its two
	options in each unit's pickerControl, after Copy from, so the line reads
	Unit, Copy from, Profile, Manage; the nameplate pages and All units have no Copy from),
	a dropdown that picks one and Manage, which opens
	the Unit frame profiles dialog (UF:OpenProfileDialog, over
	UF.GenerateProfileConfigGroup): the same dropdown, and the buttons that
	make, copy, rename, delete, export and import them.
]]

local function get_profiles()
	local profiles = {}
	local num_profiles = 0
	for key,_ in pairs(st.config.profile.unitframes.profiles) do
		profiles[key] = key
		num_profiles = num_profiles + 1
	end
	return profiles, num_profiles
end

local function get_profile_exists(profile_name)
	for key,_ in pairs(st.config.profile.unitframes.profiles) do
		if key == profile_name then return true end
	end

	return false
end

local function get_num_profiles()
	return select(2, get_profiles())
end

local function UFProfiles()
	return st.config.profile.unitframes
end

-- name, or name 2, name 3, ... whichever no profile has yet.
local function UnusedProfileName(name)
	local candidate, i = name, 1
	while get_profile_exists(candidate) do
		i = i + 1
		candidate = name .. ' ' .. i
	end
	return candidate
end

-- Edit mode's history belongs to one unit frame profile: a step made in
-- another one must never be undone here (the 'ufsetting' kind, config.lua, and
-- the movers' positions, which the unit frames read from the profile). So it
-- is emptied wherever the profile in use is switched.
local function ClearHistory()
	local EM = st.EditModeFrames
	if EM and EM.History then EM.History:Clear() end
end

-- Draws /sui again after a unit frame profile change. The pages are built for the profile in use (a
-- page has its shares only while that profile shares settings, UF:SharedReady), so an open window's
-- tree is built again, as a SaftUI profile change does (Config:UpdateConfig); then it re-renders.
function UF.RefreshPages()
	local Config, OW = st.Config, st.OptionsWindow
	if Config.RegisterOptions and OW and OW.IsShown and OW:IsShown() then
		OW:SetRoot(Config:RegisterOptions())
	end
	Config:Refresh()
end

-- Makes name the profile being edited and refreshes the frames and /sui. UF:UpdateConfig converts the
-- profile to shared settings first when it has not been (a new profile, a copy), so the frames and the
-- pages read it ready.
local function SwitchProfile(name)
	UFProfiles().config_profile = name
	ClearHistory()
	UF:UpdateConfig()
	UF.RefreshPages()
end

-- The profile prompts are SaftUI's own dialog (st.OptionsWidgets Prompt and
-- Confirm), which shows over the /sui window; StaticPopups would sit under it.

-- A new profile's name from the box: trimmed, and nil for one that can't be
-- used ('**' is AceDB's every-profile defaults key). Prints why on a duplicate.
local function UsableName(text)
	local name = strtrim(text)
	if name == '' or name == '**' then return end
	if get_profile_exists(name) then
		st:Print(("There's already a unit frame profile named %s."):format(name))
		return
	end
	return name
end

-- New, or with copy the current profile copied into the new one.
local function PromptNewProfile(copy)
	st.OptionsWidgets.Prompt('Enter a name for your new profile', '', function(text)
		local name = UsableName(text)
		if not name then return end
		if copy then
			-- Its own values, converted by the switch from ITS values: the backup of the profile it was
			-- copied from belongs to that profile and stays there (UF.CopyProfileData).
			local profiles = UFProfiles()
			profiles.profiles[name] = UF.CopyProfileData(profiles.profiles[profiles.config_profile])
		end
		SwitchProfile(name)
	end, { accept = 'Create', cancel = 'Cancel' })
end

local function ConfirmDeleteProfile()
	st.OptionsWidgets.Confirm('Are you sure you wish to delete this profile?', function()
		local profiles = UFProfiles()
		if get_num_profiles() > 1 then
			profiles.profiles[profiles.config_profile] = nil
		end
		profiles.config_profile = next(profiles.profiles)
		ClearHistory()
		local was = UF:SharedReady(profiles.profiles[profiles.config_profile])
		UF:UpdateConfig()
		UF.RefreshPages()
		local now = profiles.config_profile
		local state = UF:SharedState(profiles.profiles[now])
		st:Print(('Deleted. Unit frame profile %s is now in use%s'):format(now,
			(was and ', and it was already set up for sharing.')
			or (state == 'ready' and ', and it was just set up for sharing (nothing changed on screen).')
			or '.'))
	end)
end

local function PromptRenameProfile()
	local profiles = UFProfiles()
	local old = profiles.config_profile
	st.OptionsWidgets.Prompt('Enter a new profile name', old, function(text)
		local new = strtrim(text)
		if new == old then return end
		new = UsableName(new)
		if not new then return end
		profiles = UFProfiles()
		profiles.profiles[new] = profiles.profiles[old]
		profiles.profiles[old] = nil
		SwitchProfile(new)
	end, { accept = 'Rename', cancel = 'Cancel' })
end

local function PromptExportProfile()
	local profiles = UFProfiles()
	st.OptionsWidgets.Prompt('Copy this text to share the profile',
		-- Without the backup, which belongs to this profile on this account.
		st.Config:Export(UF.CopyProfileData(profiles.profiles[profiles.config_profile])),
		function() end,
		-- An exported profile is longer than the default limit.
		{ accept = 'Close', cancel = false, maxLetters = 0 })
end

-- Imports into a new profile ("Imported", "Imported 2", ...), so nothing is
-- overwritten.
local function PromptImportProfile()
	st.OptionsWidgets.Prompt('Paste an exported unit frame profile', '', function(text)
		local ok, data = st.Config:Import(strtrim(text))
		if not ok or type(data) ~= 'table' then
			st:Print("That isn't an exported unit frame profile.")
			return
		end
		-- The export's sharing (All units, the marker, each unit's own flags, a backup) is dropped: the
		-- imported table is plain for this session, so a page edit made before the next login would get
		-- no own flag, and that login's sync would put All units' value over it. With none of it, the
		-- next login converts the profile from what each unit shows, edits included.
		rawset(data, 'all', nil)
		rawset(data, 'backup', nil)
		-- Nor the marks of a restore: the import is not a restored profile, and converts at the next login.
		rawset(data, 'restored', nil)
		rawset(data, 'restoredTold', nil)
		for _, unit in pairs(data) do
			if type(unit) == 'table' then rawset(unit, 'own', nil) end
		end
		local name = UnusedProfileName('Imported')
		UFProfiles().profiles[name] = data
		SwitchProfile(name)
	end, { accept = 'Import', cancel = 'Cancel', maxLetters = 0 })
end

function UF:GetProfile()
	return st.config.profile.unitframes.config_profile
end

function UF:SetProfile(profile_name)
	-- If we're setting to a new profile create it as a duplicate of the current profile
	if not st.config.profile.unitframes.profiles[profile_name] then
		st.config.profile.unitframes.profiles[profile_name] = st.config.profile.unitframes.profiles[self:GetProfile()]
	end

	if st.config.profile.unitframes.profiles[profile_name] then
		local changed = st.config.profile.unitframes.config_profile ~= profile_name
		st.config.profile.unitframes.config_profile = profile_name
		if changed then ClearHistory() end
	end
end

function UF:GetProfileConfig()
	local currentProfile = self:GetProfile()
	return st.config.profile.unitframes.profiles[currentProfile]
end

-- The Unit frame profiles dialog's options (UF:OpenProfileDialog), as the
-- approved mockup lays them out: the profile being edited on a line of its
-- own, the buttons that make, copy, rename, delete, export and import one, two
-- to a half line, and Close in the middle of the last line. The Unit
-- dropdown's line's Profile is its current (UF.GenerateProfileControl).
function UF.GenerateProfileConfigGroup()
	return {
		name = 'Unit frame profiles',
		type = 'group',
		args = {
			current = {
				order = 1,
				type = 'select',
				name = 'Profile',
				desc = 'The unit frame profile being edited. Every unit frame uses it.',
				size = 'wide',
				noReset = 'Chooses the unit frame profile in use.',
				values = get_profiles,
				get = function(info)
					st.Config:Refresh()
					return st.config.profile.unitframes.config_profile
				end,
				set = function(info, value)
					local changed = st.config.profile.unitframes.config_profile ~= value
					st.config.profile.unitframes.config_profile = value
					if changed then ClearHistory() end
					UF:UpdateConfig()
					UF.RefreshPages()
				end
			},
			new = {
				order = 2,
				type = 'execute',
				name = 'New',
				desc = 'Makes a new unit frame profile with the default settings and switches to it.',
				size = 'small',
				func = function()
					PromptNewProfile(false)
				end,
			},
			copy = {
				order = 3,
				type = 'execute',
				name = 'Copy',
				desc = 'Makes a new unit frame profile as a copy of this one and switches to it.',
				size = 'small',
				func = function()
					PromptNewProfile(true)
				end,
			},
			rename = {
				order = 4,
				type = 'execute',
				name = 'Rename',
				desc = 'Renames this unit frame profile.',
				size = 'small',
				func = function()
					PromptRenameProfile()
				end,
			},
			delete = {
				order = 5,
				type = 'execute',
				name = 'Delete',
				desc = 'Deletes this unit frame profile, after asking. The last profile cannot be deleted.',
				size = 'small',
				func = function()
					if get_num_profiles() > 1 then
						ConfirmDeleteProfile()
					end
				end,
			},
			export = {
				order = 6,
				type = 'execute',
				name = 'Export',
				desc = 'Shows this unit frame profile as text to share.',
				size = 'small',
				func = function()
					PromptExportProfile()
				end
			},
			import = {
				order = 7,
				type = 'execute',
				name = 'Import',
				desc = 'Makes a new unit frame profile from pasted text and switches to it.',
				size = 'small',
				func = function()
					PromptImportProfile()
				end
			},
			close = {
				order = 8,
				type = 'execute',
				name = 'Close',
				desc = 'Closes Unit frame profiles.',
				align = 'center',
				func = function() st.OptionsWindow:CloseDialog() end,
			},
		}
	}
end

-- The Unit frame profiles dialog, over /sui (st.OptionsWindow:OpenDialog). Its
-- table is made anew each time.
function UF:OpenProfileDialog()
	st.OptionsWindow:OpenDialog('Unit frame profiles', UF.GenerateProfileConfigGroup())
end

-- The unit frame profile's two options, for each unit's pickerControl (SaftUI's
-- field: /sui draws them on the Unit dropdown's line, Profile after its name,
-- then Manage, which opens the dialog). Their orders (10 and 11) put them
-- after Copy from. searchText (SaftUI's field) is what a search finds them
-- by (OM.Search: listed once, not once per unit). Nameplate settings are in the unit frame profile, so the
-- nameplate pages have them too.
function UF.GenerateProfileControl()
	-- The dialog's select takes its own line (size 'wide'); the line has none.
	local profile = {}
	for key, value in pairs(UF.GenerateProfileConfigGroup().args.current) do profile[key] = value end
	profile.size = nil
	profile.name = 'Profile'
	profile.order = 10
	profile.searchText = 'Unit frame profile'
	return {
		profile = profile,
		manage = {
			order = 11,
			type = 'execute',
			name = 'Manage',
			searchText = 'Unit frame profile',
			desc = 'Opens Unit frame profiles, to make, copy, rename, delete, export or import one.',
			func = function() UF:OpenProfileDialog() end,
		},
	}
end
