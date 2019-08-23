local ADDON_NAME, st = ...
local UF = st:NewModule('Unitframes')

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
	self.unit = unit
	
	-- Ensure that we have access to a numberless unit type for config tables
	local baseunit = self:GetParent():GetAttribute('baseunit')
	if baseunit then
		self.is_group_unit = true
		self.base_unit = baseunit
	else
		self.base_unit = strmatch(unit, '(%D+)')
	end
	self.ID = tonumber(strmatch(unit, '(%d+)'))

	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	
	-- Used as a parent to text objects to ensure they're always above status bars
	local textoverlay = CreateFrame('frame', nil, self)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(self)
	self.TextOverlay = textoverlay

	self.config = st.config.profile.unitframes.units[self.base_unit]

	-- Since oUF doesn't give us access to a table of active elements
	-- we can keep track of them here to easily loop and update through them later
	self.elements = {}
	for element_name, funcs in pairs(UF.elements) do
		self.elements[element_name] = funcs.Constructor(self)
	end

	UF.units[unit] = self
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

function UF:OnInitialize()
	self.oUF:RegisterStyle('SaftUI', UF.ConstructUnit)
	self.oUF:SetActiveStyle('SaftUI')

	self.units = {}

	for unit, global_name in pairs(self.unit_strings) do
		self.oUF:Spawn(unit, 'SaftUI_'..global_name)
	end

	st.options.args.unitframes = self:GetConfigTable()
end

function UF:OnEnable()
	UF:UpdateConfig(unit)
	UF:UpdateColors()
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

function UF:UpdateConfig(unit, element_name)
	if not unit then 
		for unit, frame in pairs(self.units) do
			UF:UpdateConfig(unit, element_name)
		end
	else
		local frame = self.units[unit]
		
		if element_name then
			self.elements[element_name].UpdateConfig(frame)
		else
			frame:ClearAllPoints()
			if not frame.config.enable then
				frame:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 10000, 10000)
			else
				frame:SetPoint(unpack(frame.config.position))
				frame:SetSize(frame.config.width, frame.config.height)

				st:SetBackdrop(frame, frame.config.template)
				
				frame.Range = {
					insideAlpha = frame.config.range_alpha.inside,
					outsideAlpha = frame.config.range_alpha.outside
				}
				
				
				for element_name, element in pairs(frame.elements) do
					self.elements[element_name].UpdateConfig(frame)
				end
			end
		end
	end
end

function UF:GetConfigTable()
	local config = {
		order = 1,
		type = 'group',
		name = 'Unitframes',
		childGroups = 'select',
		args = {
		}
	}

	for unit,frame in pairs(self.units) do
		config.args[unit] = {
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
						enable = {
							order = 0,
							name = 'Enable',
							type = 'toggle',
							width = 0.5
						},
						framelevel = {
							order = 1,
							name = 'Frame Level',
							type = 'range',
							min = 0,
							max = 99,
							step = 1,
							width = 1,
						},
						height = {
							order = 2,
							name = 'Height',
							type = 'input',
							pattern = '%d+',
							width = 0.5,
						},
						width = {
							order = 3,
							name = 'Width',
							type = 'input',
							pattern = '%d+',
							width = 0.5,
						},
						template = {
							order = 4,
							name = 'Template',
							type = 'select',
							values = st.CF:GetFrameTemplates(),
						},
						position = st.CF:GeneratePositionGroup(
							frame.config.position, true, 5, nil, 
							function() UF:UpdateConfig(frame.unit) end
						),
					}
				}
			}
		}

		for element_name, element in pairs(frame.elements) do
			config.args[unit].args[element_name] = self.elements[element_name].GetConfigTable(frame)
		end
	end

	return config
end