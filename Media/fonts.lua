local st = SaftUI

local FN = st:NewModule('Fonts')

FN.font_objects = {}

FN.outlines = {
	NONE = st.retail and '' or 'NONE',
	OUTLINE = 'Outline',
	THICKOUTLINE = 'Thick Outline',
	MONOCHROME = 'Monochrome',
	MONOCHROMEOUTLINE = 'Monochrome Outline',
	MONOCHROMETHICKOUTLINE = 'Monochrome Thick Outine',
}

function FN:OnInitialize()
	for key, config in pairs(st.config.profile.fonts) do
		local font = CreateFont('SaftUI_'..config.name..'Font')

		font:SetFont(
			st.LSM:Fetch('font', config.font_name),
			config.font_size,
			config.font_outline
		)
		font:SetShadowOffset(unpack(config.shadow_offset))
		font:SetSpacing(config.spacing)
		font:SetTextColor(1, 1, 1)

		FN.font_objects[key] = font
	end
end

function FN:UpdateFontConfig(font_name)
	if not font_name then
		for key, config in pairs(st.config.profile.fonts) do
			self:UpdateFontConfig(key)
		end
		return 
	end

	local font = st:GetFont(font_name)
	local config = st.config.profile.fonts[font_name]

	font:SetFont(
		st.LSM:Fetch('font', config.font_name),
		config.font_size,
		config.font_outline
	)
	font:SetShadowOffset(unpack(config.shadow_offset))
	font:SetSpacing(config.spacing)
end

function st:GetFont(font_name)
	return FN.font_objects[font_name]
end

function FN:GetConfigTable()
	local config = {
		order = 1,
		type = 'group',
		name = 'Fonts',
		-- childGroups = 'select',
		set = function(info, value)
			st.config.profile.fonts[info[#info-1]][info[#info]] = value
			self:UpdateFontConfig(info[#info-1])
		end,
		get = function(info)
			return st.config.profile.fonts[info[#info-1]][info[#info]]
		end,
		args = {
		}
	}

	for font_key, font_object in pairs(self.font_objects) do
		config.args[font_key] = {
			name = st.config.profile.fonts[font_key].name,
			type = 'group',
			inline = true,
			args = {
				name = {
					order = 1,
					name = 'Name',
					type = 'input',
					width = 0.75,
				},
				font_name = {
					order = 2,
					type = 'select',
					dialogControl = 'LSM30_Font',
					name = 'Font Name',
					values = st.LSM:HashTable("font"),
					width = 0.75,
				},
				font_size = st.CF.generators.range(3, 'Font Size', 1, 100, 1),
				font_outline = {
					order = 4,
					type = 'select',
					name = 'Font Outline',
					values = FN.outlines,
					width = 0.75,
				}
			},
		}
	end

	return config
end