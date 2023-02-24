local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(self)
	local indicator = self.TextOverlay:CreateTexture(nil, 'OVERLAY')

	self.RaidTargetIndicator = indicator
	return indicator
end

local function UpdateConfig(self)
	self.RaidTargetIndicator.config = self.config.raidtargetindicator
	
	if self.config.raidtargetindicator.enable == false then
		self.RaidTargetIndicator:Hide()
		return
	else
		self.RaidTargetIndicator:Show()
	end

	self.RaidTargetIndicator:SetSize(self.config.raidtargetindicator.size, self.config.raidtargetindicator.size)

	self.RaidTargetIndicator:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.raidtargetindicator.position)
	local frame = UF:GetFrame(self, self.config.raidtargetindicator.position)
	self.RaidTargetIndicator:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.RaidTargetIndicator:SetAlpha(self.config.raidtargetindicator.alpha)
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'RaidTargetIndicator',
		get = function(info)
			return config.profiles[config.config_profile][unit].raidtargetindicator[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].raidtargetindicator[info[#info]] = value
			UF:UpdateConfig(unit, 'RaidTargetIndicator')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			alpha = st.CF.generators.alpha(3),
			size = st.CF.generators.range(4, 'Size', 1, 50),
			position = st.CF.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].raidtargetindicator.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].raidtargetindicator.position[index] = value
					UF:UpdateConfig(unit, 'RaidTargetIndicator')
				end
			),
		}
	}
end

UF:RegisterElement('RaidTargetIndicator', Constructor, UpdateConfig, GetConfigTable)