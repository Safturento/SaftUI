local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The unit frame profiles: layouts kept inside the SaftUI profile, in
	st.config.profile.unitframes.profiles, config_profile naming the one every
	unit frame uses (UF:GetProfileConfig). In /sui they're the Unitframes
	page's footer control (UF.GenerateProfileFooter, which UF:GetConfigTable in
	config.lua makes the page group's footer: drawn between Reload UI and Close
	while the page is open), a dropdown that picks one and Manage, which opens
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

-- Makes name the profile being edited and refreshes the frames and /sui.
local function SwitchProfile(name)
	UFProfiles().config_profile = name
	ClearHistory()
	UF:UpdateConfig()
	st.Config:Refresh()
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
			local profiles = UFProfiles()
			profiles.profiles[name] = st.tablecopy(profiles.profiles[profiles.config_profile], true)
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
		UF:UpdateConfig()
		st.Config:Refresh()
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
		st.Config:Export(profiles.profiles[profiles.config_profile]),
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
-- to a half line, and Close in the middle of the last line. The footer
-- control's dropdown is its current (UF.GenerateProfileFooter).
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
					st.Config:Refresh()
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

-- The Unitframes page's footer control (the page group's footer, SaftUI's
-- field: /sui draws it between Reload UI and Close while the page is open,
-- after its name): the dialog's own profile dropdown, then Manage, which
-- opens the dialog.
function UF.GenerateProfileFooter()
	-- The dialog's select takes its own line (size 'wide'); the footer has no lines.
	local current = {}
	for key, value in pairs(UF.GenerateProfileConfigGroup().args.current) do current[key] = value end
	current.size = nil
	return {
		type = 'group',
		name = 'Unit frame profile',
		args = {
			current = current,
			manage = {
				order = 2,
				type = 'execute',
				name = 'Manage',
				desc = 'Opens Unit frame profiles, to make, copy, rename, delete, export or import one.',
				func = function() UF:OpenProfileDialog() end,
			},
		},
	}
end
