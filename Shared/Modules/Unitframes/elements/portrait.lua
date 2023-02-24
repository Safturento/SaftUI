local st = SaftUI
local UF = st:GetModule('Unitframes')


local function Constructor(self)
	local portrait = CreateFrame('PlayerModel', self:GetName()..'_Portrait', self)
	portrait.config = self.config.portrait
	
	self.Portrait = portrait
	return portrait
end

local function UpdateConfig(self)
	self.Portrait.config = self.config.portrait
	
	if self.config.portrait.enable == false then
		self.Portrait:Hide()
		return
	else
		self.Portrait:Show()
	end

	if self.config.portrait.relative_height then
		self.Portrait:SetHeight(self.config.height + self.config.portrait.height)
	else
		self.Portrait:SetHeight(self.config.portrait.height)
	end

	if self.config.portrait.relative_width then
		self.Portrait:SetWidth(self.config.width + self.config.portrait.width)
	else
		self.Portrait:SetWidth(self.config.portrait.width)
	end

	st:SetBackdrop(self.Portrait, self.config.portrait.template)

	self.Portrait:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.portrait.position)
	local frame = UF:GetFrame(self, self.config.portrait.position)
	self.Portrait:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.Portrait:SetFrameLevel(self.config.portrait.framelevel)
	self.Portrait:SetAlpha(self.config.portrait.alpha)
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'Portrait',
		get = function(info)
			return config.profiles[config.config_profile][unit].portrait[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].portrait[info[#info]] = value
			UF:UpdateConfig(unit, 'Portrait')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			alpha = st.CF.generators.alpha(3),
			size = UF.GenerateRelativeSizeConfigGroup(4),
			position = st.CF.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].portrait.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].portrait.position[index] = value
					UF:UpdateConfig(unit, 'Portrait')
				end
			),
		}
	}
end

UF:RegisterElement('Portrait', Constructor, UpdateConfig, GetConfigTable)