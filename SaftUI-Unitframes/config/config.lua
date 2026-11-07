local st = SaftUI
local UF = st:GetModule('Unitframes')

local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfig = LibStub('AceConfig-3.0')

local function get_profiles()
	local profiles = {}
	num_profiles = 0
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

StaticPopup1.button1 = StaticPopup1Button1
StaticPopup1.button2 = StaticPopup1Button2
StaticPopup1.editBox = StaticPopup1EditBox

StaticPopupDialogs["SAFTUI_UF_PROFILE_NEW"] = {
	text = "Enter a name for your new profile",
	button1 = "Create",
	button2 = "Cancel",
	OnAccept = function(self)
        local editBox = _G[self:GetName()..'EditBox']
		local profile_name = editBox:GetText()
		if not get_profile_exists(profile_name) then
			if self.is_copy then
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
	OnAccept = function(self)

	end,
	OnCancel = function() end,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["SAFTUI_UF_PROFILE_EXPORT"] = {
	text = "",
	button1 = "Close",
	OnShow = function(self)
		local data = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
		self.editBox:SetText(st.Config:Export(data))

	end,
	OnAccept = function(self)

	end,
	hasEditBox = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["SAFTUI_UF_PROFILE_IMPORT"] = {
	text = "",
	button1 = "Close",
	OnShow = function(self)
		local data = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
		self.wideEditBox:Show()
	end,
	OnAccept = function(self)

	end,
	hasEditBox = true,
	whileDead = true,
	hideOnEscape = true,
}

StaticPopupDialogs["SAFTUI_UF_CONFIRM_UNIT_COPY"] = {
	text = "",
	button1 = "Copy",
	button2 = "Cancel",
	OnAccept = function(self)
		local profile = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
		if not self.options.from then return end

		for element,copy in pairs(self.options.elements) do
			if copy then
				if type(profile[self.options.from][element]) == 'table' then
					profile[self.options.to][element] = st.tablecopy(profile[self.options.from][element], true)
				else
					profile[self.options.to][element] = profile[self.options.from][element]
				end
			end
		end

		UF:UpdateConfig()
		st.Config:Refresh()

		AceConfigDialog:Close(st.name..'_Copy_Unitframe')
	end,
	OnCancel = function() end,
	whileDead = true,
	hideOnEscape = true,
}

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


function UF:RegisterCopyTable()
	local config_table = {
		name = 'Copy from',
		type = 'group',
		args = {
			copy_from = {
				order = 0,
				name = 'Copy from',
				type = 'select',
				values = function() return {} end,
			},
			toggle_all = {
				order = 1,
				name = 'All',
				type = 'execute',
				func = function(self, info) end,
				width = 0.5,
			},
			toggle_none = {
				order = 1,
				name = 'None',
				type = 'execute',
				func = function(self, info) end,
				width = 0.5,
			},
			elements = {
				order = -99,
				name = '',
				type = 'group',
				inline = true,
				childGroups = 'inline',
				args = {}
			},
			accept = {
				order = -95,
				name = 'Confirm copy',
				type = 'execute',

			},
		},
	}

	UF.CopyTable = config_table
	AceConfig:RegisterOptionsTable(st.name ..'_Copy_Unitframe', config_table)
end

function UF:OpenCopyTable(unit)
	local config = self:GetProfileConfig()
	-- We use a local table of configurations and reset all of the setters and getters
	-- To ensure there's no funny business with accidentally not clearing old values

	local copy_options = {
		['to'] = unit,
		['elements'] = {}
	}

	for element,_ in pairs(config[unit]) do
		copy_options.elements[element] = false
		self.CopyTable.name = 'Clone '..unit..' from..'

		self.CopyTable.args.copy_from.set = function(info, from)
			copy_options.from = from
			self.CopyTable.name = 'Clone '..unit..' from '..from
		end
		self.CopyTable.args.copy_from.get = function(info) return copy_options.from end
		self.CopyTable.args.copy_from.values = function(info)
			local units = {}
			-- The current profile's, in case the profile changed since opening
			for key,_ in pairs(UF:GetProfileConfig()) do
				if not (key == unit) then
					units[key] = key
				end
			end
			return units
		end

		self.CopyTable.args.toggle_all.func = function()
			for k,v in pairs(copy_options.elements) do
				copy_options.elements[k] = true
			end
			LibStub("AceConfigRegistry-3.0"):NotifyChange(st.name ..'_Copy_Unitframe')
		end

		self.CopyTable.args.toggle_none.func = function()
			for k,v in pairs(copy_options.elements) do
				copy_options.elements[k] = false
			end
			LibStub("AceConfigRegistry-3.0"):NotifyChange(st.name ..'_Copy_Unitframe')
		end

		self.CopyTable.args.elements.get = function(info)
			return copy_options.elements[info[#info]]
		end
		self.CopyTable.args.elements.set = function(info, value)
			copy_options.elements[info[#info]] = value
		end

		self.CopyTable.args.elements.args[element] =  st.Config.generators.toggle(0, element, 0.7)

		self.CopyTable.args.accept.func = function()
			if not copy_options.from then return end
			StaticPopupDialogs["SAFTUI_UF_CONFIRM_UNIT_COPY"].text = 'Are you sure you want to clone '..unit..' from ' .. copy_options.from .. '?'
			local popup = StaticPopup_Show('SAFTUI_UF_CONFIRM_UNIT_COPY')
			popup.options = copy_options
		end
	end

	AceConfigDialog:SetDefaultSize(st.name ..'_Copy_Unitframe', 400, 300)
	AceConfigDialog:Open(st.name ..'_Copy_Unitframe')
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


function UF:GetConfigTable()
	self:RegisterCopyTable()

	local config = {
		name = 'Unitframes',
		type = 'group',
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
							local dialog = StaticPopup_Show('SAFTUI_UF_PROFILE_NEW')
							dialog.is_copy = true
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
							StaticPopup_Show('SAFTIU_UF_PROFILE_RENAME')
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
			type = 'group',
			inline = false,
			childGroups = 'select',
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
						framelevel = st.Config.generators.framelevel(1),
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

		for element_name, element in pairs(UF.elements) do
			if self.elements[element_name].GetConfigTable and not (self.elements[element_name].valid_units and self.elements[element_name].valid_units(unit)) then
				config_table.args[element_name] =
					self.elements[element_name].GetConfigTable(unit, frame_position_get, frame_position_set)
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