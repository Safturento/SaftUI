local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(self)
	local name = self.TextOverlay:CreateFontString(nil, 'OVERLAY')

	self.Name = name
	return name
end

local function UpdateConfig(self)
	self.Name.config = self.config.name
	if self.config.name.enable == false then
		self.Name:Hide()
		return
	else
		self.Name:Show()
	end

	self.Name:SetFontObject(st:GetFont(self.config.name.font))
	self.Name:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.name.position)
	self.Name:SetPoint(anchor, self, rel_anchor, x_off, y_off)

	self:Tag(self.Name, '[st:name]')
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes
	return {
		type = 'group',
		name = 'Name',
		get = function(info)
			return config.profiles[config.config_profile][unit].name[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].name[info[#info]] = value
			UF:UpdateConfig(unit, 'Name')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			font = st.CF.generators.font(1),
			alpha = st.CF.generators.alpha(3),
			position = st.CF.generators.uf_element_position(4,
				function(index) return
					config.profiles[config.config_profile][unit].name.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].name.position[index] = value
					UF:UpdateConfig(unit, 'Name')
				end
			),
			show_level = st.CF.generators.toggle(5, 'Show level', 1),
			max_length = st.CF.generators.range(6, 'Max length', 1, 100, 1),
		}
	}
end

UF:RegisterElement('Name', Constructor, UpdateConfig, GetConfigTable)