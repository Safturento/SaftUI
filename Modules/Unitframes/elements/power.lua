local st = SaftUI
local UF = st:GetModule('Unitframes')

local function PostUpdatePower(power, unit, current, min, max)
	if power.text then
		if current == max and power.config.text.hide_full then
			power.text:SetText('')
		elseif UnitPowerType(unit) ~= 0 then
			power.text:SetText(current)
		else
			power.text:SetFormattedText(current < 10000 and current or st.StringFormat:ShortFormat(current, 1))
		end
	end

	if max == 0 then
		power:SetMinMaxValues(0, 1)
		power:SetValue(1)
	end

	
	power:SetStatusBarTexture(st.BLANK_TEX)
	power.bg:SetTexture(st.BLANK_TEX)
end


local function Constructor(self)
	local power = CreateFrame('StatusBar', nil, self)
	power.config = self.config.power

	power.bg = power:CreateTexture(nil, 'BACKGROUND')
	power.bg:SetAllPoints(power)
	power.bg:SetTexture(st.BLANK_TEX)

	power.text = self.TextOverlay:CreateFontString(nil, 'OVERLAY')
	-- We have to set this here since PostUpdatePower can run before UpdateConfig
	power.text:SetFontObject(st:GetFont(self.config.power.text.font))

	power.PostUpdate = PostUpdatePower
	self.Power = power
	return power
end

local function UpdateConfig(self)
	self.Power.config = self.config.power
	
	if not self.config.power.enable then
		self.Power:Hide()
		return
	else
		self.Power:Show()
	end

	if self.config.power.relative_height then
		self.Power:SetHeight(self.config.height + self.config.power.height)
	else
		self.Power:SetHeight(self.config.power.height)
	end

	if self.config.power.relative_width then
		self.Power:SetWidth(self.config.width + self.config.power.width)
	else
		self.Power:SetWidth(self.config.power.width)
	end

	st:SetBackdrop(self.Power, self.config.power.template)

	self.Power:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.power.position)
	local frame = st.CF.get_frame(self, self.config.power.position)
	self.Power:SetPoint(anchor, frame, rel_anchor, x_off, y_off)


	self.Power:SetFrameLevel(self.config.power.framelevel)
	self.Power:SetStatusBarTexture(st.BLANK_TEX)

	if self.config.power.colorCustom then
		self.Power:SetStatusBarColor(unpack(self.config.power.customColor))
	end

	if self.config.power.bg.enable then
		self.Power.bg:Show()
		self.Power.bg:SetAlpha(self.config.power.bg.alpha)
		self.Power.bg.multiplier = self.config.power.bg.multiplier
		self.Power.bg:SetTexture(st.BLANK_TEX)
	else
		self.Power.bg:Hide()
	end

	if self.config.power.text.enable then
		self.Power.text:Show()
		self.Power.text:SetFontObject(st:GetFont(self.config.power.text.font))
		self.Power.text:ClearAllPoints()
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.power.text.position)
		local frame = st.CF.get_frame(self, self.config.power.text.position)
		self.Power.text:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	else
		self.Power.text:Hide()
	end
	
	self.Power:SetReverseFill(self.config.power.reverse_fill)
	self.Power:SetOrientation(self.config.power.vertical_fill and "VERTICAL" or "HORIZONTAL")

	self.Power.Smooth = true
	self.Power.colorTapping			= self.config.power.colorTapping
	self.Power.colorDisconnected	= self.config.power.colorDisconnected
	self.Power.colorPower			= self.config.power.colorPower
	self.Power.colorClass			= self.config.power.colorClass
	self.Power.colorClassNPC		= self.config.power.colorClassNPC
	self.Power.colorClassPet		= self.config.power.colorClassPet
	self.Power.colorReaction		= self.config.power.colorReaction
	self.Power.colorSmooth			= self.config.power.colorSmooth
	self.Power.colorCustom			= self.config.power.colorCustom
	self.Power.customColor 			= self.config.power.customColor
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'Power',
		get = function(info)
			return config.profiles[config.config_profile][unit].power[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].power[info[#info]] = value
			UF:UpdateConfig(unit, 'Power')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			size = UF.GenerateRelativeSizeConfigGroup(2),
			template = st.CF.generators.template(3),
			reverse_fill = st.CF.generators.toggle(4, 'Reverse Fill', 1),
			vertical_fill = st.CF.generators.toggle(5, 'Vertical Fill', 1),
			position = st.CF.generators.uf_element_position(50,
				function(index) return
					config.profiles[config.config_profile][unit].power.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].power.position[index] = value
					UF:UpdateConfig(unit, 'Power')
				end
			),
			text = {
				order = 98,
				name = 'Text',
				type = 'group',
				inline = true,
				get = function(info)
					return config.profiles[config.config_profile][unit].power.text[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].power.text[info[#info]] = value
					UF:UpdateConfig(unit, 'Power')
				end,
				args = {
					enable = st.CF.generators.enable(0),
					font = st.CF.generators.font(1),
					position = st.CF.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].power.text.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].power.text.position[index] = value
					UF:UpdateConfig(unit, 'Power')
				end
			),
				},
			},
			bg = {
				order = 99,
				name = 'Status Bar BG',
				type = 'group',
				inline = true,
				get = function(info)
					return config.profiles[config.config_profile][unit].power.bg[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].power.bg[info[#info]] = value
					UF:UpdateConfig(unit, 'Power')
				end,
				args = {
					enable = st.CF.generators.enable(0),
					multiplier = {
						order = 2,
						name = 'Multiplier',
						type = 'range',
						min = 0,
						max = 1,
						step = 0.05,
						width = 1,
					},
					alpha = st.CF.generators.alpha(3)
				},
			}
		}
	}
end

UF:RegisterElement('Power', Constructor, UpdateConfig, GetConfigTable)