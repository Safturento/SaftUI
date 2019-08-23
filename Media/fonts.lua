local ADDON_NAME, st = ...

local FN = st:NewModule('Fonts')

FN.font_objects = {}

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

		FN.font_objects[key] = font
	end
end

function st:GetFont(font_object)
	return FN.font_objects[font_object]
end