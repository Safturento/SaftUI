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

function FN:OnEnable()
	self:UpdateFontConfig()
end

-- A profile change. Font objects are shared, so re-applying them updates every
-- font string set to one; nothing else has to be touched.
function FN:UpdateConfig()
	self:UpdateFontConfig()
end

-- Applies a font's profile settings to its font object, creating the object
-- the first time. With no font_name, does every font in the profile.
function FN:UpdateFontConfig(font_name)
	if not font_name then
		for key, config in pairs(st.config.profile.fonts) do
			self:UpdateFontConfig(key)
		end
		return 
	end

	local config = st.config.profile.fonts[font_name]
	local font = self.font_objects[font_name]
	if not font then
		font = CreateFont('SaftUI_'..config.name..'Font')
		font:SetTextColor(1, 1, 1)
		self.font_objects[font_name] = font
	end

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
					desc = "What this font is called in the Font lists of SaftUI's settings.",
					type = 'input',
				},
				font_name = {
					order = 2,
					type = 'select',
					dialogControl = 'LSM30_Font',
					name = 'Font Name',
					desc = 'The typeface of every text that uses this font.',
					values = st.LSM:HashTable("font"),
				},
				font_size = st.Config.generators.range(3, 'Font Size', 1, 100, 1,
					'How big every text that uses this font is.'),
				font_outline = {
					order = 4,
					type = 'select',
					name = 'Font Outline',
					desc = 'The outline around the letters of every text that uses this font.',
					values = FN.outlines,
				}
			},
		}
	end

	return config
end