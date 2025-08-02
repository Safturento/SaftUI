local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(unitframe)
	return UF:AddTextElement(unitframe, 'Name')
end

local function UpdateConfig(unitframe)
	unitframe.Name.config = unitframe.config.name
	UF:UpdateElement(unitframe.Name, 'Name')

	unitframe.Name:SetFontObject(st:GetFont(unitframe.config.name.font))
    unitframe.Name.overrideUnit = true
	unitframe:Tag(unitframe.Name, '[st:name('.. unitframe.base_unit..')]')
end

local function GetConfigTable(unit)
	local config = st.config.profile.unitframes
	return {
		type = 'group',
		name = 'Name',
		get = function(info)
			return config.profiles[config.config_profile][unit].name[info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].name[info[#info]] = value
			UF:UpdateConfig(unit, 'Name')
		end,
		args = {
			enable = st.Config.generators.enable(0),
			font = st.Config.generators.font(1),
			alpha = st.Config.generators.alpha(3),
			position = st.Config.generators.uf_element_position(4,
				function(index) return
					config.profiles[config.config_profile][unit].name.position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].name.position[index] = value
					UF:UpdateConfig(unit, 'Name')
				end
			),
			showLevel = st.Config.generators.toggle(5, 'Show level', 1),
			showSameLevel = st.Config.generators.toggle(6, 'Show same level', 1),
			showMaxLevel = st.Config.generators.toggle(6, 'Show max level', 1),
			allCaps = st.Config.generators.toggle(6, 'All caps', 1),
			maxLength = st.Config.generators.range(7, 'Max length', 1, 100, 1),
		}
	}
end

UF:RegisterElement('Name', Constructor, UpdateConfig, GetConfigTable)