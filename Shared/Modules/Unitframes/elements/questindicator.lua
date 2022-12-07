local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(self)
	local indicator = self.TextOverlay:CreateTexture(nil, 'OVERLAY')

	self.QuestIndicator = indicator
	return indicator
end

local function UpdateConfig(self)
	self.QuestIndicator.config = self.config.questindicator
	
	if self.config.questindicator.enable == false then
		self.QuestIndicator:Hide()
		return
	else
		self.QuestIndicator:Show()
	end

	self.QuestIndicator:SetSize(self.config.questindicator.size, self.config.questindicator.size)

	self.QuestIndicator:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.questindicator.position)
	local frame = st.CF.get_frame(self, self.config.questindicator.position)
	self.QuestIndicator:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.QuestIndicator:SetAlpha(self.config.questindicator.alpha)
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'QuestIndicator',
		get = function(info)
			return config.profiles[config.config_profile][unit].questindicator[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].questindicator[info[#info]] = value
			UF:UpdateConfig(unit, 'QuestIndicator')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			alpha = st.CF.generators.alpha(3),
			size = st.CF.generators.range(4, 'Size', 1, 50),
			position = st.CF.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].questindicator.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].questindicator.position[index] = value
					UF:UpdateConfig(unit, 'QuestIndicator')
				end
			),
		}
	}
end

UF:RegisterElement('QuestIndicator', Constructor, UpdateConfig, GetConfigTable)