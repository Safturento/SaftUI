local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local function PostUpdateHealth(health, unit, min, max)
	if health.text then

		local absorbs = st.is_retail and UnitGetTotalAbsorbs(unit) or 0
		
		if min == max and health.hide_full then
			health.text:SetText('')
		elseif health.percent then
			if absorbs > 0 then
				health.text:SetFormattedText('%d +%d', floor(min/max*100), floor(absorbs/max*100))
			else
				health.text:SetFormattedText('%d', floor(min/max*100)) 
			end
		else
			if absorbs > 0 then
				health.text:SetFormattedText('%s +%s', st.StringFormat:ShortFormat(min, 1), st.StringFormat:ShortFormat(absorbs, 1))
			else
				health.text:SetFormattedText('%s', st.StringFormat:ShortFormat(min, 1))
			end
		end
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
	-- We just hide it instead of disabling so
	-- that the text still updates
	if self.config.health.enable == false then
		self.Health:Hide()
		-- self:DisableElement('Health')
		return
	else
		-- self:EnableElement('Health')
		self.Health:Show()
	end

	if self.config.health.relative_height then
		self.Health:SetHeight(self.config.height + self.config.health.height)
	else
		self.Health:SetHeight(self.config.health.height)
	end

	if self.config.health.relative_width then
		self.Health:SetWidth(self.config.width + self.config.health.width)
	else
		self.Health:SetWidth(self.config.health.width)
	end

	st:SetBackdrop(self.Health, self.config.health.template)

	self.Health:ClearAllPoints()
	local anchor, rel_anchor, x_off, y_off = unpack(self.config.health.position)
	self.Health:SetPoint(anchor, self, rel_anchor, x_off, y_off)
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
		local anchor, rel_anchor, x_off, y_off = unpack(self.config.health.text.position)
		self.Health.text:SetPoint(anchor, self, rel_anchor, x_off, y_off)
	else
		self.Health.text:Hide()
	end

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

local function GetConfigTable(self)
	return {
		type = 'group',
		name = 'Health',
		get = function(info)
			return self.config.health[info[#info]]
		end,
		set = function(info, value)
			self.config.health[info[#info]] = value
			UF:UpdateConfig(self.unit, 'Health')
		end,
		args = {
			enable = {
				order = 0,
				name = 'Enable',
				type = 'toggle',
				width = 0.5
			},
			framelevel = {
				order = 1,
				name = 'Frame Level',
				type = 'range',
				min = 0,
				max = 99,
				step = 1,
				width = 1,
			},
			height = {
				order = 2,
				name = 'Height',
				type = 'input',
				pattern = '%d+',
				width = 0.5,
			},
			width = {
				order = 3,
				name = 'Width',
				type = 'input',
				pattern = '%d+',
				width = 0.5,
			},
			template = {
				order = 4,
				name = 'Template',
				type = 'select',
				values = st.CF:GetFrameTemplates(),
			},
			position = st.CF:GeneratePositionGroup(
				self.config.health.position, false, 5, nil, 
				function() UF:UpdateConfig(self.unit, 'Health') end
			),
			text = {
				order = 6,
				name = 'Text',
				type = 'group',
				inline = true,
				get = function(info)
					return self.config.health.text[info[#info]]
				end,
				set = function(info, value)
					self.config.health.text[info[#info]] = value
					UF:UpdateConfig(self.unit, 'Health')
				end,
				args = {
					enable = {
						order = 0,
						name = 'Enable',
						type = 'toggle',
					},
					font = {
						name = 'Font',
						type = 'select',
						order = 1,
						values = st.CF:GetFontObjects(),
					},
					position = st.CF:GeneratePositionGroup(
						self.config.health.text.position, false, 3, nil, 
						function() UF:UpdateConfig(self.unit, 'Health') end
					),
				},
			},
			bg = {
				order = 6,
				name = 'Status Bar BG',
				desc = 'A background texture for the status bar. Will be the same color as the bar but can be darker or transparent based on settings',
				descStyle = 'inline',
				type = 'group',
				inline = true,
				get = function(info)
					return self.config.health.bg[info[#info]]
				end,
				set = function(info, value)
					self.config.health.bg[info[#info]] = value
					UF:UpdateConfig(self.unit, 'Health')
				end,
				args = {
					enable = {
						order = 0,
						name = 'Enable',
						type = 'toggle',
						width = 0.5,
					},
					multiplier = {
						order = 2,
						name = 'Multiplier',
						type = 'range',
						min = 0,
						max = 1,
						step = 0.05,
						width = 1,
					},
					alpha = {
						order = 3,
						name = 'Alpha',
						type = 'range',
						min = 0,
						max = 1,
						step = 0.05,
						width = 1,
					}
				},
			}
		}
	}
end

UF:RegisterElement('Health', Constructor, UpdateConfig, GetConfigTable)
