local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

function PostUpdateClassPower(self, cur, max, hasMaxChanged, powerType)
	if not max then self:Hide() return end
	local width = (self:GetWidth() - (self.config.spacing * (max - 1))) / max
	for i = 1, max do
		self[i]:SetWidth(width)
		if self.config.show_empty then
			self[i]:Show()
		end
	end
end

local function Constructor(self)
	if not (self.unit == 'player') then return end

	local classpower = CreateFrame('frame', 'SaftUI_Player_ClassPower', self)
	classpower.config = self.config.classpower
	for i = 1, 10 do
		classpower[i] =  CreateFrame('StatusBar', nil, classpower)
	end

	classpower.PostUpdate = PostUpdateClassPower
	self.ClassPower = classpower
	return classpower
end

local function UpdateConfig(self)
	self.ClassPower.config = self.config.classpower
	if not unit == 'player' then return end
	
	if self.config.classpower.enable == false then
		return self.ClassPower:Hide()
	else
		self.ClassPower:Show()
	end

	self.ClassPower:SetPoint(st:UnpackPoint(self.config.classpower.position))

	self.ClassPower:SetFrameLevel(self.config.classpower.framelevel)

	if self.config.classpower.relative_height then
		self.ClassPower:SetHeight(self.config.height + self.config.classpower.height)
	else
		self.ClassPower:SetHeight(self.config.classpower.height)
	end

	if self.config.classpower.relative_width then
		self.ClassPower:SetWidth(self.config.width + self.config.classpower.width)
	else
		self.ClassPower:SetWidth(self.config.classpower.width)
	end

	-- st:SetBackdrop(self.ClassPower, 'thin')
	
	local prev
	for i=1, 10 do
		local point = self.ClassPower[i]
		st:SetBackdrop(point, self.config.classpower.template)
		
		point:SetStatusBarTexture(st.BLANK_TEX)
		point:ClearAllPoints()
		if prev then
			point:SetPoint('LEFT', prev, 'RIGHT', self.config.classpower.spacing, 0)
		else
			point:SetPoint('LEFT')
		end
		point:SetHeight(self.config.classpower.height)
		prev = point
	end
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'ClassPower',
		get = function(info)
			return config.profiles[config.config_profile][unit].classpower[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].classpower[info[#info]] = value
			UF:UpdateConfig(unit, 'ClassPower')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			size = UF.GenerateRelativeSizeConfigGroup(3),
			spacing = st.CF.generators.range(4, 'Spacing', 0, 20),
			show_empty = st.CF.generators.toggle(5, 'Show empty'),
			position = st.CF.generators.uf_element_position(50,
				function(index) return
					config.profiles[config.config_profile][unit].classpower.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].classpower.position[index] = value
					UF:UpdateConfig(unit, 'ClassPower')
				end
			),
		}
	}
end

function ValidUnits(unit)
	return unit == 'player'
end

UF:RegisterElement('ClassPower', Constructor, UpdateConfig, GetConfigTable, ValidUnits)
