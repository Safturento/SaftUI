local st = SaftUI
local UF = st:GetModule('Unitframes')

local function PostUpdate(self, role)
	if not self.config then return end
	if (not self.config.show_dps) and role == 'DAMAGER' then
		self:Hide()
	end
end

local function Constructor(self)
	local indicator = self.TextOverlay:CreateTexture(self:GetName()..'GroupRoleIndicator', 'OVERLAY')
	indicator.PostUpdate = PostUpdate

	self.GroupRoleIndicator = indicator
	return indicator
end

local function UpdateConfig(self)
	self.GroupRoleIndicator.config = self.config.grouproleindicator
	
	if self.config.grouproleindicator.enable == false then
		self.GroupRoleIndicator:Hide()
		return
	else
		self.GroupRoleIndicator:Show()
	end

	self.GroupRoleIndicator:SetSize(self.config.grouproleindicator.size, self.config.grouproleindicator.size)

	self.GroupRoleIndicator:ClearAllPoints()
	local anchor, frame, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.grouproleindicator.position)
	local frame = st.CF.get_frame(self, self.config.raidtargetindicator.position)
	self.GroupRoleIndicator:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.GroupRoleIndicator:SetAlpha(self.config.grouproleindicator.alpha)
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'GroupRoleIndicator',
		get = function(info)
			return config.profiles[config.config_profile][unit].grouproleindicator[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].grouproleindicator[info[#info]] = value
			UF:UpdateConfig(unit, 'GroupRoleIndicator')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			alpha = st.CF.generators.alpha(3),
			size = st.CF.generators.range(4, 'Size', 1, 50),
			show_dps = st.CF.generators.toggle(5, 'Show dps'),
			position = st.CF.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].grouproleindicator.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].grouproleindicator.position[index] = value
					UF:UpdateConfig(unit, 'GroupRoleIndicator')
				end
			),
		}
	}
end

UF:RegisterElement('GroupRoleIndicator', Constructor, UpdateConfig, GetConfigTable)