local ADDON_NAME, st = ...
local UF = st:NewModule('Unitframes')

local TEST_PARTY_SOLO = false

UF.oUF = st.oUF
assert(UF.oUF, 'st was unable to locate oUF.')

UF.elements = {}

UF.unit_strings = {
	['player'] = 'Player',
	['target'] = 'Target',
	['targettarget'] = 'TargetTarget',
	-- ['focus'] = 'Focus',
	-- ['focustarget'] = 'FocusTarget',
	-- ['pet'] = 'Pet',
	-- ['pettarget'] = 'PetTarget',
}

function UF.ConstructUnit(self, unit)
	-- Ensure that we have access to a numberless unit type for config tables
	local base_unit = self:GetParent():GetAttribute('base_unit')
	if base_unit then
		self.is_group_unit = true
		self.base_unit = base_unit
	else
		self.base_unit = strmatch(unit, '(%D+)')
	end
	self.ID = tonumber(strmatch(self:GetName(), '(%d+)'))
	
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	
	-- Used as a parent to text objects to ensure they're always above status bars
	local textoverlay = CreateFrame('frame', nil, self)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(self)
	self.TextOverlay = textoverlay
	
	-- self.config = st.config.profile.unitframes.units[self.base_unit]
	self.config = st.config.profile.unitframes.profiles[UF:GetProfile()][self.base_unit]
	
	-- Since oUF doesn't give us access to a table of active elements
	-- we can keep track of them here to easily loop and update through them later
	self.elements = {}
	for element_name, funcs in pairs(UF.elements) do
		self.elements[element_name] = funcs.Constructor(self, element_name)
	end
	
	if self.base_unit == 'nameplate' then
		UF.nameplates[self.ID] = self
		UF:UpdateUnitFrame(self)
		self:SetScale(UIParent:GetEffectiveScale())
	end

	if self.is_group_unit then
		UF:UpdateUnitFrame(self)
	end
end

--[[
name (string): the name of the element to use as the key
Constructor (function): for actually creating the element and binding it to oUF
GetConfigTable (function): returns and AceConfig table for the element's configuration options.
UpdateConfig (function): the function used to update the display of the element based on the configuration table

All three functions take one argument - the unitframe object created from oUF:Spawn

]]--
function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable)
	self.elements[name] = {
		Constructor = Constructor,
		UpdateConfig = UpdateConfig,
		GetConfigTable = GetConfigTable,
	}
end

function UF:UpdateColors()
	UF.oUF.colors.disconnected = st.config.profile.colors.status.disconnected
	UF.oUF.colors.tapped 		= st.config.profile.colors.status.tapped
	UF.oUF.colors.reaction 		= st.config.profile.colors.reaction
	UF.oUF.colors.power 			= st.config.profile.colors.power
	UF.oUF.colors.class 			= st.config.profile.colors.class
	UF.oUF.colors.roles 			= st.config.profile.colors.roles
	UF.oUF.colors.runes 			= st.config.profile.colors.runes
end

function UF:UpdateUnitFrame(frame, element_name)
	frame.config = st.config.profile.unitframes.profiles[self:GetProfile()][frame.base_unit]

	if element_name then
		self.elements[element_name].UpdateConfig(frame, element_name)
	else
		if not (frame.is_group_unit or InCombatLockdown()) then
			
			if frame.base_unit == 'nameplate' then
				frame:SetPoint('CENTER')
			else
				frame:ClearAllPoints()
				if not frame.config.enable then
					frame:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 10000, 10000)
					return
				else
					frame:SetPoint(unpack(frame.config.position))
				end
			end

			frame:SetSize(frame.config.width, frame.config.height)
		end

		st:SetBackdrop(frame, frame.config.template)
		
		frame.Range = {
			insideAlpha = frame.config.range_alpha.inside,
			outsideAlpha = frame.config.range_alpha.outside
		}
		
		for element_name, element in pairs(frame.elements) do
			self.elements[element_name].UpdateConfig(frame, element_name)
		end
	end
end

--[[
	Wrapper function for UpdateUnitFrame that allows you to update
		using unit string instead of the frame object. Also used 
		to update all group frames at once
]]
function UF:UpdateConfig(unit, element_name)
	if not unit then 
		for unit, frame in pairs(self.units) do
			UF:UpdateConfig(unit, element_name)
		end
		
		for unit,_ in pairs(self.groups) do
			UF:UpdateConfig(unit)
		end
		
		UF:UpdateConfig('nameplate')
	else
		if self.units[unit] then
			self:UpdateUnitFrame(self.units[unit], element_name)
		elseif self.groups[unit] then
			for i=1,self.groups[unit]:GetNumChildren() do
				local frame = select(i, self.groups[unit]:GetChildren())
				if frame and frame.Health then
					self:UpdateUnitFrame(frame, element_name)
				end
			end
		elseif unit == 'nameplate' then
			for id, nameplate in pairs(self.nameplates) do
				self:UpdateUnitFrame(nameplate, element_name)
			end
		end
	end
end

function UF:CreateGroupHeaders()
	self.groups = {}

	local config = st.config.profile.unitframes.profiles[self:GetProfile()].party
	local party = self.oUF:SpawnHeader(
		'SaftUI_PartyHeader',
		nil,
		'custom [@raid6,exists] hide;show',
		"oUF-initialConfigFunction", [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]],
		"initial-width", config.width,
		"initial-height", config.height,
		"showParty", true,
		"showRaid", true,
		'showSolo', TEST_PARTY_SOLO,
		'showPlayer', TEST_PARTY_SOLO,
		"xOffset", config.spacing,
		"yOffset", config.spacing,
		"point", config.growthDirection,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"maxColumns", config.maxColumns,
		"unitsPerColumn", config.unitsPerColumn,
		"columnSpacing", config.columnSpacing,
		"columnAnchorPoint", config.initialAnchor,
		"base_unit", "party"
	)

	party:SetPoint(unpack(config.position))
	self.groups.party = party


	-- local config = st.config.profile.unitframes.units.raid
	-- local raid = self.oUF:SpawnHeader('SaftUI_RaidHeader', nil, 'custom [@raid6,exists] show;hide',"oUF-initialConfigFunction", [[
	-- 		local header = self:GetParent()
	-- 		self:SetWidth(header:GetAttribute("initial-width"))
	-- 		self:SetHeight(header:GetAttribute("initial-height"))
	-- 	]],
	-- 	"initial-width", config.width,
	-- 	"initial-height", config.height,
	-- 	"showParty", false,
	-- 	"showRaid", true,
	-- 	"showPlayer", true,
	-- 	"xOffset", config.spacing,
	-- 	"yOffset", config.spacing,
	-- 	"point", config.growthDirection,
	-- 	"groupFilter", "1,2,3,4,5,6,7,8",
	-- 	"groupingOrder", "1,2,3,4,5,6,7,8",
	-- 	"groupBy", "GROUP",
	-- 	"maxColumns", config.maxColumns,
	-- 	"unitsPerColumn", config.unitsPerColumn,
	-- 	"columnSpacing", config.columnSpacing,
	-- 	"columnAnchorPoint", config.initialAnchor,
	-- 	"baseunit", "raid"
	-- )

	-- raid:SetPoint(unpack(config.position))
end

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

local ACR = LibStub("AceConfigRegistry-3.0")

StaticPopupDialogs["SAFTUI_UF_PROFILE_NEW"] = {
	text = "Enter a name for your new profile",
	button1 = "Create",
	button2 = "Cancel",
	OnAccept = function(self)
		local profile_name = self.editBox:GetText()
		if not get_profile_exists(profile_name) then
			if self.is_copy then
				st.config.profile.unitframes.profiles[profile_name] = st.tablecopy(
					st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile],
					true
				)
			end
			st.config.profile.unitframes.config_profile = profile_name
			UF:UpdateConfig()
			ACR:NotifyChange(ADDON_NAME..' Unitframes')
		end
	end,
	OnCancel = function (_,reason)
	end,
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
		ACR:NotifyChange(ADDON_NAME..' Unitframes')
	end,
	OnCancel = function (_,reason)
	end,
	whileDead = true,
	hideOnEscape = true,
	hasEditBox = false,
}

function UF.GenerateRelativeSizeConfigGroup(order)
	return {
		order = order,
		name = 'Size',
		type = 'group',
		inline = true,
		args = {
			width = st.CF.generators.width(1),
			relative_width = st.CF.generators.toggle(2, 'Relative', 1),
			height = st.CF.generators.height(3),
			relative_height = st.CF.generators.toggle(4, 'Relative', 1),
		},
	}
end

function UF:GetConfigTable()
	local config = {
		name = '',
		type = 'group',
		args = {
			profile = {
				order = 1,
				name = '',
				type = 'group',
				inline = true,
				args = {
					current = {
						order = 1,
						type = 'select',
						name = 'Profile',
						values = get_profiles,
						get = function(info)
							ACR:NotifyChange(ADDON_NAME..' Unitframes')
							return st.config.profile.unitframes.config_profile
						end,
						set = function(info, value)
							st.config.profile.unitframes.config_profile = value
							UF:UpdateConfig()
							ACR:NotifyChange(ADDON_NAME..' Unitframes')
						end
					},
					new = {
						order = 2,
						type = 'execute',
						name = 'New',
						func = function() 
							StaticPopup_Show('SAFTUI_UF_PROFILE_NEW')
						end,
						width = 0.5,
					},
					copy = {
						order = 3,
						type = 'execute',
						name = 'Copy',
						func = function()
							local dialog = StaticPopup_Show('SAFTUI_UF_PROFILE_NEW')
							dialog.is_copy = true
						end,
						width = 0.5,
					},
					delete = {
						order = 4,
						type = 'execute',
						name = 'Delete',
						func = function()
							if get_num_profiles() > 1 then
								StaticPopup_Show('SAFTUI_UF_PROFILE_DELETE')
							end
						end,
						width = 0.5,
					}
				}
			},
			unitframes = {
				order = 2,
				name = ' ',
				type = 'group',
				-- inline = true,
				childGroups = 'select',
				args = {
				}
			}
		}
	}

	local function GetUnitConfig(unit, frame)
		config_table = {
			name = self.unit_strings[unit],
			type = 'group',
			childGroups = 'select',
			args = {
				general = {
					order = 0,
					name = 'General',
					type = 'group',
					get = function(info)
						return frame.config[info[#info]]
					end,
					set = function(info, value)
						frame.config[info[#info]] = value
						UF:UpdateConfig(frame.unit)
					end,
					args = {
						enable = st.CF.generators.enable(0),
						framelevel = st.CF.generators.framelevel(1),
						height = st.CF.generators.height(2),
						width = st.CF.generators.width(3),
						template = st.CF.generators.template(4),
						position = st.CF.generators.position(5,
							frame.config.position, true,
							function() UF:UpdateConfig(frame.unit) end
						),
					}
				}
			}
		}

		for element_name, element in pairs(frame.elements) do
			config_table.args[element_name] =
				self.elements[element_name].GetConfigTable(frame)
		end

		return config_table
	end

	for unit,frame in pairs(self.units) do
		config.args.unitframes.args[unit] = GetUnitConfig(unit, frame)
	end

	return config
end

function UF:GetProfile()
	return st.config.profile.unitframes.config_profile
end

function UF:SetProfile(profile_name)
	if st.config.profile.unitframes.profiles[profile_name] then
		st.config.profile.unitframes.config_profile = profile_name
	else
		-- Create new profile
	end
end

function UF:OnInitialize()
	self.oUF:RegisterStyle('SaftUI', UF.ConstructUnit)
	self.oUF:SetActiveStyle('SaftUI')

	self.units = {}

	for unit, global_name in pairs(self.unit_strings) do
		self.units[unit] = self.oUF:Spawn(unit, 'SaftUI_'..global_name)
	end

	
	self.nameplates = {}
	st.oUF:SpawnNamePlates('SaftUI')
	
	self.RMH = RealMobHealth

	UF:CreateGroupHeaders()
end

function UF:OnEnable()
	UF:UpdateConfig()
	UF:UpdateColors()
end