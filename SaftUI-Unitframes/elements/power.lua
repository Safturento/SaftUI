local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	We can override the altPower functionality to force the main power bar
	to stay as mana for shaman/druid/priest with additionalPower. This will
	be used in conjunction the additional power overridden to show mana
	when both config.additionalpower.enable and config.additionalpower.manaAsPrimary
	are set as true
]]
local function GetDisplayPower(element)
	local unit = element.__owner.unit

	if unit == 'player' then
		return Enum.PowerType.Mana, 0
	end
end

local function PostUpdatePower(power, unit, current, min, max)
	if power.text then
		if current == max and power.config.text.hide_full then
			power.text:SetText('')
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


local function Constructor(unitframe)
    local power = UF:AddStatusBarElement(unitframe, 'Power')
    UF:AddText(unitframe, power)
	power.GetDisplayPower = GetDisplayPower
	power.PostUpdate = PostUpdatePower

	return power
end

local function UpdateConfig(unitframe)
    local power = unitframe.Power
    UF:UpdateElement(power)

	-- Toggle forcing main power as mana for shaman/druid/priest in specs with additionalPower
	power.displayAltPower = unitframe.config.additionalpower
                        and unitframe.config.additionalpower.enable
                        and unitframe.config.additionalpower.manaAsPrimary
						and UnitPowerMax('player', 0) > 0

	power.colorTapping		= power.config.colorTapping
	power.colorDisconnected	= power.config.colorDisconnected
	power.colorPower		= power.config.colorPower
	power.colorClass		= power.config.colorClass
	power.colorClassNPC		= power.config.colorClassNPC
	power.colorClassPet		= power.config.colorClassPet
	power.colorReaction		= power.config.colorReaction
	power.colorSmooth		= power.config.colorSmooth
	power.colorCustom		= power.config.colorCustom
	power.customColor 		= power.config.customColor
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
			enable = st.Config.generators.enable(0),
			framelevel = st.Config.generators.framelevel(1),
			template = st.Config.generators.template(2),
			size = UF.GenerateRelativeSizeConfigGroup(3),
			reverse_fill = st.Config.generators.toggle(4, 'Reverse Fill', 1),
			vertical_fill = st.Config.generators.toggle(5, 'Vertical Fill', 1),
			position = st.Config.generators.uf_element_position(50,
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
					enable = st.Config.generators.enable(0),
					font = st.Config.generators.font(1),
					position = st.Config.generators.uf_element_position(5,
				function(index) return
					config.profiles[config.config_profile][unit].power.text.position[index]
				end,
				function(index, value)
					print(index, value)
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
					enable = st.Config.generators.enable(0),
					multiplier = {
						order = 2,
						name = 'Multiplier',
						type = 'range',
						min = 0,
						max = 1,
						step = 0.05,
						width = 1,
					},
					alpha = st.Config.generators.alpha(3)
				},
			}
		}
	}
end

UF:RegisterElement('Power', Constructor, UpdateConfig, GetConfigTable)