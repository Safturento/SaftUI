local st = SaftUI
local UF = st:GetModule('Unitframes')

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

-- A dialog's edit box: GetEditBox on current clients, the named child before.
-- Nothing is written onto Blizzard's dialogs to find it.
local function EditBoxOf(dialog)
	if dialog.GetEditBox then return dialog:GetEditBox() end
	return _G[dialog:GetName() .. 'EditBox']
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

-- Makes name the profile being edited and refreshes the frames and /sui.
local function SwitchProfile(name)
	UFProfiles().config_profile = name
	UF:UpdateConfig()
	st.Config:Refresh()
end

StaticPopupDialogs["SAFTUI_UF_PROFILE_NEW"] = {
	text = "Enter a name for your new profile",
	button1 = "Create",
	button2 = "Cancel",
	-- data is { copy = true } from Copy (StaticPopup_Show's data argument).
	OnAccept = function(self, data)
		local profile_name = EditBoxOf(self):GetText()
		if not get_profile_exists(profile_name) then
			if data and data.copy then
				st.config.profile.unitframes.profiles[profile_name] = st.tablecopy(
					st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile],
					true
				)
			end
			st.config.profile.unitframes.config_profile = profile_name
			UF:UpdateConfig()
			st.Config:Refresh()
		end
	end,
	OnCancel = function () end,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = true,
}

StaticPopupDialogs["SAFTUI_UF_PROFILE_DELETE"] = {
	text = "Are you sure you wish to delete this profile?",
	button1 = "Delete",
	button2 = "Cancel",
	OnAccept = function(self)
		if get_num_profiles() > 1 then
			st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile] = nil
		end
		st.config.profile.unitframes.config_profile = next(st.config.profile.unitframes.profiles)
		UF:UpdateConfig()
		st.Config:Refresh()
	end,
	OnCancel = function (_,reason)
	end,
	whileDead = true,
	hideOnEscape = true,
}


StaticPopupDialogs["SAFTUI_UF_PROFILE_RENAME"] = {
	text = "Enter a new profile name",
	button1 = "Rename",
	button2 = "Cancel",
	OnShow = function(self)
		local editBox = EditBoxOf(self)
		editBox:SetText(UFProfiles().config_profile)
		editBox:HighlightText()
	end,
	OnAccept = function(self)
		local profiles = UFProfiles()
		local old = profiles.config_profile
		local new = strtrim(EditBoxOf(self):GetText())
		-- '**' is AceDB's every-profile defaults key.
		if new == '' or new == '**' or new == old then return end
		if get_profile_exists(new) then
			st:Print(("There's already a unit frame profile named %s."):format(new))
			return
		end
		profiles.profiles[new] = profiles.profiles[old]
		profiles.profiles[old] = nil
		SwitchProfile(new)
	end,
	OnCancel = function() end,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = true,
}

StaticPopupDialogs["SAFTUI_UF_PROFILE_EXPORT"] = {
	text = "Copy this text to share the profile",
	button1 = "Close",
	OnShow = function(self)
		local profiles = UFProfiles()
		local editBox = EditBoxOf(self)
		editBox:SetText(st.Config:Export(profiles.profiles[profiles.config_profile]))
		editBox:HighlightText()
	end,
	hasEditBox = true,
	maxLetters = 0, -- an exported profile is longer than the default limit
	whileDead = true,
	hideOnEscape = true,
}

-- Imports into a new profile ("Imported", "Imported 2", ...), so nothing is
-- overwritten.
StaticPopupDialogs["SAFTUI_UF_PROFILE_IMPORT"] = {
	text = "Paste an exported unit frame profile",
	button1 = "Import",
	button2 = "Cancel",
	OnAccept = function(self)
		local ok, data = st.Config:Import(strtrim(EditBoxOf(self):GetText()))
		if not ok or type(data) ~= 'table' then
			st:Print("That isn't an exported unit frame profile.")
			return
		end
		local name = UnusedProfileName('Imported')
		UFProfiles().profiles[name] = data
		SwitchProfile(name)
	end,
	OnCancel = function() end,
	hasEditBox = true,
	maxLetters = 0, -- an exported profile is longer than the default limit
	whileDead = true,
	hideOnEscape = true,
}

-- One spawned frame of a config unit, for its options to look at: the unit's
-- frame, boss (or arena) 1, or a party or raid group's first button. nil while
-- a group has no buttons.
function UF:GetConfigFrame(unit)
	local frame = self.units and self.units[unit]
	if frame then
		-- boss and arena are a list of five frames.
		return frame.GetConfig and frame or frame[1]
	end
	local header = self.groups and self.groups[unit]
	if header then
		for i = 1, header:GetNumChildren() do
			local child = select(i, header:GetChildren())
			if child and child.GetConfig then
				return child
			end
		end
	end
end

-- The target of an element's Position editor (generators.uf_element_position):
-- a function returning the element (or the text or icon at element[key]) on
-- UF:GetConfigFrame(unit), or nil. Looked up on every call, as group buttons
-- come and go.
function UF:ConfigTarget(unit, element, key)
	return function()
		local frame = self:GetConfigFrame(unit)
		local target = frame and frame[element]
		if target and key then
			target = target[key]
		end
		return target
	end
end

function UF.GenerateRelativeSizeConfigGroup(order)
	return {
		order = order,
		name = '',
		type = 'group',
		inline = true,
		args = {
			width =  st.Config.generators.width(1),
			relative_width =  st.Config.generators.toggle(2, 'Relative', 1),
			height =  st.Config.generators.height(3),
			relative_height =  st.Config.generators.toggle(4, 'Relative', 1),
		},
	}
end


-- The Copy from dialog: copies the ticked settings of another unit (in the
-- current unit frame profile) onto unit, after asking. SaftUI's options window
-- draws it as a small dialog (st.OptionsWindow:OpenDialog). The table is made
-- anew each time, so nothing carries over from the last unit.
function UF:OpenCopyTable(unit)
	local copy = { from = nil, settings = {} }
	local settingArgs = {}
	for key in pairs(self:GetProfileConfig()[unit]) do
		copy.settings[key] = false
		settingArgs[key] = st.Config.generators.toggle(0, key, 0.7)
	end
	local function SetAll(value)
		for key in pairs(copy.settings) do copy.settings[key] = value end
	end

	local options = {
		name = 'Copy from',
		type = 'group',
		args = {
			copy_from = {
				order = 0,
				name = 'Copy from',
				type = 'select',
				width = 'full',
				values = function()
					local units = {}
					-- The current profile's, in case the profile changed since opening
					for key in pairs(UF:GetProfileConfig()) do
						if key ~= unit then
							units[key] = key
						end
					end
					return units
				end,
				get = function() return copy.from end,
				set = function(_, from) copy.from = from end,
			},
			toggle_all = {
				order = 1,
				name = 'All',
				type = 'execute',
				width = 0.5,
				func = function() SetAll(true) end,
			},
			toggle_none = {
				order = 1,
				name = 'None',
				type = 'execute',
				width = 0.5,
				func = function() SetAll(false) end,
			},
			settings = {
				order = -99,
				name = 'Settings',
				type = 'group',
				inline = true,
				get = function(info) return copy.settings[info[#info]] end,
				set = function(info, value) copy.settings[info[#info]] = value end,
				args = settingArgs,
			},
			accept = {
				order = -95,
				name = 'Confirm copy',
				type = 'execute',
				disabled = function() return not copy.from end,
				confirm = function()
					return 'Are you sure you want to clone ' .. unit .. ' from ' .. tostring(copy.from) .. '?'
				end,
				func = function()
					local profile = UF:GetProfileConfig()
					for key, ticked in pairs(copy.settings) do
						if ticked then
							local value = profile[copy.from][key]
							if type(value) == 'table' then
								profile[unit][key] = st.tablecopy(value, true)
							else
								profile[unit][key] = value
							end
						end
					end
					UF:UpdateConfig()
					st.Config:Refresh()
					st.OptionsWindow:CloseDialog()
				end,
			},
		},
	}

	st.OptionsWindow:OpenDialog(function()
		return 'Clone ' .. unit .. (copy.from and (' from ' .. copy.from) or ' from..')
	end, options)
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
		st.config.profile.unitframes.config_profile = profile_name
	end
end

function UF:GetProfileConfig()
	local currentProfile = self:GetProfile()
	return st.config.profile.unitframes.profiles[currentProfile]
end

-- Group header 'point' / 'columnAnchorPoint' values, named for the way the
-- frames (or columns) grow from them.
local GROWTH_DIRECTIONS = { TOP = 'Down', BOTTOM = 'Up', LEFT = 'Right', RIGHT = 'Left' }

-- Party and raid only: the header's layout, and test mode. The values sit on
-- the group's own config, so General's get and set handle them.
local function GetGroupLayoutConfig(unit, order)
	local args = {
		test_mode = {
			order = 0,
			name = 'Test mode',
			desc = "Fills this group's spot with made-up members, styled and laid out like the real frames, so the layout can be checked without a group. Hidden while a real group of this kind is showing. Not saved: it's off after a /reload.",
			type = 'toggle',
			width = 'full',
			-- Not a config value: a plain module field, never saved.
			get = function() return UF.testGroups[unit] and true or false end,
			set = function(_, value) UF:SetGroupTestMode(unit, value) end,
		},
		growthDirection = {
			order = 1,
			name = 'Growth',
			desc = 'Which way each frame follows the one before it.',
			type = 'select',
			values = GROWTH_DIRECTIONS,
			width = 0.75,
		},
		spacing = st.Config.generators.range(2, 'Spacing', 0, 50, 1),
		unitsPerColumn = st.Config.generators.range(3, 'Units per column', 1, 40, 1),
		initialAnchor = {
			order = 4,
			name = 'Column growth',
			desc = 'Which way each new column follows the one before it. A column runs the way the frames grow, so it is a row when they grow sideways.',
			type = 'select',
			values = GROWTH_DIRECTIONS,
			width = 0.75,
		},
		columnSpacing = st.Config.generators.range(5, 'Column spacing', 0, 50, 1),
		maxColumns = st.Config.generators.range(6, 'Max columns', 1, 40, 1),
	}
	if unit == 'party' then
		args.showPlayer = st.Config.generators.toggle(7, 'Show player', 1)
	end
	return {
		order = order,
		name = 'Layout',
		type = 'group',
		inline = true,
		args = args,
	}
end


-- The units' order in /sui's unit picker (their keys are UF.unit_strings' and
-- UF.group_strings'); the page opens on the first. A unit not listed sorts
-- after these, and the Profile group (a negative order) after everything.
local UNIT_ORDER = {}
for i, unit in ipairs({
	'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40',
}) do
	UNIT_ORDER[unit] = i
end

function UF:GetConfigTable()
	local config = {
		name = 'Unitframes',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
		-- The units (and the Profile group) are the page's picker; each unit's
		-- elements are its tabs.
		childGroups = 'select',
		args = {
			profile = {
				order = -99,
				name = 'Profile',
				type = 'group',
				-- inline = true,
				args = {
					current = {
						order = 1,
						type = 'select',
						name = 'Profile',
						values = get_profiles,
						get = function(info)
							st.Config:Refresh()
							return st.config.profile.unitframes.config_profile
						end,
						set = function(info, value)
							st.config.profile.unitframes.config_profile = value
							UF:UpdateConfig()
							st.Config:Refresh()
						end
					},
					new = {
						order = 2,
						type = 'execute',
						name = 'New',
						width = 0.5,
						func = function()
							StaticPopup_Show('SAFTUI_UF_PROFILE_NEW')
						end,
					},
					copy = {
						order = 3,
						type = 'execute',
						name = 'Copy',
						width = 0.5,
						func = function()
							StaticPopup_Show('SAFTUI_UF_PROFILE_NEW', nil, nil, { copy = true })
						end,
					},
					delete = {
						order = 4,
						type = 'execute',
						name = 'Delete',
						width = 0.5,
						func = function()
							if get_num_profiles() > 1 then
								StaticPopup_Show('SAFTUI_UF_PROFILE_DELETE')
							end
						end,
					},
					rename = {
						order = 5,
						type = 'execute',
						name = 'Rename',
						width = 0.5,
						func = function()
							StaticPopup_Show('SAFTUI_UF_PROFILE_RENAME')
						end,
					},
					export = {
						order = 6,
						type = 'execute',
						name = 'Export',
						width = 0.5,
						func = function()
							local popup = StaticPopup_Show('SAFTUI_UF_PROFILE_EXPORT')
						end
					},
					import = {
						order = 6,
						type = 'execute',
						name = 'Import',
						width = 0.5,
						func = function()
							StaticPopup_Show('SAFTUI_UF_PROFILE_IMPORT')
						end
					}
				}
			},
		}
	}

	local function GetUnitConfig(unit)
		if not unit then return end

		-- Looked up on every get/set: a profile change replaces these tables.
		local function UnitConfig() return UF:GetProfileConfig()[unit] end

		local function frame_position_set(key, value)
			UnitConfig().position[key] = value
			UF:UpdateConfig(unit)
		end
		local function frame_position_get(key)
			return UnitConfig().position[key]
		end

		local config_table = {
			name = self.unit_strings[unit] or self.group_strings[unit] or unit,
			order = UNIT_ORDER[unit],
			type = 'group',
			inline = false,
			-- Elements (General, Health, Name, Power, ...) as tabs, not a dropdown.
			childGroups = 'tab',
			args = {
				copy = {
					name = 'Copy from',
					type = 'execute',
					func = function()
						UF:OpenCopyTable(unit)
					end,
					order = -99,
				},
				-- Clicking the unit's frame in edit mode selects this group (the
				-- mover's configPath, UF:RegisterMovers).
				general = {
					order = 0,
					name = 'General',
					type = 'group',
					get = function(info)
						return UnitConfig()[info[#info]]
					end,
					set = function(info, value)
						UnitConfig()[info[#info]] = value
						UF:UpdateConfig(unit)
					end,
					args = {
						enable = st.Config.generators.enable(0),
						template = st.Config.generators.template(2),
						height = st.Config.generators.height(3),
						width = st.Config.generators.width(4),
						-- Every SetPoint parameter, the relative frame included.
						-- Passing the mover's frame makes a typed frame go through
						-- st:ValidateAnchor, which rejects the frame itself and
						-- anything anchored back to it (e.g. Pet for Player).
						position = st.Config.generators.position(5, true, frame_position_get, frame_position_set,
							self:GetMoverFrame(unit)),
					}
				}
			}
		}

		if self.groups and self.groups[unit] then
			config_table.args.general.args.layout = GetGroupLayoutConfig(unit, 6)
		end

		-- Either raid group being on hides Blizzard's raid frames (groups.lua).
		if self.groups and self.groups[unit] and unit ~= 'party' then
			config_table.args.general.args.enable.desc = "While either raid group is on, Blizzard's raid frames are hidden. Blizzard's raid manager tab at the left edge of the screen stays. Turning both raid groups off brings Blizzard's raid frames back. In a raid, hiding them waits until you leave the raid, and bringing them back waits until you leave it or /reload."
		end

		-- One tab per element the unit has (ValidUnit, as in UF.ConstructUnit).
		for element_name, element in pairs(UF.elements) do
			if element.GetConfigTable and (not element.ValidUnit or element.ValidUnit(unit)) then
				config_table.args[element_name] =
					element.GetConfigTable(unit, frame_position_get, frame_position_set)
			end
		end

		return config_table
	end

	for unit,frame in pairs(self.units) do
		config.args[unit] = GetUnitConfig(unit)
	end

	for unit in pairs(self.groups or {}) do
		config.args[unit] = GetUnitConfig(unit)
	end

	return config
end