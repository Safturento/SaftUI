local st = SaftUI
local UF = st:GetModule('Unitframes')

local function getHealthPercentText(current, max, absorbs, precision)
	local perc = current/max*100
	if precision and precision > 0 then
		perc = ('%0.' .. (precision) .. 'f'):format(perc)
	else
		perc = floor(perc)
	end

	if absorbs > 0 then
		return ('%s +%d'):format(perc, floor(absorbs/max*100))
	else
		return perc
	end
end

local function PostUpdateHealth(health, unit, current, max)
	if UF.RMH and UF.RMH.UnitHasHealthData(unit) then
		current, max = UF.RMH.GetUnitHealth(unit)
	end

	local absorbs = st.retail and UnitGetTotalAbsorbs(unit) or 0
	health:SetMinMaxValues(0, max + absorbs)
	health.absorbs:SetMinMaxValues(0, max + absorbs)
	health.absorbs:SetValue(absorbs)

	if health.text then
		if current == max and health.config.text.hide_full then
			health.text:SetText('')
		elseif UnitIsDead(unit) or current == 0 then
			health.text:SetText('Dead')
		elseif health.config.text.deficit then
			health.text:SetText(current - max)
		elseif health.config.text.percent then
			health.text:SetText(getHealthPercentText(current, max, absorbs))
		else
			local text
			if absorbs > 0 then
				text = ('%s +%s'):format(st.StringFormat:ShortFormat(current, 1, 1000), st.StringFormat:ShortFormat(absorbs, 1, 1000))
			else
				text = current < 10000 and current or st.StringFormat:ShortFormat(current, 1, 1000)
			end

			if health.config.text.boss_percent and UnitLevel(unit) == -1 then
				text = ("%s | %s"):format(text, getHealthPercentText(current, max, absorbs, 1))
			end

			health.text:SetText(text)
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

local function Constructor(unitframe)
    local health = UF:AddStatusBarElement(unitframe, 'Health')

	local healthStatusBarTexture = health:GetStatusBarTexture()
	local absorbs = CreateFrame('StatusBar', nil, unitframe)
	absorbs:SetPoint('TOPLEFT', healthStatusBarTexture, 'TOPRIGHT', 0, 0)
	absorbs:SetPoint('BOTTOMLEFT', healthStatusBarTexture, 'BOTTOMRIGHT', 0, 0)
	health.absorbs = absorbs

	UF:AddText(unitframe, health)
	health.PostUpdate = PostUpdateHealth

	return health
end

local function UpdateConfig(unitframe)
    local health = unitframe.Health

    UF:UpdateElement(health)

    local config = health.config

	UF:UpdateStatusBarElement(health.absorbs, config)
	health.absorbs:SetSize(health:GetSize())
	health.absorbs:SetStatusBarColor(unpack(config.absorbColor))
	health.absorbs:SetFrameLevel(health:GetFrameLevel())

	health.colorTapping		 = config.colorTapping
	health.colorDisconnected = config.colorDisconnected
	health.colorHealth		 = config.colorHealth
	health.colorClass		 = config.colorClass
	health.colorClassNPC	 = config.colorClassNPC
	health.colorClassPet	 = config.colorClassPet
	health.colorReaction	 = config.colorReaction
	health.colorSmooth		 = config.colorSmooth
	health.colorCustom		 = config.colorCustom
	health.customColor 		 = config.customColor
end



local function GetConfigTable(unit)
	local config = st.config.profile.unitframes

	return {
		type = 'group',
		name = 'Health',
		get = function(info)
			return tostring(config.profiles[config.config_profile][unit].health[info[#info]])
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].health[info[#info]] = value
			UF:UpdateConfig(unit, 'Health')
		end,
		args = {
			enable = st.Config.generators.enable(0),
			framelevel = st.Config.generators.framelevel(1),
			template = st.Config.generators.template(2),
			size = UF.GenerateRelativeSizeConfigGroup(3),
			reverse_fill = st.Config.generators.toggle(4, 'Reverse Fill', 1),
			vertical_fill = st.Config.generators.toggle(5, 'Vertical Fill', 1),
			position = st.Config.generators.uf_element_position(50,
				function(index)
					return tostring(config.profiles[config.config_profile][unit].health.position[index])
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
					enable = st.Config.generators.enable(0),
					font = st.Config.generators.font(1),
					position = st.Config.generators.uf_element_position(2,
					function(index) return
						config.profiles[config.config_profile][unit].health.text.position[index]
					end,
					function(index, value)
						config.profiles[config.config_profile][unit].health.text.position[index] = value
						UF:UpdateConfig(unit, 'Health')
					end
					),
					deficit =st.Config.generators.toggle(3, 'Deficit'),
					hide_full = st.Config.generators.toggle(4, 'Hide full'),
					percent = st.Config.generators.toggle(5, 'Percent'),
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
					enable = st.Config.generators.enable(1),
					multiplier = st.Config.generators.range(2, 'Multiplier', 0, 1, 0.05),
					alpha = st.Config.generators.alpha(3)
				},
			}
		}
	}
end

UF:RegisterElement('Health', Constructor, UpdateConfig, GetConfigTable)
