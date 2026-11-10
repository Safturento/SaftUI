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
			relative_width =  st.Config.generators.toggle(2, 'Relative'),
			height =  st.Config.generators.height(3),
			relative_height =  st.Config.generators.toggle(4, 'Relative'),
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
		settingArgs[key] = st.Config.generators.toggle(0, key,
			'Copies this setting from the other unit frame onto this one.', 'small')
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
				desc = 'The unit frame to copy settings from.',
				type = 'select',
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
				desc = 'Ticks every setting below.',
				size = 'small',
				type = 'execute',
				func = function() SetAll(true) end,
			},
			toggle_none = {
				order = 1,
				name = 'None',
				desc = 'Clears every tick below.',
				size = 'small',
				type = 'execute',
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
				desc = 'Copies the ticked settings onto this unit frame, after asking.',
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

-- Party, raid and boss: how the frames are laid out (a party or raid header's
-- attributes; boss frames by UF.GetGroupLayout), and test mode for the groups.
-- The values sit on the unit's own config, so General's get and set handle
-- them, and set re-places the frames and the holder (UF:UpdateConfig(unit),
-- which waits for the end of combat).
local function GetGroupLayoutConfig(unit, order)
	local G = st.Config.generators
	local args = {
		growthDirection = {
			order = 2,
			name = 'Growth',
			desc = 'Which way each unit frame follows the one before it.',
			type = 'select',
			values = GROWTH_DIRECTIONS,
		},
		initialAnchor = {
			order = 3,
			name = 'Column growth',
			desc = 'Which way each new column follows the one before it. A column runs the way the frames grow, so it is a row when they grow sideways.',
			type = 'select',
			values = GROWTH_DIRECTIONS,
		},
		spacing = G.range(4, 'Spacing', 0, 50, 1, 'The gap between one unit frame and the next in a column.'),
		columnSpacing = G.range(5, 'Column spacing', 0, 50, 1, 'The gap between one column and the next.'),
		unitsPerColumn = G.range(6, 'Units per column', 1, 40, 1, 'How many unit frames fill a column before the next column starts.'),
		maxColumns = G.range(7, 'Max columns', 1, 40, 1, 'The most columns shown. Unit frames past the last column are not shown.'),
	}
	if unit ~= 'boss' then
		args.test_mode = {
			order = 0,
			name = 'Test mode',
			desc = "Fills this group's spot with made-up members, styled and laid out like the real frames, so the layout can be checked without a group. Hidden while a real group of this kind is showing. Not saved: it's off after a /reload.",
			type = 'toggle',
			size = 'small',
			-- Not a config value: a plain module field, never saved.
			get = function() return UF.testGroups[unit] and true or false end,
			set = function(_, value) UF:SetGroupTestMode(unit, value) end,
		}
	end
	if unit == 'party' then
		args.showPlayer = G.toggle(1, 'Show player', 'Shows you as the first unit frame of the party.', 'small')
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

-- An alpha option under its own name.
local function RangeAlpha(order, name, desc)
	local option = st.Config.generators.alpha(order, desc)
	option.name = name
	return option
end

function UF:GetConfigTable()
	local config = {
		name = 'Unitframes',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
		-- The units (and the Profile group) are the page's picker; each unit's
		-- elements are its tabs.
		childGroups = 'select',
		pickerLabel = 'Unit',
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
						desc = 'The unit frame profile being edited. Every unit frame uses it.',
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
					delete = {
						order = 4,
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
					rename = {
						order = 5,
						type = 'execute',
						name = 'Rename',
						desc = 'Renames this unit frame profile.',
						size = 'small',
						func = function()
							PromptRenameProfile()
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
					desc = "Copies chosen settings from another unit frame onto this one.",
					size = 'small',
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
						enable = st.Config.generators.enable(0, 'Shows this unit frame. When off, the unit frame is hidden.'),
						template = st.Config.generators.template(1, "The look of this unit frame's background and border."),
						width = st.Config.generators.width(2, "The unit frame's width."),
						height = st.Config.generators.height(3, "The unit frame's height."),
						-- Every SetPoint parameter, the relative frame included.
						-- Passing the mover's frame makes a typed frame go through
						-- st:ValidateAnchor, which rejects the frame itself and
						-- anything anchored back to it (e.g. Pet for Player).
						-- Last in General, after a group's Layout too.
						position = st.Config.generators.position(1000, true, frame_position_get, frame_position_set,
							self:GetMoverFrame(unit)),
					}
				}
			}
		}

		if (unit == 'boss' or (self.groups and self.groups[unit])) then
			config_table.args.general.args.layout = GetGroupLayoutConfig(unit, 6)
		end

		-- Range alpha only does anything on group members' frames: oUF's range
		-- element is enabled only on header children.
		if self.groups and self.groups[unit] then
			config_table.args.general.args.range_alpha = {
				order = 500,
				name = 'Range',
				type = 'group',
				inline = true,
				get = function(info)
					return UnitConfig().range_alpha[info[#info]]
				end,
				set = function(info, value)
					UnitConfig().range_alpha[info[#info]] = value
					UF:UpdateConfig(unit)
				end,
				args = {
					inside = RangeAlpha(0, 'Inside range', "How solid a group member's unit frame is while the member is within range."),
					outside = RangeAlpha(1, 'Outside range', "How solid a group member's unit frame is while the member is out of range."),
				},
			}
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