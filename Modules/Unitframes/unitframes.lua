local ADDON_NAME, st = ...
local UF = st:NewModule('Unitframes')

UF.oUF = st.oUF
assert(UF.oUF, 'st was unable to locate oUF.')

UF.elements = {}

UF.UnitStrings = {
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
	
	self.config = st.config.profile.unitframes.units[self.base_unit]


	UF.ElementStrings = {}
	for element, funcs in pairs(UF.elements) do
		UF.ElementStrings[element] = element
		funcs.Construct(self)
	end
end

function UF:OnEnable()
	self.oUF:RegisterStyle('SaftUI', UF.ConstructUnit)
	self.oUF:SetActiveStyle('SaftUI')

	self.Units = {}

	for unit, global_name in pairs(self.UnitStrings) do
		self.Units[unit] = self.oUF:Spawn(unit, 'SaftUI_'..global_name)
	end

	st.options.args.unitframes.args = self:GenerateConfigTable()
	
	self:UpdateConfig()
end

function UF:UpdateConfig(unit)
	if not unit then 
		for unit, frame in pairs(self.Units) do
			UF:UpdateConfig(unit)
		end
	else
		local frame = self.Units[unit]
		
		frame.Range = {
			insideAlpha = frame.config.range_alpha.inside,
			outsideAlpha = frame.config.range_alpha.outside
		}

		frame:ClearAllPoints()
		frame:SetPoint(unpack(frame.config.position))
		frame:SetSize(frame.config.width, frame.config.height)

		for element_name, funcs in pairs(UF.elements) do
			local element = frame[element_name]
			if element.config.enable == false then
				frame:DisableElement(element_name)
				return
			else
				frame:EnableElement(element_name)
			end

			if element.config.relative_height then
				element:SetHeight(frame.config.height + element.config.height)
			else
				element:SetHeight(element.config.height)
			end
			
			if element.config.relative_width then
				element:SetWidth(frame.config.width + element.config.width)
			else
				element:SetWidth(element.config.width)
			end

			element:ClearAllPoints()
			element:SetPoint(unpack(element.config.position))

			funcs.Update(frame)
		end
	end
end

function UF:GenerateConfigTable()
	return {
		unit = {
			order = 0,
			type = 'select',
			style = 'dropdown',
			name = 'Unit',
			values = UF.UnitStrings,
			get = function(info) return st.config.profile.unitframes.config_unit end,
			set = function(info, value) st.config.profile.unitframes.config_unit = value end,
		},
		element = {
			order = 0,
			type = 'select',
			style = 'dropdown',
			name = 'Element',
			values = UF.ElementStrings,
			get = function(info) return st.config.profile.unitframes.config_element end,
			set = function(info, value) st.config.profile.unitframes.config_element = value end,
		},
		element_config = {
			order = 2,
			type = 'group',
			inline = true,
			name = '',
			args = {
				height = {
					get = function(info)
						return st.config.profile.unitframes.units[st.config.profile.unitframes.config_unit].height
					end,
					set = function(info, value)
						st.config.profile.unitframes.units[st.config.profile.unitframes.config_unit].height = value
						UF:UpdateConfig(st.config.profile.unitframes.config_unit)
					end,
					name = 'Height',
					type = 'range',
					min = 1,
					max = 1000,
					step = 1,
				}
			}
		}
	}
	
end
