local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local function Constructor(self)
	local indicator = self.TextOverlay:CreateTexture(nil, 'OVERLAY')

	self.RaidRoleIndicator = indicator
	return indicator
end

local function UpdateConfig(self)
	self.RaidRoleIndicator.config = self.config.raidroleindicator
	
	if self.config.raidroleindicator.enable == false then
		self.RaidRoleIndicator:Hide()
		return
	else
		self.RaidRoleIndicator:Show()
	end

	self.RaidRoleIndicator:SetSize(self.config.raidroleindicator.size, self.config.raidroleindicator.size)

	self.RaidRoleIndicator:ClearAllPoints()
	local anchor, frame, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.raidroleindicator.position)
	local frame = st.CF.get_frame(self, self.config.raidtargetindicator.position)
	self.RaidRoleIndicator:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.RaidRoleIndicator:SetAlpha(self.config.raidroleindicator.alpha)
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'RaidRoleIndicator',
		get = function(info)
			return config.profiles[config.config_profile][unit].raidroleindicator[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].raidroleindicator[info[#info]] = value
			UF:UpdateConfig(unit, 'RaidRoleIndicator')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			alpha = st.CF.generators.alpha(3),
			size = st.CF.generators.range(4, 'Size', 1, 50),
			position = st.CF.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].raidroleindicator.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].raidroleindicator.position[index] = value
					UF:UpdateConfig(unit, 'RaidRoleIndicator')
				end
			),
		}
	}
end

UF:RegisterElement('RaidRoleIndicator', Constructor, UpdateConfig, GetConfigTable)