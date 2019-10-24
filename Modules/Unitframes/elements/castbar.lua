local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

function UF.PostCastStart(castbar, unit, spellName)
	if castbar.notInterruptible then
		castbar:SetStatusBarTexture(unpack(castbar.config.colors.nointerrupt))
	else
		castbar:SetStatusBarTexture(unpack(castbar.config.colors.normal))
	end

	if castbar.Icon.texture:GetTexture() == [[Interface\ICONS\INV_Misc_QuestionMark]] then
		local name, _, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = CastingInfo(unit)
		local icon = select(10, GetItemInfo(name))

		if icon then
			castbar.Icon.texture:SetTexture(icon)
		end
	end
end

local function Constructor(self)
	local castbar = CreateFrame('StatusBar', nil, self)
	castbar.config = self.config.castbar

	castbar.Text = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Text:SetFontObject(st:GetFont(self.config.castbar.text.font))
	castbar.Time = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Time:SetFontObject(st:GetFont(self.config.castbar.time.font))
	castbar.Icon = CreateFrame('frame', nil, castbar)
	castbar.Icon.texture = castbar.Icon:CreateTexture(nil, 'OVERLAY')
	castbar.Icon.SetTexture = function(self, tex) self.texture:SetTexture(tex) end
	castbar.Icon.texture:SetAllPoints(castbar.Icon)

	castbar.PostCastStart = UF.PostCastStart
	castbar.PostChannelStart = UF.PostCastStart

	self.Castbar = castbar
	return castbar
end

local function UpdateConfig(self)
	self.Castbar.config = self.config.castbar
	
	if self.config.castbar.enable == false then
		self.Castbar:Hide()
		return
	else
		self.Castbar:Show()
	end

	if self.config.castbar.relative_height then
		self.Castbar:SetHeight(self.config.height + self.config.castbar.height)
	else
		self.Castbar:SetHeight(self.config.castbar.height)
	end

	if self.config.castbar.relative_width then
		self.Castbar:SetWidth(self.config.width + self.config.castbar.width)
	else
		self.Castbar:SetWidth(self.config.castbar.width)
	end

	st:SetBackdrop(self.Castbar, self.config.castbar.template)

	if self.config.castbar.text.enable then
		self.Castbar.Text:Show()
		self.Castbar.Text:SetFontObject(st:GetFont(self.config.castbar.text.font))
		self.Castbar.Text:ClearAllPoints()
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.castbar.text.position)
		local frame = st.CF.get_frame(self, self.config.castbar.text.position)
		self.Castbar.Text:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	else
		self.Castbar.Text:Hide()
	end

	if self.config.castbar.time.enable then
		self.Castbar.Time:Show()
		self.Castbar.Time:SetFontObject(st:GetFont(self.config.castbar.time.font))
		self.Castbar.Time:ClearAllPoints()
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.castbar.time.position)
		local frame = st.CF.get_frame(self, self.config.castbar.time.position)
		self.Castbar.Time:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	else
		self.Castbar.Time:Hide()
	end

	if self.config.castbar.icon.enable then
		self.Castbar.Icon:Show()
		st:SetBackdrop(self.Castbar.Icon, self.config.castbar.icon.template)
		self.Castbar.Icon:ClearAllPoints()
		
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.castbar.icon.position)
		local frame = st.CF.get_frame(self, self.config.castbar.icon.position)

		self.Castbar.Icon:SetPoint(anchor, frame, rel_anchor, x_off, y_off)

		if self.config.castbar.icon.relative_height then
			self.Castbar.Icon:SetHeight(self.config.height + self.config.castbar.icon.height)
		else
			self.Castbar.Icon:SetHeight(self.config.castbar.icon.height)
		end
	
		if self.config.castbar.icon.relative_width then
			self.Castbar.Icon:SetWidth(self.config.width + self.config.castbar.icon.width)
		else
			self.Castbar.Icon:SetWidth(self.config.castbar.icon.width)
		end

		st:SkinIcon(self.Castbar.Icon.texture)
	else
		self.Castbar.Icon:Hide()
	end

	self.Castbar:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.castbar.position)
	self.Castbar:SetPoint(anchor, self, rel_anchor, x_off, y_off)
	self.Castbar:SetFrameLevel(self.config.castbar.framelevel)
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'Castbar',
		get = function(info)
			return config.profiles[config.config_profile][unit].castbar[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].castbar[info[#info]] = value
			UF:UpdateConfig(unit, 'Castbar')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			size = UF.GenerateRelativeSizeConfigGroup(3),
			position = st.CF.generators.uf_element_position(4,
				function(index) return
					config.profiles[config.config_profile][unit].castbar.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].castbar.position[index] = value
					UF:UpdateConfig(unit, 'Castbar')
				end
			),
			icon = {
				order = 5,
				name = 'Icon',
				inline = true,
				type = 'group',
				get = function(info)
					return config.profiles[config.config_profile][unit].castbar.icon[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].castbar.icon[info[#info]] = value
					UF:UpdateConfig(unit, 'Castbar')
				end,
				args = {
					enable = st.CF.generators.enable(0),
					framelevel = st.CF.generators.framelevel(1),
					template = st.CF.generators.template(2),
					size = UF.GenerateRelativeSizeConfigGroup(3),
					position = st.CF.generators.uf_element_position(4,
						function(index) return
							config.profiles[config.config_profile][unit].castbar.icon.position[index]
						end,
						function(index, value)
							config.profiles[config.config_profile][unit].castbar.icon.position[index] = value
							UF:UpdateConfig(unit, 'Castbar')
						end
					),
				}
			},
			text = {
				order = 6,
				name = 'Text',
				type = 'group',
				inline = true,
				get = function(info)
					return config.profiles[config.config_profile][unit].castbar.text[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].castbar.text[info[#info]] = value
					UF:UpdateConfig(self.base_unit, 'Health')
				end,
				args = {
					enable = st.CF.generators.enable(0),
					font = st.CF.generators.font(1),
					position = st.CF.generators.uf_element_position(2,
						function(index) return
							config.profiles[config.config_profile][unit].castbar.text.position[index]
						end,
						function(index, value)
							config.profiles[config.config_profile][unit].castbar.text.position[index] = value
							UF:UpdateConfig(unit, 'Castbar')
						end
					),
				},
			},
			time = {
				order = 7,
				name = 'Time',
				type = 'group',
				inline = true,
				get = function(info)
					return config.profiles[config.config_profile][unit].castbar.time[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].castbar.time[info[#info]] = value
					UF:UpdateConfig(self.base_unit, 'Health')
				end,
				args = {
					enable = st.CF.generators.enable(0),
					font = st.CF.generators.font(1),
					position = st.CF.generators.uf_element_position(2,
						function(index) return
							config.profiles[config.config_profile][unit].castbar.time.position[index]
						end,
						function(index, value)
							config.profiles[config.config_profile][unit].castbar.time.position[index] = value
							UF:UpdateConfig(unit, 'Castbar')
						end
					),
				},
			},
		}
	}
end

UF:RegisterElement('Castbar', Constructor, UpdateConfig, GetConfigTable)