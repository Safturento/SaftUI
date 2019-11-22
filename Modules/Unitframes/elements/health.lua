local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local function PostUpdateHealth(health, unit, current, max)
	if UF.RMH and UF.RMH.UnitHasHealthData(unit) then
		current, max = UF.RMH.GetUnitHealth(unit)
	end

	if health.text then

		local absorbs = st.is_retail and UnitGetTotalAbsorbs(unit) or 0
		
		if current == max and health.config.text.hide_full then
			health.text:SetText('')
		elseif health.config.text.deficit then
			health.text:SetText(current-max)
		elseif health.config.text.percent then
			if absorbs > 0 then
				health.text:SetFormattedText('%d +%d', floor(current/max*100), floor(absorbs/max*100))
			else
				health.text:SetFormattedText('%d', floor(current/max*100)) 
			end
		else
			if absorbs > 0 then
				health.text:SetFormattedText('%s +%s', st.StringFormat:ShortFormat(current, 1, 1000), st.StringFormat:ShortFormat(absorbs, 1, 1000))
			else
				health.text:SetText(current < 10000 and current or st.StringFormat:ShortFormat(current, 1, 1000))
			end
		end
	end

	if health.config.colorCustom then
		health:SetStatusBarColor(unpack(health.config.customColor))
	end

	if health.config.bg.enable then
		r, g, b = health:GetStatusBarColor()
		local mu = health.config.bg.multiplier or 1
		health.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
	
end

local function Constructor(self)
	local health = CreateFrame('StatusBar', nil, self)
	health.config = self.config.health

	health.bg = health:CreateTexture(nil, 'BACKGROUND')
	health.bg:SetAllPoints(health)
	health.bg:SetTexture(st.BLANK_TEX)

	health.text = self.TextOverlay:CreateFontString(nil, 'OVERLAY')
	-- We have to set this here since PostUpdateHealth can run before UpdateConfig
	health.text:SetFontObject(st:GetFont(self.config.health.text.font))
	
	health.PostUpdate = PostUpdateHealth
	
	self.Health = health
	return health
end

local function UpdateConfig(self)
	self.Health.config = self.config.health
	
	-- We just hide it instead of disabling so
	-- that the text still updates
	if self.config.health.enable == false then
		self.Health:Hide()
		return
	else
		self.Health:Show()
	end

	if self.config.health.relative_height then
		st:SetHeight(self.Health, self.config.height + self.config.health.height)
	else
		st:SetHeight(self.Health, self.config.health.height)
	end

	if self.config.health.relative_width then
		st:SetWidth(self.Health, self.config.width + self.config.health.width)
	else
		st:SetWidth(self.Health, self.config.health.width)
	end

	st:SetBackdrop(self.Health, self.config.health.template)

	self.Health:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.health.position)
	local frame = st.CF.get_frame(self, self.config.health.position)
	self.Health:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.Health:SetFrameLevel(self.config.health.framelevel)
	self.Health:SetStatusBarTexture(st.BLANK_TEX)
	if self.config.health.colorCustom then
		self.Health:SetStatusBarColor(unpack(self.config.health.customColor))
	end

	if self.config.health.bg.enable then
		self.Health.bg:Show()
		self.Health.bg:SetAlpha(self.config.health.bg.alpha)
		self.Health.bg.multiplier = self.config.health.bg.multiplier
	else
		self.Health.bg:Hide()
	end

	if self.config.health.text.enable then
		self.Health.text:Show()
		self.Health.text:SetFontObject(st:GetFont(self.config.health.text.font))
		self.Health.text:ClearAllPoints()
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(self.config.health.text.position)
		local frame = st.CF.get_frame(self, self.config.health.text.position)
		self.Health.text:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	else
		self.Health.text:Hide()
	end

	self.Health:SetReverseFill(self.config.health.reverse_fill)
	self.Health:SetOrientation(self.config.health.vertical_fill and "VERTICAL" or "HORIZONTAL")

	self.Health.Smooth = true
	self.Health.colorTapping		= self.config.health.colorTapping
	self.Health.colorDisconnected	= self.config.health.colorDisconnected
	self.Health.colorHealth			= self.config.health.colorHealth
	self.Health.colorClass			= self.config.health.colorClass
	self.Health.colorClassNPC		= self.config.health.colorClassNPC
	self.Health.colorClassPet		= self.config.health.colorClassPet
	self.Health.colorReaction		= self.config.health.colorReaction
	self.Health.colorSmooth			= self.config.health.colorSmooth
	self.Health.colorCustom			= self.config.health.colorCustom
	self.Health.customColor 		= self.config.health.customColor
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'Health',
		get = function(info)
			return config.profiles[config.config_profile][unit].health[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].health[info[#info]] = value
			UF:UpdateConfig(unit, 'Health')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			size = UF.GenerateRelativeSizeConfigGroup(3),
			reverse_fill = st.CF.generators.toggle(4, 'Reverse Fill', 1),
			vertical_fill = st.CF.generators.toggle(5, 'Vertical Fill', 1),
			position = st.CF.generators.uf_element_position(50,
				function(index) return
					config.profiles[config.config_profile][unit].health.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].health.position[index] = value
					UF:UpdateConfig(unit, 'Health')
				end
			),
			text = {
				order = 98,
				name = 'Text',
				type = 'group',
				inline = true,
				get = function(info)
					return config.profiles[config.config_profile][unit].health.text[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].health.text[info[#info]] = value
					UF:UpdateConfig(unit, 'Health')
				end,
				args = {
					enable = st.CF.generators.enable(0),
					font = st.CF.generators.font(1),
					position = st.CF.generators.uf_element_position(2,
					function(index) return
						config.profiles[config.config_profile][unit].health.text.position[index]
					end,
					function(index, value)
						config.profiles[config.config_profile][unit].health.text.position[index] = value
						UF:UpdateConfig(unit, 'Health')
					end
					),
					deficit =st.CF.generators.toggle(3, 'Deficit'),
					hide_full = st.CF.generators.toggle(4, 'Hide full'),
					percent = st.CF.generators.toggle(5, 'Percent'),
				},
			},
			bg = {
				order = 99,
				name = 'Status Bar BG',
				type = 'group',
				inline = true,
				get = function(info)
					return config.profiles[config.config_profile][unit].health.bg[info[#info]]
				end,
				set = function(info, value)
					config.profiles[config.config_profile][unit].health.bg[info[#info]] = value
					UF:UpdateConfig(unit, 'Health')
				end,
				args = {
					enable = st.CF.generators.enable(1),
					multiplier = st.CF.generators.range(2, 'Multiplier', 0, 1, 0.05),
					alpha = st.CF.generators.alpha(3)
				},
			}
		}
	}
end

UF:RegisterElement('Health', Constructor, UpdateConfig, GetConfigTable)
